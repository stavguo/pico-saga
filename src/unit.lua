function create_unit(x, y, class, team, in_castle)
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
        Atr = UNIT_STATS[class].Atr
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
    units[old_key] = nil
    
    -- Update position
    unit.x, unit.y = cursor[1], cursor[2]
    
    -- Add new position
    local new_key = vectoindex({unit.x, unit.y})
    units[new_key] = unit
end

function deploy_unit(unit, units, cursor)
    -- Remove old position from units
    local old_key = vectoindex({unit.x, unit.y})
    if units[old_key] then
        units[old_key] = nil
    end
    
    -- Update unit state
    unit.x, unit.y = cursor[1], cursor[2]
    unit.in_castle = false
    
    -- Add to new position
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

function find_traversable_tiles(cursor, units, movement, unit_team)
    traversable_tiles = {} -- Clear previous tiles
    traversable_tiles[vectoindex(cursor)] = true

    local frontier = {{cursor[1], cursor[2]}}
    local costs = {}
    costs[vectoindex(cursor)] = 0

    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(current)
        for _, n in pairs(neighbors) do
            local key = vectoindex(n)
            local cost = TERRAIN_COSTS[mget(n[1], n[2])]
            if cost then
                local new_cost = costs[vectoindex(current)] + cost
                if new_cost <= movement and (not costs[key] or new_cost < costs[key]) then
                    -- Check if the tile is occupied by an opposing unit
                    local unit_at_tile = get_unit_at(n, units)
                    if not unit_at_tile or unit_at_tile.team == unit_team then
                        costs[key] = new_cost
                        add(frontier, n)
                        traversable_tiles[key] = true
                    end
                end
            end
        end
    end
    return traversable_tiles
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

function init_enemy_units(units)
    local enemy_classes = {
        "Sword", "Sword", "Sword", "Sword",
        "Lance", "Lance", "Lance", "Lance",
        "Axe", "Axe", "Axe", "Axe"
    }
    SHUFFLE(enemy_classes)
    local enemies_per_quad = 4
    local quadrants = {
        --{ x_start = 0, x_end = 15, y_start = 0, y_end = 15 },  -- Q1: explicitly 0,0 to 15,15
        { x_start = 16, x_end = 31, y_start = 0, y_end = 15 },  -- Q2: explicitly 16,0 to 31,15
        { x_start = 0, x_end = 15, y_start = 16, y_end = 31 },  -- Q3: explicitly 0,16 to 15,31
        { x_start = 16, x_end = 31, y_start = 16, y_end = 31 }  -- Q4: explicitly 16,16 to 31,31
    }

    local class_index = 1
    -- Find largest square in each quadrant
    for quad in all(quadrants) do
        local traversable_tiles = {}
        for y = quad.y_start, quad.y_end do
            for x = quad.x_start, quad.x_end do
                local terrain = mget(x, y)
                if terrain == 1 then
                    add(traversable_tiles, {x = x, y = y})
                end
            end
        end
        SHUFFLE(traversable_tiles)
        for i = 1, enemies_per_quad do
            local x = traversable_tiles[i].x
            local y = traversable_tiles[i].y
            units[vectoindex({x,y})] = create_unit(x, y, enemy_classes[class_index], "enemy", false)
            class_index = class_index + 1
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
    local base_hit_rate = 70  -- Example base hit rate
    local accuracy = base_hit_rate + (attacker.Skl) - (defender.Spd + terrain_effect)
    return mid(0, accuracy, 100)  -- Clamp between 0% and 100%
end

function calculate_damage(attacker, defender)
    local damage = attacker.Str > attacker.Mag and attacker.Str - defender.Def or attacker.Mag - defender.Mdf
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
        -- Apply palette changes for enemy units
        if unit.team == "enemy" then
            pal(12, 8, 0)  -- Change palette for enemy units
            pal(1, 2, 0)
        end

        -- Draw the unit's sprite at the specified position
        spr(unit.sprite, x * 8, y * 8)

        -- Reset palette if it was changed
        if unit.team == "enemy" then
            pal()
        end
    end
end

function draw_nonselected_overworld_units(selected, units)
    draw_units(units, function (unit)
        return unit ~= selected and not unit.in_castle
    end)
end
