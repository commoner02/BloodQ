//
//  LocationManager.swift
//  BloodQ
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationName: String = ""
    @Published var district: String = ""
    @Published var upazilla: String = ""
    @Published var errorMessage: String?
    @Published var isUpdating = false
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        isUpdating = true
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        isUpdating = false
    }
    
    func reverseGeocode(location: CLLocation, completion: @escaping (String?, String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                DispatchQueue.main.async {
                    self?.errorMessage = error?.localizedDescription ?? "Unable to get location details"
                    completion(nil, nil, nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                let locationName = [
                    placemark.subLocality,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }.joined(separator: ", ")
                
                let district = placemark.administrativeArea ?? ""
                let upazilla = placemark.locality ?? ""
                
                self?.locationName = locationName.isEmpty ? "Current Location" : locationName
                self?.district = district
                self?.upazilla = upazilla
                
                completion(locationName, district, upazilla)
            }
        }
    }
    
    func searchLocation(query: String, completion: @escaping ([MKMapItem]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // ONLY use device location if available - NO default fallback
        if let location = location {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
        // If no device location, search without region bias
        // Apple will use its own default region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                completion([])
                return
            }
            completion(response.mapItems)
        }
    }
    
    // MARK: - Set Custom Location for Testing
    func setCustomLocation(latitude: Double, longitude: Double) {
        let customLocation = CLLocation(latitude: latitude, longitude: longitude)
        self.location = customLocation
        reverseGeocode(location: customLocation) { _, _, _ in }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable it in Settings or use manual location search."
            location = nil
            isUpdating = false
        case .notDetermined:
            requestPermission()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.location = location
            self.isUpdating = false
        }
        
        reverseGeocode(location: location) { _, _, _ in }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isUpdating = false
        }
    }
}
