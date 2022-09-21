pragma solidity ^0.8.0;

import "../characterManager/CharacterAccessControl.sol";
import "../interfaces/ICharacter.sol";
import "../interfaces/IMushroom.sol";

contract SkillUpgraderPhase1 is CharacterAccessControl {


    //mapping character => skill => level => shroom
    mapping(uint256 => mapping(string => mapping(uint256 => uint256))) public levelToShroom;
    //mapping(string => mapping(uint256 => uint256)) shroomToLevel;
    mapping(uint256 => mapping(string => uint256)) public maxLevel;
    mapping(bytes32 => bool) signature;


    mapping(uint256 => mapping(string => uint256)) public initialValues;
    mapping(uint256 => mapping(string => bool)) public nftInit;


    IMushroom shroomContract;
    address shroomController;
    ICharacter statsManager;
    uint256 maxClicks;

    // to generate random number
    address lastUser;
    uint256 lastTimestamp;

    event StatsUpgrade(address user, uint256 tokenId, string skill, uint256 oldLevel, uint256 increment,uint256 shrooms);

    constructor(
        IMushroom _shroom,
        address _shroomController,
        ICharacter _statsManager,
        uint256 _maxClicks
    ) {
        shroomContract = _shroom;
        shroomController = _shroomController;
        statsManager = _statsManager;
        maxClicks = _maxClicks;
    }

    function setMaxClicks(uint256 _new) public onlyRole(HANDLER_ROLE) {
        maxClicks = _new;

    }

    function addInitialValues(uint256[] memory _characters, string[] memory _skills, uint256[] memory _initialValues) public onlyRole(HANDLER_ROLE) {
        for (uint256 i = 0; i < _characters.length; i++) {
            initialValues[_characters[i]][_skills[i]] = _initialValues[i];
        }
    }

    function _character(uint256 _tokenId) internal pure returns (uint256) {
        uint256 mask = 0x00000000000000000000000000000000000000000000000FFFF0000;
        return (_tokenId & mask) >> 16;
    }

    function _isSignatureUsed(bytes32 sigHash) public returns (bool) {
        return signature[sigHash];
    }

    function isSignatureUsed(uint8 _v, bytes32 _r, bytes32 _s) public returns (bool) {
        bytes32 sigHash = keccak256(abi.encodePacked(_v, _r, _s));
        return signature[sigHash];
    }

    function _addLevel(uint256 _character_, string memory _skill, uint256 _level, uint256 _shroom) internal {
        levelToShroom[_character_][_skill][_level] = _shroom;
        //shroomToLevel[_skill][_shroom] = _level;
    }

    function addLevel(uint256 _character_, string memory _skill, uint256 _level, uint256 _shroom) public onlyRole(HANDLER_ROLE) {
        _addLevel(_character_, _skill, _level, _shroom);
    }

    // function addLevels(
    //     uint256 _character_,
    //     string[] memory _skills, 
    //     uint256[] memory _levels, 
    //     uint256[] memory _shrooms
    // ) public onlyRole(HANDLER_ROLE) {
    //     for(uint256 i=0;i<_skills.length;i++) {
    //         _addLevel(_character_,_skills[i],_levels[i],_shrooms[i]);
    //     }
    // }

    function addLevels(
        uint256 _character_,
        string memory _skill,
        uint256[] memory _levels,
        uint256[] memory _shrooms
    ) public onlyRole(HANDLER_ROLE) {
        for (uint256 i = 0; i < _levels.length; i++) {
            _addLevel(_character_, _skill, _levels[i], _shrooms[i]);
        }
    }

    function _setMaxLevel(uint256 _char, string memory _skill, uint256 _max) internal {
        maxLevel[_char][_skill] = _max;
    }

    function setMaxLevel(uint256 _char, string memory _skill, uint256 _max) public onlyRole(HANDLER_ROLE) {
        _setMaxLevel(_char, _skill, _max);
    }

    function setMaxLevels(uint256[]memory _char, string[] memory _skills, uint256[] memory _maxs) public onlyRole(HANDLER_ROLE) {
        for (uint256 i = 0; i < _skills.length; i++) {
            _setMaxLevel(_char[i], _skills[i], _maxs[i]);
        }
    }

    function _upgrade(
        address user,
        uint256 tokenId,
        string[] memory skills,
        uint256[] memory clicks,
        bytes32 hash
    ) internal {
        uint256[] memory newLevels = new uint256[](skills.length);
        uint256 character = _character(tokenId);
        uint256 shroomUsed = 0;
        uint256 currLevel;
        uint256 click;
        uint256 random;
        for (uint256 i = 0; i < skills.length; i++) {
            //            currLevel = currentLevels[i];
            if (!nftInit[tokenId][skills[i]]) {
                currLevel = initialValues[character][skills[i]];
            } else {
                currLevel = statsManager.get(tokenId, skills[i]);
            }

            if (currLevel >= maxLevel[character][skills[i]]) {
                continue;
            }

            click = clicks[i];
            if (click > maxClicks) {
                click = maxClicks;
            }

            for (uint256 j = 0; j < click; j++) {
                uint256 shroomForLevel = levelToShroom[character][skills[i]][currLevel];
                shroomUsed += shroomForLevel;
                (hash, random) = _generateRandomNumber(hash, 10 * i + j);
                if ((currLevel + random) > maxLevel[character][skills[i]]) {
                    random = maxLevel[character][skills[i]] - currLevel;
                    emit StatsUpgrade(user, tokenId, skills[i], currLevel, random,shroomForLevel);
                    currLevel += random;
                    break;
                }
                emit StatsUpgrade(user, tokenId, skills[i], currLevel, random,shroomForLevel);
                currLevel += random;
            }
            newLevels[i] = currLevel;
            nftInit[tokenId][skills[i]] = true;

        }

        shroomContract.transferFrom(user, shroomController, shroomUsed / 2);
        shroomContract.burnFrom(user, shroomUsed - shroomUsed / 2);
        statsManager.updateStats(tokenId, skills, newLevels);
    }


    function upgrade(
        uint256 tokenId,
        string memory requestId,
        string[] memory skills,
        uint256[] memory clicks,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public whenNotPaused {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenId, requestId));
        address signer = _validateSignature(hash, _v, _r, _s);
        require(hasRole(HANDLER_ROLE, signer), "Signer does not have a HANDLER_ROLE");
        _upgrade(msg.sender, tokenId, skills, clicks, hash);
        lastUser = msg.sender;
        lastTimestamp = block.timestamp;

    }


    function _generateRandomNumber(bytes32 hash, uint256 index) internal view returns (bytes32 seed, uint256 random) {
        seed = keccak256(abi.encodePacked(msg.sender, block.timestamp, hash, lastUser, lastTimestamp, index));
        random = uint256(seed) % 3 + 1;

    }

    function _validateSignature(bytes32 _hashedData, uint8 _v, bytes32 _r, bytes32 _s) public returns (address){
        bytes32 sigHash = keccak256(abi.encodePacked(_v, _r, _s));
        require(!_isSignatureUsed(sigHash), "Signature already used");
        signature[sigHash] = true;

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedData));
        return ecrecover(prefixedHashMessage,_v,_r,_s);
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

pragma solidity ^0.8.0;

interface ICharacter {
    function updateStats(uint256 _tokenId,string[] memory _attrib,uint256[] memory _value) external;
    function updateStat(uint256 _tokenId, string memory _attrib, uint256 _value) external;
    function setTokenName(uint256 _tokenId, string memory _name,string memory _uniqueName,address _user) external;
    function isNameUsed(string memory _name) external view returns (bool);
    function get(uint256 _tokenId, string memory _attr) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMushroom is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function mint(address account,uint256 amount) external;
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