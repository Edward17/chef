#
# Cookbook Name:: ntp
# Recipe:: default
#
# Copyright 2010, OpenStreetMap Foundation.
# Copyright 2009, Opscode, Inc
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

require "socket"

package "ntp"
package "ntpdate"
package "tzdata"

execute "dpkg-reconfigure-tzdata" do
  action :nothing
  command "/usr/sbin/dpkg-reconfigure -f noninteractive tzdata"
  user "root"
  group "root"
end

file "/etc/timezone" do
  owner "root"
  group "root"
  mode 0644
  content "#{node[:tz]}\n"
  notifies :run, resources(:execute => "dpkg-reconfigure-tzdata"), :immediately
end

service "ntp" do
  action [ :enable, :start ]
  supports :status => true, :restart => true
end

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "ntp")
end

munin_plugins = []

if node[:lsb][:release].to_f <= 8.04
  munin_plugins = [ "ntp_states" ]

  node[:ntp][:servers].each do |name|
    name = Socket.gethostbyname(name)[0].gsub!(/[.-]/, "_")

    munin_plugin "ntp_#{name}" do
      target "ntp_"
    end

    munin_plugins.push("ntp_#{name}")
  end

  munin_plugin "ntp_states"
else
  munin_plugins = [ "ntp_kernel_err", "ntp_kernel_pll_freq", "ntp_kernel_pll_off", "ntp_offset" ]

  munin_plugin "ntp_kernel_err"
  munin_plugin "ntp_kernel_pll_freq"
  munin_plugin "ntp_kernel_pll_off"
  munin_plugin "ntp_offset"
end

if File.directory?("/etc/munin/plugins")
  Dir.new("/etc/munin/plugins").each do |plugin|
    if plugin.match(/^ntp_/) and not munin_plugins.include?(plugin)
      munin_plugin plugin do
        action :delete
      end
    end
  end
end