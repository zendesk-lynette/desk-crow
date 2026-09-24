import AppKit

@main
enum DeskCrowMain {
  static func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private var panel: CrowPanel?
  private var statusItem: NSStatusItem?
  private var menu: NSMenu?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let size = NSSize(width: 200, height: 240)
    let panel = CrowPanel(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.becomesKeyOnlyIfNeeded = true
    panel.isMovableByWindowBackground = true

    let crow = CrowView(frame: NSRect(origin: .zero, size: size))
    crow.onBreakAcknowledged = { [weak self] in
      BreakReminder.shared.tookBreak()
      self?.refreshStatusTitle()
    }
    panel.contentView = crow

    if let screen = NSScreen.main {
      let frame = screen.visibleFrame
      panel.setFrameOrigin(NSPoint(x: frame.maxX - 230, y: frame.minY + 40))
    }

    panel.orderFrontRegardless()
    self.panel = panel
    installStatusItem()
    wireBreakReminder(to: crow)
    BreakReminder.shared.start()
    refreshStatusTitle()
  }

  private func wireBreakReminder(to crow: CrowView) {
    let reminder = BreakReminder.shared
    reminder.onNudge = { [weak self, weak crow] in
      crow?.showBreakNudge()
      self?.refreshStatusTitle()
      self?.panel?.orderFrontRegardless()
    }
    reminder.onCleared = { [weak self, weak crow] in
      crow?.clearBreakNudge()
      self?.refreshStatusTitle()
    }
    reminder.onScheduleChanged = { [weak self] in
      self?.refreshStatusTitle()
    }
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = item.button {
      button.title = "Karasu"
      button.toolTip = "Karasu — desk crow break buddy"
    }
    let menu = NSMenu()
    menu.delegate = self
    item.menu = menu
    self.menu = menu
    statusItem = item
    rebuildMenu()
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    rebuildMenu()
  }

  private func rebuildMenu() {
    guard let menu else { return }
    menu.removeAllItems()
    let reminder = BreakReminder.shared

    menu.addItem(item("Pet Karasu", action: #selector(petCrow), key: "p"))
    menu.addItem(item("Nudge now (test)", action: #selector(nudgeNow), key: ""))
    menu.addItem(.separator())

    if reminder.isNudgeActive {
      menu.addItem(item("Took a break", action: #selector(tookBreak), key: "b"))
      menu.addItem(item("Snooze 5 minutes", action: #selector(snoozeFive), key: "s"))
      menu.addItem(.separator())
    }

    let enabled = NSMenuItem(
      title: reminder.isEnabled ? "Break reminders: On" : "Break reminders: Off",
      action: #selector(toggleReminders),
      keyEquivalent: ""
    )
    enabled.target = self
    enabled.state = reminder.isEnabled ? .on : .off
    menu.addItem(enabled)

    let intervalRoot = NSMenuItem(title: "Remind every…", action: nil, keyEquivalent: "")
    let intervalMenu = NSMenu()
    for minutes in [25, 45, 50, 60, 90] {
      let label = minutes == 25 ? "25 min (focus sprint)" : "\(minutes) min"
      let choice = NSMenuItem(title: label, action: #selector(setInterval(_:)), keyEquivalent: "")
      choice.target = self
      choice.tag = minutes
      choice.state = reminder.intervalMinutes == minutes ? .on : .off
      intervalMenu.addItem(choice)
    }
    intervalRoot.submenu = intervalMenu
    menu.addItem(intervalRoot)

    if reminder.isEnabled, let mins = reminder.minutesUntilBreak, !reminder.isNudgeActive {
      let next = NSMenuItem(
        title: "Next nudge in ~\(mins) min",
        action: nil,
        keyEquivalent: ""
      )
      next.isEnabled = false
      menu.addItem(next)
    } else if reminder.isNudgeActive {
      let active = NSMenuItem(title: "Nudge active — stretch a little", action: nil, keyEquivalent: "")
      active.isEnabled = false
      menu.addItem(active)
    }

    menu.addItem(.separator())
    menu.addItem(item("Quit Karasu", action: #selector(quitApp), key: "q"))
  }

  private func item(_ title: String, action: Selector, key: String) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
    item.target = self
    return item
  }

  private func refreshStatusTitle() {
    let reminder = BreakReminder.shared
    if reminder.isNudgeActive {
      statusItem?.button?.title = "Karasu · break"
    } else if reminder.isEnabled, let mins = reminder.minutesUntilBreak {
      statusItem?.button?.title = mins <= 5 ? "Karasu · \(mins)m" : "Karasu"
    } else {
      statusItem?.button?.title = "Karasu"
    }
  }

  private var crowView: CrowView? {
    panel?.contentView as? CrowView
  }

  @objc private func petCrow() {
    crowView?.petFromMenu()
  }

  @objc private func nudgeNow() {
    BreakReminder.shared.testNudgeNow()
    panel?.orderFrontRegardless()
  }

  @objc private func toggleReminders() {
    BreakReminder.shared.isEnabled.toggle()
  }

  @objc private func setInterval(_ sender: NSMenuItem) {
    BreakReminder.shared.intervalMinutes = sender.tag
  }

  @objc private func tookBreak() {
    BreakReminder.shared.tookBreak()
    crowView?.celebrateBreakTaken()
  }

  @objc private func snoozeFive() {
    BreakReminder.shared.snooze(minutes: 5)
    crowView?.clearBreakNudge()
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}

final class CrowPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}
