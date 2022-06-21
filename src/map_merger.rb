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

def write_yaml(map_object, filename)
  #p YAML::dump(map_object)
  File.open(filename, "w+") do |output_file|
    yaml_content = YAML::dump({'root' => map_object})
    #p yaml_content
    output_file.write(yaml_content)
  end
end

def get_merged_map(yaml_maps)
  maps = yaml_maps
  # returns a map object which contains the data of the merged map.
  id = maps[0].tileset_id
  for map in maps[1...maps.length()]
    if map.tileset_id != id
      puts "These maps use different tilesets. Quitting..."
      return 
    end
  end

  tables = maps.map {|map| map.data}
  merged_table = merge_tables(tables)

  merged_map = RPG::Map.new(merged_table.xsize, merged_table.ysize) # change these values later
  merged_map.tileset_id = id
  merged_map.autoplay_bgm = maps[0].autoplay_bgm
  merged_map.bgm = maps[0].bgm
  merged_map.autoplay_bgs = maps[0].autoplay_bgs
  merged_map.bgs = maps[0].bgs
  merged_map.encounter_list = maps[0].encounter_list
  merged_map.encounter_step = maps[0].encounter_step
  merged_map.autoplay_bgm = maps[0].autoplay_bgm
  merged_map.events = maps[0].autoplay_bgm # will change this
  merged_map.data = merged_table # will change this
  #merged_map.width = maps[0].width # will change this?
  #merged_map.height = maps[0].height # will change this?
  return merged_map
end

def merge_tables(table_array)
  # returns a Table class with the merged data of table1, table2
  return get_horizontal_slice(table_array) # for now just one horizontal slice
end

def get_horizontal_slice(table_array)
  # Assumes all the data arrays in the array will fit within the 500 pixel horizontal limit
  # Produces a horizontal slice with 0 filled in in the excess vertical space

  def get_layer(table, layer_num)
    layer_area = table.xsize * table.ysize
    return table.data.slice(layer_area * layer_num, layer_area)
  end

  max_height = 0
  for table in table_array
    max_height = [max_height, table.ysize].max
  end
  for table in table_array
    rows_to_add = max_height - table.ysize
    layers = []
    for layer_num in (0...table.zsize)
      layer = get_layer(table, layer_num)
      to_add = [0] * (rows_to_add * table.xsize)
      layer += to_add
      layers.push(layer)
    end
    new_data = []
    for layer in layers
      new_data += layer
    end
    table.data = new_data
  end
  total_x = 0
  for table in table_array
    total_x += table.xsize
  end
  horizontal_table = Table.new(total_x, max_height, table_array[0].zsize)
  curr = 0
  for z in 0...horizontal_table.zsize
    for y in 0...horizontal_table.ysize
      for table_no in 0...table_array.length()
        table_x_size = table_array[table_no].xsize
        start = z * table_x_size * max_height + table_x_size * y
        row = table_array[table_no].data.slice(start, table_x_size) 
        for code in row
          horizontal_table[curr] = code
          curr += 1
        end
      end
    end
  end
  return horizontal_table
end
