# KGateway Installation Guide for Cisco AI Defense Hybrid setup

## Overview

This document outlines the steps to install [Gateway API](https://gateway-api.sigs.k8s.io/) using the CNCF project [KGateway](https://kgateway.dev/) for accessing Cisco AI Defense services in Hybrid setup.

## What is Gateway API in Kubernetes?

Gateway API is a collection of Kubernetes resources that provide advanced traffic routing capabilities. It is an official Kubernetes project managed by the SIG-Network community and represents the next generation of Kubernetes Ingress, Load Balancing, and Service Mesh APIs.

Gateway API provides:

- **Role-oriented design** - Separates concerns between infrastructure providers, cluster operators, and application developers
- **Expressive and extensible** - Support for header-based routing, traffic weighting, and other advanced features
- **Protocol support** - Native support for HTTP, HTTPS, gRPC, TCP, and UDP protocols
- **Cross-namespace routing** - Route traffic across different namespaces with proper security controls

## Why Gateway API?

Gateway API offers several advantages over traditional Ingress:

- **Enhanced routing capabilities** - Advanced traffic management features like path-based routing, header matching, query parameter routing, and traffic splitting
- **Better security model** - Built-in support for cross-namespace references with ReferenceGrant for secure multi-tenancy
- **Standardization** - Vendor-neutral API that works consistently across different implementations
- **Future-proof** - Designed to evolve with modern cloud-native requirements
- **Native TLS management** - First-class support for certificate management and TLS termination
- **Improved observability** - Better status reporting and condition tracking for troubleshooting

## Prerequisites

- Kubernetes cluster with kubectl access
- Helm 3.x installed
- TLS certificate and key files for your domain (or cert-manager configured with appropriate issuer for automatic certificate management)

## Step 1: Install Gateway API CRDs

Install the standard Gateway API Custom Resource Definitions (CRDs) required for KGateway:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
```

## Step 2: Deploy KGateway CRDs

Install KGateway Custom Resource Definitions using Helm:

```bash
helm upgrade -i --create-namespace \
  --namespace kgateway-system \
  --version v2.1.2 kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
```

## Step 3: Install KGateway Control Plane

Deploy the KGateway control plane to the `kgateway-system` namespace:

```bash
helm upgrade -i -n kgateway-system kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
--version v2.1.2
```

## Step 4: Create TLS Secret

You need to create a TLS secret that will be referenced by the Gateway. Choose one of the following methods:

### Option A: Create TLS Secret from Certificate and Key Files

If you have existing certificate and key files, create a Kubernetes TLS secret:

```bash
kubectl create secret tls aid-gateway-tls \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key \
  -n ai-defense-onprem # The namespace where the services are running
```

Replace `/path/to/tls.crt` and `/path/to/tls.key` with the actual paths to your certificate and key files.

### Option B: Use cert-manager for Automatic Certificate Management

> The AI Defense Hybrid deployment already have cert-manager installed but to support gateway API, we need to set override `config.enableGatewayAPI=true`.

```bash
helm upgrade \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.19.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set config.enableGatewayAPI=true
```

## Step 5: Configure Gateway Parameters

By default, KGateway installs with a single replica. For high availability, configure 3 replicas:

```bash
kubectl apply -f- <<EOF
apiVersion: gateway.kgateway.dev/v1alpha1
kind: GatewayParameters
metadata:
  name: aid-gateway-parameters
  namespace:  ai-defense-onprem # The namespace where the services are running
spec:
  kube:
    deployment:
      replicas: 3
EOF
```

## Step 6: Create Gateway with TLS Termination

Deploy the Gateway resource with HTTPS listener and TLS termination:
Make sure to set the FQDN based on your internal DNS setup.

export FQDN=cisco-ai-defense.your-domain.com

```bash
kubectl apply -f- <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: aid-gateway
  namespace: ai-defense-onprem # The namespace where the services are running
  annotations:
    cert-manager.io/cluster-issuer: cisco-acme-issuer  # Optional: Remove if not using cert-manager
spec:
  gatewayClassName: kgateway
  infrastructure:
    parametersRef:
      group: gateway.kgateway.dev
      kind: GatewayParameters
      name: aid-gateway-parameters
  listeners:
  - hostname: ${FQDN}
    name: https
    port: 443
    protocol: HTTPS
    tls:
      certificateRefs:
      - group: ""
        kind: Secret
        name: aid-gateway-tls
      mode: Terminate 
      options:
        kgateway.dev/min-tls-version: "1.3" # Will be available from 2.2.0
EOF
```

**Note:** The `cert-manager.io/cluster-issuer` annotation is optional and only needed if you're using cert-manager for automatic certificate management.

## Step 7: Setup HTTPRoute for AI Defense Services

Create an HTTPRoute to route traffic to both the inspect and proxy services. The route configuration includes:
- `/api/v1/inspect` path routes to the `ai-defense-apigateway` service
- `/` (root) path routes to the `ai-defense-proxy-service` service

```bash
kubectl apply -f- <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ai-defense-routes
  namespace: ai-defense-onprem # The namespace where the services are running
spec:
  parentRefs:
  - name: aid-gateway
    namespace: ai-defense-onprem # The namespace where the services are running
  hostnames:
  - "${FQDN}"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api/v1/inspect
    backendRefs:
    - name: ai-defense-apigateway
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: ai-defense-proxy-service
      port: 8080
EOF
```

## Verification

After completing the installation, verify the Gateway and HTTPRoute status:

```bash
kubectl get gateway -n kgateway-system
kubectl get httproute -n ai-defense
```

Ensure the Gateway is in a `Ready` state and the HTTPRoute is properly attached to the Gateway.

```bash
kubectl get svc -n ai-defense-onprem aid-gateway
```

Sample Output:- 

```
NAME          TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)         AGE
aid-gateway   LoadBalancer   172.20.221.35   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxx.us-west-2.elb.amazonaws.com   443:32289/TCP   3h31m
```

Add a DNS entry for the FQDN to the external IP of the Gateway so that your application can resolve the endpoints 

The entry should be a CNAME entry if your cloud provider give an alias in the load balancer and A record if your cloud provider give an IP address in the load balancer.