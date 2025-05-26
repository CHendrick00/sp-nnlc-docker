#!/usr/bin/env bash
echo "Started on: $(date +'%Y-%m-%d %H:%M:%S')" > /data/logs/nnlc-process_log.txt
/home/nnlc/nnlc/nnlc-process.sh >> /data/logs/nnlc-process_log.txt
echo "Completed on: $(date +'%Y-%m-%d %H:%M:%S')" >> /data/logs/nnlc-process_log.txt