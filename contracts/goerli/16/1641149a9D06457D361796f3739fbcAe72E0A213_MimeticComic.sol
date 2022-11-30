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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { IMirror } from "../IMirror.sol";

/**
 * @notice This implementation of ERC721 is focused on mirroring the ownership 
 *         of an existing collection to provide the initial ownership record.
 *         With this, functionally the token deployed is attached to the mirror 
 *         --> until being detached. <--
 *         Once the Comic token has moved wallets independently, it functions 
 *         as a normal ERC721 with it's own ownership.
 */
contract ERC721 is 
      Context
    , ERC165
    , IERC721
    , IERC721Metadata 
{
    using Address for address;
    using Strings for uint256;

    ///@dev Token name
    string private _name;

    ///@dev Token symbol
    string private _symbol;

    uint256 internal constant MAX_SUPPLY = 8999;

    ///@dev hard coding in a max range of _owners is required.
    address[MAX_SUPPLY] internal _owners;

    ///@dev Mapping from token ID to approved address
    ///@notice This is outside of the standard implementation as it is 
    ///        token:holder due to an ownership record that mirrors
    ///        the parent. Once a token has been seperated from it's
    ///        parent, approvals are cleared upon transfer. While 
    ///        paired, approvals are tied to the owning address.
    ///        This has been accepted as this is also how operator 
    ///        approvals function by default.
    mapping(uint256 => mapping(address => address)) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    IMirror public mirror;

    constructor(
          string memory name_
        , string memory symbol_
        , address _mirror
    ) {
        _name = name_;
        _symbol = symbol_;
        mirror = IMirror(_mirror);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) 
        public 
        view 
        virtual 
        override(ERC165, IERC165) 
        returns (
            bool
        ) 
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Get the balance of address utilizing the existing ownership *         records of comic books / nerds
     * @dev See {IERC721-balanceOf}.
     * @dev This is extremely gassy and IS NOT intended for on-chain usage.
     * @param account The address to check the total balance of.
     * @return Amount of tokens that are owned by account
     */
    function balanceOf(
        address account
    ) 
        override
        public
        view 
        returns(
            uint256
        ) 
    {
        require(
              account != address(0)
            , "ERC721: balance query for the zero address"
        );

        uint256 counter;

        for (
            uint256 i; 
            i < MAX_SUPPLY; 
            i++
        ) {
            if (ERC721.ownerOf(i) == account)
                counter++;
        }

        return counter;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     * @notice Overrides the default functionality of ownerOf() to utilize 
     *         phantom ownership of the tokens until they are first
     *         transferred.
     */
    function ownerOf(
        uint256 tokenId
    ) 
        public 
        view 
        virtual 
        override 
        returns (
            address
        ) 
    {
        address _owner = _owners[tokenId];
        
        if(_owner != address(0))
            return _owner;

        return mirror.ownerOf(tokenId);
    }
    
    /**
     * @notice Returns the entire ownership record of the comic books up to 
     *         the max supply.
     */
    function owners()
        external 
        view 
        returns(
            address[MAX_SUPPLY] memory
        ) 
    {
        return _owners;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() 
        public 
        view 
        virtual 
        override 
        returns (
            string memory
        ) 
    {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() 
        public 
        view 
        virtual 
        override 
        returns (
            string memory
        ) 
    {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) 
        public 
        view 
        virtual 
        override 
        returns (
            string memory
        ) 
    {
        require(
              _exists(tokenId)
            , "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() 
        internal 
        view 
        virtual 
        returns (
            string memory
        ) 
    {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
          address to
        , uint256 tokenId
    ) 
        public 
        virtual 
        override 
    {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(
              to
            , tokenId
        );
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) 
        public 
        view 
        virtual 
        override 
        returns (
            address
        ) 
    {
        require(
              tokenId < MAX_SUPPLY
            , "ERC721: approved query for nonexistent token"
        );

        address _owner = ERC721.ownerOf(tokenId);

        return _tokenApprovals[tokenId][_owner];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
          address operator
        , bool approved
    ) 
        public 
        virtual 
        override 
    {
        _setApprovalForAll(
              _msgSender()
            , operator
            , approved
        );
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
          address owner
        , address operator
    ) 
        public 
        view 
        virtual 
        override 
        returns (
            bool
        ) 
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
          address from
        , address to
        , uint256 tokenId
    ) 
        public 
        virtual 
        override 
    {
        require(
          _isApprovedOrOwner(
              _msgSender()
            , tokenId
          )
        , "ERC721: transfer caller is not owner nor approved");

        _transfer(
              from
            , to
            , tokenId
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
          address from
        , address to
        , uint256 tokenId
    ) 
        public 
        virtual 
        override 
    {
        safeTransferFrom(
              from
            , to
            , tokenId
            , ""
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
          address from
        , address to
        , uint256 tokenId
        , bytes memory _data
    ) 
        public 
        virtual 
        override 
    {
        require(
          _isApprovedOrOwner(
              _msgSender()
            , tokenId
          )
        , "ERC721: transfer caller is not owner nor approved");

        _safeTransfer(
              from
            , to
            , tokenId
            , _data
        );
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking 
     *      first that contract recipients are aware of the ERC721 protocol to 
     *      prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(
              from
            , to
            , tokenId
        );

        require(
              _checkOnERC721Received(
                  from
                , to
                , tokenId
                , _data
              )
            , "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(
        uint256 tokenId
    ) 
        internal 
        view 
        virtual 
        returns (
            bool
        ) 
    {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
          address spender
        , uint256 tokenId
    ) 
        internal 
        view 
        virtual 
        returns (
            bool
        ) 
    {
        require(
              tokenId < MAX_SUPPLY
            , "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (
               spender == owner 
            || getApproved(tokenId) == spender 
            || isApprovedForAll(owner, spender)
        );
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
          address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        _safeMint(
              to
            , tokenId
            , ""
        );
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
          address to
        , uint256 tokenId
        , bytes memory _data
    ) 
        internal 
        virtual 
    {
        _mint(
              to
            , tokenId
        );
        require(
              _checkOnERC721Received(
                  address(0)
                , to
                , tokenId
                , _data
              )
            , "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
          address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(
              address(0)
            , to
            , tokenId
        );

        _owners[tokenId] = to;

        emit Transfer(
              address(0)
            , to
            , tokenId
        );

        _afterTokenTransfer(
              address(0)
            , to
            , tokenId
        );
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
    function _burn(
        uint256 tokenId
    ) 
        internal 
        virtual 
    {
        address _owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(
              _owner
            , address(0)
            , tokenId
        );

        // Clear approvals
        delete _tokenApprovals[tokenId][_owner];
        emit Approval(
              _owner
            , address(0)
            , tokenId
        );

        delete _owners[tokenId];

        emit Transfer(
              _owner
            , address(0)
            , tokenId
        );

        _afterTokenTransfer(
              _owner
            , address(0)
            , tokenId
        );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
          address from
        , address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        address _owner = ERC721.ownerOf(tokenId);

        require(
              _owner == from
            , "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(
              from
            , to
            , tokenId
        );

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId][_owner];
        emit Approval(
              _owner
            , address(0)
            , tokenId
        );

        _owners[tokenId] = to;

        emit Transfer(
              from
            , to
            , tokenId
        );

        _afterTokenTransfer(
              from
            , to
            , tokenId
        );
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
          address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        address _owner = ERC721.ownerOf(tokenId);

        _tokenApprovals[tokenId][_owner] = to;
        emit Approval(
              _owner
            , to
            , tokenId
        );
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
          address owner
        , address operator
        , bool approved
    ) 
        internal 
        virtual 
    {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) 
        internal 
        returns (
            bool
        ) 
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMimeticComic {
    function loadSeries(
          uint8 _series
        , string memory _description
        , string memory _ipfsHash
        , uint256 _issuanceEnd
    )
        external;

    function lock()
        external;

    function seriesImage(
        uint8 _series
    )
        external
        view
        returns (
            string memory ipfsString
        );

    function seriesMetadata(
          uint8 _series
        , uint256 _tokenId
        , bool redeemed
        , bool exists
        , bool wildcard
        , uint256 votes
    )
        external
        view
        returns (
            string memory metadataString
        );

    function tokenSeries(
        uint256 _tokenId
    )
        external
        view
        returns (
            uint8 series
        );

    function tokenImage(
        uint256 _tokenId
    )
        external
        view
        returns (
            string memory
        );

    function tokenMetadata(
        uint256 _tokenId
    )
        external
        view
        returns (
            string memory
        );

    function focusSeries(
          uint8 _series
        , uint256 _tokenId
    )
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMirror {
    function ownerOf(uint256 tokenId_) 
        external 
        view 
        returns (
            address
        );

    function isOwnerOf(
          address account
        , uint256[] calldata _tokenIds
    ) 
        external 
        view 
        returns (
            bool
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ERC721 } from "./ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IMimeticComic } from "./IMimeticComic.sol";
import { Base64 } from "./Base64.sol"; 
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IMirror } from "./IMirror.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title Mimetic Comic w/ Phantom Ownership
 * @author @nftchance and @masonthechain 
 * @dev Implementation of EIP-721 Non-Fungible Token Standard, including the 
 *      Metadata extension and combining with the usage of Mimetic Metadata, 
 *      Phantom Ownership, and EIP-2309. Many of the features included in this 
 *      contract will be limited time use / reserved for the future. 
 * @dev The use of hooks is not enabled by default which will leave some 
 *      indexers not having the most up to date ownership record. Hooks solve 
 *      this, however full benefits can only be enjoyed after migration.
 */
contract MimeticComic is
      ERC721
    , Ownable
    , IMimeticComic
{
    using Strings for uint8;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                    TOKEN METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    ///@dev Comic series metadata info and redemption time period.
    struct Series {
        string description;     // Token description in displays
        string ipfsHash;        // Comic book cover
        uint256 issuanceEnd;    // When this issue can no longer be focused
    }

    ///@dev Comic series index to series data.
    mapping(uint8 => Series) public seriesToSeries;

    ///@dev Token id to comic series index.
    mapping(uint256 => uint256) internal tokenToSeries;

    ///@dev Number of comic series indexes stored in a single index.
    uint256 public constant PACKED = 64;
    
    ///@dev Number of bytes a series can take up.
    uint256 public constant PACKED_SHIFT = 4;
    
    ///@dev Number of tokens required for end-of-road redemption.
    uint256 public constant REDEMPTION_QUALIFIER = 13;

    ///@dev Nuclear Nerds token id to comic wildcard condition truth.
    mapping(uint256 => bool) internal nerdToWildcard;

    ///@dev The default description of the collection and tokens.
    string private collectionDescription;

    ///@dev Disclaimer message appended to wildcard tokens for buyer safety.
    string private wildcardDescription;

    ///@dev Disclaimer message appended to tokens that have been redeemed.
    string private redeemedDescription;

    ///@dev Management of redemption booleans bitpacked to lower storage needs.
    ///@notice `tokens` as it is a bitpacked mapping returned.
    mapping(uint256 => uint256) public tokensToRedeemed;

    /*//////////////////////////////////////////////////////////////
                      COLLECTION STATE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    ///@dev Controls whether or not wildcards can be loaded.
    bool public wildcardsLocked;

    ///@dev Controls whether or not master actions can be called.
    bool public masterLocked;

    ///@dev Controls all series progression within the collection.
    bool public locked;

    ///@dev Nuclear Nerd contracts that call transferHooks upon transfer.
    mapping(address => bool) public hooks;

    /*//////////////////////////////////////////////////////////////
                            ROYALTY LOGIC
    //////////////////////////////////////////////////////////////*/
    
    ///@dev IPFS hash to the contract URI json.
    string public contractURIHash;

    ///@dev On-chain royalty basis points.
    uint256 public royaltyBasis = 690;
    
    ///@dev The floating point percentage used for royalty calculation.
    uint256 private constant percentageTotal = 10000;

    ///@dev Team address that receives royalties from secondary sales.
    address public royaltyReceiver;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    ///@dev EIP-2309 standard for more efficient ownership indexing events.
    event ConsecutiveTransfer(
          uint256 indexed fromTokenId
        , uint256 toTokenId
        , address indexed fromAddress
        , address indexed toAddress
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error CollectionStateInvalid();
    error CollectionMasterLocked();
    error CollectionWildcardsLocked();

    error HookCallerMismatch();

    error TokenMinted();
    error TokenDoesNotExist();
    error TokenOwnerMismatch();
    error TokenNotWildcard();
    error TokenBundleInvalid();
    error TokenRedeemed();

    error SeriesNotLoaded();
    error SeriesAlreadyLoaded();
    error SeriesAlreadyLocked();
    error SeriesNotLocked();
    error SeriesDirectionProhibited();
    error SeriesBundleInvalid();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
          string memory _name
        , string memory _symbol
        , string memory _seriesZeroDescription
        , string memory _seriesZeroHash
        , string memory _collectionDescription
        , string memory _wildcardDescription
        , string memory _redeemedDescription        
        , address _nerds
        , address _royaltyReceiver
        , string memory _contractURIHash
    ) ERC721(
          _name
        , _symbol
        , _nerds
    ) {
        ///@dev Initialize series 0 that everyone starts with.
        seriesToSeries[0] = Series(
              _seriesZeroDescription
            , _seriesZeroHash
            , 42069
        );

        collectionDescription = _collectionDescription;
        wildcardDescription = _wildcardDescription;
        redeemedDescription = _redeemedDescription;

        royaltyReceiver = _royaltyReceiver;
        contractURIHash = _contractURIHash;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    ///@dev Prevents master locked actions.
    modifier onlyMasterUnlocked() {
        if(masterLocked) revert CollectionMasterLocked();
        _;
    }

    ///@dev Prevents unlocked actions.
    modifier onlyUnlocked() {
        if(locked) revert SeriesAlreadyLocked();
        _;
    }

    ///@dev Prevents locked actions.
    modifier onlyLocked() {
        if(!locked) revert SeriesNotLocked();
        _;
    }

    ///@dev Prevents actions not on a non-loaded series.
    modifier onlyLoaded(uint8 _series) {
        if(bytes(seriesToSeries[_series].ipfsHash).length == 0)
            revert SeriesNotLoaded();
        _;
    }

    ///@dev Prevents actions on tokenIds greater than max supply.
    modifier onlyInRange(uint256 _tokenId) {
        if(_tokenId > MAX_SUPPLY - 1) revert TokenDoesNotExist();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        METADATA INTILIAZATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the Nuclear Nerds team migrate the primary Nuclear
     *         Nerds collection without having to migrate comics and 
     *         having instant updates as the comics would follow the migration.
     *         As soon as utilization has completed the enabling of
     *         master lock will prevent this function from ever being used
     *         again. Contract ownership is delegated to multi-sig for 
     *         maximum security.
     * @notice THIS WOULD NOT BE IMPLEMENTED IF IT WAS NOT NEEDED. ;) 
     *         (Short time horizon on the usage and locking.)
     * @param _mirror The address of the parent token to mirror ownership of.
     * 
     * Requires:
     * - sender must be contract owner
     * - `masterLocked` must be false (default value)
     */
    function loadMirror(
        address _mirror
    )
        public
        virtual
        onlyMasterUnlocked()
        onlyOwner()
    { 
        mirror = IMirror(_mirror);
    }

    /**
     * @notice Loads the wildcards that have direct redemption at the
     *         locking-point for physical transformation.
     * @dev This function can only be ran once so that wildcards cannot
     *      be adjusted past the time of being established.
     * @param _tokenIds The ids of the tokens that are wildcards.
     * 
     * Requires:
     * - sender must be contract owner
     * - `wildcardsLocked` hash must be false (default value).
     */
    function loadWildcards(
        uint256[] calldata _tokenIds
    )
        public
        virtual
        onlyOwner()
    {
        if(wildcardsLocked) revert CollectionWildcardsLocked();
        
        wildcardsLocked = true;

        for(
            uint8 i;
            i < _tokenIds.length;
            i++
        ) {
            nerdToWildcard[_tokenIds[i]] = true;
        }
    }

    /**
     * @notice Allows token holders to emit an event with
     *         'refreshed' ownership that using the mirrored ownership
     *         of the parent token. This way, indexers will pick up the new
     *         ownership for far cheaper still without having to write 
     *         ownership.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     * @dev This is not needed for primary-use however, this is here for
     *      future-proofing backup for any small issues that 
     *      take place upon delivery or future roll outs of new platforms. The 
     *      primary of this use would be that the comic has not been seperated, 
     *      but has found it's in a smart contract that needs the hook to 
     *      complete processing.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - token must NOT be claimed
     * - sender must be owner of the token.
     */
    function refreshToken(
        uint256 _tokenId
    )
        public
        onlyMasterUnlocked()
    {
        if(_exists(_tokenId)) revert TokenMinted();
  
        address _owner = mirror.ownerOf(_tokenId);
        
        if(_msgSender() != _owner) revert TokenOwnerMismatch();

        emit Transfer(
              address(this)
            , _owner
            , _tokenId
        );
    }

    /**
     * @notice Bundle version of token refreshing. This can only be called
     *         if all tokens are still paired and the caller is the owner
     *         of all comics being called.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - all tokens must NOT be claimed.
     * - sender must be owner of all tokens.
     */
    function refreshTokenBundle(
        uint256[] calldata _tokenIds
    )
        public
        onlyMasterUnlocked()
    {
        if(!mirror.isOwnerOf(
              _msgSender()
            , _tokenIds
        )) revert TokenOwnerMismatch();

        for(
            uint256 i;
            i < _tokenIds.length;
            i++
        ) {
            if(_exists(_tokenIds[i])) revert TokenMinted();

            emit Transfer(
                  address(this)
                , _msgSender()
                , _tokenIds[i]
            );
        }
    }

    /**
     * @notice Allows the Nuclear Nerds team to emit an event with
     *         'refreshed' ownership utilizing the mirrored ownership
     *         of the parent token.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     * @dev This is not needed for primary-use however, this is here for
     *      future-proofing backup for any small issues that 
     *      take place upon delivery or future roll outs of new platforms. The 
     *      primary of this use would be that the comic has not been seperated, 
     *      but has found it's in a smart contract that needs the hook to 
     *      complete processing.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner.
     */
    function loadCollectionOwners(
          uint256 _fromTokenId
        , uint256 _toTokenId
    )
        public
        onlyMasterUnlocked()
        onlyOwner()
    {
        for(
            uint256 tokenId = _fromTokenId;
            tokenId < _toTokenId;
            tokenId++
        ) { 
            address _owner = mirror.ownerOf(tokenId);

            emit Transfer(
                  address(0)
                , _owner
                , tokenId
            );

            require(
                _checkOnERC721Received(
                      address(0)
                    , _owner
                    , tokenId
                    , ""
                )
                , "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /**
     * @notice Allows the Nuclear Nerds team to emit Transfer events to a 
     *         a specific target. 
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     * @dev This is not needed for primary-use however,
     *      this is here for future-proofing/backup for any small issues that 
     *      take place upon delivery or future roll outs of new platforms.
     * 
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner.
     * - length of `to` must be the same length as the range of token ids.
     */
    function loadCollectionCalldata(
            uint256 _fromTokenId
          , uint256 _toTokenId
          , address[] calldata _to
    )
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        uint256 length =  _toTokenId - _fromTokenId + 1;

        if(length != _to.length) revert CollectionStateInvalid();

        uint256 index;
        for(
            uint256 tokenId = _fromTokenId;
            tokenId <= _toTokenId;
            tokenId++
        ) { 
            emit Transfer(
                  address(0)
                , _to[index++]
                , tokenId
            );
        }
    }

    /**
     * @notice Utilizes EIP-2309 to most efficiently emit the Transfer events
     *         needed to notify the platforms that this token exists.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner
     */
    function loadCollection2309(
            uint256 _fromTokenId
          , uint256 _toTokenId
    ) 
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        emit ConsecutiveTransfer(
              _fromTokenId
            , _toTokenId
            , address(0)
            , address(this)
        );
    }

    /**
     * @notice Utilizes EIP-2309 to refresh the ownership of tokens in a 
     *         collective batch. This is to be fired after tokens have been 
     *         minted.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner
     */
    function loadCollection2309From(
            uint256 _fromTokenId
          , uint256 _toTokenId
          , address _from
    ) 
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        emit ConsecutiveTransfer(
              _fromTokenId
            , _toTokenId
            , _from
            , address(this)
        );
    }

    /**
     * @notice Utilizes EIP-2309 to most efficiently emit the Transfer events
     *         needed to notify the platforms that this token exists of a 
     *         specific range of token ids AND receivers.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner
     */
    function loadCollection2309To(
            uint256 _fromTokenId
          , uint256 _toTokenId
          , address _to
    ) 
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        emit ConsecutiveTransfer(
              _fromTokenId
            , _toTokenId
            , address(0)
            , _to
        );
    }

    /**
     * @notice Allows owners of contract to initialize a new series of 
     *         the comic as Chapter 12 cannot be published on the same
     *         day as Chapter 1.
     * @dev Fundamentally, a series is 'just' an IPFS hash.
     * @param _series The index of the series being initialized.
     * @param _ipfsHash The ipfs hash of the cover image of the series.
     * @param _issuanceEnd When the issue can no longer be focused.
     * 
     * Requires:
     * - `locked` must be false.
     * - sender must be contract owner
     * `_series` hash must not be set.
     */
    function loadSeries(
          uint8 _series
        , string memory _description
        , string memory _ipfsHash
        , uint256 _issuanceEnd
    )
        override
        public
        virtual
        onlyUnlocked()
        onlyOwner()
    {
        if(bytes(seriesToSeries[_series].ipfsHash).length != 0) {
            revert SeriesAlreadyLoaded();
        }

        seriesToSeries[_series] = Series(
              _description
            , _ipfsHash
            , _issuanceEnd
        );
    }

    /*//////////////////////////////////////////////////////////////
                            LOCK MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Locks the emission of Nuclear Nerd team member called 
     *         loadCollection(x). By default this will remain open,
     *         however with time and the completed release of series
     *         the community may prefer the contract reach a truly 
     *         immutable and decentralized state.
     *
     * Requires:
     * - sender must be contract owner
     */
    function masterLock()
        public
        virtual
        onlyOwner()
    {
        masterLocked = true;
    }

    /**
     * @notice Locks the series upgrading of the collection preventing any
     *         further series from being added and preventing holders
     *         from upgrading their series any further.
     * 
     * Requires:
     * - sender must be contract owner
     */
    function lock()
        override
        public
        virtual
        onlyOwner()
    {     
        locked = true;
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows The Nuclear Nerd team to connect Transfer hooks
     *         to the comic state of a token.
     * @dev Future feature. This can also be completely disabled and 
     *      then locked to prevent any new team additions of hook contracts.
     * @param _hook The address of the contract to accept an incoming 
     *              event from.
     * 
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner.
     */
    function toggleHook(
        address _hook
    )
        public
        onlyMasterUnlocked()
        onlyOwner()
    {
        hooks[_hook] = !hooks[_hook];
    }

    /**
     * @notice Handles the processing when a parent token of this
     *         is transferred. To be procesed within the handling of 
     *         of the parent token. With this, ownership
     *         of the child token will update immediately across all
     *         indexers, marketplaces and tools.
     * @dev Only emits an event for children tokens that haven't been seperated.
     * @param _from The address transferring the parent token.
     * @param _to The address transferring the child token.
     * @param _tokenId The id of the parent:child token being transferred.
     * 
     * Requires:
     * - sender must be an enabled hook contract.
     */
    function transferHook(
          address _from
        , address _to
        , uint256 _tokenId
    )
        public
        virtual
    {
        if(!hooks[_msgSender()]) revert HookCallerMismatch();

        if(!_exists(_tokenId)) {
            delete _tokenApprovals[_tokenId][_from];
            emit Approval(
                  _from
                , address(0)
                , _tokenId
            );

            emit Transfer(
                  _from
                , _to
                , _tokenId
            );
        }
    }

    /**
     * @notice Handles the processing when a parent token of this
     *         is transferred. To be procesed within the handling of 
     *         of the parent token. With this, ownership
     *         of the child token will update immediately across all
     *         indexers, marketplaces and tools.
     * @dev Only emits an event for children tokens that haven't been seperated.
     * @param _from The address transferring the parent token.
     * @param _to The address transferring the child token.
     * @param _tokenId The id of the parent:child token being transferred.
     * 
     * Requires:
     * - sender must be an enabled hook contract.
     */
    function safeTransferHook(
          address _from
        , address _to
        , uint256 _tokenId
        , bytes memory _data
    )
        public
        virtual
    {
        if(!hooks[_msgSender()]) revert HookCallerMismatch();

        if(!_exists(_tokenId)) {
            delete _tokenApprovals[_tokenId][_from];
            emit Approval(
                  _from
                , address(0)
                , _tokenId
            );

            emit Transfer(
                  _from
                , _to
                , _tokenId
            );

            require(
                  _checkOnERC721Received(
                        _from
                      , _to
                      , _tokenId
                      , _data
                  )
                , "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            COMIC METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the ipfs image url.
     * @param _series The index of the series we are getting the image for.
     * @return ipfsString The url to ipfs where the image is represented. 
     * 
     * Requires:
     * - Series index provided must be loaded.
     * - Token of id must exist.
     */
    function seriesImage(
        uint8 _series
    )
        override
        public
        virtual
        view
        onlyLoaded(_series)
        returns (
            string memory ipfsString
        )
    {
        ipfsString = string(
            abi.encodePacked(
                  "ipfs://"
                , seriesToSeries[_series].ipfsHash
            )
        );
    }

    /**
     * @notice Returns the series JSON metadata that conforms to standards.
     * @dev The response from this function is not intended for on-chain usage.
     * @param _series The index of the series we are getting the image for.
     * @return metadataString The JSON string of the metadata that represents
     *                        the supplied series. 
     * 
     * Requires:
     * - Series index provided must be loaded.
     * - Token of id must exist.
     */
    function seriesMetadata(
          uint8 _series
        , uint256 _tokenId
        , bool redeemed
        , bool exists
        , bool wildcard
        , uint256 votes
    ) 
        override
        public
        virtual
        view
        onlyLoaded(_series)
        returns (
            string memory metadataString
        )
    {
        ///@dev Append active series 
        ///@note Nerds special prologue of #00 and all series below 10 are 0 padded
        metadataString = string(
            abi.encodePacked(
                  '{"trait_type":"Series","value":"#'
                , _series < 10 ? string(
                    abi.encodePacked(
                          "0"
                        , _series.toString()
                    )
                ) : _series.toString()
                , '"},'
            )
        );

        ///@dev Reflect the state of the series the comic is currently at
        ///@note Minting if issues is still open -- Limited if issues is closed and no more comics can evolve to this stage (series supply is functionally max supply locked)
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , string(
                    abi.encodePacked(
                         '{"trait_type":"Edition","value":"'
                        , seriesToSeries[_series].issuanceEnd < block.timestamp ? "Limited" : "Minting"
                        , '"},'
                    )
                )
            )
        );
        
        ///@dev Append metadata to reflect the Pairing Status of the token
        ///@note When appended the ownership of the token is automatically updating until the pairing is broken through transferring or claiming.
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , string(
                    abi.encodePacked(
                        '{"trait_type":"Nerd","value":"'
                        , !exists ? string(
                            abi.encodePacked(
                                  "#"
                                , _tokenId.toString()
                            )
                        ) : "Unpaired"
                        , '"},'
                    )
                )
            )
        );

        ///@dev Adds the Schrodinger trait if applicable and reflects the status of usage
        if(wildcard) { 
            metadataString = string(
                abi.encodePacked(
                      metadataString
                    , '{"trait_type":"Schrodinger'
                    , "'"
                    , 's Cat","value":"'
                    , redeemed ? "Dead" : "Alive"
                    , '"},'
                )
            );

        ///@dev Show whether or not the token has been used for the physical comic redemption -- does not show on Schrodingers
        } else { 
            metadataString = string(
                abi.encodePacked(
                      metadataString
                    , string(
                        abi.encodePacked(
                            '{"trait_type":"Status","value":"'
                            , redeemed ? "Redeemed" : "Unredeemed"
                            , '"},'
                        )
                    )
                )
            );
        }

        ///@dev Reflect the current number of Story Votes the owner of a Comic token earns through ownership.
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , string(
                    abi.encodePacked(
                        '{"display_type":"number","trait_type":"Story Votes","value":"'
                        , votes.toString()
                        , '","max_value":"12"}'
                    )
                )
            )
        );
    }

    /**
     * @notice Allows the active series of the token to be retrieved.
     * @dev Pick the number out from where it lives. All this does is pull down
     *      the number that we've stored in the data packed index. With the 
     *      cumulative number in hand we nagivate into the proper bits and 
     *      make sure we return the properly cased number.
     * @param _tokenId The token to retrieve the comic book series for.
     * @return series The index of the series the retrieved comic represents.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenSeries(
        uint256 _tokenId
    )
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            uint8 series
        )
    {
        series = uint8(
            (
                tokenToSeries[_tokenId / PACKED] >> (
                    (_tokenId % PACKED) * PACKED_SHIFT
                )
            ) & 0xF
        );
    }

    /**
     * @notice Get the number of votes for a token.
     * @param _tokenId The comic tokenId to check votes for.
     * @return The number of votes the token actively contributes. 
     * 
     * Requires:
     * - token id must exist
     */
    function tokenVotes(
        uint256 _tokenId
    )
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            uint8
        ) 
    {
        if(nerdToWildcard[_tokenId]) return 12;
        
        return tokenSeries(_tokenId);
    }

    /**
     * @notice Determines if a Comic has been used for redemption.
     * @param _tokenId The comic tokenId being checked.
     * @return bool url to ipfs where the image is represented.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenRedeemed(
        uint256 _tokenId
    )
        public 
        view 
        onlyInRange(_tokenId)
        returns(
            bool
        )
    {
        uint256 flag = (
            tokensToRedeemed[_tokenId / 256] >> _tokenId % 256
        ) & uint256(1);

        return (flag == 1 ? true : false);
    }

    /**
     * @notice Get the ipfs image url for a given token.
     * @param _tokenId The comic tokenId desired to be updated.
     * @return The url to ipfs where the image is represented.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenImage(
        uint256 _tokenId
    )
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            string memory
        )
    {
        return seriesImage(tokenSeries(_tokenId));
    }

    /**
     * @notice Returns the series JSON metadata that conforms to standards.
     * @dev The response from this function is not intended for on-chain usage.
     * @param _tokenId The comic tokenId desired to be updated.
     * @return The JSON string of the metadata that represents
     *         the supplied series.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenMetadata(
        uint256 _tokenId
    ) 
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            string memory
        )
    {
        return seriesMetadata(
              tokenSeries(_tokenId)
            , _tokenId
            , tokenRedeemed(_tokenId)
            , _exists(_tokenId)
            , nerdToWildcard[_tokenId]
            , tokenVotes(_tokenId)
        );
    }

    /**
     * @notice Generates the on-chain metadata for each non-fungible 1155.
     * @param _tokenId The id of the token to get the uri data for.
     * @return uri encoded json in the form of a string detailing the 
     *         retrieved token.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenURI(
        uint256 _tokenId
    )
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            string memory uri
        )        
    { 
        uint8 series = tokenSeries(_tokenId);

        uri = seriesToSeries[series].description;

        if(nerdToWildcard[_tokenId]) { 
            uri = string(
                abi.encodePacked(
                      uri
                    , wildcardDescription
                )
            );
        }

        if(tokenRedeemed(_tokenId)) { 
            uri = string(
                abi.encodePacked(
                      uri
                    , redeemedDescription
                )
            );
        }

        // Build the metadata string and return it as encoded data
        uri = string(
            abi.encodePacked(
                  "data:application/json;base64,"
                , Base64.encode(
                    bytes(  
                        abi.encodePacked(
                              '{"name":"Nuclear Nerds Comic #'
                            , _tokenId.toString()
                            , '","description":"'
                            , collectionDescription
                            , uri
                            , '","image":"'
                            , seriesImage(series)
                            , '?owner='
                            , Strings.toHexString(
                                    uint160(ownerOf(_tokenId))
                                , 20
                             )
                            , '","attributes":['
                            , tokenMetadata(_tokenId)
                            , ']}'
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Helper function to assist in determining whether a Nuclear Nerd
     *         has been used to claim a comic.
     * @dev This function will return false if even one of the tokenId 
     *      parameters has been previously used to claim.
     * @param _tokenIds The tokenIds of the Nuclear Nerds being checked 
     *                  for their claiming status.
     */
    function isClaimable(
        uint256[] calldata _tokenIds
    ) 
        public
        view
        returns (
            bool
        )
    {
        for(
            uint256 i; 
            i < _tokenIds.length;
            i++
        ) {
            if(_exists(_tokenIds[i])) 
                return false;
        }

        return true;
    }

    /**
     * @notice Helper function to used to determine if an array of 
     *         tokens can still be used to redeem a physical.
     * @dev This function will return false if even one of the tokenId
     *      parameters has been previously used to claim.
     * @param _tokenIds The tokenIds of the comcis being checked.
     */
    function isRedeemable(
        uint256[] calldata _tokenIds
    )
        public
        view 
        returns ( 
            bool
        )
    {
        for(
            uint256 i;
            i < _tokenIds.length;
            i++ 
        ) { 
            if(tokenRedeemed(_tokenIds[i]))
                return false;
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            COMIC CONTROL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows holders of a Nuclear Nerd to claim a comic.
     * @dev This mint function acts as the single token call for claiming
     *      multiple tokens at a time.
     * @param _tokenId The tokenId of the Nuclear Nerd being used 
     *                  to claim a Comic.
     * 
     * Requires:
     * - sender must be owner of mirrored token.
     * - token of id must NOT exist.
     */
    function claimComic(
        uint256 _tokenId
    )
        public
        virtual
    {
        if (
            mirror.ownerOf(_tokenId) != _msgSender()
        ) revert TokenOwnerMismatch();

        _mint(
              _msgSender()
            , _tokenId
        );
    }    

    /**
     * @notice Allows holders of Nuclear Nerds to claim a comic for each 
     *         Nerd they own.
     * @dev This function should be used with reason in mind. A holder with 100 
     *      Nerds is far more likely to have a Nerd purchased in a
     *      long-pending transaction given low gas urgency. 
     * @param _tokenIds The tokenIds of the Nuclear Nerds being used 
     *                  to claim Comics.
     * 
     * Requires:
     * - sender must be owner of all mirrored tokens.
     * - all ids of token must NOT exist.
     */
    function claimComicBundle(
          uint256[] calldata _tokenIds
    ) 
        public
        virtual 
    {
        if(!mirror.isOwnerOf(
              _msgSender()
            , _tokenIds
        )) revert TokenOwnerMismatch();

        for(
            uint256 i; 
            i < _tokenIds.length;
            i++
        ) {
            _mint(
                  _msgSender()
                , _tokenIds[i]
            );
        }
    }
    
    /**
     * @notice Focuses a specific comic on a specific series.
     * @dev Every _series has at most 8 bits so we can bitpack 32 of them 
     *      (8 * 32 = 256) into a single storage slot of a uint256. 
     *      This saves a significant amount of money because setting a 
     *      non-zero slot consumes 20,000 gas where as it only costs 5,000 
     *      gas. So it is cheaper to store 31/32 times.
     * 
     * Requires:
     * - series being upgraded to must have been loaded.
     * - message sender must be the token owner.
     * - comic cannot be downgraded.
     * - cannot upgrade to series with closed issuance.
     */
    function _focusSeries(
          uint8 _series
        , uint256 _tokenId
    )
        internal
        onlyLoaded(_series)
    {        
        if(_msgSender() != ownerOf(_tokenId)) revert TokenOwnerMismatch();
    
        uint256 seriesIndex = _tokenId / PACKED;
        uint256 bitShift = (_tokenId % PACKED) * PACKED_SHIFT;

        if(uint8(
            (tokenToSeries[seriesIndex] >> bitShift) & 0xF
        ) > _series) revert SeriesDirectionProhibited();

        if(seriesToSeries[_series].issuanceEnd < block.timestamp) {
            revert SeriesAlreadyLocked();
        }

        tokenToSeries[seriesIndex] =
              (tokenToSeries[seriesIndex] & ~(0xF << bitShift)) 
            | (uint256(_series) << bitShift);
    }

    /**
     * @notice Allows the holder of a comic to progress
     *         the comic token to a subsequent issued series.
     * @dev Once a comic has progressed to the next issued series,
     *      it cannot be reverted back to a previous series.
     * @dev A token can progress from an early series to any series
     *      in the future provided Comics have not been locked.
     * @param _series The desired series index.
     * @param _tokenId The comic tokenId desired to be updated.
     *
     * Requires:
     * - series of index must be unlocked.
     */
    function focusSeries(
          uint8 _series
        , uint256 _tokenId
    ) 
        override
        public
        virtual
        onlyUnlocked()
    {
        _focusSeries(
              _series
            , _tokenId
        );
    }
 
    /**
     * @notice Allows the holder to focus multiple comics with multiple series
     *         in the same transaction so that they can update a series of
     *         comics all at once without having to go through pain.
     * @dev Once a comic has progressed to the next issued series,
     *      it cannot be reverted back to a previous series.
     * @dev A token can progress from an early series to any series
     * @param _series The array of desired series to be focused by tokenId.
     * @param _tokenIds The array of tokenIds to be focused.
     *
     * Requires:
     * - series of index must be unlocked.
     * - series array and token id array lengths must be the same.
     */
    function focusSeriesBundle(
          uint8[] calldata _series
        , uint256[] calldata _tokenIds
    ) 
        public
        virtual
        onlyUnlocked()
    {
        if(_series.length != _tokenIds.length) revert SeriesBundleInvalid();

        for(
            uint256 i;
            i < _series.length;
            i++
        ) {
            _focusSeries(
                  _series[i]
                , _tokenIds[i]
            );
        }
    }

    /**
    * @notice Toggles the redemption stage for a token id.
     * @dev Implements the boolean bitpacking of 256 values into a single 
     *      storage slot. This means, that while we've created a gas-consuming
     *      mechanism we've minimized cost to the highest extent. A boolean is 
     *      only 1 bit of information, but is typically 8 bits in solidity.
     *      With bitpacking, we can stuff 256 values into a single storage slot
     *      making it cheaper for the following 255 comics. This cost-savings 
     *      scales through the entire collection.
     * 
     * Requires:
     * - message sender must be the token owner
     * - cannot already be redeemed
     */
    function _redeemComic(
        uint256 _tokenId
    )
        internal
    {
        if(ownerOf(_tokenId) != _msgSender()) revert TokenOwnerMismatch();

        uint256 tokenIndex = _tokenId / 256;
        uint256 tokenShift =  _tokenId % 256;

        if(((
            tokensToRedeemed[tokenIndex] >> tokenShift
        ) & uint256(1)) == 1) revert TokenRedeemed();

        tokensToRedeemed[tokenIndex] = (
            tokensToRedeemed[tokenIndex] | uint256(1) << tokenShift
        );
    }

    /**
     * @notice Allows a holder to redee an array of tokens.
     * @dev The utilization of this function is not fully gated, though the 
     *      return for 'redeeming comics' is dependent on external criteria. 
     *      Nothing is earned or entitled by the redemption of a Comic unless 
     *      in the defined times and opportunities.
     * @dev Interface calls are extremely expensive. It is worthwhile to use 
     *      the higher level processing that is available.
     * @param _tokenIds The ids of the tokens to redeem.
     *
     * Requires:
     * - collection evolution must be locked preventing any future focusing.
     * - token ids array length must be equal to redemption capacity
     */
    function redeemComics(
          uint256[] calldata _tokenIds
    ) 
        public
        virtual
        onlyLocked()
    {
        if(
            _tokenIds.length != REDEMPTION_QUALIFIER
        ) revert TokenBundleInvalid();

        for (
            uint256 i; 
            i < _tokenIds.length; 
            i++
        ) {
            _redeemComic(_tokenIds[i]);
        }
    }

    /**
     * @notice Allows a wildcard holder to redeem their token.
     * @dev The utilization of this function is not fully gated, though the
     *      return for 'redeeming comics' is dependent on external criteria. 
     *      Nothing is earned or entitled by the redemption of a Comic unless 
     *      in the defined times and opportunities.
     * @dev Interface calls are extremely expensive. It is worthwhile to use 
     *      the higher level processing that is available.
     * @param _tokenId The id of the token to redeem.
     *
     * Requires:
     * - collection evolution must be locked preventing any future focusing.
     * - token id must be a wildcard representative of a wildcard Nuclear Nerd.
     */
    function redeemWildcardComic(
        uint256 _tokenId
    ) 
        public
        virtual
        onlyLocked()
    {   
        if(!nerdToWildcard[_tokenId]) revert TokenNotWildcard();

        _redeemComic(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) 
        public 
        view 
        virtual 
        override
        returns (
            bool
        ) 
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IMimeticComic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC2981 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Allows the Nuclear Nerds team to adjust contract-level metadata
     * @param _contractURIHash The ipfs hash of the contract metadata
     */
    function setContractURI(
        string memory _contractURIHash
    )
        public
        onlyOwner()
    { 
        contractURIHash = _contractURIHash;
    }

    /**
     * @notice Returns the accesible url of the contract level metadata
     */
    function contractURI() 
        public 
        view 
        returns (
            string memory
        ) 
    {
        return string(
            abi.encodePacked(
                  "ipfs://"
                , contractURIHash
            )
        );
    }

    /**
    * @notice Allows the Nuclear Nerds team to adjust where royalties
    *         are paid out if necessary.
    * @param _royaltyReceiver The address to send royalties to
    */
    function setRoyaltyReceiver(
        address _royaltyReceiver
    ) 
        public 
        onlyOwner() 
    {
        require(
              _royaltyReceiver != address(0)
            , "Royalties: new recipient is the zero address"
        );

        royaltyReceiver = _royaltyReceiver;
    }

    /**
    * @notice Allows the Nuclear Nerds team to adjust the on-chain
    *         royalty basis points.
    * @param _royaltyBasis The new basis points earned in royalties
    */
    function setRoyaltyBasis(
        uint256 _royaltyBasis
    )
        public
        onlyOwner()
    {
        royaltyBasis = _royaltyBasis;
    }

    /**
    * @notice EIP-2981 compliant view function for marketplaces
    *         to calculate the royalty percentage and what address
    *         receives them. 
    * @param _salePrice Total price of secondary sale
    * @return address of receiver and the amount of payment to send
    */
    function royaltyInfo(
          uint256
        , uint256 _salePrice
    ) 
        public 
        view 
        returns (
              address
            , uint256
        ) 
    {
        return (
              royaltyReceiver
            , (_salePrice * royaltyBasis) / percentageTotal
        );
    }
}