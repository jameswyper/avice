#!/usr/bin/env ruby

require 'sqlite3'
require 'dbus'

# dbus path names can only contain alphanumeric characters plus _ and /
# this function will translate strings into a hex representation that
# only has the characters 0-9 and A-F thus meeting the restriction

OBJECT_IFACE = "org.gnome.UPnP.MediaObject2"
CONTAINER_IFACE = "org.gnome.UPnP.MediaContainer2"
ITEM_IFACE = "org.gnome.UPnP.MediaItem2"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"
SERVICE_NAME = "org.gnome.UPnP.MediaServer2.nqu"

def bin_to_hex(s)
  s.unpack('H*').first
end

def path_to_dbus(a)
	x = String.new
	a.each do |s|
		x<<(bin_to_hex(s))<<("/")
	end
	return x
end


class MediaObject < DBus::Object
	@@nodeByPath = Hash.new
	
	attr_reader :path, :propertyValuesObject2

	def initialize (parent, path, type)
		@parent = parent.dup unless parent == nil
		@path = path.dup
		@@nodeByPath[path_to_dbus(@path)] = self
		@displayname = @path[-1]
		@type = type
#		@@service.export(self)
		@propertyValuesObject2 = Hash.new
		if parent != nil
			@propertyValuesObject2["Parent"] = path_to_dbus(@parent.path)
		else
			@propertyValuesObject2["Parent"] = path_to_dbus(path)
		end
		@propertyValuesObject2["Type"] = @type
		@propertyValuesObject2["Path"] = path_to_dbus(path)
		@propertyValuesObject2["DisplayName"] = @displayname
		
		puts "Created " + path.to_s, @@nodeByPath.to_s
	end
	
	def remove
		@@nodeByPath.delete(path_to_dbus(@path))
	end
	
	
	
#	@@bus = DBus.session_bus
#	@@service = @@bus.request_service(SERVICE_NAME)


end


class MediaContainer < MediaObject
	
	attr_reader :propertyValues
	
	def initialize (parent, path)
		
		super(parent, path, "container")
		
		@children = Array.new
		@child_items = Array.new
		@child_containers = Array.new
		@propertyValues = Hash.new
		@propertyValues["Searchable"] = false
	end

	def remove
		super
	end

	def addChild(child, sortorder)
		@children << [sortorder,child]
		@children.sort_by! { |x| x[0] }
		if child.type == "container"
			@child_items << [sortorder,child]
			@child_items.sort_by! { |x| x[0] }
		else
			@child_containers << [sortorder,child]
			@child_containers.sort_by! { |x| x[0] }
		end
		self.childChanged
	end

	def childRemoved(child)
		
		[@children, @child_containers, @child_items].each do |a|
			a.each_index do |c|
				if a[c][1] == child
					a.delete_at(c)
				end
			end
		end
		
		if (@children.empty? && parent != nil)
			self.remove
			parent.childRemoved(self)
		end
		
		self.childChanged
	
	end
	
	def childChanged
		@propertyValues["ChildCount"] = @children.size
		@propertyValues["ItemCount"] = @child_items.size
		@propertyValues["ContainerCount"] = @child_containers.size
		
		#set up signal
	end

	def getDataForList(child_array, offset, max, propertiesReq)
		response = Array.new
		s = child_array.size
		if s < offset
			offset = s
		end
		if (s < (offset + max)) || (max == 0)
			highest = s
		else
			highest = offset + max
		end
		child_array[offset..highest].each do |cref|
			child = cref[1]
			allProperties = child.propertyValues.merge(child.propertyValuesObject2)
			if propertiesReq == "*"
				propertiesResponse = allProperties.to_a
			else
				propertiesResponse = Array.new
				propertiesReq.each do |p|
					propertiesResponse << allProperties[p] unless allProperties[p] == nil
					# need to check if this is expected behaviour ie what happens if requested property doesn't exist
				end
			end
			response << propertiesResponse
		end
		
	end
		

end

class MediaItem < MediaObject
	
	attr_reader :propertyValues	
	
	def initialize(path,artist,album,genre,track,url)

# run through the path from start to end, check containers exist, if they don't create them

#		puts "mediaitem initialise " + path
		path[0..-1].each_index do |c|
			puts "path level " + c.to_s
			puts "dbus path " + path_to_dbus(path[0..c])
			if @@nodeByPath[path_to_dbus(path[0..c])] == nil
				if c < 1
					raise "Can't find root container"
				end
				parent = @@nodeByPath[path_to_dbus(path[0..c-1])]
				parent.addChild(MediaContainer.new(parent, path[0..c]),path[c])
			end
		end


		parent = @@nodeByPath[path_to_dbus(path[0..-1])]
		super(parent, path, "music")
		@propertyValues=Hash.new
		@propertyValues["Artist"] = artist
		@propertyValues["Album"] = album
		@propertyValues["Genre"] = genre
		@propertyValues["TrackNumber"] =track
		@propertyValues["URLs"] = [url]
		@propertyValues["MIMEType"] = "audio/mpeg"
		parent.addChild(self,track)
		
	end
	
	def remove
		# check if parent is empty and if so delete it
		parent.childRemoved(self)
		super
	end
	
#	dbus_interface PROPERTIES_IFACE do
#		dbus_method :Get, "in iface:s, in name:s, out value:v" do |iface, name|
#			
#			value = Array.new	
#			
#			case iface
#			when OBJECT_IFACE
#				value << @propertyValuesObject2.fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}" }
#			when ITEM_IFACE
#				value << @propertyValues.fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}"  }
#			else
#				raise DBus.error, "Could not find interface #{iface} when looking for property #{name}"
#			end
#			
#			value
#		end
#		dbus_method :GetAll, "in iface:s, out values:e{sv}" do |iface|
#			
#			values = Hash.new
#			
#			case iface
#				return @propertyValuesObject2
#			when "org.gnome.UpnP.MediaItem2"
#				return @propertyValues
#			else
#				raise DBus.error, "Could not find inteface #{iface} when getting all properties"
#			end
#			
#		end
#	end

end








