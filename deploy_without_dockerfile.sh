#!/bin/bash

################################################################################
# Deploy to Cloud Run WITHOUT a Dockerfile
# Uses Google Cloud Buildpacks to automatically containerize your app
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

print_banner "GCP Cloud Run - Deploy Without Dockerfile" "Using Google Cloud Buildpacks"

echo ""
log_info "This script deploys apps to Cloud Run without requiring a Dockerfile."
log_info "Google Cloud will automatically detect your app type and containerize it."
echo ""
log_info "Supported languages:"
echo "  • Node.js (detects package.json)"
echo "  • Python (detects requirements.txt)"
echo "  • Go (detects go.mod)"
echo "  • Java (detects pom.xml or build.gradle)"
echo "  • .NET (detects *.csproj)"
echo ""

# Check prerequisites
CHECK_DOCKER=false  # Docker not needed for buildpacks
check_prerequisites

# Get project configuration
log_step "Gathering project configuration..."
echo ""

# Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "(unset)" ]; then
    log_error "No project configured."
    echo ""
    read -p "Enter your GCP project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
fi

log_info "Current project: $PROJECT_ID"
if ! confirm "Use this project?" "y"; then
    read -p "Enter project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
fi
log_success "Using project: $PROJECT_ID"

# Region
echo ""
CURRENT_REGION=$(gcloud config get-value run/region 2>/dev/null)
if [ -z "$CURRENT_REGION" ] || [ "$CURRENT_REGION" == "(unset)" ]; then
    REGION="us-central1"
else
    REGION="$CURRENT_REGION"
fi

log_info "Common Cloud Run regions:"
echo "  1. us-central1 (Iowa)"
echo "  2. us-east1 (South Carolina)"
echo "  3. us-west1 (Oregon)"
echo "  4. europe-west1 (Belgium)"
echo "  5. asia-northeast1 (Tokyo)"
echo ""
read -p "Enter region (default: $REGION): " INPUT_REGION
REGION="${INPUT_REGION:-$REGION}"
gcloud config set run/region "$REGION"
log_success "Using region: $REGION"

# Service name
echo ""
read -p "Enter Cloud Run service name: " SERVICE_NAME
if [ -z "$SERVICE_NAME" ]; then
    log_error "Service name is required"
    exit 1
fi

# Source code path
echo ""
log_info "Enter the path to your application source code"
read -p "Path to source code (default: current directory): " SOURCE_PATH
SOURCE_PATH="${SOURCE_PATH:-.}"

if [ ! -d "$SOURCE_PATH" ]; then
    log_error "Directory not found: $SOURCE_PATH"
    exit 1
fi

# Check for common app files
echo ""
log_step "Detecting application type..."
cd "$SOURCE_PATH"

if [ -f "package.json" ]; then
    log_success "✓ Node.js app detected (package.json found)"
    APP_TYPE="Node.js"
elif [ -f "requirements.txt" ]; then
    log_success "✓ Python app detected (requirements.txt found)"
    APP_TYPE="Python"
elif [ -f "go.mod" ]; then
    log_success "✓ Go app detected (go.mod found)"
    APP_TYPE="Go"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
    log_success "✓ Java app detected"
    APP_TYPE="Java"
elif ls *.csproj 1> /dev/null 2>&1; then
    log_success "✓ .NET app detected"
    APP_TYPE=".NET"
else
    log_warning "Could not automatically detect app type"
    log_info "Make sure your app has the appropriate dependency file:"
    echo "  • Node.js: package.json"
    echo "  • Python: requirements.txt"
    echo "  • Go: go.mod"
    echo "  • Java: pom.xml or build.gradle"
    echo "  • .NET: *.csproj"
    echo ""
    if ! confirm "Continue anyway?" "n"; then
        exit 1
    fi
    APP_TYPE="Unknown"
fi

# Additional configuration
echo ""
log_step "Configuring deployment settings..."

# Memory
echo ""
log_info "Memory allocation (default: 512Mi)"
echo "  Options: 128Mi, 256Mi, 512Mi, 1Gi, 2Gi, 4Gi"
read -p "Memory: " MEMORY
MEMORY="${MEMORY:-512Mi}"

# CPU
echo ""
log_info "CPU allocation (default: 1)"
echo "  Options: 1, 2, 4"
read -p "CPU: " CPU
CPU="${CPU:-1}"

# Concurrency
echo ""
log_info "Max concurrent requests per instance (default: 80)"
read -p "Concurrency: " CONCURRENCY
CONCURRENCY="${CONCURRENCY:-80}"

# Min/Max instances
echo ""
log_info "Min instances (default: 0 - scale to zero)"
read -p "Min instances: " MIN_INSTANCES
MIN_INSTANCES="${MIN_INSTANCES:-0}"

log_info "Max instances (default: 10)"
read -p "Max instances: " MAX_INSTANCES
MAX_INSTANCES="${MAX_INSTANCES:-10}"

# Allow unauthenticated access
echo ""
if confirm "Allow unauthenticated access (public)?" "y"; then
    ALLOW_UNAUTH="--allow-unauthenticated"
else
    ALLOW_UNAUTH="--no-allow-unauthenticated"
fi

# Environment variables
echo ""
ENV_VARS=""
if confirm "Add environment variables?" "n"; then
    echo ""
    log_info "Enter environment variables (format: KEY=VALUE)"
    log_info "Enter a blank line when done"
    ENV_VARS_ARRAY=()
    while true; do
        read -p "Env var: " ENV_VAR
        if [ -z "$ENV_VAR" ]; then
            break
        fi
        ENV_VARS_ARRAY+=("$ENV_VAR")
    done
    
    if [ ${#ENV_VARS_ARRAY[@]} -gt 0 ]; then
        ENV_VARS="--set-env-vars=$(IFS=,; echo "${ENV_VARS_ARRAY[*]}")"
    fi
fi

# Summary
echo ""
log_step "Deployment Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Service Name:    $SERVICE_NAME"
echo "  Project:         $PROJECT_ID"
echo "  Region:          $REGION"
echo "  Source Path:     $SOURCE_PATH"
echo "  App Type:        $APP_TYPE"
echo "  Memory:          $MEMORY"
echo "  CPU:             $CPU"
echo "  Concurrency:     $CONCURRENCY"
echo "  Min Instances:   $MIN_INSTANCES"
echo "  Max Instances:   $MAX_INSTANCES"
echo "  Public Access:   $([ "$ALLOW_UNAUTH" == "--allow-unauthenticated" ] && echo "Yes" || echo "No")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! confirm "Proceed with deployment?" "y"; then
    log_info "Deployment cancelled"
    exit 0
fi

# Deploy
echo ""
log_step "Deploying to Cloud Run using Buildpacks..."
log_info "This will automatically containerize your application"
echo ""

# Enable required APIs
log_info "Enabling required APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com 2>/dev/null || true

# Deploy using gcloud run deploy with --source flag
# This triggers Cloud Buildpacks automatically
log_info "Starting deployment (this may take several minutes)..."
echo ""

if gcloud run deploy "$SERVICE_NAME" \
    --source="$SOURCE_PATH" \
    --region="$REGION" \
    --memory="$MEMORY" \
    --cpu="$CPU" \
    --concurrency="$CONCURRENCY" \
    --min-instances="$MIN_INSTANCES" \
    --max-instances="$MAX_INSTANCES" \
    $ALLOW_UNAUTH \
    $ENV_VARS; then
    
    echo ""
    log_success "════════════════════════════════════════════════════════════════"
    log_success "Deployment Successful!"
    log_success "════════════════════════════════════════════════════════════════"
    echo ""
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format='value(status.url)')
    
    log_success "Your application is now live at:"
    echo ""
    echo "  🌐 $SERVICE_URL"
    echo ""
    
    log_info "Test your deployment:"
    echo ""
    echo "  curl $SERVICE_URL"
    echo "  curl $SERVICE_URL/health"
    echo ""
    
    log_info "View in Cloud Console:"
    echo "  https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME?project=$PROJECT_ID"
    echo ""
    
    log_info "View logs:"
    echo "  gcloud run services logs read $SERVICE_NAME --region=$REGION --limit=50"
    echo ""
    
else
    echo ""
    log_error "════════════════════════════════════════════════════════════════"
    log_error "Deployment Failed"
    log_error "════════════════════════════════════════════════════════════════"
    echo ""
    log_info "Common issues:"
    echo "  • Make sure your app listens on \$PORT environment variable"
    echo "  • Ensure dependency files are present (package.json, requirements.txt, etc.)"
    echo "  • Check that required APIs are enabled"
    echo ""
    log_info "View build logs for more details:"
    echo "  https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
    exit 1
fi
