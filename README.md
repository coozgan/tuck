# Tuck

A tiny macOS menu bar manager. Tuck hides the menu bar items you don't need
and puts them back with a click or `⌥⌘B`.

Inspired by [Ice](https://github.com/jordanbaird/Ice) — Tuck is a from-scratch,
minimal take: one binary, no dependencies, ~600 lines of Swift.

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

**Left click** the control to toggle. **Right click** it for the menu:
toggle, *Settings…*, quit.

The control always stays visible — it sits to the right of the divider, so it
never hides itself.

## Settings

Right click the control -> *Settings…*

- **Shortcut** — click the recorder, press any combination. `⌥⌘B` by default,
  `esc` to cancel. Needs at least one modifier beyond shift.
- **Icon style** — Chevron, Eye, or Circle.
- **Show divider handle** — hide the `|` handle for a cleaner bar; it reappears
  automatically while items are hidden so you can always drag it back.
- **Launch at login**

## Troubleshooting

**Icons don't appear.** macOS remembers per-item visibility and will silently
drop a new status item when the menu bar is full — very common on notched
MacBooks. Reset Tuck's saved state:

```sh
defaults delete app.tuck.Tuck
killall Tuck; make run
```

**Icons in the wrong order** (control being swallowed when hiding). Tuck seeds
its position once and then respects your `⌘`-drags. To re-seed:

```sh
defaults delete app.tuck.Tuck
killall Tuck; make run
```

**Run the logic self-check:**

```sh
swift run Tuck --self-check
```

## How it works

macOS gives no public API to hide another app's status item. Tuck uses the
same trick every menu bar manager uses: it owns a divider status item and
expands its width to 10,000pt, pushing everything to its left off the edge of
the screen. No private API, no Accessibility permission, no injected code.

Ordering matters: macOS creates new status items at the *left* end of the
status area, which would put the control left of the divider — where the
divider swallows it on the first toggle. Tuck seeds `NSStatusItem Preferred
Position` (distance from the right edge, lower is further right) once per item,
then leaves it alone so your own `⌘`-drags stick.

Global hotkeys use Carbon's `RegisterEventHotKey` rather than
`NSEvent.addGlobalMonitorForEvents`, because the latter silently requires
Accessibility permission.

## Roadmap

- [x] Hide/show with divider + global hotkey
- [x] Launch at login
- [x] Settings window (custom hotkey, icon style)
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
