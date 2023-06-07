// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IVersioned } from "../utility/interfaces/IVersioned.sol";
import { Pairs, Pair } from "./Pairs.sol";
import { Token } from "../token/Token.sol";
import { Strategies, Strategy, TradeAction, Order, TradeTokens } from "./Strategies.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { IVoucher } from "../voucher/interfaces/IVoucher.sol";
import { ICarbonController } from "./interfaces/ICarbonController.sol";
import { Utils, AccessDenied } from "../utility/Utils.sol";
import { OnlyProxyDelegate } from "../utility/OnlyProxyDelegate.sol";
import { MAX_GAP } from "../utility/Constants.sol";

/**
 * @dev Carbon Controller contract
 */
contract CarbonController is
    ICarbonController,
    Pairs,
    Strategies,
    Upgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OnlyProxyDelegate,
    Utils
{
    // the emergency manager role is required to pause/unpause
    bytes32 private constant ROLE_EMERGENCY_STOPPER = keccak256("ROLE_EMERGENCY_STOPPER");

    // the fees manager role is required to withdraw fees
    bytes32 private constant ROLE_FEES_MANAGER = keccak256("ROLE_FEES_MANAGER");

    uint16 private constant CONTROLLER_TYPE = 1;

    // the voucher contract
    IVoucher private immutable _voucher;

    // upgrade forward-compatibility storage gap
    uint256[MAX_GAP] private __gap;

    error IdenticalAddresses();
    error UnnecessaryNativeTokenReceived();
    error InsufficientNativeTokenReceived();
    error DeadlineExpired();

    /**
     * @dev a "virtual" constructor that is only used to set immutable state variables
     */
    constructor(IVoucher initVoucher, address proxy) OnlyProxyDelegate(proxy) {
        _validAddress(address(initVoucher));

        _voucher = initVoucher;
    }

    /**
     * @dev fully initializes the contract and its parents
     */
    function initialize() external initializer {
        __CarbonController_init();
    }

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract and its parents
     */
    function __CarbonController_init() internal onlyInitializing {
        __Pairs_init();
        __Strategies_init();
        __Upgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        __CarbonController_init_unchained();
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __CarbonController_init_unchained() internal onlyInitializing {
        // set up administrative roles
        _setRoleAdmin(ROLE_EMERGENCY_STOPPER, ROLE_ADMIN);
        _setRoleAdmin(ROLE_FEES_MANAGER, ROLE_ADMIN);
    }

    // solhint-enable func-name-mixedcase

    /**
     * @inheritdoc Upgradeable
     */
    function version() public pure virtual override(IVersioned, Upgradeable) returns (uint16) {
        return 3;
    }

    /**
     * @dev returns the emergency stopper role
     */
    function roleEmergencyStopper() external pure returns (bytes32) {
        return ROLE_EMERGENCY_STOPPER;
    }

    /**
     * @dev returns the fees manager role
     */
    function roleFeesManager() external pure returns (bytes32) {
        return ROLE_FEES_MANAGER;
    }

    /**
     * @inheritdoc ICarbonController
     */
    function controllerType() external pure virtual returns (uint16) {
        return CONTROLLER_TYPE;
    }

    /**
     * @inheritdoc ICarbonController
     */
    function tradingFeePPM() external view returns (uint32) {
        return _tradingFeePPM;
    }

    /**
     * @dev sets the trading fee (in units of PPM)
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setTradingFeePPM(uint32 newTradingFeePPM) external onlyAdmin validFee(newTradingFeePPM) {
        _setTradingFeePPM(newTradingFeePPM);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function createPair(
        Token token0,
        Token token1
    ) external nonReentrant whenNotPaused onlyProxyDelegate returns (Pair memory) {
        _validateInputTokens(token0, token1);
        return _createPair(token0, token1);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function pairs() external view returns (Token[2][] memory) {
        return _pairs();
    }

    /**
     * @inheritdoc ICarbonController
     */
    function pair(Token token0, Token token1) external view returns (Pair memory) {
        _validateInputTokens(token0, token1);
        return _pair(token0, token1);
    }

    // solhint-disable var-name-mixedcase

    /**
     * @inheritdoc ICarbonController
     */
    function createStrategy(
        Token token0,
        Token token1,
        Order[2] calldata orders
    ) external payable nonReentrant whenNotPaused onlyProxyDelegate returns (uint256) {
        _validateInputTokens(token0, token1);

        // don't allow unnecessary eth
        if (msg.value > 0 && !token0.isNative() && !token1.isNative()) {
            revert UnnecessaryNativeTokenReceived();
        }

        // revert if any of the orders is invalid
        _validateOrders(orders);

        // create the pair if it does not exist
        Pair memory strategyPair;
        if (!_pairExists(token0, token1)) {
            strategyPair = _createPair(token0, token1);
        } else {
            strategyPair = _pair(token0, token1);
        }

        Token[2] memory tokens = [token0, token1];
        return _createStrategy(_voucher, tokens, orders, strategyPair, msg.sender, msg.value);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function updateStrategy(
        uint256 strategyId,
        Order[2] calldata currentOrders,
        Order[2] calldata newOrders
    ) external payable nonReentrant whenNotPaused onlyProxyDelegate {
        Pair memory strategyPair = _pairById(_pairIdByStrategyId(strategyId));

        // only the owner of the strategy is allowed to delete it
        if (msg.sender != _voucher.ownerOf(strategyId)) {
            revert AccessDenied();
        }

        // don't allow unnecessary eth
        if (msg.value > 0 && !strategyPair.tokens[0].isNative() && !strategyPair.tokens[1].isNative()) {
            revert UnnecessaryNativeTokenReceived();
        }

        // revert if any of the orders is invalid
        _validateOrders(newOrders);

        // perform update
        _updateStrategy(strategyId, currentOrders, newOrders, strategyPair, msg.sender, msg.value);
    }

    // solhint-enable var-name-mixedcase

    /**
     * @inheritdoc ICarbonController
     */
    function deleteStrategy(uint256 strategyId) external nonReentrant whenNotPaused onlyProxyDelegate {
        // find strategy, reverts if none
        Pair memory strategyPair = _pairById(_pairIdByStrategyId(strategyId));

        // only the owner of the strategy is allowed to delete it
        if (msg.sender != _voucher.ownerOf(strategyId)) {
            revert AccessDenied();
        }

        // delete strategy
        _deleteStrategy(strategyId, _voucher, strategyPair);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function strategy(uint256 id) external view returns (Strategy memory) {
        Pair memory strategyPair = _pairById(_pairIdByStrategyId(id));
        return _strategy(id, _voucher, strategyPair);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function strategiesByPair(
        Token token0,
        Token token1,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (Strategy[] memory) {
        _validateInputTokens(token0, token1);

        Pair memory strategyPair = _pair(token0, token1);
        return _strategiesByPair(strategyPair, startIndex, endIndex, _voucher);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function strategiesByPairCount(Token token0, Token token1) external view returns (uint256) {
        _validateInputTokens(token0, token1);

        Pair memory strategyPair = _pair(token0, token1);
        return _strategiesByPairCount(strategyPair);
    }

    /**
     * @inheritdoc ICarbonController
     */
    function tradeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions,
        uint256 deadline,
        uint128 minReturn
    ) external payable nonReentrant whenNotPaused onlyProxyDelegate returns (uint128) {
        _validateTradeParams(sourceToken, targetToken, deadline, msg.value, minReturn);
        Pair memory _pair = _pair(sourceToken, targetToken);
        TradeParams memory params = TradeParams({
            trader: msg.sender,
            tokens: TradeTokens({ source: sourceToken, target: targetToken }),
            byTargetAmount: false,
            constraint: minReturn,
            txValue: msg.value,
            pair: _pair,
            sourceAmount: 0,
            targetAmount: 0
        });
        _trade(tradeActions, params);
        return params.targetAmount;
    }

    /**
     * @inheritdoc ICarbonController
     */
    function tradeByTargetAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions,
        uint256 deadline,
        uint128 maxInput
    ) external payable nonReentrant whenNotPaused onlyProxyDelegate returns (uint128) {
        _validateTradeParams(sourceToken, targetToken, deadline, msg.value, maxInput);

        if (sourceToken.isNative()) {
            // tx's value should at least match the maxInput
            if (msg.value < maxInput) {
                revert InsufficientNativeTokenReceived();
            }
        }

        Pair memory _pair = _pair(sourceToken, targetToken);
        TradeParams memory params = TradeParams({
            trader: msg.sender,
            tokens: TradeTokens({ source: sourceToken, target: targetToken }),
            byTargetAmount: true,
            constraint: maxInput,
            txValue: msg.value,
            pair: _pair,
            sourceAmount: 0,
            targetAmount: 0
        });
        _trade(tradeActions, params);
        return params.sourceAmount;
    }

    /**
     * @inheritdoc ICarbonController
     */
    function calculateTradeSourceAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions
    ) external view returns (uint128) {
        _validateInputTokens(sourceToken, targetToken);
        Pair memory strategyPair = _pair(sourceToken, targetToken);
        TradeTokens memory tokens = TradeTokens({ source: sourceToken, target: targetToken });
        SourceAndTargetAmounts memory amounts = _tradeSourceAndTargetAmounts(tokens, tradeActions, strategyPair, true);
        return amounts.sourceAmount;
    }

    /**
     * @inheritdoc ICarbonController
     */
    function calculateTradeTargetAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions
    ) external view returns (uint128) {
        _validateInputTokens(sourceToken, targetToken);
        Pair memory strategyPair = _pair(sourceToken, targetToken);
        TradeTokens memory tokens = TradeTokens({ source: sourceToken, target: targetToken });
        SourceAndTargetAmounts memory amounts = _tradeSourceAndTargetAmounts(tokens, tradeActions, strategyPair, false);
        return amounts.targetAmount;
    }

    /**
     * @inheritdoc ICarbonController
     */
    function accumulatedFees(Token token) external view validAddress(Token.unwrap(token)) returns (uint256) {
        return _accumulatedFees[token];
    }

    /**
     * @inheritdoc ICarbonController
     */
    function withdrawFees(
        Token token,
        uint256 amount,
        address recipient
    )
        external
        whenNotPaused
        onlyRoleMember(ROLE_FEES_MANAGER)
        validAddress(recipient)
        validAddress(Token.unwrap(token))
        greaterThanZero(amount)
        nonReentrant
        returns (uint256)
    {
        return _withdrawFees(msg.sender, amount, token, recipient);
    }

    /**
     * @dev pauses the CarbonController
     *
     * requirements:
     *
     * - the caller must have the ROLE_EMERGENCY_STOPPER privilege
     */
    function pause() external onlyRoleMember(ROLE_EMERGENCY_STOPPER) {
        _pause();
    }

    /**
     * @dev resumes the CarbonController
     *
     * requirements:
     *
     * - the caller must have the ROLE_EMERGENCY_STOPPER privilege
     */
    function unpause() external onlyRoleMember(ROLE_EMERGENCY_STOPPER) {
        _unpause();
    }

    /**
     * @dev validates both tokens are valid addresses and unique
     */
    function _validateInputTokens(
        Token token0,
        Token token1
    ) private pure validAddress(Token.unwrap(token0)) validAddress(Token.unwrap(token1)) {
        if (token0 == token1) {
            revert IdenticalAddresses();
        }
    }

    /**
     * performs all necessary validations on the trade parameters
     */
    function _validateTradeParams(
        Token sourceToken,
        Token targetToken,
        uint256 deadline,
        uint256 value,
        uint128 constraint
    ) private view {
        // revert if deadline has passed
        if (deadline < block.timestamp) {
            revert DeadlineExpired();
        }

        // validate minReturn / maxInput
        _greaterThanZero(constraint);

        // make sure source and target tokens are valid
        _validateInputTokens(sourceToken, targetToken);

        // there shouldn't be any native token sent unless the source token is the native token
        if (value > 0 && !sourceToken.isNative()) {
            revert UnnecessaryNativeTokenReceived();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
library SafeCastUpgradeable {
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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Token } from "../token/Token.sol";
import { MAX_GAP } from "../utility/Constants.sol";

struct Pair {
    uint128 id;
    Token[2] tokens;
}

abstract contract Pairs is Initializable {
    error PairAlreadyExists();
    error PairDoesNotExist();

    // unique incremental id representing a pair
    uint128 private _lastPairId;

    // mapping of pairs of tokens to their pair id, tokens are sorted at any order
    mapping(Token => mapping(Token => uint128)) private _pairIds;

    // mapping between a pairId to its Pair object
    mapping(uint128 => Token[2]) private _pairsStorage;

    // upgrade forward-compatibility storage gap
    uint256[MAX_GAP - 3] private __gap;

    /**
     * @dev triggered when a new pair is created
     */
    event PairCreated(uint128 indexed pairId, Token indexed token0, Token indexed token1);

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract and its parents
     */
    function __Pairs_init() internal onlyInitializing {
        __Pairs_init_unchained();
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __Pairs_init_unchained() internal onlyInitializing {}

    // solhint-enable func-name-mixedcase

    /**
     * @dev generates and stores a new pair, tokens are assumed unique and valid
     */
    function _createPair(Token token0, Token token1) internal returns (Pair memory) {
        // validate pair existence
        if (_pairExists(token0, token1)) {
            revert PairAlreadyExists();
        }

        // sort tokens
        Token[2] memory sortedTokens = _sortTokens(token0, token1);

        // increment pair id
        uint128 id = _lastPairId + 1;
        _lastPairId = id;

        // store pair
        _pairsStorage[id] = sortedTokens;
        _pairIds[sortedTokens[0]][sortedTokens[1]] = id;

        emit PairCreated(id, sortedTokens[0], sortedTokens[1]);
        return Pair({ id: id, tokens: sortedTokens });
    }

    /**
     * @dev return a pair matching the given tokens
     */
    function _pair(Token token0, Token token1) internal view returns (Pair memory) {
        // validate pair existence
        if (!_pairExists(token0, token1)) {
            revert PairDoesNotExist();
        }

        // sort tokens
        Token[2] memory sortedTokens = _sortTokens(token0, token1);

        // return pair
        uint128 id = _pairIds[sortedTokens[0]][sortedTokens[1]];
        return Pair({ id: id, tokens: sortedTokens });
    }

    function _pairById(uint128 pairId) internal view returns (Pair memory) {
        Token[2] memory tokens = _pairsStorage[pairId];
        if (Token.unwrap(tokens[0]) == address(0)) {
            revert PairDoesNotExist();
        }
        return Pair({ id: pairId, tokens: tokens });
    }

    /**
     * @dev check for the existence of a pair (pair id's are sequential integers starting at 1)
     */
    function _pairExists(Token token0, Token token1) internal view returns (bool) {
        // sort tokens
        Token[2] memory sortedTokens = _sortTokens(token0, token1);

        if (_pairIds[sortedTokens[0]][sortedTokens[1]] == 0) {
            return false;
        }
        return true;
    }

    /**
     * @dev returns a list of all supported pairs
     */
    function _pairs() internal view returns (Token[2][] memory) {
        uint128 length = _lastPairId;
        Token[2][] memory list = new Token[2][](length);
        for (uint128 i = 0; i < length; i++) {
            list[i] = _pairsStorage[i + 1];
        }

        return list;
    }

    /**
     * returns the given tokens sorted by address value, smaller first
     */
    function _sortTokens(Token token0, Token token1) private pure returns (Token[2] memory) {
        return Token.unwrap(token0) < Token.unwrap(token1) ? [token0, token1] : [token1, token0];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { MathEx } from "../utility/MathEx.sol";
import { InvalidIndices } from "../utility/Utils.sol";
import { Token } from "../token/Token.sol";
import { Pair } from "./Pairs.sol";
import { IVoucher } from "../voucher/interfaces/IVoucher.sol";
import { PPM_RESOLUTION } from "../utility/Constants.sol";
import { MAX_GAP } from "../utility/Constants.sol";

/**
 * @dev:
 *
 * a strategy consists of two orders:
 * - order 0 sells `y0` units of token 0 at a marginal rate `M0` ranging between `L0` and `H0`
 * - order 1 sells `y1` units of token 1 at a marginal rate `M1` ranging between `L1` and `H1`
 *
 * rate symbols:
 * - `L0` indicates the lowest value of one wei of token 0 in units of token 1
 * - `H0` indicates the highest value of one wei of token 0 in units of token 1
 * - `M0` indicates the marginal value of one wei of token 0 in units of token 1
 * - `L1` indicates the lowest value of one wei of token 1 in units of token 0
 * - `H1` indicates the highest value of one wei of token 1 in units of token 0
 * - `M1` indicates the marginal value of one wei of token 1 in units of token 0
 *
 * the term "one wei" serves here as a simplification of "an amount tending to zero",
 * hence the rate values above are all theoretical.
 * moreover, since trade calculation is based on the square roots of the rates,
 * an order doesn't actually hold the rate values, but a modified version of them.
 * for each rate `r`, the order maintains:
 * - mantissa: the value of the 48 most significant bits of `floor(sqrt(r) * 2 ^ 48)`
 * - exponent: the number of the remaining (least significant) bits, limited up to 48
 * this allows for rates between ~12.6e-28 and ~7.92e+28, at an average resolution of ~2.81e+14.
 * it also ensures that every rate value `r` is supported if and only if `1 / r` is supported.
 * however, it also yields a certain degree of accuracy loss as soon as the order is created.
 *
 * encoding / decoding scheme:
 * - `b(x) = bit-length of x`
 * - `c(x) = max(b(x) - 48, 0)`
 * - `f(x) = floor(sqrt(x) * (1 << 48))`
 * - `g(x) = f(x) >> c(f(x)) << c(f(x))`
 * - `e(x) = (x >> c(x)) | (c(x) << 48)`
 * - `d(x) = (x & ((1 << 48) - 1)) << (x >> 48)`
 *
 * let the following denote:
 * - `L = g(lowest rate)`
 * - `H = g(highest rate)`
 * - `M = g(marginal rate)`
 *
 * then the order maintains:
 * - `y = current liquidity`
 * - `z = current liquidity * (H - L) / (M - L)`
 * - `A = e(H - L)`
 * - `B = e(L)`
 *
 * and the order reflects:
 * - `L = d(B)`
 * - `H = d(B + A)`
 * - `M = d(B + A * y / z)`
 *
 * upon trading on a given order in a given strategy:
 * - the value of `y` in the given order decreases
 * - the value of `y` in the other order increases
 * - the value of `z` in the other order may increase
 * - the values of all other parameters remain unchanged
 *
 * given a source amount `x`, the expected target amount is:
 * - theoretical formula: `M ^ 2 * x * y / (M * (M - L) * x + y)`
 * - implemented formula: `x * (A * y + B * z) ^ 2 / (A * x * (A * y + B * z) + z ^ 2)`
 *
 * given a target amount `x`, the required source amount is:
 * - theoretical formula: `x * y / (M * (L - M) * x + M ^ 2 * y)`
 * - implemented formula: `x * z ^ 2 / ((A * y + B * z) * (A * y + B * z - A * x))`
 *
 * fee scheme:
 * +-------------------+---------------------------------+---------------------------------+
 * | trade function    | trader transfers to contract    | contract transfers to trader    |
 * +-------------------+---------------------------------+---------------------------------+
 * | bySourceAmount(x) | trader transfers to contract: x | p = expectedTargetAmount(x)     |
 * |                   |                                 | q = p * (100 - fee%) / 100      |
 * |                   |                                 | contract transfers to trader: q |
 * |                   |                                 | contract retains as fee: p - q  |
 * +-------------------+---------------------------------+---------------------------------+
 * | byTargetAmount(x) | p = requiredSourceAmount(x)     | contract transfers to trader: x |
 * |                   | q = p * 100 / (100 - fee%)      |                                 |
 * |                   | trader transfers to contract: q |                                 |
 * |                   | contract retains as fee: q - p  |                                 |
 * +-------------------+---------------------------------+---------------------------------+
 */

// solhint-disable var-name-mixedcase
struct Order {
    uint128 y;
    uint128 z;
    uint64 A;
    uint64 B;
}
// solhint-enable var-name-mixedcase

struct TradeTokens {
    Token source;
    Token target;
}

struct Strategy {
    uint256 id;
    address owner;
    Token[2] tokens;
    Order[2] orders;
}

struct TradeAction {
    uint256 strategyId;
    uint128 amount;
}

// strategy update reasons
uint8 constant STRATEGY_UPDATE_REASON_EDIT = 0;
uint8 constant STRATEGY_UPDATE_REASON_TRADE = 1;

abstract contract Strategies is Initializable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using Address for address payable;
    using MathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;

    error NativeAmountMismatch();
    error BalanceMismatch();
    error GreaterThanMaxInput();
    error LowerThanMinReturn();
    error InsufficientCapacity();
    error InsufficientLiquidity();
    error InvalidRate();
    error InvalidTradeActionStrategyId();
    error InvalidTradeActionAmount();
    error OrderDisabled();
    error OutDated();

    struct SourceAndTargetAmounts {
        uint128 sourceAmount;
        uint128 targetAmount;
    }

    struct TradeParams {
        address trader;
        TradeTokens tokens;
        bool byTargetAmount;
        uint128 constraint;
        uint256 txValue;
        Pair pair;
        uint128 sourceAmount;
        uint128 targetAmount;
    }

    uint256 private constant ONE = 1 << 48;

    uint256 private constant ORDERS_INVERTED_FLAG = 1 << 255;

    uint32 private constant DEFAULT_TRADING_FEE_PPM = 2000; // 0.2%

    // total number of strategies
    uint128 private _strategyCounter;

    // the global trading fee (in units of PPM)
    uint32 internal _tradingFeePPM;

    // mapping between a strategy to its packed orders
    mapping(uint256 => uint256[3]) private _packedOrdersByStrategyId;

    // mapping between a pair id to its strategies ids
    mapping(uint128 => EnumerableSetUpgradeable.UintSet) private _strategyIdsByPairIdStorage;

    // accumulated fees per token
    mapping(Token => uint256) internal _accumulatedFees;

    // upgrade forward-compatibility storage gap
    uint256[MAX_GAP - 4] private __gap;

    /**
     * @dev triggered when the network fee is updated
     */
    event TradingFeePPMUpdated(uint32 prevFeePPM, uint32 newFeePPM);

    /**
     * @dev triggered when a strategy is created
     */
    event StrategyCreated(
        uint256 id,
        address indexed owner,
        Token indexed token0,
        Token indexed token1,
        Order order0,
        Order order1
    );

    /**
     * @dev triggered when a strategy is deleted
     */
    event StrategyDeleted(
        uint256 id,
        address indexed owner,
        Token indexed token0,
        Token indexed token1,
        Order order0,
        Order order1
    );

    /**
     * @dev triggered when a strategy is updated
     */
    event StrategyUpdated(
        uint256 indexed id,
        Token indexed token0,
        Token indexed token1,
        Order order0,
        Order order1,
        uint8 reason
    );

    /**
     * @dev triggered when tokens are traded
     */
    event TokensTraded(
        address indexed trader,
        Token indexed sourceToken,
        Token indexed targetToken,
        uint256 sourceAmount,
        uint256 targetAmount,
        uint128 tradingFeeAmount,
        bool byTargetAmount
    );

    /**
     * @dev triggered when fees are withdrawn
     */
    event FeesWithdrawn(Token indexed token, address indexed recipient, uint256 indexed amount, address sender);

    // solhint-disable func-name-mixedcase
    /**
     * @dev initializes the contract and its parents
     */
    function __Strategies_init() internal onlyInitializing {
        __Strategies_init_unchained();
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __Strategies_init_unchained() internal onlyInitializing {
        _setTradingFeePPM(DEFAULT_TRADING_FEE_PPM);
    }

    // solhint-enable func-name-mixedcase

    /**
     * @dev creates a new strategy
     */
    function _createStrategy(
        IVoucher voucher,
        Token[2] memory tokens,
        Order[2] calldata orders,
        Pair memory pair,
        address owner,
        uint256 value
    ) internal returns (uint256) {
        // transfer funds
        _validateDepositAndRefundExcessNativeToken(tokens[0], owner, orders[0].y, value, true);
        _validateDepositAndRefundExcessNativeToken(tokens[1], owner, orders[1].y, value, true);

        // store id
        uint128 counter = _strategyCounter + 1;
        _strategyCounter = counter;
        uint256 id = _strategyId(pair.id, counter);
        _strategyIdsByPairIdStorage[pair.id].add(id);

        // store orders
        bool ordersInverted = tokens[0] == pair.tokens[1];
        _packedOrdersByStrategyId[id] = _packOrders(orders, ordersInverted);

        // mint voucher
        voucher.mint(owner, id);

        // emit event
        emit StrategyCreated({
            id: id,
            owner: owner,
            token0: tokens[0],
            token1: tokens[1],
            order0: orders[0],
            order1: orders[1]
        });

        return id;
    }

    /**
     * @dev updates an existing strategy
     */
    function _updateStrategy(
        uint256 strategyId,
        Order[2] calldata currentOrders,
        Order[2] calldata newOrders,
        Pair memory pair,
        address owner,
        uint256 value
    ) internal {
        // prepare storage variable
        uint256[3] storage packedOrders = _packedOrdersByStrategyId[strategyId];
        uint256[3] memory packedOrdersMemory = packedOrders;
        (Order[2] memory orders, bool ordersInverted) = _unpackOrders(packedOrdersMemory);

        // revert if the strategy mutated since this tx was sent
        if (!_equalStrategyOrders(currentOrders, orders)) {
            revert OutDated();
        }

        // store new values if necessary
        uint256[3] memory newPackedOrders = _packOrders(newOrders, ordersInverted);
        if (packedOrdersMemory[0] != newPackedOrders[0]) {
            packedOrders[0] = newPackedOrders[0];
        }
        if (packedOrdersMemory[1] != newPackedOrders[1]) {
            packedOrders[1] = newPackedOrders[1];
        }
        if (packedOrdersMemory[2] != newPackedOrders[2]) {
            packedOrders[2] = newPackedOrders[2];
        }

        // deposit and withdraw
        Token[2] memory sortedTokens = _sortStrategyTokens(pair, ordersInverted);
        for (uint256 i = 0; i < 2; i = uncheckedInc(i)) {
            Token token = sortedTokens[i];
            if (newOrders[i].y < orders[i].y) {
                // liquidity decreased - withdraw the difference
                uint128 delta = orders[i].y - newOrders[i].y;
                _withdrawFunds(token, payable(owner), delta);
            } else if (newOrders[i].y > orders[i].y) {
                // liquidity increased - deposit the difference
                uint128 delta = newOrders[i].y - orders[i].y;
                _validateDepositAndRefundExcessNativeToken(token, owner, delta, value, true);
            }

            // refund native token when there's no deposit in the order
            // note that deposit handles refunds internally
            if (value > 0 && token.isNative() && newOrders[i].y <= orders[i].y) {
                payable(address(owner)).sendValue(value);
            }
        }

        // emit event
        emit StrategyUpdated({
            id: strategyId,
            token0: sortedTokens[0],
            token1: sortedTokens[1],
            order0: newOrders[0],
            order1: newOrders[1],
            reason: STRATEGY_UPDATE_REASON_EDIT
        });
    }

    /**
     * @dev deletes a strategy
     */
    function _deleteStrategy(uint256 strategyId, IVoucher voucher, Pair memory pair) internal {
        Strategy memory strategy = _strategy(strategyId, voucher, pair);

        // burn the voucher nft token
        voucher.burn(strategy.id);

        // clear storage
        delete _packedOrdersByStrategyId[strategy.id];
        _strategyIdsByPairIdStorage[pair.id].remove(strategy.id);

        // withdraw funds
        _withdrawFunds(strategy.tokens[0], payable(strategy.owner), strategy.orders[0].y);
        _withdrawFunds(strategy.tokens[1], payable(strategy.owner), strategy.orders[1].y);

        // emit event
        emit StrategyDeleted({
            id: strategy.id,
            owner: strategy.owner,
            token0: strategy.tokens[0],
            token1: strategy.tokens[1],
            order0: strategy.orders[0],
            order1: strategy.orders[1]
        });
    }

    /**
     * @dev perform trade, update affected strategies
     *
     * requirements:
     *
     * - the caller must have approved the source token
     */
    function _trade(TradeAction[] calldata tradeActions, TradeParams memory params) internal {
        bool isTargetToken0 = params.tokens.target == params.pair.tokens[0];

        // process trade actions
        for (uint256 i = 0; i < tradeActions.length; i = uncheckedInc(i)) {
            // prepare variables
            uint128 amount = tradeActions[i].amount;
            uint256 strategyId = tradeActions[i].strategyId;
            uint256[3] storage packedOrders = _packedOrdersByStrategyId[strategyId];
            uint256[3] memory packedOrdersMemory = packedOrders;
            (Order[2] memory orders, bool ordersInverted) = _unpackOrders(packedOrdersMemory);

            _validateTradeParams(params.pair.id, strategyId, amount);

            (Order memory targetOrder, Order memory sourceOrder) = isTargetToken0 == ordersInverted
                ? (orders[1], orders[0])
                : (orders[0], orders[1]);

            // calculate the orders new values
            (uint128 sourceAmount, uint128 targetAmount) = _singleTradeActionSourceAndTargetAmounts(
                targetOrder,
                amount,
                params.byTargetAmount
            );

            // handled specifically for a custom error message
            if (targetOrder.y < targetAmount) {
                revert InsufficientLiquidity();
            }

            // update the orders with the new values
            // safe since it's checked above
            unchecked {
                targetOrder.y -= targetAmount;
            }

            sourceOrder.y += sourceAmount;
            if (sourceOrder.z < sourceOrder.y) {
                sourceOrder.z = sourceOrder.y;
            }

            // store new values if necessary
            uint256[3] memory newPackedOrders = _packOrders(orders, ordersInverted);

            // both y values are in slot 0, so it has definitely changed
            packedOrders[0] = newPackedOrders[0];

            // one of the z values is in slot 1, so it has possibly changed
            if (packedOrdersMemory[1] != newPackedOrders[1]) {
                packedOrders[1] = newPackedOrders[1];
            }

            // the other z value has possibly changed only if the first one hasn't
            if (packedOrdersMemory[2] != newPackedOrders[2]) {
                packedOrders[2] = newPackedOrders[2];
            }

            // emit update event
            emit StrategyUpdated({
                id: strategyId,
                token0: params.pair.tokens[ordersInverted ? 1 : 0],
                token1: params.pair.tokens[ordersInverted ? 0 : 1],
                order0: orders[0],
                order1: orders[1],
                reason: STRATEGY_UPDATE_REASON_TRADE
            });

            params.sourceAmount += sourceAmount;
            params.targetAmount += targetAmount;
        }

        // apply trading fee
        uint128 tradingFeeAmount;
        if (params.byTargetAmount) {
            uint128 amountIncludingFee = _addFee(params.sourceAmount);
            tradingFeeAmount = amountIncludingFee - params.sourceAmount;
            params.sourceAmount = amountIncludingFee;
            if (params.sourceAmount > params.constraint) {
                revert GreaterThanMaxInput();
            }
            _accumulatedFees[params.tokens.source] += tradingFeeAmount;
        } else {
            uint128 amountExcludingFee = _subtractFee(params.targetAmount);
            tradingFeeAmount = params.targetAmount - amountExcludingFee;
            params.targetAmount = amountExcludingFee;
            if (params.targetAmount < params.constraint) {
                revert LowerThanMinReturn();
            }
            _accumulatedFees[params.tokens.target] += tradingFeeAmount;
        }

        // transfer funds
        _validateDepositAndRefundExcessNativeToken(
            params.tokens.source,
            params.trader,
            params.sourceAmount,
            params.txValue,
            false
        );
        _withdrawFunds(params.tokens.target, payable(params.trader), params.targetAmount);

        // tokens traded successfully, emit event
        emit TokensTraded({
            trader: params.trader,
            sourceToken: params.tokens.source,
            targetToken: params.tokens.target,
            sourceAmount: params.sourceAmount,
            targetAmount: params.targetAmount,
            tradingFeeAmount: tradingFeeAmount,
            byTargetAmount: params.byTargetAmount
        });
    }

    /**
     * @dev calculates the required amount plus fee
     */
    function _addFee(uint128 amount) private view returns (uint128) {
        // divide the input amount by `1 - fee`
        return MathEx.mulDivC(amount, PPM_RESOLUTION, PPM_RESOLUTION - _tradingFeePPM).toUint128();
    }

    /**
     * @dev calculates the expected amount minus fee
     */
    function _subtractFee(uint128 amount) private view returns (uint128) {
        // multiply the input amount by `1 - fee`
        return MathEx.mulDivF(amount, PPM_RESOLUTION - _tradingFeePPM, PPM_RESOLUTION).toUint128();
    }

    /**
     * @dev calculates and returns the total source and target amounts of a trade, including fees
     */
    function _tradeSourceAndTargetAmounts(
        TradeTokens memory tokens,
        TradeAction[] calldata tradeActions,
        Pair memory pair,
        bool byTargetAmount
    ) internal view returns (SourceAndTargetAmounts memory totals) {
        bool isTargetToken0 = tokens.target == pair.tokens[0];

        // process trade actions
        for (uint256 i = 0; i < tradeActions.length; i = uncheckedInc(i)) {
            // prepare variables
            uint128 amount = tradeActions[i].amount;
            uint256 strategyId = tradeActions[i].strategyId;
            uint256[3] memory packedOrdersMemory = _packedOrdersByStrategyId[strategyId];
            (Order[2] memory orders, bool ordersInverted) = _unpackOrders(packedOrdersMemory);

            _validateTradeParams(pair.id, strategyId, amount);

            Order memory targetOrder = isTargetToken0 == ordersInverted ? orders[1] : orders[0];

            // calculate the orders new values
            (uint128 sourceAmount, uint128 targetAmount) = _singleTradeActionSourceAndTargetAmounts(
                targetOrder,
                amount,
                byTargetAmount
            );

            // update totals
            totals.sourceAmount += sourceAmount;
            totals.targetAmount += targetAmount;
        }

        // apply trading fee
        if (byTargetAmount) {
            totals.sourceAmount = _addFee(totals.sourceAmount);
        } else {
            totals.targetAmount = _subtractFee(totals.targetAmount);
        }
    }

    /**
     * @dev returns stored strategies of a pair
     */
    function _strategiesByPair(
        Pair memory pair,
        uint256 startIndex,
        uint256 endIndex,
        IVoucher voucher
    ) internal view returns (Strategy[] memory) {
        EnumerableSetUpgradeable.UintSet storage strategyIds = _strategyIdsByPairIdStorage[pair.id];
        uint256 allLength = strategyIds.length();

        // when the endIndex is 0 or out of bound, set the endIndex to the last value possible
        if (endIndex == 0 || endIndex > allLength) {
            endIndex = allLength;
        }

        // revert when startIndex is out of bound
        if (startIndex > endIndex) {
            revert InvalidIndices();
        }

        // populate the result
        uint256 resultLength = endIndex - startIndex;
        Strategy[] memory result = new Strategy[](resultLength);
        for (uint256 i = 0; i < resultLength; i = uncheckedInc(i)) {
            uint256 strategyId = strategyIds.at(startIndex + i);
            result[i] = _strategy(strategyId, voucher, pair);
        }

        return result;
    }

    /**
     * @dev returns the count of stored strategies of a pair
     */
    function _strategiesByPairCount(Pair memory pair) internal view returns (uint256) {
        EnumerableSetUpgradeable.UintSet storage strategyIds = _strategyIdsByPairIdStorage[pair.id];
        return strategyIds.length();
    }

    /**
     @dev returns a strategy object matching the provided id.
     */
    function _strategy(uint256 id, IVoucher voucher, Pair memory pair) internal view returns (Strategy memory) {
        // fetch data
        address _owner = voucher.ownerOf(id);
        uint256[3] memory packedOrdersMemory = _packedOrdersByStrategyId[id];
        (Order[2] memory orders, bool ordersInverted) = _unpackOrders(packedOrdersMemory);

        // handle sorting
        Token[2] memory sortedTokens = _sortStrategyTokens(pair, ordersInverted);

        return Strategy({ id: id, owner: _owner, tokens: sortedTokens, orders: orders });
    }

    /**
     * @dev validates deposit amounts, refunds excess native tokens sent
     */
    function _validateDepositAndRefundExcessNativeToken(
        Token token,
        address owner,
        uint256 depositAmount,
        uint256 txValue,
        bool validateDepositAmount
    ) private {
        if (token.isNative()) {
            if (txValue < depositAmount) {
                revert NativeAmountMismatch();
            }

            // refund the owner for the remaining native token amount
            if (txValue > depositAmount) {
                payable(address(owner)).sendValue(txValue - depositAmount);
            }
        } else if (depositAmount > 0) {
            if (validateDepositAmount) {
                uint256 prevBalance = token.balanceOf(address(this));
                token.safeTransferFrom(owner, address(this), depositAmount);
                uint256 newBalance = token.balanceOf(address(this));
                if (newBalance - prevBalance != depositAmount) {
                    revert BalanceMismatch();
                }
            } else {
                token.safeTransferFrom(owner, address(this), depositAmount);
            }
        }
    }

    function _validateTradeParams(uint128 pairId, uint256 strategyId, uint128 tradeAmount) private pure {
        // make sure the strategy id matches the pair id
        if (_pairIdByStrategyId(strategyId) != pairId) {
            revert InvalidTradeActionStrategyId();
        }

        // make sure the trade amount is nonzero
        if (tradeAmount == 0) {
            revert InvalidTradeActionAmount();
        }
    }

    /**
     * @dev sets the trading fee (in units of PPM)
     */
    function _setTradingFeePPM(uint32 newTradingFeePPM) internal {
        uint32 prevTradingFeePPM = _tradingFeePPM;
        if (prevTradingFeePPM == newTradingFeePPM) {
            return;
        }

        _tradingFeePPM = newTradingFeePPM;

        emit TradingFeePPMUpdated({ prevFeePPM: prevTradingFeePPM, newFeePPM: newTradingFeePPM });
    }

    /**
     * returns true if the provided orders are equal, false otherwise
     */
    function _equalStrategyOrders(Order[2] memory orders0, Order[2] memory orders1) internal pure returns (bool) {
        uint256 i;
        for (i = 0; i < 2; i = uncheckedInc(i)) {
            if (
                orders0[i].y != orders1[i].y ||
                orders0[i].z != orders1[i].z ||
                orders0[i].A != orders1[i].A ||
                orders0[i].B != orders1[i].B
            ) {
                return false;
            }
        }
        return true;
    }

    // solhint-disable var-name-mixedcase

    /**
     * @dev returns:
     *
     *      x * (A * y + B * z) ^ 2
     * ---------------------------------
     *  A * x * (A * y + B * z) + z ^ 2
     *
     */
    function _calculateTradeTargetAmount(
        uint256 x, // < 2 ^ 128
        uint256 y, // < 2 ^ 128
        uint256 z, // < 2 ^ 128
        uint256 A, // < 2 ^ 96
        uint256 B /// < 2 ^ 96
    ) private pure returns (uint256) {
        if (A == 0) {
            if (B == 0) {
                revert OrderDisabled();
            }
            return MathEx.mulDivF(x, B * B, ONE * ONE);
        }

        uint256 temp1;
        uint256 temp2;
        unchecked {
            temp1 = z * ONE; // < 2 ^ 176
            temp2 = y * A + z * B; // < 2 ^ 225
        }
        uint256 temp3 = temp2 * x;

        uint256 factor1 = MathEx.minFactor(temp1, temp1);
        uint256 factor2 = MathEx.minFactor(temp3, A);
        uint256 factor = MathUpgradeable.max(factor1, factor2);

        uint256 temp4 = MathEx.mulDivC(temp1, temp1, factor);
        uint256 temp5 = MathEx.mulDivC(temp3, A, factor);
        return MathEx.mulDivF(temp2, temp3 / factor, temp4 + temp5);
    }

    /**
     * @dev returns:
     *
     *                  x * z ^ 2
     * -------------------------------------------
     *  (A * y + B * z) * (A * y + B * z - A * x)
     *
     */
    function _calculateTradeSourceAmount(
        uint256 x, // < 2 ^ 128
        uint256 y, // < 2 ^ 128
        uint256 z, // < 2 ^ 128
        uint256 A, // < 2 ^ 96
        uint256 B /// < 2 ^ 96
    ) private pure returns (uint256) {
        if (A == 0) {
            if (B == 0) {
                revert OrderDisabled();
            }
            return MathEx.mulDivC(x, ONE * ONE, B * B);
        }

        uint256 temp1;
        uint256 temp2;
        unchecked {
            temp1 = z * ONE; // < 2 ^ 176
            temp2 = y * A + z * B; // < 2 ^ 225
        }
        uint256 temp3 = temp2 - x * A;

        uint256 factor1 = MathEx.minFactor(temp1, temp1);
        uint256 factor2 = MathEx.minFactor(temp2, temp3);
        uint256 factor = MathUpgradeable.max(factor1, factor2);

        uint256 temp4 = MathEx.mulDivC(temp1, temp1, factor);
        uint256 temp5 = MathEx.mulDivF(temp2, temp3, factor);
        return MathEx.mulDivC(x, temp4, temp5);
    }

    // solhint-enable var-name-mixedcase

    /**
     * @dev pack 2 orders into a 3 slot uint256 data structure
     */
    function _packOrders(Order[2] memory orders, bool ordersInverted) private pure returns (uint256[3] memory values) {
        values = [
            uint256((uint256(orders[0].y) << 0) | (uint256(orders[1].y) << 128)),
            uint256((uint256(orders[0].z) << 0) | (uint256(orders[0].A) << 128) | (uint256(orders[0].B) << 192)),
            uint256(
                (uint256(orders[1].z) << 0) |
                    (uint256(orders[1].A) << 128) |
                    (uint256(orders[1].B) << 192) |
                    (ordersInverted ? ORDERS_INVERTED_FLAG : 0)
            )
        ];
    }

    /**
     * @dev unpack 2 stored orders into an array of Order types
     */
    function _unpackOrders(
        uint256[3] memory values
    ) private pure returns (Order[2] memory orders, bool ordersInverted) {
        orders = [
            Order({
                y: uint128(values[0] >> 0),
                z: uint128(values[1] >> 0),
                A: uint64(values[1] >> 128),
                B: uint64(values[1] >> 192)
            }),
            Order({
                y: uint128(values[0] >> 128),
                z: uint128(values[2] >> 0),
                A: uint64(values[2] >> 128),
                B: uint64((values[2] << 1) >> 193)
            })
        ];
        ordersInverted = values[2] >= ORDERS_INVERTED_FLAG;
    }

    /**
     * @dev expand a given rate
     */
    function _expandRate(uint256 rate) internal pure returns (uint256) {
        // safe because no `+` or `-` or `*`
        unchecked {
            return (rate % ONE) << (rate / ONE);
        }
    }

    /**
     * @dev validates a given rate
     */
    function _validRate(uint256 rate) internal pure returns (bool) {
        // safe because no `+` or `-` or `*`
        unchecked {
            return (ONE >> (rate / ONE)) > 0;
        }
    }

    /**
     * @dev returns the source and target amounts of a single trade action
     */
    function _singleTradeActionSourceAndTargetAmounts(
        Order memory order,
        uint128 amount,
        bool byTargetAmount
    ) internal pure returns (uint128 sourceAmount, uint128 targetAmount) {
        uint256 y = uint256(order.y);
        uint256 z = uint256(order.z);
        uint256 a = _expandRate(uint256(order.A));
        uint256 b = _expandRate(uint256(order.B));
        if (byTargetAmount) {
            sourceAmount = _calculateTradeSourceAmount(amount, y, z, a, b).toUint128();
            targetAmount = amount;
        } else {
            sourceAmount = amount;
            targetAmount = _calculateTradeTargetAmount(amount, y, z, a, b).toUint128();
        }
    }

    /**
     * revert if any of the orders is invalid
     */
    function _validateOrders(Order[2] calldata orders) internal pure {
        for (uint256 i = 0; i < 2; i = uncheckedInc(i)) {
            if (orders[i].z < orders[i].y) {
                revert InsufficientCapacity();
            }
            if (!_validRate(orders[i].A)) {
                revert InvalidRate();
            }
            if (!_validRate(orders[i].B)) {
                revert InvalidRate();
            }
        }
    }

    /**
     * returns the strategyId for a given pairId and a given strategyIndex
     */
    function _strategyId(uint128 pairId, uint128 strategyIndex) internal pure returns (uint256) {
        return (uint256(pairId) << 128) | strategyIndex;
    }

    /**
     * returns the pairId associated with a given strategyId
     */
    function _pairIdByStrategyId(uint256 strategyId) internal pure returns (uint128) {
        return uint128(strategyId >> 128);
    }

    function _withdrawFees(address sender, uint256 amount, Token token, address recipient) internal returns (uint256) {
        uint256 accumulatedAmount = _accumulatedFees[token];
        if (accumulatedAmount == 0) {
            return 0;
        }
        if (amount > accumulatedAmount) {
            amount = accumulatedAmount;
        }

        _accumulatedFees[token] = accumulatedAmount - amount;
        _withdrawFunds(token, payable(recipient), amount);
        emit FeesWithdrawn(token, recipient, amount, sender);
        return amount;
    }

    /**
     * returns tokens sorted accordingly to a strategy orders inversion
     */
    function _sortStrategyTokens(Pair memory pair, bool ordersInverted) private pure returns (Token[2] memory) {
        return ordersInverted ? [pair.tokens[1], pair.tokens[0]] : pair.tokens;
    }

    /**
     * sends erc20 or native token to the provided target
     */
    function _withdrawFunds(Token token, address payable target, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        if (token.isNative()) {
            // using a regular transfer here would revert due to exceeding the 2300 gas limit which is why we're using
            // call instead (via sendValue), which the 2300 gas limit does not apply for
            target.sendValue(amount);
        } else {
            token.safeTransfer(target, amount);
        }
    }

    function uncheckedInc(uint256 i) private pure returns (uint256 j) {
        unchecked {
            j = i + 1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IUpgradeable } from "../../utility/interfaces/IUpgradeable.sol";
import { Pair } from "../Pairs.sol";
import { Token } from "../../token/Token.sol";
import { Strategy, TradeAction, Order } from "../Strategies.sol";

/**
 * @dev Carbon Controller interface
 */
interface ICarbonController is IUpgradeable {
    /**
     * @dev returns the type of the controller
     */
    function controllerType() external pure returns (uint16);

    /**
     * @dev returns the trading fee (in units of PPM)
     */
    function tradingFeePPM() external view returns (uint32);

    /**
     * @dev creates a new pair of provided token0 and token1
     */
    function createPair(Token token0, Token token1) external returns (Pair memory);

    /**
     * @dev returns a pair's metadata matching the provided token0 and token1
     */
    function pair(Token token0, Token token1) external view returns (Pair memory);

    /**
     * @dev returns a list of all supported pairs
     */
    function pairs() external view returns (Token[2][] memory);

    // solhint-disable var-name-mixedcase
    /**
     * @dev creates a new strategy, returns the strategy's id
     *
     * requirements:
     *
     * - the caller must have approved the tokens with assigned liquidity in the order, if any
     */
    function createStrategy(Token token0, Token token1, Order[2] calldata orders) external payable returns (uint256);

    /**
     * @dev updates an existing strategy
     *
     * notes:
     * - currentOrders should reflect the orders values at the time of sending the tx
     * this prevents cases in which the strategy was updated due to a trade between
     * the time the transaction was sent and the time it was mined, thus, giving more
     * control to the strategy owner.
     * - reduced liquidity is refunded to the owner
     * - increased liquidity is deposited
     * - excess native token is returned to the sender if any
     * - the sorting of orders is expected to equal the sorting upon creation
     *
     * requirements:
     *
     * - the caller must have approved the tokens with increased liquidity, if any
     */
    function updateStrategy(
        uint256 strategyId,
        Order[2] calldata currentOrders,
        Order[2] calldata newOrders
    ) external payable;

    // solhint-enable var-name-mixedcase

    /**
     * @dev deletes a strategy matching the provided id
     *
     * notes:
     *
     * - 100% of liquidity is withdrawn and sent to the owner
     *
     * requirements:
     *
     * - the caller must be the owner of the NFT voucher
     */
    function deleteStrategy(uint256 strategyId) external;

    /**
     * @dev returns a strategy matching the provided id,
     * note tokens and orders are returned sorted as provided upon creation
     */
    function strategy(uint256 id) external view returns (Strategy memory);

    /**
     * @dev returns strategies belonging to a specific pair
     * note that for the full list of strategies pass 0 to both startIndex and endIndex
     */
    function strategiesByPair(
        Token token0,
        Token token1,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (Strategy[] memory);

    /**
     * @dev returns the count of strategies belonging to a specific pair
     */
    function strategiesByPairCount(Token token0, Token token1) external view returns (uint256);

    /**
     * @dev performs a trade by specifying a fixed source amount
     *
     * notes:
     *
     * - excess native token is returned to the sender if any
     *
     * requirements:
     *
     * - the caller must have approved the source token
     */
    function tradeBySourceAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions,
        uint256 deadline,
        uint128 minReturn
    ) external payable returns (uint128);

    /**
     * @dev performs a trade by specifying a fixed target amount
     *
     * notes:
     *
     * - excess native token is returned to the sender if any
     *
     * requirements:
     *
     * - the caller must have approved the source token
     */
    function tradeByTargetAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions,
        uint256 deadline,
        uint128 maxInput
    ) external payable returns (uint128);

    /**
     * @dev returns the source amount required when trading by target amount
     */
    function calculateTradeSourceAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions
    ) external view returns (uint128);

    /**
     * @dev returns the target amount expected when trading by source amount
     */
    function calculateTradeTargetAmount(
        Token sourceToken,
        Token targetToken,
        TradeAction[] calldata tradeActions
    ) external view returns (uint128);

    /**
     * @dev returns the amount of fees accumulated for the specified token
     */
    function accumulatedFees(Token token) external view returns (uint256);

    /**
     * @dev transfers the accumulated fees to the specified recipient
     *
     * notes:
     * `amount` is capped to the available amount
     * returns the amount withdrawn
     */
    function withdrawFees(Token token, uint256 amount, address recipient) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev This type implements ERC20 and SafeERC20 utilities for both the native token and for ERC20 tokens
 */
type Token is address;
using SafeERC20 for IERC20;

// the address that represents the native token reserve
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// the symbol that represents the native token
string constant NATIVE_TOKEN_SYMBOL = "ETH";

// the decimals for the native token
uint8 constant NATIVE_TOKEN_DECIMALS = 18;

// the token representing the native token
Token constant NATIVE_TOKEN = Token.wrap(NATIVE_TOKEN_ADDRESS);

using {
    equal as ==,
    notEqual as !=,
    isNative,
    symbol,
    decimals,
    balanceOf,
    allowance,
    safeTransfer,
    safeTransferFrom,
    safeApprove,
    safeIncreaseAllowance
} for Token global;

/* solhint-disable func-visibility */

function equal(Token a, Token b) pure returns (bool) {
    return Token.unwrap(a) == Token.unwrap(b);
}

function notEqual(Token a, Token b) pure returns (bool) {
    return Token.unwrap(a) != Token.unwrap(b);
}

/**
 * @dev returns whether the provided token represents an ERC20 or the native token reserve
 */
function isNative(Token token) pure returns (bool) {
    return token == NATIVE_TOKEN;
}

/**
 * @dev returns the symbol of the native token/ERC20 token
 */
function symbol(Token token) view returns (string memory) {
    if (isNative(token)) {
        return NATIVE_TOKEN_SYMBOL;
    }
    return toERC20(token).symbol();
}

/**
 * @dev returns the decimals of the native token/ERC20 token
 */
function decimals(Token token) view returns (uint8) {
    if (isNative(token)) {
        return NATIVE_TOKEN_DECIMALS;
    }
    return toERC20(token).decimals();
}

/**
 * @dev returns the balance of the native token/ERC20 token
 */
function balanceOf(Token token, address account) view returns (uint256) {
    if (isNative(token)) {
        return account.balance;
    }
    return toIERC20(token).balanceOf(account);
}

/**
 * @dev returns the allowance of an `owner` to a `spender`
 */
function allowance(Token token, address owner, address spender) view returns (uint256) {
    if (isNative(token)) {
        return 0;
    }
    return toIERC20(token).allowance(owner, spender);
}

/**
 * @dev transfers a specific amount of the native token/ERC20 token
 */
function safeTransfer(Token token, address to, uint256 amount) {
    if (amount == 0) {
        return;
    }
    if (isNative(token)) {
        payable(to).transfer(amount);
    } else {
        toIERC20(token).safeTransfer(to, amount);
    }
}

/**
 * @dev transfers a specific amount of the native token/ERC20 token from a specific holder using the allowance mechanism
 *
 * note that the function does not perform any action if the native token is provided
 */
function safeTransferFrom(Token token, address from, address to, uint256 amount) {
    if (amount == 0 || isNative(token)) {
        return;
    }
    toIERC20(token).safeTransferFrom(from, to, amount);
}

/**
 * @dev approves a specific amount of the native token/ERC20 token from a specific holder
 *
 * note that the function does not perform any action if the native token is provided
 */
function safeApprove(Token token, address spender, uint256 amount) {
    if (isNative(token)) {
        return;
    }
    toIERC20(token).safeApprove(spender, amount);
}

/**
 * @dev atomically increases the allowance granted to `spender` by the caller.
 *
 * note that the function does not perform any action if the native token is provided
 */
function safeIncreaseAllowance(Token token, address spender, uint256 amount) {
    if (isNative(token)) {
        return;
    }
    toIERC20(token).safeIncreaseAllowance(spender, amount);
}

/**
 * @dev utility function that converts a token to an IERC20
 */
function toIERC20(Token token) pure returns (IERC20) {
    return IERC20(Token.unwrap(token));
}

/**
 * @dev utility function that converts a token to an ERC20
 */
function toERC20(Token token) pure returns (ERC20) {
    return ERC20(Token.unwrap(token));
}

/* solhint-disable func-visibility */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

uint32 constant PPM_RESOLUTION = 1_000_000;

uint32 constant MAX_GAP = 50;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @dev this library provides a set of complex math operations
 */
library MathEx {
    error Overflow();

    /**
     * @dev returns the largest integer smaller than or equal to `x * y / z`
     */
    function mulDivF(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        // safe because no `+` or `-` or `*`
        unchecked {
            (uint256 xyhi, uint256 xylo) = _mul512(x, y);

            // if `x * y < 2 ^ 256`
            if (xyhi == 0) {
                return xylo / z;
            }

            // assert `x * y / z < 2 ^ 256`
            if (xyhi >= z) {
                revert Overflow();
            }

            uint256 m = _mulMod(x, y, z); // `m = x * y % z`
            (uint256 nhi, uint256 nlo) = _sub512(xyhi, xylo, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`

            // if `n < 2 ^ 256`
            if (nhi == 0) {
                return nlo / z;
            }

            uint256 p = _unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
            uint256 q = _div512(nhi, nlo, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
            uint256 r = _inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
            return _unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
        }
    }

    /**
     * @dev returns the smallest integer larger than or equal to `x * y / z`
     */
    function mulDivC(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        uint256 w = mulDivF(x, y, z);
        if (_mulMod(x, y, z) > 0) {
            if (w >= type(uint256).max) {
                revert Overflow();
            }
            unchecked {
                // safe because `w < type(uint256).max`
                return w + 1;
            }
        }
        return w;
    }

    /**
     * @dev returns the smallest integer `z` such that `x * y / z <= 2 ^ 256 - 1`
     */
    function minFactor(uint256 x, uint256 y) internal pure returns (uint256) {
        (uint256 hi, uint256 lo) = _mul512(x, y);
        unchecked {
            // safe because:
            // - if `x < 2 ^ 256 - 1` or `y < 2 ^ 256 - 1`
            //   then `hi < 2 ^ 256 - 2`
            //   hence neither `hi + 1` nor `hi + 2` overflows
            // - if `x = 2 ^ 256 - 1` and `y = 2 ^ 256 - 1`
            //   then `hi = 2 ^ 256 - 2 = ~lo`
            //   hence `hi + 1`, which does not overflow, is computed
            return hi > ~lo ? hi + 2 : hi + 1;
        }

        /* reasoning:
        |
        |   general:
        |   - find the smallest integer `z` such that `x * y / z <= 2 ^ 256 - 1`
        |   - the value of `x * y` is represented via `2 ^ 256 * hi + lo`
        |   - the expression `~lo` is equivalent to `2 ^ 256 - 1 - lo`
        |   
        |   symbols:
        |   - let `H` denote `hi`
        |   - let `L` denote `lo`
        |   - let `N` denote `2 ^ 256 - 1`
        |   
        |   inference:
        |   `x * y / z <= 2 ^ 256 - 1`     <-->
        |   `x * y / (2 ^ 256 - 1) <= z`   <-->
        |   `((N + 1) * H + L) / N <= z`   <-->
        |   `(N * H + H + L) / N <= z`     <-->
        |   `H + (H + L) / N <= z`
        |   
        |   inference:
        |   `0 <= H <= N && 0 <= L <= N`   <-->
        |   `0 <= H + L <= N + N`          <-->
        |   `0 <= H + L <= N * 2`          <-->
        |   `0 <= (H + L) / N <= 2`
        |   
        |   inference:
        |   - `0 = (H + L) / N` --> `H + L = 0` --> `x * y = 0` --> `z = 1 = H + 1`
        |   - `0 < (H + L) / N <= 1` --> `H + (H + L) / N <= H + 1` --> `z = H + 1`
        |   - `1 < (H + L) / N <= 2` --> `H + (H + L) / N <= H + 2` --> `z = H + 2`
        |   
        |   implementation:
        |   - if `hi > ~lo`:
        |     `~L < H <= N`                         <-->
        |     `N - L < H <= N`                      <-->
        |     `N < H + L <= N + L`                  <-->
        |     `1 < (H + L) / N <= 2`                <-->
        |     `H + 1 < H + (H + L) / N <= H + 2`    <-->
        |     `z = H + 2`
        |   - if `hi <= ~lo`:
        |     `H <= ~L`                             <-->
        |     `H <= N - L`                          <-->
        |     `H + L <= N`                          <-->
        |     `(H + L) / N <= 1`                    <-->
        |     `H + (H + L) / N <= H + 1`            <-->
        |     `z = H + 1`
        |
        */
    }

    /**
     * @dev returns the value of `x * y`
     */
    function _mul512(uint256 x, uint256 y) private pure returns (uint256, uint256) {
        uint256 p = _mulModMax(x, y);
        uint256 q = _unsafeMul(x, y);
        if (p >= q) {
            unchecked {
                // safe because `p >= q`
                return (p - q, q);
            }
        }
        unchecked {
            // safe because `p < q` hence `_unsafeSub(p, q) > 0`
            return (_unsafeSub(p, q) - 1, q);
        }
    }

    /**
     * @dev returns the value of `x - y`
     */
    function _sub512(uint256 xhi, uint256 xlo, uint256 y) private pure returns (uint256, uint256) {
        if (xlo >= y) {
            unchecked {
                // safe because `xlo >= y`
                return (xhi, xlo - y);
            }
        }
        return (xhi - 1, _unsafeSub(xlo, y));
    }

    /**
     * @dev returns the value of `x / pow2n`, given that `x` is divisible by `pow2n`
     */
    function _div512(uint256 xhi, uint256 xlo, uint256 pow2n) private pure returns (uint256) {
        // safe because no `+` or `-` or `*`
        unchecked {
            uint256 pow2nInv = _unsafeAdd(_unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
            return _unsafeMul(xhi, pow2nInv) | (xlo / pow2n); // `(xhi << (256 - n)) | (xlo >> n)`
        }
    }

    /**
     * @dev returns the inverse of `d` modulo `2 ^ 256`, given that `d` is congruent to `1` modulo `2`
     */
    function _inv256(uint256 d) private pure returns (uint256) {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        unchecked {
            // safe because `i < 8`
            for (uint256 i = 0; i < 8; i++) {
                x = _unsafeMul(x, _unsafeSub(2, _unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
            }
        }
        return x;
    }

    /**
     * @dev returns `(x + y) % 2 ^ 256`
     */
    function _unsafeAdd(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x + y;
        }
    }

    /**
     * @dev returns `(x - y) % 2 ^ 256`
     */
    function _unsafeSub(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x - y;
        }
    }

    /**
     * @dev returns `(x * y) % 2 ^ 256`
     */
    function _unsafeMul(uint256 x, uint256 y) private pure returns (uint256) {
        unchecked {
            return x * y;
        }
    }

    /**
     * @dev returns `x * y % (2 ^ 256 - 1)`
     */
    function _mulModMax(uint256 x, uint256 y) private pure returns (uint256) {
        return mulmod(x, y, type(uint256).max);
    }

    /**
     * @dev returns `x * y % z`
     */
    function _mulMod(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
        return mulmod(x, y, z);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @dev restrict delegation
 */
abstract contract OnlyProxyDelegate {
    address private immutable _proxy;

    error UnknownDelegator();

    constructor(address proxy) {
        _proxy = proxy;
    }

    modifier onlyProxyDelegate() {
        _onlyProxyDelegate();

        _;
    }

    function _onlyProxyDelegate() internal view {
        if (address(this) != _proxy) {
            revert UnknownDelegator();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import { IUpgradeable } from "./interfaces/IUpgradeable.sol";

import { AccessDenied } from "./Utils.sol";

import { MAX_GAP } from "./Constants.sol";

/**
 * @dev this contract provides common utilities for upgradeable contracts
 *
 * note that we're using the Transparent Upgradeable Proxy pattern and *not* the Universal Upgradeable Proxy Standard
 * (UUPS) pattern, therefore initializing the implementation contracts is not necessary or required
 */
abstract contract Upgradeable is IUpgradeable, AccessControlEnumerableUpgradeable {
    error AlreadyInitialized();

    // the admin role is used to allow a non-proxy admin to perform additional initialization/setup during contract
    // upgrades
    bytes32 internal constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    uint16 internal _initializations;

    // upgrade forward-compatibility storage gap
    uint256[MAX_GAP - 1] private __gap;

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract and its parents
     */
    function __Upgradeable_init() internal onlyInitializing {
        __AccessControl_init();

        __Upgradeable_init_unchained();
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __Upgradeable_init_unchained() internal onlyInitializing {
        _initializations = 1;

        // set up administrative roles
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        // allow the deployer to initially be the admin of the contract
        _setupRole(ROLE_ADMIN, msg.sender);
    }

    // solhint-enable func-name-mixedcase

    modifier onlyAdmin() {
        _hasRole(ROLE_ADMIN, msg.sender);

        _;
    }

    modifier onlyRoleMember(bytes32 role) {
        _hasRole(role, msg.sender);

        _;
    }

    function version() public view virtual override returns (uint16);

    /**
     * @dev returns the admin role
     */
    function roleAdmin() external pure returns (bytes32) {
        return ROLE_ADMIN;
    }

    /**
     * @dev performs post-upgrade initialization
     *
     * requirements:
     *
     * - this must and can be called only once per-upgrade
     */
    function postUpgrade(bytes calldata data) external {
        uint16 initializations = _initializations + 1;
        if (initializations != version()) {
            revert AlreadyInitialized();
        }

        _initializations = initializations;

        _postUpgrade(data);
    }

    /**
     * @dev an optional post-upgrade callback that can be implemented by child contracts
     */
    function _postUpgrade(bytes calldata /* data */) internal virtual {}

    function _hasRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert AccessDenied();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { PPM_RESOLUTION } from "./Constants.sol";
import { Token } from "../token/Token.sol";

error AccessDenied();
error InvalidAddress();
error InvalidFee();
error ZeroValue();
error InvalidIndices();

/**
 * @dev common utilities
 */
abstract contract Utils {
    using Address for address payable;

    // allows execution by the caller only
    modifier only(address caller) {
        _only(caller);

        _;
    }

    function _only(address caller) internal view {
        if (msg.sender != caller) {
            revert AccessDenied();
        }
    }

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        if (value == 0) {
            revert ZeroValue();
        }
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert InvalidAddress();
        }
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        if (fee > PPM_RESOLUTION) {
            revert InvalidFee();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IVersioned } from "./IVersioned.sol";

import { IAccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

/**
 * @dev this is the common interface for upgradeable contracts
 */
interface IUpgradeable is IAccessControlEnumerableUpgradeable, IVersioned {

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @dev an interface for a versioned contract
 */
interface IVersioned {
    function version() external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import { IUpgradeable } from "../../utility/interfaces/IUpgradeable.sol";

/**
 * @dev Voucher interface
 */
interface IVoucher is IUpgradeable, IERC721Upgradeable {
    /**
     * @dev creates a new voucher token for the given strategyId, transfers it to the owner
     *
     * requirements:
     *
     * - the caller must have the ROLE_MINTER privilege
     *
     */
    function mint(address owner, uint256 strategyId) external;

    /**
     * @dev destroys the voucher token for the given strategyId
     *
     * requirements:
     *
     * - the caller must have the ROLE_MINTER privilege
     *
     */
    function burn(uint256 strategyId) external;

    /**
     * @dev returns a list of tokenIds belonging to the given owner
     * note that for the full list of tokenIds pass 0 to both startIndex and endIndex
     */
    function tokensByOwner(
        address owner,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (uint256[] memory);
}