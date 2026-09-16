import XCTest
import AppKit
@testable import AppMirror

final class ForwardingTests: XCTestCase {
    func testCaptureUsesOnlyTheAXMainWindowAndAllowsAnEmptyTitle() {
        let main = CGRect(x: -150, y: -1320, width: 939, height: 729)
        func info(_ id: CGWindowID, _ bounds: CGRect, _ title: String) -> [String: Any] {
            [kCGWindowOwnerPID as String: pid_t(42), kCGWindowLayer as String: 0,
             kCGWindowNumber as String: id, kCGWindowName as String: title,
             kCGWindowBounds as String: bounds.dictionaryRepresentation]
        }
        let utility = info(1, CGRect(x: -136, y: -1306, width: 66, height: 20), "Window")
        let capture = info(2, main, "")
        XCTAssertEqual(TargetConnection.captureWindow(in: [utility, capture], pid: 42, mainBounds: main)?.id, 2)
        XCTAssertNil(TargetConnection.captureWindow(in: [utility], pid: 42, mainBounds: main))
        XCTAssertNil(TargetConnection.captureWindow(in: [capture], pid: 43, mainBounds: main))
    }
    func testCoordinatesWithOffsetAndScale() {
        let map = CoordinateMap(target: CGRect(x: 120, y: 70, width: 800, height: 600), mirror: CGSize(width: 400, height: 300))
        XCTAssertEqual(map.remotePoint(CGPoint(x: 0, y: 300)), CGPoint(x: 120, y: 70))
        XCTAssertEqual(map.remotePoint(CGPoint(x: 400, y: 0)), CGPoint(x: 920, y: 670))
        XCTAssertEqual(map.localFrame(CGRect(x: 320, y: 170, width: 200, height: 100)), CGRect(x: 100, y: 200, width: 100, height: 50))
        XCTAssertNil(map.localFrame(CGRect(x: -200, y: -200, width: 20, height: 20)))
    }

    func testPointerSequenceRetainsButtonModifiersAndDoubleClick() throws {
        let types: [CGEventType] = [.rightMouseDown, .rightMouseDragged, .rightMouseUp]
        let events = try types.map { type in
            try XCTUnwrap(PointerSample(type: type, point: CGPoint(x: 200, y: 100), button: .right, clickCount: 2, flags: [.maskShift, .maskCommand]).cgEvent())
        }
        XCTAssertEqual(events.map(\.type), types)
        for event in events {
            XCTAssertEqual(event.getIntegerValueField(.mouseEventButtonNumber), 1)
            XCTAssertEqual(event.getIntegerValueField(.mouseEventClickState), 2)
            XCTAssertTrue(event.flags.contains([.maskShift, .maskCommand]))
            XCTAssertEqual(event.location, CGPoint(x: 200, y: 100))
        }
        let middle = try XCTUnwrap(PointerSample(type: .otherMouseDown, point: .zero, button: .center, clickCount: 1, flags: []).cgEvent())
        XCTAssertEqual(middle.getIntegerValueField(.mouseEventButtonNumber), 2)
    }
    func testHeldKeySequencePreservesReleaseAndRepeat() throws {
        let down = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true))
        down.flags = [.maskShift]
        let repeated = try XCTUnwrap(down.copy())
        repeated.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
        let up = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false))
        let flags = try XCTUnwrap(down.copy()); flags.type = .flagsChanged
        let samples = try [flags, down, repeated, up].map { try XCTUnwrap(KeyboardSample($0)) }
        XCTAssertEqual(samples.map { $0.event.type }, [.flagsChanged, .keyDown, .keyDown, .keyUp])
        XCTAssertEqual(samples[2].event.getIntegerValueField(.keyboardEventAutorepeat), 1)
        XCTAssertTrue(samples[1].event.flags.contains(.maskShift))
        XCTAssertEqual(samples.filter { $0.event.type == .keyUp }.count, 1)
    }
    func testNativeMenuModifiers() {
        XCTAssertEqual(MenuBridge.modifiers(0), [.command])
        XCTAssertEqual(MenuBridge.modifiers(7), [.command, .shift, .option, .control])
        XCTAssertEqual(MenuBridge.modifiers(9), [.shift])
    }

    func testNavigationKeysArePhysicalAndUnicodeRemainsText() throws {
        func key(_ code: UInt16, _ characters: String, _ flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
            try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
                modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
                characters: characters, charactersIgnoringModifiers: characters,
                isARepeat: false, keyCode: code))
        }
        for (code, character) in [(UInt16(123), "\u{F702}"), (125, "\u{F701}"), (117, "\u{F728}"), (122, "\u{F704}")] {
            XCTAssertNil(KeyboardSample.unicodeText(for: try key(code, character)))
        }
        XCTAssertEqual(KeyboardSample.unicodeText(for: try key(0, "世界 🌍")), "世界 🌍")
        XCTAssertEqual(KeyboardSample.unicodeText(for: try key(0, "hello")), "hello")
        XCTAssertNil(KeyboardSample.unicodeText(for: try key(0, "é", .option)))
        XCTAssertNil(KeyboardSample.unicodeText(for: try key(0, "a")))
    }

    func testMenuLifecycleReleasesKeyboardAfterCloseAndReconnect() {
        let bridge = MenuBridge()
        let parent = NSMenu(title: "Parent")
        let child = NSMenu(title: "Child")
        bridge.beginTracking()
        bridge.menuWillOpen(parent)
        bridge.menuWillOpen(child)
        bridge.menuDidClose(child)
        XCTAssertTrue(bridge.isTracking)
        bridge.menuDidClose(parent)
        bridge.endTracking()
        XCTAssertFalse(bridge.isTracking)
        bridge.beginTracking()
        bridge.menuWillOpen(parent)
        bridge.reset()
        XCTAssertFalse(bridge.isTracking)
    }
}
