/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

contract FarmCoin is IERC20 {
	using SafeMath for uint256;

	string public constant name = "FarmCoin";
	string public constant symbol = "FMC";
	uint8 public constant decimals = 18;

	mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) allowed;

	uint256 totalSupply_;

	constructor(uint256 total) {
		totalSupply_ = total;
		balances[msg.sender] = totalSupply_;
	}

	function totalSupply() public override view returns (uint256) {
		return totalSupply_;
	}

	function balanceOf(address tokenOwner) public override view returns (uint256) {
		return balances[tokenOwner];
	}

	function transfer(address receiver, uint256 numTokens) public override returns (bool) {
		require(numTokens <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender].sub(numTokens);
		balances[receiver] = balances[receiver].add(numTokens);
		emit Transfer(msg.sender, receiver, numTokens);
		return true;
	}

	function approve(address delegate, uint256 numTokens) public override returns (bool) {
		allowed[msg.sender][delegate] = numTokens;
		emit Approval(msg.sender, delegate, numTokens);
		return true;
	}

	function allowance(address owner, address delegate) public override view returns (uint) {
		return allowed[owner][delegate];
	}

	function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
		require(numTokens <= balances[owner]);
		require(numTokens <= allowed[owner][msg.sender]);

		balances[owner] = balances[owner].sub(numTokens);
		allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
		balances[buyer] = balances[buyer].add(numTokens);
		emit Transfer(owner, buyer, numTokens);
		return true;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract PentagonStaking is Ownable {

	struct UserInfo {
		uint balances; // deposit amount
		uint lockTime; // Lock time lockTime>0 means locked.
		uint APY;
		uint lastUpdateTime; // Last Harvest Time
		uint rewards; // reward amount
	}

	event Deposited(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);

	uint public noLockAPY = 10;
	uint public sixMonthLockAPY = 20;
	uint public oneYearLockAPY = 30;

	IERC20 public USDC;
	IERC20 public farmCoin;

	mapping(address => UserInfo) private users;
	uint private _totalSupply;

	constructor(address _farmCoin, address _usdc) {
		USDC = IERC20(_usdc); // ERC20 USDC
		farmCoin = IERC20(_farmCoin);
	}

	function balanceOf(address account) external view returns (uint256) {
    	return users[account].balances;
	}

	function earned(address account) public view returns (uint) {
		uint reward = (users[account].balances * users[account].APY * (block.timestamp - users[account].lastUpdateTime) / 365 days) + users[account].rewards;
		return reward;
	}

	modifier updateReward(address account) {
		uint passedTime = block.timestamp - users[account].lastUpdateTime;
		if(passedTime >= users[account].lockTime) users[account].lockTime = 0;
		else users[account].lockTime -= block.timestamp - users[account].lastUpdateTime;
		if (account != address(0) && users[account].lockTime == 0) {
			users[account].rewards = earned(account);
			users[account].lastUpdateTime = block.timestamp;
		}
		_;
	}

	function depositUsdc(uint _amount, uint _type) external updateReward(msg.sender) {
		require(_amount > 0, "Cannot deposit 0");
		require(users[msg.sender].balances == 0, "Already deposited. Withdraw first");
		_totalSupply += _amount;
		if(_type == 0) {
			users[msg.sender].lockTime = 0;
			users[msg.sender].APY = noLockAPY;
		}
		else if(_type == 1) {
			users[msg.sender].lockTime = 183 days;
			users[msg.sender].APY = sixMonthLockAPY;
		}
		else if(_type == 2) {
			users[msg.sender].lockTime = 365 days;
			users[msg.sender].APY = oneYearLockAPY;
		}
		users[msg.sender].balances = _amount;
		users[msg.sender].lastUpdateTime = block.timestamp;
		USDC.transferFrom(msg.sender, address(this), _amount);
		emit Deposited(msg.sender, _amount);
	}

	function withdraw(uint _amount) external updateReward(msg.sender) {
		require(_amount > 0, "Cannot withdraw 0");
		require(_totalSupply >= _amount, "Not enough balance");
		require(users[msg.sender].balances >= _amount, "Not enough deposit amount");
		_totalSupply -= _amount;
		users[msg.sender].balances -= _amount;
		if(users[msg.sender].lockTime == 0) USDC.transfer(msg.sender, _amount);
		else USDC.transfer(msg.sender, _amount * 90 / 100);
		emit Withdrawn(msg.sender, _amount);
	}

	function getReward() external updateReward(msg.sender) {
		uint reward = users[msg.sender].rewards;
		if (reward > 0) {
			users[msg.sender].rewards = 0;
			farmCoin.transfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}
}