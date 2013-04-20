# Based on https://github.com/phlipper/chef-percona/blob/master/libraries/passwords.rb
# Apache 2.0 License
class Chef
  class Recipe
    class PerconaPasswords
      attr_accessor :node, :bag

      def initialize(node, bag = "passwords")
        @node = node
        @bag  = bag
      end

      # Helper for retrieving passwords
      def find_password(key, user, default=nil)

        # First, let's check for an encrypted data bag
        begin
          passwords = Chef::EncryptedDataBagItem.load(@bag, key)
          # now, let's look for the user password
          password = passwords[user]
        rescue
          Chef::Log.warn("Encrypted password for #{key}:#{user} not found")

          # Second, let's check for an non-encrypted data bag
          begin
            passwords = Chef::DataBagItem.load(@bag, key)
            # now, let's look for the user password
            password = passwords[user]
          rescue
            Chef::Log.warn("Non-Encrypted password for #{key}:#{user} not found")
          end
        end

        # password will be nil if no encrypted data bag was loaded
        # fall back to the attribute on this node
        password ||= default
      end

      # MySQL Root Password
      def root_password
        find_password "mysql", "root", @node[:percona][:root_password]
      end

      # MySQL debian password
      def debian_password
        find_password "mysql", "debian-sys-maint", @node[:percona][:debian_password]
      end

      # MySQL Xtrabackup password
      def xtrabackup_password
        find_password "mysql", "xtrabackup", @node[:percona][:xtrabackup_password]
      end

      # MySQL Xtrabackup password
      def clustercheck_password
        find_password "mysql", "clustercheck", @node[:percona][:clustercheck_password]
      end

      # MySQL PowerDNS
      def powerdns_password
        find_password "mysql", "powerdns", @node[:percona][:powerdns_password]
      end

      # MySQL Datadog
      def datadog_password
        find_password "mysql", "datadog", @node[:percona][:datadog_password]
      end

    end
  end
end
