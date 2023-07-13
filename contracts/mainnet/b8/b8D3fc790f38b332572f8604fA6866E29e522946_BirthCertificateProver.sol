/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./StateVerifier.sol";
import "./Prover.sol";
import "../lib/FactSigs.sol";

/**
 * @title BirthCertificateProver
 * @author Theori, Inc.
 * @notice BirthCertificateProver proves that an account existed in a given block
 *         and stores the oldest known account proof in the fact database
 */
contract BirthCertificateProver is Prover, StateVerifier {
    FactSignature public immutable BIRTH_CERTIFICATE_SIG;
    RelicToken immutable token;

    struct AccountProof {
        address account;
        bytes accountProof;
        bytes header;
        bytes blockProof;
    }

    constructor(
        BlockHistory blockHistory,
        IReliquary _reliquary,
        RelicToken _token
    ) Prover(_reliquary) StateVerifier(blockHistory, _reliquary) {
        BIRTH_CERTIFICATE_SIG = FactSigs.birthCertificateFactSig();
        token = _token;
    }

    function parseAccountProof(bytes calldata proof)
        internal
        pure
        returns (AccountProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that an account existed in the given block
     *
     * @param encodedProof the encoded AccountProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        AccountProof calldata proof = parseAccountProof(encodedProof);
        (bool exists, CoreTypes.BlockHeaderData memory head, ) = verifyAccountAtBlock(
            proof.account,
            proof.accountProof,
            proof.header,
            proof.blockProof
        );
        require(exists, "Account does not exist at block");

        (bool proven, , bytes memory data) = reliquary.getFact(
            proof.account,
            BIRTH_CERTIFICATE_SIG
        );

        if (proven) {
            uint48 blockNum = uint48(bytes6(data));
            require(blockNum >= head.Number, "older block already proven");
        }

        data = abi.encodePacked(uint48(head.Number), uint64(head.Time));
        return Fact(proof.account, BIRTH_CERTIFICATE_SIG, data);
    }

    /**
     * @notice handles minting the token after a fact is stored
     *
     * @param fact the fact which was stored
     */
    function _afterStore(Fact memory fact, bool alreadyStored) internal override {
        if (!alreadyStored) {
            token.mint(fact.account, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./lib/CoreTypes.sol";
import "./lib/MerkleTree.sol";
import "./lib/AuxMerkleTree.sol";
import "./interfaces/IBlockHistory.sol";
import "./interfaces/IRecursiveVerifier.sol";

import {
    RecursiveProof,
    SignedRecursiveProof,
    getProofSigner,
    readHashWords
} from "./lib/Proofs.sol";

/**
 * @title BlockHistory
 * @author Theori, Inc.
 * @notice BlockHistory allows trustless and cheap verification of any
 *         historical block hash. Historical blocks are divided into chunks of
 *         fixed size, and each chunk's merkle root is stored on-chain. The
 *         merkle roots are validated on chain using aggregated SNARK proofs,
 *         enabling both trustlessness and scalability.
 *
 * @dev Each SNARK proof validates some contiguous block headers and has
 *      public inputs (parentHash, lastHash, merkleRoot). Here the merkleRoot
 *      is the merkleRoot of all block hashes contained in the proof, which may
 *      commit to many merkle roots which to commit on chain. If the last block
 *      is recent enough (<= 256 blocks old), the lastHash can be confirmed in
 *      the EVM, verifying that all blocks of the proof belong to this chain.
 *      Due to this, the historical blocks' merkle roots are imported in reverse
 *      order.
 */
contract BlockHistory is AccessControl, IBlockHistory {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant QUERY_ROLE = keccak256("QUERY_ROLE");

    // depth of the merkle trees whose roots we store in storage
    uint256 private constant MERKLE_TREE_DEPTH = 13;
    uint256 private constant BLOCKS_PER_CHUNK = 1 << MERKLE_TREE_DEPTH;

    /// @dev address of the reliquary, immutable
    address public immutable reliquary;

    /// @dev the expected signer of the SNARK proofs - if 0, then no signatures
    address public signer;

    /// @dev maps numBlocks => SNARK verifier (with VK embedded), only assigned
    ///      to in the constructor
    mapping(uint256 => IRecursiveVerifier) public verifiers;

    /// @dev parent hash of oldest block in current merkle trees
    ///      (0 once backlog fully imported)
    bytes32 public parentHash;

    /// @dev the earliest merkle root that has been imported
    uint256 public earliestRoot;

    /// @dev hash of most recent block in merkle trees
    bytes32 public lastHash;

    /// @dev merkle roots of block chunks between parentHash and lastHash
    mapping(uint256 => bytes32) private merkleRoots;

    /// @dev ZK-Friendly merkle roots, used by auxiliary SNARKs
    mapping(uint256 => bytes32) private auxiliaryRoots;

    /// @dev whether auth checks should run on aux root queries
    bool private needsAuth;

    event ImportMerkleRoot(uint256 indexed index, bytes32 merkleRoot, bytes32 auxiliaryRoot);
    event NewSigner(address newSigner);

    enum ProofType {
        Merkle,
        SNARK
    }

    /// @dev A SNARK + Merkle proof used to prove validity of a block
    struct MerkleSNARKProof {
        uint256 numBlocks;
        uint256 endBlock;
        SignedRecursiveProof snark;
        bytes32[] merkleProof;
    }

    struct ProofInputs {
        bytes32 parent;
        bytes32 last;
        bytes32 merkleRoot;
        bytes32 auxiliaryRoot;
    }

    constructor(
        uint256[] memory sizes,
        IRecursiveVerifier[] memory _verifiers,
        address _reliquary
    ) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(QUERY_ROLE, msg.sender);

        reliquary = _reliquary;
        signer = msg.sender;

        require(sizes.length == _verifiers.length);
        for (uint256 i = 0; i < sizes.length; i++) {
            require(address(verifiers[sizes[i]]) == address(0));
            verifiers[sizes[i]] = _verifiers[i];
        }
    }

    /**
     * @notice Checks if a SNARK is valid and signed as expected.
     *         Signatures checks are disabled if stored signer == address(0)
     *         Properties proven by the SNARK:
     *         - (parent ... last) form a valid block chain of length numBlocks
     *         - root is the merkle root of all contained blocks
     *
     * @param proof the aggregated proof
     * @param numBlocks the number of blocks contained in the proof
     * @return the validity
     */
    function validSNARK(SignedRecursiveProof calldata proof, uint256 numBlocks)
        internal
        view
        returns (bool)
    {
        address expected = signer;
        if (expected != address(0) && getProofSigner(proof) != expected) {
            return false;
        }
        IRecursiveVerifier verifier = verifiers[numBlocks];
        require(address(verifier) != address(0), "invalid numBlocks");
        return verifier.verify(proof.inner);
    }

    /**
     * @notice Asserts that the provided SNARK proof is valid and contains
     *         the provied merkle roots.
     *
     * @param proof the aggregated proof
     * @param roots the block merkle roots
     * @param aux the auxiliary merkle roots
     * @return inputs the proof inputs
     */
    function assertValidSNARKWithRoots(
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots,
        bytes32[] calldata aux
    ) internal view returns (ProofInputs memory inputs) {
        require(roots.length & (roots.length - 1) == 0, "roots length must be a power of 2");
        require(roots.length == aux.length, "roots arrays must be same length");

        // extract the inputs from the proof
        inputs = parseProofInputs(proof);

        // ensure the merkle roots are valid
        require(inputs.merkleRoot == MerkleTree.computeRoot(roots), "invalid block roots");

        // ensure the auxiliary merkle roots are valid
        require(inputs.auxiliaryRoot == AuxMerkleTree.computeRoot(aux), "invalid aux roots");

        // assert the SNARK proof is valid
        require(validSNARK(proof, BLOCKS_PER_CHUNK * roots.length), "invalid SNARK");
    }

    /**
     * @notice Checks if the given block number/hash connects to the current
     *         block using a SNARK.
     *
     * @param num the block number to check
     * @param hash the block hash to check
     * @param encodedProof the encoded MerkleSNARKProof
     * @return the validity
     */
    function validBlockHashWithSNARK(
        bytes32 hash,
        uint256 num,
        bytes calldata encodedProof
    ) internal view returns (bool) {
        MerkleSNARKProof calldata proof = parseMerkleSNARKProof(encodedProof);

        ProofInputs memory inputs = parseProofInputs(proof.snark);

        // check that the proof ends with a current block
        if (!validCurrentBlock(inputs.last, proof.endBlock)) {
            return false;
        }

        if (!validSNARK(proof.snark, proof.numBlocks)) {
            return false;
        }

        // compute the first block number in the proof
        uint256 startBlock = proof.endBlock + 1 - proof.numBlocks;

        // check if the target block is the parent of the proven blocks
        if (num == startBlock - 1 && hash == inputs.parent) {
            // merkle proof not needed in this case
            return true;
        }

        // check if the target block is in the proven merkle root
        uint256 index = num - startBlock;
        return MerkleTree.validProof(inputs.merkleRoot, index, hash, proof.merkleProof);
    }

    /**
     * @notice Checks if the given block number + hash exists in a commited
     *         merkle tree.
     *
     * @param num the block number to check
     * @param hash the block hash to check
     * @param encodedProof the encoded merkle proof
     * @return the validity
     */
    function validBlockHashWithMerkle(
        bytes32 hash,
        uint256 num,
        bytes calldata encodedProof
    ) internal view returns (bool) {
        bytes32 merkleRoot = merkleRoots[num / BLOCKS_PER_CHUNK];
        if (merkleRoot == 0) {
            return false;
        }
        bytes32[] calldata proofHashes = parseMerkleProof(encodedProof);
        if (proofHashes.length != MERKLE_TREE_DEPTH) {
            return false;
        }
        return MerkleTree.validProof(merkleRoot, num % BLOCKS_PER_CHUNK, hash, proofHashes);
    }

    /**
     * @notice Checks if the block is a current block (defined as being
     *         accessible in the EVM, i.e. <= 256 blocks old) and that the hash
     *         is correct.
     *
     * @param hash the alleged block hash
     * @param num the block number
     * @return the validity
     */
    function validCurrentBlock(bytes32 hash, uint256 num) internal view returns (bool) {
        // the block hash must be accessible in the EVM and match
        return (block.number - num <= 256) && (blockhash(num) == hash);
    }

    /**
     * @notice Stores the merkle roots starting at the index
     *
     * @param index the index for the first merkle root
     * @param roots the merkle roots of the block hashes
     * @param aux the auxiliary merkle roots of the block hashes
     */
    function storeMerkleRoots(
        uint256 index,
        bytes32[] calldata roots,
        bytes32[] calldata aux
    ) internal {
        for (uint256 i = 0; i < roots.length; i++) {
            uint256 idx = index + i;
            merkleRoots[idx] = roots[i];
            auxiliaryRoots[idx] = aux[i];
            emit ImportMerkleRoot(idx, roots[i], aux[i]);
        }
    }

    /**
     * @notice Imports new chunks of blocks before the current parentHash
     *
     * @param proof the aggregated proof for these chunks
     * @param roots the merkle roots for the block hashes
     * @param aux the auxiliary roots for the block hashes
     */
    function importParent(
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots,
        bytes32[] calldata aux
    ) external {
        require(parentHash != 0 && earliestRoot != 0, "import not started or already completed");

        ProofInputs memory inputs = assertValidSNARKWithRoots(proof, roots, aux);

        // assert the last hash in the proof is our current parent hash
        require(parentHash == inputs.last, "proof doesn't connect with parentHash");

        // store the merkle roots
        uint256 index = earliestRoot - roots.length;
        storeMerkleRoots(index, roots, aux);

        // store the new parentHash and earliestRoot
        parentHash = inputs.parent;
        earliestRoot = index;
    }

    /**
     * @notice Imports new chunks of blocks after the current lastHash
     *
     * @param endBlock the last block number in the chunks
     * @param proof the aggregated proof for these chunks
     * @param roots the merkle roots for the block hashes
     * @param connectProof an optional SNARK proof connecting the proof to
     *                     a current block
     */
    function importLast(
        uint256 endBlock,
        SignedRecursiveProof calldata proof,
        bytes32[] calldata roots,
        bytes32[] calldata aux,
        bytes calldata connectProof
    ) external {
        require((endBlock + 1) % BLOCKS_PER_CHUNK == 0, "endBlock must end at a chunk boundary");

        ProofInputs memory inputs = assertValidSNARKWithRoots(proof, roots, aux);

        if (!validCurrentBlock(inputs.last, endBlock)) {
            // if the proof doesn't connect our lastHash with a current block,
            // then the connectProof must fill the gap
            require(
                validBlockHashWithSNARK(inputs.last, endBlock, connectProof),
                "connectProof invalid"
            );
        }

        uint256 index = (endBlock + 1) / BLOCKS_PER_CHUNK - roots.length;
        if (lastHash == 0) {
            // if we're importing for the first time, set parentHash and earliestRoot
            require(parentHash == 0);
            parentHash = inputs.parent;
            earliestRoot = index;
        } else {
            require(inputs.parent == lastHash, "proof doesn't connect with lastHash");
        }

        // store the new lastHash
        lastHash = inputs.last;

        // store the merkle roots
        storeMerkleRoots(index, roots, aux);
    }

    /**
     * @notice Checks if a block hash is valid. A proof is required unless the
     *         block is current (accesible in the EVM). If the target block has
     *         no commited merkle root, the proof must contain a SNARK proof.
     *
     * @param hash the hash to check
     * @param num the block number for the alleged hash
     * @param proof the merkle witness or SNARK proof (if needed)
     * @return the validity
     */
    function _validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) internal view returns (bool) {
        if (validCurrentBlock(hash, num)) {
            return true;
        }

        ProofType typ;
        (typ, proof) = parseProofType(proof);
        if (typ == ProofType.Merkle) {
            return validBlockHashWithMerkle(hash, num, proof);
        } else if (typ == ProofType.SNARK) {
            return validBlockHashWithSNARK(hash, num, proof);
        } else {
            revert("invalid proof type");
        }
    }

    /**
     * @notice Checks if a block hash is correct. A proof is required unless the
     *         block is current (accesible in the EVM). If the target block has
     *         no commited merkle root, the proof must contain a SNARK proof.
     *         Reverts if block hash or proof is invalid.
     *
     * @param hash the hash to check
     * @param num the block number for the alleged hash
     * @param proof the merkle witness or SNARK proof (if needed)
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool) {
        require(msg.sender == reliquary || hasRole(QUERY_ROLE, msg.sender));
        require(num < block.number);
        return _validBlockHash(hash, num, proof);
    }

    /**
     * @notice Queries an auxRoot
     *
     * @dev only authorized addresses can call this
     * @param idx the index of the root to query
     */
    function auxRoots(uint256 idx) external view returns (bytes32 root) {
        if (needsAuth) {
            _checkRole(QUERY_ROLE);
        }
        root = auxiliaryRoots[idx];
    }

    /**
     * @notice sets the needsAuth flag which controls auxRoot query auth checks
     *
     * @dev only the owner can call this
     * @param _needsAuth the new value
     */
    function setNeedsAuth(bool _needsAuth) external onlyRole(ADMIN_ROLE) {
        needsAuth = _needsAuth;
    }

    /**
     * @notice Parses a proof type and proof from the encoded proof
     *
     * @param proof the encoded proof
     * @return typ the proof type (SNARK or Merkle)
     * @return proof the remaining encoded proof
     */
    function parseProofType(bytes calldata encodedProof)
        internal
        pure
        returns (ProofType typ, bytes calldata proof)
    {
        require(encodedProof.length > 0, "cannot parse proof type");
        typ = ProofType(uint8(encodedProof[0]));
        proof = encodedProof[1:];
    }

    /**
     * @notice Parses a MerkleSNARKProof from calldata bytes
     *
     * @param proof the encoded proof
     * @return result a MerkleSNARKProof
     */
    function parseMerkleSNARKProof(bytes calldata proof)
        internal
        pure
        returns (MerkleSNARKProof calldata result)
    {
        // solidity doesn't support getting calldata outputs from abi.decode
        // but we can decode it; calldata structs are just offsets
        assembly {
            result := proof.offset
        }
    }

    /**
     * @notice Parses a merkle inclusion proof from the bytes
     *
     * @param proof the encoded merkle inclusion proof
     * @return result the array of proof hashes
     */
    function parseMerkleProof(bytes calldata proof)
        internal
        pure
        returns (bytes32[] calldata result)
    {
        require(proof.length % 32 == 0);
        require(proof.length >= 32);

        // solidity doesn't support getting calldata outputs from abi.decode
        // but we can decode it; calldata arrays are just (offset,length)
        assembly {
            result.offset := add(proof.offset, 0x20)
            result.length := calldataload(proof.offset)
        }
    }

    /**
     * @notice Parses the proof inputs for block history snark proofs
     *
     * @param proof the snark proof
     * @return result the parsed proof inputs
     */
    function parseProofInputs(SignedRecursiveProof calldata proof)
        internal
        pure
        returns (ProofInputs memory result)
    {
        uint256[] calldata inputs = proof.inner.inputs;
        require(inputs.length == 13);
        result = ProofInputs(
            readHashWords(inputs[0:4]),
            readHashWords(inputs[4:8]),
            readHashWords(inputs[8:12]),
            bytes32(inputs[12])
        );
    }

    /**
     * @notice sets the expected signer of the SNARK proofs, only callable by
     *         the contract owner
     *
     * @param _signer the new signer; if 0, disables signature checks
     */
    function setSigner(address _signer) external onlyRole(ADMIN_ROLE) {
        require(signer != _signer);
        signer = _signer;
        emit NewSigner(_signer);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IContractURI.sol";
import "./interfaces/IERC5192.sol";
import "./interfaces/ITokenURI.sol";

/**
 * @title RelicToken
 * @author Theori, Inc.
 * @notice RelicToken is the base contract for all Relic SBTs. It implements
 *         ERC721 (with transfers disables) and ERC5192.
 */
abstract contract RelicToken is Ownable, ERC165, IERC721, IERC721Metadata, IERC5192 {
    mapping(address => bool) public provers;

    /// @notice contract metadata URI provider
    IContractURI contractURIProvider;

    /**
     * @notice determind if the given owner is entitiled to a token with the specific data
     * @param owner the address in question
     * @param data the opaque data in question
     * @return the existence of the given data
     */
    function hasToken(address owner, uint96 data) internal view virtual returns (bool);

    /**
     * @notice updates the set of contracts trusted to create new tokens and
     *         possibly resolve entitlement questions
     * @param prover the address of the prover
     * @param valid whether the prover is trusted
     */
    function setProver(address prover, bool valid) external onlyOwner {
        provers[prover] = valid;
    }

    /**
     * @notice helper function to break a tokenId into its constituent data
     * @param tokenId the tokenId in question
     * @return who the address bound to this token
     * @return data any additional data bound to this token
     */
    function parseTokenId(uint256 tokenId) internal pure returns (address who, uint96 data) {
        who = address(bytes20(bytes32(tokenId << 96)));
        data = uint96(tokenId >> 160);
    }

    /**
     * @notice issue a new Relic
     * @param who the address to which this token should be bound
     * @param data any data to be associated with this token
     * @dev emits ERC-721 Transfer event and ERC-5192 Locked event. Note
     *      that storage is not generally updated by this function.
     */
    function mint(address who, uint96 data) public virtual {
        require(provers[msg.sender], "only a prover can mint");
        require(hasToken(who, data), "cannot mint for invalid token");

        uint256 id = uint256(uint160(who)) | (uint256(data) << 160);
        emit Transfer(address(0), who, id);
        emit Locked(id);
    }

    /* begin ERC-721 spec functions */
    /**
     * @inheritdoc IERC721
     * @dev If the token has not been issued (no transfer event) this function
     *      may still return an owner if there is an account entitled to this
     *      token.
     */
    function ownerOf(uint256 id) public view virtual returns (address who) {
        uint96 data;
        (who, data) = parseTokenId(id);
        if (!hasToken(who, data)) {
            who = address(0);
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Balance will always be 0 if the address is not entitled to any
     *      tokens, and 1 if they are entitled to a token. If multiple tokens
     *      are minted, this will still return 1.
     */
    function balanceOf(address who) external view override returns (uint256 balance) {
        require(who != address(0), "ERC721: address zero is not a valid owner");
        if (hasToken(who, 0)) {
            balance = 1;
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* _to */
        uint256, /* _tokenId */
        bytes calldata /* data */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* id */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function approve(
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function setApprovalForAll(
        address, /* operator */
        bool /* _approved */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns the null address: Relics are soul-bound/non-transferrable
     */
    function getApproved(
        uint256 /* tokenId */
    ) external pure returns (address operator) {
        operator = address(0);
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns false: Relics are soul-bound/non-transferrable
     */
    function isApprovedForAll(
        address, /* owner */
        address /* operator */
    ) external pure returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IERC721, IERC721Metadata, IERC5192
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function symbol() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenID) external view virtual returns (string memory);

    /* end ERC-721 spec functions */

    /* begin ERC-5192 spec functions */
    /**
     * @inheritdoc IERC5192
     * @dev All valid tokens are locked: Relics are soul-bound/non-transferrable
     */
    function locked(uint256 id) external view returns (bool) {
        return ownerOf(id) != address(0);
    }

    /* end ERC-5192 spec functions */

    /* begin OpenSea metadata functions */
    /**
     * @notice contract metadata URI as defined by OpenSea
     */
    function contractURI() external view returns (string memory) {
        return contractURIProvider.contractURI();
    }

    /**
     * @notice set contract-level metadata URI provider
     * @param provider new metadata URI provider
     */
    function setContractURIProvider(IContractURI provider) external onlyOwner {
        contractURIProvider = provider;
    }
    /* end OpenSea metadata functions */
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Block history provider
 * @author Theori, Inc.
 * @notice IBlockHistory provides a way to verify a blockhash
 */

interface IBlockHistory {
    /**
     * @notice Determine if the given hash corresponds to the given block
     * @param hash the hash if the block in question
     * @param num the number of the block in question
     * @param proof any witness data required to prove the block hash is
     *        correct (such as a Merkle or SNARK proof)
     * @return boolean indicating if the block hash can be verified correct
     */
    function validBlockHash(
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Contract Metadata URI provider
 * @author Theori, Inc.
 * @notice Outsourced contractURI provider for NFT/SBT tokens
 */
interface IContractURI {
    /**
     * @notice Get the contract metadata URI
     * @return the string of the URI
     */
    function contractURI() external view returns (string memory);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

/**
 * @title EIP-5192 specification
 * @author Theori, Inc.
 * @notice EIP-5192 events and functions
 */
interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.12;

/**
 * @title IProver
 * @author Theori, Inc.
 * @notice IProver is a standard interface implemented by some Relic provers.
 *         Supports proving a fact ephemerally or proving and storing it in the
 *         Reliquary.
 */
interface IProver {
    /**
     * @notice prove a fact ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return fact the proven fact information
     */
    function prove(bytes calldata proof, bool store) external payable returns (Fact memory fact);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import {RecursiveProof} from "../lib/Proofs.sol";

/**
 * @title Verifier of zk-SNARK proofs
 * @author Theori, Inc.
 * @notice Provider of validity checking of zk-SNARKs
 */
interface IRecursiveVerifier {
    /**
     * @notice Checks the validity of SNARK data
     * @param proof the proof to verify
     * @return the validity of the proof
     */
    function verify(RecursiveProof calldata proof) external view returns (bool);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../lib/Facts.sol";

interface IReliquary {
    event NewProver(address prover, uint64 version);
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);
    event ProverRevoked(address prover, uint64 version);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    function activateProver(address prover) external;

    function addCredits(address user, uint192 amount) external;

    function addProver(address prover, uint64 version) external;

    function addSubscriber(address user, uint64 ts) external;

    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    function checkProveFactFee(address sender) external payable;

    function checkProver(ProverInfo memory prover) external pure;

    function credits(address user) external view returns (uint192);

    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8)
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function getProveFactNativeFee(address prover) external view returns (uint256);

    function getProveFactTokenFee(address prover) external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function initialized() external view returns (bool);

    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address) external view returns (ProverInfo memory);

    function removeCredits(address user, uint192 amount) external;

    function removeSubscriber(address user) external;

    function renounceRole(bytes32 role, address account) external;

    function resetFact(address account, FactSignature factSig) external;

    function revokeProver(address prover) external;

    function revokeRole(bytes32 role, address account) external;

    function setCredits(address user, uint192 amount) external;

    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setInitialized() external;

    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    function verifyBlockFeeInfo()
        external
        view
        returns (
            uint8 flags,
            uint16 feeCredits,
            uint8 feeWeiMantissa,
            uint8 feeWeiExponent,
            uint32 feeExternalId
        );

    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    function versions(uint64) external view returns (address);

    function withdrawFees(address token, address dest) external;
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title NFT Token URI provider
 * @author Theori, Inc.
 * @notice Outsourced tokenURI provider for NFT/SBT tokens
 */
interface ITokenURI {
    /**
     * @notice Get the URI for the given token
     * @param tokenID the unique ID for the token
     * @return the string of the URI
     * @dev when called with an invalid tokenID, this may revert,
     *      or it may return invalid output
     */
    function tokenURI(uint256 tokenID) external view returns (string memory);
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title AnemoiJive
 * @author Theori, Inc.
 * @notice Implementation of the Anemoi hash function and Jive mode of operation
 */
library AnemoiJive {
    uint256 constant beta = 5;
    uint256 constant alpha_inv =
        17510594297471420177797124596205820070838691520332827474958563349260646796493;
    uint256 constant q =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant delta =
        8755297148735710088898562298102910035419345760166413737479281674630323398247;

    function CD(uint256 round) internal pure returns (uint256, uint256) {
        if (round == 0)
            return (
                37,
                8755297148735710088898562298102910035419345760166413737479281674630323398284
            );
        if (round == 1)
            return (
                13352247125433170118601974521234241686699252132838635793584252509352796067497,
                5240474505904316858775051800099222288270827863409873986701694203345984265770
            );
        if (round == 2)
            return (
                8959866518978803666083663798535154543742217570455117599799616562379347639707,
                9012679925958717565787111885188464538194947839997341443807348023221726055342
            );
        if (round == 3)
            return (
                3222831896788299315979047232033900743869692917288857580060845801753443388885,
                21855834035835287540286238525800162342051591799629360593177152465113152235615
            );
        if (round == 4)
            return (
                11437915391085696126542499325791687418764799800375359697173212755436799377493,
                11227229470941648605622822052481187204980748641142847464327016901091886692935
            );
        if (round == 5)
            return (
                14725846076402186085242174266911981167870784841637418717042290211288365715997,
                8277823808153992786803029269162651355418392229624501612473854822154276610437
            );
        if (round == 6)
            return (
                3625896738440557179745980526949999799504652863693655156640745358188128872126,
                20904607884889140694334069064199005451741168419308859136555043894134683701950
            );
        if (round == 7)
            return (
                463291105983501380924034618222275689104775247665779333141206049632645736639,
                1902748146936068574869616392736208205391158973416079524055965306829204527070
            );
        if (round == 8)
            return (
                17443852951621246980363565040958781632244400021738903729528591709655537559937,
                14452570815461138929654743535323908350592751448372202277464697056225242868484
            );
        if (round == 9)
            return (
                10761214205488034344706216213805155745482379858424137060372633423069634639664,
                10548134661912479705005015677785100436776982856523954428067830720054853946467
            );
        if (round == 10)
            return (
                1555059412520168878870894914371762771431462665764010129192912372490340449901,
                17068729307795998980462158858164249718900656779672000551618940554342475266265
            );
        if (round == 11)
            return (
                7985258549919592662769781896447490440621354347569971700598437766156081995625,
                16199718037005378969178070485166950928725365516399196926532630556982133691321
            );
        if (round == 12)
            return (
                9570976950823929161626934660575939683401710897903342799921775980893943353035,
                19148564379197615165212957504107910110246052442686857059768087896511716255278
            );
        if (round == 13)
            return (
                17962366505931708682321542383646032762931774796150042922562707170594807376009,
                5497141763311860520411283868772341077137612389285480008601414949457218086902
            );
        if (round == 14)
            return (
                12386136552538719544323156650508108618627836659179619225468319506857645902649,
                18379046272821041930426853913114663808750865563081998867954732461233335541378
            );
        if (round == 15)
            return (
                21184636178578575123799189548464293431630680704815247777768147599366857217074,
                7696001730141875853127759241422464241772355903155684178131833937483164915734
            );
        if (round == 16)
            return (
                3021529450787050964585040537124323203563336821758666690160233275817988779052,
                963844642109550260189938374814031216012862679737123536423540607519656220143
            );
        if (round == 17)
            return (
                7005374570978576078843482270548485551486006385990713926354381743200520456088,
                12412434690468911461310698766576920805270445399824272791985598210955534611003
            );
        if (round == 18)
            return (
                3870834761329466217812893622834770840278912371521351591476987639109753753261,
                6971318955459107915662273112161635903624047034354567202210253298398705502050
            );
        revert();
    }

    function expmod(
        uint256 base,
        uint256 e,
        uint256 m
    ) internal view returns (uint256 o) {
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            // data
            o := mload(p)
        }
    }

    function sbox(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        x = addmod(x, q - mulmod(beta, mulmod(y, y, q), q), q);
        y = addmod(y, q - expmod(x, alpha_inv, q), q);
        x = addmod(addmod(x, mulmod(beta, mulmod(y, y, q), q), q), delta, q);
        return (x, y);
    }

    function ll(uint256 x, uint256 y) internal pure returns (uint256 r0, uint256 r1) {
        r0 = addmod(x, mulmod(5, y, q), q);
        r1 = addmod(y, mulmod(5, r0, q), q);
    }

    function compress(uint256 x, uint256 y) internal view returns (uint256) {
        uint256 sum = addmod(x, y, q);
        uint256 c;
        uint256 d;
        for (uint256 r = 0; r < 19; r++) {
            (c, d) = CD(r);
            x = addmod(x, c, q);
            y = addmod(y, d, q);
            (x, y) = ll(x, y);
            (x, y) = sbox(x, y);
        }
        (x, y) = ll(x, y);
        return addmod(addmod(x, y, q), sum, q);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./AnemoiJive.sol";

/**
 * @title Auxiliary Merkle Tree
 * @author Theori, Inc.
 * @notice Gas optimized arithmetic-friendly merkle tree code.
 * @dev uses Anemoi / Jive 2-to-1
 */
library AuxMerkleTree {
    /**
     * @notice computes a jive merkle root of the provided hashes, in place
     * @param temp the mutable array of hashes
     * @return root the merkle root hash
     */
    function computeRoot(bytes32[] memory temp) internal view returns (bytes32 root) {
        uint256 count = temp.length;
        while (count > 1) {
            unchecked {
                for (uint256 i = 0; i < count / 2; i++) {
                    uint256 x;
                    uint256 y;
                    assembly {
                        let ptr := add(temp, add(0x20, mul(0x40, i)))
                        x := mload(ptr)
                        ptr := add(ptr, 0x20)
                        y := mload(ptr)
                    }
                    x = AnemoiJive.compress(x, y);
                    assembly {
                        mstore(add(temp, add(0x20, mul(0x20, i))), x)
                    }
                }
                count >>= 1;
            }
        }
        return temp[0];
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.13;

// custom bytes calldata pointer storing (length | offset) in one word,
// also allows calldata pointers to be stored in memory
type BytesCalldata is uint256;

using BytesCalldataOps for BytesCalldata global;

// can't introduce global using .. for non UDTs
// each consumer should add the following line:
using BytesCalldataOps for bytes;

/**
 * @author Theori, Inc
 * @title BytesCalldataOps
 * @notice Common operations for bytes calldata, implemented for both the builtin
 *         type and our BytesCalldata type. These operations are heavily optimized
 *         and omit safety checks, so this library should only be used when memory
 *         safety is not a security issue.
 */
library BytesCalldataOps {
    function length(BytesCalldata bc) internal pure returns (uint256 result) {
        assembly {
            result := shr(128, shl(128, bc))
        }
    }

    function offset(BytesCalldata bc) internal pure returns (uint256 result) {
        assembly {
            result := shr(128, bc)
        }
    }

    function convert(BytesCalldata bc) internal pure returns (bytes calldata value) {
        assembly {
            value.offset := shr(128, bc)
            value.length := shr(128, shl(128, bc))
        }
    }

    function convert(bytes calldata inp) internal pure returns (BytesCalldata bc) {
        assembly {
            bc := or(shl(128, inp.offset), inp.length)
        }
    }

    function slice(
        BytesCalldata bc,
        uint256 start,
        uint256 len
    ) internal pure returns (BytesCalldata result) {
        assembly {
            result := shl(128, add(shr(128, bc), start)) // add to the offset and clear the length
            result := or(result, len) // set the new length
        }
    }

    function slice(
        bytes calldata value,
        uint256 start,
        uint256 len
    ) internal pure returns (bytes calldata result) {
        assembly {
            result.offset := add(value.offset, start)
            result.length := len
        }
    }

    function prefix(BytesCalldata bc, uint256 len) internal pure returns (BytesCalldata result) {
        assembly {
            result := shl(128, shr(128, bc)) // clear out the length
            result := or(result, len) // set it to the new length
        }
    }

    function prefix(bytes calldata value, uint256 len)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := value.offset
            result.length := len
        }
    }

    function suffix(BytesCalldata bc, uint256 start) internal pure returns (BytesCalldata result) {
        assembly {
            result := add(bc, shl(128, start)) // add to the offset
            result := sub(result, start) // subtract from the length
        }
    }

    function suffix(bytes calldata value, uint256 start)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := add(value.offset, start)
            result.length := sub(value.length, start)
        }
    }

    function split(BytesCalldata bc, uint256 start)
        internal
        pure
        returns (BytesCalldata, BytesCalldata)
    {
        return (prefix(bc, start), suffix(bc, start));
    }

    function split(bytes calldata value, uint256 start)
        internal
        pure
        returns (bytes calldata, bytes calldata)
    {
        return (prefix(value, start), suffix(value, start));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./BytesCalldata.sol";
import "./RLP.sol";

/**
 * @title CoreTypes
 * @author Theori, Inc.
 * @notice Data types and parsing functions for core types, including block headers
 *         and account data.
 */
library CoreTypes {
    using BytesCalldataOps for bytes;
    struct BlockHeaderData {
        bytes32 ParentHash;
        address Coinbase;
        bytes32 Root;
        bytes32 TxHash;
        bytes32 ReceiptHash;
        uint256 Number;
        uint256 GasLimit;
        uint256 GasUsed;
        uint256 Time;
        bytes32 MixHash;
        uint256 BaseFee;
        bytes32 WithdrawalsHash;
    }

    struct AccountData {
        uint256 Nonce;
        uint256 Balance;
        bytes32 StorageRoot;
        bytes32 CodeHash;
    }

    struct LogData {
        address Address;
        bytes32[] Topics;
        bytes Data;
    }

    struct WithdrawalData {
        uint256 Index;
        uint256 ValidatorIndex;
        address Address;
        uint256 AmountInGwei;
    }

    function parseHash(bytes calldata buf) internal pure returns (bytes32 result, uint256 offset) {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = bytes32(value);
    }

    function parseAddress(bytes calldata buf)
        internal
        pure
        returns (address result, uint256 offset)
    {
        uint256 value;
        (value, offset) = RLP.parseUint(buf);
        result = address(uint160(value));
    }

    function parseBlockHeader(bytes calldata header)
        internal
        pure
        returns (BlockHeaderData memory data)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        header = header.slice(offset, listSize);

        (data.ParentHash, offset) = parseHash(header); // ParentHash
        header = header.suffix(offset);
        header = RLP.skip(header); // UncleHash
        (data.Coinbase, offset) = parseAddress(header); // Coinbase
        header = header.suffix(offset);
        (data.Root, offset) = parseHash(header); // Root
        header = header.suffix(offset);
        (data.TxHash, offset) = parseHash(header); // TxHash
        header = header.suffix(offset);
        (data.ReceiptHash, offset) = parseHash(header); // ReceiptHash
        header = header.suffix(offset);
        header = RLP.skip(header); // Bloom
        header = RLP.skip(header); // Difficulty
        (data.Number, offset) = RLP.parseUint(header); // Number
        header = header.suffix(offset);
        (data.GasLimit, offset) = RLP.parseUint(header); // GasLimit
        header = header.suffix(offset);
        (data.GasUsed, offset) = RLP.parseUint(header); // GasUsed
        header = header.suffix(offset);
        (data.Time, offset) = RLP.parseUint(header); // Time
        header = header.suffix(offset);
        header = RLP.skip(header); // Extra
        (data.MixHash, offset) = parseHash(header); // MixHash
        header = header.suffix(offset);
        header = RLP.skip(header); // Nonce

        if (header.length > 0) {
            (data.BaseFee, offset) = RLP.parseUint(header); // BaseFee
            header = header.suffix(offset);
        }

        if (header.length > 0) {
            (data.WithdrawalsHash, offset) = parseHash(header); // WithdrawalsHash
        }
    }

    function getBlockHeaderHashAndSize(bytes calldata header)
        internal
        pure
        returns (bytes32 blockHash, uint256 headerSize)
    {
        (uint256 listSize, uint256 offset) = RLP.parseList(header);
        unchecked {
            headerSize = offset + listSize;
        }
        blockHash = keccak256(header.prefix(headerSize));
    }

    function parseAccount(bytes calldata account) internal pure returns (AccountData memory data) {
        (, uint256 offset) = RLP.parseList(account);
        account = account.suffix(offset);

        (data.Nonce, offset) = RLP.parseUint(account); // Nonce
        account = account.suffix(offset);
        (data.Balance, offset) = RLP.parseUint(account); // Balance
        account = account.suffix(offset);
        (data.StorageRoot, offset) = parseHash(account); // StorageRoot
        account = account.suffix(offset);
        (data.CodeHash, offset) = parseHash(account); // CodeHash
        account = account.suffix(offset);
    }

    function parseLog(bytes calldata log) internal pure returns (LogData memory data) {
        (, uint256 offset) = RLP.parseList(log);
        log = log.suffix(offset);

        uint256 tmp;
        (tmp, offset) = RLP.parseUint(log); // Address
        data.Address = address(uint160(tmp));
        log = log.suffix(offset);

        (tmp, offset) = RLP.parseList(log); // Topics
        bytes calldata topics = log.slice(offset, tmp);
        log = log.suffix(offset + tmp);

        require(topics.length % 33 == 0);
        data.Topics = new bytes32[](tmp / 33);
        uint256 i = 0;
        while (topics.length > 0) {
            (data.Topics[i], offset) = parseHash(topics);
            topics = topics.suffix(offset);
            unchecked {
                i++;
            }
        }

        (data.Data, ) = RLP.splitBytes(log);
    }

    function extractLog(bytes calldata receiptValue, uint256 logIdx)
        internal
        pure
        returns (LogData memory)
    {
        // support EIP-2718: Currently all transaction types have the same
        // receipt RLP format, so we can just skip the receipt type byte
        if (receiptValue[0] < 0x80) {
            receiptValue = receiptValue.suffix(1);
        }

        (, uint256 offset) = RLP.parseList(receiptValue);
        receiptValue = receiptValue.suffix(offset);

        // pre EIP-658, receipts stored an intermediate state root in this field
        // post EIP-658, the field is a tx status (0 for failure, 1 for success)
        uint256 statusOrIntermediateRoot;
        (statusOrIntermediateRoot, offset) = RLP.parseUint(receiptValue);
        require(statusOrIntermediateRoot != 0, "tx did not succeed");
        receiptValue = receiptValue.suffix(offset);

        receiptValue = RLP.skip(receiptValue); // GasUsed
        receiptValue = RLP.skip(receiptValue); // LogsBloom

        uint256 length;
        (length, offset) = RLP.parseList(receiptValue); // Logs
        receiptValue = receiptValue.slice(offset, length);

        // skip the earlier logs
        for (uint256 i = 0; i < logIdx; i++) {
            require(receiptValue.length > 0, "log index does not exist");
            receiptValue = RLP.skip(receiptValue);
        }

        return parseLog(receiptValue);
    }

    function parseWithdrawal(bytes calldata withdrawal)
        internal
        pure
        returns (WithdrawalData memory data)
    {
        (, uint256 offset) = RLP.parseList(withdrawal);
        withdrawal = withdrawal.suffix(offset);

        (data.Index, offset) = RLP.parseUint(withdrawal); // Index
        withdrawal = withdrawal.suffix(offset);
        (data.ValidatorIndex, offset) = RLP.parseUint(withdrawal); // ValidatorIndex
        withdrawal = withdrawal.suffix(offset);
        (data.Address, offset) = parseAddress(withdrawal); // Address
        withdrawal = withdrawal.suffix(offset);
        (data.AmountInGwei, offset) = RLP.parseUint(withdrawal); // Amount
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "./Facts.sol";

/**
 * @title FactSigs
 * @author Theori, Inc.
 * @notice Helper functions for computing fact signatures
 */
library FactSigs {
    /**
     * @notice Produce the fact signature data for birth certificates
     */
    function birthCertificateFactSigData() internal pure returns (bytes memory) {
        return abi.encode("BirthCertificate");
    }

    /**
     * @notice Produce the fact signature for a birth certificate fact
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, birthCertificateFactSigData());
    }

    /**
     * @notice Produce the fact signature data for an account's storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSigData(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountStorage", blockNum, storageRoot);
    }

    /**
     * @notice Produce a fact signature for an account storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSig(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (FactSignature)
    {
        return
            Facts.toFactSignature(Facts.NO_FEE, accountStorageFactSigData(blockNum, storageRoot));
    }

    /**
     * @notice Produce the fact signature data for an account's code hash
     * @param blockNum the block number to look at
     * @param codeHash the codeHash for the account
     */
    function accountCodeHashFactSigData(uint256 blockNum, bytes32 codeHash)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountCodeHash", blockNum, codeHash);
    }

    /**
     * @notice Produce a fact signature for an account code hash
     * @param blockNum the block number to look at
     * @param codeHash the codeHash for the account
     */
    function accountCodeHashFactSig(uint256 blockNum, bytes32 codeHash)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, accountCodeHashFactSigData(blockNum, codeHash));
    }

    /**
     * @notice Produce the fact signature data for an account's nonce at a block
     * @param blockNum the block number to look at
     */
    function accountNonceFactSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("AccountNonce", blockNum);
    }

    /**
     * @notice Produce a fact signature for an account nonce at a block
     * @param blockNum the block number to look at
     */
    function accountNonceFactSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, accountNonceFactSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an account's balance at a block
     * @param blockNum the block number to look at
     */
    function accountBalanceFactSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("AccountBalance", blockNum);
    }

    /**
     * @notice Produce a fact signature for an account balance a block
     * @param blockNum the block number to look at
     */
    function accountBalanceFactSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, accountBalanceFactSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an account's raw header
     * @param blockNum the block number to look at
     */
    function accountFactSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("Account", blockNum);
    }

    /**
     * @notice Produce a fact signature for an account raw header
     * @param blockNum the block number to look at
     */
    function accountFactSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, accountFactSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSigData(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("StorageSlot", slot, blockNum);
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, storageSlotFactSigData(slot, blockNum));
    }

    /**
     * @notice Produce the fact signature data for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSigData(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (bytes memory) {
        return abi.encode("Log", blockNum, txIdx, logIdx);
    }

    /**
     * @notice Produce a fact signature for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSig(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, logFactSigData(blockNum, txIdx, logIdx));
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("BlockHeader", blockNum);
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, blockHeaderSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for a withdrawal
     * @param blockNum the block number
     * @param index the withdrawal index
     */
    function withdrawalSigData(uint256 blockNum, uint256 index)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("Withdrawal", blockNum, index);
    }

    /**
     * @notice Produce the fact signature for a withdrawal
     * @param blockNum the block number
     * @param index the withdrawal index
     */
    function withdrawalFactSig(uint256 blockNum, uint256 index)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, withdrawalSigData(blockNum, index));
    }

    /**
     * @notice Produce the fact signature data for an event fact
     * @param eventId The event in question
     */
    function eventFactSigData(uint64 eventId) internal pure returns (bytes memory) {
        return abi.encode("EventAttendance", "EventID", eventId);
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, eventFactSigData(eventId));
    }

    /**
     * @notice Produce the fact signature data for a transaction fact
     * @param transaction the transaction hash to be proven
     */
    function transactionFactSigData(bytes32 transaction) internal pure returns (bytes memory) {
        return abi.encode("Transaction", transaction);
    }

    /**
     * @notice Produce a fact signature for a transaction
     * @param transaction the transaction hash to be proven
     */
    function transactionFactSig(bytes32 transaction) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, transactionFactSigData(transaction));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

library Facts {
    uint8 internal constant NO_FEE = 0;

    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/**
 * @title MPT
 * @author Theori, Inc.
 * @notice Implements proof checking for Ethereum Merkle-Patricia Tries.
 *         To save gas, it assumes nodes are validly structured,
 *         so soundness is only guaranteed if the rootHash belongs
 *         to a valid ethereum block.
 */

pragma solidity >=0.8.0;

import "./RLP.sol";
import "./CoreTypes.sol";
import "./BytesCalldata.sol";

library MPT {
    using BytesCalldataOps for bytes;

    struct Node {
        BytesCalldata data;
        bytes32 hash;
    }

    // prefix constants
    uint8 constant ODD_LENGTH = 1;
    uint8 constant LEAF = 2;
    uint8 constant MAX_PREFIX = 3;

    /**
     * @notice parses concatenated MPT nodes into processed Node structs
     * @param input the concatenated MPT nodes
     * @return result the parsed nodes array, containing a calldata slice and hash
     *                for each node
     */
    function parseNodes(bytes calldata input) internal pure returns (Node[] memory result) {
        uint256 freePtr;
        uint256 firstNode;

        // we'll use a dynamic amount of memory starting at the free pointer
        // it is crucial that no other allocations happen during parsing
        assembly {
            freePtr := mload(0x40)

            // corrupt free pointer to cause out-of-gas if allocation occurs
            mstore(0x40, 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc)

            firstNode := freePtr
        }

        uint256 count;
        while (input.length > 0) {
            (uint256 listsize, uint256 offset) = RLP.parseList(input);
            bytes calldata node = input.slice(offset, listsize);
            BytesCalldata slice = node.convert();

            uint256 len;
            assembly {
                len := add(listsize, offset)

                // compute node hash
                calldatacopy(freePtr, input.offset, len)
                let nodeHash := keccak256(freePtr, len)

                // store the Node struct (calldata slice and hash)
                mstore(freePtr, slice)
                mstore(add(freePtr, 0x20), nodeHash)

                // advance pointer
                count := add(count, 1)
                freePtr := add(freePtr, 0x40)
            }

            input = input.suffix(len);
        }

        assembly {
            // allocate the result array and fill it with the node pointers
            result := freePtr
            mstore(result, count)
            freePtr := add(freePtr, 0x20)
            for {
                let i := 0
            } lt(i, count) {
                i := add(i, 1)
            } {
                mstore(freePtr, add(firstNode, mul(0x40, i)))
                freePtr := add(freePtr, 0x20)
            }

            // update the free pointer
            mstore(0x40, freePtr)
        }
    }

    /**
     * @notice parses a compressed MPT proof into arrays of Node structs
     * @param nodes the set of nodes used in the compressed proofs
     * @param compressed the compressed MPT proof
     * @param count the number of proofs expected from the compressed proof
     * @return result the array of proofs
     */
    function parseCompressedProofs(
        Node[] memory nodes,
        bytes calldata compressed,
        uint256 count
    ) internal pure returns (Node[][] memory result) {
        uint256 resultPtr;
        uint256 freePtr;

        // we'll use a dynamic amount of memory starting at the free pointer
        // it is crucial that no other allocations happen during parsing
        assembly {
            result := mload(0x40)

            // corrupt free pointer to cause out-of-gas if allocation occurs
            mstore(0x40, 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc)

            mstore(result, count)
            resultPtr := add(result, 0x20)
            freePtr := add(resultPtr, mul(0x20, count))
        }

        (uint256 listSize, uint256 offset) = RLP.parseList(compressed);
        compressed = compressed.slice(offset, listSize);

        // parse the indices and populate the proof list
        for (; count > 0; count--) {
            bytes calldata indices;
            (listSize, offset) = RLP.parseList(compressed);
            indices = compressed.slice(offset, listSize);
            compressed = compressed.suffix(listSize + offset);

            // begin next proof array
            uint256 arr;
            assembly {
                arr := freePtr
                freePtr := add(freePtr, 0x20)
            }

            // fill proof array
            uint256 len;
            for (len = 0; indices.length > 0; len++) {
                uint256 idx;
                (idx, offset) = RLP.parseUint(indices);
                indices = indices.suffix(offset);
                require(idx < nodes.length, "invalid node index in compressed proof");
                assembly {
                    let node := mload(add(add(nodes, 0x20), mul(0x20, idx)))
                    mstore(freePtr, node)
                    freePtr := add(freePtr, 0x20)
                }
            }

            assembly {
                // store the array length
                mstore(arr, len)

                // store the array pointer in the result
                mstore(resultPtr, arr)
                resultPtr := add(resultPtr, 0x20)
            }
        }

        assembly {
            // update the free pointer
            mstore(0x40, freePtr)
        }
    }

    /**
     * @notice Checks if the provided bytes match the key at a given offset
     * @param key the MPT key to check against
     * @param keyLen the length (in nibbles) of the key
     * @param testBytes the subkey to check
     */
    function subkeysEqual(
        bytes32 key,
        uint256 keyLen,
        bytes calldata testBytes
    ) private pure returns (bool result) {
        // arithmetic cannot overflow because testBytes is from calldata
        uint256 nibbleLength;
        unchecked {
            nibbleLength = 2 * testBytes.length;
            require(nibbleLength <= keyLen);
        }

        assembly {
            let shiftAmount := sub(256, shl(2, nibbleLength))
            let testValue := shr(shiftAmount, calldataload(testBytes.offset))
            let subkey := shr(shiftAmount, key)
            result := eq(testValue, subkey)
        }
    }

    /**
     * @notice checks the MPT proof. Note: for certain optimizations, we assume
     *         that the rootHash belongs to a valid ethereum block. Correctness
     *         is only guaranteed in that case.
     *         Gas usage depends on both proof size and key nibble values.
     *         Gas usage for actual ethereum account proofs: ~ 30000 - 45000
     * @param nodes MPT proof nodes, parsed using parseNodes()
     * @param key the MPT key, padded with trailing 0s if needed
     * @param keyLen the byte length of the MPT key, must be <= 32
     * @param expectedHash the root hash of the MPT
     */
    function verifyTrieValueWithNodes(
        Node[] memory nodes,
        bytes32 key,
        uint256 keyLen,
        bytes32 expectedHash
    ) internal pure returns (bool exists, bytes calldata value) {
        // handle completely empty trie case
        if (nodes.length == 0) {
            require(keccak256(hex"80") == expectedHash, "root hash incorrect");
            return (false, msg.data[:0]);
        }

        // we will read the key nibble by nibble, so double the length
        unchecked {
            keyLen *= 2;
        }

        // initialize return values to make solc happy;
        // one will always be overwritten before returing
        assembly {
            value.offset := 0
            value.length := 0
        }
        exists = true;

        // we'll use nodes as a pointer, advancing through each element
        // end will point to the end of the array
        uint256 end;
        assembly {
            end := add(nodes, add(0x20, mul(0x20, mload(nodes))))
            nodes := add(nodes, 0x20)
        }

        while (true) {
            bytes calldata node;
            {
                BytesCalldata slice;
                bytes32 nodeHash;

                // load the element and advance the proof pointer
                assembly {
                    // bounds checking
                    if iszero(lt(nodes, end)) {
                        revert(0, 0)
                    }

                    let ptr := mload(nodes)
                    nodes := add(nodes, 0x20)

                    slice := mload(ptr)
                    nodeHash := mload(add(ptr, 0x20))
                }
                node = slice.convert();

                require(nodeHash == expectedHash, "node hash incorrect");
            }

            // find the length of the first two elements
            uint256 size = RLP.nextSize(node);
            unchecked {
                size += RLP.nextSize(node.suffix(size));
            }

            // we now know which type of node we're looking at:
            // leaf + extension nodes have 2 list elements, branch nodes have 17
            if (size == node.length) {
                // only two elements, leaf or extension node
                bytes calldata encodedPath;
                (encodedPath, node) = RLP.splitBytes(node);

                // keep track of whether the key nibbles match
                bool keysMatch;

                // the first nibble of the encodedPath tells us the type of
                // node and if it contains an even or odd number of nibbles
                uint8 firstByte = uint8(encodedPath[0]);
                uint8 prefix = firstByte >> 4;
                require(prefix <= MAX_PREFIX);
                if (prefix & ODD_LENGTH == 0) {
                    // second nibble is padding, must be 0
                    require(firstByte & 0xf == 0);
                    keysMatch = true;
                } else {
                    // second nibble is part of key
                    keysMatch = (firstByte & 0xf) == (uint8(bytes1(key)) >> 4);
                    unchecked {
                        key <<= 4;
                        keyLen--;
                    }
                }

                // check the remainder of the encodedPath
                encodedPath = encodedPath.suffix(1);
                keysMatch = keysMatch && subkeysEqual(key, keyLen, encodedPath);
                // cannot overflow because encodedPath is from calldata
                unchecked {
                    key <<= 8 * encodedPath.length;
                    keyLen -= 2 * encodedPath.length;
                }

                if (prefix & LEAF == 0) {
                    // extension can't prove nonexistence, subkeys must match
                    require(keysMatch);

                    (expectedHash, ) = CoreTypes.parseHash(node);
                } else {
                    // leaf node, must have used all of key
                    require(keyLen == 0);

                    if (keysMatch) {
                        // if keys equal, we found the value
                        (value, node) = RLP.splitBytes(node);
                        break;
                    } else {
                        // if keys aren't equal, key doesn't exist
                        exists = false;
                        break;
                    }
                }
            } else {
                // branch node, this is the hotspot for gas usage

                // there should be 17 elements (16 branch hashes + a value)
                // we won't explicitly check this in order to save gas, since
                // it's implied by inclusion in a valid ethereum block

                // also note, we never need the value element because we assume
                // uniquely-prefixed keys, so branch nodes never hold values

                // fetch the branch for the next nibble of the key
                uint256 keyNibble = uint256(key >> 252);

                // skip past the branches we don't need
                // we already skipped past 2 elements; start there if we can
                uint256 i = 0;
                if (keyNibble >= 2) {
                    i = 2;
                    node = node.suffix(size);
                }
                while (i < keyNibble) {
                    node = RLP.skip(node);
                    unchecked {
                        i++;
                    }
                }

                (expectedHash, ) = CoreTypes.parseHash(node);
                // if we've reached an empty branch, key doesn't exist
                if (expectedHash == 0) {
                    exists = false;
                    break;
                }
                unchecked {
                    key <<= 4;
                    keyLen -= 1;
                }
            }
        }
    }

    /**
     * @notice checks the MPT proof. Note: for certain optimizations, we assume
     *         that the rootHash belongs to a valid ethereum block. Correctness
     *         is only guaranteed in that case.
     *         Gas usage depends on both proof size and key nibble values.
     *         Gas usage for actual ethereum account proofs: ~ 30000 - 45000
     * @param proof the encoded MPT proof noodes concatenated
     * @param key the MPT key, padded with trailing 0s if needed
     * @param keyLen the byte length of the MPT key, must be <= 32
     * @param rootHash the root hash of the MPT
     */
    function verifyTrieValue(
        bytes calldata proof,
        bytes32 key,
        uint256 keyLen,
        bytes32 rootHash
    ) internal pure returns (bool exists, bytes calldata value) {
        Node[] memory nodes = parseNodes(proof);
        return verifyTrieValueWithNodes(nodes, key, keyLen, rootHash);
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Merkle Tree
 * @author Theori, Inc.
 * @notice Gas optimized SHA256 Merkle tree code.
 */
library MerkleTree {
    /**
     * @notice computes a SHA256 merkle root of the provided hashes, in place
     * @param temp the mutable array of hashes
     * @return the merkle root hash
     */
    function computeRoot(bytes32[] memory temp) internal view returns (bytes32) {
        uint256 count = temp.length;
        assembly {
            // repeat until we arrive at one root hash
            for {

            } gt(count, 1) {

            } {
                let dataElementLocation := add(temp, 0x20)
                let hashElementLocation := add(temp, 0x20)
                for {
                    let i := 0
                } lt(i, count) {
                    i := add(i, 2)
                } {
                    if iszero(
                        staticcall(gas(), 0x2, hashElementLocation, 0x40, dataElementLocation, 0x20)
                    ) {
                        revert(0, 0)
                    }
                    dataElementLocation := add(dataElementLocation, 0x20)
                    hashElementLocation := add(hashElementLocation, 0x40)
                }
                count := shr(1, count)
            }
        }
        return temp[0];
    }

    /**
     * @notice check if a hash is in the merkle tree for rootHash
     * @param rootHash the merkle root
     * @param index the index of the node to check
     * @param hash the hash to check
     * @param proofHashes the proof, i.e. the sequence of siblings from the
     *        node to root
     */
    function validProof(
        bytes32 rootHash,
        uint256 index,
        bytes32 hash,
        bytes32[] memory proofHashes
    ) internal view returns (bool result) {
        assembly {
            let constructedHash := hash
            let length := mload(proofHashes)
            let start := add(proofHashes, 0x20)
            let end := add(start, mul(length, 0x20))
            for {
                let ptr := start
            } lt(ptr, end) {
                ptr := add(ptr, 0x20)
            } {
                let proofHash := mload(ptr)

                // use scratch space (0x0 - 0x40) for hash input
                switch and(index, 1)
                case 0 {
                    mstore(0x0, constructedHash)
                    mstore(0x20, proofHash)
                }
                case 1 {
                    mstore(0x0, proofHash)
                    mstore(0x20, constructedHash)
                }

                // compute sha256
                if iszero(staticcall(gas(), 0x2, 0x0, 0x40, 0x0, 0x20)) {
                    revert(0, 0)
                }
                constructedHash := mload(0x0)

                index := shr(1, index)
            }
            result := eq(constructedHash, rootHash)
        }
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/*
 * @author Theori, Inc.
 */

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

uint256 constant BASE_PROOF_SIZE = 34;
uint256 constant SUBPROOF_LIMBS_SIZE = 16;

struct RecursiveProof {
    uint256[BASE_PROOF_SIZE] base;
    uint256[SUBPROOF_LIMBS_SIZE] subproofLimbs;
    uint256[] inputs;
}

struct SignedRecursiveProof {
    RecursiveProof inner;
    bytes signature;
}

/**
 * @notice recover the signer of the proof
 * @param proof the SignedRecursiveProof
 * @return the address of the signer
 */
function getProofSigner(SignedRecursiveProof calldata proof) pure returns (address) {
    bytes32 msgHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n", "32", hashProof(proof.inner))
    );
    return ECDSA.recover(msgHash, proof.signature);
}

/**
 * @notice hash the contents of a RecursiveProof
 * @param proof the RecursiveProof
 * @return result a 32-byte digest of the proof
 */
function hashProof(RecursiveProof calldata proof) pure returns (bytes32 result) {
    uint256[] calldata inputs = proof.inputs;
    assembly {
        let ptr := mload(0x40)
        let contigLen := mul(0x20, add(BASE_PROOF_SIZE, SUBPROOF_LIMBS_SIZE))
        let inputsLen := mul(0x20, inputs.length)
        calldatacopy(ptr, proof, contigLen)
        calldatacopy(add(ptr, contigLen), inputs.offset, inputsLen)
        result := keccak256(ptr, add(contigLen, inputsLen))
    }
}

/**
 * @notice reverse the byte order of a uint256
 * @param input the input value
 * @return v the byte-order reversed value
 */
function byteReverse(uint256 input) pure returns (uint256 v) {
    v = input;

    uint256 MASK08 = 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;
    uint256 MASK16 = 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000;
    uint256 MASK32 = 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000;
    uint256 MASK64 = 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000;

    // swap bytes
    v = ((v & MASK08) >> 8) | ((v & (~MASK08)) << 8);

    // swap 2-byte long pairs
    v = ((v & MASK16) >> 16) | ((v & (~MASK16)) << 16);

    // swap 4-byte long pairs
    v = ((v & MASK32) >> 32) | ((v & (~MASK32)) << 32);

    // swap 8-byte long pairs
    v = ((v & MASK64) >> 64) | ((v & (~MASK64)) << 64);

    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
}

/**
 * @notice reads a 32-byte hash from its little-endian word-encoded form
 * @param words the hash words
 * @return the hash
 */
function readHashWords(uint256[] calldata words) pure returns (bytes32) {
    uint256 mask = 0xffffffffffffffff;
    uint256 result = (words[0] & mask);
    result |= (words[1] & mask) << 0x40;
    result |= (words[2] & mask) << 0x80;
    result |= (words[3] & mask) << 0xc0;
    return bytes32(byteReverse(result));
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title RLP
 * @author Theori, Inc.
 * @notice Gas optimized RLP parsing code. Note that some parsing logic is
 *         duplicated because helper functions are oddly expensive.
 */
library RLP {
    function parseUint(bytes calldata buf) internal pure returns (uint256 result, uint256 size) {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not a long string or list (> 0xB7)
            // also ensure it's not a short string longer than 32 bytes (> 0xA0)
            if gt(kind, 0xA0) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                result := kind
                size := 1
            }
            case false {
                // short string
                size := sub(kind, 0x80)

                // ensure it's not reading out of bounds
                if lt(buf.length, size) {
                    revert(0, 0)
                }

                switch eq(size, 32)
                case true {
                    // if it's exactly 32 bytes, read it from calldata
                    result := calldataload(add(buf.offset, 1))
                }
                case false {
                    // if it's < 32 bytes, we've already read it from calldata
                    result := shr(shl(3, sub(32, size)), shl(8, first32))
                }
                size := add(size, 1)
            }
        }
    }

    function nextSize(bytes calldata buf) internal pure returns (uint256 size) {
        assembly {
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            switch lt(kind, 0x80)
            case true {
                // small single byte
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    size := add(1, sub(kind, 0x80))
                }
                case false {
                    switch lt(kind, 0xC0)
                    case true {
                        // long string
                        let lengthSize := sub(kind, 0xB7)

                        // ensure that we don't overflow
                        if gt(lengthSize, 31) {
                            revert(0, 0)
                        }

                        // ensure that we don't read out of bounds
                        if lt(buf.length, lengthSize) {
                            revert(0, 0)
                        }
                        size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                        size := add(size, add(1, lengthSize))
                    }
                    case false {
                        switch lt(kind, 0xF8)
                        case true {
                            // short list
                            size := add(1, sub(kind, 0xC0))
                        }
                        case false {
                            let lengthSize := sub(kind, 0xF7)

                            // ensure that we don't overflow
                            if gt(lengthSize, 31) {
                                revert(0, 0)
                            }
                            // ensure that we don't read out of bounds
                            if lt(buf.length, lengthSize) {
                                revert(0, 0)
                            }
                            size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                            size := add(size, add(1, lengthSize))
                        }
                    }
                }
            }
        }
    }

    function skip(bytes calldata buf) internal pure returns (bytes calldata) {
        uint256 size = RLP.nextSize(buf);
        assembly {
            buf.offset := add(buf.offset, size)
            buf.length := sub(buf.length, size)
        }
        return buf;
    }

    function parseList(bytes calldata buf)
        internal
        pure
        returns (uint256 listSize, uint256 offset)
    {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a list
            if lt(kind, 0xC0) {
                revert(0, 0)
            }

            switch lt(kind, 0xF8)
            case true {
                // short list
                listSize := sub(kind, 0xC0)
                offset := 1
            }
            case false {
                // long list
                let lengthSize := sub(kind, 0xF7)

                // ensure that we don't overflow
                if gt(lengthSize, 31) {
                    revert(0, 0)
                }
                // ensure that we don't read out of bounds
                if lt(buf.length, lengthSize) {
                    revert(0, 0)
                }
                listSize := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                offset := add(lengthSize, 1)
            }
        }
    }

    function splitBytes(bytes calldata buf)
        internal
        pure
        returns (bytes calldata result, bytes calldata rest)
    {
        uint256 offset;
        uint256 size;
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not list
            if gt(kind, 0xBF) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                offset := 0
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    offset := 1
                    size := sub(kind, 0x80)
                }
                case false {
                    // long string
                    let lengthSize := sub(kind, 0xB7)

                    // ensure that we don't overflow
                    if gt(lengthSize, 31) {
                        revert(0, 0)
                    }
                    // ensure we don't read out of bounds
                    if lt(buf.length, lengthSize) {
                        revert(0, 0)
                    }
                    size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                    offset := add(lengthSize, 1)
                }
            }

            result.offset := add(buf.offset, offset)
            result.length := size

            let end := add(offset, size)
            rest.offset := add(buf.offset, end)
            rest.length := sub(buf.length, end)
        }
    }

    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        // allocate our result bytes
        bytes memory result = new bytes(33);

        if (value == 0) {
            // store length = 1, value = 0x80
            assembly {
                mstore(add(result, 1), 0x180)
            }
            return result;
        }

        if (value < 128) {
            // store length = 1, value = value
            assembly {
                mstore(add(result, 1), or(0x100, value))
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 33, prefix 0xa0 followed by value
            assembly {
                mstore(add(result, 1), 0x21a0)
                mstore(add(result, 33), value)
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 32, prefix 0x9f followed by value
            assembly {
                mstore(add(result, 1), 0x209f)
                mstore(add(result, 33), shl(8, value))
            }
            return result;
        }

        assembly {
            let length := 1
            for {
                let min := 0x100
            } lt(sub(min, 1), value) {
                min := shl(8, min)
            } {
                length := add(length, 1)
            }

            let bytesLength := add(length, 1)

            // bytes length field
            let hi := shl(mul(bytesLength, 8), bytesLength)

            // rlp encoding of value
            let lo := or(shl(mul(length, 8), add(length, 0x80)), value)

            mstore(add(result, bytesLength), or(hi, lo))
        }
        return result;
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IReliquary.sol";
import "../interfaces/IProver.sol";

abstract contract Prover is ERC165, IProver {
    IReliquary immutable reliquary;

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    event FactProven(Fact fact);

    // must implemented by each prover
    function _prove(bytes calldata proof) internal view virtual returns (Fact memory);

    // can optionally be overridden by each prover
    function _afterStore(Fact memory fact, bool alreadyStored) internal virtual {}

    /**
     * @notice proves a fact ephemerally and returns the fact information
     * @param proof the encoded proof for this prover
     * @param store whether to store the fact in the reqliquary
     */
    function prove(bytes calldata proof, bool store) public payable returns (Fact memory fact) {
        reliquary.checkProveFactFee{value: msg.value}(msg.sender);
        fact = _prove(proof);
        emit FactProven(fact);
        if (store) {
            (bool alreadyStored, , ) = reliquary.getFact(fact.account, fact.sig);
            reliquary.setFact(fact.account, fact.sig, fact.data);
            _afterStore(fact, alreadyStored);
        }
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IProver
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return (interfaceId == type(IProver).interfaceId || super.supportsInterface(interfaceId));
    }
}

/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../BlockHistory.sol";
import "../interfaces/IReliquary.sol";
import "../lib/BytesCalldata.sol";
import "../lib/CoreTypes.sol";
import "../lib/RLP.sol";
import "../lib/MPT.sol";

/**
 * @title StateVerifier
 * @author Theori, Inc.
 * @notice StateVerifier is a base contract for verifying historical Ethereum
 *         state using BlockHistory proofs and MPT proofs.
 */
contract StateVerifier {
    using BytesCalldataOps for bytes;

    BlockHistory public immutable blockHistory;
    IReliquary private immutable reliquary;

    constructor(BlockHistory _blockHistory, IReliquary _reliquary) {
        blockHistory = _blockHistory;
        reliquary = _reliquary;
    }

    /**
     * @notice verifies that the block header is included in the current chain
     *         by querying the BlockHistory contract using the provided proof.
     *         Reverts if the header or proof is invalid.
     *
     * @param header the block header in RLP encoded form
     * @param proof the proof to pass to blockHistory
     * @return head the parsed block header
     */
    function verifyBlockHeader(bytes calldata header, bytes calldata proof)
        internal
        view
        returns (CoreTypes.BlockHeaderData memory head)
    {
        // first validate the block, ensuring that the rootHash is valid
        (bytes32 blockHash, ) = CoreTypes.getBlockHeaderHashAndSize(header);
        head = CoreTypes.parseBlockHeader(header);
        reliquary.assertValidBlockHashFromProver(
            address(blockHistory),
            blockHash,
            head.Number,
            proof
        );
    }

    /**
     * @notice verifies that the account is included in the account trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the stateRoot
     *         comes from a valid Ethereum block header.
     *
     * @param account the account address to check
     * @param proof the MPT proof for the account trie
     * @param stateRoot the MPT root hash for the account trie
     * @return exists whether the account exists
     * @return acc the parsed account value
     */
    function verifyAccount(
        address account,
        bytes calldata proof,
        bytes32 stateRoot
    ) internal pure returns (bool exists, CoreTypes.AccountData memory acc) {
        bytes32 key = keccak256(abi.encodePacked(account));

        // validate the trie node and extract the value (if it exists)
        bytes calldata accountValue;
        (exists, accountValue) = MPT.verifyTrieValue(proof, key, 32, stateRoot);
        if (exists) {
            acc = CoreTypes.parseAccount(accountValue);
        }
    }

    /**
     * @notice verifies that the storage slot is included in the storage trie
     *         using the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the storageRoot
     *         comes from a valid Ethereum account.
     *
     * @param slot the storage slot index
     * @param proof the MPT proof for the storage trie
     * @param storageRoot the MPT root hash for the storage trie
     * @return value the value in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyStorageSlot(
        bytes32 slot,
        bytes calldata proof,
        bytes32 storageRoot
    ) internal pure returns (bytes calldata value) {
        bytes32 key = keccak256(abi.encodePacked(slot));

        // validate the trie node and extract the value (default is 0)
        bool exists;
        (exists, value) = MPT.verifyTrieValue(proof, key, 32, storageRoot);
        if (exists) {
            (value, ) = RLP.splitBytes(value);
            require(value.length <= 32);
        }
    }

    /**
     * @notice verifies that each storage slot is included in the storage trie
     *         using the provided proofs. Accepts both existence and nonexistence
     *         proofs. Reverts if a proof is invalid. Assumes the storageRoot
     *         comes from a valid Ethereum account.
     * @param proofNodes concatenation of all nodes used in the trie proofs
     * @param slots the list of slots being proven
     * @param slotProofs the compressed MPT proofs for each slot
     * @param storageRoot the MPT root hash for the storage trie
     * @return values the values in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyMultiStorageSlot(
        bytes calldata proofNodes,
        bytes32[] calldata slots,
        bytes calldata slotProofs,
        bytes32 storageRoot
    ) internal pure returns (BytesCalldata[] memory values) {
        MPT.Node[] memory nodes = MPT.parseNodes(proofNodes);
        MPT.Node[][] memory proofs = MPT.parseCompressedProofs(nodes, slotProofs, slots.length);
        BytesCalldata[] memory results = new BytesCalldata[](slots.length);

        for (uint256 i = 0; i < slots.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(slots[i]));
            (bool exists, bytes calldata value) = MPT.verifyTrieValueWithNodes(
                proofs[i],
                key,
                32,
                storageRoot
            );
            if (exists) {
                (value, ) = RLP.splitBytes(value);
                require(value.length <= 32);
            }
            results[i] = value.convert();
        }
        return results;
    }

    /**
     * @notice verifies that an entry is included in the indexed trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the root comes
     *         from a valid Ethereum MPT, i.e. from a valid block header.
     *
     * @param idx the receipt index in the block
     * @param proof the MPT proof for the indexed trie
     * @param root the MPT root hash for the indexed trie
     * @return exists whether the index exists
     * @return value the value at the given index, as bytes
     */
    function verifyIndexedTrieProof(
        uint256 idx,
        bytes calldata proof,
        bytes32 root
    ) internal pure returns (bool exists, bytes calldata value) {
        bytes memory key = RLP.encodeUint(idx);
        (exists, value) = MPT.verifyTrieValue(proof, bytes32(key), key.length, root);
    }

    /**
     * @notice verifies that the account is included in the account trie for
     *         a block using the provided proofs. Accepts both existence and
     *         nonexistence proofs. Reverts if the proofs are invalid.
     *
     * @param account the account address to check
     * @param accountProof the MPT proof for the account trie
     * @param header the block header in RLP encoded form
     * @param blockProof the proof to pass to blockHistory
     * @return exists whether the account exists
     * @return head the parsed block header
     * @return acc the parsed account value
     */
    function verifyAccountAtBlock(
        address account,
        bytes calldata accountProof,
        bytes calldata header,
        bytes calldata blockProof
    )
        internal
        view
        returns (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        )
    {
        head = verifyBlockHeader(header, blockProof);
        (exists, acc) = verifyAccount(account, accountProof, head.Root);
    }

    /**
     * @notice verifies a log was emitted in the given block, txIdx, and logIdx
     *         using the provided proofs. Reverts if the log doesn't exist or if
     *         the proofs are invalid.
     *
     * @param txIdx the transaction index in the block
     * @param logIdx the index of the log in the transaction
     * @param receiptProof the Merkle-Patricia trie proof for the receipt
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return log the parsed log value
     */
    function verifyLogAtBlock(
        uint256 txIdx,
        uint256 logIdx,
        bytes calldata receiptProof,
        bytes calldata header,
        bytes calldata blockProof
    ) internal view returns (CoreTypes.BlockHeaderData memory head, CoreTypes.LogData memory log) {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata receiptValue) = verifyIndexedTrieProof(
            txIdx,
            receiptProof,
            head.ReceiptHash
        );
        require(exists, "receipt does not exist");
        log = CoreTypes.extractLog(receiptValue, logIdx);
    }

    /**
     * @notice verifies the presence of a transaction in the given block at txIdx
     *         using the provided proofs. Reverts if the transaction doesn't exist or if
     *         the proofs are invalid.
     *
     * @param txIdx the transaction index in the block
     * @param transactionProof the Merkle-Patricia trie proof for the transaction's hash
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return txHash the hash of the transaction proven
     */
    function verifyTransactionAtBlock(
        uint256 txIdx,
        bytes calldata transactionProof,
        bytes calldata header,
        bytes calldata blockProof
    ) internal view returns (CoreTypes.BlockHeaderData memory head, bytes32 txHash) {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata txData) = verifyIndexedTrieProof(
            txIdx,
            transactionProof,
            head.TxHash
        );
        require(exists, "transaction does not exist in given block");
        txHash = keccak256(txData);
    }

    /**
     * @notice verifies a withdrawal occurred in the given block using the
     *         provided proofs. Reverts if the withdrawal doesn't exist or
     *         if the proofs are invalid.
     *
     * @param idx the index of the withdrawal in the block
     * @param withdrawalProof the Merkle-Patricia trie proof for the receipt
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return withdrawal the parsed withdrawal value
     */
    function verifyWithdrawalAtBlock(
        uint256 idx,
        bytes calldata withdrawalProof,
        bytes calldata header,
        bytes calldata blockProof
    )
        internal
        view
        returns (CoreTypes.BlockHeaderData memory head, CoreTypes.WithdrawalData memory withdrawal)
    {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata withdrawalValue) = verifyIndexedTrieProof(
            idx,
            withdrawalProof,
            head.WithdrawalsHash
        );
        require(exists, "Withdrawal does not exist at block");
        withdrawal = CoreTypes.parseWithdrawal(withdrawalValue);
    }
}