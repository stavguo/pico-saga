function update_camera(cursor_idx, snap)
    cursor_pos = indextovec(cursor_idx)
    -- Define deadzone boundaries (in tiles)
    local dl, dr, dt, db, cam_x, cam_y = 4, 11, 4, 11, (peek2(0x5f28) \ 8) * 8, (peek2(0x5f2a) \ 8) * 8
    -- Calculate cursor position in screen space
    local csx, csy = cursor_pos[1] - (cam_x \ 8), cursor_pos[2] - (cam_y \ 8)
    -- Move camera if cursor is outside deadzone
    if (csx < dl) cam_x = (cursor_pos[1] - dl) * 8
    if (csx > dr) cam_x = (cursor_pos[1] - dr) * 8
    if (csy < dt) cam_y = (cursor_pos[2] - dt) * 8
    if (csy > db) cam_y = (cursor_pos[2] - db) * 8
    -- Clamp camera to map boundaries
    cam_x, cam_y = mid(0, cam_x, 128), mid(0, cam_y, 128)
    if snap then
        camera(cam_x, cam_y)
    else
        local current_x, current_y, xx, yy = peek2(0x5f28), peek2(0x5f2a), 0, 0
        if current_x < cam_x then
            xx+=1
        elseif current_x > cam_x then
            xx-=1
        end
        if current_y < cam_y then
            yy+=1
        elseif current_y > cam_y then
            yy-=1
        end
        camera(current_x + xx, current_y + yy)
    end
end

function update_cursor(cursor, mw, mh)
    local temp = indextovec(cursor)
    if btnp(0) then temp[1] = mid(0, temp[1] - 1, mw) end
    if btnp(1) then temp[1] = mid(0, temp[1] + 1, mw) end
    if btnp(2) then temp[2] = mid(0, temp[2] - 1, mh) end
    if btnp(3) then temp[2] = mid(0, temp[2] + 1, mh) end
    return vectoindex(temp)
end

function draw_cursor(cursor, flashing)
    local pos = indextovec(cursor)
    if not flashing or t() % 0.5 < 0.4 then
        spr(0, pos[1] * 8, pos[2] * 8)
    end
end