-- Find the largest square of grass tiles in a given area
function find_largest_square(start_x, start_y, width, height, targ)
    local dp = {}
    for y = 0, height - 1 do
        dp[y] = 0
    end

    local max_size, candidates, diagonal = 3, {}, 0

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

function init_castles(c)
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
        if sq then add(actual, sq.center) end
    end
    if #actual < 2 then
        change_state("setup")
        return
    end
    local player, cursor = flr(rnd(#actual)) + 1
    local clusters = k_medians_cluster(2, actual)
    printh("clusters count at end "..#clusters, "logs/debug.txt")
    for i, cluster in ipairs(clusters) do
        printh("final cluster "..i, "logs/debug.txt")
        for j, point in ipairs(cluster) do
            printh("point "..j.." = {"..point[1]..","..point[2].."}", "logs/debug.txt")
        end
    end
    routes(clusters)
    for i, spot in ipairs(actual) do
        local x, y = unpack(spot)
        local idx = vectoindex(spot)
        if (i == player) cursor = idx
        c[idx] = { team = i == player and "player" or "enemy", units = {} }
        mset(x, y, i == player and 8 or 9)
    end
    return cursor
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

function flip_castle(c_idx, castles)
    local pos, current = indextovec(c_idx), castles[c_idx]
    current.team = current.team == "player" and "enemy" or "player"
    mset(pos[1], pos[2], current.team == "player" and 8 or 9)
    for _,unit in pairs(castles[c_idx].units) do
        unit.exhausted = false
    end
end

function k_medians_cluster(k, points, max_iter)
    printh("Entering k_medians_cluster()", "logs/debug.txt")
    printh("Initializing centroids:", "logs/debug.txt")
    -- Choose k centroids (Forgy) and initialize clusters list
    local centroids, clusters = {}
    SHUFFLE(points)
    for i = 1, k do
        printh("centroid "..i.." = {"..points[i][1]..","..points[i][2].."}", "logs/debug.txt")
        add(centroids, points[i])
    end
    
    printh("Looping until convergence or 100:", "logs/debug.txt")
    -- Loop until convergence
    for i = 1, max_iter or 100 do
        printh("Iteration "..i, "logs/debug.txt")
        -- Clear previous clusters
        local clusters = {}
        for y = 1, k do
            clusters[y] = {}
        end
    
        -- Assign each point to the "closest" centroid 
        for j, point in ipairs(points) do
            local distances = {}
            for k, centroid in ipairs(centroids) do
                insert(distances, k, man_dist(point, centroid))
            end
            add(clusters[distances[#distances][1]], point)
            printh("point "..j.." = {"..point[1]..","..point[2].."} is closer to centroid "..distances[#distances][1], "logs/debug.txt")
        end
        -- Calculate new centroids
        --   (the standard implementation uses the mean of all points in a
        --     cluster to determine the new centroid)
        printh("Calculating new centroids", "logs/debug.txt")
        local new_centroids = {}
        for j, cluster in ipairs(clusters) do
            printh("cluster "..j.." has "..#cluster.." points.", "logs/debug.txt")
            local med = calculate_median(cluster)
            printh("new centroid at {"..med[1]..","..med[2].."}", "logs/debug.txt")
            add(new_centroids, med)
        end 
        
        local should_break = true
        for j = 1, #centroids do
            if centroids[j][1] != new_centroids[j][1] or centroids[j][2] != new_centroids[j][2] then
                should_break = false
            end
        end
        if should_break then
            return clusters
        end
        centroids = new_centroids
    end
    return clusters
end

function calculate_median(points)
    -- Separate x and y coordinates
    local xs, ys = {}, {}
    for p in all(points) do
        insert(xs, p[1], p[1])
        insert(ys, p[2], p[2])
    end
    
    -- Find median
    local mid, median_x, median_y = flr(#xs/2)+1
    printh("mid is "..mid, "logs/debug.txt")
    
    if #xs % 2 == 1 then
        median_x = xs[mid][1]
        median_y = ys[mid][1]
    else
        median_x = (xs[mid-1][1] + xs[mid][1]) \ 2
        median_y = (ys[mid-1][1] + ys[mid][1]) \ 2
    end
    
    return {median_x, median_y}
end

function routes(clusters)
    printh("finding routes", "logs/debug.txt")
    local r,t,d={},{},99
    for i, c in ipairs(clusters) do
        printh("cluster i = "..i, "logs/debug.txt")
        -- Intra-cluster
        for p in all(c) do
            printh("point p = {"..p[1]..","..p[2].."}", "logs/debug.txt")
            if not t[vectoindex(p)] then
                t[vectoindex(p)]=true
                local n,b=99
                for q in all(c) do
                    if p~=q and not t[vectoindex(q)] then
                        a=man_dist(p,q)
                        if a<n then n,b=a,q end
                    end
                end
                if b then
                    printh("closest point 'b' is = {"..b[1]..","..b[2].."}", "logs/debug.txt")
                    -- render path
                    for tile in all(generate_full_path(p,b)) do
                        local water = get_tiles_within_distance(vectoindex(tile), 1, function (idx)
                            return map_get(idx) == 2 or map_get(idx) == 6
                        end)
                        mset(tile[1], tile[2], (#water > 1) and 13 or 5)
                        for adj in all(get_tiles_within_distance(vectoindex(tile), 1, function (idx)
                            return map_get(idx) == 8 or map_get(idx) == 9
                        end)) do
                            t[vectoindex(p)]=true
                        end
                    end
                end
            end
        end
      -- Inter-cluster
    --   if #points>1 and c==points[1] then
    --     for p in all(c) do
    --       for q in all(points[2]) do
    --         a=abs(p.x-q.x)+abs(p.y-q.y)
    --         if a<d then d,a,b=a,p,q end
    --       end
    --     end
    --     if a then line(a,b,r) end
    --   end
    end
    --return r
    return
end