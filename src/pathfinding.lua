-- A* algorithm implementation with support for multiple target coordinates
function a_star(start_x, start_y, target_coords, units, max_movement)
    frontier = {}
    insert(frontier, start, 0)
    came_from = {}
    came_from[vectoindex(start)] = nil
    cost_so_far = {}
    cost_so_far[vectoindex(start)] = 0
    found_goal = false

    while (#frontier > 0 and #frontier < 1000) do
        current = popEnd(frontier)

        if vectoindex(current) == vectoindex(goal) then
            found_goal = true
            break
        end

        local neighbours = getNeighbours(current)
        for next in all(neighbours) do
            local nextIndex = vectoindex(next)
            
            local new_cost = cost_so_far[vectoindex(current)]  + 1 -- add extra costs here

            if (cost_so_far[nextIndex] == nil) or (new_cost < cost_so_far[nextIndex]) then
                cost_so_far[nextIndex] = new_cost
                local priority = new_cost + heuristic(goal, next)
                insert(frontier, next, priority)
                
                came_from[nextIndex] = current
                
                if (nextIndex != vectoindex(start)) and (nextIndex != vectoindex(goal)) then
                    mset(next[1],next[2],19)
                end
            end 
        end
    end

    if found_goal then
        current = came_from[vectoindex(goal)]
        path = {}
        local cindex = vectoindex(current)
        local sindex = vectoindex(start)

        while cindex != sindex do
            add(path, current)
            current = came_from[cindex]
            cindex = vectoindex(current)
        end
        reverse(path)

        for point in all(path) do
            mset(point[1],point[2],18)
        end
    end
end

-- manhattan distance on a square grid
function heuristic(a, b)
    return abs(a[1] - b[1]) + abs(a[2] - b[2])
end
   
-- find all existing neighbours of a position that are not walls
function getNeighbours(pos)
    local neighbours={}
    local x = pos[1]
    local y = pos[2]
    if x > 0 and (mget(x-1,y) != wallId) then
        add(neighbours,{x-1,y})
    end
    if x < 15 and (mget(x+1,y) != wallId) then
        add(neighbours,{x+1,y})
    end
    if y > 0 and (mget(x,y-1) != wallId) then
        add(neighbours,{x,y-1})
    end
    if y < 15 and (mget(x,y+1) != wallId) then
        add(neighbours,{x,y+1})
    end
    -- for making diagonals
    if (x+y) % 2 == 0 then
        reverse(neighbours)
    end
    return neighbours
end
