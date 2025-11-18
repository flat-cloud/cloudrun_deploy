# GCP Cloud Run Deployment Toolkit 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![GCP](https://img.shields.io/badge/GCP-Cloud%20Run-blue.svg)](https://cloud.google.com/run)

> **Comprehensive, interactive bash scripts to deploy any application to Google Cloud Run with zero hassle.**

Supports Node.js, TypeScript, Python, Go, Java, .NET, Ruby, PHP, and Laravel with built-in Dockerfile generators, CI/CD pipelines, and complete lifecycle management.

---

## ✨ Features

- 🎯 **One-command deployment** - From zero to production in minutes
- 🐳 **No Docker required** - Deploy from source using Cloud Build
- 🔧 **Dockerfile generators** - Auto-generate optimized Dockerfiles for 9+ frameworks
- 🤖 **CI/CD ready** - GitHub Actions (OIDC), Cloud Build, and Makefile included
- 🔐 **Security first** - Secret Manager integration, VPC support, service accounts
- 📊 **Full lifecycle** - Deploy, manage, monitor, rollback, scale, and more
- 🧪 **Dry-run mode** - Test without touching GCP resources
- 📚 **Comprehensive docs** - Framework-specific guides and examples

---

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/flat-cloud/cloudrun_deploy.git
cd cloudrun_deploy
chmod +x *.sh
```

### 2. Run the quick start guide

```bash
./quick_start.sh
```

That's it! The script will:
- ✅ Install Docker and gcloud SDK
- ✅ Authenticate with GCP
- ✅ Configure your project
- ✅ Deploy your application

---

## 📦 What's Included

### Core Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **quick_start.sh** | Guided setup and deployment | First time or learning |
| **setup_gcp_environment.sh** | Install dependencies | New machine or missing tools |
| **deploy_to_cloudrun.sh** | Build and deploy apps | Every deployment |
| **manage_cloudrun.sh** | Manage services | Monitor, update, rollback |
| **cloudrun_ci_cd.sh** | Setup CI/CD pipelines | Automated deployments |
| **cloudrun_helpers.sh** | Utility functions | Custom automation |
| **cloudrun_examples.sh** | Generate sample apps | Learning or templates |

---

## 🎯 Use Cases

### Deploy Node.js Express API

```bash
./deploy_to_cloudrun.sh
# Choose "Node.js" when prompted
# Configure resources (memory, CPU, scaling)
# Deploy!
```

### Deploy TypeScript Application

```bash
./deploy_to_cloudrun.sh
# Choose "Node.js (TypeScript)"
# Auto-generates multi-stage Dockerfile
# Builds and deploys
```

### Deploy Laravel Application

```bash
./deploy_to_cloudrun.sh
# Choose "PHP (Laravel)"
# Configure Cloud SQL connection
# Set environment variables
# Deploy with proper Apache config
```

### Deploy from Source (No Docker)

```bash
./deploy_to_cloudrun.sh
# Choose "Build from source using Cloud Build"
# Cloud Buildpacks containerize automatically
```

---

## 🔧 Advanced Features

### Build Modes

- **Local Docker build** - Build and push from your machine
- **Cloud Build from source** - No local Docker required

### Deployment Options

- **Ingress control** - Internal, all, or load balancer only
- **VPC networking** - Private IP ranges or all traffic
- **Execution environment** - Gen1 or Gen2 (recommended)
- **Service accounts** - Custom identity for your service
- **Labels & annotations** - Organize and tag resources
- **Revision tags** - Blue/green deployments (e.g., `blue`, `canary`)
- **No-traffic deploys** - Test before shifting traffic
- **Custom domains** - Map your domain to Cloud Run

### Management Features

- **Real-time logs** - Tail, filter by severity, time range
- **Traffic splitting** - Gradual rollouts and A/B testing
- **Revision rollback** - One-click rollback to previous versions
- **Resource scaling** - Adjust CPU, memory, concurrency
- **Environment variables** - Update without redeployment
- **Secret Manager** - Secure secrets integration
- **Domain mappings** - Custom domain management

### CI/CD Integration

- **GitHub Actions** - OIDC authentication, no key files
- **Cloud Build** - Automated builds and deploys
- **Makefile** - Common tasks (deploy, logs, manage)
- **Multi-environment** - Separate staging and production

---

## 🏗️ Supported Frameworks

### Auto-Generated Dockerfiles

| Language/Framework | Features |
|-------------------|----------|
| **Node.js** | Express, production deps only |
| **Node.js (TypeScript)** | Multi-stage build, compiled output |
| **Python** | Flask, Gunicorn, optimized for Cloud Run |
| **Go** | Multi-stage build, minimal Alpine runtime |
| **Java** | Maven build, JRE runtime |
| **.NET** | SDK build, ASP.NET runtime |
| **Ruby** | Bundler, production gems |
| **PHP** | Apache, mod_rewrite enabled |
| **PHP (Laravel)** | Composer, document root, extensions, caches |

---

## 📖 Documentation

- **[Complete Guide](README_cloudrun.md)** - Detailed usage, troubleshooting, best practices
- **[Quick Reference](INDEX.md)** - Fast lookup for all scripts and features
- **[Generated Files](README_cloudrun.md#generated-files-not-committed)** - What gets created and why

---

## 🎬 Example Workflows

### Workflow 1: Deploy Express API

```bash
# Setup (one-time)
./setup_gcp_environment.sh

# Deploy
./deploy_to_cloudrun.sh
# - Service name: my-api
# - Choose: Node.js
# - Resources: 512Mi, 1 CPU
# - Public access: Yes

# View logs
./manage_cloudrun.sh
# Select: View service logs
```

### Workflow 2: Laravel with Cloud SQL

```bash
# Deploy
./deploy_to_cloudrun.sh
# - Choose: PHP (Laravel)
# - Add Cloud SQL connection
# - Set secrets: DB_PASSWORD
# - Configure env vars

# Run migrations (separate job)
gcloud run jobs create laravel-migrate \
  --image=YOUR_IMAGE \
  --command="php,artisan,migrate,--force"
```

### Workflow 3: CI/CD with GitHub Actions

```bash
# Generate CI/CD files
./cloudrun_ci_cd.sh
# Select: Complete setup

# Commit and push
git add .github/workflows/deploy-to-cloudrun.yml Makefile
git commit -m "Add CI/CD"
git push

# Configure GitHub secrets:
# - WIF_PROVIDER
# - WIF_SERVICE_ACCOUNT
# - GCP_PROJECT_ID
```

---

## 🧪 Dry Run Mode

Test deployments without touching GCP:

```bash
DRY_RUN=true NON_INTERACTIVE=true ./deploy_to_cloudrun.sh
```

All `gcloud`, `docker`, and `curl` commands will be logged but not executed.

---

## 🔐 Security Best Practices

✅ **Use Secret Manager** for sensitive data
✅ **Enable VPC** for private resources
✅ **Use service accounts** with least privilege
✅ **Implement authentication** for services
✅ **Scan images** for vulnerabilities
✅ **Use specific image tags**, not `latest`

---

## 💡 Tips & Tricks

### Use in Any Repo

Add as a submodule to your project:

```bash
git submodule add https://github.com/flat-cloud/cloudrun_deploy.git cloudrun
cd cloudrun
./quick_start.sh
```

### Non-Interactive Deployment

```bash
# Set environment variables
export NON_INTERACTIVE=true
export SERVICE_NAME=my-api
export REGION=us-central1

./deploy_to_cloudrun.sh
```

### Quick Commands via Makefile

After running `cloudrun_ci_cd.sh`:

```bash
make cloudrun-deploy    # Deploy the service
make cloudrun-logs      # View logs
make cloudrun-manage    # Open management menu
```

---

## 📊 Resource Configuration Guide

### Memory & CPU

| Application Type | Memory | CPU | Concurrency |
|-----------------|--------|-----|-------------|
| Static sites    | 128Mi  | 1   | 80-100      |
| API services    | 512Mi  | 1   | 80          |
| Web apps        | 1Gi    | 2   | 40-60       |
| Data processing | 2Gi    | 4   | 10-20       |
| ML inference    | 4Gi+   | 4-8 | 1-10        |

### Scaling

| Use Case     | Min Instances | Max Instances |
|-------------|---------------|---------------|
| Development | 0             | 1-5           |
| Staging     | 0-1           | 10            |
| Production  | 1-3           | 100+          |
| High Traffic| 10+           | 1000          |

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (dry-run mode helps!)
5. Submit a pull request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🔗 Links

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Secret Manager](https://cloud.google.com/secret-manager/docs)

---

## 💬 Support

- 📖 [Read the docs](README_cloudrun.md)
- 🐛 [Report issues](https://github.com/flat-cloud/cloudrun_deploy/issues)
- 💡 [Request features](https://github.com/flat-cloud/cloudrun_deploy/issues/new)

---

## 🎉 What Users Say

> "Went from zero to production Cloud Run deployment in 10 minutes. This toolkit is amazing!" 

> "The Laravel support with Cloud SQL integration saved me hours of configuration."

> "Finally, a deployment solution that actually works out of the box."

---

**Made with ❤️ for the Cloud Run community**

Star ⭐ this repo if you find it useful!
