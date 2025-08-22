import SwiftUI

struct FilterBottomSheetView: View {
    @ObservedObject private var viewModel: ExploreViewModel
    @Binding var isPresented: Bool
    @State private var distanceValue: Double = 60.0
    @State private var selectedGender: GenderFilter = .all
    @State private var selectedInterests: Set<String> = []
    @State private var showResetAnimation = false
    
    enum GenderFilter: String, CaseIterable {
        case all = "Anyone"
        case male = "Men"
        case female = "Women"
        
        var icon: String {
            switch self {
                case .all: return "person.2.fill"
                case .male: return "person.fill"
                case .female: return "person.fill"
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        return distanceValue != 60.0 ||
        selectedGender != .all ||
        !selectedInterests.isEmpty
    }
    
    init(viewModel: ExploreViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
    }
    
    private func loadCurrentFilters() {
        distanceValue = viewModel.currentDistanceFilter
        selectedGender = GenderFilter(rawValue: viewModel.currentGenderFilter) ?? .all
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 32) {
                        // Distance Section
                        distanceSection
                        
                        // Gender Section
                        genderSection
                        
                        // Quick Actions
                    //    quickActionsSection
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
        }
        .onAppear {
            loadCurrentFilters()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(.systemBackground), location: 0.0),
                .init(color: Color(.systemGray6).opacity(0.3), location: 0.4),
                .init(color: Color(.systemBackground), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func applyFilters() {
        viewModel.currentDistanceFilter = distanceValue
        viewModel.currentGenderFilter = selectedGender.rawValue
        viewModel.applyFilters()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func resetFilters() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            distanceValue = 60.0
            selectedGender = .all
            selectedInterests.removeAll()
            showResetAnimation = true
        }
        
        viewModel.currentDistanceFilter = 60.0
        viewModel.currentGenderFilter = "All"
        viewModel.resetAllFilters()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showResetAnimation = false
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {

            // Header with enhanced styling
            HStack(alignment: .center, spacing: 16) {
                // Reset button with modern styling
                if hasActiveFilters {
                    Button(action: {
                        resetFilters()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .medium))
                            Text("Reset")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                        .scaleEffect(showResetAnimation ? 0.95 : 1.0)
                    }
                } else {
                    Spacer()
                        .frame(width: 70)
                }
                
                Spacer()
                
                // Title with better typography
                VStack(spacing: 2) {
                    Text("Filters")
                        .fontStyle(size: 18, weight: .semibold)
                        .foregroundColor(.primary)
                    
                    if hasActiveFilters {
                        Circle()
                            .fill(ThemeManager.gradientNewPinkBackground)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                // Apply and close buttons
                HStack(spacing: 12) {
                    Button(action: {
                        applyFilters()
                        isPresented = false
                    }) {
                        Text("Apply")
                            .fontStyle(size: 16, weight: .semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                ThemeManager.gradientNewPinkBackground
                            )
                            .cornerRadius(10)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .fontStyle(size: 20, weight: .semibold)
                        .foregroundColor(.primary)
                    
                    Text("Show people within")
                        .fontStyle(size: 14, weight: .light)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Distance value with modern styling
                HStack(spacing: 4) {
                    Text("\(Int(distanceValue))")
                        .fontStyle(size: 24, weight: .semibold)
                        .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                    
                    Text("km")
                        .fontStyle(size: 16, weight: .light)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.1))
                )
            }
            
            // Enhanced custom slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Active track with gradient
                    Capsule()
                        .fill(
                            ThemeManager.gradientBackground
                        )
                        .frame(width: max(20, geometry.size.width * CGFloat(distanceValue / 120.0)), height: 8)
                    
                    // Modern thumb
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                        .overlay(
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 12, height: 12)
                        )
                        .offset(x: max(0, min(geometry.size.width - 28, geometry.size.width * CGFloat(distanceValue / 120.0))))
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: distanceValue)
                }
            }
            .frame(height: 28)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let sliderWidth = UIScreen.main.bounds.width - 48
                        let newValue = (value.location.x / sliderWidth) * 120
                        distanceValue = max(5, min(120, newValue))
                        
                        // Light haptic feedback
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                    }
            )
            
            // Distance markers
            HStack {
                Text("5km")
                    .fontStyle(size: 12, weight: .light)
                
                Spacer()
                
                Text("120km")
                    .fontStyle(size: 12, weight: .light)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
    
    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Show me")
                    .fontStyle(size: 20, weight: .semibold)
                    .foregroundColor(.primary)
                
                Text("Who would you like to see?")
                    .fontStyle(size: 16, weight: .light)
                    .foregroundColor(.secondary)
            }
            
            // Modern segmented control style
            HStack(spacing: 4) {
                ForEach(GenderFilter.allCases, id: \.self) { gender in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedGender = gender
                        }
                        
                        // Haptic feedback
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: gender.icon)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(gender.rawValue)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(selectedGender == gender ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Group {
                                if selectedGender == gender {
                                    ThemeManager.gradientBackground
                                } else {
                                    Color(.systemGray6)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .scaleEffect(selectedGender == gender ? 1.02 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring()) {
                        distanceValue = 25.0
                        selectedGender = .all
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Nearby")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: {
                    withAnimation(.spring()) {
                        distanceValue = 100.0
                        selectedGender = .all
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text("Explore")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
}
