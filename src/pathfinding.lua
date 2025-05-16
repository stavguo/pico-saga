-- Uniform cost search implementation that limits search range based on unit movement
function find_traversable_tiles(start, movement, filter_func)
    local frontier, prev, costs = {start}, {}, {}
    costs[start] = 0
    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(current, filter_func)
        for key in all(neighbors) do
            local cost = TERRAIN_COSTS[map_get(key)] or nil
            if cost then
                local new_cost = costs[current] + cost
                if not movement or new_cost <= movement then
                    if not costs[key] or new_cost < costs[key] then
                        costs[key], prev[key] = new_cost, current
                        add(frontier, key)
                    end
                end
            end
        end
    end
    return costs, prev
end

function find_optimal_attack_path(finder, units, castles, filter_func)
    printh("should def be find_optimal_attack_path", "logs/debug.txt")
    -- 1. Identify all attackable positions
    local attackable = {}
    
    -- Mark tiles adjacent to player units
    for _, unit in pairs(units) do
        if unit.team == "player" then
            local range_tiles = get_tiles_within_distance(
                vectoindex({unit.x, unit.y}),
                finder.Atr,
                function(pos)
                    local unit = get_unit_at(pos, units, false)
                    return (unit == nil or unit == finder) and map_get(pos) < 6
                end
            )
            for _, pos in ipairs(range_tiles) do
                attackable[pos] = true
            end
        end
    end

    -- Mark player castles
    for castle_idx, castle in pairs(castles) do
        if castle.team == "player" then
            local range_tiles = get_neighbors(
                castle_idx,
                function(pos)
                    local unit = get_unit_at(pos, units, false)
                    return (unit == nil or unit == finder) and map_get(pos) < 6
                end
            )
            for pos in all(range_tiles) do
                attackable[pos] = true
            end
        end
    end

    local count = 0
    for k, v in pairs(attackable) do
        count = count + 1
    end

    if next(attackable) == nil then return {} end

    -- 2. Perform pathfinding to find movement costs
    local start_vec = {finder.x, finder.y}
    local start_key = vectoindex(start_vec)
    local costs, prev
    printh(finder.enemy_ai, "logs/debug.txt")
    if finder.enemy_ai == "Charge" then
        printh("should def be charging", "logs/debug.txt")
        costs, prev = find_traversable_tiles(start_key, nil, filter_func)
    elseif finder.enemy_ai == "Range" then
        costs, prev = find_traversable_tiles(start_key, finder.Mov, filter_func)
    elseif finder.enemy_ai == "Range2" then
        costs, prev = find_traversable_tiles(start_key, finder.Mov * 2, filter_func)
    end
    

    -- 3. Find intersection and sort using your insert
    local potential = {} -- Returns array of {{key,cost},...} sorted by cost desc
    for pos_key in pairs(attackable) do
        if costs[pos_key] then
            insert(potential, pos_key, costs[pos_key])
        end
    end

    -- 4. Reconstruct path
    if #potential >= 1 then
        return reconstruct_path(prev, potential[#potential][1])
    end
    return nil  
end

function trim_path_tail_if_occupied(path, units)
    for i=#path,1,-1 do
        local point = indextovec(path[i])
        if not get_unit_at(point, units) then
            break
        end
        deli(path, i)
    end
    return path
end

function trim_path_tail_by_costs(path, mov)
    local r,p=mov,{}
    for i=1,#path do
        local v=indextovec(path[i])
        local c=TERRAIN_COSTS[mget(v[1],v[2])] or 0
        if r<c then break end
        add(p,path[i])
        r-=c
    end
    return p
end

function reconstruct_path(prev, target_key)
    local path = {}
    local current = target_key
    while current and prev[current] do
        add(path, current)
        current = prev[current]
    end
    reverse(path)
    return path
end

function generate_full_path(start, goal)
    start = indextovec(start)
    local path, dx, dy = {}, goal[1] - start[1], goal[2] - start[2]
    if abs(dx) > abs(dy) then
        for x = start[1], goal[1], dx > 0 and 1 or -1 do
            add(path, {x, start[2]})
        end
        for y = start[2], goal[2], dy > 0 and 1 or -1 do
            add(path, {goal[1], y})
        end
    else
        for y = start[2], goal[2], dy > 0 and 1 or -1 do
            add(path, {start[1], y})
        end
        for x = start[1], goal[1], dx > 0 and 1 or -1 do
            add(path, {x, goal[2]})
        end
    end
    return path
end