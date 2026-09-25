-- Easy Effects reads its sink's monitor, which ignores the sink volume unless channel-volumes is on.

log = Log.open_topic ("s-easyeffects-monitor-volume")

easyeffects_monitor_volume_hook = SimpleEventHook {
  name = "easyeffects/fix-monitor-channel-volumes",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "node.name", "=", "easyeffects_sink" },
    },
  },
  execute = function (event)
    local node = event:get_subject ()
    local pod = Pod.Object {
      "Spa:Pod:Object:Param:Props", "Props",
      params = Pod.Struct { "monitor.channel-volumes", true },
    }
    log:info (node, "enabling monitor.channel-volumes on easyeffects_sink")
    node:set_param ("Props", pod)
  end
}

easyeffects_monitor_volume_hook:register ()
