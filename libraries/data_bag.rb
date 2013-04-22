# Provide common functions for retrieving data bags according to the data bag naming schemed
# defined at https://wiki.hpcloud.net/display/iaas/Chef+Data+Bag+Usage
#
# Additionally all get_data* functions can take some options, specifically ':encrypted => true' will cause the functions to assume the
# data bag is encrypted. You can optionally specify a secret_file also, if not specified it defaults to the secret file for the base
# bag/item

module HP
  module Common

    #Return an encrypted data bag item, using the given secret_file or the default in /etc/chef/auto_edb_keys
    def get_encrypted_data_bag_item(bag, item, secret_file=nil)
      secret = Chef::EncryptedDataBagItem.load_secret(secret_file || "/etc/chef/auto_edb_keys/#{bag}_#{item}.key")
      return Chef::EncryptedDataBagItem.load(bag, item, secret)
    end

    #Return an array of environments matching this location, most specific to least, including leading _, and uspecificed region
    def get_envs()
      return [ "_#{node["continent"]}_#{node["area"]}_#{node["az"]}", "_#{node["continent"]}_#{node["area"]}", \
        "_#{node["continent"]}", ""] 
    end

    #Return item in the most specific bag, following the continent/area/az
    def get_data_bag(bag, item, options={})
      bags = Chef::DataBag.list.keys.select { |key| key.match("^#{bag}") }
      if bags.empty?
        retun nil
      end
      get_envs.each do |env|
        if bags.include?(bag + env) and data_bag(bag + env).include?(item)
          if options[:encrypted] == true
            return get_encrypted_data_bag_item(bag + env, item, options[:secret_file])
          else
            return Chef::DataBagItem.load(bag + env, item)
          end
        end
      end
    end
        
    #Return a merged item from the bags that match continent/area/az
    def get_merged_data_bag(bag, item, options={})
      bags = Chef::DataBag.list.keys.select { |key| key.match("^#{bag}") }
      if bags.empty?
        retun nil
      end
      new_item = Chef::DataBagItem.new
      new_item.data_bag(bag)
      get_envs.reverse.each do |env| #Note get_env order is reversed
        if bags.include?(bag + env) and data_bag(bag + env).include?(item)
          #duplicate keys are repaced not merged
          if options[:encrypted] == true
            new_item.raw_data.merge! get_encrypted_data_bag_item(bag + env, item, options[:secret_file]).to_hash
          else
            new_item.raw_data.merge! Chef::DataBagItem.load(bag + env, item).raw_data
          end
        end
      end
      return new_item
    end

    #Return the item from items that matches continent/area/az standard
    def get_data_bag_item(bag, item, options={})
      items = Chef::DataBag.load(bag).keys.select { |key| key.match("^#{item}") }
      if items.empty?
        retun nil
      end
      get_envs.each do |env|
        if items.include?(item + env)
          if options[:encrypted] == true
            return get_encrypted_data_bag_item(bag, item + env, options[:secret_file])
          else
            return Chef::DataBagItem.load(bag, item + env)
          end
        end
      end
    end

    #Return the merged item from items that match continent/area/az standard
    def get_merged_data_bag_item(bag, item, options={})
      items = Chef::DataBag.load(bag).keys.select { |key| key.match("^#{item}") }
      if items.empty?
        retun nil
      end
      new_item = Chef::DataBagItem.new
      new_item.data_bag(bag)
      get_envs.reverse.each do |env| #Note get_env order is reversed
        if items.include?(item + env)
          #duplicate keys are repaced not merged
          if options[:encrypted] == true
            new_item.raw_data.merge! get_encrypted_data_bag_item(bag, item + env, options[:secret_file]).to_hash
          else
            new_item.raw_data.merge! Chef::DataBagItem.load(bag, item + env).raw_data
          end
        end
      end
      return new_item
    end
        
  end
end
