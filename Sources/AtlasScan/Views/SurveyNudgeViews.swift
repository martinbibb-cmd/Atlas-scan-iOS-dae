#if canImport(SwiftUI)
import SwiftUI

struct SurveyNudgeRow: View {
    let nudge: SurveyNudge
    let assistanceLevel: SurveyAssistanceLevel
    var onSetState: ((SurveyNudgeState) -> Void)?
    var onClearState: (() -> Void)?

    init(
        nudge: SurveyNudge,
        assistanceLevel: SurveyAssistanceLevel = .defaultLevel,
        onSetState: ((SurveyNudgeState) -> Void)? = nil,
        onClearState: (() -> Void)? = nil
    ) {
        self.nudge = nudge
        self.assistanceLevel = assistanceLevel
        self.onSetState = onSetState
        self.onClearState = onClearState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nudge.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if assistanceLevel != .expert {
                        Text(nudge.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                stateBadge
            }

            let guidanceItems = nudge.guidanceItems(for: assistanceLevel)
            if !guidanceItems.isEmpty {
                DisclosureGroup("Guidance") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(guidanceItems.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .font(.caption)
            }

            if let onSetState, nudge.allowsDismissal, nudge.state == .suggested {
                HStack(spacing: 8) {
                    Button("Ignore") {
                        onSetState(.ignored)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("Not Required") {
                        onSetState(.notRequired)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            } else if let onClearState,
                      nudge.allowsDismissal,
                      nudge.state == .ignored || nudge.state == .notRequired {
                Button("Show Again") {
                    onClearState()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var stateBadge: some View {
        Text(label(for: nudge.state))
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color(for: nudge.state).opacity(0.14))
            .foregroundStyle(color(for: nudge.state))
            .clipShape(Capsule())
    }

    private func label(for state: SurveyNudgeState) -> String {
        switch state {
        case .suggested:
            return nudge.isPriority ? "Priority" : "Suggested"
        case .ignored:
            return "Ignored"
        case .fulfilled:
            return "Fulfilled"
        case .notRequired:
            return "Not Required"
        }
    }

    private func color(for state: SurveyNudgeState) -> Color {
        switch state {
        case .suggested:
            return nudge.isPriority ? .red : .blue
        case .ignored:
            return .secondary
        case .fulfilled:
            return .green
        case .notRequired:
            return .orange
        }
    }
}
#endif
