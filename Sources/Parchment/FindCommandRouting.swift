import AppKit
import SwiftUI

enum FindCommandRouting {
    static let showFindInterfaceSelectorString = "performTextFinderAction:"
    static let showFindPanelSelectorString = "orderFrontFindPanel:"

    static func performFind(
        previewFindController: PreviewFindController?,
        sendAction: (Selector) -> Bool = defaultSendAction
    ) {
        if let controller = previewFindController {
            controller.show()
            return
        }

        let showFindInterfaceSelector = NSSelectorFromString(showFindInterfaceSelectorString)
        if sendAction(showFindInterfaceSelector) {
            return
        }

        let showFindPanelSelector = NSSelectorFromString(showFindPanelSelectorString)
        _ = sendAction(showFindPanelSelector)
    }

    private static func defaultSendAction(_ selector: Selector) -> Bool {
        if NSStringFromSelector(selector) == showFindInterfaceSelectorString {
            let findSender = NSMenuItem()
            findSender.tag = NSTextFinder.Action.showFindInterface.rawValue
            return NSApp.sendAction(selector, to: nil, from: findSender)
        }

        return NSApp.sendAction(selector, to: nil, from: nil)
    }
}
