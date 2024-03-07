{{/* vim: set filetype=mustache: */}}

{{/*
Renders nodeSelector block in the manifests
*/}}
{{- define "app.nodeLabels" }}
{{- if . }}
nodeSelector:
  {{ toYaml . }}
{{- end -}}
{{- end -}}

{{- define "app.nodeAffinity" }}
{{- $nodeAffinityLabels := . -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
          {{- range $index, $label := $nodeAffinityLabels }}
          - key: {{ $label.name }}
            operator: In
            values:
              - {{ $label.value }}
          {{- end }}
{{- end -}}

{{- define "app.requiredPodAntiAffinity" }}
{{- $podAntiAffinityLabels := . -}}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
        {{- range $index, $label := $podAntiAffinityLabels }}
        - key: {{ $label.name }}
          operator: In
          values:
            - {{ $label.value }}
        {{- end }}
    topologyKey: kubernetes.io/hostname
{{- end -}}

{{- define "app.preferredPodAntiAffinity" }}
{{- $podAntiAffinityLabels := . -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
          {{- range $index, $label := $podAntiAffinityLabels }}
          - key: {{ $label.name }}
            operator: In
            values:
              - {{ $label.value }}
          {{- end }}
      topologyKey: kubernetes.io/hostname
{{- end -}}

{{/*
Renders affinity block in the manifests
*/}}
{{- define "app.affinity" }}
affinity:
  {{- if .nodeAffinityLabels }}
  {{- include "app.nodeAffinity" .nodeAffinityLabels | nindent 2 }}
  {{- end }}
  {{- if .podAntiAffinity }}
  podAntiAffinity:
  {{- if eq .podAntiAffinity.type "required" }}
  {{- include "app.requiredPodAntiAffinity" .podAntiAffinity.labels | nindent 4 }}
  {{- end }}
  {{- if eq .podAntiAffinity.type "preferred" }}
  {{- include "app.preferredPodAntiAffinity" .podAntiAffinity.labels | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end -}}

{{- define "app.configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .config.name }}
  namespace: {{ .namespace.name }}
data:
{{- toYaml .config.data | nindent 2 }}
{{- end }}

{{- define "app.configFile" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .config.name }}
  namespace: {{ .namespace.name }}
data:
  {{- (.root.Files.Glob (printf "%s" .config.file)).AsConfig | nindent 2 }}
{{- end }}

{{/*
Renders secret based on the secrets.yaml
*/}}
{{- define "app.secretsMap" -}}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: {{ .secret.name }}
  namespace: {{ .namespace.name }}
data:
{{- toYaml .secret.data | nindent 2 }}
{{- end }}

{{/*
Renders secret based on the secrets.yaml
*/}}
{{- define "app.secretsFile" -}}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: {{ .secret.name }}
  namespace: {{ .namespace.name }}
data:
  {{- (.root.Files.Glob (printf "%s" .secret.file)).AsSecrets | nindent 2 }}
{{- end }}

{{/*
Renders VolumeMounts for the Container in a Pod
*/}}
{{- define "app.containerVolumeMounts" -}}
{{- if hasKey . "configFileName" -}}
{{- $configFileName := .configFileName }}
{{- range $index, $volumeMountData := .configFiles -}}
{{- if and ($volumeMountData.file) ($volumeMountData.mountPath) }}
{{ if eq $volumeMountData.name $configFileName }}
- mountPath: {{ $volumeMountData.mountPath }}
  subPath: {{ $volumeMountData.file }}
  name: {{ $volumeMountData.name }}
  readOnly: true
{{- end }}
{{- end }}
{{- end }}
{{- else if hasKey . "secretsFileName" -}}
{{- $secretsFileName := .secretsFileName }}
{{- range $index, $volumeMountData := .secretsFiles -}}
{{- if and ($volumeMountData.file) ($volumeMountData.mountPath) }}
{{ if eq $volumeMountData.name $secretsFileName }}
- mountPath: {{ $volumeMountData.mountPath }}
  subPath: {{ $volumeMountData.file }}
  name: {{ $volumeMountData.name }}
  readOnly: true
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Renders VolumeMounts for the Pod
*/}}
{{- define "app.podVolumes" -}}
{{- if hasKey . "configFileName" }}
{{$configFileName := .configFileName }}
{{- range .podVolumes.configFiles -}}
{{- if eq .name $configFileName }}
- configMap:
    name: {{ .name }}
  name: {{ .name }}
{{- end }}
{{- end }}
{{- end }}
{{- if hasKey . "secretsFileName" }}
{{$secretsFileName := .secretsFileName }}
{{- range .podVolumes.secretsFiles -}}
{{- if eq .name $secretsFileName }}
- secret:
    secretName: {{ .name }}
  name: {{ .name }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Renders Pod Annotations. Handy to roll the Pod as and when a configmap/secret changes.
*/}}
{{- define "app.podAnnotations" -}}
{{- $namespace := .Values.namespace -}}
annotations:
  checksum/infra-secrets: {{ include (print $.Template.BasePath "/infra-secrets.yaml") . | sha256sum }}
  checksum/configmap: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  checksum/secrets: {{ include (print $.Template.BasePath "/secreds.yaml") . | sha256sum }}
{{- end }}

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
