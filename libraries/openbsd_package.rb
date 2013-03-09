#
# Author:: Joe Miller (https://github.com/joemiller / https://twitter.com/miller_joe)
# Copyright:: Copyright (c) 2013 Joe Miller
# License:: Apache License, Version 2.0
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

require 'chef/provider/package'
require 'chef/mixin/shell_out'
require 'chef/resource/package'
require 'chef/platform'

class Chef
  class Provider
    class Package
      class Openbsd < Package
        include Chef::Mixin::ShellOut

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(current_installed_version)
          @candidate_version = candidate_versions

          Chef::Log.debug("Candidate version is #{@candidate_version}") if @candidate_version
          Chef::Log.debug("#{@new_resource} current version is #{@current_resource.version}") if @current_resource.version

          # default source (ie: PKG_PATH for pkg_add) to node setting if not explicitly set by the resource
          if @new_resource.source.nil?
            @new_resource.source(node['openbsd']['pkg_path'])
          end
          @current_resource
        end

        def candidate_versions
          if @new_resource.version
            return @new_resource.version
          else
            return ''
          end
        end

        def current_installed_version
          pkg_info = shell_out!("pkg_info \"#{@new_resource.package_name}\"", :env => nil, :returns => [0,1])
          pkg_info.stdout[/Information for inst:#{@new_resource.package_name}-(\S+)/, 1]
        end

        def install_package(name, version)
          pkg_spec = version == '' ? name : "#{name}-#{version}"
          pkg_add = shell_out!("pkg_add #{pkg_spec}", :env => { "PKG_PATH" => @new_resource.source , 'LC_ALL'=>nil})

          # XXX: in many cases pkg_add will exit with status 0 even during error
          # conditions resulting in no pkg installed. Instead, we check for text on
          # stderr to detect an error preventing install (not tested for all cases)
          if pkg_add.stderr != ''
            raise Chef::Exceptions::Package, pkg_add.stderr
          end
          pkg_add.exitstatus
        end

        def remove_package(name, version)
          pkg_spec = version == '' ? name : "#{name}-#{version}"
          shell_out!("pkg_delete #{pkg_spec}").status
        end

        # @TODO(joe): upgrades are not well tested yet.
        def upgrade_package(name, version)
          if @current_version.nil? or @current_version.empty?
            install_package(name, version)
          else
            pkg_spec = version == '' ? name : "#{name}-#{version}"
            pkg_add = shell_out!("pkg_add -u -F update -F updatedepends #{pkg_spec}",
                                 :env => { "PKG_PATH" => @new_resource.source , 'LC_ALL'=>nil})
            if pkg_add.stderr != ''
              raise Chef::Exceptions::Package, pkg_add.stderr if pkg_add.stderr != ''
            end
            pkg_add.exitstatus
          end
        end

      end
    end
  end
end

Chef::Platform.set :platform => :openbsd, :resource => :package, :provider => Chef::Provider::Package::Openbsd
