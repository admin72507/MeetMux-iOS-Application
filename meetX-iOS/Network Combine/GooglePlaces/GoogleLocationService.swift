import Foundation
import CoreLocation
import Combine

class GoogleLocationService {
    private let apiKey = DeveloperConstants.googleApiKey
    
    func fetchPlaceDetails(for location: CLLocation) -> AnyPublisher<(subLocality: String?, name: String?, city: String?, country: String?), Never> {
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        guard let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)&key=\(apiKey)") else {
            return Just((nil, nil, nil, nil)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleGeocodeResponse.self, decoder: JSONDecoder())
            .map { response in
                let placemark = response.results.first
                let subLocality = placemark?.address_components.first(where: {
                    $0.types.contains("sublocality") || $0.types.contains("neighborhood")
                }
                )?.long_name
                let name = placemark?.formatted_address
                let city = placemark?.address_components.first(where: { $0.types.contains("locality") })?.long_name
                let country = placemark?.address_components.first(where: { $0.types.contains("country") })?.long_name
                return (subLocality, name, city, country)
            }
            .replaceError(with: (nil, nil, nil, nil))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Location Search
extension GoogleLocationService {
    func searchPlaces(query: String, userLocation: CLLocation? = nil) -> AnyPublisher<[String], Never> {
        guard
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return Just([]).eraseToAnyPublisher()
        }
        
        // Build URL with improved parameters
        var urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(encodedQuery)&key=\(apiKey)"
        
        // Remove restrictive types filter - allow all types of places
        // If you want to filter, use: &types=establishment|geocode
        
        // Add location bias if user location is available
        if let userLocation = userLocation {
            let lat = userLocation.coordinate.latitude
            let lng = userLocation.coordinate.longitude
            urlString += "&location=\(lat),\(lng)&radius=50000" // 50km radius
        }
        
        // Add session token for better results consistency
        let sessionToken = UUID().uuidString
        urlString += "&sessiontoken=\(sessionToken)"
        
        // Add language preference (optional)
        urlString += "&language=en"
        
        guard let url = URL(string: urlString) else {
            return Just([]).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleAutocompleteResponse.self, decoder: JSONDecoder())
            .map { response in
                // Log response for debugging
                print("Autocomplete response: \(response.predictions.count) results")
                return response.predictions.map { $0.description }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension GoogleLocationService {
    /// Fetches coordinates (lat, lng) for a place description (address)
    func getCoordinates(for placeDescription: String) -> AnyPublisher<CLLocationCoordinate2D?, Never> {
        guard
            let encodedDescription = placeDescription.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(encodedDescription)&key=\(apiKey)")
        else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleGeocodeResponse.self, decoder: JSONDecoder())
            .map { response in
                guard let location = response.results.first?.geometry.location else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension GoogleLocationService {
    func geocodeAddress(address: String) -> AnyPublisher<CLLocationCoordinate2D?, Never> {
        guard
            let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(encodedAddress)&key=\(apiKey)")
        else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleGeocodeResponse.self, decoder: JSONDecoder())
            .map { response in
                if let location = response.results.first?.geometry.location {
                    return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                }
                return nil
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
