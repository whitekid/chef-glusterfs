maintainer        ""
maintainer_email  ""
license           "Apache 2.0"
description       "Installs and configures gluster for client or server"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "0.0.1"
recipe            "glusterfs", "Includes the client recipe to configure a client"
recipe            "glusterfs::client", "Installs packages required for glusterfs clients using run_action magic"
recipe            "glusterfs::server", "Installs packages required for glusterfs servers"

%w{ centos }.each do |os|
  supports os
end

depends "yum"
