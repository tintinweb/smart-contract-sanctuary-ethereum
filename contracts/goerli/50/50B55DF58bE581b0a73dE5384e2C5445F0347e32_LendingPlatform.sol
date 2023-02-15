// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./loan.sol";

contract LendingPlatform {

    IERC20 public coins;
    uint public loanProposalsSubmitted;
    mapping(uint => address) public loanAddressByID;
    mapping(address => uint[]) loanProposalIDsCreatedBy;
    mapping(address => uint[]) loanIDsLentBy;

    constructor(address erc20TokenContractAddr) {
        coins = IERC20(erc20TokenContractAddr);
    }

    error TooHighLoanID(uint maximumLoanID, uint givenLoanID);
    error InsufficientAllowance(uint requiredAllowance, uint currentAllowance);
    error InsufficientBalance(uint requiredBalance, uint currentBalance);

    event NewLoanProposal(address proposer, uint loanId, address loanAddress, uint principal, uint interestRatePerTenThousand, uint termInYears, string title, string description);
    event GotALender(address lender, uint loanId, uint amountProvided, uint amountLent, bool principalMet);
    event LoanRepaid(address repayer, uint loanId, uint repaymentAmount);
    event LoanDisbursed(uint loanId, uint disbursedAt, uint dueAt);
    event LoanSharePaid(uint loanId, address lender, uint lentAmount, uint amountWithInterest);

    modifier validLoanID(uint loanID) {
        require(loanID > 0, "loan ID must be a positive integer");
        if (loanID > loanProposalsSubmitted) {
            revert TooHighLoanID({
                maximumLoanID: loanProposalsSubmitted,
                givenLoanID: loanID
            });
        }
        _;
    }

    function addLoanIDAsLent(uint loanID, address lender) internal returns (bool) {
        uint[] storage lentLoanIDs = loanIDsLentBy[lender];
        for (uint i = 0; i < lentLoanIDs.length; i++) {
            if (lentLoanIDs[i] == loanID) {
                return false;
            }
        }
        lentLoanIDs.push(loanID);
        return true;
    }

    function newLoanProposal(uint principal, uint interestRatePerTenThousand, uint termInYears, string memory title, string memory description) external returns (uint, address) {
        uint currentLoanID = loanProposalsSubmitted + 1;
        Loan currentLoan = new Loan(currentLoanID, msg.sender, principal, interestRatePerTenThousand, termInYears, address(coins), title, description);
        loanAddressByID[currentLoanID] = address(currentLoan);
        loanProposalIDsCreatedBy[msg.sender].push(currentLoanID);
        loanProposalsSubmitted = currentLoanID;

        emit NewLoanProposal(msg.sender, currentLoanID, address(currentLoan), principal, interestRatePerTenThousand, termInYears, title, description);
        return (currentLoanID, address(currentLoan));
    }

    function lend(uint loanID, uint amount) external validLoanID(loanID) returns (uint) {
        // check if amount is positive
        require(amount > 0, "lend amount must be a positive integer");
        address lender = msg.sender;
        address loanCntr = loanAddressByID[loanID];
        // get the loan contract
        Loan l = Loan(loanCntr);
        // track this lend in the loan contract and get the amount lent
        uint amountLent;
        bool principalMet;
        (amountLent, principalMet) = l.trackLend(lender, amount);
        // check the allowance the caller has granted to the platform
        uint currAllowance = coins.allowance(lender, address(this));
        if (currAllowance < amountLent) {
            revert InsufficientAllowance({
                requiredAllowance: amountLent,
                currentAllowance: currAllowance
            });
        }
        uint currBalance = coins.balanceOf(lender);
        if (currBalance < amountLent) {
            revert InsufficientBalance({
                requiredBalance: amountLent,
                currentBalance: currBalance
            });
        }
        emit GotALender(lender, loanID, amount, amountLent, principalMet);
        // transfer the tokens to the loan contract
        coins.transferFrom(lender, loanCntr, amountLent);
        // add this loanID to the list of loanIDs lent by this lender
        addLoanIDAsLent(loanID, lender);
        // if principal is met, process borrow
        if (principalMet) {
            l.updateLoanStatusToDisbursed();
            emit LoanDisbursed(l.id(), l.disbursedAt(), l.dueAt());
            l.transferPrincipalToBorrower();
        }
        return amountLent;
    }

    function _outstandingAmount(uint loanID) internal validLoanID(loanID) view returns (uint) {
        address loanCntr = loanAddressByID[loanID];
        return Loan(loanCntr).totalAmountDue();
    }

    function outstandingAmount(uint loanID) external view returns (uint) {
        return _outstandingAmount(loanID);
    }

    function repay(uint loanID) external validLoanID(loanID) returns (bool) {
        address repayer = msg.sender;
        // caller should be the borrower of the loan
        Loan currLoan = Loan(loanAddressByID[loanID]);
        require(repayer == currLoan.borrower(), "only borrower can repay the loan");
        // get the outstanding amount
        uint repaymentAmount = _outstandingAmount(loanID);
        // check if the borrower has approved the lending platform with the outstanding amount
        uint currAllowance = coins.allowance(repayer, address(this));
        if (currAllowance < repaymentAmount) {
            revert InsufficientAllowance({
                requiredAllowance: repaymentAmount,
                currentAllowance: currAllowance
            });
        }
        // check if the borrower has atleast outstanding amount of tokens
        uint currBalance = coins.balanceOf(repayer);
        if (currBalance < repaymentAmount) {
            revert InsufficientBalance({
                requiredBalance: repaymentAmount,
                currentBalance: currBalance
            });
        }
        emit LoanRepaid(repayer, currLoan.id(), repaymentAmount);
        // transfer the tokens to the loan contract
        coins.transferFrom(repayer, address(currLoan), repaymentAmount);
        for (uint i = 0; i < currLoan.getLendersCount(); i++) {
            uint amountLent;
            uint amountDueToLender;
            // calculate the amount payable to each lender based on his share towards the total principal
            (amountLent, amountDueToLender) = currLoan.getAmountLentAndDue(i);
            emit LoanSharePaid(currLoan.id(), currLoan.lenders(i), amountLent, amountDueToLender);
        }
        currLoan.processLoanRepayment();
        return true;
    }

    function loanInfo(uint loanID) external validLoanID(loanID) view returns (string memory title, string memory description, address borrower, uint principal, uint interestRatePerTenThousand, uint termInYears, uint principalLent, string memory status) {
        Loan currLoan = Loan(loanAddressByID[loanID]);
        return (
            currLoan.title(),
            currLoan.description(),
            currLoan.borrower(),
            currLoan.principal(),
            currLoan.interestRatePerTenThousand(),
            currLoan.termInYears(),
            currLoan.principalLent(),
            currLoan.loanStatus()
        );
    }

    function _loanIDsLentBy(address caller) internal view returns (uint[] memory) {
        return loanIDsLentBy[caller];
    }

    function loanIDsLentByMe() external view returns (uint[] memory) {
        return _loanIDsLentBy(msg.sender);
    }

    function _loanProposalIDsCreatedBy(address caller) internal view returns (uint[] memory) {
        return loanProposalIDsCreatedBy[caller];
    }

    function loanProposalIDsCreatedByMe() external view returns (uint[] memory) {
        return _loanProposalIDsCreatedBy(msg.sender);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loan {

    enum LoanStatus {
        Open,
        Full,
        Repaid
    }

    uint public id;
    address public borrower;
    uint public principal;
    // annual interest rate per 10,000
    // for example, an interest rate of 12.75% is denoted as 1275
    uint public interestRatePerTenThousand;
    // time period in years in which the loan must be repaid
    uint public termInYears;
    // total amount lent by lenders so far - cannot exceed principal
    uint public principalLent;
    // time at which the loan is disbursed
    uint public disbursedAt;
    // time at or before which the loan must be repaid
    uint public dueAt;
    // ERC-20 tokens that represent money
    IERC20 public coins;
    LoanStatus status;
    // title of the loan
    string public title;
    // a brief description about the loan
    string public description;
    address[] public lenders;
    // share of the principal lent by a lender
    mapping(address => uint) public amountLentBy;

    constructor(uint _id, address _borrower, uint _principal, uint _interestRatePerTenThousand, uint _termInYears, address _coinsAddr, string memory _title, string memory _description) {
        require(_principal > 0, "principal amount of a loan must be a positive integer");
        require(_termInYears > 0, "loan term must be a positive integer");
        require(_borrower != address(0), "zero account for a borrower is forbidden");
        id = _id;
        borrower = _borrower;
        principal = _principal;
        interestRatePerTenThousand = _interestRatePerTenThousand;
        termInYears = _termInYears;
        coins = IERC20(_coinsAddr);
        title = _title;
        description = _description;
        status = LoanStatus.Open;
    }

    function getLendersCount() external view returns(uint) {
        return lenders.length;
    }

    function getAmountLentAndDue(uint lenderIndex) external view returns(uint, uint) {
        uint amountLent = amountLentBy[lenders[lenderIndex]];
        uint amountDueToLender = amountDueFor(amountLent);
        return (amountLent, amountDueToLender);
    }

    // returns the status of the loan
    function loanStatus() external view returns (string memory) {
        if (status == LoanStatus.Open) {
            return "OPEN";
        } else if (status == LoanStatus.Full) {
            return "FULL";
        } else {
            return "REPAID";
        }
    }

    // tracks the amount lent by each lender,
    // the maximum amount that can be lent at any time is the amount needed to rwach the principal, and only that many number of tokens are tracked as being lent
    function trackLend(address lender, uint amount) external returns (uint, bool) {
        // loan should be in needslending status
        require(status == LoanStatus.Open, "loan doesn't accept lending anymore");
        // amount lent should be a positive integer
        require(amount > 0, "amount to be lent shoud be a positive integer");
        // borrower can't be a lender
        require(lender != borrower, "loan borrower cannot be a lender");
        // amount to lend can't be greater than amount needed
        // amount needed towards reaching principal
        uint amountNeeded = principal - principalLent;
        // actual lending amount that is being considered 
        uint actualAmountLent = amount;
        bool principalMet = false;
        // if the amount is more than amount needed, only consider the amount needed as being lent
        if (amount >= amountNeeded) {
            principalMet = true;
            actualAmountLent = amountNeeded;
        }
        // if the lender is lending for the first time
        if (amountLentBy[lender] == 0) {
            lenders.push(lender);
        }
        // track the total amount lent by this lender
        amountLentBy[lender] += actualAmountLent;
        principalLent += actualAmountLent;
        return (actualAmountLent, principalMet);
    }

    function updateLoanStatusToDisbursed() external {
        // signal that the loan is borrowed
        status = LoanStatus.Full;
        // mark the loan disbursed time
        disbursedAt = block.timestamp;
        dueAt = disbursedAt + (termInYears * 365 days);
    }

    function transferPrincipalToBorrower() external {
        require(status == LoanStatus.Full, "Loan status is not full");
        coins.transfer(borrower, principal);
    }

    // calculates the compound interest for an arbitrary amount as principal
    // and interestRatePerTenThousand as interest rate and term number of years as time elapsed
    function amountDueFor(uint _partialPrincipal) internal view returns (uint) {
        uint amount = _partialPrincipal;
        for (uint i = 0; i < termInYears; i++) {
            amount += Math.mulDiv(amount, interestRatePerTenThousand, 10000);
        }
        return amount;
    }

    // returns the total amount due
    function totalAmountDue() external view returns (uint) {
        return amountDueFor(principal);
    }

    // repays the loan by
    // transferring the proportionate amount of tokens to each lender
    function processLoanRepayment() external returns (bool) {
        if (status == LoanStatus.Open) {
            revert("loan is yet to be borrowed and hence cannot be repaid");
        }
        if (status == LoanStatus.Repaid) {
            revert("loan is already repaid");
        }
        // mark the loan as repaid
        status = LoanStatus.Repaid;

        for (uint i = 0; i < lenders.length; i++) {
            // calculate the amount payable to each lender based on his share towards the total principal
            uint amountLent = amountLentBy[lenders[i]];
            uint amountDueToLender = amountDueFor(amountLent);
            // transfer the above amount of tokens to the lender
            coins.transfer(lenders[i], amountDueToLender);
        }

        // transfer the remaining tokens to the platform
        uint coinBal = coins.balanceOf(address(this));
        coins.transfer(msg.sender, coinBal);
        return true;
    }
}