#!/usr/bin/env python3
"""
Simple Flask API for Cloud Run testing
"""
import os
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        'message': 'Hello from Cloud Run!',
        'framework': 'Flask',
        'language': 'Python',
        'timestamp': datetime.utcnow().isoformat(),
        'service': os.getenv('K_SERVICE', 'local'),
        'revision': os.getenv('K_REVISION', 'dev')
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()})

@app.route('/api/info')
def info():
    """Service information endpoint"""
    return jsonify({
        'service': 'Flask Sample App',
        'version': '1.0.0',
        'endpoints': {
            '/': 'Home page',
            '/health': 'Health check',
            '/api/info': 'Service information'
        },
        'environment': {
            'port': os.getenv('PORT', '8080'),
            'service': os.getenv('K_SERVICE', 'local'),
            'revision': os.getenv('K_REVISION', 'dev')
        }
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
