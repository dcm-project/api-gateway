# Three-Tier Demo App Service Provider with Kind

The Three-Tier Demo App Service Provider (SP) is a DCM plugin that provisions a Pet Clinic application
into a Kubernetes cluster. It requires the k8s-container-service-provider to be configured and running.

## Setup (one-time, until containers are recreated)

### Prerequisites

Before starting the three-tier SP, you must complete the k8s-container-service-provider setup:

1. Follow steps 1–5 in [k8s-container-sp-kind.md](k8s-container-sp-kind.md) to set up:
   - A Kind cluster connected to the Compose network
   - A kubeconfig configured to use the `kubernetes` alias
   - The k8s-container-service-provider running and healthy

Verify the setup:

```bash
curl -s http://localhost:9080/api/v1alpha1/health/providers | jq .
```

> **Note:** The response should include `k8s-container-provider` in the list of available providers.

### 1. Start the three-tier SP

```bash
podman-compose --profile three-tier up -d
```

Verify it is running:

```bash
podman-compose ps | grep three-tier
```

> **Note:** Ensure the k8s-container-service-provider is also running, as the three-tier SP depends on it.

Check the SP is registered with DCM:

```bash
curl -s http://localhost:9080/api/v1alpha1/providers | jq '.providers[] | select(.name | contains("three-tier"))'
```

### 2. Provision a Pet Clinic application

> **Important:** Users are not supposed to create service-type-instances on their own. The API Gateway only supports GET on the `/api/v1alpha1/service-type-instances` endpoint. Instead, you must create a CatalogItemInstance based on a pre-seeded CatalogItem.

First, list available catalog items to find the Pet Clinic offering:

```bash
curl -s http://localhost:9080/api/v1alpha1/catalog-items | jq .
```

> **Note:** Look for a catalog item with a `display_name` that indicates a Pet Clinic service. Note its `uid` value.

Then provision an instance by creating a CatalogItemInstance:

```bash
curl -X POST http://localhost:9080/api/v1alpha1/catalog-item-instances \
  -H "Content-Type: application/json" \
  -d '{
    "api_version": "v1alpha1",
    "display_name": "my-petclinic",
    "spec": {
      "catalog_item_id": "<catalog-item-uid>",
      "user_values": [
        {
          "path": "app_name",
          "value": "petclinic"
        }
      ]
    }
  }'
```

> **Tip:** Replace `<catalog-item-uid>` with the uid from the catalog-items list above. You can customize additional fields by adding more entries to the `user_values` array if needed.

### 3. Verify the Pet Clinic application is running

Monitor the Pet Clinic deployment in Kubernetes:

```bash
kubectl --kubeconfig kubeconfig.yaml get pods -n default
```

Wait for the Pet Clinic pod(s) to reach `Running` status.

Find the service endpoint:

```bash
kubectl --kubeconfig kubeconfig.yaml get svc -n default
```

Access the Pet Clinic application via its service endpoint (e.g., `http://<service-ip>:8080`).

## Troubleshooting

### The three-tier SP fails to start

Check the logs:

```bash
podman logs <container-name>
```

Common issues:

- **Kubeconfig not mounted correctly:** Verify `K8S_CONTAINER_SP_KUBECONFIG` is set and the file exists.
- **k8s-container-service-provider not running:** Ensure the k8s-container-service-provider is healthy.
- **NATS or Postgres not ready:** Check that `nats` and `postgres` services are running.

### Pet Clinic pod fails to start

Check the pod events:

```bash
kubectl --kubeconfig kubeconfig.yaml describe pod <pod-name> -n default
```

Check logs:

```bash
kubectl --kubeconfig kubeconfig.yaml logs <pod-name> -n default
```

### Cannot access Pet Clinic from host

The Pet Clinic application runs inside the Kind cluster and is accessible via:

- **From containers on the compose network:** Use the Kubernetes service DNS name (e.g., `petclinic.default.svc.cluster.local`).
- **From the host:** Use the NodePort or LoadBalancer endpoint exposed by Kubernetes. This depends on the `SP_K8S_EXTERNAL_SVC_TYPE` setting (see [k8s-container-sp-kind.md](k8s-container-sp-kind.md#external-service-type)).

> **Tip:** Set `SP_K8S_EXTERNAL_SVC_TYPE=LoadBalancer` and use `kubectl get svc` to find the endpoint.

## Why this is needed

The three-tier SP integrates with the DCM platform to expose Pet Clinic as a managed service,
enabling declarative provisioning and lifecycle management through the API gateway.

| Problem | Cause |
|---|---|
| Three-tier SP cannot provision apps without k8s-container-service-provider | The three-tier SP is a high-level orchestration layer that delegates resource provisioning to a k8s-container-service-provider |
| App is unreachable from the host | The app runs inside the Kind cluster, which is on a separate Podman network |
| Deployment hangs or fails | Missing environment variables or unhealthy dependencies (NATS, Postgres, k8s-container-service-provider) |
