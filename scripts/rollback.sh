#!/bin/bash

ENVIRONMENT=$1
REVISION=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$REVISION" ]; then
    echo "Usage: ./rollback.sh <dev|staging|production> <revision-number>"
    exit 1
fi

echo "Rolling back backend to revision $REVISION"
helm rollback ecommerce-backend $REVISION -n ecommerce-$ENVIRONMENT

echo "Rolling back frontend to revision $REVISION"
helm rollback ecommerce-frontend $REVISION -n ecommerce-$ENVIRONMENT

echo "Rollback completed!"
