{{- $servicePorts := list "0000" }}
{{- $root := . }}
{{- $releaseName := $root.Release.Name }}
{{- $values := $root.Values }}
{{- $deploymentsData := $values.deployments }}
{{ if $deploymentsData }}
{{- range $deploymentsData }}
{{- $currentDeployment := . }}
{{- range $currentDeployment.containers }}
    {{- range .ports -}}
    {{ if .servicePort }}
        {{- $servicePorts = append $servicePorts .servicePort }}
    {{- end }}
    {{- end }}
{{- end }}
{{- if gt (len $servicePorts) 1 -}}
apiVersion: v1
kind: Service
metadata:
    name: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentDeployment.name) }}
    namespace: {{ $values.namespace.name }}
spec:
    type: NodePort
    ports:
      {{- $serviceInfo := dict "namespace" $values.namespace.name "currentDeployment" $currentDeployment -}}
      {{- include "app.servicePorts" $serviceInfo | nindent 6 }}
    selector:
      app: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentDeployment.name) }}
      {{- if $currentDeployment.podLabels }}
      {{- toYaml $currentDeployment.podLabels | nindent 6 }}
      {{- end }}

{{- end }}
---
{{- end }}
{{- end }}
