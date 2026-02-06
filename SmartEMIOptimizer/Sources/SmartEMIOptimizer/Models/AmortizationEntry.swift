import Foundation

// MARK: - Amortization Schedule Entry

/// One row of the amortization table.
public struct AmortizationEntry: Codable, Sendable {
    /// Month number (1-based).
    public let month: Int

    /// EMI paid this month in ₹.
    public let emi: Double

    /// Principal component of this month's EMI in ₹.
    public let principalPaid: Double

    /// Interest component of this month's EMI in ₹.
    public let interestPaid: Double

    /// Any extra prepayment applied this month in ₹.
    public let prepaymentApplied: Double

    /// Outstanding balance after this month's payment in ₹.
    public let remainingBalance: Double

    public init(
        month: Int,
        emi: Double,
        principalPaid: Double,
        interestPaid: Double,
        prepaymentApplied: Double = 0,
        remainingBalance: Double
    ) {
        self.month = month
        self.emi = emi
        self.principalPaid = principalPaid
        self.interestPaid = interestPaid
        self.prepaymentApplied = prepaymentApplied
        self.remainingBalance = remainingBalance
    }
}
