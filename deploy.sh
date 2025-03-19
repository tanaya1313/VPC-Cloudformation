#!/bin/bash

STACK_NAME=$1
TEMPLATE_FILE=$2
PARAMETERS_FILE=$3
REGION=${4:-us-east-1}  # Default to us-east-1 if not provided

if [ -z "$STACK_NAME" ] || [ -z "$TEMPLATE_FILE" ] || [ -z "$PARAMETERS_FILE" ]; then
    echo "Usage: $0 <stack-name> <template-file> <parameters-file> [region]"
    exit 1
fi

# Check if stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" 2>&1)
if echo "$STACK_EXISTS" | grep -q "ValidationError" && echo "$STACK_EXISTS" | grep -q "does not exist"; then
    echo "Stack does not exist. Creating..."
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters "file://$PARAMETERS_FILE" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION"
else
    echo "Stack exists. Updating..."
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters "file://$PARAMETERS_FILE" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION"
fi

# Wait for stack operation to complete
echo "Waiting for stack operation to complete..."
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION" || \
aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$REGION"

echo "Deployment completed successfully."