# Architecture Diagram

## 1. Overall Architecture

```mermaid
flowchart TB
    subgraph AZURE["☁️ Azure"]
        subgraph RG["Resource Group: rg-proj-aks"]
            AKS["AKS Cluster<br/>aks-proj-cluster<br/>Standard_B2s × 1 node<br/>southeastasia"]
            KV["Key Vault<br/>kv-proj-cluster-vault"]
            MI["Managed Identity<br/>id-proj-externalsecrets"]
            LB["Load Balancer<br/>20.212.122.86<br/>(auto-created by AKS)"]
        end
        AD["Azure AD<br/>RBAC + Workload Identity"]
    end

    subgraph GIT["📁 Git Repo (github.com/htoonyinyiwin/apps_of_app)"]
        APPS["apps/<br/>ArgoCD Application manifests"]
        MANIFESTS["manifests/<br/>K8s resources (Kustomize)"]
        TF["terraform/<br/>Infrastructure as Code"]
    end

    TF -->|terraform apply| RG
    AD -->|authenticates| AKS
    MI -->|federated credential<br/>passwordless| KV
    AKS --- LB
```

## 2. ArgoCD Apps-of-Apps Flow

```mermaid
flowchart TD
    ROOT["root-app.yaml<br/>(manually applied once)"]
    ROOT -->|watches apps/ folder| APPS_DIR["apps/"]

    subgraph INFRA_APPS["Infrastructure — Individual Applications"]
        ING["ingress-nginx<br/>Helm chart v4.12.1"]
        CM["cert-manager<br/>Helm chart v1.17.2"]
        CMC["cert-manager-config<br/>→ manifests/cert-manager-config/"]
        ESO["external-secrets<br/>Helm chart v0.14.4"]
        ESOC["external-secrets-config<br/>→ manifests/external-secrets-config/"]
    end

    subgraph WORKLOAD_APPS["Workloads — ApplicationSet"]
        APPSET["nginx-appset.yaml<br/>(list generator)"]
        APPSET --> ND["nginx-dev<br/>→ overlays/dev/<br/>1 replica"]
        APPSET --> NS["nginx-staging<br/>→ overlays/staging/<br/>2 replicas"]
        APPSET --> NP["nginx-prod<br/>→ overlays/prod/<br/>3 replicas"]
    end

    subgraph LEGACY["Legacy — Individual Applications (kept)"]
        HB["httpbin"]
        HB2["httpbin-2"]
    end

    subgraph COMMENTED["Commented Out (old approach)"]
        NX["nginx.yaml<br/>replaced by nginx-appset"]
    end

    APPS_DIR --> INFRA_APPS
    APPS_DIR --> WORKLOAD_APPS
    APPS_DIR --> LEGACY
```

## 3. Secrets Flow

```mermaid
flowchart LR
    YOU["You (Key Vault Secrets Officer)"]
    YOU -->|stores secret| KV["Azure Key Vault<br/>kv-proj-cluster-vault<br/>proj-api-key = super-secret-123"]

    KV -->|reads via<br/>Workload Identity| ESO["External Secrets Operator<br/>(pod in external-secrets ns)"]

    subgraph WI["Workload Identity Chain"]
        SA["K8s ServiceAccount<br/>external-secrets"]
        FED["Federated Credential<br/>(AKS OIDC issuer)"]
        MI["Managed Identity<br/>id-proj-externalsecrets<br/>Key Vault Secrets User role"]
        SA -->|linked via| FED -->|authenticates as| MI
    end

    ESO --> WI
    ESO -->|creates & refreshes every 1m| SECRET["K8s Secret<br/>proj-api-key<br/>(used by apps as env vars)"]
```

## 4. Traffic Flow

```mermaid
flowchart LR
    USER["Browser"] -->|HTTPS| NIP["nginx-dev.20.212.122.86.nip.io"]
    NIP -->|resolves to| LB["Azure Load Balancer<br/>20.212.122.86"]
    LB --> INGCTRL["NGINX Ingress Controller<br/>(reads Host header, routes)"]
    INGCTRL --> SVC["nginx Service<br/>(ClusterIP)"]
    SVC --> POD["nginx Pod"]

    CERT["cert-manager"] -->|auto-requests from<br/>Let's Encrypt| TLS["TLS Certificate<br/>(stored as K8s Secret)"]
    TLS -->|serves HTTPS| INGCTRL
```

## 5. Folder Structure

```
apps_of_app/
├── root-app.yaml                    # Bootstrap (apply once manually)
├── apps/                            # ArgoCD watches this folder
│   ├── nginx-appset.yaml            # ApplicationSet → 3 envs
│   ├── nginx.yaml                   # (commented out, old approach)
│   ├── httpbin.yaml                 # Individual app
│   ├── httpbin-2.yaml               # Individual app
│   ├── ingress-nginx.yaml           # Helm chart (infra)
│   ├── cert-manager.yaml            # Helm chart (infra)
│   ├── cert-manager-config.yaml     # → manifests/cert-manager-config/
│   ├── external-secrets.yaml        # Helm chart (infra)
│   └── external-secrets-config.yaml # → manifests/external-secrets-config/
├── manifests/
│   ├── nginx/
│   │   ├── base/                    # Shared: deployment + service
│   │   └── overlays/
│   │       ├── dev/                 # 1 replica, dev hostname
│   │       ├── staging/             # 2 replicas, staging hostname
│   │       └── prod/               # 3 replicas, prod hostname
│   ├── httpbin/                     # deployment + service
│   ├── httpbin-2/                   # deployment + service
│   ├── cert-manager-config/         # ClusterIssuer
│   └── external-secrets-config/     # SecretStore + ExternalSecret
└── terraform/                       # Azure infra (AKS, Key Vault, RBAC)
```
