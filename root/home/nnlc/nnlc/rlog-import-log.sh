#!/usr/bin/env bash
echo "Started on: $(date +'%Y-%m-%d %H:%M:%S')" > /data/logs/rlog-import_log.txt
/home/nnlc/nnlc/rlog-import.sh >> /data/logs/rlog-import_log.txt
echo "Completed on: $(date +'%Y-%m-%d %H:%M:%S')" >> /data/logs/rlog-import_log.txt