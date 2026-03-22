# Inkwell

A lightweight markdown editor for macOS that renders your text as you type. No split view, no syntax clutter — just open a `.md` file and start reading or writing.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.2-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Why Inkwell?

If you work with AI agents, static sites, or documentation, you end up with dozens of markdown files. Reading them raw is painful, but Typora is overkill, Quick Look can't edit, and VS Code doesn't render inline. Inkwell fills the gap: open a `.md` file, see it beautifully formatted, edit it right there. No mode switching, no project setup, no clutter.

## Features

- **WYSIWYG editing** — Headings, bold, italic, code, lists rendered inline (powered by Milkdown/ProseMirror)
- **Drag & Drop** — Drop `.md` files onto the window to open
- **Folder sidebar** — Browse all markdown files in a directory
- **Outline panel** — Navigate by headings
- **Format bar** — Bold, Italic, Code, Headings, Lists with one click
- **Format menu** — Full keyboard shortcuts (Cmd+B, Cmd+I, etc.)
- **Status bar** — Word count, characters, lines, reading time, file path
- **Front matter** — YAML front matter collapsed into a toggleable banner
- **Dark mode** — Follows system appearance
- **Auto-Format with Apple Intelligence** — On-device AI formatting (macOS 26+, optional)
- **Offline** — All dependencies bundled, no internet required

## Install

### Build from source

Requires Xcode 26+ and macOS 14+.

```bash
git clone https://github.com/adrianfoehl/inkwell.git
cd inkwell
./build.sh
```

The app is installed to `/Applications/Inkwell.app`.

### Set as default for .md files

Right-click any `.md` file → Get Info → Open With → Inkwell → Change All.

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Bold | Cmd+B |
| Italic | Cmd+I |
| Inline Code | Cmd+E |
| Strikethrough | Shift+Cmd+D |
| Heading 1 | Option+Cmd+1 |
| Heading 2 | Option+Cmd+2 |
| Heading 3 | Option+Cmd+3 |
| Open File | Cmd+O |
| Save | Cmd+S |
| New File | Menu: File > New |

## Architecture

- **SwiftUI** shell (sidebar, toolbar, status bar)
- **WKWebView** with [Milkdown](https://milkdown.dev/) (ProseMirror-based WYSIWYG editor)
- **Apple Foundation Models** for on-device AI formatting (optional, macOS 26+)
- JS dependencies bundled via esbuild — no CDN, no network required

```
Sources/Inkwell/
  InkwellApp.swift       — App entry point, menu commands
  ContentView.swift      — Main layout, sidebar, toolbar, format bar
  InkEditorView.swift    — WKWebView wrapper with Swift/JS bridge
  AIFormatter.swift      — Apple Intelligence integration (optional)
  Resources/
    editor.html          — Milkdown editor UI
    milkdown.bundle.js   — Bundled Milkdown + ProseMirror (434KB)
```

## Rebuilding the JS bundle

Only needed if you want to update Milkdown:

```bash
cd editor-bundle
npm install
npx esbuild entry.js --bundle --format=iife --outfile=milkdown.bundle.js --minify
cp milkdown.bundle.js ../Sources/Inkwell/Resources/
```

## Built with AI

This project was built in a single session using [Claude Code](https://claude.ai/code) (Claude Opus 4.6) — from brainstorm to shipped app. Architecture decisions, code, icon, and this README were created collaboratively with AI.

## License

MIT
