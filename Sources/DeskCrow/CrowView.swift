import AppKit

@MainActor
final class CrowView: NSView {
  var onBreakAcknowledged: (() -> Void)?

  private var blinkClosed = false
  private var hopLift: CGFloat = 0
  private var tiltDegrees: CGFloat = 0
  private var wingUp = false
  private var happy = false
  private var breakNudge = false
  private var nudgePulse = false
  private var bubbleText = "Break time?"
  private var hearts: [(x: CGFloat, y: CGFloat, life: CGFloat, size: CGFloat)] = []

  private var blinkTimer: Timer?
  private var hopTimer: Timer?
  private var tiltTimer: Timer?
  private var wingTimer: Timer?
  private var displayLink: Timer?
  private var nudgeTimer: Timer?

  override var isFlipped: Bool { false }
  override var acceptsFirstResponder: Bool { true }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    toolTip = "Karasu — click to pet (or acknowledge a break)"
    startLoops()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    blinkTimer?.invalidate()
    hopTimer?.invalidate()
    tiltTimer?.invalidate()
    wingTimer?.invalidate()
    displayLink?.invalidate()
    nudgeTimer?.invalidate()
  }

  private func startLoops() {
    scheduleBlink()
    scheduleHop()
    scheduleTilt()
    scheduleWing()
    displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.tickHearts()
      }
    }
  }

  private func scheduleBlink() {
    let delay = TimeInterval.random(in: 2.4...4.2)
    blinkTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.blinkClosed = true
        self.needsDisplay = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
          self.blinkClosed = false
          self.needsDisplay = true
          self.scheduleBlink()
        }
      }
    }
  }

  private func scheduleHop() {
    let delay = breakNudge
      ? TimeInterval.random(in: 1.2...2.2)
      : TimeInterval.random(in: 5.0...9.0)
    hopTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      Task { @MainActor in
        guard let self, !self.happy else {
          self?.scheduleHop()
          return
        }
        self.animateHop()
        self.scheduleHop()
      }
    }
  }

  private func scheduleTilt() {
    let delay = TimeInterval.random(in: 3.5...6.5)
    tiltTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      Task { @MainActor in
        guard let self, !self.happy else {
          self?.scheduleTilt()
          return
        }
        self.tiltDegrees = CGFloat.random(in: -6...6)
        self.needsDisplay = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
          self.tiltDegrees = 0
          self.needsDisplay = true
          self.scheduleTilt()
        }
      }
    }
  }

  private func scheduleWing() {
    let delay = breakNudge
      ? TimeInterval.random(in: 0.8...1.6)
      : TimeInterval.random(in: 4.0...7.0)
    wingTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      Task { @MainActor in
        guard let self, !self.happy else {
          self?.scheduleWing()
          return
        }
        self.wingUp = true
        self.needsDisplay = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          self.wingUp = false
          self.needsDisplay = true
          self.scheduleWing()
        }
      }
    }
  }

  private func animateHop() {
    hopLift = breakNudge ? 18 : 14
    needsDisplay = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.hopLift = 0
      self.needsDisplay = true
    }
  }

  private func tickHearts() {
    guard !hearts.isEmpty else { return }
    hearts = hearts.compactMap { h in
      let life = h.life - 0.04
      guard life > 0 else { return nil }
      return (h.x, h.y - 2.2, life, h.size)
    }
    needsDisplay = true
  }

  func showBreakNudge() {
    breakNudge = true
    bubbleText = ["Break time?", "Stretch a little?", "Eyes off screen?", "Water + stretch?"].randomElement()!
    nudgePulse = true
    wingUp = true
    hopLift = 12
    needsDisplay = true
    hopTimer?.invalidate()
    wingTimer?.invalidate()
    scheduleHop()
    scheduleWing()

    nudgeTimer?.invalidate()
    nudgeTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self, self.breakNudge else { return }
        self.nudgePulse.toggle()
        self.needsDisplay = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.hopLift = 0
      self.wingUp = false
      self.needsDisplay = true
    }
  }

  func clearBreakNudge() {
    breakNudge = false
    nudgePulse = false
    nudgeTimer?.invalidate()
    nudgeTimer = nil
    needsDisplay = true
    hopTimer?.invalidate()
    wingTimer?.invalidate()
    scheduleHop()
    scheduleWing()
  }

  func celebrateBreakTaken() {
    clearBreakNudge()
    pet()
  }

  override func mouseDown(with event: NSEvent) {
    if breakNudge {
      onBreakAcknowledged?()
      celebrateBreakTaken()
    } else {
      pet()
    }
  }

  func petFromMenu() {
    pet()
  }

  private func pet() {
    happy = true
    wingUp = true
    tiltDegrees = CGFloat.random(in: -8...8)
    hopLift = 16
    hearts = [
      (-28, 110, 1, 10),
      (-12, 118, 1, 12),
      (0, 122, 1, 11),
      (14, 116, 1, 13),
      (30, 108, 1, 10),
    ]
    needsDisplay = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
      self.hopLift = 0
      self.wingUp = false
      self.needsDisplay = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
      self.happy = false
      self.tiltDegrees = 0
      self.needsDisplay = true
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.clear(bounds)

    if breakNudge {
      drawBubble(in: ctx)
    }

    ctx.saveGState()
    let center = CGPoint(x: bounds.midX, y: bounds.midY - 10 + hopLift)
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: tiltDegrees * .pi / 180)
    drawCrow(in: ctx)
    ctx.restoreGState()

    for h in hearts {
      drawHeart(
        in: ctx,
        at: CGPoint(x: bounds.midX + h.x, y: bounds.midY + h.y - 8),
        size: h.size,
        alpha: h.life
      )
    }
  }

  private func drawBubble(in ctx: CGContext) {
    let text = bubbleText as NSString
    let font = NSFont.systemFont(ofSize: 12, weight: .medium)
    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.24, alpha: 1),
    ]
    let textSize = text.size(withAttributes: attrs)
    let padding: CGFloat = 10
    let bubbleW = textSize.width + padding * 2
    let bubbleH = textSize.height + padding * 1.4
    let bubbleX = bounds.midX - bubbleW / 2
    let bubbleY = bounds.maxY - bubbleH - 8
    let rect = CGRect(x: bubbleX, y: bubbleY, width: bubbleW, height: bubbleH)

    let fill = nudgePulse
      ? NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.86, alpha: 0.96)
      : NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.99, alpha: 0.95)
    let stroke = NSColor(calibratedRed: 0.22, green: 0.20, blue: 0.34, alpha: 0.55)

    let path = CGPath(
      roundedRect: rect,
      cornerWidth: 12,
      cornerHeight: 12,
      transform: nil
    )
    ctx.setFillColor(fill.cgColor)
    ctx.addPath(path)
    ctx.fillPath()
    ctx.setStrokeColor(stroke.cgColor)
    ctx.setLineWidth(1.2)
    ctx.addPath(path)
    ctx.strokePath()

    // Tail
    ctx.setFillColor(fill.cgColor)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: bounds.midX - 6, y: bubbleY))
    ctx.addLine(to: CGPoint(x: bounds.midX, y: bubbleY - 8))
    ctx.addLine(to: CGPoint(x: bounds.midX + 6, y: bubbleY))
    ctx.closePath()
    ctx.fillPath()

    let textOrigin = CGPoint(
      x: rect.midX - textSize.width / 2,
      y: rect.midY - textSize.height / 2
    )
    text.draw(at: textOrigin, withAttributes: attrs)
  }

  private func drawCrow(in ctx: CGContext) {
    let plumage = NSColor(calibratedRed: 0.14, green: 0.12, blue: 0.22, alpha: 1)
    let plumageLift = NSColor(calibratedRed: 0.22, green: 0.20, blue: 0.34, alpha: 1)
    let belly = NSColor(calibratedRed: 0.92, green: 0.90, blue: 0.95, alpha: 1)
    let beak = NSColor(calibratedRed: 0.95, green: 0.62, blue: 0.28, alpha: 1)
    let cheek = NSColor(calibratedRed: 1.0, green: 0.62, blue: 0.72, alpha: (happy || breakNudge) ? 0.95 : 0.55)

    ctx.setFillColor(NSColor.black.withAlphaComponent(0.12).cgColor)
    ctx.fillEllipse(in: CGRect(x: -28, y: -78, width: 56, height: 12))

    ctx.setFillColor(plumage.cgColor)
    ctx.saveGState()
    ctx.translateBy(x: 36, y: -18)
    ctx.rotate(by: 0.28)
    ctx.fillEllipse(in: CGRect(x: -18, y: -10, width: 36, height: 20))
    ctx.restoreGState()

    ctx.setFillColor(plumage.cgColor)
    ctx.fillEllipse(in: CGRect(x: -36, y: -52, width: 72, height: 64))
    ctx.setFillColor(plumageLift.cgColor)
    ctx.fillEllipse(in: CGRect(x: -28, y: -40, width: 40, height: 34))

    ctx.setFillColor(belly.cgColor)
    ctx.fillEllipse(in: CGRect(x: -16, y: -42, width: 32, height: 28))

    let wingY: CGFloat = wingUp ? -8 : -22
    ctx.setFillColor(plumageLift.cgColor)
    ctx.saveGState()
    ctx.translateBy(x: -30, y: wingY)
    ctx.rotate(by: wingUp ? -0.45 : -0.12)
    ctx.fillEllipse(in: CGRect(x: -20, y: -12, width: 40, height: 24))
    ctx.restoreGState()
    ctx.saveGState()
    ctx.translateBy(x: 18, y: wingY + 2)
    ctx.rotate(by: wingUp ? 0.35 : 0.1)
    ctx.fillEllipse(in: CGRect(x: -16, y: -10, width: 38, height: 22))
    ctx.restoreGState()

    ctx.setFillColor(plumage.cgColor)
    ctx.fillEllipse(in: CGRect(x: -34, y: -8, width: 68, height: 68))
    ctx.setFillColor(plumageLift.cgColor)
    ctx.fillEllipse(in: CGRect(x: -26, y: 8, width: 40, height: 36))

    ctx.setFillColor(plumageLift.cgColor)
    ctx.saveGState()
    ctx.translateBy(x: -10, y: 46)
    ctx.rotate(by: -0.3)
    ctx.fill(CGRect(x: -4, y: 0, width: 8, height: 18))
    ctx.restoreGState()
    ctx.saveGState()
    ctx.translateBy(x: 6, y: 48)
    ctx.rotate(by: 0.2)
    ctx.fill(CGRect(x: -3, y: 0, width: 7, height: 15))
    ctx.restoreGState()

    ctx.setFillColor(belly.withAlphaComponent(0.95).cgColor)
    ctx.fillEllipse(in: CGRect(x: -20, y: 0, width: 40, height: 32))

    drawEye(in: ctx, at: CGPoint(x: -11, y: 18), plumage: plumage)
    drawEye(in: ctx, at: CGPoint(x: 11, y: 18), plumage: plumage)

    ctx.setFillColor(beak.cgColor)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: -2, y: 6))
    ctx.addLine(to: CGPoint(x: 16, y: 2))
    ctx.addLine(to: CGPoint(x: -2, y: -2))
    ctx.closePath()
    ctx.fillPath()

    ctx.setFillColor(cheek.cgColor)
    ctx.fillEllipse(in: CGRect(x: -26, y: 4, width: 10, height: 8))
    ctx.fillEllipse(in: CGRect(x: 16, y: 4, width: 10, height: 8))

    ctx.setFillColor(beak.cgColor)
    ctx.fill(CGRect(x: -18, y: -68, width: 16, height: 5).integral)
    ctx.fill(CGRect(x: 4, y: -68, width: 16, height: 5).integral)
  }

  private func drawEye(in ctx: CGContext, at point: CGPoint, plumage: NSColor) {
    if blinkClosed || happy {
      ctx.setStrokeColor(plumage.cgColor)
      ctx.setLineWidth(2.5)
      ctx.setLineCap(.round)
      ctx.beginPath()
      ctx.move(to: CGPoint(x: point.x - 6, y: point.y))
      ctx.addLine(to: CGPoint(x: point.x + 6, y: point.y))
      ctx.strokePath()
      return
    }

    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: point.x - 7, y: point.y - 8, width: 14, height: 16))
    ctx.setFillColor(NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.22, alpha: 1).cgColor)
    ctx.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 5, width: 8, height: 9))
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: point.x - 4, y: point.y + 1, width: 3.2, height: 3.2))
  }

  private func drawHeart(in ctx: CGContext, at point: CGPoint, size: CGFloat, alpha: CGFloat) {
    let s = size
    ctx.saveGState()
    ctx.translateBy(x: point.x, y: point.y)
    ctx.setFillColor(NSColor(calibratedRed: 0.95, green: 0.45, blue: 0.55, alpha: alpha).cgColor)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: 0, y: -s * 0.35))
    ctx.addCurve(
      to: CGPoint(x: -s * 0.5, y: s * 0.15),
      control1: CGPoint(x: -s * 0.25, y: -s * 0.15),
      control2: CGPoint(x: -s * 0.5, y: -s * 0.05)
    )
    ctx.addCurve(
      to: CGPoint(x: 0, y: -s * 0.55),
      control1: CGPoint(x: -s * 0.5, y: s * 0.45),
      control2: CGPoint(x: 0, y: s * 0.2)
    )
    ctx.addCurve(
      to: CGPoint(x: s * 0.5, y: s * 0.15),
      control1: CGPoint(x: 0, y: s * 0.2),
      control2: CGPoint(x: s * 0.5, y: s * 0.45)
    )
    ctx.addCurve(
      to: CGPoint(x: 0, y: -s * 0.35),
      control1: CGPoint(x: s * 0.5, y: -s * 0.05),
      control2: CGPoint(x: s * 0.25, y: -s * 0.15)
    )
    ctx.closePath()
    ctx.fillPath()
    ctx.restoreGState()
  }
}
