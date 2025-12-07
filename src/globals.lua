MAP_W = 16

TERRAIN_TYPES = {
    [1] = "plains", -- PLAINS
    [2] = "shoal" , -- SHOAL
    [3] = "forest" , -- FOREST
    [4] = "thicket" , -- THICKET
    [5] = "road" , -- ROAD
    [6] = "sea", -- Sea
    [7] = "cliff", -- Mountain
    [16] = "bridge", -- Bridge
    [17] = "bridge", -- Bridge
}

TERRAIN_COSTS = {
    [1] = 1, -- PLAINS
    [3] = 2 , -- FOREST
    [4] = 4 , -- THICKET
    [2] = 4 , -- SHOAL
    [5] = 0.5, -- ROAD
    [16] = 0.5, -- BRIDGE
    [17] = 0.5 -- BRIDGE
}

-- Terrain Effects on Hit Rate
TERRAIN_EFFECTS = {
    [3] = 20, -- Forest
    [4] = 30, -- Thicket
    [2] = 10,  -- Shoal
    [5] = 0,  -- Road
    [6] = 20, -- Sea
    [7] = 20, -- Mountain
    [16] = -10, -- BRIDGE
    [17] = -10 -- BRIDGE
}

LAYERS = {
    -- { 1 / 16, 1 },
    { 1 / 8,  1 },
    { 1 / 4,  1 / 2 },
    { 1 / 2,  1 / 4 },
    { 1 ,  1 / 8 }
}

TREE_LAYERS = {
    --{ 1 / 8,  1 },
    { 1 / 4,  1 },
    { 1 / 2,  1 / 2 },
    { 1 ,  1 / 4 }
}

UNIT_STATS = {
    ["Lance"] = { Sprite = 19, HP = 30, Str = 20, Mag = 0, Skl = 50, Spd = 10, Def = 5, Mdf = 0, Mov = 5, Atr = 1 },
    ["Axe"] = { Sprite = 20, HP = 30, Str = 20, Mag = 0, Skl = 50, Spd = 10, Def = 5, Mdf = 0, Mov = 5, Atr = 1 },
    ["Sword"] = { Sprite = 18, HP = 30, Str = 20, Mag = 0, Skl = 50, Spd = 10, Def = 5, Mdf = 0, Mov = 5, Atr = 1 },
    ["Archer"] = { Sprite = 21, HP = 30, Str = 15, Mag = 0, Skl = 50, Spd = 5, Def = 5, Mdf = 0, Mov = 5, Atr = 3 },
    ["Mage"] = { Sprite = 22, HP = 20, Str = 0, Mag = 20, Skl = 45, Spd = 5, Def = 0, Mdf = 5, Mov = 4, Atr = 2 },
    ["Thief"] = { Sprite = 23, HP = 20, Str = 15, Mag = 0, Skl = 50, Spd = 20, Def = 2, Mdf = 0, Mov = 6, Atr = 1 },
    ["Monk"] = { Sprite = 24, HP = 30, Str = 15, Mag = 0, Skl = 50, Spd = 10, Def = 5, Mdf = 10, Mov = 4, Atr = 1  }
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
function insert(tbl, val, p)
    if #tbl >= 1 then
        add(tbl, {})
        for i=(#tbl),2,-1 do
            local prev = tbl[i-1]
            if p < prev[2] then
                tbl[i] = {val, p}
                return
            else
                tbl[i] = prev
            end
        end
        tbl[1] = {val, p}
    else
        add(tbl, {val, p}) 
    end
end

function get_min_key(units_map)
    local min_key = nil
    for pos, _ in pairs(units_map) do
        if min_key == nil or pos < min_key then
            min_key = pos
        end
    end
    return min_key
end

function get_keys(t)
    local keys = {}
    for key, _ in pairs(t) do
        add(keys, key)
    end
    return keys
end

function reverse(tbl)
    for i=1,(#tbl/2) do
        local temp = tbl[i]
        local oppindex = #tbl-(i-1)
        tbl[i] = tbl[oppindex]
        tbl[oppindex] = temp
    end
end

-- translate a 2d x,y coordinate to a 1d index and back again
function vectoindex(vec)
    return vec[2] * MAP_W + vec[1] + 1
end

function indextovec(index)
    local i = index - 1
    local x, y = i % MAP_W, i \ MAP_W
    return {x,y}
end

function man_dist(a, b)
    return abs(a[1] - b[1]) + abs(a[2] - b[2])
end

function map_get(t_idx)
    local pos = indextovec(t_idx)
    return mget(pos[1], pos[2])
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end