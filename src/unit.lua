function create_unit(x, y, class, team, enemy_ai, exhausted)
    local unit = {
        x = x,
        y = y,
        team = team,
        class = class,
        enemy_ai = enemy_ai,
        exhausted = exhausted
    }
    for k,v in pairs(UNIT_STATS[class]) do unit[k] = v end
    return unit
end

function move_unit(u, new_idx, old_idx)
    if CASTLES[old_idx] then
        CASTLES[old_idx].units[vectoindex({u.x,u.y})]=nil
    else
        UNITS[vectoindex({u.x,u.y})]=nil
    end
    u.x,u.y=unpack(indextovec(new_idx))
    UNITS[new_idx]=u
end

function get_neighbors(idx,f)
    local v=indextovec(idx)
    local n={}
    local d={{-1,0},{1,0},{0,-1},{0,1}}

    for i=1,#d do
        local x,y=v[1]+d[i][1],v[2]+d[i][2]
        if x>=0 and x<MAP_W and y>=0 and y<MAP_W then
            local ni=vectoindex({x,y})
            if not f or f(ni) then add(n,ni) end
        end
    end

    if idx%2>0 then reverse(n) end
    return n
end

function get_random_class()
    local player_classes = get_keys(UNIT_STATS)
    return player_classes[flr(rnd(#player_classes)) + 1]
end

function populate_player_castle(castle, num_units)
    for i = 1, num_units do
        local row, pos = i \ 2, i % 2
        local is_left = pos == 1
        local x = is_left and 5 or 10
        local y = row * 2 + (is_left and 3 or 1)
        
        castle.units[vectoindex({x,y})] = create_unit(x, y, get_random_class(), "player", nil, false)
        SUMMARY.players[2] += 1
    end
end

function init_player_units(cursor)
    local num_enemy_castles, units_per_castle, player_castle = 0, 2
    for i, castle in pairs(CASTLES) do
        if i == cursor then
            player_castle = castle
        else
            num_enemy_castles = num_enemy_castles + 1
        end
    end

    local throne = rnd(1) < 0.5 and 7 or 8
    player_castle.units[vectoindex({throne,1})] = create_unit(throne, 1, get_random_class(), "player", nil, false)
    SUMMARY.players[2] += 1
    
    populate_player_castle(player_castle, units_per_castle * num_enemy_castles)
end

function count_player_units(units)
    local counts = {}
    for i, unit in pairs(units) do
        if unit.team == "player" then
            counts[unit.class] = (counts[unit.class] or 0) + 1
        end
    end
    return counts
end

function find_majority_class(counts)
    local majority_class, max_count = "", 0
    for class, count in pairs(counts) do
        if count > max_count then
            majority_class, max_count = class, count
        end
    end
    return majority_class
end

function get_counter_class(mc)
    if mc == "Archer" or mc == "Mage" or mc == "Thief" then
        local non_monk_classes = {"Sword", "Axe", "Lance", "Archer", "Mage", "Thief"}
        return non_monk_classes[flr(rnd(#non_monk_classes)) + 1]
    end
    
    local counters = WEAPON_TRIANGLE[mc]
    if counters then
        return counters[flr(rnd(#counters)) + 1]
    end
end

function init_enemy_units(cursor)
    for castle_idx, castle in pairs(CASTLES) do
        if castle.team == "enemy" then
            -- Find traversable tiles around the castle within the specified movement distance
            local traversable_tiles = find_traversable_tiles(castle_idx, 4)
            local filtered_tiles = {}
            for k, _ in pairs(traversable_tiles) do
                if map_get(k) == 1 then
                    add(filtered_tiles, k)
                end
            end

            SHUFFLE(filtered_tiles)

            for i = 1, 2 do
                if i <= #filtered_tiles then
                    local tileIdx = filtered_tiles[i]
                    local pos = indextovec(tileIdx)
                    local unit_class
                    if rnd(1) < 0.5 then
                        local counts = count_player_units(CASTLES[cursor].units)
                        local majority = find_majority_class(counts)
                        printh("majority unit: "..majority, "logs/debug.txt")
                        unit_class = get_counter_class(majority)
                        printh("good matchup made: "..unit_class, "logs/debug.txt")
                    else
                        unit_class = get_random_class()
                    end

                    UNITS[tileIdx] = create_unit(
                        pos[1],
                        pos[2],
                        unit_class,
                        "enemy",
                        ({"Charge","Range"})[flr(rnd(2))+1])
                        SUMMARY.enemies[2] += 1
                end
            end
        end
    end
end

function get_tiles_within_distance(tile_idx, max_distance, filter_func)
    local result, start = {}, indextovec(tile_idx)
    for x = start[1] - max_distance, start[1] + max_distance do
        for y = start[2] - max_distance, start[2] + max_distance do
            -- Check if the tile is within bounds (0,0 to 31,31)
            if x >= 0 and x < MAP_W and y >= 0 and y < MAP_W then
                -- Calculate Manhattan distance
                local distance = abs(x - start[1]) + abs(y - start[2])
                -- Add to result if within max_distance
                if distance <= max_distance then
                    local current = vectoindex({x, y})
                    if filter_func == nil or filter_func(current) then
                        add(result, current)
                    end
                end
            end
        end
    end
    return result
end

function hit_chance(att, def, def_idx)
    local accuracy, evade = 2 * att.Skl, 2 * def.Spd + (TERRAIN_EFFECTS[map_get(def_idx)] or 0)
    if is_adv(att, def) then accuracy *= 1.2 end
    if is_adv(def, att) then evade *= 1.2 end
    return mid(0, accuracy - evade, 100)
end

function get_dmg(att, def)
    local attack = att.Str > att.Mag and att.Str or att.Mag
    local defense = att.Str > att.Mag and def.Def or def.Mdf
    return max(1, attack - defense)
end

function will_hit(att, def, def_idx)
    return flr(rnd(100)) < hit_chance(att, def, def_idx)
end

function is_adv(att, def)
    local advantage_classes = WEAPON_TRIANGLE[att.class]
    if advantage_classes then
        for class in all(advantage_classes) do
            if class == def.class then
                return true  -- Attacker has advantage, defender cannot counterattack
            end
        end
    end
    return false  -- No advantage, defender can counterattack
end

function draw_units(filter, flashing, units)
    for _, unit in pairs(units or UNITS) do
        if not filter or filter(unit) then
            draw_unit_at(unit, nil, flashing)
        end
    end
end

function draw_unit_at(unit, map_idx, flashing)
    -- Default to unit's position if x and y are not provided
    local pos = map_idx and indextovec(map_idx) or nil
    local x, y = pos ~= nil and pos[1] or unit.x, pos ~= nil and pos[2] or unit.y

    -- Only draw if flashing is false or the flashing condition is met
    if not flashing or t() % 0.5 < 0.4 then
        -- Apply palette changes
        if unit.exhausted and unit.team == "player" then
            for col in all({14, 12, 10, 2}) do
                pal(col, 1) -- Change palette for exhausted player units
            end
        end
            
        if unit.team == "enemy" then
            pal(12, 8)  -- Change palette for normal enemy units
            pal(1, 2)
        end

        -- Draw the unit's sprite at the specified position
        spr(unit.Sprite, x * 8, y * 8)

        -- Reset the palette to default after drawing
        pal()
    end
end

function draw_nonselected_overworld_units(selected)
    draw_units(function (unit)
        return unit ~= selected
    end)
end

function sort_enemy_turn_order()
    local sorted_enemies = {}
    
    for _,unit in pairs(UNITS) do
        if unit.team == "enemy" and not unit.exhausted then
            local priority = -(unit.y * MAP_W + unit.x)
            insert(sorted_enemies, unit, priority)
        end
    end
    
    local result = {}
    for _,item in ipairs(sorted_enemies) do
        add(result, item[1])
    end
    
    return result
end

function reinforcements()
    local opts = {}
    for i, castle in pairs(CASTLES) do
        if castle.hp > 0 and castle.team == "enemy" then add(opts, {i, castle}) end
    end
    if next(opts) then
        SHUFFLE(opts)
        local idx = opts[1][1]
        local x, y = unpack(indextovec(idx))
        -- Create random charge unit over selected castle
        UNITS[idx] = create_unit(
                        x,
                        y,
                        get_random_class(),
                        "enemy",
                        "Charge")
        SUMMARY.enemies[2] += 1
        reduce_castle(idx)
    end
end
