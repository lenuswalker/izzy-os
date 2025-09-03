#!/usr/bin/env bash
set -euo pipefail

# Name of the toolbox
TB_NAME="evdi-build"

echo "📦 Creating toolbox: $TB_NAME"
toolbox create "$TB_NAME" --assumeyes || true

echo "🚪 Entering toolbox..."
toolbox run --container "$TB_NAME" bash -c "
  set -euo pipefail

  log() { printf '\033[1;36m==>\033[0m %s\n' '$*'; }
  warn() { printf '\033[1;33m[!]\033[0m %s\n' '$*'; }

  echo '🔧 Installing build dependencies...'
  KVER=$(uname -r)
  sudo dnf install -y \
    @development-tools \
    kernel-devel-"$KVER" \
    mokutil openssl kmodtool akmods dkms \
    python3-devel pybind11 --skip-unavailable

  echo '📦 Adding negativo17 repo...'
  sudo dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo --overwrite

  echo '📦 Installing DisplayLink package...'
  sudo dnf install -y displaylink

  echo '📥 Cloning EVDI source...'
  git clone https://github.com/DisplayLink/evdi.git /tmp/evdi

  echo '🛠 Building EVDI kernel module...'
  cd /tmp/evdi
  make

  echo '📂 Installing EVDI module into /lib/modules...'
  sudo make install

  cd -
  rm -rf /tmp/evdi

  echo '🔑 Generating Secure Boot keys...'
  SB_KEY_DIR='$HOME/sb-signing'
  mkdir -p '$SB_KEY_DIR'
  if [ ! -f '$SB_KEY_DIR/mok.key' ]; then
    log 'Generating Secure Boot signing key...'
    openssl req -new -x509 -newkey rsa:2048 -keyout '$SB_KEY_DIR/mok.key' \
      -outform DER -out '$SB_KEY_DIR/mok.der' -nodes -days 36500 \
      -subj '/CN=EVDI Secure Boot/'
  fi

  echo 'Signing EVDI module...'
  MOD_PATH=$(modinfo -n evdi || true)
  if [ -n '$MOD_PATH' ] && [ -f '$MOD_PATH' ]; then
    log 'Signing EVDI module at $MOD_PATH...'
    sudo /usr/src/kernels/"$KVER"/scripts/sign-file sha256 \
      '$SB_KEY_DIR/mok.key' '$SB_KEY_DIR/mok.der' '$MOD_PATH'
  else
    warn '⚠️ EVDI module not found; you may need to load it first with: sudo modprobe evdi'
  fi

  warn '⚠️ To complete Secure Boot setup, run this on the HOST (not in toolbox):'
  echo '  sudo mokutil --import $SB_KEY_DIR/mok.der'
  echo 'Then reboot, select "Enroll MOK", and confirm with your password.'

  echo '✅ Build complete. You can now load the module with:'
  echo '    sudo modprobe evdi'
"

echo "💡 Tip: You may need to rebuild after a kernel update."

echo "🚪 Exiting toolbox..."
toolbox exit
