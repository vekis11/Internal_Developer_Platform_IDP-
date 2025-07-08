#!/bin/bash

# Internal Developer Platform Deployment Script
# This script automates the deployment of the complete IDP stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLATFORM_NAME="internal-developer-platform"
BACKSTAGE_NAMESPACE="backstage"
ARGOCD_NAMESPACE="argocd"
MONITORING_NAMESPACE="monitoring"
DEVELOPMENT_NAMESPACE="development"
STAGING_NAMESPACE="staging"
PRODUCTION_NAMESPACE="production"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi
    
    # Check docker
    if ! command -v docker &> /dev/null; then
        print_error "docker is not installed"
        exit 1
    fi
    
    # Check if connected to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to Kubernetes cluster"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to load environment variables
load_env() {
    print_status "Loading environment variables..."
    
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_success "Environment variables loaded from .env"
    else
        print_warning "No .env file found. Using default values."
    fi
    
    # Set default values if not provided
    export AUTH_SECRET=${AUTH_SECRET:-"default-auth-secret-change-me"}
    export POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD:-"default-postgresql-password"}
    export REDIS_PASSWORD=${REDIS_PASSWORD:-"default-redis-password"}
    export GITHUB_TOKEN=${GITHUB_TOKEN:-""}
    export GITLAB_TOKEN=${GITLAB_TOKEN:-""}
    export AZURE_TOKEN=${AZURE_TOKEN:-""}
}

# Function to create namespaces
create_namespaces() {
    print_status "Creating Kubernetes namespaces..."
    
    kubectl apply -f kubernetes/namespaces/
    
    print_success "Namespaces created"
}

# Function to deploy RBAC
deploy_rbac() {
    print_status "Deploying RBAC configuration..."
    
    kubectl apply -f kubernetes/rbac/
    
    print_success "RBAC configuration deployed"
}

# Function to create secrets
create_secrets() {
    print_status "Creating Kubernetes secrets..."
    
    # Create backstage secrets
    kubectl create secret generic backstage-secrets \
        --from-literal=auth-secret="$AUTH_SECRET" \
        --from-literal=github-token="$GITHUB_TOKEN" \
        --from-literal=gitlab-token="$GITLAB_TOKEN" \
        --from-literal=azure-token="$AZURE_TOKEN" \
        --from-literal=postgresql-password="$POSTGRESQL_PASSWORD" \
        --from-literal=redis-password="$REDIS_PASSWORD" \
        --from-literal=k8s-service-account-token="$K8S_SERVICE_ACCOUNT_TOKEN" \
        --from-literal=k8s-staging-token="$K8S_STAGING_TOKEN" \
        --from-literal=k8s-prod-token="$K8S_PROD_TOKEN" \
        --from-literal=argocd-username="$ARGOCD_USERNAME" \
        --from-literal=argocd-password="$ARGOCD_PASSWORD" \
        --from-literal=jenkins-username="$JENKINS_USERNAME" \
        --from-literal=jenkins-api-key="$JENKINS_API_KEY" \
        --from-literal=sonarqube-api-key="$SONARQUBE_API_KEY" \
        --from-literal=grafana-api-key="$GRAFANA_API_KEY" \
        --from-literal=rollbar-organization="$ROLLBAR_ORGANIZATION" \
        --from-literal=rollbar-api-token="$ROLLBAR_API_TOKEN" \
        --from-literal=sentry-organization="$SENTRY_ORGANIZATION" \
        --from-literal=sentry-project="$SENTRY_PROJECT" \
        --from-literal=sentry-token="$SENTRY_TOKEN" \
        --from-literal=pagerduty-integration-key="$PAGERDUTY_INTEGRATION_KEY" \
        --from-literal=airbrake-project-id="$AIRBRAKE_PROJECT_ID" \
        --from-literal=airbrake-project-key="$AIRBRAKE_PROJECT_KEY" \
        --from-literal=dynatrace-api-token="$DYNATRACE_API_TOKEN" \
        --from-literal=newrelic-account-id="$NEWRELIC_ACCOUNT_ID" \
        --from-literal=newrelic-api-key="$NEWRELIC_API_KEY" \
        --from-literal=aws-access-key-id="$AWS_ACCESS_KEY_ID" \
        --from-literal=aws-secret-access-key="$AWS_SECRET_ACCESS_KEY" \
        -n "$BACKSTAGE_NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Secrets created"
}

# Function to deploy ArgoCD
deploy_argocd() {
    print_status "Deploying ArgoCD..."
    
    # Add ArgoCD Helm repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Deploy ArgoCD
    helm upgrade --install argocd argo/argo-cd \
        --namespace "$ARGOCD_NAMESPACE" \
        --create-namespace \
        --set server.ingress.enabled=true \
        --set server.ingress.hosts[0]="${ARGOCD_HOST:-argocd.company.com}" \
        --set server.ingress.tls[0].secretName=argocd-tls \
        --set server.ingress.tls[0].hosts[0]="${ARGOCD_HOST:-argocd.company.com}" \
        --set server.ingress.annotations."kubernetes\.io/ingress\.class"=nginx \
        --set server.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
        --wait --timeout=10m
    
    print_success "ArgoCD deployed"
}

# Function to build and deploy Backstage
deploy_backstage() {
    print_status "Building and deploying Backstage..."
    
    # Build Backstage Docker image
    cd backstage
    
    # Install dependencies
    yarn install --frozen-lockfile
    
    # Build the application
    yarn build
    
    # Build Docker image
    docker build -t "$PLATFORM_NAME:latest" .
    
    # Push to registry if REGISTRY is set
    if [ ! -z "$REGISTRY" ]; then
        docker tag "$PLATFORM_NAME:latest" "$REGISTRY/$PLATFORM_NAME:latest"
        docker push "$REGISTRY/$PLATFORM_NAME:latest"
        IMAGE_TAG="$REGISTRY/$PLATFORM_NAME:latest"
    else
        IMAGE_TAG="$PLATFORM_NAME:latest"
    fi
    
    cd ..
    
    # Deploy Backstage using Helm
    helm upgrade --install backstage ./helm-charts/backstage \
        --namespace "$BACKSTAGE_NAMESPACE" \
        --create-namespace \
        --set image.repository="$IMAGE_TAG" \
        --set image.tag=latest \
        --set postgresql.auth.password="$POSTGRESQL_PASSWORD" \
        --set redis.auth.password="$REDIS_PASSWORD" \
        --set ingress.hosts[0].host="${BACKSTAGE_HOST:-backstage.company.com}" \
        --set ingress.tls[0].hosts[0]="${BACKSTAGE_HOST:-backstage.company.com}" \
        --wait --timeout=10m
    
    print_success "Backstage deployed"
}

# Function to deploy ArgoCD applications
deploy_argocd_apps() {
    print_status "Deploying ArgoCD applications..."
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n "$ARGOCD_NAMESPACE" --timeout=300s
    
    # Deploy ArgoCD projects
    kubectl apply -f argocd/projects/
    
    # Deploy ArgoCD applications
    kubectl apply -f argocd/applications/
    
    print_success "ArgoCD applications deployed"
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_status "Deploying monitoring stack..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Deploy Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace "$MONITORING_NAMESPACE" \
        --create-namespace \
        --set grafana.enabled=true \
        --set prometheus.enabled=true \
        --set alertmanager.enabled=true \
        --wait --timeout=10m
    
    print_success "Monitoring stack deployed"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check Backstage
    if kubectl get deployment backstage -n "$BACKSTAGE_NAMESPACE" &> /dev/null; then
        kubectl wait --for=condition=available deployment/backstage -n "$BACKSTAGE_NAMESPACE" --timeout=300s
        print_success "Backstage is running"
    else
        print_error "Backstage deployment not found"
        return 1
    fi
    
    # Check ArgoCD
    if kubectl get deployment argocd-server -n "$ARGOCD_NAMESPACE" &> /dev/null; then
        kubectl wait --for=condition=available deployment/argocd-server -n "$ARGOCD_NAMESPACE" --timeout=300s
        print_success "ArgoCD is running"
    else
        print_error "ArgoCD deployment not found"
        return 1
    fi
    
    # Check monitoring
    if kubectl get deployment prometheus-grafana -n "$MONITORING_NAMESPACE" &> /dev/null; then
        kubectl wait --for=condition=available deployment/prometheus-grafana -n "$MONITORING_NAMESPACE" --timeout=300s
        print_success "Monitoring stack is running"
    else
        print_warning "Monitoring stack not found"
    fi
    
    print_success "Deployment verification completed"
}

# Function to display access information
display_access_info() {
    print_status "Deployment completed successfully!"
    echo ""
    echo "Access Information:"
    echo "=================="
    echo ""
    echo "Backstage Portal:"
    echo "  URL: https://${BACKSTAGE_HOST:-backstage.company.com}"
    echo "  Default Credentials: guest/guest"
    echo ""
    echo "ArgoCD Dashboard:"
    echo "  URL: https://${ARGOCD_HOST:-argocd.company.com}"
    echo "  Username: admin"
    echo "  Password: $(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    echo ""
    echo "Grafana Dashboard:"
    echo "  URL: https://${GRAFANA_HOST:-grafana.company.com}"
    echo "  Default Credentials: admin/prom-operator"
    echo ""
    echo "Useful Commands:"
    echo "================"
    echo "  kubectl get pods -n $BACKSTAGE_NAMESPACE"
    echo "  kubectl get pods -n $ARGOCD_NAMESPACE"
    echo "  kubectl get pods -n $MONITORING_NAMESPACE"
    echo "  kubectl logs -f deployment/backstage -n $BACKSTAGE_NAMESPACE"
    echo "  argocd app list"
    echo ""
}

# Function to cleanup on failure
cleanup() {
    print_error "Deployment failed. Cleaning up..."
    
    # Delete namespaces
    kubectl delete namespace "$BACKSTAGE_NAMESPACE" --ignore-not-found=true
    kubectl delete namespace "$ARGOCD_NAMESPACE" --ignore-not-found=true
    kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found=true
    
    print_warning "Cleanup completed"
}

# Main deployment function
main() {
    echo "=========================================="
    echo "Internal Developer Platform Deployment"
    echo "=========================================="
    echo ""
    
    # Set up error handling
    trap cleanup ERR
    
    # Run deployment steps
    check_prerequisites
    load_env
    create_namespaces
    deploy_rbac
    create_secrets
    deploy_argocd
    deploy_backstage
    deploy_argocd_apps
    deploy_monitoring
    verify_deployment
    display_access_info
    
    print_success "Platform deployment completed successfully!"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verify       Only verify existing deployment"
        echo "  --cleanup      Clean up all resources"
        echo ""
        echo "Environment Variables:"
        echo "  BACKSTAGE_HOST     Backstage hostname (default: backstage.company.com)"
        echo "  ARGOCD_HOST        ArgoCD hostname (default: argocd.company.com)"
        echo "  GRAFANA_HOST       Grafana hostname (default: grafana.company.com)"
        echo "  REGISTRY           Docker registry for images"
        echo ""
        exit 0
        ;;
    --verify)
        verify_deployment
        display_access_info
        exit 0
        ;;
    --cleanup)
        print_status "Cleaning up all resources..."
        kubectl delete namespace "$BACKSTAGE_NAMESPACE" --ignore-not-found=true
        kubectl delete namespace "$ARGOCD_NAMESPACE" --ignore-not-found=true
        kubectl delete namespace "$MONITORING_NAMESPACE" --ignore-not-found=true
        kubectl delete namespace "$DEVELOPMENT_NAMESPACE" --ignore-not-found=true
        kubectl delete namespace "$STAGING_NAMESPACE" --ignore-not-found=true
        kubectl delete namespace "$PRODUCTION_NAMESPACE" --ignore-not-found=true
        print_success "Cleanup completed"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac 