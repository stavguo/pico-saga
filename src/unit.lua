function create_unit(x, y, class, team, enemy_ai, exhausted)
    return {
        x = x,
        y = y,
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
        exhausted = exhausted
    }
end

function generate_units(total_units)
    -- Create base units list with guaranteed counts
    local types = {}
    for _,v in pairs(UNIT_MINS) do
      for i=1,v[2] do
        add(types, v[1])
      end
    end

    -- Distribute remaining units randomly
    for i=1,total_units - #types do
        local r = flr(rnd(#UNIT_MINS)) + 1
        add(types, UNIT_MINS[r][1])
    end

    SHUFFLE(types)
    return types
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

function init_player_units(cursor)
    local player_classes, actual = generate_units(42), 1

    for i, castle in pairs(CASTLES) do
        -- Place leader
        if i == cursor then
            local throne = rnd(1) < 0.5 and 7 or 8
            castle.units[vectoindex({throne,1})] = create_unit(throne, 1, player_classes[actual], "player", nil, false)
            actual += 1
        end

        -- Place units in formation
        for j = 0, (i == cursor and 7 or 3) do
            local row, pos = j \ 4, j % 4
            local is_right = pos >= 2
            local x = is_right and (11 + (pos - 2) * 2) or (2 + pos * 2)
            local y = 2 + row * 2
            castle.units[vectoindex({x,y})] = create_unit(x, y, player_classes[actual], "player", nil, (i ~= cursor and true or false))
            actual += 1
        end
    end
end

function init_enemy_units()
    for castle_idx, castle in pairs(CASTLES) do
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
            for i = 1, 2 do

                -- Get a random tile from the shuffled list
                if i <= #filtered_tiles then
                    local tileIdx = filtered_tiles[i]
                    local pos = indextovec(tileIdx)

                    -- Create the unit at the selected position
                    UNITS[tileIdx] = create_unit(
                        pos[1],
                        pos[2],
                        UNIT_MINS[flr(rnd(#UNIT_MINS))+1][1],
                        "enemy",
                        ({"Charge","Range"})[flr(rnd(2))+1])
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
        spr(unit.sprite, x * 8, y * 8)

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
