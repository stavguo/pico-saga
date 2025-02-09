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

    if h < -0.6 then
        return TERRAIN_TYPES.SEA
    elseif h < -0.2 then
        return TERRAIN_TYPES.SHOAL
    elseif h < -0.1 then
        return TERRAIN_TYPES.SAND
    elseif h < 0.5 then
        return TERRAIN_TYPES.PLAINS
    elseif h < 0.6 then
        return TERRAIN_TYPES.FOREST
    elseif h < 0.8 then
        return TERRAIN_TYPES.THICKET
    else
        return TERRAIN_TYPES.MOUNTAIN
    end

    -- if h < -0.5 then
    --     return TERRAIN_TYPES.DEEP_WATER
    -- elseif h < -0.3 then
    --     return TERRAIN_TYPES.WATER
    -- elseif h < -0.1 then
    --     return TERRAIN_TYPES.SAND
    -- elseif h < 0.3 then
    --     return TERRAIN_TYPES.PLAINS
    -- elseif h < 0.6 then
    --     return TERRAIN_TYPES.FOREST
    -- elseif h < 0.8 then
    --     return TERRAIN_TYPES.THICKET
    -- else
    --     return TERRAIN_TYPES.MOUNTAIN
    -- end
end

-- Get visible tile coordinates based on cursor position
function get_visible_tiles()
    -- Convert camera position from pixels to tiles
    local cam_tile_x = flr(CAMERA.x / 8)
    local cam_tile_y = flr(CAMERA.y / 8)
    
    -- Calculate visible area bounds
    -- Add 1 extra tile on each side to prevent pop-in during scrolling
    local min_x = max(0, cam_tile_x - 1)
    local max_x = min(MAP_WIDTH - 1, cam_tile_x + SCREEN_TILES_WIDTH + 1)
    local min_y = max(0, cam_tile_y - 1)
    local max_y = min(MAP_HEIGHT - 1, cam_tile_y + SCREEN_TILES_HEIGHT + 1)
    
    return min_x, max_x, min_y, max_y
end

-- Draw visible terrain
function draw_terrain()
    local min_x, max_x, min_y, max_y = get_visible_tiles()
    
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