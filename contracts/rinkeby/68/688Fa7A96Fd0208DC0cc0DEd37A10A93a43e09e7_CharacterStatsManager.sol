pragma solidity ^0.8.0;

import "./CharacterStats.sol";

contract CharacterStatsManager is CharacterStats {


    mapping(uint256 => mapping(string => uint256)) private tokenAttributes;
    mapping(uint256 => string) private tokenName;
    mapping(string => bool) public  isNameUsed;

    event StatUpdated(uint256 tokenId, string attribute, uint256 value);
    event TokenNameUpdated(uint256 tokenId, string tokenName, address owner, uint256 timestamp);

    constructor()
    CharacterStats()
    {

    }

    function getTokenAttributeMaxValue(uint256 _tokenId, string memory _attr) public view returns (uint256) {
        return getCharacterAttributeMaxValue(_character(_tokenId), _attr);
    }

    function isSupportedTokenAttribute(uint256 _tokenId, string memory _attr) public view returns (bool) {
        return isSupportedCharacterAttribute(_character(_tokenId), _attr);
    }

    function _character(uint256 _tokenId) internal pure returns (uint256) {
        uint256 mask = 0x00000000000000000000000000000000000000000000000FFFF0000;
        return (_tokenId & mask) >> 16;
    }

    function character(uint256 _tokenId) public override view returns (uint256){
        return _character(_tokenId);
    }

    function get(uint256 _tokenId, string memory _attr) public view returns (uint256){
        require(isSupportedTokenAttribute(_tokenId, _attr), "Token does not support the attribute");
        return tokenAttributes[_tokenId][_attr];
    }

    function name(uint256 _tokenId) public view returns (string memory){
        return tokenName[_tokenId];
    }

    function setTokenName(uint256 _tokenId, string memory _name, string memory _uniqueName, address _user) public whenNotPaused onlyRole(HANDLER_ROLE) {
        require(!isNameUsed[_uniqueName], "Name already used");
        isNameUsed[_uniqueName] = true;
        tokenName[_tokenId] = _name;
        emit TokenNameUpdated(_tokenId, _name, msg.sender, block.timestamp);
    }


    function _updateStat(uint256 _tokenId, string memory _attr, uint256 _val) internal {
        tokenAttributes[_tokenId][_attr] = _val;
    }

    function _updateStat_(uint256 _tokenId, string memory _attrib, uint256 _value) internal {
        require(_value <= getTokenAttributeMaxValue(_tokenId, _attrib), "Max value for attribute exceeded");
        _updateStat(_tokenId, _attrib, _value);
        emit StatUpdated(_tokenId, _attrib, _value);
    }


    function updateStats(uint256 _tokenId, string[] memory _attrib, uint256[] memory _value) public onlyRole(HANDLER_ROLE) whenNotPaused {
        uint256 total = _attrib.length;
        for (uint i = 0; i < total; i++) {
            _updateStat_(_tokenId, _attrib[i], _value[i]);
        }
    }

    function updateStat(uint256 _tokenId, string memory _attrib, uint256 _value)
    public
    onlyRole(HANDLER_ROLE)
    whenNotPaused
    {
        _updateStat_(_tokenId, _attrib, _value);
    }

}

pragma solidity ^0.8.0;

import "./CharacterAccessControl.sol";

abstract contract CharacterStats is CharacterAccessControl {
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 internal constant UNKNOWN = 0x0000;
    uint256 internal constant ALICE = 0x0001;
    uint256 internal constant QUEEN = 0x0002;
    //uint256 private constant CARD = 0x0003;
    uint256 internal constant CLUBS_OF_RUNNER = 0x0013;
    uint256 internal constant DIAMOND_OF_ENERGY = 0x0023;
    uint256 internal constant SPADES_OF_MARKER = 0x0033;
    uint256 internal constant HEART_OF_ALL_ROUNDER = 0x0043;

    mapping(uint256 => mapping(string => uint256)) internal attributeMaxValues;

    event NewAttribute(uint256 character, string attribute, uint256 max);

    constructor()
    CharacterAccessControl()
    {
        _initializeSupportedAttributes();
    }

    function _initializeSupportedAttributes() internal {

        _addAttribute(ALICE, "XP", MAX_INT);
        _addAttribute(QUEEN, "XP", MAX_INT);
        _addAttribute(CLUBS_OF_RUNNER, "XP", MAX_INT);
        _addAttribute(DIAMOND_OF_ENERGY, "XP", MAX_INT);
        _addAttribute(SPADES_OF_MARKER, "XP", MAX_INT);
        _addAttribute(HEART_OF_ALL_ROUNDER, "XP", MAX_INT);

        _addAttribute(ALICE, "LEVEL", 100);
        _addAttribute(QUEEN, "LEVEL", 100);
        _addAttribute(CLUBS_OF_RUNNER, "LEVEL", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "LEVEL", 100);
        _addAttribute(SPADES_OF_MARKER, "LEVEL", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "LEVEL", 100);

        _addAttribute(ALICE, "GENERATION", MAX_INT);
        _addAttribute(QUEEN, "GENERATION", MAX_INT);
        _addAttribute(CLUBS_OF_RUNNER, "GENERATION", MAX_INT);
        _addAttribute(DIAMOND_OF_ENERGY, "GENERATION", MAX_INT);
        _addAttribute(SPADES_OF_MARKER, "GENERATION", MAX_INT);
        _addAttribute(HEART_OF_ALL_ROUNDER, "GENERATION", MAX_INT);

        _addAttribute(ALICE, "MINT", MAX_INT);
        _addAttribute(QUEEN, "MINT", MAX_INT);
        _addAttribute(CLUBS_OF_RUNNER, "MINT", MAX_INT);
        _addAttribute(DIAMOND_OF_ENERGY, "MINT", MAX_INT);
        _addAttribute(SPADES_OF_MARKER, "MINT", MAX_INT);
        _addAttribute(HEART_OF_ALL_ROUNDER, "MINT", MAX_INT);


        // ALICE tokenAttributes
        _addAttribute(ALICE, "CURIOSITY", 100);
        _addAttribute(ALICE, "CURIOSITY_POTENTIAL", 100);
        _addAttribute(ALICE, "SECTOR", MAX_INT);


        // QUEEN tokenAttributes
        _addAttribute(QUEEN, "ORDER", 100);
        _addAttribute(QUEEN, "ORDER_POTENTIAL", 100);
        _addAttribute(QUEEN, "SECTOR", MAX_INT);

        //card tokenAttributes sector,stamina rest luck prestige);
        _addAttribute(CLUBS_OF_RUNNER, "SECTOR", 150);
        _addAttribute(DIAMOND_OF_ENERGY, "SECTOR", 150);
        _addAttribute(SPADES_OF_MARKER, "SECTOR", 150);
        _addAttribute(HEART_OF_ALL_ROUNDER, "SECTOR", 150);

        _addAttribute(CLUBS_OF_RUNNER, "STAMINA", 200);
        _addAttribute(DIAMOND_OF_ENERGY, "STAMINA", 100);
        _addAttribute(SPADES_OF_MARKER, "STAMINA", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "STAMINA", 150);


        //Stamina Potential for the cards
        _addAttribute(CLUBS_OF_RUNNER, "STAMINA_POTENTIAL", 200);
        _addAttribute(DIAMOND_OF_ENERGY, "STAMINA_POTENTIAL", 100);
        _addAttribute(SPADES_OF_MARKER, "STAMINA_POTENTIAL", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "STAMINA_POTENTIAL", 150);

        //Rest for cards
        _addAttribute(CLUBS_OF_RUNNER, "REST", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "REST", 200);
        _addAttribute(SPADES_OF_MARKER, "REST", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "REST", 150);

        //Rest Potential for cards
        _addAttribute(CLUBS_OF_RUNNER, "REST_POTENTIAL", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "REST_POTENTIAL", 200);
        _addAttribute(SPADES_OF_MARKER, "REST_POTENTIAL", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "REST_POTENTIAL", 150);

        //Luck for cards
        _addAttribute(CLUBS_OF_RUNNER, "LUCK", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "LUCK", 100);
        _addAttribute(SPADES_OF_MARKER, "LUCK", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "LUCK", 100);

        //Luck Potential for cards
        _addAttribute(CLUBS_OF_RUNNER, "LUCK_POTENTIAL", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "LUCK_POTENTIAL", 100);
        _addAttribute(SPADES_OF_MARKER, "LUCK_POTENTIAL", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "LUCK_POTENTIAL", 100);

        //Prestige for cards
        _addAttribute(CLUBS_OF_RUNNER, "PRESTIGE", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "PRESTIGE", 100);
        _addAttribute(SPADES_OF_MARKER, "PRESTIGE", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "PRESTIGE", 100);


        //Prestige Potential for cards
        _addAttribute(CLUBS_OF_RUNNER, "PRESTIGE_POTENTIAL", 100);
        _addAttribute(DIAMOND_OF_ENERGY, "PRESTIGE_POTENTIAL", 100);
        _addAttribute(SPADES_OF_MARKER, "PRESTIGE_POTENTIAL", 100);
        _addAttribute(HEART_OF_ALL_ROUNDER, "PRESTIGE_POTENTIAL", 100);

        //Extra Stamina for club and heart
        _addAttribute(CLUBS_OF_RUNNER, "EXTRA_STAMINA", 6);
        _addAttribute(HEART_OF_ALL_ROUNDER, "EXTRA_STAMINA", 2);

        //Extra Recovery for diamond and heart
        _addAttribute(DIAMOND_OF_ENERGY, "EXTRA_RECOVERY", 6);
        _addAttribute(HEART_OF_ALL_ROUNDER, "EXTRA_RECOVERY", 2);

        //Ground for spades and heart
        _addAttribute(SPADES_OF_MARKER, "GROUND", 6);
        _addAttribute(HEART_OF_ALL_ROUNDER, "GROUND", 2);
    }

    function character(uint256 _tokenId) public virtual view returns (uint256){
        return 0;
    }

    function _addAttribute(uint256 _character, string memory _attr, uint256 _maxValue) internal {
        attributeMaxValues[_character][_attr] = _maxValue;
    }

    function addAttribute(uint256 _character, string memory _attr, uint256 _maxValue) public onlyRole(OWNER_ROLE) {
        require(_character != 0x0000, "Character must not be unknown");
        require(_maxValue > 0, "Max value cannot be Zero");
        _addAttribute(_character, _attr, _maxValue);
        emit NewAttribute(_character, _attr, _maxValue);
    }

    function getCharacterAttributeMaxValue(uint256 _character, string memory _attr) public view returns (uint256){
        require(isSupportedCharacterAttribute(_character, _attr), "Attribute is not supported");
        return attributeMaxValues[_character][_attr];
    }

    function isSupportedCharacterAttribute(uint256 _character, string memory _attr) public view returns (bool) {
        return attributeMaxValues[_character][_attr] > 0;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract CharacterAccessControl is AccessControl {
    bytes32 internal constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;
    bytes32 internal constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256(abi.encodePacked("MINTER_ROLE"));
    bytes32 internal constant HANDLER_ROLE = 0x8ee6ed50dc250dbccf4d86bd88d4956ab55c7de37d1fed5508924b70da11fe8b;

    //ToDo: change this owner address in mainnet
    address internal _owner_ = 0x698c514c49C3E1C4285fc87674De84cd56A72646;
    address internal handler = 0x698c514c49C3E1C4285fc87674De84cd56A72646;

    bool public isPaused;

    modifier whenNotPaused {
        require(!isPaused, "Wonder Game Character Inventory is paused");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner_);
        _setupRole(OWNER_ROLE, _owner_);
        _setupRole(HANDLER_ROLE,handler);
    }

    function pause() public onlyRole(OWNER_ROLE) {
        isPaused = true;
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        isPaused = false;
    }
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