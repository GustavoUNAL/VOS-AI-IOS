import SwiftUI

/// Render mínimo de **negrita** y viñetas, alineado con el formato del asistente web.
struct MarkdownText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let line):
                    Text(markdownAttributed(line))
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .bullets(let items):
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(markdownAttributed(item))
                            }
                        }
                    }
                }
            }
        }
    }

    private enum Block {
        case paragraph(String)
        case bullets([String])
    }

    private var blocks: [Block] {
        var result: [Block] = []
        var bullets: [String] = []
        func flush() {
            if !bullets.isEmpty {
                result.append(.bullets(bullets))
                bullets = []
            }
        }
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw).trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
                continue
            }
            if line.hasPrefix("• ") || line.hasPrefix("- ") || line.hasPrefix("* ") {
                let content = String(line.drop(while: { $0 == "•" || $0 == "-" || $0 == "*" || $0 == " " }))
                bullets.append(content)
            } else {
                flush()
                result.append(.paragraph(line))
            }
        }
        flush()
        return result
    }

    private func markdownAttributed(_ line: String) -> AttributedString {
        var output = AttributedString()
        var remaining = line[...]
        while let start = remaining.range(of: "**") {
            output.append(AttributedString(String(remaining[..<start.lowerBound])))
            let after = remaining[start.upperBound...]
            if let end = after.range(of: "**") {
                var bold = AttributedString(String(after[..<end.lowerBound]))
                bold.font = .body.bold()
                output.append(bold)
                remaining = after[end.upperBound...]
            } else {
                output.append(AttributedString("**"))
                remaining = after
            }
        }
        output.append(AttributedString(String(remaining)))
        return output
    }
}
