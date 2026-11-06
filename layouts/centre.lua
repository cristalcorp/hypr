-- Custom layout "centre" (lua:centre) for the 32:9 screen (D-011).
-- Fixed centre window; each side is a dwindle-like tree: a new window splits the active side window
-- in half (first split of a side: one above the other; then along the longer dimension).
-- From the centre, a new window goes to the side with fewer windows.
-- A window moved from another workspace keeps its place: in the centre column -> centre (if free),
-- otherwise the side it is on.
-- One state per workspace, saved in $XDG_RUNTIME_DIR (session only) so that a reload keeps the
-- arrangement (on reload, Hyprland hands over windows one by one with placeholder boxes).
-- Layout messages: "mfact <0.2..0.8>", "grow", "shrink".
local MFACT = 0.36
local SAVE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-centre-layout.lua"

-- serialize plain tables (strings, numbers, nested tables) to a Lua literal
local function dump(v)
    if type(v) == "table" then
        local parts = {}
        for k, x in pairs(v) do parts[#parts + 1] = "[" .. dump(k) .. "]=" .. dump(x) end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif type(v) == "string" then return string.format("%q", v)
    else return tostring(v) end
end

local function load_states()
    local f = io.open(SAVE, "r")
    if not f then return {} end
    local src = f:read("a"); f:close()
    local chunk = load("return " .. src, "centre-state", "t", {})
    local ok, t = pcall(chunk or function() end)
    return (ok and type(t) == "table") and t or {}
end

local states = load_states()   -- workspace key -> { mfact, centre, l, r } (l / r: tree nodes)
local saved = dump(states)

local function save_states()
    local s = dump(states)
    if s == saved then return end
    local f = io.open(SAVE, "w")
    if f then f:write(s); f:close(); saved = s end
end

-- tree node: { id = address } (leaf) or { a = node, b = node } (split in half)
local function count(n) if not n then return 0 end; if n.id then return 1 end; return count(n.a) + count(n.b) end

local function has(n, id)
    if not n then return false end
    if n.id then return n.id == id end
    return has(n.a, id) or has(n.b, id)
end

local function where(st, id)
    if st.centre == id then return "c" end
    if has(st.l, id) then return "l" end
    if has(st.r, id) then return "r" end
end

-- remove leaves whose id fails keep(id); a split left with one child collapses into it
local function prune(n, keep)
    if not n then return nil end
    if n.id then return keep(n.id) and n or nil end
    n.a, n.b = prune(n.a, keep), prune(n.b, keep)
    if not n.a then return n.b end
    if not n.b then return n.a end
    return n
end

-- replace leaf `target` by a split (target, new)
local function split_leaf(n, target, id)
    if n.id then
        if n.id == target then return { a = { id = n.id }, b = { id = id } } end
        return n
    end
    n.a, n.b = split_leaf(n.a, target, id), split_leaf(n.b, target, id)
    return n
end

local function last_leaf(n) if n.id then return n.id end; return last_leaf(n.b) end

local function insert(st, s, id, target)
    if not st[s] then st[s] = { id = id }; return end
    st[s] = split_leaf(st[s], target or last_leaf(st[s]), id)
end

-- most recently focused window of this workspace already placed, excluding `skip`
local function prev_focused(st, wins, skip)
    local best, bid = nil, math.huge
    for _, w in ipairs(wins) do
        if w.address ~= skip and where(st, w.address) and w.focus_history_id >= 0 and w.focus_history_id < bid then
            best, bid = w.address, w.focus_history_id
        end
    end
    return best
end

local function ws_of(ctx)
    for _, t in ipairs(ctx.targets) do
        local ws = t.window and t.window.workspace
        if ws then return ws end
    end
end

local function ws_key(ctx)
    local ws = ws_of(ctx)
    return ws and (ws.name or tostring(ws.id)) or "?"
end

local function sync(ctx, st)
    local wins, present = {}, {}
    for _, t in ipairs(ctx.targets) do
        if t.window then wins[#wins + 1] = t.window; present[t.window.address] = true end
    end
    -- keep windows still on this workspace even if not handed over yet (reload: one by one)
    local alive = {}
    local ws = ws_of(ctx)
    if ws then for _, w in ipairs(hl.get_workspace_windows(ws) or {}) do alive[w.address] = true end end
    local keep = function(id) return present[id] or alive[id] end
    local centre_closed = st.centre and not keep(st.centre)
    if centre_closed then st.centre = nil end
    st.l, st.r = prune(st.l, keep), prune(st.r, keep)

    if centre_closed then   -- promote the most recently focused side window
        local p = prev_focused(st, wins, nil)
        if p then
            local drop = function(id) return id ~= p end
            st.l, st.r = prune(st.l, drop), prune(st.r, drop)
            st.centre = p
        end
    end

    local a = ctx.area
    local mid = a.x + a.w / 2
    local half_centre = a.w * st.mfact / 2
    for _, t in ipairs(ctx.targets) do
        local w = t.window
        if w and not where(st, w.address) then
            local id = w.address
            if t.box.w > 0 then
                -- already on screen (reload, moved here): keep its place
                local cx = t.box.x + t.box.w / 2
                if not st.centre and math.abs(cx - mid) < half_centre then st.centre = id
                else insert(st, cx < mid and "l" or "r", id, nil) end
            elseif not st.centre then
                st.centre = id
            else
                local p = prev_focused(st, wins, id)
                local s = p and where(st, p)
                if s == "l" or s == "r" then insert(st, s, id, p)
                else insert(st, (count(st.r) < count(st.l)) and "r" or "l", id, nil) end
            end
        end
    end
end

-- lay a tree out in box: split in half, one above the other at the root, then along the longer dimension
local function place_tree(n, box, by, depth)
    if not n then return end
    if n.id then if by[n.id] then by[n.id]:place(box) end; return end
    if depth > 0 and box.w >= box.h then
        local w = math.floor(box.w / 2)
        place_tree(n.a, { x = box.x, y = box.y, w = w, h = box.h }, by, depth + 1)
        place_tree(n.b, { x = box.x + w, y = box.y, w = box.w - w, h = box.h }, by, depth + 1)
    else
        local h = math.floor(box.h / 2)
        place_tree(n.a, { x = box.x, y = box.y, w = box.w, h = h }, by, depth + 1)
        place_tree(n.b, { x = box.x, y = box.y + h, w = box.w, h = box.h - h }, by, depth + 1)
    end
end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function state_of(ctx)
    local k = ws_key(ctx)
    states[k] = states[k] or { mfact = MFACT }
    return states[k]
end

hl.layout.register("centre", {
    recalculate = function(ctx)
        if #ctx.targets == 0 then return end
        local st = state_of(ctx)
        sync(ctx, st)
        save_states()
        local by = {}
        for _, t in ipairs(ctx.targets) do if t.window then by[t.window.address] = t end end

        local a = ctx.area
        local cw = math.floor(a.w * st.mfact)
        local sw = math.floor((a.w - cw) / 2)
        if by[st.centre] then by[st.centre]:place({ x = a.x + sw, y = a.y, w = cw, h = a.h }) end
        place_tree(st.l, { x = a.x, y = a.y, w = sw, h = a.h }, by, 0)
        place_tree(st.r, { x = a.x + sw + cw, y = a.y, w = a.w - sw - cw, h = a.h }, by, 0)
    end,

    layout_msg = function(ctx, msg)
        local st = state_of(ctx)
        local cmd, arg = msg:match("^(%S+)%s*(.*)$")
        if cmd == "mfact" then st.mfact = clamp(tonumber(arg) or st.mfact, 0.2, 0.8)
        elseif cmd == "grow" then st.mfact = clamp(st.mfact + 0.02, 0.2, 0.8)
        elseif cmd == "shrink" then st.mfact = clamp(st.mfact - 0.02, 0.2, 0.8)
        else return "centre: expected mfact <0.2..0.8>, grow or shrink" end
        save_states()
        return true
    end,
})
