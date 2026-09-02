// Message mutations: read/unread/flag/junk/delete/archive/move, and
// repeat-last-action via tk.record_action / tk.last_action from core.js.
(function (tk) {
  "use strict";

  // -- flat tk_* functions for keys.json "func:" bindings ------------------

  window.tk_mark_all_read = () => {
    const tt = tk.get_thread_tree();
    const hdr = tk.get_current_hdr(tt);
    tk.toggle_read_state(hdr);
    window.goDoCommand("cmd_markAllRead");
  };
  // The read-state nudge is a single-row habit carried over from the original
  // inline bindings; over a range it would rewrite every selected message.
  const mark_over_range = (cmd) => () => {
    const tt = tk.get_thread_tree();
    const range = tk.resolve_action_range(tt);
    if (range.is_visual) {
      window.goDoCommand(cmd);
      tk.finish_visual_action(tt, range.cursor_index);
      return;
    }
    tk.toggle_read_state(range.anchor_hdr);
    tk.repeat_command(cmd, range.count);
  };

  const act_over_range = (cmd) => () => {
    const tt = tk.get_thread_tree();
    const range = tk.resolve_action_range(tt);
    if (range.is_visual) {
      window.goDoCommand(cmd);
      tk.finish_visual_action(tt, range.top_index);
      return;
    }
    tk.repeat_command(cmd, range.count);
  };

  window.tk_mark_read = mark_over_range("cmd_markAsRead");
  window.tk_mark_unread = mark_over_range("cmd_markAsUnread");
  window.tk_mark_flagged = mark_over_range("cmd_markAsFlagged");
  window.tk_delete = act_over_range("cmd_delete");
  window.tk_archive = act_over_range("cmd_archive");

  window.tk_mark_junk_toggle = () => {
    const tt = tk.get_thread_tree();
    const range = tk.resolve_action_range(tt);
    if (!range.anchor_hdr) {
      if (range.is_visual) tk.finish_visual_action(tt, range.cursor_index);
      return;
    }
    const is_junk = range.anchor_hdr.getStringProperty("junkscore") === "100";
    if (!range.is_visual) tk.toggle_read_state(range.anchor_hdr);
    window.goDoCommand(is_junk ? "cmd_markAsNotJunk" : "cmd_markAsJunk");
    if (range.is_visual) tk.finish_visual_action(tt, range.cursor_index);
  };
  window.tk_move_to_projects = () => {
    const tt = tk.get_thread_tree();
    if (!tt) return;
    const range = tk.resolve_action_range(tt);
    const folder = tk.find_folder_by_name(tk.PROJECTS_FOLDER);
    if (!folder) {
      if (range.is_visual) tk.finish_visual_action(tt, range.cursor_index);
      return;
    }
    if (!range.is_visual) tk.toggle_read_state(range.anchor_hdr);
    tt.view?.doCommandWithFolder?.(
      window.Ci.nsMsgViewCommandType.moveMessages,
      folder,
    );
    if (range.is_visual) tk.finish_visual_action(tt, range.top_index);
  };

  window.tk_repeat_last = () => {
    const last = tk.last_action;
    if (!last || typeof window[last.name] !== "function") {
      tk.reset_count();
      return;
    }
    if (!tk.has_count()) window.count = last.count;
    window[last.name]();
  };

  [
    "tk_delete",
    "tk_archive",
    "tk_mark_read",
    "tk_mark_unread",
    "tk_mark_flagged",
  ].forEach(tk.record_action);
})(window.tk);
