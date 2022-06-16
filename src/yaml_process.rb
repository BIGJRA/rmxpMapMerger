$LOAD_PATH.unshift File.dirname(__FILE__)

require 'yaml'
require 'tmpdir'
require_relative '../rmxp/rgss_internal.rb'
require_relative '../rmxp/rgss_mod.rb'
require_relative '../rmxp/rgss_rpg.rb'
require_relative '../rmxp/rgss.rb'

def load_yaml(yaml_file)
  data = nil
  File.open( yaml_file, "r+" ) do |input_file|
    data = YAML::unsafe_load( input_file )
  end
  return data['root']
end

def merge_tables(table1, table2)
  # returns a Table class with the merged data of table1, table2
  return

# puts load_yaml("DataExport/Map059 - Peridot Ward.yaml").events
