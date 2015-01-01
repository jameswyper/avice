#!/usr/bin/env ruby

require 'sqlite3'

db = SQLite3::Database.new 'data.db'

db.execute <<SQL

create table md_folderpath ( id integer, path text, type text);

SQL

db.execute <<SQL

create table md_track (md_folderpath_id integer, id integer, filename text, path text, genre text, artist text, composer text, album_artist text,
album text, track integer, title text, other_tags text);

SQL

db.execute <<SQL

create table nt_music_leaf (id integer, url text, mimetype text,  artist text, album text, track integer, title text,depth integer);


SQL

db.execute <<SQL

create table nt_leaf (id integer, music_leaf_id integer);

SQL

db.execute <<SQL

create table nt_container(id integer, item_id integer, parent_id integer, child_id integer, depth integer, name text);

SQL

db.execute('create table  xx_id (name text, id int)')