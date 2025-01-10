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
            
            local cam_tile_x = flr(camera_x / 8)
            local cam_tile_y = flr(camera_y / 8)
            
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
            
            local cam_tile_x = flr(camera_x / 8)
            local cam_tile_y = flr(camera_y / 8)
            
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
            -- Add camera_x/y to get screen-space coordinates
            print("x:" .. entity[components.Position].x .. " y:" .. entity[components.Position].y, 
                  camera_x + 8, camera_y + 8)
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
    
    return systems
end