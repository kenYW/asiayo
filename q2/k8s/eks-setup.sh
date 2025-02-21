#!/bin/bash
set -x

CLUSTER_NAME=$1




export KUBECONFIG=$(pwd)/k8s/$CLUSTER_NAME.config

## apply q2 deployment
kubectl apply -f "$(dirname "$0")/yaml/"

