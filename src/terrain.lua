function init_terrain(noise_fn, tree_fn)
    local PRUNE_PROBABILITY = 0.2  -- 20% chance to prune a forest/thicket into plains

    for y = 0, 31 do
        for x = 0, 31 do
            local h, t = 0, 0
            -- Calculate terrain height using noise_fn
            for l in all(LAYERS) do
                local scale, weight = unpack(l)
                h += noise_fn(x * scale, y * scale) * weight
            end
            -- Calculate tree density using tree_fn
            for l in all(TREE_LAYERS) do
                local scale, weight = unpack(l)
                t += tree_fn(x * scale, y * scale) * weight
            end

            -- Determine terrain type based on height (h)
            if h < -0.6 then
                mset(x, y, 6) -- sea
            elseif h < -0.2 then
                mset(x, y, 2) -- shoal
            elseif h < -0.1 then
                mset(x, y, 5) -- sand
            elseif h < 0.8 then
                -- Determine forest/thicket/plains based on tree density (t)
                if t <= 0.3 then
                    mset(x, y, 1) -- plain
                elseif t <= 0.7 then
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
