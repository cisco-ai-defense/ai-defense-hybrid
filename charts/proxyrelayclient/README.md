# Proxy Relay Client Helm Chart

Deploys the proxy relay tunnel client that connects on-prem hybrid environments
to the Cisco AI Defense cloud gateway over a persistent gRPC tunnel.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.2.0+
- A running AI Defense cloud gateway with a proxy relay server endpoint
- An API key or OIDC token for authenticating the tunnel

## Installation

```bash
helm install proxyrelayclient ./charts/proxyrelayclient \
  --set config.serverAddr=relay.aidefense.example.com:443 \
  --set config.existingSecret=my-proxyrelay-credentials
```

Or with a values file:

```bash
helm install proxyrelayclient ./charts/proxyrelayclient -f my-values.yaml
```

## Values That Must Be Set at Deploy Time

The following values have no usable defaults and **must** be provided for the
client to connect and authenticate:

| Value | Description | Example |
|---|---|---|
| `config.serverAddr` | gRPC address of the cloud gateway proxy relay server | `relay.aidefense.example.com:443` |
| `config.existingSecret` | Name of a pre-created K8s Secret containing an `apikey` or `oidc-token` key | `my-proxyrelay-credentials` |

If you do not have a pre-created Secret, you can pass the API key inline
instead (the chart will create a managed Secret for you):

| Value | Description |
|---|---|
| `config.apiKey` | Raw API key string (ignored when `existingSecret` is set) |

### Authentication

The client supports two authentication methods. Exactly one must be provided:

1. **API key** — set the `apikey` key in the referenced Secret (or use
   `config.apiKey`). Sent as the `x-api-key` header on the tunnel connection.
2. **OIDC token** — set the `oidc-token` key in the referenced Secret. Sent as
   the `x-oidc-token` header. Used as a fallback when no API key is present.

Pre-creating the Secret is the recommended approach:

```bash
kubectl create secret generic my-proxyrelay-credentials \
  --from-literal=apikey=<your-api-key>
```

## Optional Values

These have sensible defaults but can be overridden as needed:

| Value | Description | Default |
|---|---|---|
| `image` | Full container image reference | *(see values.yaml)* |
| `imagePullPolicy` | Image pull policy | `Always` |
| `replicaCount` | Number of replicas | `1` |
| `config.connectorId` | Unique identifier for this connector | `""` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.healthzPort` | Port for the `/healthz` endpoint | `8080` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `nodeSelector` | Node selector for scheduling | `{}` |
| `tolerations` | Pod tolerations | `[]` |
| `affinity` | Pod affinity rules | `{}` |

## Health and Readiness Checks

The proxyrelayclient binary runs an HTTP server on a configurable port
(default `8080`, controlled by `service.healthzPort`) that exposes a single
endpoint:

```
GET /healthz  →  200 OK  {"status":"SERVING"}
```

Kubernetes uses this endpoint for both **liveness** and **readiness** probes:

### Liveness Probe

Tells Kubernetes whether the process is alive. If the probe fails
`failureThreshold` consecutive times, the kubelet kills and restarts the
container.

| Setting | Default | Meaning |
|---|---|---|
| `livenessProbe.enabled` | `true` | Enable the probe |
| `livenessProbe.initialDelaySeconds` | `10` | Wait 10 s after container start before first check |
| `livenessProbe.periodSeconds` | `10` | Check every 10 s |
| `livenessProbe.timeoutSeconds` | `5` | Fail if no response within 5 s |
| `livenessProbe.failureThreshold` | `6` | Restart after 6 consecutive failures (≈60 s) |

### Readiness Probe

Tells Kubernetes whether the pod should receive traffic via the Service. A pod
that fails readiness is removed from Service endpoints until it passes again.

| Setting | Default | Meaning |
|---|---|---|
| `readinessProbe.enabled` | `true` | Enable the probe |
| `readinessProbe.initialDelaySeconds` | `5` | Wait 5 s before first check |
| `readinessProbe.periodSeconds` | `10` | Check every 10 s |
| `readinessProbe.timeoutSeconds` | `5` | Fail if no response within 5 s |
| `readinessProbe.failureThreshold` | `6` | Remove from endpoints after 6 failures |

Both probes use the same mechanism:

```yaml
httpGet:
  path: /healthz
  port: healthz    # named port → service.healthzPort (default 8080)
```

To disable either probe, set `livenessProbe.enabled: false` or
`readinessProbe.enabled: false`.

### Debug Port

The container also exposes port `6060` for Go pprof profiling and channelz
diagnostics. This port is not exposed via the Service and is only accessible
from within the pod or via `kubectl port-forward`:

```bash
kubectl port-forward deploy/<release>-proxyrelayclient 6060:6060
# then: curl http://localhost:6060/debug/pprof/
```

## Upgrading

```bash
helm upgrade proxyrelayclient ./charts/proxyrelayclient -f my-values.yaml
```

## Uninstalling

```bash
helm delete proxyrelayclient
```
