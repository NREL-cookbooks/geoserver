#
# Cookbook Name:: geoserver
# Recipe:: default
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "ark"
include_recipe "java"

::Chef::Recipe.send(:include, OpenSSLCookbook::RandomPassword)

node.set_unless[:geoserver][:admin_password] = random_password
node.set_unless[:geoserver][:root_password] = random_password

if(!GeoServer.password_matches(node[:geoserver][:admin_password_digest], node[:geoserver][:admin_password]))
  node.set[:geoserver][:admin_password_digest] = GeoServer.password_digest(node[:geoserver][:admin_password])
end

if(!GeoServer.password_matches(node[:geoserver][:root_password_digest], node[:geoserver][:root_password]))
  node.set[:geoserver][:root_password_digest] = GeoServer.password_digest(node[:geoserver][:root_password])
end

node.save unless Chef::Config[:solo]

# For better fonts for rendering in legends.
package "urw-fonts"

tomcat_install "geoserver" do
  version "8.0.35"
end

tomcat_service "geoserver" do
  action [:enable, :start]
end

tomcat_user = "tomcat_geoserver"
tomcat_group = "tomcat_geoserver"
tomcat_dir = "/opt/tomcat_geoserver"

ark "geoserver" do
  action :install
  url node[:geoserver][:url]
  version node[:geoserver][:version]
  checksum node[:geoserver][:archive_checksum]
  strip_components 0
  prefix_root "/opt"
  prefix_home "/opt"
  notifies :restart, "tomcat_service[geoserver]"
end

template "#{tomcat_dir}/conf/Catalina/localhost/geoserver.xml" do
  source "tomcat_context.xml.erb"
  owner tomcat_user
  group tomcat_group
  mode "0644"
  variables({
    :geoserver_root => "/opt/geoserver",
  })
  notifies :restart, "tomcat_service[geoserver]", :immediately
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
    mkdir -p #{File.dirname(node[:geoserver][:data_dir])}
    rsync -av #{tomcat_dir}/webapps/geoserver/data/ #{node[:geoserver][:data_dir]}/
    chown -R #{tomcat_user}:#{tomcat_group} #{node[:geoserver][:data_dir]}
  EOS
  not_if { ::File.exists?(File.join(node[:geoserver][:data_dir], "workspaces")) }
end

file "#{node[:geoserver][:data_dir]}/security/masterpw.info" do
  action :delete
end

file "#{node[:geoserver][:data_dir]}/security/masterpw.digest" do
  content "digest1:#{node[:geoserver][:root_password_digest]}"
  notifies :restart, "tomcat_service[geoserver]"
end

template "#{node[:geoserver][:data_dir]}/security/usergroup/default/users.xml" do
  source "users.xml.erb"
  owner tomcat_user
  group tomcat_group
  mode "0644"
  notifies :restart, "tomcat_service[geoserver]"
end
