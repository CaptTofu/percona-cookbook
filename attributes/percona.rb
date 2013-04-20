default[:percona][:cluster_member_role]       = "percona"

default[:percona][:root_password]             = "root"
default[:percona][:debian_password]           = "debian"
default[:percona][:xtrabackup_password]       = "xtrabackup"
default[:percona][:clustercheck_password]     = "clustercheck"

default[:percona][:wsrep_slave_threads]       = 4
default[:percona][:wsrep_sst_method]          = "xtrabackup"
default[:percona][:wsrep_cluster_name]        = "percona-cluster"
default[:percona][:wsrep_provider_options]    = "gcache.size=2G;"

default[:percona][:innodb_thread_concurrency] = 0
default[:percona][:innodb_buffer_pool_size]   = (node[:memory][:total].to_i * 0.6).to_i.to_s + 'K'
default[:percona][:innodb_log_buffer_size]    = '8M'
default[:percona][:innodb_flush_method]       = 'O_DIRECT'
default[:percona][:innodb_log_file_size]      = '500M'

default[:percona][:root_password]             = 'xyz123abc'
default[:percona][:debian_password]           = 'cba321zyx'
default[:percona][:clustercheck_password]     = '321xyzabc'
default[:percona][:xtrabackup_password]       = '321xyzabc'
