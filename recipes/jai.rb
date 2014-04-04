#
# Cookbook Name:: geoserver
# Recipe:: jai
#
# Copyright 2013, NREL
#
# All rights reserved - Do Not Redistribute
#

include_recipe "java"

remote_file "#{Chef::Config[:file_cache_path]}/jai-1_1_3-lib-linux-amd64.tar.gz" do
  source "http://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64.tar.gz"
  checksum "4bf0d26acbedc9e203059b18f8a1a7bfef0b448cb5515b8c1b530706e68eb75a"
end

remote_file "#{Chef::Config[:file_cache_path]}/jai_imageio-1_1-lib-linux-amd64.tar.gz" do
  source "http://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64.tar.gz"
  checksum "78f24c75b70a93b82de05c9a024574973f2ee71c25bf068d470e5abd511fb49a"
end

bash "install_jai" do
  cwd Chef::Config[:file_cache_path]
  user "root"
  group "root"
  code <<-EOS
    tar -xvf jai-1_1_3-lib-linux-amd64.tar.gz && \
    cd jai-1_1_3 && \
    cp lib/*.so #{node[:java][:java_home]}/jre/lib/amd64/ && \
    cp lib/*.jar #{node[:java][:java_home]}/jre/lib/ext/ && \
    cd .. && \
    rm -rf jai-1_1_3
  EOS
  not_if { ::File.exists?("#{node[:java][:java_home]}/jre/lib/amd64/libclib_jiio.so") }
end

bash "install_jai_imageio" do
  cwd Chef::Config[:file_cache_path]
  user "root"
  group "root"
  code <<-EOS
    tar -xvf jai_imageio-1_1-lib-linux-amd64.tar.gz && \
    cd jai_imageio-1_1 && \
    cp lib/*.so #{node[:java][:java_home]}/jre/lib/amd64/ && \
    cp lib/*.jar #{node[:java][:java_home]}/jre/lib/ext/ && \
    cd .. && \
    rm -rf jai_imageio-1_1
  EOS
  not_if { ::File.exists?("#{node[:java][:java_home]}/jre/lib/amd64/libclib_jiio.so") }
end
