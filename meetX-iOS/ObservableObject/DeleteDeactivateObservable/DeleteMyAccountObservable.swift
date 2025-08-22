//
//  DeleteMyAccountObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 22-05-2025.
//

import Foundation
import Combine

class DeleteMyAccountObservable : ObservableObject {
    
    @Published var actionType: DeveloperConstants.DeleteDeactivateAccount
    
    private var cancellables = Set<AnyCancellable>()
    private let routeManager = RouteManager.shared
    
    init() {
        self.actionType = .deactivate
    }
    
    func handleDeleteAccount() {
        guard let apiService = SwiftInjectDI.shared.resolve(ApiServiceMapper.self) else { return }
        
        let requestBody = DeactivateRequest(
            action: actionType.rawValue
        )
        
        let publisher: AnyPublisher<DeactivateDeleteAccountModel, APIError> = apiService.genericPostPublisher(
            toURLString: URLBuilderConstants.URLBuilder(type: .deleteDeactiveAccount),
            requestBody: requestBody,
            isAuthNeeded: true
        )
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                Loader.shared.stopLoading()
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                Loader.shared.stopLoading()
                debugPrint(response.message ?? "")
                if self?.actionType == .deactivate {
                    self?.deactiveAccountNavigation()
                }else {
                    self?.deleteAlltheDataKeyChainAndUserdefaults()
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteAlltheDataKeyChainAndUserdefaults() {
        // Delete all the keychain data and other data only user selected delete
        // move user to login screen
        self.clearAllOldUserDefaults(completion: { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.routeManager.navigate(to: LoginRegister())
            }
        })
    }
    
    func deactiveAccountNavigation() {
        // Deactive account
        // remove noting
        // move user to old login selection screen like logout
        routeManager.navigate(to: oldLoginRoute())
    }
    
    func clearAllOldUserDefaults(completion: @escaping () -> Void) {
        let keysToReset = [
            DeveloperConstants.UserDefaultsInternal.menuResponse,
            DeveloperConstants.UserDefaultsInternal.userIDName,
            DeveloperConstants.UserDefaultsInternal.themeSelectedByUser,
            DeveloperConstants.UserDefaultsInternal.isAutoPlayVideos,
            DeveloperConstants.UserDefaultsInternal.seeOthersLastSeen
        ]
        
        let defaults = UserDefaults.standard
        for key in keysToReset {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let keychainCleared = KeychainMechanism.deleteAllKeychainItems()
            
            DispatchQueue.main.async {
                if keychainCleared {
                    debugPrint("Deletion of keychain items successful")
                }
                completion()
            }
        }
    }
}
