function create_ui(options, is_interactive)
    add(UI_STACK, {
        items = options,
        selected = is_interactive and 1 or 0,
        anchor = nil
    })
end

function close_ui(index)
    if index then
        deli(UI_STACK, index)
    else
        UI_STACK = {}  -- Clear the entire stack if no index is provided
    end
end

function update_ui()
    for i = #UI_STACK, 1, -1 do
        local ui = UI_STACK[i]
        if ui.selected > 0 then  -- Only update interactive UI
            -- Navigate menu with up/down buttons
            if btnp(2) then  -- Up button
                ui.selected = mid(1, ui.selected - 1, #ui.items)
            elseif btnp(3) then  -- Down button
                ui.selected = mid(1, ui.selected + 1, #ui.items)
            end
            break  -- Only update the topmost interactive UI
        end
    end
end

function get_ui_selection()
    for i = #UI_STACK, 1, -1 do
        local ui = UI_STACK[i]
        if ui.selected > 0 then
            return ui.items[ui.selected]
        end
    end
    return nil
end

function draw_ui()
    local cx = CURSOR.x - (CAMERA.x \ 8)
    local cy = CURSOR.y - (CAMERA.y \ 8)
    local left = cx < 8
    local top = cy < 8

    for i, ui in ipairs(UI_STACK) do
        local anchor = i == 1 and (left and "tr" or "tl") or
                       i == 2 and (left and "br" or "bl") or
                       (left and (top and "bl" or "tl") or (top and "br" or "tr"))

        for j, item in ipairs(ui.items) do
            local x = (anchor == "tl" or anchor == "bl") and (CAMERA.x + 8) or (CAMERA.x + 120 - #item * 4)
            local y = (anchor == "tl" or anchor == "tr") and (CAMERA.y + 8 + (j-1)*8) or (CAMERA.y + 120 - (#ui.items - j)*8)
            rectfill(x-1, y-1, x + #item*4, y+4, 0)
            color(ui.selected > 0 and j == ui.selected and 9 or 7)
            print(item, x, y)
        end
    end
end