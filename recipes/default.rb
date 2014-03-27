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
  action :install
  url node[:geoserver][:url]
  version node[:geoserver][:version]
  checksum node[:geoserver][:archive_checksum]
  strip_leading_dir false
  notifies :restart, "service[tomcat]"
end

template "#{node[:tomcat][:context_dir]}/geoserver.xml" do
  source "tomcat_context.xml.erb"
  owner node[:tomcat][:user]
  group node[:tomcat][:group]
  mode "0644"
  notifies :restart, "service[tomcat]"
end

remote_file "#{Chef::Config[:file_cache_path]}/geoserver-#{node[:geoserver][:version]}-src.zip" do
  source node[:geoserver][:source_url]
  not_if { ::File.exists?(node[:geoserver][:data_dir]) }
end

# Create the geoserver data directory outside of the version-specific
# installation so upgrades between versions of geoserver are easier.
#
# The data directory appears to need certain boiler-plate data in place to run
# successfully, so we'll base the data directory off of what's in the source
# download.
bash "create_geoserver_data_dir" do
  cwd Chef::Config[:file_cache_path]
  user "root"
  group "root"
  code <<-EOS
    unzip geoserver-#{node[:geoserver][:version]}-src.zip -d geoserver-#{node[:geoserver][:version]}-src && \
    mkdir -p #{File.dirname(node[:geoserver][:data_dir])} && \
    cp -r #{Chef::Config[:file_cache_path]}/geoserver-#{node[:geoserver][:version]}-src/data/release #{node[:geoserver][:data_dir]} && \
    chown -R #{node[:tomcat][:user]}:#{node[:tomcat][:group]} #{node[:geoserver][:data_dir]} && \
    rm -r geoserver-#{node[:geoserver][:version]}-src*
  EOS
  not_if { ::File.exists?(node[:geoserver][:data_dir]) }
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
