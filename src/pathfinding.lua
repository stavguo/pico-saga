-- Uniform cost search implementation that limits search range based on unit movement
function find_traversable_tiles(start, movement, filter_func)
    traversable_tiles = {} -- Clear previous tiles
    traversable_tiles[vectoindex(start)] = 0

    local frontier = {{start[1], start[2]}}
    local costs = {}
    costs[vectoindex(start)] = 0

    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(current)
        for _, n in pairs(neighbors) do
            local key = vectoindex(n)
            local cost = TERRAIN_COSTS[mget(n[1], n[2])]
            if cost then
                local new_cost = costs[vectoindex(current)] + cost
                if new_cost <= movement and (not costs[key] or new_cost < costs[key]) then
                    if filter_func == nil or filter_func(n) then
                        costs[key] = new_cost
                        add(frontier, n)
                        traversable_tiles[key] = new_cost
                    end
                end
            end
        end
    end
    return traversable_tiles
end

-- A* algorithm implementation that trims path based on unit movement
function a_star(start, goal, filter_func)
    costs = {}
    prev = {}
    frontier = {}
    found_goal = false

    costs[start] = 0
    insert(frontier, start, 0)

    while #frontier > 0 do
        current = popEnd(frontier)

        if current == goal then
            found_goal = true
            break
        end

        local neighbours = get_neighbors(indextovec(current), filter_func)
        for next in all(neighbours) do
            local nextIndex = vectoindex(next)
            
            -- Calculate movement cost based on terrain
            local tile = mget(next[1], next[2])
            local terrain_cost = TERRAIN_COSTS[tile] or 0 -- Default to 0 if tile is not in TERRAIN_COSTS
            local new_cost = costs[current] + terrain_cost

            if costs[nextIndex] == nil or new_cost < costs[nextIndex] then
                costs[nextIndex] = new_cost
                prev[nextIndex] = current
                local priority = new_cost + heuristic(indextovec(goal), next)
                insert(frontier, nextIndex, priority)
            end 
        end
    end

    if found_goal then
        return costs, prev
    else
        return nil -- Return nil if no path is found
    end
end

function dijkstra(start_key, filter_func)
    -- Initialize data structures
    local costs = {}       -- costs[key] = cost to reach tile
    local prev = {}       -- prev[key] = previous tile (for path reconstruction)
    local frontier = {}   -- Priority queue: {tile_key, cost}
    
    -- Initialize starting node
    costs[start_key] = 0
    insert(frontier, start_key, 0)  -- Priority = cost

    -- Main loop
    while #frontier > 0 do
        -- Extract lowest-cost tile from frontier
        local current_key = popEnd(frontier)
        local current_pos = indextovec(current_key)

        -- Explore neighbors
        local neighbors = get_neighbors(current_pos, filter_func)
        for neighbor_pos in all(neighbors) do
            local neighbor_key = vectoindex(neighbor_pos)
            local terrain_cost = TERRAIN_COSTS[mget(neighbor_pos[1], neighbor_pos[2])] or 0

            -- Skip if terrain is impassable or cost is undefined
            if not terrain_cost then goto next_neighbor end

            -- Calculate new cost
            local new_cost = costs[current_key] + terrain_cost

            -- Update if new path is better
            if not costs[neighbor_key] or new_cost < costs[neighbor_key] then
                costs[neighbor_key] = new_cost
                prev[neighbor_key] = current_key
                insert(frontier, neighbor_key, new_cost)
            end

            ::next_neighbor::
        end
        ::continue::
    end

    return costs, prev
end

function find_optimal_attack_path(finder, units, castles, filter_func)
    -- 1. Identify all attackable positions
    local attackable = {}
    
    -- Mark tiles adjacent to player units
    for _, unit in pairs(units) do
        if unit.team == "player" and not unit.in_castle then
            local range_tiles = get_tiles_within_distance(
                {unit.x, unit.y},
                finder.Atr,
                function(pos)
                    local unit = get_unit_at(pos, units, false)
                    return (unit == nil or unit == finder) and mget(pos[1], pos[2]) < 6
                end
            )
            for _, pos in ipairs(range_tiles) do
                attackable[vectoindex(pos)] = true
            end
        end
    end

    -- Mark player castles
    for _, castle in pairs(castles) do
        if castle.team == "player" then
            local range_tiles = get_tiles_within_distance(
                {castle.x, castle.y},
                finder.Atr,
                function(pos)
                    local unit = get_unit_at(pos, units, false)
                    return (unit == nil or unit == finder) and mget(pos[1], pos[2]) < 6
                end
            )
            for _, pos in ipairs(range_tiles) do
                attackable[vectoindex(pos)] = true
            end
        end
    end

    local count = 0
    for k, v in pairs(attackable) do
        count = count + 1
    end

    if next(attackable) == nil then return {} end

    -- 2. Perform Dijkstra to find movement costs
    local start_key = vectoindex({finder.x, finder.y})
    local costs, prev = dijkstra(start_key, filter_func)

    -- 3. Find intersection and sort using your insert
    local potential = {} -- Returns array of {{key,cost},...} sorted by cost desc
    for pos_key in pairs(attackable) do
        if costs[pos_key] then
            insert(potential, pos_key, costs[pos_key])
        end
    end

    -- 4. Reconstruct path
    local path = reconstruct_path(prev, potential[#potential][1])

    return path  
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
        local c=TERRAIN_COSTS[mget(v[1],v[2])]or 0
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