function init_components(world)
    local components = {
        Position = world.component(),
        Cursor = world.component(),
        Terrain = world.component(),
        Castle = world.component(),
        Selected = world.component(),
        Deselected = world.component()
    }
    return components
end
