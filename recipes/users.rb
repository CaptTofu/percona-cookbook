# This user is required for xtrabackup
execute "create xtrabackup user" do
  user    "root"
  command %Q(mysql -uroot -p#{node['percona']['root_password']} --execute="GRANT reload, lock tables, replication client ON *.* TO 'xtrabackup'@'localhost' IDENTIFIED BY '#{node['percona']['xtrabackup_password']}';")
  not_if  %Q(mysql -uxtrabackup -p#{node['percona']['xtrabackup_password']} --execute="SELECT 1;")
end

# This user is required for the HAProxy check
execute "create clustercheck user" do
  user    "root"
  command %Q(mysql -uroot -p#{node['percona']['root_password']} --execute="GRANT process ON *.* to 'clustercheck'@'localhost' IDENTIFIED BY '#{node['percona']['clustercheck_password']}';")
  not_if  %Q(mysql -uclustercheck -p#{node['percona']['clustercheck_password']} --execute="SELECT 1;")
end
