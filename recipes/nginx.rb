#
# Cookbook Name:: geoserver
# Recipe:: default
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "nginx"

template "#{node[:nginx][:dir]}/sites-available/geoserver" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, "service[nginx]"
end

nginx_site "geoserver"
