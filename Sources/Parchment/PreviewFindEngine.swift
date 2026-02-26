import SwiftUI

// MARK: - Highlight segments

struct HighlightSegment: Equatable {
    let text: String
    let isHighlighted: Bool
}

func highlightSegments(_ string: String, query: String) -> [HighlightSegment] {
    guard !query.isEmpty else {
        return [HighlightSegment(text: string, isHighlighted: false)]
    }

    var segments: [HighlightSegment] = []
    let lowered = string.lowercased()
    let loweredQuery = query.lowercased()
    var cursor = string.startIndex

    while cursor < string.endIndex {
        guard let range = lowered.range(of: loweredQuery, range: cursor..<string.endIndex) else {
            break
        }
        if cursor < range.lowerBound {
            segments.append(HighlightSegment(text: String(string[cursor..<range.lowerBound]), isHighlighted: false))
        }
        segments.append(HighlightSegment(text: String(string[range]), isHighlighted: true))
        cursor = range.upperBound
    }

    if cursor < string.endIndex {
        segments.append(HighlightSegment(text: String(string[cursor...]), isHighlighted: false))
    }

    if segments.isEmpty {
        return [HighlightSegment(text: string, isHighlighted: false)]
    }

    return segments
}

func highlightedText(_ string: String, query: String) -> SwiftUI.Text {
    let segments = highlightSegments(string, query: query)
    var attributed = AttributedString()
    for segment in segments {
        var part = AttributedString(segment.text)
        if segment.isHighlighted {
            part.backgroundColor = .yellow.opacity(0.4)
        }
        attributed.append(part)
    }
    return SwiftUI.Text(attributed)
}

// MARK: - Find engine

struct PreviewFindMatch: Equatable {
    let blockIndex: Int
}

struct PreviewFindEngine {
    private(set) var matches: [PreviewFindMatch] = []
    private(set) var currentIndex: Int = 0

    var matchCount: Int { matches.count }

    var currentMatch: PreviewFindMatch? {
        guard !matches.isEmpty else { return nil }
        return matches[currentIndex]
    }

    mutating func search(query: String, in blockTexts: [String]) {
        matches = []
        currentIndex = 0
        guard !query.isEmpty else { return }
        let lowered = query.lowercased()

        for (blockIndex, text) in blockTexts.enumerated() {
            let haystack = text.lowercased()
            var searchStart = haystack.startIndex
            while searchStart < haystack.endIndex,
                  let range = haystack.range(of: lowered, range: searchStart..<haystack.endIndex) {
                matches.append(PreviewFindMatch(blockIndex: blockIndex))
                searchStart = range.upperBound
            }
        }
    }

    mutating func nextMatch() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex + 1) % matches.count
    }

    mutating func previousMatch() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex - 1 + matches.count) % matches.count
    }
}
