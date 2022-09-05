//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITestERC20.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IOzillaGlobals.sol";
import "../interfaces/IPoolHedger.sol";
import "../synthetix/SafeDecimalMath.sol";

contract TestLendingPool is ILendingPool {

    bool initialized = false;
    ITestERC20 internal quoteAsset;
    ITestERC20 internal baseAsset;
    IPoolHedger internal poolHedger;
    uint debt = 0;

    function init(IOzillaGlobals _globals, IPoolHedger _poolHedger, ITestERC20 _quoteAsset, ITestERC20 _baseAsset) external {
        require(!initialized, "contract already initialized");
        quoteAsset = _quoteAsset;
        baseAsset = _baseAsset;
        poolHedger = _poolHedger;
        initialized = true;
    }

    /**
 * @dev mock lending to the poolHedeger.
   *
   * @param amount to lend to the poolHedger.
   */
    function lend(uint amount) external override onlyPoolHedger returns (uint) {
        baseAsset.mint(address(poolHedger), amount);
        debt = debt + amount;
        return debt;
    }

    /**
 * @dev mock repaying to the poolHedeger.
   */
    function repay() external override onlyPoolHedger returns (uint) {
        uint bal = baseAsset.balanceOf(address(poolHedger));
        uint baseToBurn = bal > debt ? debt : bal;
        baseAsset.burn(msg.sender, baseToBurn);
        debt = debt - baseToBurn;
        return debt;
    }

    function getShortPosition() external view override returns (uint) {
        return debt;
    }

    modifier onlyPoolHedger virtual {
        require(msg.sender == address(poolHedger), "Only PoolHedger");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITestERC20 is IERC20 {
    function mint(address account, uint amount) external;

    function burn(address account, uint amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    //    /**
    //     * @dev Emitted on deposit()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address initiating the deposit
    //   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
    //   * @param amount The amount deposited
    //   * @param referral The referral code used
    //   **/
    //    event Deposit(
    //        address indexed reserve,
    //        address user,
    //        address indexed onBehalfOf,
    //        uint256 amount,
    //        uint16 indexed referral
    //    );
    //
    //    /**
    //     * @dev Emitted on withdraw()
    //   * @param reserve The address of the underlyng asset being withdrawn
    //   * @param user The address initiating the withdrawal, owner of aTokens
    //   * @param to Address that will receive the underlying
    //   * @param amount The amount to be withdrawn
    //   **/
    //    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
    //
    //    /**
    //     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
    //   * @param reserve The address of the underlying asset being borrowed
    //   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
    //   * initiator of the transaction on flashLoan()
    //   * @param onBehalfOf The address that will be getting the debt
    //   * @param amount The amount borrowed out
    //   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
    //   * @param borrowRate The numeric rate at which the user has borrowed
    //   * @param referral The referral code used
    //   **/
    //    event Borrow(
    //        address indexed reserve,
    //        address user,
    //        address indexed onBehalfOf,
    //        uint256 amount,
    //        uint256 borrowRateMode,
    //        uint256 borrowRate,
    //        uint16 indexed referral
    //    );
    //
    //    /**
    //     * @dev Emitted on repay()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The beneficiary of the repayment, getting his debt reduced
    //   * @param repayer The address of the user initiating the repay(), providing the funds
    //   * @param amount The amount repaid
    //   **/
    //    event Repay(
    //        address indexed reserve,
    //        address indexed user,
    //        address indexed repayer,
    //        uint256 amount
    //    );
    //
    //    /**
    //     * @dev Emitted on swapBorrowRateMode()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user swapping his rate mode
    //   * @param rateMode The rate mode that the user wants to swap to
    //   **/
    //    event Swap(address indexed reserve, address indexed user, uint256 rateMode);
    //
    //    /**
    //     * @dev Emitted on setUserUseReserveAsCollateral()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user enabling the usage as collateral
    //   **/
    //    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    //
    //    /**
    //     * @dev Emitted on setUserUseReserveAsCollateral()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user enabling the usage as collateral
    //   **/
    //    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
    //
    //    /**
    //     * @dev Emitted on rebalanceStableBorrowRate()
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param user The address of the user for which the rebalance has been executed
    //   **/
    //    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
    //
    //    /**
    //     * @dev Emitted on flashLoan()
    //   * @param target The address of the flash loan receiver contract
    //   * @param initiator The address initiating the flash loan
    //   * @param asset The address of the asset being flash borrowed
    //   * @param amount The amount flash borrowed
    //   * @param premium The fee flash borrowed
    //   * @param referralCode The referral code used
    //   **/
    //    event FlashLoan(
    //        address indexed target,
    //        address indexed initiator,
    //        address indexed asset,
    //        uint256 amount,
    //        uint256 premium,
    //        uint16 referralCode
    //    );
    //
    //    /**
    //     * @dev Emitted when the pause is triggered.
    //   */
    //    event Paused();
    //
    //    /**
    //     * @dev Emitted when the pause is lifted.
    //   */
    //    event Unpaused();
    //
    //    /**
    //     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
    //   * LendingPoolCollateral manager using a DELEGATECALL
    //   * This allows to have the events in the generated ABI for LendingPool.
    //   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
    //   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
    //   * @param user The address of the borrower getting liquidated
    //   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
    //   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
    //   * @param liquidator The address of the liquidator
    //   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
    //   * to receive the underlying collateral asset directly
    //   **/
    //    event LiquidationCall(
    //        address indexed collateralAsset,
    //        address indexed debtAsset,
    //        address indexed user,
    //        uint256 debtToCover,
    //        uint256 liquidatedCollateralAmount,
    //        address liquidator,
    //        bool receiveAToken
    //    );
    //
    //    /**
    //     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
    //   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
    //   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
    //   * gets added to the LendingPool ABI
    //   * @param reserve The address of the underlying asset of the reserve
    //   * @param liquidityRate The new liquidity rate
    //   * @param stableBorrowRate The new stable borrow rate
    //   * @param variableBorrowRate The new variable borrow rate
    //   * @param liquidityIndex The new liquidity index
    //   * @param variableBorrowIndex The new variable borrow index
    //   **/
    //    event ReserveDataUpdated(
    //        address indexed reserve,
    //        uint256 liquidityRate,
    //        uint256 stableBorrowRate,
    //        uint256 variableBorrowRate,
    //        uint256 liquidityIndex,
    //        uint256 variableBorrowIndex
    //    );
    //
    //    /**
    //     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    //   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    //   * @param asset The address of the underlying asset to deposit
    //   * @param amount The amount to be deposited
    //   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    //   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    //   *   is a different wallet
    //   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    //   *   0 if the action is executed directly by the user, without any middle-man
    //   **/
    //    function deposit(
    //        address asset,
    //        uint256 amount,
    //        address onBehalfOf,
    //        uint16 referralCode
    //    ) external;
    //
    //    /**
    //     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    //   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    //   * @param asset The address of the underlying asset to withdraw
    //   * @param amount The underlying amount to be withdrawn
    //   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    //   * @param to Address that will receive the underlying, same as msg.sender if the user
    //   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    //   *   different wallet
    //   * @return The final amount withdrawn
    //   **/
    //    function withdraw(
    //        address asset,
    //        uint256 amount,
    //        address to
    //    ) external returns (uint256);
    //
    //    /**
    //     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    //   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
    //   * corresponding debt token (StableDebtToken or VariableDebtToken)
    //   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
    //   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
    //   * @param asset The address of the underlying asset to borrow
    //   * @param amount The amount to be borrowed
    //   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    //   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    //   *   0 if the action is executed directly by the user, without any middle-man
    //   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
    //   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
    //   * if he has been given credit delegation allowance
    //   **/
    //    function borrow(
    //        address asset,
    //        uint256 amount,
    //        uint256 interestRateMode,
    //        uint16 referralCode,
    //        address onBehalfOf
    //    ) external;
    //
    //    /**
    //     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    //   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
    //   * @param asset The address of the borrowed underlying asset previously borrowed
    //   * @param amount The amount to repay
    //   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
    //   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    //   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
    //   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    //   * other borrower whose debt should be removed
    //   * @return The final amount repaid
    //   **/
    //    function repay(
    //        address asset,
    //        uint256 amount,
    //        uint256 rateMode,
    //        address onBehalfOf
    //    ) external returns (uint256);
    //
    //    /**
    //     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
    //   * @param asset The address of the underlying asset borrowed
    //   * @param rateMode The rate mode that the user wants to swap to
    //   **/
    //    function swapBorrowRateMode(address asset, uint256 rateMode) external;
    //
    //    /**
    //     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
    //   * - Users can be rebalanced if the following conditions are satisfied:
    //   *     1. Usage ratio is above 95%
    //   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
    //   *        borrowed at a stable rate and depositors are not earning enough
    //   * @param asset The address of the underlying asset borrowed
    //   * @param user The address of the user to be rebalanced
    //   **/
    //    function rebalanceStableBorrowRate(address asset, address user) external;
    //
    //    /**
    //     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
    //   * @param asset The address of the underlying asset deposited
    //   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
    //   **/
    //    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
    //
    //    /**
    //     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
    //   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
    //   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
    //   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
    //   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
    //   * @param user The address of the borrower getting liquidated
    //   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
    //   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
    //   * to receive the underlying collateral asset directly
    //   **/
    //    function liquidationCall(
    //        address collateralAsset,
    //        address debtAsset,
    //        address user,
    //        uint256 debtToCover,
    //        bool receiveAToken
    //    ) external;
    //
    //    /**
    //     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
    //   * as long as the amount taken plus a fee is returned.
    //   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
    //   * For further details please visit https://developers.aave.com
    //   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
    //   * @param assets The addresses of the assets being flash-borrowed
    //   * @param amounts The amounts amounts being flash-borrowed
    //   * @param modes Types of the debt to open if the flash loan is not returned:
    //   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
    //   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
    //   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
    //   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
    //   * @param params Variadic packed params to pass to the receiver as extra information
    //   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    //   *   0 if the action is executed directly by the user, without any middle-man
    //   **/
    //    function flashLoan(
    //        address receiverAddress,
    //        address[] calldata assets,
    //        uint256[] calldata amounts,
    //        uint256[] calldata modes,
    //        address onBehalfOf,
    //        bytes calldata params,
    //        uint16 referralCode
    //    ) external;
    //
    //    /**
    //     * @dev Returns the user account data across all the reserves
    //   * @param user The address of the user
    //   * @return totalCollateralETH the total collateral in ETH of the user
    //   * @return totalDebtETH the total debt in ETH of the user
    //   * @return availableBorrowsETH the borrowing power left of the user
    //   * @return currentLiquidationThreshold the liquidation threshold of the user
    //   * @return ltv the loan to value of the user
    //   * @return healthFactor the current health factor of the user
    //   **/
    //    function getUserAccountData(address user)
    //    external
    //    view
    //    returns (
    //        uint256 totalCollateralETH,
    //        uint256 totalDebtETH,
    //        uint256 availableBorrowsETH,
    //        uint256 currentLiquidationThreshold,
    //        uint256 ltv,
    //        uint256 healthFactor
    //    );
    //
    //    function initReserve(
    //        address reserve,
    //        address aTokenAddress,
    //        address stableDebtAddress,
    //        address variableDebtAddress,
    //        address interestRateStrategyAddress
    //    ) external;
    //
    //    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    //    external;
    //
    //    function setConfiguration(address reserve, uint256 configuration) external;
    //
    //    /**
    //     * @dev Returns the normalized income normalized income of the reserve
    //   * @param asset The address of the underlying asset of the reserve
    //   * @return The reserve's normalized income
    //   */
    //    function getReserveNormalizedIncome(address asset) external view returns (uint256);
    //
    //    /**
    //     * @dev Returns the normalized variable debt per unit of asset
    //   * @param asset The address of the underlying asset of the reserve
    //   * @return The reserve normalized variable debt
    //   */
    //    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);
    //
    //    function finalizeTransfer(
    //        address asset,
    //        address from,
    //        address to,
    //        uint256 amount,
    //        uint256 balanceFromAfter,
    //        uint256 balanceToBefore
    //    ) external;
    //
    //    function getReservesList() external view returns (address[] memory);
    //
    //    function setPause(bool val) external;
    //
    //    function paused() external view returns (bool);

    function lend(uint amount) external returns (uint);

    function repay() external returns (uint);

    function getShortPosition() external view returns (uint);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./ICollateralShort.sol";
import "./IExchangeRates.sol";
import "./IExchanger.sol";
import "./IUniswapV2Pair.sol";
import "./ILendingPool.sol";
import "./ISwapRouter.sol";

interface IOzillaGlobals {
    enum ExchangeType {BASE_QUOTE, QUOTE_BASE, ALL}

    /**
     * @dev Structs to help reduce the number of calls between other contracts and this one
   * Grouped in usage for a particular contract/use case
   */
    struct ExchangeGlobals {
        uint spotPrice;
        uint swapFee;
        address quoteAddress;
        address baseAddress;
        ISwapRouter swapRouter;
        ILendingPool lendingPool;
    }

    struct GreekCacheGlobals {
        int rateAndCarry;
        uint spotPrice;
    }

    struct PricingGlobals {
        uint optionPriceFeeCoefficient;
        uint spotPriceFeeCoefficient;
        uint vegaFeeCoefficient;
        uint vegaNormFactor;
        uint standardSize;
        uint skewAdjustmentFactor;
        int rateAndCarry;
        int minDelta;
        uint volatilityCutoff;
        uint spotPrice;
    }

    function swapRouter() external view returns (ISwapRouter);

    function exchanger() external view returns (IExchanger);

    function exchangeRates() external view returns (IExchangeRates);

    function lendingPool() external view returns (ILendingPool);

    function isPaused() external view returns (bool);

    function tradingCutoff(address) external view returns (uint);

    function swapFee(address) external view returns (uint);

    function optionPriceFeeCoefficient(address) external view returns (uint);

    function spotPriceFeeCoefficient(address) external view returns (uint);

    function vegaFeeCoefficient(address) external view returns (uint);

    function vegaNormFactor(address) external view returns (uint);

    function standardSize(address) external view returns (uint);

    function skewAdjustmentFactor(address) external view returns (uint);

    function rateAndCarry(address) external view returns (int);

    function minDelta(address) external view returns (int);

    function volatilityCutoff(address) external view returns (uint);

    function quoteMessage(address) external view returns (address);

    function baseMessage(address) external view returns (address);

    function setGlobals(ISwapRouter _swapRouter, ILendingPool _lendingPool) external;

    function setGlobalsForContract(
        address _contractAddress,
        uint _tradingCutoff,
        uint _swapFee,
        PricingGlobals memory pricingGlobals,
        address _quoteAddress,
        address _baseAddress
    ) external;

    function setPaused(bool _isPaused) external;

    function setTradingCutoff(address _contractAddress, uint _tradingCutoff) external;

    function setSwapFee(address _contractAddress, uint _swapFee) external;

    function setOptionPriceFeeCoefficient(address _contractAddress, uint _optionPriceFeeCoefficient) external;

    function setSpotPriceFeeCoefficient(address _contractAddress, uint _spotPriceFeeCoefficient) external;

    function setVegaFeeCoefficient(address _contractAddress, uint _vegaFeeCoefficient) external;

    function setVegaNormFactor(address _contractAddress, uint _vegaNormFactor) external;

    function setStandardSize(address _contractAddress, uint _standardSize) external;

    function setSkewAdjustmentFactor(address _contractAddress, uint _skewAdjustmentFactor) external;

    function setRateAndCarry(address _contractAddress, int _rateAndCarry) external;

    function setMinDelta(address _contractAddress, int _minDelta) external;

    function setVolatilityCutoff(address _contractAddress, uint _volatilityCutoff) external;

    function setQuoteMessage(address _contractAddress, address _quoteAddress) external;

    function setBaseMessage(address _contractAddress, address _baseAddress) external;

    function getSpotPriceForMarket(address _contractAddress) external view returns (uint);

    function getSpotPrice(address to) external view returns (uint256);

    function getPricingGlobals(address _contractAddress) external view returns (PricingGlobals memory);

    function getGreekCacheGlobals(address _contractAddress) external view returns (GreekCacheGlobals memory);

    function getExchangeGlobals(address _contractAddress) external view returns (ExchangeGlobals memory exchangeGlobals);

    function getGlobalsForOptionTrade(address _contractAddress)
    external
    view
    returns (
        PricingGlobals memory pricingGlobals,
        ExchangeGlobals memory exchangeGlobals,
        uint tradeCutoff
    );
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./ILendingPool.sol";

interface IPoolHedger {

    struct Debts {
        uint debtBaseToLiquidityPool;
        uint debtQuoteToLiquidityPool;
        uint debtBaseToShortCollateral;
        uint debtQuoteToShortCollateral;
    }

    function shortingInitialized() external view returns (bool);

    function shortId() external view returns (uint);

    function lastInteraction() external view returns (uint);

    function interactionDelay() external view returns (uint);

    function setInteractionDelay(uint newInteractionDelay) external;

    function hedgeDelta() external;

    function estimateHedge(ILendingPool lendingPool) external view returns (bool);

    function getValueQuote(ILendingPool lendingPool, uint spotPrice) external view returns (uint);
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity ^0.8.0;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/SafeDecimalMath/
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
   */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
   */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
   * precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and UNIT must be less than 2**256. As
   * this is an integer division, the result is always rounded down.
   * This helps save on gas. Rounding is more expensive on gas.
   */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
   */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
   */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

//SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

interface ICollateralShort {
    struct Loan {
        // ID for the loan
        uint id;
        //  Account that created the loan
        address account;
        //  Amount of collateral deposited
        uint collateral;
        // The synth that was borrowed
        address currency;
        //  Amount of synths borrowed
        uint amount;
        // Indicates if the position was short sold
        bool short;
        // interest amounts accrued
        uint accruedInterest;
        // last interest index
        uint interestIndex;
        // time of last interaction.
        uint lastInteraction;
    }

    function loans(uint id)
    external
    returns (
        uint,
        address,
        uint,
        address,
        uint,
        bool,
        uint,
        uint,
        uint
    );

    function minCratio() external returns (uint);

    function minCollateral() external returns (uint);

    function issueFeeRate() external returns (uint);

    function open(
        uint collateral,
        uint amount,
        address currency
    ) external returns (uint id);

    function repay(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint short, uint collateral);

    function repayWithCollateral(uint id, uint repayAmount) external returns (uint short, uint collateral);

    function draw(uint id, uint amount) external returns (uint short, uint collateral);

    // Same as before
    function deposit(
        address borrower,
        uint id,
        uint amount
    ) external returns (uint short, uint collateral);

    // Same as before
    function withdraw(uint id, uint amount) external returns (uint short, uint collateral);

    // function to return the loan details in one call, without needing to know about the collateralstate
    function getShortAndCollateral(address account, uint id) external view returns (uint short, uint collateral);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
    external
    view
    returns (uint exchangeFeeRate);
}

/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountIn The amount of the received token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint amountIn);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}