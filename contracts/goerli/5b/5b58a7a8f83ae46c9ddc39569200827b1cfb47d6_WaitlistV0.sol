// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/aave/interfaces/IAaveV2.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

// TODO: Apply slot packing + gas golf/optimization across all contracts
// TODO: Measure optimizations with Foundry
contract AaveLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ILendingPoolAddressesProvider internal aaveAddressesProvider;

    IProtocolDataProvider internal aaveProtocolDataProvider;

    IWETHGateway internal aaveIWETHGateway;

    address internal aWETH;

    /* ========== EVENTS ========== */

    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    event Withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    );

    /* ========== FUNCTIONS ========== */

    constructor(
        address _aaveAddressesProvider,
        address _aaveProtocolDataProvider,
        address _aaveIWETHGateway,
        address _aWETH
    ) Ownable() {
        aaveAddressesProvider = ILendingPoolAddressesProvider(
            _aaveAddressesProvider
        );
        aaveProtocolDataProvider = IProtocolDataProvider(
            _aaveProtocolDataProvider
        );
        aaveIWETHGateway = IWETHGateway(_aaveIWETHGateway);
        aWETH = _aWETH;
    }

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }

    function deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    ) external payable override returns (bool) {
        ILendingPool lendingPool = ILendingPool(
            aaveAddressesProvider.getLendingPool()
        );

        if (isNativeDeposit) {
            aaveIWETHGateway.depositETH{value: msg.value}(
                address(lendingPool),
                msg.sender,
                0
            );

            emit Deposit(isNativeDeposit, reserveTokenAddress, msg.value);
        } else {
            IERC20(reserveTokenAddress).transferFrom(
                msg.sender,
                address(this),
                depositAmount
            );

            IERC20(reserveTokenAddress).approve(
                address(lendingPool),
                depositAmount
            );

            lendingPool.deposit(
                reserveTokenAddress,
                depositAmount,
                msg.sender,
                0
            );
            emit Deposit(isNativeDeposit, reserveTokenAddress, depositAmount);
        }

        return true;
    }

    function withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    ) external override returns (bool) {
        ILendingPool lendingPool = ILendingPool(
            aaveAddressesProvider.getLendingPool()
        );

        if (isNativeWithdraw) {
            IERC20(aWETH).transferFrom(
                msg.sender,
                address(this),
                withdrawAmount
            );

            IERC20(aWETH).approve(address(aaveIWETHGateway), withdrawAmount);

            aaveIWETHGateway.withdrawETH(
                address(lendingPool),
                withdrawAmount,
                msg.sender
            );
        } else {
            (address aTokenAddress, , ) = aaveProtocolDataProvider
                .getReserveTokensAddresses(reserveTokenAddress);

            IERC20(aTokenAddress).transferFrom(
                msg.sender,
                address(this),
                withdrawAmount
            );

            IERC20(aTokenAddress).approve(
                address(aaveIWETHGateway),
                withdrawAmount
            );

            lendingPool.withdraw(
                reserveTokenAddress,
                withdrawAmount,
                msg.sender
            );
        }

        emit Withdraw(isNativeWithdraw, reserveTokenAddress, withdrawAmount);

        return true;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12 <0.9.0;

import "../../openzeppelin/IERC20.sol";

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

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
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
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

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
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

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
     **/
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
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

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
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function ADDRESSES_PROVIDER()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

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

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
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

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

interface IAToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount)
        external
        returns (uint256);
}

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address lendingPool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address lendingPool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

interface ILendingYieldManager {
    function deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    ) external payable returns (bool);

    function withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    ) external returns (bool);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/compound/interfaces/ICompound.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract IronBankLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    mapping(address => address) reserveTokenToIToken;

    mapping(address => uint256) erc20Deposits;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    event Withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    );

    /* ========== FUNCTIONS ========== */

    constructor() Ownable() {}

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }

    function updatereserveTokenToIToken(address reserveToken, address iToken)
        public
        onlyOwner
    {
        reserveTokenToIToken[reserveToken] = iToken;
    }

    // TODO: Implement depositing and withdrawing opt-in depositor's reserve funds
    function deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    ) external payable override returns (bool) {
        require(
            !isNativeDeposit,
            "Iron Bank does not accept the network's native asset."
        );

        IERC20 reserveToken = IERC20(reserveTokenAddress); // get a handle for the underlying asset contract
        address iTokenAddress = reserveTokenToIToken[reserveTokenAddress];
        require(
            iTokenAddress != address(0),
            "IToken mapping does not exist for the given reserveTokenAddress"
        );

        reserveToken.transferFrom(msg.sender, address(this), depositAmount);

        CTokenInterface iToken = CTokenInterface(iTokenAddress);

        reserveToken.approve(address(iToken), depositAmount); // approve the transfer

        require(iToken.mint(depositAmount) == 0, "Failed to mint iToken(s)");

        iToken.transfer(msg.sender, iToken.balanceOf(address(this)));

        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].add(
            depositAmount
        );

        return true;
    }

    /// @notice withdrawAmount must be the amount of iTokens
    /// that will be redeemed, not the initial deposit amount.
    function withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    ) external override returns (bool) {
        require(
            !isNativeWithdraw,
            "Iron Bank does not accept the network's native asset."
        );
        require(
            erc20Deposits[msg.sender] >= withdrawAmount,
            "withdrawAmount > depositAmount"
        );

        IERC20 reserveToken = IERC20(reserveTokenAddress); // get a handle for the underlying asset contract
        address iTokenAddress = reserveTokenToIToken[reserveTokenAddress];
        require(
            iTokenAddress != address(0),
            "IToken mapping does not exist for the given reserveTokenAddress"
        );

        CTokenInterface iToken = CTokenInterface(iTokenAddress);
        uint256 initialBalance = iToken.balanceOf(address(this));

        require(
            iToken.redeem(withdrawAmount) == 0,
            "Failed to withdraw iTokens"
        );

        uint256 balanceDiff = iToken.balanceOf(address(this)).sub(
            initialBalance
        );

        reserveToken.transfer(msg.sender, balanceDiff);

        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].sub(
            withdrawAmount
        );

        return true;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        virtual
        returns (uint256[] memory);

    function exitMarket(address cToken) external virtual returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external virtual returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external virtual;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external virtual returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external virtual;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external virtual;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external virtual;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view virtual returns (uint256, uint256);
}

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view virtual returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view virtual returns (uint256);
}

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    // Official record of token balances for each account
    mapping(address => uint256) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(
        ComptrollerInterface oldComptroller,
        ComptrollerInterface newComptroller
    );

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(
        InterestRateModel oldInterestRateModel,
        InterestRateModel newInterestRateModel
    );

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*** User Interface ***/

    function transfer(address dst, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256);

    function balanceOfUnderlying(address owner)
        external
        virtual
        returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view virtual returns (uint256);

    function supplyRatePerBlock() external view virtual returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function borrowBalanceCurrent(address account)
        external
        virtual
        returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        virtual
        returns (uint256);

    function exchangeRateCurrent() external virtual returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function getCash() external view virtual returns (uint256);

    function accrueInterest() external virtual returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    function mint(uint256 mintAmount) external virtual returns (uint256);

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount)
        external
        virtual
        returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);

    function repayBorrow(uint256 repayAmount)
        external
        virtual
        returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        virtual
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        CTokenInterface cTokenCollateral
    ) external virtual returns (uint256);

    function sweepToken(EIP20NonStandardInterface token) external virtual;

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin)
        external
        virtual
        returns (uint256);

    function _acceptAdmin() external virtual returns (uint256);

    function _setComptroller(ComptrollerInterface newComptroller)
        external
        virtual
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        virtual
        returns (uint256);

    function _reduceReserves(uint256 reduceAmount)
        external
        virtual
        returns (uint256);

    function _setInterestRateModel(InterestRateModel newInterestRateModel)
        external
        virtual
        returns (uint256);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount)
        external
        returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);
}

abstract contract CErc20Interface is CErc20Storage {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external virtual returns (uint256);

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount)
        external
        virtual
        returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);

    function repayBorrow(uint256 repayAmount)
        external
        virtual
        returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        virtual
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        CTokenInterface cTokenCollateral
    ) external virtual returns (uint256);

    function sweepToken(EIP20NonStandardInterface token) external virtual;

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/openzeppelin/EnumerableMap.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

contract WaitlistV0 is Pausable, Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    EnumerableMap.AddressToUintMap private waitlist;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted when an emergency withdraw occurs
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event Withdraw(address owner, uint256 amount);

    /* ========== FUNCTIONS ========== */
    constructor() {}

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalInWaitList() public view returns (uint256) {
        return EnumerableMap.length(waitlist);
    }

    function join() public whenNotPaused {
        (bool success, ) = EnumerableMap.tryGet(waitlist, msg.sender);
        require(!success, "Already joined.");

        success = EnumerableMap.set(waitlist, msg.sender, 1);
        require(success, "Failed to join waitlist");
    }

    function hasEntered(address target) public view returns (bool success) {
        (success, ) = EnumerableMap.tryGet(waitlist, target);
    }

    /// @notice withdraw Self-explanatory
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

    /// @notice withdrawERC20 recovers any erc20 tokens locked in the contract
    /// @param tokenAddress Self-explanatory
    /// @param tokenAmount Self-explanatory
    function withdrawERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Withdraw(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        returns (bool)
    {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bool)
    {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map)
        internal
        view
        returns (uint256)
    {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index)
        internal
        view
        returns (bytes32, bytes32)
    {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bool, bytes32)
    {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bytes32)
    {
        bytes32 value = map._values[key];
        require(
            value != 0 || contains(map, key),
            "EnumerableMap: nonexistent key"
        );
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index)
        internal
        view
        returns (uint256, uint256)
    {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (bool, uint256)
    {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key)
        internal
        view
        returns (uint256)
    {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool, address)
    {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return
            address(
                uint160(uint256(get(map._inner, bytes32(key), errorMessage)))
            );
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key)
        internal
        returns (bool)
    {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map)
        internal
        view
        returns (uint256)
    {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index)
        internal
        view
        returns (address, uint256)
    {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key)
        internal
        view
        returns (bool, uint256)
    {
        (bool success, bytes32 value) = tryGet(
            map._inner,
            bytes32(uint256(uint160(key)))
        );
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key)
        internal
        view
        returns (uint256)
    {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return
            uint256(
                get(map._inner, bytes32(uint256(uint160(key))), errorMessage)
            );
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key)
        internal
        returns (bool)
    {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key)
        internal
        view
        returns (bool)
    {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map)
        internal
        view
        returns (uint256)
    {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index)
        internal
        view
        returns (bytes32, uint256)
    {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key)
        internal
        view
        returns (bool, uint256)
    {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key)
        internal
        view
        returns (uint256)
    {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
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
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
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
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/euler/interfaces/IEuler.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract EulerLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    address internal eulerMainContract;

    address internal eulerMarketsContract;

    mapping(address => uint256) erc20Deposits;

    /* ========== EVENTS ========== */

    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    event Withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    );

    /* ========== FUNCTIONS ========== */

    constructor(address _eulerMainContract, address _eulerMarketsContract)
        Ownable()
    {
        eulerMainContract = _eulerMainContract;
        eulerMarketsContract = _eulerMarketsContract;
    }

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }

    event MyLog(string, uint256);

    function deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    ) external payable override returns (bool) {
        require(!isNativeDeposit, "Manager does not accept native deposits");
        // Approve the main euler contract to pull your tokens:
        IERC20(reserveTokenAddress).approve(eulerMainContract, depositAmount);

        // Fetch the funds from the sender in order to deposit into the Euler reserve:
        IERC20(reserveTokenAddress).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );

        // Use the markets module:
        IEulerMarkets markets = IEulerMarkets(eulerMarketsContract);

        // Get the eToken address using the markets module:
        IEulerEToken eToken = IEulerEToken(
            markets.underlyingToEToken(reserveTokenAddress)
        );

        // The "0" argument refers to the sub-account you are depositing to.
        eToken.deposit(0, depositAmount);

        // Keep track of euler deposits:
        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].add(
            depositAmount
        );

        // Transfer the minted eTokens:
        eToken.transfer(msg.sender, eToken.balanceOf(address(this)));

        emit Deposit(false, reserveTokenAddress, depositAmount);

        return true;
    }

    /// @notice withdrawAmount must be the amount of eTokens
    /// that will be redeemed, not the initial deposit amount.
    function withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    ) external override returns (bool) {
        // Make sure they can withdraw that amount
        require(
            erc20Deposits[msg.sender] >= withdrawAmount,
            "withdraw amount > deposit amount"
        );

        // Use the markets module:
        IEulerMarkets markets = IEulerMarkets(eulerMarketsContract);

        // Get the eToken address using the markets module:
        IEulerEToken eToken = IEulerEToken(
            markets.underlyingToEToken(reserveTokenAddress)
        );

        // Fetch the funds from the sender in order to deposit into the Euler reserve:
        eToken.transferFrom(msg.sender, address(this), withdrawAmount);

        uint256 initialReserveTokenBalance = IERC20(reserveTokenAddress)
            .balanceOf(address(this));

        // Later on, withdraw your initial deposit and all earned interest:
        eToken.withdraw(0, withdrawAmount);

        uint256 postReserveTokenBalance = IERC20(reserveTokenAddress).balanceOf(
            address(this)
        );
        uint256 diff = postReserveTokenBalance.sub(initialReserveTokenBalance);

        // Transfer over the difference:
        IERC20(reserveTokenAddress).transfer(msg.sender, diff);

        // Update msg.sender's deposit
        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].sub(
            withdrawAmount
        );

        emit Withdraw(isNativeWithdraw, reserveTokenAddress, withdrawAmount);

        return true;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface IEulerMarkets {
    function underlyingToEToken(address underlying)
        external
        view
        returns (address);
}

interface IEulerEToken {
    function deposit(uint256 subAccountId, uint256 amount) external;

    function withdraw(uint256 subAccountId, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function balanceOfUnderlying(address account)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./CoreReserve.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract CoreReserveFactory is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== TYPE DECLARATIONS ========== */

    /// @dev CreateReserveParams is a data structure containing createReserve request data.
    struct CreateReserveParams {
        CoreReserve.ReserveType reserveType;
        bool isNativeTokenReserve;
        address reserveToken;
        uint256 reserveTokenInitialAmount;
        address coreFundReserveAddress;
        bool earnYieldOnDeposit;
        address lendingYieldManager;
    }

    /* ========== STATE VARIABLES ========== */

    address payable public coreTreasuryAddress;

    address payable public coreRewardsDistributorAddress;

    address payable public coreFlashLoanParamsAddress;

    address[] public reserves;

    mapping(uint256 => address) public reserveForIndex;

    mapping(address => address) public reserveForReserveToken;

    uint256 public nextReserveIndex;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ReserveCreated(
        CoreReserve.ReserveType reserveType,
        bool isNativeTokenReserve,
        address reserveToken,
        uint256 initialDepositAmount,
        uint256 blockTimestamp
    );

    event ReservePaused(address reserve, uint256 reserveIndex);

    event ReserveUnpaused(address reserve, uint256 reserveIndex);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /* ========== MODIFIERS ========== */

    /* ========== FUNCTIONS ========== */

    constructor(
        address _coreTreasuryAddress,
        address _coreRewardsDistributorAddress,
        address _coreFlashLoanParamsAddress
    ) Ownable() {
        coreTreasuryAddress = payable(_coreTreasuryAddress);
        coreRewardsDistributorAddress = payable(_coreRewardsDistributorAddress);
        coreFlashLoanParamsAddress = payable(_coreFlashLoanParamsAddress);
    }

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function createReserve(CreateReserveParams calldata params)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (address)
    {
        if (params.reserveType == CoreReserve.ReserveType.CHARITY) {
            require(
                msg.sender == owner(),
                "Only the owner can make charity reserves."
            );
        }

        CoreReserve.ReserveData memory reserveData;
        uint256 initialDepositAmount;

        reserveData.creator = msg.sender;
        reserveData.reserveType = params.reserveType;
        reserveData.isNativeTokenReserve = params.isNativeTokenReserve;
        reserveData.reserveToken = params.reserveToken;

        // NOTE: Keep in mind, the coreFundReserveAddress is address(0) when creating the initial core fund reserve
        CoreReserve newCoreReserve = new CoreReserve(
            params.coreFundReserveAddress,
            coreRewardsDistributorAddress,
            coreTreasuryAddress,
            coreFlashLoanParamsAddress,
            reserveData
        );
        address ncrAddress = address(newCoreReserve);

        if (params.isNativeTokenReserve) {
            require(
                msg.sender == owner(),
                "Only the owner can create native reserves"
            );

            initialDepositAmount = msg.value;

            require(
                initialDepositAmount > 0,
                "Native token deposit value must be > 0"
            );

            bool success = newCoreReserve.deposit{value: msg.value}(
                msg.value,
                params.earnYieldOnDeposit,
                params.lendingYieldManager
            );
            require(
                success,
                "Failed to deposit initialDepositAmount into new CoreReserve contract"
            );
        } else {
            require(
                reserveForReserveToken[params.reserveToken] == address(0),
                "A reserve exists for the given reserve token."
            );
            require(
                params.reserveToken != address(0),
                "Invalid reserve token address"
            );

            initialDepositAmount = params.reserveTokenInitialAmount;

            IERC20 erc20Token = IERC20(params.reserveToken);

            require(
                erc20Token.balanceOf(msg.sender) >= initialDepositAmount,
                "Reserve token personal balance must be >= initialDepositAmount"
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) > 0,
                "Please approve the contract to transfer the reserve token."
            );

            erc20Token.transferFrom(
                msg.sender,
                ncrAddress,
                initialDepositAmount
            );

            reserveForReserveToken[params.reserveToken] = ncrAddress;
        }

        reserves.push(ncrAddress);

        reserveForIndex[nextReserveIndex] = ncrAddress;
        nextReserveIndex = nextReserveIndex.add(1);

        emit ReserveCreated(
            params.reserveType,
            params.isNativeTokenReserve,
            params.reserveToken,
            initialDepositAmount,
            block.timestamp
        );

        return ncrAddress;
    }

    function pauseReserve(uint256 reserveIndex)
        public
        onlyOwner
        returns (bool)
    {
        CoreReserve reserve = CoreReserve(
            payable(reserveForIndex[reserveIndex])
        );

        reserve.pause();

        emit ReservePaused(address(reserve), reserveIndex);

        return true;
    }

    function unpauseReserve(uint256 reserveIndex)
        public
        onlyOwner
        returns (bool)
    {
        CoreReserve reserve = CoreReserve(
            payable(reserveForIndex[reserveIndex])
        );

        reserve.unpause();

        emit ReserveUnpaused(address(reserve), reserveIndex);

        return true;
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./CoreFlashLoanParams.sol";
import "./CoreReserve.sol";
import "./CoreRewardsDistributor.sol";
import "./dependencies/interfaces/IFlashLoanReceiver.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/EnumerableMap.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract CoreReserve is Pausable, ReentrancyGuard, Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== TYPE DECLARATIONS ========== */

    enum ReserveType {
        CHARITY,
        SNIPING
    }

    struct ReserveData {
        address creator;
        ReserveType reserveType;
        bool isNativeTokenReserve;
        address reserveToken;
    }

    struct FlashLoanParams {
        address receiver;
        uint256 amount;
        bytes params;
    }

    /* ========== STATE VARIABLES ========== */

    address payable public coreFundReserveAddress;

    address payable public coreRewardsDistributorAddress;

    address payable public coreTreasuryAddress;

    address payable public coreFlashLoanParamsAddress;

    ReserveData public reserveData;

    EnumerableMap.AddressToUintMap private nativeDeposits;

    EnumerableMap.AddressToUintMap private erc20Deposits;

    uint256 public lendingMarketDepositProportion;

    mapping(address => mapping(address => uint256)) lendingMarketDeposits;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ETHDeposit(
        address reserve,
        address depositor,
        uint256 amount,
        bool earnYieldOnDeposit,
        address lendingYieldManager
    );

    event ERC20Deposit(
        address reserve,
        address depositor,
        address reserveToken,
        uint256 amount,
        bool earnYieldOnDeposit,
        address lendingYieldManager
    );

    event ETHWithdrawnFromReserve(
        address reserve,
        address withdrawer,
        uint256 amount
    );

    event ERC20WithdrawnFromReserve(
        address reserve,
        address reserveToken,
        address withdrawer,
        uint256 amount
    );

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /* ========== MODIFIERS ========== */

    /* ========== FUNCTIONS ========== */

    constructor(
        address _coreFundReserveAddress,
        address _coreRewardsDistributorAddress,
        address _coreTreasuryAddress,
        address _coreFlashLoanParamsAddress,
        ReserveData memory _reserveData
    ) Ownable() {
        coreFundReserveAddress = payable(_coreFundReserveAddress);
        coreRewardsDistributorAddress = payable(_coreRewardsDistributorAddress);
        coreTreasuryAddress = payable(_coreTreasuryAddress);
        coreFlashLoanParamsAddress = payable(_coreFlashLoanParamsAddress);
        reserveData = _reserveData;
        if (!_reserveData.isNativeTokenReserve) {
            IERC20(_reserveData.reserveToken).approve(
                coreRewardsDistributorAddress,
                type(uint256).max
            );
        }

        // NOTE: Initially 50%
        lendingMarketDepositProportion = 50000;
    }

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateLendingMarketDepositProportion(
        uint256 _lendingMarketDepositProportion
    ) public onlyOwner {
        lendingMarketDepositProportion = _lendingMarketDepositProportion;
    }

    function totalNativeDeposits() public view returns (uint256) {
        return EnumerableMap.length(nativeDeposits);
    }

    function totalERC20Deposits() public view returns (uint256) {
        return EnumerableMap.length(erc20Deposits);
    }

    function nativeDepositAmountFor(address depositor)
        public
        view
        returns (uint256)
    {
        (bool success, uint256 amount) = EnumerableMap.tryGet(
            nativeDeposits,
            depositor
        );
        require(
            success,
            "Deposit amount not found for the given sender address"
        );
        return amount;
    }

    function erc20DepositAmountFor(address depositor)
        public
        view
        returns (uint256)
    {
        (bool success, uint256 amount) = EnumerableMap.tryGet(
            erc20Deposits,
            depositor
        );
        require(
            success,
            "Deposit amount not found for the given sender address"
        );
        return amount;
    }

    function nativeDepositEntryAt(uint256 index)
        public
        view
        returns (address, uint256)
    {
        return EnumerableMap.at(nativeDeposits, index);
    }

    function erc20DepositEntryAt(uint256 index)
        public
        view
        returns (address, uint256)
    {
        return EnumerableMap.at(erc20Deposits, index);
    }

    function deposit(
        uint256 depositAmount,
        bool earnYieldOnDeposit,
        address lendingYieldManagerAddress
    ) public payable nonReentrant whenNotPaused returns (bool) {
        bool isNativeTokenReserve = reserveData.isNativeTokenReserve;
        address reserveToken = reserveData.reserveToken;

        if (isNativeTokenReserve) {
            require(msg.value > 0, "Native token deposit value must be > 0");

            (bool success, uint256 amount) = EnumerableMap.tryGet(
                nativeDeposits,
                msg.sender
            );
            if (success) {
                EnumerableMap.set(
                    nativeDeposits,
                    msg.sender,
                    amount.add(msg.value)
                );
            } else {
                success = EnumerableMap.set(
                    nativeDeposits,
                    msg.sender,
                    msg.value
                );
                require(success, "Failed to update native deposits map");
            }

            if (earnYieldOnDeposit) {
                require(
                    lendingYieldManagerAddress != address(0),
                    "Invalid lendingYieldManager address"
                );

                // NOTE: 50% of deposit goes into the chosen lending yield reserve
                ILendingYieldManager lendingYieldManager = ILendingYieldManager(
                    lendingYieldManagerAddress
                );

                uint256 yieldDepositAmount = msg.value.mul(50000).div(10000);

                success = lendingYieldManager.deposit{
                    value: yieldDepositAmount
                }(true, address(0), yieldDepositAmount);
                require(
                    success,
                    "Failed to deposit funds into the given lending yield manager."
                );

                lendingMarketDeposits[msg.sender][
                    address(0)
                ] = lendingMarketDeposits[msg.sender][address(0)].add(
                    yieldDepositAmount
                );
            }

            emit ETHDeposit(
                address(this),
                msg.sender,
                msg.value,
                earnYieldOnDeposit,
                lendingYieldManagerAddress
            );
        } else {
            IERC20 erc20Token = IERC20(reserveToken);

            require(
                erc20Token.balanceOf(msg.sender) >= depositAmount,
                "Reserve token personal balance must be >= depositAmount"
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) > 0,
                "Please approve the contract to transfer the reserve token."
            );

            // NOTE: Sender must approve the reserve contract before executing a transaction
            erc20Token.transferFrom(msg.sender, address(this), depositAmount);

            (bool success, uint256 amount) = EnumerableMap.tryGet(
                erc20Deposits,
                msg.sender
            );
            if (success) {
                EnumerableMap.set(
                    erc20Deposits,
                    msg.sender,
                    amount.add(depositAmount)
                );
            } else {
                success = EnumerableMap.set(
                    erc20Deposits,
                    msg.sender,
                    depositAmount
                );
                require(success, "Failed to update erc20 deposits map");
            }

            if (earnYieldOnDeposit) {
                require(
                    lendingYieldManagerAddress != address(0),
                    "Invalid lendingYieldManager address"
                );

                // NOTE: 50% of deposit goes into the chosen lending yield reserve
                ILendingYieldManager lendingYieldManager = ILendingYieldManager(
                    lendingYieldManagerAddress
                );

                uint256 yieldDepositAmount = depositAmount.mul(50000).div(
                    10000
                );

                success = lendingYieldManager.deposit(
                    false,
                    reserveToken,
                    yieldDepositAmount
                );
                require(
                    success,
                    "Failed to deposit funds into the given lending yield manager."
                );

                lendingMarketDeposits[msg.sender][
                    reserveToken
                ] = lendingMarketDeposits[msg.sender][reserveToken].add(
                    yieldDepositAmount
                );
            }

            emit ERC20Deposit(
                address(this),
                msg.sender,
                reserveToken,
                depositAmount,
                earnYieldOnDeposit,
                lendingYieldManagerAddress
            );
        }

        return true;
    }

    function withdraw(uint256 withdrawAmount)
        public
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        bool isNativeTokenReserve = reserveData.isNativeTokenReserve;
        address reserveToken = reserveData.reserveToken;

        if (isNativeTokenReserve) {
            (bool success, uint256 depositAmount) = EnumerableMap.tryGet(
                nativeDeposits,
                msg.sender
            );
            require(
                success,
                "Deposit amount not found for the given sender address"
            );

            require(
                depositAmount >= withdrawAmount,
                "Your deposit/reserve balance must be >= withdrawAmount"
            );
            require(
                address(this).balance >= withdrawAmount,
                "Contract balance is less than withdrawAmount"
            );

            (bool sent, ) = address(msg.sender).call{value: withdrawAmount}("");
            require(sent, "Failed to send Ether");

            EnumerableMap.set(
                nativeDeposits,
                msg.sender,
                depositAmount.sub(withdrawAmount)
            );

            // TODO: Determine whether or not the current address has a yield deposit for the underlying reserve token
            // If so, withdraw from the yield protocol and return rewards to the current address.

            emit ETHWithdrawnFromReserve(
                address(this),
                msg.sender,
                withdrawAmount
            );
        } else {
            (bool success, uint256 depositAmount) = EnumerableMap.tryGet(
                erc20Deposits,
                msg.sender
            );
            require(
                success,
                "Deposit amount not found for the given sender address"
            );

            require(
                depositAmount >= withdrawAmount,
                "Your deposit/reserve balance must be >= withdrawAmount"
            );
            require(
                IERC20(reserveToken).balanceOf(address(this)) >= withdrawAmount,
                "Contract balance is less than withdrawAmount"
            );

            bool sent = IERC20(reserveToken).transfer(
                msg.sender,
                withdrawAmount
            );
            require(sent, "Failed to send native token");

            EnumerableMap.set(
                erc20Deposits,
                msg.sender,
                depositAmount.sub(withdrawAmount)
            );

            // TODO: Determine whether or not the current address has a yield deposit for the underlying reserve token
            // If so, withdraw from the yield protocol and return rewards to the current address.

            emit ERC20WithdrawnFromReserve(
                address(this),
                reserveToken,
                msg.sender,
                withdrawAmount
            );
        }

        return true;
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }

    function flashLoanETH(FlashLoanParams calldata params)
        public
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(
            address(this) != coreFundReserveAddress,
            "No entity can perform flash loans on the core fund reserve."
        );

        {
            (bool success, uint256 depositAmount) = EnumerableMap.tryGet(
                nativeDeposits,
                msg.sender
            );
            require(
                success,
                "Deposit amount not found for the given sender address"
            );
            require(
                depositAmount >= params.amount,
                "You must deposit >= the amount you want to use as a loan."
            );
        }

        ReserveType rType = reserveData.reserveType;
        bool isNativeTokenReserve = reserveData.isNativeTokenReserve;
        address reserveToken = reserveData.reserveToken;
        require(
            rType == ReserveType.SNIPING,
            "Only sniping reserves are eligible for flash loans."
        );

        require(
            params.amount > 0,
            "The loan amount must be greater than zero."
        );

        // Does the reserve have enough liquidity?
        uint256 liquidityBefore = isNativeTokenReserve
            ? address(this).balance
            : IERC20(reserveToken).balanceOf(address(this));

        require(
            liquidityBefore >= params.amount,
            "The reserve does not have enough liquidity for the loan amount."
        );

        // Compute fees (loan fee, protocol fee, fund fee/allocation)
        (
            uint256 amountFee,
            uint256 fundFee,
            uint256 lpRewardsFee,
            uint256 protocolFee
        ) = CoreFlashLoanParams(coreFlashLoanParamsAddress).getFlashLoanFees(
                params.amount
            );
        require(
            amountFee > 0 && protocolFee > 0 && fundFee > 0 && lpRewardsFee > 0,
            "The request amount is too small for a flashLoan given the fees applied"
        );

        // Transfer loan to the receiver
        {
            address payable userPayable = payable(
                address(uint160(params.receiver))
            );
            (bool success, ) = userPayable.call{
                value: params.amount,
                gas: 50000
            }("");
            require(success, "Failed to transfer native token to receiver.");
        }

        // Execute action/callback of the receiver
        {
            bool success = IFlashLoanReceiver(params.receiver).executeOperation(
                address(this),
                params.amount,
                amountFee,
                params.params
            );
            require(
                success,
                "Failed to execute external operation on flashLoanReceiver"
            );
        }

        // Make sure native token principal was sent back + amountFee
        uint256 liquidityAfter = address(this).balance;
        require(
            liquidityAfter >= liquidityBefore.add(amountFee),
            "Post flash loan, the condition must be resolved: liquidityAfter >= liquidityBefore + amountFee"
        );

        {
            // Transfer fund/charity fee to the Core Fund
            (bool success, ) = coreFundReserveAddress.call{value: fundFee}("");
            require(
                success,
                "Failed to transfer reserve token to the Core Fund Reserve."
            );

            // Transfer protocol fee to the Rewards Distributor for Depositors/LPs
            (success, ) = coreRewardsDistributorAddress.call{
                value: lpRewardsFee
            }("");
            require(
                success,
                "Failed to transfer reserve token to the Rewards Distributor."
            );

            // Transfer protocol fee to the Treasury
            (success, ) = coreTreasuryAddress.call{value: protocolFee}("");
            require(
                success,
                "Failed to transfer reserve token to the Treasury."
            );
        }

        return true;
    }

    function flashLoanERC20(FlashLoanParams calldata params)
        public
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(
            address(this) != coreFundReserveAddress,
            "No entity can perform flash loans on the core fund reserve."
        );

        {
            (bool success, uint256 depositAmount) = EnumerableMap.tryGet(
                erc20Deposits,
                msg.sender
            );
            require(
                success,
                "Deposit amount not found for the given sender address"
            );
            require(
                depositAmount >= params.amount,
                "You must deposit >= the amount you want to use as a loan."
            );
        }

        ReserveType rType = reserveData.reserveType;
        bool isNativeTokenReserve = reserveData.isNativeTokenReserve;
        address reserveToken = reserveData.reserveToken;
        require(
            rType == ReserveType.SNIPING,
            "Only sniping reserves are eligible for flash loans."
        );

        require(
            params.amount > 0,
            "The loan amount must be greater than zero."
        );

        // Does the reserve have enough liquidity?
        uint256 liquidityBefore = isNativeTokenReserve
            ? address(this).balance
            : IERC20(reserveToken).balanceOf(address(this));

        require(
            liquidityBefore >= params.amount,
            "The reserve does not have enough liquidity for the loan amount."
        );

        // Compute fees (loan fee, protocol fee, fund fee/allocation)
        (
            uint256 amountFee,
            uint256 fundFee,
            uint256 lpRewardsFee,
            uint256 protocolFee
        ) = CoreFlashLoanParams(coreFlashLoanParamsAddress).getFlashLoanFees(
                params.amount
            );
        require(
            amountFee > 0 && protocolFee > 0 && fundFee > 0 && lpRewardsFee > 0,
            "The request amount is too small for a flashLoan given the fees applied"
        );

        // Transfer loan to the receiver
        bool success = IERC20(reserveToken).transfer(
            params.receiver,
            params.amount
        );
        require(success, "Failed to transfer reserve token to receiver.");

        // Receiver must implement the flash loan interface; therefore, existing IFlashLoanReceiver instances can use this protocol :)
        // Execute action/callback of the receiver
        IFlashLoanReceiver(params.receiver).executeOperation(
            address(this),
            params.amount,
            amountFee,
            params.params
        );

        // Ensure that the amount deposited back into the reserve is correct + accounts for the amountFee
        uint256 liquidityAfter = IERC20(reserveToken).balanceOf(address(this));
        require(
            liquidityAfter >= liquidityBefore.add(amountFee),
            "The following condition must be resolved: liquidityAfter >= liquidityBefore + amountFee"
        );

        // Transfer fund/charity fee to the Core Fund
        success = IERC20(reserveToken).transfer(
            coreFundReserveAddress,
            fundFee
        );
        require(
            success,
            "Failed to transfer reserve token to the Core Fund Reserve."
        );

        // Transfer protocol fee to the Rewards Distributor for Depositors/LPs
        success = IERC20(reserveToken).transfer(
            coreRewardsDistributorAddress,
            lpRewardsFee
        );
        require(
            success,
            "Failed to transfer reserve token to the Rewards Distributor."
        );

        // Transfer protocol fee to the Treasury
        success = IERC20(reserveToken).transfer(
            coreTreasuryAddress,
            protocolFee
        );
        require(success, "Failed to transfer reserve token to the Treasury.");

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract CoreFlashLoanParams is Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256 public FLASHLOAN_FEE_TOTAL = 22;

    uint256 public FLASHLOAN_FEE_LP_REWARDS = 5000;

    uint256 public FLASHLOAN_FEE_FUND = 2500;

    uint256 public FLASHLOAN_FEE_PROTOCOL = 2000;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /* ========== FUNCTIONS ========== */

    constructor() Ownable() {}

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function getFlashLoanFees(uint256 amount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // 0.22%
        uint256 amountFee = amount.mul(FLASHLOAN_FEE_TOTAL).div(10000);
        // 50% of amountFee
        uint256 lpRewardsFee = amountFee.mul(FLASHLOAN_FEE_LP_REWARDS).div(
            10000
        );
        // 25% of amountFee
        uint256 fundFee = amountFee.mul(FLASHLOAN_FEE_FUND).div(10000);
        // 20% of amountFee
        uint256 protocolFee = amountFee.mul(FLASHLOAN_FEE_PROTOCOL).div(10000);
        return (amountFee, lpRewardsFee, fundFee, protocolFee);
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

import "./CoreReserve.sol";
import "./CoreReserveFactory.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract CoreRewardsDistributor is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address private extExecutor;

    address payable public coreReserveFactory;

    uint256 public distributionWaitingPeriod;

    uint256 public lastDistribution;

    // msg.sender => value
    mapping(address => uint256) public totalNativeEarned;

    // msg.sender => erc20 => value
    mapping(address => mapping(address => uint256)) public totalERC20Earned;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    event NewExternalExecutor(address updatedAddress, address updater);

    event NewDistributionWaitingPeriod(uint256 updatedPeriod, address updater);

    event NewCoreReserveFactory(address updatedAddress, address updater);

    event RewardDistributed(address to, uint256 amount, uint256 sentTimestamp);

    event DistributionCompleted(uint256 completionTimestamp);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /* ========== MODIFIERS ========== */

    modifier onlyOps() {
        require(msg.sender == owner() || msg.sender == extExecutor, "Only ops");
        _;
    }

    /* ========== FUNCTIONS ========== */

    constructor(address _extExecutor, address _coreReserveFactory) {
        // TODO: Create gelato whitelist for the executor address
        extExecutor = _extExecutor;
        coreReserveFactory = payable(_coreReserveFactory);
        lastDistribution = block.timestamp;
        // 2 weeks
        distributionWaitingPeriod = 1000 * 60 * 60 * 24 * 14;
    }

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setExtExecutor(address _extExecutor) public onlyOwner {
        extExecutor = _extExecutor;
        emit NewExternalExecutor(_extExecutor, msg.sender);
    }

    function setDistributionWaitingPeriod(uint256 _distributionWaitingPeriod)
        public
        onlyOwner
    {
        distributionWaitingPeriod = _distributionWaitingPeriod;
        emit NewDistributionWaitingPeriod(
            _distributionWaitingPeriod,
            msg.sender
        );
    }

    function setCoreReserveFactory(address _coreReserveFactory)
        public
        onlyOwner
    {
        coreReserveFactory = payable(_coreReserveFactory);
        emit NewCoreReserveFactory(_coreReserveFactory, msg.sender);
    }

    function canExecuteDistribution()
        external
        view
        onlyOps
        returns (bool canExec, bytes memory execPayload)
    {
        if (lastDistribution + distributionWaitingPeriod > block.timestamp) {
            return (
                false,
                bytes("Distribution waiting period is still active")
            );
        }
        execPayload = abi.encodeWithSelector(
            CoreRewardsDistributor.distributeRewards.selector
        );
    }

    function distributeRewards() external nonReentrant onlyOps returns (bool) {
        if (lastDistribution + distributionWaitingPeriod > block.timestamp) {
            return false;
        }
        // Periodic TX probably executed by a Gelato process
        CoreReserveFactory _coreReserveFactory = CoreReserveFactory(
            coreReserveFactory
        );
        uint256 nextReserveIndex = _coreReserveFactory.nextReserveIndex();
        uint256 i;

        // Need to iterate through each type of CoreReserve
        for (i = 1; i < nextReserveIndex; i++) {
            address reserveAddress = _coreReserveFactory.reserveForIndex(i);
            CoreReserve reserve = CoreReserve(payable(reserveAddress));

            // Get needed reserve data (reserveType, isNativeTokenReserve, reserveToken)
            (
                ,
                CoreReserve.ReserveType rType,
                bool isNativeTokenReserve,
                address reserveToken
            ) = reserve.reserveData();

            if (rType == CoreReserve.ReserveType.CHARITY) continue;

            // Need to iterate through each depositor for each type of reserve (Native + Non-Native)
            if (isNativeTokenReserve) {
                uint256 totalNativeBalance = address(reserve).balance;
                uint256 totalNativeDeposits = reserve.totalNativeDeposits();
                uint256 j;
                for (j = 0; j < totalNativeDeposits; j++) {
                    // Compute each depositor/LP reward proportional to their deposit
                    (address depositor, uint256 depositAmount) = reserve
                        .nativeDepositEntryAt(j);
                    uint256 rewardProportion = mulDiv(
                        depositAmount,
                        10000,
                        totalNativeBalance
                    );
                    uint256 rewardAmount = address(this)
                        .balance
                        .mul(rewardProportion)
                        .div(10000);

                    if (rewardAmount > 0) {
                        // Transfer that reward
                        address payable depositorPayable = payable(
                            address(uint160(depositor))
                        );
                        (bool success, ) = depositorPayable.call{
                            value: rewardAmount
                        }("");
                        require(
                            success,
                            "Failed to transfer reward to depositor"
                        );

                        totalNativeEarned[msg.sender] = totalNativeEarned[
                            msg.sender
                        ].add(rewardAmount);

                        emit RewardDistributed(
                            depositor,
                            rewardAmount,
                            block.timestamp
                        );
                    }
                }
            } else {
                uint256 totalERC20Balance = IERC20(reserveToken).balanceOf(
                    reserveAddress
                );
                uint256 totalERC20Deposits = reserve.totalERC20Deposits();
                uint256 j;
                for (j = 0; j < totalERC20Deposits; j++) {
                    (address depositor, uint256 depositAmount) = reserve
                        .erc20DepositEntryAt(j);
                    uint256 rewardProportion = mulDiv(
                        depositAmount,
                        10000,
                        totalERC20Balance
                    );
                    uint256 rewardAmount = IERC20(reserveToken)
                        .balanceOf(address(this))
                        .mul(rewardProportion)
                        .div(10000);
                    if (rewardAmount > 0) {
                        bool success = IERC20(reserveToken).transferFrom(
                            reserveAddress,
                            depositor,
                            rewardAmount
                        );
                        require(
                            success,
                            "Failed to transfer reward to depositor"
                        );

                        totalERC20Earned[msg.sender][
                            reserveToken
                        ] = totalERC20Earned[msg.sender][reserveToken].add(
                            rewardAmount
                        );

                        emit RewardDistributed(
                            depositor,
                            rewardAmount,
                            block.timestamp
                        );
                    }
                }
            }
        }

        // Update lastDistribution timestamp
        lastDistribution = block.timestamp;

        emit DistributionCompleted(lastDistribution);

        return true;
    }

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
        unchecked {
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

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

interface IFlashLoanReceiver {
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

contract CoreTreasury is Ownable {
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted when an emergency withdraw occurs
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event Withdraw(address owner, uint256 amount);

    /* ========== FUNCTIONS ========== */

    constructor() {}

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice withdraw Self-explanatory
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

    /// @notice withdrawERC20 recovers any erc20 tokens locked in the contract
    /// @param tokenAddress Self-explanatory
    /// @param tokenAmount Self-explanatory
    function withdrawERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Withdraw(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./dependencies/openzeppelin/ERC20.sol";

/*
 * @author 0xOrula
 * @notice SLToken is the SL governance token.
 */
contract SLToken is ERC20 {
    constructor() ERC20("SLToken", "SL") {
        _mint(msg.sender, 10000000);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/compound/interfaces/ICompound.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract CompoundLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    CEth cETH;

    mapping(address => address) reserveTokenToCToken;

    mapping(address => uint256) nativeDeposits;

    mapping(address => uint256) erc20Deposits;

    /* ========== EVENTS ========== */

    event ReceiveOrFallback(address caller, uint256 msgValue);

    event ETHEmergencyWithdraw(address owner, uint256 amounnt);

    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    event Withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    );

    /* ========== FUNCTIONS ========== */

    constructor(address _cETHContractAddress) Ownable() {
        cETH = CEth(_cETHContractAddress);
    }

    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    function emergencyWithdrawERC20(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        IERC20(tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, tokenAddress, balance);

        return true;
    }

    function updateReserveTokenToCToken(address reserveToken, address cToken)
        public
        onlyOwner
    {
        reserveTokenToCToken[reserveToken] = cToken;
    }

    function deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    ) external payable override nonReentrant returns (bool) {
        if (isNativeDeposit) {
            IERC20 erc20CEth = IERC20(address(cETH));
            uint256 erc20CEthBalanceBefore = erc20CEth.balanceOf(address(this));

            cETH.mint{value: msg.value}();

            uint256 erc20CEthBalanceAfter = erc20CEth.balanceOf(address(this));
            uint256 balDiff = erc20CEthBalanceAfter.sub(erc20CEthBalanceBefore);

            require(balDiff > 0, "Failed to successfully mint cETH");

            erc20CEth.transfer(msg.sender, balDiff);

            nativeDeposits[msg.sender] = nativeDeposits[msg.sender].add(
                balDiff
            );

            emit Deposit(isNativeDeposit, reserveTokenAddress, msg.value);
        } else {
            IERC20 reserveToken = IERC20(reserveTokenAddress);
            address cTokenAddress = reserveTokenToCToken[reserveTokenAddress];

            require(
                cTokenAddress != address(0),
                "CToken mapping does not exist for the given reserveTokenAddress"
            );

            IERC20 cTokenERC20 = IERC20(cTokenAddress);
            CErc20Interface cToken = CErc20Interface(cTokenAddress);

            reserveToken.transferFrom(msg.sender, address(this), depositAmount);
            reserveToken.approve(cTokenAddress, depositAmount);

            // TODO: Review logic when deployed on testnet

            uint256 cTokensBalanceBefore = cTokenERC20.balanceOf(address(this));
            uint256 mintStatus = cToken.mint(depositAmount);
            uint256 balDiff = cTokenERC20.balanceOf(address(this)).sub(
                cTokensBalanceBefore
            );

            // require(
            //     mintStatus == 0 && balDiff > 0,
            //     "Failed to successfully mint cToken"
            // );

            require(mintStatus == 0, "Failed to successfully mint cToken");

            erc20Deposits[msg.sender] = erc20Deposits[msg.sender].add(
                depositAmount
            );

            cTokenERC20.transfer(msg.sender, balDiff);

            emit Deposit(isNativeDeposit, reserveTokenAddress, depositAmount);
        }

        return true;
    }

    /// @notice withdrawAmount must be the amount of cTokens
    /// that will be redeemed, not the initial deposit amount.
    function withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    ) external override nonReentrant returns (bool) {
        if (isNativeWithdraw) {
            require(
                nativeDeposits[msg.sender] >= withdrawAmount,
                "withdrawAmount > depositAmount"
            );

            IERC20(address(cETH)).transferFrom(
                msg.sender,
                address(this),
                withdrawAmount
            );

            uint256 nativeBalanceBefore = address(this).balance;
            uint256 redeemStatus = cETH.redeem(withdrawAmount);
            uint256 diff = address(this).balance.sub(nativeBalanceBefore);

            require(
                redeemStatus == 0 && diff > 0,
                "Failed to redeem any tokens for the given cETH amount"
            );

            (bool sent, ) = address(payable(msg.sender)).call{value: diff}("");
            require(sent, "Failed to transfer ether back to depositor");

            nativeDeposits[msg.sender] = nativeDeposits[msg.sender].sub(
                withdrawAmount
            );

            emit Withdraw(
                isNativeWithdraw,
                reserveTokenAddress,
                withdrawAmount
            );
        } else {
            require(
                erc20Deposits[msg.sender] >= withdrawAmount,
                "withdrawAmount > depositAmount"
            );

            IERC20 reserveToken = IERC20(reserveTokenAddress);
            address cTokenAddress = reserveTokenToCToken[reserveTokenAddress];
            require(
                cTokenAddress != address(0),
                "CToken mapping does not exist for the given reserveTokenAddress"
            );

            CTokenInterface cToken = CTokenInterface(cTokenAddress);

            IERC20(cTokenAddress).transferFrom(
                msg.sender,
                address(this),
                withdrawAmount
            );

            uint256 balanceBefore = reserveToken.balanceOf(address(this));
            uint256 redeemStatus = cToken.redeem(withdrawAmount);
            uint256 diff = reserveToken.balanceOf(address(this)).sub(
                balanceBefore
            );

            require(
                redeemStatus == 0,
                "Failed to redeem any tokens for the given cETH amount"
            );

            reserveToken.transfer(msg.sender, diff);

            erc20Deposits[msg.sender] = erc20Deposits[msg.sender].sub(
                withdrawAmount
            );

            emit Withdraw(
                isNativeWithdraw,
                reserveTokenAddress,
                withdrawAmount
            );
        }
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./dependencies/interfaces/IFlashLoanReceiver.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

abstract contract CoreFlashLoanReceiver is IFlashLoanReceiver, Ownable {
    using SafeERC20 for IERC20;

    receive() external payable {}

    fallback() external payable {}

    function transferInternal(
        address payable reserve,
        address reserveToken,
        bool isNativeReserve,
        uint256 amount
    ) internal {
        if (isNativeReserve) {
            (bool success, ) = reserve.call{value: amount}("");
            require(success, "Failed to transfer internally");
            return;
        }
        IERC20(reserveToken).transfer(reserve, amount);
    }

    function getBalanceInternal(
        address payable reserve,
        address reserveToken,
        bool isNativeReserve
    ) internal view returns (uint256) {
        if (isNativeReserve) {
            return reserve.balance;
        }
        return IERC20(reserveToken).balanceOf(reserve);
    }
}