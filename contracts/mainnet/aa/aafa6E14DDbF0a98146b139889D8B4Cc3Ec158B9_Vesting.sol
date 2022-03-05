pragma solidity ^0.6.12;

import "Ownable.sol";
import "IERC20.sol";
import "SafeMath.sol";

import "IVesting.sol";

contract Vesting is Ownable, IVesting {
	using SafeMath for uint256;

	struct Vehicule {
		uint256 start;
		uint256 end;
		uint256 upfront;
		uint256 amount;
		uint256 claimed;
		uint256 claimedUpfront;
	}

	address public override ygg;

	mapping(address => mapping(uint256 => Vehicule)) public override vehicules;
	mapping(address => uint256) public override vehiculeCount;

	event YieldClaimed(address indexed user, uint256 amount);
	event VehiculeCreated(address indexed user, uint256 id, uint256 amount, uint256 start, uint256 end);

	constructor(address _ygg) public {
		require(_ygg != address(0));
		ygg = _ygg;
	}

	function min(uint256 a, uint256 b) pure private returns(uint256) {
		return a < b ? a : b;
	}

	function max(uint256 a, uint256 b) pure private returns(uint256) {
		return a > b ? a : b;
	}

	function createVehicule(address _user, uint256 _amount, uint256 _upfront, uint256 _start, uint256 _end) external onlyOwner returns(uint256){
		require(_end > _start, "Vesting: wrong vehicule parametres");
		require(_start > 0, "Vesting: start cannot be 0");

		uint256 counter = vehiculeCount[_user];
		vehicules[_user][counter] = Vehicule(_start, _end, _upfront, _amount, 0, 0);
		vehiculeCount[_user]++;
		emit VehiculeCreated(_user, counter, _amount + _upfront, _start, _end);
	}

	function killVehicule(address _user, uint256 _index) external onlyOwner {
		delete vehicules[_user][_index];
	}

	function endVehicule(address _user, uint256 _index) external onlyOwner {
		Vehicule storage vehicule = vehicules[_user][_index];
		uint256 _now = block.timestamp;
		uint256 start = vehicule.start;
		if (start == 0)
			revert("Vesting: vehicule does not exist");
		uint256 end = vehicule.end;
		uint256 elapsed = min(end, max(_now, vehicule.start)).sub(start);
		uint256 maxDelta = end.sub(start);
		uint256 unlocked = vehicule.amount.mul(elapsed).div(maxDelta);
		if (_now > start) {
			vehicule.amount = unlocked;
			vehicule.end = min(vehicule.end, _now);
		}
		else {
			vehicule.upfront = 0;
			vehicule.amount = 0;
		}
	}

	function fetchTokens(uint256 _amount) external onlyOwner {
		IERC20(ygg).transfer(msg.sender, _amount);
	}

	function claim(uint256 _index) external override {
		uint256 _now = block.timestamp;
		
		Vehicule storage vehicule = vehicules[msg.sender][_index];

		uint256 upfront = _claimUpfront(vehicule);
		uint256 start = vehicule.start;
		if (start == 0)
			revert("Vesting: vehicule does not exist");
		require(_now > start, "Vesting: cliff !started");
		uint256 end = vehicule.end;
		uint256 elapsed = min(end, _now).sub(start);
		uint256 maxDelta = end.sub(start);
		// yield = amount * delta / vest_duration - claimed_amount
		uint256 yield = vehicule.amount.mul(elapsed).div(maxDelta).sub(vehicule.claimed);
		vehicule.claimed += yield;
		IERC20(ygg).transfer(msg.sender, yield.add(upfront));
		emit YieldClaimed(msg.sender, yield);
	}

	function _claimUpfront(Vehicule storage vehicule) private returns(uint256) {
		uint256 upfront = vehicule.upfront;
		if (upfront > 0) {
			vehicule.upfront = 0;
			vehicule.claimedUpfront = upfront;
			return upfront;
		}
		return 0;
	}

	function pendingReward(address _user, uint256 _index) external override view returns(uint256) {
		Vehicule memory vehicule = vehicules[_user][_index];
		uint256 elapsed = min(vehicule.end, block.timestamp).sub(vehicule.start);
		uint256 maxDelta = vehicule.end.sub(vehicule.start);
		return vehicule.amount.mul(elapsed).div(maxDelta).sub(vehicule.claimed).add(vehicule.upfront);
	}

	function claimed(address _user, uint256 _index) external view override returns(uint256) {
		Vehicule memory vehicule = vehicules[_user][_index];
		return vehicule.claimed.add(vehicule.claimedUpfront);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "Context.sol";
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
contract Ownable is Context {
    address internal _owner;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.12;

interface IVesting {
	function ygg() external view returns(address);

	function vehicules(address _user, uint256 _index) external view returns (
		uint256 start,
		uint256 end,
		uint256 upfront,
		uint256 amount,
		uint256 claimed,
		uint256 claimedUpfront);
	function vehiculeCount(address _user) external view returns (uint256);
	function claim(uint256 _index) external;
	function pendingReward(address _user, uint256 _index) external view returns(uint256);
	function claimed(address _user, uint256 _index) external view returns(uint256);
}