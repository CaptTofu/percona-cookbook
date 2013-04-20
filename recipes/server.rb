include_recipe "percona::client"
include_recipe "percona::repository"

# Find the other cluster members
cluster_members = search("node", "role:#{node['percona']['cluster_member_role']} AND chef_environment:#{node.chef_environment}") || []

# reduce the cluster_members down to just the IPs
cluster_members.map! do |member|
  server_ip = begin
      member['ipaddress']
  end
end

# Reject ourselves from the list, just in case
cluster_members.reject! do |member|
  member == node['ipaddress']
end

# Reject nil's from the list
cluster_members.reject! do |member|
  member == nil
end

# Determine if we are bootstrapping a new cluster
# TODO: If the server package is already installed, then bootstrap_cluster == false
bootstrap_cluster = cluster_members.length == 0

Chef::Log.warn("Bootstrapping Cluster? #{bootstrap_cluster.to_s}")
Chef::Log.warn("Cluster member count: #{cluster_members.length.to_s}")
Chef::Log.warn("Cluster members: #{cluster_members.join(',')}")

# Define the MySQL Service
service "mysql" do
   supports :status => true, :restart => true, :reload => true
   action :nothing
end

# Constuct the cluster address
wsrep_cluster_address = 'gcomm://'

# if not bootstrapping, then we want to add members to the list
# hence this is not set to be the primary
if bootstrap_cluster == false
  wsrep_cluster_address += cluster_members.join(',')
end

# Create the mysql config (and directory)
directory "/etc/mysql" do
  mode   0755
  user   "root"
  group  "root"
  action :create
end

wsrep_node_address = node['ipaddress']

template "/etc/mysql/my.cnf" do
  source    "my.cnf.erb"
  mode      0644
  action    :create
  variables({ 
    :wsrep_cluster_address => wsrep_cluster_address, 
    # are there cases when we would want this to be the private ip?
    # use node.set['percona']['multi_az_cluster'] as a flag for requiring the public ip?
    :wsrep_node_address    => wsrep_node_address
  })
end

# Create debian.cnf, the password contained within will be used by the percona
# installer, preventing a random password from being generated on each server.
template "/etc/mysql/debian.cnf" do
  source   "debian.cnf.erb"
  mode     0600
  action   :create
  variables({ :debian_password => node['percona']['debian_password']})
end

# Install default file, increasing the init.d script timeout
cookbook_file "/etc/default/mysql" do
  source    "mysql.default"
  mode      0644
  action    :create
end

# Prepare a .my.cnf for the root user
template "/root/.my.cnf" do
  source   "dot.my.cnf.erb"
  mode     0600
  action   :create
  variables({ :username => 'root', :password => node['percona']['root_password']})
end

# Prepare a debconf seed for percona
execute "install percona preseed" do
  action  :nothing
  command "debconf-set-selections /tmp/percona.preseed"
end

template "/tmp/percona.preseed" do
  source   "percona.preseed.erb"
  mode     0600
  action   :create
  variables({:root_password => node['percona']['root_password']})
  notifies :run, resources(:execute => "install percona preseed"), :immediately
end

# install the cluster server package
package "percona-xtradb-cluster-server-5.5"

# Setup any necessary users
include_recipe "percona::users"

if bootstrap_cluster == true
  include_recipe "percona::appsetup"
end

# Install the clustercheck service
include_recipe "percona::clustercheck"

# Install backups
include_recipe "percona::backup"
