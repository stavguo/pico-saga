function init_systems(world, components)
    local systems = {}
    
    systems.move_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            if (MENU_OPEN) return
            local pos = entity[components.Position]
            local cursor = entity[components.Cursor]
            local new_x, new_y = pos.x, pos.y

            if btnp(0) then new_x = pos.x - 1 end
            if btnp(1) then new_x = pos.x + 1 end
            if btnp(2) then new_y = pos.y - 1 end
            if btnp(3) then new_y = pos.y + 1 end

            if not next(TRAVERSABLE_TILES) then
                pos.x = mid(0, new_x, cursor.max_width - 1)
                pos.y = mid(0, new_y, cursor.max_height - 1)
            elseif TRAVERSABLE_TILES[new_x..","..new_y] then
                pos.x = new_x
                pos.y = new_y
            end
            -- Update coordinate display text whenever cursor moves
            if CURSOR_COORDS and CURSOR_COORDS[components.UI].visible then
                CURSOR_COORDS[components.UI].text = "x:" .. pos.x .. " y:" .. pos.y
            end
            update_camera(pos.x, pos.y, cursor.max_width, cursor.max_height)
        end
    )

    systems.handle_cursor_coords = world.system(
        { components.Position, components.Cursor },
        function(cursor)
            -- Create cursor coordinates display if it doesn't exist
            if not CURSOR_COORDS then
                CURSOR_COORDS = world.entity()
                CURSOR_COORDS += components.Position({ x = 8, y = 8 })
                CURSOR_COORDS += components.UI({
                    text = "x:" .. cursor[components.Position].x .. " y:" .. cursor[components.Position].y,
                    color = 7,
                    relative_to_camera = true
                })
            end
        end
    )

    systems.menu_navigation = world.system(
        { components.Position, components.Cursor },
        function(cursor_entity)
            if not MENU_OPEN or (not btnp(2) and not btnp(3)) then return end
            
            MENU_ITEMS[MENU_SELECTED][components.UI].color = 7
            MENU_SELECTED = (MENU_SELECTED + (btnp(2) and -1 or 1)) % MENU_SIZE
            MENU_ITEMS[MENU_SELECTED][components.UI].color = 9
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
    
    systems.draw_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            local sprite = 0  -- Default to 0
            
            if next(TRAVERSABLE_TILES) then  -- If TRAVERSABLE_TILES is not empty
                if SELECTED_UNIT then  -- Then check if SELECTED_UNIT exists
                    sprite = SELECTED_UNIT[components.Unit].sprite
                end
            end
            
            spr(sprite, pos.x * 8, pos.y * 8)
        end
    )

    systems.castle_selection = world.system(
        { components.Position, components.Cursor },
        function(cursor_entity)
            if btnp(4) then
                local cursor_pos = cursor_entity[components.Position]
                local castles = world.query({ components.Position, components.Castle })
                for id, castle in pairs(castles) do
                    if castle[components.Castle].is_player then
                        local castle_pos = castle[components.Position]
                        if castle_pos.x == cursor_pos.x and castle_pos.y == cursor_pos.y then
                            if GAME_STATE == "world" then
                                GAME_STATE = "castle"
                                SELECTED_CASTLE = castle
                                if CURSOR_COORDS then CURSOR_COORDS[components.UI].visible = false end
                                update_cursor(world, components, 7, 2, 16, 16)
                            end
                        end
                    end
                end
            elseif btnp(5) then
                if GAME_STATE == "castle" then
                    GAME_STATE = "world"
                    update_cursor(
                        world,
                        components,
                        SELECTED_CASTLE[components.Position].x,
                        SELECTED_CASTLE[components.Position].y,
                        MAP_WIDTH,
                        MAP_HEIGHT)
                        if CURSOR_COORDS then CURSOR_COORDS[components.UI].visible = true end
                    SELECTED_CASTLE = nil
                end
            end
        end
    )

    systems.draw_units = world.system(
        { components.Position, components.Unit },
        function(entity)
            local pos = entity[components.Position]
            local unit = entity[components.Unit]
            if (pos.in_castle and GAME_STATE == "castle")
                or (not pos.in_castle and GAME_STATE == "world") then
                    spr(unit.sprite, pos.x * 8, pos.y * 8)
            end
        end
    )

    systems.unit_selection = world.system(
        { components.Position, components.Cursor },
        function(cursor_entity)
            local select = btnp(4)
            local back = btnp(5)
            local cursor_pos = cursor_entity[components.Position]
            
            if GAME_STATE == "castle" then
                if select then
                    local units = world.query({components.Unit, components.Position})
                    for id, unit in pairs(units) do
                        local unit_pos = unit[components.Position]
                        if unit_pos.x == cursor_pos.x and unit_pos.y == cursor_pos.y then
                            local castle_pos = SELECTED_CASTLE[components.Position]
                            find_traversable_tiles(world, components, castle_pos.x, castle_pos.y + 1, 5, unit[components.Unit].team)
                            update_cursor(
                                world,
                                components,
                                castle_pos.x,
                                castle_pos.y + 1,
                                MAP_WIDTH,
                                MAP_HEIGHT)
                            SELECTED_UNIT = unit
                            UNIT_STATE = "moving"
                            GAME_STATE = "world"
                            SELECTED_CASTLE = nil
                            if CURSOR_COORDS then CURSOR_COORDS[components.UI].visible = true end
                            break
                        end
                    end
                end
            elseif UNIT_STATE == "moving" then
                if select then
                    -- Check if the tile is occupied by any unit
                    local unit_at_tile = get_unit_at_tile(world, components, cursor_pos.x, cursor_pos.y)
                    if not unit_at_tile then
                        SELECTED_UNIT[components.Position].x = cursor_pos.x
                        SELECTED_UNIT[components.Position].y = cursor_pos.y
                        SELECTED_UNIT[components.Position].in_castle = false
                        TRAVERSABLE_TILES = {}
                        UNIT_STATE = "action_menu"
                        create_menu(
                            world, 
                            components,
                            {"Attack", "Item", "Standby"},
                            cursor_pos.x,
                            cursor_pos.y
                        )
                    end
                end
            elseif UNIT_STATE == "action_menu" and MENU_OPEN then
                if select then
                    local selected_text = MENU_ITEMS[MENU_SELECTED][components.UI].text
                    
                    if selected_text == "Standby" then
                        SELECTED_UNIT[components.Position].waiting = true
                        SELECTED_UNIT = nil
                        UNIT_STATE = nil
                    elseif selected_text == "Attack" then
                        UNIT_STATE = "attack"
                    elseif selected_text == "Item" then
                        UNIT_STATE = "item"
                    end
                    
                    close_menu(world, components)
                elseif back then
                    close_menu(world, components)
                    -- Add any cancel-specific logic here
                end
            end
            
            -- Only reset CAN_CHANGE_STATE at end of frame
            if not btn(4) and not btn(5) then 
                CAN_CHANGE_STATE = true
            end
        end
    )

    systems.draw_ui = world.system(
        { components.Position, components.UI },
        function(entity)
            local pos = entity[components.Position]
            local ui = entity[components.UI]
            
            if ui.visible then
                local x = pos.x
                local y = pos.y
                
                if ui.relative_to_camera then
                    x = x + CAMERA_X
                    y = y + CAMERA_Y
                end
                
                -- Draw black background
                rectfill(x-1, y-1, x+#ui.text*4, y+4, 0)
                
                -- Draw text
                color(ui.color)
                print(ui.text, x, y)
            end
        end
    )

    -- systems.handle_unit_deployment = world.system(
    --     { components.Unit, components.Selected },
    --     function(unit)
    --         if not SELECTED_UNIT and GAME_STATE == "castle" then
    --             SELECTED_UNIT = unit
    --             -- Find the player's castle first
    --             local castles = world.query({ components.Castle })
    --             for id, castle in pairs(castles) do
    --                 if castle[components.Castle].is_player then
    --                     local castle_pos = castle[components.Position]
    --                     -- Start from the tile in front of the castle
    --                     find_traversable_tiles(world, components, castle_pos.x, castle_pos.y + 1, 5)
    --                     update_cursor(
    --                         world,
    --                         components,
    --                         castle_pos.x,
    --                         castle_pos.y + 1,
    --                         MAP_WIDTH,
    --                         MAP_HEIGHT)
    --                     castle += components.Deselected()
    --                     world.queue(function()
    --                         castle -= components.Selected
    --                     end)
    --                     break
    --                 end
    --             end
    --         end
    --     end
    -- )

    -- systems.handle_unit_deselection = world.system(
    --     { components.Unit, components.Deselected },
    --     function(unit)
    --         if SELECTED_UNIT and SELECTED_UNIT == unit then
    --             SELECTED_UNIT = nil
    --             local traversable = world.query({components.TraversableTile})
    --             for id, _ in pairs(traversable) do
    --                 world.queue(function()
    --                     world.remove(id)
    --                 end)
    --             end
    --             world.queue(function()
    --                 unit -= components.Selected
    --                 unit -= components.Deselected
    --             end)
    --         end
    --     end
    -- )

    -- systems.draw_traversable_tiles = world.system(
    --     { components.Position, components.TraversableTile },
    --     function(entity)
    --         local pos = entity[components.Position]
    --         spr(19, pos.x * 8, pos.y * 8)
    --     end
    -- )
    
    return systems
end