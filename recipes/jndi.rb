#
# Cookbook Name:: geoserver
# Recipe:: jndi
#
# Copyright 2014, NREL
#
# All rights reserved - Do Not Redistribute
#

ruby_block "geoserver_jndi_cleanup_old_postgres_jars" do
  block do
    require "fileutils"
    jars = Dir.glob("#{node[:tomcat][:lib_dir]}/postgresql*jdbc*.jar")
    jars.each do |path|
      if(File.basename(path) != node[:geoserver][:jndi][:postgresql_jar_filename])
        FileUtils.rm(path)
      end
    end
  end
  action :nothing
end

remote_file "#{node[:tomcat][:lib_dir]}/#{node[:geoserver][:jndi][:postgresql_jar_filename]}" do
  source "http://jdbc.postgresql.org/download/#{node[:geoserver][:jndi][:postgresql_jar_filename]}"
  checksum node[:geoserver][:jndi][:postgresql_jar_checksum]
  notifies :run, "ruby_block[geoserver_jndi_cleanup_old_postgres_jars]"
  notifies :restart, "service[tomcat]"
end
