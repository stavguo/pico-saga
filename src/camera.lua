function update_camera(cursor_pos_x, cursor_pos_y, max_width, max_height)
    -- Define deadzone boundaries (in tiles)
    local deadzone_left = 4    -- tiles from left edge
    local deadzone_right = 11  -- tiles from left edge
    local deadzone_top = 4     -- tiles from top edge
    local deadzone_bottom = 11 -- tiles from top edge
    
    -- Calculate cursor position in screen space relative to camera
    local cursor_screen_x = cursor_pos_x - flr(CAMERA_X/8)
    local cursor_screen_y = cursor_pos_y - flr(CAMERA_Y/8)
    
    -- Only move camera if cursor is outside deadzone
    if cursor_screen_x < deadzone_left then
        CAMERA_X = (cursor_pos_x - deadzone_left) * 8
    elseif cursor_screen_x > deadzone_right then
        CAMERA_X = (cursor_pos_x - deadzone_right) * 8
    end
    
    if cursor_screen_y < deadzone_top then
        CAMERA_Y = (cursor_pos_y - deadzone_top) * 8
    elseif cursor_screen_y > deadzone_bottom then
        CAMERA_Y = (cursor_pos_y - deadzone_bottom) * 8
    end
    
    -- Clamp camera to map boundaries
    CAMERA_X = mid(0, CAMERA_X, (max_width * 8) - 128)
    CAMERA_Y = mid(0, CAMERA_Y, (max_height * 8) - 128)
    
    camera(CAMERA_X, CAMERA_Y)
end

function update_cursor(world, components, _x, _y, _width, _height)
    local cursor = world.query({components.Cursor})[1]
    if cursor then
        cursor[components.Position].x = _x
        cursor[components.Position].y = _y
        cursor[components.Cursor].max_width = _width
        cursor[components.Cursor].max_height = _height
        update_camera( _x, _y, _width, _height)
    end
end
