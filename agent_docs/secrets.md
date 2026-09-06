# Secrets (agenix)

Encrypted secrets live in `.config/nix/secrets/` and are decrypted automatically during `darwin-rebuild switch`.

## Where things are

- `.config/nix/secrets/secrets.nix` — declares the public-key recipients for each `*.age` file
- `.config/nix/secrets/*.age` — encrypted payloads (committed)
- `.config/nix/darwin/secrets.nix` — a `secrets` table declaring which secrets are decrypted and where: `dest` overrides the target path, `workOnly = true` restricts decryption to work hosts. This file is the source of truth for the current set of secrets and their target paths — read it before assuming a secret exists.
- `~/.config/age/keys.txt` — the age private key. Never committed; restore from password manager on a new machine.

## New machine setup

1. Restore the age private key:
   ```bash
   mkdir -p ~/.config/age
   # paste private key into ~/.config/age/keys.txt
   chmod 600 ~/.config/age/keys.txt
   ```
2. Run `sudo darwin-rebuild switch --flake .config/nix#<host>`. agenix decrypts each secret to the path declared in `darwin/secrets.nix`.

## Add a new secret

1. Add a `"<name>.age".publicKeys = allKeys;` entry in `.config/nix/secrets/secrets.nix`
2. Encrypt the plaintext:
   ```bash
   nix-shell -p age --run "age -r <age-public-key> -o .config/nix/secrets/<name>.age /path/to/plaintext"
   ```
3. Add `<name>` to the `secrets` table in `.config/nix/darwin/secrets.nix`: `{ }` decrypts to `~/.config/secrets/<name>`, `dest` puts it elsewhere, `workOnly = true` limits it to work hosts.
4. If the secret is loaded as an env var, wire it up in `.config/nix/home-manager/programs/zsh.nix` (see the `NPM_TOKEN` block as an example).
5. `git add .config/nix/secrets/<name>.age` and apply.

## Re-encrypt to a new key

```bash
cd .config/nix
nix-shell -p age --run "age -d -i ~/.config/age/keys.txt secrets/<name>.age | age -r <new-public-key> -o secrets/<name>.age.new"
mv secrets/<name>.age.new secrets/<name>.age
```

Repeat for every `*.age` file when rotating recipients, then update `secrets/secrets.nix` accordingly.
