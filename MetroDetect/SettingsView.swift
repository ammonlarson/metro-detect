import SwiftUI

struct SettingsView: View {
    @Binding var settings: NotificationSettings

    var body: some View {
        Form {
            proximitySection
            movementSection
        }
        .navigationTitle("Settings")
        .onChange(of: settings) { _, newValue in
            newValue.save()
        }
    }

    // MARK: - Proximity Notifications

    private var proximitySection: some View {
        Section {
            Toggle("Notify Near Station", isOn: $settings.notifyNearStation)

            if settings.notifyNearStation {
                linePicker
                radiusPicker
            }
        } header: {
            Text("Station Proximity")
        } footer: {
            Text("Get notified when you're within range of a metro station.")
        }
    }

    private var linePicker: some View {
        NavigationLink {
            LineSelectionView(selectedLines: $settings.notifyLines)
        } label: {
            HStack {
                Text("Metro Lines")
                Spacer()
                Text(settings.shouldNotifyAllLines ? "All" : settings.notifyLines.sorted().joined(separator: ", "))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var radiusPicker: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Notification Radius")
                Spacer()
                Text("\(Int(settings.proximityRadius)) m")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $settings.proximityRadius, in: 50...500, step: 25)
        }
    }

    // MARK: - Movement Notifications

    private var movementSection: some View {
        Section {
            Toggle("Notify on Movement", isOn: $settings.notifyOnMovement)

            if settings.notifyOnMovement {
                speedRangePicker
                sustainedDurationPicker
                Toggle("Only From Station", isOn: $settings.movementRequireStationOrigin)
            }
        } header: {
            Text("Movement Detection")
        } footer: {
            if settings.notifyOnMovement {
                Text("Notify when speed is sustained in the configured range\(settings.movementRequireStationOrigin ? ", starting from a metro station" : "").")
            } else {
                Text("Get notified when moving at metro speed.")
            }
        }
    }

    private var speedRangePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Min Speed")
                Spacer()
                Text(String(format: "%.0f km/h", settings.movementMinSpeedKMH))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $settings.movementMinSpeedKMH, in: 10...80, step: 5)

            HStack {
                Text("Max Speed")
                Spacer()
                Text(String(format: "%.0f km/h", settings.movementMaxSpeedKMH))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $settings.movementMaxSpeedKMH, in: 20...120, step: 5)
        }
    }

    private var sustainedDurationPicker: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Sustained Duration")
                Spacer()
                Text(String(format: "%.0f sec", settings.movementSustainedSeconds))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $settings.movementSustainedSeconds, in: 5...60, step: 5)
        }
    }
}

// MARK: - Line Selection

struct LineSelectionView: View {
    @Binding var selectedLines: Set<String>

    private let allLines = MetroLine.LineID.allCases

    var body: some View {
        List {
            Button(selectedLines.isEmpty ? "All Lines Selected" : "Select All") {
                selectedLines.removeAll()
            }
            .foregroundStyle(selectedLines.isEmpty ? .secondary : .accentColor)

            ForEach(allLines, id: \.rawValue) { line in
                let isSelected = selectedLines.isEmpty || selectedLines.contains(line.rawValue)
                Button {
                    toggleLine(line.rawValue)
                } label: {
                    HStack {
                        Text(line.rawValue)
                            .foregroundStyle(.primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Metro Lines")
    }

    private func toggleLine(_ line: String) {
        if selectedLines.isEmpty {
            // Switching from "all" to specific: select all except the tapped one
            selectedLines = Set(allLines.map(\.rawValue))
            selectedLines.remove(line)
        } else if selectedLines.contains(line) {
            selectedLines.remove(line)
            // If none left, treat as "all"
            if selectedLines.isEmpty {
                // Already empty = all selected
            }
        } else {
            selectedLines.insert(line)
            // If all are now selected, clear to mean "all"
            if selectedLines.count == allLines.count {
                selectedLines.removeAll()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(settings: .constant(NotificationSettings()))
    }
}
