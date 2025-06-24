function init_terrain(noise_fn, tree_fn)
    local PRUNE_PROBABILITY = 0.2  -- 20% chance to prune a forest/thicket into plains

    for y = 0, MAP_W - 1 do
        for x = 0, MAP_W - 1 do
            local h, td = 0, 0
            -- Calculate terrain height using noise_fn
            for l in all(LAYERS) do
                local scale, weight = unpack(l)
                h += noise_fn(x * scale, y * scale) * weight
            end
            -- Calculate tree density using tree_fn
            for l in all(TREE_LAYERS) do
                local scale, weight = unpack(l)
                td += tree_fn(x * scale, y * scale) * weight
            end

            -- Determine terrain type based on height (h)
            if h < -0.6 then
                mset(x, y, 6) -- sea
            elseif h < -0.2 then
                mset(x, y, 2) -- shoal
            elseif h < 0.8 then
                -- Determine forest/thicket/plains based on tree density (td)
                if td <= 0.3 then
                    mset(x, y, 1) -- plain
                elseif td <= 0.7 then
                    -- Forest with random pruning
                    if rnd(1) < PRUNE_PROBABILITY then
                        mset(x, y, 1) -- pruned into plain
                    else
                        mset(x, y, 3) -- forest
                    end
                else
                    -- Thicket with random pruning
                    if rnd(1) < PRUNE_PROBABILITY then
                        mset(x, y, 1) -- pruned into plain
                    else
                        mset(x, y, 4) -- thicket
                    end
                end
            else
                mset(x, y, 7) -- mountain
            end
        end
    end
end

function draw_traversable_edges(traversable_tiles, col)
    -- Create lookup table
    local traversable_lookup = {}
    for key,_ in pairs(traversable_tiles) do
        traversable_lookup[key] = true
    end

    -- Set line color (7 is white, change as needed)
    color(col)

    for key,_ in pairs(traversable_lookup) do
        local pos = indextovec(key)
        local x, y = pos[1], pos[2]
        
        -- Get screen coordinates
        local sx, sy = x*8, y*8
        
        -- Check each edge (up, right, down, left)
        -- Up edge
        if not traversable_lookup[vectoindex({x, y-1})] then
            line(sx, sy, sx+8, sy)  -- Top edge
        end
        
        -- Right edge
        if not traversable_lookup[vectoindex({x+1, y})] then
            line(sx+8, sy, sx+8, sy+8)  -- Right edge
        end
        
        -- Down edge
        if not traversable_lookup[vectoindex({x, y+1})] then
            line(sx, sy+8, sx+8, sy+8)  -- Bottom edge
        end
        
        -- Left edge
        if not traversable_lookup[vectoindex({x-1, y})] then
            line(sx, sy, sx, sy+8)  -- Left edge
        end
    end
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
    -- Sort all edges using our insert function
    local sorted_edges = generate_edges(V)

    -- Initialize DSU and result collection
    local dsu, mst_edges, count = dsu_new(V), {}, 0

    for i = #sorted_edges, 1, -1 do
        local edge = sorted_edges[i]
        local x, y = edge[1][1], edge[1][2]
        
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

    if #sorted_edges > 0 then
        local l_edge = sorted_edges[1]
        local lx, ly = indextovec(l_edge[1][1]), indextovec(l_edge[1][2])
        printh("Longest edge was {"..lx[1]..","..lx[2].."} -> {"..ly[1]..","..ly[2].."} with weight: "..l_edge[2], "logs/debug.txt")
    end

    return mst_edges
end

function make_routes(V)
    for edge in all(kruskals(V)) do
        local path = generate_full_path(indextovec(edge[1]),indextovec(edge[2]))
        for i = 1, #path -1 do
            local tile, next_tile = path[i], path[i + 1]
            local tx, ty, nx, ny = tile[1], tile[2], next_tile[1], next_tile[2]
            local dx, dy = nx - tx, ny - ty
            local spr = abs(dx) > abs(dy) and 16 or 17
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