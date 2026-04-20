import SwiftUI

extension View {

    func makeAccessible(
        label: String,
        value: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .modifier(OptionalAccessibilityValue(value: value))
            .modifier(OptionalAccessibilityHint(hint: hint))
            .modifier(OptionalAccessibilityTraits(traits: traits))
    }

    func cardAccessibility(
        title: String,
        value: String,
        description: String? = nil
    ) -> some View {
        let fullLabel = description != nil
            ? "\(title): \(value). \(description!)"
            : "\(title): \(value)"

        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(fullLabel)
            .accessibilityAddTraits(.isStaticText)
    }

    func buttonAccessibility(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .modifier(OptionalAccessibilityHint(hint: hint))
            .accessibilityAddTraits(.isButton)
            .modifier(ConditionalAccessibilityTrait(
                condition: !isEnabled,
                trait: .isButton
            ))
    }

    func chartAccessibility(
        title: String,
        summary: String,
        details: String? = nil
    ) -> some View {
        let fullDescription = details != nil
            ? "\(title). \(summary). \(details!)"
            : "\(title). \(summary)"

        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(fullDescription)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityAddTraits(.updatesFrequently)
    }

    func formFieldAccessibility(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value.isEmpty ? String(localized: "a11y_empty_field", defaultValue: "Пусто") : value)
            .modifier(OptionalAccessibilityHint(hint: hint))
    }

    func toggleAccessibility(label: String, isOn: Bool) -> some View {
        let state = isOn
            ? String(localized: "a11y_toggle_on", defaultValue: "Включено")
            : String(localized: "a11y_toggle_off", defaultValue: "Выключено")

        return self
            .accessibilityLabel(label)
            .accessibilityValue(state)
            .accessibilityAddTraits(.isButton)
    }

    func eventRowAccessibility(
        type: String,
        time: String,
        details: String? = nil
    ) -> some View {
        let fullLabel = details != nil
            ? "\(type), \(time). \(details!)"
            : "\(type), \(time)"

        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(fullLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(String(localized: "a11y_tap_for_details", defaultValue: "Коснитесь для просмотра деталей"))
    }

    func emptyStateAccessibility(
        message: String,
        actionLabel: String? = nil
    ) -> some View {
        let fullLabel = actionLabel != nil
            ? "\(message). \(actionLabel!)"
            : message

        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(fullLabel)
    }

    func sectionAccessibility(title: String) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(title)
    }

    func loadingAccessibility(message: String = "") -> some View {
        let label = message.isEmpty
            ? String(localized: "a11y_loading", defaultValue: "Загрузка")
            : message

        return self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.updatesFrequently)
    }

    func alertAccessibility(message: String, isError: Bool = false) -> some View {
        let prefix = isError
            ? String(localized: "a11y_error_prefix", defaultValue: "Ошибка")
            : String(localized: "a11y_alert_prefix", defaultValue: "Внимание")

        return self
            .accessibilityLabel("\(prefix): \(message)")
            .accessibilityAddTraits(.isStaticText)
    }

    func ensureMinimumTouchTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
    }

    func groupAccessibility(label: String) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
    }

    func hideFromAccessibility() -> some View {
        self
            .accessibilityHidden(true)
    }

    func frequentlyUpdatingAccessibility() -> some View {
        self
            .accessibilityAddTraits(.updatesFrequently)
    }

    func imageAccessibility(description: String? = nil, isDecorative: Bool = false) -> some View {
        Group {
            if isDecorative {
                self.accessibilityHidden(true)
            } else if let description = description {
                self
                    .accessibilityLabel(description)
                    .accessibilityAddTraits(.isImage)
            } else {
                self
            }
        }
    }

    func navigationAccessibility(destination: String, label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(String(localized: "a11y_navigates_to", defaultValue: "Переход к \(destination)"))
            .accessibilityAddTraits(.isButton)
    }

    func badgeAccessibility(count: Int, description: String) -> some View {
        let countString = String(localized: "a11y_count_items", defaultValue: "\(count) \(description)")

        return self
            .accessibilityLabel(countString)
            .accessibilityAddTraits(.isStaticText)
    }
}

private struct ConditionalAccessibilityTrait: ViewModifier {
    let condition: Bool
    let trait: AccessibilityTraits

    func body(content: Content) -> some View {
        Group {
            if condition {
                content.accessibilityRemoveTraits(trait)
            } else {
                content
            }
        }
    }
}

private struct OptionalAccessibilityValue: ViewModifier {
    let value: String?

    func body(content: Content) -> some View {
        Group {
            if let value = value {
                content.accessibilityValue(value)
            } else {
                content
            }
        }
    }
}

private struct OptionalAccessibilityHint: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        Group {
            if let hint = hint {
                content.accessibilityHint(hint)
            } else {
                content
            }
        }
    }
}

private struct OptionalAccessibilityTraits: ViewModifier {
    let traits: AccessibilityTraits?

    func body(content: Content) -> some View {
        Group {
            if let traits = traits {
                content.accessibilityAddTraits(traits)
            } else {
                content
            }
        }
    }
}

#if DEBUG
extension View {

    func debugAccessibilityFrame(color: Color = .red) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .stroke(color, lineWidth: 1)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            )
    }

    func debugAccessibilityLabel() -> some View {
        self
            .background(
                Color.yellow.opacity(0.3)
            )
    }
}
#endif
