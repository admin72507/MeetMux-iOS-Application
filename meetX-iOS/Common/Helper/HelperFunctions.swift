//
//  HelperFunctions.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 25-12-2024.
//

import SwiftUI
import AlertToast
import UIKit
import PhotosUI
import AVFoundation

final class HelperFunctions {

    // Format string
    func formatDateString(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            return dayFormatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let monthDayFormatter = DateFormatter()
            monthDayFormatter.dateFormat = "MMMM d"
            return monthDayFormatter.string(from: date)
        } else {
            let fullFormatter = DateFormatter()
            fullFormatter.dateFormat = "MMMM d, yyyy"
            return fullFormatter.string(from: date)
        }
    }

    // MARK: - Date Formatter in chat
    func parseMessageDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString)
    }

    // MARK: - Date Formatter
    static func formatDateFromString(_ dateString: String) -> String {
        // Assuming backend sends "yyyy-MM-dd" format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    
    // MARK: - UTC to hoursleft convertor
    static func convertUTCToISTAndCalculateDifference(utcString: String) -> (date: String, time: String, hoursFromNow: Double)? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Convert UTC string to Date
        guard let utcDate = isoFormatter.date(from: utcString) else {
            return nil
        }
        
        // TimeZone for IST
        let istTimeZone = TimeZone(identifier: "Asia/Kolkata")!
        
        // Format date part (dd MMM yyyy)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = istTimeZone
        dateFormatter.dateFormat = "dd MMM yyyy"
        let dateString = dateFormatter.string(from: utcDate)
        
        // Format time part to 12-hour format with AM/PM
        dateFormatter.dateFormat = "hh:mm a"
        let timeString = dateFormatter.string(from: utcDate)
        
        // Calculate time difference from now
        let now = Date()
        let differenceInSeconds = utcDate.timeIntervalSince(now)
        let differenceInHours = differenceInSeconds / 3600.0
        
        return (dateString, timeString, differenceInHours)
    }
    
    
    // MARK: - Mark time calculator
    static func calculateLiveTimeLeft(startDate: String?, endDate: String?, liveDuration: String?) -> String? {
        guard let startDateString = startDate,
              let endDateString = endDate else { return nil }
        
        // Create UTC timezone
        let utcTimeZone = TimeZone(abbreviation: "UTC")!
        
        // Create IST timezone
        _ = TimeZone(identifier: "Asia/Kolkata")!
        
        // Create date formatters for different possible formats
        let formatters = [
            DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                $0.timeZone = utcTimeZone
            },
            DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                $0.timeZone = utcTimeZone
            },
            DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                $0.timeZone = utcTimeZone
            },
            DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                $0.timeZone = utcTimeZone
            },
            DateFormatter().apply {
                $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
                $0.timeZone = utcTimeZone
            }
        ]
        
        // Parse start date
        var startDate: Date?
        for formatter in formatters {
            if let date = formatter.date(from: startDateString) {
                startDate = date
                break
            }
        }
        
        // Parse end date
        var endDate: Date?
        for formatter in formatters {
            if let date = formatter.date(from: endDateString) {
                endDate = date
                break
            }
        }
        
        guard let startDate = startDate, let endDate = endDate else {
            // Fallback to liveDuration if date parsing fails
            return "Duration: \(liveDuration ?? "Unknown Date")"
        }
        
        // Get current time in IST
        let now = Date()
        
        // Check if activity has started
        if now < startDate {
            return "Not Started Yet"
        }
        
        // Check if activity has ended
        if now > endDate {
            return "Activity Ended"
        }
        
        // Calculate remaining time (end time - current time)
        let timeInterval = endDate.timeIntervalSince(now)
        
        // Convert to hours and minutes
        let totalMinutes = Int(timeInterval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        // Format the remaining time
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m left"
            } else {
                return "\(hours)h left"
            }
        } else if minutes > 0 {
            return "\(minutes)m left"
        } else {
            return "Less than 1m left"
        }
    }
    
    // MARK: - Styled ASterik
    func styledAsteriskText(
        _ text: String,
        asteriskColor: Color = .red,
        baseColor: Color = ThemeManager.foregroundColor,
        asteriskFontSize: CGFloat = 14
    ) -> Text {
        let components = text.split(separator: "*", omittingEmptySubsequences: false)
        
        var result = Text("")
        
        for index in 0..<components.count {
            let part = String(components[index])
            result = result + Text(part).foregroundColor(baseColor)
            
            // If this is not the last component, it means there was a "*" after this part
            if index != components.count - 1 {
                result = result + Text("*")
                    .foregroundColor(asteriskColor)
                    .font(.system(size: asteriskFontSize, weight: .bold))
            }
        }
        
        return result
    }
    
    
    
    // MARK: - Image processing and appending
    // MARK: - Adding Image to array
    static func loadImageFromPicker(_ items: [PhotosPickerItem]) async -> [UIImage] {
        await withTaskGroup(of: UIImage?.self) { group in
            var images: [UIImage] = []
            for item in items {
                group.addTask {
                    return await self.loadAndResizeImage(from: item)
                }
            }
            
            for await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            return images
        }
    }
    
    // MARK: - Important Function for image compresion
    static func loadAndResizeImage(from item: PhotosPickerItem) async -> UIImage? {
        do {
            let imageData = try await item.loadTransferable(type: Data.self)
            if let data = imageData, let image = UIImage(data: data) {
                let originalSize = image.size
                let screenTargetWidth: CGFloat = DeveloperConstants.General.targetedScreenWidth
                let targetMinHeight: CGFloat = DeveloperConstants.General.targetedScreenWidth
                
                // Landscape image: resize to screen width
                if originalSize.width > originalSize.height {
                    let scale = screenTargetWidth / originalSize.width
                    let newSize = CGSize(
                        width: screenTargetWidth,
                        height: originalSize.height * scale
                    )
                    return image.resized(to: newSize)
                }
                
                // Portrait image with height > 300: return original
                if originalSize.height > targetMinHeight {
                    return image
                }
                
                // Portrait image with height <= 300: upscale
                let scale = targetMinHeight / originalSize.height
                let intermediateSize = CGSize(
                    width: originalSize.width * scale,
                    height: targetMinHeight
                )
                
                let scaledImage = image.resized(to: intermediateSize)
                
                // Then scale width to screen width
                let widthScale = screenTargetWidth / intermediateSize.width
                let finalSize = CGSize(
                    width: screenTargetWidth,
                    height: intermediateSize.height * widthScale
                )
                
                return scaledImage.resized(to: finalSize)
            }
        } catch {
            debugPrint("Error loading image: \(error.localizedDescription)")
        }
        return nil
    }
    
    func genderIDToString(_ genderID: Int) -> String {
        switch genderID {
            case 1:
                return Constants.menuMale
            case 0:
                return Constants.menuFemale
            case 10:
                return Constants.menuOthers
            default:
                return Constants.menuUnknow
        }
    }
    
    static func hasNotch(in geometry: EdgeInsets) -> Bool {
        return geometry.top > 20
    }
    
    static func hasBottomLine(in geometry: EdgeInsets) -> Bool {
        return geometry.bottom > 20
    }
    
    // MARK: - Custom Tab Bar Shape
    struct CustomTabBarShape: Shape {
        var cornerRadius: CGFloat
        
        init(cornerRadius: CGFloat) {
            self.cornerRadius = cornerRadius
        }
        
        func path(in rect: CGRect) -> Path {
            return Path { path in
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }
        }
    }
    
    func toastAtTopError(_ title : String, _ subtitle : String) -> AlertToast {
        return AlertToast(
            displayMode: .alert,
            type: .systemImage(DeveloperConstants.systemImage.alertToastErrorImage, .red),
            title: title,
            subTitle: subtitle)
    }
    
    func toastSystemImage(_ title : String, _ subtitle : String) -> AlertToast {
        return AlertToast(
            displayMode : .banner(.slide),
            type: .systemImage(DeveloperConstants.systemImage.photoUploadErrorImage, ThemeManager.staticPurpleColour),
            title: title,
            subTitle: subtitle)
    }
    
    func generalToastControlSystem(_ title : String, _ subtitle : String) -> AlertToast {
        return AlertToast(
            displayMode : .alert,
            type: .systemImage(DeveloperConstants.systemImage.generalToastImage, ThemeManager.staticPurpleColour),
            title: title,
            subTitle: subtitle)
    }
    
    func apiErrorToast(_ title : String, _ subtitle : String) -> AlertToast {
        return AlertToast(
            displayMode : .hud,
            type: .error(.red),
            title: title,
            subTitle: subtitle)
    }
    
    func apiErrorToastCenter(_ title : String, _ subtitle : String) -> AlertToast {
        return AlertToast(
            displayMode: .alert,
            type: .regular,
            title: title,
            subTitle: subtitle)
    }
}

// MARK: - View extensions

extension View {
    
    // MARK: - View Extension
    func glowEffect(isActive: Bool = true, color: Color = .red, radius: CGFloat = 10, intensity: Double = 0.4) -> some View {
        self.modifier(GlowEffect(isActive: isActive, color: color, radius: radius, intensity: intensity))
    }
    
    @ViewBuilder
    func applyNavBarConditionally(
        shouldShow: Bool,
        title: String,
        subtitle: String,
        image: String,
        onBackTapped: @escaping () -> Void
    ) -> some View {
        if shouldShow {
            self.generalNavBarInControlRoom(title: title, subtitle: subtitle, image: image, onBacktapped: onBackTapped)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func dashboardNavigationBar(title: String, onSearchTapped: @escaping () -> Void) -> some View {
        self.modifier(DashboardNavigationBarModifier(title: title, onSearchTapped: onSearchTapped))
    }
    
    func generalNavBarInControlRoom(title: String,subtitle: String,image : String, onBacktapped : @escaping () -> Void) -> some View {
        self.modifier(ControlGeneralNavBarModifier(title: title, subtitle: subtitle, image: image, onBackTapped: onBacktapped))
    }
    
    func generalNavBarInControlRoomWithSaveAction(
        title: String,
        subtitle: String,
        image: String,
        isSaveEnabled: Binding<Bool>,
        onBacktapped: @escaping () -> Void,
        onSavetapped: @escaping () -> Void
    ) -> some View {
        self.modifier(
            ControlSaveNavBarModifier(
                title: title,
                subtitle: subtitle,
                image: image,
                onBackTapped: onBacktapped,
                onSaveTapped: onSavetapped,
                isSaveEnabled: isSaveEnabled
            )
        )
    }
    
    func hideKeyboard() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func pressEffect() -> some View {
        self.modifier(AnimationHelper.PressEffect())
    }
    
    func styledTextField() -> some View {
        self
            .padding()
            .background(ThemeManager.backgroundColor)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .shadow(color: Color.purple.opacity(0.2), radius: 3, x: 0, y: 0)
    }
    
    
    //MARK: - Custom Navigation Bar
    /// Nav Bar with title and a back button with action
    func customNavigationBar(
        title: String,
        backButtonHidden: Bool = false,
        backAction: @escaping () -> Void) -> some View {
            
            self.modifier(CustomNavigationBar(title: title,backButtonHidden: backButtonHidden, backAction: backAction))
        }
    
    /// Nav bar with one icon set in the leading
    func customNavBarWithRightBarButton(
        title: String,
        tabIcon: String,
        tabIconColour: Color,
        backAction: @escaping () -> Void,
        rightBarButtonAction: @escaping () -> Void) -> some View {
            
            self.modifier(CustomNavigationBarWithRightTabIcon(
                title: title,
                tabIcon: tabIcon,
                tabIconColour : tabIconColour,
                backAction: backAction,
                tabBarAction: rightBarButtonAction))
        }
    
    /// Home Navigation Bar extension
    func customHomeNavigationBar(
        title: String,
        subtitle: String,
        profileImage: String = "",
        hasNotification: Bool = false,
        onTitleTapped: @escaping () -> Void,
        onSearchTapped: @escaping () -> Void,
        onNotificationTapped: @escaping () -> Void
    ) -> some View {
        self.modifier(CustomHomeNavigationBarDesign(
            title: title,
            subtitle: subtitle,
            profileImage: profileImage,
            hasNotification: hasNotification,
            onTitleTapped: onTitleTapped,
            onSearchTapped: onSearchTapped,
            onNotificationTapped: onNotificationTapped
        ))
    }
    
    // MARK: - Explore Navigation bar
    func customNavigationBarForExplore(
        title: String,
        onTitleTapped: @escaping () -> Void,
        onSearchTapped: @escaping () -> Void,
        filterTapped: @escaping () -> Void,
        hideFilterButton: Bool
    ) -> some View {
        self.modifier(CustomNavigationBarExploreScene(
            title: title,
            onTitleTapped: onTitleTapped,
            onSearchTapped: onSearchTapped,
            onFilterTapped: filterTapped,
            hideFilterButton: hideFilterButton
        ))
    }
    
    // MARK: - Create post
    func customNavBarForCreatePost(
        title: String,
        onPostTapped: @escaping () -> Void,
        postButtonEnabled: Bool
    ) -> some View {
        self.modifier(CustomNavigationBarCreatePostScene(
            title: title,
            onPostTapped: onPostTapped,
            postButtonEnabled: postButtonEnabled
        ))
    }
    
    // MARK: - Chat Scene Nav Bar
    func customNavigationBarForChatSystem(
        title: String,
        subtitle: String,
        onTitleTapped: @escaping () -> Void,
        onSearchTapped: @escaping () -> Void
    ) -> some View {
        self.modifier(CustomNavigationBarChatScene(
            title: title,
            subTitle : subtitle,
            onTitleTapped: onTitleTapped,
            onSearchTapped: onSearchTapped
        ))
    }
    
    
    // MARK: - Navigation Bar Generic
    func genericNavBar(
        title: String? = nil,
        backButtonImage: String? = "chevron.left",
        rightButtons: [(image: String, action: () -> Void)] = []
    ) -> some View {
        self.modifier(GenericNavigationBar(
            title: title,
            backButtonImage: backButtonImage,
            rightButtons: rightButtons
        ))
    }
    
    
    //MARK: - Loader Function
    func defaultLoader(_ isLoading: Bool) -> some View {
        self.modifier(ProgressiveLoader(isLoading: isLoading))
    }
    
    // MARK: - Main Button Style
    func applyCustomButtonStyle() -> some View {
        self.modifier(MainButtonStyle())
    }
    
    // MARK: - Secondary Button Style
    func applyCustomButtonStyleSecondary() -> some View {
        self.modifier(MainButtonStyleSecondary())
    }
    
    // MARK: - TextField Modifier
    func styledTextFieldSupport() -> some View {
        self
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1))
            .frame(height: 45)
    }
    
    // MARK: - Basic back Button Nav bar
    func customBackButtonNavToolBar(action: @escaping () -> Void) -> some View {
        self.modifier(CustomBackButtonModifier(onBack: action))
    }
}

// MARK: - Color Extensions

extension Color {
    static func dynamicBackground(for scheme: ColorScheme) -> Color {
        return scheme == .light ? Color.white : Color(.quaternarySystemFill)
    }
}

//
////MARK: - Destination Helper
//enum OTPNavigationDestination: Hashable {
//    case profileUpdateScene
//    case permissionHandlerScene
//    case homeScreen
//}



extension Image {
    @ViewBuilder
    func applyConditionalResizable(edgeInsets: EdgeInsets?) -> some View {
        if HelperFunctions.hasNotch(in: edgeInsets ?? EdgeInsets()) {
            self.scaledToFit()
        } else {
            self.resizable().scaledToFit()
        }
    }
}

// MARK: - Convert the UTC date to time
func timeAgoConvertor(
    from utcString: String,
    relativeTo now: Date = Date()
) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    
    guard let date = formatter.date(from: utcString) else { return "Unknown" }
    
    let istTimeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
    let calendar = Calendar.current
    let istNow = now.convertToTimeZone(istTimeZone, calendar: calendar)
    let istDate = date.convertToTimeZone(istTimeZone, calendar: calendar)
    
    let timeInterval = Int(istNow.timeIntervalSince(istDate)) // in seconds
    
    switch timeInterval {
        case ..<60:
            return "\(timeInterval) seconds ago"
        case ..<3600:
            let minutes = timeInterval / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        case ..<86400:
            let hours = timeInterval / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        case ..<604800:
            let days = timeInterval / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        case ..<2_592_000:
            let weeks = timeInterval / 604800
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        case ..<31_536_000:
            let months = timeInterval / 2_592_000
            return "\(months) month\(months == 1 ? "" : "s") ago"
        case ..<63_072_000:
            return "1 year ago"
        default:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeZone = istTimeZone
            return dateFormatter.string(from: istDate)
    }
}

extension Date {
    func convertToTimeZone(_ timeZone: TimeZone, calendar: Calendar) -> Date {
        let components = calendar.dateComponents(in: timeZone, from: self)
        return calendar.date(from: components) ?? self
    }
}

// MARK: - Handler for date String
func formatDateStringForPlannedActivity(_ inputDate: String) -> (
    formattedDateExtracted: String,
    formattedTime: String
) {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    inputFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
    let outputDateFormatter = DateFormatter()
    outputDateFormatter.dateFormat = "EEEE, MMMM d"
    outputDateFormatter.timeZone = TimeZone(identifier: "Asia/Kolkata") // IST
    
    let outputTimeFormatter = DateFormatter()
    outputTimeFormatter.dateFormat = "h:mm a"
    outputTimeFormatter.timeZone = TimeZone(identifier: "Asia/Kolkata") // IST
    
    if let date = inputFormatter.date(from: inputDate) {
        let formattedDate = outputDateFormatter.string(from: date)
        let formattedTime = outputTimeFormatter.string(from: date)
        return (formattedDate, formattedTime)
    }
    
    return (inputDate, "") // return raw input if parsing fails
}

// MARK: - JSON Helper For Encoding
extension JSONEncoder {
    static func encodeBody<T: Encodable>(_ model: T) -> Result<Data, APIError> {
        do {
            let data = try JSONEncoder().encode(model)
            return .success(data)
        } catch {
            return .failure(APIError.encodingFailure(underlyingError: error))
        }
    }
}

extension Set {
    var array: [Element] { Array(self) }
}

// MARK: - THumbnail fetcher for image
extension UIImage {
    static func thumbnailImage(for url: URL, at time: TimeInterval = 1.0) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, imageRef, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let imageRef = imageRef, result == .succeeded {
                    continuation.resume(returning: UIImage(cgImage: imageRef))
                } else {
                    continuation.resume(throwing: NSError(domain: "ThumbnailError", code: -1))
                }
            }
        }
    }
}


extension UIImage {
    /// Resize image while keeping aspect ratio, targeting max dimension (width or height)
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension String {
    var usernameWithAt: String {
        return self.hasPrefix("@") ? self : "@\(self)"
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }
}

// Extension to help with date formatter setup
extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

// MARK: - Red Asterisk
struct RedAsteriskTextView: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text(title)
                .fontStyle(size: 14, weight: .semibold)
            
            Text("*")
                .fontStyle(size: 14, weight: .semibold)
                .foregroundColor(.red)
        }
        .padding(.bottom, 5)
    }
}
