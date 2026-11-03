import Foundation

public struct TmuxLocation: Equatable, Sendable {
    public var socketPath: String
    public var paneId: String

    public init(socketPath: String, paneId: String) {
        self.socketPath = socketPath
        self.paneId = paneId
    }

    public static func from(environment: [String: String]) -> TmuxLocation? {
        guard let value = environment["TMUX"], let pane = environment["TMUX_PANE"],
              pane.first == "%", !pane.dropFirst().isEmpty, pane.dropFirst().allSatisfy(\.isNumber)
        else { return nil }
        let fields = value.split(separator: ",", omittingEmptySubsequences: false)
        guard fields.count >= 3, let server = Int32(fields[fields.count - 2]), server > 0,
              Int(fields.last!) != nil else { return nil }
        let socket = fields.dropLast(2).joined(separator: ",")
        guard socket.hasPrefix("/"), !socket.contains("\0") else { return nil }
        return TmuxLocation(socketPath: socket, paneId: pane)
    }
}

