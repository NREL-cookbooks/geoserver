#
# Cookbook Name:: geoserver
# Attributes:: geoserver
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

default[:geoserver][:version] = "2.9.1"
default[:geoserver][:url] = "http://pilotfiber.dl.sourceforge.net/project/geoserver/GeoServer/#{geoserver[:version]}/geoserver-#{geoserver[:version]}-war.zip"
default[:geoserver][:archive_checksum] = "206e3cc250e9ee46986bbb889cba69a57efea624f90f723ca042d09dc9c8059c"
default[:geoserver][:source_url] = "https://github.com/geoserver/geoserver/archive/#{geoserver[:version]}.tar.gz"
default[:geoserver][:data_dir] = "/opt/geoserver-data"
