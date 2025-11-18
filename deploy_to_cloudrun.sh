#!/bin/bash

################################################################################
# GCP Cloud Run Deployment Script
# This script handles the complete deployment process for any application
# to GCP Cloud Run, including building, pushing, and deploying
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

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
        log_error "Service name cannot be empty"
        exit 1
    fi
    
    # Dockerfile location
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
    
    # Image registry choice
    echo ""
    log_info "Choose container registry:"
    options=("Google Artifact Registry (recommended)" "Google Container Registry (gcr.io)")
    select opt in "${options[@]}"; do
        case $opt in
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
                            --description="Cloud Run applications"
                        log_success "Repository created"
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
    
    # Port configuration
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
    if confirm "Do you want to connect to Cloud SQL?" "n"; then
        read -p "Enter Cloud SQL connection string (PROJECT:REGION:INSTANCE): " cloudsql_connection
        if [ ! -z "$cloudsql_connection" ]; then
            CLOUDSQL="--add-cloudsql-instances=$cloudsql_connection"
        fi
    fi
    
    # VPC Connector
    echo ""
    if confirm "Do you want to use a VPC connector?" "n"; then
        read -p "Enter VPC connector name: " vpc_connector
        if [ ! -z "$vpc_connector" ]; then
            VPC_CONNECTOR="--vpc-connector=$vpc_connector"
        fi
    fi
    
    echo ""
}

# Generate sample Dockerfile
generate_dockerfile_interactive() {
    echo ""
    log_info "Select application type:"
    options=("Node.js" "Python" "Go" "Java" ".NET" "Ruby" "PHP" "Cancel")
    select opt in "${options[@]}"; do
        case $opt in
            "Node.js")
                generate_nodejs_dockerfile
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
    echo "$DEPLOY_CMD"
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
    echo ""
    log_info "Build options:"
    options=("Build locally with Docker (current flow)" "Build from source using Cloud Build (no local Docker required)")
    select opt in "${options[@]}"; do
        case $opt in
            "Build locally with Docker (current flow)")
                BUILD_FROM_SOURCE=false
                break
                ;;
            "Build from source using Cloud Build (no local Docker required)")
                BUILD_FROM_SOURCE=true
                read -p "Enter source directory (default: .): " SOURCE_PATH
                SOURCE_PATH=${SOURCE_PATH:-.}
                break
                ;;
            *) log_error "Invalid option";;
        esac
    done
}

# Collect advanced deployment options
collect_advanced_options() {
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
}

# Main execution
main() {
    print_banner "GCP Cloud Run - Deployment Script" "Build, Push, and Deploy Your Application"
    
    CHECK_DOCKER=true
    check_prerequisites
    
    get_project_config
    
    get_app_config
    
    choose_build_mode
    collect_advanced_options
    
    # Summary
    echo ""
    log_info "════════════════════════════════════════════════════════════════"
    log_info "Deployment Summary"
    log_info "════════════════════════════════════════════════════════════════"
    echo "  Project:          $PROJECT_ID"
    echo "  Region:           $REGION"
    echo "  Service:          $SERVICE_NAME"
    echo "  Image:            $IMAGE_URL"
    echo "  Port:             $PORT"
    echo "  Memory:           $MEMORY"
    echo "  CPU:              $CPU"
    echo "  Min Instances:    $MIN_INSTANCES"
    echo "  Max Instances:    $MAX_INSTANCES"
    echo "  Public Access:    $ALLOW_UNAUTH"
    log_info "════════════════════════════════════════════════════════════════"
    echo ""
    
    if ! confirm "Proceed with deployment?" "y"; then
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
    if confirm "Do you want to test the service now?" "y"; then
        log_info "Testing service..."
        echo ""
        curl -i $SERVICE_URL
        echo ""
    fi
    
    log_success "All done! 🚀"
}

# Run main function
main "$@"
