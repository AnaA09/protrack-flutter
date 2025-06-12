#!/bin/bash

# Full Flutter Web App Deployment Script
# This script runs both parts: S3 deployment + CloudFront setup

set -e

echo "🚀 Starting full deployment: S3 + CloudFront"
echo "============================================="

# Part 1: Deploy to S3
echo ""
echo "📦 PART 1: Deploying to S3..."
echo "=============================="
./deploy-s3.sh

echo ""
echo "⏳ Waiting 5 seconds before CloudFront setup..."
sleep 5

# Part 2: Setup CloudFront
echo ""
echo "☁️  PART 2: Setting up CloudFront..."
echo "===================================="
./setup-cloudfront.sh

echo ""
echo "🎉 Full deployment completed!"
echo "============================="
echo ""
echo "📋 Summary:"
echo "✅ Flutter app built and uploaded to S3"
echo "✅ S3 static website hosting enabled"
echo "✅ Public access permissions configured"
echo "✅ CloudFront distribution created"
echo ""
echo "📁 Check deployment-info.txt for all URLs and IDs"
echo ""
echo "⏳ Remember: CloudFront takes 15-20 minutes to fully deploy" 