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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./HeartColors.sol";

contract AH is Ownable, ERC165 {
    using Address for address;
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

//    struct HeartInfo {
//        uint64 expiryTime;
//        uint64 burnLastUpdated;
//        uint128 auxData;
//    }

    CrudeBorneEggs public cbEggs;
    address public INACTIVE_HEARTS_ADDRESS;

//    mapping(uint256 => HeartInfo) private _heartsInfo;
    mapping(uint256 => uint256) private _heartsInfo;
    mapping(address => uint256) private _nonDrainingCharge;
    uint256 public baseBurnRate = 0.005 ether;
//    uint256 public minSpendIncrement = 0.001 ether;
    uint256 public minSpendIncrement = 0.00005 ether;
//    uint256 private millisPerMonth = 2629800000;
    uint256 private secondsPerMonth = 2629800;
//    uint256 private millisPerIncrement = 525960000;
//    uint256 private secondsPerIncrement = 525960;
    uint256 private secondsPerIncrement = 26298;
    // TODO: Get rid of these after testing:
    uint256 private secondsPerWeek = 1 weeks;
    uint256 private secondsPerDay = 1 days;
    uint256 private secondsPerHour = 1 hours;
    uint256 private secondsPer5Minutes = 5 minutes;
    uint256 private secondsPerMinute = 1 minutes;

//    struct SubInfo {
//        address recipient;
//        uint96 numSubs;
//    }
//    mapping(address => SubInfo) public subInfo;

    mapping(address => bool) public burnModifiers;

    modifier onlyBurnModifier() {
        require(burnModifiers[msg.sender], "burn_auth");
        _;
    }

    mapping(address => uint256) public totalBurnMultiplier;

    string private _name;
    string private _symbol;

    string public collectionDescription;

    string public imageBase;
    string public imagePostfix;

    string public animationBase;
    string public animationPostfix;

    address public STORAGE_LAYER_ADDRESS;
    address public LIQUIDATION_REWARDS_ADDRESS;

    uint256 public transferTaxBasisPoints = 500;

    modifier onlyStorage() {
        _isStorageContract();
        _;
    }

    function _isStorageContract() internal view virtual {
        require(msg.sender == STORAGE_LAYER_ADDRESS, "nsl");
    }

    constructor(
        address cbAddy_,
        uint256 baseBurnRate_,
        string memory name_,
        string memory symbol_,
        address storageLayerAddress_
    ) {
        cbEggs = CrudeBorneEggs(cbAddy_);
        baseBurnRate = baseBurnRate_;
        minSpendIncrement = baseBurnRate/100;
        _name = name_;
        _symbol = symbol_;
        STORAGE_LAYER_ADDRESS = storageLayerAddress_;
    }

    /**
     * @dev returns the expiration time/date in milliseconds (from the Unix "zero" date).
     *   Can be compared against block.timestamp in order to tell whether
     *   a given heart's subscription is currently valid
    **/
    function getExpiryTime(uint256 heartId) public view returns (uint256) {
        require(StorageLayerProto(STORAGE_LAYER_ADDRESS)._exists(true, heartId));
//        return uint256(_heartsInfo[heartId].expiryTime);
        return uint256(_heartsInfo[heartId]);
    }

    /*
     * @dev returns the number of 100'ths of a "single" charge (aka a month's worth of charge)
     *   that a particular heart has remaining
     *   - Rounded down to the nearest 100th of a charge
    */
    function getChargeIncrements(uint256 heartId) public view returns (uint256) {
        uint256 expiryTime = getExpiryTime(heartId);

        if (expiryTime < block.timestamp) {
            return 0;
        }

        return ((expiryTime - block.timestamp)/secondsPerIncrement);
    }

    function _addCharge(uint256 heartId, uint64 timeToAdd) private {
//        _heartsInfo[heartId].expiryTime += timeToAdd;
        _heartsInfo[heartId] += timeToAdd;
    }

    function _subtractCharge(uint256 heartId, uint64 timeToSubtract) private {
//        _heartsInfo[heartId].expiryTime -= timeToSubtract;
        _heartsInfo[heartId] -= timeToSubtract;
    }

    function _spend(uint256 heartId, uint256 amt) private {
        // Get number of seconds corresponding to the charge amount being spent
        uint256 secondsSpent = secondsPerIncrement*amt;

        require((block.timestamp + secondsSpent) < getExpiryTime(heartId), "rekt");

        _subtractCharge(heartId, uint64(secondsSpent));
    }

    function spend(uint256 heartId, uint256 amt) public {
        require(msg.sender == ownerOf(heartId), "o");
        _spend(heartId, amt);
    }

    function spendOnBehalfOf(address whom, uint256 heartId, uint256 amt) public {
        require(whom == tx.origin, "whomst?");
        require(whom == ownerOf(heartId), "o");
        _spend(heartId, amt);
    }

    function _topUp(uint256 heartId, uint256 amt) private {
        uint256 topUpSeconds = secondsPerIncrement*amt;

        _addCharge(heartId, uint64(topUpSeconds));

        LiqRewardsProto(
            LIQUIDATION_REWARDS_ADDRESS
        ).storeReward{value: msg.value/10}(heartId);
    }

    function topUp(uint256 heartId, uint256 amt) public payable {
        require(msg.sender == ownerOf(heartId), "o");
        require(msg.value == amt*minSpendIncrement, "poor");
        _topUp(heartId, amt);
    }

    function giftTopUp(uint256 heartId, uint256 amt) public payable {
        require(msg.value == amt*minSpendIncrement, "poor");
        _topUp(heartId, amt);
    }

    function _topUpNonDraining(address whom) private {
        require(msg.value%minSpendIncrement == 0, "frac");
        _nonDrainingCharge[whom] += (msg.value/minSpendIncrement);

        LiqRewardsProto(
            LIQUIDATION_REWARDS_ADDRESS
        ).storeReward{value: msg.value/10}(tokenOfOwnerByIndex(msg.sender, 0));
    }

    function topUpNonDraining() public payable {
        _topUpNonDraining(msg.sender);
    }

    function giftTopUpNonDraining(address to) public payable {
        _topUpNonDraining(to);
    }

    function printNew(
        uint256 parentHeartId
    ) public payable {
        require(ownerOf(parentHeartId) == msg.sender, "ooph");

        uint256 justMinted = StorageLayerProto(
            STORAGE_LAYER_ADDRESS
        ).mint(msg.sender, colorOf(parentHeartId), parentHeartId);
        _initExpiryTime(justMinted);

        LiqRewardsProto(
            LIQUIDATION_REWARDS_ADDRESS
        ).storeReward{value: msg.value/10}(justMinted);
    }

//    function printNewWithCharge(uint256 heartId, uint256 burnMultiplier, HeartColor color) public {
//
//    }

    /********/

    function liquidate(uint256 heartId) public {
        require(balanceOf(msg.sender) > 0, "need active <3's...");
        require(getExpiryTime(heartId) < block.timestamp, "exp_liq");
//        require((getExpiryTime(heartId) - 99*secondsPerIncrement - (15*secondsPerIncrement)/16) < block.timestamp, "exp_liq");

        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_liquidate(heartId);

        LiqRewardsProto(LIQUIDATION_REWARDS_ADDRESS).disburseLiquidationReward(heartId, msg.sender);
    }

    function batchLiquidate(uint256[] calldata heartIds) public {
        require(balanceOf(msg.sender) > 0, "need active <3's...");

        bool allExpired = true;
        for (uint256 i = 0; i < heartIds.length; i++) {
            allExpired = allExpired && (getExpiryTime(heartIds[i]) < block.timestamp);
        }
        require(allExpired, "exp_batch_liq");

        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_batchLiquidate(heartIds);

        LiqRewardsProto(LIQUIDATION_REWARDS_ADDRESS).batchDisburseLiquidationReward(heartIds, msg.sender);
    }

    /********/

    function setBaseBurnRate(uint256 newBaseBurnRate) public onlyOwner {
        baseBurnRate = newBaseBurnRate;
    }

    function setMinSpendIncrement(uint256 newMinSpendIncrement) public onlyOwner {
        minSpendIncrement = newMinSpendIncrement;
    }

    function setTransferTaxRate(uint256 _transferTaxBasisPoints) public onlyOwner {
        transferTaxBasisPoints = _transferTaxBasisPoints;
    }

    /********/

    function _applyTransferTax(uint256 heartId) private {
//        uint256 timeRem = uint256(_heartsInfo[heartId].expiryTime) - block.timestamp;
        uint256 timeRem = _heartsInfo[heartId] - block.timestamp;
        uint256 tax = (timeRem*transferTaxBasisPoints)/10000;

//        _heartsInfo[heartId].expiryTime -= tax;
        _heartsInfo[heartId] -= tax;
    }

    /******************/

    function setInactiveHeartsContract(address _inactiveHearts) public onlyOwner {
        INACTIVE_HEARTS_ADDRESS = _inactiveHearts;
    }

    function setLiquidationRewardsAddress(address liquidationRewardsAddress) public onlyOwner {
        LIQUIDATION_REWARDS_ADDRESS = liquidationRewardsAddress;
    }

    /******************/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /******************/

    function _initExpiryTime(uint256 heartId) private {
        uint256 curTime = block.timestamp;
//        _heartsInfo[heartId].expiryTime = uint64(curTime + secondsPerMonth);
//        _heartsInfo[heartId] = curTime + secondsPerMonth;
        _heartsInfo[heartId] = curTime + (5 minutes); // TODO: revert this after testing
    }

    function initExpiryTime(uint256 heartId) public onlyStorage {
        _initExpiryTime(heartId);
    }

    function batchInitExpiryTime(uint256[] calldata heartIds) public onlyStorage {
//        uint64 curTime = uint64(block.timestamp);
//        uint64 expiryTime = uint64(block.timestamp + secondsPerMonth);
//        uint256 curTime = block.timestamp;
//        uint256 expiryTime = block.timestamp + secondsPerMonth;
        for (uint256 i = 0; i < heartIds.length; i++) {
            uint256 heartId = heartIds[i];
//            _heartsInfo[heartId].expiryTime = expiryTime;
//            _heartsInfo[heartId] = expiryTime;
//            _heartsInfo[heartId] = block.timestamp + secondsPerMonth;
            _heartsInfo[heartId] = block.timestamp + (5 minutes); // TODO: revert this after testing
        }
    }

    /******************/

    function emitTransfer(address from, address to, uint256 tokenId) public onlyStorage {
        emit Transfer(from, to, tokenId);
    }

    function batchEmitTransfers(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata tokenIds
    ) public onlyStorage {
        for (uint256 i = 0; i < from.length; i++) {
            emit Transfer(from[i], to[i], tokenIds[i]);
        }
    }

    function emitApproval(address owner, address approved, uint256 tokenId) public onlyStorage {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(address owner, address operator, bool approved) public onlyStorage {
        emit ApprovalForAll(owner, operator, approved);
    }

    /******************/

    /**
     * Main portion of ERC721-compatible functionality.
     * Modified to function smoothly with the top-level
     * interface of Virtue (Active) Hearts.
    **/

    function balanceOf(address owner) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_balanceOf(true, owner);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_ownerOf(true, tokenId);
    }

    function colorOf(uint256 tokenId) public view returns (HeartColor) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_colorOf(true, tokenId);
    }

    function rawGenomeOf(uint256 tokenId) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_rawGenomeOf(true, tokenId);
    }

    function genomeOf(uint256 tokenId) public view returns (string memory) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_genomeOf(true, tokenId);
    }

    function lastTransferred(uint256 tokenId) public view returns (uint64) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_lastTransferred(true, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_transferFrom(msg.sender, from, to, tokenId);
        _applyTransferTax(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_safeTransferFrom(msg.sender, from, to, tokenId, data);
        _applyTransferTax(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_safeTransferFrom(msg.sender, from, to, tokenId);
        _applyTransferTax(tokenId);
    }

    function gift(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(msg.sender == tx.origin, "no routers, yo");
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_transferFrom(msg.sender, from, to, tokenId);
    }

    function safeGift(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(msg.sender == tx.origin, "no routers, yo");
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_safeTransferFrom(msg.sender, from, to, tokenId, data);
    }

    function safeGift(
        address from,
        address to,
        uint256 tokenId
    ) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_safeTransferFrom(msg.sender, from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_approve(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_getApproved(true, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public {
        StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_setApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_isApprovedForAll(true, owner, operator);
    }

    /********/

    function totalSupply() public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_totalSupply(true);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_tokenOfOwnerByIndex(true, owner, index);
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return StorageLayerProto(STORAGE_LAYER_ADDRESS).storage_tokenByIndex(true, index);
    }

    /********/

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function imageURI(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(imageBase, "/", tokenId.toString(), imagePostfix));
    }

    function animationURI(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(animationBase, "/", tokenId.toString(), animationPostfix));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"Heart #", tokenId.toString(),"\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", imageURI(tokenId), "\",",
                "\"animation_url\":\"", animationURI(tokenId), "\",",
                "\"external_url\":\"", "INSERT EXTERNAL URL HERE", "\",",
                "\"seller_fee_basis_points\":420,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }
}

////////////////////

abstract contract InactiveHearts {

}

//////////

abstract contract CrudeBorneEggs {
    function balanceOf(address owner) public view virtual returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

//////////

abstract contract StorageLayerProto {
    uint256 public _nextToMint;

    function storage_balanceOf(
        bool active,
        address owner
    ) public view virtual returns (uint256);

    function storage_ownerOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (address);

    function storage_colorOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (HeartColor);

    function storage_rawGenomeOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (uint256);

    function storage_genomeOf(
        bool active,
        uint256 tokenId
    ) public view virtual returns (string memory);

    function storage_lastTransferred(
        bool active,
        uint256 tokenId
    ) public view virtual returns (uint64);

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual;

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_approve(
        address msgSender,
        address to,
        uint256 tokenId
    ) public virtual;

    function storage_getApproved(
        bool active,
        uint256 tokenId
    ) public view virtual returns (address);

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool _approved
    ) public virtual;

    function storage_isApprovedForAll(
        bool active,
        address owner,
        address operator
    ) public view virtual returns (bool);

    /********/

    function storage_totalSupply(bool active) public view virtual returns (uint256);

    function storage_tokenOfOwnerByIndex(
        bool active,
        address owner,
        uint256 index
    ) public view virtual returns (uint256);

    function storage_tokenByIndex(
        bool active,
        uint256 index
    ) public view virtual returns (uint256);

    /********/

    function mint(
        address to,
        HeartColor color,
        uint256 lineageToken
    ) public virtual returns (uint256);

    function storage_liquidate(uint256 tokenId) public virtual;

    function storage_batchLiquidate(uint256[] calldata tokenIds) public virtual;

    /********/

    function _exists(bool active, uint256 tokenId) public view virtual returns (bool);
}

//////////

abstract contract LiqRewardsProto {
    function storeReward(uint256 heartId) public payable virtual;

    function disburseLiquidationReward(uint256 heartId, address to) public virtual;

    function batchDisburseLiquidationReward(uint256[] calldata heartIds, address to) public virtual;
}

////////////////////////////////////////

// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - Co-Founder/CTO, Virtue Labs

pragma solidity ^0.8.17;

enum HeartColor {
    Red,
    Blue,
    Green,
    Yellow,
    Orange,
    Purple,
    Black,
    White,
    Length
}