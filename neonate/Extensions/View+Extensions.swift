import SwiftUI

extension View {

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    func loading(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
    }

    func hideNavigationBar() -> some View {
        self.navigationBarHidden(true)
    }

    var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Liquid Glass Modifiers

struct LiquidGlassModifier: ViewModifier {
    var tintColor: Color
    var intensity: CGFloat
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass layer with blur
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(tintColor.opacity(0.1))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: cornerRadius)
                        )

                    // Gradient border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: tintColor.opacity(0.1 * intensity), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.05 * intensity), radius: 20, x: 0, y: 10)
    }
}

struct LiquidGlassCardModifier: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var glowColor: Color?

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor.opacity(0.08))
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            backgroundColor.opacity(0.2),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: (glowColor ?? backgroundColor).opacity(0.12),
                radius: 8, x: 0, y: 4
            )
    }
}

struct LiquidGlassButtonModifier: ViewModifier {
    var color: Color
    var isPressed: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(isPressed ? 0.3 : 0.2))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 16)
                        )

                    // Gradient overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            Color.white.opacity(0.4),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: color.opacity(0.3), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isPressed)
    }
}

struct GlassTextFieldModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.15))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: cornerRadius)
                        )

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
    }
}

// MARK: - Legacy Card Modifier (для обратной совместимости)

struct CardModifier: ViewModifier {
    var backgroundColor: Color = .white
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - View Extensions

extension View {

    // Liquid Glass Styles
    func liquidGlass(
        tintColor: Color = .blue,
        intensity: CGFloat = 1.0,
        cornerRadius: CGFloat = 20
    ) -> some View {
        modifier(LiquidGlassModifier(
            tintColor: tintColor,
            intensity: intensity,
            cornerRadius: cornerRadius
        ))
    }

    func liquidGlassCard(
        backgroundColor: Color = .blue,
        cornerRadius: CGFloat = 20,
        glowColor: Color? = nil
    ) -> some View {
        modifier(LiquidGlassCardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            glowColor: glowColor
        ))
    }

    func liquidGlassButton(color: Color = .blue, isPressed: Bool = false) -> some View {
        modifier(LiquidGlassButtonModifier(color: color, isPressed: isPressed))
    }

    func glassTextField(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassTextFieldModifier(cornerRadius: cornerRadius))
    }

    // Legacy card style
    func cardStyle(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 5
    ) -> some View {
        modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius
        ))
    }
}
