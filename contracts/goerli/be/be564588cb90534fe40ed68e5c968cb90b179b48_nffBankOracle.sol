/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// File: @openzeppelin/contracts/utils/math/SignedSafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
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
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

// File: contracts/nffMain.sol



pragma solidity ^0.8.7;




contract nffMain{
    /*__________________________________Shared variabes______________________________________ */

    address public priceOracleAddr;
    address public bankOracleAddr;
    address public owner;
    /*_____________________________________From NFT Bank____________________________________ */
    uint256 public minDeposit;
    uint256 public nftFloorPrice;
    uint256 public nftLiquidationPrice;
    uint256 public discountFactor;
    //Use to store user's eth balance
    mapping(address => uint256) addressToBalances;
    mapping(address => uint256) addressToPrinciple;
    //Use to check user's address existance
    mapping(address => bool) userChecker;
    //Use to check if an NFT colelction is supported
    mapping(address => bool) supportedNft;
    //Use to store key (address) of people who deposit ETH
    address[] private ethDepositorList;
    //For saving supported NFT (Can be implemented by saving every data from liquidated NFT)
    address[] private supportedNftList;
    /*__________________________________Bank Risk Management_________________________________ */
    uint256 public reserveRatio; //To guarantee the bank have enough eth for withdraw
    uint256 public userDeposit; //Total users deposite value
    uint256 public payoutRatio; //payout ratio of this contract
    uint256 public LoanToValue; //LTV ratio that control risk of a loan
    int256 public netProfit; //Profit that the contract made from nft loan (can be negative)
    uint256 public APY; //APY in uint256
    /*____________________________________From NFT Loan______________________________________ */
    /*
    * Check if a loan is due every day at 00:00, if current time > due time, the loan is defaulted
    * Future development: Implement BokkyPooBahsDateTimeLibrary https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    */
    //defaultRate = number of times that the customer can pay their loan later
    uint256 public defaultRate;
    uint256 public baseInterstRate;
    //The Loan structure InLoan = instalment Loan
    //The Nft token uniquely define the Loan
    struct InLoan{
        address loanOwner;
        uint256 nftValue; //How much this contract contribute to the loan
        uint256 outstandBalance; //Outstanding Balance of the customer
        uint256 debt;
        uint256 startTime;
        uint256 dueTime;
        uint256 nextPayDay;
        uint256 baseCumuRate;
        uint256 cumuRate;
        uint256 defaultCount;
        uint256 LoanRate;
        NftToken nft;
    }
    struct NftToken{
        address nftContractAddr;
        uint256 tokenId;
    }
    //For mapping between owner and thier loans
    mapping(address => InLoan[]) addressToInLoans;
    //For mapping between customers and the number of loans
    mapping(address => uint256) customAddrToNumLoans;
    //For tracking customers, no dups in this array
    address[] private customerList;
    //For tracking which nft is in a loan, no dups in this array
    NftToken[] private nftInLoan;
    //For storing a list of Loan to be removed can be private
    InLoan[] private loanRemoveList;

    using SafeMath for uint256;
    using SignedSafeMath for int256;

    constructor(){
        owner = msg.sender;
        //Below from NFT Bank
        minDeposit = 0.5 ether;
        //initial discount factor
        discountFactor = 70;
        //initial defaultRate (Max number of default)
        defaultRate = 3;
        //initial interstRate in percent times 10^18
        baseInterstRate = 5000000000000000000;
        //initial reserve ratio in percent
        reserveRatio = 50;
        //initial LTV ratio in percent
        LoanToValue = 60;
        //initial Payout ratio in percent
        payoutRatio = 90;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry you are not the owner");
        _;
    }

/*_____________________________Below from NFT Banking____________________________ */

/*__________________________________ETH Banking_________________________________ */

    //User deposite ETH through this function
    function depositETH() external payable{
        require(msg.value >= minDeposit, "minimum deposit requirement not met");
        addressToBalances[msg.sender] += msg.value;
        addressToPrinciple[msg.sender] += msg.value;
        userChecker[msg.sender] = true;
        if(isUserInList(msg.sender) == false){
            ethDepositorList.push(msg.sender);
        }
        userDeposit += msg.value;
    }

    //Called by Oracle
    function paidInterest() internal{
        calAPY();
        for (uint256 i = 0; i < ethDepositorList.length; i++){
            uint256 interest = addressToBalances[ethDepositorList[i]].mul(APY).div(10**18).div(365).div(100);
            addressToBalances[ethDepositorList[i]] += interest;
            netProfit -= int256(interest);
            userDeposit += interest;
        }
    }

    function calAPY() internal{
        if (netProfit <= 0){
            APY = 0;
        }
        else{
            APY = uint256(netProfit).mul(10**18).mul(payoutRatio).div(100).mul(100).div(userDeposit);
        }
    }

    function acceptLiquidation(uint256 liquidatePrice) public view returns(bool){
        if (address(this).balance < liquidatePrice){
            return false;
        }
        if(address(this).balance - liquidatePrice >= userDeposit.mul(reserveRatio).div(100)){
            return true;
        }
        else{
            return false;
        }
    }

    //User withdrawETH through this function
    function withdrawETH(uint256 amount) external{
        require (addressToBalances[msg.sender] >= amount);
        addressToBalances[msg.sender] -= amount;
        if(addressToBalances[msg.sender] == 0){
            for(uint256 i = 0; i < ethDepositorList.length; i++){
                if(ethDepositorList[i] == msg.sender){
                    ethDepositorList[i] = ethDepositorList[ethDepositorList.length - 1];
                    ethDepositorList.pop();
                }
            }
        }
        if (amount > addressToPrinciple[msg.sender]){
            addressToPrinciple[msg.sender] = 0;
        }
        else{
            addressToPrinciple[msg.sender] -= amount;
        }
        payable(msg.sender).transfer(amount);
        userDeposit -= amount;
    }

/*__________________________________NFT Liquidating________________________________ */

    function liquidateNFT(address contractAddr, uint256 tokenId) external payable{
        require(acceptLiquidation(nftLiquidationPrice), "Sorry we do not accept anymore NFT right now");
        //First check if the NFT collection is verified on our platform
        require(supportedNft[contractAddr], "Your NFT collection is not verified");
        ERC721 Nft = ERC721(contractAddr);
        //Second check if the user approved this contract to use the NFT token
        require(Nft.isApprovedForAll(msg.sender, address(this)), "This contract must be approved to use your NFT");
        //Third check if the user own the NFT token
        require(Nft.ownerOf(tokenId) == msg.sender, "caller must own the NFT");
        //All statisfied then call transfer
        Nft.transferFrom(msg.sender, address(this), tokenId);
        //Set condition on amount paid later
        payable(msg.sender).transfer(nftLiquidationPrice);
        //Add to NFT cost
        netProfit -= int256(nftLiquidationPrice);
    }

/*__________________________________Getter_____________________________________ */
    
    //Check Individual balance for GUI
    function getUserBalance(address addr) public view returns(uint256){
        return addressToBalances[addr];
    }

    function getUserPrinciple(address addr) public view returns(uint256){
        return addressToPrinciple[addr];
    }

    //Check all user list for debug
    function getethDepositorList() public view returns(address[] memory){
        return(ethDepositorList);
    }

    function getsupportedNftList() public view returns(address[] memory){
        return(supportedNftList);
    }

/*__________________________________Setter_____________________________________ */
    
    //Add a collection to the supportedNFT array (onlyOwner)
    function addSuppCollection(address contractAddr) external onlyOwner{
        if (supportedNft[contractAddr] != true){
            supportedNftList.push(contractAddr);
        }
        supportedNft[contractAddr] = true;
    }

    //Remove collection from the supportedNFT array (onlyOwner)
    function removeSuppCollection(address contractAddr) external onlyOwner{
        for (uint256 i = 0; i<supportedNftList.length; i++){
            if(supportedNftList[i] == contractAddr){
                supportedNftList[i] = supportedNftList[supportedNftList.length - 1];
                supportedNftList.pop();
            }
        }
    }

    //Set minimum deposit amount (onlyOwner)
    // Please use https://eth-converter.com/ to see convertion rate
    function setMinDeposit(uint256 amountInWei) external onlyOwner{
        minDeposit = amountInWei;
    }

    // Set the orcacle address (onlyOwner)
    // Should be called using Constructor, Deploy oracle first then this contract to get the oracle contract address
    function setOracleAddr(address priceOracle, address bankOracle) external onlyOwner{
        priceOracleAddr = priceOracle;
        bankOracleAddr = bankOracle;
    }

    //only allow the oracle contract to call this
    function setAssetPrice(uint256 amount) external{
        require(msg.sender == priceOracleAddr, "Only the price orcacle contract can call this function");
        nftFloorPrice = amount;
        nftLiquidationPrice = amount.mul(discountFactor).div(100);
    }

    /*
    * Set a discount factor in terms of percentage (Used in setLiquidationPrice)
    * percentage = 80 implies a 80% discount on the OpenSea floor price
    * if OpenSea floor Price = 10e percentage = 80 implies that the bank will only
    * pay 8e for the NFT
    * Only take integer no floating point please
    */
    function setDiscountFactor(uint256 percentage) external onlyOwner{
        discountFactor = percentage;
    }

/*__________________________________Other_____________________________________ */
    
    //Check if a user is in this list 
    function isUserInList(address input) private view returns(bool){
        for (uint256 i = 0;  i < ethDepositorList.length; i++){
            if (ethDepositorList[i] == input){
                return true;
            }
        }
        return false;
    }

/*___________________________Below from NFT Loaning____________________________ */

/*__________________________________NFT Loaning_________________________________ */
    //For starting a nft instalment loan. block.timestamp gives you the current time in unix timestamp
    //Please use https://www.unixtimestamp.com/ for conversion
    function startLoan(address nftContractAddr, uint256 tokenId, uint256 dayTillDue) external payable{
        require(msg.value < nftFloorPrice, "Please consider direct buying instead of loan");
        require(acceptLoan(nftFloorPrice, msg.value), "Minimum down payment requirement not met");
        NftToken memory token = NftToken(nftContractAddr, tokenId);
        require(checkNftBalance(token), "The contract doesnt own this NFT");
        require(!checkNftInList(token), "The NFT you selected is on others instalment loan");

        //Create the loan, msg.value = down payment
        uint256 dueTime = block.timestamp + 86400*dayTillDue;
        uint256 loanInterest = setLoanInterest(nftFloorPrice, msg.value);
        uint256 baseCRate = calBaseCumuRate(block.timestamp, dueTime);
        InLoan memory temp = InLoan(
            msg.sender, //loanOwner
            nftFloorPrice, //nftValue
            nftFloorPrice - msg.value, //outstanding balance
            nftFloorPrice - msg.value, //debt
            block.timestamp, //start time
            dueTime, //due time
            block.timestamp + 86400, //next pay day
            baseCRate,
            baseCRate,
            0,
            loanInterest, 
            token
        ); //block.timestamp = now unix time stamp, 86400 = 1 day

        //Append the loan into the array inside the map
        addressToInLoans[msg.sender].push(temp);
        //Append the sender address to the customer list if he is a new customer
        if(!checkCustomerInList(msg.sender)){
            customerList.push(msg.sender);
        }
        //Increase the customers number of loan
        customAddrToNumLoans[msg.sender] += 1;
        //Append the nft to the loaning list
        nftInLoan.push(token);
        //Add to NFT Loan Profit
        netProfit += int256(msg.value);
    }

    function calBaseCumuRate(uint256 start, uint256 end) internal pure returns(uint256){
        uint256 tempp = 10**18;
        return tempp.div((end-start).div(86400));
    }

    //For User to call for repaying the loan
    function repayLoan(address nftContractAddr, uint256 tokenId) external payable{
        NftToken memory token = NftToken(nftContractAddr, tokenId);
        //Check if the loan exist in the beginning
        require(checkLoanExist(msg.sender,token), "No such loan, please check the NFT contract or tokenId");
        //A for loop to locate the loan matching the NFT contractaddr and tokenID
        for(uint256 i = 0; i<addressToInLoans[msg.sender].length; i++){
            if (addressToInLoans[msg.sender][i].nft.nftContractAddr == nftContractAddr && 
                addressToInLoans[msg.sender][i].nft.tokenId == tokenId){
                require(msg.value <= addressToInLoans[msg.sender][i].outstandBalance, "You have overpaid the loan");
                //Decrease the outstanding balance of the matching loan
                addressToInLoans[msg.sender][i].outstandBalance -= msg.value;
                //Add to NFT Loan Profit
                netProfit += int256(msg.value);
                //Check if the loan is fully paid
                if (addressToInLoans[msg.sender][i].outstandBalance <= 0){
                    //Transfer the nft
                    transferNft(addressToInLoans[msg.sender][i].nft, msg.sender);
                    //Remove the loan
                    removePaidLoan(msg.sender,token);
                }
            }
        }
    }

    //Can be internal
    function acceptLoan(uint256 nftValue, uint256 downPayment) internal view returns(bool){
        if (downPayment <= 0){
            return false;
        }
        //Calculate the percentage of eth that this contract contribute to the loan and compare to the LoanToValue (60%) requirement
        else if( (nftValue - downPayment).mul(100).div(nftValue) > LoanToValue ){
            return false;
        }
        else{
            return true;
        }
    }

    function setLoanInterest(uint256 nftValue, uint256 downPayment) internal view returns(uint256){
        //Every 10% above LoanToValue, decrease 0.2% in interest rate
        if ( (nftValue - downPayment).mul(100).div(nftValue) >= LoanToValue){
            return baseInterstRate;
        }
        else{
            return baseInterstRate - ( LoanToValue - (nftValue - downPayment).mul(100).div(nftValue) ).mul(10**18).mul(2).div(100);
        }
    }

    function buyNFT(address nftContractAddr, uint256 tokenId) external payable{
        NftToken memory token = NftToken(nftContractAddr, tokenId);
        require(supportedNft[nftContractAddr], "Your NFT collection is not verified");
        require(checkNftBalance(token), "The contract doesnt own this NFT");
        require(!checkNftInList(token), "The NFT you selected is on others instalment loan");
        require(msg.value == nftFloorPrice, "You pay too much or too less");
        transferNft(token,msg.sender);
        //Add to NFT Profit
        netProfit += int256(msg.value);
    }

    //Only callable by the contract to remove the paid loan from the addressToInLoans mapping InLoan[] aray
    function removePaidLoan(address addr, NftToken memory token) private{
        //A for loop to locate the loan matching the the NFT contractaddr and tokenID
        for(uint256 i = 0; i<addressToInLoans[addr].length; i++){
            //Check if the loan exist
            if (addressToInLoans[addr][i].nft.tokenId == token.tokenId &&
                addressToInLoans[addr][i].nft.nftContractAddr == token.nftContractAddr){
                //Set the matching loan to the last loan of the array
                addressToInLoans[addr][i] = addressToInLoans[addr][addressToInLoans[addr].length - 1];
                //pops the array to get rig of the last item
                addressToInLoans[addr].pop();
            }
        }
        //remove the nft from the NFT in loan list
        removeNftList(token);
        //Decrease the number of loans a customer holds
        customAddrToNumLoans[addr] -= 1;
        if (customAddrToNumLoans[addr] <= 0){
            //remove customer from the customerList if they dont have any loan
            removeCustomerList(addr);
        }
    }

    //Check which loan is due and remove those loan which doesn't fully paid
    //only callable by the bank Oracle
    function callDueLoan() internal{
        for (uint256 i=0; i < customerList.length; i++){
            for(uint256 j=0; j < addressToInLoans[customerList[i]].length; j++){
                if(addressToInLoans[customerList[i]][j].dueTime < block.timestamp){
                    if(addressToInLoans[customerList[i]][j].defaultCount >= defaultRate){
                        loanRemoveList.push(addressToInLoans[customerList[i]][j]);
                    }
                }
                if(addressToInLoans[customerList[i]][j].nextPayDay < block.timestamp){
                    //Check accumulative percentage, if doesnt fullfill, add to defaultcount
                    if( (addressToInLoans[customerList[i]][j].cumuRate + addressToInLoans[customerList[i]][j].baseCumuRate).div(10**18) < 1){
                        //Does not fullfill the daily instalment
                        if( addressToInLoans[customerList[i]][j].debt - addressToInLoans[customerList[i]][j].debt.mul(addressToInLoans[customerList[i]][j].cumuRate).div(10**18) 
                        < addressToInLoans[customerList[i]][j].outstandBalance){
                            addressToInLoans[customerList[i]][j].defaultCount++;
                            addressToInLoans[customerList[i]][j].nextPayDay += 86400;
                            addressToInLoans[customerList[i]][j].cumuRate += addressToInLoans[customerList[i]][j].baseCumuRate;
                        }
                        //Fullfilled the daily instalment
                        else{
                            addressToInLoans[customerList[i]][j].nextPayDay += 86400;
                            addressToInLoans[customerList[i]][j].cumuRate += addressToInLoans[customerList[i]][j].baseCumuRate;
                        }
                    }
                    else{
                        addressToInLoans[customerList[i]][j].cumuRate = 1000000000000000000;
                        addressToInLoans[customerList[i]][j].nextPayDay += 86400;
                        addressToInLoans[customerList[i]][j].defaultCount++;
                    }
                }
            }
        }
        removeDefaultLoan(loanRemoveList);
        delete loanRemoveList;
    }

    //Change interest on every NFT based on defaultRate
    //only allow the oracle contract to call this
    function chargeInterest() internal{
        for (uint256 i=0; i < customerList.length; i++){
            for(uint256 j=0; j < addressToInLoans[customerList[i]].length; j++){
                uint256 temp;
                if(addressToInLoans[customerList[i]][j].defaultCount == 0){
                    temp = addressToInLoans[customerList[i]][j].outstandBalance.mul(addressToInLoans[customerList[i]][j].LoanRate).div(10**18).div(100);
                    addressToInLoans[customerList[i]][j].outstandBalance += temp;
                    addressToInLoans[customerList[i]][j].debt += temp;
                }
                else if(addressToInLoans[customerList[i]][j].defaultCount == 1){
                    temp = addressToInLoans[customerList[i]][j].outstandBalance.mul(addressToInLoans[customerList[i]][j].LoanRate.mul(2)).div(10**18).div(100);
                    addressToInLoans[customerList[i]][j].outstandBalance += temp;
                    addressToInLoans[customerList[i]][j].debt += temp;
                }
                else if(addressToInLoans[customerList[i]][j].defaultCount == 2){
                    temp = addressToInLoans[customerList[i]][j].outstandBalance.mul(addressToInLoans[customerList[i]][j].LoanRate.mul(3)).div(10**18).div(100);
                    addressToInLoans[customerList[i]][j].outstandBalance += temp;
                    addressToInLoans[customerList[i]][j].debt += temp;
                }
                else if(addressToInLoans[customerList[i]][j].defaultCount == 3){
                    temp = addressToInLoans[customerList[i]][j].outstandBalance.mul(addressToInLoans[customerList[i]][j].LoanRate.mul(4)).div(10**18).div(100);
                    addressToInLoans[customerList[i]][j].outstandBalance += temp;
                    addressToInLoans[customerList[i]][j].debt += temp;
                }
            }
        }
    }

    //Remove all defaulted loan from all the array and mapping
    function removeDefaultLoan(InLoan[] memory removeList) private{
        for(uint256 i=0; i < removeList.length; i++){
            //Search the Loan index from addressToInLoans
            for (uint256 j=0; j < addressToInLoans[removeList[i].loanOwner].length; j++){
                if(addressToInLoans[removeList[i].loanOwner][j].nft.nftContractAddr == removeList[i].nft.nftContractAddr && 
                   addressToInLoans[removeList[i].loanOwner][j].nft.tokenId == removeList[i].nft.tokenId){
                    
                    //remove the loan from addressToInLoans
                    addressToInLoans[removeList[i].loanOwner][j] = 
                    addressToInLoans[removeList[i].loanOwner][addressToInLoans[removeList[i].loanOwner].length -1];
                    addressToInLoans[removeList[i].loanOwner].pop();
                    
                    //remove the loan from nftInLoan list so that it will be avalible for loaning out again
                    removeNftList(removeList[i].nft);
                    //Decrease the customers number of loans
                    customAddrToNumLoans[removeList[i].loanOwner] -= 1;

                    if (customAddrToNumLoans[removeList[i].loanOwner] <= 0){
                    //remove customer from the customerList if they dont have any loan
                        removeCustomerList(removeList[i].loanOwner);
                    }           
                }
            }

        }
    }

    /*__________________________________Getter_____________________________________ */

    //Return an array of InLoans of a user
    function getAllUserLoan(address addr) public view returns(InLoan[] memory){
        return addressToInLoans[addr];
    }

    //Return the number of Loans that a user have
    function getUserNumLoan(address addr) public view returns(uint256){
        return customAddrToNumLoans[addr];
    }

    //Return all NFT that is currently in a loan
    function getAllNftLoan() public view returns(NftToken[] memory){
        return nftInLoan;
    }

    function getAllDefaultLoan() public view returns(InLoan[] memory){
        return loanRemoveList;
    }

    /*__________________________________Setter_____________________________________ */

    //Only called by the contract
    function removeNftList(NftToken memory token) private{
        for(uint256 i = 0; i<nftInLoan.length; i++){
            //Check if the nft in the list or not
            if (nftInLoan[i].nftContractAddr == token.nftContractAddr 
            && nftInLoan[i].tokenId == token.tokenId){
                //Set the matching nft to the last nft of the array
                nftInLoan[i] = nftInLoan[nftInLoan.length -1];
                //pops the array to get rig of the last item
                nftInLoan.pop();
            }
        }
    }

    //Only called by the contract
    //Remove a customer from the customer list
    function removeCustomerList(address addr) private{
        for(uint256 i = 0; i <customerList.length; i++){
            if(customerList[i] == addr){
                customerList[i] = customerList[customerList.length-1];
                customerList.pop();
            }
        }
    }

    function setDefaultRate(uint256 rate) public onlyOwner{
        defaultRate = rate;
    }

    /*__________________________________Checker_____________________________________ */

    //Return true if a loan is fully repaid, false otherwise
    //For future use just in case, no use right now
    function checkLoanPaid(address addr, NftToken memory token) internal view returns(bool){ //internal
        for(uint256 i = 0; i<addressToInLoans[addr].length; i++){
            if(addressToInLoans[addr][i].nft.tokenId == token.tokenId &&
               addressToInLoans[addr][i].nft.nftContractAddr == token.nftContractAddr && 
               addressToInLoans[addr][i].outstandBalance <= 0){
                return true;
            }
        }
        return false;
    }

    //Check if a loan exist
    function checkLoanExist(address addr, NftToken memory token) internal view returns(bool){ //internal
        for(uint256 i = 0; i<addressToInLoans[addr].length; i++){
            if(addressToInLoans[addr][i].nft.tokenId == token.tokenId &&
               addressToInLoans[addr][i].nft.nftContractAddr == token.nftContractAddr){
                return true;
            }
        }
        return false;
    }

    //Check if the nft is in the loan list
    function checkNftInList(NftToken memory token) internal view returns(bool){
        for(uint256 i = 0; i<nftInLoan.length; i++){
            //Check if the nft in the list or not
            if (nftInLoan[i].nftContractAddr == token.nftContractAddr && 
                nftInLoan[i].tokenId == token.tokenId){
                return true;
            }
        }
        return false;
    }

    //Check if the this contract owns the nft
    function checkNftBalance(NftToken memory token) internal view returns(bool){
        ERC721 Nft = ERC721(token.nftContractAddr);
        if (Nft.ownerOf(token.tokenId) == address(this)){
            return true;
        }
        else{
            return false;
        }
    }

    //For degugging
    function checkCustomerInList(address addr) internal view returns(bool){
        for(uint256 i =0; i < customerList.length; i++){
            if(customerList[i] == addr){
                return true;
            }
        }
        return false;
    }

    /*__________________________________Other_____________________________________ */

    //Transfer the nft to the customer, only called by the contract
    function transferNft(NftToken memory token, address transferTo) private {
        ERC721 Nft = ERC721(token.nftContractAddr);
        Nft.transferFrom(address(this), transferTo, token.tokenId);
    }

    //Widthdraw All ETH for testnet purpose only
    function withdraw() public onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function addstartUpFund() external payable onlyOwner{
        netProfit += int256(msg.value);
    }

    //Forward one day for all loans next payment day and due time, for testing the contract only
    function fowardOneDay() external onlyOwner{
        for (uint256 i=0; i < customerList.length; i++){
            for(uint256 j=0; j < addressToInLoans[customerList[i]].length; j++){
                addressToInLoans[customerList[i]][j].nextPayDay -= 86400;
                addressToInLoans[customerList[i]][j].dueTime -=86400;
            }
        }
    }

    /*_____________________________Oracle Access___________________________________*/
    //Called by ChainLink Keepers Time-based Trigger
    function bankOracleControl() external{
        require(msg.sender == bankOracleAddr, "Only the bank orcacle contract can call this function");
        callDueLoan();
        chargeInterest();
        paidInterest();
    }

}
// File: contracts/nffBankOracle.sol


pragma solidity ^0.8.7;


contract nffBankOracle{
    address public bankaddr;
    address public oracleAddr;
    address public owner;
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry you are not the owner");
        _;
    }

    function accessGranted(address theSender) external view returns(bool){
        if (oracleAddr == address(0)){
            return true;
        }
        else if (oracleAddr == theSender){
            return true;
        }
        else{
            return false;
        }
    }

    function DailyBankOperation() public{
        require(this.accessGranted(msg.sender), "Sorry you are not the blockchain Oracle");
        nffMain(bankaddr).bankOracleControl();
    }

    function setBankOracleAddr(address theOracle) external onlyOwner(){
        oracleAddr = theOracle;
    }

    function setBankAddr(address thebank) external onlyOwner(){
        bankaddr = thebank;
    }

}