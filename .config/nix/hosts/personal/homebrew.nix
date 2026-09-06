{ ... }:

{
  homebrew = {
    casks = [
      "adobe-creative-cloud"
      # Ships its own docker CLI, compose and buildx. The work host cannot run
      # Docker Desktop and pairs the brew CLI with colima instead.
      "docker-desktop"
    ];
  };
}
