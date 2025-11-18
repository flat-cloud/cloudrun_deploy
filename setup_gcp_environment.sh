#!/bin/bash

################################################################################
# GCP Environment Setup Script
# This script installs and configures all dependencies for GCP Cloud Run deployment
# including GCloud SDK, Docker, and other required tools
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    log_info "Detected OS: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker
install_docker() {
    log_info "Checking Docker installation..."
    
    if command_exists docker; then
        log_success "Docker is already installed: $(docker --version)"
        return 0
    fi
    
    log_warning "Docker not found. Installing Docker..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            log_warning "You may need to log out and log back in for docker group changes to take effect"
            ;;
            
        centos|rhel|fedora)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
            
        macos)
            log_warning "Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop"
            log_info "Or install via Homebrew: brew install --cask docker"
            read -p "Press enter after installing Docker Desktop..."
            ;;
            
        *)
            log_error "Unsupported OS for automatic Docker installation"
            log_info "Please install Docker manually from: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
    
    if command_exists docker; then
        log_success "Docker installed successfully: $(docker --version)"
    else
        log_error "Docker installation failed"
        exit 1
    fi
}

# Install gcloud SDK
install_gcloud() {
    log_info "Checking Google Cloud SDK installation..."
    
    if command_exists gcloud; then
        log_success "gcloud SDK is already installed: $(gcloud --version | head -n 1)"
        return 0
    fi
    
    log_warning "gcloud SDK not found. Installing..."
    
    case $OS in
        ubuntu|debian)
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg
            echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y google-cloud-sdk
            ;;
            
        centos|rhel|fedora)
            sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
            sudo yum install -y google-cloud-sdk
            ;;
            
        macos)
            if command_exists brew; then
                brew install --cask google-cloud-sdk
            else
                log_info "Installing via curl method..."
                curl https://sdk.cloud.google.com | bash
                exec -l $SHELL
            fi
            ;;
            
        *)
            log_info "Installing via curl method..."
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
            ;;
    esac
    
    if command_exists gcloud; then
        log_success "gcloud SDK installed successfully"
    else
        log_error "gcloud SDK installation failed"
        exit 1
    fi
}

# Install additional tools
install_additional_tools() {
    log_info "Installing additional tools..."
    
    # Install jq for JSON parsing
    if ! command_exists jq; then
        case $OS in
            ubuntu|debian)
                sudo apt-get install -y jq
                ;;
            centos|rhel|fedora)
                sudo yum install -y jq
                ;;
            macos)
                if command_exists brew; then
                    brew install jq
                fi
                ;;
        esac
    fi
    
    # Install git
    if ! command_exists git; then
        case $OS in
            ubuntu|debian)
                sudo apt-get install -y git
                ;;
            centos|rhel|fedora)
                sudo yum install -y git
                ;;
            macos)
                if command_exists brew; then
                    brew install git
                fi
                ;;
        esac
    fi
    
    # Install curl
    if ! command_exists curl; then
        case $OS in
            ubuntu|debian)
                sudo apt-get install -y curl
                ;;
            centos|rhel|fedora)
                sudo yum install -y curl
                ;;
        esac
    fi
    
    log_success "Additional tools installed"
}

# Configure gcloud
configure_gcloud() {
    log_info "Configuring Google Cloud SDK..."
    
    echo ""
    if confirm "Do you want to authenticate with GCP now?" "y"; then
        gcloud auth login
        log_success "Authentication completed"
        
        echo ""
        if confirm "Do you want to set a default project?" "y"; then
            echo ""
            log_info "Available projects:"
            gcloud projects list
            echo ""
            read -p "Enter project ID: " project_id
            gcloud config set project $project_id
            log_success "Default project set to: $project_id"
        fi
        
        echo ""
        if confirm "Do you want to set a default region?" "y"; then
            echo ""
            log_info "Common regions:"
            echo "  - us-central1 (Iowa)"
            echo "  - us-east1 (South Carolina)"
            echo "  - us-west1 (Oregon)"
            echo "  - europe-west1 (Belgium)"
            echo "  - asia-east1 (Taiwan)"
            echo "  - australia-southeast1 (Sydney)"
            echo ""
            read -p "Enter region (e.g., us-central1): " region
            gcloud config set run/region $region
            log_success "Default region set to: $region"
        fi
    else
        log_info "Skipping authentication. You can run 'gcloud auth login' later."
    fi
}

# Enable required GCP APIs
enable_gcp_apis() {
    log_info "Checking GCP APIs..."
    
    if ! command_exists gcloud; then
        log_warning "gcloud not found, skipping API enablement"
        return 0
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
        log_warning "Not authenticated with GCP. Skipping API enablement."
        log_info "Run 'gcloud auth login' to authenticate."
        return 0
    fi
    
    # Check if project is set
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        log_warning "No project set. Skipping API enablement."
        return 0
    fi
    
    echo ""
    if confirm "Do you want to enable required GCP APIs for Cloud Run?" "y"; then
        log_info "Enabling required APIs..."
        
        APIS=(
            "run.googleapis.com"
            "containerregistry.googleapis.com"
            "cloudbuild.googleapis.com"
            "artifactregistry.googleapis.com"
        )
        
        for api in "${APIS[@]}"; do
            log_info "Enabling $api..."
            gcloud services enable $api --project=$PROJECT_ID
        done
        
        log_success "All required APIs enabled"
    fi
}

# Create configuration file
create_config_file() {
    log_info "Creating configuration file..."
    
    cat > .gcp_cloudrun_config << EOF
# GCP Cloud Run Configuration
# Generated on: $(date)

# System Information
OS=$OS
DOCKER_VERSION=$(docker --version 2>/dev/null || echo "not installed")
GCLOUD_VERSION=$(gcloud --version 2>/dev/null | head -n 1 || echo "not installed")

# GCP Configuration
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "not set")
REGION=$(gcloud config get-value run/region 2>/dev/null || echo "not set")
ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "not set")

# Installation Date
INSTALLED_ON=$(date)
EOF
    
    log_success "Configuration saved to .gcp_cloudrun_config"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    echo ""
    
    local all_ok=true
    
    # Check Docker
    if command_exists docker; then
        log_success "✓ Docker: $(docker --version)"
    else
        log_error "✗ Docker: Not found"
        all_ok=false
    fi
    
    # Check gcloud
    if command_exists gcloud; then
        log_success "✓ gcloud: $(gcloud --version | head -n 1)"
    else
        log_error "✗ gcloud: Not found"
        all_ok=false
    fi
    
    # Check jq
    if command_exists jq; then
        log_success "✓ jq: $(jq --version)"
    else
        log_warning "○ jq: Not found (optional)"
    fi
    
    # Check git
    if command_exists git; then
        log_success "✓ git: $(git --version)"
    else
        log_warning "○ git: Not found (optional)"
    fi
    
    echo ""
    if [ "$all_ok" = true ]; then
        log_success "All required tools are installed!"
        return 0
    else
        log_error "Some required tools are missing"
        return 1
    fi
}

# Main execution
main() {
    print_banner "GCP Cloud Run - Environment Setup Script" "Install Dependencies & Configure Environment"
    
    echo ""
    log_info "This script will install and configure:"
    echo "  1. Docker"
    echo "  2. Google Cloud SDK (gcloud)"
    echo "  3. Additional tools (jq, git, curl)"
    echo "  4. GCP Authentication and Configuration"
    echo ""
    
    if ! confirm "Do you want to proceed?" "y"; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    detect_os
    
    echo ""
    install_docker
    
    echo ""
    install_gcloud
    
    echo ""
    install_additional_tools
    
    echo ""
    configure_gcloud
    
    echo ""
    enable_gcp_apis
    
    echo ""
    create_config_file
    
    echo ""
    verify_installation
    
    echo ""
    log_success "════════════════════════════════════════════════════════════════"
    log_success "Setup completed successfully!"
    log_success "════════════════════════════════════════════════════════════════"
    echo ""
    log_info "Next steps:"
    echo "  1. If Docker was just installed, you may need to log out and back in"
    echo "  2. Run the deployment script to deploy your application"
    echo "  3. Check the configuration file: .gcp_cloudrun_config"
    echo ""
}

# Run main function
main
