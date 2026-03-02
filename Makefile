.PHONY: validate-config run run-gateway-only check-config compose-down clean

KRAKEND_CONFIG ?= config/krakend.json

# Validate KrakenD gateway config (requires krakend binary)
validate-config: check-config

check-config:
	@command -v krakend >/dev/null 2>&1 || { echo "krakend not found: install from https://www.krakend.io/docs/overview/installing/"; exit 1; }
	krakend check -c $(KRAKEND_CONFIG)

# Run full stack (gateway + managers) via Compose. Pulls images and starts the stack.
run:
	@podman compose up -d

# Run only the gateway binary on the host (no Compose, no managers). Use when backends are elsewhere or for quick config checks.
run-gateway-only:
	@command -v krakend >/dev/null 2>&1 || { echo "krakend not found: install from https://www.krakend.io/docs/overview/installing/"; exit 1; }
	krakend run -c $(KRAKEND_CONFIG)

# Stop compose stack and remove volumes.
compose-down:
	@podman compose down -v

# Stop stack (if running) and remove .env.
clean:
	@podman compose down -v 2>/dev/null || true
	@rm -f .env
	@echo "cleaned"
