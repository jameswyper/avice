Avice
=====

Avice is a Media hierarchy backend for the Gnome Rygel UPnP server.  It reads metadata from your media collection (currently mp3 files only) and creates a tree structure that is then made accessible to Rygel via DBus.

(see https://wiki.gnome.org/Projects/Rygel/MediaServer2Spec)

I've started work on Avice because I have a large collection of music files (~20000), half of which are classical.  To navigate through these on a UPnP player I needed a UPnP server that will

(a) recognise the composer tag on my mp3 files

(b) create a sensible tree structure (e.g. composer/artist and composer/album for classical) without having too many branches at any one time (so "All Artists"/A/Artists beginning with A, "All Artists"/B/Artists beginning with B and so on, rather than just showing all artists which would mean navigating through a list of hundreds of them in my case)

My requirements used to be met by mediatomb which allowed you to create a custom tree structure.  However the "composer" tag was only readable by patching the source code, and as of the end of 2014 mediatomb will no longer compile on recent distributions of Linux unless the custom tree functionality is disabled.  

So I'm starting my own project which will (at least initially) do as little as possible to meet my needs - piggybacking on Rygel rather than writing my own UPnP code for example.  

Avice is written in Ruby.

