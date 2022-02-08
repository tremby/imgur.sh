#!/usr/bin/env bash

# Imgur script by Bart Nagel <bart@tremby.net>
# Improvements by Tino Sino <robottinosino@gmail.com>
# Version 6 or more
# I release this into the public domain. Do with it what you will.
# The latest version can be found at https://github.com/tremby/imgur.sh

# API Key provided by Bart;
# replace with your own or specify yours as IMGUR_CLIENT_ID environment variable
# to avoid limits
default_client_id=c9a6efb3d7932fd
client_id="${IMGUR_CLIENT_ID:=$default_client_id}"

# Function to output usage instructions
usage () {
	cat << EOF
     
USAGE:
    $(basename "$0") [<filename|URL> [...]]
    ${0##*/} [OPTIONS] [NUMBER]

OPTIONS:
    -h, --help              Show this help message
    -l, --list              List imgur history of your uploads
    -o, --open <NUM>        Open recent <NUM> images(<NUM> is optional)
    -r, --remove <NUM>      Remove recent <NUM> images from imgur(<NUM> is optional)
     
DESCRIPTION: 
    Upload images to imgur and output their new URLs to stdout. Each one's
    delete page is output to stderr between the view URLs.
     
    A filename can be - to read from stdin. If no filename is given, stdin is read.
    If xsel, xclip, pbcopy, or clip is available,
    the URLs are put on the X selection or clipboard for easy pasting.
     
    Use environment variables to set special options for your clipboard program (see
    code).
    NAME 
    Randomly select & apply an kitty color theme

EOF
 
}

# Function to upload a path
# First argument should be a content spec understood by curl's -F option
upload () {
	curl --progress-bar -H "Authorization: Client-ID $client_id" \
        -H "Expect: " -F "image=$1" https://api.imgur.com/3/image.xml
	# The "Expect: " header is to get around a problem when using this through
	# the Squid proxy. Not sure if it's a Squid bug or what.
}
 
list () {
    less ~/imgur.txt
} 
 
open () {
    if [ -n "$1" ]; then
        for each_image in $( grep -io 'https://i\..*' imgur.txt  | tail "-$1" ); do
            xdg-open "$each_image"
        done 
    else
        xdg-open "$( grep -io 'https://i\..*' imgur.txt  | tail -1 )"
    fi
}
 
remove () {
    if [ -n "$1" ]; then
        for hash in $( sed -n -e 's/^.*delete\///p' imgur.txt | tail "-$1" ); do
            curl --location -g --request DELETE "https://api.imgur.com/3/image/$hash" \
                --header "Authorization: Client-ID $client_id"
            done 
        else
            hash=$( sed -n -e 's/^.*delete\///p' imgur.txt | tail -1 )
            curl --location -g --request DELETE "https://api.imgur.com/3/image/$hash" \
                --header "Authorization: Client-ID $client_id"
    fi
}
 
# Check arguments
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	usage
	exit 0
elif [ "$1" == "-l" ] || [ "$1" == "--list" ]; then
	list
	exit 0
elif [ "$1" == "-o" ] || [ "$1" == "--open" ]; then
    open "$2" 
	exit 0
elif [ "$1" == "-r" ] || [ "$1" == "--remove" ]; then
    remove "$2" 
	exit 0
elif [ $# -eq 0 ]; then
	printf '%s\n' "No file specified; reading from stdin" >&2
	exec "$0" -
fi

# Check curl is available
type curl &>/dev/null || {
	printf '%s\n' "Couldn't find curl, which is required." >&2
	exit 17
}

clip=""
errors=false

printf '%s\n' "TIME:   $( date )" >> "$HOME/imgur.txt"
     
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
		if [ "$file" != "-" ] && [ ! -f "$file" ]; then
			printf '%s\n' "File '$file' doesn't exist; skipping" >&2
            printf '%s\n' "ERROR:  $file doesn't exist" >> "$HOME/imgur.txt"
			errors=true
			continue
		fi
		response=$(upload "@$file") 2>/dev/null
	fi

	if [ $? -ne 0 ]; then
		printf '%s\n' "Upload failed" >&2
        printf '%s\n' "ERROR:  Upload failed" >> "$HOME/imgur.txt"
		errors=true
		continue
	elif printf '%s\n' "$response" | grep -q 'success="0"'; then
		printf '%s\n' "Error message from imgur:" >&2
		msg="${response##*<error>}"
		printf '%s\n' "${msg%%</error>*}" >&2
        printf '%s\n' "ERROR:  ${msg%%</error>*}" >> "$HOME/imgur.txt"
		errors=true
		continue
	fi

	# Parse the response and output our stuff
	url="${response##*<link>}"
	url="${url%%</link>*}"
	delete_hash="${response##*<deletehash>}"
	delete_hash="${delete_hash%%</deletehash>*}"
	printf '%s\n' "$url"
	printf '%s\n' "Delete page: https://imgur.com/delete/$delete_hash" >&2
    printf '%s\n' "FILE:   $file
LINK:   $url
DELETE: https://imgur.com/delete/$delete_hash" >> "$HOME/imgur.txt"

	# Append the URL to a string so we can put them all on the clipboard later
	clip+="$url"
	if [ $# -gt 0 ]; then
		clip+=$'\n'
	fi
done
 
printf '\n%s\n\n' \
"----------------------------------------------------------------------" >> \
"$HOME/imgur.txt"
 
# Put the URLs on the clipboard if we can
if type pbcopy &>/dev/null; then
	printf '%s' "$clip" | pbcopy $IMGUR_PBCOPY_OPTIONS
elif type clip &>/dev/null; then
	printf '%s' "$clip" | clip $IMGUR_CLIP_OPTIONS
elif [ "$DISPLAY" ]; then
	if type xsel &>/dev/null; then
		printf '%s' "$clip" | xsel -i $IMGUR_XSEL_OPTIONS
	elif type xclip &>/dev/null; then
		printf '%s' "$clip" | xclip $IMGUR_XCLIP_OPTIONS
	else
		echo "Haven't copied to the clipboard: no xsel or xclip" >&2
	fi
else
	echo "Haven't copied to the clipboard: no \$DISPLAY or pbcopy or clip" >&2
fi

if $errors; then
    exit 1
fi
