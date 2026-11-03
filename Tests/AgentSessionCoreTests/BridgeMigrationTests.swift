import Foundation
import Testing
@testable import AgentSessionCore

@Suite struct BridgeMigrationTests {
    private func home() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bridge-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ object: [String: Any], to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: object, options: .sortedKeys).write(to: url)
    }

    @Test func replacesLegacyHooksOnceAndPreservesMixedGroups() throws {
        let directory = try home()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = BridgePaths(home: directory)
        let legacy = "'/Applications/DeskPets.app/Contents/MacOS/deskpets-hook' record --provider codex --marker deskpets-hook-v1"
        let other = ["type": "command", "command": "echo unrelated --marker deskpets-hook-v10"]
        let group: [String: Any] = ["matcher": "custom", "hooks": [other, ["type": "command", "command": legacy]]]
        try write(["hooks": ["Stop": [group]], "unrelated": true], to: paths.codexHooks)
        let installer = HookInstaller(paths: paths, hookExecutable: paths.executable.path)
        #expect(installer.isInstalled(.codex))
        let original = try Data(contentsOf: paths.codexHooks)
        let changes = try installer.install()
        let backup = try #require(changes.first { $0.file == paths.codexHooks }?.backup)
        #expect(try Data(contentsOf: backup) == original)
        #expect(try installer.install().isEmpty)
        let installed = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: paths.codexHooks)) as? [String: Any])
        let hooks = try #require(installed["hooks"] as? [String: [[String: Any]]])
        for event in HookInstaller.codexEvents {
            let entries = try #require(hooks[event])
            let commands = entries.flatMap { $0["hooks"] as? [[String: Any]] ?? [] }
            #expect(commands.filter { HookInstaller.isOurs($0) }.count == 1)
            #expect(!commands.contains { ($0["command"] as? String) == legacy })
        }
        let end = try #require(hooks["SessionEnd"]?.first?["hooks"] as? [[String: Any]])
        #expect(end.first?["timeout"] as? Int == 3)
        try installer.uninstall()
        let removed = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: paths.codexHooks)) as? [String: Any])
        #expect(removed["unrelated"] as? Bool == true)
        let remaining = try #require(removed["hooks"] as? [String: [[String: Any]]])
        #expect(remaining.count == 1)
        #expect(remaining["Stop"]?.first?["matcher"] as? String == "custom")
        #expect(remaining["Stop"]?.first?["hooks"] as? [[String: String]] == [other])
    }

    @Test func invalidSecondProviderDoesNotModifyTheFirst() throws {
        let directory = try home()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = BridgePaths(home: directory)
        try write(["model": "test"], to: paths.claudeSettings)
        try write(["hooks": "invalid"], to: paths.codexHooks)
        let original = try Data(contentsOf: paths.claudeSettings)
        let installer = HookInstaller(paths: paths, hookExecutable: paths.executable.path)
        #expect(throws: (any Error).self) { try installer.install() }
        #expect(try Data(contentsOf: paths.claudeSettings) == original)
    }

    @Test func runtimeSurvivesRemovalOfTheSourceAndDoesNotInstallHooks() throws {
        let directory = try home()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = BridgePaths(home: directory)
        let source = directory.appendingPathComponent("downloaded-helper")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: source)
        let installed = try BridgeRuntime.deploy(from: source, paths: paths)
        try FileManager.default.removeItem(at: source)
        #expect(installed == paths.executable)
        #expect(FileManager.default.isExecutableFile(atPath: installed.path))
        #expect(!FileManager.default.fileExists(atPath: paths.claudeSettings.path))
        #expect(!FileManager.default.fileExists(atPath: paths.codexHooks.path))
        #expect(try BridgeRuntime.deploy(from: installed, paths: paths) == installed)
        #expect(throws: (any Error).self) { try BridgeRuntime.deploy(from: source, paths: paths) }
        #expect(try String(contentsOf: installed, encoding: .utf8) == "#!/bin/sh\nexit 0\n")
    }

    @Test func readsOldAndNewRecordsWithoutAnInstalledDesktopApp() throws {
        let directory = try home()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = BridgePaths(home: directory)
        let session = AgentSession(provider: .claude, pid: 42, startTime: 100, cwd: "/project")
        var record = HookRecord(provider: .claude, sessionId: "same-session", state: .working,
                                event: "PreToolUse", cwd: "/project", pid: 42, pidStart: 100, updatedAt: 101)
        try HookEvents.write(record, to: paths.legacySessions)
        #expect(SessionMerger.merge([session], records: paths.readRecords())[0].state == .working)
        record.state = .idle
        record.updatedAt = 102
        try HookEvents.write(record, to: paths.sessions)
        #expect(SessionMerger.merge([session], records: paths.readRecords())[0].state == .idle)
        try FileManager.default.removeItem(at: paths.legacySessions)
        #expect(SessionMerger.merge([session], records: paths.readRecords())[0].state == .idle)
        #expect(!paths.executable.path.contains("DeskPets"))
    }

    @Test func installationPreservesSymlinksAndPrivatePermissions() throws {
        let directory = try home()
        defer { try? FileManager.default.removeItem(at: directory) }
        let paths = BridgePaths(home: directory)
        let target = directory.appendingPathComponent("managed-settings.json")
        try write(["keep": true], to: target)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
        try FileManager.default.createDirectory(at: paths.claudeSettings.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: paths.claudeSettings, withDestinationURL: target)
        try HookInstaller(paths: paths, hookExecutable: paths.executable.path).install([.claude])
        #expect(paths.claudeSettings.resolvingSymlinksInPath() == target.resolvingSymlinksInPath())
        #expect(try FileManager.default.attributesOfItem(atPath: target.path)[.posixPermissions] as? Int == 0o600)
    }
}
