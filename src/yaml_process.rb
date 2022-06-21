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
end

def get_layer(table, layer_num)
  layer_area = table.xsize * table.ysize
  return table.data.slice(layer_area * layer_num, layer_area)
end

def get_horizontal_slice(table_array)
  # Assumes all the data arrays in the array will fit within the 500 pixel horizontal limit
  # Produces a horizontal slice with 0 filled in in the excess vertical space
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
