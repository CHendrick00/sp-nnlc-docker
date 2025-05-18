# sp-nnlc-docker

## Features
### Automated rlog collection
To enable:
- Pass the following environment variables when running the container:
  - COMMA_IP  // LAN IP address of the comma device. Comma should have a static IP assigned in your router.
  - DEVICE_ID  // Comma device or dongle ID. Find this in device settings or from your comma.ai account.
  - AUTOMATE_RLOGS // true or false. Sets whether a cronjob will be created for automated pulls or require manually running the collection script.
  - COLLECT_RLOGS = true
- [Add the SSH public key located under /input/comma.pub to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account)
- [Enable SSH on your Comma and add your GitHub username](https://docs.comma.ai/how-to/connect-to-comma/#ssh)

This will run an automated rlog collection script which will save any new rlogs to the volume you mount under /inputs/rlogs every 6 hours. Custom schedules are not currently supported.
**ADD manual exec instructions**

### rlog processing
- AMD and Nvidia GPUs are supported for model generation. See environment variable 'GPU'.

### Filetree Explanation
/
|- /input (mounted volume)
|--- /$VEHICLE
|----- /$DEVICE_ID (contains rlogs downloaded using rlog_collect.sh)
|- /output (mounted volume)
|--- /$VEHICLE (nnlc processing output here)
|- /home
|--- /nnlc
|----- rlog_collect.sh (collects rlogs from comma over SSH)
|----- /Downloads
|------- /rlogs (automnatically created rlog processing directory)
|----- /nnlc (automatically created directory containing processing tools)
|------- process.sh
|------- ...



### todo
- override $HOME,GENESIS
  - own sunnpypilot fork?
- logging?
- documentation and usage instructions
- gpu support
- docker compose example
- run setup as correct users
- copy output to output volume
- finish filetree example
- gpu support instructions
