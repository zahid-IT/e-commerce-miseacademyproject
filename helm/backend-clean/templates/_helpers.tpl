{{- define "backend-clean.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "backend-clean.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "backend-clean.labels" -}}
app.kubernetes.io/name: {{ include "backend-clean.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: Helm
{{- end }}

{{- define "backend-clean.serviceAccountName" -}}
{{ include "backend-clean.fullname" . }}
{{- end }}
