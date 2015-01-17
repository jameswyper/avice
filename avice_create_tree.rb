

require_relative 'avice_tree.rb'
require 'pry'
require 'sqlite3'


def makepath(genre, artist, composer,  album_artist, album, title, track, filename, path)
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

puts "Database output"
row.each { |r| puts r.to_s }
puts "Database output ends"

row.each do |r|
	tree_paths = makepath(r[2], r[3], r[4], r[5], r[6], r[8], r[7], r[0], r[1])
	tree_paths.each do |path| 
		puts  "Path: " + path.to_s
		MediaItem.new(path, r[3], r[6], r[2], r[7], r[8], "file://" + r[1] ) 
	end
end



MediaObject.run
