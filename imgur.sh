#!/bin/bash

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

#DBG=1; # debug output on: This will keep TEMPFILES.
DBG=;  # debug output off


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


#########################################################


cleanup() { local rc=$?;
  [ $CLEANUP_DONE ] && return;
  [ $DBG ] && printf "\nCLEANUP! ($rc) [$*]";
  if [ -n "$TEMPFILES" ]; then
    if [ $DBG ]; then
      printf "\n\nATTENTION: KEEPING THE TEMPFILES:\n" 1>&2;
      for a in $TEMPFILES; do
        [ $DBG ] && { printf "\t\t'$a'\n"; continue; }
        rm -Rf "$a" || printf "\t\t'$a' - FAILED to 'rm -f'!\n" \
                    && printf "\t\t'$a' - removed\n" 1>&2;
      done
      TEMPFILES=;
    else
      [ $VRB ] && echo "Cleaning up..."
      for a in $TEMPFILES; do rm -Rf "$a"; done; TEMPFILES=;
    fi
  fi

  CLEANUP_DONE=1
  exit $rc; # return does not suffice
}


set_TEMPFILE() {
  [ -n "$1" ] && local suffix=".$1" || local suffix=".tmp"
  [ -n "$2" ] && local prefix="$2." || local prefix="temp.mine.$US."
  local now="$( date +"%Y-%m-%d_%H%M.%S")"
  TEMPFILE=$(tempfile 2>/dev/null) || TEMPFILE="/tmp/$prefix$$@$now$suffix"
  TEMPFILES="$TEMPFILES $TEMPFILE"
}


#########################################################


# Function to upload a path
# First argument should be a content spec understood by curl's -F option
# Sets RESULT variable with output of curl call
function upload {
  set_TEMPFILE

	# The "Expect: " header is to get around a problem when using this through
	# the Squid proxy. Not sure if it's a Squid bug or what.
	[ $DBG ] && printf "Running:\ncurl --progress-bar -H \"Authorization: Client-ID %s\" -H \"Expect: \" -F \"image=%s\" https://api.imgur.com/3/image.xml -o \"$TEMPFILE\"\n\nDEBUG-MODE, so the output file '$TEMPFILE' will be kept at the end of the script!\n\n" "$client_id" "$1"
	curl --progress-bar -H "Authorization: Client-ID $client_id" -H "Expect: " -F "image=$1" https://api.imgur.com/3/image.xml -o "$TEMPFILE" || return $?

  [ -s "$TEMPFILE" ] || return 1
  RESULT="$(cat "$TEMPFILE")" || return 1
  [ $DBG ] && printf "\nResult output from curl command:\n__________________________________\n%s\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n" "$RESULT"
  return 0
}

#########################################################
#### MAIN:

US=${0##*/};   # get filename without path
TEMPFILES=;    # space separated list of tempfiles

CLEANUP_DONE=; # avoid multiple cleanups; is set in _cleanup_()

# set up the trap for a clean exit:
for i in 0 1 2 3 4 5 6 7 8 9; do trap "cleanup \"TRAP\" $i;" $i; done;


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
		upload "$file"
	else
		# File -> imgur
		# Check file exists
		if [ "$file" != "-" -a ! -f "$file" ]; then
			echo "File '$file' doesn't exist; skipping" >&2
			errors=true
			continue
		fi
		upload "@$file"
	fi

	if [ $? -ne 0 ]; then
		echo "Upload failed" >&2
		errors=true
		continue
	elif echo "$RESULT" | grep -q 'success="0"'; then
		echo "Error message from imgur:" >&2
		msg="${RESULT##*<error>}"
		echo "${msg%%</error>*}" >&2
		errors=true
		continue
	fi

	# Parse the response RESULT and output our stuff
	url="${RESULT##*<link>}"
	url="${url%%</link>*}"
	delete_hash="${RESULT##*<deletehash>}"
	delete_hash="${delete_hash%%</deletehash>*}"
	echo $url | sed 's/^http:/https:/'
	echo "Delete page: https://imgur.com/delete/$delete_hash" >&2

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
		echo -n "$clip" | xsel
	elif type xclip &>/dev/null; then
		echo -n "$clip" | xclip
	else
		echo "Haven't copied to the clipboard: no xsel or xclip" >&2
	fi
else
	echo "Haven't copied to the clipboard: no \$DISPLAY or pbcopy" >&2
fi

if $errors; then
	exit 1
fi

