#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Applies `navigationBarTitleDisplayMode` only on iOS.
    /// Use this instead of `.navigationBarTitleDisplayMode` directly to keep
    /// multiplatform targets building without `#if os(iOS)` at every call site.
    @ViewBuilder
    func iOSNavigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(mode)
#else
        self
#endif
    }
}
#endif
