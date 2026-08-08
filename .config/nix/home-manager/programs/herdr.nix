{ pkgs, ... }:

{
  programs.herdr = {
    enable = true;
    package = pkgs.herdr;

    settings = {
      # Configuration is declarative, so skip the first-run setup prompt
      onboarding = false;

      # Matches the Ghostty theme (Catppuccin Mocha)
      theme.name = "catppuccin";

      # The binary is pinned by nix, so the background version check is dead
      # weight. `update.manifest_check` stays on: it refreshes agent-detection
      # rules, which is data rather than a new binary.
      update.version_check = false;

      keys = {
        prefix = "ctrl+b";

        # Jump straight to the nth agent row. This is what makes
        # `ui.agent_panel_sort = "priority"` actionable: the agent that needs
        # attention is at index 1
        focus_agent = "prefix+alt+1..9";

        # Sequential counterpart to the jump above, keeping `alt` as the agent
        # namespace. Order follows `agent_panel_sort`, so this walks the priority
        # list without having to read indices off the sidebar
        previous_agent = "prefix+alt+k";
        next_agent = "prefix+alt+j";

        # Same idea one level up, mirroring the default `switch_tab`
        switch_workspace = "prefix+shift+1..9";

        # Arrows match the vertical workspace list in the sidebar; the vim keys
        # one would otherwise reach for are taken by `swap_pane_*`
        previous_workspace = "prefix+up";
        next_workspace = "prefix+down";

        # Toggle back to the previously focused pane. `prefix+tab`, which the
        # upstream comment suggests, is already `cycle_pane_next`
        last_pane = "prefix+a";

        # Both worktree actions are unset by default. Group them under the `g` of
        # `new_worktree`, except for removal: `alt+shift+g` is awkward to reach
        # and `shift+d` is `close_workspace`, so it borrows the delete mnemonic.
        # Destructive, but herdr opens a confirmation first
        open_worktree = "prefix+alt+g";
        remove_worktree = "prefix+alt+d";
      };

      ui = {
        # Surface agents that need attention first, rather than grouping by space
        agent_panel_sort = "priority";

        # Label split panes with the detected agent, so a workspace running
        # several agents side by side is readable without the sidebar
        show_agent_labels_on_pane_borders = true;

        # Emit OSC 9/777 and let Ghostty raise the macOS notification, so it is
        # attributed to Ghostty and clicking it returns here
        toast.delivery = "terminal";

        # The macOS notification above already carries a sound; herdr's own
        # chime would double it
        sound.enabled = false;

        # `copy_on_select` fires on every drag and double-click, so confirming
        # each one with a toast is noise
        toast.clipboard.enabled = false;

        # Show what Claude is currently doing, taken from the reported pane title
        sidebar.agents.rows_by_agent.claude = [
          [
            "state_icon"
            "workspace"
            "tab"
          ]
          [ "terminal_title_stripped" ]
          [ "agent" ]
        ];
      };

      experimental = {
        # Prefix mode swaps the macOS input source to an ASCII layout, so
        # ctrl+b commands register while the Japanese IME is active
        switch_ascii_input_source_in_prefix = true;

        # Claude Code paints its own cursor and hides the terminal one, which
        # detaches the IME candidate window. Re-expose the cursor to Ghostty so
        # the candidate window tracks it, limited to claude because the
        # trade-off is a stray cursor in apps that hide it deliberately (vim)
        reveal_hidden_cursor_for_cjk_ime = true;
        cjk_ime_agents = [ "claude" ];

        # Keep pane scrollback across server restarts. Ghostty now launches
        # herdr directly, so a restart would otherwise wipe every pane's history
        pane_history = true;
      };
    };
  };
}
