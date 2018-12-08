#!/usr/bin/env bash
# Small script to clean up NodeCore log files over 1 day old.
#
# Usage: edit crontab and insert line `@daily /path/to/nodecore_cleanup.sh`
#
# Set location of NodeCore below
#
NODECORE_DIR='/path/to/veriblock-x.x.x/nodecore-x.x.x/bin'
# Find *.log files in NodeCore dir older than 1 day and delete
#
find $NODECORE_DIR/*.log -mtime +1 -type f -delete
