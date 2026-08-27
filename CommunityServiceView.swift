import SwiftUI

struct CommunityServiceView: View {
    var body: some View {
        ActivityListView(
            title: "Community Service",
            icon: "🌟",
            endpoint: "/api/community-service"
        )
    }
}
