import Cocoa
import ServiceManagement

class StatusMenuController {
    func buildMenu(state: PetStateData?) -> NSMenu {
        let menu = NSMenu()

        // Header
        let petState = state.map { PetState.resolve(from: $0) } ?? .idle
        let header = NSMenuItem(title: "Claude Pet — \(petState.displayName)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        if let state = state {
            // Rate limits
            if let fh = state.rateLimit.fiveHourPercent {
                let bar = progressBar(percent: fh, width: 10)
                let pct = Int(fh)
                let title = "  5h: \(bar) \(pct)%"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }

            if let wk = state.rateLimit.weeklyPercent {
                let bar = progressBar(percent: wk, width: 10)
                let pct = Int(wk)
                let title = "  wk: \(bar) \(pct)%"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }

            menu.addItem(NSMenuItem.separator())

            // Sessions
            let sessHeader = NSMenuItem(
                title: "Active Sessions (\(state.activeSessions))",
                action: nil, keyEquivalent: ""
            )
            sessHeader.isEnabled = false
            menu.addItem(sessHeader)

            for session in state.sessions {
                let model = session.model
                    .replacingOccurrences(of: "claude-", with: "")
                    .components(separatedBy: "-").prefix(2).joined(separator: "-")
                let title = "  \(session.project)  \(model)  ctx:\(Int(session.contextPercent))%  \u{1F527}\(session.toolCalls)  \(session.sessionMinutes)m"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }

            if !state.sessions.isEmpty {
                menu.addItem(NSMenuItem.separator())
                let totals = NSMenuItem(
                    title: "  Total: \u{1F527}\(state.aggregate.totalToolCalls)  agents:\(state.aggregate.totalRunningAgents)",
                    action: nil, keyEquivalent: ""
                )
                totals.isEnabled = false
                menu.addItem(totals)
            }
        } else {
            let noSession = NSMenuItem(title: "  No active sessions", action: nil, keyEquivalent: "")
            noSession.isEnabled = false
            menu.addItem(noSession)
        }

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quit = NSMenuItem(title: "Quit Claude Pet", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        return menu
    }

    private func progressBar(percent: Double, width: Int) -> String {
        let filled = Int(percent / 100.0 * Double(width))
        let empty = width - filled
        let full = String(repeating: "\u{2588}", count: max(0, filled))
        let blank = String(repeating: "\u{2591}", count: max(0, empty))
        return full + blank
    }
}
