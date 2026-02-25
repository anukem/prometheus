import SwiftUI
import UniformTypeIdentifiers

struct ParchmentDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown, .plainText] }

    var text: String

    init(text: String = """
    # Product Delivery Plan

    ## Purpose
    This seed document is intentionally long so the reader view has enough height
    to test scroll-driven behavior, including progress heuristics and sticky state.

    ## 1. Objectives
    - Ship a reliable markdown reading experience.
    - Keep editing fast even on large documents.
    - Expose meaningful reading progress to users.
    - Verify visual polish in both split and preview modes.

    ## 2. Success Metrics
    - 95th percentile render time under 150ms for medium documents.
    - Scroll progress updates continuously during wheel and trackpad input.
    - No visual jitter in progress indicator while scrolling.
    - Outline remains accurate after edits and file reloads.

    ## 3. Scope
    ### In Scope
    - Reader rendering and typography.
    - Outline generation from headings.
    - Progress signal based on scroll position.
    - Status bar diagnostics.

    ### Out of Scope
    - Collaboration features.
    - Rich text editing.
    - Cloud sync and account management.

    ## 4. Workstreams
    ### 4.1 Reader UX
    We will tune spacing, hierarchy, and contrast so long-form reading feels calm
    and predictable over extended sessions.

    ### 4.2 Source Editing
    The source editor should remain responsive during frequent edits. Latency spikes
    above human perception thresholds are treated as bugs.

    ### 4.3 Outline Navigation
    Heading extraction must tolerate inconsistent markdown while preserving ordering
    and stable anchor indices.

    ### 4.4 Progress Heuristic
    Progress is treated as a heuristic, not a strict completion metric. The bar
    should still move in a way that aligns with user intuition.

    ## 5. Milestones
    1. Baseline instrumentation and logging.
    2. Reproduce non-updating progress scenarios.
    3. Validate fix with before/after logs.
    4. Add regression checks for key paths.
    5. Ship and monitor.

    ## 6. Risks
    - Geometry reads can report unexpected values during layout transitions.
    - Very short documents may produce zero-length scroll ranges.
    - Split view width changes can alter text wrapping and content height.
    - Progress can feel wrong if metadata and content blocks use mismatched offsets.

    ## 7. Mitigations
    - Clamp all progress values to [0, 1].
    - Log raw geometry inputs and derived offsets.
    - Recompute content height on source changes and viewport changes.
    - Compare previous and next progress values to detect flatlines.

    ## 8. Test Matrix
    - Short, medium, and very long markdown files.
    - Headings with mixed nesting depth.
    - Large code blocks and long block quotes.
    - Window resize events while near top, middle, and bottom.
    - Switching between preview, source, and split modes.

    ## 9. Release Checklist
    - Build in debug and release configurations.
    - Confirm progress behavior with trackpad and mouse wheel.
    - Validate expected outline and status bar values.
    - Verify no crashes when opening plain text files.
    - Smoke test export path.

    ## 10. Notes
    This is placeholder copy intended for development only. Replace it when you are
    ready to draft real content.

    ## Appendix A: Extended Body Text
    Teams often underestimate how much long-form content influences UI behavior.
    Wrapping, paragraph spacing, and inline formatting can significantly impact
    measured heights. A robust reader should produce stable progress updates across
    these variations without requiring manual calibration.

    A practical approach is to instrument first, establish a reproducible baseline,
    and then iterate with small deltas. When logs are structured consistently,
    regressions become easier to spot and compare over time.

    ## Appendix B: Extra Filler
    Paragraph 1: Reliable scroll heuristics depend on coherent geometry.

    Paragraph 2: Coherent geometry depends on stable container layout.

    Paragraph 3: Stable layout depends on predictable content measurement.

    Paragraph 4: Predictable measurement depends on transparent instrumentation.

    Paragraph 5: Transparent instrumentation makes debugging fast and repeatable.

    Paragraph 6: Fast debugging helps maintain momentum during feature delivery.

    Paragraph 7: Momentum matters most when validating visual interaction details.

    Paragraph 8: Interaction details are where users notice quality immediately.

    Paragraph 9: Immediate feedback strengthens confidence in product direction.

    Paragraph 10: Confident teams ship more often with fewer regressions.
    """) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}
