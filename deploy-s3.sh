#!/bin/bash

# Flutter Web App S3 Deployment Script (Part 1)
# This script will build your Flutter app and upload it to S3 with static website hosting

set -e

# Configuration (Update these values)
BUCKET_NAME="protrack-web-app"  # Your bucket name
REGION="us-east-1"  # Change to your preferred region

echo "🚀 Starting Flutter Web App build and S3 upload"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first:"
    echo "   brew install awscli"
    echo "   or visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run:"
    echo "   aws configure"
    exit 1
fi

echo "✅ AWS CLI is configured"

# Step 1: Build Flutter web app
echo "🏗️  Building Flutter web app..."
flutter build web --release --base-href "/"

# Step 2: Create S3 bucket (if it doesn't exist)
echo "📦 Creating S3 bucket (if it doesn't exist)..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ Bucket $BUCKET_NAME already exists"
else
    echo "📦 Creating new bucket $BUCKET_NAME..."
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
    else
        aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION
    fi
fi

# Step 3: Enable static website hosting
echo "🌐 Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html

# Step 4: Upload Flutter web build
echo "📁 Uploading Flutter web build to S3..."
aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete

# Step 5: Set correct content types for important files
echo "🏷️  Setting content types..."
aws s3 cp s3://$BUCKET_NAME/main.dart.js s3://$BUCKET_NAME/main.dart.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter.js s3://$BUCKET_NAME/flutter.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter_bootstrap.js s3://$BUCKET_NAME/flutter_bootstrap.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter_service_worker.js s3://$BUCKET_NAME/flutter_service_worker.js --content-type "application/javascript" --metadata-directive REPLACE

echo "✅ S3 deployment completed successfully!"
echo ""
echo "📊 S3 Deployment Summary:"
echo "========================"
echo "S3 Bucket: $BUCKET_NAME"
echo "S3 Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo ""
echo "⚠️  Note: The website is currently only accessible via HTTP and may not be publicly readable."
echo "📌 To complete the setup:"
echo "1. Run './setup-cloudfront.sh' to configure public access and CloudFront"
echo "2. Or manually set bucket permissions if you only want S3 hosting"
echo ""
echo "🔧 S3-only public access (optional):"
echo "aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json" 