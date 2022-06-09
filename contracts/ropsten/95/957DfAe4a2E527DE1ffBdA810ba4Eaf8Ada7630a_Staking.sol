/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/Staking.sol


pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

contract Staking is Ownable {
    
    using SafeMath for uint;
    
    address public immutable token;
    uint public payableAmount = 0;
    uint public rewardRate = 175;
    uint public cancelInterval = 365 days / 2;
    uint public claimInterval = 365 days;

    struct record {
        uint amount;
        uint stakeTime;
        bool status;
    }

    mapping (address => mapping ( uint => record)) public records;
    mapping (address => uint) public stakeCount;

    event Stake(address indexed from, uint256 value);
    event Claim(address indexed from, uint256 value);
    event Cancel(address indexed from, uint256 value);

    constructor (address _token) {
        token = _token;
    }

    //for testing
    function setRewardRate(uint _rewardRate) public onlyOwner {
        rewardRate = _rewardRate;
    }

    //for testing
    function setIntervals(uint _cancelInterval, uint _claimInterval) public onlyOwner {
        cancelInterval = _cancelInterval;
        claimInterval = _claimInterval;
    }

    function stake(uint amount) public {
        require(amount > 0, "invalid amount");
        address owner = _msgSender();
        IERC20(token).transferFrom(owner, address(this), amount);
        stakeCount[owner] = stakeCount[owner].add(1);
        uint stakeId = stakeCount[owner];
        records[owner][stakeId].amount = amount;
        records[owner][stakeId].stakeTime = block.timestamp;
        payableAmount = payableAmount.add(amount.mul(rewardRate).div(100));
        emit Stake(owner, amount);
    }

    function claim() public {
        address owner = _msgSender();
        uint claimableAmount = claimable(owner);
        require(claimableAmount > 0, "nothing to claim");
        for (uint i = 1; i <= stakeCount[owner]; i++) {
            if (records[owner][i].stakeTime.add(claimInterval) < block.timestamp && !records[owner][i].status) {
                records[owner][i].status = true;
            }
        }
        IERC20(token).transfer(owner, claimableAmount);
        emit Claim(owner, claimableAmount);
    }

    function claimable(address owner) public view returns (uint claimableAmount) {
        for (uint i = 1; i <= stakeCount[owner]; i++) {
            if (records[owner][i].stakeTime.add(claimInterval) < block.timestamp && !records[owner][i].status) {
                claimableAmount = claimableAmount.add(records[owner][i].amount.mul(rewardRate).div(100));
            }
        }
    } 
    
    function cancel() public {
        address owner = _msgSender();
        uint cancellableAmount = 0;
        for (uint i = 1; i <= stakeCount[owner]; i++) {
            if (records[owner][i].stakeTime.add(cancelInterval) < block.timestamp && records[owner][i].stakeTime.add(claimInterval) > block.timestamp && !records[owner][i].status) {
                records[owner][i].status = true;
                cancellableAmount = cancellableAmount.add(records[owner][i].amount);
            }
        }
        require(cancellableAmount > 0, "nothing to cancel");
        IERC20(token).transfer(owner, cancellableAmount);
        emit Cancel(owner, cancellableAmount);
    }

    function cancel(uint id) public {
        address owner = _msgSender();
        require(records[owner][id].amount > 0, "nothing to cancel");
        require(!records[owner][id].status, "already cancelled/claimed");
        require(records[owner][id].stakeTime.add(cancelInterval) < block.timestamp, "not allowed currently");
        require(records[owner][id].stakeTime.add(claimInterval) > block.timestamp, "claim only");
        records[owner][id].status = true;
        IERC20(token).transfer(owner, records[owner][id].amount);
        emit Cancel(owner, records[owner][id].amount);
    }

    function manage(address _token, address to, uint amount) public onlyOwner {
        IERC20(_token).transfer(to, amount);        
    }

    function getStakeCount(address owner) public view returns (uint) {
        return stakeCount[owner];
    }

    function getStakeCount(address owner, uint id) public view returns (uint, uint, bool) {
        return (records[owner][id].amount, records[owner][id].stakeTime, records[owner][id].status);
    }
}