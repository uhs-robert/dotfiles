# dotfiles/justfile

default:
    @just --list

# Show pending changes between system/ and / (dry run, no sudo)
system-diff:
    rsync -av --dry-run system/ /

# Copy system/ into / for real, e.g. /etc, /usr/local/bin (needs sudo)
system-apply:
    sudo rsync -av system/ /

# Symlink one package from home/ into ~
stow name:
    stow -d home -t ~ {{name}}

# Remove symlinks for one package from ~
unstow name:
    stow -d home -t ~ -D {{name}}

# Re-stow one package (fix stale/broken links)
restow name:
    stow -d home -t ~ -R {{name}}

# Symlink every package in home/ into ~
stow-all:
    stow -d home -t ~ $(ls home)

# Remove symlinks for every package in home/
unstow-all:
    stow -d home -t ~ -D $(ls home)

# Symlink just the CORE packages from packages/stow.ini
stow-core:
    stow -d home -t ~ $(awk '/^\[CORE\]/{f=1;next} /^\[/{f=0} f && /^[^#[:space:]]/' packages/stow.ini)

# Symlink just the OPTIONAL packages from packages/stow.ini
stow-optional:
    stow -d home -t ~ $(awk '/^\[OPTIONAL\]/{f=1;next} /^\[/{f=0} f && /^[^#[:space:]]/' packages/stow.ini)

# Run full dotfiles install (packages, stow, services); pass flags like --minimal
install *ARGS:
    ./install.sh {{ARGS}}

# Run uninstall script; pass through any flags
uninstall *ARGS:
    ./uninstall.sh {{ARGS}}

# Shellcheck install.sh, uninstall.sh, and lib/*.sh
lint:
    shellcheck install.sh uninstall.sh lib/*.sh

# Validate formatting, package manifests, and whitespace; run optional tooling when available
check:
    if command -v shellcheck >/dev/null 2>&1; then shellcheck install.sh uninstall.sh lib/*.sh; else echo 'skip: shellcheck not installed'; fi
    if command -v shfmt >/dev/null 2>&1; then shfmt -i 2 -d install.sh uninstall.sh lib/*.sh; else echo 'skip: shfmt not installed'; fi
    if command -v stylua >/dev/null 2>&1; then stylua --respect-ignores --check home/hypr/.config/hypr; else echo 'skip: stylua not installed'; fi
    sh ./lib/check-packages.sh
    git diff --check
