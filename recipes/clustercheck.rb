include_recipe "percona::client"

# Install xinetd
package "xinetd"

# Install the clustercheck script
template "/usr/bin/clustercheck" do
  source   "clustercheck.erb"
  mode     0755
  action   :create
  variables({ :clustercheck_password => node['percona']['clustercheck_password']})
end

# Create MySQLchk entry in /etc/services
execute "create mysqlchk service" do
  command %Q(echo "mysqlchk        9200/tcp                        # mysqlchk" >> /etc/services)
  not_if "grep 9200/tcp /etc/services"
end

# xinted service, should be configured by the xinetd package
# but we define it here so we can notify it to restart
service "xinetd" do
  action [:enable, :start]
end

# The percona xinetd.d script uses the wrong location. Symlink to make it work.
link "/usr/local/bin/clustercheck" do
  to "/usr/bin/clustercheck"
  # restart xinetd when all of the clustercheck bits are in place
  notifies :restart, resources(:service => "xinetd")
end

