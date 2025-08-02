#!/bin/bash

# CoachVision Backend Deployment Script
echo "🚀 Starting CoachVision Backend Deployment..."

# Stop and remove existing container
echo "📦 Stopping existing container..."
docker-compose down

# Pull latest changes from GitHub
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

# Build and start the container
echo "🔨 Building and starting container..."
docker-compose up --build -d

# Wait for container to be healthy
echo "⏳ Waiting for container to be healthy..."
sleep 10

# Check container status
echo "🔍 Checking container status..."
docker-compose ps

# Test health endpoint
echo "🏥 Testing health endpoint..."
curl -f http://localhost:8000/health || echo "❌ Health check failed"

echo "✅ Deployment completed!" 