local base_state = {
    enter = function() end,
    update = function() end,
    draw = function() end,
    exit = function() end
}

fsm = {
    current_state = "overworld",
    selected_unit = nil,
    selected_castle = nil,
    castles = {},
    cursor = nil,
    units = {},
    ui = {},
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

fsm.states.setup = setmetatable({
    enter = function()
        local seed = flr(rnd(32767))
        local treeseed = flr(rnd(32767))
        if not _seeds_initialized then
            printh("", "logs/seeds.txt", true)
            _seeds_initialized = true
        end
        printh(
            "Generated map with seed: " .. seed .."/" .. treeseed ..
            " at " .. stat(93) .. ":" .. stat(94) .. ":" .. stat(95),
            "logs/seeds.txt"
        )
        -- Initialize terrain and castles
        local noise_fn = os2d_noisefn(seed)
        local tree_fn = os2d_noisefn(treeseed)

        init_terrain(noise_fn, tree_fn)
        fsm.cursor = init_castles(fsm.castles)
        init_player_units(fsm.units)
        init_enemy_units(fsm.units)

        fsm:change_state("overworld")
    end
}, { __index = base_state })

fsm.states.overworld = setmetatable({
    enter = function()
        if (fsm.selected_unit) fsm.selected_unit = nil
        if (fsm.selected_castle) fsm.selected_castle = nil
    end,
    update = function()
        -- Move cursor
        update_cursor(fsm.cursor, 31, 31)

        -- Update camera
        update_camera(fsm.cursor)

        -- Select castle or unit
        if btnp(4) then -- "Select" button
            local castle = mget(fsm.cursor[1], fsm.cursor[2])
            local unit = get_unit_at(fsm.cursor, fsm.units, false)
            if castle == 8 then
                fsm.selected_castle = {fsm.cursor[1], fsm.cursor[2]}
                fsm:change_state("castle")
            elseif unit then
                    fsm.selected_unit = unit
                    fsm:change_state("unit_info")
                end
            end
            end,
    draw = function()
        draw_units(fsm.units, function (unit)
            return not unit.in_castle
        end)
        draw_cursor(fsm.cursor, true)
        draw_cursor_coords(fsm.cursor)
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.castle = setmetatable({
    enter = function()
        enter_castle(fsm.cursor)
        if (fsm.selected_unit) fsm.selected_unit = nil
    end,
    update = function()
        -- Move cursor
        update_cursor(fsm.cursor, 15, 15)

        -- Select unit
        if btnp(4) then -- "Select" button
            local unit = get_unit_at(fsm.cursor, fsm.units, true)
            if unit then
                fsm.selected_unit = unit
                fsm:change_state("unit_info")
            end
        elseif btnp(5) then -- "Back" button
            exit_castle(fsm.cursor, fsm.selected_castle)
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        draw_castle_interior()
        draw_units(fsm.units, function (unit)
            return unit.in_castle
        end)
        draw_cursor(fsm.cursor, true)
        draw_cursor_coords(fsm.cursor)
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.unit_info = setmetatable({
    enter = function()
        create_ui({
            fsm.selected_unit.team.." "..fsm.selected_unit.class
        }, fsm.ui, false)
        create_ui({
            "HP: " .. fsm.selected_unit.HP .. " Spd: " .. fsm.selected_unit.Spd,
            "Str: " .. fsm.selected_unit.Str .. " Def: " .. fsm.selected_unit.Def,
            "Mag: " .. fsm.selected_unit.Mag .. " Mdf: " .. fsm.selected_unit.Mdf,
            "Skl: " .. fsm.selected_unit.Skl .. " Mov: " .. fsm.selected_unit.Mov
        }, fsm.ui, false)
    end,
    update = function()
        if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
            if (fsm.selected_unit.team == "enemy") then
                fsm:change_state("enemy_turn", {enemy = fsm.selected_unit})
            else
                if (fsm.selected_castle) exit_castle(fsm.cursor, fsm.selected_castle)
                fsm:change_state("move_unit")
            end
        elseif btnp(5) then -- "Back" button
            if fsm.selected_castle then
                fsm:change_state("castle")
            else
                fsm:change_state("overworld")
            end
        end
    end,
    draw = function()
        if fsm.selected_castle then
            draw_castle_interior()
            draw_units(fsm.units, function (unit)
                return unit.in_castle
            end)
        else
            draw_nonselected_overworld_units(fsm.selected_unit, fsm.units)
        end
        draw_unit_at(fsm.selected_unit, nil, nil, true)
        draw_cursor(fsm.cursor, true)
        draw_ui(fsm.cursor, fsm.ui)
    end,
    exit = function()
        fsm.ui = {}
    end,
}, { __index = base_state })

fsm.states.move_unit = setmetatable({
    traversable_tiles,
    enter = function()
        -- Show traversable tiles
        traversable_tiles = find_traversable_tiles(fsm.cursor, fsm.units, fsm.selected_unit.Mov, fsm.selected_unit.team)
    end,
    update = function()
        -- Store the current cursor position
        local old_x, old_y = fsm.cursor[1], fsm.cursor[2]
    
        -- Move cursor based on input
        update_cursor(fsm.cursor, 31, 31)
    
        -- Check if the new cursor position is in traversable_tiles
        local key = vectoindex(fsm.cursor)
        if not traversable_tiles[key] then
            -- If not, revert to the old position
            fsm.cursor[1], fsm.cursor[2] = old_x, old_y
        end
    
        -- Update camera
        update_camera(fsm.cursor)
    
        -- Select tile to move to
        if btnp(4) then -- "Select" button
            local unit_at_tile = get_unit_at(fsm.cursor, fsm.units, false)
            if not unit_at_tile or unit_at_tile == fsm.selected_unit then
                fsm:change_state("action_menu")
            end
        elseif btnp(5) then -- "Back" button
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        draw_nonselected_overworld_units(fsm.selected_unit, fsm.units)
        if fsm.selected_castle then
            draw_unit_at(fsm.selected_unit, fsm.selected_castle[1], fsm.selected_castle[2], true)
        else
            draw_unit_at(fsm.selected_unit, nil, nil, true)
        end
        draw_cursor(fsm.cursor, true)
        draw_cursor_coords(fsm.cursor)
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.action_menu = setmetatable({
    enemy_positions,
    enter = function()
        enemy_positions = {}
        local tiles = get_tiles_within_distance(fsm.cursor, fsm.selected_unit.Atr)
        for _, tile in ipairs(tiles) do
            local unit = get_unit_at(tile, fsm.units, false)
            if unit and unit.team == "enemy" then
                add(enemy_positions, tile)
            end
        end
        if next(enemy_positions) ~= nil then
            create_ui({
                "Attack",
                -- "Item",
                "Standby"}, fsm.ui, true)
        else
            create_ui({
                -- "Item",
                "Standby"}, fsm.ui, true)
        end
    end,
    update = function()
        update_ui(fsm.ui)
        if btnp(4) then
            local selected_item = get_ui_selection(fsm.ui)
            if selected_item == "Attack" then
                fsm:change_state("attack_menu", {["enemy_positions"] = enemy_positions })
            -- elseif selected_item == "Item" then
            --     fsm:change_state("item")
            elseif selected_item == "Standby" then
                if (fsm.selected_unit.in_castle) then
                    deploy_unit(fsm.selected_unit, fsm.units, fsm.cursor)
                else
                    move_unit(fsm.selected_unit, fsm.units, fsm.cursor)
                end
                fsm:change_state("overworld")
            end
        end
        if btnp(5) then
            if fsm.selected_castle then
                fsm.cursor[1], fsm.cursor[2] = fsm.selected_castle[1], fsm.selected_castle[2]
                update_camera(fsm.cursor)
            end
            fsm:change_state("move_unit", {})
        end
    end,
    draw = function()
        draw_nonselected_overworld_units(fsm.selected_unit, fsm.units)
        draw_unit_at(fsm.selected_unit, fsm.cursor[1], fsm.cursor[2], true)
        draw_ui(fsm.cursor, fsm.ui)
    end,
    exit = function()
        fsm.ui = {}
    end
}, { __index = base_state })

fsm.states.attack_menu = setmetatable({
    initial_cursor, attackable_units,
    enter = function(props)
        -- Store the initial cursor position
        initial_cursor = {fsm.cursor[1], fsm.cursor[2]}

        -- Find all attackable enemies within range using bfs output
        attackable_units = get_attackable_units(props.enemy_positions, fsm.units, "enemy")
    end,
    update = function()
        -- Allow the player to move the cursor freely
        update_cursor(fsm.cursor, 31, 31)
        update_camera(fsm.cursor)

        -- Handle the select button press
        if btnp(4) then  -- Select button
            local key = vectoindex(fsm.cursor) -- Convert cursor position to "x,y"
            local enemy = attackable_units[key] -- Check if the cursor is on an attackable enemy

            if enemy then
                -- Set up combat
                if fsm.selected_unit.in_castle then
                    deploy_unit(fsm.selected_unit, fsm.units, initial_cursor)
                else
                    move_unit(fsm.selected_unit, fsm.units, initial_cursor)
                end
                fsm:change_state("combat", {
                    attacker = fsm.selected_unit,
                    defender = enemy,
                    is_counter = false
                })
            else
                -- Optionally, provide feedback that the selected unit is not attackable
                -- (e.g., play a sound or show a message)
            end
        elseif btnp(5) then  -- Back button
            fsm.cursor = initial_cursor
            update_camera(fsm.cursor)
            fsm:change_state("action_menu")
        end
    end,
    draw = function()
        draw_units(fsm.units, function (unit)
            return unit ~= fsm.selected_unit and not unit.in_castle and attackable_units[vectoindex({unit.x, unit.y})] == nil
        end, false)
        draw_units(fsm.units, function (unit)
            return unit ~= fsm.selected_unit and not unit.in_castle and attackable_units[vectoindex({unit.x, unit.y})] != nil
        end, true)
        draw_unit_at(fsm.selected_unit, initial_cursor[1], initial_cursor[2])
        draw_cursor(fsm.cursor, true)
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
        is_broken = not is_counter and is_attacker_advantage(attacker, defender)
        message = hit and { attacker.team.." "..attacker.class..(is_broken and " broke " or " hit ").. defender.team.." "..defender.class, "for "..damage.." damage!" } or { attacker.team.." "..attacker.class.." attack missed..." }

        -- Display the result
        create_ui(message, fsm.ui, false)
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
        draw_units(fsm.units, function (unit)
            return unit ~= attacker and unit ~= defender and not unit.in_castle
        end, false)
        draw_unit_at(attacker, nil, nil, true)
        draw_unit_at(defender, nil, nil, true)
        draw_ui(fsm.cursor, fsm.ui)
    end,
    exit = function()
        fsm.ui = {}
    end
}, { __index = base_state })

fsm.states.enemy_turn = setmetatable({
    enemy,
    enter = function(payload)
        enemy = payload.enemy
        local target = find_target(enemy, fsm.units, fsm.castles)
        local start = {enemy.x, enemy.y}
        local target_coords = get_tiles_within_distance(target, enemy.Atr, function (pos)
            local unit = get_unit_at(pos, fsm.units, false)
            return (unit == nil or unit == enemy) and mget(pos[1], pos[2]) < 6
        end)
        local trimmed_path = a_star(start, target, target_coords, enemy.Mov, function (pos)
            return get_unit_at(pos, fsm.units, false) == nil and mget(pos[1], pos[2]) < 6
        end)

        -- Use the trimmed path
        if trimmed_path and #trimmed_path > 0 then
            for _, point in ipairs(trimmed_path) do
                printh("Move to: "..point[1]..","..point[2], "logs/debug.txt")
            end
            move_unit(enemy, fsm.units, trimmed_path[#trimmed_path])
        else
            printh("No path found.", "logs/debug.txt")
        end
        fsm:change_state("overworld")
    end,
    update = function() end,
    draw = function() end,
    exit = function() end
}, { __index = base_state })