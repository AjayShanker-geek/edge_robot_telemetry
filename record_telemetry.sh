#!/bin/bash

FLIGHT_ID=$(date +"%Y-%m-%d_%H-%M-%S")
FLIGHT_DIR="$HOME/logs/flight_telemetry_${FLIGHT_ID}"

mkdir -p "$FLIGHT_DIR"
# Create syslink
ln -sfn "$FLIGHT_DIR" /logs/flight_telemetry

echo "Flight folder: $FLIGHT_DIR"
echo "Symlink ~/logs/flight_telemetry -> $FLIGHT_DIR"

sudo telegraf --config ./telegraf.conf

