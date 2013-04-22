
node.set['build_essential']['compiletime'] = true
include_recipe "build-essential"
include_recipe "percona::client"
package "libmysqlclient-dev" do
  action :nothing
end.run_action(:install)
chef_gem "mysql"

mysql_connection_info = {:host => "localhost", :username => 'root', :password => node['percona']['root_password']}

mysql_database_user 'xtrabackup' do
  connection mysql_connection_info
  host '%'
  password node['percona']['xtrabackup_password']
  privileges ['reload', 'lock tables', 'replication slave', 'replication client']
  action :grant
end

mysql_database_user 'clustercheck' do
  connection mysql_connection_info
  host 'localhost'
  password node['percona']['xtrabackup_password']
  privileges [:process]
  action :grant
end

