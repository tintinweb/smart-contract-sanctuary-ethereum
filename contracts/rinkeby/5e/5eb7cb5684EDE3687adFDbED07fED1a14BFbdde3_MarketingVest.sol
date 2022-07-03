// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MarketingVest is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    IERC20 public dlpToken;
    /**
     * Address for receiving tokens.
     */
    address public withdrawAddress;

    /** When this vault was locked (UNIX Timestamp)*/
    uint256 public lockedAt = 0;

    //Total Token Allocations
    uint256 public constant totalAllocation = 5 * (10**7) * (10**18);

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    uint256 private constant month = 31 days;

    uint8 private constant vestStages = 3;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct UnLockStage {
        uint256 startDate;
        uint256 period;
        uint256 periodPercentage;
    }
    /**
     * Array for storing all vesting stages with structure defined above.
     */
    UnLockStage[vestStages] public stages;

    /**
     * Amount of tokens already sent.
     */
    uint256 public tokensSent;

    /** Allocated reserve tokens */
    event Allocated(address wallet, uint256 lockTime);

    /** Allocated reserve tokens */
    event Withdraw(address wallet, uint256 value);

    //Has not been locked yet
    modifier notLocked() {
        require(lockedAt == 0);
        _;
    }

    modifier locked() {
        require(lockedAt > 0);
        _;
    }
    /**
     * Could be called only from withdraw address.
     */
    modifier onlyWithdrawAddress() {
        require(msg.sender == withdrawAddress);
        _;
    }

    constructor(address _dlpToken, address _withdraw) {
        require(_dlpToken != address(0), "Dlptoken cannot be the zero address");
        require(
            _withdraw != address(0),
            "withdrawAddress cannot be the zero address"
        );
        dlpToken = IERC20(_dlpToken);
        withdrawAddress = _withdraw;
    }

    //Lock the vault for the three wallets
    function lock() internal {
        lockedAt = block.timestamp;

        //Need to release 48%
        stages[0].startDate = lockedAt;
        stages[0].period = 12;
        stages[0].periodPercentage = 400;

        //Need to release 32%
        stages[1].startDate = lockedAt + month * 12;
        stages[1].period = 12;
        stages[1].periodPercentage = 270;

        //Need to release 20%
        stages[2].startDate = lockedAt + month * 24;
        stages[2].period = 12;
        stages[2].periodPercentage = 163;
        emit Allocated(withdrawAddress, lockedAt);
    }

    function allocate() public notLocked onlyOwner {
        //Makes sure Token Contract has the exact number of tokens
        require(
            getTotalBalance() == totalAllocation,
            "Please transfer the 'totalallocation' token to the contract first"
        );
        lock();
    }

    //Claim tokens for Libra withdrawAddress reserve wallet
    function withdrawReserve() private onlyWithdrawAddress locked {
        uint256 tokensToSend = getClaimReserve();
        require(tokensToSend > 0, "Token is less than or equal to 0");

        // Updating tokens sent counter
        tokensSent = tokensSent.add(tokensToSend);
        // Sending allowed tokens amount
        dlpToken.transfer(withdrawAddress, tokensToSend);
        // Raising event
        emit Withdraw(withdrawAddress, tokensToSend);
    }

    //In the case locking failed, then allow the withdrawAddress to reclaim the tokens on the contract.
    //Recover Tokens in case incorrect amount was sent to contract.
    function recoverFailedLock() external notLocked onlyWithdrawAddress {
        // Transfer all tokens on this contract back to the withdrawAddress
        require(getTotalBalance() > 0);
        dlpToken.transfer(withdrawAddress, getTotalBalance());
    }

    /**
     * Get tokens unlocked percentage on current stage.
     *
     * @return Percent of tokens allowed to be sent.
     */
    function getUnlockedPercentage() private view returns (uint256) {
        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (block.timestamp > stages[i].startDate) {
                allowedPercent = getStagePrecent(stages[i], i);
            }
        }
        return allowedPercent;
    }

    //Current Vesting stage Percentage for Libra team
    function getStagePrecent(UnLockStage memory _unLockStage, uint8 stage)
        private
        view
        returns (uint256)
    {
        uint256 _period = (block.timestamp.sub(_unLockStage.startDate)).div(
            month
        );
        uint256 _periodMode = (block.timestamp.sub(_unLockStage.startDate)).mod(
            month
        );
        if (_periodMode > 0) {
            _period = _period.add(1);
        }

        //Ensures  vesting stage doesn't go past vestingStages
        if (_period > _unLockStage.period) {
            _period = _unLockStage.period;
        }
        uint256 allowedPercent = (_unLockStage.periodPercentage.mul(_period));

        for (uint8 i = 0; i < stage; i++) {
            uint256 prePercentage = stages[i].period.mul(
                stages[i].periodPercentage
            );
            allowedPercent = allowedPercent.add(prePercentage);
        }
        //If the final stage is reached and the final stage is reached at the same time, and the percentage is less than the default,
        //it will be set as the default
        if (
            (stage.add(1)) == vestStages &&
            _period == _unLockStage.period &&
            allowedPercent < INVERSE_BASIS_POINT
        ) {
            allowedPercent = INVERSE_BASIS_POINT;
        }
        return allowedPercent;
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param unlockedPercentage Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided percentage.
     */
    function getAllowedToWithdraw(uint256 unlockedPercentage)
        private
        view
        returns (uint256)
    {
        uint256 totalAllowedToWithdraw = totalAllocation
            .mul(unlockedPercentage)
            .div(INVERSE_BASIS_POINT);
        uint256 unsentTokensAmount = totalAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

    /**
     *Calculate tokens amount that is sent to withdrawAddress.
     */
    function getClaimReserve() public view returns (uint256 tokensToSend) {
        uint256 tokensUnlockedPercentage = getUnlockedPercentage();
        // In the case of stuck tokens we allow the withdrawal of them all after vesting period ends.
        if (tokensUnlockedPercentage >= INVERSE_BASIS_POINT) {
            tokensToSend = getTotalBalance();
        } else {
            tokensToSend = getAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    // Total number of tokens currently in the vault
    function getTotalBalance()
        public
        view
        returns (uint256 tokensCurrentlyInVault)
    {
        return dlpToken.balanceOf(address(this));
    }

    receive() external payable {
        withdrawReserve();
    }

    fallback() external payable {}
}

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}