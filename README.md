# sp-nnlc-docker

## Quickstart Guide
1. Follow the [installation instructions](#installation) for your host OS to install docker and create the nnlc docker container.
2. Import rlogs by running `rlog-import` on the container OR copy existing rlogs with the correct naming scheme to `/data/rlogs` OR copy the comma's `/data/media/0/realdata` directory to `/data/rlogs` and run `rlog-rename` on the container.
3. Generate the model by running `nnlc-process` on the container.
4. Follow the instructions in [Testing Models](#testing-models) to upload your generated model to your comma device for testing.

## Features and Usage

### Automated Rlog Collection
Importing rlogs from the comma device directly from the docker container is not only supported but also encouraged in order to ensure the files are named correctly and saved in the proper format and location for processing.

**Instructions**
1. Reference the [Environment Variables](#environment-variables) section for the following variables to pass when creating the container:
    - COMMA_IP
    - DEVICE_ID
    - ENABLE_RLOGS_IMPORTER
    - ENABLE_RLOGS_SCHEDULER
    - RLOGS_SCHEDULE
2. [Add the SSH public key located under /data/config/id_ed25519.pub to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#adding-a-new-ssh-key-to-your-account)
    - This value can be retrieved with:</br>
  `docker exec -t nnlc bash -c "cat /data/config/id_ed25519.pub"`
3. [Enable SSH on your Comma and add your GitHub username](https://docs.comma.ai/how-to/connect-to-comma/#ssh)
    - Note: if you already have SSH set up on your comma, remove and readd your Github username to load the new SSH key.
4. Rlogs can be manually imported by running the following:</br>
`docker exec -t nnlc bash -c rlog-import`
5. If the scheduled rlog importer is enabled and the container is left running, rlogs will be imported automatically every 6 hours or following the schedule provided with RLOGS_SCHEDULE.

### NNLC Model Generation
The container includes all required tools and packages to process rlogs into an NNLC model.

**Instructions**
1. Ensure rlog.zst files are present under `/data/rlogs/$VEHICLE/$DEVICE_ID` and named according to the required format: `[DEVICE_ID]_[ROUTE]--rlog.zst`
2. Run the rlog processing and model generation script using docker exec:</br>
  `docker exec -it nnlc bash -c nnlc-process`
3. After processing steps 1 and 2 have completed, you will be presented with a prompt before proceeding with model generation. Before continuing, it's a good idea to view the generated graphs to determine if enough data points are present and all speeds and lateral acceleration bands are well-represented.
    - `plots_torque/*.png`
    - `$VEHICLE lat_accel_vs_torque.png`
4. During the model generation step, make sure you see the expected device being used in the output: `using device: gpu`
    - If you see `using device: cpu`, abort the training as the resulting model will not work correctly. A check is in place to prevent this in most situations, however all edge cases may not be tested.
5. After model generation completes, review the following outputs:
    - `VEHICLE_NAME_torque_adjusted_eps.json` - NNLC model file
    - `VEHICLE_NAME_torque_adjusted_eps/*.png`
6. Exit the container's shell with `exit`

**Notes:**
- The first run of the model training step will need to precompile a small number of Julia packages based on your host system, which may cause this run to take a few extra minutes. This should generally be a one-time thing, but may be triggered again after updating GPU drivers on the host system.

### Renaming Existing Rlogs
In the event you have rlogs copied directly from the comma device with the original directory structure and naming scheme, you can still use these by renaming them to the required format with the included script.

**Instructions**
1. From the host, copy the existing logs to the data volume mount location under `/data/rlogs/$VEHICLE/$DEVICE_ID/data/media/0/realdata`
2. Run the rlog renaming script using docker exec:</br>
  `docker exec -t nnlc bash -c rlog-rename`
3. See the renamed files under `/data/rlogs/$VEHICLE/$DEVICE_ID`
4. Optional. Delete the files under `/data/rlogs/$VEHICLE/$DEVICE_ID/data/media/0/realdata`

## Installation

### Windows
1. Enable virtualization in BIOS. Refer to your motherboard's documentation for where this setting is located. Typically this is named 'VT-x' or 'SVM' and located under CPU Configuration or similar.
2. From PowerShell, install [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install):</br>`wsl --install`
3. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) with WSL 2 backend.
4. Follow the instructions in [GPU Support](#gpu-support).
5. Download the provided docker-compose-windows.yml file.
6. Update environment variables for your vehicle and comma device ID. See [Environment Variables](#environment-variables).
7. Create the container (example):</br>`docker compose -f C:\PATH-TO\docker-compose-windows.yml up -d`
    - This will create the **data** volume accessible from the following path:</br>
  `\\wsl.localhost\docker-desktop\mnt\docker-desktop-disk\data\docker\volumes\nnlc_data\_data`

**Notes**: 
- Docker Exec commands can be run directly in the Docker Desktop GUI if desired: `Containers > nnlc > Exec`
  - `docker exec -it nnlc bash -c` should be removed from supplied commands when running directly in the container.
- Creating a bind mount from an existing Windows path to the data volume is difficult due to permissions, so the provided docker compose file creates a volume in the WSL filesystem. You can still view and operate on these files as normal with File Explorer using the path provided above.

### Linux - Debian/Ubuntu
1. Install [Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository).
2. Follow the instructions in [GPU Support](#gpu-support).
3. Download the provided docker-compose-linux.yml file.
4. Update environment variables for your vehicle and comma device ID. See [Environment Variables](#environment-variables).
5. Create a mountpoint for the data volume. If using the default path: `sudo mkdir /opt/nnlc`.
6. Update the data mountpoint's owner to the container user: `sudo chown -R 1234:1234 /opt/nnlc`
5. Create the container (example):</br>`docker compose -f /PATH-TO/docker-compose-linux.yml up -d`
    - This will create the **data** volume as a bind mount accessible under `/opt/nnlc` - see note below.

**Notes**: 
- Bind mounts are easier to permission to work with Docker on Linux, so this is the default on the docker-compose-linux.yml example.
- You can create the volume as a normal Docker volume if you wish, but be aware that the path is created under the main Docker data directory which is owned by root and is not visible to rootless users without running `chown` on the volume directory. If you choose to use this anyway, you can find the volume under `cd /var/lib/docker/volumes/nnlc_data/_data`.

### Others
- Other host operating systems are untested and may or may not work out-of-box.


## GPU Support
Some packages may need to be installed on the host system in order to use the GPU for model processing inside the container. First, ensure you have updated drivers for your GPU installed on the host. Afterwards, see below:

### NVIDIA

- **Linux**
  1. Install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host.
  2. Restart the docker daemon with `sudo systemctl restart docker`

- **Windows**
  1. Untested, but support should already be included with Docker Desktop using WSL 2. See [Docker GPU Support Documentation](https://docs.docker.com/desktop/features/gpu/).

### Other
- Other GPU types are not currently supported by the training scripts due to CUDA requirement.
- CPU training is not supported as this functionality is not working correctly in the training scripts and results in a broken model.


## Testing Models
### Testing Instructions
After generating a model, the following steps must be performed to test on your vehicle. **BE CAREFUL** - any models you generate are entirely experimental and are in no way guaranteed to be safe. I would recommend asking for feedback on your model's `lat_accel_vs_torque.png` in the sunnypilot discord first before proceeding with testing.

**When testing, always be prepared to take control at any time!!!**
1. SSH to the comma device, and run all following steps from this SSH session. If you don't have SSH to the comma set up on the host, you can do so from the container with:</br>
`docker exec -it nnlc bash -c ssh comma`
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
10. Reboot your comma device again, repeating Step 3
11. Exit the container's shell with `exit`
12. Start/stop your vehicle once to ensure the NNLC model has been reloaded.
13. Ensure NNLC shows Exact Match for the expected vehicle.

### Reverting Testing Changes:
**Method 1**
1. SSH to the comma device:</br>
`docker exec -it nnlc bash -c ssh comma`
2. Re-enable updates with:</br>
`echo -en "0" > /data/params/d/DisableUpdates`
3. Reboot the comma device.</br>
`sudo reboot now`
4. Exit the container's shell with `exit`
5. Install any pending updates - this will overwrite all changes in the data directory.

**Method 2**
1. SSH to the comma device:</br>
`docker exec -it nnlc bash -c ssh comma`
2. Delete your model with:</br>
`cd /data/openpilot/sunnypilot/neural_network_data/neural_network_lateral_control && rm VEHICLE_NAME.json`
3. If you backed up an existing model, revert the name change with:</br>
`mv VEHICLE_NAME.bk VEHICLE_NAME.json`
4. Reboot the comma device.</br>
`sudo reboot now`
5. Exit the container's shell with `exit`


## Environment Variables
| Variable Name          | Description                                                      | Example Value       | Default Value  | Allowed Values                                                        | Required                      | Notes                                                                                                                                      |
|------------------------|------------------------------------------------------------------|---------------------|----------------|-----------------------------------------------------------------------|-------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| COMMA_IP               | Local IP of the comma device                                     | 192.168.1.100       | -              | -                                                                     | If ENABLE_RLOGS_IMPORTER=true | Highly recommended to assign the comma a static IP in your router to prevent this value from changing                                      |
| DEVICE_ID              | Comma device's dongle ID                                         | 3d264cee10fdc8d3    | -              | -                                                                     | Yes                           | Can be found in comma device settings or your Comma Connect account.                                                                       |
| ENABLE_RLOGS_IMPORTER  | Enables importing of rlogs from comma device                     | true                | false          | true, false                                                           | No, but recommended           | Creates the SSH config to the comma device - the container can't be used to upload a model without this enabled                            |
| ENABLE_RLOGS_SCHEDULER | Enables rlog import script to be automatically run on a schedule | true                | false          | true, false                                                           | No                            | Requires the container to be left running continuously                                                                                     |
| RLOGS_SCHEDULE         | Allows a custom schedule for ENABLE_RLOGS_SCHEDULER              | 0 0 * * *           | 0 0-23/6 * * * | See https://crontab.guru/                                             | No                            | Highly advise against setting the minute (first) value to anything other than 0 to avoid triggering concurrent runs or unexpected behavior |
| VEHICLE                | Name of vehicle to use when naming directories                   | ioniq6              | -              | -                                                                     | Yes                           | Does not have to match vehicle name in opendbc. Do NOT include any spaces or special characters in this value                              |
| TZ                     | Timezone used by the container                                   | America/Los_Angeles | UTC            | See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List | No, but recommended           | Useful to set with ENABLE_RLOGS_SCHEDULER in order for the scheduled runs to happen at the expected time                                   |


## Data Volume Filetree
See below for a diagram of the data volume directory structure, where certain files are located, what files you should expect to see after running the processing script, and which of these files are important.
```
/
├── data/ (VOLUME)
│   ├── config/                                            (persistent SSH keys)
│   │   ├── ... 
│   ├── logs/                                              (script output logs)
│   │   ├── nnlc-process_log.txt
│   │   ├── rlog-import_log.txt
│   │   ├── rlog-import_scheduled_log.txt
│   ├── output/
│   │   ├── $VEHICLE/
│   │   │   ├── plots_torque/                              (Fit data plots - Processing Step 1)
│   │   │   ├── plots_torque-/                             (Fit data plots from previous run)
│   │   │   ├── rlogs/
│   │   │   │   ├── $DEVICE_ID/
│   │   │   │   │   ├── *.zst                              (Rlogs copied from /data/rlogs for processing)
│   │   │   ├── VEHICLE_NAME_steer_cmd/                    (Model generation output)
│   │   │   │   ├── ... 
│   │   │   ├── VEHICLE_NAME_torque_adjusted_eps/          (Model generation output - plots and model file)
│   │   │   │   ├── VEHICLE_NAME_torque_adjusted_eps-a.png (Generated model plot)
│   │   │   │   ├── VEHICLE_NAME_torque_adjusted_eps-b.png (Generated model plot)
│   │   │   │   ├── VEHICLE_NAME_torque_adjusted_eps.json  (Model file to be copied to comma)
│   │   │   ├── *.csv                                      (Processing files - Processing Step 2)
│   │   │   ├── *.feather                                  (Feather files - Processing Step 2)
│   │   │   ├── *.lat                                      (Lat files - Processing Step 1)
│   │   │   ├── $VEHICLE lat_accel_vs_torque.png           (Main processing data plots - Processing Step 2)
│   ├── rlogs/
│   │   ├── $VEHICLE/
│   │   │   ├── $DEVICE_ID/
│   │   │   │   ├── *.zst                                  (Rlogs downloaded using rlog-import)
```


## Misc

### Logging
The following logs are stored under `/data/logs` for basic debugging purposes. These are overwritten each time the associated script is run to prevent unintentional accumulation, and as such only include the log for the latest run.
- nnlc-process_log.txt
  - Generated by `nnlc-process`
- rlog-import_log.txt
  - Generated by `rlog-import`
- rlog-import_scheduled_log.txt
  - Generated by scheduled rlog import job

### Notable Untested Functionality
The following may or may not work out-of-box. These items have not been tested and as such may not exactly match the documentation or could require additional work.
- Other hosts: MacOS, non-Ubuntu Linux distros
- Nvidia GPU on Windows host


## Credits
<table id='credit'>
<tr>

<td align="center">
<a href='https://github.com/sunnypilot'>
<img src='https://avatars.githubusercontent.com/u/129032390?s=200&v=4' width='110px;'>
</a>
<br>
<a href='https://github.com/sunnypilot'>sunnypilot</a>
</td>

<td align="center">
<a href='https://github.com/twilsonco'>
<img src='https://avatars.githubusercontent.com/u/7284371?v=4' width='110px;'>
</a>
<br>
<a href='https://github.com/twilsonco'>twilsonco</a>
</td>

<td align="center">
<a href='https://github.com/mmmorks'>
<img src='https://avatars.githubusercontent.com/u/97648376?v=4' width='110px;'>
</a>
<br>
<a href='https://github.com/mmmorks'>mmmorks</a>
</td>

<td align="center">
<a href='https://github.com/wtogami'>
<img src='https://avatars.githubusercontent.com/u/93665?v=4' width='110px;'>
</a>
<br>
<a href='https://github.com/wtogami'>wtogami</a>
</td>

<td align="center">
<img src='https://cdn.discordapp.com/avatars/955452888740667452/2141725ad8985989069112a5cab58f04.webp?size=128' width='110px;'>
</a>
<br>
<a>syncword</a>
</td>

</tr>
</table>