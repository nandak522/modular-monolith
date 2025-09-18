{{- $root := . }}
{{- $releaseName := $root.Release.Name }}
{{- $values := $root.Values }}
{{- $deploymentsData := $values.deployments }}
{{- range $values.deployments }}
{{ $currentDeployment := . }}
kind: Deployment
apiVersion: apps/v1
metadata:
  name: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentDeployment.name) }}
  namespace: {{ $values.namespace.name }}
spec:
  {{- if .replicas}}
  replicas: {{ .replicas }}
  {{- end }}
  strategy:
    rollingUpdate:
      {{- toYaml $currentDeployment.rollingUpdate | nindent 6 }}
    type: RollingUpdate
  selector:
    matchLabels:
      app: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentDeployment.name) }}
      {{- if $currentDeployment.podLabels }}
      {{- toYaml $currentDeployment.podLabels | nindent 6 }}
      {{- end }}
  template:
    metadata:
      labels:
        app: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentDeployment.name) }}
        {{- if $currentDeployment.podLabels }}
        {{- toYaml $currentDeployment.podLabels | nindent 8 }}
        {{- end }}
      annotations:
        {{- if $currentDeployment.podAnnotations }}
        {{- toYaml $currentDeployment.podAnnotations | nindent 8 -}}
        {{- end }}
        {{- include "app.checksumAnnotations" $root | nindent 8 }}
    spec:
      {{- if $currentDeployment.imagePullSecret }}
      imagePullSecrets:
        - name: {{ $currentDeployment.imagePullSecret }}
      {{- end }}
      containers:
      {{- range $currentDeployment.containers }}
        - name: {{ .name }}
          {{- if .livenessProbe }}
          {{- $probe := dict "probe" .livenessProbe "type" "livenessProbe" }}
          {{- include "app.probe" $probe | nindent 10 }}
          {{- end }}
          env:
            {{- if .env }}
            {{- toYaml .env | nindent 12 }}
            {{- end }}
            - name: K8S_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: K8S_HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: K8S_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: K8S_POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: K8S_POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          imagePullPolicy: {{ default "IfNotPresent" .imagePullPolicy }}
          {{- if .readinessProbe }}
          {{- $probe := dict "probe" .readinessProbe "type" "readinessProbe" }}
          {{- include "app.probe" $probe | nindent 10 }}
          {{- end }}
          image: {{ .imageName }}:{{- .imageTag }}
          ports:
            {{- if hasKey . "ports" }}
            {{- range .ports }}
            - protocol: TCP
              name: {{ .name }}
              containerPort: {{ .value }}
            {{- end }}
            {{- else if .containerPort }}
            - protocol: TCP
              name: {{ .containerPortName }}
              containerPort: {{ .containerPort }}
            {{- end }}
          resources:
          {{- toYaml .resources | nindent 12 }}
          {{- if or (.configFileName) (.secretsFileName) }}
          volumeMounts:
            {{- if .configFileName -}}
            {{- $requiredConfigFileInfo := dict "configFiles" $values.configFiles "configFileName" .configFileName "releaseName" $releaseName }}
            {{- include "app.containerVolumeMounts" $requiredConfigFileInfo | trim | nindent 12 }}
            {{- end }}
            {{- if .secretsFileName -}}
            {{- $requiredSecretsFileInfo := dict "secretsFiles" $values.secretsFiles "secretsFileName" .secretsFileName "releaseName" $releaseName }}
            {{- include "app.containerVolumeMounts" $requiredSecretsFileInfo | trim | nindent 12 }}
            {{- end }}
          {{- end -}}
      {{- end -}}
      {{- include "app.nodeLabels" $values.nodeLabels | trim | nindent 6 }}
      {{ $podConfigMapVolumesData := dict "configFiles" $values.configFiles "type" "configFiles" -}}
      {{ $podSecretVolumesData := dict "secretsFiles" $values.secretsFiles "type" "secretsFiles" -}}
      {{- if or ($podConfigMapVolumesData.configFiles) ($podSecretVolumesData.secretsFiles) -}}
      volumes:
        {{- if $podConfigMapVolumesData.configFiles }}
        {{- range $currentDeployment.containers }}
        {{- if .configFileName }}
        {{- $requiredPodVolumeInfo := dict "podVolumes" $podConfigMapVolumesData "configFileName" .configFileName "releaseName" $releaseName }}
        {{- include "app.podVolumes" $requiredPodVolumeInfo | trim | nindent 8 }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- if $podSecretVolumesData.secretsFiles }}
        {{- range $currentDeployment.containers }}
        {{- if .secretsFileName }}
        {{- $requiredPodVolumeInfo := dict "podVolumes" $podSecretVolumesData "secretsFileName" .secretsFileName "releaseName" $releaseName }}
        {{- include "app.podVolumes" $requiredPodVolumeInfo | trim | nindent 8 }}
        {{- end }}
        {{- end }}
        {{- end }}
      {{- end }}
      {{ if $currentDeployment.terminationGracePeriodSeconds -}}
      terminationGracePeriodSeconds: {{ $currentDeployment.terminationGracePeriodSeconds }}
      {{ end }}
---
{{ end }}
