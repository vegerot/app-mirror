import AppKit

// A low-level fixture check, not Computer Use end-to-end coverage.
// Focus the fixture's draft through the mirror before running this script.
guard let proxy = NSRunningApplication.runningApplications(withBundleIdentifier: "com.chatgpt-mirror.proxy").first else {
    fatalError("Launch the mirror targeting MirrorTarget first")
}
for (type, repeated, flags) in [
    (CGEventType.flagsChanged, false, CGEventFlags.maskShift),
    (.keyDown, false, .maskShift),
    (.keyDown, true, .maskShift),
    (.keyUp, false, .maskShift),
    (.flagsChanged, false, CGEventFlags())
] {
    let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: type == .keyDown)!
    event.type = type
    event.flags = flags
    event.setIntegerValueField(.keyboardEventAutorepeat, value: repeated ? 1 : 0)
    event.postToPid(proxy.processIdentifier)
    usleep(250_000)
}
