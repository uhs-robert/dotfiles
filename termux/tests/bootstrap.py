#!/usr/bin/env python3
"""Bootstrap regression tests: real Stow/OpenSSH, mocked Android-only commands."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parents[1]
REAL_GIT = shutil.which('git')
REAL_KEYGEN = shutil.which('ssh-keygen')


def run(args, env, success=True):
    result = subprocess.run(args, env=env, text=True, capture_output=True)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result


def executable(path, body):
    path.write_text('#!/usr/bin/env bash\nset -e\n' + body)
    path.chmod(0o755)


with tempfile.TemporaryDirectory(prefix='termux test ') as temporary:
    root = Path(temporary)
    checkout = root / 'checkout' / 'termux'
    shutil.copytree(SOURCE, checkout)
    prefix = root / 'prefix'
    bins = prefix / 'bin'
    bins.mkdir(parents=True)
    for name in ('pkg', 'chsh', 'termux-reload-settings', 'ya', 'nvim'):
        executable(bins / name, 'printf "%s\\n" "$0 $*" >> "$HOME/calls"\n')
    executable(bins / 'apt-cache', 'exit 100\n')
    executable(bins / 'git', '''if [[ $1 == clone ]]; then
    destination=${@: -1}
    origin=${@: -2:1}
    "$REAL_GIT" init -q "$destination"
    "$REAL_GIT" -C "$destination" remote add origin "$origin"
else
    exec "$REAL_GIT" "$@"
fi
''')
    executable(bins / 'ssh-keygen', '''if [[ $1 == -t ]]; then
    exec "$REAL_KEYGEN" "$@" -N '' -q
else
    exec "$REAL_KEYGEN" "$@"
fi
''')
    environment = dict(os.environ, PREFIX=str(prefix), REAL_GIT=REAL_GIT,
                       REAL_KEYGEN=REAL_KEYGEN, PATH=str(bins) + ':' + os.environ['PATH'])
    for name in ('XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CACHE_HOME'):
        environment.pop(name, None)

    def home(name):
        location = root / name
        location.mkdir()
        return location, dict(environment, HOME=str(location))

    def install(env, success=True):
        return run(['bash', str(checkout / 'install.sh')], env, success)

    fresh, env = home('fresh')
    install(env)
    key = (fresh / '.ssh/id_ed25519').read_bytes()
    config = fresh / '.ssh/config'
    config.write_text('Host personal\n    HostName example.invalid\n')
    manifest = fresh / '.config/yazi/package.toml'
    assert not manifest.is_symlink()
    manifest.write_text(manifest.read_text() + '\n# local change\n')
    install(env)
    assert (fresh / '.ssh/id_ed25519').read_bytes() == key
    assert 'personal' in config.read_text()
    assert '# local change' in manifest.read_text()
    assert (fresh / '.zshrc').is_symlink()
    assert (fresh / '.termux/heliboard/main.jsonc').exists()
    assert not (checkout / 'zsh/.local').exists()
    print('PASS: fresh bootstrap and safe rerun, paths containing spaces')

    conflict, conflict_env = home('conflict')
    (conflict / '.zshrc').write_text('keep me\n')
    install(conflict_env, success=False)
    assert (conflict / '.zshrc').read_text() == 'keep me\n'
    assert not (conflict / '.config/nvim/init.lua').exists()
    assert not (conflict / '.ssh').exists()
    print('PASS: Stow conflicts fail before deploying any package')

    existing, existing_env = home('existing key')
    (existing / '.ssh').mkdir()
    private = existing / '.ssh/custom-name'
    run([REAL_KEYGEN, '-t', 'ed25519', '-N', '', '-q', '-f', str(private)], existing_env)
    expected_public = private.with_suffix('.pub').read_text().split()[:2]
    private.with_suffix('.pub').unlink()
    original = private.read_bytes()
    result = install(existing_env)
    assert ' '.join(expected_public) in result.stdout
    assert private.read_bytes() == original
    assert not (existing / '.ssh/id_ed25519').exists()
    print('PASS: custom private key without public file is preserved and displayed')

    blocked, blocked_env = home('blocked key')
    (blocked / '.ssh').mkdir()
    (blocked / '.ssh/id_ed25519').symlink_to(blocked / 'missing')
    install(blocked_env, success=False)
    assert (blocked / '.ssh/id_ed25519').is_symlink()
    print('PASS: dangling key symlinks are never replaced')

    config.write_text('''Host first second * !excluded foo? bar[12]
    HostName never-offer-this
hOsT = third first # ignore-comment
Host "quoted"
Match host no-match
''')
    hosts = run(['zsh', '-fc', 'source "$HOME/.config/zsh/ssh-hosts.zsh"; termux_ssh_hosts'], env)
    assert hosts.stdout.splitlines() == ['first', 'quoted', 'second', 'third'], hosts.stdout
    print('PASS: host aliases are deduplicated; patterns, HostName and Match excluded')
