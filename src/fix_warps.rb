$LOAD_PATH.unshift File.dirname(__FILE__)

require_relative 'common'

def get_fixed_external_map(external_map_yaml, offset_hash, destination_num)
  changed = false
  external_map_yaml.events.each do |_original_position, event|
    event.pages.each do |page|
      page.list.each do |command|
        
        if command.code == 201 then # Transfer Player. 
          # 6 Params: Declaration Type (?) (ALWAYS IS 0 IN REBORN), Destination Map ID, Dest X, Dest Y, Direction, Fade
          if offset_hash.keys.include?(command.parameters[1]) then
            command.parameters[2] += offset_hash[command.parameters[1]][0]
            command.parameters[3] += offset_hash[command.parameters[1]][1]
            command.parameters[1] = destination_num
            changed = true
          end
        end

        # Should be unneeded here
        # if command.code == 202 then # Set Event Location. 
        #   # 5 Params: Event ID, Declaration Type, Dest X, Dest Y, Direction, Fade
        #   command.parameters[0] += event_num_offset_hash[map_num]
        #   if (command.parameters[1] == 0) then
        #     command.parameters[2] += offset_hash[map_num][0]
        #     command.parameters[3] += offset_hash[map_num][1]
        #   else puts ("Variable Set Event Location, in event with name " + event.name + " found on map " + map_num.to_s + ". Skipping...")
        #   end
        # end

        # Should be unneeded here
        # if command.code == 209 then # Set Move Route
        #   # 2 Params: Event ID, and then a list of MoveCommand objects. I shouldn't have to change the latter it seems. 
        #   command.parameters[0] += event_num_offset_hash[map_num]
        # end
      end
    end
  end
  
  if changed 
    return external_map_yaml 
  else 
    return nil
  end
end

