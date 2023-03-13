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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized and flexible operator filterer to abide to OpenSea's
/// mandatory on-chain royalty enforcement in order for new collections to
/// receive royalties.
/// For more information, see:
/// See: https://github.com/ProjectOpenSea/operator-filter-registry
abstract contract OperatorFilterer {
    /// @dev The default OpenSea operator blocklist subscription.
    address internal constant _DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev The OpenSea operator filter registry.
    address internal constant _OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev Registers the current contract to OpenSea's operator filter,
    /// and subscribe to the default OpenSea operator blocklist.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering() internal virtual {
        _registerForOperatorFiltering(_DEFAULT_SUBSCRIPTION, true);
    }

    /// @dev Registers the current contract to OpenSea's operator filter.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            let functionSelector := 0x7d3e3dbe // `registerAndSubscribe(address,address)`.

            // Clean the upper 96 bits of `subscriptionOrRegistrantToCopy` in case they are dirty.
            subscriptionOrRegistrantToCopy := shr(96, shl(96, subscriptionOrRegistrantToCopy))

            for {} iszero(subscribe) {} {
                if iszero(subscriptionOrRegistrantToCopy) {
                    functionSelector := 0x4420e486 // `register(address)`.
                    break
                }
                functionSelector := 0xa0af2903 // `registerAndCopyEntries(address,address)`.
                break
            }
            // Store the function selector.
            mstore(0x00, shl(224, functionSelector))
            // Store the `address(this)`.
            mstore(0x04, address())
            // Store the `subscriptionOrRegistrantToCopy`.
            mstore(0x24, subscriptionOrRegistrantToCopy)
            // Register into the registry.
            if iszero(call(gas(), _OPERATOR_FILTER_REGISTRY, 0, 0x00, 0x44, 0x00, 0x04)) {
                // If the function selector has not been overwritten,
                // it is an out-of-gas error.
                if eq(shr(224, mload(0x00)), functionSelector) {
                    // To prevent gas under-estimation.
                    revert(0, 0)
                }
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, because of Solidity's memory size limits.
            mstore(0x24, 0)
        }
    }

    /// @dev Modifier to guard a function and revert if the caller is a blocked operator.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            if (!_isPriorityOperator(msg.sender)) {
                if (_operatorFilteringEnabled()) _revertIfBlocked(msg.sender);
            }
        }
        _;
    }

    /// @dev Modifier to guard a function from approving a blocked operator..
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (!_isPriorityOperator(operator)) {
            if (_operatorFilteringEnabled()) _revertIfBlocked(operator);
        }
        _;
    }

    /// @dev Helper function that reverts if the `operator` is blocked by the registry.
    function _revertIfBlocked(address operator) private view {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `isOperatorAllowed(address,address)`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xc6171134001122334455)
            // Store the `address(this)`.
            mstore(0x1a, address())
            // Store the `operator`.
            mstore(0x3a, operator)

            // `isOperatorAllowed` always returns true if it does not revert.
            if iszero(staticcall(gas(), _OPERATOR_FILTER_REGISTRY, 0x16, 0x44, 0x00, 0x00)) {
                // Bubble up the revert if the staticcall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // We'll skip checking if `from` is inside the blacklist.
            // Even though that can block transferring out of wrapper contracts,
            // we don't want tokens to be stuck.

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev For deriving contracts to override, so that operator filtering
    /// can be turned on / off.
    /// Returns true by default.
    function _operatorFilteringEnabled() internal view virtual returns (bool) {
        return true;
    }

    /// @dev For deriving contracts to override, so that preferred marketplaces can
    /// skip operator filtering, helping users save gas.
    /// Returns false for all inputs by default.
    function _isPriorityOperator(address) internal view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Base is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{

    bool public operatorFilteringEnabled;

    error ZeroBalance();
    error FailToWithdraw();

    constructor(string memory name, string memory symbol) ERC721A (name, symbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% as BP.
        _setDefaultRoyalty(msg.sender, 500);
    }

    /**
     * @notice Withdraw all Eth funds
     */
    function withdrawAll() external onlyOwner {
        if (address(this).balance == 0) revert ZeroBalance();
        (bool sent, ) = owner().call{value: address(this).balance}("");
        if(!sent) revert FailToWithdraw();
    }

    /**
     * @notice Withdraw erc20 that pile up, if any
     * @param token - ERC20 token to withdraw
     */
    function withdrawAllERC20(IERC20 token) external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /**
     * @notice Global approval for given operator
     * @param operator - address of operator
     * @param approved - true | false
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Operator approval for a given tokenId
     * @param operator - address of operator
     * @param tokenId - tokenId to grant approval for
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Transfer token `from` `to`
     * @param from - address to transfer from
     * @param to - address to transfer to
     * @param tokenId - id of token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Safe transfer token `from` `to`
     * @param from - address to transfer from
     * @param to - address to transfer to
     * @param tokenId - id of token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Safe transfer token `from` `to`
     * @param from - address to transfer from
     * @param to - address to transfer to
     * @param tokenId - id of token to transfer
     * @param data - additional bytes data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Check that various interfaces are supported
     * @param interfaceId - id of interface to check
     * @return bool for support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @notice Set royalties for all tokens.
     * @param receiver - Address receiving royalties.
     * @param feeNumerator - Fee as Basis points.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set operator filtering on or off
     * @param value - desired state value
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * @notice Internally check operator filter state
     * @return state as boolean
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
     * @notice Internally check if operator is priority
     * @return priority as boolean
     */
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**======================================================================================
   .-'--`-._                           .-'--`-._                           .-'--`-._
   '-O---O--'                          '-O---O--'                          '-O---O--'
=========================================================================================

                    ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
                    ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
                    ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
                    ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
                    ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
                    ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░

                ░█████╗░░█████╗░░█████╗░░██████╗████████╗███████╗██████╗░
                ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
                ██║░░╚═╝██║░░██║███████║╚█████╗░░░░██║░░░█████╗░░██████╔╝
                ██║░░██╗██║░░██║██╔══██║░╚═══██╗░░░██║░░░██╔══╝░░██╔══██╗
                ╚█████╔╝╚█████╔╝██║░░██║██████╔╝░░░██║░░░███████╗██║░░██║
                ░╚════╝░░╚════╝░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

/*=========================================================================================
   .-'--`-._                           .-'--`-._                           .-'--`-._
   '-O---O--'                          '-O---O--'                          '-O---O--'
=========================================================================================*/

import "./Base.sol";
import "./lib/scripty/IScriptyBuilder.sol";
import "./lib/SmallSolady.sol";
import "./Thumbnail.sol";
import "./ICryptoCoaster.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Crypto Coaster
 * @author @xtremetom
 * @notice Experiment, 100% on-chain procedurally generated roller coaster
 * @dev No fancy mint mechanics, no promise of utility, no discord, just a code experiment
 *
 *      There are parts of this contract that could be optimized but I have deliberately
 *      tried to make things easy to read and understand
 *
 *      Huge thanks to 0xthedude, frolic, dhof, ****, CODENAME883, Mathcastles community,
 *      and everyone that helped with testing
 */
contract CryptoCoaster is Base {

    using BitMaps for BitMaps.BitMap;

    address public immutable _ethfsFileStorageAddress;
    address public immutable _scriptyStorageAddress;
    address public immutable _scriptyBuilderAddress;
    uint256 public immutable _supply;
    address public _thumbnailAddress;

    uint256 public _price = 0.025 ether;

    bool public _isOpen = false;

    // Address => Minted?
    BitMaps.BitMap _minted;

    address public _signer;
    address public constant _signatureDisabled =
    address(bytes20(keccak256("signatureDisabled")));

    error MintClosed();
    error ContractMinter();
    error SoldOut();
    error GreedyMinter();
    error InsufficientFunds();
    error WalletMax();
    error TokenDoesntExist();
    error InvalidSignature();

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        address ethfsFileStorageAddress,
        address scriptyStorageAddress,
        address scriptyBuilderAddress,
        address thumbnailAddress
    ) Base(name, symbol) {
        _ethfsFileStorageAddress = ethfsFileStorageAddress;
        _scriptyStorageAddress = scriptyStorageAddress;
        _scriptyBuilderAddress = scriptyBuilderAddress;
        _thumbnailAddress = thumbnailAddress;

        _supply = supply;

        // mint reserve of 20 for friends that helped
        // and a few giveaways
        _safeMint(msg.sender, 20, "");
    }

    /**
     * @notice Minting starts at token id #1
     * @return Token id to start minting at
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Retrieve how many tokens have been minted
     * @return Total number of minted tokens
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /*=========================================================================================
       .-'--`-._                            MINTING
       '-O---O--'                            LOGIC
    =========================================================================================*/

    /**
     * @notice Verify signature
     * @param sender - Address of sender
     * @param signature - Signature to verify
     */
    modifier validateSignature(address sender, bytes memory signature) {
        if (_signer != _signatureDisabled) {
            bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encode(sender));
            (address signer,) = ECDSA.tryRecover(messageHash, signature);
            if (signer != _signer) {
                revert InvalidSignature();
            }
        }
        _;
    }

    /**
     * @notice Mint those tokens
     * @dev No whitelist, just limit per wallet and signature verification
     * @param signature - Signature to verify
     */
    function mint(bytes memory signature)
        public payable
        validateSignature(msg.sender, signature)
    {
        if (!_isOpen) revert MintClosed();
        if (msg.sender != tx.origin) revert ContractMinter();
        if (_minted.get(uint160(msg.sender))) revert WalletMax();
        if (msg.value < _price) revert InsufficientFunds();
        unchecked {
            if (_totalMinted() + 1 > _supply) revert SoldOut();
        }

        _minted.set(uint160(msg.sender));
        _safeMint(msg.sender, 1, "");
    }

    /**
     * @notice Update the mint price.
     * @dev Very doubtful this gets used, but good to have
     * @param price - The new price.
     */
    function updateMintPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    /**
     * @notice Update thumbnail contract address
     * @param thumbnailAddress - Address of the thumbnail contract.
     */
    function setThumbnailAddress(address thumbnailAddress) external onlyOwner {
        if (_totalMinted() == _supply) revert SoldOut();
        _thumbnailAddress = thumbnailAddress;
    }

    /**
     * @notice Open or close minting
     * @param state - Boolean state for being open or closed.
     */
    function setMintStatus(bool state) external onlyOwner {
        _isOpen = state;
    }

    /**
     * @notice Set address of signer
     * @param signer - Address of new signer
     */
    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    /*=========================================================================================
       .-'--`-._                            METADATA
       '-O---O--'                            LOGIC
    =========================================================================================*/

    /**
     * @notice Build all the settings into a struct
     * @param tokenIdString - Value as string
     * @return settings - All settings as a struct
     */
    function buildSettings(string memory tokenIdString) internal view returns (Settings memory settings) {

        (uint256 seed, bytes memory varSeed) = genSeed(tokenIdString);
        settings.seed = seed;
        settings.vars[0] = varSeed;

        (bytes memory varSpeed, uint256 speed) = trackSpeed(seed);
        settings.speed = speed;
        settings.vars[1] = varSpeed;

        (bytes memory varScale, uint256 scale) = worldScale(seed >> 8);
        settings.scale = scale;
        settings.vars[2] = varScale;

        (bytes memory varColor, Color memory color) = trackColor(seed >> 16);
        settings.color = color;
        settings.vars[3] = varColor;

        (bytes memory varBiome, string memory biomeName, uint256 biomeIDX) = biome(seed >> 24);
        settings.biomeName = biomeName;
        settings.biomeIDX = biomeIDX;
        settings.vars[4] = varBiome;

        (bytes memory varFlip, uint256 flip) = trackOrientation(seed >> 32);
        settings.flip = flip;
        settings.vars[5] = varFlip;
    }

    /**
     * @notice Util function to generate hash
     * @param tokenIdString - Value as string
     * @return hash - as uint256
     */
    function createHash(string memory tokenIdString) internal view returns (uint256 hash) {
        return uint256(keccak256(abi.encodePacked("coaster", tokenIdString, address(this))));
    }

    /**
     * @notice Generate seed based on tag and track ID
     * @param tokenIdString - Track id as string
     * @return seed - final seed as uint56
     * @return varSeed - JS compatible declaration of seed
     */
    function genSeed(string memory tokenIdString) internal view returns (uint256 seed, bytes memory varSeed) {
        seed = createHash(tokenIdString);
        varSeed = abi.encodePacked(
            'var seed="', SmallSolady.toString(seed), '";'
        );
    }

    /**
     * @notice Determine the track speed setting
     * @param seed - Seed for a specific track
     * @return varSpeed - JS compatible declaration of track speed
     * @return speed - Speed setting a uint256
     */
    function trackSpeed(uint256 seed) internal pure returns (bytes memory varSpeed, uint256 speed) {
        uint256 r = seed % 100;
        speed = (r > 90) ? 2 : 1;
        varSpeed = abi.encodePacked(
            'var speed="', SmallSolady.toString(speed), '";'
        );
    }

    /**
     * @notice Determine the world scale setting
     * @param seed - Seed for a specific track
     * @return varScale - JS compatible declaration of world scale
     * @return scale - Scale setting a uint256
     */
    function worldScale(uint256 seed) internal pure returns (bytes memory varScale, uint256 scale) {
        uint256 r = seed % 100;
        scale = (r > 85) ? 2 : 1;
        varScale = abi.encodePacked(
            'var scale="', SmallSolady.toString(scale), '";'
        );
    }

    /**
     * @notice Pick track color based on seed
     * @param seed - Seed for a specific track
     * @return varColor - JS compatible declaration of track color
     * @return color - Color info struct
     */
    function trackColor(uint256 seed) internal pure returns (bytes memory varColor, Color memory color) {
        string[7] memory trackHexs = ["#2710cf","#cf10c4","#10cf27","#106acf","#cf3210","#cf0808","#cfcf10"];
        string[7] memory iconHexs = ["#9530eb", "#eb30d7","#23cc16","#169bcc","#f97316","#eb3030","#f0cb38"];
        string[7] memory names = ["Purple", "Pink", "Green", "Blue", "Orange", "Red", "Yellow"];

        uint256 r = seed % 7;
        color = Color(names[r], trackHexs[r], iconHexs[r]);

        varColor = abi.encodePacked(
            'var trackColor="', color.trackHex, '";'
        );
    }

    /**
     * @notice Gather biome data based on seed
     * @param seed - Seed for a specific track
     * @return varBiome - JS compatible declaration of biomeName
     * @return biomeName - Biome name as string
     * @return biomeIDX - array index for biome
     */
    function biome(uint256 seed) internal pure returns (bytes memory varBiome, string memory biomeName, uint256 biomeIDX) {
        string[3] memory biomes = ["Snow", "Forest", "Desert"];
        biomeIDX = seed % 3;
        biomeName = biomes[biomeIDX];
        varBiome = abi.encodePacked(
            'var biomeName="', biomeName, '";'
        );
    }

    /**
     * @notice Silly adjustment to track
     * @param seed - Seed for a specific track
     * @return varTrackOr - JS compatible declaration of track orientation
     * @return flip - 0 | 1 | 2 - normal | horiz |  vert
     */
    function trackOrientation(uint256 seed) internal pure returns (bytes memory varTrackOr, uint256 flip) {
        uint256 r = seed % 100;
        flip = 0;
        if (r == 0) flip = 2;
        else if (r > 95) flip = 1;
        varTrackOr = abi.encodePacked(
            'var flip="', SmallSolady.toString(flip) , '";'
        );
    }

    /**
     * @notice Util function to help build traits
     * @param key - Trait key as string
     * @param value - Trait value as string
     * @return trait - object as string
     */
    function buildTrait(string memory key, string memory value) internal pure returns (string memory trait) {
        return string.concat('{"trait_type":"', key, '","value": "', value, '"}');
    }

    /**
     * @notice Build attributes for metadata
     * @param settings - Track settings struct
     * @return attr - array as a string
     */
    function buildAttributes(Settings memory settings) internal pure returns (bytes memory attr) {
        // orientation
        string memory orientation = "Forward";
        if (settings.flip == 1) orientation = "Backward";
        else if (settings.flip == 2) orientation = "Upside down";

        // speed
        string memory speedString = "Normal";
        if (settings.speed == 2) speedString = "Fast";

        // world scale
        string memory scaleString = "Normal";
        if (settings.scale == 2) scaleString = "Big";

        return abi.encodePacked(
            '"attributes": [',
                buildTrait("Track Color", settings.color.name),
                ',',
                buildTrait("Biome", settings.biomeName),
                ',',
                buildTrait("Orientation", orientation),
                ',',
                buildTrait("Speed", speedString),
                ',',
                buildTrait("World Scale", scaleString),
            ']'
        );
    }

    /**
     * @notice Pack and base64 encode JS compatible vars
     * @param settings - Track settings struct
     * @return vars - base64 encoded JS compatible setting variables
     */
    function buildVars(Settings memory settings) internal pure returns (bytes memory vars){
        return bytes(
            SmallSolady.encode(
                abi.encodePacked(
                    settings.vars[0],
                    settings.vars[1],
                    settings.vars[2],
                    settings.vars[3],
                    settings.vars[4],
                    settings.vars[5]
                )
            )
        );
    }

    /**
     * @notice Use Scripty to generate the final html
     * @dev I opted for the lazy dev approach and let scripty calculate the required buffersize
     *      This could be calculated and passed to the contract at any point prior to its use
     *      in `getHTMLWrappedURLSafe`
     * @param requests - Array of WrappedScriptRequest data
     * @return html - as bytes
     */
    function buildAnimationURI(WrappedScriptRequest[] memory requests) internal view returns (bytes memory html) {
        IScriptyBuilder iScriptyBuilder = IScriptyBuilder(_scriptyBuilderAddress);
        uint256 bufferSize = iScriptyBuilder.getBufferSizeForURLSafeHTMLWrapped(requests);
        return iScriptyBuilder.getHTMLWrappedURLSafe(requests, bufferSize);
    }

    /**
     * @notice Build the metadata including the full render html for the coaster
     * @dev This depends on
     *      - https://ethfs.xyz/ [stores code libraries]
     *      - https://github.com/intartnft/scripty.sol [builds rendering html and stores code libraries]
     * @param tokenId - TokenId to build coaster for
     * @return metadata - as string
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory metadata) {

        // show nothing if token doesnt exist
        if (!_exists(tokenId)) revert TokenDoesntExist();

        string memory tokenIdString = SmallSolady.toString(tokenId);

        // Generate all the settings and various objects for the metadata
        Settings memory settings = buildSettings(tokenIdString);
        bytes memory attr = buildAttributes(settings);
        bytes memory vars = buildVars(settings);
        string memory thumbnail = SmallSolady.encode(
            Thumbnail(_thumbnailAddress).buildThumbnail(settings)
        );

        // To build the html I use Scripty to manage all the annoying tagging and html construction
        // A combination of EthFS and Scripty is used for storage and this array stores the required
        // code data
        WrappedScriptRequest[] memory requests = new WrappedScriptRequest[](7);

        // The order of steps is the order the code will appear in the final
        // rendering html injected into the metadata
        //
        // 1. - CSS + dom elements
        // 2. - setting JS variables
        // 3. - gzipped 3D models as JS variable
        // 4. - gzipped ThreeJS lib
        // 5. - gzipped Coaster bundle
        // 6. - gzip handler
        //
        // When the gzip handler runs it detects scripts with `text/javascript+gzip`
        // gunzips them and appends the raw code in this order:
        //
        // - ThreeJS [no dependencies]
        // - Coaster script bundle [depends on ThreeJS]
        //   |
        //   -- GLTFLoader [requires ThreeJS]
        //   -- BufferGeometryUtils [requires ThreeJS]
        //   -- Other scripts [requires ThreeJS + setting variables]
        //   -- Scenebuilder [requires ThreeJS + 3D models]
        //
        // 3D models are explicitly gunzipped and converted into `octet-stream`
        // allowing them to easily be loaded using the glb ThreeJS loader
        // More loaders are available:
        // https://github.com/mrdoob/three.js/tree/dev/examples/jsm/loaders
        // I used .glb files as an example, however other formats like SDF and colored STL
        // would be better suited in terms of storage cost
        //
        // [PREVENTING GAS OUT]
        // It is worth noting that for this piece I am using `getHTMLWrappedURLSafe` in `buildAnimationURI()`
        // above. This ensures the code is handled with urlencoding to make it URL safe vs base64 encoding. For a
        // codebase this big (threejs + models + scripts) base64 encoding within a contract would result in a gas
        // out.
        // However, I have tried to include an example of all `wrapTypes` below, one of which is a forced base64
        // encoding, for demo purposes.


        // Step 1.
        // - create custom content blocks that have no wrapper
        // - we do this to easily inject css and dom elements
        // - double urlencoded
        // - first block is css + some JS
        // - second block is coaster settings [biome + speed]
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L648
        // [double urlencoded data]

        requests[0].wrapType = 4;
        requests[0].scriptContent = "%253Cstyle%253Ebody%252Chtml%257Boverflow%253Ahidden%253Bmargin%253A0%253Bwidth%253A100%2525%253Bheight%253A100%2525%257D%2523overlay%257Bposition%253Aabsolute%253Bwidth%253A100vw%253Bheight%253A100vh%253Btransition%253A.75s%2520ease-out%253Bbackground-color%253A%2523e2e8f0%253Bdisplay%253Aflex%253Bflex-direction%253Acolumn%253Bjustify-content%253Acenter%253Balign-items%253Acenter%257D.bbg%257Bwidth%253A75%2525%253Bmargin%253A1rem%253Bbackground-color%253A%2523cbd5e1%253Bmax-width%253A400px%253Bborder-radius%253A2rem%253Bheight%253A.8rem%257D.bbar%257Bbackground-color%253A%25236366f1%253Bwidth%253A5%2525%253Bborder-radius%253A2rem%253Bheight%253A.8rem%257D%2523info%257Bfont-family%253ATahoma%252CArial%252CHelvetica%252Csans-serif%253Bfont-size%253A.8rem%253Bcolor%253A%2523475569%253Bmin-height%253A1rem%257D%2523controls%257Bposition%253Aabsolute%253Bbottom%253A20px%253Bleft%253A20px%257D%2523camber%257Bborder%253A1px%2520solid%2520%2523fff%253Bborder-radius%253A4px%253Bbackground%253Argba(0%252C0%252C0%252C.1)%253Bcolor%253A%2523dc2626%253Btext-align%253Acenter%253Bopacity%253A.5%253Boutline%253A0%253Bmouse%253Apointer%257D%2523camber.active%257Bbackground%253Argba(255%252C255%252C255%252C.5)%253Bcolor%253A%252316a34a%253Bopacity%253A1%257D%2523camber%2520svg%257Bwidth%253A36px%253Bheight%253A36px%257D%253C%252Fstyle%253E%253Cdiv%2520id%253D'overlay'%253E%253Cdiv%2520class%253D'bbg'%253E%253Cdiv%2520id%253D'bar'%2520class%253D'bbar'%253E%253C%252Fdiv%253E%253C%252Fdiv%253E%253Cdiv%2520id%253D'info'%253E%253C%252Fdiv%253E%253C%252Fdiv%253E%253Ccanvas%2520id%253D'coaster'%253E%253C%252Fcanvas%253E%253Cdiv%2520id%253D'controls'%253E%253Cbutton%2520id%253D'camber'%2520onclick%253D'toggleActive()'%253E%253Csvg%2520viewBox%253D'0%25200%252012.7%252012.7'%2520xmlns%253D'http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg'%253E%253Cg%2520style%253D'stroke%253AcurrentColor%253Bstroke-width%253A.6%253Bstroke-linecap%253Around%253Bfill%253Anone'%253E%253Crect%2520width%253D'4.217'%2520height%253D'4.217'%2520x%253D'4.257'%2520y%253D'5.388'%2520ry%253D'.31'%2520rx%253D'.31'%252F%253E%253Cpath%2520d%253D'm12.37%25206.919-.935%25201.16-1.145-1.025M.487%25206.919l.936%25201.16%25201.145-1.025'%2520transform%253D'matrix(.94246%25200%25200%2520.9392%2520.291%2520.21)'%252F%253E%253Cpath%2520d%253D'M-1.464-8.007a4.99%25205.036%25200%25200%25201-2.495%25204.36%25204.99%25205.036%25200%25200%25201-4.99%25200%25204.99%25205.036%25200%25200%25201-2.495-4.36'%2520transform%253D'matrix(-.94246%25200%25200%2520-.9392%2520.291%2520.21)'%252F%253E%253C%252Fg%253E%253C%252Fsvg%253E%253C%252Fbutton%253E%253C%252Fdiv%253E";

        // Step 2.
        // - wrap the JS variables in <script>
        // - no name is needed as we are injected the code rather than
        //   pulling it from a contract (scriptyStorage/EthFS)
        // - wrapType 1 w/ script content
        //
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L638
        // <script src="data:text/javascript;base64,[vars]"></script>

        requests[1].name = "";
        requests[1].wrapType = 1;
        requests[1].scriptContent = vars;

        // Ideally these settings would be included in the main bulk of the coaster
        // code, but to allow you to mess around with the coaster by creating your own
        // settings json, I have kept them separate
        //
        // [IMPORTANT]
        // Note how this code is not encoded in any way. The `wrapType 0` in combination with `getHTMLWrappedURLSafe`
        // from `buildAnimationURI()` results in the scriptContent being base64 encoded in Scripty
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L638
        // <script src="data:text/javascript;base64,[SCRIPT]"></script>

        requests[2].wrapType = 0;
        requests[2].scriptContent = 'const biomes={Snow:{sky:15987703,fog:14737632,ground:11526632,hemi:[14154495,13806982,.5],sun:[15127463,1,0,100,50],models:[["treePineSnowRound",200,2,7,1],["rockB",50,1,3,0,[["rock.001",5918017]]]]},Desert:{fog:15005690,sky:12446963,ground:10777144,hemi:[16770732,4142384,.605],sun:[16763989,1,0,100,50],models:[["palmDetailed",200,1,2.8,1],["grassLarge",50,1,3,0,[["foliage",4225055]]],["rockB",50,1,3,0]]},Forest:{fog:15005690,sky:12446963,ground:5535813,hemi:[16770732,4142384,.45],sun:[16763989,1,0,100,-50],models:[["treePine",250,3,8,1,[["leafsDark",1274191],["woodBarkDark",12606262]]],["grassLarge",50,1,3,0,[["foliage",4225055]]],["rockB",50,1,3,0,[["rock.001",5918017]]]]}};const data=biomes[biomeName];const speedSettings=[{acc:45e-5,dec:453e-6,max:.03,min:.004},{acc:3e-4,dec:305e-6,max:.03,min:.004}];';

        // Step 3.
        // - pull the gzipped 3D models from scriptyStorage
        //   I could have stored on EthFS, but wanted to show that pulling from
        //   another contract is possible.
        // - custom wrap to declare the data as a JS compatible variable
        // - wrapType 4 w/ script content and custom wraps
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L648
        // <script>var gzipModels="[coaster_models_v8]"</script>

        requests[3].name = "coaster_models_v8";
        requests[3].wrapType = 4;
        requests[3].wrapPrefix = "%253Cscript%253Evar%2520gzipModels%2520%253D%2522";
        requests[3].wrapSuffix = "%2522%253C%252Fscript%253E";
        requests[3].contractAddress = _scriptyStorageAddress;

        // Step 4.
        // - pull the gzipped threeJS lib from EthFS
        // - wrapType 2 will handle the gzip script wrappers
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L642
        // <script type="text/javascript+gzip" src="data:text/javascript;base64,[three-v0.147.0.min.js.gz]"></script>

        requests[4].name = "three-v0.147.0.min.js.gz";
        requests[4].wrapType = 2;
        requests[4].contractAddress = _ethfsFileStorageAddress;

        // Step 5.
        // - pull the coaster code from scriptyStorage
        //   I could have stored on EthFS, but wanted to show that pulling from
        //   another contract is possible.
        // - wrapType 2 will handle the gzip script wrappers
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L642
        // <script type="text/javascript+gzip" src="data:text/javascript;base64,[cryptoCoaster.min.js.gz]"></script>

        requests[5].name = "cryptoCoaster.min.js.gz_v2";
        requests[5].wrapType = 2;
        requests[5].contractAddress = _scriptyStorageAddress;

        // Step 6.
        // - pull the gunzip handler from EthFS
        // - wrapType 1 will handle the script tags
        //
        // Final Output:
        // https://github.com/intartnft/scripty.sol/blob/main/contracts/scripty/ScriptyBuilder.sol#L638
        // <script src="data:text/javascript;base64,[gunzipScripts-0.0.1.js]"></script>

        requests[6].name = "gunzipScripts-0.0.1.js";
        requests[6].wrapType = 1;
        requests[6].contractAddress = _ethfsFileStorageAddress;

        bytes memory json = abi.encodePacked(
            '{"name":"',
            'Track: #',
            tokenIdString,
            '", "description":"',
            'Crypto Coaster is an experiment to see just how far we can push on-chain NFTs. All the models and code are compressed then stored, and retrieved from the blockchain.',
            '","image":"data:image/svg+xml;base64,',
            thumbnail,
            '","animation_url":"',
            buildAnimationURI(requests),
            '",',
            attr,
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json,",
                json
            )
        );
    }

    /*=========================================================================================
       .-'--`-._                             GETTER
       '-O---O--'                            LOGIC
    =========================================================================================*/

    /**
     * @notice Grab settings for given Id
     * @dev Can do fun stuff with settings in the future :)
     *      On the minting app we use this to grab the settings and create each coaster without having
     *      to call tokenURI()
     * @param tokenId - Id of chosen token
     * @return settings - All settings as a struct
     */
    function getSettings(uint256 tokenId) public view returns (Settings memory settings) {
        if (!_exists(tokenId)) return settings;
        return buildSettings(SmallSolady.toString(tokenId));
    }
}
/**======================================================================================
   .-'--`-._                           .-'--`-._                           .-'--`-._
   '-O---O--'                          '-O---O--'                          '-O---O--'
=========================================================================================*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Settings {
    uint256 seed;
    uint256 biomeIDX;
    string biomeName;
//    uint256 color;
//    string colorHex;
//    string colorName;
    Color color;
    uint256 scale;
    uint256 speed;
    uint256 flip;
    bytes[6] vars;
}

struct Color {
    string name;
    string trackHex;
    string iconHex;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

// =============================================================
//                            STRUCTS
// =============================================================

struct WrappedScriptRequest {
    string name;
    address contractAddress;
    bytes contractData;
    uint8 wrapType;
    bytes wrapPrefix;
    bytes wrapSuffix;
    bytes scriptContent;
}

struct InlineScriptRequest {
    string name;
    address contractAddress;
    bytes contractData;
    bytes scriptContent;
}

interface IScriptyBuilder {

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @notice Error for, Invalid length of requests
     */
    error InvalidRequestsLength();

    // =============================================================
    //                      RAW HTML GETTERS
    // =============================================================

    /**
     * @notice Get requested scripts housed in <body> with custom wrappers
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get requested scripts housed in URL Safe wrappers
     * @dev Any wrapper type 0 scripts are converted to base64 and wrapped
     *      with <script src="data:text/javascript;base64,[SCRIPT]"></script>
     *
     *      [WARNING]: Large non-base64 libraries that need base64 encoding
     *      carry a high risk of causing a gas out. Highly advised to use
     *      base64 encoded scripts where possible
     *
     *      Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              [wrapPrefix[0]]{request[0]}[wrapSuffix[0]]
     *              [wrapPrefix[1]]{request[1]}[wrapSuffix[1]]
     *              ...
     *              [wrapPrefix[n]]{request[n]}[wrapSuffix[n]]
     *          </body>
     *      </html>
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full URL Safe wrapped scripts
     */
    function getHTMLWrappedURLSafe(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get requested scripts housed in <body> all wrapped in <script></script>
     * @dev Your requested scripts are returned in the following format:
     *      <html>
     *          <head></head>
     *          <body style='margin:0;'>
     *              <script>
     *                  {request[0]}
     *                  {request[1]}
     *                  ...
     *                  {request[n]}
     *              </script>
     *          </body>
     *      </html>
     * @param requests - Array of InlineScriptRequest
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts
     */
    function getHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    // =============================================================
    //                      ENCODED HTML GETTERS
    // =============================================================

    /**
     * @notice Get {getHTMLWrapped} and base64 encode it
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    /**
     * @notice Get {getHTMLInline} and base64 encode it
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return Full html wrapped scripts, base64 encoded
     */
    function getEncodedHTMLInline(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (bytes memory);

    // =============================================================
    //                      STRING UTILITIES
    // =============================================================

    /**
     * @notice Convert {getHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLWrapped} as a string
     */
    function getHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     * @return {getHTMLInline} as a string
     */
    function getHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getEncodedHTMLWrapped} output to a string
     * @param requests - Array of WrappedScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     *                     before encoding.
     * @return {getEncodedHTMLWrapped} as a string
     */
    function getEncodedHTMLWrappedString(
        WrappedScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    /**
     * @notice Convert {getEncodedHTMLInline} output to a string
     * @param requests - Array of InlineScriptRequests
     * @param bufferSize - Total buffer size of all requested scripts
     *                     before encoding.
     * @return {getEncodedHTMLInline} as a string
     */
    function getEncodedHTMLInlineString(
        InlineScriptRequest[] calldata requests,
        uint256 bufferSize
    ) external view returns (string memory);

    // =============================================================
    //                      OFF-CHAIN UTILITIES
    // =============================================================

    /**
     * @notice Get the buffer size of a single inline requested code
     * @param request - InlineScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getInlineScriptSize(InlineScriptRequest memory request)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getWrappedScriptSize(WrappedScriptRequest memory request)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of a single wrapped requested code
     * @dev If the script is of wrapper type 0, we get buffer size for
     *      base64 encoded version.
     * @param request - WrappedScriptRequest data for code
     * @return Buffer size as an unit256
     */
    function getURLSafeWrappedScriptSize(WrappedScriptRequest memory request)
    external
    view
    returns (uint256);

    /**
     * @notice Get the buffer size of an array of html wrapped inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLInline(InlineScriptRequest[] calldata requests)
        external
        view
        returns (uint256);

    /**
     * @notice Get the buffer size of an array of html wrapped, wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);

    /**
     * @notice Get the buffer size of an array of URL safe html wrapped scripts
     * @param requests - WrappedScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForURLSafeHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);
    
    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLInline(
        InlineScriptRequest[] calldata requests
    ) external view returns (uint256);

    /**
     * @notice Get the buffer size for encoded HTML inline scripts
     * @param requests - InlineScriptRequests data for code
     * @return Buffer size as an unit256
     */
    function getBufferSizeForEncodedHTMLWrapped(
        WrappedScriptRequest[] calldata requests
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Library created from cherry picked parts of Solady
/// @author Solady (https://github.com/vectorized/solady/blob/main/src)
library SmallSolady {

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, add(str, 0x20))
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for { let temp := value } 1 {} {
                str := add(str, w) // `sub(str, 1)`.
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
    internal
    pure
    returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoCoaster.sol";

contract Thumbnail {

    bytes constant BASE = '<path class="l1" d="M.006 0h511.993v383.997H.002C-.006 263.19.006 0 .006 0Z"/><path class="l2" d="M512 229.868s-68.63 47.607-139.47 44.655c-70.842-2.952-146.81-30.585-146.81-30.585s-106.132-43.602-151.091-43.431C29.669 200.677 0 215.187 0 215.187v230.136h512z"/><path class="l3" d="M147.137 117.002c-50.043.204-93.869 28.627-98.075 75.914v158.74l417.184 16.867s-2.445-95.713-4.414-113.525c-1.968-17.812-15.591-40.98-51.71-41.324-28.638-.273-61.043 19.505-78.653 27.137-.753-.352-20.145-16.8-42.336-39.014-22.856-22.878-32.808-36.846-52.028-52.137-17.91-14.25-47.157-32.92-89.968-32.658zm3.408 16.95c1.298-.014 2.408-.006 3.3.01 14.278.27 43.839 4.066 68.817 25.388 15.679 13.383 20.343 17.772 48.813 46.607 23.333 23.633 44.779 44.23 44.779 44.23s-59.769 36.223-141.61 33.338c-21.365-.753-53.836-6.784-77.302-26.586-12.04-10.16-35.255-32.383-33.112-57.83 5.031-59.724 66.844-64.958 86.315-65.158z"/><path class="l4" d="M0 296.545s68.63 47.607 139.47 44.655c70.842-2.953 146.81-30.585 146.81-30.585s106.132-43.602 151.091-43.432c44.96.17 74.629 14.681 74.629 14.681V512H0Z"/><path class="l3" d="M157.625 128.372h6.743v157.647h-6.743z"/><path class="l3" d="M175.378 129.993h6.743V287.64h-6.743z"/><path class="l3" d="M193.131 134.176h6.743v157.647h-6.743z"/><path class="l3" d="M210.878 147.926h6.743v141.647h-6.743z"/><path class="l3" d="M228.628 160.176h6.743v123.513h-6.743z"/><path class="l3" d="M246.378 177.744h6.743v105.945h-6.743z"/><path class="l3" d="M264.128 194.789h6.743v83.195h-6.743z"/><path class="l3" d="M281.878 213h6.743v59.523h-6.743z"/><path class="l3" d="M299.628 228.239h6.743v38.944h-6.743z"/><path class="l3" d="M68.878 157.542h6.743v83.05h-6.743z"/><path class="l3" d="M86.628 143.975h6.743v123.208h-6.743z"/><path class="l3" d="M104.378 137.463h6.743v136.232h-6.743z"/><path class="l3" d="M122.128 130.951h6.743v149.257h-6.743z"/><path class="l3" d="M139.878 128.372h6.743v155.317h-6.743z"/>';

    bytes constant SUN = '<circle cx="448.545" cy="71.741" r="38.217" style="fill:#fff"/>';

    bytes constant SNOW = '<style>.sn{fill:#fff}</style><circle class="sn" cx="208.174" cy="102.449" r="4.848"/><circle class="sn" cx="125.499" cy="36.538" r="4.848"/><circle class="sn" cx="73.118" cy="90.464" r="7.136"/><circle class="sn" cx="349.836" cy="125.563" r="5.992"/><circle class="sn" cx="428.432" cy="26.94" r="5.992"/><circle class="sn" cx="390.254" cy="92.982" r="4.619"/><circle class="sn" cx="483.828" cy="190.385" r="4.619"/><circle class="sn" cx="473.288" cy="114.821" r="4.619"/><circle class="sn" cx="337.348" cy="226.96" r="5.992"/><circle class="sn" cx="63.308" cy="206.578" r="11.942"/><circle class="sn" cx="257.836" cy="74.299" r="5.077"/><circle class="sn" cx="288.372" cy="139.537" r="5.077"/><circle class="sn" cx="207.259" cy="16.399" r="4.848"/><circle class="sn" cx="168.013" cy="68.994" r="7.365"/><circle class="sn" cx="452.046" cy="69.223" r="7.594"/><circle class="sn" cx="417.821" cy="170.136" r="4.619"/><circle class="sn" cx="102.541" cy="304.314" r="4.619"/><circle class="sn" cx="200.622" cy="139.295" r="5.077"/><circle class="sn" cx="50.95" cy="162.409" r="7.594"/><circle class="sn" cx="257.149" cy="289.195" r="5.534"/><circle class="sn" cx="406.92" cy="226.045" r="5.534"/><circle class="sn" cx="462.303" cy="217.806" r="5.534"/><circle class="sn" cx="324.433" cy="36.538" r="7.136"/><circle class="sn" cx="350.98" cy="174.755" r="7.136"/><circle class="sn" cx="126.472" cy="257.613" r="6.221"/><circle class="sn" cx="46.602" cy="42.717" r="11.942"/><circle class="sn" cx="24.424" cy="256" r="7.365"/>';

    bytes constant TREES = '<path style="fill:#97ad89" d="m473.282 208.809-3.703 21.978-3.708 21.983 2.767-.624-2.256 17.652a145.48 145.48 0 0 1 15.029 2.759l-2.895-22.644 4.081-.922-4.656-20.093zm-441.281 3.439L24.957 268.1l-5.144 40.794a82.398 82.398 0 0 0 4.218 2.275c3.654 1.814 7.361 3.515 10.959 5.435a100.553 100.553 0 0 0 6.25 3.057c1.512.68 3.031 1.33 4.558 1.976l-6.753-53.537z"/><path style="fill:#c6e9af" d="m491.066 193.394-6.209 25.508-6.205 25.509 5.608 1.209-.317 1.738-4.88 26.48a150.01 150.01 0 0 1 12.558 3.242c3.96 1.213 7.868 2.592 11.693 4.195 2.645 1.107 7.218 2.902 8.446 3.386l-2.067-18.117-3.851-33.81-3.855 33.81-.786 6.916-4.64-25.191 4.38.945-4.94-27.912zm-470.913 34.6L11.3 257.086l-8.865 29.091 6.764.688L6.1 302.758c2.887 1.739 5.775 3.48 8.688 5.181 3.065 1.792 6.103 3.658 9.285 5.23 2.256 1.12 4.524 2.207 6.78 3.315l-5.457-27.972 3.522.355-4.38-30.436zm24.488 40.38-7.41 37.993-2.37 12.142.19.095a98.76 98.76 0 0 0 6.261 3.057c2.951 1.323 5.948 2.547 8.926 3.817 3 1.194 4.667 1.87 6.012 2.392l-4.194-21.503zm468.218 25.969-.004 6.008h.692z"/>';

    bytes constant SINGLE_CHEVERON = '<path class="l2" d="M8.487 0A8.487 8.487 0 0 0 0 8.487a8.487 8.487 0 0 0 8.487 8.488 8.487 8.487 0 0 0 8.488-8.488A8.487 8.487 0 0 0 8.487 0zm0 5.095c.114 0 .212.041.295.124l4.865 4.858a.407.407 0 0 1 .125.299.407.407 0 0 1-.125.298l-1.088 1.081a.404.404 0 0 1-.295.125.404.404 0 0 1-.295-.125l-3.482-3.48-3.48 3.48a.404.404 0 0 1-.296.125.404.404 0 0 1-.295-.125l-1.088-1.081a.407.407 0 0 1-.125-.298c0-.116.042-.216.125-.299L8.192 5.22a.403.403 0 0 1 .295-.124z"/>';

    bytes constant DOUBLE_CHEVERON = '<path class="l2" d="M0 8.487A8.487 8.487 0 0 0-8.487 0a8.487 8.487 0 0 0-8.488 8.487 8.487 8.487 0 0 0 8.488 8.488A8.487 8.487 0 0 0 0 8.487zm-3.664 0c0 .09-.033.167-.098.232l-3.816 3.821a.32.32 0 0 1-.234.098.32.32 0 0 1-.235-.098l-.85-.855a.316.316 0 0 1-.097-.231c0-.09.033-.167.098-.232l2.735-2.735-2.735-2.734a.316.316 0 0 1-.098-.231c0-.09.033-.167.098-.232l.85-.855a.32.32 0 0 1 .234-.098c.091 0 .169.033.234.098l3.816 3.82a.316.316 0 0 1 .098.232zm-4.317 0c0 .09-.033.167-.098.232l-3.816 3.821a.32.32 0 0 1-.234.098.319.319 0 0 1-.234-.098l-.85-.855a.316.316 0 0 1-.098-.231c0-.09.033-.167.098-.232l2.735-2.735-2.735-2.734a.316.316 0 0 1-.098-.231c0-.09.033-.167.098-.232l.85-.855a.319.319 0 0 1 .234-.098c.091 0 .169.033.234.098l3.816 3.82a.317.317 0 0 1 .098.232z" transform="rotate(-90)"/>';

    bytes constant FACING = '<path class="l2" d="M8.487 0A8.487 8.487 0 0 0 0 8.487a8.487 8.487 0 0 0 8.487 8.488 8.487 8.487 0 0 0 8.488-8.488A8.487 8.487 0 0 0 8.487 0zm1.48 4.337c.092 0 .17.033.235.098l3.816 3.82a.316.316 0 0 1 .097.232c0 .09-.032.167-.097.232l-3.816 3.821a.32.32 0 0 1-.234.098.32.32 0 0 1-.235-.098l-.85-.855a.316.316 0 0 1-.097-.231c0-.09.032-.167.098-.232l2.734-2.735-2.734-2.734a.316.316 0 0 1-.098-.231c0-.09.032-.167.098-.232l.85-.855a.32.32 0 0 1 .234-.098zm-4.579.9a1.445 1.445 0 0 1 0 2.89A1.445 1.445 0 0 1 3.943 6.68a1.445 1.445 0 0 1 1.445-1.445zm0 3.612a2.529 2.529 0 0 1 2.529 2.529.361.361 0 0 1-.361.36H3.22a.361.361 0 0 1-.36-.36 2.529 2.529 0 0 1 2.528-2.529z"/>';

    bytes constant WANG = '<path class="l2" d="M348.918 441.374a32.079 32.079 0 0 0-32.079 32.078 32.079 32.079 0 0 0 32.079 32.08 32.079 32.079 0 0 0 32.08-32.08 32.079 32.079 0 0 0-32.08-32.078zm-12.29 13.642h24.58a2.048 2.048 0 0 1 2.05 2.05 14.339 14.339 0 0 1-28.678 0 2.048 2.048 0 0 1 2.049-2.05zm12.29 20.485a8.193 8.193 0 0 1 8.193 8.193 8.193 8.193 0 1 1-8.193-8.193z" transform="matrix(.26458 0 0 .26458 -83.83 -116.78)"/>';

    bytes constant TRACK = '<path class="trackColor" d="M8.487 0A8.487 8.487 0 0 0 0 8.487a8.487 8.487 0 0 0 8.487 8.488 8.487 8.487 0 0 0 8.488-8.488A8.487 8.487 0 0 0 8.487 0zM5.188 3.312h1.5a.44.44 0 0 1 .442.441v.307h2.715v-.307a.44.44 0 0 1 .441-.441h1.5a.44.44 0 0 1 .442.441v9.468a.44.44 0 0 1-.441.442h-1.5a.44.44 0 0 1-.442-.442v-.367H7.13v.367a.44.44 0 0 1-.442.442h-1.5a.44.44 0 0 1-.441-.442V3.753a.44.44 0 0 1 .441-.441zm1.942 2.1V6.54h2.715V5.413H7.13zm0 2.481V9.02h2.715V7.893H7.13zm0 2.48v1.128h2.715v-1.127H7.13z"/>';

    /**
     * @dev Array order
     *      0. Snow
     *      1. Forest
     *      2. Desert
     */
    string[3] STYLES = [
        '<style>.l1{fill:#d9eaf1}.l2{fill:#8b9a9f}.l3{fill:#bfd3da}.l4{fill:#ffffff}</style>',
        '<style>.l1{fill:#f2fee8}.l2{fill:#615f60}.l3{fill:#9bac8c}.l4{fill:#cce8b5}</style>',
        '<style>.l1{fill:#fea}.l2{fill:#ffc460}.l3{fill:#cca066}.l4{fill:#ffffda}</style>'
    ];

    /**
     * @notice Build the SVG thumbnail
     * @param settings - Track settings struct
     * @return final svg as bytes
     */
    function buildThumbnail(Settings calldata settings) external view returns(bytes memory) {

        // Default to SNOW
        bytes memory biomeExtra = SNOW;
        if (settings.biomeIDX == 1) biomeExtra = TREES;
        else if (settings.biomeIDX == 2) biomeExtra = SUN;

        return abi.encodePacked(
            '<svg preserveAspectRatio="xMidYMid meet" width="100%" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">',
            STYLES[settings.biomeIDX],
            BASE,
            biomeExtra,
            addIcons(settings),
            '</svg>'
        );
    }

    /**
     * @notice Pack att the icons into SVGs
     * @param settings - Track settings struct
     * @return icons as bytes
     */
    function addIcons(Settings memory settings) internal pure returns(bytes memory) {
        return abi.encodePacked(
            '<svg x="20px" y="446"><g transform="scale(3, 3)">',
            '<svg x="0">', buildSize(settings.scale), '</svg>',
            '<svg x="20">', buildTrackColor(settings.color.iconHex), '</svg>',
            '<svg x="40">', buildSpeed(settings.speed), '</svg>',
            '<svg x="60">', buildFacing(settings.flip), '</svg>',
            '</g></svg>'
        );
    }

    /**
     * @notice Handle track color styling for SVG
     * @param colorHex - Color settings
     * @return track color icon path with styling as bytes
     */
    function buildTrackColor(string memory colorHex) internal pure returns(bytes memory) {
        return abi.encodePacked(
            '<style>.trackColor{fill:', colorHex, '}</style>',
            TRACK
        );
    }

    /**
     * @notice Handle train orientation styling for SVG
     * @param flip - Train orientation settings
     * @return train orientation icon path with styling as bytes
     */
    function buildFacing(uint256 flip) internal pure returns(bytes memory) {
        if (flip == 1) {
            return abi.encodePacked(
                '<g transform="scale(-1,1) translate(-16.975,0)">',
                FACING,
                '</g>'
            );
        }

        if (flip == 2) return WANG;

        return FACING;
    }

    /**
     * @notice Handle world scale styling for SVG
     * @param scale - Scale settings
     * @return world scale icon path with styling as bytes
     */
    function buildSize(uint256 scale) internal pure returns(bytes memory) {
        return (scale == 1) ? SINGLE_CHEVERON : DOUBLE_CHEVERON;
    }

    /**
     * @notice Handle train speed styling for SVG
     * @param speed - Speed settings
     * @return train speed icon path with styling as bytes
     */
    function buildSpeed(uint256 speed) internal pure returns(bytes memory) {
        bytes memory icon = (speed == 1) ? SINGLE_CHEVERON : DOUBLE_CHEVERON;
        return abi.encodePacked(
            '<g transform="rotate(90 8.4875 8.4875)">',
            icon,
            '</g>'
        );
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721ABurnable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721ABurnable.
 *
 * @dev ERC721A token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is ERC721A, IERC721ABurnable {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721ABurnable.
 */
interface IERC721ABurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}