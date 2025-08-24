#!/usr/bin/env bash
set -euo pipefail

# Name of the toolbox
TB_NAME="evdi-build"

echo "📦 Creating toolbox: $TB_NAME"
toolbox create "$TB_NAME" || true

echo "🚪 Entering toolbox..."
toolbox run --container "$TB_NAME" bash -c "
  set -euo pipefail

  echo '🔧 Installing build dependencies...'
  sudo dnf install -y git make automake gcc kernel-devel

  echo '📥 Cloning EVDI source...'
  git clone https://github.com/DisplayLink/evdi.git /tmp/evdi

  echo '🛠 Building EVDI kernel module...'
  cd /tmp/evdi/module
  make

  echo '📂 Installing EVDI module into /lib/modules...'
  sudo make install

  echo '✅ Build complete. You can now load the module with:'
  echo '    sudo modprobe evdi'

  echo '🔧 Install DisplayLink driver with:'
  echo '    sudo rpm-ostree install displaylink'
"

echo "💡 Tip: You may need to rebuild after a kernel update."

echo "🚪 Exiting toolbox..."
toolbox exit