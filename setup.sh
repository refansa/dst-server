#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env from .env.example. Please edit .env with your cluster token, then re-run setup.sh."
    exit 1
fi

# shellcheck disable=SC2046
export $(grep -v '^\s*#' .env | grep -v '^\s*$' | xargs)

if [ -z "${CLUSTER_TOKEN:-}" ] || [ "$CLUSTER_TOKEN" = "pds-g^XXXXXXXXX-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY=" ]; then
    echo "ERROR: CLUSTER_TOKEN is not set or still has the placeholder value."
    echo "Edit .env and set your real cluster token from https://accounts.klei.com/account/game/servers?game=DontStarveTogether"
    exit 1
fi

echo "$CLUSTER_TOKEN" > data/save/Cluster_1/cluster_token.txt
echo "✓ cluster_token.txt written"

if [ -n "${CLUSTER_NAME:-}" ]; then
    sed -i "s/^cluster_name =.*/cluster_name = $CLUSTER_NAME/" data/save/Cluster_1/cluster.ini
    echo "✓ cluster_name set to: $CLUSTER_NAME"
fi

if [ -n "${CLUSTER_PASSWORD:-}" ]; then
    sed -i "s/^cluster_password =.*/cluster_password = $CLUSTER_PASSWORD/" data/save/Cluster_1/cluster.ini
    echo "✓ cluster_password set"
fi

echo ""
echo "All done! Start the server with:"
echo "  docker compose up -d"
echo ""
echo "To update mods, first edit data/mods/dedicated_server_mods_setup.lua, then:"
echo "  docker compose --profile mod-update run --rm dst-mod-updater"
