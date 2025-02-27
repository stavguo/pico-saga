TERRAIN_COSTS = {
    [1] = 1, -- PLAINS
    [3] = 2 , -- FOREST
    [4] = 4 , -- THICKET
    [2] = 4 , -- SHOAL
    [6] = nil , -- SEA(impassable)
    [5] = 2 , -- SAND
    [7] = nil, -- MOUNTAIN(impassable)
    [8] = nil, -- PLAYER CASTLE
    [9] = nil -- ENEMY CASTLE
}

-- Terrain Effects on Hit Rate
TERRAIN_EFFECTS = {
    [1] = 0,   -- Plains: no effect
    [3] = 10, -- Forest: -10% hit rate
    [4] = 15, -- Thicket: -15% hit rate
    [2] = 5,  -- Shoal: -5% hit rate
    [5] = 5,  -- Sand: -5% hit rate
    [6] = 20, -- Sea: -20% hit rate (unlikely to attack from here)
    [7] = 20, -- Mountain: -20% hit rate (unlikely to attack from here)
    [8] = 0,   -- Player Castle: no effect
    [9] = 0    -- Enemy Castle: no effect
}

LAYERS = {
    { 1 / 16, 1 },
    { 1 / 8,  1 / 2 },
    { 1 / 4,  1 / 4 },
    { 1 / 2,  1 / 8 }
}

TREE_LAYERS = {
    --{ 1 / 8,  1 },
    { 1 / 4,  1 },
    { 1 / 2,  1 / 2 }
}

UNIT_STATS = {
    ["Lance"] = { Sprite = 14, HP = 30, Str = 20, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6, Atr = 1 },
    ["Axe"] = { Sprite = 15, HP = 30, Str = 20, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6, Atr = 1 },
    ["Sword"] = { Sprite = 13, HP = 30, Str = 20, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6, Atr = 1 },
    ["Archer"] = { HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6, Atr = 3 },
    ["Mage"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 6, Def = 1, Mdf = 5, Mov = 5, Atr = 1 },
    ["Thief"] = { HP = 26, Str = 3, Mag = 0, Skl = 3, Spd = 7, Def = 1, Mdf = 0, Mov = 6, Atr = 1 },
    ["Monk"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 6, Def = 1, Mdf = 7, Mov = 5, Atr = 1  }
}

-- Weapon Triangle Matchups
WEAPON_TRIANGLE = {
    ["Sword"] = {"Axe"},
    ["Axe"] = {"Lance"},
    ["Lance"] = {"Sword"},
    ["Monk"] = {"Archer", "Mage", "Thief"}
}

function SHUFFLE(items)
    for i = #items, 2, -1 do
        local j = flr(rnd(i)) + 1
        items[i], items[j] = items[j], items[i]
    end
end

-- insert into start of table
function insert(t, val)
    for i=(#t+1),2,-1 do
        t[i] = t[i-1]
    end
    t[1] = val
end

-- insert into table and sort by priority
function insert(t, val, p)
    if #t >= 1 then
        add(t, {})
        for i=(#t),2,-1 do
            local next = t[i-1]
            if p < next[2] then
                t[i] = {val, p}
                return
            else
                t[i] = next
            end
        end
        t[1] = {val, p}
    else
        add(t, {val, p}) 
    end
end

-- pop the last element off a table
function popEnd(t)
    local top = t[#t]
    del(t,t[#t])
    return top[1]
end

function reverse(t)
    for i=1,(#t/2) do
        local temp = t[i]
        local oppindex = #t-(i-1)
        t[i] = t[oppindex]
        t[oppindex] = temp
    end
end

-- translate a 2d x,y coordinate to a 1d index and back again
function vectoindex(vec)
    return maptoindex(vec[1],vec[2])
end

function maptoindex(x, y)
    return ((x+1) * 32) + y
end

function indextomap(index)
    local x = (index-1)/32
    local y = index - (x * 32)
    return {x,y}
end 
