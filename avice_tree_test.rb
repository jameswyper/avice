
require_relative 'avice_tree.rb'
require 'pry'



root = MediaContainer.new(nil, ["avice"])

test1 = MediaItem.new(["avice","track1"], "art1", "alb1", "gen1", 1, "http://blah1")

MediaItem.new(["avice", "album1", "track2"] , "art2", "alb2", "gen2", 1, "http://blah2")
MediaItem.new(["avice", "album1", "track3"] , "art2", "alb2", "gen2", 2, "http://blah3")
MediaItem.new(["avice", "genre", "album2", "track1"] , "art2", "alb2", "gen2", 1, "http://blah4")

def dump(container, depth)
	puts ("++" * depth) + container.path.to_s
	if container.type == "container"
		container.child_containers.each do |c|
			dump(c[1], depth + 1)
		end
		container.child_items.each do |i|
			#binding.pry
			puts ("--" * (depth + 1)) + i[1].path.to_s
		end
	end
end

puts "------------------------------"
dump(root,0)



#binding.pry

