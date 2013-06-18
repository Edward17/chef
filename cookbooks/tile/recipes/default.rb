#
# Cookbook Name:: tile
# Recipe:: default
#
# Copyright 2013, OpenStreetMap Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "apache"
include_recipe "git"
include_recipe "nodejs"
include_recipe "postgresql"

blocks = data_bag_item("tile", "blocks")

apache_module "alias"
apache_module "expires"
apache_module "headers"
apache_module "remoteip"
apache_module "rewrite"

apache_module "tile" do
  conf "tile.conf.erb"
end

tilecaches = search(:node, "roles:tilecache")

apache_site "default" do
  action [ :disable ]
end

apache_site "tile.openstreetmap.org" do
  template "apache.erb"
  variables :caches => tilecaches
end

template "/etc/logrotate.d/apache2" do
  source "logrotate.apache.erb"
  owner "root"
  group "root"
  mode 0644
end

directory "/srv/tile.openstreetmap.org" do
  owner "tile"
  group "tile"
  mode 0755
end

package "renderd"

service "renderd" do
  action [ :enable, :start ]
  supports :status => false, :restart => true, :reload => false
end

directory node[:tile][:tile_directory] do
  owner "tile"
  group "www-data"
  mode 0775
end

if node[:tile][:tile_directory] != "/srv/tile.openstreetmap.org/tiles"
  link "/srv/tile.openstreetmap.org/tiles" do
    to node[:tile][:tile_directory]
  end
end

template "/etc/renderd.conf" do
  source "renderd.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, resources(:service => "apache2")
  notifies :restart, resources(:service => "renderd")
end

remote_directory "/srv/tile.openstreetmap.org/html" do
  source "html"
  owner "tile"
  group "tile"
  mode 0755
  files_owner "tile"
  files_group "tile"
  files_mode 0644
end

directory "/srv/tile.openstreetmap.org/cgi-bin" do
  owner "tile"
  group "tile"
  mode 0755
end

template "/srv/tile.openstreetmap.org/cgi-bin/export" do
  source "export.erb"
  owner "tile"
  group "tile"
  mode 0755
  variables :blocks => blocks
end

directory "/srv/tile.openstreetmap.org/data" do
  owner "tile"
  group "tile"
  mode 0755
end

node[:tile][:data].each do |name,data|
  url = data[:url]
  file = "/srv/tile.openstreetmap.org/data/#{File.basename(url)}"
  directory = "/srv/tile.openstreetmap.org/data/#{data[:directory]}"

  directory directory do
    owner "tile"
    group "tile"
    mode 0755
  end

  if file =~ /\.tgz$/
    package "tar"

    execute file do
      action :nothing
      command "tar -zxf #{file} -C #{directory}"
      user "tile"
      group "tile"
    end
  elsif file =~ /\.tar\.bz2$/
    package "tar"

    execute file do
      action :nothing
      command "tar -jxf #{file} -C #{directory}"
      user "tile"
      group "tile"
    end
  elsif file =~ /\.zip$/
    package "unzip"

    execute file do
      action :nothing
      command "unzip -qq #{file} -d #{directory}"
      user "tile"
      group "tile"
    end
  end

  if data[:processed]
    original = "#{directory}/#{data[:original]}"
    processed = "#{directory}/#{data[:processed]}"

    package "gdal-bin"

    execute processed do
      action :nothing
      command "ogr2ogr #{processed} #{original}"
      user "tile"
      group "tile"
      subscribes :run, resources(:execute => file), :immediately
    end
  end

  remote_file file do
    action :create_if_missing 
    source url
    owner "tile"
    group "tile"
    mode 0644
    notifies :run, resources(:execute => file), :immediately
    notifies :restart, resources(:service => "renderd")
  end
end

nodejs_package "carto"
nodejs_package "millstone"

directory "/srv/tile.openstreetmap.org/styles" do
  owner "tile"
  group "tile"
  mode 0755
end

node[:tile][:styles].each do |name,details|
  style_directory = "/srv/tile.openstreetmap.org/styles/#{name}"
  tile_directory = "/srv/tile.openstreetmap.org/tiles/#{name}"

  file "#{tile_directory}/planet-import-complete" do
    action :create_if_missing
    owner "tile"
    group "tile"
    mode 0444
  end

  git style_directory do
    action :sync
    repository details[:repository]
    revision details[:revision]
    user "tile"
    group "tile"
  end

  link "#{style_directory}/data" do
    to "/srv/tile.openstreetmap.org/data"
    owner "tile"
    group "tile"
  end

  execute "#{style_directory}/project.mml" do
    command "carto project.mml > project.xml"
    cwd style_directory
    user "tile"
    group "tile"
    not_if do
      File.exist?("#{style_directory}/project.xml") and
      File.mtime("#{style_directory}/project.xml") >= File.mtime("#{style_directory}/project.mml")
    end
    notifies :touch, "file[#{tile_directory}/planet-import-complete]"
    notifies :restart, "service[renderd]"
  end
end

package "postgis"

postgresql_user "jburgess" do
  cluster node[:tile][:database][:cluster]
  superuser true
end

postgresql_user "tomh" do
  cluster node[:tile][:database][:cluster]
  superuser true
end

postgresql_user "tile" do
  cluster node[:tile][:database][:cluster]
end

postgresql_user "www-data" do
  cluster node[:tile][:database][:cluster]
end

postgresql_database "gis" do
  cluster node[:tile][:database][:cluster]
  owner "tile"
end

postgresql_extension "postgis" do
  cluster node[:tile][:database][:cluster]
  database "gis"
end

[ "geography_columns",
  "planet_osm_nodes",
  "planet_osm_rels",
  "planet_osm_ways",
  "raster_columns", 
  "raster_overviews", 
  "spatial_ref_sys" ].each do |table|
  postgresql_table table do
    cluster node[:tile][:database][:cluster]
    database "gis"
    owner "tile"
    permissions "tile" => :all
  end
end

[ "geometry_columns", 
  "planet_osm_line", 
  "planet_osm_point", 
  "planet_osm_polygon", 
  "planet_osm_roads" ].each do |table|
  postgresql_table table do
    cluster node[:tile][:database][:cluster]
    database "gis"
    owner "tile"
    permissions "tile" => :all, "www-data" => :select
  end
end

postgresql_munin "gis" do
  cluster node[:tile][:database][:cluster]
  database "gis"
end

#if node[:tile][:node_file]
#  file node[:tile][:node_file] do
#    owner "tile"
#    group "tile"
#    mode 0664
#  end
#end

package "osm2pgsql"
package "osmosis"

package "ruby"
package "rubygems"

package "libproj-dev"
package "libxml2-dev"
package "libpq-dev"

gem_package "proj4rb"
gem_package "libxml-ruby"
gem_package "pg"

remote_directory "/usr/local/lib/site_ruby" do
  source "ruby"
  owner "root"
  group "root"
  mode 0755
  files_owner "root"
  files_group "root"
  files_mode 0644
end

template "/usr/local/bin/expire-tiles" do
  source "expire-tiles.erb"
  owner "root"
  group "root"
  mode 0755
end

directory "/var/lib/replicate" do
  owner "tile"
  group "tile"
  mode 0755
end

directory "/var/log/replicate" do
  owner "tile"
  group "tile"
  mode 0755
end

template "/var/lib/replicate/configuration.txt" do
  source "replicate.configuration.erb"
  owner "tile"
  group "tile"
  mode 0644
end

template "/usr/local/bin/replicate" do
  source "replicate.erb"
  owner "root"
  group "root"
  mode 0755
end

template "/etc/init.d/replicate" do
  source "replicate.init.erb"
  owner "root"
  group "root"
  mode 0755
end

service "replicate" do
  action [ :enable, :start ]
  supports :restart => true
  subscribes :restart, resources(:template => "/usr/local/bin/replicate")
  subscribes :restart, resources(:template => "/etc/init.d/replicate")
end

template "/etc/logrotate.d/replicate" do
  source "replicate.logrotate.erb"
  owner "root"
  group "root"
  mode 0644
end

munin_plugin "mod_tile_fresh"
munin_plugin "mod_tile_response"
munin_plugin "mod_tile_zoom"

munin_plugin "renderd_processed"
munin_plugin "renderd_queue"
munin_plugin "renderd_zoom"
munin_plugin "renderd_zoom_time"

munin_plugin "replication_delay" do
  conf "munin.erb"
end
