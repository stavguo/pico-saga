function create_setup_state()
    return {
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
            local cursor = init_castles(castles)
            init_player_units(castles[cursor].units)
            init_enemy_units(castles, units)
    
            update_camera(cursor, true)
            change_state("phase_change", {cursor=cursor, phase="player"})
        end
    }
end

function create_overworld_state()
    local cursor, selected_unit, traversable_tiles
    return {
        enter = function(p)
            if selected_unit ~= nil then printh("this is bad", "logs/debug.txt") end
            if p then
                if p.cursor then cursor = p.cursor end
                if p.cam then camera(p.cam[1], p.cam[2]) end
            end
        end,
        update = function()
            if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
                if selected_unit and selected_unit.team == "player" then
                    if not selected_unit.exhausted then
                        change_state("move_unit", {unit=selected_unit, cursor=cursor, start=cursor})
                    end
                else
                    cursor = update_cursor(cursor, 31, 31)
                end
            end
    
            update_camera(cursor)
    
            if btnp(5) then
                if not selected_unit then
                    change_state("phase_change", {cursor=cursor, phase="enemy"})
                else
                    selected_unit, traversable_tiles = nil, nil
                end
            end
    
            -- Select castle or unit
            if btnp(4) then
                local castle, unit = castles[cursor], units[cursor]
                if castle and castle.team == "player" then
                    change_state("castle", {castle=castle, pos=cursor, ov_cam={ peek2(0x5f28), peek2(0x5f2a) }})
                elseif unit then
                    selected_unit = unit
                    traversable_tiles = find_traversable_tiles(cursor, selected_unit.Mov, function (idx)
                        local unit = units[idx]
                        return (unit == nil or unit.team == selected_unit.team) and map_get(idx) < 6
                    end)
                end
            end
        end,
        draw = function()
            if selected_unit then draw_traversable_edges(traversable_tiles, selected_unit.team == "player" and 7 or 8) end
            draw_nonselected_overworld_units(selected_unit)
            if selected_unit then
                draw_unit_at(selected_unit, nil, true)
                show_unit_info(selected_unit, cursor)
            end
            draw_cursor(cursor, true)
        end,
        exit = function () selected_unit = nil end
    }
end

function create_castle_state()
    local selected_unit, castle, pos, ov_cam, cursor
    return {
        enter = function(p)
            castle, pos, ov_cam = p.castle, p.pos, p.ov_cam
    
            -- Store the cursor's screen position before moving the camera
            local castle_pos = indextovec(pos)
            local csx, csy = castle_pos[1] - (peek2(0x5f28) \ 8), castle_pos[2] - (peek2(0x5f2a) \ 8)
    
            -- Move the camera to (0, 0)
            camera(0,0)
    
            -- Adjust the cursor's world position to maintain its screen position
            cursor = vectoindex({csx, csy})
        end,
        update = function()
            if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
                if selected_unit then
                    if not selected_unit.exhausted then
                        change_state("move_unit", {unit=selected_unit, cursor=pos, start=pos, cam=ov_cam})
                    end
                else
                    cursor = update_cursor(cursor, 15, 15)
                end
            end
    
            if btnp(5) then
                if not selected_unit then
                    change_state("overworld", {cursor=pos, cam=ov_cam})
                else
                    selected_unit = nil
                end
            elseif btnp(4) then
                local unit = castle.units[cursor]
                if unit then
                    selected_unit = unit
                end
            end
        end,
        draw = function()
            draw_castle_interior()
            draw_units(castle.units, function (unit)
                return unit ~= selected_unit
            end)
            if selected_unit then
                draw_unit_at(selected_unit, nil, true)
                show_unit_info(selected_unit, cursor)
            end
            draw_cursor(cursor, true)
        end,
        exit = function () selected_unit = nil end
    }
end

function create_move_state()
    local selected_unit, cursor, start, traversable_tiles
    return {
        enter = function(p)
            selected_unit, cursor = p.unit, p.cursor
            if p.start then start = p.start end
            if p.cam then camera(p.cam[1], p.cam[2]) end
            traversable_tiles = find_traversable_tiles(start, selected_unit.Mov, function (idx)
                local unit = units[idx]
                return (unit == nil or unit.team == selected_unit.team) and map_get(idx) < 6
            end)
        end,
        update = function()
            local old_cursor = cursor
        
            cursor = update_cursor(cursor, 31, 31)
        
            if not traversable_tiles[cursor] then
                cursor = old_cursor
            end
        
            update_camera(cursor)
        
            -- Select tile to move to
            if btnp(4) then
                local unit_at_tile = units[cursor]
                if map_get(cursor) < 6 and not unit_at_tile or unit_at_tile == selected_unit then
                    change_state("action_menu", {unit=selected_unit, cursor=cursor})
                end
            elseif btnp(5) then
                change_state("overworld", {cursor=cursor})
            end
        end,
        draw = function()
            draw_traversable_edges(traversable_tiles, 7)
            draw_nonselected_overworld_units(selected_unit)
            draw_unit_at(selected_unit, cursor, true)
        end
    }
end

function create_action_menu_state()
    local ui, cursor, selected_unit, start, enemy_positions, c_idx
    return {
        enter = function(p)
            selected_unit, cursor, start, ui = p.unit, p.cursor, p.cursor, {}
            enemy_positions = get_tiles_within_distance(cursor, selected_unit.Atr, function (idx)
                local unit = units[idx]
                return unit and unit.team == "enemy"
            end)
            c_idx=check_for_castle(cursor)
            local opts={}
            if next(enemy_positions) then add(opts,"Attack") end
            add(opts,c_idx and "Capture" or "Standby")
            create_ui(opts,ui,true)
        end,
        update = function()
            update_ui(ui)
            if btnp(4) then
                local selected_item = get_ui_selection(ui)
                if selected_item == "Attack" then
                    change_state("attack_menu", { start = cursor, unit = selected_unit, enemy_positions = enemy_positions })
                elseif selected_item == "Standby" or selected_item == "Capture" then
                    move_unit(selected_unit, start, cursor)
                    selected_unit.exhausted = true
                    if selected_item == "Capture" then
                        flip_castle(c_idx, castles)
                    end
                    change_state("overworld", {cursor=cursor})
                end
            end
            if btnp(5) then
                change_state("move_unit", {unit=selected_unit, cursor=cursor})
            end
        end,
        draw = function()
            draw_nonselected_overworld_units(selected_unit)
            draw_unit_at(selected_unit, cursor, true)
            draw_ui(cursor, ui)
        end
    }
end

function create_attack_menu_state()
    local cursor, selected_unit, ui, start, attackable_units
    return {
        enter = function(p)
            selected_unit, start, cursor, attackable_units, ui = p.unit, p.start, p.start, {}, {}
            for tile_idx in all(p.enemy_positions) do
                attackable_units[tile_idx] = true
            end
        end,
        update = function()
            ui = {}

            cursor = update_cursor(cursor, 31, 31)
            update_camera(cursor)

            if attackable_units[cursor] then
                local top = (indextovec(cursor)[2] - (peek2(0x5f2a) \ 8)) < 8
                local att, def = selected_unit, units[cursor]
                create_ui({
                    att.team.." "..att.class,
                    "HP:"..att.HP,
                    "Dmg:"..calculate_damage(att, def),
                    "Hit:"..hit_chance(att.Skl, def.Spd, start).."%"
                }, ui, false, top and "bl" or "tl")
                create_ui({
                    def.team.." "..def.class,
                    "HP:"..def.HP,
                    "Dmg:"..calculate_damage(def, att),
                    "Hit:"..hit_chance(def.Skl, att.Spd, cursor).."%"
                }, ui, false, top and "br" or "tr")

                if btnp(4) then  -- Select button
                    local enemy = units[cursor] -- Check if the cursor is on an attackable enemy
                    if enemy then
                        move_unit(att, vectoindex({att.x,att.y}), start)
                        change_state("combat", {
                            attacker = att,
                            defender = enemy,
                            cursor = cursor
                        })
                        return
                    end
                end
            end
    
            if btnp(5) then
                update_camera(start)
                change_state("action_menu", {unit=selected_unit, cursor=start})
            end
        end,
        draw = function()
            draw_units(units, function (unit)
                return (attackable_units[vectoindex({unit.x,unit.y})] == nil or unit.team != "enemy") and unit ~= selected_unit
            end)
            draw_units(units, function (unit)
                return attackable_units[vectoindex({unit.x,unit.y})] ~= nil and unit.team == "enemy"
            end, true)
            draw_unit_at(selected_unit, start)
            draw_cursor(cursor, true)
            draw_ui(cursor, ui)
        end
    }
end

function create_combat_state()
    local ui, cursor, co, attacker, defender = {}
    return {
        enter = function(p)
            co = cocreate(function()
                local function process_attack(atk, def, is_counter)
                    local hit = will_hit(atk.Skl, def.Spd, vectoindex({def.x,def.y}))
                    local dmg = hit and calculate_damage(atk, def) or 0
                    local broken = is_counter and false or is_attacker_advantage(atk, def)
                    
                    local msg = hit and {
                        atk.team.." "..atk.class.." "..(def.HP - dmg <= 0 and "defeated" or broken and "broke" or "hit"),
                        def.team.." "..def.class,
                        "for "..dmg.." damage!"
                    } or {atk.team.." "..atk.class.." attack missed..."}
                    
                    create_ui(msg, ui, false)
                    yield()
                    ui = {}
                    
                    -- Apply damage
                    if hit then
                        def.HP = max(0, def.HP - dmg)
                        if def.HP <= 0 then
                            units[vectoindex({def.x, def.y})] = nil
                        end
                    end
                    
                    return hit, broken
                end
                
                -- Main combat flow
                attacker, defender, cursor = p.attacker, p.defender, p.cursor
                local hit, broken = process_attack(attacker, defender, false)
                
                -- Counterattack if applicable
                if defender.HP > 0 and (not hit or not broken) then
                    process_attack(defender, attacker, true)
                end
                
                -- End combat
                attacker.exhausted = true
                if attacker.team == "enemy" then
                    change_state("enemy_phase", {cursor=cursor})
                else
                    change_state("overworld", {cursor=cursor})
                end
            end)
            coresume(co)
        end,
        update = function()
            if btnp(4) or btnp(5) then coresume(co) end
        end,
        draw = function()
            draw_units(units, function(u)
                return u ~= attacker and u ~= defender
            end, false)
            if attacker then draw_unit_at(attacker, nil, true) end
            if defender then draw_unit_at(defender, nil, true) end
            draw_ui(cursor, ui)
        end
    }
end

function create_enemy_turn()
    local path, logic_co, anim_co, cursor, enemy = {}
    return {
        enter = function(p)
            enemy, cursor, path = p.enemy, p.cursor, p.path
            logic_co = cocreate(function()
                if path and #path > 0 then
                    path = trim_path_tail_by_costs(path, enemy.Mov)
                    path = trim_path_tail_if_occupied(path, units)
                    
                    -- Start movement animation
                    anim_co = cocreate(function()
                        for i=1,#path do
                            local v = indextovec(path[i])
                            cursor = vectoindex({v[1], v[2]})
                            update_camera(cursor, true)
                            local t = time()
                            while time() - t < 0.2 do yield() end
                        end
                    end)
                    
                    -- Wait for animation completion (or skip)
                    while anim_co and costatus(anim_co) ~= "dead" do
                        yield()
                    end
                    
                    move_unit(enemy, units, cursor)
                end
                
                -- Find attack targets (pure logic)
                local player_units = {}
                for t in all(get_tiles_within_distance(cursor, enemy.Atr)) do
                    local u = units[t]
                    if u and u.team == "player" then add(player_units, u) end
                end
    
                -- Transition to next state
                if #player_units == 0 then
                    local c_idx = check_for_castle(cursor, true)
                    if (c_idx ~= nil) then
                        flip_castle(c_idx, castles)
                        change_state("castle_capture", {cursor=cursor,capturer=enemy})
                    else
                        enemy.exhausted = true
                        change_state("enemy_phase", {cursor=cursor})
                    end
                else
                    SHUFFLE(player_units)
                    change_state("combat", {
                        attacker = enemy,
                        defender = player_units[1],
                        cursor = cursor
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
                    cursor = vectoindex({v[1], v[2]})
                    update_camera(cursor, true)
                end
            end
            
            if logic_co and costatus(logic_co) ~= "dead" then
                local active, exception = coresume(logic_co)
                if exception then
                    printh(trace(logic_co, exception), "logs/debug.txt")
                    stop()
                end
            end
            if anim_co and costatus(anim_co) ~= "dead" then
                local active, exception = coresume(anim_co)
                if exception then
                    printh(trace(anim_co, exception), "logs/debug.txt")
                    stop()
                end
            end
        end,
    
        draw = function()
            draw_nonselected_overworld_units(enemy, units)
            draw_unit_at(enemy, cursor, true)
        end,
    }
end

function create_castle_capture_state()
    local ui, cursor, capturer = {}
    return {
        enter = function(p)
            cursor, capturer, ui = p.cursor, p.capturer, {}
            local msg = {
                capturer.team.." "..capturer.class.." ".."captured",
                (capturer.team == "player" and "enemy" or "player").." castle!"
            }
            create_ui(msg, ui, false)
        end,
        update = function()
            if btnp(4) or btnp(5) then
                capturer.exhausted = true
                local game_over = true
                for _, castle in pairs(castles) do
                    if (castle.team != capturer.team) game_over = false
                end
                if game_over then
                    change_state("game_over", {win=capturer.team=="player"})
                else
                    change_state(capturer.team == "enemy" and "enemy_phase" or "overworld", {cursor=cursor})
                end
            end
        end,
        draw = function()
            draw_units(units, function(u)
                return u ~= capturer
            end, false)
            if capturer then draw_unit_at(capturer, nil, true) end
            draw_ui(cursor, ui)
        end
    }
end

function create_enemy_phase()
    local cam_path, ui, logic_co, anim_co, current_enemy, cursor
    return {
        enter = function(p)
            cursor, ui = p.cursor, {}
            create_ui({"Loading..."}, ui, false)
            local enemies = sort_enemy_turn_order(units)
            printh("amount of enemies: "..#enemies, "logs/debug.txt")
            logic_co = cocreate(function()
                for current_enemy in all(enemies) do
                    local path = find_optimal_attack_path(current_enemy, units, castles, function(pos)
                        local u = units[pos]
                        return (u == nil or u.team == current_enemy.team) and map_get(pos) < 6
                    end)
                    printh("current enemy: "..current_enemy.enemy_ai, "logs/debug.txt")
                    if path then
                        printh("path length: "..#path, "logs/debug.txt")
                        cam_path = generate_full_path(cursor, {current_enemy.x, current_enemy.y})
                        
                        -- Start animation coroutine
                        anim_co = cocreate(function()
                            for i=1,#cam_path do
                                local v = cam_path[i]
                                cursor = vectoindex({v[1], v[2]})
                                update_camera(cursor, true)
                                local t = time()
                                while time() - t < 0.1 do
                                    yield()
                                end
                            end
                        end)
                        
                        -- Wait for animation to complete (or be skipped)
                        while anim_co and costatus(anim_co) ~= "dead" do
                            yield()
                        end
                        
                        -- Proceed to enemy turn
                        change_state("enemy_turn", {enemy=current_enemy, cursor=cursor, path=path})

                        return -- necessary to not continue to the next non-charge unit
                    else
                        current_enemy.exhausted = true
                    end
                end

                -- leave
                change_state("phase_change", {cursor=cursor, phase="player"})
            end)
        end,
    
        update = function()
            if btnp(4) and anim_co then
                -- Skip animation by killing the anim coroutine
                anim_co = nil
                -- Jump to final position
                if cam_path and #cam_path > 0 then
                    local v = cam_path[#cam_path]
                    cursor = vectoindex({v[1], v[2]})
                    update_camera(cursor, true)
                end
            end
            
            if logic_co and costatus(logic_co) ~= "dead" then
                local active, exception = coresume(logic_co)
                if exception then
                    printh(trace(logic_co, exception), "logs/debug.txt")
                    stop()
                end
            end
            if anim_co and costatus(anim_co) ~= "dead" then
                local active, exception = coresume(anim_co)
                if exception then
                    printh(trace(anim_co, exception), "logs/debug.txt")
                    stop()
                end
            end
        end,
    
        draw = function()
            draw_units(units)
            draw_cursor(cursor, true)
            if (not anim_co or costatus(anim_co) == "dead") draw_ui(cursor, ui)
        end
    }
end

function create_phase_change()
    local co, cursor, phase
    return {
        enter = function(p)
            cursor, phase = p.cursor, p.phase
            for _, unit in pairs(units) do
                if (phase == "enemy" and unit.team == "player") or (phase == "player" and unit.team == "enemy") then
                    unit.exhausted = false
                end
            end
            co = cocreate(function()
                local last_move_time = time()
                while time() - last_move_time < 3.0 do
                    yield()
                end
                change_state(phase == "enemy" and "enemy_phase" or "overworld", {cursor=cursor})
            end)
        end,
        update = function()
            update_camera(cursor)
            if btnp(4) then change_state(phase == "enemy" and "enemy_phase" or "overworld", {cursor=cursor}) end
            local active, exception = coresume(co)
            if exception then
                stop(trace(co, exception))
            end
        end,
        draw = function()
            draw_units(units)
            draw_centered_text(
                (phase == "enemy") and "Enemy Phase" or "Player Phase",
                (phase == "enemy") and 8 or 12
            )
        end
    }
end

function create_game_over()
    local win, go_text, reset_text
    return {
        enter = function(p)
            win = p.win
            go_text = not win and "game over" or "stage clear"
            reset_text = "PRESS ANY BUTTON TO RESET"
        end,
        update = function()
            if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
                extcmd('reset')
            end
        end,
        draw = function()
            draw_units(units)
            draw_centered_text(go_text, not win and 8 or 12)
            draw_centered_text(reset_text, 7, 67)
        end
    }
end