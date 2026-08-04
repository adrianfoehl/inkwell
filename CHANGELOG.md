# Changelog

## 0.2.0

**Writing**

- New File opens an empty document immediately. Where it goes on disk is decided
  on the first save, which proposes a name from the first heading or line.
- The save panel is a sheet on its window instead of an application-modal panel
  that froze every other window.
- A Save button sits in the toolbar whenever there is something to save, and the
  status bar names the shortcut for an unsaved document.
- Pasted console output loses its quote gutter (`  ▎ `) and the terminal's hard
  wrapping, so it can go straight into an email. Deliberate line breaks survive,
  and text without a gutter is pasted untouched.

**Files**

- Files changed by another program are picked up. With no unsaved edits the new
  version loads by itself; otherwise a banner offers the choice. Cmd+R reloads on
  demand.

**Fixes**

- Menu commands acted on every open window at once: opening a file replaced the
  contents of all of them, Cmd+S saved every document, and formatting ran once per
  window, so with two windows Cmd+B set bold and immediately removed it again.
- Cmd+N belonged to New Window while the toolbar advertised it for New File.
  New File takes Cmd+N, New Window moves to Shift+Cmd+N.
- Toolbar buttons no longer appear and disappear, which used to shift every other
  button out from under the pointer.
- The Save icon was macOS's download symbol.
- `Info.plist` is part of the repository and installed by `build.sh`. It only
  existed on the author's machine, so a fresh clone built an app without an icon,
  a bundle identifier or the `.md` file association.

## 0.1

Initial release: WYSIWYG markdown editing, drag & drop, folder sidebar, outline
panel, format bar and menu, status bar, front matter banner, dark mode, optional
Apple Intelligence formatting, source mode.
