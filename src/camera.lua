function update_camera(cx, cy)
    -- Define deadzone boundaries (in tiles)
    local dl, dr, dt, db = 4, 11, 4, 11
    -- Calculate cursor position in screen space
    local csx, csy = cx - (CAMERA.x \ 8), cy - (CAMERA.y \ 8)
    -- Move camera if cursor is outside deadzone
    if (csx < dl) CAMERA.x = (cx - dl) * 8
    if (csx > dr) CAMERA.x = (cx - dr) * 8
    if (csy < dt) CAMERA.y = (cy - dt) * 8
    if (csy > db) CAMERA.y = (cy - db) * 8
    -- Clamp camera to map boundaries
    CAMERA.x, CAMERA.y = mid(0, CAMERA.x, 128), mid(0, CAMERA.y, 128)
    -- Update camera position
    camera(CAMERA.x, CAMERA.y)
end

function update_cursor(mw, mh)
    if btnp(0) then CURSOR.x = mid(0, CURSOR.x - 1, mw) end
    if btnp(1) then CURSOR.x = mid(0, CURSOR.x + 1, mw) end
    if btnp(2) then CURSOR.y = mid(0, CURSOR.y - 1, mh) end
    if btnp(3) then CURSOR.y = mid(0, CURSOR.y + 1, mh) end
end

function draw_cursor(flashing)
    if not flashing or t() % 0.5 < 0.4 then
        spr(CURSOR.sprite, CURSOR.x * 8, CURSOR.y * 8)
    end
end

function draw_cursor_coords()
    local offset = 8
    local x, y, text = offset + CAMERA.x, offset + CAMERA.y, "x:" .. CURSOR.x .. " y:" .. CURSOR.y
    rectfill(x - 1, y - 1, x + #text * 4, y + 4, 0)
    color(7)
    print(text, x, y)
end

function enter_castle()
    -- Store the cursor's screen position before moving the camera
    local csx, csy = CURSOR.x - (CAMERA.x \ 8), CURSOR.y - (CAMERA.y \ 8)

    -- Move the camera to (0, 0)
    CAMERA.x, CAMERA.y = 0, 0
    camera(CAMERA.x, CAMERA.y)

    -- Adjust the cursor's world position to maintain its screen position
    CURSOR.x, CURSOR.y = csx, csy
end

function exit_castle(castle_x, castle_y)
    CURSOR.x, CURSOR.y = castle_x, castle_y
    update_camera(castle_x, castle_y)
end