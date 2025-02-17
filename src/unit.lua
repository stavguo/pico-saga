function create_unit(x, y, class, team, in_castle)
    return {
        x = x,
        y = y,
        in_castle = in_castle,
        sprite = UNIT_STATS[class].Sprite,
        team = team,
        class = class,
        HP = UNIT_STATS[class].HP,
        Str = UNIT_STATS[class].Str,
        Mag = UNIT_STATS[class].Mag,
        Skl = UNIT_STATS[class].Skl,
        Spd = UNIT_STATS[class].Spd,
        Def = UNIT_STATS[class].Def,
        Mdf = UNIT_STATS[class].Mdf,
        Mov = UNIT_STATS[class].Mov
    }
end

function get_unit_at(x, y, in_castle)
    if in_castle then
        return PLAYER_CASTLE_UNITS[x..","..y]
    end
    return PLAYER_UNITS[x..","..y] or ENEMY_UNITS[x..","..y]
end

function move_unit(unit, to_x, to_y)
    local from_key = unit.x..","..unit.y
    local to_key = to_x..","..to_y
    if unit.team == "player" then
        PLAYER_UNITS[to_key], PLAYER_UNITS[from_key] = unit
    elseif unit.team == "enemy" then
        ENEMY_UNITS[to_key], ENEMY_UNITS[from_key] = unit
    end
    unit.x, unit.y = to_x, to_y
end

function deploy_unit(unit, to_x, to_y)
    PLAYER_UNITS[to_x..","..to_y], PLAYER_CASTLE_UNITS[unit.x..","..unit.y] = unit
    unit.x, unit.y, unit.in_castle = to_x, to_y, false
end

function get_neighbors(x, y, max_width, max_height)
    local neighbors = {}
    local directions = {
        {x = -1, y = 0}, {x = 1, y = 0},
        {x = 0, y = -1}, {x = 0, y = 1}
    }

    for _, dir in pairs(directions) do
        local nx = x + dir.x
        local ny = y + dir.y
        if nx >= 0 and nx < max_width and ny >= 0 and ny < max_height then
            add(neighbors, {x = nx, y = ny})
        end
    end

    return neighbors
end

function find_traversable_tiles(start_x, start_y, movement, unit_team)
    TRAVERSABLE_TILES = {} -- Clear previous tiles
    TRAVERSABLE_TILES[start_x..","..start_y] = true

    local frontier = {{x = start_x, y = start_y}}
    local costs = {}
    costs[start_x..","..start_y] = 0

    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(current.x, current.y, 32, 32)
        for _, n in pairs(neighbors) do
            local key = n.x..","..n.y
            local cost = TERRAIN_COSTS[mget(n.x, n.y)]
            if cost then
                local new_cost = costs[current.x..","..current.y] + cost
                if new_cost <= movement and (not costs[key] or new_cost < costs[key]) then
                    -- Check if the tile is occupied by an opposing unit
                    local unit_at_tile = get_unit_at(n.x, n.y)
                    if not unit_at_tile or unit_at_tile.team == unit_team then
                        costs[key] = new_cost
                        add(frontier, n)
                        TRAVERSABLE_TILES[key] = true
                    end
                end
            end
        end
    end
end

function init_player_units()
    local player_classes = {
        "Sword Soldier", "Sword Soldier", "Sword Soldier",
        "Spear Soldier", "Spear Soldier", "Spear Soldier",
        "Axe Soldier", "Axe Soldier", "Axe Soldier"
    }
    local leader_idx = flr(rnd(9)) + 1
    -- Place leader
    local throne = rnd(1) < 0.5 and 7 or 8
    
    PLAYER_CASTLE_UNITS[throne..","..1] = create_unit(throne, 1, player_classes[leader_idx], "player", true)

    -- Place 8 units in formation
    count = 0
    for i = 1, 9 do
        if i ~= leader_idx then
            local row = (count \ 4)
            local pos = count % 4
            local is_right = pos >= 2
            local x = is_right and (11 + (pos - 2) * 2) or (2 + pos * 2)
            local y = 2 + row * 2
            PLAYER_CASTLE_UNITS[x..","..y] = create_unit(x, y, player_classes[i], "player", true)
            count = count + 1
        end
    end
end

function init_enemy_units()
    local enemy_classes = {
        "Sword Soldier", "Sword Soldier", "Sword Soldier", "Sword Soldier",
        "Spear Soldier", "Spear Soldier", "Spear Soldier", "Spear Soldier",
        "Axe Soldier", "Axe Soldier", "Axe Soldier", "Axe Soldier"
    }
    SHUFFLE(enemy_classes)
    local enemies_per_quad = 4
    local quadrants = {
        --{ x_start = 0, x_end = 15, y_start = 0, y_end = 15 },  -- Q1: explicitly 0,0 to 15,15
        { x_start = 16, x_end = 31, y_start = 0, y_end = 15 },  -- Q2: explicitly 16,0 to 31,15
        { x_start = 0, x_end = 15, y_start = 16, y_end = 31 },  -- Q3: explicitly 0,16 to 15,31
        { x_start = 16, x_end = 31, y_start = 16, y_end = 31 }  -- Q4: explicitly 16,16 to 31,31
    }

    -- Find largest square in each quadrant
    for quad in all(quadrants) do
        local traversable_tiles = {}
        for y = quad.y_start, quad.y_end do
            for x = quad.x_start, quad.x_end do
                local terrain = mget(x, y)
                if terrain ~= 6 and terrain ~= 7 then
                    add(traversable_tiles, {x = x, y = y})
                end
            end
        end
        SHUFFLE(traversable_tiles)
        for i = 1, enemies_per_quad do
            local x = traversable_tiles[i].x
            local y = traversable_tiles[i].y
            ENEMY_UNITS[x..","..y] = create_unit(x, y, enemy_classes[i], "enemy", false)
        end
    end
end

function draw_nonselected_overworld_units()
    for _, unit in pairs(PLAYER_UNITS) do
        if not unit.in_castle and unit ~= SELECTED_UNIT then
            spr(unit.sprite, unit.x * 8, unit.y * 8)
        end
    end
    pal(12, 8, 0)
    pal(1, 2, 0)
    for _, unit in pairs(ENEMY_UNITS) do
        if not unit.in_castle and unit ~= SELECTED_UNIT then
            spr(unit.sprite, unit.x * 8, unit.y * 8)
        end
    end
    pal()
end

function draw_nonselected_castle_units()
    for _, unit in pairs(PLAYER_CASTLE_UNITS) do
        if unit ~= SELECTED_UNIT then
            spr(unit.sprite, unit.x * 8, unit.y * 8)
        end
    end
end

function draw_selected_unit_flashing(unit, tile_x, tile_y)
    if t() % 0.5 < 0.4 then
        if unit.team == "enemy" then
            pal(12, 8, 0)
            pal(1, 2, 0)
        end
        spr(unit.sprite, (tile_x or unit.x) * 8, (tile_y or unit.y) * 8)
        if unit.team == "enemy" then
            pal()
        end
    end
end

function draw_flashing_sprite(sprite, tile_x, tile_y)
    if t() % 0.5 < 0.4 then
        spr(sprite, tile_x * 8, tile_y * 8)
    end
end