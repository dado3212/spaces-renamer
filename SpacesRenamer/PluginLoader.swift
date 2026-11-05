//
//  PluginLoader.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/4/26.
//  Copyright © 2026 Alex Beals. All rights reserved.
//

import Cocoa

// Loads spaces-renamer.dylib into WindowManager, which draws the Spaces bar on macOS 27, and loads it
// again whenever WindowManager restarts. DYLD_INSERT_LIBRARIES is set for the login session only
// while WindowManager restarts. Apps launched in that second load the plugin too; it does nothing there.
class PluginLoader {
  static let shared = PluginLoader()

  private let queue = DispatchQueue(label: "com.alexbeals.SpacesRenamer.PluginLoader")
  private let hostTarget = "gui/\(getuid())/com.apple.WindowManager.agent"
  // WindowManager's sandbox can read its own Application Support folder.
  private let stagingFolder = Utils.libraryPath.appending("/Application Support/com.apple.windowmanager/SpacesRenamer")
  private var exitSource: DispatchSourceProcess?
  private var attempts: [Date] = []
  private var warned = false

  func start() {
    queue.async { self.ensureLoaded() }
  }

  private func ensureLoaded() {
    // An interrupted load can leave the variable set. Remove it if it names one of ours.
    if run("/bin/launchctl", ["getenv", "DYLD_INSERT_LIBRARIES"]).hasPrefix(stagingFolder + "/") {
      run("/bin/launchctl", ["unsetenv", "DYLD_INSERT_LIBRARIES"])
    }
    guard prerequisitesMet() else {
      warnOnce()
      return
    }
    guard let library = stagedLibrary() else { return }
    if let pid = hostPID(), isLoaded(library, in: pid) {
      watch(pid)
      return
    }

    // Stop, rather than restart WindowManager over and over, if the plugin keeps failing.
    attempts = attempts.filter { $0.timeIntervalSinceNow > -600 }
    guard attempts.count < 3 else {
      NSLog("SpacesRenamer: the plugin failed to load 3 times in 10 minutes; not retrying")
      return
    }
    attempts.append(Date())
    watch(nil)
    load(library)
    // The plugin records its process and file as it loads.
    for _ in 0..<25 {
      if let pid = hostPID(), isLoaded(library, in: pid) {
        watch(pid)
        return
      }
      usleep(200_000)
    }
    NSLog("SpacesRenamer: the plugin did not load into WindowManager")
    watch(hostPID())
  }

  private func prerequisitesMet() -> Bool {
    return run("/usr/sbin/sysctl", ["-n", "kern.bootargs"]).components(separatedBy: " ").contains("-arm64e_preview_abi") &&
      run("/usr/bin/csrutil", ["status"]).contains("status: disabled.")
  }

  private func warnOnce() {
    guard !warned else { return }
    warned = true
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.messageText = "Spaces Renamer can't rename spaces yet"
      alert.informativeText = "On macOS 27 it needs System Integrity Protection disabled and the -arm64e_preview_abi boot argument. See the installation instructions."
      NSApp.activate(ignoringOtherApps: true)
      alert.runModal()
    }
  }

  // One file per version, never deleted: apps launched while the variable was set keep its path, and
  // their children die at launch if the file is missing. Replacing it atomically is safe, since
  // running processes keep the copy they loaded.
  private func stagedLibrary() -> String? {
    guard let bundled = Bundle.main.url(forResource: "spaces-renamer", withExtension: "dylib"),
      let data = try? Data(contentsOf: bundled),
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
      NSLog("SpacesRenamer: spaces-renamer.dylib is missing from the app")
      return nil
    }
    let staged = "\(stagingFolder)/spaces-renamer-\(version).dylib"
    do {
      try FileManager.default.createDirectory(atPath: stagingFolder, withIntermediateDirectories: true, attributes: nil)
      try data.write(to: URL(fileURLWithPath: staged), options: .atomic)
    } catch {
      NSLog("SpacesRenamer: could not stage the plugin: \(error)")
      return nil
    }
    return staged
  }

  private func hostPID() -> pid_t? {
    for line in run("/bin/launchctl", ["print", hostTarget]).components(separatedBy: "\n") {
      let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: " = ")
      if parts.count == 2 && parts[0] == "pid" {
        return pid_t(parts[1])
      }
    }
    return nil
  }

  private func isLoaded(_ library: String, in pid: pid_t) -> Bool {
    let domain = "com.apple.WindowManager" as CFString
    CFPreferencesAppSynchronize(domain)
    guard let status = CFPreferencesCopyAppValue("SpacesRenamerWindowManagerPlugin" as CFString, domain) as? [String: Any],
      let hostPID = status["HostPID"] as? Int else {
      return false
    }
    return pid_t(hostPID) == pid && status["LibraryPath"] as? String == library
  }

  private func load(_ library: String) {
    guard run("/bin/launchctl", ["getenv", "DYLD_INSERT_LIBRARIES"]).isEmpty else {
      NSLog("SpacesRenamer: DYLD_INSERT_LIBRARIES is already set for this session; not loading the plugin")
      return
    }
    let previous = hostPID()
    run("/bin/launchctl", ["setenv", "DYLD_INSERT_LIBRARIES", library])
    defer { run("/bin/launchctl", ["unsetenv", "DYLD_INSERT_LIBRARIES"]) }
    // Restarts WindowManager if it is running, and starts it otherwise.
    run("/bin/launchctl", ["kickstart", "-k", hostTarget])
    for _ in 0..<50 {
      if let pid = hostPID(), pid != previous { return }
      usleep(200_000)
    }
    NSLog("SpacesRenamer: WindowManager did not restart")
  }

  // launchd restarts WindowManager after it exits. Load the plugin into the new process.
  private func watch(_ pid: pid_t?) {
    exitSource?.cancel()
    exitSource = nil
    guard let pid = pid else { return }
    let source = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: queue)
    source.setEventHandler { [weak self] in
      self?.queue.asyncAfter(deadline: .now() + 2) { self?.ensureLoaded() }
    }
    source.resume()
    exitSource = source
  }

  @discardableResult
  private func run(_ path: String, _ arguments: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
    } catch {
      return ""
    }
    let output = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(decoding: output, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
