import AppKit
import ServiceManagement
import SwiftUI

// Keep the system thumb and interactions; customize only the filled track.
final class PinkSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        super.drawBar(inside: rect, flipped: flipped)
        guard isEnabled else { return }
        let thumb = knobRect(flipped: flipped)
        let end = min(rect.maxX, max(rect.minX, thumb.midX))
        let track = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        NSGraphicsContext.saveGraphicsState()
        track.addClip()
        NSColor(srgbRed: 234.0 / 255, green: 190.0 / 255, blue: 187.0 / 255, alpha: 1).setFill()
        NSRect(x: rect.minX, y: rect.minY, width: end - rect.minX, height: rect.height).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

// Four tiny, static windows per display. No timers, animation or event taps.
final class CornerView: NSView {
    private let maskPath: CGPath
    init(size: CGFloat, radius: CGFloat, screenSize: CGSize, corner: Int) {
        // Generate the actual Apple continuous shape at the complete display size.
        // Crop its inverse into a small corner window, including the full curve tail.
        let nativePath = RoundedRectangle(cornerRadius: radius, style: .continuous)
            .path(in: CGRect(origin: .zero, size: screenSize)).cgPath
        let transform = CGAffineTransform(
            translationX: (corner == 1 || corner == 3) ? size - screenSize.width : 0,
            y: corner >= 2 ? size - screenSize.height : 0)
        let mask = CGMutablePath()
        mask.addRect(CGRect(x: 0, y: 0, width: size, height: size))
        mask.addPath(nativePath, transform: transform)
        maskPath = mask
        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size))
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.clip(to: bounds)
        context.setFillColor(NSColor.black.cgColor)
        context.addPath(maskPath)
        context.drawPath(using: .eoFill)
        context.restoreGState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var windows: [NSWindow] = []
    private var statusItem: NSStatusItem!
    private var enabled = true
    private let defaults = UserDefaults.standard
    private var radiusLabel: NSTextField?
    private var nativeCurve: Bool { defaults.bool(forKey: "nativeCurve") }
    private var customRadius: Double { (min(36, max(1, defaults.double(forKey: "radius"))) * 10).rounded() / 10 }
    private var radius: CGFloat { nativeCurve ? 26.1 : CGFloat(customRadius) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!).count > 1 {
            NSApp.terminate(nil)
            return
        }
        defaults.register(defaults: ["radius": 12, "nativeCurve": true])
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: "屏幕圆角")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        NotificationCenter.default.addObserver(self, selector: #selector(rebuild), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(rebuild), name: NSWorkspace.didWakeNotification, object: nil)
        rebuild()
        if !defaults.bool(forKey: "loginAttempted") {
            defaults.set(true, forKey: "loginAttempted")
            setLoginEnabled(true)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let title = NSMenuItem(title: "屏幕圆角 · RoundCorners", action: nil, keyEquivalent: "")
        menu.addItem(title)
        add(menu, enabled ? "暂停圆角" : "启用圆角", #selector(toggleCorners))
        menu.addItem(.separator())
        for (name, tag) in [("苹果原生曲率", 1), ("SwiftUI", 0)] {
            let item = add(menu, name, #selector(changeCurve(_:)))
            item.tag = tag
            item.state = defaults.bool(forKey: "nativeCurve") == (tag == 1) ? .on : .off
        }
        menu.addItem(.separator())
        let control = NSView(frame: NSRect(x: 0, y: 0, width: 284, height: 88))
        let label = NSTextField(labelWithString: radiusText)
        label.frame = NSRect(x: 18, y: 60, width: 252, height: 19)
        label.textColor = nativeCurve ? .disabledControlTextColor : .labelColor
        control.addSubview(label)
        radiusLabel = label
        let slider = NSSlider()
        slider.cell = PinkSliderCell()
        slider.minValue = 1
        slider.maxValue = 36
        slider.doubleValue = customRadius
        slider.target = self
        slider.action = #selector(changeRadius(_:))
        slider.frame = NSRect(x: 18, y: 30, width: 248, height: 24)
        slider.isContinuous = true
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false
        slider.isEnabled = !nativeCurve
        slider.setAccessibilityLabel("自定义圆角大小")
        control.addSubview(slider)
        let hint = NSTextField(labelWithString: "小  1 pt                                 大  36 pt")
        hint.frame = NSRect(x: 18, y: 7, width: 252, height: 18)
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = nativeCurve ? .disabledControlTextColor : .secondaryLabelColor
        control.addSubview(hint)
        let sliderItem = NSMenuItem()
        sliderItem.view = control
        menu.addItem(sliderItem)
        menu.addItem(.separator())
        let login = SMAppService.mainApp.status
        let item = add(menu, login == .requiresApproval ? "开机自启（需要系统批准）" : "开机自启", #selector(toggleLogin))
        item.state = login == .enabled ? .on : (login == .requiresApproval ? .mixed : .off)
        add(menu, "打开登录项设置…", #selector(openLoginSettings))
        menu.addItem(.separator())
        add(menu, "退出", #selector(quit)).keyEquivalent = "q"
    }

    @discardableResult private func add(_ menu: NSMenu, _ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return item
    }

    @objc private func rebuild() {
        windows.forEach { $0.orderOut(nil); $0.close() }
        windows.removeAll()
        guard enabled else { return }
        for screen in NSScreen.screens {
            let f = screen.frame
            let r = ceil(radius * 3)
            let origins = [CGPoint(x: f.minX, y: f.minY), CGPoint(x: f.maxX-r, y: f.minY), CGPoint(x: f.minX, y: f.maxY-r), CGPoint(x: f.maxX-r, y: f.maxY-r)]
            for (corner, origin) in origins.enumerated() {
                let window = NSWindow(contentRect: NSRect(origin: origin, size: NSSize(width: r, height: r)), styleMask: .borderless, backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = false
                window.ignoresMouseEvents = true
                window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
                window.hidesOnDeactivate = false
                window.isExcludedFromWindowsMenu = true
                window.contentView = CornerView(size: r, radius: radius, screenSize: f.size, corner: corner)
                window.orderFrontRegardless()
                windows.append(window)
            }
        }
    }

    @objc private func changeCurve(_ sender: NSMenuItem) {
        defaults.set(sender.tag == 1, forKey: "nativeCurve")
        rebuild()
    }
    @objc private func toggleCorners() { enabled.toggle(); rebuild() }
    private var radiusText: String {
        String(format: "圆角大小：%.1f pt", customRadius)
    }
    @objc private func changeRadius(_ sender: NSSlider) {
        guard !nativeCurve else { return }
        let value = (min(36, max(1, sender.doubleValue)) * 10).rounded() / 10
        sender.doubleValue = value
        guard value != customRadius else { return }
        defaults.set(value, forKey: "radius")
        radiusLabel?.stringValue = radiusText
        rebuild()
    }
    @objc private func toggleLogin() {
        if SMAppService.mainApp.status == .requiresApproval { openLoginSettings(); return }
        setLoginEnabled(SMAppService.mainApp.status != .enabled)
    }
    private func setLoginEnabled(_ enable: Bool) {
        do {
            if enable { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            let alert = NSAlert()
            alert.messageText = "无法更新开机自启"
            alert.informativeText = error.localizedDescription + "\n请在系统设置 → 通用 → 登录项与扩展中检查。"
            alert.runModal()
        }
    }
    @objc private func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }
    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
