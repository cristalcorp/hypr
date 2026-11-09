-- Layout "video" (lua:video) for the video workspace (D-015): each window takes the full monitor
-- height (Waybar's reserved area ignored), centred, width = height x aspect; the wallpaper shows
-- on both sides (OLED). Layout messages: grow / shrink -> next / previous aspect.
local ASPECTS = { 4 / 3, 16 / 9, 1.85, 2.0, 2.39 }
local idx = 2   -- 16:9
hl.layout.register("video", {
    recalculate = function(ctx)
        local m = hl.get_monitor_at(ctx.area.x + 1, ctx.area.y + 1)
        if not m then return end
        local w = math.min(m.width, math.floor(m.height * ASPECTS[idx]))
        local box = { x = m.x + math.floor((m.width - w) / 2), y = m.y, w = w, h = m.height }
        for _, t in ipairs(ctx.targets) do t:place(box) end
    end,
    layout_msg = function(ctx, msg)
        if msg == "grow" then idx = math.min(idx + 1, #ASPECTS)
        elseif msg == "shrink" then idx = math.max(idx - 1, 1) end
        return true
    end,
})
