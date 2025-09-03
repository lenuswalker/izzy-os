#!/usr/bin/env bash
set -euo pipefail

# Fedora-focused WinApps installer using podman-compose + Flatpak FreeRDP
# - Assumes podman(+podman-compose), git, curl already installed
# - Assumes org.freerdp.FreeRDP is installed as a Flatpak
# - Creates a wrapper so 'xfreerdp'/'wfreerdp' resolve to the Flatpak
# - Creates ~/.config/winapps/winapps.conf (non-destructive)
# - Adds compose.override.yaml (non-destructive)
# - Launches the WinApps container/VM and runs upstream setup

REPO_URL="https://github.com/winapps-org/winapps"
REPO_DIR="${HOME}/.local/src/winapps"
CFG_DIR="${HOME}/.config/winapps"
CFG_FILE="${CFG_DIR}/winapps.conf"
OVERRIDE_FILE="${REPO_DIR}/compose.override.yaml"
BIN_DIR="${HOME}/.local/bin"
RDP_WRAPPER="${BIN_DIR}/xfreerdp-flatpak"

# ---------- check if already installed ----------
if [ -d "$REPO_DIR" ] && ls "${HOME}/.local/share/applications"/winapps-*.desktop >/dev/null 2>&1; then
  echo ">> WinApps already appears to be installed (found repo and desktop entries)."
  echo ">> Skipping installation. Remove ${REPO_DIR} or desktop files if you want a clean reinstall."
  exit 0
fi

have() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  local c="$1"
  if ! have "$c"; then
    echo "ERROR: '$c' is required but not found in PATH. Please install it first." >&2
    exit 1
  fi
}

clone_repo() {
  mkdir -p "$(dirname "$REPO_DIR")"
  if [ -d "$REPO_DIR/.git" ]; then
    git -C "$REPO_DIR" fetch --depth=1 origin main
    git -C "$REPO_DIR" checkout -q main
    git -C "$REPO_DIR" pull -q --rebase
  else
    git clone --depth=1 "$REPO_URL" "$REPO_DIR"
  fi
}

setup_flatpak_freerdp_wrapper() {
  mkdir -p "$BIN_DIR"

  # Wrapper that mimics xfreerdp/wfreerdp CLI using Flatpak
  cat > "$RDP_WRAPPER" <<'EOF'
#!/usr/bin/env bash
# Invoke FreeRDP via Flatpak while preserving args.
# We grant home filesystem so /drive:home works, and allow Wayland/X11 sockets.
exec flatpak run \
  --branch=stable \
  --filesystem=home:rw \
  --socket=wayland --socket=fallback-x11 \
  --device=all \
  org.freerdp.FreeRDP \
  "$@"
EOF
  chmod +x "$RDP_WRAPPER"

  # Provide both xfreerdp and wfreerdp names so WinApps can discover either.
  ln -sf "$(basename "$RDP_WRAPPER")" "${BIN_DIR}/xfreerdp"
  ln -sf "$(basename "$RDP_WRAPPER")" "${BIN_DIR}/wfreerdp"

  # Make sure ~/.local/bin is on PATH for this session
  case ":$PATH:" in
    *":${BIN_DIR}:"*) ;;
    *) export PATH="${BIN_DIR}:${PATH}";;
  esac

  # Persist Flatpak overrides idempotently (so the app can see your home for drive redirection).
  if have flatpak; then
    flatpak override --user --filesystem=home:rw org.freerdp.FreeRDP >/dev/null 2>&1 || true
  fi
}

write_config() {
  mkdir -p "$CFG_DIR"
  if [ -f "$CFG_FILE" ]; then
    echo ">> Found existing ${CFG_FILE}; leaving as is."
    return
  fi

  cat > "$CFG_FILE" <<'EOF'
##################################
#   WINAPPS CONFIGURATION FILE   #
##################################

# --- Windows credentials (inside the WinApps VM or your own RDP host) ---
RDP_USER="lenus"
RDP_PASS="Lenus-Winapps0"
#RDP_DOMAIN="MYDOMAIN"

# --- Connection target ---
# Leave RDP_IP empty when using the WinApps containerized VM (auto-discovery).
# For an external Windows host, set its IP:
#RDP_IP="192.168.122.50"

# --- RDP behavior ---
RDP_SCALE="100"
RDP_FLAGS="/cert:tofu /sound /microphone /clipboard +home-drive"

# multi-monitor (true/false)
#MULTIMON="true"

# Extra logs
#DEBUG="true"

# --- Podman/Flatpak specific helpers ---
WAFLAVOR="podman"

# If WinApps supports an explicit RDP command override in your version, set it:
#WA_RDP_CMD="${HOME}/.local/bin/xfreerdp"
# Otherwise, our wrapper provides 'xfreerdp' in PATH so no change is needed.

# Where removable drives are mounted on Fedora (common default)
REMOVABLE_MEDIA="/run/media"

# Auto-pause Windows VM when idle (on/off)
AUTOPAUSE="on"
AUTOPAUSE_TIME="300"

# PORT CHECK
# - The maximum time (in seconds) to wait when checking if the RDP port on Windows is open.
# - Corresponding error: "NETWORK CONFIGURATION ERROR" (exit status 13).
# DEFAULT VALUE: '5'
PORT_TIMEOUT="5"

# RDP CONNECTION TEST
# - The maximum time (in seconds) to wait when testing the initial RDP connection to Windows.
# - Corresponding error: "REMOTE DESKTOP PROTOCOL FAILURE" (exit status 14).
# DEFAULT VALUE: '30'
RDP_TIMEOUT="30"

# APPLICATION SCAN
# - The maximum time (in seconds) to wait for the script that scans for installed applications on Windows to complete.
# - Corresponding error: "APPLICATION QUERY FAILURE" (exit status 15).
# DEFAULT VALUE: '60'
APP_SCAN_TIMEOUT="60"

# WINDOWS BOOT
# - The maximum time (in seconds) to wait for the Windows VM to boot if it is not running, before attempting to launch an application.
# DEFAULT VALUE: '120'
BOOT_TIMEOUT="120"
EOF

  chmod 600 "$CFG_FILE"
  echo ">> Wrote ${CFG_FILE} (edit credentials now if needed)."
}

write_compose_override() {
  cat > "$OVERRIDE_FILE" <<'YAML'
# compose.override.yaml for WinApps (Podman)
services:
  windows:
    environment:
      USERNAME: "lenus"
      PASSWORD: "Lenus-Winapps0"
    group_add:
      - keep-groups
YAML
}

bring_up_vm() {
  cd "$REPO_DIR"
  if have podman-compose; then
    podman-compose -f compose.yaml -f compose.override.yaml up -d
  else
    # Podman v4+ also supports "podman compose"
    podman compose -f compose.yaml -f compose.override.yaml up -d
  fi
}

run_winapps_setup() {
  # Runs upstream setup to generate desktop files/icons
  bash <(curl -fsSL https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)
}

next_steps() {
  cat <<'TXT'

============================================================
WinApps (Podman + Flatpak FreeRDP) bootstrap run complete.

Now:
1) If first launch, complete Windows OOBE in the VM.
2) Ensure ~/.config/winapps/winapps.conf has correct RDP_USER/RDP_PASS.
3) Re-run the setup step anytime to refresh desktop entries:
     bash <(curl -fsSL https://raw.githubusercontent.com/winapps-org/winapps/main/setup.sh)

Handy:
  podman ps --all --filter name=winapps
  podman logs winapps-windows --tail=200
  podman compose -f "${HOME}/.local/src/winapps/compose.yaml" -f "${HOME}/.local/src/winapps/compose.override.yaml" stop
  podman compose -f "${HOME}/.local/src/winapps/compose.yaml" -f "${HOME}/.local/src/winapps/compose.override.yaml" start
============================================================
TXT
}

main() {
  echo "==> Checking prerequisites..."
  require_cmd git
  require_cmd curl
  require_cmd podman
  require_cmd flatpak
  # Either podman-compose OR new 'podman compose' subcommand is fine
  if ! have podman-compose && ! podman compose version >/dev/null 2>&1; then
    echo "ERROR: Need either 'podman-compose' or 'podman compose' support." >&2
    exit 1
  fi

  echo "==> Cloning/Updating WinApps..."
  clone_repo

  echo "==> Configuring Flatpak FreeRDP wrapper..."
  setup_flatpak_freerdp_wrapper

  echo "==> Writing WinApps config..."
  write_config

  echo "==> Writing compose override..."
  write_compose_override

  echo "==> Launching Windows VM/container..."
  bring_up_vm

  echo "==> Running WinApps setup..."
  run_winapps_setup

  next_steps
}

main "$@"
