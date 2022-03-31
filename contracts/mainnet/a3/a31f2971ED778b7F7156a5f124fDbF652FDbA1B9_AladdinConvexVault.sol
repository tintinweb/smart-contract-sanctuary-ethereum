// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IAladdinConvexVault.sol";
import "../interfaces/IAladdinCRV.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/IConvexBasicRewards.sol";
import "../interfaces/IConvexCRVDepositor.sol";
import "../interfaces/ICurveFactoryPlainPool.sol";
import "../interfaces/IZap.sol";

// solhint-disable no-empty-blocks, reason-string
contract AladdinConvexVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, IAladdinConvexVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct PoolInfo {
    // The amount of total deposited token.
    uint128 totalUnderlying;
    // The amount of total deposited shares.
    uint128 totalShare;
    // The accumulated acrv reward per share, with 1e18 precision.
    uint256 accRewardPerShare;
    // The pool id in Convex Booster.
    uint256 convexPoolId;
    // The address of deposited token.
    address lpToken;
    // The address of Convex reward contract.
    address crvRewards;
    // The withdraw fee percentage, with 1e9 precision.
    uint256 withdrawFeePercentage;
    // The platform fee percentage, with 1e9 precision.
    uint256 platformFeePercentage;
    // The harvest bounty percentage, with 1e9 precision.
    uint256 harvestBountyPercentage;
    // Whether deposit for the pool is paused.
    bool pauseDeposit;
    // Whether withdraw for the pool is paused.
    bool pauseWithdraw;
    // The list of addresses of convex reward tokens.
    address[] convexRewardTokens;
  }

  struct UserInfo {
    // The amount of shares the user deposited.
    uint128 shares;
    // The amount of current accrued rewards.
    uint128 rewards;
    // The reward per share already paid for the user, with 1e18 precision.
    uint256 rewardPerSharePaid;
  }

  uint256 private constant PRECISION = 1e18;
  uint256 private constant FEE_DENOMINATOR = 1e9;
  uint256 private constant MAX_WITHDRAW_FEE = 1e8; // 10%
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  // The address of cvxCRV token.
  address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
  // The address of CRV token.
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  // The address of WETH token.
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  // The address of Convex Booster Contract
  address private constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
  // The address of Curve cvxCRV/CRV Pool
  address private constant CURVE_CVXCRV_CRV_POOL = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;
  // The address of Convex CRV => cvxCRV Contract.
  address private constant CRV_DEPOSITOR = 0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;

  /// @dev The list of all supported pool.
  PoolInfo[] public poolInfo;
  /// @dev Mapping from pool id to account address to user share info.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @dev The address of AladdinCRV token.
  address public aladdinCRV;
  /// @dev The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /// @dev The address of recipient of platform fee
  address public platform;

  function initialize(
    address _aladdinCRV,
    address _zap,
    address _platform
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    require(_aladdinCRV != address(0), "AladdinConvexVault: zero acrv address");
    require(_zap != address(0), "AladdinConvexVault: zero zap address");
    require(_platform != address(0), "AladdinConvexVault: zero platform address");

    aladdinCRV = _aladdinCRV;
    zap = _zap;
    platform = _platform;
  }

  /********************************** View Functions **********************************/

  /// @notice Returns the number of pools.
  function poolLength() public view returns (uint256 pools) {
    pools = poolInfo.length;
  }

  /// @dev Return the amount of pending AladdinCRV rewards for specific pool.
  /// @param _pid - The pool id.
  /// @param _account - The address of user.
  function pendingReward(uint256 _pid, address _account) public view override returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    UserInfo storage _userInfo = userInfo[_pid][_account];
    return
      uint256(_userInfo.rewards).add(
        _pool.accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(_userInfo.shares) / PRECISION
      );
  }

  /// @dev Return the amount of pending AladdinCRV rewards for all pool.
  /// @param _account - The address of user.
  function pendingRewardAll(address _account) external view override returns (uint256) {
    uint256 _pending;
    for (uint256 i = 0; i < poolInfo.length; i++) {
      _pending += pendingReward(i, _account);
    }
    return _pending;
  }

  /********************************** Mutated Functions **********************************/

  /// @dev Deposit some token to specific pool.
  /// @param _pid - The pool id.
  /// @param _amount - The amount of token to deposit.
  /// @return share - The amount of share after deposit.
  function deposit(uint256 _pid, uint256 _amount) public override returns (uint256 share) {
    require(_amount > 0, "AladdinConvexVault: zero amount deposit");
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseDeposit, "AladdinConvexVault: pool paused");
    _updateRewards(_pid, msg.sender);

    // 2. transfer user token
    address _lpToken = _pool.lpToken;
    {
      uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
      IERC20Upgradeable(_lpToken).safeTransferFrom(msg.sender, address(this), _amount);
      _amount = IERC20Upgradeable(_lpToken).balanceOf(address(this)) - _before;
    }

    // 3. deposit
    return _deposit(_pid, _amount);
  }

  /// @dev Deposit all token of the caller to specific pool.
  /// @param _pid - The pool id.
  /// @return share - The amount of share after deposit.
  function depositAll(uint256 _pid) external override returns (uint256 share) {
    PoolInfo storage _pool = poolInfo[_pid];
    uint256 _balance = IERC20Upgradeable(_pool.lpToken).balanceOf(msg.sender);
    return deposit(_pid, _balance);
  }

  /// @dev Deposit some token to specific pool with zap.
  /// @param _pid - The pool id.
  /// @param _token - The address of token to deposit.
  /// @param _amount - The amount of token to deposit.
  /// @param _minAmount - The minimum amount of share to deposit.
  /// @return share - The amount of share after deposit.
  function zapAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) public payable override returns (uint256 share) {
    require(_amount > 0, "AladdinConvexVault: zero amount deposit");
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseDeposit, "AladdinConvexVault: pool paused");

    address _lpToken = _pool.lpToken;
    if (_lpToken == _token) {
      return deposit(_pid, _amount);
    }

    // 1. update rewards
    _updateRewards(_pid, msg.sender);

    // transfer token to zap contract.
    address _zap = zap;
    uint256 _before;
    if (_token != address(0)) {
      require(msg.value == 0, "AladdinConvexVault: nonzero msg.value");
      _before = IERC20Upgradeable(_token).balanceOf(_zap);
      IERC20Upgradeable(_token).safeTransferFrom(msg.sender, _zap, _amount);
      _amount = IERC20Upgradeable(_token).balanceOf(_zap) - _before;
    } else {
      require(msg.value == _amount, "AladdinConvexVault: invalid amount");
    }

    // zap token to lp token using zap contract.
    _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
    IZap(_zap).zap{ value: msg.value }(_token, _amount, _lpToken, _minAmount);
    _amount = IERC20Upgradeable(_lpToken).balanceOf(address(this)) - _before;

    share = _deposit(_pid, _amount);

    require(share >= _minAmount, "AladdinConvexVault: insufficient share");
    return share;
  }

  /// @dev Deposit all token to specific pool with zap.
  /// @param _pid - The pool id.
  /// @param _token - The address of token to deposit.
  /// @param _minAmount - The minimum amount of share to deposit.
  /// @return share - The amount of share after deposit.
  function zapAllAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _minAmount
  ) external payable override returns (uint256) {
    uint256 _balance = IERC20Upgradeable(_token).balanceOf(msg.sender);
    return zapAndDeposit(_pid, _token, _balance, _minAmount);
  }

  /// @dev Withdraw some token from specific pool and claim pending rewards.
  /// @param _pid - The pool id.
  /// @param _shares - The share of token want to withdraw.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (don't claim, as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return withdrawn - The amount of token sent to caller.
  /// @return claimed - The amount of reward sent to caller.
  function withdrawAndClaim(
    uint256 _pid,
    uint256 _shares,
    uint256 _minOut,
    ClaimOption _option
  ) public override nonReentrant returns (uint256 withdrawn, uint256 claimed) {
    require(_shares > 0, "AladdinConvexVault: zero share withdraw");
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "AladdinConvexVault: pool paused");
    _updateRewards(_pid, msg.sender);

    // 2. withdraw lp token
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    require(_shares <= _userInfo.shares, "AladdinConvexVault: shares not enough");

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _withdrawable;
    if (_shares == _totalShare) {
      // If user is last to withdraw, don't take withdraw fee.
      // And there may still have some pending rewards, we just simple ignore it now.
      // If we want the reward later, we can upgrade the contract.
      _withdrawable = _totalUnderlying;
    } else {
      // take withdraw fee here
      _withdrawable = _shares.mul(_totalUnderlying) / _totalShare;
      uint256 _fee = _withdrawable.mul(_pool.withdrawFeePercentage) / FEE_DENOMINATOR;
      _withdrawable = _withdrawable - _fee; // never overflow
    }

    _pool.totalShare = _toU128(_totalShare - _shares);
    _pool.totalUnderlying = _toU128(_totalUnderlying - _withdrawable);
    _userInfo.shares = _toU128(uint256(_userInfo.shares) - _shares);

    IConvexBasicRewards(_pool.crvRewards).withdrawAndUnwrap(_withdrawable, false);
    IERC20Upgradeable(_pool.lpToken).safeTransfer(msg.sender, _withdrawable);
    emit Withdraw(_pid, msg.sender, _shares);

    // 3. claim rewards
    if (_option == ClaimOption.None) {
      return (_withdrawable, 0);
    } else {
      uint256 _rewards = _userInfo.rewards;
      _userInfo.rewards = 0;

      emit Claim(msg.sender, _rewards, _option);
      _rewards = _claim(_rewards, _minOut, _option);

      return (_withdrawable, _rewards);
    }
  }

  /// @dev Withdraw all share of token from specific pool and claim pending rewards.
  /// @param _pid - The pool id.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return withdrawn - The amount of token sent to caller.
  /// @return claimed - The amount of reward sent to caller.
  function withdrawAllAndClaim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external override returns (uint256 withdrawn, uint256 claimed) {
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    return withdrawAndClaim(_pid, _userInfo.shares, _minOut, _option);
  }

  /// @dev Withdraw some token from specific pool and zap to token.
  /// @param _pid - The pool id.
  /// @param _shares - The share of token want to withdraw.
  /// @param _token - The address of token zapping to.
  /// @param _minOut - The minimum amount of token to receive.
  /// @return withdrawn - The amount of token sent to caller.
  function withdrawAndZap(
    uint256 _pid,
    uint256 _shares,
    address _token,
    uint256 _minOut
  ) public override nonReentrant returns (uint256 withdrawn) {
    require(_shares > 0, "AladdinConvexVault: zero share withdraw");
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "AladdinConvexVault: pool paused");
    _updateRewards(_pid, msg.sender);

    // 2. withdraw and zap
    address _lpToken = _pool.lpToken;
    if (_token == _lpToken) {
      return _withdraw(_pid, _shares, msg.sender);
    } else {
      address _zap = zap;
      // withdraw to zap contract
      uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(_zap);
      _withdraw(_pid, _shares, _zap);
      uint256 _amount = IERC20Upgradeable(_lpToken).balanceOf(_zap) - _before;

      // zap to desired token
      if (_token == address(0)) {
        _before = address(this).balance;
        IZap(_zap).zap(_lpToken, _amount, _token, _minOut);
        _amount = address(this).balance - _before;
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = msg.sender.call{ value: _amount }("");
        require(_success, "AladdinConvexVault: transfer failed");
      } else {
        _before = IERC20Upgradeable(_token).balanceOf(address(this));
        IZap(_zap).zap(_lpToken, _amount, _token, _minOut);
        _amount = IERC20Upgradeable(_token).balanceOf(address(this)) - _before;
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
      }
      return _amount;
    }
  }

  /// @dev Withdraw all token from specific pool and zap to token.
  /// @param _pid - The pool id.
  /// @param _token - The address of token zapping to.
  /// @param _minOut - The minimum amount of token to receive.
  /// @return withdrawn - The amount of token sent to caller.
  function withdrawAllAndZap(
    uint256 _pid,
    address _token,
    uint256 _minOut
  ) external override returns (uint256 withdrawn) {
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    return withdrawAndZap(_pid, _userInfo.shares, _token, _minOut);
  }

  /// @dev claim pending rewards from specific pool.
  /// @param _pid - The pool id.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return claimed - The amount of reward sent to caller.
  function claim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) public override nonReentrant returns (uint256 claimed) {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.pauseWithdraw, "AladdinConvexVault: pool paused");
    _updateRewards(_pid, msg.sender);

    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    uint256 _rewards = _userInfo.rewards;
    _userInfo.rewards = 0;

    emit Claim(msg.sender, _rewards, _option);
    _rewards = _claim(_rewards, _minOut, _option);
    return _rewards;
  }

  /// @dev claim pending rewards from all pools.
  /// @param _minOut - The minimum amount of pending reward to receive.
  /// @param _option - The claim option (as aCRV, cvxCRV, CRV, CVX, or ETH)
  /// @return claimed - The amount of reward sent to caller.
  function claimAll(uint256 _minOut, ClaimOption _option) external override nonReentrant returns (uint256 claimed) {
    uint256 _rewards;
    for (uint256 _pid = 0; _pid < poolInfo.length; _pid++) {
      if (poolInfo[_pid].pauseWithdraw) continue; // skip paused pool

      UserInfo storage _userInfo = userInfo[_pid][msg.sender];
      // update if user has share
      if (_userInfo.shares > 0) {
        _updateRewards(_pid, msg.sender);
      }
      // withdraw if user has reward
      if (_userInfo.rewards > 0) {
        _rewards = _rewards.add(_userInfo.rewards);
        _userInfo.rewards = 0;
      }
    }

    emit Claim(msg.sender, _rewards, _option);
    _rewards = _claim(_rewards, _minOut, _option);
    return _rewards;
  }

  /// @dev Harvest the pending reward and convert to aCRV.
  /// @param _pid - The pool id.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of cvxCRV should get.
  /// @return harvested - The amount of cvxCRV harvested after zapping all other tokens to it.
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minimumOut
  ) external override nonReentrant returns (uint256 harvested) {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    PoolInfo storage _pool = poolInfo[_pid];
    // 1. claim rewards
    IConvexBasicRewards(_pool.crvRewards).getReward();

    // 2. swap all rewards token to CRV
    address[] memory _rewardsToken = _pool.convexRewardTokens;
    uint256 _amount = address(this).balance;
    address _token;
    address _zap = zap;
    for (uint256 i = 0; i < _rewardsToken.length; i++) {
      _token = _rewardsToken[i];
      if (_token != CRV) {
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
        if (_balance > 0) {
          // saving gas
          IERC20Upgradeable(_token).safeTransfer(_zap, _balance);
          _amount = _amount.add(IZap(_zap).zap(_token, _balance, address(0), 0));
        }
      }
    }
    if (_amount > 0) {
      IZap(_zap).zap{ value: _amount }(address(0), _amount, CRV, 0);
    }
    _amount = IERC20Upgradeable(CRV).balanceOf(address(this));
    _amount = _swapCRVToCvxCRV(_amount, _minimumOut);

    _token = aladdinCRV; // gas saving
    _approve(CVXCRV, _token, _amount);
    uint256 _rewards = IAladdinCRV(_token).deposit(address(this), _amount);

    // 3. distribute rewards to platform and _recipient
    uint256 _platformFee = _pool.platformFeePercentage;
    uint256 _harvestBounty = _pool.harvestBountyPercentage;
    if (_platformFee > 0) {
      _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
      _rewards = _rewards - _platformFee;
      IERC20Upgradeable(_token).safeTransfer(platform, _platformFee);
    }
    if (_harvestBounty > 0) {
      _harvestBounty = (_harvestBounty * _rewards) / FEE_DENOMINATOR;
      _rewards = _rewards - _harvestBounty;
      IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounty);
    }

    // 4. update rewards info
    _pool.accRewardPerShare = _pool.accRewardPerShare.add(_rewards.mul(PRECISION) / _pool.totalShare);

    emit Harvest(msg.sender, _rewards, _platformFee, _harvestBounty);

    return _amount;
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the withdraw fee percentage.
  /// @param _pid - The pool id.
  /// @param _feePercentage - The fee percentage to update.
  function updateWithdrawFeePercentage(uint256 _pid, uint256 _feePercentage) external onlyOwner {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");
    require(_feePercentage <= MAX_WITHDRAW_FEE, "AladdinConvexVault: fee too large");

    poolInfo[_pid].withdrawFeePercentage = _feePercentage;

    emit UpdateWithdrawalFeePercentage(_pid, _feePercentage);
  }

  /// @dev Update the platform fee percentage.
  /// @param _pid - The pool id.
  /// @param _feePercentage - The fee percentage to update.
  function updatePlatformFeePercentage(uint256 _pid, uint256 _feePercentage) external onlyOwner {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");
    require(_feePercentage <= MAX_PLATFORM_FEE, "AladdinConvexVault: fee too large");

    poolInfo[_pid].platformFeePercentage = _feePercentage;

    emit UpdatePlatformFeePercentage(_pid, _feePercentage);
  }

  /// @dev Update the harvest bounty percentage.
  /// @param _pid - The pool id.
  /// @param _percentage - The fee percentage to update.
  function updateHarvestBountyPercentage(uint256 _pid, uint256 _percentage) external onlyOwner {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");
    require(_percentage <= MAX_HARVEST_BOUNTY, "AladdinConvexVault: fee too large");

    poolInfo[_pid].harvestBountyPercentage = _percentage;

    emit UpdateHarvestBountyPercentage(_pid, _percentage);
  }

  /// @dev Update the recipient
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "AladdinConvexVault: zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @dev Update the zap contract
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "AladdinConvexVault: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @dev Add new Convex pool.
  /// @param _convexPid - The Convex pool id.
  /// @param _rewardTokens - The list of addresses of reward tokens.
  /// @param _withdrawFeePercentage - The withdraw fee percentage of the pool.
  /// @param _platformFeePercentage - The platform fee percentage of the pool.
  /// @param _harvestBountyPercentage - The harvest bounty percentage of the pool.
  function addPool(
    uint256 _convexPid,
    address[] memory _rewardTokens,
    uint256 _withdrawFeePercentage,
    uint256 _platformFeePercentage,
    uint256 _harvestBountyPercentage
  ) external onlyOwner {
    for (uint256 i = 0; i < poolInfo.length; i++) {
      require(poolInfo[i].convexPoolId != _convexPid, "AladdinConvexVault: duplicate pool");
    }

    require(_withdrawFeePercentage <= MAX_WITHDRAW_FEE, "AladdinConvexVault: fee too large");
    require(_platformFeePercentage <= MAX_PLATFORM_FEE, "AladdinConvexVault: fee too large");
    require(_harvestBountyPercentage <= MAX_HARVEST_BOUNTY, "AladdinConvexVault: fee too large");

    IConvexBooster.PoolInfo memory _info = IConvexBooster(BOOSTER).poolInfo(_convexPid);
    poolInfo.push(
      PoolInfo({
        totalUnderlying: 0,
        totalShare: 0,
        accRewardPerShare: 0,
        convexPoolId: _convexPid,
        lpToken: _info.lptoken,
        crvRewards: _info.crvRewards,
        withdrawFeePercentage: _withdrawFeePercentage,
        platformFeePercentage: _platformFeePercentage,
        harvestBountyPercentage: _harvestBountyPercentage,
        pauseDeposit: false,
        pauseWithdraw: false,
        convexRewardTokens: _rewardTokens
      })
    );

    emit AddPool(poolInfo.length - 1, _convexPid, _rewardTokens);
  }

  /// @dev update reward tokens
  /// @param _pid - The pool id.
  /// @param _rewardTokens - The address list of new reward tokens.
  function updatePoolRewardTokens(uint256 _pid, address[] memory _rewardTokens) external onlyOwner {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    delete poolInfo[_pid].convexRewardTokens;
    poolInfo[_pid].convexRewardTokens = _rewardTokens;

    emit UpdatePoolRewardTokens(_pid, _rewardTokens);
  }

  /// @dev Pause withdraw for specific pool.
  /// @param _pid - The pool id.
  /// @param _status - The status to update.
  function pausePoolWithdraw(uint256 _pid, bool _status) external onlyOwner {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    poolInfo[_pid].pauseWithdraw = _status;

    emit PausePoolWithdraw(_pid, _status);
  }

  /// @dev Pause deposit for specific pool.
  /// @param _pid - The pool id.
  /// @param _status - The status to update.
  function pausePoolDeposit(uint256 _pid, bool _status) external onlyOwner {
    require(_pid < poolInfo.length, "AladdinConvexVault: invalid pool");

    poolInfo[_pid].pauseDeposit = _status;

    emit PausePoolDeposit(_pid, _status);
  }

  /********************************** Internal Functions **********************************/

  function _updateRewards(uint256 _pid, address _account) internal {
    uint256 _rewards = pendingReward(_pid, _account);
    PoolInfo storage _pool = poolInfo[_pid];
    UserInfo storage _userInfo = userInfo[_pid][_account];

    _userInfo.rewards = _toU128(_rewards);
    _userInfo.rewardPerSharePaid = _pool.accRewardPerShare;
  }

  function _deposit(uint256 _pid, uint256 _amount) internal nonReentrant returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    _approve(_pool.lpToken, BOOSTER, _amount);
    IConvexBooster(BOOSTER).deposit(_pool.convexPoolId, _amount, true);

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _shares;
    if (_totalShare == 0) {
      _shares = _amount;
    } else {
      _shares = _amount.mul(_totalShare) / _totalUnderlying;
    }
    _pool.totalShare = _toU128(_totalShare.add(_shares));
    _pool.totalUnderlying = _toU128(_totalUnderlying.add(_amount));

    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    _userInfo.shares = _toU128(_shares + _userInfo.shares);

    emit Deposit(_pid, msg.sender, _amount);
    return _shares;
  }

  function _withdraw(
    uint256 _pid,
    uint256 _shares,
    address _recipient
  ) internal returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    // 2. withdraw lp token
    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    require(_shares <= _userInfo.shares, "AladdinConvexVault: shares not enough");

    uint256 _totalShare = _pool.totalShare;
    uint256 _totalUnderlying = _pool.totalUnderlying;
    uint256 _withdrawable;
    if (_shares == _totalShare) {
      // If user is last to withdraw, don't take withdraw fee.
      // And there may still have some pending rewards, we just simple ignore it now.
      // If we want the reward later, we can upgrade the contract.
      _withdrawable = _totalUnderlying;
    } else {
      // take withdraw fee here
      _withdrawable = _shares.mul(_totalUnderlying) / _totalShare;
      uint256 _fee = _withdrawable.mul(_pool.withdrawFeePercentage) / FEE_DENOMINATOR;
      _withdrawable = _withdrawable - _fee; // never overflow
    }

    _pool.totalShare = _toU128(_totalShare - _shares);
    _pool.totalUnderlying = _toU128(_totalUnderlying - _withdrawable);
    _userInfo.shares = _toU128(uint256(_userInfo.shares) - _shares);

    IConvexBasicRewards(_pool.crvRewards).withdrawAndUnwrap(_withdrawable, false);
    IERC20Upgradeable(_pool.lpToken).safeTransfer(_recipient, _withdrawable);
    emit Withdraw(_pid, msg.sender, _shares);

    return _withdrawable;
  }

  function _claim(
    uint256 _amount,
    uint256 _minOut,
    ClaimOption _option
  ) internal returns (uint256) {
    if (_amount == 0) return _amount;

    IAladdinCRV.WithdrawOption _withdrawOption;
    if (_option == ClaimOption.Claim) {
      require(_amount >= _minOut, "AladdinConvexVault: insufficient output");
      IERC20Upgradeable(aladdinCRV).safeTransfer(msg.sender, _amount);
      return _amount;
    } else if (_option == ClaimOption.ClaimAsCvxCRV) {
      _withdrawOption = IAladdinCRV.WithdrawOption.Withdraw;
    } else if (_option == ClaimOption.ClaimAsCRV) {
      _withdrawOption = IAladdinCRV.WithdrawOption.WithdrawAsCRV;
    } else if (_option == ClaimOption.ClaimAsCVX) {
      _withdrawOption = IAladdinCRV.WithdrawOption.WithdrawAsCVX;
    } else if (_option == ClaimOption.ClaimAsETH) {
      _withdrawOption = IAladdinCRV.WithdrawOption.WithdrawAsETH;
    } else {
      revert("AladdinConvexVault: invalid claim option");
    }
    return IAladdinCRV(aladdinCRV).withdraw(msg.sender, _amount, _minOut, _withdrawOption);
  }

  function _toU128(uint256 _value) internal pure returns (uint128) {
    require(_value < 340282366920938463463374607431768211456, "AladdinConvexVault: overflow");
    return uint128(_value);
  }

  function _swapCRVToCvxCRV(uint256 _amountIn, uint256 _minOut) internal returns (uint256) {
    // CRV swap to CVXCRV or stake to CVXCRV
    // CRV swap to CVXCRV or stake to CVXCRV
    uint256 _amountOut = ICurveFactoryPlainPool(CURVE_CVXCRV_CRV_POOL).get_dy(0, 1, _amountIn);
    bool useCurve = _amountOut > _amountIn;
    require(_amountOut >= _minOut || _amountIn >= _minOut, "AladdinCRVZap: insufficient output");

    if (useCurve) {
      _approve(CRV, CURVE_CVXCRV_CRV_POOL, _amountIn);
      _amountOut = ICurveFactoryPlainPool(CURVE_CVXCRV_CRV_POOL).exchange(0, 1, _amountIn, 0, address(this));
    } else {
      _approve(CRV, CRV_DEPOSITOR, _amountIn);
      uint256 _lockIncentive = IConvexCRVDepositor(CRV_DEPOSITOR).lockIncentive();
      // if use `lock = false`, will possible take fee
      // if use `lock = true`, some incentive will be given
      _amountOut = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
      if (_lockIncentive == 0) {
        // no lock incentive, use `lock = false`
        IConvexCRVDepositor(CRV_DEPOSITOR).deposit(_amountIn, false, address(0));
      } else {
        // no lock incentive, use `lock = true`
        IConvexCRVDepositor(CRV_DEPOSITOR).deposit(_amountIn, true, address(0));
      }
      _amountOut = IERC20Upgradeable(CVXCRV).balanceOf(address(this)) - _amountOut; // never overflow here
    }
    return _amountOut;
  }

  function _approve(
    address _token,
    address _spender,
    uint256 _amount
  ) internal {
    IERC20Upgradeable(_token).safeApprove(_spender, 0);
    IERC20Upgradeable(_token).safeApprove(_spender, _amount);
  }

  receive() external payable {}
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

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IAladdinConvexVault {
  enum ClaimOption {
    None,
    Claim,
    ClaimAsCvxCRV,
    ClaimAsCRV,
    ClaimAsCVX,
    ClaimAsETH
  }

  event Deposit(uint256 indexed _pid, address indexed _sender, uint256 _amount);
  event Withdraw(uint256 indexed _pid, address indexed _sender, uint256 _shares);
  event Claim(address indexed _sender, uint256 _reward, ClaimOption _option);
  event Harvest(address indexed _caller, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);

  event UpdateWithdrawalFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 indexed _pid, uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 indexed _pid, uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);
  event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);
  event AddPool(uint256 indexed _pid, uint256 _convexPid, address[] _rewardTokens);
  event PausePoolDeposit(uint256 indexed _pid, bool _status);
  event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  function pendingReward(uint256 _pid, address _account) external view returns (uint256);

  function pendingRewardAll(address _account) external view returns (uint256);

  function deposit(uint256 _pid, uint256 _amount) external returns (uint256);

  function depositAll(uint256 _pid) external returns (uint256);

  function zapAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _amount,
    uint256 _minAmount
  ) external payable returns (uint256);

  function zapAllAndDeposit(
    uint256 _pid,
    address _token,
    uint256 _minAmount
  ) external payable returns (uint256);

  function withdrawAndZap(
    uint256 _pid,
    uint256 _shares,
    address _token,
    uint256 _minOut
  ) external returns (uint256);

  function withdrawAllAndZap(
    uint256 _pid,
    address _token,
    uint256 _minOut
  ) external returns (uint256);

  function withdrawAndClaim(
    uint256 _pid,
    uint256 _shares,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256, uint256);

  function withdrawAllAndClaim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256, uint256);

  function claim(
    uint256 _pid,
    uint256 _minOut,
    ClaimOption _option
  ) external returns (uint256);

  function claimAll(uint256 _minOut, ClaimOption _option) external returns (uint256);

  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minimumOut
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IAladdinCRV is IERC20Upgradeable {
  event Harvest(address indexed _caller, uint256 _amount);
  event Deposit(address indexed _sender, address indexed _recipient, uint256 _amount);
  event Withdraw(
    address indexed _sender,
    address indexed _recipient,
    uint256 _shares,
    IAladdinCRV.WithdrawOption _option
  );

  event UpdateWithdrawalFeePercentage(uint256 _feePercentage);
  event UpdatePlatformFeePercentage(uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);

  enum WithdrawOption {
    Withdraw,
    WithdrawAndStake,
    WithdrawAsCRV,
    WithdrawAsCVX,
    WithdrawAsETH
  }

  /// @dev return the total amount of cvxCRV staked.
  function totalUnderlying() external view returns (uint256);

  /// @dev return the amount of cvxCRV staked for user
  function balanceOfUnderlying(address _user) external view returns (uint256);

  function deposit(address _recipient, uint256 _amount) external returns (uint256);

  function depositAll(address _recipient) external returns (uint256);

  function depositWithCRV(address _recipient, uint256 _amount) external returns (uint256);

  function depositAllWithCRV(address _recipient) external returns (uint256);

  function withdraw(
    address _recipient,
    uint256 _shares,
    uint256 _minimumOut,
    WithdrawOption _option
  ) external returns (uint256);

  function withdrawAll(
    address _recipient,
    uint256 _minimumOut,
    WithdrawOption _option
  ) external returns (uint256);

  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IConvexBooster {
  struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
  }

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

  function depositAll(uint256 _pid, bool _stake) external returns (bool);

  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  function earmarkRewards(uint256 _pid) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexBasicRewards {
  function stakeFor(address, uint256) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function earned(address) external view returns (uint256);

  function withdrawAll(bool) external returns (bool);

  function withdraw(uint256, bool) external returns (bool);

  function withdrawAndUnwrap(uint256, bool) external returns (bool);

  function getReward() external returns (bool);

  function stake(uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexCRVDepositor {
  function deposit(
    uint256 _amount,
    bool _lock,
    address _stakeAddress
  ) external;

  function deposit(uint256 _amount, bool _lock) external;

  function lockIncentive() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase
interface ICurveFactoryPlainPool {
  function remove_liquidity_one_coin(
    uint256 token_amount,
    int128 i,
    uint256 min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 _dx,
    uint256 _min_dy,
    address _receiver
  ) external returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);
}

/// @dev This is the interface of Curve Factory Plain Pool with 2 tokens, examples:
interface ICurveFactoryPlain2Pool is ICurveFactoryPlainPool {
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool _is_deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve Factory Plain Pool with 3 tokens, examples:
interface ICurveFactoryPlain3Pool is ICurveFactoryPlainPool {
  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[3] memory amounts, bool _is_deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve Factory Plain Pool with 4 tokens, examples:
interface ICurveFactoryPlain4Pool is ICurveFactoryPlainPool {
  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[4] memory amounts, bool _is_deposit) external view returns (uint256);
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