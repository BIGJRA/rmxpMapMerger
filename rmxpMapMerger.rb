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
    #nums = '688,695,694,703,704,705' #TODO Change this to empty string in working version
    #nums = '059,060,062,063,061'
    nums = '023,025,026'
    while !validate_nums_list(nums)
      puts "Invalid input. Enter the 2+ map numbers you want to merge, separated by commas (no whitespace)."
      nums = gets.chomp
    end
    map_numbers = nums.split(',').map {|num| num.rjust(3, "0").to_i }.sort
    puts "Merging maps: " + map_numbers.to_s[1..-2] + '...'

    # Create map hash for easier lookup
    map_name_hash = {}
    for file in Dir.entries(input_dir)
      if file[0..2] == "Map" && !!(file[3..5] =~ /^\d{3}$/)
        map_name_hash[file[3..5].to_i] = file
      end
    end

    # Creates a hash from map number to yaml data
    map_yaml_hash = {}
    for num in map_numbers
      if map_name_hash[num].nil?
        p "Map with number " + num.to_s + " not found. Quitting..."
        return
      end
      map_yaml_hash[num] = load_yaml(input_dir + map_name_hash[num])
    end

    destination_num = map_numbers[0] # TO-DO: Swap these
    destination_num = 999

    # merges the maps and writes output
    merged_map = get_merged_map(map_yaml_hash, destination_num)
    if merged_map == nil
      return
    end

    # stores new map in the name of the first one
    write_target = output_dir + map_name_hash[destination_num]
    write_yaml(merged_map, write_target) 

    puts "Successfully wrote to " + write_target + "."

    # deletes other map YAMLS
    for map_no in map_numbers.slice(1, map_numbers.length + 1)
      delete_target = output_dir + map_name_hash[map_no]
      delete_yaml(delete_target)
    end

    puts "Successfully deleted maps " + map_numbers.slice(1, map_numbers.length + 1).to_s + "."

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