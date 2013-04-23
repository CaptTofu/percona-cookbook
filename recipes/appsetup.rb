
# pull in the mysql client libs etc
node.set['build_essential']['compiletime'] = true
include_recipe "build-essential"
include_recipe "percona::client"
package "libmysqlclient-dev" do
  action :nothing
end.run_action(:install)
chef_gem "mysql"

begin
  global_db_data_bag = data_bag_item('percona', 'applications')
rescue => e
  Chef::Log.debug("unable to find global db data bag")
  Chef::Log.debug( e.backtrace.join( "\n" ) )
end

# set up the application schema, user, password
if global_db_data_bag and global_db_data_bag.has_key?('applications')
  application_hash = global_db_data_bag['applications']

  application_hash.keys.sort.each do |db_schema|
    create_schema = application_hash[db_schema]['create_schema']
    db_user = application_hash[db_schema]['db_user']
    db_password = application_hash[db_schema]['db_password']

    Chef::Log.info "setting up #{db_schema} schema, #{db_user} user"

    mysql_connection_info = {:host => "localhost", :username => 'root', :password => node['percona']['root_password']}
 
    if create_schema
      # create a mysql database called #{db_schema}
      mysql_database db_schema do
        connection mysql_connection_info
        encoding 'utf8'
        action :create
      end   
    end

    mysql_database_user db_user do
      connection mysql_connection_info
      host '%'
      database_name db_schema
      password db_password
      privileges [:all]
      action :grant
    end

  end
end

