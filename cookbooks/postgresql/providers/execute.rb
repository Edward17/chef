#
# Cookbook Name:: postgresql
# Provider:: postgresql_execute
#
# Copyright 2012, OpenStreetMap Foundation
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

def load_current_resource
  @pg = Chef::PostgreSQL.new(new_resource.cluster)

  @current_resource = Chef::Resource::PostgresqlExecute.new(new_resource.name)
  @current_resource.cluster(new_resource.cluster)
  @current_resource.database(new_resource.database)
  @current_resource
end

action :nothing do
end

action :run do
  options = { :database => new_resource.database, :user => new_resource.user, :group => new_resource.group }

  if ::File.exist?(new_resource.command)
    @pg.execute(options.merge(:file => new_resource.command))
  else
    @pg.execute(options.merge(:command => new_resource.command))
  end

  new_resource.updated_by_last_action(true)
end
