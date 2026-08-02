{ ... }:

# Codex reads config from several layers. Precedence, highest first:
#
#   /etc/codex/managed_config.toml   (MDM / enterprise, unused here)
#   CLI -c overrides
#   <project>/.codex/config.toml
#   ~/.codex/<profile>.config.toml
#   ~/.codex/config.toml             <- Codex writes here at runtime
#   /etc/codex/config.toml           <- managed declaratively below
#
# ~/.codex/config.toml cannot be a symlink into this repo: Codex rewrites it in
# place to record project trust levels, feature toggles and TUI state. Shipping
# the managed settings through the system layer instead keeps them declarative
# and re-applied on every `darwin-rebuild switch`, while leaving the user layer
# free for Codex's own runtime state.

{
  environment.etc."codex/config.toml".source = ../../codex/config.toml;
}
