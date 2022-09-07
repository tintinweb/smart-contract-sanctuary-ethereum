// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Borrower__InvalidTimestamp();
error Borrower__InvalidInterestPoolRates();
error Borrower__LateFeeNotPaid();

import "./SafeMath.sol";

/**
 * @title Borrower
 * @notice This contract works as a record for the borrower
 * @author Erly Stage Studios
 */
contract Borrower {
    using SafeMath for uint256;
    // THE DATA HAS TO BE IN PRECISION FORM
    struct PaymentAllocation {
        uint256 interestPayment;
        uint256 principalPayment;
        uint256 additionalBalancePayment;
    }
    struct PaymentScheme {
        uint256 interestPayment;
        uint256 principalPayment;
        string timestamp;
    }
    uint256 private constant PRECISION = 10**10;
    uint256 private constant SECONDS_IN_A_MONTH = 2.628e6;
    address private immutable i_borrowerWallet;
    uint256 private immutable i_principalAmount;
    uint256 private immutable i_interestRate;
    uint256 private immutable i_termInMonths;
    uint256 private immutable i_juniorPoolInterest;
    uint256 private immutable i_seniorPoolInterest;
    string[] private i_collateralHashs;
    uint256 private immutable i_lateFee;
    uint256 private s_lastBlockTimestamp;
    PaymentScheme[] private s_paymentScheme;
    mapping(string => PaymentAllocation) s_fundRecord;
    uint256 private s_monthsPaid;
    uint256 private s_remainingAmount;

    event contractCreated(address walletAddress);
    event fundRecorded(string timestamp);
    event paymentSchemeUpdated(PaymentScheme[] scheme);

    /**
     * @notice constructor for the contract
     * @param walletAddress: the wallet address of the borrower
     * @param principalAmount: the amount the borrower wants to borrow
     * @param interestRate: the amount of interest applied on the loan
     * @param termInMonths: the number of months for the repayment
     * @param juniorInterest: the interest given to junior pool
     * @param seniorInterest: the interest given to senior pool
     * @param collaterals: the list of collaterals for the loan
     * @param lateFee: the fee charged if the payment is not made on time
     * @param interestPayments: the list of interest payments to be paid monthly
     * @param principalPayments: the list of principal payments to be pain monthly
     * @param timestamps: the list of timestamps at which the payments are to be made
     */
    constructor(
        address walletAddress,
        uint256 principalAmount,
        uint256 interestRate,
        uint256 termInMonths,
        uint256 juniorInterest,
        uint256 seniorInterest,
        string[] memory collaterals,
        uint256 lateFee,
        uint256[] memory interestPayments,
        uint256[] memory principalPayments,
        string[] memory timestamps
    ) {
        if (juniorInterest <= seniorInterest) {
            revert Borrower__InvalidInterestPoolRates();
        }
        i_borrowerWallet = walletAddress;
        i_principalAmount = principalAmount;
        i_interestRate = interestRate;
        i_termInMonths = termInMonths;
        i_collateralHashs = collaterals;
        i_juniorPoolInterest = juniorInterest;
        i_seniorPoolInterest = seniorInterest;
        i_lateFee = lateFee;
        s_lastBlockTimestamp = block.timestamp;
        for (uint256 i = 0; i < i_termInMonths; i++) {
            s_paymentScheme.push();
            s_paymentScheme[i] = PaymentScheme(
                interestPayments[i],
                principalPayments[i],
                timestamps[i]
            );
        }
        s_remainingAmount = principalAmount * PRECISION;
        emit contractCreated(walletAddress);
    }

    /**
     * @notice Update the new payment scheme in case of partial payments
     * @param interestPayments: a list of interest Payments for the upcoming months
     * @param principalPayments: a list of principal payments for the upcoming months
     * @param timestamps : a list of the timestamps involving the months to pay in
     */
    function updatePaymentScheme(
        uint256[] memory interestPayments,
        uint256[] memory principalPayments,
        string[] memory timestamps
    ) external {
        delete s_paymentScheme;
        for (uint256 i = 0; i < i_termInMonths - s_monthsPaid; i++) {
            s_paymentScheme.push();
            s_paymentScheme[i] = PaymentScheme(
                interestPayments[i],
                principalPayments[i],
                timestamps[i]
            );
        }
        emit paymentSchemeUpdated(s_paymentScheme);
    }

    /**
     * @notice Record a Monthly Payment Return and check if late fee is paid
     * @param timestamp: the month in which the payment was made
     * @param interestPayment: the interest paid for the month
     * @param principalPayment: the principal amount paid for the month
     * @param lateFee: the additional late Fee if paid
     */
    function loanPaymentReturn(
        string memory timestamp,
        uint256 interestPayment,
        uint256 principalPayment,
        uint256 lateFee
    ) external {
        if (isLate() && lateFee == 0) {
            revert Borrower__LateFeeNotPaid();
        }
        s_fundRecord[timestamp] = PaymentAllocation(
            interestPayment,
            principalPayment,
            lateFee
        );
        s_lastBlockTimestamp = block.timestamp;
        s_monthsPaid++;
        s_remainingAmount = s_remainingAmount.sub(principalPayment);
        emit fundRecorded(timestamp);
    }

    /**
     * @notice Check if the payment was made for a specific month
     * @param timestamp : the time at which we want to check if the payment exists
     * @return paymentAllocation object consisting of the interest, principal and additionally paid amount
     */
    function getPaymentStatus(string memory timestamp)
        external
        view
        returns (PaymentAllocation memory)
    {
        PaymentAllocation memory fund = s_fundRecord[timestamp];
        if (fund.principalPayment <= 0) {
            revert Borrower__InvalidTimestamp();
        }
        return fund;
    }

    /**
     * @notice check if the borrower is late on a payment
     * @return bool : true or false
     */
    function isLate() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (currentTime.sub(s_lastBlockTimestamp) > SECONDS_IN_A_MONTH) {
            return true;
        }
        return false;
    }

    /**
     * @notice return the borrower's wallet address
     * @return address
     */
    function getWalletAddress() external view returns (address) {
        return i_borrowerWallet;
    }

    /**
     * @notice return the borrower's months paid
     * @return uint256
     */
    function getMonthsPaid() external view returns (uint256) {
        return s_monthsPaid;
    }

    /**
     * @notice return the borrower's principal requested amount
     * @return uint256
     */
    function getPrincipalAmount() external view returns (uint256) {
        return i_principalAmount;
    }

    /**
     * @notice return the borrower's interest rate
     * @return uint256
     */
    function getInterestRate() external view returns (uint256) {
        return i_interestRate;
    }

    /**
     * @notice return the borrower's term in months
     * @return uint256
     */
    function getTerm() external view returns (uint256) {
        return i_termInMonths;
    }

    /**
     * @notice return the borrower's collateral contents
     * @return string[]
     */
    function getCollateralHashs() external view returns (string[] memory) {
        return i_collateralHashs;
    }

    /**
     * @notice return the borrower's junior pool interest
     * @return uint256
     */
    function getJuniorPoolInterest() external view returns (uint256) {
        return i_juniorPoolInterest;
    }

    /**
     * @notice return the borrower's senior pool interest
     * @return uint256
     */
    function getSeniorPoolInterest() external view returns (uint256) {
        return i_seniorPoolInterest;
    }

    /**
     * @notice return the borrower's late fee amount
     * @return uint256
     */
    function getLateFee() external view returns (uint256) {
        return i_lateFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity >=0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}