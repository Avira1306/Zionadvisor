import Foundation

// MARK: - EMI Calculator
// Pure functions — no side effects, no state, no advice.
// All amounts in ₹, rates as annual percentages.

public enum EMICalculator {

    // MARK: - A. EMI Formula

    /// Calculates EMI using the standard reducing-balance formula:
    /// EMI = P × r × (1+r)^n / ((1+r)^n − 1)
    ///
    /// - Parameters:
    ///   - principal: Outstanding loan amount in ₹
    ///   - annualRate: Annual interest rate as percentage (e.g. 8.5)
    ///   - tenureMonths: Remaining tenure in months
    /// - Returns: Monthly EMI in ₹, rounded to 2 decimal places
    public static func calculateEMI(
        principal: Double,
        annualRate: Double,
        tenureMonths: Int
    ) -> Double {
        guard principal > 0, annualRate > 0, tenureMonths > 0 else { return 0 }

        let r = annualRate / (12.0 * 100.0) // Monthly rate as decimal
        let n = Double(tenureMonths)
        let onePlusR_n = pow(1.0 + r, n)

        let emi = principal * r * onePlusR_n / (onePlusR_n - 1.0)
        return (emi * 100).rounded() / 100.0
    }

    // MARK: - B. Amortization Schedule

    /// Generates a full month-by-month amortization schedule.
    /// No prepayments applied — use `amortizationWithPrepayment` for that.
    public static func amortizationSchedule(
        principal: Double,
        annualRate: Double,
        tenureMonths: Int
    ) -> [AmortizationEntry] {
        let emi = calculateEMI(principal: principal, annualRate: annualRate, tenureMonths: tenureMonths)
        guard emi > 0 else { return [] }

        let r = annualRate / (12.0 * 100.0)
        var balance = principal
        var schedule: [AmortizationEntry] = []

        for month in 1...tenureMonths {
            let interestComponent = balance * r
            let principalComponent = min(emi - interestComponent, balance)
            balance -= principalComponent

            // Handle floating-point dust on the last month
            if balance < 1.0 { balance = 0 }

            schedule.append(AmortizationEntry(
                month: month,
                emi: emi,
                principalPaid: (principalComponent * 100).rounded() / 100.0,
                interestPaid: (interestComponent * 100).rounded() / 100.0,
                remainingBalance: (balance * 100).rounded() / 100.0
            ))

            if balance <= 0 { break }
        }

        return schedule
    }

    /// Total interest paid over the full schedule.
    public static func totalInterest(
        principal: Double,
        annualRate: Double,
        tenureMonths: Int
    ) -> Double {
        let emi = calculateEMI(principal: principal, annualRate: annualRate, tenureMonths: tenureMonths)
        return (emi * Double(tenureMonths)) - principal
    }

    // MARK: - C. Prepayment Simulator

    /// Generates amortization schedule with an annual lump-sum prepayment.
    /// Prepayment is applied at the end of every 12th month (or a specific year).
    ///
    /// - Parameters:
    ///   - principal: Outstanding loan amount in ₹
    ///   - annualRate: Annual rate as percentage
    ///   - tenureMonths: Original remaining tenure
    ///   - annualPrepayment: Lump sum prepaid each year in ₹
    ///   - prepaymentStartYear: Year to start prepaying (1 = end of first year). Nil = every year.
    ///   - prepaymentEndYear: Year to stop prepaying. Nil = until loan closes.
    /// - Returns: Amortization entries with prepayments applied.
    public static func amortizationWithPrepayment(
        principal: Double,
        annualRate: Double,
        tenureMonths: Int,
        annualPrepayment: Double,
        prepaymentStartYear: Int? = nil,
        prepaymentEndYear: Int? = nil
    ) -> [AmortizationEntry] {
        let emi = calculateEMI(principal: principal, annualRate: annualRate, tenureMonths: tenureMonths)
        guard emi > 0 else { return [] }

        let r = annualRate / (12.0 * 100.0)
        var balance = principal
        var schedule: [AmortizationEntry] = []
        let startYear = prepaymentStartYear ?? 1
        let endYear = prepaymentEndYear ?? (tenureMonths / 12 + 1)

        for month in 1...tenureMonths {
            let interestComponent = balance * r
            let principalComponent = min(emi - interestComponent, balance)
            balance -= principalComponent

            // Apply prepayment at end of each 12-month cycle
            var prepaymentThisMonth: Double = 0
            if month % 12 == 0 {
                let currentYear = month / 12
                if currentYear >= startYear && currentYear <= endYear && balance > 0 {
                    prepaymentThisMonth = min(annualPrepayment, balance)
                    balance -= prepaymentThisMonth
                }
            }

            if balance < 1.0 { balance = 0 }

            schedule.append(AmortizationEntry(
                month: month,
                emi: emi,
                principalPaid: (principalComponent * 100).rounded() / 100.0,
                interestPaid: (interestComponent * 100).rounded() / 100.0,
                prepaymentApplied: (prepaymentThisMonth * 100).rounded() / 100.0,
                remainingBalance: (balance * 100).rounded() / 100.0
            ))

            if balance <= 0 { break }
        }

        return schedule
    }

    /// Finds the single best year to make a one-time prepayment for maximum interest savings.
    /// Tests each year independently and returns results sorted by interest saved (descending).
    public static func bestPrepaymentYear(
        principal: Double,
        annualRate: Double,
        tenureMonths: Int,
        prepaymentAmount: Double
    ) -> [PrepaymentYearResult] {
        let baseInterest = totalInterest(principal: principal, annualRate: annualRate, tenureMonths: tenureMonths)
        let baseTenure = tenureMonths
        let maxYears = tenureMonths / 12

        guard maxYears > 0 else { return [] }

        var results: [PrepaymentYearResult] = []

        for year in 1...maxYears {
            let schedule = amortizationWithPrepayment(
                principal: principal,
                annualRate: annualRate,
                tenureMonths: tenureMonths,
                annualPrepayment: prepaymentAmount,
                prepaymentStartYear: year,
                prepaymentEndYear: year
            )

            let optimizedInterest = schedule.reduce(0.0) { $0 + $1.interestPaid }
            let optimizedTenure = schedule.count
            let saved = baseInterest - optimizedInterest
            let tenureReduced = baseTenure - optimizedTenure

            if saved > 0 {
                results.append(PrepaymentYearResult(
                    year: year,
                    interestSaved: (saved * 100).rounded() / 100.0,
                    tenureReduced: tenureReduced
                ))
            }
        }

        // Earlier years save more interest — sort descending by savings
        return results.sorted { $0.interestSaved > $1.interestSaved }
    }

    // MARK: - D. EMI vs Tenure Trade-off

    /// Compares two options after a reduction in effective principal (e.g., via prepayment):
    /// Option A: Keep same EMI → how many months less?
    /// Option B: Keep same tenure → how much lower EMI?
    public static func emiTenureTradeOff(
        originalPrincipal: Double,
        reducedPrincipal: Double,
        annualRate: Double,
        originalTenureMonths: Int
    ) -> EMITenureTradeOff {
        let originalEMI = calculateEMI(
            principal: originalPrincipal,
            annualRate: annualRate,
            tenureMonths: originalTenureMonths
        )
        let originalTotalInterest = totalInterest(
            principal: originalPrincipal,
            annualRate: annualRate,
            tenureMonths: originalTenureMonths
        )

        // Option A: Same EMI, find reduced tenure
        // Solve for n: n = -log(1 - P*r/EMI) / log(1+r)
        let r = annualRate / (12.0 * 100.0)
        let reducedTenure: Int
        let prOverEMI = reducedPrincipal * r / originalEMI
        if prOverEMI >= 1.0 {
            // EMI can't even cover interest — no reduction possible
            reducedTenure = originalTenureMonths
        } else {
            let nDouble = -log(1.0 - prOverEMI) / log(1.0 + r)
            reducedTenure = Int(ceil(nDouble))
        }
        let interestSavedByTenure = originalTotalInterest - totalInterest(
            principal: reducedPrincipal,
            annualRate: annualRate,
            tenureMonths: reducedTenure
        )

        // Option B: Same tenure, find reduced EMI
        let reducedEMI = calculateEMI(
            principal: reducedPrincipal,
            annualRate: annualRate,
            tenureMonths: originalTenureMonths
        )
        let interestSavedByEMI = originalTotalInterest - totalInterest(
            principal: reducedPrincipal,
            annualRate: annualRate,
            tenureMonths: originalTenureMonths
        )

        return EMITenureTradeOff(
            originalEMI: originalEMI,
            originalTenure: originalTenureMonths,
            reducedTenure: reducedTenure,
            interestSavedByReducingTenure: (interestSavedByTenure * 100).rounded() / 100.0,
            reducedEMI: reducedEMI,
            interestSavedByReducingEMI: (interestSavedByEMI * 100).rounded() / 100.0
        )
    }

    // MARK: - E. Refinancing Break-even

    /// Calculates whether refinancing to a lower rate saves money after accounting for costs.
    ///
    /// Mathematical output only — no recommendation.
    public static func refinancingAnalysis(
        principal: Double,
        currentRate: Double,
        newRate: Double,
        tenureMonths: Int,
        refinancingCost: Double
    ) -> RefinancingResult {
        let interestCurrent = totalInterest(
            principal: principal,
            annualRate: currentRate,
            tenureMonths: tenureMonths
        )
        let interestNew = totalInterest(
            principal: principal,
            annualRate: newRate,
            tenureMonths: tenureMonths
        )

        let grossSavings = interestCurrent - interestNew
        let netSavings = grossSavings - refinancingCost

        // Break-even: months until cumulative monthly savings exceed refinancing cost.
        // Monthly savings = old EMI - new EMI
        let oldEMI = calculateEMI(principal: principal, annualRate: currentRate, tenureMonths: tenureMonths)
        let newEMI = calculateEMI(principal: principal, annualRate: newRate, tenureMonths: tenureMonths)
        let monthlySaving = oldEMI - newEMI

        let breakEvenMonth: Int
        if monthlySaving <= 0 {
            breakEvenMonth = tenureMonths + 1 // Never breaks even
        } else {
            breakEvenMonth = Int(ceil(refinancingCost / monthlySaving))
        }

        return RefinancingResult(
            makesSense: netSavings > 0 && breakEvenMonth < tenureMonths,
            netSavings: (netSavings * 100).rounded() / 100.0,
            breakEvenMonth: breakEvenMonth,
            interestAtCurrentRate: (interestCurrent * 100).rounded() / 100.0,
            interestAtNewRate: (interestNew * 100).rounded() / 100.0
        )
    }
}
