TERRAIN_TYPES = {
    [1] = "plains", -- PLAINS
    [2] = "shoal" , -- SHOAL
    [3] = "forest" , -- FOREST
    [4] = "thicket" , -- THICKET
    [5] = "sand" , -- SAND
    [6] = "sea", -- Sea
    [7] = "cliff", -- Mountain
}

TERRAIN_COSTS = {
    [1] = 1, -- PLAINS
    [3] = 2 , -- FOREST
    [4] = 4 , -- THICKET
    [2] = 4 , -- SHOAL
    [5] = 2 , -- SAND
}

-- Terrain Effects on Hit Rate
TERRAIN_EFFECTS = {
    [3] = 20, -- Forest
    [4] = 30, -- Thicket
    [2] = 10,  -- Shoal
    [5] = 5,  -- Sand
    [6] = 20, -- Sea
    [7] = 20, -- Mountain
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
    return vec[2] * 32 + vec[1] + 1
end

function indextovec(index)
    local i = index - 1
    local x, y = i % 32, i \ 32
    return {x,y}
end