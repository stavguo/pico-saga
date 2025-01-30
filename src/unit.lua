function get_unit_at_tile(world, components, x, y)
    local units = world.query({components.Unit, components.Position})
    for id, unit in pairs(units) do
        local unit_pos = unit[components.Position]
        if unit_pos.x == x and unit_pos.y == y then
            return unit -- Return the unit at this tile
        end
    end
    return nil -- No unit at this tile
end

function get_neighbors(tile_x, tile_y, max_width, max_height)
    local neighbors = {}
    local directions = {
        {x=-1, y=0}, {x=1, y=0}, {x=0, y=-1}, {x=0, y=1}
    }
    
    for dir in all(directions) do
        local nx = tile_x + dir.x
        local ny = tile_y + dir.y
        if nx >= 0 and nx < max_width and ny >= 0 and ny < max_height then
            add(neighbors, {x=nx, y=ny})
        end
    end
    
    return neighbors
end

function find_traversable_tiles(world, components, start_x, start_y, movement, unit_team)
    TRAVERSABLE_TILES = {} -- Clear previous tiles
    TRAVERSABLE_TILES[start_x..","..start_y] = true
    
    local start_tile = world.entity()
    start_tile += components.Position({x=start_x, y=start_y})
    start_tile += components.TraversableTile()
    
    local frontier = {{x=start_x, y=start_y}}
    local costs = {}
    costs[start_x..","..start_y] = 0
    
    local castles = world.query({components.Castle, components.Position})
    local castle_positions = {}
    for id, castle in pairs(castles) do
        local pos = castle[components.Position]
        castle_positions[pos.x..","..pos.y] = true
    end
    
    while #frontier > 0 do
        local current = deli(frontier, 1)
        local neighbors = get_neighbors(current.x, current.y, MAP_WIDTH, MAP_HEIGHT)
        
        for n in all(neighbors) do
            local key = n.x..","..n.y
            if not castle_positions[key] then
                local terrain = get_terrain_at(n.x, n.y)
                if terrain and terrain.cost then
                    local new_cost = costs[current.x..","..current.y] + terrain.cost
                    if new_cost <= movement and (not costs[key] or new_cost < costs[key]) then
                        -- Check if the tile is occupied by an opposing unit
                        local unit_at_tile = get_unit_at_tile(world, components, n.x, n.y)
                        if not unit_at_tile or unit_at_tile[components.Unit].team == unit_team then
                            costs[key] = new_cost
                            add(frontier, n)
                            TRAVERSABLE_TILES[key] = true
                            local tile = world.entity()
                            tile += components.Position({x=n.x, y=n.y})
                            tile += components.TraversableTile()
                        end
                    end
                end
            end
        end
    end
end

function init_units(world, components)
    -- Place leader centered at top, coin flip between king/queen seat
    local leader = world.entity()
    local throne = rnd(1) < 0.5 and 7 or 8
    leader += components.Position({x=throne, y=1, in_castle=true})
    local weapon = flr(rnd(3))
    leader += components.Unit({
        sprite=16+weapon,
        team="player" -- Set team to "player"
    })
    
    -- Place 8 units in formation
    for i=0,7 do
        local row = flr(i/4)
        local pos = i%4
        local is_right = pos >= 2
        local unit = world.entity()
        unit += components.Position({
            x = is_right and (11+(pos-2)*2) or (2+pos*2),
            y = 2 + row*2,
            in_castle = true
        })
        unit += components.Unit({
            sprite=13+flr(rnd(3)),
            team="player" -- Set team to "player"
        })
    end
end