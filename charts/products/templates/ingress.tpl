{{- $root := . }}
{{- $releaseName := $root.Release.Name }}
{{- $values := $root.Values }}

apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: {{ $values.namespace.name }}
  namespace: {{ $values.namespace.name }}
spec:
  weighted:
    services:
      {{- $deploymentsData := $values.deployments }}
      {{- range $deploymentsData }}
      {{ $currentDeployment := . }}
      - name: {{ $currentDeployment.name }}
        port: 80
        scheme: h2c
        weight: {{ $currentDeployment.trafficWeightPercentage }}
      {{- end }}
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ $values.namespace.name }}
  namespace: {{ $values.namespace.name }}
spec:
  entryPoints:
    - web
  routes:
    - kind: Rule
      match: PathPrefix(`/`)
      services:
      {{- range $deploymentsData }}
      {{ $currentDeployment := . }}
        - kind: Service
          name: {{ $currentDeployment.name }}
          namespace: {{ $values.namespace.name }}
          port: 81
          weight: {{ $currentDeployment.trafficWeightPercentage }}
      {{- end }}
---
apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: {{ .Values.namespace.name }}-base-traefik-service
  namespace: {{ .Values.namespace.name }}
spec:
  weighted:
    services:
    {{- range $deploymentsData }}
    {{ $currentDeployment := . }}
      - name: {{ $currentDeployment.name }}
        port: 80
        weight: {{ $currentDeployment.trafficWeightPercentage }}
    {{- end }}
---
apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: {{ .Values.namespace.name }}-mirror-traefik-service
  namespace: {{ .Values.namespace.name }}
spec:
  weighted:
    services:
      - name: {{ .Values.namespace.name }}-mirror
        port : 80
---
apiVersion: traefik.io/v1alpha1
kind: TraefikService
metadata:
  name: {{ .Values.namespace.name }}-traefik-service
  namespace: {{ .Values.namespace.name }}
spec:
  mirroring:
    name: {{ .Values.namespace.name }}-base-traefik-service
    kind: TraefikService
    mirrors:
      - name: {{ .Values.namespace.name }}-mirror-traefik-service
        kind: TraefikService
        percent: {{ .Values.mirror_percent }}
