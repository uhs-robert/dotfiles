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
--- Missing profiles are intentionally ignored.
--- @return table
function Machines.load()
  local name = hostname()
  if not name then return {} end

  local ok, profile = pcall(require, "config.machines." .. name)
  if not ok then return {} end

  return profile
end

--- Merge the current machine profile with explicit session overrides.
--- Explicit overrides win over machine-profile values.
--- @param overrides table|nil
--- @return table
function Machines.merge(overrides)
  local merged = Utils.deep_extend({}, Machines.load())
  if overrides then Utils.deep_extend(merged, overrides) end

  return merged
end

return Machines
