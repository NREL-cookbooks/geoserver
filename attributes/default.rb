#
# Cookbook Name:: geoserver
# Attributes:: geoserver
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

default[:geoserver][:path] = "/opt/geoserver"
default[:geoserver][:version] = "2.4.1"
default[:geoserver][:url] = "http://superb-dca2.dl.sourceforge.net/project/geoserver/GeoServer/#{geoserver[:version]}/geoserver-#{geoserver[:version]}-war.zip"
default[:geoserver][:archive_checksum] = "71761abe68945fcdd8739512d3c91c1e986cdd4679d5915094d5abfb1c119cb5"

default[:geoserver][:data_dir] = "#{geoserver[:path]}/data"
