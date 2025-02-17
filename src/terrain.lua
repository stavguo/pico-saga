function init_terrain(noise_fn)
    for y = 0, 31 do
        for x = 0, 31 do
            local h = 0
            for l in all(LAYERS) do
                local scale, weight = unpack(l)
                h += noise_fn(x * scale, y * scale) * weight
            end
            if h < -0.6 then
                mset(x, y, 6) -- sea
            elseif h < -0.2 then
                mset(x, y, 2) -- shoal
            elseif h < -0.1 then
                mset(x, y, 5) -- sand
            elseif h < 0.5 then
                mset(x, y, 1) -- plain
            elseif h < 0.6 then
                mset(x, y, 3) -- forest
            elseif h < 0.8 then
                mset(x, y, 4) -- thicket
            else
                mset(x, y, 7) -- mountain
            end
        end
    end
end
