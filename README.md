Bart's Imgur uploader bash script
=================================

- By Bart Nagel <bart@tremby.net>
- Improvements by Tino Sino <robottinosino@gmail.com>

Purpose
-------

Upload images to [Imgur](http://imgur.com/) via a small bash script.

History
-------

This is the repository for the Bash script which has been found on [Imgur's
tools page](http://imgur.com/tools) since way back in 2009.

I got infrequent but steady emails over the years with thanks and suggestions
for improvements. A Google search shows the script has been reused and forked
many times over the years. About time this had its own Git repository, so maybe
the improvements can find their way back to the source.

Requirements
------------

- `curl`

### Optional

- `xsel`, `xclip`, or `pbcopy`, to automatically put the URLs on the X selection
  for easy pasting

Instructions
------------

1. Put it somewhere in your path and maybe rename it

        mv imgur.sh ~/bin/imgur

2. Make it executable

        chmod +x ~/bin/imgur

3. *Optional, since I've provided a client ID:*
   add your [client id](https://imgur.com/account/settings/apps)
   to the top of the script, replacing the provided one,
   or set it as the `IMGUR_CLIENT_ID` environment variable

### Uploading images

- Single image

        imgur images/hilarious/manfallingover.jpg

- Multiple images

        imgur images/delicious/cake.png images/exciting/bungeejump.jpg

The URLs will be displayed (and the delete page URLs will be displayed on
stderr). If you have `xsel`, `xclip`, or `pbcopy`, the URLs will also be put on
the X selection, which you can then usually paste with a middle click.

### Rate limits

There are some [rate limits](https://api.imgur.com/#limits) with the API.
The daily upload limit is shared by everyone using the same client ID,
so if you're using the provided one and start to get errors,
you might consider using your own client ID.
