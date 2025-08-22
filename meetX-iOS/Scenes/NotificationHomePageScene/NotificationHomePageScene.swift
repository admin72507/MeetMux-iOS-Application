////
////  NotificationHomePageScene.swift
////  meetX-iOS
////
////  Created by Karthick Thavasimuthu on 06-03-2025.
////
import SwiftUI
import Kingfisher
import AlertToast

// MARK: - All
//new_post
//like,
//comment
//,activity_interest_accept
//,activity_interest_request --> Show accept and decline button ,
//follow_accepted ---> someon acepted your follow request
//follow_request --> sent you a follow request --> show accept and decline button,
//follow --> someone started following you,
//comment_like---> comment liked
//comment_reply --> comment reply
//chat_connection_request ---> Connection Request
//chat_connection_accept ---> Connection Request accepted

// MARK: - Activity
//activity_interest_request --> Show accept and decline button,
//follow_request --> sent you a follow request --> show accept and decline button,
//chat_connection_request ---> Connection Request show accept and decline button,

// MARK: - Main Notification View
struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            headerView
            
            // Filter chips
            if !viewModel.availableFilters.isEmpty {
                filterChipsView
            }
            
            // Content
            contentView
        }
        .refreshable {
            await viewModel.refreshNotifications()
        }
        .toast(isPresenting: $viewModel.errorToast, alert: {
            HelperFunctions().apiErrorToastCenter("Notifications !!", viewModel.errorMessage ?? "")
        })
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            
            CustomSegmentedControl(
                selectedSegment: $viewModel.selectedTab,
                titleProvider: { tab in
                    switch tab {
                        case .all:
                            return "All (\(viewModel.allNotificationCount))"
                        case .activity:
                            return "Activity (\(viewModel.activityNotificationCount))"
                    }
                },
                onSegmentChanged: { index in
                    let selected = NotificationTab.allCases[index]
                    viewModel.selectedTab = selected
                    viewModel.selectFilter(nil)
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private var filterChipsView: some View {
        FlowLayout(spacing: 8) {
            // All chip
            FilterChip(
                title: "All",
                isSelected: viewModel.selectedFilter == nil
            ) {
                viewModel.selectFilter(nil)
            }
            
            // Type-specific chips
            ForEach(viewModel.availableFilters, id: \.self) { filter in
                FilterChip(
                    title: filter.displayName,
                    isSelected: viewModel.selectedFilter == filter
                ) {
                    viewModel.selectFilter(filter)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // Custom FlowLayout for wrapping chips
    struct FlowLayout: Layout {
        let spacing: CGFloat
        
        init(spacing: CGFloat = 8) {
            self.spacing = spacing
        }
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            let height = rows.reduce(0) { result, row in
                result + row.maxHeight + (result > 0 ? spacing : 0)
            }
            return CGSize(width: proposal.width ?? 0, height: height)
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            var yOffset = bounds.minY
            
            for row in rows {
                var xOffset = bounds.minX
                
                for subview in row.subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    subview.place(at: CGPoint(x: xOffset, y: yOffset), proposal: ProposedViewSize(size))
                    xOffset += size.width + spacing
                }
                
                yOffset += row.maxHeight + spacing
            }
        }
        
        private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
            var rows: [Row] = []
            var currentRow = Row()
            var currentWidth: CGFloat = 0
            let maxWidth = proposal.width ?? .infinity
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentWidth + size.width > maxWidth && !currentRow.subviews.isEmpty {
                    rows.append(currentRow)
                    currentRow = Row()
                    currentWidth = 0
                }
                
                currentRow.subviews.append(subview)
                currentRow.maxHeight = max(currentRow.maxHeight, size.height)
                currentWidth += size.width + spacing
            }
            
            if !currentRow.subviews.isEmpty {
                rows.append(currentRow)
            }
            
            return rows
        }
        
        struct Row {
            var subviews: [LayoutSubview] = []
            var maxHeight: CGFloat = 0
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
            case .loading:
                loadingView
            case .loaded:
                notificationsList
            case .error(let message):
                errorView(message)
            case .empty:
                emptyView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(ThemeManager.staticPinkColour)
            Text("Loading notifications...")
                .fontStyle(size: 12, weight: .light)
                .foregroundStyle(ThemeManager.foregroundColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notificationsList: some View {
        List {
            let groupedNotifications = Dictionary(grouping: viewModel.filteredNotifications) { notification -> String in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                
                guard let utcDate = formatter.date(from: notification.createdAt) else {
                    return "Old"
                }
                
                // Convert to IST like in timeAgoConvertor
                let istTimeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
                let calendar = Calendar.current
                let istNow = Date().convertToTimeZone(istTimeZone, calendar: calendar)
                let istDate = utcDate.convertToTimeZone(istTimeZone, calendar: calendar)
                
                // Use the IST converted date for grouping
                let date = istDate
                
                let now = istNow // Use IST now instead of UTC now
                
                // Check if it's today
                if calendar.isDateInToday(date) {
                    return "Today"
                }
                
                // Get the start of current week and last week
                guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                    return "Old"
                }
                
                // Check if it's this week (but not today)
                if date >= currentWeekStart && !calendar.isDateInToday(date) {
                    return "This Week"
                }
                
                // Check if it's last week
                guard let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else {
                    return "Old"
                }
                
                if date >= lastWeekStart && date < currentWeekStart {
                    return "Last Week"
                }
                
                // Everything else is old
                return "Old"
            }
            
            let orderedSections = ["Today", "This Week", "Last Week", "Old"]
            
            ForEach(orderedSections, id: \.self) { section in
                if let notifications = groupedNotifications[section], !notifications.isEmpty {
                    Section(header: Text(section).foregroundColor(.secondary)) {
                        ForEach(notifications) { notification in
                            NotificationRow(
                                notification: notification,
                                onAccept: { viewModel.acceptNotification(notification) },
                                onDecline: { viewModel.declineNotification(notification) }, onProfileTap: { viewModel.moveUserToSenderProfile(for: notification.sender?.userId ?? "")
                                }
                            )
                            .onAppear {
                                // Load more when reaching the last item
                                if viewModel.shouldLoadMore(for: notification) {
                                    viewModel.loadMoreNotifications()
                                }
                            }
                        }
                    }
                }
            }
            
            // Loading indicator for pagination
            if viewModel.isLoadingMore {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(ThemeManager.staticPinkColour)
                        Text("Loading more...")
                            .fontStyle(size: 12, weight: .light)
                            .foregroundStyle(ThemeManager.foregroundColor)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refreshNotifications()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            
            Text(message)
                .fontStyle(size: 16, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
                .multilineTextAlignment(.center)
            
            Text("Please try to reload the page.")
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.retryLoading()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                    Text("Retry")
                        .fontStyle(size: 14, weight: .regular)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ThemeManager.staticPinkColour.opacity(0.1))
                .foregroundColor(ThemeManager.staticPinkColour)
                .clipShape(Capsule())
                .shadow(color: ThemeManager.staticPinkColour.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
        )
    }
    
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
            
            Text("No New Notifications")
                .fontStyle(size: 16, weight: .regular)
                .foregroundColor(ThemeManager.foregroundColor)
            
            Text("You're all caught up! Check back later for new notifications.")
                .fontStyle(size: 14, weight: .light)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isSelected ? 14 : 12, weight: isSelected ? .semibold : .regular))
                .lineLimit(1) // ✅ Prevent text wrapping
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ThemeManager.staticPurpleColour : .gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .fixedSize() // ✅ Prevent vertical expansion
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Row Component
struct NotificationRow: View {
    let notification: NotificationItem
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onProfileTap: () -> Void // Add profile tap handler
    
    private var notificationType: NotificationType? {
        NotificationType(rawValue: notification.type)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image - Now tappable
            Button(action: onProfileTap) {
                KFImage(URL(string: notification.sender?.profilePicUrl ?? ""))
                    .placeholder {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray4))
                            
                            Text(notification.sender?.name.prefix(1).uppercased() ?? "?")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(notification.sender?.name ?? "")
                            .fontStyle(size: 16, weight: .semibold)
                            .padding(.bottom, 5)
                        
                        Text(notification.message)
                            .fontStyle(size: 14, weight: .light)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(timeAgoConvertor(from: notification.createdAt))
                            .fontStyle(size: 12, weight: .light)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
                
                // Action buttons for specific notification types
                if notificationType?.needsActionButtons == true {
                    HStack(spacing: 12) { // Increased spacing to prevent accidental taps
                                          // Decline Button
                        Button(action: {
                            onDecline()
                        }) {
                            Text("Decline")
                                .fontStyle(size: 14, weight: .medium)
                                .foregroundColor(.purple)
                                .frame(minWidth: 80) // Set minimum width
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.purple, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevent interference
                        .contentShape(Rectangle()) // Define tap area explicitly
                        
                        // Accept Button
                        Button(action: {
                            onAccept()
                        }) {
                            Text("Accept")
                                .fontStyle(size: 14, weight: .medium)
                                .foregroundStyle(.white)
                                .frame(minWidth: 80) // Set minimum width
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(ThemeManager.gradientNewPinkBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle()) // Prevent interference
                        .contentShape(Rectangle()) // Define tap area explicitly
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.top, 5)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Make entire row tappable when no action buttons
        .onTapGesture {
            // Only handle row tap if no action buttons are present
            if notificationType?.needsActionButtons != true {
                onProfileTap()
            }
        }
    }
    
    private func extractUsernameFromMessage() -> String {
        let message = notification.message
        if let atIndex = message.firstIndex(of: "@") {
            let startIndex = message.index(after: atIndex)
            if let spaceIndex = message[startIndex...].firstIndex(of: " ") {
                return String(message[atIndex..<spaceIndex])
            } else {
                return String(message[atIndex...])
            }
        }
        return notification.sender?.username ?? ""
    }
    
    private func extractActionFromMessage() -> String {
        let message = notification.message
        if let spaceIndex = message.firstIndex(of: " ") {
            return String(message[message.index(after: spaceIndex)...])
        }
        return message
    }
}

// MARK: - Preview
struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
