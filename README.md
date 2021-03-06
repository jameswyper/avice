Avice
=====

Avice is a Media hierarchy backend for the Gnome Rygel UPnP server.  It reads metadata from your media collection (currently mp3 files only) and creates a customisable tree structure that is then made accessible to Rygel via DBus.

Put it another way:  Rygel + Avice = Flexible UPnP media server  - at least that's the plan :)

I've started work on Avice because I have a large collection of music files (~20000), half of which are classical.  To navigate through these on a UPnP player I needed a UPnP server that will

(a) recognise the composer tag on my mp3 files

(b) create a sensible tree structure (e.g. composer/artist and composer/album for classical) without having too many branches at any one time (so "All Artists"/A/Artists beginning with A, "All Artists"/B/Artists beginning with B and so on, rather than just showing all artists which would mean navigating through a list of hundreds of them in my case)

My requirements used to be met by mediatomb which allows you to create a custom tree structure.  However the "composer" tag was only readable by patching the source code, and as of the end of 2014 mediatomb will no longer compile on recent distributions of Linux unless the custom tree functionality is disabled.  When my last server died and I had to reinstall Ubuntu I kissed my mediatomb installation goodbye, but haven't found anything to replace it.

So I'm starting my own project which will (at least initially) do as little as possible to meet my needs - piggybacking on Rygel rather than writing my own UPnP code for example.  

The name is a small tribute to the character Avice Benner Cho from China Mieville's novel Embassytown.  In the book, she has to bridge an impossible communications gap.  Programming with DBus sometimes feels much the same way.

Avice is written in Ruby.  At the moment it is about halfway towards alpha code. It's a collection of scripts:

avice_scan is a script to read metadata from a collection of mp3 files. It will scan directories recursively.  At the moment the script needs to be edited (at the end of the file, should be obvious how) to enter the correct starting directory.  The metadata is stored in a sqlite database file which can be initialised by running the avice_dbcreate script.

avice_id is a small helper script purely concerned with creating unique id fields for the database; I'll probably get rid of this in a later version

avice_tree is a set of classes implementing the MediaServer2 specification.  The idea is that creating an instance of MediaItem will represent one entry in the media hierarchy exported to Rygel.  The classes will take care of creating MediaContainer and MediaObject objects automatically.

avice_tree_test is a script to create some (dummy) entries in a media hierarchy and export them to rygel. I used this for testing.

avice_create_tree reads through the sqlite database and for each file create one or more entries in the media hierarchy (by creating MediaItem objects).  

Instructions

1.  Edit avice_scan.rb to point to your music
2.  Delete data.db if present and run avice_dbcreate.rb
3.  run avice_scan.rb
4.  (if you're feeling brave) edit the custom path creation code in avice_create_tree.rb
5.  run avice_create_tree.rb
6.  configure rygel to accept external plugins over DBus (change the section under [External] in rygel.conf to read "enabled=true")
7.  Run rygel (rygel will abort after 5 seconds if it can't find any media backends so ensure you have avice_tree_create running first)
8.  Start your UPnP client


Bugs and other issues:

- High memory usage (0.6GB for a tree of about 100,000 objects - this is 30,000 files which are duplicated at least once in the tree e.g. by artist and by album, or by composer / artist etc.)

- No internationalisation

- Very little exception handling

- May not handle files with missing metadata very well

Issues with Rygel (that I've reported to the rygel-dev team and will have a go at fixing when I have time):

- Rygel appears to want to read the entire media hierarchy tree into memory on startup, this works OK with ~1000 files but with my complete collection I get dbus timeouts.  I need to find out why this is necessary and if possible change it.

- Rygel serves all media containers as upnp class object.container, which causes at least one of my clients (a Roberts Stream 63i radio) to display tracks in title rather than tracknumber sequence. (Other clients using rygel + avice, and other servers with the same client work fine).


On my 64-bit 2ghz quad-core system (2008 vintage) avice_scan takes a small number of minutes to read through 30,000 mp3 files (100 or so per second, I think, depending on other disk activity). avice_create_tree.mp3 will craeate about 100,000 dbus objects from this at a rate of about 300/second and when done uses 0.6 GB of memory.

Software Requirements:

Ruby packages used: pry dbus sqlite3 mp3info - you need to install these via gem or your distro's package installer

Other software that I've found helpful: bustle, upnp-inspector, d-feet, djmount, eezupnp

References:

https://wiki.gnome.org/Projects/Rygel/MediaServer2Spec
