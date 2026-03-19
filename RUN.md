# Running DCM

## Prerequisites

- [Podman](https://podman.io/) and `podman-compose` installed
- (Optional) A Kubernetes cluster with KubeVirt for the kubevirt-service-provider

## Quick start

Start all core services (gateway, postgres, nats, opa, and all managers):

```bash
podman-compose up -d
```

The API gateway will be available at `http://localhost:9080`.

## Running with the KubeVirt service provider

The `kubevirt-service-provider` is behind a compose profile and does not start by default.
To include it, set the required environment variables and activate the `kubevirt` profile:

```bash
export KUBERNETES_NAMESPACE=vms
export KUBERNETES_KUBECONFIG="/path/to/kubeconfig"
podman-compose --profile kubevirt up -d
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
