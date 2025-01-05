-- camera.lua
camera_x = 0
camera_y = 0

function update_camera(cursor_pos)
    -- Try to center camera on cursor
    camera_x = (cursor_pos.x * 8) - 64 -- 64 = half screen width
    camera_y = (cursor_pos.y * 8) - 64 -- 64 = half screen height

    -- Clamp to map boundaries
    camera_x = mid(0, camera_x, (MAP_WIDTH * 8) - 128)
    camera_y = mid(0, camera_y, (MAP_HEIGHT * 8) - 128)

    -- Actually set PICO-8's camera
    camera(camera_x, camera_y)
end
