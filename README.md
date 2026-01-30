# Edge Robot Telemetry

The purpose of this tool is to simply record robot telemetry needed not reinventing the wheel with the focus on low-profile.

## Telegraf Setup

### Install Telegraf

> [link](https://docs.influxdata.com/telegraf/v1/install/)

### Without Password Prompt

```bash
sudo visudo
```

```bash
radxa ALL=(ALL) NOPASSWD: /usr/bin/telegraf
```
