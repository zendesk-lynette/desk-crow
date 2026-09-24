import AppKit
import Foundation

@MainActor
final class BreakReminder {
  static let shared = BreakReminder()

  private enum Keys {
    static let enabled = "karasu.breakRemindersEnabled"
    static let intervalMinutes = "karasu.breakIntervalMinutes"
  }

  private var timer: Timer?
  private var fireDate: Date?
  private(set) var isNudgeActive = false

  var onNudge: (() -> Void)?
  var onCleared: (() -> Void)?
  var onScheduleChanged: (() -> Void)?

  var isEnabled: Bool {
    get {
      if UserDefaults.standard.object(forKey: Keys.enabled) == nil { return true }
      return UserDefaults.standard.bool(forKey: Keys.enabled)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.enabled)
      if newValue {
        restart()
      } else {
        clearNudge()
        stop()
      }
      onScheduleChanged?()
    }
  }

  var intervalMinutes: Int {
    get {
      let stored = UserDefaults.standard.integer(forKey: Keys.intervalMinutes)
      return stored > 0 ? stored : 45
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.intervalMinutes)
      if isEnabled { restart() }
      onScheduleChanged?()
    }
  }

  var minutesUntilBreak: Int? {
    guard isEnabled, let fireDate else { return nil }
    let seconds = max(0, fireDate.timeIntervalSinceNow)
    return Int(ceil(seconds / 60))
  }

  func start() {
    guard isEnabled else { return }
    restart()
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    fireDate = nil
  }

  func restart() {
    stop()
    clearNudge(notify: false)
    guard isEnabled else {
      onScheduleChanged?()
      return
    }
    let seconds = TimeInterval(intervalMinutes * 60)
    fireDate = Date().addingTimeInterval(seconds)
    timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
      Task { @MainActor in
        self?.fire()
      }
    }
    onScheduleChanged?()
  }

  func snooze(minutes: Int) {
    stop()
    clearNudge(notify: false)
    guard isEnabled else { return }
    let seconds = TimeInterval(minutes * 60)
    fireDate = Date().addingTimeInterval(seconds)
    timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
      Task { @MainActor in
        self?.fire()
      }
    }
    isNudgeActive = false
    onCleared?()
    onScheduleChanged?()
  }

  func tookBreak() {
    clearNudge()
    restart()
  }

  func testNudgeNow() {
    stop()
    fire()
  }

  private func fire() {
    isNudgeActive = true
    fireDate = nil
    timer = nil
    onNudge?()
    onScheduleChanged?()
  }

  private func clearNudge(notify: Bool = true) {
    let wasActive = isNudgeActive
    isNudgeActive = false
    if notify, wasActive {
      onCleared?()
    }
  }
}
