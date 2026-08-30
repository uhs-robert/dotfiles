# Machine profiles

Optional hostname-specific Hyprland overrides live in this directory.

Create `<hostname>.lua` and return only the values that differ from the shared configuration:

```lua
return {
  persistent_workspaces = 4,
  drm_devices = "/dev/dri/card0",
  app = {
    term = "foot",
  },
}
```

The loader uses `$HOSTNAME` first and falls back to `/etc/hostname`. Missing profiles are ignored. Explicit values passed by `hyprland.lua` take precedence over profile values, so profiles remain a narrow override layer rather than a replacement configuration.
