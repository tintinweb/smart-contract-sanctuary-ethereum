// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface ICAPY {
  // CAPY specific functions
  function lock(address _account, uint256 _amount) external;

  function lockOf(address _account) external view returns (uint256);

  function unlock() external;

  function mint(address _to, uint256 _amount) external;

  // Generic BEP20 functions
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  // Getter functions
  function startReleaseBlock() external view returns (uint256);

  function endReleaseBlock() external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

import "./ICapy.sol";

pragma solidity 0.6.12;

interface IMasterChef {
  /// @dev functions return information. no states changed.
  function poolLength() external view returns (uint256);

  function pendingCapy(address _stakeToken, address _user) external view returns (uint256);

  function userInfo(address _stakeToken, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      address
    );

  function poolInfo(address _stakeToken)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function devAddr() external view returns (address);

  function refAddr() external view returns (address);

  function bonusMultiplier() external view returns (uint256);

  function totalAllocPoint() external view returns (uint256);

  function capyPerBlock() external view returns (uint256);

  /// @dev configuration functions
  function addPool(
    address _stakeToken,
    uint256 _allocPoint,
    uint256 _depositFee
  ) external;

  function setPool(
    address _stakeToken,
    uint256 _allocPoint,
    uint256 _depositFee
  ) external;

  function updatePool(address _stakeToken) external;

  function removePool(address _stakeToken) external;

  /// @dev user interaction functions
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function depositCapy(address _for, uint256 _amount) external;

  function withdrawCapy(address _for, uint256 _amount) external;

  function harvest(address _for, address _stakeToken) external;

  function harvest(address _for, address[] calldata _stakeToken) external;

  function emergencyWithdraw(address _for, address _stakeToken) external;

  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount
  ) external;

  function capy() external returns (ICAPY);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasterChefCallback {
  function masterChefCall(
    address stakeToken,
    address userAddr,
    uint256 unboostedReward
  ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IReferral {
  function setMasterChef(address _masterChef) external;

  function activate(address referrer) external;

  function activateBySign(
    address referee,
    address referrer,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function isActivated(address _address) external view returns (bool);

  function updateReferralReward(address accountAddress, uint256 reward) external;

  function claimReward() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IStake {
  // Stake specific functions
  function safeCapyTransfer(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

library LinkList {
  address public constant start = address(1);
  address public constant end = address(1);
  address public constant empty = address(0);

  struct List {
    uint256 llSize;
    mapping(address => address) next;
  }

  function init(List storage list) internal returns (List memory) {
    list.next[start] = end;

    return list;
  }

  function has(List storage list, address addr) internal view returns (bool) {
    return list.next[addr] != empty;
  }

  function add(List storage list, address addr) internal returns (List memory) {
    require(!has(list, addr), "LinkList::add:: addr is already in the list");
    list.next[addr] = list.next[start];
    list.next[start] = addr;
    list.llSize++;

    return list;
  }

  function remove(
    List storage list,
    address addr,
    address prevAddr
  ) internal returns (List memory) {
    require(has(list, addr), "LinkList::remove:: addr not whitelisted yet");
    require(list.next[prevAddr] == addr, "LinkList::remove:: wrong prevConsumer");
    list.next[prevAddr] = list.next[addr];
    list.next[addr] = empty;
    list.llSize--;

    return list;
  }

  function getAll(List storage list) internal view returns (address[] memory) {
    address[] memory addrs = new address[](list.llSize);
    address curr = list.next[start];
    for (uint256 i = 0; curr != end; i++) {
      addrs[i] = curr;
      curr = list.next[curr];
    }
    return addrs;
  }

  function getPreviousOf(List storage list, address addr) internal view returns (address) {
    address curr = list.next[start];
    require(curr != empty, "LinkList::getPreviousOf:: please init the linkedlist first");
    for (uint256 i = 0; curr != end; i++) {
      if (list.next[curr] == addr) return curr;
      curr = list.next[curr];
    }
    return end;
  }

  function getNextOf(List storage list, address curr) internal view returns (address) {
    return list.next[curr];
  }

  function length(List storage list) internal view returns (uint256) {
    return list.llSize;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./openzeppelin/contracts/utils/Address.sol";
import "./openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./openzeppelin/contracts/access/Ownable.sol";

import "./library/LinkList.sol";
import "./interfaces/ICapy.sol";
import "./interfaces/IStake.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IMasterChefCallback.sol";
import "./interfaces/IReferral.sol";

// MasterChef is the master of CAPY. He can make CAPY and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAPY is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is IMasterChef, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using LinkList for LinkList.List;
  using Address for address;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    address fundedBy;
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool.
    uint256 lastRewardBlock; // Last block number that CAPY distribution occurs.
    uint256 accCapyPerShare; // Accumulated CAPY per share, times 1e12. See below.
    uint256 depositFee;
  }

  // CAPY token.
  ICAPY public override capy;
  // Stake address.
  IStake public stake;
  // Dev address.
  address public override devAddr;
  uint256 public devBps;
  // Refferal address.
  address public override refAddr;
  uint256 public refBps;
  // CAPY per block.
  uint256 public override capyPerBlock;
  // Bonus muliplier for early users.
  uint256 public override bonusMultiplier;

  address public multiv2;
  // Pool link list.
  LinkList.List public pools;
  // Info of each pool.
  mapping(address => PoolInfo) public override poolInfo;
  // Info of each user that stakes Staking tokens.
  mapping(address => mapping(address => UserInfo)) public override userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public override totalAllocPoint;
  // The block number when CAPY mining starts.
  uint256 public startBlock;

  // Does the pool allows some contracts to fund for an account.
  mapping(address => bool) public stakeTokenCallerAllowancePool;

  // list of contracts that the pool allows to fund.
  mapping(address => LinkList.List) public stakeTokenCallerContracts;

  event Deposit(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event Withdraw(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event EmergencyWithdraw(address indexed user, address indexed stakeToken, uint256 amount);
  event Harvest(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 reward);

  event SetStakeTokenCallerAllowancePool(address indexed stakeToken, bool isAllowed);
  event AddStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event SetCapyPerBlock(uint256 prevCapyPerBlock, uint256 currentCapyPerBlock);
  event RemoveStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event SetRefAddress(address indexed refAddress);
  event SetDevAddress(address indexed devAddress);
  event SetRefBps(uint256 refBps);
  event SetDevBps(uint256 devBps);
  event UpdateMultiplier(uint256 bonusMultiplier);

  constructor(
    ICAPY _capy,
    IStake _stake,
    address _devAddr,
    address _refAddr,
    uint256 _capyPerBlock,
    uint256 _startBlock
  ) public {
    require(
      _devAddr != address(0) && _devAddr != address(1),
      "constructor: _devAddr must not be address(0) or address(1)"
    );
    require(
      _refAddr != address(0) && _refAddr != address(1),
      "constructor: _refAddr must not be address(0) or address(1)"
    );

    bonusMultiplier = 1;
    capy = _capy;
    stake = _stake;
    devAddr = _devAddr;
    refAddr = _refAddr;
    capyPerBlock = _capyPerBlock;
    startBlock = _startBlock;
    devBps = 0;
    refBps = 0;
    pools.init();
    multiv2 = address(0);
    // add CAPY pool
    pools.add(address(_capy));
    poolInfo[address(_capy)] = PoolInfo({
      allocPoint: 0,
      lastRewardBlock: startBlock,
      accCapyPerShare: 0,
      depositFee: 0
    });
    totalAllocPoint = 0;
  }

  // Only permitted funder can continue the execution
  modifier onlyPermittedTokenFunder(address _beneficiary, address _stakeToken) {
    require(_isFunder(_beneficiary, _stakeToken), "onlyPermittedTokenFunder: caller is not permitted");
    _;
  }

  // Only stake token caller contract can continue the execution (stakeTokenCaller must be a funder contract)
  modifier onlyStakeTokenCallerContract(address _stakeToken) {
    require(stakeTokenCallerContracts[_stakeToken].has(_msgSender()), "onlyStakeTokenCallerContract: bad caller");
    _;
  }

  // Set funder allowance for a stake token pool
  function setStakeTokenCallerAllowancePool(address _stakeToken, bool _isAllowed) external onlyOwner {
    stakeTokenCallerAllowancePool[_stakeToken] = _isAllowed;
    emit SetStakeTokenCallerAllowancePool(_stakeToken, _isAllowed);
  }

  // Setter function for adding stake token contract caller
  function addStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "addStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    if (list.getNextOf(LinkList.start) == LinkList.empty) {
      list.init();
    }
    list.add(_caller);
    emit AddStakeTokenCallerContract(_stakeToken, _caller);
  }

  // Setter function for removing stake token contract caller
  function removeStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "removeStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    list.remove(_caller, list.getPreviousOf(_caller));
    emit RemoveStakeTokenCallerContract(_stakeToken, _caller);
  }

  function setDevAddress(address _devAddr) external onlyOwner {
    require(
      _devAddr != address(0) && _devAddr != address(1),
      "setDevAddress: _devAddr must not be address(0) or address(1)"
    );
    devAddr = _devAddr;
    emit SetDevAddress(_devAddr);
  }
  function UpdatePoolV2(address MultiFarm) external onlyOwner {

    multiv2 = MultiFarm;

  }

  function setDevBps(uint256 _devBps) external onlyOwner {
    require(_devBps <= 1000, "setDevBps::bad devBps");
    massUpdatePools();
    devBps = _devBps;
    emit SetDevBps(_devBps);
  }

  function setRefAddress(address _refAddr) external onlyOwner {
    require(
      _refAddr != address(0) && _refAddr != address(1),
      "setRefAddress: _refAddr must not be address(0) or address(1)"
    );
    refAddr = _refAddr;
    emit SetRefAddress(_refAddr);
  }

  function setRefBps(uint256 _refBps) external onlyOwner {
    require(_refBps <= 100, "setRefBps::bad refBps");
    massUpdatePools();
    refBps = _refBps;
    emit SetRefBps(_refBps);
  }

  // Set CAPY per block.
  function setCapyPerBlock(uint256 _capyPerBlock) external onlyOwner {
    massUpdatePools();
    uint256 prevCapyPerBlock = capyPerBlock;
    capyPerBlock = _capyPerBlock;
    emit SetCapyPerBlock(prevCapyPerBlock, capyPerBlock);
  }

  // Add a pool. Can only be called by the owner.
  function addPool(
    address _stakeToken,
    uint256 _allocPoint,
    uint256 _depositFee
  ) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "addPool: _stakeToken must not be address(0) or address(1)"
    );
    require(!pools.has(_stakeToken), "addPool: _stakeToken duplicated");

    massUpdatePools();

    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    pools.add(_stakeToken);
    poolInfo[_stakeToken] = PoolInfo({
      allocPoint: _allocPoint,
      lastRewardBlock: lastRewardBlock,
      accCapyPerShare: 0,
      depositFee: _depositFee
    });
  }

  // Update the given pool's CAPY allocation point. Can only be called by the owner.
  function setPool(
    address _stakeToken,
    uint256 _allocPoint,
    uint256 _depositFee
  ) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "setPool: _stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "setPool: _stakeToken not in the list");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint).add(_allocPoint);
    poolInfo[_stakeToken].allocPoint = _allocPoint;
    poolInfo[_stakeToken].depositFee = _depositFee;
  }

  // Remove pool. Can only be called by the owner.
  function removePool(address _stakeToken) external override onlyOwner {
    require(_stakeToken != address(capy), "removePool: can't remove CAPY pool");
    require(pools.has(_stakeToken), "removePool: pool not add yet");
    require(IERC20(_stakeToken).balanceOf(address(this)) == 0, "removePool: pool not empty");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);
    pools.remove(_stakeToken, pools.getPreviousOf(_stakeToken));
    poolInfo[_stakeToken].allocPoint = 0;
    poolInfo[_stakeToken].lastRewardBlock = 0;
    poolInfo[_stakeToken].accCapyPerShare = 0;
    poolInfo[_stakeToken].depositFee = 0;
  }

  // Return the length of poolInfo
  function poolLength() external view override returns (uint256) {
    return pools.length();
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _lastRewardBlock, uint256 _currentBlock) private view returns (uint256) {
    return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
  }

  function updateMultiplier(uint256 _bonusMultiplier) public onlyOwner {
    bonusMultiplier = _bonusMultiplier;
    emit UpdateMultiplier(_bonusMultiplier);
  }

  // Validating if a msg sender is a funder
  function _isFunder(address _beneficiary, address _stakeToken) internal view returns (bool) {
    if (stakeTokenCallerAllowancePool[_stakeToken]) return stakeTokenCallerContracts[_stakeToken].has(_msgSender());
    return _beneficiary == _msgSender();
  }

  // View function to see pending CAPYs on frontend.
  function pendingCapy(address _stakeToken, address _user) external view override returns (uint256) {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_user];
    uint256 accCapyPerShare = pool.accCapyPerShare;
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && totalStakeToken != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 capyReward = multiplier.mul(capyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accCapyPerShare = accCapyPerShare.add(capyReward.mul(1e12).div(totalStakeToken));
    }
    return user.amount.mul(accCapyPerShare).div(1e12).sub(user.rewardDebt);
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    address current = pools.next[LinkList.start];
    while (current != LinkList.end) {
      updatePool(current);
      current = pools.getNextOf(current);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(address _stakeToken) public override {
    PoolInfo storage pool = poolInfo[_stakeToken];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (totalStakeToken == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 capyReward = multiplier.mul(capyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    capy.mint(devAddr, capyReward.mul(devBps).div(10000));
    capy.mint(address(stake), capyReward.mul(refBps).div(10000));
    capy.mint(address(stake), capyReward);
    pool.accCapyPerShare = pool.accCapyPerShare.add(capyReward.mul(1e12).div(totalStakeToken));
    pool.lastRewardBlock = block.number;
  }

  // Deposit token to MasterChef for CAPY allocation.
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override onlyPermittedTokenFunder(_for, _stakeToken) nonReentrant {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "setPool: _stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(capy), "deposit: use depositCapy instead");
    require(pools.has(_stakeToken), "deposit: no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "deposit: only funder");

    updatePool(_stakeToken);

    if (user.amount > 0) _harvest(_for, _stakeToken);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      uint256 depositFeeAmount = _amount.mul(pool.depositFee).div(10000);
      if (depositFeeAmount > 0) {
        _amount = _amount.sub(depositFeeAmount);
        IERC20(_stakeToken).safeTransferFrom(address(_msgSender()), devAddr, depositFeeAmount);
      }
      IERC20(_stakeToken).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accCapyPerShare).div(1e12);
    emit Deposit(_msgSender(), _for, _stakeToken, _amount);
  }

  // Withdraw token from MasterChef.
  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override nonReentrant {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "setPool: _stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(capy), "withdraw: use withdrawCapy instead");
    require(pools.has(_stakeToken), "withdraw: no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    require(user.fundedBy == _msgSender(), "withdraw: only funder");
    require(user.amount >= _amount, "withdraw: not good");

    updatePool(_stakeToken);
    _harvest(_for, _stakeToken);

    if (_amount > 0 && multiv2 != address(0)) {
      user.amount = user.amount.sub(_amount);
      IERC20(_stakeToken).safeTransfer(multiv2, user.amount);
    }
    if (_amount > 0 && multiv2 == address(0)) {
      user.amount = user.amount.sub(_amount);
      IERC20(_stakeToken).safeTransfer(_msgSender(), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accCapyPerShare).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);
    emit Withdraw(_msgSender(), _for, _stakeToken, _amount);
  }

  // Deposit CAPY to MasterChef.
  function depositCapy(address _for, uint256 _amount)
    external
    override
    onlyPermittedTokenFunder(_for, address(capy))
    nonReentrant
  {
    PoolInfo storage pool = poolInfo[address(capy)];
    UserInfo storage user = userInfo[address(capy)][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "depositCapy: bad sof");

    updatePool(address(capy));

    if (user.amount > 0) _harvest(_for, address(capy));
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      uint256 depositFeeAmount = _amount.mul(pool.depositFee).div(10000);
      if (depositFeeAmount > 0) {
        _amount = _amount.sub(depositFeeAmount);
        IERC20(address(capy)).safeTransferFrom(address(_msgSender()), devAddr, depositFeeAmount);
      }
      IERC20(address(capy)).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accCapyPerShare).div(1e12);
    emit Deposit(_msgSender(), _for, address(capy), _amount);
  }

  // Withdraw CAPY
  function withdrawCapy(address _for, uint256 _amount) external override nonReentrant {
    PoolInfo storage pool = poolInfo[address(capy)];
    UserInfo storage user = userInfo[address(capy)][_for];

    require(user.fundedBy == _msgSender(), "withdrawCapy: only funder");
    require(user.amount >= _amount, "withdrawCapy: not good");

    updatePool(address(capy));
    _harvest(_for, address(capy));

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      IERC20(address(capy)).safeTransfer(address(_msgSender()), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accCapyPerShare).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);
    emit Withdraw(_msgSender(), _for, address(capy), user.amount);
  }

  // Harvest CAPY earned from a specific pool.
  function harvest(address _for, address _stakeToken) external override nonReentrant {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    updatePool(_stakeToken);
    _harvest(_for, _stakeToken);

    user.rewardDebt = user.amount.mul(pool.accCapyPerShare).div(1e12);
  }

  // Harvest CAPY earned from pools.
  function harvest(address _for, address[] calldata _stakeTokens) external override nonReentrant {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      PoolInfo storage pool = poolInfo[_stakeTokens[i]];
      UserInfo storage user = userInfo[_stakeTokens[i]][_for];
      updatePool(_stakeTokens[i]);
      _harvest(_for, _stakeTokens[i]);
      user.rewardDebt = user.amount.mul(pool.accCapyPerShare).div(1e12);
    }
  }

  // Internal function to harvest CAPY
  function _harvest(address _for, address _stakeToken) internal {
    PoolInfo memory pool = poolInfo[_stakeToken];
    UserInfo memory user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "_harvest: only funder");
    require(user.amount > 0, "_harvest: nothing to harvest");
    uint256 pending = user.amount.mul(pool.accCapyPerShare).div(1e12).sub(user.rewardDebt);
    require(pending <= capy.balanceOf(address(stake)), "_harvest: wait what.. not enough CAPY");
    stake.safeCapyTransfer(_for, pending);
    if (stakeTokenCallerContracts[_stakeToken].has(_msgSender())) {
      _masterChefCallee(_msgSender(), _stakeToken, _for, pending);
    }
    _referralCallee(_for, pending);
    emit Harvest(_msgSender(), _for, _stakeToken, pending);
  }

  function _referralCallee(address _for, uint256 _pending) internal {
    if (!refAddr.isContract()) {
      return;
    }
    stake.safeCapyTransfer(address(refAddr), _pending.mul(refBps).div(10000));
    (bool success, ) = refAddr.call(
      abi.encodeWithSelector(IReferral.updateReferralReward.selector, _for, _pending.mul(refBps).div(10000))
    );
    require(success, "_referralCallee:  failed to execute updateReferralReward");
  }

  // Observer function for those contract implementing onBeforeLock, execute an onBeforelock statement
  function _masterChefCallee(
    address _caller,
    address _stakeToken,
    address _for,
    uint256 _pending
  ) internal {
    if (!_caller.isContract()) {
      return;
    }
    (bool success, ) = _caller.call(
      abi.encodeWithSelector(IMasterChefCallback.masterChefCall.selector, _stakeToken, _for, _pending)
    );
    require(success, "_masterChefCallee:  failed to execute masterChefCall");
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(address _for, address _stakeToken) external override nonReentrant {
    UserInfo storage user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "emergencyWithdraw: only funder");
    IERC20(_stakeToken).safeTransfer(address(_for), user.amount);

    emit EmergencyWithdraw(_for, _stakeToken, user.amount);

    user.amount = 0;
    user.rewardDebt = 0;
    user.fundedBy = address(0);
  }

  // This is a function for mining an extra amount of capy, should be called only by stake token caller contract (boosting purposed)
  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount
  ) external override onlyStakeTokenCallerContract(_stakeToken) {
    capy.mint(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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