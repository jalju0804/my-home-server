.PHONY: deploy-argocd
deploy-argocd: ## Deploy Argo CD on Kubernetes cluster
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	helm install --create-namespace --namespace argocd argocd argo/argo-cd
	kubectl -n argocd wait --for=condition=available --timeout=300s --all deployments
	kustomize build ./manifests/applications | kubectl apply -f -
        # enable Argo CD metrics Service and ServiceMonitor
	helm upgrade -f ./manifests/argocd/values.yaml --namespace argocd argocd argo/argo-cd
	kubectl -n argocd wait --for=condition=available --timeout=300s --all deployments
.PHONY: argocd-password
argocd-password: ## Show admin password for ArgoCD
	@kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

.PHONY: grafana-password
grafana-password: ## Show admin password for Grafana
	@kubectl get secrets -n prometheus prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d
