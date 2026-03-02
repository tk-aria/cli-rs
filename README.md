# 🦀 cli-rs

Rust implementation of [cli.sh](https://github.com/tk-aria/cli.sh) -- a minimal CLI subcommand framework with self-documenting help.

## 📦 Install

### Quick install (recommended)

```bash
curl -sSLf https://raw.githubusercontent.com/tk-aria/cli-rs/main/scripts/setup.sh | sh -s install
```

### Specify version and install path

```bash
curl -sSLf https://raw.githubusercontent.com/tk-aria/cli-rs/main/scripts/setup.sh | \
  CLI_RS_VERSION=v0.1.0 CLI_RS_INSTALL_PATH=/usr/local/bin sh -s install
```

### 🗑️ Uninstall

```bash
curl -sSLf https://raw.githubusercontent.com/tk-aria/cli-rs/main/scripts/setup.sh | sh -s uninstall
```

### 🔨 Build from source

```bash
git clone https://github.com/tk-aria/cli-rs.git
cd cli-rs
cargo build --release
```

## 🚀 Usage

```bash
cli-rs <command> [arguments]
```

## 📖 Commands

| Command | Description |
|---------|-------------|
| `help` | 💡 Display help information for all available commands |
| `version` | 🏷️ Display the current version |
| `fzf` | 🔍 Select and execute a subcommand interactively with fzf |
| `hello_world` | 👋 Display "Hello, World!" |
| `show_date` | 📅 Display the current date and time |

### Examples

```bash
# Show help
cli-rs help

# Show version
cli-rs version
# => v0.1.0

# Run hello_world
cli-rs hello_world
# => Hello, World!

# Show current date and time
cli-rs show_date
# => Current date and time: Mon Mar  2 09:00:00 UTC 2026

# Interactive command selection (requires fzf)
cli-rs fzf
```

## 🗂️ Project Structure

```
cli-rs/
├── src/
│   └── main.rs            # CLI implementation
├── scripts/
│   └── setup.sh           # Installer (install / uninstall)
├── .github/
│   └── workflows/
│       └── release.yml    # CI release pipeline
├── Cargo.toml
├── Makefile
└── README.md
```

## 🛠️ Development

```bash
make build      # Build in debug mode
make test       # Run tests
make release    # Build in release mode
make fmt        # Format code
make clippy     # Run linter
make all        # Full validation (fmt + clippy + test + release)
```

## 🌍 Supported Platforms

| Platform | Architecture | Status |
|----------|-------------|--------|
| 🐧 Linux | x86_64 | ✅ Supported (musl static binary) |
| 🍎 macOS | x86_64 | ✅ Supported |
| 🍎 macOS | aarch64 (Apple Silicon) | ✅ Supported |
| 🪟 Windows | x86_64 | ✅ Supported |

## 📄 License

See [LICENSE](LICENSE) for details.
