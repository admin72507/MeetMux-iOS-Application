//
//  Constants.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 24-12-2024.
//

import Foundation

enum Constants {
    
    //Intro Screens
    static let introData: [IntroItem] = [
        IntroItem(
            lightIcon: "intro1Light",
            darkIcon: "intro1Dark",
            description: "Discover spontaneous hangouts, live events, and real-time plans happening near you—join in instantly!",
            title: "Real-Time Meetups, Anytime!"
        ),
        
        IntroItem(
            lightIcon: "intro2Light",
            darkIcon: "intro2Dark",
            description: "Chat, call, and coordinate plans without switching apps. Your social life—streamlined.",
            title: "All-in-One Planning Made Easy"
        ),
        
        IntroItem(
            lightIcon: "intro3Light",
            darkIcon: "intro3Dark",
            description: "Dive into trending activities, match with like-minded people, and never miss out on the fun.",
            title: "Explore, Connect & Go!"
        )
    ]

    static let firstTabBarTitle     = "Home"
    static let secondTabBarTitle    = "Explore"
    static let thirdTabBarTitle     = "Messages"
    static let fourthTabBarTitle    = "Settings"
    static let genericTitleError    = "Oops 😬"
    static let chatTitleWithEmoji   = "Chat 💬"

    //Login Register
    static let loginTitle           = "Login or Register"
    static let loginSubtitle        = """
    
    """
    static let placeHolderText      = "Enter your Mobile Number"
    static let acceptText           = "I accept"
    static let termsConditiontext   = "Terms of use"
    static let continueText         = "Continue"
    static let errorTitle           = "Error"
    static let validMobileNumber    = "Please enter a valid Mobile Number"
    static let needHelp             = "Need Help?"
    static let connectText          = "Contact Support"
    static let phoneNumberError     = "Please check Mobile Number"
    static let isTermsCondition     = "Please accept Terms and Condition"
    
    //OTP Page
    static let otpTitle            = "Mobile Number Verification"
    static let otpSubtitle         = "Enter the code sent to your mobile via SMS."
    static let otpResendTitle      = "Resend"
    static let otpResendSubtitle   = "If you didn’t receive a code?"
    static let toastErrorTitle     = "OTP!"
    static let toastSubTitle       = "Please enter valid verification code"
    
    //Profile Updation Page
    // Error Messages
    static let minImagesRequired   = "Upload at least 1 image."
    static let emptyUsername       = "Username is required."
    static let bioEmptyMessage     = "Bio is required, Since you are new here."
    static let emptyEmail          = "Enter a valid email."
    static let invalidEmail        = "Invalid email. Check and try again."
    static let emptyGender         = "Select a gender."
    static let emptyDate           = "Enter a valid date."
    static let userAgeLimit        = "Must be 12+ to register."
    static let activityNotSelected = "Select at least one activity."
    static let verificationPhoto   = "Kindly capture a verification photo of yourself."

    static let choosePhotoTitle    = "Choose Photo"
    static let cameraClick         = "Take Photo"
    static let choosePhotoOrVideo  = "Choose Photo or Video"
    static let recordVideo         = "Record Video"
    static let updateProfileTitle  = "Update Profile"
    static let saveButtonText      = "Save Changes"
    static let saveText            = "Save"
    static let uploadPhotoTitle    = "Upload Picture"
    static let mandatoryPhotoCount = "A minimum of 1 image is mandatory"
    static let photoAccessDenied   = "Photo Access Denied"
    static let settingsTitle       = "Settings"
    static let cancelText          = "Cancel"
    static let photoDeniedMessage  = "Allow access to Photos Gallary or Camera in Settings to upload media  "
    static let photoDeniedPostSection  = "Please allow access to Photos Library or Camera in Settings to upload media to your post"
    static let photoVerification   = "Photo Verification"
    static let photoVerificationDesc = """
Upload a clear, well-lit selfie for identity verification.
"""
    static let bioSectionTitle     = "Bio / About"
    static let bioSectionSubTitle  = "VisualVibes, LifeUnfiltered, Wanderlust, StyleInspo, NowPlaying, SelfLoveClub, RealTalk - Speak your mind here."
    static let bioLimitReached     = "Bio limit reached"
    static let bioErrorBodyLimit   = "Bio Limited to 150 characters"
    static let bioPlaceholder      = "Add your bio"
    static let openCamera          = "Open Camera"
    static let retakePhoto         = "Retake Photo"
    static let fullName            = "Full Name"
    static let fullNameDesc        = """
Your chosen name will be used to create a unique username, visible in your Profile and used across the platform.
"""
    static let changeYourDisplayName = "Change Your Display Name"
    static let fullNamePlaceholder = "Enter your full name"
    static let fullNameErrorTitle  = "Name Limit Reached"
    static let fullNameErrorBody   = "Please enter username under 20 characters"
    static let emailAddressTitle   = "Email Address"
    static let enterPrimaryEmail   = "Please enter your primary email"
    static let enterEmail          = "Enter your email"
    static let emailVerificationFail = "Email Validation Failed"
    static let emailError          = "Please enter valid email"
    static let genderTitle         = "Gender"
    static let genderDesc          = "Identify yourself"
    static let menuFemale          = "Female"
    static let menuMale            = "Male"
    static let menuOthers          = "Others"
    static let menuUnknow          = "Gender"
    static let dateOfBirth         = "Date of Birth"
    static let dateOfBirthDesc     = "Please select your Date of Birth"
    static let selectDatrOfBirth   = "Select Date of Birth"
    
    // Activities / Hobbies / Interest Scene
    static let pageTitleActivities  = "Activities / Hobbies / Interest"
    static let pageTitleMain        = "Activities / Hobbies / Interest"
    static let pageDescription      = "Please select all the activities that you enjoy."
    static let searchText           = "Search by"
    static let sortButton           = "Selected Activities / Hobbies / Interest -"
    static let resetButton          = "Reset"
    static let saveReturnButton     = "Save & Return"
    static let filterByCategory     = "Filter By Category"
    static let filterByDesc         = "Please select all the category that interest you"
    static let viewLess             = "Show Less"
    static let viewMore             = "Show More"
    static let noSearchResultFound  = "No search result found, Please try again with different keywords"
    static let selectedMainActivites = "Selected Activities - "
    
    //Need Help / Connect Us
    static let submitRequest         = "Submit Request"
    static let sendEmailToSupport    = "Send Email to Support"
    static let needHelpToSubTitle    = "Need help? We’re here to assist you"
    static let contactSupportHeading = "Contact Support"
    static let describeRequest       = "Describe your request"
    static let additionalDetails     = "Additional Details (Optional)"
    static let selectYourIssue       = "Select Your Issue *"
    static let mobileNumberTitle     = "Mobile Number *"
    static let errorMessageSupport   = "Please check all fields"
    static let submitSupportTitle    = "Support!"
    static let mobileNumberSubTitle  = "Please use the same number you were facing problem with"
    static let selectYourIssuetitle  = "Select Your Issue *"
    static let selectYourIssueSubTitle = "Please select an issue from the list below, if your issue is not listed, please select 'Issue not listed'."
    static let selectAnIssueTitle      = "Select an Issue"
    static let additionInformationText = "If selected 'Issue not listed', please provide additional information below, our support team will get back to you as soon as possible."
    
    static let issues                = [
                                            "Forgotten password",
                                            "Account locked",
                                            "OTP not receiving",
                                            "Account not recognized",
                                            "Account not found",
                                            "Could not access your account",
                                            "Issue not listed"
                                        ]
    static let reportIssues = [
        "App is crashing",
        "App is freezing or lagging",
        "Feature not working as expected",
        "UI elements not displaying properly",
        "App is slow to load",
        "Error when making a purchase",
        "Notification not received",
        "Unable to load content",
        "Can't access specific section of the app",
        "App not responding to taps",
        "Login credentials not recognized",
        "Issue with payment method",
        "App is consuming too much battery",
        "App is using too much data",
        "App is not syncing with the server",
        "Unable to upload files/images",
        "Unable to download content",
        "Incorrect app language",
        "Issue with search functionality",
        "Bug in app's navigation",
        "Problem with app permissions",
        "Account settings not saving",
        "Can't change profile picture",
        "App is displaying incorrect information",
        "App's content is outdated",
        "Unable to logout",
        "Other issue"
    ]

    static let profesionalDetailsTitle = "Professional Details"
    static let professionalDesc        = "Please provide your professional details, this will help us match you with the right opportunities and people to connect with."
    
    
    //Permission Scene
    static let settingMovingText        = "\n You can skip the permission now and enable it in setting later."
    static let skipSinglePermission     = "Skip"
    static let permissionText           = "Permission"
    static let skipAllPermission        = "Skip All Permissions"
    static let enableLocationText       = "Enable Location for a Better Experience"
    static let subTitleLocation         = "Allow location access to connect with people around you, discover nearby events, and enhance your experience."
    static let buttonTitleLocation      = "Allow Location"
    static let titleNewPopUpForLocation = "Let’s Go Live - We’ll Need Your Location"
    static let subTitlePopUpForLocation = "To Power Your Live Activity"
    static let descriptionPopUpForLocation = "To create your live activity, we use your live location. Your data stays secure and is only used to support this feature.. This helps us connect you with people and activities around you."
    static let locationAccessDisabled   = "Location Access is Disabled"
    static let locationAccessEnabled    = "To enable location access, go to Settings and allow location permissions."
    static let openSettingsText         = "Open Settings"
    static let allowContacts            = "Allow Contacts"
    
    static let stayUpdatedText          = "Stay Updated with Important Alerts"
    static let notificationText         = "Turn on notifications to get real-time updates on new messages, trending posts, and friend requests. Don’t miss out on what matters!, Tap to enable"
    static let buttonTitleNotification  = "Allow Notifications"
    static let notificationAccessDisabled = "Notifications are Disabled"
    static let notificationAccessEnabled = "To receive notifications, enable them in Settings"
    static let helpTrackingText          = "Help Us Improve with Tracking"
    static let trackingText              = "Share anonymized usage data to help us improve the app experience. Your data remains private and secure."
    static let allowTrackingText         = "Allow Tracking"
    static let trackingDisabled          = "Tracking is Disabled"
    static let trackingEnabled           = "To enable tracking, update your preferences in Settings."
    static let locationAccessInstructions = """
            1. Open the Settings app on your iPhone.\n2. Tap Privacy & Security, then select Location Services.\n3. Scroll down, choose the app you want to modify, and set the preferred location access option.\n4. (Optional) Enable Precise Location for more accurate tracking.
            """
    static let lastEnducationText         = "Last Education"
    static let degreeText                 = "Degree"
    static let institutionText            = "College/University/School"
    static let professionalDetailsText    = "Professional Details"
    static let jobTitleText               = "Job Title"
    static let companyNameText            = "Company Name"
    static let yearOfExpText              = "Years of Experience"
    static let addAnotherProfession       = "Add Another Profession"
    static let doneText                   = "Done"
    
    //Notification
    static let notificationTitle          = "Notifications"
    static let notificationSegmentOne     = "All"
    static let notificationSegmentTwo     = "Activity"
    
    static let generalPost               = "Post"
    static let plannedAct_title          = "Planned"
    static let liveActivity_title        = "Live"
    
    //HomePage Segment Control
    static let homepageSegmentTwo        = "Planned"
    static let homepageSegmentThree      = "Live"
    static let retryText                 = "Retry"
    static let videoNotPlayableText      = "Video is not playable"
    static let passionsAndPursuitsText   = "Passions & Pursuits"
    static let liveAndTrendingText       = "Live & Trending Near You"
    static let liveText                  = "Live"
    static let interestedText            = "Interested"
    static let joinedText                = " Joined"
    static let atText                    = " at "
    static let tapToLocateText           = "Tap to Locate Me"
    
    //ControlRoom
    static let controlRoomTitle          = "Menu"
    static let privacyPolicy             = "Privacy Policy"
    static let termsConsitionText        = "Terms & Condition"
    static let faqText                   = "FAQ's"
    static let greetText                 = "MeetMux with ❤️ \n by Altradov Technologies, Bengaluru"
    static let linkCopiedTOClipboardText = "Link copied to clipboard"
    static let rateUsInAppStore          = "Rate us in App Store"
    static let DashboardText             = "Dashboard"
    
    /* Previoud login detected*/
    static let previousLoginDetected    = "Welcome back, "
    static let previoudLoginSubtitle    = "Great to see you again! We’ve saved your last session securely. Ready to continue or explore something new?"
    static let primaryButtonText        = "Continue with "
    static let secondaryButtonText      = "Login/Signup with Another Account"
    
    //API error
    static let apiLoginFailed            = "Login Failed"
    static let activitiesFetchingFailed  = "Activities Fetching Failed"
    static let apiGeneralError           = "Something went wrong, Please try again!"
    
    // Profile Page
    static let shareYourProfile          = "Meet me where the cool people hang – MeetMux 😎"
    static let bioProfileText            = "Bio / About"
    static let postMadeByYou             = "Your Posts"
    static let generalShare              = "Share"
    static let copyLink                  = "Copy Link"
    static let scanQRCode                = "Scan QRCode"
    static let LinkCopiedToClipboard     = "Link Copied to Clipboard 😎"
    static let hereToHelpYou             = "We're here for you! How would you like to contact support – call or email us (Email response time is 24h to 48h)?"
    static let changeMobileNumber        = "Change MobileNumber"
    static let changeMobileNumberDescription = "To ensure security, OTPs are sent to both the old and new numbers. The number is updated only after successful verification of both OTPs."
    static let themeSwitcher             = "Theme Switcher"
    static let changeThemeBasedonMood   = "Change Theme Based on your Mood"
    static let locateMeText              = "Locate Me"
    static let locateMeDescription       = "Use your current location"
    static let chooseLocationText        = "Choose Location"
    static let searchLocations           = "Search locations..."
    static let noRecentSearchText        = "No recent search"
    static let recenctSearchText         = "Recent Searches"
    
    // Create Post
    static let createPostDescription    = "Create post based on your mood"
    static let createPostTitle          = "Create Post"
    static let postTitle                = "Post"
    static let closeButtontext          = "Close"
    
    // Tag people
    static let tagConnectionsTitle      = "Tag from your connections"
    static let connectionsSelected      = "Connections selected:"
    static let resetSelectedList        = "- Reset"
    static let blockNoResponse          = "Looks like you’re keeping things peaceful — no one is blocked!"
    static let followFollowersNoResponse = "No follows here yet — time to make some connections!"
    static let searchConnectionText     = "Search connections..."
    static let searchBlockedUsersText   = "Search blocked users..."
    static let mentionFriendsText      = "Mention friends or colleagues"
    static let makePostMoreInteresting  = "Make your post more interesting"
    static let makePlannedPostInteresting = "Make your planned activity more interesting"
    static let makePlannedPostSubtitle  = "Add a date & time, and location for more attention "
    static let makeLiveActivityInteresting = "Make your live activity more interesting"
    static let makeLiveSubtitle = "Add live duration for more attention"
    static let tagSubtitle              = "Tag friends or colleagues to make your post more interesting"
    static let chooseLocationSubtitle    = "Adding places make your feed or post interesting"
    static let unknownUser              = "Unknown user"
    static let toggleControlTitleText   = "Toggle this to control who can see your post — your connections or everyone."
    static let publicPost               = "Public Post"
    static let privatepost              = "Private Post"
    static let followingText            = "Following"
    static let followersText            = "Followers"
    static let messagesPast             = "Messages"
    static let exploreConnections       = "Connection List"
    static let searchFollowingText      = "Search following..."
    static let searchFollowersText      = "Search followers..."
    static let writeAPostText           = "Write a post..."
    
    // Activities atgging
    static let activitiesHeaderInPost  = "Add some actvities/interest to your post"
    static let activitiesHeaderSubText = "This will help others understand what you're interested in"
    static let unknownError            = "Unknown error, please try again later"
    static let checkOutThisAppText     = "Check out this app!"
    static let submitFeedback          = "Submit Feedback"
    static let helpUsImproveText       = "Help us improve this app!"
    static let additionalComments      = "Additional Comments (optional)"
    static let tagUserSubtitleText     = "Customize who appears in your connections"
    static let connectListTitle        = "Connection List"
    static let browseConnectionsText   = "Browse from your connections"
    static let blockedUserList         = "Blocked Users"
    static let blockerUsersSubtitleText = "People you've blocked from your account."
    static let blockedUserListText      = "People you’ve blocked won’t be able to find your profile, message you, or interact with your posts."
    static let unBlocktext              = "Unblock"
    static let unknownText              = "Unknown"
    static let unblockContentSubtitle   = "from your list? \n\n This user can able to receive notification and message from you.If you have any other reason to block this user, please contact support team."
    static let unFollow                 = "Unfollow"
    static let followBackText           = "Follow back"
    static let noConnectionsFound       = "No connections found, Please Explore or search new connections and add them to your list."
    static let uploadMediaTomakePostInterestText = "Upload media to make this post interesting"
    static let uploadProfilePictureText  = "Upload profile picture"
    static let genderArray = ["Male", "Female", "Any"]
    static let liveDurations  = [
        "30 minutes", "1 hour", "1.5 hours", "2 hours", "2.5 hours", "3 hours",
        "3.5 hours", "4 hours", "4.5 hours", "5 hours", "5.5 hours", "6 hours",
        "6.5 hours", "7 hours", "7.5 hours", "8 hours", "8.5 hours", "9 hours",
        "9.5 hours", "10 hours", "10.5 hours", "11 hours", "11.5 hours", "12 hours",
        "12.5 hours", "13 hours", "13.5 hours", "14 hours", "14.5 hours", "15 hours",
        "15.5 hours", "16 hours", "16.5 hours", "17 hours", "17.5 hours", "18 hours",
        "18.5 hours", "19 hours", "19.5 hours", "20 hours", "20.5 hours", "21 hours",
        "21.5 hours", "22 hours", "22.5 hours", "23 hours", "23.5 hours", "24 hours"
    ]

    // search and recommendations and suggestions
    static let searchAndStartInteractingText = "Search & Start interacting...."
    static let recentSearchesText          = "Recent Searches"
    static let noRecentSearchesText        = "No recent searches available"
    static let searchResultsText          = "Search Results"
    static let suggestedConnectionsText  = "Recommended Connections"
    static let searchAndRecommendationsText = "Search & Recommendations"
    static let searchOrSuggestionsText    = "Search or look for suggestions"
    static let noUsersFoundText           = "No Users Found, Please try again\n"
    static let noUsersFoundSubText       = "We couldn't find any users matching your search.\nTry searching with a different term."
    static let postText = "Posts"
    static let connectionText = "Connections"
    static let activityEndOn = "Activity Ends on"
    static let resendOTP = "Resend OTP in"
    static let joinUserTitle = "Joined or Interested User"
    static let taggedUserTitle = "Tagged Users"

    static let noChatMessages = "It’s way too quiet in here..."
    static let noChatMessagesSubText = "Start a convo before the tumbleweeds do 🐎💬"

}
