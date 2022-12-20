// SPDX-License-Identifier: BUSL-1.1
// Audit of commit 9e6a33d at https://hackmd.io/7YB8QorOSs-nAAaz_f8EbQ

pragma solidity >=0.8.13;

import { IStrategy } from "./interfaces/IStrategy.sol";
import { StrategyMigrator } from "./StrategyMigrator.sol";
import { AccessControl } from "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import { SafeERC20Namer } from "@yield-protocol/utils-v2/contracts/token/SafeERC20Namer.sol";
import { MinimalTransferHelper } from "@yield-protocol/utils-v2/contracts/token/MinimalTransferHelper.sol";
import { IERC20 } from "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import { ERC20Rewards } from "@yield-protocol/utils-v2/contracts/token/ERC20Rewards.sol";
import { IFYToken } from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import { IPool } from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

/// @dev The Strategy contract allows liquidity providers to provide liquidity in yieldspace
/// pool tokens and receive strategy tokens that represent a stake in a YieldSpace pool contract.
/// Upon maturity, the strategy can `divest` from the mature pool, becoming a proportional
/// ownership underlying vault. When not invested, the strategy can `invest` into a Pool using
/// all its underlying.
/// The strategy can also `eject` from a Pool before maturity. Any fyToken obtained will be available
/// to be bought by anyone at face value. If the pool tokens can't be burned, they will be ejected
/// and the strategy can be recapitalized.
contract Strategy is AccessControl, ERC20Rewards, StrategyMigrator { // TODO: I'd like to import IStrategy
    enum State {DEPLOYED, DIVESTED, INVESTED, EJECTED, DRAINED}
    using MinimalTransferHelper for IERC20;
    using MinimalTransferHelper for IFYToken;
    using MinimalTransferHelper for IPool;

    event Invested(address indexed pool, uint256 baseInvested, uint256 lpTokensObtained);
    event Divested(address indexed pool, uint256 lpTokenDivested, uint256 baseObtained);
    event Ejected(address indexed pool, uint256 lpTokenDivested, uint256 baseObtained, uint256 fyTokenObtained);
    event Drained(address indexed pool, uint256 lpTokenDivested);
    event SoldFYToken(uint256 soldFYToken, uint256 returnedBase);

    State public state;                          // The state determines which functions are available

    // IERC20 public immutable base;             // Base token for this strategy (inherited from StrategyMigrator)
    // IFYToken public override fyToken;         // Current fyToken for this strategy (inherited from StrategyMigrator)
    IPool public pool;                           // Current pool that this strategy invests in

    uint256 public baseCached;                   // Base tokens held by the strategy
    uint256 public poolCached;                   // Pool tokens held by the strategy
    uint256 public fyTokenCached;                // In emergencies, the strategy can keep fyToken

    constructor(string memory name_, string memory symbol_, IFYToken fyToken_)
        ERC20Rewards(name_, symbol_, SafeERC20Namer.tokenDecimals(address(fyToken_)))
        StrategyMigrator(
            IERC20(fyToken_.underlying()),
            fyToken_)
    {
        // Deploy with a seriesId_ matching the migrating strategy if using the migration feature
        // Deploy with any series matching the desired base in any other case
        fyToken = fyToken_;

        base = IERC20(fyToken_.underlying());

        _grantRole(Strategy.init.selector, address(this)); // Enable the `mint` -> `init` hook.
    }

    modifier isState(State target) {
        require (
            target == state,
            "Not allowed in this state"
        );
        _;
    }

    /// @dev State and state variable management
    /// @param target State to transition to
    /// @param pool_ If transitioning to invested, update pool state variable with this parameter
    function _transition(State target, IPool pool_) internal {
        if (target == State.INVESTED) {
            pool = pool_;
            fyToken = IFYToken(address(pool_.fyToken()));
            maturity = pool_.maturity();
        } else if (target == State.DIVESTED) {
            delete fyToken;
            delete maturity;
            delete pool;
        } else if (target == State.EJECTED) {
            delete maturity;
            delete pool;
        } else if (target == State.DRAINED) {
            delete maturity;
            delete pool;
        }
        state = target;
    }

    /// @dev State and state variable management
    /// @param target State to transition to
    function _transition(State target) internal {
        require (target != State.INVESTED, "Must provide a pool");
        _transition(target, IPool(address(0)));
    }

    // ----------------------- INVEST & DIVEST --------------------------- //

    /// @notice Mock pool mint called by a strategy when trying to migrate.
    /// @dev Will initialize the strategy and return strategy tokens.
    /// It is expected that base has been transferred in, but no fyTokens
    /// @return baseIn Amount of base tokens found in contract
    /// @return fyTokenIn This is always returned as 0 since they aren't used
    /// @return minted Amount of strategy tokens minted from base tokens which is the same as baseIn
    function mint(address, address, uint256, uint256)
        external
        override
        auth
        returns (uint256 baseIn, uint256 fyTokenIn, uint256 minted)
    {
        fyTokenIn = 0; // Silence compiler warning
        baseIn = minted = _init(msg.sender);
    }

    /// @dev Mint the first strategy tokens, without investing
    /// @param to Recipient for the strategy tokens
    /// @return minted Amount of strategy tokens minted from base tokens
    function init(address to)
        external
        auth
        returns (uint256 minted)
    {
        minted = _init(to);
    }

    /// @dev Mint the first strategy tokens, without investing
    /// @param to Recipient for the strategy tokens
    /// @return minted Amount of strategy tokens minted from base tokens
    function _init(address to)
        internal
        isState(State.DEPLOYED)
        returns (uint256 minted)
    {
        // Clear fyToken in case we initialized through `mint`
        delete fyToken;

        baseCached = minted = base.balanceOf(address(this));
        require (minted > 0, "Not enough base in");
        // Make sure that at the end of the transaction the strategy has enough tokens as to not expose itself to a rounding-down liquidity attack.
        _mint(to, minted);

        _transition(State.DIVESTED);
    }

    /// @dev Start the strategy investments in the next pool
    /// @param pool_ Pool to invest into
    /// @return poolTokensObtained Amount of pool tokens minted from base tokens
    /// @notice When calling this function for the first pool, some underlying needs to be transferred to the strategy first, using a batchable router.
    function invest(IPool pool_)
        external
        auth
        isState(State.DIVESTED)
        returns (uint256 poolTokensObtained)
    {
        // Caching
        IFYToken fyToken_ = IFYToken(address(pool_.fyToken()));
        uint256 baseCached_ = baseCached; // We could read the real balance, but this is a bit safer

        require(base == pool_.base(), "Mismatched base");

        // Mint LP tokens and initialize the pool
        delete baseCached;
        base.safeTransfer(address(pool_), baseCached_);
        (,, poolTokensObtained) = pool_.init(address(this));
        poolCached = poolTokensObtained;

        // Update state variables
        fyToken = fyToken_;
        maturity = pool_.maturity();
        pool = pool_;

        _transition(State.INVESTED, pool_);
        emit Invested(address(pool_), baseCached_, poolTokensObtained);
    }

    /// @dev Divest out of a pool once it has matured
    /// @return baseObtained Amount of base tokens obtained from burning pool tokens   
    function divest()
        external
        isState(State.INVESTED)
        returns (uint256 baseObtained)
    {
        // Caching
        IPool pool_ = pool;
        IFYToken fyToken_ = fyToken;
        require (uint32(block.timestamp) >= maturity, "Only after maturity");

        uint256 toDivest = pool_.balanceOf(address(this));

        // Burn lpTokens
        delete poolCached;
        pool_.safeTransfer(address(pool_), toDivest);
        (, uint256 baseFromBurn, uint256 fyTokenFromBurn) = pool_.burn(address(this), address(this), 0, type(uint256).max); // We don't care about slippage, because the strategy holds to maturity

        // Redeem any fyToken
        uint256 baseFromRedeem = fyToken_.redeem(address(this), fyTokenFromBurn);

        // Reset the base cache
        baseCached = base.balanceOf(address(this));

        // Transition to Divested
        _transition(State.DIVESTED, pool_);
        emit Divested(address(pool_), toDivest, baseObtained = baseFromBurn + baseFromRedeem);
    }

    // ----------------------- EJECT --------------------------- //

    /// @dev Divest out of a pool at any time. If possible the pool tokens will be burnt for base and fyToken, the latter of which
    /// must be sold to return the strategy to a functional state. If the pool token burn reverts, the pool tokens will be transferred
    /// to the caller as a last resort.
    /// @return baseReceived Amount of base tokens received from pool tokens
    /// @return fyTokenReceived Amount of fyToken received from pool tokens
    /// @notice The caller must take care of slippage when selling fyToken, if relevant.
    function eject()
        external
        auth
        isState(State.INVESTED)
        returns (uint256 baseReceived, uint256 fyTokenReceived)
    {
        // Caching
        IPool pool_ = pool;
        uint256 toDivest = pool_.balanceOf(address(this));

        // Burn lpTokens, if not possible, eject the pool tokens out. Slippage should be managed by the caller.
        delete poolCached;
        try this.burnPoolTokens(pool_, toDivest) returns (uint256 baseReceived_, uint256 fyTokenReceived_) {
            baseCached = baseReceived = baseReceived_;
            fyTokenCached = fyTokenReceived = fyTokenReceived_;
            if (fyTokenReceived > 0) {
                _transition(State.EJECTED, pool_);
                emit Ejected(address(pool_), toDivest, baseReceived, fyTokenReceived);
            } else {
                _transition(State.DIVESTED, pool_);
                emit Divested(address(pool_), toDivest, baseReceived);
            }

        } catch {
            pool_.safeTransfer(msg.sender, toDivest);
            _transition(State.DRAINED, pool_);
            emit Drained(address(pool_), toDivest);
        }
    }

    /// @dev Burn an amount of pool tokens.
    /// @notice Only the Strategy itself can call this function. It is external and exists so that the transfer is reverted if the burn also reverts.
    /// @param pool_ Pool for the pool tokens.
    /// @param poolTokens Amount of tokens to burn.
    /// @return baseReceived Amount of base tokens received from pool tokens
    /// @return fyTokenReceived Amount of fyToken received from pool tokens
    function burnPoolTokens(IPool pool_, uint256 poolTokens)
        external
        returns (uint256 baseReceived, uint256 fyTokenReceived)
    {
        require (msg.sender ==  address(this), "Unauthorized");

        // Burn lpTokens
        pool_.safeTransfer(address(pool_), poolTokens);
        uint256 baseBalance = base.balanceOf(address(this));
        uint256 fyTokenBalance = fyToken.balanceOf(address(this));
        (, baseReceived, fyTokenReceived) = pool_.burn(address(this), address(this), 0, type(uint256).max);
        require(base.balanceOf(address(this)) - baseBalance == baseReceived, "Burn failed - base");
        require(fyToken.balanceOf(address(this)) - fyTokenBalance == fyTokenReceived, "Burn failed - fyToken");
    }

    /// @dev Buy ejected fyToken in the strategy at face value
    /// @param fyTokenTo Address to send the purchased fyToken to.
    /// @param baseTo Address to send any remaining base to.
    /// @return soldFYToken Amount of fyToken sold.
    /// @return returnedBase Amount of base unused and returned.
    function buyFYToken(address fyTokenTo, address baseTo)
        external
        isState(State.EJECTED)
        returns (uint256 soldFYToken, uint256 returnedBase)
    {
        // Caching
        IFYToken fyToken_ = fyToken;
        uint256 baseCached_ = baseCached;
        uint256 fyTokenCached_ = fyTokenCached;

        uint256 baseIn = base.balanceOf(address(this)) - baseCached_;
        (soldFYToken, returnedBase) = baseIn > fyTokenCached_ ? (fyTokenCached_, baseIn - fyTokenCached_) : (baseIn, 0);

        // Update base and fyToken cache
        baseCached = baseCached_ + soldFYToken; // soldFYToken is base not returned
        fyTokenCached = fyTokenCached_ -= soldFYToken;

        // Transition to divested if done
        if (fyTokenCached_ == 0) {
            // Transition to Divested
            _transition(State.DIVESTED);
            emit Divested(address(0), 0, 0);
        }

        // Transfer fyToken and base (if surplus)
        fyToken_.safeTransfer(fyTokenTo, soldFYToken);
        if (soldFYToken < baseIn) {
            base.safeTransfer(baseTo, baseIn - soldFYToken);
        }

        emit SoldFYToken(soldFYToken, returnedBase);
    }

    /// @dev If we drained the strategy, we can recapitalize it with base to avoid a forced migration
    /// @return baseIn Amount of base tokens used to restart
    function restart()
        external
        auth
        isState(State.DRAINED)
        returns (uint256 baseIn)
    {
        require((baseCached = baseIn = base.balanceOf(address(this))) > 0, "No base to restart");
        _transition(State.DIVESTED);
        emit Divested(address(0), 0, 0);
    }

    // ----------------------- MINT & BURN --------------------------- //

    /// @dev Mint strategy tokens with pool tokens. It can be called only when invested.
    /// @param to Recipient for the strategy tokens
    /// @return minted Amount of strategy tokens minted
    /// @notice The pool tokens that the user contributes need to have been transferred previously, using a batchable router.
    function mint(address to)
        external
        isState(State.INVESTED)
        returns (uint256 minted)
    {
        // Caching
        IPool pool_ = pool;
        uint256 poolCached_ = poolCached;

        // minted = supply * value(deposit) / value(strategy)

        // Find how much was deposited
        uint256 deposit = pool_.balanceOf(address(this)) - poolCached_;

        // Update the pool cache
        poolCached = poolCached_ + deposit;

        // Mint strategy tokens
        minted = _totalSupply * deposit / poolCached_;
        _mint(to, minted);
    }

    /// @dev Burn strategy tokens to withdraw pool tokens. It can be called only when invested.
    /// @param to Recipient for the pool tokens
    /// @return poolTokensObtained Amount of pool tokens obtained
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burn(address to)
        external
        isState(State.INVESTED)
        returns (uint256 poolTokensObtained)
    {
        // Caching
        IPool pool_ = pool;
        uint256 poolCached_ = poolCached;
        uint256 totalSupply_ = _totalSupply;

        // Burn strategy tokens
        uint256 burnt = _balanceOf[address(this)];
        _burn(address(this), burnt);

        poolTokensObtained = pool.balanceOf(address(this)) * burnt / totalSupply_;
        pool_.safeTransfer(address(to), poolTokensObtained);

        // Update pool cache
        poolCached = poolCached_ - poolTokensObtained;
    }

    /// @dev Mint strategy tokens with base tokens. It can be called only when not invested and not ejected.
    /// @param to Recipient for the strategy tokens
    /// @return minted Amount of strategy tokens minted
    /// @notice The base tokens that the user invests need to have been transferred previously, using a batchable router.
    function mintDivested(address to)
        external
        isState(State.DIVESTED)
        returns (uint256 minted)
    {
        // minted = supply * value(deposit) / value(strategy)
        uint256 baseCached_ = baseCached;
        uint256 deposit = base.balanceOf(address(this)) - baseCached_;
        baseCached = baseCached_ + deposit;

        minted = _totalSupply * deposit / baseCached_;

        _mint(to, minted);
    }

    /// @dev Burn strategy tokens to withdraw base tokens. It can be called when not invested and not ejected.
    /// @param to Recipient for the base tokens
    /// @return baseObtained Amount of base tokens obtained
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burnDivested(address to)
        external
        isState(State.DIVESTED)
        returns (uint256 baseObtained)
    {
        // strategy * burnt/supply = withdrawal
        uint256 baseCached_ = baseCached;
        uint256 burnt = _balanceOf[address(this)];
        baseObtained = baseCached_ * burnt / _totalSupply;
        baseCached = baseCached_ - baseObtained;

        _burn(address(this), burnt);
        base.safeTransfer(to, baseObtained);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20Permit.sol";
import "../access/AccessControl.sol";
import "../utils/RevertMsgExtractor.sol";
import "../token/MinimalTransferHelper.sol";
import "../cast/CastU256U128.sol";
import "../cast/CastU256U32.sol";


/// @dev A token inheriting from ERC20Rewards will reward token holders with a rewards token.
/// The rewarded amount will be a fixed wei per second, distributed proportionally to token holders
/// by the size of their holdings.
contract ERC20Rewards is AccessControl, ERC20Permit {
    using MinimalTransferHelper for IERC20;
    using CastU256U32 for uint256;
    using CastU256U128 for uint256;

    event RewardsTokenSet(IERC20 token);
    event RewardsSet(uint32 start, uint32 end, uint256 rate);
    event RewardsPerTokenUpdated(uint256 accumulated);
    event UserRewardsUpdated(address user, uint256 userRewards, uint256 paidRewardPerToken);
    event Claimed(address user, address receiver, uint256 claimed);

    struct RewardsPeriod {
        uint32 start;                                   // Start time for the current rewardsToken schedule
        uint32 end;                                     // End time for the current rewardsToken schedule
    }

    struct RewardsPerToken {
        uint128 accumulated;                            // Accumulated rewards per token for the period, scaled up by 1e18
        uint32 lastUpdated;                             // Last time the rewards per token accumulator was updated
        uint96 rate;                                    // Wei rewarded per second among all token holders
    }

    struct UserRewards {
        uint128 accumulated;                            // Accumulated rewards for the user until the checkpoint
        uint128 checkpoint;                             // RewardsPerToken the last time the user rewards were updated
    }

    IERC20 public rewardsToken;                         // Token used as rewards
    RewardsPeriod public rewardsPeriod;                 // Period in which rewards are accumulated by users

    RewardsPerToken public rewardsPerToken;             // Accumulator to track rewards per token               
    mapping (address => UserRewards) public rewards;    // Rewards accumulated by users
    
    constructor(string memory name, string memory symbol, uint8 decimals)
        ERC20Permit(name, symbol, decimals)
    { }

    /// @dev Return the earliest of two timestamps
    function earliest(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = (x < y) ? x : y;
    }

    /// @dev Set a rewards token.
    /// @notice Careful, this can only be done once.
    function setRewardsToken(IERC20 rewardsToken_)
        external
        auth
    {
        require(rewardsToken == IERC20(address(0)), "Rewards token already set");
        rewardsToken = rewardsToken_;
        emit RewardsTokenSet(rewardsToken_);
    }

    /// @dev Set a rewards schedule
    function setRewards(uint32 start, uint32 end, uint96 rate)
        external
        auth
    {
        require(
            start <= end,
            "Incorrect input"
        );
        require(
            rewardsToken != IERC20(address(0)),
            "Rewards token not set"
        );
        // A new rewards program can be set if one is not running
        require(
            block.timestamp.u32() < rewardsPeriod.start || block.timestamp.u32() > rewardsPeriod.end,
            "Ongoing rewards"
        );

        // Update the rewards per token so that we don't lose any rewards
        _updateRewardsPerToken();

        rewardsPeriod.start = start;
        rewardsPeriod.end = end;

        // If setting up a new rewards program, the rewardsPerToken.accumulated is used and built upon
        // New rewards start accumulating from the new rewards program start
        // Any unaccounted rewards from last program can still be added to the user rewards
        // Any unclaimed rewards can still be claimed
        rewardsPerToken.lastUpdated = start;
        rewardsPerToken.rate = rate;

        emit RewardsSet(start, end, rate);
    }

    /// @dev Update the rewards per token accumulator.
    /// @notice Needs to be called on each liquidity event
    function _updateRewardsPerToken() internal {
        RewardsPerToken memory rewardsPerToken_ = rewardsPerToken;
        RewardsPeriod memory rewardsPeriod_ = rewardsPeriod;
        uint256 totalSupply_ = _totalSupply;

        // We skip the update if the program hasn't started
        if (block.timestamp.u32() < rewardsPeriod_.start) return;

        // Find out the unaccounted time
        uint32 end = earliest(block.timestamp.u32(), rewardsPeriod_.end);
        uint256 unaccountedTime = end - rewardsPerToken_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime == 0) return; // We skip the storage changes if already updated in the same block

        // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
        // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
        if (totalSupply_ != 0) rewardsPerToken_.accumulated = (rewardsPerToken_.accumulated + 1e18 * unaccountedTime * rewardsPerToken_.rate / totalSupply_).u128(); // The rewards per token are scaled up for precision
        rewardsPerToken_.lastUpdated = end;
        rewardsPerToken = rewardsPerToken_;
        
        emit RewardsPerTokenUpdated(rewardsPerToken_.accumulated);
    }

    /// @dev Accumulate rewards for an user.
    /// @notice Needs to be called on each liquidity event, or when user balances change.
    function _updateUserRewards(address user) internal returns (uint128) {
        UserRewards memory userRewards_ = rewards[user];
        RewardsPerToken memory rewardsPerToken_ = rewardsPerToken;
        
        // Calculate and update the new value user reserves. _balanceOf[user] casts it into uint256, which is desired.
        userRewards_.accumulated = (userRewards_.accumulated + _balanceOf[user] * (rewardsPerToken_.accumulated - userRewards_.checkpoint) / 1e18).u128(); // We must scale down the rewards by the precision factor
        userRewards_.checkpoint = rewardsPerToken_.accumulated;
        rewards[user] = userRewards_;
        emit UserRewardsUpdated(user, userRewards_.accumulated, userRewards_.checkpoint);

        return userRewards_.accumulated;
    }

    /// @dev Mint tokens, after accumulating rewards for an user and update the rewards per token accumulator.
    function _mint(address dst, uint256 wad)
        internal virtual override
        returns (bool)
    {
        _updateRewardsPerToken();
        _updateUserRewards(dst);
        return super._mint(dst, wad);
    }

    /// @dev Burn tokens, after accumulating rewards for an user and update the rewards per token accumulator.
    function _burn(address src, uint256 wad)
        internal virtual override
        returns (bool)
    {
        _updateRewardsPerToken();
        _updateUserRewards(src);
        return super._burn(src, wad);
    }

    /// @dev Transfer tokens, after updating rewards for source and destination.
    function _transfer(address src, address dst, uint wad) internal virtual override returns (bool) {
        _updateRewardsPerToken();
        _updateUserRewards(src);
        _updateUserRewards(dst);
        return super._transfer(src, dst, wad);
    }

    /// @dev Claim all rewards from caller into a given address
    function claim(address to)
        external
        returns (uint256 claiming)
    {
        claiming = _claim(msg.sender, to);
    }

    /// @dev Trigger a claim for any user
    function remit(address user)
        external
        returns (uint256 claiming)
    {
        claiming = _claim(user, user);
    }

    /// @dev Claim all rewards from a user into an arbitrary receiver
    function _claim(address from, address to)
        internal
        returns (uint256 claiming)
    {
        _updateRewardsPerToken();
        claiming = _updateUserRewards(from);
        rewards[from].accumulated = 0; // A Claimed event implies the rewards were set to zero
        rewardsToken.safeTransfer(to, claiming);
        emit Claimed(from, to, claiming);
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";


// helper methods for transferring ERC20 tokens that do not consistently return true/false
library MinimalTransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
// Last audit: https://github.com/yieldprotocol/yield-utils-v2/commit/0d0b08b6b67cef6dfa69e6e6539bee542f49e25b
// Report: https://code4rena.com/reports/2021-05-yield

pragma solidity >=0.5.0;

import "../token/IERC20Metadata.sol";
import "../utils/AddressStringUtil.sol";

// produces token descriptors from inconsistent or absent ERC20 symbol implementations that can return string or bytes32
// this library will always produce a string symbol to represent the token
library SafeERC20Namer {
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    // assumes the data is in position 2
    function parseStringData(bytes memory b) private pure returns (string memory) {
        uint256 charCount = 0;
        // first parse the charCount out of the data
        for (uint256 i = 32; i < 64; i++) {
            charCount <<= 8;
            charCount += uint8(b[i]);
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 i = 0; i < charCount; i++) {
            bytesStringTrimmed[i] = b[i + 64];
        }

        return string(bytesStringTrimmed);
    }

    // uses a heuristic to produce a token name from the address
    // the heuristic returns the full hex of the address string in upper case
    function addressToName(address token) private pure returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 40);
    }

    // uses a heuristic to produce a token symbol from the address
    // the heuristic returns the first 6 hex of the address string in upper case
    function addressToSymbol(address token) private pure returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 6);
    }

    // calls an external view token contract method that returns a symbol or name, and parses the output into a string
    function callAndParseStringReturn(address token, bytes4 selector) private view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) public view returns (string memory) {
        string memory symbol = callAndParseStringReturn(token, IERC20Metadata.symbol.selector);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) public view returns (string memory) {
        string memory name = callAndParseStringReturn(token, IERC20Metadata.name.selector);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }
        return name;
    }

    /// @notice Provides a safe ERC20.decimals version which returns '0' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function tokenDecimals(address token) public view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20Metadata.decimals.selector));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC5095.sol";
import "./IJoin.sol";
import "./IOracle.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import {IStrategyMigrator} from "./IStrategyMigrator.sol";
import {IERC20} from "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";
import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";


/// @dev The Strategy contract allows liquidity providers to provide liquidity in underlying
/// and receive strategy tokens that represent a stake in a YieldSpace pool contract.
/// Upon maturity, the strategy can `divest` from the mature pool, becoming a proportional
/// ownership underlying vault. When not invested, the strategy can `invest` into a Pool using
/// all its underlying.
/// The strategy can also `eject` from a Pool before maturity, immediately converting its assets
/// to underlying as much as possible. If any fyToken can't be exchanged for underlying, the
/// strategy will hold them until maturity when `redeemEjected` can be used.
interface IStrategy is IStrategyMigrator {
    enum State {DEPLOYED, DIVESTED, INVESTED, EJECTED, DRAINED}

    function state() external view returns(State);                          // The state determines which functions are available
    function base() external view returns(IERC20);                          // Base token for this strategy (inherited from StrategyMigrator)
    function fyToken() external view returns(IFYToken);                     // Current fyToken for this strategy (inherited from StrategyMigrator)
    function pool() external view returns(IPool);                           // Current pool that this strategy invests in
    function cached() external view returns(uint256);                       // Base tokens owned by the strategy after the last operation
    function fyTokenCached() external view returns(uint256);                // In emergencies, the strategy can keep fyToken of one series

    /// @dev Mint the first strategy tokens, without investing
    function init(address to)
        external
        returns (uint256 minted);

    /// @dev Start the strategy investments in the next pool
    /// @notice When calling this function for the first pool, some underlying needs to be transferred to the strategy first, using a batchable router.
    function invest(IPool pool_)
        external
        returns (uint256 poolTokensObtained);


    /// @dev Divest out of a pool once it has matured
    function divest()
        external
        returns (uint256 baseObtained);

    /// @dev Divest out of a pool at any time. If possible the pool tokens will be burnt for base and fyToken, the latter of which
    /// must be sold to return the strategy to a functional state. If the pool token burn reverts, the pool tokens will be transferred
    /// to the caller as a last resort.
    /// @notice The caller must take care of slippage when selling fyToken, if relevant.
    function eject()
        external
        returns (uint256 baseObtained, uint256 fyTokenObtained);

    /// @dev Buy ejected fyToken in the strategy at face value
    /// @param fyTokenTo Address to send the purchased fyToken to.
    /// @param baseTo Address to send any remaining base to.
    /// @return soldFYToken Amount of fyToken sold.
    /// @return returnedBase Amount of base unused and returned.
    function buyFYToken(address fyTokenTo, address baseTo)
        external
        returns (uint256 soldFYToken, uint256 returnedBase);

    /// @dev If we ejected the pool tokens, we can recapitalize the strategy to avoid a forced migration
    function restart()
        external
        returns (uint256 baseIn);

    /// @dev Mint strategy tokens with pool tokens. It can be called only when invested.
    /// @notice The pool tokens that the user contributes need to have been transferred previously, using a batchable router.
    function mint(address to)
        external
        returns (uint256 minted);

    /// @dev Burn strategy tokens to withdraw pool tokens. It can be called only when invested.
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burn(address to)
        external
        returns (uint256 poolTokensObtained);

    /// @dev Mint strategy tokens with base tokens. It can be called only when not invested and not ejected.
    /// @notice The base tokens that the user invests need to have been transferred previously, using a batchable router.
    function mintDivested(address to)
        external
        returns (uint256 minted);
    
    /// @dev Burn strategy tokens to withdraw base tokens. It can be called when not invested and not ejected.
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burnDivested(address baseTo)
        external
        returns (uint256 baseObtained);

    /// @dev Token used as rewards
    function rewardsToken() external view returns(IERC20);
    
    /// @dev Rewards schedule
    function rewardsPeriod() external view returns(uint32 start, uint32 end);

    /// @dev Rewards per token
    function rewardsPerToken() external view returns(uint128 accumulated, uint32 lastUpdated, uint96 rate);
    
    /// @dev Rewards accumulated by users
    function rewards(address user) external view returns(uint128 accumulatedUserStart, uint128 accumulatedCheckpoint);

    /// @dev Set the rewards token
    function setRewardsToken(IERC20 rewardsToken_)
        external;

    /// @dev Set a rewards schedule
    function setRewards(uint32 start, uint32 end, uint96 rate)
        external;

    /// @dev Claim all rewards from caller into a given address
    function claim(address to)
        external
        returns (uint256 claiming);

    /// @dev Trigger a claim for any user
    function remit(address user)
        external
        returns (uint256 claiming);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IStrategyMigrator} from "./interfaces/IStrategyMigrator.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {IERC20} from "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import {ERC20Permit} from "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";


/// @dev The Migrator contract poses as a Pool to receive all assets from a Strategy
/// during a roll operation.
/// @notice The Pool and fyToken must exist. The fyToken needs to be not mature, and the pool needs to have no fyToken in it.
/// There will be no state changes on pool or fyToken.
/// TODO: For this to work, the implementing class must inherit from ERC20 and make sure that totalSupply is not zero after the `mint` call.
abstract contract StrategyMigrator is IStrategyMigrator {

    /// Mock pool base - Must match that of the calling strategy
    IERC20 public base;

    /// Mock pool fyToken - Must be set to a real fyToken registered to a series in the Cauldron, any will do
    IFYToken public fyToken;

    /// Mock pool maturity - Its contents don't matter
    uint32 public maturity;

    constructor(IERC20 base_, IFYToken fyToken_) {
        base = base_;
        fyToken = fyToken_;
    }

    /// @dev Mock pool mint. Called within `startPool`. This contract must hold 1 wei of base.
    function mint(address, address, uint256, uint256)
        external
        virtual
        returns (uint256, uint256, uint256)
    {
        return (0, 0, 0);
    }

    /// @dev Mock pool burn and make it revert so that `endPool`never suceeds, and `burnForBase` can never be called.
    function burn(address, address, uint256, uint256)
        external
        returns  (uint256, uint256, uint256)
    {
        revert();
    }

    /// @dev Mock pool getBaseBalance
    function getBaseBalance() external view returns(uint128) {
        return 0;
    }

    /// @dev Mock pool getFYTokenBalance
    function getFYTokenBalance() external view returns(uint128) {
        return 0;
    }

    /// @dev Mock pool ts
    function ts() external view returns(int128) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import {IMaturingToken} from "./IMaturingToken.sol";
import {IERC20Metadata} from  "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns(IERC20Metadata);
    function base() external view returns(IERC20);
    function burn(address baseTo, address fyTokenTo, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function burnForBase(address to, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256);
    function buyBase(address to, uint128 baseOut, uint128 max) external returns(uint128);
    function buyBasePreview(uint128 baseOut) external view returns(uint128);
    function buyFYToken(address to, uint128 fyTokenOut, uint128 max) external returns(uint128);
    function buyFYTokenPreview(uint128 fyTokenOut) external view returns(uint128);
    function currentCumulativeRatio() external view returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent);
    function cumulativeRatioLast() external view returns (uint256);
    function fyToken() external view returns(IMaturingToken);
    function g1() external view returns(int128);
    function g2() external view returns(int128);
    function getC() external view returns (int128);
    function getCurrentSharePrice() external view returns (uint256);
    function getCache() external view returns (uint104 baseCached, uint104 fyTokenCached, uint32 blockTimestampLast, uint16 g1Fee_);
    function getBaseBalance() external view returns(uint128);
    function getFYTokenBalance() external view returns(uint128);
    function getSharesBalance() external view returns(uint128);
    function init(address to) external returns (uint256, uint256, uint256);
    function maturity() external view returns(uint32);
    function mint(address to, address remainder, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function mu() external view returns (int128);
    function mintWithBase(address to, address remainder, uint256 fyTokenToBuy, uint256 minRatio, uint256 maxRatio) external returns (uint256, uint256, uint256);
    function retrieveBase(address to) external returns(uint128 retrieved);
    function retrieveFYToken(address to) external returns(uint128 retrieved);
    function retrieveShares(address to) external returns(uint128 retrieved);
    function scaleFactor() external view returns(uint96);
    function sellBase(address to, uint128 min) external returns(uint128);
    function sellBasePreview(uint128 baseIn) external view returns(uint128);
    function sellFYToken(address to, uint128 min) external returns(uint128);
    function sellFYTokenPreview(uint128 fyTokenIn) external view returns(uint128);
    function setFees(uint16 g1Fee_) external;
    function sharesToken() external view returns(IERC20Metadata);
    function ts() external view returns(int128);
    function wrap(address receiver) external returns (uint256 shares);
    function wrapPreview(uint256 assets) external view returns (uint256 shares);
    function unwrap(address receiver) external returns (uint256 assets);
    function unwrapPreview(uint256 shares) external view returns (uint256 assets);
    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128) ;
    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128) ;
    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128) ;
    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);
    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U32 {
    /// @dev Safely cast an uint256 to an u32
    function u32(uint256 x) internal pure returns (uint32 y) {
        require (x <= type(uint32).max, "Cast overflow");
        y = uint32(x);
    }
}

// SPDX-License-Identifier: MIT
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/contracts/token/ERC20/ERC20Permit.sol
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC2612.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        deploymentChainId = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(block.chainid);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid),
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _setAllowance(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

pragma solidity >=0.5.0;

library AddressStringUtil {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr, uint256 len) internal pure returns (string memory) {
        require(len % 2 == 0 && len > 0 && len <= 40, "AddressStringUtil: INVALID_LEN");
        bytes memory s = new bytes(len);
        uint256 addrNum = uint256(uint160(addr));
        for (uint256 ii = 0; ii < len ; ii +=2) {
            uint8 b = uint8(addrNum >> (4 * (38 - ii)));
            s[ii] = char(b >> 4);
            s[ii + 1] = char(b & 0x0f);
        }
        return string(s);
    }

    // hi and lo are only 4 bits and between 0 and 16
    // this method converts those values to the unicode/ascii code point for the hex representation
    // uses upper case for the characters
    function char(uint8 b) private pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x37);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";
import "./DataTypes.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Router.sol";
import "./IJoin.sol";
import "./ICauldron.sol";
import "./IFYToken.sol";
import "./IOracle.sol";
import "@yield-protocol/utils-v2/contracts/interfaces/IWETH9.sol";
import "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";

interface ILadle {
    function tokens(address) 
        external view 
        returns (bool);

    function integrations(address) 
        external view 
        returns (bool);

    function modules(address) 
        external view 
        returns (bool);

    function joins(bytes6) 
        external view 
        returns (IJoin);

    function pools(bytes6) 
        external view 
        returns (address);

    function cauldron() 
        external view
         returns(ICauldron);
    
    function router() 
        external view
         returns(Router);
    
    function weth() 
        external view
         returns(IWETH9);
    
    function borrowingFee() 
        external view
         returns(uint256);
    
    // ---- Administration ----

    /// @dev Add or remove an integration.
    function addIntegration(address integration, bool set)
        external;

    /// @dev Add or remove a token that the Ladle can call `transfer` or `permit` on.
    function addToken(address token, bool set)
        external;


    /// @dev Add a new Join for an Asset, or replace an existing one for a new one.
    /// There can be only one Join per Asset. Until a Join is added, no tokens of that Asset can be posted or withdrawn.
    function addJoin(bytes6 assetId, IJoin join)
        external;

    /// @dev Add a new Pool for a Series, or replace an existing one for a new one.
    /// There can be only one Pool per Series. Until a Pool is added, it is not possible to borrow Base.
    function addPool(bytes6 seriesId, IPool pool)
        external;

    /// @dev Add or remove a module.
    /// @notice Treat modules as you would Ladle upgrades. Modules have unrestricted access to the Ladle
    /// storage, and can wreak havoc easily.
    /// Modules must not do any changes to any vault (owner, seriesId, ilkId) because of vault caching.
    /// Modules must not be contracts that can self-destruct because of `moduleCall`.
    /// Modules can't use `msg.value` because of `batch`.
    function addModule(address module, bool set)
        external;

    /// @dev Set the fee parameter
    function setFee(uint256 fee)
        external;

    // ---- Call management ----

    /// @dev Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    function batch(bytes[] calldata calls)
        external
        returns(bytes[] memory results);

    /// @dev Allow users to route calls to a contract, to be used with batch
    function route(address integration, bytes calldata data)
        external
        returns (bytes memory result);

    /// @dev Allow users to use functionality coded in a module, to be used with batch
    function moduleCall(address module, bytes calldata data)
        external
        returns (bytes memory result);

    // ---- Token management ----

    /// @dev Execute an ERC2612 permit for the selected token
    function forwardPermit(IERC2612 token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /// @dev Execute a Dai-style permit for the selected token
    function forwardDaiPermit(IERC20 token, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        external;

    /// @dev Allow users to trigger a token transfer from themselves to a receiver through the ladle, to be used with batch
    function transfer(IERC20 token, address receiver, uint128 wad)
        external;

    /// @dev Retrieve any token in the Ladle
    function retrieve(IERC20 token, address to) 
        external
        returns (uint256 amount);

    /// @dev Accept Ether, wrap it and forward it to the WethJoin
    /// This function should be called first in a batch, and the Join should keep track of stored reserves
    /// Passing the id for a join that doesn't link to a contract implemnting IWETH9 will fail
    function joinEther(bytes6 etherId)
        external
        returns (uint256 ethTransferred);

    /// @dev Unwrap Wrapped Ether held by this Ladle, and send the Ether
    /// This function should be called last in a batch, and the Ladle should have no reason to keep an WETH balance
    function exitEther(address to)
        external
        returns (uint256 ethTransferred);

    // ---- Vault management ----

    /// @dev Create a new vault, linked to a series (and therefore underlying) and a collateral
    function build(bytes6 seriesId, bytes6 ilkId, uint8 salt)
        external virtual
        returns(bytes12, DataTypes.Vault memory);

    /// @dev Change a vault series or collateral.
    function tweak(bytes12 vaultId_, bytes6 seriesId, bytes6 ilkId)
        external
        returns(DataTypes.Vault memory vault);

    /// @dev Give a vault to another user.
    function give(bytes12 vaultId_, address receiver)
        external
        returns(DataTypes.Vault memory vault);

    /// @dev Destroy an empty vault. Used to recover gas costs.
    function destroy(bytes12 vaultId_)
        external;

    // ---- Asset and debt management ----

    /// @dev Move collateral and debt between vaults.
    function stir(bytes12 from, bytes12 to, uint128 ink, uint128 art)
        external;

    /// @dev Add collateral and borrow from vault, pull assets from and push borrowed asset to user
    /// Or, repay to vault and remove collateral, pull borrowed asset from and push assets to user
    /// Borrow only before maturity.
    function pour(bytes12 vaultId_, address to, int128 ink, int128 art)
        external;

    /// @dev Add collateral and borrow from vault, so that a precise amount of base is obtained by the user.
    /// The base is obtained by borrowing fyToken and buying base with it in a pool.
    /// Only before maturity.
    function serve(bytes12 vaultId_, address to, uint128 ink, uint128 base, uint128 max)
        external
        returns (uint128 art);

    /// @dev Repay vault debt using underlying token at a 1:1 exchange rate, without trading in a pool.
    /// It can add or remove collateral at the same time.
    /// The debt to repay is denominated in fyToken, even if the tokens pulled from the user are underlying.
    /// The debt to repay must be entered as a negative number, as with `pour`.
    /// Debt cannot be acquired with this function.
    function close(bytes12 vaultId_, address to, int128 ink, int128 art)
        external
        returns (uint128 base);

    /// @dev Repay debt by selling base in a pool and using the resulting fyToken
    /// The base tokens need to be already in the pool, unaccounted for.
    /// Only before maturity. After maturity use close.
    function repay(bytes12 vaultId_, address to, int128 ink, uint128 min)
        external
        returns (uint128 art);

    /// @dev Repay all debt in a vault by buying fyToken from a pool with base.
    /// The base tokens need to be already in the pool, unaccounted for. The surplus base will be returned to msg.sender.
    /// Only before maturity. After maturity use close.
    function repayVault(bytes12 vaultId_, address to, int128 ink, uint128 max)
        external
        returns (uint128 base);

    /// @dev Change series and debt of a vault.
    function roll(bytes12 vaultId_, bytes6 newSeriesId, uint8 loan, uint128 max)
        external
        returns (DataTypes.Vault memory vault, uint128 newDebt);

    // ---- Ladle as a token holder ----

    /// @dev Use fyToken in the Ladle to repay debt. Return unused fyToken to `to`.
    /// Return as much collateral as debt was repaid, as well. This function is only used when
    /// removing liquidity added with "Borrow and Pool", so it's safe to assume the exchange rate
    /// is 1:1. If used in other contexts, it might revert, which is fine.
    function repayFromLadle(bytes12 vaultId_, address to)
        external
        returns (uint256 repaid);

    /// @dev Use base in the Ladle to repay debt. Return unused base to `to`.
    /// Return as much collateral as debt was repaid, as well. This function is only used when
    /// removing liquidity added with "Borrow and Pool", so it's safe to assume the exchange rate
    /// is 1:1. If used in other contexts, it might revert, which is fine.
    function closeFromLadle(bytes12 vaultId_, address to)
        external
        returns (uint256 repaid);

    /// @dev Allow users to redeem fyToken, to be used with batch.
    /// If 0 is passed as the amount to redeem, it redeems the fyToken balance of the Ladle instead.
    function redeem(bytes6 seriesId, address to, uint256 wad)
        external
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {IERC20} from "@yield-protocol/utils-v2/contracts/token/IERC20.sol";


/// @dev The Migrator contract poses as a Pool to receive all assets from a Strategy
/// during a roll operation.
/// @notice The Pool and fyToken must exist. The fyToken needs to be not mature, and the pool needs to have no fyToken in it.
/// There will be no state changes on pool or fyToken.
interface IStrategyMigrator is IERC20 {

    /// @dev Mock pool base - Must match that of the calling strategy
    function base() external view returns(IERC20);

    /// @dev Mock pool fyToken - Must be set to a real fyToken registered to a series in the Cauldron, any will do
    function fyToken() external view returns(IFYToken);

    /// @dev Mock pool mint. Called within `startPool`. This contract must hold 1 wei of base.
    function mint(address, address, uint256, uint256) external returns (uint256, uint256, uint256);

    /// @dev Mock pool burn and make it revert so that `endPool`never suceeds, and `burnForBase` can never be called.
    function burn(address, address, uint256, uint256) external returns  (uint256, uint256, uint256);

    /// @dev Mock pool maturity
    function maturity() external view returns(uint32);

    /// @dev Mock pool getBaseBalance
    function getBaseBalance() external view returns(uint128);

    /// @dev Mock pool getFYTokenBalance
    function getFYTokenBalance() external view returns(uint128);

    /// @dev Mock pool ts
    function ts() external view returns(int128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFYToken.sol";
import "./IOracle.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;
import "@yield-protocol/utils-v2/contracts/utils/RevertMsgExtractor.sol";
import "@yield-protocol/utils-v2/contracts/utils/IsContract.sol";


/// @dev Router forwards calls between two contracts, so that any permissions
/// given to the original caller are stripped from the call.
/// This is useful when implementing generic call routing functions on contracts
/// that might have ERC20 approvals or AccessControl authorizations.
contract Router {
    using IsContract for address;

    address immutable public owner;

    constructor () {
        owner = msg.sender;
    }

    /// @dev Allow users to route calls to a pool, to be used with batch
    function route(address target, bytes calldata data)
        external payable
        returns (bytes memory result)
    {
        require(msg.sender == owner, "Only owner");
        require(target.isContract(), "Target is not a contract");
        bool success;
        (success, result) = target.call(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }
}

// SPDX-License-Identifier: MIT
import "../token/IERC20.sol";

pragma solidity ^0.8.0;


interface IWETH9 is IERC20 {
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT
// Taken from Address.sol from OpenZeppelin.
pragma solidity ^0.8.0;


library IsContract {
  /// @dev Returns true if `account` is a contract.
  function isContract(address account) internal view returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.
      return account.code.length > 0;
  }
}