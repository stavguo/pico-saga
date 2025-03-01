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

    if quadrant == 1 then  -- Top-left quadrant
        return half - 1, half - 1  -- Bias towards top-left
    elseif quadrant == 2 then  -- Top-right quadrant
        return half, half - 1  -- Bias towards top-right
    elseif quadrant == 3 then  -- Bottom-left quadrant
        return half - 1, half  -- Bias towards bottom-left
    else  -- Bottom-right quadrant
        return half, half  -- Bias towards bottom-right
    end
end

-- Find the best spots for castles in each quadrant
function find_castle_spots()
    local quadrants = {
        { x_start = 0, x_end = 15, y_start = 0, y_end = 15 },  -- Q1: explicitly 0,0 to 15,15
        { x_start = 16, x_end = 31, y_start = 0, y_end = 15 },  -- Q2: explicitly 16,0 to 31,15
        { x_start = 0, x_end = 15, y_start = 16, y_end = 31 },  -- Q3: explicitly 0,16 to 15,31
        { x_start = 16, x_end = 31, y_start = 16, y_end = 31 }  -- Q4: explicitly 16,16 to 31,31
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
    local cursor
    local spots = find_castle_spots()
    for i, spot in ipairs(spots) do
        -- Get biased offset based on quadrant
        local offset_x, offset_y = get_castle_offset(spot.quadrant, spot.size)

        local x = spot.x + offset_x
        local y = spot.y + offset_y
        mset(x, y, i == 1 and 8 or 9)

        -- Initialize cursor for the player's castle
        if i == 1 then
            cursor = { x, y }
            add(castles, {x = x, y = y, team = "player"})
        else
            add(castles, {x = x, y = y, team = "enemy"})
        end
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
