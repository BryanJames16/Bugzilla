{{- define "bugzilla.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bugzilla.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "bugzilla.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "bugzilla.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "bugzilla.namespace" -}}
{{- if .Values.namespace.name -}}
{{- .Values.namespace.name -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "bugzilla.labels" -}}
helm.sh/chart: {{ include "bugzilla.chart" . }}
app.kubernetes.io/name: {{ include "bugzilla.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "bugzilla.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bugzilla.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: web
{{- end -}}

{{- define "bugzilla.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "bugzilla.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "bugzilla.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- printf "%s-secrets" (include "bugzilla.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "bugzilla.pvcName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-data" (include "bugzilla.fullname" .) -}}
{{- end -}}
{{- end -}}
