/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


pragma solidity ^0.8.13;

contract StakingContract is Ownable {
    using SafeMath for uint256;

    struct Bracket {
        uint256 lockedDays;
        uint256 dailyRewards;
        bool enabled;
    }

    struct DepositInfo {
        uint256 amount;
        uint256 timestamp;
    }

    struct Deposit {
        DepositInfo info;
        Bracket bracket;
        uint256 claimed;
        bool active;
    }

    uint256 private PRECISION_FACTOR = 10000;
    IERC20 public depositToken;
    IERC20 public rewardsToken;

    address[] public depositAddresses;
    mapping (uint256 => Bracket) public brackets;
    mapping (address => Deposit) public deposits;

    event UserDeposit(address wallet, uint256 amount);
    event RewardsWithdraw(address wallet, uint256 rewardsAmount);
    event FullWithdraw(address wallet, uint256 depositAmount, uint256 rewardsAmount);

    function mapProportionalHoldingsToRewardsSupply(uint256 proportion, IERC20 token) private view returns (uint256) {
        uint256 totalSupply = token.totalSupply();
        uint256 rewardsSupply = proportion.mul(totalSupply).div(PRECISION_FACTOR.mul(100));
        return rewardsSupply;
    }

    function getProportionalSupplyHoldings(uint256 balance, IERC20 token) private view returns (uint256) {
        uint256 totalSupply = token.totalSupply();
        uint256 proportion = balance.mul(PRECISION_FACTOR).mul(100).div(totalSupply);
        return proportion;
    }

    function calculateRewards(address wallet) public view returns (uint256) {
        uint256 rewards = 0;
        Deposit memory userDeposit = deposits[wallet];
        if (userDeposit.active) {
            uint256 depositDays = block.timestamp.sub(userDeposit.info.timestamp).div(86400);
            uint256 depositTokenHoldings = getProportionalSupplyHoldings(userDeposit.info.amount, depositToken);
            uint256 proportionalRewardsSupply = mapProportionalHoldingsToRewardsSupply(depositTokenHoldings, rewardsToken);

            uint256 rewardsPercent = depositDays.mul(userDeposit.bracket.dailyRewards);
            rewards = proportionalRewardsSupply.mul(rewardsPercent).div(PRECISION_FACTOR.mul(100));
        }
        return rewards.sub(userDeposit.claimed);
    }

    function deposit(uint256 tokenAmount, uint256 bracket) external {
        require(!deposits[_msgSender()].active, "user has already deposited");
        require(brackets[bracket].enabled, "bracket is not enabled");

        // transfer tokens
        uint256 previousBalance = depositToken.balanceOf(address(this));
        depositToken.transferFrom(_msgSender(), address(this), tokenAmount);
        uint256 deposited = depositToken.balanceOf(address(this)).sub(previousBalance);

        // deposit logic
        DepositInfo memory info = DepositInfo(deposited, block.timestamp);
        deposits[_msgSender()] = Deposit(info, brackets[bracket], 0, true);
        depositAddresses.push(_msgSender());
        emit UserDeposit(_msgSender(), deposited);
    }

    function claimRewards() external {
        Deposit memory userDeposit = deposits[_msgSender()];
        require(userDeposit.active, "user has no active deposits");

        uint256 rewardsAmount = calculateRewards(_msgSender());

        require (rewardsToken.balanceOf(address(this)) >= rewardsAmount, "insufficient rewards balance");

        deposits[_msgSender()].claimed = rewardsAmount;
        rewardsToken.transfer(_msgSender(), rewardsAmount);

        emit RewardsWithdraw(_msgSender(), rewardsAmount);
    }

    function withdraw() external {
        Deposit memory userDeposit = deposits[_msgSender()];
        require(userDeposit.active, "user has no active deposits");
        require(block.timestamp >= userDeposit.info.timestamp + userDeposit.bracket.lockedDays * 1 days, "Can't withdraw yet");
        uint256 depositedAmount = userDeposit.info.amount;
        uint256 rewardsAmount = calculateRewards(_msgSender());

        require (rewardsToken.balanceOf(address(this)) >= rewardsAmount, "insufficient rewards balance");

        deposits[_msgSender()].info.amount = 0;
        deposits[_msgSender()].claimed = 0;
        deposits[_msgSender()].active = false;
        rewardsToken.transfer(_msgSender(), rewardsAmount);
        depositToken.transfer(_msgSender(), depositedAmount);

        emit FullWithdraw(_msgSender(), depositedAmount, rewardsAmount);
    }

    function addBracket(uint256 id, uint256 lockedDays, uint256 dailyRewards) external onlyOwner {
        brackets[id] = Bracket(lockedDays, dailyRewards, true);
    }

    function setDepositToken(address tokenAddress) external onlyOwner {
        depositToken = IERC20(tokenAddress);
    }

    function setRewardsToken(address tokenAddress) external onlyOwner {
        rewardsToken = IERC20(tokenAddress);
    }

    function rescueTokens() external onlyOwner {
        if (rewardsToken.balanceOf(address(this)) > 0) {
            rewardsToken.transfer(_msgSender(), rewardsToken.balanceOf(address(this)));
        }

        if (depositToken.balanceOf(address(this)) > 0) {
            depositToken.transfer(_msgSender(), depositToken.balanceOf(address(this)));
        }
    }
}