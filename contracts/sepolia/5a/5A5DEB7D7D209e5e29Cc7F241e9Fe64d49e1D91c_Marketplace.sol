// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Trait} from "./Structs.sol";

/// @title Helpers
/// @dev A utility contract that provides signature verification and array manipulation functions.
library Helpers {
    using ECDSA for bytes32;

    /// @dev Checks if a given signature is valid for a specific message hash and signer address.
    /// @param signature The signature to be verified.
    /// @param msgHash The hash of the message that was signed.
    /// @param signer The address of the signer.
    /// @return True if the signature is valid, false otherwise.
    function _validSignature(bytes memory signature, bytes32 msgHash, address signer) internal pure returns (bool) {
        return msgHash.toEthSignedMessageHash().recover(signature) == signer;
    }

    /// @dev Checks if an array contains duplicate values.
    /// @param arr The array to be checked for duplicates.
    /// @return True if the array has duplicate values, false otherwise.
    function _hasDuplicate(uint[] memory arr) internal pure returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            for (uint j = i + 1; j < arr.length; j++) {
                if (arr[i] == arr[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @dev Checks if all values in arrayA are present in arrayB.
    /// @param arrayA The array containing the values to be checked.
    /// @param arrayB The array to be searched for the values from arrayA.
    /// @return True if all values in arrayA are present in arrayB, false otherwise.
    function _containsAllValues(uint[] memory arrayA, uint[] memory arrayB) internal pure returns (bool) {
        for (uint i = 0; i < arrayA.length; i++) {
            bool found = false;
            for (uint j = 0; j < arrayB.length; j++) {
                if (arrayA[i] == arrayB[j]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return false;
            }
        }
        return true;
    }

	/// @notice Initializes an array with the specified length and value
    /// @param length The length of the array
    /// @param value The value to initialize each element with
    /// @return The initialized array
    function _initArray(uint256 length, uint256 value) internal pure returns (uint256[] memory) {
        uint256[] memory _arr = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            _arr[i] = value;
        }
        return _arr;
    }

     /// @notice Extracts trait IDs and layer IDs from an array of Trait structs
    /// @param traits The array of Trait structs
    /// @return Two arrays containing trait IDs and layer IDs
    function _extractTraitLayerIds(Trait[] memory traits) internal pure returns (uint256[] memory, uint256[] memory) {
        uint256[] memory _traitIds = new uint256[](traits.length);
        uint256[] memory _layerIds = new uint256[](traits.length);
        for (uint256 i = 0; i < traits.length; i++) {
            _traitIds[i] = traits[i].traitId;
            _layerIds[i] = traits[i].layerId;
        }
        return (_traitIds, _layerIds);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external ;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import {Trait,AvatarTrait,OrderParams} from "../Structs.sol";
import "./IERC4907.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IMainNft is IERC4907,IERC721{

    function mintTempAvatar(address,OrderParams calldata,uint256,uint64) external;
    function getAvatarTraits(uint256) external view returns(uint256[] memory);
    function updateAvatarTraits(AvatarTrait calldata,AvatarTrait calldata) external;
    function updateAvatar(OrderParams calldata,uint256) external;
	function getAvatarTraitIndex(uint256,uint256) external view returns(bool,uint256);
	function temporalAvatars(uint256) external view returns(bool);
	function removeTemporalAvatar(uint256) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;
import {Trait} from "../Structs.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC4907.sol";
interface ITraitNft is IERC1155,IERC4907 {

    function isBaseLayer(uint8 _layerId) external view returns(bool);
    function getBaseLayers() external view returns(uint256[] memory);
	function batchTraitMint(address, uint256[] memory, uint256[] memory) external returns(bool);
    function rentAvatarTraits(address owner,address user,uint256[] memory traitIds,uint64 expires) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;
import "./interfaces/IMainNft.sol";
import "./interfaces/ITraitNft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Helpers} from "./Helpers.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Trait,RentAvatar,RentTrait,SellOrder,Swap} from "./Structs.sol";

// import "hardhat/console.sol";

/**
@title NFT Marketplace
@notice This contract handles the marketplace operations for NFT avatars and traits, such as renting, selling, and swapping.
@dev It extends the ReentrancyGuard, and Ownable contracts.
 The contract also uses Structs.sol for the data structures needed in various marketplace operations.
*/

contract Marketplace is ReentrancyGuard,Ownable{
    
   /// @notice The MainNft contract
   IMainNft public mainContract;
   /// @notice The TraitNft contract
   ITraitNft public traitContract;
   /// @notice The server address used for signing orders
   address public serverAddress;

   /// @notice Emitted when an unauthorized action is taken on a temporal NFT.
   event TemporalNFT(uint256,string);

    /**
     * @dev Modifier to check if the specified `owner` is the owner of the given `traitId`.
     * @param owner The address to check for ownership of the trait.
     * @param traitId The ID of the trait to check for ownership.
     * @notice This modifier will only allow the function to be called if the specified `owner` is the owner of the given `traitId`.
     */
    modifier isOwnerOfTrait(address owner, uint256 traitId) {
        require(traitContract.balanceOf(owner, traitId) > 0, "You are not the trait owner");
        _;
    }

    /**
     * @dev Modifier to check if the specified `owner` is the owner of the given `avatarId`.
     * @param owner The address to check for ownership of the avatar.
     * @param avatarId The ID of the avatar to check for ownership.
     * @notice This modifier will only allow the function to be called if the specified `owner` is the owner of the given `avatarId`.
     */
    modifier isOwnerOfAvatar(address owner, uint256 avatarId) {
        require(mainContract.ownerOf(avatarId) == owner, "The from account is not the avatar owner");
        _;
    }


  
    /**
    * @notice Constructor for the Marketplace contract.
    * @param _mainContract The address of the main NFT contract.
    * @param _traitContract The address of the trait NFT contract.
    * @param _server The address of the server used for signing orders.
    */
    constructor(address _mainContract,address _traitContract,address _server){
         require(_mainContract!=address(0) && _traitContract != address(0) && _server != address(0),"ADDRESS ZERO");
         mainContract = IMainNft(_mainContract);
         traitContract = ITraitNft(_traitContract);
         serverAddress = _server;
    }

    
     /**
    * @notice Sets the MainNft contract address
    * @param _mainAddress The address of the MainNft contract
	* @dev only the contract owner can call this function
	* Requirements:
    * - `_mainAddress` should not be NullAddress
	*/

    function updateMainContract(address _mainAddress) external onlyOwner {
        require(_mainAddress != address(0), "ADDRESS(0)");
        mainContract = IMainNft(_mainAddress);
    }
    /**
    * @notice Sets the TraitNft contract address
    * @param _traitAddress The address of the TraitNft contract
	* @dev only the contract owner can call this function
	* Requirements:
    * - `_traitAddress` should not be NullAddress
	*/

    function updateTraitContract(address _traitAddress) external onlyOwner {
        require(_traitAddress != address(0), "ADDRESS(0)");
        traitContract = ITraitNft(_traitAddress);
    }

        /**
    * @notice Sets the server address
    * @param _server The address of the server account
	* @dev only the contract owner can call this function
	* Requirements:
    * - `_server` should not be NullAddress
	*/

    function updateServerAddress(address _server) external { // commented onlyOwner for testing
        require(_server != address(0), "ADDRESS(0)");
        serverAddress = _server;
    }

    /**
    * @notice Allows users to rent an avatar.
    * @param _order The RentAvatar struct containing the rental order details.
    * @param _signature The signature of the rental order.
    */
    function rentAvatar(RentAvatar calldata _order,bytes calldata _signature) external payable nonReentrant isOwnerOfAvatar(_order.owner,_order.avatarId) {
        require(msg.value == _order.price,"Invalid Amount");
        require(_order.expires > block.timestamp,"expires should be in future");
        bytes32 orderHash = keccak256(
            abi.encodePacked("RentAvatar(",
			     _order.owner,
			     _order.avatarId,
				 _order.price,
				 _order.expires,
                 ")"
				));
        require(Helpers._validSignature(_signature, orderHash,_order.owner), "INVALID_SIGNATURE::INVALID_ORDER");        
        require(!mainContract.temporalAvatars(_order.avatarId),"You can not Rent a temporal Avatar");
		uint256[] memory traitIds = mainContract.getAvatarTraits(_order.avatarId);
        (bool sent,) = payable(_order.owner).call{value:msg.value}("");
		require(sent,"Failled to send Ether");
        mainContract.setUser(_order.avatarId,msg.sender,_order.expires);
        traitContract.rentAvatarTraits(_order.owner,msg.sender,traitIds,_order.expires);

    }
    /**
    * @notice Allows users to rent a trait.
    * @param _order The RentTrait struct containing the rental order details.
    * @param _signature The signature of the rental order.
    */
    function rentTrait(RentTrait calldata _order,bytes calldata _signature) external payable isOwnerOfTrait(_order.owner,_order.trait) {
        require(msg.value == _order.price,"Invalid Amount");
        require(_order.expires > block.timestamp,"expires should be in future");
        bytes32 orderHash = keccak256(
            abi.encodePacked("RentTrait(",
			     _order.owner,
			     _order.trait,
				 _order.price,
				 _order.data.fromAvatar,
                 _order.data.toAvatar,
                 _order.data.fromUri,
				 _order.data.toUri,
				 _order.expires,
                 ")"
				));
        require(Helpers._validSignature(_signature, orderHash,_order.owner), "INVALID_SIGNATURE::INVALID_ORDER");        
        (bool sent,) = payable(_order.owner).call{value:msg.value}("");
		require(sent,"Failled to send Ether");
        traitContract.setUser(_order.trait,msg.sender,_order.expires);
        mainContract.mintTempAvatar(msg.sender,_order.data,_order.trait,_order.expires);
    }
    /**
    * @notice Executes a sell order for an avatar or a trait.
    * @param _order The SellOrder struct containing the sell order details.
    * @param _signature The signature of the sell order.
    * @param _serverSig The server signature for the sell order.
    */
    function executeSellOrder(SellOrder calldata _order,bytes calldata _signature,bytes calldata _serverSig) external payable  {
        require(msg.value == _order.price,"Invalid Amount");
        bytes32 orderHash = keccak256(
            abi.encodePacked("SellOrder(",
			     _order.from,
			     _order.itemId,
                 _order.itemType,
                 _order.price,
                 ")"
				));
        bytes32 msgHash = keccak256(
            abi.encodePacked("SellValid(",
			     _order.itemId,
				 _order.data.fromAvatar,
                 _order.data.toAvatar,
                 ")"
				));
        require(Helpers._validSignature(_signature, orderHash,_order.from), "INVALID_SIGNATURE::INVALID_ORDER");
        require(Helpers._validSignature(_serverSig, msgHash,serverAddress), "INVALID_SIGNATURE::COMPATIBILITY");
        (bool sent,) = payable(_order.from).call{value:msg.value}("");
		require(sent,"Failled to send Ether");
        if(_order.itemType == 1) {
            require(_isAvatarTrait(_order.data.fromAvatar,_order.itemId),"Invalid Avatar Trait");
            require(traitContract.balanceOf(_order.from,_order.itemId)>0,"The from account is not the trait1 owner");
            require(mainContract.ownerOf(_order.data.toAvatar) == msg.sender,"You are not the avatar Owner");
            mainContract.updateAvatar(_order.data,_order.itemId);
            traitContract.safeTransferFrom(_order.from,msg.sender,_order.itemId,1,"");
        }
        else {
			require(mainContract.ownerOf(_order.itemId) == _order.from,"The from account are not the avatar owner");
			(bool is_tmp,bool is_exp) = checkTemporalNft(_order.itemId);
			require(!is_tmp || (is_tmp && is_exp),"ERROR :: Temporal NFT");
			if(!is_tmp) { 
				mainContract.safeTransferFrom(_order.from,msg.sender,_order.itemId);
			}
            else {
				mainContract.removeTemporalAvatar(_order.itemId);
				emit TemporalNFT(_order.itemId,"You cannot sell a temporary avatar as it will be burned during this action");
			} 
        }

    }

    /**
    * @notice Swaps two avatars or traits between users.
    * @param _order The Swap struct containing the swap order details.
    * @param _signature The signature of the swap order.
    * @param _serverSig The server signature for the swap order.
    */
    function swap(Swap calldata _order,bytes calldata _signature,bytes calldata _serverSig) external  {
         bytes32 orderHash = keccak256(
            abi.encodePacked("Swap(",
			     _order.from,
			     _order.item1.itemId,
				 _order.item2.itemId,
                 _order.itemType,
                 ")"
				));
        
        require(Helpers._validSignature(_signature, orderHash,_order.from), "INVALID_SIGNATURE::INVALID_ORDER");
        require(Helpers._validSignature(_serverSig, orderHash,serverAddress), "INVALID_SIGNATURE::COMPATIBILITY");
        if(_order.itemType == 1){
           require(traitContract.balanceOf(_order.from,_order.item1.itemId)>0,"The from account is not the trait1 owner");
           require(traitContract.balanceOf(msg.sender,_order.item2.itemId)>0,"You are not the trait2 owner");
           mainContract.updateAvatarTraits(_order.item1,_order.item2);
           traitContract.safeTransferFrom(_order.from,msg.sender,_order.item1.itemId,1,"");
           traitContract.safeTransferFrom(msg.sender,_order.from,_order.item2.itemId,1,"");
        }
        else {
		    (bool is_tmp1,bool is_exp1)  = checkTemporalNft(_order.item1.itemId);
			(bool is_tmp2,bool is_exp2)  = checkTemporalNft(_order.item2.itemId);
			require((!is_tmp1 && !is_tmp2) || (is_tmp1 && is_exp1) || (is_tmp2 && is_exp2),"ERROR :: Temporal NFT");
			if(!is_tmp1 && !is_tmp2){
		        mainContract.safeTransferFrom(_order.from,msg.sender,_order.item1.itemId);
                mainContract.safeTransferFrom(msg.sender,_order.from,_order.item2.itemId);
			}
			if(is_tmp1) {
				mainContract.removeTemporalAvatar(_order.item1.itemId);
				emit TemporalNFT(_order.item1.itemId,"You cannot swap a temporary avatar as it will be burned during this action");
			}
			if(is_tmp2) {
				mainContract.removeTemporalAvatar(_order.item2.itemId);
				emit TemporalNFT(_order.item2.itemId,"You cannot swap a temporary avatar as it will be burned during this action");
			}
		
			
        }

    }

    /**
    * @notice Checks if a given trait is applied to a specific avatar.
    * @param avatarId The ID of the avatar.
    * @param traitId The ID of the trait.
    * @return status True if the trait is applied to the avatar, false otherwise.
    */
     function _isAvatarTrait(uint256 avatarId,uint256 traitId) internal view returns(bool status) {
        (status,) = mainContract.getAvatarTraitIndex(avatarId,traitId);

    }

    /**
    * @notice Checks if an NFT is a temporal NFT.
    * @param avatarId The ID of the NFT.
    * @return True if the NFT is temporal, false otherwise.
    */
	function checkTemporalNft(uint256 avatarId) internal  view returns(bool,bool){
		bool is_tmp = mainContract.temporalAvatars(avatarId);
	   return (is_tmp,is_tmp && mainContract.userOf(avatarId)==address(0));	    
	}


    function validateMinting(address user,uint256 avatarId,string memory avatarUri,bytes memory signature,uint256[] memory traitIds,uint256[] memory layerIds) external  view {
        bytes32 msgHash = keccak256(
            abi.encodePacked("NewAvatar(",avatarId,avatarUri, traitIds,user,")")
        );
        require(Helpers._validSignature(signature, msgHash,serverAddress), "INVALID_SIGNATURE");
		require(!Helpers._hasDuplicate(traitIds) && !Helpers._hasDuplicate(layerIds),"You cannot own more than 1 trait per layer");
		require(Helpers._containsAllValues(traitContract.getBaseLayers(),layerIds),"Your Avatar does not contains all base traits"); 
            
    }



}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**

@title Structs.sol 
@notice This file contains all the data structures needed in the project.
@dev It manages multiple structs to handle various marketplace interactions.
*/
/**

@dev Struct representing an individual trait.
@param traitId The unique identifier for the trait.
@param layerId The unique identifier for the layer associated with the trait.
@param layerName The name of the layer associated with the trait.
*/
struct Trait {
    uint256 traitId;
    uint256 layerId;
    // string layerName;
}
/**

@dev Struct representing a rental order for a trait.
@param owner The address of the owner of the trait.
@param trait The unique identifier for the trait being rented.
@param price The rental price per ether.
@param expires The expiration timestamp for the rental offer.
@param data Additional order parameters for the rental offer.
*/
struct RentTrait {
    address owner;
    uint256 trait;
    uint256 price;
    uint64 expires;
    OrderParams data;
}
/**

@dev Struct representing a rental order for an avatar.
@param owner The address of the owner of the avatar.
@param avatarId The unique identifier for the avatar being rented.
@param price The rental price per ether.
@param expires The expiration timestamp for the rental offer.
*/
struct RentAvatar {
    address owner;
    uint256 avatarId;
    uint256 price;
    uint64 expires;
}
/**

@dev Struct representing a sell order for an avatar or a trait.
@param from The address of the seller.
@param itemId The unique identifier for the item being sold.
@param itemType The type of the item being sold (0 => avatar, 1 => trait).
@param price The selling price per ether.
@param data Additional order parameters for the sell order.
*/
struct SellOrder {
    address from;
    uint256 itemId;
    uint256 itemType;
    uint256 price;
    OrderParams data;
}
/**

@dev Struct representing a swap offer between two items.
@param from The address of the swapper.
@param item1 The first item involved in the swap.
@param item2 The second item involved in the swap.
@param itemType The type of the items being swapped (0 => avatar, 1 => trait).
*/
struct Swap {
    address from;
    AvatarTrait item1;
    AvatarTrait item2;
    uint256 itemType;
}
/**

@dev Struct representing an item applied to an avatar.
@param itemId The unique identifier for the trait or the avatar.
@param uri The new URI for the avatar after applying the item (if itemType = 1)..
@param avatarId The unique identifier for the avatar to which the trait is applied (if itemType = 1).
*/
struct AvatarTrait {
    uint256 itemId;
    string uri;
    uint256 avatarId;
}


/**

@dev Struct representing additional order parameters.
@param fromAvatar 
      - RentTrait : The identifier for the avatar that contains the trait being rented
      - SellOrder : The identifier for the avatar being sold or the ID of the avatar that contains the trait being sold.
@param toAvatar 
      - RentTrait : The identifier of the temporal avatar that will be created
      - SellOrder : the identifier of the avatar that will contain the bought trait, or null in case of itemType == 0.
@param fromUri The new URI for the fromAvatar after the order.
@param toUri The new URI for the toAvatar after the order.
*/

struct OrderParams {
    uint256 fromAvatar;
    uint256 toAvatar;
    string fromUri;
    string toUri;
}
/**

@dev Struct representing an avatar's URI data.
@param avatarUri The original URI of the avatar.
@param tmpUri The temporary URI of the avatar.
@param expires The expiration timestamp of the temporary URI.
*/

struct AvatarUri{
	string avatarUri;
	string tmpUri;
	uint64 expires;
}