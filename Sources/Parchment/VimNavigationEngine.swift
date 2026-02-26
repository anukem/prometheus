import Foundation

enum VimNavigationCommand {
    case moveUp
    case moveDown
    case selectCurrent
    case comment
    case delete
}

func parseVimNavigationCommand(_ character: String) -> VimNavigationCommand? {
    switch character.lowercased() {
    case "j":
        return .moveDown
    case "k":
        return .moveUp
    case "c":
        return .comment
    case "d":
        return .delete
    case "\r":
        return .selectCurrent
    default:
        return nil
    }
}

enum VimNavigationAction: Equatable {
    case none
    case moveSelection(to: Int)
    case selectBlock(Int)
    case commentBlock(Int)
    case deleteBlock(Int)
}

struct VimNavigationEngine {
    private(set) var blockCount: Int
    private(set) var selectedBlockIndex: Int?
    private(set) var isBlockSelected: Bool = false

    init(blockCount: Int, selectedBlockIndex: Int? = nil) {
        self.blockCount = max(0, blockCount)
        if let selectedBlockIndex, selectedBlockIndex >= 0, selectedBlockIndex < blockCount {
            self.selectedBlockIndex = selectedBlockIndex
        } else {
            self.selectedBlockIndex = nil
        }
    }

    mutating func updateBlockCount(_ newCount: Int) {
        blockCount = max(0, newCount)
        if let selectedBlockIndex, selectedBlockIndex >= blockCount {
            self.selectedBlockIndex = blockCount > 0 ? blockCount - 1 : nil
            isBlockSelected = false
        }
        if blockCount == 0 {
            selectedBlockIndex = nil
            isBlockSelected = false
        }
    }

    mutating func setSelection(_ index: Int) -> VimNavigationAction {
        guard blockCount > 0, index >= 0, index < blockCount else { return .none }
        if selectedBlockIndex == index {
            return .none
        }
        selectedBlockIndex = index
        isBlockSelected = false
        return .moveSelection(to: index)
    }

    mutating func handle(_ command: VimNavigationCommand) -> VimNavigationAction {
        guard blockCount > 0 else { return .none }

        switch command {
        case .moveDown:
            let target = min((selectedBlockIndex ?? -1) + 1, blockCount - 1)
            return setSelection(target)
        case .moveUp:
            let target = max((selectedBlockIndex ?? 0) - 1, 0)
            return setSelection(target)
        case .selectCurrent:
            guard let selectedBlockIndex else { return .none }
            isBlockSelected = true
            return .selectBlock(selectedBlockIndex)
        case .comment:
            guard let selectedBlockIndex else { return .none }
            return .commentBlock(selectedBlockIndex)
        case .delete:
            guard let selectedBlockIndex else { return .none }
            return .deleteBlock(selectedBlockIndex)
        }
    }
}

enum BlockKeyboardAction {
    case comment
    case delete
}

struct BlockKeyboardActionRequest {
    let token: Int
    let blockIndex: Int
    let action: BlockKeyboardAction
}
