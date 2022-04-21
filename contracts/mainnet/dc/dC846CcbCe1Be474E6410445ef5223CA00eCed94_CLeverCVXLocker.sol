// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/ICLeverCVXLocker.sol";
import "../interfaces/ICLeverToken.sol";
import "../interfaces/IConvexCVXLocker.sol";
import "../interfaces/IConvexCVXRewardPool.sol";
import "../interfaces/IFurnace.sol";
import "../interfaces/ISnapshotDelegateRegistry.sol";
import "../interfaces/IZap.sol";

// solhint-disable not-rely-on-time, max-states-count, reason-string

contract CLeverCVXLocker is OwnableUpgradeable, ICLeverCVXLocker {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UpdateWhitelist(address indexed _whitelist, bool _status);
  event UpdateStakePercentage(uint256 _percentage);
  event UpdateStakeThreshold(uint256 _threshold);
  event UpdateRepayFeePercentage(uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);
  event UpdateGovernor(address indexed _governor);

  // The precision used to calculate accumulated rewards.
  uint256 private constant PRECISION = 1e18;
  // The denominator used for fee calculation.
  uint256 private constant FEE_DENOMINATOR = 1e9;
  // The maximum value of repay fee percentage.
  uint256 private constant MAX_REPAY_FEE = 1e8; // 10%
  // The maximum value of platform fee percentage.
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  // The maximum value of harvest bounty percentage.
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%
  // The length of epoch in CVX Locker.
  uint256 private constant REWARDS_DURATION = 86400 * 7; // 1 week

  // The address of CVX token.
  address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
  // The address of cvxCRV token.
  address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
  // The address of CVXRewardPool Contract.
  address private constant CVX_REWARD_POOL = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;
  // The address of CVXLockerV2 Contract.
  address private constant CVX_LOCKER = 0x72a19342e8F1838460eBFCCEf09F6585e32db86E;
  // The address of votium distributor
  address private constant VOTIUM_DISTRIBUTOR = 0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;

  struct EpochUnlockInfo {
    // The number of CVX should unlocked at the start of epoch `unlockEpoch`.
    uint192 pendingUnlock;
    // The epoch number to unlock `pendingUnlock` CVX
    uint64 unlockEpoch;
  }

  struct UserInfo {
    // The total number of clevCVX minted.
    uint128 totalDebt;
    // The amount of distributed reward.
    uint128 rewards;
    // The paid accumulated reward per share, multipled by 1e18.
    uint192 rewardPerSharePaid;
    // The block number of the last interacted block (deposit, unlock, withdraw, repay, borrow).
    uint64 lastInteractedBlock;
    // The total amount of CVX locked.
    uint112 totalLocked;
    // The total amount of CVX unlocked.
    uint112 totalUnlocked;
    // The next unlock index to speedup unlock process.
    uint32 nextUnlockIndex;
    // In Convex, if you lock at epoch `e` (block.timestamp in `[e * rewardsDuration, (e + 1) * rewardsDuration)`),
    // you lock will start at epoch `e + 1` and will unlock at the beginning of epoch `(e + 17)`. If we relock right
    //  after the unlock, all unlocked CVX will start lock at epoch `e + 18`, and will locked again at epoch `e + 18 + 16`.
    // If we continue the process, all CVX locked in epoch `e` will be unlocked at epoch `e + 17 * k` (k >= 1).
    //
    // Here, we maintain an array for easy calculation when users lock or unlock.
    //
    // `epochLocked[r]` maintains all locked CVX whose unlocking epoch is `17 * k + r`. It means at the beginning of
    //  epoch `17 * k + r`, the CVX will unlock, if we continue to relock right after unlock.
    uint256[17] epochLocked;
    // The list of pending unlocked CVX.
    EpochUnlockInfo[] pendingUnlockList;
  }

  /// @dev The address of governor
  address public governor;
  /// @dev The address of clevCVX contract.
  address public clevCVX;

  /// @dev Assumptons:
  ///  1. totalLockedGlobal + totalPendingUnlockGlobal is the total amount of CVX locked in CVXLockerV2.
  ///  2. totalUnlockedGlobal is the total amount of CVX unlocked from CVXLockerV2 but still in contract.
  ///  3. totalDebtGlobal is the total amount of clevCVX borrowed, will decrease when debt is repayed.
  /// @dev The total amount of CVX locked in contract.
  uint256 public totalLockedGlobal;
  /// @dev The total amount of CVX going to unlocked.
  uint256 public totalPendingUnlockGlobal;
  /// @dev The total amount of CVX unlocked in CVXLockerV2 and will never be locked again.
  uint256 public totalUnlockedGlobal;
  /// @dev The total amount of clevCVX borrowed from this contract.
  uint256 public totalDebtGlobal;

  /// @dev The reward per share of CVX accumulated, will be updated in each harvest, multipled by 1e18.
  uint256 public accRewardPerShare;
  /// @dev Mapping from user address to user info.
  mapping(address => UserInfo) public userInfo;
  /// @dev Mapping from epoch number to the amount of CVX to be unlocked.
  mapping(uint256 => uint256) public pendingUnlocked;
  /// @dev The address of Furnace Contract.
  address public furnace;
  /// @dev The percentage of free CVX will be staked in CVXRewardPool.
  uint256 public stakePercentage;
  /// @dev The minimum of amount of CVX to be staked.
  uint256 public stakeThreshold;
  /// @dev The debt reserve rate to borrow clevCVX for each user.
  uint256 public reserveRate;
  /// @dev The list of tokens which will swap manually.
  mapping(address => bool) public manualSwapRewardToken;

  /// @dev The address of zap contract.
  address public zap;
  /// @dev The percentage of repay fee.
  uint256 public repayFeePercentage;
  /// @dev The percentage of rewards to take for caller on harvest
  uint256 public harvestBountyPercentage;
  /// @dev The percentage of rewards to take for platform on harvest
  uint256 public platformFeePercentage;
  /// @dev The address of recipient of platform fee
  address public platform;

  /// @dev The list of whitelist keeper.
  mapping(address => bool) public isKeeper;

  modifier onlyGovernorOrOwner() {
    require(msg.sender == governor || msg.sender == owner(), "CLeverCVXLocker: only governor or owner");
    _;
  }

  modifier onlyKeeper() {
    require(isKeeper[msg.sender], "CLeverCVXLocker: only keeper");
    _;
  }

  function initialize(
    address _governor,
    address _clevCVX,
    address _zap,
    address _furnace,
    address _platform,
    uint256 _platformFeePercentage,
    uint256 _harvestBountyPercentage
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_governor != address(0), "CLeverCVXLocker: zero governor address");
    require(_clevCVX != address(0), "CLeverCVXLocker: zero clevCVX address");
    require(_zap != address(0), "CLeverCVXLocker: zero zap address");
    require(_furnace != address(0), "CLeverCVXLocker: zero furnace address");
    require(_platform != address(0), "CLeverCVXLocker: zero platform address");
    require(_platformFeePercentage <= MAX_PLATFORM_FEE, "CLeverCVXLocker: fee too large");
    require(_harvestBountyPercentage <= MAX_HARVEST_BOUNTY, "CLeverCVXLocker: fee too large");

    governor = _governor;
    clevCVX = _clevCVX;
    zap = _zap;
    furnace = _furnace;
    platform = _platform;
    platformFeePercentage = _platformFeePercentage;
    harvestBountyPercentage = _harvestBountyPercentage;
    reserveRate = 500_000_000;
  }

  /********************************** View Functions **********************************/

  /// @dev Return user info in this contract.
  /// @param _account The address of user.
  /// @return totalDeposited The amount of CVX deposited in this contract of the user.
  /// @return totalPendingUnlocked The amount of CVX pending to be unlocked.
  /// @return totalUnlocked The amount of CVX unlokced of the user and can be withdrawed.
  /// @return totalBorrowed The amount of clevCVX borrowed by the user.
  /// @return totalReward The amount of CVX reward accrued for the user.
  function getUserInfo(address _account)
    external
    view
    override
    returns (
      uint256 totalDeposited,
      uint256 totalPendingUnlocked,
      uint256 totalUnlocked,
      uint256 totalBorrowed,
      uint256 totalReward
    )
  {
    UserInfo storage _info = userInfo[_account];

    totalDeposited = _info.totalLocked;

    // update total reward and total Borrowed
    totalBorrowed = _info.totalDebt;
    totalReward = uint256(_info.rewards).add(
      accRewardPerShare.sub(_info.rewardPerSharePaid).mul(totalDeposited) / PRECISION
    );
    if (totalBorrowed > 0) {
      if (totalReward >= totalBorrowed) {
        totalReward -= totalBorrowed;
        totalBorrowed = 0;
      } else {
        totalBorrowed -= totalReward;
        totalReward = 0;
      }
    }

    // update total unlocked and total pending unlocked.
    totalUnlocked = _info.totalUnlocked;
    EpochUnlockInfo[] storage _pendingUnlockList = _info.pendingUnlockList;
    uint256 _nextUnlockIndex = _info.nextUnlockIndex;
    uint256 _currentEpoch = block.timestamp / REWARDS_DURATION;
    while (_nextUnlockIndex < _pendingUnlockList.length) {
      if (_pendingUnlockList[_nextUnlockIndex].unlockEpoch <= _currentEpoch) {
        totalUnlocked += _pendingUnlockList[_nextUnlockIndex].pendingUnlock;
      } else {
        totalPendingUnlocked += _pendingUnlockList[_nextUnlockIndex].pendingUnlock;
      }
      _nextUnlockIndex += 1;
    }
  }

  /// @dev Return the lock and pending unlocked list of user.
  /// @param _account The address of user.
  /// @return locks The list of CVX locked by the user, including amount and nearest unlock epoch.
  /// @return pendingUnlocks The list of CVX pending unlocked of the user, including amount and the unlock epoch.
  function getUserLocks(address _account)
    external
    view
    returns (EpochUnlockInfo[] memory locks, EpochUnlockInfo[] memory pendingUnlocks)
  {
    UserInfo storage _info = userInfo[_account];

    uint256 _currentEpoch = block.timestamp / REWARDS_DURATION;
    uint256 lengthLocks;
    for (uint256 i = 0; i < 17; i++) {
      if (_info.epochLocked[i] > 0) {
        lengthLocks++;
      }
    }
    locks = new EpochUnlockInfo[](lengthLocks);
    lengthLocks = 0;
    for (uint256 i = 0; i < 17; i++) {
      uint256 _index = (_currentEpoch + i + 1) % 17;
      if (_info.epochLocked[_index] > 0) {
        locks[lengthLocks].pendingUnlock = uint192(_info.epochLocked[_index]);
        locks[lengthLocks].unlockEpoch = uint64(_currentEpoch + i + 1);
        lengthLocks += 1;
      }
    }

    uint256 _nextUnlockIndex = _info.nextUnlockIndex;
    EpochUnlockInfo[] storage _pendingUnlockList = _info.pendingUnlockList;
    uint256 lengthPendingUnlocks;
    for (uint256 i = _nextUnlockIndex; i < _pendingUnlockList.length; i++) {
      if (_pendingUnlockList[i].unlockEpoch > _currentEpoch) {
        lengthPendingUnlocks += 1;
      }
    }
    pendingUnlocks = new EpochUnlockInfo[](lengthPendingUnlocks);
    lengthPendingUnlocks = 0;
    for (uint256 i = _nextUnlockIndex; i < _pendingUnlockList.length; i++) {
      if (_pendingUnlockList[i].unlockEpoch > _currentEpoch) {
        pendingUnlocks[lengthPendingUnlocks] = _pendingUnlockList[i];
        lengthPendingUnlocks += 1;
      }
    }
  }

  /// @dev Return the total amount of free CVX in this contract, including staked in CVXRewardPool.
  /// @return The amount of CVX in this contract now.
  function totalCVXInPool() public view returns (uint256) {
    return
      IERC20Upgradeable(CVX).balanceOf(address(this)).add(
        IConvexCVXRewardPool(CVX_REWARD_POOL).balanceOf(address(this))
      );
  }

  /********************************** Mutated Functions **********************************/

  /// @dev Deposit CVX and lock into CVXLockerV2
  /// @param _amount The amount of CVX to lock.
  function deposit(uint256 _amount) external override {
    require(_amount > 0, "CLeverCVXLocker: deposit zero CVX");
    IERC20Upgradeable(CVX).safeTransferFrom(msg.sender, address(this), _amount);

    // 1. update reward info
    _updateReward(msg.sender);

    // 2. lock to CVXLockerV2
    IERC20Upgradeable(CVX).safeApprove(CVX_LOCKER, 0);
    IERC20Upgradeable(CVX).safeApprove(CVX_LOCKER, _amount);
    IConvexCVXLocker(CVX_LOCKER).lock(address(this), _amount, 0);

    // 3. update user lock info
    uint256 _currentEpoch = block.timestamp / REWARDS_DURATION;
    uint256 _reminder = _currentEpoch % 17;

    UserInfo storage _info = userInfo[msg.sender];
    _info.totalLocked = uint112(_amount + uint256(_info.totalLocked)); // should never overflow
    _info.epochLocked[_reminder] = _amount + _info.epochLocked[_reminder]; // should never overflow

    // 4. update global info
    totalLockedGlobal = _amount.add(totalLockedGlobal); // direct cast shoule be safe

    emit Deposit(msg.sender, _amount);
  }

  /// @dev Unlock CVX from the CVXLockerV2
  ///      Notice that all pending unlocked CVX will not share future rewards.
  /// @param _amount The amount of CVX to unlock.
  function unlock(uint256 _amount) external override {
    require(_amount > 0, "CLeverCVXLocker: unlock zero CVX");
    // 1. update reward info
    _updateReward(msg.sender);

    // 2. update unlocked info
    _updateUnlocked(msg.sender);

    // 3. check unlock limit and update
    UserInfo storage _info = userInfo[msg.sender];
    {
      uint256 _totalLocked = _info.totalLocked;
      uint256 _totalDebt = _info.totalDebt;
      require(_amount <= _totalLocked, "CLeverCVXLocker: insufficient CVX to unlock");

      _checkAccountHealth(_totalLocked, _totalDebt, _amount, 0);
      // if you choose unlock, all pending unlocked CVX will not share the reward.
      _info.totalLocked = uint112(_totalLocked - _amount); // should never overflow
      // global unlock info will be updated in `processUnlockableCVX`
      totalLockedGlobal -= _amount;
      totalPendingUnlockGlobal += _amount;
    }

    emit Unlock(msg.sender, _amount);

    // 4. enumerate lockInfo array to unlock
    uint256 _nextEpoch = block.timestamp / REWARDS_DURATION + 1;
    EpochUnlockInfo[] storage _pendingUnlockList = _info.pendingUnlockList;
    uint256 _index;
    uint256 _locked;
    uint256 _unlocked;
    for (uint256 i = 0; i < 17; i++) {
      _index = _nextEpoch % 17;
      _locked = _info.epochLocked[_index];
      if (_amount >= _locked) _unlocked = _locked;
      else _unlocked = _amount;

      if (_unlocked > 0) {
        _info.epochLocked[_index] = _locked - _unlocked; // should never overflow
        _amount = _amount - _unlocked; // should never overflow
        pendingUnlocked[_nextEpoch] = pendingUnlocked[_nextEpoch] + _unlocked; // should never overflow

        if (
          _pendingUnlockList.length == 0 || _pendingUnlockList[_pendingUnlockList.length - 1].unlockEpoch != _nextEpoch
        ) {
          _pendingUnlockList.push(
            EpochUnlockInfo({ pendingUnlock: uint192(_unlocked), unlockEpoch: uint64(_nextEpoch) })
          );
        } else {
          _pendingUnlockList[_pendingUnlockList.length - 1].pendingUnlock = uint192(
            _unlocked + _pendingUnlockList[_pendingUnlockList.length - 1].pendingUnlock
          );
        }
      }

      if (_amount == 0) break;
      _nextEpoch = _nextEpoch + 1;
    }
  }

  /// @dev Withdraw all unlocked CVX from this contract.
  function withdrawUnlocked() external override {
    // 1. update reward info
    _updateReward(msg.sender);

    // 2. update unlocked info
    _updateUnlocked(msg.sender);

    // 3. claim unlocked CVX
    UserInfo storage _info = userInfo[msg.sender];
    uint256 _unlocked = _info.totalUnlocked;
    _info.totalUnlocked = 0;

    // update global info
    totalUnlockedGlobal = totalUnlockedGlobal.sub(_unlocked);

    uint256 _balanceInContract = IERC20Upgradeable(CVX).balanceOf(address(this));
    // balance is not enough, with from reward pool
    if (_balanceInContract < _unlocked) {
      IConvexCVXRewardPool(CVX_REWARD_POOL).withdraw(_unlocked - _balanceInContract, false);
    }

    IERC20Upgradeable(CVX).safeTransfer(msg.sender, _unlocked);

    emit Withdraw(msg.sender, _unlocked);
  }

  /// @dev Repay clevCVX debt with CVX or clevCVX.
  /// @param _cvxAmount The amount of CVX used to pay debt.
  /// @param _clevCVXAmount The amount of clevCVX used to pay debt.
  function repay(uint256 _cvxAmount, uint256 _clevCVXAmount) external override {
    require(_cvxAmount > 0 || _clevCVXAmount > 0, "CLeverCVXLocker: repay zero amount");

    // 1. update reward info
    _updateReward(msg.sender);

    UserInfo storage _info = userInfo[msg.sender];
    uint256 _totalDebt = _info.totalDebt;
    uint256 _totalDebtGlobal = totalDebtGlobal;

    // 3. check repay with cvx and take fee
    if (_cvxAmount > 0 && _totalDebt > 0) {
      if (_cvxAmount > _totalDebt) _cvxAmount = _totalDebt;
      uint256 _fee = _cvxAmount.mul(repayFeePercentage) / FEE_DENOMINATOR;
      _totalDebt = _totalDebt - _cvxAmount; // never overflow
      _totalDebtGlobal = _totalDebtGlobal - _cvxAmount; // never overflow

      // distribute to furnace and transfer fee to platform
      IERC20Upgradeable(CVX).safeTransferFrom(msg.sender, address(this), _cvxAmount + _fee);
      if (_fee > 0) {
        IERC20Upgradeable(CVX).safeTransfer(platform, _fee);
      }
      address _furnace = furnace;
      IERC20Upgradeable(CVX).safeApprove(_furnace, 0);
      IERC20Upgradeable(CVX).safeApprove(_furnace, _cvxAmount);
      IFurnace(_furnace).distribute(address(this), _cvxAmount);
    }

    // 4. check repay with clevCVX
    if (_clevCVXAmount > 0 && _totalDebt > 0) {
      if (_clevCVXAmount > _totalDebt) _clevCVXAmount = _totalDebt;
      uint256 _fee = _clevCVXAmount.mul(repayFeePercentage) / FEE_DENOMINATOR;
      _totalDebt = _totalDebt - _clevCVXAmount; // never overflow
      _totalDebtGlobal = _totalDebtGlobal - _clevCVXAmount;

      // burn debt token and tranfer fee to platform
      if (_fee > 0) {
        IERC20Upgradeable(clevCVX).safeTransferFrom(msg.sender, platform, _fee);
      }
      ICLeverToken(clevCVX).burnFrom(msg.sender, _clevCVXAmount);
    }

    _info.totalDebt = uint128(_totalDebt);
    totalDebtGlobal = _totalDebtGlobal;

    emit Repay(msg.sender, _cvxAmount, _clevCVXAmount);
  }

  /// @dev Borrow clevCVX from this contract.
  ///      Notice the reward will be used first and it will not be treated as debt.
  /// @param _amount The amount of clevCVX to borrow.
  /// @param _depositToFurnace Whether to deposit borrowed clevCVX to furnace.
  function borrow(uint256 _amount, bool _depositToFurnace) external override {
    require(_amount > 0, "CLeverCVXLocker: borrow zero amount");

    // 1. update reward info
    _updateReward(msg.sender);

    UserInfo storage _info = userInfo[msg.sender];
    uint256 _rewards = _info.rewards;
    uint256 _borrowWithLocked;

    // 2. borrow with rewards, this will not be treated as debt.
    if (_rewards >= _amount) {
      _info.rewards = uint128(_rewards - _amount);
    } else {
      _info.rewards = 0;
      _borrowWithLocked = _amount - _rewards;
    }

    // 3. borrow with locked CVX
    if (_borrowWithLocked > 0) {
      uint256 _totalLocked = _info.totalLocked;
      uint256 _totalDebt = _info.totalDebt;
      _checkAccountHealth(_totalLocked, _totalDebt, 0, _borrowWithLocked);
      // update user info
      _info.totalDebt = uint128(_totalDebt + _borrowWithLocked); // should not overflow.
      // update global info
      totalDebtGlobal = totalDebtGlobal + _borrowWithLocked; // should not overflow.
    }

    _mintOrDeposit(_amount, _depositToFurnace);

    emit Borrow(msg.sender, _amount);
  }

  /// @dev Someone donate CVX to all CVX locker in this contract.
  /// @param _amount The amount of CVX to donate.
  function donate(uint256 _amount) external override {
    require(_amount > 0, "CLeverCVXLocker: donate zero amount");
    IERC20Upgradeable(CVX).safeTransferFrom(msg.sender, address(this), _amount);

    _distribute(_amount);
  }

  /// @dev Harvest pending reward from CVXLockerV2 and CVXRewardPool, then swap it to CVX.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of CVX should get.
  /// @return The amount of CVX harvested.
  function harvest(address _recipient, uint256 _minimumOut) external override returns (uint256) {
    // 1. harvest from CVXLockerV2 and CVXRewardPool
    IConvexCVXRewardPool(CVX_REWARD_POOL).getReward(false);
    IConvexCVXLocker(CVX_LOCKER).getReward(address(this));

    // 2. convert all CVXCRV to CVX
    uint256 _amount = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
    if (_amount > 0) {
      IERC20Upgradeable(CVXCRV).safeTransfer(zap, _amount);
      _amount = IZap(zap).zap(CVXCRV, _amount, CVX, _minimumOut);
    }
    require(_amount >= _minimumOut, "CLeverCVXLocker: insufficient output");

    // 3. distribute incentive to platform and _recipient
    uint256 _platformFee = platformFeePercentage;
    uint256 _distributeAmount = _amount;
    if (_platformFee > 0) {
      _platformFee = (_distributeAmount * _platformFee) / FEE_DENOMINATOR;
      _distributeAmount = _distributeAmount - _platformFee;
      IERC20Upgradeable(CVX).safeTransfer(platform, _platformFee);
    }
    uint256 _harvestBounty = harvestBountyPercentage;
    if (_harvestBounty > 0) {
      _harvestBounty = (_distributeAmount * _harvestBounty) / FEE_DENOMINATOR;
      _distributeAmount = _distributeAmount - _harvestBounty;
      IERC20Upgradeable(CVX).safeTransfer(_recipient, _harvestBounty);
    }

    // 4. distribute to users
    _distribute(_distributeAmount);

    emit Harvest(msg.sender, _distributeAmount, _platformFee, _harvestBounty);

    return _amount;
  }

  /// @dev Harvest pending reward from Votium, then swap it to CVX.
  /// @param claims The parameters used by VotiumMultiMerkleStash contract.
  /// @param _minimumOut - The minimum amount of CVX should get.
  /// @return The amount of CVX harvested.
  function harvestVotium(IVotiumMultiMerkleStash.claimParam[] calldata claims, uint256 _minimumOut)
    external
    override
    onlyKeeper
    returns (uint256)
  {
    // 1. claim reward from votium
    for (uint256 i = 0; i < claims.length; i++) {
      // in case someone has claimed the reward for this contract, we can still call this function to process reward.
      if (!IVotiumMultiMerkleStash(VOTIUM_DISTRIBUTOR).isClaimed(claims[i].token, claims[i].index)) {
        IVotiumMultiMerkleStash(VOTIUM_DISTRIBUTOR).claim(
          claims[i].token,
          claims[i].index,
          address(this),
          claims[i].amount,
          claims[i].merkleProof
        );
      }
    }
    address[] memory _rewardTokens = new address[](claims.length);
    uint256[] memory _amounts = new uint256[](claims.length);
    for (uint256 i = 0; i < claims.length; i++) {
      _rewardTokens[i] = claims[i].token;
      // TODO: consider fee on transfer token (currently, such token doesn't exsist)
      _amounts[i] = claims[i].amount;
    }

    // 2. swap all tokens to CVX
    uint256 _amount = _swapToCVX(_rewardTokens, _amounts, _minimumOut);

    // 3. distribute to platform
    uint256 _distributeAmount = _amount;
    uint256 _platformFee = platformFeePercentage;
    if (_platformFee > 0) {
      _platformFee = (_distributeAmount * _platformFee) / FEE_DENOMINATOR;
      _distributeAmount = _distributeAmount - _platformFee;
      IERC20Upgradeable(CVX).safeTransfer(platform, _platformFee);
    }

    // 4. distribute to users
    _distribute(_distributeAmount);

    emit Harvest(msg.sender, _distributeAmount, _platformFee, 0);

    return _amount;
  }

  /// @dev Process unlocked CVX in CVXLockerV2.
  ///
  /// This function should be called every week if
  ///   1. `pendingUnlocked[currentEpoch]` is nonzero.
  ///   2. some CVX is unlocked in current epoch.
  function processUnlockableCVX() external onlyKeeper {
    // Be careful that someone may kick us out from CVXLockerV2
    // `totalUnlockedGlobal` keep track the amount of CVX unlocked from CVXLockerV2
    // all other CVX in this contract can be considered unlocked from CVXLockerV2 by someone else.

    // 1. find extra CVX from donation or kicked out from CVXLockerV2
    uint256 _extraCVX = totalCVXInPool().sub(totalUnlockedGlobal);

    // 2. unlock CVX
    uint256 _unlocked = IERC20Upgradeable(CVX).balanceOf(address(this));
    IConvexCVXLocker(CVX_LOCKER).processExpiredLocks(false);
    _unlocked = IERC20Upgradeable(CVX).balanceOf(address(this)).sub(_unlocked).add(_extraCVX);

    // 3. remove user unlocked CVX
    uint256 currentEpoch = block.timestamp / REWARDS_DURATION;
    uint256 _pending = pendingUnlocked[currentEpoch];
    if (_pending > 0) {
      // check if the unlocked CVX is enough, normally this should always be true.
      require(_unlocked >= _pending, "CLeverCVXLocker: insufficient unlocked CVX");
      _unlocked -= _pending;
      // update global info
      totalUnlockedGlobal = totalUnlockedGlobal.add(_pending);
      totalPendingUnlockGlobal -= _pending; // should never overflow
      pendingUnlocked[currentEpoch] = 0;
    }

    // 4. relock
    if (_unlocked > 0) {
      IERC20Upgradeable(CVX).safeApprove(CVX_LOCKER, 0);
      IERC20Upgradeable(CVX).safeApprove(CVX_LOCKER, _unlocked);
      IConvexCVXLocker(CVX_LOCKER).lock(address(this), _unlocked, 0);
    }
  }

  /********************************** Restricted Functions **********************************/

  /// @dev delegate vlCVX voting power.
  /// @param _registry The address of Snapshot Delegate Registry.
  /// @param _id The id for which the delegate should be set.
  /// @param _delegate The address of the delegate.
  function delegate(
    address _registry,
    bytes32 _id,
    address _delegate
  ) external onlyGovernorOrOwner {
    ISnapshotDelegateRegistry(_registry).setDelegate(_id, _delegate);
  }

  /// @dev Update the address of governor.
  /// @param _governor The address to be updated
  function updateGovernor(address _governor) external onlyGovernorOrOwner {
    require(_governor != address(0), "CLeverCVXLocker: zero governor address");
    governor = _governor;

    emit UpdateGovernor(_governor);
  }

  /// @dev Update stake percentage for CVX in this contract.
  /// @param _percentage The stake percentage to be updated, multipled by 1e9.
  function updateStakePercentage(uint256 _percentage) external onlyGovernorOrOwner {
    require(_percentage <= FEE_DENOMINATOR, "CLeverCVXLocker: percentage too large");
    stakePercentage = _percentage;

    emit UpdateStakePercentage(_percentage);
  }

  /// @dev Update stake threshold for CVX.
  /// @param _threshold The stake threshold to be updated.
  function updateStakeThreshold(uint256 _threshold) external onlyGovernorOrOwner {
    stakeThreshold = _threshold;

    emit UpdateStakeThreshold(_threshold);
  }

  /// @dev Update manual swap reward token lists.
  /// @param _tokens The addresses of token list.
  /// @param _status The status to be updated.
  function updateManualSwapRewardToken(address[] memory _tokens, bool _status) external onlyGovernorOrOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      require(_tokens[i] != CVX, "CLeverCVXLocker: invalid token");
      manualSwapRewardToken[_tokens[i]] = _status;
    }
  }

  /// @dev Update the repay fee percentage.
  /// @param _feePercentage - The fee percentage to update.
  function updateRepayFeePercentage(uint256 _feePercentage) external onlyOwner {
    require(_feePercentage <= MAX_REPAY_FEE, "AladdinCRV: fee too large");
    repayFeePercentage = _feePercentage;

    emit UpdateRepayFeePercentage(_feePercentage);
  }

  /// @dev Update the platform fee percentage.
  /// @param _feePercentage - The fee percentage to update.
  function updatePlatformFeePercentage(uint256 _feePercentage) external onlyOwner {
    require(_feePercentage <= MAX_PLATFORM_FEE, "AladdinCRV: fee too large");
    platformFeePercentage = _feePercentage;

    emit UpdatePlatformFeePercentage(_feePercentage);
  }

  /// @dev Update the harvest bounty percentage.
  /// @param _percentage - The fee percentage to update.
  function updateHarvestBountyPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= MAX_HARVEST_BOUNTY, "AladdinCRV: fee too large");
    harvestBountyPercentage = _percentage;

    emit UpdateHarvestBountyPercentage(_percentage);
  }

  /// @dev Update the recipient
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "AladdinCRV: zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @dev Update the zap contract
  function updateZap(address _zap) external onlyGovernorOrOwner {
    require(_zap != address(0), "CLeverCVXLocker: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  function updateReserveRate(uint256 _reserveRate) external onlyOwner {
    require(_reserveRate <= FEE_DENOMINATOR, "CLeverCVXLocker: invalid reserve rate");
    reserveRate = _reserveRate;
  }

  /// @dev Withdraw all manual swap reward tokens from the contract.
  /// @param _tokens The address list of tokens to withdraw.
  /// @param _recipient The address of user who will recieve the tokens.
  function withdrawManualSwapRewardTokens(address[] memory _tokens, address _recipient) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (!manualSwapRewardToken[_tokens[i]]) continue;
      uint256 _balance = IERC20Upgradeable(_tokens[i]).balanceOf(address(this));
      IERC20Upgradeable(_tokens[i]).safeTransfer(_recipient, _balance);
    }
  }

  /// @dev Update keepers.
  /// @param _accounts The address list of keepers to update.
  /// @param _status The status of updated keepers.
  function updateKeepers(address[] memory _accounts, bool _status) external onlyGovernorOrOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      isKeeper[_accounts[i]] = _status;
    }
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function called by `deposit`, `unlock`, `withdrawUnlocked`, `repay`, `borrow` and `claim`.
  /// @param _account The address of account to update reward info.
  function _updateReward(address _account) internal {
    UserInfo storage _info = userInfo[_account];
    require(_info.lastInteractedBlock != block.number, "CLeverCVXLocker: enter the same block");

    uint256 _totalDebtGlobal = totalDebtGlobal;
    uint256 _totalDebt = _info.totalDebt;
    uint256 _rewards = uint256(_info.rewards).add(
      accRewardPerShare.sub(_info.rewardPerSharePaid).mul(_info.totalLocked) / PRECISION
    );

    _info.rewardPerSharePaid = uint192(accRewardPerShare); // direct cast should be safe
    _info.lastInteractedBlock = uint64(block.number);

    // pay debt with reward if possible
    if (_totalDebt > 0) {
      if (_rewards >= _totalDebt) {
        _rewards -= _totalDebt;
        _totalDebtGlobal -= _totalDebt;
        _totalDebt = 0;
      } else {
        _totalDebtGlobal -= _rewards;
        _totalDebt -= _rewards;
        _rewards = 0;
      }
    }

    _info.totalDebt = uint128(_totalDebt); // direct cast should be safe
    _info.rewards = uint128(_rewards); // direct cast should be safe
    totalDebtGlobal = _totalDebtGlobal;
  }

  /// @dev Internal function called by `unlock`, `withdrawUnlocked`.
  /// @param _account The address of account to update pending unlock list.
  function _updateUnlocked(address _account) internal {
    UserInfo storage _info = userInfo[_account];
    uint256 _currentEpoch = block.timestamp / REWARDS_DURATION;
    uint256 _nextUnlockIndex = _info.nextUnlockIndex;
    uint256 _totalUnlocked = _info.totalUnlocked;
    EpochUnlockInfo[] storage _pendingUnlockList = _info.pendingUnlockList;

    uint256 _unlockEpoch;
    uint256 _unlockAmount;
    while (_nextUnlockIndex < _pendingUnlockList.length) {
      _unlockEpoch = _pendingUnlockList[_nextUnlockIndex].unlockEpoch;
      _unlockAmount = _pendingUnlockList[_nextUnlockIndex].pendingUnlock;
      if (_unlockEpoch <= _currentEpoch) {
        _totalUnlocked = _totalUnlocked + _unlockAmount;
        delete _pendingUnlockList[_nextUnlockIndex]; // clear entry to refund gas
      } else {
        break;
      }
      _nextUnlockIndex += 1;
    }
    _info.totalUnlocked = uint112(_totalUnlocked);
    _info.nextUnlockIndex = uint32(_nextUnlockIndex);
  }

  /// @dev Internal function used to swap tokens to CVX.
  /// @param _rewardTokens The address list of reward tokens.
  /// @param _amounts The amount list of reward tokens.
  /// @param _minimumOut The minimum amount of CVX should get.
  /// @return The amount of CVX swapped.
  function _swapToCVX(
    address[] memory _rewardTokens,
    uint256[] memory _amounts,
    uint256 _minimumOut
  ) internal returns (uint256) {
    uint256 _amount;
    address _token;
    address _zap = zap;
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      _token = _rewardTokens[i];
      // skip manual swap token
      if (manualSwapRewardToken[_token]) continue;
      if (_token != CVX) {
        if (_amounts[i] > 0) {
          IERC20Upgradeable(_token).safeTransfer(_zap, _amounts[i]);
          _amount = _amount.add(IZap(_zap).zap(_token, _amounts[i], CVX, 0));
        }
      } else {
        _amount = _amount.add(_amounts[i]);
      }
    }
    require(_amount >= _minimumOut, "CLeverCVXLocker: insufficient output");
    return _amount;
  }

  /// @dev Internal function called by `harvest` and `harvestVotium`.
  function _distribute(uint256 _amount) internal {
    // 1. update reward info
    uint256 _totalLockedGlobal = totalLockedGlobal; // gas saving
    // It's ok to donate when on one is locking in this contract.
    if (_totalLockedGlobal > 0) {
      accRewardPerShare = accRewardPerShare.add(_amount.mul(PRECISION) / uint256(_totalLockedGlobal));
    }

    // 2. distribute reward CVX to Furnace
    address _furnace = furnace;
    IERC20Upgradeable(CVX).safeApprove(_furnace, 0);
    IERC20Upgradeable(CVX).safeApprove(_furnace, _amount);
    IFurnace(_furnace).distribute(address(this), _amount);

    // 3. stake extra CVX to cvxRewardPool
    uint256 _balanceStaked = IConvexCVXRewardPool(CVX_REWARD_POOL).balanceOf(address(this));
    uint256 _toStake = _balanceStaked.add(IERC20Upgradeable(CVX).balanceOf(address(this))).mul(stakePercentage).div(
      FEE_DENOMINATOR
    );
    if (_balanceStaked < _toStake) {
      _toStake = _toStake - _balanceStaked;
      if (_toStake >= stakeThreshold) {
        IERC20Upgradeable(CVX).safeApprove(CVX_REWARD_POOL, 0);
        IERC20Upgradeable(CVX).safeApprove(CVX_REWARD_POOL, _toStake);
        IConvexCVXRewardPool(CVX_REWARD_POOL).stake(_toStake);
      }
    }
  }

  /// @dev Internal function used to help to mint clevCVX.
  /// @param _amount The amount of clevCVX to mint.
  /// @param _depositToFurnace Whether to deposit the minted clevCVX to furnace.
  function _mintOrDeposit(uint256 _amount, bool _depositToFurnace) internal {
    if (_depositToFurnace) {
      address _clevCVX = clevCVX;
      address _furnace = furnace;
      // stake clevCVX to furnace.
      ICLeverToken(_clevCVX).mint(address(this), _amount);
      IERC20Upgradeable(_clevCVX).safeApprove(_furnace, 0);
      IERC20Upgradeable(_clevCVX).safeApprove(_furnace, _amount);
      IFurnace(_furnace).depositFor(msg.sender, _amount);
    } else {
      // transfer clevCVX to sender.
      ICLeverToken(clevCVX).mint(msg.sender, _amount);
    }
  }

  /// @dev Internal function to check the health of account.
  ///      And account is health if and only if
  ///                                       cvxBorrowed
  ///                      cvxDeposited >= --------------
  ///                                      cvxReserveRate
  /// @param _totalDeposited The amount of CVX currently deposited.
  /// @param _totalDebt The amount of clevCVX currently borrowed.
  /// @param _newUnlock The amount of CVX to unlock.
  /// @param _newBorrow The amount of clevCVX to borrow.
  function _checkAccountHealth(
    uint256 _totalDeposited,
    uint256 _totalDebt,
    uint256 _newUnlock,
    uint256 _newBorrow
  ) internal view {
    require(
      _totalDeposited.sub(_newUnlock).mul(reserveRate) >= _totalDebt.add(_newBorrow).mul(FEE_DENOMINATOR),
      "CLeverCVXLocker: unlock or borrow exceeds limit"
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IVotiumMultiMerkleStash.sol";

interface ICLeverCVXLocker {
  event Deposit(address indexed _account, uint256 _amount);
  event Unlock(address indexed _account, uint256 _amount);
  event Withdraw(address indexed _account, uint256 _amount);
  event Repay(address indexed _account, uint256 _cvxAmount, uint256 _clevCVXAmount);
  event Borrow(address indexed _account, uint256 _amount);
  event Claim(address indexed _account, uint256 _amount);
  event Harvest(address indexed _caller, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);

  function getUserInfo(address _account)
    external
    view
    returns (
      uint256 totalDeposited,
      uint256 totalPendingUnlocked,
      uint256 totalUnlocked,
      uint256 totalBorrowed,
      uint256 totalReward
    );

  function deposit(uint256 _amount) external;

  function unlock(uint256 _amount) external;

  function withdrawUnlocked() external;

  function repay(uint256 _cvxAmount, uint256 _clevCVXAmount) external;

  function borrow(uint256 _amount, bool _depositToFurnace) external;

  function donate(uint256 _amount) external;

  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256);

  function harvestVotium(IVotiumMultiMerkleStash.claimParam[] calldata claims, uint256 _minimumOut)
    external
    returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICLeverToken is IERC20 {
  function mint(address _recipient, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function burnFrom(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IConvexCVXLocker {
  struct LockedBalance {
    uint112 amount;
    uint112 boosted;
    uint32 unlockTime;
  }

  function lockedBalanceOf(address _user) external view returns (uint256 amount);

  // Information on a user's locked balances
  function lockedBalances(address _user)
    external
    view
    returns (
      uint256 total,
      uint256 unlockable,
      uint256 locked,
      LockedBalance[] memory lockData
    );

  function lock(
    address _account,
    uint256 _amount,
    uint256 _spendRatio
  ) external;

  function processExpiredLocks(
    bool _relock,
    uint256 _spendRatio,
    address _withdrawTo
  ) external;

  function processExpiredLocks(bool _relock) external;

  function kickExpiredLocks(address _account) external;

  function getReward(address _account, bool _stake) external;

  function getReward(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexCVXRewardPool {
  function balanceOf(address account) external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function withdraw(uint256 _amount, bool claim) external;

  function withdrawAll(bool claim) external;

  function stake(uint256 _amount) external;

  function stakeAll() external;

  function stakeFor(address _for, uint256 _amount) external;

  function getReward(
    address _account,
    bool _claimExtras,
    bool _stake
  ) external;

  function getReward(bool _stake) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IFurnace {
  event Deposit(address indexed _account, uint256 _amount);
  event Withdraw(address indexed _account, address _recipient, uint256 _amount);
  event Claim(address indexed _account, address _recipient, uint256 _amount);
  event Distribute(address indexed _origin, uint256 _amount);
  event Harvest(address indexed _caller, uint256 _amount);

  /// @dev Return the amount of clevCVX unrealised and realised of user.
  /// @param _account The address of user.
  /// @return unrealised The amount of clevCVX unrealised.
  /// @return realised The amount of clevCVX realised and can be claimed.
  function getUserInfo(address _account) external view returns (uint256 unrealised, uint256 realised);

  /// @dev Deposit clevCVX in this contract to change for CVX.
  /// @param _amount The amount of clevCVX to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Deposit clevCVX in this contract to change for CVX for other user.
  /// @param _account The address of user you deposit for.
  /// @param _amount The amount of clevCVX to deposit.
  function depositFor(address _account, uint256 _amount) external;

  /// @dev Withdraw unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  /// @param _amount The amount of clevCVX to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;

  /// @dev Withdraw all unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  function withdrawAll(address _recipient) external;

  /// @dev Claim all realised CVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the CVX.
  function claim(address _recipient) external;

  /// @dev Exit the contract, withdraw all unrealised clevCVX and realised CVX of the caller.
  /// @param _recipient The address of user who will recieve the clevCVX and CVX.
  function exit(address _recipient) external;

  /// @dev Distribute CVX from `origin` to pay clevCVX debt.
  /// @param _origin The address of the user who will provide CVX.
  /// @param _amount The amount of CVX will be provided.
  function distribute(address _origin, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ISnapshotDelegateRegistry {
  function setDelegate(bytes32 id, address delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IZap {
  function zap(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);
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
library SafeMathUpgradeable {
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

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IVotiumMultiMerkleStash {
  // solhint-disable-next-line contract-name-camelcase
  struct claimParam {
    address token;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function isClaimed(address token, uint256 index) external view returns (bool);

  function claim(
    address token,
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function claimMulti(address account, claimParam[] calldata claims) external;
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