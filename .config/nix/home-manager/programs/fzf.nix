{ ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];

    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };
}
