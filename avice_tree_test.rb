
require_relative 'avice_tree.rb'
require 'pry'



root = MediaContainer.new(nil, ["Avice"])

test1 = MediaItem.new(["Avice","track1"], "art1", "alb1", "gen1", 1, "http://blah1")

MediaItem.new(["Avice", "album1", "track2"] , "art2", "alb2", "gen2", 1, "http://blah2")
MediaItem.new(["Avice", "album1", "track3"] , "art2", "alb2", "gen2", 2, "http://blah3")
MediaItem.new(["Avice", "genre", "album2", "track1"] , "art2", "alb2", "gen2", 1, "http://blah4")

def dump(container, depth)
	puts ("++" * depth) + container.pathElements.to_s
	puts ("**" * depth) + container.propertyValuesObject2["DisplayName"]
	if container.type == "container"
		container.child_containers.each do |c|
			dump(c[1], depth + 1)
		end
		container.child_items.each do |i|
			#binding.pry
			puts ("--" * (depth + 1)) + i[1].pathElements.to_s
			puts ("//" * depth) + i[1].propertyValuesObject2["DisplayName"]
		end
	end
end


puts "------------------------------"
dump(root,0)

MediaObject.run

#binding.pry

