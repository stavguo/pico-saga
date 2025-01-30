local world
local components
local systems

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
    local seed, noise_fn = init_noise()
    init_terrain_renderer(noise_fn)

    -- Create cursor
    CURSOR = world.entity()

    init_castles(world, components)
    init_units(world, components)
end

function _update()
    world.update()
    systems.move_cursor()
    systems.handle_cursor_coords()
    systems.castle_selection()
    systems.unit_selection()
    systems.menu_navigation()
end

function _draw()
    cls()
    if GAME_STATE == "world" then
        draw_terrain()
        systems.draw_castles()
    elseif GAME_STATE == "castle" then
        draw_castle_interior()
    end
    systems.draw_units()
    systems.draw_cursor()
    systems.draw_ui()
end