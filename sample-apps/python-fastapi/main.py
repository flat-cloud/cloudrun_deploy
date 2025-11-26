#!/usr/bin/env python3
"""
FastAPI application for Cloud Run testing
"""
import os
from datetime import datetime
from typing import Dict, Any
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(
    title="Cloud Run FastAPI Sample",
    description="A modern async API for testing Cloud Run deployments",
    version="1.0.0"
)

class EchoRequest(BaseModel):
    """Request model for echo endpoint"""
    message: str
    data: Dict[str, Any] = {}

class EchoResponse(BaseModel):
    """Response model for echo endpoint"""
    received: Dict[str, Any]
    timestamp: str

@app.get("/")
async def home():
    """Home endpoint"""
    return {
        "message": "Hello from Cloud Run!",
        "framework": "FastAPI",
        "language": "Python",
        "timestamp": datetime.utcnow().isoformat(),
        "service": os.getenv("K_SERVICE", "local"),
        "revision": os.getenv("K_REVISION", "dev"),
        "docs": "/docs",
        "redoc": "/redoc"
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/info")
async def info():
    """Service information endpoint"""
    return {
        "service": "FastAPI Sample App",
        "version": "1.0.0",
        "endpoints": {
            "/": "Home page",
            "/health": "Health check",
            "/api/info": "Service information",
            "/api/echo": "Echo POST endpoint",
            "/docs": "Interactive API docs (Swagger UI)",
            "/redoc": "Alternative API docs (ReDoc)"
        },
        "environment": {
            "port": os.getenv("PORT", "8080"),
            "service": os.getenv("K_SERVICE", "local"),
            "revision": os.getenv("K_REVISION", "dev")
        },
        "features": [
            "Async/await support",
            "Automatic data validation",
            "Interactive API documentation",
            "Type hints and Pydantic models",
            "High performance"
        ]
    }

@app.post("/api/echo", response_model=EchoResponse)
async def echo(request: EchoRequest):
    """Echo endpoint - returns the received data"""
    return EchoResponse(
        received=request.dict(),
        timestamp=datetime.utcnow().isoformat()
    )
