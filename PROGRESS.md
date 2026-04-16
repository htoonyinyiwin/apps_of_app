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

### Next Steps
- [ ] `terraform init` + `plan` + `apply`
- [ ] Access ArgoCD UI (port-forward)
- [ ] Create root Application (apps-of-apps pattern)
- [ ] Deploy a sample app through ArgoCD
