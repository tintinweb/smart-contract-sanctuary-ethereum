// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LoanLibrary {
    using SafeMath for uint256;

    /// Supported NFT Standard
    enum Standard {
        ERC721,
        ERC1155
    }

    /// Loan Status
    enum LoanStatus {
        ACTIVE,
        CANCELLED,
        DEFAULTED,
        LIQUIDATED,
        PAID,
        RECRUITING,
        SOLD
    }

    /// Loan structure
    /// developer note might be able to put some of these fields in IPFS to save gas
    /// field nftHolder The borrower address, holds the NFTs that is being borrowed against
    /// field nftContracts list of NFT contracts collateral that are part of the loan
    /// field nftTokenIds list of NFT tokenIds collateral that are part of the loan
    /// field nftTokenAmounts list of NFT tokenAmounts collateral that are part of the loan - typically should only be 1
    /// field standards list of NFT standards collateral that are part of the loan
    /// field nftEstimatedValue the estimated value of the NFTs put forth by the borrower
    /// field loanAmount The loan amount that is being asked for
    /// field loanDuration The loan duration that is being asked for
    /// field created The creation timestamp when the loan is created
    /// field loanStart The start timestamp when the loan is activated
    /// field fractionalizedTokenId The tokenId of the 1155 minted token distributed to the loan providers
    /// field status The status of the loan
    /// field loanNftCollateralTokenId The LoanCollateral tokenID created to represent the loan and distributed to the borrower
    /// field calculatedApr The calculated APR of all the accepted bids
    /// field description The description of the loan collateral
    struct Loan {
        address nftHolder;                      // 0
        address[] nftContracts;                 // 1
        uint256[] nftTokenIds;                  // 2
        uint256[] nftTokenAmounts;              // 3
        Standard[] standards;                   // 4
        uint256 nftEstimatedValue;              // 5
        uint256 loanAmount;                     // 6
        uint256 loanDuration;                   // 7
        uint256 created;                        // 8
        uint256 loanStart;                      // 9
        uint256 fractionalizedTokenId;          // 10
        LoanStatus status;                      // 11
        uint256 loanCollateralNftTokenId;       // 12
        uint256 calculatedApr;                  // 13
        string description;                     // 14
    }

    /// Bid Status - the possible statuses of a bid
    enum LoanBidStatus {
        ACCEPTED,
        PENDING,
        DENIED
    }

    /// Provider Loan Bid Structure
    struct LoanBid {
        uint256 loanBidId;
        uint256 loanId;
        address provider;
        uint256 offered;
        uint256 apr;
        uint256 created;
        uint256 acceptedAmount;
        LoanBidStatus status;
    }

    /// The structure of a loan payment
    struct LoanPayment {
        uint256 paymentId;
        address payer;
        uint256 loanId;
        uint256 amount;
        uint256 created;
    }

    /// @notice calculate yearly gross
    /// @param _amount The amount from a loan
    /// @param _apr The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @return amount + the year interest revenue
    function calculateYearlyGross(uint256 _amount, uint256 _apr, uint256 _precision) public pure returns (uint256) {
        return _amount + calculateYearlyInterestRevenue(_amount, _apr, _precision);
    }

    /// @notice calculate yearly interest revenue
    /// @param _amount The amount from a loan
    /// @param _apr The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @return the year interest revenue
    function calculateYearlyInterestRevenue(uint256 _amount, uint256 _apr, uint256 _precision) public pure returns (uint256) {
        return _amount.mul(_apr).div(_precision);
    }

    /// @notice calculate interest revenue for number of days
    /// @param _amount The amount from a loan
    /// @param _apr The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @param _days The number of days to calculate for interest earned
    /// @return the days interest revenue
    function calculateInterestRevenueForDays(uint256 _amount, uint256 _apr, uint256 _precision, uint256 _days) public pure returns (uint256) {
        uint256 yearlyInterestRevenue = calculateYearlyInterestRevenue(_amount, _apr, _precision);
        return yearlyInterestRevenue.mul(_days).div(365);
    }

    /// @notice calculate the percentage of an amount
    /// @dev (_amount * _percent) / _factor
    function calculatePercentage(uint256 _amount, uint256 _percent, uint256 _precision) public pure returns (uint256) {
        return _amount.mul(_percent).div(_precision);
    }

    /// @notice calculate the number of day between two timestamps
    /// @param _timestampBegin the beginning timestamp
    /// @param _timestampEnd the ending timestamp
    /// @return the number of days between the two timestamps
    /// @dev business logic dictates that point 0 is day 1
    function calculateDurationInDays(uint256 _timestampBegin, uint256 _timestampEnd) public pure returns (uint256) {
        require(_timestampBegin <= _timestampEnd, "The begin timestamp must be less than the end timestamp");
        uint256 day = 60 * 60 * 24;
        return _timestampEnd.sub(_timestampBegin).div(day) + 1;
    }

    /// @notice get the number of seconds for a period in days
    /// @param _period The period amount
    /// @return number of seconds in days for a given period
    function periodInDays(uint256 _period) public pure returns (uint256) {
        return _period.mul(60 * 60 * 24);
    }

    /// @notice get the number of seconds for a period in minutes
    /// @param _period The period amount
    /// @return number of seconds in minutes for a given period
    function periodInMinutes(uint256 _period) public pure returns (uint256) {
        return _period.mul(60 * 60);
    }
}

interface ERC1155_I {
    function setApprovalForAll(address _operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external;

    function balanceOf(address _address, uint256 _tokenId) external view returns (uint256 _balance);
}

interface ERC721_I {
    function isApprovedForAll(address _nftOwner, address _operator) external view returns (bool);

    function setApprovalForAll(address _operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address _address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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