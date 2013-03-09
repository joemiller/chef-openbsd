OpenBSD Chef Resources
======================

This cookbook includes basic LWRPs for OpenBSD. Included resources are:

- Package
- Service

Package resource
----------------

The package resource is loosely based on the FreeBSD package resource included
with Chef except it does not include support for compiling from ports. Use
this resource to install compiled packages, such as from an openbsd ftp mirror.

### Setting $PKG_PATH

OpenBSD's pkg_add and pkg_info tools use the $PKG_PATH variable to find
packages. This recipe supports setting a default PKG_PATH for all packages
or explicitly setting a PKG_PATH for individual packages.

Set the `node['openbsd']['pkg_path']` variable to assign a default for all
packages.

Alternatively, the `source` attribute may be set on an individual package
resource to specify an alternate $PKG_PATH, eg:

    package "thttpd" do
      source "ftp://ftp.dom.tld/packages/i386"
    end


Any PKG_PATH accepted by pkg_add and pkg_info should work fine, such as FTP,
HTTP, local path. (Only tested with ftp)

### Package install

Most packages can be installed by specifying their base name, eg:

    package "git"

Some packages have multiple versions or flavors and these need to be explicitly
defined using the `version` attribute.

This recipe does not currently support picking a package automatically if there
are multiple flavors available. You need to explicitly set the version and
flavor in these cases. eg:

    package "vim" do
      version "7.3.154p2-no_x11"
    end

    package "python" do
      version "2.7.3p0"
    end

Service resource
----------------

This resource is based on the FreeBSD Service resource included with Chef and
is compatible with OpenBSD 5.x which uses the `rc.d` method for service script
management.

OpenBSD's `rc.d` includes a few differences from FreeBSD that this resource
handles for you.

Enabled services are added to the `/etc/rc.conf.local` file so that
`/etc/rc.conf` is left untouched, simplifying openbsd upgrades.

Passing parameters to the service is doing by setting the `:flags` attribute
on the `parameters` hash.

### Usage

    service "ntpd" do
      parameters({:flags => "-s"})
      action [:enable, :start]
    end

    service "ftpproxy" do
      action [:enable, :start]
    end

Author
------

* [Joe Miller](https://twitter.com/miller_joe) - http://joemiller.me / https://github.com/joemiller

License
-------

    Author:: Joe Miller (<joeym@joeym.net>)
    Copyright:: Copyright (c) 2013 Joe Miller
    License:: Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
