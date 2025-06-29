function create_setup_state()
    local co, step
    return {
        enter = function()
            step = 0
            co = cocreate(function()
                local seed, treeseed, _seeds_initialized = flr(rnd(32767)), flr(rnd(32767))
                if not _seeds_initialized then
                    _seeds_initialized = true
                end
                local noise_fn, tree_fn = os2d_noisefn(seed), os2d_noisefn(treeseed)
        
                init_terrain(noise_fn, tree_fn)
                local cursor = init_castles()
                if cursor then
                    init_player_units(cursor)
                    init_enemy_units()
                    yield()
                    step = 1
                    yield()
                    change_state("phase_change", {cursor=cursor, phase="player"})
                end
            end)
            local active, exception = coresume(co)
            if exception then
                stop(trace(co, exception))
            end
        end,
        update = function()
            if btnp(5) then coresume(co) end
        end,
        draw = function()
            if step == 0 then
                print("v1.0", peek2(0x5f28) + 1, peek2(0x5f2a) + 1, 7)
                sspr( (42 % 16) * 8, (42 \ 16) * 8, 16 * 3, 16, peek2(0x5f28) + 1, peek2(0x5f2a) + 12, 32 * 3, 32)
                draw_centered_text(t() % 0.5 < 0.4 and "press ❎ to start " or "press    to start", 7, 65)
                draw_centered_text("★ 2025, stavguo ", 7, 120)
            elseif step == 1 then
                draw_centered_text("victory:", 12, 36)
                draw_centered_text("liberate all enemy castles", 7, 43)
                draw_centered_text("defeat:", 8, 57)
                draw_centered_text("stop the enemy from", 7, 64)
                draw_centered_text("capturing all your castles", 7, 71)
                draw_centered_text(t() % 0.5 < 0.4 and "press ❎ to continue " or "press    to continue", 7, 85)
            end
        end
    }
end

function create_overworld_state()
    local cursor, selected_unit, traversable_tiles, ui
    return {
        enter = function(p)
            ui, selected_unit = {}
            if p then
                if p.cursor then cursor = p.cursor end
            end
        end,
        update = function()
            if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
                if selected_unit and selected_unit.team == "player" then
                    if not selected_unit.exhausted then
                        change_state("move_unit", {unit=selected_unit, cursor=cursor, start=cursor})
                    end
                else
                    cursor, ui = update_cursor(cursor), {}
                end
            end
    
            if btnp(5) then
                if not next(ui) then
                    change_state("turn_end", {cursor=cursor})
                else
                    selected_unit, traversable_tiles, ui = nil, nil, {}
                end
            end
    
            -- Select castle or unit
            if btnp(4) then
                ui = {}
                local castle, unit = CASTLES[cursor], UNITS[cursor]
                if castle then
                    change_state("castle", {castle=castle, pos=cursor})
                elseif unit then
                    selected_unit = unit
                    traversable_tiles = find_traversable_tiles(cursor, selected_unit.Mov, function (idx)
                        local u = UNITS[idx]
                        return (u == nil or u.team == selected_unit.team) and TERRAIN_COSTS[map_get(idx)]
                    end)
                    create_unit_info(selected_unit, ui)
                else
                    local m_idx = map_get(cursor)
                    local t_cost, t_avo = TERRAIN_COSTS[m_idx], TERRAIN_EFFECTS[m_idx]
                    create_ui({
                        TERRAIN_TYPES[m_idx],
                        (t_cost and "mOV:-"..t_cost or nil),
                        (t_avo and "aVO:"..(t_avo > 0 and "+" or "")..t_avo.."%" or nil)
                    }, ui)
                end
            end
        end,
        draw = function()
            if selected_unit then
                draw_traversable_edges(traversable_tiles, selected_unit.team == "player" and 7 or 8)
                draw_unit_at(selected_unit, nil, true)
            end
            draw_nonselected_overworld_units(selected_unit)
            draw_cursor(cursor, true)
            draw_ui(cursor, ui)
        end
    }
end

function create_castle_state()
    local selected_unit, castle, pos, cursor, ui
    return {
        enter = function(p)
            castle, pos, cursor, ui, selected_unit = p.castle, p.pos, p.pos, {}
        end,
        update = function()
            if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
                if selected_unit then
                    if not selected_unit.exhausted then
                        change_state("move_unit", {unit=selected_unit, cursor=pos, start=pos})
                    end
                else
                    cursor = update_cursor(cursor)
                end
            end
    
            if btnp(5) then
                if not selected_unit then
                    change_state("overworld", {cursor=pos})
                else
                    selected_unit, ui = nil, {}
                end
            elseif btnp(4) then
                local unit = castle.units[cursor]
                if unit then
                    selected_unit, ui = unit, {}
                    create_unit_info(selected_unit, ui)
                end
            end
        end,
        draw = function()
            draw_castle_interior()
            draw_units(function (unit)
                return unit ~= selected_unit
            end, false, castle.units)
            if selected_unit then
                draw_unit_at(selected_unit, nil, true)
            end
            draw_cursor(cursor, true)
            draw_ui(cursor, ui)
        end
    }
end

function create_move_state()
    local selected_unit, cursor, start, traversable_tiles
    return {
        enter = function(p)
            selected_unit, cursor, start = p.unit, p.cursor, p.start
            traversable_tiles = find_traversable_tiles(start, selected_unit.Mov, function (idx)
                local unit = UNITS[idx]
                return (unit == nil or unit.team == selected_unit.team) and TERRAIN_COSTS[map_get(idx)]
            end)
        end,
        update = function()
            local old_cursor = cursor
        
            cursor = update_cursor(cursor)
        
            if not traversable_tiles[cursor] then
                cursor = old_cursor
            end
        
            -- Select tile to move to
            if btnp(4) then
                local unit_at_tile = UNITS[cursor]
                if TERRAIN_COSTS[map_get(cursor)] and not unit_at_tile or unit_at_tile == selected_unit then
                    change_state("action_menu", {unit=selected_unit, cursor=cursor, start=start})
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
    local ui, cursor, selected_unit, start, c_idx
    return {
        enter = function(p)
            selected_unit, cursor, start, ui = p.unit, p.cursor, p.start, {}
            c_idx=check_for_castle(cursor)
            local opts={}
            if #get_tiles_within_distance(cursor, selected_unit.Atr, function (idx)
                local unit = UNITS[idx]
                return unit and unit.team == "enemy"
            end) > 0 then add(opts,"attack") end
            add(opts,(CASTLES[c_idx] == nil) and "standby" 
                or (CASTLES[c_idx].hp > 0) and "siege" 
                or "liberate")
            create_ui(opts,ui,true)
        end,
        update = function()
            update_ui(ui)
            if btnp(4) then
                local opt = get_ui_selection(ui)
                if opt == "attack" then
                    change_state("attack_menu", { pos = cursor, start = start, unit = selected_unit })
                else
                    move_unit(selected_unit, cursor, start)
                    if opt == "liberate" then
                        flip_castle(c_idx)
                        change_state("castle_capture", {cursor=cursor, capturer=selected_unit, castle=c_idx})
                    else
                        if opt == "siege" then
                            reduce_castle(c_idx)
                        end
                        selected_unit.exhausted = true
                        change_state("overworld", {cursor=cursor})
                    end
                end
            end
            if btnp(5) then
                change_state("move_unit", {unit=selected_unit, cursor=cursor, start=start})
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
    local cursor, selected_unit, ui, pos, start, attackable_units, reachable
    return {
        enter = function(p)
            selected_unit, pos, start, cursor, attackable_units, ui, reachable = p.unit, p.pos, p.start, p.pos, {}, {}, {}
            for tile in all(get_tiles_within_distance(cursor, selected_unit.Atr)) do
                reachable[tile] = true
                local unit = UNITS[tile]
                if unit and unit.team == "enemy" then
                    attackable_units[tile] = true
                end
            end
        end,
        update = function()
            ui = {}

            cursor = update_cursor(cursor)

            if attackable_units[cursor] then
                local top = (indextovec(cursor)[2] - (peek2(0x5f2a) \ 8)) < 8
                local att, def = selected_unit, UNITS[cursor]
                create_ui({
                    att.team.." "..att.class,
                    "HP:"..att.HP,
                    "Dmg:"..get_dmg(att, def),
                    "Hit:"..flr(hit_chance(att, def, cursor)).."%"
                }, ui, false, top and "bl" or "tl")
                create_ui({
                    def.team.." "..def.class,
                    "HP:"..def.HP,
                    "Dmg:"..get_dmg(def, att),
                    "Hit:"..flr(hit_chance(def, att, pos)).."%"
                }, ui, false, top and "br" or "tr")

                if btnp(4) then  -- Select button
                    local enemy = UNITS[cursor] -- Check if the cursor is on an attackable enemy
                    if enemy then
                        move_unit(att, pos, start)
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
                change_state("action_menu", {unit=selected_unit, cursor=pos, start=start})
            end
        end,
        draw = function()
            draw_traversable_edges(reachable, 7)
            draw_units(function (unit)
                return (attackable_units[vectoindex({unit.x,unit.y})] == nil or unit.team != "enemy") and unit ~= selected_unit
            end)
            draw_units(function (unit)
                return attackable_units[vectoindex({unit.x,unit.y})] ~= nil and unit.team == "enemy"
            end, true)
            draw_unit_at(selected_unit, pos)
            draw_cursor(cursor, true)
            draw_ui(cursor, ui)
        end
    }
end

function create_combat_state()
    local ui, cursor, co, attacker, defender = {}
    return {
        enter = function(p)
            attacker, defender, cursor = p.attacker, p.defender, p.cursor
            co = cocreate(function()
                local function process_attack(atk, def, is_counter)
                    local hit = will_hit(atk, def, vectoindex({def.x,def.y}))
                    local dmg = hit and get_dmg(atk, def) or 0
                    local broken = is_counter and false or is_adv(atk, def)
                    
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
                            UNITS[vectoindex({def.x, def.y})] = nil
                            if def.team == "player" then
                                SUMMARY.players[1] += 1
                            else
                                SUMMARY.enemies[1] += 1
                            end
                        end
                    end
                    
                    return hit, broken
                end
                
                -- Main combat flow
                local hit, broken = process_attack(attacker, defender, false)
                
                -- Counterattack if possible
                if defender.Atr >= man_dist({defender.x,defender.y},{attacker.x,attacker.y}) and defender.HP > 0 and (not hit or not broken) then
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
            draw_units(function(u)
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
                    path = trim_path_tail_if_occupied(path)
                    
                    -- Start movement animation
                    anim_co = cocreate(function()
                        for i=1,#path do
                            local v = indextovec(path[i])
                            cursor = vectoindex({v[1], v[2]})
                            local lt = time()
                            while time() - lt < 0.2 do yield() end
                        end
                    end)
                    
                    -- Wait for animation completion (or skip)
                    while anim_co and costatus(anim_co) ~= "dead" do
                        yield()
                    end
                    
                    move_unit(enemy, cursor)
                end
                
                -- Find attack targets (pure logic)
                local player_units = {}
                for idx in all(get_tiles_within_distance(cursor, enemy.Atr)) do
                    local u = UNITS[idx]
                    if u and u.team == "player" then add(player_units, u) end
                end
    
                -- Transition to next state
                if #player_units == 0 then
                    local c_idx = check_for_castle(cursor, true)
                    if (c_idx ~= nil) then
                        flip_castle(c_idx)
                        change_state("castle_capture", {cursor=cursor, capturer=enemy, castle=c_idx})
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
                end
            end
            
            if logic_co and costatus(logic_co) ~= "dead" then
                coresume(logic_co)
            end
            if anim_co and costatus(anim_co) ~= "dead" then
                coresume(anim_co)
            end
        end,
    
        draw = function()
            draw_nonselected_overworld_units(enemy)
            draw_unit_at(enemy, cursor, true)
        end,
    }
end

function create_enemy_phase()
    local c_path, logic_co, anim_co, cursor
    return {
        enter = function(p)
            cursor = p.cursor
            local enemies = sort_enemy_turn_order()
            logic_co = cocreate(function()
                for current_enemy in all(enemies) do
                    local path = find_optimal_attack_path(current_enemy, function(pos)
                        local u = UNITS[pos]
                        return (u == nil or u.team == current_enemy.team) and TERRAIN_COSTS[map_get(pos)]
                    end)
                    if path then
                        c_path = generate_full_path(indextovec(cursor), {current_enemy.x, current_enemy.y})
                        
                        -- Start animation coroutine
                        anim_co = cocreate(function()
                            for i=1,#c_path do
                                local v = c_path[i]
                                cursor = vectoindex({v[1], v[2]})
                                local lt = time()
                                while time() - lt < 0.1 do
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

                local lt = time()
                while time() - lt < 0.5 do yield() end

                -- leave
                change_state("phase_change", {cursor=cursor, phase="player"})
            end)
        end,
    
        update = function()
            if btnp(4) and anim_co then
                -- Skip animation by killing the anim coroutine
                anim_co = nil
                -- Jump to final position
                if next(c_path) then
                    local v = c_path[#c_path]
                    cursor = vectoindex({v[1], v[2]})
                end
            end
            
            if logic_co and costatus(logic_co) ~= "dead" then
                coresume(logic_co)
            end
            if anim_co and costatus(anim_co) ~= "dead" then
                coresume(anim_co)
            end
        end,
    
        draw = function()
            draw_units()
            draw_cursor(cursor, true)
        end
    }
end

function create_phase_change()
    local co, cursor, phase
    return {
        enter = function(p)
            SUMMARY.phases += 1
            cursor, phase = p.cursor, p.phase
            for _, unit in pairs(UNITS) do
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
            if btnp(4) then change_state(phase == "enemy" and "enemy_phase" or "overworld", {cursor=cursor}) end
            coresume(co)
        end,
        draw = function()
            draw_units()
            draw_centered_text(
                (phase == "enemy") and "Enemy Phase" or "Player Phase",
                (phase == "enemy") and 8 or 12,
                8
            )
        end,
        exit = function()
            if phase == "enemy" then
                reinforcements()
            end
        end
    }
end

function create_castle_capture_state()
    local ui, cursor, capturer, castle = {}
    return {
        enter = function(p)
            cursor, capturer, castle, ui = p.cursor, p.capturer, p.castle, {}
            local unit_count = tablelength(CASTLES[castle].units)
            local msg = {
                capturer.team.." "..capturer.class.." "..(capturer.team == "player" and "liberated" or "captured"),
                (capturer.team == "player" and "enemy" or "player").." castle!",
                (unit_count > 0 and (unit_count.." unit"..(unit_count > 1 and "s" or "").." "..(capturer.team == "player" and "released" or "imprisoned")) or nil)
            }
            create_ui(msg, ui, false)
        end,
        update = function()
            if btnp(4) or btnp(5) then
                capturer.exhausted = true
                local game_over = true
                for _, castle in pairs(CASTLES) do
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
            draw_nonselected_overworld_units(capturer)
            if capturer then draw_unit_at(capturer, nil, true) end
            draw_ui(cursor, ui)
        end
    }
end

function create_turn_end_confirmation()
    local cursor
    return {
        enter = function(p)
            cursor = p.cursor
        end,
        update = function()
            if btnp(4) then
                change_state("phase_change", {cursor=cursor, phase="enemy"})
            elseif btnp(5) then
                change_state("overworld", {cursor=cursor})
            end
        end,
        draw = function()
            draw_units()
            draw_centered_text("🅾️:end turn ", 8)
            draw_centered_text("❎:go back ", 12, 67)
        end
    }
end

function create_game_over()
    local win, go_text, reset_text
    return {
        enter = function(p)
            win = p.win
            go_text = not win and "defeat" or "victory"
        end,
        update = function()
            if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
                change_state("setup")
            end
        end,
        draw = function()
            draw_units()
            draw_centered_text(go_text, not win and 8 or 12, 39)
            draw_centered_text("phases:"..SUMMARY.phases, 7, 53)
            draw_centered_text("units lost:"..SUMMARY.players[1].."/"..SUMMARY.players[2], 7, 60)
            draw_centered_text("foes defeated:"..SUMMARY.enemies[1].."/"..SUMMARY.enemies[2], 7, 67)
            draw_centered_text("press any button to reset", 7, 81)
        end,
        exit = function()
            reset()
            CASTLES, UNITS = {}, {}
        end
    }
end