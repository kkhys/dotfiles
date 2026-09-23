{ ... }:

{
  homebrew = {
    brews = [
      "docker"
      "docker-compose"
      "docker-buildx"
      "datadog-labs/pack/pup"
    ];

    casks = [
      "blackhole-2ch"
      "cursor"
      "devin-cli"
      "grok-bot"
      "microsoft-edge"
      "openvpn-connect"
      # "ovice"
      "slack"
      # "zoom"
    ];
  };
}
