// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error JuniorPool__CannotWithdrawMoreFunds();
error JuniorPool__CannotWithdrawExtraFunds();
error JuniorPool__InvestmentPeriodOver();
import "./SafeMath.sol";

/**
 * @title Junior Pool
 * @notice This contract holds the information for the junior pool of an opportunity
 * @author Erly Stage Studios
 */
contract JuniorPool {
    using SafeMath for uint256;
    struct juniorPoolMember {
        address walletAddress;
        uint256 amountInvested;
        uint256 amountDeserving;
        uint256 amountWithdrawn;
    }
    uint256 private immutable i_creationTimestamp;
    address[] private s_walletAddresses;
    mapping(address => juniorPoolMember) s_member;
    uint256 private s_balance;
    uint256 private immutable i_juniorInterestRate;
    address private immutable i_poolWalletAddress;
    uint256 private immutable i_investmentDays;
    uint256 private immutable i_investmentFinalizationTimestamp;
    uint256 private constant SECONDS_IN_A_DAY = 86400;

    /**
     * @notice constructor for the contract
     * @param walletAddress: the Gnosis wallet address for the junior pool
     * @param juniorInterest: the interest rate for the junior pool
     * @param investmentDays: the number of days the option to invest is availaible
     */
    constructor(
        address walletAddress,
        uint256 juniorInterest,
        uint256 investmentDays
    ) {
        i_poolWalletAddress = walletAddress;
        i_juniorInterestRate = juniorInterest;
        i_investmentDays = investmentDays;
        i_creationTimestamp = block.timestamp;
        i_investmentFinalizationTimestamp = i_creationTimestamp.add(
            SECONDS_IN_A_DAY.mul(i_investmentDays)
        );
    }

    /**
     * @notice check and tell if investment period is complete
     * @return bool: the truth value if investment period is ongoing
     */
    function isInvestmentPeriodComplete() public view returns (bool) {
        uint256 timestamp = block.timestamp;
        if (timestamp > i_investmentFinalizationTimestamp) {
            return true;
        }
        return false;
    }

    /**
     * @notice add a member to junior pool with a certain investment, calculates the deserving amount inside the contract
     * @param walletAddress: the wallet address of the investor
     * @param amountInvested: the amount invested
     */
    function addJuniorPoolInvestment(
        address walletAddress,
        uint256 amountInvested
    ) external {
        if (isInvestmentPeriodComplete()) {
            revert JuniorPool__InvestmentPeriodOver();
        }
        s_walletAddresses.push(walletAddress);
        juniorPoolMember memory temp = s_member[walletAddress];
        if (temp.amountInvested == 0) {
            s_member[walletAddress] = juniorPoolMember(
                walletAddress,
                amountInvested,
                calculateAmountDeserving(amountInvested),
                0
            );
        } else {
            s_member[walletAddress].amountInvested += amountInvested;
            s_member[walletAddress].amountDeserving = calculateAmountDeserving(
                s_member[walletAddress].amountInvested
            );
        }

        s_balance += amountInvested;
    }

    /**
     * @notice calculate the amount the investor deserves with the interest provided
     * @param amountInvested: the amount paid by the investor
     * @return uint256: the amount they deserve with the interest
     */
    function calculateAmountDeserving(uint256 amountInvested)
        internal
        view
        returns (uint256)
    {
        uint256 hundred = 100;
        uint256 amountDeserving = amountInvested.mul(i_juniorInterestRate) /
            hundred;
        return amountInvested + amountDeserving;
    }

    /**
     * @notice adds the record of withdrawal by an investor to the chain
     * @param walletAddress: the wallet address of the investor
     * @param amountWithdrawn: the amount the investor wants to withdraw
     */
    function addWithdrawalRecord(address walletAddress, uint256 amountWithdrawn)
        external
    {
        if (
            s_member[walletAddress].amountDeserving ==
            s_member[walletAddress].amountWithdrawn
        ) {
            revert JuniorPool__CannotWithdrawMoreFunds();
        }
        if (s_member[walletAddress].amountDeserving < amountWithdrawn) {
            revert JuniorPool__CannotWithdrawExtraFunds();
        }
        s_member[walletAddress].amountWithdrawn += amountWithdrawn;
    }

    /**
     * @notice return the junior pool's wallet address
     * @return address
     */
    function getPoolWalletAddress() external view returns (address) {
        return i_poolWalletAddress;
    }

    /**
     * @notice return the finalization timestamp for investment
     * @return uint256
     */
    function getFinalizationTimestamp() external view returns (uint256) {
        return i_investmentFinalizationTimestamp;
    }

    /**
     * @notice return the interest rate of the junior pool
     * @return uint256
     */
    function getPoolInterestRate() external view returns (uint256) {
        return i_juniorInterestRate;
    }

    /**
     * @notice return the balance in the pool
     * @return uint256
     */
    function getPoolBalance() external view returns (uint256) {
        return s_balance;
    }

    /**
     * @notice return the list of wallet address of the investors
     * @return address[]
     */
    function getInvestorWalletAddresses()
        external
        view
        returns (address[] memory)
    {
        return s_walletAddresses;
    }

    /**
     * @notice return the  investor depending on the wallet address
     * @param walletAddress: the wallet address of the investor
     * @return juniorPoolMember
     */
    function getInvestor(address walletAddress)
        external
        view
        returns (juniorPoolMember memory)
    {
        return s_member[walletAddress];
    }

    function getAmountDeserving(address investor)
        external
        view
        returns (uint256)
    {
        return s_member[investor].amountDeserving;
    }

    function getCreationTimestamp() public view returns (uint256) {
        return i_creationTimestamp;
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