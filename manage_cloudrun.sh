#!/bin/bash

################################################################################
# GCP Cloud Run Management Script
# This script provides management operations for Cloud Run services
# including logs, monitoring, scaling, updates, and rollbacks
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

# Get project and region
get_project_info() {
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    REGION=$(gcloud config get-value run/region 2>/dev/null)
    
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        gcloud projects list
        read -p "Enter Project ID: " PROJECT_ID
        gcloud config set project $PROJECT_ID
    fi
    
    if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
        read -p "Enter Region (default: us-central1): " REGION
        REGION=${REGION:-us-central1}
        gcloud config set run/region $REGION
    fi
}

# List all Cloud Run services
list_services() {
    log_step "Listing Cloud Run services..."
    echo ""
    
    gcloud run services list \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    echo ""
}

# Get service details
get_service_details() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    log_step "Retrieving service details for: $SERVICE_NAME"
    echo ""
    
    # Get service description
    gcloud run services describe $SERVICE_NAME \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    echo ""
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format='value(status.url)')
    
    log_info "Service URL: $SERVICE_URL"
    echo ""
}

# View service logs
view_logs() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    echo ""
    log_info "Log viewing options:"
    options=(
        "Tail logs (follow)"
        "Recent logs (last 50 lines)"
        "Logs with time range"
        "Filter logs by severity"
        "Back to main menu"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "Tail logs (follow)")
                log_info "Following logs (Ctrl+C to stop)..."
                gcloud run logs tail $SERVICE_NAME \
                    --region=$REGION \
                    --project=$PROJECT_ID
                break
                ;;
            "Recent logs (last 50 lines)")
                gcloud run logs read $SERVICE_NAME \
                    --region=$REGION \
                    --project=$PROJECT_ID \
                    --limit=50
                break
                ;;
            "Logs with time range")
                read -p "Enter time range (e.g., 1h, 30m, 2d): " time_range
                gcloud run logs read $SERVICE_NAME \
                    --region=$REGION \
                    --project=$PROJECT_ID \
                    --limit=100
                break
                ;;
            "Filter logs by severity")
                echo ""
                log_info "Severity levels: DEBUG, INFO, WARNING, ERROR, CRITICAL"
                read -p "Enter severity level: " severity
                gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME AND severity>=$severity" \
                    --limit=50 \
                    --format=json \
                    --project=$PROJECT_ID
                break
                ;;
            "Back to main menu")
                return
                ;;
            *) log_error "Invalid option";;
        esac
    done
    
    echo ""
}

# Update service configuration
update_service() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    log_step "Update options for: $SERVICE_NAME"
    echo ""
    options=(
        "Update image"
        "Update environment variables"
        "Update resource limits (memory/CPU)"
        "Update scaling settings"
        "Update traffic split"
        "Update IAM policy"
        "Back to main menu"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "Update image")
                update_image
                break
                ;;
            "Update environment variables")
                update_env_vars
                break
                ;;
            "Update resource limits (memory/CPU)")
                update_resources
                break
                ;;
            "Update scaling settings")
                update_scaling
                break
                ;;
            "Update traffic split")
                update_traffic
                break
                ;;
            "Update IAM policy")
                update_iam
                break
                ;;
            "Back to main menu")
                return
                ;;
            *) log_error "Invalid option";;
        esac
    done
}

# Update image
update_image() {
    echo ""
    read -p "Enter new image URL: " NEW_IMAGE
    
    log_info "Updating image to: $NEW_IMAGE"
    
    gcloud run services update $SERVICE_NAME \
        --image=$NEW_IMAGE \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    log_success "Image updated successfully"
}

# Update environment variables
update_env_vars() {
    echo ""
    log_info "Environment variable operations:"
    options=(
        "Set/Update variables"
        "Remove variables"
        "Clear all variables"
        "Back to update menu"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "Set/Update variables")
                echo ""
                log_info "Enter environment variables (format: KEY=VALUE)"
                log_info "Separate multiple variables with comma"
                read -p "Environment variables: " env_vars
                
                gcloud run services update $SERVICE_NAME \
                    --set-env-vars="$env_vars" \
                    --platform=managed \
                    --region=$REGION \
                    --project=$PROJECT_ID
                
                log_success "Environment variables updated"
                break
                ;;
            "Remove variables")
                echo ""
                log_info "Enter variable names to remove (comma-separated)"
                read -p "Variables: " remove_vars
                
                gcloud run services update $SERVICE_NAME \
                    --remove-env-vars="$remove_vars" \
                    --platform=managed \
                    --region=$REGION \
                    --project=$PROJECT_ID
                
                log_success "Environment variables removed"
                break
                ;;
            "Clear all variables")
                gcloud run services update $SERVICE_NAME \
                    --clear-env-vars \
                    --platform=managed \
                    --region=$REGION \
                    --project=$PROJECT_ID
                
                log_success "All environment variables cleared"
                break
                ;;
            "Back to update menu")
                return
                ;;
            *) log_error "Invalid option";;
        esac
    done
}

# Update resources
update_resources() {
    echo ""
    read -p "Enter memory limit (e.g., 512Mi, 1Gi, 2Gi): " memory
    read -p "Enter CPU count (1, 2, 4, 8): " cpu
    
    gcloud run services update $SERVICE_NAME \
        --memory=$memory \
        --cpu=$cpu \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    log_success "Resources updated"
}

# Update scaling
update_scaling() {
    echo ""
    read -p "Enter minimum instances: " min_instances
    read -p "Enter maximum instances: " max_instances
    read -p "Enter max concurrent requests per instance: " concurrency
    
    gcloud run services update $SERVICE_NAME \
        --min-instances=$min_instances \
        --max-instances=$max_instances \
        --concurrency=$concurrency \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    log_success "Scaling settings updated"
}

# Update traffic split
update_traffic() {
    echo ""
    log_info "Current revisions:"
    gcloud run revisions list \
        --service=$SERVICE_NAME \
        --region=$REGION \
        --project=$PROJECT_ID
    
    echo ""
    log_info "Traffic split format: REVISION-NAME=PERCENTAGE"
    log_info "Example: myservice-00001-abc=50,myservice-00002-xyz=50"
    read -p "Enter traffic split: " traffic_split
    
    gcloud run services update-traffic $SERVICE_NAME \
        --to-revisions=$traffic_split \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    log_success "Traffic split updated"
}

# Update IAM policy
update_iam() {
    echo ""
    options=(
        "Allow unauthenticated access (make public)"
        "Require authentication (make private)"
        "Add specific member"
        "Back to update menu"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "Allow unauthenticated access (make public)")
                gcloud run services add-iam-policy-binding $SERVICE_NAME \
                    --member="allUsers" \
                    --role="roles/run.invoker" \
                    --region=$REGION \
                    --project=$PROJECT_ID
                
                log_success "Service is now publicly accessible"
                break
                ;;
            "Require authentication (make private)")
                gcloud run services remove-iam-policy-binding $SERVICE_NAME \
                    --member="allUsers" \
                    --role="roles/run.invoker" \
                    --region=$REGION \
                    --project=$PROJECT_ID 2>/dev/null || true
                
                log_success "Service now requires authentication"
                break
                ;;
            "Add specific member")
                read -p "Enter member (e.g., user:email@example.com): " member
                gcloud run services add-iam-policy-binding $SERVICE_NAME \
                    --member="$member" \
                    --role="roles/run.invoker" \
                    --region=$REGION \
                    --project=$PROJECT_ID
                
                log_success "Member added to IAM policy"
                break
                ;;
            "Back to update menu")
                return
                ;;
            *) log_error "Invalid option";;
        esac
    done
}

# Rollback to previous revision
rollback_service() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    log_step "Available revisions for: $SERVICE_NAME"
    echo ""
    
    gcloud run revisions list \
        --service=$SERVICE_NAME \
        --region=$REGION \
        --project=$PROJECT_ID
    
    echo ""
    read -p "Enter revision name to rollback to: " REVISION_NAME
    
    if [ -z "$REVISION_NAME" ]; then
        log_error "Revision name cannot be empty"
        return 1
    fi
    
    log_info "Rolling back to revision: $REVISION_NAME"
    
    gcloud run services update-traffic $SERVICE_NAME \
        --to-revisions=$REVISION_NAME=100 \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID
    
    log_success "Rollback completed successfully"
}

# Delete service
delete_service() {
    echo ""
    read -p "Enter service name to delete: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    if confirm "This will permanently delete the service: $SERVICE_NAME. Are you sure?" "n"; then
        log_info "Deleting service..."
        
        gcloud run services delete $SERVICE_NAME \
            --platform=managed \
            --region=$REGION \
            --project=$PROJECT_ID \
            --quiet
        
        log_success "Service deleted successfully"
    else
        log_info "Deletion cancelled"
    fi
}

# Monitor service metrics
monitor_service() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    log_step "Service metrics for: $SERVICE_NAME"
    echo ""
    
    # Get current metrics
    log_info "Request Count (last hour):"
    gcloud monitoring time-series list \
        --filter="resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME AND metric.type=run.googleapis.com/request_count" \
        --format="table(metric.labels.response_code_class, points[0].value.int64Value)" \
        --project=$PROJECT_ID 2>/dev/null || log_warning "Metrics not available yet"
    
    echo ""
    log_info "Container Instance Count:"
    gcloud monitoring time-series list \
        --filter="resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME AND metric.type=run.googleapis.com/container/instance_count" \
        --format="table(points[0].value.int64Value)" \
        --project=$PROJECT_ID 2>/dev/null || log_warning "Metrics not available yet"
    
    echo ""
    log_info "View detailed metrics in Cloud Console:"
    echo "https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/metrics?project=$PROJECT_ID"
    echo ""
}

# Export service configuration
export_service_config() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    OUTPUT_FILE="${SERVICE_NAME}_config.yaml"
    
    log_info "Exporting service configuration to: $OUTPUT_FILE"
    
    gcloud run services describe $SERVICE_NAME \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format=yaml > $OUTPUT_FILE
    
    log_success "Configuration exported to: $OUTPUT_FILE"
}

# Test service endpoint
test_service() {
    echo ""
    read -p "Enter service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        log_error "Service name cannot be empty"
        return 1
    fi
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format='value(status.url)')
    
    log_info "Service URL: $SERVICE_URL"
    echo ""
    
    read -p "Enter path to test (default: /): " test_path
    test_path=${test_path:-/}
    
    log_info "Testing: ${SERVICE_URL}${test_path}"
    echo ""
    
    curl -i "${SERVICE_URL}${test_path}"
    echo ""
}

# Domain mappings
domain_mappings_menu() {
    echo ""
    log_info "Domain mappings:"
    options=(
        "List domain mappings"
        "Create domain mapping"
        "Delete domain mapping"
        "Back to main menu"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "List domain mappings")
                log_step "Listing domain mappings..."
                gcloud run domain-mappings list --region=$REGION --project=$PROJECT_ID
                break
                ;;
            "Create domain mapping")
                read -p "Enter service name: " SERVICE_NAME
                read -p "Enter domain (e.g., app.example.com): " DOMAIN
                log_info "Creating domain mapping..."
                gcloud run domain-mappings create --service=$SERVICE_NAME --domain=$DOMAIN \
                    --region=$REGION --project=$PROJECT_ID
                log_success "Domain mapping created. Configure DNS per the output instructions."
                break
                ;;
            "Delete domain mapping")
                read -p "Enter domain to delete (e.g., app.example.com): " DOMAIN
                if confirm "This will remove the domain mapping for: $DOMAIN. Are you sure?" "n"; then
                    gcloud run domain-mappings delete $DOMAIN --region=$REGION --project=$PROJECT_ID --quiet
                    log_success "Domain mapping deleted."
                else
                    log_info "Operation cancelled"
                fi
                break
                ;;
            "Back to main menu")
                return
                ;;
            *) log_error "Invalid option";;
        esac
    done
}

# Main execution
main() {
    print_banner "GCP Cloud Run - Management Script" "Manage, Monitor, and Control Your Services"
    
    check_prerequisites
    get_project_info
    
    log_success "Connected to project: $PROJECT_ID (Region: $REGION)"
    
    while true; do
        echo ""
        log_info "Cloud Run Management Menu"
        
        options=(
            "List all services"
            "Get service details"
            "View service logs"
            "Update service"
            "Rollback service"
            "Delete service"
            "Monitor service metrics"
            "Export service configuration"
            "Test service endpoint"
            "Domain mappings"
            "Change project/region"
            "Exit"
        )
        
        select opt in "${options[@]}"; do
            case $opt in
                "List all services")
                    list_services
                    break
                    ;;
                "Get service details")
                    get_service_details
                    break
                    ;;
                "View service logs")
                    view_logs
                    break
                    ;;
                "Update service")
                    update_service
                    break
                    ;;
                "Rollback service")
                    rollback_service
                    break
                    ;;
                "Delete service")
                    delete_service
                    break
                    ;;
                "Monitor service metrics")
                    monitor_service
                    break
                    ;;
                "Export service configuration")
                    export_service_config
                    break
                    ;;
                "Test service endpoint")
                    test_service
                    break
                    ;;
                "Domain mappings")
                    domain_mappings_menu
                    break
                    ;;
                "Change project/region")
                    get_project_info
                    break
                    ;;
                "Exit")
                    log_info "Goodbye!"
                    exit 0
                    ;;
                *)
                    log_error "Invalid option"
                    ;;
            esac
        done
        
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
