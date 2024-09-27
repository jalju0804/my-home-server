# my-home-server
## prometheus-operator
```
helm template --include-crds \           
  --namespace prometheus \
  prometheus prometheus-community/kube-prometheus-stack > prometheus-manifest.yaml
```