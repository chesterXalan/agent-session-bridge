import Darwin
import Foundation

public enum BridgeRuntime {
    /// Publish a complete executable atomically; hooks never point into an app bundle or checkout.
    @discardableResult
    public static func deploy(from source: URL, paths: BridgePaths) throws -> URL {
        let target = paths.executable
        if source.resolvingSymlinksInPath() == target.resolvingSymlinksInPath() { return target }
        let manager = FileManager.default
        try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true,
                                    attributes: [.posixPermissions: 0o700])
        let staging = target.deletingLastPathComponent().appendingPathComponent(".bridge-\(UUID().uuidString)")
        defer { try? manager.removeItem(at: staging) }
        try manager.copyItem(at: source, to: staging)
        try manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: staging.path)
        guard rename(staging.path, target.path) == 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
        return target
    }
}
