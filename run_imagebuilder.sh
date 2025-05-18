#!/bin/bash

# Include the config file in the same directory as this script
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/extract_tar.sh"

# Clear the screen
clear

# Show a message from a txt file in dialogs folder inside the script folder. Dialog button shows "Continue"
dialog --title "Welcome" --msgbox "$(cat "$(dirname "$0")/dialogs/welcome.txt")" 20 60

# After user presses OK, get the list of folders in this URL
OPENWRT_VERSIONS=$(curl -s $OPENWRT_URL/ | grep -oP '(?<=href=")[0-9]+\.[0-9]+(\.[0-9]+)?/' | sed 's|/||' | sort -Vr)

# Get the selected version and store it in a variable
SELECTED_VERSION=$(dialog --stdout --title "Select a folder" --menu "Choose a stable version:" 15 50 10 $OPENWRT_VERSIONS)

# Show a 2 fields form to fill in the "Custom files path" and "Extra Packages list" and store them in variables when submitted. Fields can be left empty
# The form must be 2 lines, the first line is the "Custom files path" and the second line is the "Extra Packages list" 
# You selected version XXXX. Please fill in the following fields:
# "Custom files path" : ________________
# "Extra Packages list" : ________________

# < OK > < Cancel >

while true; do
  form_output=$(dialog --clear \
    --title "OpenWRT Configuration" \
    --form "You selected version $SELECTED_VERSION. Please fill in the following fields:" 15 90 2 \
    "Custom files path:"     1 1 "" 1 25 40 0 \
    "Extra Packages list:"   2 1 "" 2 25 40 0 \
    3>&1 1>&2 2>&3)
  exitcode=$?
  exec 3>&-

  if [ $exitcode -ne 0 ]; then
    echo "User cancelled the form."
    exit 1
  fi

  custom_path=$(echo "$form_output" | sed -n '1p')
  extra_packages=$(echo "$form_output" | sed -n '2p')

  dialog --title "Confirm" \
    --yes-label "OK" \
    --no-label "Edit" \
    --yesno "You selected version $SELECTED_VERSION.\n\nCustom files path: $custom_path\n\nExtra Packages path: $extra_packages" 15 90

  confirm_exit=$?

  if [ $confirm_exit -eq 0 ]; then
    # OK pressed, break out of loop
    break
  elif [ $confirm_exit -eq 1 ]; then
    # Edit selected, loop again
    continue
  else
    # ESC pressed, exit
    echo "User cancelled confirmation."
    exit 1
  fi
done

# Try to read the custom files path and extra packages list from the form, if files are not found, show a message and exit
# If the custom files path is empty, continue and quit the if statement
if [ -z "$custom_path" ]; then
    custom_path=""
elif [ ! -d "$custom_path" ]; then
  dialog --title "Error" --msgbox "Custom files path not found: $custom_path" 10 50
  exit 1
fi
if [ -z "$extra_packages" ]; then
    extra_packages=""
elif [ ! -f "$extra_packages" ]; then
  dialog --title "Error" --msgbox "Custom packages path not found: $extra_packages" 10 50
  exit 1
fi
# Show a message with the list of packages in the file, replace spaces with new lines if custoḿ_packages is not empty
if [ "$extra_packages" != "" ]; then
    dialog --title "Extra Packages" --msgbox "$(cat "$extra_packages" | tr ' ' '\n')" 20 60
    extra_packages=$(cat "$extra_packages")
fi
# Show a message with the list of files in the custom path if it is not empty
if [ "$custom_path" != "" ]; then
    dialog --title "Custom Files" --msgbox "$(ls "$custom_path" --all --recursive)" 20 60
fi

# Get the name of the downloaded file
OPENWRT_FILE=$(wget -qO- $OPENWRT_URL/$SELECTED_VERSION/$WGET_PATH/ | grep -oP 'href="(openwrt-imagebuilder-[^"]+)"' | cut -d'"' -f2)

# Donwload the OpenWRT imagebuilder tar file if it doesn't exist
if [ ! -f "builds/$OPENWRT_FILE" ]; then
    mkdir -p builds
    wget -q $OPENWRT_URL/$SELECTED_VERSION/$WGET_PATH/$OPENWRT_FILE -O builds/$OPENWRT_FILE
else
    echo "File already exists, skipping download."
fi

# --------------
# Run the command to download the imagebuilder
extract_tar builds/$OPENWRT_FILE

# Get the name of decompressed folder
IMAGEBUILDER_FOLDER=$(echo "$OPENWRT_FILE" | sed 's/\.tar\..*//' | head -n 1)

# Move into the extracted folder 
cd "builds/$IMAGEBUILDER_FOLDER"

# Run the build in background and capture output
LOGFILE=$(mktemp)
(
    echo "Starting build for profile: $PROFILE..."
    echo "make image PROFILE=$PROFILE PACKAGES=$extra_packages FILES=$custom_path"
    make image PROFILE=$PROFILE PACKAGES=$extra_packages FILES=$custom_path
    echo "Build complete."
) &> "$LOGFILE" &

BUILD_PID=$!

# Show the log output in real-time
dialog --title "Building OpenWRT Image" --tailbox "$LOGFILE" 20 70 &

DIALOG_PID=$!

# Wait for build to finish
wait $BUILD_PID

# Once done, close the tailbox
kill $DIALOG_PID 2>/dev/null

# Get date as YYYYMMDD
DATE=$(date +%Y%m%d)
# Move back a directory and create a new directory with the date
cd ../..
mkdir -p "output/$DATE"
FINAL_PATH=$(pwd)
cp $FINAL_PATH/builds/$IMAGEBUILDER_FOLDER/bin/targets/bcm27xx/bcm2710/* $FINAL_PATH/output/$DATE/

# Clean up the builds folder
rm -r "builds/$IMAGEBUILDER_FOLDER"
#rm "builds/$OPENWRT_FILE"

dialog --title "Done" --msgbox "Image build finished.\n\nLog file: $LOGFILE\n\n
Output files are in \n\n$FINAL_PATH/output/$DATE/" 20 60

# Clear the screen
clear

# Also echo the log file path and last lines of the log file
printf "Image build finished.\n\nLog file: $LOGFILE\n\n"
printf "Output files are in \n$FINAL_PATH/output/$DATE/\n\n"



