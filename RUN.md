# Running DCM

## Prerequisites

- [Podman](https://podman.io/) and `podman-compose` installed
- (Optional) A Kubernetes cluster with KubeVirt for the kubevirt-service-provider
- (Optional) A Kubernetes cluster for the k8s-container-service-provider
- (Optional) An OpenShift cluster with ACM/MCE and HyperShift for the acm-cluster-service-provider

## Quick start

Start all core services (gateway, postgres, nats, and all managers):

```bash
podman-compose up -d
```

The API gateway will be available at `http://localhost:9080`.

## Running with service providers

Service providers are behind compose profiles and do not start by default.

### KubeVirt service provider

To include the `kubevirt-service-provider`, set the required environment variables and
activate the `kubevirt` profile:

```bash
export KUBERNETES_NAMESPACE=vms
export KUBERNETES_KUBECONFIG="/path/to/kubeconfig"
podman-compose --profile kubevirt up -d
```

### K8s container service provider

To include the `k8s-container-service-provider`, set the required environment variables and
activate the `k8s-container` profile:

```bash
export K8S_CONTAINER_SP_KUBECONFIG="/path/to/kubeconfig"
podman-compose --profile k8s-container up -d
```

If using Kind, see [K8s Container SP with Kind](docs/k8s-container-sp-kind.md) for additional network setup.

Optionally override the provider name or external service type:

```bash
export K8S_CONTAINER_SP_NAME=my-provider
export K8S_CONTAINER_SP_EXTERNAL_SVC_TYPE=LoadBalancer
```

### ACM cluster service provider

To include the `acm-cluster-service-provider`, set the required environment variables and
activate the `acm-cluster` profile:

```bash
export ACM_CLUSTER_SP_KUBECONFIG="/path/to/kubeconfig"
export ACM_CLUSTER_SP_PULL_SECRET="<base64-encoded-dockerconfigjson>"
podman-compose --profile acm-cluster up -d
```

Optionally override the provider name, namespace, or base domain:

```bash
export ACM_CLUSTER_SP_NAME=my-acm-provider
export ACM_CLUSTER_SP_NAMESPACE=clusters
export ACM_CLUSTER_SP_BASE_DOMAIN="apps.example.com"
```

For BareMetal provisioning, also set:

```bash
export ACM_CLUSTER_SP_DEFAULT_INFRA_ENV="my-infra-env"
export ACM_CLUSTER_SP_AGENT_NAMESPACE="my-agent-namespace"
```

### All providers

To start all providers at once, use the `providers` profile:

```bash
export KUBERNETES_KUBECONFIG="/path/to/kubeconfig"
export K8S_CONTAINER_SP_KUBECONFIG="/path/to/kubeconfig"
export ACM_CLUSTER_SP_KUBECONFIG="/path/to/kubeconfig"
export ACM_CLUSTER_SP_PULL_SECRET="<base64-encoded-dockerconfigjson>"
# BareMetal only:
export ACM_CLUSTER_SP_DEFAULT_INFRA_ENV="my-infra-env"
export ACM_CLUSTER_SP_AGENT_NAMESPACE="my-agent-namespace"
podman-compose --profile providers up -d
```

## Verifying the deployment

Check that all services are running:

```bash
podman-compose ps
```

Check health endpoints through the gateway:

```bash
curl http://localhost:9080/api/v1alpha1/health/providers
curl http://localhost:9080/api/v1alpha1/health/catalog
curl http://localhost:9080/api/v1alpha1/health/policies
curl http://localhost:9080/api/v1alpha1/health/placement
```

## Stopping services

```bash
podman-compose down
```

To also remove volumes (databases, NATS data):

```bash
podman-compose down -v
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_USER` | `admin` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `adminpass` | PostgreSQL password |
| `KUBERNETES_NAMESPACE` | `default` | Kubernetes namespace for KubeVirt VMs |
| `KUBERNETES_KUBECONFIG` | `~/.kube/config` | Path to kubeconfig on the host |
| `K8S_CONTAINER_SP_KUBECONFIG` | `~/.kube/config` | Path to kubeconfig on the host for the k8s-container-service-provider|
| `K8S_CONTAINER_SP_NAMESPACE` | `default` | Kubernetes namespace for k8s containers |
| `K8S_CONTAINER_SP_NAME` | `k8s-container-provider` | Provider name for the k8s-container-service-provider |
| `K8S_CONTAINER_SP_EXTERNAL_SVC_TYPE` | `NodePort` | Kubernetes Service type for external ports (`NodePort` or `LoadBalancer`) |
| `ACM_CLUSTER_SP_KUBECONFIG` | `~/.kube/config` | Path to kubeconfig on the host for the acm-cluster-service-provider |
| `ACM_CLUSTER_SP_NAMESPACE` | `default` | Kubernetes namespace for ACM hosted clusters |
| `ACM_CLUSTER_SP_NAME` | `acm-cluster-sp` | Provider name for the acm-cluster-service-provider |
| `ACM_CLUSTER_SP_BASE_DOMAIN` | *(none)* | Base DNS domain for hosted clusters; can be overridden per-request via `provider_hints.acm.base_domain` |
| `ACM_CLUSTER_SP_PULL_SECRET` | *(required)* | Base64-encoded dockerconfigjson pull secret for ACM hosted clusters |
| `ACM_CLUSTER_SP_DEFAULT_INFRA_ENV` | *(none)* | **BareMetal only.** Default InfraEnv name; can be overridden per-request via `provider_hints.acm.infra_env` |
| `ACM_CLUSTER_SP_AGENT_NAMESPACE` | *(none)* | **BareMetal only.** Namespace where Agent resources are located |
