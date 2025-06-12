# Flutter Web App Deployment Guide
# S3 + CloudFront Hosting

This guide will help you deploy your Protrack Flutter web application to AWS S3 with CloudFront CDN for optimal performance and global distribution.

## ✅ Prerequisites

Before starting, ensure you have:

1. **AWS CLI installed and configured**
   ```bash
   # Install AWS CLI (macOS)
   brew install awscli
   
   # Or download from: https://aws.amazon.com/cli/
   
   # Configure AWS CLI with your credentials
   aws configure
   ```

2. **Flutter SDK installed** (already have this)

3. **AWS Account** with appropriate permissions for:
   - S3 (CreateBucket, PutObject, PutBucketPolicy, PutBucketWebsite)
   - CloudFront (CreateDistribution)

## 🚀 Quick Deployment

### Option 1: Automated Deployment (Recommended)

1. **Run the deployment script:**
   ```bash
   ./deploy-to-s3.sh
   ```

   This script will:
   - Create a unique S3 bucket
   - Configure static website hosting
   - Upload your Flutter web build
   - Create CloudFront distribution
   - Provide you with the URLs

2. **Wait for CloudFront deployment** (15-20 minutes)

3. **Access your app** at the provided CloudFront URL

### Option 2: Manual Deployment

If you prefer manual control or need to customize the process:

#### Step 1: Build Flutter Web App
```bash
flutter build web --release --base-href "/"
```

#### Step 2: Create S3 Bucket
```bash
# Replace 'your-unique-bucket-name' with your desired bucket name
BUCKET_NAME="protrack-web-app-$(date +%s)"
REGION="us-east-1"

aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
```

#### Step 3: Enable Static Website Hosting
```bash
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html
```

#### Step 4: Set Bucket Policy
```bash
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
```

#### Step 5: Upload Files
```bash
aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete
```

#### Step 6: Create CloudFront Distribution
```bash
aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json
```

## 🔄 Updating Your App

After making changes to your Flutter app:

### Option 1: Use Update Script
1. Edit `update-app.sh` and add your bucket name and distribution ID
2. Run:
   ```bash
   ./update-app.sh
   ```

### Option 2: Manual Update
```bash
# 1. Build the app
flutter build web --release --base-href "/"

# 2. Upload to S3
aws s3 sync build/web/ s3://YOUR_BUCKET_NAME/ --delete

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## 🌐 Custom Domain Setup (Optional)

To use your own domain (e.g., app.yourdomain.com):

1. **Get SSL Certificate** (ACM - must be in us-east-1 for CloudFront):
   ```bash
   aws acm request-certificate \
       --domain-name app.yourdomain.com \
       --validation-method DNS \
       --region us-east-1
   ```

2. **Update CloudFront Distribution** to include your domain

3. **Create Route 53 record** pointing to CloudFront distribution

## 📊 Cost Estimation

For a typical small to medium app with moderate traffic:

| Service | Monthly Cost |
|---------|-------------|
| S3 Storage (1GB) | ~$0.25 |
| S3 Requests | ~$0.50 |
| CloudFront (100GB transfer) | ~$8.50 |
| **Total** | **~$9.25/month** |

*Costs may vary based on actual usage and AWS pricing changes*

## 🔧 Configuration Options

### Environment-Specific Builds
For different environments, you can modify the build command:

```bash
# Development
flutter build web --release --dart-define=ENV=dev

# Staging
flutter build web --release --dart-define=ENV=staging

# Production
flutter build web --release --dart-define=ENV=prod
```

### Performance Optimizations

1. **Enable compression** in CloudFront
2. **Set appropriate cache headers**
3. **Use appropriate file types** (already configured in script)

## 🛠️ Troubleshooting

### Common Issues

1. **App shows blank page**
   - Check browser console for errors
   - Verify base-href is set correctly
   - Ensure all assets are uploaded

2. **Assets not loading**
   - Check S3 bucket permissions
   - Verify CloudFront cache settings
   - Invalidate CloudFront cache

3. **Authentication issues**
   - Update CORS settings in your backend
   - Check Cognito configuration for web domain

### Debug Commands
```bash
# Check S3 bucket contents
aws s3 ls s3://YOUR_BUCKET_NAME --recursive

# Check CloudFront distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID

# Create cache invalidation
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## 📝 Important Notes

1. **CloudFront takes time**: Initial deployment takes 15-20 minutes
2. **Cache invalidation**: May take 10-15 minutes to propagate
3. **Flutter web limitations**: Some mobile-specific features may not work
4. **Browser compatibility**: Modern browsers required for full functionality

## 🔒 Security Considerations

1. **HTTPS only**: CloudFront redirects HTTP to HTTPS
2. **CORS**: Configure your backend APIs for web domain
3. **CSP**: Consider Content Security Policy headers
4. **API Keys**: Ensure sensitive keys are not exposed in web build

## 📞 Support

If you encounter issues:
1. Check AWS CloudWatch logs
2. Review Flutter web documentation
3. Test locally with `flutter run -d chrome --web-renderer html`

---

**Generated on:** $(date)
**Flutter Version:** $(flutter --version | head -1)
**Target:** AWS S3 + CloudFront 