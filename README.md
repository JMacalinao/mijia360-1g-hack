# Mijia 360 1080p (1st-gen) camera hack

This is an indirect fork of [niclet/xiaomi_hack](https://github.com/niclet/xiaomi_hack) for the first-gen Mijia 360 1080p IP camera (JTSXJ01CM), with additional features:

* Enable/disable cloud (Mi Home)
* SSH support
* RTSP support
* Night vision (on/off/auto)

However, there are a couple of features not working on Disabled Cloud mode, namely the voice translations; in this case, voice is not working at all. I also wanted to get even more features in here like motor control ~~and night mode~~, but they're locked up in a library named libdrv.so (at least, according to my initial research).

Unfortunately, I do not have enough time or brains to reverse-engineer either niclet's library (libxiaomihack.so) or libdrv.so, but if you are able to get a hold of their sources, or any other relevant source or clues/hints, just hit me up via [Twitter](https://twitter.com/JMacalinao).

## Recommended firmware

The firmware I'm currently using is version **3.3.10_2017121915** that I upgraded OTA via Mi Home years ago, and I haven't upgraded to anything beyond that, so I can only recommend firmwares less than or equal to that. You might be able to downgrade your firmware (if you have a Windows machine) by going to a particular Russian site and getting an older firmware and the flashing tool, but I haven't tested that yet.

## Installation

0. If you are planning to use this with Mi Home (ENABLE_CLOUD=true), reset the camera and set it up first.
1. Copy all files to your SD card.
2. Edit config.ini.
3. Insert SD card to the camera.
4. Plug in the camera.

## Usage

* FTP server
  * Port 21
  * Login: root, no password
* SSH server
  * Port 22
  * Login: root, Password: MCH_ROOT_PASSWORD value in config.ini
* Telnet server
  * Port 23
  * Login: root, Password: MCH_ROOT_PASSWORD value in config.ini
* RTSP server
  * Stream 1 (1080p): rtsp://{IP}/stream1
  * Stream 2 (360p): rtsp://{IP}/stream2

## LED indicator on startup (Disabled Cloud mode)

Solid yellow - It's turned on. Hope and pray that it doesn't get stuck in this mode.

Flashing green - Setting up the camera's network configuration and connecting to Wi-Fi.

Solid red - Wi-Fi connection failed. Maybe the config is wrong?

Flashing blue - Connected to Wi-Fi, setting up the rest of the services (e.g. NTP, RSTP, etc.)

Solid blue (or off, if you disabled it) - Startup complete.

## Stuck in solid yellow LED?

Before pushing the reset button or getting a recovery image, try the following first:

1. Remove the SD card.
2. Plug in the camera.
3. Wait for 30 seconds.
4. If the LED is still solid yellow, unplug the camera.
5. Do #3 and #4 five to six times.

## License

I'm kinda lazy to get into jargon, but basically, everything is provided as-is, and I am not liable if using this code bricks your device, causes a nuclear holocaust, or anything in between.
