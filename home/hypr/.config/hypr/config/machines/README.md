# Machine profiles

Machine-specific Hyprland configuration lives in this directory.

`workstation.lua` owns the current workstation hardware configuration, including monitor layouts and DRM device ordering. This keeps physical-device details out of the shared `hyprland.lua` entrypoint.

Optional hostname-specific overrides can further specialize that configuration. Create `<hostname>.lua` and return only the values that differ from the workstation configuration:

```lua
return {
  persistent_workspaces = 4,
  drm_devices = "/dev/dri/card0",
  app = {
    term = "foot",
  },
}
```

The loader uses `$HOSTNAME` first and falls back to `/etc/hostname`. Missing hostname profiles are ignored. Hostname-profile values take precedence over `workstation.lua`, so host-specific differences can be represented without duplicating the full configuration.
