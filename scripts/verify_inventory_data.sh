#!/bin/bash

# Verify sample inventory data
REGION="us-east-1"
TABLE_NAME="Instruments"

echo "🔍 Verifying sample inventory data..."
echo ""

# Count Labs
LAB_COUNT=$(aws dynamodb scan --table-name $TABLE_NAME --filter-expression "#type = :type" --expression-attribute-names '{"#type":"type"}' --expression-attribute-values '{":type":{"S":"LAB"}}' --query 'Count' --output text)
echo "📊 Labs found: $LAB_COUNT"

# Count Categories
CATEGORY_COUNT=$(aws dynamodb scan --table-name $TABLE_NAME --filter-expression "#type = :type" --expression-attribute-names '{"#type":"type"}' --expression-attribute-values '{":type":{"S":"CATEGORY"}}' --query 'Count' --output text)
echo "📊 Categories found: $CATEGORY_COUNT"

# Count Entries
ENTRY_COUNT=$(aws dynamodb scan --table-name $TABLE_NAME --filter-expression "#type = :type" --expression-attribute-names '{"#type":"type"}' --expression-attribute-values '{":type":{"S":"ENTRY"}}' --query 'Count' --output text)
echo "📊 Entries found: $ENTRY_COUNT"

echo ""
echo "🏢 Sample Labs Created:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type" \
    --expression-attribute-names '{"#type":"type"}' \
    --expression-attribute-values '{":type":{"S":"LAB"}}' \
    --query 'Items[].[name.S, location.S, status.S]' \
    --output text | while read name location status; do
        echo "   ✓ $name ($location) - $status"
done

echo ""
echo "📂 Sample Categories by Type:"

echo "   🔬 INSTRUMENTS Categories:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type AND categoryType = :catType" \
    --expression-attribute-names '{"#type":"type"}' \
    --expression-attribute-values '{":type":{"S":"CATEGORY"}, ":catType":{"S":"INSTRUMENTS"}}' \
    --query 'Items[].[name.S]' \
    --output text | while read name; do
        echo "      - $name"
done

echo "   🧪 CHEMICALS Categories:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type AND categoryType = :catType" \
    --expression-attribute-names '{"#type":"type"}' \
    --expression-attribute-values '{":type":{"S":"CATEGORY"}, ":catType":{"S":"CHEMICALS"}}' \
    --query 'Items[].[name.S]' \
    --output text | while read name; do
        echo "      - $name"
done

echo "   🦠 CULTURES Categories:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type AND categoryType = :catType" \
    --expression-attribute-names '{"#type":"type"}' \
    --expression-attribute-values '{":type":{"S":"CATEGORY"}, ":catType":{"S":"CULTURES"}}' \
    --query 'Items[].[name.S]' \
    --output text | while read name; do
        echo "      - $name"
done

echo ""
echo "📋 Sample Entries by Status:"

echo "   ✅ AVAILABLE Entries:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type AND #status = :status" \
    --expression-attribute-names '{"#type":"type", "#status":"status"}' \
    --expression-attribute-values '{":type":{"S":"ENTRY"}, ":status":{"S":"AVAILABLE"}}' \
    --query 'Items[].[name.S, availableQuantity.N]' \
    --output text | while read name qty; do
        echo "      - $name (Qty: $qty)"
done

echo "   🔄 IN_USE Entries:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type AND #status = :status" \
    --expression-attribute-names '{"#type":"type", "#status":"status"}' \
    --expression-attribute-values '{":type":{"S":"ENTRY"}, ":status":{"S":"IN_USE"}}' \
    --query 'Items[].[name.S]' \
    --output text | while read name; do
        echo "      - $name"
done

echo "   🔧 MAINTENANCE Entries:"
aws dynamodb scan --table-name $TABLE_NAME \
    --filter-expression "#type = :type AND #status = :status" \
    --expression-attribute-names '{"#type":"type", "#status":"status"}' \
    --expression-attribute-values '{":type":{"S":"ENTRY"}, ":status":{"S":"MAINTENANCE"}}' \
    --query 'Items[].[name.S]' \
    --output text | while read name; do
        echo "      - $name"
done

echo ""
echo "✅ Sample data verification complete!"
echo ""
echo "🚀 Ready to test in your Flutter app:"
echo "   1. Run 'flutter run'"
echo "   2. Login to the app"
echo "   3. Open the drawer and select 'Inventory'"
echo "   4. You should see the 3 sample labs"
echo "   5. Click on any lab to see its categories"
echo "   6. Add new labs and categories to test the functionality" 