-- Find the largest square of grass tiles in a given area
function find_largest_square(start_x, start_y, width, height, quadrant)
    local dp = {}
    for y = 0, height - 1 do
        dp[y] = 0
    end

    local max_size = 0
    local candidates = {}  -- Store all squares of max size
    local diagonal = 0

    -- Process column by column from right to left
    for x = width - 1, 0, -1 do
        for y = height - 1, 0, -1 do
            local tmp = dp[y]

            local world_x = start_x + x
            local world_y = start_y + y
            local terrain = mget(world_x, world_y)
            local is_grass = terrain == 1

            if not is_grass then
                dp[y] = 0
            else
                -- Get all three neighbors
                local right = dp[y]
                local bottom = (y < height - 1) and dp[y + 1] or 0
                local min_val = min(right, min(bottom, diagonal))
                dp[y] = 1 + min_val

                if dp[y] >= max_size then
                    if dp[y] > max_size then
                        -- New max found, clear previous candidates
                        candidates = {}
                        max_size = dp[y]
                    end
                    -- Add this square to candidates
                    add(candidates, {
                        x = world_x,
                        y = world_y,
                        size = dp[y]
                    })
                end
            end
            diagonal = tmp
        end
    end

    if #candidates > 0 then
        -- Pick best candidate based on quadrant preference
        local best_score = 32767  -- Large number
        local best_candidate = nil

        for c in all(candidates) do
            local score = 0
            local quad_center_x = start_x + (width \ 2)
            local quad_center_y = start_y + (height \ 2)

            if quadrant == 1 then  -- Top-left
                score = abs(c.x - start_x) + abs(c.y - start_y)
            elseif quadrant == 2 then  -- Top-right
                score = abs(c.x - (start_x + width - 1)) + abs(c.y - start_y)
            elseif quadrant == 3 then  -- Bottom-left
                score = abs(c.x - start_x) + abs(c.y - (start_y + height - 1))
            else  -- Bottom-right
                score = abs(c.x - (start_x + width - 1)) + abs(c.y - (start_y + height - 1))
            end

            -- Also factor in distance from center to avoid extremes
            score = score + (abs(c.x - quad_center_x) + abs(c.y - quad_center_y)) \ 2

            if score < best_score then
                best_score = score
                best_candidate = c
            end
        end
        return best_candidate
    end
    return nil
end

-- Get the offset for placing a castle based on its quadrant and size
function get_castle_offset(quadrant, size)
    -- For odd-sized squares, use center placement
    if size % 2 == 1 then
        return (size \ 2), (size \ 2)
    end

    -- For even-sized squares, bias based on quadrant
    local half = size / 2

    if quadrant == 1 then
        return half - 1, half - 1
    elseif quadrant == 2 then
        return half, half - 1
    elseif quadrant == 3 then
        return half - 1, half
    else
        return half, half
    end
end

-- Find the best spots for castles in each quadrant
function find_castle_spots()
    local quadrants = {
        { x_start = 0, x_end = 15, y_start = 0, y_end = 15 },
        { x_start = 16, x_end = 31, y_start = 0, y_end = 15 },
        { x_start = 0, x_end = 15, y_start = 16, y_end = 31 },
        { x_start = 16, x_end = 31, y_start = 16, y_end = 31 }
    }

    local best_spots = {}

    -- Find largest square in each quadrant
    for i, quad in ipairs(quadrants) do
        local width = quad.x_end - quad.x_start + 1
        local height = quad.y_end - quad.y_start + 1
        local spot = find_largest_square(quad.x_start, quad.y_start, width, height, i)
        if spot then
            spot.quadrant = i
            add(best_spots, spot)
        end
    end

    return best_spots
end

function init_castles(castles)
    local spots, cursor = find_castle_spots()
    local player = flr(rnd(4)) + 1
    for i, spot in ipairs(spots) do
        local offset_x, offset_y = get_castle_offset(spot.quadrant, spot.size)
        local x, y = spot.x + offset_x, spot.y + offset_y
        local idx = vectoindex({ x, y })
        if (i == player) cursor = idx
        castles[idx] = { team = i == player and "player" or "enemy", units = {} }
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