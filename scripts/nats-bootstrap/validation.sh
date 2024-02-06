#!/bin/bash

OS=$(uname -s)

function validate_command() {
	if ! [ -x "$(command -v $1)" ]; then
		echo "Error: On $OS. Command $1 isnt found!"
		exit 1
	fi
}

# While "base64" exists on MacOS, it is the BSD verison without the '-w' option. We want the GNU version.
# So we will use os_base64 to make it work cleanly on linux and macos
if [[ $OS == *"Darwin"* ]]; then
	validate_command gbase64
	os_base64=(gbase64)
elif [[ $OS == *"Linux"* ]]; then
	validate_command base64
	os_base64=(base64)
else
	echo "Error: Unknown/Unsupported OS detected!"
	exit 1
fi

validate_command helm
validate_command kubectl
validate_command make
