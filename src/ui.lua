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
    local cx = CURSOR.x - flr(CAMERA.x / 8)
    local cy = CURSOR.y - flr(CAMERA.y / 8)
    local left = cx < SCREEN_TILES_WIDTH / 2
    local top = cy < SCREEN_TILES_HEIGHT / 2

    for i, ui in ipairs(UI_STACK) do
        -- First menu: opposite side of cursor, always top
        if i == 1 then
            ui.anchor = left and "top-right" or "top-left"
        -- Second menu: opposite side of cursor, always bottom
        elseif i == 2 then
            ui.anchor = left and "bottom-right" or "bottom-left"
        -- Third menu: same side as cursor, opposite vertical position
        elseif i == 3 then
            ui.anchor = left and 
                (top and "bottom-left" or "top-left") or
                (top and "bottom-right" or "top-right")
        end

        -- Draw UI items
        for j, item in ipairs(ui.items) do
            local text_w = #item * 4
            local is_left = ui.anchor == "top-left" or ui.anchor == "bottom-left"
            local is_top = ui.anchor == "top-left" or ui.anchor == "top-right"
            
            local x = is_left and (CAMERA.x + 8) 
                or (CAMERA.x + SCREEN_TILES_WIDTH * 8 - text_w - 8)
            local y = is_top and (CAMERA.y + 8 + (j-1) * 8)
                or (CAMERA.y + SCREEN_TILES_HEIGHT * 8 - 8 - (#ui.items - j) * 8)

            rectfill(x - 1, y - 1, x + text_w, y + 4, 0)
            color(ui.selected > 0 and j == ui.selected and 9 or 7)
            print(item, x, y)
        end
    end
end