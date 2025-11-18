#!/bin/bash

################################################################################
# GCP Cloud Run - Example Deployment Scenarios
# This script provides ready-to-use examples for common deployment scenarios
################################################################################

# Source the common script
source "$(dirname "$0")/common.sh"

# Example 1: Simple Hello World
example_hello_world() {
    log_step "Example 1: Simple Hello World Service"
    echo ""
    
    log_info "Creating a minimal Node.js Hello World service..."
    
    # Create directory
    mkdir -p hello-world-demo
    cd hello-world-demo
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "hello-world",
  "version": "1.0.0",
  "description": "Simple Hello World for Cloud Run",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF
    
    # Create index.js
    cat > index.js << 'EOF'
const express = require('express');
const app = express();

const PORT = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Cloud Run!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
EOF
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["npm", "start"]
EOF
    
    log_success "Hello World demo created in: hello-world-demo/"
    echo ""
    log_info "Deploy with:"
    echo "  cd hello-world-demo"
    echo "  gcloud run deploy hello-world --source ."
    echo ""
    
    cd ..
}

# Example 2: Python Flask API
example_flask_api() {
    log_step "Example 2: Python Flask REST API"
    echo ""
    
    log_info "Creating a Flask REST API service..."
    
    mkdir -p flask-api-demo
    cd flask-api-demo
    
    # Create requirements.txt
    cat > requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
flask-cors==4.0.0
EOF
    
    # Create main.py
    cat > main.py << 'EOF'
import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)

# In-memory data store (use a database in production)
items = []

@app.route('/')
def home():
    return jsonify({
        'message': 'Flask API on Cloud Run',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/api/items', methods=['GET'])
def get_items():
    return jsonify({'items': items, 'count': len(items)})

@app.route('/api/items', methods=['POST'])
def create_item():
    data = request.get_json()
    item = {
        'id': len(items) + 1,
        'name': data.get('name'),
        'created_at': datetime.utcnow().isoformat()
    }
    items.append(item)
    return jsonify(item), 201

@app.route('/api/items/<int:item_id>', methods=['GET'])
def get_item(item_id):
    item = next((i for i in items if i['id'] == item_id), None)
    if item:
        return jsonify(item)
    return jsonify({'error': 'Item not found'}), 404

@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    global items
    items = [i for i in items if i['id'] != item_id]
    return '', 204

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
EOF
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
EXPOSE 8080

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
EOF
    
    log_success "Flask API demo created in: flask-api-demo/"
    echo ""
    log_info "Deploy with:"
    echo "  cd flask-api-demo"
    echo "  gcloud run deploy flask-api --source ."
    echo ""
    
    cd ..
}

# Example 3: Go Microservice
example_go_service() {
    log_step "Example 3: Go Microservice"
    echo ""
    
    log_info "Creating a Go microservice..."
    
    mkdir -p go-service-demo
    cd go-service-demo
    
    # Create go.mod
    cat > go.mod << 'EOF'
module cloudrun-demo

go 1.21

require github.com/gorilla/mux v1.8.1
EOF
    
    # Create main.go
    cat > main.go << 'EOF'
package main

import (
    "encoding/json"
    "log"
    "net/http"
    "os"
    "time"

    "github.com/gorilla/mux"
)

type Response struct {
    Message   string    `json:"message"`
    Timestamp time.Time `json:"timestamp"`
    Version   string    `json:"version"`
}

type HealthResponse struct {
    Status string `json:"status"`
    Uptime string `json:"uptime"`
}

var startTime = time.Now()

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    r := mux.NewRouter()
    
    r.HandleFunc("/", homeHandler).Methods("GET")
    r.HandleFunc("/health", healthHandler).Methods("GET")
    r.HandleFunc("/api/data", dataHandler).Methods("GET")
    
    log.Printf("Server starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, r))
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
    response := Response{
        Message:   "Go Microservice on Cloud Run",
        Timestamp: time.Now(),
        Version:   "1.0.0",
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    uptime := time.Since(startTime)
    
    response := HealthResponse{
        Status: "healthy",
        Uptime: uptime.String(),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func dataHandler(w http.ResponseWriter, r *http.Request) {
    data := map[string]interface{}{
        "data": []string{"item1", "item2", "item3"},
        "timestamp": time.Now(),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(data)
}
EOF
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/
COPY --from=builder /app/server .

ENV PORT=8080
EXPOSE 8080

CMD ["./server"]
EOF
    
    log_success "Go service demo created in: go-service-demo/"
    echo ""
    log_info "Deploy with:"
    echo "  cd go-service-demo"
    echo "  gcloud run deploy go-service --source ."
    echo ""
    
    cd ..
}

# Example 4: Static Website with Nginx
example_static_site() {
    log_step "Example 4: Static Website with Nginx"
    echo ""
    
    log_info "Creating a static website..."
    
    mkdir -p static-site-demo
    cd static-site-demo
    
    # Create index.html
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud Run Static Site</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        p { font-size: 1.2em; margin-bottom: 30px; }
        .btn {
            background: white;
            color: #667eea;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 50px;
            font-weight: bold;
            display: inline-block;
            transition: transform 0.3s;
        }
        .btn:hover { transform: scale(1.05); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to Cloud Run</h1>
        <p>Your static website is running on Google Cloud Run!</p>
        <a href="/about.html" class="btn">Learn More</a>
    </div>
</body>
</html>
EOF
    
    # Create about.html
    cat > about.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About - Cloud Run Site</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; margin-bottom: 20px; }
        p { line-height: 1.6; margin-bottom: 15px; color: #666; }
        a { color: #667eea; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>About This Site</h1>
        <p>This is a static website hosted on Google Cloud Run using Nginx.</p>
        <p>Cloud Run is a managed compute platform that automatically scales your stateless containers.</p>
        <p><a href="/">← Back to Home</a></p>
    </div>
</body>
</html>
EOF
    
    # Create nginx.conf
    cat > nginx.conf << 'EOF'
server {
    listen 8080;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY *.html /usr/share/nginx/html/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
EOF
    
    log_success "Static site demo created in: static-site-demo/"
    echo ""
    log_info "Deploy with:"
    echo "  cd static-site-demo"
    echo "  gcloud run deploy static-site --source ."
    echo ""
    
    cd ..
}

# Example 5: Scheduled Job (Cloud Scheduler + Cloud Run)
example_scheduled_job() {
    log_step "Example 5: Scheduled Job Setup"
    echo ""
    
    log_info "Creating a scheduled job example..."
    
    mkdir -p scheduled-job-demo
    cd scheduled-job-demo
    
    # Create job.py
    cat > job.py << 'EOF'
import os
from flask import Flask, request
from datetime import datetime

app = Flask(__name__)

@app.route('/', methods=['POST'])
def run_job():
    """This endpoint will be called by Cloud Scheduler"""
    
    # Verify the request is from Cloud Scheduler
    auth_header = request.headers.get('Authorization', '')
    
    print(f"Job triggered at {datetime.utcnow().isoformat()}")
    
    # Your job logic here
    result = perform_job()
    
    return {'status': 'success', 'result': result, 'timestamp': datetime.utcnow().isoformat()}

def perform_job():
    """Your actual job logic"""
    print("Performing scheduled task...")
    # Add your logic here
    return "Job completed successfully"

@app.route('/health', methods=['GET'])
def health():
    return {'status': 'healthy'}

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
EOF
    
    # Create requirements.txt
    cat > requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
EOF
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
CMD exec gunicorn --bind :$PORT --workers 1 --threads 1 --timeout 0 job:app
EOF
    
    # Create setup script
    cat > setup_scheduler.sh << 'EOF'
#!/bin/bash

# Deploy the Cloud Run service
SERVICE_NAME="scheduled-job"
REGION="us-central1"

echo "Deploying Cloud Run service..."
gcloud run deploy $SERVICE_NAME \
    --source . \
    --region=$REGION \
    --no-allow-unauthenticated

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --region=$REGION \
    --format='value(status.url)')

echo "Service deployed: $SERVICE_URL"

# Create service account for Cloud Scheduler
SA_NAME="cloud-scheduler-sa"
PROJECT_ID=$(gcloud config get-value project)

echo "Creating service account..."
gcloud iam service-accounts create $SA_NAME \
    --display-name="Cloud Scheduler Service Account" || true

# Grant permission to invoke Cloud Run
gcloud run services add-iam-policy-binding $SERVICE_NAME \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.invoker" \
    --region=$REGION

# Create Cloud Scheduler job (runs every day at 9 AM)
echo "Creating Cloud Scheduler job..."
gcloud scheduler jobs create http ${SERVICE_NAME}-daily \
    --location=$REGION \
    --schedule="0 9 * * *" \
    --uri="${SERVICE_URL}/" \
    --http-method=POST \
    --oidc-service-account-email="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --oidc-token-audience="${SERVICE_URL}"

echo "Setup complete!"
echo "Test the job: gcloud scheduler jobs run ${SERVICE_NAME}-daily --location=$REGION"
EOF
    
    chmod +x setup_scheduler.sh
    
    log_success "Scheduled job demo created in: scheduled-job-demo/"
    echo ""
    log_info "Deploy and setup with:"
    echo "  cd scheduled-job-demo"
    echo "  ./setup_scheduler.sh"
    echo ""
    
    cd ..
}

# Example 6: Multi-container with Cloud SQL
example_cloudsql() {
    log_step "Example 6: Application with Cloud SQL"
    echo ""
    
    log_info "Creating Cloud SQL integration example..."
    
    mkdir -p cloudsql-demo
    cd cloudsql-demo
    
    # Create app.py
    cat > app.py << 'EOF'
import os
import sqlalchemy
from flask import Flask, jsonify
from sqlalchemy import create_engine, text

app = Flask(__name__)

def get_db_connection():
    """Create database connection"""
    
    # Cloud SQL connection
    db_user = os.environ.get('DB_USER', 'root')
    db_pass = os.environ.get('DB_PASS', '')
    db_name = os.environ.get('DB_NAME', 'mydb')
    db_socket_dir = os.environ.get('DB_SOCKET_DIR', '/cloudsql')
    cloud_sql_connection_name = os.environ.get('CLOUD_SQL_CONNECTION_NAME')
    
    if cloud_sql_connection_name:
        # Production: Use Unix socket
        unix_socket = f'{db_socket_dir}/{cloud_sql_connection_name}'
        engine = create_engine(
            f'mysql+pymysql://{db_user}:{db_pass}@/{db_name}?unix_socket={unix_socket}'
        )
    else:
        # Development: Use TCP
        db_host = os.environ.get('DB_HOST', 'localhost')
        engine = create_engine(
            f'mysql+pymysql://{db_user}:{db_pass}@{db_host}/{db_name}'
        )
    
    return engine

@app.route('/')
def home():
    return jsonify({'message': 'Cloud SQL Integration Demo'})

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/db/test')
def test_db():
    """Test database connection"""
    try:
        engine = get_db_connection()
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1")).fetchone()
            return jsonify({
                'status': 'success',
                'message': 'Database connection successful',
                'result': result[0]
            })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
EOF
    
    # Create requirements.txt
    cat > requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
SQLAlchemy==2.0.23
PyMySQL==1.1.0
EOF
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app
EOF
    
    # Create deployment script
    cat > deploy_with_cloudsql.sh << 'EOF'
#!/bin/bash

SERVICE_NAME="cloudsql-app"
REGION="us-central1"
PROJECT_ID=$(gcloud config get-value project)

# Replace these with your Cloud SQL instance details
INSTANCE_CONNECTION_NAME="PROJECT:REGION:INSTANCE"
DB_NAME="mydb"
DB_USER="root"

# Get database password from Secret Manager
# gcloud secrets versions access latest --secret="db-password"

echo "Deploying to Cloud Run with Cloud SQL..."

gcloud run deploy $SERVICE_NAME \
    --source . \
    --region=$REGION \
    --add-cloudsql-instances=$INSTANCE_CONNECTION_NAME \
    --set-env-vars="CLOUD_SQL_CONNECTION_NAME=$INSTANCE_CONNECTION_NAME" \
    --set-env-vars="DB_NAME=$DB_NAME" \
    --set-env-vars="DB_USER=$DB_USER" \
    --set-secrets="DB_PASS=db-password:latest" \
    --allow-unauthenticated

echo "Deployment complete!"
EOF
    
    chmod +x deploy_with_cloudsql.sh
    
    log_success "Cloud SQL demo created in: cloudsql-demo/"
    echo ""
    log_warning "Before deploying:"
    echo "  1. Create a Cloud SQL instance"
    echo "  2. Create a database"
    echo "  3. Store database password in Secret Manager"
    echo "  4. Update INSTANCE_CONNECTION_NAME in deploy_with_cloudsql.sh"
    echo ""
    log_info "Deploy with:"
    echo "  cd cloudsql-demo"
    echo "  ./deploy_with_cloudsql.sh"
    echo ""
    
    cd ..
}

# Main execution
main() {
    print_banner "GCP Cloud Run - Example Scenarios" "Ready-to-use deployment examples"
    
    echo ""
    log_info "Select an example to create:"
    
    options=(
        "Hello World (Node.js + Express)"
        "REST API (Python + Flask)"
        "Microservice (Go + Gorilla Mux)"
        "Static Website (Nginx)"
        "Scheduled Job (Cloud Scheduler)"
        "Database Integration (Cloud SQL)"
        "Create all examples"
        "Exit"
    )
    
    select opt in "${options[@]}"; do
        case $opt in
            "Hello World (Node.js + Express)")
                example_hello_world
                break
                ;;
            "REST API (Python + Flask)")
                example_flask_api
                break
                ;;
            "Microservice (Go + Gorilla Mux)")
                example_go_service
                break
                ;;
            "Static Website (Nginx)")
                example_static_site
                break
                ;;
            "Scheduled Job (Cloud Scheduler)")
                example_scheduled_job
                break
                ;;
            "Database Integration (Cloud SQL)")
                example_cloudsql
                break
                ;;
            "Create all examples")
                log_info "Creating all examples..."
                example_hello_world
                example_flask_api
                example_go_service
                example_static_site
                example_scheduled_job
                example_cloudsql
                log_success "All examples created!"
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
    
    echo ""
    log_success "════════════════════════════════════════════════════════════════"
    log_success "Example created successfully!"
    log_success "════════════════════════════════════════════════════════════════"
}

main "$@"
