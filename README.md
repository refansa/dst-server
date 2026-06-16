# Don't Starve Together — Dedicated Server (Docker)

A production-ready **Don't Starve Together** dedicated server with **Overworld + Caves** shards, running in Docker. Built on [`superjump22/dontstarvetogether`](https://hub.docker.com/r/superjump22/dontstarvetogether) — an image that auto-updates every 30 minutes so your server always has the latest DST build.

## Features

- **Two-shard setup** — Master (Overworld) and Caves in separate containers
- **Auto-updating** — game binary refreshed every 30 minutes via the upstream image
- **Health-checked** — Caves waits for Master to be fully initialized before connecting
- **Mod support** — update mods with a single command, no container rebuild needed
- **Windows + Linux** — setup scripts for PowerShell (`setup.ps1`) and bash (`setup.sh`)
- **Config templates** — ready-to-use `cluster.ini`, `server.ini`, `worldgenoverride.lua` included

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) v24+ with Docker Compose v2+
- A [Klei cluster token](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)
- UDP ports reachable from the internet (see [Port Reference](#port-reference))

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/refansa/dst-server.git
cd dst-server

# 2. Configure
cp .env.example .env
# → Edit .env: paste your Klei token, set server name & password

# 3. Apply config (PowerShell)
.\setup.ps1
#    OR (bash)
# bash setup.sh

# 4. Start the server
docker compose up -d
```

Your server will appear in the in-game server browser under **Browse Games → Server** within 1–2 minutes.

## Project Structure

```
dst-server/
├── .env.example            # Environment variable template
├── docker-compose.yml      # Master + Caves + mod updater services
├── setup.ps1               # PowerShell setup (Windows)
├── setup.sh                # Bash setup (Linux/macOS)
├── scripts/
│   └── update-mods.sh      # Mod update helper
├── data/
│   ├── mods/               # V1 mod files
│   │   ├── dedicated_server_mods_setup.lua   # Add Workshop IDs here
│   │   └── modsettings.lua
│   ├── ugc_mods/           # V2 mods (Docker volume, auto-managed)
│   └── save/Cluster_1/     # Cluster configuration
│       ├── cluster.ini
│       ├── adminlist.txt
│       ├── whitelist.txt
│       ├── blocklist.txt
│       ├── modoverrides.lua
│       ├── Master/
│       │   ├── server.ini
│       │   └── worldgenoverride.lua
│       └── Caves/
│           ├── server.ini
│           └── worldgenoverride.lua
```

## Commands

### Server lifecycle

```bash
# Start
docker compose up -d

# View logs
docker compose logs -f
docker compose logs -f dst-master
docker compose logs -f dst-caves

# Stop (saves world gracefully)
docker compose stop

# Restart (after config changes)
docker compose restart

# Full teardown
docker compose down
```

### Adding mods

```bash
# 1. Add Workshop IDs to data/mods/dedicated_server_mods_setup.lua
#    ServerModSetup("378160973")   # Global Positions

# 2. Download mods
docker compose --profile mod-update run --rm dst-mod-updater

# 3. Enable mods in data/save/Cluster_1/modoverrides.lua

# 4. Restart
docker compose restart
```

### Granting admin

1. Ask the player to type `!klist` in chat (or `/klist`)
2. Add their `KU_` ID to `data/save/Cluster_1/adminlist.txt`
3. Restart: `docker compose restart`

Admin commands in-game: `c_godmode()`, `c_give("meat", 10)`, `c_save()`, `c_shutdown()`

## Port Reference

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| `10999` | UDP | Master | Player connections (Overworld) |
| `11000` | UDP | Caves | Player connections (Caves) |
| `10888` | UDP | Internal | Inter-shard communication |
| `27016` | UDP | Master | Steam master server |
| `27017` | UDP | Caves | Steam master server |
| `8766` | UDP | Master | Steam authentication |
| `8767` | UDP | Caves | Steam authentication |

Port `10888` is internal between containers — do not expose it on your firewall.

## Configuration Reference

### `cluster.ini`

| Setting | Default | Notes |
|---------|---------|-------|
| `game_mode` | `endless` | `survival`, `endless`, or `wilderness` |
| `max_players` | `16` | 1–64 |
| `pause_when_empty` | `true` | Freezes simulation when no one is online |
| `tick_rate` | `15` | 15–60. Higher = smoother but more CPU |
| `cluster_intention` | `cooperative` | `cooperative`, `competitive`, `social`, `madness` |

### `worldgenoverride.lua`

Controls world generation. The Override file applies on first start or after the `save/` directory is deleted (`c_regenerateworld()` also works).

For a full list of override options, see the [Klei forums](https://forums.kleientertainment.com/forums/topic/900508-worldgenoverridelua-documentation/).

## Changing World Settings

The `worldgenoverride.lua` file only takes effect when a **new world** is generated. To regenerate:

```bash
docker compose down
# Delete world saves
Remove-Item -Recurse -Force data/save/Cluster_1/Master/save -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force data/save/Cluster_1/Caves/save -ErrorAction SilentlyContinue
# Edit worldgenoverride.lua files now, then:
docker compose up -d
```

**Warning:** This destroys the existing world and all player progress.

## Updating

The game binary updates automatically — the upstream image rebuilds every 30 minutes. To pick up the latest version:

```bash
docker compose pull
docker compose up -d
```

## Credits

- **[superjump22/dontstarvetogether](https://github.com/superjump22/dontstarve-server-docker)** — the underlying Docker image with 30-minute auto-update cadence
- **Klei Entertainment** — for Don't Starve Together and the free dedicated server binary

## License

MIT
