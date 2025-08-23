#!/usr/bin/env bash
set -euo pipefail

# Name of the toolbox
TB_NAME="evdi-build"

echo "📦 Creating toolbox: $TB_NAME"
/usr/bin/toolbox create "$TB_NAME" || true

echo "🚪 Entering toolbox..."
/usr/bin/toolbox run --container "$TB_NAME" bash -c "
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
"

echo "💡 Tip: You may need to rebuild after a kernel update."

echo "🚪 Exiting toolbox..."
/usr/bin/toolbox exit

sudo modprobe evdi

modinfo evdi