#!/bin/bash

# Variables we need to make things easier later on.

CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
VID="0x05ac"
PID="0xdead"
DEVICE="0x0001"
SERIAL="1"
MANUF="Apple"
PRODUCT="PiSight"
BOARD=$(strings /proc/device-tree/model)
UDC=`ls /sys/class/udc` # will identify the 'first' UDC

# Later on, this function is used to tell the usb subsystem that we want
# to support a particular format, framesize and frameintervals
create_frame() {
	# Example usage:
	# create_frame <function name> <width> <height> <format> <name> <intervals>

	FUNCTION=$1
	WIDTH=$2
	HEIGHT=$3
	FORMAT=$4
	NAME=$5

	wdir=functions/$FUNCTION/streaming/$FORMAT/$NAME/${HEIGHT}p

	mkdir -p $wdir
	echo $WIDTH > $wdir/wWidth
	echo $HEIGHT > $wdir/wHeight
	echo $(( $WIDTH * $HEIGHT * 2 )) > $wdir/dwMaxVideoFrameBufferSize
	cat <<EOF > $wdir/dwFrameInterval
$6
EOF
}

# This function sets up the UVC gadget function in configfs and binds us
# to the UVC gadget driver.
create_uvc() {
	CONFIG=$1
	FUNCTION=$2

	echo "	Creating UVC gadget functionality : $FUNCTION"
	mkdir functions/$FUNCTION

	create_frame $FUNCTION 640 480 uncompressed u "333333
416667
500000
666666
1000000
1333333
2000000
"
	create_frame $FUNCTION 1280 720 uncompressed u "1000000
1333333
2000000
"
	create_frame $FUNCTION 1920 1080 uncompressed u "2000000"
	create_frame $FUNCTION 640 480 mjpeg m "333333
416667
500000
666666
1000000
1333333
2000000
"
	create_frame $FUNCTION 1280 720 mjpeg m "333333
416667
500000
666666
1000000
1333333
2000000
"
	create_frame $FUNCTION 1920 1080 mjpeg m "333333
416667
500000
666666
1000000
1333333
2000000
"

	mkdir functions/$FUNCTION/streaming/header/h
	cd functions/$FUNCTION/streaming/header/h
	ln -s ../../uncompressed/u
	ln -s ../../mjpeg/m
	cd ../../class/fs
	ln -s ../../header/h
	cd ../../class/hs
	ln -s ../../header/h
	cd ../../class/ss
	ln -s ../../header/h
	cd ../../../control
	mkdir header/h
	ln -s header/h class/fs
	ln -s header/h class/ss
	cd ../../../

	# This configures the USB endpoint to allow 3x 1024 byte packets per
	# microframe, which gives us the maximum speed for USB 2.0. Other
	# valid values are 1024 and 2048, but these will result in a lower
	# supportable framerate.
	echo 2048 > functions/$FUNCTION/streaming_maxpacket

	ln -s functions/$FUNCTION configs/c.1
}

# This loads the module responsible for allowing USB Gadgets to be
# configured through configfs, without which we can't connect to the
# UVC gadget kernel driver
echo "Loading composite module"
modprobe libcomposite

# This section configures the gadget through configfs. We need to
# create a bunch of files and directories that describe the USB
# device we want to pretend to be.

if
[ ! -d $GADGET/g1 ]; then
	echo "Detecting platform:"
	echo "  board : $BOARD"
	echo "  udc   : $UDC"

	echo "Creating the USB gadget"

	echo "Creating gadget directory g1"
	mkdir -p $GADGET/g1

	cd $GADGET/g1
	if
[ $? -ne 0 ]; then
		echo "Error creating usb gadget in configfs"
		exit 1;
	else
		echo "OK"
	fi

	echo "Setting Vendor and Product ID's"
	echo $VID > idVendor
	echo $PID > idProduct
	echo $DEVICE > bcdDevice
	echo "OK"

	echo "Setting English strings"
	mkdir -p strings/0x409
	echo $SERIAL > strings/0x409/serialnumber
	echo $MANUF > strings/0x409/manufacturer
	echo $PRODUCT > strings/0x409/product
	echo "OK"

	echo "Creating Config"
	mkdir configs/c.1
	mkdir configs/c.1/strings/0x409

	echo "Creating functions..."

	create_uvc configs/c.1 uvc.0

	echo "OK"

	echo "Binding USB Device Controller"
	echo $UDC > UDC
	echo "OK"
fi

# Run uvc-gadget. The -c flag sets libcamera as a source, arg 0 selects
# the first available camera on the system. All cameras will be listed,
# you can re-run with -c n to select camera n or -c ID to select via
# the camera ID.
uvc-gadget -c 0 uvc.0 &
