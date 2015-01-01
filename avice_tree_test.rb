
require_relative 'avice_tree.rb'
require 'pry'



root = MediaContainer.new(nil, ["avice"])

test1 = MediaItem.new(["avice","track1"], "art1", "alb1", "gen1", 1, "http://blah1")

test2 = MediaItem.new(["avice", "album1", "track2"] , "art2", "alb2", "gen2", 1, "http://blah2")

binding.pry

