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
        local ui = ui[i]
        if ui.selected > 0 then
            return ui.items[ui.selected]
        end
    end
    return nil
end

function get_anchor(cursor, count)
    count, cursor = count or 1, indextovec(cursor)
    local cx, cy = cursor[1] - (peek2(0x5f28) \ 8), cursor[2] - (peek2(0x5f2a) \ 8)
    local left, top = cx < 8, cy < 8
    return (count == 1 and (left and "tr" or "tl")) or
        (count == 2 and (left and "br" or "bl")) or
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