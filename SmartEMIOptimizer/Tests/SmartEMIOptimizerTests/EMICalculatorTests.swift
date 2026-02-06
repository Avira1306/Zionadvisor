import XCTest
@testable import SmartEMIOptimizer

final class EMICalculatorTests: XCTestCase {

    // MARK: - EMI Formula Tests

    func testEMICalculation_HomeLoan() {
        // ₹50,00,000 at 8.5% for 20 years (240 months)
        // Expected EMI ≈ ₹43,391
        let emi = EMICalculator.calculateEMI(principal: 5_000_000, annualRate: 8.5, tenureMonths: 240)
        XCTAssertEqual(emi, 43_391.38, accuracy: 1.0, "Home loan EMI should be approximately ₹43,391")
    }

    func testEMICalculation_PersonalLoan() {
        // ₹5,00,000 at 14% for 3 years (36 months)
        let emi = EMICalculator.calculateEMI(principal: 500_000, annualRate: 14.0, tenureMonths: 36)
        XCTAssertEqual(emi, 17_089.88, accuracy: 1.0, "Personal loan EMI should be approximately ₹17,090")
    }

    func testEMICalculation_CarLoan() {
        // ₹8,00,000 at 9.5% for 5 years (60 months)
        let emi = EMICalculator.calculateEMI(principal: 800_000, annualRate: 9.5, tenureMonths: 60)
        XCTAssertEqual(emi, 16_779.58, accuracy: 1.0, "Car loan EMI should be approximately ₹16,780")
    }

    func testEMICalculation_ZeroPrincipal() {
        let emi = EMICalculator.calculateEMI(principal: 0, annualRate: 8.5, tenureMonths: 240)
        XCTAssertEqual(emi, 0, "Zero principal should return zero EMI")
    }

    func testEMICalculation_ZeroRate() {
        let emi = EMICalculator.calculateEMI(principal: 1_000_000, annualRate: 0, tenureMonths: 120)
        XCTAssertEqual(emi, 0, "Zero rate returns 0 (edge case, not interest-free loan)")
    }

    // MARK: - Amortization Tests

    func testAmortizationScheduleLength() {
        let schedule = EMICalculator.amortizationSchedule(principal: 1_000_000, annualRate: 10.0, tenureMonths: 60)
        XCTAssertEqual(schedule.count, 60, "Schedule should have exactly 60 entries")
    }

    func testAmortizationBalanceReachesZero() {
        let schedule = EMICalculator.amortizationSchedule(principal: 1_000_000, annualRate: 10.0, tenureMonths: 60)
        guard let last = schedule.last else { return XCTFail("Schedule is empty") }
        XCTAssertEqual(last.remainingBalance, 0, accuracy: 1.0, "Balance should reach zero")
    }

    func testAmortizationTotalPrincipalEqualsPrincipal() {
        let principal = 1_000_000.0
        let schedule = EMICalculator.amortizationSchedule(principal: principal, annualRate: 10.0, tenureMonths: 60)
        let totalPrincipalPaid = schedule.reduce(0.0) { $0 + $1.principalPaid }
        XCTAssertEqual(totalPrincipalPaid, principal, accuracy: 10.0, "Total principal paid should equal original principal")
    }

    // MARK: - Prepayment Tests

    func testPrepaymentReducesTenure() {
        let baseSchedule = EMICalculator.amortizationSchedule(
            principal: 5_000_000, annualRate: 8.5, tenureMonths: 240
        )
        let prepaySchedule = EMICalculator.amortizationWithPrepayment(
            principal: 5_000_000, annualRate: 8.5, tenureMonths: 240,
            annualPrepayment: 200_000
        )
        XCTAssertLessThan(prepaySchedule.count, baseSchedule.count, "Prepayment should reduce tenure")
    }

    func testPrepaymentReducesInterest() {
        let baseInterest = EMICalculator.totalInterest(
            principal: 5_000_000, annualRate: 8.5, tenureMonths: 240
        )
        let prepaySchedule = EMICalculator.amortizationWithPrepayment(
            principal: 5_000_000, annualRate: 8.5, tenureMonths: 240,
            annualPrepayment: 200_000
        )
        let prepayInterest = prepaySchedule.reduce(0.0) { $0 + $1.interestPaid }
        XCTAssertLessThan(prepayInterest, baseInterest, "Prepayment should reduce total interest")
    }

    func testBestPrepaymentYearIsFirst() {
        // Earlier prepayment saves more interest
        let results = EMICalculator.bestPrepaymentYear(
            principal: 5_000_000, annualRate: 8.5, tenureMonths: 240,
            prepaymentAmount: 500_000
        )
        XCTAssertFalse(results.isEmpty, "Should have results")
        XCTAssertEqual(results.first?.year, 1, "Year 1 should save the most interest")
    }

    // MARK: - Refinancing Tests

    func testRefinancingMakesSense() {
        // Drop from 10% to 8% on ₹50L over 20 years, cost ₹50,000
        let result = EMICalculator.refinancingAnalysis(
            principal: 5_000_000,
            currentRate: 10.0,
            newRate: 8.0,
            tenureMonths: 240,
            refinancingCost: 50_000
        )
        XCTAssertTrue(result.makesSense, "2% rate drop on ₹50L should make sense")
        XCTAssertGreaterThan(result.netSavings, 0, "Net savings should be positive")
        XCTAssertLessThan(result.breakEvenMonth, 240, "Should break even before tenure ends")
    }

    func testRefinancingDoesNotMakeSense() {
        // Tiny rate drop with high cost
        let result = EMICalculator.refinancingAnalysis(
            principal: 500_000,
            currentRate: 9.0,
            newRate: 8.9,
            tenureMonths: 36,
            refinancingCost: 50_000
        )
        XCTAssertFalse(result.makesSense, "Tiny rate drop with high cost should not make sense")
    }

    // MARK: - EMI vs Tenure Trade-off

    func testEMITenureTradeOff() {
        let tradeOff = EMICalculator.emiTenureTradeOff(
            originalPrincipal: 5_000_000,
            reducedPrincipal: 4_500_000,
            annualRate: 8.5,
            originalTenureMonths: 240
        )
        XCTAssertLessThan(tradeOff.reducedTenure, tradeOff.originalTenure, "Reduced principal should reduce tenure")
        XCTAssertLessThan(tradeOff.reducedEMI, tradeOff.originalEMI, "Reduced principal should reduce EMI")
        XCTAssertGreaterThan(tradeOff.interestSavedByReducingTenure, 0, "Should save interest")
        XCTAssertGreaterThan(tradeOff.interestSavedByReducingEMI, 0, "Should save interest")
    }
}
