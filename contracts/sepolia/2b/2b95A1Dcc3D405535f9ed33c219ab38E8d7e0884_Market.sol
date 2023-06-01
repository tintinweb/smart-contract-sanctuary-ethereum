// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { IMarket } from "./interfaces/IMarket.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";

// solhint-disable max-states-count

contract Market is AccessControlUpgradeable, ReentrancyGuardUpgradeable, IMarket {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the fee ratio for minting fToken is updated.
  /// @param defaultFeeRatio The new default fee ratio, multipled by 1e18.
  /// @param extraFeeRatio The new extra fee ratio, multipled by 1e18.
  event UpdateMintFeeRatioFToken(uint128 defaultFeeRatio, int128 extraFeeRatio);

  /// @notice Emitted when the fee ratio for minting xToken is updated.
  /// @param defaultFeeRatio The new default fee ratio, multipled by 1e18.
  /// @param extraFeeRatio The new extra fee ratio, multipled by 1e18.
  event UpdateMintFeeRatioXToken(uint128 defaultFeeRatio, int128 extraFeeRatio);

  /// @notice Emitted when the fee ratio for redeeming fToken is updated.
  /// @param defaultFeeRatio The new default fee ratio, multipled by 1e18.
  /// @param extraFeeRatio The new extra fee ratio, multipled by 1e18.
  event UpdateRedeemFeeRatioFToken(uint128 defaultFeeRatio, int128 extraFeeRatio);

  /// @notice Emitted when the fee ratio for redeeming xToken is updated.
  /// @param defaultFeeRatio The new default fee ratio, multipled by 1e18.
  /// @param extraFeeRatio The new extra fee ratio, multipled by 1e18.
  event UpdateRedeemFeeRatioXToken(uint128 defaultFeeRatio, int128 extraFeeRatio);

  /// @notice Emitted when the market config is updated.
  /// @param stabilityRatio The new start collateral ratio to enter system stability mode, multiplied by 1e18.
  /// @param liquidationRatio The new start collateral ratio to enter incentivized user liquidation mode, multiplied by 1e18.
  /// @param selfLiquidationRatio The new start collateral ratio to enter self liquidation mode, multiplied by 1e18.
  /// @param recapRatio The new start collateral ratio to enter recap mode, multiplied by 1e18.
  event UpdateMarketConfig(
    uint64 stabilityRatio,
    uint64 liquidationRatio,
    uint64 selfLiquidationRatio,
    uint64 recapRatio
  );

  /// @notice Emitted when the incentive config is updated.
  /// @param stabilityIncentiveRatio The new incentive ratio for system stability mode, multiplied by 1e18.
  /// @param liquidationIncentiveRatio The new incentive ratio for incentivized user liquidation mode, multiplied by 1e18.
  /// @param selfLiquidationIncentiveRatio The new incentive ratio for self liquidation mode, multiplied by 1e18.
  event UpdateIncentiveConfig(
    uint64 stabilityIncentiveRatio,
    uint64 liquidationIncentiveRatio,
    uint64 selfLiquidationIncentiveRatio
  );

  /// @notice Emitted when the whitelist status for settle is changed.
  /// @param account The address of account to change.
  /// @param status The new whitelist status.
  event UpdateLiquidationWhitelist(address account, bool status);

  /// @notice Emitted when the platform contract is changed.
  /// @param platform The address of new platform.
  event UpdatePlatform(address platform);

  /// @notice Pause or unpause mint.
  /// @param status The new status for mint.
  event PauseMint(bool status);

  /// @notice Pause or unpause redeem.
  /// @param status The new status for redeem.
  event PauseRedeem(bool status);

  /// @notice Pause or unpause fToken mint in system stability mode.
  /// @param status The new status for mint.
  event PauseFTokenMintInSystemStabilityMode(bool status);

  /// @notice Pause or unpause xToken redeem in system stability mode.
  /// @param status The new status for redeem.
  event PauseXTokenRedeemInSystemStabilityMode(bool status);

  /*************
   * Constants *
   *************/

  /// @notice The role for emergency dao.
  bytes32 public constant EMERGENCY_DAO_ROLE = keccak256("EMERGENCY_DAO_ROLE");

  /// @dev The precision used to compute nav.
  uint256 private constant PRECISION = 1e18;

  /***********
   * Structs *
   ***********/

  /// @dev Compiler will pack this into single `uint256`.
  struct FeeRatio {
    // The default fee ratio, multiplied by 1e18.
    uint128 defaultFeeRatio;
    // The extra delta fee ratio, multiplied by 1e18.
    int128 extraFeeRatio;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct MarketConfig {
    // The start collateral ratio to enter system stability mode, multiplied by 1e18.
    uint64 stabilityRatio;
    // The start collateral ratio to enter incentivized user liquidation mode, multiplied by 1e18.
    uint64 liquidationRatio;
    // The start collateral ratio to enter self liquidation mode, multiplied by 1e18.
    uint64 selfLiquidationRatio;
    // The start collateral ratio to enter recap mode, multiplied by 1e18.
    uint64 recapRatio;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct IncentiveConfig {
    // The incentive ratio for system stability mode, multiplied by 1e18.
    uint64 stabilityIncentiveRatio;
    // The incentive ratio for incentivized user liquidation mode, multiplied by 1e18.
    uint64 liquidationIncentiveRatio;
    // The incentive ratio for self liquidation mode, multiplied by 1e18.
    uint64 selfLiquidationIncentiveRatio;
  }

  /*************
   * Variables *
   *************/

  /// @notice The address of Treasury contract.
  address public treasury;

  /// @notice The address of platform contract;
  address public platform;

  /// @notice The address base token;
  address public baseToken;

  /// @notice The address fractional base token.
  address public fToken;

  /// @notice The address leveraged base token.
  address public xToken;

  /// @notice The market config in each mode.
  MarketConfig public marketConfig;

  /// @notice The incentive config in each mode.
  IncentiveConfig public incentiveConfig;

  /// @notice The mint fee ratio for fToken.
  FeeRatio public fTokenMintFeeRatio;

  /// @notice The mint fee ratio for xToken.
  FeeRatio public xTokenMintFeeRatio;

  /// @notice The redeem fee ratio for fToken.
  FeeRatio public fTokenRedeemFeeRatio;

  /// @notice The redeem fee ratio for xToken.
  FeeRatio public xTokenRedeemFeeRatio;

  /// @notice Whether the sender is allowed to do self liquidation.
  mapping(address => bool) public liquidationWhitelist;

  /// @notice Whether the mint is paused.
  bool public mintPaused;

  /// @notice Whether the redeem is paused.
  bool public redeemPaused;

  /// @notice Whether to pause fToken mint in system stability mode
  bool public fTokenMintInSystemStabilityModePaused;

  /// @notice Whether to pause xToken redeem in system stability mode
  bool public xTokenRedeemInSystemStabilityModePaused;

  /************
   * Modifier *
   ************/

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only Admin");
    _;
  }

  modifier onlyEmergencyDAO() {
    require(hasRole(EMERGENCY_DAO_ROLE, msg.sender), "only Emergency DAO");
    _;
  }

  modifier cachePrice() {
    ITreasury(treasury).cacheTwap();
    _;
  }

  /***************
   * Constructor *
   ***************/

  function initialize(address _treasury, address _platform) external initializer {
    AccessControlUpgradeable.__AccessControl_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    treasury = _treasury;
    platform = _platform;

    baseToken = ITreasury(_treasury).baseToken();
    fToken = ITreasury(_treasury).fToken();
    xToken = ITreasury(_treasury).xToken();
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @inheritdoc IMarket
  function mint(
    uint256 _baseIn,
    address _recipient,
    uint256 _minFTokenMinted,
    uint256 _minXTokenMinted
  ) external override nonReentrant cachePrice returns (uint256 _fTokenMinted, uint256 _xTokenMinted) {
    address _baseToken = baseToken;
    if (_baseIn == uint256(-1)) {
      _baseIn = IERC20Upgradeable(_baseToken).balanceOf(msg.sender);
    }
    require(_baseIn > 0, "mint zero amount");

    ITreasury _treasury = ITreasury(treasury);
    require(_treasury.totalBaseToken() == 0, "only initialize once");

    IERC20Upgradeable(_baseToken).safeTransferFrom(msg.sender, address(_treasury), _baseIn);
    (_fTokenMinted, _xTokenMinted) = _treasury.mint(_baseIn, _recipient, ITreasury.MintOption.Both);

    require(_fTokenMinted >= _minFTokenMinted, "insufficient fToken output");
    require(_xTokenMinted >= _minXTokenMinted, "insufficient xToken output");

    emit Mint(msg.sender, _recipient, _baseIn, _fTokenMinted, _xTokenMinted, 0);
  }

  /// @inheritdoc IMarket
  function mintFToken(
    uint256 _baseIn,
    address _recipient,
    uint256 _minFTokenMinted
  ) external override nonReentrant cachePrice returns (uint256 _fTokenMinted) {
    require(!mintPaused, "mint is paused");

    address _baseToken = baseToken;
    if (_baseIn == uint256(-1)) {
      _baseIn = IERC20Upgradeable(_baseToken).balanceOf(msg.sender);
    }
    require(_baseIn > 0, "mint zero amount");

    ITreasury _treasury = ITreasury(treasury);
    (uint256 _maxBaseInBeforeSystemStabilityMode, ) = _treasury.maxMintableFToken(marketConfig.stabilityRatio);

    if (fTokenMintInSystemStabilityModePaused) {
      uint256 _collateralRatio = _treasury.collateralRatio();
      require(_collateralRatio > marketConfig.stabilityRatio, "fToken mint paused");

      // bound maximum amount of base token to mint fToken.
      if (_baseIn > _maxBaseInBeforeSystemStabilityMode) {
        _baseIn = _maxBaseInBeforeSystemStabilityMode;
      }
    }

    uint256 _amountWithoutFee = _deductFTokenMintFee(_baseIn, fTokenMintFeeRatio, _maxBaseInBeforeSystemStabilityMode);

    IERC20Upgradeable(_baseToken).safeTransferFrom(msg.sender, address(_treasury), _amountWithoutFee);
    (_fTokenMinted, ) = _treasury.mint(_amountWithoutFee, _recipient, ITreasury.MintOption.FToken);
    require(_fTokenMinted >= _minFTokenMinted, "insufficient fToken output");

    emit Mint(msg.sender, _recipient, _baseIn, _fTokenMinted, 0, _baseIn - _amountWithoutFee);
  }

  /// @inheritdoc IMarket
  function mintXToken(
    uint256 _baseIn,
    address _recipient,
    uint256 _minXTokenMinted
  ) external override nonReentrant cachePrice returns (uint256 _xTokenMinted) {
    require(!mintPaused, "mint is paused");

    address _baseToken = baseToken;
    if (_baseIn == uint256(-1)) {
      _baseIn = IERC20Upgradeable(_baseToken).balanceOf(msg.sender);
    }
    require(_baseIn > 0, "mint zero amount");

    ITreasury _treasury = ITreasury(treasury);
    (uint256 _maxBaseInBeforeSystemStabilityMode, ) = _treasury.maxMintableXToken(marketConfig.stabilityRatio);

    uint256 _amountWithoutFee = _deductXTokenMintFee(_baseIn, xTokenMintFeeRatio, _maxBaseInBeforeSystemStabilityMode);

    IERC20Upgradeable(_baseToken).safeTransferFrom(msg.sender, address(_treasury), _amountWithoutFee);
    (, _xTokenMinted) = _treasury.mint(_amountWithoutFee, _recipient, ITreasury.MintOption.XToken);
    require(_xTokenMinted >= _minXTokenMinted, "insufficient xToken output");

    emit Mint(msg.sender, _recipient, _baseIn, 0, _xTokenMinted, _baseIn - _amountWithoutFee);
  }

  /// @inheritdoc IMarket
  function addBaseToken(
    uint256 _baseIn,
    address _recipient,
    uint256 _minXTokenMinted
  ) external override nonReentrant cachePrice returns (uint256 _xTokenMinted) {
    require(!mintPaused, "mint is paused");

    ITreasury _treasury = ITreasury(treasury);
    uint256 _collateralRatio = _treasury.collateralRatio();

    MarketConfig memory _marketConfig = marketConfig;
    require(
      _marketConfig.recapRatio <= _collateralRatio && _collateralRatio < _marketConfig.stabilityRatio,
      "Not system stability mode"
    );

    (uint256 _maxBaseInBeforeSystemStabilityMode, ) = _treasury.maxMintableXTokenWithIncentive(
      _marketConfig.stabilityRatio,
      incentiveConfig.stabilityIncentiveRatio
    );

    // bound the amount of base token
    FeeRatio memory _ratio = xTokenMintFeeRatio;
    uint256 _feeRatio = uint256(int256(_ratio.defaultFeeRatio) + _ratio.extraFeeRatio);
    if (_baseIn * (PRECISION - _feeRatio) > _maxBaseInBeforeSystemStabilityMode * PRECISION) {
      _baseIn = (_maxBaseInBeforeSystemStabilityMode * PRECISION) / (PRECISION - _feeRatio);
    }

    // take fee to platform
    if (_feeRatio > 0) {
      uint256 _fee = (_baseIn * _feeRatio) / PRECISION;
      IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, platform, _fee);
      _baseIn = _baseIn - _fee;
    }

    IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(_treasury), _baseIn);
    _xTokenMinted = _treasury.addBaseToken(_baseIn, incentiveConfig.stabilityIncentiveRatio, _recipient);
    require(_xTokenMinted >= _minXTokenMinted, "insufficient xToken output");

    emit AddCollateral(msg.sender, _recipient, _baseIn, _xTokenMinted);
  }

  /// @inheritdoc IMarket
  function redeem(
    uint256 _fTokenIn,
    uint256 _xTokenIn,
    address _recipient,
    uint256 _minBaseOut
  ) external override nonReentrant cachePrice returns (uint256 _baseOut) {
    require(!redeemPaused, "redeem is paused");

    if (_fTokenIn == uint256(-1)) {
      _fTokenIn = IERC20Upgradeable(fToken).balanceOf(msg.sender);
    }
    if (_xTokenIn == uint256(-1)) {
      _xTokenIn = IERC20Upgradeable(xToken).balanceOf(msg.sender);
    }
    require(_fTokenIn > 0 || _xTokenIn > 0, "redeem zero amount");
    require(_fTokenIn == 0 || _xTokenIn == 0, "only redeem single side");

    ITreasury _treasury = ITreasury(treasury);
    MarketConfig memory _marketConfig = marketConfig;

    uint256 _feeRatio;
    if (_fTokenIn > 0) {
      (, uint256 _maxFTokenInBeforeSystemStabilityMode) = _treasury.maxRedeemableFToken(_marketConfig.stabilityRatio);
      _feeRatio = _computeFTokenRedeemFeeRatio(_fTokenIn, fTokenRedeemFeeRatio, _maxFTokenInBeforeSystemStabilityMode);
    } else {
      (, uint256 _maxXTokenInBeforeSystemStabilityMode) = _treasury.maxRedeemableXToken(_marketConfig.stabilityRatio);

      if (xTokenRedeemInSystemStabilityModePaused) {
        uint256 _collateralRatio = _treasury.collateralRatio();
        require(_collateralRatio > _marketConfig.stabilityRatio, "xToken redeem paused");

        // bound maximum amount of xToken to redeem.
        if (_xTokenIn > _maxXTokenInBeforeSystemStabilityMode) {
          _xTokenIn = _maxXTokenInBeforeSystemStabilityMode;
        }
      }

      _feeRatio = _computeXTokenRedeemFeeRatio(_xTokenIn, xTokenRedeemFeeRatio, _maxXTokenInBeforeSystemStabilityMode);
    }

    _baseOut = _treasury.redeem(_fTokenIn, _xTokenIn, msg.sender);
    uint256 _balance = IERC20Upgradeable(baseToken).balanceOf(address(this));
    // consider possible slippage
    if (_balance < _baseOut) {
      _baseOut = _balance;
    }

    uint256 _fee = (_baseOut * _feeRatio) / PRECISION;
    if (_fee > 0) {
      IERC20Upgradeable(baseToken).safeTransfer(platform, _fee);
      _baseOut = _baseOut - _fee;
    }
    require(_baseOut >= _minBaseOut, "insufficient base output");

    IERC20Upgradeable(baseToken).safeTransfer(_recipient, _baseOut);

    emit Redeem(msg.sender, _recipient, _fTokenIn, _xTokenIn, _baseOut, _fee);
  }

  /// @inheritdoc IMarket
  function liquidate(
    uint256 _fTokenIn,
    address _recipient,
    uint256 _minBaseOut
  ) external override nonReentrant cachePrice returns (uint256 _baseOut) {
    require(!redeemPaused, "redeem is paused");

    ITreasury _treasury = ITreasury(treasury);
    uint256 _collateralRatio = _treasury.collateralRatio();

    MarketConfig memory _marketConfig = marketConfig;
    require(
      _marketConfig.recapRatio <= _collateralRatio && _collateralRatio < _marketConfig.liquidationRatio,
      "Not liquidation mode"
    );

    // bound the amount of fToken
    (, uint256 _maxFTokenLiquidatable) = _treasury.maxLiquidatable(
      _marketConfig.liquidationRatio,
      incentiveConfig.liquidationIncentiveRatio
    );
    if (_fTokenIn > _maxFTokenLiquidatable) {
      _fTokenIn = _maxFTokenLiquidatable;
    }

    _baseOut = _treasury.liquidate(_fTokenIn, incentiveConfig.liquidationIncentiveRatio, msg.sender);

    // take platform fee
    uint256 _feeRatio;
    {
      FeeRatio memory _ratio = fTokenRedeemFeeRatio;
      _feeRatio = uint256(int256(_ratio.defaultFeeRatio) + _ratio.extraFeeRatio);
    }
    uint256 _fee = (_baseOut * _feeRatio) / PRECISION;
    if (_fee > 0) {
      IERC20Upgradeable(baseToken).safeTransfer(platform, _fee);
      _baseOut = _baseOut - _fee;
    }
    require(_baseOut >= _minBaseOut, "insufficient base output");

    IERC20Upgradeable(baseToken).safeTransfer(_recipient, _baseOut);

    emit UserLiquidate(msg.sender, _recipient, _fTokenIn, _baseOut);
  }

  /// @inheritdoc IMarket
  function selfLiquidate(
    uint256 _baseSwapAmt,
    uint256 _minFTokenLiquidated,
    bytes calldata _data
  ) external override nonReentrant cachePrice returns (uint256 _baseOut, uint256 _fTokenLiquidated) {
    require(!redeemPaused, "redeem is paused");
    require(liquidationWhitelist[msg.sender], "not liquidation whitelist");

    ITreasury _treasury = ITreasury(treasury);
    uint256 _collateralRatio = _treasury.collateralRatio();

    MarketConfig memory _marketConfig = marketConfig;
    require(
      _marketConfig.recapRatio <= _collateralRatio && _collateralRatio < _marketConfig.selfLiquidationRatio,
      "Not self liquidation mode"
    );

    // bound the amount of base token
    (uint256 _maxBaseOut, ) = _treasury.maxLiquidatable(
      _marketConfig.selfLiquidationRatio,
      incentiveConfig.selfLiquidationIncentiveRatio
    );
    if (_baseSwapAmt > _maxBaseOut) {
      _baseSwapAmt = _maxBaseOut;
    }

    (_baseOut, _fTokenLiquidated) = _treasury.selfLiquidate(
      _baseSwapAmt,
      incentiveConfig.selfLiquidationIncentiveRatio,
      platform,
      _data
    );
    require(_fTokenLiquidated >= _minFTokenLiquidated, "insufficient fToken liquidated");

    emit SelfLiquidate(msg.sender, _baseSwapAmt, _baseOut, _fTokenLiquidated);
  }

  /// @inheritdoc IMarket
  function onSelfLiquidate(uint256 _baseSwapAmt, bytes calldata _data) external override returns (uint256 _fTokenAmt) {
    require(msg.sender == treasury, "only called by treasury");
    (address _target, bytes memory _calldata) = abi.decode(_data, (address, bytes));
    require(_target != treasury, "invalid target contract");

    address _baseToken = baseToken;
    IERC20Upgradeable(_baseToken).safeApprove(_target, 0);
    IERC20Upgradeable(_baseToken).safeApprove(_target, _baseSwapAmt);

    // solhint-disable-next-line avoid-low-level-calls
    (bool _success, ) = _target.call(_calldata);
    require(_success, "call failed");

    address _fToken = fToken;
    _fTokenAmt = IERC20Upgradeable(_fToken).balanceOf(address(this));
    IERC20Upgradeable(_fToken).safeTransfer(msg.sender, _fTokenAmt);
  }

  /*******************************
   * Public Restricted Functions *
   *******************************/

  /// @notice Update the fee ratio for redeeming.
  /// @param _defaultFeeRatio The new default fee ratio, multipled by 1e18.
  /// @param _extraFeeRatio The new extra fee ratio, multipled by 1e18.
  /// @param _isFToken Whether we are updating for fToken.
  function updateRedeemFeeRatio(
    uint128 _defaultFeeRatio,
    int128 _extraFeeRatio,
    bool _isFToken
  ) external onlyAdmin {
    require(_defaultFeeRatio <= PRECISION, "default fee ratio too large");
    if (_extraFeeRatio < 0) {
      require(uint128(-_extraFeeRatio) <= _defaultFeeRatio, "delta fee too small");
    } else {
      require(uint128(_extraFeeRatio) <= PRECISION - _defaultFeeRatio, "total fee too large");
    }

    if (_isFToken) {
      fTokenRedeemFeeRatio = FeeRatio(_defaultFeeRatio, _extraFeeRatio);
      emit UpdateRedeemFeeRatioFToken(_defaultFeeRatio, _extraFeeRatio);
    } else {
      xTokenRedeemFeeRatio = FeeRatio(_defaultFeeRatio, _extraFeeRatio);
      emit UpdateRedeemFeeRatioXToken(_defaultFeeRatio, _extraFeeRatio);
    }
  }

  /// @notice Update the fee ratio for minting.
  /// @param _defaultFeeRatio The new default fee ratio, multipled by 1e18.
  /// @param _extraFeeRatio The new extra fee ratio, multipled by 1e18.
  /// @param _isFToken Whether we are updating for fToken.
  function updateMintFeeRatio(
    uint128 _defaultFeeRatio,
    int128 _extraFeeRatio,
    bool _isFToken
  ) external onlyAdmin {
    require(_defaultFeeRatio <= PRECISION, "default fee ratio too large");
    if (_extraFeeRatio < 0) {
      require(uint128(-_extraFeeRatio) <= _defaultFeeRatio, "delta fee too small");
    } else {
      require(uint128(_extraFeeRatio) <= PRECISION - _defaultFeeRatio, "total fee too large");
    }

    if (_isFToken) {
      fTokenMintFeeRatio = FeeRatio(_defaultFeeRatio, _extraFeeRatio);
      emit UpdateMintFeeRatioFToken(_defaultFeeRatio, _extraFeeRatio);
    } else {
      xTokenMintFeeRatio = FeeRatio(_defaultFeeRatio, _extraFeeRatio);
      emit UpdateMintFeeRatioXToken(_defaultFeeRatio, _extraFeeRatio);
    }
  }

  /// @notice Update the market config.
  /// @param _stabilityRatio The start collateral ratio to enter system stability mode to update, multiplied by 1e18.
  /// @param _liquidationRatio The start collateral ratio to enter incentivized user liquidation mode to update, multiplied by 1e18.
  /// @param _selfLiquidationRatio The start collateral ratio to enter self liquidation mode to update, multiplied by 1e18.
  /// @param _recapRatio The start collateral ratio to enter recap mode to update, multiplied by 1e18.
  function updateMarketConfig(
    uint64 _stabilityRatio,
    uint64 _liquidationRatio,
    uint64 _selfLiquidationRatio,
    uint64 _recapRatio
  ) external onlyAdmin {
    require(
      _stabilityRatio > _liquidationRatio &&
        _liquidationRatio > _selfLiquidationRatio &&
        _selfLiquidationRatio > _recapRatio &&
        _recapRatio >= PRECISION,
      "invalid market config"
    );

    marketConfig = MarketConfig(_stabilityRatio, _liquidationRatio, _selfLiquidationRatio, _recapRatio);

    emit UpdateMarketConfig(_stabilityRatio, _liquidationRatio, _selfLiquidationRatio, _recapRatio);
  }

  /// @notice Update the incentive config.
  /// @param _stabilityIncentiveRatio The incentive ratio for system stability mode to update, multiplied by 1e18.
  /// @param _liquidationIncentiveRatio The incentive ratio for incentivized user liquidation mode to update, multiplied by 1e18.
  /// @param _selfLiquidationIncentiveRatio The incentive ratio for self liquidation mode to update, multiplied by 1e18.
  function updateIncentiveConfig(
    uint64 _stabilityIncentiveRatio,
    uint64 _liquidationIncentiveRatio,
    uint64 _selfLiquidationIncentiveRatio
  ) external onlyAdmin {
    require(_stabilityIncentiveRatio > 0, "incentive too small");
    require(_selfLiquidationIncentiveRatio > 0, "incentive too small");
    require(_liquidationIncentiveRatio >= _selfLiquidationIncentiveRatio, "invalid incentive config");

    incentiveConfig = IncentiveConfig(
      _stabilityIncentiveRatio,
      _liquidationIncentiveRatio,
      _selfLiquidationIncentiveRatio
    );

    emit UpdateIncentiveConfig(_stabilityIncentiveRatio, _liquidationIncentiveRatio, _selfLiquidationIncentiveRatio);
  }

  /// @notice Change address of platform contract.
  /// @param _platform The new address of platform contract.
  function updatePlatform(address _platform) external onlyAdmin {
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @notice Update the whitelist status for self liquidation account.
  /// @param _account The address of account to update.
  /// @param _status The status of the account to update.
  function updateLiquidationWhitelist(address _account, bool _status) external onlyAdmin {
    liquidationWhitelist[_account] = _status;

    emit UpdateLiquidationWhitelist(_account, _status);
  }

  /// @notice Pause mint in this contract
  /// @param _status The pause status.
  function pauseMint(bool _status) external onlyEmergencyDAO {
    mintPaused = _status;

    emit PauseMint(_status);
  }

  /// @notice Pause redeem in this contract
  /// @param _status The pause status.
  function pauseRedeem(bool _status) external onlyEmergencyDAO {
    redeemPaused = _status;

    emit PauseRedeem(_status);
  }

  /// @notice Pause fToken mint in system stability mode.
  /// @param _status The pause status.
  function pauseFTokenMintInSystemStabilityMode(bool _status) external onlyEmergencyDAO {
    fTokenMintInSystemStabilityModePaused = _status;

    emit PauseFTokenMintInSystemStabilityMode(_status);
  }

  /// @notice Pause xToken redeem in system stability mode
  /// @param _status The pause status.
  function pauseXTokenRedeemInSystemStabilityMode(bool _status) external onlyEmergencyDAO {
    xTokenRedeemInSystemStabilityModePaused = _status;

    emit PauseXTokenRedeemInSystemStabilityMode(_status);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Internal function to deduct fToken mint fee for base token.
  /// @param _baseIn The amount of base token.
  /// @param _ratio The mint fee ratio.
  /// @param _maxBaseInBeforeSystemStabilityMode The maximum amount of base token can be deposit before entering system stability mode.
  /// @return _baseInWithoutFee The amount of base token without fee.
  function _deductFTokenMintFee(
    uint256 _baseIn,
    FeeRatio memory _ratio,
    uint256 _maxBaseInBeforeSystemStabilityMode
  ) internal returns (uint256 _baseInWithoutFee) {
    // [0, _maxBaseInBeforeSystemStabilityMode) => default = fee_ratio_0
    // [_maxBaseInBeforeSystemStabilityMode, infinity) => default + extra = fee_ratio_1

    uint256 _feeRatio0 = _ratio.defaultFeeRatio;
    uint256 _feeRatio1 = uint256(int256(_ratio.defaultFeeRatio) + _ratio.extraFeeRatio);

    _baseInWithoutFee = _defuctMintFee(_baseIn, _feeRatio0, _feeRatio1, _maxBaseInBeforeSystemStabilityMode);
  }

  /// @dev Internal function to deduct fToken mint fee for base token.
  /// @param _baseIn The amount of base token.
  /// @param _ratio The mint fee ratio.
  /// @param _maxBaseInBeforeSystemStabilityMode The maximum amount of base token can be deposit before entering system stability mode.
  /// @return _baseInWithoutFee The amount of base token without fee.
  function _deductXTokenMintFee(
    uint256 _baseIn,
    FeeRatio memory _ratio,
    uint256 _maxBaseInBeforeSystemStabilityMode
  ) internal returns (uint256 _baseInWithoutFee) {
    // [0, _maxBaseInBeforeSystemStabilityMode) => default + extra = fee_ratio_0
    // [_maxBaseInBeforeSystemStabilityMode, infinity) => default = fee_ratio_1

    uint256 _feeRatio0 = uint256(int256(_ratio.defaultFeeRatio) + _ratio.extraFeeRatio);
    uint256 _feeRatio1 = _ratio.defaultFeeRatio;

    _baseInWithoutFee = _defuctMintFee(_baseIn, _feeRatio0, _feeRatio1, _maxBaseInBeforeSystemStabilityMode);
  }

  function _defuctMintFee(
    uint256 _baseIn,
    uint256 _feeRatio0,
    uint256 _feeRatio1,
    uint256 _maxBaseInBeforeSystemStabilityMode
  ) internal returns (uint256 _baseInWithoutFee) {
    uint256 _maxBaseIn = _maxBaseInBeforeSystemStabilityMode.mul(PRECISION).div(PRECISION - _feeRatio0);

    // compute fee
    uint256 _fee;
    if (_baseIn <= _maxBaseIn) {
      _fee = _baseIn.mul(_feeRatio0).div(PRECISION);
    } else {
      _fee = _maxBaseIn.mul(_feeRatio0).div(PRECISION);
      _fee = _fee.add((_baseIn - _maxBaseIn).mul(_feeRatio1).div(PRECISION));
    }

    _baseInWithoutFee = _baseIn.sub(_fee);
    // take fee to platform
    if (_fee > 0) {
      IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, platform, _fee);
    }
  }

  /// @dev Internal function to deduct mint fee for base token.
  /// @param _amountIn The amount of fToken.
  /// @param _ratio The redeem fee ratio.
  /// @param _maxInBeforeSystemStabilityMode The maximum amount of fToken can be redeemed before leaving system stability mode.
  /// @return _feeRatio The computed fee ratio for base token redeemed.
  function _computeFTokenRedeemFeeRatio(
    uint256 _amountIn,
    FeeRatio memory _ratio,
    uint256 _maxInBeforeSystemStabilityMode
  ) internal pure returns (uint256 _feeRatio) {
    // [0, _maxBaseInBeforeSystemStabilityMode) => default + extra = fee_ratio_0
    // [_maxBaseInBeforeSystemStabilityMode, infinity) => default = fee_ratio_1

    uint256 _feeRatio0 = uint256(int256(_ratio.defaultFeeRatio) + _ratio.extraFeeRatio);
    uint256 _feeRatio1 = _ratio.defaultFeeRatio;

    _feeRatio = _computeRedeemFeeRatio(_amountIn, _feeRatio0, _feeRatio1, _maxInBeforeSystemStabilityMode);
  }

  /// @dev Internal function to deduct mint fee for base token.
  /// @param _amountIn The amount of xToken.
  /// @param _ratio The redeem fee ratio.
  /// @param _maxInBeforeSystemStabilityMode The maximum amount of xToken can be redeemed before entering system stability mode.
  /// @return _feeRatio The computed fee ratio for base token redeemed.
  function _computeXTokenRedeemFeeRatio(
    uint256 _amountIn,
    FeeRatio memory _ratio,
    uint256 _maxInBeforeSystemStabilityMode
  ) internal pure returns (uint256 _feeRatio) {
    // [0, _maxBaseInBeforeSystemStabilityMode) => default = fee_ratio_0
    // [_maxBaseInBeforeSystemStabilityMode, infinity) => default + extra = fee_ratio_1

    uint256 _feeRatio0 = _ratio.defaultFeeRatio;
    uint256 _feeRatio1 = uint256(int256(_ratio.defaultFeeRatio) + _ratio.extraFeeRatio);

    _feeRatio = _computeRedeemFeeRatio(_amountIn, _feeRatio0, _feeRatio1, _maxInBeforeSystemStabilityMode);
  }

  /// @dev Internal function to deduct mint fee for base token.
  /// @param _amountIn The amount of fToken or xToken.
  /// @param _feeRatio0 The default fee ratio.
  /// @param _feeRatio1 The second fee ratio.
  /// @param _maxInBeforeSystemStabilityMode The maximum amount of fToken/xToken can be redeemed before entering/leaving system stability mode.
  /// @return _feeRatio The computed fee ratio for base token redeemed.
  function _computeRedeemFeeRatio(
    uint256 _amountIn,
    uint256 _feeRatio0,
    uint256 _feeRatio1,
    uint256 _maxInBeforeSystemStabilityMode
  ) internal pure returns (uint256 _feeRatio) {
    if (_amountIn <= _maxInBeforeSystemStabilityMode) {
      return _feeRatio0;
    }
    uint256 _fee = _maxInBeforeSystemStabilityMode.mul(_feeRatio0);
    _fee = _fee.add((_amountIn - _maxInBeforeSystemStabilityMode).mul(_feeRatio1));
    return _fee.div(_amountIn);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMarket {
  /**********
   * Events *
   **********/

  /// @notice Emitted when fToken or xToken is minted.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param fTokenOut The amount of fToken minted.
  /// @param xTokenOut The amount of xToken minted.
  /// @param mintFee The amount of mint fee charged.
  event Mint(
    address indexed owner,
    address indexed recipient,
    uint256 baseTokenIn,
    uint256 fTokenOut,
    uint256 xTokenOut,
    uint256 mintFee
  );

  /// @notice Emitted when someone redeem base token with fToken or xToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param xTokenBurned The amount of xToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param redeemFee The amount of redeem fee charged.
  event Redeem(
    address indexed owner,
    address indexed recipient,
    uint256 fTokenBurned,
    uint256 xTokenBurned,
    uint256 baseTokenOut,
    uint256 redeemFee
  );

  /// @notice Emitted when someone add more base token.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param xTokenMinted The amount of xToken minted.
  event AddCollateral(address indexed owner, address indexed recipient, uint256 baseTokenIn, uint256 xTokenMinted);

  /// @notice Emitted when someone liquidate with fToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  event UserLiquidate(address indexed owner, address indexed recipient, uint256 fTokenBurned, uint256 baseTokenOut);

  /// @notice Emitted when self liquidate with fToken.
  /// @param caller The address of caller.
  /// @param baseSwapAmt The amount of base token used to swap.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param fTokenBurned The amount of fToken liquidated.
  event SelfLiquidate(address indexed caller, uint256 baseSwapAmt, uint256 baseTokenOut, uint256 fTokenBurned);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint both fToken and xToken with some base token.
  /// @param baseIn The amount of base token supplied.
  /// @param recipient The address of receiver for fToken and xToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mint(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted,
    uint256 minXTokenMinted
  ) external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint some fToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for fToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  function mintFToken(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted
  ) external returns (uint256 fTokenMinted);

  /// @notice Mint some xToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mintXToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Mint some xToken by add some base token as collateral.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function addBaseToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Redeem base token with fToken and xToken.
  /// @param fTokenIn the amount of fToken to redeem, use `uint256(-1)` to redeem all fToken.
  /// @param xTokenIn the amount of xToken to redeem, use `uint256(-1)` to redeem all xToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Permissionless liquidate some fToken to increase the collateral ratio.
  /// @param fTokenIn the amount of fToken to supply, use `uint256(-1)` to liquidate all fToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function liquidate(
    uint256 fTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate some fToken to increase the collateral ratio.
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param minFTokenLiquidated The minimum amount of fToken should be liquidated.
  /// @param data The data used to swap base token to fToken.
  /// @return baseOut The amount of base token should be received.
  /// @return fTokenLiquidated the amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 minFTokenLiquidated,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fTokenLiquidated);

  /// @notice Callback to swap base token to fToken
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param data The data passed to market contract.
  /// @return fTokenAmt The amount of fToken received.
  function onSelfLiquidate(uint256 baseSwapAmt, bytes calldata data) external returns (uint256 fTokenAmt);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITreasury {
  /**********
   * Events *
   **********/

  /// @notice Emitted when the net asset value is updated.
  /// @param price The new price of base token.
  /// @param fNav The new net asset value of fToken.
  event ProtocolSettle(uint256 price, uint256 fNav);

  /*********
   * Enums *
   *********/

  enum MintOption {
    Both,
    FToken,
    XToken
  }

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the address of base token.
  function baseToken() external view returns (address);

  /// @notice Return the address fractional base token.
  function fToken() external view returns (address);

  /// @notice Return the address leveraged base token.
  function xToken() external view returns (address);

  /// @notice Return the address of strategy contract.
  function strategy() external view returns (address);

  /// @notice The last updated permissioned base token price.
  function lastPermissionedPrice() external view returns (uint256);

  /// @notice Return the total amount of base token deposited.
  function totalBaseToken() external view returns (uint256);

  /// @notice Return the total amount of base token managed by strategy.
  function strategyUnderlying() external view returns (uint256);

  /// @notice Return the current collateral ratio of fToken, multipled by 1e18.
  function collateralRatio() external view returns (uint256);

  /// @notice Return current nav for base token, fToken and xToken.
  /// @return baseNav The nav for base token.
  /// @return fNav The nav for fToken.
  /// @return xNav The nav for xToken.
  function getCurrentNav()
    external
    view
    returns (
      uint256 baseNav,
      uint256 fNav,
      uint256 xNav
    );

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxFTokenMintable The amount of fToken can be minted.
  function maxMintableFToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxFTokenMintable);

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxXTokenMintable);

  /// @notice Compute the amount of base token needed to reach the new collateral ratio, with incentive.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXTokenWithIncentive(uint256 newCollateralRatio, uint256 incentiveRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxXTokenMintable);

  /// @notice Compute the amount of fToken needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseOut The amount of base token redeemed.
  /// @return maxFTokenRedeemable The amount of fToken needed.
  function maxRedeemableFToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxFTokenRedeemable);

  /// @notice Compute the amount of xToken needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseOut The amount of base token redeemed.
  /// @return maxXTokenRedeemable The amount of xToken needed.
  function maxRedeemableXToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxXTokenRedeemable);

  /// @notice Compute the maximum amount of fToken can be liquidated.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return maxBaseOut The maximum amount of base token can liquidate, without incentive.
  /// @return maxFTokenLiquidatable The maximum amount of fToken can be liquidated.
  function maxLiquidatable(uint256 newCollateralRatio, uint256 incentiveRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxFTokenLiquidatable);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint fToken and xToken with some base token.
  /// @param baseIn The amount of base token deposited.
  /// @param recipient The address of receiver.
  /// @param option The mint option, xToken or fToken or both.
  /// @return fTokenOut The amount of fToken minted.
  /// @return xTokenOut The amount of xToken minted.
  function mint(
    uint256 baseIn,
    address recipient,
    MintOption option
  ) external returns (uint256 fTokenOut, uint256 xTokenOut);

  /// @notice Redeem fToken and xToken to base tokne.
  /// @param fTokenIn The amount of fToken to redeem.
  /// @param xTokenIn The amount of xToken to redeem.
  /// @param owner The owner of the fToken or xToken.
  /// @param baseOut The amount of base token redeemed.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address owner
  ) external returns (uint256 baseOut);

  /// @notice Add some base token to mint xToken with incentive.
  /// @param baseIn The amount of base token deposited.
  /// @param incentiveRatio The incentive ratio.
  /// @param recipient The address of receiver.
  /// @return xTokenOut The amount of xToken minted.
  function addBaseToken(
    uint256 baseIn,
    uint256 incentiveRatio,
    address recipient
  ) external returns (uint256 xTokenOut);

  /// @notice Liquidate fToken to base token with incentive.
  /// @param fTokenIn The amount of fToken to liquidate.
  /// @param incentiveRatio The incentive ratio.
  /// @param owner The owner of the fToken.
  /// @param baseOut The amount of base token liquidated.
  function liquidate(
    uint256 fTokenIn,
    uint256 incentiveRatio,
    address owner
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate fToken to base token with incentive.
  /// @param baseSwapAmt The amount of base token used to buy fToken.
  /// @param incentiveRatio The incentive ratio.
  /// @param recipient The address of receiver of profited base token.
  /// @param data The calldata passed to market contract.
  /// @return baseOut The expected base token received.
  /// @return fAmt The amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 incentiveRatio,
    address recipient,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fAmt);

  /// @notice Cache the twap price.
  function cacheTwap() external;

  /// @notice Settle the nav of base token, fToken and xToken.
  function protocolSettle() external;

  /// @notice Transfer some base token to strategy contract.
  /// @param amount The amount of token to transfer.
  function transferToStrategy(uint256 amount) external;

  /// @notice Notify base token profit from strategy contract.
  /// @param amount The amount of base token.
  function notifyStrategyProfit(uint256 amount) external;
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

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
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

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
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

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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