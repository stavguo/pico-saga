local TERRAIN_TYPES = {
    PLAINS = { sprite = 1, cost = 1 },
    FOREST = { sprite = 3, cost = 2 },
    THICKET = { sprite = 4, cost = 4 },
    WATER = { sprite = 2, cost = nil }, -- impassable
    DEEP_WATER = { sprite = 6, cost = nil }, -- impassable
    SAND = { sprite = 5, cost = 2},
    MOUNTAIN = { sprite = 7, cost = nil } -- impassable
}

local current_seed = nil
local noise_fn = nil

-- Initialize with a seed
function init_terrain_renderer()
    current_seed = flr(rnd(32767))
    if not _seeds_initialized then
        printh("", "fe4_seeds.txt", true)
        _seeds_initialized = true
    end
    printh(
        "Generated map with seed: " .. current_seed ..
        " at " .. stat(93) .. ":" .. stat(94) .. ":" .. stat(95),
        "fe4_seeds.txt"
    )
    noise_fn = os2d_noisefn(current_seed)
end

-- Get terrain type at any world position
function get_terrain_at(x, y)
    -- Skip if out of bounds
    if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT then
        return nil
    end

    local h = 0
    local layers = {
        { 1 / 16, 1 },
        { 1 / 8,  1 / 2 },
        { 1 / 4,  1 / 4 },
        { 1 / 2,  1 / 8 }
    }
    
    for l in all(layers) do
        local scale, weight = unpack(l)
        h += noise_fn(x * scale, y * scale) * weight
    end

    if h < -0.5 then
        return TERRAIN_TYPES.DEEP_WATER
    elseif h < -0.3 then
        return TERRAIN_TYPES.WATER
    elseif h < -0.1 then
        return TERRAIN_TYPES.SAND
    elseif h < 0.3 then
        return TERRAIN_TYPES.PLAINS
    elseif h < 0.6 then
        return TERRAIN_TYPES.FOREST
    elseif h < 0.8 then
        return TERRAIN_TYPES.THICKET
    else
        return TERRAIN_TYPES.MOUNTAIN
    end
end

-- Get visible tile coordinates based on cursor position
function get_visible_tiles(cursor_x, cursor_y)
    -- Calculate viewport bounds
    local view_center_x = mid(SCREEN_TILES_WIDTH/2, 
                             cursor_x, 
                             MAP_WIDTH - SCREEN_TILES_WIDTH/2)
    local view_center_y = mid(SCREEN_TILES_HEIGHT/2, 
                             cursor_y, 
                             MAP_HEIGHT - SCREEN_TILES_HEIGHT/2)

    -- Calculate visible area bounds
    local min_x = flr(max(0, view_center_x - SCREEN_TILES_WIDTH/2))
    local max_x = flr(min(MAP_WIDTH-1, view_center_x + SCREEN_TILES_WIDTH/2))
    local min_y = flr(max(0, view_center_y - SCREEN_TILES_HEIGHT/2))
    local max_y = flr(min(MAP_HEIGHT-1, view_center_y + SCREEN_TILES_HEIGHT/2))

    return min_x, max_x, min_y, max_y
end

-- Draw visible terrain
function draw_terrain(cursor_x, cursor_y)
    local min_x, max_x, min_y, max_y = get_visible_tiles(cursor_x, cursor_y)
    
    -- Draw all visible tiles
    for y = min_y, max_y do
        for x = min_x, max_x do
            local terrain = get_terrain_at(x, y)
            if terrain then
                spr(terrain.sprite, x * 8, y * 8)
            end
        end
    end
end