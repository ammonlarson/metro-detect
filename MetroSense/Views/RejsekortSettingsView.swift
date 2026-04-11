import SwiftUI

struct RejsekortSettingsView: View {
    @Binding var settings: NotificationSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable Rejsekort Integration", isOn: $settings.rejsekortEnabled)
                    .tint(.blue)
            } header: {
                Text("Quickly open the Rejsekort app from MetroSense when near a station or traveling on the metro.")
            }

            if settings.rejsekortEnabled {
                Section {
                    Toggle("Metro Proximity", isOn: $settings.proximityShowRejsekortPill)
                        .tint(.blue)
                    Toggle("Movement Detection", isOn: $settings.movementShowRejsekortPill)
                        .tint(.blue)
                } header: {
                    Text("Overlay Button")
                } footer: {
                    Text("Show the Rejsekort shortcut button on the main screen when proximity or movement is detected.")
                }

                Section {
                    Toggle("Metro Proximity", isOn: $settings.proximityRejsekortAction)
                        .tint(.blue)
                    Toggle("Movement Detection", isOn: $settings.movementRejsekortAction)
                        .tint(.blue)
                } header: {
                    Text("Notification Action")
                } footer: {
                    Text("Add a \"Check in with Rejsekort\" button to notification banners so you can open Rejsekort directly.")
                }
            }
        }
        .navigationTitle("Rejsekort")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RejsekortSettingsView(settings: .constant(.default))
    }
}
