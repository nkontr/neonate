import SwiftUI

struct OnboardingView: View {

    @State private var currentPage: Int = 0
    @State private var showLoginView: Bool = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "heart.circle.fill",
            title: "Добро пожаловать в neonate",
            description: "Ваш персональный помощник по уходу за малышом",
            color: .pink
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "Отслеживайте важные события",
            description: "Кормление, сон, смена подгузников и многое другое",
            color: .blue
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Получайте напоминания",
            description: "Никогда не пропускайте важные моменты",
            color: .orange
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Анализируйте прогресс",
            description: "Следите за развитием вашего малыша",
            color: .green
        )
    ]

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    pages[currentPage].color.opacity(0.3),
                    pages[currentPage].color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            VStack(spacing: 0) {

                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: { showLoginView = true }) {
                            Text("Пропустить")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 450)

                pageIndicator

                Spacer()

                actionButton
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                    .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.vertical, 20)
    }

    private var actionButton: some View {
        Button(action: handleAction) {
            Text(currentPage == pages.count - 1 ? "Начать" : "Далее")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(pages[currentPage].color)
                .cornerRadius(12)
        }
    }

    private func handleAction() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            showLoginView = true
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.color)
            }

            VStack(spacing: 15) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }
}

#if Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif
