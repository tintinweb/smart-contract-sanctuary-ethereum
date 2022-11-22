// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Math.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/ERC20Upgradeable.sol";
import "./VaultStorage.sol";
import "./VaultLibrary.sol";
import "../governance/ControllableV2.sol";
import "../interface/IStrategy.sol";
import "../interface/IController.sol";
import "../interface/IBookkeeper.sol";
import "../interface/IVaultController.sol";

/// @title Smart Vault is a combination of implementations drawn from Synthetix pool
///        for their innovative reward vesting and Yearn vault for their share price model
/// @dev Use with TetuProxy
/// @author belbix
contract SmartVault is Initializable, ERC20Upgradeable, VaultStorage, ControllableV2 {
  using SafeERC20 for IERC20;

  // ************* CONSTANTS ********************
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant override VERSION = "1.10.5";
  /// @dev Denominator for penalty numerator
  uint256 public constant override LOCK_PENALTY_DENOMINATOR = 1000;
  uint256 public constant override TO_INVEST_DENOMINATOR = 1000;
  uint256 public constant override DEPOSIT_FEE_DENOMINATOR = 10000;
  uint256 private constant NAME_OVERRIDE_ID = 0;
  uint256 private constant SYMBOL_OVERRIDE_ID = 1;
  string private constant FORBIDDEN_MSG = "SV: Forbidden";

  // ********************* VARIABLES *****************
  //in upgradable contracts you can skip storage ONLY for mapping and dynamically-sized array types
  //https://docs.soliditylang.org/en/v0.4.21/miscellaneous.html#layout-of-state-variables-in-storage
  //use VaultStorage for primitive variables

  // ****** REWARD MECHANIC VARIABLES ******** //
  /// @dev A list of reward tokens that able to be distributed to this contract
  address[] internal _rewardTokens;
  /// @dev Timestamp value when current period of rewards will be ended
  mapping(address => uint256) public override periodFinishForToken;
  /// @dev Reward rate in normal circumstances is distributed rewards divided on duration
  mapping(address => uint256) public override rewardRateForToken;
  /// @dev Last rewards snapshot time. Updated on each share movements
  mapping(address => uint256) public override lastUpdateTimeForToken;
  /// @dev Rewards snapshot calculated from rewardPerToken(rt). Updated on each share movements
  mapping(address => uint256) public override rewardPerTokenStoredForToken;
  /// @dev User personal reward rate snapshot. Updated on each share movements
  mapping(address => mapping(address => uint256)) public override userRewardPerTokenPaidForToken;
  /// @dev User personal earned reward snapshot. Updated on each share movements
  mapping(address => mapping(address => uint256)) public override rewardsForToken;

  // ******** OTHER VARIABLES **************** //
  /// @dev Only for statistical purposes, no guarantee to be accurate
  ///      Last timestamp value when user withdraw. Resets on transfer
  mapping(address => uint256) public override userLastWithdrawTs;
  /// @dev In normal circumstances hold last claim timestamp for users
  mapping(address => uint256) public override userBoostTs;
  /// @dev In normal circumstances hold last withdraw timestamp for users
  mapping(address => uint256) public override userLockTs;
  /// @dev Only for statistical purposes, no guarantee to be accurate
  ///      Last timestamp value when user deposit. Doesn't update on transfers
  mapping(address => uint256) public override userLastDepositTs;
  /// @dev VaultStorage doesn't have a map for strings so we need to add it here
  mapping(uint256 => string) private _nameOverrides;
  mapping(address => address) public rewardsRedirect;

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  /// @param _name ERC20 name
  /// @param _symbol ERC20 symbol
  /// @param _controller Controller address
  /// @param __underlying Vault underlying address
  /// @param _duration Rewards duration
  /// @param _lockAllowed Set true with lock mechanic requires
  /// @param _rewardToken Reward token address. Set zero address if not requires
  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint _depositFee
  ) external override initializer {
    __ERC20_init(_name, _symbol);

    ControllableV2.initializeControllable(_controller);
    VaultStorage.initializeVaultStorage(
      __underlying,
      _duration,
      _lockAllowed
    );
    // initialize reward token for easily deploy new vaults from deployer address
    if (_rewardToken != address(0)) {
      require(_rewardToken != _underlying());
      _rewardTokens.push(_rewardToken);
    }
    // set 100% to invest
    _setToInvest(TO_INVEST_DENOMINATOR);
    // set deposit fee
    if (_depositFee > 0) {
      require(_depositFee <= DEPOSIT_FEE_DENOMINATOR / 100);
      _setDepositFeeNumerator(_depositFee);
    }
  }

  // *************** EVENTS ***************************
  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);
  event StrategyAnnounced(address newStrategy, uint256 time);
  event StrategyChanged(address newStrategy, address oldStrategy);
  event RewardAdded(address rewardToken, uint256 reward);
  event RewardMovedToController(address rewardToken, uint256 amount);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, address rewardToken, uint256 reward);
  event RewardDenied(address indexed user, address rewardToken, uint256 reward);
  event AddedRewardToken(address indexed token);
  event RemovedRewardToken(address indexed token);
  event RewardRecirculated(address indexed token, uint256 amount);
  event RewardSentToController(address indexed token, uint256 amount);
  event SetRewardsRedirect(address owner, address receiver);

  // *************** RESTRICTIONS ***************************

  /// @dev Allow operation only for VaultController
  function _onlyVaultController(address _sender) private view {
    require(IController(_controller()).vaultController() == _sender, FORBIDDEN_MSG);
  }

  /// @dev Allowed only for active strategy
  function _isActive() private view {
    require(_active(), "SV: Not active");
  }

  /// @dev Only smart contracts will be affected by this restriction
  ///      If it is a contract it should be whitelisted
  function _onlyAllowedUsers(address _sender) private view {
    require(IController(_controller()).isAllowedUser(_sender), FORBIDDEN_MSG);
  }

  // ************ COMMON VIEWS ***********************

  function name() public view override returns (string memory) {
    string memory nameForOverride = _nameOverrides[NAME_OVERRIDE_ID];
    if (bytes(nameForOverride).length != 0) {
      return nameForOverride;
    }
    return super.name();
  }

  function symbol() public view override returns (string memory) {
    string memory symbolForOverride = _nameOverrides[SYMBOL_OVERRIDE_ID];
    if (bytes(symbolForOverride).length != 0) {
      return symbolForOverride;
    }
    return super.symbol();
  }

  /// @notice ERC20 compatible decimals value. Should be the same as underlying
  function decimals() public view override returns (uint8) {
    return ERC20Upgradeable(_underlying()).decimals();
  }

  /// @dev Returns vault controller
  function _vaultController() internal view returns (IVaultController){
    return IVaultController(IController(_controller()).vaultController());
  }

  // ************ GOVERNANCE ACTIONS ******************

  /// @notice Override vault name
  function overrideName(string calldata value) external override {
    require(_isGovernance(msg.sender));
    _nameOverrides[NAME_OVERRIDE_ID] = value;
  }

  /// @notice Override vault name
  function overrideSymbol(string calldata value) external override {
    require(_isGovernance(msg.sender));
    _nameOverrides[SYMBOL_OVERRIDE_ID] = value;
  }

  /// @notice Change permission for decreasing ppfs during hard work process
  /// @param _value true - allowed, false - disallowed
  function changePpfsDecreaseAllowed(bool _value) external override {
    _onlyVaultController(msg.sender);
    _setPpfsDecreaseAllowed(_value);
  }

  /// @notice Set lock period for funds. Can be called only once
  /// @param _value Timestamp value
  function setLockPeriod(uint256 _value) external override {
    require(_isController(msg.sender) || _isGovernance(msg.sender), FORBIDDEN_MSG);
    require(_lockAllowed());
    require(lockPeriod() == 0);
    _setLockPeriod(_value);
  }

  /// @notice Set lock initial penalty nominator. Can be called only once
  /// @param _value Penalty denominator, should be in range 0 - (LOCK_PENALTY_DENOMINATOR / 2)
  function setLockPenalty(uint256 _value) external override {
    require(_isController(msg.sender) || _isGovernance(msg.sender), FORBIDDEN_MSG);
    require(_value <= (LOCK_PENALTY_DENOMINATOR / 2));
    require(_lockAllowed());
    require(lockPenalty() == 0);
    _setLockPenalty(_value);
  }

  /// @dev All rewards for given owner could be claimed for receiver address.
  function setRewardsRedirect(address owner, address receiver) external override {
    require(_isGovernance(msg.sender), FORBIDDEN_MSG);
    rewardsRedirect[owner] = receiver;
    emit SetRewardsRedirect(owner, receiver);
  }

  /// @notice Set numerator for toInvest ratio in range 0 - 1000
  function setToInvest(uint256 _value) external override {
    _onlyVaultController(msg.sender);
    require(_value <= TO_INVEST_DENOMINATOR);
    _setToInvest(_value);
  }

  // we should be able to disable lock functionality for not initialized contract
  function disableLock() external override {
    _onlyVaultController(msg.sender);
    require(_lockAllowed());
    // should be not initialized
    // initialized lock forbidden to change
    require(lockPenalty() == 0);
    require(lockPeriod() == 0);
    _disableLock();
  }

  /// @notice Change the active state marker
  /// @param _active Status true - active, false - deactivated
  function changeActivityStatus(bool _active) external override {
    _onlyVaultController(msg.sender);
    _setActive(_active);
  }

  /// @notice Change the protection mode status.
  ///          Protection mode means claim rewards on withdraw and 0% initial reward boost
  /// @param _active Status true - active, false - deactivated
  function changeProtectionMode(bool _active) external override {
    require(_isGovernance(msg.sender), FORBIDDEN_MSG);
    _setProtectionMode(_active);
  }

  /// @notice If true we will call doHardWork for each invest action
  /// @param _active Status true - active, false - deactivated
  function changeDoHardWorkOnInvest(bool _active) external override {
    require(_isGovernance(msg.sender), FORBIDDEN_MSG);
    _setDoHardWorkOnInvest(_active);
  }

  /// @notice If true we will call invest for each deposit
  /// @param _active Status true - active, false - deactivated
  function changeAlwaysInvest(bool _active) external override {
    require(_isGovernance(msg.sender), FORBIDDEN_MSG);
    _setAlwaysInvest(_active);
  }

  /// @notice Earn some money for honest work
  function doHardWork() external override {
    require(_isController(msg.sender) || _isGovernance(msg.sender), FORBIDDEN_MSG);
    _invest();
    // otherwise we already do
    if (!_doHardWorkOnInvest()) {
      _doHardWork();
    }
  }

  function _doHardWork() internal {
    uint256 sharePriceBeforeHardWork = _getPricePerFullShare();
    IStrategy(_strategy()).doHardWork();
    require(ppfsDecreaseAllowed() || sharePriceBeforeHardWork <= _getPricePerFullShare(), "SV: PPFS decreased");
  }

  /// @notice Add a reward token to the internal array
  /// @param rt Reward token address
  function addRewardToken(address rt) external override {
    _onlyVaultController(msg.sender);
    require(_getRewardTokenIndex(rt) == type(uint256).max);
    require(rt != _underlying());
    _rewardTokens.push(rt);
    emit AddedRewardToken(rt);
  }

  /// @notice Remove reward token. Last token removal is not allowed
  /// @param rt Reward token address
  function removeRewardToken(address rt) external override {
    _onlyVaultController(msg.sender);
    uint256 i = _getRewardTokenIndex(rt);
    require(i != type(uint256).max);
    require(periodFinishForToken[_rewardTokens[i]] < block.timestamp);
    require(_rewardTokens.length > 1);
    uint256 lastIndex = _rewardTokens.length - 1;
    // swap
    _rewardTokens[i] = _rewardTokens[lastIndex];
    // delete last element
    _rewardTokens.pop();
    emit RemovedRewardToken(rt);
  }

  /// @notice Withdraw all from strategy to the vault and invest again
  function rebalance() external override {
    _onlyVaultController(msg.sender);
    IStrategy(_strategy()).withdrawAllToVault();
    _invest();
  }

  /// @notice Withdraw all from strategy to the vault
  function withdrawAllToVault() external override {
    require(address(_controller()) == msg.sender
      || IController(_controller()).governance() == msg.sender, FORBIDDEN_MSG);
    IStrategy(_strategy()).withdrawAllToVault();
  }

  //****************** USER ACTIONS ********************

  /// @notice Allows for depositing the underlying asset in exchange for shares.
  ///         Approval is assumed.
  function deposit(uint256 amount) external override {
    _isActive();
    _onlyAllowedUsers(msg.sender);

    _deposit(amount, msg.sender, msg.sender);
    if (_alwaysInvest()) {
      _invest();
    }
  }

  /// @notice Allows for depositing the underlying asset in exchange for shares.
  ///         Approval is assumed. Immediately invests the asset to the strategy
  function depositAndInvest(uint256 amount) external override {
    _isActive();
    _onlyAllowedUsers(msg.sender);

    _deposit(amount, msg.sender, msg.sender);
    _invest();
  }

  /// @notice Allows for depositing the underlying asset in exchange for shares assigned to the holder.
  ///         This facilitates depositing for someone else
  function depositFor(uint256 amount, address holder) external override {
    _isActive();
    _onlyAllowedUsers(msg.sender);

    _deposit(amount, msg.sender, holder);
    if (_alwaysInvest()) {
      _invest();
    }
  }

  /// @notice Withdraw shares partially without touching rewards
  function withdraw(uint256 numberOfShares) external override {
    _onlyAllowedUsers(msg.sender);

    // assume that allowed users is trusted contracts with internal specific logic
    // for compatability we should not claim rewards on withdraw for them
    if (_protectionMode() && !IController(_controller()).isAllowedUser(msg.sender)) {
      _getAllRewards(msg.sender, msg.sender);
    }

    _withdraw(numberOfShares);
  }

  /// @notice Withdraw all and claim rewards
  /// @notice If you use DepositHelper - then call getAllRewardsFor before exit to receive rewards
  function exit() external override {
    _onlyAllowedUsers(msg.sender);
    // for locked functionality need to claim rewards firstly
    // otherwise token transfer will refresh the lock period
    // also it will withdraw claimed tokens too
    _getAllRewards(msg.sender, msg.sender);
    _withdraw(balanceOf(msg.sender));
  }

  /// @notice Update and Claim all rewards
  function getAllRewards() external override {
    _onlyAllowedUsers(msg.sender);
    _getAllRewards(msg.sender, msg.sender);
  }

  /// @notice Update and Claim all rewards for given owner address. Send them to predefined receiver.
  function getAllRewardsAndRedirect(address owner) external override {
    address receiver = rewardsRedirect[owner];
    require(receiver != address(0), "zero receiver");
    _getAllRewards(owner, receiver);
  }

  /// @notice Update and Claim all rewards for the given owner.
  ///         Sender should have allowance for push rewards for the owner.
  function getAllRewardsFor(address owner) external override {
    _onlyAllowedUsers(msg.sender);
    if (owner != msg.sender) {
      // To avoid calls from any address, and possibility to cancel boosts for other addresses
      // we check approval of shares for msg.sender. Msg sender should have approval for max amount
      // As approved amount is deducted every transfer, we checks it with max / 10
      uint allowance = allowance(owner, msg.sender);
      require(allowance > (type(uint256).max / 10), "SV: Not allowed");
    }
    _getAllRewards(owner, owner);
  }

  function _getAllRewards(address owner, address receiver) internal {
    _updateRewards(owner);
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      _payRewardTo(_rewardTokens[i], owner, receiver);
    }
  }

  /// @notice Update and Claim rewards for specific token
  function getReward(address rt) external override {
    _onlyAllowedUsers(msg.sender);
    _updateReward(msg.sender, rt);
    _payRewardTo(rt, msg.sender, msg.sender);
  }

  /// @dev Update user specific variables
  ///      Store statistical information to Bookkeeper
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    _updateRewards(from);
    _updateRewards(to);

    // mint - assuming it is deposit action
    if (from == address(0)) {
      // new deposit
      if (_underlyingBalanceWithInvestmentForHolder(to) == 0) {
        userBoostTs[to] = block.timestamp;
      }

      // start lock only for new deposits
      if (userLockTs[to] == 0 && _lockAllowed()) {
        userLockTs[to] = block.timestamp;
      }

      // store current timestamp
      userLastDepositTs[to] = block.timestamp;
    } else if (to == address(0)) {
      // burn - assuming it is withdraw action
      userLastWithdrawTs[from] = block.timestamp;
    } else {
      // regular transfer

      // we can't normally refresh lock timestamp for locked assets when it transfers to another account
      // need to allow transfers for reward notification process and claim rewards
      require(!_lockAllowed()
      || to == address(this)
      || from == address(this)
      || from == _controller(), FORBIDDEN_MSG);

      // if recipient didn't have deposit - start boost time
      if (_underlyingBalanceWithInvestmentForHolder(to) == 0) {
        userBoostTs[to] = block.timestamp;
      }

      // update only for new deposit for avoiding miscellaneous sending for reset the value
      if (userLastDepositTs[to] == 0) {
        userLastDepositTs[to] = block.timestamp;
      }

      // reset timer if token transferred
      userLastWithdrawTs[from] = block.timestamp;
    }

    // register ownership changing
    // only statistic, no funds affected
    try IBookkeeper(IController(_controller()).bookkeeper())
    .registerVaultTransfer(from, to, amount) {
    } catch {}
    super._beforeTokenTransfer(from, to, amount);
  }

  //**************** UNDERLYING MANAGEMENT FUNCTIONALITY ***********************

  /// @notice Return underlying precision units
  function underlyingUnit() external view override returns (uint256) {
    return _underlyingUnit();
  }

  function _underlyingUnit() internal view returns (uint256) {
    return 10 ** uint256(ERC20Upgradeable(address(_underlying())).decimals());
  }

  /// @notice Returns the cash balance across all users in this contract.
  function underlyingBalanceInVault() external view override returns (uint256) {
    return _underlyingBalanceInVault();
  }

  function _underlyingBalanceInVault() internal view returns (uint256) {
    return IERC20(_underlying()).balanceOf(address(this));
  }

  /// @notice Returns the current underlying (e.g., DAI's) balance together with
  ///         the invested amount (if DAI is invested elsewhere by the strategy).
  function underlyingBalanceWithInvestment() external view override returns (uint256) {
    return _underlyingBalanceWithInvestment();
  }

  function _underlyingBalanceWithInvestment() internal view returns (uint256) {
    return VaultLibrary.underlyingBalanceWithInvestment(
      _strategy(),
      IERC20(_underlying()).balanceOf(address(this))
    );
  }

  /// @notice Get the user's share (in underlying)
  ///         underlyingBalanceWithInvestment() * balanceOf(holder) / totalSupply()
  function underlyingBalanceWithInvestmentForHolder(address holder)
  external view override returns (uint256) {
    return _underlyingBalanceWithInvestmentForHolder(holder);
  }

  function _underlyingBalanceWithInvestmentForHolder(address holder) internal view returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return _underlyingBalanceWithInvestment() * balanceOf(holder) / totalSupply();
  }

  /// @notice Price per full share (PPFS)
  ///         Vaults with 100% buybacks have a value of 1 constantly
  ///         (underlyingUnit() * underlyingBalanceWithInvestment()) / totalSupply()
  function getPricePerFullShare() external view override returns (uint256) {
    return _getPricePerFullShare();
  }

  function _getPricePerFullShare() internal view returns (uint256) {
    return totalSupply() == 0
    ? _underlyingUnit()
    : _underlyingUnit() * _underlyingBalanceWithInvestment() / totalSupply();
  }

  /// @notice Return amount of the underlying asset ready to invest to the strategy
  function availableToInvestOut() external view override returns (uint256) {
    return _availableToInvestOut();
  }

  function _availableToInvestOut() internal view returns (uint256) {
    return VaultLibrary.availableToInvestOut(
      _strategy(),
      _toInvest(),
      _underlyingBalanceInVault()
    );
  }

  /// @notice Burn shares, withdraw underlying from strategy
  ///         and send back to the user the underlying asset
  function _withdraw(uint256 numberOfShares) internal {
    require(!_reentrantLock(), "SV: Reentrant call");
    _setReentrantLock(true);
    _updateRewards(msg.sender);
    require(totalSupply() > 0, "SV: No shares for withdraw");
    require(numberOfShares > 0, "SV: Zero amount for withdraw");

    // store totalSupply before shares burn
    uint256 _totalSupply = totalSupply();

    // this logic not eligible for normal vaults
    if (_lockAllowed()) {
      numberOfShares = _processLockedAmount(numberOfShares);
    }

    // only statistic, no funds affected
    try IBookkeeper(IController(_controller()).bookkeeper())
    .registerUserAction(msg.sender, numberOfShares, false) {
    } catch {}

    uint256 underlyingAmountToWithdraw = VaultLibrary.processWithdrawFromStrategy(
      numberOfShares,
      _underlying(),
      _totalSupply,
      _toInvest(),
      _strategy()
    );

    // need to burn shares after strategy withdraw for properly PPFS calculation
    _burn(msg.sender, numberOfShares);

    IERC20(_underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

    _setReentrantLock(false);
    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, underlyingAmountToWithdraw);
  }

  /// @dev Locking logic will add a part of locked shares as rewards for this vault
  ///      Calculate locked amount and distribute locked shares as reward to the current vault
  /// @return Number of shares available to withdraw
  function _processLockedAmount(uint256 numberOfShares) internal returns (uint256){
    (uint numberOfSharesAdjusted, uint lockedSharesToReward) = VaultLibrary.calculateLockedAmount(
      numberOfShares,
      userLockTs,
      lockPeriod(),
      lockPenalty(),
      balanceOf(msg.sender)
    );

    if (lockedSharesToReward != 0) {
      // move shares to current contract for using as rewards
      _transfer(msg.sender, address(this), lockedSharesToReward);
      // vault should have itself as reward token for recirculation process
      _notifyRewardWithoutPeriodChange(lockedSharesToReward, address(this));
    }

    return numberOfSharesAdjusted;
  }

  /// @notice Mint shares and transfer underlying from user to the vault
  ///         New shares = (invested amount * total supply) / underlyingBalanceWithInvestment()
  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(!_reentrantLock(), "SV: Reentrant call");
    _setReentrantLock(true);
    _updateRewards(beneficiary);
    require(amount > 0, "SV: Zero amount");
    require(beneficiary != address(0), "SV: Zero beneficiary for deposit");

    uint256 toMint = totalSupply() == 0
    ? amount
    : amount * totalSupply() / _underlyingBalanceWithInvestment();
    // no revert for this case for keep compatability
    if (toMint != 0) {
      toMint = toMint * (DEPOSIT_FEE_DENOMINATOR - _depositFeeNumerator()) / DEPOSIT_FEE_DENOMINATOR;
      _mint(beneficiary, toMint);

      IERC20(_underlying()).safeTransferFrom(sender, address(this), amount);

      // only statistic, no funds affected
      try IBookkeeper(IController(_controller()).bookkeeper())
      .registerUserAction(beneficiary, toMint, true){
      } catch {}
      emit Deposit(beneficiary, amount);
    }
    _setReentrantLock(false);
  }

  /// @notice Transfer underlying to the strategy
  function _invest() internal {
    require(_strategy() != address(0));
    // avoid recursive hardworks
    if (_doHardWorkOnInvest() && msg.sender != _strategy()) {
      _doHardWork();
    }
    uint256 availableAmount = _availableToInvestOut();
    if (availableAmount > 0) {
      IERC20(_underlying()).safeTransfer(address(_strategy()), availableAmount);
      IStrategy(_strategy()).investAllUnderlying();
      emit Invest(availableAmount);
    }
  }

  //**************** REWARDS FUNCTIONALITY ***********************

  /// @dev Refresh reward numbers
  function _updateReward(address account, address rt) internal {
    rewardPerTokenStoredForToken[rt] = _rewardPerToken(rt);
    lastUpdateTimeForToken[rt] = _lastTimeRewardApplicable(rt);
    if (account != address(0) && account != address(this)) {
      rewardsForToken[rt][account] = _earned(rt, account);
      userRewardPerTokenPaidForToken[rt][account] = rewardPerTokenStoredForToken[rt];
    }
  }

  /// @dev Use it for any underlying movements
  function _updateRewards(address account) private {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      _updateReward(account, _rewardTokens[i]);
    }
  }

  /// @notice Return earned rewards for specific token and account (with 100% boost)
  ///         Accurate value returns only after updateRewards call
  ///         ((balanceOf(account)
  ///           * (rewardPerToken - userRewardPerTokenPaidForToken)) / 10**18) + rewardsForToken
  function earned(address rt, address account) external view override returns (uint256) {
    return _earned(rt, account);
  }

  function _earned(address rt, address account) internal view returns (uint256) {
    return balanceOf(account)
    * (_rewardPerToken(rt) - userRewardPerTokenPaidForToken[rt][account])
    / 1e18
    + rewardsForToken[rt][account];
  }

  /// @notice Return amount ready to claim, calculated with actual boost
  ///         Accurate value returns only after updateRewards call
  function earnedWithBoost(address rt, address account) external view override returns (uint256) {
    return VaultLibrary.earnedWithBoost(
      rt,
      _earned(rt, account),
      userBoostTs[account],
      _controller(),
      _protectionMode()
    );
  }

  /// @notice Return reward per token ratio by reward token address
  ///                rewardPerTokenStoredForToken + (
  ///                (lastTimeRewardApplicable - lastUpdateTimeForToken)
  ///                 * rewardRateForToken * 10**18 / totalSupply)
  function rewardPerToken(address rt) external view override returns (uint256) {
    return _rewardPerToken(rt);
  }

  function _rewardPerToken(address rt) internal view returns (uint256) {
    uint256 totalSupplyWithoutItself = totalSupply() - balanceOf(address(this));
    if (totalSupplyWithoutItself == 0) {
      return rewardPerTokenStoredForToken[rt];
    }
    return
    rewardPerTokenStoredForToken[rt] + (
    (_lastTimeRewardApplicable(rt) - lastUpdateTimeForToken[rt])
    * rewardRateForToken[rt]
    * 1e18
    / totalSupplyWithoutItself
    );
  }

  /// @notice Return periodFinishForToken or block.timestamp by reward token address
  function lastTimeRewardApplicable(address rt) external view override returns (uint256) {
    return _lastTimeRewardApplicable(rt);
  }

  function _lastTimeRewardApplicable(address rt) internal view returns (uint256) {
    return Math.min(block.timestamp, periodFinishForToken[rt]);
  }

  /// @notice Return reward token array
  function rewardTokens() external view override returns (address[] memory){
    return _rewardTokens;
  }

  /// @notice Return reward token array length
  function rewardTokensLength() external view override returns (uint256){
    return _rewardTokens.length;
  }

  /// @notice Return reward token index
  ///         If the return value is MAX_UINT256, it means that
  ///         the specified reward token is not in the list
  function getRewardTokenIndex(address rt) external override view returns (uint256) {
    return _getRewardTokenIndex(rt);
  }

  function _getRewardTokenIndex(address rt) internal view returns (uint256) {
    for (uint i = 0; i < _rewardTokens.length; i++) {
      if (_rewardTokens[i] == rt)
        return i;
    }
    return type(uint256).max;
  }

  /// @notice Update rewardRateForToken
  ///         If period ended: reward / duration
  ///         else add leftover to the reward amount and refresh the period
  ///         (reward + ((periodFinishForToken - block.timestamp) * rewardRateForToken)) / duration
  function notifyTargetRewardAmount(address _rewardToken, uint256 amount) external override {
    require(IController(_controller()).isRewardDistributor(msg.sender), FORBIDDEN_MSG);
    _updateRewards(address(0));
    // register notified amount for statistical purposes
    IBookkeeper(IController(_controller()).bookkeeper())
    .registerRewardDistribution(address(this), _rewardToken, amount);

    // overflow fix according to https://sips.synthetix.io/sips/sip-77
    require(amount < type(uint256).max / 1e18, "SV: Amount overflow");
    uint256 i = _getRewardTokenIndex(_rewardToken);
    require(i != type(uint256).max, "SV: RT not found");

    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), amount);

    if (block.timestamp >= periodFinishForToken[_rewardToken]) {
      rewardRateForToken[_rewardToken] = amount / duration();
    } else {
      uint256 remaining = periodFinishForToken[_rewardToken] - block.timestamp;
      uint256 leftover = remaining * rewardRateForToken[_rewardToken];
      rewardRateForToken[_rewardToken] = (amount + leftover) / duration();
    }
    lastUpdateTimeForToken[_rewardToken] = block.timestamp;
    periodFinishForToken[_rewardToken] = block.timestamp + duration();

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint balance = IERC20(_rewardToken).balanceOf(address(this));
    require(rewardRateForToken[_rewardToken] <= balance / duration(), "SV: Provided reward too high");
    emit RewardAdded(_rewardToken, amount);
  }

  /// @dev Assume approve
  ///      Add reward amount without changing reward duration
  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 _amount) external override {
    require(IController(_controller()).isRewardDistributor(msg.sender), FORBIDDEN_MSG);
    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
    _notifyRewardWithoutPeriodChange(_amount, _rewardToken);
  }

  /// @notice Transfer earned rewards to rewardsReceiver
  function _payRewardTo(address rt, address owner, address receiver) internal {
    (uint renotifiedAmount, uint paidReward) = VaultLibrary.processPayRewardFor(
      rt,
      _earned(rt, owner),
      userBoostTs,
      _controller(),
      _protectionMode(),
      rewardsForToken,
      owner,
      receiver
    );
    if (renotifiedAmount != 0) {
      _notifyRewardWithoutPeriodChange(renotifiedAmount, rt);
    }
    if (paidReward != 0) {
      emit RewardPaid(owner, rt, renotifiedAmount);
    }
  }

  /// @dev Add reward amount without changing reward duration
  function _notifyRewardWithoutPeriodChange(uint256 _amount, address _rewardToken) internal {
    _updateRewards(address(0));
    require(_getRewardTokenIndex(_rewardToken) != type(uint256).max, "SV: RT not found");
    if (_amount > 1 && _amount < type(uint256).max / 1e18) {
      rewardPerTokenStoredForToken[_rewardToken] = _rewardPerToken(_rewardToken);
      lastUpdateTimeForToken[_rewardToken] = _lastTimeRewardApplicable(_rewardToken);
      if (block.timestamp >= periodFinishForToken[_rewardToken]) {
        // if vesting ended transfer the change to the controller
        // otherwise we will have possible infinity rewards duration
        IERC20(_rewardToken).safeTransfer(_controller(), _amount);
        emit RewardSentToController(_rewardToken, _amount);
      } else {
        uint256 remaining = periodFinishForToken[_rewardToken] - block.timestamp;
        uint256 leftover = remaining * rewardRateForToken[_rewardToken];
        rewardRateForToken[_rewardToken] = (_amount + leftover) / remaining;
        emit RewardRecirculated(_rewardToken, _amount);
      }
    }
  }

  /// @notice Disable strategy and move rewards to controller
  function stop() external override {
    _onlyVaultController(msg.sender);
    IStrategy(_strategy()).withdrawAllToVault();
    _setActive(false);

    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      address rt = _rewardTokens[i];
      periodFinishForToken[rt] = block.timestamp;
      rewardRateForToken[rt] = 0;
      uint256 amount = IERC20(rt).balanceOf(address(this));
      if (amount != 0) {
        IERC20(rt).safeTransfer(_controller(), amount);
      }
      emit RewardMovedToController(rt, amount);
    }
  }

  //**************** STRATEGY UPDATE FUNCTIONALITY ***********************

  /// @notice Check the strategy time lock, withdraw all to the vault and change the strategy
  ///         Should be called via controller
  function setStrategy(address newStrategy) external override {
    // the main functionality moved to library for reduce contract size
    VaultLibrary.changeStrategy(_controller(), _underlying(), newStrategy, _strategy());
    emit StrategyChanged(newStrategy, _strategy());
    _setStrategy(newStrategy);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
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
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
    __Context_init_unchained();
    __ERC20_init_unchained(name_, symbol_);
  }

  function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
  unchecked {
    _approve(sender, _msgSender(), currentAllowance - amount);
  }

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
  unchecked {
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);
  }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
  unchecked {
    _balances[sender] = senderBalance - amount;
  }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
  unchecked {
    _balances[account] = accountBalance - amount;
  }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
  uint256[45] private __gap;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/ISmartVault.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If you will change a key value it will require setup it again
///      Implements IVault interface for reducing code base
/// @author belbix
abstract contract VaultStorage is Initializable, ISmartVault {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;
  mapping(bytes32 => bool) private boolStorage;

  /// @notice Boolean value changed the variable with `name`
  event UpdatedBoolSlot(string indexed name, bool oldValue, bool newValue);
  /// @notice Address changed the variable with `name`
  event UpdatedAddressSlot(string indexed name, address oldValue, address newValue);
  /// @notice Value changed the variable with `name`
  event UpdatedUint256Slot(string indexed name, uint256 oldValue, uint256 newValue);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  /// @param _underlyingToken Vault underlying token
  /// @param _durationValue Reward vesting period
  function initializeVaultStorage(
    address _underlyingToken,
    uint256 _durationValue,
    bool __lockAllowed
  ) public initializer {
    _setUnderlying(_underlyingToken);
    _setDuration(_durationValue);
    _setActive(true);
    // no way to change it after initialisation for avoiding risks of misleading users
    setBoolean("lockAllowed", __lockAllowed);
  }

  // ******************* SETTERS AND GETTERS **********************

  function _setStrategy(address _address) internal {
    emit UpdatedAddressSlot("strategy", _strategy(), _address);
    setAddress("strategy", _address);
  }

  /// @notice Current strategy that vault use for farming
  function strategy() external override view returns (address) {
    return _strategy();
  }

  function _strategy() internal view returns (address) {
    return getAddress("strategy");
  }

  function _setUnderlying(address _address) private {
    emit UpdatedAddressSlot("underlying", _underlying(), _address);
    setAddress("underlying", _address);
  }

  /// @notice Vault underlying
  function underlying() external view override returns (address) {
    return _underlying();
  }

  function _underlying() internal view returns (address) {
    return getAddress("underlying");
  }


  function _setDuration(uint256 _value) internal {
    emit UpdatedUint256Slot("duration", duration(), _value);
    setUint256("duration", _value);
  }

  /// @notice Rewards vesting period
  function duration() public view override returns (uint256) {
    return getUint256("duration");
  }

  function _setActive(bool _value) internal {
    emit UpdatedBoolSlot("active", _active(), _value);
    setBoolean("active", _value);
  }

  /// @notice Vault status
  function active() external view override returns (bool) {
    return _active();
  }

  function _active() internal view returns (bool) {
    return getBoolean("active");
  }

  function _setPpfsDecreaseAllowed(bool _value) internal {
    emit UpdatedBoolSlot("ppfsDecreaseAllowed", ppfsDecreaseAllowed(), _value);
    setBoolean("ppfsDecreaseAllowed", _value);
  }

  /// @notice Vault status
  function ppfsDecreaseAllowed() public view override returns (bool) {
    return getBoolean("ppfsDecreaseAllowed");
  }

  function _setLockPeriod(uint256 _value) internal {
    emit UpdatedUint256Slot("lockPeriod", lockPeriod(), _value);
    setUint256("lockPeriod", _value);
  }

  /// @notice Deposit lock period
  function lockPeriod() public view override returns (uint256) {
    return getUint256("lockPeriod");
  }

  function _setLockPenalty(uint256 _value) internal {
    emit UpdatedUint256Slot("lockPenalty", lockPenalty(), _value);
    setUint256("lockPenalty", _value);
  }

  /// @notice Base penalty if funds locked
  function lockPenalty() public view override returns (uint256) {
    return getUint256("lockPenalty");
  }

  function _disableLock() internal {
    emit UpdatedBoolSlot("lockAllowed", _lockAllowed(), false);
    setBoolean("lockAllowed", false);
  }

  /// @notice Lock functionality allowed for this contract or not
  function lockAllowed() external view override returns (bool) {
    return _lockAllowed();
  }

  function _lockAllowed() internal view returns (bool) {
    return getBoolean("lockAllowed");
  }

  function _setToInvest(uint256 _value) internal {
    emit UpdatedUint256Slot("toInvest", _toInvest(), _value);
    setUint256("toInvest", _value);
  }

  function toInvest() external view override returns (uint256) {
    return _toInvest();
  }

  function _toInvest() internal view returns (uint256) {
    return getUint256("toInvest");
  }

  function _setReentrantLock(bool _value) internal {
    setBoolean("reentrantLock", _value);
  }

  /// @notice Vault status
  function _reentrantLock() internal view returns (bool) {
    return getBoolean("reentrantLock");
  }

  function _setDepositFeeNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("depositFeeNumerator", _depositFeeNumerator(), _value);
    setUint256("depositFeeNumerator", _value);
  }

  function depositFeeNumerator() external view override returns (uint256) {
    return getUint256("depositFeeNumerator");
  }

  function _depositFeeNumerator() internal view returns (uint256) {
    return getUint256("depositFeeNumerator");
  }

  function _setProtectionMode(bool _value) internal {
    emit UpdatedBoolSlot("protectionMode", _protectionMode(), _value);
    setBoolean("protectionMode", _value);
  }

  /// @notice Protection mode means claim rewards on withdraw and 0% initial reward boost
  function protectionMode() external view override returns (bool) {
    return _protectionMode();
  }

  function _protectionMode() internal view returns (bool) {
    return getBoolean("protectionMode");
  }

  function _setDoHardWorkOnInvest(bool _value) internal {
    emit UpdatedBoolSlot("hw_inv", _doHardWorkOnInvest(), _value);
    setBoolean("hw_inv", _value);
  }

  /// @dev Returns doHardWorkOnInvest mode status
  function doHardWorkOnInvest() external view override returns (bool) {
    return _doHardWorkOnInvest();
  }

  function _doHardWorkOnInvest() internal view returns (bool) {
    return getBoolean("hw_inv");
  }

  function _setAlwaysInvest(bool _value) internal {
    emit UpdatedBoolSlot("alwaysInvest", _alwaysInvest(), _value);
    setBoolean("alwaysInvest", _value);
  }

  /// @dev Returns doHardWorkOnInvest mode status
  function alwaysInvest() external view override returns (bool) {
    return _doHardWorkOnInvest();
  }

  function _alwaysInvest() internal view returns (bool) {
    return getBoolean("alwaysInvest");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setBoolean(string memory key, bool _value) private {
    boolStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getBoolean(string memory key) private view returns (bool) {
    return boolStorage[keccak256(abi.encodePacked(key))];
  }

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  //slither-disable-next-line unused-state
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../openzeppelin/Math.sol";
import "../interface/IStrategy.sol";
import "../interface/IControllable.sol";
import "../interface/IController.sol";
import "../interface/IVaultController.sol";
import "../interface/IBookkeeper.sol";

/// @title Library for SmartVault
/// @author belbix
library VaultLibrary {
  using SafeERC20 for IERC20;

  // !!! CONSTANTS MUST BE THE SAME AS IN SMART VAULT !!!
  uint private constant TO_INVEST_DENOMINATOR = 1000;
  uint private constant LOCK_PENALTY_DENOMINATOR = 1000;

  /// @dev Do necessary checks and prepare a strategy for installing
  function changeStrategy(
    address controller,
    address underlying,
    address newStrategy,
    address oldStrategy
  ) public {
    require(controller == msg.sender, "SV: Not controller");
    require(newStrategy != address(0), "SV: Zero new strategy");
    require(IStrategy(newStrategy).underlying() == address(underlying), "SV: Wrong strategy underlying");
    require(IStrategy(newStrategy).vault() == address(this), "SV: Wrong strategy vault");
    require(IControllable(newStrategy).isController(controller), "SV: Wrong strategy controller");
    require(newStrategy != oldStrategy, "SV: The same strategy");

    if (oldStrategy != address(0)) {// if the original strategy is defined
      IERC20(underlying).safeApprove(address(oldStrategy), 0);
      IStrategy(oldStrategy).withdrawAllToVault();
    }
    IERC20(underlying).safeApprove(newStrategy, 0);
    IERC20(underlying).safeApprove(newStrategy, type(uint).max);
    IController(controller).addStrategy(newStrategy);
  }

  /// @notice Returns amount of the underlying asset ready to invest to the strategy
  function availableToInvestOut(
    address strategy,
    uint toInvest,
    uint underlyingBalanceInVault
  ) public view returns (uint) {
    if (strategy == address(0)) {
      return 0;
    }
    uint wantInvestInTotal = underlyingBalanceWithInvestment(strategy, underlyingBalanceInVault)
    * toInvest / TO_INVEST_DENOMINATOR;
    uint alreadyInvested = IStrategy(strategy).investedUnderlyingBalance();
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint remainingToInvest = wantInvestInTotal - alreadyInvested;
      return remainingToInvest <= underlyingBalanceInVault
      ? remainingToInvest : underlyingBalanceInVault;
    }
  }

  /// @dev It is a part of withdrawing process.
  ///      Do necessary calculation for withdrawing from strategy and move funds to vault
  function processWithdrawFromStrategy(
    uint numberOfShares,
    address underlying,
    uint totalSupply,
    uint toInvest,
    address strategy
  ) public returns (uint) {
    uint underlyingBalanceInVault = IERC20(underlying).balanceOf(address(this));
    uint underlyingAmountToWithdraw =
    underlyingBalanceWithInvestment(strategy, underlyingBalanceInVault)
    * numberOfShares / totalSupply;
    if (underlyingAmountToWithdraw > underlyingBalanceInVault) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy).withdrawAllToVault();
      } else {
        uint strategyBalance = IStrategy(strategy).investedUnderlyingBalance();
        // we should always have buffer amount inside the vault
        uint missing = (strategyBalance + underlyingBalanceInVault)
        * (TO_INVEST_DENOMINATOR - toInvest)
        / TO_INVEST_DENOMINATOR
        + underlyingAmountToWithdraw;
        missing = Math.min(missing, strategyBalance);
        if (missing > 0) {
          IStrategy(strategy).withdrawToVault(missing);
        }
      }
      underlyingBalanceInVault = IERC20(underlying).balanceOf(address(this));
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = Math.min(
        underlyingBalanceWithInvestment(strategy, underlyingBalanceInVault)
        * numberOfShares / totalSupply,
        underlyingBalanceInVault
      );
    }
    return underlyingAmountToWithdraw;
  }

  /// @notice Returns the current underlying (e.g., DAI's) balance together with
  ///         the invested amount (if DAI is invested elsewhere by the strategy).
  function underlyingBalanceWithInvestment(
    address strategy,
    uint underlyingBalanceInVault
  ) internal view returns (uint256) {
    if (address(strategy) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault;
    }
    return underlyingBalanceInVault + IStrategy(strategy).investedUnderlyingBalance();
  }

  /// @dev Locking logic will add a part of locked shares as rewards for this vault
  ///      Calculate locked amount for using in the main logic
  function calculateLockedAmount(
    uint numberOfShares,
    mapping(address => uint) storage userLockTs,
    uint lockPeriod,
    uint lockPenalty,
    uint userBalance
  ) public returns (uint numberOfSharesAdjusted, uint lockedSharesToReward) {
    numberOfSharesAdjusted = numberOfShares;
    uint lockStart = userLockTs[msg.sender];
    // refresh lock time
    // if full withdraw set timer to 0
    if (userBalance == numberOfSharesAdjusted) {
      userLockTs[msg.sender] = 0;
    } else {
      userLockTs[msg.sender] = block.timestamp;
    }
    if (lockStart != 0 && lockStart < block.timestamp) {
      uint currentLockDuration = block.timestamp - lockStart;
      if (currentLockDuration < lockPeriod) {
        uint sharesBase = numberOfSharesAdjusted
        * (LOCK_PENALTY_DENOMINATOR - lockPenalty)
        / LOCK_PENALTY_DENOMINATOR;
        uint toWithdraw = sharesBase + (
        ((numberOfSharesAdjusted - sharesBase) * currentLockDuration) / lockPeriod
        );
        lockedSharesToReward = numberOfSharesAdjusted - toWithdraw;
        numberOfSharesAdjusted = toWithdraw;
      }
    }
    return (numberOfSharesAdjusted, lockedSharesToReward);
  }

  /// @notice Return amount ready to claim, calculated with actual boost.
  ///         Accurate value returns only after updateRewards call.
  function earnedWithBoost(
    address rt,
    uint reward,
    uint boostStart,
    address controller,
    bool protectionMode
  ) public view returns (uint) {
    // if we don't have a record we assume that it was deposited before boost logic and use 100% boost
    if (_isBoostProtected(controller, rt) && boostStart != 0 && boostStart < block.timestamp) {
      uint currentBoostDuration = block.timestamp - boostStart;
      // not 100% boost
      IVaultController _vaultController = IVaultController(IController(controller).vaultController());
      uint boostDuration = _vaultController.rewardBoostDuration();
      uint rewardRatioWithoutBoost = _vaultController.rewardRatioWithoutBoost();
      if (protectionMode) {
        rewardRatioWithoutBoost = 0;
      }
      if (currentBoostDuration < boostDuration) {
        uint rewardWithoutBoost = reward * rewardRatioWithoutBoost / 100;
        // calculate boosted part of rewards
        reward = rewardWithoutBoost + (
        (reward - rewardWithoutBoost) * currentBoostDuration / boostDuration
        );
      }
    }
    return reward;
  }

  /// @notice Transfer earned rewards to caller
  /// @notice for backward compatibility with SmartVaultV110
  function processPayReward(
    address rt,
    uint reward,
    mapping(address => uint256) storage userBoostTs,
    address controller,
    bool protectionMode,
    mapping(address => mapping(address => uint256)) storage rewardsForToken
  ) public returns (uint renotifiedAmount, uint paidReward) {
    return processPayRewardFor(rt, reward, userBoostTs, controller, protectionMode, rewardsForToken, msg.sender, msg.sender);
  }

  /// @notice Transfer earned rewards to rewardsReceiver
  function processPayRewardFor(
    address rt,
    uint reward,
    mapping(address => uint256) storage userBoostTs,
    address controller,
    bool protectionMode,
    mapping(address => mapping(address => uint256)) storage rewardsForToken,
    address owner,
    address receiver
  ) public returns (uint renotifiedAmount, uint paidReward) {
    paidReward = reward;
    if (paidReward > 0 && IERC20(rt).balanceOf(address(this)) >= paidReward) {
      // calculate boosted amount
      uint256 boostStart = userBoostTs[owner];
      // refresh boost
      userBoostTs[owner] = block.timestamp;
      // if we don't have a record we assume that it was deposited before boost logic and use 100% boost
      // allow claim without penalty to some addresses, TetuSwap pairs as example
      if (
        _isBoostProtected(controller, rt)
        && boostStart != 0
        && boostStart < block.timestamp
        && !IController(controller).isPoorRewardConsumer(owner)
      ) {
        uint256 currentBoostDuration = block.timestamp - boostStart;
        IVaultController _vaultController = IVaultController(IController(controller).vaultController());
        // not 100% boost
        uint256 boostDuration = _vaultController.rewardBoostDuration();
        uint256 rewardRatioWithoutBoost = _vaultController.rewardRatioWithoutBoost();
        if (protectionMode) {
          rewardRatioWithoutBoost = 0;
        }
        if (currentBoostDuration < boostDuration) {
          uint256 rewardWithoutBoost = paidReward * rewardRatioWithoutBoost / 100;
          // calculate boosted part of rewards
          uint256 toClaim = rewardWithoutBoost + (
          (paidReward - rewardWithoutBoost) * currentBoostDuration / boostDuration
          );
          renotifiedAmount = paidReward - toClaim;
          paidReward = toClaim;
          // notify reward should be called in vault
        }
      }

      rewardsForToken[rt][owner] = 0;
      IERC20(rt).safeTransfer(receiver, paidReward);
      // only statistic, should not affect reward claim process
      try IBookkeeper(IController(controller).bookkeeper())
      .registerUserEarned(owner, address(this), rt, paidReward) {
      } catch {}
    }
    return (renotifiedAmount, paidReward);
  }

  function _isBoostProtected(address controller, address token) internal view returns (bool){
    return IController(controller).rewardToken() == token || IController(controller).psVault() == token;
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IControllableExtended.sol";
import "../interface/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
///        V2 is optimised version for less gas consumption
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract ControllableV2 is Initializable, IControllable, IControllableExtended {

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _setController(__controller);
    _setCreated(block.timestamp);
    _setCreatedBlock(block.number);
    emit ContractInitialized(__controller, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  function _setController(address _newController) private {
    require(_newController != address(0));
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view override returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.timestamp
  function _setCreated(uint256 _value) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

  /// @notice Return creation block number
  /// @return ts Creation block number
  function createdBlock() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.number
  function _setCreatedBlock(uint256 _value) private {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategy {

  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT, //26
    BEETHOVEN, //27
    IMPERMAX, //28
    TETU_SF, //29
    ALPACA, //30
    MARKET, //31
    UNIVERSE, //32
    MAI_BAL, //33
    UMA, //34
    SPHERE, //35
    BALANCER, //36
    OTTERCLAM, //37
    MESH, //38
    D_FORCE, //39
    DYSTOPIA, //40
    CONE, //41
    SLOT_42, //42
    SLOT_43, //43
    SLOT_44, //44
    SLOT_45, //45
    SLOT_46, //46
    SLOT_47, //47
    SLOT_48, //48
    SLOT_49, //49
    SLOT_50 //50
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {


  function VERSION() external view returns (string memory);

  function addHardWorker(address _worker) external;

  function addStrategiesToSplitter(
    address _splitter,
    address[] memory _strategies
  ) external;

  function addStrategy(address _strategy) external;

  function addVaultsAndStrategies(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function announcer() external view returns (address);

  function bookkeeper() external view returns (address);

  function changeWhiteListStatus(address[] memory _targets, bool status)
  external;

  function controllerTokenMove(
    address _recipient,
    address _token,
    uint256 _amount
  ) external;

  function dao() external view returns (address);

  function distributor() external view returns (address);

  function doHardWork(address _vault) external;

  function feeRewardForwarder() external view returns (address);

  function fund() external view returns (address);

  function fundDenominator() external view returns (uint256);

  function fundKeeperTokenMove(
    address _fund,
    address _token,
    uint256 _amount
  ) external;

  function fundNumerator() external view returns (uint256);

  function fundToken() external view returns (address);

  function governance() external view returns (address);

  function hardWorkers(address) external view returns (bool);

  function initialize() external;

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function mintAndDistribute(uint256 totalAmount, bool mintAllAvailable)
  external;

  function mintHelper() external view returns (address);

  function psDenominator() external view returns (uint256);

  function psNumerator() external view returns (uint256);

  function psVault() external view returns (address);

  function pureRewardConsumers(address) external view returns (bool);

  function rebalance(address _strategy) external;

  function removeHardWorker(address _worker) external;

  function rewardDistribution(address) external view returns (bool);

  function rewardToken() external view returns (address);

  function setAnnouncer(address _newValue) external;

  function setBookkeeper(address newValue) external;

  function setDao(address newValue) external;

  function setDistributor(address _distributor) external;

  function setFeeRewardForwarder(address _feeRewardForwarder) external;

  function setFund(address _newValue) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setFundToken(address _newValue) external;

  function setGovernance(address newValue) external;

  function setMintHelper(address _newValue) external;

  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator)
  external;

  function setPsVault(address _newValue) external;

  function setPureRewardConsumers(address[] memory _targets, bool _flag)
  external;

  function setRewardDistribution(
    address[] memory _newRewardDistribution,
    bool _flag
  ) external;

  function setRewardToken(address _newValue) external;

  function setVaultController(address _newValue) external;

  function setVaultStrategyBatch(
    address[] memory _vaults,
    address[] memory _strategies
  ) external;

  function strategies(address) external view returns (bool);

  function strategyTokenMove(
    address _strategy,
    address _token,
    uint256 _amount
  ) external;

  function upgradeTetuProxyBatch(
    address[] memory _contracts,
    address[] memory _implementations
  ) external;

  function vaultController() external view returns (address);

  function vaults(address) external view returns (bool);

  function whiteList(address) external view returns (bool);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function _vaults(uint id) external view returns (address);

  function _strategies(uint id) external view returns (address);

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param strategy Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address strategy) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address strategy) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IVaultController {

  function rewardBoostDuration() external view returns (uint256);

  function rewardRatioWithoutBoost() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    assembly {
      size := extcodesize(account)
    }
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

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
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
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
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
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
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
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
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
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal initializer {
    __Context_init_unchained();
  }

  function __Context_init_unchained() internal initializer {
  }
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function alwaysInvest() external view returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function disableLock() external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account)
  external
  view
  returns (uint256);

  function earnedWithBoost(address rt, address account)
  external
  view
  returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsAndRedirect(address owner) external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function lastTimeRewardApplicable(address rt)
  external
  view
  returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function notifyRewardWithoutPeriodChange(
    address _rewardToken,
    uint256 _amount
  ) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount)
  external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address)
  external
  view
  returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setRewardsRedirect(address owner, address receiver) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function toInvest() external view returns (uint256);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder)
  external
  view
  returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address)
  external
  view
  returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function lockPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend the exist Controllable for the reason of huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}