# Add bin directory to the Ruby search path
#$LOAD_PATH << "C:/bin"

require 'yaml'
require 'tmpdir'
require 'parallel'

CHECKSUMS_FILE = 'checksums.csv'

# This is the filename where the startup timestamp is dumped.  Later it can
# be compared with the modification timestamp for data files to determine
# if they need to be exported.
TIME_LOG_FILE = "timestamp.bin"

#----------------------------------------------------------------------------
# recursive_mkdir: Creates a directory and all its parent directories if they
# do not exist.
#   directory: The directory to create
#----------------------------------------------------------------------------
def recursive_mkdir( directory )
  begin
    # Attempt to make the directory
    Dir.mkdir( directory )
  rescue Errno::ENOENT
    # Failed, so let's use recursion on the parent directory
    base_dir = File.dirname( directory )
    recursive_mkdir( base_dir )
    
    # Make the original directory
    Dir.mkdir( directory )
  end
end

#----------------------------------------------------------------------------
# print_separator: Prints a separator line to stdout.
#----------------------------------------------------------------------------
def print_separator( enable = $CONFIG.verbose )
  puts "-" * 80 if enable
end

#----------------------------------------------------------------------------
# puts_verbose: Prints a string to stdout if verbosity is enabled.
#   s: The string to print
#----------------------------------------------------------------------------
def puts_verbose(s = "")
  puts s if $CONFIG.verbose
end

class Config
  attr_accessor :data_dir
  attr_accessor :yaml_dir
  attr_accessor :backup_dir
  attr_accessor :game_yaml_dir
  attr_accessor :modified_yaml_dir
  attr_accessor :import_only_list
  attr_accessor :verbose
  attr_accessor :delete_other_maps
  attr_accessor :fix_other_maps

  def initialize(config)
    @data_dir         = config['data_dir']
    @yaml_dir         = config['yaml_dir']
    @backup_dir       = config['backup_dir']
    @game_yaml_dir    = config['game_yaml_dir']
    @modified_yaml_dir= config['modified_yaml_dir']
    @import_only_list = config['import_only_list']
    @verbose          = config['verbose']
    @delete_other_maps= config['delete_other_maps']
    @fix_other_maps   = config['fix_other_maps']
  end
end

def yaml_stable_ref(input_file, output_file)
  i = 1
  j = 1
  queue = Queue.new
  File.open(output_file, 'w') do |output|
    File.open(input_file, 'r').each do |line|
      if ! line[' &'].nil? || ! line[' *'].nil?
        match = line.match(/^ *(?:-|[a-zA-Z0-9_]++:) (?<type>[&*])(?<reference>[0-9]++)/)
        unless match.nil?
          if match[:type] === '&'
            queue.push(match[:reference])
            line[' &' + match[:reference]] = ' &' + i.to_s
            i += 1
          elsif match[:reference] === queue.pop()
            line[' *' + match[:reference]] = ' *' + j.to_s
            j += 1
            if queue.empty?
              i = 1
              j = 1
            end
          else
            raise "Unexpected alias " + match[:reference]
          end
        end
      end
      output.print line
    end
  end
end

###

def load_yaml(yaml_file)
  data = nil
  File.open( yaml_file, "r+" ) do |input_file|
    data = YAML::unsafe_load( input_file )
  end
  return data['root']
end

def write_yaml(map_object, filename)
  #p YAML::dump(map_object)
  temp_name = Dir.tmpdir() + '/' + "tmp"
  File.open(temp_name, "w+") do |tmp|
    yaml_content = YAML::dump({'root' => map_object})
    #p yaml_content
    tmp.write(yaml_content)
    yaml_stable_ref(tmp, filename)
  end
end

def delete_yaml(filename)
  begin 
    File.delete(filename)
  rescue Errno::ENOENT
  end
end
