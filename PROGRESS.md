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

### Next Steps
- [ ] RBAC and Azure AD integration
- [ ] Secrets management (Azure Key Vault + External Secrets or Sealed Secrets)
- [ ] Multi-environment (dev/staging/prod)
- [ ] Ingress, TLS, DNS



RBAC + Azure AD — lock down who can access ArgoCD and the cluster

Secrets management — Azure Key Vault + External Secrets so you never put secrets in git

Multi-environment — separate dev/staging/prod with ArgoCD ApplicationSets

Ingress + TLS + DNS — expose ArgoCD and apps via a real domain instead of port-forward

are we using ingress controller? deprecated?