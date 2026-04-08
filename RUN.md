# Running DCM

## Prerequisites

- [Podman](https://podman.io/) and `podman-compose` installed
- (Optional) A Kubernetes cluster with KubeVirt for the kubevirt-service-provider
- (Optional) A Kubernetes cluster for the k8s-container-service-provider

## Quick start

Start all core services (gateway, postgres, nats, opa, and all managers):

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

### All providers

To start all providers at once, use the `providers` profile:

```bash
export KUBERNETES_KUBECONFIG="/path/to/kubeconfig"
export K8S_CONTAINER_SP_KUBECONFIG="/path/to/kubeconfig"
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
