-- hold-to-speedup.lua
--
-- Hold Space (or the left mouse button) to play at an increased speed, like
-- YouTube. Release to go back to the speed you were on. A short tap keeps the
-- usual pause/unpause behaviour -- and tapping once the file has finished
-- replays it from the start.
--
-- Fork of https://github.com/iiiGerardoiii/mpv-hold-to-speedup
-- Settings live in script-opts/hold-to-speedup.conf

local mp = require "mp"
local options = require "mp.options"

local o = {
    speed          = 2.0,   -- playback speed while held
    hold_threshold = 0.2,   -- seconds before a press counts as a hold
    enable_mouse   = true,  -- also speed up while the left mouse button is held
    replay_on_end  = true,  -- tapping on the final frame restarts the file
    keep_open      = true,  -- force keep-open so there is a frame left to tap on
    osd_duration   = 1.0,
}
options.read_options(o, "hold-to-speedup")

-- Upstream shared one timer and one is_speeding flag between the keyboard and
-- the mouse binding, so releasing one cancelled the other's hold. Give each
-- binding its own state instead.
local function new_state()
    return { timer = nil, speeding = false, saved_speed = 1.0 }
end

local space_state = new_state()
local mouse_state = new_state()

local function speed_on(state)
    state.speeding    = true
    state.saved_speed = mp.get_property_number("speed", 1.0)
    mp.set_property_number("speed", o.speed)
    mp.osd_message("▶▶  " .. o.speed .. "x", o.osd_duration)
end

local function speed_off(state)
    mp.set_property_number("speed", state.saved_speed)
    state.speeding = false
    mp.osd_message("▶  " .. state.saved_speed .. "x", o.osd_duration)
end

-- eof-reached is only true while keep-open is parking us on the last frame.
-- The duration check is a fallback; both are gated on being paused, so an
-- ordinary pause just before the end is never mistaken for the end.
local function at_end_of_file()
    if not mp.get_property_bool("pause", false) then return false end
    if mp.get_property_bool("eof-reached", false) then return true end

    local duration = mp.get_property_number("duration")
    local position = mp.get_property_number("time-pos")
    return duration ~= nil and position ~= nil
        and duration > 0 and (duration - position) < 0.25
end

local function replay()
    mp.commandv("seek", "0", "absolute", "exact")
    mp.set_property_bool("pause", false)
    mp.osd_message("↺  Replay", o.osd_duration)
end

local function press(state)
    if state.timer then state.timer:kill() end
    state.timer = mp.add_timeout(o.hold_threshold, function()
        state.timer = nil
        speed_on(state)
    end)
end

local function release(state, on_tap)
    if state.timer then
        state.timer:kill()
        state.timer = nil
    end

    if state.speeding then
        speed_off(state)
    elseif on_tap then
        on_tap()
    end
end

local function space_tap()
    if o.replay_on_end and at_end_of_file() then
        replay()
    else
        mp.command("cycle pause")
    end
end

mp.add_forced_key_binding("space", "hold_to_speedup_space", function(event)
    if event.event == "down" then
        press(space_state)
    elseif event.event == "up" then
        release(space_state, space_tap)
    end
end, { complex = true })

if o.enable_mouse then
    -- Deliberately no tap action here: a bare left click keeps whatever the
    -- player already does with it.
    mp.add_forced_key_binding("MBTN_LEFT", "hold_to_speedup_mouse", function(event)
        if event.event == "down" then
            press(mouse_state)
        elseif event.event == "up" then
            release(mouse_state, nil)
        end
    end, { complex = true })
end

-- Without keep-open the player drops the file the instant it ends, so there is
-- no last frame to tap on and nothing to seek back through.
if o.keep_open and o.replay_on_end then
    mp.register_event("file-loaded", function()
        if mp.get_property("keep-open") == "no" then
            mp.set_property("keep-open", "yes")
        end
    end)
end
