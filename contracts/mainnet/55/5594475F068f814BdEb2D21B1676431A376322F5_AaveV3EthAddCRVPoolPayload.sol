// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an address as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPriceOracleGetter} from './IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IAaveOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IReserveInterestRateStrategy} from './IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IDefaultInterestRateStrategy
 * @author Aave
 * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
 */
interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
  /**
   * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
   * @return The optimal usage ratio, expressed in ray.
   */
  function OPTIMAL_USAGE_RATIO() external view returns (uint256);

  /**
   * @notice Returns the optimal stable to total debt ratio of the reserve.
   * @return The optimal stable to total debt ratio, expressed in ray.
   */
  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @notice Returns the excess usage ratio above the optimal.
   * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
   * @return The max excess usage ratio, expressed in ray.
   */
  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

  /**
   * @notice Returns the excess stable debt ratio above the optimal.
   * @dev It's always equal to 1-optimal stable to total debt ratio (added as constant for gas optimizations)
   * @return The max excess stable to total debt ratio, expressed in ray.
   */
  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @notice Returns the address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the variable rate slope below optimal usage ratio
   * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The variable rate slope, expressed in ray
   */
  function getVariableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the variable rate slope above optimal usage ratio
   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The variable rate slope, expressed in ray
   */
  function getVariableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope below optimal usage ratio
   * @dev It's the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The stable rate slope, expressed in ray
   */
  function getStableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope above optimal usage ratio
   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The stable rate slope, expressed in ray
   */
  function getStableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate excess offset
   * @dev It's an additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
   * @return The stable rate excess offset, expressed in ray
   */
  function getStableRateExcessOffset() external view returns (uint256);

  /**
   * @notice Returns the base stable borrow rate
   * @return The base stable borrow rate, expressed in ray
   */
  function getBaseStableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the base variable borrow rate
   * @return The base variable borrow rate, expressed in ray
   */
  function getBaseVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the maximum variable borrow rate
   * @return The maximum variable borrow rate, expressed in ray
   */
  function getMaxVariableBorrowRate() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   */
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   */
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   */
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   */
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   */
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   */
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   */
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   */
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   */
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
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
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   */
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   */
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @notice Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   * @return The backed amount
   */
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external returns (uint256);

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   */
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   */
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   */
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
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   */
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   */
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   */
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   */
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   */
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   */
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   */
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   */
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   */
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   */
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
   * "dynamic" variable index based on time, current stored index and virtual rate at the current
   * moment (approx. a borrower would get if opening a position). This means that is always used in
   * combination with variable debt supply/balances.
   * If using this function externally, consider that is possible to have an increasing normalized
   * variable debt that is not equivalent to how the variable debt index would be updated in storage
   * (e.g. only updates with non-zero variable debt supply)
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   */
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   */
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   */
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   */
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   */
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ConfiguratorInputTypes} from '../protocol/libraries/types/ConfiguratorInputTypes.sol';

/**
 * @title IPoolConfigurator
 * @author Aave
 * @notice Defines the basic interface for a Pool configurator.
 */
interface IPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   */
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing is enabled, false otherwise
   */
  event ReserveBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when flashloans are enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if flashloans are enabled, false otherwise
   */
  event ReserveFlashLoaning(address indexed asset, bool enabled);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing is enabled, false otherwise
   */
  event ReserveStableRateBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when a reserve is activated or deactivated
   * @param asset The address of the underlying asset of the reserve
   * @param active True if reserve is active, false otherwise
   */
  event ReserveActive(address indexed asset, bool active);

  /**
   * @dev Emitted when a reserve is frozen or unfrozen
   * @param asset The address of the underlying asset of the reserve
   * @param frozen True if reserve is frozen, false otherwise
   */
  event ReserveFrozen(address indexed asset, bool frozen);

  /**
   * @dev Emitted when a reserve is paused or unpaused
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if reserve is paused, false otherwise
   */
  event ReservePaused(address indexed asset, bool paused);

  /**
   * @dev Emitted when a reserve is dropped.
   * @param asset The address of the underlying asset of the reserve
   */
  event ReserveDropped(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldReserveFactor The old reserve factor, expressed in bps
   * @param newReserveFactor The new reserve factor, expressed in bps
   */
  event ReserveFactorChanged(
    address indexed asset,
    uint256 oldReserveFactor,
    uint256 newReserveFactor
  );

  /**
   * @dev Emitted when the borrow cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldBorrowCap The old borrow cap
   * @param newBorrowCap The new borrow cap
   */
  event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

  /**
   * @dev Emitted when the supply cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldSupplyCap The old supply cap
   * @param newSupplyCap The new supply cap
   */
  event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

  /**
   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldFee The old liquidation protocol fee, expressed in bps
   * @param newFee The new liquidation protocol fee, expressed in bps
   */
  event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

  /**
   * @dev Emitted when the unbacked mint cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldUnbackedMintCap The old unbacked mint cap
   * @param newUnbackedMintCap The new unbacked mint cap
   */
  event UnbackedMintCapChanged(
    address indexed asset,
    uint256 oldUnbackedMintCap,
    uint256 newUnbackedMintCap
  );

  /**
   * @dev Emitted when the category of an asset in eMode is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldCategoryId The old eMode asset category
   * @param newCategoryId The new eMode asset category
   */
  event EModeAssetCategoryChanged(address indexed asset, uint8 oldCategoryId, uint8 newCategoryId);

  /**
   * @dev Emitted when a new eMode category is added.
   * @param categoryId The new eMode category id
   * @param ltv The ltv for the asset category in eMode
   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
   * @param liquidationBonus The liquidationBonus for the asset category in eMode
   * @param oracle The optional address of the price oracle specific for this category
   * @param label A human readable identifier for the category
   */
  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  /**
   * @dev Emitted when a reserve interest strategy contract is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldStrategy The address of the old interest strategy contract
   * @param newStrategy The address of the new interest strategy contract
   */
  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address oldStrategy,
    address newStrategy
  );

  /**
   * @dev Emitted when an aToken implementation is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   */
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   */
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   */
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the debt ceiling of an asset is set.
   * @param asset The address of the underlying asset of the reserve
   * @param oldDebtCeiling The old debt ceiling
   * @param newDebtCeiling The new debt ceiling
   */
  event DebtCeilingChanged(address indexed asset, uint256 oldDebtCeiling, uint256 newDebtCeiling);

  /**
   * @dev Emitted when the the siloed borrowing state for an asset is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldState The old siloed borrowing state
   * @param newState The new siloed borrowing state
   */
  event SiloedBorrowingChanged(address indexed asset, bool oldState, bool newState);

  /**
   * @dev Emitted when the bridge protocol fee is updated.
   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
   */
  event BridgeProtocolFeeUpdated(uint256 oldBridgeProtocolFee, uint256 newBridgeProtocolFee);

  /**
   * @dev Emitted when the total premium on flashloans is updated.
   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
   * @param newFlashloanPremiumTotal The new premium, expressed in bps
   */
  event FlashloanPremiumTotalUpdated(
    uint128 oldFlashloanPremiumTotal,
    uint128 newFlashloanPremiumTotal
  );

  /**
   * @dev Emitted when the part of the premium that goes to protocol is updated.
   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
   */
  event FlashloanPremiumToProtocolUpdated(
    uint128 oldFlashloanPremiumToProtocol,
    uint128 newFlashloanPremiumToProtocol
  );

  /**
   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
   */
  event BorrowableInIsolationChanged(address asset, bool borrowable);

  /**
   * @notice Initializes multiple reserves.
   * @param input The array of initialization parameters
   */
  function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

  /**
   * @dev Updates the aToken implementation for the reserve.
   * @param input The aToken update parameters
   */
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input) external;

  /**
   * @notice Updates the stable debt token implementation for the reserve.
   * @param input The stableDebtToken update parameters
   */
  function updateStableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external;

  /**
   * @notice Updates the variable debt token implementation for the asset.
   * @param input The variableDebtToken update parameters
   */
  function updateVariableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external;

  /**
   * @notice Configures borrowing on a reserve.
   * @dev Can only be disabled (set to false) if stable borrowing is disabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing needs to be enabled, false otherwise
   */
  function setReserveBorrowing(address asset, bool enabled) external;

  /**
   * @notice Configures the reserve collateralization parameters.
   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @notice Enable or disable stable rate borrowing on a reserve.
   * @dev Can only be enabled (set to true) if borrowing is enabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
   */
  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  /**
   * @notice Enable or disable flashloans on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if flashloans need to be enabled, false otherwise
   */
  function setReserveFlashLoaning(address asset, bool enabled) external;

  /**
   * @notice Activate or deactivate a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param active True if the reserve needs to be active, false otherwise
   */
  function setReserveActive(address asset, bool active) external;

  /**
   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
   * @param asset The address of the underlying asset of the reserve
   * @param freeze True if the reserve needs to be frozen, false otherwise
   */
  function setReserveFreeze(address asset, bool freeze) external;

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
   */
  function setBorrowableInIsolation(address asset, bool borrowable) external;

  /**
   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
   * swap interest rate, liquidate, atoken transfers).
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if pausing the reserve, false if unpausing
   */
  function setReservePause(address asset, bool paused) external;

  /**
   * @notice Updates the reserve factor of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newReserveFactor The new reserve factor of the reserve
   */
  function setReserveFactor(address asset, uint256 newReserveFactor) external;

  /**
   * @notice Sets the interest rate strategy of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newRateStrategyAddress The address of the new interest strategy contract
   */
  function setReserveInterestRateStrategyAddress(address asset, address newRateStrategyAddress)
    external;

  /**
   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
   * are suspended.
   * @param paused True if protocol needs to be paused, false otherwise
   */
  function setPoolPause(bool paused) external;

  /**
   * @notice Updates the borrow cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newBorrowCap The new borrow cap of the reserve
   */
  function setBorrowCap(address asset, uint256 newBorrowCap) external;

  /**
   * @notice Updates the supply cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newSupplyCap The new supply cap of the reserve
   */
  function setSupplyCap(address asset, uint256 newSupplyCap) external;

  /**
   * @notice Updates the liquidation protocol fee of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
   */
  function setLiquidationProtocolFee(address asset, uint256 newFee) external;

  /**
   * @notice Updates the unbacked mint cap of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
   */
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap) external;

  /**
   * @notice Assign an efficiency mode (eMode) category to asset.
   * @param asset The address of the underlying asset of the reserve
   * @param newCategoryId The new category id of the asset
   */
  function setAssetEModeCategory(address asset, uint8 newCategoryId) external;

  /**
   * @notice Adds a new efficiency mode (eMode) category.
   * @dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
   * overcollateralization of the users using this category.
   * @dev The new ltv and liquidation threshold must be greater than the base
   * ltvs and liquidation thresholds of all assets within the eMode category
   * @param categoryId The id of the category to be configured
   * @param ltv The ltv associated with the category
   * @param liquidationThreshold The liquidation threshold associated with the category
   * @param liquidationBonus The liquidation bonus associated with the category
   * @param oracle The oracle associated with the category
   * @param label A label identifying the category
   */
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    address oracle,
    string calldata label
  ) external;

  /**
   * @notice Drops a reserve entirely.
   * @param asset The address of the reserve to drop
   */
  function dropReserve(address asset) external;

  /**
   * @notice Updates the bridge fee collected by the protocol reserves.
   * @param newBridgeProtocolFee The part of the fee sent to the protocol treasury, expressed in bps
   */
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;

  /**
   * @notice Updates the total flash loan premium.
   * Total flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra balance
   * - A part is collected by the protocol reserves
   * @dev Expressed in bps
   * @dev The premium is calculated on the total amount borrowed
   * @param newFlashloanPremiumTotal The total flashloan premium
   */
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;

  /**
   * @notice Updates the flash loan premium collected by protocol reserves
   * @dev Expressed in bps
   * @dev The premium to protocol is calculated on the total flashloan premium
   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
   */
  function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;

  /**
   * @notice Sets the debt ceiling for an asset.
   * @param newDebtCeiling The new debt ceiling
   */
  function setDebtCeiling(address asset, uint256 newDebtCeiling) external;

  /**
   * @notice Sets siloed borrowing for an asset
   * @param siloed The new siloed borrowing state
   */
  function setSiloedBorrowing(address asset, bool siloed) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IPoolDataProvider
 * @author Aave
 * @notice Defines the basic interface of a PoolDataProvider
 */
interface IPoolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  /**
   * @notice Returns the address for the PoolAddressesProvider contract.
   * @return The address for the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the list of the existing reserves in the pool.
   * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
   * @return The list of reserves, pairs of symbols and addresses
   */
  function getAllReservesTokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the list of the existing ATokens in the pool.
   * @return The list of ATokens, pairs of symbols and addresses
   */
  function getAllATokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the configuration data of the reserve
   * @dev Not returning borrow and supply caps for compatibility, nor pause flag
   * @param asset The address of the underlying asset of the reserve
   * @return decimals The number of decimals of the reserve
   * @return ltv The ltv of the reserve
   * @return liquidationThreshold The liquidationThreshold of the reserve
   * @return liquidationBonus The liquidationBonus of the reserve
   * @return reserveFactor The reserveFactor of the reserve
   * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
   * @return borrowingEnabled True if borrowing is enabled, false otherwise
   * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
   * @return isActive True if it is active, false otherwise
   * @return isFrozen True if it is frozen, false otherwise
   */
  function getReserveConfigurationData(address asset)
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

  /**
   * @notice Returns the efficiency mode category of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The eMode id of the reserve
   */
  function getReserveEModeCategory(address asset) external view returns (uint256);

  /**
   * @notice Returns the caps parameters of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return borrowCap The borrow cap of the reserve
   * @return supplyCap The supply cap of the reserve
   */
  function getReserveCaps(address asset)
    external
    view
    returns (uint256 borrowCap, uint256 supplyCap);

  /**
   * @notice Returns if the pool is paused
   * @param asset The address of the underlying asset of the reserve
   * @return isPaused True if the pool is paused, false otherwise
   */
  function getPaused(address asset) external view returns (bool isPaused);

  /**
   * @notice Returns the siloed borrowing flag
   * @param asset The address of the underlying asset of the reserve
   * @return True if the asset is siloed for borrowing
   */
  function getSiloedBorrowing(address asset) external view returns (bool);

  /**
   * @notice Returns the protocol fee on the liquidation bonus
   * @param asset The address of the underlying asset of the reserve
   * @return The protocol fee on liquidation
   */
  function getLiquidationProtocolFee(address asset) external view returns (uint256);

  /**
   * @notice Returns the unbacked mint cap of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The unbacked mint cap of the reserve
   */
  function getUnbackedMintCap(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The debt ceiling of the reserve
   */
  function getDebtCeiling(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling decimals
   * @return The debt ceiling decimals
   */
  function getDebtCeilingDecimals() external pure returns (uint256);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   */
  function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   */
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   */
  function getTotalDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the user data in a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @return currentATokenBalance The current AToken balance of the user
   * @return currentStableDebt The current stable debt of the user
   * @return currentVariableDebt The current variable debt of the user
   * @return principalStableDebt The principal stable debt of the user
   * @return scaledVariableDebt The scaled variable debt of the user
   * @return stableBorrowRate The stable borrow rate of the user
   * @return liquidityRate The liquidity rate of the reserve
   * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
   * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
   *         otherwise
   */
  function getUserReserveData(address asset, address user)
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

  /**
   * @notice Returns the token addresses of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return aTokenAddress The AToken address of the reserve
   * @return stableDebtTokenAddress The StableDebtToken address of the reserve
   * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
   */
  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  /**
   * @notice Returns the address of the Interest Rate strategy
   * @param asset The address of the underlying asset of the reserve
   * @return irStrategyAddress The address of the Interest Rate strategy
   */
  function getInterestRateStrategyAddress(address asset)
    external
    view
    returns (address irStrategyAddress);

  /**
   * @notice Returns whether the reserve has FlashLoans enabled or disabled
   * @param asset The address of the underlying asset of the reserve
   * @return True if FlashLoans are enabled, false otherwise
   */
  function getFlashLoanEnabled(address asset) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   */
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   */
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IReserveInterestRateStrategy
 * @author Aave
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
  /**
   * @notice Calculates the interest rates depending on the reserve's state and configurations
   * @param params The parameters needed to calculate interest rates
   * @return liquidityRate The liquidity rate expressed in rays
   * @return stableBorrowRate The stable borrow rate expressed in rays
   * @return variableBorrowRate The variable borrow rate expressed in rays
   */
  function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

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

  ILendingRateOracle internal constant LENDING_RATE_ORACLE =
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
    0x33DeAc0861FD6a9235b86172AA939E79085c6f52;

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
    0x6bcE15B789e537f3abA3C60CB183F0E8737f05eC;

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

  address internal constant BAL_INTEREST_RATE_STRATEGY = 0x04c28D6fE897859153eA753f986cc249Bf064f71;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {ConfiguratorInputTypes} from 'aave-v3-core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from 'aave-v3-core/contracts/interfaces/IPoolConfigurator.sol';
import {IPriceOracleGetter} from 'aave-v3-core/contracts/interfaces/IPriceOracleGetter.sol';
import {IAaveOracle} from 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IACLManager as BasicIACLManager} from 'aave-v3-core/contracts/interfaces/IACLManager.sol';
import {IPoolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {IDefaultInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {IPoolDataProvider as IAaveProtocolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';

/**
 * @title ICollector
 * @notice Defines the interface of the Collector contract
 * @author Aave
 **/
interface ICollector {
  /**
   * @dev Emitted during the transfer of ownership of the funds administrator address
   * @param fundsAdmin The new funds administrator address
   **/
  event NewFundsAdmin(address indexed fundsAdmin);

  /**
   * @dev Retrieve the current implementation Revision of the proxy
   * @return The revision version
   */
  function REVISION() external view returns (uint256);

  /**
   * @dev Retrieve the current funds administrator
   * @return The address of the funds administrator
   */
  function getFundsAdmin() external view returns (address);

  /**
   * @dev Approve an amount of tokens to be pulled by the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity allowed to pull tokens
   * @param amount The amount allowed to be pulled. If zero it will revoke the approval.
   */
  function approve(
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function transfer(
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer the ownership of the funds administrator role.
          This function should only be callable by the current funds administrator.
   * @param admin The address of the new funds administrator
   */
  function setFundsAdmin(address admin) external;
}

interface IACLManager is BasicIACLManager {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

  function renounceRole(bytes32 role, address account) external;

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Ethereum {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);

  IPool internal constant POOL = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x64b761D848206f447Fe2dd461b0c635Ec39EbB27);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0);

  address internal constant ACL_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57;

  address internal constant EMISSION_MANAGER = 0x223d844fc4B006D67c0cDbd39371A9F73f69d974;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0xbaA999AC55EAce41CcAE355c77809e68Bb345170;

  address internal constant WETH_GATEWAY = 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x1809f186D680f239420B56948C58F8DbbCdf1E18;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x872fBcb1B582e8Cd0D0DD4327fBFa0B4C2730995;

  address internal constant LISTING_ENGINE = 0xC51e6E38d406F98049622Ca54a6096a23826B426;

  address internal constant WALLET_BALANCE_PROVIDER = 0xC7be5307ba715ce89b152f3Df0658295b3dbA8E2;

  address internal constant UI_POOL_DATA_PROVIDER = 0x91c0eA31b49B69Ea18607702c5d9aC360bf3dE7d;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x162A7AC02f547ad796CA549f757e2b8d1D9b10a6;
}

library AaveV3EthereumAssets {
  address internal constant WETH_UNDERLYING = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant WETH_A_TOKEN = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

  address internal constant WETH_V_TOKEN = 0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;

  address internal constant WETH_S_TOKEN = 0x102633152313C81cD80419b6EcF66d14Ad68949A;

  address internal constant WETH_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x53F57eAAD604307889D87b747Fc67ea9DE430B01;

  address internal constant wstETH_UNDERLYING = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

  address internal constant wstETH_A_TOKEN = 0x0B925eD163218f6662a35e0f0371Ac234f9E9371;

  address internal constant wstETH_V_TOKEN = 0xC96113eED8cAB59cD8A66813bCB0cEb29F06D2e4;

  address internal constant wstETH_S_TOKEN = 0x39739943199c0fBFe9E5f1B5B160cd73a64CB85D;

  address internal constant wstETH_ORACLE = 0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45;

  address internal constant wstETH_INTEREST_RATE_STRATEGY =
    0x7b8Fa4540246554e77FCFf140f9114de00F8bB8D;

  address internal constant WBTC_UNDERLYING = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

  address internal constant WBTC_A_TOKEN = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;

  address internal constant WBTC_V_TOKEN = 0x40aAbEf1aa8f0eEc637E0E7d92fbfFB2F26A8b7B;

  address internal constant WBTC_S_TOKEN = 0xA1773F1ccF6DB192Ad8FE826D15fe1d328B03284;

  address internal constant WBTC_ORACLE = 0x230E0321Cf38F09e247e50Afc7801EA2351fe56F;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;

  address internal constant USDC_UNDERLYING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address internal constant USDC_A_TOKEN = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;

  address internal constant USDC_V_TOKEN = 0x72E95b8931767C79bA4EeE721354d6E99a61D004;

  address internal constant USDC_S_TOKEN = 0xB0fe3D292f4bd50De902Ba5bDF120Ad66E9d7a39;

  address internal constant USDC_ORACLE = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xD6293edBB2E5E0687a79F01BEcd51A778d59D1c5;

  address internal constant DAI_UNDERLYING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address internal constant DAI_A_TOKEN = 0x018008bfb33d285247A21d44E50697654f754e63;

  address internal constant DAI_V_TOKEN = 0xcF8d0c70c850859266f5C338b38F9D663181C314;

  address internal constant DAI_S_TOKEN = 0x413AdaC9E2Ef8683ADf5DDAEce8f19613d60D1bb;

  address internal constant DAI_ORACLE = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x694d4cFdaeE639239df949b6E24Ff8576A00d1f2;

  address internal constant LINK_UNDERLYING = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  address internal constant LINK_A_TOKEN = 0x5E8C8A7243651DB1384C0dDfDbE39761E8e7E51a;

  address internal constant LINK_V_TOKEN = 0x4228F8895C7dDA20227F6a5c6751b8Ebf19a6ba8;

  address internal constant LINK_S_TOKEN = 0x63B1129ca97D2b9F97f45670787Ac12a9dF1110a;

  address internal constant LINK_ORACLE = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;

  address internal constant AAVE_UNDERLYING = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

  address internal constant AAVE_A_TOKEN = 0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9;

  address internal constant AAVE_V_TOKEN = 0xBae535520Abd9f8C85E58929e0006A2c8B372F74;

  address internal constant AAVE_S_TOKEN = 0x268497bF083388B1504270d0E717222d3A87D6F2;

  address internal constant AAVE_ORACLE = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;

  address internal constant cbETH_UNDERLYING = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;

  address internal constant cbETH_A_TOKEN = 0x977b6fc5dE62598B08C85AC8Cf2b745874E8b78c;

  address internal constant cbETH_V_TOKEN = 0x0c91bcA95b5FE69164cE583A2ec9429A569798Ed;

  address internal constant cbETH_S_TOKEN = 0x82bE6012cea6D147B968eBAea5ceEcF6A5b4F493;

  address internal constant cbETH_ORACLE = 0x5f4d15d761528c57a5C30c43c1DAb26Fc5452731;

  address internal constant cbETH_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;

  address internal constant USDT_UNDERLYING = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  address internal constant USDT_A_TOKEN = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;

  address internal constant USDT_V_TOKEN = 0x6df1C1E379bC5a00a7b4C6e67A203333772f45A8;

  address internal constant USDT_S_TOKEN = 0x822Fa72Df1F229C3900f5AD6C3Fa2C424D691622;

  address internal constant USDT_ORACLE = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0xdd1BAC6A713c5b0EC42bA39D0c5e4582975DE6D6;

  address internal constant rETH_UNDERLYING = 0xae78736Cd615f374D3085123A210448E74Fc6393;

  address internal constant rETH_A_TOKEN = 0xCc9EE9483f662091a1de4795249E24aC0aC2630f;

  address internal constant rETH_V_TOKEN = 0xae8593DD575FE29A9745056aA91C4b746eee62C8;

  address internal constant rETH_S_TOKEN = 0x1d1906f909CAe494c7441604DAfDDDbD0485A925;

  address internal constant rETH_ORACLE = 0x05225Cd708bCa9253789C1374e4337a019e99D56;

  address internal constant rETH_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {IGenericV3ListingEngine} from './IGenericV3ListingEngine.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 listing.
 * - Assumes this contract has the right permissions
 * - Connected to a IGenericV3ListingEngine, handling the internals of the listing
 *   and exposing a simple interface
 * @author BGD Labs
 */
abstract contract AaveV3ListingBase {
  using Address for address;

  IGenericV3ListingEngine public immutable LISTING_ENGINE;

  constructor(IGenericV3ListingEngine listingEngine) {
    LISTING_ENGINE = listingEngine;
  }

  /// @dev to be overriden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overriden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    address(LISTING_ENGINE).functionDelegateCall(
      abi.encodeWithSelector(LISTING_ENGINE.listAssets.selector, getPoolContext(), getAllConfigs())
    );

    _postExecute();
  }

  /// @dev to be defined in the child with the specific listing config
  function getAllConfigs() public virtual returns (IGenericV3ListingEngine.Listing[] memory);

  /// @dev the lack of support for immutable strings kinds of forces for this
  /// Besides that, it can actually be useful being able to change the naming, but remote
  function getPoolContext() public virtual returns (IGenericV3ListingEngine.PoolContext memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3ListingBase, IGenericV3ListingEngine} from './AaveV3ListingBase.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 (compatible with 3.0.0) listing on v3 Ethereum.
 * @author BGD Labs
 */
abstract contract AaveV3ListingEthereum is AaveV3ListingBase {
  constructor(IGenericV3ListingEngine listingEngine) AaveV3ListingBase(listingEngine) {}

  function getPoolContext()
    public
    pure
    override
    returns (IGenericV3ListingEngine.PoolContext memory)
  {
    return
      IGenericV3ListingEngine.PoolContext({networkName: 'Ethereum', networkAbbreviation: 'Eth'});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenericV3ListingEngine {
  /**
   * @dev Required for naming of a/v/s tokens
   * Example:
   * PoolContext({
   *   networkName: 'Polygon',
   *   networkAbbreviation: 'Pol'
   * })
   */
  struct PoolContext {
    string networkName;
    string networkAbbreviation;
  }

  /**
   * @dev Example (mock addresses):
   * Listing({
   *   asset: 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
   *   assetSymbol: 'AAVE',
   *   priceFeed: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9,
   *   rateStrategy: 0x03733F4E008d36f2e37F0080fF1c8DF756622E6F,
   *   enabledToBorrow: true,
   *   flashloanable: true,
   *   stableRateModeEnabled: false,
   *   borrowableInIsolation: true,
   *   withSiloedBorrowing:, false,
   *   ltv: 70_50, // 70.5%
   *   liqThreshold: 76_00, // 76%
   *   liqBonus: 5_00, // 5%
   *   reserveFactor: 10_00, // 10%
   *   supplyCap: 100_000, // 100k AAVE
   *   borrowCap: 60_000, // 60k AAVE
   *   debtCeiling: 100_000, // 100k USD
   *   liqProtocolFee: 10_00, // 10%
   *   eModeCategory: 0, // No category
   * }
   */
  struct Listing {
    address asset;
    string assetSymbol;
    address priceFeed;
    address rateStrategy; // Mandatory, no matter if enabled for borrowing or not
    bool enabledToBorrow;
    bool stableRateModeEnabled; // Only considered is enabledToBorrow == true
    bool borrowableInIsolation; // Only considered is enabledToBorrow == true
    bool withSiloedBorrowing; // Only considered if enabledToBorrow == true
    bool flashloanable; // Independent from enabled to borrow: an asset can be flashloanble and not enabled to borrow
    uint256 ltv; // Only considered if liqThreshold > 0
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral
    uint256 liqBonus; // Only considered if liqThreshold > 0
    uint256 reserveFactor; // Only considered if enabledToBorrow == true
    uint256 supplyCap; // Always configured
    uint256 borrowCap; // Always configured, no matter if enabled for borrowing or not
    uint256 debtCeiling; // Only considered if liqThreshold > 0
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0
    uint8 eModeCategory; // If `O`, no eMode category will be set
  }

  struct AssetsConfig {
    address[] ids;
    Basic[] basics;
    Borrow[] borrows;
    Collateral[] collaterals;
    Caps[] caps;
  }

  struct Basic {
    string assetSymbol;
    address priceFeed;
    address rateStrategy; // Mandatory, no matter if enabled for borrowing or not
  }

  struct Borrow {
    bool enabledToBorrow; // Main config flag, if false, some of the other fields will not be considered
    bool flashloanable;
    bool stableRateModeEnabled;
    bool borrowableInIsolation;
    bool withSiloedBorrowing;
    uint256 reserveFactor; // With 2 digits precision, `10_00` for 10%. Should be positive and < 100_00
  }

  struct Collateral {
    uint256 ltv; // Only considered if liqThreshold > 0. With 2 digits precision, `10_00` for 10%. Should be lower than liquidationThreshold
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral. Same format as ltv, and should be higher
    uint256 liqBonus; // Only considered if liqThreshold > 0. Same format as ltv
    uint256 debtCeiling; // Only considered if liqThreshold > 0. In USD and with 2 digits for decimals, e.g. 10_000_00 for 10k
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0. Same format as ltv
    uint8 eModeCategory;
  }

  struct Caps {
    uint256 supplyCap; // Always configured. In "big units" of the asset, and no decimals. 100 for 100 ETH supply cap
    uint256 borrowCap; // Always configured, no matter if enabled for borrowing or not. Same format as supply cap
  }

  /**
   * @notice Performs a full listing of an asset in the Aave pool configured in this engine instance
   * @param context `PoolContext` struct, effectively meta-data for naming of a/v/s tokens.
   *   More information on the documentation of the struct.
   * @param listings `Listing[]` list of declarative configs for every aspect of the asset listing.
   *   More information on the documentation of the struct.
   */
  function listAssets(PoolContext memory context, Listing[] memory listings) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.1;

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), 'Address: call to non-contract');
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason or using the provided one.
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
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IGenericV3ListingEngine, AaveV3ListingEthereum} from 'aave-helpers/v3-listing-engine/AaveV3ListingEthereum.sol';

/**
 * @title List CRV on AaveV3Ethereum
 * @author Llama
 * @dev This proposal lists CRV on Aave V3 Ethereum
 * Governance: https://governance.aave.com/t/arfc-add-crv-to-ethereum-v3/11532
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xa0b5336692735fb4288537646aec5819cb4cbf01fc3a8a7cb06c9e62db708055
 */
contract AaveV3EthAddCRVPoolPayload is AaveV3ListingEthereum {
  address public constant INTEREST_RATE_STRATEGY = 0x76884cAFeCf1f7d4146DA6C4053B18B76bf6ED14;
  address public constant CRV_USD_FEED = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f;

  constructor() AaveV3ListingEthereum(IGenericV3ListingEngine(AaveV3Ethereum.LISTING_ENGINE)) {}

  function getAllConfigs() public pure override returns (IGenericV3ListingEngine.Listing[] memory) {
    IGenericV3ListingEngine.Listing[] memory listings = new IGenericV3ListingEngine.Listing[](1);

    listings[0] = IGenericV3ListingEngine.Listing({
      asset: AaveV2EthereumAssets.CRV_UNDERLYING,
      assetSymbol: 'CRV',
      priceFeed: CRV_USD_FEED,
      rateStrategy: INTEREST_RATE_STRATEGY,
      enabledToBorrow: true,
      stableRateModeEnabled: false,
      borrowableInIsolation: false,
      withSiloedBorrowing: false,
      flashloanable: true,
      ltv: 55_00,
      liqThreshold: 61_00,
      liqBonus: 8_30,
      reserveFactor: 20_00,
      supplyCap: 62_500_000,
      borrowCap: 7_700_000,
      debtCeiling: 20_900_000_00,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }
}