#!/bin/bash
# Octoprint prusaPi (updated for buster)
# by Nick Haley
# Credit to https://community.octoprint.org/t/setting-up-octoprint-on-a-raspberry-pi-running-raspbian/2337 for the majority of the code base.
# No affiliation with Prusa Research or OctoPrint - Project named for printer models supported

if ! [ $(id -u) -ne 0 ]; then
	echo "Setup cannot be run with sudo"
	echo "Please use: 'bash $0'"
	exit 1
fi

echo && read -p "Would you like to install OctoPrint on your Raspberry Pi? (y/n)" -n 1 -r -s installRPI && echo
if [[ $installRPI != "Y" && $installRPI != "y" ]]; then
	echo "prusaPi install cancelled."
	exit 1
fi

echo && read -p "Have you run the Package Installer already? (y/n)" -n 1 -r -s installRPI && echo
if [[ $installRPI != "Y" && $installRPI != "y" ]]; then
	echo "prusaPi install cancelled."
	exit 1
fi

# Download and compile software to stream images as video - mjpeg-streamer
# REQUIRED PACKAGES: subversion libjpeg62-turbo-dev imagemagick ffmpeg libv4l-dev cmake
cd /home/pi
git clone https://github.com/jacksonliam/mjpg-streamer.git
cd /home/pi/mjpg-streamer/mjpg-streamer-experimental
export LD_LIBRARY_PATH=.
make
#sudo make install
cd /home/pi

#######################OctoPrint#############################
# Install packages for octoprint
# REQUIRED PACKAGES: python-pip python-dev python-setuptools python-virtualenv git libyaml-dev build-essential

# Configure environment and setup octoprint
mkdir /home/pi/octoprint
cd /home/pi/octoprint
virtualenv venv
source venv/bin/activate
pip install pip --upgrade
pip install --no-cache-dir octoprint
cd /home/pi

# Modify User Permissions - Add user to dialout group to allow access to serial port
sudo usermod -a -G tty pi
sudo usermod -a -G dialout pi

# Create Service file for OctoPrint Auto Start
cat << EOF > "$HOME/octoprint.service"
[Unit]
Description=Octoprint - prusaPi Version
After=network.target
Wants = network-online.target
 
[Service]
User=pi
Type = simple
ExecStart=/home/pi/octoprint/venv/bin/octoprint serve
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF
#Move the file to SystemD
sudo mv /home/pi/octoprint.service /etc/systemd/system/octoprint.service

#Reload, enable auto-start, and start OctoPrint Sevice
sudo systemctl daemon-reload
sudo systemctl enable octoprint.service
sudo systemctl start octoprint.service

######################HAProxy###################################
# Install HAProxy
# REQUIRED PACKAGES: haproxy

# Create config for HAProxy
cat << EOF >> "$HOME/haproxy.cfg"
global
        maxconn 4096
        user haproxy
        group haproxy
        daemon
        log 127.0.0.1 local0 debug

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        retries 3
        option redispatch
        option http-server-close
        option forwardfor
        maxconn 2000
        timeout connect 5s
        timeout client  15min
        timeout server  15min

frontend public
        bind :::80 v4v6
        use_backend webcam if { path_beg /webcam/ }
        default_backend octoprint

backend octoprint
        reqrep ^([^\ :]*)\ /(.*)     \1\ /\2
        option forwardfor
        server octoprint1 127.0.0.1:5000

backend webcam
        reqrep ^([^\ :]*)\ /webcam/(.*)     \1\ /\2
        server webcam1  127.0.0.1:8080
EOF
sudo mv /home/pi/haproxy.cfg /etc/haproxy/haproxy.cfg
echo ENABLED=1 | sudo tee -a /etc/default/haproxy
sudo service haproxy start

#########################Pi Camera################################
# Load camera driver and set to load on startup
sudo modprobe bcm2835-v4l2
echo bcm2835-v4l2 | sudo tee -a /etc/modules

# Add Webcam control scripts
mkdir /home/pi/scripts
cat << EOF > "$HOME/scripts/webcam"
#!/bin/bash
# Start / stop streamer daemon

case "\$1" in
    start)
        /home/pi/scripts/webcamDaemon >/dev/null 2>&1 &
        echo "\$0: started"
        ;;
    stop)
        pkill -x webcamDaemon
        pkill -x mjpg_streamer
        echo "\$0: stopped"
        ;;
    *)
        echo "Usage: \$0 {start|stop}" >&2
        ;;
esac
EOF
chmod +x /home/pi/scripts/webcam

cat << EOF > "$HOME/scripts/webcamDaemon"
#!/bin/bash

MJPGSTREAMER_HOME=/home/pi/mjpg-streamer/mjpg-streamer-experimental
MJPGSTREAMER_INPUT_USB="input_uvc.so"
MJPGSTREAMER_INPUT_RASPICAM="input_raspicam.so"

# init configuration
camera="auto"
camera_usb_options="-r 640x480 -f 10"
camera_raspi_options="-fps 10"

if [ -e "/boot/octopi.txt" ]; then
    source "/boot/octopi.txt"
fi

# runs MJPG Streamer, using the provided input plugin + configuration
function runMjpgStreamer {
    input=\$1
    pushd \$MJPGSTREAMER_HOME
    echo Running ./mjpg_streamer -o "output_http.so -w ./www" -i "\$input"
    LD_LIBRARY_PATH=. ./mjpg_streamer -o "output_http.so -w ./www" -i "\$input"
    popd
}

# starts up the RasPiCam
function startRaspi {
    logger "Starting Raspberry Pi camera"
    runMjpgStreamer "\$MJPGSTREAMER_INPUT_RASPICAM \$camera_raspi_options"
}

# starts up the USB webcam
function startUsb {
    logger "Starting USB webcam"
    runMjpgStreamer "\$MJPGSTREAMER_INPUT_USB \$camera_usb_options"
}

# we need this to prevent the later calls to vcgencmd from blocking
# I have no idea why, but that's how it is...
# Honest comments are the best!!!! Black Box solution incoming........
vcgencmd version

# echo configuration
echo camera: \$camera
echo usb options: \$camera_usb_options
echo raspi options: \$camera_raspi_options

# keep mjpg streamer running if some camera is attached
while true; do
    if [ -e "/dev/video0" ] && { [ "\$camera" = "auto" ] || [ "\$camera" = "usb" ] ; }; then
        startUsb
    elif [ "`vcgencmd get_camera`" = "supported=1 detected=1" ] && { [ "\$camera" = "auto" ] || [ "\$camera" = "raspi" ] ; }; then
        startRaspi
    fi

    sleep 120
done
EOF
chmod +x /home/pi/scripts/webcamDaemon

# Set Webcam to run on Startup
sudo sed -i 's/exit 0/home\/pi\/scripts\/webcam start/' /etc/rc.local
echo exit 0 | sudo tee -a /etc/rc.local

#####################Custom Profiles and Settings##############################
# Stop OctoPrint after initiialization to customize services
sudo systemctl stop octoprint.service

#Create Default Profiles for Prusa - because Prusa
cat << EOF >> "$HOME/.octoprint/printerProfiles/prusaMK3.profile"
axes:
  e:
    inverted: false
    speed: 300
  x:
    inverted: false
    speed: 6000
  y:
    inverted: false
    speed: 6000
  z:
    inverted: false
    speed: 200
color: default
extruder:
  count: 1
  nozzleDiameter: 0.4
  offsets:
  - - 0.0
    - 0.0
  sharedNozzle: false
heatedBed: true
heatedChamber: false
id: _default
model: Prusa_Generic_MK3
name: Prusa_Generic_MK3
volume:
  custom_box:
    x_max: 250.0
    x_min: 0.0
    y_max: 210.0
    y_min: -4.0
    z_max: 200.0
    z_min: 0.0
  depth: 210.0
  formFactor: rectangular
  height: 200.0
  origin: lowerleft
  width: 250.0
EOF

#Copy and Modify files - hacky way to save lines of code with the previous cat 2 more times
cd /home/pi/.octoprint/printerProfiles/
cp prusaMK3.profile prusaMK2.profile
sed -i 's/MK3/MK2/g' prusaMK2.profile
cp prusaMK3.profile prusaMMU.profile
sed -i 's/MK3/MMU/g' prusaMMU.profile
sed -i 's/count: 1/count: 5/g' prusaMMU.profile

# Add settings to OctoPrint yaml for webcam
cat << EOF >> "$HOME/.octoprint/config.yaml"
printerProfiles:
  default: Prusa_Generic_MK3
server:
  host: 127.0.0.1
  commands:
    serverRestartCommand: sudo service octoprint restart
    systemRestartCommand: sudo shutdown -r now
    systemShutdownCommand: sudo shutdown -h now
webcam:
  ffmpeg: /usr/bin/ffmpeg
  snapshot: http://127.0.0.1:8080/?action=snapshot
  stream: /webcam/?action=stream
  streamRatio: '4:3'
  watermark: false
system:
  actions:
   - action: streamon
     command: /home/pi/scripts/webcam start
     confirm: false
     name: Start video stream
   - action: streamoff
     command: sudo /home/pi/scripts/webcam stop
     confirm: false
     name: Stop video stream
EOF

# Restart OctoPrint and wait for it to initialize - otherwise it reboots too quickly and causes safe mode on next run
sudo systemctl start octoprint.service
sleep 15

################## Reboot##########################
# Reboot to complete
sudo reboot now