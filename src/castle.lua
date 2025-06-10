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
        { x_start = 0, x_end = 15, y_start = 0, y_end = 15, targ = {0,0} },
        { x_start = 16, x_end = 31, y_start = 0, y_end = 15, targ = {31,0} },
        { x_start = 0, x_end = 15, y_start = 16, y_end = 31, targ = {0,31} },
        { x_start = 16, x_end = 31, y_start = 16, y_end = 31, targ = {31,31} }
    }, {}
    for i, sec in ipairs(sections) do
        local w, h = sec.x_end - sec.x_start + 1, sec.y_end - sec.y_start + 1
        local sq = find_largest_square(sec.x_start, sec.y_start, w, h, sec.targ)
        if sq then add(actual, sq.center) end
    end
    local player, cursor = flr(rnd(#actual)) + 1
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
end