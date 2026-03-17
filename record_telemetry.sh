#!/bin/bash
# start_telemetry.sh
# Starts a Telegraf profiling session for a single drone flight.
# Each run creates a timestamped folder and updates a stable symlink
# so the Telegraf config never needs to change between flights.
#
# Usage:
#   ./start_telemetry.sh            # foreground (blocks until Ctrl+C)
#   ./start_telemetry.sh --bg       # background daemon, logs to flight dir
#   ./start_telemetry.sh --stop     # stop a running background session

set -euo pipefail

#  Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEGRAF_CONF="$SCRIPT_DIR/telegraf.conf"
LOGS_BASE="$HOME/logs"
SYMLINK="$LOGS_BASE/flight_telemetry"     # stable path used in telegraf.conf
PID_FILE="$LOGS_BASE/telegraf.pid"

#  Stop mode
if [[ "${1:-}" == "--stop" ]]; then
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "Stopping Telegraf (PID $PID)..."
            sudo kill "$PID"
            rm -f "$PID_FILE"
            echo "Done."
        else
            echo "PID $PID is not running. Removing stale PID file."
            rm -f "$PID_FILE"
        fi
    else
        echo "No PID file found at $PID_FILE — nothing to stop."
    fi
    exit 0
fi

#  Pre-flight checks
if [[ ! -f "$TELEGRAF_CONF" ]]; then
    echo "[ERROR] Config not found: $TELEGRAF_CONF"
    exit 1
fi

if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[ERROR] Telegraf already running (PID $OLD_PID). Run with --stop first."
        exit 1
    else
        rm -f "$PID_FILE"   # stale PID file
    fi
fi

#  Create per-flight folder
FLIGHT_ID=$(date +"%Y-%m-%d_%H-%M-%S")
FLIGHT_DIR="$LOGS_BASE/flight_telemetry_${FLIGHT_ID}"

mkdir -p "$FLIGHT_DIR"

# Update the stable symlink that telegraf.conf always writes to.
# Must point to $HOME/logs/flight_telemetry, not /logs/flight_telemetry.
ln -sfn "$FLIGHT_DIR" "$SYMLINK"

echo ""
echo "  Flight ID : $FLIGHT_ID"
echo "  Log dir   : $FLIGHT_DIR"
echo "  Symlink   : $SYMLINK -> $FLIGHT_DIR"
echo ""

#  Cleanup handler (foreground mode)
cleanup() {
    echo ""
    echo "Stopping Telegraf..."
    if [[ -n "${TELEGRAF_PID:-}" ]] && kill -0 "$TELEGRAF_PID" 2>/dev/null; then
        sudo kill "$TELEGRAF_PID"
        wait "$TELEGRAF_PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
    echo "Telemetry saved to: $FLIGHT_DIR"
}

#  Launch
if [[ "${1:-}" == "--bg" ]]; then
    # Background mode — detach and log telegraf stderr to flight dir
    sudo telegraf --config "$TELEGRAF_CONF" \
        >> "$FLIGHT_DIR/telegraf.log" 2>&1 &
    TELEGRAF_PID=$!
    echo "$TELEGRAF_PID" | sudo tee "$PID_FILE" > /dev/null
    echo "Telegraf running in background (PID $TELEGRAF_PID)"
    echo "  Stop with: $0 --stop"
    echo "  Log file : $FLIGHT_DIR/telegraf.log"
else
    # Foreground mode — block here, Ctrl+C triggers cleanup
    trap cleanup INT TERM EXIT
    sudo telegraf --config "$TELEGRAF_CONF" &
    TELEGRAF_PID=$!
    echo "$TELEGRAF_PID" | sudo tee "$PID_FILE" > /dev/null
    echo "Telegraf running (PID $TELEGRAF_PID) — press Ctrl+C to stop"
    wait "$TELEGRAF_PID"
fi
