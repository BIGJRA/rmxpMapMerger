$LOAD_PATH.unshift File.dirname(__FILE__)

require 'yaml'
require 'tmpdir'
require_relative 'common.rb'
require_relative '../rmxp/rgss_internal.rb'
require_relative '../rmxp/rgss_mod.rb'
require_relative '../rmxp/rgss_rpg.rb'
require_relative '../rmxp/rgss.rb'

def fix_map_yaml(map_yaml, map_numbers, delete_other_maps=true)
  # Makes sure remaining map has parent_id that is not deleted
  data = map_yaml
  top = map_numbers.slice(0)
  while map_numbers.include?(top)
    top = data[top].parent_id
  end
  data[map_numbers.slice(0)].parent_id = top

  # Deletes data on unnecessary maps
  if delete_other_maps
    for map_no in map_numbers.slice(1, map_numbers.length + 1)
      data.delete(map_no)
    end
  end

  data.each do |map_no, map_data|
    if map_numbers.include?(map_data.parent_id)
      # p map_no, map_data.parent_id
      map_data.parent_id = map_numbers.slice(0)
    end
  end

  return data
end

