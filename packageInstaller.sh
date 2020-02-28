#!/bin/bash
# Pi Package Installer - Prevent repos and Large Downloads from ruining a program install
# by Nick Haley

# Programs and Dependencies here - for simple review and edits
BasicFeatures="fail2ban git"
MJPGStreamer="subversion libjpeg62-turbo-dev imagemagick ffmpeg libv4l-dev cmake"
OctoPrint="python-pip python-dev python-setuptools python-virtualenv git libyaml-dev build-essential"
HAProxy="haproxy"

# Add all Dependencies to List
ProgramList="$BasicFeatures $MJPGStreamer $OctoPrint $HAProxy"

# Update then Install List
sudo apt-get update -y
sudo apt-get install -y $ProgramList
exit 0