#
# Cookbook Name:: apache
# Recipe:: ssl
#
# Copyright 2011, OpenStreetMap Foundation
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
include_recipe "ssl"

apache_module "ssl"

template "/etc/apache2/conf.d/ssl" do
  source "ssl.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :reload, resources(:service => "apache2")
end

service "apache2" do
  action :nothing
  subscribes :restart, resources(:cookbook_file => "/etc/ssl/certs/rapidssl.pem")
  subscribes :restart, resources(:cookbook_file => "/etc/ssl/certs/openstreetmap.pem")
  subscribes :restart, resources(:file => "/etc/ssl/private/openstreetmap.key")
end