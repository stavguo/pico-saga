local world
local components
local systems

-- Map dimensions (FE4-like scale)
MAP_WIDTH = 48
MAP_HEIGHT = 32

-- Screen dimensions in tiles
SCREEN_TILES_WIDTH = 16
SCREEN_TILES_HEIGHT = 16

function _init()
    world = pecs()
    components = init_components(world)
    systems = init_systems(world, components)

    generate_terrain(world, components)

    -- Create cursor
    local cursor = world.entity()
    cursor += components.Position({ x = 0, y = 0 })
    cursor += components.Cursor({})
end

function _update()
    world.update()
    systems.move_cursor()
end

function _draw()
    cls()
    -- Draw all systems
    systems.draw_terrain()
    systems.draw_cursor()
    -- Reset camera for any UI we might add later
    -- camera(0, 0)
end
