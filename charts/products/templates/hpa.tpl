{{- $root := . }}
{{- $values := $root.Values }}
{{- $deploymentsData := $values.deployments }}
{{ if $deploymentsData }}
{{- range $deploymentsData }}
{{ $currentDeployment := . }}
{{- if $currentDeployment.hpa -}}
{{- if $currentDeployment.hpa.native -}}
{{- $hpaConfig := dict "deploymentName" $currentDeployment.name "config" $currentDeployment.hpa.native "environment" $values.environment "releaseName" $root.Release.Name }}
{{- include "app.nativeHPA" $hpaConfig }}
{{ end }}
{{ end }}
---
{{ end }}
{{ end }}
