// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ==================== Internal Imports ====================

import { ILendingPool } from "../../../interfaces/external/aave-v2/ILendingPool.sol";

import { IMatrixToken } from "../../../interfaces/IMatrixToken.sol";

/**
 * @title AaveV2
 *
 * @dev Collection of helper functions for interacting with AaveV2 integrations.
 */
library AaveV2 {
    // ==================== External functions ====================

    /**
     * @dev Get deposit calldata from MatrixToken. Deposits an `amountNotional` of underlying asset into the reserve,
     * receiving in return overlying aTokens. E.g. User deposits 100 USDC and gets in return 100 aUSDC.
     *
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to deposit
     * @param amountNotional    The amount to be deposited
     * @param onBehalfOf        The address that will receive the aTokens, same as msg.sender if the user wants to receive them on his own wallet,
     *                              or a different address if the beneficiary of aTokens is a different wallet
     * @param referralCode      Code used to register the integrator originating the operation, for potential rewards.
     *                              0 if the action is executed directly by the user, without any middle-man
     *
     * @return target          Target contract address
     * @return value           Call value
     * @return callData        Deposit calldata
     */
    function getDepositCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        address onBehalfOf,
        uint16 referralCode
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        callData = abi.encodeWithSignature("deposit(address,uint256,address,uint16)", asset, amountNotional, onBehalfOf, referralCode);
    }

    /**
     * @dev Invoke deposit on LendingPool from MatrixToken. Deposits an `amountNotional` of underlying asset into the reserve,
     * receiving in return overlying aTokens.E.g. MatrixToken deposits 100 USDC and gets in return 100 aUSDC
     *
     * @param matrixToken       Address of the MatrixToken
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to deposit
     * @param amountNotional    The amount to be deposited
     */
    function invokeDeposit(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional
    ) external {
        (address target, , bytes memory callData) = getDepositCalldata(lendingPool, asset, amountNotional, address(matrixToken), 0);

        matrixToken.invoke(target, 0, callData);
    }

    /**
     * @dev Get withdraw calldata from MatrixToken. Withdraws an `amountNotional` of underlying asset from the reserve,
     * burning the equivalent aTokens owned. E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC.
     *
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to withdraw
     * @param amountNotional    The underlying amount to be withdraw. Passing type(uint256).max will withdraw the entire aToken balance
     * @param receiver          Address that will receive the underlying, same as msg.sender if the user wants to receive it on his own wallet,
     *                              or a different address if the beneficiary is a different wallet
     *
     * @return target           Target contract address
     * @return value            Call value
     * @return callData         Withdraw calldata
     */
    function getWithdrawCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        address receiver
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // withdraw(address asset, uint256 amount, address to)
        callData = abi.encodeWithSignature("withdraw(address,uint256,address)", asset, amountNotional, receiver);
    }

    /**
     * @dev Invoke withdraw on LendingPool from MatrixToken. Withdraws an `amountNotional` of underlying asset from the reserve,
     * burning the equivalent aTokens owned. E.g. MatrixToken has 100 aUSDC, and receives 100 USDC, burning the 100 aUSDC.
     *
     * @param matrixToken       Address of the MatrixToken
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to withdraw
     * @param amountNotional    The underlying amount to be withdraw. Passing type(uint256).max will withdraw the entire aToken balance.
     *
     * @return uint256          The final amount withdraw
     */
    function invokeWithdraw(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional
    ) external returns (uint256) {
        (address target, , bytes memory callData) = getWithdrawCalldata(lendingPool, asset, amountNotional, address(matrixToken));

        return abi.decode(matrixToken.invoke(target, 0, callData), (uint256));
    }

    /**
     * @dev Get borrow calldata from MatrixToken. Allows users to borrow a specific `amountNotional` of the reserve
     * underlying `asset`, provided that the borrower already deposited enough collateral, or he was given enough
     * allowance by a credit delegator on the corresponding debt token (StableDebtToken or VariableDebtToken).
     *
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the underlying asset to borrow
     * @param amountNotional      The amount to be borrowed
     * @param interestRateMode    The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode        Code used to register the integrator originating the operation, for potential rewards.
     *                                0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf          Address of the user who will receive the debt. Should be the address of the borrower itself calling the function if he wants to
     *                                borrow against his own collateral, or the address of the credit delegator if he has been given credit delegation allowance.
     *
     * @return target             Target contract address
     * @return value              Call value
     * @return callData           Borrow calldata
     */
    function getBorrowCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        callData = abi.encodeWithSignature("borrow(address,uint256,uint256,uint16,address)", asset, amountNotional, interestRateMode, referralCode, onBehalfOf);
    }

    /**
     * @dev Invoke borrow on LendingPool from MatrixToken. Allows MatrixToken to borrow a specific `amountNotional` of
     * the reserve underlying `asset`, provided that the MatrixToken already deposited enough collateral, or it was given
     * enough allowance by a credit delegator on the corresponding debt token (StableDebtToken or VariableDebtToken).
     *
     * @param matrixToken         Address of the MatrixToken
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the underlying asset to borrow
     * @param amountNotional      The amount to be borrowed
     * @param interestRateMode    The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     */
    function invokeBorrow(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode
    ) external {
        (address target, , bytes memory callData) = getBorrowCalldata(lendingPool, asset, amountNotional, interestRateMode, 0, address(matrixToken));

        matrixToken.invoke(target, 0, callData);
    }

    /**
     * @dev Get repay calldata from MatrixToken. Repays a borrowed `amountNotional` on a specific `asset` reserve, burning the
     * equivalent debt tokens owned. E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address.
     *
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the borrowed underlying asset previously borrowed
     * @param amountNotional      The amount to repay. Passing type(uint256).max will repay the whole debt for `asset` on the specific `interestRateMode`
     * @param interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf          Address of the user who will get his debt reduced/removed. Should be the address of the user calling the function
     *                                if he wants to reduce/remove his own debt, or the address of any other other borrower whose debt should be removed.
     *
     * @return target             Target contract address
     * @return value              Call value
     * @return callData           Repay calldata
     */
    function getRepayCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode,
        address onBehalfOf
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf)
        callData = abi.encodeWithSignature("repay(address,uint256,uint256,address)", asset, amountNotional, interestRateMode, onBehalfOf);
    }

    /**
     * @dev Invoke repay on LendingPool from MatrixToken. Repays a borrowed `amountNotional` on a specific `asset` reserve,
     * burning the equivalent debt tokens owned. E.g. MatrixToken repays 100 USDC, burning 100 variable/stable debt tokens.
     *
     * @param matrixToken         Address of the MatrixToken
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the borrowed underlying asset previously borrowed
     * @param amountNotional      The amount to repay. Passing type(uint256).max will repay the whole debt for `asset` on the specific `interestRateMode`
     * @param interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     *
     * @return uint256            The final amount repaid
     */
    function invokeRepay(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode
    ) external returns (uint256) {
        (address target, , bytes memory callData) = getRepayCalldata(lendingPool, asset, amountNotional, interestRateMode, address(matrixToken));

        return abi.decode(matrixToken.invoke(target, 0, callData), (uint256));
    }

    /**
     * @dev Get setUserUseReserveAsCollateral calldata from MatrixToken. Allows borrower to enable/disable a specific deposited asset as collateral
     *
     * @param lendingPool        Address of the LendingPool contract
     * @param asset              The address of the underlying asset deposited
     * @param useAsCollateral    true` if the user wants to use the deposit as collateral, `false` otherwise
     *
     * @return target           Target contract address
     * @return value           Call value
     * @return callData             SetUserUseReserveAsCollateral calldata
     */
    function getSetUserUseReserveAsCollateralCalldata(
        ILendingPool lendingPool,
        address asset,
        bool useAsCollateral
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        callData = abi.encodeWithSignature("setUserUseReserveAsCollateral(address,bool)", asset, useAsCollateral);
    }

    /**
     * @dev Invoke an asset to be used as collateral on Aave from MatrixToken. Allows MatrixToken to enable/disable a specific deposited asset as collateral.
     *
     * @param matrixToken        Address of the MatrixToken
     * @param lendingPool        Address of the LendingPool contract
     * @param asset              The address of the underlying asset deposited
     * @param useAsCollateral    true` if the user wants to use the deposit as collateral, `false` otherwise
     */
    function invokeSetUserUseReserveAsCollateral(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        bool useAsCollateral
    ) external {
        (address target, , bytes memory callData) = getSetUserUseReserveAsCollateralCalldata(lendingPool, asset, useAsCollateral);

        matrixToken.invoke(target, 0, callData);
    }

    /**
     * @dev Get swapBorrowRate calldata from MatrixToken. Allows a borrower to toggle his debt between stable and variable mode.
     *
     * @param lendingPool    Address of the LendingPool contract
     * @param asset          The address of the underlying asset borrowed
     * @param rateMode       The rate mode that the user wants to swap to
     *
     * @return target        Target contract address
     * @return value         Call value
     * @return callData      SwapBorrowRate calldata
     */
    function getSwapBorrowRateModeCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 rateMode
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // swapBorrowRateMode(address asset, uint256 rateMode)
        callData = abi.encodeWithSignature("swapBorrowRateMode(address,uint256)", asset, rateMode);
    }

    /**
     * @dev Invoke to swap borrow rate of MatrixToken. Allows MatrixToken to toggle it's debt between stable and variable mode.
     *
     * @param matrixToken    Address of the MatrixToken
     * @param lendingPool    Address of the LendingPool contract
     * @param asset          The address of the underlying asset borrowed
     * @param rateMode       The rate mode that the user wants to swap to
     */
    function invokeSwapBorrowRateMode(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 rateMode
    ) external {
        (address target, , bytes memory callData) = getSwapBorrowRateModeCalldata(lendingPool, asset, rateMode);

        matrixToken.invoke(target, 0, callData);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { DataTypes } from "../../../external/aave-v2/lib/DataTypes.sol";

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";

/**
 * @title ILendingPool
 * @author Aave
 */
interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   */
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
   */
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
   */
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
   */
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
   */
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

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
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   */
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
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
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
   */
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

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
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   */
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
   */
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   */
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   */
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
   */
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
   */
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
   */
  function getUserAccountData(address user)
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

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

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
   */
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixToken
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit    Virtual value of a component's EXTERNAL position.
     * @param data           Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and  virtual units.
     *
     * @param virtualUnit                Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units
     *                                   at once via the position multiplier. Virtual units are achieved by dividing a real value by the positionMultiplier
     * @param externalPositionModules    Eexternal modules attached to each external position. Each module maps to an external position
     * @param externalPositions          Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== Events ====================

    event Invoke(address indexed target, uint256 indexed value, bytes data, bytes returnValue);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event InitializeModule(address indexed module);
    event EditManager(address newManager, address oldManager);
    event RemovePendingModule(address indexed module);
    event EditPositionMultiplier(int256 newMultiplier);
    event AddComponent(address indexed component);
    event RemoveComponent(address indexed component);
    event EditDefaultPositionUnit(address indexed component, int256 realUnit);
    event EditExternalPositionUnit(address indexed component, address indexed positionModule, int256 realUnit);
    event EditExternalPositionData(address indexed component, address indexed positionModule, bytes data);
    event AddPositionModule(address indexed component, address indexed positionModule);
    event RemovePositionModule(address indexed component, address indexed positionModule);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(
        address component,
        address positionModule,
        int256 realUnit
    ) external;

    function editExternalPositionData(
        address component,
        address positionModule,
        bytes calldata data
    ) external;

    function invoke(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    function invokeSafeApprove(
        address token,
        address spender,
        uint256 amount
    ) external;

    function invokeSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeExactSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/types/DataTypes.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

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

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

/**
 * @title ILendingPoolAddressesProvider
 * @author Aave
 *
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 */

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