--- Window groups submap

local Cmd = require("lib.actions.cmd") ---@class Cmd
local Config = require("config") ---@class Config
local Submap = require("lib.key.submap") ---@class Submap

local function dispatch(name, args)
  local command = "hyprctl dispatch " .. name
  if args then command = command .. " " .. args end
  return Cmd.run(command)
end

Submap.define({
  name = "Groups",
  desc = "+Groups",
  enter = Config.leader .. " + SHIFT + G",

  escape = "reset",
  catchall = "stay",

  binds = function()
    return {
      { "G", dispatch("togglegroup"), "Toggle Group" },
      { "N", dispatch("changegroupactive", "f"), "Next Group Window" },
      { "P", dispatch("changegroupactive", "b"), "Previous Group Window" },
      { "I", dispatch("moveintogroup", "r"), "Move Into Group" },
      { "O", dispatch("moveoutofgroup"), "Move Out of Group" },
      { "L", dispatch("lockactivegroup", "toggle"), "Toggle Group Lock" },
    }
  end,
}).setup()
