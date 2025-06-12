#!/bin/bash

# Flutter Web App S3 + CloudFront Deployment Script
# This script will create an S3 bucket, upload your Flutter web app, and set up CloudFront

set -e

# Configuration (Update these values)
#BUCKET_NAME="protrack-web-app-$(date +%s)"  # Unique bucket name
BUCKET_NAME="protrack-web-app"  # Unique bucket name
REGION="us-east-1"  # Change to your preferred region
DOMAIN_NAME=""  # Optional: your custom domain (e.g., app.yourdomain.com)

echo "🚀 Starting deployment of Flutter Web App to S3 + CloudFront"
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

# Step 1: Create S3 bucket
echo "📦 Creating S3 bucket..."
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
else
    aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION
fi

# Step 2: Enable static website hosting
echo "🌐 Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html

# Step 3: Set bucket policy for public read access
echo "🔓 Setting bucket policy for public access..."
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json
rm bucket-policy.json

# Step 4: Upload Flutter web build
echo "📁 Uploading Flutter web build to S3..."
aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete

# Set correct content types for important files
echo "🏷️  Setting content types..."
aws s3 cp s3://$BUCKET_NAME/main.dart.js s3://$BUCKET_NAME/main.dart.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter.js s3://$BUCKET_NAME/flutter.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter_bootstrap.js s3://$BUCKET_NAME/flutter_bootstrap.js --content-type "application/javascript" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/flutter_service_worker.js s3://$BUCKET_NAME/flutter_service_worker.js --content-type "application/javascript" --metadata-directive REPLACE

# Step 5: Create CloudFront distribution
echo "☁️  Creating CloudFront distribution..."
cat > cloudfront-config.json << EOF
{
    "CallerReference": "protrack-$(date +%s)",
    "Aliases": {
        "Quantity": 0
    },
    "DefaultRootObject": "index.html",
    "Comment": "Protrack Flutter Web App",
    "Enabled": true,
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        }
    },
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "PriceClass": "PriceClass_100"
}
EOF

DISTRIBUTION_OUTPUT=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json)
DISTRIBUTION_ID=$(echo $DISTRIBUTION_OUTPUT | grep -o '"Id": "[^"]*"' | head -1 | sed 's/"Id": "\([^"]*\)"/\1/')
DISTRIBUTION_DOMAIN=$(echo $DISTRIBUTION_OUTPUT | grep -o '"DomainName": "[^"]*"' | head -1 | sed 's/"DomainName": "\([^"]*\)"/\1/')

rm cloudfront-config.json

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "===================="
echo "S3 Bucket: $BUCKET_NAME"
echo "S3 Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"
echo "CloudFront URL: https://$DISTRIBUTION_DOMAIN"
echo ""
echo "⏳ Note: CloudFront distribution is being deployed. It may take 15-20 minutes to be fully available."
echo ""
echo "🔧 Next Steps:"
echo "1. Test your app at: https://$DISTRIBUTION_DOMAIN"
echo "2. (Optional) Set up custom domain using Route 53"
echo "3. (Optional) Configure SSL certificate using AWS Certificate Manager"
echo ""
echo "💰 Estimated monthly cost for low traffic:"
echo "- S3: ~$1-5/month"
echo "- CloudFront: ~$1-10/month"
echo ""
echo "🔄 To update your app:"
echo "1. Run: flutter build web --release"
echo "2. Run: aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete"
echo "3. Run: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'" 