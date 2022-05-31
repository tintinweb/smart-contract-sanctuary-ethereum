// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IDeltaNeutralOracle.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWorker02.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWNativeRelayer.sol";
import "./interfaces/IDeltaNeutralVaultConfig02.sol";
import "./interfaces/IFairLaunch.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IController.sol";

import "./utils/SafeToken.sol";
import "./utils/FixedPointMathLib.sol";
import "./utils/Math.sol";
import "./utils/FullMath.sol";

/// @title DeltaNeutralVault02 is designed to take a long and short position in an asset at the same time
/// to cancel out the effect on the out-standing portfolio when the asset’s price moves.
/// Moreover, DeltaNeutralVault02 support credit-dependent limit access
// solhint-disable max-states-count
contract DeltaNeutralVault02 is ERC20Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  // --- Libraries ---
  using FixedPointMathLib for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // --- Events ---
  event LogInitializePositions(address indexed _from, uint256 _stableVaultPosId, uint256 _assetVaultPosId);
  event LogDeposit(
    address indexed _from,
    address indexed _shareReceiver,
    uint256 _shares,
    uint256 _stableTokenAmount,
    uint256 _assetTokenAmount
  );
  event LogWithdraw(address indexed _shareOwner, uint256 _minStableTokenAmount, uint256 _minAssetTokenAmount);
  event LogRebalance(uint256 _equityBefore, uint256 _equityAfter);
  event LogReinvest(uint256 _equityBefore, uint256 _equityAfter);
  event LogSetDeltaNeutralOracle(address indexed _caller, address _priceOracle);
  event LogSetDeltaNeutralVaultConfig(address indexed _caller, address _config);

  // --- Errors ---
  error DeltaNeutralVault_BadReinvestPath();
  error DeltaNeutralVault_BadActionSize();
  error DeltaNeutralVault_Unauthorized(address _caller);
  error DeltaNeutralVault_PositionsAlreadyInitialized();
  error DeltaNeutralVault_PositionsNotInitialized();
  error DeltaNeutralVault_InvalidPositions(address _vault, uint256 _positionId);
  error DeltaNeutralVault_UnsafePositionEquity();
  error DeltaNeutralVault_UnsafePositionValue();
  error DeltaNeutralVault_UnsafeDebtValue();
  error DeltaNeutralVault_UnsafeDebtRatio();
  error DeltaNeutralVault_UnsafeOutstanding(address _token, uint256 _amountBefore, uint256 _amountAfter);
  error DeltaNeutralVault_PositionsIsHealthy();
  error DeltaNeutralVault_InsufficientTokenReceived(address _token, uint256 _requiredAmount, uint256 _receivedAmount);
  error DeltaNeutralVault_InsufficientShareReceived(uint256 _requiredAmount, uint256 _receivedAmount);
  error DeltaNeutralVault_UnTrustedPrice();
  error DeltaNeutralVault_PositionValueExceedLimit();
  error DeltaNeutralVault_WithdrawValueExceedShareValue(uint256 _withdrawValue, uint256 _shareValue);
  error DeltaNeutralVault_IncorrectNativeAmountDeposit();
  error DeltaNeutralVault_InvalidLpToken();
  error DeltaNeutralVault_InvalidInitializedAddress();
  error DeltaNeutralVault_UnsupportedDecimals(uint256 _decimals);
  error DeltaNeutralVault_InvalidShareAmount();
  error DeltaNeutralVault_ExceedCredit();

  struct Outstanding {
    uint256 stableAmount;
    uint256 assetAmount;
    uint256 nativeAmount;
  }

  struct PositionInfo {
    uint256 stablePositionEquity;
    uint256 stablePositionDebtValue;
    uint256 stableLpAmount;
    uint256 assetPositionEquity;
    uint256 assetPositionDebtValue;
    uint256 assetLpAmount;
  }

  // --- Constants ---
  uint64 private constant MAX_BPS = 10000;

  uint8 private constant ACTION_WORK = 1;
  uint8 private constant ACTION_WRAP = 2;

  // --- States ---

  uint256 public stableTo18ConversionFactor;
  uint256 public assetTo18ConversionFactor;

  address private lpToken;
  address public stableVault;
  address public assetVault;

  address public stableVaultWorker;
  address public assetVaultWorker;

  address public stableToken;
  address public assetToken;
  address public alpacaToken;

  uint256 public stableVaultPosId;
  uint256 public assetVaultPosId;

  uint256 public lastFeeCollected;

  IDeltaNeutralOracle public priceOracle;

  IDeltaNeutralVaultConfig02 public config;

  // --- Mutable ---
  uint8 private OPENING;

  /// @dev Require that the caller must be an EOA account if not whitelisted.
  modifier onlyEOAorWhitelisted() {
    if (msg.sender != tx.origin && !config.whitelistedCallers(msg.sender)) {
      revert DeltaNeutralVault_Unauthorized(msg.sender);
    }
    _;
  }

  /// @dev Require that the caller must be a rebalancer account.
  modifier onlyRebalancers() {
    if (!config.whitelistedRebalancers(msg.sender)) revert DeltaNeutralVault_Unauthorized(msg.sender);
    _;
  }

  /// @dev Require that the caller must be a reinvestor account.
  modifier onlyReinvestors() {
    if (!config.whitelistedReinvestors(msg.sender)) revert DeltaNeutralVault_Unauthorized(msg.sender);
    _;
  }

  /// @dev Collect management fee before interactions
  modifier collectFee() {
    _mintFee();
    _;
  }

  constructor() initializer {}

  /// @notice Initialize Delta Neutral vault.
  /// @param _name Name.
  /// @param _symbol Symbol.
  /// @param _stableVault Address of stable vault.
  /// @param _assetVault Address of asset vault.
  /// @param _stableVaultWorker Address of stable worker.
  /// @param _stableVaultWorker Address of asset worker.
  /// @param _lpToken Address stable and asset token pair.
  /// @param _alpacaToken Alpaca token address.
  /// @param _priceOracle DeltaNeutralOracle address.
  /// @param _config The address of delta neutral vault config.
  function initialize(
    string calldata _name,
    string calldata _symbol,
    address _stableVault,
    address _assetVault,
    address _stableVaultWorker,
    address _assetVaultWorker,
    address _lpToken,
    address _alpacaToken,
    IDeltaNeutralOracle _priceOracle,
    IDeltaNeutralVaultConfig02 _config
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    ERC20Upgradeable.__ERC20_init(_name, _symbol);

    stableVault = _stableVault;
    assetVault = _assetVault;

    stableToken = IVault(_stableVault).token();
    assetToken = IVault(_assetVault).token();
    alpacaToken = _alpacaToken;

    stableVaultWorker = _stableVaultWorker;
    assetVaultWorker = _assetVaultWorker;

    lpToken = _lpToken;

    priceOracle = _priceOracle;
    config = _config;

    stableTo18ConversionFactor = _to18ConversionFactor(stableToken);
    assetTo18ConversionFactor = _to18ConversionFactor(assetToken);

    // check if parameters config properly
    if (
      lpToken != address(IWorker(assetVaultWorker).lpToken()) ||
      lpToken != address(IWorker(stableVaultWorker).lpToken())
    ) {
      revert DeltaNeutralVault_InvalidLpToken();
    }
    if (address(alpacaToken) == address(0)) revert DeltaNeutralVault_InvalidInitializedAddress();
    if (address(priceOracle) == address(0)) revert DeltaNeutralVault_InvalidInitializedAddress();
    if (address(config) == address(0)) revert DeltaNeutralVault_InvalidInitializedAddress();
  }

  /// @notice initialize delta neutral vault positions.
  /// @param _stableTokenAmount Amount of stable token transfer to vault.
  /// @param _assetTokenAmount Amount of asset token transfer to vault.
  /// @param _minShareReceive Minimum share that _shareReceiver must receive.
  /// @param _data The calldata to pass along to the proxy action for more working context.
  function initPositions(
    uint256 _stableTokenAmount,
    uint256 _assetTokenAmount,
    uint256 _minShareReceive,
    bytes calldata _data
  ) external payable onlyOwner {
    if (stableVaultPosId != 0 || assetVaultPosId != 0) {
      revert DeltaNeutralVault_PositionsAlreadyInitialized();
    }

    OPENING = 1;
    stableVaultPosId = IVault(stableVault).nextPositionID();
    assetVaultPosId = IVault(assetVault).nextPositionID();
    deposit(_stableTokenAmount, _assetTokenAmount, msg.sender, _minShareReceive, _data);

    OPENING = 0;

    emit LogInitializePositions(msg.sender, stableVaultPosId, assetVaultPosId);
  }

  /// @notice Get token from msg.sender.
  /// @param _token token to transfer.
  /// @param _amount amount to transfer.
  function _transferTokenToVault(address _token, uint256 _amount) internal {
    if (_token == config.getWrappedNativeAddr()) {
      if (msg.value != _amount) {
        revert DeltaNeutralVault_IncorrectNativeAmountDeposit();
      }
      IWETH(_token).deposit{ value: _amount }();
    } else {
      IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }
  }

  /// @notice return token to share owenr.
  /// @param _to receiver address.
  /// @param _token token to transfer.
  /// @param _amount amount to transfer.
  function _transferTokenToShareOwner(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    if (_token == config.getWrappedNativeAddr()) {
      SafeToken.safeTransferETH(_to, _amount);
    } else {
      IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }
  }

  /// @notice minting shares as a form of management fee to teasury account
  function _mintFee() internal {
    _mint(config.managementFeeTreasury(), pendingManagementFee());
    lastFeeCollected = block.timestamp;
  }

  /// @notice Return amount of share pending for minting as a form of management fee
  function pendingManagementFee() public view returns (uint256) {
    uint256 _secondsFromLastCollection = block.timestamp - lastFeeCollected;
    return (totalSupply() * config.managementFeePerSec() * _secondsFromLastCollection) / 1e18;
  }

  /// @notice Deposit to delta neutral vault.
  /// @param _stableTokenAmount Amount of stable token transfer to vault.
  /// @param _assetTokenAmount Amount of asset token transfer to vault.
  /// @param _shareReceiver Addresses to be receive share.
  /// @param _minShareReceive Minimum share that _shareReceiver must receive.
  /// @param _data The calldata to pass along to the proxy action for more working context.
  function deposit(
    uint256 _stableTokenAmount,
    uint256 _assetTokenAmount,
    address _shareReceiver,
    uint256 _minShareReceive,
    bytes calldata _data
  ) public payable onlyEOAorWhitelisted collectFee nonReentrant returns (uint256) {
    PositionInfo memory _positionInfoBefore = positionInfo();
    Outstanding memory _outstandingBefore = _outstanding();
    _outstandingBefore.nativeAmount = _outstandingBefore.nativeAmount - msg.value;
    // 1. transfer tokens from user to vault
    _transferTokenToVault(stableToken, _stableTokenAmount);
    _transferTokenToVault(assetToken, _assetTokenAmount);
    {
      // 2. call execute to do more work.
      // Perform the actual work, using a new scope to avoid stack-too-deep errors.
      (uint8[] memory _actions, uint256[] memory _values, bytes[] memory _datas) = abi.decode(
        _data,
        (uint8[], uint256[], bytes[])
      );
      _execute(_actions, _values, _datas);
    }
    return
      _checkAndMint(
        _stableTokenAmount,
        _assetTokenAmount,
        _shareReceiver,
        _minShareReceive,
        _positionInfoBefore,
        _outstandingBefore
      );
  }

  function _checkAndMint(
    uint256 _stableTokenAmount,
    uint256 _assetTokenAmount,
    address _shareReceiver,
    uint256 _minShareReceive,
    PositionInfo memory _positionInfoBefore,
    Outstanding memory _outstandingBefore
  ) internal returns (uint256) {
    // continued from deposit as we're getting stack too deep
    // 3. mint share for shareReceiver
    PositionInfo memory _positionInfoAfter = positionInfo();
    uint256 _depositValue = _calculateEquityChange(_positionInfoAfter, _positionInfoBefore);

    // For private vault, deposit value should not exeed credit
    // Check availableCredit from msg.sender since user interact with contract directly
    IController _controller = IController(config.controller());
    if (address(_controller) != address(0) && _depositValue > _controller.availableCredit(msg.sender)) {
      revert DeltaNeutralVault_ExceedCredit();
    }

    // Calculate share from the value gain against the total equity before execution of actions
    uint256 _sharesToUser = _valueToShare(
      _depositValue,
      _positionInfoBefore.stablePositionEquity + _positionInfoBefore.assetPositionEquity
    );

    if (_sharesToUser < _minShareReceive) {
      revert DeltaNeutralVault_InsufficientShareReceived(_minShareReceive, _sharesToUser);
    }
    _mint(_shareReceiver, _sharesToUser);

    // 4. sanity check
    _depositHealthCheck(_depositValue, _positionInfoBefore, _positionInfoAfter);
    _outstandingCheck(_outstandingBefore, _outstanding());

    // Deduct credit from msg.sender regardless of the _shareReceiver.
    if (address(_controller) != address(0)) _controller.onDeposit(msg.sender, _sharesToUser);

    emit LogDeposit(msg.sender, _shareReceiver, _sharesToUser, _stableTokenAmount, _assetTokenAmount);
    return _sharesToUser;
  }

  /// @notice Withdraw from delta neutral vault.
  /// @param _shareAmount Amount of share to withdraw from vault.
  /// @param _minStableTokenAmount Minimum stable token shareOwner expect to receive.
  /// @param _minAssetTokenAmount Minimum asset token shareOwner expect to receive.
  /// @param _data The calldata to pass along to the proxy action for more working context.
  function withdraw(
    uint256 _shareAmount,
    uint256 _minStableTokenAmount,
    uint256 _minAssetTokenAmount,
    bytes calldata _data
  ) external onlyEOAorWhitelisted collectFee nonReentrant returns (uint256) {
    if (_shareAmount == 0) revert DeltaNeutralVault_InvalidShareAmount();

    PositionInfo memory _positionInfoBefore = positionInfo();
    Outstanding memory _outstandingBefore = _outstanding();

    uint256 _withdrawalFeeBps = config.feeExemptedCallers(msg.sender) ? 0 : config.withdrawalFeeBps();
    uint256 _shareToWithdraw = ((MAX_BPS - _withdrawalFeeBps) * _shareAmount) / MAX_BPS;
    uint256 _withdrawShareValue = shareToValue(_shareToWithdraw);

    // burn shares from share owner
    _burn(msg.sender, _shareAmount);

    // mint shares equal to withdrawal fee to treasury.
    _mint(config.withdrawalFeeTreasury(), _shareAmount - _shareToWithdraw);

    {
      (uint8[] memory actions, uint256[] memory values, bytes[] memory _datas) = abi.decode(
        _data,
        (uint8[], uint256[], bytes[])
      );
      _execute(actions, values, _datas);
    }

    return
      _checkAndTransfer(
        _shareAmount,
        _minStableTokenAmount,
        _minAssetTokenAmount,
        _withdrawShareValue,
        _positionInfoBefore,
        _outstandingBefore
      );
  }

  function _checkAndTransfer(
    uint256 _shareAmount,
    uint256 _minStableTokenAmount,
    uint256 _minAssetTokenAmount,
    uint256 _withdrawShareValue,
    PositionInfo memory _positionInfoBefore,
    Outstanding memory _outstandingBefore
  ) internal returns (uint256) {
    PositionInfo memory _positionInfoAfter = positionInfo();
    Outstanding memory _outstandingAfter = _outstanding();

    // transfer funds back to shareOwner
    uint256 _stableTokenBack = stableToken == config.getWrappedNativeAddr()
      ? _outstandingAfter.nativeAmount - _outstandingBefore.nativeAmount
      : _outstandingAfter.stableAmount - _outstandingBefore.stableAmount;
    uint256 _assetTokenBack = assetToken == config.getWrappedNativeAddr()
      ? _outstandingAfter.nativeAmount - _outstandingBefore.nativeAmount
      : _outstandingAfter.assetAmount - _outstandingBefore.assetAmount;

    if (_stableTokenBack < _minStableTokenAmount) {
      revert DeltaNeutralVault_InsufficientTokenReceived(stableToken, _minStableTokenAmount, _stableTokenBack);
    }
    if (_assetTokenBack < _minAssetTokenAmount) {
      revert DeltaNeutralVault_InsufficientTokenReceived(assetToken, _minAssetTokenAmount, _assetTokenBack);
    }

    uint256 _withdrawValue = _calculateEquityChange(_positionInfoBefore, _positionInfoAfter);

    if (_withdrawShareValue < _withdrawValue) {
      revert DeltaNeutralVault_WithdrawValueExceedShareValue(_withdrawValue, _withdrawShareValue);
    }

    // sanity check
    _withdrawHealthCheck(_withdrawShareValue, _positionInfoBefore, _positionInfoAfter);
    _outstandingCheck(_outstandingBefore, _outstandingAfter);

    _transferTokenToShareOwner(msg.sender, stableToken, _stableTokenBack);
    _transferTokenToShareOwner(msg.sender, assetToken, _assetTokenBack);

    // on withdraw increase credit to tx.origin since user can withdraw from DN Gateway -> DN Vault
    IController _controller = IController(config.controller());
    if (address(_controller) != address(0)) _controller.onWithdraw(tx.origin, _shareAmount);

    emit LogWithdraw(msg.sender, _stableTokenBack, _assetTokenBack);

    return _withdrawValue;
  }

  /// @notice Rebalance stable and asset positions.
  /// @param _actions List of actions to execute.
  /// @param _values Native token amount.
  /// @param _datas The calldata to pass along for more working context.
  function rebalance(
    uint8[] memory _actions,
    uint256[] memory _values,
    bytes[] memory _datas
  ) external onlyRebalancers collectFee {
    PositionInfo memory _positionInfoBefore = positionInfo();
    Outstanding memory _outstandingBefore = _outstanding();
    uint256 _stablePositionValue = _positionInfoBefore.stablePositionEquity +
      _positionInfoBefore.stablePositionDebtValue;
    uint256 _assetPositionValue = _positionInfoBefore.assetPositionEquity + _positionInfoBefore.assetPositionDebtValue;
    uint256 _equityBefore = _positionInfoBefore.stablePositionEquity + _positionInfoBefore.assetPositionEquity;
    uint256 _rebalanceFactor = config.rebalanceFactor(); // bps

    // 1. check if positions need rebalance
    if (
      _stablePositionValue * _rebalanceFactor >= _positionInfoBefore.stablePositionDebtValue * MAX_BPS &&
      _assetPositionValue * _rebalanceFactor >= _positionInfoBefore.assetPositionDebtValue * MAX_BPS
    ) {
      revert DeltaNeutralVault_PositionsIsHealthy();
    }

    // 2. execute rebalance
    {
      _execute(_actions, _values, _datas);
    }

    // 3. sanity check
    // check if position in a healthy state after rebalancing
    uint256 _equityAfter = totalEquityValue();
    if (!Math.almostEqual(_equityAfter, _equityBefore, config.positionValueTolerance())) {
      revert DeltaNeutralVault_UnsafePositionValue();
    }
    _outstandingCheck(_outstandingBefore, _outstanding());

    emit LogRebalance(_equityBefore, _equityAfter);
  }

  /// @notice Reinvest fund to stable and asset positions.
  /// @param _actions List of actions to execute.
  /// @param _values Native token amount.
  /// @param _datas The calldata to pass along for more working context.
  /// @param _minTokenReceive Minimum token received when swap reward.
  function reinvest(
    uint8[] memory _actions,
    uint256[] memory _values,
    bytes[] memory _datas,
    uint256 _minTokenReceive
  ) external onlyReinvestors {
    address[] memory reinvestPath = config.getReinvestPath();
    uint256 _alpacaBountyBps = config.alpacaBountyBps();
    uint256 _alpacaBeneficiaryBps = config.alpacaBeneficiaryBps();

    if (reinvestPath.length == 0) {
      revert DeltaNeutralVault_BadReinvestPath();
    }

    // 1.  claim reward from fairlaunch
    uint256 _equityBefore = totalEquityValue();

    address _fairLaunchAddress = config.fairLaunchAddr();
    IFairLaunch(_fairLaunchAddress).harvest(IVault(stableVault).fairLaunchPoolId());
    IFairLaunch(_fairLaunchAddress).harvest(IVault(assetVault).fairLaunchPoolId());
    uint256 _alpacaAmount = IERC20Upgradeable(alpacaToken).balanceOf(address(this));

    // 2. collect alpaca bounty & distribute to ALPACA beneficiary
    uint256 _bounty = (_alpacaBountyBps * _alpacaAmount) / MAX_BPS;
    uint256 _beneficiaryShare = (_bounty * _alpacaBeneficiaryBps) / MAX_BPS;
    if (_beneficiaryShare > 0)
      IERC20Upgradeable(alpacaToken).safeTransfer(config.alpacaBeneficiary(), _beneficiaryShare);
    IERC20Upgradeable(alpacaToken).safeTransfer(config.alpacaReinvestFeeTreasury(), _bounty - _beneficiaryShare);

    // 3. swap alpaca
    uint256 _rewardAmount = _alpacaAmount - _bounty;
    ISwapRouter _router = ISwapRouter(config.getSwapRouter());
    IERC20Upgradeable(alpacaToken).approve(address(_router), _rewardAmount);
    _router.swapExactTokensForTokens(_rewardAmount, _minTokenReceive, reinvestPath, address(this), block.timestamp);

    // 4. execute reinvest
    {
      _execute(_actions, _values, _datas);
    }

    // 5. sanity check
    uint256 _equityAfter = totalEquityValue();
    if (_equityAfter <= _equityBefore) {
      revert DeltaNeutralVault_UnsafePositionEquity();
    }

    emit LogReinvest(_equityBefore, _equityAfter);
  }

  /// @notice check if position equity and debt are healthy after deposit. LEVERAGE_LEVEL must be >= 3
  /// @param _depositValue deposit value in usd.
  /// @param _positionInfoBefore position equity and debt before deposit.
  /// @param _positionInfoAfter position equity and debt after deposit.
  function _depositHealthCheck(
    uint256 _depositValue,
    PositionInfo memory _positionInfoBefore,
    PositionInfo memory _positionInfoAfter
  ) internal view {
    uint256 _toleranceBps = config.positionValueTolerance();
    uint8 _leverageLevel = config.leverageLevel();

    uint256 _positionValueAfter = _positionInfoAfter.stablePositionEquity +
      _positionInfoAfter.stablePositionDebtValue +
      _positionInfoAfter.assetPositionEquity +
      _positionInfoAfter.assetPositionDebtValue;

    // 1. check if vault accept new total position value
    if (!config.isVaultSizeAcceptable(_positionValueAfter)) {
      revert DeltaNeutralVault_PositionValueExceedLimit();
    }

    // 2. check position value
    // The equity allocation of long side should be equal to _depositValue * (_leverageLevel - 2) / ((2*_leverageLevel) - 2)
    uint256 _expectedStableEqChange = (_depositValue * (_leverageLevel - 2)) / ((2 * _leverageLevel) - 2);
    // The equity allocation of short side should be equal to _depositValue * _leverageLevel / ((2*_leverageLevel) - 2)
    uint256 _expectedAssetEqChange = (_depositValue * _leverageLevel) / ((2 * _leverageLevel) - 2);

    uint256 _actualStableDebtChange = _positionInfoAfter.stablePositionDebtValue -
      _positionInfoBefore.stablePositionDebtValue;
    uint256 _actualAssetDebtChange = _positionInfoAfter.assetPositionDebtValue -
      _positionInfoBefore.assetPositionDebtValue;

    uint256 _actualStableEqChange = _lpToValue(_positionInfoAfter.stableLpAmount - _positionInfoBefore.stableLpAmount) -
      _actualStableDebtChange;
    uint256 _actualAssetEqChange = _lpToValue(_positionInfoAfter.assetLpAmount - _positionInfoBefore.assetLpAmount) -
      _actualAssetDebtChange;

    if (
      !Math.almostEqual(_actualStableEqChange, _expectedStableEqChange, _toleranceBps) ||
      !Math.almostEqual(_actualAssetEqChange, _expectedAssetEqChange, _toleranceBps)
    ) {
      revert DeltaNeutralVault_UnsafePositionEquity();
    }

    // 3. check Debt value
    // The debt allocation of long side should be equal to _expectedStableEqChange * (_leverageLevel - 1)
    uint256 _expectedStableDebtChange = (_expectedStableEqChange * (_leverageLevel - 1));
    // The debt allocation of short side should be equal to _expectedAssetEqChange * (_leverageLevel - 1)
    uint256 _expectedAssetDebtChange = (_expectedAssetEqChange * (_leverageLevel - 1));

    if (
      !Math.almostEqual(_actualStableDebtChange, _expectedStableDebtChange, _toleranceBps) ||
      !Math.almostEqual(_actualAssetDebtChange, _expectedAssetDebtChange, _toleranceBps)
    ) {
      revert DeltaNeutralVault_UnsafeDebtValue();
    }
  }

  /// @notice Check if position equity and debt ratio are healthy after withdraw.
  /// @param _withdrawValue Withdraw value in usd.
  /// @param _positionInfoBefore Position equity and debt before deposit.
  /// @param _positionInfoAfter Position equity and debt after deposit.
  function _withdrawHealthCheck(
    uint256 _withdrawValue,
    PositionInfo memory _positionInfoBefore,
    PositionInfo memory _positionInfoAfter
  ) internal view {
    uint256 _positionValueTolerance = config.positionValueTolerance();
    uint256 _debtRationTolerance = config.debtRatioTolerance();

    uint256 _totalEquityBefore = _positionInfoBefore.stablePositionEquity + _positionInfoBefore.assetPositionEquity;
    uint256 _stableLpWithdrawValue = _lpToValue(_positionInfoBefore.stableLpAmount - _positionInfoAfter.stableLpAmount);

    // This will force the equity loss in stable vault stay within the expectation
    // Given that the expectation is equity loss in stable vault will not alter the stable equity to total equity ratio
    // _stableExpectedWithdrawValue = _withdrawValue * _positionInfoBefore.stablePositionEquity / _totalEquityBefore
    // _stableActualWithdrawValue should be almost equal to _stableExpectedWithdrawValue
    if (
      !Math.almostEqual(
        (_stableLpWithdrawValue -
          (_positionInfoBefore.stablePositionDebtValue - _positionInfoAfter.stablePositionDebtValue)) *
          _totalEquityBefore,
        _withdrawValue * _positionInfoBefore.stablePositionEquity,
        _positionValueTolerance
      )
    ) {
      revert DeltaNeutralVault_UnsafePositionValue();
    }

    uint256 _assetLpWithdrawValue = _lpToValue(_positionInfoBefore.assetLpAmount - _positionInfoAfter.assetLpAmount);

    // This will force the equity loss in asset vault stay within the expectation
    // Given that the expectation is equity loss in asset vault will not alter the asset equity to total equity ratio
    // _assetExpectedWithdrawValue = _withdrawValue * _positionInfoBefore.assetPositionEquity / _totalEquityBefore
    // _assetActualWithdrawValue should be almost equal to _assetExpectedWithdrawValue
    if (
      !Math.almostEqual(
        (_assetLpWithdrawValue -
          (_positionInfoBefore.assetPositionDebtValue - _positionInfoAfter.assetPositionDebtValue)) *
          _totalEquityBefore,
        _withdrawValue * _positionInfoBefore.assetPositionEquity,
        _positionValueTolerance
      )
    ) {
      revert DeltaNeutralVault_UnsafePositionValue();
    }

    // // debt ratio check to prevent closing all out the debt but the equity stay healthy
    uint256 _totalStablePositionBefore = _positionInfoBefore.stablePositionEquity +
      _positionInfoBefore.stablePositionDebtValue;
    uint256 _totalStablePositionAfter = _positionInfoAfter.stablePositionEquity +
      _positionInfoAfter.stablePositionDebtValue;
    // debt ratio = debt / position
    // debt after / position after ~= debt b4 / position b4
    // position b4 * debt after = position after * debt b4
    if (
      !Math.almostEqual(
        _totalStablePositionBefore * _positionInfoAfter.stablePositionDebtValue,
        _totalStablePositionAfter * _positionInfoBefore.stablePositionDebtValue,
        _debtRationTolerance
      )
    ) {
      revert DeltaNeutralVault_UnsafeDebtRatio();
    }

    uint256 _totalassetPositionBefore = _positionInfoBefore.assetPositionEquity +
      _positionInfoBefore.assetPositionDebtValue;
    uint256 _totalassetPositionAfter = _positionInfoAfter.assetPositionEquity +
      _positionInfoAfter.assetPositionDebtValue;

    if (
      !Math.almostEqual(
        _totalassetPositionBefore * _positionInfoAfter.assetPositionDebtValue,
        _totalassetPositionAfter * _positionInfoBefore.assetPositionDebtValue,
        _debtRationTolerance
      )
    ) {
      revert DeltaNeutralVault_UnsafeDebtRatio();
    }
  }

  /// @notice Compare Delta neutral vault tokens' balance before and afrer.
  /// @param _outstandingBefore Tokens' balance before.
  /// @param _outstandingAfter Tokens' balance after.
  function _outstandingCheck(Outstanding memory _outstandingBefore, Outstanding memory _outstandingAfter)
    internal
    view
  {
    if (_outstandingAfter.stableAmount < _outstandingBefore.stableAmount) {
      revert DeltaNeutralVault_UnsafeOutstanding(
        stableToken,
        _outstandingBefore.stableAmount,
        _outstandingAfter.stableAmount
      );
    }
    if (_outstandingAfter.assetAmount < _outstandingBefore.assetAmount) {
      revert DeltaNeutralVault_UnsafeOutstanding(
        assetToken,
        _outstandingBefore.assetAmount,
        _outstandingAfter.assetAmount
      );
    }
    if (_outstandingAfter.nativeAmount < _outstandingBefore.nativeAmount) {
      revert DeltaNeutralVault_UnsafeOutstanding(
        address(0),
        _outstandingBefore.nativeAmount,
        _outstandingAfter.nativeAmount
      );
    }
  }

  /// @notice Return stable token, asset token and native token balance.
  function _outstanding() internal view returns (Outstanding memory) {
    return
      Outstanding({
        stableAmount: IERC20Upgradeable(stableToken).balanceOf(address(this)),
        assetAmount: IERC20Upgradeable(assetToken).balanceOf(address(this)),
        nativeAmount: address(this).balance
      });
  }

  /// @notice Return equity and debt value in usd of stable and asset positions.
  function positionInfo() public view returns (PositionInfo memory) {
    uint256 _stableLpAmount = IWorker02(stableVaultWorker).totalLpBalance();
    uint256 _assetLpAmount = IWorker02(assetVaultWorker).totalLpBalance();
    uint256 _stablePositionValue = _lpToValue(_stableLpAmount);
    uint256 _assetPositionValue = _lpToValue(_assetLpAmount);
    uint256 _stableDebtValue = _positionDebtValue(stableVault, stableVaultPosId, stableTo18ConversionFactor);
    uint256 _assetDebtValue = _positionDebtValue(assetVault, assetVaultPosId, assetTo18ConversionFactor);

    return
      PositionInfo({
        stablePositionEquity: _stablePositionValue > _stableDebtValue ? _stablePositionValue - _stableDebtValue : 0,
        stablePositionDebtValue: _stableDebtValue,
        stableLpAmount: _stableLpAmount,
        assetPositionEquity: _assetPositionValue > _assetDebtValue ? _assetPositionValue - _assetDebtValue : 0,
        assetPositionDebtValue: _assetDebtValue,
        assetLpAmount: _assetLpAmount
      });
  }

  /// @notice Return the value of share from the given share amount.
  /// @param _shareAmount Amount of share.
  function shareToValue(uint256 _shareAmount) public view returns (uint256) {
    // From internal call + pendingManagementFee should be 0 as it was collected
    // at the beginning of the external contract call
    // For external call, to calculate shareToValue, pending fee shall be accounted
    uint256 _shareSupply = totalSupply() + pendingManagementFee();
    if (_shareSupply == 0) return _shareAmount;
    return FullMath.mulDiv(_shareAmount, totalEquityValue(), _shareSupply);
  }

  /// @notice Return the amount of share from the given value.
  /// @param _value value in usd.
  function valueToShare(uint256 _value) external view returns (uint256) {
    return _valueToShare(_value, totalEquityValue());
  }

  /// @notice Return equity value of delta neutral position.
  function totalEquityValue() public view returns (uint256) {
    uint256 _totalPositionValue = _lpToValue(
      IWorker02(stableVaultWorker).totalLpBalance() + IWorker02(assetVaultWorker).totalLpBalance()
    );
    uint256 _totalDebtValue = _positionDebtValue(stableVault, stableVaultPosId, stableTo18ConversionFactor) +
      _positionDebtValue(assetVault, assetVaultPosId, assetTo18ConversionFactor);
    if (_totalPositionValue < _totalDebtValue) {
      return 0;
    }
    return _totalPositionValue - _totalDebtValue;
  }

  /// @notice Set new DeltaNeutralOracle.
  /// @param _newPriceOracle New deltaNeutralOracle address.
  function setDeltaNeutralOracle(IDeltaNeutralOracle _newPriceOracle) external onlyOwner {
    // sanity call
    _newPriceOracle.getTokenPrice(stableToken);
    _newPriceOracle.lpToDollar(1e18, lpToken);

    priceOracle = _newPriceOracle;
    emit LogSetDeltaNeutralOracle(msg.sender, address(_newPriceOracle));
  }

  /// @notice Set new DeltaNeutralVaultConfig.
  /// @param _newVaultConfig New deltaNeutralOracle address.
  function setDeltaNeutralVaultConfig(IDeltaNeutralVaultConfig02 _newVaultConfig) external onlyOwner {
    // sanity call
    _newVaultConfig.positionValueTolerance();

    config = _newVaultConfig;
    emit LogSetDeltaNeutralVaultConfig(msg.sender, address(_newVaultConfig));
  }

  /// @notice Return position debt + pending interest value.
  /// @param _vault Vault addrss.
  /// @param _posId Position id.
  function _positionDebtValue(
    address _vault,
    uint256 _posId,
    uint256 _18ConversionFactor
  ) internal view returns (uint256) {
    (, , uint256 _positionDebtShare) = IVault(_vault).positions(_posId);
    address _token = IVault(_vault).token();
    uint256 _vaultDebtShare = IVault(_vault).vaultDebtShare();
    if (_vaultDebtShare == 0) {
      return (_positionDebtShare * _18ConversionFactor).mulWadDown(_getTokenPrice(_token));
    }
    uint256 _vaultDebtValue = IVault(_vault).vaultDebtVal() + IVault(_vault).pendingInterest(0);
    uint256 _debtAmount = FullMath.mulDiv(_positionDebtShare, _vaultDebtValue, _vaultDebtShare);
    return (_debtAmount * _18ConversionFactor).mulWadDown(_getTokenPrice(_token));
  }

  /// @notice Return value of given lp amount.
  /// @param _lpAmount Amount of lp.
  function _lpToValue(uint256 _lpAmount) internal view returns (uint256) {
    (uint256 _lpValue, uint256 _lastUpdated) = priceOracle.lpToDollar(_lpAmount, lpToken);
    if (block.timestamp - _lastUpdated > 86400) revert DeltaNeutralVault_UnTrustedPrice();
    return _lpValue;
  }

  /// @notice Return equity change between two position
  /// @param _greaterPosition Position information that's expected to have higer value
  /// @param _lesserPosition Position information that's expected to have lower value
  function _calculateEquityChange(PositionInfo memory _greaterPosition, PositionInfo memory _lesserPosition)
    internal
    view
    returns (uint256)
  {
    uint256 _lpChange = (_greaterPosition.stableLpAmount + _greaterPosition.assetLpAmount) -
      (_lesserPosition.stableLpAmount + _lesserPosition.assetLpAmount);

    uint256 _debtChange = (_greaterPosition.stablePositionDebtValue + _greaterPosition.assetPositionDebtValue) -
      (_lesserPosition.stablePositionDebtValue + _lesserPosition.assetPositionDebtValue);

    return _lpToValue(_lpChange) - _debtChange;
  }

  /// @notice Proxy function for calling internal action.
  /// @param _actions List of actions to execute.
  /// @param _values Native token amount.
  /// @param _datas The calldata to pass along for more working context.
  function _execute(
    uint8[] memory _actions,
    uint256[] memory _values,
    bytes[] memory _datas
  ) internal {
    if (_actions.length != _values.length || _actions.length != _datas.length) revert DeltaNeutralVault_BadActionSize();

    for (uint256 i = 0; i < _actions.length; i++) {
      uint8 _action = _actions[i];
      if (_action == ACTION_WORK) {
        _doWork(_datas[i]);
      }
      if (_action == ACTION_WRAP) {
        IWETH(config.getWrappedNativeAddr()).deposit{ value: _values[i] }();
      }
    }
  }

  /// @notice interact with delta neutral position.
  /// @param _data The calldata to pass along to the vault for more working context.
  function _doWork(bytes memory _data) internal {
    if (stableVaultPosId == 0 || assetVaultPosId == 0) {
      revert DeltaNeutralVault_PositionsNotInitialized();
    }

    // 1. Decode data
    (
      address payable _vault,
      uint256 _posId,
      address _worker,
      uint256 _principalAmount,
      uint256 _borrowAmount,
      uint256 _maxReturn,
      bytes memory _workData
    ) = abi.decode(_data, (address, uint256, address, uint256, uint256, uint256, bytes));

    // OPENING for initializing positions
    if (
      OPENING != 1 &&
      !((_vault == stableVault && _posId == stableVaultPosId) || (_vault == assetVault && _posId == assetVaultPosId))
    ) {
      revert DeltaNeutralVault_InvalidPositions({ _vault: _vault, _positionId: _posId });
    }

    // 2. approve vault
    IERC20Upgradeable(stableToken).safeApprove(_vault, type(uint256).max);
    IERC20Upgradeable(assetToken).safeApprove(_vault, type(uint256).max);

    // 3. Call work to altering Vault position
    IVault(_vault).work(_posId, _worker, _principalAmount, _borrowAmount, _maxReturn, _workData);

    // 4. Reset approve to 0
    IERC20Upgradeable(stableToken).safeApprove(_vault, 0);
    IERC20Upgradeable(assetToken).safeApprove(_vault, 0);
  }

  /// @dev _getTokenPrice with validate last price updated
  function _getTokenPrice(address _token) internal view returns (uint256) {
    (uint256 _price, uint256 _lastUpdated) = priceOracle.getTokenPrice(_token);
    // _lastUpdated > 1 day revert
    if (block.timestamp - _lastUpdated > 86400) revert DeltaNeutralVault_UnTrustedPrice();
    return _price;
  }

  /// @notice Calculate share from value and total equity
  /// @param _value Value to convert
  /// @param _totalEquity Total equity at the time of calculation
  function _valueToShare(uint256 _value, uint256 _totalEquity) internal view returns (uint256) {
    uint256 _shareSupply = totalSupply() + pendingManagementFee();
    if (_shareSupply == 0) return _value;
    return FullMath.mulDiv(_value, _shareSupply, _totalEquity);
  }

  /// @dev Return a conversion factor to 18 decimals.
  /// @param _token token to convert.
  function _to18ConversionFactor(address _token) internal view returns (uint256) {
    uint256 _decimals = ERC20Upgradeable(_token).decimals();
    if (_decimals > 18) revert DeltaNeutralVault_UnsupportedDecimals(_decimals);
    if (_decimals == 18) return 1;
    uint256 _conversionFactor = 10**(18 - _decimals);
    return _conversionFactor;
  }

  /// @dev Fallback function to accept BNB.
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IDeltaNeutralOracle {
  /// @dev Return value in USD for the given lpAmount.
  function lpToDollar(uint256 _lpAmount, address _pancakeLPToken) external view returns (uint256, uint256);

  /// @dev Return amount of LP for the given USD.
  function dollarToLp(uint256 _dollarAmount, address _lpToken) external view returns (uint256, uint256);

  /// @dev Return value of given token in USD.
  function getTokenPrice(address _token) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

abstract contract IVault {
  struct Position {
    address worker;
    address owner;
    uint256 debtShare;
  }

  mapping(uint256 => Position) public positions;

  //@dev Return address of the token to be deposited in vault
  function token() external view virtual returns (address);

  uint256 public vaultDebtShare;

  uint256 public vaultDebtVal;

  //@dev Return next position id of vault
  function nextPositionID() external view virtual returns (uint256);

  //@dev Return the pending interest that will be accrued in the next call.
  function pendingInterest(uint256 value) external view virtual returns (uint256);

  function fairLaunchPoolId() external view virtual returns (uint256);

  /// @dev a function for interacting with position
  function work(
    uint256 id,
    address worker,
    uint256 principalAmount,
    uint256 borrowAmount,
    uint256 maxReturn,
    bytes calldata data
  ) external payable virtual;
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

import "./IWorker.sol";

interface IWorker02 is IWorker {
  /// @dev Return the trading path that worker is using for convert BTOKEN->...->FTOKEN
  function getPath() external view returns (address[] memory);

  /// @dev Return the inverse of the path that worker is using for convert BTOKEN->...->FTOKEN
  function getReversedPath() external view returns (address[] memory);

  /// @dev Return the trading path that the worker is using to convert reward token to beneficial vault token
  function getRewardPath() external view returns (address[] memory);

  /// @dev Return the amount of lp that worker has
  function totalLpBalance() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IWNativeRelayer {
  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IDeltaNeutralVaultConfig02 {
  function getWrappedNativeAddr() external view returns (address);

  function getWNativeRelayer() external view returns (address);

  function rebalanceFactor() external view returns (uint256);

  function positionValueTolerance() external view returns (uint256);

  function debtRatioTolerance() external view returns (uint256);

  /// @dev Return if the caller is whitelisted.
  function whitelistedCallers(address _caller) external view returns (bool);

  /// @dev Return if the caller is whitelisted.
  function whitelistedRebalancers(address _caller) external view returns (bool);

  /// @dev Return if the caller is exempted from fee.
  function feeExemptedCallers(address _caller) external returns (bool);

  /// @dev Get fairlaunch address.
  function fairLaunchAddr() external view returns (address);

  /// @dev Return the deposit fee treasury.
  function depositFeeTreasury() external view returns (address);

  /// @dev Get deposit fee.
  function depositFeeBps() external view returns (uint256);

  /// @dev Return the withdrawl fee treasury.
  function withdrawalFeeTreasury() external view returns (address);

  /// @dev Get withdrawal fee.
  function withdrawalFeeBps() external returns (uint256);

  /// @dev Return management fee treasury
  function managementFeeTreasury() external view returns (address);

  /// @dev Return management fee per sec.
  function managementFeePerSec() external view returns (uint256);

  /// @dev Get leverage level.
  function leverageLevel() external view returns (uint8);

  /// @dev Return if the caller is whitelisted.
  function whitelistedReinvestors(address _caller) external view returns (bool);

  /// @dev Return ALPACA reinvest fee treasury.
  function alpacaReinvestFeeTreasury() external view returns (address);

  /// @dev Return alpaca bounty bps.
  function alpacaBountyBps() external view returns (uint256);

  /// @dev Return ALPACA beneficiary address.
  function alpacaBeneficiary() external view returns (address);

  /// @dev Return ALPACA beneficiary bps.
  function alpacaBeneficiaryBps() external view returns (uint256);

  /// @dev Return if delta neutral vault position value acceptable.
  function isVaultSizeAcceptable(uint256 _totalPositionValue) external view returns (bool);

  /// @dev Return swap router
  function getSwapRouter() external view returns (address);

  /// @dev Return reinvest path
  function getReinvestPath() external view returns (address[] memory);

  /// @dev Return controller address
  function controller() external view returns (address);

  /// @dev Set a new controller
  function setController(address _controller) external;

  /// @dev Return deposit executor
  function depositExecutor() external view returns (address);

  /// @dev Return withdraw executor
  function withdrawExecutor() external view returns (address);

  /// @dev Return rebalance executor
  function rebalanceExecutor() external view returns (address);

  /// @dev Return reinvest executor
  function reinvestExecutor() external view returns (address);

  /// @dev Return if caller is executor.
  function isExecutor(address _caller) external view returns (bool);

  /// @dev Return Partial close minimize strategy address
  function partialCloseMinimizeStrategy() external view returns (address);

  /// @dev Return Stable add two side strategy address
  function stableAddTwoSideStrategy() external view returns (address);

  /// @dev Return Asset add two side strategy address
  function assetAddTwoSideStrategy() external view returns (address);

  /// @dev Return swap fee
  function swapFee() external view returns (uint256);

  /// @dev Return swap fee denom
  function swapFeeDenom() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IFairLaunch {
  function poolLength() external view returns (uint256);

  function addPool(
    uint256 _allocPoint,
    address _stakeToken,
    bool _withUpdate
  ) external;

  function setPool(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external;

  function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);

  function updatePool(uint256 _pid) external;

  function deposit(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    uint256 _pid,
    uint256 _amount
  ) external;

  function withdrawAll(address _for, uint256 _pid) external;

  function harvest(uint256 _pid) external;

  function getFairLaunchPoolId() external returns (uint256);

  function poolInfo(uint256 _pid)
    external
    returns (
      address,
      uint256,
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface ISwapRouter {
  function WETH() external pure returns (address);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IController {
  function totalCredit(address _user) external view returns (uint256);

  function usedCredit(address _user) external view returns (uint256);

  function availableCredit(address _user) external view returns (uint256);

  function onDeposit(address _user, uint256 _shareAmount) external;

  function onWithdraw(address _user, uint256 _shareAmount) external;
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    // solhint-disable-next-line avoid-low-level-calls
    require(token.code.length > 0, "!contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    // solhint-disable-next-line avoid-low-level-calls
    require(token.code.length > 0, "!not contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    require(token.code.length > 0, "!not contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "!safeTransferETH");
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
  /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

  function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
  }

  function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
  }

  function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
  }

  function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
    return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
  }

  /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function mulDivDown(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

      // Divide z by the denominator.
      z := div(z, denominator)
    }
  }

  function mulDivUp(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
        revert(0, 0)
      }

      // First, divide z - 1 by the denominator and add 1.
      // Then multiply it by 0 if z is zero, or 1 otherwise.
      z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
    }
  }

  function rpow(
    uint256 x,
    uint256 n,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          // 0 ** 0 = 1
          z := denominator
        }
        default {
          // 0 ** n = 0
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          // If n is even, store denominator in z for now.
          z := denominator
        }
        default {
          // If n is odd, store x in z for now.
          z := x
        }

        // Shifting right by 1 is like dividing by 2.
        let half := shr(1, denominator)

        for {
          // Shift n right by 1 before looping to halve it.
          n := shr(1, n)
        } n {
          // Shift n right by 1 each iteration to halve it.
          n := shr(1, n)
        } {
          // Revert immediately if x ** 2 would overflow.
          // Equivalent to iszero(eq(div(xx, x), x)) here.
          if shr(128, x) {
            revert(0, 0)
          }

          // Store x squared.
          let xx := mul(x, x)

          // Round to the nearest number.
          let xxRound := add(xx, half)

          // Revert if xx + half overflowed.
          if lt(xxRound, xx) {
            revert(0, 0)
          }

          // Set x to scaled xxRound.
          x := div(xxRound, denominator)

          // If n is even:
          if mod(n, 2) {
            // Compute z * x.
            let zx := mul(z, x)

            // If z * x overflowed:
            if iszero(eq(div(zx, x), z)) {
              // Revert if x is non-zero.
              if iszero(iszero(x)) {
                revert(0, 0)
              }
            }

            // Round to the nearest number.
            let zxRound := add(zx, half)

            // Revert if zx + half overflowed.
            if lt(zxRound, zx) {
              revert(0, 0)
            }

            // Return properly scaled zxRound.
            z := div(zxRound, denominator)
          }
        }
      }
    }
  }

  /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

  function sqrt(uint256 x) internal pure returns (uint256 z) {
    assembly {
      // Start off with z at 1.
      z := 1

      // Used below to help find a nearby power of 2.
      let y := x

      // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z)
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z)
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z)
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z)
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z)
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z)
      }
      if iszero(lt(y, 0x8)) {
        // Equivalent to 2 ** z.
        z := shl(1, z)
      }

      // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

      // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

      // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

library Math {
  /**
   * @dev Check if two values are almost equal within toleranceBps.
   */
  function almostEqual(
    uint256 value0,
    uint256 value1,
    uint256 toleranceBps
  ) internal pure returns (bool) {
    uint256 maxValue = max(value0, value1);
    return ((maxValue - min(value0, value1)) * 10000) <= toleranceBps * maxValue;
  }

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
   * @dev Returns the rounded number.
   */
  function e36round(uint256 a) internal pure returns (uint256) {
    return (a + 5e17) / 1e18;
  }
}

// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = a * b
      // Compute the product mod 2**256 and mod 2**256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2**256 + prod0
      uint256 prod0; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division
      if (prod1 == 0) {
        require(denominator > 0);
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      // Make sure the result is less than 2**256.
      // Also prevents denominator == 0
      require(denominator > prod1);

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(a, b, denominator)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1.
      uint256 twos = (type(uint256).max - denominator + 1) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    unchecked {
      if (mulmod(a, b, denominator) > 0) {
        require(result < type(uint256).max);
        result++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

import "./IPancakePair.sol";

interface IWorker {
  /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;

  /// @dev Re-invest whatever the worker is working on.
  function reinvest() external;

  /// @dev Return the amount of wei to get back if we are to liquidate the position.
  function health(uint256 id) external view returns (uint256);

  /// @dev Liquidate the given position to token. Send all token back to its Vault.
  function liquidate(uint256 id) external;

  /// @dev SetStretegy that be able to executed by the worker.
  function setStrategyOk(address[] calldata strats, bool isOk) external;

  /// @dev Set address that can be reinvest
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

  /// @dev LP token holds by worker
  function lpToken() external view returns (address);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);
}

// SPDX-License-Identifier: BUSL
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

interface IPancakePair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}