/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

// Tuan 110120220918
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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


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

// File: digiminer.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: digiminer.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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
library EnumerableSet {
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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

}
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
contract dminer is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private VortexiaOre; /* Integers which makes Vortexia Ore */
    EnumerableSet.UintSet private DiamondOre; /* Integers which makes Diamond Ore */
    EnumerableSet.UintSet private GoldOre; /* Integers which makes Golden Ore */
    EnumerableSet.UintSet private EmeraldOre; /* Integers which makes Emerald  Ore */
    EnumerableSet.UintSet private BronzeOre; /* Integers which makes Bronze Ore */
    EnumerableSet.UintSet private IronOre; /* Integers which makes Iron Ore */

    address private signerWallet;

    struct LotteryRound{
        uint256 RoundId; //round id
        uint256 startTime; //startTime of lottery
        uint256 endTime; //endTime of lottery 
        uint256 ticketsSold; //tickets sold in this round
        uint256 priceClaimed;
    } 

    struct Ticket{
        address holder; //owner of the ticket (non transferrable
        uint256 ticketKey; // a 3 digit number for each ticket
        uint256 miningLevel; //mining level of the NFT used to buy this ticket
        uint256 tokenId; //NFT used to buy this ticket
        bool claimed; // whether price is claimed or not
        Ores winningOre;
        uint256 price; // amount of price claimed for this ticket
    }


    struct JackpotClaim {
        address wallet;
        bool claimed;
    }
    /* Contract address of DIGI NFT */
    IERC721 public DIGI_NFT; 
   
    /* Current Round of Lottery */
    uint256 public LotteryRounds;

    
    /* Price for Each Ticket */
    uint256 public immutable ticketPrice = 0.01 ether;


    /* Winning Amount*/

    uint256 public constant Vortexia = 1 ether;
    uint256 public constant Diamond = 0.1 ether;
    uint256 public constant Gold = 0.02 ether;
    uint256 public constant Emerald = 0.01 ether;
    uint256 public constant Bronze = 0.002 ether;
    uint256 public constant Iron = 0.001 ether;
    
    struct BulkClaim {
        uint256 roundId;
        uint256[] ticketIds;
    }


    enum Ores {
        Vortexia,
        Diamond,
        Gold,
        Emerald,
        Bronze,
        Iron
    }
    /* 
    Mapping of Lottery round to nft id which returns uint256 to check how many tickets an NFT has bought;
    */
    mapping(uint256=>mapping(uint256=>uint256)) public nftUsed;

    mapping(Ores=>uint256) public price;
    /* Ticket counter for each round of NFT */
    mapping(uint256=>LotteryRound) public RoundDetails;


    /* Mapping of Lottery round to its winning key */
    mapping(uint256=>uint256) public winningKey;

    /* Mapping of lottery round with result announcement */
    mapping(uint256=>bool) public resultAnnounced;

    /* Mapping of Lottery Round to ticket id which returns uint256 output of 3 digits which is a key of any NFT*/
    mapping(uint256=>mapping(uint256=>Ticket)) public TicketKey;

    mapping(Ores=>uint256) public Distributelimit;

    mapping(uint256=>Ores) public checkore;

    mapping(uint256=>mapping(Ores=>uint256)) public claimCounter;

    mapping(address=>mapping(uint256=>uint256[])) private ticketHolding;

    event TicketPurchased(uint256 indexed ticketId, uint256 indexed roundId, address indexed buyer);
    event WinningClaimed(uint256 indexed ticketId, uint256 indexed roundId, address indexed buyer, uint256 price);
    event JackpotClaimed(uint256 indexed ticketId, uint256 indexed roundId, address indexed buyer, uint256 jackpotPrice);
    event ResultAnnounced(uint256 indexed roundId);


    constructor(){
        price[Ores.Vortexia]= Vortexia;
        price[Ores.Diamond]= Diamond;
        price[Ores.Gold]= Gold;
        price[Ores.Emerald]= Emerald;
        price[Ores.Bronze]= Bronze;
        price[Ores.Iron]= Iron;
        
        checkore[0]=Ores.Vortexia;
        checkore[1]=Ores.Diamond;
        checkore[2]=Ores.Gold;
        checkore[3]=Ores.Emerald;
        checkore[4]=Ores.Bronze;
        checkore[5]=Ores.Iron;

        Distributelimit[Ores.Vortexia] = 250;
        Distributelimit[Ores.Diamond] = 750;
        Distributelimit[Ores.Gold] = 4000;
        Distributelimit[Ores.Emerald] = 20000;
        Distributelimit[Ores.Bronze] = 25000;
        Distributelimit[Ores.Iron] = 50000;
    }
        
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number))) % 10**15;
    }

    function test1(uint256 value1, uint256 value2) public pure returns(uint256){
        return ((value1 % (10**20))*value2) % 1000;
    }

    function getTicketDetails(uint256 roundId, uint256 ticketId) public view returns(Ticket memory){
        return TicketKey[roundId][ticketId];
    }


    function changeSignerwallet(address _signerWallet) public onlyOwner {
        signerWallet = _signerWallet;
    }

    
    function getPrice(Ores ore) public view returns(uint256){
        return price[ore];
    }

    function getTicketHolding(address wallet, uint256 roundId) public view returns(uint256[] memory){
        return ticketHolding[wallet][roundId];
    }

    function currentRound() public view returns(uint256){
        return LotteryRounds;
    }

    function startRound(uint256 startTime, uint256 endTime) public onlyOwner {
        require(block.timestamp > RoundDetails[currentRound()].endTime, "DIGI: Last Round has not ended");
        LotteryRounds++;
        RoundDetails[LotteryRounds] = LotteryRound(LotteryRounds, startTime, endTime, 0,0);
        announceResult();
    }


    function buyTickets( bytes calldata signature,  uint256 quantity,  uint256 tokenIdHolding,  uint256 miningLevel) external payable nonReentrant {
        require(msg.value == ticketPrice.mul(quantity), "DIGI: Send proper ticket fees");
        //require(DIGI_NFT.ownerOf(tokenIdHolding) == msg.sender, "You are not owner of NFT");
        uint256 roundId = currentRound();
        require(checkSign(signature, quantity, tokenIdHolding, miningLevel, _msgSender(), roundId)==signerWallet, "DIGI: Fake signature");
        //nftUsed[roundId][tokenIdHolding] += quantity;
        //require(nftUsed[roundId][tokenIdHolding] <= 10, "DIGI: NFT used enough");
        LotteryRound storage round = RoundDetails[roundId];
        require(round.endTime>block.timestamp, "DIGI: Lottery has been ended");
        require(round.ticketsSold < 100000, "DIGI: All tickets are sold");
        for(uint256 i= 0;i<quantity; i++){
            round.ticketsSold += 1;
            uint256 ticketKey = getTicketKey(round.ticketsSold);
            Ores winningOre = getWinningOre(roundId, ticketKey, getMultiplier(miningLevel));
            claimCounter[roundId][winningOre]++;
            TicketKey[roundId][round.ticketsSold] = Ticket(_msgSender(), getTicketKey(round.ticketsSold), miningLevel, tokenIdHolding, false, winningOre, 0);
            ticketHolding[msg.sender][roundId].push(round.ticketsSold);
            emit TicketPurchased(round.ticketsSold, roundId, _msgSender());
        }
    }



    function checkSign(bytes calldata signature, uint256 quantity, uint256 tokenIdHolding, uint256 miningLevel, address wallet, uint256 roundId) private pure returns(address){
        return keccak256(
            abi.encodePacked(
               "\x19Ethereum Signed Message:\n32",
                getSignData(quantity, tokenIdHolding, miningLevel, wallet, roundId)   
            )
        ).recover(signature);
    }

    function getSignData(uint256 quantity, uint256 tokenIdHolding, uint256 miningLevel, address wallet, uint256 roundId) public pure returns(bytes32) {
        return (
        keccak256(abi.encodePacked(keccak256(abi.encodePacked(wallet)), keccak256(abi.encodePacked(quantity, tokenIdHolding, miningLevel, roundId))))
        );
    }
    function announceResult() private {
        uint256 roundId = currentRound();
        require(resultAnnounced[roundId] == false, "DIGI: Already Announced");
        resultAnnounced[roundId] = true;
        uint256 key = random(); /* will use chainlink in real contract */
        winningKey[roundId] = key;
        emit ResultAnnounced(roundId);
    }    

    function distributionLimit(Ores ore) public view returns(uint256){
        return Distributelimit[ore];
    }

    function getTicketKey(uint256 ticketId) internal view returns(uint256){
        return uint(keccak256(abi.encodePacked(ticketId, block.difficulty, block.timestamp, block.number))) % 10**3;
    }

    function getWinningKey(uint256 roundId) public view returns(uint256){
        return winningKey[roundId];
    }

    
    /* 0-25 no additional random number generated
    26-50 one additional number
    51-75 two additional numbers
    76 and higher three additional numbers */
    
    function getMultiplier(uint256 miningLevel) public pure returns(uint256){
//        uint256 miningLevel = TicketKey[roundId][ticketId].miningLevel;
        uint256 multiplier;
        if(0 <= miningLevel && miningLevel <= 25){
            multiplier = 1;
        } else if(26 <= miningLevel && miningLevel <= 50){
            multiplier = 2;
        } else if(51 <= miningLevel && miningLevel <= 75){
            multiplier = 3;
        } else if(76 <= miningLevel){
            multiplier = 4;
        }
        return multiplier;
    }

    function getTicketWinning(uint256 roundId, uint256 ticketId) public view returns(Ores ore){
        return TicketKey[roundId][ticketId].winningOre;
    }
    
    function getWinningOre(uint256 roundId, uint256 TicketKey_, uint256 multiplier) public view returns(Ores Ore){
        //uint256 TicketKey_ = TicketKey[roundId][ticketId].ticketKey;
        uint256 winningKey_ = getWinningKey(roundId);
        Ores previousOre = Ores.Iron; //starting from lowest
      //  uint256 multipler = getMultiplier(ticketId,roundId);
        for(uint256 i = 1; i<=multiplier; i++) {
        Ores ore;
        uint256 result_ = ticketKeyFactory(TicketKey_, i).mul(winningKey_);
        uint256 multiplierResult= result_ % 1000 ;
           ore = _getWinningOre(roundId, multiplierResult);
            if (previousOre > ore) {
                previousOre = ore;
            }
        }
       return previousOre;
    }

    function _getWinningOre(uint256 roundId, uint256 number) private view returns(Ores){
        Ores ore = getOre(number);
        uint256 num = oreToNumber(ore);
        uint256 nextNum;
        if(claimAvailable(roundId, num) == true){
            return ore;
        } else {
            nextNum = upToDown(roundId, num);
            if(nextNum == 7){
                nextNum = downToUp(roundId, num);
            }
            /* If its still 7 then iron ore will be given */
            if(nextNum == 7){
                nextNum = 5;
            }
        }
        Ores finalOre = numberToOre(nextNum);
        return finalOre;
    }


    function upToDown(uint256 roundId, uint256 ore) private view returns(uint256 num){
        num = 7; //7 means none,  not available
        for(uint256 i = ore; i <= 5; i++){
            if(claimAvailable(roundId, i)){
                num = i;
            }
        }
        return num;
    }

    function downToUp(uint256 roundId, uint256 ore) private view returns(uint256 num){
        num = 7; //7 means none, not available
         for(uint256 i = ore; i >= 0; i--){
            if(claimAvailable(roundId, i)){
                num = i;
            }
        }
        return num;
    }

    function oreToNumber(Ores ore) public pure returns(uint256 num){
            return uint256(ore);
    }

    function numberToOre(uint256 number) public view returns(Ores ore){
        return checkore[number];
    }

    function claimAvailable(uint256 roundId, uint256 ore) private view returns(bool){
        Ores ore_ = numberToOre(ore);
        if(Distributelimit[ore_]>claimCounter[roundId][ore_]){
            return true;
        }
        return false;
    }

    function ticketKeyFactory(uint256 ticketKey, uint256 multiplier) private pure returns(uint256){
        return ticketKey.mul(multiplier) % 1000;
    }

    function getOre(uint256 number) public view returns(Ores Ore){
        if(VortexiaOre.contains(number)){
            return Ores.Vortexia;
        } else if(DiamondOre.contains(number)){
            return Ores.Diamond;
        } else if(GoldOre.contains(number)) {
            return Ores.Gold;
        } else if (EmeraldOre.contains(number)){
            return Ores.Emerald;
        } else if (BronzeOre.contains(number)){
            return Ores.Bronze;
        } else if(IronOre.contains(number)){
            return Ores.Iron;
        }
        return Ores.Iron;
    }


    function claimAllWinning(uint256 roundId, uint256[] memory ticketIds) public nonReentrant {
        for(uint256 i=0;i<ticketIds.length;i++){
            if(TicketKey[roundId][ticketIds[i]].claimed == false){
                _claimWinning(roundId, ticketIds[i]);
            }
        }
    }


    function bulkClaim(BulkClaim[] memory data) public nonReentrant {
        for(uint256 i=0;i<data.length;i++){
            uint256 roundId = data[i].roundId;
            for(uint256 j=0;j<data[i].ticketIds.length;j++){
                if(TicketKey[roundId][data[i].ticketIds[i]].claimed == false){
                    _claimWinning(roundId, data[i].ticketIds[i]);
                }
            }
        }
    }


    function claimWinning(uint256 roundId, uint256 ticketId) public nonReentrant {
        _claimWinning(roundId, ticketId);
    }

    function _claimWinning(uint256 roundId, uint256 ticketId) private {
        Ticket storage ticket = TicketKey[roundId][ticketId];
        require(ticket.claimed == false, "DIGI: Already claimed");
        require(DIGI_NFT.ownerOf(ticket.tokenId) == _msgSender(), "DIGI: You dont own the NFT");
        ticket.claimed = true;
        LotteryRound storage round = RoundDetails[roundId];
        require(ticket.holder == _msgSender(),"DIGI: You are not owner");
        Ores winningOre = ticket.winningOre;
        uint256 winning = getPrice(winningOre);
        ticket.price = winning;
        round.priceClaimed += winning;
        TransferHelper.safeTransferETH(_msgSender(), winning);
        emit WinningClaimed(roundId, ticketId, _msgSender(), winning);
    }



    function setVortexia(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            VortexiaOre.add(tuple[i]);
        }
    }

    function setDiamond(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            DiamondOre.add(tuple[i]);
        }
    }

    function setGold(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            GoldOre.add(tuple[i]);
        }
    }

    function setIron(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            IronOre.add(tuple[i]);
        }
    }

    function setEmerald(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            EmeraldOre.add(tuple[i]);
        }
    }

    function setBronze(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            BronzeOre.add(tuple[i]);
        }
    }   
    
    function removeVortexia(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            VortexiaOre.remove(tuple[i]);
        }
    }

    function removeDiamond(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            DiamondOre.remove(tuple[i]);
        }
    }

    function removeGold(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            GoldOre.remove(tuple[i]);
        }
    }

    function removeEmerald(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            EmeraldOre.remove(tuple[i]);
        }
    }

    function removeBronze(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            BronzeOre.remove(tuple[i]);
        }
    }

    function removeIron(uint256[] memory tuple) public onlyOwner {
        for(uint256 i=0;i<tuple.length;i++){
            IronOre.remove(tuple[i]);
        }
    } 

    function getGold(uint256 index) public view returns(uint256) {
        return GoldOre.at(index);
    }

    function getIron(uint256 index) public view returns(uint256) {
        return IronOre.at(index);
    }

    function getBronze(uint256 index) public view returns(uint256) {
        return BronzeOre.at(index);
    }

    function getEmerald(uint256 index) public view returns(uint256) {
        return EmeraldOre.at(index);
    }

    function getVortexia(uint256 index) public view returns(uint256) {
        return VortexiaOre.at(index);
    }

    function getDiamond(uint256 index) public view returns(uint256) {
        return DiamondOre.at(index);
    }
}