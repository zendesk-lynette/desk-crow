# Karasu

A floating desk crow for macOS that gently nudges you to take breaks.

Karasu sits on your desktop, hops and blinks, and lives in the menu bar. When it’s time to stretch, it nudges you — pet it or mark that you took a break, and it settles again.

## Requirements

- macOS 14+
- Swift 5.9+ (Xcode or Command Line Tools)

## Run

```bash
swift run
```

Karasu appears as a borderless floating window (default: bottom-right) and a **Karasu** menu bar item.

## Features

- Pet the crow (click or **Pet Karasu** in the menu)
- Break reminders (default every 45 minutes; 25 / 45 / 50 / 60 / 90)
- When nudged: acknowledge with a click, **Took a break**, or **Snooze 5 minutes**
- **Nudge now (test)** to preview the break animation

## Menu bar

| Action | What it does |
|--------|----------------|
| Pet Karasu | Happy hop + hearts |
| Nudge now (test) | Trigger a break nudge |
| Break reminders | On / Off |
| Remind every… | Pick an interval |
| Quit Karasu | Exit |

## License

MIT
