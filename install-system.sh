#!/usr/bin/env bash
# Install root-owned /etc files that stow can't manage (it only symlinks, and
# NetworkManager ignores dispatcher scripts that aren't owned by root).
# These are COPIED into place — re-run after editing anything under system/.
#
# Usage:  ./install-system.sh
set -euo pipefail
cd "$(dirname "$0")"

# NetworkManager dispatcher: set the system timezone from public-IP geolocation
# on every network up / connectivity change.
sudo install -Dm755 -o root -g root \
  system/etc/NetworkManager/dispatcher.d/90-autotz \
  /etc/NetworkManager/dispatcher.d/90-autotz
echo "installed: /etc/NetworkManager/dispatcher.d/90-autotz"
