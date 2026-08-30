local Utils = require("lib.utils") ---@class Utils

local Machines = {}

local function hostname()
  local name = os.getenv("HOSTNAME")
  if name and name ~= "" then return name end

  local file = io.open("/etc/hostname", "r")
  if not file then return nil end
  name = file:read("*l")
  file:close()

  return name
end

--- Load the optional profile for the current hostname.
--- Missing profiles are intentionally ignored; errors in existing profiles propagate.
--- @return table
function Machines.load()
  local name = hostname()
  if not name then return {} end

  local module = "config.machines." .. name
  if not package.searchpath(module, package.path) then return {} end

  return require(module)
end

--- Merge shared session values with the current machine profile.
--- Machine-profile values win so host-specific hardware can override shared defaults.
--- @param shared table|nil
--- @return table
function Machines.merge(shared)
  local merged = Utils.deep_extend({}, shared or {})
  Utils.deep_extend(merged, Machines.load())

  return merged
end

return Machines
