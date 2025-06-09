function init_terrain(noise_fn, tree_fn)
    local PRUNE_PROBABILITY = 0.2  -- 20% chance to prune a forest/thicket into plains

    for y = 0, 31 do
        for x = 0, 31 do
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
            elseif h < -0.1 then
                mset(x, y, 5) -- sand
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

function draw_side_bars()
    local current_x, current_y = peek2(0x5f28), peek2(0x5f2a)
    local offset_x, offset_y = current_x / 2, current_y / 2
    color(13)
    line(current_x, current_y + 127, current_x + 127, current_y + 127)
    line(current_x + 127, current_y, current_x + 127, current_y + 127)
    color(1)
    line(current_x + offset_x, current_y + 127, current_x + (127/2) + offset_x, current_y + 127)
    line(current_x + 127, current_y + offset_y, current_x + 127, current_y + (127/2) + offset_y)
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