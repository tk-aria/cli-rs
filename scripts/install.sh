#!/bin/sh

set -e

if [ -n "${DEBUG}" ]; then
  set -x
fi

# デフォルト設定
DEFAULT_INSTALL_PATH="/usr/local/bin"
CLI_RS_REPO="tk-aria/cli-rs"

# 最新バージョンを取得
_cli_rs_latest() {
  curl -sSLf "https://api.github.com/repos/${CLI_RS_REPO}/releases/latest" | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/'
}

# OS検出
_detect_os() {
  os="$(uname -s)"
  case "$os" in
    Linux) echo "linux" ;;
    Darwin) echo "darwin" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) echo "Unsupported operating system: $os" 1>&2; return 1 ;;
  esac
  unset os
}

# アーキテクチャ検出
_detect_arch() {
  arch="$(uname -m)"
  case "$arch" in
    amd64|x86_64) echo "x86_64" ;;
    arm64|aarch64) echo "aarch64" ;;
    armv7l|armv8l|arm) echo "armv7" ;;
    *) echo "Unsupported processor architecture: $arch" 1>&2; return 1 ;;
  esac
  unset arch
}

# バイナリ名を決定
_get_binary_name() {
  os="$1"
  case "$os" in
    windows) echo "cli-rs.exe" ;;
    *) echo "cli-rs" ;;
  esac
}

# ダウンロードURL生成
_download_url() {
  local version="$1"
  local os="$2"
  local arch="$3"

  # バイナリファイル名: cli-rs-{version}-{os}-{arch}.tar.gz
  local archive_name="cli-rs-${version}-${os}-${arch}.tar.gz"
  echo "https://github.com/${CLI_RS_REPO}/releases/download/${version}/${archive_name}"
}

# インストール実行
main() {
  # バージョン決定
  if [ -z "${CLI_RS_VERSION}" ]; then
    echo "Getting latest version..."
    CLI_RS_VERSION=$(_cli_rs_latest)
    if [ -z "${CLI_RS_VERSION}" ]; then
      echo "Failed to get latest version" 1>&2
      return 1
    fi
  fi

  # インストールパス決定
  cli_rs_install_path="${CLI_RS_INSTALL_PATH:-$DEFAULT_INSTALL_PATH}"

  # プラットフォーム検出
  cli_rs_os="$(_detect_os)"
  cli_rs_arch="$(_detect_arch)"
  cli_rs_binary="$(_get_binary_name "$cli_rs_os")"

  # ダウンロードURL生成
  cli_rs_download_url="$(_download_url "$CLI_RS_VERSION" "$cli_rs_os" "$cli_rs_arch")"

  echo "Installing cli-rs ${CLI_RS_VERSION} for ${cli_rs_os}/${cli_rs_arch}..."
  echo "Download URL: $cli_rs_download_url"

  # インストールディレクトリ作成
  if [ ! -d "$cli_rs_install_path" ]; then
    echo "Creating install directory: $cli_rs_install_path"
    mkdir -p -- "$cli_rs_install_path"
  fi

  # 一時ディレクトリ作成
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  # アーカイブダウンロード
  echo "Downloading cli-rs archive..."
  if ! curl -sSLf "$cli_rs_download_url" -o "$tmp_dir/cli-rs.tar.gz"; then
    echo "Failed to download cli-rs archive from: $cli_rs_download_url" 1>&2
    echo "Please check if the version ${CLI_RS_VERSION} exists and supports ${cli_rs_os}/${cli_rs_arch}" 1>&2
    return 1
  fi

  # アーカイブ展開
  echo "Extracting cli-rs archive..."
  if ! tar -xzf "$tmp_dir/cli-rs.tar.gz" -C "$tmp_dir"; then
    echo "Failed to extract cli-rs archive" 1>&2
    return 1
  fi

  # バイナリ配置
  echo "Installing cli-rs to $cli_rs_install_path/$cli_rs_binary"
  if ! cp "$tmp_dir/$cli_rs_binary" "$cli_rs_install_path/$cli_rs_binary"; then
    echo "Failed to install cli-rs binary. Check permissions for $cli_rs_install_path" 1>&2
    echo "You may need to run this script with sudo or choose a different install path" 1>&2
    return 1
  fi

  chmod 755 -- "$cli_rs_install_path/$cli_rs_binary"

  echo ""
  echo "✅ cli-rs ${CLI_RS_VERSION} has been successfully installed!"
  echo ""
  echo "The cli-rs binary is installed at: $cli_rs_install_path/$cli_rs_binary"
  echo ""
  echo "To get started, run:"
  echo "  cli-rs help"
  echo ""
  echo "For more information, visit: https://github.com/${CLI_RS_REPO}"
}

main "$@"
