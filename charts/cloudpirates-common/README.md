Forked from https://github.com/CloudPirates-io/helm-charts/tree/e23b8028eb0df6376c2da46041ab3b3dc116588c/charts/common

---

# Common Helm Chart

### Example config for OpenShift Clusters
The `_helpers.tpl` detects for `route.openshift.io/v1` to determine the target platform.
If the target platform is Openshift, following fields are beeing removed if you use `{{ include "common.renderContainerSecurityContext" . }}` or `{{ include "common.renderPodSecurityContext" . }}` in the Chart to render the SecurityContext.
```yaml
fsGroup:
runAsUser:
runAsGroup:
seLinuxOptions:
```

Example usage:
```yaml
apiVersion: apps/v1
kind: StatefulSet
spec:
  template:
    spec:
      securityContext: {{ include "common.renderPodSecurityContext" . | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext: {{ include "common.renderContainerSecurityContext" . | nindent 12 }}
```
