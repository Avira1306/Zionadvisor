import Foundation

// MARK: - Result Summary

/// Aggregated output shown on the one-screen savings summary.
/// Every field answers: "How much ₹ will I save?"
public struct ResultSummary: Codable, Sendable {
    /// Total interest remaining under current terms in ₹.
    public let totalInterestWithoutOptimization: Double

    /// Total interest after applying the optimization scenario in ₹.
    public let totalInterestWithOptimization: Double

    /// Interest saved = without − with, in ₹.
    public let interestSaved: Double

    /// Number of months reduced from original tenure.
    public let tenureReducedMonths: Int

    /// EMI reduction if user keeps same tenure but applies prepayments, in ₹.
    public let emiReducedAmount: Double

    /// Net savings from refinancing (interest saved minus costs), in ₹. Nil if refinancing not evaluated.
    public let refinanceNetSavings: Double?

    /// Months to recover refinancing costs. Nil if refinancing not evaluated.
    public let breakEvenMonths: Int?

    /// Whether refinancing makes mathematical sense.
    public let refinanceMakesSense: Bool?

    /// Best year to make prepayment (1-based year index from now).
    public let bestPrepaymentYear: Int?

    /// Confidence score 0.0–1.0 derived from savings magnitude relative to total interest.
    /// Higher = more impactful optimization.
    public let confidenceScore: Double

    public init(
        totalInterestWithoutOptimization: Double,
        totalInterestWithOptimization: Double,
        interestSaved: Double,
        tenureReducedMonths: Int,
        emiReducedAmount: Double,
        refinanceNetSavings: Double? = nil,
        breakEvenMonths: Int? = nil,
        refinanceMakesSense: Bool? = nil,
        bestPrepaymentYear: Int? = nil,
        confidenceScore: Double
    ) {
        self.totalInterestWithoutOptimization = totalInterestWithoutOptimization
        self.totalInterestWithOptimization = totalInterestWithOptimization
        self.interestSaved = interestSaved
        self.tenureReducedMonths = tenureReducedMonths
        self.emiReducedAmount = emiReducedAmount
        self.refinanceNetSavings = refinanceNetSavings
        self.breakEvenMonths = breakEvenMonths
        self.refinanceMakesSense = refinanceMakesSense
        self.bestPrepaymentYear = bestPrepaymentYear
        self.confidenceScore = confidenceScore
    }
}

// MARK: - Refinancing Result

/// Standalone refinancing analysis result.
public struct RefinancingResult: Codable, Sendable {
    /// Does refinancing save money after costs?
    public let makesSense: Bool

    /// Net savings in ₹ (interest saved − refinancing cost).
    public let netSavings: Double

    /// Months needed to recover the refinancing cost from monthly interest savings.
    public let breakEvenMonth: Int

    /// Total interest under current rate in ₹.
    public let interestAtCurrentRate: Double

    /// Total interest under new rate in ₹.
    public let interestAtNewRate: Double

    public init(
        makesSense: Bool,
        netSavings: Double,
        breakEvenMonth: Int,
        interestAtCurrentRate: Double,
        interestAtNewRate: Double
    ) {
        self.makesSense = makesSense
        self.netSavings = netSavings
        self.breakEvenMonth = breakEvenMonth
        self.interestAtCurrentRate = interestAtCurrentRate
        self.interestAtNewRate = interestAtNewRate
    }
}

// MARK: - Prepayment Analysis

/// Result of the prepayment simulator for a single year.
public struct PrepaymentYearResult: Codable, Sendable {
    /// Which year the prepayment is applied (1-based).
    public let year: Int

    /// Interest saved by prepaying in this year in ₹.
    public let interestSaved: Double

    /// Months reduced from tenure.
    public let tenureReduced: Int

    public init(year: Int, interestSaved: Double, tenureReduced: Int) {
        self.year = year
        self.interestSaved = interestSaved
        self.tenureReduced = tenureReduced
    }
}

// MARK: - EMI vs Tenure Trade-off

/// Comparison of keeping same EMI vs same tenure after optimization.
public struct EMITenureTradeOff: Codable, Sendable {
    /// Original EMI in ₹.
    public let originalEMI: Double

    /// Original tenure in months.
    public let originalTenure: Int

    // Option A: Keep same EMI → reduce tenure
    /// New tenure if EMI stays the same (months).
    public let reducedTenure: Int

    /// Interest saved by reducing tenure in ₹.
    public let interestSavedByReducingTenure: Double

    // Option B: Keep same tenure → reduce EMI
    /// New EMI if tenure stays the same in ₹.
    public let reducedEMI: Double

    /// Interest saved by reducing EMI in ₹.
    public let interestSavedByReducingEMI: Double

    public init(
        originalEMI: Double,
        originalTenure: Int,
        reducedTenure: Int,
        interestSavedByReducingTenure: Double,
        reducedEMI: Double,
        interestSavedByReducingEMI: Double
    ) {
        self.originalEMI = originalEMI
        self.originalTenure = originalTenure
        self.reducedTenure = reducedTenure
        self.interestSavedByReducingTenure = interestSavedByReducingTenure
        self.reducedEMI = reducedEMI
        self.interestSavedByReducingEMI = interestSavedByReducingEMI
    }
}
