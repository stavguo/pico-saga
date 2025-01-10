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
    cursor += components.Position({ x = flr(MAP_WIDTH/2), y = flr(MAP_HEIGHT/2) })
    cursor += components.Cursor({})

    init_castles(world, components)
end

function _update()
    world.update()
    
    if GAME_STATE == "world" then
        systems.move_cursor()
    end
    
    -- Always run these
    systems.check_selection()
    systems.clean_deselected()
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
    else
        print("inside castle", 48, 60, 7)
    end
end