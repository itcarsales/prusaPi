## prusaPi
  OctoPrint full install script for Raspberry Pi 2/3/4 with camera and Prusa MK series 3D printer

  This project is not meant to replace OctoPi, but to give Prusa Users a basic install with profiles already created, most settings already configured, and an easy out-of-box experience.  This project does not walk a user through flashing images, or setting up wifi.  It assumes the user can image an SD card, add the blank SSH file, add their own wpa_supplicant.conf, and connect to their fresh Raspbian install via SSH.  I will only touch on these steps, and place example files in the project.

![prusaPi Camera Case](https://github.com/itcarsales/prusaPi/blob/master/images/camera.jpg)

## Configures
- OctoPrint (latest release build)
- Fail2Ban (extra security)
- HAProxy (clean URLs without port numbers)
- MJPEG-Streamer (sends images as video)
- Prusa Profiles for MK2, MK3, and MMU (generic defaults)

  
## Requirements:
- Prusa 3D Printer (MK2/3 and MMU)
- Raspberry Pi 3 or 4 with adequate Power Supply
  - Since there is only 1 reliable UART, a Zero can handle print control, or video...but not both reliably.
  - A Zero could be the perfect choice for Print Farm Individual Management without video
- Raspberry Pi Camera Module with ribbon cable
- 8Gb SD Card or larger
- USB Cable include with Prusa Printer
- Case - I recommend: https://www.prusaprinters.org/prints/24283

# Warning
  - It is never a good practice to blindly run random scripts from the internet.  This is a learning tool and shortcut for Prusa users, not a general OctoPi replacement. Please review the comments and code.

# Step 1)  SD Card Setup
  - Download the latest version of Raspbian Lite 
  https://www.raspberrypi.org/downloads/raspbian/ ( Raspbian Buster Lite 2020-02-13 at time of writing )
  
  - Image your SD card with Raspbian
  - Create a blank file and name it SSH on the boot partition
  - Add your wpa_supplicant.conf to the boot partition with your country code and wifi settings
 
# Step 2) Initial Pi Setup
  - Insert SD Card in the Pi (with camera module)
  - Plug your Pi into the power supply, but do not plug in the USB cable
  - Wait a minute for it to boot, the connect via SSH (it will grab a DHCP IP Address - so I recommend checking your router to see which address was assigned)
    - ```ssh pi@PI.IP.ADDRESS.HERE```
    - Password: ```raspberry```
  - run the following command to download the setup script from this repo, then follow along with the prompts
    - ```bash <(curl -Ls https://github.com/itcarsales/prusaPi/raw/master/newPi.sh)```
    - Select your language, location, and timezone
      - I use ```en_US.UTF-8 UTF-8``` for US Language
  - Your Pi should complete the script and reboot automatically
  
# Step 3) Linux Preperation
  - Your Pi should have rebooted, and your USB cable should still be disconnected
  - You can now reconnect via SSH using ```prusamaker``` as the new password
  - CHANGE THE PASSWORD NOW
    - type ```passwd``` and follow the prompts
  - run the following command to download the update script from this repo
    - ```bash <(curl -Ls https://github.com/itcarsales/prusaPi/raw/master/packageInstaller.sh)```
    - This will update and install the required Raspbian Buster dependencies for this project (current as of 2-2020)
    - depending on your model Pi, this could take some time.
    - WARNING - this will download about 800Mb of data updates.  An unstable connection may result in a bad time.

# Step 4) Software Installation
  - run the following command to download the setup script from this repo
    - ```bash <(curl -Ls https://github.com/itcarsales/prusaPi/raw/master/prusaPi.sh)```
  - Your Pi should complete the script and reboot automatically
  
 # Step 5) Connect Printer and Test
  - Give your Pi a minute or so to reboot
  - Connect your USB cable to your Prusa
  - Power-On your Prusa
  - Open a browser and visit the following URL:
    - ```http://PI.IP.ADDRESS.HERE```
    - You should see the First-Run Setup screen for OctoPrint
    
 # Step 6) Setup OctoPrint and Enjoy!
  - I'm not going to try to reinvent a setup guide, as this project was designed to simply allow Raspberry Pi users a way to use current OS releases with current OctoPrint releases......and include Prusa Printer Profiles.
  
  
 ## COMING SOON
  Add an additional piHome Server to enable piHole adblocking, NodeRED IOT server, and VPN access for OctoPrint anywhere control.

  <hr>

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MLRHALWRP3KJC)

bitcoin donations: 19J2vXb7Zj57fQxtGXHqmq6pFDoeW7jAVb
  