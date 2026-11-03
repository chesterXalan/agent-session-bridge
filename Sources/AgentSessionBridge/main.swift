import AgentSessionCore
import Foundation

let executable = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL.resolvingSymlinksInPath()
exit(BridgeCLI.run(Array(CommandLine.arguments.dropFirst()), executable: executable))
