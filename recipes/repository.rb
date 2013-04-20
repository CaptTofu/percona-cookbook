include_recipe "apt"

# Repository Install
apt_repository "percona" do
  uri "http://repo.percona.com/apt"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "pool.sks-keyservers.net"
  key "CD2EFD2A"
  notifies :run, resources(:execute => "apt-get update"), :immediately
end
