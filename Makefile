.PHONY: validate-config run run-with-providers run-gateway-only run-gateway-only-container check-config compose-down clean

ENGINE ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || \
	(command -v docker >/dev/null 2>&1 && echo docker || \
	(echo "podman")))

TRAEFIK_CONFIG ?= config/traefik.yml
PROFILES ?= providers

# Validate Traefik gateway config
validate-config: check-config

check-config:
	@echo "Starting Traefik to validate config..."
	@$(ENGINE) run --rm -d --name gateway-validate -v ${PWD}/config/traefik.yml:/etc/traefik/traefik.yml:ro -v ${PWD}/config/dynamic:/etc/traefik/dynamic:ro docker.io/traefik:v3.4 --configFile=/etc/traefik/traefik.yml && \
	sleep 2 && \
	$(ENGINE) logs gateway-validate 2>&1 | (! grep -qi 'error\|cannot\|invalid\|fatal') && \
	echo "Config OK" && \
	$(ENGINE) rm -f gateway-validate > /dev/null 2>&1 || \
	{ echo "Config validation failed:"; $(ENGINE) logs gateway-validate 2>&1; $(ENGINE) rm -f gateway-validate > /dev/null 2>&1; exit 1; }

# Run full stack (gateway + managers) via Compose. Pulls images and starts the stack.
run:
	$(ENGINE) compose up -d

# Run full stack with service providers. Defaults to all providers; override with PROFILES=kubevirt, etc.
run-with-providers:
	$(ENGINE) compose --profile $(PROFILES) up -d

# Run only the gateway binary on the host (no Compose, no managers). Use when backends are elsewhere or for quick config checks.
run-gateway-only:
	@command -v traefik >/dev/null 2>&1 || { echo "traefik not found: install from https://doc.traefik.io/traefik/getting-started/install-traefik/"; exit 1; }
	traefik --configFile=$(TRAEFIK_CONFIG)

run-gateway-only-container:
	$(ENGINE) run --rm -d --name gateway -p 9080:9080 -v ${PWD}/config/traefik.yml:/etc/traefik/traefik.yml:ro -v ${PWD}/config/dynamic:/etc/traefik/dynamic:ro docker.io/traefik:v3.4 --configFile=/etc/traefik/traefik.yml

# Stop compose stack and remove volumes.
compose-down:
	$(ENGINE) compose down -v

# Stop stack (if running) and remove .env.
clean:
	$(ENGINE) compose down -v 2>/dev/null || true
	@rm -f .env
	@echo "cleaned"
