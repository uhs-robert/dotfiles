# Termux

Standalone mobile SSH environment. Requires a current supported [Termux](https://github.com/termux/termux-app#installation) installation, network access, and the default `~/.config` location. Keep the checkout in Termux home, not Android shared storage (Stow needs symlinks).

## Install

In a fresh Termux session, run:

```sh
pkg update -y && pkg install -y git && git clone https://github.com/uhs-robert/dotfiles.git ~/dotfiles && bash ~/dotfiles/termux/install.sh
```

For an existing checkout, run `bash ~/dotfiles/termux/install.sh`. No submodules or Arch installer are needed. The installer prompts for an SSH key passphrase only when creating a key, prints public keys, sets Zsh as the default shell, and reloads Termux settings. Run `exec zsh` afterward.

All packages in `packages.txt` come from the [official Termux repository](https://github.com/termux/termux-packages/tree/master/packages). `zsh-autosuggestions` is installed as a package if available; otherwise it is cloned from [upstream](https://github.com/zsh-users/zsh-autosuggestions) into `~/.local/share/zsh/plugins/`. [fzf-tab](https://github.com/Aloxaf/fzf-tab) is cloned there too. No shell framework or compiled fallback is required. Failed downloads or unavailable packages stop installation; fix the reported error and rerun.

## SSH

The installer copies `~/.ssh/config.example` to `~/.ssh/config` only if absent. Replace its documentation-only hosts with real entries using `v ~/.ssh/config`. Real connection details stay outside the checkout. Keep short, literal `Host` aliases directly in that file; the picker does not expand `Include` files or `Match` blocks.

Add the public key printed by the installer to the server's `~/.ssh/authorized_keys`. For a server with password login enabled:

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub your-host-alias
```

Use the appropriate existing `.pub` path if you already have a key. Private keys never leave the phone.

- `s`: fuzzy-select an alias and connect. Escape cancels.
- `ssh <Tab>`: fuzzy host completion through fzf-tab.
- `ssh alias`: connect directly.

Wildcard, negated, and catch-all Host patterns are excluded. No persistent connections, keepalives, or automatic SSH sessions are configured.

## Everyday use

| Command/key | Action |
| --- | --- |
| `v` | Neovim |
| `y` | Yazi; return the shell to its final directory |
| `lg` | LazyGit, with Difftastic and a raw Git fallback |
| `up` | Topgrade updates |
| Zsh `Esc` | Vi normal mode |
| Zsh `Ctrl-r` | Search persistent command history |
| Neovim `<Space><Space>` / `<Space>,` | Find files / buffers |
| Neovim `<Space>gg` | Standard LazyVim LazyGit workflow |
| Yazi `gs` / `gd` / `gr` / `gy` | SSH directory / checkout / Git root / Yazi config |
| Yazi `gl` / `gw` / `cm` | LazyGit / changed files / permissions |
| Yazi `.` | Toggle hidden files |
| Yazi `Tp` / `Tf` | Toggle / maximize preview |
| Yazi `Ctrl-d` / `Ctrl-u` / `+` / `-` | Scroll / zoom preview |

Fastfetch runs on interactive Zsh startup. Neovim keeps LazyVim navigation, which-key, Git integration, and Oasis Night, but disables Mason, LSP, completion engines, formatters, linters, and Tree-sitter plugins. It uses built-in completion (`Ctrl-n` / `Ctrl-p`) and syntax highlighting. The Termux Neovim package may itself ship parsers; this profile installs none. Avoid enabling language extras through `LazyExtras` if you want to keep the profile minimal.

Yazi's six curated plugins are restored from `yazi/.config/yazi/package.toml` with `ya pkg install`. The installer copies that manifest into the local configuration on first run so upgrades do not dirty the checkout. The Oasis Night Dark flavor is bundled, including its upstream license.

The existing HeliBoard PC-style layout is deployed to `~/.termux/heliboard/`. Import its JSONC files manually through **HeliBoard → Settings → Layouts → Custom layouts → Add layout**. Termux's extra-key row is deployed automatically; HeliBoard cannot be configured by `termux-reload-settings`.

## Updates and safe reruns

`up` runs only Termux package updates, LazyVim plugin sync, Yazi package upgrades, and Git pulls. Git repositories in non-hidden home directories (plus Zsh plugins) use `--ff-only`; divergent or dirty work requiring intervention is reported rather than reset. Git discovery uses `~/[!.]*/**/.git/..`; hidden application caches are excluded to avoid pulling plugins managed by LazyVim and Yazi. It can be slow in a large home directory. Replace it with explicit repository paths in your local Topgrade config if needed. Neovim's mutable lockfile lives under its state directory.

Rerunning the installer preserves existing SSH configuration and keys (including nonstandard key filenames), existing plugin checkouts, and the local Yazi manifest. Existing `.pub` files also prevent key generation. An existing private key without a `.pub` file is used to print its public half and may prompt for its passphrase. Review unused public keys yourself if no working private key remains.

Stow checks all packages before linking any of them. Conflicting files cause a clear failure; back them up and move them manually, then rerun. The installer never adopts or overwrites them. A partial plugin download can be removed manually after inspecting the reported directory. Re-running Neovim sync can update its plugins.

Every configuration directory is an independent Stow package:

```sh
stow --dir="$HOME/dotfiles/termux" --target="$HOME" --no-folding zsh
stow --dir="$HOME/dotfiles/termux" --target="$HOME" --delete zsh
```

Available packages: `zsh ssh neovim yazi lazygit topgrade termux`. Use `--no-folding` when stowing so runtime files remain local. Unstowing SSH preserves the real configuration and keys; unstowing Yazi preserves its copied manifest and downloaded plugins. To customize tracked configuration without changing the checkout, unstow its package and copy the required files locally.

## Verification

`python3 termux/tests/bootstrap.py` exercises bootstrap reruns, conflicts, and SSH preservation using real Stow and SSH tools with mocked Termux package/application commands. Requires Bash, Zsh, Git, GNU Stow, and OpenSSH. Application startup and the Android keyboard still need a device smoke test.
