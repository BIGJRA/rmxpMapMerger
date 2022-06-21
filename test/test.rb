$COMMAND = 'merge'
$PROJECT_DIR = Dir.pwd + '/'

require_relative '../src/yaml_process'
require_relative '../src/common'
require_relative '../src/data_importer_exporter'
require 'test/unit/assertions'


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

inp_path = File.expand_path($CONFIG.game_yaml_dir, __FILE__)
input_dir  = inp_path + '/'

############################
files = ["Map008 - Blacksteam Factory 3F.yaml", "Map009 - Blacksteam Factory 2F.yaml"]

tables = []
for file in files
    tables.push(load_yaml(input_dir + file).data)
end

if !(tables[0].data.length() == 1125)
    raise ("Value is wrong")
end
if !(tables[1].data.length() == 3000)
    raise ("Value is wrong")
end

get_horizontal_slice(tables)

if !(tables[0].data.length() == 1875)
    raise ("Value is wrong")
end
if !(tables[1].data.length() == 3000)
    raise ("Value is wrong")
end

############################