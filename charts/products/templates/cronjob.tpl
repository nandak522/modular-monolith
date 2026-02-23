{{- $root := . }}
{{- $releaseName := $root.Release.Name }}
{{- $values := $root.Values }}
{{- range $values.crons }}
{{ $currentCron := . }}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "app.appendReleaseName" (dict "releaseName" $releaseName "resourceName" $currentCron.name) }}
  namespace: {{ $values.namespace.name }}
spec:
  schedule: "{{ $currentCron.timing }}"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: $currentCron.name
            image: busybox:1.28
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
---
{{ end }}
