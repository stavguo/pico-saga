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
    local cursor = world.entity()

    init_castles(world, components, cursor)

    init_units(world, components)
end

function _update()
    world.update()
    systems.move_cursor()
    systems.check_selection()
    systems.handle_castle_selection()
    systems.handle_castle_deselection()
end

function _draw()
    cls()
    local cursor_ent = world.query({components.Cursor})[1]
    local pos = nil
    if cursor_ent then
        pos = cursor_ent[components.Position]
    end
    if GAME_STATE == "world" then
        draw_terrain(pos.x, pos.y)
        systems.draw_castles()
        systems.draw_coordinates()
    elseif GAME_STATE == "castle" then
        draw_castle_interior()
        systems.draw_castle_units()
    end
    -- render cursor last
    if (pos) spr(0, pos.x * 8, pos.y * 8)
end