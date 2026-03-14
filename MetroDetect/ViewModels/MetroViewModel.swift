import CoreLocation
import Combine

@MainActor
final class MetroViewModel: ObservableObject {
    @Published var tripState: MetroTripState = .idle
    @Published var nearestStation: MetroStation?
    @Published var speedKMH: Double = 0
    @Published var settings: NotificationSettings

    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()

    // Track departure station when a trip begins
    private var departureStation: MetroStation?
    private var hasNotifiedCurrentTrip = false
    private var hasNotifiedProximity = false
    private var lastNotifiedStationName: String?

    // Movement sustained tracking
    private var movementStartTime: Date?
    private var hasNotifiedMovement = false

    init(locationService: LocationService = LocationService()) {
        self.locationService = locationService
        self.settings = NotificationSettings.load()
        bindLocation()
    }

    func start() {
        locationService.requestPermission()
        NotificationService.shared.requestPermission()
    }

    // MARK: - Private

    private func bindLocation() {
        locationService.$currentLocation
            .compactMap { $0 }
            .combineLatest(locationService.$currentSpeed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location, speed in
                self?.evaluate(location: location, speed: speed)
            }
            .store(in: &cancellables)
    }

    private func evaluate(location: CLLocation, speed: Double) {
        speedKMH = speed * 3.6

        let nearby = nearbyStation(for: location)
        nearestStation = nearby

        // Proximity notification (independent of trip state)
        handleProximityNotification(station: nearby)

        // Movement sustained notification
        handleMovementNotification(speed: speed)

        switch tripState {
        case .idle, .atStation:
            if isMetroSpeed(speed) {
                // Moving at metro speed — find the most likely line
                if let departure = departureStation ?? nearby,
                   let line = likelyLine(near: location, from: departure) {
                    departureStation = departure
                    tripState = .onMetro(line: line, fromStation: departure, speed: speed)
                    if !hasNotifiedCurrentTrip {
                        hasNotifiedCurrentTrip = true
                        NotificationService.shared.sendMetroDetected(
                            line: line.rawValue,
                            fromStation: departure.name
                        )
                    }
                }
            } else if let station = nearby {
                departureStation = station
                tripState = .atStation(station)
            } else {
                tripState = .idle
                hasNotifiedCurrentTrip = false
            }

        case .onMetro(let line, let from, _):
            if isMetroSpeed(speed) {
                // Still on metro — update speed
                tripState = .onMetro(line: line, fromStation: from, speed: speed)
                // Check if we've arrived at a new station
                if let arrived = nearby, arrived != from {
                    tripState = .arrived(line: line, from: from, to: arrived)
                    departureStation = arrived
                }
            } else if let station = nearby {
                // Slowed down at a station — arrival
                tripState = .arrived(line: line, from: from, to: station)
                departureStation = station
            } else {
                // Slowed down away from any station — treat as arrived/idle
                tripState = .idle
                hasNotifiedCurrentTrip = false
            }

        case .arrived(_, _, let to):
            // Reset to atStation at the arrival point after a moment
            tripState = .atStation(to)
            departureStation = to
            hasNotifiedCurrentTrip = false
        }
    }

    // MARK: - Proximity Notifications

    private func handleProximityNotification(station: MetroStation?) {
        guard settings.notifyNearStation else { return }

        if let station {
            // Check if this station's lines match the user's filter
            let stationLineNames = station.lines.map { $0.rawValue }
            let matchesFilter = settings.shouldNotifyAllLines ||
                !Set(stationLineNames).isDisjoint(with: settings.notifyLines)

            if matchesFilter && lastNotifiedStationName != station.name {
                lastNotifiedStationName = station.name
                NotificationService.shared.sendNearStation(
                    stationName: station.name,
                    lines: stationLineNames
                )
            }
        } else {
            // Moved away from all stations — allow re-notification
            lastNotifiedStationName = nil
        }
    }

    // MARK: - Movement Notifications

    private func handleMovementNotification(speed: Double) {
        guard settings.notifyOnMovement else {
            movementStartTime = nil
            hasNotifiedMovement = false
            return
        }

        let inRange = speed >= settings.movementMinSpeedMPS && speed <= settings.movementMaxSpeedMPS

        if inRange {
            if movementStartTime == nil {
                movementStartTime = Date()
            }

            let elapsed = Date().timeIntervalSince(movementStartTime!)
            if elapsed >= settings.movementSustainedSeconds && !hasNotifiedMovement {
                // Check station origin requirement
                if settings.movementRequireStationOrigin && departureStation == nil {
                    return
                }
                hasNotifiedMovement = true
                NotificationService.shared.sendMovementDetected(
                    speedKMH: speed * 3.6,
                    fromStation: departureStation?.name
                )
            }
        } else {
            movementStartTime = nil
            hasNotifiedMovement = false
        }
    }

    // MARK: - Detection Helpers

    private func isMetroSpeed(_ speed: Double) -> Bool {
        speed >= MetroLine.minimumSpeedMPS && speed <= MetroLine.maximumSpeedMPS
    }

    private func nearbyStation(for location: CLLocation) -> MetroStation? {
        let radius = settings.notifyNearStation ? settings.proximityRadius : MetroStation.proximityRadius
        let allStations = MetroLine.all.flatMap { $0.stations }
        return allStations
            .filter { $0.distance(from: location) <= radius }
            .min { $0.distance(from: location) < $1.distance(from: location) }
    }

    private func likelyLine(near location: CLLocation, from departure: MetroStation) -> MetroLine.LineID? {
        // Find lines that serve the departure station
        let candidateLines = departure.lines

        // Among those, pick the line whose next station is closest to current position
        return candidateLines.min { lineA, lineB in
            let distA = distanceToNearestStation(on: lineA, from: location, excluding: departure)
            let distB = distanceToNearestStation(on: lineB, from: location, excluding: departure)
            return distA < distB
        }
    }

    private func distanceToNearestStation(
        on lineID: MetroLine.LineID,
        from location: CLLocation,
        excluding station: MetroStation
    ) -> CLLocationDistance {
        guard let line = MetroLine.all.first(where: { $0.id == lineID }) else {
            return .infinity
        }
        return line.stations
            .filter { $0 != station }
            .map { $0.distance(from: location) }
            .min() ?? .infinity
    }
}
