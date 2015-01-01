
require_relative 'nqu_tree.rb'

path_root = ["org","gnome","UPnP", "MediaServer2", "nqu"]

root = MediaContainer.new(nil, path_root)

test1 = MediaItem.new(path_root << "track1", "art1", "alb1", "gen1", 1, "http://blah1")

test2 = MediaItem.new(path_root << ["album1", "track2"] , "art2", "alb2", "gen2", 1, "http://blah2")

