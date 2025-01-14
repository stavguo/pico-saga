function init_units(world, components)
    -- Place leader centered at top, coin flip between king/queen seat
    local leader = world.entity()
    local throne = rnd(1) < 0.5 and 7 or 8
    leader += components.Position({x=throne, y=1, in_castle=true})
    local weapon = flr(rnd(3))
    leader += components.Unit({
        sprite=16+weapon
    })
    
    -- Place 8 units in formation
    for i=0,7 do
        local row = flr(i/4)
        local pos = i%4
        local is_right = pos >= 2
        local unit = world.entity()
        unit += components.Position({
            x = is_right and (11+(pos-2)*2) or (2+pos*2),
            y = 2 + row*2,
            in_castle = true
        })
        unit += components.Unit({
            sprite=13+flr(rnd(3))
        })
    end
end