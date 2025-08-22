//
//  DateAndTimePickerScene.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 28-05-2025.
//

import SwiftUI

struct DateAndTimePickerScene: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    var onDone: (Date) -> Void
    
    @State private var tempSelectedDate: Date = Date()
    
    private var isSelectionValid: Bool {
        tempSelectedDate > Date()
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Custom toolbar
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .tint(.gray)
                .fontStyle(size: 16, weight: .semibold)
                
                Spacer()
                
                Button("Done") {
                    selectedDate = tempSelectedDate
                    onDone(tempSelectedDate)
                    isPresented = false
                }
                .tint(isSelectionValid ? ThemeManager.staticPinkColour : .gray.opacity(0.5))
                .disabled(!isSelectionValid)
                .fontStyle(size: 16, weight: .semibold)
            }
            
            // Graphical Date Picker
            DatePicker("Date",
                       selection: $tempSelectedDate,
                       in: Date()...,
                       displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .tint(ThemeManager.gradientNewPinkBackground)
            
            // Time Picker
            DatePicker("Time",
                       selection: $tempSelectedDate,
                       in: timeRangeForSelectedDate(),
                       displayedComponents: [.hourAndMinute])
            .datePickerStyle(.compact)
            .tint(ThemeManager.gradientNewPinkBackground)
        }
        .padding(24)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            tempSelectedDate = selectedDate
        }
    }
    
    private func timeRangeForSelectedDate() -> ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(tempSelectedDate) {
            return now...calendar.date(byAdding: .day, value: 7, to: now)!
        } else {
            let startOfDay = calendar.startOfDay(for: tempSelectedDate)
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: tempSelectedDate)!
            return startOfDay...endOfDay
        }
    }
}
