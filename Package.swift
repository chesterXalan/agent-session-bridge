// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "AgentSessionBridge",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AgentSessionCore", targets: ["AgentSessionCore"]),
        .executable(name: "agent-session-bridge", targets: ["AgentSessionBridge"]),
    ],
    targets: [
        .target(name: "AgentSessionCore"),
        .executableTarget(name: "AgentSessionBridge", dependencies: ["AgentSessionCore"]),
        .testTarget(name: "AgentSessionCoreTests", dependencies: ["AgentSessionCore"]),
    ],
    swiftLanguageModes: [.v5]
)
