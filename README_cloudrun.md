# GCP Cloud Run Deployment Scripts - Complete Guide

A comprehensive set of interactive bash scripts to prepare, deploy, manage, and automate any application on Google Cloud Run.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Scripts Description](#scripts-description)
- [Detailed Usage](#detailed-usage)
- [Common Use Cases](#common-use-cases)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🎯 Overview

This toolkit provides four comprehensive scripts:

1. **Setup Script** - Install and configure all dependencies
2. **Deployment Script** - Build and deploy applications to Cloud Run
3. **Management Script** - Manage, monitor, and control deployed services
4. **CI/CD Script** - Setup automated pipelines with Cloud Build

## ✅ Prerequisites

- A Google Cloud Platform account
- A project with billing enabled
- Basic knowledge of Docker and containerization
- (Optional) Git for version control

## 🚀 Quick Start

### Step 1: Setup Environment

```bash
chmod +x setup_gcp_environment.sh
./setup_gcp_environment.sh
```

This script will:
- Detect your operating system
- Install Docker
- Install Google Cloud SDK (gcloud)
- Install additional tools (jq, git, curl)
- Configure authentication with GCP
- Enable required APIs
- Set default project and region

### Step 2: Deploy Your Application

```bash
chmod +x deploy_to_cloudrun.sh
./deploy_to_cloudrun.sh
```

The script will interactively guide you through:
- Project and region selection
- Service configuration
- Container registry setup
- Resource allocation
- Environment variables
- Secrets management
- VPC and Cloud SQL connections

### Step 3: Manage Your Service

```bash
chmod +x manage_cloudrun.sh
./manage_cloudrun.sh
```

Interactive menu to:
- List and view services
- Monitor logs and metrics
- Update configurations
- Rollback deployments
- Test endpoints

### Step 4: Setup CI/CD (Optional)

```bash
chmod +x cloudrun_ci_cd.sh
./cloudrun_ci_cd.sh
```

Setup automated deployments with:
- Cloud Build triggers
- GitHub Actions
- Testing pipelines
- Multi-environment support

## 📜 Scripts Description

### 1. Setup Script (`setup_gcp_environment.sh`)

**Purpose**: Install and configure all required dependencies for GCP Cloud Run deployment.

**Features**:
- ✅ OS detection (Linux, macOS, Windows)
- ✅ Docker installation
- ✅ Google Cloud SDK installation
- ✅ Tool verification
- ✅ GCP authentication
- ✅ Project and region configuration
- ✅ API enablement
- ✅ Configuration file generation

**Supported Operating Systems**:
- Ubuntu/Debian
- CentOS/RHEL/Fedora
- macOS
- Windows (WSL/Cygwin)

### 2. Deployment Script (`deploy_to_cloudrun.sh`)

**Purpose**: Complete deployment workflow from build to production.

**Features**:
- ✅ Interactive configuration
- ✅ Dockerfile generation for multiple languages
- ✅ Docker image building
- ✅ Multiple registry support (GCR, Artifact Registry)
- ✅ Environment variables management
- ✅ Secrets integration (Secret Manager)
- ✅ Cloud SQL connection
- ✅ VPC connector support
- ✅ Resource configuration (CPU, memory, scaling)
- ✅ IAM policy management
- ✅ Deployment testing
- ✅ Configuration persistence

**Supported Languages**:
- Node.js
- Python
- Go
- Java
- .NET
- Ruby
- PHP

### 3. Management Script (`manage_cloudrun.sh`)

**Purpose**: Comprehensive service management and monitoring.

**Features**:
- ✅ Service listing and details
- ✅ Real-time log viewing
- ✅ Configuration updates
- ✅ Traffic splitting
- ✅ Revision rollback
- ✅ Service deletion
- ✅ Metrics monitoring
- ✅ Configuration export
- ✅ Endpoint testing
- ✅ IAM policy management

### 4. CI/CD Script (`cloudrun_ci_cd.sh`)

**Purpose**: Automated build and deployment pipelines.

**Features**:
- ✅ Cloud Build configuration
- ✅ GitHub integration
- ✅ Cloud Source Repositories
- ✅ Bitbucket integration
- ✅ GitHub Actions workflow
- ✅ Automated testing
- ✅ Security scanning
- ✅ Multi-environment support
- ✅ Smoke tests
- ✅ Local testing

## 📖 Detailed Usage

### Environment Setup

```bash
# Run the setup script
./setup_gcp_environment.sh

# Follow the interactive prompts:
# 1. Confirm installation
# 2. Wait for tools installation
# 3. Authenticate with GCP
# 4. Set default project
# 5. Set default region
# 6. Enable required APIs
```

**Configuration File**: `.gcp_cloudrun_config`

### Application Deployment

```bash
# Run the deployment script
./deploy_to_cloudrun.sh

# Provide the following information:
# - Service name
# - Dockerfile path (or generate one)
# - Container registry preference
# - Port number
# - Resource limits (memory, CPU)
# - Scaling configuration
# - Public/private access
# - Environment variables
# - Secrets (if needed)
# - Cloud SQL connection (if needed)
# - VPC connector (if needed)
```

**Generated Files**:
- `.cloudrun_deploy_<service-name>.conf` - Deployment configuration

### Service Management

```bash
# Run the management script
./manage_cloudrun.sh

# Available operations:
# 1. List services
# 2. View service details
# 3. View logs
# 4. Update service
# 5. Rollback
# 6. Delete service
# 7. Monitor metrics
# 8. Export configuration
# 9. Test endpoint
```

### CI/CD Setup

```bash
# Run the CI/CD script
./cloudrun_ci_cd.sh

# Choose setup type:
# 1. Basic Cloud Build
# 2. Advanced Cloud Build (with tests)
# 3. GitHub Actions
# 4. Configuration files only
# 5. Local testing
# 6. Permissions setup
# 7. Complete setup
```

**Generated Files**:
- `cloudbuild.yaml` - Cloud Build configuration
- `.env.example` - Environment variables template
- `.gcloudignore` - Build ignore file
- `deploy.sh` - Quick deployment script
- `.github/workflows/deploy-to-cloudrun.yml` - GitHub Actions workflow

## 💡 Common Use Cases

### Use Case 1: Deploy a Node.js Application

```bash
# 1. Setup environment (one-time)
./setup_gcp_environment.sh

# 2. Deploy the application
./deploy_to_cloudrun.sh
# Select Node.js when prompted for Dockerfile generation
# Configure resources and environment variables

# 3. Test the deployment
curl https://your-service-url.run.app
```

### Use Case 2: Update Environment Variables

```bash
# Run management script
./manage_cloudrun.sh

# Select option 4 (Update service)
# Select option 2 (Update environment variables)
# Enter new variables: KEY1=value1,KEY2=value2
```

### Use Case 3: Setup Automated Deployment

```bash
# 1. Setup CI/CD
./cloudrun_ci_cd.sh
# Select option 7 (Complete setup)

# 2. Configure GitHub trigger
# Follow prompts to connect repository

# 3. Push code to trigger deployment
git add .
git commit -m "Deploy to Cloud Run"
git push origin main
```

### Use Case 4: Rollback to Previous Version

```bash
# Run management script
./manage_cloudrun.sh

# Select option 5 (Rollback service)
# Choose the revision to rollback to
```

### Use Case 5: Monitor Service Logs

```bash
# Run management script
./manage_cloudrun.sh

# Select option 3 (View service logs)
# Choose log viewing option:
# - Tail logs (real-time)
# - Recent logs
# - Time range
# - Filter by severity
```

### Use Case 6: Blue-Green Deployment

```bash
# Deploy new version without traffic
gcloud run deploy my-service \
  --image=new-image \
  --no-traffic \
  --tag=blue

# Test the new version
curl https://blue---my-service-xxx.run.app

# Gradually shift traffic
./manage_cloudrun.sh
# Select option 4 (Update service)
# Select option 5 (Update traffic split)
# Enter: revision-001=50,revision-002=50
```

## 🔧 Troubleshooting

### Issue: Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or run: newgrp docker
```

### Issue: gcloud Command Not Found

```bash
# Restart your shell
exec -l $SHELL

# Or source the profile
source ~/.bashrc  # or ~/.zshrc for zsh
```

### Issue: Authentication Failed

```bash
# Re-authenticate
gcloud auth login

# Application default credentials
gcloud auth application-default login
```

### Issue: Build Failed - Dockerfile Not Found

```bash
# Use the deployment script to generate a Dockerfile
./deploy_to_cloudrun.sh
# Select 'yes' when asked to generate a Dockerfile
```

### Issue: Insufficient Permissions

```bash
# Check current permissions
gcloud projects get-iam-policy PROJECT_ID

# Add required roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/run.admin"
```

### Issue: Service Not Accessible

```bash
# Check IAM policy
gcloud run services get-iam-policy SERVICE_NAME

# Allow public access
gcloud run services add-iam-policy-binding SERVICE_NAME \
  --member="allUsers" \
  --role="roles/run.invoker"
```

### Issue: Build Timeout

```bash
# Increase timeout in cloudbuild.yaml
timeout: '3600s'  # 1 hour

# Or use a larger machine type
options:
  machineType: 'N1_HIGHCPU_8'
```

## 🎯 Best Practices

### 1. Security

- ✅ Use Secret Manager for sensitive data
- ✅ Implement authentication for services
- ✅ Use least privilege IAM roles
- ✅ Enable VPC connectors for private resources
- ✅ Scan images for vulnerabilities
- ✅ Use specific image tags, not `latest`

### 2. Performance

- ✅ Set appropriate CPU and memory limits
- ✅ Configure concurrency based on workload
- ✅ Use minimum instances for latency-sensitive apps
- ✅ Optimize container image size
- ✅ Use multi-stage Docker builds
- ✅ Enable HTTP/2 and gRPC

### 3. Cost Optimization

- ✅ Set maximum instances to control costs
- ✅ Use minimum instances = 0 for dev environments
- ✅ Implement request coalescing
- ✅ Use appropriate memory allocation
- ✅ Monitor and analyze billing reports
- ✅ Clean up unused services and images

### 4. Reliability

- ✅ Implement health checks
- ✅ Use readiness probes
- ✅ Configure appropriate timeouts
- ✅ Implement graceful shutdown
- ✅ Use Cloud SQL Proxy for database connections
- ✅ Monitor error rates and latency

### 5. Development Workflow

- ✅ Use environment-specific configurations
- ✅ Test locally before deploying
- ✅ Implement CI/CD pipelines
- ✅ Use Cloud Build for consistent builds
- ✅ Tag releases appropriately
- ✅ Maintain deployment documentation

### 6. Monitoring

- ✅ Enable Cloud Logging
- ✅ Set up Cloud Monitoring dashboards
- ✅ Configure alerting policies
- ✅ Track custom metrics
- ✅ Review error logs regularly
- ✅ Use structured logging

## 📊 Resource Configuration Guidelines

### Memory and CPU

| Application Type | Memory | CPU | Concurrency |
|-----------------|--------|-----|-------------|
| Static sites    | 128Mi  | 1   | 80-100      |
| API services    | 512Mi  | 1   | 80          |
| Web apps        | 1Gi    | 2   | 40-60       |
| Data processing | 2Gi    | 4   | 10-20       |
| ML inference    | 4Gi+   | 4-8 | 1-10        |

### Scaling Configuration

| Use Case        | Min Instances | Max Instances |
|----------------|---------------|---------------|
| Development    | 0             | 1-5           |
| Staging        | 0-1           | 10            |
| Production     | 1-3           | 100+          |
| High Traffic   | 10+           | 1000          |

### Timeout Settings

| Application Type | Timeout |
|-----------------|---------|
| API endpoints   | 60s     |
| Web requests    | 300s    |
| Background jobs | 900s    |
| Long processing | 3600s   |

## 🔗 Useful Links

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Container Registry](https://cloud.google.com/container-registry/docs)
- [Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Secret Manager](https://cloud.google.com/secret-manager/docs)
- [Cloud SQL Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy)

## 📝 Environment Variables Reference

### Common Environment Variables

```bash
# Required
PROJECT_ID=your-project-id
REGION=us-central1
SERVICE_NAME=your-service

# Optional
PORT=8080
NODE_ENV=production
LOG_LEVEL=info

# Cloud Run Provided
K_SERVICE=service-name
K_REVISION=revision-name
K_CONFIGURATION=configuration-name
```

## 🎨 Customization

### Custom Dockerfile Template

Create custom templates in the deployment script by adding a new function:

```bash
generate_custom_dockerfile() {
    cat > Dockerfile << 'EOF'
# Your custom Dockerfile
FROM custom-base:latest
# ... your instructions
EOF
}
```

### Custom Cloud Build Steps

Add custom steps to `cloudbuild.yaml`:

```yaml
steps:
  - name: 'gcr.io/cloud-builders/npm'
    args: ['run', 'custom-script']
```

## 🤝 Contributing

These scripts are designed to be comprehensive and user-friendly. Feel free to customize them based on your specific needs.

## 📄 License

These scripts are provided as-is for use with Google Cloud Platform.

---

**Need Help?**

- Check the [Troubleshooting](#troubleshooting) section
- Review [GCP Documentation](https://cloud.google.com/docs)
- Use the interactive help in each script
- Contact GCP Support for platform issues

**Happy Deploying! 🚀**
