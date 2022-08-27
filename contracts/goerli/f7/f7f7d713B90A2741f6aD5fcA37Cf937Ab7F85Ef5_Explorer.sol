// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./../interfaces/ISkyCastle.sol";
import "./../interfaces/ISkyCastleStats.sol";
import "./../interfaces/IItemVault.sol";
import "./../interfaces/IRegion.sol";

// import "hardhat/console.sol";

contract Explorer is AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant EXPLORER_ROLE = keccak256("EXPLORER_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    ISkyCastle private _castle;
    IItemVault private _itemVault;
    ISkyCastleStats private _castleStats;
    IRegion private _region;

    mapping(uint256 => uint256) public regionStartTime;
    mapping(uint256 => uint256) public activeRegion;
    mapping(uint256 => LiveAction) public liveActions;
    mapping(string => Action) public actionsRepository;

    struct Action {
        string name;
        uint8 stat;
        string payload;
        address to;
        uint256 duration;
        bool initialized;
    }

    struct LiveAction {
        uint256 castleId;
        uint256 regionId;
        string actionName;
        bool active;
        uint256 startTime;
        string buildingName;
    }

    constructor(
        address payable skyCastleAddress,
        address itemVaultAddress,
        address castleStats,
        address payable region
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MAINTAINER_ROLE, msg.sender);
        _grantRole(EXPLORER_ROLE, address(this));

        _castle = ISkyCastle(skyCastleAddress);
        _itemVault = IItemVault(itemVaultAddress);
        _castleStats = ISkyCastleStats(castleStats);
        _region = IRegion(region);
    }

    //------------------------------------------------------ Regions

    function getMyRegions(uint256 castleId) public view returns (uint256[] memory) {
        uint256 regionCount = getRegionCount(castleId);

        uint256[] memory _regions = new uint256[](regionCount);
        for (uint8 i = 0; i < regionCount; i++) {
            _regions[i] = getIdempotentRandom(_region.totalSupply(), castleId, regionStartTime[castleId] + i);
        }
        return _regions;
    }

    function getMyRegionNames(uint256 castleId) public view returns (string[] memory) {
        uint256 regionCount = getRegionCount(castleId);

        uint256[] memory _ids = getMyRegions(castleId);

        string[] memory _regions = new string[](regionCount);
        for (uint8 i = 0; i < regionCount; i++) {
            _regions[i] = _region.regionName(_ids[i]);
        }
        return _regions;
    }

    // Assumes the UI has served `getMyRegions` and the user is providing an index within that array
    function chooseRegion(uint256 castleId, uint256 regionIndex) public {
        require(block.timestamp > regionStartTime[castleId] + getRegionLock(castleId), "Region choice hasn't expired yet");
        require(msg.sender == _castle.ownerOf(castleId), "can only explore with a castle you own");

        uint256[] memory regionIds = getMyRegions(castleId);
        require(regionIndex < regionIds.length, "Region index out of bounds");

        activeRegion[castleId] = regionIds[regionIndex];
        regionStartTime[castleId] = block.timestamp;
    }

    function getMyActiveRegion(uint256 castleId) public view returns (string memory) {
        require(block.timestamp < regionStartTime[castleId] + getRegionLock(castleId), "No Active Region");

        return _region.regionName(activeRegion[castleId]);
    }

    //------------------------------------------------------ Buildings

    function getMyBuildings(uint256 castleId) public view returns (string[] memory) {
        // console.log(
        //     "getMyBuildings curTime: %s, unlocks at: %s",
        //     block.timestamp,
        //     regionStartTime[castleId] + getRegionLock(castleId)
        // );
        require(block.timestamp < regionStartTime[castleId] + getRegionLock(castleId), "No Active Region for buildings");

        return _region.getBuildingNames(activeRegion[castleId]);
    }

    //------------------------------------------------------ Actions

    function getActions(uint256 castleId, string memory buildingName) public view returns (string[] memory) {
        // console.log(
        //     "getActions curTime: %s, unlocks at: %s",
        //     block.timestamp,
        //     regionStartTime[castleId] + getRegionLock(castleId)
        // );

        require(block.timestamp < regionStartTime[castleId] + getRegionLock(castleId), "No Active Region for actions");

        return _region.getBuildingActions(activeRegion[castleId], buildingName);
    }

    function performAction(
        uint256 castleId,
        uint256 buildingIndex,
        uint256 actionIndex
    ) public {
        require(block.timestamp < regionStartTime[castleId] + getRegionLock(castleId), "Region not selected");
        require(msg.sender == _castle.ownerOf(castleId), "can only explore with a castle you own");

        uint256 regionId = activeRegion[castleId];

        string[] memory buildingNames = getMyBuildings(castleId);
        require(buildingIndex < buildingNames.length, "Building index out of bounds");

        string[] memory actionNames = getActions(castleId, buildingNames[buildingIndex]);
        require(actionIndex < actionNames.length, "Action index out of bounds");

        liveActions[castleId] = LiveAction({
            castleId: castleId,
            regionId: regionId,
            actionName: actionNames[actionIndex],
            startTime: block.timestamp,
            active: true,
            buildingName: buildingNames[buildingIndex]
        });
    }

    function resolveAction(uint256 castleId) public {
        require(block.timestamp < regionStartTime[castleId] + getRegionLock(castleId), "Region not selected");
        require(msg.sender == _castle.ownerOf(castleId), "can only explore with a castle you own");
        require(liveActions[castleId].active, "No action is currently active");

        Action memory action = actionsRepository[liveActions[castleId].actionName];
        require(block.timestamp > liveActions[castleId].startTime + action.duration, "Action hasn't expired yet");

        liveActions[castleId].active = false;

        (bool success, ) = action.to.call(abi.encodeWithSignature(action.payload, action.name, castleId));

        require(success, "action failed");
    }

    function addAction(
        string calldata name,
        uint256 _duration,
        uint8 _stat,
        string calldata _payload,
        address _to
    ) public onlyRole(MAINTAINER_ROLE) {
        require(!actionsRepository[name].initialized, "Action already exists");

        actionsRepository[name] = Action({
            name: name,
            stat: _stat,
            payload: _payload,
            to: _to,
            duration: _duration,
            initialized: true
        });
    }

    // ------------------------------------------------------ Actionable

    function rollForLoot(string memory actionName, uint256 castleId) public onlyRole(EXPLORER_ROLE) {
        // console.log("rolling");

        _itemVault.rollForLoot(actionName, castleId);

        //TODO boost stat value if needed
    }

    //------------------------------------------------------ Stats

    function getRegionLock(uint256 tokenId) public pure returns (uint256) {
        //TODO region lock based on a stat is shorter better?
        return 7 days;
    }

    function getRegionCount(uint256 tokenId) public pure returns (uint256) {
        //TODO region count based on a stat
        return 3;
    }

    //------------------------------------------------------ Utils

    function getIdempotentRandom(
        uint256 outOf,
        uint256 first,
        uint256 second
    ) internal view virtual returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(msg.sender, first, second))) % outOf);
    }

    // Observatory astromancy
    // Ruins geomancy
    // Fire Dance Lunacy

    // authority,
    // sustainability,
    // resiliency,
    // literacy,
    // creativity,
    // culture

    // astromancy,
    // horomancy,
    // geomancy,
    // technomancy,
    // lunacy

    //players can submit an action against a building using their stats to influence the outcome

    // build
    // socialize
    // scavenge  materials
    // harvest drinks
    // dig
    // hunt food
    // observe
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISkyCastle {
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISkyCastleStats {
    function calculateStatsForMint(uint256 tokenId) external;

    function getMintPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IItemVault {
    function rollForLoot(string memory tableName, uint256 castleId) external returns (address);

    function rollForBulkLoot(
        string memory tableName,
        uint256 castleId,
        uint256 amount
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRegion {
    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);

    function regionName(uint256 id) external view returns (string memory);

    function getBuildingNames(uint256 id) external view returns (string[] memory);

    function getBuildingActions(uint256 id, string memory buildingName) external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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