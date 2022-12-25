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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/*
	It saves bytecode to revert on custom errors instead of using require
	statements. We are just declaring these errors for reverting with upon various
	conditions later in this contract.
*/
error ApprovalCallerNotOwnerNorApproved ();
error ApprovalQueryForNonexistentToken ();
error ApproveToCaller ();
error AlreadyOwner ();
error CapExceeded ();
error MintedQueryForZeroAddress ();
error MintToZeroAddress ();
error NotAnAdmin ();
error OwnerIndexOutOfBounds ();
error OwnerQueryForNonexistentToken ();
error TokenIndexOutOfBounds ();
error TransferCallerNotOwnerNorApproved ();
error TransferFromIncorrectOwner ();
error TransferIsLockedGlobally ();
error TransferIsLocked ();
error TransferToNonERC721ReceiverImplementer ();
error TransferToZeroAddress ();
error URIQueryForNonexistentToken ();
error AlreadyInteracted ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT FAMILIA MEAM
	@title A conduit for Christmas cheer.
	@author Tim Clancy
	@author Rostislav Khlebnikov
	@author 0xthrpw

	A Merry Christmas to all, and to all a good night.

	December 24th, 2022.
*/
contract Christmas is
	ERC165, IERC721, IERC721Metadata, Ownable
{
	using Address for address;
	using Strings for uint256;

	/// The name of this ERC-721 contract.
	string public name;

	/// The symbol associated with this ERC-721 contract.
	string public symbol;

	/**
		The metadata URI to which token IDs are appended for generating `tokenUri`
		results. The URI will always naively slap a decimal token ID to the end of
		this provided URI.
	*/
	string public metadataUri;

	/// The maximum number of this NFT that may be minted.
	uint256 public immutable cap;

	/**
		The ID of the next token that will be minted. Our range of token IDs begins
		at one in order to avoid downstream errors with uninitialized mappings.
	*/
	uint256 public nextId = 1;

	/**
		A mapping from token IDs to their holding addresses. If the holding address
		is the zero address, that does not necessarily mean that the token is
		unowned; the ID space of owned tokens is gappy. The `_ownershipOf` function
		handles these gaps for determining the appropriate owners.
	*/
	mapping ( uint256 => address ) private owners;

	/// A mapping from an address to the balance of tokens held by that address.
	mapping ( address => uint256 ) private balances;

	/**
		A mapping from each token ID to an approved address for that specific ID. An
		approved address is allowed to transfer the token with the specified ID on
		behalf of that token's owner.
	*/
	mapping ( uint256 => address ) private tokenApprovals;

	/**
		A mapping from each address to per-address operator approvals. Operators are
		those addresses that have been approved to transfer tokens of any ID on
		behalf of the approver.
	*/
	mapping ( address => mapping( address => bool )) private operatorApprovals;

	/// A mapping to track administrative callers who have been set by the owner.
	mapping ( address => bool ) private administrators;

	/// A mapping from an address to whether or not it has interacted.
	mapping ( address => bool ) public interacted;

	/**
		A modifier to see if a caller is an approved administrator.
	*/
	modifier onlyAdmin () {
		if (_msgSender() != owner() && !administrators[_msgSender()]) {
			revert NotAnAdmin();
		}
		_;
	}

	/**
		Construct a new instance of this ERC-721 contract.

		@param _name The name to assign to this item collection contract.
		@param _symbol The ticker symbol of this item collection.
		@param _metadataURI The metadata URI to perform later token ID substitution
			with.
		@param _cap The maximum number of tokens that may be minted.
	*/
	constructor (
		string memory _name,
		string memory _symbol,
		string memory _metadataURI,
		uint256 _cap
	) {
		name = _name;
		symbol = _symbol;
		metadataUri = _metadataURI;
		cap = _cap;
	}

	/**
		Flag this contract as supporting the ERC-721 standard, the ERC-721 metadata
		extension, and the enumerable ERC-721 extension.

		@param _interfaceId The identifier, as defined by ERC-165, of the contract
			interface to support.

		@return Whether or not the interface being tested is supported.
	*/
	function supportsInterface (
		bytes4 _interfaceId
	) public view virtual override(ERC165, IERC165) returns (bool) {
		return (_interfaceId == type(IERC721).interfaceId)
			|| (_interfaceId == type(IERC721Metadata).interfaceId)
			|| (super.supportsInterface(_interfaceId));
	}

	/**
		Return the total number of this token that have ever been minted.

		@return The total supply of minted tokens.
	*/
	function totalSupply () public view returns (uint256) {
		return nextId - 1;
	}

	/**
		Retrieve the number of distinct token IDs held by `_owner`.

		@param _owner The address to retrieve a count of held tokens for.

		@return The number of tokens held by `_owner`.
	*/
	function balanceOf (
		address _owner
	) external view override returns (uint256) {
		return balances[_owner];
	}

	/**
		Just as Chiru Labs does, we maintain a sparse list of token owners; for
		example if Alice owns tokens with ID #1 through #3 and Bob owns tokens #4
		through #5, the ownership list would look like:

		[ 1: Alice, 2: 0x0, 3: 0x0, 4: Bob, 5: 0x0, ... ].

		This function is able to consume that sparse list for determining an actual
		owner. Chiru Labs says that the gas spent here starts off proportional to
		the maximum mint batch size and gradually moves to O(1) as tokens get
		transferred.

		@param _id The ID of the token which we are finding the owner for.

		@return owner The owner of the token with ID of `_id`.
	*/
	function _ownershipOf (
		uint256 _id
	) private view returns (address owner) {
		if (!_exists(_id)) { revert OwnerQueryForNonexistentToken(); }
		unchecked {
			for (uint256 curr = _id;; curr--) {
				owner = owners[curr];
				if (owner != address(0)) {
					return owner;
				}
			}
		}
	}

	/**
		Return the address that holds a particular token ID.

		@param _id The token ID to check for the holding address of.

		@return The address that holds the token with ID of `_id`.
	*/
	function ownerOf (
		uint256 _id
	) external view override returns (address) {
		return _ownershipOf(_id);
	}

	/**
		Return whether a particular token ID has been minted or not.

		@param _id The ID of a specific token to check for existence.

		@return Whether or not the token of ID `_id` exists.
	*/
	function _exists (
		uint256 _id
	) public view returns (bool) {
		return _id > 0 && _id < nextId;
	}

	/**
		Return the address approved to perform transfers on behalf of the owner of
		token `_id`. If no address is approved, this returns the zero address.

		@param _id The specific token ID to check for an approved address.

		@return The address that may operate on token `_id` on its owner's behalf.
	*/
	function getApproved (
		uint256 _id
	) public view override returns (address) {
		if (!_exists(_id)) { revert ApprovalQueryForNonexistentToken(); }
		return tokenApprovals[_id];
	}

	/**
		This function returns true if `_operator` is approved to transfer items
		owned by `_owner`.

		@param _owner The owner of items to check for transfer ability.
		@param _operator The potential transferrer of `_owner`'s items.

		@return Whether `_operator` may transfer items owned by `_owner`.
	*/
	function isApprovedForAll (
		address _owner,
		address _operator
	) public view virtual override returns (bool) {
		return operatorApprovals[_owner][_operator];
	}

	/**
		Return the token URI of the token with the specified `_id`. The token URI is
		dynamically constructed from this contract's `metadataUri`.

		@param _id The ID of the token to retrive a metadata URI for.

		@return The metadata URI of the token with the ID of `_id`.
	*/
	function tokenURI (
		uint256 _id
	) external view virtual override returns (string memory) {
		if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }
		return bytes(metadataUri).length != 0
			? string(abi.encodePacked(metadataUri, _id.toString()))
			: "";
	}

	/**
		This private helper function updates the token approval address of the token
		with ID of `_id` to the address `_to` and emits an event that the address
		`_owner` triggered this approval. This function emits an {Approval} event.

		@param _owner The owner of the token with the ID of `_id`.
		@param _to The address that is being granted approval to the token `_id`.
		@param _id The ID of the token that is having its approval granted.
	*/
	function _approve (
		address _owner,
		address _to,
		uint256 _id
	) private {
		tokenApprovals[_id] = _to;
		emit Approval(_owner, _to, _id);
	}

	/**
		Allow the owner of a particular token ID, or an approved operator of the
		owner, to set the approved address of a particular token ID.

		@param _approved The address being approved to transfer the token of ID `_id`.
		@param _id The token ID with its approved address being set to `_approved`.
	*/
	function approve (
		address _approved,
		uint256 _id
	) external override {
		address owner = _ownershipOf(_id);
		if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
			revert ApprovalCallerNotOwnerNorApproved();
		}
		_approve(owner, _approved, _id);
	}

	/**
		Enable or disable approval for a third party `_operator` address to manage
		all of the caller's tokens.

		@param _operator The address to grant management rights over all of the
			caller's tokens.
		@param _approved The status of the `_operator`'s approval for the caller.
	*/
	function setApprovalForAll (
		address _operator,
		bool _approved
	) external override {
		operatorApprovals[_msgSender()][_operator] = _approved;
		emit ApprovalForAll(_msgSender(), _operator, _approved);
	}

	/**
		This private helper function handles the portion of transferring an ERC-721
		token that is common to both the unsafe `transferFrom` and the
		`safeTransferFrom` variants.

		This function does not support burning tokens and emits a {Transfer} event.

		@param _from The address to transfer the token with ID of `_id` from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token to transfer.
	*/
	function _transfer (
		address _from,
		address _to,
		uint256 _id
	) private {
		address previousOwner = _ownershipOf(_id);
		bool isApprovedOrOwner = (_msgSender() == previousOwner)
			|| (isApprovedForAll(previousOwner, _msgSender()))
			|| (getApproved(_id) == _msgSender());

		if (!isApprovedOrOwner) { revert TransferCallerNotOwnerNorApproved(); }
		if (previousOwner != _from) { revert TransferFromIncorrectOwner(); }
		if (_to == address(0)) { revert TransferToZeroAddress(); }

		// Clear any token approval set by the previous owner.
		_approve(previousOwner, address(0), _id);

		/*
			Another Chiru Labs tip: we may safely use unchecked math here given the
			sender balance check and the limited range of our expected token ID space.
		*/
		unchecked {
			balances[_from] -= 1;
			balances[_to] += 1;
			owners[_id] = _to;

			/*
				The way the gappy token ownership list is setup, we can tell that
				`_from` owns the next token ID if it has a zero address owner. This also
				happens to be what limits an efficient burn implementation given the
				current setup of this contract. We need to update this spot in the list
				to mark `_from`'s ownership of this portion of the token range.
			*/
			uint256 nextTokenId = _id + 1;
			if (owners[nextTokenId] == address(0) && _exists(nextTokenId)) {
				owners[nextTokenId] = previousOwner;
			}
		}

		// Emit the transfer event.
		emit Transfer(_from, _to, _id);
	}

	/**
		This function performs an unsafe transfer of token ID `_id` from address
		`_from` to address `_to`. The transfer is considered unsafe because it does
		not validate that the receiver can actually take proper receipt of an
		ERC-721 token.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
	*/
	function transferFrom (
		address _from,
		address _to,
		uint256 _id
	) external virtual override {
		_transfer(_from, _to, _id);
	}

	/**
		This is an private helper function used to, if the transfer destination is
		found to be a smart contract, check to see if that contract reports itself
		as safely handling ERC-721 tokens by returning the magical value from its
		`onERC721Received` function.

		@param _from The address of the previous owner of token `_id`.
		@param _to The destination address that will receive the token.
		@param _id The ID of the token being transferred.
		@param _data Optional data to send along with the transfer check.

		@return Whether or not the destination contract reports itself as being able
			to handle ERC-721 tokens.
	*/
	function _checkOnERC721Received(
		address _from,
		address _to,
		uint256 _id,
		bytes memory _data
	) private returns (bool) {
		if (_to.isContract()) {
			try IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _id, _data)
			returns (bytes4 retval) {
				return retval == IERC721Receiver(_to).onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();
				else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	/**
		This function performs transfer of token ID `_id` from address `_from` to
		address `_to`. This function validates that the receiving address reports
		itself as being able to properly handle an ERC-721 token.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
	*/
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _id
	) public virtual override {
		safeTransferFrom(_from, _to, _id, "");
	}

	/**
		This function performs transfer of token ID `_id` from address `_from` to
		address `_to`. This function validates that the receiving address reports
		itself as being able to properly handle an ERC-721 token. This variant also
		sends `_data` along with the transfer check.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
		@param _data Optional data to send along with the transfer check.
	*/
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _id,
		bytes memory _data
	) public override {
		_transfer(_from, _to, _id);
		if (!_checkOnERC721Received(_from, _to, _id, _data)) {
			revert TransferToNonERC721ReceiverImplementer();
		}
	}

	/**
		This function allows the caller to mint a token.

		Note that tokens are always minted sequentially starting at one. That is,
		the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
		Also note that per our use cases the intended recipient of these minted
		items will always be externally-owned accounts and not other contracts. As a
		result there is no safety check on whether or not the mint destination can
		actually correctly handle an ERC-721 token.

		@param _recipient The recipient of the tokens being minted.
	*/
	function mint (
		address _recipient
	) external {
		if (_recipient == address(0)) { revert MintToZeroAddress(); }
		if (nextId > cap) { revert CapExceeded(); }
		if (balances[_recipient] != 0) { revert AlreadyOwner(); }
		if (interacted[_msgSender()]) { revert AlreadyInteracted(); }

		// Flag the message sender as interacting.
		interacted[_msgSender()] = true;

		/*
			Inspired by the Chiru Labs implementation, we use unchecked math here.
			Only enormous minting counts that are unrealistic for our purposes would
			cause an overflow.
		*/
		uint256 startTokenId = nextId;
		unchecked {
			balances[_recipient] += 1;
			owners[startTokenId] = _recipient;

			uint256 updatedIndex = startTokenId;
			emit Transfer(address(0), _recipient, updatedIndex);
			updatedIndex++;
			nextId = updatedIndex;
		}
	}

	/**
		This function allows the caller to take an address from the `_victim`
		and mint them a new item.

		@param _victim The address to steal an item from.
		@param _id The ID of the item to steal from the `_victim`.
	*/
	function swap (
		address _victim,
		uint256 _id
	) external {
		if (_victim == address(0)) { revert MintToZeroAddress(); }
		if (nextId > cap) { revert CapExceeded(); }
		if (balances[_msgSender()] != 0) { revert AlreadyOwner(); }
		if (interacted[_msgSender()]) { revert AlreadyInteracted(); }

		// Flag the message sender as interacting.
		interacted[_msgSender()] = true;

		address previousOwner = _ownershipOf(_id);
		bool isApprovedOrOwner = (_victim == previousOwner);

		if (!isApprovedOrOwner) { revert TransferCallerNotOwnerNorApproved(); }

		/*
			Another Chiru Labs tip: we may safely use unchecked math here given the
			sender balance check and the limited range of our expected token ID space.
		*/
		unchecked {
			balances[_victim] -= 1;
			balances[_msgSender()] += 1;
			owners[_id] = _msgSender();

			/*
				The way the gappy token ownership list is setup, we can tell that
				`_from` owns the next token ID if it has a zero address owner. This also
				happens to be what limits an efficient burn implementation given the
				current setup of this contract. We need to update this spot in the list
				to mark `_from`'s ownership of this portion of the token range.
			*/
			uint256 nextTokenId = _id + 1;
			if (owners[nextTokenId] == address(0) && _exists(nextTokenId)) {
				owners[nextTokenId] = previousOwner;
			}
		}

		// Emit the transfer event.
		emit Transfer(_victim, _msgSender(), _id);

		/*
			Inspired by the Chiru Labs implementation, we use unchecked math here.
			Only enormous minting counts that are unrealistic for our purposes would
			cause an overflow.
		*/
		uint256 startTokenId = nextId;
		unchecked {
			balances[_victim] += 1;
			owners[startTokenId] = _victim;

			uint256 updatedIndex = startTokenId;
			emit Transfer(address(0), _victim, updatedIndex);
			updatedIndex++;
			nextId = updatedIndex;
		}
	}

	/**
		This function allows the original owner of the contract to add or remove
		other addresses as administrators. Administrators may perform mints and may
		lock token transfers.

		@param _newAdmin The new admin to update permissions for.
		@param _isAdmin Whether or not the new admin should be an admin.
	*/
	function setAdmin (
		address _newAdmin,
		bool _isAdmin
	) external onlyOwner {
		administrators[_newAdmin] = _isAdmin;
	}

	/**
		Allow the item collection owner to update the metadata URI of this
		collection.

		@param _uri The new URI to update to.
	*/
	function setURI (
		string calldata _uri
	) external virtual onlyOwner {
		metadataUri = _uri;
	}
}