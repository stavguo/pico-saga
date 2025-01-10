local terrain_noise_fn = nil

function init_terrain_renderer(noise_fn)
    terrain_noise_fn = noise_fn
end

-- Get terrain type at any world position
function get_terrain_at(x, y)
    -- Skip if out of bounds
    if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT then
        return nil
    end

    local h = 0
    
    for l in all(LAYERS) do
        local scale, weight = unpack(l)
        h += terrain_noise_fn(x * scale, y * scale) * weight
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