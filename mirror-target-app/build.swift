#!/usr/bin/env swift

// Builds MirrorTarget and packages it into a signed .app bundle.
// This is the native test target for verifying AppMirror's input
// forwarding against an app we fully control (a SwiftUI TextField), before
// blaming ChatGPT's WKWebView-based composer.
//
// Run directly: ./build.swift   (or: swift build.swift)
// Override the signing identity with the SIGN_ID environment variable.

import Foundation

// Sign with a stable identity so TCC grants (if ever needed) persist across
// rebuilds — same rationale as the AppMirror build.
let signID = ProcessInfo.processInfo.environment["SIGN_ID"]
    ?? "Apple Development: ssjvegerot@icloud.com (MV276V5B7J)"

let app = "MirrorTarget.app"
let executable = "MirrorTarget"
let bundleID = "com.mirror-target.testapp"

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
FileManager.default.changeCurrentDirectoryPath(scriptDir.path)

@discardableResult
func run(_ launchPath: String, _ args: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
    } catch {
        fatalError("failed to launch \(launchPath): \(error)")
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let output = String(data: data, encoding: .utf8) ?? ""
    guard process.terminationStatus == 0 else {
        FileHandle.standardError.write(output.data(using: .utf8) ?? Data())
        fatalError("`\(([launchPath] + args).joined(separator: " "))` failed (exit \(process.terminationStatus))")
    }
    return output
}

print("Building…")
run("/usr/bin/swift", ["build", "-c", "release"])

let fm = FileManager.default
try? fm.removeItem(atPath: app)
try fm.createDirectory(atPath: "\(app)/Contents/MacOS", withIntermediateDirectories: true)
try fm.copyItem(atPath: ".build/release/\(executable)", toPath: "\(app)/Contents/MacOS/\(executable)")
try fm.copyItem(atPath: "Info.plist", toPath: "\(app)/Contents/Info.plist")

print("Signing as \(signID)…")
run("/usr/bin/codesign", [
    "--force", "--deep", "--options", "runtime",
    "--identifier", bundleID,
    "--sign", signID,
    app,
])

let authority = run("/usr/bin/codesign", ["-dvv", app])
    .split(separator: "\n")
    .first { $0.hasPrefix("Authority=") }
    .map(String.init) ?? "Authority=?"

print("Built \(app) with bundle id: \(bundleID)")
print("Signed by: \(authority)")
print("Run: open \(scriptDir.appendingPathComponent(app).path)")
