import Foundation

/// Shared runtime and metadata, independent of either consumer's installation directory.
public struct BridgePaths: Sendable {
    public let home: URL

    public init(home: URL) { self.home = home }

    public static func current() -> BridgePaths {
        let home = ProcessInfo.processInfo.environment["HOME"].flatMap { $0.isEmpty ? nil : $0 }
        return BridgePaths(home: home.map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser)
    }

    public var support: URL { home.appendingPathComponent("Library/Application Support/AgentSessionBridge", isDirectory: true) }
    public var sessions: URL { support.appendingPathComponent("sessions", isDirectory: true) }
    public var executable: URL { support.appendingPathComponent("bin/agent-session-bridge") }
    public var hookErrors: URL { support.appendingPathComponent("hook-errors.log") }
    public var claudeSettings: URL { home.appendingPathComponent(".claude/settings.json") }
    public var codexHooks: URL { home.appendingPathComponent(".codex/hooks.json") }
    public var legacySessions: URL { home.appendingPathComponent("Library/Application Support/DeskPets/sessions", isDirectory: true) }

    /// Existing CLI sessions may still invoke the old hook until they restart.
    public func readRecords() -> [HookRecord] {
        HookEvents.readAll(from: legacySessions) + HookEvents.readAll(from: sessions)
    }
}
