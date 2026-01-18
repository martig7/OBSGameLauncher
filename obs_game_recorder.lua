--[[
    Game Auto-Recorder OBS Script (Lightweight)

    Reads state from game_state file written by game_watcher.pyw
    Very lightweight - just file reads, no process scanning.
]]

obs = obslua

-- Settings
local state_file_path = ""
local check_interval = 50  -- ms
local last_state = ""
local is_recording = false
local current_game = ""

-- Get default path (same folder as this script, or user profile)
function get_default_state_path()
    -- Try UserProfile location first (most reliable)
    local user_profile = os.getenv("USERPROFILE")
    if user_profile then
        -- Check common locations
        local paths = {
            user_profile .. "\\Downloads\\OBSGameLauncher\\game_state",
            user_profile .. "\\.config\\OBSGameLauncher\\game_state",
        }
        for _, path in ipairs(paths) do
            local f = io.open(path, "r")
            if f then
                f:close()
                return path
            end
        end
        -- Return first path as default even if doesn't exist yet
        return paths[1]
    end
    return "C:\\game_state"
end

-- Read first line from file
function read_state_file()
    if state_file_path == "" then
        return nil
    end

    local file = io.open(state_file_path, "r")
    if file == nil then
        return nil
    end
    local content = file:read("*line")
    file:close()
    return content
end

-- Check if file exists
function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Split string by delimiter
function split(str, delim)
    if str == nil then
        return {}
    end
    local result = {}
    for match in (str .. delim):gmatch("(.-)" .. delim) do
        table.insert(result, match)
    end
    return result
end

-- Main loop - called every check_interval ms
function check_state()
    local state = read_state_file()

    if state == nil or state == last_state then
        return
    end

    last_state = state

    local parts = split(state, "|")
    local status = parts[1]
    local game_name = parts[2] or ""

    local recording_active = obs.obs_frontend_recording_active()

    if status == "RECORDING" and not recording_active and not is_recording then
        -- Start recording
        obs.script_log(obs.LOG_INFO, "Game detected: " .. game_name .. " - Starting recording")
        obs.obs_frontend_recording_start()
        is_recording = true
        current_game = game_name

    elseif status ~= "RECORDING" and is_recording then
        -- Stop recording
        obs.script_log(obs.LOG_INFO, "Game closed: " .. current_game .. " - Stopping recording")
        obs.obs_frontend_recording_stop()
        is_recording = false
        current_game = ""

    elseif status == "STOPPED" then
        -- Watcher stopped
        if is_recording then
            obs.script_log(obs.LOG_WARNING, "Game watcher stopped while recording!")
        end
    end
end

-- Script description
function script_description()
    return [[
<h2>Game Auto-Recorder</h2>
<p>Automatically records when games are running.</p>
<hr>
<p><b>Setup:</b></p>
<ol>
<li>Set the correct path to <code>game_state</code> file below</li>
<li>Run <code>game_watcher.pyw</code> in the background</li>
<li>Use the Game Manager to add games</li>
</ol>
<p><small>Uses file-based communication - minimal CPU impact.</small></p>
]]
end

-- Script properties
function script_properties()
    local props = obs.obs_properties_create()

    -- Path to state file
    obs.obs_properties_add_path(props, "state_file_path", "State File Path",
        obs.OBS_PATH_FILE, "State File (game_state)", nil)

    -- Check interval
    obs.obs_properties_add_int(props, "check_interval", "Check Interval (ms)", 20, 1000, 10)

    -- Status info
    local status_text = "Status: "
    if state_file_path ~= "" and file_exists(state_file_path) then
        local state = read_state_file()
        if state then
            status_text = status_text .. "Connected (" .. state .. ")"
        else
            status_text = status_text .. "File exists but empty"
        end
    else
        status_text = status_text .. "State file not found - check path!"
    end

    obs.obs_properties_add_text(props, "status_info", status_text, obs.OBS_TEXT_INFO)

    return props
end

-- Script defaults
function script_defaults(settings)
    local default_path = get_default_state_path()
    obs.obs_data_set_default_string(settings, "state_file_path", default_path)
    obs.obs_data_set_default_int(settings, "check_interval", 50)
end

-- Script update (called when settings change)
function script_update(settings)
    -- Remove old timer
    obs.timer_remove(check_state)

    -- Get settings
    state_file_path = obs.obs_data_get_string(settings, "state_file_path")
    check_interval = obs.obs_data_get_int(settings, "check_interval")

    -- Log status
    if state_file_path == "" then
        obs.script_log(obs.LOG_WARNING, "State file path not set!")
    elseif file_exists(state_file_path) then
        obs.script_log(obs.LOG_INFO, "State file found: " .. state_file_path)
        -- Start timer
        obs.timer_add(check_state, check_interval)
    else
        obs.script_log(obs.LOG_WARNING, "State file not found: " .. state_file_path)
        obs.script_log(obs.LOG_WARNING, "Make sure game_watcher.pyw is running!")
        -- Still start timer in case file appears later
        obs.timer_add(check_state, check_interval)
    end
end

-- Script load
function script_load(settings)
    obs.script_log(obs.LOG_INFO, "Game Auto-Recorder loaded")
end

-- Script unload
function script_unload()
    obs.timer_remove(check_state)
    obs.script_log(obs.LOG_INFO, "Game Auto-Recorder unloaded")
end
