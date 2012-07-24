package "glusterfs-server" do
	action :install
end


directory node[:glusterfs][:server][:export_directory] do
  recursive true
end

service "glusterd" do
  supports :status => true, :restart => true, :reload => true
  action :start
end

rule_before = `iptables -L INPUT --line-numbers | grep reject-with | awk '{print $1}'`.strip
execute "iptables for gluster #1" do
	command "iptables -I INPUT #{rule_before} -m state --state NEW -m tcp -p tcp --dport 24007:24008 -j ACCEPT"
	not_if "iptables -L -n | grep 24007 | grep ACCEPT"
end

execute "iptables for gluster #2" do
	command "iptables -I INPUT #{rule_before} -m state --state NEW -m tcp -p tcp --dport 24009:24014 -j ACCEPT"
	not_if "iptables -L -n | grep 24009 | grep ACCEPT"
end

# build peers
# peer는 먼저 있어야하고, 한 곳에서 peer 등록하면 된다.
# 따라서 리스트의 첫번째 녀석이 담당하는 것으로 한다
is_first_node = node[:glusterfs][:server][:peers].index(node['ipaddress']) == 0

if node[:glusterfs][:server][:peers].index(node['ipaddress']) == 0 then
	node[:glusterfs][:server][:peers].each do |peer|
		# peer 추가
		execute "gluster peer probe #{peer}" do
			not_if "gluster peer status | grep '^Hostname: #{peer}'" 
			not_if { peer == node['ipaddress'] }
		end

		# peer의 brick추가
		node[:glusterfs][:server][:volumes].each do |volume|
			execute "gluster volume add-brick #{volume} #{peer}:/#{volume}" do
				not_if "gluster volume info #{volume} | grep '#{peer}:/#{volume}$'"
				only_if "gluster volume info | grep -c '^Volume Name: #{volume}'$"
				only_if "gluster volume info #{volume} | grep 'Status: Started'"
			end
		end
	end
end


peers = node[:glusterfs][:server][:peers].map{|x| "#{x}:/test"}.join(' ')

# volume create & starts
# peer가 3개 이상 있어야하고 첫번째 것이 담당한다.
node[:glusterfs][:server][:volumes].each do |volume|
	if is_first_node and `gluster volume info | grep -c '^Volume Name: #{volume}$'`.to_i == 0 and `gluster peer status | grep ^Hostname -c`.to_i >= 2 then
		peers = `gluster peer status | grep ^Hostname | awk '{print $2}'`.split.map{|x| "#{x}:/#{volume}"}.join(' ')

		execute "gluster volume create #{volume} replica 2 #{peers}" do
			not_if "gluster volume info | grep -c '^Volume Name: #{volume}'$"
		end

		execute "gluster volume start #{volume}" do
			not_if "gluster volume info #{volume} | grep 'Status: Started'"
		end
	end
end

