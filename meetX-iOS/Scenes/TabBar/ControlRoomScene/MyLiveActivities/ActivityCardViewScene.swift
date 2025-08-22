//
//  EnhancedActivityCardView.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 08-06-2025.
//

import SwiftUI
import Kingfisher
import AVFoundation

struct ActivityCardView: View {
    let activity: PostItem
    let onEndActivity: (String) -> Void
    let onOptionsPressed: (PostItem) -> Void
    let onPeopleTagPressed: ([PeopleTags]) -> Void
    let onJoinedUserIconTapped: ([PeopleTags]) -> Void
    let onLikeTapped: (_ postId: String) -> Void
    let onCommentsTapped: (_ selectedPostId: String) -> Void
    
    @State private var isAnimatingButton = false
    @State private var showEndConfirmation = false
    @State private var isExpanded = false
    
    private var isLiveActivity: Bool {
        activity.postType?.lowercased() == "liveactivity"
    }
    
    private var activityTypeColor: Color {
        isLiveActivity ? Color.red : Color.orange
    }
    
    private var shouldShowExpandButton: Bool {
        (activity.caption?.count ?? 0) > 100
    }
    
    private var displayCaption: String {
        guard let caption = activity.caption, !caption.isEmpty else { return "" }
        
        if shouldShowExpandButton && !isExpanded {
            return String(caption.prefix(100)) + "..."
        }
        return caption
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with End Button - Always on top right
            HStack(alignment: .top) {
                // Live/Planned indicator with enhanced design
                HStack(spacing: 8) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: isLiveActivity ? [.red, .pink] : [.orange, .yellow],
                                center: .center,
                                startRadius: 2,
                                endRadius: 8
                            )
                        )
                        .frame(width: 12, height: 12)
                        .opacity(isLiveActivity ? 1.0 : 0.8)
                        .scaleEffect(isAnimatingButton && isLiveActivity ? 1.3 : 1.0)
                        .shadow(color: activityTypeColor.opacity(0.5), radius: isAnimatingButton ? 4 : 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isLiveActivity ? "LIVE NOW" : "PLANNED")
                            .fontStyle(size: 14, weight: .semibold)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isLiveActivity ? [.red, .pink] : [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        if isLiveActivity, let duration = HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: activity.endTime ?? "") {
                            Text("\(String(format: "%.1f", duration.hoursFromNow)) hrs Left")
                                .fontStyle(size: 12, weight: .regular)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // End Activity Button - Always visible on top right
                Button(action: {
                    showEndConfirmation = true
                }) {
                    HStack(spacing: 8) {
                        // Dynamic icon based on activity type
                        Image(systemName: isLiveActivity ? "stop.circle.fill" : "calendar.badge.minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimatingButton ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isAnimatingButton)
                        
                        Text(isLiveActivity ? "End Live" : "Cancel Plan")
                            .fontStyle(size: 13, weight: .bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if isLiveActivity {
                                // Red gradient for live activities
                                LinearGradient(
                                    colors: [ThemeManager.staticPinkColour, ThemeManager.staticPurpleColour],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                // Orange gradient for planned activities
                                LinearGradient(
                                    colors: [ThemeManager.staticPinkColour, ThemeManager.staticPurpleColour],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: (isLiveActivity ? Color.red : Color.orange).opacity(0.4),
                        radius: isAnimatingButton ? 8 : 4,
                        x: 0,
                        y: isAnimatingButton ? 4 : 2
                    )
                    .scaleEffect(isAnimatingButton ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnimatingButton)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 18) {
                // Caption Section with enhanced typography
                if let caption = activity.caption, !caption.isEmpty {
                    Text("Caption")
                        .fontStyle(size: 16, weight: .semibold)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(displayCaption)
                            .fontStyle(size: 12, weight: .medium)
                            .foregroundColor(ThemeManager.foregroundColor)
                            .lineLimit(isExpanded ? nil : 4)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                        
                        if shouldShowExpandButton {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(isExpanded ? "Show less" : "Show more")
                                }
                                .fontStyle(size: 12, weight: .semibold)
                                .foregroundStyle(
                                    ThemeManager.gradientNewPinkBackground
                                )
                            }
                        }
                    }
                }
                
                // Enhanced Location and Date Section
                locationDateSection
                
                // Enhanced Media Preview
                if let mediaFiles = activity.mediaFiles, !mediaFiles.isEmpty {
                    mediaPreview
                }
                
                // Tagged People with Overlapping Images
                if let peopleTags = activity.peopleTags, !peopleTags.isEmpty {
                    taggedPeopleSection
                }
                
                // Activity Tags as Chips
                if let tags = activity.activityTags, !tags.isEmpty {
                    activityTagsChipsView
                }
                
                // Enhanced Stats and Options Section
                bottomSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemGray6).opacity(0.3),
                            Color(.systemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 12)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    isLiveActivity ?
                    LinearGradient(
                        colors: [.red.opacity(0.4), .pink.opacity(0.3), .red.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                        LinearGradient(
                            colors: [Color(.orange).opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: isLiveActivity ? 2 : 0.8
                )
        )
        .scaleEffect(0.98)
        .onAppear {
            if isLiveActivity {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    isAnimatingButton = true
                }
            }
        }
        .confirmationDialog("End Activity", isPresented: $showEndConfirmation) {
            Button("End Activity", role: .destructive) {
                if let activityId = activity.postID {
                    onEndActivity(activityId)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to end this activity? \n \n Make sure to end it before it ends automatically, because once it ends, you won't be able to re-start it")
        }
    }
    
    // MARK: - Subviews
    
    private var locationDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location & End Date")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundColor(ThemeManager.foregroundColor)
            
            if let location = activity.location {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24)
                    
                    Text(location)
                        .fontStyle(size: 12, weight: .regular)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ThemeManager.staticPinkColour.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(ThemeManager.staticPinkColour.opacity(0.15), lineWidth: 1.2)
                        )
                )
            }
            
            if let eventDate = activity.eventDate {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24)
                    
                    Text("\(HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: eventDate)?.date ?? "")")
                        .fontStyle(size: 12, weight: .regular)
                        .foregroundColor(ThemeManager.foregroundColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ThemeManager.staticPurpleColour.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(ThemeManager.staticPurpleColour.opacity(0.15), lineWidth: 1.2)
                        )
                )
            }
        }
    }
    
    private var mediaPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Media")
                    .fontStyle(size: 16, weight: .semibold)
                    .foregroundColor(ThemeManager.foregroundColor)
                
                Spacer()
                
                if let mediaCount = activity.mediaFiles?.count {
                    Text("\(mediaCount) \(mediaCount == 1 ? "item" : "items")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    ThemeManager.gradientBackground
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array((activity.mediaFiles ?? []).prefix(6).enumerated()), id: \.offset) { index, media in
                        EnhancedMediaHandleView(media: media, index: index, typeFrom: .MyActivities)
                    }
                    
                    if let mediaFiles = activity.mediaFiles, mediaFiles.count > 6 {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 150)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(
                                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                    
                                    Text("+\(mediaFiles.count - 6) more")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.gray.opacity(0.25), style: StrokeStyle(lineWidth: 2.5, dash: [10, 5]))
                            )
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }
    
    private var taggedPeopleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tagged People")
                    .fontStyle(size: 16, weight: .semibold)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // People count chip
                if let peopleCount = activity.peopleTags?.count, peopleCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(peopleCount)")
                            .fontStyle(size: 14, weight: .regular)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: .green.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
                }
            }
            
            // Overlapping profile images with enhanced design
            OverlappingProfileImages(peopleTags: activity.peopleTags ?? [])
        }
        .contentShape(Rectangle()) // Make entire area tappable, including spacing
        .onTapGesture {
            onPeopleTagPressed(activity.peopleTags ?? [])
        }
    }
    
    private var activityTagsChipsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Tags")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundColor(ThemeManager.foregroundColor)
            
            // Enhanced wrap layout for tags
            FlowLayout(spacing: 10) {
                ForEach((activity.activityTags?.first?.subcategories ?? []).prefix(12), id: \.id) { tag in
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text(tag.title ?? "")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1.2
                                    )
                            )
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: .blue.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    private var bottomSection: some View {
        HStack(alignment: .center, spacing: 24) {
            // Enhanced Stats with better spacing and design
            HStack(spacing: 36) {
                EnhancedStatView(
                    icon: activity.userContext?.hasLiked ?? false ? "heart.fill" : "heart",
                    count: activity.totalLikes ?? 0,
                    color: .red,
                    label: "Likes"
                )
                .onTapGesture {
                    onLikeTapped(activity.postID ?? "")
                }
                
                EnhancedStatView(
                    icon: "bubble.left.fill",
                    count: activity.totalComments ?? 0,
                    color: .blue,
                    label: "Comments"
                )
                .onTapGesture {
                    onCommentsTapped(activity.postID ?? "")
                }
                
                EnhancedStatView(
                    icon: "person.2.fill",
                    count: activity.totalJoinedUsers ?? 0,
                    color: .green, 
                    label: "Joined"
                )
                .onTapGesture {
                    onJoinedUserIconTapped(activity.joinedUserTags ?? [])
                }
            }
            
            Spacer()
            
            // Enhanced Options Button
            Button(action: {
                onOptionsPressed(activity)
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                    )
            }
            .hidden()
            .scaleEffect(0.95)
            .animation(.easeInOut(duration: 0.15), value: false)
        }
        .padding(.top, 12)
    }
}

// MARK: - Overlapping Profile Images
struct OverlappingProfileImages: View {
    let peopleTags: [PeopleTags]
    private let maxVisible = 6
    private let imageSize: CGFloat = 48
    private let overlap: CGFloat = 16
    
    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(peopleTags.prefix(maxVisible).enumerated()), id: \.offset) { index, person in
                KFImage(URL(string: person.profilePicUrl))
                    .placeholder {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.25), .gray.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    .zIndex(Double(maxVisible - index))
            }
            
            // Show +more indicator if there are more people
            if peopleTags.count > maxVisible {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.95), .purple.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Text("+\(peopleTags.count - maxVisible)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.leading, 8)
    }
}

// MARK: - Enhanced Stat View
struct EnhancedStatView: View {
    let icon: String
    let count: Int
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                if count != -1 {
                    Text("\(count)")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        let totalHeight = rows.reduce(0) { result, row in
            result + row.maxHeight + (rows.count > 1 ? spacing : 0)
        }
        
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
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
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRow.width + size.width + spacing > maxWidth && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
            }
            
            currentRow.add(subview: subview, size: size, spacing: spacing)
        }
        
        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var subviews: [LayoutSubview] = []
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        mutating func add(subview: LayoutSubview, size: CGSize, spacing: CGFloat) {
            if !subviews.isEmpty {
                width += spacing
            }
            subviews.append(subview)
            width += size.width
            maxHeight = max(maxHeight, size.height)
        }
    }
}
