$LOAD_PATH.unshift File.dirname(__FILE__)

require 'yaml'
require 'rmxp/rgss_internal.rb'
require 'rmxp/rgss_mod.rb'
require 'rmxp/rgss_rpg.rb'
require 'rmxp/rgss.rb'


def load_yaml(yaml_file)
    data = nil
    File.open( yaml_file, "r+" ) do |input_file|
      data = YAML::unsafe_load( input_file )
    end
    return data['root']
  end

puts load_yaml("DataExport/Map059 - Peridot Ward.yaml").events
