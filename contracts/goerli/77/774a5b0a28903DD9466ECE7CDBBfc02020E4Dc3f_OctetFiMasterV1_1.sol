// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./common/OctetFiPool.sol";
import "./common/library/ERC20Helper.sol";

contract OctetFiMasterV1_1 is Ownable {
  using SafeMath for uint256;

  bool    public poolCreateStatus;
  address public devAddress;
  uint256 public minPoolPeriod;
  uint256 public feePoint;

  struct UserInfo {
    uint256   stakedBalance;
    uint256   rewardDebt;
  }

  struct PoolInfo {
    bool         isPool;
    address      creator;
    address      poolAddr;//
    address      stakedToken;
    address      rewardToken;
    uint256      startBlock;
    uint256      endBlock;
    uint256      updatedBlock;
    uint256      perBlock;
    uint256      totalStaked;
    uint256      totalReward;
    uint256      withdrawReward;//
    uint256      unAllocReward;
    uint256      accPerShare;
  }

  // All Pool Addresses
  address[] public pools;

  // Pool Address => User Address => User Info 
  mapping (address => mapping (address => UserInfo)) public userInfo;

  // Pool Address => Pool Info
  mapping (address => PoolInfo) public poolByPoolAddr;

  // Pool Creator => Pool Address 
  mapping (address => address[]) public poolsByCreator;

  event PoolCreated(address indexed creator, address indexed stakedToken, address indexed rewardToken, uint256 totalReward);
  event Staked(address indexed staker, address indexed pool, uint256 amount);
  event UnStaked(address indexed staker, address indexed pool, uint256 amount);
  event EmergencyUnstaked(address indexed staker, address indexed pool, uint256 amount);
  event WithdrawUnAllocReward(address indexed creator, address indexed pool, uint256 amount);

  constructor(address _devAddress, uint256 _minPoolPeriod, uint256 _feePoint, bool _poolCreateStatus) {
    devAddress       = _devAddress;
    minPoolPeriod    = _minPoolPeriod;
    feePoint         = _feePoint;
    poolCreateStatus = _poolCreateStatus;
  }

  modifier onlyPoolCreator(address _poolAddr) {
      PoolInfo memory pool = poolByPoolAddr[_poolAddr];
      require(msg.sender == IOctetFiPool(_poolAddr).creator(), "Only access pool creator");
      _;
  }

  function getAllPools() public view returns (address[] memory) {
    return pools;
  }

  // Pre: Approve RewardToken (from creator) (to OctetfiMaster) (amount maximum) 
  function createPool(address _stakedToken, address _rewardToken, uint256 _totalReward, uint256 _startBlock, uint256 _endBlock) public {
    require(poolCreateStatus, "createPool: Cannot create staking pool");
    require(block.number <= _startBlock, "createPool: StartBlock cannot be past");
    require(_startBlock < _endBlock, "createPool: StartBlock cannot be higher than endBlock");
    require(ERC20Helper.safeBalanceOf(_rewardToken, msg.sender) >= _totalReward, "createPool: Insufficient balance to reward");
    require(_endBlock.sub(_startBlock) >= minPoolPeriod, "createPool: Should be at least the minimum pool period");
    
    bytes memory bytecode = type(OctetFiPool).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _totalReward, _startBlock, _endBlock, msg.sender, block.timestamp));
    address pool;
    assembly {
      pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    uint256 devFee = _totalReward.mul(feePoint).div(1000);

    ERC20Helper.safeTransferFrom(_rewardToken, msg.sender, devAddress, devFee);
    ERC20Helper.safeTransferFrom(_rewardToken, msg.sender, pool, _totalReward.sub(devFee));

    PoolInfo memory poolObj = PoolInfo({
      isPool:        true,
      creator:       msg.sender,
      poolAddr:      pool,
      stakedToken:   _stakedToken,
      rewardToken:   _rewardToken,
      startBlock:    _startBlock,
      endBlock:      _endBlock,
      updatedBlock:  _startBlock,
      perBlock:      (_totalReward.sub(devFee)).div(_endBlock.sub(_startBlock)),
      totalStaked:   0,
      totalReward:   _totalReward,
      withdrawReward: devFee,
      unAllocReward: 0,
      accPerShare:   0
    });
        
    pools.push(pool); 
    poolsByCreator[msg.sender].push(pool);
    poolByPoolAddr[pool] = poolObj;

    IOctetFiPool(pool).initialize(msg.sender, _stakedToken, _rewardToken);
    
    emit PoolCreated(msg.sender, _stakedToken, _rewardToken, _totalReward);
  }

  function updatePool(address _poolAddr) public {
    PoolInfo storage pool = poolByPoolAddr[_poolAddr];
    if (block.number <= pool.updatedBlock) return;

    uint256 totalStaked = pool.totalStaked;
    uint256 pendingBlock = getPendingBlocks(pool.startBlock, pool.endBlock, pool.updatedBlock, block.number);
    uint256 pendingReward = pendingBlock.mul(pool.perBlock);
    
    if (totalStaked == 0) {
      pool.unAllocReward = pool.unAllocReward.add(pendingReward);
      pool.updatedBlock = block.number;
      return;
    }
    
    pool.accPerShare = pool.accPerShare.add(pendingReward.mul(1e12).div(totalStaked));
    pool.updatedBlock = block.number;
  }

  function getPendingRewards(address _poolAddr, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolByPoolAddr[_poolAddr];
    UserInfo storage user = userInfo[_poolAddr][_user];

    uint256 totalStaked = pool.totalStaked;
    uint256 accPerShare = pool.accPerShare;

    if (block.number > pool.updatedBlock && totalStaked != 0) {
      uint256 pendingBlock  = getPendingBlocks(pool.startBlock, pool.endBlock, pool.updatedBlock, block.number);
      uint256 pendingReward = pendingBlock.mul(pool.perBlock);
      accPerShare = pool.accPerShare.add(pendingReward.mul(1e12).div(totalStaked));
    }
    return user.stakedBalance.mul(accPerShare).div(1e12).sub(user.rewardDebt);
  }

  function getPendingBlocks(uint256 _start, uint256 _end, uint256 _from, uint256 _to) internal pure returns (uint256) {
    if (_start <= _from && _from < _to && _to < _end) {
      return _to.sub(_from);
    } else if (_start <= _from && _from < _end && _end <= _to ) {
      return _end.sub(_from);
    } else return 0;
  }

  // // Pre: Approve StakeToken (from staker) (to OctetfiMaster) (amount maximum)
  function stake(address _poolAddr, uint256 _amount) public {
    PoolInfo storage pool = poolByPoolAddr[_poolAddr];
    UserInfo storage user = userInfo[_poolAddr][msg.sender];
    
    require(pool.isPool, "stake: Not found pool");
    
    updatePool(_poolAddr);
    
    if (user.stakedBalance > 0) {
      uint256 pendingReward = user.stakedBalance.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
      if (pendingReward > 0) {
        IOctetFiPool(_poolAddr).claimReward(msg.sender, pendingReward);
        pool.withdrawReward = pool.withdrawReward.add(pendingReward);
      }
    } 

    if (_amount > 0 && block.number < pool.endBlock) {
      ERC20Helper.safeTransferFrom(pool.stakedToken, msg.sender, address(pool.poolAddr), _amount);
      user.stakedBalance = user.stakedBalance.add(_amount);
      pool.totalStaked = pool.totalStaked.add(_amount);
    }
    
    user.rewardDebt = user.stakedBalance.mul(pool.accPerShare).div(1e12);
    emit Staked(msg.sender, _poolAddr, _amount);
  }                                                           

  function unstake(address _poolAddr, uint256 _amount) public {
    PoolInfo storage pool = poolByPoolAddr[_poolAddr];
    UserInfo storage user = userInfo[_poolAddr][msg.sender];
    
    require(pool.isPool, "unstake: Not found pool");
    require(user.stakedBalance >= _amount, "unstake: Insufficient Staked amount");
    
    updatePool(_poolAddr);

    uint256 pendingReward = user.stakedBalance.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
    if (pendingReward > 0) {
      IOctetFiPool(_poolAddr).claimReward(msg.sender, pendingReward);
      pool.withdrawReward = pool.withdrawReward.add(pendingReward);
    }

    if (_amount > 0) {
      user.stakedBalance = user.stakedBalance.sub(_amount);
      pool.totalStaked = pool.totalStaked.sub(_amount);
      IOctetFiPool(_poolAddr).claimStaked(msg.sender, _amount);
    }

    user.rewardDebt = user.stakedBalance.mul(pool.accPerShare).div(1e12);

    emit UnStaked(msg.sender, _poolAddr, _amount);
  }
  
  function emergencyUnstake(address _poolAddr) public  {
    PoolInfo storage pool = poolByPoolAddr[_poolAddr];
    UserInfo storage user = userInfo[_poolAddr][msg.sender];

    require(pool.isPool, "emergencyUnstake: Not found pool");

    if (user.stakedBalance > 0) {
      IOctetFiPool(_poolAddr).claimStaked(msg.sender, user.stakedBalance);
      emit EmergencyUnstaked(msg.sender, _poolAddr, user.stakedBalance);
      user.stakedBalance = 0;
      user.rewardDebt = 0;
      pool.totalStaked = pool.totalStaked.sub(user.stakedBalance);
    }
  }

  function withdrawUnAllocReward(address _poolAddr) public onlyPoolCreator(_poolAddr) {
    PoolInfo storage pool = poolByPoolAddr[_poolAddr];

    require(pool.isPool, "withdrawUnAllocReward: Not found pool");
    require(block.number > pool.endBlock, "withdrawUnAllocReward: Not finished pool");

    updatePool(_poolAddr);

    if (pool.unAllocReward > 0) {
      IOctetFiPool(_poolAddr).claimReward(msg.sender, pool.unAllocReward);
      pool.unAllocReward = 0;
      pool.withdrawReward = pool.withdrawReward.add(pool.unAllocReward);
    }

    emit WithdrawUnAllocReward(msg.sender, _poolAddr, pool.unAllocReward);
  }


  /* Ownable Function */
  function setPoolPeriod(uint256 _period) public onlyOwner {
    minPoolPeriod = _period;
  }
  /* Ownable Function */
  function setPoolCreateStatus(bool _status) public onlyOwner {
    poolCreateStatus = _status;
  }
  /* Ownable Function */
  function setDevAddress(address _devAddress) public onlyOwner {
    devAddress = _devAddress;
  }
  /* Ownable Function */
  function setFeePoint(uint256 _feePoint) public onlyOwner {
    feePoint = _feePoint;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library ERC20Helper {

  function safeBalanceOf(address token, address holder) internal view returns (uint256) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231, holder));
    require(success, "ERC20Helper: safeBalanceOf failed");
    return abi.decode(data, (uint256));
  }

  // function safeApprove(address token, address to, uint value) internal returns (bool) {
  //   (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
  //   require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20Helper: safeApprove failed');
  // }

  function safeTransfer(address token, address to, uint value) internal returns (bool) {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20Helper: safeTransfer failed');
    return true;
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool) {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20Helper: safeTransferFrom failed');
    return true;
  }

  // function safeTransferETH(address to, uint value) internal returns (bool) {
  //   (bool success,) = to.call{value:value}(new bytes(0));
  //   require(success, 'ERC20Helper: safeTransferETH failed');
  //   return true;
  // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../common/interface/IOctetFiPool.sol";
import "../common/library/ERC20Helper.sol";

contract OctetFiPool {
  using SafeMath for uint256;

  address public octetfiMaster;
  address public creator;
  address public stakedToken;
  address public rewardToken;
  
  event InitPool(address indexed creator, address indexed stakedToken, address indexed rewardToken);
  event ClaimStaked(address indexed to, uint256 value);
  event ClaimReward(address indexed to, uint256 value);

  modifier onlyChef() {
    require(msg.sender == octetfiMaster, "OctetFiPool: Only octetFiMaster");
    _;
  }

  constructor() {
    octetfiMaster = msg.sender;
  }

  function initialize(address _creator, address _stakedToken, address _rewardToken) external onlyChef {
    creator = _creator;
    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
    emit InitPool(_creator, _stakedToken, _rewardToken);
  }

  function claimReward(address _to, uint256 _amount) external onlyChef {
    require(
      ERC20Helper.safeBalanceOf(rewardToken, address(this)) >= _amount, 
      "claimReward: Insufficient balance in pool"
    );
    ERC20Helper.safeTransfer(rewardToken, _to, _amount);
    emit ClaimReward(_to, _amount);
  }

  function claimStaked(address _to, uint256 _amount) external onlyChef {
    require(
      ERC20Helper.safeBalanceOf(stakedToken, address(this)) >= _amount, 
      "claimStaked: Insufficient balance in pool"
    );
    ERC20Helper.safeTransfer(stakedToken, _to, _amount);
    emit ClaimStaked(_to, _amount);
  }
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IOctetFiPool {
  function creator() external view returns (address);
  function stakedToken() external view returns (address);
  function rewardToken() external view returns (address);

  function initialize(address, address, address) external;
  function claimStaked(address, uint256) external;
  function claimReward(address, uint256) external;
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