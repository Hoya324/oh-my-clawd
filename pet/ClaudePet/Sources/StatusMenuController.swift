import Cocoa
import SwiftUI

class StatusMenuController {
    let viewModel = ClawdViewModel()
    private var popover: NSPopover?

    func setupPopover() -> NSPopover {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 640)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: CollectionPopoverView(viewModel: viewModel)
        )
        self.popover = popover
        return popover
    }

    func togglePopover(relativeTo button: NSStatusBarButton) {
        guard let popover = popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func updateState(_ stateData: PetStateData?) {
        viewModel.refresh(stateData: stateData)
    }
}
