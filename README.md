Bart's Imgur uploader bash script
=================================

- By Bart Nagel <bart@tremby.net>
- Improvements by Tino Sino <robottinosino@gmail.com>
- Other contributions from the [Github community][contributors]

[contributors]: https://github.com/tremby/imgur.sh/graphs/contributors

Purpose
-------

Upload images to [Imgur][imgur] via a small bash script.

[imgur]: https://imgur.com/

History
-------

This is the repository for the Bash script
which has been found on [Imgur's tools page][tools-old]
since way back in 2009, and now on
[their new tools page][tools-new].

I received infrequent but steady emails over the years
with thanks and suggestions for improvements.
A Google search shows the script has been reused and forked
many times over the years.
About time this had its own Git repository,
so maybe the improvements can find their way back to the source.

[tools-old]: http://imgur.com/tools
[tools-new]: https://help.imgur.com/hc/en-us/articles/209592766-Tools-for-Imgur

Requirements
------------

- `curl`

### Optional

- `xsel`, `xclip`, `pbcopy` (Mac), or `clip` (Windows)
  to automatically put the URLs on the X selection or clipboard
  for easy pasting

Instructions
------------

1. Put it somewhere in your path and maybe rename it

        mv imgur.sh ~/bin/imgur

   Or you could make a symlink instead.

2. Make it executable

        chmod +x ~/bin/imgur

3. *Optional, since I've provided a client ID:*
   add your [client id][settings]
   to the top of the script, replacing the provided one,
   or set it as the `IMGUR_CLIENT_ID` environment variable

[settings]: https://imgur.com/account/settings/apps

### Uploading images

- Single image

        imgur images/hilarious/manfallingover.jpg

- Single image from a URL

        imgur https://example.com/egg.png

- Multiple images

        imgur images/delicious/cake.png https://example.com/exciting/bungeejump.jpg

- Directly from a screenshot

        import png:- | imgur

  Note that the `import` command above is from Imagemagick,
  and will await a selection being made on screen.

The new URLs will be displayed
(and the delete page URLs will be displayed on stderr).
If you have `xsel`, `xclip`, or `pbcopy`,
the URLs will also be put on the X selection,
which you can then usually paste with a middle click.

If no filename is given, or if `-` is given as one of the arguments,
an image is read from standard input.

### Rate limits

There are some [rate limits][limits] with the API.
The daily upload limit is shared by everyone using the same client ID,
so if you're using the provided one and start to get errors,
you might consider using your own client ID.

[limits]: https://api.imgur.com/#limits
