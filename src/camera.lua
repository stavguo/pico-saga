function update_camera(cursor_pos)
    -- Try to center camera on cursor
    CAMERA_X = (cursor_pos.x * 8) - 64 -- 64 = half screen width
    CAMERA_Y = (cursor_pos.y * 8) - 64 -- 64 = half screen height

    -- Clamp to map boundaries
    CAMERA_X = mid(0, CAMERA_X, (MAP_WIDTH * 8) - 128)
    CAMERA_Y = mid(0, CAMERA_Y, (MAP_HEIGHT * 8) - 128)

    -- Actually set PICO-8's camera
    camera(CAMERA_X, CAMERA_Y)
end
