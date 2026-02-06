import Foundation

// MARK: - Scenario Engine
// Orchestrates the calculation engine to produce a full ResultSummary + ChartData
// from a single LoanInput. This is the main entry point for the UI layer.

public enum ScenarioEngine {

    /// Runs a complete optimization analysis on the given loan input.
    /// Returns both the summary numbers and chart-ready data.
    ///
    /// This function does NOT give advice — it computes scenarios and reports numbers.
    public static func analyze(input: LoanInput) -> (summary: ResultSummary, chartData: ChartDataSet) {
        // --- Baseline (no optimization) ---
        let baseSchedule = EMICalculator.amortizationSchedule(
            principal: input.principalAmount,
            annualRate: input.annualInterestRate,
            tenureMonths: input.remainingTenureMonths
        )
        let baseInterest = baseSchedule.reduce(0.0) { $0 + $1.interestPaid }

        // --- Optimized schedule (with prepayments if provided) ---
        let optimizedSchedule: [AmortizationEntry]
        let prepaymentAmount = input.annualPrepaymentAmount ?? 0

        if prepaymentAmount > 0 {
            optimizedSchedule = EMICalculator.amortizationWithPrepayment(
                principal: input.principalAmount,
                annualRate: input.annualInterestRate,
                tenureMonths: input.remainingTenureMonths,
                annualPrepayment: prepaymentAmount
            )
        } else {
            optimizedSchedule = baseSchedule
        }

        let optimizedInterest = optimizedSchedule.reduce(0.0) { $0 + $1.interestPaid }
        let interestSaved = baseInterest - optimizedInterest
        let tenureReduced = baseSchedule.count - optimizedSchedule.count

        // --- EMI reduction (same tenure, reduced principal after 1 year of prepayment) ---
        let emiReduction: Double
        if prepaymentAmount > 0 {
            let reducedPrincipal = input.principalAmount - prepaymentAmount
            let reducedEMI = EMICalculator.calculateEMI(
                principal: max(reducedPrincipal, 0),
                annualRate: input.annualInterestRate,
                tenureMonths: input.remainingTenureMonths
            )
            let originalEMI = EMICalculator.calculateEMI(
                principal: input.principalAmount,
                annualRate: input.annualInterestRate,
                tenureMonths: input.remainingTenureMonths
            )
            emiReduction = originalEMI - reducedEMI
        } else {
            emiReduction = 0
        }

        // --- Best prepayment year ---
        let bestYear: Int?
        if prepaymentAmount > 0 {
            let yearResults = EMICalculator.bestPrepaymentYear(
                principal: input.principalAmount,
                annualRate: input.annualInterestRate,
                tenureMonths: input.remainingTenureMonths,
                prepaymentAmount: prepaymentAmount
            )
            bestYear = yearResults.first?.year
        } else {
            bestYear = nil
        }

        // --- Refinancing analysis ---
        let refinanceResult: RefinancingResult?
        if let newRate = input.refinancedRate, let cost = input.refinancingCost {
            refinanceResult = EMICalculator.refinancingAnalysis(
                principal: input.principalAmount,
                currentRate: input.annualInterestRate,
                newRate: newRate,
                tenureMonths: input.remainingTenureMonths,
                refinancingCost: cost
            )
        } else {
            refinanceResult = nil
        }

        // --- Confidence score ---
        // Based on how significant the savings are relative to total interest.
        // 0 savings = 0 confidence, savings >= 20% of total interest = 1.0
        let confidenceScore: Double
        if baseInterest > 0 {
            let ratio = interestSaved / baseInterest
            confidenceScore = min(max(ratio / 0.20, 0.0), 1.0)
        } else {
            confidenceScore = 0
        }

        // --- Build chart data ---
        let chartData = buildChartData(
            baseSchedule: baseSchedule,
            optimizedSchedule: optimizedSchedule,
            principal: input.principalAmount,
            baseInterest: baseInterest,
            optimizedInterest: optimizedInterest
        )

        // --- Assemble summary ---
        let summary = ResultSummary(
            totalInterestWithoutOptimization: round2(baseInterest),
            totalInterestWithOptimization: round2(optimizedInterest),
            interestSaved: round2(interestSaved),
            tenureReducedMonths: tenureReduced,
            emiReducedAmount: round2(emiReduction),
            refinanceNetSavings: refinanceResult.map { round2($0.netSavings) },
            breakEvenMonths: refinanceResult?.breakEvenMonth,
            refinanceMakesSense: refinanceResult?.makesSense,
            bestPrepaymentYear: bestYear,
            confidenceScore: (confidenceScore * 100).rounded() / 100.0
        )

        return (summary, chartData)
    }

    // MARK: - Chart Data Builder

    private static func buildChartData(
        baseSchedule: [AmortizationEntry],
        optimizedSchedule: [AmortizationEntry],
        principal: Double,
        baseInterest: Double,
        optimizedInterest: Double
    ) -> ChartDataSet {
        // Balance over time
        let balanceOriginal = baseSchedule.map {
            TimeSeriesPoint(month: $0.month, value: $0.remainingBalance)
        }
        let balanceOptimized = optimizedSchedule.map {
            TimeSeriesPoint(month: $0.month, value: $0.remainingBalance)
        }

        // Cumulative interest over time
        var cumOriginal: Double = 0
        let cumulativeInterestOriginal = baseSchedule.map { entry -> TimeSeriesPoint in
            cumOriginal += entry.interestPaid
            return TimeSeriesPoint(month: entry.month, value: round2(cumOriginal))
        }

        var cumOptimized: Double = 0
        let cumulativeInterestOptimized = optimizedSchedule.map { entry -> TimeSeriesPoint in
            cumOptimized += entry.interestPaid
            return TimeSeriesPoint(month: entry.month, value: round2(cumOptimized))
        }

        let breakdown = InterestBreakdown(
            interestPaid: round2(optimizedInterest),
            interestAvoided: round2(baseInterest - optimizedInterest),
            principalRepaid: round2(principal)
        )

        return ChartDataSet(
            balanceOriginal: balanceOriginal,
            balanceOptimized: balanceOptimized,
            cumulativeInterestOriginal: cumulativeInterestOriginal,
            cumulativeInterestOptimized: cumulativeInterestOptimized,
            interestBreakdown: breakdown
        )
    }

    private static func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100.0
    }
}
