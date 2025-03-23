function create_ui(options, ui, is_interactive)
    add(ui, {
        items = options,
        selected = is_interactive and 1 or 0,
        anchor = nil
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

function draw_ui(cursor, ui_stack)
    local cx = cursor[1] - (peek2(0x5f28) \ 8)
    local cy = cursor[2] - (peek2(0x5f2a) \ 8)
    local left = cx < 8
    local top = cy < 8

    for i, ui in ipairs(ui_stack) do
        local anchor = i == 1 and (left and "tr" or "tl") or
                       i == 2 and (left and "br" or "bl") or
                       (left and (top and "bl" or "tl") or (top and "br" or "tr"))

        for j, item in ipairs(ui.items) do
            local x = (anchor == "tl" or anchor == "bl") and (peek2(0x5f28) + 8) or (peek2(0x5f28) + 120 - #item * 4)
            local y = (anchor == "tl" or anchor == "tr") and (peek2(0x5f2a) + 8 + (j-1)*8) or (peek2(0x5f2a) + 120 - (#ui.items - j)*8)
            rectfill(x-1, y-1, x + #item*4, y+4, 0)
            color(ui.selected > 0 and j == ui.selected and 9 or 7)
            print(item, x, y)
        end
    end
end

function draw_phase_text(current_phase)
    local phase_text = current_phase == "enemy" and "Enemy Phase" or "Player Phase"
    local x, y = peek2(0x5f28) + hcenter(phase_text), peek2(0x5f2a) + 61
    rectfill(x-1, y-1, x + #phase_text*4, y+4, 0)
    color(current_phase == "enemy" and 8 or 12)
    print(phase_text, x, y)
end
