pragma solidity ^0.7.5;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ZooIDO is Ownable 
{
	using SafeMath for uint256;

	IERC20 public zoo;                                                          // Zoo token.
	IERC20 public dai;                                                          // Dai token.

	address public team;                                                        // Zoodao team address.

	enum Phase
	{
		ZeroPhase,
		FirstPhase,
		SecondPhase,
		ClaimLockPhase,
		UnlockPhase
	}

	uint256 public idoStart;                                                    // Start date of Ido.
	uint256 public zeroPhaseDuration;                                           // Time before IDO starts.
	uint256 public firstPhaseDuration = 5 days;                                 // Duration of whitelist buy phase.
	uint256 public secondPhaseDuration = 3 days;                               // Duration of non whitelist buy phase.
	uint256 public thirdPhaseDuration = 17 days;                                // Duration of zoo tokens lock from start of ido.

	uint256 public saleLimit = 800 * 10 ** 18;                                  // Amount of dai allowed to spend.
	uint256 public zooRate = 5;                                                 // Rate of zoo for dai.
	uint256 public zooAllocatedTotal;                                           // Amount of total allocated zoo.
	
	mapping (address => uint256) public amountAllowed;                          // Amount of dai allowed to spend for each whitelisted person.

	mapping (address => uint256) public zooAllocated;                           // Amount of zoo allocated for each person.

	mapping (address => uint256) public nonWhiteListLimit;                      // Records if user already take part in not whitelisted IDO.

	event DaiInvested(uint256 indexed daiAmount);                               // Records amount of dai spent.

	event ZooClaimed(uint256 indexed zooAmount);                                // Records amount of zoo claimed.

	event TeamClaimed(uint256 indexed daiAmount, uint256 indexed zooAmount);    // Records amount of dai and zoo claimed by team.

	/// @notice Contract constructor.
	/// @param _zoo - address of zoo token.
	/// @param _dai - address of dai token.
	/// @param _team - address of team.
	/// @param _zeroPhaseDuration - time until Ido start.
	constructor (
		address _zoo,
		address _dai,
		address _team,
		uint256 _zeroPhaseDuration
		)
	{
		zoo = IERC20(_zoo);
		dai = IERC20(_dai);

		team = _team;
		zeroPhaseDuration = _zeroPhaseDuration;
		idoStart = block.timestamp + zeroPhaseDuration;
	}

	/// @notice Function to add addresses to whitelist.
	/// @notice Sets amount of dai allowed to spent.
	/// @notice so, u can spend up to saleLimit with more than 1 transaction.
	function batchAddToWhiteList(address[] calldata users) external onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			amountAllowed[users[i]] = saleLimit;
		}
	}

	/// @notice Function to buy zoo tokens for dai.
	/// @notice Sends dai and sets amount of zoo to claim after claim date.
	/// @notice Requires to be in whitelist.
	/// @param amount - amount of dai spent.
	function whitelistedBuy(uint256 amount) external
	{
		require(getCurrentPhase() == Phase.FirstPhase, "Wrong phase!");         // Requires first phase.
		require(amountAllowed[msg.sender] >= amount, "amount exceeds limit");   // Requires allowed amount left to spent.
		uint256 amountZoo = amount.mul(zooRate);                                // Amount of zoo to buy.
		require(unallocatedZoo() >= amountZoo, "Not enough zoo");               // Requires to be enough unallocated zoo.
		dai.transferFrom(msg.sender, address(this), amount);                    // Dai transfers from msg.sender to this contract.
		zooAllocated[msg.sender] += amountZoo;                                  // Records amount of zoo allocated to this person.
		zooAllocatedTotal = zooAllocatedTotal.add(amountZoo);                   // Records total amount of allocated zoo.

		amountAllowed[msg.sender] = amountAllowed[msg.sender].sub(amount);      // Decreases amount of allowed dai to spend.

		emit DaiInvested(amount);
	}

	/// @notice Function to buy rest of zoo for non whitelisted.
	/// @param amount - amount of DAI to spend.
	function notWhitelistedBuy(uint256 amount) external
	{
		require(getCurrentPhase() == Phase.SecondPhase, "Wrong phase!");        // Requires second phase.
		uint256 amountZoo = amount.mul(zooRate);                                // Amount of zoo to buy.
		require(unallocatedZoo() >= amountZoo, "Not enough zoo");               // Requires to be enough unallocated zoo.
		require(nonWhiteListLimit[msg.sender] + amount <= saleLimit, "reached sale limit");//Requires amount to spend less than limit.

		dai.transferFrom(msg.sender, address(this), amount);                    // Dai transfers from msg.sender to this contract.

		nonWhiteListLimit[msg.sender] += amount;                                // Records amount of dai spent.
		zooAllocated[msg.sender] += amountZoo;                                  // Records amount of zoo allocated to this person.
		zooAllocatedTotal += amountZoo;                                         // Records total amount of allocated zoo.

		emit DaiInvested(amount);
	}

	/// @notice Function to see amount of not allocated zoo tokens.
	/// @return availableZoo - amount of zoo available to buy.
	function unallocatedZoo() public view returns(uint256 availableZoo)
	{
		availableZoo = zoo.balanceOf(address(this)).sub(zooAllocatedTotal);     // All Zoo on contract minus allocated to users.
	}

	/// @notice Function to claim zoo.
	/// @notice sents all the zoo tokens bought to caller address.
	function claimZoo() external
	{
		require(getCurrentPhase() == Phase.UnlockPhase, "Wrong phase!");        // Rquires unlock phase. 
		require(zooAllocated[msg.sender] > 0, "zero zoo allocated");            // Requires amount of dai spent more than zero.

		uint256 zooAmount = zooAllocated[msg.sender];                           // Amount of zoo to claim.

		zooAllocated[msg.sender] = 0;                                           // Sets amount of allocated zoo for this user to zero.
		zooAllocatedTotal.sub(zooAmount);                                       // Reduces amount of total zoo allocated.

		zoo.transfer(msg.sender, zooAmount);                                    // Transfers zoo.

		emit ZooClaimed(zooAmount);
	}

	/// @notice Function to claim dai and unsold zoo from IDO to team.
	function teamClaim() external 
	{
		require(getCurrentPhase() == Phase.ClaimLockPhase || getCurrentPhase() == Phase.UnlockPhase, "Wrong phase!");// Requires end of sale.

		uint256 daiAmount = dai.balanceOf(address(this));                       // Sets dai amount for all tokens invested.
		uint256 zooAmount = unallocatedZoo();                                   // Sets zoo amount for all unallocated zoo tokens.

		dai.transfer(team, daiAmount);                                          // Sends all the dai to team address.
		zoo.transfer(team, zooAmount);                                          // Sends all the zoo left to team address.

		emit TeamClaimed(daiAmount, zooAmount);
	}

	function getCurrentPhase() public view returns (Phase)
	{
		if (block.timestamp < idoStart)                                         // before start
		{
			return Phase.ZeroPhase;
		}
		else if (block.timestamp < idoStart + firstPhaseDuration)               // from start to phase 1 end.
		{
			return Phase.FirstPhase;
		}
		else if (block.timestamp < idoStart + firstPhaseDuration + secondPhaseDuration) // from phase 1 end to ido end(second phase)
		{
			return Phase.SecondPhase;
		}
		else if (block.timestamp < idoStart + firstPhaseDuration + secondPhaseDuration + thirdPhaseDuration) // from ido end to claimLock end.
		{
			return Phase.ClaimLockPhase;
		}
		else
		{
			return Phase.UnlockPhase;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}