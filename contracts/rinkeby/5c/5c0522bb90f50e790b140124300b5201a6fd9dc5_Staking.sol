/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

    /**s
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
    function transferFrom(
        address sender,
        address recipient,
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

contract Staking is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter internal _tokenIdCounter;

  /*** EVENTS ***/

  event Stake(
    address indexed _from,
    uint256 indexed _id,
    uint256 _term,
    uint256 _timestamp,
    uint256 _amount
  );

  event Withdraw(
    address indexed _from,
    uint256 indexed _id,
    uint256 _term,
    uint256 _startTimestamp,
    uint256 _timestamp,
    uint256 _principal,
    uint256 _interest
  );

  /*** DATA TYPES ***/

  IERC20 public token;
  // List address staking holder
  address[] internal _addresses;
  // whitelist admin with role
  mapping(address => bool) public whitelistAdmin;
  // mapping to addess with balance, term, start time
  mapping(address => uint256[]) private _addressToIds;
  mapping(uint256 => address) private _idToAddress;
  mapping(uint256 => uint256) public idToBalance;
  mapping(uint256 => uint256) public idToTerm;
  mapping(uint256 => uint256) public idToStartTime;

  // time point begin and end staking
  uint256 public startStakingAt;
  uint256 public endStakingAt;

  // Week is APR per term
  mapping(uint256 => uint256) public termToInterestRate;
  mapping(uint256 => uint256) public idToInterestRate;

  uint256 public TERM = 7 days;
  // Maximum token per pool
  uint256 public maxPool = 3 * 10**6 * 10**18;

  // bool public enabled = true;

  /*** CONSTRUCTOR ***/
  constructor(address _token) {
    token = IERC20(_token);
    termToInterestRate[TERM] = 463;
    startStakingAt = 1644390000;
    endStakingAt = 1644908340;
  }

  /// @dev Access modifier for StakeHolder-only functionality
  modifier onlyStakeholder(uint256 _id) {
    require(_idToAddress[_id] == msg.sender, "Caller is not the stakeholder");
    _;
  }

  /// @dev Access modifier for AdminOrOwner-only functionality
  modifier onlyAdminOrOwner() {
    require(
      msg.sender == owner() || whitelistAdmin[msg.sender] == true,
      "You don't have permission to perform action"
    );
    _;
  }

  /// @dev
  function setStartStakingAt(uint256 _time) external onlyAdminOrOwner {
    startStakingAt = _time;
  }

  /// @dev
  function setEndStakingAt(uint256 _time) external onlyAdminOrOwner {
    endStakingAt = _time;
  }

  /// @dev Change token contract address staking
  function setTokenContractAddress(address _newTokenAddress)
    external
    onlyOwner
  {
    token = IERC20(_newTokenAddress);
  }

  /// @dev Update white list admin for runing autotask
  function updateWhitelistAdmin(address _address, bool _isAdmin)
    external
    onlyOwner
  {
    whitelistAdmin[_address] = _isAdmin;
  }

  /// @dev Update APR per term
  function updateInterestRate(uint256 _interestRate) external onlyAdminOrOwner {
    termToInterestRate[TERM] = _interestRate;
  }

  /// @dev Update maximum token per pool
  function updateMaxPool(uint256 _maxPool) external onlyAdminOrOwner {
    maxPool = _maxPool;
  }

  /// @dev Staking
  function stake(uint256 _amount) external nonReentrant {
    require(
      block.timestamp >= startStakingAt && block.timestamp <= endStakingAt,
      "Staking is not availabe at this time"
    );
    require(_amount >= 1e18, "Amount must be greater than 0");
    uint256 totalStaked = getTotalStaked();
    require(totalStaked.add(_amount) <= maxPool, "The pool is full");

    uint256 currentId = _tokenIdCounter.current();
    _idToAddress[currentId] = msg.sender;
    idToTerm[currentId] = TERM;
    idToStartTime[currentId] = block.timestamp;
    idToBalance[currentId] = _amount;
    idToInterestRate[currentId] = termToInterestRate[TERM];
    if (_addressToIds[msg.sender].length == 0) {
      _addresses.push(msg.sender);
    }
    _addressToIds[msg.sender].push(currentId);
    token.transferFrom(msg.sender, address(this), _amount);
    _tokenIdCounter.increment();

    emit Stake(msg.sender, currentId, TERM, block.timestamp, _amount);
  }

  /// @dev With draw by staking id
  function withdraw(uint256 _id) external nonReentrant onlyStakeholder(_id) {
    require(
      block.timestamp - idToStartTime[_id] >= idToTerm[_id],
      "Not allow early withdraw"
    );
    uint256 interest = getInterest(_id);
    uint256 principal = idToBalance[_id];
    uint256 term = idToTerm[_id];
    uint256 startTimestamp = idToStartTime[_id];

    delete _idToAddress[_id];
    delete idToTerm[_id];
    delete idToStartTime[_id];
    delete idToBalance[_id];

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
    token.transfer(msg.sender, principal + interest);

    emit Withdraw(
      msg.sender,
      _id,
      term,
      startTimestamp,
      block.timestamp,
      principal,
      interest
    );
  }

  function getPrincipal(uint256 _id) external view returns (uint256) {
    return idToBalance[_id];
  }

  /// @dev Get current estimated Interest
  function getEstimatedInterest(uint256 _id) public view returns (uint256) {
    uint256 term = idToTerm[_id];
    uint256 stakeAmount = idToBalance[_id];
    uint256 rate = idToInterestRate[_id];
    uint256 currentStakeDuration = block.timestamp.sub(idToStartTime[_id]);
    if (block.timestamp - idToStartTime[_id] >= idToTerm[_id]) {
      currentStakeDuration = idToTerm[_id];
    }
    uint256 currentInterest = stakeAmount
      .mul(currentStakeDuration)
      .mul(rate)
      .div(term)
      .div(10000);

    return currentInterest;
  }

  function getInterest(uint256 _id)
    public
    view
    returns (uint256)
  {
    if (block.timestamp - idToStartTime[_id] < idToTerm[_id]) {
      return 0;
    }

    return idToBalance[_id].mul(idToInterestRate[_id]).div(10000);
  }

  function getStakingDetailById(uint256 _id)
    external
    view
    returns (
      uint256 amount,
      uint256 currentInterest,
      uint256 startAt,
      uint256 endAt,
      uint256 weeklyAPR
    )
  {
    amount = idToBalance[_id];
    currentInterest = getEstimatedInterest(_id);
    startAt = idToStartTime[_id];
    endAt = startAt + idToTerm[_id];
    weeklyAPR = idToInterestRate[_id];
    return (amount, currentInterest, startAt, endAt, weeklyAPR);
  }

  function getStakingIds(address _address)
    external
    view
    returns (uint256[] memory)
  {
    return _addressToIds[_address];
  }

  function getStakeHolders() external view returns (address[] memory) {
    return _addresses;
  }

  function getTotalStaked() public view returns (uint256) {
    uint256 totalStaked;
    for (uint256 i = 0; i < _addresses.length; ++i) {
      uint256[] memory ids = _addressToIds[_addresses[i]];
      for (uint256 j = 0; j < ids.length; ++j) {
        totalStaked = totalStaked.add(idToBalance[ids[j]]);
      }
    }
    return totalStaked;
  }

  function getTotalStakeholders()
    public
    view
    returns (address[] memory, uint256[] memory)
  {
    address[] memory stakeholders = new address[](_addresses.length);
    uint256[] memory totalStaked = new uint256[](_addresses.length);
    for (uint256 i = 0; i < _addresses.length; ++i) {
      uint256 staked = 0;
      uint256[] memory ids = _addressToIds[_addresses[i]];
      for (uint256 j = 0; j < ids.length; ++j) {
        staked = staked.add(idToBalance[ids[j]]);
      }
      stakeholders[i] = _addresses[i];
      totalStaked[i] = staked;
    }
    return (stakeholders, totalStaked);
  }

  function getTotalStakeByAddress(address _address)
    public
    view
    returns (uint256) 
  {
    uint256[] memory stakeIds = _addressToIds[_address];
    uint256 totalStaked = 0;
    for(uint256 i = 0; i < stakeIds.length; i++) {
      totalStaked = totalStaked.add(idToBalance[stakeIds[i]]);
    }
    return totalStaked;
  }


  function transfer(address _recipient, uint256 _amount)
    external
    onlyOwner
    returns (bool)
  {
    uint256 totalStaked = getTotalStaked();
    uint256 totalBalance = token.balanceOf(address(this));

    require(
      totalBalance - _amount >= totalStaked,
      "remaining amount cannot less than total staked"
    );
    return token.transfer(_recipient, _amount);
  }
}