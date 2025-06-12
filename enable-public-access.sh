#!/bin/bash

# Helper script to enable public access for S3 static website hosting
# Use this if you only want S3 hosting without CloudFront

set -e

# Configuration (Update to match your bucket)
BUCKET_NAME="protrack-web-app"  # Your bucket name

echo "🔓 Enabling public access for S3 bucket: $BUCKET_NAME"

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run: aws configure"
    exit 1
fi

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

# Wait for settings to propagate
echo "⏳ Waiting 3 seconds for settings to propagate..."
sleep 3

# Step 2: Create and apply bucket policy
echo "🔓 Setting bucket policy for public read access..."
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

echo "✅ Public access enabled successfully!"
echo ""
echo "📊 S3 Website Information:"
echo "========================="
echo "S3 Bucket: $BUCKET_NAME"
echo "S3 Website URL: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
echo ""
echo "🌐 Your Flutter app is now publicly accessible via the S3 website URL above."
echo ""
echo "🔒 Security Note:"
echo "Block Public Access settings have been disabled for this bucket."
echo "This is required for static website hosting but be aware of the security implications."
echo "Only the contents of your bucket are publicly readable, not writable." 