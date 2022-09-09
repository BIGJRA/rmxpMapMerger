$COMMAND = 'merge'
$PROJECT_DIR = Dir.pwd + '/'

require_relative 'src/map_merger'
require_relative 'src/mapInfos_fixer'
require_relative 'src/common'
require_relative 'src/validation'
require_relative 'src/fix_warps'

class DataMerger
  def merge

    # Set up the directory paths
    map_path = File.expand_path($CONFIG.game_yaml_dir, __FILE__)
    map_dir  = map_path + '/'

    print_separator(true)
    puts("RMXP Map Merger")
    print_separator(true)

    # Check if the input directory exist
    if not (File.exist? map_dir and File.directory? map_dir)
      puts_verbose("Input directory #{map_dir} does not exist.")
      puts_verbose("Double check config.yaml.")
      puts_verbose("")
      return
    end

    if not (File.exist? map_dir and File.directory? map_dir)
      recursive_mkdir( map_dir )
    end

    # Gets the map numbers to merge
    nums = ''

    # For testing - TODO, comment these out for real version
    # nums = '8,9'


    while !validate_nums_list(nums)
      puts ("Enter the 2+ map numbers you want to merge, separated by commas, or press ENTER to quit...")
      nums = gets.chomp
      if nums == ""
        return
      end
    end

    map_numbers = nums.split(',').map {|num| num.rjust(3, "0").to_i }.sort
    puts_verbose("Merging maps: " + map_numbers.to_s[1..-2] + '...')
    
    # Create map hash for easier lookup
    map_name_hash = {}
    for file in Dir.entries(map_dir)
      if file[0..2] == "Map" && !!(file[3..5] =~ /^\d{3}$/)
        map_name_hash[file[3..5].to_i] = file
      end
    end

    # Creates a hash from map number to yaml data
    map_yaml_hash = {}
    for num in map_numbers
      if map_name_hash[num].nil?
        puts_verbose("Map with number " + num.to_s + " not found. Quitting...")
        return
      end
      map_yaml_hash[num] = load_yaml(map_dir + map_name_hash[num])
    end

    destination_num = map_numbers[0]
    # merges the maps and writes output
    merged_map, offset_hash = get_merged_map(map_yaml_hash, destination_num)
    if merged_map == nil
      puts "Could not merge map data. Quitting..."
      return
    end

    # stores new map in the name of the first one
    write_target = map_dir + map_name_hash[destination_num]
    write_yaml(merged_map, write_target) 

    puts_verbose("Successfully wrote to " + write_target + ".")

    # deletes other map YAMLS
    if $CONFIG.delete_other_maps
      for map_no in map_numbers.slice(1, map_numbers.length + 1)
        delete_target = map_dir + map_name_hash[map_no]
        delete_yaml(delete_target)
      end
      puts_verbose("Successfully deleted maps " + map_numbers.slice(1, map_numbers.length + 1).to_s[1..-2] + ".")
    end

    # fixes MapInfos.yaml
    mapInfo = load_yaml(map_dir + "MapInfos.yaml")
    mapInfo = fix_map_yaml(mapInfo, map_numbers, $CONFIG.delete_other_maps)
    write_yaml(mapInfo, map_dir + "MapInfos.yaml")
    puts_verbose("Successfully changed mapInfo.yaml.")

    # fixes external map warps
    if $CONFIG.fix_other_maps
      map_name_hash.each do |map_no, _map_dir|
        if !(map_numbers.include?(map_no))
          filename = map_dir + map_name_hash[map_no]
          external_map_yaml = load_yaml(filename)
          new_map = get_fixed_external_map(external_map_yaml, offset_hash, destination_num)
          if !(new_map.nil?) then 
            write_yaml(new_map, filename)
            puts_verbose ("Fixed warp events in " + filename + ".")
          end
        end
      end
    end



    puts("Complete!")
    
  end
end

# Setup config filename
config_filename = "config.yaml"
# Setup the config file path
$CONFIG_PATH = $PROJECT_DIR + "/" + config_filename

# Read the config YAML file
config = nil
File.open( $CONFIG_PATH, "r+" ) do |configfile|
  config = YAML::load( configfile )
end

# Initialize configuration parameters
$CONFIG = Config.new(config)

plugin = DataMerger.new

if $COMMAND == "merge"
  plugin.merge
end