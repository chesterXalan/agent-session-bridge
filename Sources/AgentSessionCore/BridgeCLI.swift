import Foundation

/// The app compatibility command and standalone executable share one implementation.
public enum BridgeCLI {
    public static func run(_ arguments: [String], executable: URL) -> Int32 {
        func option(_ name: String) -> String? {
            guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        let provider = option("--provider").flatMap(Provider.init(rawValue:))
        let command = arguments.first ?? ""
        if arguments.contains("--provider"), provider == nil {
            error("--provider must be claude or codex")
            return command == "record" ? 0 : 2
        }
        let paths = option("--home").map { BridgePaths(home: URL(fileURLWithPath: $0, isDirectory: true)) }
            ?? .current()
        switch command {
        case "record":
            record(provider: provider ?? .claude, paths: paths)
        case "install-runtime", "install", "uninstall":
            do {
                if command != "uninstall" { try BridgeRuntime.deploy(from: executable, paths: paths) }
                if command == "install-runtime" { return 0 }
                let installer = HookInstaller(paths: paths, hookExecutable: paths.executable.path)
                let providers = provider.map { [$0] } ?? Provider.allCases
                let changes = command == "install" ? try installer.install(providers) : try installer.uninstall(providers)
                for change in changes {
                    print("updated \(change.file.path)" + (change.backup.map { " (backup: \($0.path))" } ?? ""))
                }
                if changes.isEmpty { print("nothing to change") }
            } catch {
                self.error(error.localizedDescription)
                return 1
            }
        case "list":
            let records = paths.readRecords()
            let sessions = SessionMerger.merge(SessionScanner.scan(), records: records)
            let names = SessionNamer(home: paths.home).names(for: sessions, records: records)
            for session in sessions {
                let tab = session.cmux.map { "cmux:\($0.workspaceId)/\($0.surfaceId)" } ?? "-"
                let fields = [session.provider.rawValue, String(session.pid), session.state.rawValue,
                              names[session.id] ?? session.location, session.cwd, tab]
                print(fields.map { $0.components(separatedBy: .newlines.union(.init(charactersIn: "\t"))).joined(separator: " ") }
                    .joined(separator: "\t"))
            }
        default:
            error("usage: agent-session-bridge record|list|install-runtime|install|uninstall [--provider claude|codex] [--home DIR]")
            return 2
        }
        return 0
    }

    private struct HookInputError: Error {}

    private static func record(provider: Provider, paths: BridgePaths) {
        do {
            let input = FileHandle.standardInput.readData(ofLength: 1024 * 1024 + 1)
            guard input.count <= 1024 * 1024,
                  let payload = try JSONSerialization.jsonObject(with: input) as? [String: Any] else { throw HookInputError() }
            let agent = SessionScanner.agentAncestor().map { (pid: $0.pid, start: $0.start) }
            if let record = HookEvents.record(provider: provider, payload: payload, agent: agent) {
                _ = try HookEvents.write(record, to: paths.sessions)
            }
        } catch {
            // Never log the payload: it can contain private prompts and tool input.
            let line = "\(Int(Date().timeIntervalSince1970)) \(type(of: error))\n"
            try? FileManager.default.createDirectory(at: paths.support, withIntermediateDirectories: true,
                                                    attributes: [.posixPermissions: 0o700])
            if let handle = try? FileHandle(forWritingTo: paths.hookErrors) {
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                try? handle.close()
            } else {
                try? Data(line.utf8).write(to: paths.hookErrors)
            }
        }
        // An empty Codex response and exit 0 never block the agent.
        if provider == .codex { print("{}") }
    }

    private static func error(_ message: String) {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    }
}
