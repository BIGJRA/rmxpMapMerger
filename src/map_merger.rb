$LOAD_PATH.unshift File.dirname(__FILE__)

require 'yaml'
require 'tmpdir'
require_relative '../rmxp/rgss_internal.rb'
require_relative '../rmxp/rgss_mod.rb'
require_relative '../rmxp/rgss_rpg.rb'
require_relative '../rmxp/rgss.rb'

HOR_MAX = 500
VER_MAX = 500

HOR_BUFFER = 10
VER_BUFFER = 8

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

def get_merged_map(maps)

  # Quits if tilesets don't match
  if not overlap?(maps, 'tileset_id')
    puts "These maps use different tilesets. Quitting..."
    return
  end

  # Warns if other properties don't match
  ['autoplay_bgm', 'bgm', 'autoplay_bgs', 'bgs', 'encounter_list', 'encounter_step', 'autoplay_bgm'].each do |property| 
    if not overlap?(maps, property)
      puts "WARNING: These maps have different " + property + ". Using values from the first map." 
    end
  end

  tables = maps.map {|map| map.data}
  merged_table = merge_tables(tables)

  merged_map = RPG::Map.new(merged_table.xsize, merged_table.ysize) # change these values later
  merged_map.tileset_id = maps[0].tileset_id
  merged_map.autoplay_bgm = maps[0].autoplay_bgm
  merged_map.bgm = maps[0].bgm
  merged_map.autoplay_bgs = maps[0].autoplay_bgs
  merged_map.bgs = maps[0].bgs
  merged_map.encounter_list = maps[0].encounter_list
  merged_map.encounter_step = maps[0].encounter_step
  merged_map.autoplay_bgm = maps[0].autoplay_bgm
  merged_map.events = maps[0].autoplay_bgm # will change this
  merged_map.data = merged_table
  return merged_map
end

def merge_tables(table_array)
  # returns a Table class with the merged data of table1, table2

  def get_horizontal_slice(table_array)
    # Assumes all the data arrays in the array will fit within the 500 pixel horizontal limit
    # Produces a horizontal slice with 0 filled in in the excess vertical space
  
    # Finds max height so all layers can have same height
    max_height = 0
    for table in table_array
      max_height = [max_height, table.ysize].max
    end
  
    for table in table_array
      # Adds horizontal buffer region on the end of each line
      add_empty_columns(table, HOR_BUFFER)
  
      # Adds extra vertical space to match the rest of the tables
      rows_to_add = max_height - table.ysize
      add_empty_rows(table, rows_to_add) 
    end
  
    total_x = 0
    for table in table_array
      total_x += table.xsize
    end
  
    # Creates new table and fills in each tile correctly
    horizontal_table = Table.new(total_x, max_height, table_array[0].zsize)
  
    new_data = []
    for z in 0...horizontal_table.zsize
      for y in 0...horizontal_table.ysize
        for table in table_array
          table_x_size = table.xsize
          start = (z * table_x_size * max_height) + (table_x_size * y)
          row = table.data.slice(start, table_x_size) 
          for code in row
            new_data.push(code)
          end
        end
      end
    end
    for pos in 0...new_data.length()
      horizontal_table[pos] = new_data[pos]
    end
    return horizontal_table
  end
  
  def combine_vertical(horizontal_slices)
    # Combines horizontal slices vertically
  
    # Finds max width so all layers can have same width
    max_width = 0
    for table in horizontal_slices
      max_width = [max_width, table.xsize].max
    end
  
    for table in horizontal_slices
  
      # add vertical buffer to each slice
      add_empty_rows(table, VER_BUFFER)
      
      # Adds extra horizontal space to match the rest of the tables
      cols_to_add = max_width - table.xsize
      add_empty_columns(table, cols_to_add)
    
    end
  
    total_y = 0
    for table in horizontal_slices
      total_y += table.ysize
    end
  
    # Creates new table and fills in each tile correctly
    vertical_table = Table.new(max_width, total_y, horizontal_slices[0].zsize)
    new_data = []
    for z in 0...vertical_table.zsize
      for table_no in 0...horizontal_slices.length()
        layer = get_layer(horizontal_slices[table_no], z)
        new_data += layer
      end
    end
    for pos in 0...(max_width * total_y * horizontal_slices[0].zsize)
      vertical_table[pos] = new_data[pos]
    end
    return vertical_table
  end
  
  def add_empty_columns(table, num_cols)
    # mutates table to add empty columns
  
    if num_cols == 0
      return
    end
  
    new_data = []
    for layer_num in (0...table.zsize)
      layer = get_layer(table, layer_num)
      for y_value in (0...table.ysize)
        new_data += layer.slice(y_value * table.xsize, table.xsize)
        new_data += [0] * num_cols
      end
    end
    table.data = new_data
    table.xsize += num_cols
    return table
  end
  
  def add_empty_rows(table, num_rows)
    # mutates table to add empty rows
  
    if num_rows == 0
      return
    end
  
    new_data = []
    for layer_num in (0...table.zsize)
      layer = get_layer(table, layer_num)
      new_data += layer
      new_data += [0] * (num_rows * table.xsize)
    end
    table.data = new_data
    table.ysize += num_rows
  end
  
  def get_layer(table, layer_num)
    # gets the layer @ num, helper function
    layer_area = table.xsize * table.ysize
    return table.data.slice(layer_area * layer_num, layer_area)
  end

  horizontal_slices = []
  width = 0
  start = 0
  finish = 0
  for table in table_array
    finish += 1
    if width + table.xsize + HOR_BUFFER >= HOR_MAX
      width = 0
      horizontal_slices.push(get_horizontal_slice(table_array[start...finish]))
      start = finish
    else
      width += table.xsize + HOR_BUFFER
    end
  end
  horizontal_slices.push(get_horizontal_slice(table_array[start...finish]))

  return combine_vertical(horizontal_slices)
end

def overlap?(maps, field_name)
  value = maps[0].send(field_name)
  for map in maps[1...maps.length()]
    if map.send(field_name) != value
      return false
    end
  end
  return true
end