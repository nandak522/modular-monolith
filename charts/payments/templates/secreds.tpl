{{/*
This file is intentionally named as secreDS.yaml to escape the gitignore rule.
This file is more like a template and doesn't contain any actual secrets.
*/}}

{{- $root := . }}
{{- $namespace := .Values.namespace }}
{{- $secretsMaps := .Values.secretsMaps }}
{{- $secretsFiles := .Values.secretsFiles }}
{{ range $index, $secret := $secretsMaps }}
{{- $secretData := dict "root" $root "namespace" $namespace "secret" $secret }}
{{- include "app.secretsMap" $secretData }}
---
{{- end }}
{{ range $index, $secret := $secretsFiles }}
{{- $secretData := dict "root" $root "namespace" $namespace "secret" $secret }}
{{- include "app.secretsFile" $secretData }}
---
{{- end }}
