include_recipe "python"

package "python-m2crypto"
package "python-crypto"

begin
  creds = data_bag_item('percona', 'backup_creds')

rescue => e
  Chef::Log.debug("unable to find global db data bag")
  Chef::Log.debug( e.backtrace.join( "\n" ) )
  raise e
end

# Create the mysql backup dir
directory "/var/lib/mysql-backup" do
  mode   0755
  user   "root"
  group  "root"
  action :create
end

# Create the mysql backup dir
directory "/etc/mysql-backup" do
  mode   0755
  user   "root"
  group  "root"
  action :create
end

if !creds.nil?
  if node['percona'].has_key?('hpcloud') and node['percona']['hpcloud']

    python_pip "python-swiftclient" do
      action :install
    end
  
    template "/etc/mysql-backup/.swiftenv" do
      source    "swift_env.erb"
      mode      0644
      action    :create
      variables({ :tenant_name => creds['tenant_name'],
                  :tenant_id => creds['tenant_id'],
                  :username    => creds['username'],
                  :auth_url    => creds['auth_url'],
                  :region_name => creds['region_name'],
                  :password    => creds['password'] })
    end
  end

  # AES KEY
  template "/etc/mysql-backup/.backup.key" do
    source    "backup.key.erb"
    mode      0644
    action    :create
    variables({ :backup_key => creds['backup_key'] })
  end

else
  Chef::Log.error("creds not set for backup, did you set node['percona']['backup_creds_set'] to something sensible in the environment?")
end

# backup script
cookbook_file "/usr/local/bin/backup.py" do
  source    "backup.py"
  mode      0755
  action    :create
end

# restore script
cookbook_file "/usr/local/bin/restore.py" do
  source    "restore.py"
  mode      0755
  action    :create
end

# the following code is to stagger backups
# across nodes in the cluster
hostnum = node['hostname'][/(\d+)/]
hostnum = hostnum.to_i

# the following code is to stagger cron jobs
# across cluster nodes
cron_days = Array.new()
diw = 6
cluster_members = search("node", "role:#{node['percona']['cluster_member_role']} AND chef_environment:#{node.chef_environment}") || []
cluster_members = cluster_members.length
if cluster_members == 0 
  cluster_members = 1
end

while hostnum <= diw do
  cron_days.push(hostnum)
  hostnum += cluster_members
end

cron_days_string = cron_days.join(',')


cron "percona_backup" do
  action :delete
end
cron "percona_backup" do
  action :create
  minute 0
  hour 01
  day cron_days_string
  user "root"
  command ". /etc/mysql-backup/.swiftenv && /usr/local/bin/backup.py"
end
