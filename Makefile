.PHONY: validate-config run run-gateway-only run-gateway-only-container check-config compose-down clean

ENGINE ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || \
	(command -v docker >/dev/null 2>&1 && echo docker || \
	(echo "podman")))

KRAKEND_CONFIG ?= config/krakend.json.tmpl

# Validate KrakenD gateway config
validate-config: check-config

check-config:
	$(ENGINE) run --rm -v ${PWD}:/workspace -w /workspace -e FC_ENABLE=1 -e FC_SETTINGS=config/settings docker.io/krakend:2.13.1 krakend check -c $(KRAKEND_CONFIG)

# Run full stack (gateway + managers) via Compose. Pulls images and starts the stack.
run:
	$(ENGINE) compose up -d

# Run only the gateway binary on the host (no Compose, no managers). Use when backends are elsewhere or for quick config checks.
run-gateway-only:
	@command -v krakend >/dev/null 2>&1 || { echo "krakend not found: install from https://www.krakend.io/docs/overview/installing/"; exit 1; }
	FC_ENABLE=1 FC_SETTINGS=config/settings krakend run -c $(KRAKEND_CONFIG)

run-gateway-only-container:
	$(ENGINE) run --rm -d --name gateway -p 9080:9080 -v ${PWD}:/workspace -w /workspace -e FC_ENABLE=1 -e FC_SETTINGS=config/settings docker.io/krakend:2.13.1 krakend run -c $(KRAKEND_CONFIG)

# Stop compose stack and remove volumes.
compose-down:
	$(ENGINE) compose down -v

# Stop stack (if running) and remove .env.
clean:
	$(ENGINE) compose down -v 2>/dev/null || true
	@rm -f .env
	@echo "cleaned"
