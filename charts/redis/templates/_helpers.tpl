{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "redis.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the namespace to use for resources.
Defaults to .Release.Namespace but can be overridden via .Values.namespaceOverride.
Useful for multi-namespace deployments in combined charts.
*/}}
{{- define "redis.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "redis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "redis.labels" -}}
helm.sh/chart: {{ include "redis.chart" . }}
{{ include "redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "redis.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Return the proper image name with registry and tag (tag includes digest if present)
*/}}
{{- define "redis.lib.image" -}}
{{- $registryName := .image.registry -}}
{{- $repositoryName := .image.repository -}}
{{- $tag := .image.tag | toString -}}
{{- if .global }}
    {{- if .global.imageRegistry }}
        {{- $registryName = .global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end }}

{{/*
Return the proper Redis image name
*/}}
{{- define "redis.image" -}}
{{- include "redis.lib.image" (dict "image" .Values.image "global" .Values.global) -}}
{{- end }}

{{/*
Return the proper image pull policy
*/}}
{{- define "redis.lib.imagePullPolicy" -}}
{{- .image.imagePullPolicy | default .image.pullPolicy | default "Always" -}}
{{- end }}

{{/*
Return the proper image pull policy
*/}}
{{- define "redis.imagePullPolicy" -}}
{{- include "redis.lib.imagePullPolicy" (dict "image" .Values.image) -}}
{{- end }}

{{/*
Render a value that contains template perhaps
*/}}
{{- define "redis.tplvalues.render" -}}
  {{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
  {{- if contains "{{" (toString $value) }}
    {{- tpl $value .context }}
  {{- else }}
    {{- $value }}
  {{- end }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names evaluating values as templates
{{ include "redis.lib.images.renderPullSecrets" ( dict "images" (list .Values.path.to.the.image1, .Values.path.to.the.image2) "context" $) }}
*/}}
{{- define "redis.lib.images.renderPullSecrets" -}}
  {{- $pullSecrets := list }}
  {{- $context := .context }}

  {{- range (($context.Values.global).imagePullSecrets) -}}
    {{- if kindIs "map" . -}}
      {{- $pullSecrets = append $pullSecrets (include "redis.tplvalues.render" (dict "value" .name "context" $context)) -}}
    {{- else -}}
      {{- $pullSecrets = append $pullSecrets (include "redis.tplvalues.render" (dict "value" . "context" $context)) -}}
    {{- end -}}
  {{- end -}}

  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- if kindIs "map" . -}}
        {{- $pullSecrets = append $pullSecrets (include "redis.tplvalues.render" (dict "value" .name "context" $context)) -}}
      {{- else -}}
        {{- $pullSecrets = append $pullSecrets (include "redis.tplvalues.render" (dict "value" . "context" $context)) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) -}}
imagePullSecrets:
    {{- range $pullSecrets | uniq }}
  - name: {{ . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "redis.imagePullSecrets" -}}
{{ include "redis.lib.images.renderPullSecrets" (dict "images" (list .Values.image) "context" .) }}
{{- end -}}

{{/*
Detect if the target platform is OpenShift (via .Values.targetPlatform or API group).
Usage: {{ include "redis.isOpenshift" . }}
*/}}
{{- define "redis.isOpenshift" -}}
{{- if or (eq (lower (default "" .Values.targetPlatform)) "openshift") (.Capabilities.APIVersions.Has "route.openshift.io/v1") -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/*
Render podSecurityContext, omitting runAsUser, runAsGroup, fsGroup, and seLinuxOptions if OpenShift is detected.
Usage: {{ include "redis.renderPodSecurityContext" . }}
*/}}
{{- define "redis.renderPodSecurityContext" -}}
{{- $isOpenshift := include "redis.isOpenshift" . | trim }}
{{- if eq $isOpenshift "true" }}
{{- omit .Values.podSecurityContext "runAsUser" "runAsGroup" "fsGroup" "seLinuxOptions" | toYaml }}
{{- else }}
{{- toYaml .Values.podSecurityContext }}
{{- end }}
{{- end }}

{{/*
Render containerSecurityContext, omitting runAsUser, runAsGroup, and seLinuxOptions if OpenShift is detected.
Usage: {{ include "redis.renderContainerSecurityContext" . }}
*/}}
{{- define "redis.renderContainerSecurityContext" -}}
{{- $isOpenshift := include "redis.isOpenshift" . | trim }}
{{- if eq $isOpenshift "true" }}
{{- omit .Values.containerSecurityContext "runAsUser" "runAsGroup" "seLinuxOptions" | toYaml }}
{{- else }}
{{- toYaml .Values.containerSecurityContext }}
{{- end }}
{{- end }}

{{- define "redis.configFullName" -}}
{{- if and .Values.config.existingConfigmapKey .Values.config.existingConfigmap }}
{{- printf "%s/%s" .Values.config.mountPath .Values.config.existingConfigmapKey }}
{{- else }}
{{- printf "%s/redis.conf" .Values.config.mountPath }}
{{- end -}}
{{- end -}}
