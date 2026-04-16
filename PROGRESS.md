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

### Next Steps
- [ ] Create root Application (apps-of-apps pattern)
- [ ] Deploy a sample app through ArgoCD
