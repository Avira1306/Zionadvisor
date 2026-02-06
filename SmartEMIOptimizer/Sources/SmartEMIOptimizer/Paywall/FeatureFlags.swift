import Foundation

// MARK: - Subscription Tier

public enum SubscriptionTier: String, Codable, Sendable {
    /// Free: EMI calculator + 1 scenario run.
    case free

    /// Paid (₹299/year): Unlimited scenarios, prepayment optimizer, refinance checker, PDF export.
    case paid
}

// MARK: - Feature Gate

/// Controls which features are available based on subscription tier.
/// No network calls — MVP uses local state only.
public enum Feature: String, CaseIterable, Sendable {
    case emiCalculator
    case singleScenario
    case unlimitedScenarios
    case prepaymentOptimizer
    case refinanceChecker
    case pdfExport
}

// MARK: - Feature Access Control

public struct FeatureAccess: Sendable {
    public let tier: SubscriptionTier

    public init(tier: SubscriptionTier) {
        self.tier = tier
    }

    /// Returns true if the given feature is unlocked for the current tier.
    public func isUnlocked(_ feature: Feature) -> Bool {
        switch feature {
        case .emiCalculator, .singleScenario:
            // Always available in free tier
            return true
        case .unlimitedScenarios, .prepaymentOptimizer, .refinanceChecker, .pdfExport:
            return tier == .paid
        }
    }

    /// Returns list of locked features for the current tier (useful for paywall UI).
    public func lockedFeatures() -> [Feature] {
        Feature.allCases.filter { !isUnlocked($0) }
    }
}

// MARK: - Scenario Usage Tracker

/// Tracks how many scenarios the user has run in the current session.
/// Free users get 1 scenario; paid users get unlimited.
public final class ScenarioUsageTracker: @unchecked Sendable {
    private var scenariosRun: Int = 0
    private let access: FeatureAccess
    private let lock = NSLock()

    public init(access: FeatureAccess) {
        self.access = access
    }

    /// Returns true if the user can run another scenario.
    public func canRunScenario() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if access.isUnlocked(.unlimitedScenarios) {
            return true
        }
        return scenariosRun < 1
    }

    /// Records that a scenario was run. Returns false if limit exceeded.
    @discardableResult
    public func recordScenarioRun() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if access.isUnlocked(.unlimitedScenarios) {
            scenariosRun += 1
            return true
        }
        if scenariosRun < 1 {
            scenariosRun += 1
            return true
        }
        return false
    }

    /// Resets the counter (e.g., on subscription upgrade).
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        scenariosRun = 0
    }

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return scenariosRun
    }
}
