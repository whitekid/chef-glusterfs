package "glusterfs-fuse" do
	action :install
end


node[:glusterfs][:client][:mount].each do |volume, mount_to|
	if not File.directory?(mount_to)
		directory mount_to do
		action :create
		recursive true
	  end
	end

	# mount -t glusterfs -o log-level=WARNING,log-file=/var/log/gluster.log 10.200.1.11:/test /mnt
	server =  node[:glusterfs][:server][:peers][0]
	mount mount_to do
		device "#{server}:/#{volume}"
		fstype "glusterfs"
		options "log-level=WARNING,log-file=/var/log/gluster.log"
	end
end
