function create_unit_info(unit, ui)
    create_ui({
        unit.team.." "..unit.class,
        "HP:" .. unit.HP .. " Mov:" .. unit.Mov,
        (unit.team == "enemy" and "AI:" .. unit.enemy_ai or nil)
    }, ui)
end

function create_ui(options, ui, is_interactive, anchor)
    add(ui, {
        items = options,
        selected = is_interactive and 1 or 0,
        anchor = anchor
    })
end

function update_ui(ui)
    for i = #ui, 1, -1 do
        local u = ui[i]
        if u.selected > 0 then  -- Only update interactive UI
            -- Navigate menu with up/down buttons
            if btnp(2) then  -- Up button
                u.selected = mid(1, u.selected - 1, #u.items)
            elseif btnp(3) then  -- Down button
                u.selected = mid(1, u.selected + 1, #u.items)
            end
            break  -- Only update the topmost interactive UI
        end
    end
end

function get_ui_selection(ui)
    for i = #ui, 1, -1 do
        local el = ui[i]
        if el.selected > 0 then
            return el.items[el.selected]
        end
    end
    return nil
end

function get_anchor(cursor, items)
    items, cursor = items or 1, indextovec(cursor)
    local cx, cy = cursor[1] - (peek2(0x5f28) \ 8), cursor[2] - (peek2(0x5f2a) \ 8)
    local left, top = cx < 8, cy < 8
    return (items == 1 and (left and "tr" or "tl")) or
        (items == 2 and (left and "br" or "bl")) or
        (left and (top and "bl" or "tl") or (top and "br" or "tr"))
end

function draw_ui(cursor, ui_stack)
    for i, ui in ipairs(ui_stack) do
        local anchor = ui.anchor or get_anchor(cursor, i)
        for j, item in ipairs(ui.items) do
            local x = (anchor == "tl" or anchor == "bl") and (peek2(0x5f28) + 2) or (peek2(0x5f28) + 127 - #item * 4)
            local y = (anchor == "tl" or anchor == "tr") and (peek2(0x5f2a) + 2 + (j-1)*6) or (peek2(0x5f2a) + 121 - (#ui.items - j)*6)
            rectfill(x-1, y-1, x - 1 + #item*4, y+5, 0)
            color(ui.selected > 0 and j == ui.selected and 9 or 7)
            print(item, x, y)
        end
    end
end

function draw_centered_text(text, color_idx, height)
    local x, y = peek2(0x5f28) + (64-#text*2), peek2(0x5f2a) + (height or 61)
    rectfill(x-1, y-1, x - 1 + #text*4, y+5, 0)
    color(color_idx)
    print(text, x, y)
end

function draw_mini_map(units)
    local cx,cy=peek2(0x5f28),peek2(0x5f2a)
    local mx,my,mw=32,39,64
    local mt_col={[2]=12,[1]=11,[6]=1,[3]=3,[4]=3,[5]=15,[7]=7,[8]=10,[9]=9}
    
    for y=0,31 do
        for x=0,31 do
            local mt=mget(x,y)
            local col=mt_col[mt]
            local unit=units[vectoindex{x,y}]
            if unit then col=unit.team=="enemy"and 8 or 12 end
            if col then
                local px,py=cx+mx+2*x,cy+my+2*y
                rectfill(px,py,px+2,py+2,col)
            end
        end
    end
    
    local r1=cx+mx-1
    local r2=cy+my-1
    local r3=cx+mx+mw
    local r4=cy+my+mw
    rect(r1,r2,r3,r4,0)
    
    local vx,vy=cx/4,cy/4
    rect(cx+mx+vx-1,cy+my+vy-1,cx+mx+vx+32,cy+my+vy+32,0)
end