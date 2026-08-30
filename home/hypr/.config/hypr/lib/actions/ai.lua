--- AI workspace and voice command actions.

local Config = require("config") --- @class Config

local AI = {
  recording = false,
  prefix = nil,
  submit = true,
  pending_show = false,
}

local AI_CLASS = "ai-workspace"
local AI_WORKSPACE = "ai"
local TRANSCRIPT_FILE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/ai-voice-command.txt"
local AI_SEND = "~/.config/hypr/scripts/ai-send.sh"

--- @param value string
--- @return string
local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

--- @param command string
--- @param rules table|nil
local function exec(command, rules)
  hl.dispatch(hl.dsp.exec_cmd(command, rules))
end

--- @return boolean
local function window_exists()
  return #hl.get_windows({ class = AI_CLASS }) > 0
end

--- @return boolean
local function workspace_visible()
  for _, monitor in pairs(hl.get_monitors()) do
    local workspace = monitor.active_special_workspace
    if workspace and workspace.name == "special:" .. AI_WORKSPACE then return true end
  end

  return false
end

--- @param window any|string
local function show_workspace(window)
  if not workspace_visible() then hl.dispatch(hl.dsp.workspace.toggle_special(AI_WORKSPACE)) end
  hl.dispatch(hl.dsp.focus({ window = window }))
end

function AI.launch()
  if window_exists() then return end

  exec(Config.app.term_cmd .. " --class " .. AI_CLASS .. " -e tmuxifier load-session ai", {
    workspace = "special:" .. AI_WORKSPACE .. " silent",
  })
end

function AI.show()
  local windows = hl.get_windows({ class = AI_CLASS })
  if #windows > 0 then
    show_workspace(windows[1])
    return
  end

  AI.pending_show = true
  AI.launch()
end

hl.on("window.open", function(window)
  if not AI.pending_show or window.class ~= AI_CLASS then return end

  AI.pending_show = false
  show_workspace(window)
end)

local function start_recording(prefix, submit)
  AI.recording = true
  AI.prefix = prefix
  AI.submit = submit

  os.remove(TRANSCRIPT_FILE)
  exec("voxtype record start --file=" .. shell_quote(TRANSCRIPT_FILE))
end

local function finish_recording()
  exec("voxtype record stop")

  local prefix = AI.prefix or ""
  local mode = AI.submit and "submit" or "prefill"

  AI.recording = false
  AI.prefix = nil
  AI.submit = true

  exec(string.format(
    "%s %s %s %s",
    AI_SEND,
    shell_quote(TRANSCRIPT_FILE),
    shell_quote(prefix),
    mode
  ))

  AI.show()
end

--- Toggle VoxType recording for a tool-specific prompt prefix.
--- Press once to start recording; press again to stop and send/prefill.
--- @param prefix string
--- @param submit boolean
function AI.toggle(prefix, submit)
  if AI.recording then
    finish_recording()
    return
  end

  start_recording(prefix, submit)
end

return AI
