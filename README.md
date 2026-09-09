# istio-resources

A Helm chart to manage Istio resources declaratively from a single `values.yaml`.

It renders the most common Istio CRDs — Gateway, VirtualService, ServiceEntry,
DestinationRule, AuthorizationPolicy, PeerAuthentication, RequestAuthentication —
with sensible helpers (labels, namespaces, health probes, redirects, etc.) so you
don't hand-write boilerplate per project.

## Resources

| Resource | Values key | Notes |
|---|---|---|
| `Gateway` | `ingress.gateways[]` | One or more gateways (e.g. external + internal) |
| `VirtualService` | `ingress.virtualservice` | Routes; optional built-in health probe, retries, timeout, CORS |
| `ServiceEntry` | `egress[]` | List of external/mesh service entries; optional egress-gateway routing |
| `DestinationRule` | `destinationrule[]` | Load balancing, subsets, outlier detection, connection pools |
| `AuthorizationPolicy` | `authorizationPolicy[]` | ALLOW/DENY rules; selector or targetRefs |
| `PeerAuthentication` | `peerAuthentication[]` | mTLS mode (STRICT/PERMISSIVE), port-level overrides |
| `RequestAuthentication` | `requestAuthentication[]` | JWT validation rules |

## Quick start

```yaml
ingress:
  name: git
  hosts:
    - git.example.com
  gateways:
    - type: external
      gateway_selector: istio-ingress-gateway-external
      ports:
        - number: 443
          name: https
          protocol: HTTPS
          tls:
            mode: SIMPLE
        - number: 80
          name: http
          protocol: HTTP
  virtualservice:
    health:
      enabled: true
    http:
      - route:
          - destination:
              host: httpbin.default.svc.cluster.local
              port:
                number: 3000
```

## Features

### Multiple gateways per ingress
Define several gateways (e.g. public + internal) under `ingress.gateways`.
Each produces `<name>-gateway-<type>`, and the VirtualService automatically
references all of them.

### HTTP → HTTPS redirect
Set `redirectHttps: true` on an individual gateway to render its HTTP (non-TLS)
ports as redirect servers (`tls.httpsRedirect: true`) instead of plain HTTP.
The flag is **per-gateway**, so the external gateway can redirect to HTTPS
while the internal gateway keeps serving plain HTTP.

### Built-in health probe
`ingress.virtualservice.health.enabled: true` injects a `/health` →
`/healthz/ready` route as the **first** HTTP rule (before your `http[]`),
routing to the ingress gateway's health endpoint by default. Override
`health.host` / `health.port` for non-default setups.

### Cross-namespace gateway references
When `ingress.gatewayNamespace` is set, the VirtualService references the
created gateways as `<gatewayNamespace>/<name>-gateway-<type>` (Istio's
required format for cross-namespace refs). Omit it for same-namespace refs.

### Egress gateway routing
Route mesh traffic to an external host through an Istio egress gateway.
The pattern mirrors ingress: **presence of `gateways`** creates the resources —
no separate enable flags.

```yaml
egress:
  - name: gitlab
    hosts:
      - gitlab.com
    ports:
      - number: 443
        name: https
        protocol: TLS
    location: MESH_EXTERNAL
    resolution: DNS
    gateways:
      - type: egress                       # Gateway: gitlab-gateway-egress
        gateway_selector: istio-egressgateway
```

This renders, alongside the `ServiceEntry`, the egress `Gateway`
(`<name>-gateway-<type>`, servers generated from the entry's ports/hosts, TLS
passthrough for non-HTTP ports) and a `VirtualService` with two rules:
mesh → egress gateway, and egress gateway → external host.

Per-gateway options:
- `host` — egress gateway service host to route traffic to
  (default `istio-egressgateway.istio-system.svc.cluster.local`)
- `subset` — route to a DestinationRule subset on the gateway host

### List-valued resources
`egress`, `destinationrule`, `authorizationPolicy`, `peerAuthentication`, and
`requestAuthentication` are **lists**, so one release can declare several of
each (multiple egress endpoints, multiple policies, etc.).

### Standardized metadata
Every resource gets Helm recommended labels (`app.kubernetes.io/*`,
`helm.sh/chart`) plus optional `commonLabels` and `commonAnnotations`. Use
`namespace` to place resources outside the release namespace.

## Values

| Key | Type | Default | Description |
|---|---|---|---|
| `nameOverride` | string | `""` | Override the chart name in resource names/labels |
| `namespace` | string | `""` | Namespace for all resources (defaults to release namespace) |
| `commonLabels` | object | `{}` | Labels added to every resource |
| `commonAnnotations` | object | `{}` | Annotations added to every resource |
| `ingress.name` | string | `""` | Base name for gateway/VS (defaults to release name) |
| `ingress.hosts` | list | `[]` | Hosts shared by gateway servers and the VirtualService |
| `ingress.gatewayNamespace` | string | `""` | Namespace prefix for cross-namespace gateway refs |
| `ingress.redirectHttps` | bool | `false` | *(removed — now per-gateway)* |
| `ingress.gateways[]` | list | `[]` | Gateway definitions (type, gateway_selector, redirectHttps, ports, tls) |
| `ingress.virtualservice.gateways` | list | `[]` | Explicit gateway refs (used when `ingress.gateways` is empty) |
| `ingress.virtualservice.health.enabled` | bool | `false` | Inject `/health` probe as first HTTP rule |
| `ingress.virtualservice.health.host` | string | `istio-ingress-gateway` | Health destination host |
| `ingress.virtualservice.health.port` | int | `15021` | Health destination port |
| `ingress.virtualservice.http[]` | list | `[]` | HTTP routes (match/rewrite/redirect/route/timeout/retries/corsPolicy) |
| `ingress.virtualservice.tcp[]` | list | `[]` | TCP routes |
| `egress[]` | list | `[]` | ServiceEntry definitions |
| `destinationrule[]` | list | `[]` | DestinationRule definitions |
| `authorizationPolicy[]` | list | `[]` | AuthorizationPolicy definitions |
| `peerAuthentication[]` | list | `[]` | PeerAuthentication definitions |
| `requestAuthentication[]` | list | `[]` | RequestAuthentication definitions |

See [`charts/istio-resources/values.yaml`](charts/istio-resources/values.yaml)
for fully commented examples of every resource.

## CI

The GitHub Actions workflow (`.github/workflows/release.yml`) runs `helm lint`
on default and full-feature values before publishing with chart-releaser.
