apiVersion: v1
kind: Namespace
metadata:
  labels:
    app.kubernetes.io/name: {{ .Values.namespace.name }}
    name: {{ .Values.namespace.name }}
  name: {{ .Values.namespace.name }}
