import SwiftUI

struct GroupTripView: View {
    var body: some View {
        ActivityListView(
            title: "Mindful Group Trips",
            icon: "🏕️",
            endpoint: "/api/trips"
        )
    }
}
