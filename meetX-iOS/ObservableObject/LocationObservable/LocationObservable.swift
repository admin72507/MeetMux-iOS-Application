//
//  LocationObservable.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 18-05-2025.
//
import Combine
import CoreLocation
import Foundation

class LocationObservable: ObservableObject {
    // Search Location in homepageRelated
    @Published var searchText: String = ""
    @Published var searchResults: [String] = []
    @Published var recentSearches: [String] = []
    @Published var showNoResultsMessage = false
    
    // Initial Location Fetching
    @Published var subLocalityName: String?
    @Published var locationName: String?
    @Published var city: String?
    @Published var country: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // User location
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    
    // New published vars for UI
    @Published var mainLocationName: String = Constants.locateMeText
    @Published var entireLocationName: String = Constants.locateMeDescription
    @Published var isLocationSelectionSheetPresent: Bool = false
    
    private let locationManager = LocationManager()
    private let googleService = GoogleLocationService()
    private var cancellables = Set<AnyCancellable>()
    
    let locationSelected = PassthroughSubject<(String, String, Double?, Double?), Never>()
    
    init() {
        locationManager.$authorizationStatus
            .assign(to: \.authorizationStatus, on: self)
            .store(in: &cancellables)
        
        locationManager.$userLocation
            .compactMap { $0 }
            .removeDuplicates(by: {
                $0.coordinate.latitude == $1.coordinate.latitude &&
                $0.coordinate.longitude == $1.coordinate.longitude
            })
            .sink { [weak self] location in
                guard let self = self else { return }
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
                
                self.fetchGoogleLocationDetails(for: location) { details in
                    DispatchQueue.main.async {
                        if let name = details.name, !name.isEmpty {
                            self.mainLocationName = name
                            self.entireLocationName = details.subLocality ?? details.city ?? details.country ?? ""
                        } else {
                            self.mainLocationName = Constants.locateMeText
                            self.entireLocationName = Constants.locateMeDescription
                        }
                        self.isLocationSelectionSheetPresent = false
                    }
                }
            }
            .store(in: &cancellables)
        
        // Search text publisher
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.isEmpty {
                    self.searchResults = []
                } else {
                    self.fetchLocalities(matching: text)
                }
            }
            .store(in: &cancellables)
        
        loadRecentSearches()
    }
    
    private func fetchLocalities(matching query: String) {
        googleService.searchPlaces(query: query)
            .sink { [weak self] results in
                self?.searchResults = results
                self?.showNoResultsMessage = results.isEmpty
            }
            .store(in: &cancellables)
    }
    
    func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: DeveloperConstants.UserDefaultsInternal.userRecentLocationSearch) ?? []
    }
    
    func saveRecentSearch(_ item: String) {
        var searches = UserDefaults.standard.stringArray(forKey: DeveloperConstants.UserDefaultsInternal.userRecentLocationSearch) ?? []
        if let index = searches.firstIndex(of: item) {
            searches.remove(at: index)
        }
        searches.insert(item, at: 0)
        UserDefaults.standard.setValue(Array(searches.prefix(10)), forKey: DeveloperConstants.UserDefaultsInternal.userRecentLocationSearch)
        loadRecentSearches()
    }
    
    func requestPermission() {
        locationManager.requestLocationPermission { granted in
            if !granted {
                print("Location permission denied")
            }
        }
    }
    
    private func fetchGoogleLocationDetails(for location: CLLocation,
                                            completion: @escaping ((subLocality: String?, name: String?, city: String?, country: String?)) -> Void) {
        googleService.fetchPlaceDetails(for: location)
            .sink { details in
                completion(details)
                self.subLocalityName = details.subLocality
                self.locationName = details.name
                self.city = details.city
                self.country = details.country
            }
            .store(in: &cancellables)
    }
    
    // MARK: - When user selects a location from search or recent
    func selectLocation(
        _ locationName: String
    ) {
        saveRecentSearch(locationName)
        self.isLocationSelectionSheetPresent = false
        
        googleService.geocodeAddress(address: locationName)
            .sink { [weak self] coordinate in
                guard let self = self, let coordinate = coordinate else { return }
                
                self.latitude = coordinate.latitude
                self.longitude = coordinate.longitude
                
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self.fetchGoogleLocationDetails(for: location) { details in
                    DispatchQueue.main.async {
                        // mainName: priority = subLocality > city > fallback text
                        let mainName = details.subLocality ?? details.city ?? Constants.locateMeText
                        let entireName = locationName // full original search string
                        
                        self.mainLocationName = mainName
                        self.entireLocationName = entireName

                        LocationStorage.save(
                            main: mainName,
                            entire: entireName,
                            lat: coordinate.latitude, lon: coordinate.longitude)
                        LocationStorage.isUsingCurrentLocation = false
                        self.locationSelected.send((mainName, entireName, coordinate.latitude, coordinate.longitude))
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - When user taps "Locate Me"
    func useCurrentLocation() {
        guard let lat = latitude, let lon = longitude else {
            requestPermission()
            return
        }
        
        let location = CLLocation(latitude: lat, longitude: lon)
        
        fetchGoogleLocationDetails(for: location) { [weak self] details in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let mainName = details.subLocality ?? details.city ?? Constants.locateMeText
                let entireName = details.name ?? Constants.locateMeDescription
                
                self.mainLocationName = mainName
                self.entireLocationName = entireName
                LocationStorage.isUsingCurrentLocation = true

                self.locationSelected.send((mainName, entireName, lat, lon))
                self.isLocationSelectionSheetPresent = false
            }
        }
    }
    
    // MARK: - Remove recent item
    func deleteRecentSearch(_ item: String) {
        var searches = UserDefaults.standard.stringArray(forKey: DeveloperConstants.UserDefaultsInternal.userRecentLocationSearch) ?? []
        if let index = searches.firstIndex(of: item) {
            searches.remove(at: index)
            UserDefaults.standard.setValue(searches, forKey: DeveloperConstants.UserDefaultsInternal.userRecentLocationSearch)
            loadRecentSearches()
        }
    }

}

