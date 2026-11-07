{{/* Labels shared by every resource in the release. */}}
{{- define "url-shortener.labels" -}}
app.kubernetes.io/part-of: url-shortener
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/* Locked-down container settings: no root, no privilege escalation,
     no Linux capabilities, and a read-only root filesystem. */}}
{{- define "url-shortener.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{/* Pod-level settings: refuse to start as root, use the default seccomp profile. */}}
{{- define "url-shortener.podSecurityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/* Host the backend connects to: the in-cluster PostgreSQL or an external one. */}}
{{- define "url-shortener.dbHost" -}}
{{- if .Values.postgres.enabled -}}postgres{{- else -}}{{ required "postgres.externalHost is required when postgres.enabled is false" .Values.postgres.externalHost }}{{- end -}}
{{- end }}
