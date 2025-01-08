function find_largest_square(start_x, start_y, width, height)
    local dp = {}
    
    -- Set strict quadrant bounds
    local end_x = start_x + width
    local end_y = start_y + height
    
    -- Initialize dp array
    for y=0,height-1 do
        dp[y] = 0
    end
    
    local max_size = 0
    local best_x, best_y = -1, -1
    local diagonal = 0
    
    -- Process column by column from right to left
    for x=width-1,0,-1 do
        for y=height-1,0,-1 do
            local tmp = dp[y]
            
            -- Check terrain directly instead of using a grid
            local world_x = start_x + x
            local world_y = start_y + y
            local terrain = get_terrain_at(world_x, world_y)
            local is_grass = terrain and terrain.sprite == 1
            
            if not is_grass then
                dp[y] = 0
            else
                local min_val = dp[y]  -- right
                if y < height-1 then
                    min_val = min(min_val, dp[y+1])  -- bottom
                end
                min_val = min(min_val, diagonal)  -- diagonal
                dp[y] = 1 + min_val
                
                -- Track largest square found
                if dp[y] > max_size then
                    max_size = dp[y]
                    best_x = x
                    best_y = y
                end
            end
            diagonal = tmp
        end
    end
    
    -- If we found a valid square
    if max_size > 0 then
        return {
            x = start_x + best_x,
            y = start_y + best_y,
            size = max_size
        }
    end
    return nil
end

function find_castle_spots(num_spots)
    local quad_size = 16
    local quadrants = {
        {x=0, y=0},      -- Q1
        {x=16, y=0},     -- Q2
        {x=0, y=16},     -- Q3
        {x=16, y=16}     -- Q4
    }
    
    local best_spots = {}
    
    -- Find largest square in each quadrant
    for i, quad in ipairs(quadrants) do
        printh("Checking quadrant " .. i .. " at (" .. quad.x .. "," .. quad.y .. ")", "fe4_castles.txt")
        local spot = find_largest_square(quad.x, quad.y, quad_size, quad_size)
        if spot then
            spot.quadrant = i
            add(best_spots, spot)
            printh("Found spot in quadrant " .. i .. " size=" .. spot.size .. " at (" .. spot.x .. "," .. spot.y .. ")", "fe4_castles.txt")
        else
            printh("No valid spot found in quadrant " .. i, "fe4_castles.txt")
        end
    end
    
    return best_spots
end

function init_castles(world, components, noise_fn)
    local spots = find_castle_spots(4)
    
    if not _castle_log_initialized then
        printh("", "fe4_castles.txt", true)
        _castle_log_initialized = true
    end
    
    printh(
        "\n=== Castle Placements at " .. 
        stat(93) .. ":" .. stat(94) .. ":" .. stat(95) .. 
        " ===",
        "fe4_castles.txt"
    )
    
    for i, spot in ipairs(spots) do
        local castle = world.entity()
        -- Place castle at center of the square
        castle += components.Position({ 
            x = spot.x + flr(spot.size/2),
            y = spot.y + flr(spot.size/2)
        })
        castle += components.Castle({ 
            is_player = i == 1
        })
        
        -- Log castle details
        printh(
            "Castle " .. i .. 
            " (Player: " .. tostr(i == 1) .. 
            "): Position=(" .. (spot.x + flr(spot.size/2)) .. 
            "," .. (spot.y + flr(spot.size/2)) .. 
            "), Quadrant=" .. spot.quadrant ..
            ", Square Size=" .. spot.size .. "x" .. spot.size,
            "fe4_castles.txt"
        )
    end
    
    printh("=== End Castle Placements ===\n", "fe4_castles.txt")
end