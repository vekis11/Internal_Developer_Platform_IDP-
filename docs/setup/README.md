# Internal Developer Platform Setup Guide

This guide will walk you through setting up the complete Internal Developer Platform (IDP) with Backstage, Kubernetes, ArgoCD, and all supporting tools.

## Prerequisites

### System Requirements
- **Kubernetes Cluster**: v1.24+ (EKS, GKE, AKS, or on-premises)
- **Helm**: v3.8+
- **kubectl**: Latest version
- **Docker**: v20.10+
- **Node.js**: v18+
- **Git**: Latest version

### Infrastructure Requirements
- **Load Balancer**: For ingress traffic
- **Storage**: Persistent volumes for databases
- **DNS**: Domain configuration for services
- **SSL Certificates**: Let's Encrypt or custom certificates

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/internal-developer-platform.git
cd internal-developer-platform
```

### 2. Configure Environment Variables
Create a `.env` file in the root directory:
```bash
# Backstage Configuration
AUTH_SECRET=your-auth-secret-here
GITHUB_TOKEN=your-github-token
GITLAB_TOKEN=your-gitlab-token
AZURE_TOKEN=your-azure-token

# Database Configuration
POSTGRESQL_PASSWORD=your-postgresql-password
REDIS_PASSWORD=your-redis-password

# Kubernetes Configuration
K8S_SERVICE_ACCOUNT_TOKEN=your-k8s-token
K8S_STAGING_TOKEN=your-staging-token
K8S_PROD_TOKEN=your-prod-token

# ArgoCD Configuration
ARGOCD_BASE_URL=https://argocd.company.com
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=your-argocd-password

# External Services
JENKINS_BASE_URL=https://jenkins.company.com
SONARQUBE_BASE_URL=https://sonarqube.company.com
PROMETHEUS_BASE_URL=https://prometheus.company.com
GRAFANA_BASE_URL=https://grafana.company.com
```

### 3. Deploy Infrastructure

#### Deploy Kubernetes Resources
```bash
# Create namespaces
kubectl apply -f kubernetes/namespaces/

# Deploy RBAC
kubectl apply -f kubernetes/rbac/

# Create secrets (you'll need to populate these)
kubectl create secret generic backstage-secrets \
  --from-literal=auth-secret=$AUTH_SECRET \
  --from-literal=github-token=$GITHUB_TOKEN \
  --from-literal=postgresql-password=$POSTGRESQL_PASSWORD \
  --from-literal=redis-password=$REDIS_PASSWORD \
  -n backstage
```

#### Deploy ArgoCD
```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Deploy ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.ingress.enabled=true \
  --set server.ingress.hosts[0]=argocd.company.com \
  --set server.ingress.tls[0].secretName=argocd-tls \
  --set server.ingress.tls[0].hosts[0]=argocd.company.com
```

#### Deploy Backstage
```bash
# Deploy Backstage using Helm
helm install backstage ./helm-charts/backstage \
  --namespace backstage \
  --create-namespace \
  --set postgresql.auth.password=$POSTGRESQL_PASSWORD \
  --set redis.auth.password=$REDIS_PASSWORD \
  --set image.tag=latest
```

### 4. Configure ArgoCD Applications
```bash
# Deploy ArgoCD projects
kubectl apply -f argocd/projects/

# Deploy ArgoCD applications
kubectl apply -f argocd/applications/
```

### 5. Access the Platform

#### Backstage Portal
- **URL**: https://backstage.company.com
- **Default Credentials**: guest/guest

#### ArgoCD Dashboard
- **URL**: https://argocd.company.com
- **Default Username**: admin
- **Default Password**: Get from secret or set during installation

## Detailed Setup

### Backstage Configuration

#### Customize app-config.yaml
Update the Backstage configuration in `backstage/app-config.yaml`:

1. **Organization Settings**
   ```yaml
   organization:
     name: Your Organization
   ```

2. **Authentication Providers**
   ```yaml
   auth:
     providers:
       github:
         development:
           clientId: ${AUTH_GITHUB_CLIENT_ID}
           clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
   ```

3. **Integrations**
   ```yaml
   integrations:
     github:
       - host: github.com
         token: ${GITHUB_TOKEN}
   ```

#### Build and Deploy Backstage
```bash
# Build the Backstage application
cd backstage
yarn install
yarn build

# Build Docker image
docker build -t internal-developer-platform:latest .

# Push to registry
docker push your-registry/internal-developer-platform:latest
```

### Kubernetes Configuration

#### Cluster Setup
Ensure your Kubernetes cluster has:
- **Ingress Controller**: NGINX or similar
- **Certificate Manager**: cert-manager for SSL
- **Storage Class**: For persistent volumes
- **Load Balancer**: For external access

#### Namespace Structure
```
backstage/          # Backstage application
argocd/            # ArgoCD deployment
monitoring/        # Prometheus, Grafana, etc.
development/       # Development environment
staging/           # Staging environment
production/        # Production environment
```

### ArgoCD Configuration

#### Project Setup
ArgoCD projects define:
- **Source Repositories**: Allowed Git repositories
- **Destinations**: Target namespaces and clusters
- **Resource Whitelist**: Allowed Kubernetes resources
- **Roles**: User permissions and policies

#### Application Management
Applications are defined in `argocd/applications/`:
- **Backstage**: Main platform application
- **Monitoring Stack**: Prometheus, Grafana, etc.
- **Service Templates**: Reusable service charts

### Service Templates

#### Available Templates
1. **Node.js Service**: Full-stack Node.js application
2. **Python Service**: FastAPI/Python microservice
3. **Java Service**: Spring Boot application
4. **React Frontend**: Single-page application
5. **Database Service**: PostgreSQL/Redis services

#### Using Templates
```bash
# Create a new service using template
helm create my-service --starter ./helm-charts/templates/nodejs-service

# Customize the service
cd my-service
# Edit values.yaml and other files

# Deploy the service
helm install my-service . --namespace development
```

## Security Configuration

### RBAC Setup
The platform includes comprehensive RBAC:
- **Platform Team**: Full access to all resources
- **Developers**: Access to development and staging
- **Viewers**: Read-only access to production

### Network Policies
```yaml
# Example network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Secrets Management
- **Kubernetes Secrets**: For sensitive data
- **External Secret Manager**: For production environments
- **Vault Integration**: For advanced secret management

## Monitoring and Observability

### Prometheus Configuration
```yaml
# Prometheus configuration
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'backstage'
    static_configs:
      - targets: ['backstage:3000']
```

### Grafana Dashboards
Pre-configured dashboards for:
- **Platform Overview**: System health and metrics
- **Service Performance**: Application metrics
- **Infrastructure**: Cluster and node metrics
- **Security**: Security events and alerts

### Alerting
Configure alerts for:
- **High CPU/Memory Usage**
- **Failed Deployments**
- **Security Vulnerabilities**
- **Service Downtime**

## Troubleshooting

### Common Issues

#### Backstage Not Starting
```bash
# Check logs
kubectl logs -f deployment/backstage -n backstage

# Check configuration
kubectl get configmap backstage-config -n backstage -o yaml
```

#### ArgoCD Sync Issues
```bash
# Check application status
argocd app list

# Check sync status
argocd app sync backstage

# View application details
argocd app get backstage
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
kubectl get pods -n backstage -l app=postgresql

# Check connection
kubectl exec -it deployment/backstage -n backstage -- psql $DATABASE_URL
```

### Performance Optimization

#### Resource Limits
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

#### Horizontal Pod Autoscaling
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## Next Steps

1. **Customize Templates**: Adapt service templates for your needs
2. **Add Integrations**: Connect additional tools and services
3. **Configure CI/CD**: Set up automated deployment pipelines
4. **Train Team**: Provide training on platform usage
5. **Monitor Usage**: Track platform adoption and metrics

## Support

- **Documentation**: [docs/README.md](../README.md)
- **Issues**: [GitHub Issues](https://github.com/your-org/internal-developer-platform/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/internal-developer-platform/discussions)
- **Slack**: #platform-support 