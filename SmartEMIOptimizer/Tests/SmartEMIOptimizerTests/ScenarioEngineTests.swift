import XCTest
@testable import SmartEMIOptimizer

final class ScenarioEngineTests: XCTestCase {

    func testFullScenarioWithPrepayment() {
        let input = LoanInput(
            loanType: .home,
            principalAmount: 5_000_000,
            annualInterestRate: 8.5,
            remainingTenureMonths: 240,
            annualPrepaymentAmount: 200_000
        )

        let (summary, chartData) = ScenarioEngine.analyze(input: input)

        XCTAssertGreaterThan(summary.interestSaved, 0, "Should save interest with prepayment")
        XCTAssertGreaterThan(summary.tenureReducedMonths, 0, "Should reduce tenure")
        XCTAssertGreaterThan(summary.confidenceScore, 0, "Confidence should be positive")
        XCTAssertNotNil(summary.bestPrepaymentYear, "Should identify best prepayment year")

        // Chart data should have entries
        XCTAssertFalse(chartData.balanceOriginal.isEmpty)
        XCTAssertFalse(chartData.balanceOptimized.isEmpty)
        XCTAssertGreaterThan(chartData.interestBreakdown.interestAvoided, 0)
    }

    func testScenarioWithRefinancing() {
        let input = LoanInput(
            loanType: .home,
            principalAmount: 5_000_000,
            annualInterestRate: 10.0,
            remainingTenureMonths: 240,
            refinancingCost: 50_000,
            refinancedRate: 8.0
        )

        let (summary, _) = ScenarioEngine.analyze(input: input)

        XCTAssertNotNil(summary.refinanceMakesSense)
        XCTAssertNotNil(summary.refinanceNetSavings)
        XCTAssertNotNil(summary.breakEvenMonths)
    }

    func testScenarioWithoutOptimization() {
        // No prepayment, no refinancing — baseline only
        let input = LoanInput(
            loanType: .personal,
            principalAmount: 500_000,
            annualInterestRate: 14.0,
            remainingTenureMonths: 36
        )

        let (summary, chartData) = ScenarioEngine.analyze(input: input)

        XCTAssertEqual(summary.interestSaved, 0, "No optimization = no savings")
        XCTAssertEqual(summary.tenureReducedMonths, 0)
        XCTAssertEqual(summary.confidenceScore, 0)
        XCTAssertNil(summary.refinanceMakesSense)

        // Chart data should still be present (baseline)
        XCTAssertFalse(chartData.balanceOriginal.isEmpty)
    }
}

final class ValidationTests: XCTestCase {

    func testValidInput() {
        let input = LoanInput(
            loanType: .home,
            principalAmount: 5_000_000,
            annualInterestRate: 8.5,
            remainingTenureMonths: 240
        )
        XCTAssertTrue(input.validate().isEmpty, "Valid input should have no errors")
    }

    func testInvalidPrincipal() {
        let input = LoanInput(
            loanType: .personal,
            principalAmount: 100, // Too low
            annualInterestRate: 14.0,
            remainingTenureMonths: 36
        )
        let errors = input.validate()
        XCTAssertTrue(errors.contains(.principalTooLow))
    }

    func testInvalidRate() {
        let input = LoanInput(
            loanType: .car,
            principalAmount: 800_000,
            annualInterestRate: 50.0, // Too high
            remainingTenureMonths: 60
        )
        let errors = input.validate()
        XCTAssertTrue(errors.contains(.rateTooHigh))
    }

    func testPrepaymentExceedsPrincipal() {
        let input = LoanInput(
            loanType: .personal,
            principalAmount: 100_000,
            annualInterestRate: 12.0,
            remainingTenureMonths: 24,
            annualPrepaymentAmount: 200_000
        )
        let errors = input.validate()
        XCTAssertTrue(errors.contains(.prepaymentExceedsPrincipal))
    }

    func testRefinancedRateNotLower() {
        let input = LoanInput(
            loanType: .home,
            principalAmount: 5_000_000,
            annualInterestRate: 8.5,
            remainingTenureMonths: 240,
            refinancingCost: 30_000,
            refinancedRate: 9.0 // Higher, not lower
        )
        let errors = input.validate()
        XCTAssertTrue(errors.contains(.refinancedRateNotLower))
    }
}

final class FeatureAccessTests: XCTestCase {

    func testFreeUserAccess() {
        let access = FeatureAccess(tier: .free)
        XCTAssertTrue(access.isUnlocked(.emiCalculator))
        XCTAssertTrue(access.isUnlocked(.singleScenario))
        XCTAssertFalse(access.isUnlocked(.unlimitedScenarios))
        XCTAssertFalse(access.isUnlocked(.prepaymentOptimizer))
        XCTAssertFalse(access.isUnlocked(.refinanceChecker))
        XCTAssertFalse(access.isUnlocked(.pdfExport))
    }

    func testPaidUserAccess() {
        let access = FeatureAccess(tier: .paid)
        for feature in Feature.allCases {
            XCTAssertTrue(access.isUnlocked(feature), "\(feature) should be unlocked for paid users")
        }
    }

    func testScenarioUsageTrackerFreeUser() {
        let tracker = ScenarioUsageTracker(access: FeatureAccess(tier: .free))
        XCTAssertTrue(tracker.canRunScenario())
        XCTAssertTrue(tracker.recordScenarioRun())
        XCTAssertFalse(tracker.canRunScenario(), "Free user should be limited to 1 scenario")
        XCTAssertFalse(tracker.recordScenarioRun())
    }

    func testScenarioUsageTrackerPaidUser() {
        let tracker = ScenarioUsageTracker(access: FeatureAccess(tier: .paid))
        for _ in 0..<100 {
            XCTAssertTrue(tracker.recordScenarioRun())
        }
        XCTAssertTrue(tracker.canRunScenario(), "Paid user should have unlimited scenarios")
    }
}
