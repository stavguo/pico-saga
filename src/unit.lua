function create_unit(x, y, class, team, in_castle, enemy_ai, castle_idx)
    return {
        x = x,
        y = y,
        in_castle = in_castle,
        sprite = UNIT_STATS[class].Sprite,
        team = team,
        class = class,
        HP = UNIT_STATS[class].HP,
        Str = UNIT_STATS[class].Str,
        Mag = UNIT_STATS[class].Mag,
        Skl = UNIT_STATS[class].Skl,
        Spd = UNIT_STATS[class].Spd,
        Def = UNIT_STATS[class].Def,
        Mdf = UNIT_STATS[class].Mdf,
        Mov = UNIT_STATS[class].Mov,
        Atr = UNIT_STATS[class].Atr,
        enemy_ai = enemy_ai,
        castle_idx = castle_idx,
        exhausted = false
    }
end

function get_unit_at(cursor, units, in_castle)
    local unit = units[cursor]
    if unit then
        if in_castle == nil and not unit.in_castle then
            return unit
        else
            if unit.in_castle == in_castle then
                return unit
            end
        end
    end
    return nil
end

function move_unit(u, old_idx, new_idx)
    if castles[old_idx] then
        castles[old_idx].units[vectoindex({u.x,u.y})]=nil
    else
        units[vectoindex({u.x,u.y})]=nil
    end
    u.x,u.y=unpack(indextovec(new_idx))
    units[new_idx]=u
end

function get_neighbors(t,f)
    local v=indextovec(t)
    local n={}
    local d={{-1,0},{1,0},{0,-1},{0,1}}

    for i=1,#d do
        local x,y=v[1]+d[i][1],v[2]+d[i][2]
        if x>=0 and x<32 and y>=0 and y<32 then
            local ni=vectoindex({x,y})
            if not f or f(ni) then add(n,ni) end
        end
    end

    if t%2>0 then reverse(n) end
    return n
end

function init_player_units(units)
    local player_classes = {
        "Sword", "Sword", "Sword",
        "Lance", "Lance", "Lance",
        "Axe", "Axe", "Axe"
    }
    local leader_idx = flr(rnd(9)) + 1
    -- Place leader
    local throne = rnd(1) < 0.5 and 7 or 8
    
    units[vectoindex({throne,1})] = create_unit(throne, 1, player_classes[leader_idx], "player", true)

    -- Place 8 units in formation
    count = 0
    for i = 1, 9 do
        if i ~= leader_idx then
            local row = (count \ 4)
            local pos = count % 4
            local is_right = pos >= 2
            local x = is_right and (11 + (pos - 2) * 2) or (2 + pos * 2)
            local y = 2 + row * 2
            units[vectoindex({x,y})] = create_unit(x, y, player_classes[i], "player", true)
            count = count + 1
        end
    end
end

function init_enemy_units(castles, units)
    for castle_idx, castle in pairs(castles) do
        if castle.team == "enemy" then  -- Only place units around enemy castles
            -- Find traversable tiles around the castle within the specified movement distance
            local traversable_tiles = find_traversable_tiles(castle_idx, 4)
            local filtered_tiles = {}
            for k, _ in pairs(traversable_tiles) do
                if map_get(k) == 1 then
                    add(filtered_tiles, k)
                end
            end

            -- Shuffle the list of tiles
            SHUFFLE(filtered_tiles)

            -- Calculate the number of units to place around this castle
            for i = 1, 4 do

                -- Get a random tile from the shuffled list
                if i <= #filtered_tiles then
                    local tileIdx = filtered_tiles[i]
                    local pos = indextovec(tileIdx)

                    -- Create the unit at the selected position
                    units[tileIdx] = create_unit(
                        pos[1],
                        pos[2],
                        ({'Sword','Lance','Axe'})[flr(rnd(3))+1],
                        "enemy",
                        false,
                        ({"Charge","Range","Range2"})[flr(rnd(3))+1],
                        castle_idx)
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
            if x >= 0 and x < 32 and y >= 0 and y < 32 then
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

function find_enemy(x, y, units)
    local key = vectoindex({x,y})
    return units[key] ~= nil and units[key].team == "enemy"
end

function hit_chance(att_skl, def_spd, def_idx)
    local terrain = map_get(def_idx)
    local terrain_effect = TERRAIN_EFFECTS[terrain] or 0
    local base_hit_rate = 80  -- Example base hit rate
    local accuracy = base_hit_rate + (att_skl) - (def_spd + terrain_effect)
    return mid(0, accuracy, 100)  -- Clamp between 0% and 100%
end

function calculate_damage(attacker, defender)
    local attack = attacker.Str > attacker.Mag and attacker.Str or attacker.Mag
    local defense = attacker.Str > attacker.Mag and defender.Def or defender.Mdf
    if is_attacker_advantage(attacker, defender) then defense = 0 end
    if is_attacker_advantage(defender, attacker) then defense = defense * 2 end
    local damage = attack - defense
    return max(1, damage)  -- Ensure at least 1 damage
end

function will_hit(att_skl, def_spd, def_idx)
    return flr(rnd(100)) < hit_chance(att_skl, def_spd, def_idx)
end

function is_attacker_advantage(attacker, defender)
    local advantage_classes = WEAPON_TRIANGLE[attacker.class]
    if advantage_classes then
        for _, class in ipairs(advantage_classes) do
            if class == defender.class then
                return true  -- Attacker has advantage, defender cannot counterattack
            end
        end
    end
    return false  -- No advantage, defender can counterattack
end

function draw_units(units, filter, flashing)
    for _, unit in pairs(units) do
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
        if unit.exhausted then
            if unit.team == "enemy" then
                pal(12, 2)  -- Change palette for exhausted enemy units
                pal(1, 2)
                pal(10, 2)
            else
                pal(12, 1)  -- Change palette for exhausted player units
                pal(1, 1)
                pal(10, 1)
            end
        else
            if unit.team == "enemy" then
                pal(12, 8)  -- Change palette for normal enemy units
                pal(1, 2)
            end
        end

        -- Draw the unit's sprite at the specified position
        spr(unit.sprite, x * 8, y * 8)

        -- Reset the palette to default after drawing
        pal()
    end
end

function draw_nonselected_overworld_units(selected)
    draw_units(units, function (unit)
        return unit ~= selected
    end)
end

function is_phase_over(team)
    for _, unit in pairs(units) do
        printh(team, "logs/debug.txt")
        printh(unit.exhausted, "logs/debug.txt")
        if unit.team == team and unit.exhausted == false then
            printh("should be returning false", "logs/debug.txt")
            return false
        end
    end
    return true
end

function sort_enemy_turn_order(units, castles)
    local enemies = {}
    local castle_lists = {}
    for k,_ in pairs(castles) do
        castle_lists[k] = {}
    end

    for _,u in pairs(units) do
        if u.team == "enemy" and not u.exhausted then
            local max_dist = 0
            for k,v in pairs(castles) do
                max_dist = max(max_dist, heuristic(indextovec(k),{u.x,u.y}))
            end
            insert(castle_lists[u.castle_idx], u, max_dist)
        end
    end

    for castle_idx, _ in pairs(castle_lists) do
        reverse(castle_lists[castle_idx])
        for item in all(castle_lists[castle_idx]) do
            add(enemies, item) -- item[1] is the unit, item[2] is the distance
        end
    end

    return enemies
end
