{{- $root := . }}
{{- $values := $root.Values }}
{{- $deploymentsData := $values.deployments }}
{{- range $values.deployments }}
{{ $currentDeployment := . }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ $currentDeployment.name }}
  namespace: {{ $values.namespace.name }}
spec:
  jobLabel: app
  namespaceSelector:
    matchNames:
    - {{ $values.namespace.name }}
  selector:
    matchLabels:
      app: {{ $currentDeployment.name }}
---
{{ end }}
