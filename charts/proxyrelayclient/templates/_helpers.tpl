{{/*
Copyright 2026 Cisco Systems, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "proxyrelayclient.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "proxyrelayclient.fullname" -}}
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
*/}}
{{- define "proxyrelayclient.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "proxyrelayclient.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "proxyrelayclient.labels" -}}
helm.sh/chart: {{ include "proxyrelayclient.chart" . }}
{{ include "proxyrelayclient.selectorLabels" . }}
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
{{- define "proxyrelayclient.selectorLabels" -}}
app.kubernetes.io/name: {{ include "proxyrelayclient.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "proxyrelayclient.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Return the proper image name with registry and tag
*/}}
{{- define "proxyrelayclient.lib.image" -}}
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
Return the proper proxyrelayclient image name
*/}}
{{- define "proxyrelayclient.image" -}}
{{- include "proxyrelayclient.lib.image" (dict "image" .Values.image "global" .Values.global) -}}
{{- end }}

{{/*
Return the proper image pull policy
*/}}
{{- define "proxyrelayclient.imagePullPolicy" -}}
{{- .Values.image.pullPolicy | default "Always" -}}
{{- end }}

{{/*
Render a value that contains template perhaps
*/}}
{{- define "proxyrelayclient.tplvalues.render" -}}
  {{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
  {{- if contains "{{" (toString $value) }}
    {{- tpl $value .context }}
  {{- else }}
    {{- $value }}
  {{- end }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "proxyrelayclient.lib.images.renderPullSecrets" -}}
  {{- $pullSecrets := list }}
  {{- $context := .context }}

  {{- range (($context.Values.global).imagePullSecrets) -}}
    {{- if kindIs "map" . -}}
      {{- $pullSecrets = append $pullSecrets (include "proxyrelayclient.tplvalues.render" (dict "value" .name "context" $context)) -}}
    {{- else -}}
      {{- $pullSecrets = append $pullSecrets (include "proxyrelayclient.tplvalues.render" (dict "value" . "context" $context)) -}}
    {{- end -}}
  {{- end -}}

  {{- range .images -}}
    {{- range .pullSecrets -}}
      {{- if kindIs "map" . -}}
        {{- $pullSecrets = append $pullSecrets (include "proxyrelayclient.tplvalues.render" (dict "value" .name "context" $context)) -}}
      {{- else -}}
        {{- $pullSecrets = append $pullSecrets (include "proxyrelayclient.tplvalues.render" (dict "value" . "context" $context)) -}}
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
{{- define "proxyrelayclient.imagePullSecrets" -}}
{{ include "proxyrelayclient.lib.images.renderPullSecrets" (dict "images" (list .Values.image) "context" .) }}
{{- end -}}

{{/*
Detect if the target platform is OpenShift
*/}}
{{- define "proxyrelayclient.isOpenshift" -}}
{{- if or (eq (lower (default "" .Values.targetPlatform)) "openshift") (.Capabilities.APIVersions.Has "route.openshift.io/v1") -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/*
Render podSecurityContext, omitting runAsUser, runAsGroup, fsGroup, and seLinuxOptions if OpenShift
*/}}
{{- define "proxyrelayclient.renderPodSecurityContext" -}}
{{- $isOpenshift := include "proxyrelayclient.isOpenshift" . | trim }}
{{- if eq $isOpenshift "true" }}
{{- omit .Values.podSecurityContext "runAsUser" "runAsGroup" "fsGroup" "seLinuxOptions" | toYaml }}
{{- else }}
{{- toYaml .Values.podSecurityContext }}
{{- end }}
{{- end }}

{{/*
Render containerSecurityContext, omitting runAsUser, runAsGroup, and seLinuxOptions if OpenShift
*/}}
{{- define "proxyrelayclient.renderContainerSecurityContext" -}}
{{- $isOpenshift := include "proxyrelayclient.isOpenshift" . | trim }}
{{- if eq $isOpenshift "true" }}
{{- omit .Values.containerSecurityContext "runAsUser" "runAsGroup" "seLinuxOptions" | toYaml }}
{{- else }}
{{- toYaml .Values.containerSecurityContext }}
{{- end }}
{{- end }}
