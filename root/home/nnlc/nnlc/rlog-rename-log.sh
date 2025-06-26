#!/usr/bin/env bash
echo "Started on: $(date +'%Y-%m-%d %H:%M:%S')" | tee /data/logs/rlog-rename_log.txt
/home/nnlc/nnlc/rlog-rename.sh | tee -a /data/logs/rlog-rename_log.txt
echo "Completed on: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a /data/logs/rlog-rename_log.txt