# Redis Helm Chart

An open source, in-memory data structure store used as a database, cache, and message broker.

This chart deploys a single Redis instance with ephemeral storage, suitable for caching and development environments.

## Quick Start

### Prerequisites

- Kubernetes 1.24+
- Helm 3.2.0+

### Installation

To install the chart with the release name `my-redis`:

```bash
helm install my-redis ./charts/redis
```

To install with custom values:

```bash
helm install my-redis ./charts/redis -f my-values.yaml
```

### Connecting to Redis

Connect to Redis from inside the cluster:

```bash
kubectl run redis-client --rm --tty -i --restart='Never' \
    --image redis:7.2 -- redis-cli -h my-redis
```

## Configuration

The following table lists the configurable parameters of the Redis chart and their default values.

### Global Parameters

| Parameter                            | Description                                                                             | Default       |
| ------------------------------------ | --------------------------------------------------------------------------------------- | ------------- |
| `global.imageRegistry`               | Global Docker image registry override                                                   | `""`          |
| `global.imagePullSecrets`            | Global Docker registry secret names                                                     | `["regcred"]` |
| `global.replicated.dockerconfigjson` | Replicated Docker config JSON filled during packaging and should not be overridden      | `""`          |

### Common Parameters

| Parameter              | Description                                     | Default         |
| ---------------------- | ----------------------------------------------- | --------------- |
| `nameOverride`         | String to partially override redis.fullname     | `""`            |
| `fullnameOverride`     | String to fully override redis.fullname         | `""`            |
| `namespaceOverride`    | String to override the namespace for all resources | `""`         |
| `clusterDomain`        | Kubernetes cluster domain                       | `cluster.local` |
| `commonLabels`         | Labels to add to all deployed objects           | `{}`            |
| `commonAnnotations`    | Annotations to add to all deployed objects      | `{}`            |
| `revisionHistoryLimit` | Number of revisions to keep in history          | `10`            |

### Image Configuration

| Parameter          | Description            | Default                                                                                       |
| ------------------ | ---------------------- | --------------------------------------------------------------------------------------------- |
| `image.registry`   | Redis image registry   | `proxyimages.aidefense.security.cisco.com/proxy/aidefensehybrid/artifactory.devhub-cloud.cisco.com` |
| `image.repository` | Redis image repository | `ai-defense-hybrid-docker/redis` |
| `image.tag`        | Redis image tag        | `v7.2.12-2026.02.03` |
| `image.pullPolicy` | Image pull policy      | `Always`                                                                                      |

### Pod Configuration

| Parameter        | Description                           | Default |
| ---------------- | ------------------------------------- | ------- |
| `podLabels`      | Map of labels to add to the pods      | `{}`    |
| `podAnnotations` | Map of annotations to add to the pods | `{}`    |
| `ipFamily`       | IP family to use (auto, ipv4, ipv6)   | `auto`  |

### Service Configuration

| Parameter                           | Description                                       | Default     |
| ----------------------------------- | ------------------------------------------------- | ----------- |
| `service.annotations`               | Kubernetes service annotations                    | `{}`        |
| `service.type`                      | Kubernetes service type                           | `ClusterIP` |
| `service.port`                      | Redis service port                                | `6379`      |
| `service.headless.annotations`      | Annotations for headless service                  | `{}`        |

### Redis Configuration

| Parameter                     | Description                          | Default                |
| ----------------------------- | ------------------------------------ | ---------------------- |
| `config.mountPath`            | Redis configuration mount path       | `/usr/local/etc/redis` |
| `config.content`              | Custom Redis configuration as string | `bind * -::*`          |
| `config.existingConfigmap`    | Name of existing ConfigMap to use    | `""`                   |
| `config.existingConfigmapKey` | Key in existing ConfigMap            | `""`                   |
| `extraConfig`                 | Additional configuration to append   | `""`                   |

### Resource Management

| Parameter                   | Description    | Default |
| --------------------------- | -------------- | ------- |
| `resources.limits.cpu`      | CPU limit      | `100m`  |
| `resources.limits.memory`   | Memory limit   | `128Mi` |
| `resources.requests.cpu`    | CPU request    | `50m`   |
| `resources.requests.memory` | Memory request | `128Mi` |

### Pod Assignment

| Parameter                        | Description                                       | Default |
| -------------------------------- | ------------------------------------------------- | ------- |
| `nodeSelector`                   | Node selector for pod assignment                  | `{}`    |
| `priorityClassName`              | Priority class for pod eviction                   | `""`    |
| `tolerations`                    | Tolerations for pod assignment                    | `[]`    |
| `affinity`                       | Affinity rules for pod assignment                 | `{}`    |
| `terminationGracePeriodSeconds`  | Seconds to wait for pod to terminate gracefully   | `30`    |
| `topologySpreadConstraints`      | Topology spread constraints for pod assignment    | `[]`    |

### Security Context

| Parameter                                           | Description                       | Default          |
| --------------------------------------------------- | --------------------------------- | ---------------- |
| `containerSecurityContext.runAsUser`                | User ID to run the container      | `999`            |
| `containerSecurityContext.runAsGroup`               | Group ID to run the container     | `999`            |
| `containerSecurityContext.runAsNonRoot`             | Run as non-root user              | `true`           |
| `containerSecurityContext.privileged`               | Set container's privileged mode   | `false`          |
| `containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation        | `false`          |
| `containerSecurityContext.readOnlyRootFilesystem`   | Read-only root filesystem         | `true`           |
| `containerSecurityContext.capabilities.drop`        | Linux capabilities to be dropped  | `["ALL"]`        |
| `containerSecurityContext.seccompProfile.type`      | Seccomp profile for the container | `RuntimeDefault` |
| `podSecurityContext.fsGroup`                        | Pod's Security Context fsGroup    | `999`            |

### Health Checks

#### Liveness Probe

| Parameter                           | Description                                     | Default |
| ----------------------------------- | ----------------------------------------------- | ------- |
| `livenessProbe.enabled`             | Enable liveness probe                           | `true`  |
| `livenessProbe.initialDelaySeconds` | Initial delay before starting probes            | `30`    |
| `livenessProbe.periodSeconds`       | How often to perform the probe                  | `10`    |
| `livenessProbe.timeoutSeconds`      | Timeout for each probe attempt                  | `5`     |
| `livenessProbe.failureThreshold`    | Number of failures before pod is restarted      | `6`     |
| `livenessProbe.successThreshold`    | Number of successes to mark probe as successful | `1`     |

#### Readiness Probe

| Parameter                            | Description                                     | Default |
| ------------------------------------ | ----------------------------------------------- | ------- |
| `readinessProbe.enabled`             | Enable readiness probe                          | `true`  |
| `readinessProbe.initialDelaySeconds` | Initial delay before starting probes            | `5`     |
| `readinessProbe.periodSeconds`       | How often to perform the probe                  | `10`    |
| `readinessProbe.timeoutSeconds`      | Timeout for each probe attempt                  | `5`     |
| `readinessProbe.failureThreshold`    | Number of failures before pod is marked unready | `6`     |
| `readinessProbe.successThreshold`    | Number of successes to mark probe as successful | `1`     |

#### Startup Probe

| Parameter                           | Description                                     | Default |
| ----------------------------------- | ----------------------------------------------- | ------- |
| `startupProbe.enabled`              | Enable startup probe                            | `false` |
| `startupProbe.initialDelaySeconds`  | Initial delay before starting probes            | `10`    |
| `startupProbe.periodSeconds`        | How often to perform the probe                  | `10`    |
| `startupProbe.timeoutSeconds`       | Timeout for each probe attempt                  | `5`     |
| `startupProbe.failureThreshold`     | Number of failures before pod is restarted      | `30`    |
| `startupProbe.successThreshold`     | Number of successes to mark probe as successful | `1`     |

### Additional Configuration

| Parameter           | Description                                                             | Default |
| ------------------- | ----------------------------------------------------------------------- | ------- |
| `extraEnvVars`      | Additional environment variables to set                                 | `[]`    |
| `extraFlags`        | Additional command-line flags to pass to redis-server                   | `[]`    |
| `extraPorts`        | Additional ports to be exposed by Services and StatefulSet              | `[]`    |
| `extraVolumes`      | Additional volumes to add to the pod                                    | `[]`    |
| `extraVolumeMounts` | Additional volume mounts for Redis container                            | `[]`    |
| `extraObjects`      | A list of additional Kubernetes objects to deploy alongside the release | `[]`    |

### Init Container Resources

| Parameter                                  | Description                          | Default |
| ------------------------------------------ | ------------------------------------ | ------- |
| `initContainer.resources.limits.cpu`       | CPU limit for init container         | `50m`   |
| `initContainer.resources.limits.memory`    | Memory limit for init container      | `128Mi` |
| `initContainer.resources.requests.cpu`     | CPU request for init container       | `25m`   |
| `initContainer.resources.requests.memory`  | Memory request for init container    | `64Mi`  |

### Custom Scripts and Hooks

| Parameter                          | Description                                                              | Default |
| ---------------------------------- | ------------------------------------------------------------------------ | ------- |
| `customScripts.postStart.enabled`  | Enable postStart lifecycle hook                                          | `false` |
| `customScripts.postStart.command`  | Command to execute in postStart hook                                     | `[]`    |
| `customScripts.preStop.enabled`    | Enable preStop lifecycle hook                                            | `false` |
| `customScripts.preStop.command`    | Command to execute in preStop hook                                       | `[]`    |

## Storage

This Redis chart uses **ephemeral storage** (emptyDir) by default. Data is stored in memory and does not persist across pod restarts. This makes it suitable for:

- **Caching** - Temporary data storage
- **Session storage** - Non-critical session data
- **Development/Testing** - Quick deployments without persistence overhead

**Important:** All data will be lost when the pod is deleted or restarted.

## Examples

### Basic Deployment

```bash
helm install my-redis ./charts/redis
```

### Custom Redis Configuration

```yaml
# values-custom-config.yaml
config:
  content: |
    bind * -::*
    maxmemory 256mb
    maxmemory-policy allkeys-lru

extraConfig: |
  # Additional custom configuration
  timeout 300
```

```bash
helm install my-redis ./charts/redis -f values-custom-config.yaml
```

### With Additional Environment Variables

```yaml
# values-env.yaml
extraEnvVars:
  - name: TZ
    value: "America/New_York"
  - name: REDIS_LOGLEVEL
    value: "debug"
```

### Extra Objects

You can use the `extraObjects` array to deploy additional Kubernetes resources (such as NetworkPolicies, ConfigMaps, etc.) alongside the release.

**Helm templating is supported in any field, but all template expressions must be quoted.**

```yaml
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: redis-extra-config
      namespace: "{{ .Release.Namespace }}"
    data:
      key: value
```

## Upgrading

To upgrade your Redis installation:

```bash
helm upgrade my-redis ./charts/redis
```

## Uninstalling

To uninstall/delete the Redis deployment:

```bash
helm delete my-redis
```

## Getting Support

For issues related to Redis:
- [Redis Documentation](https://redis.io/docs/latest/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
