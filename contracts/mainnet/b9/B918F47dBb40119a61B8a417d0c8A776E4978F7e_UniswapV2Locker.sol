/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// SafeMutual reserves all rights on this code. You may NOT copy these contracts.

// This contract locks uniswap v2 liquidity tokens. Used to give investors peace of mind a token team has locked liquidity
// and that the univ2 tokens cannot be removed from uniswap until the specified unlock date has been reached.

pragma solidity 0.6.12;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; 

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner) external returns (bool);
}

contract UniswapV2Locker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  IUniFactory public uniswapFactory;

  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all tokens the user has locked
    mapping(address => uint256[]) locksForToken; // map erc20 address to lock id for that token
  }

  struct TokenLock {
    uint256 lockDate; // the date the token was locked
    uint256 amount; // the amount of tokens still locked (initialAmount minus withdrawls)
    uint256 initialAmount; // the initial lock amount
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner;
  }

  mapping(address => UserInfo) private users;

  EnumerableSet.AddressSet private lockedTokens;
  mapping(address => TokenLock[]) public tokenLocks; //map univ2 pair to all its locks
  
  struct FeeStruct {
    uint256 ethFee; // Small eth fee to prevent spam on the platform
    IERCBurn secondaryFeeToken; // UNCX or UNCL
    uint256 secondaryTokenFee; // optional, UNCX or UNCL
    uint256 secondaryTokenDiscount; // discount on liquidity fee for burning secondaryToken
    uint256 liquidityFee; // fee on univ2 liquidity tokens
    uint256 referralPercent; // fee for referrals
    IERCBurn referralToken; // token the refferer must hold to qualify as a referrer
    uint256 referralHold; // balance the referrer must hold to qualify as a referrer
    uint256 referralDiscount; // discount on flatrate fees for using a valid referral address
  }
    
  FeeStruct public gFees;
  EnumerableSet.AddressSet private feeWhitelist;
  
  address payable devaddr;
  
  IMigrator migrator;
  address public MIGRATION_IN;

  event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
  event onWithdraw(address lpToken, uint256 amount);

  constructor(IUniFactory _uniswapFactory) public {
    devaddr = msg.sender;
    gFees.referralPercent = 250; // 25%
    gFees.ethFee = 13*1e16;
    gFees.secondaryTokenFee = 50e18;
    gFees.secondaryTokenDiscount = 400; // 40%
    gFees.liquidityFee = 10; // 1%
    gFees.referralHold = 10e18;
    gFees.referralDiscount = 100; // 10%
    uniswapFactory = _uniswapFactory;
  }
  
  function setDev(address payable _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }
  
  /**
   * @notice set the migrator contract which allows locked lp tokens to be migrated to uniswap v3
   */
  function setMigrator(IMigrator _migrator) public onlyOwner {
    migrator = _migrator;
  }

  function setMigrationIn(address _migrationIn) public onlyOwner {
    MIGRATION_IN = _migrationIn;
  }
  
  function setSecondaryFeeToken(address _secondaryFeeToken) public onlyOwner {
    gFees.secondaryFeeToken = IERCBurn(_secondaryFeeToken);
  }
  
  /**
   * @notice referrers need to hold the specified token and hold amount to be elegible for referral fees
   */
  function setReferralTokenAndHold(IERCBurn _referralToken, uint256 _hold) public onlyOwner {
    gFees.referralToken = _referralToken;
    gFees.referralHold = _hold;
  }
  
  function setFees(uint256 _referralPercent, uint256 _referralDiscount, uint256 _ethFee, uint256 _secondaryTokenFee, uint256 _secondaryTokenDiscount, uint256 _liquidityFee) public onlyOwner {
    gFees.referralPercent = _referralPercent;
    gFees.referralDiscount = _referralDiscount;
    gFees.ethFee = _ethFee;
    gFees.secondaryTokenFee = _secondaryTokenFee;
    gFees.secondaryTokenDiscount = _secondaryTokenDiscount;
    gFees.liquidityFee = _liquidityFee;
  }
  
  /**
   * @notice whitelisted accounts dont pay flatrate fees on locking
   */
  function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
    if (_add) {
      feeWhitelist.add(_user);
    } else {
      feeWhitelist.remove(_user);
    }
  }

  /**
   * @notice Creates a new lock
   * @param _lpToken the univ2 token address
   * @param _amount amount of LP tokens to lock
   * @param _unlock_date the unix timestamp (in seconds) until unlock
   * @param _referral the referrer address if any or address(0) for none
   * @param _fee_in_eth fees can be paid in eth or in a secondary token such as UNCX with a discount on univ2 tokens
   * @param _withdrawer the user who can withdraw liquidity once the lock expires.
   */
  function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer) external payable nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    require(_amount > 0, 'INSUFFICIENT');

    // ensure this pair is a univ2 pair by querying the factory
    IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
    address factoryPairAddress = uniswapFactory.getPair(lpair.token0(), lpair.token1());
    require(factoryPairAddress == address(_lpToken), 'NOT UNIV2');

    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    
    if (_referral != address(0) && address(gFees.referralToken) != address(0)) {
      require(gFees.referralToken.balanceOf(_referral) >= gFees.referralHold, 'INADEQUATE BALANCE');
    }
    
    // flatrate fees
    if (!feeWhitelist.contains(msg.sender)) {
      if (_fee_in_eth) { // charge fee in eth
        uint256 ethFee = gFees.ethFee;
        if (_referral != address(0)) {
          ethFee = ethFee.mul(1000 - gFees.referralDiscount).div(1000);
        }
        require(msg.value == ethFee, 'FEE NOT MET');
        uint256 devFee = ethFee;
        if (ethFee != 0 && _referral != address(0)) { // referral fee
          uint256 referralFee = devFee.mul(gFees.referralPercent).div(1000);
          _referral.transfer(referralFee);
          devFee = devFee.sub(referralFee);
        }
        devaddr.transfer(devFee);
      } else { // charge fee in token
        uint256 burnFee = gFees.secondaryTokenFee;
        if (_referral != address(0)) {
          burnFee = burnFee.mul(1000 - gFees.referralDiscount).div(1000);
        }
        TransferHelper.safeTransferFrom(address(gFees.secondaryFeeToken), address(msg.sender), address(this), burnFee);
        if (gFees.referralPercent != 0 && _referral != address(0)) { // referral fee
          uint256 referralFee = burnFee.mul(gFees.referralPercent).div(1000);
          TransferHelper.safeApprove(address(gFees.secondaryFeeToken), _referral, referralFee);
          TransferHelper.safeTransfer(address(gFees.secondaryFeeToken), _referral, referralFee);
          burnFee = burnFee.sub(referralFee);
        }
        gFees.secondaryFeeToken.burn(burnFee);
      }
    } else if (msg.value > 0){
      // refund eth if a whitelisted member sent it by mistake
      msg.sender.transfer(msg.value);
    }
    
    // percent fee
    uint256 amountLocked = _amount;
    if (msg.sender != MIGRATION_IN) {
      uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
      if (!_fee_in_eth && !feeWhitelist.contains(msg.sender)) { // fee discount for large lockers using secondary token
        liquidityFee = liquidityFee.mul(1000 - gFees.secondaryTokenDiscount).div(1000);
      }
      TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
      amountLocked = _amount.sub(liquidityFee);
    }

    TokenLock memory token_lock;
    token_lock.lockDate = block.timestamp;
    token_lock.amount = amountLocked;
    token_lock.initialAmount = amountLocked;
    token_lock.unlockDate = _unlock_date;
    token_lock.lockID = tokenLocks[_lpToken].length;
    token_lock.owner = _withdrawer;

    // record the lock for the univ2pair
    tokenLocks[_lpToken].push(token_lock);
    lockedTokens.add(_lpToken);

    // record the lock for the user
    UserInfo storage user = users[_withdrawer];
    user.lockedTokens.add(_lpToken);
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(token_lock.lockID);
    
    emit onDeposit(_lpToken, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
  }
  
  /**
   * @notice extend a lock with a new unlock date, _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
  function relock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');
    
    uint256 liquidityFee = userLock.amount.mul(gFees.liquidityFee).div(1000);
    uint256 amountLocked = userLock.amount.sub(liquidityFee);
    
    userLock.amount = amountLocked;
    userLock.unlockDate = _unlock_date;

    // send univ2 fee to dev address
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
  }
  
  /**
   * @notice withdraw a specified amount from a lock. _index and _lockID ensure the correct lock is changed
   * this prevents errors when a user performs multiple tx per block possibly with varying gas prices
   */
  function withdraw (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO WITHDRAWL');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    require(userLock.unlockDate < block.timestamp, 'NOT YET');
    userLock.amount = userLock.amount.sub(_amount);
    
    // clean user storage
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(_lpToken);
      }
    }
    
    TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
    emit onWithdraw(_lpToken, _amount);
  }
  
  /**
   * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock, less fees, and faster loading on our live block explorer
   */
  function incrementLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    
    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    
    // send univ2 fee to dev address
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);
    
    userLock.amount = userLock.amount.add(amountLocked);
    
    emit onDeposit(_lpToken, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
  }
  
  /**
   * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   */
  function splitLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external payable nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    
    require(msg.value == gFees.ethFee, 'FEE NOT MET');
    devaddr.transfer(gFees.ethFee);
    
    userLock.amount = userLock.amount.sub(_amount);
    
    TokenLock memory token_lock;
    token_lock.lockDate = userLock.lockDate;
    token_lock.amount = _amount;
    token_lock.initialAmount = _amount;
    token_lock.unlockDate = userLock.unlockDate;
    token_lock.lockID = tokenLocks[_lpToken].length;
    token_lock.owner = msg.sender;

    // record the lock for the univ2pair
    tokenLocks[_lpToken].push(token_lock);

    // record the lock for the user
    UserInfo storage user = users[msg.sender];
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(token_lock.lockID);
  }
  
  /**
   * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   */
  function transferLockOwnership (address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external {
    require(msg.sender != _newOwner, 'OWNER');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && transferredLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    
    // record the lock for the new Owner
    UserInfo storage user = users[_newOwner];
    user.lockedTokens.add(_lpToken);
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(transferredLock.lockID);
    
    // remove the lock from the old owner
    uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
    userLocks[_index] = userLocks[userLocks.length-1];
    userLocks.pop();
    if (userLocks.length == 0) {
      users[msg.sender].lockedTokens.remove(_lpToken);
    }
    transferredLock.owner = _newOwner;
  }
  
  /**
   * @notice migrates liquidity to uniswap v3
   */
  function migrate (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(address(migrator) != address(0), "NOT SET");
    require(_amount > 0, 'ZERO MIGRATION');
    
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    userLock.amount = userLock.amount.sub(_amount);
    
    // clean user storage
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(_lpToken);
      }
    }
    
    TransferHelper.safeApprove(_lpToken, address(migrator), _amount);
    migrator.migrate(_lpToken, _amount, userLock.unlockDate, msg.sender);
  }
  
  function getNumLocksForToken (address _lpToken) external view returns (uint256) {
    return tokenLocks[_lpToken].length;
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return lockedTokens.length();
  }
  
  function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
    return lockedTokens.at(_index);
  }
  
  // user functions
  function getUserNumLockedTokens (address _user) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.lockedTokens.length();
  }
  
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    UserInfo storage user = users[_user];
    return user.lockedTokens.at(_index);
  }
  
  function getUserNumLocksForToken (address _user, address _lpToken) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.locksForToken[_lpToken].length;
  }
  
  function getUserLockForTokenAtIndex (address _user, address _lpToken, uint256 _index) external view 
  returns (uint256, uint256, uint256, uint256, uint256, address) {
    uint256 lockID = users[_user].locksForToken[_lpToken][_index];
    TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
    return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
  }
  
  // whitelist
  function getWhitelistedUsersLength () external view returns (uint256) {
    return feeWhitelist.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return feeWhitelist.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return feeWhitelist.contains(_user);
  }
}