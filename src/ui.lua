function create_menu(world, components, texts, cursor_x, cursor_y)
    -- First hide all existing UI elements
    local ui_elements = world.query({components.UI})
    for _, element in pairs(ui_elements) do
        element[components.UI].visible = false
    end

    MENU_SIZE = #texts
    MENU_SELECTED = 0
    MENU_ITEMS = {}
    
    -- Calculate if cursor is in left or right half of screen
    local cursor_screen_x = cursor_x - flr(CAMERA_X/8)
    local is_cursor_left = cursor_screen_x < 8  -- Check if cursor in left half
    
    -- Calculate menu x position (opposite side of cursor)
    -- If cursor is on left, put menu on right (but ensure enough room for text)
    -- If cursor is on right, put menu on left
    local menu_x = is_cursor_left and 
        (13 * 8) or  -- Left side cursor: menu on right
        8            -- Right side cursor: menu on left
    local menu_y = 8  -- One tile down from top
    
    for i = 1, MENU_SIZE do
        local item = world.entity()
        item += components.Position({ x = menu_x, y = menu_y + (i-1) * 8 })
        item += components.UI({
            text = texts[i],
            color = i == 1 and 9 or 7,
            relative_to_camera = true  -- Menu stays fixed to screen
        })
        MENU_ITEMS[i-1] = item
    end
    
    MENU_OPEN = true
end

function close_menu(world, components)
    -- Restore visibility to all UI elements
    local ui_elements = world.query({components.UI})
    for _, element in pairs(ui_elements) do
        element[components.UI].visible = true
    end

    for i = 0, MENU_SIZE-1 do
        world.remove(MENU_ITEMS[i])
    end
    MENU_ITEMS = {}
    MENU_SELECTED = 0
    MENU_SIZE = 0
    MENU_OPEN = false
end