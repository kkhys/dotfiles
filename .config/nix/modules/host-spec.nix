{ config, lib, ... }:

{
  options.hostSpec = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "Hostname";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "Username";
    };

    isWork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is a work machine";
    };
  };

  # System identity derives from hostSpec the same way on every host, so it is
  # wired once here; hosts only declare their hostSpec values.
  config = {
    networking.hostName = config.hostSpec.hostName;
    system.primaryUser = config.hostSpec.username;

    users.users.${config.hostSpec.username} = {
      name = config.hostSpec.username;
      home = "/Users/${config.hostSpec.username}";
    };
  };
}
