// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./configuration/UserConfiguration.sol";
import "./interfaces/ILedger.sol";
import "./interfaces/IUserData.sol";
import "./libraries/math/MathUtils.sol";
import "./libraries/helpers/Errors.sol";
import "./types/DataTypes.sol";

contract UserData is IUserData, Initializable, AccessControlUpgradeable {
    using MathUtils for uint256;
    using MathUtils for int256;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 3;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev Total reserve share supply, expressed in ray
    // pid => share supply
    mapping(uint256 => uint256) public totalReserveShareSupply;

    /// @dev Total collateral share supply, expressed in ray
    // pid => share supply
    mapping(uint256 => uint256) public totalCollateralShareSupply;

    // user => amount
    mapping(address => DataTypes.UserData) public userData;

    /// @dev Ledger
    ILedger public ledger;

    event SetLedger(address ledger);

    function initialize() external initializer onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), Errors.CALLER_NOT_OPERATOR);
        _;
    }

    function setLedger(address ledger_) external onlyOperator {
        require(address(ledger) == address(0), Errors.LEDGER_INITIALIZED);
        ledger = ILedger(ledger_);
        emit SetLedger(ledger_);
    }

    function depositReserve(address user, uint256 pid, uint256 amount, uint256 unit, uint256 currPoolSupply) external override onlyLedger {
        uint256 currTotalReserveShareSupply = totalReserveShareSupply[pid];

        if (userData[user].reserveShares[pid] == 0) {
            userData[user].configuration.setUsingReserve(pid, true);
        }

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalReserveShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        userData[user].reserveShares[pid] += shares;
        totalReserveShareSupply[pid] += shares;
    }

    function withdrawReserve(address user, uint256 pid, uint256 amount, uint256 unit, uint256 currPoolSupply) external override onlyLedger {
        uint256 currTotalReserveShareSupply = totalReserveShareSupply[pid];

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalReserveShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        require(shares <= userData[user].reserveShares[pid], Errors.NOT_ENOUGH_BALANCE);

        userData[user].reserveShares[pid] -= shares;
        totalReserveShareSupply[pid] -= shares;

        if (userData[user].reserveShares[pid] == 0) {
            userData[user].configuration.setUsingReserve(pid, false);
        }
    }

    function depositCollateral(address user, uint256 pid, uint256 amount, uint256 unit, uint256 currPoolSupply) external override onlyLedger {
        uint256 currTotalCollateralShareSupply = totalCollateralShareSupply[pid];

        if (userData[user].collateralShares[pid] == 0) {
            userData[user].configuration.setUsingCollateral(pid, true);
        }

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalCollateralShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        userData[user].collateralShares[pid] += shares;
        totalCollateralShareSupply[pid] += shares;
    }

    function withdrawCollateral(address user, uint256 pid, uint256 amount, uint256 currPoolSupply, uint256 unit) external override onlyLedger {
        uint256 currTotalCollateralShareSupply = totalCollateralShareSupply[pid];

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalCollateralShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        userData[user].collateralShares[pid] -= shares;
        totalCollateralShareSupply[pid] -= shares;

        if (userData[user].collateralShares[pid] == 0) {
            userData[user].configuration.setUsingCollateral(pid, false);
        }
    }

    // TODO: requires review
    function changePosition(address user, uint256 pid, int256 incomingPosition, uint256 borrowIndex, uint256 decimals) external override onlyLedger {
        int256 currNormalizedPositionRay = _normalizedPositionRay(userData[user].positions[pid], borrowIndex);

        int256 nextPositionRay = currNormalizedPositionRay + incomingPosition.unitToRay(decimals);

        userData[user].positions[pid] = _scaledPositionRay(nextPositionRay, borrowIndex);

        userData[user].configuration.setUsingPosition(pid, nextPositionRay != 0);
    }

    function getUserCollateralInternal(address user, uint256 pid, uint256 currPoolSupply, uint256 decimals) external view onlyLedger returns (uint256) {
        uint256 currUserCollateralShare = userData[user].collateralShares[pid];

        if (currUserCollateralShare == 0) {
            return 0;
        }

        uint256 currTotalShareSupply = totalCollateralShareSupply[pid];

        return _toAmount(
            currUserCollateralShare,
            currTotalShareSupply,
            currPoolSupply.unitToRay(decimals)
        ).rayToUnit(decimals);
    }

    function getUserPositionInternal(address user, uint256 pid, uint256 borrowIndex, uint256 decimals) external view override onlyLedger returns (int256) {
        return _normalizedPositionRay(userData[user].positions[pid], borrowIndex).rayToUnit(decimals);
    }

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfiguration memory) {
        return userData[user].configuration;
    }

    function getUserReserve(address user, address asset, bool claimable) external view returns (uint256) {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        uint256 currUserReserveShare = userData[user].reserveShares[reserve.poolId];

        if (currUserReserveShare == 0) {
            return 0;
        }

        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);
        uint256 decimals = assetConfig.decimals;

        (uint256 currAvailableSupply,uint256 currPoolSupply,,,) = ledger.reserveSupplies(asset);

        uint256 currTotalShareSupply = totalReserveShareSupply[reserve.poolId];

        uint256 balance = _toAmount(
            currUserReserveShare,
            currTotalShareSupply,
            currPoolSupply.unitToRay(decimals)
        ).rayToUnit(decimals);

        if (claimable) {
            if (balance > currAvailableSupply) {
                balance = currAvailableSupply;
            }
        }

        return balance;
    }

    function getUserCollateral(address user, address asset_, address reinvestment, bool claimable) external override view returns (uint256) {
        // resolve stack too deep;
        address asset = asset_;
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);

        uint256 currUserCollateralShare = userData[user].collateralShares[collateral.poolId];

        if (currUserCollateralShare == 0) {
            return 0;
        }

        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);
        uint256 decimals = assetConfig.decimals;

        uint256 currPoolSupply = ledger.collateralTotalSupply(asset, reinvestment);
        uint256 currTotalShareSupply = totalCollateralShareSupply[collateral.poolId];

        uint256 balance = _toAmount(
            currUserCollateralShare,
            currTotalShareSupply,
            currPoolSupply.unitToRay(decimals)
        ).rayToUnit(decimals);

        if (claimable) {

            DataTypes.UserLiquidity memory currUserLiquidity = ledger.getUserLiquidity(user);

            if (currUserLiquidity.availableLeverageUsd <= 0) {
                return 0;
            }

            uint256 leverageFactor = ledger.getProtocolConfig().leverageFactor;

            (uint256 assetPrice, uint256 assetPriceUnit) = assetConfig.oracle.getAssetPrice(asset);

            uint256 ltvGwei = uint256(collateral.configuration.ltvGwei);

            uint256 maxAmount = uint256(currUserLiquidity.availableLeverageUsd)
            .wadDiv(leverageFactor)
            .wadDiv(ltvGwei.unitToWad(9))
            .wadDiv(assetPrice.unitToWad(assetPriceUnit))
            .wadToUnit(decimals);

            if (maxAmount < balance) {
                balance = maxAmount;
            }
        }

        return balance;
    }

    function getUserPosition(address user, address asset) external override view returns (int256) {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);

        (,,uint256 borrowIndex) = ledger.getReserveIndexes(asset);

        return _normalizedPositionRay(
            userData[user].positions[reserve.poolId],
            borrowIndex
        ).rayToUnit(assetConfig.decimals);
    }

    function _normalizedPositionRay(int256 scaledPosition, uint256 borrowIndex) internal pure returns (int256) {
        if (scaledPosition < 0) {
            uint256 absNormalizedPosition = scaledPosition.abs().rayMul(borrowIndex);
            return int256(absNormalizedPosition) * (- 1);
        } else {
            return scaledPosition;
        }
    }

    function _scaledPositionRay(int256 normalizedPosition, uint256 borrowIndex) internal pure returns (int256) {
        if (normalizedPosition < 0) {
            uint256 absScaledPosition = normalizedPosition.abs().rayDiv(borrowIndex);
            return int256(absScaledPosition) * (-1);
        } else {
            return normalizedPosition;
        }
    }

    function _toShare(uint256 amount, uint256 shareSupply, uint256 poolSupply) internal pure returns (uint256) {
        if (poolSupply == 0) {
            return amount;
        }
        return amount * shareSupply / poolSupply;
    }

    function _toAmount(uint256 share, uint256 shareSupply, uint256 poolSupply) internal pure returns (uint256) {
        if (shareSupply == 0) {
            return share;
        }
        return share * poolSupply / shareSupply;
    }

    modifier onlyLedger() {
        require(address(ledger) == msg.sender, Errors.CALLER_NOT_LEDGER);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

library UserConfiguration {

    function setUsingReserve(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingReserve
    ) internal {
        self.reserve = (self.reserve & ~(1 << bitIndex)) | (uint256(usingReserve ? 1 : 0) << bitIndex);
    }

    function setUsingCollateral(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingCollateral
    ) internal {
        self.collateral = (self.collateral & ~(1 << bitIndex)) | (uint256(usingCollateral ? 1 : 0) << bitIndex);
    }

    function setUsingPosition(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingPosition
    ) internal {
        self.position = (self.position & ~(1 << bitIndex)) | (uint256(usingPosition ? 1 : 0) << bitIndex);
    }

    function isUsingReserve(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.reserve >> bitIndex) & 1 != 0;
    }

    function isUsingCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.collateral >> bitIndex) & 1 != 0;
    }

    function isUsingPosition(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.position >> bitIndex) & 1 != 0;
    }

    function hasReserve(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.reserve >> offSetIndex) > 0;
    }

    function hasCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.collateral >> offSetIndex) > 0;
    }

    function hasPosition(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.position >> offSetIndex) > 0;
    }

    function isEmpty(DataTypes.UserConfiguration memory self) internal pure returns (bool) {
        return self.reserve == 0 && self.collateral == 0 && self.position == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface ILedger {

    function getProtocolConfig() external view returns (DataTypes.ProtocolConfig memory);

    function setProtocolConfig(DataTypes.ProtocolConfig memory config) external;

    function initAssetConfiguration(address asset) external returns (uint256 assetId);

    function setAssetConfiguration(address asset, DataTypes.AssetConfig memory configuration) external;

    function initReserve(address asset) external returns (uint256 poolId);

    function initCollateral(address asset, address reinvestment) external returns (uint256 poolId);

    function setReserveBonusPool(uint256 poolId, address newBonusPool) external;

    function setReserveReinvestment(uint256 poolId, address newReinvestment) external;

    function setReserveLongReinvestment(uint256 poolId, address newReinvestment) external;

    function setCollateralReinvestment(uint256 poolId, address newReinvestment) external;

    function setReserveConfiguration(uint256 poolId, DataTypes.ReserveConfiguration memory configuration) external;

    function setCollateralConfiguration(uint256 poolId, DataTypes.CollateralConfiguration memory configuration) external;

    function managePoolReinvestment(uint256 actionId, uint256 poolId) external;

    function getAssetConfiguration(address asset) external view returns (DataTypes.AssetConfig memory);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function getCollateralData(address asset, address reinvestment) external view returns (DataTypes.CollateralData memory);

    function getReserveIndexes(address asset) external view returns (uint256, uint256, uint256);

    function reserveSupplies(address asset) external view returns (uint256, uint256, uint256, uint256, uint256);

    function collateralTotalSupply(address asset, address reinvestment) external view returns (uint256);

    function getUserLiquidity(address user) external view returns (DataTypes.UserLiquidity memory);

    function depositReserve(address asset, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface IUserData {
    function depositReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function depositCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 currReserveSupply,
        uint256 decimals
    ) external;

    function changePosition(
        address user,
        uint256 pid,
        int256 incomingPosition,
        uint256 borrowIndex,
        uint256 decimals
    ) external;

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfiguration memory);

    function getUserReserve(address user, address asset, bool claimable) external view returns (uint256);

    function getUserCollateral(address user, address asset, address reinvestment, bool claimable) external view returns (uint256);

    function getUserCollateralInternal(address user, uint256 pid, uint256 currPoolSupply, uint256 decimals) external view returns (uint256);

    function getUserPosition(address user, address asset) external view returns (int256);

    function getUserPositionInternal(address user, uint256 pid, uint256 borrowIndex, uint256 decimals) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/
library MathUtils {
    uint256 public constant VERSION = 1;

    uint256 internal constant WAD_UNIT = 18;
    uint256 internal constant RAY_UNIT = 27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;
    uint256 public constant HALF_WAD = WAD / 2;
    uint256 public constant HALF_RAY = RAY / 2;


    /**
     * @notice Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_WAD) / b, "MathUtils: overflow");

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @notice Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, "MathUtils: overflow");

        return (a * WAD + halfB) / b;
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_RAY) / b, "MathUtils: overflow");

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, "MathUtils: overflow");

        return (a * RAY + halfB) / b;
    }

    /**
     * @notice Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, "MathUtils: overflow");

        return result / WAD_RAY_RATIO;
    }

    /**
     * @notice Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, "MathUtils: overflow");
        return result;
    }

    /**
     * @notice Converts unit to wad
     * @param self Value
     * @param unit Value's unit
     * @return value converted in wad
     **/
    function unitToWad(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD_UNIT) return self;

        if (unit < WAD_UNIT) {
            return self * 10**(WAD_UNIT - unit);
        } else {
            return self / 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * 10**(RAY_UNIT -unit);
        } else {
            return self / 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * int256(10**(RAY_UNIT -unit));
        } else {
            return self / int256(10**(unit - RAY_UNIT));
        }
    }

    /**
     * @notice Converts wad to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function wadToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD) return self;

        if (unit < WAD_UNIT) {
            return self / 10**(WAD_UNIT - unit);
        } else {
            return self * 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / 10**(RAY_UNIT - unit);
        } else {
            return self * 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / int256(10**(RAY_UNIT - unit));
        } else {
            return self * int256(10**(unit - RAY_UNIT));
        }
    }

    function abs(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(a * (-1));
        } else {
            return uint256(a);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Errors {
    string public constant LEDGER_INITIALIZED = 'LEDGER_INITIALIZED';
    string public constant CALLER_NOT_OPERATOR = 'CALLER_NOT_OPERATOR';
    string public constant CALLER_NOT_LIQUIDATE_EXECUTOR = 'CALLER_NOT_LIQUIDATE_EXECUTOR';
    string public constant CALLER_NOT_CONFIGURATOR = 'CALLER_NOT_CONFIGURATOR';
    string public constant CALLER_NOT_WHITELISTED = 'CALLER_NOT_WHITELISTED';
    string public constant CALLER_NOT_LEDGER = 'ONLY_LEDGER';
    string public constant INVALID_LEVERAGE_FACTOR = 'INVALID_LEVERAGE_FACTOR';
    string public constant INVALID_LIQUIDATION_RATIO = 'INVALID_LIQUIDATION_RATIO';
    string public constant INVALID_TRADE_FEE = 'INVALID_TRADE_FEE';
    string public constant INVALID_ZERO_ADDRESS = 'INVALID_ZERO_ADDRESS';
    string public constant INVALID_ASSET_CONFIGURATION = 'INVALID_ASSET_CONFIGURATION';
    string public constant ASSET_INACTIVE = 'ASSET_INACTIVE';
    string public constant ASSET_ACTIVE = 'ASSET_ACTIVE';
    string public constant POOL_INACTIVE = 'POOL_INACTIVE';
    string public constant POOL_ACTIVE = 'POOL_ACTIVE';
    string public constant POOL_EXIST = 'POOL_EXIST';
    string public constant INVALID_POOL_REINVESTMENT = 'INVALID_POOL_REINVESTMENT';
    string public constant ASSET_INITIALIZED = 'ASSET_INITIALIZED';
    string public constant ASSET_NOT_INITIALIZED = 'ASSET_NOT_INITIALIZED';
    string public constant POOL_INITIALIZED = 'POOL_INITIALIZED';
    string public constant POOL_NOT_INITIALIZED = 'POOL_NOT_INITIALIZED';
    string public constant INVALID_ZERO_AMOUNT = 'INVALID_ZERO_AMOUNT';
    string public constant CANNOT_SWEEP_REGISTERED_ASSET = 'CANNOT_SWEEP_REGISTERED_ASSET';
    string public constant INVALID_ACTION_ID = 'INVALID_ACTION_ID';
    string public constant INVALID_POSITION_TYPE = 'INVALID_POSITION_TYPE';
    string public constant INVALID_AMOUNT_INPUT = 'INVALID_AMOUNT_INPUT';
    string public constant INVALID_ASSET_INPUT = 'INVALID_ASSET_INPUT';
    string public constant INVALID_SWAP_BUFFER_LIMIT = 'INVALID_SWAP_BUFFER_LIMIT';
    string public constant NOT_ENOUGH_BALANCE = 'NOT_ENOUGH_BALANCE';
    string public constant NOT_ENOUGH_LONG_BALANCE = 'NOT_ENOUGH_LONG_BALANCE';
    string public constant NOT_ENOUGH_POOL_BALANCE = 'NOT_ENOUGH_POOL_BALANCE';
    string public constant NOT_ENOUGH_USER_LEVERAGE = 'NOT_ENOUGH_USER_LEVERAGE';
    string public constant MISSING_UNDERLYING_ASSET = 'MISSING_UNDERLYING_ASSET';
    string public constant NEGATIVE_PNL = 'NEGATIVE_PNL';
    string public constant NEGATIVE_AVAILABLE_LEVERAGE = 'NEGATIVE_AVAILABLE_LEVERAGE';
    string public constant BAD_TRADE = 'BAD_TRADE';
    string public constant USER_TRADE_BLOCK = 'USER_TRADE_BLOCK';
    string public constant ERROR_EMERGENCY_WITHDRAW = 'ERROR_EMERGENCY_WITHDRAW';
    string public constant ERROR_UNWRAP_LP = 'ERROR_UNWRAP_LP';
    string public constant CANNOT_TRADE_SAME_ASSET = 'CANNOT_TRADE_SAME_ASSET';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/ISwapAdapter.sol";
import "../interfaces/IPriceOracleGetter.sol";
import "../interfaces/IReinvestment.sol";
import "../interfaces/IBonusPool.sol";
import "../interfaces/IUserData.sol";

/// @dev This help resolves cyclic dependencies
library DataTypes {

    uint256 public constant VERSION = 1;

    address public constant LIQUIDATION_WALLET = 0x0000000000000000000000000000000000000001;

    enum AssetState {Disabled, Active, Withdrawing}

    enum PositionType {Long, Short}

    enum AssetMode {Disabled, OnlyReserve, OnlyLong, ReserveAndLong}

    enum AssetKind {SingleStable, SingleVolatile, LP}

    struct AssetStorage {
        uint256 assetsCount;
        mapping(uint256 => address) assetsList;
        mapping(address => DataTypes.AssetConfig) assetConfigs;
    }

    struct ReserveStorage {
        uint256 reservesCount;
        mapping(address => uint256) reservesList;
        mapping(uint256 => DataTypes.ReserveData) reserves;
    }

    struct CollateralStorage {
        uint256 collateralsCount;
        mapping(address => mapping(address => uint256)) collateralsList;
        mapping(uint256 => DataTypes.CollateralData) collaterals;
    }

    struct ProtocolConfig {
        address treasury;
        address configuratorAddress;
        address userData;
        uint256 leverageFactor;
        uint256 tradeFeeMantissa;
        uint256 liquidationRatioMantissa;
        uint256 swapBufferLimitPercentage;
    }

    struct MappingStorage {
        mapping(address => bool) whitelistedCallers;
        mapping(address => uint256) userLastTradeBlock;
        mapping(address => uint256) liquidatedCollaterals;
    }

    // Shared property of reserve, collateral and portfolio
    struct AssetConfig {
        uint256 assetId;
        uint8 decimals;
        AssetKind kind;
        ISwapAdapter swapAdapter;
        IPriceOracleGetter oracle;
    }

    struct ReserveConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 protocolRateMantissaGwei;
        uint32 utilizationBaseRateMantissaGwei;
        uint32 kinkMantissaGwei;
        uint32 multiplierAnnualGwei;
        uint32 jumpMultiplierAnnualGwei;
        // --- 208 bits used ---
        AssetState state;
        AssetMode mode;
    }

    struct ReserveDataExtension {
        address reinvestment;
        address longReinvestment;
        address bonusPool;
    }

    struct ReserveData {
        ReserveConfiguration configuration;
        ReserveDataExtension ext;
        address asset;
        uint256 poolId;
        uint256 liquidSupply;
        // scaled utilized supply on reserve, changes whenever a deposit, withdraw, borrow and repay is executed
        uint256 scaledUtilizedSupplyRay;
        uint256 longSupply;
        uint256 reserveIndexRay;
        uint256 utilizationPercentageRay;
        uint256 protocolIndexRay;
        uint256 lastUpdatedTimestamp;
    }

    struct ReserveDataCache {
        address asset;
        address reinvestment;
        address longReinvestment;
        uint256 currReserveIndexRay;
        uint256 currProtocolIndexRay;
        uint256 currBorrowIndexRay;
    }

    struct CollateralConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 ltvGwei;
        uint128 minBalance;
        // --- 192 bits used ---
        AssetState state;
    }

    struct CollateralData {
        CollateralConfiguration configuration;
        address asset;
        address reinvestment;
        uint256 poolId;
        uint256 liquidSupply;
        uint256 totalShareSupplyRay;
    }

    struct UserConfiguration {
        uint256 reserve;
        uint256 collateral;
        uint256 position;
    }

    struct UserData {
        UserConfiguration configuration;
        mapping(uint256 => uint256) reserveShares; // in ray
        mapping(uint256 => uint256) collateralShares; // in ray
        mapping(uint256 => int256) positions; // in ray
    }

    struct InitReserveData {
        address reinvestment;
        address bonusPool;
        address longReinvestment;
        uint32 depositFeeMantissa;
        uint32 protocolRateMantissaRay;
        uint32 utilizationBaseRateMantissaRay;
        uint32 kinkMantissaRay;
        uint32 multiplierAnnualRay;
        uint32 jumpMultiplierAnnualRay;
        AssetState state;
        AssetMode mode;
    }


    struct ValidateTradeParams {
        address user;
        uint256 amountToTrade;
        uint256 currShortReserveAvailableSupply;
        uint256 maxAmountToTrade;
        uint256 userLastTradeBlock;
    }

    struct UserLiquidity {
        uint256 totalCollateralUsdPreLtv;
        uint256 totalCollateralUsdPostLtv;
        uint256 totalLongUsd;
        uint256 totalShortUsd;
        int256 pnlUsd;
        int256 totalLeverageUsd;
        int256 availableLeverageUsd;
        bool isLiquidatable;
    }

    struct UserLiquidityCachedData {
        int256 currShortingPosition;
        int256 currLongingPosition;
        uint256 shortingPrice;
        uint256 shortingPriceDecimals;
        uint256 longingPrice;
        uint256 longingPriceDecimals;
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
pragma solidity 0.8.9;

interface ISwapAdapter {
    function swap(
        address selling,
        address buying,
        uint256 amount,
        bytes memory data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IReinvestmentProxy {
    function owner() external view returns (address);

    function logic() external view returns (address);

    function setLogic() external view returns (address);

    function supportedInterfaceId() external view returns (bytes4);
}

interface IReinvestmentLogic {

    event UpdatedTreasury(address oldAddress, address newAddress);
    event UpdatedFeeMantissa(uint256 oldFee, uint256 newFee);

    struct Reward {
        address asset;
        uint256 claimable;
    }

    function setTreasury(address treasury_) external;

    function setFeeMantissa(uint256 feeMantissa_) external;

    function asset() external view returns (address);

    function treasury() external view returns (address);

    function ledger() external view returns (address);

    function feeMantissa() external view returns (uint256);

    function receipt() external view returns (address);

    function platform() external view returns (address);

    function rewardOf(address, uint256) external view returns (Reward[] memory);

    function rewardLength() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim(address, uint256) external;

    function checkpoint(address, uint256) external;

    function invest(uint256) external;

    function divest(uint256) external;

    function emergencyWithdraw() external returns (uint256);

    function sweep(address) external;
}

interface IReinvestment is IReinvestmentProxy, IReinvestmentLogic {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBonusPool {
    function updatePoolUser(address _token, address _account, uint256 _amount) external;
}