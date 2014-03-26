#
# Cookbook Name:: geoserver
# Attributes:: geoserver
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

default[:geoserver][:version] = "2.5"
default[:geoserver][:url] = "http://superb-dca2.dl.sourceforge.net/project/geoserver/GeoServer/#{geoserver[:version]}/geoserver-#{geoserver[:version]}-war.zip"
default[:geoserver][:archive_checksum] = "ec3baa17dd45c9a6a1100a72f74c893456f37f06a2169f07ed4dcbb4b352941b"
default[:geoserver][:source_url] = "http://superb-dca2.dl.sourceforge.net/project/geoserver/GeoServer/#{geoserver[:version]}/geoserver-#{geoserver[:version]}-src.zip"
default[:geoserver][:data_dir] = "#{ark[:prefix_root]}/var/data/geoserver"
