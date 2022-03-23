// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IGmStudioBlobStorage.sol";
import "../utils/sstore2/SSTORE2.sol";

/// @notice Canonical implementation of a blob storage contract.
/// @dev Stores data in contract bytecode.
contract GmStudioBlobStorage is ERC165, IGmStudioBlobStorage {
    address private immutable pointer;

    constructor(bytes memory code) {
        pointer = SSTORE2.write(code);
    }

    function getBlob() external view override returns (bytes memory) {
        return SSTORE2.read(pointer);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IGmStudioBlobStorage).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";

import "./IGmStudioBlobStorage.sol";
import "./GmStudioBlobStorage.sol";

//                                           __                    __ __
//                                          |  \                  |  \  \
//   ______  ______ ____           _______ _| ▓▓_   __    __  ____| ▓▓\▓▓ ______
//  /      \|      \    \         /       \   ▓▓ \ |  \  |  \/      ▓▓  \/      \
// |  ▓▓▓▓▓▓\ ▓▓▓▓▓▓\▓▓▓▓\       |  ▓▓▓▓▓▓▓\▓▓▓▓▓▓ | ▓▓  | ▓▓  ▓▓▓▓▓▓▓ ▓▓  ▓▓▓▓▓▓\
// | ▓▓  | ▓▓ ▓▓ | ▓▓ | ▓▓        \▓▓    \  | ▓▓ __| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓ ▓▓  | ▓▓
// | ▓▓__| ▓▓ ▓▓ | ▓▓ | ▓▓__      _\▓▓▓▓▓▓\ | ▓▓|  \ ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓ ▓▓__/ ▓▓
//  \▓▓    ▓▓ ▓▓ | ▓▓ | ▓▓  \    |       ▓▓  \▓▓  ▓▓\▓▓    ▓▓\▓▓    ▓▓ ▓▓\▓▓    ▓▓
//  _\▓▓▓▓▓▓▓\▓▓  \▓▓  \▓▓\▓▓     \▓▓▓▓▓▓▓    \▓▓▓▓  \▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓ \▓▓▓▓▓▓
// |  \__| ▓▓
//  \▓▓    ▓▓
//   \▓▓▓▓▓▓
//
contract GmStudioCodeRepository is Ownable {
    using DynamicBuffer for bytes;

    /// @notice The possible types of registered collections.
    enum CollectionType {
        Unknown,
        OnChain,
        InChain
    }

    /// @notice The data entries for a collection.
    /// @dev `id` corresponds to the index in `collectionList`
    /// `exists` is used to indicate if a collection is in the repo (due to zero
    /// default values of mappings)
    /// `locked` if a collection cannot be changed anymore
    /// `collectionType` indicates if the collection is on- or in-chain
    /// `storageContracts` is the list of contracts used for code storage
    /// `artist` is the artist address used to sign the registry entry (equals
    /// zero if the entry is not signed)
    /// `version` allows for possible future versioning requirements.
    struct CollectionData {
        bool locked;
        bool exists;
        CollectionType collectionType;
        uint8 version;
        address artist;
        uint64 id;
        IGmStudioBlobStorage[] storageContracts;
    }

    /// @notice The type and code blob of a given collection.
    /// @dev Return type of `getBlob`
    /// @dev `data` corresponds to a GZip'ed tarball.
    struct CollectionBlob {
        CollectionType collectionType;
        bytes data;
    }

    /// @notice The collection contract addresses in the repository
    address[] internal collectionList;

    /// @notice The collection data in the repository
    mapping(address => CollectionData) internal collectionData;

    /// @notice Managers are addresses are allowed to perform special actions
    /// in place of owner
    mapping(address => bool) public isManager;

    /// @notice The collections supplementary notes. Used for post-lock
    /// informational addendums that are not part of standardized collection
    /// data.
    mapping(address => string[]) internal collectionNotes;

    constructor(address newOwner, address manager_) {
        isManager[manager_] = true;
        _transferOwnership(newOwner);
    }

    // -------------------------------------------------------------------------
    //
    //  Getters
    //
    // -------------------------------------------------------------------------

    /// @notice Returns the list of registered collections in the repository.
    function getCollections() external view returns (address[] memory) {
        return collectionList;
    }

    /// @notice Checks if a registered collection is locked.
    /// @param collection The collection of interest.
    /// @dev Reverts if the collection is not in the repository.
    function isLocked(address collection)
        external
        view
        collectionExists(collection)
        returns (bool)
    {
        return collectionData[collection].locked;
    }

    /// @notice Returns the code blob for a registered collection.
    /// @param collection The collection of interest.
    /// @dev For on-chain projects the return contains a GZip'ed tarball, that
    /// is already concatenated if multiple storage contracts were used.
    /// @dev Reverts if the collection is not in the repository.
    function getBlob(address collection)
        external
        view
        collectionExists(collection)
        returns (CollectionBlob memory)
    {
        CollectionBlob memory blob;
        CollectionData storage data = collectionData[collection];
        blob.collectionType = CollectionType(data.collectionType);

        if (blob.collectionType == CollectionType.InChain) {
            return blob;
        }

        // Concatenate all blobs
        IGmStudioBlobStorage[] storage stores = data.storageContracts;
        uint256 num = stores.length;
        blob.data = DynamicBuffer.allocate(num * 25000);
        for (uint256 idx = 0; idx < num; ++idx) {
            blob.data.appendSafe(stores[idx].getBlob());
        }

        return blob;
    }

    /// @notice Returns the storage addresses for a registered collection.
    /// @param collection The collection of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getStorageContracts(address collection)
        external
        view
        collectionExists(collection)
        returns (IGmStudioBlobStorage[] memory)
    {
        return collectionData[collection].storageContracts;
    }

    /// @notice Returns the registry data for a registered collection.
    /// @param collection The collection of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getCollectionData(address collection)
        external
        view
        collectionExists(collection)
        returns (CollectionData memory)
    {
        return collectionData[collection];
    }

    /// @notice Returns the storage type of a registered collection.
    /// @param collection The collection contract address of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getCollectionType(address collection)
        public
        view
        collectionExists(collection)
        returns (CollectionType)
    {
        return CollectionType(collectionData[collection].collectionType);
    }

    /// @notice Returns the list of notes attached to a registered collection.
    /// @param collection The collection contract address of interest.
    /// @dev Reverts if the collection is not in the repository.
    function getNotes(address collection)
        public
        view
        collectionExists(collection)
        returns (string[] memory)
    {
        return collectionNotes[collection];
    }

    // -------------------------------------------------------------------------
    //
    //  Setters
    //
    // -------------------------------------------------------------------------

    /// @notice A convenience interface to store blobs on-chain
    /// @dev Stores blobs in contract bytecode for efficiency
    /// @param blob The bytes of the blob to be stored
    function store(bytes calldata blob)
        external
        returns (IGmStudioBlobStorage)
    {
        IGmStudioBlobStorage storageContract = new GmStudioBlobStorage(blob);
        emit NewBlobStorage(storageContract);
        return storageContract;
    }

    /// @notice Adds a new collection to the repository.
    /// @param collection The collection of interest.
    /// @param storageContracts The contracts storing the code blobs.
    /// @dev Reverts if the collection already exists.
    function addOnChainCollection(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    ) external onlyManagerOrOwner {
        _addOnChainCollection(collection, storageContracts);
    }

    function addInChainCollection(address collection)
        external
        onlyManagerOrOwner
    {
        _addInchainCollection(collection);
    }

    /// @notice Pops collections from the internal list.
    /// @dev Reverts if the collection is locked.
    function popCollection() external onlyManagerOrOwner {
        _popCollection();
    }

    /// @notice Sets the storage contract addresses for a registered collection.
    /// @param collection The collection of interest.
    /// @param storageContracts The contract storing the code.
    /// @dev Reverts if the collection is locked, is not in the repository, or
    /// is not an on-chain collection.
    /// @dev Invalidates existing artist signatures.
    function setStorageContracts(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    ) external onlyManagerOrOwner {
        _setStorageContracts(collection, storageContracts);
    }

    /// @notice Changes the address of a registered collection.
    /// @param addrOld The previous address of the collection.
    /// @param addrNew The new address of the collection.
    /// @dev Reverts if the collection is locked or is not in the repository.
    /// @dev Invalidates existing artist signatures.
    function setCollectionAddress(address addrOld, address addrNew)
        external
        onlyManagerOrOwner
    {
        _setCollectionAddress(addrOld, addrNew);
    }

    /// @notice Adds a note to a locked collection.
    /// @param collection The collection to have notes added to.
    /// @param note The note to be added. If technical in nature, preferred to
    /// be structured JSON.
    /// @dev Reverts if the collection is not locked or is not in the repository
    function addNote(address collection, string calldata note)
        external
        onlyManagerOrOwner
        onlyLockedExistingCollection(collection)
    {
        collectionNotes[collection].push(note);
    }

    /// @notice Adds an artist to a registered collection.
    /// @param collection The collection of interest.
    /// @param artist The signing artist's address.
    /// @param signature The artist's signature.
    /// @dev Reverts if the collection is not in the repository or is locked, or
    /// if the given signature is invalid.
    /// @dev The signature is not stored explicitly within the contract.
    /// However, this method is the only way to add an artist to a collection.
    /// Hence, a collection can be regarded as signed if the artist is set.
    function addArtistWithSignature(
        address collection,
        address artist,
        bytes calldata signature
    ) external onlyManagerOrOwner {
        _addArtistWithSignature(collection, artist, signature);
    }

    /// @notice Locks a collection.
    /// @param collection The collection to be locked.
    /// @dev Reverts if the collection is locked or is not in the repository.
    function lock(address collection) external onlyOwner {
        _lock(collection);
    }

    /// @notice Sets or removes manager permissions for an address.
    /// @param manager The manager address.
    /// @param status Manager status to be set. True corresponds to granting
    /// elevated permissions.
    function setManager(address manager, bool status) external onlyOwner {
        isManager[manager] = status;
    }

    // -------------------------------------------------------------------------
    //
    //  Internal
    //
    // -------------------------------------------------------------------------

    /// @dev Restrics access to owner and manager
    modifier onlyManagerOrOwner() {
        if (!(msg.sender == owner() || isManager[msg.sender]))
            revert OnlyManagerOrOwner();
        _;
    }

    /// @notice Reverts if a collection is locked or nonexistent.
    modifier onlyUnlockedExistingCollection(address collection) {
        if (!collectionData[collection].exists) revert CollectionNotFound();
        if (collectionData[collection].locked) revert CollectionIsLocked();
        _;
    }

    /// @notice Reverts if a collection is not locked or nonexistent.
    modifier onlyLockedExistingCollection(address collection) {
        if (!collectionData[collection].exists) revert CollectionNotFound();
        if (!collectionData[collection].locked) revert CollectionIsNotLocked();
        _;
    }

    /// @notice Reverts if a collection is nonexistent.
    modifier collectionExists(address collection) {
        if (!collectionData[collection].exists) revert CollectionNotFound();
        _;
    }

    /// @notice Reverts if a collection.isOnChain does not match onChain.
    modifier hasCollectionType(
        address collection,
        CollectionType collectionType
    ) {
        if (
            CollectionType(collectionData[collection].collectionType) !=
            collectionType
        ) {
            revert WrongCollectionType(
                collectionData[collection].collectionType
            );
        }
        _;
    }

    /// @notice Reverts if a collection exists.
    modifier onlyNewCollections(address collection) {
        if (collectionData[collection].exists) revert CollectionAlreadyExists();
        _;
    }

    /// @notice Reverts if at least one of the given storageContracts does not
    /// satisfy the IGmStudioBlobStorage interface according to EIP-165.
    modifier onlyValidStorageContracts(
        IGmStudioBlobStorage[] calldata storageContracts
    ) {
        uint256 num = storageContracts.length;
        for (uint256 idx = 0; idx < num; ++idx) {
            (bool success, bytes memory returnData) = address(
                storageContracts[idx]
            ).call(
                    abi.encodePacked(
                        IERC165.supportsInterface.selector,
                        abi.encode(type(IGmStudioBlobStorage).interfaceId)
                    )
                );

            if (!success || returnData.length == 0) {
                revert InvalidStorageContract();
            }

            bool supported = abi.decode(returnData, (bool));
            if (!supported) {
                revert InvalidStorageContract();
            }
        }
        _;
    }

    /// @notice Adds a collection
    function _addOnChainCollection(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    )
        internal
        onlyNewCollections(collection)
        onlyValidStorageContracts(storageContracts)
    {
        uint256 nextId = collectionList.length;
        collectionList.push(collection);
        collectionData[collection] = CollectionData({
            locked: false,
            exists: true,
            collectionType: CollectionType.OnChain,
            artist: address(0),
            version: 0,
            id: uint64(nextId),
            storageContracts: storageContracts
        });
    }

    /// @notice Adds a collection
    function _addInchainCollection(address collection)
        internal
        onlyNewCollections(collection)
    {
        uint256 nextId = collectionList.length;
        collectionList.push(collection);
        collectionData[collection] = CollectionData({
            locked: false,
            exists: true,
            collectionType: CollectionType.InChain,
            artist: address(0),
            version: 0,
            id: uint64(nextId),
            storageContracts: new IGmStudioBlobStorage[](0)
        });
    }

    /// @notice Sets the storage contract addresses for a registered colleciton
    function _setStorageContracts(
        address collection,
        IGmStudioBlobStorage[] calldata storageContracts
    )
        internal
        onlyUnlockedExistingCollection(collection)
        hasCollectionType(collection, CollectionType.OnChain)
        onlyValidStorageContracts(storageContracts)
    {
        collectionData[collection].artist = address(0);
        collectionData[collection].storageContracts = storageContracts;
    }

    /// @notice Sets a new contract address for an existing collection.
    /// @dev Overwrites if `id` exists, reverts otherwise.
    /// @dev Reverts if the collection is locked or isn't in the repo.
    function _setCollectionAddress(address addrOld, address addrNew) internal {
        CollectionData memory data = collectionData[addrOld];
        data.artist = address(0);
        collectionData[addrNew] = data;
        collectionList[data.id] = addrNew;
        _removeCollectionData(addrOld);
    }

    /// @notice Pops an existing collection.
    /// @dev Reverts if the latest collection is locked.
    function _popCollection() internal {
        address collection = collectionList[collectionList.length - 1];
        _removeCollectionData(collection);
        collectionList.pop();
    }

    /// @notice Removes a registered collection.
    function _removeCollectionData(address collection)
        internal
        onlyUnlockedExistingCollection(collection)
    {
        delete collectionData[collection];
    }

    /// @notice Locks a collection.
    function _lock(address collection)
        internal
        onlyUnlockedExistingCollection(collection)
    {
        CollectionData storage data = collectionData[collection];
        if (
            (data.collectionType == CollectionType.OnChain &&
                data.storageContracts.length == 0) ||
            data.collectionType == CollectionType.Unknown
        ) revert StorageContractsNotSet();
        collectionData[collection].locked = true;
    }

    /// @notice Adds an artist to a registered collection
    /// @dev Reverts if the signature is invalid.
    function _addArtistWithSignature(
        address collection,
        address artist,
        bytes calldata signature
    ) internal onlyUnlockedExistingCollection(collection) {
        CollectionData storage data = collectionData[collection];
        data.artist = artist;

        bytes32 message = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(collection, data.storageContracts)
        );
        address signer = ECDSA.recover(message, signature);
        if (signer != artist) revert InvalidSignature();
    }

    // -------------------------------------------------------------------------
    //
    //  Events
    //
    // -------------------------------------------------------------------------

    event NewBlobStorage(IGmStudioBlobStorage indexed storageAddress);

    // -------------------------------------------------------------------------
    //
    //  Errors
    //
    // -------------------------------------------------------------------------

    error CollectionIsLocked();
    error CollectionIsNotLocked();
    error WrongCollectionType(CollectionType);
    error CollectionNotFound();
    error OnlyManagerOrOwner();
    error StorageContractsNotSet();
    error CollectionAlreadyExists();
    error InvalidStorageContract();
    error InvalidSignature();
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @notice Interface for on-chain data storage
interface IGmStudioBlobStorage is IERC165 {
    /// @notice Returns the stored code blob
    /// @dev Conforming to (a slice of) a GZip'ed tarball.
    function getBlob() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
    error WriteError();

    /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(hex"00", _data)
        );

        // Deploy contract using create
        assembly {
            pointer := create(0, add(code, 32), mload(code))
        }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
    function read(address _pointer, uint256 _start)
        internal
        view
        returns (bytes memory)
    {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
    function read(
        address _pointer,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}