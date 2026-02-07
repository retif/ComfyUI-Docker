.PHONY: help build build-base build-python build-pytorch build-deps build-perf build-comfyui load run clean dev

help:
	@echo "ComfyUI NixOS Flake - Build Commands"
	@echo ""
	@echo "Build individual layers:"
	@echo "  make build-base      - Build base layer (CUDA + system)"
	@echo "  make build-python    - Build Python 3.14 layer"
	@echo "  make build-pytorch   - Build PyTorch layer"
	@echo "  make build-deps      - Build dependencies layer"
	@echo "  make build-perf      - Build performance libs layer"
	@echo "  make build-comfyui   - Build ComfyUI app layer"
	@echo ""
	@echo "Build complete image:"
	@echo "  make build           - Build complete image"
	@echo "  make load            - Build and load into Docker"
	@echo ""
	@echo "Run:"
	@echo "  make run             - Run ComfyUI container"
	@echo "  make dev             - Enter development shell"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean           - Remove build artifacts"
	@echo "  make update          - Update flake inputs"

build-base:
	nix build .#baseLayer
	@echo "Built: baseLayer → result"

build-python:
	nix build .#pythonLayer
	@echo "Built: pythonLayer → result"

build-pytorch:
	nix build .#pytorchLayer
	@echo "Built: pytorchLayer → result"

build-deps:
	nix build .#dependenciesLayer
	@echo "Built: dependenciesLayer → result"

build-perf:
	nix build .#performanceLayer
	@echo "Built: performanceLayer → result"

build-comfyui:
	nix build .#comfyuiLayer
	@echo "Built: comfyuiLayer → result"

build:
	nix build .#comfyui
	@echo "Built: Complete image → result"
	@echo "Load with: ./result | docker load"

load: build
	./result | docker load
	@echo "Loaded into Docker as: comfyui-boot:cu130-megapak-py314-nix"

run:
	docker run --rm -it \
		--gpus all \
		-p 8188:8188 \
		-v "$$(pwd)/output:/root/output" \
		comfyui-boot:cu130-megapak-py314-nix

dev:
	nix develop

clean:
	rm -rf result result-*
	@echo "Cleaned build artifacts"

update:
	nix flake update
	@echo "Updated flake inputs"

# Development helpers
show-layers:
	@echo "Image layers:"
	@nix eval .#packages.x86_64-linux --apply 'pkgs: builtins.attrNames pkgs'

info:
	@echo "Flake info:"
	@nix flake info
	@echo ""
	@echo "Flake metadata:"
	@nix flake metadata
