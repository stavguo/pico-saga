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
    local unit = units[vectoindex(cursor)]
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

function move_unit(unit, units, cursor)
    -- Remove old position from units
    local old_key = vectoindex({unit.x, unit.y})
    if (units[old_key]) units[old_key] = nil
    
    -- Update position
    unit.x, unit.y = cursor[1], cursor[2]
    if (unit.in_castle) unit.in_castle = false
    
    -- Add new position
    local new_key = vectoindex({unit.x, unit.y})
    units[new_key] = unit
end

function get_neighbors(pos, filter_func)
    local neighbors = {}
    local directions = {
        {-1, 0}, {1, 0},
        {0, -1}, {0, 1}
    }
    for _, dir in ipairs(directions) do
        local nx, ny = pos[1] + dir[1], pos[2] + dir[2]
        if nx >= 0 and nx < 32 and ny >= 0 and ny < 32 then
            if filter_func == nil or filter_func({nx, ny}) then
                add(neighbors, {nx, ny})
            end
        end
    end
    if (pos[1] + pos[2]) % 2 == 0 then
        reverse(neighbors)
    end
    return neighbors
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

function init_enemy_units(units, castles)
    -- Loop through each castle
    for castle_idx, castle_type in pairs(castles) do
        if castle_type == "enemy" then  -- Only place units around enemy castles
            -- Find traversable tiles around the castle within the specified movement distance
            local pos = indextovec(castle_idx)
            local traversable_tiles = find_traversable_tiles(pos, 4)
            local filtered_tiles = {}
            for k, _ in pairs(traversable_tiles) do
                local pos = indextovec(k)
                local unit = get_unit_at(pos, units)
                local terrain = mget(pos[1], pos[2])
                if unit == nil and terrain == 1 then
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

-- Convert bfs output (list of {x, y} coordinates) to a list of units
function get_attackable_units(bfs_output, units, team)
    local attackable_units = {}
    for _, pos in ipairs(bfs_output) do
        local key = vectoindex(pos)  -- Convert {x, y} to "x,y"
        local unit = units[key]        -- Look up the unit in ENEMY_UNITS
        if unit and unit.team == team then
            attackable_units[key] = unit      -- Add the unit to the list
        end
    end
    return attackable_units
end

function get_tiles_within_distance(start, max_distance, filter_func)
    local result = {}
    for x = start[1] - max_distance, start[1] + max_distance do
        for y = start[2] - max_distance, start[2] + max_distance do
            -- Check if the tile is within bounds (0,0 to 31,31)
            if x >= 0 and x < 32 and y >= 0 and y < 32 then
                -- Calculate Manhattan distance
                local distance = abs(x - start[1]) + abs(y - start[2])
                -- Add to result if within max_distance
                if distance > 0 and distance <= max_distance then
                    if filter_func == nil or filter_func({x, y}) then
                        add(result, {x, y})
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

function hit_chance(attacker, defender)
    local terrain = mget(defender.x, defender.y)
    local terrain_effect = TERRAIN_EFFECTS[terrain] or 0
    local base_hit_rate = 80  -- Example base hit rate
    local accuracy = base_hit_rate + (attacker.Skl) - (defender.Spd + terrain_effect)
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

function will_hit(attacker, defender)
    return flr(rnd(100)) < hit_chance(attacker, defender)
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
            draw_unit_at(unit, nil, nil, flashing)
        end
    end
end

function draw_unit_at(unit, x, y, flashing)
    -- Default to unit's position if x and y are not provided
    x = x or unit.x
    y = y or unit.y

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

function draw_nonselected_overworld_units(selected, units)
    draw_units(units, function (unit)
        return unit ~= selected and not unit.in_castle
    end)
end

function is_phase_over(team, units)
    local actionable = false
    for _, unit in pairs(units) do
        if unit.team == team and not unit.exhausted then
            actionable = true
        end
    end
    return not actionable
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
