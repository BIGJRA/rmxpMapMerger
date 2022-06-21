$COMMAND = 'merge'
$PROJECT_DIR = Dir.pwd + '/'

require_relative 'src/map_merger'
require_relative 'src/common'
#require_relative 'src/data_importer_exporter'
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
      puts "Nothing to import...skipping import."
      puts
      return
    end
    # Check if the output directory exist
    # if not (File.exist? output_dir and File.directory? output_dir)
    #   puts "Error: Output directory #{output_dir} does not exist."
    #   puts "Hint: Check that the $CONFIG.data_dir variable in paths.rb is set to the correct path."
    #   puts
    #   exit
    # end

    if not (File.exist? output_dir and File.directory? output_dir)
      recursive_mkdir( output_dir )
    end

    # Gets the map numbers to merge
    nums = '8,9,10,11,12,13' #TODO Change this to empty string in working version
    while !validate_nums_list(nums)
      puts "Enter the 2+ map numbers you want to merge, separated by commas (no whitespace)."
      nums = gets.chomp
    end
    map_numbers = nums.split(',').map {|num| num.rjust(3, "0") }.sort

    # Create map hash for easier lookup
    map_hash = {}
    for file in Dir.entries(input_dir)
      if file[0..2] == "Map" && !!(file[3..5] =~ /^\d{3}$/)
        map_hash[file[3..5]] = file
      end
    end
    # p map_hash

    yaml_maps = []
    for num in map_numbers
      yaml_maps.push(load_yaml(input_dir + map_hash[num]))
    end

    # merges the maps and writes output
    merged_map = get_merged_map(yaml_maps)
    if merged_map == nil
      return
    end
    target = output_dir + map_hash[map_numbers[0]]
    target[map_numbers[0]] = "999" # Just for testing to create a new map
    write_yaml(merged_map, target) # stores new map in the name of the first one

    puts "Successfully wrote to " + target + "."

  end
  
  def on_start
    # Set up the directory paths
    input_dir  = $PROJECT_DIR + $CONFIG.yaml_dir + '/'
    output_dir = $PROJECT_DIR + $CONFIG.data_dir + '/'

    print_separator(true)
    puts "  RMXP Data Import"
    print_separator(true)

    # Check if the input directory exist
    if not (File.exist? input_dir and File.directory? input_dir)
      puts "Input directory #{input_dir} does not exist."
      puts "Nothing to import...skipping import."
      puts
      return
    end

    # Check if the output directory exist
    if not (File.exist? output_dir and File.directory? output_dir)
      puts "Error: Output directory #{output_dir} does not exist."
      puts "Hint: Check that the $CONFIG.data_dir variable in paths.rb is set to the correct path."
      puts
      exit
    end

    # Create the list of data files to export
    files = Dir.entries( input_dir )
    files = files.select { |e| File.extname(e) == '.yaml' && ! e.end_with?('.local.yaml') }
    files = files.select { |f| f.index("._") != 0 }  # FIX: Ignore TextMate annoying backup files
    files.sort!

    if files.empty?
      puts_verbose "No data files to import."
      puts_verbose
      return
    end

    total_start_time = Time.now
    total_dump_time  = 0.0
    i = 1
    checksums = load_checksums
    ensure_non_duplicate_maps(files)

    # For each yaml file, load it and dump the objects to data file
    Parallel.each(
      files,
      in_threads: detect_cores,
      finish: -> (file, index, dump_time) {
        next if dump_time.nil?

        # Update the user on the status
        str =  "Imported "
        str += "#{file}".ljust(40)
        str += "(" + "#{index}".rjust(3, '0')
        str += "/"
        str += "#{files.size}".rjust(3, '0') + ")"
        str += "    #{dump_time} seconds"
        puts str

        total_dump_time += dump_time
        i += 1
      }
    ) do |file|
      import_file(file, checksums, input_dir, output_dir)
    end

    save_checksums(checksums)

    # Calculate the total elapsed time
    total_elapsed_time = Time.now - total_start_time

    # Report the times
    print_separator
    puts_verbose "rxdata dump time: #{total_dump_time} seconds."
    puts_verbose "Total import time: #{total_elapsed_time} seconds."
    print_separator
    puts_verbose
  end

  def on_exit
    # Set up the directory paths
    input_dir  = $PROJECT_DIR + $CONFIG.data_dir + '/'
    output_dir = $PROJECT_DIR + $CONFIG.yaml_dir + '/'

    print_separator(true)
    puts "  Data Export"
    print_separator(true)

    $STARTUP_TIME = load_startup_time || Time.now

    # Check if the input directory exist
    if not (File.exist? input_dir and File.directory? input_dir)
      puts "Error: Input directory #{input_dir} does not exist."
      puts "Hint: Check that the $CONFIG.data_dir variable in paths.rb is set to the correct path."
      exit
    end

    # Create the output directory if it doesn't exist
    if not (File.exist? output_dir and File.directory? output_dir)
      recursive_mkdir( output_dir )
    end

    # Create the list of data files to export
    files = Dir.entries( input_dir )
    files -= $CONFIG.data_ignore_list
    files = files.select { |e| File.extname(e) == ".rxdata" }
    files = files.select { |e| file_modified_since?(input_dir + e, $STARTUP_TIME) || ! data_file_exported?(input_dir + e) }
    files.sort!

    if files.empty?
      puts_verbose "No data files need to be exported."
      puts_verbose
      return
    end

    total_start_time = Time.now
    total_dump_time = 0.0
    i = 1
    checksums = load_checksums
    maps = load_maps

    # For each data file, load it and dump the objects to YAML
    Parallel.each(
      files,
      in_threads: detect_cores,
      finish: -> (file, index, dump_time) {
        next if dump_time.nil?

        # Update the user on the export status
        str =  "Exported "
        str += "#{file}".ljust(30)
        str += "(" + "#{index}".rjust(3, '0')
        str += "/"
        str += "#{files.size}".rjust(3, '0') + ")"
        str += "    #{dump_time} seconds"
        puts_verbose str

        total_dump_time += dump_time
        i += 1
      }
    ) do |file|
      export_file(file, checksums, maps, input_dir, output_dir)
    end

    save_checksums(checksums)

    # Calculate the total elapsed time
    total_elapsed_time = Time.now - total_start_time
  
    # Report the times
    print_separator
    puts_verbose "YAML dump time: #{total_dump_time} seconds."
    puts_verbose "Total export time: #{total_elapsed_time} seconds."
    print_separator
    puts_verbose
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

#   # Dump the system time at startup into a file to read later
#   dump_startup_time

#   # Definitely do not want the user to close the command window
#   puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#   puts "!!!DO NOT CLOSE THIS COMMAND WINDOW!!!"
#   puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#   puts_verbose

#   maps = load_maps
#   input_dir = $PROJECT_DIR + $CONFIG.game_yaml_dir + '/'
#   output_dir = $PROJECT_DIR + $CONFIG.modified_yaml_dir + '/'
#   listener = Listen.to(input_dir) do |modified, added, removed|
#     removed.each do |file|
#       if file.start_with?(input_dir) && file.end_with?('.rxdata')
#         name = file.slice(input_dir.length .. - '.rxdata'.length - 1)
#         yaml_file = output_dir + format_yaml_name(name, maps)
#         if File.exist?(yaml_file)
#           File.delete(yaml_file)
#           puts 'Deleted ' + name + '.rxdata'
#         end
#       end
#     end

#     plugin.on_exit
#   end
#   listener.start

#   # Start RMXP
#   File.write($PROJECT_DIR + '/Game.rxproj', 'RPGXP 1.05')
#   system('START /WAIT /D "' + $PROJECT_DIR + '" Game.rxproj')
#   File.delete($PROJECT_DIR + '/Game.rxproj') if File.exist?($PROJECT_DIR + '/Game.rxproj')

#   plugin.on_exit

#   clear_backups

#   # Delete the startup timestamp
#   load_startup_time(true)
# elsif $COMMAND == "patch"
#   require 'open3'
#   require 'zip'

#   generate_patch
# else
#   puts "Unknown command " + $COMMAND
end