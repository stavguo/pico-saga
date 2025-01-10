function init_components(world)
    local components = {
        Position = world.component(),
        Cursor = world.component(),
        Terrain = world.component(),
        Castle = world.component()
    }
    return components
end
