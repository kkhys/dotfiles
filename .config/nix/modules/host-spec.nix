{ lib, ... }:

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
}
