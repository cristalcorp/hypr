-- Custom layout "centre" (lua:centre) for the 32:9 screen (D-014).
-- Fixed centre window; each side is a dwindle-like tree: a new window splits the active side window
-- in half (first split of a side: one above the other; then along the longer dimension).
-- From the centre, a new window goes to the side with fewer windows.
-- A window moved from another workspace keeps its place: in the centre column -> centre (if free),
-- otherwise the side it is on.
-- One state per workspace, saved in $XDG_RUNTIME_DIR (session only) so that a reload keeps the
-- arrangement (on reload, Hyprland hands over windows one by one with placeholder boxes).
-- Layout messages:
--   mfact <0.2..0.8> | grow | shrink     width of the centre window
--   move <l|r|u|d>                        side window: up/down swaps with its neighbour, toward the
--                                         centre jumps to the other side; centre window: swaps with
--                                         the neighbouring side window
--   swapcentre                            swap the active window with the centre window
--   refresh                               recompute (sent on window close)
local NAME = CENTRE_LAYOUT_NAME or "centre"
local MFACT = 0.36
local SAVE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-" .. NAME .. "-layout.lua"

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
local geo = {}                 -- workspace key -> { address -> box } (last layout, not saved)

local function save_states()
    local s = dump(states)
    if s == saved then return end
    local f = io.open(SAVE, "w")
    if f then f:write(s); f:close(); saved = s end
end

-- tree node: { id = address } (leaf) or { a = node, b = node, dir = "h"|"v" } (split in half;
-- "h": side by side, "v": one above the other; kept when the tree changes, like dwindle's preserve_split)
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

-- replace leaf `target` by a split (target, new) in direction dir
local function split_leaf(n, target, id, dir)
    if n.id then
        if n.id == target then return { a = { id = n.id }, b = { id = id }, dir = dir } end
        return n
    end
    n.a, n.b = split_leaf(n.a, target, id, dir), split_leaf(n.b, target, id, dir)
    return n
end

-- exchange two ids wherever they are (centre or trees)
local function rename(n, from, to)
    if not n then return end
    if n.id then if n.id == from then n.id = to end; return end
    rename(n.a, from, to); rename(n.b, from, to)
end

local function swap(st, x, y)
    local tmp = "\0swap"
    for _, s in ipairs({ "l", "r" }) do rename(st[s], x, tmp); rename(st[s], y, x); rename(st[s], tmp, y) end
    if st.centre == x then st.centre = y elseif st.centre == y then st.centre = x end
end

local function last_leaf(n) if n.id then return n.id end; return last_leaf(n.b) end

-- first split of a side: one above the other; then along the longer dimension of the split window
local function insert(st, g, s, id, target)
    if not st[s] then st[s] = { id = id }; return end
    target = target or last_leaf(st[s])
    local b = g[target]
    local dir = "v"
    if not st[s].id and b and b.w >= b.h then dir = "h" end
    st[s] = split_leaf(st[s], target, id, dir)
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

local function sync(ctx, st, g)
    local wins, present = {}, {}
    for _, t in ipairs(ctx.targets) do
        if t.window then wins[#wins + 1] = t.window; present[t.window.address] = true end
    end
    -- keep windows still mapped on this workspace even if not handed over yet (reload: one by one);
    -- a closing window is no longer mapped, so its place is freed at once
    local alive = {}
    local ws = ws_of(ctx)
    if ws then
        for _, w in ipairs(hl.get_workspace_windows(ws) or {}) do
            if w.mapped then alive[w.address] = true end
        end
    end
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
                else insert(st, g, cx < mid and "l" or "r", id, nil) end
            elseif not st.centre then
                st.centre = id
            else
                local p = prev_focused(st, wins, id)
                local s = p and where(st, p)
                if s == "l" or s == "r" then insert(st, g, s, id, p)
                else insert(st, g, (count(st.r) < count(st.l)) and "r" or "l", id, nil) end
            end
        end
    end
end

-- lay a tree out in box: split in half, one above the other at the root, then along the longer dimension
local function place_tree(n, box, by, g, depth)
    if not n then return end
    if n.id then
        g[n.id] = box
        if by[n.id] then by[n.id]:place(box) end
        return
    end
    local dir = n.dir or ((depth > 0 and box.w >= box.h) and "h" or "v")
    if dir == "h" then
        local w = math.floor(box.w / 2)
        place_tree(n.a, { x = box.x, y = box.y, w = w, h = box.h }, by, g, depth + 1)
        place_tree(n.b, { x = box.x + w, y = box.y, w = box.w - w, h = box.h }, by, g, depth + 1)
    else
        local h = math.floor(box.h / 2)
        place_tree(n.a, { x = box.x, y = box.y, w = box.w, h = h }, by, g, depth + 1)
        place_tree(n.b, { x = box.x, y = box.y + h, w = box.w, h = box.h - h }, by, g, depth + 1)
    end
end

-- nearest window from box `b` in direction d (l/r/u/d), among boxes of g (excluding `self`)
local function neighbour(g, self, d, only)
    local b = g[self]
    if not b then return end
    local best, bd, bo
    for id, o in pairs(g) do
        if id ~= self and (not only or only(id)) then
            local dist, ov
            if d == "l" then dist = b.x - (o.x + o.w); ov = math.min(b.y + b.h, o.y + o.h) - math.max(b.y, o.y)
            elseif d == "r" then dist = o.x - (b.x + b.w); ov = math.min(b.y + b.h, o.y + o.h) - math.max(b.y, o.y)
            elseif d == "u" then dist = b.y - (o.y + o.h); ov = math.min(b.x + b.w, o.x + o.w) - math.max(b.x, o.x)
            else dist = o.y - (b.y + b.h); ov = math.min(b.x + b.w, o.x + o.w) - math.max(b.x, o.x) end
            if dist >= -2 and ov > 0 and (not best or dist < bd - 2 or (math.abs(dist - bd) <= 2 and ov > bo)) then
                best, bd, bo = id, dist, ov
            end
        end
    end
    return best
end

local function active_id(ctx)
    for _, t in ipairs(ctx.targets) do
        if t.window and t.window.active then return t.window.address end
    end
end

local function move(ctx, st, g, d)
    local id = active_id(ctx)
    local s = id and where(st, id)
    if not s then return end
    if s == "c" then
        -- centre: swap with the neighbouring window on that side
        if d == "l" or d == "r" then
            local n = neighbour(g, id, d)
            if n then swap(st, id, n) end
        end
        return
    end
    local n = neighbour(g, id, d)
    if n and where(st, n) == s then
        swap(st, id, n)                          -- same side: exchange places (dwindle-like)
    elseif n and where(st, n) == "c" then
        -- toward the centre: jump to the other side, splitting the window facing it
        local other = (s == "l") and "r" or "l"
        local b = g[id]
        local target
        if st[other] then
            local best, bo = nil, -1
            for oid, o in pairs(g) do
                if where(st, oid) == other then
                    local ov = math.min(b.y + b.h, o.y + o.h) - math.max(b.y, o.y)
                    if ov > bo then best, bo = oid, ov end
                end
            end
            target = best
        end
        local drop = function(x) return x ~= id end
        st[s] = prune(st[s], drop)
        insert(st, g, other, id, target)
    end
end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function state_of(ctx)
    local k = ws_key(ctx)
    states[k] = states[k] or { mfact = MFACT }
    geo[k] = geo[k] or {}
    return states[k], geo[k]
end

-- Hyprland does not recompute a custom layout after a window closes: ask for it
hl.on("window.destroy", function() hl.dispatch(hl.dsp.layout("refresh")) end)

hl.layout.register(NAME, {
    recalculate = function(ctx)
        if #ctx.targets == 0 then return end
        local st, g = state_of(ctx)
        sync(ctx, st, g)
        save_states()
        local by = {}
        for _, t in ipairs(ctx.targets) do if t.window then by[t.window.address] = t end end
        for k in pairs(g) do g[k] = nil end

        local a = ctx.area
        local cw = math.floor(a.w * st.mfact)
        local sw = math.floor((a.w - cw) / 2)
        if st.centre then
            g[st.centre] = { x = a.x + sw, y = a.y, w = cw, h = a.h }
            if by[st.centre] then by[st.centre]:place(g[st.centre]) end
        end
        place_tree(st.l, { x = a.x, y = a.y, w = sw, h = a.h }, by, g, 0)
        place_tree(st.r, { x = a.x + sw + cw, y = a.y, w = a.w - sw - cw, h = a.h }, by, g, 0)
    end,

    layout_msg = function(ctx, msg)
        local st, g = state_of(ctx)
        local cmd, arg = msg:match("^(%S+)%s*(.*)$")
        if cmd == "mfact" then st.mfact = clamp(tonumber(arg) or st.mfact, 0.2, 0.8)
        elseif cmd == "grow" then st.mfact = clamp(st.mfact + 0.02, 0.2, 0.8)
        elseif cmd == "shrink" then st.mfact = clamp(st.mfact - 0.02, 0.2, 0.8)
        elseif cmd == "move" and arg:match("^[lrud]$") then move(ctx, st, g, arg)
        elseif cmd == "swapcentre" then
            local id = active_id(ctx)
            if id and st.centre and id ~= st.centre then swap(st, id, st.centre) end
        elseif cmd == "refresh" then -- nothing: returning true recomputes the layout
        else return NAME .. ": expected mfact <0.2..0.8>, grow, shrink, move <l|r|u|d>, swapcentre or refresh" end
        save_states()
        return true
    end,
})
