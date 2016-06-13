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
include_recipe "tomcat"

# For better fonts for rendering in legends.
package "urw-fonts"

# If not defined, set random passwords for the GeoServer users.
::Chef::Recipe.send(:include, OpenSSLCookbook::RandomPassword)
node.set_unless[:geoserver][:admin_password] = random_password
node.set_unless[:geoserver][:root_password] = random_password
if(!GeoServer.password_matches?(node[:geoserver][:admin_password_digest], node[:geoserver][:admin_password]))
  node.set[:geoserver][:admin_password_digest] = GeoServer.password_digest(node[:geoserver][:admin_password])
end
if(!GeoServer.password_matches?(node[:geoserver][:root_password_digest], node[:geoserver][:root_password]))
  node.set[:geoserver][:root_password_digest] = GeoServer.password_digest(node[:geoserver][:root_password])
end
node.save unless Chef::Config[:solo]

# Define the tomcat service again. This seems to be necessary with the tomcat
# v0.17 cookbook, or else our notifies below don't acknowledge the existence of
# the service within the tomcat cookbok's providers/instance.rb.
service node[:tomcat][:base_instance] do
  supports :restart => true, :status => true
  action [:enable, :start]
  retries 4
  retry_delay 30
end

# Unpack and install GeoServer using ark.
ark "geoserver" do
  action :install
  url node[:geoserver][:url]
  version node[:geoserver][:version]
  checksum node[:geoserver][:archive_checksum]
  strip_components 0
  prefix_root "/opt"
  prefix_home "/opt"
  notifies :restart, "service[#{node[:tomcat][:base_instance]}]"
end

# Create the geoserver data directory outside of the version-specific
# installation so upgrades between versions of geoserver are easier.
#
# The data directory appears to need certain boiler-plate data in place to run
# successfully, so we'll copy the default data directory from source.
remote_file "#{Chef::Config[:file_cache_path]}/geoserver-#{node[:geoserver][:version]}.tar.gz" do
  source node[:geoserver][:source_url]
  not_if { ::File.exists?(File.join(node[:geoserver][:data_dir], "workspaces")) }
end
bash "create_geoserver_data_dir" do
  cwd Chef::Config[:file_cache_path]
  user "root"
  group "root"
  code <<-EOS
    rm -rf geoserver-src
    mkdir geoserver-src
    tar -xvf #{Chef::Config[:file_cache_path]}/geoserver-#{node[:geoserver][:version]}.tar.gz -C geoserver-src --strip-components=1
    mkdir -p #{File.dirname(node[:geoserver][:data_dir])}
    rsync -av geoserver-src/data/release/ #{node[:geoserver][:data_dir]}/
    chown -R #{node[:tomcat][:user]}:#{node[:tomcat][:group]} #{node[:geoserver][:data_dir]}
    rm -rf geoserver-src
  EOS
  not_if { ::File.exists?(File.join(node[:geoserver][:data_dir], "workspaces")) }
end

# Install a tomcat context file for defining the GeoServer install location.
template "#{node[:tomcat][:context_dir]}/geoserver.xml" do
  source "tomcat_context.xml.erb"
  owner node[:tomcat][:user]
  group node[:tomcat][:group]
  mode "0644"
  variables({
    :geoserver_root => "/opt/geoserver",
  })
  notifies :restart, "service[#{node[:tomcat][:base_instance]}]"
end

users_xml_path = "#{node[:geoserver][:data_dir]}/security/usergroup/default/users.xml"
replace_or_add "geoserver_set_admin_password" do
  path users_xml_path
  pattern '<user.*name="admin".*>'
  line %(<user enabled="true" name="admin" password="digest1:#{node[:geoserver][:admin_password_digest]}"/>)
  not_if do
    doc = REXML::Document.new(File.read(users_xml_path))
    existing_password = doc.elements["/userRegistry/users/user[@name='admin']"].attributes["password"].gsub("digest1:", "")
    GeoServer.password_matches?(existing_password, node[:geoserver][:admin_password])
  end

  # Restart immediately so the new password can be used for the master password
  # API call below.
  notifies :restart, "service[#{node[:tomcat][:base_instance]}]", :immediately
end


# Update the master/root password.
#
# Use the API to do this, since it seems tricky to set this in the multiple
# required places otherwise.
ruby_block "geoserver_set_master_password" do
  block do
    require "net/http"
    require "uri"
    require "json"

    # Fetch the current master password, since it's required to set a new one.
    uri = URI.parse("http://127.0.0.1:8080/geoserver/rest/security/masterpw.json")
    request = Net::HTTP::Get.new(uri.path)
    request.basic_auth("admin", node[:geoserver][:admin_password])
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    if(response.code.to_i != 200)
      raise "Failed to fetch GeoServer master password via API: #{response.code.inspect} - #{response.body}"
    end
    old_password = JSON.parse(response.body)["oldMasterPassword"]

    # Set the new master password.
    request = Net::HTTP::Put.new(uri.path)
    request.basic_auth("admin", node[:geoserver][:admin_password])
    request.content_type = "application/json"
    request.body = JSON.dump({
      "oldMasterPassword" => old_password,
      "newMasterPassword" => node[:geoserver][:root_password],
    })

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    if(response.code.to_i != 200)
      raise "Failed to update GeoServer master password via API: #{response.code.inspect} - #{response.body}"
    end
  end

  # Retry in case tomcat is spinning up.
  retries 4
  retry_delay 30

  not_if do
    path = "#{node[:geoserver][:data_dir]}/security/masterpw.digest"
    if(::File.exist?(path))
      existing_password = ::File.read(path).strip.gsub("digest1:", "")
      GeoServer.password_matches?(existing_password, node[:geoserver][:root_password])
    else
      false
    end
  end
end
