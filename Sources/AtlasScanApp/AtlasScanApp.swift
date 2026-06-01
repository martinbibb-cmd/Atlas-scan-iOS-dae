#if canImport(SwiftUI)
import SwiftUI
import AtlasScan

@main
struct AtlasScanApp: App {

    @StateObject private var store = VisitStore()

    var body: some Scene {
        WindowGroup {
            VisitListView(store: store)
        }
    }
}
#else
@main
struct AtlasScanAppCLI {
    static func main() {}
}
#endif