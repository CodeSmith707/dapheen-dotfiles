-- MONITORS.LUA
-- https://wiki.hypr.land/Configuring/Monitors/
-- Find your monitor names with:
--   hyprctl monitors

-- 1. First monitor
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", disabled = true })

-- 2. Second monitor
-- hl.monitor({ output = "eDP-1", disabled = true })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- 3. Extend / Auto

-- Acer VG240Y S: primary monitor, 144 Hz, on the left
hl.monitor({
    output = "DP-1",
    mode = "1920x1080@143.85Hz",
    position = "0x0",
    scale = 1
})

-- Dell P2419H: secondary monitor, on the right
hl.monitor({
    output = "DP-2",
    mode = "1920x1080@60Hz",
    position = "1920x0",
    scale = 1
})

-- 4. Duplicate
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1 })

-- 5. Second vertical monitor
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1 })
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "1920x0", scale = 1, transform = 1 })


-- WORKSPACE RULES
-- https://wiki.hypr.land/Configuring/Workspace-Rules/

-- hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR, default = true })

hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = MONITOR1, default = true, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = MONITOR1, default = true, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = MONITOR1, default = true, persistent = true })

-- hl.workspace_rule({ workspace = "5", monitor = MONITOR2, default = true, persistent = true })
-- hl.workspace_rule({ workspace = "6", monitor = MONITOR2, default = true, persistent = true })

