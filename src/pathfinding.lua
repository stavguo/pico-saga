-- A* algorithm implementation with support for multiple target coordinates
function a_star(start, goal, target_coords, max_movement, filter_func)
    frontier = {}
    insert(frontier, start, 0)
    came_from = {}
    came_from[vectoindex(start)] = nil
    cost_so_far = {}
    cost_so_far[vectoindex(start)] = 0
    found_goal = false
    end_point = nil

    while (#frontier > 0 and #frontier < 1025) do
        current = popEnd(frontier)

        for _, coord in ipairs(target_coords) do
            if vectoindex(current) == vectoindex(coord) then
                found_goal = true
                end_point = current
                break
            end
        end

        if found_goal then
            break
        end

        local neighbours = get_neighbors(current, filter_func)
        for next in all(neighbours) do
            local nextIndex = vectoindex(next)
            
            -- Calculate movement cost based on terrain
            local tile = mget(next[1], next[2])
            local terrain_cost = TERRAIN_COSTS[tile] or 0 -- Default to 0 if tile is not in TERRAIN_COSTS
            local new_cost = cost_so_far[vectoindex(current)] + terrain_cost

            if (cost_so_far[nextIndex] == nil) or (new_cost < cost_so_far[nextIndex]) then
                cost_so_far[nextIndex] = new_cost
                local priority = new_cost + heuristic(goal, next)
                insert(frontier, next, priority)
                
                came_from[nextIndex] = current
            end 
        end
    end

    if found_goal then
        -- Reconstruct the path, excluding the start
        local path = {}
        local current = end_point
        while current do
            if came_from[vectoindex(current)] == nil then
                break
            end
            add(path, current)
            current = came_from[vectoindex(current)]
        end
        reverse(path)

        -- Calculate cumulative movement cost and trim the path
        local remaining_movement = max_movement
        local trimmed_path = {}
        for i, point in ipairs(path) do
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

function find_target(finder, units, castles)
    local weakest_hp = 32767
    local weakest_unit
    for _, unit in pairs(units) do
        if unit.team == "player" and not unit.in_castle then
            if unit.HP < weakest_hp then
                weakest_hp = unit.HP
                weakest_unit = {unit.x, unit.y}
            end
        end
    end
    if weakest_unit == nil then
        local closest_distance = 32767
        local closest_castle
        for _, castle in pairs(castles) do
            if castle.team == "player" then
                local dist = heuristic({finder.x, finder.y}, {castle.x, castle.y})
                if dist < closest_distance then
                    closest_distance = dist
                    closest_castle = {castle.x, castle.y}
                end
            end
        end
        return closest_castle, "castle"
    else
        return weakest_unit, "unit"
    end
end
