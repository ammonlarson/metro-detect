import CoreMotion
import Combine

final class MotionService: ObservableObject {
    @Published var isInMotion: Bool = false
    @Published var motionConfidence: Double = 0
    @Published var dominantActivity: ActivityType = .unknown
    @Published var vibrationLevel: Double = 0

    enum ActivityType: String {
        case stationary
        case automotive
        case walking
        case unknown
    }

    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private var isAccelerometerActive = false
    private var isActivityMonitoringActive = false

    /// Rolling window of recent acceleration magnitudes for vibration analysis.
    private var accelerationSamples: [Double] = []
    private static let sampleWindowSize = 50
    /// Accelerometer sampling interval in seconds.
    private static let samplingInterval: TimeInterval = 0.1

    /// Vibration standard deviation thresholds.
    private static let vibrationMinThreshold: Double = 0.02
    private static let vibrationMaxThreshold: Double = 0.15

    /// Start accelerometer and activity monitoring for tunnel detection.
    /// Call only when tunnel detection conditions are met (signal lost near station).
    func startMonitoring() {
        startAccelerometer()
        startActivityMonitoring()
    }

    /// Stop all motion monitoring to conserve battery.
    func stopMonitoring() {
        stopAccelerometer()
        stopActivityMonitoring()
        resetState()
    }

    var isMonitoring: Bool {
        isAccelerometerActive || isActivityMonitoringActive
    }

    // MARK: - Accelerometer

    private func startAccelerometer() {
        guard !isAccelerometerActive else { return }
        guard motionManager.isAccelerometerAvailable else { return }

        isAccelerometerActive = true
        accelerationSamples.removeAll()
        motionManager.accelerometerUpdateInterval = Self.samplingInterval

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processAccelerometerData(data)
        }
    }

    private func stopAccelerometer() {
        guard isAccelerometerActive else { return }
        motionManager.stopAccelerometerUpdates()
        isAccelerometerActive = false
    }

    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acc = data.acceleration
        // Total acceleration magnitude minus gravity (≈1g when stationary)
        let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z) - 1.0

        accelerationSamples.append(magnitude)
        if accelerationSamples.count > Self.sampleWindowSize {
            accelerationSamples.removeFirst()
        }

        guard accelerationSamples.count >= Self.sampleWindowSize / 2 else { return }

        let stdDev = standardDeviation(of: accelerationSamples)
        vibrationLevel = stdDev

        // Normalize vibration to 0–1 confidence range
        let normalized = min(max((stdDev - Self.vibrationMinThreshold)
            / (Self.vibrationMaxThreshold - Self.vibrationMinThreshold), 0), 1)

        updateMotionConfidence(vibrationScore: normalized)
    }

    // MARK: - Activity Monitoring

    private func startActivityMonitoring() {
        guard !isActivityMonitoringActive else { return }
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        isActivityMonitoringActive = true

        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            self.processActivity(activity)
        }
    }

    private func stopActivityMonitoring() {
        guard isActivityMonitoringActive else { return }
        activityManager.stopActivityUpdates()
        isActivityMonitoringActive = false
    }

    private func processActivity(_ activity: CMMotionActivity) {
        if activity.automotive {
            dominantActivity = .automotive
        } else if activity.stationary {
            dominantActivity = .stationary
        } else if activity.walking {
            dominantActivity = .walking
        } else {
            dominantActivity = .unknown
        }

        updateMotionState()
    }

    // MARK: - Confidence Calculation

    private func updateMotionConfidence(vibrationScore: Double) {
        let activityScore: Double
        switch dominantActivity {
        case .automotive: activityScore = 1.0
        case .unknown: activityScore = 0.5
        case .walking: activityScore = 0.2
        case .stationary: activityScore = 0.0
        }

        // Weighted combination: vibration 60%, activity classification 40%
        motionConfidence = vibrationScore * 0.6 + activityScore * 0.4
        updateMotionState()
    }

    private func updateMotionState() {
        isInMotion = motionConfidence >= 0.3
    }

    private func resetState() {
        accelerationSamples.removeAll()
        isInMotion = false
        motionConfidence = 0
        dominantActivity = .unknown
        vibrationLevel = 0
    }

    // MARK: - Math Helpers

    private func standardDeviation(of values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count - 1)
        return sqrt(variance)
    }
}
