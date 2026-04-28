{{/*
Fully qualified resource name: <release>-proxyrelayclient, truncated to 63 chars.
*/}}
{{- define "proxyrelayclient.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels (used by Deployment matchLabels and Service selector).
*/}}
{{- define "proxyrelayclient.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "proxyrelayclient.labels" -}}
{{ include "proxyrelayclient.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
