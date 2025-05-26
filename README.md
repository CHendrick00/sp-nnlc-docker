# sp-nnlc-docker

## Features
### Automated Rlog Collection
Importing rlogs from the comma device directly from the docker container is supported and encouraged in order to ensure they are named correctly and saved in the proper format and location for processing.

**Instructions**
- Reference the [Environment Variables](#environment-variables) section for the following variables to pass when creating the container:
  - COMMA_IP
  - DEVICE_ID
  - ENABLE_RLOGS_IMPORTER
  - ENABLE_RLOGS_SCHEDULER
  - RLOGS_SCHEDULE
- [Add the SSH public key located under /data/config/id_ed25519.pub to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account)
  - If you don't mount /data as a volume, this value can be retrieved with:</br>
  `docker exec -it sp-nnlc-docker bash -c cat /data/config/id_ed25519.pub`
- [Enable SSH on your Comma and add your GitHub username](https://docs.comma.ai/how-to/connect-to-comma/#ssh)

If ENABLE_RLOGS_IMPORTER and ENABLE_RLOGS_SCHEDULER is set:
- This container will run an automated rlog collection script which will save any new rlogs to /data/rlogs following the cron schedule supplied with RLOGS_SCHEDULE or every 6 hours if RLOGS_SCHEDULE is not set.

If ENABLE_RLOGS_IMPORTER is set and ENABLE_RLOGS_SCHEDULER is unset:
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

## Installation and Usage
### Windows

1. Enable virtualization in BIOS. Refer to your motherboard's documentation for where this setting is located. Typically this is named 'VT-x' or 'SVM' and located under CPU Configuration or similar.
2. From PowerShell, install [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install):</br>`wsl --install`
3. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) with WSL 2 backend.
4. If using a GPU, following the instructions in [GPU Support](#gpu-support)
4. Download the provided docker-compose-windows.yml file for Windows
5. Update environment variables for your vehicle and comma device ID
6. Create the container with:</br>`docker compose -f C:\PATH-TO\docker-compose-windows.yml up -d`
  - This automatically creates the required 'data' volume accessible from the following path:</br>
  `\\wsl.localhost\docker-desktop\mnt\docker-desktop-disk\data\docker\volumes\data`
5. Docker Exec commands can be run directly in Docker Desktop: `Containers > sp-nnlc-docker > Exec`

### Linux - Debian/Ubuntu
1. TODO

## [GPU Support](#gpu-support)
Some packages may need to be installed on the host system in order to use the GPU for model processing inside the container. First, ensure you have updated drivers for your GPU installed on the host. Following that, see below:

### NVIDIA
- **Linux**
  - Install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host
- **Windows**
  - Support should be included with Docker Desktop using WSL 2
    - [Documentation](https://docs.docker.com/desktop/features/gpu/)

## Testing Models
### Testing Instructions
After generating a model, the following steps must be performed to test on your vehicle. **BE CAREFUL** - any models you generate are entirely experimental and are in no way guaranteed to be safe. I would recommend asking for feedback on your model's lat_accel_vs_torque.png in the sunnypilot discord first before proceeding with testing.

**When testing, always be prepared to take control at any time!!!**
1. SSH to the comma device, and run all following steps from this SSH session. If you don't have SSH to the comma set up on the host, you can do so from the container with:</br>
`docker exec -it sp-nnlc-docker bash -c ssh comma`
2. Disable updates on the comma device to prevent the data directory from being overwritten.</br>
`echo -en "1" > /data/params/d/DisableUpdates`
3. Reboot the comma device.</br>
`sudo reboot now`
4. Wait 1-2 minutes, then open another SSH session by repeating Step 1.
5. Determine the file name that will be required by finding your vehicle in [opendbc](https://github.com/sunnypilot/opendbc/blob/master-new/opendbc/car). The name will be under your make's directory in the file `fingerprints.py`, and should look like `HYUNDAI_IONIQ_6`. This should also match the vehicle name on the output JSON model's original filename. In the following steps this will be referred to as VEHICLE_NAME.
6. List existing model files with:</br>
`cd /data/openpilot/sunnypilot/neural_network_data/neural_network_lateral_control && ls -l`
7. If a model already exists with your car's name, rename the file to back it up with `mv VEHICLE_NAME.json VEHICLE_NAME.bk`
8. Copy the contents of your VEHICLE_NAME_torque_adjusted_eps.json file to this directory using `nano VEHICLE_NAME.json` (safer) or with `echo "(paste file contents inside the quotes)" > VEHICLE_NAME.json`
9. **IMPORTANT**: Check to make sure the contents of the new file appear to match VEHICLE_NAME_torque_adjusted_eps.json with `cat VEHICLE_NAME.json` or `nano VEHICLE_NAME.json`
10. Reboot your comma device again, then start/stop your vehicle once to ensure the NNLC model has been reloaded.
11. Ensure NNLC shows Exact Match for the expected vehicle.

### Reverting Testing Changes:
**Method 1**
1. SSH to the comma device:</br>
`docker exec -it sp-nnlc-docker bash -c ssh comma`
2. Re-enable updates with:</br>
`echo -en "0" > /data/params/d/DisableUpdates`
3. Reboot the comma device.</br>
`sudo reboot now`
4. Install any pending updates - this will overwrite all changes in the data directory.

**Method 2**
1. Delete your model with:</br>
`cd /data/openpilot/sunnypilot/neural_network_data/neural_network_lateral_control && rm VEHICLE_NAME.json`
2. If you backed up an existing model, revert the name change with:</br>
`mv VEHICLE_NAME.bk VEHICLE_NAME.json`

## [Environment Variables](#environment-variables)
| Variable Name          | Description                                                      | Example Value       | Default Value  | Allowed Values                                                        | Required                      | Notes                                                                                                                                       |
|------------------------|------------------------------------------------------------------|---------------------|----------------|-----------------------------------------------------------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| COMMA_IP               | Local IP of the comma device                                     | 192.168.1.100       | -              | -                                                                     | If ENABLE_RLOGS_IMPORTER=true | Highly recommended to assign the comma a static IP in your router to prevent this value from changing                                       |
| DEVICE_ID              | Comma device's dongle ID                                         | 3d264cee10fdc8d3    | -              | -                                                                     | Yes                           | Can be found in comma device settings or your Comma Connect account                                                                         |
| ENABLE_RLOGS_IMPORTER  | Enables importing of rlogs from comma device                     | true                | false          | true, false                                                           | No, but recommended           | Creates the SSH config to the comma device - the container can't be used to upload a model without this enabled                             |
| ENABLE_RLOGS_SCHEDULER | Enables rlog import script to be automatically run on a schedule | true                | false          | true, false                                                           | No                            | Requires the container to be left running continuously                                                                                      |
| RLOGS_SCHEDULE         | Allows a custom schedule for ENABLE_RLOGS_SCHEDULER              | 0 0 * * *           | 0 0-23/6 * * * | See https://crontab.guru/                                             | No                            | Highly advise against setting the minute (first) value to anything other than 0 to avoid triggering concurrent runs or unexpected behavior. |
| VEHICLE                | Name of vehicle to use when naming directories                   | ioniq6              | -              | -                                                                     | Yes                           | Does not have to match vehicle name in opendbc. Do NOT include any spaces or special characters in this value.                              |
| TZ                     | Timezone used by the container                                   | America/Los_Angeles | UTC            | See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List | No, but recommended           | Useful to set with ENABLE_RLOGS_SCHEDULER in order for the scheduled runs to happen at the expected time                                    |

## Data Volume Filetree
See below for a diagram of the data volume directory structure, where certain files are located, what files you should expect to see after running the processing script, and which of these files are important.
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

## Untested Functionality
- Nvidia GPU on Windows host
- Angle steering vehicles

## Credits
TODO

## TODO
- logging
- documentation and usage instructions
- docker compose example(s)
- gpu support host instructions
- credits
- script to push output model to comma?