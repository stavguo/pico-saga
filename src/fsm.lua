local base_state = {
    enter = function() end,
    update = function() end,
    draw = function() end,
    exit = function() end
}

fsm = {
    current_state = "overworld",
    phase = "player",
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
        printh("", "logs/debug.txt", true)
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

        fsm.phase = "player"
        fsm:change_state("phase_change")
    end
}, { __index = base_state })

fsm.states.overworld = setmetatable({
    enter = function()
        if (fsm.selected_unit) fsm.selected_unit = nil
        if (fsm.selected_castle) fsm.selected_castle = nil
        if is_phase_over("player", fsm.units) then
            fsm.phase = "enemy"
            fsm:change_state("phase_change")
        end
    end,
    update = function()
        -- Move cursor
        update_cursor(fsm.cursor, 31, 31)

        -- Update camera
        update_camera(fsm.cursor)

        if btnp(5) then
            fsm.phase = "enemy"
            fsm:change_state("phase_change")
        end

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
    end,
    exit = function() end
}, { __index = base_state })

fsm.states.unit_info = setmetatable({
    traversable_tiles,
    enter = function()
        create_ui({
            fsm.selected_unit.team.." "..fsm.selected_unit.class,
            "HP:" .. fsm.selected_unit.HP .. " Mov:" .. fsm.selected_unit.Mov
        }, fsm.ui, false)
        if not fsm.selected_castle then
            traversable_tiles = find_traversable_tiles(fsm.cursor, fsm.selected_unit.Mov, function (pos)
                -- Check if the tile is occupied by an opposing unit
                local unit = get_unit_at(pos, fsm.units)
                return (unit == nil or unit.team == fsm.selected_unit.team) and mget(pos[1], pos[2]) < 6
            end)
        end
    end,
    update = function()
        if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
            if fsm.selected_unit.team == "player" then
                if not fsm.selected_unit.exhausted then fsm:change_state("move_unit") end
            else
                update_cursor(fsm.cursor, 31, 31)
                update_camera(fsm.cursor)
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
            draw_traversable_edges(traversable_tiles, fsm.selected_unit.team == "player" and 7 or 8)
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
        if fsm.selected_castle then
            exit_castle(fsm.cursor, fsm.selected_castle)
        else
            fsm.cursor = {fsm.selected_unit.x, fsm.selected_unit.y}
        end
        -- Show traversable tiles
        traversable_tiles = find_traversable_tiles(fsm.cursor, fsm.selected_unit.Mov, function (pos)
            -- Check if the tile is occupied by an opposing unit
            local unit = get_unit_at(pos, fsm.units)
            return (unit == nil or unit.team == fsm.selected_unit.team) and mget(pos[1], pos[2]) < 6
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
            if mget(fsm.cursor[1], fsm.cursor[2]) < 6 and not unit_at_tile or unit_at_tile == fsm.selected_unit then
                fsm:change_state("action_menu")
            end
        elseif btnp(5) then -- "Back" button
            fsm:change_state("overworld")
        end
    end,
    draw = function()
        draw_traversable_edges(traversable_tiles, 7)
        draw_nonselected_overworld_units(fsm.selected_unit, fsm.units)
        draw_unit_at(fsm.selected_unit, fsm.cursor[1], fsm.cursor[2], true)
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

        fsm.ui = {}
        local top = (fsm.cursor[2] - (peek2(0x5f2a) \ 8)) < 8
        local above_unit = get_unit_at(fsm.cursor, fsm.units, false)
                if above_unit and above_unit.team == "enemy" then
            create_ui({
                fsm.selected_unit.team.." "..fsm.selected_unit.class,
                "HP:"..fsm.selected_unit.HP,
                "Dmg:"..calculate_damage(fsm.selected_unit, above_unit),
                "Hit:"..hit_chance(fsm.selected_unit, above_unit).."%"
            }, fsm.ui, false, top and "bl" or "tl")
            create_ui({
                above_unit.team.." "..above_unit.class,
                "HP:"..above_unit.HP,
                "Dmg:"..calculate_damage(above_unit, fsm.selected_unit),
                "Hit:"..hit_chance(above_unit, {x=initial_cursor[1], y=initial_cursor[2], Spd=fsm.selected_unit.Spd}).."%"
            }, fsm.ui, false, top and "br" or "tr")
        end

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
        draw_ui(fsm.cursor, fsm.ui)
    end,
    exit = function()
        fsm.ui = {}
    end
}, { __index = base_state })

fsm.states.combat = setmetatable({
    co, attacker, defender,
    enter = function(p)
        co = cocreate(function()
            local function process_attack(atk, def, is_counter)
                local hit = will_hit(atk, def)
                local dmg = hit and calculate_damage(atk, def) or 0
                local broken = is_counter and false or is_attacker_advantage(atk, def)
                
                -- Build message
                local msg = hit and {
                    atk.team.." "..atk.class.." "..(def.HP - dmg <= 0 and "defeated" or broken and "broke" or "hit"),
                    def.team.." "..def.class,
                    "for "..dmg.." damage!"
                } or {atk.team.." "..atk.class.." attack missed..."}
                
                create_ui(msg, fsm.ui, false)
                yield() -- Show message
                fsm.ui = {} -- Clear UI
                
                -- Apply damage
                if hit then
                    def.HP = max(0, def.HP - dmg)
                    if def.HP <= 0 then
                        fsm.units[vectoindex({def.x, def.y})] = nil
                    end
                end
                
                return hit, broken
            end
            
            -- Main combat flow
            attacker, defender = p.attacker, p.defender
            local hit, broken = process_attack(attacker, defender, false)
            
            -- Counterattack if applicable
            if defender.HP > 0 and (not hit or not broken) then
                process_attack(defender, attacker, true)
            end
            
            -- End combat
            attacker.exhausted = true
            fsm:change_state(fsm.phase == "enemy" and "enemy_phase" or "overworld")
        end)
        coresume(co)
    end,
    update = function()
        if btnp(4) or btnp(5) then coresume(co) end
    end,
    draw = function()
        draw_units(fsm.units, function(u)
            return u ~= attacker and u ~= defender and not u.in_castle
        end, false)
        if attacker then draw_unit_at(attacker, nil, nil, true) end
        if defender then draw_unit_at(defender, nil, nil, true) end
        draw_ui(fsm.cursor, fsm.ui)
    end,
    exit = function()
        fsm.ui = {}
    end
}, { __index = base_state })

fsm.states.enemy_turn = setmetatable({
    logic_co = nil,
    anim_co = nil,
    path = {},

    enter = function(payload)
        local enemy = payload.enemy
        fsm.selected_unit = enemy
        logic_co = cocreate(function()
            -- Calculate path (logic)
            path = find_optimal_attack_path(enemy, fsm.units, fsm.castles, function(pos)
                local u = get_unit_at(pos, fsm.units)
                return (u == nil or u.team == enemy.team) and mget(pos[1], pos[2]) < 6
            end)
            
            if path and #path > 0 then
                path = trim_path_tail_by_costs(path, enemy.Mov)
                path = trim_path_tail_if_occupied(path, fsm.units)
                
                -- Start movement animation
                anim_co = cocreate(function()
                    for i=1,#path do
                        local v = indextovec(path[i])
                        fsm.cursor = {v[1], v[2]}
                        update_camera(fsm.cursor)
                        local t = time()
                        while time() - t < 0.2 do yield() end
                    end
                end)
                
                -- Wait for animation completion (or skip)
                while anim_co and costatus(anim_co) ~= "dead" do
                    yield()
                end
                
                move_unit(enemy, fsm.units, fsm.cursor)
            end
            
            -- Find attack targets (pure logic)
            local player_units = {}
            for _,t in ipairs(get_tiles_within_distance(fsm.cursor, enemy.Atr)) do
                local u = get_unit_at(t, fsm.units, false)
                if u and u.team == "player" then add(player_units, u) end
            end

            -- Transition to next state
            if #player_units == 0 then
                enemy.exhausted = true
                fsm:change_state("enemy_phase")
            else
                SHUFFLE(player_units)
                fsm:change_state("combat", {
                    attacker = enemy,
                    defender = player_units[1],
                    is_counter = false
                })
            end
        end)
    end,

    update = function()
        if btnp(4) and anim_co then
            -- Skip animation
            anim_co = nil
            if #path > 0 then
                local v = indextovec(path[#path])
                fsm.cursor = {v[1], v[2]}
                update_camera(fsm.cursor)
            end
        end
        
        if logic_co then coresume(logic_co) end
        if anim_co then coresume(anim_co) end
    end,

    draw = function()
        draw_nonselected_overworld_units(fsm.selected_unit, fsm.units)
        draw_unit_at(fsm.selected_unit, fsm.cursor[1], fsm.cursor[2], true)
    end,

    exit = function()
        logic_co, anim_co = nil, nil
        path = {}
    end
}, { __index = base_state })

fsm.states.enemy_phase = setmetatable({
    logic_co = nil,
    anim_co = nil,
    current_enemy = nil,
    path = {},

    enter = function()
        local enemies = sort_enemy_turn_order(fsm.units, fsm.castles)
        printh("amount of enemies: "..#enemies, "logs/debug.txt")
        logic_co = cocreate(function()
            -- Find all active enemies (logic coroutine)
            
            -- printh("current enemy: "..enemies[1], "logs/debug.txt")
            
            if #enemies == 0 then
                fsm.phase = "player"
                fsm:change_state("phase_change")
            else
                current_enemy = enemies[1][1]
                path = generate_full_path({fsm.cursor[1], fsm.cursor[2]}, {current_enemy.x, current_enemy.y})
                
                -- Start animation coroutine
                anim_co = cocreate(function()
                    for i=1,#path do
                        local v = path[i]
                        fsm.cursor = {v[1], v[2]}
                        update_camera(fsm.cursor)
                        local t = time()
                        while time() - t < 0.05 do
                            yield()
                        end
                    end
                end)
                
                -- Wait for animation to complete (or be skipped)
                while anim_co and costatus(anim_co) ~= "dead" do
                    yield()
                end
                
                -- Proceed to enemy turn
                fsm:change_state("enemy_turn", {enemy=current_enemy})
            end
        end)
    end,

    update = function()
        if btnp(4) and anim_co then
            -- Skip animation by killing the anim coroutine
            anim_co = nil
            -- Jump to final position
            if #path > 0 then
                local v = path[#path]
                fsm.cursor = {v[1], v[2]}
                update_camera(fsm.cursor)
            end
        end
        
        if logic_co then coresume(logic_co) end
        if anim_co then coresume(anim_co) end
    end,

    draw = function()
        draw_units(fsm.units, function(u) return not u.in_castle end)
        draw_cursor(fsm.cursor, true)
    end,

    exit = function()
        logic_co, anim_co = nil, nil
        current_enemy, path = nil, {}
    end
}, { __index = base_state })

fsm.states.phase_change = setmetatable({
    co,
    enter = function()
        for _, unit in pairs(fsm.units) do
            if (fsm.phase == "enemy" and unit.team == "player") or (fsm.phase == "player" and unit.team == "enemy") then
                unit.exhausted = false
            end
        end
        co = cocreate(function()
            local last_move_time = time()
            while time() - last_move_time < 3.0 do
                yield()
            end
            fsm:change_state(fsm.phase == "enemy" and "enemy_phase" or "overworld")
        end)
    end,
    update = function()
        update_camera(fsm.cursor)
        if btnp(4) then fsm:change_state(fsm.phase == "enemy" and "enemy_phase" or "overworld") end
        local active, exception = coresume(co)
        if exception then
            stop(trace(co, exception))
        end
    end,
    draw = function()
        draw_units(fsm.units, function(unit) return not unit.in_castle end)
        draw_centered_text(
            (fsm.phase == "enemy") and "Enemy Phase" or "Player Phase",
            (fsm.phase == "enemy") and 8 or 12
        )
    end,
    exit = function() end
}, { __index = base_state })