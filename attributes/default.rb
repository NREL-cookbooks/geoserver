#
# Cookbook Name:: geoserver
# Attributes:: geoserver
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

default[:geoserver][:version] = "2.9.0"
default[:geoserver][:url] = "http://pilotfiber.dl.sourceforge.net/project/geoserver/GeoServer/#{geoserver[:version]}/geoserver-#{geoserver[:version]}-war.zip"
default[:geoserver][:archive_checksum] = "eb28ec2623caf566fc587ad553fad8dc1a403ebb43b8b8c5b390279279e09abb"
default[:geoserver][:source_url] = "https://github.com/geoserver/geoserver/archive/#{geoserver[:version]}.tar.gz"
default[:geoserver][:data_dir] = "/opt/geoserver-data"
