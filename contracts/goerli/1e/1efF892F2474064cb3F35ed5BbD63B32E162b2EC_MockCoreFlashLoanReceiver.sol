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

/// @title A contract for managing lending out funds to the AAVE protocol
/// @author https://github.com/softlinkprotocol
contract AaveLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice Address for the aWETH token
    address internal aWETH;

    /// @notice Interface for AAVE's LendingPoolAddressesProvider
    ILendingPoolAddressesProvider internal aaveAddressesProvider;

    /// @notice Interface for AAVE's ProtocolDataProvider
    IProtocolDataProvider internal aaveProtocolDataProvider;

    /// @notice Interface for AAVE's WETH Gateway
    IWETHGateway internal aaveIWETHGateway;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /// @notice Emitted whenever a deposit into an AAVE lending pool occurs.
    /// @param isNativeDeposit Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param depositAmount Self-explanatory
    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    /// @notice Emitted whenever a withdrawal from an AAVE lending pool occurs.
    /// @param isNativeWithdraw Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param withdrawAmount Self-explanatory
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

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Deposits funds into the protocol's lending pool.
    /// @param _isNativeDeposit Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _depositAmount Self-explanatory
    function deposit(
        bool _isNativeDeposit,
        address _reserveTokenAddress,
        uint256 _depositAmount
    ) external payable override nonReentrant returns (uint) {
        ILendingPool lendingPool = ILendingPool(
            aaveAddressesProvider.getLendingPool()
        );

        if (_isNativeDeposit) {
            uint callerBalanceBefore = IERC20(aWETH).balanceOf(msg.sender);

            aaveIWETHGateway.depositETH{value: _depositAmount}(
                address(lendingPool),
                msg.sender,
                0
            );

            uint callerBalanceAfterDiff = IERC20(aWETH)
                .balanceOf(msg.sender)
                .sub(callerBalanceBefore);

            emit Deposit(
                _isNativeDeposit,
                _reserveTokenAddress,
                _depositAmount
            );

            return callerBalanceAfterDiff;
        }

        IERC20(_reserveTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );

        IERC20(_reserveTokenAddress).approve(
            address(lendingPool),
            _depositAmount
        );

        (address aTokenAddress, , ) = aaveProtocolDataProvider
            .getReserveTokensAddresses(_reserveTokenAddress);

        uint callerBalanceBefore = IERC20(aTokenAddress).balanceOf(msg.sender);

        lendingPool.deposit(
            _reserveTokenAddress,
            _depositAmount,
            msg.sender,
            0
        );

        uint callerBalanceAfterDiff = IERC20(aTokenAddress)
            .balanceOf(msg.sender)
            .sub(callerBalanceBefore);

        emit Deposit(_isNativeDeposit, _reserveTokenAddress, _depositAmount);

        return callerBalanceAfterDiff;
    }

    /// @notice Withdraws funds from a protocol's lending pool.
    /// @param _isNativeWithdraw Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _withdrawAmount Self-explanatory
    function withdraw(
        bool _isNativeWithdraw,
        address _reserveTokenAddress,
        uint256 _withdrawAmount
    ) external override nonReentrant {
        ILendingPool lendingPool = ILendingPool(
            aaveAddressesProvider.getLendingPool()
        );

        if (_isNativeWithdraw) {
            IERC20(aWETH).transferFrom(
                msg.sender,
                address(this),
                _withdrawAmount
            );

            IERC20(aWETH).approve(address(aaveIWETHGateway), _withdrawAmount);

            aaveIWETHGateway.withdrawETH(
                address(lendingPool),
                _withdrawAmount,
                msg.sender
            );
        } else {
            (address aTokenAddress, , ) = aaveProtocolDataProvider
                .getReserveTokensAddresses(_reserveTokenAddress);

            IERC20(aTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _withdrawAmount
            );

            IERC20(aTokenAddress).approve(
                address(aaveIWETHGateway),
                _withdrawAmount
            );

            lendingPool.withdraw(
                _reserveTokenAddress,
                _withdrawAmount,
                msg.sender
            );
        }

        emit Withdraw(_isNativeWithdraw, _reserveTokenAddress, _withdrawAmount);
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    function emergencyWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);

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
    ) external payable returns (uint);

    function withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    ) external;
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
pragma solidity ^0.8.10;

import "./CoreReserve.sol";
import "./CoreFlashLoanReceiver.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

contract MockCoreFlashLoanReceiver is CoreFlashLoanReceiver {
    using SafeMath for uint256;

    constructor() {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external returns (bool) {
        // Perform any logic with the loan
        (bool success, ) = address(0).call(_params);
        require(success, "Strategy failed.");

        // Return the funds + amount fee
        (, , bool isNativeTokenReserve, address reserveToken) = CoreReserve(
            payable(_reserve)
        ).reserveData();

        transferInternal(
            payable(_reserve),
            reserveToken,
            isNativeTokenReserve,
            _amount.add(_fee)
        );

        return true;
    }

    function tI(
        address payable _reserve,
        address _reserveToken,
        bool _isNativeReserve,
        uint256 _amount
    ) public {
        transferInternal(_reserve, _reserveToken, _isNativeReserve, _amount);
    }

    function gBI(
        address payable _reserve,
        address _reserveToken,
        bool _isNativeReserve
    ) public view returns (uint256) {
        return getBalanceInternal(_reserve, _reserveToken, _isNativeReserve);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./CoreFlashLoanParams.sol";
import "./CoreReserveFactory.sol";
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

/// @title A contract for managing SoftLink reserves.
/// @author https://github.com/softlinkprotocol
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

    /// @notice Address of the core reserve factory
    address payable public coreReserveFactoryAddress;

    /// @notice The type of the reserve (Charity or Sniping for V0)
    address payable public coreFundReserveAddress;

    /// @notice Address of the deployed Core Treasury contract
    address payable public coreTreasuryAddress;

    /// @notice Address of the deployed Core Rewards Distributor contract
    address payable public coreRewardsDistributorAddress;

    /// @notice Address of the deployed Core Flash Loans Parameters contract
    address payable public coreFlashLoanParamsAddress;

    /// @notice The data structure representing the reserve
    ReserveData public reserveData;

    /// @notice Mapping from a depositor's address to their total native network asset (ETH) deposit amount.
    EnumerableMap.AddressToUintMap private nativeDeposits;

    /// @notice Mapping from a depositor's address to their total ERC20 reserve token deposit amount.
    EnumerableMap.AddressToUintMap private erc20Deposits;

    /// @notice Protocol-assigned/managed integer representing the percentage of
    // the deposit amount that will be deposited into the supported lending protocols if "earnYieldOnDeposit" is enabled.
    uint256 public maxLendingMarketDepositProportion;

    /// @notice Mapping from the depositor's address => the lending yield manager address => the address of the underlying reserve token => to the amount deposited in the chosen lending market of the chosen "lendingYieldManager"
    mapping(address => mapping(address => mapping(address => uint256)))
        public lendingMarketDeposits;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH is deposited into the contract
    /// @param reserve Self-explanatory
    /// @param depositor Self-explanatory
    /// @param amount Self-explanatory
    event ETHDeposit(address reserve, address depositor, uint256 amount);

    /// @notice Emitted whenever ERC20 tokens are deposited into the contract
    /// @param reserve Self-explanatory
    /// @param depositor Self-explanatory
    /// @param reserveToken Self-explanatory
    /// @param amount Self-explanatory
    event ERC20Deposit(
        address reserve,
        address depositor,
        address reserveToken,
        uint256 amount
    );

    /// @notice Emitted whenever ETH deposited into the specific reserve (not the contract itself) is withdrawed a depositor
    /// @param reserve Self-explanatory
    /// @param withdrawer Self-explanatory
    /// @param amount Self-explanatory
    event ETHWithdrawnFromReserve(
        address reserve,
        address withdrawer,
        uint256 amount
    );

    /// @notice Emitted whenever ETH deposited into the specific reserve (not the contract itself) is withdrawed a depositor
    /// @param reserve Self-explanatory
    /// @param reserveToken Self-explanatory
    /// @param withdrawer Self-explanatory
    /// @param amount Self-explanatory
    event ERC20WithdrawnFromReserve(
        address reserve,
        address reserveToken,
        address withdrawer,
        uint256 amount
    );

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /// @notice Emitted whenever a depositor transfers a portion of their deposit into a valid lending pool
    /// @param _isNativeTokenReserve Self-explanatory
    /// @param _proportionOfExistingDeposit Self-explanatory
    /// @param _lendingYieldManagerAddress Self-explanatory
    event TransferReserveDepositToLendingPool(
        bool _isNativeTokenReserve,
        uint256 _proportionOfExistingDeposit,
        address _lendingYieldManagerAddress
    );

    /// @notice Emitted whenever a depositor withdraws funds from a lending pool.
    /// @param _isNativeTokenReserve Self-explanatory
    /// @param _withdrawAmount Self-explanatory
    /// @param _lendingYieldManagerAddress Self-explanatory
    /// @param _lendingInterestBearingTokenAddress Self-explanatory
    event TransferFromLendingPoolToReserveDeposit(
        bool _isNativeTokenReserve,
        uint256 _withdrawAmount,
        address _lendingYieldManagerAddress,
        address _lendingInterestBearingTokenAddress
    );

    /* ========== FUNCTIONS ========== */

    constructor(
        address _coreReserveFactoryAddress,
        address _coreFundReserveAddress,
        address _coreRewardsDistributorAddress,
        address _coreTreasuryAddress,
        address _coreFlashLoanParamsAddress,
        ReserveData memory _reserveData
    ) Ownable() {
        coreReserveFactoryAddress = payable(_coreReserveFactoryAddress);
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
        maxLendingMarketDepositProportion = 5000;
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Updates the maxLendingMarketDepositProportion (read above)
    /// @param _maxLendingMarketDepositProportion Self-explanatory
    function updateMaxLendingMarketDepositProportion(
        uint256 _maxLendingMarketDepositProportion
    ) external onlyOwner {
        maxLendingMarketDepositProportion = _maxLendingMarketDepositProportion;
    }

    /// @notice Fetches the total native deposits in the reserve contract
    /// @return total amount of native deposits
    function totalNativeDeposits() external view returns (uint256) {
        return EnumerableMap.length(nativeDeposits);
    }

    /// @notice Fetches the total ERC20 deposits in the reserve contract
    /// @return total amount of ERC20 deposits
    function totalERC20Deposits() public view returns (uint256) {
        return EnumerableMap.length(erc20Deposits);
    }

    /// @notice Fetches the total native deposit amount for a given depositor
    /// @param _depositor Self-explanatory
    /// @return total native deposit amount for the depositor
    function nativeDepositAmountFor(address _depositor)
        external
        view
        returns (uint256)
    {
        (bool success, uint256 amount) = EnumerableMap.tryGet(
            nativeDeposits,
            _depositor
        );
        require(
            success,
            "Deposit amount not found for the given sender address"
        );
        return amount;
    }

    /// @notice Fetches the total ERC20 deposit amount for a given depositor
    /// @param _depositor Self-explanatory
    /// @return total ERC20 deposit amount for the depositor
    function erc20DepositAmountFor(address _depositor)
        external
        view
        returns (uint256)
    {
        (bool success, uint256 amount) = EnumerableMap.tryGet(
            erc20Deposits,
            _depositor
        );
        require(
            success,
            "Deposit amount not found for the given sender address"
        );
        return amount;
    }

    /// @notice Fetches a pair of a given depositor and their total native deposit amount at a given index.
    /// @param _index Self-explanatory
    /// @return pair of (depositor address, total native deposit amount)
    function nativeDepositEntryAt(uint256 _index)
        external
        view
        returns (address, uint256)
    {
        return EnumerableMap.at(nativeDeposits, _index);
    }

    /// @notice Fetches a pair of a given depositor and their total ERC20 deposit amount at a given index.
    /// @param _index Self-explanatory
    /// @return pair of (depositor address, total ERC20 deposit amount)
    function erc20DepositEntryAt(uint256 _index)
        external
        view
        returns (address, uint256)
    {
        return EnumerableMap.at(erc20Deposits, _index);
    }

    /// @notice Deposits funds into the reserve and potentially into one of the supported lending protocols
    /// @param _depositAmount Self-explanatory
    /// @param _creationDepositor Self-explanatory
    function deposit(uint256 _depositAmount, address _creationDepositor)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        bool isNativeTokenReserve = reserveData.isNativeTokenReserve;
        address reserveToken = reserveData.reserveToken;
        address depositor = (
            msg.sender == coreReserveFactoryAddress
                ? _creationDepositor
                : msg.sender
        );

        if (isNativeTokenReserve) {
            // All deposits must be greater than 0...
            _depositAmount = msg.value;
            require(
                _depositAmount > 0,
                "Native token deposit value must be > 0"
            );

            // Protocol service fee
            uint protocolServiceFee = _depositAmount
                .mul(
                    CoreReserveFactory(coreReserveFactoryAddress)
                        .baseTransactionFee()
                )
                .div(10000);
            (bool success, ) = coreTreasuryAddress.call{
                value: protocolServiceFee
            }("");
            require(
                success,
                "Failed to transfer protocol service fee to the treasury."
            );

            _depositAmount = _depositAmount.sub(protocolServiceFee);

            // Update the depositor's total deposit amount
            (bool getSuccess, uint256 amount) = EnumerableMap.tryGet(
                nativeDeposits,
                depositor
            );
            if (getSuccess) {
                EnumerableMap.set(
                    nativeDeposits,
                    depositor,
                    amount.add(_depositAmount)
                );
            } else {
                success = EnumerableMap.set(
                    nativeDeposits,
                    depositor,
                    _depositAmount
                );
                require(success, "Failed to update native deposits map");
            }

            emit ETHDeposit(address(this), depositor, _depositAmount);
        } else {
            IERC20 erc20Token = IERC20(reserveToken);

            // NOTE: Deposit amount must be > 0 AND sender must approve the reserve
            // contract to transfer ERC20 tokens into the contract before executing th transaction.
            require(
                erc20Token.balanceOf(msg.sender) >= _depositAmount,
                "Reserve token personal balance must be >= depositAmount"
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) > 0,
                "Please approve the contract to transfer the reserve token."
            );

            erc20Token.transferFrom(msg.sender, address(this), _depositAmount);

            // Protocol service fee
            uint protocolServiceFee = _depositAmount
                .mul(
                    CoreReserveFactory(coreReserveFactoryAddress)
                        .baseTransactionFee()
                )
                .div(10000);

            bool success = erc20Token.transfer(
                coreTreasuryAddress,
                protocolServiceFee
            );
            require(
                success,
                "Failed to transfer protocol service fee to the treasury."
            );

            _depositAmount = _depositAmount.sub(protocolServiceFee);

            (bool getSuccess, uint256 amount) = EnumerableMap.tryGet(
                erc20Deposits,
                depositor
            );
            if (getSuccess) {
                EnumerableMap.set(
                    erc20Deposits,
                    depositor,
                    amount.add(_depositAmount)
                );
            } else {
                success = EnumerableMap.set(
                    erc20Deposits,
                    depositor,
                    _depositAmount
                );
                require(success, "Failed to update erc20 deposits map");
            }

            emit ERC20Deposit(
                address(this),
                depositor,
                reserveToken,
                _depositAmount
            );
        }
    }

    /// @notice Transfers a proportion of the depositors reserve deposit to a supported lending pool
    /// @param _isNativeTokenReserve Self-explanatory
    /// @param _proportionOfExistingDeposit Self-explanatory
    /// @param _lendingYieldManagerAddress Self-explanatory
    function transferReserveDepositToLendingPool(
        bool _isNativeTokenReserve,
        uint256 _proportionOfExistingDeposit,
        address _lendingYieldManagerAddress
    ) external {
        require(
            _proportionOfExistingDeposit <= maxLendingMarketDepositProportion,
            "_proprotion must be <= maxLendingMarketDepositProportion"
        );
        require(
            _lendingYieldManagerAddress != address(0),
            "Invalid lendingYieldManager address"
        );

        ILendingYieldManager lendingYieldManager = ILendingYieldManager(
            _lendingYieldManagerAddress
        );

        if (_isNativeTokenReserve) {
            (bool success, uint256 totalDepositAmount) = EnumerableMap.tryGet(
                nativeDeposits,
                msg.sender
            );
            require(success, "Deposit does not exist for msg.sender");

            // Compute the proportion of the current depositor's reserve deposit they would like to add to a lending pool
            uint256 lendingPoolDepositAmount = totalDepositAmount
                .mul(_proportionOfExistingDeposit)
                .div(10000);
            require(
                lendingPoolDepositAmount > 0 &&
                    totalDepositAmount > lendingPoolDepositAmount,
                "Total deposit amount * proportion must be > 0 && totalDepositAmount must be > lendingPoolDepositAmount"
            );
            require(
                address(this).balance > lendingPoolDepositAmount,
                "Reserve contract balance must be > lendingPoolDepositAmount"
            );

            // Note: We need the poolTokenBalancePostDeposit because the final interst-bearing token amount
            // received from depositing into the lending pool might differ from the lendingPoolDepositAmount.
            uint poolTokenBalancePostDeposit = lendingYieldManager.deposit{
                value: lendingPoolDepositAmount,
                gas: 500000
            }(true, address(0), lendingPoolDepositAmount);

            // Portion of the reserve deposit moved to the lending pool so update
            EnumerableMap.set(
                nativeDeposits,
                msg.sender,
                totalDepositAmount.sub(lendingPoolDepositAmount)
            );

            // NOTE: ONLY FOR NATIVE DEPOSITS, we use address(0) to represent the native asset mapping for storage in "lendingMarketDeposits"
            lendingMarketDeposits[msg.sender][_lendingYieldManagerAddress][
                address(0)
            ] = lendingMarketDeposits[msg.sender][_lendingYieldManagerAddress][
                address(0)
            ].add(poolTokenBalancePostDeposit);
        } else {
            (bool success, uint256 totalDepositAmount) = EnumerableMap.tryGet(
                erc20Deposits,
                msg.sender
            );
            require(success, "Deposit does not exist for msg.sender");

            // Similar to above
            uint256 lendingPoolDepositAmount = totalDepositAmount
                .mul(_proportionOfExistingDeposit)
                .div(10000);
            require(
                lendingPoolDepositAmount > 0 &&
                    totalDepositAmount > lendingPoolDepositAmount,
                "Total deposit amount * proportion must be > 0 && totalDepositAmount must be > lendingPoolDepositAmount"
            );

            address reserveToken = reserveData.reserveToken;
            require(
                IERC20(reserveToken).balanceOf(address(this)) >
                    lendingPoolDepositAmount,
                "Reserve contract balance must be > lendingPoolDepositAmount"
            );

            IERC20(reserveToken).approve(
                address(lendingYieldManager),
                lendingPoolDepositAmount
            );

            // NOTE: Similar to above
            uint256 poolTokenBalancePostDeposit = lendingYieldManager.deposit{
                gas: 500000
            }(false, reserveToken, lendingPoolDepositAmount);

            // Similar to above
            EnumerableMap.set(
                erc20Deposits,
                msg.sender,
                totalDepositAmount.sub(lendingPoolDepositAmount)
            );

            // NOTE: Setting the poolTokenBalancePostDeposit so when withdrawing from lending pools we account
            // for the initial amount of interest-bearing tokens received from the caller's deposit.
            lendingMarketDeposits[msg.sender][_lendingYieldManagerAddress][
                reserveToken
            ] = lendingMarketDeposits[msg.sender][_lendingYieldManagerAddress][
                reserveToken
            ].add(poolTokenBalancePostDeposit);
        }

        emit TransferReserveDepositToLendingPool(
            _isNativeTokenReserve,
            _proportionOfExistingDeposit,
            _lendingYieldManagerAddress
        );
    }

    /// @notice Transfers deposits from a supported lending pool back to the reserve
    /// @param _isNativeTokenReserve Self-explanatory
    /// @param _withdrawAmount Self-explanatory
    /// @param _lendingYieldManagerAddress Self-explanatory
    /// @param _lendingInterestBearingTokenAddress Self-explanatory (ex: The address for aWETH)
    function transferFromLendingPoolToReserveDeposit(
        bool _isNativeTokenReserve,
        uint256 _withdrawAmount,
        address _lendingYieldManagerAddress,
        address _lendingInterestBearingTokenAddress
    ) external {
        require(_withdrawAmount > 0, "_withdrawAmount must be > 0");
        require(
            IERC20(_lendingInterestBearingTokenAddress).balanceOf(
                address(this)
            ) > 0,
            "The contract's interest-bearing token balance must be > 0"
        );

        if (_isNativeTokenReserve) {
            uint totalLendingPoolDeposit = lendingMarketDeposits[msg.sender][
                _lendingYieldManagerAddress
            ][address(0)];
            require(
                totalLendingPoolDeposit > 0,
                "totalLendingPoolDeposit must be > 0 to withdraw"
            );
            require(
                totalLendingPoolDeposit >= _withdrawAmount,
                "totalLendingPoolDeposit must be >= _withdrawAmount"
            );

            uint nativeBalanceBefore = address(this).balance;

            IERC20(_lendingInterestBearingTokenAddress).approve(
                _lendingYieldManagerAddress,
                _withdrawAmount
            );

            ILendingYieldManager(_lendingYieldManagerAddress).withdraw(
                true,
                address(0),
                _withdrawAmount
            );

            uint nativeBalanceAfterDiff = address(this).balance.sub(
                nativeBalanceBefore
            );

            require(
                nativeBalanceAfterDiff > 0,
                "Failed to withdraw any funds from lending pool"
            );

            (bool success, uint256 totalReserveDepositAmount) = EnumerableMap
                .tryGet(nativeDeposits, msg.sender);
            require(
                success,
                "Failed to get totalReserveDepositAmount for msg.sender"
            );

            EnumerableMap.set(
                nativeDeposits,
                msg.sender,
                totalReserveDepositAmount.add(nativeBalanceAfterDiff)
            );

            lendingMarketDeposits[msg.sender][_lendingYieldManagerAddress][
                address(0)
            ] = totalLendingPoolDeposit.sub(_withdrawAmount);
        } else {
            // NOTE: Recall from above (transferReserveDepositToLendingPool) that the totalLendingPoolDeposit
            // from ERC20 lending pool deposits will be the total amount of interest-bearing tokens (ex. aWETH) deposited/stored
            // into the reserve contract for a given depositor.
            address reserveToken = reserveData.reserveToken;
            uint totalLendingPoolDeposit = lendingMarketDeposits[msg.sender][
                _lendingYieldManagerAddress
            ][reserveToken];
            require(
                totalLendingPoolDeposit > 0,
                "totalLendingPoolDeposit must be > 0 to withdraw"
            );
            require(
                totalLendingPoolDeposit >= _withdrawAmount,
                "_withdrawAmount must be <= the total 'lendingMarketDeposits' amount"
            );

            uint erc20BalanceBefore = IERC20(reserveToken).balanceOf(
                address(this)
            );

            IERC20(_lendingInterestBearingTokenAddress).approve(
                _lendingYieldManagerAddress,
                _withdrawAmount
            );

            ILendingYieldManager(_lendingYieldManagerAddress).withdraw(
                false,
                reserveToken,
                _withdrawAmount
            );

            uint erc20BalanceAfterDiff = IERC20(reserveToken)
                .balanceOf(address(this))
                .sub(erc20BalanceBefore);

            require(
                erc20BalanceAfterDiff > 0,
                "Failed to withdraw any funds from lending pool"
            );

            (bool success, uint256 totalReserveDepositAmount) = EnumerableMap
                .tryGet(erc20Deposits, msg.sender);
            require(
                success,
                "Failed to get totalReserveDepositAmount for msg.sender"
            );

            EnumerableMap.set(
                erc20Deposits,
                msg.sender,
                totalReserveDepositAmount.add(erc20BalanceAfterDiff)
            );

            lendingMarketDeposits[msg.sender][_lendingYieldManagerAddress][
                reserveToken
            ] = totalLendingPoolDeposit.sub(_withdrawAmount);
        }

        emit TransferFromLendingPoolToReserveDeposit(
            _isNativeTokenReserve,
            _withdrawAmount,
            _lendingYieldManagerAddress,
            _lendingInterestBearingTokenAddress
        );
    }

    /// @notice Withdraws funds from the reserve and potentially from one of the supported lending protocols
    /// @param _withdrawAmount Self-explanatory
    function withdraw(uint256 _withdrawAmount)
        external
        nonReentrant
        whenNotPaused
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
                depositAmount >= _withdrawAmount,
                "Your deposit/reserve balance must be >= withdrawAmount"
            );
            require(
                address(this).balance >= _withdrawAmount,
                "Contract balance is less than withdrawAmount"
            );

            // Protocol service fee
            uint protocolServiceFee = _withdrawAmount
                .mul(
                    CoreReserveFactory(coreReserveFactoryAddress)
                        .baseTransactionFee()
                )
                .div(10000);
            (success, ) = coreTreasuryAddress.call{value: protocolServiceFee}(
                ""
            );
            require(
                success,
                "Failed to transfer protocol service fee to the treasury."
            );

            // Update sender's deposit amount
            EnumerableMap.set(
                nativeDeposits,
                msg.sender,
                depositAmount.sub(_withdrawAmount)
            );

            // Sent back amount - protocol service fee
            _withdrawAmount = _withdrawAmount.sub(protocolServiceFee);

            (bool sent, ) = address(msg.sender).call{value: _withdrawAmount}(
                ""
            );
            require(sent, "Failed to send Ether");

            emit ETHWithdrawnFromReserve(
                address(this),
                msg.sender,
                _withdrawAmount
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
                depositAmount >= _withdrawAmount,
                "Your deposit/reserve balance must be >= withdrawAmount"
            );
            require(
                IERC20(reserveToken).balanceOf(address(this)) >=
                    _withdrawAmount,
                "Contract balance is less than withdrawAmount"
            );

            // Protocol service fee
            uint protocolServiceFee = _withdrawAmount
                .mul(
                    CoreReserveFactory(coreReserveFactoryAddress)
                        .baseTransactionFee()
                )
                .div(10000);
            require(
                IERC20(reserveToken).balanceOf(address(this)) >=
                    protocolServiceFee,
                "Contract balance is less than protocolServiceFee"
            );

            success = IERC20(reserveToken).transferFrom(
                address(this),
                coreTreasuryAddress,
                protocolServiceFee
            );
            require(
                success,
                "Failed to transfer protocol service fee to the treasury."
            );

            uint withdrawAmountPostFees = _withdrawAmount.sub(
                protocolServiceFee
            );
            bool sent = IERC20(reserveToken).transfer(
                msg.sender,
                withdrawAmountPostFees
            );
            require(sent, "Failed to send native token");

            EnumerableMap.set(
                erc20Deposits,
                msg.sender,
                depositAmount.sub(_withdrawAmount)
            );

            emit ERC20WithdrawnFromReserve(
                address(this),
                reserveToken,
                msg.sender,
                _withdrawAmount
            );
        }
    }

    /// @notice Allows for contracts to perform a flash loan on the reserve.
    /// @param _params Self-explanatory
    function flashLoanETH(FlashLoanParams calldata _params)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            address(this) != coreFundReserveAddress,
            "No entity can perform flash loans on the core fund reserve."
        );

        ReserveType rType = reserveData.reserveType;
        require(
            rType == ReserveType.SNIPING,
            "Only sniping reserves are eligible for flash loans."
        );
        require(
            _params.amount > 0,
            "The loan amount must be greater than zero."
        );

        // Does the reserve have enough liquidity?
        uint256 liquidityBefore = address(this).balance;
        require(
            liquidityBefore >= _params.amount,
            "The reserve does not have enough liquidity for the loan amount."
        );

        // Fetch current flash loan fees
        (
            uint256 amountFee,
            uint256 fundFee,
            uint256 lpRewardsFee,
            uint256 protocolFee
        ) = CoreFlashLoanParams(coreFlashLoanParamsAddress).getFlashLoanFees(
                _params.amount
            );
        require(
            amountFee > 0 && fundFee > 0 && lpRewardsFee > 0 && protocolFee > 0,
            "The request amount is too small for a flashLoan given the fees applied"
        );

        // Transfer loan to the receiver (IFlashLoanReceiver)
        {
            address payable userPayable = payable(
                address(uint160(_params.receiver))
            );
            (bool success, ) = userPayable.call{
                value: _params.amount,
                gas: 50000
            }("");
            require(success, "Failed to transfer native token to receiver.");
        }

        // Execute action/callback of the receiver
        {
            bool success = IFlashLoanReceiver(_params.receiver)
                .executeOperation(
                    address(this),
                    _params.amount,
                    amountFee,
                    _params.params
                );
            require(
                success,
                "Failed to execute external operation on flashLoanReceiver"
            );
        }

        // Make sure native token principal was sent back w/ amountFee
        uint256 liquidityAfter = address(this).balance;
        require(
            liquidityAfter >= liquidityBefore.add(amountFee),
            "Post flash loan, the condition must be resolved: liquidityAfter >= liquidityBefore + amountFee"
        );

        {
            // Transfer fund/charity fee to the Core Fund Reserve
            (bool success, ) = coreFundReserveAddress.call{value: fundFee}("");
            require(
                success,
                "Failed to transfer reserve token to the Core Fund Reserve."
            );

            // Transfer protocol fee to the Rewards Distributor contract for Depositor/LP reward distribution
            (success, ) = coreRewardsDistributorAddress.call{
                value: lpRewardsFee
            }("");
            require(
                success,
                "Failed to transfer reserve token to the Rewards Distributor."
            );

            // Transfer protocol fee to the Treasury (protocol revenue)
            (success, ) = coreTreasuryAddress.call{value: protocolFee}("");
            require(
                success,
                "Failed to transfer reserve token to the Treasury."
            );
        }
    }

    /// @notice Allows for contracts to perform a flash loan on reserves containing ERC20 tokens as reserve token.
    /// @param _params Self-explanatory
    function flashLoanERC20(FlashLoanParams calldata _params)
        external
        nonReentrant
        whenNotPaused
    {
        require(
            address(this) != coreFundReserveAddress,
            "No entity can perform flash loans on the core fund reserve."
        );

        ReserveType rType = reserveData.reserveType;
        address reserveToken = reserveData.reserveToken;
        require(
            rType == ReserveType.SNIPING,
            "Only sniping reserves are eligible for flash loans."
        );

        require(
            _params.amount > 0,
            "The loan amount must be greater than zero."
        );

        // Does the reserve have enough liquidity?
        uint256 liquidityBefore = IERC20(reserveToken).balanceOf(address(this));

        require(
            liquidityBefore >= _params.amount,
            "The reserve does not have enough liquidity for the loan amount."
        );

        // Compute fees (loan fee, protocol fee, fund fee/allocation)
        (
            uint256 amountFee,
            uint256 fundFee,
            uint256 lpRewardsFee,
            uint256 protocolFee
        ) = CoreFlashLoanParams(coreFlashLoanParamsAddress).getFlashLoanFees(
                _params.amount
            );
        require(
            amountFee > 0 && protocolFee > 0 && fundFee > 0 && lpRewardsFee > 0,
            "The request amount is too small for a flashLoan given the fees applied"
        );

        // Transfer loan to the receiver
        bool success = IERC20(reserveToken).transfer(
            _params.receiver,
            _params.amount
        );
        require(success, "Failed to transfer reserve token to receiver.");

        // Receiver must implement the flash loan interface; therefore, existing IFlashLoanReceiver instances can use this protocol :)
        // Execute action/callback of the receiver
        IFlashLoanReceiver(_params.receiver).executeOperation(
            address(this),
            _params.amount,
            amountFee,
            _params.params
        );

        // Ensure that the amount deposited back into the reserve is correct + accounts for the amountFee
        uint256 liquidityAfter = IERC20(reserveToken).balanceOf(address(this));
        require(
            liquidityAfter >= liquidityBefore.add(amountFee),
            "The following condition must be resolved: liquidityAfter >= liquidityBefore + amountFee"
        );

        // Transfer fund/charity fee to the Core Fund Reserve
        success = IERC20(reserveToken).transfer(
            coreFundReserveAddress,
            fundFee
        );
        require(
            success,
            "Failed to transfer reserve token to the Core Fund Reserve."
        );

        // Transfer protocol fee to the Rewards Distributor contract for Depositor/LP reward distribution
        success = IERC20(reserveToken).transfer(
            coreRewardsDistributorAddress,
            lpRewardsFee
        );
        require(
            success,
            "Failed to transfer reserve token to the Rewards Distributor."
        );

        // Transfer protocol fee to the Treasury (protocol revenue)
        success = IERC20(reserveToken).transfer(
            coreTreasuryAddress,
            protocolFee
        );
        require(success, "Failed to transfer reserve token to the Treasury.");
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    /// @param _tokenAddress The address of the ERC20 token
    function emergencyWithdrawERC20(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./dependencies/interfaces/IFlashLoanReceiver.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

/// @title An abstract contract for receivers of Flash Loans
/// @author https://github.com/softlinkprotocol
abstract contract CoreFlashLoanReceiver is IFlashLoanReceiver, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {}

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {}

    /// @notice Helper function to transfer funds back to a CoreReserve to pay off the loan.
    /// @param _reserve Self-explanatory
    /// @param _reserveToken Self-explanatory
    /// @param _isNativeReserve Self-explanatory
    /// @param _amount Self-explanatory
    function transferInternal(
        address payable _reserve,
        address _reserveToken,
        bool _isNativeReserve,
        uint256 _amount
    ) internal {
        if (_isNativeReserve) {
            (bool success, ) = _reserve.call{value: _amount}("");
            require(success, "Failed to transfer internally");
        } else {
            bool success = IERC20(_reserveToken).transfer(_reserve, _amount);
            require(success, "Failed to transfer internally");
        }
    }

    /// @notice Helper function to get a CoreReserve's native and/or (specific) ERC20 reserve balance
    /// @param _reserve Self-explanatory
    /// @param _reserveToken Self-explanatory
    /// @param _isNativeReserve Self-explanatory
    function getBalanceInternal(
        address payable _reserve,
        address _reserveToken,
        bool _isNativeReserve
    ) internal view returns (uint256) {
        return
            _isNativeReserve
                ? _reserve.balance
                : IERC20(_reserveToken).balanceOf(_reserve);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

/// @title A contract for managing Flash Loan parameters
/// @author https://github.com/softlinkprotocol
contract CoreFlashLoanParams is Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice The base fee for performing flash loans: 0.22%
    uint256 public FLASHLOAN_FEE_TOTAL = 22;

    /// @notice The LP rewards fee taken from the base fee: 50% of the base fee
    uint256 public FLASHLOAN_FEE_LP_REWARDS = 5000;

    /// @notice The Core Fund Reserve fee taken from the base fee: 25% of the base fee
    uint256 public FLASHLOAN_FEE_FUND = 2500;

    /// @notice The protocol service fee taken from the base fee: 20% of the base fee
    uint256 public FLASHLOAN_FEE_PROTOCOL = 2000;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /* ========== FUNCTIONS ========== */

    constructor() Ownable() {}

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Computes and returns flash loan fees
    /// @param _flashLoanAmount Self-explanatory
    function getFlashLoanFees(uint256 _flashLoanAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountFee = _flashLoanAmount.mul(FLASHLOAN_FEE_TOTAL).div(
            10000
        );
        uint256 lpRewardsFee = amountFee.mul(FLASHLOAN_FEE_LP_REWARDS).div(
            10000
        );
        uint256 fundFee = amountFee.mul(FLASHLOAN_FEE_FUND).div(10000);
        uint256 protocolFee = amountFee.mul(FLASHLOAN_FEE_PROTOCOL).div(10000);
        return (amountFee, lpRewardsFee, fundFee, protocolFee);
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    /// @param _tokenAddress The address of the ERC20 token
    function emergencyWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);

        return true;
    }
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

/// @title A factory contract for creating new reserves.
/// @author https://github.com/softlinkprotocol
contract CoreReserveFactory is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== TYPE DECLARATIONS ========== */

    struct CreateReserveParams {
        CoreReserve.ReserveType reserveType;
        bool isNativeTokenReserve;
        address reserveToken;
        uint256 reserveTokenInitialAmount;
    }

    /* ========== STATE VARIABLES ========== */

    /// @notice Address of the deployed Core Treasury contract
    address payable public coreTreasuryAddress;

    /// @notice Address of the deployed Core Rewards Distributor contract
    address payable public coreRewardsDistributorAddress;

    /// @notice Address of the deployed Core Flash Loans Parameters contract
    address payable public coreFlashLoanParamsAddress;

    /// @notice Address of the Core Fund Reserve address
    address payable public coreFundReserveAddress;

    /// @notice List of deployed CoreReserve addresses
    address[] public reserves;

    /// @notice Mapping of a deployed CoreReserve's underlying reserve token address to the reserve's address
    mapping(address => address) public reserveForReserveToken;

    /// @notice Integer representing the index of the next CoreReserve
    uint256 public nextReserveIndex;

    /// @notice Mapping of a CoreReserve's index above to it's address
    mapping(uint256 => address) public reserveForIndex;

    /// @notice Integer representing the base transaction fee, paid out to the protocol, for providing CoreReserve features
    uint256 public baseTransactionFee;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever the base transaction fee is updated.
    /// @param caller Self-explanatory
    /// @param newFee Self-explanatory
    event BaseTransactionFeeUpdated(address caller, uint256 newFee);

    /// @notice Emitted whenever the Core Fund Reserve address is updated
    /// @param caller Self-explanatory
    /// @param newAddress Self-explanatory
    event CoreFundReserveAddressUpdated(address caller, address newAddress);

    /// @notice Emitted whenever a new CoreReserve is created
    /// @param reserveType Self-explanatory
    /// @param isNativeTokenReserve Self-explanatory
    /// @param reserveToken Self-explanatory
    /// @param initialDepositAmount Self-explanatory
    event ReserveCreated(
        CoreReserve.ReserveType reserveType,
        bool isNativeTokenReserve,
        address reserveToken,
        uint256 initialDepositAmount
    );

    /// @notice Emitted whenever a CoreReserve is paused
    /// @param reserve Self-explanatory
    /// @param reserveIndex Self-explanatory
    event ReservePaused(address reserve, uint256 reserveIndex);

    /// @notice Emitted whenever a CoreReserve is un-paused
    /// @param reserve Self-explanatory
    /// @param reserveIndex Self-explanatory
    event ReserveUnpaused(address reserve, uint256 reserveIndex);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /* ========== FUNCTIONS ========== */

    constructor(
        address _coreTreasuryAddress,
        address _coreRewardsDistributorAddress,
        address _coreFlashLoanParamsAddress
    ) Ownable() {
        coreTreasuryAddress = payable(_coreTreasuryAddress);
        coreRewardsDistributorAddress = payable(_coreRewardsDistributorAddress);
        coreFlashLoanParamsAddress = payable(_coreFlashLoanParamsAddress);
        // 0.22%;
        baseTransactionFee = 22;
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Updates the base transaction fee
    /// @param _newValue Self-explanatory
    function updateBaseTransactionFee(uint256 _newValue) external onlyOwner {
        // TODO: Collect baseTransaction fee at the start of every critical function (Create, Deposit, Withdraw, etc)
        baseTransactionFee = _newValue;
        emit BaseTransactionFeeUpdated(msg.sender, _newValue);
    }

    /// @notice Updates the Core Fund Reserve address
    /// @param _newAddress Self-explanatory
    function updateCoreFundReserveAddresss(address _newAddress)
        external
        onlyOwner
    {
        // TODO: Collect baseTransaction fee at the start of every critical function (Create, Deposit, Withdraw, etc)
        coreFundReserveAddress = payable(_newAddress);
        emit CoreFundReserveAddressUpdated(msg.sender, _newAddress);
    }

    /// @notice Creates/deploys a new CoreReserve contract
    /// @param _params Method parameters (refresh above)
    /// @return address of the new,created CoreReserve
    function createReserve(CreateReserveParams calldata _params)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (address)
    {
        // Charity reserves can only be created/deployed by the owner
        if (_params.reserveType == CoreReserve.ReserveType.CHARITY) {
            require(
                msg.sender == owner(),
                "Only the owner can make charity reserves."
            );
        }

        // Populated reserveData needed for creating/deploying a new CoreReserve
        CoreReserve.ReserveData memory reserveData;
        uint256 initialDepositAmount;

        reserveData.creator = msg.sender;
        reserveData.reserveType = _params.reserveType;
        reserveData.isNativeTokenReserve = _params.isNativeTokenReserve;
        reserveData.reserveToken = _params.reserveToken;

        // NOTE: Keep in mind, the coreFundReserveAddress is address(0) when creating the initial core fund reserve
        CoreReserve newCoreReserve = new CoreReserve(
            address(this),
            coreFundReserveAddress,
            coreRewardsDistributorAddress,
            coreTreasuryAddress,
            coreFlashLoanParamsAddress,
            reserveData
        );
        address ncrAddress = address(newCoreReserve);
        // NOTE: On contract deployment, the coreFundReserveAddress will intially be zero.
        // In our deployment script, we create the first reserve (the CoreFundReserve) so therefore,
        // we only set the value of the coreFundReserveAddress if the following condition is t
        if (msg.sender == owner() && coreFundReserveAddress == address(0)) {
            coreFundReserveAddress = payable(ncrAddress);
        }

        // Is the new created CoreReserve a reserve containing the network's native asset (ETH)? An ERC20 token?
        if (_params.isNativeTokenReserve) {
            // Only the owner can create/manage native reserve assets
            require(
                msg.sender == owner(),
                "Only the owner can create native reserves"
            );

            initialDepositAmount = msg.value;
            require(
                initialDepositAmount > 0,
                "Native token deposit value must be > 0"
            );

            // Deposit/Add initial liquidity to the new CoreReserve (required)
            newCoreReserve.deposit{value: initialDepositAmount}(
                initialDepositAmount,
                msg.sender
            );
        } else {
            // The underlying token for the reserve (reserveToken) can not be the SoftLink address
            // nor can be assigned to a new reserve if another reserve stores that token
            require(
                _params.reserveToken != address(0),
                "Invalid reserve token address"
            );
            require(
                reserveForReserveToken[_params.reserveToken] == address(0),
                "A reserve exists for the given reserve token."
            );

            initialDepositAmount = _params.reserveTokenInitialAmount;

            IERC20 erc20Token = IERC20(_params.reserveToken);

            // Make sure the creator(msg.sender) has enough to deposit and allowed the contract to deposit
            // their tokens into the new reserve for the required initial liquidity (can specify amount with initialDepositAmount)
            require(
                erc20Token.balanceOf(msg.sender) >= initialDepositAmount,
                "Reserve token personal balance must be >= initialDepositAmount"
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) > 0,
                "Please approve the contract to transfer the reserve token."
            );

            // Transfer their tokens into the new Core Reserve (ncr) contract.
            erc20Token.transferFrom(
                msg.sender,
                address(this),
                initialDepositAmount
            );

            // Deposit into the new contract for them
            erc20Token.approve(ncrAddress, initialDepositAmount);
            newCoreReserve.deposit(initialDepositAmount, msg.sender);

            reserveForReserveToken[_params.reserveToken] = ncrAddress;
        }

        reserves.push(ncrAddress);

        reserveForIndex[nextReserveIndex] = ncrAddress;
        nextReserveIndex = nextReserveIndex.add(1);

        emit ReserveCreated(
            _params.reserveType,
            _params.isNativeTokenReserve,
            _params.reserveToken,
            initialDepositAmount
        );

        return ncrAddress;
    }

    /// @notice Pauses a reserve
    /// @param _reserveIndex The index of the reserve to pause
    function pauseReserve(uint256 _reserveIndex)
        external
        onlyOwner
        returns (bool)
    {
        CoreReserve reserve = CoreReserve(
            payable(reserveForIndex[_reserveIndex])
        );

        reserve.pause();

        emit ReservePaused(address(reserve), _reserveIndex);

        return true;
    }

    /// @notice Unpauses a reserve
    /// @param _reserveIndex The index of the reserve to unpause
    function unpauseReserve(uint256 _reserveIndex)
        external
        onlyOwner
        returns (bool)
    {
        CoreReserve reserve = CoreReserve(
            payable(reserveForIndex[_reserveIndex])
        );

        reserve.unpause();

        emit ReserveUnpaused(address(reserve), _reserveIndex);

        return true;
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    /// @param _tokenAddress The address of the ERC20 token
    function emergencyWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

import "./CoreReserve.sol";
import "./CoreReserveFactory.sol";
import "./dependencies/gelato/interfaces/IOpsExtended.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

/// @title A contract for managing distributing rewards
/// @author https://github.com/softlinkprotocol
contract CoreRewardsDistributor is
    Pausable,
    ReentrancyGuard,
    Ownable,
    OpsReady
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice The address of the CoreReserveFactory
    address payable public coreReserveFactory;

    /// @notice The time that must elapse before rewards are distributed again (start: bi-weekly)
    uint256 public distributionWaitingPeriod = 1000 * 60 * 60 * 24 * 14;

    /// @notice The last time rewards were distributed
    uint256 public lastDistribution;

    /// @notice The mapping between a depositor and the total amount of native rewards they received.
    /// @dev address (msg.sender) => uint256 (total amount)
    mapping(address => uint256) public totalNativeEarned;

    /// @notice The mapping between a depositor and the total amount of ERC20 token rewards they received.
    /// @dev address (msg.sender) => address (erc20 token address) uint256 (total amount)
    mapping(address => mapping(address => uint256)) public totalERC20Earned;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /// @notice Emitted whenever a new distribution waiting period is assigned
    /// @param updatedPeriod Self-explanatory
    /// @param updater Self-explanatory
    event NewDistributionWaitingPeriod(uint256 updatedPeriod, address updater);

    /// @notice Emitted whenever a new core reserve factory address is assigned
    /// @param updatedAddress Self-explanatory
    /// @param updater Self-explanatory
    event NewCoreReserveFactory(address updatedAddress, address updater);

    /// @notice Emitted whenever rewards are distributed to an address
    /// @param to Self-explanatory
    /// @param amount Self-explanatory
    /// @param sentTimestamp Self-explanatory
    event RewardDistributed(address to, uint256 amount, uint256 sentTimestamp);

    /// @notice Emitted whenever rewards are distributed successfully (completed)
    /// @param completionTimestamp Self-explanatory
    event DistributionCompleted(uint256 completionTimestamp);

    modifier onlyOpsOrOwner() {
        require(msg.sender == ops || msg.sender == owner(), "onlyOps or owner");
        _;
    }

    /* ========== FUNCTIONS ========== */

    constructor(address payable _ops, address _coreReserveFactory)
        OpsReady(_ops)
    {
        coreReserveFactory = payable(_coreReserveFactory);
        lastDistribution = block.timestamp;
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Updates the distributionWaitingPeriod
    /// @param _distributionWaitingPeriod Self-explanatory
    function setDistributionWaitingPeriod(uint256 _distributionWaitingPeriod)
        external
        onlyOwner
    {
        distributionWaitingPeriod = _distributionWaitingPeriod;

        emit NewDistributionWaitingPeriod(
            _distributionWaitingPeriod,
            msg.sender
        );
    }

    /// @notice Updates the _oreReserveFactory
    /// @param _coreReserveFactory Self-explanatory
    function setCoreReserveFactory(address _coreReserveFactory)
        external
        onlyOwner
    {
        coreReserveFactory = payable(_coreReserveFactory);

        emit NewCoreReserveFactory(_coreReserveFactory, msg.sender);
    }

    /// @notice Determines whether or not the execPayload can be executed
    function canExecuteDistribution()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        // distributionWaitingPeriod has elasped
        canExec =
            lastDistribution + distributionWaitingPeriod <= block.timestamp;

        execPayload = abi.encodeWithSelector(this.distributeRewards.selector);
    }

    /// @notice Starts the reward distribution task
    function startDistribution() external onlyOwner {
        IOps(ops).createTask(
            address(this),
            this.distributeRewards.selector,
            address(this),
            abi.encodeWithSelector(this.canExecuteDistribution.selector)
        );
    }

    /// @notice Distributes rewards to CoreReserve depositors (LPs)
    function distributeRewards()
        external
        nonReentrant
        onlyOpsOrOwner
        returns (bool)
    {
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

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    /// @param _tokenAddress The address of the ERC20 token
    function emergencyWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).safeTransfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/SafeERC20.sol";

interface IOps {
    function gelato() external view returns (address payable);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);
}

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
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

import "./dependencies/openzeppelin/EnumerableMap.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

/// @title A contract for managing a waitlist
/// @author https://github.com/softlinkprotocol
contract WaitlistV0 is Pausable, Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice A mapping to keep track of those who signed up to the waitlist
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

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Returns the total addresses that are in the waitlist
    function totalInWaitList() public view returns (uint256) {
        return EnumerableMap.length(waitlist);
    }

    /// @notice Adds the caller to the waitlist
    function join() public whenNotPaused {
        (bool success, ) = EnumerableMap.tryGet(waitlist, msg.sender);
        require(!success, "Already joined.");

        success = EnumerableMap.set(waitlist, msg.sender, 1);
        require(success, "Failed to join waitlist");
    }

    /// @notice Returns whether or not the target address is in the waitlist
    /// @param _target Self-explanatory
    function hasEntered(address _target) public view returns (bool success) {
        (success, ) = EnumerableMap.tryGet(waitlist, _target);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "lib/compound-protocol/contracts/CErc20.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

/// @title A contract for managing lending out funds to the Iron Bank protocol
/// @author https://github.com/softlinkprotocol
contract IronBankLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice A mapping from a CoreReserve token address to a cToken address
    mapping(address => address) reserveTokenToIToken;

    /// @notice A mapping from a depositor's address to their total ERC20 token deposit in the lending protocol
    mapping(address => uint256) erc20Deposits;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /// @notice Emitted whenever a deposit into an AAVE lending pool occurs.
    /// @param isNativeDeposit Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param depositAmount Self-explanatory
    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    /// @notice Emitted whenever a withdrawal from an AAVE lending pool occurs.
    /// @param isNativeWithdraw Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param withdrawAmount Self-explanatory
    event Withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    );

    /* ========== FUNCTIONS ========== */

    constructor() Ownable() {}

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Updates the reserveTokenToIToken map
    /// @param _reserveToken Self-explanatory
    /// @param _iToken Self-explanatory
    function updateReserveTokenToIToken(address _reserveToken, address _iToken)
        public
        onlyOwner
    {
        reserveTokenToIToken[_reserveToken] = _iToken;
    }

    /// @notice Deposits funds into the protocol's lending pool.
    /// @param _isNativeDeposit Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _depositAmount Self-explanatory
    function deposit(
        bool _isNativeDeposit,
        address _reserveTokenAddress,
        uint256 _depositAmount
    ) external payable override nonReentrant returns (uint) {
        require(
            !_isNativeDeposit,
            "Iron Bank does not accept the network's native asset."
        );

        IERC20 reserveToken = IERC20(_reserveTokenAddress);
        address iTokenAddress = reserveTokenToIToken[_reserveTokenAddress];
        require(
            iTokenAddress != address(0),
            "IToken mapping does not exist for the given _reserveTokenAddress"
        );

        reserveToken.transferFrom(msg.sender, address(this), _depositAmount);

        CErc20 iToken = CErc20(iTokenAddress);

        reserveToken.approve(address(iToken), _depositAmount);

        uint callerBalanceBefore = IERC20(iTokenAddress).balanceOf(
            address(this)
        );

        require(iToken.mint(_depositAmount) == 0, "Failed to mint iToken(s)");

        uint callerBalanceAfterDiff = IERC20(iTokenAddress)
            .balanceOf(address(this))
            .sub(callerBalanceBefore);
        require(
            callerBalanceAfterDiff > 0,
            "callerBalanceAfterDiff must be > 0"
        );

        iToken.transfer(msg.sender, callerBalanceAfterDiff);

        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].add(
            callerBalanceAfterDiff
        );

        return callerBalanceAfterDiff;
    }

    /// @notice Withdraws funds from a protocol's lending pool.
    /// @param _isNativeWithdraw Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _withdrawAmount Self-explanatory
    function withdraw(
        bool _isNativeWithdraw,
        address _reserveTokenAddress,
        uint256 _withdrawAmount
    ) external override nonReentrant {
        /// @dev _withdrawAmount must be the amount of iTokens that will be redeemed, not the initial deposit amount.
        require(
            !_isNativeWithdraw,
            "Iron Bank does not accept the network's native asset."
        );
        require(
            erc20Deposits[msg.sender] >= _withdrawAmount,
            "_withdrawAmount > _depositAmount"
        );

        IERC20 reserveToken = IERC20(_reserveTokenAddress);
        address iTokenAddress = reserveTokenToIToken[_reserveTokenAddress];
        require(
            iTokenAddress != address(0),
            "IToken mapping does not exist for the given _reserveTokenAddress"
        );

        CErc20 iToken = CErc20(iTokenAddress);

        uint256 reserveTokenBalanceBefore = reserveToken.balanceOf(
            address(this)
        );

        require(
            iToken.redeem(_withdrawAmount) == 0,
            "Failed to withdraw iTokens"
        );

        uint256 reserveTokenBalanceDiff = reserveToken
            .balanceOf(address(this))
            .sub(reserveTokenBalanceBefore);
        require(
            reserveTokenBalanceDiff > 0,
            "reserveTokenBalanceDiff must be > 0"
        );

        reserveToken.transfer(msg.sender, reserveTokenBalanceDiff);

        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].sub(
            _withdrawAmount
        );
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    function emergencyWithdrawERC20(address _tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);

        return true;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";

interface CompLike {
    function delegate(address delegatee) external;
}

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract CErc20 is CToken, CErc20Interface {
    /**
     * @notice Initialize the new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     */
    function initialize(address underlying_,
                        ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        // CToken initialize does the bulk of the work
        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) override external returns (uint) {
        mintInternal(mintAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) override external returns (uint) {
        redeemInternal(redeemTokens);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) override external returns (uint) {
        redeemUnderlyingInternal(redeemAmount);
        return NO_ERROR;
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) override external returns (uint) {
        borrowInternal(borrowAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) override external returns (uint) {
        repayBorrowInternal(repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) override external returns (uint) {
        repayBorrowBehalfInternal(borrower, repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param cTokenCollateral The market in which to seize collateral from the borrower
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) override external returns (uint) {
        liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
        return NO_ERROR;
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(EIP20NonStandardInterface token) override external {
        require(msg.sender == admin, "CErc20::sweepToken: only admin can sweep tokens");
        require(address(token) != underlying, "CErc20::sweepToken: can not sweep underlying token");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(admin, balance);
    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount fo underlying token to add as reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves(uint addAmount) override external returns (uint) {
        return _addReservesInternal(addAmount);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() virtual override internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint amount) virtual override internal returns (uint) {
        // Read from storage once
        address underlying_ = underlying;
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying_);
        uint balanceBefore = EIP20Interface(underlying_).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of override external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying_).balanceOf(address(this));
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint amount) virtual override internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of override external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    /**
    * @notice Admin call to delegate the votes of the COMP-like underlying
    * @param compLikeDelegatee The address to delegate votes to
    * @dev CTokens whose underlying are not CompLike should revert here
    */
    function _delegateCompLikeTo(address compLikeDelegatee) external {
        require(msg.sender == admin, "only the admin may set the comp-like delegate");
        CompLike(underlying).delegate(compLikeDelegatee);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./ExponentialNoError.sol";

/**
 * @title Compound's CToken Contract
 * @notice Abstract base for CTokens
 * @author Compound
 */
abstract contract CToken is CTokenInterface, ExponentialNoError, TokenErrorReporter {
    /**
     * @notice Initialize the money market
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     */
    function initialize(ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        require(msg.sender == admin, "only admin may initialize the market");
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        // Set initial exchange rate
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        // Set the comptroller
        uint err = _setComptroller(comptroller_);
        require(err == NO_ERROR, "setting comptroller failed");

        // Initialize block number and borrow index (block number mocks depend on comptroller being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = mantissaOne;

        // Set the interest rate model (depends on block number / borrow index)
        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == NO_ERROR, "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return 0 if the transfer succeeded, else revert
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Fail if transfer not allowed */
        uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
        if (allowed != 0) {
            revert TransferComptrollerRejection(allowed);
        }

        /* Do not allow self-transfers */
        if (src == dst) {
            revert TransferNotAllowed();
        }

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        uint allowanceNew = startingAllowance - tokens;
        uint srcTokensNew = accountTokens[src] - tokens;
        uint dstTokensNew = accountTokens[dst] + tokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        // unused function
        // comptroller.transferVerify(address(this), src, dst, tokens);

        return NO_ERROR;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == NO_ERROR;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == NO_ERROR;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (uint256.max means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) override external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) override external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) override external view returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) override external returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) override external view returns (uint, uint, uint, uint) {
        return (
            NO_ERROR,
            accountTokens[account],
            borrowBalanceStoredInternal(account),
            exchangeRateStoredInternal()
        );
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() virtual internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() override external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() override external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() override external nonReentrant returns (uint) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) override external nonReentrant returns (uint) {
        accrueInterest();
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) override public view returns (uint) {
        return borrowBalanceStoredInternal(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        uint principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        return principalTimesIndex / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() override public nonReentrant returns (uint) {
        accrueInterest();
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() override public view returns (uint) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() virtual internal view returns (uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves = totalCash + totalBorrows - totalReserves;
            uint exchangeRate = cashPlusBorrowsMinusReserves * expScale / _totalSupply;

            return exchangeRate;
        }
    }

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() override external view returns (uint) {
        return getCashPrior();
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() virtual override public returns (uint) {
        /* Remember the initial block number */
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return NO_ERROR;
        }

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        uint blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor = mul_(Exp({mantissa: borrowRateMantissa}), blockDelta);
        uint interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
        uint totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint totalReservesNew = mul_ScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        uint borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return NO_ERROR;
    }

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mintInternal(uint mintAmount) internal nonReentrant {
        accrueInterest();
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        mintFresh(msg.sender, mintAmount);
    }

    /**
     * @notice User supplies assets into the market and receives cTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mintFresh(address minter, uint mintAmount) internal {
        /* Fail if mint not allowed */
        uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
        if (allowed != 0) {
            revert MintComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert MintFreshnessCheck();
        }

        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
         *  of cash.
         */
        uint actualMintAmount = doTransferIn(minter, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of cTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        uint mintTokens = div_(actualMintAmount, exchangeRate);

        /*
         * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         * And write them into storage
         */
        totalSupply = totalSupply + mintTokens;
        accountTokens[minter] = accountTokens[minter] + mintTokens;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, actualMintAmount, mintTokens);
        emit Transfer(address(this), minter, mintTokens);

        /* We call the defense hook */
        // unused function
        // comptroller.mintVerify(address(this), minter, actualMintAmount, mintTokens);
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     */
    function redeemInternal(uint redeemTokens) internal nonReentrant {
        accrueInterest();
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        redeemFresh(payable(msg.sender), redeemTokens, 0);
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming cTokens
     */
    function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant {
        accrueInterest();
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        redeemFresh(payable(msg.sender), 0, redeemAmount);
    }

    /**
     * @notice User redeems cTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        /* exchangeRate = invoke Exchange Rate Stored() */
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal() });

        uint redeemTokens;
        uint redeemAmount;
        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            redeemTokens = redeemTokensIn;
            redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */
            redeemTokens = div_(redeemAmountIn, exchangeRate);
            redeemAmount = redeemAmountIn;
        }

        /* Fail if redeem not allowed */
        uint allowed = comptroller.redeemAllowed(address(this), redeemer, redeemTokens);
        if (allowed != 0) {
            revert RedeemComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert RedeemFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient cash */
        if (getCashPrior() < redeemAmount) {
            revert RedeemTransferOutNotPossible();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)


        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing reduced supply before external transfer.
         */
        totalSupply = totalSupply - redeemTokens;
        accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(redeemer, redeemAmount);

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens);

        /* We call the defense hook */
        comptroller.redeemVerify(address(this), redeemer, redeemAmount, redeemTokens);
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      */
    function borrowInternal(uint borrowAmount) internal nonReentrant {
        accrueInterest();
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        borrowFresh(payable(msg.sender), borrowAmount);
    }

    /**
      * @notice Users borrow assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      */
    function borrowFresh(address payable borrower, uint borrowAmount) internal {
        /* Fail if borrow not allowed */
        uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            revert BorrowComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert BorrowFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (getCashPrior() < borrowAmount) {
            revert BorrowCashNotAvailable();
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowNew = accountBorrow + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
        uint accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint totalBorrowsNew = totalBorrows + borrowAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing increased borrow before external transfer.
        `*/
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(borrower, borrowAmount);

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     */
    function repayBorrowInternal(uint repayAmount) internal nonReentrant {
        accrueInterest();
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     */
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant {
        accrueInterest();
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned, or -1 for the full outstanding amount
     * @return (uint) the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint) {
        /* Fail if repayBorrow not allowed */
        uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        if (allowed != 0) {
            revert RepayBorrowComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert RepayBorrowFreshnessCheck();
        }

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint accountBorrowsPrev = borrowBalanceStoredInternal(borrower);

        /* If repayAmount == -1, repayAmount = accountBorrows */
        uint repayAmountFinal = repayAmount == type(uint).max ? accountBorrowsPrev : repayAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        uint actualRepayAmount = doTransferIn(payer, repayAmountFinal);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint accountBorrowsNew = accountBorrowsPrev - actualRepayAmount;
        uint totalBorrowsNew = totalBorrows - actualRepayAmount;

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);

        return actualRepayAmount;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param cTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     */
    function liquidateBorrowInternal(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal nonReentrant {
        accrueInterest();

        uint error = cTokenCollateral.accrueInterest();
        if (error != NO_ERROR) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            revert LiquidateAccrueCollateralInterestFailed(error);
        }

        // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
        liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param cTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     */
    function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal {
        /* Fail if liquidate not allowed */
        uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
        if (allowed != 0) {
            revert LiquidateComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert LiquidateFreshnessCheck();
        }

        /* Verify cTokenCollateral market's block number equals current block number */
        if (cTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
            revert LiquidateCollateralFreshnessCheck();
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            revert LiquidateLiquidatorIsBorrower();
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            revert LiquidateCloseAmountIsZero();
        }

        /* Fail if repayAmount = -1 */
        if (repayAmount == type(uint).max) {
            revert LiquidateCloseAmountIsUintMax();
        }

        /* Fail if repayBorrow fails */
        uint actualRepayAmount = repayBorrowFresh(liquidator, borrower, repayAmount);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(cTokenCollateral), actualRepayAmount);
        require(amountSeizeError == NO_ERROR, "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        /* Revert if borrower collateral token balance < seizeTokens */
        require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

        // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
        if (address(cTokenCollateral) == address(this)) {
            seizeInternal(address(this), liquidator, borrower, seizeTokens);
        } else {
            require(cTokenCollateral.seize(liquidator, borrower, seizeTokens) == NO_ERROR, "token seizure failed");
        }

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another cToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(address liquidator, address borrower, uint seizeTokens) override external nonReentrant returns (uint) {
        seizeInternal(msg.sender, liquidator, borrower, seizeTokens);

        return NO_ERROR;
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
     * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     */
    function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal {
        /* Fail if seize not allowed */
        uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
        if (allowed != 0) {
            revert LiquidateSeizeComptrollerRejection(allowed);
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            revert LiquidateSeizeLiquidatorIsBorrower();
        }

        /*
         * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
         *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
         *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
         */
        uint protocolSeizeTokens = mul_(seizeTokens, Exp({mantissa: protocolSeizeShareMantissa}));
        uint liquidatorSeizeTokens = seizeTokens - protocolSeizeTokens;
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});
        uint protocolSeizeAmount = mul_ScalarTruncate(exchangeRate, protocolSeizeTokens);
        uint totalReservesNew = totalReserves + protocolSeizeAmount;


        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the calculated values into storage */
        totalReserves = totalReservesNew;
        totalSupply = totalSupply - protocolSeizeTokens;
        accountTokens[borrower] = accountTokens[borrower] - seizeTokens;
        accountTokens[liquidator] = accountTokens[liquidator] + liquidatorSeizeTokens;

        /* Emit a Transfer event */
        emit Transfer(borrower, liquidator, liquidatorSeizeTokens);
        emit Transfer(borrower, address(this), protocolSeizeTokens);
        emit ReservesAdded(address(this), protocolSeizeAmount, totalReservesNew);
    }


    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address payable newPendingAdmin) override external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            revert SetPendingAdminOwnerCheck();
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return NO_ERROR;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() override external returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            revert AcceptAdminPendingAdminCheck();
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = payable(address(0));

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return NO_ERROR;
    }

    /**
      * @notice Sets a new comptroller for the market
      * @dev Admin function to set a new comptroller
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setComptroller(ComptrollerInterface newComptroller) override public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            revert SetComptrollerOwnerCheck();
        }

        ComptrollerInterface oldComptroller = comptroller;
        // Ensure invoke comptroller.isComptroller() returns true
        require(newComptroller.isComptroller(), "marker method returned false");

        // Set market's comptroller to newComptroller
        comptroller = newComptroller;

        // Emit NewComptroller(oldComptroller, newComptroller)
        emit NewComptroller(oldComptroller, newComptroller);

        return NO_ERROR;
    }

    /**
      * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
      * @dev Admin function to accrue interest and set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactor(uint newReserveFactorMantissa) override external nonReentrant returns (uint) {
        accrueInterest();
        // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    /**
      * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
      * @dev Admin function to set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            revert SetReserveFactorAdminCheck();
        }

        // Verify market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetReserveFactorFreshCheck();
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            revert SetReserveFactorBoundsCheck();
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return NO_ERROR;
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring from msg.sender
     * @param addAmount Amount of addition to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
        accrueInterest();

        // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
        _addReservesFresh(addAmount);
        return NO_ERROR;
    }

    /**
     * @notice Add reserves by transferring from caller
     * @dev Requires fresh interest accrual
     * @param addAmount Amount of addition to reserves
     * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
     */
    function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
        // totalReserves + actualAddAmount
        uint totalReservesNew;
        uint actualAddAmount;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert AddReservesFactorFreshCheck(actualAddAmount);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */

        actualAddAmount = doTransferIn(msg.sender, addAmount);

        totalReservesNew = totalReserves + actualAddAmount;

        // Store reserves[n+1] = reserves[n] + actualAddAmount
        totalReserves = totalReservesNew;

        /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        /* Return (NO_ERROR, actualAddAmount) */
        return (NO_ERROR, actualAddAmount);
    }


    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint reduceAmount) override external nonReentrant returns (uint) {
        accrueInterest();
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(reduceAmount);
    }

    /**
     * @notice Reduces reserves by transferring to admin
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        // totalReserves - reduceAmount
        uint totalReservesNew;

        // Check caller is admin
        if (msg.sender != admin) {
            revert ReduceReservesAdminCheck();
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert ReduceReservesFreshCheck();
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (getCashPrior() < reduceAmount) {
            revert ReduceReservesCashNotAvailable();
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            revert ReduceReservesCashValidation();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        totalReservesNew = totalReserves - reduceAmount;

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);

        return NO_ERROR;
    }

    /**
     * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) override public returns (uint) {
        accrueInterest();
        // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {

        // Used to store old model for use in the event that is emitted on success
        InterestRateModel oldInterestRateModel;

        // Check caller is admin
        if (msg.sender != admin) {
            revert SetInterestRateModelOwnerCheck();
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetInterestRateModelFreshCheck();
        }

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return NO_ERROR;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying owned by this contract
     */
    function getCashPrior() virtual internal view returns (uint);

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(address from, uint amount) virtual internal returns (uint);

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(address payable to, uint amount) virtual internal;


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) virtual external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) virtual external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) virtual external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) virtual external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";

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
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint internal constant reserveFactorMaxMantissa = 1e18;

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
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    // Official record of token balances for each account
    mapping (address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
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
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);


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
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);


    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);
    function balanceOfUnderlying(address owner) virtual external returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() virtual external view returns (uint);
    function supplyRatePerBlock() virtual external view returns (uint);
    function totalBorrowsCurrent() virtual external returns (uint);
    function borrowBalanceCurrent(address account) virtual external returns (uint);
    function borrowBalanceStored(address account) virtual external view returns (uint);
    function exchangeRateCurrent() virtual external returns (uint);
    function exchangeRateStored() virtual external view returns (uint);
    function getCash() virtual external view returns (uint);
    function accrueInterest() virtual external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) virtual external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) virtual external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);
    function _reduceReserves(uint reduceAmount) virtual external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual external returns (uint);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

abstract contract CErc20Interface is CErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) virtual external returns (uint);
    function redeem(uint redeemTokens) virtual external returns (uint);
    function redeemUnderlying(uint redeemAmount) virtual external returns (uint);
    function borrow(uint borrowAmount) virtual external returns (uint);
    function repayBorrow(uint repayAmount) virtual external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) virtual external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) virtual external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) virtual external;


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) virtual external returns (uint);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) virtual external;
}

abstract contract CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) virtual external;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() virtual external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    uint public constant NO_ERROR = 0; // support legacy return codes

    error TransferComptrollerRejection(uint256 errorCode);
    error TransferNotAllowed();
    error TransferNotEnough();
    error TransferTooMuch();

    error MintComptrollerRejection(uint256 errorCode);
    error MintFreshnessCheck();

    error RedeemComptrollerRejection(uint256 errorCode);
    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();

    error BorrowComptrollerRejection(uint256 errorCode);
    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowComptrollerRejection(uint256 errorCode);
    error RepayBorrowFreshnessCheck();

    error LiquidateComptrollerRejection(uint256 errorCode);
    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();
    error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

    error LiquidateSeizeComptrollerRejection(uint256 errorCode);
    error LiquidateSeizeLiquidatorIsBorrower();

    error AcceptAdminPendingAdminCheck();

    error SetComptrollerOwnerCheck();
    error SetPendingAdminOwnerCheck();

    error SetReserveFactorAdminCheck();
    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesAdminCheck();
    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelOwnerCheck();
    error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

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
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return a + b;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return a * b;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

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
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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

/// @title A contract for managing lending out funds to the Euler protocol
/// @author https://github.com/softlinkprotocol
contract EulerLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice The address of the Euler Main Contract
    address internal eulerMainContract;

    /// @notice The address of the Euler Markets Contract
    address internal eulerMarketsContract;

    /// @notice A mapping from a depositor's address to their total ERC20 token deposit in the lending protocol
    mapping(address => uint256) erc20Deposits;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /// @notice Emitted whenever a deposit into an AAVE lending pool occurs.
    /// @param isNativeDeposit Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param depositAmount Self-explanatory
    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    /// @notice Emitted whenever a withdrawal from an AAVE lending pool occurs.
    /// @param isNativeWithdraw Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param withdrawAmount Self-explanatory
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

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Deposits funds into the protocol's lending pool.
    /// @param _isNativeDeposit Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _depositAmount Self-explanatory
    function deposit(
        bool _isNativeDeposit,
        address _reserveTokenAddress,
        uint256 _depositAmount
    ) external payable override nonReentrant returns (uint) {
        require(!_isNativeDeposit, "Manager does not accept native deposits");
        // Approve the main euler contract to pull your tokens:
        IERC20(_reserveTokenAddress).approve(eulerMainContract, _depositAmount);

        // Fetch the funds from the sender in order to deposit into the Euler reserve:
        IERC20(_reserveTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );

        // Use the markets module:
        IEulerMarkets markets = IEulerMarkets(eulerMarketsContract);

        // Get the eToken address using the markets module:
        IEulerEToken eToken = IEulerEToken(
            markets.underlyingToEToken(_reserveTokenAddress)
        );

        uint eTokenBalanceBefore = eToken.balanceOf(address(this));

        // The "0" argument refers to the sub-account you are depositing to.
        eToken.deposit(0, _depositAmount);

        uint eTokenBalanceAfterDiff = eToken.balanceOf(address(this)).sub(
            eTokenBalanceBefore
        );
        require(
            eTokenBalanceAfterDiff > 0,
            "eTokenBalanceAfterDiff must be > 0"
        );

        // Keep track of euler deposits:
        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].add(
            eTokenBalanceAfterDiff
        );

        // Transfer the minted eTokens:
        eToken.transfer(msg.sender, eTokenBalanceAfterDiff);

        emit Deposit(false, _reserveTokenAddress, _depositAmount);

        return eTokenBalanceAfterDiff;
    }

    /// @notice Withdraws funds from a protocol's lending pool.
    /// @param _isNativeWithdraw Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _withdrawAmount Self-explanatory
    function withdraw(
        bool _isNativeWithdraw,
        address _reserveTokenAddress,
        uint256 _withdrawAmount
    ) external override nonReentrant {
        /// @dev _withdrawAmount must be the amount of eTokens that will be redeemed, not the initial deposit amount.

        // Make sure they can withdraw that amount
        require(
            erc20Deposits[msg.sender] >= _withdrawAmount,
            "withdraw amount > deposit amount"
        );

        // Use the markets module:
        IEulerMarkets markets = IEulerMarkets(eulerMarketsContract);

        // Get the eToken address using the markets module:
        IEulerEToken eToken = IEulerEToken(
            markets.underlyingToEToken(_reserveTokenAddress)
        );

        // Fetch the funds from the sender in order to deposit into the Euler reserve:
        eToken.transferFrom(msg.sender, address(this), _withdrawAmount);

        uint256 initialReserveTokenBalance = IERC20(_reserveTokenAddress)
            .balanceOf(address(this));

        // Later on, withdraw your initial deposit and all earned interest:
        eToken.withdraw(0, _withdrawAmount);

        uint256 reserveTokenBalanceAfterDiff = IERC20(_reserveTokenAddress)
            .balanceOf(address(this))
            .sub(initialReserveTokenBalance);

        // Transfer over the difference:
        IERC20(_reserveTokenAddress).transfer(
            msg.sender,
            reserveTokenBalanceAfterDiff
        );

        // Update msg.sender's deposit
        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].sub(
            _withdrawAmount
        );

        emit Withdraw(_isNativeWithdraw, _reserveTokenAddress, _withdrawAmount);
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    function emergencyWithdrawERC20(address _tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);

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

pragma solidity >=0.8.0;

import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

/// @title A contract for managing the SoftLink Protocol treasury
/// @author https://github.com/softlinkprotocol
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

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
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
    /// @param _tokenAddress Self-explanatory
    /// @param _tokenAmount Self-explanatory
    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit Withdraw(_tokenAddress, _tokenAmount);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "lib/compound-protocol/contracts/CErc20.sol";
import "./dependencies/compound/interfaces/ICompound.sol";
import "./dependencies/interfaces/ILendingYieldManager.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";
import "./dependencies/openzeppelin/SafeMath.sol";

/// @title A contract for managing lending out funds to the Compound protocol
/// @author https://github.com/softlinkprotocol
contract CompoundLendingYieldManager is
    ILendingYieldManager,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @notice The address for the cETH token
    CEth cETH;

    /// @notice A mapping from a CoreReserve token address to a cToken address
    mapping(address => address) reserveTokenToCToken;

    /// @notice A mapping from a depositor's address to their total native token deposit in the lending protocol
    mapping(address => uint256) nativeDeposits;

    /// @notice A mapping from a depositor's address to their total ERC20 token deposit in the lending protocol
    mapping(address => uint256) erc20Deposits;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the fallback or receive function is emitted
    /// @param caller Self-explanatory
    /// @param msgValue Self-explanatory
    event ReceiveOrFallback(address caller, uint256 msgValue);

    /// @notice Emitted whenever ETH deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param amount Self-explanatory
    event ETHEmergencyWithdraw(address owner, uint256 amount);

    /// @notice Emitted whenever an ERC20 token deposited into the contract is withdrawed
    /// @param owner Self-explanatory
    /// @param tokenAddress Self-explanatory
    /// @param amount Self-explanatory
    event ERC20EmergencyWithdraw(
        address owner,
        address tokenAddress,
        uint256 amount
    );

    /// @notice Emitted whenever a deposit into an AAVE lending pool occurs.
    /// @param isNativeDeposit Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param depositAmount Self-explanatory
    event Deposit(
        bool isNativeDeposit,
        address reserveTokenAddress,
        uint256 depositAmount
    );

    /// @notice Emitted whenever a withdrawal from an AAVE lending pool occurs.
    /// @param isNativeWithdraw Self-explanatory
    /// @param reserveTokenAddress Self-explanatory
    /// @param withdrawAmount Self-explanatory
    event Withdraw(
        bool isNativeWithdraw,
        address reserveTokenAddress,
        uint256 withdrawAmount
    );

    /* ========== FUNCTIONS ========== */

    constructor(address _cETHContractAddress) Ownable() {
        cETH = CEth(_cETHContractAddress);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    receive() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Refresh on method: https://solidity-by-example.org/fallback/
    fallback() external payable {
        emit ReceiveOrFallback(msg.sender, msg.value);
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Un-pauses the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Updates the reserveTokereserveTokenToCTokennToIToken map
    /// @param _reserveToken Self-explanatory
    /// @param _cToken Self-explanatory
    function updateReserveTokenToCToken(address _reserveToken, address _cToken)
        public
        onlyOwner
    {
        reserveTokenToCToken[_reserveToken] = _cToken;
    }

    /// @notice Deposits funds into the protocol's lending pool.
    /// @param _isNativeDeposit Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _depositAmount Self-explanatory
    function deposit(
        bool _isNativeDeposit,
        address _reserveTokenAddress,
        uint256 _depositAmount
    ) external payable override nonReentrant returns (uint) {
        if (_isNativeDeposit) {
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

            emit Deposit(_isNativeDeposit, _reserveTokenAddress, msg.value);

            return balDiff;
        }

        IERC20 reserveToken = IERC20(_reserveTokenAddress);
        address cTokenAddress = reserveTokenToCToken[_reserveTokenAddress];

        require(
            cTokenAddress != address(0),
            "CToken mapping does not exist for the given _reserveTokenAddress"
        );

        IERC20 cTokenERC20 = IERC20(cTokenAddress);
        CErc20 cToken = CErc20(cTokenAddress);

        reserveToken.transferFrom(msg.sender, address(this), _depositAmount);
        reserveToken.approve(cTokenAddress, _depositAmount);

        uint256 cTokensBalanceBefore = cTokenERC20.balanceOf(address(this));
        uint256 mintStatus = cToken.mint(_depositAmount);
        uint256 balDiff = cTokenERC20.balanceOf(address(this)).sub(
            cTokensBalanceBefore
        );

        require(
            mintStatus == 0 && balDiff > 0,
            "Failed to successfully mint cToken"
        );

        require(mintStatus == 0, "Failed to successfully mint cToken");

        erc20Deposits[msg.sender] = erc20Deposits[msg.sender].add(balDiff);

        cTokenERC20.transfer(msg.sender, balDiff);

        emit Deposit(_isNativeDeposit, _reserveTokenAddress, _depositAmount);

        return _depositAmount;
    }

    /// @notice Withdraws funds from a protocol's lending pool.
    /// @param _isNativeWithdraw Self-explanatory
    /// @param _reserveTokenAddress Self-explanatory
    /// @param _withdrawAmount Self-explanatory
    function withdraw(
        bool _isNativeWithdraw,
        address _reserveTokenAddress,
        uint256 _withdrawAmount
    ) external override nonReentrant {
        /// @dev _withdrawAmount must be the amount of cTokens that will be redeemed, not the initial deposit amount.
        if (_isNativeWithdraw) {
            uint totalNativeDeposit = nativeDeposits[msg.sender];
            require(
                totalNativeDeposit >= _withdrawAmount,
                "_withdrawAmount > _depositAmount"
            );

            IERC20(address(cETH)).transferFrom(
                msg.sender,
                address(this),
                _withdrawAmount
            );

            uint256 nativeBalanceBefore = address(this).balance;
            uint256 redeemStatus = cETH.redeem(_withdrawAmount);
            uint256 diff = address(this).balance.sub(nativeBalanceBefore);

            require(
                redeemStatus == 0 && diff > 0,
                "redeemStatus must be 0 && diff must be > 0"
            );

            (bool sent, ) = address(payable(msg.sender)).call{value: diff}("");
            require(sent, "Failed to transfer ether back to depositor");

            nativeDeposits[msg.sender] = totalNativeDeposit.sub(
                _withdrawAmount
            );

            emit Withdraw(
                _isNativeWithdraw,
                _reserveTokenAddress,
                _withdrawAmount
            );
        } else {
            uint totalERC20Deposit = erc20Deposits[msg.sender];
            require(
                totalERC20Deposit >= _withdrawAmount,
                "_withdrawAmount > _depositAmount"
            );

            IERC20 reserveToken = IERC20(_reserveTokenAddress);
            address cTokenAddress = reserveTokenToCToken[_reserveTokenAddress];
            require(
                cTokenAddress != address(0),
                "CToken mapping does not exist for the given _reserveTokenAddress"
            );

            CErc20 cToken = CErc20(cTokenAddress);

            IERC20(cTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _withdrawAmount
            );

            uint256 reserveTokenBalanceBefore = reserveToken.balanceOf(
                address(this)
            );
            uint256 redeemStatus = cToken.redeem(_withdrawAmount);
            uint256 reserveTokenBalanceDiff = reserveToken
                .balanceOf(address(this))
                .sub(reserveTokenBalanceBefore);

            require(
                redeemStatus == 0 && reserveTokenBalanceDiff > 0,
                "redeemStatus must be 0 && reserveTokenBalanceDiff must be > 0"
            );

            reserveToken.transfer(msg.sender, reserveTokenBalanceDiff);

            erc20Deposits[msg.sender] = totalERC20Deposit.sub(_withdrawAmount);

            emit Withdraw(
                _isNativeWithdraw,
                _reserveTokenAddress,
                _withdrawAmount
            );
        }
    }

    /// @notice Withdraws the ETH stored in the contract in case of an emergency
    function emergencyWithdrawETH() external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);

        emit ETHEmergencyWithdraw(msg.sender, balance);

        return true;
    }

    /// @notice Withdraws ERC20 token balances stored in the contract in case of an emergency
    function emergencyWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

        IERC20(_tokenAddress).transfer(owner(), balance);

        emit ERC20EmergencyWithdraw(msg.sender, _tokenAddress, balance);

        return true;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);
}