local world
local components
local systems
local noise_fn

-- Map dimensions (FE4-like scale)
MAP_WIDTH = 32
MAP_HEIGHT = 32

-- Screen dimensions in tiles
SCREEN_TILES_WIDTH = 16
SCREEN_TILES_HEIGHT = 16

function init_noise()
    local seed = flr(rnd(32767))
    if not _seeds_initialized then
        printh("", "fe4_seeds.txt", true)
        _seeds_initialized = true
    end
    printh(
        "Generated map with seed: " .. seed ..
        " at " .. stat(93) .. ":" .. stat(94) .. ":" .. stat(95),
        "fe4_seeds.txt"
    )
    return seed, os2d_noisefn(seed)
end

function _init()
    world = pecs()
    components = init_components(world)
    systems = init_systems(world, components)

    -- Initialize noise function first
    local seed, noise = init_noise()
    noise_fn = noise  -- Store globally

    -- Initialize terrain renderer with the noise function
    init_terrain_renderer(noise_fn)

    -- Create cursor
    local cursor = world.entity()
    cursor += components.Position({ x = flr(MAP_WIDTH/2), y = flr(MAP_HEIGHT/2) })
    cursor += components.Cursor({})

    -- Initialize castles with the same noise function
    init_castles(world, components, noise_fn)
end

function _update()
    world.update()
    systems.move_cursor()
end

function _draw()
    cls()
    
    -- Get cursor position
    local cursor_ent = world.query({components.Cursor})[1]
    if cursor_ent then
        local pos = cursor_ent[components.Position]
        -- Draw terrain based on cursor position
        draw_terrain(pos.x, pos.y)
        systems.draw_castles()
        systems.draw_coordinates()
        -- Draw cursor
        spr(0, pos.x * 8, pos.y * 8)
    end
end