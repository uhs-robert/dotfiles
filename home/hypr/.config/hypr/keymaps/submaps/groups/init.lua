--- Window groups submap

local Config = require("config") ---@class Config
local Submap = require("lib.key.submap") ---@class Submap
local Window = require("lib.actions.window") ---@class WindowActions

Submap.define({
  name = "Groups",
  desc = "+Groups",
  enter = Config.leader .. " + SHIFT + G",

  escape = "reset",
  catchall = "stay",

  binds = function()
    return {
      { "G", Window.group_toggle(), "Toggle Group" },
      { "N", Window.group_next(), "Next Group Window" },
      { "P", Window.group_prev(), "Previous Group Window" },
      { "I", Window.group_move_in(), "Move Into Group" },
      { "O", Window.group_move_out(), "Move Out of Group" },
      { "L", Window.group_lock_toggle(), "Toggle Group Lock" },
    }
  end,
}).setup()
