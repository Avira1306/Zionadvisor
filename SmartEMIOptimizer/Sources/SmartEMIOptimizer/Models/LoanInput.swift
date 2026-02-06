import Foundation

// MARK: - Loan Type

/// Supported loan categories in the Indian market.
public enum LoanType: String, Codable, CaseIterable, Sendable {
    case home
    case car
    case personal
}

// MARK: - Loan Input

/// Primary input model for all EMI calculations.
/// Max 6 user-facing inputs to keep UX clean.
public struct LoanInput: Codable, Sendable {
    /// Type of loan – affects typical rate ranges for validation.
    public let loanType: LoanType

    /// Original or outstanding principal in ₹.
    public let principalAmount: Double

    /// Annual interest rate as a percentage (e.g. 8.5 means 8.5%).
    public let annualInterestRate: Double

    /// Remaining loan tenure in months.
    public let remainingTenureMonths: Int

    // MARK: Optional fields (unlocked in paid tier)

    /// Annual lump-sum prepayment amount in ₹.
    public let annualPrepaymentAmount: Double?

    /// One-time cost of refinancing (processing fee, legal, etc.) in ₹.
    public let refinancingCost: Double?

    /// New annual interest rate being considered for refinancing.
    public let refinancedRate: Double?

    public init(
        loanType: LoanType,
        principalAmount: Double,
        annualInterestRate: Double,
        remainingTenureMonths: Int,
        annualPrepaymentAmount: Double? = nil,
        refinancingCost: Double? = nil,
        refinancedRate: Double? = nil
    ) {
        self.loanType = loanType
        self.principalAmount = principalAmount
        self.annualInterestRate = annualInterestRate
        self.remainingTenureMonths = remainingTenureMonths
        self.annualPrepaymentAmount = annualPrepaymentAmount
        self.refinancingCost = refinancingCost
        self.refinancedRate = refinancedRate
    }
}

// MARK: - Input Validation

public enum ValidationError: Error, LocalizedError, Sendable {
    case principalTooLow
    case principalTooHigh
    case rateTooLow
    case rateTooHigh
    case tenureTooShort
    case tenureTooLong
    case prepaymentExceedsPrincipal
    case refinancingCostNegative
    case refinancedRateNotLower

    public var errorDescription: String? {
        switch self {
        case .principalTooLow:
            return "Loan amount must be at least ₹10,000."
        case .principalTooHigh:
            return "Loan amount cannot exceed ₹50 crore."
        case .rateTooLow:
            return "Interest rate must be at least 1%."
        case .rateTooHigh:
            return "Interest rate cannot exceed 36%."
        case .tenureTooShort:
            return "Tenure must be at least 3 months."
        case .tenureTooLong:
            return "Tenure cannot exceed 360 months (30 years)."
        case .prepaymentExceedsPrincipal:
            return "Annual prepayment cannot exceed the principal amount."
        case .refinancingCostNegative:
            return "Refinancing cost cannot be negative."
        case .refinancedRateNotLower:
            return "Refinanced rate should be lower than current rate to make sense."
        }
    }
}

extension LoanInput {
    /// Validates all inputs against Indian market boundaries.
    /// Returns an array of validation errors (empty = valid).
    public func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // Principal: ₹10,000 to ₹50 crore
        if principalAmount < 10_000 { errors.append(.principalTooLow) }
        if principalAmount > 500_000_000 { errors.append(.principalTooHigh) }

        // Rate: 1% to 36% (covers all Indian loan types)
        if annualInterestRate < 1.0 { errors.append(.rateTooLow) }
        if annualInterestRate > 36.0 { errors.append(.rateTooHigh) }

        // Tenure: 3 months to 30 years
        if remainingTenureMonths < 3 { errors.append(.tenureTooShort) }
        if remainingTenureMonths > 360 { errors.append(.tenureTooLong) }

        // Prepayment sanity
        if let prepayment = annualPrepaymentAmount, prepayment > principalAmount {
            errors.append(.prepaymentExceedsPrincipal)
        }

        // Refinancing sanity
        if let cost = refinancingCost, cost < 0 {
            errors.append(.refinancingCostNegative)
        }
        if let newRate = refinancedRate, newRate >= annualInterestRate {
            errors.append(.refinancedRateNotLower)
        }

        return errors
    }
}
