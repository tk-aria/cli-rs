#!/bin/sh
VERSION=v0.1.0

set -e

if [ -n "${DEBUG}" ]; then
  set -x
fi

# デフォルト設定
DEFAULT_INSTALL_PATH="/usr/local/bin"
CLI_RS_REPO="tk-aria/cli-rs"
BINARY_NAME="cli-rs"

# ANSI color codes
PURPLE='\033[35m'
CYAN='\033[36m'
GREEN='\033[32m'
BRIGHT_GREEN='\033[92m'
RESET='\033[0m'

# 最新バージョンを取得
_cli_rs_latest() {
  curl -sSLf "https://api.github.com/repos/${CLI_RS_REPO}/releases/latest" | \
    grep '"tag_name":' | \
    sed -E 's/.*"([^"]+)".*/\1/'
}

# OS検出
_detect_os() {
  _os="$(uname -s)"
  case "$_os" in
    Linux) echo "linux" ;;
    Darwin) echo "darwin" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) echo "Unsupported operating system: $_os" 1>&2; return 1 ;;
  esac
  unset _os
}

# アーキテクチャ検出
_detect_arch() {
  _arch="$(uname -m)"
  case "$_arch" in
    amd64|x86_64) echo "x86_64" ;;
    arm64|aarch64) echo "aarch64" ;;
    armv7l|armv8l|arm) echo "armv7" ;;
    *) echo "Unsupported processor architecture: $_arch" 1>&2; return 1 ;;
  esac
  unset _arch
}

# バイナリ名を決定
_get_binary_name() {
  _gbn_os="$1"
  case "$_gbn_os" in
    windows) echo "${BINARY_NAME}.exe" ;;
    *) echo "${BINARY_NAME}" ;;
  esac
  unset _gbn_os
}

# ダウンロードURL生成
_download_url() {
  _dl_version="$1"
  _dl_os="$2"
  _dl_arch="$3"
  _dl_archive_name="${BINARY_NAME}-${_dl_version}-${_dl_os}-${_dl_arch}.tar.gz"
  echo "https://github.com/${CLI_RS_REPO}/releases/download/${_dl_version}/${_dl_archive_name}"
  unset _dl_version _dl_os _dl_arch _dl_archive_name
}

# バージョンとプラットフォーム情報を準備
_resolve_platform() {
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
  CLI_RS_INSTALL_PATH="${CLI_RS_INSTALL_PATH:-$DEFAULT_INSTALL_PATH}"

  # プラットフォーム検出
  _platform_os="$(_detect_os)"
  _platform_arch="$(_detect_arch)"
  _platform_binary="$(_get_binary_name "$_platform_os")"
}

# display help information for all available commands.
help() {
  _cmd=$(basename "$0")
  _cmd="${_cmd%.*}"

  printf "${PURPLE}%s${RESET} (${CYAN}%s${RESET})\n" "$_cmd" "$VERSION"
  printf "\nUsage: ${PURPLE}%s${RESET} [${BRIGHT_GREEN}arguments${RESET}]\"\n" "$0"

  printf "\n${GREEN}help${RESET}:\n"
  printf "  display help information for all available commands.\n"

  printf "\n${GREEN}version${RESET}:\n"
  printf "  display the current version of this command.\n"

  printf "\n${GREEN}install${RESET}:\n"
  printf "  download and install the cli-rs binary.\n"
  printf "  \n"
  printf "  Environment variables:\n"
  printf "    CLI_RS_VERSION       - version to install (default: latest)\n"
  printf "    CLI_RS_INSTALL_PATH  - install directory (default: /usr/local/bin)\n"

  printf "\n${GREEN}uninstall${RESET}:\n"
  printf "  remove the cli-rs binary from the system.\n"
  printf "  \n"
  printf "  Environment variables:\n"
  printf "    CLI_RS_INSTALL_PATH  - install directory (default: /usr/local/bin)\n"
  echo ""

  unset _cmd
}

# display the current version of this command.
version() {
  echo "${VERSION}"
}

# download and install the cli-rs binary.
#
# Environment variables:
#   CLI_RS_VERSION       - version to install (default: latest)
#   CLI_RS_INSTALL_PATH  - install directory (default: /usr/local/bin)
install() {
  _resolve_platform

  # ダウンロードURL生成
  _install_download_url="$(_download_url "$CLI_RS_VERSION" "$_platform_os" "$_platform_arch")"

  echo "Installing ${BINARY_NAME} ${CLI_RS_VERSION} for ${_platform_os}/${_platform_arch}..."
  echo "Download URL: $_install_download_url"

  # インストールディレクトリ作成
  if [ ! -d "$CLI_RS_INSTALL_PATH" ]; then
    echo "Creating install directory: $CLI_RS_INSTALL_PATH"
    mkdir -p "$CLI_RS_INSTALL_PATH"
  fi

  # 一時ディレクトリ作成
  _install_tmp_dir=$(mktemp -d)
  trap 'rm -rf "$_install_tmp_dir"' EXIT

  # アーカイブダウンロード
  echo "Downloading ${BINARY_NAME} archive..."
  if ! curl -sSLf "$_install_download_url" -o "$_install_tmp_dir/${BINARY_NAME}.tar.gz"; then
    echo "Failed to download ${BINARY_NAME} archive from: $_install_download_url" 1>&2
    echo "Please check if the version ${CLI_RS_VERSION} exists and supports ${_platform_os}/${_platform_arch}" 1>&2
    return 1
  fi

  # アーカイブ展開
  echo "Extracting ${BINARY_NAME} archive..."
  if ! tar -xzf "$_install_tmp_dir/${BINARY_NAME}.tar.gz" -C "$_install_tmp_dir"; then
    echo "Failed to extract ${BINARY_NAME} archive" 1>&2
    return 1
  fi

  # バイナリ配置
  echo "Installing ${BINARY_NAME} to $CLI_RS_INSTALL_PATH/$_platform_binary"
  if ! cp "$_install_tmp_dir/$_platform_binary" "$CLI_RS_INSTALL_PATH/$_platform_binary"; then
    echo "Failed to install ${BINARY_NAME} binary. Check permissions for $CLI_RS_INSTALL_PATH" 1>&2
    echo "You may need to run this script with sudo or choose a different install path" 1>&2
    return 1
  fi

  chmod 755 "$CLI_RS_INSTALL_PATH/$_platform_binary"

  echo ""
  echo "✅ ${BINARY_NAME} ${CLI_RS_VERSION} has been successfully installed!"
  echo ""
  echo "The ${BINARY_NAME} binary is installed at: $CLI_RS_INSTALL_PATH/$_platform_binary"
  echo ""
  echo "To get started, run:"
  echo "  ${BINARY_NAME} help"
  echo ""
  echo "For more information, visit: https://github.com/${CLI_RS_REPO}"

  unset _install_download_url _install_tmp_dir
}

# remove the cli-rs binary from the system.
#
# Environment variables:
#   CLI_RS_INSTALL_PATH  - install directory (default: /usr/local/bin)
uninstall() {
  CLI_RS_INSTALL_PATH="${CLI_RS_INSTALL_PATH:-$DEFAULT_INSTALL_PATH}"

  _uninstall_os="$(_detect_os)"
  _uninstall_binary="$(_get_binary_name "$_uninstall_os")"
  _uninstall_target="$CLI_RS_INSTALL_PATH/$_uninstall_binary"

  if [ ! -f "$_uninstall_target" ]; then
    echo "${BINARY_NAME} is not installed at: $_uninstall_target" 1>&2
    return 1
  fi

  echo "Removing ${BINARY_NAME} from $_uninstall_target..."
  if ! rm "$_uninstall_target"; then
    echo "Failed to remove ${BINARY_NAME}. Check permissions for $CLI_RS_INSTALL_PATH" 1>&2
    echo "You may need to run this script with sudo" 1>&2
    return 1
  fi

  echo ""
  echo "✅ ${BINARY_NAME} has been successfully uninstalled!"
  echo ""

  unset _uninstall_os _uninstall_binary _uninstall_target
}

cmd="${1:-}"
if [ $# -gt 0 ]; then
  shift
fi
case "$cmd" in
  help)
    help
    ;;

  version)
    version
    ;;

  install)
    install "$@"
    exit $?
    ;;

  uninstall)
    uninstall "$@"
    exit $?
    ;;

  *)
    help
    ;;
esac
