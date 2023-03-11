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
     * @dev Sets `amount` as the allowance of `spender` over the caller's
     * tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the
     * risk
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId`
     * token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to
     * manage all of its assets.
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
     * - If the caller is not `from`, it must be approved to move this token by
     * either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first
     * that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever
     * locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this
     * token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the
     * recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom}
     * prevents loss, though the caller must
     * understand this adds an external call which potentially creates a
     * reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by
     * either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another
     * account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero
     * address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom} for any token
     * owned by the caller.
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
     * @dev Returns if the `operator` is allowed to manage all of the assets of
     * `owner`.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via
     * {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via
     * {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same
     * value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
        internal
        pure
        returns (address addr)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓
            // ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC
            // |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            |
            // 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC
            // |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
            // |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage
                // bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final
                // garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal
     * representation with fixed length.
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
     * @dev Converts an `address` with fixed length of 20 bytes to its not
     * checksummed ASCII `string` hexadecimal representation.
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP
     * section]
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
     * @notice Calculates floor(x * y / denominator) with full precision. Throws
     * if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license
     * (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod
            // 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit
            // result. The result is stored in two 256
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
                // Solidity will revert if denominator == 0, unlike the div
                // opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See
                // https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents
            // denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1
            // prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power
            // of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this
            // stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then
                // it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd
            // number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by
            // starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks
            // to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the
            // preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to
            // compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the
     * selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect
     * square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller
        // than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number
        // `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k`
        // with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of
        // `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We
        // know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges
        // quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our
        // partial result with one bit of precision
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
     * @dev Return the log in base 2, following the selected rounding direction,
     * of a positive value.
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
     * @dev Return the log in base 10, following the selected rounding
     * direction, of a positive value.
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
     * Adding one to the result gives the number of pairs of hex symbols needed
     * to represent `value` as a hex string.
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
     * @dev Return the log in base 256, following the selected rounding
     * direction, of a positive value.
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IFundraising01Factory/IFundraising01Factory.sol";
import "./interfaces/IFundraising01ERC721/IFundraising01ERC721.sol";
import "./interfaces/IERC721Mintable.sol";
import "./base/Fundraising01Base.sol";
import "./libraries/AddressArrayUtils.sol";
import "./libraries/Uint256ArrayUtils.sol";

/// @title Fundraising01ERC721
/// @dev Opposed to Fundraising01ERC20, the NFTs are not being transferred in
/// construction,
/// but instead should be filled manually by calling `replenish(...)` function
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Third-party to make sale democratic.
contract Fundraising01ERC721 is IFundraising01ERC721, Fundraising01Base {
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Immutables
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    /// @inheritdoc IFundraising01ERC721ImmutableState
    IERC721Mintable public immutable override tokenToSell;

    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // =========================================================================

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Mutables
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    /// @inheritdoc IFundraising01ERC721State
    uint256[] public override sellTokens;

    /// @inheritdoc IFundraising01ERC721State
    mapping(address => uint256[]) public tokensOf;
    /// @inheritdoc IFundraising01ERC721State
    mapping(address => uint256[]) public frozenTokensOf;
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // =========================================================================

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Reserves
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    /// @inheritdoc IFundraising01ERC721State
    uint256[] public override reservesSellTokens;
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    using Uint256ArrayUtils for uint256[];

    // =========================================================================

    constructor(
        IERC721Mintable _tokenToSell,
        IERC20 _tokenToRaise,
        uint256 _amountToSellSoft,
        ISaleRounds.SaleRound[] memory _saleRounds,
        RefundConfiguration memory _refundConfiguration,
        uint256 _executionDelay
    ) Fundraising01Base(_tokenToRaise, _amountToSellSoft, _saleRounds, _refundConfiguration, _executionDelay) {
        if (address(_tokenToSell) == address(0)) {
            revert CannotCreateFundraisingIfTokenToSellIsZeroAddressError();
        }
        if (address(_tokenToRaise) == address(_tokenToSell)) {
            revert CannotCreateFundraisingIfTokenToSellAndTokenToRaiseAreSameError();
        }

        tokenToSell = _tokenToSell;
    }

    // =========================================================================

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Invest Logic
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function _afterInvest(uint256 amount) internal virtual override {
        super._afterInvest(amount);

        uint256 pricePerToken = amountToRaise() / amountToSellHard();
        if (amount % pricePerToken != 0) {
            revert IncorrectInvestmentAmountError();
        }
        reservesRaise += amount;
        tokenToRaise.transferFrom(msg.sender, address(this), amount);

        // gas savings
        uint256 amountToSellHardLocal = amountToSellHard();
        for (uint256 i = 0; i < amount / pricePerToken; i++) {
            uint256 randomToken = _random(msg.sender) % amountToSellHardLocal;
            tokensOf[msg.sender].push(randomToken);
            tokenToSell.mint(msg.sender, randomToken);
        }

        investorsData[msg.sender].amountDeposited += amount;

        emit Invest(msg.sender, amount);
    }

    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // =========================================================================

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Claim Logic
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    function _random(address to) internal view returns (uint256 num) {
        num = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.prevrandao,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );
    }
    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // =========================================================================

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Refund Logic
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

    function _beforeRefundStart(bytes calldata _data) internal virtual override {
        uint256[] memory tokenIds = abi.decode(_data, (uint256[]));
        {
            uint256 availableToRefund = leftToClaimOf(msg.sender) * amountToSellHard() / amountToRaise();
            if (availableToRefund < tokenIds.length) {
                revert CannotRefundStartIfAmountToRefundExceedsAvailableToRefundError(
                    tokenIds.length - availableToRefund
                );
            }
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenToSell.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function _afterRefundStart(bytes calldata _data) internal virtual override {
        uint256[] memory tokensToFreeze = abi.decode(_data, (uint256[]));
        for (uint256 i = 0; i < tokensToFreeze.length; i++) {
            frozenTokensOf[msg.sender].push(tokensToFreeze[i]);
        }
        emit RefundStart(msg.sender, tokensToFreeze);
    }

    function _afterRefundFinish() internal virtual override {
        uint256 amountToRefund =
            leftToClaimOf(msg.sender) * frozenTokensOf[msg.sender].length / tokensOf[msg.sender].length;
        investorsData[msg.sender].amountDeposited -= amountToRefund;
        reservesRaise -= amountToRefund;
        tokenToRaise.transfer(msg.sender, amountToRefund);

        for (uint256 i = 0; i < frozenTokensOf[msg.sender].length; i++) {
            reservesSellTokens.push(frozenTokensOf[msg.sender][i]);
            tokensOf[msg.sender].removeStorage(tokensOf[msg.sender].indexOf(frozenTokensOf[msg.sender][i]));
        }

        emit RefundFinish(msg.sender, frozenTokensOf[msg.sender]);
        delete frozenTokensOf[msg.sender];
    }

    function _afterRefundCancel() internal virtual override {
        investorsData[msg.sender].refundStartedAt = 0;
        for (uint256 i = 0; i < frozenTokensOf[msg.sender].length; i++) {
            tokenToSell.transferFrom(address(this), msg.sender, frozenTokensOf[msg.sender][i]);
        }

        emit RefundCancel(msg.sender, frozenTokensOf[msg.sender]);
        delete frozenTokensOf[msg.sender];
    }

    // ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // =========================================================================

    /// @inheritdoc Ownable
    function transferOwnership(address newOwner)
        public
        virtual
        override(Fundraising01Base, IFundraising01BaseOwnerActions)
        onlyOwner
        notFailed
    {
        super.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IERC721Mintable.sol";
import "./interfaces/IFundraising01FactoryERC721/IFundraising01FactoryERC721.sol";
import "./interfaces/IWETH.sol";
import {IFundraising01Base} from "./base/interfaces/IFundraising01Base/IFundraising01Base.sol";
import {Fundraising01ERC721} from "./Fundraising01ERC721.sol";

/// @title Fundraising01Factory
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Factory contract for Fundraising01 contracts.
contract Fundraising01FactoryERC721 is IFundraising01FactoryERC721 {
    /// @inheritdoc IFundraising01FactoryERC721ImmutableState
    IWETH public immutable override WETH;

    constructor(IWETH _WETH) {
        WETH = _WETH;
    }

    /// @inheritdoc IFundraising01FactoryERC721Actions
    function createFundraisingERC721(
        address _creator,
        IERC721Mintable _tokenToSell,
        IERC20 _tokenToRaise,
        uint256 _amountToSellSoft,
        ISaleRounds.SaleRound[] memory _saleRounds,
        IRefunds.RefundConfiguration memory _refundConfiguration,
        uint256 _executionDelay
    ) external returns (address sale) {
        bytes32 salt = keccak256(abi.encodePacked(_tokenToSell, _tokenToRaise));

        sale = address(
            new Fundraising01ERC721{salt: salt}(
            _tokenToSell,
            _tokenToRaise,
            _amountToSellSoft,
            _saleRounds,
            _refundConfiguration,
            _executionDelay
            )
        );
        IFundraising01Base(sale).transferOwnership(_creator);

        emit Fundraising01ERC721Created(sale, _creator);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./interfaces/IBuildRounds.sol";
import "@/interfaces/ICondition.sol";

/// @title Build Rounds
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
abstract contract BuildRounds is IBuildRounds {
    /// @inheritdoc IBuildRounds
    IBuildRounds.BuildRound[] public override buildRounds;
    uint256 public executionDelay;

    constructor(uint256 _executionDelay) {
        executionDelay = _executionDelay;
    }

    /// @inheritdoc IBuildRounds
    function buildRoundsCount() external view override returns (uint256) {
        return buildRounds.length;
    }

    function _beforePushBuildRound(uint256) internal virtual {
        if (hasPendingBuildRound()) {
            revert CannotPushRoundIfAnotherRoundIsPendingError();
        }
        if (buildRounds.length > 1 && !buildRounds[buildRounds.length - 1].isExecuted) {
            revert CannotPushRoundBeforePreviousRoundIsExecutedError();
        }
    }

    function _afterPushBuildRound(uint256 amount) internal virtual {}

    function pushBuildRound(uint256 amount, string memory details) external override {
        _beforePushBuildRound(amount);

        buildRounds.push(
            BuildRound({
                amountAsked: amount,
                amountUnlocked: 0,
                amountRefunded: 0,
                amountRefundedCumulative: 0,
                details: details,
                createdAt: block.timestamp,
                isFulfilled: false,
                isExecuted: false
            })
        );
        emit BuildingRoundPushed(buildRounds.length - 1);

        _afterPushBuildRound(amount);
    }

    function hasPendingBuildRound() public view override returns (bool) {
        return buildRounds.length > 0 && block.timestamp >= buildRounds[buildRounds.length - 1].createdAt
            && block.timestamp <= buildRounds[buildRounds.length - 1].createdAt + executionDelay;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFundraising01Base/IFundraising01Base.sol";
import "../interfaces/IFundraising01Factory/IFundraising01Factory.sol";
import "../libraries/AddressArrayUtils.sol";

import "./SaleRounds.sol";
import "./BuildRounds.sol";
import "./Refunds.sol";

/// @title Fundraising01Base
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Third-party to make sale democratic.
abstract contract Fundraising01Base is Refunds, SaleRounds, BuildRounds, IFundraising01Base, Ownable {
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                LIBRARIES                               */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    using AddressArrayUtils for address[];

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                CONSTANTS                               */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    /// @inheritdoc IFundraising01BaseConstants
    uint256 public constant SALE_STAGE_MIN_PERIOD = 30 days;

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                               IMMUTABLES                               */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    /// @inheritdoc IFundraising01BaseImmutableState
    uint256 public immutable override createdAt;
    /// @inheritdoc IFundraising01BaseImmutableState
    uint256 public immutable override amountToSellSoft;
    /// @inheritdoc IFundraising01BaseImmutableState
    IERC20 public immutable override tokenToRaise;

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                MUTABLES                                */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    /// @inheritdoc IFundraising01BaseState
    uint256 public amountRaised;
    uint256 public amountApproved;
    uint256 public amountRefunded;
    uint256 public amountRefunding;

    /// @inheritdoc IFundraising01BaseState
    uint256 public override reservesRaise;

    struct InvestorData {
        uint256 amountDeposited;
        uint256 refundStartedAt;
        uint256 amountClaimed;
    }

    mapping(address => InvestorData) internal investorsData;

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                MODIFIERS                               */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    modifier notFailed() {
        if (isFailed()) revert SaleIsFailedError();
        _;
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                               CONSTRUCTOR                              */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    constructor(
        IERC20 _tokenToRaise,
        uint256 _amountToSellSoft,
        ISaleRounds.SaleRound[] memory _saleRounds,
        RefundConfiguration memory _refundConfiguration,
        uint256 _executionDelay
    ) Ownable() Refunds(_refundConfiguration) SaleRounds(_saleRounds) BuildRounds(_executionDelay) {
        if (address(_tokenToRaise) == address(0)) {
            revert CannotCreateFundraisingIfTokenToRaiseIsZeroAddressError();
        }
        if (_amountToSellSoft == 0) {
            revert CannotCreateFundraisingIfAmountToSellSoftIsZeroError();
        }

        createdAt = block.timestamp;

        tokenToRaise = _tokenToRaise;

        amountToSellSoft = _amountToSellSoft;
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                 INVEST                                 */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    function _afterInvest(uint256 amount) internal virtual {
        amountRaised += amount;
    }

    /// @inheritdoc IFundraising01BaseActions
    function invest(uint256 amount, bytes memory data) public virtual override {
        _beforeInvest(amount);

        bool passed = true;
        for (uint256 i = 0; i < saleRounds.length; i++) {
            if (address(saleRounds[i].condition) == address(0)) continue;
            passed = passed && saleRounds[i].condition.check(abi.encode(msg.sender, data));
        }

        if (!passed) revert CannotInvestIfSaleRoundConditionIsNotPassedError();

        _afterInvest(amount);
    }

    function _beforeInvest(uint256 amount) internal view notFailed {
        if (amount == 0) revert AmountCannotBeZeroError();
        if (block.timestamp > createdAt + SALE_STAGE_MIN_PERIOD) {
            revert CannotInvestIfSaleRoundIsNotInProgressError();
        }
        if (amountToRaise() < reservesRaise + amount) {
            revert CannotInvestIfInvestAmountExceedsRaiseHardAmountError(reservesRaise + amount - amountToRaise());
        }
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                              BUILD ROUNDS                              */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    function _beforePushBuildRound(uint256 amount) internal override(BuildRounds) onlyOwner notFailed {
        super._beforePushBuildRound(amount);

        // specific cheks for maximum unlock ask amount can be implemented below
        if (amount > reservesRaise) {
            revert CannotPushRoundIfInsufficientReservesForProposalError(amount - reservesRaise);
        }
    }

    function executeBuildRound() external override(IBuildRounds) {
        if (buildRounds.length > 1 && !hasPendingBuildRound()) {
            revert CannotExecuteRoundIfThereIsPendingProposalError();
        }
        BuildRound storage round = buildRounds[buildRounds.length - 1];
        if (round.isExecuted) {
            revert CannotExecuteRoundIfProposalIsExecutedError();
        }

        round.isExecuted = true;
        round.amountRefunded = (round.amountRefundedCumulative = amountRefunded) - buildRounds.length == 1
            ? 0
            : buildRounds[buildRounds.length - 1].amountRefundedCumulative;

        amountApproved += round.amountAsked;

        emit UnlockExecuted(msg.sender, buildRounds.length - 1);
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                WITHDRAW                                */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    /// @inheritdoc IFundraising01BaseOwnerActions
    function withdraw(uint256 index) external {
        BuildRound storage round = buildRounds[index];

        if (round.amountUnlocked == 0) revert CannotWithdrawZeroTokensError();
        if (round.isFulfilled) revert CannotWithdrawIfRoundIsFulfilledError();

        round.isFulfilled = true;
        reservesRaise -= round.amountUnlocked;
        tokenToRaise.transfer(owner(), round.amountAsked);

        emit Withdraw(round.amountAsked);
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                 REFUND                                 */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    function isRefundAvailable() public view override returns (bool) {
        // Refund becomes available either after two months of fundraising
        // living or after the first proposal
        return buildRounds.length > 1 || createdAt + refundConfiguration.availabilityDelay > block.timestamp;
    }

    /**
     * @dev This function is called before a refund has been created.
     */
    function _beforeRefundStart(bytes calldata) internal virtual {
        if (!isRefundAvailable()) {
            revert CannotRefundStartIfRefundIsNotAvailableYetError();
        }
    }
    /**
     * @dev This function is called after a refund has been created.
     */

    function _afterRefundStart(bytes calldata _data) internal virtual {}

    function refundStart(bytes calldata _data) external override {
        _beforeRefundStart(_data);
        investorsData[msg.sender].refundStartedAt = block.timestamp;
        _afterRefundStart(_data);
    }

    /**
     * @dev This function is called after a refund has been finished.
     */
    function _afterRefundFinish() internal virtual {}

    function refundFinish() external virtual override {
        bool failed = isFailed();
        if (!failed && block.timestamp < investorsData[msg.sender].refundStartedAt + refundConfiguration.cancelWindow) {
            revert CannotRefundYet(investorsData[msg.sender].refundStartedAt + refundConfiguration.cancelWindow);
        }
        _afterRefundFinish();
    }

    /**
     * @dev This function is called after a refund has been cancelled.
     */
    function _afterRefundCancel() internal virtual;

    function refundCancel() external override {
        if (investorsData[msg.sender].refundStartedAt == 0) {
            revert CannotCancelRefundIfNotStartedError();
        }
        if (block.timestamp > investorsData[msg.sender].refundStartedAt + refundConfiguration.cancelWindow) {
            revert CannotCancelRefundIfWindowPassedError();
        }
        investorsData[msg.sender].refundStartedAt = 0;
        _afterRefundCancel();
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                  MISC                                  */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    /// @inheritdoc Ownable
    function transferOwnership(address newOwner)
        public
        virtual
        override(Ownable, IFundraising01BaseOwnerActions)
        onlyOwner
    {
        super.transferOwnership(newOwner);
    }

    /// @inheritdoc IFundraising01BaseActions
    function skim() public virtual override {
        uint256 reserveRaiseSkim = tokenToRaise.balanceOf(address(this)) - reservesRaise;

        if (reserveRaiseSkim > 0) {
            tokenToRaise.transfer(msg.sender, reserveRaiseSkim);
        }

        emit SkimRaiseReserves(msg.sender, reserveRaiseSkim);
    }

    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/
    /*                                 GETTERS                                */
    /*:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:.•°:°.´+˚.*°.*/

    /// @inheritdoc IFundraising01BaseDerivedState
    function claimable() public view virtual override returns (uint256) {
        return investorsData[msg.sender].amountDeposited * amountToSellHard() / amountToRaise()
            - investorsData[msg.sender].amountClaimed;
    }

    function amountToRaise() public view returns (uint256 amount) {
        for (uint256 i = 0; i < saleRounds.length; ++i) {
            amount += saleRounds[i].amountToRaise;
        }
    }

    function amountToSellHard() public view returns (uint256 amount) {
        for (uint256 i = 0; i < saleRounds.length; ++i) {
            amount += saleRounds[i].amountToSell;
        }
    }

    function amountUnlocked() public view returns (uint256) {
        return amountApproved - amountRefunding - amountRefunded;
    }

    function depositedOf(address investor) public view returns (uint256) {
        return investorsData[investor].amountDeposited;
    }

    function unlockedOf(address investor) public view returns (uint256) {
        return amountUnlocked() * investorsData[investor].amountDeposited / amountRaised;
    }

    function leftToClaimOf(address investor) public view returns (uint256) {
        return depositedOf(investor) - unlockedOf(investor);
    }

    /// @inheritdoc IFundraising01BaseDerivedState
    function isFailed() public view override returns (bool) {
        // this looks tricky, but the `reservesRaise` won't be updated if the
        // `SALE_STAGE_MIN_PERIOD` has passed and the `amountToSellSoft` was not
        // reached
        return block.timestamp > createdAt + SALE_STAGE_MIN_PERIOD
            && reservesRaise < amountToSellSoft * amountToRaise() / amountToSellHard();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./interfaces/IRefunds.sol";

abstract contract Refunds is IRefunds {
    IRefunds.RefundConfiguration public override refundConfiguration;

    constructor(IRefunds.RefundConfiguration memory _refundConfiguration) {
        if (_refundConfiguration.availabilityDelay > 60 days) {
            revert CannotCreateFundraisingIfAvailabilityDelayIsGreaterThan60DaysError();
        }

        if (_refundConfiguration.cancelWindow > 30 days) {
            revert CannotCreateFundraisingIfCancelWindowIsGreaterThan30DaysError();
        }
        refundConfiguration = _refundConfiguration;
    }

    function isRefundAvailable() public view virtual override returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./interfaces/ISaleRounds.sol";
import "@/interfaces/ICondition.sol";

/// @title Sale Stages
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
abstract contract SaleRounds is ISaleRounds {
    ISaleRounds.SaleRound[] public override saleRounds;

    constructor(ISaleRounds.SaleRound[] memory _saleRounds) {
        for (uint256 i = 0; i < _saleRounds.length; i++) {
            saleRounds.push(_saleRounds[i]);
        }
    }

    function saleRoundsCount() external view override returns (uint256) {
        return saleRounds.length;
    }

    function applicableSaleRoundIndexOf(bytes memory data) external view override returns (uint256) {
        bool conditionFound = false;
        for (uint256 i = 0; i < saleRounds.length; i++) {
            if (
                saleRounds[i].startsAt <= block.timestamp && block.timestamp <= saleRounds[i].endsAt
                    && address(saleRounds[i].condition) != address(0)
            ) {
                conditionFound = true;
                if (saleRounds[i].condition.check(abi.encode(msg.sender, data))) {
                    return i;
                }
            }
        }
        if (!conditionFound) {
            for (uint256 i = 0; i < saleRounds.length; i++) {
                if (saleRounds[i].startsAt <= block.timestamp && block.timestamp <= saleRounds[i].endsAt) {
                    return i;
                }
            }
        }
        revert NoApplicableSaleRoundIndex();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @title Build Rounds
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
interface IBuildRounds {
    event BuildingRoundPushed(uint256 index);

    error CannotPushRoundIfAnotherRoundIsPendingError();
    error CannotPushRoundBeforePreviousRoundIsExecutedError();
    error CannotPushRoundIfInsufficientReservesForProposalError(uint256 amountExceeds);

    struct BuildRound {
        uint256 amountAsked;
        string details;
        uint256 createdAt;
        uint256 amountUnlocked;
        uint256 amountRefunded;
        uint256 amountRefundedCumulative;
        bool isExecuted;
        bool isFulfilled;
    }

    /**
     * @notice Returns build round by index.
     * @param _index index.
     */
    function buildRounds(uint256 _index)
        external
        view
        returns (
            uint256 amountAsked,
            string memory details,
            uint256 createdAt,
            uint256 amountUnlocked,
            uint256 amountRefunded,
            uint256 amountRefundedCumulative,
            bool isExecuted,
            bool isFulfilled
        );

    /**
     * @notice Returns build rounds count.
     */
    function buildRoundsCount() external view returns (uint256);

    /// @notice Ask for unlock
    /// @dev Only the issuer can call this function.
    /// @param amount The amount of tokens to unlock.
    /// @param details The unlock details
    function pushBuildRound(uint256 amount, string memory details) external;

    function executeBuildRound() external;

    function hasPendingBuildRound() external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@/base/interfaces/IBuildRounds.sol";
import "@/base/interfaces/ISaleRounds.sol";
import "./IFundraising01BaseActions.sol";
import "./IFundraising01BaseConstants.sol";
import "./IFundraising01BaseDerivedState.sol";
import "./IFundraising01BaseErrors.sol";
import "./IFundraising01BaseEvents.sol";
import "./IFundraising01BaseImmutableState.sol";
import "./IFundraising01BaseOwnerActions.sol";
import "./IFundraising01BaseState.sol";

/// @title IFundraising01Base
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Interface for Fundraising01Base contract.
interface IFundraising01Base is
    ISaleRounds,
    IBuildRounds,
    IFundraising01BaseActions,
    IFundraising01BaseConstants,
    IFundraising01BaseDerivedState,
    IFundraising01BaseErrors,
    IFundraising01BaseEvents,
    IFundraising01BaseImmutableState,
    IFundraising01BaseOwnerActions,
    IFundraising01BaseState
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01BaseActions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Public Fundraising01 actions that anyone can call
interface IFundraising01BaseActions {
    /// @notice Invest in the sale.
    /// @param amount The amount of tokens to invest.
    function invest(uint256 amount, bytes memory data) external;

    /// @notice Forces balances to match reserves.
    /// @dev If some tokens were transferred directly to the contract, they can
    /// be claimed.
    function skim() external;
}

// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.18;

/// @title IFundraising01BaseConstants
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that will never change and encoded in the
/// contract.
interface IFundraising01BaseConstants {
    /// @notice The time period at which a sell should be up and running.
    /// If this period has lasted after the sale start, the sale will be
    /// destroyed.
    /// @return Start period.
    function SALE_STAGE_MIN_PERIOD() external pure returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01BaseDerivedState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that is computed on fly.
interface IFundraising01BaseDerivedState {
    /// @notice Returns available amount for claim.
    /// @return Claimable amount
    function claimable() external view returns (uint256);

    /// @notice Is the sale failed
    /// @return True if sale is failed
    function isFailed() external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFundraising01BaseErrors {
    error CannotCreateFundraisingIfFactoryIsZeroAddressError();

    error InsufficientTTLError();

    error CannotCreateFundraisingIfAmountToSellSoftIsZeroError();
    error CannotCreateFundraisingIfAmountToSellHardIsZeroError();
    error CannotCreateFundraisingIfAmountToRaiseIsZeroError();
    error CannotCreateFundraisingIfTokenToRaiseIsZeroAddressError();
    error CannotCreateFundraisingIfTokenToSellIsZeroAddressError();
    error CannotCreateFundraisingIfTokenToSellAndTokenToRaiseAreSameError();

    error AmountCannotBeZeroError();

    error CannotInvestIfSaleRoundIsNotInProgressError();
    error SaleIsFailedError();
    error SaleIsNotFinishedError();

    error CannotUnlockIfDesiredUnlockAmountExceedsInvestedError(uint256 max);

    error CannotInvestIfInvestAmountExceedsRaiseHardAmountError(uint256 amountExceeds);

    error CannotInvestWithETHError(address tokenToRaise);

    error CannotRefundStartIfRefundIsNotAvailableYetError();
    error CannotRefundYet(uint256 availableAt);

    error CannotRefundStartIfAmountToRefundExceedsAvailableToRefundError(uint256 amountExceeds);

    error CannotCancelRefundIfNotStartedError();
    error CannotCancelRefundIfWindowPassedError();

    error CannotExecuteRoundIfNoRoundIsPendingError();
    error CannotExecuteRoundIfDelayNotPassedYetError();
    error CannotExecuteRoundIfThereIsPendingProposalError();
    error CannotExecuteRoundIfProposalIsExecutedError();

    error CannotWithdrawZeroTokensError();
    error CannotWithdrawIfRoundIsFulfilledError();

    error ProposalToLiquidateIsInProgressError();

    error LiquidationIsNotAvailableYetError();

    error CannotClaimIfExceedsClaimableMaximumError();

    error CannotInvestIfSaleRoundConditionIsNotPassedError();
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFundraising01BaseEvents {
    event SaleFailed();
    event UnlockExecuted(address indexed executor, uint256 index);

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(uint256 amount);
    event Unlock(address indexed investor, uint256 amount);

    event SkimRaiseReserves(address indexed skimmer, uint256 reserveRaiseSkim);
}

// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.18;

/// @title IFundraising01BaseImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the sale that will never change.
interface IFundraising01BaseImmutableState {
    /// @notice Timestamp when the sale took place
    /// @return Timestamp
    function createdAt() external view returns (uint256);

    /// @notice Amount of tokens to raise
    /// @return Amount
    function amountToRaise() external view returns (uint256);

    /// @notice Amount of tokens to sell
    /// If sale doesn't sell the `amountToSellSoft` – it is considered as
    /// failed.
    /// @return Amount
    function amountToSellSoft() external view returns (uint256);

    /// @notice Amount of tokens to sell
    /// Fundraising cannot sell more than this amount.
    /// @return Amount
    function amountToSellHard() external view returns (uint256);

    /// @notice The token to raise
    /// @return The token to raise
    function tokenToRaise() external view returns (IERC20);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title Owner Actions of Fundraising01
/// @notice Actions that can be performed by the owner of the sale.
interface IFundraising01BaseOwnerActions {
    function transferOwnership(address newOwner) external;

    /// @notice Withdraw available raised funds.
    /// @dev Only the owner can call this function.
    /// @param index Index of the unlock proposal.
    function withdraw(uint256 index) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @title IFundraising01BaseState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that can change.
interface IFundraising01BaseState {
    /// @notice Raise Reserves
    /// @dev Used in skim() to equalize the tokens with real balance
    /// @return Raise Reserves
    function reservesRaise() external view returns (uint256);

    /// @notice Amount raised
    /// @return Amount raised
    function amountRaised() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IRefunds {
    error CannotCreateFundraisingIfAvailabilityDelayIsGreaterThan60DaysError();
    error CannotCreateFundraisingIfCancelWindowIsGreaterThan30DaysError();

    struct RefundConfiguration {
        uint32 cancelWindow; // max 30 days
        uint32 availabilityDelay; // max 60 days
    }

    function refundConfiguration() external view returns (uint32 cancelWindow, uint32 availabilityDelay);

    function isRefundAvailable() external view returns (bool);

    function refundStart(bytes calldata _data) external;

    function refundFinish() external;

    function refundCancel() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "@/interfaces/ICondition.sol";

/// @title Sale Stages
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
interface ISaleRounds {
    error NoApplicableSaleRoundIndex();

    struct SaleRound {
        uint256 startsAt;
        uint256 endsAt;
        uint256 amountToRaise;
        uint256 amountToSell;
        ICondition condition;
    }

    function saleRounds(uint256 _index)
        external
        view
        returns (uint256 startsAt, uint256 endsAt, uint256 amountToRaise, uint256 amountToSell, ICondition condition);

    function saleRoundsCount() external view returns (uint256);

    function applicableSaleRoundIndexOf(bytes memory data) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @title Vestable
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Abstract contract for calculating claimable amounts with unlock
/// periods.
interface IVestable {
    struct Period {
        uint256 start;
        uint16 bps;
        bool cliffs;
    }

    error TotalBPSUnfulfilledError();
    error MinimumOfPeriodsNotMetError();
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/**
 * @title ICondition
 * @dev Interface for the Condition contract.
 */
interface ICondition {
    /**
     * @notice Checks if the condition is met.
     * @param _data The data needed to perform a check.
     * @return True if the condition is met, false otherwise.
     */
    function check(bytes memory _data) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Mintable is IERC721 {
    function mint(address account, uint256 amount) external;

    function MINTER_ROLE() external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../../base/interfaces/IFundraising01Base/IFundraising01Base.sol";
import "./IFundraising01ERC721State.sol";
import "./IFundraising01ERC721ImmutableState.sol";
import "./IFundraising01ERC721Errors.sol";
import "./IFundraising01ERC721Events.sol";

/// @title IFundraising01
/// @notice A simple sale contract interface.
interface IFundraising01ERC721 is
    IFundraising01Base,
    IFundraising01ERC721ImmutableState,
    IFundraising01ERC721State,
    IFundraising01ERC721Errors,
    IFundraising01ERC721Events
{}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFundraising01ERC721Errors {
    error CantReceiveERC721NotFromTheOwnerError();
    error IncorrectCollectionReceivedError();
    error IncorrectTokensAmountPassedError(uint256 expected);
    error SaleHasNoTokenIdError(uint256 tokenId);
    error IncorrectInvestmentAmountError();

    error ExceedsSyntheticBalanceError();
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IFundraising01ERC721Events {
    event Skim(address indexed skimmer, uint256 reserveRaiseSkim);
    event Claim(address indexed investor, uint256 amount, uint256[] tokenIds);
    event RefundStart(address indexed investor, uint256[] tokenIds);
    event RefundFinish(address indexed investor, uint256[] tokenIds);
    event RefundCancel(address indexed investor, uint256[] tokenIds);
}

// SPDX-License-Identifier: Unlicense

import "../IERC721Mintable.sol";

pragma solidity ^0.8.18;

/// @title IFundraising01ERC721ImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the sale that will never change.
interface IFundraising01ERC721ImmutableState {
    /// @notice The token to sell
    /// @return The token to sell
    function tokenToSell() external view returns (IERC721Mintable);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01ERC721State
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the sale that can change.
interface IFundraising01ERC721State {
    /// @notice Sell Reserves Token Indeces
    /// @param index Index of the token
    /// @return Sell Reserves
    function reservesSellTokens(uint256 index) external view returns (uint256);

    /// @notice Sell Token Indeces
    /// @param index Index of the token
    /// @return Sell Token indeces
    function sellTokens(uint256 index) external view returns (uint256);

    /**
     * @notice Returns an array of all ERC-721 tokens owned by an account
     * @param account The address of the account to query
     * @return An array of uint256 representing the tokens owned by the account
     */
    function tokensOf(address account, uint256 index) external view returns (uint256);

    /// @notice Frozen tokens of the investor
    /// @dev Used to store the tokens that have been sent for a refund
    /// @param account Investor address
    /// @return Frozen tokens
    function frozenTokensOf(address account, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "./IFundraising01FactoryActions.sol";
import "./IFundraising01FactoryState.sol";
import "./IFundraising01FactoryImmutableState.sol";

/// @title IFundraising01Factory
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice This interface combines all interfaces for Factory.
interface IFundraising01Factory is
    IFundraising01FactoryState,
    IFundraising01FactoryImmutableState,
    IFundraising01FactoryActions
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IFundraising01FactoryERC20/IFundraising01FactoryERC20Actions.sol";
import "../IFundraising01FactoryERC721/IFundraising01FactoryERC721Actions.sol";

/// @title IFundraising01FactoryActions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Actions for factory contract for Fundraising01 contracts.
interface IFundraising01FactoryActions {
    /// @notice Creates a new sale.
    /// @param tokenToSell The token to sell.
    /// @param tokenToRaise The token to raise.
    /// @param amountToSellSoft The amount of tokens to sell soft (Soft Cap).
    /// @param saleRounds Sale Rounds.
    /// @param periods Vesting periods.
    /// @param refundConfiguration Refund configuration.
    /// @param executionDelay Refund configuration.
    /// @return The address of the sale.
    function createFundraisingERC20(
        IERC20 tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IVestable.Period[] memory periods,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);

    /**
     * @notice Creates a new ERC721 sale contract.
     * @param tokenToSell The ERC721 token to be sold.
     * @param tokenToRaise The ERC20 token to be used to buy the ERC721 token.
     * @param amountToSellSoft The soft cap of the ERC721 token to be sold.
     * @param saleRounds Sale Rounds.
     * @param refundConfiguration Refund configuration.
     * @param executionDelay Refund configuration.
     */
    function createFundraisingERC721(
        IERC721Mintable tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IWETH.sol";

import "../IFundraising01FactoryERC20/IFundraising01FactoryERC20.sol";
import "../IFundraising01FactoryERC721/IFundraising01FactoryERC721.sol";

/// @title IFundraising01ERC721FactoryImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the Factory that will never change.
interface IFundraising01FactoryImmutableState {
    /// @notice The address of the Fundraising Factory ERC20.
    /// @return The address of the Fundraising Factory ERC20.
    function factoryERC20() external view returns (IFundraising01FactoryERC20);

    /// @notice The address of the Fundraising Factory ERC721.
    /// @return The address of the Fundraising Factory ERC721.
    function factoryERC721() external view returns (IFundraising01FactoryERC721);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01FactoryState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice State of the factory that can change.
interface IFundraising01FactoryState {
    /// @notice All ongoing sales.
    /// @param index The index of the sale.
    /// @return The IFundraising01 sale contract.
    function sales(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "./IFundraising01FactoryERC20Actions.sol";
import "./IFundraising01FactoryERC20ImmutableState.sol";
import "./IFundraising01FactoryERC20Events.sol";

/// @title IFundraising01FactoryERC20
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice This interface combines all interfaces for FactoryERC20.
interface IFundraising01FactoryERC20 is
    IFundraising01FactoryERC20ImmutableState,
    IFundraising01FactoryERC20Actions,
    IFundraising01FactoryERC20Events
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../IERC721Mintable.sol";
import "../../base/interfaces/ISaleRounds.sol";
import "../../base/interfaces/IRefunds.sol";
import "../../base/interfaces/IVestable.sol";

/// @title IFundraising01FactoryERC20Actions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Actions for factory contract for Fundraising01 contracts.
interface IFundraising01FactoryERC20Actions {
    /// @notice Creates a new sale.
    /// @param tokenToSell The token to sell.
    /// @param tokenToRaise The token to raise.
    /// @param amountToSellSoft The amount of tokens to sell soft (Soft Cap).
    /// @param saleRounds Sale Rounds.
    /// @param periods Vesting periods.
    /// @param refundConfiguration Refund configuration.
    /// @param executionDelay Refund configuration.
    /// @return The address of the sale.
    function createFundraisingERC20(
        address creator,
        IERC20 tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IVestable.Period[] memory periods,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01ERC20FactoryEvents
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Events emitted by factory.
interface IFundraising01FactoryERC20Events {
    event Fundraising01ERC20Created(address indexed fundraising, address indexed creator);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IWETH.sol";

/// @title IFundraising01ERC20FactoryImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the Factory that will never change.
interface IFundraising01FactoryERC20ImmutableState {
    /// @notice The address of the WETH contract.
    /// @return The address of the WETH contract.
    function WETH() external view returns (IWETH);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "./IFundraising01FactoryERC721Actions.sol";
import "./IFundraising01FactoryERC721ImmutableState.sol";
import "./IFundraising01FactoryERC721Events.sol";

/// @title IFundraising01FactoryERC721
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice This interface combines all interfaces for FactoryERC721.
interface IFundraising01FactoryERC721 is
    IFundraising01FactoryERC721ImmutableState,
    IFundraising01FactoryERC721Actions,
    IFundraising01FactoryERC721Events
{}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../IERC721Mintable.sol";
import "../../base/interfaces/ISaleRounds.sol";
import "../../base/interfaces/IRefunds.sol";
import "../../base/interfaces/IVestable.sol";

/// @title IFundraising01FactoryERC721Actions
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Actions for factory contract for Fundraising01 contracts.
interface IFundraising01FactoryERC721Actions {
    /**
     * @notice Creates a new ERC721 sale contract.
     * @param tokenToSell The ERC721 token to be sold.
     * @param tokenToRaise The ERC20 token to be used to buy the ERC721 token.
     * @param amountToSellSoft The soft cap of the ERC721 token to be sold.
     * @param saleRounds Sale Rounds.
     * @param refundConfiguration Refund configuration.
     * @param executionDelay Refund configuration.
     */
    function createFundraisingERC721(
        address creator,
        IERC721Mintable tokenToSell,
        IERC20 tokenToRaise,
        uint256 amountToSellSoft,
        ISaleRounds.SaleRound[] memory saleRounds,
        IRefunds.RefundConfiguration memory refundConfiguration,
        uint256 executionDelay
    ) external returns (address);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/// @title IFundraising01ERC721FactoryEvents
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Events emitted by factory.
interface IFundraising01FactoryERC721Events {
    event Fundraising01ERC721Created(address indexed fundraising, address indexed creator);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

import "../IWETH.sol";

/// @title IFundraising01ERC721FactoryImmutableState
/// @author Vladyslav Dalechyn <h0tw4t3r.eth>
/// @notice Immutable state of the Factory that will never change.
interface IFundraising01FactoryERC721ImmutableState {
    /// @notice The address of the WETH contract.
    /// @return The address of the WETH contract.
    function WETH() external view returns (IWETH);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

library AddressArrayUtils {
    function filter(address[] memory self, function (address) view returns (bool) predicate)
        internal
        view
        returns (address[] memory)
    {
        bool[] memory includeMap = new bool[](self.length);
        uint256 count = 0;
        for (uint256 i = 0; i < self.length; i++) {
            if (predicate(self[i])) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory filtered = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < self.length; i++) {
            if (includeMap[i]) {
                filtered[j] = self[i];
                j++;
            }
        }
        return filtered;
    }

    function filteredLength(address[] memory self, function (address) view returns (bool) predicate)
        internal
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < self.length; i++) {
            if (predicate(self[i])) {
                count++;
            }
        }
        return count;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

library Uint256ArrayUtils {
    error NotFoundError();

    function remove(uint256[] memory self, uint256 index) internal pure {
        (self[index], self[self.length - 1]) = (self[self.length - 1], self[index]);
        delete self[self.length - 1];
        assembly {
            mstore(self, sub(mload(self), 1))
        }
    }

    function removeStorage(uint256[] storage self, uint256 index) internal returns (uint256 r) {
        (self[index], self[self.length - 1]) = (self[self.length - 1], self[index]);
        r = self[index];
        self.pop();
    }

    function indexOf(uint256[] memory self, uint256 value) internal pure returns (uint256 r) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == value) {
                r = i;
                break;
            }
        }
    }
}