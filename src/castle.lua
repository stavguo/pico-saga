-- Find the largest square of grass tiles in a given area
function find_largest_square(start_x, start_y, width, height, targ)
    local dp = {}
    for y = 0, height - 1 do
        dp[y] = 0
    end

    local max_size, candidates, diagonal = 2, {}, 0

    -- Process column by column from right to left
    for x = width - 1, 0, -1 do
        for y = height - 1, 0, -1 do
            local tmp, world_x, world_y = dp[y], start_x + x, start_y + y

            if mget(world_x, world_y) ~= 1 then
                dp[y] = 0
            else
                -- Get all three neighbors
                local right = dp[y]
                local bottom = (y < height - 1) and dp[y + 1] or 0
                local min_val = min(right, min(bottom, diagonal))
                dp[y] = 1 + min_val
                local size = dp[y]

                if size >= max_size then
                    if size > max_size then
                        -- New max found, clear previous candidates
                        candidates = {}
                        max_size = size
                    end
                    local c_loc = get_square_center({world_x, world_y}, size, targ)
                    -- Add this square to candidates
                    insert(candidates, {
                        x = world_x,
                        y = world_y,
                        size = dp[y],
                        center = c_loc
                    }, man_dist(targ, c_loc))
                end
            end
            diagonal = tmp
        end
    end

    return #candidates > 0 and candidates[#candidates][1] or nil
end

function get_square_center(top_left, size, targ)
    -- Odd-sized squares: exact center
    if size % 2 == 1 then
        local offset = size \ 2
        return {top_left[1]+offset, top_left[2]+offset}
    end
    
    -- Even-sized squares: find closest center to target
    local half = size/2
    local candidates, possible_centers = {}, {
        {top_left[1]+half-1, top_left[2]+half-1},  -- top-left
        {top_left[1]+half,    top_left[2]+half-1},  -- top-right
        {top_left[1]+half-1,  top_left[2]+half},    -- bottom-left
        {top_left[1]+half,    top_left[2]+half}     -- bottom-right
    }
    
    for center in all(possible_centers) do
        insert(candidates, center, man_dist(center, targ))
    end
    
    return candidates[#candidates][1]  -- closest center
end

function init_castles()
    local sections, actual = {
        -- Top row (y: 0-4)
        {x_start=0, x_end=4, y_start=0, y_end=4, targ={0, 0}},    -- Top-left
        {x_start=5, x_end=10, y_start=0, y_end=4, targ={7, 0}},   -- Top-center
        {x_start=11, x_end=15, y_start=0, y_end=4, targ={15, 0}}, -- Top-right
        
        -- Middle row (y: 5-10)
        {x_start=0, x_end=4, y_start=5, y_end=10, targ={0, 7}},    -- Mid-left
        {x_start=5, x_end=10, y_start=5, y_end=10, targ={7, 7}},  -- Center
        {x_start=11, x_end=15, y_start=5, y_end=10, targ={15, 7}},-- Mid-right
        
        -- Bottom row (y: 11-15)
        {x_start=0, x_end=4, y_start=11, y_end=15, targ={0, 15}},  -- Bottom-left
        {x_start=5, x_end=10, y_start=11, y_end=15, targ={7, 15}},-- Bottom-center
        {x_start=11, x_end=15, y_start=11, y_end=15, targ={15, 15}}-- Bottom-right
        -- { x_start = 0, x_end = 15, y_start = 0, y_end = 15, targ = {0,0} },
        -- { x_start = 16, x_end = 31, y_start = 0, y_end = 15, targ = {31,0} },
        -- { x_start = 0, x_end = 15, y_start = 16, y_end = 31, targ = {0,31} },
        -- { x_start = 16, x_end = 31, y_start = 16, y_end = 31, targ = {31,31} }
    }, {}
    for sec in all(sections) do
        local w, h = sec.x_end - sec.x_start + 1, sec.y_end - sec.y_start + 1
        local sq = find_largest_square(sec.x_start, sec.y_start, w, h, sec.targ)
        if sq then add(actual, vectoindex(sq.center)) end
    end
    if #actual < 2 then
        printh("NEED TO RESET")
        change_state("setup")
        --return
    end
    make_routes(actual)
    local player, cursor = flr(rnd(#actual)) + 1
    for i, idx in ipairs(actual) do
        local x, y = unpack(indextovec(idx))
        printh("creating castle at "..idx, "logs/debug.txt")
        if (i == player) cursor = idx
        CASTLES[idx] = { team = i == player and "player" or "enemy", units = {} }
        mset(x, y, i == player and 8 or 9)
    end
    return cursor
end

function generate_edges(vertices)
    local edges = {}
    for i=1,#vertices-1 do
        for j=i+1,#vertices do
            local goal, start, cost = vertices[j], vertices[i], 0
            local path = generate_full_path(indextovec(start), indextovec(goal))
            -- for k=1,#path-1 do
            --     cost += TERRAIN_COSTS[mget(path[k][1],path[k][2])]
            -- end
            insert(edges, {start, goal}, #path)
        end
    end
    return edges
end

function dsu_new(V)
    local dsu = {
        parent = {},
        rank = {}
    }
    for v in all(V) do
        dsu.parent[v], dsu.rank[v] = v, 1
    end
    return dsu
end
  
function dsu_find(dsu, i)
    if dsu.parent[i] ~= i then
        dsu.parent[i] = dsu_find(dsu, dsu.parent[i])
    end
    return dsu.parent[i]
end
  
function dsu_union(dsu, x, y)
    local s1 = dsu_find(dsu, x)
    local s2 = dsu_find(dsu, y)
    if s1 ~= s2 then
        if dsu.rank[s1] < dsu.rank[s2] then
            dsu.parent[s1] = s2
        elseif dsu.rank[s1] > dsu.rank[s2] then
            dsu.parent[s2] = s1
        else
            dsu.parent[s2] = s1
            dsu.rank[s1] = dsu.rank[s1] + 1
        end
        return true  -- Indicate a successful union
    end
    return false  -- Indicate no union was performed
end

function kruskals(V)
    printh("kruskals_mst()", "logs/debug.txt")
    -- Sort all edges using our insert function
    local sorted_edges = generate_edges(V)

    -- Initialize DSU and result collection
    local dsu, mst_edges, count = dsu_new(V), {}, 0

    for i = #sorted_edges, 0, -1 do
        local edge = sorted_edges[i]
        local x, y = edge[1][1], edge[1][2]
        printh("edge {"..x..","..y.."} has weight "..edge[2], "logs/debug.txt")
        
        -- Only add edge if it doesn't form a cycle
        if dsu_find(dsu, x) ~= dsu_find(dsu, y) then
            dsu_union(dsu, x, y)
            add(mst_edges, {x, y})  -- Store the edge
            local vx, vy = indextovec(x), indextovec(y)
            printh("adding {"..vx[1]..","..vx[2].."} -> {"..vy[1]..","..vy[2].."} to MST", "logs/debug.txt")
            count += 1
            if count == #V - 1 then
                break  -- MST is complete
            end
        end
    end

    local l_edge = sorted_edges[1]
    local lx, ly = indextovec(l_edge[1][1]), indextovec(l_edge[1][2])
    printh("Longest edge was {"..lx[1]..","..lx[2].."} -> {"..ly[1]..","..ly[2].."}", "logs/debug.txt")

    return mst_edges
end

function make_routes(V)
    for edge in all(kruskals(V)) do
        local path = generate_full_path(indextovec(edge[1]),indextovec(edge[2]))
        for i = 1, #path -1 do
            local tile, next_tile = path[i], path[i + 1]
            local tx, ty, nx, ny = tile[1], tile[2], next_tile[1], next_tile[2]
            local dx, dy = nx - tx, ny - ty
            local spr = abs(dx) > abs(dy) and 13 or 14
            local has_north, has_south, has_east, has_west = false, false, false, false
            local ns = get_tiles_within_distance(vectoindex(tile), 1, function (idx)
                return map_get(idx) == 2 or map_get(idx) == 6
            end)
            for idx in all(ns) do
                local vec = indextovec(idx)
                if vec[1] == tx then
                    -- Vertical neighbor (N or S)
                    if vec[2] < ty then has_north = true
                    elseif vec[2] > ty then has_south = true end
                elseif vec[2] == ty then
                    -- Horizontal neighbor (E or W)
                    if vec[1] > tx then has_east = true
                    elseif vec[1] < tx then has_west = true end
                end
            end
            if (has_north and has_south) or (has_east and has_west) then
                mset(tx, ty, spr)
            else
                mset(tx, ty, 5)
            end
        end
    end
end

-- Draw the interior of a castle
function draw_castle_interior()
    for y = 0, 15 do
        for x = 0, 15 do
            if x == 0 or x == 15 then
                if y == 0 or y == 15 then
                    spr(10, x * 8, y * 8)
                else
                    spr(11, x * 8, y * 8)
                end
            else
                spr(12, x * 8, y * 8)
            end
        end
    end
end

function map_get(t_idx)
    local pos = indextovec(t_idx)
    return mget(pos[1], pos[2])
end

function check_for_castle(t_idx, is_enemy_turn)
    local adj_tiles = get_neighbors(t_idx, function (idx)
        return map_get(idx) == (is_enemy_turn and 8 or 9)
    end)
    return #adj_tiles > 0 and adj_tiles[1] or nil
end

function flip_castle(c_idx)
    local pos, current = indextovec(c_idx), CASTLES[c_idx]
    current.team = current.team == "player" and "enemy" or "player"
    mset(pos[1], pos[2], current.team == "player" and 8 or 9)
    for _,unit in pairs(CASTLES[c_idx].units) do
        unit.exhausted = false
    end
end
