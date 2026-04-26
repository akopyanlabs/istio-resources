{{/*
Generate a full name for resources
*/}}
{{- define "istio-resources.fullname" -}}
{{- printf "%s-%s" .Chart.Name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}