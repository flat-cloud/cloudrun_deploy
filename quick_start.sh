#!/bin/bash

################################################################################
# GCP Cloud Run - Quick Start Script
# This script provides a guided quick start experience
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

show_welcome() {
    print_banner "GCP Cloud Run - Quick Start Guide"
    echo ""
    log_info "Welcome to the GCP Cloud Run Quick Start!"
    echo ""
    echo "This script will guide you through:"
    echo "  1. Environment setup"
    echo "  2. Application deployment"
    echo "  3. Service management"
    echo ""
    echo "Estimated time: 10-20 minutes"
    echo ""
    read -p "Press Enter to continue..."
}

check_status() {
    echo ""
    log_step "Checking current setup status..."
    echo ""
    
    # Check Docker
    if command -v docker &> /dev/null; then
        log_success "✓ Docker is installed"
        DOCKER_OK=true
    else
        log_warning "✗ Docker is not installed"
        DOCKER_OK=false
    fi
    
    # Check gcloud
    if command -v gcloud &> /dev/null; then
        log_success "✓ gcloud SDK is installed"
        GCLOUD_OK=true
    else
        log_warning "✗ gcloud SDK is not installed"
        GCLOUD_OK=false
    fi
    
    # Check authentication
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
        ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
        log_success "✓ Authenticated as: $ACCOUNT"
        AUTH_OK=true
    else
        log_warning "✗ Not authenticated with GCP"
        AUTH_OK=false
    fi
    
    # Check project
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ ! -z "$PROJECT_ID" ] && [ "$PROJECT_ID" != "(unset)" ]; then
        log_success "✓ Project configured: $PROJECT_ID"
        PROJECT_OK=true
    else
        log_warning "✗ No project configured"
        PROJECT_OK=false
    fi
    
    echo ""
    
    if [ "$DOCKER_OK" = true ] && [ "$GCLOUD_OK" = true ] && [ "$AUTH_OK" = true ] && [ "$PROJECT_OK" = true ]; then
        log_success "Your environment is ready!"
        return 0
    else
        log_warning "Some setup is required"
        return 1
    fi
}

run_setup() {
    echo ""
    log_step "Running environment setup..."
    echo ""
    
    if [ -f "setup_gcp_environment.sh" ]; then
        chmod +x setup_gcp_environment.sh
        ./setup_gcp_environment.sh
    else
        log_error "Setup script not found: setup_gcp_environment.sh"
        exit 1
    fi
}

run_deployment() {
    echo ""
    log_step "Running deployment..."
    echo ""
    
    if [ -f "deploy_to_cloudrun.sh" ]; then
        chmod +x deploy_to_cloudrun.sh
        ./deploy_to_cloudrun.sh
    else
        log_error "Deployment script not found: deploy_to_cloudrun.sh"
        exit 1
    fi
}

show_next_steps() {
    echo ""
    log_success "════════════════════════════════════════════════════════════════"
    log_success "Quick Start Complete!"
    log_success "════════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "What you can do next:"
    echo ""
    echo "📊 Manage your service:"
    echo "   ./manage_cloudrun.sh"
    echo ""
    echo "🔄 Setup CI/CD pipeline:"
    echo "   ./cloudrun_ci_cd.sh"
    echo ""
    echo "📖 Read the full guide:"
    echo "   cat README_cloudrun.md"
    echo ""
    echo "🌐 View in Cloud Console:"
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    echo "   https://console.cloud.google.com/run?project=$PROJECT_ID"
    echo ""
    
    log_info "Useful commands:"
    echo "   gcloud run services list"
    echo "   gcloud run logs tail SERVICE_NAME"
    echo "   gcloud run services describe SERVICE_NAME"
    echo ""
}

main() {
    show_welcome
    
    if check_status; then
        echo ""
        log_info "Your environment is already configured."
        if confirm "Do you want to deploy an application now?" "y"; then
            run_deployment
        fi
    else
        echo ""
        if confirm "Do you want to run the setup now?" "y"; then
            run_setup
            
            echo ""
            if confirm "Setup complete! Deploy an application now?" "y"; then
                run_deployment
            fi
        else
            log_info "You can run the setup manually:"
            echo "   ./setup_gcp_environment.sh"
            exit 0
        fi
    fi
    
    show_next_steps
}

main "$@"
