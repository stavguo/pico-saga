function update_camera(cursor)
    -- Define deadzone boundaries (in tiles)
    local dl, dr, dt, db, cam_x, cam_y = 4, 11, 4, 11, peek2(0x5f28), peek2(0x5f2a)
    -- Calculate cursor position in screen space
    local csx, csy = cursor[1] - (cam_x \ 8), cursor[2] - (cam_y \ 8)
    -- Move camera if cursor is outside deadzone
    if (csx < dl) cam_x = (cursor[1] - dl) * 8
    if (csx > dr) cam_x = (cursor[1] - dr) * 8
    if (csy < dt) cam_y = (cursor[2] - dt) * 8
    if (csy > db) cam_y = (cursor[2] - db) * 8
    -- Clamp camera to map boundaries
    cam_x, cam_y = mid(0, cam_x, 128), mid(0, cam_y, 128)
    -- Update camera position
    camera(cam_x, cam_y)
end

function update_cursor(cursor, mw, mh)
    if btnp(0) then cursor[1] = mid(0, cursor[1] - 1, mw) end
    if btnp(1) then cursor[1] = mid(0, cursor[1] + 1, mw) end
    if btnp(2) then cursor[2] = mid(0, cursor[2] - 1, mh) end
    if btnp(3) then cursor[2] = mid(0, cursor[2] + 1, mh) end
end

function draw_cursor(cursor, flashing)
    if not flashing or t() % 0.5 < 0.4 then
        spr(0, cursor[1] * 8, cursor[2] * 8)
    end
end

function draw_cursor_coords(cursor)
    local offset = 8
    local x, y, text = offset + peek2(0x5f28), offset + peek2(0x5f2a), "x:" .. cursor[1] .. " y:" .. cursor[2]
    rectfill(x - 1, y - 1, x + #text * 4, y + 4, 0)
    color(7)
    print(text, x, y)
end

function enter_castle(cursor)
    -- Store the cursor's screen position before moving the camera
    local csx, csy = cursor[1] - (peek2(0x5f28) \ 8), cursor[2] - (peek2(0x5f2a) \ 8)

    -- Move the camera to (0, 0)
    camera(0,0)

    -- Adjust the cursor's world position to maintain its screen position
    cursor[1], cursor[2] = csx, csy
end

function exit_castle(cursor, castle)
    cursor[1], cursor[2] = castle[1], castle[2]
    update_camera(cursor)
end