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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

/////////////////////////////////////////////////////////////////
// KYL // THE WATCHMAKER BANK // TWM STAKING CONTRACT // 2022 //
///////////////////////////////////////////////////////////////
// producer: KYL WATCHES LTD // Instagram: @kylwatchesltd   //
/////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//    ___  _______  __  _______   _______  ___  __   __  _______          ///
//   |   ||       ||  ||       | |       ||   ||  |_|  ||       |        ///
//   |   ||_     _||__||  _____| |_     _||   ||       ||    ___|       ///
//   |   |  |   |      | |_____    |   |  |   ||       ||   |___       ///
//   |   |  |   |      |_____  |   |   |  |   ||       ||    ___|     ///
//   |   |  |   |       _____| |   |   |  |   || ||_|| ||   |___     ///
//   |___|  |___|      |_______|   |___|  |___||_|   |_||_______|   ///
//                                                                 ///
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  ///
//                                                                                 ./%@@@@@@@#,                    ///
//                                           .*(%&@@@@&&%%%##%%%&&@@@@%#*.    ,#@@&#/*,,.....,#@&,                ///
//                                     *%&@@&(*,.......................,*#@@@@#*******,%@@@@@@@@@@(              ///
//                                ,&@@&*.................................... (@@#,******,,,*/#@@@#              ///
//                            ,%@@#,............................................%@%*****/(//*,,..&&.           ///
//                         ,&@%*.,,,.............................................,%@#****//((#&@@@%.          ///
//                       (@&*,,,,,,,,..............................................,@&******,.../@&.         ///
//                     /@@,,,,,,,,,,,,...............................................%@(,/%#/,,..,%@,       ///
//      .*%@@@@&&&&%%%@@/,,,,,,,,,,,,,,,..............................................#@#,**#@@/,.*@@.     ///
//    (@@(,.........,&@*.,,,,,,,,,,,,,,,,............................(@(.............. (@(,**,&@,.,%@*    ///
//  .&@/..,/%&(.....#@/.,,,,,,,,,,,,,,,,,,.....................,(%@&/,..................#@(,**(@&.,%@*   ///
//  #@#&@@@@%,......&&,,,,,,,,,,,,,,,,,,,,,,.......... .*#@@@&(. ...............  .......&@/**(@@&*&@.  ///
// .#&(#@&,.../&#*,*@#.,,,,,,,,,,,,,,,,,,,,,,,*/#&@@&%(*..................,/%@@@@@(*.....,@&*,#@*/@&,  ///
//    %@*.,(@@#*,,.*@#.,,,,,,,,,.%&&&@@@&%%#/*,,......................*&@&#*...,@&#@&,..../@#*@%      ///
//    (@&@@%*******/@#.,,,,,,,,,,,,,,,,,,,,,,,,,....................#@&*.#@@@&/..,&@*......%@@&.      ///
//       @&****,(@@*&&.,,,,,,,,,,,,,,,,,,,,,,,,,,..................%@*.,&@@@@@@@@@@@@%* ...(@/        ///
//      [email protected]&****@@/,.#@*.,,,,,,,,,,,,,,,,,,,,,,,,,,..............*@@%*(@@@@@@@@&&&&&@@@@@@&*,&@,       ///
//       %@/**/@@*,./@%.,,,,/%&@@@@&%%%&&@@&/,,.,,..............&&(@@@@@%@@####%##(((((%@@@@@@%.      ///
//        &@**,#@#,.,%@*.,,*%@@%************#@@@@#,............,&@@@@#(#&@@@&%###%@@@@#(((&@@@@(      ///
//        .%@#,/@@%,*(@%,,,%@@/,**,,/%@@@@@@@@@&#&@#.......... #@@@#(%@@%*/%@@@@@@&(/#@@%((#@@@@.     ///
//          ,@&/@&&@#*%@(,,,./@&&@@@@@@@&&@&&&@@@@@@@(......../@@@((&@&/%@@@@@@@*     *%@&(((@@@&     ///
//            .((. .%@&@@*,,,#@@@@#/%*,,,*@(.,,,#/*%@@@&,.....%@@%(%@@/&@@@@@@@@(.  ,%&/&@%((&@@@*    ///
//                    .(@@*/@@@&,,,,,&#.,,(*..*@/.,,,*@@@#....(@@&(%@&/@@@@@@@@@@@@@@@@/&@#((@@@@%    ///
//                      *@@@@@#%@%,.,,,,,,,,,,,,.. /@@/@@@%%@@@@@@%(&@%%@@@@@@@@@@@@@@/&@&((&@@@@&    ///
//                       #@@@(.,,.,,,,.,,,*(%&%/, .    ,@@@&#/,.#@@&(&@@#&@@@@@@@@@@#%@@#((@@@&/@&    ///
//                       %@@&.***,*##(*.&@@@@&,    ,,,,,@@@,.....*@@@&(#@@@&&&%%&&@@@&((#@@@@/.(@(    ///
//                       &@@@.          #@/*. ..       *@@&........,%@@@&#(((####(((#&@@@@&*..,&@.    ///
//                       (@@@*    (,   @%         #,   %@@(............%@@@@@@@@@@@@@@@#......(@/     ///
//                        #@@@((#,    (,            (&@@@#,...........*#&@%,,*//**[email protected]%      ///
//                         *@@@@(   ,&*  .&*   %(  .#@@@&%*...............#@/./#&@@@&&@@@&%/,%@*      ///
//                           .&@@@@&%,   [email protected]/   .#@@@@@#@@,,,.............,%@@%/,...%@%/...,*(%@@@&#*  ///
//                             /@@@@@@@@@@@@@@@@@@&*.,#@*.,,............(@%.,,&@/...../&@@@(.,#@@@(   ///
//                               /@&*..,*****,..,*(#%&&@@@&(*.........(@@*.....*&@#...,#@@(&@%,       ///
//                                 /@@/.,,,,*%@@%(/,...,,.,*#&@@@@@@@&(,.........*&@&&&/../@(         ///
//                                   ,&@%,(@@(,#@#,*,&@/*,**,................,(&@@(......,@&.         ///
//                                      %@@*,(@&/**,#@#*****,..,,,.*,.....#@@&* .........&@*         ////
//                                   .%@%**/@@%//**#@@%(*********//((#&@@%*..*,.........#@(         /////
//                                [email protected]@@@@@@@&%@@#(#(,.,/%%%%###((/**,.....,(@%,....... (@/          //////
//                                             *@@(,,,,,,,,,,,,,(@&&&&@@@#/...........%@/         ///////
//                                                %@@,.,,,,,,,,,,,,,,,,,........... /@@.         ////////
//                                                  *&@%,,,,,,,,,,,,,,.........,/&@@#.          /////////
//                                                     ,%@&(,........,,*/#%@@@%(,              //////////
//                                                         *%@@@@@@@&%(*,.                    ///////////
//                                                                                           ////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       ////////
//  ████████╗██╗  ██╗███████╗    ██╗    ██╗ █████╗ ████████╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗       ///
//  ╚══██╔══╝██║  ██║██╔════╝    ██║    ██║██╔══██╗╚══██╔══╝██╔════╝██║  ██║████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗     ///
//     ██║   ███████║█████╗      ██║ █╗ ██║███████║   ██║   ██║     ███████║██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝    ///
//     ██║   ██╔══██║██╔══╝      ██║███╗██║██╔══██║   ██║   ██║     ██╔══██║██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗   ///
//     ██║   ██║  ██║███████╗    ╚███╔███╔╝██║  ██║   ██║   ╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║  ///
//     ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ///
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.7;

contract TWMStaking is Ownable, ReentrancyGuard {
    IERC721 public FirstCollection;
    IERC721 public SecondCollection;
    IERC721 public ThirdCollection;

    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;

    IERC20 public rewardToken;

    address public signerAddress;
    address[] public authorisedLog;

    bool public stakingLaunched;
    bool public depositPaused;

    struct Staker {
        uint256 currentYield;
        uint256 accumulatedAmount;
        uint256 lastCheckpoint;
        uint256[] stakedFIRST;
        uint256[] stakedSECOND;
        uint256[] stakedTHIRD;
    }

    enum ContractTypes {
        FIRSTCOL,
        SECONDCOL,
        THIRDCOL
    }

    mapping(address => uint256) public _baseRates;
    mapping(address => Staker) private _stakers;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;
    mapping(address => ContractTypes) private _contractTypes;
    mapping(address => mapping(uint256 => uint256)) private _tokensMultiplier;
    mapping(address => bool) private _authorised;
    mapping(uint8 => uint256) public _depositReward;

    event Deposit(
        address indexed staker,
        address contractAddress,
        uint256 tokensAmount
    );
    event Withdraw(
        address indexed staker,
        address contractAddress,
        uint256 tokensAmount
    );
    event WithdrawStuckERC721(
        address indexed receiver, 
        address indexed tokenAddress, 
        uint256 indexed tokenId
    );

    constructor(address _twm, address _rewardToken, address _signer) {
        FirstCollection = IERC721(_twm);
        _contractTypes[_twm] = ContractTypes.FIRSTCOL;
        rewardToken = IERC20(_rewardToken);
        _baseRates[_twm] = 50 ether;
        signerAddress = _signer;
    }

    modifier authorised() {
        require(
            _authorised[_msgSender()],
            "The token contract is not authorised"
        );
        _;
    }

    function deposit(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenTraits,
        bytes calldata signature
    ) public nonReentrant {
        require(!depositPaused, "Deposit paused");
        require(stakingLaunched, "Staking is not launched yet");
        require(
            contractAddress != address(0) &&
            contractAddress == address(FirstCollection)
            || contractAddress == address(SecondCollection)
            || contractAddress == address(ThirdCollection),
            "Unknown contract"
        );
        ContractTypes contractType = _contractTypes[contractAddress];

        if (tokenTraits.length > 0) {
            require(
                _validateSignature(
                    signature,
                    contractAddress,
                    tokenIds,
                    tokenTraits
                ),
                "Invalid data provided"
            );
            _setTokensValues(contractAddress, tokenIds, tokenTraits);
        }

        Staker storage user = _stakers[_msgSender()];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                IERC721(contractAddress).ownerOf(tokenIds[i]) == _msgSender(),
                "Not the owner"
            );
            IERC721(contractAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            _ownerOfToken[contractAddress][tokenIds[i]] = _msgSender();

            newYield += getTokenYield(contractAddress, tokenIds[i]);

            if (contractType == ContractTypes.FIRSTCOL) { user.stakedFIRST.push(tokenIds[i]); }
            if (contractType == ContractTypes.SECONDCOL) { user.stakedSECOND.push(tokenIds[i]); }
            if (contractType == ContractTypes.THIRDCOL) { user.stakedTHIRD.push(tokenIds[i]); }
        }

        accumulate(_msgSender());
        user.currentYield = newYield;

        emit Deposit(_msgSender(), contractAddress, tokenIds.length);
    }

    function withdraw(
        address contractAddress,
        uint256[] memory tokenIds
    ) public nonReentrant {
        require(
            contractAddress != address(0) &&
            contractAddress == address(FirstCollection)
            || contractAddress == address(SecondCollection)
            || contractAddress == address(ThirdCollection),
            "Unknown contract"
        );
        ContractTypes contractType = _contractTypes[contractAddress];
        Staker storage user = _stakers[_msgSender()];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                IERC721(contractAddress).ownerOf(tokenIds[i]) == address(this),
                "Not the owner"
            );

            _ownerOfToken[contractAddress][tokenIds[i]] = address(0);

            if (user.currentYield != 0) {
                uint256 tokenYield = getTokenYield(
                    contractAddress,
                    tokenIds[i]
                );
                newYield -= tokenYield;
            }

            if (contractType == ContractTypes.FIRSTCOL) {
                user.stakedFIRST = _moveTokenInTheList(
                    user.stakedFIRST,
                    tokenIds[i]
                );
                user.stakedFIRST.pop();
            }
            if (contractType == ContractTypes.SECONDCOL) {
                user.stakedSECOND = _moveTokenInTheList(
                    user.stakedSECOND,
                    tokenIds[i]
                );
                user.stakedSECOND.pop();
            }
            if (contractType == ContractTypes.THIRDCOL) {
                user.stakedTHIRD = _moveTokenInTheList(
                    user.stakedTHIRD,
                    tokenIds[i]
                );
                user.stakedTHIRD.pop();
            }

            IERC721(contractAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );
        }

        accumulate(_msgSender());
        user.currentYield = newYield;

        emit Withdraw(_msgSender(), contractAddress, tokenIds.length);
    }

    function claim(uint256 _amount) public nonReentrant {
        require(
            getAccumulatedAmount(_msgSender()) > 0 &&
            getAccumulatedAmount(_msgSender()) >= _amount,
            "Not enough token funds for claim"
        );
        require(
          IERC20(rewardToken).balanceOf(address(this)) >= _amount, "Not enough token funds in the contract"
        );
        IERC20(rewardToken).transfer(_msgSender(), _amount);
        accumulate(_msgSender());
        _stakers[_msgSender()].accumulatedAmount -= _amount;
    }

    function getAccumulatedAmount(
        address staker
    ) public view returns (uint256) {
        return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    function getTokenYield(
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 tokenYield = _tokensMultiplier[contractAddress][tokenId];
        if (tokenYield == 0) {
            tokenYield = _baseRates[contractAddress];
        }

        return tokenYield;
    }

    function getStakerYield(address staker) public view returns (uint256) {
        return _stakers[staker].currentYield;
    }

    function getStakerTokens(
        address staker
    ) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        return (_stakers[staker].stakedFIRST, _stakers[staker].stakedSECOND, _stakers[staker].stakedTHIRD);
    }

    function isMultiplierSet(
        address contractAddress,
        uint256 tokenId
    ) public view returns (bool) {
        return _tokensMultiplier[contractAddress][tokenId] > 0;
    }

    function _moveTokenInTheList(
        uint256[] memory list,
        uint256 tokenId
    ) internal pure returns (uint256[] memory) {
        uint256 tokenIndex = 0;
        uint256 lastTokenIndex = list.length - 1;
        uint256 length = list.length;

        for (uint256 i = 0; i < length; i++) {
            if (list[i] == tokenId) {
                tokenIndex = i + 1;
                break;
            }
        }
        require(tokenIndex != 0, "msg.sender is not the owner");

        tokenIndex -= 1;

        if (tokenIndex != lastTokenIndex) {
            list[tokenIndex] = list[lastTokenIndex];
            list[lastTokenIndex] = tokenId;
        }

        return list;
    }

    function _validateSignature(
        bytes calldata signature,
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenTraits
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(contractAddress, tokenIds, tokenTraits)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) &&
            receivedAddress == signerAddress);
    }

    function _setTokensValues(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenTraits
    ) internal {
        require(tokenIds.length == tokenTraits.length, "Wrong arrays provided");
        for (uint256 i; i < tokenIds.length; i++) {
            if (tokenTraits[i] != 0 && tokenTraits[i] <= 1000 ether) {
                _tokensMultiplier[contractAddress][tokenIds[i]] = tokenTraits[
                    i
                ];
            }
        }
    }

    function getCurrentReward(address staker) public view returns (uint256) {
        Staker memory user = _stakers[staker];
        if (user.lastCheckpoint == 0) {
            return 0;
        }
        return
            ((block.timestamp - user.lastCheckpoint) * user.currentYield) /
            SECONDS_IN_DAY;
    }

    function accumulate(address staker) internal {
        _stakers[staker].accumulatedAmount += getCurrentReward(staker);
        _stakers[staker].lastCheckpoint = block.timestamp;
    }

    /**
     * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
     */
    function ownerOf(
        address contractAddress,
        uint256 tokenId
    ) public view returns (address) {
        return _ownerOfToken[contractAddress][tokenId];
    }

    function setRewardTokenContract(address _rewardToken) public onlyOwner {
        rewardToken = IERC20(_rewardToken);
    }

    function setSecondContract(address _second, uint256 _baseReward) public onlyOwner {
        SecondCollection = IERC721(_second);
        _contractTypes[_second] = ContractTypes.SECONDCOL;
        _baseRates[_second] = _baseReward;
    }

    function setThirdContract(address _third, uint256 _baseReward) public onlyOwner {
        ThirdCollection = IERC721(_third);
        _contractTypes[_third] = ContractTypes.THIRDCOL;
        _baseRates[_third] = _baseReward;
    }

    /**
     * @dev Admin function to authorise the contract address
     */
    function authorise(address toAuth) public onlyOwner {
        _authorised[toAuth] = true;
        authorisedLog.push(toAuth);
    }

    /**
     * @dev Function allows admin add unauthorised address.
     */
    function unauthorise(address addressToUnAuth) public onlyOwner {
        _authorised[addressToUnAuth] = false;
    }

    /**
    * @dev Function allows admin withdraw ERC721 in case of emergency.
    */
    function emergencyWithdraw(address tokenAddress, uint256[] memory tokenIds) public onlyOwner {
      require(tokenIds.length <= 50, "50 is max per tx");
      pauseDeposit(true);
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = _ownerOfToken[tokenAddress][tokenIds[i]];
        if (receiver != address(0) && IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
          IERC721(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
          emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
        }
      }
    }

    function withdrawRewardToken(address tokenAddress) public onlyOwner {
        uint256 curBalance = IERC20(rewardToken).balanceOf(address(this));
        require(curBalance > 0, "Zero funds");
        IERC20(tokenAddress).transfer(_msgSender(), curBalance);
    }

    /**
     * @dev Function allows to pause deposits if needed. Withdraw remains active.
     */
    function pauseDeposit(bool _pause) public onlyOwner {
        depositPaused = _pause;
    }

    /**
     * @dev Function allows to pause deposits if needed. Withdraw remains active.
     */
    function updateSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    function launchStaking() public onlyOwner {
        require(!stakingLaunched, "Staking has been launched already");
        stakingLaunched = true;
    }

    function updateBaseYield(
        address _contract,
        uint256 _yield
    ) public onlyOwner {
        _baseRates[_contract] = _yield;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}