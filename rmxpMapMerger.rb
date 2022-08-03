$COMMAND = 'merge'
$PROJECT_DIR = Dir.pwd + '/'

require_relative 'src/map_merger'
require_relative 'src/common'
require_relative 'src/validation'

class DataImporterExporter
  def merge

    # Set up the directory paths
    inp_path = File.expand_path($CONFIG.game_yaml_dir, __FILE__)
    out_path = File.expand_path($CONFIG.modified_yaml_dir, __FILE__)

    input_dir  = inp_path + '/'
    output_dir = out_path + '/'

    print_separator(true)
    puts "  RMXP Map Merger"
    print_separator(true)

    # Check if the input directory exist
    if not (File.exist? input_dir and File.directory? input_dir)
      puts "Input directory #{input_dir} does not exist."
      puts "Double check config.yaml."
      puts
      return
    end

    if not (File.exist? output_dir and File.directory? output_dir)
      recursive_mkdir( output_dir )
    end

    # Gets the map numbers to merge
    nums = '285,286,290' #TODO Change this to empty string in working version
    while !validate_nums_list(nums)
      puts "Enter the 2+ map numbers you want to merge, separated by commas (no whitespace)."
      nums = gets.chomp
    end
    map_numbers = nums.split(',').map {|num| num.rjust(3, "0").to_i }.sort

    # Create map hash for easier lookup
    map_name_hash = {}
    for file in Dir.entries(input_dir)
      if file[0..2] == "Map" && !!(file[3..5] =~ /^\d{3}$/)
        map_name_hash[file[3..5].to_i] = file
      end
    end



    # Need a hash for storing x and y offsets of maps. Will be updated
    offset_hash = {}
    for number in map_numbers
      offset_hash[number] = [0,0]
    end

    p offset_hash

    # Creates a hash from map number to yaml data
    map_yaml_hash = {}
    for num in map_numbers
      map_yaml_hash[num] = load_yaml(input_dir + map_name_hash[num])
    end

    # merges the maps and writes output
    merged_map = get_merged_map(map_yaml_hash, offset_hash)
    if merged_map == nil
      return
    end

    target = output_dir + map_name_hash[map_numbers[0]]
    target = output_dir + map_name_hash[999] # Just for testing to create a new map
    write_yaml(merged_map, target) # stores new map in the name of the first one

    p offset_hash

    puts "Successfully wrote to " + target + "."

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

plugin = DataImporterExporter.new

if $COMMAND == "merge"
  plugin.merge
end