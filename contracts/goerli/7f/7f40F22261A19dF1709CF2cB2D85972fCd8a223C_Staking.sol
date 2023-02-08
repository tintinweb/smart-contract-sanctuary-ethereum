// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Pausable, Ownable {
  using SafeMath for uint256;

  IERC20 private _token;

  struct Position {
    bytes32 id;
    address account;
    uint256 deposit;
    uint256 interest;
    uint256 openedAt;
    uint256 expiresAt;
    bytes32 previousId;
    bytes32 nextId;
  }
  event OpenPosition(address indexed account, Position position);
  event ClosePosition(address indexed account, Position position);
  event SetMinDeposit(uint256 minDeposit);
  event SetMaxDeposit(uint256 maxDeposit);
  event Withdraw(address tokenAddress, address withdrawalAddress);
  event SetConditions(uint256[] expiresAfter, uint256[] percent);

  mapping(bytes32 => Position) private _positions;
  mapping(address => bytes32) private _accountsPositionsTail;

  mapping(address => uint256) private _accountsActivePositionsCount;
  mapping(address => uint256) private _accountsActiveDeposit;

  uint256 private _totalPositionsCount = 0;
  uint256 private _activePositionsCount = 0;
  uint256 private _stakedAmount = 0;
  uint256 private _interestAmount = 0;

  uint256[] private _availableExpiresAfter = [
    90 days,
    180 days,
    270 days,
    360 days
  ];
  uint256[] private _availablePercents = [5, 10, 15, 20];
  mapping(uint256 => uint256) private _expiresAfterToPercent;

  uint256 private _minDeposit = 100 ether;
  uint256 private _maxDeposit = 100000 ether;

  constructor(address tokenAddress) {
    _token = IERC20(tokenAddress);
    setConditions(_availableExpiresAfter, _availablePercents);
  }

  function _incrementTotalPositionsCount() internal virtual returns (uint256) {
    uint256 currentTotalPositionsCount = _totalPositionsCount;
    _totalPositionsCount = _totalPositionsCount.add(1);
    return currentTotalPositionsCount;
  }

  function openPosition(uint256 amount, uint256 expiresAt)
    public
    whenNotPaused
    returns (bool)
  {
    require(
      _token.balanceOf(msg.sender) >= amount,
      "Not enough tokens to stake"
    );
    require(amount >= _minDeposit, "Amount is less than min deposit");
    require(
      amount.add(_accountsActiveDeposit[msg.sender]) <= _maxDeposit,
      "Amount plus active deposit is greater than max deposit"
    );
    require(amount > 0, "Amount must be greater than 0");
    require(msg.sender != address(0), "Receiver address cannot be 0");
    require(
      _token.allowance(msg.sender, address(this)) >= amount,
      "Not enough allowance to stake"
    );
    require(_expiresAfterToPercent[expiresAt] > 0, "Invalid expiresAt");
    uint256 interest = amount.mul(_expiresAfterToPercent[expiresAt]).div(100);
    require(
      interest <= _token.balanceOf(address(this)) - _interestAmount,
      "Not enough tokens in the contract to pay interest"
    );

    _activePositionsCount = _activePositionsCount.add(1);

    bytes32 id = keccak256(abi.encode(_incrementTotalPositionsCount()));

    _token.transferFrom(msg.sender, address(this), amount);
    _accountsActiveDeposit[msg.sender] = _accountsActiveDeposit[msg.sender].add(
      amount
    );
    _stakedAmount = _stakedAmount.add(amount);
    _interestAmount = _interestAmount.add(interest);

    Position memory position = Position(
      id,
      msg.sender,
      amount,
      interest,
      block.timestamp,
      block.timestamp.add(expiresAt),
      _accountsPositionsTail[msg.sender],
      0
    );

    if (_accountsPositionsTail[msg.sender] != 0) {
      _positions[_accountsPositionsTail[msg.sender]].nextId = id;
    }

    _positions[id] = position;

    _accountsActivePositionsCount[msg.sender] = _accountsActivePositionsCount[
      msg.sender
    ].add(1);

    _accountsPositionsTail[msg.sender] = id;

    emit OpenPosition(msg.sender, position);

    return true;
  }

  function closePosition(bytes32 id) public {
    require(_positions[id].deposit > 0, "Position does not exist");
    require(_positions[id].account == msg.sender, "Not your position");
    require(
      _positions[id].expiresAt < block.timestamp,
      "Position is not expired"
    );

    uint256 amount = _positions[id].deposit;
    uint256 interest = _positions[id].interest;
    _token.transfer(msg.sender, amount.add(interest));
    _accountsActiveDeposit[msg.sender] = _accountsActiveDeposit[msg.sender].sub(
      amount
    );
    _stakedAmount = _stakedAmount.sub(amount);
    _interestAmount = _interestAmount.sub(interest);

    // # if position is not the first one in the list (has previous position)
    if (_positions[id].previousId != 0) {
      _positions[_positions[id].previousId].nextId = _positions[id].nextId;
    }

    // # if position is not the last one in the list (has next position)
    if (_positions[id].nextId != 0) {
      _positions[_positions[id].nextId].previousId = _positions[id].previousId;
    }

    // # if position is the last one in the list (has no next position)
    if (_accountsPositionsTail[msg.sender] == id) {
      _accountsPositionsTail[msg.sender] = _positions[id].previousId;
    }
    // # save position to emit event
    Position memory position = _positions[id];
    delete _positions[id];
    _accountsActivePositionsCount[msg.sender] = _accountsActivePositionsCount[
      msg.sender
    ].sub(1);

    _activePositionsCount = _activePositionsCount.sub(1);

    emit ClosePosition(msg.sender, position);
  }

  // # pause unpause
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // # get and set max deposit
  function getMaxDeposit() public view virtual returns (uint256) {
    return _maxDeposit;
  }

  function setMaxDeposit(uint256 newMaxDeposit) public onlyOwner {
    require(newMaxDeposit >= 0, "Amount must be greater or equal than 0");

    _maxDeposit = newMaxDeposit;
    emit SetMaxDeposit(newMaxDeposit);
  }

  // # get and set min deposit
  function getMinDeposit() public view virtual returns (uint256) {
    return _minDeposit;
  }

  function setMinDeposit(uint256 newMinDeposit) public onlyOwner {
    require(newMinDeposit >= 0, "Amount must be greater or equal than 0");

    _minDeposit = newMinDeposit;
    emit SetMinDeposit(newMinDeposit);
  }

  function getConditions()
    public
    view
    virtual
    returns (
      uint256[] memory availableExpiresAfter,
      uint256[] memory availablePercents
    )
  {
    return (_availableExpiresAfter, _availablePercents);
  }

  function setConditions(
    uint256[] memory expiresAfter,
    uint256[] memory percents
  ) public onlyOwner {
    require(
      expiresAfter.length == percents.length,
      "Arrays must be equal length"
    );

    for (uint256 i = 0; i < expiresAfter.length; i++) {
      require(
        expiresAfter[i] >= 0 && percents[i] > 0,
        "Expires at must be greater or equal and percent must be greater than 0"
      );
    }

    // # reset all values to 0
    for (uint256 i = 0; i < _availableExpiresAfter.length; i++) {
      _expiresAfterToPercent[_availableExpiresAfter[i]] = 0;
    }

    // # set new values
    for (uint256 i = 0; i < expiresAfter.length; i++) {
      _expiresAfterToPercent[expiresAfter[i]] = percents[i];
    }

    _availableExpiresAfter = expiresAfter;
    _availablePercents = percents;

    emit SetConditions(expiresAfter, percents);
  }

  function getAllPositions(address account)
    public
    view
    virtual
    returns (Position[] memory)
  {
    Position[] memory positions = new Position[](
      _accountsActivePositionsCount[account]
    );

    if (_accountsActivePositionsCount[account] == 0) {
      return positions;
    }

    // # we cant assign negative value to uint256 so we need to use this trick
    uint256 activePositionsIndex = _accountsActivePositionsCount[account];
    bytes32 prevId = 0;
    for (uint256 i = _accountsActivePositionsCount[account]; i > 0; i--) {
      if (i == _accountsActivePositionsCount[account]) {
        positions[activePositionsIndex.sub(1)] = _positions[
          _accountsPositionsTail[account]
        ];

        prevId = positions[activePositionsIndex.sub(1)].previousId;

        activePositionsIndex--;
      } else {
        positions[activePositionsIndex.sub(1)] = _positions[prevId];
        prevId = positions[activePositionsIndex.sub(1)].previousId;
        activePositionsIndex--;
      }
    }

    return positions;
  }

  function getLastPosition(address account)
    public
    view
    virtual
    returns (Position memory)
  {
    return _positions[_accountsPositionsTail[account]];
  }

  function getLastPositionId(address account)
    public
    view
    virtual
    returns (bytes32 id)
  {
    return _accountsPositionsTail[account];
  }

  function getPosition(bytes32 id)
    public
    view
    virtual
    returns (Position memory)
  {
    return _positions[id];
  }

  function getTotalPositionsCount() public view virtual returns (uint256) {
    return _totalPositionsCount;
  }

  function getActivePositionsCount() public view virtual returns (uint256) {
    return _activePositionsCount;
  }

  function getAccountsActivePositionsCount(address account)
    public
    view
    virtual
    returns (uint256)
  {
    return _accountsActivePositionsCount[account];
  }

  function withdraw(address tokenAddress, address withdrawalAddress)
    public
    onlyOwner
  {
    IERC20 token = IERC20(tokenAddress);
    // # if token is not the same as staked token
    if (tokenAddress != address(_token)) {
      token.transfer(withdrawalAddress, token.balanceOf(address(this)));
    } else {
      token.transfer(
        withdrawalAddress,
        token.balanceOf(address(this)) - _stakedAmount - _interestAmount
      );
    }

    emit Withdraw(tokenAddress, withdrawalAddress);
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _accountsActiveDeposit[account];
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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