/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File @yield-protocol/utils-v2/contracts/cast/[email protected]

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}


// File @yield-protocol/utils-v2/contracts/math/[email protected]


pragma solidity ^0.8.0;


library WDiv { // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide an amount by a fixed point factor with 18 decimals
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e18) / y;
    }
}


// File @yield-protocol/utils-v2/contracts/math/[email protected]


pragma solidity ^0.8.0;


library WMul {
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Multiply an amount by a fixed point factor with 18 decimals, rounds down.
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked { z /= 1e18; }
    }
}


// File @yield-protocol/utils-v2/contracts/math/[email protected]


pragma solidity ^0.8.0;


library WDivUp { // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide x and y, with y being fixed point. If both are integers, the result is a fixed point factor. Rounds up.
    function wdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * 1e18 + y;            // 101 (1.01) / 1000 (10) -> (101 * 100 + 1000 - 1) / 1000 -> 11 (0.11 = 0.101 rounded up).
        unchecked { z -= 1; }       // Can do unchecked subtraction since division in next line will catch y = 0 case anyway
        z /= y;
    }
}


// File @yield-protocol/utils-v2/contracts/access/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
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
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}


// File @yield-protocol/utils-v2/contracts/token/[email protected]



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity ^0.8.0;

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev amount of assets held by this contract
    function storedBalance() external view returns (uint256);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);

    /// @dev Retrieve any tokens other than the `asset`. Useful for airdropped tokens.
    function retrieve(IERC20 token, address to) external;
}


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity >=0.8.13;

interface IERC5095 is IERC20 {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address underlyingAddress);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256 timestamp);

    /// @dev Converts a specified amount of principal to underlying
    function convertToUnderlying(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Converts a specified amount of underlying to principal
    function convertToPrincipal(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Gives the maximum amount an address holder can redeem in terms of the principal
    function maxRedeem(address holder) external view returns (uint256 maxPrincipalAmount);

    /// @dev Gives the amount in terms of underlying that the princiapl amount can be redeemed for plus accrual
    function previewRedeem(uint256 principalAmount) external returns (uint256 underlyingAmount);

    /// @dev Burn fyToken after maturity for an amount of principal.
    function redeem(uint256 principalAmount, address to, address from) external returns (uint256 underlyingAmount);

    /// @dev Gives the maximum amount an address holder can withdraw in terms of the underlying
    function maxWithdraw(address holder) external returns (uint256 maxUnderlyingAmount);

    /// @dev Gives the amount in terms of principal that the underlying amount can be withdrawn for plus accrual
    function previewWithdraw(uint256 underlyingAmount) external returns (uint256 principalAmount);

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function withdraw(uint256 underlyingAmount, address to, address from) external returns (uint256 principalAmount);
}


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function peek(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @param base The asset in which the `amount` to be converted is represented
     * @param quote The asset in which the converted `value` will be represented
     * @param amount The amount to be converted from `base` to `quote`
     * @return value The converted value of `amount` from `base` to `quote`
     * @return updateTime The timestamp when the conversion price was taken
     */
    function get(
        bytes32 base,
        bytes32 quote,
        uint256 amount
    ) external returns (uint256 value, uint256 updateTime);
}


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity ^0.8.0;



interface IFYToken is IERC5095 {

    /// @dev Oracle for the savings rate.
    function oracle() view external returns (IOracle);

    /// @dev Source of redemption funds.
    function join() view external returns (IJoin); 

    /// @dev Asset to be paid out on redemption.
    function underlying() view external returns (address);

    /// @dev Yield id of the asset to be paid out on redemption.
    function underlyingId() view external returns (bytes6);

    /// @dev Time at which redemptions are enabled.
    function maturity() view external returns (uint256);

    /// @dev Spot price (exchange rate) between the base and an interest accruing token at maturity, set to 2^256-1 before maturity
    function chiAtMaturity() view external returns (uint256);
    
    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint fyToken providing an equal amount of underlying to the protocol
    function mintWithUnderlying(address to, uint256 amount) external;

    /// @dev Burn fyToken after maturity for an amount of underlying.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the fyToken in.
    /// @param fyTokenAmount Amount of fyToken to mint.
    function mint(address to, uint256 fyTokenAmount) external;

    /// @dev Burn fyToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the fyToken from.
    /// @param fyTokenAmount Amount of fyToken to burn.
    function burn(address from, uint256 fyTokenAmount) external;
}


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity ^0.8.0;


library DataTypes {
    // ======== Cauldron data types ========
    struct Series {
        IFYToken fyToken; // Redeemable token for the series.
        bytes6 baseId; // Asset received on redemption.
        uint32 maturity; // Unix time at which redemption becomes possible.
        // bytes2 free
    }

    struct Debt {
        uint96 max; // Maximum debt accepted for a given underlying, across all series
        uint24 min; // Minimum debt accepted for a given underlying, across all series
        uint8 dec; // Multiplying factor (10**dec) for max and min
        uint128 sum; // Current debt for a given underlying, across all series
    }

    struct SpotOracle {
        IOracle oracle; // Address for the spot price oracle
        uint32 ratio; // Collateralization ratio to multiply the price for
        // bytes8 free
    }

    struct Vault {
        address owner;
        bytes6 seriesId; // Each vault is related to only one series, which also determines the underlying.
        bytes6 ilkId; // Asset accepted as collateral
    }

    struct Balances {
        uint128 art; // Debt amount
        uint128 ink; // Collateral amount
    }

    // ======== Witch data types ========
    struct Auction {
        address owner;
        uint32 start;
        bytes6 baseId; // We cache the baseId here
        uint128 ink;
        uint128 art;
        address auctioneer;
        bytes6 ilkId; // We cache the ilkId here
        bytes6 seriesId; // We cache the seriesId here
    }

    struct Line {
        uint32 duration; // Time that auctions take to go to minimal price and stay there
        uint64 vaultProportion; // Proportion of the vault that is available each auction (1e18 = 100%)
        uint64 collateralProportion; // Proportion of collateral that is sold at auction start (1e18 = 100%)
    }

    struct Limits {
        uint128 max; // Maximum concurrent auctioned collateral
        uint128 sum; // Current concurrent auctioned collateral
    }
}


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity ^0.8.0;



interface ICauldron {
    /// @dev Variable rate lending oracle for an underlying
    function lendingOracles(bytes6 baseId) external view returns (IOracle);

    /// @dev An user can own one or more Vaults, with each vault being able to borrow from a single series.
    function vaults(bytes12 vault)
        external
        view
        returns (DataTypes.Vault memory);

    /// @dev Series available in Cauldron.
    function series(bytes6 seriesId)
        external
        view
        returns (DataTypes.Series memory);

    /// @dev Assets available in Cauldron.
    function assets(bytes6 assetsId) external view returns (address);

    /// @dev Each vault records debt and collateral balances_.
    function balances(bytes12 vault)
        external
        view
        returns (DataTypes.Balances memory);

    /// @dev Max, min and sum of debt per underlying and collateral.
    function debt(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.Debt memory);

    // @dev Spot price oracle addresses and collateralization ratios
    function spotOracles(bytes6 baseId, bytes6 ilkId)
        external
        view
        returns (DataTypes.SpotOracle memory);

    /// @dev Create a new vault, linked to a series (and therefore underlying) and up to 5 collateral types
    function build(
        address owner,
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vault) external;

    /// @dev Change a vault series and/or collateral types.
    function tweak(
        bytes12 vaultId,
        bytes6 seriesId,
        bytes6 ilkId
    ) external returns (DataTypes.Vault memory);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId, address receiver)
        external
        returns (DataTypes.Vault memory);

    /// @dev Move collateral and debt between vaults.
    function stir(
        bytes12 from,
        bytes12 to,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory, DataTypes.Balances memory);

    /// @dev Manipulate a vault debt and collateral.
    function pour(
        bytes12 vaultId,
        int128 ink,
        int128 art
    ) external returns (DataTypes.Balances memory);

    /// @dev Change series and debt of a vault.
    /// The module calling this function also needs to buy underlying in the pool for the new series, and sell it in pool for the old series.
    function roll(
        bytes12 vaultId,
        bytes6 seriesId,
        int128 art
    ) external returns (DataTypes.Vault memory, DataTypes.Balances memory);

    /// @dev Reduce debt and collateral from a vault, ignoring collateralization checks.
    function slurp(
        bytes12 vaultId,
        uint128 ink,
        uint128 art
    ) external returns (DataTypes.Balances memory);

    // ==== Helpers ====

    /// @dev Convert a debt amount for a series from base to fyToken terms.
    /// @notice Think about rounding if using, since we are dividing.
    function debtFromBase(bytes6 seriesId, uint128 base)
        external
        returns (uint128 art);

    /// @dev Convert a debt amount for a series from fyToken to base terms
    function debtToBase(bytes6 seriesId, uint128 art)
        external
        returns (uint128 base);

    // ==== Accounting ====

    /// @dev Record the borrowing rate at maturity for a series
    function mature(bytes6 seriesId) external;

    /// @dev Retrieve the rate accrual since maturity, maturing if necessary.
    function accrual(bytes6 seriesId) external returns (uint256);

    /// @dev Return the collateralization level of a vault. It will be negative if undercollateralized.
    function level(bytes12 vaultId) external returns (int256);
}


// File @yield-protocol/vault-v2/contracts/interfaces/[email protected]


pragma solidity ^0.8.0;


interface ILadle {
    function joins(bytes6) external view returns (IJoin);

    function pools(bytes6) external view returns (address);

    function cauldron() external view returns (ICauldron);

    function build(
        bytes6 seriesId,
        bytes6 ilkId,
        uint8 salt
    ) external returns (bytes12 vaultId, DataTypes.Vault memory vault);

    function destroy(bytes12 vaultId) external;

    function pour(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external payable;

    function serve(
        bytes12 vaultId,
        address to,
        uint128 ink,
        uint128 base,
        uint128 max
    ) external payable returns (uint128 art);

    function close(
        bytes12 vaultId,
        address to,
        int128 ink,
        int128 art
    ) external;
}


// File contracts/Witch.sol


pragma solidity >=0.8.13;









/// @title  The Witch is a DataTypes.Auction/Liquidation Engine for the Yield protocol
/// @notice The Witch grabs under-collateralised vaults, replacing the owner by itself. Then it sells
/// the vault collateral in exchange for underlying to pay its debt. The amount of collateral
/// given increases over time, until it offers to sell all the collateral for underlying to pay
/// all the debt. The auction is held open at the final price indefinitely.
/// @dev After the debt is settled, the Witch returns the vault to its original owner.
contract Witch is AccessControl {
    using WMul for uint256;
    using WDiv for uint256;
    using WDivUp for uint256;
    using CastU256U128 for uint256;

    // ==================== Errors ====================

    error VaultAlreadyUnderAuction(bytes12 vaultId, address witch);
    error VaultNotLiquidatable(bytes6 ilkId, bytes6 baseId);
    error AuctionIsCorrect(bytes12 vaultId);
    error AuctioneerRewardTooHigh(uint256 max, uint256 actual);
    error WitchIsDead();
    error CollateralLimitExceeded(uint256 current, uint256 max);
    error NotUnderCollateralised(bytes12 vaultId);
    error UnderCollateralised(bytes12 vaultId);
    error VaultNotUnderAuction(bytes12 vaultId);
    error NotEnoughBought(uint256 expected, uint256 got);
    error JoinNotFound(bytes6 id);
    error UnrecognisedParam(bytes32 param);
    error LeavesDust(uint256 remainder, uint256 min);

    // ==================== User events ====================

    event Auctioned(
        bytes12 indexed vaultId,
        DataTypes.Auction auction,
        uint256 duration,
        uint256 initialCollateralProportion
    );
    event Cancelled(bytes12 indexed vaultId);
    event Cleared(bytes12 indexed vaultId);
    event Ended(bytes12 indexed vaultId);
    event Bought(
        bytes12 indexed vaultId,
        address indexed buyer,
        uint256 ink,
        uint256 art
    );

    // ==================== Governance events ====================

    event Point(
        bytes32 indexed param,
        address indexed oldValue,
        address indexed newValue
    );
    event LineSet(
        bytes6 indexed ilkId,
        bytes6 indexed baseId,
        uint32 duration,
        uint64 vaultProportion,
        uint64 collateralProportion
    );
    event LimitSet(bytes6 indexed ilkId, bytes6 indexed baseId, uint128 max);
    event ProtectedSet(address indexed value, bool protected);
    event AuctioneerRewardSet(uint256 auctioneerReward);

    ICauldron public immutable cauldron;
    ILadle public ladle;

    uint128 public constant ONE_HUNDRED_PERCENT = 1e18;
    uint128 public constant ONE_PERCENT = 0.01e18;

    // Reward given to whomever calls `auction`. It represents a % of the bought collateral
    uint256 public auctioneerReward;

    mapping(bytes12 => DataTypes.Auction) public auctions;
    mapping(bytes6 => mapping(bytes6 => DataTypes.Line)) public lines;
    mapping(bytes6 => mapping(bytes6 => DataTypes.Limits)) public limits;
    mapping(address => bool) public protected;

    constructor(ICauldron cauldron_, ILadle ladle_) {
        cauldron = cauldron_;
        ladle = ladle_;
        auctioneerReward = ONE_PERCENT;
    }

    // ======================================================================
    // =                        Governance functions                        =
    // ======================================================================

    /// @dev Point to a different ladle
    /// @param param Name of parameter to set (must be "ladle")
    /// @param value Address of new ladle
    function point(bytes32 param, address value) external auth {
        if (param != "ladle") {
            revert UnrecognisedParam(param);
        }
        address oldLadle = address(ladle);
        ladle = ILadle(value);
        emit Point(param, oldLadle, value);
    }

    /// @dev Governance function to set the parameters that govern how much collateral is sold over time.
    /// @param ilkId Id of asset used for collateral
    /// @param baseId Id of asset used for underlying
    /// @param duration Time that auctions take to go to minimal price
    /// @param vaultProportion Vault proportion that is set for auction each time
    /// @param collateralProportion Proportion of collateral that is sold at auction start (1e18 = 100%)
    /// @param max Maximum concurrent auctioned collateral
    function setLineAndLimit(
        bytes6 ilkId,
        bytes6 baseId,
        uint32 duration,
        uint64 vaultProportion,
        uint64 collateralProportion,
        uint128 max
    ) external auth {
        require(
            collateralProportion <= ONE_HUNDRED_PERCENT,
            "Collateral Proportion above 100%"
        );
        require(
            vaultProportion <= ONE_HUNDRED_PERCENT,
            "Vault Proportion above 100%"
        );
        require(
            collateralProportion >= ONE_PERCENT,
            "Collateral Proportion below 1%"
        );
        require(vaultProportion >= ONE_PERCENT, "Vault Proportion below 1%");

        lines[ilkId][baseId] = DataTypes.Line({
            duration: duration,
            vaultProportion: vaultProportion,
            collateralProportion: collateralProportion
        });
        emit LineSet(
            ilkId,
            baseId,
            duration,
            vaultProportion,
            collateralProportion
        );

        limits[ilkId][baseId] = DataTypes.Limits({
            max: max,
            sum: limits[ilkId][baseId].sum // sum is initialized at zero, and doesn't change when changing any ilk parameters
        });
        emit LimitSet(ilkId, baseId, max);
    }

    /// @dev Governance function to protect specific vault owners from liquidations.
    /// @param owner The address that may be set/unset as protected
    /// @param _protected Is this address protected or not
    function setProtected(address owner, bool _protected) external auth {
        protected[owner] = _protected;
        emit ProtectedSet(owner, _protected);
    }

    /// @dev Governance function to set the % paid to whomever starts an auction
    /// @param auctioneerReward_ New % to be used, must have 18 dec precision
    function setAuctioneerReward(uint256 auctioneerReward_) external auth {
        if (auctioneerReward_ > ONE_HUNDRED_PERCENT) {
            revert AuctioneerRewardTooHigh(
                ONE_HUNDRED_PERCENT,
                auctioneerReward_
            );
        }
        auctioneerReward = auctioneerReward_;
        emit AuctioneerRewardSet(auctioneerReward_);
    }

    // ======================================================================
    // =                    Auction management functions                    =
    // ======================================================================

    /// @dev Put an under-collateralised vault up for liquidation
    /// @param vaultId Id of the vault to liquidate
    /// @param to Receiver of the auctioneer reward
    /// @return auction_ Info associated to the auction itself
    /// @return vault Vault that's being auctioned
    /// @return series Series for the vault that's being auctioned
    function auction(bytes12 vaultId, address to)
        external
        returns (
            DataTypes.Auction memory auction_,
            DataTypes.Vault memory vault,
            DataTypes.Series memory series
        )
    {
        // If the world has not turned to ashes and darkness, auctions will malfunction on
        // the 7th of February 2106, at 06:28:16 GMT
        // TODO: Replace this contract before then 😰
        // UPDATE: Enshrined issue in a folk song that will be remembered ✅
        if (block.timestamp > type(uint32).max) {
            revert WitchIsDead();
        }
        vault = cauldron.vaults(vaultId);
        if (auctions[vaultId].start != 0 || protected[vault.owner]) {
            revert VaultAlreadyUnderAuction(vaultId, vault.owner);
        }
        series = cauldron.series(vault.seriesId);

        DataTypes.Limits memory limits_ = limits[vault.ilkId][series.baseId];
        if (limits_.max == 0) {
            revert VaultNotLiquidatable(vault.ilkId, series.baseId);
        }
        // There is a limit on how much collateral can be concurrently put at auction, but it is a soft limit.
        // This means that the first auction to reach the limit is allowed to pass it,
        // so that there is never the situation where a vault would be too big to ever be auctioned.
        if (limits_.sum > limits_.max) {
            revert CollateralLimitExceeded(limits_.sum, limits_.max);
        }

        if (cauldron.level(vaultId) >= 0) {
            revert NotUnderCollateralised(vaultId);
        }

        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        DataTypes.Debt memory debt = cauldron.debt(series.baseId, vault.ilkId);
        DataTypes.Line memory line;

        (auction_, line) = _calcAuction(vault, series, to, balances, debt);

        limits_.sum += auction_.ink;
        limits[vault.ilkId][series.baseId] = limits_;

        auctions[vaultId] = auction_;

        vault = _auctionStarted(vaultId, auction_, line);
    }

    /// @dev Moves the vault ownership to the witch.
    /// Useful as a method so it can be overridden by specialised witches that may need to do extra accounting or notify 3rd parties
    /// @param vaultId Id of the vault to liquidate
    function _auctionStarted(
        bytes12 vaultId,
        DataTypes.Auction memory auction_,
        DataTypes.Line memory line
    ) internal virtual returns (DataTypes.Vault memory vault) {
        // The Witch is now in control of the vault under auction
        vault = cauldron.give(vaultId, address(this));
        emit Auctioned(
            vaultId,
            auction_,
            line.duration,
            line.collateralProportion
        );
    }

    /// @dev Calculates the auction initial values, the 2 non-trivial values are how much art must be repaid
    /// and what's the max ink that will be offered in exchange. For the realtime amount of ink that's on offer
    /// use `_calcPayout`
    /// @param vault Vault data
    /// @param series Series data
    /// @param to Who's gonna get the auctioneerCut
    /// @param balances Balances data
    /// @param debt Debt data
    /// @return auction_ Auction data
    /// @return line Line data
    function _calcAuction(
        DataTypes.Vault memory vault,
        DataTypes.Series memory series,
        address to,
        DataTypes.Balances memory balances,
        DataTypes.Debt memory debt
    )
        internal
        view
        returns (DataTypes.Auction memory auction_, DataTypes.Line memory line)
    {
        // We try to partially liquidate the vault if possible.
        line = lines[vault.ilkId][series.baseId];
        uint256 vaultProportion = line.vaultProportion;

        // There's a min amount of debt that a vault can hold,
        // this limit is set so liquidations are big enough to be attractive,
        // so 2 things have to be true:
        //      a) what we are putting up for liquidation has to be over the min
        //      b) what we leave in the vault has to be over the min (or zero) in case another liquidation has to be performed
        uint256 min = debt.min * (10**debt.dec);

        uint256 art;
        uint256 ink;

        if (balances.art > min) {
            // We optimistically assume the vaultProportion to be liquidated is correct.
            art = uint256(balances.art).wmul(vaultProportion);

            // If the vaultProportion we'd be liquidating is too small
            if (art < min) {
                // We up the amount to the min
                art = min;
                // We calculate the new vaultProportion of the vault that we're liquidating
                vaultProportion = art.wdivup(balances.art);
            }

            // If the debt we'd be leaving in the vault is too small
            if (balances.art - art < min) {
                // We liquidate everything
                art = balances.art;
                // Proportion is set to 100%
                vaultProportion = ONE_HUNDRED_PERCENT;
            }

            // We calculate how much ink has to be put for sale based on how much art are we asking to be repaid
            ink = uint256(balances.ink).wmul(vaultProportion);
        } else {
            // If min debt was raised, any vault that's left below the new min should be liquidated 100%
            art = balances.art;
            ink = balances.ink;
        }

        auction_ = DataTypes.Auction({
            owner: vault.owner,
            start: uint32(block.timestamp), // Overflow can't happen as max value is checked before
            seriesId: vault.seriesId,
            baseId: series.baseId,
            ilkId: vault.ilkId,
            art: art.u128(),
            ink: ink.u128(),
            auctioneer: to
        });
    }

    /// @dev Cancel an auction for a vault that isn't under-collateralised any more
    /// @param vaultId Id of the vault to remove from auction
    function cancel(bytes12 vaultId) external {
        DataTypes.Auction memory auction_ = _auction(vaultId);
        if (cauldron.level(vaultId) < 0) {
            revert UnderCollateralised(vaultId);
        }

        // Update concurrent collateral under auction
        limits[auction_.ilkId][auction_.baseId].sum -= auction_.ink;

        _auctionEnded(vaultId, auction_.owner);

        emit Cancelled(vaultId);
    }

    /// @dev Moves the vault ownership back to the original owner & clean internal state.
    /// Useful as a method so it can be overridden by specialised witches that may need to do extra accounting or notify 3rd parties
    /// @param vaultId Id of the liquidated vault
    function _auctionEnded(bytes12 vaultId, address owner) internal virtual {
        cauldron.give(vaultId, owner);
        delete auctions[vaultId];
        emit Ended(vaultId);
    }

    /// @dev Remove an auction for a vault that isn't owned by this Witch
    /// @notice Other witches or similar contracts can take vaults
    /// @param vaultId Id of the vault whose auction we will clear
    function clear(bytes12 vaultId) external {
        DataTypes.Auction memory auction_ = _auction(vaultId);
        if (cauldron.vaults(vaultId).owner == address(this)) {
            revert AuctionIsCorrect(vaultId);
        }

        // Update concurrent collateral under auction
        limits[auction_.ilkId][auction_.baseId].sum -= auction_.ink;
        delete auctions[vaultId];
        emit Cleared(vaultId);
    }

    // ======================================================================
    // =                          Bidding functions                         =
    // ======================================================================

    /// @notice If too much base is offered, only the necessary amount are taken.
    /// @dev Pay at most `maxBaseIn` of the debt in a vault in liquidation, getting at least `minInkOut` collateral.
    /// @param vaultId Id of the vault to buy
    /// @param to Receiver of the collateral bought
    /// @param minInkOut Minimum amount of collateral that must be received
    /// @param maxBaseIn Maximum amount of base that the liquidator will pay
    /// @return liquidatorCut Amount paid to `to`.
    /// @return auctioneerCut Amount paid to an address specified by whomever started the auction. 0 if it's the same as the `to` address
    /// @return baseIn Amount of underlying taken
    function payBase(
        bytes12 vaultId,
        address to,
        uint128 minInkOut,
        uint128 maxBaseIn
    )
        external
        returns (
            uint256 liquidatorCut,
            uint256 auctioneerCut,
            uint256 baseIn
        )
    {
        DataTypes.Auction memory auction_ = _auction(vaultId);

        // Find out how much debt is being repaid
        uint256 artIn = cauldron.debtFromBase(auction_.seriesId, maxBaseIn);

        // If offering too much base, take only the necessary.
        if (artIn > auction_.art) {
            artIn = auction_.art;
        }
        baseIn = cauldron.debtToBase(auction_.seriesId, artIn.u128());

        // Calculate the collateral to be sold
        (liquidatorCut, auctioneerCut) = _calcPayout(auction_, to, artIn);
        if (liquidatorCut < minInkOut) {
            revert NotEnoughBought(minInkOut, liquidatorCut);
        }

        // Update Cauldron and local auction data
        _updateAccounting(
            vaultId,
            auction_,
            (liquidatorCut + auctioneerCut).u128(),
            artIn.u128()
        );

        // Move the assets
        (liquidatorCut, auctioneerCut) = _payInk(
            auction_,
            to,
            liquidatorCut,
            auctioneerCut
        );

        if (baseIn != 0) {
            // Take underlying from liquidator
            IJoin baseJoin = ladle.joins(auction_.baseId);
            if (baseJoin == IJoin(address(0))) {
                revert JoinNotFound(auction_.baseId);
            }
            baseJoin.join(msg.sender, baseIn.u128());
        }

        _collateralBought(vaultId, to, liquidatorCut + auctioneerCut, artIn);
    }

    /// @notice If too much fyToken are offered, only the necessary amount are taken.
    /// @dev Pay up to `maxArtIn` debt from a vault in liquidation using fyToken, getting at least `minInkOut` collateral.
    /// @param vaultId Id of the vault to buy
    /// @param to Receiver for the collateral bought
    /// @param maxArtIn Maximum amount of fyToken that will be paid
    /// @param minInkOut Minimum amount of collateral that must be received
    /// @return liquidatorCut Amount paid to `to`.
    /// @return auctioneerCut Amount paid to an address specified by whomever started the auction. 0 if it's the same as the `to` address
    /// @return artIn Amount of fyToken taken
    function payFYToken(
        bytes12 vaultId,
        address to,
        uint128 minInkOut,
        uint128 maxArtIn
    )
        external
        returns (
            uint256 liquidatorCut,
            uint256 auctioneerCut,
            uint128 artIn
        )
    {
        DataTypes.Auction memory auction_ = _auction(vaultId);

        // If offering too much fyToken, take only the necessary.
        artIn = maxArtIn > auction_.art ? auction_.art : maxArtIn;

        // Calculate the collateral to be sold
        (liquidatorCut, auctioneerCut) = _calcPayout(auction_, to, artIn);
        if (liquidatorCut < minInkOut) {
            revert NotEnoughBought(minInkOut, liquidatorCut);
        }

        // Update Cauldron and local auction data
        _updateAccounting(
            vaultId,
            auction_,
            (liquidatorCut + auctioneerCut).u128(),
            artIn
        );

        // Move the assets
        (liquidatorCut, auctioneerCut) = _payInk(
            auction_,
            to,
            liquidatorCut,
            auctioneerCut
        );

        if (artIn != 0) {
            // Burn fyToken from liquidator
            cauldron.series(auction_.seriesId).fyToken.burn(msg.sender, artIn);
        }

        _collateralBought(vaultId, to, liquidatorCut + auctioneerCut, artIn);
    }

    /// @dev transfers funds from the ilkJoin to the liquidator (and potentially the auctioneer if they're different people)
    /// @param auction_ Auction data
    /// @param to Who's gonna get the `liquidatorCut`
    /// @param liquidatorCut How much collateral the liquidator is expected to get
    /// @param auctioneerCut How much collateral the auctioneer is expected to get. 0 if liquidator == auctioneer
    /// @return updated liquidatorCut & auctioneerCut
    function _payInk(
        DataTypes.Auction memory auction_,
        address to,
        uint256 liquidatorCut,
        uint256 auctioneerCut
    ) internal returns (uint256, uint256) {
        IJoin ilkJoin = ladle.joins(auction_.ilkId);
        if (ilkJoin == IJoin(address(0))) {
            revert JoinNotFound(auction_.ilkId);
        }

        // Pay auctioneer's cut if necessary
        if (auctioneerCut > 0) {
            // A transfer revert would block the auction, in that case the liquidator gets the auctioneer's cut as well
            try
                ilkJoin.exit(auction_.auctioneer, auctioneerCut.u128())
            returns (uint128) {} catch {
                liquidatorCut += auctioneerCut;
                auctioneerCut = 0;
            }
        }

        // Give collateral to the liquidator
        if (liquidatorCut > 0) {
            ilkJoin.exit(to, liquidatorCut.u128());
        }

        return (liquidatorCut, auctioneerCut);
    }

    /// @notice Update accounting on the Witch and on the Cauldron. Delete the auction and give back the vault if finished.
    /// @param vaultId Id of the liquidated vault
    /// @param auction_ Auction data
    /// @param inkOut How much collateral was sold
    /// @param artIn How much debt was repaid
    /// This function doesn't verify the vaultId matches the vault and auction passed. Check before calling.
    function _updateAccounting(
        bytes12 vaultId,
        DataTypes.Auction memory auction_,
        uint128 inkOut,
        uint128 artIn
    ) internal {
        // Duplicate check, but guarantees data integrity
        if (auction_.start == 0) {
            revert VaultNotUnderAuction(vaultId);
        }

        DataTypes.Limits memory limits_ = limits[auction_.ilkId][
            auction_.baseId
        ];

        // Update local auction
        {
            if (auction_.art == artIn) {
                // If there is no debt left, return the vault with the collateral to the owner
                _auctionEnded(vaultId, auction_.owner);

                // Update limits - reduce it by the whole auction
                limits_.sum -= auction_.ink;
            } else {
                // Ensure enough dust is left
                DataTypes.Debt memory debt = cauldron.debt(
                    auction_.baseId,
                    auction_.ilkId
                );

                uint256 remainder = auction_.art - artIn;
                uint256 min = debt.min * (10**debt.dec);
                if (remainder < min) {
                    revert LeavesDust(remainder, min);
                }

                // Update the auction
                auction_.ink -= inkOut;
                auction_.art -= artIn;

                // Store auction changes
                auctions[vaultId] = auction_;

                // Update limits - reduce it by whatever was bought
                limits_.sum -= inkOut;
            }
        }

        // Store limit changes
        limits[auction_.ilkId][auction_.baseId] = limits_;

        // Update accounting at Cauldron
        cauldron.slurp(vaultId, inkOut, artIn);
    }

    /// @dev Logs that a certain amount of a vault was liquidated
    /// Useful as a method so it can be overridden by specialised witches that may need to do extra accounting or notify 3rd parties
    /// @param vaultId Id of the liquidated vault
    /// @param buyer Who liquidated the vault
    /// @param ink How much collateral was sold
    /// @param art How much debt was repaid
    function _collateralBought(
        bytes12 vaultId,
        address buyer,
        uint256 ink,
        uint256 art
    ) internal virtual {
        emit Bought(vaultId, buyer, ink, art);
    }

    // ======================================================================
    // =                         Quoting functions                          =
    // ======================================================================

    /*

       x x x
     x      x    Hi Fren!
    x  .  .  x   I want to buy this vault under auction!  I'll pay
    x        x   you in the same `base` currency of the debt, or in fyToken, but
    x        x   I want no less than `uint min` of the collateral, ok?
    x   ===  x
    x       x
      xxxxx
        x                             __  Ok Fren!
        x     ┌────────────┐  _(\    |@@|
        xxxxxx│ BASE BUCKS │ (__/\__ \--/ __
        x     │     OR     │    \___|----|  |   __
        x     │   FYTOKEN  │        \ }{ /\ )_ / _\
       x x    └────────────┘        /\__/\ \__O (__
                                   (--/\--)    \__/
                            │      _)(  )(_
                            │     `---''---`
                            ▼
      _______
     /  12   \  First lets check how much time `t` is left on the auction
    |    |    | because that helps us determine the price we will accept
    |9   |   3| for the debt! Yay!
    |     \   |                       p + (1 - p) * t
    |         |
     \___6___/          (p is the auction starting price!)

                            │
                            │
                            ▼                  (\
                                                \ \
    Then the Cauldron updates our internal    __    \/ ___,.-------..__        __
    accounting by slurping up the debt      //\\ _,-'\\               `'--._ //\\
    and the collateral from the vault!      \\ ;'      \\                   `: //
                                             `(          \\                   )'
    The Join then dishes out the collateral    :.          \\,----,         ,;
    to you, dear user. And the debt is          `.`--.___   (    /  ___.--','
    settled with the base join or debt fyToken.   `.     ``-----'-''     ,'
                                                    -.               ,-
                                                       `-._______.-'


    */
    /// @dev quotes how much ink a liquidator is expected to get if it repays an `artIn` amount. Works for both Auctioned and ToBeAuctioned vaults
    /// @param vaultId The vault to get a quote for
    /// @param to Address that would get the collateral bought
    /// @param maxArtIn How much of the vault debt will be paid. GT than available art means all
    /// @return liquidatorCut How much collateral the liquidator is expected to get
    /// @return auctioneerCut How much collateral the auctioneer is expected to get. 0 if liquidator == auctioneer
    /// @return artIn How much debt the liquidator is expected to pay
    function calcPayout(
        bytes12 vaultId,
        address to,
        uint256 maxArtIn
    )
        external
        view
        returns (
            uint256 liquidatorCut,
            uint256 auctioneerCut,
            uint256 artIn
        )
    {
        DataTypes.Auction memory auction_ = auctions[vaultId];
        DataTypes.Vault memory vault = cauldron.vaults(vaultId);

        // If the vault hasn't been auctioned yet, we calculate what values it'd have if it was started right now
        if (auction_.start == 0) {
            DataTypes.Series memory series = cauldron.series(vault.seriesId);
            DataTypes.Balances memory balances = cauldron.balances(vaultId);
            DataTypes.Debt memory debt = cauldron.debt(
                series.baseId,
                vault.ilkId
            );
            (auction_, ) = _calcAuction(vault, series, to, balances, debt);
        }

        // GT check is to cater for partial buys right before this method executes
        artIn = maxArtIn > auction_.art ? auction_.art : maxArtIn;

        (liquidatorCut, auctioneerCut) = _calcPayout(auction_, to, artIn);
    }

    /// @notice Return how much collateral should be given out.
    /// @dev Calculate how much collateral to give for paying a certain amount of debt, at a certain time, for a certain vault.
    /// @param auction_ Auction data
    /// @param to Who's gonna get the collateral
    /// @param artIn How much debt is being repaid
    /// @return liquidatorCut how much collateral will be paid to `to`
    /// @return auctioneerCut how much collateral will be paid to whomever started the auction
    /// Formula: (artIn / totalArt) * totalInk * (initialProportion + (1 - initialProportion) * t)
    function _calcPayout(
        DataTypes.Auction memory auction_,
        address to,
        uint256 artIn
    ) internal view returns (uint256 liquidatorCut, uint256 auctioneerCut) {
        DataTypes.Line memory line_ = lines[auction_.ilkId][auction_.baseId];
        uint256 duration = line_.duration;
        uint256 initialCollateralProportion = line_.collateralProportion;

        uint256 collateralProportionNow;
        uint256 elapsed = block.timestamp - auction_.start;
        if (duration == type(uint32).max) {
            // Interpreted as infinite duration
            collateralProportionNow = initialCollateralProportion;
        } else if (elapsed >= duration) {
            collateralProportionNow = ONE_HUNDRED_PERCENT;
        } else {
            collateralProportionNow =
                initialCollateralProportion +
                ((ONE_HUNDRED_PERCENT - initialCollateralProportion) *
                    elapsed) /
                duration;
        }

        uint256 inkAtEnd = artIn.wdiv(auction_.art).wmul(auction_.ink);
        liquidatorCut = inkAtEnd.wmul(collateralProportionNow);
        if (auction_.auctioneer != to) {
            auctioneerCut = liquidatorCut.wmul(auctioneerReward);
            liquidatorCut -= auctioneerCut;
        }
    }

    /// @dev Loads the auction data for a given `vaultId` (if valid)
    /// @param vaultId Id of the vault for which we need the auction data
    /// @return auction_ Auction data for `vaultId`
    function _auction(bytes12 vaultId)
        internal
        view
        returns (DataTypes.Auction memory auction_)
    {
        auction_ = auctions[vaultId];

        if (auction_.start == 0) {
            revert VaultNotUnderAuction(vaultId);
        }
    }
}