// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IERC20.sol";

import "SafeOwnable.sol";
import "Math.sol";
import "ReentrancyGuard.sol";

// veWILD is a non-transferrable governance token minted by locking up WILD
// The longer the lock period, the higher the reward
// 1 veWILD = WILD locked for 4 years

contract VeToken is SafeOwnable, ReentrancyGuard {

  uint private constant MIN_LOCK_PERIOD = 1 weeks;
  uint private constant MAX_LOCK_PERIOD = 1460 days; // 4 years
  uint private constant WITHDRAW_DELAY  = 1 days;

  mapping (address => uint) public balanceOf; // veBalanceOf
  mapping (address => uint) public lockedBalanceOf;
  mapping (address => uint) public lockedUntil;
  mapping (address => uint) public rewardSnapshot;
  mapping (address => uint) public withdrawAt;

  string public constant name     = 'veWILD';
  string public constant symbol   = 'veWILD';
  uint8  public constant decimals = 18;
  uint   public totalSupply;
  uint   public totalLocked;
  uint   public distributionPeriod;

  address public  lockedToken;     // WILD
  uint    public  lastAccrueBlock;
  uint    public  lastIncomeBlock;
  uint    public  rewardPerToken;  // Reward per veToken. Increases over time.
  uint    private rewardRateStored;

  event Transfer(address indexed from, address indexed to, uint value);

  event Lock            (address indexed account, uint lockedBalance, uint veBalance, uint lockedUntil);
  event WithdrawRequest (address indexed account, uint amount, uint withdrawAt);
  event Withdraw        (address indexed account, uint amount);
  event Claim           (address indexed account, uint veBalance, uint claimAmount);
  event NewIncome       (uint addAmount, uint remainingAmount, uint rewardRate);
  event NewDistributionPeriod(uint value);

  function initialize(address _lockedToken, uint _distributionPeriod) external {
    require(lockedToken == address(0), "VeToken: already initialized");

    lockedToken     = _lockedToken;
    lastAccrueBlock = block.number;
    _setDistributionPeriod(_distributionPeriod);

    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  function lock(uint _amount, uint _newLockedUntil) external nonReentrant {
    uint lockSeconds = _newLockedUntil - block.timestamp;

    require(lockSeconds >= MIN_LOCK_PERIOD, "VeToken: lock time too short");
    require(lockSeconds <= MAX_LOCK_PERIOD, "VeToken: lock time too long");
    require(_newLockedUntil >= lockedUntil[msg.sender], "VeToken: cannot reduce locked time");

    _claim();

    if (_amount > 0) {
      lockedBalanceOf[msg.sender] += _amount;
      totalLocked += _amount;
      IERC20(lockedToken).transferFrom(msg.sender, address(this), _amount);
    }

    _updateLock(msg.sender, _newLockedUntil);
    _checkReserves();

    // TODO: 1M total locked WILD limit. remove after the initial test period
    require(totalLocked < 1000000e18, "lock limit reached");

    emit Lock(msg.sender, lockedBalanceOf[msg.sender], balanceOf[msg.sender], _newLockedUntil);
  }

  function requestWithdraw() external nonReentrant {
    uint withdrawAmount = lockedBalanceOf[msg.sender];

    require(withdrawAmount > 0, "VeToken: nothing to withdraw");
    require(block.timestamp > lockedUntil[msg.sender], "VeToken: cannot withdraw before unlock");

    _claim();
    withdrawAt[msg.sender] = block.timestamp + WITHDRAW_DELAY;

    emit WithdrawRequest(msg.sender, withdrawAmount, withdrawAt[msg.sender]);
  }

  function withdraw() external nonReentrant {
    uint withdrawTime = withdrawAt[msg.sender];
    uint withdrawAmount = lockedBalanceOf[msg.sender];

    require(withdrawTime > 0 && withdrawTime <= block.timestamp, "VeToken: withdraw delay not over");

    withdrawAt[msg.sender] = 0;

    totalLocked -= withdrawAmount;
    lockedBalanceOf[msg.sender] = 0;
    _setBalance(msg.sender, 0);

    IERC20(lockedToken).transfer(msg.sender, withdrawAmount);
    _checkReserves();

    emit Withdraw(msg.sender, withdrawAmount);
  }

  // Claiming resets veWILD balance based on locked WILD and lock time remaining.
  function claim() external nonReentrant {
    _claim();
    _checkReserves();
  }

  // Update rewardRateStored to distribute previous unvested income + new income
  // over the next distributionPeriod blocks
  function addIncome(uint _addAmount) external onlyOwner {
    _accrue();
    IERC20(lockedToken).transferFrom(msg.sender, address(this), _addAmount);

    uint unvestedIncome = _updateRewardRate(_addAmount, distributionPeriod);
    _checkReserves();

    emit NewIncome(_addAmount, unvestedIncome, rewardRateStored);
  }

  function setDistributionPeriod(uint _blocks) external onlyOwner {
    _setDistributionPeriod(_blocks);
  }

  // If no new income is added for more than distributionPeriod blocks,
  // then do not distribute any more rewards
  function rewardRate() public view returns(uint) {
    uint blocksElapsed = block.number - lastIncomeBlock;

    if (blocksElapsed < distributionPeriod) {
      return rewardRateStored;
    } else {
      return 0;
    }
  }

  function pendingAccountReward(address _account) public view returns(uint) {
    uint pedingRewardPerToken = rewardPerToken + _pendingRewardPerToken();
    uint rewardPerTokenDelta  = pedingRewardPerToken - rewardSnapshot[_account];
    return rewardPerTokenDelta * balanceOf[_account] / 1e18;
  }

  function _claim() internal {
    _accrue();
    uint pendingReward = pendingAccountReward(msg.sender);

    if(pendingReward > 0) {
      IERC20(lockedToken).transfer(msg.sender, pendingReward);
    }

    rewardSnapshot[msg.sender] = rewardPerToken;
    _updateLock(msg.sender, lockedUntil[msg.sender]);

    emit Claim(msg.sender, balanceOf[msg.sender], pendingReward);
  }

  function _accrue() internal {
    rewardPerToken += _pendingRewardPerToken();
    lastAccrueBlock = block.number;
  }

  function _setDistributionPeriod(uint _blocks) internal {
    require(_blocks > 0, "VeToken: distribution period must be >= 100 blocks");
    _accrue();
    _updateRewardRate(0, _blocks);
    emit NewDistributionPeriod(_blocks);
  }

  function _updateRewardRate(uint _addAmount, uint _newDistributionPeriod) internal returns(uint) {
    // Avoid inflation of blocksElapsed inside of _pendingRewardPerToken()
    // Ensures _pendingRewardPerToken() is 0 and all rewards are accounted for
    require(block.number == lastAccrueBlock, "VeToken: accrue first");

    uint blocksElapsed  = Math.min(distributionPeriod, block.number - lastIncomeBlock);
    uint unvestedIncome = rewardRateStored * (distributionPeriod - blocksElapsed);

    rewardRateStored   = (unvestedIncome + _addAmount) / _newDistributionPeriod;
    distributionPeriod = _newDistributionPeriod;
    lastIncomeBlock    = block.number;

    return unvestedIncome;
  }

  function _updateLock(address _account, uint _newLockedUntil) internal {
    uint lockSeconds = _newLockedUntil > block.timestamp ? _newLockedUntil - block.timestamp : 0;
    uint newBalance = (lockedBalanceOf[_account] * lockSeconds) / MAX_LOCK_PERIOD;
    lockedUntil[msg.sender] = _newLockedUntil;
    _setBalance(_account, newBalance);
  }

  function _setBalance(address _account, uint _amount) internal {
    // Balance must be updated after claiming as it's used to calculate pending rewards
    require(rewardSnapshot[msg.sender] == rewardPerToken, "VeToken: claim first");

    if (balanceOf[_account] > _amount) {
      _burn(_account, balanceOf[_account] - _amount);
    } else if (balanceOf[_account] < _amount) {
      _mint(_account, _amount - balanceOf[_account]);
    }
  }

  function _mint(address _account, uint _amount) internal {
    balanceOf[_account] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0), _account, _amount);
  }

  function _burn(address _account, uint _amount) internal {
    balanceOf[_account] -= _amount;
    totalSupply -= _amount;
    emit Transfer(_account, address(0), _amount);
  }

  function _pendingRewardPerToken() internal view returns(uint) {
    if (totalSupply == 0) { return 0; }

    uint blocksElapsed = block.number - lastAccrueBlock;
    return blocksElapsed * rewardRate() * 1e18 / totalSupply;
  }

  function _checkReserves() internal view {
    uint reserveBalance = IERC20(lockedToken).balanceOf(address(this));

    uint blocksElapsed  = Math.min(distributionPeriod, block.number - lastIncomeBlock);
    uint unvestedIncome = rewardRateStored * (distributionPeriod - blocksElapsed);

    require(reserveBalance >= totalLocked + unvestedIncome, "VeToken: reserve balance too low");
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns(uint);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function allowance(address owner, address spender) external view returns(uint);
  function decimals() external view returns(uint8);
  function approve(address spender, uint amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint amount) external returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

contract SafeOwnable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 1 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute.
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}