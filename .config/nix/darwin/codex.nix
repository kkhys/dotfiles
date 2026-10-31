{ ... }:

# Codex config layers, highest precedence first:
#
#   /etc/codex/managed_config.toml   (MDM, unused here)
#   CLI -c overrides
#   <project>/.codex/config.toml
#   ~/.codex/<profile>.config.toml
#   ~/.codex/config.toml             rewritten by Codex at runtime
#   /etc/codex/config.toml           managed here

{
  environment.etc."codex/config.toml".source = ../../codex/config.toml;
}
