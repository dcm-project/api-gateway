.PHONY: validate-config run run-gateway-only check-config clone-deps compose-up compose-down clean

KRAKEND_CONFIG ?= config/krakend.json

# Validate KrakenD gateway config (requires krakend binary)
validate-config: check-config

check-config:
	@command -v krakend >/dev/null 2>&1 || { echo "krakend not found: install from https://www.krakend.io/docs/overview/installing/"; exit 1; }
	krakend check -c $(KRAKEND_CONFIG)

# Run full stack (gateway + managers) via Compose. Runs clone-deps then compose-up.
run: clone-deps
	@podman compose up -d --build

# Run only the gateway binary on the host (no Compose, no managers). Use when backends are elsewhere or for quick config checks.
run-gateway-only:
	@command -v krakend >/dev/null 2>&1 || { echo "krakend not found: install from https://www.krakend.io/docs/overview/installing/"; exit 1; }
	krakend run -c $(KRAKEND_CONFIG)

# Clone manager repos for compose (default: /tmp/dcm-compose-repos). Idempotent. Writes .env so compose sees DCM_MANAGERS_DIR.
clone-deps:
	@bash hack/ensure-repos.sh .env

# Start gateway and managers with compose. Run "make clone-deps" first, or have manager repos as siblings (parent dir) so build context .. works.
compose-up:
	@podman compose up -d --build

# Stop compose stack and remove volumes.
compose-down:
	@podman compose down -v

# Stop stack (if running), remove .env and default clone dir. Safe when nothing is running.
clean:
	@podman compose down -v 2>/dev/null || true
	@rm -f .env
	@rm -rf "$${TMPDIR:-/tmp}/dcm-compose-repos"
	@echo "cleaned .env and default manager clone dir"
