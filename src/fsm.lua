local base_state = {
    enter = function() end,
    update = function() end,
    draw = function() end,
    exit = function() end
}

fsm = {
    current_state = "overworld",
    states = {},
    change_state = function(self, new_state)
        if self.states[self.current_state].exit then
            self.states[self.current_state].exit()
        end
        self.current_state = new_state
        if self.states[self.current_state].enter then
            self.states[self.current_state].enter()
        end
    end,
    update = function(self)
        if self.states[self.current_state].update then
            self.states[self.current_state].update()
        end
    end,
    draw = function(self)
        if self.states[self.current_state].draw then
            self.states[self.current_state].draw()
        end
    end
}

fsm.states.overworld = setmetatable({
    enter = function()
        if SELECTED_UNIT then
            SELECTED_UNIT = nil
        end
    end,
    update = function()
        -- Move cursor
        if btnp(0) then CURSOR.x = mid(0, CURSOR.x - 1, MAP_WIDTH - 1) end
        if btnp(1) then CURSOR.x = mid(0, CURSOR.x + 1, MAP_WIDTH - 1) end
        if btnp(2) then CURSOR.y = mid(0, CURSOR.y - 1, MAP_HEIGHT - 1) end
        if btnp(3) then CURSOR.y = mid(0, CURSOR.y + 1, MAP_HEIGHT - 1) end

        -- Update camera
        if SELECTED_CASTLE then
            update_camera(CURSOR.x, CURSOR.y, 16, 16)
        else
            update_camera(CURSOR.x, CURSOR.y, MAP_WIDTH, MAP_HEIGHT)
        end

        -- Select castle or unit
        if btnp(4) then -- "Select" button
            local castle = get_castle_at(CURSOR.x, CURSOR.y)
            local unit = get_unit_at(CURSOR.x, CURSOR.y, SELECTED_CASTLE)
            if castle and SELECTED_CASTLE == nil then
                SELECTED_CASTLE = castle
                enter_castle() -- Call this to handle camera and cursor adjustment
            elseif unit then
                SELECTED_UNIT = unit
                fsm:change_state("unit_info")
            end
        elseif btnp(5) then -- "Back" button
            if SELECTED_CASTLE then
                exit_castle()
                SELECTED_CASTLE = nil
            end
        end
    end,
    draw = function()
        if SELECTED_CASTLE then
            draw_castle_interior()
            draw_nonselected_castle_units()
        else
            draw_terrain()
            draw_castles()
            draw_nonselected_overworld_units()
        end
        draw_cursor(true)
        draw_cursor_coords()
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.unit_info = setmetatable({
    enter = function()
        create_ui({
            SELECTED_UNIT.class
        }, false)
        create_ui({
            "HP: " .. UNIT_STATS[SELECTED_UNIT.class].HP .. " Spd: " .. UNIT_STATS[SELECTED_UNIT.class].Spd,
            "Str: " .. UNIT_STATS[SELECTED_UNIT.class].Str .. " Def: " .. UNIT_STATS[SELECTED_UNIT.class].Def,
            "Mag: " .. UNIT_STATS[SELECTED_UNIT.class].Mag .. " Mdf: " .. UNIT_STATS[SELECTED_UNIT.class].Mdf,
            "Skl: " .. UNIT_STATS[SELECTED_UNIT.class].Skl .. " Mov: " .. UNIT_STATS[SELECTED_UNIT.class].Mov
        }, false)
    end,
    update = function()
        if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
            if (SELECTED_CASTLE) exit_castle()
            fsm:change_state("move_unit")
        elseif btnp(5) then -- "Back" button
            SELECTED_UNIT = nil
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        if SELECTED_CASTLE then
            draw_castle_interior()
            draw_nonselected_castle_units()
        else
            draw_terrain()
            draw_castles()
            draw_nonselected_overworld_units()
        end
        draw_selected_unit_flashing(SELECTED_UNIT)
        draw_cursor(true)
        draw_ui()
    end,
    exit = function()
        close_ui()
    end,
}, { __index = base_state })

fsm.states.move_unit = setmetatable({
    enter = function()
        -- Show traversable tiles
        find_traversable_tiles(CURSOR.x, CURSOR.y, 5, SELECTED_UNIT.team)
    end,
    update = function()
        -- Store the current cursor position
        local old_x, old_y = CURSOR.x, CURSOR.y
    
        -- Move cursor based on input
        if btnp(0) then CURSOR.x = mid(0, CURSOR.x - 1, MAP_WIDTH - 1) end
        if btnp(1) then CURSOR.x = mid(0, CURSOR.x + 1, MAP_WIDTH - 1) end
        if btnp(2) then CURSOR.y = mid(0, CURSOR.y - 1, MAP_HEIGHT - 1) end
        if btnp(3) then CURSOR.y = mid(0, CURSOR.y + 1, MAP_HEIGHT - 1) end
    
        -- Check if the new cursor position is in TRAVERSABLE_TILES
        local key = CURSOR.x..","..CURSOR.y
        if not TRAVERSABLE_TILES[key] then
            -- If not, revert to the old position
            CURSOR.x, CURSOR.y = old_x, old_y
        end
    
        -- Update camera
        update_camera(CURSOR.x, CURSOR.y, MAP_WIDTH, MAP_HEIGHT)
    
        -- Select tile to move to
        if btnp(4) then -- "Select" button
            local unit_at_tile = get_unit_at(CURSOR.x, CURSOR.y, false)
            if not unit_at_tile then
                -- TODO: temp place unit here (maybe use cursor pos?)
                fsm:change_state("action_menu")
            end
        elseif btnp(5) then -- "Back" button
            -- TODO: Determine if cursor follows player into castle.
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        draw_terrain()
        draw_castles()
        draw_nonselected_overworld_units()
        if SELECTED_UNIT.in_castle then
            draw_selected_unit_flashing(SELECTED_UNIT, SELECTED_CASTLE.x, SELECTED_CASTLE.y)
        else
            draw_selected_unit_flashing(SELECTED_UNIT)
        end
        draw_cursor(true)
        draw_cursor_coords()
    end,
    exit = function()
        TRAVERSABLE_TILES = {}
    end
}, { __index = base_state })

fsm.states.action_menu = setmetatable({
    enter = function()
        -- create_ui({"Mv", "Hp", "Atk"}, false)
        create_ui({"Attack", "Item", "Standby"}, true)
        -- create_ui({"Shoal", "Cost: 2", "Avo: 25"}, false)
    end,
    update = function()
        update_ui()

        -- Select menu item with "Select" button
        if btnp(4) then
            local selected_item = get_ui_selection()
            if selected_item == "Attack" then
                fsm:change_state("attack")
            elseif selected_item == "Item" then
                fsm:change_state("item")
            elseif selected_item == "Standby" then
                if (SELECTED_UNIT.in_castle) then
                    deploy_unit(SELECTED_UNIT, CURSOR.x, CURSOR.y)
                else
                    move_unit(SELECTED_UNIT, CURSOR.x, CURSOR.y)
                end
                SELECTED_CASTLE = nil
                fsm:change_state("overworld")
            end
        end

        -- Go back with "Back" button
        if btnp(5) then
            if SELECTED_CASTLE then
                CURSOR.x = SELECTED_CASTLE.x
                CURSOR.y = SELECTED_CASTLE.y
                update_camera(CURSOR.x, CURSOR.y, MAP_WIDTH, MAP_HEIGHT)
            end
            fsm:change_state("move_unit")
        end
    end,
    draw = function()
        draw_terrain()
        draw_castles()
        draw_nonselected_overworld_units()
        draw_selected_unit_flashing(SELECTED_UNIT, CURSOR.x, CURSOR.y)
        -- draw_cursor()
        draw_ui()
    end,
    exit = function()
        close_ui()
    end
}, { __index = base_state })
