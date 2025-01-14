function update_camera(cursor_pos_x, cursor_pos_y, max_width, max_height)
    CAMERA_X = (cursor_pos_x * 8) - 64 -- 64 = half screen width
    CAMERA_Y = (cursor_pos_y * 8) - 64 -- 64 = half screen height
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
