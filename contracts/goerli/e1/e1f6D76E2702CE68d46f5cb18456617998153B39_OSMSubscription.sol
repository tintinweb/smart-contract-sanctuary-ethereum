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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.17;
import { SetContractable, ContractableData, AllowedContract, AllowedPath } from "./SetContractable.sol";
import "./Lockable.sol";


abstract contract Contractable is Lockable {  
    using SetContractable for ContractableData; // this is the crucial change
    ContractableData contractables;
    function balanceOfAllowance(address wallet) public view returns (uint256) {
        return contractables.balanceOfAllowance(wallet);
    }
    function allowances(address wallet) public view returns (AllowedContract [] memory) {
        return contractables.allowances(wallet);
    }
    function allowContract(address allowed, string calldata urlPath) public {
        contractables.allowContract(allowed, urlPath);
    }
    function pathAllows(string calldata path) public view returns (AllowedPath memory) {
        return contractables.pathAllows(path);
    }
    function revokeContract(address revoked) public {
        contractables.revokeContract(revoked);
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { SetLockable, FindableData, LockableStatus, TokenStatus, TokenNonOwner, TokenNonExistent, MAX_INT } from "./SetLockable.sol";

error WalletLockedByOwner();
error CannotApproveSelf();
error InvalidOwner();
error InvalidTransferRecipient();
error NotApprovedOrOwner();
error TokenAlreadyMinted();
error OnlyOneSubscriptionPerWallet();

abstract contract Lockable is Ownable, ERC165, IERC721 {    
    using SetLockable for FindableData; // this is the crucial change
    FindableData findable;
    
    // mapping(address => Custodian) private _custodian;
    // mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => TokenStatus) internal _tokens;  

    string internal _name;
    string internal _symbol;

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert TokenNonOwner(owner,tokenId);
        }
        return owner;
    }  

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _tokens[tokenId].owner;
    }  

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);
        return _tokens[tokenId].approval;
    }            

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
    }    

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
        

    function custodianOf(uint256 id)
        public
        view
        returns (address)
    {             
        return findable.findCustodian(ownerOf(id));
    }     

    function lockWallet(uint256 id) public {             
        address owner = ownerOf(id);
        findable.lockWallet(owner);
    }

    function unlockWallet(uint256 id) public {  
        address owner = ownerOf(id);             
        findable.unlockWallet(owner);
    }    

    function _forceUnlock(uint256 id) internal {  
        address owner = ownerOf(id);
        LockableStatus storage status = findable.lockableStatus[owner];
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }    

    function setCustodian(uint256 id, address custodianAddress) public {
        address owner = ownerOf(id);         
        findable.setCustodian(custodianAddress,owner);
    }

    function isLocked(uint256 id)
        public
        view
        returns (bool)
    {     
        return findable.lockableStatus[ownerOf(id)].isLocked;
    } 

    function lockedSince(uint256 id)
        public
        view
        returns (uint256)
    {     
        return findable.lockableStatus[ownerOf(id)].lockedAt;
    }     

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return findable.lockableStatus[owner].approvals[operator];
    }    
            
    function approve(address to, uint256 tokenId) public virtual override {     
        if (isLocked(tokenId)) {
            revert WalletLockedByOwner();
        }
        _tokens[tokenId].approval = to;
        emit Approval(ownerOf(tokenId), to, tokenId);        
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {        
        if (findable.lockableStatus[_msgSender()].isLocked) {
            revert WalletLockedByOwner();
        } 
        if (operator == msg.sender) {
            revert CannotApproveSelf();
        }          
        
        findable.lockableStatus[_msgSender()].approvals[operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);

        if (approved) {
            findable.lockableStatus[_msgSender()].approvedAll.push(operator);
        }
    }   

    function _mint(address to, uint256 tokenId) internal virtual {
        if(to == address(0)) {
            revert InvalidOwner();
        }
        
        if(_exists(tokenId)) {
            revert TokenAlreadyMinted();
        }

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        if(_exists(tokenId)) {
            revert TokenAlreadyMinted();
        }

        findable.lockableStatus[to].balance += 1;   

        _tokens[tokenId].owner = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }    

    function safeTransferFrom(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual override {
        if (isLocked(id)) {
            revert WalletLockedByOwner();
        }
    }    

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (isLocked(tokenId)) {
            revert WalletLockedByOwner();
        }
        if(!_isApprovedOrOwner(_msgSender(), tokenId)) { 
            revert NotApprovedOrOwner();
        }

        _transfer(from, to, tokenId);        
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (balanceOf(to) > 0) {
            revert OnlyOneSubscriptionPerWallet();
        } 
        if(ownerOf(tokenId) != from) {
            revert InvalidOwner();
        }
        if(to == address(0)) {
            revert InvalidTransferRecipient();
        }

        _beforeTokenTransfer(from, to, tokenId, 1);

        if(ownerOf(tokenId) != from) {
            revert InvalidOwner();
        }

        // Clear approvals from the previous owner
        delete _tokens[tokenId].approval;


        findable.lockableStatus[from].balance -= 1;
        findable.lockableStatus[to].balance += 1;
        
        _tokens[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }    



    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                findable.lockableStatus[from].balance -= batchSize;           
            }
            if (to != address(0)) {
                findable.lockableStatus[to].balance += batchSize;
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {} 
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }  

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
        return findable.lockableStatus[owner].balance;
    }  

    function ownedTokens(address owner) public view virtual returns (uint256[] memory) {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
        return findable.findTokensOwned(owner);
    }  

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./Subscribable.sol";
import "./Subscribable.sol";

contract OSMSubscription is Subscribable {  

    uint256 totalSupplied = 0;

    address payable private HORDE_AI_WALLET = payable(0x3f1849C19394CfaA0BC85734F3ADEeff155424F5);

    string tokenName = "OSM Subscription Pass";
    string version = "1";
    string tokenSymbol = "OSM";    

    string private revealedBaseURI="ipfs://Qmbw9vH1a9Vadc58Zu5sfNRXUHzAgG1ToMVwkTCFboEbuP";  

    constructor() {

    }      

    function setRecipient(address recipient) external onlyOwner {        
        HORDE_AI_WALLET = payable(recipient);    
    }  

    function setURI(string calldata uri) external onlyOwner {    
        revealedBaseURI = uri;
    }     

    function mint(uint numberOfDays) external payable {  
        if (balanceOf(msg.sender) > 0) {
            revert OnlyOneSubscriptionPerWallet();
        }        
        validateSubscription(numberOfDays);
        HORDE_AI_WALLET.transfer(msg.value);
        uint256 tokenId = totalSupplied+1;
        totalSupplied = tokenId;
        _safeMint(msg.sender,tokenId);
        commitSubscription(tokenId, numberOfDays);        
    }  

    function mintForRecipient(address recipient) external onlyOwner { 
        if (balanceOf(recipient) > 0) {
            revert OnlyOneSubscriptionPerWallet();
        }
        _safeMint(recipient,totalSupplied);    
    }      

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        if(!_exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
        return string(abi.encodePacked(revealedBaseURI, "/", Strings.toString(tokenId)));
    }      

    function totalSupply() public view virtual returns (uint256) {
        return totalSupplied;
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct AllowedContract {
    address addressed;
    string urlPath;
    bool exists;
}

struct AllowedPath {
    address addressed;
    address wallet;
    bool exists;
}

struct ContractableData { 
    mapping(address => AllowedContract[]) contractAllowlist;
    mapping(string => AllowedPath) paths;
    mapping(address => mapping(address => uint256)) contractIndexList;
    
    mapping(address => uint256) allowanceBalances;
}    

library SetContractable {

    error AlreadyAllowed(address requester, address contracted);  
    error PathAlreadyInUse(string path);   
    error PathDoesNotExist(string path);  
    error IsNotAllowed(address requester, address contracted); 
    
    function balanceOfAllowance(ContractableData storage self, address wallet) public view returns (uint256) {        
        return self.allowanceBalances[wallet];
    }     

    function allowances(ContractableData storage self, address wallet) public view returns (AllowedContract [] memory) {
        return self.contractAllowlist[wallet];
    }

    function allowContract(ContractableData storage self, address allowed, string calldata urlPath) public {
        uint256 index = self.contractIndexList[msg.sender][allowed];
        if (index > 0 && self.contractAllowlist[msg.sender][index].exists) {
            revert AlreadyAllowed(msg.sender,allowed);
        }
        if (self.paths[urlPath].exists) {
            revert PathAlreadyInUse(urlPath);
        }        
        self.paths[urlPath] = AllowedPath(allowed,msg.sender,true);   
        if (balanceOfAllowance(self, msg.sender) >= self.contractAllowlist[msg.sender].length) {            
            self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,true));
        } else {
            self.contractAllowlist[msg.sender][balanceOfAllowance(self, msg.sender)] = AllowedContract(allowed,urlPath,true);
            self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self, msg.sender);            
        }
        self.allowanceBalances[msg.sender]++;  
    } 

    function pathAllows(ContractableData storage self, string calldata path) public view returns (AllowedPath memory) {
        if (!self.paths[path].exists) {
            revert PathDoesNotExist(path);
        }
        return self.paths[path];
    }

    function revokeContract(ContractableData storage self, address revoked) public {
        uint256 index = self.contractIndexList[msg.sender][revoked];
        AllowedContract storage revokee = self.contractAllowlist[msg.sender][index];
        if (revokee.addressed != revoked) {
            revert IsNotAllowed(msg.sender,revoked);
        }
        delete self.paths[revokee.urlPath];
        // When the token to delete is the last token, the swap operation is unnecessary
        if (self.contractIndexList[msg.sender][revoked] != balanceOfAllowance(self, msg.sender) - 1) {
            self.contractAllowlist[msg.sender][self.contractIndexList[msg.sender][revoked]] = self.contractAllowlist[msg.sender][balanceOfAllowance(self,msg.sender) - 1]; // Move the last token to the slot of the to-delete token
            self.contractIndexList[msg.sender][self.contractAllowlist[msg.sender][balanceOfAllowance(self,msg.sender) - 1].addressed] = self.contractIndexList[msg.sender][revoked]; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.contractIndexList[msg.sender][self.contractAllowlist[msg.sender][self.contractIndexList[msg.sender][revoked]].addressed];
        self.contractAllowlist[msg.sender].pop();

        self.allowanceBalances[msg.sender]--;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
struct FindableData { 
    // Mapping from owner to tokens
    mapping(address => uint256[]) ownedTokens;

    // Mapping from contract to token ID to index of the owner tokens list
    mapping(address => mapping(uint256 => uint256)) ownedTokensIndex; 

    mapping(address => LockableStatus) lockableStatus;  
} 

struct TokenStatus {
    address owner;
    address approval;
}

struct LockableStatus {
    bool isLocked;
    uint256 lockedAt;
    address custodian;
    uint256 balance;
    mapping(address => bool) approvals;
    address[] approvedAll;
}

uint64 constant MAX_INT = 2**64 - 1;

error HolderRestrictedInformation();

error TokenNonExistent(uint256 tokenId);

error TokenNonOwner(address requester, uint256 tokenId);  

error OnlyCustodianCanLock();

error OnlyOwnerCanSetCustodian();

library SetLockable {

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

    function revokeApprovals(LockableStatus storage status) internal {        
        while (status.approvedAll.length > 0) {     
            address approved = status.approvedAll[status.approvedAll.length-1];  
            status.approvals[approved] = false;      
            emit ApprovalForAll(msg.sender, approved, false);      
            status.approvedAll.pop();                   
        }    
    }
    function lockWallet(FindableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }           
        revokeApprovals(status);        
        status.isLocked = true;
        status.lockedAt = block.timestamp;
    }

    function unlockWallet(FindableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }                   
        
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }

    function setCustodian(FindableData storage self, address custodianAddress, address holder) public {
        if (msg.sender != holder) {
            revert OnlyOwnerCanSetCustodian();
        }    
        LockableStatus storage status = self.lockableStatus[holder];
        status.custodian = custodianAddress;
    }

    function findCustodian(FindableData storage self, address wallet) public view returns (address) {
        return self.lockableStatus[wallet].custodian;
    }

    function balanceOfTokens(FindableData storage self, address wallet) public view returns (uint256) {        
        return self.lockableStatus[wallet].balance;
    }

    function _addTokenToEnumeration(FindableData storage self, address to, uint256 tokenId) internal {
        uint256 length = balanceOfTokens(self,to);
        self.ownedTokens[to][length] = tokenId;
        self.ownedTokensIndex[to][tokenId] = length;
        self.lockableStatus[to].balance++;
    }    

    function _removeTokenFromEnumeration(FindableData storage self, address to, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).        

        // When the token to delete is the last token, the swap operation is unnecessary
        if (self.ownedTokensIndex[to][tokenId] != balanceOfTokens(self,to) - 1) {
            uint256 lastTokenId = self.ownedTokens[to][balanceOfTokens(self,to) - 1];

            self.ownedTokens[to][self.ownedTokensIndex[to][tokenId]] = lastTokenId; // Move the last token to the slot of the to-delete token
            self.ownedTokensIndex[to][lastTokenId] = self.ownedTokensIndex[to][tokenId]; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.ownedTokensIndex[to][tokenId];
        self.ownedTokens[to].pop();
        self.lockableStatus[to].balance--;
    }    

    function findTokensOwned(FindableData storage self, address wallet) public view returns (uint256[] storage) {
        return self.ownedTokens[wallet];
    }  

    function tokenIndex(FindableData storage self, address wallet, uint256 index) public view returns (uint256) {
        return self.ownedTokens[wallet][index];
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
struct ReceivableData { 
    // Mapping from owner to contract to tokens
    mapping(address => mapping(address => uint256[])) receivedTokens;

    // Mapping from contract to token ID to index of the owner tokens list
    mapping(address => mapping(uint256 => uint256)) receivedTokensIndex;    
    
    mapping(address => mapping(address => uint256)) walletBalances;
} 

interface Holdable {
    function balanceOf(address owner) external returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
}

error ReceivedTokenNonExistent(uint256 tokenId);

error ReceivedTokenNonOwner(address requester, uint256 tokenId);  

library SetReceivable {

    function balanceOfWallet(ReceivableData storage self, address wallet, address contracted) public view returns (uint256) {        
        return self.walletBalances[wallet][contracted];
    }

    function receivedFromWallet(ReceivableData storage self, address wallet, address contracted) public view returns (uint256[] memory) {        
        return self.receivedTokens[wallet][contracted];
    }    

    function _addTokenToReceivedEnumeration(ReceivableData storage self, address from, address contracted, uint256 tokenId) internal {
        uint256 length = balanceOfWallet(self,from,contracted);
        if (length >= self.receivedTokens[from][contracted].length) {
            self.receivedTokens[from][contracted].push(tokenId);
        } else {
            self.receivedTokens[from][contracted][length] = tokenId;    
            
        }
        self.receivedTokensIndex[contracted][tokenId] = length;
        self.walletBalances[from][contracted]++;
    }    

    function _removeTokenFromReceivedEnumeration(ReceivableData storage self, address from, address contracted, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).        

        // When the token to delete is the last token, the swap operation is unnecessary
        if (self.receivedTokensIndex[contracted][tokenId] != balanceOfWallet(self,from,contracted) - 1) {
            uint256 lastTokenId = self.receivedTokens[from][contracted][balanceOfWallet(self,from,contracted) - 1];

            self.receivedTokens[from][contracted][self.receivedTokensIndex[contracted][tokenId]] = lastTokenId; // Move the last token to the slot of the to-delete token
            self.receivedTokensIndex[contracted][lastTokenId] = self.receivedTokensIndex[contracted][tokenId]; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.receivedTokensIndex[contracted][tokenId];
        self.receivedTokens[from][contracted].pop();
        self.walletBalances[from][contracted]--;
    }    

    function tokenReceivedByIndex(ReceivableData storage self, address wallet, address contracted, uint256 index) public view returns (uint256) {
        return self.receivedTokens[wallet][contracted][index];
    }    

    function withdraw(ReceivableData storage self, address contracted, uint256[] calldata tokenIds) public {        
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Holdable held = Holdable(contracted);
            if (held.ownerOf(tokenId) != address(this)) {
                revert ReceivedTokenNonOwner(address(this),tokenId);
            }
            uint256 tokenIndex = self.receivedTokensIndex[contracted][tokenId];
            if (tokenReceivedByIndex(self,msg.sender,contracted,tokenIndex) != tokenId) {
                revert ReceivedTokenNonOwner(msg.sender,tokenId);
            }            
            _removeTokenFromReceivedEnumeration(self,msg.sender,contracted,tokenId);
            IERC721(contracted).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./TokenReceiver.sol";

abstract contract Subscribable is TokenReceiver {
    address payable private HORDE_AI_WALLET = payable(0xa399Ffb1C1244FA6B583a20c53FF85501Fb91086);
    mapping(uint256 => uint256) private _subscriptions;
    /// @notice Emitted when a subscription expiration changes
    /// @dev When a subscription is canceled, the expiration value should also be 0.
    event SubscriptionUpdate(uint256 indexed tokenId, uint256 expiration);

    error InvalidNumberOfDays(uint numberOfDays);
    error InvalidAmountForDays(uint numberOfDays, uint256 amount);

    uint internal FOURWEEKS = 28;
    uint internal TWELVEWEEKS = 84;
    uint internal TWENTYFOURWEEKS = 168;
    uint internal FORTYEIGHTWEEKS = 336;

    uint256 internal FOURFEE = 0.02 ether;
    uint256 internal TWELVEFEE = 0.05 ether;
    uint256 internal TWENTYFOURFEE = 0.08 ether;
    uint256 internal FORTYEIGHTFEE = 0.1 ether;    

    function commitSubscription(uint256 tokenId, uint numberOfDays) internal {
        uint256 expiration;
        if (block.timestamp > _subscriptions[tokenId]) {
            expiration = block.timestamp + numberOfDays * 1 days;
        } else {
            expiration = _subscriptions[tokenId] + numberOfDays * 1 days;
        }        
        _subscriptions[tokenId] = expiration;
        emit SubscriptionUpdate(tokenId, expiration);
    }

    function calculateExpiration(uint256 tokenId, uint numberOfDays) public view returns (uint256) {
        if (block.timestamp > _subscriptions[tokenId]) {
            return block.timestamp + numberOfDays * 1 days;
        } 
        return _subscriptions[tokenId] + numberOfDays * 1 days;                     
    }

    function validateSubscription(uint numberOfDays) internal {
        if (numberOfDays != FOURWEEKS &&
            numberOfDays != TWELVEWEEKS && 
            numberOfDays != TWENTYFOURWEEKS && 
            numberOfDays != FORTYEIGHTWEEKS ) {
            revert InvalidNumberOfDays(numberOfDays);
        }
        if ((numberOfDays == FOURWEEKS && msg.value != FOURFEE) ||
            (numberOfDays == TWELVEWEEKS && msg.value != TWELVEFEE) ||
            (numberOfDays == TWENTYFOURWEEKS && msg.value != TWENTYFOURFEE) ||
            (numberOfDays == FORTYEIGHTWEEKS && msg.value != FORTYEIGHTFEE) ) {
            revert InvalidAmountForDays(numberOfDays, msg.value);
        }
    }

    function renewSubscription(uint256 tokenId, uint numberOfDays) external payable {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TokenNonOwner(msg.sender,tokenId);
        }        
        validateSubscription(numberOfDays);
        HORDE_AI_WALLET.transfer(msg.value);
        commitSubscription(tokenId, numberOfDays);
    }    

    function cancelSubscription(uint256 tokenId) external payable {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TokenNonOwner(msg.sender,tokenId);
        }
        delete _subscriptions[tokenId];
        emit SubscriptionUpdate(tokenId, 0);
    }

    function expiresAt(uint256 tokenId) external view returns(uint256) {
        return _subscriptions[tokenId];
    }

    function isRenewable(uint256 tokenId) external view returns(bool) {
        return _exists(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Contractable.sol";
import { SetReceivable, ReceivableData, ReceivedTokenNonExistent, ReceivedTokenNonOwner } from "./SetReceivable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error ReceiverNotImplemented();

abstract contract TokenReceiver is Contractable,IERC721Receiver {
    using Address for address;
    using SetReceivable for ReceivableData; // this is the crucial change
    ReceivableData receivables;

    

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ReceiverNotImplemented();                    
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }        

    function balanceOfWallet(address wallet, address contracted) public view returns (uint256) {
        return receivables.balanceOfWallet(wallet,contracted);
    }  

    function hasReceived(address wallet, address contracted) public view returns (uint256[] memory) {
        return receivables.receivedFromWallet(wallet,contracted);
    }

    function _addTokenToReceivedEnumeration(address from, address contracted, uint256 tokenId) private {
        receivables._addTokenToReceivedEnumeration(from,contracted,tokenId);
    }    

    function _removeTokenFromReceivedEnumeration(address from, address contracted, uint256 tokenId) private {
        receivables._removeTokenFromReceivedEnumeration(from,contracted,tokenId);
    }

    function tokenReceivedByIndex(address wallet, address contracted, uint256 index) public view returns (uint256) {
        return receivables.tokenReceivedByIndex(wallet,contracted,index);
    }

    function withdraw(address contracted, uint256[] calldata tokenIds) public {
        return receivables.withdraw(contracted,tokenIds);
    }
 
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
        _addTokenToReceivedEnumeration(from, msg.sender, tokenId);
        return this.onERC721Received.selector;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if(!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert ReceiverNotImplemented();
        }
    }   

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if(!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ReceiverNotImplemented();
        }        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if(!_isApprovedOrOwner(_msgSender(),tokenId)) {
            revert NotApprovedOrOwner();
        }
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }            
     
}