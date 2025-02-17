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
    -- Initialize terrain and castles
    local seed, noise_fn = init_noise()
    init_terrain(noise_fn)
    init_castles()
    init_player_units()
    init_enemy_units()

    -- Initialize FSM
    fsm:change_state("overworld")
end

function _update()
    fsm:update()
end

function _draw()
    cls()
    map()
    fsm:draw()
end