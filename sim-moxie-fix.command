#!/bin/bash
# sim-moxie-fix.command — macOS version of sim-moxie-fix.bat
# Rebuilds the OpenMoxie broker (mqtt) so the browser door (port 9001)
# is baked in, then prints the config inside the running broker so you
# can check for "listener 9001".

export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

pause_end() {
    echo
    read -r -p "Press Enter to close this window..." _
}

# --- Docker must exist and be running -------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker was not found. Install Docker Desktop for Mac first, then run this again."
    pause_end
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker doesn't seem to be running. Open Docker Desktop, wait until it"
    echo "says it is running, then run this file again."
    pause_end
    exit 1
fi

# --- Find the folder that holds docker-compose.yml -------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CANDIDATES=(
    "$SCRIPT_DIR"
    "$HOME"
    "$HOME/openmoxie-main"
    "$HOME/openmoxie-main/openmoxie-main"
    "$HOME/Downloads/openmoxie-main"
    "$HOME/Downloads/openmoxie-main/openmoxie-main"
    "$HOME/Downloads"
    "$HOME/Desktop/openmoxie-main"
    "$HOME/Desktop/openmoxie-main/openmoxie-main"
)

PROJECT_DIR=""
for d in "${CANDIDATES[@]}"; do
    if [ -f "$d/docker-compose.yml" ]; then
        PROJECT_DIR="$d"
        break
    fi
done

if [ -z "$PROJECT_DIR" ]; then
    FOUND="$(find "$HOME" -maxdepth 5 -name docker-compose.yml -path '*openmoxie*' 2>/dev/null | head -n 1)"
    if [ -n "$FOUND" ]; then
        PROJECT_DIR="$(dirname "$FOUND")"
    fi
fi

if [ -z "$PROJECT_DIR" ]; then
    echo "I couldn't find your OpenMoxie folder (no docker-compose.yml found)."
    echo "Put this file in the same folder as docker-compose.yml and run it again,"
    echo "or tell Muse where the folder is."
    pause_end
    exit 1
fi

cd "$PROJECT_DIR" || exit 1
echo "Using OpenMoxie folder: $PROJECT_DIR"
echo

# --- Pick the compose command ----------------------------------------------
if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
else
    echo "Docker Compose was not found. Update Docker Desktop, then run this again."
    pause_end
    exit 1
fi

# --- Rebuild the broker (same as the .bat) ----------------------------------
echo "Rebuilding the broker with the browser door (port 9001)..."
"${COMPOSE[@]}" up -d --build mqtt

echo
echo "--- Config inside the running broker ---"
docker exec openmoxie-mqtt cat /mosquitto/config/mosquitto.conf

echo
if docker exec openmoxie-mqtt grep -q "listener 9001" /mosquitto/config/mosquitto.conf 2>/dev/null; then
    echo "listener 9001 is in there — the browser door is open."
else
    echo "I can't see \"listener 9001\" in that config — the door is not baked in yet."
fi
echo "If you can see \"listener 9001\" above, open the sim page and tap Connect."
pause_end
