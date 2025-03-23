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

function generate_full_path(start, goal)
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

function move_cursor_along_path(path, cursor, speed, on_arrival, on_delayed_action)
    local current_step = 1
    local last = time()
    local at_end = false
    local pause_start
    local function move_to_end()
        cursor[1], cursor[2] = path[#path][1], path[#path][2]
        update_camera(cursor)
        at_end = true
        if on_arrival then
            on_arrival()
        end
        pause_start = time()
    end
    local function skip_delay()
        if on_delayed_action then
            on_delayed_action()
        end
    end
    return function()
        if btnp(4) then
            if not at_end then
                move_to_end()
            elseif pause_start then
                skip_delay()
            end
        end
        if not at_end and current_step <= #path then
            local target = path[current_step]
            local elapsed = time() - last
            if elapsed >= (1 / speed) then
                cursor[1], cursor[2] = target[1], target[2]
                current_step = current_step + 1
                last = time()
                update_camera(cursor)
            end
            if current_step > #path then
                move_to_end()
            end
        elseif at_end and pause_start then
            if (time() - pause_start) > 1 then
                skip_delay()
            end
        end
    end
end