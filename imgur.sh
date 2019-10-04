#!/usr/bin/env bash

# Imgur script by Bart Nagel <bart@tremby.net>
# Improvements by Tino Sino <robottinosino@gmail.com>
# Version 6 or more
# I release this into the public domain. Do with it what you will.
# The latest version can be found at https://github.com/tremby/imgur.sh

# API Key provided by Bart;
# replace with your own or specify yours as IMGUR_CLIENT_ID envionment variable
# to avoid limits
default_client_id=c9a6efb3d7932fd
client_id="${IMGUR_CLIENT_ID:=$default_client_id}"

# Function to output usage instructions
function usage {
	echo "Usage: $(basename $0) [<filename|URL> [...]]" >&2
	echo
	echo "Upload images to imgur and output their new URLs to stdout. Each one's" >&2
	echo "delete page is output to stderr between the view URLs." >&2
	echo
	echo "A filename can be - to read from stdin. If no filename is given, stdin is read." >&2
	echo
	echo "If xsel, xclip, or pbcopy is available, the URLs are put on the X selection for" >&2
	echo "easy pasting." >&2
}

# Function to upload a path
# First argument should be a content spec understood by curl's -F option
function upload {
	curl -s -H "Authorization: Client-ID $client_id" -H "Expect: " -F "image=$1" https://api.imgur.com/3/image.xml
	# The "Expect: " header is to get around a problem when using this through
	# the Squid proxy. Not sure if it's a Squid bug or what.
}


# Shows a desktop notification that the screenshot has been uploaded
# Requires libnotify
function show_notification {
	if type notify-send &>/dev/null;then
		notify-send "Screenshot uploaded" "Link: $1\nDelete page: $2" --icon=dialog-information
	else 
		echo "Couldn't find notify-send, missing package libnotify" >&2
	fi
}

# Check arguments
if [ "$1" == "-h" -o "$1" == "--help" ]; then
	usage
	exit 0
elif [ $# -eq 0 ]; then
	echo "No file specified; reading from stdin" >&2
	exec "$0" -
fi

# Check curl is available
type curl &>/dev/null || {
	echo "Couldn't find curl, which is required." >&2
	exit 17
}

clip=""
errors=false

# Loop through arguments
while [ $# -gt 0 ]; do
	file="$1"
	shift

	# Upload the image
	if [[ "$file" =~ ^https?:// ]]; then
		# URL -> imgur
		response=$(upload "$file") 2>/dev/null
	else
		# File -> imgur
		# Check file exists
		if [ "$file" != "-" -a ! -f "$file" ]; then
			echo "File '$file' doesn't exist; skipping" >&2
			errors=true
			continue
		fi
		response=$(upload "@$file") 2>/dev/null
	fi

	if [ $? -ne 0 ]; then
		echo "Upload failed" >&2
		errors=true
		continue
	elif echo "$response" | grep -q 'success="0"'; then
		echo "Error message from imgur:" >&2
		msg="${response##*<error>}"
		echo "${msg%%</error>*}" >&2
		errors=true
		continue
	fi

	# Parse the response and output our stuff
	url="${response##*<link>}"
	url="${url%%</link>*}"
	delete_hash="${response##*<deletehash>}"
	delete_hash="${delete_hash%%</deletehash>*}"
	delete_image_url="https://imgur.com/delete/$delete_hash"
	echo $url | sed 's/^http:/https:/'
	echo "Delete page: $delete_image_url" >&2	

	# Append the URL to a string so we can put them all on the clipboard later
	clip+="$url"
	if [ $# -gt 0 ]; then
		clip+=$'\n'
	fi
done

# Put the URLs on the clipboard if we can
if type pbcopy &>/dev/null; then
	echo -n "$clip" | pbcopy
elif [ $DISPLAY ]; then
	if type xsel &>/dev/null; then
		echo -n "$clip" | xsel -i
	elif type xclip &>/dev/null; then
		echo -n "$clip" | xclip
	else
		echo "Haven't copied to the clipboard: no xsel or xclip" >&2
	fi
else
	echo "Haven't copied to the clipboard: no \$DISPLAY or pbcopy" >&2
fi

if ! $errors; then
	# Notify over GUI if possible
	show_notification $url $delete_image_url
else 
	exit 1
fi