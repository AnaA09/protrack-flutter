#!/bin/bash

# Flutter Web App CloudFront Setup Script (Part 2)  
# This script will set bucket permissions and create CloudFront distribution

set -e

# Configuration (Update these values to match deploy-s3.sh)
BUCKET_NAME="protrack-web-app"  # Your bucket name (must match deploy-s3.sh)
REGION="us-east-1"  # Change to your preferred region (must match deploy-s3.sh)
DOMAIN_NAME=""  # Optional: your custom domain (e.g., app.yourdomain.com)

echo "☁️  Starting CloudFront setup for Flutter Web App"
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

# Check if bucket exists
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "❌ Bucket $BUCKET_NAME does not exist. Please run './deploy-s3.sh' first."
    exit 1
fi

echo "✅ Bucket $BUCKET_NAME found"

# Step 1: Disable Block Public Access settings
echo "🔓 Disabling Block Public Access settings..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo "✅ Block Public Access settings disabled"

# Wait a moment for the settings to propagate
echo "⏳ Waiting 3 seconds for settings to propagate..."
sleep 3

# Step 2: Set bucket policy for public read access
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

echo "✅ Bucket policy set for public access"

# Step 3: Create CloudFront distribution
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

# Save deployment info for future updates
cat > deployment-info.txt << EOF
# Deployment Information
# Generated on: $(date)
BUCKET_NAME=$BUCKET_NAME
REGION=$REGION
DISTRIBUTION_ID=$DISTRIBUTION_ID
DISTRIBUTION_DOMAIN=$DISTRIBUTION_DOMAIN
S3_WEBSITE_URL=http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com
CLOUDFRONT_URL=https://$DISTRIBUTION_DOMAIN
EOF

echo "✅ CloudFront setup completed successfully!"
echo ""
echo "📊 Complete Deployment Summary:"
echo "==============================="
echo "S3 Bucket: $BUCKET_NAME"
echo "S3 Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"
echo "CloudFront URL: https://$DISTRIBUTION_DOMAIN"
echo ""
echo "⏳ Note: CloudFront distribution is being deployed. It may take 15-20 minutes to be fully available."
echo ""
echo "📁 Deployment info saved to: deployment-info.txt"
echo ""
echo "🔧 Next Steps:"
echo "1. Test your app at: https://$DISTRIBUTION_DOMAIN (wait 15-20 minutes)"
echo "2. Test S3 direct access: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
echo "3. (Optional) Set up custom domain using Route 53"
echo "4. (Optional) Configure SSL certificate using AWS Certificate Manager"
echo ""
echo "💰 Estimated monthly cost for low traffic:"
echo "- S3: ~$1-5/month"
echo "- CloudFront: ~$1-10/month"
echo ""
echo "🔄 To update your app in the future:"
echo "1. Run: ./deploy-s3.sh (builds and uploads to S3)"
echo "2. Run: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
echo "3. Or use: ./update-app.sh (after updating it with the deployment info)"
echo ""
echo "🔒 Security Note:"
echo "Block Public Access settings have been disabled for this bucket to allow public website hosting."
echo "This is normal for static website hosting but be aware of the security implications." 