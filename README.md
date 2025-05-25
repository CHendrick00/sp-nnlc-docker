# sp-nnlc-docker

## Features
### Automated Rlog Collection
Collecting rlogs from the comma device directly from the docker container is supported and encouraged in order to ensure they are named correctly and saved in the proper format and location for processing.

**Instructions**
- Pass the following environment variables when running the container:
  - COMMA_IP - Local IP address of the comma device. Comma should ideally have a static IP assigned in your router.
  - DEVICE_ID - Comma device or dongle ID. Find this in device settings or from your comma.ai account.
  - IMPORT_RLOGS - true. Creates SSH config to allow access to comma device. Default = disabled.
  - AUTOMATE_RLOGS - true. Sets whether a cronjob will be created for automated pulls or require manually running the collection script. Default = disabled.
  - RLOG_CRON - Allows a custom cron schedule for AUTOMATE_RLOGS. Format as '* * * * *'. Default = '00 0-23/6 * * *'
- [Add the SSH public key located under /data/config/id_ed25519.pub to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account)
  - If you don't mount /data as a volume, this value can be retrieved with:</br>
  `docker exec -it sp-nnlc-docker bash -c cat /data/config/id_ed25519.pub`
- [Enable SSH on your Comma and add your GitHub username](https://docs.comma.ai/how-to/connect-to-comma/#ssh)

If IMPORT_RLOGS and AUTOMATE_RLOGS is set:
- This container will run an automated rlog collection script which will save any new rlogs to /data/rlogs following the cron schedule supplied with RLOG_CRON or every 6 hours if RLOG_CRON is not set.

If IMPORT_RLOGS is set and AUTOMATE_RLOGS is unset:
- rlogs can be imported from comma device on-demand using docker exec:</br>
  `docker exec -it sp-nnlc-docker bash -c rlog-import`

### NNLC Model Generation
- Only CPU training is currently tested.
- Run the rlog processing and model generation script using docker exec:</br>
  `docker exec -it sp-nnlc-docker bash -c nnlc-process`
  - After processing steps 1 and 2 have completed, you will be presented with a prompt before proceeding with model generation. Before continuing, it's a good idea to view the generated graphs to determine if enough data points are present and all speeds and lateral acceleration bands are well-represented.
- Key output files:
  - VEHICLE_NAME_torque_adjusted_eps.json - NNLC model file
  - Graphs:
    - plots_torque/*.png
    - $VEHICLE lat_accel_vs_torque.png
    - VEHICLE_NAME_torque_adjusted_eps/*.png

## Data Volume Filetree
See below for a description of the basic file tree, where different files are located, what files you should expect to see after running the processing script, and which of these files are important.
```
/
├── data/ (VOLUME)
│   ├── config/     (persistent SSH keys)
│   │   ├── ... 
│   ├── logs/       (script output logs)
│   │   ├── rlog-import_cron.txt
│   ├── output/
│   │   ├── $VEHICLE/
│   │   │   ├── plots_torque/ (Fit data plots - Processing Step 1)
│   │   │   ├── plots_torque-/ (Fit data plots from previous run)
│   │   │   ├── rlogs/
│   │   │   │   ├── $DEVICE_ID/
│   │   │   │   │   ├── ... (rlogs copied from /data/rlogs and updated for processing)
│   │   │   ├── VEHICLE_NAME_steer_cmd/ (Model generation output)
│   │   │   │   ├── ... 
│   │   │   ├── VEHICLE_NAME_torque_adjusted_eps/ (Model generation output - graphs and model file)
│   │   │   │   ├── VEHICLE_NAME_torque_adjusted_eps.json (Model file to be copied to comma)
│   │   │   ├── *.csv (Processing files - Processing Step 2)
│   │   │   ├── *.feather (Feather files - Processing Step 2)
│   │   │   ├── *.lat (Lat files - Processing Step 1)
│   │   │   ├── $VEHICLE lat_accel_vs_torque.png (Graph showing data points covered - Processing Step 2)
│   ├── rlogs/
│   │   ├── $VEHICLE/
│   │   │   ├── $DEVICE_ID/
│   │   │   │   ├── ... (rlogs downloaded using rlog_collect.sh)
```

## GPU Support
### AMD
- Install required host packages following [ROCm Docker Prerequisites](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/docker.html#prerequisites)
### NVIDIA
- **Linux**
  - Install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host
- **Windows**
  - Support is included with Docker Desktop using WSL 2
  - [Documentation](https://docs.docker.com/desktop/features/gpu/)

## Testing Model Files
### Testing Models
After generating a model, the following steps must be performed to test on your vehicle. **BE CAREFUL** - any models you generate are entirely experimental and are in no way guaranteed to be safe. It's always best to ask for feedback on your model in the sunnypilot discord first before proceeding with testing.

**When testing, always be prepared to take control at any time!!!**
1. SSH to the comma device. If you don't have this set up on the host, you can do so from the container with:</br>
`docker exec -it sp-nnlc-docker bash -c ssh comma`
2. Disable updates on the comma device to prevent the data directory from being overwritten.
`echo -en "1" > /data/params/d/DisableUpdates`
3. Reboot the comma device.
4. Determine the file name that will be required by finding your vehicle in [opendbc](https://github.com/sunnypilot/opendbc/blob/master-new/opendbc/car). The name will be under your make's directory in the file `fingerprints.py`, and should look like `HYUNDAI_IONIQ_6`.
5. `cd /data/openpilot/sunnypilot/neural_network_data/neural_network_lateral_control && ls -l`
6. If a model already exists with your car's name, rename the file as a backup with `mv VEHICLE_NAME.json VEHICLE_NAME.bk`
7. Copy the contents of your VEHICLE_NAME_torque_adjusted_eps.json file to this directory using `nano VEHICLE_NAME.json` (safer) or with `echo "FILE_CONTENTS" > VEHICLE_NAME.json`
8. **IMPORTANT**: Check to make sure the contents of the new file appear to match VEHICLE_NAME_torque_adjusted_eps.json with `cat VEHICLE_NAME.json` or `nano VEHICLE_NAME.json`
9. Reboot your comma device again, then restart your vehicle once to ensure the NNLC model has been reloaded.
10. Ensure NNLC shows Exact Match for the correct vehicle.

### Reverting Testing Changes:

**Method 1**
1. Re-enable updates with `echo -en "0" > /data/params/d/DisableUpdates`
2. Reboot the comma device
3. Install any updates - this will overwrite your changes in the data directory.

**Method 2**
1. Delete your model with `cd /data/openpilot/sunnypilot/neural_network_data/neural_network_lateral_control && rm VEHICLE_NAME.json`
2. If you backed up an existing model, revert the name change with `mv VEHICLE_NAME.bk VEHICLE_NAME.json`

## Credits
TODO

## TODO
- logging
- documentation and usage instructions
- docker compose example(s)
- finish filetree example (outputs)
- gpu support host instructions
- credits
- script to push output model to comma?
- test processing script
- add scripts to PATH (or at least root-level symlinks)