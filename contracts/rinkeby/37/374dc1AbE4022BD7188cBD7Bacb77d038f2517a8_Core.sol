// SPDX-License-Identifier: MIT

import './storage/CoreStorage.sol';
import './interfaces/ICore.sol';
import '../managers/interfaces/IIncentiveManager.sol';
import '../managers/interfaces/ILoanManager.sol';
import '../managers/interfaces/ILiquidationManager.sol';
import '../pool/interfaces/IPool.sol';
import '../pool/interfaces/IDebtToken.sol';
import './libraries/ERC20Metadata.sol';
import './libraries/Factory.sol';
import './logic/Validation.sol';
import './logic/Index.sol';
import './logic/Rate.sol';
import './logic/Treasury.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

pragma solidity 0.8.4;

/// @title Core
/// @notice ELYFI has various contract interactions centered on the Core contract.
/// Several tokens are issued or destroyed to indicate the status of participants,
/// and all issuance and burn processes are carried out through the Core contract.
/// The depositor and borrower should approve the ELYFI core contract to move their AssetBond token
/// or ERC20 tokens on their behalf.
contract Core is ICore, CoreStorage {
  using SafeERC20 for IERC20;
  using Index for PoolData;
  using Validation for PoolData;
  using Rate for PoolData;
  using Treasury for PoolData;
  using Math for uint256;

  constructor(IProtocolAddressProvider protocolAddressProvider, address interestRateModel) {
    _protocolAddressProvider = protocolAddressProvider;
    _interestRateModel = interestRateModel;
  }

  /// ************** Modifiers ************* ///

  modifier onlyGuardian() {
    if (msg.sender != _protocolAddressProvider.getGuardian()) revert OnlyGuardian();
    _;
  }

  modifier onlyGovernance() {
    if (msg.sender != _protocolAddressProvider.getGovernance()) revert OnlyGovernance();
    _;
  }

  modifier onlyCouncil() {
    if (msg.sender != _protocolAddressProvider.getCouncil()) revert OnlyCouncil();
    _;
  }

  /// ************** User Interactions ************* ///

  /// @inheritdoc ICore
  /// @custom:check - make sure that pool is active and not paused
  /// @custom:check - `amount` is not 0
  /// @custom:effect - update interest rate and pool state
  /// @custom:interaction - `asset.safeTransferFrom`
  ///   - transfer underlying asset from `msg.sender` to `pool`
  /// @custom:interaction - call `pool.mint`
  ///   - mint poolToken to `account`
  /// @custom:interaction - `incentiveManager.updateUserIncentive`
  ///   - update user incentive
  /// @custom:interaction emit `Deposit` event
  function deposit(
    address asset,
    address account,
    uint256 amount
  ) external override {
    PoolData storage poolData = _poolData[asset];

    poolData.validateDeposit(amount);

    uint256 newIndex = poolData.updatePoolIndex(asset);

    poolData.updateRates(asset, address(_interestRateModel), amount, 0);

    address poolAddress = poolData.poolAddress;

    IERC20(asset).safeTransferFrom(msg.sender, poolAddress, amount);

    IPool(poolAddress).mint(account, amount, newIndex);

    emit Deposit(asset, account, amount);
  }

  /// @inheritdoc ICore
  /// @custom:check - make sure that pool is active and not paused
  /// @custom:check - `amount` is not 0
  /// @custom:check - `amount` exceeds pool available liquidity
  /// @custom:effect - update interest rate and pool state
  /// @custom:interaction - call `pool.burnAndTransferAsset`
  ///   - burn poolToken from `msg.sender` and transfer underlying asset to `account`
  /// @custom:interaction - emit `Withdraw` event
  function withdraw(
    address asset,
    address receiver,
    uint256 amount
  ) external override {
    PoolData storage poolData = _poolData[asset];

    address poolAddress = poolData.poolAddress;

    uint256 userPoolTokenBalance = IPool(poolAddress).balanceOf(msg.sender);

    uint256 amountToWithdraw = amount;

    // if amount is equal to uint(-1), the user wants to redeem everything
    if (amount == type(uint256).max) {
      amountToWithdraw = userPoolTokenBalance;
    }

    uint256 newIndex = poolData.updatePoolIndex(asset);

    poolData.validateWithdraw(asset, amountToWithdraw, userPoolTokenBalance);

    uint256 stabilityFee = poolData.getStabilityFee(
      asset,
      _protocolAddressProvider.getProtocolTreasury(),
      amountToWithdraw
    );

    poolData.updateRates(asset, address(_interestRateModel), stabilityFee, amountToWithdraw);

    if (stabilityFee != 0) {
      IPool(poolData.poolAddress).mintToProtocolTreasury(stabilityFee, newIndex);
    }

    IPool(poolAddress).burnAndTransferAsset(
      msg.sender,
      receiver,
      amountToWithdraw,
      amountToWithdraw - stabilityFee,
      newIndex
    );

    emit Withdraw(asset, msg.sender, receiver, amountToWithdraw);
  }

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the council governance contract
  /// @custom:check - make sure that pool is active and not paused
  /// @custom:check - `amount` should be less than `asset.balanceOf(pool)`
  /// @custom:check - call `onERC721Received` and check that erc721 is whitelisted one
  /// @custom:effect - update interest rate and pool state
  /// @custom:interaction - call `_accrueProtocolTreasury`
  ///   - accrue protocol treasury
  /// @custom:interaction - call `loanManager.beginLoan`
  ///   - hash loan and save loan data in the loanManager
  /// @custom:interaction - call `debtToken.mint`
  ///   - mint debt token to borrower
  /// @custom:interaction - call `pool.transferAsset`
  ///   - transfer loan principal to `receiver`
  /// @custom:interaction - call `collateral.safeTransferFrom`
  ///   - transfer asset token from `borrower` to `receiver`
  ///   - asset token to be collateralized should be approved for core `address(this)`
  /// @custom:interaction - emit `Borrow` event
  function borrow(
    address asset,
    address collateral,
    address borrower,
    address receiver,
    uint256 tokenId,
    uint256 loanPrincipal,
    uint256 loanDuration,
    string memory description
  ) external override onlyCouncil {
    PoolData storage poolData = _poolData[asset];

    bytes32 descriptionHash = keccak256(bytes(description));

    uint256 poolRemainingLiquidity = IERC20(asset).balanceOf(poolData.poolAddress);
    uint256 loanInterestRate = poolData.borrowAPY;

    poolData.validateBorrow(loanPrincipal, poolRemainingLiquidity);

    uint256 interestIndex = poolData.getPoolTokenInterestIndex();

    poolData.accrueLoanFee(interestIndex);

    poolData.updatePoolIndex(asset);

    ILoanManager(_protocolAddressProvider.getLoanManager()).beginLoan(
      borrower,
      asset,
      collateral,
      tokenId,
      loanPrincipal,
      loanDuration,
      loanInterestRate,
      descriptionHash
    );

    IDebtToken(poolData.debtTokenAddress).mint(borrower, loanPrincipal, loanInterestRate);

    poolData.updateRates(asset, address(_interestRateModel), 0, loanPrincipal);

    IPool(poolData.poolAddress).transferAsset(receiver, loanPrincipal);

    IERC721(collateral).safeTransferFrom(borrower, address(this), tokenId);

    emit Borrow(
      asset,
      collateral,
      borrower,
      receiver,
      tokenId,
      loanPrincipal,
      loanInterestRate,
      loanDuration,
      description
    );
  }

  /// @inheritdoc ICore
  /// @custom:check - call `loanManager.repayLoan`
  ///   - loan must not be `DEFAULTED`
  /// @custom:effect - update interest rate and pool state
  ///   - burn debt token from `borrower` and transfer
  /// @custom:interaction call `loanManager.repayLoan`
  ///   - change loan state to `END`
  /// @custom:interaction - call `_accrueProtocolTreasury`
  ///   - accrue protocol treasury
  /// @custom:interaction - call `asset.safeTransferFrom`
  ///   - transfer principal and interest from `msg.sender` to `pool`
  /// @custom:interaction - call `debtToken.burn`
  ///   - burn debt token from `borrower`
  /// @custom:interaction - call `collateral.safeTransferFrom`
  ///   - transfer collateralized asset token from the core contract to `borrower`
  function repay(
    address asset,
    address collateral,
    address borrower,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external override {
    PoolData storage poolData = _poolData[asset];

    (uint256 loanState, uint256 repayAmount, uint256 loanInterestRate) = ILoanManager(
      _protocolAddressProvider.getLoanManager()
    ).repayLoan(borrower, asset, collateral, tokenId, descriptionHash);

    poolData.validateRepay(loanState);

    uint256 interestIndex = poolData.getPoolTokenInterestIndex();

    poolData.accrueLoanFee(interestIndex);

    poolData.updatePoolIndex(asset);

    IERC20(asset).safeTransferFrom(msg.sender, poolData.poolAddress, repayAmount);

    IDebtToken(poolData.debtTokenAddress).burn(borrower, repayAmount);

    poolData.updateRates(asset, address(_interestRateModel), repayAmount, 0);

    IERC721(collateral).safeTransferFrom(address(this), borrower, tokenId);

    emit Repay(
      asset,
      collateral,
      borrower,
      msg.sender,
      tokenId,
      repayAmount,
      loanInterestRate,
      block.timestamp
    );
  }

  /// @inheritdoc ICore
  /// @custom:check - call `loanManager.repayLoan`
  ///   - loan must be `DEFAULTED`
  /// @custom:effect - update interest rate and pool state
  ///   - burn debt token from `borrower` and transfer
  /// @custom:interaction - call `loanManager.repayLoan`
  ///   - change loan state to `END`
  /// @custom:interaction - call `liquidationManager.liquidate`
  ///   - transfer principal and interest from `msg.sender` to `pool` by LiquidationManager
  /// @custom:interaction - call `collateral.safeTransferFrom`
  ///   - transfer collateralized asset token to `liquidationManager`
  /// @custom:interaction - call `debtToken.burn`
  ///   - burn debt token from `borrower`
  function liquidate(
    address asset,
    address collateral,
    address borrower,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external override {
    PoolData storage poolData = _poolData[asset];

    uint256 previousRemainingLiquiditiy = IERC20(asset).balanceOf(poolData.poolAddress);

    uint256 loanId = ILoanManager(_protocolAddressProvider.getLoanManager()).hashLoan(
      borrower,
      asset,
      collateral,
      msg.sender,
      tokenId,
      descriptionHash
    );

    (uint256 loanState, uint256 repayAmount, uint256 loanInterestRate) = ILoanManager(
      _protocolAddressProvider.getLoanManager()
    ).repayLoan(borrower, asset, collateral, tokenId, descriptionHash);

    ILiquidationManager(_protocolAddressProvider.getLiquidationManager()).liquidate(
      asset,
      poolData.poolAddress,
      msg.sender,
      loanId,
      repayAmount
    );

    {
      uint256 remainingLiquiditiy = IERC20(asset).balanceOf(poolData.poolAddress);

      poolData.validateLiquidate(
        loanState,
        repayAmount,
        previousRemainingLiquiditiy,
        remainingLiquiditiy
      );
    }

    uint256 interestIndex = poolData.getPoolTokenInterestIndex();

    poolData.accrueLoanFee(interestIndex);

    poolData.updatePoolIndex(asset);

    IDebtToken(poolData.debtTokenAddress).burn(borrower, repayAmount);

    poolData.updateRates(asset, address(_interestRateModel), repayAmount, 0);

    IERC721(collateral).safeTransferFrom(
      address(this),
      _protocolAddressProvider.getLiquidationManager(),
      tokenId
    );

    emit Liquidate(
      asset,
      collateral,
      borrower,
      msg.sender,
      tokenId,
      repayAmount,
      loanInterestRate,
      block.timestamp
    );
  }

  /// @inheritdoc ICore
  /// @custom:interaction - call `_accrueProtocolTreasury`
  ///   - mint pool token the amount of debt token accrued multiplied by the pool factor
  function accrueProtocolTreasury(address asset) external override {
    PoolData storage poolData = _poolData[asset];

    uint256 currentIndex = poolData.getPoolTokenInterestIndex();

    poolData.accrueLoanFee(currentIndex);

    IDebtToken(poolData.debtTokenAddress).updateDebtTokenState();
  }

  /// ************** Governance Functions ************* ///

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the governance contract
  /// @custom:effect - set new `_interestRateModel`
  /// @custom:interaction - emit `UpdateInterestRateModel` event
  function updateInterestRateModel(address interestRateModel) external override onlyGovernance {
    address previousInterestRateModel = _interestRateModel;
    _interestRateModel = interestRateModel;
    emit UpdateInterestRateModel(previousInterestRateModel, interestRateModel);
  }

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the governance.
  /// @custom:effect - set `_allowedAssetToken[assetToken]` to true
  /// @custom:interaction - emit `AllowAssetToken` event
  function allowAssetToken(address assetToken) external override onlyGovernance {
    _allowedAssetToken[assetToken] = true;
    emit AllowAssetToken(assetToken);
  }

  /// @inheritdoc ICore
  /// @custom:check - Make sure that `msg.sender` is core contract
  /// @custom:check - PoolData with `asset` does not already exist
  /// @custom:effect - Deploy Pool and DebtToken contract and store its data
  /// @custom:interaction - call `incentiveManager.setIncentivePlan`
  ///   - set incentive plan with given allocation for given asset
  /// @custom:interaction - emit `AddNewPool` event
  function addNewPool(
    address asset,
    uint256 incentiveAllocation,
    uint256 poolFactor
  ) external override {
    // use temporary storage to allow pool and debt token contract to call ERC20Metadata
    _assetToAdd = asset;
    (address poolAddress, address debtTokenAddress) = Factory.createPool(asset);
    _assetToAdd = address(0);

    PoolData memory newPoolData = PoolData({
      poolInterestIndex: Math.ray(),
      borrowAPY: 0,
      depositAPY: 0,
      lastUpdateTimestamp: block.timestamp,
      poolFactor: poolFactor,
      poolAddress: poolAddress,
      debtTokenAddress: debtTokenAddress,
      isPaused: false,
      isActivated: true
    });

    _poolData[asset] = newPoolData;

    IIncentiveManager(_protocolAddressProvider.getIncentiveManager()).setIncentivePlan(
      poolAddress,
      incentiveAllocation
    );

    emit AddNewPool(poolAddress, debtTokenAddress);
  }

  /// ************** Guardian Functions ************* ///

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the guardian address
  /// @custom:effect - set `poolData[asset].isActive` to true
  /// @custom:interaction - emit `ActivatePool` event
  function activatePool(address asset) external override onlyGuardian {
    PoolData storage poolData = _poolData[asset];
    poolData.isActivated = true;
    emit ActivatePool(asset, block.timestamp);
  }

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the guardian address
  /// @custom:effect - set `poolData[asset].isActive` to false
  /// @custom:interaction - emit `DeactivatePool` event
  function deactivatePool(address asset) external override onlyGuardian {
    PoolData storage poolData = _poolData[asset];
    poolData.isActivated = false;
    emit DeactivatePool(asset, block.timestamp);
  }

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the guardian address
  /// @custom:effect - set `poolData[asset].isPaused` to true
  /// @custom:interaction - emit `PausePool` event
  function pausePool(address asset) external override onlyGuardian {
    PoolData storage poolData = _poolData[asset];
    poolData.isPaused = true;
    emit PausePool(asset, block.timestamp);
  }

  /// @inheritdoc ICore
  /// @custom:check - make sure that `msg.sender` is the guardian address
  /// @custom:effect - set `poolData[asset].isPaused` to false
  /// @custom:interaction - emit `UnpausePool` event
  function unpausePool(address asset) external override onlyGuardian {
    PoolData storage poolData = _poolData[asset];
    poolData.isPaused = false;
    emit UnpausePool(asset, block.timestamp);
  }

  /// ************** View Functions ************* ///

  /// @inheritdoc ICore
  function getPoolData(address asset)
    external
    view
    override
    returns (
      uint256 poolInterestIndex,
      uint256 borrowAPY,
      uint256 depositAPY,
      uint256 lastUpdateTimestamp,
      uint256 poolFactor,
      address poolAddress,
      address debtTokenAddress,
      bool isPaused,
      bool isActivated
    )
  {
    PoolData storage poolData = _poolData[asset];

    poolInterestIndex = poolData.poolInterestIndex;
    borrowAPY = poolData.borrowAPY;
    depositAPY = poolData.depositAPY;
    lastUpdateTimestamp = poolData.lastUpdateTimestamp;
    poolFactor = poolData.poolFactor;
    poolAddress = poolData.poolAddress;
    debtTokenAddress = poolData.debtTokenAddress;
    isPaused = poolData.isPaused;
    isActivated = poolData.isActivated;
  }

  /// @inheritdoc ICore
  function getPoolInterestIndex(address asset)
    external
    view
    override
    returns (uint256 poolInterestIndex)
  {
    PoolData storage poolData = _poolData[asset];

    poolInterestIndex = poolData.getPoolTokenInterestIndex();
  }

  /// @inheritdoc ICore
  function getProtocolAddressProvider()
    external
    view
    override
    returns (address protocolAddressProvider)
  {
    protocolAddressProvider = address(_protocolAddressProvider);
  }

  /// @inheritdoc ICore
  function getInterestRateModel() external view override returns (address interestRateModel) {
    interestRateModel = _interestRateModel;
  }

  /// @inheritdoc ICore
  function getProtocolTreasury() external view override returns (address protocolTreasury) {
    protocolTreasury = _protocolAddressProvider.getProtocolTreasury();
  }

  /// @inheritdoc ICore
  function getAssetTokenAllowed(address assetToken) external view override returns (bool allowed) {
    return _allowedAssetToken[assetToken];
  }

  /// @inheritdoc ICore
  function getAssetAdded() external view override returns (address asset) {
    asset = _assetToAdd;
  }

  /// @inheritdoc ICore
  function getERC20NameSafe(address asset) external view override returns (string memory name) {
    name = ERC20Metadata.tokenName(asset);
  }

  /// @inheritdoc ICore
  function getERC20SymbolSafe(address asset) external view override returns (string memory symbol) {
    symbol = ERC20Metadata.tokenSymbol(asset);
  }

  /// @notice Upon receiving an allowed asset token, checks if the asset token is listed
  /// @inheritdoc IERC721Receiver
  /// @custom:check - make sure that `msg.sender` is listed asset token contract.
  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    if (!_allowedAssetToken[msg.sender]) revert NotAllowedAssetToken();

    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT

import '../../managers/interfaces/IProtocolAddressProvider.sol';
import '../interfaces/IInterestRateModel.sol';
import '../../managers/interfaces/IIncentiveManager.sol';

pragma solidity 0.8.4;

abstract contract CoreStorage {
  /// @notice Pool state and configuration
  struct PoolData {
    uint256 poolInterestIndex;
    uint256 borrowAPY;
    uint256 depositAPY;
    uint256 lastUpdateTimestamp;
    uint256 poolFactor;
    address poolAddress;
    address debtTokenAddress;
    bool isPaused;
    bool isActivated;
  }

  address internal _assetToAdd;

  mapping(address => PoolData) internal _poolData;

  IProtocolAddressProvider internal _protocolAddressProvider;

  address internal _interestRateModel;

  mapping(address => bool) internal _allowedAssetToken;
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '../../managers/interfaces/IProtocolAddressProvider.sol';

pragma solidity 0.8.4;

error NotAllowedAssetToken();

interface ICore is IERC721Receiver {
  /// @notice Emitted on deposit()
  /// @param asset The address of the asset deposited
  /// @param account The address initiating the deposit
  /// @param amount The amount deposited
  event Deposit(address asset, address indexed account, uint256 amount);

  /// @notice Emitted on withdraw()
  /// @param asset The address of the asset withdrawed
  /// @param account The address initiating the withdrawal
  /// @param receiver  The address that will receive the asset withdrawed
  /// @param amount The amount to be withdrawn
  event Withdraw(address asset, address indexed account, address indexed receiver, uint256 amount);

  /// @notice Emitted on borrow()
  /// @param asset The address of the underlying asset to borrow
  /// @param collateral The address of the asset token to be collateralized
  /// @param borrower The address of account who will collateralize the asset token and begin the loan
  /// @param receiver The address of account who will receive the loan principal
  /// @param tokenId The id of the token to be collateralized
  /// @param loanPrincipal The original sum of money transferred from lender to borrower at the beginning of the loan
  /// @param loanInterestRate  The interest rate of the loan issued
  /// @param loanDuration The amount of time (measured in seconds) that can elapse before the lender can liquidate the loan and seize the underlying collateral NFT
  /// @param description Description for the loan
  event Borrow(
    address asset,
    address collateral,
    address indexed borrower,
    address indexed receiver,
    uint256 tokenId,
    uint256 loanPrincipal,
    uint256 loanInterestRate,
    uint256 loanDuration,
    string description
  );

  /// @notice Emitted on repay()
  /// @param asset The address of the underlying asset to repay
  /// @param collateral The address of the asset token collateralized
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param repayer The address of account who repay the loan
  /// @param tokenId The id of the token returned to the receiver
  /// @param repayAmount The amount of asset repayed
  /// @param loanInterestRate The interst rate of the loan repayed
  /// @param timestamp The timestamp repayed
  event Repay(
    address asset,
    address collateral,
    address indexed borrower,
    address indexed repayer,
    uint256 tokenId,
    uint256 repayAmount,
    uint256 loanInterestRate,
    uint256 timestamp
  );

  /// @notice Emitted on liquidate()
  /// @param asset The address of the underlying asset to liquidate
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param liquidator The address of account who liquidate the loan
  /// @param tokenId The id of the token given to the liquidation manager
  /// @param repayAmount The amount of asset repayed
  /// @param loanInterestRate The interst rate of the loan liquidated
  /// @param timestamp The timestamp liquidated
  event Liquidate(
    address asset,
    address collateral,
    address indexed borrower,
    address indexed liquidator,
    uint256 tokenId,
    uint256 repayAmount,
    uint256 loanInterestRate,
    uint256 timestamp
  );

  /// @notice Emitted on updateInterestRateModel()
  /// @param previousInterestRateModel The address of the previous interest rate model contract
  /// @param interestRateModel The address of the interest rate model to use
  event UpdateInterestRateModel(address previousInterestRateModel, address interestRateModel);

  /// @notice Emitted on activatePool()
  /// @param asset The address of the underlying asset of the pool
  /// @param timestamp The timestamp activated
  event ActivatePool(address asset, uint256 timestamp);

  /// @notice Emitted on deactivatePool()
  /// @param asset The address of the underlying asset of the pool
  /// @param timestamp The timestamp deactivated
  event DeactivatePool(address asset, uint256 timestamp);

  /// @notice Emitted on pausePool()
  /// @param asset The address of the underlying asset of the pool
  /// @param timestamp The timestamp paused
  event PausePool(address asset, uint256 timestamp);

  /// @notice Emitted on unpausePool()
  /// @param asset The address of the underlying asset of the pool
  /// @param timestamp The timestamp unpaused
  event UnpausePool(address asset, uint256 timestamp);

  /// @notice Emitted on addNewPool()
  /// @param pool The address of the pool added
  /// @param debtToken The address of the debt token created
  event AddNewPool(address pool, address debtToken);

  /// @notice Emitted on allowAssetToken()
  /// @param assetToken The address of the ERC-721 asset token allowed
  event AllowAssetToken(address assetToken);

  /// @notice By depositing assets in the pool and supply liquidity, depositors can receive
  /// interest accruing from the pool. The return on the deposit arises from the interest on loans.
  /// MoneyPool depositors who deposit certain assets receives pool token equivalent to
  /// the deposit amount. Pool tokens are backed by assets deposited in the pool in a 1:1 ratio.
  /// @param asset The address of the underlying asset to deposit
  /// @param account The address that will receive the LToken
  /// @param amount Deposit amount
  function deposit(
    address asset,
    address account,
    uint256 amount
  ) external;

  /// @notice The depositors can seize their assets deposited in the pool whenever they wish.
  /// User can withdraw an amount of underlying asset from the pool and burn the corresponding pool tokens.
  /// @param asset The address of the underlying asset to withdraw
  /// @param receiver The address that will receive the underlying asset
  /// @param amount Withdrawl amount
  function withdraw(
    address asset,
    address receiver,
    uint256 amount
  ) external;

  /// @notice The user can take out a loan of value below to the principal
  /// recorded in the asset bond data. As asset token is deposited as collateral in the ...(TODO)
  /// and loans are made, financial services that link real assets and cryptoassets can be achieved.
  /// @param asset The address of the underlying asset to borrow
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param receiver The address of account who will receive the loan principal
  /// @param tokenId The id of the token to collateralize
  /// @param loanPrincipal The original sum of money transferred from lender to borrower at the beginning of the loan
  /// @param loanDuration The amount of time (measured in seconds) that can elapse before the lender can liquidate the loan and seize the underlying collateral NFT
  /// @param description Description for the loan
  function borrow(
    address asset,
    address collateral,
    address borrower,
    address receiver,
    uint256 tokenId,
    uint256 loanPrincipal,
    uint256 loanDuration,
    string memory description
  ) external;

  /// @notice Repay function
  /// @param asset The address of the underlying asset to repay
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param tokenId The id of the token to be collateralized
  /// @param descriptionHash Description hash for the loan
  function repay(
    address asset,
    address collateral,
    address borrower,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external;

  /// @notice Liquidation function
  /// @param asset The address of the underlying asset to liquidate
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param tokenId The id of the token to be collateralized
  /// @param descriptionHash Description hash for the loan
  function liquidate(
    address asset,
    address collateral,
    address borrower,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external;

  /// @notice This function accrues protocol treasury calculated based on the debt token data by minting pool token to treasury contract
  /// @param asset The address of the underlying asset of the pool
  function accrueProtocolTreasury(address asset) external;

  /// @notice This function can be called when new pool added
  /// Only callable by the core contract
  /// @param asset Underlying asset address to add
  /// @param incentiveAllocation Incentive allocation for the given pool in incentive pool
  function addNewPool(
    address asset,
    uint256 incentiveAllocation,
    uint256 poolFactor
  ) external;

  /// @notice This function updates the address of interestRateModel contract
  /// @param interestRateModel The address of interestRateModel contract
  function updateInterestRateModel(address interestRateModel) external;

  /// @notice Allow an asset token that can be used for collateral for the loan in the protocol
  /// @param assetToken The address of the asset token
  function allowAssetToken(address assetToken) external;

  /// @notice Activates a pool
  /// @param asset The address of the underlying asset of the pool
  function activatePool(address asset) external;

  /// @notice Deactivates a pool
  /// @param asset The address of the underlying asset of the pool
  function deactivatePool(address asset) external;

  /// @notice Pause a pool. A paused pool doesn't allow any new deposit, borrow or rate swap
  /// but allows repayments, liquidations, rate rebalances and withdrawals
  /// @param asset The address of the underlying asset of the pool
  function pausePool(address asset) external;

  /// @notice Unpause a pool
  /// @param asset The address of the underlying asset of the pool
  function unpausePool(address asset) external;

  /// @notice Returns the state and configuration of the pool
  /// @param asset Underlying asset address
  /// @return poolInterestIndex The poolInterestIndex recently updated and stored in. Not current index
  /// @return borrowAPY The current borrowAPY expressed in RAY
  /// @return depositAPY The current depositAPY expressed in RAY
  /// @return lastUpdateTimestamp The protocol last updated timestamp
  /// @return poolFactor The pool factor expressed in ray
  /// @return poolAddress The address of the pool contract
  /// @return debtTokenAddress The address of the debt token contract
  /// @return isPaused The pool is paused
  /// @return isActivated The pool is activated
  function getPoolData(address asset)
    external
    view
    returns (
      uint256 poolInterestIndex,
      uint256 borrowAPY,
      uint256 depositAPY,
      uint256 lastUpdateTimestamp,
      uint256 poolFactor,
      address poolAddress,
      address debtTokenAddress,
      bool isPaused,
      bool isActivated
    );

  /// @notice This function calculates and returns the current `poolInterestIndex`
  /// @param asset The address of the underlying asset of the pool
  /// @notice poolInterestIndex current poolInterestIndex calculated
  function getPoolInterestIndex(address asset) external view returns (uint256 poolInterestIndex);

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The instance of protocolAddressProvider contract
  function getProtocolAddressProvider() external view returns (address protocolAddressProvider);

  /// @notice This function returns the address of interestRateModel contract
  /// @return interestRateModel The address of `InterestRateModel` contract
  function getInterestRateModel() external view returns (address interestRateModel);

  /// @notice This function returns the address of protocol treasury contract
  /// @return protocolTreasury The address of `ProtocolTreasury` contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function returns the address of interestRateModel contract
  /// @return allowed Whether the given assetToken address is allowed or not
  function getAssetTokenAllowed(address assetToken) external view returns (bool allowed);

  /// @notice This function return temporary storage slot in add new pool
  /// @return asset Returns the address of asset to added only in the `addNewPool` tx, Others, returns `address(0)`
  function getAssetAdded() external view returns (address asset);

  /// @notice This function calls an external view token contract method that returns name, and parses the output into a string
  /// @param asset The address of the token contract
  /// @return name the name of the token. If not exists, it generates randomly
  function getERC20NameSafe(address asset) external view returns (string memory name);

  /// @notice This function calls an external view token contract method that returns symbol, and parses the output into a string
  /// @param asset The address of the token contract
  /// @return symbol the symbol of the token. If not exists, it generates randomly
  function getERC20SymbolSafe(address asset) external view returns (string memory symbol);
}

// SPDX-License-Identifier: MIT

import './IProtocolAddressProvider.sol';

pragma solidity 0.8.4;

interface IIncentiveManager {
  /// @notice Emitted when new incentive plan setup
  event SetIncentivePlan(address pool, uint256 allocation, uint256 totalAllocation);

  /// @notice Emitted when user incentive is updated.
  event UpdateUserIncentive(address pool, address account, uint256 incentive);

  /// @notice Emitted when user incentive index is updated.
  event UpdateUserIndex(address pool, address account, uint256 index);

  /// @notice Emitted when plan index is updated.
  event UpdatePlanState(address pool, uint256 incentive, uint256 lastUpdateTimestamp);

  /// @notice Emitted when a plan allocation is updated.
  event PlanAllocationUpdated(address pool, uint256 newAllocation, uint256 totalAllocation);

  /// @notice Update user incentive index, incentive index, and last update timestamp on minting or burining pool token.
  /// @param pool incentive plan to update
  /// @param account user account
  function updateUserIncentive(address pool, address account) external;

  /// @notice Update only incentive index and timestamp when _totalAllocation or allocation of a pool is updated. In this case, userIndex remains the same.
  /// @param pool incentive plan to update
  function updatePlanState(address pool) external;

  /// @notice User can claim their accrued incentive by calling this function.
  /// @param pool plan to claim
  function claimIncentive(address pool) external;

  /// @notice Init the new incentive plan when new pool added
  /// @param pool plan to add
  /// @param allocation allocation for the plan
  function setIncentivePlan(address pool, uint256 allocation) external;

  /// @notice Update incentive allocation of the `_incentivePlan[pool]`
  /// @dev Mass update should be followed after update plan allocation
  /// @param pool plan to update
  /// @param newAllocation new allocation for the plan
  function updatePlanAllocation(address pool, uint256 newAllocation) external;

  /// @notice Update total incentive
  /// @dev Mass update should be followed after update total incentive
  /// @param totalIncentivePerSecond new total incentive
  function updateTotalIncentive(uint256 totalIncentivePerSecond) external;

  /// @notice Hook that is called before any transfer of tokens.
  /// @dev If a user transfered lToken, accrued reward will be updated and user index will be set to the current index
  /// @param pool token to transfer
  /// @param from the address transferred from
  /// @param to the address transferred to
  function beforeTokenTransfer(
    address pool,
    address from,
    address to
  ) external;

  /// @notice Returns the current incentive index of the pool given a pool address
  /// @param pool The pool to get incentive index
  /// @return The current incentive index of the pool
  function getPlanIndex(address pool) external view returns (uint256);

  /// @notice Returns user accrued incentive with plan
  /// @param pool plan to get
  /// @param user user account
  /// @return incentive user accrued incentive
  function getUserIncentive(address pool, address user) external view returns (uint256 incentive);

  /// @notice Returns incentive plan data for given pool
  /// @param pool incentive plan
  /// @return lastUpdateTimestamp Last incentive update timestamp of the pool
  /// @return planIndex Current incentive index of the pool
  /// @return poolAllocatedIncentive pool allocated incentive
  /// @return allocation incentive allocation for given pool
  function getIncentivePlanData(address pool)
    external
    view
    returns (
      uint256 lastUpdateTimestamp,
      uint256 planIndex,
      uint256 poolAllocatedIncentive,
      uint256 allocation
    );

  function getUserIncentivePlanData(address pool, address user)
    external
    view
    returns (
      uint256 userIndex,
      uint256 userPreviousIncentive,
      uint256 userIncentive
    );

  /// @notice returns incentive manager data
  /// @return incentiveAsset incentive pool address
  function getIncentiveManagerData()
    external
    view
    returns (
      address incentiveAsset,
      uint256 totalIncentivePerSecond,
      uint256 totalAllocation
    );

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The address of protocolAddressProvider contract
  function getProtocolAddressProvider()
    external
    view
    returns (IProtocolAddressProvider protocolAddressProvider);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ILoanManager {
  event LoanBegin(
    address indexed borrower,
    address asset,
    address collateral,
    uint256 loanId,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 duration,
    uint256 interestRate,
    bytes32 descriptionHash
  );

  event LoanRepaid(
    address asset,
    address collateral,
    address borrower,
    uint256 loanId,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 repayAmount,
    uint256 repayTimestamp
  );

  /// @notice This function can be called when new loan begins. The loan detail hashed.
  /// Only callable by core contract
  /// @param borrower The borrower address
  /// @param asset The address of the ERC20 contract of the currency being used as principal/interest for this loan.
  /// @param collateral The address of the ERC721 contract of the asset token being collateralized for this loan.
  /// @param tokenId The id of the token which is used as collateral of this loan
  /// @param principalAmount The original sum of money transferred from lender to borrower at the beginning of the loan
  /// @param duration The amount of time (measured in seconds) that can elapse before the lender can liquidate the loan
  // and seize the underlying collateral NFT
  /// @param interestRate The interest rate for the loan
  /// @param descriptionHash The description hash of loan
  /// @return loanId The id of loan initialized which is build from hashing the loan struct
  function beginLoan(
    address borrower,
    address asset,
    address collateral,
    uint256 tokenId,
    uint256 principalAmount,
    uint256 duration,
    uint256 interestRate,
    bytes32 descriptionHash
  ) external returns (uint256 loanId);

  /// @notice This function can be called when loan redeemed
  /// @param borrower The borrower address
  /// @param asset The address of the ERC20 contract of the currency being used as principal/interest for this loan.
  /// @param collateral The address of the ERC721 contract of the asset token being collateralized for this loan.
  /// @param tokenId The id of the token which is collateralized for the loan
  /// @param descriptionHash bytes32 which itself is the keccak256 hash of the description string
  /// @return loanState returns the loan state prior to the action
  function repayLoan(
    address borrower,
    address asset,
    address collateral,
    uint256 tokenId,
    bytes32 descriptionHash
  )
    external
    returns (
      uint256 loanState,
      uint256 repayAmount,
      uint256 loanInterestRate
    );

  /// @notice Hashing function used to build the loan id from the loan detail
  /// - borrower: the address of the borrower who begins the loan and will receive collateral after redemption of the loan
  /// - asset: underlying asset address for the loan principal
  /// - collateral: asset token address for the loan collateral
  /// - core: the address of the core contract executing the borrow which can be passed as `msg.sender`
  /// - tokenId: the id of the token for the loan collateral
  /// - descriptionHash: the description for the loan which is posted in the protocol forum
  /// @param borrower The address of the borrower
  /// @param asset description
  /// @param collateral description
  /// @param core The address of the core contract
  /// @param tokenId The id of the token which is collateralized for the loan
  /// @param descriptionHash bytes32 which itself is the keccak256 hash of the description string
  /// @return loanId The loan id produced by hashing the loan data
  function hashLoan(
    address borrower,
    address asset,
    address collateral,
    address core,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external pure returns (uint256 loanId);

  /// @notice This function return the data of the loan
  /// @param loanId The loan id
  /// @return principalAmount The principal amount of the loan
  /// @return startTimestamp Loan start timestamp
  /// @return dueTimestamp Loan due timestamp
  /// @return interestRate The interest rate of the loan
  /// @return loanState The state of the loan
  function getLoan(uint256 loanId)
    external
    view
    returns (
      uint256 principalAmount,
      uint256 startTimestamp,
      uint256 dueTimestamp,
      uint256 interestRate,
      uint256 loanState
    );

  /// @notice This function returns the state of the loan
  /// @dev It checks the state of the asset token first. If the current asset token state from the assetTokenStateOracle is invalid, the loan state is `DEFAULTED`
  /// After then, it compares the current block timestamp and loan timestamps
  /// @param assetToken The address of the assetToken
  /// @param loanId The loan id
  /// @param tokenId The id of the token collateralized
  /// @return loanState The loan state
  function getLoanState(
    address assetToken,
    uint256 loanId,
    uint256 tokenId
  ) external view returns (uint256 loanState);

  /// @notice This function compute and return the amount for redepmtion of the loan based on the loan data
  /// @param loanId The loan id
  /// @return amountToRepay Amount to repay
  function getRepaymentAmount(uint256 loanId) external view returns (uint256 amountToRepay);

  /// @notice ElysiaProvider address to validate and check the state of asset token.
  /// @return assetTokenStateProvider The address of AssetTokenStateProvider contract
  function getAssetTokenStateProvider() external view returns (address assetTokenStateProvider);

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The address of protocolAddressProvider contract
  function getProtocolAddressProvider() external view returns (address protocolAddressProvider);
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import './IProtocolAddressProvider.sol';

pragma solidity 0.8.4;

interface ILiquidationManager is IERC721ReceiverUpgradeable {
  event Liquidate(address asset, address pool, address liquidator, uint256 loanId, uint256 amount);

  event DepositLiquidationReserve(
    address asset,
    address account,
    uint256 amount,
    uint256 timestamp
  );

  event WithdrawLiquidationReserve(
    address asset,
    address account,
    uint256 amount,
    uint256 timestamp
  );

  /// @notice Liquidate loan. This function can be called by the core contract
  function liquidate(
    address asset,
    address pool,
    address liquidator,
    uint256 loanId,
    uint256 amount
  ) external;

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The address of protocolAddressProvider contract
  function getProtocolAddressProvider()
    external
    view
    returns (IProtocolAddressProvider protocolAddressProvider);

  /// @notice User can deposit asset to liquidationManager contract to supply reserve for the liquidation
  /// @param asset The address of the asset
  /// @param amount amount to deposit
  function deposit(address asset, uint256 amount) external;

  /// @notice User who deposited can withdraw asset from this contract
  /// @param asset The address of the asset
  /// @param amount amount to withdraw
  function withdraw(address asset, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

import './IPoolToken.sol';

pragma solidity 0.8.4;

interface IPool is IPoolToken {
  /// @notice Mints pool tokens account `account`
  /// @param account The address of the user who will receive the pool tokens
  /// @param amount The amount being minted
  /// @param index The new interest index of the pool
  function mint(
    address account,
    uint256 amount,
    uint256 index
  ) external;

  /// @notice When user withdraw, pool contract burns pool tokens from `account`and transfer underlying asset to `receiver`
  /// This function is only callable by the core contract
  /// @param account The owner of the pool tokens
  /// @param receiver The address that will receive the underlying asset
  /// @param amountToBurn The amount being pool token burned
  /// @param amountToTransfer The amount being asset transferred
  /// @param poolInterestIndex The new interest index of the pool
  function burnAndTransferAsset(
    address account,
    address receiver,
    uint256 amountToBurn,
    uint256 amountToTransfer,
    uint256 poolInterestIndex
  ) external;

  /// @notice Transfers the underlying asset to receiver.
  /// @param receiver The recipient of the underlying asset
  /// @param amount The amount being transferred to receiver
  function transferAsset(address receiver, uint256 amount) external;

  /// @notice This function returns the underlying asset of this pool
  /// @return underlyingAsset The underlying asset of the pool
  function getUnderlyingAsset() external view returns (address underlyingAsset);

  /// @notice This function mints the `amount` of pool token to the `_protocolTreasury`
  /// @param amount Amount to mint
  /// @param index The current interest index of the pool
  function mintToProtocolTreasury(uint256 amount, uint256 index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IDebtToken is IERC20Metadata {
  /// @notice Emitted when new debt token is minted
  /// @param account The address of the account who triggered the minting
  /// @param amount The amount minted
  /// @param currentBalance The current balance of the account
  /// @param balanceIncrease The increase in balance since the last action of the account
  /// @param newRate The rate of the debt after the minting
  /// @param averageBorrowRate The new average rate after the minting
  /// @param newTotalSupply The new total supply of the debt token after the action
  event Mint(
    address indexed account,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 averageBorrowRate,
    uint256 newTotalSupply
  );

  /// @notice Emitted when new debt is burned
  /// @param account The address of the account
  /// @param amount The amount being burned
  /// @param currentBalance The current balance of the account
  /// @param balanceIncrease The the increase in balance since the last action of the account
  /// @param averageBorrowRate The new average rate after the burning
  /// @param newTotalSupply The new total supply of the debt token after the action
  event Burn(
    address indexed account,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 averageBorrowRate,
    uint256 newTotalSupply
  );

  /// @notice Mints debt token to the `receiver` address.
  /// - The resulting rate is the weighted average between the rate of the new debt
  /// and the rate of the previous debt
  /// @param account The address receiving the borrowed underlying, being the delegatee in case
  /// of credit delegate, or same as `receiver` otherwise
  /// @param amount The amount of debt tokens to mint
  /// @param rate The borrow rate of the loan which is same as current pool borrowAPY
  function mint(
    address account,
    uint256 amount,
    uint256 rate
  ) external;

  /// @notice Burns debt of `account`
  /// - The resulting rate is the weighted average between the rate of the new debt
  /// and the rate of the previous debt
  /// @param account The address of the account getting his debt burned
  /// @param amount The amount of debt tokens getting burned
  function burn(address account, uint256 amount) external;

  /// @notice Returns the average rate of all the rate loans.
  /// @return totalAverageBorrowRate Total average borrow rate
  function getTotalAverageBorrowRate() external view returns (uint256 totalAverageBorrowRate);

  /// @notice Returns the rate of the account debt
  /// @return averageBorrowRate The rate of the account
  function getUserAverageBorrowRate(address account)
    external
    view
    returns (uint256 averageBorrowRate);

  /// @notice Returns the timestamp of the last update of the account
  /// @return userLastUpdateTimestamp User debt token last update timestamp
  function getUserLastUpdateTimestamp(address account)
    external
    view
    returns (uint256 userLastUpdateTimestamp);

  /// @notice Returns the principal, the total supply and the average rate
  function getDebtTokenData()
    external
    view
    returns (
      uint256 principalDebtTokenSupply,
      uint256 totalDebtTokenSupply,
      uint256 averageBorrowRate,
      uint256 debtTokenLastUpdateTimestamp
    );

  /// @notice Returns the timestamp of the last update of the total supply
  /// @return lastUpdateTimestamp The timestamp
  function getDebtTokenLastUpdateTimestamp() external view returns (uint256 lastUpdateTimestamp);

  /// @notice Returns the total supply and the average rate
  /// @return totalSupply The totalSupply
  /// @return averageBorrowRate The average borrow rate
  function getTotalSupplyAndAverageBorrowRate()
    external
    view
    returns (uint256 totalSupply, uint256 averageBorrowRate);

  /// @notice Returns the principal debt balance of the account
  /// @return principalBalance balance of the account since the last burn/mint action
  function principalBalanceOf(address account) external view returns (uint256 principalBalance);

  /// @notice Update the total supply and last updated timestamp of the debt token
  function updateDebtTokenState() external;

  /// @notice Returns the amount of accrued debt since the last update timestamp
  /// @return accruedDebt The amount of accrued debt since the last update timestamp
  function getAccruedDebt() external view returns (uint256 accruedDebt);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library ERC20Metadata {
  function bytes32ToString(bytes32 x) private pure returns (string memory) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 j = 0; j < 32; j++) {
      bytes1 char = x[j];
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint256 j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  // calls an external view token contract method that returns a symbol or name, and parses the output into a string
  function callAndParseStringReturn(address token, bytes4 selector)
    private
    view
    returns (string memory)
  {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
    // if not implemented, or returns empty data, return empty string
    if (!success || data.length == 0) {
      return '';
    }
    // bytes32 data always has length 32
    if (data.length == 32) {
      bytes32 decoded = abi.decode(data, (bytes32));
      return bytes32ToString(decoded);
    } else if (data.length > 64) {
      return abi.decode(data, (string));
    }
    return '';
  }

  // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
  function tokenSymbol(address token) external view returns (string memory) {
    string memory symbol = callAndParseStringReturn(token, IERC20Metadata.symbol.selector);
    if (bytes(symbol).length == 0) {
      // fallback to 6 uppercase hex of address
      return Strings.toHexString(uint256(keccak256(abi.encode(token))), 32);
    }
    return symbol;
  }

  // attempts to extract the token name. if it does not implement name, returns a name derived from the address
  function tokenName(address token) external view returns (string memory) {
    string memory name = callAndParseStringReturn(token, IERC20Metadata.name.selector);
    if (bytes(name).length == 0) {
      // fallback to full hex of address
      return Strings.toHexString(uint256(keccak256(abi.encode(token))), 32);
    }
    return name;
  }
}

// SPDX-License-Identifier: MIT

import '../../pool/Pool.sol';
import '../../pool/tokens/DebtToken.sol';

import '@openzeppelin/contracts/utils/Create2.sol';

pragma solidity 0.8.4;

/// @title Factory
/// @notice Factory for new pool and debt token contract
library Factory {
  function createPool(address asset)
    external
    returns (address poolAddress, address debtTokenAddress)
  {
    bytes32 salt = keccak256(abi.encodePacked(asset, block.timestamp));
    poolAddress = Create2.deploy(0, salt, type(Pool).creationCode);
    debtTokenAddress = Create2.deploy(0, salt, type(DebtToken).creationCode);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../storage/CoreStorage.sol';
import '../libraries/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @notice Emitted when the amount is zero
error ZeroAmount();

/// @notice Emitted when the pool is paused
error PoolPaused();

/// @notice Emitted when the pool is deactivated
error PoolDeactivated();

/// @notice Emitted when the pool token balance of the user is not enough
error NotEnoughPoolTokenBalance();

/// @notice Emitted when the remaining pool liquidity is insufficient
error InsufficientLiquidity();

/// @notice Emitted when the repaying a loan is not allowed by the core contract
error RepayLoanNotAllowed();

/// @notice Emitted when the liquidation of the loan is not allowed by the core contract
error LiquidateLoanNotAllowed();

/// @notice Emitted when the amount of the asset transferred from the liquidation manager is insufficient
error InsufficientLiquidationAmount();

/// @notice Emitted when the withdrawl amount exceed pool remaining liquidity
error WithdrawAmountExceedLiquidity();

library Validation {
  using Math for uint256;

  /// @dev Validate Deposit
  /// Check pool state
  /// @param pool The pool object
  /// @param amount Deposit amount
  function validateDeposit(CoreStorage.PoolData storage pool, uint256 amount) internal view {
    if (amount == 0) revert ZeroAmount();
    if (pool.isPaused == true) revert PoolPaused();
    if (pool.isActivated == false) revert PoolDeactivated();
  }

  function validateWithdraw(
    CoreStorage.PoolData storage pool,
    address asset,
    uint256 amount,
    uint256 userPoolTokenBalance
  ) internal view {
    uint256 poolRemainingLiquidity = IERC20(asset).balanceOf(pool.poolAddress);
    if (amount == 0) revert ZeroAmount();
    if (pool.isPaused == true) revert PoolPaused();
    if (amount > userPoolTokenBalance) revert NotEnoughPoolTokenBalance();
    if (poolRemainingLiquidity < amount) revert WithdrawAmountExceedLiquidity();
  }

  /// @dev Validate Borrow
  /// Check pool state
  /// @param pool The pool object
  function validateBorrow(
    CoreStorage.PoolData storage pool,
    uint256 loanPrincipal,
    uint256 poolRemainingLiquidity
  ) internal view {
    if (loanPrincipal == 0) revert ZeroAmount();
    if (pool.isPaused == true) revert PoolPaused();
    if (pool.isActivated == false) revert PoolDeactivated();
    if (loanPrincipal > poolRemainingLiquidity) revert InsufficientLiquidity();
  }

  /// @dev Validate Repay
  /// Check pool state
  /// @param pool The pool object
  function validateRepay(CoreStorage.PoolData storage pool, uint256 loanState) internal view {
    if (loanState != 0) revert RepayLoanNotAllowed();
  }

  /// @dev Validate Deposit
  /// Check pool state
  /// @param pool The pool object
  function validateLiquidate(
    CoreStorage.PoolData storage pool,
    uint256 loanState,
    uint256 repayAmount,
    uint256 previousRemainingLiquiditiy,
    uint256 remainingLiquiditiy
  ) internal view {
    if (loanState != 1) revert LiquidateLoanNotAllowed();
    if (repayAmount + previousRemainingLiquiditiy != remainingLiquiditiy)
      revert InsufficientLiquidationAmount();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../storage/CoreStorage.sol';
import '../libraries/Math.sol';
import '../libraries/Calculation.sol';

library Index {
  using Math for uint256;

  event PoolInterestIndexUpdated(
    address indexed asset,
    uint256 lTokenIndex,
    uint256 lastUpdateTimestamp
  );

  /**
   * @dev Returns the ongoing normalized income for the pool
   * A value of 1e27 means there is no income. As time passes, the income is accrued
   * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param pool The pool object
   * @return the normalized income. expressed in ray
   **/
  function getPoolTokenInterestIndex(CoreStorage.PoolData storage pool)
    internal
    view
    returns (uint256)
  {
    uint256 lastUpdateTimestamp = pool.lastUpdateTimestamp;

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (lastUpdateTimestamp == block.timestamp) {
      return pool.poolInterestIndex;
    }

    uint256 newIndex = Calculation
      .calculateLinearInterest(pool.depositAPY, lastUpdateTimestamp, block.timestamp)
      .rayMul(pool.poolInterestIndex);

    return newIndex;
  }

  /**
   * @dev Updates the pool indexes and the timestamp
   * @param pool The pool to be updated
   **/
  function updatePoolIndex(CoreStorage.PoolData storage pool, address asset)
    internal
    returns (uint256 newIndex)
  {
    if (pool.depositAPY == 0) {
      pool.lastUpdateTimestamp = block.timestamp;
      return pool.poolInterestIndex;
    }

    pool.poolInterestIndex = getPoolTokenInterestIndex(pool);
    pool.lastUpdateTimestamp = block.timestamp;

    emit PoolInterestIndexUpdated(asset, pool.poolInterestIndex, pool.lastUpdateTimestamp);

    return pool.poolInterestIndex;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../storage/CoreStorage.sol';
import '../libraries/Calculation.sol';
import '../../pool/interfaces/IPool.sol';
import '../../pool/interfaces/IDebtToken.sol';
import '../interfaces/IInterestRateModel.sol';

library Rate {
  event RatesUpdated(
    address indexed asset,
    uint256 poolInterestIndex,
    uint256 borrowAPY,
    uint256 depositAPY,
    uint256 totalBorrow,
    uint256 totalDeposit
  );

  struct UpdateRatesLocalVars {
    uint256 debtTokenTotalSupply;
    uint256 newBorrowAPY;
    uint256 newDepositAPY;
    uint256 averageBorrowAPY;
  }

  function updateRates(
    CoreStorage.PoolData storage poolData,
    address asset,
    address interestRateModel,
    uint256 depositAmount,
    uint256 borrowAmount
  ) internal {
    UpdateRatesLocalVars memory vars;

    vars.debtTokenTotalSupply = IDebtToken(poolData.debtTokenAddress).totalSupply();

    vars.averageBorrowAPY = IDebtToken(poolData.debtTokenAddress).getTotalAverageBorrowRate();

    uint256 poolRemainingLiquidity = IERC20(asset).balanceOf(poolData.poolAddress);
    (vars.newBorrowAPY, vars.newDepositAPY) = IInterestRateModel(interestRateModel).calculateRates(
      asset,
      poolRemainingLiquidity + depositAmount - borrowAmount,
      vars.debtTokenTotalSupply,
      poolData.poolFactor
    );

    poolData.borrowAPY = vars.newBorrowAPY;
    poolData.depositAPY = vars.newDepositAPY;

    emit RatesUpdated(
      asset,
      poolData.poolInterestIndex,
      vars.newBorrowAPY,
      vars.newDepositAPY,
      vars.debtTokenTotalSupply,
      poolRemainingLiquidity + depositAmount - borrowAmount + vars.debtTokenTotalSupply
    );
  }

  function getUtilizationRate(
    CoreStorage.PoolData storage poolData,
    address asset,
    address interestRateModel,
    uint256 depositAmount,
    uint256 borrowAmount
  ) internal view returns (uint256) {
    uint256 debtTokenTotalSupply = IDebtToken(poolData.debtTokenAddress).totalSupply();
    uint256 poolRemainingLiquidity = IERC20(asset).balanceOf(poolData.poolAddress);
    return
      IInterestRateModel(interestRateModel).getUtilizationRate(
        debtTokenTotalSupply,
        poolRemainingLiquidity + depositAmount - borrowAmount
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../storage/CoreStorage.sol';
import '../libraries/Calculation.sol';
import '../libraries/Math.sol';
import '../../pool/interfaces/IPool.sol';
import '../../pool/interfaces/IDebtToken.sol';
import '../interfaces/IInterestRateModel.sol';
import '../../managers/interfaces/IProtocolTreasury.sol';

library Treasury {
  using Math for uint256;

  struct UpdateRatesLocalVars {
    uint256 debtTokenTotalSupply;
    uint256 newBorrowAPY;
    uint256 newDepositAPY;
    uint256 averageBorrowAPY;
  }

  function getStabilityFee(
    CoreStorage.PoolData storage poolData,
    address asset,
    address treasury,
    uint256 withdrawAmount
  ) internal view returns (uint256 fee) {
    (uint256 totalDebtTokenSupply, ) = IDebtToken(poolData.debtTokenAddress)
      .getTotalSupplyAndAverageBorrowRate();

    uint256 poolRemainingLiquidity = IERC20(asset).balanceOf(poolData.poolAddress);

    uint256 stabilityFeeRate = IProtocolTreasury(treasury).calculateStabilityFeeRate(
      totalDebtTokenSupply,
      poolRemainingLiquidity,
      poolRemainingLiquidity - withdrawAmount
    );

    return withdrawAmount.rayMul(stabilityFeeRate);
  }

  function accrueLoanFee(CoreStorage.PoolData storage poolData, uint256 interestIndex) internal {
    uint256 accruedDebt = IDebtToken(poolData.debtTokenAddress).getAccruedDebt();

    uint256 accruedProtocolTreasury = accruedDebt.rayMul(Math.RAY - poolData.poolFactor);

    IPool(poolData.poolAddress).mintToProtocolTreasury(accruedProtocolTreasury, interestIndex);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

error OnlyGovernance();
error OnlyGuardian();
error OnlyCouncil();
error OnlyCore();

interface IProtocolAddressProvider {
  /// @notice emitted when liquidationManager address updated
  event UpdateLiquidationManager(address liquidationManager);

  /// @notice emitted when loanManager address updated
  event UpdateLoanManager(address loanManager);

  /// @notice emitted when incentiveManager address updated
  event UpdateIncentiveManager(address incentiveManager);

  /// @notice emitted when governance address updated
  event UpdateGovernance(address governance);

  /// @notice emitted when council address updated
  event UpdateCouncil(address council);

  /// @notice emitted when core address updated
  event UpdateCore(address core);

  /// @notice emitted when treasury address updated
  event UpdateTreasury(address treasury);

  /// @notice emitted when protocol address provider initialized
  event ProtocolAddressProviderInitialized(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treausury
  );

  /// @notice ProtocolAddressProvider should be initialized after deploying protocol contracts finished.
  /// @param guardian guardian
  /// @param liquidationManager liquidationManager
  /// @param loanManager loanManager
  /// @param incentiveManager incentiveManager
  /// @param governance governance
  /// @param council council
  /// @param core core
  /// @param treasury treasury
  function initialize(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treasury
  ) external;

  /// @notice This function returns the address of the guardian
  /// @return guardian The address of the protocol guardian
  function getGuardian() external view returns (address guardian);

  /// @notice This function returns the address of liquidationManager contract
  /// @return liquidationManager The address of liquidationManager contract
  function getLiquidationManager() external view returns (address liquidationManager);

  /// @notice This function returns the address of LoanManager contract
  /// @return loanManager The address of LoanManager contract
  function getLoanManager() external view returns (address loanManager);

  /// @notice This function returns the address of incentiveManager contract
  /// @return incentiveManager The address of incentiveManager contract
  function getIncentiveManager() external view returns (address incentiveManager);

  /// @notice This function returns the address of governance contract
  /// @return governance The address of governance contract
  function getGovernance() external view returns (address governance);

  /// @notice This function returns the address of council contract
  /// @return council The address of council contract
  function getCouncil() external view returns (address council);

  /// @notice This function returns the address of core contract
  /// @return core The address of core contract
  function getCore() external view returns (address core);

  /// @notice This function returns the address of protocolTreasury contract
  /// @return protocolTreasury The address of protocolTreasury contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function updates the address of liquidationManager contract
  /// @param liquidationManager The address of liquidationManager contract to update
  function updateLiquidationManager(address liquidationManager) external;

  /// @notice This function updates the address of LoanManager contract
  /// @param loanManager The address of LoanManager contract to update
  function updateLoanManager(address loanManager) external;

  /// @notice This function updates the address of incentiveManager contract
  /// @param incentiveManager The address of incentiveManager contract to update
  function updateIncentiveManager(address incentiveManager) external;

  /// @notice This function updates the address of governance contract
  /// @param governance The address of governance contract to update
  function updateGovernance(address governance) external;

  /// @notice This function updates the address of council contract
  /// @param council The address of council contract to update
  function updateCouncil(address council) external;

  /// @notice This function updates the address of core contract
  /// @param core The address of core contract to update
  function updateCore(address core) external;

  /// @notice This function updates the address of treasury contract
  /// @param treasury The address of treasury contract to update
  function updateTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '../../managers/interfaces/IProtocolAddressProvider.sol';

interface IInterestRateModel {
  /// @param optimalUtilizationRate New optimalUtilizationRate
  event UpdateOptimalUtilizationRate(uint256 optimalUtilizationRate);

  /// @param borrowRateBase New borrowRateBase
  event UpdateBorrowRateBase(uint256 borrowRateBase);

  /// @param borrowRateOptimal New borrowRateOptimal
  event UpdateBorrowRateOptimal(uint256 borrowRateOptimal);

  /// @param borrowRateMax New borrowRateMax
  event UpdateBorrowRateMax(uint256 borrowRateMax);

  /// @param asset Underlying asset address to added
  /// @param optimalUtilizationRate The new optimalUtilizationRate
  /// @param borrowRateBase The new borrowRateBase
  /// @param borrowRateOptimal The new borrowRateOptimal
  /// @param borrowRateMax The new borrowRateMax
  event AddNewPoolInterestRateModel(
    address asset,
    uint256 optimalUtilizationRate,
    uint256 borrowRateBase,
    uint256 borrowRateOptimal,
    uint256 borrowRateMax
  );

  /// @notice Calculates the interest rates based on the token balances.
  /// @dev Calculation Example
  /// - Case1: under optimal U
  ///   - baseRate = 2%, util = 40%, optimalRate = 10%, optimalUtil = 80%
  ///   - result = 2+40*(10-2)/80 = 4%
  /// - Case2: over optimal U
  ///   - optimalRate = 10%, util = 90%, maxRate = 100%, optimalUtil = 80%
  ///   - result = 10+(90-80)*(100-10)/(100-80) = 55%
  /// @param asset Underlying asset address
  /// @param poolRemainingLiquidityAfterAction Pool remaining liquidity after the deposit or borrow
  /// @param totalDebtTokenSupply Total debt token supply
  /// @param poolFactor The pool factor for reserve
  /// @return newBorrowAPY Calculeted borrowAPY
  /// @return newDepositAPY Calculeted depositAPY
  function calculateRates(
    address asset,
    uint256 poolRemainingLiquidityAfterAction,
    uint256 totalDebtTokenSupply,
    uint256 poolFactor
  ) external view returns (uint256 newBorrowAPY, uint256 newDepositAPY);

  /// @notice This function can be called when new pool added to add new interest rate model
  /// Only callable by the core contract
  /// @param asset Underlying asset address to added
  /// @param optimalUtilizationRate The new optimalUtilizationRate
  /// @param borrowRateBase The new borrowRateBase
  /// @param borrowRateOptimal The new borrowRateOptimal
  /// @param borrowRateMax The new borrowRateMax
  function addNewPoolInterestRateModel(
    address asset,
    uint256 optimalUtilizationRate,
    uint256 borrowRateBase,
    uint256 borrowRateOptimal,
    uint256 borrowRateMax
  ) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param optimalUtilizationRate New optimalUtilizationRate to update
  function updateOptimalUtilizationRate(address asset, uint256 optimalUtilizationRate) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param borrowRateBase New optimalUtilizationRate to update
  function updateBorrowRateBase(address asset, uint256 borrowRateBase) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param borrowRateOptimal New optimalUtilizationRate to update
  function updateBorrowRateOptimal(address asset, uint256 borrowRateOptimal) external;

  /// @notice This function can be called by governance to update interest rate model param
  /// Only callable by the governance contract
  /// @param asset Underlying asset address to update model
  /// @param borrowRateMax New optimalUtilizationRate to update
  function updateBorrowRateMax(address asset, uint256 borrowRateMax) external;

  /// @notice This function returns interest rate model params for asset
  /// @param asset Underlying asset address
  /// @return optimalUtilizationRate When the pool utilization ratio exceeds this parameter, the kinked rates model adjusts interests.
  /// @return borrowRateBase The interest rate when utilization ratio is zero.
  /// @return borrowRateOptimal The interest rate when the pool utilization ratio is optimal.
  /// @return borrowRateMax The interest rate when the pool utilization ratio is 1.
  function getInterestRateModelParam(address asset)
    external
    view
    returns (
      uint256 optimalUtilizationRate,
      uint256 borrowRateBase,
      uint256 borrowRateOptimal,
      uint256 borrowRateMax
    );

  /// @notice This function returns the current utilization rate of the pool for the asset
  /// @param totalDebt The total debt borrowed from the pool
  /// @param availableLiquidity The remaining liquidity of the pool
  /// @return utilizationRate The current utilization rate of the pool for the asset.
  function getUtilizationRate(
    uint256 totalDebt,
    uint256 availableLiquidity
  )
    external
    pure
    returns (uint256 utilizationRate);

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The address of protocolAddressProvider contract
  function getProtocolAddressProvider()
    external
    returns (IProtocolAddressProvider protocolAddressProvider);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPoolToken is IERC20 {
  /// @notice Emitted after pool tokens are minted
  /// @param account The receiver of minted pool token
  /// @param amount The amount being minted
  /// @param index The new interest index of the pool
  event Mint(address indexed account, uint256 amount, uint256 index);

  /// @notice Emitted after pool tokens are burned
  /// @param account The owner of the pool tokens, getting them burned
  /// @param receiver The address that will receive the underlying asset
  /// @param amount The amount being burned
  /// @param index The new interest index of the pool
  event Burn(address indexed account, address indexed receiver, uint256 amount, uint256 index);

  /// @notice Emitted during the transfer action
  /// @param account The account whose tokens are being transferred
  /// @param to The recipient
  /// @param amount The amount being transferred
  /// @param index The new interest index of the pool
  event BalanceTransfer(address indexed account, address indexed to, uint256 amount, uint256 index);

  /// @notice Returns the address of the underlying asset of this pool tokens (E.g. USDC for pool USDC token)
  /// @return implicitBalance Implicit balance of `account`
  function implicitBalanceOf(address account) external view returns (uint256 implicitBalance);

  /// @notice Returns the address of the underlying asset of this pool tokens (E.g. USDC for pool USDC token)
  /// @return implicitTotalSupply_ Implicit total supply of the pool token
  function implicitTotalSupply() external view returns (uint256 implicitTotalSupply_);
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

import "../IERC20.sol";

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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

import './tokens/PoolToken.sol';
import './interfaces/IPool.sol';

import '../core/libraries/Math.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

pragma solidity 0.8.4;

/// @title Pool
/// @notice Pool contract is the reserve of the underlying asset. If users deposit or withdraw assets from the Pool Contract, the contract automatically
/// issues or destroys Pool Tokens accordingly. Pool Tokens are the basis for repayment of loans and interest on their deposits.
contract Pool is IPool, PoolToken {
  using SafeERC20 for IERC20;
  using Math for uint256;

  constructor()
    PoolToken(
      string(
        abi.encodePacked(
          'Elyfi_',
          ICore(msg.sender).getERC20NameSafe(ICore(msg.sender).getAssetAdded()),
          '_PoolToken'
        )
      ),
      string(
        abi.encodePacked(
          'ELFI_',
          ICore(msg.sender).getERC20SymbolSafe(ICore(msg.sender).getAssetAdded()),
          '_PT'
        )
      )
    )
  {}

  /// @inheritdoc IPool
  /// @custom:check - check that `msg.sender` should be the address of `core`
  ///   - call `_core.getCore()`
  /// @custom:effect - mint poolToken to `account` address
  function mint(
    address account,
    uint256 amount,
    uint256 index
  ) external override onlyCore {
    uint256 implicitBalance = amount.rayDiv(index);

    _mint(account, implicitBalance);

    emit Mint(account, implicitBalance, index);
  }

  /// @inheritdoc IPool
  /// @custom:check - check that `msg.sender` should be the address of `core`
  ///   - call `_core.getCore()`
  /// @custom:effect - `burn` pool token `amountToBurn`
  /// @custom:interaction - `asset.transfer`
  ///   - transfer `amountToTransfer`
  function burnAndTransferAsset(
    address account,
    address receiver,
    uint256 amountToBurn,
    uint256 amountToTransfer,
    uint256 poolInterestIndex
  ) external override onlyCore {
    uint256 implicitBalance = amountToBurn.rayDiv(poolInterestIndex);

    _burn(account, implicitBalance);

    IERC20(_underlyingAsset).safeTransfer(receiver, amountToTransfer);

    emit Burn(account, receiver, implicitBalance, poolInterestIndex);
  }

  /// @inheritdoc IPool
  /// @custom:check - check that `msg.sender` should be the address of `core`
  ///   - call `_core.getCore()`
  /// @custom:interaction - `asset.transfer` `amount` to `receiver`
  function transferAsset(address receiver, uint256 amount) external override {
    IERC20(_underlyingAsset).safeTransfer(receiver, amount);
  }

  /// @inheritdoc IPool
  /// @custom:check - check that `msg.sender` should be the address of `core`
  ///   - call `_core.getCore()`
  /// @custom:effect - mint poolToken to `_protocolTreasury` contract
  function mintToProtocolTreasury(uint256 amount, uint256 index) external override {
    uint256 implicitBalance = amount.rayDiv(index);

    _mint(_protocolTreasury, implicitBalance);
  }

  /// @inheritdoc IPool
  function getUnderlyingAsset() external view override returns (address underlyingAsset) {
    underlyingAsset = _underlyingAsset;
  }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../interfaces/IDebtToken.sol';
import '../../core/interfaces/ICore.sol';
import '../../core/libraries/Math.sol';
import '../../core/libraries/Calculation.sol';

pragma solidity 0.8.4;

/// @title DebtToken
/// @notice Dedt token represents for user debt principal and accured interest
contract DebtToken is IDebtToken, Context {
  using Math for uint256;
  uint256 internal _averageBorrowRate;
  uint256 internal _lastUpdateTimestamp;
  mapping(address => uint256) internal _userLastUpdateTimestamp;
  mapping(address => uint256) internal _userAverageBorrowRate;

  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;

  string private _name;
  string private _symbol;

  ICore internal _core;
  address internal _underlyingAsset;

  constructor() {
    _name = string(
      abi.encodePacked(
        'Elyfi_',
        ICore(msg.sender).getERC20NameSafe(ICore(msg.sender).getAssetAdded()),
        '_DebtToken'
      )
    );
    _symbol = string(
      abi.encodePacked(
        'ELFI_',
        ICore(msg.sender).getERC20SymbolSafe(ICore(msg.sender).getAssetAdded()),
        '_DT'
      )
    );
    _core = ICore(msg.sender);
  }

  modifier onlyCore() {
    require(msg.sender == address(_core), 'Only Core');
    _;
  }

  /// @dev Returns the name of the token.
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /// @dev Returns the symbol of the token, usually a shorter version of the
  /// name.
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /// @dev Returns the decimals of the token.
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    recipient;
    amount;
    require(false, 'DebtTokenTransferNotAllowed');
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    sender;
    recipient;
    amount;
    require(false, 'DebtTokenTransferFromNotAllowed');
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    owner;
    spender;
    require(false, 'DebtTokenAllowanceNotAllowed');
    return 0;
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    spender;
    amount;
    require(false, 'DebtTokenApproveNotAllowed');
    return true;
  }

  struct MintLocalVars {
    uint256 previousSupply;
    uint256 nextSupply;
    uint256 amountInRay;
    uint256 newStableRate;
    uint256 currentAverageBorrowRate;
  }

  /// @inheritdoc IDebtToken
  function getAccruedDebt() external view override returns (uint256 accruedDebt) {
    accruedDebt = _calcTotalSupply(_averageBorrowRate) - _totalSupply;
  }

  /// @inheritdoc IDebtToken
  function updateDebtTokenState() external override {
    _totalSupply = _calcTotalSupply(_averageBorrowRate);
    _lastUpdateTimestamp = block.timestamp;
  }

  /// @inheritdoc IDebtToken
  function mint(
    address account,
    uint256 amount,
    uint256 rate
  ) external override onlyCore {
    MintLocalVars memory vars;

    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(account);

    vars.previousSupply = totalSupply();
    vars.currentAverageBorrowRate = _averageBorrowRate;
    vars.nextSupply = _totalSupply = vars.previousSupply + amount;

    vars.amountInRay = amount.wadToRay();

    (, vars.newStableRate) = Calculation.calculateRateInIncreasingBalance(
      _userAverageBorrowRate[account],
      currentBalance,
      amount,
      rate
    );

    _userAverageBorrowRate[account] = vars.newStableRate;

    //solium-disable-next-line
    _lastUpdateTimestamp = _userLastUpdateTimestamp[account] = block.timestamp;

    // Calculates the updated average stable rate
    (, vars.currentAverageBorrowRate) = Calculation.calculateRateInIncreasingBalance(
      vars.currentAverageBorrowRate,
      vars.previousSupply,
      amount,
      rate
    );

    _averageBorrowRate = vars.currentAverageBorrowRate;

    _mint(account, amount + balanceIncrease);

    emit Transfer(address(0), account, amount);

    emit Mint(
      account,
      amount + balanceIncrease,
      currentBalance,
      balanceIncrease,
      vars.newStableRate,
      vars.currentAverageBorrowRate,
      vars.nextSupply
    );
  }

  /// @inheritdoc IDebtToken
  function burn(address account, uint256 amount) external override onlyCore {
    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(account);

    uint256 previousSupply = totalSupply();
    uint256 newAvgStableRate = 0;
    uint256 nextSupply = 0;
    uint256 userStableRate = _userAverageBorrowRate[account];

    // Since the total supply and each single account debt accrue separately,
    // there might be accumulation errors so that the last borrower repaying
    // mght actually try to repay more than the available debt supply.
    // In this case we simply set the total supply and the avg stable rate to 0
    if (previousSupply <= amount) {
      _averageBorrowRate = 0;
      _totalSupply = 0;
    } else {
      nextSupply = _totalSupply = previousSupply - amount;
      uint256 firstTerm = _averageBorrowRate.rayMul(previousSupply.wadToRay());
      uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

      // For the same reason described above, when the last account is repaying it might
      // happen that account rate * account balance > avg rate * total supply. In that case,
      // we simply set the avg rate to 0
      if (secondTerm >= firstTerm) {
        newAvgStableRate = _averageBorrowRate = _totalSupply = 0;
      } else {
        newAvgStableRate = _averageBorrowRate = (firstTerm - secondTerm).rayDiv(
          nextSupply.wadToRay()
        );
      }
    }

    if (amount == currentBalance) {
      _userAverageBorrowRate[account] = 0;
      _userLastUpdateTimestamp[account] = 0;
    } else {
      //solium-disable-next-line
      _userLastUpdateTimestamp[account] = block.timestamp;
    }
    //solium-disable-next-line
    _lastUpdateTimestamp = block.timestamp;

    if (balanceIncrease > amount) {
      uint256 amountToMint = balanceIncrease - amount;
      _mint(account, amountToMint);
      emit Mint(
        account,
        amountToMint,
        currentBalance,
        balanceIncrease,
        userStableRate,
        newAvgStableRate,
        nextSupply
      );
    } else {
      uint256 amountToBurn = amount - balanceIncrease;
      _burn(account, amountToBurn);
      emit Burn(
        account,
        amountToBurn,
        currentBalance,
        balanceIncrease,
        newAvgStableRate,
        nextSupply
      );
    }

    emit Transfer(account, address(0), amount);
  }

  /// @inheritdoc IDebtToken
  function getDebtTokenLastUpdateTimestamp()
    external
    view
    override
    returns (uint256 lastUpdateTimestamp)
  {
    lastUpdateTimestamp = _lastUpdateTimestamp;
  }

  /// @inheritdoc IDebtToken
  function getTotalAverageBorrowRate() external view override returns (uint256 averageBorrowRate) {
    averageBorrowRate = _averageBorrowRate;
  }

  /// @inheritdoc IDebtToken
  function getUserAverageBorrowRate(address account)
    external
    view
    override
    returns (uint256 userAverageBorrowRate)
  {
    userAverageBorrowRate = _userAverageBorrowRate[account];
  }

  /// @inheritdoc IDebtToken
  function getUserLastUpdateTimestamp(address account)
    external
    view
    override
    returns (uint256 userLastUpdateTimestamp)
  {
    userLastUpdateTimestamp = _userLastUpdateTimestamp[account];
  }

  /// @inheritdoc IDebtToken
  function getDebtTokenData()
    external
    view
    override
    returns (
      uint256 principalDebtTokenSupply,
      uint256 totalDebtTokenSupply,
      uint256 averageBorrowRate,
      uint256 debtTokenLastUpdateTimestamp
    )
  {
    principalDebtTokenSupply = _totalSupply;
    totalDebtTokenSupply = _calcTotalSupply(_averageBorrowRate);
    averageBorrowRate = _averageBorrowRate;
    debtTokenLastUpdateTimestamp = _lastUpdateTimestamp;
  }

  /// @inheritdoc IDebtToken
  function getTotalSupplyAndAverageBorrowRate()
    external
    view
    override
    returns (uint256 totalDebtTokenSupply, uint256 averageBorrowRate)
  {
    totalDebtTokenSupply = _calcTotalSupply(_averageBorrowRate);
    averageBorrowRate = _averageBorrowRate;
  }

  /// @inheritdoc IDebtToken
  function principalBalanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  /// @dev Returns the total supply
  function totalSupply() public view override returns (uint256) {
    return _calcTotalSupply(_averageBorrowRate);
  }

  /// @dev Calculates the current account debt balance
  /// @return The accumulated debt of the account
  function balanceOf(address account) public view virtual override returns (uint256) {
    uint256 accountBalance = _balances[account];
    uint256 stableRate = _userAverageBorrowRate[account];

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (accountBalance == 0) {
      return 0;
    }
    uint256 cumulatedInterest = Calculation.calculateCompoundedInterest(
      stableRate,
      _userLastUpdateTimestamp[account],
      block.timestamp
    );
    return accountBalance.rayMul(cumulatedInterest);
  }

  /// @dev Calculates the increase in balance since the last account interaction
  /// @param account The address of the account for which the interest is being accumulated
  /// @return The principal principal balance, the new principal balance and the balance increase
  function _calculateBalanceIncrease(address account)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 previousprincipalBalance = _balances[account];

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (previousprincipalBalance == 0) {
      return (0, 0, 0);
    }

    // Calculation of the accrued interest since the last accumulation
    uint256 balanceIncrease = balanceOf(account) - previousprincipalBalance;

    return (previousprincipalBalance, previousprincipalBalance + balanceIncrease, balanceIncrease);
  }

  /// @dev Calculates the total supply
  /// @param avgRate The average rate at which the total supply increases
  /// @return The debt balance of the account since the last burn/mint action
  function _calcTotalSupply(uint256 avgRate) internal view virtual returns (uint256) {
    uint256 principalSupply = _totalSupply;

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (principalSupply == 0) {
      return 0;
    }

    uint256 cumulatedInterest = Calculation.calculateCompoundedInterest(
      avgRate,
      _lastUpdateTimestamp,
      block.timestamp
    );

    return principalSupply.rayMul(cumulatedInterest);
  }

  /**
   * @dev Mints stable debt tokens to an account
   * @param account The account receiving the debt tokens
   * @param amount The amount being minted
   **/
  function _mint(address account, uint256 amount) internal {
    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance + amount;
  }

  /**
   * @dev Burns stable debt tokens of an account
   * @param account The account getting his debt burned
   * @param amount The amount being burned
   **/
  function _burn(address account, uint256 amount) internal {
    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance - amount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interfaces/IPoolToken.sol';
import '../../core/interfaces/ICore.sol';
import '../../core/libraries/Math.sol';
import '../../managers/interfaces/IIncentiveManager.sol';

pragma solidity 0.8.4;

/// @title PoolToken
/// @notice Pool token represents the state of user who deposited.
contract PoolToken is IPoolToken, ERC20 {
  using Math for uint256;
  ICore internal _core;
  address internal _underlyingAsset;
  address internal _protocolTreasury;
  IProtocolAddressProvider internal _protocolAddressProvider;

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    _core = ICore(msg.sender);

    _protocolAddressProvider = IProtocolAddressProvider(_core.getProtocolAddressProvider());
    _underlyingAsset = ICore(msg.sender).getAssetAdded();

    _protocolTreasury = _protocolAddressProvider.getProtocolTreasury();
  }

  modifier onlyCore() {
    require(msg.sender == address(_core), 'Only Core');
    _;
  }

  /// @notice Returns implicit balance multipied by pool interst index
  /// @param account user account
  /// @return balance the balance of the user
  function balanceOf(address account)
    public
    view
    override(IERC20, ERC20)
    returns (uint256 balance)
  {
    balance = super.balanceOf(account).rayMul(_core.getPoolInterestIndex(_underlyingAsset));
  }

  /// @notice calculates the total supply of the specific pool token
  /// since the balance of every single user increases over time, the total supply
  /// does that too.
  /// @return totalSupply_ the current total supply
  function totalSupply() public view override(IERC20, ERC20) returns (uint256 totalSupply_) {
    totalSupply_ = super.totalSupply().rayMul(_core.getPoolInterestIndex(_underlyingAsset));
  }

  /// @inheritdoc IPoolToken
  function implicitBalanceOf(address account)
    external
    view
    override
    returns (uint256 implicitBalance)
  {
    implicitBalance = super.balanceOf(account);
  }

  /// @inheritdoc IPoolToken
  function implicitTotalSupply() external view override returns (uint256 implicitTotalSupply_) {
    implicitTotalSupply_ = super.totalSupply();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (_protocolAddressProvider.getIncentiveManager() != address(0)) {
      IIncentiveManager(_protocolAddressProvider.getIncentiveManager()).beforeTokenTransfer(
        address(this),
        from,
        to
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title Math library
/// @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
library Math {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /// @return One ray, 1e27
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /// @return One wad, 1e18

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  ///@return Half ray, 1e27/2
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /// @return Half ray, 1e18/2
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /// @dev Multiplies two wad, rounding half up to the nearest wad
  /// @param a Wad
  /// @param b Wad
  /// @return The result of a*b, in wad
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /// @dev Divides two wad, rounding half up to the nearest wad
  /// @param a Wad
  /// @param b Wad
  /// @return The result of a/b, in wad
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /// @dev Multiplies two ray, rounding half up to the nearest ray
  /// @param a Ray
  /// @param b Ray
  /// @return The result of a*b, in ray
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /// @dev Divides two ray, rounding half up to the nearest ray
  /// @param a Ray
  /// @param b Ray
  /// @return The result of a/b, in ray
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /// @dev Casts ray down to wad
  /// @param a Ray
  /// @return a casted to wad, rounded half up to the nearest wad
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /// @dev Converts wad up to ray
  /// @param a Wad
  /// @return a converted in ray
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.4;

import './Math.sol';

library Calculation {
  using Math for uint256;

  uint256 internal constant SECONDSPERYEAR = 365 days;

  function calculateLinearInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    uint256 timeDelta = currentTimestamp - uint256(lastUpdateTimestamp);

    return ((rate * timeDelta) / SECONDSPERYEAR) + Math.ray();
  }

  /// @dev Function to calculate the interest using a compounded interest rate formula
  /// To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
  ///  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
  ///
  /// The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
  /// The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
  ///
  /// @param rate The interest rate, in ray
  /// @param lastUpdateTimestamp The timestamp of the last update of the interest
  /// @return The interest rate compounded during the timeDelta, in ray
  function calculateCompoundedInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - lastUpdateTimestamp;

    if (exp == 0) {
      return Math.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    // loss of precision is endurable
    // slither-disable-next-line divide-before-multiply
    uint256 ratePerSecond = rate / SECONDSPERYEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
    uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

    return Math.ray() + (ratePerSecond * exp) + secondTerm + thirdTerm;
  }

  function calculateRateInIncreasingBalance(
    uint256 averageRate,
    uint256 totalBalance,
    uint256 amountIn,
    uint256 rate
  ) internal pure returns (uint256, uint256) {
    uint256 weightedAverageRate = totalBalance.wadToRay().rayMul(averageRate);
    uint256 weightedAmountRate = amountIn.wadToRay().rayMul(rate);

    uint256 newTotalBalance = totalBalance + amountIn;
    uint256 newAverageRate = (weightedAverageRate + weightedAmountRate).rayDiv(
      newTotalBalance.wadToRay()
    );

    return (newTotalBalance, newAverageRate);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './IProtocolAddressProvider.sol';

interface IProtocolTreasury {
  event UpdateStabilityFee(uint256 base, uint256 baseFee, uint256 maxFee);

  /// @notice Returns the address of the ProtocolAddressProvider contract.
  /// @return protocolAddressProvider The address of the ProtocolAddressProvider contract
  function getProtocolAddressProvider()
    external
    view
    returns (IProtocolAddressProvider protocolAddressProvider);

  /// @notice Calculate the stability fee base on input parameters.
  /// @param totalDebtTokenSupply The total amount of debt token supply
  /// @param poolRemainingLiquidity The pool remaining liquidity before the action
  /// @param poolRemainingLiquidityAfterAction The pool remaining liquidity after the action
  /// @return stabilityFee The amount of stability fee
  function calculateStabilityFeeRate(
    uint256 totalDebtTokenSupply,
    uint256 poolRemainingLiquidity,
    uint256 poolRemainingLiquidityAfterAction
  ) external view returns (uint256 stabilityFee);


  /// @notice Update parameters that determine the stability fee.
  /// @param base The utilization rate above which the stability fee is charged.
  /// @param baseFee The amount of fee at base.
  /// @param maxFee The amount of fee at 100% utilization.
  function setStabilityFee(
    uint256 base,
    uint256 baseFee,
    uint256 maxFee
  ) external;

  /// @notice Return parameters that determine the stability fee.
  /// @return base The utilization rate above which the stability fee is charged.
  /// @return baseFee The amount of fee at base.
  /// @return maxFee The amount of fee at 100% utilization.
  function getStabilityFee()
    external
    view
    returns (
      uint256 base,
      uint256 baseFee,
      uint256 maxFee
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}