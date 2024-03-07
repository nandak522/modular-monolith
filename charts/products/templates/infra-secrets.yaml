{{- $root := . -}}
{{- if $root.Values.infraSettings -}}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: {{ .Values.requiredInfraDependencies.name }}
  namespace: {{ .Values.namespace.name }}
data:
  # Iterate on all required keys of .requiredInfraDependencies and
  # for each key, pull the value expression and
  # lookup that expression in .infraSettings values
  {{ range $settingKey, $settingValue := .Values.requiredInfraDependencies.values }}
  {{- $settingValue := trimPrefix "$" $settingValue }}
  {{- $actualSettingValue := pluck $settingValue $root.Values.infraSettings | first }}
  {{- $decodedActualSettingValue := $actualSettingValue | b64dec }}
  {{- if contains ".svc.cluster.local" $decodedActualSettingValue }}
  {{- $decodedActualSettingValue := $decodedActualSettingValue | replace ".svc.cluster.local" "" }}
  {{- $settingKey -}}: {{$decodedActualSettingValue | b64enc | quote}}
  {{- else }}
  {{- $settingKey -}}: {{$actualSettingValue | quote}}
  {{- end }}
  {{ end }}
---
{{- end }}
