//
//  SegmentControl.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-03-2025.
//

import SwiftUI

struct CustomSegmentedControl<T: CaseIterable & Hashable>: View where T.AllCases: RandomAccessCollection {
    
    @Binding var selectedSegment: T
    @Namespace private var animationNamespace
    @Environment(\.colorScheme) private var colorScheme
    
    private let titleProvider: (T) -> String
    private let onSegmentChanged: (Int) -> Void
    private let showLiveIndicator: Bool
    
    init(
        selectedSegment: Binding<T>,
        titleProvider: @escaping (T) -> String,
        showLiveIndicator: Bool = false,
        onSegmentChanged: @escaping (Int) -> Void
    ) {
        self._selectedSegment = selectedSegment
        self.titleProvider = titleProvider
        self.showLiveIndicator = showLiveIndicator
        self.onSegmentChanged = onSegmentChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            let allCases = Array(T.allCases)
            let segmentWidth = geometry.size.width / CGFloat(allCases.count)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        colorScheme == .dark
                        ? ThemeManager.gradientBackground
                        : LinearGradient(
                            gradient: Gradient(colors: [.white, .white]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(segmentWidth - 8, 0), height: 35)
                    .offset(x: segmentOffset(segmentWidth, allCases: allCases))
                    .matchedGeometryEffect(id: "segmentBackground", in: animationNamespace)
                    .animation(.easeInOut(duration: 0.3), value: selectedSegment)
                    .frame(maxHeight: .infinity, alignment: .center)
                
                HStack(spacing: 0) {
                    ForEach(allCases, id: \.self) { type in
                        segmentView(for: type, width: segmentWidth, allCases: allCases)
                    }
                }
            }
        }
        .frame(height: 45)
        .background(colorScheme == .dark ? ThemeManager.darkBackground : ThemeManager.softPinkBackground)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func segmentOffset(_ segmentWidth: CGFloat, allCases: [T]) -> CGFloat {
        let selectedIndex = allCases.firstIndex(of: selectedSegment) ?? 0
        return CGFloat(selectedIndex) * segmentWidth + 4
    }
    
    @ViewBuilder
    private func segmentView(for type: T, width: CGFloat, allCases: [T]) -> some View {
        let isSelected = selectedSegment == type
        let index = allCases.firstIndex(of: type) ?? 0
        let isLiveSegment = index == 2 // third segment
        
        HStack(spacing: 6) {
            if showLiveIndicator && isLiveSegment {
                LiveIndicatorView()
            }
            
            Text(titleProvider(type))
                .fontStyle(size: 14, weight: isSelected ? .semibold : .light)
                .foregroundColor(
                    colorScheme == .dark
                    ? (isSelected ? .white : .gray)
                    : (isSelected ? ThemeManager.staticPurpleColour : .gray)
                )
        }
        .frame(width: max(width, 0), height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedSegment != type {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedSegment = type
                }
                if let newIndex = allCases.firstIndex(of: type) {
                    onSegmentChanged(newIndex)
                }
            }
        }
    }
}

struct LiveIndicatorView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(animate ? 1.8 : 1.0)
                .opacity(animate ? 0.0 : 1.0)
                .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: animate)
            
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            animate = true
        }
    }
}
