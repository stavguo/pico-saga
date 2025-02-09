function update_camera(cursor_x, cursor_y, max_width, max_height)
    -- Define deadzone boundaries (in tiles)
    local deadzone_left = 4
    local deadzone_right = 11
    local deadzone_top = 4
    local deadzone_bottom = 11

    -- Calculate cursor position in screen space
    local cursor_screen_x = cursor_x - flr(CAMERA.x / 8)
    local cursor_screen_y = cursor_y - flr(CAMERA.y / 8)

    -- Move camera if cursor is outside deadzone
    if cursor_screen_x < deadzone_left then
        CAMERA.x = (cursor_x - deadzone_left) * 8
    elseif cursor_screen_x > deadzone_right then
        CAMERA.x = (cursor_x - deadzone_right) * 8
    end

    if cursor_screen_y < deadzone_top then
        CAMERA.y = (cursor_y - deadzone_top) * 8
    elseif cursor_screen_y > deadzone_bottom then
        CAMERA.y = (cursor_y - deadzone_bottom) * 8
    end

    -- Clamp camera to map boundaries
    CAMERA.x = mid(0, CAMERA.x, (max_width * 8) - 128)
    CAMERA.y = mid(0, CAMERA.y, (max_height * 8) - 128)

    -- Update camera position
    camera(CAMERA.x, CAMERA.y)
end

function draw_cursor(flashing)
    if not flashing or t() % 0.5 < 0.4 then
        spr(CURSOR.sprite, CURSOR.x * 8, CURSOR.y * 8)
    end
end

function draw_cursor_coords()
    local offset = 8
    local x = offset + CAMERA.x
    local y = offset + CAMERA.y
    local text = "x:" .. CURSOR.x .. " y:" .. CURSOR.y
    rectfill(x - 1, y - 1, x + #text * 4, y + 4, 0)
    color(7)
    print(text, x, y)
end

function enter_castle()
    -- Store the cursor's screen position before moving the camera
    local cursor_screen_x = CURSOR.x - flr(CAMERA.x / 8)
    local cursor_screen_y = CURSOR.y - flr(CAMERA.y / 8)

    -- Move the camera to (0, 0)
    CAMERA.x = 0
    CAMERA.y = 0
    camera(CAMERA.x, CAMERA.y)

    -- Adjust the cursor's world position to maintain its screen position
    CURSOR.x = cursor_screen_x + flr(CAMERA.x / 8)
    CURSOR.y = cursor_screen_y + flr(CAMERA.y / 8)
end

function exit_castle()
    CURSOR.x = SELECTED_CASTLE.x
    CURSOR.y = SELECTED_CASTLE.y
    update_camera(SELECTED_CASTLE.x, SELECTED_CASTLE.y, MAP_WIDTH, MAP_HEIGHT)
end