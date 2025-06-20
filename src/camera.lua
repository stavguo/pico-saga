function update_cursor(cursor)
    local temp = indextovec(cursor)
    if btnp(0) then temp[1] = mid(0, temp[1] - 1, 15) end
    if btnp(1) then temp[1] = mid(0, temp[1] + 1, 15) end
    if btnp(2) then temp[2] = mid(0, temp[2] - 1, 15) end
    if btnp(3) then temp[2] = mid(0, temp[2] + 1, 15) end
    return vectoindex(temp)
end

function draw_cursor(cursor, flashing)
    local pos = indextovec(cursor)
    if not flashing or t() % 0.5 < 0.4 then
        spr(0, pos[1] * 8, pos[2] * 8)
    end
end