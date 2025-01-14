function init_systems(world, components)
    local systems = {}
    
    systems.move_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            local cursor = entity[components.Cursor]
            if (btnp(0)) pos.x = mid(0, pos.x - 1, cursor.max_width - 1)
            if (btnp(1)) pos.x = mid(0, pos.x + 1, cursor.max_width - 1)
            if (btnp(2)) pos.y = mid(0, pos.y - 1, cursor.max_height - 1)
            if (btnp(3)) pos.y = mid(0, pos.y + 1, cursor.max_height - 1)
            update_camera(pos.x, pos.y, cursor.max_width, cursor.max_height)
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
    
    systems.draw_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            spr(0, pos.x * 8, pos.y * 8)
        end
    )

    systems.check_selection = world.system(
        { components.Position, components.Cursor },
        function(cursor_entity)
            if btnp(4) then
                local cursor_pos = cursor_entity[components.Position]
                local positions = world.query({ components.Position })
                for id, position in pairs(positions) do
                    local pos = position[components.Position]
                    local castle_cond = (pos.in_castle and GAME_STATE == "castle") or (not pos.in_castle and GAME_STATE == "world")
                    if not position[components.Cursor] and castle_cond and pos.x == cursor_pos.x and pos.y == cursor_pos.y then
                        if not position[components.Selected] then
                            position += components.Selected()
                        end
                        return
                    end
                end
            end
            
            if btnp(5) then
                local selected = world.query({ components.Selected })
                for id, sel in pairs(selected) do
                    if not sel[components.Deselected] then
                        sel += components.Deselected()
                        world.queue(function()
                            sel -= components.Selected
                        end)
                    end
                end
            end
        end
    )
    
    systems.handle_castle_selection = world.system(
        { components.Castle, components.Selected },
        function(castle)
            if GAME_STATE == "world" and not SELECTED_UNIT then
                GAME_STATE = "castle"
                update_cursor(world, components, 7, 2, 16, 16)
            end
        end
    )
    
    systems.handle_castle_deselection = world.system(
        { components.Castle, components.Deselected },
        function(castle)
            if GAME_STATE == "castle" then
                GAME_STATE = "world"
                update_cursor(
                    world,
                    components,
                    castle[components.Position].x,
                    castle[components.Position].y,
                    MAP_WIDTH,
                    MAP_HEIGHT)
                world.queue(function()
                    castle -= components.Deselected
                end)
            end
        end
    )

    systems.draw_castle_units = world.system(
        { components.Position, components.Unit },
        function(entity)
            local pos = entity[components.Position]
            local unit = entity[components.Unit]
            if pos.in_castle then
                spr(unit.sprite, pos.x * 8, pos.y * 8)
            end
        end
    )

    systems.handle_unit_deployment = world.system(
        { components.Unit, components.Selected },
        function(unit)
            if not SELECTED_UNIT and GAME_STATE == "castle" then
                SELECTED_UNIT = unit
                local castles = world.query({ components.Selected, components.Castle })
                for id, castle in pairs(castles) do
                    if not castle[components.Deselected] then
                        castle += components.Deselected()
                        world.queue(function()
                            castle -= components.Selected
                        end)
                    end
                end
            end
        end
    )

    systems.handle_unit_deselection = world.system(
        { components.Unit, components.Deselected },
        function(unit)
            if SELECTED_UNIT and SELECTED_UNIT == unit then
                SELECTED_UNIT = nil
                world.queue(function()
                    unit -= components.Selected
                    unit -= components.Deselected
                end)
            end
        end
    )
    
    return systems
end