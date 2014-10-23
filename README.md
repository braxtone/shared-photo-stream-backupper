shared-photo-stream-backupper
=============================

A tool to identify and back up photos in an iCloud Shared Photo Stream to a given directory.

Gems Required:
--------------
* Rsync
* Sqlite3

Examples:
---------
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
$ ./photo_stream_backup.rb -s all -d '~/Dropbox/Photos'
  Backing up stream 'My Most Awesome Photo Stream'
  Backing up 169 images...
  Backing up stream 'This Other Pretty Cool Photo Stream'
  Backing up 239 images...
```

Setup:
------
0) Install Dropbox

Instructions at https://www.dropbox.com/install?os=mac
Make sure you've got a folder in your Dropbox called `Photos`

1) Open a Terminal window

Open Finder and go to Utilities > Terminal

2) Install the required Ruby libraries:
```bash
sudo gem install rsync sqlite3
```
You'll be prompted to type your password, nothing will appear on screen (security reasons) so just type it and press Enter.

3) Download the code on this page using one of the following methods:

a) Via command line (in the same Terminal window):
```bash
cd ~/
git clone https://github.com/braxtone/shared-photo-stream-backupper.git
```

b) Via the Github Mac application:

See https://help.github.com/articles/working-with-repositories/#cloning for a great guide.

4) Install the workflow:

Open the shiny new folder full of coding awesomemess that you just downloaded via Finder. The easiest way to do this is go open a new Finder window, hit ⌘+⇧+G to open a specific folder, type `~/photo_stream_backupper`, and press Enter.

Once you have the folder open, double-click the `shared_photo_stream_backupper.workflow` file to install the workflow. You'll be asked if you want to install the folder action which you do, so click Install. If you're installing a newer version of the workflow, it might want to know if you're OK replacing whatever was there, so click Replace to confirm.

When you get the _Installation complete_ message, you're good to go. You can also take a look at the workflow and tweak the script by selecting _Open with Automator_.

5) Test

Now that the workflow is installed, you should test it out! Create a shared Photo Steam (http://help.apple.com/icloud/#mmc0cd7e99) if you haven't already, then add an image to it from the Photos app on your iThing. 

Within a minute or less, you should see a notification pop up on your Mac notifying you that new images have been copied over. Congrats!


To Do:
------

* Learn more about Automator workflows and allow a user to specify the directory that they want to back images up to
* More specific notifications about the number of images uploaded
* Come up with a snazzier name for this project, something clever to do with saving streams, windmills or something.
