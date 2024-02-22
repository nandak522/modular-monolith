{{/* vim: set filetype=mustache: */}}

{{- define "app.probe" -}}
{{- $probeInfo := . -}}
{{- $probeInfo.type }}:
  {{- if $probeInfo.probe.exec }}
  exec: {{ $probeInfo.probe.exec }}
  {{- end }}
  {{- if $probeInfo.probe.failureThreshold }}
  failureThreshold: {{ $probeInfo.probe.failureThreshold }}
  {{- end }}
  {{- if $probeInfo.probe.initialDelaySeconds }}
  initialDelaySeconds: {{ $probeInfo.probe.initialDelaySeconds }}
  {{- end }}
  {{- if $probeInfo.probe.periodSeconds }}
  periodSeconds: {{ $probeInfo.probe.periodSeconds }}
  {{- end }}
  {{- if $probeInfo.probe.successThreshold }}
  successThreshold: {{ $probeInfo.probe.successThreshold }}
  {{- end }}
  {{- if $probeInfo.probe.timeoutSeconds }}
  timeoutSeconds: {{ $probeInfo.probe.timeoutSeconds }}
  {{- end }}
  {{- if $probeInfo.probe.httpGet }}
  httpGet:
    path: {{ $probeInfo.probe.httpGet.path }}
    port: {{ $probeInfo.probe.httpGet.port }}
  {{- end }}
  {{- if $probeInfo.probe.tcpSocket }}
  tcpSocket:
    port: {{ $probeInfo.probe.tcpSocket.port }}
  {{- end }}
{{- end }}

{{/*
Renders nodeSelector block in the manifests
*/}}
{{- define "app.nodeLabels" }}
{{- if . }}
nodeSelector:
  {{ toYaml . }}
{{- end -}}
{{- end -}}

{{/*
Renders Pod's Annotations.
*/}}
{{- define "app.podAnnotations" -}}
{{- toYaml .podAnnotations -}}
{{- end }}

{{- define "app.nativeHPA"}}
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  labels:
    app: {{ .deploymentName }}
    env: {{ .environment }}
  name: {{ .deploymentName }}
  namespace: {{ .config.targetNamespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .config.targetDeployment }}
  minReplicas: {{ .config.minReplicas }}
  maxReplicas: {{ .config.maxReplicas }}
  metrics:
  {{- if hasKey .config "targetCPUAverage" }}
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .config.targetCPUAverage }}
  {{- end }}
  {{- if hasKey .config "targetMemoryAverage" }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ .config.targetMemoryAverage }}
  {{- end }}
{{- end }}

{{- define "app.hpaImageInfo" }}
{{- $imageName := "k8s-custom-hpa" -}}
{{- $imageTag := "v0.7.1" -}}
{{- $region := eq .environment "prod" | ternary "ap-south-1" "us-east-1" }}
{{- $registry := printf "274334742953.dkr.ecr.%s.amazonaws.com/bb-engg" $region }}
image: {{ $registry }}/{{ .imageName }}:{{- .imageTag }}
imagePullPolicy: IfNotPresent
{{- end }}

{{- define "app.deploymentName" -}}
{{- if and .deploymentName (default "" .tenant) }}
{{- printf "%s-%s" .deploymentName .tenant }}
{{- else}}
{{- .deploymentName }}
{{- end }}
{{- end }}

{{- define "app.servicePorts" -}}
{{- range .currentDeployment.containers -}}
{{- range .ports -}}
{{- if .servicePort }}
- port: {{ .servicePort }}
  protocol: TCP
  name: {{ .servicePortName }}
  targetPort: {{ .value }}
  {{ if .nodePort -}}
  nodePort: {{ .nodePort }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
