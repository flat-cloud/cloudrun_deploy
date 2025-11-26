#!/bin/bash

################################################################################
# GCP Cloud Run Deployment Script
# This script handles the complete deployment process for any application
# to GCP Cloud Run, including building, pushing, and deploying
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

# --- Default values ---
CONFIG_FILE=""
SKIP_CONFIRMATIONS=false
CHECKPOINT_FILE=".cloudrun-checkpoint.sh"
CHECKPOINT_MAX_AGE=3600  # 1 hour in seconds

# --- Parse command-line arguments ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --config) CONFIG_FILE="$2"; shift ;;
        --yes) SKIP_CONFIRMATIONS=true ;;
        --debug) set -x ;; # Already handled in common.sh, but good to have here
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# --- Functions ---

# Load configuration from a file
load_config() {
    if [ -f "$1" ]; then
        log_info "Loading configuration from $1..."
        source "$1"
        CONFIG_LOADED=true
    else
        log_error "Configuration file not found: $1"
        exit 1
    fi
}

# Save checkpoint after each major configuration step
save_checkpoint() {
    cat > "$CHECKPOINT_FILE" << EOF
# Cloud Run Deployment Checkpoint
# Created: $(date)
# Timestamp: $(date +%s)

PROJECT_ID='${PROJECT_ID:-}'
REGION='${REGION:-}'
SERVICE_NAME='${SERVICE_NAME:-}'
PORT='${PORT:-}'
MEMORY='${MEMORY:-}'
CPU='${CPU:-}'
CONCURRENCY='${CONCURRENCY:-}'
MIN_INSTANCES='${MIN_INSTANCES:-}'
MAX_INSTANCES='${MAX_INSTANCES:-}'
TIMEOUT='${TIMEOUT:-}'
ALLOW_UNAUTH='${ALLOW_UNAUTH:-}'
ENV_VARS='${ENV_VARS:-}'
SECRETS='${SECRETS:-}'
CLOUDSQL='${CLOUDSQL:-}'
VPC_CONNECTOR='${VPC_CONNECTOR:-}'
BUILD_FROM_SOURCE='${BUILD_FROM_SOURCE:-}'
SOURCE_PATH='${SOURCE_PATH:-}'
DOCKERFILE_PATH='${DOCKERFILE_PATH:-}'
BUILD_CONTEXT='${BUILD_CONTEXT:-}'
IMAGE_URL='${IMAGE_URL:-}'
AR_REPO='${AR_REPO:-}'
INGRESS='${INGRESS:-}'
VPC_EGRESS='${VPC_EGRESS:-}'
EXEC_ENV='${EXEC_ENV:-}'
SERVICE_ACCOUNT='${SERVICE_ACCOUNT:-}'
LABELS='${LABELS:-}'
ANNOTATIONS='${ANNOTATIONS:-}'
REV_TAG='${REV_TAG:-}'
NO_TRAFFIC='${NO_TRAFFIC:-}'
REV_SUFFIX='${REV_SUFFIX:-}'
CHECKPOINT_STAGE='${CHECKPOINT_STAGE:-}'
EOF
}

# Check if checkpoint exists and is recent
check_checkpoint() {
    if [ ! -f "$CHECKPOINT_FILE" ]; then
        return 1
    fi
    
    # Extract timestamp from checkpoint
    local checkpoint_time=$(grep "^# Timestamp:" "$CHECKPOINT_FILE" | cut -d' ' -f3)
    local current_time=$(date +%s)
    local age=$((current_time - checkpoint_time))
    
    # Check if checkpoint is recent (less than 1 hour old)
    if [ $age -gt $CHECKPOINT_MAX_AGE ]; then
        log_info "Found old checkpoint (${age}s old), ignoring..."
        return 1
    fi
    
    return 0
}

# Load checkpoint and offer to resume
load_checkpoint() {
    if check_checkpoint; then
        echo ""
        log_info "Found recent deployment session"
        
        # Show checkpoint details
        local checkpoint_date=$(grep "^# Created:" "$CHECKPOINT_FILE" | cut -d' ' -f3-)
        log_info "Last session: $checkpoint_date"
        
        # Extract service name from checkpoint
        local saved_service=$(grep "^SERVICE_NAME=" "$CHECKPOINT_FILE" | cut -d"'" -f2)
        local saved_stage=$(grep "^CHECKPOINT_STAGE=" "$CHECKPOINT_FILE" | cut -d"'" -f2)
        
        if [ -n "$saved_service" ]; then
            log_info "Service: $saved_service"
        fi
        if [ -n "$saved_stage" ]; then
            log_info "Stage: $saved_stage"
        fi
        
        echo ""
        log_info "Options:"
        echo "  1) Resume from checkpoint"
        echo "  2) Edit service name and resume"
        echo "  3) Start fresh (discard checkpoint)"
        read -p "Choose option [1-3]: " resume_option
        
        case "$resume_option" in
            1|"")
                log_info "Loading checkpoint..."
                source "$CHECKPOINT_FILE"
                CONFIG_LOADED=true
                log_success "Checkpoint loaded! Resuming deployment..."
                return 0
                ;;
            2)
                log_info "Loading checkpoint for editing..."
                source "$CHECKPOINT_FILE"
                echo ""
                log_info "Current service name: $SERVICE_NAME"
                read -p "Enter new service name (lowercase, dashes only): " new_service_name
                
                # Validate service name
                if [[ ! "$new_service_name" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
                    log_error "Invalid service name. Must be lowercase, alphanumeric with dashes, 1-63 chars"
                    log_info "Starting fresh..."
                    rm -f "$CHECKPOINT_FILE"
                    return 1
                fi
                
                SERVICE_NAME="$new_service_name"
                # Update checkpoint with new service name
                save_checkpoint
                CONFIG_LOADED=true
                log_success "Service name updated to: $SERVICE_NAME"
                log_success "Resuming deployment..."
                return 0
                ;;
            3)
                log_info "Starting fresh deployment"
                rm -f "$CHECKPOINT_FILE"
                return 1
                ;;
            *)
                log_error "Invalid option"
                return 1
                ;;
        esac
    fi
    return 1
}

# Clear checkpoint on successful deployment
clear_checkpoint() {
    if [ -f "$CHECKPOINT_FILE" ]; then
        rm -f "$CHECKPOINT_FILE"
        log_info "Checkpoint cleared"
    fi
}

# Find and offer to load existing config
find_and_load_config() {
    local config_files=($(ls .cloudrun_deploy_*.conf 2>/dev/null || true))
    if [ ${#config_files[@]} -gt 0 ]; then
        log_info "Found existing deployment configurations:"
        select config in "${config_files[@]}" "Enter manually"; do
            if [[ "$config" == "Enter manually" ]]; then
                CONFIG_LOADED=false
                break
            elif [ -n "$config" ]; then
                load_config "$config"
                break
            else
                log_warning "Invalid selection."
            fi
        done
    else
        CONFIG_LOADED=false
    fi
}

# Get project configuration
get_project_config() {
    log_step "Gathering project configuration..."
    
    # Get or set project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        echo ""
        log_info "Available projects:"
        gcloud projects list
        echo ""
        read -p "Enter GCP Project ID: " PROJECT_ID
        gcloud config set project $PROJECT_ID
    else
        echo ""
        log_info "Current project: $PROJECT_ID"
        if ! confirm "Use this project?" "y"; then
            gcloud projects list
            echo ""
            read -p "Enter GCP Project ID: " PROJECT_ID
            gcloud config set project $PROJECT_ID
        fi
    fi
    
    log_success "Using project: $PROJECT_ID"
    
    # Get or set region
    REGION=$(gcloud config get-value run/region 2>/dev/null)
    
    if [ -z "$REGION" ] || [ "$REGION" = "(unset)" ]; then
        echo ""
        log_info "Common Cloud Run regions:"
        echo "  1. us-central1 (Iowa)"
        echo "  2. us-east1 (South Carolina)"
        echo "  3. us-west1 (Oregon)"
        echo "  4. europe-west1 (Belgium)"
        echo "  5. europe-west2 (London)"
        echo "  6. asia-east1 (Taiwan)"
        echo "  7. asia-northeast1 (Tokyo)"
        echo "  8. australia-southeast1 (Sydney)"
        echo ""
        read -p "Enter region (default: us-central1): " REGION
        REGION=${REGION:-us-central1}
        gcloud config set run/region $REGION
    else
        echo ""
        log_info "Current region: $REGION"
        if ! confirm "Use this region?" "y"; then
            read -p "Enter region: " REGION
            gcloud config set run/region $REGION
        fi
    fi
    
    log_success "Using region: $REGION"
    echo ""
}

# Get application configuration
get_app_config() {
    log_step "Configuring application deployment..."
    echo ""
    
    # Service name
    read -p "Enter Cloud Run service name: " SERVICE_NAME
    
    if [ -z "$SERVICE_NAME" ]; then
        if [[ "$NON_INTERACTIVE" == "true" || "$DRY_RUN" == "true" ]]; then
            SERVICE_NAME="demo-service"
            log_warning "Service name empty; using default: $SERVICE_NAME"
        else
            log_error "Service name cannot be empty"
            exit 1
        fi
    fi
    
    # Container port
    read -p "Enter container port (default: 8080): " PORT
    PORT=${PORT:-8080}
    
    # Memory configuration
    echo ""
    log_info "Memory options: 128Mi, 256Mi, 512Mi, 1Gi, 2Gi, 4Gi, 8Gi"
    read -p "Enter memory limit (default: 512Mi): " MEMORY
    MEMORY=${MEMORY:-512Mi}
    
    # CPU configuration
    echo ""
    log_info "CPU options: 1, 2, 4, 8"
    read -p "Enter CPU count (default: 1): " CPU
    CPU=${CPU:-1}
    
    # Concurrency
    read -p "Enter max concurrent requests per instance (default: 80): " CONCURRENCY
    CONCURRENCY=${CONCURRENCY:-80}
    
    # Min/Max instances
    read -p "Enter minimum instances (default: 0): " MIN_INSTANCES
    MIN_INSTANCES=${MIN_INSTANCES:-0}
    
    read -p "Enter maximum instances (default: 100): " MAX_INSTANCES
    MAX_INSTANCES=${MAX_INSTANCES:-100}
    
    # Timeout
    read -p "Enter request timeout in seconds (default: 300, max: 3600): " TIMEOUT
    TIMEOUT=${TIMEOUT:-300}
    
    # Public access
    echo ""
    if confirm "Allow unauthenticated (public) access?" "n"; then
        ALLOW_UNAUTH="--allow-unauthenticated"
    else
        ALLOW_UNAUTH="--no-allow-unauthenticated"
    fi
    
    # Environment variables
    echo ""
    ENV_VARS=""
    if confirm "Do you want to set environment variables?" "n"; then
        echo ""
        log_info "Enter environment variables (format: KEY=VALUE)"
        log_info "Press Enter with empty line when done"
        
        ENV_VARS_ARRAY=()
        while true; do
            read -p "Environment variable: " env_var
            if [ -z "$env_var" ]; then
                break
            fi
            ENV_VARS_ARRAY+=("$env_var")
        done
        
        if [ ${#ENV_VARS_ARRAY[@]} -gt 0 ]; then
            ENV_VARS="--set-env-vars=$(IFS=,; echo "${ENV_VARS_ARRAY[*]}")"
        fi
    fi
    
    # Secrets
    echo ""
    SECRETS=""
    if confirm "Do you want to mount secrets from Secret Manager?" "n"; then
        echo ""
        log_info "Enter secrets (format: ENV_VAR_NAME=SECRET_NAME:VERSION)"
        log_info "Example: DATABASE_PASSWORD=db-password:latest"
        log_info "Press Enter with empty line when done"
        
        SECRETS_ARRAY=()
        while true; do
            read -p "Secret: " secret
            if [ -z "$secret" ]; then
                break
            fi
            SECRETS_ARRAY+=("$secret")
        done
        
        if [ ${#SECRETS_ARRAY[@]} -gt 0 ]; then
            SECRETS="--set-secrets=$(IFS=,; echo "${SECRETS_ARRAY[*]}")"
        fi
    fi
    
    # Cloud SQL
    echo ""
    CLOUDSQL=""
    if confirm "Do you want to connect to Cloud SQL?" "n"; then
        read -p "Enter Cloud SQL connection string (PROJECT:REGION:INSTANCE): " cloudsql_connection
        if [ ! -z "$cloudsql_connection" ]; then
            CLOUDSQL="--add-cloudsql-instances=$cloudsql_connection"
        fi
    fi
    
    # VPC Connector
    echo ""
    VPC_CONNECTOR=""
    if confirm "Do you want to use a VPC connector?" "n"; then
        read -p "Enter VPC connector name: " vpc_connector
        if [ ! -z "$vpc_connector" ]; then
            VPC_CONNECTOR="--vpc-connector=$vpc_connector"
        fi
    fi
    
    echo ""
    
    # Save checkpoint after app config
    CHECKPOINT_STAGE="app_config_complete"
    save_checkpoint
}

# Generate sample Dockerfile
generate_dockerfile_interactive() {
    echo ""
    log_info "Select application type:"
    options=("Node.js" "Node.js (TypeScript)" "Python" "Go" "Java" ".NET" "Ruby" "PHP" "PHP (Laravel)" "Cancel")
    select opt in "${options[@]}"; do
        case $opt in
            "Node.js")
                generate_nodejs_dockerfile
                break
                ;;
            "Node.js (TypeScript)")
                generate_nodejs_typescript_dockerfile
                break
                ;;
            "Python")
                generate_python_dockerfile
                break
                ;;
            "Go")
                generate_go_dockerfile
                break
                ;;
            "Java")
                generate_java_dockerfile
                break
                ;;
            ".NET")
                generate_dotnet_dockerfile
                break
                ;;
            "Ruby")
                generate_ruby_dockerfile
                break
                ;;
            "PHP")
                generate_php_dockerfile
                break
                ;;
            "PHP (Laravel)")
                generate_laravel_dockerfile
                break
                ;;
            "Cancel")
                log_error "Dockerfile generation cancelled"
                exit 1
                ;;
            *) log_error "Invalid option";;
        esac
    done
}

# Dockerfile templates
generate_nodejs_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

# Use the PORT environment variable provided by Cloud Run
ENV PORT=8080
EXPOSE 8080

CMD ["node", "index.js"]
EOF
    log_success "Node.js Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_python_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Use the PORT environment variable provided by Cloud Run
ENV PORT=8080
EXPOSE 8080

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
EOF
    log_success "Python Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_go_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY . ./

RUN go build -v -o server

FROM alpine:latest
RUN apk add --no-cache ca-certificates

COPY --from=builder /app/server /server

ENV PORT=8080
EXPOSE 8080

CMD ["/server"]
EOF
    log_success "Go Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_java_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre-alpine

COPY --from=build /app/target/*.jar /app.jar

ENV PORT=8080
EXPOSE 8080

CMD ["java", "-jar", "/app.jar"]
EOF
    log_success "Java Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_dotnet_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

WORKDIR /app

COPY *.csproj ./
RUN dotnet restore

COPY . ./
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:7.0

WORKDIR /app
COPY --from=build /app/out .

ENV PORT=8080
EXPOSE 8080

CMD ASPNETCORE_URLS=http://*:$PORT dotnet YourApp.dll
EOF
    log_success ".NET Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_ruby_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM ruby:3.2-alpine

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install --without development test

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["ruby", "app.rb"]
EOF
    log_success "Ruby Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_php_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM php:8.2-apache

COPY . /var/www/html/

RUN chown -R www-data:www-data /var/www/html \
    && a2enmod rewrite

ENV PORT=8080
EXPOSE 8080

RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf \
    && sed -i 's/:80/:8080/g' /etc/apache2/sites-available/000-default.conf

CMD ["apache2-foreground"]
EOF
    log_success "PHP Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_laravel_dockerfile() {
    cat > Dockerfile << 'EOF'
FROM php:8.2-apache

# System deps and PHP extensions commonly needed by Laravel
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libonig-dev libicu-dev libpng-dev \
 && docker-php-ext-install pdo_mysql zip intl opcache \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/*

# Set Apache DocumentRoot to public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/000-default.conf /etc/apache2/apache2.conf

WORKDIR /var/www/html

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy source and install dependencies
COPY . /var/www/html
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader || true \
 && php artisan config:cache || true \
 && php artisan route:cache || true

# Ensure proper permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

# Cloud Run uses PORT env; adjust Apache
ENV PORT=8080
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf \
 && sed -i 's/:80/:8080/g' /etc/apache2/sites-available/000-default.conf

EXPOSE 8080
CMD ["apache2-foreground"]
EOF
    log_success "Laravel Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

generate_nodejs_typescript_dockerfile() {
    cat > Dockerfile << 'EOF'
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
# If you use pnpm/yarn, adjust accordingly
RUN npm ci
COPY . .
# Ensure TypeScript is installed in devDependencies
RUN npm run build

# Runtime stage
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production
COPY --from=build /app/dist ./dist

# Cloud Run provides PORT
ENV PORT=8080
EXPOSE 8080
CMD ["node", "dist/index.js"]
EOF
    log_success "Node.js (TypeScript) Dockerfile created"
    DOCKERFILE_PATH="./Dockerfile"
}

# Configure Docker authentication
configure_docker_auth() {
    log_step "Configuring Docker authentication..."
    
    gcloud auth configure-docker $REGION-docker.pkg.dev --quiet 2>/dev/null || true
    gcloud auth configure-docker gcr.io --quiet 2>/dev/null || true
    
    log_success "Docker authentication configured"
    echo ""
}

# Build Docker image
build_image() {
    log_step "Building Docker image..."
    echo ""
    
    log_info "Building: $IMAGE_URL"
    log_info "Dockerfile: $DOCKERFILE_PATH"
    log_info "Context: $BUILD_CONTEXT"
    echo ""
    
    # Add build arguments support
    if confirm "Do you want to add build arguments?" "n"; then
        echo ""
        log_info "Enter build arguments (format: KEY=VALUE)"
        log_info "Press Enter with empty line when done"
        
        while true; do
            read -p "Build argument: " build_arg
            if [ -z "$build_arg" ]; then
                break
            fi
            BUILD_ARGS="$BUILD_ARGS --build-arg $build_arg"
        done
    fi
    
    if docker build -t $IMAGE_URL -f $DOCKERFILE_PATH $BUILD_ARGS $BUILD_CONTEXT; then
        log_success "Image built successfully"
    else
        log_error "Image build failed"
        exit 1
    fi
    
    echo ""
}

# Push image to registry
push_image() {
    log_step "Pushing image to registry..."
    echo ""
    
    log_info "Pushing: $IMAGE_URL"
    
    if docker push $IMAGE_URL; then
        log_success "Image pushed successfully"
    else
        log_error "Image push failed"
        exit 1
    fi
    
    echo ""
}

# Deploy to Cloud Run
deploy_to_cloudrun() {
    log_step "Deploying to Cloud Run..."
    echo ""
    
    if [ "$BUILD_FROM_SOURCE" = true ]; then
        DEPLOY_CMD="gcloud run deploy $SERVICE_NAME \
            --source=$SOURCE_PATH \
            --platform=managed \
            --region=$REGION \
            --project=$PROJECT_ID \
            --port=$PORT \
            --memory=$MEMORY \
            --cpu=$CPU \
            --concurrency=$CONCURRENCY \
            --min-instances=$MIN_INSTANCES \
            --max-instances=$MAX_INSTANCES \
            --timeout=$TIMEOUT \
            --ingress=$INGRESS \
            --vpc-egress=$VPC_EGRESS \
            --execution-environment=$EXEC_ENV \
            $ALLOW_UNAUTH"
    else
        DEPLOY_CMD="gcloud run deploy $SERVICE_NAME \
            --image=$IMAGE_URL \
            --platform=managed \
            --region=$REGION \
            --project=$PROJECT_ID \
            --port=$PORT \
            --memory=$MEMORY \
            --cpu=$CPU \
            --concurrency=$CONCURRENCY \
            --min-instances=$MIN_INSTANCES \
            --max-instances=$MAX_INSTANCES \
            --timeout=$TIMEOUT \
            --ingress=$INGRESS \
            --vpc-egress=$VPC_EGRESS \
            --execution-environment=$EXEC_ENV \
            $ALLOW_UNAUTH"
    fi
    
    # Optional flags
    [ -n "$SERVICE_ACCOUNT" ] && DEPLOY_CMD="$DEPLOY_CMD --service-account=$SERVICE_ACCOUNT"
    [ -n "$LABELS" ] && DEPLOY_CMD="$DEPLOY_CMD --labels=$LABELS"
    [ -n "$ANNOTATIONS" ] && DEPLOY_CMD="$DEPLOY_CMD --annotations=$ANNOTATIONS"
    [ -n "$REV_TAG" ] && DEPLOY_CMD="$DEPLOY_CMD --tag=$REV_TAG"
    [ -n "$REV_SUFFIX" ] && DEPLOY_CMD="$DEPLOY_CMD --revision-suffix=$REV_SUFFIX"
    [ "$NO_TRAFFIC" = true ] && DEPLOY_CMD="$DEPLOY_CMD --no-traffic"
    
    # Append optional parameters from earlier sections
    [ ! -z "$ENV_VARS" ] && DEPLOY_CMD="$DEPLOY_CMD $ENV_VARS"
    [ ! -z "$SECRETS" ] && DEPLOY_CMD="$DEPLOY_CMD $SECRETS"
    [ ! -z "$CLOUDSQL" ] && DEPLOY_CMD="$DEPLOY_CMD $CLOUDSQL"
    [ ! -z "$VPC_CONNECTOR" ] && DEPLOY_CMD="$DEPLOY_CMD $VPC_CONNECTOR"
    
    log_info "Deployment command:"
    echo "$DEPLOY_CMD" | sed 's/ --/\n    --/g'
    echo ""
    
    if eval $DEPLOY_CMD; then
        log_success "Deployment successful!"
    else
        log_error "Deployment failed"
        exit 1
    fi
    
    echo ""
}
# Get service URL
get_service_url() {
    log_step "Retrieving service URL..."
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format='value(status.url)')
    
    echo ""
    log_success "════════════════════════════════════════════════════════════════"
    log_success "Deployment Complete!"
    log_success "════════════════════════════════════════════════════════════════"
    echo ""
    log_info "Service URL: $SERVICE_URL"
    log_info "Service Name: $SERVICE_NAME"
    log_info "Region: $REGION"
    log_info "Project: $PROJECT_ID"
    echo ""
    log_info "View logs: gcloud run logs read $SERVICE_NAME --region=$REGION"
    log_info "View in console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME"
    echo ""
}

# Save deployment configuration
save_deployment_config() {
    CONFIG_FILE=".cloudrun_deploy_${SERVICE_NAME}.conf"
    
    cat > $CONFIG_FILE << EOF
# Cloud Run Deployment Configuration
# Service: $SERVICE_NAME
# Generated: $(date)

PROJECT_ID=$PROJECT_ID
REGION=$REGION
SERVICE_NAME=$SERVICE_NAME
IMAGE_URL=$IMAGE_URL
PORT=$PORT
MEMORY=$MEMORY
CPU=$CPU
CONCURRENCY=$CONCURRENCY
MIN_INSTANCES=$MIN_INSTANCES
MAX_INSTANCES=$MAX_INSTANCES
TIMEOUT=$TIMEOUT
ALLOW_UNAUTH=$ALLOW_UNAUTH
SERVICE_URL=$SERVICE_URL
DOCKERFILE_PATH=$DOCKERFILE_PATH
BUILD_CONTEXT=$BUILD_CONTEXT
EOF
    
    log_success "Configuration saved to: $CONFIG_FILE"
}

# Choose build mode (Docker vs Source)
choose_build_mode() {
    if [[ "$NON_INTERACTIVE" == "true" || "$DRY_RUN" == "true" ]]; then
        BUILD_FROM_SOURCE=false
        SOURCE_PATH=.
        log_info "Non-interactive/dry-run: using local Docker build mode"
        return
    fi
    echo ""
    log_info "Build options:"
    options=("Build locally with Docker" "Build from source using Cloud Build (no Dockerfile required)")
    select opt in "${options[@]}"; do
        case $opt in
            "Build locally with Docker")
                BUILD_FROM_SOURCE=false
                
                # Ask for Dockerfile only if using Docker build
                echo ""
                read -p "Enter path to Dockerfile (default: ./Dockerfile): " DOCKERFILE_PATH
                DOCKERFILE_PATH=${DOCKERFILE_PATH:-./Dockerfile}
                
                if [ ! -f "$DOCKERFILE_PATH" ]; then
                    log_warning "Dockerfile not found at: $DOCKERFILE_PATH"
                    if confirm "Do you want to generate a sample Dockerfile?" "y"; then
                        generate_dockerfile_interactive
                    else
                        log_error "Cannot proceed without a Dockerfile"
                        exit 1
                    fi
                fi
                
                # Build context
                read -p "Enter build context directory (default: .): " BUILD_CONTEXT
                BUILD_CONTEXT=${BUILD_CONTEXT:-.}
                
                # Image registry choice (only for Docker builds)
                echo ""
                log_info "Choose container registry:"
                options_registry=("Google Artifact Registry (recommended)" "Google Container Registry (gcr.io)")
                select opt_registry in "${options_registry[@]}"; do
                    case $opt_registry in
                        "Google Artifact Registry (recommended)")
                            read -p "Enter Artifact Registry repository name (default: cloud-run-apps): " AR_REPO
                            AR_REPO=${AR_REPO:-cloud-run-apps}
                            IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"
                            
                            # Check if repository exists, create if not
                            if ! gcloud artifacts repositories describe $AR_REPO --location=$REGION &>/dev/null; then
                                log_warning "Artifact Registry repository '$AR_REPO' not found"
                                if confirm "Create repository?" "y"; then
                                    log_info "Creating Artifact Registry repository..."
                                    gcloud artifacts repositories create $AR_REPO \
                                        --repository-format=docker \
                                        --location=$REGION \
                                        --description="Docker repository for Cloud Run applications"
                                    log_success "Repository created"
                                else
                                    log_error "Cannot proceed without a repository"
                                    exit 1
                                fi
                            fi
                            break
                            ;;
                        "Google Container Registry (gcr.io)")
                            IMAGE_URL="gcr.io/$PROJECT_ID/$SERVICE_NAME"
                            break
                            ;;
                        *) log_error "Invalid option";;
                    esac
                done
                break
                ;;
            "Build from source using Cloud Build (no Dockerfile required)")
                BUILD_FROM_SOURCE=true
                read -p "Enter source directory (default: .): " SOURCE_PATH
                SOURCE_PATH=${SOURCE_PATH:-.}
                log_info "Cloud Build will automatically detect your app type and containerize it"
                break
                ;;
            *) log_error "Invalid option";;
        esac
    done
    
    # Save checkpoint after build mode selection
    CHECKPOINT_STAGE="build_mode_complete"
    save_checkpoint
}

# Collect advanced deployment options
collect_advanced_options() {
    if [[ "$NON_INTERACTIVE" == "true" || "$DRY_RUN" == "true" ]]; then
        INGRESS=${INGRESS:-all}
        VPC_EGRESS=${VPC_EGRESS:-all-traffic}
        EXEC_ENV=${EXEC_ENV:-gen2}
        SERVICE_ACCOUNT=${SERVICE_ACCOUNT:-}
        LABELS=${LABELS:-}
        ANNOTATIONS=${ANNOTATIONS:-}
        REV_TAG=${REV_TAG:-}
        NO_TRAFFIC=false
        REV_SUFFIX=${REV_SUFFIX:-}
        log_info "Non-interactive/dry-run: using default advanced options"
        return
    fi
    echo ""
    log_step "Advanced deployment options"
    
    # Ingress
    echo ""
    log_info "Ingress options: all, internal, internal-and-cloud-load-balancing"
    read -p "Ingress setting (default: all): " INGRESS
    INGRESS=${INGRESS:-all}
    
    # VPC Egress
    echo ""
    log_info "VPC egress options: all-traffic, private-ranges-only"
    read -p "VPC egress (default: all-traffic): " VPC_EGRESS
    VPC_EGRESS=${VPC_EGRESS:-all-traffic}
    
    # Execution environment
    echo ""
    log_info "Execution environment: gen2 is recommended"
    read -p "Execution environment (gen1/gen2, default: gen2): " EXEC_ENV
    EXEC_ENV=${EXEC_ENV:-gen2}
    
    # Service account
    echo ""
    read -p "Service Account email to run as (leave blank to use default): " SERVICE_ACCOUNT
    
    # Labels
    echo ""
    read -p "Add labels? (comma-separated key=value, leave blank to skip): " LABELS
    
    # Annotations
    echo ""
    read -p "Add annotations? (comma-separated key=value, leave blank to skip): " ANNOTATIONS
    
    # Tags
    echo ""
    read -p "Add a URL tag for this revision? (e.g., blue, canary) leave blank to skip: " REV_TAG
    
    # No-traffic flag
    echo ""
    if confirm "Deploy with no traffic?" "n"; then
        NO_TRAFFIC=true
    else
        NO_TRAFFIC=false
    fi
    
    # Optional revision suffix
    read -p "Revision suffix (leave blank to auto-generate): " REV_SUFFIX
    REV_SUFFIX=${REV_SUFFIX:-}
    
    # Save checkpoint after advanced options
    CHECKPOINT_STAGE="advanced_options_complete"
    save_checkpoint
}

# Main execution
main() {
    print_banner "GCP Cloud Run - Deployment Script" "Build, Push, and Deploy Your Application"
    
    CHECK_DOCKER=true
    check_prerequisites
    
    # Try to load checkpoint first (most recent session)
    if [ "$SKIP_CONFIRMATIONS" = false ] && load_checkpoint; then
        # Checkpoint loaded, CONFIG_LOADED is set to true
        :
    elif [ -n "$CONFIG_FILE" ]; then
        load_config "$CONFIG_FILE"
    elif [ "$SKIP_CONFIRMATIONS" = false ]; then
        find_and_load_config
    fi

    if [ "${CONFIG_LOADED:-false}" = false ]; then
        get_project_config
        CHECKPOINT_STAGE="project_config_complete"
        save_checkpoint
        
        get_app_config
        choose_build_mode
        collect_advanced_options
    fi
    
    # Summary
    echo ""
    log_info "════════════════════════════════════════════════════════════════"
    log_info "Deployment Summary"
    log_info "════════════════════════════════════════════════════════════════"
    echo "  Project:          $PROJECT_ID"
    echo "  Region:           $REGION"
    echo "  Service:          $SERVICE_NAME"
    if [ "$BUILD_FROM_SOURCE" = true ]; then
        echo "  Build Method:     Cloud Build (from source)"
        echo "  Source Path:      $SOURCE_PATH"
    else
        echo "  Build Method:     Docker (local)"
        echo "  Image:            $IMAGE_URL"
    fi
    echo "  Port:             $PORT"
    echo "  Memory:           $MEMORY"
    echo "  CPU:              $CPU"
    echo "  Min Instances:    $MIN_INSTANCES"
    echo "  Max Instances:    $MAX_INSTANCES"
    echo "  Public Access:    $ALLOW_UNAUTH"
    log_info "════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ "$SKIP_CONFIRMATIONS" = false ] && ! confirm "Proceed with deployment?" "y"; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    echo ""
    if [ "$BUILD_FROM_SOURCE" = false ]; then
        configure_docker_auth
        build_image
        push_image
    fi
    
    deploy_to_cloudrun
    
    get_service_url
    
    save_deployment_config
    
    # Test the service
    echo ""
    if [ "$SKIP_CONFIRMATIONS" = false ] && confirm "Do you want to test the service now?" "y"; then
        log_info "Testing service..."
        echo ""
        curl -i $SERVICE_URL
        echo ""
    fi
    
    # Clear checkpoint on success
    clear_checkpoint
    
    log_success "All done! 🚀"
}

# Run main function
main "$@"
