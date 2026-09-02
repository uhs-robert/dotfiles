// Persistent mode/count/status indicator in the mail window's status bar,
// and the insert-mode tracking that follows focus in and out of text fields.
(function (tk) {
  "use strict";

  const MODE_LABELS = {
    normal: "-- NORMAL --",
    visual: "-- VISUAL --",
    insert: "-- INSERT --",
  };

  /**
   * @returns {Element} the injected mode/count indicator, or null where the mail status bar is absent (e.g. compose windows)
   */
  tk.ensure_mode_indicator = () => {
    const doc = window.document;
    const host =
      doc?.getElementById("statusTextBox") ?? doc?.getElementById("status-bar");
    if (!host) return null;
    let el = doc.getElementById("tbkeys-mode-indicator");
    if (el) return el;
    el = doc.createXULElement
      ? doc.createXULElement("label")
      : doc.createElement("label");
    el.id = "tbkeys-mode-indicator";
    el.className = "statusbarpanel";
    el.setAttribute("crop", "end");
    host.insertBefore(el, host.firstChild);
    return el;
  };

  // Known gap: the pending chord (e.g. "m" awaiting "r") is not shown - it
  // lives inside Mousetrap's internal buffer and isn't exposed to us.
  /**
   * Repaints the mode/count indicator from window.vim and window.count; a no-op where the status bar is absent.
   */
  tk.repaint_mode = () => {
    const el = tk.ensure_mode_indicator();
    if (!el) return;
    const parts = [MODE_LABELS[window.vim] ?? MODE_LABELS.normal];
    if (tk.has_count()) parts.push(String(window.count));
    if (tk.folder_search_active) {
      const matches = window.folderSearchMatches || [];
      const pos = matches.length ? (window.folderSearchIndex ?? 0) + 1 : 0;
      parts.push(`/${tk.search_term} [${pos}/${matches.length}]`);
    }
    const text = parts.join(" ");
    if (el.namespaceURI?.includes("there.is.only.xul")) {
      el.setAttribute("value", text);
    } else {
      el.textContent = text;
    }
  };

  // -- insert mode ----------------------------------------------------------

  tk.mode_before_insert = null;

  /**
   * @returns {boolean} true when focus sits in a field that takes typed text, in either the chrome window or the 3-pane document
   */
  tk.is_text_focus = () =>
    !!(
      tk.is_text_input?.(window.document?.activeElement) ||
      tk.is_text_input?.(tk.get_inbox_doc()?.activeElement)
    );

  /**
   * Enters insert mode while a text field holds focus and returns to the mode that was current before it, so a visual selection survives a trip through the filter box.
   */
  tk.sync_insert_mode = () => {
    const in_text = tk.is_text_focus();
    if (in_text) {
      if (window.vim === "insert") return;
      tk.mode_before_insert = window.vim ?? "normal";
      window.vim = "insert";
    } else {
      if (window.vim !== "insert") return;
      window.vim = tk.mode_before_insert ?? "normal";
      tk.mode_before_insert = null;
    }
    tk.repaint_mode();
  };

  // focusout fires before activeElement moves, so recheck on the next tick.
  tk.focus_handler = (e) =>
    e.type === "focusout"
      ? window.setTimeout(tk.sync_insert_mode, 0)
      : tk.sync_insert_mode();

  window.addEventListener("focusin", tk.focus_handler, { capture: true });
  window.addEventListener("focusout", tk.focus_handler, { capture: true });

  tk.ui_teardown = () => {
    window.removeEventListener("focusin", tk.focus_handler, { capture: true });
    window.removeEventListener("focusout", tk.focus_handler, { capture: true });
  };
})(window.tk);
