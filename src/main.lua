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
end

function _update()
    world.update()
    if GAME_STATE == "world" then
        systems.move_cursor()
    end
    systems.check_selection()
    systems.handle_castle_selection()
    systems.handle_castle_deselection()
end

function _draw()
    cls()
    if GAME_STATE == "world" then
        local cursor_ent = world.query({components.Cursor})[1]
        if cursor_ent then
            local pos = cursor_ent[components.Position]
            draw_terrain(pos.x, pos.y)
            systems.draw_castles()
            systems.draw_coordinates()
            spr(0, pos.x * 8, pos.y * 8)
        end
    elseif GAME_STATE == "castle" then
        draw_castle_interior()
    end
end