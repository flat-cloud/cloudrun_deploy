# GCP Cloud Run Deployment Scripts - Index

## 📚 Complete Script Collection

This is a comprehensive collection of interactive bash scripts for deploying and managing applications on Google Cloud Run.

---

## 🚀 Quick Start

**For first-time users, start here:**

```bash
./quick_start.sh
```

This guided script will help you set up everything and deploy your first application.

---

## 📋 All Available Scripts

### 1. **Setup Environment** 
**File:** `setup_gcp_environment.sh`

**Purpose:** Install and configure all dependencies (Docker, gcloud SDK, etc.)

**Use when:**
- First time setting up
- New machine/environment
- Installing missing tools

```bash
./setup_gcp_environment.sh
```

**Features:**
- ✅ Automatic OS detection
- ✅ Docker installation
- ✅ gcloud SDK installation
- ✅ GCP authentication
- ✅ Project/region configuration
- ✅ API enablement

---

### 2. **Deploy Application**
**File:** `deploy_to_cloudrun.sh`

**Purpose:** Build and deploy any application to Cloud Run

**Use when:**
- Deploying a new service
- Updating an existing service
- Need to configure resources/scaling

```bash
./deploy_to_cloudrun.sh
```

**Features:**
- ✅ Interactive configuration
- ✅ Dockerfile generation (Node.js, Python, Go, Java, .NET, Ruby, PHP)
- ✅ Container registry setup
- ✅ Environment variables
- ✅ Secrets management
- ✅ Cloud SQL integration
- ✅ VPC connector support
- ✅ Resource configuration

---

### 3. **Manage Services**
**File:** `manage_cloudrun.sh`

**Purpose:** Manage, monitor, and control deployed services

**Use when:**
- Viewing service details
- Monitoring logs
- Updating configuration
- Rolling back deployments
- Troubleshooting issues

```bash
./manage_cloudrun.sh
```

**Features:**
- ✅ List all services
- ✅ View service details
- ✅ Real-time logs
- ✅ Update configurations
- ✅ Traffic splitting
- ✅ Rollback revisions
- ✅ Service metrics
- ✅ IAM management
- ✅ Endpoint testing

---

### 4. **Setup CI/CD**
**File:** `cloudrun_ci_cd.sh`

**Purpose:** Setup automated deployment pipelines

**Use when:**
- Setting up automated deployments
- Configuring Cloud Build
- Integrating with GitHub/GitLab/Bitbucket
- Creating multi-environment pipelines

```bash
./cloudrun_ci_cd.sh
```

**Features:**
- ✅ Cloud Build configuration
- ✅ GitHub Actions workflow
- ✅ Trigger setup (GitHub, Cloud Source Repos, Bitbucket)
- ✅ Automated testing
- ✅ Security scanning
- ✅ Multi-environment support
- ✅ Deployment scripts

---

### 5. **Helper Functions**
**File:** `cloudrun_helpers.sh`

**Purpose:** Reusable utility functions for Cloud Run operations

**Use when:**
- Writing custom scripts
- Automating repetitive tasks
- Need common operations as functions

```bash
source cloudrun_helpers.sh
get_service_url my-service
```

**Available Functions:**
- Service management (get URL, check status, wait for ready)
- Monitoring (logs, metrics, testing)
- Secrets management
- Service accounts
- Backup/restore
- Cost estimation
- Load testing
- And more...

---

### 6. **Example Scenarios**
**File:** `cloudrun_examples.sh`

**Purpose:** Generate ready-to-deploy example applications

**Use when:**
- Learning Cloud Run
- Need a starting template
- Want to see working examples

```bash
./cloudrun_examples.sh
```

**Available Examples:**
1. Hello World (Node.js)
2. REST API (Python Flask)
3. Microservice (Go)
4. Static Website (Nginx)
5. Scheduled Job (Cloud Scheduler)
6. Database Integration (Cloud SQL)

---

## 📖 Documentation

### **Complete Guide**
**File:** `README_cloudrun.md`

Comprehensive documentation covering:
- Detailed usage instructions
- Common use cases
- Troubleshooting guide
- Best practices
- Resource configuration guidelines
- Security recommendations

```bash
cat README_cloudrun.md
```

---

## 🎯 Common Workflows

### **Workflow 1: First Time Setup and Deployment**

```bash
# Step 1: Run quick start (recommended)
./quick_start.sh

# OR do it manually:

# Step 1: Setup environment
./setup_gcp_environment.sh

# Step 2: Deploy application
./deploy_to_cloudrun.sh

# Step 3: Check deployment
./manage_cloudrun.sh
```

### **Workflow 2: Deploy Example Application**

```bash
# Generate example
./cloudrun_examples.sh
# Select option 1 (Hello World)

# Deploy it
cd hello-world-demo
gcloud run deploy hello-world --source .
```

### **Workflow 3: Setup Automated Deployment**

```bash
# Setup CI/CD
./cloudrun_ci_cd.sh
# Select option 7 (Complete setup)

# Commit and push to trigger deployment
git add .
git commit -m "Setup Cloud Run deployment"
git push origin main
```

### **Workflow 4: Monitor and Update Service**

```bash
# Open management console
./manage_cloudrun.sh

# Options available:
# - View logs (option 3)
# - Update environment variables (option 4 -> 2)
# - Scale service (option 4 -> 4)
# - Monitor metrics (option 7)
```

### **Workflow 5: Rollback Deployment**

```bash
# Open management console
./manage_cloudrun.sh

# Select option 5 (Rollback service)
# Choose previous revision
```

---

## 🔧 Script Features Comparison

| Feature | Setup | Deploy | Manage | CI/CD | Helpers | Examples |
|---------|-------|--------|--------|-------|---------|----------|
| Interactive Mode | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| One-time Setup | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Regular Use | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Learning Tool | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| Production Ready | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |

---

## 🎨 Usage Patterns

### **Pattern 1: Quick Testing**
```bash
./cloudrun_examples.sh        # Create example
cd <example-dir>                  # Enter directory
gcloud run deploy --source .     # Deploy quickly
```

### **Pattern 2: Production Deployment**
```bash
./deploy_to_cloudrun.sh
# Configure all production settings interactively
```

### **Pattern 3: Automated Pipeline**
```bash
./cloudrun_ci_cd.sh
# Setup once, deploy automatically on git push
```

### **Pattern 4: Custom Automation**
```bash
source cloudrun_helpers.sh

# Use helper functions in your scripts
SERVICE_URL=$(get_service_url "my-service")
test_endpoint "$SERVICE_URL"
stream_logs "my-service"
```

---

## 📊 When to Use Each Script

### Use **Quick Start** when:
- 👶 You're new to Cloud Run
- 🚀 You want the fastest path to deployment
- 🎓 You're learning the platform

### Use **Setup Script** when:
- 💻 Setting up a new development machine
- 🔧 Installing missing dependencies
- 🔄 Configuring GCP authentication

### Use **Deploy Script** when:
- 📦 Deploying a new application
- 🔄 Updating an existing service
- ⚙️ Configuring service settings

### Use **Manage Script** when:
- 👀 Monitoring service health
- 📊 Viewing logs and metrics
- 🔄 Updating configurations
- ⏮️ Rolling back changes
- 🧪 Testing endpoints

### Use **CI/CD Script** when:
- 🤖 Setting up automated deployments
- 🔗 Integrating with Git repositories
- 🏗️ Creating build pipelines
- 🌍 Managing multiple environments

### Use **Helper Functions** when:
- 🛠️ Building custom automation
- 🔁 Scripting repetitive tasks
- 🧩 Need reusable components

### Use **Examples Script** when:
- 📚 Learning Cloud Run
- 🎨 Need a starting template
- 🔍 Exploring different frameworks

---

## ⚡ Quick Reference Commands

### Check Status
```bash
gcloud run services list
gcloud run services describe SERVICE_NAME
```

### View Logs
```bash
gcloud run logs tail SERVICE_NAME
gcloud run logs read SERVICE_NAME --limit=50
```

### Update Service
```bash
gcloud run services update SERVICE_NAME --memory=1Gi
gcloud run services update SERVICE_NAME --set-env-vars="KEY=VALUE"
```

### Traffic Management
```bash
gcloud run services update-traffic SERVICE_NAME --to-revisions=REVISION=100
```

### Delete Service
```bash
gcloud run services delete SERVICE_NAME
```

---

## 🆘 Getting Help

### **Within Scripts**
Most scripts provide help when run without arguments or with `--help`

### **Documentation**
```bash
cat README_cloudrun.md | less
```

### **List Helper Functions**
```bash
./cloudrun_helpers.sh
```

### **GCP Documentation**
- [Cloud Run Docs](https://cloud.google.com/run/docs)
- [Cloud Build Docs](https://cloud.google.com/build/docs)

---

## 🗂️ File Structure

```
.
├── quick_start.sh              # ⭐ Start here!
├── setup_gcp_environment.sh    # Setup dependencies
├── deploy_to_cloudrun.sh       # Deploy applications
├── manage_cloudrun.sh          # Manage services
├── cloudrun_ci_cd.sh           # Setup CI/CD
├── cloudrun_helpers.sh         # Helper functions
├── cloudrun_examples.sh                 # Example generators
├── README_cloudrun.md          # Complete guide
└── INDEX.md                    # This file
```

---

## 🎓 Learning Path

**Beginner Path:**
1. Read this INDEX
2. Run `quick_start.sh`
3. Try `cloudrun_examples.sh`
4. Read `README_cloudrun.md`

**Intermediate Path:**
1. Use `deploy_to_cloudrun.sh`
2. Explore `manage_cloudrun.sh`
3. Setup CI/CD with `cloudrun_ci_cd.sh`

**Advanced Path:**
1. Use `cloudrun_helpers.sh` functions
2. Create custom automation scripts
3. Implement multi-region deployments
4. Setup blue-green deployments

---

## ✨ Pro Tips

1. **Always start with Quick Start** if you're new
2. **Keep configuration files** generated by deploy script
3. **Use helper functions** for custom automation
4. **Setup CI/CD early** for consistent deployments
5. **Monitor costs** in GCP Console
6. **Use Artifact Registry** instead of Container Registry
7. **Enable VPC** for private resources
8. **Use Secret Manager** for sensitive data
9. **Implement health checks** in your applications
10. **Set up alerts** for production services

---

## 🔄 Update and Maintenance

These scripts are designed to be comprehensive and up-to-date. They follow GCP best practices and include the latest Cloud Run features.

**To keep scripts updated:**
- Check GCP documentation for new features
- Review and update Dockerfile base images
- Update dependency versions in examples
- Test scripts periodically

---

## 📞 Support

For issues related to:
- **Scripts**: Review the README and troubleshooting section
- **GCP Platform**: Check GCP documentation or support
- **Specific frameworks**: Refer to framework documentation

---

## 🎉 Next Steps

Ready to get started? Here's what to do:

```bash
# Make everything executable (if not already)
chmod +x *.sh

# Start with Quick Start
./quick_start.sh

# Or read the full guide first
cat README_cloudrun.md
```

**Happy deploying! 🚀**

---

## New Capabilities

- Build modes: local Docker or Cloud Build from source
- Advanced Cloud Run options (ingress, VPC egress, gen2, service account, tags, labels, annotations, no-traffic)
- Domain mappings management (list/create/delete)
- Dry-run and non-interactive support

### Quick Examples
```bash
# Dry-run end-to-end
DRY_RUN=true NON_INTERACTIVE=true ./quick_start.sh

# Dry-run deploy only
DRY_RUN=true NON_INTERACTIVE=true ./deploy_to_cloudrun.sh
```

### Where these live
- Shared behavior (dry-run wrappers, logging, strict mode): `common.sh`
- Build mode + advanced flags: `deploy_to_cloudrun.sh`
- Domain mappings: `manage_cloudrun.sh` (menu option 10)
