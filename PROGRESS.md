# Apps of App — Learning Progress

## Phase 1: Minimal AKS + ArgoCD

### Steps Completed

1. **Project scaffolding** (2026-04-16)
   - Created `.gitignore` — excludes tfstate, tfvars, .terraform/, keys
   - Created Terraform structure under `terraform/`

2. **Terraform: AKS cluster** (2026-04-16)
   - `providers.tf` — azurerm + helm providers
   - `variables.tf` — subscription_id (sensitive), location (germanywestcentral), Standard_B2s (cheap), 1 node
   - `aks.tf` — resource group + AKS cluster with SystemAssigned identity
   - `outputs.tf` — cluster name, RG, kubectl config command
   - `terraform.tfvars.example` — template for sensitive values

3. **Terraform: ArgoCD Helm** (2026-04-16)
   - `argocd.tf` — installs argo-cd chart into `argocd` namespace with chart defaults

4. **Terraform: Apply** (2026-04-16)
   - Ran `terraform init` + `plan` + `apply`
   - AKS cluster running with ArgoCD pods healthy
   - Auto-created namespaces: `default`, `kube-system`, `kube-node-lease`, `kube-public`, `gatekeeper-system` (Azure Policy/OPA — auto-installed by Azure)
   - `konnectivity-agent` present in `kube-system` (AKS control plane ↔ node communication — auto-installed)

5. **Connect to AKS cluster** (2026-04-16)
   - `az aks get-credentials --resource-group rg-proj-aks --name aks-proj-cluster`
   - Verify context: `kubectl config current-context` / `kubectl config get-contexts`

6. **ArgoCD UI Access** (2026-04-16)
   - Get admin password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
   - Port-forward: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
   - Access at `https://localhost:8080` (self-signed cert)
   - Initial admin secret didn't match — reset password manually via `argocd-secret` patch + server restart
   - Installed `argocd` CLI via brew (v3.3.6)

7. **Apps-of-apps pattern** (2026-04-16)
   - Created `root-app.yaml` — root Application watches `apps/` folder in repo
   - `kubectl apply -f root-app.yaml` — only manual apply needed, everything else is GitOps
   - Auto-sync enabled (`prune: true`, `selfHeal: true`)

8. **Sample app: nginx** (2026-04-16)
   - `apps/nginx.yaml` — child Application, picked up automatically by root app
   - `manifests/nginx/deployment.yaml` — nginx:1.27, 1 replica
   - `manifests/nginx/service.yaml` — ClusterIP on port 80
   - `CreateNamespace=true` — ArgoCD auto-creates `nginx` namespace
   - Verified: pod running in `nginx` namespace

9. **Testing the pattern: httpbin** (2026-04-16)
   - `apps/httpbin.yaml` — second child app, deployed automatically by root app
   - `manifests/httpbin/` — deployment (kennethreitz/httpbin) + service
   - ArgoCD didn't show it immediately — learned that ArgoCD **polls git every 3 minutes** by default
   - Forced sync via: `argocd app get root-app --refresh`
   - Can also click "Refresh" in the UI or set up GitHub webhooks for instant sync (Phase 2)

10. **Testing the pattern: httpbin-2** (2026-04-16)
    - `apps/httpbin-2.yaml` — third child app, another copy to confirm the pattern
    - `manifests/httpbin-2/` — deployment + service
    - Proves: just drop a YAML into `apps/`, push, and ArgoCD deploys it — **git push is the deployment tool**

### Phase 1 Complete

## Phase 2: Enterprise Hardening

### Steps Completed

11. **NGINX Ingress Controller** (2026-04-16)
    - `apps/ingress-nginx.yaml` — deployed via ArgoCD using official Helm chart (`ingress-nginx 4.12.1`)
    - AKS automatically provisions an Azure Load Balancer with public IP when it sees a `LoadBalancer` type Service
    - External IP: `20.212.122.86`
    - AKS also auto-creates a managed resource group (`MC_rg-proj-aks_...`) with VMs, VNet, NSG, LB, managed identities
    - Enterprise note: production teams pre-provision VNet, static IPs, DNS zones in Terraform; let AKS manage node-level resources

12. **Ingress rule + nip.io DNS** (2026-04-16)
    - `manifests/nginx/ingress.yaml` — routes `nginx.20.212.122.86.nip.io` → nginx Service
    - **nip.io** — free DNS service, embeds IP in hostname (e.g., `anything.1.2.3.4.nip.io` → `1.2.3.4`). Acts like a DNS provider (similar to GoDaddy) but automatic, no purchase needed. Good for dev/learning, not for production.
    - Ingress controller reads the `Host` header and routes to the correct Service — multiple apps can share one public IP with different hostnames
    - Verified: `http://nginx.20.212.122.86.nip.io` accessible from browser without port-forward

13. **TLS with cert-manager + Let's Encrypt** (2026-04-16)
    - `apps/cert-manager.yaml` — cert-manager Helm chart (v1.17.2) with CRDs enabled
    - `apps/cert-manager-config.yaml` — points to `manifests/cert-manager-config/`
    - `manifests/cert-manager-config/cluster-issuer.yaml` — ClusterIssuer using Let's Encrypt (ACME, HTTP-01 challenge)
    - Updated `manifests/nginx/ingress.yaml` — added `cert-manager.io/cluster-issuer` annotation + `tls` block with `secretName: nginx-tls`
    - How it works: cert-manager sees the annotation → requests cert from Let's Encrypt → Let's Encrypt verifies domain via HTTP-01 challenge (hits `/.well-known/acme-challenge/` on the public IP) → cert stored in K8s Secret → ingress controller serves HTTPS
    - Certs auto-renew every 60 days
    - Verified: `https://nginx.20.212.122.86.nip.io` shows valid HTTPS lock

### Folder structure learned
- `apps/` — ArgoCD Application manifests (`kind: Application`) — pointers that tell ArgoCD what/where to deploy
- `manifests/` — actual K8s resources (Deployments, Services, Ingresses, ClusterIssuers, etc.)
- Helm-based apps (ingress-nginx, cert-manager) don't need a `manifests/` folder — the chart is the source

14. **AKS RBAC + Azure AD** (2026-04-16)
    - Two layers: **Azure AD** = who you are (identity), **Azure RBAC** = what you can do (permissions)
    - Added `azuread` provider to `providers.tf`
    - Updated `aks.tf` — enabled `azure_active_directory_role_based_access_control` with `azure_rbac_enabled = true`
    - Created `rbac.tf` — role assignments separated from cluster config
    - Enterprise approach (commented out, needs AD admin): create `azuread_group` for aks-admins/aks-developers, attach RBAC roles to groups. Manage access by adding/removing people from groups.
    - Our approach (option 2): assigned current user directly as Cluster Admin via `azurerm_role_assignment`
    - Fixed Terraform drift — Azure auto-enabled `azure_policy_enabled`, `microsoft_defender`, and `upgrade_settings` that weren't in our Terraform. Added them to `aks.tf` to prevent `→ null` changes.
    - Applied: `terraform plan -var-file=dev.tfvars` → 1 to add, 1 to change, 0 to destroy
    - **Two AKS roles needed** when Azure RBAC mode is enabled:
      - `Azure Kubernetes Service Cluster Admin Role` — lets you get credentials (`az aks get-credentials`)
      - `Azure Kubernetes Service RBAC Cluster Admin` — lets you actually run kubectl commands
    - Installed `kubelogin` via brew — required for Azure AD auth with kubectl
    - `kubelogin convert-kubeconfig -l azurecli` — converts kubeconfig to use Azure CLI auth flow
    - Re-fetch credentials after enabling AD: `az aks get-credentials --resource-group rg-proj-aks --name aks-proj-cluster --overwrite-existing`

15. **Secrets management — Terraform infra** (2026-04-17)
    - **The problem:** apps need secrets but you can't put them in git (public repo)
    - **The solution:** Azure Key Vault + External Secrets Operator + Workload Identity
    - Flow: Key Vault (stores secrets) → Workload Identity (passwordless auth) → External Secrets Operator (pulls secrets) → K8s Secret (apps use as env vars/volumes)
    - Updated `aks.tf` — enabled `oidc_issuer_enabled` + `workload_identity_enabled`
    - Created `keyvault.tf`:
      - `azurerm_key_vault` — standard SKU, `rbac_authorization_enabled = true`
      - `azurerm_user_assigned_identity` — Managed Identity for External Secrets Operator (no password, uses federated auth)
      - `azurerm_federated_identity_credential` — links K8s service account `external-secrets:external-secrets` to the Managed Identity. AKS OIDC issuer certifies pod identity → Azure trusts it → pod can read Key Vault
      - `azurerm_key_vault_secret` — demo secret `proj-api-key` for testing
      - Role assignments: `Key Vault Secrets Officer` (you), `Key Vault Secrets User` (Managed Identity)
    - Added `keyvault_name` variable + output for `external_secrets_client_id`
    - Updated `providers.tf` — Helm provider switched from `kube_config` to `kube_admin_config` (old config broke after Azure AD RBAC was enabled). Old config commented out with explanation.
    - **Gotcha:** `enable_rbac_authorization` was deprecated and silently ignored — Key Vault created without RBAC. Fixed with `rbac_authorization_enabled = true` and `az keyvault update --enable-rbac-authorization true`.
    - **Gotcha:** RBAC Cluster Admin role was created manually with `az role assignment create`, then Terraform failed with conflict. Fixed with `terraform import` to bring existing resource into state.
    - Applied: Key Vault + Managed Identity + federated credential + demo secret all created
    - Outputs: `external_secrets_client_id = fa7e21d3-3370-4bde-b265-b66dd6362495`, `keyvault_name = kv-proj-aks-brian`

### Next Steps
- [ ] Secrets management — K8s side (External Secrets Operator + SecretStore + ExternalSecret)
- [ ] Multi-environment (dev/staging/prod)