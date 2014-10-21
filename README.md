shared-photo-stream-backupper
=============================

A tool to identify and back up photos in an iCloud Shared Photo Stream to a given directory.

Gems Required:
==============
* Rsync
* Sqlite3

Examples:
=========
As a quick reference, here's the help text:
```bash
$ ./photo_stream_backup.rb -h
Usage: photo_stream_backup.rb [options]
  -s, --streams X,Y,Z              The name of one or more streams that will be backed up, use "all" to back all of them up
  -d, --destination DEST           The destination folder for the images found, ie ~/Dropbox, etc
  -v, --[no-]verbose               Run verbosely
  -h, --help                       Display this screen
```

and here's what an example run looks like:
```bash
$ ./photo_stream_backup.rb -s all -d '~/icloud_test'
  Backing up stream 'Wife and Life'
  Backing up 169 images...
  Backing up stream 'Family pics'
  Backing up 239 images...
```
