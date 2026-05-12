#!/bin/bash

# ==============================================================================
# 💰 INFRACOST BUDGET GUARDRAIL SCRIPT (Hidden Folder Edition)
# ==============================================================================

# Ensure the hidden .infracost folder exists
mkdir -p .infracost

# 1. Run Infracost breakdown inside Docker, saving to the hidden folder
docker run --rm \
  -v "$(pwd):/code" \
  -e INFRACOST_API_KEY="$INFRACOST_API_KEY" \
  infracost/infracost:ci-latest breakdown \
  --path /code \
  --format json \
  --out-file /code/.infracost/infracost.json

# Check if the file was created successfully
if [ ! -f .infracost/infracost.json ]; then
    echo "❌ [ERROR] Infracost failed to generate .infracost/infracost.json"
    exit 1
fi

# 2. Extract the overall totalMonthlyCost value
TOTAL=$(grep -o '"totalMonthlyCost":"[0-9.]*"' .infracost/infracost.json | cut -d':' -f2 | tr -d '"' | tail -n 1)

if [ -z "$TOTAL" ]; then
    echo "❌ [ERROR] Could not extract cost from .infracost/infracost.json"
    exit 1
fi

echo "💰 Current Monthly Cost Estimate: \$$TOTAL"

# 3. Budget threshold evaluation ($100.00)
IS_OVER_BUDGET=$(awk -v cost="$TOTAL" 'BEGIN { if (cost > 100.00) print 1; else print 0 }')

if [ "$IS_OVER_BUDGET" -eq 1 ]; then
    echo "❌ [COST ERROR] Above \$100 budget! Rejecting commit."
    echo "👉 Action: Go to 'variables.tf' and reduce instance sizes."
    exit 1
else
    echo "✅ [COST OK] Within budget. Proceeding..."
    exit 0
fi