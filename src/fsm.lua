local base_state = {
    enter = function() end,
    update = function() end,
    draw = function() end,
    exit = function() end
}

fsm = {
    current_state = "overworld",
    states = {},
    change_state = function(self, new_state, payload)
        if self.states[self.current_state].exit then
            self.states[self.current_state].exit()
        end
        self.current_state = new_state
        if self.states[self.current_state].enter then
            self.states[self.current_state].enter(payload)
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
        if (SELECTED_UNIT) SELECTED_UNIT = nil
        if (SELECTED_CASTLE) SELECTED_CASTLE = nil
    end,
    update = function()
        -- Move cursor
        update_cursor(31, 31)

        -- Update camera
        update_camera(CURSOR.x, CURSOR.y)

        -- Select castle or unit
        if btnp(4) then -- "Select" button
            local castle = mget(CURSOR.x, CURSOR.y)
            local unit = get_unit_at(CURSOR.x, CURSOR.y)
            if castle == 8 then
                SELECTED_CASTLE = {
                    x = CURSOR.x,
                    y = CURSOR.y,
                }
                fsm:change_state("castle")
            elseif unit then
                SELECTED_UNIT = unit
                fsm:change_state("unit_info")
            end
        end
    end,
    draw = function()
        draw_units(ENEMY_UNITS)
        draw_units(PLAYER_UNITS, function (unit)
            return not unit.in_castle
        end)
        draw_cursor(true)
        draw_cursor_coords()
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.castle = setmetatable({
    enter = function()
        enter_castle()
        if (SELECTED_UNIT) SELECTED_UNIT = nil
    end,
    update = function()
        -- Move cursor
        update_cursor(15, 15)

        -- Select unit
        if btnp(4) then -- "Select" button
            local unit = get_unit_at(CURSOR.x, CURSOR.y, SELECTED_CASTLE)
            if unit then
                SELECTED_UNIT = unit
                fsm:change_state("unit_info")
            end
        elseif btnp(5) then -- "Back" button
            exit_castle()
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        draw_castle_interior()
        draw_units(PLAYER_CASTLE_UNITS)
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
            "HP: " .. SELECTED_UNIT.HP .. " Spd: " .. SELECTED_UNIT.Spd,
            "Str: " .. SELECTED_UNIT.Str .. " Def: " .. SELECTED_UNIT.Def,
            "Mag: " .. SELECTED_UNIT.Mag .. " Mdf: " .. SELECTED_UNIT.Mdf,
            "Skl: " .. SELECTED_UNIT.Skl .. " Mov: " .. SELECTED_UNIT.Mov
        }, false)
    end,
    update = function()
        if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
            if (SELECTED_CASTLE) exit_castle()
            fsm:change_state("move_unit")
        elseif btnp(5) then -- "Back" button
            if SELECTED_CASTLE then
                fsm:change_state("castle")
            else
                fsm:change_state("overworld")
            end
        end
    end,
    draw = function()
        if SELECTED_CASTLE then
            draw_castle_interior()
            draw_units(PLAYER_CASTLE_UNITS, function (unit)
                return unit ~= SELECTED_UNIT
            end)
        else
            draw_nonselected_overworld_units(SELECTED_UNIT)
        end
        draw_unit_at(SELECTED_UNIT, nil, nil, true)
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
        update_cursor(31, 31)
    
        -- Check if the new cursor position is in TRAVERSABLE_TILES
        local key = CURSOR.x..","..CURSOR.y
        if not TRAVERSABLE_TILES[key] then
            -- If not, revert to the old position
            CURSOR.x, CURSOR.y = old_x, old_y
        end
    
        -- Update camera
        update_camera(CURSOR.x, CURSOR.y)
    
        -- Select tile to move to
        if btnp(4) then -- "Select" button
            local unit_at_tile = get_unit_at(CURSOR.x, CURSOR.y, false)
            if not unit_at_tile or unit_at_tile == SELECTED_UNIT then
                -- TODO: temp place unit here (maybe use cursor pos?)
                fsm:change_state("action_menu")
            end
        elseif btnp(5) then -- "Back" button
            -- TODO: Determine if cursor follows player into castle.
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        draw_nonselected_overworld_units(SELECTED_UNIT)
        if SELECTED_CASTLE then
            draw_unit_at(SELECTED_UNIT, SELECTED_CASTLE.x, SELECTED_CASTLE.y, true)
        else
            draw_unit_at(SELECTED_UNIT, nil, nil, true)
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
        local ENEMY_POSITIONS = bfs(CURSOR.x, CURSOR.y, 2, find_enemy)
        if next(ENEMY_POSITIONS) ~= nil then
            create_ui({"Attack", "Item", "Standby"}, true)
        else
            create_ui({"Item", "Standby"}, true)
        end
    end,
    update = function()
        update_ui()
        if btnp(4) then
            local selected_item = get_ui_selection()
            if selected_item == "Attack" then
                fsm:change_state("attack_menu")
            elseif selected_item == "Item" then
                fsm:change_state("item")
            elseif selected_item == "Standby" then
                if (SELECTED_UNIT.in_castle) then
                    deploy_unit(SELECTED_UNIT, CURSOR.x, CURSOR.y)
                else
                    move_unit(SELECTED_UNIT, CURSOR.x, CURSOR.y)
                end
                fsm:change_state("overworld")
            end
        end
        if btnp(5) then
            if SELECTED_CASTLE then
                CURSOR.x = SELECTED_CASTLE.x
                CURSOR.y = SELECTED_CASTLE.y
                update_camera(CURSOR.x, CURSOR.y)
            end
            fsm:change_state("move_unit")
        end
    end,
    draw = function()
        draw_nonselected_overworld_units(SELECTED_UNIT)
        draw_unit_at(SELECTED_UNIT, CURSOR.x, CURSOR.y, true)
        draw_ui()
    end,
    exit = function()
        close_ui()
    end
}, { __index = base_state })

fsm.states.attack_menu = setmetatable({
    initial_cursor_x, initial_cursor_y, attackable_units,
    enter = function()
        -- Store the initial cursor position
        initial_cursor_x = CURSOR.x
        initial_cursor_y = CURSOR.y
        printh("cursor init: "..initial_cursor_x..", "..initial_cursor_y, "fe4_debug.txt")

        -- Find all attackable enemies within range using bfs
        attackable_units = get_attackable_units(bfs(CURSOR.x, CURSOR.y, 2, find_enemy))
    end,
    update = function()
        -- Allow the player to move the cursor freely
        update_cursor(31, 31)
        update_camera(CURSOR.x, CURSOR.y)

        -- Handle the select button press
        if btnp(4) then  -- Select button
            local key = CURSOR.x .. "," .. CURSOR.y  -- Convert cursor position to "x,y"
            local enemy = attackable_units[key] -- Check if the cursor is on an attackable enemy

            if enemy then
                -- Set up combat
                -- attacker, defender, is_counter = SELECTED_UNIT, enemy, false
                printh("cursor after: "..initial_cursor_x..", "..initial_cursor_y, "fe4_debug.txt")
                if SELECTED_UNIT.in_castle then
                    deploy_unit(SELECTED_UNIT, initial_cursor_x, initial_cursor_y)
                else
                    move_unit(SELECTED_UNIT, initial_cursor_x, initial_cursor_y)
                end
                fsm:change_state("combat", {
                    attacker = SELECTED_UNIT,
                    defender = enemy,
                    is_counter = false
                })
            else
                -- Optionally, provide feedback that the selected unit is not attackable
                -- (e.g., play a sound or show a message)
            end
        elseif btnp(5) then  -- Back button
            CURSOR.x = initial_cursor_x
            CURSOR.y = initial_cursor_y
            update_camera(CURSOR.x, CURSOR.y)
            fsm:change_state("action_menu")
        end
    end,
    draw = function()
        draw_units(PLAYER_UNITS, function (unit)
            return unit ~= SELECTED_UNIT
        end, false)
        draw_units(ENEMY_UNITS, function (unit)
            return attackable_units[unit.x..","..unit.y] == nil
        end, false)
        draw_units(attackable_units, nil, true)
        draw_unit_at(SELECTED_UNIT, initial_cursor_x, initial_cursor_y)
        draw_cursor(true)
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.combat = setmetatable({
    attacker, defender, is_counter, hit, damage, is_broken, message,
    enter = function(payload)
        attacker, defender, is_counter = payload.attacker, payload.defender, payload.is_counter

        -- Calculate the attack outcome
        hit = will_hit(attacker, defender)
        damage = hit and calculate_damage(attacker, defender) or 0
        is_broken = is_attacker_advantage(attacker, defender)
        message = hit and { attacker.class..(is_broken and " broke " or " hit ").. defender.class, "for "..damage.." damage!" } or { attacker.class.." attack missed..." }

        -- Display the result
        create_ui(message, false)
    end,
    update = function()
        if btnp(4) or btnp(5) then  -- "Select" or "Back" button
            -- Apply the attack effects
            if hit then
                defender.HP = max(0, defender.HP - damage)
            end
            -- Check for counterattack
            if (not hit and not is_counter) or (not is_counter and defender.HP > 0 and not is_attacker_advantage(attacker, defender)) then
                -- Swap attacker and defender for counterattack
                fsm:change_state("combat", {
                    attacker = defender,
                    defender = attacker,
                    is_counter = true
                })  -- Loop back to handle counterattack
            else
                is_counter, attacker, defender = false
                fsm:change_state("overworld")
            end
        end
    end,
    draw = function()
        draw_units(PLAYER_UNITS, function (unit)
            return unit ~= attacker and unit ~= defender
        end, false)
        draw_units(ENEMY_UNITS, function (unit)
            return unit ~= attacker and unit ~= defender
        end, false)
        draw_unit_at(attacker, nil, nil, true)
        draw_unit_at(defender, nil, nil, true)
        draw_ui()
    end,
    exit = function()
        close_ui()
    end
}, { __index = base_state })