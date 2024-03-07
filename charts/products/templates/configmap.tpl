{{- $root := . -}}
{{- $namespace := .Values.namespace }}
{{- $configMaps := .Values.configMaps }}
{{- $configFiles := .Values.configFiles }}
{{- range $index, $configMap := $configMaps }}
{{- $configData := dict "root" $root "namespace" $namespace "config" $configMap }}

{{- include "app.configmap" $configData }}
---
{{- end }}
{{- range $index, $configFile := $configFiles }}
{{- $configData := dict "root" $root "namespace" $namespace "config" $configFile }}

{{- include "app.configFile" $configData }}
---
{{- end }}
