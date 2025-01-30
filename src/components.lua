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
            sprite = 0,
            team = "player" -- Add team field, default to "player"
        }),
        TraversableTile = world.component(),
        UI = world.component({
            text = "",           -- Text to display
            color = 7,          -- Default to white
            visible = true,     -- Visibility flag
            relative_to_camera = true  -- Whether position should be relative to camera
        })
    }
    return components
end
