// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IPool} from "@aave-v3-core/interfaces/IPool.sol";
import {IPositionsManager} from "./interfaces/IPositionsManager.sol";

import {Types} from "./libraries/Types.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {PoolLib} from "./libraries/PoolLib.sol";
import {Constants} from "./libraries/Constants.sol";
import {MarketBalanceLib} from "./libraries/MarketBalanceLib.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";

import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC20 as ERC20Permit2, Permit2Lib} from "@permit2/libraries/Permit2Lib.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {MorphoStorage} from "./MorphoStorage.sol";
import {PositionsManagerInternal} from "./PositionsManagerInternal.sol";

/// @title PositionsManager
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Abstract contract exposing logic functions delegate-called by the `Morpho` contract.
contract PositionsManager is IPositionsManager, PositionsManagerInternal {
    using PoolLib for IPool;
    using MarketBalanceLib for Types.MarketBalances;

    using Math for uint256;
    using PercentageMath for uint256;

    using SafeTransferLib for ERC20;
    using Permit2Lib for ERC20Permit2;

    using EnumerableSet for EnumerableSet.AddressSet;

    /* EXTERNAL */

    /// @notice Implements the supply logic.
    /// @param underlying The address of the underlying asset to supply.
    /// @param amount The amount of `underlying` to supply.
    /// @param from The address to transfer the underlying from.
    /// @param onBehalf The address that will receive the supply position.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    /// @return The amount supplied (in underlying).
    function supplyLogic(address underlying, uint256 amount, address from, address onBehalf, uint256 maxIterations)
        external
        returns (uint256)
    {
        Types.Market storage market = _validateSupply(underlying, amount, onBehalf);

        Types.Indexes256 memory indexes = _updateIndexes(underlying);

        ERC20Permit2(underlying).transferFrom2(from, address(this), amount);

        Types.SupplyRepayVars memory vars = _executeSupply(underlying, amount, from, onBehalf, maxIterations, indexes);

        _pool.repayToPool(underlying, market.variableDebtToken, vars.toRepay);
        _pool.supplyToPool(underlying, vars.toSupply, indexes.supply.poolIndex);

        return amount;
    }

    /// @notice Implements the supply collateral logic.
    /// @dev Relies on Aave to check the supply cap when supplying collateral.
    /// @param underlying The address of the underlying asset to supply.
    /// @param amount The amount of `underlying` to supply.
    /// @param from The address to transfer the underlying from.
    /// @param onBehalf The address that will receive the collateral position.
    /// @return The collateral amount supplied (in underlying).
    function supplyCollateralLogic(address underlying, uint256 amount, address from, address onBehalf)
        external
        returns (uint256)
    {
        _validateSupplyCollateral(underlying, amount, onBehalf);

        Types.Indexes256 memory indexes = _updateIndexes(underlying);

        ERC20Permit2(underlying).transferFrom2(from, address(this), amount);

        _executeSupplyCollateral(underlying, amount, from, onBehalf, indexes.supply.poolIndex);

        _pool.supplyToPool(underlying, amount, indexes.supply.poolIndex);

        return amount;
    }

    /// @notice Implements the borrow logic.
    /// @param underlying The address of the underlying asset to borrow.
    /// @param amount The amount of `underlying` to borrow.
    /// @param borrower The address that will receive the debt position.
    /// @param receiver The address that will receive the borrowed funds.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    /// @return The amount borrowed (in underlying).
    function borrowLogic(address underlying, uint256 amount, address borrower, address receiver, uint256 maxIterations)
        external
        returns (uint256)
    {
        Types.Market storage market = _validateBorrow(underlying, amount, borrower, receiver);

        Types.Indexes256 memory indexes = _updateIndexes(underlying);

        _authorizeBorrow(underlying, amount, indexes);

        Types.BorrowWithdrawVars memory vars =
            _executeBorrow(underlying, amount, borrower, receiver, maxIterations, indexes);

        // The following check requires accounting to have been performed.
        Types.LiquidityData memory values = _liquidityData(borrower);
        if (values.debt > values.borrowable) revert Errors.UnauthorizedBorrow();

        _pool.withdrawFromPool(underlying, market.aToken, vars.toWithdraw);
        _pool.borrowFromPool(underlying, vars.toBorrow);

        ERC20(underlying).safeTransfer(receiver, amount);

        return amount;
    }

    /// @notice Implements the repay logic.
    /// @param underlying The address of the underlying asset to borrow.
    /// @param amount The amount of `underlying` to repay.
    /// @param repayer The address that repays the underlying debt.
    /// @param onBehalf The address whose position will be repaid.
    /// @return The amount repaid (in underlying).
    function repayLogic(address underlying, uint256 amount, address repayer, address onBehalf)
        external
        returns (uint256)
    {
        Types.Market storage market = _validateRepay(underlying, amount, onBehalf);

        Types.Indexes256 memory indexes = _updateIndexes(underlying);
        amount = Math.min(_getUserBorrowBalanceFromIndexes(underlying, onBehalf, indexes), amount);

        if (amount == 0) revert Errors.DebtIsZero();

        ERC20Permit2(underlying).transferFrom2(repayer, address(this), amount);

        Types.SupplyRepayVars memory vars =
            _executeRepay(underlying, amount, repayer, onBehalf, _defaultIterations.repay, indexes);

        _pool.repayToPool(underlying, market.variableDebtToken, vars.toRepay);
        _pool.supplyToPool(underlying, vars.toSupply, indexes.supply.poolIndex);

        return amount;
    }

    /// @notice Implements the withdraw logic.
    /// @param underlying The address of the underlying asset to withdraw.
    /// @param amount The amount of `underlying` to withdraw.
    /// @param supplier The address whose position will be withdrawn.
    /// @param receiver The address that will receive the withdrawn funds.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    /// @return The amount withdrawn (in underlying).
    function withdrawLogic(
        address underlying,
        uint256 amount,
        address supplier,
        address receiver,
        uint256 maxIterations
    ) external returns (uint256) {
        Types.Market storage market = _validateWithdraw(underlying, amount, supplier, receiver);

        Types.Indexes256 memory indexes = _updateIndexes(underlying);
        amount = Math.min(_getUserSupplyBalanceFromIndexes(underlying, supplier, indexes), amount);

        if (amount == 0) revert Errors.SupplyIsZero();

        Types.BorrowWithdrawVars memory vars = _executeWithdraw(
            underlying, amount, supplier, receiver, Math.max(_defaultIterations.withdraw, maxIterations), indexes
        );

        _pool.withdrawFromPool(underlying, market.aToken, vars.toWithdraw);
        _pool.borrowFromPool(underlying, vars.toBorrow);

        ERC20(underlying).safeTransfer(receiver, amount);

        return amount;
    }

    /// @notice Implements the withdraw collateral logic.
    /// @param underlying The address of the underlying asset to withdraw.
    /// @param amount The amount of `underlying` to withdraw.
    /// @param supplier The address whose position will be withdrawn.
    /// @param receiver The address that will receive the withdrawn funds.
    /// @return The collateral amount withdrawn (in underlying).
    function withdrawCollateralLogic(address underlying, uint256 amount, address supplier, address receiver)
        external
        returns (uint256)
    {
        Types.Market storage market = _validateWithdrawCollateral(underlying, amount, supplier, receiver);

        Types.Indexes256 memory indexes = _updateIndexes(underlying);
        uint256 poolSupplyIndex = indexes.supply.poolIndex;
        amount = Math.min(_getUserCollateralBalanceFromIndex(underlying, supplier, poolSupplyIndex), amount);

        if (amount == 0) revert Errors.CollateralIsZero();

        _executeWithdrawCollateral(underlying, amount, supplier, receiver, poolSupplyIndex);

        // The following check requires accounting to have been performed.
        if (_getUserHealthFactor(supplier) < Constants.DEFAULT_LIQUIDATION_MAX_HF) {
            revert Errors.UnauthorizedWithdraw();
        }

        _pool.withdrawFromPool(underlying, market.aToken, amount);

        ERC20(underlying).safeTransfer(receiver, amount);

        return amount;
    }

    /// @notice Implements the liquidation logic.
    /// @param underlyingBorrowed The address of the underlying borrowed to repay.
    /// @param underlyingCollateral The address of the underlying collateral to seize.
    /// @param amount The amount of `underlyingBorrowed` to repay.
    /// @param borrower The address of the borrower to liquidate.
    /// @param liquidator The address that will liquidate the borrower.
    /// @return The `underlyingBorrowed` amount repaid (in underlying) and the `underlyingCollateral` amount seized (in underlying).
    function liquidateLogic(
        address underlyingBorrowed,
        address underlyingCollateral,
        uint256 amount,
        address borrower,
        address liquidator
    ) external returns (uint256, uint256) {
        _validateLiquidate(underlyingBorrowed, underlyingCollateral, borrower);

        Types.Indexes256 memory borrowIndexes = _updateIndexes(underlyingBorrowed);
        Types.Indexes256 memory collateralIndexes = _updateIndexes(underlyingCollateral);

        Types.LiquidateVars memory vars;
        vars.closeFactor = _authorizeLiquidate(underlyingBorrowed, borrower);

        amount = Math.min(
            _getUserBorrowBalanceFromIndexes(underlyingBorrowed, borrower, borrowIndexes).percentMul(vars.closeFactor), // Max liquidatable debt.
            amount
        );

        // If the check is done later, it is ambiguous whether debt is truly zero or whether there's not enough collateral to cover for 1 dust of debt.
        if (amount == 0) revert Errors.DebtIsZero();

        (amount, vars.seized) = _calculateAmountToSeize(
            underlyingBorrowed, underlyingCollateral, amount, borrower, collateralIndexes.supply.poolIndex
        );

        if (vars.seized == 0) revert Errors.CollateralIsZero();
        if (amount == 0) revert Errors.DebtIsZero(); // `amount` could still be zero because there's not enough collateral to cover for 1 dust of debt.

        ERC20Permit2(underlyingBorrowed).transferFrom2(liquidator, address(this), amount);

        Types.SupplyRepayVars memory repayVars =
            _executeRepay(underlyingBorrowed, amount, liquidator, borrower, 0, borrowIndexes);
        _executeWithdrawCollateral(
            underlyingCollateral, vars.seized, borrower, liquidator, collateralIndexes.supply.poolIndex
        );

        _pool.repayToPool(underlyingBorrowed, _market[underlyingBorrowed].variableDebtToken, repayVars.toRepay);
        _pool.supplyToPool(underlyingBorrowed, repayVars.toSupply, borrowIndexes.supply.poolIndex);
        _pool.withdrawFromPool(underlyingCollateral, _market[underlyingCollateral].aToken, vars.seized);

        ERC20(underlyingCollateral).safeTransfer(liquidator, vars.seized);

        emit Events.Liquidated(liquidator, borrower, underlyingBorrowed, amount, underlyingCollateral, vars.seized);

        return (amount, vars.seized);
    }
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
   * into consideration. For further details please visit https://docs.aave.com/developers/
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
   * into consideration. For further details please visit https://docs.aave.com/developers/
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface IPositionsManager {
    function supplyLogic(address underlying, uint256 amount, address from, address onBehalf, uint256 maxIterations)
        external
        returns (uint256 supplied);

    function supplyCollateralLogic(address underlying, uint256 amount, address from, address onBehalf)
        external
        returns (uint256 supplied);

    function borrowLogic(address underlying, uint256 amount, address borrower, address receiver, uint256 maxIterations)
        external
        returns (uint256 borrowed);

    function repayLogic(address underlying, uint256 amount, address repayer, address onBehalf)
        external
        returns (uint256 repaid);

    function withdrawLogic(
        address underlying,
        uint256 amount,
        address supplier,
        address receiver,
        uint256 maxIterations
    ) external returns (uint256 withdrawn);
    function withdrawCollateralLogic(address underlying, uint256 amount, address supplier, address receiver)
        external
        returns (uint256 withdrawn);

    function liquidateLogic(
        address underlyingBorrowed,
        address underlyingCollateral,
        uint256 amount,
        address borrower,
        address liquidator
    ) external returns (uint256 liquidated, uint256 seized);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IAaveOracle} from "@aave-v3-core/interfaces/IAaveOracle.sol";

import {DataTypes} from "@aave-v3-core/protocol/libraries/types/DataTypes.sol";

import {LogarithmicBuckets} from "@morpho-data-structures/LogarithmicBuckets.sol";

/// @title Types
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library exposing all Types used in Morpho.
library Types {
    /* ENUMS */

    /// @notice Enumeration of the different position types in the protocol.
    enum Position {
        POOL_SUPPLIER,
        P2P_SUPPLIER,
        POOL_BORROWER,
        P2P_BORROWER
    }

    /* NESTED STRUCTS */

    /// @notice Contains the market side delta data.
    struct MarketSideDelta {
        uint256 scaledDelta; // The delta amount in pool unit.
        uint256 scaledP2PTotal; // The total peer-to-peer amount in peer-to-peer unit.
    }

    /// @notice Contains the delta data for both `supply` and `borrow`.
    struct Deltas {
        MarketSideDelta supply; // The `MarketSideDelta` related to the supply side.
        MarketSideDelta borrow; // The `MarketSideDelta` related to the borrow side.
    }

    /// @notice Contains the market side indexes.
    struct MarketSideIndexes {
        uint128 poolIndex; // The pool index (in ray).
        uint128 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the indexes for both `supply` and `borrow`.
    struct Indexes {
        MarketSideIndexes supply; // The `MarketSideIndexes` related to the supply side.
        MarketSideIndexes borrow; // The `MarketSideIndexes` related to the borrow side.
    }

    /// @notice Contains the different pauses statuses possible in Morpho.
    struct PauseStatuses {
        bool isP2PDisabled;
        bool isSupplyPaused;
        bool isSupplyCollateralPaused;
        bool isBorrowPaused;
        bool isWithdrawPaused;
        bool isWithdrawCollateralPaused;
        bool isRepayPaused;
        bool isLiquidateCollateralPaused;
        bool isLiquidateBorrowPaused;
        bool isDeprecated;
    }

    /* STORAGE STRUCTS */

    /// @notice Contains the market data that is stored in storage.
    /// @dev This market struct is able to be passed into memory.
    struct Market {
        // SLOT 0-1
        Indexes indexes;
        // SLOT 2-5
        Deltas deltas; // 1024 bits
        // SLOT 6
        address underlying; // 160 bits
        PauseStatuses pauseStatuses; // 80 bits
        bool isCollateral; // 8 bits
        // SLOT 7
        address variableDebtToken; // 160 bits
        uint32 lastUpdateTimestamp; // 32 bits
        uint16 reserveFactor; // 16 bits
        uint16 p2pIndexCursor; // 16 bits
        // SLOT 8
        address aToken; // 160 bits
        // SLOT 9
        address stableDebtToken; // 160 bits
        // SLOT 10
        uint256 idleSupply; // 256 bits
    }

    /// @notice Contains storage-only dynamic arrays and mappings.
    struct MarketBalances {
        LogarithmicBuckets.Buckets poolSuppliers; // In pool unit.
        LogarithmicBuckets.Buckets p2pSuppliers; // In peer-to-peer unit.
        LogarithmicBuckets.Buckets poolBorrowers; // In pool unit.
        LogarithmicBuckets.Buckets p2pBorrowers; // In peer-to-peer unit.
        mapping(address => uint256) collateral; // In pool unit.
    }

    /// @notice Contains the minimum number of iterations for a `repay` or a `withdraw`.
    struct Iterations {
        uint128 repay;
        uint128 withdraw;
    }

    /* STACK AND RETURN STRUCTS */

    /// @notice Contains the data related to the liquidity of a user.
    struct LiquidityData {
        uint256 borrowable; // The maximum debt value allowed to borrow (in base currency).
        uint256 maxDebt; // The maximum debt value allowed before being liquidatable (in base currency).
        uint256 debt; // The debt value (in base currency).
    }

    /// @notice The paramaters used to compute the new peer-to-peer indexes.
    struct IndexesParams {
        MarketSideIndexes256 lastSupplyIndexes; // The last supply indexes stored (in ray).
        MarketSideIndexes256 lastBorrowIndexes; // The last borrow indexes stored (in ray).
        uint256 poolSupplyIndex; // The current pool supply index (in ray).
        uint256 poolBorrowIndex; // The current pool borrow index (in ray).
        uint256 reserveFactor; // The reserve factor percentage (10 000 = 100%).
        uint256 p2pIndexCursor; // The peer-to-peer index cursor (10 000 = 100%).
        Deltas deltas; // The deltas and peer-to-peer amounts.
        uint256 proportionIdle; // The amount of proportion idle (in underlying).
    }

    /// @notice Contains the data related to growth factors as part of the peer-to-peer indexes computation.
    struct GrowthFactors {
        uint256 poolSupplyGrowthFactor; // The pool's supply index growth factor (in ray).
        uint256 p2pSupplyGrowthFactor; // Peer-to-peer supply index growth factor (in ray).
        uint256 poolBorrowGrowthFactor; // The pool's borrow index growth factor (in ray).
        uint256 p2pBorrowGrowthFactor; // Peer-to-peer borrow index growth factor (in ray).
    }

    /// @notice Contains the market side indexes as uint256 instead of uint128.
    struct MarketSideIndexes256 {
        uint256 poolIndex; // The pool index (in ray).
        uint256 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the indexes as uint256 instead of uint128.
    struct Indexes256 {
        MarketSideIndexes256 supply; // The `MarketSideIndexes` related to the supply as uint256.
        MarketSideIndexes256 borrow; // The `MarketSideIndexes` related to the borrow as uint256.
    }

    /// @notice Contains the `v`, `r` and `s` parameters of an ECDSA signature.
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Variables used in the matching engine.
    struct MatchingEngineVars {
        address underlying; // The underlying asset address.
        MarketSideIndexes256 indexes; // The indexes of the market side.
        uint256 amount; // The amount to promote or demote (in underlying).
        uint256 maxIterations; // The maximum number of iterations allowed.
        bool borrow; // Whether the process happens on the borrow side or not.
        function (address, address, uint256, uint256, bool) returns (uint256, uint256) updateDS; // This function will be used to update the data-structure.
        bool demoting; // True for demote, False for promote.
        function(uint256, uint256, MarketSideIndexes256 memory, uint256)
            pure returns (uint256, uint256, uint256) step; // This function will be used to decide whether to use the algorithm for promoting or for demoting.
    }

    /// @notice Variables used in the liquidity computation process of a `user`.
    /// @dev Used to avoid stack too deep.
    struct LiquidityVars {
        address user; // The user address.
        IAaveOracle oracle; // The oracle used by Aave.
        DataTypes.EModeCategory eModeCategory; // The data related to the eMode category (could be empty if not in any e-mode).
    }

    /// @notice Variables used during a borrow or withdraw.
    /// @dev Used to avoid stack too deep.
    struct BorrowWithdrawVars {
        uint256 onPool; // The working scaled balance on pool of the user.
        uint256 inP2P; // The working scaled balance in peer-to-peer of the user.
        uint256 toWithdraw; // The amount to withdraw from the pool (in underlying).
        uint256 toBorrow; // The amount to borrow on the pool (in underlying).
    }

    /// @notice Variables used during a supply or repay.
    /// @dev Used to avoid stack too deep.
    struct SupplyRepayVars {
        uint256 onPool; // The working scaled balance on pool of the user.
        uint256 inP2P; // The working scaled balance in peer-to-peer of the user.
        uint256 toSupply; // The amount to supply on the pool (in underlying).
        uint256 toRepay; // The amount to repay on the pool (in underlying).
    }

    /// @notice Variables used during a liquidate.
    /// @dev Used to avoid stack too deep.
    struct LiquidateVars {
        uint256 closeFactor; // The close factor used during the liquidation process.
        uint256 seized; // The amount of collateral to be seized (in underlying).
    }

    /// @notice Variables used to compute the amount to seize during a liquidation.
    /// @dev Used to avoid stack too deep.
    struct AmountToSeizeVars {
        uint256 liquidationBonus; // The liquidation bonus used during the liquidation process.
        uint256 borrowedTokenUnit; // The borrowed token unit.
        uint256 collateralTokenUnit; // The collateral token unit.
        uint256 borrowedPrice; // The borrowed token price (in base currency).
        uint256 collateralPrice; // The collateral token price (in base currency).
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/// @title Errors
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library exposing errors used in Morpho.
library Errors {
    /// @notice Thrown when interacting with a market that is not created.
    error MarketNotCreated();

    /// @notice Thrown when creating a market that is already created.
    error MarketAlreadyCreated();

    /// @notice Thrown when creating a market that is not listed on Aave.
    error MarketIsNotListedOnAave();

    /// @notice Thrown when the market is in a siloed borrowing mode.
    error SiloedBorrowMarket();

    /// @notice Thrown when the market liquidation threshold is too low to be created.
    error MarketLtTooLow();

    /// @notice Thrown when the address used is the zero address.
    error AddressIsZero();

    /// @notice Thrown when the amount used is zero.
    error AmountIsZero();

    /// @notice Thrown when the user's debt is zero.
    error DebtIsZero();

    /// @notice Thrown when the user's supply is zero.
    error SupplyIsZero();

    /// @notice Thrown when the user's collateral is zero.
    error CollateralIsZero();

    /// @notice Thrown when the manager is not approved by the delegator.
    error PermissionDenied();

    /// @notice Thrown when supply is paused for the asset.
    error SupplyIsPaused();

    /// @notice Thrown when supply collateral is paused for the asset.
    error SupplyCollateralIsPaused();

    /// @notice Thrown when borrow is paused for the asset.
    error BorrowIsPaused();

    /// @notice Thrown when repay is paused for the asset.
    error RepayIsPaused();

    /// @notice Thrown when withdraw is paused for the asset.
    error WithdrawIsPaused();

    /// @notice Thrown when withdraw collateral is paused for the asset.
    error WithdrawCollateralIsPaused();

    /// @notice Thrown when liquidate is paused for the collateral asset.
    error LiquidateCollateralIsPaused();

    /// @notice Thrown when liquidate is paused for the borrow asset
    error LiquidateBorrowIsPaused();

    /// @notice Thrown when claim rewards is paused.
    error ClaimRewardsPaused();

    /// @notice Thrown when unpausing the borrow of a market that is deprecated.
    error MarketIsDeprecated();

    /// @notice Thrown when deprecating a market that is not paused.
    error BorrowNotPaused();

    /// @notice Thrown when the market is not enabled on Aave.
    error BorrowNotEnabled();

    /// @notice Thrown when the oracle sentinel is set and disables borrowing.
    error SentinelBorrowNotEnabled();

    /// @notice Thrown when borrowing an asset that is not in Morpho's e-mode category.
    error InconsistentEMode();

    /// @notice Thrown when a borrow would leave the user undercollateralized.
    error UnauthorizedBorrow();

    /// @notice Thrown when a withdraw would leave the user undercollateralized.
    error UnauthorizedWithdraw();

    /// @notice Thrown when the liquidatation is not authorized because of a collateralization ratio too high.
    error UnauthorizedLiquidate();

    /// @notice Thrown when the oracle sentinel is set and disables liquidating.
    error SentinelLiquidateNotEnabled();

    /// @notice Thrown when (un)setting a market as collateral on Morpho while it is not a collateral on Aave.
    error AssetNotCollateralOnPool();

    /// @notice Thrown when supplying an asset as collateral while it is not a collateral on Morpho.
    error AssetNotCollateralOnMorpho();

    /// @notice Thrown when (un)setting a market as collateral on Aave while it is a collateral on Morpho.
    error AssetIsCollateralOnMorpho();

    /// @notice Thrown when setting a market as collateral on Aave while the market is not created on Morpho.
    error SetAsCollateralOnPoolButMarketNotCreated();

    /// @notice Thrown when the value exceeds the maximum basis points value (100% = 10000).
    error ExceedsMaxBasisPoints();

    /// @notice Thrown when the s part of the ECDSA signature is invalid.
    error InvalidValueS();

    /// @notice Thrown when the v part of the ECDSA signature is invalid.
    error InvalidValueV();

    /// @notice Thrown when the signatory of the ECDSA signature is invalid.
    error InvalidSignatory();

    /// @notice Thrown when the nonce is invalid.
    error InvalidNonce();

    /// @notice Thrown when the signature is expired
    error SignatureExpired();

    /// @notice Thrown when the borrow cap on Aave is exceeded.
    error ExceedsBorrowCap();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Events
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library exposing events used in Morpho.
library Events {
    /// @notice Emitted when a supply happens.
    /// @param from The address of the user supplying the funds.
    /// @param onBehalf The address of the user on behalf of which the position is created.
    /// @param underlying The address of the underlying asset supplied.
    /// @param amount The amount of `underlying` asset supplied.
    /// @param scaledOnPool The scaled supply balance on pool of `onBehalf` after the supply.
    /// @param scaledInP2P The scaled supply balance in peer-to-peer of `onBehalf` after the supply.
    event Supplied(
        address indexed from,
        address indexed onBehalf,
        address indexed underlying,
        uint256 amount,
        uint256 scaledOnPool,
        uint256 scaledInP2P
    );

    /// @notice Emitted when a supply collateral happens.
    /// @param from The address of the user supplying the funds.
    /// @param onBehalf The address of the user on behalf of which the position is created.
    /// @param underlying The address of the underlying asset supplied.
    /// @param amount The amount of `underlying` asset supplied.
    /// @param scaledBalance The scaled collateral balance of `onBehalf` after the supply.
    event CollateralSupplied(
        address indexed from,
        address indexed onBehalf,
        address indexed underlying,
        uint256 amount,
        uint256 scaledBalance
    );

    /// @notice Emitted when a borrow happens.
    /// @param caller The address of the caller.
    /// @param onBehalf The address of the user on behalf of which the position is created.
    /// @param receiver The address of the user receiving the funds.
    /// @param underlying The address of the underlying asset borrowed.
    /// @param amount The amount of `underlying` asset borrowed.
    /// @param scaledOnPool The scaled borrow balance on pool of `onBehalf` after the borrow.
    /// @param scaledInP2P The scaled borrow balance in peer-to-peer of `onBehalf` after the borrow.
    event Borrowed(
        address caller,
        address indexed onBehalf,
        address indexed receiver,
        address indexed underlying,
        uint256 amount,
        uint256 scaledOnPool,
        uint256 scaledInP2P
    );

    /// @notice Emitted when a repay happens.
    /// @param repayer The address of the user repaying the debt.
    /// @param onBehalf The address of the user on behalf of which the position is modified.
    /// @param underlying The address of the underlying asset repaid.
    /// @param amount The amount of `underlying` asset repaid.
    /// @param scaledOnPool The scaled borrow balance on pool of `onBehalf` after the repay.
    /// @param scaledInP2P The scaled borrow balance in peer-to-peer of `onBehalf` after the repay.
    event Repaid(
        address indexed repayer,
        address indexed onBehalf,
        address indexed underlying,
        uint256 amount,
        uint256 scaledOnPool,
        uint256 scaledInP2P
    );

    /// @notice Emitted when a withdraw happens.
    /// @param caller The address of the caller.
    /// @param onBehalf The address of the user on behalf of which the position is modified.
    /// @param receiver The address of the user receiving the funds.
    /// @param underlying The address of the underlying asset withdrawn.
    /// @param amount The amount of `underlying` asset withdrawn.
    /// @param scaledOnPool The scaled supply balance on pool of `onBehalf` after the withdraw.
    /// @param scaledInP2P The scaled supply balance in peer-to-peer of `onBehalf` after the withdraw.
    event Withdrawn(
        address caller,
        address indexed onBehalf,
        address indexed receiver,
        address indexed underlying,
        uint256 amount,
        uint256 scaledOnPool,
        uint256 scaledInP2P
    );

    /// @notice Emitted when a withdraw collateral happens.
    /// @param caller The address of the caller.
    /// @param onBehalf The address of the user on behalf of which the position is modified.
    /// @param receiver The address of the user receiving the funds.
    /// @param underlying The address of the underlying asset withdrawn.
    /// @param amount The amount of `underlying` asset withdrawn.
    /// @param scaledBalance The scaled collateral balance of `onBehalf` after the withdraw.
    event CollateralWithdrawn(
        address caller,
        address indexed onBehalf,
        address indexed receiver,
        address indexed underlying,
        uint256 amount,
        uint256 scaledBalance
    );

    /// @notice Emitted when a liquidate happens.
    /// @param liquidator The address of the liquidator.
    /// @param borrower The address of the borrower that was liquidated.
    /// @param underlyingBorrowed The address of the underlying asset borrowed being repaid.
    /// @param amountLiquidated The amount of `underlyingBorrowed` repaid.
    /// @param underlyingCollateral The address of the collateral underlying seized.
    /// @param amountSeized The amount of `underlyingCollateral` seized.
    event Liquidated(
        address indexed liquidator,
        address indexed borrower,
        address indexed underlyingBorrowed,
        uint256 amountLiquidated,
        address underlyingCollateral,
        uint256 amountSeized
    );

    /// @notice Emitted when a `manager` is approved or unapproved to act on behalf of a `delegator`.
    event ManagerApproval(address indexed delegator, address indexed manager, bool isAllowed);

    /// @notice Emitted when a supply position is updated.
    /// @param user The address of the user.
    /// @param underlying The address of the underlying asset.
    /// @param scaledOnPool The scaled supply balance on pool of `user` after the update.
    /// @param scaledInP2P The scaled supply balance in peer-to-peer of `user` after the update.
    event SupplyPositionUpdated(
        address indexed user, address indexed underlying, uint256 scaledOnPool, uint256 scaledInP2P
    );

    /// @notice Emitted when a borrow position is updated.
    /// @param user The address of the user.
    /// @param underlying The address of the underlying asset.
    /// @param scaledOnPool The scaled borrow balance on pool of `user` after the update.
    /// @param scaledInP2P The scaled borrow balance in peer-to-peer of `user` after the update.
    event BorrowPositionUpdated(
        address indexed user, address indexed underlying, uint256 scaledOnPool, uint256 scaledInP2P
    );

    /// @notice Emitted when a peer-to-peer supply delta is updated.
    /// @param underlying The address of the underlying asset.
    /// @param scaledDelta The scaled supply delta of `underlying` asset.
    event P2PSupplyDeltaUpdated(address indexed underlying, uint256 scaledDelta);

    /// @notice Emitted when a peer-to-peer borrow delta is updated.
    /// @param underlying The address of the underlying asset.
    /// @param scaledDelta The scaled borrow delta of `underlying` asset.
    event P2PBorrowDeltaUpdated(address indexed underlying, uint256 scaledDelta);

    /// @notice Emitted when the peer-to-peer total amounts are updated.
    /// @param underlying The address of the underlying asset.
    /// @param scaledTotalSupplyP2P The scaled total supply of `underlying` asset in peer-to-peer.
    /// @param scaledTotalBorrowP2P The scaled total borrow of `underlying` asset in peer-to-peer.
    event P2PTotalsUpdated(address indexed underlying, uint256 scaledTotalSupplyP2P, uint256 scaledTotalBorrowP2P);

    /// @notice Emitted when a rewards are claimed.
    /// @param claimer The address of the user claiming the rewards.
    /// @param onBehalf The address of the user on behalf of which the rewards are claimed.
    /// @param rewardToken The address of the reward token claimed.
    /// @param amountClaimed The amount of `rewardToken` claimed.
    event RewardsClaimed(
        address indexed claimer, address indexed onBehalf, address indexed rewardToken, uint256 amountClaimed
    );

    /// @notice Emitted when the collateral status of the `underlying` market is set to `isCollateral`.
    event IsCollateralSet(address indexed underlying, bool isCollateral);

    /// @notice Emitted when the claim rewards status is set to `isPaused`.
    event IsClaimRewardsPausedSet(bool isPaused);

    /// @notice Emitted when the supply pause status of the `underlying` market is set to `isPaused`.
    event IsSupplyPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the supply collateral pause status of the `underlying` market is set to `isPaused`.
    event IsSupplyCollateralPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the borrow pause status of the `underlying` market is set to `isPaused`.
    event IsBorrowPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the withdraw pause status of the `underlying` market is set to `isPaused`.
    event IsWithdrawPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the withdraw collateral pause status of the `underlying` market is set to `isPaused`.
    event IsWithdrawCollateralPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the repay pause status of the `underlying` market is set to `isPaused`.
    event IsRepayPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the liquidate collateral pause status of the `underlying` market is set to `isPaused`.
    event IsLiquidateCollateralPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when the liquidate borrow pause status of the `underlying` market is set to `isPaused`.
    event IsLiquidateBorrowPausedSet(address indexed underlying, bool isPaused);

    /// @notice Emitted when an `_increaseP2PDeltas` is triggered.
    /// @param underlying The address of the underlying asset.
    /// @param amount The amount of the increases in `underlying` asset.
    event P2PDeltasIncreased(address indexed underlying, uint256 amount);

    /// @notice Emitted when a new market is created.
    /// @param underlying The address of the underlying asset of the new market.
    event MarketCreated(address indexed underlying);

    /// @notice Emitted when the default iterations are set.
    /// @param repay The default number of repay iterations.
    /// @param withdraw The default number of withdraw iterations.
    event DefaultIterationsSet(uint128 repay, uint128 withdraw);

    /// @notice Emitted when the positions manager is set.
    /// @param positionsManager The address of the positions manager.
    event PositionsManagerSet(address indexed positionsManager);

    /// @notice Emitted when the rewards manager is set.
    /// @param rewardsManager The address of the rewards manager.
    event RewardsManagerSet(address indexed rewardsManager);

    /// @notice Emitted when the treasury vault is set.
    /// @param treasuryVault The address of the treasury vault.
    event TreasuryVaultSet(address indexed treasuryVault);

    /// @notice Emitted when the reserve factor is set.
    /// @param underlying The address of the underlying asset.
    /// @param reserveFactor The reserve factor for this `underlying` asset.
    event ReserveFactorSet(address indexed underlying, uint16 reserveFactor);

    /// @notice Emitted when the peer-to-peer index cursor is set.
    /// @param underlying The address of the underlying asset.
    /// @param p2pIndexCursor The peer-to-peer index cursor for this `underlying` asset.
    event P2PIndexCursorSet(address indexed underlying, uint16 p2pIndexCursor);

    /// @notice Emitted when the peer-to-peer disabled status is set.
    /// @param underlying The address of the underlying asset.
    /// @param isP2PDisabled The peer-to-peer disabled status for this `underlying` asset.
    event IsP2PDisabledSet(address indexed underlying, bool isP2PDisabled);

    /// @notice Emitted when the deprecation status is set.
    /// @param underlying The address of the underlying asset.
    /// @param isDeprecated The deprecation status for this `underlying` asset.
    event IsDeprecatedSet(address indexed underlying, bool isDeprecated);

    /// @notice Emitted when the indexes are updated.
    /// @param underlying The address of the underlying asset.
    /// @param poolSupplyIndex The new pool supply index.
    /// @param p2pSupplyIndex The new peer-to-peer supply index.
    /// @param poolBorrowIndex The new pool borrow index.
    /// @param p2pBorrowIndex The new peer-to-peer borrow index.
    event IndexesUpdated(
        address indexed underlying,
        uint256 poolSupplyIndex,
        uint256 p2pSupplyIndex,
        uint256 poolBorrowIndex,
        uint256 p2pBorrowIndex
    );

    /// @notice Emitted when the idle supply is updated.
    /// @param underlying The address of the underlying asset.
    /// @param idleSupply The new idle supply.
    event IdleSupplyUpdated(address indexed underlying, uint256 idleSupply);

    /// @notice Emitted when the reserve fee is claimed.
    /// @param underlying The address of the underlying asset.
    /// @param claimed The amount of the claimed reserve fee.
    event ReserveFeeClaimed(address indexed underlying, uint256 claimed);

    /// @notice Emitted when a user nonce is incremented.
    /// @param caller The address of the caller.
    /// @param signatory The address of the signatory.
    /// @param usedNonce The used nonce.
    event UserNonceIncremented(address indexed caller, address indexed signatory, uint256 usedNonce);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IAToken} from "../interfaces/aave/IAToken.sol";
import {IPool} from "@aave-v3-core/interfaces/IPool.sol";
import {IVariableDebtToken} from "@aave-v3-core/interfaces/IVariableDebtToken.sol";

import {Constants} from "./Constants.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";

/// @title PoolLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease pool interactions.
library PoolLib {
    using WadRayMath for uint256;

    /// @notice Supplies `amount` of `underlying` to `pool`.
    /// @dev The pool supply `index` must be passed as a parameter to skip the supply on pool
    ///      if it were to revert due to the amount being too small.
    function supplyToPool(IPool pool, address underlying, uint256 amount, uint256 index) internal {
        if (amount.rayDiv(index) == 0) return;

        pool.supply(underlying, amount, address(this), Constants.NO_REFERRAL_CODE);
    }

    /// @notice Borrows `amount` of `underlying`from `pool`.
    function borrowFromPool(IPool pool, address underlying, uint256 amount) internal {
        if (amount == 0) return;

        pool.borrow(underlying, amount, Constants.VARIABLE_INTEREST_MODE, Constants.NO_REFERRAL_CODE, address(this));
    }

    /// @notice Repays `amount` of `underlying` to `pool`.
    /// @dev If the debt has been fully repaid already, the function will return early.
    function repayToPool(IPool pool, address underlying, address variableDebtToken, uint256 amount) internal {
        if (amount == 0 || IVariableDebtToken(variableDebtToken).scaledBalanceOf(address(this)) == 0) return;

        pool.repay(underlying, amount, Constants.VARIABLE_INTEREST_MODE, address(this)); // Reverts if debt is 0.
    }

    /// @notice Withdraws `amount` of `underlying` from `pool`.
    /// @dev If the amount is greater than the balance of the aToken, the function will withdraw the maximum possible.
    function withdrawFromPool(IPool pool, address underlying, address aToken, uint256 amount) internal {
        if (amount == 0) return;

        // Withdraw only what is possible. The remaining dust is taken from the contract balance.
        amount = Math.min(IAToken(aToken).balanceOf(address(this)), amount);
        pool.withdraw(underlying, amount, address(this));
    }

    /// @notice Returns the current pool indexes for `underlying` on the `pool`.
    /// @return poolSupplyIndex The current supply index of the pool (in ray).
    /// @return poolBorrowIndex The current borrow index of the pool (in ray).
    function getCurrentPoolIndexes(IPool pool, address underlying)
        internal
        view
        returns (uint256 poolSupplyIndex, uint256 poolBorrowIndex)
    {
        poolSupplyIndex = pool.getReserveNormalizedIncome(underlying);
        poolBorrowIndex = pool.getReserveNormalizedVariableDebt(underlying);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";

/// @title Constants
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library exposing constants used in Morpho.
library Constants {
    /// @dev The referral code used for Aave.
    uint8 internal constant NO_REFERRAL_CODE = 0;

    /// @dev The variable interest rate mode of Aave.
    uint8 internal constant VARIABLE_INTEREST_MODE = 2;

    /// @dev The threshold under which the balance is swept to 0.
    uint256 internal constant DUST_THRESHOLD = 1;

    /// @dev A lower bound on the liquidation threshold values of all the listed assets.
    uint256 internal constant LT_LOWER_BOUND = 10_00;

    /// @dev The maximum close factor used during liquidations (100%).
    uint256 internal constant MAX_CLOSE_FACTOR = PercentageMath.PERCENTAGE_FACTOR;

    /// @dev The default close factor used during liquidations (50%).
    uint256 internal constant DEFAULT_CLOSE_FACTOR = PercentageMath.HALF_PERCENTAGE_FACTOR;

    /// @dev Health factor below which the positions can be liquidated.
    uint256 internal constant DEFAULT_LIQUIDATION_MAX_HF = WadRayMath.WAD;

    /// @dev Health factor below which the positions can be liquidated, whether or not the price oracle sentinel allows the liquidation.
    uint256 internal constant DEFAULT_LIQUIDATION_MIN_HF = 0.95e18;

    /// @dev The prefix used for EIP-712 signature.
    string internal constant EIP712_MSG_PREFIX = "\x19\x01";

    /// @dev The name used for EIP-712 signature.
    string internal constant EIP712_NAME = "Morpho-AaveV3";

    /// @dev The version used for EIP-712 signature.
    string internal constant EIP712_VERSION = "0";

    /// @dev The domain typehash used for the EIP-712 signature.
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @dev The typehash for approveManagerWithSig Authorization used for the EIP-712 signature.
    bytes32 internal constant EIP712_AUTHORIZATION_TYPEHASH =
        keccak256("Authorization(address delegator,address manager,bool isAllowed,uint256 nonce,uint256 deadline)");

    /// @dev The highest valid value for s in an ECDSA signature pair (0 < s < secp256k1n ÷ 2 + 1).
    uint256 internal constant MAX_VALID_ECDSA_S = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Types} from "./Types.sol";

import {LogarithmicBuckets} from "@morpho-data-structures/LogarithmicBuckets.sol";

/// @title MarketBalanceLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease market balance reads.
library MarketBalanceLib {
    /// @notice Returns the scaled pool supply balance of `user` given the `marketBalances` of a specific market.
    function scaledPoolSupplyBalance(Types.MarketBalances storage marketBalances, address user)
        internal
        view
        returns (uint256)
    {
        return marketBalances.poolSuppliers.valueOf[user];
    }

    /// @notice Returns the scaled peer-to-peer supply balance of `user` given the `marketBalances` of a specific market.
    function scaledP2PSupplyBalance(Types.MarketBalances storage marketBalances, address user)
        internal
        view
        returns (uint256)
    {
        return marketBalances.p2pSuppliers.valueOf[user];
    }

    /// @notice Returns the scaled pool borrow balance of `user` given the `marketBalances` of a specific market.
    function scaledPoolBorrowBalance(Types.MarketBalances storage marketBalances, address user)
        internal
        view
        returns (uint256)
    {
        return marketBalances.poolBorrowers.valueOf[user];
    }

    /// @notice Returns the scaled peer-to-peer borrow balance of `user` given the `marketBalances` of a specific market.
    function scaledP2PBorrowBalance(Types.MarketBalances storage marketBalances, address user)
        internal
        view
        returns (uint256)
    {
        return marketBalances.p2pBorrowers.valueOf[user];
    }

    /// @notice Returns the scaled collateral balance of `user` given the `marketBalances` of a specific market.
    function scaledCollateralBalance(Types.MarketBalances storage marketBalances, address user)
        internal
        view
        returns (uint256)
    {
        return marketBalances.collateral[user];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns max(x - y, 0).
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns x / y rounded up (x / y + boolAsInt(x % y > 0)).
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Division by 0 if
        //    y = 0
        assembly {
            if iszero(y) { revert(0, 0) }

            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }

    /// @dev Returns the floor of log2(x) and returns 0 on input 0.
    /// @dev This computation makes use of De Bruijn sequences, their usage for computing log2 is referenced here: http://supertech.csail.mit.edu/papers/debruijn.pdf
    function log2(uint256 x) internal pure returns (uint256 y) {
        assembly {
            // Use the highest set bit of x to set each of its lower bits
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))
            x := or(x, shr(32, x))
            x := or(x, shr(64, x))
            x := or(x, shr(128, x))
            // Take only the highest bit of x
            x := xor(x, shr(1, x))

            // Hash table associating the first 256 powers of 2 to their log
            // Let x be a power of 2, its hash is obtained by taking the first byte of x * deBruijnSeq
            let m := mload(0x40)
            mstore(m, 0x0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a75)
            mstore(add(m, 0x20), 0x06264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9)
            mstore(add(m, 0x40), 0x071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee3)
            mstore(add(m, 0x60), 0x0e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7)
            mstore(add(m, 0x80), 0xff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c8)
            mstore(add(m, 0xa0), 0x16365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6)
            mstore(add(m, 0xc0), 0xfe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5)
            mstore(add(m, 0xe0), 0xfd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8)
            mstore(0x40, add(m, 0x100)) // Update the free memory pointer

            // This De Bruijn sequence begins with the byte 0, which is important to make shifting work like a rotation on the first byte
            let deBruijnSeq := 0x00818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let key := shr(248, mul(x, deBruijnSeq)) // With the multiplication it works also for 0
            y := shr(248, mload(add(m, key))) // Look in the table and take the first byte
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title PercentageMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    ///	CONSTANTS ///

    // Only direct number constants and references to such constants are supported by inline assembly.
    uint256 internal constant PERCENTAGE_FACTOR = 100_00;
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 50_00;
    uint256 internal constant PERCENTAGE_FACTOR_MINUS_ONE = 100_00 - 1;
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR = 2 ** 256 - 1 - 50_00;
    uint256 internal constant MAX_UINT256_MINUS_PERCENTAGE_FACTOR_MINUS_ONE = 2 ** 256 - 1 - (100_00 - 1);

    /// INTERNAL ///

    /// @notice Executes the bps-based percentage addition (x * (1 + p)), rounded half up.
    /// @param x The value to which to add the percentage.
    /// @param percentage The percentage of the value to add (in bps).
    /// @return y The result of the addition.
    function percentAdd(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // 1. Overflow if
        //        PERCENTAGE_FACTOR + percentage > type(uint256).max
        //    <=> percentage > type(uint256).max - PERCENTAGE_FACTOR
        // 2. Overflow if
        //        x * (PERCENTAGE_FACTOR + percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //    <=> x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR + percentage)
        assembly {
            y := add(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(
                gt(percentage, sub(MAX_UINT256, PERCENTAGE_FACTOR)),
                gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, y))
            ) { revert(0, 0) }

            y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes the bps-based percentage subtraction (x * (1 - p)), rounded half up.
    /// @param x The value to which to subtract the percentage.
    /// @param percentage The percentage of the value to subtract (in bps).
    /// @return y The result of the subtraction.
    function percentSub(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // 1. Underflow if
        //        percentage > PERCENTAGE_FACTOR
        // 2. Overflow if
        //        x * (PERCENTAGE_FACTOR - percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //    <=> (PERCENTAGE_FACTOR - percentage) > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR - percentage)
        assembly {
            y := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(gt(percentage, PERCENTAGE_FACTOR), mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, y)))) {
                revert(0, 0)
            }

            y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes the bps-based multiplication (x * p), rounded half up.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply (in bps).
    /// @return y The result of the multiplication.
    function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Overflow if
        //     x * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, percentage))) { revert(0, 0) }

            y := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes the bps-based multiplication (x * p), rounded down.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply.
    /// @return y The result of the multiplication.
    function percentMulDown(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Overflow if
        //     x * percentage > type(uint256).max
        // <=> percentage > 0 and x > type(uint256).max / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256, percentage))) { revert(0, 0) }

            y := div(mul(x, percentage), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes the bps-based multiplication (x * p), rounded up.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply.
    /// @return y The result of the multiplication.
    function percentMulUp(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Overflow if
        //     x * percentage + PERCENTAGE_FACTOR_MINUS_ONE > type(uint256).max
        // <=> percentage > 0 and x > (type(uint256).max - PERCENTAGE_FACTOR_MINUS_ONE) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_PERCENTAGE_FACTOR_MINUS_ONE, percentage))) { revert(0, 0) }

            y := div(add(mul(x, percentage), PERCENTAGE_FACTOR_MINUS_ONE), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes the bps-based division (x / p), rounded half up.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide (in bps).
    /// @return y The result of the division.
    function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // 1. Division by 0 if
        //        percentage == 0
        // 2. Overflow if
        //        x * PERCENTAGE_FACTOR + percentage / 2 > type(uint256).max
        //    <=> x > (type(uint256).max - percentage / 2) / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2) // Temporary assignment to save gas.

            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) { revert(0, 0) }

            y := div(add(mul(PERCENTAGE_FACTOR, x), y), percentage)
        }
    }

    /// @notice Executes the bps-based division (x / p), rounded down.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide.
    /// @return y The result of the division.
    function percentDivDown(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // 1. Division by 0 if
        //        percentage == 0
        // 2. Overflow if
        //        x * PERCENTAGE_FACTOR > type(uint256).max
        //    <=> x > type(uint256).max / PERCENTAGE_FACTOR
        assembly {
            if iszero(mul(percentage, lt(x, add(div(MAX_UINT256, PERCENTAGE_FACTOR), 1)))) { revert(0, 0) }

            y := div(mul(PERCENTAGE_FACTOR, x), percentage)
        }
    }

    /// @notice Executes the bps-based division (x / p), rounded up.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide.
    /// @return y The result of the division.
    function percentDivUp(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // 1. Division by 0 if
        //        percentage == 0
        // 2. Overflow if
        //        x * PERCENTAGE_FACTOR + (percentage - 1) > type(uint256).max
        //    <=> x > (type(uint256).max - (percentage - 1)) / PERCENTAGE_FACTOR
        assembly {
            y := sub(percentage, 1) // Temporary assignment to save gas.

            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) { revert(0, 0) }

            y := div(add(mul(PERCENTAGE_FACTOR, x), y), percentage)
        }
    }

    /// @notice Executes the bps-based weighted average (x * (1 - p) + y * p), rounded half up.
    /// @param x The first value, with a weight of 1 - percentage.
    /// @param y The second value, with a weight of percentage.
    /// @param percentage The weight of y, and complement of the weight of x (in bps).
    /// @return z The result of the bps-based weighted average.
    function weightedAvg(uint256 x, uint256 y, uint256 percentage) internal pure returns (uint256 z) {
        // 1. Underflow if
        //        percentage > PERCENTAGE_FACTOR
        // 2. Overflow if
        //        y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //    <=> percentage > 0 and y > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        // 3. Overflow if
        //        x * (PERCENTAGE_FACTOR - percentage) + y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //    <=> x * (PERCENTAGE_FACTOR - percentage) > type(uint256).max - HALF_PERCENTAGE_FACTOR - y * percentage
        //    <=> PERCENTAGE_FACTOR > percentage and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR - y * percentage) / (PERCENTAGE_FACTOR - percentage)
        assembly {
            z := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(
                gt(percentage, PERCENTAGE_FACTOR),
                or(
                    mul(percentage, gt(y, div(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, percentage))),
                    mul(z, gt(x, div(sub(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, mul(y, percentage)), z)))
                )
            ) { revert(0, 0) }

            z := div(add(add(mul(x, z), mul(y, percentage)), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {IDAIPermit} from "../interfaces/IDAIPermit.sol";
import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {SafeCast160} from "./SafeCast160.sol";

/// @title Permit2Lib
/// @notice Enables efficient transfers and EIP-2612/DAI
/// permits for any token by falling back to Permit2.
library Permit2Lib {
    using SafeCast160 for uint256;
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The unique EIP-712 domain domain separator for the DAI token contract.
    bytes32 internal constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    /// @dev The address for the WETH9 contract on Ethereum mainnet, encoded as a bytes32.
    bytes32 internal constant WETH9_ADDRESS = 0x000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;

    /// @dev The address of the Permit2 contract the library will use.
    IAllowanceTransfer internal constant PERMIT2 =
        IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

    /// @notice Transfer a given amount of tokens from one user to another.
    /// @param token The token to transfer.
    /// @param from The user to transfer from.
    /// @param to The user to transfer to.
    /// @param amount The amount to transfer.
    function transferFrom2(ERC20 token, address from, address to, uint256 amount) internal {
        // Generate calldata for a standard transferFrom call.
        bytes memory inputData = abi.encodeCall(ERC20.transferFrom, (from, to, amount));

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        assembly {
            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0), 1), iszero(returndatasize())),
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the first slot of scratch space.
                    call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 32)
                )
        }

        // We'll fall back to using Permit2 if calling transferFrom on the token directly reverted.
        if (!success) PERMIT2.transferFrom(from, to, amount.toUint160(), address(token));
    }

    /*//////////////////////////////////////////////////////////////
                              PERMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Permit a user to spend a given amount of
    /// another user's tokens via native EIP-2612 permit if possible, falling
    /// back to Permit2 if native permit fails or is not implemented on the token.
    /// @param token The token to permit spending.
    /// @param owner The user to permit spending from.
    /// @param spender The user to permit spending to.
    /// @param amount The amount to permit spending.
    /// @param deadline  The timestamp after which the signature is no longer valid.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Generate calldata for a call to DOMAIN_SEPARATOR on the token.
        bytes memory inputData = abi.encodeWithSelector(ERC20.DOMAIN_SEPARATOR.selector);

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        bytes32 domainSeparator; // If the call succeeded, we'll capture the return value here.

        assembly {
            // If the token is WETH9, we know it doesn't have a DOMAIN_SEPARATOR, and we'll skip this step.
            // We make sure to mask the token address as its higher order bits aren't guaranteed to be clean.
            if iszero(eq(and(token, 0xffffffffffffffffffffffffffffffffffffffff), WETH9_ADDRESS)) {
                success :=
                    and(
                        // Should resolve false if its not 32 bytes or its first word is 0.
                        and(iszero(iszero(mload(0))), eq(returndatasize(), 32)),
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the and() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        // We send a maximum of 5000 gas to prevent tokens with fallbacks from using a ton of gas.
                        // which should be plenty to allow tokens to fetch their DOMAIN_SEPARATOR from storage, etc.
                        staticcall(5000, token, add(inputData, 32), mload(inputData), 0, 32)
                    )

                domainSeparator := mload(0) // Copy the return value into the domainSeparator variable.
            }
        }

        // If the call to DOMAIN_SEPARATOR succeeded, try using permit on the token.
        if (success) {
            // We'll use DAI's special permit if it's DOMAIN_SEPARATOR matches,
            // otherwise we'll just encode a call to the standard permit function.
            inputData = domainSeparator == DAI_DOMAIN_SEPARATOR
                ? abi.encodeCall(IDAIPermit.permit, (owner, spender, token.nonces(owner), deadline, true, v, r, s))
                : abi.encodeCall(ERC20.permit, (owner, spender, amount, deadline, v, r, s));

            assembly {
                success := call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 0)
            }
        }

        if (!success) {
            // If the initial DOMAIN_SEPARATOR call on the token failed or a
            // subsequent call to permit failed, fall back to using Permit2.
            simplePermit2(token, owner, spender, amount, deadline, v, r, s);
        }
    }

    /// @notice Simple unlimited permit on the Permit2 contract.
    /// @param token The token to permit spending.
    /// @param owner The user to permit spending from.
    /// @param spender The user to permit spending to.
    /// @param amount The amount to permit spending.
    /// @param deadline  The timestamp after which the signature is no longer valid.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function simplePermit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        (,, uint48 nonce) = PERMIT2.allowance(owner, address(token), spender);

        PERMIT2.permit(
            owner,
            IAllowanceTransfer.PermitSingle({
                details: IAllowanceTransfer.PermitDetails({
                    token: address(token),
                    amount: amount.toUint160(),
                    // Use an unlimited expiration because it most
                    // closely mimics how a standard approval works.
                    expiration: type(uint48).max,
                    nonce: nonce
                }),
                spender: spender,
                sigDeadline: deadline
            }),
            bytes.concat(r, s, bytes1(v))
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IRewardsManager} from "./interfaces/IRewardsManager.sol";
import {IPool, IPoolAddressesProvider} from "@aave-v3-core/interfaces/IPool.sol";

import {Types} from "./libraries/Types.sol";
import {Constants} from "./libraries/Constants.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Initializable} from "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";

/// @title MorphoStorage
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice The storage shared by Morpho's contracts.
abstract contract MorphoStorage is Initializable, Ownable2StepUpgradeable {
    /* STORAGE */

    /// @dev The address of Aave's pool.
    IPool internal _pool;

    /// @dev The address of the pool addresses provider.
    IPoolAddressesProvider internal _addressesProvider;

    /// @dev The e-mode category of the deployed Morpho.
    uint8 internal _eModeCategoryId;

    /// @dev The list of created markets.
    address[] internal _marketsCreated;

    /// @dev The markets data.
    mapping(address => Types.Market) internal _market;

    /// @dev The markets balances data.
    mapping(address => Types.MarketBalances) internal _marketBalances;

    /// @dev The collateral markets entered by users.
    mapping(address => EnumerableSet.AddressSet) internal _userCollaterals;

    /// @dev The borrow markets entered by users.
    mapping(address => EnumerableSet.AddressSet) internal _userBorrows;

    /// @dev Users allowances to manage other users' accounts. delegator => manager => isManagedBy
    mapping(address => mapping(address => bool)) internal _isManagedBy;

    /// @dev The nonce of users. Used to prevent replay attacks with EIP-712 signatures.
    mapping(address => uint256) internal _userNonce;

    /// @dev The default number of iterations to use in the matching process.
    Types.Iterations internal _defaultIterations;

    /// @dev The address of the positions manager on which calls are delegated to.
    address internal _positionsManager;

    /// @dev The address of the rewards manager to track pool rewards for users.
    IRewardsManager internal _rewardsManager;

    /// @dev The address of the treasury vault, recipient of the reserve fee.
    address internal _treasuryVault;

    /// @dev Whether claiming rewards is paused or not.
    bool internal _isClaimRewardsPaused;

    /* CONSTRUCTOR */

    /// @notice Contract constructor.
    /// @dev The implementation contract disables initialization upon deployment to avoid being hijacked.
    constructor() {
        _disableInitializers();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IAaveOracle} from "@aave-v3-core/interfaces/IAaveOracle.sol";
import {IPriceOracleSentinel} from "@aave-v3-core/interfaces/IPriceOracleSentinel.sol";

import {Types} from "./libraries/Types.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";
import {Constants} from "./libraries/Constants.sol";
import {MarketLib} from "./libraries/MarketLib.sol";
import {DeltasLib} from "./libraries/DeltasLib.sol";
import {MarketSideDeltaLib} from "./libraries/MarketSideDeltaLib.sol";
import {MarketBalanceLib} from "./libraries/MarketBalanceLib.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";

import {LogarithmicBuckets} from "@morpho-data-structures/LogarithmicBuckets.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {DataTypes} from "@aave-v3-core/protocol/libraries/types/DataTypes.sol";
import {UserConfiguration} from "@aave-v3-core/protocol/libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "@aave-v3-core/protocol/libraries/configuration/ReserveConfiguration.sol";

import {ERC20} from "@solmate/tokens/ERC20.sol";

import {MatchingEngine} from "./MatchingEngine.sol";

/// @title PositionsManagerInternal
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Abstract contract defining `PositionsManager`'s internal functions.
abstract contract PositionsManagerInternal is MatchingEngine {
    using MarketLib for Types.Market;
    using DeltasLib for Types.Deltas;
    using MarketBalanceLib for Types.MarketBalances;
    using MarketSideDeltaLib for Types.MarketSideDelta;

    using Math for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /// @dev Validates the manager's permission.
    function _validatePermission(address delegator, address manager) internal view {
        if (!(delegator == manager || _isManagedBy[delegator][manager])) revert Errors.PermissionDenied();
    }

    /// @dev Validates the input.
    function _validateInput(address underlying, uint256 amount, address user)
        internal
        view
        returns (Types.Market storage market)
    {
        if (user == address(0)) revert Errors.AddressIsZero();
        if (amount == 0) revert Errors.AmountIsZero();

        market = _market[underlying];
        if (!market.isCreated()) revert Errors.MarketNotCreated();
    }

    /// @dev Validates the manager's permission and the input.
    function _validateManagerInput(address underlying, uint256 amount, address onBehalf, address receiver)
        internal
        view
        returns (Types.Market storage market)
    {
        if (receiver == address(0)) revert Errors.AddressIsZero();

        market = _validateInput(underlying, amount, onBehalf);

        _validatePermission(onBehalf, msg.sender);
    }

    /// @dev Validates a supply action.
    function _validateSupply(address underlying, uint256 amount, address user)
        internal
        view
        returns (Types.Market storage market)
    {
        market = _validateInput(underlying, amount, user);
        if (market.isSupplyPaused()) revert Errors.SupplyIsPaused();
    }

    /// @dev Validates a supply collateral action.
    function _validateSupplyCollateral(address underlying, uint256 amount, address user) internal view {
        Types.Market storage market = _validateInput(underlying, amount, user);
        if (market.isSupplyCollateralPaused()) revert Errors.SupplyCollateralIsPaused();
        if (!market.isCollateral) revert Errors.AssetNotCollateralOnMorpho();
    }

    /// @dev Validates a borrow action.
    function _validateBorrow(address underlying, uint256 amount, address borrower, address receiver)
        internal
        view
        returns (Types.Market storage market)
    {
        market = _validateManagerInput(underlying, amount, borrower, receiver);
        if (market.isBorrowPaused()) revert Errors.BorrowIsPaused();
    }

    /// @dev Authorizes a borrow action.
    function _authorizeBorrow(address underlying, uint256 amount, Types.Indexes256 memory indexes) internal view {
        DataTypes.ReserveConfigurationMap memory config = _pool.getConfiguration(underlying);
        if (!config.getBorrowingEnabled()) revert Errors.BorrowNotEnabled();

        address priceOracleSentinel = _addressesProvider.getPriceOracleSentinel();
        if (priceOracleSentinel != address(0) && !IPriceOracleSentinel(priceOracleSentinel).isBorrowAllowed()) {
            revert Errors.SentinelBorrowNotEnabled();
        }

        if (_eModeCategoryId != 0 && _eModeCategoryId != config.getEModeCategory()) {
            revert Errors.InconsistentEMode();
        }

        if (config.getBorrowCap() != 0) {
            Types.Market storage market = _market[underlying];

            uint256 trueP2PBorrow = market.trueP2PBorrow(indexes);
            uint256 borrowCap = config.getBorrowCap() * (10 ** config.getDecimals());
            uint256 poolDebt =
                ERC20(market.variableDebtToken).totalSupply() + ERC20(market.stableDebtToken).totalSupply();

            if (amount + trueP2PBorrow + poolDebt > borrowCap) revert Errors.ExceedsBorrowCap();
        }
    }

    /// @dev Validates a repay action.
    function _validateRepay(address underlying, uint256 amount, address user)
        internal
        view
        returns (Types.Market storage market)
    {
        market = _validateInput(underlying, amount, user);
        if (market.isRepayPaused()) revert Errors.RepayIsPaused();
    }

    /// @dev Validates a withdraw action.
    function _validateWithdraw(address underlying, uint256 amount, address supplier, address receiver)
        internal
        view
        returns (Types.Market storage market)
    {
        market = _validateManagerInput(underlying, amount, supplier, receiver);
        if (market.isWithdrawPaused()) revert Errors.WithdrawIsPaused();
    }

    /// @dev Validates a withdraw collateral action.
    function _validateWithdrawCollateral(address underlying, uint256 amount, address supplier, address receiver)
        internal
        view
        returns (Types.Market storage market)
    {
        market = _validateManagerInput(underlying, amount, supplier, receiver);
        if (market.isWithdrawCollateralPaused()) revert Errors.WithdrawCollateralIsPaused();
    }

    /// @dev Validates a liquidate action.
    function _validateLiquidate(address underlyingBorrowed, address underlyingCollateral, address borrower)
        internal
        view
    {
        Types.Market storage borrowMarket = _market[underlyingBorrowed];
        Types.Market storage collateralMarket = _market[underlyingCollateral];

        if (borrower == address(0)) revert Errors.AddressIsZero();

        if (!borrowMarket.isCreated() || !collateralMarket.isCreated()) revert Errors.MarketNotCreated();
        if (collateralMarket.isLiquidateCollateralPaused()) revert Errors.LiquidateCollateralIsPaused();
        if (borrowMarket.isLiquidateBorrowPaused()) revert Errors.LiquidateBorrowIsPaused();
    }

    /// @dev Authorizes a liquidate action.
    function _authorizeLiquidate(address underlyingBorrowed, address borrower) internal view returns (uint256) {
        if (_market[underlyingBorrowed].isDeprecated()) return Constants.MAX_CLOSE_FACTOR; // Allow liquidation of the whole debt.

        uint256 healthFactor = _getUserHealthFactor(borrower);
        if (healthFactor >= Constants.DEFAULT_LIQUIDATION_MAX_HF) {
            revert Errors.UnauthorizedLiquidate();
        }

        if (healthFactor >= Constants.DEFAULT_LIQUIDATION_MIN_HF) {
            address priceOracleSentinel = _addressesProvider.getPriceOracleSentinel();

            if (priceOracleSentinel != address(0) && !IPriceOracleSentinel(priceOracleSentinel).isLiquidationAllowed())
            {
                revert Errors.SentinelLiquidateNotEnabled();
            }
        }

        if (healthFactor > Constants.DEFAULT_LIQUIDATION_MIN_HF) return Constants.DEFAULT_CLOSE_FACTOR;

        return Constants.MAX_CLOSE_FACTOR;
    }

    /// @dev Performs the accounting of a supply action.
    function _accountSupply(
        address underlying,
        uint256 amount,
        address onBehalf,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.SupplyRepayVars memory vars) {
        Types.Market storage market = _market[underlying];
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];
        vars.onPool = marketBalances.scaledPoolSupplyBalance(onBehalf);
        vars.inP2P = marketBalances.scaledP2PSupplyBalance(onBehalf);

        /* Peer-to-peer supply */

        if (!market.isP2PDisabled()) {
            // Decrease the peer-to-peer borrow delta.
            (amount, vars.toRepay) =
                market.deltas.borrow.decreaseDelta(underlying, amount, indexes.borrow.poolIndex, true);

            // Promote pool borrowers.
            uint256 promoted;
            (amount, promoted,) = _promoteRoutine(underlying, amount, maxIterations, _promoteBorrowers);
            vars.toRepay += promoted;

            // Update the peer-to-peer totals.
            vars.inP2P += market.deltas.increaseP2P(underlying, promoted, vars.toRepay, indexes, true);
        }

        /* Pool supply */

        // Supply on pool.
        (vars.toSupply, vars.onPool) = _addToPool(amount, vars.onPool, indexes.supply.poolIndex);

        (vars.onPool, vars.inP2P) = _updateSupplierInDS(underlying, onBehalf, vars.onPool, vars.inP2P, false);
    }

    /// @dev Performs the accounting of a borrow action.
    ///      Note: the borrower's set of borrowed market is updated in `_updateBorrowerInDS`.
    function _accountBorrow(
        address underlying,
        uint256 amount,
        address borrower,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.BorrowWithdrawVars memory vars) {
        Types.Market storage market = _market[underlying];
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];
        vars.onPool = marketBalances.scaledPoolBorrowBalance(borrower);
        vars.inP2P = marketBalances.scaledP2PBorrowBalance(borrower);

        /* Peer-to-peer borrow */

        if (!market.isP2PDisabled()) {
            // Decrease the peer-to-peer idle supply.
            uint256 matchedIdle;
            (amount, matchedIdle) = market.decreaseIdle(underlying, amount);

            // Decrease the peer-to-peer supply delta.
            (amount, vars.toWithdraw) =
                market.deltas.supply.decreaseDelta(underlying, amount, indexes.supply.poolIndex, false);

            // Promote pool suppliers.
            uint256 promoted;
            (amount, promoted,) = _promoteRoutine(underlying, amount, maxIterations, _promoteSuppliers);
            vars.toWithdraw += promoted;

            // Update the peer-to-peer totals.
            vars.inP2P += market.deltas.increaseP2P(underlying, promoted, vars.toWithdraw + matchedIdle, indexes, false);
        }

        /* Pool borrow */

        // Borrow on pool.
        (vars.toBorrow, vars.onPool) = _addToPool(amount, vars.onPool, indexes.borrow.poolIndex);

        (vars.onPool, vars.inP2P) = _updateBorrowerInDS(underlying, borrower, vars.onPool, vars.inP2P, false);
    }

    /// @dev Performs the accounting of a repay action.
    ///      Note: the borrower's set of borrowed market is updated in `_updateBorrowerInDS`.
    function _accountRepay(
        address underlying,
        uint256 amount,
        address onBehalf,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.SupplyRepayVars memory vars) {
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];
        vars.onPool = marketBalances.scaledPoolBorrowBalance(onBehalf);
        vars.inP2P = marketBalances.scaledP2PBorrowBalance(onBehalf);

        /* Pool repay */

        // Repay borrow on pool.
        (amount, vars.toRepay, vars.onPool) = _subFromPool(amount, vars.onPool, indexes.borrow.poolIndex);

        // Repay borrow peer-to-peer.
        vars.inP2P = vars.inP2P.zeroFloorSub(amount.rayDivUp(indexes.borrow.p2pIndex)); // In peer-to-peer borrow unit.

        (vars.onPool, vars.inP2P) = _updateBorrowerInDS(underlying, onBehalf, vars.onPool, vars.inP2P, false);

        // Returning early requires having updated the borrower in the data structure, which in turn requires having updated `inP2P`.
        if (amount == 0) return vars;

        Types.Market storage market = _market[underlying];

        // Decrease the peer-to-peer borrow delta.
        uint256 matchedBorrowDelta;
        (amount, matchedBorrowDelta) =
            market.deltas.borrow.decreaseDelta(underlying, amount, indexes.borrow.poolIndex, true);
        vars.toRepay += matchedBorrowDelta;

        // Updates the P2P total for the repay fee calculation. Events are emitted in the decreaseP2P step.
        market.deltas.borrow.scaledP2PTotal =
            market.deltas.borrow.scaledP2PTotal.zeroFloorSub(matchedBorrowDelta.rayDiv(indexes.borrow.p2pIndex));

        // Repay the fee.
        amount = market.repayFee(amount, indexes);

        /* Transfer repay */

        if (!market.isP2PDisabled()) {
            // Promote pool borrowers.
            uint256 promoted;
            (amount, promoted, maxIterations) = _promoteRoutine(underlying, amount, maxIterations, _promoteBorrowers);
            vars.toRepay += promoted;
        }

        /* Breaking repay */

        // Handle the supply cap.
        uint256 idleSupplyIncrease;
        (vars.toSupply, idleSupplyIncrease) =
            market.increaseIdle(underlying, amount, _pool.getReserveData(underlying), indexes);

        // Demote peer-to-peer suppliers.
        uint256 demoted = _demoteSuppliers(underlying, vars.toSupply, maxIterations);

        // Increase the peer-to-peer supply delta.
        market.deltas.supply.increaseDelta(underlying, vars.toSupply - demoted, indexes.supply, false);

        // Update the peer-to-peer totals.
        market.deltas.decreaseP2P(underlying, demoted, vars.toSupply + idleSupplyIncrease, indexes, false);
    }

    /// @dev Performs the accounting of a withdraw action.
    function _accountWithdraw(
        address underlying,
        uint256 amount,
        address supplier,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.BorrowWithdrawVars memory vars) {
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];
        vars.onPool = marketBalances.scaledPoolSupplyBalance(supplier);
        vars.inP2P = marketBalances.scaledP2PSupplyBalance(supplier);

        /* Pool withdraw */

        // Withdraw supply on pool.
        (amount, vars.toWithdraw, vars.onPool) = _subFromPool(amount, vars.onPool, indexes.supply.poolIndex);

        Types.Market storage market = _market[underlying];

        // Withdraw supply peer-to-peer.
        vars.inP2P = vars.inP2P.zeroFloorSub(amount.rayDivUp(indexes.supply.p2pIndex)); // In peer-to-peer supply unit.

        (vars.onPool, vars.inP2P) = _updateSupplierInDS(underlying, supplier, vars.onPool, vars.inP2P, false);

        // Returning early requires having updated the supplier in the data structure, which in turn requires having updated `inP2P`.
        if (amount == 0) return vars;

        // Decrease the peer-to-peer idle supply.
        uint256 matchedIdle;
        (amount, matchedIdle) = market.decreaseIdle(underlying, amount);

        // Decrease the peer-to-peer supply delta.
        uint256 toWithdrawStep;
        (amount, toWithdrawStep) =
            market.deltas.supply.decreaseDelta(underlying, amount, indexes.supply.poolIndex, false);
        vars.toWithdraw += toWithdrawStep;
        uint256 p2pTotalSupplyDecrease = toWithdrawStep + matchedIdle;

        /* Transfer withdraw */

        if (!market.isP2PDisabled()) {
            // Promote pool suppliers.
            (vars.toBorrow, toWithdrawStep, maxIterations) =
                _promoteRoutine(underlying, amount, maxIterations, _promoteSuppliers);
            vars.toWithdraw += toWithdrawStep;
        } else {
            vars.toBorrow = amount;
        }

        /* Breaking withdraw */

        // Demote peer-to-peer borrowers.
        uint256 demoted = _demoteBorrowers(underlying, vars.toBorrow, maxIterations);

        // Increase the peer-to-peer borrow delta.
        market.deltas.borrow.increaseDelta(underlying, vars.toBorrow - demoted, indexes.borrow, true);

        // Update the peer-to-peer totals.
        market.deltas.decreaseP2P(underlying, demoted, vars.toBorrow + p2pTotalSupplyDecrease, indexes, true);
    }

    /// @dev Performs the accounting of a supply action.
    function _accountSupplyCollateral(address underlying, uint256 amount, address onBehalf, uint256 poolSupplyIndex)
        internal
        returns (uint256 collateralBalance)
    {
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];

        collateralBalance = marketBalances.collateral[onBehalf];

        _updateRewards(onBehalf, _market[underlying].aToken, collateralBalance);

        collateralBalance += amount.rayDivDown(poolSupplyIndex);

        marketBalances.collateral[onBehalf] = collateralBalance;

        _userCollaterals[onBehalf].add(underlying);
    }

    /// @dev Performs the accounting of a withdraw collateral action.
    function _accountWithdrawCollateral(address underlying, uint256 amount, address onBehalf, uint256 poolSupplyIndex)
        internal
        returns (uint256 collateralBalance)
    {
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];

        collateralBalance = marketBalances.collateral[onBehalf];

        _updateRewards(onBehalf, _market[underlying].aToken, collateralBalance);

        collateralBalance = collateralBalance.zeroFloorSub(amount.rayDivUp(poolSupplyIndex));

        marketBalances.collateral[onBehalf] = collateralBalance;

        if (collateralBalance == 0) _userCollaterals[onBehalf].remove(underlying);
    }

    /// @dev Executes a supply action.
    function _executeSupply(
        address underlying,
        uint256 amount,
        address from,
        address onBehalf,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.SupplyRepayVars memory vars) {
        vars = _accountSupply(underlying, amount, onBehalf, maxIterations, indexes);

        emit Events.Supplied(from, onBehalf, underlying, amount, vars.onPool, vars.inP2P);
    }

    /// @dev Executes a borrow action.
    function _executeBorrow(
        address underlying,
        uint256 amount,
        address onBehalf,
        address receiver,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.BorrowWithdrawVars memory vars) {
        vars = _accountBorrow(underlying, amount, onBehalf, maxIterations, indexes);

        emit Events.Borrowed(msg.sender, onBehalf, receiver, underlying, amount, vars.onPool, vars.inP2P);
    }

    /// @dev Executes a repay action.
    function _executeRepay(
        address underlying,
        uint256 amount,
        address repayer,
        address onBehalf,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.SupplyRepayVars memory vars) {
        vars = _accountRepay(underlying, amount, onBehalf, maxIterations, indexes);

        emit Events.Repaid(repayer, onBehalf, underlying, amount, vars.onPool, vars.inP2P);
    }

    /// @dev Executes a withdraw action.
    function _executeWithdraw(
        address underlying,
        uint256 amount,
        address onBehalf,
        address receiver,
        uint256 maxIterations,
        Types.Indexes256 memory indexes
    ) internal returns (Types.BorrowWithdrawVars memory vars) {
        vars = _accountWithdraw(underlying, amount, onBehalf, maxIterations, indexes);

        emit Events.Withdrawn(msg.sender, onBehalf, receiver, underlying, amount, vars.onPool, vars.inP2P);
    }

    /// @dev Executes a supply collateral action.
    function _executeSupplyCollateral(
        address underlying,
        uint256 amount,
        address from,
        address onBehalf,
        uint256 poolSupplyIndex
    ) internal {
        uint256 collateralBalance = _accountSupplyCollateral(underlying, amount, onBehalf, poolSupplyIndex);

        emit Events.CollateralSupplied(from, onBehalf, underlying, amount, collateralBalance);
    }

    /// @dev Executes a withdraw collateral action.
    function _executeWithdrawCollateral(
        address underlying,
        uint256 amount,
        address onBehalf,
        address receiver,
        uint256 poolSupplyIndex
    ) internal {
        uint256 collateralBalance = _accountWithdrawCollateral(underlying, amount, onBehalf, poolSupplyIndex);

        emit Events.CollateralWithdrawn(msg.sender, onBehalf, receiver, underlying, amount, collateralBalance);
    }

    /// @notice Given variables from a market side, calculates the amount to supply/borrow and a new on pool amount.
    /// @param amount The amount to supply/borrow.
    /// @param onPool The current user's scaled on pool balance.
    /// @param poolIndex The current pool index.
    /// @return The amount to supply/borrow and the new on pool amount.
    function _addToPool(uint256 amount, uint256 onPool, uint256 poolIndex) internal pure returns (uint256, uint256) {
        if (amount == 0) return (0, onPool);

        return (
            amount,
            onPool + amount.rayDivDown(poolIndex) // In scaled balance.
        );
    }

    /// @notice Given variables from a market side, calculates the amount to repay/withdraw, the amount left to process, and a new on pool amount.
    /// @param amount The amount to repay/withdraw.
    /// @param onPool The current user's scaled on pool balance.
    /// @param poolIndex The current pool index.
    /// @return The amount left to process, the amount to repay/withdraw, and the new on pool amount.
    function _subFromPool(uint256 amount, uint256 onPool, uint256 poolIndex)
        internal
        pure
        returns (uint256, uint256, uint256)
    {
        if (onPool == 0) return (amount, 0, onPool);

        uint256 toProcess = Math.min(onPool.rayMul(poolIndex), amount);

        return (
            amount - toProcess,
            toProcess,
            onPool.zeroFloorSub(toProcess.rayDivUp(poolIndex)) // In scaled balance.
        );
    }

    /// @notice Given variables from a market side, promotes users and calculates the amount to repay/withdraw from promote,
    ///         the amount left to process, and the number of iterations left.
    /// @param underlying The underlying address.
    /// @param amount The amount to supply/borrow.
    /// @param maxIterations The maximum number of iterations to run.
    /// @param promote The promote function.
    /// @return The amount left to process, the amount to repay/withdraw from promote, and the number of iterations left.
    function _promoteRoutine(
        address underlying,
        uint256 amount,
        uint256 maxIterations,
        function(address, uint256, uint256) returns (uint256, uint256) promote
    ) internal returns (uint256, uint256, uint256) {
        if (amount == 0) return (amount, 0, maxIterations);

        (uint256 promoted, uint256 iterationsDone) = promote(underlying, amount, maxIterations); // In underlying.

        return (amount - promoted, promoted, maxIterations - iterationsDone);
    }

    /// @dev Calculates the amount to seize during a liquidation process.
    /// @param underlyingBorrowed The address of the underlying borrowed asset.
    /// @param underlyingCollateral The address of the underlying collateral asset.
    /// @param maxToRepay The maximum amount of `underlyingBorrowed` to repay.
    /// @param borrower The address of the borrower being liquidated.
    /// @param poolSupplyIndex The current pool supply index of the `underlyingCollateral` market.
    /// @return amountToRepay The amount of `underlyingBorrowed` to repay.
    /// @return amountToSeize The amount of `underlyingCollateral` to seize.
    function _calculateAmountToSeize(
        address underlyingBorrowed,
        address underlyingCollateral,
        uint256 maxToRepay,
        address borrower,
        uint256 poolSupplyIndex
    ) internal view returns (uint256 amountToRepay, uint256 amountToSeize) {
        Types.AmountToSeizeVars memory vars;

        DataTypes.EModeCategory memory eModeCategory;
        if (_eModeCategoryId != 0) eModeCategory = _pool.getEModeCategoryData(_eModeCategoryId);

        bool collateralIsInEMode;
        IAaveOracle oracle = IAaveOracle(_addressesProvider.getPriceOracle());
        DataTypes.ReserveConfigurationMap memory borrowedConfig = _pool.getConfiguration(underlyingBorrowed);
        DataTypes.ReserveConfigurationMap memory collateralConfig = _pool.getConfiguration(underlyingCollateral);

        (, vars.borrowedPrice, vars.borrowedTokenUnit) =
            _assetData(underlyingBorrowed, oracle, borrowedConfig, eModeCategory.priceSource);
        (collateralIsInEMode, vars.collateralPrice, vars.collateralTokenUnit) =
            _assetData(underlyingCollateral, oracle, collateralConfig, eModeCategory.priceSource);

        vars.liquidationBonus =
            collateralIsInEMode ? eModeCategory.liquidationBonus : collateralConfig.getLiquidationBonus();

        amountToRepay = maxToRepay;
        amountToSeize = (
            (amountToRepay * vars.borrowedPrice * vars.collateralTokenUnit)
                / (vars.borrowedTokenUnit * vars.collateralPrice)
        ).percentMul(vars.liquidationBonus);

        uint256 collateralBalance = _getUserCollateralBalanceFromIndex(underlyingCollateral, borrower, poolSupplyIndex);

        if (amountToSeize > collateralBalance) {
            amountToSeize = collateralBalance;
            amountToRepay = (
                (collateralBalance * vars.collateralPrice * vars.borrowedTokenUnit)
                    / (vars.borrowedPrice * vars.collateralTokenUnit)
            ).percentDiv(vars.liquidationBonus);
        }
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./BucketDLL.sol";

/// @title LogarithmicBuckets
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice The logarithmic buckets data-structure.
library LogarithmicBuckets {
    using BucketDLL for BucketDLL.List;

    struct Buckets {
        mapping(uint256 => BucketDLL.List) buckets;
        mapping(address => uint256) valueOf;
        uint256 bucketsMask;
    }

    /* ERRORS */

    /// @notice Thrown when the address is zero at insertion.
    error ZeroAddress();

    /// @notice Thrown when 0 value is inserted.
    error ZeroValue();

    /* INTERNAL */

    /// @notice Updates an account in the `buckets`.
    /// @param buckets The buckets to update.
    /// @param id The address of the account.
    /// @param newValue The new value of the account.
    /// @param head Indicates whether to insert the new values at the head or at the tail of the buckets list.
    function update(
        Buckets storage buckets,
        address id,
        uint256 newValue,
        bool head
    ) internal {
        if (id == address(0)) revert ZeroAddress();
        uint256 value = buckets.valueOf[id];
        buckets.valueOf[id] = newValue;

        if (value == 0) {
            if (newValue == 0) revert ZeroValue();
            // `highestSetBit` is used to compute the bucket associated with `newValue`.
            _insert(buckets, id, highestSetBit(newValue), head);
            return;
        }

        // `highestSetBit` is used to compute the bucket associated with `value`.
        uint256 currentBucket = highestSetBit(value);
        if (newValue == 0) {
            _remove(buckets, id, currentBucket);
            return;
        }

        // `highestSetBit` is used to compute the bucket associated with `newValue`.
        uint256 newBucket = highestSetBit(newValue);
        if (newBucket != currentBucket) {
            _remove(buckets, id, currentBucket);
            _insert(buckets, id, newBucket, head);
        }
    }

    /// @notice Returns the address in `buckets` that is a candidate for matching the value `value`.
    /// @param buckets The buckets to get the head.
    /// @param value The value to match.
    /// @return The address of the head.
    function getMatch(Buckets storage buckets, uint256 value) internal view returns (address) {
        uint256 bucketsMask = buckets.bucketsMask;
        if (bucketsMask == 0) return address(0);

        uint256 next = nextBucket(value, bucketsMask);
        if (next != 0) return buckets.buckets[next].getNext(address(0));

        // `highestSetBit` is used to compute the highest non-empty bucket.
        // Knowing that `next` == 0, it is also the highest previous non-empty bucket.
        uint256 prev = highestSetBit(bucketsMask);
        return buckets.buckets[prev].getNext(address(0));
    }

    /* PRIVATE */

    /// @notice Removes an account in the `buckets`.
    /// @dev Does not update the value.
    /// @param buckets The buckets to modify.
    /// @param id The address of the account to remove.
    /// @param bucket The mask of the bucket where to remove.
    function _remove(
        Buckets storage buckets,
        address id,
        uint256 bucket
    ) private {
        if (buckets.buckets[bucket].remove(id)) buckets.bucketsMask &= ~bucket;
    }

    /// @notice Inserts an account in the `buckets`.
    /// @dev Expects that `id` != 0.
    /// @dev Does not update the value.
    /// @param buckets The buckets to modify.
    /// @param id The address of the account to update.
    /// @param bucket The mask of the bucket where to insert.
    /// @param head Whether to insert at the head or at the tail of the list.
    function _insert(
        Buckets storage buckets,
        address id,
        uint256 bucket,
        bool head
    ) private {
        if (buckets.buckets[bucket].insert(id, head)) buckets.bucketsMask |= bucket;
    }

    /* PURE HELPERS */

    /// @notice Returns the highest set bit.
    /// @dev Used to compute the bucket associated to a given `value`.
    /// @dev Used to compute the highest non empty bucket given the `bucketsMask`.
    function highestSetBit(uint256 value) internal pure returns (uint256) {
        uint256 lowerMask = setLowerBits(value);
        return lowerMask ^ (lowerMask >> 1);
    }

    /// @notice Sets all the bits lower than (or equal to) the highest bit in the input.
    /// @dev This is the same as rounding the input the nearest upper value of the form `2 ** n - 1`.
    function setLowerBits(uint256 x) internal pure returns (uint256 y) {
        assembly {
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))
            x := or(x, shr(32, x))
            x := or(x, shr(64, x))
            y := or(x, shr(128, x))
        }
    }

    /// @notice Returns the lowest non-empty bucket containing larger values.
    /// @dev The bucket returned is the lowest that is in `bucketsMask` and not in `lowerMask`.
    function nextBucket(uint256 value, uint256 bucketsMask) internal pure returns (uint256 bucket) {
        uint256 lowerMask = setLowerBits(value);
        assembly {
            let higherBucketsMask := and(not(lowerMask), bucketsMask)
            bucket := and(higherBucketsMask, add(not(higherBucketsMask), 1))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IScaledBalanceToken} from "@aave-v3-core/interfaces/IScaledBalanceToken.sol";
import {IInitializableAToken} from "@aave-v3-core/interfaces/IInitializableAToken.sol";

/**
 * @title IAToken
 * @author Aave
 * @notice Defines the basic interface for an AToken.
 * @dev Aave's IAToken inherit IERC20 from OZ, using pragma 0.8.10. This interface is copied to enable compilation using a different pragma.
 */
interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The scaled amount being transferred
     * @param index The next liquidity index of the reserve
     */
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @notice Mints `amount` aTokens to `user`
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted aTokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address caller, address onBehalfOf, uint256 amount, uint256 index) external returns (bool);

    /**
     * @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the aTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The next liquidity index of the reserve
     */
    function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) external;

    /**
     * @notice Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     */
    function transferOnLiquidation(address from, address to, uint256 value) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the underlying
     * @param amount The amount getting transferred
     */
    function transferUnderlyingTo(address target, uint256 amount) external;

    /**
     * @notice Handles the underlying received by the aToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param onBehalfOf The address of the user who will get his debt reduced/removed
     * @param amount The amount getting repaid
     */
    function handleRepayment(address user, address onBehalfOf, uint256 amount) external;

    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /**
     * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
     * @return Address of the Aave treasury
     */
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the nonce for owner.
     * @param owner The address of the owner
     * @return The nonce of the owner
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableDebtToken} from './IInitializableDebtToken.sol';

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 */
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
  /**
   * @notice Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return True if the previous balance of the user is 0, false otherwise
   * @return The scaled total debt of the reserve
   */
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool, uint256);

  /**
   * @notice Burns user variable debt
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the debt will be burned
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   * @return The scaled total debt of the reserve
   */
  function burn(
    address from,
    uint256 amount,
    uint256 index
  ) external returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title WadRayMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library WadRayMath to conduct wad and ray manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/WadRayMath.sol
library WadRayMath {
    /// CONSTANTS ///

    // Only direct number constants and references to such constants are supported by inline assembly.
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;
    uint256 internal constant WAD_MINUS_ONE = 1e18 - 1;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;
    uint256 internal constant RAY_MINUS_ONE = 1e27 - 1;
    uint256 internal constant RAY_WAD_RATIO = 1e9;
    uint256 internal constant HALF_RAY_WAD_RATIO = 0.5e9;
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_WAD = 2 ** 256 - 1 - 0.5e18;
    uint256 internal constant MAX_UINT256_MINUS_HALF_RAY = 2 ** 256 - 1 - 0.5e27;
    uint256 internal constant MAX_UINT256_MINUS_WAD_MINUS_ONE = 2 ** 256 - 1 - (1e18 - 1);
    uint256 internal constant MAX_UINT256_MINUS_RAY_MINUS_ONE = 2 ** 256 - 1 - (1e27 - 1);

    /// INTERNAL ///

    /// @dev Executes the wad-based multiplication of 2 numbers, rounded half up.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x * y, in wad.
    function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y + HALF_WAD > type(uint256).max
        // <=> x * y > type(uint256).max - HALF_WAD
        // <=> y > 0 and x > (type(uint256).max - HALF_WAD) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_WAD, y))) { revert(0, 0) }

            z := div(add(mul(x, y), HALF_WAD), WAD)
        }
    }

    /// @dev Executes the wad-based multiplication of 2 numbers, rounded down.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x * y, in wad.
    function wadMulDown(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y > type(uint256).max
        // <=> y > 0 and x > type(uint256).max / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256, y))) { revert(0, 0) }

            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Executes the wad-based multiplication of 2 numbers, rounded up.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x * y, in wad.
    function wadMulUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y + WAD_MINUS_ONE > type(uint256).max
        // <=> x * y > type(uint256).max - WAD_MINUS_ONE
        // <=> y > 0 and x > (type(uint256).max - WAD_MINUS_ONE) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_WAD_MINUS_ONE, y))) { revert(0, 0) }

            z := div(add(mul(x, y), WAD_MINUS_ONE), WAD)
        }
    }

    /// @dev Executes wad-based division of 2 numbers, rounded half up.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in wad.
    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * WAD + y / 2 > type(uint256).max
        //    <=> x * WAD > type(uint256).max - y / 2
        //    <=> x > (type(uint256).max - y / 2) / WAD
        assembly {
            z := div(y, 2) // Temporary assignment to save gas.

            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), WAD))))) { revert(0, 0) }

            z := div(add(mul(WAD, x), z), y)
        }
    }

    /// @dev Executes wad-based division of 2 numbers, rounded down.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in wad.
    function wadDivDown(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * WAD > type(uint256).max
        //    <=> x > type(uint256).max / WAD
        assembly {
            if iszero(mul(y, lt(x, add(div(MAX_UINT256, WAD), 1)))) { revert(0, 0) }

            z := div(mul(WAD, x), y)
        }
    }

    /// @dev Executes wad-based division of 2 numbers, rounded up.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in wad.
    function wadDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * WAD + (y - 1) > type(uint256).max
        //    <=> x * WAD > type(uint256).max - (y - 1)
        //    <=> x > (type(uint256).max - (y - 1)) / WAD
        assembly {
            z := sub(y, 1) // Temporary assignment to save gas.

            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), WAD))))) { revert(0, 0) }

            z := div(add(mul(WAD, x), z), y)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded half up.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x * y, in ray.
    function rayMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y + HALF_RAY > type(uint256).max
        // <=> x * y > type(uint256).max - HALF_RAY
        // <=> y > 0 and x > (type(uint256).max - HALF_RAY) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_RAY, y))) { revert(0, 0) }

            z := div(add(mul(x, y), HALF_RAY), RAY)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded down.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x * y, in ray.
    function rayMulDown(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y > type(uint256).max
        // <=> y > 0 and x > type(uint256).max / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256, y))) { revert(0, 0) }

            z := div(mul(x, y), RAY)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded up.
    /// @param x Ray.
    /// @param y Wad.
    /// @return z The result of x * y, in ray.
    function rayMulUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y + RAY_MINUS_ONE > type(uint256).max
        // <=> x * y > type(uint256).max - RAY_MINUS_ONE
        // <=> y > 0 and x > (type(uint256).max - RAY_MINUS_ONE) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_RAY_MINUS_ONE, y))) { revert(0, 0) }

            z := div(add(mul(x, y), RAY_MINUS_ONE), RAY)
        }
    }

    /// @dev Executes the ray-based division of 2 numbers, rounded half up.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x / y, in ray.
    function rayDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * RAY + y / 2 > type(uint256).max
        //    <=> x * RAY > type(uint256).max - y / 2
        //    <=> x > (type(uint256).max - y / 2) / RAY
        assembly {
            z := div(y, 2) // Temporary assignment to save gas.

            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), RAY))))) { revert(0, 0) }

            z := div(add(mul(RAY, x), z), y)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded down.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in ray.
    function rayDivDown(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * RAY > type(uint256).max
        //    <=> x > type(uint256).max / RAY
        assembly {
            if iszero(mul(y, lt(x, add(div(MAX_UINT256, RAY), 1)))) { revert(0, 0) }

            z := div(mul(RAY, x), y)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded up.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in ray.
    function rayDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * RAY + (y - 1) > type(uint256).max
        //    <=> x * RAY > type(uint256).max - (y - 1)
        //    <=> x > (type(uint256).max - (y - 1)) / RAY
        assembly {
            z := sub(y, 1) // Temporary assignment to save gas.

            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), RAY))))) { revert(0, 0) }

            z := div(add(mul(RAY, x), z), y)
        }
    }

    /// @dev Converts ray down to wad.
    /// @param x Ray.
    /// @return y = x converted to wad, rounded half up to the nearest wad.
    function rayToWad(uint256 x) internal pure returns (uint256 y) {
        assembly {
            // If x % RAY_WAD_RATIO >= HALF_RAY_WAD_RATIO, round up.
            y := add(div(x, RAY_WAD_RATIO), iszero(lt(mod(x, RAY_WAD_RATIO), HALF_RAY_WAD_RATIO)))
        }
    }

    /// @dev Converts wad up to ray.
    /// @param x Wad.
    /// @return y = x converted in ray.
    function wadToRay(uint256 x) internal pure returns (uint256 y) {
        // Overflow if
        //     x * RAY_WAD_RATIO > type(uint256).max
        // <=> x > type(uint256).max / RAY_WAD_RATIO
        assembly {
            if gt(x, div(MAX_UINT256, RAY_WAD_RATIO)) { revert(0, 0) }

            y := mul(x, RAY_WAD_RATIO)
        }
    }

    /// @notice Computes the wad-based weighted average (x * (1 - weight) + y * weight), rounded half up.
    /// @param x The first value, with a weight of 1 - weight.
    /// @param y The second value, with a weight of weight.
    /// @param weight The weight of y, and complement of the weight of x (in wad).
    /// @return z The result of the wad-based weighted average.
    function wadWeightedAvg(uint256 x, uint256 y, uint256 weight) internal pure returns (uint256 z) {
        // 1. Underflow if
        //        weight > WAD
        // 2. Overflow if
        //        y * weight + HALF_WAD > type(uint256).max
        //    <=> weight > 0 and y > (type(uint256).max - HALF_WAD) / weight
        // 3. Overflow if
        //        x * (WAD - weight) + y * weight + HALF_WAD > type(uint256).max
        //    <=> x * (WAD - weight) > type(uint256).max - HALF_WAD - y * weight
        //    <=> WAD > weight and x > (type(uint256).max - HALF_WAD - y * weight) / (WAD - weight)
        assembly {
            z := sub(WAD, weight) // Temporary assignment to save gas.

            if or(
                gt(weight, WAD),
                or(
                    mul(weight, gt(y, div(MAX_UINT256_MINUS_HALF_WAD, weight))),
                    mul(z, gt(x, div(sub(MAX_UINT256_MINUS_HALF_WAD, mul(y, weight)), z)))
                )
            ) { revert(0, 0) }

            z := div(add(add(mul(x, z), mul(y, weight)), HALF_WAD), WAD)
        }
    }

    /// @notice Computes the ray-based weighted average (x * (1 - weight) + y * weight), rounded half up.
    /// @param x The first value, with a weight of 1 - weight.
    /// @param y The second value, with a weight of weight.
    /// @param weight The weight of y, and complement of the weight of x (in ray).
    /// @return z The result of the ray-based weighted average.
    function rayWeightedAvg(uint256 x, uint256 y, uint256 weight) internal pure returns (uint256 z) {
        // 1. Underflow if
        //        weight > RAY
        // 2. Overflow if
        //        y * weight + HALF_RAY > type(uint256).max
        //    <=> weight > 0 and y > (type(uint256).max - HALF_RAY) / weight
        // 3. Overflow if
        //        x * (RAY - weight) + y * weight + HALF_RAY > type(uint256).max
        //    <=> x * (RAY - weight) > type(uint256).max - HALF_RAY - y * weight
        //    <=> RAY > weight and x > (type(uint256).max - HALF_RAY - y * weight) / (RAY - weight)
        assembly {
            z := sub(RAY, weight) // Temporary assignment to save gas.

            if or(
                gt(weight, RAY),
                or(
                    mul(weight, gt(y, div(MAX_UINT256_MINUS_HALF_RAY, weight))),
                    mul(z, gt(x, div(sub(MAX_UINT256_MINUS_HALF_RAY, mul(y, weight)), z)))
                )
            ) { revert(0, 0) }

            z := div(add(add(mul(x, z), mul(y, weight)), HALF_RAY), RAY)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDAIPermit {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeCast160 {
    /// @notice Thrown when a valude greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface IRewardsManager {
    function MORPHO() external view returns (address);
    function REWARDS_CONTROLLER() external view returns (address);

    function getRewardData(address asset, address reward)
        external
        view
        returns (uint256 startingIndex, uint256 index, uint256 lastUpdateTimestamp);
    function getUserData(address asset, address reward, address user)
        external
        view
        returns (uint256 index, uint256 accrued);

    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (address[] memory rewardsList, uint256[] memory unclaimedAmounts);
    function getUserRewards(address[] calldata assets, address user, address reward) external view returns (uint256);
    function getUserAccruedRewards(address[] calldata assets, address user, address reward)
        external
        view
        returns (uint256 totalAccrued);
    function getUserAssetIndex(address user, address asset, address reward) external view returns (uint256);
    function getAssetIndex(address asset, address reward) external view returns (uint256 assetIndex);

    function claimRewards(address[] calldata assets, address user)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
    function updateUserRewards(address user, address asset, uint256 userBalance) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IPriceOracleSentinel
 * @author Aave
 * @notice Defines the basic interface for the PriceOracleSentinel
 */
interface IPriceOracleSentinel {
  /**
   * @dev Emitted after the sequencer oracle is updated
   * @param newSequencerOracle The new sequencer oracle
   */
  event SequencerOracleUpdated(address newSequencerOracle);

  /**
   * @dev Emitted after the grace period is updated
   * @param newGracePeriod The new grace period value
   */
  event GracePeriodUpdated(uint256 newGracePeriod);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns true if the `borrow` operation is allowed.
   * @dev Operation not allowed when PriceOracle is down or grace period not passed.
   * @return True if the `borrow` operation is allowed, false otherwise.
   */
  function isBorrowAllowed() external view returns (bool);

  /**
   * @notice Returns true if the `liquidation` operation is allowed.
   * @dev Operation not allowed when PriceOracle is down or grace period not passed.
   * @return True if the `liquidation` operation is allowed, false otherwise.
   */
  function isLiquidationAllowed() external view returns (bool);

  /**
   * @notice Updates the address of the sequencer oracle
   * @param newSequencerOracle The address of the new Sequencer Oracle to use
   */
  function setSequencerOracle(address newSequencerOracle) external;

  /**
   * @notice Updates the duration of the grace period
   * @param newGracePeriod The value of the new grace period duration
   */
  function setGracePeriod(uint256 newGracePeriod) external;

  /**
   * @notice Returns the SequencerOracle
   * @return The address of the sequencer oracle contract
   */
  function getSequencerOracle() external view returns (address);

  /**
   * @notice Returns the grace period
   * @return The duration of the grace period
   */
  function getGracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IAToken} from "../interfaces/aave/IAToken.sol";
import {IPool} from "@aave-v3-core/interfaces/IPool.sol";

import {Types} from "./Types.sol";
import {Events} from "./Events.sol";
import {Errors} from "./Errors.sol";
import {ReserveDataLib} from "./ReserveDataLib.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {DataTypes} from "@aave-v3-core/protocol/libraries/types/DataTypes.sol";
import {ReserveConfiguration} from "@aave-v3-core/protocol/libraries/configuration/ReserveConfiguration.sol";

/// @title MarketLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease market reads and writes.
library MarketLib {
    using Math for uint256;
    using SafeCast for uint256;
    using WadRayMath for uint256;
    using MarketLib for Types.Market;
    using ReserveDataLib for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /// @notice Returns whether the `market` is created or not.
    function isCreated(Types.Market storage market) internal view returns (bool) {
        return market.aToken != address(0);
    }

    /// @notice Returns whether supply is paused on `market` or not.
    function isSupplyPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isSupplyPaused;
    }

    /// @notice Returns whether supply collateral is paused on `market` or not.
    function isSupplyCollateralPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isSupplyCollateralPaused;
    }

    /// @notice Returns whether borrow is paused on `market` or not.
    function isBorrowPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isBorrowPaused;
    }

    /// @notice Returns whether repay is paused on `market` or not.
    function isRepayPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isRepayPaused;
    }

    /// @notice Returns whether withdraw is paused on `market` or not.
    function isWithdrawPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isWithdrawPaused;
    }

    /// @notice Returns whether withdraw collateral is paused on `market` or not.
    function isWithdrawCollateralPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isWithdrawCollateralPaused;
    }

    /// @notice Returns whether liquidate collateral is paused on `market` or not.
    function isLiquidateCollateralPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isLiquidateCollateralPaused;
    }

    /// @notice Returns whether liquidate borrow is paused on `market` or not.
    function isLiquidateBorrowPaused(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isLiquidateBorrowPaused;
    }

    /// @notice Returns whether the `market` is deprecated or not.
    function isDeprecated(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isDeprecated;
    }

    /// @notice Returns whether the peer-to-peer is disabled on `market` or not.
    function isP2PDisabled(Types.Market storage market) internal view returns (bool) {
        return market.pauseStatuses.isP2PDisabled;
    }

    /// @notice Sets the `market` as `isCollateral` on Morpho.
    function setAssetIsCollateral(Types.Market storage market, bool isCollateral) internal {
        market.isCollateral = isCollateral;

        emit Events.IsCollateralSet(market.underlying, isCollateral);
    }

    /// @notice Sets the `market` supply pause status as `isPaused` on Morpho.
    function setIsSupplyPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isSupplyPaused = isPaused;

        emit Events.IsSupplyPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` supply collateral pause status as `isPaused` on Morpho.
    function setIsSupplyCollateralPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isSupplyCollateralPaused = isPaused;

        emit Events.IsSupplyCollateralPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` borrow pause status as `isPaused` on Morpho.
    function setIsBorrowPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isBorrowPaused = isPaused;

        emit Events.IsBorrowPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` repay pause status as `isPaused` on Morpho.
    function setIsRepayPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isRepayPaused = isPaused;

        emit Events.IsRepayPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` withdraw pause status as `isPaused` on Morpho.
    function setIsWithdrawPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isWithdrawPaused = isPaused;

        emit Events.IsWithdrawPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` withdraw collateral pause status as `isPaused` on Morpho.
    function setIsWithdrawCollateralPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isWithdrawCollateralPaused = isPaused;

        emit Events.IsWithdrawCollateralPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` liquidate collateral pause status as `isPaused` on Morpho.
    function setIsLiquidateCollateralPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isLiquidateCollateralPaused = isPaused;

        emit Events.IsLiquidateCollateralPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` liquidate borrow pause status as `isPaused` on Morpho.
    function setIsLiquidateBorrowPaused(Types.Market storage market, bool isPaused) internal {
        market.pauseStatuses.isLiquidateBorrowPaused = isPaused;

        emit Events.IsLiquidateBorrowPausedSet(market.underlying, isPaused);
    }

    /// @notice Sets the `market` as `deprecated` on Morpho.
    function setIsDeprecated(Types.Market storage market, bool deprecated) internal {
        market.pauseStatuses.isDeprecated = deprecated;

        emit Events.IsDeprecatedSet(market.underlying, deprecated);
    }

    /// @notice Sets the `market` peer-to-peer as `p2pDisabled` on Morpho.
    function setIsP2PDisabled(Types.Market storage market, bool p2pDisabled) internal {
        market.pauseStatuses.isP2PDisabled = p2pDisabled;

        emit Events.IsP2PDisabledSet(market.underlying, p2pDisabled);
    }

    /// @notice Sets the `market` peer-to-peer reserve factor to `reserveFactor`.
    function setReserveFactor(Types.Market storage market, uint16 reserveFactor) internal {
        if (reserveFactor > PercentageMath.PERCENTAGE_FACTOR) revert Errors.ExceedsMaxBasisPoints();
        market.reserveFactor = reserveFactor;

        emit Events.ReserveFactorSet(market.underlying, reserveFactor);
    }

    /// @notice Sets the `market` peer-to-peer index cursor to `p2pIndexCursor`.
    function setP2PIndexCursor(Types.Market storage market, uint16 p2pIndexCursor) internal {
        if (p2pIndexCursor > PercentageMath.PERCENTAGE_FACTOR) revert Errors.ExceedsMaxBasisPoints();
        market.p2pIndexCursor = p2pIndexCursor;

        emit Events.P2PIndexCursorSet(market.underlying, p2pIndexCursor);
    }

    /// @notice Sets the `market` indexes to `indexes`.
    function setIndexes(Types.Market storage market, Types.Indexes256 memory indexes) internal {
        market.indexes.supply.poolIndex = indexes.supply.poolIndex.toUint128();
        market.indexes.supply.p2pIndex = indexes.supply.p2pIndex.toUint128();
        market.indexes.borrow.poolIndex = indexes.borrow.poolIndex.toUint128();
        market.indexes.borrow.p2pIndex = indexes.borrow.p2pIndex.toUint128();
        market.lastUpdateTimestamp = uint32(block.timestamp);
        emit Events.IndexesUpdated(
            market.underlying,
            indexes.supply.poolIndex,
            indexes.supply.p2pIndex,
            indexes.borrow.poolIndex,
            indexes.borrow.p2pIndex
        );
    }

    /// @notice Returns the supply indexes of `market`.
    function getSupplyIndexes(Types.Market storage market)
        internal
        view
        returns (Types.MarketSideIndexes256 memory supplyIndexes)
    {
        supplyIndexes.poolIndex = uint256(market.indexes.supply.poolIndex);
        supplyIndexes.p2pIndex = uint256(market.indexes.supply.p2pIndex);
    }

    /// @notice Returns the borrow indexes of `market`.
    function getBorrowIndexes(Types.Market storage market)
        internal
        view
        returns (Types.MarketSideIndexes256 memory borrowIndexes)
    {
        borrowIndexes.poolIndex = uint256(market.indexes.borrow.poolIndex);
        borrowIndexes.p2pIndex = uint256(market.indexes.borrow.p2pIndex);
    }

    /// @notice Returns the indexes of `market`.
    function getIndexes(Types.Market storage market) internal view returns (Types.Indexes256 memory indexes) {
        indexes.supply = getSupplyIndexes(market);
        indexes.borrow = getBorrowIndexes(market);
    }

    /// @notice Returns the proportion of idle supply in `market` over the total peer-to-peer amount in supply.
    function getProportionIdle(Types.Market storage market) internal view returns (uint256) {
        uint256 idleSupply = market.idleSupply;
        if (idleSupply == 0) return 0;

        uint256 totalP2PSupplied = market.deltas.supply.scaledP2PTotal.rayMul(market.indexes.supply.p2pIndex);
        if (totalP2PSupplied == 0) return 0;

        // We take the minimum to handle the case where the proportion is rounded to greater than 1.
        return Math.min(idleSupply.rayDivUp(totalP2PSupplied), WadRayMath.RAY);
    }

    /// @notice Increases the idle supply if the supply cap is reached in a breaking repay, and returns a new toSupply amount.
    /// @param market The market storage.
    /// @param underlying The underlying address.
    /// @param amount The amount to repay. (by supplying on pool)
    /// @param reserve The reserve data for the market.
    /// @return The amount to supply to stay below the supply cap and the amount the idle supply was increased by.
    function increaseIdle(
        Types.Market storage market,
        address underlying,
        uint256 amount,
        DataTypes.ReserveData memory reserve,
        Types.Indexes256 memory indexes
    ) internal returns (uint256, uint256) {
        uint256 supplyCap = reserve.configuration.getSupplyCap() * (10 ** reserve.configuration.getDecimals());
        if (supplyCap == 0) return (amount, 0);

        uint256 suppliable = supplyCap.zeroFloorSub(
            (IAToken(market.aToken).scaledTotalSupply() + reserve.getAccruedToTreasury(indexes)).rayMul(
                indexes.supply.poolIndex
            )
        );
        if (amount <= suppliable) return (amount, 0);

        uint256 idleSupplyIncrease = amount - suppliable;
        uint256 newIdleSupply = market.idleSupply + idleSupplyIncrease;

        market.idleSupply = newIdleSupply;

        emit Events.IdleSupplyUpdated(underlying, newIdleSupply);

        return (suppliable, idleSupplyIncrease);
    }

    /// @notice Decreases the idle supply.
    /// @param market The market storage.
    /// @param underlying The underlying address.
    /// @param amount The amount to borrow.
    /// @return The amount left to process and the processed amount.
    function decreaseIdle(Types.Market storage market, address underlying, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        if (amount == 0) return (0, 0);

        uint256 idleSupply = market.idleSupply;
        if (idleSupply == 0) return (amount, 0);

        uint256 matchedIdle = Math.min(idleSupply, amount); // In underlying.
        uint256 newIdleSupply = idleSupply.zeroFloorSub(matchedIdle);
        market.idleSupply = newIdleSupply;

        emit Events.IdleSupplyUpdated(underlying, newIdleSupply);

        return (amount - matchedIdle, matchedIdle);
    }

    /// @notice Calculates the total quantity of underlyings truly supplied peer-to-peer on the given market.
    /// @param indexes The current indexes.
    /// @return The total peer-to-peer supply (total peer-to-peer supply - supply delta - idle supply).
    function trueP2PSupply(Types.Market storage market, Types.Indexes256 memory indexes)
        internal
        view
        returns (uint256)
    {
        Types.MarketSideDelta storage supplyDelta = market.deltas.supply;
        return supplyDelta.scaledP2PTotal.rayMul(indexes.supply.p2pIndex).zeroFloorSub(
            supplyDelta.scaledDelta.rayMul(indexes.supply.poolIndex)
        ).zeroFloorSub(market.idleSupply);
    }

    /// @notice Calculates the total quantity of underlyings truly borrowed peer-to-peer on the given market.
    /// @param indexes The current indexes.
    /// @return The total peer-to-peer borrow (total peer-to-peer borrow - borrow delta).
    function trueP2PBorrow(Types.Market storage market, Types.Indexes256 memory indexes)
        internal
        view
        returns (uint256)
    {
        Types.MarketSideDelta storage borrowDelta = market.deltas.borrow;
        return borrowDelta.scaledP2PTotal.rayMul(indexes.borrow.p2pIndex).zeroFloorSub(
            borrowDelta.scaledDelta.rayMul(indexes.borrow.poolIndex)
        );
    }

    /// @notice Calculates & deducts the reserve fee to repay from the given amount, updating the total peer-to-peer amount.
    /// @param amount The amount to repay (in underlying).
    /// @param indexes The current indexes.
    /// @return The new amount left to process (in underlying).
    function repayFee(Types.Market storage market, uint256 amount, Types.Indexes256 memory indexes)
        internal
        returns (uint256)
    {
        if (amount == 0) return 0;

        Types.Deltas storage deltas = market.deltas;
        uint256 feeToRepay = Math.min(amount, market.trueP2PBorrow(indexes).zeroFloorSub(market.trueP2PSupply(indexes)));

        if (feeToRepay == 0) return amount;

        deltas.borrow.scaledP2PTotal =
            deltas.borrow.scaledP2PTotal.zeroFloorSub(feeToRepay.rayDivDown(indexes.borrow.p2pIndex)); // P2PTotalsUpdated emitted in `decreaseP2P`.

        return amount - feeToRepay;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Types} from "./Types.sol";
import {Events} from "./Events.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";

/// @title DeltasLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease delta reads and writes.
library DeltasLib {
    using Math for uint256;
    using WadRayMath for uint256;

    /// @notice Increases the peer-to-peer amounts following a promotion.
    /// @param deltas The market deltas to update.
    /// @param underlying The underlying address.
    /// @param promoted The amount to increase the promoted side peer-to-peer total (in underlying). Must be lower than or equal to amount.
    /// @param amount The amount to increase the opposite side peer-to-peer total (in underlying).
    /// @param indexes The current indexes.
    /// @param borrowSide True if this follows borrower promotions. False for supplier promotions.
    /// @return p2pBalanceIncrease The scaled balance amount in peer-to-peer to increase.
    function increaseP2P(
        Types.Deltas storage deltas,
        address underlying,
        uint256 promoted,
        uint256 amount,
        Types.Indexes256 memory indexes,
        bool borrowSide
    ) internal returns (uint256 p2pBalanceIncrease) {
        if (amount == 0) return 0; // promoted == 0 is not checked since promoted <= amount.

        Types.MarketSideDelta storage promotedDelta = borrowSide ? deltas.borrow : deltas.supply;
        Types.MarketSideDelta storage counterDelta = borrowSide ? deltas.supply : deltas.borrow;
        Types.MarketSideIndexes256 memory promotedIndexes = borrowSide ? indexes.borrow : indexes.supply;
        Types.MarketSideIndexes256 memory counterIndexes = borrowSide ? indexes.supply : indexes.borrow;

        p2pBalanceIncrease = amount.rayDiv(counterIndexes.p2pIndex);
        promotedDelta.scaledP2PTotal += promoted.rayDiv(promotedIndexes.p2pIndex);
        counterDelta.scaledP2PTotal += p2pBalanceIncrease;

        emit Events.P2PTotalsUpdated(underlying, deltas.supply.scaledP2PTotal, deltas.borrow.scaledP2PTotal);
    }

    /// @notice Decreases the peer-to-peer amounts following a demotion.
    /// @param deltas The market deltas to update.
    /// @param underlying The underlying address.
    /// @param demoted The amount to decrease the demoted side peer-to-peer total (in underlying). Must be lower than or equal to amount.
    /// @param amount The amount to decrease the opposite side peer-to-peer total (in underlying).
    /// @param indexes The current indexes.
    /// @param borrowSide True if this follows borrower demotions. False for supplier demotions.
    function decreaseP2P(
        Types.Deltas storage deltas,
        address underlying,
        uint256 demoted,
        uint256 amount,
        Types.Indexes256 memory indexes,
        bool borrowSide
    ) internal {
        if (amount == 0) return; // demoted == 0 is not checked since demoted <= amount.

        Types.MarketSideDelta storage demotedDelta = borrowSide ? deltas.borrow : deltas.supply;
        Types.MarketSideDelta storage counterDelta = borrowSide ? deltas.supply : deltas.borrow;
        Types.MarketSideIndexes256 memory demotedIndexes = borrowSide ? indexes.borrow : indexes.supply;
        Types.MarketSideIndexes256 memory counterIndexes = borrowSide ? indexes.supply : indexes.borrow;

        demotedDelta.scaledP2PTotal = demotedDelta.scaledP2PTotal.zeroFloorSub(demoted.rayDiv(demotedIndexes.p2pIndex));
        counterDelta.scaledP2PTotal = counterDelta.scaledP2PTotal.zeroFloorSub(amount.rayDiv(counterIndexes.p2pIndex));

        emit Events.P2PTotalsUpdated(underlying, deltas.supply.scaledP2PTotal, deltas.borrow.scaledP2PTotal);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Types} from "./Types.sol";
import {Events} from "./Events.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";

/// @title MarketSideDeltaLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease increase or decrease deltas.
library MarketSideDeltaLib {
    using Math for uint256;
    using WadRayMath for uint256;

    /// @notice Given variables from a market side, updates the market side delta according to the demoted amount.
    /// @param delta The market deltas to update.
    /// @param underlying The underlying address.
    /// @param amount The amount to supply/borrow (in underlying).
    /// @param indexes The current indexes.
    /// @param borrowSide Whether the market side is borrow.
    function increaseDelta(
        Types.MarketSideDelta storage delta,
        address underlying,
        uint256 amount,
        Types.MarketSideIndexes256 memory indexes,
        bool borrowSide
    ) internal {
        if (amount == 0) return;

        uint256 newScaledDelta = delta.scaledDelta + amount.rayDiv(indexes.poolIndex);

        delta.scaledDelta = newScaledDelta;

        if (borrowSide) emit Events.P2PBorrowDeltaUpdated(underlying, newScaledDelta);
        else emit Events.P2PSupplyDeltaUpdated(underlying, newScaledDelta);
    }

    /// @notice Given variables from a market side, matches the delta and calculates the amount to supply/borrow from delta.
    ///         Updates the market side delta accordingly.
    /// @param delta The market deltas to update.
    /// @param underlying The underlying address.
    /// @param amount The amount to supply/borrow (in underlying).
    /// @param poolIndex The current pool index.
    /// @param borrowSide Whether the market side is borrow.
    /// @return The amount left to process (in underlying) and the amount to repay/withdraw (in underlying).
    function decreaseDelta(
        Types.MarketSideDelta storage delta,
        address underlying,
        uint256 amount,
        uint256 poolIndex,
        bool borrowSide
    ) internal returns (uint256, uint256) {
        if (amount == 0) return (0, 0);

        uint256 scaledDelta = delta.scaledDelta;
        if (scaledDelta == 0) return (amount, 0);

        uint256 decreased = Math.min(scaledDelta.rayMulUp(poolIndex), amount); // In underlying.
        uint256 newScaledDelta = scaledDelta.zeroFloorSub(decreased.rayDivDown(poolIndex));

        delta.scaledDelta = newScaledDelta;

        if (borrowSide) emit Events.P2PBorrowDeltaUpdated(underlying, newScaledDelta);
        else emit Events.P2PSupplyDeltaUpdated(underlying, newScaledDelta);

        return (amount - decreased, decreased);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

/**
 * @title UserConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;
  uint256 internal constant COLLATERAL_MASK =
    0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

  /**
   * @notice Sets if the user is borrowing the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param borrowing True if the user is borrowing the reserve, false otherwise
   */
  function setBorrowing(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool borrowing
  ) internal {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << (reserveIndex << 1);
      if (borrowing) {
        self.data |= bit;
      } else {
        self.data &= ~bit;
      }
    }
  }

  /**
   * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
   */
  function setUsingAsCollateral(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool usingAsCollateral
  ) internal {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << ((reserveIndex << 1) + 1);
      if (usingAsCollateral) {
        self.data |= bit;
      } else {
        self.data &= ~bit;
      }
    }
  }

  /**
   * @notice Returns if a user has been using the reserve for borrowing or as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
   */
  function isUsingAsCollateralOrBorrowing(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> (reserveIndex << 1)) & 3 != 0;
    }
  }

  /**
   * @notice Validate a user has been using the reserve for borrowing
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing, false otherwise
   */
  function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> (reserveIndex << 1)) & 1 != 0;
    }
  }

  /**
   * @notice Validate a user has been using the reserve as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve as collateral, false otherwise
   */
  function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
    }
  }

  /**
   * @notice Checks if a user has been supplying only one reserve as collateral
   * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
   * @param self The configuration object
   * @return True if the user has been supplying as collateral one reserve, false otherwise
   */
  function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    uint256 collateralData = self.data & COLLATERAL_MASK;
    return collateralData != 0 && (collateralData & (collateralData - 1) == 0);
  }

  /**
   * @notice Checks if a user has been supplying any reserve as collateral
   * @param self The configuration object
   * @return True if the user has been supplying as collateral any reserve, false otherwise
   */
  function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return self.data & COLLATERAL_MASK != 0;
  }

  /**
   * @notice Checks if a user has been borrowing only one asset
   * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
   * @param self The configuration object
   * @return True if the user has been supplying as collateral one reserve, false otherwise
   */
  function isBorrowingOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    uint256 borrowingData = self.data & BORROWING_MASK;
    return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
  }

  /**
   * @notice Checks if a user has been borrowing from any reserve
   * @param self The configuration object
   * @return True if the user has been borrowing any reserve, false otherwise
   */
  function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data & BORROWING_MASK != 0;
  }

  /**
   * @notice Checks if a user has not been using any reserve for borrowing or supply
   * @param self The configuration object
   * @return True if the user has not been borrowing or supplying any reserve, false otherwise
   */
  function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data == 0;
  }

  /**
   * @notice Returns the Isolation Mode state of the user
   * @param self The configuration object
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @return True if the user is in isolation mode, false otherwise
   * @return The address of the only asset used as collateral
   * @return The debt ceiling of the reserve
   */
  function getIsolationModeState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  )
    internal
    view
    returns (
      bool,
      address,
      uint256
    )
  {
    if (isUsingAsCollateralOne(self)) {
      uint256 assetId = _getFirstAssetIdByMask(self, COLLATERAL_MASK);

      address assetAddress = reservesList[assetId];
      uint256 ceiling = reservesData[assetAddress].configuration.getDebtCeiling();
      if (ceiling != 0) {
        return (true, assetAddress, ceiling);
      }
    }
    return (false, address(0), 0);
  }

  /**
   * @notice Returns the siloed borrowing state for the user
   * @param self The configuration object
   * @param reservesData The data of all the reserves
   * @param reservesList The reserve list
   * @return True if the user has borrowed a siloed asset, false otherwise
   * @return The address of the only borrowed asset
   */
  function getSiloedBorrowingState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  ) internal view returns (bool, address) {
    if (isBorrowingOne(self)) {
      uint256 assetId = _getFirstAssetIdByMask(self, BORROWING_MASK);
      address assetAddress = reservesList[assetId];
      if (reservesData[assetAddress].configuration.getSiloedBorrowing()) {
        return (true, assetAddress);
      }
    }

    return (false, address(0));
  }

  /**
   * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
   * @param self The configuration object
   * @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
   */
  function _getFirstAssetIdByMask(DataTypes.UserConfigurationMap memory self, uint256 mask)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 bitmapData = self.data & mask;
      uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);
      uint256 id;

      while ((firstAssetPosition >>= 2) != 0) {
        id += 1;
      }
      return id;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

  uint256 internal constant MAX_VALID_LTV = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 internal constant MAX_VALID_DECIMALS = 255;
  uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
  uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
  uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
  uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint256 public constant DEBT_CEILING_DECIMALS = 2;
  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   */
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   */
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   */
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold)
    internal
    pure
  {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   */
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   */
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
    internal
    pure
  {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   */
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   */
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
    internal
    pure
  {
    require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   */
  function getDecimals(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   */
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   */
  function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   */
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   */
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   */
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
    self.data =
      (self.data & PAUSED_MASK) |
      (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   */
  function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
   * amount will be accumulated in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   */
  function setBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self, bool borrowable)
    internal
    pure
  {
    self.data =
      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
      (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
   * isolated collateral is accounted for in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   */
  function getBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Sets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @param siloed True if the asset is siloed
   */
  function setSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self, bool siloed)
    internal
    pure
  {
    self.data =
      (self.data & SILOED_BORROWING_MASK) |
      (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @return The siloed borrowing flag
   */
  function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~SILOED_BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   */
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   */
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   */
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   */
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   */
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
    internal
    pure
  {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   */
  function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   */
  function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap)
    internal
    pure
  {
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   */
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   */
  function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap)
    internal
    pure
  {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   */
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   */
  function setDebtCeiling(DataTypes.ReserveConfigurationMap memory self, uint256 ceiling)
    internal
    pure
  {
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);

    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   */
  function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   */
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 liquidationProtocolFee
  ) internal pure {
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   */
  function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   */
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 unbackedMintCap
  ) internal pure {
    require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);

    self.data =
      (self.data & UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   */
  function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the eMode asset category
   * @param self The reserve configuration
   * @param category The asset category when the user selects the eMode
   */
  function setEModeCategory(DataTypes.ReserveConfigurationMap memory self, uint256 category)
    internal
    pure
  {
    require(category <= MAX_VALID_EMODE_CATEGORY, Errors.INVALID_EMODE_CATEGORY);

    self.data = (self.data & EMODE_CATEGORY_MASK) | (category << EMODE_CATEGORY_START_BIT_POSITION);
  }

  /**
   * @dev Gets the eMode asset category
   * @param self The reserve configuration
   * @return The eMode category for the asset
   */
  function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
  }

  /**
   * @notice Sets the flashloanable flag for the reserve
   * @param self The reserve configuration
   * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
   */
  function setFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self, bool flashLoanEnabled)
    internal
    pure
  {
    self.data =
      (self.data & FLASHLOAN_ENABLED_MASK) |
      (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the flashloanable flag for the reserve
   * @param self The reserve configuration
   * @return The flashloanable flag
   */
  function getFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing stableRateBorrowing enabled
   * @return The state flag representing paused
   */
  function getFlags(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
      (dataLocal & ~PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   * @return The state param representing eMode category
   */
  function getParams(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   */
  function getCaps(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Types} from "./libraries/Types.sol";
import {Events} from "./libraries/Events.sol";

import {MarketLib} from "./libraries/MarketLib.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";

import {LogarithmicBuckets} from "@morpho-data-structures/LogarithmicBuckets.sol";

import {MorphoInternal} from "./MorphoInternal.sol";

/// @title MatchingEngine
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Abstract contract with functions to promote or demote users to/from peer-to-peer.
abstract contract MatchingEngine is MorphoInternal {
    using MarketLib for Types.Market;

    using Math for uint256;
    using WadRayMath for uint256;

    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    /// @dev Promotes suppliers on the `underlying` market.
    /// @param underlying The address of the underlying market on which to promote suppliers.
    /// @param amount The amount of `underlying` to promote.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    function _promoteSuppliers(address underlying, uint256 amount, uint256 maxIterations)
        internal
        returns (uint256, uint256)
    {
        return _promoteOrDemote(
            _marketBalances[underlying].poolSuppliers,
            _marketBalances[underlying].p2pSuppliers,
            Types.MatchingEngineVars({
                underlying: underlying,
                indexes: _market[underlying].getSupplyIndexes(),
                amount: amount,
                maxIterations: maxIterations,
                borrow: false,
                updateDS: _updateSupplierInDS,
                demoting: false,
                step: _promote
            })
        );
    }

    /// @dev Promotes borrowers on the `underlying` market.
    /// @param underlying The address of the underlying market on which to promote borrowers.
    /// @param amount The amount of `underlying` to promote.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    function _promoteBorrowers(address underlying, uint256 amount, uint256 maxIterations)
        internal
        returns (uint256, uint256)
    {
        return _promoteOrDemote(
            _marketBalances[underlying].poolBorrowers,
            _marketBalances[underlying].p2pBorrowers,
            Types.MatchingEngineVars({
                underlying: underlying,
                indexes: _market[underlying].getBorrowIndexes(),
                amount: amount,
                maxIterations: maxIterations,
                borrow: true,
                updateDS: _updateBorrowerInDS,
                demoting: false,
                step: _promote
            })
        );
    }

    /// @dev Demotes suppliers on the `underlying` market.
    /// @param underlying The address of the underlying market on which to demote suppliers.
    /// @param amount The amount of `underlying` to demote.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    function _demoteSuppliers(address underlying, uint256 amount, uint256 maxIterations)
        internal
        returns (uint256 demoted)
    {
        (demoted,) = _promoteOrDemote(
            _marketBalances[underlying].poolSuppliers,
            _marketBalances[underlying].p2pSuppliers,
            Types.MatchingEngineVars({
                underlying: underlying,
                indexes: _market[underlying].getSupplyIndexes(),
                amount: amount,
                maxIterations: maxIterations,
                borrow: false,
                updateDS: _updateSupplierInDS,
                demoting: true,
                step: _demote
            })
        );
    }

    /// @dev Demotes borrowers on the `underlying` market.
    /// @param underlying The address of the underlying market on which to demote borrowers.
    /// @param amount The amount of `underlying` to demote.
    /// @param maxIterations The maximum number of iterations allowed during the matching process.
    function _demoteBorrowers(address underlying, uint256 amount, uint256 maxIterations)
        internal
        returns (uint256 demoted)
    {
        (demoted,) = _promoteOrDemote(
            _marketBalances[underlying].poolBorrowers,
            _marketBalances[underlying].p2pBorrowers,
            Types.MatchingEngineVars({
                underlying: underlying,
                indexes: _market[underlying].getBorrowIndexes(),
                amount: amount,
                maxIterations: maxIterations,
                borrow: true,
                updateDS: _updateBorrowerInDS,
                demoting: true,
                step: _demote
            })
        );
    }

    /// @dev Promotes or demotes users.
    /// @param poolBuckets The pool buckets.
    /// @param poolBuckets The peer-to-peer buckets.
    /// @param vars The required matching engine variables to perform the matching process.
    function _promoteOrDemote(
        LogarithmicBuckets.Buckets storage poolBuckets,
        LogarithmicBuckets.Buckets storage p2pBuckets,
        Types.MatchingEngineVars memory vars
    ) internal returns (uint256 processed, uint256 iterationsDone) {
        if (vars.maxIterations == 0) return (0, 0);

        uint256 remaining = vars.amount;
        LogarithmicBuckets.Buckets storage workingBuckets = vars.demoting ? p2pBuckets : poolBuckets;

        for (; iterationsDone < vars.maxIterations && remaining != 0; ++iterationsDone) {
            address firstUser = workingBuckets.getMatch(remaining);
            if (firstUser == address(0)) break;

            uint256 onPool;
            uint256 inP2P;

            (onPool, inP2P, remaining) =
                vars.step(poolBuckets.valueOf[firstUser], p2pBuckets.valueOf[firstUser], vars.indexes, remaining);

            (onPool, inP2P) = vars.updateDS(vars.underlying, firstUser, onPool, inP2P, vars.demoting);

            if (vars.borrow) emit Events.BorrowPositionUpdated(firstUser, vars.underlying, onPool, inP2P);
            else emit Events.SupplyPositionUpdated(firstUser, vars.underlying, onPool, inP2P);
        }

        // Safe unchecked because vars.amount >= remaining.
        unchecked {
            processed = vars.amount - remaining;
        }
    }

    /// @dev Promotes a given amount in peer-to-peer.
    /// @param poolBalance The scaled balance of the user on the pool.
    /// @param p2pBalance The scaled balance of the user in peer-to-peer.
    /// @param indexes The indexes of the market.
    /// @param remaining The remaining amount to promote.
    function _promote(
        uint256 poolBalance,
        uint256 p2pBalance,
        Types.MarketSideIndexes256 memory indexes,
        uint256 remaining
    ) internal pure returns (uint256 newPoolBalance, uint256 newP2PBalance, uint256 newRemaining) {
        uint256 toProcess = Math.min(poolBalance.rayMul(indexes.poolIndex), remaining);

        newRemaining = remaining - toProcess;
        newPoolBalance = poolBalance - toProcess.rayDiv(indexes.poolIndex);
        newP2PBalance = p2pBalance + toProcess.rayDiv(indexes.p2pIndex);
    }

    /// @dev Demotes a given amount in peer-to-peer.
    /// @param poolBalance The scaled balance of the user on the pool.
    /// @param p2pBalance The scaled balance of the user in peer-to-peer.
    /// @param indexes The indexes of the market.
    /// @param remaining The remaining amount to demote.
    function _demote(
        uint256 poolBalance,
        uint256 p2pBalance,
        Types.MarketSideIndexes256 memory indexes,
        uint256 remaining
    ) internal pure returns (uint256 newPoolBalance, uint256 newP2PBalance, uint256 newRemaining) {
        uint256 toProcess = Math.min(p2pBalance.rayMul(indexes.p2pIndex), remaining);

        newRemaining = remaining - toProcess;
        newPoolBalance = poolBalance + toProcess.rayDiv(indexes.poolIndex);
        newP2PBalance = p2pBalance - toProcess.rayDiv(indexes.p2pIndex);
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title BucketDLL
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice The doubly linked list used in logarithmic buckets.
library BucketDLL {
    /* STRUCTS */

    struct Account {
        address prev;
        address next;
    }

    struct List {
        mapping(address => Account) accounts;
    }

    /* INTERNAL */

    /// @notice Returns the next id address from the current `id`.
    /// @dev Pass the address 0 to get the head of the list.
    /// @param list The list to search in.
    /// @param id The address of the current account.
    /// @return The address of the next account.
    function getNext(List storage list, address id) internal view returns (address) {
        return list.accounts[id].next;
    }

    /// @notice Removes an account of the `list`.
    /// @dev This function should not be called with `id` equal to address 0.
    /// @dev This function should not be called with an `_id` that is not in the list.
    /// @param list The list to search in.
    /// @param id The address of the account.
    /// @return Whether the bucket is empty after removal.
    function remove(List storage list, address id) internal returns (bool) {
        Account memory account = list.accounts[id];
        address prev = account.prev;
        address next = account.next;

        list.accounts[prev].next = next;
        list.accounts[next].prev = prev;

        delete list.accounts[id];

        return (prev == address(0) && next == address(0));
    }

    /// @notice Inserts an account in the `list`.
    /// @dev This function should not be called with `id` equal to address 0.
    /// @dev This function should not be called with an `id` that is already in the list.
    /// @param list The list to search in.
    /// @param id The address of the account.
    /// @param atHead Tells whether to insert at the head or at the tail of the list.
    /// @return Whether the bucket was empty before insertion.
    function insert(
        List storage list,
        address id,
        bool atHead
    ) internal returns (bool) {
        if (atHead) {
            address head = list.accounts[address(0)].next;
            list.accounts[address(0)].next = id;
            list.accounts[head].prev = id;
            list.accounts[id].next = head;
            return head == address(0);
        } else {
            address tail = list.accounts[address(0)].prev;
            list.accounts[address(0)].prev = id;
            list.accounts[tail].next = id;
            list.accounts[id].prev = tail;
            return tail == address(0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IScaledBalanceToken
 * @author Aave
 * @notice Defines the basic interface for a scaled-balance token.
 */
interface IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted tokens
   * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
   * @param index The next liquidity index of the reserve
   */
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @dev Emitted after the burn action
   * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
   * @param from The address from which the tokens will be burned
   * @param target The address that will receive the underlying, if any
   * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
   * @param index The next liquidity index of the reserve
   */
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @notice Returns the scaled balance of the user.
   * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
   * at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   */
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled total supply
   */
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
   * @return The scaled total supply
   */
  function scaledTotalSupply() external view returns (uint256);

  /**
   * @notice Returns last index interest was accrued to the user's balance
   * @param user The address of the user
   * @return The last index interest was accrued to the user's balance, expressed in ray
   */
  function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableAToken
 * @author Aave
 * @notice Interface for the initialize function on AToken
 */
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals The decimals of the underlying
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the aToken
   * @param pool The pool contract that is initializing this contract
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableDebtToken
 * @author Aave
 * @notice Interface for the initialize function common between debt tokens
 */
interface IInitializableDebtToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param incentivesController The address of the incentives controller for this aToken
   * @param debtTokenDecimals The decimals of the debt token
   * @param debtTokenName The name of the debt token
   * @param debtTokenSymbol The symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the debt token.
   * @param pool The pool contract that is initializing this contract
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
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
                require(isContract(target), "Address: call to non-contract");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IStableDebtToken} from "@aave-v3-core/interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "@aave-v3-core/interfaces/IVariableDebtToken.sol";

import {Types} from "./Types.sol";

import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";

import {MathUtils} from "@aave-v3-core/protocol/libraries/math/MathUtils.sol";
import {DataTypes} from "@aave-v3-core/protocol/libraries/types/DataTypes.sol";
import {ReserveConfiguration} from "@aave-v3-core/protocol/libraries/configuration/ReserveConfiguration.sol";

/// @title ReserveDataLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease AaveV3's reserve-related calculations.
library ReserveDataLib {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /// @notice Calculates the scaled quantity of reserve dedicated to AaveV3's treasury, taking into account interests accrued.
    /// @dev Reference: https://github.com/aave/aave-v3-core/blob/a00f28e3ad7c0e4a369d8e06e0ac9fd0acabcab7/contracts/protocol/libraries/logic/ReserveLogic.sol#L230-L282.
    /// @param reserve The reserve data of a given market.
    /// @param indexes The updated pool & peer-to-peer indexes of the associated market.
    /// @return The reserve's dedicated treasury, in pool unit.
    function getAccruedToTreasury(DataTypes.ReserveData memory reserve, Types.Indexes256 memory indexes)
        internal
        view
        returns (uint256)
    {
        uint256 reserveFactor = reserve.configuration.getReserveFactor();
        if (reserveFactor == 0) return reserve.accruedToTreasury;

        (
            uint256 currPrincipalStableDebt,
            uint256 currTotalStableDebt,
            uint256 currAvgStableBorrowRate,
            uint40 stableDebtLastUpdateTimestamp
        ) = IStableDebtToken(reserve.stableDebtTokenAddress).getSupplyData();
        uint256 scaledTotalVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledTotalSupply();

        uint256 currTotalVariableDebt = scaledTotalVariableDebt.rayMul(indexes.borrow.poolIndex);
        uint256 prevTotalVariableDebt = scaledTotalVariableDebt.rayMul(reserve.variableBorrowIndex);
        uint256 prevTotalStableDebt = currPrincipalStableDebt.rayMul(
            MathUtils.calculateCompoundedInterest(
                currAvgStableBorrowRate, stableDebtLastUpdateTimestamp, reserve.lastUpdateTimestamp
            )
        );

        uint256 accruedTotalDebt =
            currTotalVariableDebt + currTotalStableDebt - prevTotalVariableDebt - prevTotalStableDebt;
        if (accruedTotalDebt == 0) return reserve.accruedToTreasury;

        uint256 newAccruedToTreasury = accruedTotalDebt.percentMul(reserveFactor).rayDiv(indexes.supply.poolIndex);

        return reserve.accruedToTreasury + newAccruedToTreasury;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
  string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
  string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {IPool} from "@aave-v3-core/interfaces/IPool.sol";
import {IRewardsManager} from "./interfaces/IRewardsManager.sol";
import {IAaveOracle} from "@aave-v3-core/interfaces/IAaveOracle.sol";

import {Types} from "./libraries/Types.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";
import {PoolLib} from "./libraries/PoolLib.sol";
import {MarketLib} from "./libraries/MarketLib.sol";
import {DeltasLib} from "./libraries/DeltasLib.sol";
import {Constants} from "./libraries/Constants.sol";
import {MarketBalanceLib} from "./libraries/MarketBalanceLib.sol";
import {InterestRatesLib} from "./libraries/InterestRatesLib.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";

import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {LogarithmicBuckets} from "@morpho-data-structures/LogarithmicBuckets.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {DataTypes} from "@aave-v3-core/protocol/libraries/types/DataTypes.sol";
import {UserConfiguration} from "@aave-v3-core/protocol/libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "@aave-v3-core/protocol/libraries/configuration/ReserveConfiguration.sol";

import {MorphoStorage} from "./MorphoStorage.sol";

/// @title MorphoInternal
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Abstract contract exposing `Morpho`'s internal functions.
abstract contract MorphoInternal is MorphoStorage {
    using PoolLib for IPool;
    using MarketLib for Types.Market;
    using DeltasLib for Types.Deltas;
    using MarketBalanceLib for Types.MarketBalances;

    using Math for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    using SafeTransferLib for ERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    using LogarithmicBuckets for LogarithmicBuckets.Buckets;

    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /* INTERNAL */

    /// @dev Dynamically computed to use the root proxy address in a delegate call.
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                Constants.EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(Constants.EIP712_NAME)),
                keccak256(bytes(Constants.EIP712_VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Creates a new market for the `underlying` token with a given `reserveFactor` (in bps) and a given `p2pIndexCursor` (in bps).
    function _createMarket(address underlying, uint16 reserveFactor, uint16 p2pIndexCursor) internal {
        if (underlying == address(0)) revert Errors.AddressIsZero();

        DataTypes.ReserveData memory reserve = _pool.getReserveData(underlying);
        if (!reserve.configuration.getActive()) revert Errors.MarketIsNotListedOnAave();
        if (reserve.configuration.getSiloedBorrowing()) revert Errors.SiloedBorrowMarket();

        // `liquidationThreshold < Constants.LT_LOWER_BOUND` checks that the asset's LT is not too low to be listed as a collateral on Morpho.
        // If the LT is 0, the check is skipped to be able to create markets for non-collateral assets.
        // In the case where the "standard" LT is below the `LT_LOWER_BOUND` while the eMode LT is higher, the check will still revert for safety.
        uint256 liquidationThreshold = reserve.configuration.getLiquidationThreshold();
        if (liquidationThreshold > 0 && liquidationThreshold < Constants.LT_LOWER_BOUND) {
            revert Errors.MarketLtTooLow();
        }

        Types.Market storage market = _market[underlying];

        if (market.isCreated()) revert Errors.MarketAlreadyCreated();

        market.underlying = underlying;
        market.aToken = reserve.aTokenAddress;
        market.variableDebtToken = reserve.variableDebtTokenAddress;
        market.stableDebtToken = reserve.stableDebtTokenAddress;

        _marketsCreated.push(underlying);

        emit Events.MarketCreated(underlying);

        Types.Indexes256 memory indexes;
        (indexes.supply.poolIndex, indexes.borrow.poolIndex) = _pool.getCurrentPoolIndexes(underlying);
        indexes.supply.p2pIndex = WadRayMath.RAY;
        indexes.borrow.p2pIndex = WadRayMath.RAY;

        market.setIndexes(indexes);
        market.setReserveFactor(reserveFactor);
        market.setP2PIndexCursor(p2pIndexCursor);

        ERC20(underlying).safeApprove(address(_pool), type(uint256).max);
    }

    /// @dev Claims the fee for the `underlyings` and send it to the `_treasuryVault`.
    ///      Claiming on a market where there are some rewards might steal users' rewards.
    function _claimToTreasury(address[] calldata underlyings, uint256[] calldata amounts) internal {
        address treasuryVault = _treasuryVault;
        if (treasuryVault == address(0)) revert Errors.AddressIsZero();

        for (uint256 i; i < underlyings.length; ++i) {
            address underlying = underlyings[i];
            Types.Market storage market = _market[underlying];

            if (!market.isCreated()) continue;

            uint256 claimable = ERC20(underlying).balanceOf(address(this)) - market.idleSupply;
            uint256 claimed = Math.min(amounts[i], claimable);

            if (claimed == 0) continue;

            ERC20(underlying).safeTransfer(treasuryVault, claimed);
            emit Events.ReserveFeeClaimed(underlying, claimed);
        }
    }

    /// @dev Increases the peer-to-peer delta of `amount` on the `underlying` market.
    /// @dev Note that this can fail if the amount is too big. In this case, consider splitting in multiple calls/txs.
    function _increaseP2PDeltas(address underlying, uint256 amount) internal {
        Types.Indexes256 memory indexes = _updateIndexes(underlying);

        Types.Market storage market = _market[underlying];
        Types.Deltas storage deltas = market.deltas;
        uint256 poolSupplyIndex = indexes.supply.poolIndex;
        uint256 poolBorrowIndex = indexes.borrow.poolIndex;

        amount = Math.min(amount, Math.min(market.trueP2PSupply(indexes), market.trueP2PBorrow(indexes)));
        if (amount == 0) revert Errors.AmountIsZero();

        uint256 newSupplyDelta = deltas.supply.scaledDelta + amount.rayDiv(poolSupplyIndex);
        uint256 newBorrowDelta = deltas.borrow.scaledDelta + amount.rayDiv(poolBorrowIndex);

        deltas.supply.scaledDelta = newSupplyDelta;
        deltas.borrow.scaledDelta = newBorrowDelta;
        emit Events.P2PSupplyDeltaUpdated(underlying, newSupplyDelta);
        emit Events.P2PBorrowDeltaUpdated(underlying, newBorrowDelta);

        _pool.borrowFromPool(underlying, amount);
        _pool.supplyToPool(underlying, amount, poolSupplyIndex);

        emit Events.P2PDeltasIncreased(underlying, amount);
    }

    /// @dev Returns the hash of the EIP712 typed data.
    function _hashEIP712TypedData(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(Constants.EIP712_MSG_PREFIX, _domainSeparator(), structHash));
    }

    /// @dev Approves a `manager` to borrow/withdraw on behalf of the `delegator`.
    /// @param delegator The address of the delegator.
    /// @param manager The address of the manager.
    /// @param isAllowed Whether `manager` is allowed to manage `delegator`'s position or not.
    function _approveManager(address delegator, address manager, bool isAllowed) internal {
        _isManagedBy[delegator][manager] = isAllowed;
        emit Events.ManagerApproval(delegator, manager, isAllowed);
    }

    /// @dev Returns the total supply balance of `user` on the `underlying` market given `indexes` (in underlying).
    function _getUserSupplyBalanceFromIndexes(address underlying, address user, Types.Indexes256 memory indexes)
        internal
        view
        returns (uint256)
    {
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];

        return marketBalances.scaledPoolSupplyBalance(user).rayMulDown(indexes.supply.poolIndex)
            + marketBalances.scaledP2PSupplyBalance(user).rayMulDown(indexes.supply.p2pIndex);
    }

    /// @dev Returns the total borrow balance of `user` on the `underlying` market given `indexes` (in underlying).
    function _getUserBorrowBalanceFromIndexes(address underlying, address user, Types.Indexes256 memory indexes)
        internal
        view
        returns (uint256)
    {
        Types.MarketBalances storage marketBalances = _marketBalances[underlying];

        return marketBalances.scaledPoolBorrowBalance(user).rayMulUp(indexes.borrow.poolIndex)
            + marketBalances.scaledP2PBorrowBalance(user).rayMulUp(indexes.borrow.p2pIndex);
    }

    /// @dev Returns the collateral balance of `user` on the `underlying` market a `poolSupplyIndex` (in underlying).
    function _getUserCollateralBalanceFromIndex(address underlying, address user, uint256 poolSupplyIndex)
        internal
        view
        returns (uint256)
    {
        return _marketBalances[underlying].scaledCollateralBalance(user).rayMulDown(poolSupplyIndex);
    }

    /// @dev Returns the buckets of a particular side of a market.
    /// @param underlying The address of the underlying asset.
    /// @param position The side of the market.
    function _getBuckets(address underlying, Types.Position position)
        internal
        view
        returns (LogarithmicBuckets.Buckets storage)
    {
        if (position == Types.Position.POOL_SUPPLIER) {
            return _marketBalances[underlying].poolSuppliers;
        } else if (position == Types.Position.P2P_SUPPLIER) {
            return _marketBalances[underlying].p2pSuppliers;
        } else if (position == Types.Position.POOL_BORROWER) {
            return _marketBalances[underlying].poolBorrowers;
        } else {
            return _marketBalances[underlying].p2pBorrowers;
        }
    }

    /// @notice Returns the liquidity data about the position of `user`.
    /// @param user The address of the user to get the liquidity data for.
    /// @return liquidityData The liquidity data of the user.
    function _liquidityData(address user) internal view returns (Types.LiquidityData memory liquidityData) {
        Types.LiquidityVars memory vars;

        if (_eModeCategoryId != 0) vars.eModeCategory = _pool.getEModeCategoryData(_eModeCategoryId);
        vars.oracle = IAaveOracle(_addressesProvider.getPriceOracle());
        vars.user = user;

        (liquidityData.borrowable, liquidityData.maxDebt) = _totalCollateralData(vars);
        liquidityData.debt = _totalDebt(vars);
    }

    /// @dev Returns the collateral data for a given set of inputs.
    /// @dev The total collateral data is computed looping through all user's collateral assets.
    /// @param vars The liquidity variables.
    /// @return borrowable The total borrowable amount of `vars.user`.
    /// @return maxDebt The total maximum debt of `vars.user`.
    function _totalCollateralData(Types.LiquidityVars memory vars)
        internal
        view
        returns (uint256 borrowable, uint256 maxDebt)
    {
        address[] memory userCollaterals = _userCollaterals[vars.user].values();

        for (uint256 i; i < userCollaterals.length; ++i) {
            (uint256 borrowableSingle, uint256 maxDebtSingle) = _collateralData(userCollaterals[i], vars);

            borrowable += borrowableSingle;
            maxDebt += maxDebtSingle;
        }
    }

    /// @dev Returns the debt data for a given set of inputs.
    /// @dev The total debt data is computed iterating through all user's borrow assets.
    /// @param vars The liquidity variables.
    /// @return debt The total debt of `vars.user`.
    function _totalDebt(Types.LiquidityVars memory vars) internal view returns (uint256 debt) {
        address[] memory userBorrows = _userBorrows[vars.user].values();

        for (uint256 i; i < userBorrows.length; ++i) {
            debt += _debt(userBorrows[i], vars);
        }
    }

    /// @dev Returns the collateral data for a given set of inputs.
    /// @param underlying The address of the underlying collateral asset.
    /// @param vars The liquidity variables.
    /// @return borrowable The borrowable amount of `vars.user` on the `underlying` market.
    /// @return maxDebt The maximum debt of `vars.user` on the `underlying` market.
    function _collateralData(address underlying, Types.LiquidityVars memory vars)
        internal
        view
        returns (uint256 borrowable, uint256 maxDebt)
    {
        if (!_market[underlying].isCollateral) return (0, 0);

        (uint256 underlyingPrice, uint256 ltv, uint256 liquidationThreshold, uint256 underlyingUnit) =
            _assetLiquidityData(underlying, vars);

        Types.Indexes256 memory indexes = _computeIndexes(underlying);
        uint256 rawCollateral = (
            (_getUserCollateralBalanceFromIndex(underlying, vars.user, indexes.supply.poolIndex)) * underlyingPrice
        ) / underlyingUnit;

        // Morpho has a slightly different method of health factor calculation from the underlying pool.
        // This method is used to account for a potential rounding error in calculateUserAccountData,
        // see https://github.com/aave/aave-v3-core/blob/94e571f3a7465201881a59555314cd550ccfda57/contracts/protocol/libraries/logic/GenericLogic.sol#L64-L196
        // To resolve this, Morpho reduces the collateral value by a small amount.
        uint256 collateral = ((Constants.LT_LOWER_BOUND - 1) * rawCollateral) / Constants.LT_LOWER_BOUND;

        borrowable = collateral.percentMulDown(ltv);
        maxDebt = collateral.percentMulDown(liquidationThreshold);
    }

    /// @dev Returns the debt value for a given set of inputs.
    /// @param underlying The address of the underlying asset to borrow.
    /// @param vars The liquidity variables.
    /// @return debtValue The debt value of `vars.user` on the `underlying` market.
    function _debt(address underlying, Types.LiquidityVars memory vars) internal view returns (uint256 debtValue) {
        DataTypes.ReserveConfigurationMap memory config = _pool.getConfiguration(underlying);
        (, uint256 underlyingPrice, uint256 underlyingUnit) =
            _assetData(underlying, vars.oracle, config, vars.eModeCategory.priceSource);

        Types.Indexes256 memory indexes = _computeIndexes(underlying);
        debtValue =
            (_getUserBorrowBalanceFromIndexes(underlying, vars.user, indexes) * underlyingPrice).divUp(underlyingUnit);
    }

    /// @dev Returns the liquidity data for a given set of inputs.
    /// @param underlying The address of the underlying asset.
    /// @param vars The liquidity variables.
    /// @return underlyingPrice The price of the underlying asset (in base currency).
    /// @return ltv The loan to value of the underlying asset.
    /// @return liquidationThreshold The liquidation threshold of the underlying asset.
    /// @return underlyingUnit The token unit of the underlying asset.
    function _assetLiquidityData(address underlying, Types.LiquidityVars memory vars)
        internal
        view
        returns (uint256 underlyingPrice, uint256 ltv, uint256 liquidationThreshold, uint256 underlyingUnit)
    {
        DataTypes.ReserveConfigurationMap memory config = _pool.getConfiguration(underlying);

        bool isInEMode;
        (isInEMode, underlyingPrice, underlyingUnit) =
            _assetData(underlying, vars.oracle, config, vars.eModeCategory.priceSource);

        // If the LTV is 0 on Aave V3, the asset cannot be used as collateral to borrow upon a breaking withdraw.
        // In response, Morpho disables the asset as collateral and sets its liquidation threshold
        // to 0 and the governance should warn users to repay their debt.
        if (config.getLtv() == 0) return (underlyingPrice, 0, 0, underlyingUnit);

        if (isInEMode) {
            ltv = vars.eModeCategory.ltv;
            liquidationThreshold = vars.eModeCategory.liquidationThreshold;
        } else {
            ltv = config.getLtv();
            liquidationThreshold = config.getLiquidationThreshold();
        }
    }

    /// @dev Prompts the rewards manager (if set) to accrue a user's rewards.
    /// @param user The address of the user to accrue rewards for.
    /// @param poolToken The address of the pool token related to this market (aToken or variable debt token address).
    /// @param formerOnPool The former scaled balance on pool of the `user`.
    function _updateRewards(address user, address poolToken, uint256 formerOnPool) internal {
        IRewardsManager rewardsManager = _rewardsManager;
        if (address(rewardsManager) != address(0)) {
            rewardsManager.updateUserRewards(user, poolToken, formerOnPool);
        }
    }

    /// @dev Updates a `user`'s position in the data structure.
    /// @param poolToken The address of the pool token related to this market (aToken or variable debt token address).
    /// @param user The address of the user to update.
    /// @param poolBuckets The pool buckets.
    /// @param p2pBuckets The peer-to-peer buckets.
    /// @param onPool The new scaled balance on pool of the `user`.
    /// @param inP2P The new scaled balance in peer-to-peer of the `user`.
    /// @param demoting Whether the update is happening during a demoting process or not.
    /// @return The actual new scaled balance on pool and in peer-to-peer of the `user` after accounting for dust.
    function _updateInDS(
        address poolToken,
        address user,
        LogarithmicBuckets.Buckets storage poolBuckets,
        LogarithmicBuckets.Buckets storage p2pBuckets,
        uint256 onPool,
        uint256 inP2P,
        bool demoting
    ) internal returns (uint256, uint256) {
        if (onPool <= Constants.DUST_THRESHOLD) onPool = 0;
        if (inP2P <= Constants.DUST_THRESHOLD) inP2P = 0;

        uint256 formerOnPool = poolBuckets.valueOf[user];
        uint256 formerInP2P = p2pBuckets.valueOf[user];

        if (onPool != formerOnPool) {
            _updateRewards(user, poolToken, formerOnPool);
            poolBuckets.update(user, onPool, demoting);
        }

        if (inP2P != formerInP2P) p2pBuckets.update(user, inP2P, true);
        return (onPool, inP2P);
    }

    /// @dev Updates a `user`'s supply position in the data structure.
    /// @param underlying The address of the underlying asset.
    /// @param user The address of the user to update.
    /// @param onPool The new scaled balance on pool of the `user`.
    /// @param inP2P The new scaled balance in peer-to-peer of the `user`.
    /// @param demoting Whether the update is happening during a demoting process or not.
    /// @return The actual new scaled balance on pool and in peer-to-peer of the `user` after accounting for dust.
    function _updateSupplierInDS(address underlying, address user, uint256 onPool, uint256 inP2P, bool demoting)
        internal
        returns (uint256, uint256)
    {
        return _updateInDS(
            _market[underlying].aToken,
            user,
            _marketBalances[underlying].poolSuppliers,
            _marketBalances[underlying].p2pSuppliers,
            onPool,
            inP2P,
            demoting
        );
        // No need to update the user's list of supplied assets,
        // as it cannot be used as collateral and thus there's no need to iterate over it.
    }

    /// @dev Updates a `user`'s borrow position in the data structure.
    /// @param underlying The address of the underlying asset.
    /// @param user The address of the user to update.
    /// @param onPool The new scaled balance on pool of the `user`.
    /// @param inP2P The new scaled balance in peer-to-peer of the `user`.
    /// @param demoting Whether the update is happening during a demoting process or not.
    /// @return The actual new scaled balance on pool and in peer-to-peer of the `user` after accounting for dust.
    function _updateBorrowerInDS(address underlying, address user, uint256 onPool, uint256 inP2P, bool demoting)
        internal
        returns (uint256, uint256)
    {
        (onPool, inP2P) = _updateInDS(
            _market[underlying].variableDebtToken,
            user,
            _marketBalances[underlying].poolBorrowers,
            _marketBalances[underlying].p2pBorrowers,
            onPool,
            inP2P,
            demoting
        );
        if (onPool == 0 && inP2P == 0) _userBorrows[user].remove(underlying);
        else _userBorrows[user].add(underlying);
        return (onPool, inP2P);
    }

    /// @dev Sets globally the pause status to `isPaused` on the `underlying` market.
    function _setPauseStatus(address underlying, bool isPaused) internal {
        Types.Market storage market = _market[underlying];

        market.setIsSupplyPaused(isPaused);
        market.setIsSupplyCollateralPaused(isPaused);
        market.setIsRepayPaused(isPaused);
        market.setIsWithdrawPaused(isPaused);
        market.setIsWithdrawCollateralPaused(isPaused);
        market.setIsLiquidateCollateralPaused(isPaused);
        market.setIsLiquidateBorrowPaused(isPaused);
        if (!market.isDeprecated()) market.setIsBorrowPaused(isPaused);
    }

    /// @dev Updates the indexes of the `underlying` market and returns them.
    function _updateIndexes(address underlying) internal returns (Types.Indexes256 memory indexes) {
        indexes = _computeIndexes(underlying);

        _market[underlying].setIndexes(indexes);
    }

    /// @dev Computes the updated indexes of the `underlying` market (if not already updated) and returns them.
    function _computeIndexes(address underlying) internal view returns (Types.Indexes256 memory indexes) {
        Types.Market storage market = _market[underlying];
        Types.Indexes256 memory lastIndexes = market.getIndexes();

        (indexes.supply.poolIndex, indexes.borrow.poolIndex) = _pool.getCurrentPoolIndexes(underlying);

        (indexes.supply.p2pIndex, indexes.borrow.p2pIndex) = InterestRatesLib.computeP2PIndexes(
            Types.IndexesParams({
                lastSupplyIndexes: lastIndexes.supply,
                lastBorrowIndexes: lastIndexes.borrow,
                poolSupplyIndex: indexes.supply.poolIndex,
                poolBorrowIndex: indexes.borrow.poolIndex,
                reserveFactor: market.reserveFactor,
                p2pIndexCursor: market.p2pIndexCursor,
                deltas: market.deltas,
                proportionIdle: market.getProportionIdle()
            })
        );
    }

    /// @dev Returns the `user`'s health factor.
    function _getUserHealthFactor(address user) internal view returns (uint256) {
        Types.LiquidityData memory liquidityData = _liquidityData(user);

        return liquidityData.debt > 0 ? liquidityData.maxDebt.wadDiv(liquidityData.debt) : type(uint256).max;
    }

    /// @dev Returns data relative to the given asset and its configuration, according to a given oracle.
    /// @return Whether the given asset is part of Morpho's e-mode category.
    /// @return The asset's price or the price of the given e-mode price source if the asset is in the e-mode category, according to the given oracle.
    /// @return The asset's unit.
    function _assetData(
        address asset,
        IAaveOracle oracle,
        DataTypes.ReserveConfigurationMap memory config,
        address priceSource
    ) internal view returns (bool, uint256, uint256) {
        uint256 assetUnit;
        unchecked {
            assetUnit = 10 ** config.getDecimals();
        }

        bool isInEMode = _isInEModeCategory(config);
        if (isInEMode && priceSource != address(0)) {
            uint256 eModePrice = oracle.getAssetPrice(priceSource);

            if (eModePrice != 0) return (isInEMode, eModePrice, assetUnit);
        }

        return (isInEMode, oracle.getAssetPrice(asset), assetUnit);
    }

    /// @dev Returns whether Morpho is in an e-mode category and the given asset configuration is in the same e-mode category.
    function _isInEModeCategory(DataTypes.ReserveConfigurationMap memory config) internal view returns (bool) {
        return _eModeCategoryId != 0 && config.getEModeCategory() == _eModeCategoryId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 * @dev It only contains one single function, needed as a hook on aToken and debtToken transfers.
 */
interface IAaveIncentivesController {
  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   */
  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IInitializableDebtToken} from './IInitializableDebtToken.sol';

/**
 * @title IStableDebtToken
 * @author Aave
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 */
interface IStableDebtToken is IInitializableDebtToken {
  /**
   * @dev Emitted when new stable debt is minted
   * @param user The address of the user who triggered the minting
   * @param onBehalfOf The recipient of stable debt tokens
   * @param amount The amount minted (user entered amount + balance increase from interest)
   * @param currentBalance The balance of the user based on the previous balance and balance increase from interest
   * @param balanceIncrease The increase in balance since the last action of the user 'onBehalfOf'
   * @param newRate The rate of the debt after the minting
   * @param avgStableRate The next average stable rate after the minting
   * @param newTotalSupply The next total supply of the stable debt token after the action
   */
  event Mint(
    address indexed user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Emitted when new stable debt is burned
   * @param from The address from which the debt will be burned
   * @param amount The amount being burned (user entered amount - balance increase from interest)
   * @param currentBalance The balance of the user based on the previous balance and balance increase from interest
   * @param balanceIncrease The increase in balance since the last action of 'from'
   * @param avgStableRate The next average stable rate after the burning
   * @param newTotalSupply The next total supply of the stable debt token after the action
   */
  event Burn(
    address indexed from,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @notice Mints debt token to the `onBehalfOf` address.
   * @dev The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   * @return True if it is the first borrow, false otherwise
   * @return The total stable debt
   * @return The average stable borrow rate
   */
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 rate
  )
    external
    returns (
      bool,
      uint256,
      uint256
    );

  /**
   * @notice Burns debt of `user`
   * @dev The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest the user earned
   * @param from The address from which the debt will be burned
   * @param amount The amount of debt tokens getting burned
   * @return The total stable debt
   * @return The average stable borrow rate
   */
  function burn(address from, uint256 amount) external returns (uint256, uint256);

  /**
   * @notice Returns the average rate of all the stable rate loans.
   * @return The average stable rate
   */
  function getAverageStableRate() external view returns (uint256);

  /**
   * @notice Returns the stable rate of the user debt
   * @param user The address of the user
   * @return The stable rate of the user
   */
  function getUserStableRate(address user) external view returns (uint256);

  /**
   * @notice Returns the timestamp of the last update of the user
   * @param user The address of the user
   * @return The timestamp
   */
  function getUserLastUpdated(address user) external view returns (uint40);

  /**
   * @notice Returns the principal, the total supply, the average stable rate and the timestamp for the last update
   * @return The principal
   * @return The total supply
   * @return The average stable rate
   * @return The timestamp of the last update
   */
  function getSupplyData()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint40
    );

  /**
   * @notice Returns the timestamp of the last update of the total supply
   * @return The timestamp
   */
  function getTotalSupplyLastUpdated() external view returns (uint40);

  /**
   * @notice Returns the total supply and the average stable rate
   * @return The total supply
   * @return The average rate
   */
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

  /**
   * @notice Returns the principal debt balance of the user
   * @return The debt balance of the user since the last burn/mint action
   */
  function principalBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of this stableDebtToken (E.g. WETH for stableDebtWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {WadRayMath} from './WadRayMath.sol';

/**
 * @title MathUtils library
 * @author Aave
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   */
  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
    unchecked {
      result = result / SECONDS_PER_YEAR;
    }

    return WadRayMath.RAY + result;
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
   * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
   * error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   */
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

    if (exp == 0) {
      return WadRayMath.RAY;
    }

    uint256 expMinusOne;
    uint256 expMinusTwo;
    uint256 basePowerTwo;
    uint256 basePowerThree;
    unchecked {
      expMinusOne = exp - 1;

      expMinusTwo = exp > 2 ? exp - 2 : 0;

      basePowerTwo = rate.rayMul(rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
      basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
    }

    uint256 secondTerm = exp * expMinusOne * basePowerTwo;
    unchecked {
      secondTerm /= 2;
    }
    uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
    unchecked {
      thirdTerm /= 6;
    }

    return WadRayMath.RAY + (rate * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
   */
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Types} from "./Types.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {WadRayMath} from "@morpho-utils/math/WadRayMath.sol";
import {PercentageMath} from "@morpho-utils/math/PercentageMath.sol";

/// @title InterestRatesLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library helping to compute the new peer-to-peer indexes.
library InterestRatesLib {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    /// @notice Computes and returns the new peer-to-peer indexes of a market given its parameters.
    /// @return newP2PSupplyIndex The peer-to-peer supply index.
    /// @return newP2PBorrowIndex The peer-to-peer borrow index.
    function computeP2PIndexes(Types.IndexesParams memory params)
        internal
        pure
        returns (uint256 newP2PSupplyIndex, uint256 newP2PBorrowIndex)
    {
        Types.GrowthFactors memory growthFactors = computeGrowthFactors(
            params.poolSupplyIndex,
            params.poolBorrowIndex,
            params.lastSupplyIndexes.poolIndex,
            params.lastBorrowIndexes.poolIndex,
            params.p2pIndexCursor,
            params.reserveFactor
        );
        newP2PSupplyIndex = computeP2PIndex(
            growthFactors.poolSupplyGrowthFactor,
            growthFactors.p2pSupplyGrowthFactor,
            params.lastSupplyIndexes,
            params.deltas.supply.scaledDelta,
            params.deltas.supply.scaledP2PTotal,
            params.proportionIdle
        );
        newP2PBorrowIndex = computeP2PIndex(
            growthFactors.poolBorrowGrowthFactor,
            growthFactors.p2pBorrowGrowthFactor,
            params.lastBorrowIndexes,
            params.deltas.borrow.scaledDelta,
            params.deltas.borrow.scaledP2PTotal,
            0
        );
    }

    /// @notice Computes and returns the new growth factors associated to a given pool's supply/borrow index & Morpho's peer-to-peer index.
    /// @param newPoolSupplyIndex The pool's current supply index.
    /// @param newPoolBorrowIndex The pool's current borrow index.
    /// @param lastPoolSupplyIndex The pool's last supply index.
    /// @param lastPoolBorrowIndex The pool's last borrow index.
    /// @param p2pIndexCursor The peer-to-peer index cursor for the given market.
    /// @param reserveFactor The reserve factor of the given market.
    /// @return growthFactors The market's indexes growth factors (in ray).
    function computeGrowthFactors(
        uint256 newPoolSupplyIndex,
        uint256 newPoolBorrowIndex,
        uint256 lastPoolSupplyIndex,
        uint256 lastPoolBorrowIndex,
        uint256 p2pIndexCursor,
        uint256 reserveFactor
    ) internal pure returns (Types.GrowthFactors memory growthFactors) {
        growthFactors.poolSupplyGrowthFactor = newPoolSupplyIndex.rayDiv(lastPoolSupplyIndex);
        growthFactors.poolBorrowGrowthFactor = newPoolBorrowIndex.rayDiv(lastPoolBorrowIndex);

        if (growthFactors.poolSupplyGrowthFactor <= growthFactors.poolBorrowGrowthFactor) {
            uint256 p2pGrowthFactor = PercentageMath.weightedAvg(
                growthFactors.poolSupplyGrowthFactor, growthFactors.poolBorrowGrowthFactor, p2pIndexCursor
            );

            growthFactors.p2pSupplyGrowthFactor =
                p2pGrowthFactor - (p2pGrowthFactor - growthFactors.poolSupplyGrowthFactor).percentMul(reserveFactor);
            growthFactors.p2pBorrowGrowthFactor =
                p2pGrowthFactor + (growthFactors.poolBorrowGrowthFactor - p2pGrowthFactor).percentMul(reserveFactor);
        } else {
            // The case poolSupplyGrowthFactor > poolBorrowGrowthFactor happens because someone has done a flashloan on Aave:
            // the peer-to-peer growth factors are set to the pool borrow growth factor.
            growthFactors.p2pSupplyGrowthFactor = growthFactors.poolBorrowGrowthFactor;
            growthFactors.p2pBorrowGrowthFactor = growthFactors.poolBorrowGrowthFactor;
        }
    }

    /// @notice Computes and returns the new peer-to-peer index of a market given its parameters.
    /// @param poolGrowthFactor The pool growth factor.
    /// @param p2pGrowthFactor The peer-to-peer growth factor.
    /// @param lastIndexes The last pool & peer-to-peer indexes.
    /// @param scaledDelta The last scaled peer-to-peer delta (pool unit).
    /// @param scaledP2PTotal The last scaled total peer-to-peer amount (P2P unit).
    /// @return newP2PIndex The updated peer-to-peer index (in ray).
    function computeP2PIndex(
        uint256 poolGrowthFactor,
        uint256 p2pGrowthFactor,
        Types.MarketSideIndexes256 memory lastIndexes,
        uint256 scaledDelta,
        uint256 scaledP2PTotal,
        uint256 proportionIdle
    ) internal pure returns (uint256) {
        if (scaledP2PTotal == 0 || (scaledDelta == 0 && proportionIdle == 0)) {
            return lastIndexes.p2pIndex.rayMul(p2pGrowthFactor);
        }

        uint256 proportionDelta = Math.min(
            scaledDelta.rayMul(lastIndexes.poolIndex).rayDivUp(scaledP2PTotal.rayMul(lastIndexes.p2pIndex)),
            WadRayMath.RAY - proportionIdle // To avoid proportionDelta + proportionIdle > 1 with rounding errors.
        ); // In ray.

        // Equivalent to:
        // lastP2PIndex * (
        // p2pGrowthFactor * (1 - proportionDelta - proportionIdle) +
        // poolGrowthFactor * proportionDelta +
        // idleGrowthFactor * proportionIdle)
        // Notice that the idleGrowthFactor is always equal to 1 (no interests accumulated).
        return lastIndexes.p2pIndex.rayMul(
            p2pGrowthFactor.rayMul(WadRayMath.RAY - proportionDelta - proportionIdle)
                + poolGrowthFactor.rayMul(proportionDelta) + proportionIdle
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   */
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   */
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   */
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   */
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}