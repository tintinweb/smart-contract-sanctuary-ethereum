// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/IInterestRates.sol";
import "./positions-manager-parts/PositionsManagerForAaveStorage.sol";

import "./libraries/Math.sol";
import "./libraries/Types.sol";

contract InterestRatesV1 is IInterestRates {
    using Math for uint256;

    /// STRUCT ///

    struct Vars {
        uint256 shareOfTheDelta; // Share of delta in the total P2P amount.
        uint256 supplyP2PGrowthFactor; // Supply growth factor (between now and the last update).
        uint256 borrowP2PGrowthFactor; // Borrow growth factor (between now and the last update).
        uint256 supplyPoolGrowthFactor; // Borrow growth factor (between now and the last update).
        uint256 borrowPoolGrowthFactor; // Borrow growth factor (between now and the last update).
    }

    /// STORAGE ///

    uint256 public constant MAX_BASIS_POINTS = 10_000; // 100% (in basis point).

    /// EXTERNAL ///

    /// @notice Computes and return new P2P exchange rates.
    /// @param _params Parameters:
    ///             supplyP2PEchangeRate The current supply P2P exchange rate.
    ///             borrowP2PExchangeRate The current borrow P2P exchange rate.
    ///             poolSupplyExchangeRate The current pool supply exchange rate.
    ///             poolBorrowExchangeRate The current pool borrow exchange rate.
    ///             lastPoolSupplyExchangeRate The pool supply exchange rate at last update.
    ///             lastPoolBorrowExchangeRate The pool borrow exchange rate at last update.
    ///             reserveFactor The reserve factor percentage (10 000 = 100%).
    ///             delta The deltas and P2P amounts.
    /// @return newSupplyP2PExchangeRate The updated supplyP2PExchangeRate.
    /// @return newBorrowP2PExchangeRate The updated borrowP2PExchangeRate.
    function computeP2PExchangeRates(Types.Params memory _params)
        public
        pure
        returns (uint256 newSupplyP2PExchangeRate, uint256 newBorrowP2PExchangeRate)
    {
        Vars memory vars;
        (
            vars.supplyP2PGrowthFactor,
            vars.borrowP2PGrowthFactor,
            vars.supplyPoolGrowthFactor,
            vars.borrowPoolGrowthFactor
        ) = _computeGrowthFactors(
            _params.poolSupplyExchangeRate,
            _params.poolBorrowExchangeRate,
            _params.lastPoolSupplyExchangeRate,
            _params.lastPoolBorrowExchangeRate,
            _params.reserveFactor
        );

        if (_params.delta.supplyP2PAmount == 0 || _params.delta.supplyP2PDelta == 0) {
            newSupplyP2PExchangeRate = _params.supplyP2PExchangeRate.rayMul(
                vars.supplyP2PGrowthFactor
            );
        } else {
            vars.shareOfTheDelta = Math.min(
                _params
                .delta
                .supplyP2PDelta
                .wadToRay()
                .rayMul(_params.poolSupplyExchangeRate)
                .rayDiv(_params.supplyP2PExchangeRate)
                .rayDiv(_params.delta.supplyP2PAmount.wadToRay()),
                Math.ray() // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newSupplyP2PExchangeRate = _params.supplyP2PExchangeRate.rayMul(
                (Math.ray() - vars.shareOfTheDelta).rayMul(vars.supplyP2PGrowthFactor) +
                    vars.shareOfTheDelta.rayMul(vars.supplyPoolGrowthFactor)
            );
        }

        if (_params.delta.borrowP2PAmount == 0 || _params.delta.borrowP2PDelta == 0) {
            newBorrowP2PExchangeRate = _params.borrowP2PExchangeRate.rayMul(
                vars.borrowP2PGrowthFactor
            );
        } else {
            vars.shareOfTheDelta = Math.min(
                _params
                .delta
                .borrowP2PDelta
                .wadToRay()
                .rayMul(_params.poolBorrowExchangeRate)
                .rayDiv(_params.borrowP2PExchangeRate)
                .rayDiv(_params.delta.borrowP2PAmount.wadToRay()),
                Math.ray() // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newBorrowP2PExchangeRate = _params.borrowP2PExchangeRate.rayMul(
                (Math.ray() - vars.shareOfTheDelta).rayMul(vars.borrowP2PGrowthFactor) +
                    vars.shareOfTheDelta.rayMul(vars.borrowPoolGrowthFactor)
            );
        }
    }

    /// @notice Computes and returns supply P2P growth factor and borrow P2P growth factor.
    /// @param _poolSupplyExchangeRate The current pool supply exchange rate.
    /// @param _poolBorrowExchangeRate The current pool borrow exchange rate.
    /// @param _lastPoolSupplyExchangeRate The pool supply exchange rate at last update.
    /// @param _lastPoolBorrowExchangeRate The pool borrow exchange rate at last update.
    /// @param _reserveFactor The reserve factor percentage (10 000 = 100%).
    /// @return supplyP2PGrowthFactor The supply P2P growth factor.
    /// @return borrowP2PGrowthFactor The borrow P2P growth factor.
    /// @return supplyPoolGrowthFactor The supply pool growth factor.
    /// @return borrowPoolGrowthFactor The borrow pool growth factor.
    function _computeGrowthFactors(
        uint256 _poolSupplyExchangeRate,
        uint256 _poolBorrowExchangeRate,
        uint256 _lastPoolSupplyExchangeRate,
        uint256 _lastPoolBorrowExchangeRate,
        uint256 _reserveFactor
    )
        internal
        pure
        returns (
            uint256 supplyP2PGrowthFactor,
            uint256 borrowP2PGrowthFactor,
            uint256 supplyPoolGrowthFactor,
            uint256 borrowPoolGrowthFactor
        )
    {
        supplyPoolGrowthFactor = _poolSupplyExchangeRate.rayDiv(_lastPoolSupplyExchangeRate);
        borrowPoolGrowthFactor = _poolBorrowExchangeRate.rayDiv(_lastPoolBorrowExchangeRate);
        supplyP2PGrowthFactor =
            ((MAX_BASIS_POINTS - _reserveFactor) *
                (2 * supplyPoolGrowthFactor + borrowPoolGrowthFactor)) /
            3 /
            MAX_BASIS_POINTS +
            (_reserveFactor * supplyPoolGrowthFactor) /
            MAX_BASIS_POINTS;

        borrowP2PGrowthFactor =
            ((MAX_BASIS_POINTS - _reserveFactor) *
                (2 * supplyPoolGrowthFactor + borrowPoolGrowthFactor)) /
            3 /
            MAX_BASIS_POINTS +
            (_reserveFactor * borrowPoolGrowthFactor) /
            MAX_BASIS_POINTS;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "../libraries/Types.sol";

interface IInterestRates {
    function computeP2PExchangeRates(Types.Params memory _params)
        external
        pure
        returns (uint256 newSupplyP2PExchangeRate, uint256 newBorrowP2PExchangeRate);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {IVariableDebtToken} from "../interfaces/aave/IVariableDebtToken.sol";
import "../interfaces/aave/ILendingPoolAddressesProvider.sol";
import "../interfaces/aave/IAaveIncentivesController.sol";
import "../interfaces/aave/ILendingPool.sol";
import "../interfaces/IMarketsManagerForAave.sol";
import "../interfaces/IMatchingEngineForAave.sol";
import "../interfaces/IRewardsManagerForAave.sol";
import "../../common/interfaces/ISwapManager.sol";

import "../../common/libraries/DoubleLinkedList.sol";
import "../libraries/Types.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PositionsManagerForAaveStorage is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// ENUMS ///

    enum PositionType {
        SUPPLIERS_IN_P2P,
        SUPPLIERS_ON_POOL,
        BORROWERS_IN_P2P,
        BORROWERS_ON_POOL
    }

    /// STRUCTS ///

    struct SupplyBalance {
        uint256 inP2P; // In supplier's p2pUnit, a unit that grows in value, to keep track of the interests earned when users are in P2P.
        uint256 onPool; // In scaled balance.
    }

    struct BorrowBalance {
        uint256 inP2P; // In borrower's p2pUnit, a unit that grows in value, to keep track of the interests paid when users are in P2P.
        uint256 onPool; // In adUnit, a unit that grows in value, to keep track of the debt increase when users are in Aave. Multiply by current borrowIndex to get the underlying amount.
    }

    // Max gas to consume for supply, borrow, withdraw and repay functions.
    struct MaxGas {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct AssetLiquidityData {
        uint256 collateralValue; // The collateral value of the asset (in ETH).
        uint256 liquidationValue; // The value which made liquidation possible (in ETH).
        uint256 maxDebtValue; // The maximum possible debt value of the asset (in ETH).
        uint256 debtValue; // The debt value of the asset (in ETH).
        uint256 tokenUnit; // The token unit considering its decimals.
        uint256 underlyingPrice; // The price of the token (in ETH).
        uint256 liquidationThreshold; // The liquidation threshold applied on this token (in basis point).
        uint256 ltv; // The LTV applied on this token (in basis point).
    }

    struct LiquidateVars {
        address tokenBorrowedAddress; // The address of the borrowed asset.
        address tokenCollateralAddress; // The address of the collateral asset.
        uint256 debtValue; // The debt value (in ETH).
        uint256 maxDebtValue; // The maximum debt value possible (in ETH).
        uint256 liquidationValue; // The value for a possible liquidation (in ETH).
        uint256 borrowedPrice; // The price of the asset borrowed (in ETH).
        uint256 collateralPrice; // The price of the collateral asset (in ETH).
        uint256 borrowBalance; // Total borrow balance of the user for a given asset (in underlying).
        uint256 supplyBalance; // The total of collateral of the user (in underlying).
        uint256 amountToSeize; // The amount of collateral the liquidator can seize (in underlying).
        uint256 liquidationBonus; // The liquidation bonus on Aave.
        uint256 collateralReserveDecimals; // The number of decimals of the collateral asset in the reserve.
        uint256 collateralTokenUnit; // The collateral token unit considering its decimals.
        uint256 borrowedReserveDecimals; // The number of decimals of the borrowed asset in the reserve.
        uint256 borrowedTokenUnit; // The unit of borrowed token considering its decimals.
    }

    struct LiquidityData {
        uint256 collateralValue; // The collateral value (in ETH).
        uint256 maxDebtValue; // The maximum debt value possible (in ETH).
        uint256 debtValue; // The debt value (in ETH).
    }

    /// STORAGE ///

    MaxGas public maxGas; // Max gas to consume within loops in matching engine functions.
    uint8 public NDS; // Max number of iterations in the data structure sorting process.
    uint8 public constant NO_REFERRAL_CODE = 0;
    uint8 public constant VARIABLE_INTEREST_MODE = 2;
    uint16 public constant MAX_BASIS_POINTS = 10_000; // 100% in basis points.
    uint16 public constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5_000; // 50% in basis points.
    mapping(address => DoubleLinkedList.List) internal suppliersInP2P; // For a given market, the suppliers in peer-to-peer.
    mapping(address => DoubleLinkedList.List) internal suppliersOnPool; // For a given market, the suppliers on Aave.
    mapping(address => DoubleLinkedList.List) internal borrowersInP2P; // For a given market, the borrowers in peer-to-peer.
    mapping(address => DoubleLinkedList.List) internal borrowersOnPool; // For a given market, the borrowers on Aave.
    mapping(address => mapping(address => SupplyBalance)) public supplyBalanceInOf; // For a given market, the supply balance of a user.
    mapping(address => mapping(address => BorrowBalance)) public borrowBalanceInOf; // For a given market, the borrow balance of a user.
    mapping(address => mapping(address => bool)) public userMembership; // Whether the user is in the market or not.
    mapping(address => address[]) public enteredMarkets; // The markets entered by a user.
    mapping(address => Types.Delta) public deltas; // Delta parameters for each market.
    mapping(address => bool) public paused; // Whether a market is paused or not.

    IAaveIncentivesController public aaveIncentivesController;
    ILendingPoolAddressesProvider public addressesProvider;
    ILendingPool public lendingPool;
    IMarketsManagerForAave public marketsManager;
    IMatchingEngineForAave public matchingEngine;
    IRewardsManagerForAave public rewardsManager;
    address public treasuryVault;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

/// @title Math library.
/// @dev Aave math modified and basic math library.
library Math {
    /// AAVE MATH ///

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (halfWAD + a * b) / WAD;
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return (halfB + a * WAD) / b;
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (halfRAY + a * b) / RAY;
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return (halfB + a * RAY) / b;
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return (halfRatio + a) / WAD_RAY_RATIO;
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a * WAD_RAY_RATIO;
    }

    function divWadByRay(uint256 a, uint256 b) internal pure returns (uint256) {
        return rayToWad(rayDiv(wadToRay(a), b));
    }

    function mulWadByRay(uint256 a, uint256 b) internal pure returns (uint256) {
        return rayToWad(rayMul(wadToRay(a), b));
    }

    /// GENERAL ///

    function min(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return a < b ? a < c ? a : c : b < c ? b : c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

library Types {
    struct Params {
        uint256 supplyP2PExchangeRate;
        uint256 borrowP2PExchangeRate;
        uint256 poolSupplyExchangeRate;
        uint256 poolBorrowExchangeRate;
        uint256 lastPoolSupplyExchangeRate;
        uint256 lastPoolBorrowExchangeRate;
        uint256 reserveFactor;
        Delta delta;
    }

    struct Delta {
        uint256 supplyP2PDelta; // Difference between the stored P2P supply amount and the real P2P supply amount (in scaled balance).
        uint256 borrowP2PDelta; // Difference between the stored P2P borrow amount and the real P2P borrow amount (in adUnit).
        uint256 supplyP2PAmount; // Sum of all stored P2P supply (in P2P unit).
        uint256 borrowP2PAmount; // Sum of all stored P2P borrow (in P2P unit).
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param onBehalfOf The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted when variable debt is burnt
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event Burn(address indexed user, uint256 amount, uint256 index);

    /**
     * @dev Burns user variable debt
     * @param user The user which debt is burnt
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

interface IAaveDistributionManager {
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
    event DistributionEndUpdated(uint256 newDistributionEnd);

    /**
     * @dev Sets the end date for the distribution
     * @param distributionEnd The end date timestamp
     **/
    function setDistributionEnd(uint256 distributionEnd) external;

    /**
     * @dev Gets the end date for the distribution
     * @return The end of the distribution
     **/
    function getDistributionEnd() external view returns (uint256);

    /**
     * @dev for backwards compatibility with the previous DistributionManager used
     * @return The end of the distribution
     **/
    function DISTRIBUTION_END() external view returns (uint256);

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IAaveIncentivesController is IAaveDistributionManager {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
        external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);

    struct AssetData {
        uint128 emissionPerSecond;
        uint128 lastUpdateTimestamp;
        uint256 index;
    }

    function assets(address) external view returns (AssetData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../../libraries/aave/DataTypes.sol";

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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface IMarketsManagerForAave {
    function isCreated(address _marketAddress) external returns (bool);

    function noP2P(address _marketAddress) external view returns (bool);

    function supplyP2PExchangeRate(address _marketAddress) external view returns (uint256);

    function borrowP2PExchangeRate(address _marketAddress) external view returns (uint256);

    function exchangeRatesLastUpdateTimestamp(address _marketAddress) external returns (uint256);

    function updateP2PExchangeRates(address _marketAddress) external;

    function getUpdatedP2PExchangeRates(address _marketAddress)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {IAToken} from "./aave/IAToken.sol";

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

interface IMatchingEngineForAave {
    function matchSuppliers(
        IAToken,
        ERC20,
        uint256,
        uint256
    ) external returns (uint256);

    function unmatchSuppliers(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function matchBorrowers(
        IAToken,
        ERC20,
        uint256,
        uint256
    ) external returns (uint256);

    function unmatchBorrowers(
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function updateBorrowers(address _poolTokenAddress, address _user) external;

    function updateSuppliers(address _poolTokenAddress, address _user) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./aave/IAaveIncentivesController.sol";

interface IRewardsManagerForAave {
    function aaveIncentivesController() external view returns (IAaveIncentivesController);

    function swapManager() external view returns (address);

    function setAaveIncentivesController(address) external;

    function setSwapManager(address) external;

    function getUserIndex(address, address) external returns (uint256);

    function accrueUserUnclaimedRewards(address[] calldata, address) external returns (uint256);

    function getUserUnclaimedRewards(address[] calldata, address) external view returns (uint256);

    function claimRewards(
        address[] calldata,
        uint256,
        address
    ) external returns (uint256);

    function updateUserAssetAndAccruedRewards(
        address,
        address,
        uint256,
        uint256
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface ISwapManager {
    function swapToMorphoToken(uint256 _amountIn, address _receiver)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

/// @title Double Linked List.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Modified double linked list with capped sorting insertion.
library DoubleLinkedList {
    /// STRUCTS ///

    struct Account {
        address prev;
        address next;
        uint256 value;
    }

    struct List {
        mapping(address => Account) accounts;
        address head;
        address tail;
    }

    /// ERRORS ///

    /// @notice Thrown when the account is already inserted in the double linked list.
    error AccountAlreadyInserted();

    /// @notice Thrown when the account to remove does not exist.
    error AccountDoesNotExist();

    /// @notice Thrown when the address is zero at insertion.
    error AddressIsZero();

    /// @notice Thrown when the value is zero at insertion.
    error ValueIsZero();

    /// INTERNAL ///

    /// @notice Returns the `account` linked to `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The value of the account.
    function getValueOf(List storage _list, address _id) internal view returns (uint256) {
        return _list.accounts[_id].value;
    }

    /// @notice Returns the address at the head of the `_list`.
    /// @param _list The list to get the head.
    /// @return The address of the head.
    function getHead(List storage _list) internal view returns (address) {
        return _list.head;
    }

    /// @notice Returns the address at the tail of the `_list`.
    /// @param _list The list to get the tail.
    /// @return The address of the tail.
    function getTail(List storage _list) internal view returns (address) {
        return _list.tail;
    }

    /// @notice Returns the next id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the next account.
    function getNext(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].next;
    }

    /// @notice Returns the previous id address from the current `_id`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @return The address of the previous account.
    function getPrev(List storage _list, address _id) internal view returns (address) {
        return _list.accounts[_id].prev;
    }

    /// @notice Removes an account of the `_list`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    function remove(List storage _list, address _id) internal {
        if (_list.accounts[_id].value == 0) revert AccountDoesNotExist();
        Account memory account = _list.accounts[_id];

        if (account.prev != address(0)) _list.accounts[account.prev].next = account.next;
        else _list.head = account.next;
        if (account.next != address(0)) _list.accounts[account.next].prev = account.prev;
        else _list.tail = account.prev;

        delete _list.accounts[_id];
    }

    /// @notice Inserts an account in the `_list` at the right slot based on its `_value`.
    /// @param _list The list to search in.
    /// @param _id The address of the account.
    /// @param _value The value of the account.
    /// @param _maxIterations The max number of iterations.
    function insertSorted(
        List storage _list,
        address _id,
        uint256 _value,
        uint256 _maxIterations
    ) internal {
        if (_value == 0) revert ValueIsZero();
        if (_id == address(0)) revert AddressIsZero();
        if (_list.accounts[_id].value != 0) revert AccountAlreadyInserted();

        uint256 numberOfIterations;
        address next = _list.head; // If not added at the end of the list `_id` will be inserted before `next`.

        while (
            numberOfIterations < _maxIterations &&
            next != _list.tail &&
            _list.accounts[next].value >= _value
        ) {
            next = _list.accounts[next].next;
            unchecked {
                ++numberOfIterations;
            }
        }

        // Account is not the new tail.
        if (next != address(0) && _list.accounts[next].value < _value) {
            // Account is the new head.
            if (next == _list.head) {
                _list.accounts[_id] = Account(address(0), next, _value);
                _list.head = _id;
                _list.accounts[next].prev = _id;
            }
            // Account is not the new head.
            else {
                _list.accounts[_id] = Account(_list.accounts[next].prev, next, _value);
                _list.accounts[_list.accounts[next].prev].next = _id;
                _list.accounts[next].prev = _id;
            }
        }
        // Account is the new tail.
        else {
            // Account is the new head.
            if (_list.head == address(0)) {
                _list.accounts[_id] = Account(address(0), address(0), _value);
                _list.head = _id;
                _list.tail = _id;
            }
            // Account is not the new head.
            else {
                _list.accounts[_id] = Account(_list.tail, address(0), _value);
                _list.accounts[_list.tail].next = _id;
                _list.tail = _id;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

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
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {IERC20} from "./IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

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
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

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
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {IAToken} from "./interfaces/aave/IAToken.sol";
import "./interfaces/aave/ILendingPool.sol";
import "./interfaces/IPositionsManagerForAave.sol";
import "./interfaces/IMarketsManagerForAave.sol";
import "./interfaces/IInterestRates.sol";

import {ReserveConfiguration} from "./libraries/aave/ReserveConfiguration.sol";
import "./libraries/Math.sol";
import "./libraries/Types.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title MarketsManagerForAave
/// @notice Smart contract managing the markets used by a MorphoPositionsManagerForAave contract, an other contract interacting with Aave or a fork of Aave.
contract MarketsManagerForAave is IMarketsManagerForAave, OwnableUpgradeable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using Math for uint256;

    /// STRUCTS ///

    struct LastPoolIndexes {
        uint256 lastSupplyPoolIndex; // Last supply pool index (normalized income) stored.
        uint256 lastBorrowPoolIndex; // Last borrow pool index (normalized variable debt) stored.
    }

    struct Vars {
        uint256 shareOfTheDelta;
        uint256 poolIncrease;
        Types.Delta delta;
    }

    /// STORAGE ///

    uint16 public constant MAX_BASIS_POINTS = 10_000; // 100% (in basis point).
    uint256 public constant SECONDS_PER_YEAR = 365 days; // The number of seconds in one year.
    address[] public marketsCreated; // Keeps track of the created markets.
    mapping(address => bool) public override isCreated; // Whether or not this market is created.
    mapping(address => uint256) public reserveFactor; // Proportion of the interest earned by users sent to the DAO for each market, in basis point (100% = 10000). The default value is 0.
    mapping(address => uint256) public override supplyP2PExchangeRate; // Current exchange rate from supply p2pUnit to underlying (in ray).
    mapping(address => uint256) public override borrowP2PExchangeRate; // Current exchange rate from borrow p2pUnit to underlying (in ray).
    mapping(address => uint256) public override exchangeRatesLastUpdateTimestamp; // The last time the P2P exchange rates were updated.
    mapping(address => LastPoolIndexes) public lastPoolIndexes; // Last pool index stored.
    mapping(address => bool) public override noP2P; // Whether to put users on pool or not for the given market.

    IPositionsManagerForAave public positionsManager;
    IInterestRates public interestRates;
    ILendingPool public lendingPool;

    /// EVENTS ///

    /// @notice Emitted when a new market is created.
    /// @param _marketAddress The address of the market that has been created.
    event MarketCreated(address indexed _marketAddress);

    /// @notice Emitted when the `positionsManager` is set.
    /// @param _positionsManager The address of the `positionsManager`.
    event PositionsManagerSet(address indexed _positionsManager);

    /// @notice Emitted when the `interestRates` is set.
    /// @param _interestRates The address of the `interestRates`.
    event InterestRatesSet(address _interestRates);

    /// @notice Emitted when a `noP2P` variable is set.
    /// @param _marketAddress The address of the market to set.
    /// @param _noP2P The new value of `_noP2P` adopted.
    event NoP2PSet(address indexed _marketAddress, bool _noP2P);

    /// @notice Emitted when the p2p exchange rates of a market are updated.
    /// @param _marketAddress The address of the market updated.
    /// @param _newSupplyP2PExchangeRate The new value of the supply exchange rate from p2pUnit to underlying.
    /// @param _newBorrowP2PExchangeRate The new value of the borrow exchange rate from p2pUnit to underlying.
    event P2PExchangeRatesUpdated(
        address indexed _marketAddress,
        uint256 _newSupplyP2PExchangeRate,
        uint256 _newBorrowP2PExchangeRate
    );

    /// @notice Emitted when the `reserveFactor` is set.
    /// @param _marketAddress The address of the market set.
    /// @param _newValue The new value of the `reserveFactor`.
    event ReserveFactorSet(address indexed _marketAddress, uint256 _newValue);

    /// ERRORS ///

    /// @notice Thrown when the market is not created yet.
    error MarketNotCreated();

    /// @notice Thrown when the market is not listed on Aave.
    error MarketIsNotListedOnAave();

    /// @notice Thrown when the market is already created.
    error MarketAlreadyCreated();

    /// @notice Thrown when the positionsManager is already set.
    error PositionsManagerAlreadySet();

    /// @notice Thrown when only the positions manager can call the function.
    error OnlyPositionsManager();

    /// MODIFIERS ///

    /// @notice Prevents to update a market not created yet.
    /// @param _marketAddress The address of the market to check.
    modifier isMarketCreated(address _marketAddress) {
        if (!isCreated[_marketAddress]) revert MarketNotCreated();
        _;
    }

    /// @notice Prevents a user to call function only allowed for `positionsManager` owner.
    modifier onlyPositionsManager() {
        if (msg.sender != address(positionsManager)) revert OnlyPositionsManager();
        _;
    }

    /// UPGRADE ///

    /// @notice Initializes the MarketsManagerForAave contract.
    /// @param _lendingPool The `lendingPool`.
    /// @param _interestRates The `interestRates`.
    function initialize(ILendingPool _lendingPool, IInterestRates _interestRates)
        external
        initializer
    {
        __Ownable_init();

        lendingPool = _lendingPool;
        interestRates = _interestRates;
    }

    /// EXTERNAL ///

    /// @notice Sets the `positionsManager` to interact with Aave.
    /// @param _positionsManager The address of the `positionsManager`.
    function setPositionsManager(address _positionsManager) external onlyOwner {
        if (address(positionsManager) != address(0)) revert PositionsManagerAlreadySet();
        positionsManager = IPositionsManagerForAave(_positionsManager);
        emit PositionsManagerSet(_positionsManager);
    }

    /// @notice Sets the `intersRates`.
    /// @param _interestRates The new `interestRates` contract.
    function setInterestRates(IInterestRates _interestRates) external onlyOwner {
        interestRates = _interestRates;
        emit InterestRatesSet(address(_interestRates));
    }

    /// @notice Sets the `reserveFactor`.
    /// @param _marketAddress The market on which to set the `_newReserveFactor`.
    /// @param _newReserveFactor The proportion of the interest earned by users sent to the DAO, (in basis point).
    function setReserveFactor(address _marketAddress, uint256 _newReserveFactor)
        external
        onlyOwner
    {
        reserveFactor[_marketAddress] = Math.min(MAX_BASIS_POINTS, _newReserveFactor);
        updateP2PExchangeRates(_marketAddress);
        emit ReserveFactorSet(_marketAddress, reserveFactor[_marketAddress]);
    }

    /// @notice Creates a new market to borrow/supply in.
    /// @param _underlyingTokenAddress The underlying address of the given market.
    function createMarket(address _underlyingTokenAddress) external onlyOwner {
        DataTypes.ReserveConfigurationMap memory configuration = lendingPool.getConfiguration(
            _underlyingTokenAddress
        );
        (bool isActive, , , ) = configuration.getFlagsMemory();
        if (!isActive) revert MarketIsNotListedOnAave();

        address poolTokenAddress = lendingPool
        .getReserveData(_underlyingTokenAddress)
        .aTokenAddress;

        if (isCreated[poolTokenAddress]) revert MarketAlreadyCreated();
        isCreated[poolTokenAddress] = true;

        exchangeRatesLastUpdateTimestamp[poolTokenAddress] = block.timestamp;
        supplyP2PExchangeRate[poolTokenAddress] = Math.ray();
        borrowP2PExchangeRate[poolTokenAddress] = Math.ray();

        LastPoolIndexes storage poolIndexes = lastPoolIndexes[poolTokenAddress];
        poolIndexes.lastSupplyPoolIndex = lendingPool.getReserveNormalizedIncome(
            _underlyingTokenAddress
        );
        poolIndexes.lastBorrowPoolIndex = lendingPool.getReserveNormalizedVariableDebt(
            _underlyingTokenAddress
        );

        marketsCreated.push(poolTokenAddress);
        emit MarketCreated(poolTokenAddress);
    }

    /// @notice Sets whether to match people P2P or not.
    /// @param _marketAddress The address of the market.
    /// @param _noP2P Whether to match people P2P or not.
    function setNoP2P(address _marketAddress, bool _noP2P)
        external
        onlyOwner
        isMarketCreated(_marketAddress)
    {
        noP2P[_marketAddress] = _noP2P;
        emit NoP2PSet(_marketAddress, _noP2P);
    }

    /// @notice Returns all created markets.
    /// @return marketsCreated_ The list of market adresses.
    function getAllMarkets() external view returns (address[] memory marketsCreated_) {
        marketsCreated_ = marketsCreated;
    }

    /// @notice Returns market's data.
    /// @return supplyP2PExchangeRate_ The supply P2P exchange rate of the market.
    /// @return borrowP2PExchangeRate_ The borrow P2P exchange rate of the market.
    /// @return exchangeRatesLastUpdateTimestamp_ The last timestamp when P2P exchange rates where updated.
    /// @return supplyP2PDelta_ The supply P2P delta (in scaled balance).
    /// @return borrowP2PDelta_ The borrow P2P delta (in adUnit).
    /// @return supplyP2PAmount_ The supply P2P amount (in P2P unit).
    /// @return borrowP2PAmount_ The borrow P2P amount (in P2P unit).
    function getMarketData(address _marketAddress)
        external
        view
        returns (
            uint256 supplyP2PExchangeRate_,
            uint256 borrowP2PExchangeRate_,
            uint256 exchangeRatesLastUpdateTimestamp_,
            uint256 supplyP2PDelta_,
            uint256 borrowP2PDelta_,
            uint256 supplyP2PAmount_,
            uint256 borrowP2PAmount_
        )
    {
        {
            Types.Delta memory delta = positionsManager.deltas(_marketAddress);
            supplyP2PDelta_ = delta.supplyP2PDelta;
            borrowP2PDelta_ = delta.borrowP2PDelta;
            supplyP2PAmount_ = delta.supplyP2PAmount;
            borrowP2PAmount_ = delta.borrowP2PAmount;
        }

        supplyP2PExchangeRate_ = supplyP2PExchangeRate[_marketAddress];
        borrowP2PExchangeRate_ = borrowP2PExchangeRate[_marketAddress];
        exchangeRatesLastUpdateTimestamp_ = exchangeRatesLastUpdateTimestamp[_marketAddress];
    }

    /// @notice Returns market's configuration.
    /// @return isCreated_ Whether the market is created or not.
    /// @return noP2P_ Whether user are put in P2P or not.
    function getMarketConfiguration(address _marketAddress)
        external
        view
        returns (bool isCreated_, bool noP2P_)
    {
        isCreated_ = isCreated[_marketAddress];
        noP2P_ = noP2P[_marketAddress];
    }

    /// PUBLIC ///

    /// @notice Returns the updated P2P exchange rates.
    /// @param _marketAddress The address of the market to update.
    /// @return newSupplyP2PExchangeRate The supply P2P exchange rate after udpate.
    /// @return newBorrowP2PExchangeRate The supply P2P exchange rate after udpate.
    function getUpdatedP2PExchangeRates(address _marketAddress)
        external
        view
        override
        returns (uint256 newSupplyP2PExchangeRate, uint256 newBorrowP2PExchangeRate)
    {
        if (block.timestamp == exchangeRatesLastUpdateTimestamp[_marketAddress]) {
            newSupplyP2PExchangeRate = supplyP2PExchangeRate[_marketAddress];
            newBorrowP2PExchangeRate = borrowP2PExchangeRate[_marketAddress];
        } else {
            address underlyingTokenAddress = IAToken(_marketAddress).UNDERLYING_ASSET_ADDRESS();
            LastPoolIndexes storage poolIndexes = lastPoolIndexes[_marketAddress];

            uint256 poolSupplyExchangeRate = lendingPool.getReserveNormalizedIncome(
                underlyingTokenAddress
            );
            uint256 poolBorrowExchangeRate = lendingPool.getReserveNormalizedVariableDebt(
                underlyingTokenAddress
            );

            Types.Params memory params = Types.Params(
                supplyP2PExchangeRate[_marketAddress],
                borrowP2PExchangeRate[_marketAddress],
                poolSupplyExchangeRate,
                poolBorrowExchangeRate,
                poolIndexes.lastSupplyPoolIndex,
                poolIndexes.lastBorrowPoolIndex,
                reserveFactor[_marketAddress],
                positionsManager.deltas(_marketAddress)
            );

            (newSupplyP2PExchangeRate, newBorrowP2PExchangeRate) = interestRates
            .computeP2PExchangeRates(params);
        }
    }

    /// @notice Updates the P2P exchange rates, taking into account the Second Percentage Yield values.
    /// @param _marketAddress The address of the market to update.
    function updateP2PExchangeRates(address _marketAddress) public {
        uint256 timeDifference = block.timestamp - exchangeRatesLastUpdateTimestamp[_marketAddress];

        if (timeDifference > 0) {
            address underlyingTokenAddress = IAToken(_marketAddress).UNDERLYING_ASSET_ADDRESS();
            exchangeRatesLastUpdateTimestamp[_marketAddress] = block.timestamp;
            LastPoolIndexes storage poolIndexes = lastPoolIndexes[_marketAddress];

            uint256 poolSupplyExchangeRate = lendingPool.getReserveNormalizedIncome(
                underlyingTokenAddress
            );
            uint256 poolBorrowExchangeRate = lendingPool.getReserveNormalizedVariableDebt(
                underlyingTokenAddress
            );

            Types.Params memory params = Types.Params(
                supplyP2PExchangeRate[_marketAddress],
                borrowP2PExchangeRate[_marketAddress],
                poolSupplyExchangeRate,
                poolBorrowExchangeRate,
                poolIndexes.lastSupplyPoolIndex,
                poolIndexes.lastBorrowPoolIndex,
                reserveFactor[_marketAddress],
                positionsManager.deltas(_marketAddress)
            );

            (uint256 newSupplyP2PExchangeRate, uint256 newBorrowP2PExchangeRate) = interestRates
            .computeP2PExchangeRates(params);

            supplyP2PExchangeRate[_marketAddress] = newSupplyP2PExchangeRate;
            borrowP2PExchangeRate[_marketAddress] = newBorrowP2PExchangeRate;
            poolIndexes.lastSupplyPoolIndex = poolSupplyExchangeRate;
            poolIndexes.lastBorrowPoolIndex = poolBorrowExchangeRate;

            emit P2PExchangeRatesUpdated(
                _marketAddress,
                newSupplyP2PExchangeRate,
                newBorrowP2PExchangeRate
            );
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "../libraries/Types.sol";

interface IPositionsManagerForAave {
    struct Balance {
        uint256 inP2P;
        uint256 onPool;
    }

    function createMarket(address) external returns (uint256[] memory);

    function getUserMaxCapacitiesForAsset(address _user, address _poolTokenAddress)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable);

    function setNMAX(uint16) external;

    function setTreasuryVault(address) external;

    function setRewardsManager(address _rewardsManagerAddress) external;

    function borrowBalanceInOf(address, address) external view returns (Balance memory);

    function supplyBalanceInOf(address, address) external view returns (Balance memory);

    function deltas(address) external view returns (Types.Delta memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

    uint256 constant MAX_VALID_LTV = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 constant MAX_VALID_DECIMALS = 255;
    uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

    /**
     * @dev Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv the new ltv
     **/
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
        require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @dev Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @dev Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 threshold
    ) internal pure {
        require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

        self.data =
            (self.data & LIQUIDATION_THRESHOLD_MASK) |
            (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @dev Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     **/
    function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
        internal
        pure
    {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

        self.data =
            (self.data & LIQUIDATION_BONUS_MASK) |
            (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     **/
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @dev Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     **/
    function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
        internal
        pure
    {
        require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

        self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @dev Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     **/
    function getDecimals(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @dev Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @dev Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @dev Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
        internal
        pure
    {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @dev Enables or disables stable rate borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
     **/
    function setStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & STABLE_BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the stable rate borrowing state of the reserve
     * @param self The reserve configuration
     * @return The stable rate borrowing state
     **/
    function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~STABLE_BORROWING_MASK) != 0;
    }

    /**
     * @dev Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
        internal
        pure
    {
        require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

        self.data =
            (self.data & RESERVE_FACTOR_MASK) |
            (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @dev Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @dev Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlags(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (
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
            (dataLocal & ~STABLE_BORROWING_MASK) != 0
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve
     * @param self The reserve configuration
     * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
     **/
    function getParams(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (
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
            (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
     **/
    function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            self.data & ~LTV_MASK,
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration flags of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        return (
            (self.data & ~ACTIVE_MASK) != 0,
            (self.data & ~FROZEN_MASK) != 0,
            (self.data & ~BORROWING_MASK) != 0,
            (self.data & ~STABLE_BORROWING_MASK) != 0
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
    //common errors
    string public constant CALLER_NOT_POOL_ADMIN = "33"; // 'The caller must be the pool admin'
    string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

    //contract specific errors
    string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
    string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
    string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
    string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "10"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
    string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
    string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
    string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
    string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
    string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
    string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
    string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
    string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
    string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
    string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
    string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
    string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
    string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
    string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
    string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
    string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "38"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "39"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
    string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
    string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
    string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
    string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
    string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
    string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
    string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
    string public constant MATH_ADDITION_OVERFLOW = "49";
    string public constant MATH_DIVISION_BY_ZERO = "50";
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
    string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
    string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
    string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
    string public constant LP_FAILED_COLLATERAL_SWAP = "60";
    string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
    string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
    string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
    string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
    string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
    string public constant RC_INVALID_LTV = "67";
    string public constant RC_INVALID_LIQ_THRESHOLD = "68";
    string public constant RC_INVALID_LIQ_BONUS = "69";
    string public constant RC_INVALID_DECIMALS = "70";
    string public constant RC_INVALID_RESERVE_FACTOR = "71";
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
    string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
    string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
    string public constant UL_INVALID_INDEX = "77";
    string public constant LP_NOT_CONTRACT = "78";
    string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
    string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

    enum CollateralManagerErrors {
        NO_ERROR,
        NO_COLLATERAL_AVAILABLE,
        COLLATERAL_CANNOT_BE_LIQUIDATED,
        CURRRENCY_NOT_BORROWED,
        HEALTH_FACTOR_ABOVE_THRESHOLD,
        NOT_ENOUGH_LIQUIDITY,
        NO_ACTIVE_RESERVE,
        HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
        INVALID_EQUAL_ASSETS_TO_SWAP,
        FROZEN_RESERVE
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/compound/ICompound.sol";
import "./interfaces/IPositionsManager.sol";
import "./interfaces/IIncentivesVault.sol";
import "./interfaces/IRewardsManager.sol";
import "./interfaces/IInterestRatesManager.sol";

import "../common/libraries/DoubleLinkedList.sol";
import "./libraries/Types.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title MorphoStorage.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice All storage variables used in Morpho contracts.
abstract contract MorphoStorage is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// GLOBAL STORAGE ///

    uint8 public constant CTOKEN_DECIMALS = 8; // The number of decimals for cToken.
    uint16 public constant MAX_BASIS_POINTS = 10_000; // 100% in basis points.
    uint16 public constant MAX_CLAIMABLE_RESERVE = 9_000; // The max proportion of reserve fee claimable by the DAO at once (90% in basis points).
    uint256 public constant WAD = 1e18;

    uint256 public maxSortedUsers; // The max number of users to sort in the data structure.
    uint256 public dustThreshold; // The minimum amount to keep in the data structure.
    Types.MaxGasForMatching public defaultMaxGasForMatching; // The default max gas to consume within loops in matching engine functions.

    /// POSITIONS STORAGE ///

    mapping(address => DoubleLinkedList.List) internal suppliersInP2P; // For a given market, the suppliers in peer-to-peer.
    mapping(address => DoubleLinkedList.List) internal suppliersOnPool; // For a given market, the suppliers on Compound.
    mapping(address => DoubleLinkedList.List) internal borrowersInP2P; // For a given market, the borrowers in peer-to-peer.
    mapping(address => DoubleLinkedList.List) internal borrowersOnPool; // For a given market, the borrowers on Compound.
    mapping(address => mapping(address => Types.SupplyBalance)) public supplyBalanceInOf; // For a given market, the supply balance of a user. cToken -> user -> balances.
    mapping(address => mapping(address => Types.BorrowBalance)) public borrowBalanceInOf; // For a given market, the borrow balance of a user. cToken -> user -> balances.
    mapping(address => mapping(address => bool)) public userMembership; // Whether the user is in the market or not. cToken -> user -> bool.
    mapping(address => address[]) public enteredMarkets; // The markets entered by a user. user -> cTokens.

    /// MARKETS STORAGE ///

    address[] public marketsCreated; // Keeps track of the created markets.
    mapping(address => bool) public p2pDisabled; // Whether the peer-to-peer market is open or not.
    mapping(address => uint256) public p2pSupplyIndex; // Current index from supply peer-to-peer unit to underlying (in wad).
    mapping(address => uint256) public p2pBorrowIndex; // Current index from borrow peer-to-peer unit to underlying (in wad).
    mapping(address => Types.LastPoolIndexes) public lastPoolIndexes; // Last pool index stored.
    mapping(address => Types.MarketParameters) public marketParameters; // Market parameters.
    mapping(address => Types.MarketStatus) public marketStatus; // Market status.
    mapping(address => Types.Delta) public deltas; // Delta parameters for each market.

    /// CONTRACTS AND ADDRESSES ///

    IPositionsManager public positionsManager;
    IIncentivesVault public incentivesVault;
    IRewardsManager public rewardsManager;
    IInterestRatesManager public interestRatesManager;
    IComptroller public comptroller;
    address public treasuryVault;
    address public cEth;
    address public wEth;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @dev The contract is automatically marked as initialized when deployed so that nobody can highjack the implementation contract.
    constructor() initializer {}
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface ICEth {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface IComptroller {
    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    function liquidationIncentiveMantissa() external returns (uint256);

    function closeFactorMantissa() external returns (uint256);

    function admin() external view returns (address);

    function oracle() external view returns (address);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address,
        address,
        uint256,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function checkMembership(address, address) external view returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function compSupplyState(address) external view returns (CompMarketState memory);

    function compBorrowState(address) external view returns (CompMarketState memory);

    function getCompAddress() external view returns (address);

    function _setPriceOracle(address newOracle) external returns (uint256);
}

interface IInterestRateModel {
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICToken {
    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function interestRateModel() external view returns (IInterestRateModel);

    function reserveFactorMantissa() external view returns (uint256);

    function initialExchangeRateMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICEther is ICToken {
    function mint() external payable;

    function repayBorrow() external payable;
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface IPositionsManager {
    function supplyLogic(
        address _poolTokenAddress,
        address _supplier,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function borrowLogic(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function withdrawLogic(
        address _poolTokenAddress,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasForMatching
    ) external;

    function repayLogic(
        address _poolTokenAddress,
        address _repayer,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function liquidateLogic(
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./IOracle.sol";

interface IIncentivesVault {
    function setOracle(IOracle _newOracle) external;

    function setMorphoDao(address _newMorphoDao) external;

    function setBonus(uint256 _newBonus) external;

    function setPauseStatus(bool _newStatus) external;

    function transferMorphoTokensToDao(uint256 _amount) external;

    function tradeCompForMorphoTokens(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./compound/ICompound.sol";

interface IRewardsManager {
    function claimRewards(address[] calldata, address) external returns (uint256);

    function accrueUserUnclaimedRewards(address[] calldata _cTokenAddresses, address)
        external
        returns (uint256);

    function userUnclaimedCompRewards(address) external view returns (uint256);

    function getUserUnclaimedRewards(address[] calldata _cTokenAddresses, address _user)
        external
        returns (uint256 unclaimedRewards);

    function compSupplierIndex(address, address) external view returns (uint256);

    function compBorrowerIndex(address, address) external view returns (uint256);

    function getLocalCompSupplyState(address)
        external
        view
        returns (IComptroller.CompMarketState memory);

    function getLocalCompBorrowState(address)
        external
        view
        returns (IComptroller.CompMarketState memory);

    function getUpdatedSupplyIndex(address) external view returns (uint256);

    function getUpdatedBorrowIndex(address) external view returns (uint256);

    function accrueUserSupplyUnclaimedRewards(
        address,
        address,
        uint256
    ) external;

    function accrueUserBorrowUnclaimedRewards(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface IInterestRatesManager {
    function updateP2PIndexes(address _marketAddress) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

/// @title Types.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Common types and structs used in Moprho contracts.
library Types {
    /// ENUMS ///

    enum PositionType {
        SUPPLIERS_IN_P2P,
        SUPPLIERS_ON_POOL,
        BORROWERS_IN_P2P,
        BORROWERS_ON_POOL
    }

    /// STRUCTS ///

    struct SupplyBalance {
        uint256 inP2P; // In supplier's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In cToken. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In borrower's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In cdUnit, a unit that grows in value, to keep track of the debt increase when borrowers are on Compound. Multiply by the pool borrow index to get the underlying amount.
    }

    // Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
    struct MaxGasForMatching {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct Delta {
        uint256 p2pSupplyDelta; // Difference between the stored peer-to-peer supply amount and the real peer-to-peer supply amount (in cToken).
        uint256 p2pBorrowDelta; // Difference between the stored peer-to-peer borrow amount and the real peer-to-peer borrow amount (in cdUnit).
        uint256 p2pSupplyAmount; // Sum of all stored peer-to-peer supply (in peer-to-peer unit).
        uint256 p2pBorrowAmount; // Sum of all stored peer-to-peer borrow (in peer-to-peer unit).
    }

    struct AssetLiquidityData {
        uint256 collateralValue; // The collateral value of the asset.
        uint256 maxDebtValue; // The maximum possible debt value of the asset.
        uint256 debtValue; // The debt value of the asset.
        uint256 underlyingPrice; // The price of the token.
        uint256 collateralFactor; // The liquidation threshold applied on this token.
    }

    struct LiquidityData {
        uint256 collateralValue; // The collateral value.
        uint256 maxDebtValue; // The maximum debt value possible.
        uint256 debtValue; // The debt value.
    }

    // Variables are packed together to save gas (will not exceed their limit during Morpho's lifetime).
    struct LastPoolIndexes {
        uint32 lastUpdateBlockNumber; // The last time the peer-to-peer indexes were updated.
        uint112 lastSupplyPoolIndex; // Last pool supply index.
        uint112 lastBorrowPoolIndex; // Last pool borrow index.
    }

    struct MarketParameters {
        uint16 reserveFactor; // Proportion of the interest earned by users sent to the DAO for each market, in basis point (100% = 10 000). The value is set at market creation.
        uint16 p2pIndexCursor; // Position of the peer-to-peer rate in the pool's spread. Determine the weights of the weighted arithmetic average in the indexes computations ((1 - p2pIndexCursor) * r^S + p2pIndexCursor * r^B) (in basis point).
    }

    struct MarketStatus {
        bool isCreated; // Whether or not this market is created.
        bool isPaused; // Whether the market is paused or not (all entry points on Morpho are frozen; supply, borrow, withdraw, repay and liquidate).
        bool isPartiallyPaused; // Whether the market is partially paused or not (only supply and borrow are frozen).
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface IOracle {
    function consult(uint256 _amountIn) external returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./libraries/CompoundMath.sol";
import "../common/libraries/DelegateCall.sol";

import "./MorphoStorage.sol";

/// @title MorphoUtils.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Modifiers, getters and other util functions for Morpho.
abstract contract MorphoUtils is MorphoStorage {
    using DoubleLinkedList for DoubleLinkedList.List;
    using CompoundMath for uint256;
    using DelegateCall for address;

    /// ERRORS ///

    /// @notice Thrown when the Compound's oracle failed.
    error CompoundOracleFailed();

    /// @notice Thrown when the market is not created yet.
    error MarketNotCreated();

    /// @notice Thrown when the market is paused.
    error MarketPaused();

    /// MODIFIERS ///

    /// @notice Prevents to update a market not created yet.
    /// @param _poolTokenAddress The address of the market to check.
    modifier isMarketCreated(address _poolTokenAddress) {
        if (!marketStatus[_poolTokenAddress].isCreated) revert MarketNotCreated();
        _;
    }

    /// @notice Prevents a user to trigger a function when market is not created or paused.
    /// @param _poolTokenAddress The address of the market to check.
    modifier isMarketCreatedAndNotPaused(address _poolTokenAddress) {
        Types.MarketStatus memory marketStatus_ = marketStatus[_poolTokenAddress];
        if (!marketStatus_.isCreated) revert MarketNotCreated();
        if (marketStatus_.isPaused) revert MarketPaused();
        _;
    }

    /// @notice Prevents a user to trigger a function when market is not created or paused or partial paused.
    /// @param _poolTokenAddress The address of the market to check.
    modifier isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolTokenAddress) {
        Types.MarketStatus memory marketStatus_ = marketStatus[_poolTokenAddress];
        if (!marketStatus_.isCreated) revert MarketNotCreated();
        if (marketStatus_.isPaused || marketStatus_.isPartiallyPaused) revert MarketPaused();
        _;
    }

    /// EXTERNAL ///

    /// @notice Returns all markets entered by a given user.
    /// @param _user The address of the user.
    /// @return enteredMarkets_ The list of markets entered by this user.
    function getEnteredMarkets(address _user)
        external
        view
        returns (address[] memory enteredMarkets_)
    {
        return enteredMarkets[_user];
    }

    /// @notice Returns all created markets.
    /// @return marketsCreated_ The list of market addresses.
    function getAllMarkets() external view returns (address[] memory marketsCreated_) {
        return marketsCreated;
    }

    /// @notice Gets the head of the data structure on a specific market (for UI).
    /// @param _poolTokenAddress The address of the market from which to get the head.
    /// @param _positionType The type of user from which to get the head.
    /// @return head The head in the data structure.
    function getHead(address _poolTokenAddress, Types.PositionType _positionType)
        external
        view
        returns (address head)
    {
        if (_positionType == Types.PositionType.SUPPLIERS_IN_P2P)
            head = suppliersInP2P[_poolTokenAddress].getHead();
        else if (_positionType == Types.PositionType.SUPPLIERS_ON_POOL)
            head = suppliersOnPool[_poolTokenAddress].getHead();
        else if (_positionType == Types.PositionType.BORROWERS_IN_P2P)
            head = borrowersInP2P[_poolTokenAddress].getHead();
        else if (_positionType == Types.PositionType.BORROWERS_ON_POOL)
            head = borrowersOnPool[_poolTokenAddress].getHead();
    }

    /// @notice Gets the next user after `_user` in the data structure on a specific market (for UI).
    /// @param _poolTokenAddress The address of the market from which to get the user.
    /// @param _positionType The type of user from which to get the next user.
    /// @param _user The address of the user from which to get the next user.
    /// @return next The next user in the data structure.
    function getNext(
        address _poolTokenAddress,
        Types.PositionType _positionType,
        address _user
    ) external view returns (address next) {
        if (_positionType == Types.PositionType.SUPPLIERS_IN_P2P)
            next = suppliersInP2P[_poolTokenAddress].getNext(_user);
        else if (_positionType == Types.PositionType.SUPPLIERS_ON_POOL)
            next = suppliersOnPool[_poolTokenAddress].getNext(_user);
        else if (_positionType == Types.PositionType.BORROWERS_IN_P2P)
            next = borrowersInP2P[_poolTokenAddress].getNext(_user);
        else if (_positionType == Types.PositionType.BORROWERS_ON_POOL)
            next = borrowersOnPool[_poolTokenAddress].getNext(_user);
    }

    /// @notice Updates the peer-to-peer indexes.
    /// @dev Note: This function updates the exchange rate on Compound. As a consequence only a call to exchangeRatesStored() is necessary to get the most up to date exchange rate.
    /// @param _poolTokenAddress The address of the market to update.
    function updateP2PIndexes(address _poolTokenAddress)
        external
        isMarketCreated(_poolTokenAddress)
    {
        _updateP2PIndexes(_poolTokenAddress);
    }

    /// INTERNAL ///

    /// @dev Updates the peer-to-peer indexes.
    /// @dev Note: This function updates the exchange rate on Compound. As a consequence only a call to exchangeRatesStored() is necessary to get the most up to date exchange rate.
    /// @param _poolTokenAddress The address of the market to update.
    function _updateP2PIndexes(address _poolTokenAddress) internal {
        address(interestRatesManager).functionDelegateCall(
            abi.encodeWithSelector(
                interestRatesManager.updateP2PIndexes.selector,
                _poolTokenAddress
            )
        );
    }

    /// @dev Checks whether the user has enough collateral to maintain such a borrow position.
    /// @param _user The user to check.
    /// @param _poolTokenAddress The market to hypothetically withdraw/borrow in.
    /// @param _withdrawnAmount The amount of tokens to hypothetically withdraw (in underlying).
    /// @param _borrowedAmount The amount of tokens to hypothetically borrow (in underlying).
    function _isLiquidatable(
        address _user,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) internal view returns (bool) {
        ICompoundOracle oracle = ICompoundOracle(comptroller.oracle());
        uint256 numberOfEnteredMarkets = enteredMarkets[_user].length;

        Types.AssetLiquidityData memory assetData;
        uint256 maxDebtValue;
        uint256 debtValue;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[_user][i];

            assetData = _getUserLiquidityDataForAsset(_user, poolTokenEntered, oracle);
            maxDebtValue += assetData.maxDebtValue;
            debtValue += assetData.debtValue;

            if (_poolTokenAddress == poolTokenEntered) {
                if (_borrowedAmount > 0)
                    debtValue += _borrowedAmount.mul(assetData.underlyingPrice);

                if (_withdrawnAmount > 0)
                    maxDebtValue -= _withdrawnAmount.mul(assetData.underlyingPrice).mul(
                        assetData.collateralFactor
                    );
            }

            unchecked {
                ++i;
            }
        }

        return debtValue > maxDebtValue;
    }

    /// @notice Returns the data related to `_poolTokenAddress` for the `_user`.
    /// @dev Note: Must be called after calling `_updateP2PIndexes()` to have the most up-to-date indexes.
    /// @param _user The user to determine data for.
    /// @param _poolTokenAddress The address of the market.
    /// @param _oracle The oracle used.
    /// @return assetData The data related to this asset.
    function _getUserLiquidityDataForAsset(
        address _user,
        address _poolTokenAddress,
        ICompoundOracle _oracle
    ) internal view returns (Types.AssetLiquidityData memory assetData) {
        assetData.underlyingPrice = _oracle.getUnderlyingPrice(_poolTokenAddress);
        if (assetData.underlyingPrice == 0) revert CompoundOracleFailed();
        (, assetData.collateralFactor, ) = comptroller.markets(_poolTokenAddress);

        assetData.collateralValue = _getUserSupplyBalanceInOf(_poolTokenAddress, _user).mul(
            assetData.underlyingPrice
        );
        assetData.debtValue = _getUserBorrowBalanceInOf(_poolTokenAddress, _user).mul(
            assetData.underlyingPrice
        );
        assetData.maxDebtValue = assetData.collateralValue.mul(assetData.collateralFactor);
    }

    /// @dev Returns the supply balance of `_user` in the `_poolTokenAddress` market.
    /// @dev Note: Compute the result with the index stored and not the most up to date one.
    /// @param _user The address of the user.
    /// @param _poolTokenAddress The market where to get the supply amount.
    /// @return The supply balance of the user (in underlying).
    function _getUserSupplyBalanceInOf(address _poolTokenAddress, address _user)
        internal
        view
        returns (uint256)
    {
        return
            supplyBalanceInOf[_poolTokenAddress][_user].inP2P.mul(
                p2pSupplyIndex[_poolTokenAddress]
            ) +
            supplyBalanceInOf[_poolTokenAddress][_user].onPool.mul(
                ICToken(_poolTokenAddress).exchangeRateStored()
            );
    }

    /// @dev Returns the borrow balance of `_user` in the `_poolTokenAddress` market.
    /// @param _user The address of the user.
    /// @param _poolTokenAddress The market where to get the borrow amount.
    /// @return The borrow balance of the user (in underlying).
    function _getUserBorrowBalanceInOf(address _poolTokenAddress, address _user)
        internal
        view
        returns (uint256)
    {
        return
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P.mul(
                p2pBorrowIndex[_poolTokenAddress]
            ) +
            borrowBalanceInOf[_poolTokenAddress][_user].onPool.mul(
                ICToken(_poolTokenAddress).borrowIndex()
            );
    }

    /// @dev Returns the underlying ERC20 token related to the pool token.
    /// @param _poolTokenAddress The address of the pool token.
    /// @return The underlying ERC20 token.
    function _getUnderlying(address _poolTokenAddress) internal view returns (ERC20) {
        if (_poolTokenAddress == cEth)
            // cETH has no underlying() function.
            return ERC20(wEth);
        else return ERC20(ICToken(_poolTokenAddress).underlying());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

/// @title CompoundMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Library emulating in solidity 8+ the behavior of Compound's mulScalarTruncate and divScalarByExpTruncate functions.
library CompoundMath {
    /// ERRORS ///

    /// @notice Reverts when the number exceeds 224 bits.
    error NumberExceeds224Bits();

    /// @notice Reverts when the number exceeds 32 bits.
    error NumberExceeds32Bits();

    /// INTERNAL ///

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / 1e18;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((1e18 * x * 1e18) / y) / 1e18;
    }

    function safe224(uint256 n) internal pure returns (uint224) {
        if (n >= 2**224) revert NumberExceeds224Bits();
        return uint224(n);
    }

    function safe32(uint256 n) internal pure returns (uint32) {
        if (n >= 2**32) revert NumberExceeds32Bits();
        return uint32(n);
    }

    function min(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return a < b ? a < c ? a : c : b < c ? b : c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : 0;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

/// @title Delegate Call Library.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Library to perform delegate calls inspired by the OZ Address library: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol.
library DelegateCall {
    /// ERRORS ///

    /// @notice Thrown when a low delegate call has failed without error message.
    error LowLevelDelegateCallFailed();

    /// INTERNAL ///

    /// @dev Performs a low-level delegate call to the `_target` contract.
    /// @dev Note: Unlike the OZ's library this function does not check if the `_target` is a contract. It is the responsibility of the caller to ensure that the `_target` is a contract.
    /// @param _target The address of the target contract.
    /// @param _data The data to pass to the function called on the target contract.
    /// @return The return data from the function called on the target contract.
    function functionDelegateCall(address _target, bytes memory _data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = _target.delegatecall(_data);
        if (success) return returndata;
        else {
            // Look for revert reason and bubble it up if present.
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly.

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else revert LowLevelDelegateCallFailed();
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./MorphoUtils.sol";

/// @title MorphoGovernance.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Governance functions for Morpho.
abstract contract MorphoGovernance is MorphoUtils {
    using SafeTransferLib for ERC20;

    /// EVENTS ///

    /// @notice Emitted when a new `defaultMaxGasForMatching` is set.
    /// @param _defaultMaxGasForMatching The new `defaultMaxGasForMatching`.
    event DefaultMaxGasForMatchingSet(Types.MaxGasForMatching _defaultMaxGasForMatching);

    /// @notice Emitted when a new value for `maxSortedUsers` is set.
    /// @param _newValue The new value of `maxSortedUsers`.
    event MaxSortedUsersSet(uint256 _newValue);

    /// @notice Emitted the address of the `treasuryVault` is set.
    /// @param _newTreasuryVaultAddress The new address of the `treasuryVault`.
    event TreasuryVaultSet(address indexed _newTreasuryVaultAddress);

    /// @notice Emitted the address of the `incentivesVault` is set.
    /// @param _newIncentivesVaultAddress The new address of the `incentivesVault`.
    event IncentivesVaultSet(address indexed _newIncentivesVaultAddress);

    /// @notice Emitted when the `positionsManager` is set.
    /// @param _positionsManager The new address of the `positionsManager`.
    event PositionsManagerSet(address indexed _positionsManager);

    /// @notice Emitted when the `rewardsManager` is set.
    /// @param _newRewardsManagerAddress The new address of the `rewardsManager`.
    event RewardsManagerSet(address indexed _newRewardsManagerAddress);

    /// @notice Emitted when the `interestRatesManager` is set.
    /// @param _interestRatesManager The new address of the `interestRatesManager`.
    event InterestRatesSet(address indexed _interestRatesManager);

    /// @dev Emitted when a new `dustThreshold` is set.
    /// @param _dustThreshold The new `dustThreshold`.
    event DustThresholdSet(uint256 _dustThreshold);

    /// @notice Emitted when the `reserveFactor` is set.
    /// @param _poolTokenAddress The address of the concerned market.
    /// @param _newValue The new value of the `reserveFactor`.
    event ReserveFactorSet(address indexed _poolTokenAddress, uint16 _newValue);

    /// @notice Emitted when the `p2pIndexCursor` is set.
    /// @param _poolTokenAddress The address of the concerned market.
    /// @param _newValue The new value of the `p2pIndexCursor`.
    event P2PIndexCursorSet(address indexed _poolTokenAddress, uint16 _newValue);

    /// @notice Emitted when a reserve fee is claimed.
    /// @param _poolTokenAddress The address of the concerned market.
    /// @param _amountClaimed The amount of reward token claimed.
    event ReserveFeeClaimed(address indexed _poolTokenAddress, uint256 _amountClaimed);

    /// @notice Emitted when the value of `p2pDisabled` is set.
    /// @param _poolTokenAddress The address of the concerned market.
    /// @param _p2pDisabled The new value of `_p2pDisabled` adopted.
    event P2PStatusSet(address indexed _poolTokenAddress, bool _p2pDisabled);

    /// @notice Emitted when a market is paused or unpaused.
    /// @param _poolTokenAddress The address of the concerned market.
    /// @param _newStatus The new pause status of the market.
    event PauseStatusSet(address indexed _poolTokenAddress, bool _newStatus);

    /// @notice Emitted when a market is partially paused or unpaused.
    /// @param _poolTokenAddress The address of the concerned market.
    /// @param _newStatus The new partial pause status of the market.
    event PartialPauseStatusSet(address indexed _poolTokenAddress, bool _newStatus);

    /// @notice Emitted when a new market is created.
    /// @param _poolTokenAddress The address of the market that has been created.
    /// @param _reserveFactor The reserve factor set for this market.
    /// @param _poolTokenAddress The P2P index cursor set for this market.
    event MarketCreated(
        address indexed _poolTokenAddress,
        uint16 _reserveFactor,
        uint16 _p2pIndexCursor
    );

    /// ERRORS ///

    /// @notice Thrown when the creation of a market failed on Compound.
    error MarketCreationFailedOnCompound();

    /// @notice Thrown when the input is above the max basis points value (100%).
    error ExceedsMaxBasisPoints();

    /// @notice Thrown when the market is already created.
    error MarketAlreadyCreated();

    /// @notice Thrown when the amount is equal to 0.
    error AmountIsZero();

    /// @notice Thrown when the address is the zero address.
    error ZeroAddress();

    /// UPGRADE ///

    /// @notice Initializes the Morpho contract.
    /// @param _positionsManager The `positionsManager`.
    /// @param _interestRatesManager The `interestRatesManager`.
    /// @param _comptroller The `comptroller`.
    /// @param _defaultMaxGasForMatching The `defaultMaxGasForMatching`.
    /// @param _dustThreshold The `dustThreshold`.
    /// @param _maxSortedUsers The `_maxSortedUsers`.
    /// @param _cEth The cETH address.
    /// @param _wEth The wETH address.
    function initialize(
        IPositionsManager _positionsManager,
        IInterestRatesManager _interestRatesManager,
        IComptroller _comptroller,
        Types.MaxGasForMatching memory _defaultMaxGasForMatching,
        uint256 _dustThreshold,
        uint256 _maxSortedUsers,
        address _cEth,
        address _wEth
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        interestRatesManager = _interestRatesManager;
        positionsManager = _positionsManager;
        comptroller = _comptroller;

        defaultMaxGasForMatching = _defaultMaxGasForMatching;
        dustThreshold = _dustThreshold;
        maxSortedUsers = _maxSortedUsers;

        cEth = _cEth;
        wEth = _wEth;
    }

    /// GOVERNANCE ///

    /// @notice Sets `maxSortedUsers`.
    /// @param _newMaxSortedUsers The new `maxSortedUsers` value.
    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external onlyOwner {
        maxSortedUsers = _newMaxSortedUsers;
        emit MaxSortedUsersSet(_newMaxSortedUsers);
    }

    /// @notice Sets `defaultMaxGasForMatching`.
    /// @param _defaultMaxGasForMatching The new `defaultMaxGasForMatching`.
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _defaultMaxGasForMatching)
        external
        onlyOwner
    {
        defaultMaxGasForMatching = _defaultMaxGasForMatching;
        emit DefaultMaxGasForMatchingSet(_defaultMaxGasForMatching);
    }

    /// @notice Sets the `positionsManager`.
    /// @param _positionsManager The new `positionsManager`.
    function setPositionsManager(IPositionsManager _positionsManager) external onlyOwner {
        positionsManager = _positionsManager;
        emit PositionsManagerSet(address(_positionsManager));
    }

    /// @notice Sets the `rewardsManager`.
    /// @param _rewardsManager The new `rewardsManager`.
    function setRewardsManager(IRewardsManager _rewardsManager) external onlyOwner {
        rewardsManager = _rewardsManager;
        emit RewardsManagerSet(address(_rewardsManager));
    }

    /// @notice Sets the `interestRatesManager`.
    /// @param _interestRatesManager The new `interestRatesManager` contract.
    function setInterestRates(IInterestRatesManager _interestRatesManager) external onlyOwner {
        interestRatesManager = _interestRatesManager;
        emit InterestRatesSet(address(_interestRatesManager));
    }

    /// @notice Sets the `treasuryVault`.
    /// @param _treasuryVault The address of the new `treasuryVault`.
    function setTreasuryVault(address _treasuryVault) external onlyOwner {
        treasuryVault = _treasuryVault;
        emit TreasuryVaultSet(_treasuryVault);
    }

    /// @notice Sets the `incentivesVault`.
    /// @param _incentivesVault The new `incentivesVault`.
    function setIncentivesVault(IIncentivesVault _incentivesVault) external onlyOwner {
        incentivesVault = _incentivesVault;
        emit IncentivesVaultSet(address(_incentivesVault));
    }

    /// @dev Sets `dustThreshold`.
    /// @param _dustThreshold The new `dustThreshold`.
    function setDustThreshold(uint256 _dustThreshold) external onlyOwner {
        dustThreshold = _dustThreshold;
        emit DustThresholdSet(_dustThreshold);
    }

    /// @notice Sets the `reserveFactor`.
    /// @param _poolTokenAddress The market on which to set the `_newReserveFactor`.
    /// @param _newReserveFactor The proportion of the interest earned by users sent to the DAO, in basis point.
    function setReserveFactor(address _poolTokenAddress, uint16 _newReserveFactor)
        external
        onlyOwner
        isMarketCreated(_poolTokenAddress)
    {
        if (_newReserveFactor > MAX_BASIS_POINTS) revert ExceedsMaxBasisPoints();
        _updateP2PIndexes(_poolTokenAddress);

        marketParameters[_poolTokenAddress].reserveFactor = _newReserveFactor;
        emit ReserveFactorSet(_poolTokenAddress, _newReserveFactor);
    }

    /// @notice Sets a new peer-to-peer cursor.
    /// @param _poolTokenAddress The address of the market to update.
    /// @param _p2pIndexCursor The new peer-to-peer cursor.
    function setP2PIndexCursor(address _poolTokenAddress, uint16 _p2pIndexCursor)
        external
        onlyOwner
        isMarketCreated(_poolTokenAddress)
    {
        if (_p2pIndexCursor > MAX_BASIS_POINTS) revert ExceedsMaxBasisPoints();
        _updateP2PIndexes(_poolTokenAddress);

        marketParameters[_poolTokenAddress].p2pIndexCursor = _p2pIndexCursor;
        emit P2PIndexCursorSet(_poolTokenAddress, _p2pIndexCursor);
    }

    /// @notice Sets the pause status on a specific market in case of emergency.
    /// @param _poolTokenAddress The address of the market to pause/unpause.
    /// @param _newStatus The new status to set.
    function setPauseStatus(address _poolTokenAddress, bool _newStatus)
        external
        onlyOwner
        isMarketCreated(_poolTokenAddress)
    {
        marketStatus[_poolTokenAddress].isPaused = _newStatus;
        emit PauseStatusSet(_poolTokenAddress, _newStatus);
    }

    /// @notice Sets the partial pause status on a specific market in case of emergency.
    /// @param _poolTokenAddress The address of the market to partially pause/unpause.
    /// @param _newStatus The new status to set.
    function setPartialPauseStatus(address _poolTokenAddress, bool _newStatus)
        external
        onlyOwner
        isMarketCreated(_poolTokenAddress)
    {
        marketStatus[_poolTokenAddress].isPartiallyPaused = _newStatus;
        emit PartialPauseStatusSet(_poolTokenAddress, _newStatus);
    }

    /// @notice Sets the peer-to-peer disable status.
    /// @param _poolTokenAddress The address of the market to able/disable P2P.
    /// @param _newStatus The new status to set.
    function setP2PDisable(address _poolTokenAddress, bool _newStatus)
        external
        onlyOwner
        isMarketCreated(_poolTokenAddress)
    {
        p2pDisabled[_poolTokenAddress] = _newStatus;
        emit P2PStatusSet(_poolTokenAddress, _newStatus);
    }

    /// @notice Transfers the protocol reserve fee to the DAO.
    /// @dev No more than 90% of the accumulated fees are claimable at once.
    /// @param _poolTokenAddress The address of the market on which to claim the reserve fee.
    /// @param _amount The amount of underlying to claim.
    function claimToTreasury(address _poolTokenAddress, uint256 _amount)
        external
        onlyOwner
        isMarketCreatedAndNotPaused(_poolTokenAddress)
    {
        if (treasuryVault == address(0)) revert ZeroAddress();

        ERC20 underlyingToken = _getUnderlying(_poolTokenAddress);
        uint256 underlyingBalance = underlyingToken.balanceOf(address(this));

        if (underlyingBalance == 0) revert AmountIsZero();

        uint256 amountToClaim = Math.min(
            _amount,
            (underlyingBalance * MAX_CLAIMABLE_RESERVE) / MAX_BASIS_POINTS
        );

        underlyingToken.safeTransfer(treasuryVault, amountToClaim);
        emit ReserveFeeClaimed(_poolTokenAddress, amountToClaim);
    }

    /// @notice Creates a new market to borrow/supply in.
    /// @param _poolTokenAddress The pool token address of the given market.
    /// @param _marketParams The market's parameters to set.
    function createMarket(address _poolTokenAddress, Types.MarketParameters calldata _marketParams)
        external
        onlyOwner
    {
        if (
            _marketParams.p2pIndexCursor > MAX_BASIS_POINTS ||
            _marketParams.reserveFactor > MAX_BASIS_POINTS
        ) revert ExceedsMaxBasisPoints();

        if (marketStatus[_poolTokenAddress].isCreated) revert MarketAlreadyCreated();
        marketStatus[_poolTokenAddress].isCreated = true;

        address[] memory marketToEnter = new address[](1);
        marketToEnter[0] = _poolTokenAddress;
        uint256[] memory results = comptroller.enterMarkets(marketToEnter);
        if (results[0] != 0) revert MarketCreationFailedOnCompound();

        ICToken poolToken = ICToken(_poolTokenAddress);

        // Same initial index as Compound.
        uint256 initialIndex;
        if (_poolTokenAddress == cEth) initialIndex = 2e26;
        else initialIndex = 2 * 10**(16 + ERC20(poolToken.underlying()).decimals() - 8);
        p2pSupplyIndex[_poolTokenAddress] = initialIndex;
        p2pBorrowIndex[_poolTokenAddress] = initialIndex;

        Types.LastPoolIndexes storage poolIndexes = lastPoolIndexes[_poolTokenAddress];

        poolIndexes.lastUpdateBlockNumber = uint32(block.number);
        poolIndexes.lastSupplyPoolIndex = uint112(poolToken.exchangeRateCurrent());
        poolIndexes.lastBorrowPoolIndex = uint112(poolToken.borrowIndex());

        marketParameters[_poolTokenAddress] = _marketParams;

        marketsCreated.push(_poolTokenAddress);
        emit MarketCreated(
            _poolTokenAddress,
            _marketParams.reserveFactor,
            _marketParams.p2pIndexCursor
        );
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./MorphoGovernance.sol";

/// @title Morpho.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Main Morpho contract handling user interactions and pool interactions.
contract Morpho is MorphoGovernance {
    using SafeTransferLib for ERC20;
    using DelegateCall for address;

    /// EVENTS ///

    /// @notice Emitted when a user claims rewards.
    /// @param _user The address of the claimer.
    /// @param _amountClaimed The amount of reward token claimed.
    event RewardsClaimed(address indexed _user, uint256 _amountClaimed);

    /// @notice Emitted when a user claims rewards and trades them for MORPHO tokens.
    /// @param _user The address of the claimer.
    /// @param _amountSent The amount of reward token sent to the vault.
    event RewardsClaimedAndTraded(address indexed _user, uint256 _amountSent);

    /// EXTERNAL ///

    /// @notice Supplies underlying tokens in a specific market.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying) to supply.
    function supply(
        address _poolTokenAddress,
        address _onBehalf,
        uint256 _amount
    ) external nonReentrant isMarketCreatedAndNotPausedNorPartiallyPaused(_poolTokenAddress) {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.supplyLogic.selector,
                _poolTokenAddress,
                msg.sender,
                _onBehalf,
                _amount,
                defaultMaxGasForMatching.supply
            )
        );
    }

    /// @notice Supplies underlying tokens in a specific market.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying) to supply.
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function supply(
        address _poolTokenAddress,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external nonReentrant isMarketCreatedAndNotPausedNorPartiallyPaused(_poolTokenAddress) {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.supplyLogic.selector,
                _poolTokenAddress,
                msg.sender,
                _onBehalf,
                _amount,
                _maxGasForMatching
            )
        );
    }

    /// @notice Borrows underlying tokens in a specific market.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    function borrow(address _poolTokenAddress, uint256 _amount)
        external
        nonReentrant
        isMarketCreatedAndNotPausedNorPartiallyPaused(_poolTokenAddress)
    {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.borrowLogic.selector,
                _poolTokenAddress,
                _amount,
                defaultMaxGasForMatching.borrow
            )
        );
    }

    /// @notice Borrows underlying tokens in a specific market.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function borrow(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external nonReentrant isMarketCreatedAndNotPausedNorPartiallyPaused(_poolTokenAddress) {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.borrowLogic.selector,
                _poolTokenAddress,
                _amount,
                _maxGasForMatching
            )
        );
    }

    /// @notice Withdraws underlying tokens in a specific market.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of tokens (in underlying) to withdraw from supply.
    function withdraw(address _poolTokenAddress, uint256 _amount)
        external
        nonReentrant
        isMarketCreatedAndNotPaused(_poolTokenAddress)
    {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.withdrawLogic.selector,
                _poolTokenAddress,
                _amount,
                msg.sender,
                msg.sender,
                defaultMaxGasForMatching.withdraw
            )
        );
    }

    /// @notice Repays debt of the user.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying) to repay from borrow.
    function repay(
        address _poolTokenAddress,
        address _onBehalf,
        uint256 _amount
    ) external nonReentrant isMarketCreatedAndNotPaused(_poolTokenAddress) {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.repayLogic.selector,
                _poolTokenAddress,
                msg.sender,
                _onBehalf,
                _amount,
                defaultMaxGasForMatching.repay
            )
        );
    }

    /// @notice Liquidates a position.
    /// @param _poolTokenBorrowedAddress The address of the pool token the liquidator wants to repay.
    /// @param _poolTokenCollateralAddress The address of the collateral pool token the liquidator wants to seize.
    /// @param _borrower The address of the borrower to liquidate.
    /// @param _amount The amount of token (in underlying) to repay.
    function liquidate(
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    )
        external
        nonReentrant
        isMarketCreatedAndNotPaused(_poolTokenBorrowedAddress)
        isMarketCreatedAndNotPaused(_poolTokenCollateralAddress)
    {
        address(positionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                positionsManager.liquidateLogic.selector,
                _poolTokenBorrowedAddress,
                _poolTokenCollateralAddress,
                _borrower,
                _amount
            )
        );
    }

    /// @notice Claims rewards for the given assets.
    /// @param _cTokenAddresses The cToken addresses to claim rewards from.
    /// @param _tradeForMorphoToken Whether or not to trade COMP tokens for MORPHO tokens.
    function claimRewards(address[] calldata _cTokenAddresses, bool _tradeForMorphoToken)
        external
        nonReentrant
    {
        uint256 amountOfRewards = rewardsManager.claimRewards(_cTokenAddresses, msg.sender);

        if (amountOfRewards == 0) revert AmountIsZero();

        ERC20 comp = ERC20(comptroller.getCompAddress());
        // If there is not enough COMP tokens on the contract, claim them. Else, continue.
        if (comp.balanceOf(address(this)) < amountOfRewards)
            comptroller.claimComp(address(this), _cTokenAddresses);

        if (_tradeForMorphoToken) {
            comp.safeApprove(address(incentivesVault), amountOfRewards);
            incentivesVault.tradeCompForMorphoTokens(msg.sender, amountOfRewards);
            emit RewardsClaimedAndTraded(msg.sender, amountOfRewards);
        } else {
            comp.safeTransfer(msg.sender, amountOfRewards);
            emit RewardsClaimed(msg.sender, amountOfRewards);
        }
    }

    /// @notice Allows to receive ETH.
    receive() external payable {}
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/IRewardsManager.sol";
import "./interfaces/IMorpho.sol";

import "./libraries/CompoundMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title RewardsManager.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice This contract is used to manage the COMP rewards from the Compound protocol.
contract RewardsManager is IRewardsManager, Ownable {
    using CompoundMath for uint256;

    /// STORAGE ///

    mapping(address => uint256) public userUnclaimedCompRewards; // The unclaimed rewards of the user.
    mapping(address => mapping(address => uint256)) public compSupplierIndex; // The supply index of the user for a specific cToken. cToken -> user -> index.
    mapping(address => mapping(address => uint256)) public compBorrowerIndex; // The borrow index of the user for a specific cToken. cToken -> user -> index.
    mapping(address => IComptroller.CompMarketState) public localCompSupplyState; // The local supply state for a specific cToken.
    mapping(address => IComptroller.CompMarketState) public localCompBorrowState; // The local borrow state for a specific cToken.

    IMorpho public immutable morpho;
    IComptroller public immutable comptroller;

    /// ERRORS ///

    /// @notice Thrown when only Morpho can call the function.
    error OnlyMorpho();

    /// @notice Thrown when an invalid cToken address is passed to accrue rewards.
    error InvalidCToken();

    /// MODIFIERS ///

    /// @notice Thrown when an other address than Morpho triggers the function.
    modifier onlyMorpho() {
        if (msg.sender != address(morpho)) revert OnlyMorpho();
        _;
    }

    /// CONSTRUCTOR ///

    /// @notice Constructs the RewardsManager contract.
    /// @param _morpho The `morpho`.
    constructor(address _morpho) {
        morpho = IMorpho(_morpho);
        comptroller = IComptroller(morpho.comptroller());
    }

    /// EXTERNAL ///

    /// @notice Accrues unclaimed COMP rewards for the given cToken addresses and returns the total COMP unclaimed rewards.
    /// @dev This function is called by the `morpho` to accrue COMP rewards and reset them to 0.
    /// @dev The transfer of tokens is done in the `morpho`.
    /// @param _cTokenAddresses The cToken addresses for which to claim rewards.
    /// @param _user The address of the user.
    function claimRewards(address[] calldata _cTokenAddresses, address _user)
        external
        onlyMorpho
        returns (uint256 totalUnclaimedRewards)
    {
        totalUnclaimedRewards = accrueUserUnclaimedRewards(_cTokenAddresses, _user);
        if (totalUnclaimedRewards > 0) userUnclaimedCompRewards[_user] = 0;
    }

    /// @notice Updates the unclaimed COMP rewards of the user.
    /// @param _user The address of the user.
    /// @param _cTokenAddress The cToken address.
    /// @param _userBalance The user balance of tokens in the distribution.
    function accrueUserSupplyUnclaimedRewards(
        address _user,
        address _cTokenAddress,
        uint256 _userBalance
    ) external onlyMorpho {
        _updateSupplyIndex(_cTokenAddress);
        userUnclaimedCompRewards[_user] += _accrueSupplierComp(_user, _cTokenAddress, _userBalance);
    }

    /// @notice Updates the unclaimed COMP rewards of the user.
    /// @param _user The address of the user.
    /// @param _cTokenAddress The cToken address.
    /// @param _userBalance The user balance of tokens in the distribution.
    function accrueUserBorrowUnclaimedRewards(
        address _user,
        address _cTokenAddress,
        uint256 _userBalance
    ) external onlyMorpho {
        _updateBorrowIndex(_cTokenAddress);
        userUnclaimedCompRewards[_user] += _accrueBorrowerComp(_user, _cTokenAddress, _userBalance);
    }

    /// @notice Returns the unclaimed COMP rewards for the given cToken addresses.
    /// @param _cTokenAddresses The cToken addresses for which to compute the rewards.
    /// @param _user The address of the user.
    function getUserUnclaimedRewards(address[] calldata _cTokenAddresses, address _user)
        external
        view
        returns (uint256 unclaimedRewards)
    {
        unclaimedRewards = userUnclaimedCompRewards[_user];

        for (uint256 i; i < _cTokenAddresses.length; ) {
            address cTokenAddress = _cTokenAddresses[i];

            (bool isListed, , ) = comptroller.markets(cTokenAddress);
            if (!isListed) revert InvalidCToken();

            unclaimedRewards += getAccruedSupplierComp(
                _user,
                cTokenAddress,
                morpho.supplyBalanceInOf(cTokenAddress, _user).onPool
            );
            unclaimedRewards += getAccruedBorrowerComp(
                _user,
                cTokenAddress,
                morpho.borrowBalanceInOf(cTokenAddress, _user).onPool
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the local COMP supply state.
    /// @param _cTokenAddress The cToken address.
    /// @return The local COMP supply state.
    function getLocalCompSupplyState(address _cTokenAddress)
        external
        view
        override
        returns (IComptroller.CompMarketState memory)
    {
        return localCompSupplyState[_cTokenAddress];
    }

    /// @notice Returns the local COMP borrow state.
    /// @param _cTokenAddress The cToken address.
    /// @return The local COMP borrow state.
    function getLocalCompBorrowState(address _cTokenAddress)
        external
        view
        override
        returns (IComptroller.CompMarketState memory)
    {
        return localCompBorrowState[_cTokenAddress];
    }

    /// PUBLIC ///

    /// @notice Accrues unclaimed COMP rewards for the cToken addresses and returns the total unclaimed COMP rewards.
    /// @param _cTokenAddresses The cToken addresses for which to accrue rewards.
    /// @param _user The address of the user.
    /// @return unclaimedRewards The user unclaimed rewards.
    function accrueUserUnclaimedRewards(address[] calldata _cTokenAddresses, address _user)
        public
        returns (uint256 unclaimedRewards)
    {
        unclaimedRewards = userUnclaimedCompRewards[_user];

        for (uint256 i; i < _cTokenAddresses.length; ) {
            address cTokenAddress = _cTokenAddresses[i];

            (bool isListed, , ) = comptroller.markets(cTokenAddress);
            if (!isListed) revert InvalidCToken();

            _updateSupplyIndex(cTokenAddress);
            unclaimedRewards += _accrueSupplierComp(
                _user,
                cTokenAddress,
                morpho.supplyBalanceInOf(cTokenAddress, _user).onPool
            );

            _updateBorrowIndex(cTokenAddress);
            unclaimedRewards += _accrueBorrowerComp(
                _user,
                cTokenAddress,
                morpho.borrowBalanceInOf(cTokenAddress, _user).onPool
            );

            unchecked {
                ++i;
            }
        }

        userUnclaimedCompRewards[_user] = unclaimedRewards;
    }

    /// @notice Returns the accrued COMP rewards of a user since the last update.
    /// @param _supplier The address of the supplier.
    /// @param _cTokenAddress The cToken address.
    /// @param _balance The user balance of tokens in the distribution.
    /// @return The accrued COMP rewards.
    function getAccruedSupplierComp(
        address _supplier,
        address _cTokenAddress,
        uint256 _balance
    ) public view returns (uint256) {
        uint256 supplyIndex = getUpdatedSupplyIndex(_cTokenAddress);
        uint256 supplierIndex = compSupplierIndex[_cTokenAddress][_supplier];

        if (supplierIndex == 0) return 0;
        return (_balance * (supplyIndex - supplierIndex)) / 1e36;
    }

    /// @notice Returns the accrued COMP rewards of a user since the last update.
    /// @param _borrower The address of the borrower.
    /// @param _cTokenAddress The cToken address.
    /// @param _balance The user balance of tokens in the distribution.
    /// @return The accrued COMP rewards.
    function getAccruedBorrowerComp(
        address _borrower,
        address _cTokenAddress,
        uint256 _balance
    ) public view returns (uint256) {
        uint256 borrowIndex = getUpdatedBorrowIndex(_cTokenAddress);
        uint256 borrowerIndex = compBorrowerIndex[_cTokenAddress][_borrower];

        if (borrowerIndex == 0) return 0;
        return (_balance * (borrowIndex - borrowerIndex)) / 1e36;
    }

    /// @notice Returns the updated COMP supply index.
    /// @param _cTokenAddress The cToken address.
    /// @return The updated COMP supply index.
    function getUpdatedSupplyIndex(address _cTokenAddress) public view returns (uint256) {
        IComptroller.CompMarketState memory localSupplyState = localCompSupplyState[_cTokenAddress];
        uint256 blockNumber = block.number;

        if (localSupplyState.block == blockNumber) return localSupplyState.index;
        else {
            IComptroller.CompMarketState memory supplyState = comptroller.compSupplyState(
                _cTokenAddress
            );

            if (supplyState.block == blockNumber) return supplyState.index;
            else {
                uint256 deltaBlocks = localSupplyState.block == 0
                    ? blockNumber - supplyState.block
                    : blockNumber - localSupplyState.block;
                uint256 supplySpeed = comptroller.compSupplySpeeds(_cTokenAddress);

                if (supplySpeed > 0) {
                    uint256 supplyTokens = ICToken(_cTokenAddress).totalSupply();
                    uint256 compAccrued = deltaBlocks * supplySpeed;
                    uint256 ratio = supplyTokens > 0 ? (compAccrued * 1e36) / supplyTokens : 0;
                    uint256 formerIndex = localSupplyState.index == 0
                        ? supplyState.index
                        : localSupplyState.index;
                    return formerIndex + ratio;
                } else return supplyState.index;
            }
        }
    }

    /// @notice Returns the updated COMP borrow index.
    /// @param _cTokenAddress The cToken address.
    /// @return The updated COMP borrow index.
    function getUpdatedBorrowIndex(address _cTokenAddress) public view returns (uint256) {
        IComptroller.CompMarketState memory localBorrowState = localCompBorrowState[_cTokenAddress];
        uint256 blockNumber = block.number;

        if (localBorrowState.block == blockNumber) return localBorrowState.index;
        else {
            IComptroller.CompMarketState memory borrowState = comptroller.compBorrowState(
                _cTokenAddress
            );

            if (borrowState.block == blockNumber) return borrowState.index;
            else {
                uint256 deltaBlocks = localBorrowState.block == 0
                    ? blockNumber - borrowState.block
                    : blockNumber - localBorrowState.block;
                uint256 borrowSpeed = comptroller.compBorrowSpeeds(_cTokenAddress);

                if (borrowSpeed > 0) {
                    uint256 borrowAmount = ICToken(_cTokenAddress).totalBorrows().div(
                        ICToken(_cTokenAddress).borrowIndex()
                    );
                    uint256 compAccrued = deltaBlocks * borrowSpeed;
                    uint256 ratio = borrowAmount > 0 ? (compAccrued * 1e36) / borrowAmount : 0;
                    uint256 formerIndex = localBorrowState.index == 0
                        ? borrowState.index
                        : localBorrowState.index;
                    return formerIndex + ratio;
                } else return borrowState.index;
            }
        }
    }

    /// INTERNAL ///

    /// @notice Updates supplier index and returns the accrued COMP rewards of the supplier since the last update.
    /// @param _supplier The address of the supplier.
    /// @param _cTokenAddress The cToken address.
    /// @param _balance The user balance of tokens in the distribution.
    /// @return The accrued COMP rewards.
    function _accrueSupplierComp(
        address _supplier,
        address _cTokenAddress,
        uint256 _balance
    ) internal returns (uint256) {
        uint256 supplyIndex = localCompSupplyState[_cTokenAddress].index;
        uint256 supplierIndex = compSupplierIndex[_cTokenAddress][_supplier];
        compSupplierIndex[_cTokenAddress][_supplier] = supplyIndex;

        if (supplierIndex == 0) return 0;
        return (_balance * (supplyIndex - supplierIndex)) / 1e36;
    }

    /// @notice Updates borrower index and returns the accrued COMP rewards of the borrower since the last update.
    /// @param _borrower The address of the borrower.
    /// @param _cTokenAddress The cToken address.
    /// @param _balance The user balance of tokens in the distribution.
    /// @return The accrued COMP rewards.
    function _accrueBorrowerComp(
        address _borrower,
        address _cTokenAddress,
        uint256 _balance
    ) internal returns (uint256) {
        uint256 borrowIndex = localCompBorrowState[_cTokenAddress].index;
        uint256 borrowerIndex = compBorrowerIndex[_cTokenAddress][_borrower];
        compBorrowerIndex[_cTokenAddress][_borrower] = borrowIndex;

        if (borrowerIndex == 0) return 0;
        return (_balance * (borrowIndex - borrowerIndex)) / 1e36;
    }

    /// @notice Updates the COMP supply index.
    /// @param _cTokenAddress The cToken address.
    function _updateSupplyIndex(address _cTokenAddress) internal {
        IComptroller.CompMarketState storage localSupplyState = localCompSupplyState[
            _cTokenAddress
        ];
        uint256 blockNumber = block.number;

        if (localSupplyState.block == blockNumber) return;
        else {
            IComptroller.CompMarketState memory supplyState = comptroller.compSupplyState(
                _cTokenAddress
            );

            if (supplyState.block == blockNumber) {
                localSupplyState.block = supplyState.block;
                localSupplyState.index = supplyState.index;
            } else {
                uint256 deltaBlocks = localSupplyState.block == 0
                    ? blockNumber - supplyState.block
                    : blockNumber - localSupplyState.block;
                uint256 supplySpeed = comptroller.compSupplySpeeds(_cTokenAddress);

                if (supplySpeed > 0) {
                    uint256 supplyTokens = ICToken(_cTokenAddress).totalSupply();
                    uint256 compAccrued = deltaBlocks * supplySpeed;
                    uint256 ratio = supplyTokens > 0 ? (compAccrued * 1e36) / supplyTokens : 0;
                    uint256 formerIndex = localSupplyState.index == 0
                        ? supplyState.index
                        : localSupplyState.index;
                    uint256 index = formerIndex + ratio;
                    localCompSupplyState[_cTokenAddress] = IComptroller.CompMarketState({
                        index: CompoundMath.safe224(index),
                        block: CompoundMath.safe32(blockNumber)
                    });
                } else localSupplyState.block = CompoundMath.safe32(blockNumber);
            }
        }
    }

    /// @notice Updates the COMP borrow index.
    /// @param _cTokenAddress The cToken address.
    function _updateBorrowIndex(address _cTokenAddress) internal {
        IComptroller.CompMarketState storage localBorrowState = localCompBorrowState[
            _cTokenAddress
        ];
        uint256 blockNumber = block.number;

        if (localBorrowState.block == blockNumber) return;
        else {
            IComptroller.CompMarketState memory borrowState = comptroller.compBorrowState(
                _cTokenAddress
            );

            if (borrowState.block == blockNumber) {
                localBorrowState.block = borrowState.block;
                localBorrowState.index = borrowState.index;
            } else {
                uint256 deltaBlocks = localBorrowState.block == 0
                    ? blockNumber - borrowState.block
                    : blockNumber - localBorrowState.block;
                uint256 borrowSpeed = comptroller.compBorrowSpeeds(_cTokenAddress);

                if (borrowSpeed > 0) {
                    uint256 borrowAmount = ICToken(_cTokenAddress).totalBorrows().div(
                        ICToken(_cTokenAddress).borrowIndex()
                    );
                    uint256 compAccrued = deltaBlocks * borrowSpeed;
                    uint256 ratio = borrowAmount > 0 ? (compAccrued * 1e36) / borrowAmount : 0;
                    uint256 formerIndex = localBorrowState.index == 0
                        ? borrowState.index
                        : localBorrowState.index;
                    uint256 index = formerIndex + ratio;
                    localBorrowState.index = CompoundMath.safe224(index);
                    localBorrowState.block = CompoundMath.safe32(blockNumber);
                } else localBorrowState.block = CompoundMath.safe32(blockNumber);
            }
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./IInterestRatesManager.sol";
import "./IRewardsManager.sol";
import "./IPositionsManager.sol";
import "./IIncentivesVault.sol";

import "../libraries/Types.sol";

// prettier-ignore
interface IMorpho {

    /// STORAGE ///

    function defaultMaxGasForMatching() external view returns (Types.MaxGasForMatching memory);
    function maxSortedUsers() external view returns (uint256);
    function dustThreshold() external view returns (uint256);
    function supplyBalanceInOf(address, address) external view returns (Types.SupplyBalance memory);
    function borrowBalanceInOf(address, address) external view returns (Types.BorrowBalance memory);
    function enteredMarkets(address) external view returns (address);
    function deltas(address) external view returns (Types.Delta memory);
    function marketsCreated() external view returns (address[] memory);
    function marketParameters(address) external view returns (Types.MarketParameters memory);
    function p2pDisabled(address) external view returns (bool);
    function p2pSupplyIndex(address) external view returns (uint256);
    function p2pBorrowIndex(address) external view returns (uint256);
    function lastPoolIndexes(address) external view returns (Types.LastPoolIndexes memory);
    function marketStatus(address) external view returns (Types.MarketStatus memory);
    function comptroller() external view returns (IComptroller);
    function interestRatesManager() external view returns (IInterestRatesManager);
    function rewardsManager() external view returns (IRewardsManager);
    function positionsManager() external view returns (IPositionsManager);
    function incentiveVault() external view returns (IIncentivesVault);
    function treasuryVault() external view returns (address);
    function cEth() external view returns (address);
    function wEth() external view returns (address);

    /// GETTERS ///

    function updateP2PIndexes(address _poolTokenAddress) external;
    function getEnteredMarkets(address _user) external view returns (address[] memory enteredMarkets_);
    function getAllMarkets() external view returns (address[] memory marketsCreated_);
    function getHead(address _poolTokenAddress, Types.PositionType _positionType) external view returns (address head);
    function getNext(address _poolTokenAddress, Types.PositionType _positionType, address _user) external view returns (address next);

    /// GOVERNANCE ///

    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external;
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _maxGasForMatching) external;
    function setTreasuryVault(address _newTreasuryVaultAddress) external;
    function setIncentivesVault(address _newIncentivesVault) external;
    function setRewardsManager(address _rewardsManagerAddress) external;
    function setDustThreshold(uint256 _dustThreshold) external;
    function setP2PDisable(address _poolTokenAddress, bool _p2pDisabled) external;
    function setReserveFactor(address _poolTokenAddress, uint256 _newReserveFactor) external;
    function setP2PIndexCursor(address _poolTokenAddress, uint16 _p2pIndexCursor) external;
    function setPauseStatus(address _poolTokenAddress) external;
    function setPartialPauseStatus(address _poolTokenAddress) external;
    function claimToTreasury(address _poolTokenAddress, uint256 _amount) external;
    function createMarket(address _poolTokenAddress) external;

    /// USERS ///

    function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
    function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;
    function borrow(address _poolTokenAddress, uint256 _amount) external;
    function borrow(address _poolTokenAddress, uint256 _amount, uint256 _maxGasForMatching) external;
    function withdraw(address _poolTokenAddress, uint256 _amount) external;
    function repay(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
    function liquidate(address _poolTokenBorrowedAddress, address _poolTokenCollateralAddress, address _borrower, uint256 _amount) external;
    function claimRewards(address[] calldata _cTokenAddresses, bool _tradeForMorphoToken) external;
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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/IIncentivesVault.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMorpho.sol";

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title IncentivesVault.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Contract handling Morpho incentives.
contract IncentivesVault is IIncentivesVault, Ownable {
    using SafeTransferLib for ERC20;

    /// STORAGE ///

    uint256 public constant MAX_BASIS_POINTS = 10_000;

    IMorpho public immutable morpho; // The address of the main Morpho contract.
    IComptroller public immutable comptroller; // Compound's comptroller proxy.
    ERC20 public immutable morphoToken; // The MORPHO token.

    IOracle public oracle; // The oracle used to get the price of MORPHO tokens against COMP tokens.
    address public morphoDao; // The address of the Morpho DAO treasury.
    uint256 public bonus; // The bonus percentage of MORPHO tokens to give to the user.
    bool public isPaused; // Whether the trade of COMP rewards for MORPHO rewards is paused or not.

    /// EVENTS ///

    /// @notice Emitted when the oracle is set.
    event OracleSet(address _newOracle);

    /// @notice Emitted when the Morpho DAO is set.
    event MorphoDaoSet(address _newMorphoDao);

    /// @notice Emitted when the reward bonus is set.
    event BonusSet(uint256 _newBonus);

    /// @notice Emitted when the pause status is changed.
    event PauseStatusSet(bool _newStatus);

    /// @notice Emitted when MORPHO tokens are transferred to the DAO.
    event MorphoTokensTransferred(uint256 _amount);

    /// @notice Emitted when COMP tokens are traded for MORPHO tokens.
    /// @param _receiver The address of the receiver.
    /// @param _compAmount The amount of COMP traded.
    /// @param _morphoAmount The amount of MORPHO sent.
    event CompTokensTraded(address indexed _receiver, uint256 _compAmount, uint256 _morphoAmount);

    /// ERRORS ///

    /// @notice Thrown when an other address than Morpho triggers the function.
    error OnlyMorpho();

    /// @notice Thrown when the vault is paused.
    error VaultIsPaused();

    /// CONSTRUCTOR ///

    /// @notice Constructs the IncentivesVault contract.
    /// @param _comptroller The Compound comptroller.
    /// @param _morpho The main Morpho contract.
    /// @param _morphoToken The MORPHO token.
    /// @param _morphoDao The address of the Morpho DAO.
    /// @param _oracle The oracle.
    constructor(
        IComptroller _comptroller,
        IMorpho _morpho,
        ERC20 _morphoToken,
        address _morphoDao,
        IOracle _oracle
    ) {
        morpho = _morpho;
        comptroller = _comptroller;
        morphoToken = _morphoToken;
        morphoDao = _morphoDao;
        oracle = _oracle;
    }

    /// EXTERNAL ///

    /// @notice Sets the oracle.
    /// @param _newOracle The address of the new oracle.
    function setOracle(IOracle _newOracle) external onlyOwner {
        oracle = _newOracle;
        emit OracleSet(address(_newOracle));
    }

    /// @notice Sets the morpho DAO.
    /// @param _newMorphoDao The address of the Morpho DAO.
    function setMorphoDao(address _newMorphoDao) external onlyOwner {
        morphoDao = _newMorphoDao;
        emit MorphoDaoSet(_newMorphoDao);
    }

    /// @notice Sets the reward bonus.
    /// @param _newBonus The new reward bonus.
    function setBonus(uint256 _newBonus) external onlyOwner {
        bonus = _newBonus;
        emit BonusSet(_newBonus);
    }

    /// @notice Sets the pause status.
    /// @param _newStatus The new pause status.
    function setPauseStatus(bool _newStatus) external onlyOwner {
        isPaused = _newStatus;
        emit PauseStatusSet(_newStatus);
    }

    /// @notice Transfers the MORPHO tokens to the DAO.
    /// @param _amount The amount of MORPHO tokens to transfer to the DAO.
    function transferMorphoTokensToDao(uint256 _amount) external onlyOwner {
        morphoToken.safeTransfer(morphoDao, _amount);
        emit MorphoTokensTransferred(_amount);
    }

    /// @notice Trades COMP tokens for MORPHO tokens and sends them to the receiver.
    /// @param _receiver The address of the receiver.
    /// @param _amount The amount to transfer to the receiver.
    function tradeCompForMorphoTokens(address _receiver, uint256 _amount) external {
        if (msg.sender != address(morpho)) revert OnlyMorpho();
        if (isPaused) revert VaultIsPaused();
        // Transfer COMP to the DAO.
        ERC20(comptroller.getCompAddress()).safeTransferFrom(msg.sender, morphoDao, _amount);

        // Add a bonus on MORPHO rewards.
        uint256 amountOut = (oracle.consult(_amount) * (MAX_BASIS_POINTS + bonus)) /
            MAX_BASIS_POINTS;
        morphoToken.transfer(_receiver, amountOut);

        emit CompTokensTraded(_receiver, _amount, amountOut);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/compound/ICompound.sol";
import "./interfaces/IMorpho.sol";

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./libraries/CompoundMath.sol";

/// @title Lens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice User accessible getters.
contract Lens {
    using CompoundMath for uint256;

    /// STRUCTS ///

    struct Params {
        uint256 lastP2PSupplyIndex; // The current peer-to-peer supply index.
        uint256 lastP2PBorrowIndex; // The current peer-to-peer borrow index
        uint256 poolSupplyIndex; // The current pool supply index.
        uint256 poolBorrowIndex; // The current pool borrow index.
        uint256 lastPoolSupplyIndex; // The pool supply index at last update.
        uint256 lastPoolBorrowIndex; // The pool borrow index at last update.
        uint256 reserveFactor; // The reserve factor percentage (10 000 = 100%).
        uint256 p2pIndexCursor; // The peer-to-peer index cursor (10 000 = 100%).
        Types.Delta delta; // The deltas and peer-to-peer amounts.
    }

    struct RateParams {
        uint256 p2pIndex; // The peer-to-peer index.
        uint256 poolIndex; // The pool index.
        uint256 lastPoolIndex; // The pool index at last update.
        uint256 reserveFactor; // The reserve factor percentage (10 000 = 100%).
        uint256 p2pAmount; // Sum of all stored peer-to-peer balance in supply or borrow (in peer-to-peer unit).
        uint256 p2pDelta; // Sum of all stored peer-to-peer in supply or borrow (in peer-to-peer unit).
    }

    /// STORAGE ///

    uint256 public constant MAX_BASIS_POINTS = 10_000; // 100% (in basis points).
    uint256 public constant WAD = 1e18;
    IMorpho public immutable morpho;

    /// CONSTRUCTOR ///

    constructor(address _morphoAddress) {
        morpho = IMorpho(_morphoAddress);
    }

    /// ERRORS ///

    /// @notice Thrown when the Compound's oracle failed.
    error CompoundOracleFailed();

    ///////////////////////////////////
    ///           GETTERS           ///
    ///////////////////////////////////

    /// MARKET STATUSES ///

    /// @notice Checks if a market is created.
    /// @param _poolTokenAddress The address of the market to check.
    /// @return true if the market is created and not paused, otherwise false.
    function isMarketCreated(address _poolTokenAddress) external view returns (bool) {
        return morpho.marketStatus(_poolTokenAddress).isCreated;
    }

    /// @notice Checks if a market is created and not paused.
    /// @param _poolTokenAddress The address of the market to check.
    /// @return true if the market is created and not paused, otherwise false.
    function isMarketCreatedAndNotPaused(address _poolTokenAddress) external view returns (bool) {
        Types.MarketStatus memory marketStatus = morpho.marketStatus(_poolTokenAddress);
        return marketStatus.isCreated && !marketStatus.isPaused;
    }

    /// @notice Checks if a market is created and not paused or partially paused.
    /// @param _poolTokenAddress The address of the market to check.
    /// @return true if the market is created, not paused and not partially paused, otherwise false.
    function isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolTokenAddress)
        external
        view
        returns (bool)
    {
        Types.MarketStatus memory marketStatus = morpho.marketStatus(_poolTokenAddress);
        return marketStatus.isCreated && !marketStatus.isPaused && !marketStatus.isPartiallyPaused;
    }

    /// MARKET INFO ///

    /// @notice Returns all markets entered by a given user.
    /// @param _user The address of the user.
    /// @return enteredMarkets_ The list of markets entered by this user.
    function getEnteredMarkets(address _user)
        external
        view
        returns (address[] memory enteredMarkets_)
    {
        return morpho.getEnteredMarkets(_user);
    }

    /// @notice Returns all created markets.
    /// @return marketsCreated_ The list of market addresses.
    function getAllMarkets() external view returns (address[] memory marketsCreated_) {
        return morpho.getAllMarkets();
    }

    /// @notice Returns market's data.
    /// @return p2pSupplyIndex_ The peer-to-peer supply index of the market.
    /// @return p2pBorrowIndex_ The peer-to-peer borrow index of the market.
    /// @return lastUpdateBlockNumber_ The last block number when peer-to-peer indexes were updated.
    /// @return p2pSupplyDelta_ The peer-to-peer supply delta (in scaled balance).
    /// @return p2pBorrowDelta_ The peer-to-peer borrow delta (in cdUnit).
    /// @return p2pSupplyAmount_ The peer-to-peer supply amount (in peer-to-peer unit).
    /// @return p2pBorrowAmount_ The peer-to-peer borrow amount (in peer-to-peer unit).
    function getMarketData(address _poolTokenAddress)
        external
        view
        returns (
            uint256 p2pSupplyIndex_,
            uint256 p2pBorrowIndex_,
            uint32 lastUpdateBlockNumber_,
            uint256 p2pSupplyDelta_,
            uint256 p2pBorrowDelta_,
            uint256 p2pSupplyAmount_,
            uint256 p2pBorrowAmount_
        )
    {
        {
            Types.Delta memory delta = morpho.deltas(_poolTokenAddress);
            p2pSupplyDelta_ = delta.p2pSupplyDelta;
            p2pBorrowDelta_ = delta.p2pBorrowDelta;
            p2pSupplyAmount_ = delta.p2pSupplyAmount;
            p2pBorrowAmount_ = delta.p2pBorrowAmount;
        }
        p2pSupplyIndex_ = morpho.p2pSupplyIndex(_poolTokenAddress);
        p2pBorrowIndex_ = morpho.p2pBorrowIndex(_poolTokenAddress);
        lastUpdateBlockNumber_ = morpho.lastPoolIndexes(_poolTokenAddress).lastUpdateBlockNumber;
    }

    /// @notice Returns market's configuration.
    /// @return underlying_ The underlying token address.
    /// @return isCreated_ Whether the market is created or not.
    /// @return p2pDisabled_ Whether user are put in peer-to-peer or not.
    /// @return isPaused_ Whether the market is paused or not (all entry points on Morpho are frozen; supply, borrow, withdraw, repay and liquidate).
    /// @return isPartiallyPaused_ Whether the market is partially paused or not (only supply and borrow are frozen).
    /// @return reserveFactor_ The reserve actor applied to this market.
    /// @return collateralFactor_ The pool collateral factor also used by Morpho.
    function getMarketConfiguration(address _poolTokenAddress)
        external
        view
        returns (
            address underlying_,
            bool isCreated_,
            bool p2pDisabled_,
            bool isPaused_,
            bool isPartiallyPaused_,
            uint256 reserveFactor_,
            uint256 collateralFactor_
        )
    {
        underlying_ = ICToken(_poolTokenAddress).underlying();
        Types.MarketStatus memory marketStatus = morpho.marketStatus(_poolTokenAddress);
        isCreated_ = marketStatus.isCreated;
        p2pDisabled_ = morpho.p2pDisabled(_poolTokenAddress);
        isPaused_ = marketStatus.isPaused;
        isPartiallyPaused_ = marketStatus.isPartiallyPaused;
        reserveFactor_ = morpho.marketParameters(_poolTokenAddress).reserveFactor;
        (, collateralFactor_, ) = morpho.comptroller().markets(_poolTokenAddress);
    }

    /// @notice Computes and returns peer-to-peer and pool rates for a specific market (without taking into account deltas!).
    /// @param _poolTokenAddress The market address.
    /// @return p2pSupplyRate_ The market's peer-to-peer supply rate per block (in wad).
    /// @return p2pBorrowRate_ The market's peer-to-peer borrow rate per block (in wad).
    /// @return poolSupplyRate_ The market's pool supply rate per block (in wad).
    /// @return poolBorrowRate_ The market's pool borrow rate per block (in wad).
    function getRates(address _poolTokenAddress)
        public
        view
        returns (
            uint256 p2pSupplyRate_,
            uint256 p2pBorrowRate_,
            uint256 poolSupplyRate_,
            uint256 poolBorrowRate_
        )
    {
        ICToken cToken = ICToken(_poolTokenAddress);

        poolSupplyRate_ = cToken.supplyRatePerBlock();
        poolBorrowRate_ = cToken.borrowRatePerBlock();
        Types.MarketParameters memory marketParams = morpho.marketParameters(_poolTokenAddress);

        uint256 p2pRate = ((MAX_BASIS_POINTS - marketParams.p2pIndexCursor) *
            poolSupplyRate_ +
            marketParams.p2pIndexCursor *
            poolBorrowRate_) / MAX_BASIS_POINTS;

        p2pSupplyRate_ =
            p2pRate -
            (marketParams.reserveFactor * (p2pRate - poolSupplyRate_)) /
            MAX_BASIS_POINTS;
        p2pBorrowRate_ =
            p2pRate +
            (marketParams.reserveFactor * (poolBorrowRate_ - p2pRate)) /
            MAX_BASIS_POINTS;
    }

    /// BALANCES ///

    /// @notice Returns the collateral value, debt value and max debt value of a given user.
    /// @dev Note: must be called after calling `accrueInterest()` on the cToken to have the most up to date values.
    /// @param _user The user to determine liquidity for.
    /// @return collateralValue The collateral value of the user.
    /// @return debtValue The current debt value of the user.
    /// @return maxDebtValue The maximum possible debt value of the user.
    function getUserBalanceStates(address _user)
        external
        view
        returns (
            uint256 collateralValue,
            uint256 debtValue,
            uint256 maxDebtValue
        )
    {
        ICompoundOracle oracle = ICompoundOracle(morpho.comptroller().oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);
        uint256 i;

        while (i < enteredMarkets.length) {
            address poolTokenEntered = enteredMarkets[i];
            Types.AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                oracle
            );

            collateralValue += assetData.collateralValue;
            maxDebtValue += assetData.maxDebtValue;
            debtValue += assetData.debtValue;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param _user The user to determine balances of.
    /// @param _poolTokenAddress The address of the market.
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function getUserBorrowBalance(address _user, address _poolTokenAddress)
        external
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        )
    {
        (, uint256 newBorrowIndex) = _computePoolIndexes(_poolTokenAddress);
        balanceOnPool = morpho.borrowBalanceInOf(_poolTokenAddress, _user).onPool.mul(
            newBorrowIndex
        );
        balanceInP2P = morpho.borrowBalanceInOf(_poolTokenAddress, _user).inP2P.mul(
            getUpdatedP2PBorrowIndex(_poolTokenAddress)
        );
        totalBalance = balanceOnPool + balanceInP2P;
    }

    /// @notice Returns the balance in underlying of a given user in a given market.
    /// @param _user The user to determine balances of.
    /// @param _poolTokenAddress The address of the market.
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function getUserSupplyBalance(address _user, address _poolTokenAddress)
        external
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        )
    {
        (uint256 newSupplyIndex, ) = _computePoolIndexes(_poolTokenAddress);
        balanceOnPool = morpho.supplyBalanceInOf(_poolTokenAddress, _user).onPool.mul(
            newSupplyIndex
        );
        balanceInP2P = morpho.supplyBalanceInOf(_poolTokenAddress, _user).inP2P.mul(
            getUpdatedP2PSupplyIndex(_poolTokenAddress)
        );
        totalBalance = balanceOnPool + balanceInP2P;
    }

    /// @notice Returns the maximum amount available to withdraw and borrow for `_user` related to `_poolTokenAddress` (in underlyings).
    /// @dev Note: must be called after calling `accrueInterest()` on the cToken to have the most up to date values.
    /// @param _user The user to determine the capacities for.
    /// @param _poolTokenAddress The address of the market.
    /// @return withdrawable The maximum withdrawable amount of underlying token allowed (in underlying).
    /// @return borrowable The maximum borrowable amount of underlying token allowed (in underlying).
    function getUserMaxCapacitiesForAsset(address _user, address _poolTokenAddress)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable)
    {
        Types.LiquidityData memory data;
        Types.AssetLiquidityData memory assetData;
        ICompoundOracle oracle = ICompoundOracle(morpho.comptroller().oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);
        uint256 i;

        while (i < enteredMarkets.length) {
            address poolTokenEntered = enteredMarkets[i];

            if (_poolTokenAddress != poolTokenEntered) {
                assetData = getUserLiquidityDataForAsset(_user, poolTokenEntered, oracle);

                data.maxDebtValue += assetData.maxDebtValue;
                data.debtValue += assetData.debtValue;
            }

            unchecked {
                ++i;
            }
        }

        assetData = getUserLiquidityDataForAsset(_user, _poolTokenAddress, oracle);

        data.maxDebtValue += assetData.maxDebtValue;
        data.debtValue += assetData.debtValue;

        // Not possible to withdraw nor borrow.
        if (data.maxDebtValue < data.debtValue) return (0, 0);

        uint256 differenceInUnderlying = (data.maxDebtValue - data.debtValue).div(
            assetData.underlyingPrice
        );

        withdrawable = assetData.collateralValue.div(assetData.underlyingPrice);
        if (assetData.collateralFactor != 0) {
            withdrawable = Math.min(
                withdrawable,
                differenceInUnderlying.div(assetData.collateralFactor)
            );
        }

        borrowable = differenceInUnderlying;
    }

    /// @notice Returns the data related to `_poolTokenAddress` for the `_user`.
    /// @dev Note: must be called after calling `accrueInterest()` on the cToken to have the most up to date values.
    /// @param _user The user to determine data for.
    /// @param _poolTokenAddress The address of the market.
    /// @param _poolTokenAddress The address of the market.
    /// @param _oracle The oracle used.
    /// @return assetData The data related to this asset.
    function getUserLiquidityDataForAsset(
        address _user,
        address _poolTokenAddress,
        ICompoundOracle _oracle
    ) public view returns (Types.AssetLiquidityData memory assetData) {
        assetData.underlyingPrice = _oracle.getUnderlyingPrice(_poolTokenAddress);
        (, assetData.collateralFactor, ) = morpho.comptroller().markets(_poolTokenAddress);

        (
            uint256 newP2PSupplyIndex,
            uint256 newP2PBorrowIndex,
            uint256 newPoolSupplyIndex,
            uint256 newPoolBorrowIndex
        ) = getUpdatedIndexes(_poolTokenAddress);

        assetData.collateralValue = _computeUserSupplyBalanceInOf(
            _poolTokenAddress,
            _user,
            newP2PSupplyIndex,
            newPoolSupplyIndex
        ).mul(assetData.underlyingPrice);

        assetData.debtValue = _computeUserBorrowBalanceInOf(
            _poolTokenAddress,
            _user,
            newP2PBorrowIndex,
            newPoolBorrowIndex
        ).mul(assetData.underlyingPrice);

        assetData.maxDebtValue = assetData.collateralValue.mul(assetData.collateralFactor);
    }

    /// @dev Returns the debt value, max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    /// @param _poolTokenAddress The market to hypothetically withdraw/borrow in.
    /// @param _withdrawnAmount The number of tokens to hypothetically withdraw (in underlying).
    /// @param _borrowedAmount The amount of tokens to hypothetically borrow (in underlying).
    /// @return debtValue The current debt value of the user.
    /// @return maxDebtValue The maximum debt value possible of the user.
    function getUserHypotheticalBalanceStates(
        address _user,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) public view returns (uint256 debtValue, uint256 maxDebtValue) {
        ICompoundOracle oracle = ICompoundOracle(morpho.comptroller().oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);
        uint256 i;

        while (i < enteredMarkets.length) {
            address poolTokenEntered = enteredMarkets[i];

            Types.AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                oracle
            );

            maxDebtValue += assetData.maxDebtValue;
            debtValue += assetData.debtValue;
            unchecked {
                ++i;
            }

            if (_poolTokenAddress == poolTokenEntered) {
                if (_borrowedAmount > 0)
                    debtValue += _borrowedAmount.mul(assetData.underlyingPrice);

                if (_withdrawnAmount > 0)
                    maxDebtValue -= _withdrawnAmount.mul(assetData.underlyingPrice).mul(
                        assetData.collateralFactor
                    );
            }
        }
    }

    /// INDEXES ///

    /// @notice Returns the updated peer-to-peer indexes.
    /// @param _poolTokenAddress The address of the market.
    /// @return newP2PSupplyIndex The updated peer-to-peer supply index.
    /// @return newP2PBorrowIndex The updated peer-to-peer borrow index.
    function getUpdatedP2PIndexes(address _poolTokenAddress)
        external
        view
        returns (uint256 newP2PSupplyIndex, uint256 newP2PBorrowIndex)
    {
        (newP2PSupplyIndex, newP2PBorrowIndex, , ) = getUpdatedIndexes(_poolTokenAddress);
    }

    /// @notice Returns the updated pool indexes.
    /// @param _poolTokenAddress The address of the market.
    /// @return newPoolSupplyIndex_ The updated pool supply index.
    /// @return newPoolBorrowIndex_ The updated pool borrow index.
    function getUpdatedPoolIndexes(address _poolTokenAddress)
        external
        view
        returns (uint256 newPoolSupplyIndex_, uint256 newPoolBorrowIndex_)
    {
        return _computePoolIndexes(_poolTokenAddress);
    }

    /// @notice Returns the updated peer-to-peer supply index.
    /// @param _poolTokenAddress The address of the market.
    /// @return newP2PSupplyIndex The updated peer-to-peer supply index.
    function getUpdatedP2PSupplyIndex(address _poolTokenAddress) public view returns (uint256) {
        if (block.number == morpho.lastPoolIndexes(_poolTokenAddress).lastUpdateBlockNumber)
            return morpho.p2pSupplyIndex(_poolTokenAddress);
        else {
            Types.LastPoolIndexes memory poolIndexes = morpho.lastPoolIndexes(_poolTokenAddress);
            Types.MarketParameters memory marketParams = morpho.marketParameters(_poolTokenAddress);

            (uint256 poolSupplyIndex, uint256 poolBorrowIndex) = _computePoolIndexes(
                _poolTokenAddress
            );

            Params memory params = Params(
                morpho.p2pSupplyIndex(_poolTokenAddress),
                morpho.p2pBorrowIndex(_poolTokenAddress),
                poolSupplyIndex,
                poolBorrowIndex,
                poolIndexes.lastSupplyPoolIndex,
                poolIndexes.lastBorrowPoolIndex,
                marketParams.reserveFactor,
                marketParams.p2pIndexCursor,
                morpho.deltas(_poolTokenAddress)
            );

            return _computeP2PSupplyIndex(params);
        }
    }

    /// @notice Returns the updated peer-to-peer borrow index.
    /// @param _poolTokenAddress The address of the market.
    /// @return newP2PBorrowIndex The updated peer-to-peer borrow index.
    function getUpdatedP2PBorrowIndex(address _poolTokenAddress) public view returns (uint256) {
        if (block.number == morpho.lastPoolIndexes(_poolTokenAddress).lastUpdateBlockNumber)
            return morpho.p2pBorrowIndex(_poolTokenAddress);
        else {
            Types.LastPoolIndexes memory poolIndexes = morpho.lastPoolIndexes(_poolTokenAddress);
            Types.MarketParameters memory marketParams = morpho.marketParameters(_poolTokenAddress);

            (uint256 poolSupplyIndex, uint256 poolBorrowIndex) = _computePoolIndexes(
                _poolTokenAddress
            );

            Params memory params = Params(
                morpho.p2pSupplyIndex(_poolTokenAddress),
                morpho.p2pBorrowIndex(_poolTokenAddress),
                poolSupplyIndex,
                poolBorrowIndex,
                poolIndexes.lastSupplyPoolIndex,
                poolIndexes.lastBorrowPoolIndex,
                marketParams.reserveFactor,
                marketParams.p2pIndexCursor,
                morpho.deltas(_poolTokenAddress)
            );

            return _computeP2PBorrowIndex(params);
        }
    }

    /// @notice Returns the updated peer-to-peer and pool indexes.
    /// @param _poolTokenAddress The address of the market.
    /// @return newP2PSupplyIndex The updated peer-to-peer supply index.
    /// @return newP2PBorrowIndex The updated peer-to-peer borrow index.
    /// @return newPoolSupplyIndex The updated pool supply index.
    /// @return newPoolBorrowIndex The updated pool borrow index.
    function getUpdatedIndexes(address _poolTokenAddress)
        public
        view
        returns (
            uint256 newP2PSupplyIndex,
            uint256 newP2PBorrowIndex,
            uint256 newPoolSupplyIndex,
            uint256 newPoolBorrowIndex
        )
    {
        (newPoolSupplyIndex, newPoolBorrowIndex) = _computePoolIndexes(_poolTokenAddress);

        if (block.number == morpho.lastPoolIndexes(_poolTokenAddress).lastUpdateBlockNumber) {
            newP2PSupplyIndex = morpho.p2pSupplyIndex(_poolTokenAddress);
            newP2PBorrowIndex = morpho.p2pBorrowIndex(_poolTokenAddress);
        } else {
            Types.LastPoolIndexes memory poolIndexes = morpho.lastPoolIndexes(_poolTokenAddress);
            Types.MarketParameters memory marketParams = morpho.marketParameters(_poolTokenAddress);

            Params memory params = Params(
                morpho.p2pSupplyIndex(_poolTokenAddress),
                morpho.p2pBorrowIndex(_poolTokenAddress),
                newPoolSupplyIndex,
                newPoolBorrowIndex,
                poolIndexes.lastSupplyPoolIndex,
                poolIndexes.lastBorrowPoolIndex,
                marketParams.reserveFactor,
                marketParams.p2pIndexCursor,
                morpho.deltas(_poolTokenAddress)
            );

            (newP2PSupplyIndex, newP2PBorrowIndex) = _computeP2PIndexes(params);
        }
    }

    /// LIQUIDATION ///

    /// @dev Checks whether the user has enough collateral to maintain such a borrow position.
    /// @param _user The user to check.
    /// @return isLiquidable_ whether or not the user is liquidable.
    function isLiquidable(address _user) external view returns (bool) {
        ICompoundOracle oracle = ICompoundOracle(morpho.comptroller().oracle());
        address[] memory enteredMarkets = morpho.getEnteredMarkets(_user);
        uint256 numberOfEnteredMarkets = enteredMarkets.length;

        uint256 maxDebtValue;
        uint256 debtValue;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[i];

            Types.AssetLiquidityData memory assetData = _computeUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                oracle
            );

            maxDebtValue += assetData.maxDebtValue;
            debtValue += assetData.debtValue;
            ++i;
        }
        return debtValue > maxDebtValue;
    }

    ////////////////////////////////////
    ///           INTERNAL           ///
    ////////////////////////////////////

    /// @dev Returns the supply balance of `_user` in the `_poolTokenAddress` market.
    /// @dev Note: Compute the result with the index stored and not the most up to date one.
    /// @param _user The address of the user.
    /// @param _poolTokenAddress The market where to get the supply amount.
    /// @return The supply balance of the user (in underlying).
    function _computeUserSupplyBalanceInOf(
        address _poolTokenAddress,
        address _user,
        uint256 _p2pSupplyIndex,
        uint256 _poolSupplyIndex
    ) internal view returns (uint256) {
        return
            morpho.supplyBalanceInOf(_poolTokenAddress, _user).inP2P.mul(_p2pSupplyIndex) +
            morpho.supplyBalanceInOf(_poolTokenAddress, _user).onPool.mul(_poolSupplyIndex);
    }

    /// @dev Returns the borrow balance of `_user` in the `_poolTokenAddress` market.
    /// @param _user The address of the user.
    /// @param _poolTokenAddress The market where to get the borrow amount.
    /// @return The borrow balance of the user (in underlying).
    function _computeUserBorrowBalanceInOf(
        address _poolTokenAddress,
        address _user,
        uint256 _p2pBorrowIndex,
        uint256 _poolBorrowIndex
    ) internal view returns (uint256) {
        return
            morpho.borrowBalanceInOf(_poolTokenAddress, _user).inP2P.mul(_p2pBorrowIndex) +
            morpho.borrowBalanceInOf(_poolTokenAddress, _user).onPool.mul(_poolBorrowIndex);
    }

    /// @notice Returns the data related to `_poolTokenAddress` for the `_user`.
    /// @param _user The user to determine data for.
    /// @param _poolTokenAddress The address of the market.
    /// @param _oracle The oracle used.
    /// @return assetData The data related to this asset.
    function _computeUserLiquidityDataForAsset(
        address _user,
        address _poolTokenAddress,
        ICompoundOracle _oracle
    ) internal view returns (Types.AssetLiquidityData memory assetData) {
        assetData.underlyingPrice = _oracle.getUnderlyingPrice(_poolTokenAddress);
        if (assetData.underlyingPrice == 0) revert CompoundOracleFailed();
        (, assetData.collateralFactor, ) = morpho.comptroller().markets(_poolTokenAddress);
        (
            uint256 newP2PSupplyIndex,
            uint256 newP2PBorrowIndex,
            uint256 newPoolSupplyIndex,
            uint256 newPoolBorrowIndex
        ) = getUpdatedIndexes(_poolTokenAddress);

        assetData.collateralValue = _computeUserSupplyBalanceInOf(
            _poolTokenAddress,
            _user,
            newP2PSupplyIndex,
            newPoolSupplyIndex
        ).mul(assetData.underlyingPrice);
        assetData.debtValue = _computeUserBorrowBalanceInOf(
            _poolTokenAddress,
            _user,
            newP2PBorrowIndex,
            newPoolBorrowIndex
        ).mul(assetData.underlyingPrice);
        assetData.maxDebtValue = assetData.collateralValue.mul(assetData.collateralFactor);
    }

    /// INDEXES ///

    /// @dev Computes and returns Compound's updated indexes.
    /// @param _poolTokenAddress The address of the market.
    /// @return newSupplyIndex The updated supply index.
    /// @return newBorrowIndex The updated borrow index.
    function _computePoolIndexes(address _poolTokenAddress)
        internal
        view
        returns (uint256 newSupplyIndex, uint256 newBorrowIndex)
    {
        ICToken cToken = ICToken(_poolTokenAddress);
        uint256 accrualBlockNumberPrior = cToken.accrualBlockNumber();

        if (block.number == accrualBlockNumberPrior)
            return (cToken.exchangeRateStored(), cToken.borrowIndex());

        // Read the previous values out of storage
        uint256 cashPrior = cToken.getCash();
        uint256 totalSupply = cToken.totalSupply();
        uint256 borrowsPrior = cToken.totalBorrows();
        uint256 reservesPrior = cToken.totalReserves();
        uint256 borrowIndexPrior = cToken.borrowIndex();

        // Calculate the current borrow interest rate
        uint256 borrowRateMantissa = cToken.interestRateModel().getBorrowRate(
            cashPrior,
            borrowsPrior,
            reservesPrior
        );
        require(borrowRateMantissa <= 0.0005e16, "borrow rate is absurdly high");

        uint256 blockDelta = block.number - accrualBlockNumberPrior;

        // Calculate the interest accumulated into borrows and reserves and the new index.
        uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
        uint256 interestAccumulated = simpleInterestFactor.mul(borrowsPrior);
        uint256 totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint256 totalReservesNew = cToken.reserveFactorMantissa().mul(interestAccumulated) +
            reservesPrior;

        newSupplyIndex = totalSupply > 0
            ? (cashPrior + totalBorrowsNew - totalReservesNew).div(totalSupply)
            : cToken.initialExchangeRateMantissa();
        newBorrowIndex = simpleInterestFactor.mul(borrowIndexPrior) + borrowIndexPrior;
    }

    /// @notice Computes and returns new peer-to-peer indexes.
    /// @param _params Computation parameters.
    /// @return newP2PSupplyIndex The updated peer-to-peer supply index.
    /// @return newP2PBorrowIndex The updated peer-to-peer borrow index.
    function _computeP2PIndexes(Params memory _params)
        internal
        pure
        returns (uint256 newP2PSupplyIndex, uint256 newP2PBorrowIndex)
    {
        // Compute pool growth factors

        uint256 poolSupplyGrowthFactor = _params.poolSupplyIndex.div(_params.lastPoolSupplyIndex);
        uint256 poolBorrowGrowthFactor = _params.poolBorrowIndex.div(_params.lastPoolBorrowIndex);

        // Compute peer-to-peer growth factors

        uint256 p2pGrowthFactor = ((MAX_BASIS_POINTS - _params.p2pIndexCursor) *
            poolSupplyGrowthFactor +
            _params.p2pIndexCursor *
            poolBorrowGrowthFactor) / MAX_BASIS_POINTS;
        uint256 p2pSupplyGrowthFactor = p2pGrowthFactor -
            (_params.reserveFactor * (p2pGrowthFactor - poolSupplyGrowthFactor)) /
            MAX_BASIS_POINTS;
        uint256 p2pBorrowGrowthFactor = p2pGrowthFactor +
            (_params.reserveFactor * (poolBorrowGrowthFactor - p2pGrowthFactor)) /
            MAX_BASIS_POINTS;

        // Compute new peer-to-peer supply index

        if (_params.delta.p2pSupplyAmount == 0 || _params.delta.p2pSupplyDelta == 0) {
            newP2PSupplyIndex = _params.lastP2PSupplyIndex.mul(p2pSupplyGrowthFactor);
        } else {
            uint256 shareOfTheDelta = CompoundMath.min(
                (_params.delta.p2pSupplyDelta.mul(_params.lastPoolSupplyIndex)).div(
                    (_params.delta.p2pSupplyAmount).mul(_params.lastP2PSupplyIndex)
                ),
                WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PSupplyIndex = _params.lastP2PSupplyIndex.mul(
                (WAD - shareOfTheDelta).mul(p2pSupplyGrowthFactor) +
                    shareOfTheDelta.mul(poolSupplyGrowthFactor)
            );
        }

        // Compute new peer-to-peer borrow index

        if (_params.delta.p2pBorrowAmount == 0 || _params.delta.p2pBorrowDelta == 0) {
            newP2PBorrowIndex = _params.lastP2PBorrowIndex.mul(p2pBorrowGrowthFactor);
        } else {
            uint256 shareOfTheDelta = CompoundMath.min(
                (_params.delta.p2pBorrowDelta.mul(_params.poolBorrowIndex)).div(
                    (_params.delta.p2pBorrowAmount).mul(_params.lastP2PBorrowIndex)
                ),
                WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PBorrowIndex = _params.lastP2PBorrowIndex.mul(
                (WAD - shareOfTheDelta).mul(p2pBorrowGrowthFactor) +
                    shareOfTheDelta.mul(poolBorrowGrowthFactor)
            );
        }
    }

    /// @notice Computes and returns the new peer-to-peer supply index.
    /// @param _params Computation parameters.
    /// @return newP2PSupplyIndex The updated p2pSupplyIndex.
    function _computeP2PSupplyIndex(Params memory _params)
        internal
        pure
        returns (uint256 newP2PSupplyIndex)
    {
        // Compute pool growth factors

        uint256 poolSupplyGrowthFactor = _params.poolSupplyIndex.div(_params.lastPoolSupplyIndex);
        uint256 poolBorrowGrowthFactor = _params.poolBorrowIndex.div(_params.lastPoolBorrowIndex);

        // Compute peer-to-peer growth factors

        uint256 p2pGrowthFactor = ((MAX_BASIS_POINTS - _params.p2pIndexCursor) *
            poolSupplyGrowthFactor +
            _params.p2pIndexCursor *
            poolBorrowGrowthFactor) / MAX_BASIS_POINTS;
        uint256 p2pSupplyGrowthFactor = p2pGrowthFactor -
            (_params.reserveFactor * (p2pGrowthFactor - poolSupplyGrowthFactor)) /
            MAX_BASIS_POINTS;

        // Compute new peer-to-peer supply index

        if (_params.delta.p2pSupplyAmount == 0 || _params.delta.p2pSupplyDelta == 0) {
            newP2PSupplyIndex = _params.lastP2PSupplyIndex.mul(p2pSupplyGrowthFactor);
        } else {
            uint256 shareOfTheDelta = CompoundMath.min(
                (_params.delta.p2pSupplyDelta.mul(_params.lastPoolSupplyIndex)).div(
                    (_params.delta.p2pSupplyAmount).mul(_params.lastP2PSupplyIndex)
                ),
                WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PSupplyIndex = _params.lastP2PSupplyIndex.mul(
                (WAD - shareOfTheDelta).mul(p2pSupplyGrowthFactor) +
                    shareOfTheDelta.mul(poolSupplyGrowthFactor)
            );
        }
    }

    /// @notice Computes and return the new peer-to-peer borrow index.
    /// @param _params Computation parameters.
    /// @return newP2PBorrowIndex The updated p2pBorrowIndex.
    function _computeP2PBorrowIndex(Params memory _params)
        internal
        pure
        returns (uint256 newP2PBorrowIndex)
    {
        // Compute pool growth factors

        uint256 poolSupplyGrowthFactor = _params.poolSupplyIndex.div(_params.lastPoolSupplyIndex);
        uint256 poolBorrowGrowthFactor = _params.poolBorrowIndex.div(_params.lastPoolBorrowIndex);

        // Compute peer-to-peer growth factors

        uint256 p2pGrowthFactor = ((MAX_BASIS_POINTS - _params.p2pIndexCursor) *
            poolSupplyGrowthFactor +
            _params.p2pIndexCursor *
            poolBorrowGrowthFactor) / MAX_BASIS_POINTS;
        uint256 p2pBorrowGrowthFactor = p2pGrowthFactor +
            (_params.reserveFactor * (poolBorrowGrowthFactor - p2pGrowthFactor)) /
            MAX_BASIS_POINTS;

        // Compute new peer-to-peer borrow index

        if (_params.delta.p2pBorrowAmount == 0 || _params.delta.p2pBorrowDelta == 0) {
            newP2PBorrowIndex = _params.lastP2PBorrowIndex.mul(p2pBorrowGrowthFactor);
        } else {
            uint256 shareOfTheDelta = CompoundMath.min(
                (_params.delta.p2pBorrowDelta.mul(_params.poolBorrowIndex)).div(
                    (_params.delta.p2pBorrowAmount).mul(_params.lastP2PBorrowIndex)
                ),
                WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PBorrowIndex = _params.lastP2PBorrowIndex.mul(
                (WAD - shareOfTheDelta).mul(p2pBorrowGrowthFactor) +
                    shareOfTheDelta.mul(poolBorrowGrowthFactor)
            );
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/IPositionsManager.sol";
import "./interfaces/IWETH.sol";

import "./MatchingEngine.sol";

/// @title PositionsManager.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Main Logic of Morpho Protocol, implementation of the 5 main functionalities: supply, borrow, withdraw, repay and liquidate.
contract PositionsManager is IPositionsManager, MatchingEngine {
    using DoubleLinkedList for DoubleLinkedList.List;
    using SafeTransferLib for ERC20;
    using CompoundMath for uint256;

    /// EVENTS ///

    /// @notice Emitted when a supply happens.
    /// @param _supplier The address of the account sending funds.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _poolTokenAddress The address of the market where assets are supplied into.
    /// @param _amount The amount of assets supplied (in underlying).
    /// @param _balanceOnPool The supply balance on pool after update.
    /// @param _balanceInP2P The supply balance in peer-to-peer after update.
    event Supplied(
        address indexed _supplier,
        address indexed _onBehalf,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when a borrow happens.
    /// @param _borrower The address of the borrower.
    /// @param _poolTokenAddress The address of the market where assets are borrowed.
    /// @param _amount The amount of assets borrowed (in underlying).
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in peer-to-peer after update
    event Borrowed(
        address indexed _borrower,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when a withdrawal happens.
    /// @param _supplier The address of the supplier whose supply is withdrawn.
    /// @param _receiver The address receiving the tokens.
    /// @param _poolTokenAddress The address of the market from where assets are withdrawn.
    /// @param _amount The amount of assets withdrawn (in underlying).
    /// @param _balanceOnPool The supply balance on pool after update.
    /// @param _balanceInP2P The supply balance in peer-to-peer after update.
    event Withdrawn(
        address indexed _supplier,
        address indexed _receiver,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when a repayment happens.
    /// @param _repayer The address of the account repaying the debt.
    /// @param _onBehalf The address of the account whose debt is repaid.
    /// @param _poolTokenAddress The address of the market where assets are repaid.
    /// @param _amount The amount of assets repaid (in underlying).
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in peer-to-peer after update.
    event Repaid(
        address indexed _repayer,
        address indexed _onBehalf,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when a liquidation happens.
    /// @param _liquidator The address of the liquidator.
    /// @param _liquidated The address of the liquidated.
    /// @param _poolTokenBorrowedAddress The address of the borrowed asset.
    /// @param _amountRepaid The amount of borrowed asset repaid (in underlying).
    /// @param _poolTokenCollateralAddress The address of the collateral asset seized.
    /// @param _amountSeized The amount of collateral asset seized (in underlying).
    event Liquidated(
        address _liquidator,
        address indexed _liquidated,
        address indexed _poolTokenBorrowedAddress,
        uint256 _amountRepaid,
        address indexed _poolTokenCollateralAddress,
        uint256 _amountSeized
    );

    /// @notice Emitted when the borrow peer-to-peer delta is updated.
    /// @param _poolTokenAddress The address of the market.
    /// @param _p2pBorrowDelta The borrow peer-to-peer delta after update.
    event P2PBorrowDeltaUpdated(address indexed _poolTokenAddress, uint256 _p2pBorrowDelta);

    /// @notice Emitted when the supply peer-to-peer delta is updated.
    /// @param _poolTokenAddress The address of the market.
    /// @param _p2pSupplyDelta The supply peer-to-peer delta after update.
    event P2PSupplyDeltaUpdated(address indexed _poolTokenAddress, uint256 _p2pSupplyDelta);

    /// @notice Emitted when the supply and borrow peer-to-peer amounts are updated.
    /// @param _poolTokenAddress The address of the market.
    /// @param _p2pSupplyAmount The supply peer-to-peer amount after update.
    /// @param _p2pBorrowAmount The borrow peer-to-peer amount after update.
    event P2PAmountsUpdated(
        address indexed _poolTokenAddress,
        uint256 _p2pSupplyAmount,
        uint256 _p2pBorrowAmount
    );

    /// ERRORS ///

    /// @notice Thrown when the amount repaid during the liquidation is above what is allowed to be repaid.
    error AmountAboveWhatAllowedToRepay();

    /// @notice Thrown when the amount of collateral to seize is above the collateral amount.
    error ToSeizeAboveCollateral();

    /// @notice Thrown when the borrow on Compound failed.
    error BorrowOnCompoundFailed();

    /// @notice Thrown when the redeem on Compound failed .
    error RedeemOnCompoundFailed();

    /// @notice Thrown when the repay on Compound failed.
    error RepayOnCompoundFailed();

    /// @notice Thrown when the mint on Compound failed.
    error MintOnCompoundFailed();

    /// @notice Thrown when user is not a member of the market.
    error UserNotMemberOfMarket();

    /// @notice Thrown when the user does not have enough remaining collateral to withdraw.
    error UnauthorisedWithdraw();

    /// @notice Thrown when the positions of the user is not liquidatable.
    error UnauthorisedLiquidate();

    /// @notice Thrown when the user does not have enough collateral for the borrow.
    error UnauthorisedBorrow();

    /// @notice Thrown when the amount desired for a withdrawal is too small.
    error WithdrawTooSmall();

    /// @notice Thrown when the address is zero.
    error AddressIsZero();

    /// @notice Thrown when the amount is equal to 0.
    error AmountIsZero();

    /// STRUCTS ///

    // Struct to avoid stack too deep.
    struct SupplyVars {
        uint256 remainingToSupply;
        uint256 poolBorrowIndex;
        uint256 toRepay;
    }

    // Struct to avoid stack too deep.
    struct WithdrawVars {
        uint256 remainingToWithdraw;
        uint256 maxGasForMatching;
        uint256 poolSupplyIndex;
        uint256 p2pSupplyIndex;
        uint256 withdrawable;
        uint256 toWithdraw;
        ERC20 underlyingToken;
        ICToken poolToken;
    }

    // Struct to avoid stack too deep.
    struct RepayVars {
        uint256 maxGasForMatching;
        uint256 remainingToRepay;
        uint256 maxToRepayOnPool;
        uint256 poolBorrowIndex;
        uint256 p2pSupplyIndex;
        uint256 p2pBorrowIndex;
        uint256 borrowedOnPool;
        uint256 feeToRepay;
        uint256 toRepay;
    }

    // Struct to avoid stack too deep.
    struct LiquidateVars {
        uint256 collateralPrice;
        uint256 borrowBalance;
        uint256 supplyBalance;
        uint256 borrowedPrice;
        uint256 amountToSeize;
        uint256 maxDebtValue;
        uint256 debtValue;
    }

    /// LOGIC ///

    /// @dev Implements supply logic.
    /// @param _poolTokenAddress The address of the pool token the user wants to interact with.
    /// @param _supplier The address of the account sending funds.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function supplyLogic(
        address _poolTokenAddress,
        address _supplier,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external {
        if (_onBehalf == address(0)) revert AddressIsZero();
        if (_amount == 0) revert AmountIsZero();
        _updateP2PIndexes(_poolTokenAddress);

        _enterMarketIfNeeded(_poolTokenAddress, _onBehalf);
        ERC20 underlyingToken = _getUnderlying(_poolTokenAddress);
        underlyingToken.safeTransferFrom(_supplier, address(this), _amount);

        Types.Delta storage delta = deltas[_poolTokenAddress];
        SupplyVars memory vars;
        vars.poolBorrowIndex = ICToken(_poolTokenAddress).borrowIndex();
        vars.remainingToSupply = _amount;

        /// Supply in peer-to-peer ///

        // Match borrow peer-to-peer delta first if any.
        if (delta.p2pBorrowDelta > 0) {
            uint256 deltaInUnderlying = delta.p2pBorrowDelta.mul(vars.poolBorrowIndex);
            if (deltaInUnderlying > vars.remainingToSupply) {
                vars.toRepay += vars.remainingToSupply;
                delta.p2pBorrowDelta -= vars.remainingToSupply.div(vars.poolBorrowIndex);
                vars.remainingToSupply = 0;
            } else {
                vars.toRepay += deltaInUnderlying;
                delta.p2pBorrowDelta = 0;
                vars.remainingToSupply -= deltaInUnderlying;
            }
            emit P2PBorrowDeltaUpdated(_poolTokenAddress, delta.p2pBorrowDelta);
        }

        // Match pool borrowers if any.
        if (
            vars.remainingToSupply > 0 &&
            !p2pDisabled[_poolTokenAddress] &&
            borrowersOnPool[_poolTokenAddress].getHead() != address(0)
        ) {
            (uint256 matched, ) = _matchBorrowers(
                _poolTokenAddress,
                vars.remainingToSupply,
                _maxGasForMatching
            ); // In underlying.

            if (matched > 0) {
                vars.toRepay += matched;
                vars.remainingToSupply -= matched;
                delta.p2pBorrowAmount += matched.div(p2pBorrowIndex[_poolTokenAddress]);
            }
        }

        if (vars.toRepay > 0) {
            uint256 toAddInP2P = vars.toRepay.div(p2pSupplyIndex[_poolTokenAddress]);

            delta.p2pSupplyAmount += toAddInP2P;
            supplyBalanceInOf[_poolTokenAddress][_onBehalf].inP2P += toAddInP2P;
            _repayToPool(_poolTokenAddress, underlyingToken, vars.toRepay); // Reverts on error.

            emit P2PAmountsUpdated(_poolTokenAddress, delta.p2pSupplyAmount, delta.p2pBorrowAmount);
        }

        /// Supply on pool ///

        if (vars.remainingToSupply > 0) {
            supplyBalanceInOf[_poolTokenAddress][_onBehalf].onPool += vars.remainingToSupply.div(
                ICToken(_poolTokenAddress).exchangeRateStored() // Exchange rate has already been updated.
            ); // In scaled balance.
            _supplyToPool(_poolTokenAddress, underlyingToken, vars.remainingToSupply); // Reverts on error.
        }

        _updateSupplierInDS(_poolTokenAddress, _onBehalf);

        emit Supplied(
            _supplier,
            _onBehalf,
            _poolTokenAddress,
            _amount,
            supplyBalanceInOf[_poolTokenAddress][_onBehalf].onPool,
            supplyBalanceInOf[_poolTokenAddress][_onBehalf].inP2P
        );
    }

    /// @dev Implements borrow logic.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function borrowLogic(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external {
        if (_amount == 0) revert AmountIsZero();
        _updateP2PIndexes(_poolTokenAddress);

        _enterMarketIfNeeded(_poolTokenAddress, msg.sender);
        if (_isLiquidatable(msg.sender, _poolTokenAddress, 0, _amount)) revert UnauthorisedBorrow();
        ERC20 underlyingToken = _getUnderlying(_poolTokenAddress);
        uint256 remainingToBorrow = _amount;
        uint256 toWithdraw;
        Types.Delta storage delta = deltas[_poolTokenAddress];
        uint256 poolSupplyIndex = ICToken(_poolTokenAddress).exchangeRateStored(); // Exchange rate has already been updated.
        uint256 withdrawable = ICToken(_poolTokenAddress).balanceOfUnderlying(address(this)); // The balance on pool.

        /// Borrow in peer-to-peer ///

        // Match supply peer-to-peer delta first if any.
        if (delta.p2pSupplyDelta > 0) {
            uint256 deltaInUnderlying = delta.p2pSupplyDelta.mul(poolSupplyIndex);
            if (deltaInUnderlying > remainingToBorrow || deltaInUnderlying > withdrawable) {
                uint256 matchedDelta = CompoundMath.min(remainingToBorrow, withdrawable);
                toWithdraw += matchedDelta;
                delta.p2pSupplyDelta -= matchedDelta.div(poolSupplyIndex);
                remainingToBorrow -= matchedDelta;
            } else {
                toWithdraw += deltaInUnderlying;
                delta.p2pSupplyDelta = 0;
                remainingToBorrow -= deltaInUnderlying;
            }

            emit P2PSupplyDeltaUpdated(_poolTokenAddress, delta.p2pSupplyDelta);
        }

        // Match pool suppliers if any.
        if (
            remainingToBorrow > 0 &&
            !p2pDisabled[_poolTokenAddress] &&
            suppliersOnPool[_poolTokenAddress].getHead() != address(0)
        ) {
            (uint256 matched, ) = _matchSuppliers(
                _poolTokenAddress,
                CompoundMath.min(remainingToBorrow, withdrawable - toWithdraw),
                _maxGasForMatching
            ); // In underlying.

            if (matched > 0) {
                toWithdraw += matched;
                remainingToBorrow -= matched;
                deltas[_poolTokenAddress].p2pSupplyAmount += matched.div(
                    p2pSupplyIndex[_poolTokenAddress]
                );
            }
        }

        if (toWithdraw > 0) {
            uint256 toAddInP2P = toWithdraw.div(p2pBorrowIndex[_poolTokenAddress]); // In peer-to-peer unit.

            deltas[_poolTokenAddress].p2pBorrowAmount += toAddInP2P;
            borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P += toAddInP2P;
            emit P2PAmountsUpdated(_poolTokenAddress, delta.p2pSupplyAmount, delta.p2pBorrowAmount);

            // If this value is equal to 0 the withdraw will revert on Compound.
            if (toWithdraw.div(poolSupplyIndex) > 0)
                _withdrawFromPool(_poolTokenAddress, toWithdraw); // Reverts on error.
        }

        /// Borrow on pool ///

        if (remainingToBorrow > 0) {
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool += remainingToBorrow.div(
                ICToken(_poolTokenAddress).borrowIndex()
            ); // In cdUnit.
            _borrowFromPool(_poolTokenAddress, remainingToBorrow);
        }

        _updateBorrowerInDS(_poolTokenAddress, msg.sender);
        underlyingToken.safeTransfer(msg.sender, _amount);

        emit Borrowed(
            msg.sender,
            _poolTokenAddress,
            _amount,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P
        );
    }

    /// @dev Implements withdraw logic with security checks.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _supplier The address of the supplier.
    /// @param _receiver The address of the user who will receive the tokens.
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function withdrawLogic(
        address _poolTokenAddress,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasForMatching
    ) external {
        if (_amount == 0) revert AmountIsZero();
        if (!userMembership[_poolTokenAddress][_supplier]) revert UserNotMemberOfMarket();

        _updateP2PIndexes(_poolTokenAddress);
        uint256 toWithdraw = Math.min(
            _getUserSupplyBalanceInOf(_poolTokenAddress, _supplier),
            _amount
        );

        if (_isLiquidatable(_supplier, _poolTokenAddress, toWithdraw, 0))
            revert UnauthorisedWithdraw();

        _safeWithdrawLogic(_poolTokenAddress, toWithdraw, _supplier, _receiver, _maxGasForMatching);
    }

    /// @dev Implements repay logic with security checks.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _repayer The address of the account repaying the debt.
    /// @param _onBehalf The address of the account whose debt is repaid.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function repayLogic(
        address _poolTokenAddress,
        address _repayer,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external {
        if (_amount == 0) revert AmountIsZero();
        if (!userMembership[_poolTokenAddress][_onBehalf]) revert UserNotMemberOfMarket();

        _updateP2PIndexes(_poolTokenAddress);
        uint256 toRepay = Math.min(
            _getUserBorrowBalanceInOf(_poolTokenAddress, _onBehalf),
            _amount
        );

        _safeRepayLogic(_poolTokenAddress, _repayer, _onBehalf, toRepay, _maxGasForMatching);
    }

    /// @notice Liquidates a position.
    /// @param _poolTokenBorrowedAddress The address of the pool token the liquidator wants to repay.
    /// @param _poolTokenCollateralAddress The address of the collateral pool token the liquidator wants to seize.
    /// @param _borrower The address of the borrower to liquidate.
    /// @param _amount The amount of token (in underlying) to repay.
    function liquidateLogic(
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external {
        if (
            !userMembership[_poolTokenBorrowedAddress][_borrower] ||
            !userMembership[_poolTokenCollateralAddress][_borrower]
        ) revert UserNotMemberOfMarket();

        _updateP2PIndexes(_poolTokenBorrowedAddress);
        _updateP2PIndexes(_poolTokenCollateralAddress);

        if (!_isLiquidatable(_borrower, address(0), 0, 0)) revert UnauthorisedLiquidate();

        LiquidateVars memory vars;
        vars.borrowBalance = _getUserBorrowBalanceInOf(_poolTokenBorrowedAddress, _borrower);

        if (_amount > vars.borrowBalance.mul(comptroller.closeFactorMantissa()))
            revert AmountAboveWhatAllowedToRepay(); // Same mechanism as Compound. Liquidator cannot repay more than part of the debt (cf close factor on Compound).

        _safeRepayLogic(_poolTokenBorrowedAddress, msg.sender, _borrower, _amount, 0);

        ICompoundOracle compoundOracle = ICompoundOracle(comptroller.oracle());
        vars.collateralPrice = compoundOracle.getUnderlyingPrice(_poolTokenCollateralAddress);
        vars.borrowedPrice = compoundOracle.getUnderlyingPrice(_poolTokenBorrowedAddress);
        if (vars.collateralPrice == 0 || vars.borrowedPrice == 0) revert CompoundOracleFailed();

        // Compute the amount of collateral tokens to seize. This is the minimum between the repaid value plus the liquidation incentive and the available supply.
        vars.amountToSeize = Math.min(
            _amount.mul(comptroller.liquidationIncentiveMantissa()).mul(vars.borrowedPrice).div(
                vars.collateralPrice
            ),
            _getUserSupplyBalanceInOf(_poolTokenCollateralAddress, _borrower)
        );

        _safeWithdrawLogic(
            _poolTokenCollateralAddress,
            vars.amountToSeize,
            _borrower,
            msg.sender,
            0
        );

        emit Liquidated(
            msg.sender,
            _borrower,
            _poolTokenBorrowedAddress,
            _amount,
            _poolTokenCollateralAddress,
            vars.amountToSeize
        );
    }

    /// INTERNAL ///

    /// @dev Implements withdraw logic without security checks.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _supplier The address of the supplier.
    /// @param _receiver The address of the user who will receive the tokens.
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function _safeWithdrawLogic(
        address _poolTokenAddress,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasForMatching
    ) internal {
        if (_amount == 0) revert AmountIsZero();

        WithdrawVars memory vars;
        vars.poolToken = ICToken(_poolTokenAddress);
        vars.underlyingToken = _getUnderlying(_poolTokenAddress);
        vars.remainingToWithdraw = _amount;
        vars.maxGasForMatching = _maxGasForMatching;
        vars.withdrawable = vars.poolToken.balanceOfUnderlying(address(this));
        vars.poolSupplyIndex = vars.poolToken.exchangeRateStored(); // Exchange rate has already been updated.

        if (_amount.div(vars.poolSupplyIndex) == 0) revert WithdrawTooSmall();

        /// Soft withdraw ///

        uint256 onPoolSupply = supplyBalanceInOf[_poolTokenAddress][_supplier].onPool;
        if (onPoolSupply > 0) {
            uint256 maxToWithdrawOnPool = onPoolSupply.mul(vars.poolSupplyIndex);

            if (
                maxToWithdrawOnPool > vars.remainingToWithdraw ||
                maxToWithdrawOnPool > vars.withdrawable
            ) {
                vars.toWithdraw = CompoundMath.min(vars.remainingToWithdraw, vars.withdrawable);

                vars.remainingToWithdraw -= vars.toWithdraw;
                supplyBalanceInOf[_poolTokenAddress][_supplier].onPool -= vars.toWithdraw.div(
                    vars.poolSupplyIndex
                );
            } else {
                vars.toWithdraw = maxToWithdrawOnPool;
                vars.remainingToWithdraw -= maxToWithdrawOnPool;
                supplyBalanceInOf[_poolTokenAddress][_supplier].onPool = 0;
            }

            _updateSupplierInDS(_poolTokenAddress, _supplier);

            if (vars.remainingToWithdraw == 0) {
                _leaveMarketIfNeeded(_poolTokenAddress, _supplier);

                // If this value is equal to 0 the withdraw will revert on Compound.
                if (vars.toWithdraw.div(vars.poolSupplyIndex) > 0)
                    _withdrawFromPool(_poolTokenAddress, vars.toWithdraw); // Reverts on error.
                vars.underlyingToken.safeTransfer(_receiver, _amount);

                emit Withdrawn(
                    _supplier,
                    _receiver,
                    _poolTokenAddress,
                    _amount,
                    supplyBalanceInOf[_poolTokenAddress][_supplier].onPool,
                    supplyBalanceInOf[_poolTokenAddress][_supplier].inP2P
                );

                return;
            }
        }

        Types.Delta storage delta = deltas[_poolTokenAddress];
        vars.p2pSupplyIndex = p2pSupplyIndex[_poolTokenAddress];

        supplyBalanceInOf[_poolTokenAddress][_supplier].inP2P -= CompoundMath.min(
            supplyBalanceInOf[_poolTokenAddress][_supplier].inP2P,
            vars.remainingToWithdraw.div(vars.p2pSupplyIndex)
        ); // In peer-to-peer unit
        _updateSupplierInDS(_poolTokenAddress, _supplier);

        /// Transfer withdraw ///

        // Reduce peer-to-peer supply delta first if any.
        if (vars.remainingToWithdraw > 0 && delta.p2pSupplyDelta > 0) {
            uint256 deltaInUnderlying = delta.p2pSupplyDelta.mul(vars.poolSupplyIndex);

            if (
                deltaInUnderlying > vars.remainingToWithdraw ||
                deltaInUnderlying > vars.withdrawable - vars.toWithdraw
            ) {
                uint256 matchedDelta = CompoundMath.min(
                    vars.remainingToWithdraw,
                    vars.withdrawable - vars.toWithdraw
                );

                delta.p2pSupplyDelta -= matchedDelta.div(vars.poolSupplyIndex);
                delta.p2pSupplyAmount -= matchedDelta.div(vars.p2pSupplyIndex);
                vars.toWithdraw += matchedDelta;
                vars.remainingToWithdraw -= matchedDelta;
            } else {
                vars.toWithdraw += deltaInUnderlying;
                vars.remainingToWithdraw -= deltaInUnderlying;
                delta.p2pSupplyDelta = 0;
                delta.p2pSupplyAmount -= deltaInUnderlying.div(vars.p2pSupplyIndex);
            }

            emit P2PSupplyDeltaUpdated(_poolTokenAddress, delta.p2pSupplyDelta);
            emit P2PAmountsUpdated(_poolTokenAddress, delta.p2pSupplyAmount, delta.p2pBorrowAmount);
        }

        // Match pool suppliers if any.
        if (
            vars.remainingToWithdraw > 0 &&
            !p2pDisabled[_poolTokenAddress] &&
            suppliersOnPool[_poolTokenAddress].getHead() != address(0)
        ) {
            (uint256 matched, uint256 gasConsumedInMatching) = _matchSuppliers(
                _poolTokenAddress,
                CompoundMath.min(vars.remainingToWithdraw, vars.withdrawable - vars.toWithdraw),
                vars.maxGasForMatching
            );
            if (vars.maxGasForMatching <= gasConsumedInMatching) vars.maxGasForMatching = 0;
            else vars.maxGasForMatching -= gasConsumedInMatching;

            if (matched > 0) {
                vars.remainingToWithdraw -= matched;
                vars.toWithdraw += matched;
            }
        }

        // If this value is equal to 0 the withdraw will revert on Compound.
        if (vars.toWithdraw.div(vars.poolSupplyIndex) > 0)
            _withdrawFromPool(_poolTokenAddress, vars.toWithdraw); // Reverts on error.

        /// Hard withdraw ///

        // Unmatch peer-to-peer borrowers.
        if (vars.remainingToWithdraw > 0) {
            uint256 unmatched = _unmatchBorrowers(
                _poolTokenAddress,
                vars.remainingToWithdraw,
                _maxGasForMatching
            );

            // If unmatched does not cover remainingToWithdraw, the difference is added to the borrow peer-to-peer delta.
            if (unmatched < vars.remainingToWithdraw) {
                delta.p2pBorrowDelta += (vars.remainingToWithdraw - unmatched).div(
                    vars.poolToken.borrowIndex()
                );
                emit P2PBorrowDeltaUpdated(_poolTokenAddress, delta.p2pBorrowAmount);
            }

            delta.p2pSupplyAmount -= vars.remainingToWithdraw.div(vars.p2pSupplyIndex);
            delta.p2pBorrowAmount -= unmatched.div(p2pBorrowIndex[_poolTokenAddress]);
            emit P2PAmountsUpdated(_poolTokenAddress, delta.p2pSupplyAmount, delta.p2pBorrowAmount);

            _borrowFromPool(_poolTokenAddress, vars.remainingToWithdraw); // Reverts on error.
        }

        _leaveMarketIfNeeded(_poolTokenAddress, _supplier);
        vars.underlyingToken.safeTransfer(_receiver, _amount);

        emit Withdrawn(
            _supplier,
            _receiver,
            _poolTokenAddress,
            _amount,
            supplyBalanceInOf[_poolTokenAddress][_supplier].onPool,
            supplyBalanceInOf[_poolTokenAddress][_supplier].inP2P
        );
    }

    /// @dev Implements repay logic without security checks.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _repayer The address of the account repaying the debt.
    /// @param _onBehalf The address of the account whose debt is repaid.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    function _safeRepayLogic(
        address _poolTokenAddress,
        address _repayer,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal {
        ERC20 underlyingToken = _getUnderlying(_poolTokenAddress);
        underlyingToken.safeTransferFrom(_repayer, address(this), _amount);

        RepayVars memory vars;
        vars.remainingToRepay = _amount;
        vars.maxGasForMatching = _maxGasForMatching;
        vars.poolBorrowIndex = ICToken(_poolTokenAddress).borrowIndex();

        /// Soft repay ///

        vars.borrowedOnPool = borrowBalanceInOf[_poolTokenAddress][_onBehalf].onPool;
        if (vars.borrowedOnPool > 0) {
            vars.maxToRepayOnPool = vars.borrowedOnPool.mul(vars.poolBorrowIndex);

            if (vars.maxToRepayOnPool > vars.remainingToRepay) {
                vars.toRepay = vars.remainingToRepay;

                borrowBalanceInOf[_poolTokenAddress][_onBehalf].onPool -= CompoundMath.min(
                    vars.borrowedOnPool,
                    vars.toRepay.div(vars.poolBorrowIndex)
                ); // In cdUnit.
                _updateBorrowerInDS(_poolTokenAddress, _onBehalf);

                _repayToPool(_poolTokenAddress, underlyingToken, vars.toRepay); // Reverts on error.
                _leaveMarketIfNeeded(_poolTokenAddress, _onBehalf);

                emit Repaid(
                    _repayer,
                    _onBehalf,
                    _poolTokenAddress,
                    _amount,
                    borrowBalanceInOf[_poolTokenAddress][_onBehalf].onPool,
                    borrowBalanceInOf[_poolTokenAddress][_onBehalf].inP2P
                );

                return;
            } else {
                vars.toRepay = vars.maxToRepayOnPool;
                vars.remainingToRepay -= vars.toRepay;

                borrowBalanceInOf[_poolTokenAddress][_onBehalf].onPool = 0;
                _updateBorrowerInDS(_poolTokenAddress, _onBehalf);
            }
        }

        Types.Delta storage delta = deltas[_poolTokenAddress];
        vars.p2pSupplyIndex = p2pSupplyIndex[_poolTokenAddress];
        vars.p2pBorrowIndex = p2pBorrowIndex[_poolTokenAddress];

        borrowBalanceInOf[_poolTokenAddress][_onBehalf].inP2P -= CompoundMath.min(
            borrowBalanceInOf[_poolTokenAddress][_onBehalf].inP2P,
            vars.remainingToRepay.div(vars.p2pBorrowIndex)
        ); // In peer-to-peer unit.
        _updateBorrowerInDS(_poolTokenAddress, _onBehalf);

        /// Transfer repay ///

        // Reduce peer-to-peer borrow delta first if any.
        if (vars.remainingToRepay > 0 && delta.p2pBorrowDelta > 0) {
            uint256 deltaInUnderlying = delta.p2pBorrowDelta.mul(vars.poolBorrowIndex);
            if (deltaInUnderlying > vars.remainingToRepay) {
                delta.p2pBorrowDelta -= vars.remainingToRepay.div(vars.poolBorrowIndex);
                delta.p2pBorrowAmount -= vars.remainingToRepay.div(vars.p2pBorrowIndex);
                vars.toRepay += vars.remainingToRepay;
                vars.remainingToRepay = 0;
            } else {
                delta.p2pBorrowDelta = 0;
                delta.p2pBorrowAmount -= deltaInUnderlying.div(vars.p2pBorrowIndex);
                vars.toRepay += deltaInUnderlying;
                vars.remainingToRepay -= deltaInUnderlying;
            }

            emit P2PBorrowDeltaUpdated(_poolTokenAddress, delta.p2pBorrowDelta);
            emit P2PAmountsUpdated(_poolTokenAddress, delta.p2pSupplyAmount, delta.p2pBorrowAmount);
        }

        // Repay the fee.
        if (vars.remainingToRepay > 0) {
            // Fee = (p2pBorrowAmount - p2pBorrowDelta) - (p2pSupplyAmount - p2pSupplyDelta).
            vars.feeToRepay = CompoundMath.safeSub(
                (delta.p2pBorrowAmount.mul(vars.p2pBorrowIndex) -
                    delta.p2pBorrowDelta.mul(vars.poolBorrowIndex)),
                (delta.p2pSupplyAmount.mul(vars.p2pSupplyIndex) -
                    delta.p2pSupplyDelta.mul(ICToken(_poolTokenAddress).exchangeRateStored()))
            );

            if (vars.feeToRepay > 0) {
                uint256 feeRepaid = CompoundMath.min(vars.feeToRepay, vars.remainingToRepay);
                vars.remainingToRepay -= feeRepaid;
                delta.p2pBorrowAmount -= feeRepaid.div(vars.p2pBorrowIndex);
                emit P2PAmountsUpdated(
                    _poolTokenAddress,
                    delta.p2pSupplyAmount,
                    delta.p2pBorrowAmount
                );
            }
        }

        // Match pool borrowers if any.
        if (
            vars.remainingToRepay > 0 &&
            !p2pDisabled[_poolTokenAddress] &&
            borrowersOnPool[_poolTokenAddress].getHead() != address(0)
        ) {
            (uint256 matched, uint256 gasConsumedInMatching) = _matchBorrowers(
                _poolTokenAddress,
                vars.remainingToRepay,
                vars.maxGasForMatching
            );
            if (vars.maxGasForMatching <= gasConsumedInMatching) vars.maxGasForMatching = 0;
            else vars.maxGasForMatching -= gasConsumedInMatching;

            if (matched > 0) {
                vars.remainingToRepay -= matched;
                vars.toRepay += matched;
            }
        }

        _repayToPool(_poolTokenAddress, underlyingToken, vars.toRepay); // Reverts on error.

        /// Hard repay ///

        // Unmatch peer-to-peer suppliers.
        if (vars.remainingToRepay > 0) {
            uint256 unmatched = _unmatchSuppliers(
                _poolTokenAddress,
                vars.remainingToRepay,
                vars.maxGasForMatching
            );

            // If unmatched does not cover remainingToRepay, the difference is added to the supply peer-to-peer delta.
            if (unmatched < vars.remainingToRepay) {
                delta.p2pSupplyDelta += (vars.remainingToRepay - unmatched).div(
                    ICToken(_poolTokenAddress).exchangeRateStored() // Exchange rate has already been updated.
                );
                emit P2PSupplyDeltaUpdated(_poolTokenAddress, delta.p2pBorrowDelta);
            }

            delta.p2pSupplyAmount -= unmatched.div(vars.p2pSupplyIndex);
            delta.p2pBorrowAmount -= vars.remainingToRepay.div(vars.p2pBorrowIndex);
            emit P2PAmountsUpdated(_poolTokenAddress, delta.p2pSupplyAmount, delta.p2pBorrowAmount);

            _supplyToPool(_poolTokenAddress, underlyingToken, vars.remainingToRepay); // Reverts on error.
        }

        _leaveMarketIfNeeded(_poolTokenAddress, _onBehalf);

        emit Repaid(
            _repayer,
            _onBehalf,
            _poolTokenAddress,
            _amount,
            borrowBalanceInOf[_poolTokenAddress][_onBehalf].onPool,
            borrowBalanceInOf[_poolTokenAddress][_onBehalf].inP2P
        );
    }

    /// @dev Supplies underlying tokens to Compound.
    /// @param _poolTokenAddress The address of the pool token.
    /// @param _underlyingToken The underlying token of the market to supply to.
    /// @param _amount The amount of token (in underlying).
    function _supplyToPool(
        address _poolTokenAddress,
        ERC20 _underlyingToken,
        uint256 _amount
    ) internal {
        if (_poolTokenAddress == cEth) {
            IWETH(wEth).withdraw(_amount); // Turn wETH into ETH.
            ICEther(_poolTokenAddress).mint{value: _amount}();
        } else {
            _underlyingToken.safeApprove(_poolTokenAddress, _amount);
            if (ICToken(_poolTokenAddress).mint(_amount) != 0) revert MintOnCompoundFailed();
        }
    }

    /// @dev Withdraws underlying tokens from Compound.
    /// @param _poolTokenAddress The address of the pool token.
    /// @param _amount The amount of token (in underlying).
    function _withdrawFromPool(address _poolTokenAddress, uint256 _amount) internal {
        if (ICToken(_poolTokenAddress).redeemUnderlying(_amount) != 0)
            revert RedeemOnCompoundFailed();
        if (_poolTokenAddress == cEth) IWETH(address(wEth)).deposit{value: _amount}(); // Turn the ETH received in wETH.
    }

    /// @dev Borrows underlying tokens from Compound.
    /// @param _poolTokenAddress The address of the pool token.
    /// @param _amount The amount of token (in underlying).
    function _borrowFromPool(address _poolTokenAddress, uint256 _amount) internal {
        if ((ICToken(_poolTokenAddress).borrow(_amount) != 0)) revert BorrowOnCompoundFailed();
        if (_poolTokenAddress == cEth) IWETH(address(wEth)).deposit{value: _amount}(); // Turn the ETH received in wETH.
    }

    /// @dev Repays underlying tokens to Compound.
    /// @param _poolTokenAddress The address of the pool token.
    /// @param _underlyingToken The underlying token of the market to repay to.
    /// @param _amount The amount of token (in underlying).
    function _repayToPool(
        address _poolTokenAddress,
        ERC20 _underlyingToken,
        uint256 _amount
    ) internal {
        // Repay only what is necessary. The remaining tokens stays on the contracts and are claimable by the DAO.
        _amount = Math.min(
            _amount,
            ICToken(_poolTokenAddress).borrowBalanceCurrent(address(this)) // The debt of the contract.
        );

        if (_amount > 0) {
            if (_poolTokenAddress == cEth) {
                IWETH(wEth).withdraw(_amount); // Turn wETH into ETH.
                ICEther(_poolTokenAddress).repayBorrow{value: _amount}();
            } else {
                _underlyingToken.safeApprove(_poolTokenAddress, _amount);
                if (ICToken(_poolTokenAddress).repayBorrow(_amount) != 0)
                    revert RepayOnCompoundFailed();
            }
        }
    }

    /// @dev Enters the user into the market if not already there.
    /// @param _user The address of the user to update.
    /// @param _poolTokenAddress The address of the market to check.
    function _enterMarketIfNeeded(address _poolTokenAddress, address _user) internal {
        if (!userMembership[_poolTokenAddress][_user]) {
            userMembership[_poolTokenAddress][_user] = true;
            enteredMarkets[_user].push(_poolTokenAddress);
        }
    }

    /// @dev Removes the user from the market if its balances are null.
    /// @param _user The address of the user to update.
    /// @param _poolTokenAddress The address of the market to check.
    function _leaveMarketIfNeeded(address _poolTokenAddress, address _user) internal {
        if (
            userMembership[_poolTokenAddress][_user] &&
            supplyBalanceInOf[_poolTokenAddress][_user].inP2P == 0 &&
            supplyBalanceInOf[_poolTokenAddress][_user].onPool == 0 &&
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P == 0 &&
            borrowBalanceInOf[_poolTokenAddress][_user].onPool == 0
        ) {
            uint256 index;
            while (enteredMarkets[_user][index] != _poolTokenAddress) {
                unchecked {
                    ++index;
                }
            }
            userMembership[_poolTokenAddress][_user] = false;

            uint256 length = enteredMarkets[_user].length;
            if (index != length - 1)
                enteredMarkets[_user][index] = enteredMarkets[_user][length - 1];
            enteredMarkets[_user].pop();
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./MorphoUtils.sol";

/// @title MatchingEngine.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Smart contract managing the matching engine.
contract MatchingEngine is MorphoUtils {
    using DoubleLinkedList for DoubleLinkedList.List;
    using CompoundMath for uint256;

    /// STRUCTS ///

    // Struct to avoid stack too deep.
    struct UnmatchVars {
        uint256 p2pIndex;
        uint256 toUnmatch;
        uint256 poolIndex;
        uint256 inUnderlying;
        uint256 gasLeftAtTheBeginning;
    }

    // Struct to avoid stack too deep.
    struct MatchVars {
        uint256 p2pIndex;
        uint256 toMatch;
        uint256 poolIndex;
        uint256 inUnderlying;
        uint256 gasLeftAtTheBeginning;
    }

    /// @notice Emitted when the position of a supplier is updated.
    /// @param _user The address of the supplier.
    /// @param _poolTokenAddress The address of the market.
    /// @param _balanceOnPool The supply balance on pool after update.
    /// @param _balanceInP2P The supply balance in peer-to-peer after update.
    event SupplierPositionUpdated(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when the position of a borrower is updated.
    /// @param _user The address of the borrower.
    /// @param _poolTokenAddress The address of the market.
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in peer-to-peer after update.
    event BorrowerPositionUpdated(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// INTERNAL ///

    /// @notice Matches suppliers' liquidity waiting on Compound up to the given `_amount` and moves it to peer-to-peer.
    /// @dev Note: This function expects Compound's exchange rate and peer-to-peer indexes to have been updated.
    /// @param _poolTokenAddress The address of the market from which to match suppliers.
    /// @param _amount The token amount to search for (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return matched The amount of liquidity matched (in underlying).
    /// @return gasConsumedInMatching The amount of gas consumed within the matching loop.
    function _matchSuppliers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256 matched, uint256 gasConsumedInMatching) {
        if (_maxGasForMatching == 0) return (0, 0);

        MatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).exchangeRateStored(); // Exchange rate has already been updated.
        vars.p2pIndex = p2pSupplyIndex[_poolTokenAddress];
        address firstPoolSupplier;
        Types.SupplyBalance storage firstPoolSupplierBalance;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            matched < _amount &&
            (firstPoolSupplier = suppliersOnPool[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstPoolSupplierBalance = supplyBalanceInOf[_poolTokenAddress][firstPoolSupplier];
            vars.inUnderlying = firstPoolSupplierBalance.onPool.mul(vars.poolIndex);

            uint256 newPoolBorrowBalance;
            uint256 newP2PBorrowBalance;
            uint256 maxToMatch = _amount - matched;

            if (vars.inUnderlying <= maxToMatch) {
                // newPoolBorrowBalance is 0.
                newP2PBorrowBalance =
                    firstPoolSupplierBalance.inP2P +
                    vars.inUnderlying.div(vars.p2pIndex);
                matched += vars.inUnderlying;
            } else {
                newPoolBorrowBalance =
                    firstPoolSupplierBalance.onPool -
                    maxToMatch.div(vars.poolIndex);
                newP2PBorrowBalance =
                    firstPoolSupplierBalance.inP2P +
                    maxToMatch.div(vars.p2pIndex);
                matched = _amount;
            }

            firstPoolSupplierBalance.onPool = newPoolBorrowBalance;
            firstPoolSupplierBalance.inP2P = newP2PBorrowBalance;
            _updateSupplierInDS(_poolTokenAddress, firstPoolSupplier);

            emit SupplierPositionUpdated(
                firstPoolSupplier,
                _poolTokenAddress,
                newPoolBorrowBalance,
                newP2PBorrowBalance
            );
        }

        gasConsumedInMatching = vars.gasLeftAtTheBeginning - gasleft();
    }

    /// @notice Unmatches suppliers' liquidity in peer-to-peer up to the given `_amount` and moves it to Compound.
    /// @dev Note: This function expects Compound's exchange rate and peer-to-peer indexes to have been updated.
    /// @param _poolTokenAddress The address of the market from which to unmatch suppliers.
    /// @param _amount The amount to search for (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return The amount unmatched (in underlying).
    function _unmatchSuppliers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256) {
        if (_maxGasForMatching == 0) return 0;

        UnmatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).exchangeRateStored(); // Exchange rate has already been updated.
        vars.p2pIndex = p2pSupplyIndex[_poolTokenAddress];
        address firstP2PSupplier;
        Types.SupplyBalance storage firstP2PSupplierBalance;
        uint256 remainingToUnmatch = _amount;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            remainingToUnmatch > 0 &&
            (firstP2PSupplier = suppliersInP2P[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstP2PSupplierBalance = supplyBalanceInOf[_poolTokenAddress][firstP2PSupplier];
            vars.inUnderlying = firstP2PSupplierBalance.inP2P.mul(vars.p2pIndex);

            uint256 newPoolBorrowBalance;
            uint256 newP2PBorrowBalance;

            if (vars.inUnderlying <= remainingToUnmatch) {
                // newP2PBorrowBalance is 0.
                newPoolBorrowBalance =
                    firstP2PSupplierBalance.onPool +
                    vars.inUnderlying.div(vars.poolIndex);
                remainingToUnmatch -= vars.inUnderlying;
            } else {
                newPoolBorrowBalance =
                    firstP2PSupplierBalance.onPool +
                    remainingToUnmatch.div(vars.poolIndex);
                newP2PBorrowBalance =
                    firstP2PSupplierBalance.inP2P -
                    remainingToUnmatch.div(vars.p2pIndex);
                remainingToUnmatch = 0;
            }

            firstP2PSupplierBalance.onPool = newPoolBorrowBalance;
            firstP2PSupplierBalance.inP2P = newP2PBorrowBalance;
            _updateSupplierInDS(_poolTokenAddress, firstP2PSupplier);

            emit SupplierPositionUpdated(
                firstP2PSupplier,
                _poolTokenAddress,
                newPoolBorrowBalance,
                newP2PBorrowBalance
            );
        }

        return _amount - remainingToUnmatch;
    }

    /// @notice Matches borrowers' liquidity waiting on Compound up to the given `_amount` and moves it to peer-to-peer.
    /// @dev Note: This function expects peer-to-peer indexes to have been updated..
    /// @param _poolTokenAddress The address of the market from which to match borrowers.
    /// @param _amount The amount to search for (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return matched The amount of liquidity matched (in underlying).
    /// @return gasConsumedInMatching The amount of gas consumed within the matching loop.
    function _matchBorrowers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256 matched, uint256 gasConsumedInMatching) {
        if (_maxGasForMatching == 0) return (0, 0);

        MatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).borrowIndex();
        vars.p2pIndex = p2pBorrowIndex[_poolTokenAddress];
        address firstPoolBorrower;
        Types.BorrowBalance storage firstPoolBorrowerBalance;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            matched < _amount &&
            (firstPoolBorrower = borrowersOnPool[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstPoolBorrowerBalance = borrowBalanceInOf[_poolTokenAddress][firstPoolBorrower];
            vars.inUnderlying = firstPoolBorrowerBalance.onPool.mul(vars.poolIndex);

            uint256 newPoolBorrowBalance;
            uint256 newP2PBorrowBalance;
            uint256 maxToMatch = _amount - matched;

            if (vars.inUnderlying <= maxToMatch) {
                // newPoolBorrowBalance is 0.
                newP2PBorrowBalance =
                    firstPoolBorrowerBalance.inP2P +
                    vars.inUnderlying.div(vars.p2pIndex);
                matched += vars.inUnderlying;
            } else {
                newPoolBorrowBalance =
                    firstPoolBorrowerBalance.onPool -
                    maxToMatch.div(vars.poolIndex);
                newP2PBorrowBalance =
                    firstPoolBorrowerBalance.inP2P +
                    maxToMatch.div(vars.p2pIndex);
                matched = _amount;
            }

            firstPoolBorrowerBalance.onPool = newPoolBorrowBalance;
            firstPoolBorrowerBalance.inP2P = newP2PBorrowBalance;
            _updateBorrowerInDS(_poolTokenAddress, firstPoolBorrower);

            emit BorrowerPositionUpdated(
                firstPoolBorrower,
                _poolTokenAddress,
                newPoolBorrowBalance,
                newP2PBorrowBalance
            );
        }

        gasConsumedInMatching = vars.gasLeftAtTheBeginning - gasleft();
    }

    /// @notice Unmatches borrowers' liquidity in peer-to-peer for the given `_amount` and moves it to Compound.
    /// @dev Note: This function expects and peer-to-peer indexes to have been updated.
    /// @param _poolTokenAddress The address of the market from which to unmatch borrowers.
    /// @param _amount The amount to unmatch (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return The amount unmatched (in underlying).
    function _unmatchBorrowers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256) {
        if (_maxGasForMatching == 0) return 0;

        UnmatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).borrowIndex();
        vars.p2pIndex = p2pBorrowIndex[_poolTokenAddress];
        address firstP2PBorrower;
        Types.BorrowBalance storage firstP2PBorrowerBalance;
        uint256 remainingToUnmatch = _amount;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            remainingToUnmatch > 0 &&
            (firstP2PBorrower = borrowersInP2P[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstP2PBorrowerBalance = borrowBalanceInOf[_poolTokenAddress][firstP2PBorrower];
            vars.inUnderlying = firstP2PBorrowerBalance.inP2P.mul(vars.p2pIndex);

            uint256 newPoolBorrowBalance;
            uint256 newP2PBorrowBalance;

            if (vars.inUnderlying <= remainingToUnmatch) {
                // newP2PBorrowBalance is 0.
                newPoolBorrowBalance =
                    firstP2PBorrowerBalance.onPool +
                    vars.inUnderlying.div(vars.poolIndex);
                remainingToUnmatch -= vars.inUnderlying;
            } else {
                newPoolBorrowBalance =
                    firstP2PBorrowerBalance.onPool +
                    remainingToUnmatch.div(vars.poolIndex);
                newP2PBorrowBalance =
                    firstP2PBorrowerBalance.inP2P -
                    remainingToUnmatch.div(vars.p2pIndex);
                remainingToUnmatch = 0;
            }

            firstP2PBorrowerBalance.onPool = newPoolBorrowBalance;
            firstP2PBorrowerBalance.inP2P = newP2PBorrowBalance;
            _updateBorrowerInDS(_poolTokenAddress, firstP2PBorrower);

            emit BorrowerPositionUpdated(
                firstP2PBorrower,
                _poolTokenAddress,
                newPoolBorrowBalance,
                newP2PBorrowBalance
            );
        }

        return _amount - remainingToUnmatch;
    }

    /// @notice Updates `_user` in the supplier data structures.
    /// @param _poolTokenAddress The address of the market on which to update the suppliers data structure.
    /// @param _user The address of the user.
    function _updateSupplierInDS(address _poolTokenAddress, address _user) internal {
        uint256 onPool = supplyBalanceInOf[_poolTokenAddress][_user].onPool;
        uint256 inP2P = supplyBalanceInOf[_poolTokenAddress][_user].inP2P;
        uint256 formerValueOnPool = suppliersOnPool[_poolTokenAddress].getValueOf(_user);
        uint256 formerValueInP2P = suppliersInP2P[_poolTokenAddress].getValueOf(_user);

        // Round pool balance to 0 if below threshold.
        if (onPool <= dustThreshold) {
            supplyBalanceInOf[_poolTokenAddress][_user].onPool = 0;
            onPool = 0;
        }
        if (formerValueOnPool != onPool) {
            if (formerValueOnPool > 0) suppliersOnPool[_poolTokenAddress].remove(_user);
            if (onPool > 0)
                suppliersOnPool[_poolTokenAddress].insertSorted(_user, onPool, maxSortedUsers);
        }

        // Round peer-to-peer balance to 0 if below threshold.
        if (inP2P <= dustThreshold) {
            supplyBalanceInOf[_poolTokenAddress][_user].inP2P = 0;
            inP2P = 0;
        }
        if (formerValueInP2P != inP2P) {
            if (formerValueInP2P > 0) suppliersInP2P[_poolTokenAddress].remove(_user);
            if (inP2P > 0)
                suppliersInP2P[_poolTokenAddress].insertSorted(_user, inP2P, maxSortedUsers);
        }

        if (address(rewardsManager) != address(0))
            rewardsManager.accrueUserSupplyUnclaimedRewards(
                _user,
                _poolTokenAddress,
                formerValueOnPool
            );
    }

    /// @notice Updates `_user` in the borrower data structures.
    /// @param _poolTokenAddress The address of the market on which to update the borrowers data structure.
    /// @param _user The address of the user.
    function _updateBorrowerInDS(address _poolTokenAddress, address _user) internal {
        uint256 onPool = borrowBalanceInOf[_poolTokenAddress][_user].onPool;
        uint256 inP2P = borrowBalanceInOf[_poolTokenAddress][_user].inP2P;
        uint256 formerValueOnPool = borrowersOnPool[_poolTokenAddress].getValueOf(_user);
        uint256 formerValueInP2P = borrowersInP2P[_poolTokenAddress].getValueOf(_user);

        // Round pool balance to 0 if below threshold.
        if (onPool <= dustThreshold) {
            borrowBalanceInOf[_poolTokenAddress][_user].onPool = 0;
            onPool = 0;
        }
        if (formerValueOnPool != onPool) {
            if (formerValueOnPool > 0) borrowersOnPool[_poolTokenAddress].remove(_user);
            if (onPool > 0)
                borrowersOnPool[_poolTokenAddress].insertSorted(_user, onPool, maxSortedUsers);
        }

        // Round peer-to-peer balance to 0 if below threshold.
        if (inP2P <= dustThreshold) {
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P = 0;
            inP2P = 0;
        }
        if (formerValueInP2P != inP2P) {
            if (formerValueInP2P > 0) borrowersInP2P[_poolTokenAddress].remove(_user);
            if (inP2P > 0)
                borrowersInP2P[_poolTokenAddress].insertSorted(_user, inP2P, maxSortedUsers);
        }

        if (address(rewardsManager) != address(0))
            rewardsManager.accrueUserBorrowUnclaimedRewards(
                _user,
                _poolTokenAddress,
                formerValueOnPool
            );
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/IInterestRatesManager.sol";

import "./libraries/CompoundMath.sol";

import "./MorphoStorage.sol";

/// @title InterestRatesManager.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Smart contract handling the computation of indexes used for peer-to-peer interactions.
/// @dev This contract inherits from MorphoStorage so that Morpho can delegate calls to this contract.
contract InterestRatesManager is IInterestRatesManager, MorphoStorage {
    using CompoundMath for uint256;

    /// STRUCTS ///

    struct Params {
        uint256 lastP2PSupplyIndex; // The peer-to-peer supply index at last update.
        uint256 lastP2PBorrowIndex; // The peer-to-peer borrow index at last update.
        uint256 poolSupplyIndex; // The current pool supply index.
        uint256 poolBorrowIndex; // The current pool borrow index.
        uint256 lastPoolSupplyIndex; // The pool supply index at last update.
        uint256 lastPoolBorrowIndex; // The pool borrow index at last update.
        uint256 reserveFactor; // The reserve factor percentage (10 000 = 100%).
        uint256 p2pIndexCursor; // The peer-to-peer index cursor (10 000 = 100%).
        Types.Delta delta; // The deltas and peer-to-peer amounts.
    }

    /// EVENTS ///

    /// @notice Emitted when the peer-to-peer indexes of a market are updated.
    /// @param _poolTokenAddress The address of the market updated.
    /// @param _p2pSupplyIndex The updated supply index from peer-to-peer unit to underlying.
    /// @param _p2pBorrowIndex The updated borrow index from peer-to-peer unit to underlying.
    /// @param _poolSupplyIndex The updated pool supply index.
    /// @param _poolBorrowIndex The updated pool borrow index.
    event P2PIndexesUpdated(
        address indexed _poolTokenAddress,
        uint256 _p2pSupplyIndex,
        uint256 _p2pBorrowIndex,
        uint256 _poolSupplyIndex,
        uint256 _poolBorrowIndex
    );

    /// EXTERNAL ///

    /// @notice Updates the peer-to-peer indexes.
    /// @param _poolTokenAddress The address of the market to update.
    function updateP2PIndexes(address _poolTokenAddress) external {
        if (block.number > lastPoolIndexes[_poolTokenAddress].lastUpdateBlockNumber) {
            ICToken poolToken = ICToken(_poolTokenAddress);
            Types.LastPoolIndexes storage poolIndexes = lastPoolIndexes[_poolTokenAddress];
            Types.MarketParameters storage marketParams = marketParameters[_poolTokenAddress];

            uint256 poolSupplyIndex = poolToken.exchangeRateCurrent();
            uint256 poolBorrowIndex = poolToken.borrowIndex();

            Params memory params = Params(
                p2pSupplyIndex[_poolTokenAddress],
                p2pBorrowIndex[_poolTokenAddress],
                poolSupplyIndex,
                poolBorrowIndex,
                poolIndexes.lastSupplyPoolIndex,
                poolIndexes.lastBorrowPoolIndex,
                marketParams.reserveFactor,
                marketParams.p2pIndexCursor,
                deltas[_poolTokenAddress]
            );

            (uint256 newP2PSupplyIndex, uint256 newP2PBorrowIndex) = _computeP2PIndexes(params);

            p2pSupplyIndex[_poolTokenAddress] = newP2PSupplyIndex;
            p2pBorrowIndex[_poolTokenAddress] = newP2PBorrowIndex;

            poolIndexes.lastUpdateBlockNumber = uint32(block.number);
            poolIndexes.lastSupplyPoolIndex = uint112(poolSupplyIndex);
            poolIndexes.lastBorrowPoolIndex = uint112(poolBorrowIndex);

            emit P2PIndexesUpdated(
                _poolTokenAddress,
                newP2PSupplyIndex,
                newP2PBorrowIndex,
                poolSupplyIndex,
                poolBorrowIndex
            );
        }
    }

    /// INTERNAL ///

    /// @notice Computes and returns new peer-to-peer indexes.
    /// @param _params Computation parameters.
    /// @return newP2PSupplyIndex The updated p2pSupplyIndex.
    /// @return newP2PBorrowIndex The updated p2pBorrowIndex.
    function _computeP2PIndexes(Params memory _params)
        internal
        pure
        returns (uint256 newP2PSupplyIndex, uint256 newP2PBorrowIndex)
    {
        // Compute pool growth factors

        uint256 poolSupplyGrowthFactor = _params.poolSupplyIndex.div(_params.lastPoolSupplyIndex);
        uint256 poolBorrowGrowthFactor = _params.poolBorrowIndex.div(_params.lastPoolBorrowIndex);

        // Compute peer-to-peer growth factors

        uint256 p2pGrowthFactor = ((MAX_BASIS_POINTS - _params.p2pIndexCursor) *
            poolSupplyGrowthFactor +
            _params.p2pIndexCursor *
            poolBorrowGrowthFactor) / MAX_BASIS_POINTS;
        uint256 p2pSupplyGrowthFactor = p2pGrowthFactor -
            (_params.reserveFactor * (p2pGrowthFactor - poolSupplyGrowthFactor)) /
            MAX_BASIS_POINTS;
        uint256 p2pBorrowGrowthFactor = p2pGrowthFactor +
            (_params.reserveFactor * (poolBorrowGrowthFactor - p2pGrowthFactor)) /
            MAX_BASIS_POINTS;

        // Compute new peer-to-peer supply index

        if (_params.delta.p2pSupplyAmount == 0 || _params.delta.p2pSupplyDelta == 0) {
            newP2PSupplyIndex = _params.lastP2PSupplyIndex.mul(p2pSupplyGrowthFactor);
        } else {
            uint256 shareOfTheDelta = CompoundMath.min(
                (_params.delta.p2pSupplyDelta.mul(_params.lastPoolSupplyIndex)).div(
                    (_params.delta.p2pSupplyAmount).mul(_params.lastP2PSupplyIndex)
                ),
                WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PSupplyIndex = _params.lastP2PSupplyIndex.mul(
                (WAD - shareOfTheDelta).mul(p2pSupplyGrowthFactor) +
                    shareOfTheDelta.mul(poolSupplyGrowthFactor)
            );
        }

        // Compute new peer-to-peer borrow index

        if (_params.delta.p2pBorrowAmount == 0 || _params.delta.p2pBorrowDelta == 0) {
            newP2PBorrowIndex = _params.lastP2PBorrowIndex.mul(p2pBorrowGrowthFactor);
        } else {
            uint256 shareOfTheDelta = CompoundMath.min(
                (_params.delta.p2pBorrowDelta.mul(_params.poolBorrowIndex)).div(
                    (_params.delta.p2pBorrowAmount).mul(_params.lastP2PBorrowIndex)
                ),
                WAD // To avoid shareOfTheDelta > 1 with rounding errors.
            );

            newP2PBorrowIndex = _params.lastP2PBorrowIndex.mul(
                (WAD - shareOfTheDelta).mul(p2pBorrowGrowthFactor) +
                    shareOfTheDelta.mul(poolBorrowGrowthFactor)
            );
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./interfaces/ISwapManager.sol";

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./libraries/uniswap/PoolAddress.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

interface Weth9Provider {
    function WETH9() external view returns (address);
}

/// @title SwapManager for Uniswap V3.
/// @notice Smart contract managing the swap of reward tokens to Morpho tokens on Uniswap V3.
contract SwapManagerUniV3 is ISwapManager, Ownable {
    using SafeTransferLib for ERC20;
    using FullMath for uint256;

    /// STORAGE ///

    bool public immutable singlePath; // Wether a single or a multiple paths is used for the swap.
    uint32 public rewardTwapInterval; // The interval for the Time-Weighted Average Price for REWARD_TOKEN/WETH9 pool.
    uint32 public morphoTwapInterval; // The interval for the Time-Weighted Average Price for MORPHO/WETH9 pool.
    uint24 public immutable REWARD_POOL_FEE; // Fee on Uniswap for REWARD_TOKEN/WETH9 pool.
    uint24 public immutable MORPHO_POOL_FEE; // Fee on Uniswap for MORPHO/WETH9 pool.
    uint256 public constant ONE_PERCENT = 100; // 1% in basis points.
    uint256 public constant TWO_PERCENT = 200; // 2% in basis points.
    uint256 public constant MAX_BASIS_POINTS = 10_000; // 100% in basis points.

    address public immutable REWARD_TOKEN; // The reward token address.
    address public immutable MORPHO; // The Morpho token address.
    address public immutable WETH9; // Intermediate token address.

    // Hard coded addresses as they are the same across chains.
    address public constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // The address of the Uniswap V3 factory.
    ISwapRouter public constant SWAP_ROUTER =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // The Uniswap V3 router.

    IUniswapV3Pool public immutable pool0;
    IUniswapV3Pool public immutable pool1;

    /// EVENTS ///

    /// @notice Emitted when a swap to Morpho tokens happens.
    /// @param _receiver The address of the receiver.
    /// @param _amountIn The amount of reward token swapped.
    /// @param _amountOut The amount of Morpho token received.
    event Swapped(address indexed _receiver, uint256 _amountIn, uint256 _amountOut);

    /// @notice Emitted when TWAP intervals are set.
    /// @param _rewardTwapInterval The new `rewardTwapInterval`.
    /// @param _morphoTwapInterval The new `morphoTwapInterval`.
    event TwapIntervalsSet(uint32 _rewardTwapInterval, uint32 _morphoTwapInterval);

    /// ERRORS ///

    /// @notice Thrown when a TWAP interval is too short.
    error TwapTooShort();

    /// CONSTRUCTOR ///

    /// @notice Constructs the SwapManagerUniV3 contract.
    /// @param _morphoToken The Morpho token address.
    /// @param _morphoPoolFee The fee on Uniswap for REWARD_TOKEN/WETH9 pool.
    /// @param _rewardToken The reward token address.
    /// @param _rewardPoolFee The fee on Uniswap for MORPHO/WETH9 pool.
    /// @param _rewardTwapInterval The interval for the Time-Weighted Average Price for REWARD_TOKEN/WETH9 pool.
    /// @param _morphoTwapInterval The interval for the Time-Weighted Average Price MORPHO/WETH9 pool.
    constructor(
        address _morphoToken,
        uint24 _morphoPoolFee,
        address _rewardToken,
        uint24 _rewardPoolFee,
        uint32 _rewardTwapInterval,
        uint32 _morphoTwapInterval
    ) {
        if (_rewardTwapInterval < 5 minutes || _morphoTwapInterval < 5 minutes)
            revert TwapTooShort();

        MORPHO = _morphoToken;
        MORPHO_POOL_FEE = _morphoPoolFee;
        REWARD_TOKEN = _rewardToken;
        REWARD_POOL_FEE = _rewardPoolFee;
        WETH9 = Weth9Provider(address(SWAP_ROUTER)).WETH9();
        rewardTwapInterval = _rewardTwapInterval;
        morphoTwapInterval = _morphoTwapInterval;

        singlePath = _rewardToken == WETH9;
        pool0 = singlePath
            ? IUniswapV3Pool(address(0))
            : IUniswapV3Pool(
                PoolAddress.computeAddress(
                    FACTORY,
                    PoolAddress.getPoolKey(_rewardToken, WETH9, _rewardPoolFee)
                )
            );
        pool1 = IUniswapV3Pool(
            PoolAddress.computeAddress(
                FACTORY,
                PoolAddress.getPoolKey(WETH9, _morphoToken, _morphoPoolFee)
            )
        );
    }

    /// EXTERNAL ///

    /// @notice Sets TWAP intervals.
    /// @param _rewardTwapInterval The new `rewardTwapInterval`.
    /// @param _morphoTwapInterval The new `morphoTwapInterval`.
    function setTwapIntervals(uint32 _rewardTwapInterval, uint32 _morphoTwapInterval)
        external
        onlyOwner
    {
        if (_rewardTwapInterval < 5 minutes || _morphoTwapInterval < 5 minutes)
            revert TwapTooShort();
        rewardTwapInterval = _rewardTwapInterval;
        morphoTwapInterval = _morphoTwapInterval;
        emit TwapIntervalsSet(_rewardTwapInterval, _morphoTwapInterval);
    }

    /// @notice Swaps reward tokens to Morpho token.
    /// @param _amountIn The amount of reward token to swap.
    /// @param _receiver The address of the receiver of the Morpho tokens.
    /// @return amountOut The amount of Morpho tokens sent.
    function swapToMorphoToken(uint256 _amountIn, address _receiver)
        external
        override
        returns (uint256 amountOut)
    {
        uint256 expectedAmountOutMinimum;
        bytes memory path;

        if (singlePath) (expectedAmountOutMinimum, path) = _getSinglePathParams(_amountIn);
        else (expectedAmountOutMinimum, path) = _getMultiplePathParams(_amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: _receiver,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: expectedAmountOutMinimum
        });

        // Execute the swap
        ERC20(REWARD_TOKEN).safeApprove(address(SWAP_ROUTER), _amountIn);
        amountOut = SWAP_ROUTER.exactInput(params);

        emit Swapped(_receiver, _amountIn, amountOut);
    }

    /// INTERNAL ///

    /// @dev Returns the minimum expected amount of Morpho token to receive and the multiple path for a swap.
    /// @param _amountIn The amount of reward token to swap.
    /// @return expectedAmountOutMinimum The minimum amount of Morpho tokens to receive.
    /// @return path The path for the swap.
    function _getMultiplePathParams(uint256 _amountIn)
        internal
        view
        returns (uint256 expectedAmountOutMinimum, bytes memory path)
    {
        uint256 priceX960;
        uint256 priceX961;

        {
            uint32[] memory rewardSecondsAgo = new uint32[](2);
            rewardSecondsAgo[0] = rewardTwapInterval;
            rewardSecondsAgo[1] = 0;

            uint32[] memory morphoSecondsAgo = new uint32[](2);
            morphoSecondsAgo[0] = morphoTwapInterval;
            morphoSecondsAgo[1] = 0;

            (int56[] memory tickCumulatives0, ) = pool0.observe(rewardSecondsAgo);
            (int56[] memory tickCumulatives1, ) = pool1.observe(morphoSecondsAgo);

            // For the pair token0/token1 -> 1.0001 * readingTick = price = token1 / token0
            // So token1 = price * token0.

            // Ticks (imprecise as it's an integer) to price.
            uint160 sqrtPriceX960 = TickMath.getSqrtRatioAtTick(
                int24(
                    (tickCumulatives0[1] - tickCumulatives0[0]) / int24(uint24(rewardTwapInterval))
                )
            );
            uint160 sqrtPriceX961 = TickMath.getSqrtRatioAtTick(
                int24(
                    (tickCumulatives1[1] - tickCumulatives1[0]) / int24(uint24(morphoTwapInterval))
                )
            );

            priceX960 = _getPriceX96FromSqrtPriceX96(sqrtPriceX960);
            priceX961 = _getPriceX96FromSqrtPriceX96(sqrtPriceX961);
        }

        // Computation depends on the position of token in pools.
        if (REWARD_TOKEN == pool0.token0() && WETH9 == pool1.token0()) {
            expectedAmountOutMinimum = _amountIn.mulDiv(priceX960, FixedPoint96.Q96).mulDiv(
                priceX961,
                FixedPoint96.Q96
            );
        } else if (REWARD_TOKEN == pool0.token1() && WETH9 == pool1.token0()) {
            expectedAmountOutMinimum = _amountIn.mulDiv(FixedPoint96.Q96, priceX960).mulDiv(
                priceX961,
                FixedPoint96.Q96
            );
        } else if (REWARD_TOKEN == pool0.token0() && WETH9 == pool1.token1()) {
            expectedAmountOutMinimum = _amountIn.mulDiv(FixedPoint96.Q96, priceX961).mulDiv(
                priceX960,
                FixedPoint96.Q96
            );
        } else {
            expectedAmountOutMinimum = _amountIn.mulDiv(FixedPoint96.Q96, priceX960).mulDiv(
                FixedPoint96.Q96,
                priceX961
            );
        }

        // Max slippage of 2% for the trade.
        expectedAmountOutMinimum = expectedAmountOutMinimum.mulDiv(
            MAX_BASIS_POINTS - TWO_PERCENT,
            MAX_BASIS_POINTS
        );
        path = abi.encodePacked(REWARD_TOKEN, REWARD_POOL_FEE, WETH9, MORPHO_POOL_FEE, MORPHO);
    }

    function _getSinglePathParams(uint256 _amountIn)
        internal
        view
        returns (uint256 expectedAmountOutMinimum, bytes memory path)
    {
        uint32[] memory morphoSecondsAgo = new uint32[](2);
        morphoSecondsAgo[0] = morphoTwapInterval;
        morphoSecondsAgo[1] = 0;

        (int56[] memory tickCumulatives1, ) = pool1.observe(morphoSecondsAgo);

        // For the pair token0/token1 -> 1.0001 * readingTick = price = token1 / token0
        // So token1 = price * token0

        // Ticks (imprecise as it's an integer) to price.
        uint160 sqrtPriceX961 = TickMath.getSqrtRatioAtTick(
            int24((tickCumulatives1[1] - tickCumulatives1[0]) / int24(uint24(morphoTwapInterval)))
        );

        // Computation depends on the position of token in pool.
        if (pool1.token0() == REWARD_TOKEN) {
            expectedAmountOutMinimum = _amountIn.mulDiv(
                _getPriceX96FromSqrtPriceX96(sqrtPriceX961),
                FixedPoint96.Q96
            );
        } else {
            expectedAmountOutMinimum = _amountIn.mulDiv(
                FixedPoint96.Q96,
                _getPriceX96FromSqrtPriceX96(sqrtPriceX961)
            );
        }

        // Max slippage of 1% for the trade.
        expectedAmountOutMinimum =
            (expectedAmountOutMinimum * (MAX_BASIS_POINTS - ONE_PERCENT)) /
            MAX_BASIS_POINTS;
        path = abi.encodePacked(REWARD_TOKEN, MORPHO_POOL_FEE, MORPHO);
    }

    /// @dev Returns the price in fixed point 96 from the square of the price in fixed point 96.
    /// @param _sqrtPriceX96 The square of the price in fixed point 96.
    /// @return priceX96 The price in fixed point 96.
    function _getPriceX96FromSqrtPriceX96(uint160 _sqrtPriceX96)
        internal
        pure
        returns (uint256 priceX96)
    {
        return FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, FixedPoint96.Q96);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
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
        unchecked {
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
            uint256 twos = (0 - denominator) & denominator;
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return PoolKey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./interfaces/ISwapManager.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./libraries/uniswap/PoolAddress.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SwapManager for Uniswap V3 on ethereum mainnet.
/// @dev Smart contract managing the swap of reward tokens to Morpho tokens on Uniswap V3 on ethereum mainnet.
contract SwapManagerUniV3OnMainnet is ISwapManager, Ownable {
    using SafeERC20 for IERC20;
    using FullMath for uint256;

    /// STORAGE ///

    uint32 public aaveTwapInterval; // The interval for the Time-Weighted Average Price for AAVE/WETH9 pool.
    uint32 public morphoTwapInterval; // The interval for the Time-Weighted Average Price for MORPHO/WETH9 pool.
    uint24 public constant POOL_FEE = 3_000; // Fee on Uniswap for first pools.
    uint24 public immutable MORPHO_POOL_FEE; // Fee on Uniswap for WETH9/MORPHO pool.
    uint256 public constant THREE_PERCENT = 300; // 3% in basis points.
    uint256 public constant MAX_BASIS_POINTS = 10_000; // 100% in basis points.

    address public immutable MORPHO; // Morpho token address.
    address public constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // The address of the Uniswap V3 factory.
    address public constant stkAAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5; // The address of stkAAVE token.
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; // The address of AAVE token.
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // The address of WETH9 token.

    ISwapRouter public constant SWAP_ROUTER =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // The Uniswap V3 router.

    IUniswapV3Pool public immutable pool0;
    IUniswapV3Pool public immutable pool1;
    IUniswapV3Pool public immutable pool2;

    /// EVENTS ///

    /// @notice Emitted when a swap to Morpho tokens happens.
    /// @param _receiver The address of the receiver.
    /// @param _amountIn The amount of reward token swapped.
    /// @param _amountOut The amount of Morpho token received.
    event Swapped(address indexed _receiver, uint256 _amountIn, uint256 _amountOut);

    /// @notice Emitted when TWAP intervals are set.
    /// @param _aaveTwapInterval The new `aaveTwapInterval`.
    /// @param _morphoTwapInterval The new `morphoTwapInterval`.
    event TwapIntervalsSet(uint32 _aaveTwapInterval, uint32 _morphoTwapInterval);

    /// ERRORS ///

    /// @notice Thrown when a TWAP interval is too short.
    error TwapTooShort();

    /// CONSTRUCTOR ///

    /// @notice Constructs the SwapManagerUniV3 contract.
    /// @param _morphoToken The Morpho token address.
    /// @param _morphoPoolFee The reward token address.
    /// @param _aaveTwapInterval The interval for the Time-Weighted Average Price for AAVE/WETH9 pool.
    /// @param _morphoTwapInterval The interval for the Time-Weighted Average Price MORPHO/WETH9 pool.
    constructor(
        address _morphoToken,
        uint24 _morphoPoolFee,
        uint32 _aaveTwapInterval,
        uint32 _morphoTwapInterval
    ) {
        if (_aaveTwapInterval < 5 minutes || _morphoTwapInterval < 5 minutes) revert TwapTooShort();

        MORPHO = _morphoToken;
        MORPHO_POOL_FEE = _morphoPoolFee;
        aaveTwapInterval = _aaveTwapInterval;
        morphoTwapInterval = _morphoTwapInterval;

        pool0 = IUniswapV3Pool(
            PoolAddress.computeAddress(FACTORY, PoolAddress.getPoolKey(stkAAVE, AAVE, POOL_FEE))
        );
        pool1 = IUniswapV3Pool(
            PoolAddress.computeAddress(FACTORY, PoolAddress.getPoolKey(AAVE, WETH9, POOL_FEE))
        );
        pool2 = IUniswapV3Pool(
            PoolAddress.computeAddress(
                FACTORY,
                PoolAddress.getPoolKey(WETH9, _morphoToken, _morphoPoolFee)
            )
        );
    }

    /// EXTERNAL ///

    /// @notice Sets TWAP intervals.
    /// @param _aaveTwapInterval The new `aaveTwapInterval`.
    /// @param _morphoTwapInterval The new `morphoTwapInterval`.
    function setTwapIntervals(uint32 _aaveTwapInterval, uint32 _morphoTwapInterval)
        external
        onlyOwner
    {
        if (_aaveTwapInterval < 5 minutes || _morphoTwapInterval < 5 minutes) revert TwapTooShort();

        aaveTwapInterval = _aaveTwapInterval;
        morphoTwapInterval = _morphoTwapInterval;

        emit TwapIntervalsSet(_aaveTwapInterval, _morphoTwapInterval);
    }

    /// @notice Swaps reward tokens to Morpho token.
    /// @param _amountIn The amount of reward token to swap.
    /// @param _receiver The address of the receiver of the Morpho tokens.
    /// @return amountOut The amount of Morpho tokens sent.
    function swapToMorphoToken(uint256 _amountIn, address _receiver)
        external
        override
        returns (uint256 amountOut)
    {
        uint256 expectedAmountOutMinimum;
        bytes memory path;

        (expectedAmountOutMinimum, path) = _getMultiplePathParams(_amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: _receiver,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: expectedAmountOutMinimum
        });

        // Execute the swap.
        IERC20(stkAAVE).safeApprove(address(SWAP_ROUTER), _amountIn);
        amountOut = SWAP_ROUTER.exactInput(params);

        emit Swapped(_receiver, _amountIn, amountOut);
    }

    /// INTERNAL ///

    /// @dev Returns the minimum expected amount of Morpho token to receive and the multiple path for a swap.
    /// @param _amountIn The amount of reward token to swap.
    /// @return expectedAmountOutMinimum The minimum amount of Morpho tokens to receive.
    /// @return path The path for the swap.
    function _getMultiplePathParams(uint256 _amountIn)
        internal
        view
        returns (uint256 expectedAmountOutMinimum, bytes memory path)
    {
        uint32[] memory aaveSecondsAgo = new uint32[](2);
        aaveSecondsAgo[0] = aaveTwapInterval;
        aaveSecondsAgo[1] = 0;

        uint32[] memory morphoSecondsAgo = new uint32[](2);
        morphoSecondsAgo[0] = morphoTwapInterval;
        morphoSecondsAgo[1] = 0;

        uint256 priceX961;
        uint256 priceX962;

        {
            // pool0 is not observed as AAVE and stkAAVE are pegged.
            // We consider 1 aave = 1 stkaave as the fair price.
            (int56[] memory tickCumulatives1, ) = pool1.observe(aaveSecondsAgo);
            (int56[] memory tickCumulatives2, ) = pool2.observe(morphoSecondsAgo);

            // For the pair token0/token1 -> 1.0001 * readingTick = price = token1 / token0
            // So token1 = price * token0.

            uint160 sqrtPriceX961 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives1[1] - tickCumulatives1[0]) / int24(uint24(aaveTwapInterval)))
            );
            uint160 sqrtPriceX962 = TickMath.getSqrtRatioAtTick(
                int24(
                    (tickCumulatives2[1] - tickCumulatives2[0]) / int24(uint24(morphoTwapInterval))
                )
            );
            priceX961 = _getPriceX96FromSqrtPriceX96(sqrtPriceX961);
            priceX962 = _getPriceX96FromSqrtPriceX96(sqrtPriceX962);
        }

        // stkAAVE/AAVE -> token0 = stkAAVE
        // AAVE/WETH9 -> token0 = AAVE

        // Computation depends on the position of token in pool.
        if (pool2.token0() == WETH9) {
            expectedAmountOutMinimum = _amountIn.mulDiv(priceX961, FixedPoint96.Q96).mulDiv(
                priceX962,
                FixedPoint96.Q96
            );
        } else {
            expectedAmountOutMinimum = _amountIn.mulDiv(priceX961, FixedPoint96.Q96).mulDiv(
                FixedPoint96.Q96,
                priceX962
            );
        }

        // Max slippage of 3% for the trade.
        expectedAmountOutMinimum = expectedAmountOutMinimum.mulDiv(
            MAX_BASIS_POINTS - THREE_PERCENT,
            MAX_BASIS_POINTS
        );
        path = abi.encodePacked(stkAAVE, POOL_FEE, AAVE, POOL_FEE, WETH9, MORPHO_POOL_FEE, MORPHO);
    }

    /// @dev Returns the price in fixed point 96 from the square of the price in fixed point 96.
    /// @param _sqrtPriceX96 The square of the price in fixed point 96.
    /// @return priceX96 The price in fixed point 96.
    function _getPriceX96FromSqrtPriceX96(uint160 _sqrtPriceX96)
        public
        pure
        returns (uint256 priceX96)
    {
        return FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, FixedPoint96.Q96);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {IAToken} from "./interfaces/aave/IAToken.sol";
import "./interfaces/aave/IScaledBalanceToken.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "./libraries/Math.sol";

import "./positions-manager-parts/PositionsManagerForAaveStorage.sol";

/// @title MatchingEngineManager.
/// @notice Smart contract managing the matching engine.
contract MatchingEngineForAave is IMatchingEngineForAave, PositionsManagerForAaveStorage {
    using DoubleLinkedList for DoubleLinkedList.List;
    using Address for address;
    using Math for uint256;

    /// STRUCTS ///

    // Struct to avoid stack too deep
    struct UnmatchVars {
        uint256 p2pRate;
        uint256 toUnmatch;
        uint256 normalizer;
        uint256 inUnderlying;
        uint256 remainingToUnmatch;
        uint256 gasLeftAtTheBeginning;
    }

    // Struct to avoid stack too deep
    struct MatchVars {
        uint256 p2pRate;
        uint256 toMatch;
        uint256 normalizer;
        uint256 inUnderlying;
        uint256 gasLeftAtTheBeginning;
    }

    /// @notice Emitted when the position of a supplier is updated.
    /// @param _user The address of the supplier.
    /// @param _poolTokenAddress The address of the market.
    /// @param _balanceOnPool The supply balance on pool after update.
    /// @param _balanceInP2P The supply balance in P2P after update.
    event SupplierPositionUpdated(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when the position of a borrower is updated.
    /// @param _user The address of the borrower.
    /// @param _poolTokenAddress The address of the market.
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in P2P after update.
    event BorrowerPositionUpdated(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// CONSTRUCTOR ///

    /// @notice Constructs the MatchingEngineForAave contract.
    /// @dev The contract is automatically marked as initialized when deployed.
    constructor() initializer {}

    /// EXTERNAL ///

    /// @notice Matches suppliers' liquidity waiting on Aave up to the given `_amount` and move it to P2P.
    /// @dev Note: p2pExchangeRates must have been updated before calling this function.
    /// @param _poolToken The pool token of the market from which to match suppliers.
    /// @param _underlyingToken The underlying token of the market to find liquidity.
    /// @param _amount The token amount to search for (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    /// @return matched The amount of liquidity matched (in underlying).
    function matchSuppliers(
        IAToken _poolToken,
        ERC20 _underlyingToken,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) external override returns (uint256 matched) {
        MatchVars memory vars;
        address poolTokenAddress = address(_poolToken);
        address user = suppliersOnPool[poolTokenAddress].getHead();
        vars.normalizer = lendingPool.getReserveNormalizedIncome(address(_underlyingToken));
        vars.p2pRate = marketsManager.supplyP2PExchangeRate(poolTokenAddress);

        if (_maxGasToConsume != 0) {
            vars.gasLeftAtTheBeginning = gasleft();
            while (
                matched < _amount &&
                user != address(0) &&
                vars.gasLeftAtTheBeginning - gasleft() < _maxGasToConsume
            ) {
                vars.inUnderlying = supplyBalanceInOf[poolTokenAddress][user].onPool.mulWadByRay(
                    vars.normalizer
                );
                unchecked {
                    vars.toMatch = vars.inUnderlying < _amount - matched
                        ? vars.inUnderlying
                        : _amount - matched;
                    matched += vars.toMatch;
                }

                supplyBalanceInOf[poolTokenAddress][user].onPool -= vars.toMatch.divWadByRay(
                    vars.normalizer
                );
                supplyBalanceInOf[poolTokenAddress][user].inP2P += vars.toMatch.divWadByRay(
                    vars.p2pRate
                ); // In p2pUnit
                updateSuppliers(poolTokenAddress, user);
                emit SupplierPositionUpdated(
                    user,
                    poolTokenAddress,
                    supplyBalanceInOf[poolTokenAddress][user].onPool,
                    supplyBalanceInOf[poolTokenAddress][user].inP2P
                );

                user = suppliersOnPool[poolTokenAddress].getHead();
            }
        }
    }

    /// @notice Unmatches suppliers' liquidity in P2P up to the given `_amount` and move it to Aave.
    /// @dev Note: p2pExchangeRates must have been updated before calling this function.
    /// @param _poolTokenAddress The address of the market from which to unmatch suppliers.
    /// @param _amount The amount to search for (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    /// @return The amount unmatched (in underlying).
    function unmatchSuppliers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) external override returns (uint256) {
        UnmatchVars memory vars;
        ERC20 underlyingToken = ERC20(IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS());
        address user = suppliersInP2P[_poolTokenAddress].getHead();
        vars.normalizer = lendingPool.getReserveNormalizedIncome(address(underlyingToken));
        vars.p2pRate = marketsManager.supplyP2PExchangeRate(_poolTokenAddress);
        vars.remainingToUnmatch = _amount; // In underlying

        if (_maxGasToConsume != 0) {
            vars.gasLeftAtTheBeginning = gasleft();
            while (
                vars.remainingToUnmatch > 0 &&
                user != address(0) &&
                vars.gasLeftAtTheBeginning - gasleft() < _maxGasToConsume
            ) {
                vars.inUnderlying = supplyBalanceInOf[_poolTokenAddress][user].inP2P.mulWadByRay(
                    vars.p2pRate
                );
                unchecked {
                    vars.toUnmatch = vars.inUnderlying < vars.remainingToUnmatch
                        ? vars.inUnderlying
                        : vars.remainingToUnmatch; // In underlying
                    vars.remainingToUnmatch -= vars.toUnmatch;
                }

                supplyBalanceInOf[_poolTokenAddress][user].onPool += vars.toUnmatch.divWadByRay(
                    vars.normalizer
                );
                supplyBalanceInOf[_poolTokenAddress][user].inP2P -= vars.toUnmatch.divWadByRay(
                    vars.p2pRate
                ); // In p2pUnit
                updateSuppliers(_poolTokenAddress, user);
                emit SupplierPositionUpdated(
                    user,
                    _poolTokenAddress,
                    supplyBalanceInOf[_poolTokenAddress][user].onPool,
                    supplyBalanceInOf[_poolTokenAddress][user].inP2P
                );

                user = suppliersInP2P[_poolTokenAddress].getHead();
            }
        }

        return _amount - vars.remainingToUnmatch;
    }

    /// @notice Matches borrowers' liquidity waiting on Aave up to the given `_amount` and move it to P2P.
    /// @dev Note: p2pExchangeRates must have been updated before calling this function.
    /// @param _poolToken The pool token of the market from which to match borrowers.
    /// @param _underlyingToken The underlying token of the market to find liquidity.
    /// @param _amount The amount to search for (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    /// @return matched The amount of liquidity matched (in underlying).
    function matchBorrowers(
        IAToken _poolToken,
        ERC20 _underlyingToken,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) external override returns (uint256 matched) {
        MatchVars memory vars;
        address poolTokenAddress = address(_poolToken);
        address user = borrowersOnPool[poolTokenAddress].getHead();
        vars.normalizer = lendingPool.getReserveNormalizedVariableDebt(address(_underlyingToken));
        vars.p2pRate = marketsManager.borrowP2PExchangeRate(poolTokenAddress);

        if (_maxGasToConsume != 0) {
            vars.gasLeftAtTheBeginning = gasleft();
            while (
                matched < _amount &&
                user != address(0) &&
                vars.gasLeftAtTheBeginning - gasleft() < _maxGasToConsume
            ) {
                vars.inUnderlying = borrowBalanceInOf[poolTokenAddress][user].onPool.mulWadByRay(
                    vars.normalizer
                );
                unchecked {
                    vars.toMatch = vars.inUnderlying < _amount - matched
                        ? vars.inUnderlying
                        : _amount - matched;
                    matched += vars.toMatch;
                }

                borrowBalanceInOf[poolTokenAddress][user].onPool -= vars.toMatch.divWadByRay(
                    vars.normalizer
                );
                borrowBalanceInOf[poolTokenAddress][user].inP2P += vars.toMatch.divWadByRay(
                    vars.p2pRate
                );
                updateBorrowers(poolTokenAddress, user);
                emit BorrowerPositionUpdated(
                    user,
                    poolTokenAddress,
                    borrowBalanceInOf[poolTokenAddress][user].onPool,
                    borrowBalanceInOf[poolTokenAddress][user].inP2P
                );

                user = borrowersOnPool[poolTokenAddress].getHead();
            }
        }
    }

    /// @notice Unmatches borrowers' liquidity in P2P for the given `_amount` and move it to Aave.
    /// @dev Note: p2pExchangeRates must have been updated before calling this function.
    /// @param _poolTokenAddress The address of the market from which to unmatch borrowers.
    /// @param _amount The amount to unmatch (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    /// @return The amount unmatched (in underlying).
    function unmatchBorrowers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) external override returns (uint256) {
        UnmatchVars memory vars;
        ERC20 underlyingToken = ERC20(IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS());
        address user = borrowersInP2P[_poolTokenAddress].getHead();
        vars.remainingToUnmatch = _amount;
        vars.normalizer = lendingPool.getReserveNormalizedVariableDebt(address(underlyingToken));
        vars.p2pRate = marketsManager.borrowP2PExchangeRate(_poolTokenAddress);

        if (_maxGasToConsume != 0) {
            vars.gasLeftAtTheBeginning = gasleft();
            while (
                vars.remainingToUnmatch > 0 &&
                user != address(0) &&
                vars.gasLeftAtTheBeginning - gasleft() < _maxGasToConsume
            ) {
                vars.inUnderlying = borrowBalanceInOf[_poolTokenAddress][user].inP2P.mulWadByRay(
                    vars.p2pRate
                );
                unchecked {
                    vars.toUnmatch = vars.inUnderlying < vars.remainingToUnmatch
                        ? vars.inUnderlying
                        : vars.remainingToUnmatch; // In underlying
                    vars.remainingToUnmatch -= vars.toUnmatch;
                }

                borrowBalanceInOf[_poolTokenAddress][user].onPool += vars.toUnmatch.divWadByRay(
                    vars.normalizer
                );
                borrowBalanceInOf[_poolTokenAddress][user].inP2P -= vars.toUnmatch.divWadByRay(
                    vars.p2pRate
                );
                updateBorrowers(_poolTokenAddress, user);
                emit BorrowerPositionUpdated(
                    user,
                    _poolTokenAddress,
                    borrowBalanceInOf[_poolTokenAddress][user].onPool,
                    borrowBalanceInOf[_poolTokenAddress][user].inP2P
                );

                user = borrowersInP2P[_poolTokenAddress].getHead();
            }
        }

        return _amount - vars.remainingToUnmatch;
    }

    /// PUBLIC ///

    /// @notice Updates borrowers matching engine with the new balances of a given user.
    /// @param _poolTokenAddress The address of the market on which to update the borrowers data structure.
    /// @param _user The address of the user.
    function updateBorrowers(address _poolTokenAddress, address _user) public override {
        uint256 onPool = borrowBalanceInOf[_poolTokenAddress][_user].onPool;
        uint256 inP2P = borrowBalanceInOf[_poolTokenAddress][_user].inP2P;
        uint256 formerValueOnPool = borrowersOnPool[_poolTokenAddress].getValueOf(_user);
        uint256 formerValueInP2P = borrowersInP2P[_poolTokenAddress].getValueOf(_user);

        // Check pool
        bool wasOnPoolAndValueChanged = formerValueOnPool != 0 && formerValueOnPool != onPool;
        if (wasOnPoolAndValueChanged) borrowersOnPool[_poolTokenAddress].remove(_user);
        if (onPool > 0 && (wasOnPoolAndValueChanged || formerValueOnPool == 0)) {
            if (address(rewardsManager) != address(0)) {
                address variableDebtTokenAddress = lendingPool
                .getReserveData(IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS())
                .variableDebtTokenAddress;
                uint256 totalBorrowed = IScaledBalanceToken(variableDebtTokenAddress)
                .scaledTotalSupply();
                rewardsManager.updateUserAssetAndAccruedRewards(
                    _user,
                    variableDebtTokenAddress,
                    formerValueOnPool,
                    totalBorrowed
                );
            }
            borrowersOnPool[_poolTokenAddress].insertSorted(_user, onPool, NDS);
        }

        // Check P2P
        bool wasInP2PAndValueChanged = formerValueInP2P != 0 && formerValueInP2P != inP2P;
        if (wasInP2PAndValueChanged) borrowersInP2P[_poolTokenAddress].remove(_user);
        if (inP2P > 0 && (wasInP2PAndValueChanged || formerValueInP2P == 0))
            borrowersInP2P[_poolTokenAddress].insertSorted(_user, inP2P, NDS);
    }

    /// @notice Updates suppliers matching engine with the new balances of a given user.
    /// @param _poolTokenAddress The address of the market on which to update the suppliers data structure.
    /// @param _user The address of the user.
    function updateSuppliers(address _poolTokenAddress, address _user) public override {
        uint256 onPool = supplyBalanceInOf[_poolTokenAddress][_user].onPool;
        uint256 inP2P = supplyBalanceInOf[_poolTokenAddress][_user].inP2P;
        uint256 formerValueOnPool = suppliersOnPool[_poolTokenAddress].getValueOf(_user);
        uint256 formerValueInP2P = suppliersInP2P[_poolTokenAddress].getValueOf(_user);

        // Check pool
        bool wasOnPoolAndValueChanged = formerValueOnPool != 0 && formerValueOnPool != onPool;
        if (wasOnPoolAndValueChanged) suppliersOnPool[_poolTokenAddress].remove(_user);
        if (onPool > 0 && (wasOnPoolAndValueChanged || formerValueOnPool == 0)) {
            if (address(rewardsManager) != address(0)) {
                uint256 totalSupplied = IScaledBalanceToken(_poolTokenAddress).scaledTotalSupply();
                rewardsManager.updateUserAssetAndAccruedRewards(
                    _user,
                    _poolTokenAddress,
                    formerValueOnPool,
                    totalSupplied
                );
            }
            suppliersOnPool[_poolTokenAddress].insertSorted(_user, onPool, NDS);
        }

        // Check P2P
        bool wasInP2PAndValueChanged = formerValueInP2P != 0 && formerValueInP2P != inP2P;
        if (wasInP2PAndValueChanged) suppliersInP2P[_poolTokenAddress].remove(_user);
        if (inP2P > 0 && (wasInP2PAndValueChanged || formerValueInP2P == 0))
            suppliersInP2P[_poolTokenAddress].insertSorted(_user, inP2P, NDS);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./PositionsManagerForAaveStorage.sol";

/// @title PositionsManagerForAaveEventsErrors.
/// @notice Events and Errors for PositionsManagerForAave.
abstract contract PositionsManagerForAaveEventsErrors is PositionsManagerForAaveStorage {
    /// EVENTS ///

    /// @notice Emitted when a supply happens.
    /// @param _user The address of the supplier.
    /// @param _poolTokenAddress The address of the market where assets are supplied into.
    /// @param _amount The amount of assets supplied (in underlying).
    /// @param _balanceOnPool The supply balance on pool after update (in underlying).
    /// @param _balanceInP2P The supply balance in P2P after update (in underlying).
    /// @param _referralCode The referral code of an integrator that may receive rewards. 0 if no referral code.
    event Supplied(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P,
        uint16 indexed _referralCode
    );

    /// @notice Emitted when a withdrawal happens.
    /// @param _user The address of the withdrawer.
    /// @param _poolTokenAddress The address of the market from where assets are withdrawn.
    /// @param _amount The amount of assets withdrawn (in underlying).
    /// @param _balanceOnPool The supply balance on pool after update.
    /// @param _balanceInP2P The supply balance in P2P after update.
    event Withdrawn(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when a borrow happens.
    /// @param _user The address of the borrower.
    /// @param _poolTokenAddress The address of the market where assets are borrowed.
    /// @param _amount The amount of assets borrowed (in underlying).
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in P2P after update.
    /// @param _referralCode The referral code of an integrator that may receive rewards. 0 if no referral code.
    event Borrowed(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P,
        uint16 indexed _referralCode
    );

    /// @notice Emitted when a repayment happens.
    /// @param _user The address of the repayer.
    /// @param _poolTokenAddress The address of the market where assets are repaid.
    /// @param _amount The amount of assets repaid (in underlying).
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in P2P after update.
    event Repaid(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _amount,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when a liquidation happens.
    /// @param _liquidator The address of the liquidator.
    /// @param _liquidatee The address of the liquidatee.
    /// @param _amountRepaid The amount of borrowed asset repaid (in underlying).
    /// @param _poolTokenBorrowedAddress The address of the borrowed asset.
    /// @param _amountSeized The amount of collateral asset seized (in underlying).
    /// @param _poolTokenCollateralAddress The address of the collateral asset seized.
    event Liquidated(
        address _liquidator,
        address indexed _liquidatee,
        uint256 _amountRepaid,
        address indexed _poolTokenBorrowedAddress,
        uint256 _amountSeized,
        address indexed _poolTokenCollateralAddress
    );

    /// @notice Emitted when the borrow P2P delta is updated.
    /// @param _poolTokenAddress The address of the market.
    /// @param _borrowP2PDelta The borrow P2P delta after update.
    event BorrowP2PDeltaUpdated(address indexed _poolTokenAddress, uint256 _borrowP2PDelta);

    /// @notice Emitted when the supply P2P delta is updated.
    /// @param _poolTokenAddress The address of the market.
    /// @param _supplyP2PDelta The supply P2P delta after update.
    event SupplyP2PDeltaUpdated(address indexed _poolTokenAddress, uint256 _supplyP2PDelta);

    /// @notice Emitted when the supply and borrow P2P amounts are updated.
    /// @param _poolTokenAddress The address of the market.
    /// @param _supplyP2PAmount The supply P2P amount after update.
    /// @param _borrowP2PAmount The borrow P2P amount after update.
    event P2PAmountsUpdated(
        address indexed _poolTokenAddress,
        uint256 _supplyP2PAmount,
        uint256 _borrowP2PAmount
    );

    /// @dev Emitted when a new value for `NDS` is set.
    /// @param _newValue The new value of `NDS`.
    event NDSSet(uint8 _newValue);

    /// @dev Emitted when a new `maxGas` is set.
    /// @param _maxGas The new `maxGas`.
    event MaxGasSet(MaxGas _maxGas);

    /// @dev Emitted the address of the `treasuryVault` is set.
    /// @param _newTreasuryVaultAddress The new address of the `treasuryVault`.
    event TreasuryVaultSet(address indexed _newTreasuryVaultAddress);

    /// @notice Emitted the address of the `rewardsManager` is set.
    /// @param _newRewardsManagerAddress The new address of the `rewardsManager`.
    event RewardsManagerSet(address indexed _newRewardsManagerAddress);

    /// @notice Emitted the address of the `aaveIncentivesController` is set.
    /// @param _aaveIncentivesController The new address of the `aaveIncentivesController`.
    event AaveIncentivesControllerSet(address indexed _aaveIncentivesController);

    /// @notice Emitted when a market is paused or unpaused.
    /// @param _poolTokenAddress The address of the pool token concerned..
    /// @param _newStatus The new pause status of the market.
    event PauseStatusSet(address indexed _poolTokenAddress, bool _newStatus);

    /// @notice Emitted when a reserve fee is claimed.
    /// @param _poolTokenAddress The address of the pool token concerned.
    /// @param _amountClaimed The amount of reward token claimed.
    event ReserveFeeClaimed(address indexed _poolTokenAddress, uint256 _amountClaimed);

    /// @notice Emitted when a user claims rewards.
    /// @param _user The address of the claimer.
    /// @param _amountClaimed The amount of reward token claimed.
    event RewardsClaimed(address indexed _user, uint256 _amountClaimed);

    /// @dev Emitted when a user claims rewards and swaps them to Morpho tokens.
    /// @param _user The address of the claimer.
    /// @param _amountIn The amount of reward token swapped.
    /// @param _amountOut The amount of tokens received.
    event RewardsClaimedAndSwapped(address indexed _user, uint256 _amountIn, uint256 _amountOut);

    /// ERRORS ///

    /// @notice Thrown when the amount is equal to 0.
    error AmountIsZero();

    /// @notice Thrown when the address is the zero address.
    error ZeroAddress();

    /// @notice Thrown when the market is not created yet.
    error MarketNotCreated();

    /// @notice Thrown when the market is paused.
    error MarketPaused();

    /// @notice Thrown when the market is not listed on Aave.
    error MarketIsNotListedOnAave();

    /// @notice Thrown when the debt value is above the maximum debt value.
    error DebtValueAboveMax();

    /// @notice Thrown when the debt value is not above the maximum debt value.
    error DebtValueNotAboveMax();

    /// @notice Thrown when the amount of collateral to seize is above the collateral amount.
    error ToSeizeAboveCollateral();

    /// @notice Thrown when the amount repaid during the liquidation is above what is allowed to be repaid.
    error AmountAboveWhatAllowedToRepay();
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "../interfaces/aave/IPriceOracleGetter.sol";

import {ReserveConfiguration} from "../libraries/aave/ReserveConfiguration.sol";
import "../libraries/Math.sol";

import "./PositionsManagerForAaveEventsErrors.sol";

/// @title PositionsManagerForAaveGettersSetters.
/// @notice Getters and setters for PositionsManagerForAave, including externals, internals, user-accessible and admin-only functions.
abstract contract PositionsManagerForAaveGettersSetters is PositionsManagerForAaveEventsErrors {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using DoubleLinkedList for DoubleLinkedList.List;
    using Math for uint256;

    /// MODIFIERS ///

    /// @notice Prevents a user to trigger a function when market is not created or paused.
    /// @param _poolTokenAddress The address of the market to check.
    modifier isMarketCreatedAndNotPaused(address _poolTokenAddress) {
        if (!marketsManager.isCreated(_poolTokenAddress)) revert MarketNotCreated();
        if (paused[_poolTokenAddress]) revert MarketPaused();
        _;
    }

    /// SETTERS ///

    /// @notice Sets the `aaveIncentivesController`.
    /// @param _aaveIncentivesController The address of the `aaveIncentivesController`.
    function setAaveIncentivesController(address _aaveIncentivesController) external onlyOwner {
        aaveIncentivesController = IAaveIncentivesController(_aaveIncentivesController);
        emit AaveIncentivesControllerSet(_aaveIncentivesController);
    }

    /// @dev Sets `NDS`.
    /// @param _newNDS The new `NDS` value.
    function setNDS(uint8 _newNDS) external onlyOwner {
        NDS = _newNDS;
        emit NDSSet(_newNDS);
    }

    /// @dev Sets `maxGas`.
    /// @param _maxGas The new `maxGas`.
    function setMaxGas(MaxGas memory _maxGas) external onlyOwner {
        maxGas = _maxGas;
        emit MaxGasSet(_maxGas);
    }

    /// @notice Sets the `treasuryVault`.
    /// @param _newTreasuryVaultAddress The address of the new `treasuryVault`.
    function setTreasuryVault(address _newTreasuryVaultAddress) external onlyOwner {
        treasuryVault = _newTreasuryVaultAddress;
        emit TreasuryVaultSet(_newTreasuryVaultAddress);
    }

    /// @dev Sets the `rewardsManager`.
    /// @param _rewardsManagerAddress The address of the `rewardsManager`.
    function setRewardsManager(address _rewardsManagerAddress) external onlyOwner {
        rewardsManager = IRewardsManagerForAave(_rewardsManagerAddress);
        emit RewardsManagerSet(_rewardsManagerAddress);
    }

    /// @dev Sets the pause status on a specific market in case of emergency.
    /// @param _poolTokenAddress The address of the market to pause/unpause.
    function setPauseStatus(address _poolTokenAddress) external onlyOwner {
        bool newPauseStatus = !paused[_poolTokenAddress];
        paused[_poolTokenAddress] = newPauseStatus;
        emit PauseStatusSet(_poolTokenAddress, newPauseStatus);
    }

    /// GETTERS ///

    /// @notice Gets the head of the data structure on a specific market (for UI).
    /// @param _poolTokenAddress The address of the market from which to get the head.
    /// @param _positionType The type of user from which to get the head.
    /// @return head The head in the data structure.
    function getHead(address _poolTokenAddress, PositionType _positionType)
        external
        view
        returns (address head)
    {
        if (_positionType == PositionType.SUPPLIERS_IN_P2P)
            head = suppliersInP2P[_poolTokenAddress].getHead();
        else if (_positionType == PositionType.SUPPLIERS_ON_POOL)
            head = suppliersOnPool[_poolTokenAddress].getHead();
        else if (_positionType == PositionType.BORROWERS_IN_P2P)
            head = borrowersInP2P[_poolTokenAddress].getHead();
        else if (_positionType == PositionType.BORROWERS_ON_POOL)
            head = borrowersOnPool[_poolTokenAddress].getHead();
    }

    /// @notice Gets the next user after `_user` in the data structure on a specific market (for UI).
    /// @param _poolTokenAddress The address of the market from which to get the user.
    /// @param _positionType The type of user from which to get the next user.
    /// @param _user The address of the user from which to get the next user.
    /// @return next The next user in the data structure.
    function getNext(
        address _poolTokenAddress,
        PositionType _positionType,
        address _user
    ) external view returns (address next) {
        if (_positionType == PositionType.SUPPLIERS_IN_P2P)
            next = suppliersInP2P[_poolTokenAddress].getNext(_user);
        else if (_positionType == PositionType.SUPPLIERS_ON_POOL)
            next = suppliersOnPool[_poolTokenAddress].getNext(_user);
        else if (_positionType == PositionType.BORROWERS_IN_P2P)
            next = borrowersInP2P[_poolTokenAddress].getNext(_user);
        else if (_positionType == PositionType.BORROWERS_ON_POOL)
            next = borrowersOnPool[_poolTokenAddress].getNext(_user);
    }

    /// @notice Returns the collateral value, debt value, max debt and liquidation value of a given user (in ETH).
    /// @param _user The user to determine liquidity for.
    /// @return collateralValue The collateral value of the user (in ETH).
    /// @return debtValue The current debt value of the user (in ETH).
    /// @return maxDebtValue The maximum possible debt value of the user (in ETH).
    /// @return liquidationValue The value which made liquidation possible (in ETH).
    function getUserBalanceStates(address _user)
        external
        view
        returns (
            uint256 collateralValue,
            uint256 debtValue,
            uint256 maxDebtValue,
            uint256 liquidationValue
        )
    {
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        uint256 numberOfEnteredMarkets = enteredMarkets[_user].length;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[_user][i];
            AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                oracle
            );

            unchecked {
                collateralValue += assetData.collateralValue;
                maxDebtValue += assetData.maxDebtValue;
                debtValue += assetData.debtValue;
                liquidationValue += assetData.liquidationValue;
                ++i;
            }
        }
    }

    /// @notice Returns the maximum amount available to withdraw and borrow for `_user` related to `_poolTokenAddress` (in underlyings).
    /// @param _user The user to determine the capacities for.
    /// @param _poolTokenAddress The address of the market.
    /// @return withdrawable The maximum withdrawable amount of underlying token allowed (in underlying).
    /// @return borrowable The maximum borrowable amount of underlying token allowed (in underlying).
    function getUserMaxCapacitiesForAsset(address _user, address _poolTokenAddress)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable)
    {
        LiquidityData memory data;
        AssetLiquidityData memory assetData;
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        uint256 numberOfEnteredMarkets = enteredMarkets[_user].length;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[_user][i];

            if (_poolTokenAddress != poolTokenEntered) {
                assetData = getUserLiquidityDataForAsset(_user, poolTokenEntered, oracle);

                unchecked {
                    data.maxDebtValue += assetData.maxDebtValue;
                    data.debtValue += assetData.debtValue;
                }
            }

            unchecked {
                ++i;
            }
        }

        assetData = getUserLiquidityDataForAsset(_user, _poolTokenAddress, oracle);

        unchecked {
            data.maxDebtValue += assetData.maxDebtValue;
            data.debtValue += assetData.debtValue;
        }

        // Not possible to withdraw nor borrow
        if (data.maxDebtValue < data.debtValue) return (0, 0);

        uint256 differenceInUnderlying = ((data.maxDebtValue - data.debtValue) *
            assetData.tokenUnit) / assetData.underlyingPrice;

        withdrawable =
            (assetData.collateralValue * assetData.tokenUnit) /
            assetData.underlyingPrice;
        if (assetData.ltv != 0) {
            withdrawable = Math.min(
                withdrawable,
                (differenceInUnderlying * MAX_BASIS_POINTS) / assetData.ltv
            );
        }

        borrowable = differenceInUnderlying;
    }

    /// @notice Returns the data related to `_poolTokenAddress` for the `_user`.
    /// @param _user The user to determine data for.
    /// @param _poolTokenAddress The address of the market.
    /// @return assetData The data related to this asset.
    function getUserLiquidityDataForAsset(
        address _user,
        address _poolTokenAddress,
        IPriceOracleGetter oracle
    ) public view returns (AssetLiquidityData memory assetData) {
        // Compute the current debt amount (in underlying)
        address underlyingAddress = IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS();
        assetData.debtValue = _getUserBorrowBalanceInOf(
            _poolTokenAddress,
            _user,
            underlyingAddress
        );

        // Compute the current collateral amount (in underlying)
        assetData.collateralValue = _getUserSupplyBalanceInOf(
            _poolTokenAddress,
            _user,
            underlyingAddress
        );

        assetData.underlyingPrice = oracle.getAssetPrice(underlyingAddress); // In ETH
        (uint256 ltv, uint256 liquidationThreshold, , uint256 reserveDecimals, ) = lendingPool
        .getConfiguration(underlyingAddress)
        .getParamsMemory();
        assetData.ltv = ltv;
        assetData.liquidationThreshold = liquidationThreshold;

        unchecked {
            assetData.tokenUnit = 10**reserveDecimals;
        }

        // Then, convert values to ETH
        assetData.collateralValue = assetData.collateralValue * assetData.underlyingPrice;
        unchecked {
            assetData.collateralValue /= assetData.tokenUnit;
        }

        assetData.debtValue = assetData.debtValue * assetData.underlyingPrice;
        unchecked {
            assetData.maxDebtValue = assetData.collateralValue * ltv;
            assetData.liquidationValue = assetData.collateralValue * liquidationThreshold;
            assetData.maxDebtValue /= MAX_BASIS_POINTS;
            assetData.liquidationValue /= MAX_BASIS_POINTS;
            assetData.debtValue /= assetData.tokenUnit;
        }
    }

    /// @dev Returns the debt value, max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    /// @param _poolTokenAddress The market to hypothetically withdraw/borrow in.
    /// @param _withdrawnAmount The number of tokens to hypothetically withdraw (in underlying).
    /// @param _borrowedAmount The amount of tokens to hypothetically borrow (in underlying).
    /// @return debtValue The current debt value of the user (in ETH).
    /// @return maxDebtValue The maximum debt value possible of the user (in ETH).
    /// @return liquidationValue The value when liquidation is possible (in ETH).
    function _getUserHypotheticalBalanceStates(
        address _user,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    )
        internal
        view
        returns (
            uint256 debtValue,
            uint256 maxDebtValue,
            uint256 liquidationValue
        )
    {
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        uint256 numberOfEnteredMarkets = enteredMarkets[_user].length;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[_user][i];
            AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                _user,
                poolTokenEntered,
                oracle
            );

            unchecked {
                liquidationValue += assetData.liquidationValue;
                maxDebtValue += assetData.maxDebtValue;
                debtValue += assetData.debtValue;
                ++i;
            }

            if (_poolTokenAddress == poolTokenEntered) {
                debtValue += (_borrowedAmount * assetData.underlyingPrice) / assetData.tokenUnit;

                uint256 maxDebtValueSub = (_withdrawnAmount *
                    assetData.underlyingPrice *
                    assetData.ltv) / (assetData.tokenUnit * MAX_BASIS_POINTS);
                uint256 liquidationValueSub = (_withdrawnAmount *
                    assetData.underlyingPrice *
                    assetData.liquidationThreshold) / (assetData.tokenUnit * MAX_BASIS_POINTS);

                unchecked {
                    maxDebtValue -= maxDebtValue < maxDebtValueSub ? maxDebtValue : maxDebtValueSub;
                    liquidationValue -= liquidationValue < liquidationValueSub
                        ? liquidationValue
                        : liquidationValueSub;
                }
            }
        }
    }

    /// @dev Returns the supply balance of `_user` in the `_poolTokenAddress` market.
    /// @param _user The address of the user.
    /// @param _poolTokenAddress The market where to get the supply amount.
    /// @param _underlyingTokenAddress The underlying token address related to this market.
    /// @return The supply balance of the user (in underlying).
    function _getUserSupplyBalanceInOf(
        address _poolTokenAddress,
        address _user,
        address _underlyingTokenAddress
    ) internal view returns (uint256) {
        (uint256 supplyP2PExchangeRate, ) = marketsManager.getUpdatedP2PExchangeRates(
            _poolTokenAddress
        );
        return
            supplyBalanceInOf[_poolTokenAddress][_user].inP2P.mulWadByRay(supplyP2PExchangeRate) +
            supplyBalanceInOf[_poolTokenAddress][_user].onPool.mulWadByRay(
                lendingPool.getReserveNormalizedIncome(_underlyingTokenAddress)
            );
    }

    /// @dev Returns the borrow balance of `_user` in the `_poolTokenAddress` market.
    /// @param _user The address of the user.
    /// @param _poolTokenAddress The market where to get the borrow amount.
    /// @param _underlyingTokenAddress The underlying token address related to this market.
    /// @return The borrow balance of the user (in underlying).
    function _getUserBorrowBalanceInOf(
        address _poolTokenAddress,
        address _user,
        address _underlyingTokenAddress
    ) internal view returns (uint256) {
        (, uint256 borrowP2PExchangeRate) = marketsManager.getUpdatedP2PExchangeRates(
            _poolTokenAddress
        );
        return
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P.mulWadByRay(borrowP2PExchangeRate) +
            borrowBalanceInOf[_poolTokenAddress][_user].onPool.mulWadByRay(
                lendingPool.getReserveNormalizedVariableDebt(_underlyingTokenAddress)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/************
@title IPriceOracleGetter interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "../libraries/MatchingEngineFns.sol";

import "./PositionsManagerForAaveGettersSetters.sol";

/// @title PositionsManagerForAaveLogic.
/// @notice Main Logic of Morpho Protocol, implementation of the 5 main functionalities: supply, borrow, withdraw, repay, liquidate.
contract PositionsManagerForAaveLogic is PositionsManagerForAaveGettersSetters {
    using MatchingEngineFns for IMatchingEngineForAave;
    using DoubleLinkedList for DoubleLinkedList.List;
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /// STRUCTS ///

    struct WithdrawVars {
        uint256 remainingToWithdraw;
        uint256 supplyPoolIndex;
        uint256 withdrawable;
        uint256 toWithdraw;
    }

    struct RepayVars {
        uint256 remainingToRepay;
        uint256 borrowPoolIndex;
        uint256 supplyPoolIndex;
        uint256 toRepay;
    }

    /// UPGRADE ///

    /// @notice Initializes the PositionsManagerForAave contract.
    /// @param _marketsManager The `marketsManager`.
    /// @param _matchingEngine The `matchingEngine`.
    /// @param _lendingPoolAddressesProvider The `addressesProvider`.
    function initialize(
        IMarketsManagerForAave _marketsManager,
        IMatchingEngineForAave _matchingEngine,
        ILendingPoolAddressesProvider _lendingPoolAddressesProvider,
        MaxGas memory _maxGas,
        uint8 _NDS
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        maxGas = _maxGas;
        marketsManager = _marketsManager;
        matchingEngine = _matchingEngine;
        addressesProvider = _lendingPoolAddressesProvider;
        lendingPool = ILendingPool(addressesProvider.getLendingPool());

        NDS = _NDS;
    }

    /// LOGIC ///

    /// @dev Implements supply logic.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    function _supply(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal isMarketCreatedAndNotPaused(_poolTokenAddress) {
        _enterMarketIfNeeded(_poolTokenAddress, msg.sender);

        ERC20 underlyingToken = ERC20(IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS());
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);

        Types.Delta storage delta = deltas[_poolTokenAddress];
        uint256 borrowPoolIndex = lendingPool.getReserveNormalizedVariableDebt(
            address(underlyingToken)
        );
        uint256 remainingToSupply = _amount;
        uint256 toRepay;

        /// Supply in P2P ///

        if (!marketsManager.noP2P(_poolTokenAddress)) {
            // Match borrow P2P delta first if any.
            if (delta.borrowP2PDelta > 0) {
                uint256 matchedDelta = Math.min(
                    delta.borrowP2PDelta.mulWadByRay(borrowPoolIndex),
                    remainingToSupply
                );
                if (matchedDelta > 0) {
                    toRepay += matchedDelta;
                    remainingToSupply -= matchedDelta;
                    delta.borrowP2PDelta -= matchedDelta.divWadByRay(borrowPoolIndex);
                    emit BorrowP2PDeltaUpdated(_poolTokenAddress, delta.borrowP2PDelta);
                }
            }

            // Match pool suppliers if any.
            if (
                remainingToSupply > 0 && borrowersOnPool[_poolTokenAddress].getHead() != address(0)
            ) {
                uint256 matched = matchingEngine.matchBorrowersDC(
                    IAToken(_poolTokenAddress),
                    underlyingToken,
                    remainingToSupply,
                    _maxGasToConsume
                ); // In underlying.

                if (matched > 0) {
                    toRepay += matched;
                    remainingToSupply -= matched;
                    delta.borrowP2PAmount += matched.divWadByRay(
                        marketsManager.borrowP2PExchangeRate(_poolTokenAddress)
                    );
                }
            }
        }

        if (toRepay > 0) {
            uint256 toAddInP2P = toRepay.divWadByRay(
                marketsManager.supplyP2PExchangeRate(_poolTokenAddress)
            );

            delta.supplyP2PAmount += toAddInP2P;
            supplyBalanceInOf[_poolTokenAddress][msg.sender].inP2P += toAddInP2P;
            matchingEngine.updateSuppliersDC(_poolTokenAddress, msg.sender);

            toRepay = Math.min(
                toRepay,
                IVariableDebtToken(
                    lendingPool.getReserveData(address(underlyingToken)).variableDebtTokenAddress
                ).scaledBalanceOf(address(this))
                .mulWadByRay(borrowPoolIndex) // Current Morpho's debt on Aave.
            );

            if (toRepay > 0) _repayERC20ToPool(underlyingToken, toRepay); // Reverts on error.
            emit P2PAmountsUpdated(_poolTokenAddress, delta.supplyP2PAmount, delta.borrowP2PAmount);
        }

        /// Supply on pool ///

        if (remainingToSupply > 0) {
            supplyBalanceInOf[_poolTokenAddress][msg.sender].onPool += remainingToSupply
            .divWadByRay(lendingPool.getReserveNormalizedIncome(address(underlyingToken))); // In scaled balance.
            matchingEngine.updateSuppliersDC(_poolTokenAddress, msg.sender);
            _supplyToPool(underlyingToken, remainingToSupply); // Reverts on error.
        }
    }

    /// @dev Implements borrow logic.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    function _borrow(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal isMarketCreatedAndNotPaused(_poolTokenAddress) {
        _enterMarketIfNeeded(_poolTokenAddress, msg.sender);
        _checkUserLiquidity(msg.sender, _poolTokenAddress, 0, _amount);
        ERC20 underlyingToken = ERC20(IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS());
        uint256 remainingToBorrow = _amount;
        uint256 toWithdraw;
        Types.Delta storage delta = deltas[_poolTokenAddress];
        uint256 poolSupplyIndex = lendingPool.getReserveNormalizedIncome(address(underlyingToken));
        uint256 withdrawable = IAToken(_poolTokenAddress).balanceOf(address(this)); // The balance on pool.

        /// Borrow in P2P ///

        if (!marketsManager.noP2P(_poolTokenAddress)) {
            // Match supply P2P delta first if any.
            uint256 matchedDelta;
            if (delta.supplyP2PDelta > 0) {
                matchedDelta = Math.min(
                    delta.supplyP2PDelta.mulWadByRay(poolSupplyIndex),
                    remainingToBorrow,
                    withdrawable
                );
                if (matchedDelta > 0) {
                    toWithdraw += matchedDelta;
                    remainingToBorrow -= matchedDelta;
                    delta.supplyP2PDelta -= matchedDelta.divWadByRay(poolSupplyIndex);
                    emit SupplyP2PDeltaUpdated(_poolTokenAddress, delta.supplyP2PDelta);
                }
            }

            // Match pool suppliers if any.
            if (
                remainingToBorrow > 0 && suppliersOnPool[_poolTokenAddress].getHead() != address(0)
            ) {
                uint256 matched = matchingEngine.matchSuppliersDC(
                    IAToken(_poolTokenAddress),
                    underlyingToken,
                    Math.min(remainingToBorrow, withdrawable - toWithdraw),
                    _maxGasToConsume
                ); // In underlying.

                if (matched > 0) {
                    toWithdraw += matched;
                    remainingToBorrow -= matched;
                    deltas[_poolTokenAddress].supplyP2PAmount += matched.divWadByRay(
                        marketsManager.supplyP2PExchangeRate(_poolTokenAddress)
                    );
                }
            }
        }

        if (toWithdraw > 0) {
            uint256 toAddInP2P = toWithdraw.divWadByRay(
                marketsManager.borrowP2PExchangeRate(_poolTokenAddress)
            ); // In p2pUnit.

            deltas[_poolTokenAddress].borrowP2PAmount += toAddInP2P;
            borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P += toAddInP2P;
            matchingEngine.updateBorrowersDC(_poolTokenAddress, msg.sender);

            _withdrawFromPool(underlyingToken, toWithdraw); // Reverts on error.
            emit P2PAmountsUpdated(_poolTokenAddress, delta.supplyP2PAmount, delta.borrowP2PAmount);
        }

        /// Borrow on pool ///

        if (remainingToBorrow > 0) {
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool += remainingToBorrow
            .divWadByRay(lendingPool.getReserveNormalizedVariableDebt(address(underlyingToken))); // In adUnit.
            matchingEngine.updateBorrowersDC(_poolTokenAddress, msg.sender);
            _borrowFromPool(underlyingToken, remainingToBorrow);
        }

        underlyingToken.safeTransfer(msg.sender, _amount);
    }

    /// @dev Implements withdraw logic.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _supplier The address of the supplier.
    /// @param _receiver The address of the user who will receive the tokens.
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    function _withdraw(
        address _poolTokenAddress,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasToConsume
    ) internal isMarketCreatedAndNotPaused(_poolTokenAddress) {
        IAToken poolToken = IAToken(_poolTokenAddress);
        ERC20 underlyingToken = ERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        WithdrawVars memory vars;
        vars.remainingToWithdraw = _amount;
        vars.withdrawable = poolToken.balanceOf(address(this));
        vars.supplyPoolIndex = lendingPool.getReserveNormalizedIncome(address(underlyingToken));

        /// Soft withdraw ///

        if (supplyBalanceInOf[_poolTokenAddress][_supplier].onPool > 0) {
            uint256 onPoolSupply = supplyBalanceInOf[_poolTokenAddress][_supplier].onPool;
            vars.toWithdraw = Math.min(
                onPoolSupply.mulWadByRay(vars.supplyPoolIndex),
                vars.remainingToWithdraw,
                vars.withdrawable
            );
            vars.remainingToWithdraw -= vars.toWithdraw;

            supplyBalanceInOf[_poolTokenAddress][_supplier].onPool -= Math.min(
                onPoolSupply,
                vars.toWithdraw.divWadByRay(vars.supplyPoolIndex)
            ); // In poolToken.
            matchingEngine.updateSuppliersDC(_poolTokenAddress, _supplier);

            if (vars.remainingToWithdraw == 0) {
                if (vars.toWithdraw > 0) _withdrawFromPool(underlyingToken, vars.toWithdraw); // Reverts on error.
                underlyingToken.safeTransfer(_receiver, _amount);
                _leaveMarkerIfNeeded(_poolTokenAddress, _supplier);
                return;
            }
        }

        Types.Delta storage delta = deltas[_poolTokenAddress];
        uint256 supplyP2PExchangeRate = marketsManager.supplyP2PExchangeRate(_poolTokenAddress);

        /// Transfer withdraw ///

        if (vars.remainingToWithdraw > 0 && !marketsManager.noP2P(_poolTokenAddress)) {
            supplyBalanceInOf[_poolTokenAddress][_supplier].inP2P -= Math.min(
                supplyBalanceInOf[_poolTokenAddress][_supplier].inP2P,
                vars.remainingToWithdraw.divWadByRay(supplyP2PExchangeRate)
            ); // In p2pUnit
            matchingEngine.updateSuppliersDC(_poolTokenAddress, _supplier);

            // Match Delta if any.
            if (delta.supplyP2PDelta > 0) {
                uint256 matchedDelta;
                matchedDelta = Math.min(
                    delta.supplyP2PDelta.mulWadByRay(vars.supplyPoolIndex),
                    vars.remainingToWithdraw,
                    vars.withdrawable - vars.toWithdraw
                );

                if (matchedDelta > 0) {
                    vars.toWithdraw += matchedDelta;
                    vars.remainingToWithdraw -= matchedDelta;
                    delta.supplyP2PDelta -= matchedDelta.divWadByRay(vars.supplyPoolIndex);
                    delta.supplyP2PAmount -= matchedDelta.divWadByRay(supplyP2PExchangeRate);
                    emit SupplyP2PDeltaUpdated(_poolTokenAddress, delta.supplyP2PDelta);
                }
            }

            // Match pool suppliers if any.
            if (
                vars.remainingToWithdraw > 0 &&
                suppliersOnPool[_poolTokenAddress].getHead() != address(0)
            ) {
                // Match suppliers.
                uint256 matched = matchingEngine.matchSuppliersDC(
                    poolToken,
                    underlyingToken,
                    Math.min(vars.remainingToWithdraw, vars.withdrawable - vars.toWithdraw),
                    _maxGasToConsume / 2
                );

                if (matched > 0) {
                    vars.remainingToWithdraw -= matched;
                    vars.toWithdraw += matched;
                }
            }
        }

        if (vars.toWithdraw > 0) _withdrawFromPool(underlyingToken, vars.toWithdraw); // Reverts on error.

        /// Hard withdraw ///

        if (vars.remainingToWithdraw > 0) {
            uint256 unmatched = matchingEngine.unmatchBorrowersDC(
                _poolTokenAddress,
                vars.remainingToWithdraw,
                _maxGasToConsume / 2
            );

            // If unmatched does not cover remainingToWithdraw, the difference is added to the borrow P2P delta.
            if (unmatched < vars.remainingToWithdraw) {
                delta.borrowP2PDelta += (vars.remainingToWithdraw - unmatched).divWadByRay(
                    lendingPool.getReserveNormalizedVariableDebt(address(underlyingToken))
                );
                emit BorrowP2PDeltaUpdated(_poolTokenAddress, delta.borrowP2PAmount);
            }

            delta.supplyP2PAmount -= vars.remainingToWithdraw.divWadByRay(supplyP2PExchangeRate);
            delta.borrowP2PAmount -= unmatched.divWadByRay(
                marketsManager.borrowP2PExchangeRate(_poolTokenAddress)
            );
            emit P2PAmountsUpdated(_poolTokenAddress, delta.supplyP2PAmount, delta.borrowP2PAmount);

            _borrowFromPool(underlyingToken, vars.remainingToWithdraw); // Reverts on error.
        }

        underlyingToken.safeTransfer(_receiver, _amount);
        _leaveMarkerIfNeeded(_poolTokenAddress, _supplier);
    }

    /// @dev Implements repay logic.
    /// @dev Note: `msg.sender` must have approved this contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _user The address of the user.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    function _repay(
        address _poolTokenAddress,
        address _user,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal isMarketCreatedAndNotPaused(_poolTokenAddress) {
        IAToken poolToken = IAToken(_poolTokenAddress);
        ERC20 underlyingToken = ERC20(poolToken.UNDERLYING_ASSET_ADDRESS());
        underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);
        RepayVars memory vars;
        vars.remainingToRepay = _amount;
        vars.borrowPoolIndex = lendingPool.getReserveNormalizedVariableDebt(
            address(underlyingToken)
        );

        /// Soft repay ///

        if (borrowBalanceInOf[_poolTokenAddress][_user].onPool > 0) {
            uint256 borrowedOnPool = borrowBalanceInOf[_poolTokenAddress][_user].onPool;
            vars.toRepay = Math.min(
                borrowedOnPool.mulWadByRay(vars.borrowPoolIndex),
                vars.remainingToRepay
            );
            vars.remainingToRepay -= vars.toRepay;

            borrowBalanceInOf[_poolTokenAddress][_user].onPool -= Math.min(
                borrowedOnPool,
                vars.toRepay.divWadByRay(vars.borrowPoolIndex)
            ); // In adUnit
            matchingEngine.updateBorrowersDC(_poolTokenAddress, _user);

            if (vars.remainingToRepay == 0) {
                vars.toRepay = Math.min(
                    vars.toRepay,
                    IVariableDebtToken(
                        lendingPool
                        .getReserveData(address(underlyingToken))
                        .variableDebtTokenAddress
                    ).scaledBalanceOf(address(this))
                    .mulWadByRay(vars.borrowPoolIndex) // The debt of the contract.
                );
                if (vars.toRepay > 0) _repayERC20ToPool(underlyingToken, vars.toRepay); // Reverts on error.
                _leaveMarkerIfNeeded(_poolTokenAddress, _user);
                return;
            }
        }

        Types.Delta storage delta = deltas[_poolTokenAddress];
        uint256 borrowP2PExchangeRate = marketsManager.borrowP2PExchangeRate(_poolTokenAddress);
        uint256 supplyP2PExchangeRate = marketsManager.supplyP2PExchangeRate(_poolTokenAddress);
        vars.supplyPoolIndex = lendingPool.getReserveNormalizedIncome(address(underlyingToken));
        borrowBalanceInOf[_poolTokenAddress][_user].inP2P -= Math.min(
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P,
            vars.remainingToRepay.divWadByRay(borrowP2PExchangeRate)
        ); // In p2pUnit
        matchingEngine.updateBorrowersDC(_poolTokenAddress, _user);

        /// Fee repay ///

        uint256 feeToRepay = Math.min(
            (delta.borrowP2PAmount.mulWadByRay(borrowP2PExchangeRate) -
                delta.borrowP2PDelta.mulWadByRay(vars.borrowPoolIndex)) -
                (delta.supplyP2PAmount.mulWadByRay(supplyP2PExchangeRate) -
                    delta.supplyP2PDelta.mulWadByRay(vars.supplyPoolIndex)),
            vars.remainingToRepay
        );
        vars.remainingToRepay -= feeToRepay;

        /// Transfer repay ///

        if (vars.remainingToRepay > 0 && !marketsManager.noP2P(_poolTokenAddress)) {
            // Match Delta if any.
            if (delta.borrowP2PDelta > 0) {
                uint256 matchedDelta = Math.min(
                    delta.borrowP2PDelta.mulWadByRay(vars.borrowPoolIndex),
                    vars.remainingToRepay
                );

                if (matchedDelta > 0) {
                    vars.toRepay += matchedDelta;
                    vars.remainingToRepay -= matchedDelta;
                    delta.borrowP2PDelta -= matchedDelta.divWadByRay(vars.borrowPoolIndex);
                    delta.borrowP2PAmount -= matchedDelta.divWadByRay(borrowP2PExchangeRate);
                    emit BorrowP2PDeltaUpdated(_poolTokenAddress, delta.borrowP2PDelta);
                }
            }

            if (
                vars.remainingToRepay > 0 &&
                borrowersOnPool[_poolTokenAddress].getHead() != address(0)
            ) {
                // Match borrowers.
                uint256 matched = matchingEngine.matchBorrowersDC(
                    poolToken,
                    underlyingToken,
                    vars.remainingToRepay,
                    _maxGasToConsume / 2
                );

                if (matched > 0) {
                    vars.remainingToRepay -= matched;
                    vars.toRepay += matched;
                }
            }
        }

        // Manages the case where someone has repaid on behalf of Morpho.
        // The remaining tokens stay on the contract, and will be claimed as reserve by the governance.
        vars.toRepay = Math.min(
            vars.toRepay,
            IVariableDebtToken(
                lendingPool.getReserveData(address(underlyingToken)).variableDebtTokenAddress
            ).scaledBalanceOf(address(this))
            .mulWadByRay(vars.borrowPoolIndex) // The debt of the contract.
        );

        if (vars.toRepay > 0) _repayERC20ToPool(underlyingToken, vars.toRepay); // Reverts on error.

        /// Hard repay ///

        if (vars.remainingToRepay > 0) {
            uint256 unmatched = matchingEngine.unmatchSuppliersDC(
                _poolTokenAddress,
                vars.remainingToRepay,
                _maxGasToConsume / 2
            ); // Reverts on error.

            // If unmatched does not cover remainingToRepay, the difference is added to the supply P2P delta.
            if (unmatched < vars.remainingToRepay) {
                delta.supplyP2PDelta += (vars.remainingToRepay - unmatched).divWadByRay(
                    vars.supplyPoolIndex
                );
                emit SupplyP2PDeltaUpdated(_poolTokenAddress, delta.borrowP2PDelta);
            }

            delta.supplyP2PAmount -= unmatched.divWadByRay(supplyP2PExchangeRate);
            delta.borrowP2PAmount -= vars.remainingToRepay.divWadByRay(borrowP2PExchangeRate);
            emit P2PAmountsUpdated(_poolTokenAddress, delta.supplyP2PAmount, delta.borrowP2PAmount);

            _supplyToPool(underlyingToken, vars.remainingToRepay); // Reverts on error.
        }
        _leaveMarkerIfNeeded(_poolTokenAddress, _user);
    }

    /// @dev Enters the user into the market if not already there.
    /// @param _user The address of the user to update.
    /// @param _poolTokenAddress The address of the market to check.
    function _enterMarketIfNeeded(address _poolTokenAddress, address _user) internal {
        if (!userMembership[_poolTokenAddress][_user]) {
            userMembership[_poolTokenAddress][_user] = true;
            enteredMarkets[_user].push(_poolTokenAddress);
        }
    }

    /// @dev Removes the user from the market if he has no funds or borrow on it.
    /// @param _user The address of the user to update.
    /// @param _poolTokenAddress The address of the market to check.
    function _leaveMarkerIfNeeded(address _poolTokenAddress, address _user) internal {
        if (
            supplyBalanceInOf[_poolTokenAddress][_user].inP2P == 0 &&
            supplyBalanceInOf[_poolTokenAddress][_user].onPool == 0 &&
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P == 0 &&
            borrowBalanceInOf[_poolTokenAddress][_user].onPool == 0
        ) {
            uint256 index;
            while (enteredMarkets[_user][index] != _poolTokenAddress) {
                unchecked {
                    ++index;
                }
            }
            userMembership[_poolTokenAddress][_user] = false;

            uint256 length = enteredMarkets[_user].length;
            if (index != length - 1)
                enteredMarkets[_user][index] = enteredMarkets[_user][length - 1];
            enteredMarkets[_user].pop();
        }
    }

    /// @dev Checks whether the user can borrow/withdraw or not.
    /// @param _user The user to determine liquidity for.
    /// @param _poolTokenAddress The market to hypothetically withdraw/borrow in.
    /// @param _withdrawnAmount The number of tokens to hypothetically withdraw (in underlying).
    /// @param _borrowedAmount The amount of tokens to hypothetically borrow (in underlying).
    function _checkUserLiquidity(
        address _user,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) internal view {
        (uint256 debtValue, uint256 maxDebtValue, ) = _getUserHypotheticalBalanceStates(
            _user,
            _poolTokenAddress,
            _withdrawnAmount,
            _borrowedAmount
        );
        if (debtValue > maxDebtValue) revert DebtValueAboveMax();
    }

    /// @dev Supplies underlying tokens to Aave.
    /// @param _underlyingToken The underlying token of the market to supply to.
    /// @param _amount The amount of token (in underlying).
    function _supplyToPool(ERC20 _underlyingToken, uint256 _amount) internal {
        _underlyingToken.safeApprove(address(lendingPool), _amount);
        lendingPool.deposit(address(_underlyingToken), _amount, address(this), NO_REFERRAL_CODE);
    }

    /// @dev Withdraws underlying tokens from Aave.
    /// @param _underlyingToken The underlying token of the market to withdraw from.
    /// @param _amount The amount of token (in underlying).
    function _withdrawFromPool(ERC20 _underlyingToken, uint256 _amount) internal {
        lendingPool.withdraw(address(_underlyingToken), _amount, address(this));
    }

    /// @dev Borrows underlying tokens from Aave.
    /// @param _underlyingToken The underlying token of the market to borrow from.
    /// @param _amount The amount of token (in underlying).
    function _borrowFromPool(ERC20 _underlyingToken, uint256 _amount) internal {
        lendingPool.borrow(
            address(_underlyingToken),
            _amount,
            VARIABLE_INTEREST_MODE,
            NO_REFERRAL_CODE,
            address(this)
        );
    }

    /// @dev Repays underlying tokens to Aave.
    /// @param _underlyingToken The underlying token of the market to repay to.
    /// @param _amount The amount of token (in underlying).
    function _repayERC20ToPool(ERC20 _underlyingToken, uint256 _amount) internal {
        _underlyingToken.safeApprove(address(lendingPool), _amount);
        lendingPool.repay(
            address(_underlyingToken),
            _amount,
            VARIABLE_INTEREST_MODE,
            address(this)
        );
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import {IAToken} from "../interfaces/aave/IAToken.sol";
import "../interfaces/IMatchingEngineForAave.sol";

import "@openzeppelin/contracts/utils/Address.sol";

library MatchingEngineFns {
    using Address for address;

    function matchSuppliersDC(
        IMatchingEngineForAave _matchingEngine,
        IAToken _poolToken,
        ERC20 _underlyingToken,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal returns (uint256) {
        bytes memory data = address(_matchingEngine).functionDelegateCall(
            abi.encodeWithSelector(
                _matchingEngine.matchSuppliers.selector,
                _poolToken,
                _underlyingToken,
                _amount,
                _maxGasToConsume
            )
        );
        return abi.decode(data, (uint256));
    }

    function unmatchSuppliersDC(
        IMatchingEngineForAave _matchingEngine,
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal returns (uint256) {
        bytes memory data = address(_matchingEngine).functionDelegateCall(
            abi.encodeWithSelector(
                _matchingEngine.unmatchSuppliers.selector,
                _poolTokenAddress,
                _amount,
                _maxGasToConsume
            )
        );
        return abi.decode(data, (uint256));
    }

    function matchBorrowersDC(
        IMatchingEngineForAave _matchingEngine,
        IAToken _poolToken,
        ERC20 _underlyingToken,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal returns (uint256) {
        bytes memory data = address(_matchingEngine).functionDelegateCall(
            abi.encodeWithSelector(
                _matchingEngine.matchBorrowers.selector,
                _poolToken,
                _underlyingToken,
                _amount,
                _maxGasToConsume
            )
        );
        return abi.decode(data, (uint256));
    }

    function unmatchBorrowersDC(
        IMatchingEngineForAave _matchingEngine,
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasToConsume
    ) internal returns (uint256) {
        bytes memory data = address(_matchingEngine).functionDelegateCall(
            abi.encodeWithSelector(
                _matchingEngine.unmatchBorrowers.selector,
                _poolTokenAddress,
                _amount,
                _maxGasToConsume
            )
        );
        return abi.decode(data, (uint256));
    }

    function updateBorrowersDC(
        IMatchingEngineForAave _matchingEngine,
        address _poolTokenAddress,
        address _user
    ) internal {
        address(_matchingEngine).functionDelegateCall(
            abi.encodeWithSelector(
                _matchingEngine.updateBorrowers.selector,
                _poolTokenAddress,
                _user
            )
        );
    }

    function updateSuppliersDC(
        IMatchingEngineForAave _matchingEngine,
        address _poolTokenAddress,
        address _user
    ) internal {
        address(_matchingEngine).functionDelegateCall(
            abi.encodeWithSelector(
                _matchingEngine.updateSuppliers.selector,
                _poolTokenAddress,
                _user
            )
        );
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./positions-manager-parts/PositionsManagerForAaveLogic.sol";

/// @title PositionsManagerForAave.
/// @notice Smart contract interacting with Aave to enable P2P supply/borrow positions that can fallback on Aave's pool using pool tokens.
contract PositionsManagerForAave is PositionsManagerForAaveLogic {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using MatchingEngineFns for IMatchingEngineForAave;
    using DoubleLinkedList for DoubleLinkedList.List;
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /// @notice Supplies underlying tokens in a specific market.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying) to supply.
    /// @param _referralCode The referral code of an integrator that may receive rewards. 0 if no referral code.
    function supply(
        address _poolTokenAddress,
        uint256 _amount,
        uint16 _referralCode
    ) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenAddress);
        _supply(_poolTokenAddress, _amount, maxGas.supply);

        emit Supplied(
            msg.sender,
            _poolTokenAddress,
            _amount,
            supplyBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            supplyBalanceInOf[_poolTokenAddress][msg.sender].inP2P,
            _referralCode
        );
    }

    /// @notice Supplies underlying tokens in a specific market.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying) to supply.
    /// @param _referralCode The referral code of an integrator that may receive rewards. 0 if no referral code.
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    function supply(
        address _poolTokenAddress,
        uint256 _amount,
        uint16 _referralCode,
        uint256 _maxGasToConsume
    ) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenAddress);
        _supply(_poolTokenAddress, _amount, _maxGasToConsume);

        emit Supplied(
            msg.sender,
            _poolTokenAddress,
            _amount,
            supplyBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            supplyBalanceInOf[_poolTokenAddress][msg.sender].inP2P,
            _referralCode
        );
    }

    /// @notice Borrows underlying tokens in a specific market.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _referralCode The referral code of an integrator that may receive rewards. 0 if no referral code.
    function borrow(
        address _poolTokenAddress,
        uint256 _amount,
        uint16 _referralCode
    ) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenAddress);
        _borrow(_poolTokenAddress, _amount, maxGas.borrow);

        emit Borrowed(
            msg.sender,
            _poolTokenAddress,
            _amount,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P,
            _referralCode
        );
    }

    /// @notice Borrows underlying tokens in a specific market.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _referralCode The referral code of an integrator that may receive rewards. 0 if no referral code.
    /// @param _maxGasToConsume The maximum amount of gas to consume within a matching engine loop.
    function borrow(
        address _poolTokenAddress,
        uint256 _amount,
        uint16 _referralCode,
        uint256 _maxGasToConsume
    ) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenAddress);
        _borrow(_poolTokenAddress, _amount, _maxGasToConsume);

        emit Borrowed(
            msg.sender,
            _poolTokenAddress,
            _amount,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P,
            _referralCode
        );
    }

    /// @notice Withdraws underlying tokens in a specific market.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of tokens (in underlying) to withdraw from supply.
    function withdraw(address _poolTokenAddress, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenAddress);

        uint256 toWithdraw = Math.min(
            _getUserSupplyBalanceInOf(
                _poolTokenAddress,
                msg.sender,
                IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS()
            ),
            _amount
        );

        _checkUserLiquidity(msg.sender, _poolTokenAddress, toWithdraw, 0);
        _withdraw(_poolTokenAddress, toWithdraw, msg.sender, msg.sender, maxGas.withdraw);

        emit Withdrawn(
            msg.sender,
            _poolTokenAddress,
            _amount,
            supplyBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            supplyBalanceInOf[_poolTokenAddress][msg.sender].inP2P
        );
    }

    /// @notice Repays debt of the user.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolTokenAddress The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying) to repay from borrow.
    function repay(address _poolTokenAddress, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenAddress);

        uint256 toRepay = Math.min(
            _getUserBorrowBalanceInOf(
                _poolTokenAddress,
                msg.sender,
                IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS()
            ),
            _amount
        );

        _repay(_poolTokenAddress, msg.sender, toRepay, maxGas.repay);

        emit Repaid(
            msg.sender,
            _poolTokenAddress,
            _amount,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].onPool,
            borrowBalanceInOf[_poolTokenAddress][msg.sender].inP2P
        );
    }

    /// @notice Liquidates a position.
    /// @param _poolTokenBorrowedAddress The address of the pool token the liquidator wants to repay.
    /// @param _poolTokenCollateralAddress The address of the collateral pool token the liquidator wants to seize.
    /// @param _borrower The address of the borrower to liquidate.
    /// @param _amount The amount of token (in underlying) to repay.
    function liquidate(
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external nonReentrant {
        if (_amount == 0) revert AmountIsZero();
        marketsManager.updateP2PExchangeRates(_poolTokenBorrowedAddress);
        marketsManager.updateP2PExchangeRates(_poolTokenCollateralAddress);

        LiquidateVars memory vars;
        (vars.debtValue, , vars.liquidationValue) = _getUserHypotheticalBalanceStates(
            _borrower,
            address(0),
            0,
            0
        );
        if (vars.debtValue <= vars.liquidationValue) revert DebtValueNotAboveMax();

        IAToken poolTokenBorrowed = IAToken(_poolTokenBorrowedAddress);
        vars.tokenBorrowedAddress = poolTokenBorrowed.UNDERLYING_ASSET_ADDRESS();

        vars.borrowBalance = _getUserBorrowBalanceInOf(
            _poolTokenBorrowedAddress,
            _borrower,
            vars.tokenBorrowedAddress
        );

        if (_amount > (vars.borrowBalance * LIQUIDATION_CLOSE_FACTOR_PERCENT) / MAX_BASIS_POINTS)
            revert AmountAboveWhatAllowedToRepay(); // Same mechanism as Aave. Liquidator cannot repay more than part of the debt (cf close factor on Aave).

        _repay(_poolTokenBorrowedAddress, _borrower, _amount, 0);

        IAToken poolTokenCollateral = IAToken(_poolTokenCollateralAddress);
        vars.tokenCollateralAddress = poolTokenCollateral.UNDERLYING_ASSET_ADDRESS();

        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        vars.borrowedPrice = oracle.getAssetPrice(vars.tokenBorrowedAddress); // In ETH
        vars.collateralPrice = oracle.getAssetPrice(vars.tokenCollateralAddress); // In ETH

        (, , vars.liquidationBonus, vars.collateralReserveDecimals, ) = lendingPool
        .getConfiguration(vars.tokenCollateralAddress)
        .getParamsMemory();
        (, , , vars.borrowedReserveDecimals, ) = lendingPool
        .getConfiguration(vars.tokenBorrowedAddress)
        .getParamsMemory();

        unchecked {
            vars.collateralTokenUnit = 10**vars.collateralReserveDecimals;
            vars.borrowedTokenUnit = 10**vars.borrowedReserveDecimals;
        }

        // Calculate the amount of collateral to seize (cf Aave):
        // seizeAmount = repayAmount * liquidationBonus * borrowedPrice * collateralTokenUnit / (collateralPrice * borrowedTokenUnit)
        vars.amountToSeize =
            (_amount * vars.borrowedPrice * vars.collateralTokenUnit * vars.liquidationBonus) /
            (vars.borrowedTokenUnit * vars.collateralPrice * MAX_BASIS_POINTS); // Same mechanism as aave. The collateral amount to seize is given.

        vars.supplyBalance = _getUserSupplyBalanceInOf(
            _poolTokenCollateralAddress,
            _borrower,
            vars.tokenCollateralAddress
        );

        if (vars.amountToSeize > vars.supplyBalance) revert ToSeizeAboveCollateral();

        _withdraw(_poolTokenCollateralAddress, vars.amountToSeize, _borrower, msg.sender, 0);

        emit Liquidated(
            msg.sender,
            _borrower,
            _amount,
            _poolTokenBorrowedAddress,
            vars.amountToSeize,
            _poolTokenCollateralAddress
        );
    }

    /// @dev Transfers the protocol reserve fee to the DAO.
    /// @param _poolTokenAddress The address of the market on which we want to claim the reserve fee.
    function claimToTreasury(address _poolTokenAddress)
        external
        onlyOwner
        isMarketCreatedAndNotPaused(_poolTokenAddress)
    {
        if (treasuryVault == address(0)) revert ZeroAddress();

        ERC20 underlyingToken = ERC20(IAToken(_poolTokenAddress).UNDERLYING_ASSET_ADDRESS());
        uint256 amountToClaim = underlyingToken.balanceOf(address(this));

        if (amountToClaim == 0) revert AmountIsZero();

        underlyingToken.safeTransfer(treasuryVault, amountToClaim);
        emit ReserveFeeClaimed(_poolTokenAddress, amountToClaim);
    }

    /// @notice Claims rewards for the given assets and the unclaimed rewards.
    /// @param _assets The assets to claim rewards from (aToken or variable debt token).
    /// @param _swap Whether or not to swap reward tokens for Morpho tokens.
    function claimRewards(address[] calldata _assets, bool _swap) external nonReentrant {
        uint256 amountToClaim = rewardsManager.claimRewards(_assets, type(uint256).max, msg.sender);

        if (amountToClaim == 0) revert AmountIsZero();
        else {
            if (_swap) {
                address swapManager = rewardsManager.swapManager();
                uint256 amountClaimed = aaveIncentivesController.claimRewards(
                    _assets,
                    amountToClaim,
                    swapManager
                );
                uint256 amountOut = ISwapManager(swapManager).swapToMorphoToken(
                    amountClaimed,
                    msg.sender
                );
                emit RewardsClaimedAndSwapped(msg.sender, amountClaimed, amountOut);
            } else {
                uint256 amountClaimed = aaveIncentivesController.claimRewards(
                    _assets,
                    amountToClaim,
                    msg.sender
                );
                emit RewardsClaimed(msg.sender, amountClaimed);
            }
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./interfaces/aave/IAaveIncentivesController.sol";
import "./interfaces/aave/IScaledBalanceToken.sol";
import "./interfaces/aave/ILendingPool.sol";
import "./interfaces/IPositionsManagerForAave.sol";
import "./interfaces/IGetterUnderlyingAsset.sol";
import "./interfaces/IRewardsManagerForAave.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RewardsManagerForAave is IRewardsManagerForAave, Ownable {
    /// STRUCTS ///

    struct LocalAssetData {
        uint256 lastIndex; // The last index for the given market.
        uint256 lastUpdateTimestamp; // The last time the index has been updated for the given market.
        mapping(address => uint256) userIndex; // The current index for a given user.
    }

    /// STORAGE ///

    mapping(address => uint256) public userUnclaimedRewards; // The unclaimed rewards of the user.
    mapping(address => LocalAssetData) public localAssetData; // The local data related to a given market.

    IAaveIncentivesController public override aaveIncentivesController;
    IPositionsManagerForAave public immutable positionsManager;
    ILendingPool public immutable lendingPool;
    address public override swapManager;

    /// EVENTS ///

    /// @notice Emitted the address of the `aaveIncentivesController` is set.
    /// @param _aaveIncentivesController The new address of the `aaveIncentivesController`.
    event AaveIncentivesControllerSet(address indexed _aaveIncentivesController);

    /// @notice Emitted the address of the `swapManager` is set.
    /// @param _swapManager The new address of the `swapManager`.
    event SwapManagerSet(address indexed _swapManager);

    /// ERRORS ///

    /// @notice Thrown when only the positions manager can call the function.
    error OnlyPositionsManager();

    /// @notice Thrown when an invalid asset is passed to accrue rewards.
    error InvalidAsset();

    /// MODIFIERS ///

    /// @notice Prevents a user to call function allowed for the positions manager only.
    modifier onlyPositionsManager() {
        if (msg.sender != address(positionsManager)) revert OnlyPositionsManager();
        _;
    }

    /// CONSTRUCTOR ///

    /// @notice Constructs the RewardsManager contract.
    /// @param _lendingPool The `lendingPool`.
    /// @param _positionsManager The `positionsManager`.
    /// @param _swapManager The address of the `swapManager`.
    constructor(
        ILendingPool _lendingPool,
        IPositionsManagerForAave _positionsManager,
        address _swapManager
    ) {
        lendingPool = _lendingPool;
        positionsManager = _positionsManager;
        swapManager = _swapManager;
    }

    /// EXTERNAL ///

    /// @notice Sets the `aaveIncentivesController`.
    /// @param _aaveIncentivesController The address of the `aaveIncentivesController`.
    function setAaveIncentivesController(address _aaveIncentivesController)
        external
        override
        onlyOwner
    {
        aaveIncentivesController = IAaveIncentivesController(_aaveIncentivesController);
        emit AaveIncentivesControllerSet(_aaveIncentivesController);
    }

    /// @notice Sets the `swapManager`.
    /// @param _swapManager The address of the `swapManager`.
    function setSwapManager(address _swapManager) external override onlyOwner {
        swapManager = _swapManager;
        emit SwapManagerSet(_swapManager);
    }

    /// @notice Accrues unclaimed rewards for the given assets and returns the total unclaimed rewards.
    /// @param _assets The assets for which to accrue rewards (aToken or variable debt token).
    /// @param _amount The amount of token rewards to claim.
    /// @param _user The address of the user.
    function claimRewards(
        address[] calldata _assets,
        uint256 _amount,
        address _user
    ) external override onlyPositionsManager returns (uint256 amountToClaim) {
        if (_amount == 0) return 0;

        uint256 unclaimedRewards = accrueUserUnclaimedRewards(_assets, _user);
        if (unclaimedRewards == 0) return 0;

        amountToClaim = _amount > unclaimedRewards ? unclaimedRewards : _amount;
        userUnclaimedRewards[_user] = unclaimedRewards - amountToClaim;
    }

    /// @notice Updates the unclaimed rewards of an user.
    /// @param _user The address of the user.
    /// @param _asset The address of the reference asset of the distribution (aToken or variable debt token).
    /// @param _userBalance The user balance of tokens in the distribution.
    /// @param _totalBalance The total balance of tokens in the distribution.
    function updateUserAssetAndAccruedRewards(
        address _user,
        address _asset,
        uint256 _userBalance,
        uint256 _totalBalance
    ) external override onlyPositionsManager {
        userUnclaimedRewards[_user] += _updateUserAsset(_user, _asset, _userBalance, _totalBalance);
    }

    /// @notice Returns the index of the `_user` for a given `_asset`.
    /// @param _asset The address of the reference asset of the distribution (aToken or variable debt token).
    /// @param _user The address of the user.
    /// @return userIndex_ The index of the user.
    function getUserIndex(address _asset, address _user)
        external
        view
        override
        returns (uint256 userIndex_)
    {
        LocalAssetData storage localData = localAssetData[_asset];
        userIndex_ = localData.userIndex[_user];
    }

    /// @notice Get the unclaimed rewards for the given assets and returns the total unclaimed rewards.
    /// @param _assets The assets for which to accrue rewards (aToken or variable debt token).
    /// @param _user The address of the user.
    /// @return unclaimedRewards The user unclaimed rewards.
    function getUserUnclaimedRewards(address[] calldata _assets, address _user)
        external
        view
        override
        returns (uint256 unclaimedRewards)
    {
        unclaimedRewards = userUnclaimedRewards[_user];

        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            DataTypes.ReserveData memory reserve = lendingPool.getReserveData(
                IGetterUnderlyingAsset(asset).UNDERLYING_ASSET_ADDRESS()
            );
            uint256 userBalance;
            if (asset == reserve.aTokenAddress)
                userBalance = positionsManager
                .supplyBalanceInOf(reserve.aTokenAddress, _user)
                .onPool;
            else if (asset == reserve.variableDebtTokenAddress)
                userBalance = positionsManager
                .borrowBalanceInOf(reserve.aTokenAddress, _user)
                .onPool;
            else revert InvalidAsset();

            uint256 totalBalance = IScaledBalanceToken(asset).scaledTotalSupply();

            unclaimedRewards += _getUserAsset(_user, asset, userBalance, totalBalance);
        }
    }

    /// PUBLIC ///

    /// @notice Accrues unclaimed rewards for the given assets and returns the total unclaimed rewards.
    /// @param _assets The assets for which to accrue rewards (aToken or variable debt token).
    /// @param _user The address of the user.
    /// @return unclaimedRewards The user unclaimed rewards.
    function accrueUserUnclaimedRewards(address[] calldata _assets, address _user)
        public
        override
        returns (uint256 unclaimedRewards)
    {
        unclaimedRewards = userUnclaimedRewards[_user];

        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            DataTypes.ReserveData memory reserve = lendingPool.getReserveData(
                IGetterUnderlyingAsset(asset).UNDERLYING_ASSET_ADDRESS()
            );
            uint256 userBalance;
            if (asset == reserve.aTokenAddress)
                userBalance = positionsManager
                .supplyBalanceInOf(reserve.aTokenAddress, _user)
                .onPool;
            else if (asset == reserve.variableDebtTokenAddress)
                userBalance = positionsManager
                .borrowBalanceInOf(reserve.aTokenAddress, _user)
                .onPool;
            else revert InvalidAsset();

            uint256 totalBalance = IScaledBalanceToken(asset).scaledTotalSupply();

            unclaimedRewards += _updateUserAsset(_user, asset, userBalance, totalBalance);
        }

        userUnclaimedRewards[_user] = unclaimedRewards;
    }

    /// INTERNAL ///

    /// @dev Updates the state of a user in a distribution.
    /// @param _user The address of the user.
    /// @param _asset The address of the reference asset of the distribution (aToken or variable debt token).
    /// @param _userBalance The user balance of tokens in the distribution.
    /// @param _totalBalance The total balance of tokens in the distribution.
    /// @return accruedRewards The accrued rewards for the user until the moment for this asset.
    function _updateUserAsset(
        address _user,
        address _asset,
        uint256 _userBalance,
        uint256 _totalBalance
    ) internal returns (uint256 accruedRewards) {
        LocalAssetData storage localData = localAssetData[_asset];
        uint256 formerUserIndex = localData.userIndex[_user];
        uint256 newIndex = _getUpdatedIndex(_asset, _totalBalance);

        if (formerUserIndex != newIndex) {
            if (_userBalance != 0)
                accruedRewards = _getRewards(_userBalance, newIndex, formerUserIndex);

            localData.userIndex[_user] = newIndex;
        }
    }

    /// @dev Gets the state of a user in a distribution.
    /// @dev This function is the equivalent of _updateUserAsset but as a view.
    /// @param _user The address of the user.
    /// @param _asset The address of the reference asset of the distribution (aToken or variable debt token).
    /// @param _userBalance The user balance of tokens in the distribution.
    /// @param _totalBalance The total balance of tokens in the distribution.
    /// @return accruedRewards The accrued rewards for the user until the moment for this asset.
    function _getUserAsset(
        address _user,
        address _asset,
        uint256 _userBalance,
        uint256 _totalBalance
    ) internal view returns (uint256 accruedRewards) {
        LocalAssetData storage localData = localAssetData[_asset];
        uint256 formerUserIndex = localData.userIndex[_user];
        uint256 newIndex = _getNewIndex(_asset, _totalBalance);

        if (formerUserIndex != newIndex) {
            if (_userBalance != 0)
                accruedRewards = _getRewards(_userBalance, newIndex, formerUserIndex);
        }
    }

    /// @dev Computes and returns the next value of a specific distribution index.
    /// @param _currentIndex The current index of the distribution.
    /// @param _emissionPerSecond The total rewards distributed per second per asset unit, on the distribution.
    /// @param _lastUpdateTimestamp The last moment this distribution was updated.
    /// @param _totalBalance The total balance of tokens in the distribution.
    /// @return The new index.
    function _getAssetIndex(
        uint256 _currentIndex,
        uint256 _emissionPerSecond,
        uint256 _lastUpdateTimestamp,
        uint256 _totalBalance
    ) internal view returns (uint256) {
        uint256 distributionEnd = aaveIncentivesController.DISTRIBUTION_END();
        uint256 currentTimestamp = block.timestamp;

        if (
            _lastUpdateTimestamp == currentTimestamp ||
            _emissionPerSecond == 0 ||
            _totalBalance == 0 ||
            _lastUpdateTimestamp >= distributionEnd
        ) return _currentIndex;

        if (currentTimestamp > distributionEnd) currentTimestamp = distributionEnd;
        uint256 timeDelta = currentTimestamp - _lastUpdateTimestamp;
        return ((_emissionPerSecond * timeDelta * 1e18) / _totalBalance) + _currentIndex;
    }

    /// @dev Computes and returns the rewards on a distribution.
    /// @param _userBalance The user balance of tokens in the distribution.
    /// @param _reserveIndex The current index of the distribution.
    /// @param _userIndex The index stored for the user, representing his staking moment.
    /// @return The rewards.
    function _getRewards(
        uint256 _userBalance,
        uint256 _reserveIndex,
        uint256 _userIndex
    ) internal pure returns (uint256) {
        return (_userBalance * (_reserveIndex - _userIndex)) / 1e18;
    }

    /// @dev Returns the next reward index.
    /// @param _asset The address of the reference asset of the distribution (aToken or variable debt token).
    /// @param _totalBalance The total balance of tokens in the distribution.
    /// @return newIndex The new distribution index.
    function _getUpdatedIndex(address _asset, uint256 _totalBalance)
        internal
        virtual
        returns (uint256 newIndex);

    /// @dev Returns the next reward index.
    /// @dev This function is the equivalent of _getUpdatedIndex, but as a view.
    /// @param _asset The address of the reference asset of the distribution (aToken or variable debt token).
    /// @param _totalBalance The total balance of tokens in the distribution.
    /// @return newIndex The new distribution index.
    function _getNewIndex(address _asset, uint256 _totalBalance)
        internal
        view
        virtual
        returns (uint256 newIndex);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

interface IGetterUnderlyingAsset {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "../RewardsManagerForAave.sol";

contract RewardsManagerForAaveOnPolygon is RewardsManagerForAave {
    constructor(
        ILendingPool _lendingPool,
        IPositionsManagerForAave _positionsManager,
        address _swapManager
    ) RewardsManagerForAave(_lendingPool, _positionsManager, _swapManager) {}

    /// @inheritdoc RewardsManagerForAave
    function _getUpdatedIndex(address _asset, uint256 _totalBalance)
        internal
        override
        returns (uint256 newIndex)
    {
        LocalAssetData storage localData = localAssetData[_asset];
        uint256 blockTimestamp = block.timestamp;
        uint256 lastTimestamp = localData.lastUpdateTimestamp;

        if (blockTimestamp == lastTimestamp) return localData.lastIndex;
        else {
            IAaveIncentivesController.AssetData memory assetData = aaveIncentivesController.assets(
                _asset
            );
            uint256 oldIndex = assetData.index;
            uint128 lastTimestampOnAave = assetData.lastUpdateTimestamp;

            newIndex = _getAssetIndex(
                oldIndex,
                assetData.emissionPerSecond,
                lastTimestampOnAave,
                _totalBalance
            );
            localData.lastUpdateTimestamp = blockTimestamp;
            localData.lastIndex = newIndex;
        }
    }

    /// @inheritdoc RewardsManagerForAave
    function _getNewIndex(address _asset, uint256 _totalBalance)
        internal
        view
        override
        returns (uint256 newIndex)
    {
        LocalAssetData storage localData = localAssetData[_asset];
        uint256 blockTimestamp = block.timestamp;
        uint256 lastTimestamp = localData.lastUpdateTimestamp;

        if (blockTimestamp == lastTimestamp) return localData.lastIndex;
        else {
            IAaveIncentivesController.AssetData memory assetData = aaveIncentivesController.assets(
                _asset
            );
            uint256 oldIndex = assetData.index;
            uint128 lastTimestampOnAave = assetData.lastUpdateTimestamp;

            newIndex = _getAssetIndex(
                oldIndex,
                assetData.emissionPerSecond,
                lastTimestampOnAave,
                _totalBalance
            );
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "../RewardsManagerForAave.sol";

contract RewardsManagerForAaveOnMainnetAndAvalanche is RewardsManagerForAave {
    constructor(
        ILendingPool _lendingPool,
        IPositionsManagerForAave _positionsManager,
        address _swapManager
    ) RewardsManagerForAave(_lendingPool, _positionsManager, _swapManager) {}

    /// @inheritdoc RewardsManagerForAave
    function _getUpdatedIndex(address _asset, uint256 _totalBalance)
        internal
        override
        returns (uint256 newIndex)
    {
        LocalAssetData storage localData = localAssetData[_asset];
        uint256 blockTimestamp = block.timestamp;
        uint256 lastTimestamp = localData.lastUpdateTimestamp;
        if (blockTimestamp == lastTimestamp) return localData.lastIndex;
        else {
            (
                uint256 oldIndex,
                uint256 emissionPerSecond,
                uint256 lastTimestampOnAave
            ) = aaveIncentivesController.getAssetData(_asset);

            newIndex = _getAssetIndex(
                oldIndex,
                emissionPerSecond,
                lastTimestampOnAave,
                _totalBalance
            );
            localData.lastUpdateTimestamp = blockTimestamp;
            localData.lastIndex = newIndex;
        }
    }

    /// @inheritdoc RewardsManagerForAave
    function _getNewIndex(address _asset, uint256 _totalBalance)
        internal
        view
        override
        returns (uint256 newIndex)
    {
        LocalAssetData storage localData = localAssetData[_asset];
        uint256 blockTimestamp = block.timestamp;
        uint256 lastTimestamp = localData.lastUpdateTimestamp;
        if (blockTimestamp == lastTimestamp) return localData.lastIndex;
        else {
            (
                uint256 oldIndex,
                uint256 emissionPerSecond,
                uint256 lastTimestampOnAave
            ) = aaveIncentivesController.getAssetData(_asset);

            newIndex = _getAssetIndex(
                oldIndex,
                emissionPerSecond,
                lastTimestampOnAave,
                _totalBalance
            );
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/ISwapManager.sol";

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SwapManager for Uniswap V2.
/// @notice Smart contract managing the swap of reward tokens to Morpho tokens.
contract SwapManagerUniV2 is ISwapManager, Ownable {
    using SafeTransferLib for ERC20;
    using FixedPoint for *;

    /// STORAGE ///

    uint256 public twapInterval;
    uint256 public constant ONE_PERCENT = 100; // 1% in basis points.
    uint256 public constant MAX_BASIS_POINTS = 10_000; // 100% in basis points.
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    address public immutable REWARD_TOKEN; // The reward token address.
    address public immutable MORPHO; // Morpho token address.
    address public immutable token0;
    address public immutable token1;

    IUniswapV2Router02 public immutable swapRouter;
    IUniswapV2Pair public immutable pair;

    /// EVENTS ///

    /// @notice Emitted when a swap to Morpho tokens happens.
    /// @param _receiver The address of the receiver.
    /// @param _amountIn The amount of reward token swapped.
    /// @param _amountOut The amount of Morpho token received.
    event Swapped(address indexed _receiver, uint256 _amountIn, uint256 _amountOut);

    /// @notice Emitted when the TWAP interval is set.
    /// @param _twapInterval The new `twapInterval`.
    event TwapIntervalSet(uint256 _twapInterval);

    /// ERRORS ///

    /// @notice Thrown when the TWAP interval is too short.
    error TwapTooShort();

    /// CONSTRUCTOR ///

    /// @notice Constructs the SwapManager contract.
    /// @param _swapRouter The swap router address.
    /// @param _morphoToken The Morpho token address.
    /// @param _rewardToken The reward token address.
    /// @param _twapInterval The interval for the Time-Weighted Average Price for the pair.
    constructor(
        address _swapRouter,
        address _morphoToken,
        address _rewardToken,
        uint256 _twapInterval
    ) {
        if (_twapInterval < 5 minutes) revert TwapTooShort();

        swapRouter = IUniswapV2Router02(_swapRouter);
        MORPHO = _morphoToken;
        REWARD_TOKEN = _rewardToken;
        twapInterval = _twapInterval;

        pair = IUniswapV2Pair(
            IUniswapV2Factory(swapRouter.factory()).getPair(_morphoToken, _rewardToken)
        );

        token0 = pair.token0();
        token1 = pair.token1();

        price0CumulativeLast = pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0).
        price1CumulativeLast = pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1).

        price0Average = FixedPoint.uq112x112(uint224(price0CumulativeLast));
        price1Average = FixedPoint.uq112x112(uint224(price1CumulativeLast));
    }

    /// EXTERNAL ///

    /// @notice Sets TWAP intervals.
    /// @param _twapInterval The new `twapInterval`.
    function setTwapIntervals(uint32 _twapInterval) external onlyOwner {
        if (_twapInterval < 5 minutes) revert TwapTooShort();
        twapInterval = _twapInterval;
        emit TwapIntervalSet(_twapInterval);
    }

    /// @dev Swaps reward tokens to Morpho tokens.
    /// @param _amountIn The amount of reward token to swap.
    /// @param _receiver The address of the receiver of the Morpho tokens.
    /// @return amountOut The amount of Morpho tokens sent.
    function swapToMorphoToken(uint256 _amountIn, address _receiver)
        external
        override
        returns (uint256 amountOut)
    {
        update();
        amountOut = consult(_amountIn);

        // Max slippage of 1% for the trade.
        uint256 expectedAmountOutMinimum = (amountOut * (MAX_BASIS_POINTS - ONE_PERCENT)) /
            MAX_BASIS_POINTS;

        address[] memory path = new address[](2);
        path[0] = REWARD_TOKEN;
        path[1] = MORPHO;

        // Execute the swap.
        ERC20(REWARD_TOKEN).safeApprove(address(swapRouter), _amountIn);
        uint256[] memory amountsOut = swapRouter.swapExactTokensForTokens(
            _amountIn,
            expectedAmountOutMinimum,
            path,
            _receiver,
            block.timestamp
        );

        amountOut = amountsOut[1];

        emit Swapped(_receiver, _amountIn, amountOut);
    }

    /// PUBLIC ///

    /// @notice Updates average prices on twapInterval fixed window.
    /// @dev From https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
    function update() public {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint256 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint256 timeElapsed;

        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired.
        }

        // Ensure that at least one full period has passed since the last update.
        if (timeElapsed < twapInterval) return;

        // An overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed.
        unchecked {
            price0Average = FixedPoint.uq112x112(
                uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
            );
            price1Average = FixedPoint.uq112x112(
                uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
            );
        }

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    /// @notice Returns the amount of Morpho tokens according to the price average and the `_amountIn` of reward tokens.
    /// @param _amountIn The amount of reward tokens as input.
    /// @return The amount of Morpho tokens given the `_amountIn` as input.
    function consult(uint256 _amountIn) public view returns (uint256) {
        if (MORPHO == token0) return price1Average.mul(_amountIn).decode144();
        else return price0Average.mul(_amountIn).decode144();
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _receiver
    ) ERC20(_name, _symbol) {
        _mint(_receiver, 10_000 ether);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Morpho Rewards Distributor.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice This contract allows Morpho users to claim their rewards. This contract is largely inspired by Euler Distributor's contract: https://github.com/euler-xyz/euler-contracts/blob/master/contracts/mining/EulDistributor.sol.
contract RewardsDistributor is Ownable {
    using SafeTransferLib for ERC20;

    /// STORAGE ///

    bytes32 public currRoot; // The merkle tree's root of the current rewards distribution.
    bytes32 public prevRoot; // The merkle tree's root of the previous rewards distribution.
    mapping(address => mapping(address => uint256)) public claimed; // The rewards already claimed. account -> token -> amount.

    /// EVENTS ///

    /// @notice Emitted when the root is updated.
    /// @param _newRoot The new merkle's tree root.
    event RootUpdated(bytes32 _newRoot);

    /// @notice Emitted when an account claims rewards.
    /// @param _account The address of the claimer.
    /// @param _amountClaimed The amount of rewards claimed.
    event RewardsClaimed(address _account, uint256 _amountClaimed);

    /// ERRORS ///

    /// @notice Thrown when the proof is invalid or expired.
    error ProofInvalidOrExpired();

    /// @notice Thrown when the claimer has already claimed the rewards.
    error AlreadyClaimed();

    /// EXTERNAL ///

    /// @notice Updates the current merkle tree's root.
    /// @param _newRoot The new merkle tree's root.
    function updateRoot(bytes32 _newRoot) external onlyOwner {
        prevRoot = currRoot;
        currRoot = _newRoot;
        emit RootUpdated(_newRoot);
    }

    /// @notice Claims rewards.
    /// @param _account The address of the claimer.
    /// @param _token The address of token being claimed (ie MORPHO).
    /// @param _claimable The overall claimable amount of token rewards.
    /// @param _proof The merkle proof that validates this claim.
    function claim(
        address _account,
        address _token,
        uint256 _claimable,
        bytes32[] calldata _proof
    ) external {
        bytes32 candidateRoot = MerkleProof.processProof(
            _proof,
            keccak256(abi.encodePacked(_account, _token, _claimable))
        );
        if (candidateRoot != currRoot && candidateRoot != prevRoot) revert ProofInvalidOrExpired();

        uint256 alreadyClaimed = claimed[_account][_token];
        if (_claimable <= alreadyClaimed) revert AlreadyClaimed();

        uint256 amount;
        unchecked {
            amount = _claimable - alreadyClaimed;
        }

        claimed[_account][_token] = _claimable;

        ERC20(_token).safeTransfer(_account, amount);
        emit RewardsClaimed(_account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}