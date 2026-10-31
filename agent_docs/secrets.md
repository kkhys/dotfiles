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

The `agenix` CLI is installed system-wide (`darwin/secrets.nix`). It reads the recipients from `secrets.nix` in the current directory, so run it from `.config/nix/secrets/`. `-i` points it at the age key; without it, agenix only tries the default `~/.ssh` identities.

## Add a new secret

1. Add a `"<name>.age".publicKeys = allKeys;` entry in `.config/nix/secrets/secrets.nix`
2. Encrypt the plaintext (opens `$EDITOR`; paste the plaintext and save):
   ```bash
   cd .config/nix/secrets && agenix -e <name>.age -i ~/.config/age/keys.txt
   ```
3. Add `<name>` to the `secrets` table in `.config/nix/darwin/secrets.nix`: `{ }` decrypts to `~/.config/secrets/<name>`, `dest` puts it elsewhere, `workOnly = true` limits it to work hosts.
4. If the secret is loaded as an env var, add it to the `secretEnvVars` table in `.config/nix/home-manager/programs/zsh.nix`.
5. `git add .config/nix/secrets/<name>.age` and apply.

## Re-encrypt to a new key

Update the recipients in `secrets/secrets.nix`, then rekey every `*.age` file in one go:

```bash
cd .config/nix/secrets && agenix -r -i ~/.config/age/keys.txt
```
