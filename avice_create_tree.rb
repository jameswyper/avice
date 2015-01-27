

require_relative 'avice_tree.rb'
require 'pry'
require 'sqlite3'


def makepath(genre, artist, composer,  album_artist, album, title, track, filename, path)
	#puts "File: #{path}/#{filename}"
	#puts "Artist:#{artist}:Album:#{album}:Title:#{title}:"
	treepaths = Array.new
	path = SERVER_NAME.dup
	path << "Artists" << artist[0] << artist << album << title
	treepaths << path.dup
	path = SERVER_NAME.dup
	#binding.pry
	path << "Genres" << genre << artist[0] << artist << album << title
	treepaths <<path.dup
	path = SERVER_NAME.dup
	path << "Albums" << album[0] << (album + " ("  + artist + ")" ) << title
	treepaths << path.dup
	if (genre == "Classical")
		path = SERVER_NAME.dup
		path << "Classical" << "Composer" << composer[0] << composer << artist << album << title
		treepaths << path.dup
	end
	return treepaths
end






root = MediaContainer.new(nil, SERVER_NAME)

db = SQLite3::Database.new 'data.db'

row = db.execute('select filename, path, genre, artist, composer, album_artist, album, track, title, other_tags from md_track')

db.close

#puts "Database output"
#row.each { |r| puts r.to_s }
#puts "Database output ends"

puts row.size.to_s + " entries to add"
c = 0


row.each do |r|
	
	r[2] = "--" if  (r[2].nil? || r[2].empty?)
	r[3] = "--" if  (r[3].nil? || r[3].empty?)
	r[4] = "--" if  (r[4].nil? || r[4].empty?)
	r[5] = "--" if  (r[5].nil? || r[5].empty?)
	r[6] = "--" if  (r[6].nil? || r[6].empty?)
	r[8] = "--" if  (r[8].nil? || r[8].empty?)
	r[7] = 0 if (r[7].nil?)
	tree_paths = makepath(r[2], r[3], r[4], r[5], r[6], r[8], r[7], r[0], r[1])
	tree_paths.each do |path| 
		puts  "Path: " + path.to_s
		begin
			MediaItem.new(path, r[3], r[6], r[2], r[7], r[8], "file://" + r[1] )
		rescue
			puts "Problem with " + r[1]
		end
	end
	c = c + 1
	if (c %  100 == 0)
		puts c.to_s + " out of " + row.size.to_s  
	end
end

#binding.pry

MediaObject.run
