# Self-Service Developer Platform (IDP)

A comprehensive internal developer platform built with Backstage, Kubernetes, Helm, ArgoCD, React, and GitHub Actions for automated provisioning, standardized tooling, and developer experience optimization.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Backstage     │    │   Kubernetes    │    │   ArgoCD        │
│   Portal        │◄──►│   Cluster       │◄──►│   GitOps        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React         │    │   Helm Charts   │    │   GitHub        │
│   Plugins       │    │   & Templates   │    │   Actions       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

### Self-Service Capabilities
- **Service Catalog**: Browse and create new services
- **Template Scaffolding**: Pre-built templates for common service types
- **Resource Provisioning**: Automated Kubernetes resource creation
- **Environment Management**: Dev, staging, production environments

### Developer Experience
- **Unified Dashboard**: Single pane of glass for all developer needs
- **Documentation**: Integrated docs and runbooks
- **Monitoring**: Built-in observability and alerting
- **CI/CD Integration**: Automated pipelines with GitHub Actions

### GitOps & Automation
- **ArgoCD Integration**: Declarative deployments
- **Helm Charts**: Standardized application packaging
- **Automated Provisioning**: Infrastructure as Code
- **Policy Enforcement**: RBAC and security policies

## 📁 Project Structure

```
├── backstage/                 # Backstage application
│   ├── app-config.yaml       # Backstage configuration
│   ├── packages/             # Custom plugins and components
│   └── Dockerfile            # Container configuration
├── kubernetes/               # Kubernetes manifests
│   ├── namespaces/           # Namespace definitions
│   ├── rbac/                 # Role-based access control
│   └── crds/                 # Custom resource definitions
├── helm-charts/              # Helm charts for services
│   ├── backstage/            # Backstage deployment chart
│   ├── argocd/               # ArgoCD deployment chart
│   └── templates/            # Service templates
├── argocd/                   # ArgoCD configuration
│   ├── applications/         # Application definitions
│   └── projects/             # Project configurations
├── github-actions/           # CI/CD workflows
│   ├── workflows/            # GitHub Actions workflows
│   └── scripts/              # Automation scripts
├── react-components/         # Custom React components
│   ├── plugins/              # Backstage plugins
│   └── components/           # Reusable components
└── docs/                     # Documentation
    ├── setup/                # Setup guides
    ├── user-guide/           # User documentation
    └── architecture/         # Architecture docs
```

## 🛠️ Quick Start

### Prerequisites
- Kubernetes cluster (v1.24+)
- Helm (v3.8+)
- kubectl
- Docker
- Node.js (v18+)

### 1. Deploy Infrastructure
```bash
# Deploy ArgoCD
helm install argocd ./helm-charts/argocd

# Deploy Backstage
helm install backstage ./helm-charts/backstage
```

### 2. Configure Backstage
```bash
# Update app-config.yaml with your settings
kubectl apply -f kubernetes/namespaces/
kubectl apply -f kubernetes/rbac/
```

### 3. Set up CI/CD
```bash
# Configure GitHub Actions secrets
# Deploy ArgoCD applications
kubectl apply -f argocd/applications/
```

## 📚 Documentation

- [Setup Guide](docs/setup/README.md)
- [User Guide](docs/user-guide/README.md)
- [Architecture](docs/architecture/README.md)
- [API Reference](docs/api/README.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- [Issues](https://github.com/your-org/internal-developer-platform/issues)
- [Discussions](https://github.com/your-org/internal-developer-platform/discussions)
- [Documentation](docs/README.md) 