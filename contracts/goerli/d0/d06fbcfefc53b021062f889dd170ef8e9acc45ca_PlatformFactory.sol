/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory events ]]]]]]]]]]]

    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address indexed clone
    );

    event FactoryImplementationSet(
        address indexed factory,
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// > [[[[[[[[[[[ Clone events ]]]]]]]]]]]

    event ContentSet(
        address indexed clone,
        uint256 indexed bundleId,
        string bundleJSON,
        address indexed owner
    );

    event PlatformMetadataSet(address indexed clone, string metadataJSON);

    event RoleSet(
        address indexed clone,
        address indexed account,
        bytes32 indexed role,
        bool granted
    );
}

interface IObservability {
    function emitDeploymentEvent(address owner, address clone) external;

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external;

    function emitContentSet(
        uint256 bundleId,
        string calldata bundleJSON,
        address owner
    ) external;

    function emitPlatformMetadataSet(string calldata metadataJSON) external;

    function emitRoleSet(
        address account,
        bytes32 role,
        bool granted
    ) external;
}

interface IPlatform {
    struct PlatformData {
        string platformMetadataJSON;
        address[] publishers;
        address[] metadataManagers;
        uint256 nonce;
    }

    struct BundleData {
        bytes32 contentHash;
        address owner;
    }

    struct PublishAuthorization {
        string message;
        address platform;
        address publishingKey;
        uint256 nonce;
    }

    struct RoleRequest {
        address account;
        bytes32 role;
        bool grant;
    }

    function CONTENT_PUBLISHER_ROLE() external view returns (bytes32);

    function METADATA_MANAGER_ROLE() external view returns (bytes32);

    function VERSION() external view returns (uint8);

    function factory() external returns (address);

    function o11y() external returns (address);

    function getDefaultAdminRole() external view returns (bytes32);

    function addContent(string calldata bundleJSON, address owner) external;

    function setContent(uint256 bundleId, string calldata bundleJSON) external;

    function setPlatformMetadata(string calldata _platformMetadataJSON)
        external;

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function getSigningMessage(address signer) external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
abstract contract AccessControl is IAccessControl, ERC165 {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
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
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

    function _msgSender() internal view virtual returns (address ret);
}

// solhint-disable no-inline-assembly

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

contract Platform is AccessControl, IPlatform, ERC2771Recipient {
    /*//////////////////////////////////////////////////////////////
                            Version
    //////////////////////////////////////////////////////////////*/

    /// @notice Version.
    uint8 public immutable override VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                            Addresses
    //////////////////////////////////////////////////////////////*/

    /// @notice Address that deploys and initializes clones.
    address public immutable override factory;

    /// @notice Address for Artiva's observability contract.
    address public immutable override o11y;

    /*//////////////////////////////////////////////////////////////
                            Signature Configuation
    //////////////////////////////////////////////////////////////*/

    /// @notice Domain seperator for typed data
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice Mapping of address to its signature nonce used for publishing with signature.
    mapping(address => uint256) addressToSignatureNonce;

    /// @notice Typed data struct for publishing authorization
    bytes32 public immutable PUBLISH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "PublishAuthorization(string message,address publishingKey,uint256 nonce)"
        );

    /*//////////////////////////////////////////////////////////////
                            Platform State
    //////////////////////////////////////////////////////////////*/

    /// @notice Hash of the platform metadata
    bytes32 public platformMetadataHash;

    /// @notice Mapping of bundle id to its bundle data.
    mapping(uint256 => BundleData) bundleIdToBundleData;

    /// @notice Private bundle id for indexing content bundles
    uint256 private _currentBundleId = 0;

    /*//////////////////////////////////////////////////////////////
                            Platform Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice Content publisher role hash for AccessControl
    bytes32 public immutable override CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    /// @notice Metadata manager role hash for AccessControl
    bytes32 public immutable override METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if member is in role.
    modifier onlyRoleMember(bytes32 role, address member) {
        require(hasRole(role, member), "UNAUTHORIZED_ACCOUNT");
        _;
    }

    /// @notice Checks if publishing signature is valid.
    modifier onlyValidSignature(address signer, bytes calldata signature) {
        require(
            SignatureChecker.isValidSignatureNow(
                signer,
                getSigningMessage(signer),
                signature
            ),
            "UNATHORIZED_SIGNATURE"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _factory, address _o11y) {
        // Assert not the zero-address.
        require(_factory != address(0), "MUST_SET_FACTORY");

        // Store factory.
        factory = _factory;

        // Assert not the zero-address.
        require(_o11y != address(0), "MUST_SET_OBSERVABILITY");

        // Store observability.
        o11y = _o11y;
    }

    /*//////////////////////////////////////////////////////////////
                            View Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns admin role for use in composing contracts.
    function getDefaultAdminRole() external pure returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /// @notice Get typed data message for clients to execute functions with publishing keys.
    function getSigningMessage(address signer) public view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PUBLISH_AUTHORIZATION_TYPEHASH,
                        keccak256(
                            bytes(
                                "I authorize publishing on artiva from this device"
                            )
                        ),
                        _msgSender(),
                        addressToSignatureNonce[signer]
                    )
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                            Initilization
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets default platform data must be called by factory contract.
    function initialize(
        address owner,
        address forwarder,
        PlatformData memory platform
    ) external {
        require(_msgSender() == factory, "NOT_FACTORY");

        /// > [[[[[[[[[[[ Roles ]]]]]]]]]]]

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        IObservability(o11y).emitRoleSet(owner, DEFAULT_ADMIN_ROLE, true);

        for (uint256 i; i < platform.publishers.length; i++) {
            _setupRole(CONTENT_PUBLISHER_ROLE, platform.publishers[i]);
            IObservability(o11y).emitRoleSet(
                platform.publishers[i],
                CONTENT_PUBLISHER_ROLE,
                true
            );
        }

        for (uint256 i; i < platform.metadataManagers.length; i++) {
            _setupRole(METADATA_MANAGER_ROLE, platform.metadataManagers[i]);
            IObservability(o11y).emitRoleSet(
                platform.metadataManagers[i],
                METADATA_MANAGER_ROLE,
                true
            );
        }

        /// > [[[[[[[[[[[ Platform metadata ]]]]]]]]]]]

        platformMetadataHash = keccak256(
            abi.encode(platform.platformMetadataJSON)
        );
        IObservability(o11y).emitPlatformMetadataSet(
            platform.platformMetadataJSON
        );

        /// > [[[[[[[[[[[ GSN ]]]]]]]]]]]

        require(forwarder != address(0), "MUST_SET_FORWARDER");
        _setTrustedForwarder(forwarder);

        /// > [[[[[[[[[[[ Typed data ]]]]]]]]]]]

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                            Content Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a content bundle to the platform.
    function addContent(string calldata bundleJSON, address owner)
        public
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, _msgSender())
    {
        uint256 bundleId = _addContent(bundleJSON, owner);
        IObservability(o11y).emitContentSet(bundleId, bundleJSON, owner);
    }

    /// @notice Sets content at a specific bundle ID. Useful for deleting of updating content bundles.
    function setContent(uint256 bundleId, string calldata bundleJSON)
        public
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, _msgSender())
    {
        address owner = bundleIdToBundleData[bundleId].owner;
        require(owner != address(0), "NO_OWNER");
        require(owner == _msgSender(), "SENDER_NOT_OWNER");

        _setContent(bundleId, bundleJSON);
        IObservability(o11y).emitContentSet(bundleId, bundleJSON, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            Metadata Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the metadata for the platform.
    function setPlatformMetadata(string calldata _platformMetadataJSON)
        external
        onlyRoleMember(METADATA_MANAGER_ROLE, _msgSender())
    {
        platformMetadataHash = keccak256(abi.encode(_platformMetadataJSON));
        IObservability(o11y).emitPlatformMetadataSet(_platformMetadataJSON);
    }

    /*//////////////////////////////////////////////////////////////
                            Role Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets many AccessControl roles. Useful for clients that want to batch role updates.
    function setManyRoles(RoleRequest[] calldata requests) public {
        for (uint256 i = 0; i < requests.length; i++) {
            RoleRequest memory request = requests[i];
            if (request.grant) grantRole(request.role, request.account);
            else revokeRole(request.role, request.account);

            IObservability(o11y).emitRoleSet(
                request.account,
                request.role,
                request.grant
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Signature Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the signature nonce, can be used if a user wants to invalidate their publishing signature.
    function setSignatureNonce(uint256 nonce) external {
        addressToSignatureNonce[_msgSender()] = nonce;
    }

    /// @notice Adds content to the platform with support for publishing signatures.
    function addContentWithSig(
        string calldata bundleJSON,
        address owner,
        address signer,
        bytes calldata signature
    )
        external
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, signer)
        onlyValidSignature(signer, signature)
    {
        uint256 bundleId = _addContent(bundleJSON, owner);
        IObservability(o11y).emitContentSet(bundleId, bundleJSON, owner);
    }

    /// @notice Sets content with support for publishing signatures.
    function setContentWithSig(
        uint256 bundleId,
        string calldata bundleJSON,
        address signer,
        bytes calldata signature
    )
        external
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, signer)
        onlyValidSignature(signer, signature)
    {
        address owner = bundleIdToBundleData[bundleId].owner;
        require(owner != address(0), "NO_OWNER");
        require(owner == signer, "SENDER_NOT_OWNER");

        _setContent(bundleId, bundleJSON);
        IObservability(o11y).emitContentSet(bundleId, bundleJSON, owner);
    }

    /// @notice Set the metadata for the platform with support for publishing signatures.
    function setPlatformMetadataWithSig(
        string calldata _platformMetadataJSON,
        address signer,
        bytes calldata signature
    )
        external
        onlyRoleMember(METADATA_MANAGER_ROLE, signer)
        onlyValidSignature(signer, signature)
    {
        platformMetadataHash = keccak256(abi.encode(_platformMetadataJSON));
        IObservability(o11y).emitPlatformMetadataSet(_platformMetadataJSON);
    }

    /// @notice Sets many AccessControl with support for publishing signatures.
    function setManyRolesWithSig(
        RoleRequest[] calldata requests,
        address signer,
        bytes calldata signature
    ) public onlyValidSignature(signer, signature) {
        for (uint256 i = 0; i < requests.length; i++) {
            RoleRequest memory request = requests[i];

            require(
                hasRole(getRoleAdmin(request.role), signer),
                "UNAUTHORIZED_ACCOUNT"
            );

            if (request.grant) _grantRole(request.role, request.account);
            else _revokeRole(request.role, request.account);

            IObservability(o11y).emitRoleSet(
                request.account,
                request.role,
                request.grant
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates the current content ID then sets content for the content data mapping.
    function _addContent(string calldata bundleJSON, address owner)
        internal
        returns (uint256 bundleId)
    {
        bundleIdToBundleData[_currentBundleId] = BundleData({
            contentHash: keccak256(abi.encode(bundleJSON)),
            owner: owner
        });
        unchecked {
            return _currentBundleId++;
        }
    }

    /// @notice Updates the content at a given content ID.
    function _setContent(uint256 bundleId, string calldata bundleJSON)
        internal
    {
        bundleIdToBundleData[bundleId].contentHash = keccak256(
            abi.encode(bundleJSON)
        );
    }

    /*//////////////////////////////////////////////////////////////
                            Ovverides
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Grants `role` to `account`. Overridden to support observability.
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IPlatform)
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, true);
    }

    /**
     * @dev Revokes `role` from `account`. Overridden to support observability.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IPlatform)
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, false);
    }

    /**
     * @dev Revokes `role` from the calling account. Overridden to support observability.
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl)
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, false);
    }

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @dev Overridden due to conflict with AccessControl _msgSender.
     * @return ret The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender()
        internal
        view
        override(AccessControl, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }
}

contract Observability is IObservability, IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory functions ]]]]]]]]]]]

    function emitDeploymentEvent(address owner, address clone)
        external
        override
    {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external override {
        emit FactoryImplementationSet(
            msg.sender,
            oldImplementation,
            newImplementation
        );
    }

    /// > [[[[[[[[[[[ Clone functions ]]]]]]]]]]]

    function emitContentSet(
        uint256 bundleId,
        string calldata bundleJSON,
        address owner
    ) external override {
        emit ContentSet(msg.sender, bundleId, bundleJSON, owner);
    }

    function emitPlatformMetadataSet(string calldata metadataJSON)
        external
        override
    {
        emit PlatformMetadataSet(msg.sender, metadataJSON);
    }

    function emitRoleSet(
        address account,
        bytes32 role,
        bool granted
    ) external override {
        emit RoleSet(msg.sender, account, role, granted);
    }
}

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

interface IOwnable {
    function transferOwnership(address nextOwner_) external;

    function cancelOwnershipTransfer() external;

    function acceptOwnership() external;

    function renounceOwnership() external;

    function isOwner() external view returns (bool);

    function isNextOwner() external view returns (bool);
}

abstract contract Ownable is IOwnable, IOwnableEvents {
    address public owner;
    address private nextOwner;

    /// > [[[[[[[[[[[ Modifiers ]]]]]]]]]]]

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /// @notice Initialize contract by setting the initial owner.
    constructor(address owner_) {
        _setInitialOwner(owner_);
    }

    /// @notice Initiate ownership transfer by setting nextOwner.
    function transferOwnership(address nextOwner_) external override onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /// @notice Cancel ownership transfer by deleting nextOwner.
    function cancelOwnershipTransfer() external override onlyOwner {
        delete nextOwner;
    }

    /// @notice Accepts ownership transfer by setting owner.
    function acceptOwnership() external override onlyNextOwner {
        delete nextOwner;

        owner = _msgSender();

        emit OwnershipTransferred(owner, _msgSender());
    }

    /// @notice Renounce ownership by setting owner to zero address.
    function renounceOwnership() external override onlyOwner {
        _renounceOwnership();
    }

    /// @notice Returns true if the caller is the current owner.
    function isOwner() public view override returns (bool) {
        return _msgSender() == owner;
    }

    /// @notice Returns true if the caller is the next owner.
    function isNextOwner() public view override returns (bool) {
        return _msgSender() == nextOwner;
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _setInitialOwner(address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function _renounceOwnership() internal {
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }

    function _msgSender() internal view virtual returns (address ret);
}

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

contract PlatformFactory is Ownable, ReentrancyGuard, ERC2771Recipient {
    /*//////////////////////////////////////////////////////////////
                            Version
    //////////////////////////////////////////////////////////////*/

    /// @notice Version.
    uint8 public immutable VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                            Deployments
    //////////////////////////////////////////////////////////////*/

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    /// @notice platform implementation.
    address public implementation;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys observability and implementation contracts, sets fowarder for GSN.
    constructor(address _owner, address forwarder) Ownable(_owner) {
        // Deploy and store Observability contract.
        o11y = address(new Observability());

        // Deploy and store implementation contract.
        implementation = address(new Platform(address(this), o11y));

        //Set the forwarder address for GSN
        _setTrustedForwarder(forwarder);
    }

    /*//////////////////////////////////////////////////////////////
                            View Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Generates the address that a clone will be deployed to.
    /// @param _implementation the WritingEditions address.
    /// @param salt the entropy used by create2 for generatating a deterministic address.
    function predictDeterministicAddress(address _implementation, bytes32 salt)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                _implementation,
                salt,
                address(this)
            );
    }

    function getSalt(address owner, Platform.PlatformData memory platform)
        external
        pure
        returns (bytes32)
    {
        return _getSalt(owner, platform);
    }

    /*//////////////////////////////////////////////////////////////
                            Implementation
    //////////////////////////////////////////////////////////////*/

    function setImplementation(address _implementation) external onlyOwner {
        // slither-disable-next-line reentrancy-no-eth
        IObservability(o11y).emitFactoryImplementationSet(
            // oldImplementation
            implementation,
            // newImplementation
            _implementation
        );

        // Store implementation.
        implementation = _implementation;
    }

    /*//////////////////////////////////////////////////////////////
                            Deployment functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a new platform clone with the sender as the owner.
    function create(
        string calldata platformMetadataJSON,
        address[] calldata publishers,
        address[] calldata metadataManagers,
        uint256 nonce
    ) external returns (address clone) {
        clone = _deployCloneAndInitialize(
            _msgSender(),
            IPlatform.PlatformData({
                platformMetadataJSON: platformMetadataJSON,
                publishers: publishers,
                metadataManagers: metadataManagers,
                nonce: nonce
            })
        );
    }

    function _getSalt(address owner, Platform.PlatformData memory platform)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    owner,
                    platform.platformMetadataJSON,
                    platform.publishers,
                    platform.metadataManagers,
                    platform.nonce
                )
            );
    }

    /// @dev Deploys a clone and calls the initialize function
    function _deployCloneAndInitialize(
        address owner,
        Platform.PlatformData memory platform
    ) internal returns (address clone) {
        clone = Clones.cloneDeterministic(
            implementation,
            keccak256(
                abi.encode(
                    owner,
                    platform.platformMetadataJSON,
                    platform.publishers,
                    platform.metadataManagers,
                    platform.nonce
                )
            )
        );

        IObservability(o11y).emitDeploymentEvent(owner, clone);

        // Initialize clone.
        Platform(clone).initialize(owner, getTrustedForwarder(), platform);
    }

    /*//////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return ret The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender()
        internal
        view
        override(Ownable, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }
}