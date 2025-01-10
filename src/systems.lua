function init_systems(world, components)
    local systems = {}
    
    -- Move cursor system
    systems.move_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            if btnp(0) then pos.x = max(0, pos.x - 1) end
            if btnp(1) then pos.x = min(MAP_WIDTH - 1, pos.x + 1) end
            if btnp(2) then pos.y = max(0, pos.y - 1) end
            if btnp(3) then pos.y = min(MAP_HEIGHT - 1, pos.y + 1) end
            update_camera(pos)
        end
    )
    
    -- Draw terrain system
    systems.draw_terrain = world.system(
        { components.Position, components.Terrain },
        function(entity)
            local pos = entity[components.Position]
            local terrain = entity[components.Terrain]
            
            local cam_tile_x = flr(CAMERA_X / 8)
            local cam_tile_y = flr(CAMERA_Y / 8)
            
            if pos.x >= cam_tile_x - 1 and
                pos.x <= cam_tile_x + SCREEN_TILES_WIDTH + 1 and
                pos.y >= cam_tile_y - 1 and
                pos.y <= cam_tile_y + SCREEN_TILES_HEIGHT + 1 then
                spr(terrain.sprite, pos.x * 8, pos.y * 8)
            end
        end
    )

    systems.draw_castles = world.system(
        { components.Position, components.Castle },
        function(entity)
            local pos = entity[components.Position]
            local sprite = entity[components.Castle].is_player and 8 or 9
            
            local cam_tile_x = flr(CAMERA_X / 8)
            local cam_tile_y = flr(CAMERA_Y / 8)
            
            if pos.x >= cam_tile_x - 1 and
                pos.x <= cam_tile_x + SCREEN_TILES_WIDTH + 1 and
                pos.y >= cam_tile_y - 1 and
                pos.y <= cam_tile_y + SCREEN_TILES_HEIGHT + 1 then
                spr(sprite, pos.x * 8, pos.y * 8)
            end
        end
    )

    systems.draw_coordinates = world.system(
        { components.Position, components.Cursor },
        function(entity)
            color(7)
            -- Add CAMERA_X/y to get screen-space coordinates
            print("x:" .. entity[components.Position].x .. " y:" .. entity[components.Position].y, 
                  CAMERA_X + 8, CAMERA_Y + 8)
        end
    )
    
    -- Draw cursor system
    systems.draw_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            spr(0, pos.x * 8, pos.y * 8)
        end
    )

    -- Selection system
    systems.check_selection = world.system(
        { components.Position, components.Cursor },
        function(cursor_entity)
            if btnp(🅾️) then
                local cursor_pos = cursor_entity[components.Position]
                local castles = world.query({ components.Position, components.Castle })
                
                for id, castle in pairs(castles) do
                    local castle_pos = castle[components.Position]
                    if castle_pos.x == cursor_pos.x and castle_pos.y == cursor_pos.y then
                        castle += components.Selected()
                        GAME_STATE = "castle"
                    end
                end
            end
            
            if btnp(❌) then
                local selected = world.query({ components.Selected })
                for id, entity in pairs(selected) do
                    entity += components.Deselected()
                    entity -= components.Selected
                    GAME_STATE = "world"
                end
            end
        end
    )
    
    -- Clean up deselected entities
    systems.clean_deselected = world.system(
        { components.Deselected },
        function(entity)
            entity -= components.Deselected
        end
    )
    
    return systems
end