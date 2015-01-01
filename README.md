Avice
=====

Avice is a Media hierarchy backend for the Gnome Rygel UPnP server.  It reads metadata from your media collection (currently mp3 files only) and creates a tree structure that is then made accessible to Rygel via DBus.

(see https://wiki.gnome.org/Projects/Rygel/MediaServer2Spec)

I've started work on Avice because I have a large collection of music files (~20000), half of which are classical.  To navigate through these on a UPnP player I needed a UPnP server that will

(a) recognise the composer tag on my mp3 files

(b) create a sensible tree structure (e.g. composer/artist and composer/album for classical) without having too many branches at any one time (so "All Artists"/A/Artists beginning with A, "All Artists"/B/Artists beginning with B and so on, rather than just showing all artists which would mean navigating through a list of hundreds of them in my case)

My requirements used to be met by mediatomb which allowed you to create a custom tree structure.  However the "composer" tag was only readable by patching the source code, and as of the end of 2014 mediatomb will no longer compile on recent distributions of Linux unless the custom tree functionality is disabled.  

So I'm starting my own project which will (at least initially) do as little as possible to meet my needs - piggybacking on Rygel rather than writing my own UPnP code for example.  

Avice is written in Ruby.  At the moment it is about halfway towards alpha code. The name is a small tribute to the character Avice Benner Cho from China Mieville's novel Embassytown.

avice_scan is a script to read metadata from a collection of mp3 files. It will scan directories recursively.  At the moment the script needs to be edited (at the end of the file, should be obvious how) to enter the correct starting directory.  The metadata is stored in a sqlite database file which can be initialised by running the avice_dbcreate script.

avice_id is a small helper script purely concerned with creating unique id fields for the database.

avice_tree is a set of classes implementing the MediaServer2 specification.  This code is mostly written but untested.  The idea is that creating an instance of MediaItem will represent one entry in the media hierarchy exported to Rygel.  The classes will take care of creating MediaContainer and MediaObject objects automatically.

avice_xxxx (yet to be written) will read through the sqlite database and for each file create one or more entries in the media hierarchy (by creating MediaItem objects).

Software Requirements:

id3v2
sqlite3

Ruby packages: pry dbus sqlite3
