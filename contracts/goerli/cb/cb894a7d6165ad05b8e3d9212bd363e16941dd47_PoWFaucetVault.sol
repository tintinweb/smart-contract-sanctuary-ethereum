/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





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
        _checkRole(role);
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
}

// File: contracts/test.sol


pragma solidity ^0.8.15;

// Contract Factory: 0xd58660caD6E1eeeaFf48647c10Fd49428E6277D9 / Salt: 1
// Source Code:  608060405234801561001057600080fd5b506040516111a63803806111a683398101604081905261002f916100df565b61003a600082610040565b5061010f565b6000828152602081815260408083206001600160a01b038516845290915290205460ff166100db576000828152602081815260408083206001600160a01b03851684529091529020805460ff1916600117905561009a3390565b6001600160a01b0316816001600160a01b0316837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45b5050565b6000602082840312156100f157600080fd5b81516001600160a01b038116811461010857600080fd5b9392505050565b6110888061011e6000396000f3fe6080604052600436106100e15760003560e01c80635b05b8e71161007f578063c1756a2c11610059578063c1756a2c14610257578063d547741f14610277578063e2cf801c14610297578063eb5a662e146102b757600080fd5b80635b05b8e71461020257806391d1485414610222578063a217fddf1461024257600080fd5b80632e1a7d4d116100bb5780632e1a7d4d146101825780632f2ff15d146101a25780632fdcfbd2146101c257806336568abe146101e257600080fd5b806301ffc9a7146100ed57806304acbb9914610122578063248a9ca31461014457600080fd5b366100e857005b600080fd5b3480156100f957600080fd5b5061010d610108366004610d5d565b6102d7565b60405190151581526020015b60405180910390f35b34801561012e57600080fd5b5061014261013d366004610da3565b61030e565b005b34801561015057600080fd5b5061017461015f366004610dd6565b60009081526020819052604090206001015490565b604051908152602001610119565b34801561018e57600080fd5b5061014261019d366004610dd6565b61034f565b3480156101ae57600080fd5b506101426101bd366004610def565b610576565b3480156101ce57600080fd5b506101426101dd366004610e1b565b6105a0565b3480156101ee57600080fd5b506101426101fd366004610def565b610737565b34801561020e57600080fd5b5061017461021d366004610e57565b6107b5565b34801561022e57600080fd5b5061010d61023d366004610def565b61084f565b34801561024e57600080fd5b50610174600081565b34801561026357600080fd5b50610142610272366004610e57565b610878565b34801561028357600080fd5b50610142610292366004610def565b6109b4565b3480156102a357600080fd5b506101426102b2366004610e81565b6109d9565b3480156102c357600080fd5b506101746102d2366004610e81565b6109f0565b60006001600160e01b03198216637965db0b60e01b148061030857506301ffc9a760e01b6001600160e01b03198316145b92915050565b600061031981610a67565b5060408051808201825292835260208084019283526001600160a01b039094166000908152600194859052209151825551910155565b600061035a336109f0565b9050600081116103a55760405162461bcd60e51b81526020600482015260116024820152701dda5d1a191c985dd85b0819195b9a5959607a1b60448201526064015b60405180910390fd5b808211156103f55760405162461bcd60e51b815260206004820152601860248201527f616d6f756e74206578636565647320616c6c6f77616e63650000000000000000604482015260640161039c565b478211156104455760405162461bcd60e51b815260206004820152601c60248201527f616d6f756e742065786365656473207661756c742062616c616e636500000000604482015260640161039c565b336000818152600360209081526040808320548151808301835242815280840188815295855260028452828520828652909352922090518155915160019283015590610492908290610eb2565b3360008181526003602090815260409182902093909355805142815292830186905290917f208daaa35021650dedef7f64aea5dd5b67a87db19dad6af3ffba779748e7a2e8910160405180910390a2604051600090339085908381818185875af1925050503d8060008114610523576040519150601f19603f3d011682016040523d82523d6000602084013e610528565b606091505b50509050806105705760405162461bcd60e51b81526020600482015260146024820152733330b4b632b2103a379039b2b7321032ba3432b960611b604482015260640161039c565b50505050565b60008281526020819052604090206001015461059181610a67565b61059b8383610a74565b505050565b60006105ab81610a67565b6040516370a0823160e01b815230600482015284906000906001600160a01b038316906370a0823190602401602060405180830381865afa1580156105f4573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906106189190610eca565b90506000811161065f5760405162461bcd60e51b81526020600482015260126024820152710746f6b656e2062616c616e636520697320360741b604482015260640161039c565b838110156106bb5760405162461bcd60e51b815260206004820152602360248201527f616d6f756e7420697320626967676572207468616e20746f6b656e2062616c616044820152626e636560e81b606482015260840161039c565b60405163a9059cbb60e01b81526001600160a01b0386811660048301526024820186905283169063a9059cbb906044016020604051808303816000875af115801561070a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061072e9190610ee3565b50505050505050565b6001600160a01b03811633146107a75760405162461bcd60e51b815260206004820152602f60248201527f416363657373436f6e74726f6c3a2063616e206f6e6c792072656e6f756e636560448201526e103937b632b9903337b91039b2b63360891b606482015260840161039c565b6107b18282610af8565b5050565b6001600160a01b038216600090815260036020526040812054815b811561084757816107e081610f05565b6001600160a01b0387166000908152600260209081526040808320848452825291829020825180840190935280548084526001909101549183019190915291945091508511156108305750610847565b602081015161083f9083610eb2565b9150506107d0565b949350505050565b6000918252602082815260408084206001600160a01b0393909316845291905290205460ff1690565b600061088381610a67565b47806108c35760405162461bcd60e51b815260206004820152600f60248201526e77616c6c657420697320656d70747960881b604482015260640161039c565b828110156109135760405162461bcd60e51b815260206004820152601a60248201527f6e6f7420656e6f7567682066756e647320696e2077616c6c6574000000000000604482015260640161039c565b6000846001600160a01b03168460405160006040518083038185875af1925050503d8060008114610960576040519150601f19603f3d011682016040523d82523d6000602084013e610965565b606091505b50509050806109ad5760405162461bcd60e51b81526020600482015260146024820152733330b4b632b2103a379039b2b7321032ba3432b960611b604482015260640161039c565b5050505050565b6000828152602081905260409020600101546109cf81610a67565b61059b8383610af8565b60006109e481610a67565b816001600160a01b0316ff5b6001600160a01b03811660009081526001602081815260408084208151808301909252805480835293015491810191909152908015610a60576000610a3f8584602001514261021d9190610f1c565b9050818110610a515760009150610a5e565b610a5b8183610f1c565b91505b505b9392505050565b610a718133610b5d565b50565b610a7e828261084f565b6107b1576000828152602081815260408083206001600160a01b03851684529091529020805460ff19166001179055610ab43390565b6001600160a01b0316816001600160a01b0316837f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45050565b610b02828261084f565b156107b1576000828152602081815260408083206001600160a01b0385168085529252808320805460ff1916905551339285917ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b9190a45050565b610b67828261084f565b6107b157610b7f816001600160a01b03166014610bc1565b610b8a836020610bc1565b604051602001610b9b929190610f5f565b60408051601f198184030181529082905262461bcd60e51b825261039c91600401610fd4565b60606000610bd0836002611007565b610bdb906002610eb2565b67ffffffffffffffff811115610bf357610bf3611026565b6040519080825280601f01601f191660200182016040528015610c1d576020820181803683370190505b509050600360fc1b81600081518110610c3857610c3861103c565b60200101906001600160f81b031916908160001a905350600f60fb1b81600181518110610c6757610c6761103c565b60200101906001600160f81b031916908160001a9053506000610c8b846002611007565b610c96906001610eb2565b90505b6001811115610d0e576f181899199a1a9b1b9c1cb0b131b232b360811b85600f1660108110610cca57610cca61103c565b1a60f81b828281518110610ce057610ce061103c565b60200101906001600160f81b031916908160001a90535060049490941c93610d0781610f05565b9050610c99565b508315610a605760405162461bcd60e51b815260206004820181905260248201527f537472696e67733a20686578206c656e67746820696e73756666696369656e74604482015260640161039c565b600060208284031215610d6f57600080fd5b81356001600160e01b031981168114610a6057600080fd5b80356001600160a01b0381168114610d9e57600080fd5b919050565b600080600060608486031215610db857600080fd5b610dc184610d87565b95602085013595506040909401359392505050565b600060208284031215610de857600080fd5b5035919050565b60008060408385031215610e0257600080fd5b82359150610e1260208401610d87565b90509250929050565b600080600060608486031215610e3057600080fd5b610e3984610d87565b9250610e4760208501610d87565b9150604084013590509250925092565b60008060408385031215610e6a57600080fd5b610e7383610d87565b946020939093013593505050565b600060208284031215610e9357600080fd5b610a6082610d87565b634e487b7160e01b600052601160045260246000fd5b60008219821115610ec557610ec5610e9c565b500190565b600060208284031215610edc57600080fd5b5051919050565b600060208284031215610ef557600080fd5b81518015158114610a6057600080fd5b600081610f1457610f14610e9c565b506000190190565b600082821015610f2e57610f2e610e9c565b500390565b60005b83811015610f4e578181015183820152602001610f36565b838111156105705750506000910152565b7f416363657373436f6e74726f6c3a206163636f756e7420000000000000000000815260008351610f97816017850160208801610f33565b7001034b99036b4b9b9b4b733903937b6329607d1b6017918401918201528351610fc8816028840160208801610f33565b01602801949350505050565b6020815260008251806020840152610ff3816040850160208701610f33565b601f01601f19169190910160400192915050565b600081600019048311821515161561102157611021610e9c565b500290565b634e487b7160e01b600052604160045260246000fd5b634e487b7160e01b600052603260045260246000fdfea2646970667358221220fa81a335da228f74f48bb49bde7af2951e02ec10e83f544e3a10e162ced2851364736f6c634300080f0033000000000000000000000000332e43696a505ef45b9319973785f837ce5267b9
// Constructor:  000000000000000000000000332e43696a505ef45b9319973785f837ce5267b9
// Contract Address:  0xA5058fbcD09425e922E3E9e78D569aB84EdB88Eb


interface IERC20Interface {
  function transfer(address _to, uint256 _value) external returns (bool success);
  function balanceOf(address account) external view returns (uint256);
}

struct FaucetAllowance {
  uint256 amount;
  uint256 interval;
}

struct FaucetWithdrawal {
  uint256 time;
  uint256 amount;
}

contract PoWFaucetVault is AccessControl {

  mapping(address => FaucetAllowance) private _faucetAllowances;
  mapping(address => mapping(uint256 => FaucetWithdrawal)) private _faucetWithdrawals;
  mapping(address => uint256) private _faucetWithdrawalCount;

  event FaucetWithdraw(address indexed faucet, uint time, uint amount);

  constructor(address owner) {
    _grantRole(DEFAULT_ADMIN_ROLE, owner);
  }

  function sendToken(address tokenAddr, address addr, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20Interface token = IERC20Interface(tokenAddr);
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "token balance is 0");
    require(balance >= amount, "amount is bigger than token balance");
    token.transfer(addr, amount);
  }

  function sendEther(address addr, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint balance = address(this).balance;
    require(balance > 0, "wallet is empty");
    require(balance >= amount, "not enough funds in wallet");

    (bool sent, ) = payable(addr).call{value: amount}("");
    require(sent, "failed to send ether");
  }

  function _selfdestruct(address addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
    selfdestruct(payable(addr));
  }


  receive() external payable {
  }

  function setAllowance(address addr, uint256 amount, uint256 interval) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _faucetAllowances[addr] = FaucetAllowance({
      amount: amount,
      interval: interval
    });
  }

  function getWithdrawnAmount(address addr, uint256 time) public view returns (uint256) {
    uint256 withdrawalIndex = _faucetWithdrawalCount[addr];
    uint256 amount = 0;
    while(withdrawalIndex > 0) {
      withdrawalIndex--;
      FaucetWithdrawal memory withdrawal = _faucetWithdrawals[addr][withdrawalIndex];
      if(withdrawal.time < time)
        break;
      amount += withdrawal.amount;
    }
    return amount;
  }

  function getAllowance(address addr) public view returns (uint256) {
    FaucetAllowance memory allowance = _faucetAllowances[addr];
    uint256 amount = allowance.amount;
    if(amount > 0) {
      uint256 withdrawn = getWithdrawnAmount(addr, block.timestamp - allowance.interval);
      if(withdrawn >= amount)
        amount = 0;
      else
        amount -= withdrawn;
    }
    return amount;
  }

  function withdraw(uint256 amount) public {
    uint256 allowance = getAllowance(msg.sender);
    require(allowance > 0, "withdrawal denied");
    require(amount <= allowance, "amount exceeds allowance");
    require(amount <= address(this).balance, "amount exceeds vault balance");

    uint256 withdrawalIndex = _faucetWithdrawalCount[msg.sender];
    _faucetWithdrawals[msg.sender][withdrawalIndex] = FaucetWithdrawal({
      time: block.timestamp,
      amount: amount
    });
    _faucetWithdrawalCount[msg.sender] = withdrawalIndex + 1;

    emit FaucetWithdraw(msg.sender, block.timestamp, amount);

    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "failed to send ether");
  }

}