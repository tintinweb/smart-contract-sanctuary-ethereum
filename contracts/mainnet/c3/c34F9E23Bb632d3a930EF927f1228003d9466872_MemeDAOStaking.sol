// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// MEME DAO Staking
contract MemeDAOStaking is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter;

    event Stake(
        address indexed _from,
        uint256 indexed _id,
        uint256 _timestamp,
        uint256 _amount
    );

    event Withdraw(
        address indexed _from,
        uint256 indexed _id,
        uint256 _startTimestamp,
        uint256 _timestamp,
        uint256 _principal,
        uint256 _interest
    );

    event Claim(
        address indexed _from,
        uint256 indexed _id,
        uint256 _timestamp,
        uint256 _interest
    );

    IERC20 public stakingToken;

    struct StakeDetail {
        address staker;
        uint256 startAt;
        uint256 endAt;
        uint256 principal;
        uint256 interestRate;
        uint256 lastClaimAt;
    }

    mapping(uint256 => StakeDetail) public idToStakeDetail;

    mapping(address => uint256[]) private _addressToIds;
    mapping(uint256 => uint256) public terms;

    address[] internal _addresses;

    bool public enabled;
    uint256 constant MIN_AMOUNT = 1e9;
    uint256 constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;
    uint256 constant ONE_YEAR_IN_SECONDS = 365 * ONE_DAY_IN_SECONDS;
    uint256 constant DENOMINATOR = 10000;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        enabled = false;

        terms[0] = 3200;
    }

    modifier onlyStakeholder(uint256 _id) {
        StakeDetail memory stakeDetail = idToStakeDetail[_id];
        require(
            stakeDetail.staker == msg.sender,
            "Staking: Caller is not the stakeholder"
        );
        _;
    }

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function setTerm(uint256 _term, uint256 _interestRate) external onlyOwner {
        require(!enabled, "Staking: Cannot set interest rate while enabled");
        require(
            _interestRate <= 10000,
            "Staking: Interest rate must be less than 100%"
        );
        terms[_term] = _interestRate;
    }

    function stake(uint256 _amount, uint256 _duration) external {
        require(enabled, "Staking: Staking is disabled");
        require(_amount >= 1e18, "Staking: Amount must be >= 1 token");
        require(terms[_duration] > 0, "Staking: Term is not supported");

        uint256 currentId = _tokenIdCounter.current();

        StakeDetail memory newStake = StakeDetail(
            msg.sender,
            block.timestamp,
            block.timestamp.add(_duration),
            _amount,
            terms[_duration],
            block.timestamp
        );
        idToStakeDetail[currentId] = newStake;

        if (_addressToIds[msg.sender].length == 0) {
            _addresses.push(msg.sender);
        }
        _addressToIds[msg.sender].push(currentId);
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _tokenIdCounter.increment();

        emit Stake(msg.sender, currentId, block.timestamp, _amount);
    }

    function getPrincipal(uint256 _id) external view returns (uint256) {
        return idToStakeDetail[_id].principal;
    }

    function getInterest(uint256 _id) public view returns (uint256) {
        StakeDetail memory currentStake = idToStakeDetail[_id];
        uint256 interestRate = currentStake.interestRate;
        uint256 principal = currentStake.principal;
        uint256 startAt = currentStake.startAt;
        uint256 lastClaimAt = currentStake.lastClaimAt;
        uint256 duration = block.timestamp.sub(startAt);
        if (lastClaimAt > 0) {
            duration = block.timestamp.sub(lastClaimAt);
        }
        uint256 interest = principal
            .mul(interestRate)
            .mul(duration)
            .div(ONE_YEAR_IN_SECONDS)
            .div(10000);
        return interest;
    }

    function claim(uint256 _id) external onlyStakeholder(_id) {
        uint256 interest = getInterest(_id);
        require(interest > 0, "Staking: No interest to claim");
        StakeDetail storage currentStake = idToStakeDetail[_id];
        currentStake.lastClaimAt = block.timestamp;
        stakingToken.transfer(msg.sender, interest);
        emit Claim(msg.sender, _id, block.timestamp, interest);
    }

    function withdraw(uint256 _id) external onlyStakeholder(_id) {
        StakeDetail memory currentStake = idToStakeDetail[_id];
        require(
            block.timestamp >= currentStake.endAt,
            "Staking: Cannot withdraw before end date"
        );
        uint256 interest = getInterest(_id);
        uint256 principal = currentStake.principal;
        uint256 startTimestamp = currentStake.startAt;

        delete idToStakeDetail[_id];

        for (uint256 i = 0; i < _addressToIds[msg.sender].length; ++i) {
            if (_addressToIds[msg.sender][i] == _id) {
                _addressToIds[msg.sender][i] = _addressToIds[msg.sender][
                    _addressToIds[msg.sender].length - 1
                ];
                _addressToIds[msg.sender].pop();
                break;
            }
        }
        if (_addressToIds[msg.sender].length == 0) {
            for (uint256 i = 0; i < _addresses.length; ++i) {
                if (_addresses[i] == msg.sender) {
                    _addresses[i] = _addresses[_addresses.length - 1];
                    _addresses.pop();
                    break;
                }
            }
        }
        stakingToken.transfer(msg.sender, principal.add(interest));

        emit Withdraw(
            msg.sender,
            _id,
            startTimestamp,
            block.timestamp,
            principal,
            interest
        );
    }

    function getStakingIds() external view returns (uint256[] memory) {
        return _addressToIds[msg.sender];
    }

    function getStakeHolders()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return _addresses;
    }

    function transferStakingToken(address _recipient, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        return stakingToken.transfer(_recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
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