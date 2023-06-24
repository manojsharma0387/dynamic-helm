{{/*
Expand the name of the chart.
*/}}
{{- define "selfhostedagents.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "selfhostedagents.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "selfhostedagents.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "selfhostedagents.labels" -}}
helm.sh/chart: {{ include "selfhostedagents.chart" . }}
{{ include "selfhostedagents.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "selfhostedagents.selectorLabels" -}}
app.kubernetes.io/name: {{ include "selfhostedagents.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "selfhostedagents.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "selfhostedagents.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the namespace to use
*/}}
{{- define "selfhostedagents.namespace" -}}
namespace: {{ .Values.env }}-{{ include "selfhostedagents.name" .}}
{{- end}}