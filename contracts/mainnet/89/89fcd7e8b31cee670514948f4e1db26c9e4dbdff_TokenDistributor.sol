/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// TokenDistributor v1.0

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/TokenDistributor.sol

pragma solidity 0.5.16;




contract TokenDistributor is Ownable {
	using SafeMath for uint256;

	// The token holder that distribution will be done on behalf of
	address public tokenHolder;

	// The  tokens that will be distributed
	IERC20 public tokenContract;

	// The states that the contract can be in
	enum ContractState {
		NONE, // State where nothing is set up
		LOADING, // State where addresses/amounts can be added
		LOCKED // State where no new addresses can be added, but distribute can be called
	}

	// The current state that the contract is in
	ContractState public currentState;

	// Distribution stats - populated with the load() function
	address[] public distributionAddresses;
	uint256[] public distributionAmounts;
	uint256 public totalDistributionAmount;

	// Track the index for the distribution - increases by 1 with each transferFrom() call
	uint256 public currentDistributionCount;

	// Events
	event Reset(address indexed _tokenHolder, IERC20 indexed _tokenContract);
	event Load(uint256 currentLoaded, uint256 totalLoaded);
	event Lock(uint256 totalLoaded);
	event Distribute(uint256 currentDistributed, uint256 totalDistributed);

	/**
	 * Constructor to set the owner.
	 * Will transfer ownership to the specified address.
	 */
	constructor(address _owner) public {
		transferOwnership(_owner);
		currentState = ContractState.NONE;
	}

	/**
	 * The reset() function sets all variables back to the initial state for a new distribution.
	 */
	function reset(address _tokenHolder, IERC20 _tokenContract) public onlyOwner {
		// Save off the token holder address and token contract
		tokenHolder = _tokenHolder;
		tokenContract = _tokenContract;

		// Verify the token holder does not already have an amount allowed - should be 0 at the start
		require(checkAllowanceAmount() == 0, "Reset failed since tokenHolder already has an allowance balance");

		// Reset distribution vars
		distributionAddresses.length = 0;
		distributionAmounts.length = 0;
		totalDistributionAmount = 0;
		currentDistributionCount = 0;

		// Reset the state to loading
		currentState = ContractState.LOADING;

		// Emit the event
		emit Reset(_tokenHolder, _tokenContract);
	}

	/**
	 * Called iteratively to build the distribution list of tokens that will be sent out.
	 */
	function load(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
		// Verify the current state is loading
		require(currentState == ContractState.LOADING, "load() can only be called when in LOADING state.");

		// Verify the lists are correct length
		require(addresses.length == amounts.length, "load() array lengths must match");

		// Add the values to the distribution vars
		for(uint256 i = 0; i < addresses.length; i++) {
			distributionAddresses.push(addresses[i]);
			distributionAmounts.push(amounts[i]);
			totalDistributionAmount = totalDistributionAmount.add(amounts[i]);
		}

		// Emit the event
		emit Load(addresses.length, distributionAddresses.length);
	}

	/**
	 * Called once the distribution list is complete.  This locks the list in place.
	 */
	function lock() public onlyOwner {
		// Verify the current state is loading
		require(currentState == ContractState.LOADING, "lock() can only be called when in LOADING state.");

		currentState = ContractState.LOCKED;

		// Emit the event
		emit Lock(distributionAddresses.length);
	}

	/**
	 * Iteratively called to send batches out until all tokens are distributed.
	 * Note that it will delete items from the list as it goes to free up storage and reclaim gas.
	 * Reclaiming gas cuts total gas consumed by approx 50% with test token.
	 */
	function distribute(uint256 batchSize) public onlyOwner {
		// Verify the state
		require(currentState == ContractState.LOCKED, "distribute() can only be called when in LOCKED state.");

		// Track the number of distributions
		uint256 numberDistributed = 0;

		// Iterate and send tokens
		while( currentDistributionCount < distributionAddresses.length && numberDistributed < batchSize) {
			// Send tokens
			tokenContract.transferFrom(tokenHolder, distributionAddresses[currentDistributionCount], distributionAmounts[currentDistributionCount]);

			// Delete the items to reclaim gas
			delete distributionAddresses[currentDistributionCount];
			delete distributionAmounts[currentDistributionCount];

			// Update counters
			numberDistributed = numberDistributed.add(1);
			currentDistributionCount = currentDistributionCount.add(1);
		}

		// Emit the event
		emit Distribute(numberDistributed, currentDistributionCount);
	}

	/**
	 * Convenience function just to check how many tokens are allowed to be sent on the token holder's behalf.
	 */
	function checkAllowanceAmount() public view returns (uint256) {
		return tokenContract.allowance(tokenHolder, address(this));
	}

	/**
	 * Convenience function to get distribution addresses
	 */
  function getDistributionAddressesArray() public view returns (address[] memory) {
      return distributionAddresses;
  }

	/**
	 * Convenience function to get distribution amounts
	 */
  function getDistributionAmountsArray() public view returns (uint256[] memory) {
      return distributionAmounts;
  }
}