function get_unit_at(x, y)
    for _, unit in pairs(UNITS) do
        if unit.x == x and unit.y == y then
            return unit
        end
    end
    return nil
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

    -- Query all castles to get their positions
    local castle_positions = {}
    for _, castle in pairs(CASTLES) do
        castle_positions[castle.x..","..castle.y] = true
    end

    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(current.x, current.y, MAP_WIDTH, MAP_HEIGHT)

        for _, n in pairs(neighbors) do
            local key = n.x..","..n.y
            if not castle_positions[key] then
                local terrain = get_terrain_at(n.x, n.y)
                if terrain and terrain.cost then
                    local new_cost = costs[current.x..","..current.y] + terrain.cost
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
end

function init_player_units()
    -- Place leader
    local throne = rnd(1) < 0.5 and 7 or 8
    local weapon = flr(rnd(3))
    add(UNITS, {
        x = throne, y = 1, in_castle = true,
        sprite = 16 + weapon, team = "player",
        is_visible = true
    })

    -- Place 8 units in formation
    for i = 0, 7 do
        local row = flr(i / 4)
        local pos = i % 4
        local is_right = pos >= 2
        add(UNITS, {
            x = is_right and (11 + (pos - 2) * 2) or (2 + pos * 2),
            y = 2 + row * 2, in_castle = true,
            sprite = 13 + flr(rnd(3)), team = "player",
            is_visible = true
        })
    end
end

function init_enemy_units()
    local enemies_per_quad = 4
    local quadrants = {
        --{ x_start = 0, x_end = 15, y_start = 0, y_end = 15 },  -- Q1: explicitly 0,0 to 15,15
        { x_start = 16, x_end = 31, y_start = 0, y_end = 15 },  -- Q2: explicitly 16,0 to 31,15
        { x_start = 0, x_end = 15, y_start = 16, y_end = 31 },  -- Q3: explicitly 0,16 to 15,31
        { x_start = 16, x_end = 31, y_start = 16, y_end = 31 }  -- Q4: explicitly 16,16 to 31,31
    }

    -- Find largest square in each quadrant
    for i, quad in ipairs(quadrants) do
        local traversable_tiles = {}
        for y = quad.y_start, quad.y_end do
            for x = quad.x_start, quad.x_end do
                local terrain = get_terrain_at(x, y)
                if terrain.cost ~= nil then
                    add(traversable_tiles, {x = x, y = y})
                end
            end
        end
        shuffle_traversable_tiles(traversable_tiles)
        for i = 1, enemies_per_quad do
            add(UNITS, {
                x = traversable_tiles[i].x,
                y = traversable_tiles[i].y,
                in_castle = false,
                sprite = 13 + flr(rnd(3)),
                team = "enemy",
                is_visible = true
            })
        end
    end
end

function shuffle_traversable_tiles(tiles)
    for i = #tiles, 2, -1 do
        local j = flr(rnd(i)) + 1
        tiles[i], tiles[j] = tiles[j], tiles[i]
    end
end

function draw_units(filter_func)
    for _, unit in pairs(UNITS) do
        if filter_func(unit) then
            if unit.team == "enemy" then
                pal(12, 8, 0)
                pal(1, 2, 0)
            end
            spr(unit.sprite, unit.x * 8, unit.y * 8)
            if unit.team == "enemy" then
                pal()
            end
        end
    end
end

function draw_nonselected_overworld_units()
    draw_units(function(unit)
        return not unit.in_castle and unit ~= SELECTED_UNIT
    end)
end

function draw_nonselected_castle_units()
    draw_units(function(unit)
        return unit.in_castle and unit ~= SELECTED_UNIT
    end)
end

function draw_flashing_sprite(sprite, tile_x, tile_y)
    if t() % 0.5 < 0.4 then
        spr(sprite, tile_x * 8, tile_y * 8)
    end
end