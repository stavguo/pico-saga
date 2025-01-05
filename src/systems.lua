function init_systems(world, components)
    local systems = {}

    systems.move_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            if btnp(0) then pos.x = max(0, pos.x - 1) end
            if btnp(1) then pos.x = min(MAP_WIDTH - 1, pos.x + 1) end
            if btnp(2) then pos.y = max(0, pos.y - 1) end
            if btnp(3) then pos.y = min(MAP_HEIGHT - 1, pos.y + 1) end
            update_camera(pos)
        end
    )

    systems.draw_terrain = world.system(
        { components.Position, components.Terrain },
        function(entity)
            local pos = entity[components.Position]
            local terrain = entity[components.Terrain]

            -- Get current camera tile position (top-left of viewport)
            local cam_tile_x = flr(camera_x / 8)
            local cam_tile_y = flr(camera_y / 8)

            -- Only draw if within viewport (plus one tile padding)
            if pos.x >= cam_tile_x - 1 and
                pos.x <= cam_tile_x + SCREEN_TILES_WIDTH + 1 and
                pos.y >= cam_tile_y - 1 and
                pos.y <= cam_tile_y + SCREEN_TILES_HEIGHT + 1 then
                -- Since we called camera(), we can just multiply by 8
                spr(terrain.sprite, pos.x * 8, pos.y * 8)
            end
        end
    )

    systems.draw_cursor = world.system(
        { components.Position, components.Cursor },
        function(entity)
            local pos = entity[components.Position]
            spr(0, pos.x * 8, pos.y * 8)
        end
    )

    return systems
end
