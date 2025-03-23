local base_state = {
    enter = function() end,
    update = function() end,
    draw = function() end,
    exit = function() end
}

fsm = {
    current_state = "overworld",
    current_phase = "player",
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
        init_enemy_units(fsm.units, fsm.castles, 4)

        fsm:change_state("phase_change")
    end
}, { __index = base_state })

fsm.states.overworld = setmetatable({
    enter = function()
        if (fsm.selected_unit) fsm.selected_unit = nil
        if (fsm.selected_castle) fsm.selected_castle = nil
        local actionable = false
        for _, unit in pairs(fsm.units) do
            if unit.team == "player" and not unit.exhausted then
                actionable = true
            end
        end
        if not actionable then
            fsm.current_phase = "enemy"
            fsm:change_state("phase_change")
        end
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
            "HP: " .. fsm.selected_unit.HP .. " Mov: " .. fsm.selected_unit.Mov,
            (fsm.selected_unit.team == "enemy" and "AI: "..fsm.selected_unit.enemy_ai or nil)
        }, fsm.ui, false)
    end,
    update = function()
        if (btnp(0) or btnp(1) or btnp(2) or btnp(3)) and not fsm.selected_unit.exhausted then
            if (fsm.selected_unit.team == "enemy") then
                fsm.current_phase = "enemy"
                -- fsm:change_state("enemy_phase")
                fsm:change_state("phase_change")
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
        traversable_tiles = find_traversable_tiles(fsm.cursor, fsm.selected_unit.Mov, function (pos)
            -- Check if the tile is occupied by an opposing unit
            local unit = get_unit_at(pos, fsm.units)
            return (unit == nil or unit == fsm.cursor.team) and mget(pos[1], pos[2]) < 6
        end)
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
        local adj_tiles = get_neighbors({fsm.cursor[1], fsm.cursor[2]}, function (pos)
            return mget(pos[1], pos[2]) == 9
        end)
        local capturable = next(adj_tiles) ~= nil
        if next(enemy_positions) ~= nil then
            create_ui({
                "Attack",
                -- "Item",
                (capturable and "Capture" or "Standby")}, fsm.ui, true)
        else
            create_ui({
                -- "Item",
                (capturable and "Capture" or "Standby")}, fsm.ui, true)
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
            elseif selected_item == "Standby" or selected_item == "Capture" then
                move_unit(fsm.selected_unit, fsm.units, fsm.cursor)
                fsm.selected_unit.exhausted = true
                if selected_item == "Capture" then
                    flip_castles({fsm.cursor[1], fsm.cursor[2]}, fsm.castles)
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
                move_unit(fsm.selected_unit, fsm.units, initial_cursor)
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
        if hit then
            -- Reduce defender's HP, ensuring it doesn't go below 0
            local remaining_hp = max(0, defender.HP - damage)
        
            -- Determine the action word based on whether the defender is defeated
            local action_word
            if remaining_hp <= 0 then
                action_word = "defeated"
            elseif is_broken then
                action_word = "broke"
            else
                action_word = "hit"
            end
        
            -- Construct the message based on the action word
            message = {
                attacker.team .. " " .. attacker.class .. " " .. action_word,
                defender.team .. " " .. defender.class,
                "for " .. damage .. " damage!"
            }
        else
            -- Construct the message for a missed attack
            message = {
                attacker.team .. " " .. attacker.class .. " attack missed..."
            }
        end
        -- Display the result
        create_ui(message, fsm.ui, false)
    end,
    update = function()
        if btnp(4) or btnp(5) then  -- "Select" or "Back" button
            -- Apply the attack effects
            if hit then
                defender.HP = max(0, defender.HP - damage)
                if defender.HP <= 0 then
                    fsm.units[vectoindex({defender.x,defender.y})] = nil
                end
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
                if (hit and is_broken) then
                    attacker.exhausted = true
                else
                    defender.exhausted = true
                end
                is_counter, attacker, defender = false
                fsm:change_state(fsm.current_phase == "enemy" and "enemy_phase" or "overworld")
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
    mv_cursor_func,
    enter = function(payload)
        local function end_enemy_turn(enemy)
            enemy.exhausted = true
            fsm:change_state(fsm.current_phase == "enemy" and "enemy_phase" or "overworld")
        end
        enemy = payload.enemy
        local enemy_pos = {enemy.x, enemy.y}
        local target_pos, target_type = find_target(enemy, fsm.units, fsm.castles)
        printh('target_pos: ' .. target_pos[1]..","..target_pos[2] .. ", target_type: " .. target_type, 'logs/debug.txt')
        -- Check if a valid target exists
        if not target_pos then
            end_enemy_turn(enemy)
        else
            -- If a target exists, proceed with movement logic
            local target_coords = get_tiles_within_distance(target_pos, enemy.Atr, function (pos)
                local unit = get_unit_at(pos, fsm.units, false)
                return (unit == nil or unit == enemy) and mget(pos[1], pos[2]) < 6
            end)
            local trimmed_path = a_star(enemy_pos, target_pos, target_coords, enemy.Mov, function (pos)
                return get_unit_at(pos, fsm.units, false) == nil and mget(pos[1], pos[2]) < 6
            end)
            -- Use the trimmed path
            if trimmed_path and #trimmed_path > 0 then
                local dest = trimmed_path[#trimmed_path]
                -- Initialize the cursor movement function
                mv_cursor_func = move_cursor_along_path(trimmed_path, fsm.cursor, 5, function()
                    move_unit(enemy, fsm.units, dest)
                end, function()
                    -- Check if combat should start
                    if target_type == "unit" and heuristic(dest, target_pos) <= enemy.Atr then
                        fsm:change_state("combat", {
                            attacker = fsm.units[vectoindex(dest)],
                            defender = fsm.units[vectoindex(target_pos)],
                            is_counter = false
                        })
                    else
                        flip_castles(dest, fsm.castles)
                    end
                    -- end_enemy_turn(enemy)
                end)
            else
                end_enemy_turn(enemy)
            end
        end
    end,
    update = function()
        if mv_cursor_func then
            mv_cursor_func()
        end
    end,
    draw = function()
        draw_units(fsm.units, function (unit)
            return not unit.in_castle
        end)
        draw_cursor(fsm.cursor, true)
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.enemy_phase = setmetatable({
    mv_cursor_func,
    enter = function()
        local enemies = {}
        for _, unit in pairs(fsm.units) do
            if unit.team == "enemy" and not unit.exhausted then
                local priority = (31-unit.y) * 32 + (31-unit.x)
                insert(enemies, unit, priority)
            end
        end
        if #enemies == 0 then
            -- All enemies have acted, return to player phase
            fsm.current_phase = "player"
            fsm:change_state("phase_change")
        else
            local enemy = enemies[1][1] -- Extract the unit from the {unit, priority} table
            local path = generate_full_path({fsm.cursor[1], fsm.cursor[2]}, {enemy.x, enemy.y})
            mv_cursor_func = move_cursor_along_path(path, fsm.cursor, 15, nil, function()
                -- Callback when the cursor reaches the enemy's position
                fsm:change_state("enemy_turn", {enemy = enemy})
            end)
        end
    end,
    update = function()
        if mv_cursor_func then
            mv_cursor_func()
        end
    end,
    draw = function()
        draw_units(fsm.units, function (unit)
            return not unit.in_castle
        end)
        draw_cursor(fsm.cursor, true)
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.phase_change = setmetatable({
    last, skip,
    enter = function()
        for _, unit in pairs(fsm.units) do
            if (fsm.current_phase == "enemy" and unit.team == "player") or (fsm.current_phase == "player" and unit.team == "enemy") then
                unit.exhausted = false
            end
        end
        last, skip = time(), false
    end,
    update = function()
        update_camera(fsm.cursor)
        if btnp(4) then skip = true end
        if time() - last > 3 or skip then
            fsm:change_state(fsm.current_phase == "enemy" and "enemy_phase" or "overworld")
        end
    end,
    draw = function()
        draw_units(fsm.units, function(unit) return not unit.in_castle end)
        draw_phase_text(fsm.current_phase)
    end,
    exit = function() end
}, { __index = base_state })