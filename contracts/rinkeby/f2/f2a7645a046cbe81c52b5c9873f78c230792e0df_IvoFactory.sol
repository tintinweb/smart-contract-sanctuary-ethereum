/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

    function totalSupply() external view returns (uint256);

      function mintToken(uint256 tokenId, address userAddress) external;
}


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/IERC721Metadata.sol

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: NFT.sol


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

contract IVONFTSaleContract is Ownable{
    using Strings for uint256;
    using SafeMath for uint;
    
    IERC20 public tokenAddress;
    IERC721 public nftAddress;
    uint256 public tokenPrice;
    uint256 public cliffTime;
    uint256 public hardcap;
    bool public preSaleOver;

    mapping(address => bool) public isTokenPurchasedByUser;
    mapping(address => uint256) public tokenIdPurchasedByUser;
    mapping(address => bool) public isClaimed;
    mapping(address => bool) public isMinter;

    constructor(IERC20 _tokenAddress, IERC721 _nftAddress, uint256 _tokenPrice, uint256 _hardcap, uint256 _cliffTime)
    {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
        tokenPrice = _tokenPrice;
        hardcap = _hardcap;
        cliffTime = block.timestamp + _cliffTime;
        preSaleOver = true;
    }

    function buyNFT() external {
        require(preSaleOver == false, "buyNFT: NFT sale has not started yet");
        require(nftAddress.totalSupply() <= hardcap, "buyNFT: Hardcap reached for NFTs");
        require(!isTokenPurchasedByUser[msg.sender], "buyNFT: User has already purchased the token");
        require(tokenAddress.transferFrom(msg.sender, address(this), tokenPrice), "buyNFT: Can not transfer token to contract, check allowance");
        uint idx = nftAddress.totalSupply();
        tokenIdPurchasedByUser[msg.sender] = idx;
    }

    function claimNFT() external {
        require(preSaleOver == false, "claimNFT: NFT sale has not started yet");
        require(!isClaimed[msg.sender], "claimNFT: User has already claimed the NFT");
        require(block.timestamp > cliffTime, "claimNFT: Can not claim before cliff duration");
            isClaimed[msg.sender] = true;
            nftAddress.mintToken(tokenIdPurchasedByUser[msg.sender], msg.sender);
    }

    function setCliffTime(uint _cliff) external onlyOwner {
        cliffTime = _cliff;
    }

    /*
     * @notice end presale
     */
    function endPresale() external onlyOwner returns (bool) {
        preSaleOver = true;
        return preSaleOver;
    }

    /*
     * @notice start presale
     */
    function startPresale() external onlyOwner returns (bool) {
        preSaleOver = false;
        return preSaleOver;
    }
    
    function getContractBalance() public view returns(uint) {
        return tokenAddress.balanceOf(address(this));
    }

}

contract IVOERC1155aleContract is Ownable{
    using Strings for uint256;
    using SafeMath for uint;
    
    IERC20 public tokenAddress;
    IERC1155 public nftAddress;
    uint256 public tokenPrice;
    uint256 public cliffTime;
    uint256 public hardcap;
    bool public preSaleOver;

    mapping(address => bool) public isTokenPurchasedByUser;
    mapping(address => uint256) public tokenIdPurchasedByUser;
    mapping(address => bool) public isClaimed;
    mapping(address => bool) public isMinter;

    constructor(IERC20 _tokenAddress, IERC1155 _nftAddress, uint256 _tokenPrice, uint256 _hardcap, uint256 _cliffTime)
    {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
        tokenPrice = _tokenPrice;
        hardcap = _hardcap;
        cliffTime = block.timestamp + _cliffTime;
        preSaleOver = true;
    }

    function buyNFT(uint idx) external {
        require(preSaleOver == false, "buyNFT: NFT sale has not started yet");
        require(!isTokenPurchasedByUser[msg.sender], "buyNFT: User has already purchased the token");
        require(tokenAddress.transferFrom(msg.sender, address(this), tokenPrice), "buyNFT: Can not transfer token to contract, check allowance");
        tokenIdPurchasedByUser[msg.sender] = idx;
    }

    function claimNFT() external {
        require(preSaleOver == false, "claimNFT: NFT sale has not started yet");
        require(!isClaimed[msg.sender], "claimNFT: User has already claimed the NFT");
        require(block.timestamp > cliffTime, "claimNFT: Can not claim before cliff duration");
            isClaimed[msg.sender] = true;
            nftAddress.safeTransferFrom(address(this), msg.sender, tokenIdPurchasedByUser[msg.sender], 1, "0x00");
    }

    function setCliffTime(uint _cliff) external onlyOwner {
        cliffTime = _cliff;
    }

    /*
     * @notice end presale
     */
    function endPresale() external onlyOwner returns (bool) {
        preSaleOver = true;
        return preSaleOver;
    }

    /*
     * @notice start presale
     */
    function startPresale() external onlyOwner returns (bool) {
        preSaleOver = false;
        return preSaleOver;
    }
    
    function getContractBalance() public view returns(uint) {
        return tokenAddress.balanceOf(address(this));
    }

}

abstract contract Whitelist is Ownable {
    mapping (address => bool) private whitelistUser;

    bool private isWhitelistEnable;

    modifier onlyWhitelisted() {
        if(isWhitelistEnable){
            require(isWhitelisted(msg.sender), "Whitelist: caller does not have the Whitelisted role");             
        }
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return whitelistUser[account];
    }

    function setWhitelistEnable(bool value) public onlyOwner returns(bool){
        isWhitelistEnable = value;
        return true;
    }

    function setWhitelistAddress (address[] memory users) public onlyOwner returns(bool){
        for (uint i = 0; i < users.length; i++) {
            whitelistUser[users[i]] = true;
        }
        return true;
    }
}

interface INonStandardERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! transfer does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///
    function transfer(address dst, uint256 amount) external;
    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! transferFrom does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;
    function approve(address spender, uint256 amount)
        external
        returns (bool success);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

contract Sale  is Ownable, Whitelist {
    using SafeMath for uint256;
    event ClaimableAmount(address _user, uint256 _claimableAmount);

    //rate of token per usdt
    uint256 public rate; 

    // max allowed purchase of usdt per user 
    uint256 public allowedUserBalance; 

    // check presale is over or not
    bool public presaleOver;

    // usdt token address
    IERC20 public usdt;
    
    // check claimable amount of given user
    mapping(address => uint256) public claimable;

    // hardcap to raise in usdt
    uint256 public hardcap; 
    
    // participated user addresses
    address[] public participatedUsers;

    /*
     * @notice Initialize the contract
     * @param _rate: rate of token
     * @param _usdt: usdt token address
     * @param _hardcap: amount to raise
     * @param _allowedUserBalance: max allowed purchase of usdt per user
     */
    constructor(uint256 _rate, IERC20 _usdt, uint256 _hardcap, uint256 _allowedUserBalance) {
        rate = _rate;
        usdt = _usdt;
        presaleOver = true;
        hardcap = _hardcap;
        allowedUserBalance = _allowedUserBalance;
    }

    modifier isPresaleOver() {
        require(presaleOver == true, "The Private Sale Round 1 is not over");
        _;
    }

    /*
     * @notice Change Hardcap
     * @param _hardcap: amount in usdt
     */
    function changeHardCap(uint256 _hardcap) onlyOwner public {
        hardcap = _hardcap;
    }

    /*
     * @notice Change Rate
     * @param _rate: token rate per usdt
     */
    function changeRate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    /*
     * @notice Change Allowed user balance
     * @param _allowedUserBalance: amount allowed per user to purchase tokens in usdt
     */
    function changeAllowedUserBalance(uint256 _allowedUserBalance) onlyOwner public {
        allowedUserBalance = _allowedUserBalance;
    }

    /*
     * @notice get total number of participated user
     * @return no of participated user
     */
    function getTotalParticipatedUser() public view returns(uint256){
        return participatedUsers.length;
    }

    /*
     * @notice end presale
     */
    function endPresale() external onlyOwner returns (bool) {
        presaleOver = true;
        return presaleOver;
    }

    /*
     * @notice start presale
     */
    function startPresale() external onlyOwner returns (bool) {
        presaleOver = false;
        return presaleOver;
    }

    /*
     * @notice Buy Token with USDT
     * @param _amount: amount of usdt
     */
    function buyTokenWithUSDT(uint256 _amount) external onlyWhitelisted{
        // user enter amount of ether which is then transfered into the smart contract and tokens to be given is saved in the mapping
        require(presaleOver == false, "Private Sale Round 1 is over you cannot buy now");
        uint256 tokensPurchased = _amount.mul(rate);
        uint256 userUpdatedBalance = claimable[msg.sender].add(tokensPurchased);
        require( _amount.add(usdt.balanceOf(address(this))) <= hardcap, "Hardcap for the tokens reached");
        // for USDT
        require(userUpdatedBalance.div(rate) <= allowedUserBalance, "Exceeded allowed user balance");
        doTransferIn(address(usdt), msg.sender, _amount);
        claimable[msg.sender] = userUpdatedBalance;
        participatedUsers.push(msg.sender);
        emit ClaimableAmount(msg.sender, tokensPurchased);
    }

    /*
     * @notice get user list
     * @return userAddress: user address list
     * @return amount : user wise claimable amount list
     */
    function getUsersList(uint startIndex, uint endIndex) external view returns(address[] memory userAddress, uint[] memory amount){
        uint length = endIndex.sub(startIndex);
        address[] memory _userAddress = new address[](length);
        uint[] memory _amount = new uint[](length);

        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address user = participatedUsers[i];
            uint listIndex = i.sub(startIndex);
            _userAddress[listIndex] = user;
            _amount[listIndex] = claimable[user];
        }

        return (_userAddress, _amount);
    }

    /*
     * @notice do transfer in - tranfer token to contract
     * @param tokenAddress: token address to transfer in contract
     * @param from : user address from where to transfer token to contract
     * @param amount : amount to trasnfer 
     */
    function doTransferIn(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        INonStandardERC20 _token = INonStandardERC20(tokenAddress);
        uint256 balanceBefore = INonStandardERC20(tokenAddress).balanceOf(address(this));
        _token.transferFrom(from, address(this), amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set success = returndata of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
        // Calculate the amount that was actually transferred
        uint256 balanceAfter = INonStandardERC20(tokenAddress).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter.sub(balanceBefore); // underflow already checked above, just subtract
    }

    /*
     * @notice do transfer out - tranfer token from contract
     * @param tokenAddress: token address to transfer from contract
     * @param to : user address to where transfer token from contract
     * @param amount : amount to trasnfer 
     */
    function doTransferOut(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        INonStandardERC20 _token = INonStandardERC20(tokenAddress);
        _token.transfer(to, amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set success = returndata of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    /*
     * @notice funds withdraw
     * @param _value: usdt value to transfer from contract to owner
     */
    function fundsWithdrawal(uint256 _value) external onlyOwner isPresaleOver {
        doTransferOut(address(usdt), _msgSender(), _value);
    }

    /*
     * @notice funds withdraw
     * @param _tokenAddress: token address to transfer
     * @param _value: token value to transfer from contract to owner
     */
    function transferAnyERC20Tokens(address _tokenAddress, uint256 _value) external onlyOwner {
        doTransferOut(address(_tokenAddress), _msgSender(), _value);
    }
}

contract IvoFactory{
    struct NFTSale{
        address saleAddress;
        IERC20 tokenAddress;
        IERC721 nftAddress;
        uint256 tokenPrice;
        uint256 hardcap;
        uint256 cliffTime;
    }

    struct FungibleTokenSale{
        address saleAddress;
        uint256 rate;
        IERC20 usdt;
        uint256 hardcap;
        uint256 allowedUserBalance;
    }

    mapping(address => NFTSale) public nftSaleData;
    mapping(address => FungibleTokenSale) public fungibleTokenSaleData;
    address[] public nftSaleAddress;
    address[] public fungibleTokenAddress;

    function createNFTSaleContract(IERC20 _tokenAddress, IERC721 _nftAddress, uint256 _tokenPrice, uint256 _hardcap, uint256 _cliffTime) public returns(address) {
        IVONFTSaleContract sale = new IVONFTSaleContract(_tokenAddress, _nftAddress, _tokenPrice, _hardcap, _cliffTime);
        nftSaleData[address(sale)].saleAddress = address(sale); 
        nftSaleData[address(sale)].tokenAddress = _tokenAddress;
        nftSaleData[address(sale)].tokenPrice = _tokenPrice;
        nftSaleData[address(sale)].hardcap = _hardcap;
        nftSaleData[address(sale)].cliffTime = _cliffTime;
        nftSaleAddress.push(address(sale));
        return address(sale);
    }

    function createFungibleTokenSaleContract(IERC20 _usdt, uint256 _rate, uint256 _hardcap, uint256 _allowedUserBalance) public returns(address) {
        Sale sale = new Sale(_rate, _usdt, _hardcap, _allowedUserBalance);
        fungibleTokenSaleData[address(sale)].saleAddress = address(sale); 
        fungibleTokenSaleData[address(sale)].usdt = _usdt;
        fungibleTokenSaleData[address(sale)].rate = _rate;
        fungibleTokenSaleData[address(sale)].hardcap = _hardcap;
        fungibleTokenSaleData[address(sale)].allowedUserBalance = _allowedUserBalance;
        fungibleTokenAddress.push(address(sale));
        return address(sale);
    }

    function getNftSaleAddresses() public view returns(address[] memory){
        return nftSaleAddress;
    }

    function getFungibleTokenSaleAddresses() public view returns(address[] memory){
        return fungibleTokenAddress;
    }
}