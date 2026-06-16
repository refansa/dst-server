#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "Updating mods via superjump22/dontstarvetogether..."
echo "Make sure data/mods/dedicated_server_mods_setup.lua has your mod IDs."

docker compose --profile mod-update run --rm dst-mod-updater

echo ""
echo "Mod update complete. Restart the server to apply changes:"
echo "  docker compose restart"
