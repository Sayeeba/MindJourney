import SwiftUI
import MapKit

struct SafeHavenView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var hotels: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("LavenderBG").opacity(0.2)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Search Bar & Button
                    HStack(spacing: 10) {
                        TextField("Search city or hotel...", text: $searchText)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .onSubmit {
                                searchHotels(query: searchText)
                            }
                        
                        Button(action: {
                            searchHotels(query: searchText)
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color("DeepPurple"))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Text("Need a break? Search a city or find nearby peaceful spaces.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Results List
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if isSearching {
                                ProgressView("Searching retreats...")
                                    .padding(.top, 40)
                            } else if hotels.isEmpty {
                                Text("No retreats found. Try searching for a city like 'Dhaka' or 'Cox's Bazar'.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 40)
                                    .padding(.horizontal)
                            } else {
                                ForEach(hotels, id: \.self) { item in
                                    HotelCard(item: item)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Safe Havens")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                searchHotels(query: "Hotel Retreat")
            }
        }
    }
    // MARK: - Search Function
        func searchHotels(query: String) {
            guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            
            isSearching = true
            let request = MKLocalSearch.Request()
            
            // 1. Format the search text
            let searchQuery = query.lowercased().contains("hotel") ? query : "\(query) hotel"
            request.naturalLanguageQuery = searchQuery
            request.resultTypes = .pointOfInterest
            
            // 2. Set your local area coordinates (e.g., Dhaka: Lat 23.8103, Long 90.4125)
            let localCenter = CLLocationCoordinate2D(latitude: 23.8103, longitude: 90.4125)
            let searchSpan = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5) // ~50km radius
            request.region = MKCoordinateRegion(center: localCenter, span: searchSpan)
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                DispatchQueue.main.async {
                    self.isSearching = false
                    if let response = response {
                        self.hotels = response.mapItems.filter {
                            $0.pointOfInterestCategory == .hotel
                        }
                    } else {
                        self.hotels = []
                    }
                }
            }
        }
    
    // MARK: - Hotel Card Subview
    struct HotelCard: View {
        let item: MKMapItem
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Peaceful Retreat")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(item.placemark.title ?? "Nearby Location")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    Spacer()
                    
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(Color("DeepPurple"))
                        .font(.title2)
                }
                
                Divider()
                
                HStack {
                    Text("Great for a day trip or staycation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        item.openInMaps()
                    }) {
                        Text("View on Map")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("DeepPurple"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }
}
#Preview {
    SafeHavenView()
}

