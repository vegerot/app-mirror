#!/usr/bin/env swift

// Builds AppMirror and packages it into a signed .app bundle.
// The .app is what carries the com.chatgpt-mirror.proxy identifier that lets
// Computer Use target it (a bare SPM binary has no Info.plist / bundle ID).
//
// Run directly: ./build.swift   (or: swift build.swift)
// Override the signing identity with the SIGN_ID environment variable.

import Foundation

// Sign with a stable identity so TCC (Screen Recording / Accessibility) grants
// persist across rebuilds. Ad-hoc (`-`) changes the cdhash every build, which
// makes macOS re-prompt for permission on every launch.
let signID = ProcessInfo.processInfo.environment["SIGN_ID"]
    ?? "Apple Development: ssjvegerot@icloud.com (MV276V5B7J)"

let app = "AppMirror.app"
let executable = "AppMirror"
let bundleID = "com.chatgpt-mirror.proxy"

// Work relative to this script's directory, matching the old `cd $(dirname $0)`.
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent()
FileManager.default.changeCurrentDirectoryPath(scriptDir.path)

/// Runs a command, streaming its output, and aborts the script on failure.
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

// 1. Compile the release binary.
print("Building…")
run("/usr/bin/swift", ["build", "-c", "release"])

// 2. Assemble a fresh .app bundle around the compiled binary + Info.plist.
let fm = FileManager.default
try? fm.removeItem(atPath: app)
try fm.createDirectory(atPath: "\(app)/Contents/MacOS", withIntermediateDirectories: true)
try fm.copyItem(atPath: ".build/release/\(executable)", toPath: "\(app)/Contents/MacOS/\(executable)")
try fm.copyItem(atPath: "Info.plist", toPath: "\(app)/Contents/Info.plist")

// 3. Sign with the stable identity, pinning the bundle id into the signature.
print("Signing as \(signID)…")
run("/usr/bin/codesign", [
    "--force", "--deep", "--options", "runtime",
    "--identifier", bundleID,
    "--sign", signID,
    app,
])

// 4. Report what we built.
let authority = run("/usr/bin/codesign", ["-dvv", app])
    .split(separator: "\n")
    .first { $0.hasPrefix("Authority=") }
    .map(String.init) ?? "Authority=?"

print("Built \(app) with bundle id: \(bundleID)")
print("Signed by: \(authority)")
print("Run: open \(scriptDir.appendingPathComponent(app).path)")
