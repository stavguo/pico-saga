function init_components(world)
    local components = {
        Position = world.component({
            in_castle = false
        }),
        Cursor = world.component({
            max_width = MAP_WIDTH,
            max_height = MAP_HEIGHT
        }),
        Terrain = world.component(),
        Castle = world.component(),
        Selected = world.component(),
        Deselected = world.component(),
        Unit = world.component({
            sprite = 0
        })
    }
    return components
end
