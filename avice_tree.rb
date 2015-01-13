#!/usr/bin/env ruby

require 'sqlite3'
require 'dbus'
require 'pry'



OBJECT_IFACE = "org.gnome.UPnP.MediaObject2"
CONTAINER_IFACE = "org.gnome.UPnP.MediaContainer2"
ITEM_IFACE = "org.gnome.UPnP.MediaItem2"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"
SERVICE_NAME = "org.gnome.UPnP.MediaServer2.Avice"
PATH_ROOT = "org/gnome/UPnP/MediaServer2"


# dbus path names can only contain alphanumeric characters plus _ and /
# this function will translate strings into a hex representation that
# only has the characters 0-9 and A-F thus meeting the restriction

def bin_to_hex(s)
  s.unpack('H*').first
end

# this function takes an array of strings and creates a dbus path out of them, converting the strings to hex (see function above) and separating each one with a slash

def path_to_dbus(a)
	#puts "path_to_dbus:" + a.to_s
	x = String.new
	x = PATH_ROOT + "/" + a[0]  
	if a.size > 1
		a[1..-1].each { |s| x += "/" + bin_to_hex(s) } 
	end
	return x
end


class MediaObject < DBus::Object
	@@nodeByPath = Hash.new
	
	attr_reader :pathElements, :propertyValuesObject2, :type

	def initialize (parent, pathElements, type)
		puts "MediaObject constructor:" + pathElements.to_s
		@parent = parent.dup unless parent == nil
		@pathElements = pathElements.dup
		@@nodeByPath[path_to_dbus(@pathElements)] = self
		@displayName = @pathElements[-1]
		@type = type
		@propertyValuesObject2 = Hash.new
		if parent != nil
			@propertyValuesObject2["Parent"] = path_to_dbus(@parent.pathElements)
		else
			@propertyValuesObject2["Parent"] = path_to_dbus(pathElements)
		end
		@propertyValuesObject2["Type"] = @type
		@propertyValuesObject2["Path"] = path_to_dbus(pathElements)
		@propertyValuesObject2["DisplayName"] = @displayName
		super (path_to_dbus(pathElements))  
		@@service.export(self)
		puts "Created " + pathElements.to_s
		@@nodeByPath.each { |k,v| puts k.to_s + "=>" + v.pathElements.to_s }
	end
	
	def remove
		@@nodeByPath.delete(path_to_dbus(@pathElements))
	end
	
	
	
 	@@bus = DBus.session_bus
 	@@service = @@bus.request_service(SERVICE_NAME)
	

	def MediaObject.run
		loop = DBus::Main.new
		loop << @@bus
		loop.run
	end

end


class MediaContainer < MediaObject
	
	attr_reader :propertyValues, :child_items, :child_containers
	
	def initialize (parent, pathElements)
		
		super(parent, pathElements, "container")
		
		@children = Array.new
		@child_items = Array.new
		@child_containers = Array.new
		@propertyValues = Hash.new
		@propertyValues["Searchable"] = false
		@propertyValues["ChildCount"] = 0
		@propertyValues["ItemCount"] = 0
		@propertyValues["ContainerCount"] = 0
	end

	def remove
		super
	end

	def addChild(child, sortorder)
		puts "in addChild routine"
		@children << [sortorder,child]
		@children.sort_by! { |x| if x[0].instance_of?(Fixnum) then sprintf("%03i",x[0]) else x[0] end }
		if child.type == "container"
			@child_containers << [sortorder,child]
			@child_containers.sort_by! { |x| x[0] }
			puts "added a container "+ child.pathElements.to_s + "to " + self.pathElements.to_s
		else
			@child_items << [sortorder,child]
			@child_items.sort_by! { |x| x[0] }
			puts "added an item "+ child.pathElements.to_s + "to " + self.pathElements.to_s
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
			highest = s - 1
		else
			highest = offset + max - 1
		end
		puts "getDataForList #{@displayname} #{offset} #{highest}, request properties #{propertiesReq}"
		#binding.pry
		child_array[offset..highest].each do |cref|
			child = cref[1]
			allProperties = child.propertyValues.merge(child.propertyValuesObject2)
			if propertiesReq == ["*"]
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
		#binding.pry
		return response
	end

	dbus_interface PROPERTIES_IFACE do
		dbus_method :Get, "in iface:s, in name:s, out value:v" do |iface, name|
			
			rvalue = Array.new	
			
			case iface
			when OBJECT_IFACE
				rvalue << @propertyValuesObject2.fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}" }
			when CONTAINER_IFACE
				rvalue << @propertyValues.fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}"  }
			when ""
				rvalue << @propertyValues.merge(@propertyValuesObject2).fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}"  }
			else
				raise DBus.error, "Could not find interface #{iface} when looking for property #{name}"
			end
			
			[rvalue]
		end

		dbus_method :GetAll, "in iface:s, out values:a{sv}" do |iface|
			
			rvalues = Hash.new
			puts "GetAll for #{iface} called"
			#binding.pry
			case iface
			when OBJECT_IFACE
				rvalues = @propertyValuesObject2
			when CONTAINER_IFACE
				rvalues = @propertyValues
			when ""
				rvalues = @propertyValuesObject2.merge(@propertyValues)
			else
				raise DBus.error, "Could not find interface #{iface} when getting all properties"
			end
			puts rvalues.to_s
			[rvalues]
		end
	end
	
	dbus_interface CONTAINER_IFACE do
		
		dbus_method :ListChildren, "in offset:u, in max:u, in filter:as, out values:aa{sv}" do |offset, max, filter|
			puts "ListChildren called for " + @displayName
			rvalues = getDataForList(@children,offset,max,filter)
			#binding.pry
			[rvalues]
		end
		
		dbus_method :ListItems , "in offset:u, in max:u, in filter:as, out values:aa{sv}"do |offset, max, filter|
			rvalues = getDataForList(@child_items,offset,max,filter)
			[rvalues]
		end
		
		dbus_method :ListContainers, "in offset:u, in max:u, in filter:as, out values:aa{sv}" do |offset, max, filter|
			rvalues = getDataForList(@child_containers,offset,max,filter)
			[rvalues]
		end
		
		dbus_method :SearchObjects do
			raise DBus.error("org.freedesktop.DBus.Error.NotSupported") #need to confirm this is right
		end
	end


end

class MediaItem < MediaObject
	
	attr_reader :propertyValues	
	
	def initialize(pathElements,artist,album,genre,track,url)

# run through the path from start to end, check containers exist, if they don't create them

		puts "mediaitem initialise " + pathElements.to_s
		pathElements[0..-2].each_index do |c|
			puts "path level " + c.to_s
			puts "looking for " + pathElements[0..c].to_s
			puts "dbus path " + path_to_dbus(pathElements[0..c])
			if @@nodeByPath[path_to_dbus(pathElements[0..c])] == nil
				puts "not found, will create " + pathElements[0..c].to_s + " name " + pathElements[c] + "under parent " + pathElements[0..c-1].to_s
				if c < 1
					raise "Can't find root container"
				end
				parent = @@nodeByPath[path_to_dbus(pathElements[0..c-1])]
				parent.addChild(MediaContainer.new(parent, pathElements[0..c]),pathElements[c])
			end
		end

# set up the item

		puts "Will place item under " + pathElements[0..-2].to_s
		parent = @@nodeByPath[path_to_dbus(pathElements[0..-2])]
		if parent == nil then raise "parent not found!" end
		super(parent, pathElements, "music")
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
	
	dbus_interface PROPERTIES_IFACE do
		dbus_method :Get, "in iface:s, in name:s, out value:v" do |iface, name|
			
			rvalue = Array.new	
			
			case iface
			when OBJECT_IFACE
				rvalue << @propertyValuesObject2.fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}" }
			when ITEM_IFACE
				rvalue << @propertyValues.fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}"  }
			when ""
				rvalue << @propertyValues.merge(@propertyValuesObject2).fetch(name) { |x| raise DBus.error, "Could not find property #{x} in #{iface}"  }
			else
				raise DBus.error, "Could not find interface #{iface} when looking for property #{name}"
			end
			
			rvalue
		end

		dbus_method :GetAll, "in iface:s, out values:a{sv}" do |iface|
			
			rvalues = Hash.new
			
			case iface
			when OBJECT_IFACE
				rvalues = @propertyValuesObject2
			when ITEM_IFACE
				rvalues = @propertyValues
			when ""
				rvalues = @propertyValuesObject2.merge(@propertyValues)
			else
				raise DBus.error, "Could not find inteface #{iface} when getting all properties"
			end
			[rvalues]
		end
	end
end








