# Internal Developer Platform Deployment Script (PowerShell)
# This script automates the deployment of the complete IDP stack

param(
    [switch]$Help,
    [switch]$Verify,
    [switch]$Cleanup
)

# Configuration
$PLATFORM_NAME = "internal-developer-platform"
$BACKSTAGE_NAMESPACE = "backstage"
$ARGOCD_NAMESPACE = "argocd"
$MONITORING_NAMESPACE = "monitoring"
$DEVELOPMENT_NAMESPACE = "development"
$STAGING_NAMESPACE = "staging"
$PRODUCTION_NAMESPACE = "production"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed"
        exit 1
    }
    
    # Check helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Error "helm is not installed"
        exit 1
    }
    
    # Check docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "docker is not installed"
        exit 1
    }
    
    # Check if connected to cluster
    try {
        kubectl cluster-info | Out-Null
    }
    catch {
        Write-Error "Not connected to Kubernetes cluster"
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

# Function to load environment variables
function Load-Environment {
    Write-Status "Loading environment variables..."
    
    if (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            if ($_ -match "^([^#][^=]+)=(.*)$") {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
        Write-Success "Environment variables loaded from .env"
    }
    else {
        Write-Warning "No .env file found. Using default values."
    }
    
    # Set default values if not provided
    if (-not $env:AUTH_SECRET) { $env:AUTH_SECRET = "default-auth-secret-change-me" }
    if (-not $env:POSTGRESQL_PASSWORD) { $env:POSTGRESQL_PASSWORD = "default-postgresql-password" }
    if (-not $env:REDIS_PASSWORD) { $env:REDIS_PASSWORD = "default-redis-password" }
    if (-not $env:GITHUB_TOKEN) { $env:GITHUB_TOKEN = "" }
    if (-not $env:GITLAB_TOKEN) { $env:GITLAB_TOKEN = "" }
    if (-not $env:AZURE_TOKEN) { $env:AZURE_TOKEN = "" }
}

# Function to create namespaces
function New-Namespaces {
    Write-Status "Creating Kubernetes namespaces..."
    
    kubectl apply -f kubernetes/namespaces/
    
    Write-Success "Namespaces created"
}

# Function to deploy RBAC
function Deploy-RBAC {
    Write-Status "Deploying RBAC configuration..."
    
    kubectl apply -f kubernetes/rbac/
    
    Write-Success "RBAC configuration deployed"
}

# Function to create secrets
function New-Secrets {
    Write-Status "Creating Kubernetes secrets..."
    
    # Create backstage secrets
    $secretData = @{
        "auth-secret" = $env:AUTH_SECRET
        "github-token" = $env:GITHUB_TOKEN
        "gitlab-token" = $env:GITLAB_TOKEN
        "azure-token" = $env:AZURE_TOKEN
        "postgresql-password" = $env:POSTGRESQL_PASSWORD
        "redis-password" = $env:REDIS_PASSWORD
        "k8s-service-account-token" = $env:K8S_SERVICE_ACCOUNT_TOKEN
        "k8s-staging-token" = $env:K8S_STAGING_TOKEN
        "k8s-prod-token" = $env:K8S_PROD_TOKEN
        "argocd-username" = $env:ARGOCD_USERNAME
        "argocd-password" = $env:ARGOCD_PASSWORD
        "jenkins-username" = $env:JENKINS_USERNAME
        "jenkins-api-key" = $env:JENKINS_API_KEY
        "sonarqube-api-key" = $env:SONARQUBE_API_KEY
        "grafana-api-key" = $env:GRAFANA_API_KEY
        "rollbar-organization" = $env:ROLLBAR_ORGANIZATION
        "rollbar-api-token" = $env:ROLLBAR_API_TOKEN
        "sentry-organization" = $env:SENTRY_ORGANIZATION
        "sentry-project" = $env:SENTRY_PROJECT
        "sentry-token" = $env:SENTRY_TOKEN
        "pagerduty-integration-key" = $env:PAGERDUTY_INTEGRATION_KEY
        "airbrake-project-id" = $env:AIRBRAKE_PROJECT_ID
        "airbrake-project-key" = $env:AIRBRAKE_PROJECT_KEY
        "dynatrace-api-token" = $env:DYNATRACE_API_TOKEN
        "newrelic-account-id" = $env:NEWRELIC_ACCOUNT_ID
        "newrelic-api-key" = $env:NEWRELIC_API_KEY
        "aws-access-key-id" = $env:AWS_ACCESS_KEY_ID
        "aws-secret-access-key" = $env:AWS_SECRET_ACCESS_KEY
    }
    
    $secretYaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: backstage-secrets
  namespace: $BACKSTAGE_NAMESPACE
type: Opaque
data:
"@
    
    foreach ($key in $secretData.Keys) {
        if ($secretData[$key]) {
            $value = [System.Text.Encoding]::UTF8.GetBytes($secretData[$key])
            $base64Value = [System.Convert]::ToBase64String($value)
            $secretYaml += "`n  $key`: $base64Value"
        }
    }
    
    $secretYaml | kubectl apply -f -
    
    Write-Success "Secrets created"
}

# Function to deploy ArgoCD
function Deploy-ArgoCD {
    Write-Status "Deploying ArgoCD..."
    
    # Add ArgoCD Helm repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Deploy ArgoCD
    $argocdHost = if ($env:ARGOCD_HOST) { $env:ARGOCD_HOST } else { "argocd.company.com" }
    
    helm upgrade --install argocd argo/argo-cd `
        --namespace $ARGOCD_NAMESPACE `
        --create-namespace `
        --set server.ingress.enabled=true `
        --set server.ingress.hosts[0]=$argocdHost `
        --set server.ingress.tls[0].secretName=argocd-tls `
        --set server.ingress.tls[0].hosts[0]=$argocdHost `
        --set server.ingress.annotations."kubernetes\.io/ingress\.class"=nginx `
        --set server.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod `
        --wait --timeout=10m
    
    Write-Success "ArgoCD deployed"
}

# Function to build and deploy Backstage
function Deploy-Backstage {
    Write-Status "Building and deploying Backstage..."
    
    # Build Backstage Docker image
    Push-Location backstage
    
    # Install dependencies
    yarn install --frozen-lockfile
    
    # Build the application
    yarn build
    
    # Build Docker image
    docker build -t "$PLATFORM_NAME`:latest" .
    
    # Push to registry if REGISTRY is set
    if ($env:REGISTRY) {
        docker tag "$PLATFORM_NAME`:latest" "$env:REGISTRY/$PLATFORM_NAME`:latest"
        docker push "$env:REGISTRY/$PLATFORM_NAME`:latest"
        $imageTag = "$env:REGISTRY/$PLATFORM_NAME`:latest"
    }
    else {
        $imageTag = "$PLATFORM_NAME`:latest"
    }
    
    Pop-Location
    
    # Deploy Backstage using Helm
    $backstageHost = if ($env:BACKSTAGE_HOST) { $env:BACKSTAGE_HOST } else { "backstage.company.com" }
    
    helm upgrade --install backstage ./helm-charts/backstage `
        --namespace $BACKSTAGE_NAMESPACE `
        --create-namespace `
        --set image.repository=$imageTag `
        --set image.tag=latest `
        --set postgresql.auth.password=$env:POSTGRESQL_PASSWORD `
        --set redis.auth.password=$env:REDIS_PASSWORD `
        --set ingress.hosts[0].host=$backstageHost `
        --set ingress.tls[0].hosts[0]=$backstageHost `
        --wait --timeout=10m
    
    Write-Success "Backstage deployed"
}

# Function to deploy ArgoCD applications
function Deploy-ArgoCDApps {
    Write-Status "Deploying ArgoCD applications..."
    
    # Wait for ArgoCD to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n $ARGOCD_NAMESPACE --timeout=300s
    
    # Deploy ArgoCD projects
    kubectl apply -f argocd/projects/
    
    # Deploy ArgoCD applications
    kubectl apply -f argocd/applications/
    
    Write-Success "ArgoCD applications deployed"
}

# Function to deploy monitoring stack
function Deploy-Monitoring {
    Write-Status "Deploying monitoring stack..."
    
    # Add Prometheus Helm repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Deploy Prometheus
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
        --namespace $MONITORING_NAMESPACE `
        --create-namespace `
        --set grafana.enabled=true `
        --set prometheus.enabled=true `
        --set alertmanager.enabled=true `
        --wait --timeout=10m
    
    Write-Success "Monitoring stack deployed"
}

# Function to verify deployment
function Test-Deployment {
    Write-Status "Verifying deployment..."
    
    # Check Backstage
    try {
        kubectl get deployment backstage -n $BACKSTAGE_NAMESPACE | Out-Null
        kubectl wait --for=condition=available deployment/backstage -n $BACKSTAGE_NAMESPACE --timeout=300s
        Write-Success "Backstage is running"
    }
    catch {
        Write-Error "Backstage deployment not found or not ready"
        return 1
    }
    
    # Check ArgoCD
    try {
        kubectl get deployment argocd-server -n $ARGOCD_NAMESPACE | Out-Null
        kubectl wait --for=condition=available deployment/argocd-server -n $ARGOCD_NAMESPACE --timeout=300s
        Write-Success "ArgoCD is running"
    }
    catch {
        Write-Error "ArgoCD deployment not found or not ready"
        return 1
    }
    
    # Check monitoring
    try {
        kubectl get deployment prometheus-grafana -n $MONITORING_NAMESPACE | Out-Null
        kubectl wait --for=condition=available deployment/prometheus-grafana -n $MONITORING_NAMESPACE --timeout=300s
        Write-Success "Monitoring stack is running"
    }
    catch {
        Write-Warning "Monitoring stack not found"
    }
    
    Write-Success "Deployment verification completed"
}

# Function to display access information
function Show-AccessInfo {
    Write-Status "Deployment completed successfully!"
    Write-Host ""
    Write-Host "Access Information:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host ""
    
    $backstageHost = if ($env:BACKSTAGE_HOST) { $env:BACKSTAGE_HOST } else { "backstage.company.com" }
    $argocdHost = if ($env:ARGOCD_HOST) { $env:ARGOCD_HOST } else { "argocd.company.com" }
    $grafanaHost = if ($env:GRAFANA_HOST) { $env:GRAFANA_HOST } else { "grafana.company.com" }
    
    Write-Host "Backstage Portal:" -ForegroundColor Yellow
    Write-Host "  URL: https://$backstageHost"
    Write-Host "  Default Credentials: guest/guest"
    Write-Host ""
    
    Write-Host "ArgoCD Dashboard:" -ForegroundColor Yellow
    Write-Host "  URL: https://$argocdHost"
    Write-Host "  Username: admin"
    try {
        $argocdPassword = kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
        Write-Host "  Password: $argocdPassword"
    }
    catch {
        Write-Host "  Password: (check ArgoCD secret)"
    }
    Write-Host ""
    
    Write-Host "Grafana Dashboard:" -ForegroundColor Yellow
    Write-Host "  URL: https://$grafanaHost"
    Write-Host "  Default Credentials: admin/prom-operator"
    Write-Host ""
    
    Write-Host "Useful Commands:" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "  kubectl get pods -n $BACKSTAGE_NAMESPACE"
    Write-Host "  kubectl get pods -n $ARGOCD_NAMESPACE"
    Write-Host "  kubectl get pods -n $MONITORING_NAMESPACE"
    Write-Host "  kubectl logs -f deployment/backstage -n $BACKSTAGE_NAMESPACE"
    Write-Host "  argocd app list"
    Write-Host ""
}

# Function to cleanup
function Remove-AllResources {
    Write-Status "Cleaning up all resources..."
    
    kubectl delete namespace $BACKSTAGE_NAMESPACE --ignore-not-found=true
    kubectl delete namespace $ARGOCD_NAMESPACE --ignore-not-found=true
    kubectl delete namespace $MONITORING_NAMESPACE --ignore-not-found=true
    kubectl delete namespace $DEVELOPMENT_NAMESPACE --ignore-not-found=true
    kubectl delete namespace $STAGING_NAMESPACE --ignore-not-found=true
    kubectl delete namespace $PRODUCTION_NAMESPACE --ignore-not-found=true
    
    Write-Success "Cleanup completed"
}

# Main deployment function
function Start-Deployment {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Internal Developer Platform Deployment" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Run deployment steps
    Test-Prerequisites
    Load-Environment
    New-Namespaces
    Deploy-RBAC
    New-Secrets
    Deploy-ArgoCD
    Deploy-Backstage
    Deploy-ArgoCDApps
    Deploy-Monitoring
    Test-Deployment
    Show-AccessInfo
    
    Write-Success "Platform deployment completed successfully!"
}

# Main script logic
if ($Help) {
    Write-Host "Usage: .\deploy.ps1 [OPTIONS]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Help          Show this help message"
    Write-Host "  -Verify        Only verify existing deployment"
    Write-Host "  -Cleanup       Clean up all resources"
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor Yellow
    Write-Host "  BACKSTAGE_HOST     Backstage hostname (default: backstage.company.com)"
    Write-Host "  ARGOCD_HOST        ArgoCD hostname (default: argocd.company.com)"
    Write-Host "  GRAFANA_HOST       Grafana hostname (default: grafana.company.com)"
    Write-Host "  REGISTRY           Docker registry for images"
    Write-Host ""
    exit 0
}
elseif ($Verify) {
    Test-Deployment
    Show-AccessInfo
    exit 0
}
elseif ($Cleanup) {
    Remove-AllResources
    exit 0
}
else {
    Start-Deployment
} 