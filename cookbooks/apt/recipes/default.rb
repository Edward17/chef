#
# Cookbook Name:: apt
# Recipe:: default
#
# Copyright 2010, Tom Hughes
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

package "apt"
package "update-notifier-common"

file "/etc/motd.tail" do
  action :delete
end

execute "apt-update" do
  action :nothing
  command "/usr/bin/apt-get update"
end

template "/etc/apt/sources.list" do
  source "sources.list.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :run, resources(:execute => "apt-update")
end

apt_source "opscode" do
  template "opscode.list.erb"
  url "http://apt.opscode.com/"
  key "83EF826A"
end

apt_source "brightbox" do
  url "http://apt.brightbox.net/"
  key "0090DAAD"
end

apt_source "brightbox-ruby-ng" do
  url "http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu"
  key "C3173AA6"
end

apt_source "brightbox-ruby-ng-experimental" do
  url "http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu-experimental"
  key "C3173AA6"
end

apt_source "pitti-postgresql" do
  url "http://ppa.launchpad.net/pitti/postgresql/ubuntu"
  key "8683D8A2"
end

apt_source "ubuntugis-stable" do
  url "http://ppa.launchpad.net/ubuntugis/ppa/ubuntu"
  key "314DF160"
end

apt_source "ubuntugis-unstable" do
  url "http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu"
  key "314DF160"
end

apt_source "brianmercer-php" do
  url "http://ppa.launchpad.net/brianmercer/php/ubuntu"
  key "8D0DC64F"
end

apt_source "aw-drupal" do
  url "http://ppa.launchpad.net/aw/drupal/ubuntu"
  key "7D5AE8F6"
end

apt_source "openstreetmap" do
  url "http://ppa.launchpad.net/osmadmins/ppa/ubuntu"
  key "0AC4F2CB"
end

apt_source "proliant-support-pack" do
  template "hp.list.erb"
  url "http://downloads.linux.hp.com/SDR/downloads/ProLiantSupportPack"
  key "2689B887"
end

apt_source "management-component-pack" do
  template "hp.list.erb"
  url "http://downloads.linux.hp.com/SDR/downloads/ManagementComponentPack"
  key "2689B887"
end

apt_source "mapnik-v210" do
  url "http://ppa.launchpad.net/mapnik/v2.1.0/ubuntu"
  key "5D50B6BA"
end