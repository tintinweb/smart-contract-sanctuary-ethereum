// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAccessControlAngle.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlAngleUpgradeable is Initializable, IAccessControlAngle {
    // solhint-disable-next-line
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    // solhint-disable-next-line
    function __AccessControl_init_unchained() internal initializer {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external override {
        require(account == msg.sender, "71");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

library ComputePower {
    /// @notice Calculates (1+x)**n where x is a small number in base `base`
    /// @param ratePerSecond x value
    /// @param exp n value
    /// @param base Base in which the `ratePerSecond` is
    /// @dev This function avoids expensive exponentiation and the calculation is performed using a binomial approximation
    /// (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
    /// @dev This function was mostly inspired from Aave implementation and comes with the advantage of a great gas cost
    /// reduction with respect to the base power implementation
    function computePower(
        uint256 ratePerSecond,
        uint256 exp,
        uint256 base
    ) internal pure returns (uint256) {
        if (exp == 0 || ratePerSecond == 0) return base;
        uint256 halfBase = base / 2;
        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;
        uint256 basePowerTwo = (ratePerSecond * ratePerSecond + halfBase) / base;
        uint256 basePowerThree = (basePowerTwo * ratePerSecond + halfBase) / base;
        uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
        uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;
        return base + ratePerSecond * exp + secondTerm + thirdTerm;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControlAngle {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IAccessControlAngle.sol";

/// @title IGenericLender
/// @author Yearn with slight modifications from Angle Core Team
/// @dev Interface for the `GenericLender` contract, the base interface for contracts interacting
/// with lending and yield farming platforms
interface IGenericLender is IAccessControlAngle {
    /// @notice Name of the lender on which funds are invested
    function lenderName() external view returns (string memory);

    /// @notice Helper function to get the current total of assets managed by the lender.
    function nav() external view returns (uint256);

    /// @notice Reference to the `Strategy` contract the lender interacts with
    function strategy() external view returns (address);

    /// @notice Returns an estimation of the current Annual Percentage Rate on the lender
    function apr() external view returns (uint256);

    /// @notice Returns an estimation of the current Annual Percentage Rate weighted by the assets under
    /// management of the lender
    function weightedApr() external view returns (uint256);

    /// @notice Withdraws a given amount from lender
    /// @param amount The amount the caller wants to withdraw
    /// @return Amount actually withdrawn
    function withdraw(uint256 amount) external returns (uint256);

    /// @notice Withdraws as much as possible in case of emergency and sends it to the `PoolManager`
    /// @param amount Amount to withdraw
    /// @dev Does not check if any error occurs or if the amount withdrawn is correct
    function emergencyWithdraw(uint256 amount) external;

    /// @notice Deposits the current balance of the contract to the lending platform
    function deposit() external;

    /// @notice Withdraws as much as possible from the lending platform
    /// @return Whether everything was withdrawn or not
    function withdrawAll() external returns (bool);

    /// @notice Check if assets are currently managed by the lender
    /// @dev We're considering that the strategy has no assets if it has less than 10 of the
    /// underlying asset in total to avoid the case where there is dust remaining on the lending market
    /// and we cannot withdraw everything
    function hasAssets() external view returns (bool);

    /// @notice Returns an estimation of the current Annual Percentage Rate after a new deposit
    /// of `amount`
    /// @param amount Amount to add to the lending platform, and that we want to take into account
    /// in the apr computation
    function aprAfterDeposit(int256 amount) external view returns (uint256);

    /// @notice
    /// Removes tokens from this Strategy that are not the type of tokens
    /// managed by this Strategy. This may be used in case of accidentally
    /// sending the wrong kind of token to this Strategy.
    ///
    /// Tokens will be sent to `governance()`.
    ///
    /// This will fail if an attempt is made to sweep `want`, or any tokens
    /// that are protected by this Strategy.
    ///
    /// This may only be called by governance.
    /// @param _token The token to transfer out of this poolManager.
    /// @param to Address to send the tokens to.
    /// @dev
    /// Implement `_protectedTokens()` to specify any additional tokens that
    /// should be protected from sweeping in addition to `want`.
    function sweep(address _token, address to) external;

    /// @notice Returns the current balance invested on the lender and related staking contracts
    function underlyingBalanceStored() external view returns (uint256 balance);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

// Struct for the parameters associated with a strategy interacting with a collateral `PoolManager`
// contract
struct StrategyParams {
    // Timestamp of last report made by this strategy
    // It is also used to check if a strategy has been initialized
    uint256 lastReport;
    // Total amount the strategy is expected to have
    uint256 totalStrategyDebt;
    // The share of the total assets in the `PoolManager` contract that the `strategy` can access to.
    uint256 debtRatio;
}

/// @title IPoolManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the collateral poolManager contracts handling each one type of collateral for
/// a given stablecoin
/// @dev Only the functions used in other contracts of the protocol are left here
interface IPoolManagerFunctions {
    // ============================ Yield Farming ==================================

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;

    // ============================= Getters =======================================

    function getBalance() external view returns (uint256);

    function getTotalAsset() external view returns (uint256);
}

/// @title IPoolManager
/// @author Angle Core Team
/// @notice Previous interface with additional getters for public variables and mappings
/// @dev Used in other contracts of the protocol
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);

    function token() external view returns (address);

    function totalDebt() external view returns (uint256);

    function strategies(address _strategy) external view returns (StrategyParams memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IAccessControlAngle.sol";

struct LendStatus {
    string name;
    uint256 assets;
    uint256 rate;
    address add;
}

/// @title IStrategy
/// @author Inspired by Yearn with slight changes
/// @notice Interface for yield farming strategies
interface IStrategy is IAccessControlAngle {
    function estimatedAPR() external view returns (uint256);

    function poolManager() external view returns (address);

    function want() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amountNeeded) external returns (uint256 amountFreed, uint256 _loss);

    function setEmergencyExit() external;

    function addGuardian(address _guardian) external;

    function revokeGuardian(address _guardian) external;
}

// SPDX-License-Identifier: GPL-3.0

// Forked from https://github.com/euler-xyz/euler-interfaces
pragma solidity ^0.8.12;

/// @notice Main storage contract for the Euler system
interface IEulerConstants {
    /// @notice gives the maxExternalAmount in base 18
    //solhint-disable-next-line
    function MAX_SANE_AMOUNT() external view returns (uint256);
}

/// @notice Main storage contract for the Euler system
interface IEuler {
    /// @notice Lookup the current implementation contract for a module
    /// @param moduleId Fixed constant that refers to a module type (ie MODULEID__ETOKEN)
    /// @return An internal address specifies the module's implementation code
    function moduleIdToImplementation(uint256 moduleId) external view returns (address);

    /// @notice Lookup a proxy that can be used to interact with a module (only valid for single-proxy modules)
    /// @param moduleId Fixed constant that refers to a module type (ie MODULEID__MARKETS)
    /// @return An address that should be cast to the appropriate module interface, ie IEulerMarkets(moduleIdToProxy(2))
    function moduleIdToProxy(uint256 moduleId) external view returns (address);

    /// @notice Euler-related configuration for an asset
    struct AssetConfig {
        address eTokenAddress;
        bool borrowIsolated;
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint24 twapWindow;
    }
}

/// @notice Activating and querying markets, and maintaining entered markets lists
interface IEulerMarkets {
    /// @notice Create an Euler pool and associated EToken and DToken addresses.
    /// @param underlying The address of an ERC20-compliant token. There must be an initialised uniswap3 pool for the underlying/reference asset pair.
    /// @return The created EToken, or the existing EToken if already activated.
    function activateMarket(address underlying) external returns (address);

    /// @notice Create a pToken and activate it on Euler. pTokens are protected wrappers around assets that prevent borrowing.
    /// @param underlying The address of an ERC20-compliant token. There must already be an activated market on Euler for this underlying, and it must have a non-zero collateral factor.
    /// @return The created pToken, or an existing one if already activated.
    function activatePToken(address underlying) external returns (address);

    /// @notice Given an underlying, lookup the associated EToken
    /// @param underlying Token address
    /// @return EToken address, or address(0) if not activated
    function underlyingToEToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated DToken
    /// @param underlying Token address
    /// @return DToken address, or address(0) if not activated
    function underlyingToDToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated PToken
    /// @param underlying Token address
    /// @return PToken address, or address(0) if it doesn't exist
    function underlyingToPToken(address underlying) external view returns (address);

    /// @notice Looks up the Euler-related configuration for a token, and resolves all default-value placeholders to their currently configured values.
    /// @param underlying Token address
    /// @return Configuration struct
    function underlyingToAssetConfig(address underlying) external view returns (IEuler.AssetConfig memory);

    /// @notice Looks up the Euler-related configuration for a token, and returns it unresolved (with default-value placeholders)
    /// @param underlying Token address
    /// @return config Configuration struct
    function underlyingToAssetConfigUnresolved(address underlying)
        external
        view
        returns (IEuler.AssetConfig memory config);

    /// @notice Given an EToken address, looks up the associated underlying
    /// @param eToken EToken address
    /// @return underlying Token address
    function eTokenToUnderlying(address eToken) external view returns (address underlying);

    /// @notice Given an EToken address, looks up the associated DToken
    /// @param eToken EToken address
    /// @return dTokenAddr DToken address
    function eTokenToDToken(address eToken) external view returns (address dTokenAddr);

    /// @notice Looks up an asset's currently configured interest rate model
    /// @param underlying Token address
    /// @return Module ID that represents the interest rate model (IRM)
    function interestRateModel(address underlying) external view returns (uint256);

    /// @notice Retrieves the current interest rate for an asset
    /// @param underlying Token address
    /// @return The interest rate in yield-per-second, scaled by 10**27
    function interestRate(address underlying) external view returns (int96);

    /// @notice Retrieves the current interest rate accumulator for an asset
    /// @param underlying Token address
    /// @return An opaque accumulator that increases as interest is accrued
    function interestAccumulator(address underlying) external view returns (uint256);

    /// @notice Retrieves the reserve fee in effect for an asset
    /// @param underlying Token address
    /// @return Amount of interest that is redirected to the reserves, as a fraction scaled by RESERVE_FEE_SCALE (4e9)
    function reserveFee(address underlying) external view returns (uint32);

    /// @notice Retrieves the pricing config for an asset
    /// @param underlying Token address
    /// @return pricingType (1=pegged, 2=uniswap3, 3=forwarded)
    /// @return pricingParameters If uniswap3 pricingType then this represents the uniswap pool fee used, otherwise unused
    /// @return pricingForwarded If forwarded pricingType then this is the address prices are forwarded to, otherwise address(0)
    function getPricingConfig(address underlying)
        external
        view
        returns (
            uint16 pricingType,
            uint32 pricingParameters,
            address pricingForwarded
        );

    /// @notice Retrieves the list of entered markets for an account (assets enabled for collateral or borrowing)
    /// @param account User account
    /// @return List of underlying token addresses
    function getEnteredMarkets(address account) external view returns (address[] memory);

    /// @notice Add an asset to the entered market list, or do nothing if already entered
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param newMarket Underlying token address
    function enterMarket(uint256 subAccountId, address newMarket) external;

    /// @notice Remove an asset from the entered market list, or do nothing if not already present
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param oldMarket Underlying token address
    function exitMarket(uint256 subAccountId, address oldMarket) external;
}

/// @notice Definition of callback method that deferLiquidityCheck will invoke on your contract
interface IDeferredLiquidityCheck {
    function onDeferredLiquidityCheck(bytes memory data) external;
}

/// @notice Batch executions, liquidity check deferrals, and interfaces to fetch prices and account liquidity
interface IEulerExec {
    /// @notice Liquidity status for an account, either in aggregate or for a particular asset
    struct LiquidityStatus {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 numBorrows;
        bool borrowIsolated;
    }

    /// @notice Aggregate struct for reporting detailed (per-asset) liquidity for an account
    struct AssetLiquidity {
        address underlying;
        LiquidityStatus status;
    }

    /// @notice Single item in a batch request
    struct EulerBatchItem {
        bool allowError;
        address proxyAddr;
        bytes data;
    }

    /// @notice Single item in a batch response
    struct EulerBatchItemResponse {
        bool success;
        bytes result;
    }

    /// @notice Compute aggregate liquidity for an account
    /// @param account User address
    /// @return status Aggregate liquidity (sum of all entered assets)
    function liquidity(address account) external returns (LiquidityStatus memory status);

    /// @notice Compute detailed liquidity for an account, broken down by asset
    /// @param account User address
    /// @return assets List of user's entered assets and each asset's corresponding liquidity
    function detailedLiquidity(address account) external returns (AssetLiquidity[] memory assets);

    /// @notice Retrieve Euler's view of an asset's price
    /// @param underlying Token address
    /// @return twap Time-weighted average price
    /// @return twapPeriod TWAP duration, either the twapWindow value in AssetConfig, or less if that duration not available
    function getPrice(address underlying) external view returns (uint256 twap, uint256 twapPeriod);

    /// @notice Retrieve Euler's view of an asset's price, as well as the current marginal price on uniswap
    /// @param underlying Token address
    /// @return twap Time-weighted average price
    /// @return twapPeriod TWAP duration, either the twapWindow value in AssetConfig, or less if that duration not available
    /// @return currPrice The current marginal price on uniswap3 (informational: not used anywhere in the Euler protocol)
    function getPriceFull(address underlying)
        external
        returns (
            uint256 twap,
            uint256 twapPeriod,
            uint256 currPrice
        );

    /// @notice Defer liquidity checking for an account, to perform rebalancing, flash loans, etc. msg.sender must implement IDeferredLiquidityCheck
    /// @param account The account to defer liquidity for. Usually address(this), although not always
    /// @param data Passed through to the onDeferredLiquidityCheck() callback, so contracts don't need to store transient data in storage
    function deferLiquidityCheck(address account, bytes memory data) external;

    /// @notice Execute several operations in a single transaction
    /// @param items List of operations to execute
    /// @param deferLiquidityChecks List of user accounts to defer liquidity checks for
    /// @return List of operation results
    function batchDispatch(EulerBatchItem[] calldata items, address[] calldata deferLiquidityChecks)
        external
        returns (EulerBatchItemResponse[] memory);

    /// @notice Results of a batchDispatch, but with extra information
    struct EulerBatchExtra {
        EulerBatchItemResponse[] responses;
        uint256 gasUsed;
        AssetLiquidity[][] liquidities;
    }

    /// @notice Call batchDispatch, but return extra information. Only intended to be used with callStatic.
    /// @param items List of operations to execute
    /// @param deferLiquidityChecks List of user accounts to defer liquidity checks for
    /// @param queryLiquidity List of user accounts to return detailed liquidity information for
    /// @return output Structure with extra information
    function batchDispatchExtra(
        EulerBatchItem[] calldata items,
        address[] calldata deferLiquidityChecks,
        address[] calldata queryLiquidity
    ) external returns (EulerBatchExtra memory output);

    /// @notice Enable average liquidity tracking for your account. Operations will cost more gas, but you may get additional benefits when performing liquidations
    /// @param subAccountId subAccountId 0 for primary, 1-255 for a sub-account.
    /// @param delegate An address of another account that you would allow to use the benefits of your account's average liquidity (use the null address if you don't care about this). The other address must also reciprocally delegate to your account.
    /// @param onlyDelegate Set this flag to skip tracking average liquidity and only set the delegate.
    function trackAverageLiquidity(
        uint256 subAccountId,
        address delegate,
        bool onlyDelegate
    ) external;

    /// @notice Disable average liquidity tracking for your account and remove delegate
    /// @param subAccountId subAccountId 0 for primary, 1-255 for a sub-account
    function unTrackAverageLiquidity(uint256 subAccountId) external;

    /// @notice Retrieve the average liquidity for an account
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity, in terms of the reference asset, and post risk-adjustment
    function getAverageLiquidity(address account) external returns (uint256);

    /// @notice Retrieve the average liquidity for an account or a delegate account, if set
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity, in terms of the reference asset, and post risk-adjustment
    function getAverageLiquidityWithDelegate(address account) external returns (uint256);

    /// @notice Retrieve the account which delegates average liquidity for an account, if set
    /// @param account User account (xor in subAccountId, if applicable)
    /// @return The average liquidity delegate account
    function getAverageLiquidityDelegateAccount(address account) external view returns (address);

    /// @notice Transfer underlying tokens from sender's wallet into the pToken wrapper. Allowance should be set for the euler address.
    /// @param underlying Token address
    /// @param amount The amount to wrap in underlying units
    function pTokenWrap(address underlying, uint256 amount) external;

    /// @notice Transfer underlying tokens from the pToken wrapper to the sender's wallet.
    /// @param underlying Token address
    /// @param amount The amount to unwrap in underlying units
    function pTokenUnWrap(address underlying, uint256 amount) external;
}

/// @notice Tokenised representation of assets
interface IEulerEToken is IEulerConstants {
    /// @notice Pool name, ie "Euler Pool: DAI"
    function name() external view returns (string memory);

    /// @notice Pool symbol, ie "eDAI"
    function symbol() external view returns (string memory);

    /// @notice Decimals, always normalised to 18.
    function decimals() external pure returns (uint8);

    /// @notice Sum of all balances, in internal book-keeping units (non-increasing)
    function totalSupply() external view returns (uint256);

    /// @notice Sum of all balances, in underlying units (increases as interest is earned)
    function totalSupplyUnderlying() external view returns (uint256);

    /// @notice Balance of a particular account, in internal book-keeping units (non-increasing)
    function balanceOf(address account) external view returns (uint256);

    /// @notice Balance of a particular account, in underlying units (increases as interest is earned)
    function balanceOfUnderlying(address account) external view returns (uint256);

    /// @notice Balance of the reserves, in internal book-keeping units (non-increasing)
    function reserveBalance() external view returns (uint256);

    /// @notice Balance of the reserves, in underlying units (increases as interest is earned)
    function reserveBalanceUnderlying() external view returns (uint256);

    /// @notice Updates interest accumulator and totalBorrows, credits reserves, re-targets interest rate, and logs asset status
    function touch() external;

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full underlying token balance)
    function deposit(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint256 subAccountId, uint256 amount) external;

    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    /// @param balance eToken balance, in internal book-keeping units (18 decimals)
    /// @return Amount in underlying units, (same decimals as underlying token)
    function convertBalanceToUnderlying(uint256 balance) external view returns (uint256);

    /// @notice Convert an underlying amount to an eToken balance, taking into account current exchange rate
    /// @param underlyingAmount Amount in underlying units (same decimals as underlying token)
    /// @return eToken balance, in internal book-keeping units (18 decimals)
    function convertUnderlyingToBalance(uint256 underlyingAmount) external view returns (uint256);
}

interface IEulerDToken is IEulerConstants {
    /// @notice Debt token name, ie "Euler Debt: DAI"
    function name() external view returns (string memory);

    /// @notice Debt token symbol, ie "dDAI"
    function symbol() external view returns (string memory);

    /// @notice Decimals, always normalised to 18.
    function decimals() external pure returns (uint8);

    /// @notice Sum of all outstanding debts, in underlying units (increases as interest is accrued)
    function totalSupply() external view returns (uint256);

    /// @notice Sum of all outstanding debts, in underlying units with extra precision (increases as interest is accrued)
    function totalSupplyExact() external view returns (uint256);

    /// @notice Debt owed by a particular account, in underlying units
    function balanceOf(address account) external view returns (uint256);

    /// @notice Debt owed by a particular account, in underlying units with extra precision
    function balanceOfExact(address account) external view returns (uint256);

    /// @notice Transfer underlying tokens from the Euler pool to the sender, and increase sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for all available tokens)
    function borrow(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from the sender to the Euler pool, and decrease sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full debt owed)
    function repay(uint256 subAccountId, uint256 amount) external;

    /// @notice Allow spender to send an amount of dTokens to a particular sub-account
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param spender Trusted address
    /// @param amount Use max uint256 for "infinite" allowance
    function approveDebt(
        uint256 subAccountId,
        address spender,
        uint256 amount
    ) external returns (bool);

    /// @notice Retrieve the current debt allowance
    /// @param holder Xor with the desired sub-account ID (if applicable)
    /// @param spender Trusted address
    function debtAllowance(address holder, address spender) external view returns (uint256);
}

interface IBaseIRM {
    function computeInterestRate(address underlying, uint32 utilisation) external view returns (int96);
}

interface IGovernance {
    function setIRM(
        address underlying,
        uint256 interestRateModel,
        bytes calldata resetParams
    ) external;

    function setReserveFee(address underlying, uint32 newReserveFee) external;

    function getGovernorAdmin() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/interfaces/IStakingRewards.sol
interface IEulerStakingRewards {
    // Views

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    // Mutative

    function exit() external;

    function exit(uint256 subAccountId) external;

    function getReward() external;

    function stake(uint256 amount) external;

    function stake(uint256 subAccountId, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdraw(uint256 subAccountId, uint256 amount) external;

    function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../external/AccessControlAngleUpgradeable.sol";

import "../../../interfaces/IGenericLender.sol";
import "../../../interfaces/IPoolManager.sol";
import "../../../interfaces/IStrategy.sol";

import "../../../utils/Errors.sol";

/// @title GenericLenderBaseUpgradeable
/// @author Forked from https://github.com/Grandthrax/yearnV2-generic-lender-strat/tree/master/contracts/GenericLender
/// @notice A base contract to build contracts that lend assets to protocols
abstract contract GenericLenderBaseUpgradeable is IGenericLender, AccessControlAngleUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    bytes32 public constant STRATEGY_ROLE = 0x928286c473ded01ff8bf61a1986f14a0579066072fa8261442d9fea514d93a4c;
    bytes32 public constant KEEPER_ROLE = 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab;

    // ========================= REFERENCES AND PARAMETERS =========================

    /// @inheritdoc IGenericLender
    string public override lenderName;
    /// @notice Reference to the protocol's collateral poolManager
    IPoolManager public poolManager;
    /// @inheritdoc IGenericLender
    address public override strategy;
    /// @notice Reference to the token lent
    IERC20 public want;
    /// @notice Base of the asset handled by the lender
    uint256 public wantBase;
    /// @notice 1inch Aggregation router
    address internal _oneInch;

    uint256[44] private __gapBaseLender;

    // ================================ INITIALIZER ================================

    /// @notice Initializer of the `GenericLenderBase`
    /// @param _strategy Reference to the strategy using this lender
    /// @param _name Name of the lender
    /// @param governorList List of addresses with governor privilege
    /// @param guardian Address of the guardian
    /// @param keeperList List of keeper addresses
    function _initialize(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        address oneInch_
    ) internal initializer {
        _oneInch = oneInch_;
        strategy = _strategy;
        // The corresponding `PoolManager` is inferred from the `Strategy`
        poolManager = IPoolManager(IStrategy(strategy).poolManager());
        want = IERC20(poolManager.token());
        lenderName = _name;

        _setupRole(GUARDIAN_ROLE, address(poolManager));
        uint256 governorListLength = governorList.length;
        for (uint256 i; i < governorListLength; ++i) {
            _setupRole(GUARDIAN_ROLE, governorList[i]);
        }

        _setupRole(KEEPER_ROLE, guardian);
        uint256 keeperListLength = keeperList.length;
        for (uint256 i; i < keeperListLength; ++i) {
            _setupRole(KEEPER_ROLE, keeperList[i]);
        }

        _setRoleAdmin(KEEPER_ROLE, GUARDIAN_ROLE);

        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(STRATEGY_ROLE, _strategy);
        _setRoleAdmin(GUARDIAN_ROLE, STRATEGY_ROLE);
        _setRoleAdmin(STRATEGY_ROLE, GUARDIAN_ROLE);
        wantBase = 10**IERC20Metadata(address(want)).decimals();
        want.safeApprove(_strategy, type(uint256).max);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // =============================== VIEW FUNCTIONS ==============================

    /// @inheritdoc IGenericLender
    function apr() external view override returns (uint256) {
        return _apr();
    }

    /// @inheritdoc IGenericLender
    function weightedApr() external view override returns (uint256) {
        uint256 a = _apr();
        return a * _nav();
    }

    /// @inheritdoc IGenericLender
    function nav() external view override returns (uint256) {
        return _nav();
    }

    /// @inheritdoc IGenericLender
    function hasAssets() external view virtual override returns (bool) {
        return _nav() > 10 * wantBase;
    }

    /// @notice See `nav`
    function _nav() internal view returns (uint256) {
        return want.balanceOf(address(this)) + underlyingBalanceStored();
    }

    /// @notice See `apr`
    function _apr() internal view virtual returns (uint256);

    /// @notice Returns the current balance invested in the lender and related staking contracts
    function underlyingBalanceStored() public view virtual returns (uint256 balance);

    // ================================= GOVERNANCE ================================

    /// @notice Override this to add all tokens/tokenized positions this contract
    /// manages on a *persistent* basis (e.g. not just for swapping back to
    /// want ephemerally).
    ///
    /// Example:
    /// ```
    ///    function _protectedTokens() internal override view returns (address[] memory) {
    ///      address[] memory protected = new address[](3);
    ///      protected[0] = tokenA;
    ///      protected[1] = tokenB;
    ///      protected[2] = tokenC;
    ///      return protected;
    ///    }
    /// ```
    function _protectedTokens() internal view virtual returns (address[] memory);

    /// @inheritdoc IGenericLender
    function sweep(address _token, address to) external override onlyRole(GUARDIAN_ROLE) {
        address[] memory __protectedTokens = _protectedTokens();
        uint256 protectedTokensLength = __protectedTokens.length;
        for (uint256 i; i < protectedTokensLength; ++i) if (_token == __protectedTokens[i]) revert ProtectedToken();

        IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Changes allowance of a set of tokens to addresses
    /// @param tokens Addresses of the tokens for which approvals should be made
    /// @param spenders Addresses to approve
    /// @param amounts Approval amounts for each address
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyRole(GUARDIAN_ROLE) {
        if (tokens.length != spenders.length || tokens.length != amounts.length) revert IncompatibleLengths();
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @notice Changes oneInch contract address
    /// @param oneInch_ Addresses of the new 1inch api endpoint contract
    function set1Inch(address oneInch_) external onlyRole(GUARDIAN_ROLE) {
        _oneInch = oneInch_;
    }

    /// @notice Swap earned _stkAave or Aave for `want` through 1Inch
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API
    /// @dev In the case of a contract lending to Aave, tokens swapped should typically be: _stkAave -> `want` or Aave -> `want`
    function sellRewards(uint256 minAmountOut, bytes memory payload) external onlyRole(KEEPER_ROLE) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _oneInch.call(payload);
        if (!success) _revertBytes(result);

        uint256 amountOut = abi.decode(result, (uint256));
        if (amountOut < minAmountOut) revert TooSmallAmount();
    }

    /// @notice Internal function used for error handling
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length != 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert ErrorSwap();
    }

    /// @notice Changes allowance of a set of tokens to addresses
    /// @param token Address of the token for which approval should be made
    /// @param spender Address to approve
    /// @param amount Approval amount
    function _changeAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), address(spender));
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(address(spender), amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(address(spender), currentAllowance - amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { IEuler, IEulerMarkets, IEulerEToken, IEulerDToken, IBaseIRM } from "../../../../interfaces/external/euler/IEuler.sol";
import "../../../../external/ComputePower.sol";
import "./../GenericLenderBaseUpgradeable.sol";

/// @title GenericEuler
/// @author Angle Core Team
/// @notice Simple supplier to Euler markets
contract GenericEuler is GenericLenderBaseUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Base used for interest rate / power computation
    // solhint-disable-next-line
    uint256 private constant BASE_INTEREST = 10 ** 27;

    /// @notice Euler address holding assets
    // solhint-disable-next-line
    IEuler private constant _euler = IEuler(0x27182842E098f60e3D576794A5bFFb0777E025d3);
    /// @notice Euler address with data on all eTokens, debt tokens and interest rates
    // solhint-disable-next-line
    IEulerMarkets private constant _eulerMarkets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);
    // solhint-disable-next-line
    uint256 internal constant _SECONDS_IN_YEAR = 365 days;
    // solhint-disable-next-line
    uint256 private constant RESERVE_FEE_SCALE = 4_000_000_000;

    // ========================== REFERENCES TO CONTRACTS ==========================

    /// @notice Euler interest rate model for the desired token
    // solhint-disable-next-line
    IBaseIRM private irm;
    /// @notice Euler debt token
    // solhint-disable-next-line
    IEulerDToken private dToken;
    /// @notice Token given to lenders on Euler
    IEulerEToken public eToken;
    /// @notice Reserve fee on the token on Euler
    uint32 public reserveFee;

    // ================================ CONSTRUCTOR ================================

    /// @notice Initializer of the `GenericEuler`
    /// @param _strategy Reference to the strategy using this lender
    /// @param governorList List of addresses with governor privilege
    /// @param keeperList List of addresses with keeper privilege
    /// @param guardian Address of the guardian
    function initializeEuler(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        address oneInch_
    ) public {
        _initialize(_strategy, _name, governorList, guardian, keeperList, oneInch_);

        eToken = IEulerEToken(_eulerMarkets.underlyingToEToken(address(want)));
        dToken = IEulerDToken(_eulerMarkets.underlyingToDToken(address(want)));

        _setEulerPoolVariables();

        want.safeApprove(address(_euler), type(uint256).max);
    }

    // ===================== EXTERNAL PERMISSIONLESS FUNCTIONS =====================

    /// @notice Retrieves Euler variables `reserveFee` and the `irm` - rates curve -  used for the underlying token
    /// @dev No access control is needed here because values are fetched from Euler directly
    /// @dev We expect the values concerned not to be modified often
    function setEulerPoolVariables() external {
        _setEulerPoolVariables();
    }

    // ======================== EXTERNAL STRATEGY FUNCTIONS ========================

    /// @inheritdoc IGenericLender
    function deposit() external override onlyRole(STRATEGY_ROLE) {
        uint256 balance = want.balanceOf(address(this));
        eToken.deposit(0, balance);
        // We don't stake balance but the whole eToken balance
        // if some dust has been kept idle
        _stakeAll();
    }

    /// @inheritdoc IGenericLender
    function withdraw(uint256 amount) external override onlyRole(STRATEGY_ROLE) returns (uint256) {
        return _withdraw(amount);
    }

    /// @inheritdoc IGenericLender
    function withdrawAll() external override onlyRole(STRATEGY_ROLE) returns (bool) {
        uint256 invested = _nav();
        uint256 returned = _withdraw(invested);
        return returned >= invested;
    }

    // ========================== EXTERNAL VIEW FUNCTIONS ==========================

    /// @inheritdoc GenericLenderBaseUpgradeable
    function underlyingBalanceStored() public view override returns (uint256) {
        uint256 stakeAmount = _stakedBalance();
        return eToken.balanceOfUnderlying(address(this)) + stakeAmount;
    }

    /// @inheritdoc IGenericLender
    function aprAfterDeposit(int256 amount) external view override returns (uint256) {
        return _aprAfterDeposit(amount);
    }

    // ================================= GOVERNANCE ================================

    /// @inheritdoc IGenericLender
    function emergencyWithdraw(uint256 amount) external override onlyRole(GUARDIAN_ROLE) {
        _unstake(amount);
        eToken.withdraw(0, amount);
        want.safeTransfer(address(poolManager), want.balanceOf(address(this)));
    }

    function emergencyBorrow(address assetToBorrow, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        IEulerEToken eTokenBorrow = IEulerEToken(_eulerMarkets.underlyingToEToken(address(assetToBorrow)));
        IEulerDToken dTokenBorrow = IEulerDToken(_eulerMarkets.underlyingToDToken(address(assetToBorrow)));
        _eulerMarkets.enterMarket(0, address(want));
        dTokenBorrow.borrow(0, amount);
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @inheritdoc GenericLenderBaseUpgradeable
    function _apr() internal view override returns (uint256) {
        return _aprAfterDeposit(0);
    }

    /// @notice Internal version of the `aprAfterDeposit` function
    function _aprAfterDeposit(int256 amount) internal view returns (uint256) {
        uint256 totalBorrows = dToken.totalSupply();
        // Total supply is current supply + added liquidity

        uint256 totalSupply = eToken.totalSupplyUnderlying();
        if (amount >= 0) totalSupply += uint256(amount);
        else totalSupply -= uint256(-amount);

        uint256 supplyAPY;
        if (totalSupply != 0) {
            uint32 futureUtilisationRate = uint32(
                (totalBorrows * (uint256(type(uint32).max) * 1e18)) / totalSupply / 1e18
            );
            uint256 interestRate = uint256(uint96(irm.computeInterestRate(address(want), futureUtilisationRate)));
            supplyAPY = _computeAPYs(interestRate, totalBorrows, totalSupply, reserveFee);
        }

        // Adding the yield from EUL
        return supplyAPY + _stakingApr(amount);
    }

    /// @notice Computes APYs based on the interest rate, reserve fee, borrow
    /// @param borrowSPY Interest rate paid per second by borrowers
    /// @param totalBorrows Total amount borrowed on Euler of the underlying token
    /// @param totalSupplyUnderlying Total amount supplied on Euler of the underlying token
    /// @param _reserveFee Reserve fee set by governance for the underlying token
    /// @return supplyAPY The annual percentage yield received as a supplier with current settings
    function _computeAPYs(
        uint256 borrowSPY,
        uint256 totalBorrows,
        uint256 totalSupplyUnderlying,
        uint32 _reserveFee
    ) internal pure returns (uint256 supplyAPY) {
        // Not useful for the moment
        // uint256 borrowAPY = (ComputePower.computePower(borrowSPY, _SECONDS_IN_YEAR) - ComputePower.BASE_INTEREST) / 1e9;
        uint256 supplySPY = (borrowSPY * totalBorrows) / totalSupplyUnderlying;
        supplySPY = (supplySPY * (RESERVE_FEE_SCALE - _reserveFee)) / RESERVE_FEE_SCALE;
        // All rates are in base 18 on Angle strategies
        supplyAPY = (ComputePower.computePower(supplySPY, _SECONDS_IN_YEAR, BASE_INTEREST) - BASE_INTEREST) / 1e9;
    }

    /// @notice See `withdraw`
    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 stakedBalance = _stakedBalance();
        uint256 balanceUnderlying = eToken.balanceOfUnderlying(address(this));
        uint256 looseBalance = want.balanceOf(address(this));
        uint256 total = stakedBalance + balanceUnderlying + looseBalance;

        if (amount > total) {
            // Can't withdraw more than we own
            amount = total;
        }

        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }

        // Not state changing but still cheap because of previous call
        uint256 availableLiquidity = want.balanceOf(address(_euler));

        if (availableLiquidity > 1) {
            uint256 toWithdraw = amount - looseBalance;
            uint256 toUnstake;
            // We can take all
            if (toWithdraw <= availableLiquidity)
                toUnstake = toWithdraw > balanceUnderlying ? toWithdraw - balanceUnderlying : 0;
            else {
                // Take all we can
                toUnstake = availableLiquidity > balanceUnderlying ? availableLiquidity - balanceUnderlying : 0;
                toWithdraw = availableLiquidity;
            }
            if (toUnstake != 0) _unstake(toUnstake);
            eToken.withdraw(0, toWithdraw);
        }

        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }

    /// @notice Internal version of the `setEulerPoolVariables`
    function _setEulerPoolVariables() internal {
        uint256 interestRateModel = _eulerMarkets.interestRateModel(address(want));
        address moduleImpl = _euler.moduleIdToImplementation(interestRateModel);
        irm = IBaseIRM(moduleImpl);
        reserveFee = _eulerMarkets.reserveFee(address(want));
    }

    /// @inheritdoc GenericLenderBaseUpgradeable
    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(eToken);
        return protected;
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Allows the lender to stake its eTokens in an external staking contract
    function _stakeAll() internal virtual {}

    /// @notice Allows the lender to unstake its eTokens from an external staking contract
    /// @return Amount of eTokens actually unstaked
    function _unstake(uint256) internal virtual returns (uint256) {
        return 0;
    }

    /// @notice Gets the value of the eTokens currently staked
    function _stakedBalance() internal view virtual returns (uint256) {
        return (0);
    }

    /// @notice Calculates APR from Liquidity Mining Program
    /// @dev amountToAdd Amount to add to the currently supplied liquidity (for the `aprAfterDeposit` function)
    function _stakingApr(int256) internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { IEulerExec } from "../../../../interfaces/external/euler/IEuler.sol";
import "../../../../interfaces/external/euler/IEulerStakingRewards.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./GenericEuler.sol";

/// @title GenericEulerStaker
/// @author  Angle Core Team
/// @notice `GenericEuler` with staking to earn EUL incentives
contract GenericEulerStaker is GenericEuler {
    using SafeERC20 for IERC20;
    using Address for address;

    // ================================= CONSTANTS =================================
    uint32 internal constant _TWAP_PERIOD = 1 minutes;
    IEulerExec private constant _EXEC = IEulerExec(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);
    IERC20 private constant _EUL = IERC20(0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b);

    // ================================= VARIABLES =================================
    IEulerStakingRewards public eulerStakingContract;
    AggregatorV3Interface public chainlinkOracle;
    uint8 public isUniMultiplied;

    // ================================ CONSTRUCTOR ================================

    /// @notice Wrapper built on top of the `initializeEuler` method to initialize the contract
    function initialize(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        address oneInch_,
        IEulerStakingRewards _eulerStakingContract,
        AggregatorV3Interface _chainlinkOracle
    ) external {
        initializeEuler(_strategy, _name, governorList, guardian, keeperList, oneInch_);
        eulerStakingContract = _eulerStakingContract;
        chainlinkOracle = _chainlinkOracle;
        IERC20(address(eToken)).safeApprove(address(_eulerStakingContract), type(uint256).max);
        IERC20(_EUL).safeApprove(oneInch_, type(uint256).max);
    }

    // ============================= EXTERNAL FUNCTION =============================

    /// @notice Claim earned EUL
    function claimRewards() external {
        eulerStakingContract.getReward();
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @inheritdoc GenericEuler
    function _stakeAll() internal override {
        eulerStakingContract.stake(eToken.balanceOf(address(this)));
    }

    /// @inheritdoc GenericEuler
    function _unstake(uint256 amount) internal override returns (uint256 eTokensUnstaked) {
        // Take an upper bound as when withdrawing from Euler there could be rounding issue
        eTokensUnstaked = eToken.convertUnderlyingToBalance(amount) + 1;
        eulerStakingContract.withdraw(eTokensUnstaked);
    }

    /// @inheritdoc GenericEuler
    function _stakedBalance() internal view override returns (uint256 amount) {
        uint256 amountInEToken = eulerStakingContract.balanceOf(address(this));
        amount = eToken.convertBalanceToUnderlying(amountInEToken);
    }

    /// @inheritdoc GenericEuler
    function _stakingApr(int256 amount) internal view override returns (uint256 apr) {
        uint256 periodFinish = eulerStakingContract.periodFinish();
        uint256 newTotalSupply = eToken.convertBalanceToUnderlying(eulerStakingContract.totalSupply());
        if (amount >= 0) newTotalSupply += uint256(amount);
        else newTotalSupply -= uint256(-amount);
        if (periodFinish <= block.timestamp || newTotalSupply == 0) return 0;
        // APRs are in 1e18 and a 5% penalty on the EUL price is taken to avoid overestimations
        // `_estimatedEulToWant()` and eTokens are in base 18
        apr =
            (_estimatedEulToWant(eulerStakingContract.rewardRate() * _SECONDS_IN_YEAR) * 9_500 * 10**6) /
            10_000 /
            newTotalSupply;
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @notice Estimates the amount of `want` we will get out by swapping it for EUL
    /// @param quoteAmount The amount to convert in the out-currency
    /// @return The value of the `quoteAmount` expressed in out-currency
    /// @dev Uses Euler TWAP and Chainlink spot price
    function _estimatedEulToWant(uint256 quoteAmount) internal view returns (uint256) {
        (uint256 twapEUL, ) = _EXEC.getPrice(address(_EUL));
        return _quoteOracleEUL((quoteAmount * twapEUL) / 10**18);
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Return quote amount of the EUL amount
    function _quoteOracleEUL(uint256 amount) internal view virtual returns (uint256 quoteAmount) {
        // No stale checks are made as it is only used to estimate the staking APR
        (, int256 ethPriceUSD, , , ) = chainlinkOracle.latestRoundData();
        // ethPriceUSD is in base 8
        return (uint256(ethPriceUSD) * amount) / 1e8;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

error ErrorSwap();
error FailedToMint();
error FailedToRecoverETH();
error FailedToRedeem();
error FailedWithdrawal();
error IncompatibleLengths();
error IncorrectDistribution();
error IncorrectListLength();
error InvalidOracleValue();
error InvalidSender();
error InvalidSetOfParameters();
error InvalidShares();
error InvalidToken();
error InvalidWithdrawCheck();
error LenderAlreadyAdded();
error NoLockedLiquidity();
error NonExistentLender();
error PoolNotIncentivized();
error ProtectedToken();
error TooHighParameterValue();
error TooSmallAmount();
error TooSmallAmountOut();
error TooSmallStakingPeriod();
error UndockedLender();
error WrongCToken();
error ZeroAddress();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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