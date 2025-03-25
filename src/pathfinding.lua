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
function a_star(start, goal, max_movement, filter_func)
    frontier = {}
    insert(frontier, start, 0)
    came_from = {}
    came_from[start] = nil
    cost_so_far = {}
    cost_so_far[start] = 0
    found_goal = false
    end_point = nil

    while (#frontier > 0 and #frontier < 1025) do
        current = popEnd(frontier)

        if current == goal then
            found_goal = true
            end_point = current
            break
        end

        if found_goal then
            break
        end

        local neighbours = get_neighbors(indextovec(current), filter_func)
        for next in all(neighbours) do
            local nextIndex = vectoindex(next)
            
            -- Calculate movement cost based on terrain
            local tile = mget(next[1], next[2])
            local terrain_cost = TERRAIN_COSTS[tile] or 0 -- Default to 0 if tile is not in TERRAIN_COSTS
            local new_cost = cost_so_far[current] + terrain_cost

            if (cost_so_far[nextIndex] == nil) or (new_cost < cost_so_far[nextIndex]) then
                cost_so_far[nextIndex] = new_cost
                local priority = new_cost + heuristic(indextovec(goal), next)
                insert(frontier, nextIndex, priority)
                
                came_from[nextIndex] = current
            end 
        end
    end

    if found_goal then
        -- Reconstruct the path, excluding the start
        local path = {}
        local current = end_point
        while current do
            if came_from[current] == nil then
                break
            end
            add(path, current)
            current = came_from[current]
        end
        reverse(path)

        -- Calculate cumulative movement cost and trim the path
        local remaining_movement = max_movement
        local trimmed_path = {}
        for i, t_idx in ipairs(path) do
            local point = indextovec(t_idx)
            local tile = mget(point[1], point[2])
            local cost = TERRAIN_COSTS[tile] or 0 -- Default to 0 if tile is not in TERRAIN_COSTS

            if remaining_movement >= cost then
                add(trimmed_path, point)
                remaining_movement = remaining_movement - cost
            else
                break -- Stop if the unit cannot move further
            end
        end

        -- Return the trimmed path
        return trimmed_path
    else
        return nil -- Return nil if no path is found
    end
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

    -- 2. Perform UCS to find movement costs
    local start_key = vectoindex({finder.x, finder.y})
    local frontier = {start_key}
    local costs = {}
    costs[start_key] = 0

    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(indextovec(current))
        for _, n in pairs(neighbors) do
            local key = vectoindex(n)
            local cost = TERRAIN_COSTS[mget(n[1], n[2])]
            if cost then
                local new_cost = costs[current] + cost
                if costs[key] == nil or new_cost < costs[key] then
                    if filter_func == nil or filter_func(n) then
                        costs[key] = new_cost
                        add(frontier, key)
                    end
                end
            end
        end
    end

    -- 3. Find intersection and sort using your insert
    local potential = {} -- Returns array of {key,...} sorted by cost
    for pos_key in pairs(attackable) do
        if costs[pos_key] then
            insert(potential, pos_key, costs[pos_key])
        end
    end

    -- 4. Use a_star to get shortest path to best potential dest tile
    local path = a_star(start_key, potential[#potential][1], finder.Mov, filter_func)

    return path  
end

function create_path_follower(path, interval, on_step, on_complete)
    local co = cocreate(function()
        for i=1,#path do
            on_step(path[i])
            local t=time()
            while time()-t < interval do
                yield()
            end
        end
        if on_complete then on_complete() end
    end)
    return co
end