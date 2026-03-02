.PHONY: help build test clean release fmt clippy install

# Default target
help:
	@echo "Available targets:"
	@echo "  build       - Build in debug mode"
	@echo "  test        - Run tests"
	@echo "  clean       - Clean build artifacts"
	@echo "  release     - Build in release mode"
	@echo "  fmt         - Format code"
	@echo "  clippy      - Run clippy lints"
	@echo "  install     - Install locally"
	@echo "  all         - Run full validation pipeline"

# Development targets
build:
	cargo build

test:
	cargo test

clean:
	cargo clean

release:
	cargo build --release

fmt:
	cargo fmt --all

clippy:
	cargo clippy --all-targets -- -D warnings

install:
	cargo install --path . --force

# CI-like validation
all: fmt clippy test release
	@echo "All validation steps completed successfully!"
