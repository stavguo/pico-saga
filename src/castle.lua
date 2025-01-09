-- https://www.geeksforgeeks.org/maximum-size-sub-matrix-with-all-1s-in-a-binary-matrix/#using-space-optimized-dp-onm-time-and-on-space
function find_largest_square(start_x, start_y, width, height)
    local dp = {}
    
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
            
            local world_x = start_x + x
            local world_y = start_y + y
            local terrain = get_terrain_at(world_x, world_y)
            local is_grass = terrain and terrain.sprite == 1
            
            if not is_grass then
                dp[y] = 0
            else
                -- Get all three neighbors
                local right = dp[y]
                local bottom = (y < height-1) and dp[y+1] or 0
                -- Take minimum of all three at once, matching C++ logic
                local min_val = min(right, min(bottom, diagonal))
                dp[y] = 1 + min_val
                
                if dp[y] > max_size then
                    max_size = dp[y]
                    best_x = x
                    best_y = y
                    printh("New max square: size="..dp[y].." at ("..world_x..","..world_y..")", "fe4_debug.txt")
                end
            end
            diagonal = tmp
        end
    end
    
    if max_size > 0 then
        return {
            x = start_x + best_x,
            y = start_y + best_y,
            size = max_size
        }
    end
    return nil
end

function find_castle_spots()
    local quadrants = {
        {x_start=0,  x_end=15, y_start=0,  y_end=15},  -- Q1: explicitly 0,0 to 15,15
        {x_start=16, x_end=31, y_start=0,  y_end=15},  -- Q2: explicitly 16,0 to 31,15
        {x_start=0,  x_end=15, y_start=16, y_end=31},  -- Q3: explicitly 0,16 to 15,31
        {x_start=16, x_end=31, y_start=16, y_end=31}   -- Q4: explicitly 16,16 to 31,31
    }
    
    local best_spots = {}
    
    -- Find largest square in each quadrant
    for i, quad in ipairs(quadrants) do
        local width = quad.x_end - quad.x_start + 1
        local height = quad.y_end - quad.y_start + 1
        
        printh("Checking quadrant " .. i .. " range: (" .. 
               quad.x_start .. "," .. quad.y_start .. ") to (" .. 
               quad.x_end .. "," .. quad.y_end .. ")", 
               "fe4_castles.txt")
               
        local spot = find_largest_square(quad.x_start, quad.y_start, width, height)
        if spot then
            spot.quadrant = i
            add(best_spots, spot)
            printh("Found spot in Q" .. i .. ": size=" .. spot.size .. 
                   " at (" .. spot.x .. "," .. spot.y .. ")", 
                   "fe4_castles.txt")
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