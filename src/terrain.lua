local TERRAIN_TYPES = {
    PLAINS = { sprite = 1, cost = 1 },
    FOREST = { sprite = 3, cost = 2 },
    THICKET = { sprite = 4, cost = 4 },
    WATER = { sprite = 2, cost = nil }, -- impassable
    DEEP_WATER = { sprite = 6, cost = nil }, -- impassable
    SAND = { sprite = 5, cost = 2},
    MOUNTAIN = { sprite = 7, cost = nil } -- impassable
}

function generate_terrain(world, components)
    -- Generate random seed between 0 and 32767 (PICO-8's max)
    local seed = flr(rnd(32767))
    -- Clear file on startup by writing with "@" flag
    if not _seeds_initialized then
        printh("", "fe4_seeds.txt", true) -- true = overwrite
        _seeds_initialized = true
    end
    -- Append new seed to file
    printh(
        "Generated map with seed: " .. seed ..
        " at " .. stat(93) .. ":" .. stat(94) .. ":" .. stat(95),
        "fe4_seeds.txt"
    )
    local noise = os2d_noisefn(seed)

    -- Configure detail layers for more natural terrain
    local layers = {
        -- {uv_scale, weight}
        -- { 1 / 32, 1 / 2 }, -- large features (equivalent to 1/32 in original)
        { 1 / 16, 1 },     -- medium features (equivalent to 1/16 in original)
        { 1 / 8,  1 / 2 }, -- small features (equivalent to 1/8 in original)
        { 1 / 4,  1 / 4 }, -- detail (equivalent to 1/4 in original)
        { 1 / 2,  1 / 8 }  -- detail (equivalent to 1/4 in original)
    }

    for y = 0, 64 do
        for x = 0, 96 do
            -- Accumulate height from multiple noise layers
            local h = 0
            for l in all(layers) do
                local scale, weight = unpack(l)
                h += noise(x * scale, y * scale) * weight
            end

            local tile = world.entity()
            tile += components.Position({ x = x, y = y })

            local terrain_type
            if h < -0.5 then
                terrain_type = TERRAIN_TYPES.DEEP_WATER
            elseif h < -0.3 then
                terrain_type = TERRAIN_TYPES.WATER
            elseif h < -0.1 then
                terrain_type = TERRAIN_TYPES.SAND
            elseif h < 0.3 then
                terrain_type = TERRAIN_TYPES.PLAINS
            elseif h < 0.6 then
                terrain_type = TERRAIN_TYPES.FOREST
            elseif h < 0.8 then
                terrain_type = TERRAIN_TYPES.THICKET
            else
                terrain_type = TERRAIN_TYPES.MOUNTAIN
            end

            tile += components.Terrain(terrain_type)
        end
    end
end
