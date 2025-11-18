#!/bin/bash

################################################################################
# GCP Cloud Run - Helper Functions and Utilities
# This script provides common helper functions and utilities
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

################################################################################
# HELPER FUNCTIONS
################################################################################

# Get service URL
get_service_url() {
    local service_name=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run services describe "$service_name" \
        --region="$region" \
        --project="$project" \
        --format='value(status.url)' 2>/dev/null
}

# Check if service exists
service_exists() {
    local service_name=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run services describe "$service_name" \
        --region="$region" \
        --project="$project" &>/dev/null
}

# Get service status
get_service_status() {
    local service_name=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run services describe "$service_name" \
        --region="$region" \
        --project="$project" \
        --format='value(status.conditions[0].status)' 2>/dev/null
}

# Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local timeout=${2:-300}
    local region=${3:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${4:-$(gcloud config get-value project 2>/dev/null)}
    
    log_info "Waiting for service to be ready..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        local status=$(get_service_status "$service_name" "$region" "$project")
        
        if [ "$status" = "True" ]; then
            log_success "Service is ready!"
            return 0
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    
    echo ""
    log_error "Timeout waiting for service"
    return 1
}

# Test service endpoint
test_endpoint() {
    local url=$1
    local expected_status=${2:-200}
    
    log_info "Testing endpoint: $url"
    
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "Test passed! Status: $status_code"
        return 0
    else
        log_error "Test failed! Expected: $expected_status, Got: $status_code"
        return 1
    fi
}

# Get latest revision
get_latest_revision() {
    local service_name=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run revisions list \
        --service="$service_name" \
        --region="$region" \
        --project="$project" \
        --format='value(metadata.name)' \
        --limit=1 \
        --sort-by='~metadata.creationTimestamp' 2>/dev/null
}

# Get service image
get_service_image() {
    local service_name=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run services describe "$service_name" \
        --region="$region" \
        --project="$project" \
        --format='value(spec.template.spec.containers[0].image)' 2>/dev/null
}

# Stream logs
stream_logs() {
    local service_name=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run logs tail "$service_name" \
        --region="$region" \
        --project="$project"
}

# Get service metrics
get_service_metrics() {
    local service_name=$1
    local metric_type=$2
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    case $metric_type in
        requests)
            gcloud monitoring time-series list \
                --filter="resource.type=cloud_run_revision AND resource.labels.service_name=$service_name AND metric.type=run.googleapis.com/request_count" \
                --project="$project"
            ;;
        latency)
            gcloud monitoring time-series list \
                --filter="resource.type=cloud_run_revision AND resource.labels.service_name=$service_name AND metric.type=run.googleapis.com/request_latencies" \
                --project="$project"
            ;;
        instances)
            gcloud monitoring time-series list \
                --filter="resource.type=cloud_run_revision AND resource.labels.service_name=$service_name AND metric.type=run.googleapis.com/container/instance_count" \
                --project="$project"
            ;;
        *)
            log_error "Unknown metric type: $metric_type"
            return 1
            ;;
    esac
}

# Create secret in Secret Manager
create_secret() {
    local secret_name=$1
    local secret_value=$2
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    echo -n "$secret_value" | gcloud secrets create "$secret_name" \
        --data-file=- \
        --project="$project"
}

# Update secret version
update_secret() {
    local secret_name=$1
    local secret_value=$2
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    echo -n "$secret_value" | gcloud secrets versions add "$secret_name" \
        --data-file=- \
        --project="$project"
}

# Grant secret access to service
grant_secret_access() {
    local secret_name=$1
    local service_name=$2
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    local project_number=$(gcloud projects describe "$project" --format="value(projectNumber)")
    
    local compute_sa="${project_number}-compute@developer.gserviceaccount.com"
    
    gcloud secrets add-iam-policy-binding "$secret_name" \
        --member="serviceAccount:$compute_sa" \
        --role="roles/secretmanager.secretAccessor" \
        --project="$project"
}

# Create Cloud SQL connection
create_cloudsql_connection() {
    local instance_name=$1
    local database=$2
    local user=$3
    local region=${4:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${5:-$(gcloud config get-value project 2>/dev/null)}
    
    local connection_name="${project}:${region}:${instance_name}"
    echo "$connection_name"
}

# Generate service account for Cloud Run
create_service_account() {
    local sa_name=$1
    local display_name=$2
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud iam service-accounts create "$sa_name" \
        --display-name="$display_name" \
        --project="$project"
    
    echo "${sa_name}@${project}.iam.gserviceaccount.com"
}

# Grant role to service account
grant_role_to_sa() {
    local sa_email=$1
    local role=$2
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud projects add-iam-policy-binding "$project" \
        --member="serviceAccount:$sa_email" \
        --role="$role"
}

# Enable service with custom service account
deploy_with_custom_sa() {
    local service_name=$1
    local sa_email=$2
    local image=$3
    local region=${4:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${5:-$(gcloud config get-value project 2>/dev/null)}
    
    gcloud run deploy "$service_name" \
        --image="$image" \
        --service-account="$sa_email" \
        --region="$region" \
        --project="$project" \
        --platform=managed
}

# Calculate estimated cost
estimate_cost() {
    local requests_per_month=$1
    local avg_duration_ms=$2
    local memory_mb=$3
    local cpu=$4
    
    # Cloud Run pricing (approximate, as of 2024)
    local request_cost=0.0000004  # per request
    local cpu_cost=0.00002400      # per vCPU-second
    local memory_cost=0.0000025    # per GiB-second
    
    # Calculate
    local request_total=$(echo "$requests_per_month * $request_cost" | bc -l)
    local cpu_seconds=$(echo "$requests_per_month * ($avg_duration_ms / 1000) * $cpu" | bc -l)
    local cpu_total=$(echo "$cpu_seconds * $cpu_cost" | bc -l)
    local memory_gib_seconds=$(echo "$requests_per_month * ($avg_duration_ms / 1000) * ($memory_mb / 1024)" | bc -l)
    local memory_total=$(echo "$memory_gib_seconds * $memory_cost" | bc -l)
    
    local total=$(echo "$request_total + $cpu_total + $memory_total" | bc -l)
    
    echo "Estimated monthly cost: \$$total"
    echo "  Requests: \$$request_total"
    echo "  CPU: \$$cpu_total"
    echo "  Memory: \$$memory_total"
}

# Validate Cloud Run service name
validate_service_name() {
    local name=$1
    
    # Cloud Run service name rules:
    # - Must be lowercase
    # - Must start with a letter
    # - Only letters, numbers, and hyphens
    # - Maximum 63 characters
    
    if [[ ! $name =~ ^[a-z][a-z0-9-]{0,62}$ ]]; then
        log_error "Invalid service name: $name"
        log_info "Service name must:"
        echo "  - Start with a letter"
        echo "  - Be lowercase"
        echo "  - Contain only letters, numbers, and hyphens"
        echo "  - Be 63 characters or less"
        return 1
    fi
    
    return 0
}

# Generate random service name
generate_service_name() {
    local prefix=${1:-service}
    local random_suffix=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
    echo "${prefix}-${random_suffix}"
}

# Backup service configuration
backup_service_config() {
    local service_name=$1
    local backup_dir=${2:-./.cloudrun_backups}
    local region=${3:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${4:-$(gcloud config get-value project 2>/dev/null)}
    
    mkdir -p "$backup_dir"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_dir}/${service_name}_${timestamp}.yaml"
    
    gcloud run services describe "$service_name" \
        --region="$region" \
        --project="$project" \
        --format=yaml > "$backup_file"
    
    log_success "Configuration backed up to: $backup_file"
}

# Restore service from backup
restore_service_config() {
    local backup_file=$1
    local region=${2:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${3:-$(gcloud config get-value project 2>/dev/null)}
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    gcloud run services replace "$backup_file" \
        --region="$region" \
        --project="$project"
}

# Compare two revisions
compare_revisions() {
    local service_name=$1
    local revision1=$2
    local revision2=$3
    local region=${4:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${5:-$(gcloud config get-value project 2>/dev/null)}
    
    log_info "Comparing revisions..."
    echo ""
    
    echo "Revision 1: $revision1"
    gcloud run revisions describe "$revision1" \
        --region="$region" \
        --project="$project" \
        --format=json | jq '.spec.containers[0]'
    
    echo ""
    echo "Revision 2: $revision2"
    gcloud run revisions describe "$revision2" \
        --region="$region" \
        --project="$project" \
        --format=json | jq '.spec.containers[0]'
}

# Get service quota
get_quotas() {
    local project=${1:-$(gcloud config get-value project 2>/dev/null)}
    
    log_info "Cloud Run quotas for project: $project"
    echo ""
    
    gcloud run services list \
        --project="$project" \
        --format='table(metadata.name, status.url, status.traffic[0].percent)' 2>/dev/null || true
}

# Clean up old revisions
cleanup_old_revisions() {
    local service_name=$1
    local keep_count=${2:-5}
    local region=${3:-$(gcloud config get-value run/region 2>/dev/null)}
    local project=${4:-$(gcloud config get-value project 2>/dev/null)}
    
    log_info "Cleaning up old revisions (keeping latest $keep_count)..."
    
    local revisions=$(gcloud run revisions list \
        --service="$service_name" \
        --region="$region" \
        --project="$project" \
        --format='value(metadata.name)' \
        --sort-by='~metadata.creationTimestamp')
    
    local count=0
    while IFS= read -r revision; do
        count=$((count + 1))
        if [ $count -gt $keep_count ]; then
            log_info "Deleting revision: $revision"
            gcloud run revisions delete "$revision" \
                --region="$region" \
                --project="$project" \
                --quiet
        fi
    done <<< "$revisions"
    
    log_success "Cleanup complete"
}

# Generate load test
generate_load_test() {
    local service_url=$1
    local requests=${2:-100}
    local concurrency=${3:-10}
    
    log_info "Running load test..."
    log_info "URL: $service_url"
    log_info "Requests: $requests"
    log_info "Concurrency: $concurrency"
    echo ""
    
    if command -v ab &> /dev/null; then
        ab -n "$requests" -c "$concurrency" "$service_url"
    elif command -v hey &> /dev/null; then
        hey -n "$requests" -c "$concurrency" "$service_url"
    else
        log_warning "No load testing tool found (ab or hey)"
        log_info "Install ApacheBench: sudo apt-get install apache2-utils"
        log_info "Or install hey: go install github.com/rakyll/hey@latest"
    fi
}

################################################################################
# UTILITY COMMANDS
################################################################################

# Show usage
show_usage() {
    cat << EOF
GCP Cloud Run Helper Functions

Usage: source ${BASH_SOURCE[0]}
       <function_name> [arguments]

Available Functions:

Service Management:
  get_service_url <service> [region] [project]
  service_exists <service> [region] [project]
  get_service_status <service> [region] [project]
  wait_for_service <service> [timeout] [region] [project]
  get_latest_revision <service> [region] [project]
  get_service_image <service> [region] [project]

Monitoring:
  stream_logs <service> [region] [project]
  get_service_metrics <service> <metric_type> [project]
  test_endpoint <url> [expected_status]

Secrets:
  create_secret <name> <value> [project]
  update_secret <name> <value> [project]
  grant_secret_access <secret> <service> [project]

Service Accounts:
  create_service_account <name> <display_name> [project]
  grant_role_to_sa <sa_email> <role> [project]
  deploy_with_custom_sa <service> <sa_email> <image> [region] [project]

Utilities:
  validate_service_name <name>
  generate_service_name [prefix]
  backup_service_config <service> [backup_dir] [region] [project]
  restore_service_config <backup_file> [region] [project]
  compare_revisions <service> <rev1> <rev2> [region] [project]
  cleanup_old_revisions <service> [keep_count] [region] [project]
  estimate_cost <requests/month> <avg_duration_ms> <memory_mb> <cpu>
  generate_load_test <url> [requests] [concurrency]

Examples:
  get_service_url my-service
  test_endpoint https://my-service-xxx.run.app
  backup_service_config my-service
  cleanup_old_revisions my-service 3

EOF
}

# If script is executed directly, show usage
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    show_usage
fi
