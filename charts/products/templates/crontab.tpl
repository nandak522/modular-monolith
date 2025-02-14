{{- $root := . }}
{{- $releaseName := $root.Release.Name }}
{{- $values := $root.Values }}
{{- $cronsData := $values.crons }}
{{- range $cronsData }}
{{- $currentCron := . }}
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  name: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentCron.name) }}
  namespace: {{ $values.namespace.name }}
spec:
  cronSpec: {{ .timing | quote }}
---
{{ end }}
