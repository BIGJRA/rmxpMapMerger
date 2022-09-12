# RMXP Map Merger Tool V 1.0

- Created and maintained by BIGJRA (bigjra441@gmail.com)
- Parent projects by: 
  - enumag (enumag@gmail.com)
  - Raku (rakudayo@gmail.com)

This CLI Ruby tool is meant to allow developers to automatically merge RPG Maker XP map files to reduce filesizes and counts and simplify game development.

## Features

- Automatically merge metadata, tile data, and event data from any number of RMXP map files.
- Reads and writes RMXP Map YAML files. To export these from game data, [EEVEE](https://github.com/enumag/eevee/) project is necessary
- Configurable details: 
  - Deletes excess maps?  
  - Verbose output?
  - Scans other maps for warps into merged maps? If so, automatically fixes these.
  
## Current Version Notes

- Does not automatically fix variable-based warp events. Currently warns for manual fixes.
- Potential issues arise when autorun events overlap. Can be fixed with RMXP variables internally.
  
## Usage

1. Clone this repository.
2. Clone [EEVEE](https://github.com/enumag/eevee/) and export game map data YAML's if necessary.
3. Edit the ```config.yaml```, putting the path to your game's exported YAML directory, change other config bools as desired.
4. Run ```ruby rmxpMapMerger.rb```!
