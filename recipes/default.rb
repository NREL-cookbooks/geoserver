#
# Cookbook Name:: geoserver
# Recipe:: default
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "ark"
include_recipe "tomcat"

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
::Chef::Recipe.send(:include, Chef::Recipe::GeoServer)

node.set_unless[:geoserver][:admin_password] = secure_password
node.set_unless[:geoserver][:root_password] = secure_password

if(!password_matches(node[:geoserver][:admin_password_digest], node[:geoserver][:admin_password]))
  node.set[:geoserver][:admin_password_digest] = password_digest(node[:geoserver][:admin_password])
end

if(!password_matches(node[:geoserver][:root_password_digest], node[:geoserver][:root_password]))
  node.set[:geoserver][:root_password_digest] = password_digest(node[:geoserver][:root_password])
end

node.save unless Chef::Config[:solo]

ark "geoserver" do
  action :put
  name ::File.basename(node[:geoserver][:path])
  path ::File.dirname(node[:geoserver][:path])
  url node[:geoserver][:url]
  version node[:geoserver][:version]
  checksum node[:geoserver][:archive_checksum]
  strip_leading_dir false
end

template "#{node[:tomcat][:context_dir]}/geoserver.xml" do
  source "tomcat_context.xml.erb"
  owner node[:tomcat][:user]
  group node[:tomcat][:group]
  mode "0644"
  notifies :restart, "service[tomcat]"
end

%w(security/usergroup/default).each do |dir|
  directory "#{node[:geoserver][:data_dir]}/#{dir}" do
    recursive true
    owner node[:tomcat][:user]
    group node[:tomcat][:group]
    mode "0755"
  end
end 

file "#{node[:geoserver][:data_dir]}/security/masterpw.info" do
  action :delete
end

file "#{node[:geoserver][:data_dir]}/security/masterpw.digest" do
  content "digest1:#{node[:geoserver][:root_password_digest]}"
  notifies :restart, "service[tomcat]"
end

template "#{node[:geoserver][:data_dir]}/security/usergroup/default/users.xml" do
  source "users.xml.erb"
  owner node[:tomcat][:user]
  group node[:tomcat][:group]
  mode "0644"
  notifies :restart, "service[tomcat]"
end
