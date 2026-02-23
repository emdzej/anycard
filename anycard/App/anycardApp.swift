import SwiftUI
import SwiftData

@main
struct anycardApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Card.self)
    }
}
