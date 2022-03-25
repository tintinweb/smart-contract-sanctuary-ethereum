//SPDX-License-Identifier: Unlicense
pragma solidity >0.6.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract Vesting is Ownable {
  using SafeMath for uint256;

  struct VestingType {
    string name;
    uint256 startTime;
    uint256 endTime;
    uint256 lockDuration;
  }

  struct VestingInfo {
    address recipient;
    uint256 amount;
    uint256 claimedAmount;
    uint256 lastClaim;
    bool removed;
    uint256 removedTime;
  }

  IERC20 public token;
  address public rewardAddress;

  mapping(address => bool) public admin;
  VestingType[] public typeInfo;
  mapping(uint256 => VestingInfo[]) public vestingInfo;
  mapping(uint256 => mapping(address => uint256[])) public userVestingIds;

  event AddVestingType(
    uint256 indexed _typeId,
    string _name,
    uint256 _start,
    uint256 _end,
    uint256 _lockDuration
  );
  event UpdateVestingType(
    uint256 indexed _typeId,
    string _name,
    uint256 _start,
    uint256 _end,
    uint256 _lockDuration
  );
  event RemoveVestingType(uint256 indexed _typeId);
  event AddVesting(
    uint256 indexed _typeId,
    uint256 indexed _vestingId,
    address indexed _recipient,
    uint256 _amount
  );
  event UpdateVesting(
    uint256 indexed _typeId,
    uint256 indexed _vestingId,
    address indexed _recipient,
    uint256 _amount
  );
  event RemoveVesting(
    uint256 indexed _typeId,
    uint256 indexed _vestingId,
    address indexed _recipient
  );
  event Claim(
    uint256 indexed _typeId,
    uint256 indexed _vestingId,
    address indexed _recipient,
    uint256 _claimedAmount
  );
  event UpdateRewardAddress(address indexed _rewardAddress);

  modifier onlyAdmin() {
    require(admin[msg.sender], 'Not admin');
    _;
  }

  constructor(address _token, address _rewardAddress) {
    token = IERC20(_token);
    rewardAddress = _rewardAddress;
  }

  function updateRewardAddress(address _rewardAddress) public onlyOwner {
    rewardAddress = _rewardAddress;
    emit UpdateRewardAddress(_rewardAddress);
  }

  function addAdmin(address _addr) public onlyOwner {
    admin[_addr] = true;
  }

  function removeAdmin(address _addr) public onlyOwner {
    admin[_addr] = false;
  }

  function addVestingType(
    string memory _name,
    uint256 _start,
    uint256 _end,
    uint256 _lockDuration
  ) public onlyAdmin {
    require(_end > _start, 'Invalid vesting duration');

    uint256 _typeId = typeInfo.length;

    typeInfo.push(
      VestingType({
        name: _name,
        startTime: _start,
        endTime: _end,
        lockDuration: _lockDuration
      })
    );

    emit AddVestingType(_typeId, _name, _start, _end, _lockDuration);
  }

  function updateVestingType(
    uint256 _typeId,
    string memory _name,
    uint256 _start,
    uint256 _end,
    uint256 _lockDuration
  ) public onlyAdmin {
    require(_typeId < typeInfo.length, 'Invalid type id');
    require(_end > _start, 'Invalid vesting duration');

    VestingType storage info = typeInfo[_typeId];
    info.name = _name;
    info.startTime = _start;
    info.endTime = _end;
    info.lockDuration = _lockDuration;

    emit UpdateVestingType(_typeId, _name, _start, _end, _lockDuration);
  }

  function addVesting(
    uint256 _typeId,
    address _recipient,
    uint256 _amount
  ) public onlyAdmin {
    require(_typeId < typeInfo.length, 'Invalid type id');
    require(_recipient != address(0), 'Invalid address');
    require(_amount > 0, 'Invalid amount');

    uint256 _vestingId = vestingInfo[_typeId].length;

    vestingInfo[_typeId].push(
      VestingInfo({
        recipient: _recipient,
        amount: _amount,
        claimedAmount: 0,
        lastClaim: typeInfo[_typeId].startTime,
        removed: false,
        removedTime: block.timestamp
      })
    );

    userVestingIds[_typeId][_recipient].push(_vestingId);

    emit AddVesting(_typeId, _vestingId, _recipient, _amount);
  }

  function updateVesting(
    uint256 _typeId,
    uint256 _vestingId,
    address _recipient,
    uint256 _amount
  ) public onlyAdmin {
    require(_typeId < typeInfo.length, 'Invalid type id');
    require(_vestingId < vestingInfo[_typeId].length, 'Invalid vesting id');
    require(_recipient != address(0), 'Invalid address');
    require(_amount > 0, 'Invalid amount');

    VestingInfo storage info = vestingInfo[_typeId][_vestingId];
    uint256[] storage userIds = userVestingIds[_typeId][info.recipient];

    for (uint256 i = 0; i < userIds.length; i++) {
      if (userIds[i] == _vestingId) {
        userVestingIds[_typeId][_recipient].push(_vestingId);
        userIds[i] = userIds[userIds.length - 1];
        userIds.pop();
      }
    }

    info.recipient = _recipient;
    info.amount = _amount;

    if (typeInfo[_typeId].startTime > info.lastClaim) {
      info.lastClaim = typeInfo[_typeId].startTime;
    }

    emit UpdateVesting(_typeId, _vestingId, _recipient, _amount);
  }

  function removeVesting(uint256 _typeId, uint256 _vestingId) public onlyAdmin {
    require(_typeId < typeInfo.length, 'Invalid type id');
    require(_vestingId < vestingInfo[_typeId].length, 'Invalid vesting id');

    VestingInfo storage info = vestingInfo[_typeId][_vestingId];
    info.removed = true;
    info.removedTime = block.timestamp;

    emit RemoveVesting(_typeId, _vestingId, info.recipient);
  }

  function claim(uint256 _typeId, uint256 _vestingId) public {
    require(_typeId < typeInfo.length, 'Invalid type id');
    require(_vestingId < vestingInfo[_typeId].length, 'Invalid vesting id');

    VestingInfo storage info = vestingInfo[_typeId][_vestingId];

    require(info.recipient == msg.sender, 'Invalid recipient');
    require(
      info.lastClaim + typeInfo[_typeId].lockDuration <= block.timestamp,
      'Not able to claim yet'
    );

    uint256 availableAmount = claimAvailable(_typeId, _vestingId);
    if (availableAmount > 0) {
      info.claimedAmount = info.claimedAmount + availableAmount;
      info.lastClaim = block.timestamp;
      require(
        token.transferFrom(rewardAddress, msg.sender, availableAmount),
        'Not enough balance'
      );
      emit Claim(_typeId, _vestingId, info.recipient, availableAmount);
    }
  }

  function claimAvailable(uint256 _typeId, uint256 _vestingId)
    public
    view
    returns (uint256)
  {
    require(_typeId < typeInfo.length, 'Invalid type id');
    require(_vestingId < vestingInfo[_typeId].length, 'Invalid vesting id');

    VestingInfo storage info = vestingInfo[_typeId][_vestingId];

    if (info.lastClaim + typeInfo[_typeId].lockDuration > block.timestamp) {
      return 0;
    }

    uint256 totalAmount = 0;

    if (block.timestamp < typeInfo[_typeId].startTime) {
      totalAmount = 0;
    } else {
      uint256 lastTime = info.removed ? info.removedTime : block.timestamp;
      if (lastTime > typeInfo[_typeId].endTime) {
        totalAmount = info.amount;
      } else {
        uint256 duration = typeInfo[_typeId].endTime -
          typeInfo[_typeId].startTime;
        totalAmount = info
          .amount
          .mul(lastTime - typeInfo[_typeId].startTime)
          .div(duration);
      }
    }

    if (totalAmount > info.claimedAmount) {
      return totalAmount - info.claimedAmount;
    }
    return 0;
  }

  function typeCount() public view returns (uint256) {
    return typeInfo.length;
  }

  function vestingCount(uint256 _typeId) public view returns (uint256) {
    return vestingInfo[_typeId].length;
  }

  function userVestingCount(uint256 _typeId, address _recipient)
    public
    view
    returns (uint256)
  {
    return userVestingIds[_typeId][_recipient].length;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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