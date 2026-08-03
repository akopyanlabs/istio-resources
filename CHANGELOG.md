# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.1] - 2026-08-03

### Added
- **Security resources:**
  - `AuthorizationPolicy` (ALLOW/DENY, selector or targetRefs, raw spec override)
  - `PeerAuthentication` (mTLS STRICT/PERMISSIVE, port-level overrides)
  - `RequestAuthentication` (JWT validation rules)
- **Multiple gateways per ingress:** `gateway` (single) is now `gateways` (list),
  so one release can declare external + internal gateways.
- **Built-in health probe:** `ingress.virtualservice.health.enabled` injects a
  `/health` → `/healthz/ready` route as the first HTTP rule.
- **Cross-namespace gateway references** via `ingress.gatewayNamespace`.
- **Per-gateway HTTP→HTTPS redirect** via `redirectHttps` on each gateway.
- **VirtualService route fields:** `timeout`, `retries`, `headers`, `corsPolicy`.
- **DestinationRule:** `outlierDetection`, `connectionPool`.
- **Standardized metadata:** Helm recommended labels (`app.kubernetes.io/*`,
  `helm.sh/chart`), `commonLabels`, `commonAnnotations`, configurable `namespace`.
- **CI:** `helm lint` (default + full) and `helm template` validation before release.
- **`ci/full.yaml`** test fixture covering all resources.
- **README** with resources overview, features, and a values table.
- `Chart.yaml` metadata: `type`, `home`, `sources`, `maintainers`, `icon`,
  `annotations`, expanded `keywords`.

### Changed
- `gateway` → **`gateways`** (list).
- `egress` → **`egress[]`** (list, multiple ServiceEntries per release).
- `destinationrule` → **`destinationrule[]`** (list).
- `redirectHttps` moved from ingress level to **per-gateway**.

### Fixed
- `ServiceEntry.ports` rendered an invalid structure (extra `port:` key with
  collapsed fields); now matches the Istio schema (flat `number`/`name`/`protocol`).
- Typo in `values.yaml` example: `htpbin` → `httpbin`.

### Removed
- Top-level `ingress.redirectHttps` (replaced by per-gateway `redirectHttps`).

### ⚠️ Breaking changes
- `gateway` (single) → `gateways` (list).
- `egress` and `destinationrule` are now lists.
- `redirectHttps` moved from ingress level to per-gateway.
- The health probe moved from a manual `http[]` entry to the `health` block.

## [0.1.0] - 2026-04-26

### Added
- Initial chart: Gateway, VirtualService, ServiceEntry, DestinationRule.
- GitHub Actions workflow publishing the chart via chart-releaser.
