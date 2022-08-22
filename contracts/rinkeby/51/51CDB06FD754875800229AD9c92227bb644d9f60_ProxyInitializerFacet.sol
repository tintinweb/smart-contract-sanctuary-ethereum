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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibRoles} from "../../libraries/LibRoles.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @author Amit Molek
/// @dev Role-based access control.
/// Based on OpenZeppelin's `AccessControl` (adapted to ERC-2535)
contract RolesFacet is IAccessControl {
    /// @dev Modifier that checks that the caller has `role`.
    modifier onlyRole(bytes32 role) {
        LibRoles._roleGuard(role);
        _;
    }

    /// @return Returns `true` if `account` has been granted `role`
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return LibRoles._hasRole(role, account);
    }

    /// @return Returns the admin role of `role`
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return LibRoles._getRoleAdmin(role);
    }

    /// @dev Grants `role` to `account`
    /// If `account` had not been already granted `role`, emits a {RoleGranted} event.
    /// Caller must have `role`'s admin role
    function grantRole(bytes32 role, address account)
        external
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        LibRoles._grantRole(role, account);
    }

    /// @dev Revokes `role` from `account`
    /// If `account` had been granted `role`, emits a {RoleRevoked} event.
    /// Caller must have `role`'s admin role
    function revokeRole(bytes32 role, address account)
        external
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        LibRoles._revokeRole(role, account);
    }

    /// @dev Revokes `role` from the caller
    /// The caller must be `account`
    function renounceRole(bytes32 role, address account)
        external
        virtual
        override
    {
        require(
            msg.sender == account,
            "RolesFacet: caller can only renounce for itself"
        );

        LibRoles._revokeRole(role, account);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibRoles} from "../access/RolesFacet.sol";
import {LibMemberRole} from "../../libraries/LibMemberRole.sol";
import {IProxyInitializer} from "../../interfaces/IProxyInitializer.sol";
import {LibProxyInitializer} from "../../libraries/LibProxyInitializer.sol";
import {StorageQuorumGovernance} from "../../storage/StorageQuorumGovernance.sol";
import {StorageState} from "../../storage/StorageState.sol";
import {StorageOwnershipUnits} from "../../storage/StorageOwnershipUnits.sol";
import {LibEIP712} from "../../libraries/LibEIP712.sol";

/// @author Amit Molek
/// @dev Initializes the DominiumProxy storage.
contract ProxyInitializerFacet is IProxyInitializer {
    struct InitData {
        uint8 quorumPercentage;
        uint8 passRatePercentage;
        /// @dev Total ownership units. Must be the price of the target nft in wei
        uint256 totalOwnershipUnits;
        /// @dev Smallest ownership unit. Must be in wei
        uint256 smallestOwnershipUnit;
    }

    modifier initializer() {
        LibProxyInitializer.DiamondStorage storage ds = LibProxyInitializer
            .diamondStorage();
        require(!ds.initialized, "ProxyInitializerFacet: Initialized");
        ds.initialized = true;
        _;
    }

    function proxyInit(bytes memory data) external override initializer {
        InitData memory initData = _decode(data);

        // EIP712's domain seperator
        LibEIP712._initDomainSeperator();

        // State
        StorageState._initStorage();

        // Governance
        StorageQuorumGovernance._initStorage(
            initData.quorumPercentage,
            initData.passRatePercentage
        );

        // Ownership
        StorageOwnershipUnits._initStorage(
            initData.smallestOwnershipUnit,
            initData.totalOwnershipUnits
        );
    }

    function initialized() external view override returns (bool) {
        LibProxyInitializer.DiamondStorage storage ds = LibProxyInitializer
            .diamondStorage();
        return ds.initialized;
    }

    function encode(InitData memory initData)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(initData);
    }

    function _decode(bytes memory data)
        internal
        pure
        returns (InitData memory)
    {
        return abi.decode(data, (InitData));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Proxy initialization
interface IProxyInitializer {
    function proxyInit(bytes memory data) external;

    function initialized() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Multisig wallet interface
/// @author Amit Molek
interface IWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposition {
        /// @dev Proposition's deadline
        uint256 endsAt;
        /// @dev Proposed transaction to execute
        Transaction tx;
        /// @dev can be useful if your `transaction` needs an accompanying hash.
        /// For example in EIP1271 `isValidSignature` function.
        /// Note: Pass zero hash (0x0) if you don't need this.
        bytes32 relevantHash;
    }

    /// @dev Emitted on proposition execution
    /// @param hash the transaction's hash
    /// @param value the value passed with `transaction`
    /// @param successful is the transaction were successfully executed
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    /// @dev Emitted on approved hash
    /// @param hash the approved hash
    event ApprovedHash(bytes32 hash);

    /// @return true if the hash has been approved
    function isHashApproved(bytes32 hash) external view returns (bool);

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IWallet} from "../interfaces/IWallet.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712 {
    bytes32 internal constant _DOMAIN_NAME = keccak256("Antic");
    bytes32 internal constant _DOMAIN_VERSION = keccak256("1");
    bytes32 internal constant _SALT = keccak256("Magrathea");

    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibEIP712");

    struct DiamondStorage {
        bytes32 domainSeparator;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @dev Initializes the EIP712's domain seperator
    /// note Must be called at least once, because it saves the
    /// domain seperator in storage
    function _initDomainSeperator() internal {
        DiamondStorage storage ds = diamondStorage();
        ds.domainSeparator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                _chainId(),
                _verifyingContract(),
                _salt()
            )
        );
    }

    function _toTypedDataHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeperator(), messageHash);
    }

    function _domainSeperator() internal view returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        return ds.domainSeparator;
    }

    function _chainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _verifyingContract() internal view returns (address) {
        return address(this);
    }

    function _salt() internal pure returns (bytes32) {
        return _SALT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Holds the unique id of the member role
library LibMemberRole {
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Storage for the ProxyInitializerFacet
library LibProxyInitializer {
    struct DiamondStorage {
        bool initialized;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibProxyInitializer");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @author Amit Molek
/// @dev Implements Diamond Storage for access control logic
/// Based on OpenZeppelin's Access Control
library LibRoles {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct DiamondStorage {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibRoles");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    /// @return Returns `true` if `account` has been granted `role`
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        DiamondStorage storage ds = diamondStorage();
        return ds.roles[role].members[account];
    }

    /// @return Returns the admin role of `role`
    function _getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        return ds.roles[role].adminRole;
    }

    /// @dev Reverts if the caller was not granted with `role`
    function _roleGuard(bytes32 role) internal view {
        LibRoles._roleGuard(role, msg.sender);
    }

    /// @dev Reverts if `account` was not granted with `role`
    function _roleGuard(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
            bytes memory err = abi.encodePacked(
                "RolesFacet: ",
                account,
                " lacks role: ",
                role
            );
            revert(string(err));
        }
    }

    /// @dev Use this to change the `role`'s admin role
    /// @param role the role you want to change the admin role
    /// @param adminRole the new admin role you want `role` to have
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        bytes32 oldAdminRole = _getRoleAdmin(role);
        ds.roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, oldAdminRole, adminRole);
    }

    /// @dev Use to grant `role` to `account`
    /// No access restriction
    function _grantRole(bytes32 role, address account) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        // Early exist if the account already has role
        if (_hasRole(role, account)) {
            return;
        }

        ds.roles[role].members[account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Use to revoke `role` to `account`
    /// No access restriction
    function _revokeRole(bytes32 role, address account) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        if (!_hasRole(role, account)) {
            return;
        }

        ds.roles[role].members[account] = false;

        emit RoleRevoked(role, account, msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for ownership units of members
library StorageOwnershipUnits {
    struct DiamondStorage {
        /// @dev Smallest ownership unit
        uint256 smallestOwnershipUnit;
        /// @dev Total ownership units
        uint256 totalOwnershipUnits;
        /// @dev Amount of ownership units that are owned by members.
        /// join -> adding | leave -> subtracting
        /// This is used in the join process to know when the group is fully funded
        uint256 totalOwnedOwnershipUnits;
        /// @dev Maps between member and their ownership units
        mapping(address => uint256) ownershipUnits;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.OwnershipUnits");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(
        uint256 smallestOwnershipUnit,
        uint256 totalOwnershipUnits
    ) internal {
        require(
            smallestOwnershipUnit > 0,
            "Storage: smallest ownership unit must be bigger than 0"
        );
        require(
            totalOwnershipUnits % smallestOwnershipUnit == 0,
            "Storage: total units not divisible by smallest unit"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.smallestOwnershipUnit = smallestOwnershipUnit;
        ds.totalOwnershipUnits = totalOwnershipUnits;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for quorum governance
library StorageQuorumGovernance {
    struct DiamondStorage {
        /// @dev The minimum level of participation required for a vote to be valid.
        /// in percentages out of 100 (e.g. 40)
        uint8 quorumPercentage;
        /// @dev What percentage of the votes cast need to be in favor in order
        /// for the proposal to be accepted.
        /// in percentages out of 100 (e.g. 40)
        uint8 passRatePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.QuorumGovernance");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(uint8 quorumPercentage, uint8 passRatePercentage)
        internal
    {
        require(
            quorumPercentage > 0 && quorumPercentage <= 100,
            "Storage: quorum percentage must be in range (0,100]"
        );
        require(
            passRatePercentage > 0 && passRatePercentage <= 100,
            "Storage: pass rate percentage must be in range (0,100]"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.quorumPercentage = quorumPercentage;
        ds.passRatePercentage = passRatePercentage;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for group state
library StorageState {
    struct DiamondStorage {
        /// @dev State of the group
        StateEnum state;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.State");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage() internal {
        DiamondStorage storage ds = diamondStorage();
        ds.state = StateEnum.OPEN;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    OPEN,
    FORMED
}