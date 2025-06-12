#!/bin/bash

# Quick update script for Flutter Web App
# Use this after making changes to update your deployed app

set -e

# Try to read configuration from deployment-info.txt first
if [ -f "deployment-info.txt" ]; then
    echo "📁 Reading deployment configuration from deployment-info.txt..."
    source deployment-info.txt
    echo "✅ Configuration loaded:"
    echo "   Bucket: $BUCKET_NAME"
    echo "   Distribution: $DISTRIBUTION_ID"
else
    # Fallback to manual configuration
    echo "⚠️  deployment-info.txt not found. Using manual configuration..."
    
    # Configuration - Update these with your actual values from deployment
    BUCKET_NAME=""  # Set this to your actual bucket name
    DISTRIBUTION_ID=""  # Set this to your CloudFront distribution ID

    # Check if configuration is set
    if [ -z "$BUCKET_NAME" ] || [ -z "$DISTRIBUTION_ID" ]; then
        echo "❌ Please update BUCKET_NAME and DISTRIBUTION_ID in this script"
        echo "   Or run './setup-cloudfront.sh' to generate deployment-info.txt"
        echo "   You can find these values from your deployment output"
        exit 1
    fi
fi

echo "🔄 Updating Flutter Web App..."

# Step 1: Build the app
echo "🏗️  Building Flutter web app..."
flutter build web --release --base-href "/"

# Step 2: Upload to S3
echo "📁 Uploading to S3..."
aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete

# Set correct content types for important files
echo "🏷️  Setting content types..."
aws s3 cp s3://$BUCKET_NAME/main.dart.js s3://$BUCKET_NAME/main.dart.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter.js s3://$BUCKET_NAME/flutter.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter_bootstrap.js s3://$BUCKET_NAME/flutter_bootstrap.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter_service_worker.js s3://$BUCKET_NAME/flutter_service_worker.js --content-type "application/javascript" --metadata-directive REPLACE

# Step 3: Invalidate CloudFront cache (if distribution exists)
if [ -n "$DISTRIBUTION_ID" ]; then
    echo "☁️  Invalidating CloudFront cache..."
    aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
    echo "✅ Update completed successfully!"
    echo "🌐 Your app will be updated within a few minutes."
    if [ -n "$CLOUDFRONT_URL" ]; then
        echo "🔗 CloudFront URL: $CLOUDFRONT_URL"
    fi
else
    echo "✅ S3 update completed successfully!"
    echo "🌐 Your app is updated on S3."
    if [ -n "$S3_WEBSITE_URL" ]; then
        echo "🔗 S3 Website URL: $S3_WEBSITE_URL"
    fi
fi 