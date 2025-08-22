# zeXmeet-iOS

  The app will use MVVM-C (iOS) and Clean Architecture (Android) for separation of concerns, reusability, and testing. It will leverage Combine (iOS) for reactive programming,       alongside GCD/NSOperationQueue for task handling, and Coroutines (Android). Caching will be implemented for improved performance and memory management.

## Table of Contents

1. [Branching Structure](#branching-structure)
2. [Project Layers](#project-layers)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Development Guidelines](#development-guidelines)
6. [Technologies Used](#technologies-used)
7. [Contributing](#contributing)
8. [License](#license)
9. [PR Guidelines](#pr-guidelines)

## Branching Structure

### Production
  The main branch used for deploying the stable and final version of the application. It contains thoroughly tested and approved code.
  
### Production / Hot Fix 
  A hotfix branch dedicated to resolving critical issues or bugs in the production environment. It is merged back into both Production and Develop branches.
  
### Pre Production / QA Environment
  This branch is used to stage code for testing before release. It reflects the environment closest to Production for quality assurance.
  
### Develop
  The primary branch for integrating new features and ongoing development. It is the base for all feature branches and undergoes rigorous testing before merging into Pre Production.

### Feature branches 
  This branch will be created by fellow developers to arrange the functionalities

## Project Layers

### HLD Docx:
https://docs.google.com/document/d/1UIrYklm6crjLSbkPcc1Va2_80NM9jxE4VWxf9q5EHpM/edit?tab=t.0#heading=h.l00xnbx3zhac

### Language: 
   Swift 
   SwiftUI and UIKit

  #### Why Use Both?
  
  ##### SwiftUI Advantages:
  Simplified UI development with declarative syntax.
  Automatic support for accessibility, dark mode, and other modern features.
  Real-time previews in Xcode.
  
  ##### UIKit Advantages:
  Access to more mature APIs and views not yet fully supported in SwiftUI.
  Fine-grained control over layouts and animations.
  Compatibility with existing UIKit-based codebases.

  
  ### UIViewRepresentable: 
  This is used for embedding a UIKit UIView (e.g., UIButton, UISlider, etc.) into SwiftUI.
  ### UIViewControllerRepresentable:
  This is used for embedding a UIKit UIViewController (e.g., UIImagePickerController, custom view controllers, etc.) into SwiftUI.
  ### UIHostingController: 
  Invoke SwiftUI from UIKit: If needed, you can also present SwiftUI views from UIKit by embedding them in a UIHostingController.

### Architecture: 
   MVVM & Co-Ordinator & Combine

### Disk Memory: 
   File Manager

### In Memory:
   NSCache

### Networking: 
   URLSession or Alamofire

### Data Base 
   Core Data

### Map Integration
   Google Maps 

### Event Management / Push Notification / Crashlytics / Analytics 
   Firebase

### Deeplinking 
   Universal Links 

### Design Patterns: 
   Singleton

### Video Handling: 
   AVPlayer

## Installation

1. Clone the repository
   ``` 
    git clone <repository-url>
    cd altrodav-meetX-iOS
2. Install dependencies using CocoaPods or Swift Package Manager.
3. Open the project in Xcode.

## Usage

  Build and run the app using the simulator or a physical device.
  Configure the Firebase backend if required (details in FirebaseConfig.md).

## Development Guidelines

  Follow the coding standards defined for Swift and MVVM-C & Combine architecture.
  Ensure all feature branches are merged into Develop with code reviews.
  Add unit tests for each module.

## Technologies Used

  iOS: Swift, SwiftUI, UIKit, Core Data, Combine, Alamofire
  Firebase: Push Notifications, Crashlytics, Analytics
  Third-Party Libraries: List any additional dependencies or frameworks used

## Contributing

  Fork the repository.
  Create a feature branch: git checkout -b feature/<feature-name>
  Push your changes and create a pull request.

## License

  This project is licensed under the MIT License.

## PR GuideLines

### Branch Naming

  Use meaningful and consistent branch names.
  Format: <type>/<short-description>
  #### Examples:
  ```
  feature/add-user-login
  bugfix/fix-crash-on-login
  hotfix/update-production-config
  ```

### PR Title

  Use a concise and descriptive title summarizing the change.

### PR Description

  ### Summary
  - [Brief overview of the changes]

  ### What has been done?
  - [List of key changes]
  - [Mention any refactoring or optimizations]

  ### Screenshots (if applicable)
  - Add before/after screenshots for UI changes.

  ### Related Issues
  - Resolves #[IssueNumber]

  ### Testing Checklist
  - [ ] Unit tests added/updated
  - [ ] Integration tests performed
  - [ ] Manual QA completed

### Screenshots/Demos: 

  Add visuals for a better overview.
  
### API Documentation: 

  Links or details for backend endpoints if applicable attach the End point details in the PR itself.
  
### CI/CD Details: 

  Each PR should pass the CI, then only we can merge it 

### Code Quality
  
  Ensure code adheres to the project’s coding standards and style guidelines.
  Avoid commented-out or unused code. Clean it up before submission.
  Ensure appropriate naming conventions and modular structure.

### Testing Requirements

  Write/Update unit tests for new or modified code.
  Verify all tests pass locally before pushing.
  Include test coverage details in the PR description.

### Documentation

  Update relevant documentation (e.g. inline comments, API references).
  Mention any breaking changes in the PR description.

###  Review Process

  Assign the PR to appropriate reviewers (e.g., tech leads or team members).
  Set a minimum of two reviewers for approval before merging.
  Actively address all comments from reviewers.

###  Merging Rules

  Use squash and merge for a cleaner commit history unless instructed otherwise.
  Ensure the PR is up-to-date with the target branch before merging.
  ```
  git fetch origin
  git rebase origin/develop
  ```

### Do’s and Don’ts

#### Do:
  Keep PRs small and focused.
  Use meaningful commit messages.
  Test the application for regressions.
  
#### Don’t:
  Merge your own PR unless explicitly authorized.
  Push incomplete or experimental code without proper flags.
