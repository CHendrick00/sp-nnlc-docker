#!/usr/bin/env bash
echo "Started on: $(date +'%Y-%m-%d %H:%M:%S')" | tee /data/logs/nnlc-review_log.txt
/home/nnlc/nnlc/nnlc-review.sh | tee -a /data/logs/nnlc-review_log.txt
echo "Completed on: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a /data/logs/nnlc-review_log.txt