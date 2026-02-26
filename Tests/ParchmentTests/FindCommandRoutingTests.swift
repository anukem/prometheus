import XCTest
@testable import Parchment

final class FindCommandRoutingTests: XCTestCase {
    func testPerformFindUsesShowFindInterfaceWhenAvailable() {
        let recorder = ActionRecorder(resultBySelector: [
            FindCommandRouting.showFindInterfaceSelectorString: true,
            FindCommandRouting.showFindPanelSelectorString: false
        ])

        FindCommandRouting.performFind(previewFindController: nil, sendAction: recorder.send)

        XCTAssertEqual(recorder.invocations, [FindCommandRouting.showFindInterfaceSelectorString])
    }

    func testPerformFindFallsBackToFindPanelWhenInterfaceActionUnavailable() {
        let recorder = ActionRecorder(resultBySelector: [
            FindCommandRouting.showFindInterfaceSelectorString: false,
            FindCommandRouting.showFindPanelSelectorString: true
        ])

        FindCommandRouting.performFind(previewFindController: nil, sendAction: recorder.send)

        XCTAssertEqual(
            recorder.invocations,
            [
                FindCommandRouting.showFindInterfaceSelectorString,
                FindCommandRouting.showFindPanelSelectorString
            ]
        )
    }

    func testPerformFindShowsPreviewFindWhenControllerProvided() {
        let controller = PreviewFindController()
        let recorder = ActionRecorder(resultBySelector: [:])

        FindCommandRouting.performFind(previewFindController: controller, sendAction: recorder.send)

        XCTAssertTrue(controller.isVisible)
        XCTAssertTrue(recorder.invocations.isEmpty, "Should not send responder-chain actions when preview find is available")
    }

    func testPerformFindUsesResponderChainWhenControllerNil() {
        let recorder = ActionRecorder(resultBySelector: [
            FindCommandRouting.showFindInterfaceSelectorString: true
        ])

        FindCommandRouting.performFind(previewFindController: nil, sendAction: recorder.send)

        XCTAssertEqual(recorder.invocations, [FindCommandRouting.showFindInterfaceSelectorString])
    }
}

private final class ActionRecorder {
    private let resultBySelector: [String: Bool]
    private(set) var invocations: [String] = []

    init(resultBySelector: [String: Bool]) {
        self.resultBySelector = resultBySelector
    }

    func send(_ selector: Selector) -> Bool {
        let selectorName = NSStringFromSelector(selector)
        invocations.append(selectorName)
        return resultBySelector[selectorName] ?? false
    }
}
