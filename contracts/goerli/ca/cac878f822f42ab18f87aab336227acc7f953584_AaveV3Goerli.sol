// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";
import {IAaveProtocolDataProvider} from "../../interfaces/aaveV3/IAaveProtocolDataProvider.sol";
import {IPool} from "../../interfaces/aaveV3/IPool.sol";

/**
 * @title AaveV3 Lending Provider.
 * @author fujidao Labs
 * @notice This contract allows interaction with AaveV3.
 */
contract AaveV3Goerli is ILendingProvider {
  function _getAaveProtocolDataProvider() internal pure returns (IAaveProtocolDataProvider) {
    return IAaveProtocolDataProvider(0x9BE876c6DC42215B00d7efe892E2691C3bc35d10);
  }

  function _getPool() internal pure returns (IPool) {
    return IPool(0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6);
  }

  /**
   * @notice See {ILendingProvider}
   */
  function approvedOperator(address) external pure override returns (address operator) {
    operator = address(_getPool());
  }

  /**
   * @notice See {ILendingProvider}
   */
  function deposit(address asset, uint256 amount) external override returns (bool success) {
    IPool aave = _getPool();
    aave.supply(asset, amount, address(this), 0);
    aave.setUserUseReserveAsCollateral(asset, true);
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function borrow(address asset, uint256 amount) external override returns (bool success) {
    IPool aave = _getPool();
    aave.borrow(asset, amount, 2, 0, address(this));
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function withdraw(address asset, uint256 amount) external override returns (bool success) {
    IPool aave = _getPool();
    aave.withdraw(asset, amount, address(this));
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function payback(address asset, uint256 amount) external override returns (bool success) {
    IPool aave = _getPool();
    aave.repay(asset, amount, 2, address(this));
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getDepositRateFor(address asset) external view override returns (uint256 rate) {
    IPool aaveData = _getPool();
    IPool.ReserveData memory rdata = aaveData.getReserveData(asset);
    rate = rdata.currentLiquidityRate;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getBorrowRateFor(address asset) external view override returns (uint256 rate) {
    IPool aaveData = _getPool();
    IPool.ReserveData memory rdata = aaveData.getReserveData(asset);
    rate = rdata.currentVariableBorrowRate;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getDepositBalance(address asset, address user)
    external
    view
    override
    returns (uint256 balance)
  {
    IAaveProtocolDataProvider aaveData = _getAaveProtocolDataProvider();
    (balance,,,,,,,,) = aaveData.getUserReserveData(asset, user);
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getBorrowBalance(address asset, address user)
    external
    view
    override
    returns (uint256 balance)
  {
    IAaveProtocolDataProvider aaveData = _getAaveProtocolDataProvider();
    (,, balance,,,,,,) = aaveData.getUserReserveData(asset, user);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

/**
 * @title Lending provider interface.
 * @author fujidao Labs
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 */
interface ILendingProvider {
  /**
   * @notice Returns the operator address that requires ERC20-approval for deposits.
   * @param asset address.
   */
  function approvedOperator(address asset) external returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   */
  function deposit(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   */
  function borrow(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   */
  function withdraw(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Performs payback operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   * @dev Check erc20-approval to lending provider prior to call.
   */
  function payback(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   * @param asset address.
   * @dev Should return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   */
  function getDepositRateFor(address asset) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   * @param asset address.
   * @dev Should return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   */
  function getBorrowRateFor(address asset) external view returns (uint256 rate);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   * @param asset address.
   * @param user address whom balance is needed.
   */
  function getDepositBalance(address asset, address user) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   * @param asset address.
   * @param user address whom balance is needed.
   */
  function getBorrowBalance(address asset, address user) external view returns (uint256 balance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IAaveProtocolDataProvider {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IPool {
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

  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  )
    external;

  function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
    external
    returns (uint256);

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  )
    external;

  function getReserveData(address asset) external view returns (ReserveData memory);
}