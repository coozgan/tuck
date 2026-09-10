# Tuck

A tiny macOS menu bar manager. Tuck hides the menu bar items you don't need
and puts them back with a click or `⌥⌘B`.

Inspired by [Ice](https://github.com/jordanbaird/Ice) — Tuck is a from-scratch,
minimal take: one binary, no dependencies, ~250 lines of Swift.

> Requires macOS 13+. Apple Silicon or Intel.

## Build

```sh
make run       # build + launch
make install   # copy to /Applications
```

No Xcode project — SwiftPM plus a Makefile that assembles the `.app` bundle
and ad-hoc signs it.

## Use

1. Two icons appear in your menu bar: a **divider** (`|`) and the **Tuck control** (`‹›`).
2. `⌘`-drag the divider so that every item you want hidden sits to its **left**.
   *Hold `⌘` down first, then press and drag* — clicking before holding `⌘` just
   toggles the item. Control Center and the clock can't be moved by any app.
3. Click the control (or press `⌥⌘B`) to collapse everything left of the divider.
4. Click again to bring them back.

Right-click the control for the menu: toggle, *Launch at Login*, quit.

## Troubleshooting

**Icons don't appear.** macOS remembers per-item visibility and will silently
drop a new status item when the menu bar is full — very common on notched
MacBooks. Reset Tuck's saved state:

```sh
defaults delete app.tuck.Tuck
killall Tuck; make run
```

**See what the app thinks is happening:**

```sh
TUCK_DEBUG=1 ./.build/release/Tuck
```

## How it works

macOS gives no public API to hide another app's status item. Tuck uses the
same trick every menu bar manager uses: it owns a status item and expands its
width to 10,000pt, pushing everything to its left off the edge of the screen.
No private API, no Accessibility permission, no injected code.

## Roadmap

- [x] Hide/show with divider + global hotkey
- [x] Launch at login
- [ ] Settings window (custom hotkey, divider style)
- [ ] "Always hidden" second section
- [ ] Auto-rehide on a timer
- [ ] Show on hover / scroll
- [ ] Menu bar item search

## Renaming

The brand is one string. To rebrand:

```sh
grep -rl Tuck . | xargs sed -i '' 's/Tuck/YourName/g'
git mv Sources/Tuck Sources/YourName
```

## License

MIT.
