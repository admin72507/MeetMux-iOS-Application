import SwiftUI
import CoreHaptics

struct ThemeSwitcherScene: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: Int = 0
    @State private var hapticEngine: CHHapticEngine?
    @Namespace private var animation
    
    private let themes: [AppColorScheme] = AppColorScheme.allCases
    
    var body: some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()
                .animation(.easeInOut, value: selectedIndex)
            
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    ForEach(themes.indices, id: \.self) { index in
                        let theme = themes[index]
                        ThemeCard(theme: theme, isSelected: index == selectedIndex)
                            .scaleEffect(index == selectedIndex ? 1.0 : 0.85)
                            .rotationEffect(.degrees(index == selectedIndex ? 0 : -5))
                            .offset(x: CGFloat(index - selectedIndex) * 20, y: CGFloat(abs(index - selectedIndex) * 10))
                            .zIndex(index == selectedIndex ? 1 : 0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    if index == selectedIndex {
                                        // Already selected? Move to next
                                        selectedIndex = (selectedIndex + 1) % themes.count
                                    } else {
                                        // Tap on a different card? Bring it to front
                                        selectedIndex = index
                                    }
                                    selectTheme(themes[selectedIndex])
                                }
                            }
                    }
                }
                .frame(height: 300)
                
                HStack(spacing: 8) {
                    ForEach(themes.indices, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? ThemeManager.foregroundColor : ThemeManager.foregroundColor.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            prepareHaptics()
            let saved = UserDefaults.standard.string(forKey: DeveloperConstants.UserDefaultsInternal.themeSelectedByUser)
            let savedTheme = AppColorScheme(rawValue: saved ?? "") ?? .system
            selectedIndex = themes.firstIndex(of: savedTheme) ?? 0
        }
        .generalNavBarInControlRoom(
            title: "Choose Theme",
            subtitle: "Tap a card to apply",
            image: "paintbrush.fill",
            onBacktapped: { dismiss() }
        )
    }
    
    private func selectTheme(_ theme: AppColorScheme) {
        themeManager.selectedTheme = theme.rawValue
        UserDefaults.standard.setValue(theme.rawValue, forKey: DeveloperConstants.UserDefaultsInternal.themeSelectedByUser)
        playHaptic()
    }
    
    private var backgroundView: some View {
        switch themes[selectedIndex] {
            case .light:
                return AnyView(Color.white)
            case .dark:
                return AnyView(Color.black)
            case .system:
                return AnyView(
                    LinearGradient(colors: [.white, .black], startPoint: .top, endPoint: .bottom)
                )
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error.localizedDescription)")
        }
    }
    
    private func playHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let pattern = try CHHapticPattern(events: [
                .init(eventType: .hapticTransient,
                      parameters: [.init(parameterID: .hapticIntensity, value: 0.8),
                                   .init(parameterID: .hapticSharpness, value: 0.8)],
                      relativeTime: 0)
            ], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic failed: \(error.localizedDescription)")
        }
    }
}


struct ThemeCard: View {
    let theme: AppColorScheme
    let isSelected: Bool
    @EnvironmentObject var themeManager: AppThemeManager
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .symbolEffect(.bounce, value: animate)
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(theme == .dark ? ThemeManager.gradientNewPinkBackground : ThemeManager.gradientBackground)
                .onAppear { animate = true }
            
            Text(theme.displayName)
                .fontStyle(size: 18, weight: .semibold)
                .foregroundColor(ThemeManager.foregroundColor)
            
            Text(description)
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(ThemeManager.foregroundColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(width: 220, height: 260)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    private var icon: String {
        switch theme {
            case .light: return "sun.max.circle.fill"
            case .dark: return "moon.stars.circle.fill"
            case .system: return "gearshape.circle.fill"
        }
    }
    
    private var description: String {
        switch theme {
            case .light: return "Bright and uplifting look perfect for daytime use."
            case .dark: return "Comfortable and battery-saving theme ideal for nighttime."
            case .system: return "Automatically adjusts to match your device settings."
        }
    }
}

