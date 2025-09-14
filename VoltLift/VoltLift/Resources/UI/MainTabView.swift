import SwiftUI

struct MainTabView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: self.$selection) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)

            Text("Activities")
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Activities")
                }
                .tag(1)

            Text("Progress")
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Progress")
                }
                .tag(2)

            Text("Settings")
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(DesignSystem.ColorRole.primary)
    }
}
