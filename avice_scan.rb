#!/usr/bin/env ruby

require 'sqlite3'
require 'fileutils'
require 'pathname'
require 'mp3info'
require 'pry'
#require 'shellwords'

require_relative 'avice_id.rb'



def mp3scan(path)
	
	count = 0
	total = 0
	yield "Initialising scan", count, total
	
	set = Array.new
	fields = [['title','TIT2'],['albumartist','TPE2'],['genre','TCON'],['track','TRCK'],['artist','TPE1'],['album','TALB'],['composer','TCOM']]
	 
	# get a list of all files with .mp3 extension below the path
	list = Dir[path+'/**/*.mp3']
	
	total = list.size
	
	yield total.to_s + " files to scan", count, total
	
	#loop through each file
	list.each do |fn|
		h = Hash.new
		
		# call the id3v2 utility with the filename and store the output in rl
		begin
			
			Mp3Info.open(fn) do |mp3|
		
				#binding.pry
				
				h['title'] = mp3.tag.title
				h['artist'] = mp3.tag.artist
				h['albumartist'] = mp3.tag.TPE2
				h['composer'] = mp3.tag.TCOM
				h['album'] = mp3.tag.album
				h['genre'] = mp3.tag.genre_s
				h['track'] = mp3.tag.tracknum
				h['length'] = mp3.length
				h['bitrate'] = mp3.bitrate
			
			
			end
		
			set << [fn.dup, h.dup]
		
		rescue
			puts "Errant filename is " + fn
		
		end
		
		count = count + 1
		if (count  % 100 == 0)
			yield "Scanned " + count.to_s + " of " + total.to_s + " files (" + sprintf('%0.1f', ((count.to_f*100)/total)) + "%)", count, total
		end
	end
	
	yield "Scanning complete", count, total
	
	return set
	
end



def scan_and_store(cmd_path, cmd_ext)

	db = SQLite3::Database.new 'data.db'

	row = db.execute('select id, path, type from md_folderpath where path = ?', cmd_path)


	if row.size != 0
		puts "row exists"
		r = row[0]
		id=r[0].to_i
		path = r[1]
		type = r[2]
		db.execute('delete from md_track where md_folderpath_id = ?', id)
	else
		path = cmd_path
		id = get_id(db, 'md_folderpath')
		db.execute('insert into md_folderpath (id, path, type) values (?, ?, ?)', id, cmd_path, cmd_ext)
	end

	set = mp3scan(path) { |msg, count, total| puts msg }

	db.transaction

	track_id = get_id(db, 'md_track',set.size)
	set.each do |s|
		sp = Pathname.new(s[0])
		sh = s[1]
		db.execute('insert into md_track (md_folderpath_id, id, filename, path, genre, artist, composer, album_artist, 
		     album , track , title , other_tags ) 
		     values(?,?,?,?,?,?,?,?,?,?,?,?)',
		         id, track_id,sp.basename.to_s,s[0], sh['genre'],
			sh['artist'], sh['composer'], sh['albumartist'], sh['album'], 
			sh['track'],sh['title'], " "
			)
		track_id = track_id + 1
	end
	
	db.commit
	db.close if db

end



#cmd_path = '/home/james/Music/mp3/originals/classical'
#cmd_ext = 'mp3'

scan_and_store('/home/james/Music/mp3/originals/jazz', 'mp3')
#scan_and_store('/home/james/Music/mp3/converted/flac/classical', 'mp3')
