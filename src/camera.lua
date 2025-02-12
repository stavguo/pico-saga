local function update_axis(pos, screen_pos, deadzone_min, deadzone_max)
    if screen_pos < deadzone_min then
        return (pos - deadzone_min) * 8
    elseif screen_pos > deadzone_max then
        return (pos - deadzone_max) * 8
    end
    return nil
end

function update_camera(cx, cy, mw, mh)
    local deadzone = {left=4, right=11, top=4, bottom=11}
    local csx = cx - flr(CAMERA.x / 8)
    local csy = cy - flr(CAMERA.y / 8)

    CAMERA.x = update_axis(cx, csx, deadzone.left, deadzone.right) or CAMERA.x
    CAMERA.y = update_axis(cy, csy, deadzone.bottom, deadzone.top) or CAMERA.y

    -- Clamp camera to map boundaries
    CAMERA.x = mid(0, CAMERA.x, (mw * 8) - 128)
    CAMERA.y = mid(0, CAMERA.y, (mh * 8) - 128)

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