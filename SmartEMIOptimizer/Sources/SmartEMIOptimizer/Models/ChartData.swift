import Foundation

// MARK: - Chart-Ready Data Structures
// These provide pre-computed arrays for UI charting libraries.
// No chart rendering here — just data shapes.

/// A single data point for time-series charts.
public struct TimeSeriesPoint: Codable, Sendable {
    /// Month number (1-based).
    public let month: Int
    /// Value in ₹.
    public let value: Double

    public init(month: Int, value: Double) {
        self.month = month
        self.value = value
    }
}

/// Bar/pie chart segment for interest breakdown.
public struct InterestBreakdown: Codable, Sendable {
    /// Interest you will pay in ₹.
    public let interestPaid: Double
    /// Interest you avoid by optimizing in ₹.
    public let interestAvoided: Double
    /// Principal repaid in ₹.
    public let principalRepaid: Double

    public init(interestPaid: Double, interestAvoided: Double, principalRepaid: Double) {
        self.interestPaid = interestPaid
        self.interestAvoided = interestAvoided
        self.principalRepaid = principalRepaid
    }
}

/// All chart data for a single scenario comparison.
public struct ChartDataSet: Codable, Sendable {
    /// Outstanding balance over time — original schedule.
    public let balanceOriginal: [TimeSeriesPoint]

    /// Outstanding balance over time — after optimization.
    public let balanceOptimized: [TimeSeriesPoint]

    /// Cumulative interest paid — original schedule.
    public let cumulativeInterestOriginal: [TimeSeriesPoint]

    /// Cumulative interest paid — after optimization.
    public let cumulativeInterestOptimized: [TimeSeriesPoint]

    /// Interest paid vs avoided summary.
    public let interestBreakdown: InterestBreakdown

    public init(
        balanceOriginal: [TimeSeriesPoint],
        balanceOptimized: [TimeSeriesPoint],
        cumulativeInterestOriginal: [TimeSeriesPoint],
        cumulativeInterestOptimized: [TimeSeriesPoint],
        interestBreakdown: InterestBreakdown
    ) {
        self.balanceOriginal = balanceOriginal
        self.balanceOptimized = balanceOptimized
        self.cumulativeInterestOriginal = cumulativeInterestOriginal
        self.cumulativeInterestOptimized = cumulativeInterestOptimized
        self.interestBreakdown = interestBreakdown
    }
}
