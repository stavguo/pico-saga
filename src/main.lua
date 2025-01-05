local world
local components
local systems
local noise_fn

-- Map dimensions (FE4-like scale)
MAP_WIDTH = 96
MAP_HEIGHT = 64

-- Screen dimensions in tiles
SCREEN_TILES_WIDTH = 16
SCREEN_TILES_HEIGHT = 16

function _init()
    world = pecs()
    components = init_components(world)
    systems = init_systems(world, components)

    -- Initialize terrain renderer instead of generating entities
    init_terrain_renderer()

    -- Create cursor
    local cursor = world.entity()
    cursor += components.Position({ x = flr(MAP_WIDTH/2), y = flr(MAP_HEIGHT/2) })
    cursor += components.Cursor({})
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
        -- Draw cursor
        spr(0, pos.x * 8, pos.y * 8)
    end
end