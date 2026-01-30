#!/bin/bash

FLIGHT_ID=$(date +"%Y-%m-%d_%H-%M-%S")
FLIGHT_DIR="/logs/flight_telemetry_${FLIGHT_ID}"

mkdir -p "$FLIGHT_DIR"
# Create syslink
ln -sfn "$FLIGHT_DIR" /logs/flight_telemetry

sudo telegraf --config /etc/telegraf/telegraf.conf
