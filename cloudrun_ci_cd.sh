#!/bin/bash

################################################################################
# GCP Cloud Run CI/CD Setup Script
# This script helps setup CI/CD pipelines for Cloud Run using Cloud Build
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

# Get project configuration
get_project_config() {
    log_step "Getting project configuration..."
    
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        gcloud projects list
        read -p "Enter Project ID: " PROJECT_ID
        gcloud config set project $PROJECT_ID
    fi
    
    PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
    
    log_success "Project: $PROJECT_ID"
    echo ""
}

# Enable required APIs
enable_apis() {
    log_step "Enabling required APIs..."
    
    APIS=(
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "containerregistry.googleapis.com"
        "artifactregistry.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "iamcredentials.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable $api --project=$PROJECT_ID
    done
    
    log_success "All APIs enabled"
    echo ""
}

# Grant Cloud Build permissions
grant_cloudbuild_permissions() {
    log_step "Granting Cloud Build permissions..."
    
    CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
    
    # Grant Cloud Run Admin role
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${CLOUDBUILD_SA}" \
        --role="roles/run.admin" \
        --quiet
    
    # Grant Service Account User role
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${CLOUDBUILD_SA}" \
        --role="roles/iam.serviceAccountUser" \
        --quiet
    
    log_success "Permissions granted to Cloud Build service account"
    echo ""
}

# Create Cloud Build configuration
create_cloudbuild_config() {
    log_step "Creating Cloud Build configuration..."
    echo ""
    
    read -p "Enter service name: " SERVICE_NAME
    read -p "Enter region (default: us-central1): " REGION
    REGION=${REGION:-us-central1}
    
    echo ""
    log_info "Select registry type:"
    options=("Artifact Registry (recommended)" "Google Container Registry (gcr.io)")
    select opt in "${options[@]}"; do
        case $opt in
            "Artifact Registry (recommended)")
                read -p "Enter Artifact Registry repository (default: cloud-run-apps): " AR_REPO
                AR_REPO=${AR_REPO:-cloud-run-apps}
                IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"
                
                # Create repository if it doesn't exist
                if ! gcloud artifacts repositories describe $AR_REPO --location=$REGION &>/dev/null; then
                    log_info "Creating Artifact Registry repository..."
                    gcloud artifacts repositories create $AR_REPO \
                        --repository-format=docker \
                        --location=$REGION \
                        --description="Cloud Run applications" \
                        --project=$PROJECT_ID
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
    
    echo ""
    log_info "CI/CD trigger options:"
    trigger_options=("Manual trigger" "GitHub trigger" "Cloud Source Repositories trigger" "Bitbucket trigger")
    select trigger_opt in "${trigger_options[@]}"; do
        case $trigger_opt in
            "Manual trigger")
                trigger_type=1
                break
                ;;
            "GitHub trigger")
                trigger_type=2
                break
                ;;
            "Cloud Source Repositories trigger")
                trigger_type=3
                break
                ;;
            "Bitbucket trigger")
                trigger_type=4
                break
                ;;
            *) log_error "Invalid option";;
        esac
    done
    
    # Generate cloudbuild.yaml
    cat > cloudbuild.yaml << EOF
# Cloud Build configuration for $SERVICE_NAME
steps:
  # Build the container image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '$IMAGE_URL:\$SHORT_SHA', '-t', '$IMAGE_URL:latest', '.']
  
  # Push the container image to registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', '$IMAGE_URL:\$SHORT_SHA']
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', '$IMAGE_URL:latest']
  
  # Deploy container image to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - '$SERVICE_NAME'
      - '--image=$IMAGE_URL:\$SHORT_SHA'
      - '--region=$REGION'
      - '--platform=managed'
      - '--allow-unauthenticated'

images:
  - '$IMAGE_URL:\$SHORT_SHA'
  - '$IMAGE_URL:latest'

options:
  machineType: 'N1_HIGHCPU_8'
  logging: CLOUD_LOGGING_ONLY

timeout: '1600s'
EOF
    
    log_success "Created: cloudbuild.yaml"
    
    # Create trigger based on selection
    case $trigger_type in
        1)
            create_manual_trigger
            ;;
        2)
            create_github_trigger
            ;;
        3)
            create_csr_trigger
            ;;
        4)
            create_bitbucket_trigger
            ;;
        *)
            log_warning "Invalid selection. cloudbuild.yaml created but no trigger set up."
            ;;
    esac
    
    echo ""
}

# Create manual trigger
create_manual_trigger() {
    log_info "Manual trigger setup"
    log_info "Run builds with: gcloud builds submit --config=cloudbuild.yaml"
}

# Create GitHub trigger
create_github_trigger() {
    echo ""
    log_info "GitHub trigger setup"
    echo ""
    
    read -p "Enter GitHub repository owner: " GITHUB_OWNER
    read -p "Enter GitHub repository name: " GITHUB_REPO
    read -p "Enter branch pattern (default: ^main$): " BRANCH_PATTERN
    BRANCH_PATTERN=${BRANCH_PATTERN:-^main$}
    
    TRIGGER_NAME="${SERVICE_NAME}-github-trigger"
    
    # First, connect the repository
    log_info "Please connect your GitHub repository in Cloud Console:"
    echo "https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID"
    echo ""
    read -p "Press Enter after connecting the repository..."
    
    # Create trigger
    gcloud builds triggers create github \
        --name=$TRIGGER_NAME \
        --repo-name=$GITHUB_REPO \
        --repo-owner=$GITHUB_OWNER \
        --branch-pattern=$BRANCH_PATTERN \
        --build-config=cloudbuild.yaml \
        --project=$PROJECT_ID
    
    log_success "GitHub trigger created: $TRIGGER_NAME"
}

# Create Cloud Source Repository trigger
create_csr_trigger() {
    echo ""
    log_info "Cloud Source Repository trigger setup"
    echo ""
    
    read -p "Enter repository name: " REPO_NAME
    read -p "Enter branch pattern (default: ^main$): " BRANCH_PATTERN
    BRANCH_PATTERN=${BRANCH_PATTERN:-^main$}
    
    TRIGGER_NAME="${SERVICE_NAME}-csr-trigger"
    
    gcloud builds triggers create cloud-source-repositories \
        --name=$TRIGGER_NAME \
        --repo=$REPO_NAME \
        --branch-pattern=$BRANCH_PATTERN \
        --build-config=cloudbuild.yaml \
        --project=$PROJECT_ID
    
    log_success "Cloud Source Repository trigger created: $TRIGGER_NAME"
}

# Create Bitbucket trigger
create_bitbucket_trigger() {
    echo ""
    log_info "Bitbucket trigger setup"
    echo ""
    
    log_info "Please connect your Bitbucket repository in Cloud Console:"
    echo "https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID"
    echo ""
    read -p "Press Enter after connecting the repository..."
    
    read -p "Enter Bitbucket repository: " BITBUCKET_REPO
    read -p "Enter branch pattern (default: ^main$): " BRANCH_PATTERN
    BRANCH_PATTERN=${BRANCH_PATTERN:-^main$}
    
    TRIGGER_NAME="${SERVICE_NAME}-bitbucket-trigger"
    
    # Note: This requires the repository to be connected first
    log_warning "Please create the trigger manually in Cloud Console with the generated cloudbuild.yaml"
    echo "https://console.cloud.google.com/cloud-build/triggers/add?project=$PROJECT_ID"
}

# Create advanced cloudbuild.yaml with tests
create_advanced_cloudbuild() {
    log_step "Creating advanced Cloud Build configuration..."
    echo ""
    
    read -p "Enter service name: " SERVICE_NAME
    read -p "Enter region (default: us-central1): " REGION
    REGION=${REGION:-us-central1}
    
    IMAGE_URL="gcr.io/$PROJECT_ID/$SERVICE_NAME"
    
    cat > cloudbuild.yaml << 'EOF'
# Advanced Cloud Build configuration with testing and multi-environment support
substitutions:
  _SERVICE_NAME: 'my-service'
  _REGION: 'us-central1'
  _DEPLOY_ENV: 'production'

steps:
  # Install dependencies and run tests
  - name: 'gcr.io/cloud-builders/npm'
    id: 'install-deps'
    args: ['install']
    
  - name: 'gcr.io/cloud-builders/npm'
    id: 'run-tests'
    args: ['test']
    waitFor: ['install-deps']
  
  - name: 'gcr.io/cloud-builders/npm'
    id: 'run-lint'
    args: ['run', 'lint']
    waitFor: ['install-deps']
  
  # Build the container image
  - name: 'gcr.io/cloud-builders/docker'
    id: 'build-image'
    args: [
      'build',
      '-t', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:$SHORT_SHA',
      '-t', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:latest',
      '--build-arg', 'BUILD_ENV=${_DEPLOY_ENV}',
      '.'
    ]
    waitFor: ['run-tests', 'run-lint']
  
  # Run security scan
  - name: 'gcr.io/cloud-builders/gcloud'
    id: 'scan-image'
    args: [
      'container',
      'images',
      'scan',
      'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:$SHORT_SHA'
    ]
    waitFor: ['build-image']
  
  # Push the container image
  - name: 'gcr.io/cloud-builders/docker'
    id: 'push-image'
    args: ['push', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:$SHORT_SHA']
    waitFor: ['scan-image']
  
  - name: 'gcr.io/cloud-builders/docker'
    id: 'push-latest'
    args: ['push', 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:latest']
    waitFor: ['scan-image']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    id: 'deploy'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - '${_SERVICE_NAME}'
      - '--image=gcr.io/$PROJECT_ID/${_SERVICE_NAME}:$SHORT_SHA'
      - '--region=${_REGION}'
      - '--platform=managed'
      - '--allow-unauthenticated'
      - '--set-env-vars=DEPLOY_ENV=${_DEPLOY_ENV},BUILD_ID=$BUILD_ID,SHORT_SHA=$SHORT_SHA'
    waitFor: ['push-image']
  
  # Run smoke tests
  - name: 'gcr.io/cloud-builders/curl'
    id: 'smoke-test'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        SERVICE_URL=$(gcloud run services describe ${_SERVICE_NAME} --region=${_REGION} --format='value(status.url)')
        echo "Testing service at: $SERVICE_URL"
        curl -f $SERVICE_URL/health || exit 1
    waitFor: ['deploy']

images:
  - 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:$SHORT_SHA'
  - 'gcr.io/$PROJECT_ID/${_SERVICE_NAME}:latest'

options:
  machineType: 'N1_HIGHCPU_8'
  logging: CLOUD_LOGGING_ONLY

timeout: '2400s'
EOF
    
    log_success "Created: cloudbuild.yaml (advanced configuration)"
    echo ""
}

# Create deployment configuration files
create_deployment_configs() {
    log_step "Creating deployment configuration files..."
    
    # Create .env.example
    cat > .env.example << 'EOF'
# Environment Variables Template
# Copy this to .env and fill in your values

PROJECT_ID=your-project-id
REGION=us-central1
SERVICE_NAME=your-service-name

# Application Config
PORT=8080
NODE_ENV=production

# Database (if applicable)
DATABASE_URL=
DATABASE_NAME=

# API Keys
API_KEY=

# Feature Flags
ENABLE_FEATURE_X=false
EOF
    
    log_success "Created: .env.example"
    
    # Create .gcloudignore
    cat > .gcloudignore << 'EOF'
# This file specifies files that are *not* uploaded to Google Cloud
# using gcloud. It follows the same syntax as .gitignore

.gcloudignore
.git
.gitignore
node_modules/
__pycache__/
*.pyc
.pytest_cache/
.venv/
venv/
*.log
.env
.env.local
*.swp
.DS_Store
README.md
tests/
*.test.js
*.spec.js
coverage/
docs/
.github/
EOF
    
    log_success "Created: .gcloudignore"
    
    # Create deployment script
    cat > deploy.sh << 'EOF'
#!/bin/bash
# Quick deployment script
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}

echo "Deploying to environment: $ENVIRONMENT"

# Load environment-specific variables
if [ -f ".env.$ENVIRONMENT" ]; then
    source ".env.$ENVIRONMENT"
else
    echo "Warning: .env.$ENVIRONMENT not found"
fi

# Submit build to Cloud Build
gcloud builds submit \
    --config=cloudbuild.yaml \
    --substitutions=_DEPLOY_ENV=$ENVIRONMENT

echo "Deployment complete!"
EOF
    
    chmod +x deploy.sh
    log_success "Created: deploy.sh"
    
    echo ""
}

# Test Cloud Build locally
test_cloudbuild_locally() {
    log_step "Testing Cloud Build configuration locally..."
    echo ""
    
    if ! command -v cloud-build-local &> /dev/null; then
        log_warning "cloud-build-local is not installed"
        log_info "Install with: gcloud components install cloud-build-local"
        if confirm "Do you want to install it now?" "y"; then
            gcloud components install cloud-build-local
        else
            return 0
        fi
    fi
    
    log_info "Running local build..."
    cloud-build-local --config=cloudbuild.yaml --dryrun=false .
    
    log_success "Local build test completed"
    echo ""
}

# Create Makefile with common Cloud Run targets
create_makefile() {
    log_step "Creating Makefile..."
    cat > Makefile << 'EOF'
# Makefile for Cloud Run
# Usage: make cloudrun-deploy SERVICE=my-service REGION=us-central1

SERVICE ?= my-service
REGION  ?= us-central1
PROJECT ?= $(shell gcloud config get-value project 2>/dev/null)

# Non-interactive deploy with defaults (edit scripts or pass vars via env/config)
cloudrun-deploy:
	NON_INTERACTIVE=true ./deploy_to_cloudrun.sh --yes

cloudrun-deploy-source:
	NON_INTERACTIVE=true ./deploy_to_cloudrun.sh --yes

cloudrun-setup:
	./setup_gcp_environment.sh

cloudrun-logs:
	gcloud run logs tail $(SERVICE) --region=$(REGION) --project=$(PROJECT)

cloudrun-manage:
	./manage_cloudrun.sh

cloudrun-ci:
	gcloud builds submit --config=cloudbuild.yaml --project=$(PROJECT)

cloudrun-clean:
	@echo "Cleaning old revisions for $(SERVICE) ..."
	@./manage_cloudrun.sh || true

cloudrun-domain-map:
	@echo "Use manage script to create/list/delete domain mappings"
	@./manage_cloudrun.sh || true

.PHONY: cloudrun-deploy cloudrun-deploy-source cloudrun-setup cloudrun-logs cloudrun-manage cloudrun-ci cloudrun-clean cloudrun-domain-map
EOF
    log_success "Created: Makefile"
}

# Create GitHub Actions workflow
create_github_actions() {
    log_step "Creating GitHub Actions workflow..."
    echo ""
    
    read -p "Enter service name: " SERVICE_NAME
    read -p "Enter region (default: us-central1): " REGION
    REGION=${REGION:-us-central1}
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/deploy-to-cloudrun.yml << EOF
name: Deploy to Cloud Run

on:
  push:
    branches:
      - main
      - '**'
  pull_request:
    branches:
      - '**'
  workflow_dispatch:

env:
  PROJECT_ID: \\${{ secrets.GCP_PROJECT_ID }}
  SERVICE_NAME: $SERVICE_NAME
  REGION: $REGION
  GAR_LOCATION: $REGION

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud (OIDC)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \\${{ secrets.WIF_PROVIDER }}
          service_account: \\${{ secrets.WIF_SERVICE_ACCOUNT }}

      - name: Setup gcloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker \\${{ env.GAR_LOCATION }}-docker.pkg.dev --quiet

      - name: Compute image name
        id: meta
        run: |
          BRANCH="\\${{ github.ref_name }}"
          SAFE_BRANCH=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-')
          echo "branch=$BRANCH" >> $GITHUB_OUTPUT
          echo "safe_branch=$SAFE_BRANCH" >> $GITHUB_OUTPUT
          echo "image=\\${{ env.GAR_LOCATION }}-docker.pkg.dev/\\${{ env.PROJECT_ID }}/cloud-run-source-deploy/\\${{ env.SERVICE_NAME }}:\\${{ github.sha }}" >> $GITHUB_OUTPUT

      - name: Build and push image
        run: |
          docker build -t "\\${{ steps.meta.outputs.image }}" .
          docker push "\\${{ steps.meta.outputs.image }}"

      - name: Deploy to Cloud Run
        id: deploy
        uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: \\${{ env.SERVICE_NAME }}
          region: \\${{ env.REGION }}
          image: "\\${{ steps.meta.outputs.image }}"
          flags: >-
            --execution-environment=gen2
            --ingress=all
            --concurrency=80
            --memory=512Mi

      - name: Output service URL
        run: echo "Service URL: \\${{ steps.deploy.outputs.url }}"
EOF
    
    log_success "Created: .github/workflows/deploy-to-cloudrun.yml"
    echo ""
    
    log_info "Next steps for GitHub Actions (OIDC):"
    echo "  1. Create a Workload Identity Federation Pool and Provider in GCP."
    echo "  2. Create a GCP service account and grant it 'roles/run.admin', 'roles/iam.serviceAccountUser', and 'roles/storage.admin'."
    echo "  3. Allow the GitHub Action to impersonate the service account."
    echo "  4. Add the WIF_PROVIDER and WIF_SERVICE_ACCOUNT as secrets in your GitHub repository."
    echo ""
}

# Show summary and next steps
show_summary() {
    log_success "════════════════════════════════════════════════════════════════"
    log_success "CI/CD Setup Complete!"
    log_success "════════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "Files created:"
    [ -f "cloudbuild.yaml" ] && echo "  - cloudbuild.yaml"
    [ -f ".env.example" ] && echo "  - .env.example"
    [ -f ".gcloudignore" ] && echo "  - .gcloudignore"
    [ -f "deploy.sh" ] && echo "  - deploy.sh"
    [ -f ".github/workflows/deploy-to-cloudrun.yml" ] && echo "  - .github/workflows/deploy-to-cloudrun.yml"
    echo ""
    
    log_info "Next steps:"
    echo "  1. Review and customize the generated configuration files."
    echo "  2. Commit and push changes to your repository to trigger the pipeline."
    echo "  3. Monitor builds in the Google Cloud Console."
    echo ""
}

# Main execution
main() {
    print_banner "GCP Cloud Run - CI/CD Setup Script" "Automate Build and Deployment"
    
    check_prerequisites
    get_project_config
    
    while true; do
        echo ""
        log_info "CI/CD Setup Menu"
        
        options=(
            "Basic Cloud Build setup"
            "Advanced Cloud Build setup (with tests)"
            "Create GitHub Actions workflow (OIDC)"
            "Create Makefile"
            "Create deployment configuration files"
            "Test Cloud Build locally"
            "Grant Cloud Build permissions"
            "Complete setup (all of the above)"
            "Exit"
        )
        
        select opt in "${options[@]}"; do
            case $opt in
                "Basic Cloud Build setup")
                    enable_apis
                    grant_cloudbuild_permissions
                    create_cloudbuild_config
                    create_deployment_configs
                    show_summary
                    break
                    ;;
                "Advanced Cloud Build setup (with tests)")
                    enable_apis
                    grant_cloudbuild_permissions
                    create_advanced_cloudbuild
                    create_deployment_configs
                    show_summary
                    break
                    ;;
                "Create GitHub Actions workflow (OIDC)")
                    enable_apis
                    create_github_actions
                    break
                    ;;
                "Create Makefile")
                    create_makefile
                    break
                    ;;
                "Create deployment configuration files")
                    create_deployment_configs
                    break
                    ;;
                "Test Cloud Build locally")
                    test_cloudbuild_locally
                    break
                    ;;
                "Grant Cloud Build permissions")
                    grant_cloudbuild_permissions
                    break
                    ;;
                "Complete setup (all of the above)")
                    enable_apis
                    grant_cloudbuild_permissions
                    create_cloudbuild_config
                    create_deployment_configs
                    create_makefile
                    create_github_actions
                    show_summary
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
    done
}

# Run main function
main "$@"
