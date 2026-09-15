#!/usr/bin/env bash

BUCKET="$1"
REGION="$2"

if [ -z "$BUCKET" ] || [ -z "$REGION" ]; then
    echo "Usage: ./validate-access.sh <bucket-name> <region>"
    exit 1
fi

echo "======================================"
echo "BLACKSITE ACCESS VALIDATION"
echo "======================================"

echo
echo "[TEST 1] Authorized prefix listing"

if aws s3 ls "s3://${BUCKET}/allowed/" --region "$REGION"; then
    echo "[PASS] Authorized prefix accessible"
else
    echo "[FAIL] Authorized prefix inaccessible"
fi

echo
echo "[TEST 2] Authorized object download"

if aws s3 cp \
    "s3://${BUCKET}/allowed/mission-brief.txt" \
    /tmp/mission-brief.txt \
    --region "$REGION"; then
    echo "[PASS] Authorized object download succeeded"
else
    echo "[FAIL] Authorized object download failed"
fi

echo
echo "[TEST 3] Authorized object upload"

echo "BLACKSITE validation $(date -u)" > /tmp/blacksite-validation.txt

if aws s3 cp \
    /tmp/blacksite-validation.txt \
    "s3://${BUCKET}/allowed/automated-validation.txt" \
    --region "$REGION"; then
    echo "[PASS] Authorized object upload succeeded"
else
    echo "[FAIL] Authorized object upload failed"
fi

echo
echo "[TEST 4] Restricted object access"

if aws s3 cp \
    "s3://${BUCKET}/restricted/admin-only.txt" \
    /tmp/admin-only.txt \
    --region "$REGION"; then
    echo "[FAIL] Restricted object was accessible"
else
    echo "[PASS] Restricted object access denied"
fi

echo
echo "======================================"
echo "VALIDATION COMPLETE"
echo "======================================"