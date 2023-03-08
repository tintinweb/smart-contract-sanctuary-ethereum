// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string underlyingAssetName;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(
    address reserve,
    address rateStrategyAddress
  ) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(
    address asset
  ) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(
    address user
  ) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

interface ILendingPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
   **/
  event BorrowingEnabledOnReserve(address indexed asset, bool stableRateEnabled);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when stable rate borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when an aToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   **/
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Initializes a reserve
   * @param aTokenImpl  The address of the aToken contract implementation
   * @param stableDebtTokenImpl The address of the stable debt token contract
   * @param variableDebtTokenImpl The address of the variable debt token contract
   * @param underlyingAssetDecimals The decimals of the reserve underlying asset
   * @param interestRateStrategyAddress The address of the interest rate strategy contract for this reserve
   **/
  function initReserve(
    address aTokenImpl,
    address stableDebtTokenImpl,
    address variableDebtTokenImpl,
    uint8 underlyingAssetDecimals,
    address interestRateStrategyAddress
  ) external;

  function batchInitReserve(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

  /**
   * @dev Updates the aToken implementation for the reserve
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateAToken(address asset, address implementation) external;

  /**
   * @dev Updates the stable debt token implementation for the reserve
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateStableDebtToken(address asset, address implementation) external;

  /**
   * @dev Updates the variable debt token implementation for the asset
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateVariableDebtToken(address asset, address implementation) external;

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
   **/
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external;

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external;

  /**
   * @dev Configures the reserve collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always above 100%. A value of 105%
   * means the liquidator will receive a 5% bonus
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @dev Enable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableReserveStableRate(address asset) external;

  /**
   * @dev Disable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableReserveStableRate(address asset) external;

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external;

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external;

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
   *  but allows repayments, liquidations, rate rebalances and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external;

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external;

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external;

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @dev pauses or unpauses all the actions of the protocol, including aToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external;
}

interface IAaveOracle {
  event WethSet(address indexed weth);
  event AssetSourceUpdated(address indexed asset, address indexed source);
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /// @notice Returns the WETH address (reference asset of the oracle)
  function WETH() external returns (address);

  /// @notice External function called by the Aave governance to set or replace sources of assets
  /// @param assets The addresses of the assets
  /// @param sources The address of the source of each asset
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /// @notice Sets the fallbackOracle
  /// - Callable only by the Aave governance
  /// @param fallbackOracle The address of the fallbackOracle
  function setFallbackOracle(address fallbackOracle) external;

  /// @notice Gets an asset price by address
  /// @param asset The asset address
  function getAssetPrice(address asset) external view returns (uint256);

  /// @notice Gets a list of prices from a list of assets addresses
  /// @param assets The list of assets addresses
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /// @notice Gets the address of the source for an asset address
  /// @param asset The address of the asset
  /// @return address The address of the source
  function getSourceOfAsset(address asset) external view returns (address);

  /// @notice Gets the address of the fallback oracle
  /// @return address The addres of the fallback oracle
  function getFallbackOracle() external view returns (address);
}

struct TokenData {
  string symbol;
  address tokenAddress;
}

// TODO: incomplete interface
interface IAaveProtocolDataProvider {
  function getReserveConfigurationData(
    address asset
  )
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  function getUserReserveData(
    address asset,
    address user
  )
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );
}

interface ILendingRateOracle {
  /**
    @dev returns the market borrow rate in ray
    **/
  function getMarketBorrowRate(address asset) external view returns (uint256);

  /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
  function setMarketBorrowRate(address asset, uint256 rate) external;
}

interface IDefaultInterestRateStrategy {
  function EXCESS_UTILIZATION_RATE() external view returns (uint256);

  function OPTIMAL_UTILIZATION_RATE() external view returns (uint256);

  function addressesProvider() external view returns (address);

  function baseVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  ) external view returns (uint256, uint256, uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function stableRateSlope1() external view returns (uint256);

  function stableRateSlope2() external view returns (uint256);

  function variableRateSlope1() external view returns (uint256);

  function variableRateSlope2() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Ethereum {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

  ILendingPool internal constant POOL = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0x8A32f49FFbA88aba6EFF96F45D8BD1D4b3f35c7D);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

  address internal constant POOL_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant EMERGENCY_ADMIN = 0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  address internal constant COLLECTOR_CONTROLLER = 0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

  address internal constant EMISSION_MANAGER = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x52D306e36E3B6B02c153d0266ff0f85d18BCD413;

  address internal constant WETH_GATEWAY = 0xEFFC18fC3b7eb8E676dac549E0c693ad50D1Ce31;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x80Aca0C645fEdABaa20fd2Bf0Daf57885A309FE6;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x135896DE8421be2ec868E0b811006171D9df802A;

  address internal constant MIGRATION_HELPER = 0xB748952c7BC638F31775245964707Bcc5DDFabFC;

  address internal constant WALLET_BALANCE_PROVIDER = 0x8E8dAd5409E0263a51C0aB5055dA66Be28cFF922;

  address internal constant UI_POOL_DATA_PROVIDER = 0x00e50FAB64eBB37b87df06Aa46b8B35d5f1A4e1A;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xD01ab9a6577E1D84F142e44D49380e23A340387d;
}

library AaveV2EthereumAssets {
  address internal constant USDT_UNDERLYING = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  address internal constant USDT_A_TOKEN = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

  address internal constant USDT_V_TOKEN = 0x531842cEbbdD378f8ee36D171d6cC9C4fcf475Ec;

  address internal constant USDT_S_TOKEN = 0xe91D55AB2240594855aBd11b3faAE801Fd4c4687;

  address internal constant USDT_ORACLE = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x515E87cb3fec986050F202a2bbfa362A2188bc3F;

  address internal constant WBTC_UNDERLYING = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

  address internal constant WBTC_A_TOKEN = 0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656;

  address internal constant WBTC_V_TOKEN = 0x9c39809Dec7F95F5e0713634a4D0701329B3b4d2;

  address internal constant WBTC_S_TOKEN = 0x51B039b9AFE64B78758f8Ef091211b5387eA717c;

  address internal constant WBTC_ORACLE = 0xdeb288F737066589598e9214E782fa5A8eD689e8;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0xf41E8F817e6C399d1AdE102059c454093b24f35B;

  address internal constant WETH_UNDERLYING = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant WETH_A_TOKEN = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;

  address internal constant WETH_V_TOKEN = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;

  address internal constant WETH_S_TOKEN = 0x4e977830ba4bd783C0BB7F15d3e243f73FF57121;

  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x853844459106feefd8C7C4cC34066bFBC0531722;

  address internal constant YFI_UNDERLYING = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

  address internal constant YFI_A_TOKEN = 0x5165d24277cD063F5ac44Efd447B27025e888f37;

  address internal constant YFI_V_TOKEN = 0x7EbD09022Be45AD993BAA1CEc61166Fcc8644d97;

  address internal constant YFI_S_TOKEN = 0xca823F78C2Dd38993284bb42Ba9b14152082F7BD;

  address internal constant YFI_ORACLE = 0x7c5d4F8345e66f68099581Db340cd65B078C41f4;

  address internal constant YFI_INTEREST_RATE_STRATEGY = 0xfd71623D7F41360aefE200de4f17E20A29e1d58C;

  address internal constant ZRX_UNDERLYING = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

  address internal constant ZRX_A_TOKEN = 0xDf7FF54aAcAcbFf42dfe29DD6144A69b629f8C9e;

  address internal constant ZRX_V_TOKEN = 0x85791D117A392097590bDeD3bD5abB8d5A20491A;

  address internal constant ZRX_S_TOKEN = 0x071B4323a24E73A5afeEbe34118Cd21B8FAAF7C3;

  address internal constant ZRX_ORACLE = 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962;

  address internal constant ZRX_INTEREST_RATE_STRATEGY = 0x1a4babC0e20d892167792AC79618273711afD3e7;

  address internal constant UNI_UNDERLYING = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

  address internal constant UNI_A_TOKEN = 0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1;

  address internal constant UNI_V_TOKEN = 0x5BdB050A92CADcCfCDcCCBFC17204a1C9cC0Ab73;

  address internal constant UNI_S_TOKEN = 0xD939F7430dC8D5a427f156dE1012A56C18AcB6Aa;

  address internal constant UNI_ORACLE = 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e;

  address internal constant UNI_INTEREST_RATE_STRATEGY = 0x24ABFac8dd8f270D752837fDFe3B3C735361f4eE;

  address internal constant AAVE_UNDERLYING = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

  address internal constant AAVE_A_TOKEN = 0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;

  address internal constant AAVE_V_TOKEN = 0xF7DBA49d571745D9d7fcb56225B05BEA803EBf3C;

  address internal constant AAVE_S_TOKEN = 0x079D6a3E844BcECf5720478A718Edb6575362C5f;

  address internal constant AAVE_ORACLE = 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0xd4cA26F2496195C4F886D464D8578368236bB747;

  address internal constant BAT_UNDERLYING = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;

  address internal constant BAT_A_TOKEN = 0x05Ec93c0365baAeAbF7AefFb0972ea7ECdD39CF1;

  address internal constant BAT_V_TOKEN = 0xfc218A6Dfe6901CB34B1a5281FC6f1b8e7E56877;

  address internal constant BAT_S_TOKEN = 0x277f8676FAcf4dAA5a6EA38ba511B7F65AA02f9F;

  address internal constant BAT_ORACLE = 0x0d16d4528239e9ee52fa531af613AcdB23D88c94;

  address internal constant BAT_INTEREST_RATE_STRATEGY = 0xBdfC85b140edF1FeaFd6eD664027AA4C23b4A29F;

  address internal constant BUSD_UNDERLYING = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

  address internal constant BUSD_A_TOKEN = 0xA361718326c15715591c299427c62086F69923D9;

  address internal constant BUSD_V_TOKEN = 0xbA429f7011c9fa04cDd46a2Da24dc0FF0aC6099c;

  address internal constant BUSD_S_TOKEN = 0x4A7A63909A72D268b1D8a93a9395d098688e0e5C;

  address internal constant BUSD_ORACLE = 0x614715d2Af89E6EC99A233818275142cE88d1Cfd;

  address internal constant BUSD_INTEREST_RATE_STRATEGY =
    0x26D40544447F68a3De69005822195549934624B9;

  address internal constant DAI_UNDERLYING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address internal constant DAI_A_TOKEN = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

  address internal constant DAI_V_TOKEN = 0x6C3c78838c761c6Ac7bE9F59fe808ea2A6E4379d;

  address internal constant DAI_S_TOKEN = 0x778A13D3eeb110A4f7bb6529F99c000119a08E92;

  address internal constant DAI_ORACLE = 0x773616E4d11A78F511299002da57A0a94577F1f4;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xfffE32106A68aA3eD39CcCE673B646423EEaB62a;

  address internal constant ENJ_UNDERLYING = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;

  address internal constant ENJ_A_TOKEN = 0xaC6Df26a590F08dcC95D5a4705ae8abbc88509Ef;

  address internal constant ENJ_V_TOKEN = 0x38995F292a6E31b78203254fE1cdd5Ca1010A446;

  address internal constant ENJ_S_TOKEN = 0x943DcCA156b5312Aa24c1a08769D67FEce4ac14C;

  address internal constant ENJ_ORACLE = 0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B;

  address internal constant ENJ_INTEREST_RATE_STRATEGY = 0x4a4fb6B26e7F516594b7242240039EA8FAAc897a;

  address internal constant KNC_UNDERLYING = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;

  address internal constant KNC_A_TOKEN = 0x39C6b3e42d6A679d7D776778Fe880BC9487C2EDA;

  address internal constant KNC_V_TOKEN = 0x6B05D1c608015Ccb8e205A690cB86773A96F39f1;

  address internal constant KNC_S_TOKEN = 0x9915dfb872778B2890a117DA1F35F335eb06B54f;

  address internal constant KNC_ORACLE = 0x656c0544eF4C98A6a98491833A89204Abb045d6b;

  address internal constant KNC_INTEREST_RATE_STRATEGY = 0xFDBDa42D2aC1bfbbc10555eb255De8387b8977C4;

  address internal constant LINK_UNDERLYING = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  address internal constant LINK_A_TOKEN = 0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0;

  address internal constant LINK_V_TOKEN = 0x0b8f12b1788BFdE65Aa1ca52E3e9F3Ba401be16D;

  address internal constant LINK_S_TOKEN = 0xFB4AEc4Cc858F2539EBd3D37f2a43eAe5b15b98a;

  address internal constant LINK_ORACLE = 0xDC530D9457755926550b59e8ECcdaE7624181557;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0xED6547b83276B076B771B88FcCbD68BDeDb3927f;

  address internal constant MANA_UNDERLYING = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;

  address internal constant MANA_A_TOKEN = 0xa685a61171bb30d4072B338c80Cb7b2c865c873E;

  address internal constant MANA_V_TOKEN = 0x0A68976301e46Ca6Ce7410DB28883E309EA0D352;

  address internal constant MANA_S_TOKEN = 0xD86C74eA2224f4B8591560652b50035E4e5c0a3b;

  address internal constant MANA_ORACLE = 0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9;

  address internal constant MANA_INTEREST_RATE_STRATEGY =
    0x004fC239848D8A8d3304729b78ba81d73d83C99F;

  address internal constant MKR_UNDERLYING = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

  address internal constant MKR_A_TOKEN = 0xc713e5E149D5D0715DcD1c156a020976e7E56B88;

  address internal constant MKR_V_TOKEN = 0xba728eAd5e496BE00DCF66F650b6d7758eCB50f8;

  address internal constant MKR_S_TOKEN = 0xC01C8E4b12a89456a9fD4e4e75B72546Bf53f0B5;

  address internal constant MKR_ORACLE = 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2;

  address internal constant MKR_INTEREST_RATE_STRATEGY = 0xE3a3DE71B827cB73663A24cDB6243bA7F986cC3b;

  address internal constant REN_UNDERLYING = 0x408e41876cCCDC0F92210600ef50372656052a38;

  address internal constant REN_A_TOKEN = 0xCC12AbE4ff81c9378D670De1b57F8e0Dd228D77a;

  address internal constant REN_V_TOKEN = 0xcd9D82d33bd737De215cDac57FE2F7f04DF77FE0;

  address internal constant REN_S_TOKEN = 0x3356Ec1eFA75d9D150Da1EC7d944D9EDf73703B7;

  address internal constant REN_ORACLE = 0x3147D7203354Dc06D9fd350c7a2437bcA92387a4;

  address internal constant REN_INTEREST_RATE_STRATEGY = 0x9B1e3C7483F0f21abFEaE3AeBC9b47b5f23f5bB0;

  address internal constant SNX_UNDERLYING = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

  address internal constant SNX_A_TOKEN = 0x35f6B052C598d933D69A4EEC4D04c73A191fE6c2;

  address internal constant SNX_V_TOKEN = 0x267EB8Cf715455517F9BD5834AeAE3CeA1EBdbD8;

  address internal constant SNX_S_TOKEN = 0x8575c8ae70bDB71606A53AeA1c6789cB0fBF3166;

  address internal constant SNX_ORACLE = 0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c;

  address internal constant SNX_INTEREST_RATE_STRATEGY = 0xCc92073dDe8aE03bAA1812AC5cF22e69b5E76914;

  address internal constant sUSD_UNDERLYING = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

  address internal constant sUSD_A_TOKEN = 0x6C5024Cd4F8A59110119C56f8933403A539555EB;

  address internal constant sUSD_V_TOKEN = 0xdC6a3Ab17299D9C2A412B0e0a4C1f55446AE0817;

  address internal constant sUSD_S_TOKEN = 0x30B0f7324feDF89d8eff397275F8983397eFe4af;

  address internal constant sUSD_ORACLE = 0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757;

  address internal constant sUSD_INTEREST_RATE_STRATEGY =
    0x3082D0a473385Ed2cbd1f16087ab8b7BF79f0355;

  address internal constant TUSD_UNDERLYING = 0x0000000000085d4780B73119b644AE5ecd22b376;

  address internal constant TUSD_A_TOKEN = 0x101cc05f4A51C0319f570d5E146a8C625198e636;

  address internal constant TUSD_V_TOKEN = 0x01C0eb1f8c6F1C1bF74ae028697ce7AA2a8b0E92;

  address internal constant TUSD_S_TOKEN = 0x7f38d60D94652072b2C44a18c0e14A481EC3C0dd;

  address internal constant TUSD_ORACLE = 0x3886BA987236181D98F2401c507Fb8BeA7871dF2;

  address internal constant TUSD_INTEREST_RATE_STRATEGY =
    0x0DdEC679166C367ae45036c8b2c169C5FB2dceE1;

  address internal constant USDC_UNDERLYING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address internal constant USDC_A_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

  address internal constant USDC_V_TOKEN = 0x619beb58998eD2278e08620f97007e1116D5D25b;

  address internal constant USDC_S_TOKEN = 0xE4922afAB0BbaDd8ab2a88E0C79d884Ad337fcA6;

  address internal constant USDC_ORACLE = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27;

  address internal constant CRV_UNDERLYING = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  address internal constant CRV_A_TOKEN = 0x8dAE6Cb04688C62d939ed9B68d32Bc62e49970b1;

  address internal constant CRV_V_TOKEN = 0x00ad8eBF64F141f1C81e9f8f792d3d1631c6c684;

  address internal constant CRV_S_TOKEN = 0x9288059a74f589C919c7Cf1Db433251CdFEB874B;

  address internal constant CRV_ORACLE = 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0xE3a3DE71B827cB73663A24cDB6243bA7F986cC3b;

  address internal constant GUSD_UNDERLYING = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;

  address internal constant GUSD_A_TOKEN = 0xD37EE7e4f452C6638c96536e68090De8cBcdb583;

  address internal constant GUSD_V_TOKEN = 0x279AF5b99540c1A3A7E3CDd326e19659401eF99e;

  address internal constant GUSD_S_TOKEN = 0xf8aC64ec6Ff8E0028b37EB89772d21865321bCe0;

  address internal constant GUSD_ORACLE = 0xEc6f4Cd64d28Ef32507e2dc399948aAe9Bbedd7e;

  address internal constant GUSD_INTEREST_RATE_STRATEGY =
    0x2893405d64a7Bc8Db02Fa617351a5399d59eCf8D;

  address internal constant BAL_UNDERLYING = 0xba100000625a3754423978a60c9317c58a424e3D;

  address internal constant BAL_A_TOKEN = 0x272F97b7a56a387aE942350bBC7Df5700f8a4576;

  address internal constant BAL_V_TOKEN = 0x13210D4Fe0d5402bd7Ecbc4B5bC5cFcA3b71adB0;

  address internal constant BAL_S_TOKEN = 0xe569d31590307d05DA3812964F1eDd551D665a0b;

  address internal constant BAL_ORACLE = 0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b;

  address internal constant BAL_INTEREST_RATE_STRATEGY = 0xfC0Eace19AA7498e0f36eF1607D282a8d6debbDd;

  address internal constant xSUSHI_UNDERLYING = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

  address internal constant xSUSHI_A_TOKEN = 0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a;

  address internal constant xSUSHI_V_TOKEN = 0xfAFEDF95E21184E3d880bd56D4806c4b8d31c69A;

  address internal constant xSUSHI_S_TOKEN = 0x73Bfb81D7dbA75C904f430eA8BAe82DB0D41187B;

  address internal constant xSUSHI_ORACLE = 0x9b26214bEC078E68a394AaEbfbffF406Ce14893F;

  address internal constant xSUSHI_INTEREST_RATE_STRATEGY =
    0xb49034Ada4BE5c6Bb3823A623C6250267110b06b;

  address internal constant renFIL_UNDERLYING = 0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5;

  address internal constant renFIL_A_TOKEN = 0x514cd6756CCBe28772d4Cb81bC3156BA9d1744aa;

  address internal constant renFIL_V_TOKEN = 0x348e2eBD5E962854871874E444F4122399c02755;

  address internal constant renFIL_S_TOKEN = 0xcAad05C49E14075077915cB5C820EB3245aFb950;

  address internal constant renFIL_ORACLE = 0x0606Be69451B1C9861Ac6b3626b99093b713E801;

  address internal constant renFIL_INTEREST_RATE_STRATEGY =
    0x311C866D55456e465e314A3E9830276B438A73f0;

  address internal constant RAI_UNDERLYING = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

  address internal constant RAI_A_TOKEN = 0xc9BC48c72154ef3e5425641a3c747242112a46AF;

  address internal constant RAI_V_TOKEN = 0xB5385132EE8321977FfF44b60cDE9fE9AB0B4e6b;

  address internal constant RAI_S_TOKEN = 0x9C72B8476C33AE214ee3e8C20F0bc28496a62032;

  address internal constant RAI_ORACLE = 0x4ad7B025127e89263242aB68F0f9c4E5C033B489;

  address internal constant RAI_INTEREST_RATE_STRATEGY = 0xA7d4df837926cD55036175AfeF38395d56A64c22;

  address internal constant AMPL_UNDERLYING = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;

  address internal constant AMPL_A_TOKEN = 0x1E6bb68Acec8fefBD87D192bE09bb274170a0548;

  address internal constant AMPL_V_TOKEN = 0xf013D90E4e4E3Baf420dFea60735e75dbd42f1e1;

  address internal constant AMPL_S_TOKEN = 0x18152C9f77DAdc737006e9430dB913159645fa87;

  address internal constant AMPL_ORACLE = 0x492575FDD11a0fCf2C6C719867890a7648d526eB;

  address internal constant AMPL_INTEREST_RATE_STRATEGY =
    0x84d1FaD9559b8AC1Fda17d073B8542c8Fb6986dd;

  address internal constant USDP_UNDERLYING = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;

  address internal constant USDP_A_TOKEN = 0x2e8F4bdbE3d47d7d7DE490437AeA9915D930F1A3;

  address internal constant USDP_V_TOKEN = 0xFDb93B3b10936cf81FA59A02A7523B6e2149b2B7;

  address internal constant USDP_S_TOKEN = 0x2387119bc85A74e0BBcbe190d80676CB16F10D4F;

  address internal constant USDP_ORACLE = 0x3a08ebBaB125224b7b6474384Ee39fBb247D2200;

  address internal constant USDP_INTEREST_RATE_STRATEGY =
    0x404d396fc42e20d14585A1a10Cd64BDdC6C6574A;

  address internal constant DPI_UNDERLYING = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

  address internal constant DPI_A_TOKEN = 0x6F634c6135D2EBD550000ac92F494F9CB8183dAe;

  address internal constant DPI_V_TOKEN = 0x4dDff5885a67E4EffeC55875a3977D7E60F82ae0;

  address internal constant DPI_S_TOKEN = 0xa3953F07f389d719F99FC378ebDb9276177d8A6e;

  address internal constant DPI_ORACLE = 0x029849bbc0b1d93b85a8b6190e979fd38F5760E2;

  address internal constant DPI_INTEREST_RATE_STRATEGY = 0x9440aEc0795D7485e58bCF26622c2f4A681A9671;

  address internal constant FRAX_UNDERLYING = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

  address internal constant FRAX_A_TOKEN = 0xd4937682df3C8aEF4FE912A96A74121C0829E664;

  address internal constant FRAX_V_TOKEN = 0xfE8F19B17fFeF0fDbfe2671F248903055AFAA8Ca;

  address internal constant FRAX_S_TOKEN = 0x3916e3B6c84b161df1b2733dFfc9569a1dA710c2;

  address internal constant FRAX_ORACLE = 0x14d04Fff8D21bd62987a5cE9ce543d2F1edF5D3E;

  address internal constant FRAX_INTEREST_RATE_STRATEGY =
    0xb0a73aC3B10980A598685d4631c83f5348F5D32c;

  address internal constant FEI_UNDERLYING = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

  address internal constant FEI_A_TOKEN = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

  address internal constant FEI_V_TOKEN = 0xC2e10006AccAb7B45D9184FcF5b7EC7763f5BaAe;

  address internal constant FEI_S_TOKEN = 0xd89cF9E8A858F8B4b31Faf793505e112d6c17449;

  address internal constant FEI_ORACLE = 0x7F0D2c2838c6AC24443d13e23d99490017bDe370;

  address internal constant FEI_INTEREST_RATE_STRATEGY = 0xF0bA2a8c12A2354c075b363765EAe825619bd490;

  address internal constant stETH_UNDERLYING = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

  address internal constant stETH_A_TOKEN = 0x1982b2F5814301d4e9a8b0201555376e62F82428;

  address internal constant stETH_V_TOKEN = 0xA9DEAc9f00Dc4310c35603FCD9D34d1A750f81Db;

  address internal constant stETH_S_TOKEN = 0x66457616Dd8489dF5D0AFD8678F4A260088aAF55;

  address internal constant stETH_ORACLE = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

  address internal constant stETH_INTEREST_RATE_STRATEGY =
    0xff04ed5f7a6C3a0F1e5Ea20617F8C6f513D5A77c;

  address internal constant ENS_UNDERLYING = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;

  address internal constant ENS_A_TOKEN = 0x9a14e23A58edf4EFDcB360f68cd1b95ce2081a2F;

  address internal constant ENS_V_TOKEN = 0x176808047cc9b7A2C9AE202c593ED42dDD7C0D13;

  address internal constant ENS_S_TOKEN = 0x34441FFD1948E49dC7a607882D0c38Efd0083815;

  address internal constant ENS_ORACLE = 0xd4641b75015E6536E8102D98479568D05D7123Db;

  address internal constant ENS_INTEREST_RATE_STRATEGY = 0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

  address internal constant UST_UNDERLYING = 0xa693B19d2931d498c5B318dF961919BB4aee87a5;

  address internal constant UST_A_TOKEN = 0xc2e2152647F4C26028482Efaf64b2Aa28779EFC4;

  address internal constant UST_V_TOKEN = 0xaf32001cf2E66C4C3af4205F6EA77112AA4160FE;

  address internal constant UST_S_TOKEN = 0x7FDbfB0412700D94403c42cA3CAEeeA183F07B26;

  address internal constant UST_ORACLE = 0xa20623070413d42a5C01Db2c8111640DD7A5A03a;

  address internal constant UST_INTEREST_RATE_STRATEGY = 0x0dEDCaE8Eb22A2EFB597aBde1834173C47Cff186;

  address internal constant CVX_UNDERLYING = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

  address internal constant CVX_A_TOKEN = 0x952749E07d7157bb9644A894dFAF3Bad5eF6D918;

  address internal constant CVX_V_TOKEN = 0x4Ae5E4409C6Dbc84A00f9f89e4ba096603fb7d50;

  address internal constant CVX_S_TOKEN = 0xB01Eb1cE1Da06179136D561766fc2d609C5F55Eb;

  address internal constant CVX_ORACLE = 0xC9CbF687f43176B302F03f5e58470b77D07c61c6;

  address internal constant CVX_INTEREST_RATE_STRATEGY = 0x1dA981865AE7a0C838eFBF4C7DFecb5c7268E73A;

  address internal constant ONE_INCH_UNDERLYING = 0x111111111117dC0aa78b770fA6A738034120C302;

  address internal constant ONE_INCH_A_TOKEN = 0xB29130CBcC3F791f077eAdE0266168E808E5151e;

  address internal constant ONE_INCH_V_TOKEN = 0xD7896C1B9b4455aFf31473908eB15796ad2295DA;

  address internal constant ONE_INCH_S_TOKEN = 0x1278d6ED804d59d2d18a5Aa5638DfD591A79aF0a;

  address internal constant ONE_INCH_ORACLE = 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8;

  address internal constant ONE_INCH_INTEREST_RATE_STRATEGY =
    0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

  address internal constant LUSD_UNDERLYING = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

  address internal constant LUSD_A_TOKEN = 0xce1871f791548600cb59efbefFC9c38719142079;

  address internal constant LUSD_V_TOKEN = 0x411066489AB40442d6Fc215aD7c64224120D33F2;

  address internal constant LUSD_S_TOKEN = 0x39f010127274b2dBdB770B45e1de54d974974526;

  address internal constant LUSD_ORACLE = 0x60c0b047133f696334a2b7f68af0b49d2F3D4F72;

  address internal constant LUSD_INTEREST_RATE_STRATEGY =
    0x545Ae1908B6F12e91E03B1DEC4F2e06D0570fE1b;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Ethereum, AaveV2EthereumAssets} from "aave-address-book/AaveV2Ethereum.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Ethereum v2liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x56aaf192f5cad8277b0e7c82abad030c62bb8fcfe4f2640ce5b896ab04397c20
 */
contract ProposalPayload {
    address public constant INTEREST_RATE_STRATEGY = 0xA4C2C730A4c01c64d54ce0165c27120989A3C743;

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2EthereumAssets.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY
        );
    }
}