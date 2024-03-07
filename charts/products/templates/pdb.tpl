{{- $root := . }}
{{- $values := $root.Values }}
{{- $deploymentsData := $values.deployments }}
{{- range $deploymentsData }}
{{ $currentDeployment := . }}
{{ if $currentDeployment.pdb }}
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: {{ printf "%s-%s" $currentDeployment.name "pdb" }}
  namespace: {{ $values.namespace.name }}
spec:
  minAvailable: {{ $currentDeployment.pdb.minAvailable }}
  selector:
    matchLabels:
      {{- if $currentDeployment.podLabels }}
      {{- toYaml $currentDeployment.podLabels | nindent 6 }}
      {{- end }}
{{ end -}}
---
{{ end }}
