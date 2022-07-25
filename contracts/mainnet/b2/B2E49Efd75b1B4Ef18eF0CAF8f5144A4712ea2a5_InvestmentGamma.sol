/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts_ETH/main/libraries/Data.sol


pragma solidity ^0.8.4;
library Data {

enum State {
        NONE,
        PENDING
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

// File: contracts_ETH/main/libraries/Math.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts_ETH/main/libraries/SafeERC20.sol


pragma solidity ^0.8.4;


library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x95d89b41)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x06fdde03)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x313ce567)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TransferFrom failed"
        );
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts_ETH/main/WithdrawalConfirmation.sol


pragma solidity ^0.8.4;




/** 
* @author Formation.Fi.
* @notice The Implementation of the user's withdrawal proof token {ERC721}.
*/

contract WithdrawalConfirmation is ERC721, Ownable { 
    struct PendingWithdrawal {
        Data.State state;
        uint256 amount;
        uint256 listPointer;
    }
    uint256 public tolerance = 1e3;
    address public proxyInvestement; 
    string public baseURI;
    mapping(address => uint256) private tokenIdPerAddress;
    mapping(address => PendingWithdrawal) public pendingWithdrawPerAddress;
    address[] public usersOnPendingWithdraw;
    event MintWithdrawal(address indexed _address, uint256 _id);
    event BurnWithdrawal(address indexed _address, uint256 _id);
    event UpdateBaseURI( string _baseURI);

    constructor(string memory _name , string memory _symbol)  
    ERC721 (_name,  _symbol){
    }

    modifier onlyProxy() {
        require(
            proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        require(msg.sender == proxyInvestement, "Formation.Fi: not the proxy");
         _;
    }

     /**
     * @dev get the token id of user's address.
     * @param _account The user's address.
     * @return token id.
     */
    function getTokenId(address _account) external view returns (uint256) {
        return tokenIdPerAddress[ _account];
    }

      /**
     * @dev get the number of users.
     * @return number of users.
     */
     function getUsersSize() external view returns (uint256) {
        return usersOnPendingWithdraw.length;
    }

    /**
     * @dev get addresses of users on withdrawal pending.
     * @return  addresses of users.
     */
    function getUsers() public view returns (address[] memory) {
        return usersOnPendingWithdraw;
    }

    /**
     * @dev update the proxy.
     * @param _proxyInvestement the new proxy.
     */
    function setProxy(address _proxyInvestement) public onlyOwner {
        require(
            _proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        proxyInvestement = _proxyInvestement;
    }    

    /**
     * @dev update the Metadata URI
     * @param _tokenURI the Metadata URI.
     */
    function setBaseURI(string calldata _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
        emit UpdateBaseURI(_tokenURI);
    }
    
    /**
     * @dev mint the withdrawal proof ERC721 token.
     * @notice the user receives this token when he makes 
     * a withdrawal request.
     * Each user's address can at most have one withdrawal proof token.
     * @param _account The user's address.
     * @param _tokenId The id of the token.
     * @param _amount The withdrawal amount in the product token.
     * @notice Emits a {MintWithdrawal} event with `_account` and `_tokenId `.
     */
    function mint(address _account, uint256 _tokenId, uint256 _amount) 
       external onlyProxy {
       require (balanceOf( _account) == 0, "Formation.Fi:  has withdrawal token");
       _safeMint(_account,  _tokenId);
       tokenIdPerAddress[_account] = _tokenId;
       updateWithdrawalData (_account,  _tokenId,  _amount, true);
       emit MintWithdrawal(_account, _tokenId);
    }

     /**
     * @dev burn the withdrawal proof ERC721 token.
     * @notice the token is burned  when the manager fully validates
     * the user's withdrawal request.
     * @param _tokenId The id of the token.
     * @notice Emits a {BurnWithdrawal} event with `owner` and `_tokenId `.
     */
    function burn(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        require (pendingWithdrawPerAddress[owner].state != Data.State.PENDING, 
        "Formation.Fi: is on pending");
        _deleteWithdrawalData(owner);
        _burn(_tokenId);   
        emit BurnWithdrawal(owner, _tokenId);
    }

    /**
     * @dev update the user's withdrawal data.
     * @notice this function is called after the withdrawal request 
     * by the user or after each validation by the manager.
     * @param _account The user's address.
     * @param _tokenId The withdrawal proof token id.
     * @param _amount  The withdrawal amount to be added or removed.
     * @param isAddCase  = 1 when teh user makes a withdrawal request.
     * = 0, when the manager validates the user's withdrawal request.
     */
    function updateWithdrawalData (address _account, uint256 _tokenId, 
        uint256 _amount, bool isAddCase) public onlyProxy {

        require (_exists(_tokenId), "Formation Fi: no token");

        require (ownerOf(_tokenId) == _account , 
         "Formation.Fi: not owner");

        if( _amount > 0){
            if (isAddCase){
               pendingWithdrawPerAddress[_account].state = Data.State.PENDING;
               pendingWithdrawPerAddress[_account].amount = _amount;
               pendingWithdrawPerAddress[_account].listPointer = usersOnPendingWithdraw.length;
               usersOnPendingWithdraw.push(_account);
            }
            else {
               require(pendingWithdrawPerAddress[_account].amount >= _amount, 
               "Formation.Fi: not enough amount");
               uint256 _newAmount = pendingWithdrawPerAddress[_account].amount - _amount;
               pendingWithdrawPerAddress[_account].amount = _newAmount;
               if (_newAmount <= tolerance){
                   pendingWithdrawPerAddress[_account].state = Data.State.NONE;
                   burn(_tokenId);
                }
            }     
       }
    }

    /**
     * @dev delete the user's withdrawal proof token data.
     * @notice this function is called when the user's withdrawal request is fully 
     * validated by the manager.
     * @param _account The user's address.
     */
    function _deleteWithdrawalData(address _account) internal {
        require(
          _account!= address(0),
          "Formation.Fi: zero address"
        );
        uint256 _index = pendingWithdrawPerAddress[_account].listPointer;
        address _lastUser = usersOnPendingWithdraw[usersOnPendingWithdraw.length -1];
        usersOnPendingWithdraw[_index] = _lastUser ;
        pendingWithdrawPerAddress[_lastUser].listPointer = _index;
        usersOnPendingWithdraw.pop();
        delete pendingWithdrawPerAddress[_account]; 
        delete tokenIdPerAddress[_account];    
    }

     /**
     * @dev update the withdrawal token proof data of both the sender and the receiver 
       when the token is transferred.
     * @param from The sender's address.
     * @param to The receiver's address.
     * @param tokenId The withdrawal token proof id.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
       if ((to != address(0)) && (from != address(0))){
          uint256 indexFrom = pendingWithdrawPerAddress[from].listPointer;
          pendingWithdrawPerAddress[to] = pendingWithdrawPerAddress[from];
          pendingWithdrawPerAddress[from].state = Data.State.NONE;
          pendingWithdrawPerAddress[from].amount =0;
          usersOnPendingWithdraw[indexFrom] = to; 
          tokenIdPerAddress[to] = tokenId;
          delete pendingWithdrawPerAddress[from];
          delete tokenIdPerAddress[from];
        }
    }
    
    /**
     * @dev Get the Metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
   
}
  
// File: contracts_ETH/main/DepositConfirmation.sol


pragma solidity ^0.8.4;





/** 
* @author Formation.Fi.
* @notice The Implementation of the user's deposit proof token {ERC721}.
*/

contract DepositConfirmation is ERC721, Ownable {
    struct PendingDeposit {
        Data.State state;
        uint256 amount;
        uint256 listPointer;
    }
    uint256 public tolerance = 1e3; 
    address public proxyInvestement;
    string public baseURI;
    mapping(address => uint256) private tokenIdPerAddress;
    mapping(address => PendingDeposit) public pendingDepositPerAddress;
    address[] public usersOnPendingDeposit;
    event MintDeposit(address indexed _address, uint256 _id);
    event BurnDeposit(address indexed _address, uint256 _id);
    event UpdateBaseURI( string _baseURI);

    constructor(string memory _name , string memory _symbol)  
    ERC721 (_name, _symbol){
    }

    modifier onlyProxy() {
        require(
            proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        require(msg.sender == proxyInvestement, "Formation.Fi: not the proxy");
        _;
    }
    
     /**
     * @dev get the token id of user's address.
     * @param _account The user's address.
     * @return token id.
     */
    function getTokenId(address _account) external view returns (uint256) {
        require(
           _account!= address(0),
            "Formation.Fi: zero address"
        );

        return tokenIdPerAddress[_account];
    }

     /**
     * @dev get the number of users.
     * @return number of users.
     */
    function getUsersSize() external view  returns (uint256) {
        return usersOnPendingDeposit.length;
    }
    
     /**
     * @dev get addresses of users on deposit pending.
     * @return  addresses of users.
     */
    function getUsers() external view returns (address[] memory) {
        return usersOnPendingDeposit;
    }

     /**
     * @dev update the proxy.
     * @param _proxyInvestement the new proxy.
     */
    function setProxy(address _proxyInvestement) external onlyOwner {
        require(
            _proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        proxyInvestement = _proxyInvestement;
    }    

    /**
     * @dev update the Metadata URI
     * @param _tokenURI the Metadata URI.
     */
    function setBaseURI(string calldata _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
        emit UpdateBaseURI(_tokenURI);
    }

     /**
     * @dev mint the deposit proof ERC721 token.
     * @notice the user receives this token when he makes 
     * a deposit request.
     * Each user's address can at most have one deposit proof token.
     * @param _account The user's address.
     * @param _tokenId The id of the token.
     * @param _amount The deposit amount in the requested Stablecoin.
     * @notice Emits a {MintDeposit} event with `_account` and `_tokenId `.
     */
    function mint(address _account, uint256 _tokenId, uint256 _amount) 
       external onlyProxy {
       require (balanceOf(_account) == 0, "Formation.Fi: has deposit token");
       _safeMint(_account,  _tokenId);
       updateDepositData( _account,  _tokenId, _amount, true);
       emit MintDeposit(_account, _tokenId);
    }

     /**
     * @dev burn the deposit proof ERC721 token.
     * @notice the token is burned  when the manager fully validates
     * the user's deposit request.
     * @param _tokenId The id of the token.
     * @notice Emits a {BurnDeposit} event with `owner` and `_tokenId `.
     */
    function burn(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        require (pendingDepositPerAddress[owner].state != Data.State.PENDING,
        "Formation.Fi: is on pending");
        _deleteDepositData(owner);
        _burn(_tokenId); 
        emit BurnDeposit(owner, _tokenId);
    }
     
     /**
     * @dev update the user's deposit data.
     * @notice this function is called after each desposit request 
     * by the user or after each validation by the manager.
     * @param _account The user's address.
     * @param _tokenId The depoist proof token id.
     * @param _amount  The deposit amount to be added or removed.
     * @param isAddCase  = 1 when teh user makes a deposit request.
     * = 0, when the manager validates the user's deposit request.
     */
    function updateDepositData(address _account, uint256 _tokenId, 
        uint256 _amount, bool isAddCase) public onlyProxy {
        require (_exists(_tokenId), "Formation.Fi: no token");
        require (ownerOf(_tokenId) == _account , "Formation.Fi:  not owner");
        if( _amount > 0){
           if (isAddCase){
              if(pendingDepositPerAddress[_account].amount == 0){
                  pendingDepositPerAddress[_account].state = Data.State.PENDING;
                  pendingDepositPerAddress[_account].listPointer = usersOnPendingDeposit.length;
                  tokenIdPerAddress[_account] = _tokenId;
                  usersOnPendingDeposit.push(_account);
                }
                pendingDepositPerAddress[_account].amount +=  _amount;
            }
            else {
               require(pendingDepositPerAddress[_account].amount >= _amount, 
               "Formation Fi: not enough amount");
               uint256 _newAmount = pendingDepositPerAddress[_account].amount - _amount;
               pendingDepositPerAddress[_account].amount = _newAmount;
               if (_newAmount <= tolerance){
                  pendingDepositPerAddress[_account].state = Data.State.NONE;
                  burn(_tokenId);
                }
            }
        }
    }    

    
     /**
     * @dev delete the user's deposit proof token data.
     * @notice this function is called when the user's deposit request is fully 
     * validated by the manager.
     * @param _account The user's address.
     */
    function _deleteDepositData(address _account) internal {
        require(
           _account!= address(0),
            "Formation.Fi: zero address"
        );

         uint256 _index = pendingDepositPerAddress[_account].listPointer;
         address _lastUser = usersOnPendingDeposit[usersOnPendingDeposit.length - 1];
         usersOnPendingDeposit[_index] = _lastUser;
         pendingDepositPerAddress[_lastUser].listPointer = _index;
         usersOnPendingDeposit.pop();
         delete pendingDepositPerAddress[_account]; 
         delete tokenIdPerAddress[_account];    
    }

     /**
     * @dev update the deposit token proof data of both the sender and the receiver 
       when the token is transferred.
     * @param from The sender's address.
     * @param to The receiver's address.
     * @param tokenId The deposit token proof id.
     */
    function _beforeTokenTransfer(
       address from,
       address to,
       uint256 tokenId
    )   internal virtual override {
        if ((to != address(0)) && (from != address(0))){
            uint256 indexFrom = pendingDepositPerAddress[from].listPointer;
            pendingDepositPerAddress[to] = pendingDepositPerAddress[from];
            pendingDepositPerAddress[from].state = Data.State.NONE;
            pendingDepositPerAddress[from].amount = 0;
            usersOnPendingDeposit[indexFrom] = to; 
            tokenIdPerAddress[to] = tokenId;
            delete pendingDepositPerAddress[from];
            delete tokenIdPerAddress[from];
        }
    }
     /**
     * @dev Get the Metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
      
}
  
// File: contracts_ETH/main/Token.sol


pragma solidity ^0.8.4;




/** 
* @author Formation.Fi.
* @notice  A common Implementation for tokens ALPHA, BETA and GAMMA.
*/

contract Token is ERC20, Ownable {
    struct Deposit{
        uint256 amount;
        uint256 time;
    }
    address public proxyInvestement;
    address private proxyAdmin;

    mapping(address => Deposit[]) public depositPerAddress;
    mapping(address => bool) public  whitelist;
    event SetProxyInvestement(address  _address);
    constructor(string memory _name, string memory _symbol) 
    ERC20(_name,  _symbol) {
    }

    modifier onlyProxy() {
        require(
            (proxyInvestement != address(0)) && (proxyAdmin != address(0)),
            "Formation.Fi: zero address"
        );

        require(
            (msg.sender == proxyInvestement) || (msg.sender == proxyAdmin),
             "Formation.Fi: not the proxy"
        );
        _;
    }
    modifier onlyProxyInvestement() {
        require(proxyInvestement != address(0),
            "Formation.Fi: zero address"
        );

        require(msg.sender == proxyInvestement,
             "Formation.Fi: not the proxy"
        );
        _;
    }

     /**
     * @dev Update the proxyInvestement.
     * @param _proxyInvestement.
     * @notice Emits a {SetProxyInvestement} event with `_proxyInvestement`.
     */
    function setProxyInvestement(address _proxyInvestement) external onlyOwner {
        require(
            _proxyInvestement!= address(0),
            "Formation.Fi: zero address"
        );

         proxyInvestement = _proxyInvestement;

        emit SetProxyInvestement( _proxyInvestement);

    } 

    /**
     * @dev Add a contract address to the whitelist
     * @param _contract The address of the contract.
     */
    function addToWhitelist(address _contract) external onlyOwner {
        require(
            _contract!= address(0),
            "Formation.Fi: zero address"
        );

        whitelist[_contract] = true;
    } 

    /**
     * @dev Remove a contract address from the whitelist
     * @param _contract The address of the contract.
     */
    function removeFromWhitelist(address _contract) external onlyOwner {
         require(
            whitelist[_contract] == true,
            "Formation.Fi: no whitelist"
        );
        require(
            _contract!= address(0),
            "Formation.Fi: zero address"
        );

        whitelist[_contract] = false;
    } 

    /**
     * @dev Update the proxyAdmin.
     * @param _proxyAdmin.
     */
    function setAdmin(address _proxyAdmin) external onlyOwner {
        require(
            _proxyAdmin!= address(0),
            "Formation.Fi: zero address"
        );
        
         proxyAdmin = _proxyAdmin;
    } 


    
    /**
     * @dev add user's deposit.
     * @param _account The user's address.
     * @param _amount The user's deposit amount.
     * @param _time The deposit time.
     */
    function addDeposit(address _account, uint256 _amount, uint256 _time) 
        external onlyProxyInvestement {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

        require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

        require(
            _time!= 0,
            "Formation.Fi: zero time"
        );
        Deposit memory _deposit = Deposit(_amount, _time); 
        depositPerAddress[_account].push(_deposit);
    } 

     /**
     * @dev mint the token product for the user.
     * @notice To receive the token product, the user has to deposit 
     * the required StableCoin in this product. 
     * @param _account The user's address.
     * @param _amount The amount to be minted.
     */
    function mint(address _account, uint256 _amount) external onlyProxy {
        require(
          _account!= address(0),
           "Formation.Fi: zero address"
        );

        require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

       _mint(_account,  _amount);
   }

    /**
     * @dev burn the token product of the user.
     * @notice When the user withdraws his Stablecoins, his tokens 
     * product are burned. 
     * @param _account The user's address.
     * @param _amount The amount to be burned.
     */
    function burn(address _account, uint256 _amount) external onlyProxy {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

         require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

        _burn( _account, _amount);
    }
    
     /**
     * @dev Verify the lock up condition for a user's withdrawal request.
     * @param _account The user's address.
     * @param _amount The amount to be withdrawn.
     * @param _period The lock up period.
     * @return _success  is true if the lock up condition is satisfied.
     */
    function checklWithdrawalRequest(address _account, uint256 _amount, uint256 _period) 
        external view returns (bool _success){
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

        require(
           _amount!= 0,
            "Formation.Fi: zero amount"
        );

        Deposit[] memory _deposit = depositPerAddress[_account];
        uint256 _amountTotal = 0;
        for (uint256 i = 0; i < _deposit.length; i++) {
             require ((block.timestamp - _deposit[i].time) >= _period, 
            "Formation.Fi:  position locked");
            if (_amount<= (_amountTotal + _deposit[i].amount)){
                break; 
            }
            _amountTotal = _amountTotal + _deposit[i].amount;
        }
        _success= true;
    }


     /**
     * @dev update the user's token data.
     * @notice this function is called after each desposit request 
     * validation by the manager.
     * @param _account The user's address.
     * @param _amount The deposit amount validated by the manager.
     */
    function updateTokenData( address _account,  uint256 _amount) 
        external onlyProxyInvestement {
        _updateTokenData(_account,  _amount);
    }

    function _updateTokenData( address _account,  uint256 _amount) internal {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );

        require(
            _amount!= 0,
            "Formation.Fi: zero amount"
        );

        Deposit[] memory _deposit = depositPerAddress[_account];
        uint256 _amountlocal = 0;
        uint256 _amountTotal = 0;
        uint256 _newAmount;
        uint256 k =0;
        for (uint256 i = 0; i < _deposit.length; i++) {
            _amountlocal  = Math.min(_deposit[i].amount, _amount -  _amountTotal);
            _amountTotal = _amountTotal + _amountlocal;
            _newAmount = _deposit[i].amount - _amountlocal;
            depositPerAddress[_account][k].amount = _newAmount;
            if (_newAmount == 0){
               _deleteTokenData(_account, k);
            }
            else {
                k = k+1;
            }
            if (_amountTotal == _amount){
               break; 
            }
        }
    }
    
     /**
     * @dev delete the user's token data.
     * @notice This function is called when the user's withdrawal request is  
     * validated by the manager.
     * @param _account The user's address.
     * @param _index The index of the user in 'amountDepositPerAddress'.
     */
    function _deleteTokenData(address _account, uint256 _index) internal {
        require(
            _account!= address(0),
            "Formation.Fi: zero address"
        );
        uint256 _size = depositPerAddress[_account].length - 1;
        
        require( _index <= _size,
            "Formation.Fi: index is out"
        );
        for (uint256 i = _index; i< _size; i++){
            depositPerAddress[ _account][i] = depositPerAddress[ _account][i+1];
        }
        depositPerAddress[ _account].pop();   
    }
   
     /**
     * @dev update the token data of both the sender and the receiver 
       when the product token is transferred.
     * @param from The sender's address.
     * @param to The receiver's address.
     * @param amount The transferred amount.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
      ) internal virtual override{
      
       if ((to != address(0)) && (to != proxyInvestement) 
       && (to != proxyAdmin) && (from != address(0)) && (!whitelist[to])){
          _updateTokenData(from, amount);
          Deposit memory _deposit = Deposit(amount, block.timestamp);
          depositPerAddress[to].push(_deposit);
         
        }
    }

}

// File: contracts_ETH/main/Admin.sol


pragma solidity ^0.8.4;





/** 
* @author Formation.Fi.
* @notice Implementation of the contract Admin.
*/

contract Admin is Ownable {
    using SafeERC20 for IERC20;
    uint256 public constant FACTOR_FEES_DECIMALS = 1e4; 
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e6;
    uint256 public constant  SECONDES_PER_YEAR = 365 days; 
    uint256 public slippageTolerance = 200;
    uint256 public  amountScaleDecimals = 1; 
    uint256 public depositFeeRate = 50;  
    uint256 public depositFeeRateParity= 15; 
    uint256 public managementFeeRate = 200;
    uint256 public performanceFeeRate = 2000;
    uint256 public performanceFees;
    uint256 public managementFees;
    uint256 public managementFeesTime;
    uint256 public tokenPrice = 1e6;
    uint256 public tokenPriceMean = 1e6;
    uint256 public minAmount= 100 * 1e18;
    uint256 public lockupPeriodUser = 604800; 
    uint public netDepositInd;
    uint256 public netAmountEvent;
    address public manager;
    address public treasury;
    address public investement;
    address private safeHouse;
    bool public isCancel;
    Token public token;
    IERC20 public stableToken;


    constructor( address _manager, address _treasury,  address _stableTokenAddress,
     address _tokenAddress) {
        require(
            _manager != address(0),
            "Formation.Fi: zero address"
        );

        require(
           _treasury != address(0),
            "Formation.Fi:  zero address"
            );

        require(
            _stableTokenAddress != address(0),
            "Formation.Fi:  zero address"
        );

        require(
           _tokenAddress != address(0),
            "Formation.Fi:  zero address"
        );

        manager = _manager;
        treasury = _treasury; 
        stableToken = IERC20(_stableTokenAddress);
        token = Token(_tokenAddress);
        uint8 _stableTokenDecimals = ERC20( _stableTokenAddress).decimals();
        if ( _stableTokenDecimals == 6) {
            amountScaleDecimals= 1e12;
        }
    }

    modifier onlyInvestement() {
        require(investement != address(0),
            "Formation.Fi:  zero address"
        );

        require(msg.sender == investement,
             "Formation.Fi:  not investement"
        );
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 
        "Formation.Fi: not manager");
        _;
    }

     /**
     * @dev Setter functions to update the Portfolio Parameters.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "Formation.Fi: zero address"
        );

        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Formation.Fi: zero address"
        );

        manager = _manager;
    }

    function setInvestement(address _investement) external onlyOwner {
        require(
            _investement!= address(0),
            "Formation.Fi: zero address"
        );

        investement = _investement;
    } 

    function setSafeHouse(address _safeHouse) external onlyOwner {
        require(
            _safeHouse!= address(0),
            "Formation.Fi: zero address"
        );

        safeHouse = _safeHouse;
    } 

    function setCancel(bool _cancel) external onlyManager {
        isCancel= _cancel;
    }
  
    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        lockupPeriodUser = _lockupPeriodUser;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        depositFeeRate= _rate;
    }

    function setDepositFeeRateParity(uint256 _rate) external onlyManager {
        depositFeeRateParity= _rate;
    }

    function setManagementFeeRate(uint256 _rate) external onlyManager {
        managementFeeRate = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
        performanceFeeRate  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
        minAmount= _minAmount;
     }

    function updateTokenPrice(uint256 _price) external onlyManager {
        require(
             _price > 0,
            "Formation.Fi: zero price"
        );

        tokenPrice = _price;
    }

    function updateTokenPriceMean(uint256 _price) external onlyInvestement {
        require(
             _price > 0,
            "Formation.Fi: zero price"
        );
        tokenPriceMean  = _price;
    }

    function updateManagementFeeTime(uint256 _time) external onlyInvestement {
        managementFeesTime = _time;
    }
    

     /**
     * @dev Calculate performance Fees.
     */
    function calculatePerformanceFees() external onlyManager {
        require(performanceFees == 0, "Formation.Fi: fees on pending");

        uint256 _deltaPrice = 0;
        if (tokenPrice > tokenPriceMean) {
            _deltaPrice = tokenPrice - tokenPriceMean;
            tokenPriceMean = tokenPrice;
            performanceFees = (token.totalSupply() *
            _deltaPrice * performanceFeeRate) / (tokenPrice * FACTOR_FEES_DECIMALS); 
        }
    }

    
     /**
     * @dev Calculate management Fees.
     */
    function calculateManagementFees() external onlyManager {
        require(managementFees == 0, "Formation.Fi: fees on pending");
        if (managementFeesTime!= 0){
           uint256 _deltaTime;
           _deltaTime = block.timestamp -  managementFeesTime; 
           managementFees = (token.totalSupply() * managementFeeRate * _deltaTime ) 
           /(FACTOR_FEES_DECIMALS * SECONDES_PER_YEAR);
           managementFeesTime = block.timestamp; 
        }
    }
     
    /**
     * @dev Mint Fees.
     */
    function mintFees() external onlyManager {
        require ((performanceFees + managementFees) > 0, "Formation.Fi: zero fees");

        token.mint(treasury, performanceFees + managementFees);
        performanceFees = 0;
        managementFees = 0;
    }

    /**
     * @dev Calculate net deposit indicator
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param  _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     * @return net Deposit indicator: 1 if net deposit case, 0 otherwise (net withdrawal case).
     */
    function calculateNetDepositInd(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestement returns( uint256) {
        _depositAmountTotal = Math.min(  _depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal =  (_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS;
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
        uint256  _depositAmountTotalAfterFees = _depositAmountTotal - 
        ( _depositAmountTotal * depositFeeRate)/ FACTOR_FEES_DECIMALS;
        if  ( _depositAmountTotalAfterFees >= _withdrawalAmountTotal) {
            netDepositInd = 1 ;
        }
        else {
            netDepositInd = 0;
        }
        return netDepositInd;
    }

    /**
     * @dev Calculate net amount 
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     * @return net amount.
     */
    function calculateNetAmountEvent(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestement returns(uint256) {
        _depositAmountTotal = Math.min(  _depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal =  (_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS;
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
         uint256  _depositAmountTotalAfterFees = _depositAmountTotal - 
        ( _depositAmountTotal * depositFeeRate)/ FACTOR_FEES_DECIMALS;
        
        if (netDepositInd == 1) {
             netAmountEvent =  _depositAmountTotalAfterFees - _withdrawalAmountTotal;
        }
        else {
             netAmountEvent = _withdrawalAmountTotal - _depositAmountTotalAfterFees;
        
        }
        return netAmountEvent;
    }

    /**
     * @dev Protect against slippage due to assets sale.
     * @param _withdrawalAmount the value of sold assets in Stablecoin.
     * _withdrawalAmount has to be sent to the contract.
     * treasury has to approve the contract for both Stablecoin and token.
     * @return Missed amount to send to the contract due to slippage.
     */
    function protectAgainstSlippage(uint256 _withdrawalAmount) external onlyManager 
        returns (uint256) {
        require(_withdrawalAmount != 0, "Formation.Fi: zero amount");

        require(netDepositInd == 0, "Formation.Fi: no slippage");
       
       uint256 _amount = 0; 
       uint256 _deltaAmount =0;
       uint256 _slippage = 0;
       uint256  _tokenAmount = 0;
       uint256 _balanceTokenTreasury = token.balanceOf(treasury);
       uint256 _balanceStableTreasury = stableToken.balanceOf(treasury) * amountScaleDecimals;
      
        if (_withdrawalAmount< netAmountEvent){
            _amount = netAmountEvent - _withdrawalAmount;   
            _slippage = (_amount * FACTOR_FEES_DECIMALS ) / netAmountEvent;
            if (_slippage >= slippageTolerance) {
                return netAmountEvent;
            }
            else {
                 _deltaAmount = Math.min( _amount, _balanceStableTreasury);
                if ( _deltaAmount  > 0){
                    stableToken.safeTransferFrom(treasury, investement, _deltaAmount/amountScaleDecimals);
                    _tokenAmount = (_deltaAmount * FACTOR_PRICE_DECIMALS)/tokenPrice;
                    token.mint(treasury, _tokenAmount);
                    return _amount - _deltaAmount;
                }
                else {
                     return _amount; 
                }  
            }    
        
        }
        else  {
           _amount = _withdrawalAmount - netAmountEvent;   
          _tokenAmount = (_amount * FACTOR_PRICE_DECIMALS)/tokenPrice;
          _tokenAmount = Math.min(_tokenAmount, _balanceTokenTreasury);
          if (_tokenAmount >0) {
              _deltaAmount = (_tokenAmount * tokenPrice)/FACTOR_PRICE_DECIMALS;
              stableToken.safeTransfer(treasury, _deltaAmount/amountScaleDecimals);   
              token.burn( treasury, _tokenAmount);
            }
           if ((_amount - _deltaAmount) > 0) {
            
              stableToken.safeTransfer(safeHouse, (_amount - _deltaAmount)/amountScaleDecimals); 
            }
        }
        return 0;

    } 

     /**
     * @dev Send Stablecoin from the manager to the contract.
     * @param _amount  tha amount to send.
     */
    function sendStableTocontract(uint256 _amount) external 
     onlyManager {
      require( _amount > 0,  "Formation.Fi: zero amount");

      stableToken.safeTransferFrom(msg.sender, address(this),
       _amount/amountScaleDecimals);
    }

   
     /**
     * @dev Send Stablecoin from the contract to the contract Investement.
     */
    function sendStableFromcontract() external 
        onlyManager {
        require(investement != address(0),
            "Formation.Fi: zero address"
        );
         stableToken.safeTransfer(investement, stableToken.balanceOf(address(this)));
    }
  
}

// File: contracts_ETH/utils/Pausable.sol


pragma solidity ^0.8.4;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Transaction is not available");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Transaction is available");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// File: contracts_ETH/main/Assets.sol


pragma solidity ^0.8.4;




/** 
* @author Formation.Fi.
* @notice Implementation of the contract Assets.
*/

contract Assets is  Pausable {
    using SafeERC20 for IERC20;
    struct Asset{
        address  token;
        address oracle;
        uint256 price;
        uint256 decimals;   
    }

    uint256 public index;
    Asset[] public  assets;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public indexAsset;
    Admin public admin;
    constructor(address _admin) {
         require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
         admin = Admin(_admin);
    }


    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: no manager");
        _;
    }

    modifier onlyManagerOrOwner() {
        address _manager = admin.manager();
        require( (msg.sender == _manager) || ( msg.sender == owner()),
        "Formation.Fi: no manager or owner");
        _;
    }

    /**
     * @dev Getter functions .
     */
    function isWhitelist( address _token) external view  returns (bool) {
        return whitelist[_token];
    }
    function getIndex( address _token) external view  returns (uint256) {
        return indexAsset[_token];
    }


     /**
     * @dev Setter functions .
     */
    function setAdmin(address _admin) external onlyOwner {
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        
        admin = Admin(_admin);
    } 


    /**
     * @dev Add an asset .
     * @param  _token The address of the asset.
     * @param  _oracle The address of the oracle.
     * @param  _price The price in the case where the oracle doesn't exist.
     */
    function addAsset( address _token, address _oracle, uint256 _price) 
        external onlyOwner {
        require ( whitelist[_token] == false, "Formation.Fi: Token exists");
        if (_oracle == address(0)){
           require(_price != 0, "zero price");
        }
        else {
        require(_price == 0, "not zero price");
        }
        uint8 _decimals = 0;
        if (_token!=address(0)){
        _decimals = ERC20(_token).decimals();
        }
        Asset memory _asset = Asset(_token, _oracle, _price, _decimals);
        indexAsset[_token] = index;
        assets.push(_asset);
        index = index +1;
        whitelist[_token] = true;
    }
    
     /**
     * @dev Remove an asset .
     * @param  _token The address of the asset.
     */
    function removeAsset( address _token) external onlyManagerOrOwner {
        require ( whitelist[_token] == true, "Formation.Fi: no Token");
        whitelist[_token] = false;
    }

    /**
     * @dev update the asset's oracle .
     * @param  _token The address of the asset.
     * @param  _oracle The new oracle's address.
     */
    function updateOracle( address _token, address _oracle) external onlyOwner {
        require ( whitelist[_token] == true, "Formation.Fi: no token");
        uint256 _index = indexAsset[_token];
        assets[_index].oracle = _oracle;
    }

    /**
     * @dev update the asset's price .
     * @param  _token The address of the asset.
     * @param  _price The new price's address.
     */
    function updatePrice( address _token, uint256 _price) external onlyOwner {
        require ( whitelist[_token] == true, "Formation.Fi: no token");
        require ( _price != 0, "Formation.Fi: zero price");
        uint256 _index = indexAsset[_token];
        require (assets[_index].oracle == address(0), " no zero address");
        assets[_index].price = _price;
    }
    
}

// File: contracts_ETH/main/SafeHouse.sol


pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";








/** 
* @author Formation.Fi.
* @notice Implementation of the contract SafeHouse.
*/

contract SafeHouse is  Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;
    uint256 public constant  FACTOR_DECIMALS = 8;
    uint256 public constant STABLE_DECIMALS = 1e18;
    uint256 public maxWithdrawalStatic = 1000000 * 1e18;
    uint256 public maxWithdrawalDynamic =  1000000 * 1e18; 
    uint256 public  tolerance;
    mapping(address => bool) public vaultsList;
    Assets public assets;
    Admin public admin;
    constructor( address _assets, address _admin) payable {
        require(
            _assets != address(0),
            "Formation.Fi: zero address"
        );
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        assets = Assets(_assets);

        admin = Admin(_admin);
    }
   

    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: no manager");
        _;
    }


     /**
     * @dev Setter functions.
     */
     function setMaxWithdrawalStatic( uint256 _maxWithdrawalStatic) external onlyOwner {
     maxWithdrawalStatic = _maxWithdrawalStatic;
     }
    
    function setMaxWithdrawalDynamic( uint256 _maxWithdrawalDynamic) external onlyOwner {
     maxWithdrawalDynamic = _maxWithdrawalDynamic;
     }

    function setTolerance( uint256 _tolerance) external  onlyOwner {
     tolerance = _tolerance;
    }

    function setAdmin(address _admin) external onlyOwner {
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        
        admin = Admin(_admin);
    } 

    /**
     * @dev Add a vault address the manager.
     * @param  _vault vault'address.
     */
    function addVault( address _vault) external onlyOwner {
        require(
            _vault != address(0),
            "Formation.Fi: zero address"
        );
        vaultsList[_vault] = true; 
     }

    /**
     * @dev Remove a vault address the manager.
     * @param  _vault vault'address.
     */
    function removeVault( address _vault) external onlyOwner {
        require(
            vaultsList[_vault]== true,
            "Formation.Fi: no vault"
        );
        vaultsList[_vault] = false; 
     }
    
     /**
     * @dev Send an asset to the contract by the manager.
     * @param _asset asset'address.
     * @param _amount amount to send.
     */
    function sendAsset( address _asset, uint256 _amount) 
        external whenNotPaused onlyManager payable {
        uint256 _index =  assets.getIndex(_asset);
        uint256 _price;
        uint256 _decimals;
        uint256 _decimalsPrice;
        address _oracle;
        ( , _oracle, _price, _decimals ) = assets.assets(_index);
        (_price, _decimalsPrice) = getLatestPrice( _asset, _oracle, _price);
      
        maxWithdrawalDynamic = Math.min(maxWithdrawalDynamic + (_amount * _price) / (10 ** _decimalsPrice),
        maxWithdrawalStatic);


        if ( _asset == address(0)) {
          require (_amount == msg.value, "Formation.Fi: wrong amount");
        }
        else {
            uint256 _scale;
            _scale = Math.max((STABLE_DECIMALS/ 10 ** _decimals), 1);
            IERC20 asset = IERC20(_asset);
            asset.safeTransferFrom(msg.sender, address(this), _amount/_scale); 
        }
        
    }

    /**
     * @dev Withdraw an asset from the contract by the manager.
     * @param _asset asset'address.
     * @param _amount amount to send.
     */
    function withdrawAsset( address _asset, uint256 _amount) external whenNotPaused onlyManager {
        uint256 _index =  assets.getIndex(_asset);
        uint256 _price;
        uint256 _decimals;
        uint256 _decimalsPrice;
        address _oracle;
        ( , _oracle, _price, _decimals ) = assets.assets(_index);
        (_price, _decimalsPrice) = getLatestPrice( _asset, _oracle, _price);
        uint256 _delta = (_amount * _price)  / (10 ** _decimalsPrice);
        require ( Math.min(maxWithdrawalDynamic, maxWithdrawalStatic) >= _delta , "Formation.Fi: maximum withdrawal");
        maxWithdrawalDynamic = maxWithdrawalDynamic  - _delta  + (_delta * tolerance)/(10 ** FACTOR_DECIMALS);
         if ( _asset == address(0)) {
         payable(msg.sender).transfer(_amount);
        }
        else {
        uint256 _scale;
        _scale = Math.max((STABLE_DECIMALS/ 10 **_decimals), 1);
        IERC20 asset = IERC20(_asset);
        asset.safeTransfer(msg.sender, _amount/_scale);   
        } 

    }

    /**
     * @dev Get the asset's price.
     * @param _asset asset'address.
     * @param _oracle oracle'address.
     * @param _price asset'price.
     * @return price
     */

    function getLatestPrice( address _asset, address _oracle, uint256 _price) public view returns (uint256, uint256) {
        require (assets.isWhitelist(_asset) ==true, "Formation.Fi: not asset");
        if (_oracle == address(0)) {
            return (_price, FACTOR_DECIMALS);
        }
        else {
        AggregatorV3Interface  priceFeed = AggregatorV3Interface(_oracle);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        uint8 _decimals = priceFeed.decimals();
        return (uint256(price), _decimals);
        }   
    }

     /**
     * @dev Send an asset to the vault.
     * @param _asset asset'address.
     * @param _vault vault'address.
     * @param _amount to send.
     */
    function sendToVault( address _asset, address _vault,  uint256 _amount) external
        whenNotPaused onlyManager {
        require (_vault !=address(0) , "Formation.Fi: zero address");
        require (vaultsList[_vault] == true , "Formation.Fi: no vault");
        uint256 _index =  assets.getIndex(_asset);
        uint256 _decimals;
        ( , , , _decimals ) = assets.assets(_index);
        if ( _asset == address(0)){
           require (_amount <= address(this).balance , 
           "Formation.Fi: balance limit");
           payable (_vault).transfer(_amount);
        }
        else{
            uint256 _scale;
            _scale = Math.max((STABLE_DECIMALS/ 10 ** _decimals), 1);
            IERC20 asset = IERC20(_asset);
           require ((_amount/_scale) <= asset.balanceOf(address(this)) , "Formation.Fi: balance limit");
           asset.transfer(_vault, _amount/_scale);   
        
        }
    }


    fallback() external payable {
     
    }

     receive() external payable {
       
    }


    
       

}

// File: contracts_ETH/main/Investment.sol


pragma solidity ^0.8.4;









/** 
* @author Formation.Fi.
* @notice Implementation of the contract Investement.
*/

contract Investment is Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant FACTOR_FEES_DECIMALS = 1e4;
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e6; 
    uint256 public amountScaleDecimals = 1;
    uint256 public maxDepositAmount = 1000000 * 1e18;
    uint256 public maxWithdrawalAmount = 1000000 * 1e18;
     uint256 public maxDeposit;
    uint256 public maxWithdrawal;
    uint256 public depositFeeRate;
    uint256 public depositFeeRateParity;
    uint256 public tokenPrice;
    uint256 public tokenPriceMean;
    uint256 public netDepositInd;
    uint256 public netAmountEvent;
    uint256 public withdrawalAmountTotal;
    uint256 public withdrawalAmountTotalOld;
    uint256 public depositAmountTotal;
    uint256 public validatedDepositParityStableAmount;
    uint256 public validatedWithdrawalParityStableAmount;
    uint256 public validatedDepositParityTokenAmount;
    uint256 public validatedWithdrawalParityTokenAmount;
    uint256 public tokenTotalSupply;
    uint256 public tokenIdDeposit;
    uint256 public tokenIdWithdraw;
    address private treasury;
    address private safeHouse;
    address public parity;
    mapping(address => uint256) public acceptedWithdrawalPerAddress;
    Admin public admin;
    IERC20 public stableToken;
    Token public token;
    DepositConfirmation public deposit;
    WithdrawalConfirmation public withdrawal;
    event DepositRequest(address indexed _address, uint256 _amount);
    event CancelDepositRequest(address indexed _address, uint256 _amount);
    event WithdrawalRequest(address indexed _address, uint256 _amount);
    event CancelWithdrawalRequest(address indexed _address, uint256 _amount);
    event ValidateDeposit(address indexed _address, uint256 _finalizedAmount, uint256 _mintedAmount);
    event ValidateWithdrawal(address indexed _address, uint256 _finalizedAmount, uint256 _SentAmount);
   
    constructor(address _admin, address _safeHouse, address _stableTokenAddress, 
        address _token,  address _depositConfirmationAddress, 
        address __withdrawalConfirmationAddress) {
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        require(
            _safeHouse != address(0),
            "Formation.Fi:  zero address"
        );
        require(
            _stableTokenAddress != address(0),
            "Formation.Fi:  zero address"
        );
        require(
           _token != address(0),
            "Formation.Fi:  zero address"
        );
        require(
           _depositConfirmationAddress != address(0),
            "Formation.Fi:  zero address"
        );
        require(
            __withdrawalConfirmationAddress != address(0),
            "Formation.Fi:  zero address"
        );
        
        admin = Admin(_admin);
        safeHouse = _safeHouse;
        stableToken = IERC20(_stableTokenAddress);
        token = Token(_token);
        deposit = DepositConfirmation(_depositConfirmationAddress);
        withdrawal = WithdrawalConfirmation(__withdrawalConfirmationAddress);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
           amountScaleDecimals = 1e12;
        }
    }
  
    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: no manager");
        _;
    }

    modifier cancel() {
        bool  _isCancel = admin.isCancel();
        require( _isCancel == true, "Formation.Fi: no cancel");
        _;
    }

     /**
     * @dev Setter functions to update the Portfolio Parameters.
     */
    function setMaxDepositAmount(uint256 _maxDepositAmount) external 
        onlyManager {
        maxDepositAmount = _maxDepositAmount;

    }
    function setMaxWithdrawalAmount(uint256 _maxWithdrawalAmount) external 
        onlyManager{
         maxWithdrawalAmount = _maxWithdrawalAmount;      
    }

    function setParity(address _parity) external onlyOwner{
        require(
            _parity != address(0),
            "Formation.Fi: zero address"
        );

        parity = _parity;      
    }

    function setSafeHouse(address _safeHouse) external onlyOwner{
          require(
            _safeHouse != address(0),
            "Formation.Fi: zero address"
        );  
        safeHouse = _safeHouse;
    }
     /**
     * @dev Calculate net deposit indicator
     */
    function calculateNetDepositInd( ) public onlyManager {
        updateAdminData();
        netDepositInd = admin.calculateNetDepositInd(depositAmountTotal, withdrawalAmountTotal,
        maxDepositAmount,  maxWithdrawalAmount);
    }

     /**
     * @dev Calculate net amount 
     */
    function calculateNetAmountEvent( ) public onlyManager {
        netAmountEvent = admin.calculateNetAmountEvent(depositAmountTotal,  withdrawalAmountTotal,
        maxDepositAmount,  maxWithdrawalAmount);
    }

     /**
     * @dev Calculate the maximum deposit amount to be validated 
     * by the manager for the users.
     */
    function calculateMaxDepositAmount( ) public onlyManager {
             maxDeposit = Math.min(depositAmountTotal, maxDepositAmount);
        }
    
     /**
     * @dev Calculate the maximum withdrawal amount to be validated 
     * by the manager for the users.
     */
    function calculateMaxWithdrawAmount( ) public onlyManager {
        withdrawalAmountTotalOld = withdrawalAmountTotal;
        maxWithdrawal = Math.min(withdrawalAmountTotal, (maxWithdrawalAmount * FACTOR_PRICE_DECIMALS) / tokenPrice);
    }

     /**
     * @dev Calculate the event parameters by the manager. 
     */
    function calculateEventParameters( ) external onlyManager {
        calculateNetDepositInd( );
        calculateNetAmountEvent( );
        calculateMaxDepositAmount( );
        calculateMaxWithdrawAmount( );
    }

     /**
     * @dev  Validate the deposit requests of users by the manager.
     * @param _users the addresses of users.
     */
    function validateDeposits( address[] memory _users) external 
        whenNotPaused onlyManager {
        uint256 _amountStable;
        uint256 _amountStableTotal = 0;
        uint256 _depositToken;
        uint256 _depositTokenTotal = 0;
        uint256 _feeStable;
        uint256 _feeStableTotal = 0;
        uint256 _tokenIdDeposit;
        require (_users.length > 0, "Formation.Fi: no user");
        for (uint256 i = 0; i < _users.length  ; i++) {
             address _user =_users[i];
            (  , _amountStable, )= deposit.pendingDepositPerAddress(_user);
           
            if (deposit.balanceOf(_user) == 0) {
                continue;
              }
            if (maxDeposit <= _amountStableTotal) {
                break;
             }
             _tokenIdDeposit = deposit.getTokenId(_user);
             _amountStable = Math.min(maxDeposit  - _amountStableTotal ,  _amountStable);
             depositAmountTotal =  depositAmountTotal - _amountStable;
             if (_user == parity) {
             _feeStable =  (_amountStable * depositFeeRateParity) /
              FACTOR_FEES_DECIMALS;
             }
             else {
            _feeStable =  (_amountStable * depositFeeRate) /
              FACTOR_FEES_DECIMALS;

             }
             _feeStableTotal = _feeStableTotal + _feeStable;
             _depositToken = (( _amountStable - _feeStable) *
             FACTOR_PRICE_DECIMALS) / tokenPrice;
             if (_user == parity) {
                validatedDepositParityStableAmount  = _amountStable;
                validatedDepositParityTokenAmount  = _depositToken;
             }
             _depositTokenTotal = _depositTokenTotal + _depositToken;
             _amountStableTotal = _amountStableTotal + _amountStable;

             token.mint(_user, _depositToken);
             deposit.updateDepositData( _user,  _tokenIdDeposit, _amountStable, false);
             token.addDeposit(_user,  _depositToken, block.timestamp);
             emit ValidateDeposit( _user, _amountStable, _depositToken);
        }
        maxDeposit = maxDeposit - _amountStableTotal;
        if (_depositTokenTotal > 0){
            tokenPriceMean  = (( tokenTotalSupply * tokenPriceMean) + 
            ( _depositTokenTotal * tokenPrice)) /
            ( tokenTotalSupply + _depositTokenTotal);
            admin.updateTokenPriceMean( tokenPriceMean);
        }
        
        if (admin.managementFeesTime() == 0){
            admin.updateManagementFeeTime(block.timestamp);   
        }
        if ( _feeStableTotal > 0){
           stableToken.safeTransfer( treasury, _feeStableTotal/amountScaleDecimals);
        }
    }

    /**
     * @dev  Validate the withdrawal requests of users by the manager.
     * @param _users the addresses of users.
     */
    function validateWithdrawals(address[] memory _users) external
        whenNotPaused onlyManager {
        uint256 tokensToBurn = 0;
        uint256 _amountLP;
        uint256 _amountStable;
        uint256 _tokenIdWithdraw;
        calculateAcceptedWithdrawalAmount(_users);
        for (uint256 i = 0; i < _users.length; i++) {
            address _user =_users[i];
            if (withdrawal.balanceOf(_user) == 0) {
                continue;
            }
            _amountLP = acceptedWithdrawalPerAddress[_user];

            withdrawalAmountTotal = withdrawalAmountTotal - _amountLP ;
            _amountStable = (_amountLP *  tokenPrice) / 
            ( FACTOR_PRICE_DECIMALS * amountScaleDecimals);

            if (_user == parity) {
               validatedWithdrawalParityStableAmount  =  _amountStable;
               validatedWithdrawalParityTokenAmount = _amountLP;
            }
            stableToken.safeTransfer(_user, _amountStable);
            _tokenIdWithdraw = withdrawal.getTokenId(_user);
            withdrawal.updateWithdrawalData( _user,  _tokenIdWithdraw, _amountLP, false);
            tokensToBurn = tokensToBurn + _amountLP;
            token.updateTokenData(_user, _amountLP);
            delete acceptedWithdrawalPerAddress[_user]; 
            emit ValidateWithdrawal(_user,  _amountLP, _amountStable);
        }
        if ((tokensToBurn) > 0){
           token.burn(address(this), tokensToBurn);
        }
        if (withdrawalAmountTotal == 0){
            withdrawalAmountTotalOld = 0;
        }
    }

    /**
     * @dev  Make a deposit request.
     * @param _user the addresses of the user.
     * @param _amount the deposit amount in Stablecoin.
     */
    function depositRequest(address _user, uint256 _amount) external whenNotPaused {
        require(_amount >= admin.minAmount(), 
        "Formation.Fi: min Amount");
        if (deposit.balanceOf( _user)==0){
            tokenIdDeposit = tokenIdDeposit +1;
            deposit.mint( _user, tokenIdDeposit, _amount);
        }
        else {
            uint256 _tokenIdDeposit = deposit.getTokenId(_user);
            deposit.updateDepositData (_user,  _tokenIdDeposit, _amount, true);
        }
        depositAmountTotal = depositAmountTotal + _amount; 
        stableToken.safeTransferFrom(msg.sender, address(this), _amount/amountScaleDecimals);
        emit DepositRequest(_user, _amount);
    }

    /**
     * @dev  Cancel the deposit request.
     * @param _amount the deposit amount to cancel in Stablecoin.
     */
    function cancelDepositRequest(uint256 _amount) external whenNotPaused cancel {
        uint256 _tokenIdDeposit = deposit.getTokenId(msg.sender);
        require( _tokenIdDeposit > 0, 
        "Formation.Fi: no deposit request"); 
        deposit.updateDepositData(msg.sender,  _tokenIdDeposit, _amount, false);
        depositAmountTotal = depositAmountTotal - _amount; 
        stableToken.safeTransfer(msg.sender, _amount/amountScaleDecimals);
        emit CancelDepositRequest(msg.sender, _amount);      
    }
    
     /**
     * @dev  Make a withdrawal request.
     * @param _amount the withdrawal amount in Token.
     */
    function withdrawRequest(uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: zero amount");
        require(withdrawal.balanceOf(msg.sender) == 0, "Formation.Fi: request on pending");
        if (msg.sender != parity) {
        require (token.checklWithdrawalRequest(msg.sender, _amount, admin.lockupPeriodUser()),
         "Formation.Fi: locked position");
        }
        tokenIdWithdraw = tokenIdWithdraw +1;
        withdrawal.mint(msg.sender, tokenIdWithdraw, _amount);
        withdrawalAmountTotal = withdrawalAmountTotal + _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit WithdrawalRequest(msg.sender, _amount);
         
    }

     /**
     * @dev Cancel the withdrawal request.
     * @param _amount the withdrawal amount in Token.
     */
    function cancelWithdrawalRequest( uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: zero amount");
        uint256 _tokenIdWithdraw = withdrawal.getTokenId(msg.sender);
        require( _tokenIdWithdraw > 0, 
        "Formation.Fi: no request"); 
        withdrawal.updateWithdrawalData(msg.sender, _tokenIdWithdraw, _amount, false);
        withdrawalAmountTotal = withdrawalAmountTotal - _amount;
        token.transfer(msg.sender, _amount);
        emit CancelWithdrawalRequest(msg.sender, _amount);
    }
    
    /**
     * @dev Send Stablecoins to the SafeHouse by the manager.
     * @param _amount the amount to send.
     */
    function sendToSafeHouse(uint256 _amount) external 
        whenNotPaused onlyManager {
        require( _amount > 0,  "Formation.Fi: zero amount");
        uint256 _scaledAmount = _amount/amountScaleDecimals;
        require(
            stableToken.balanceOf(address(this)) >= _scaledAmount,
            "Formation.Fi: exceeds balance"
        );
        stableToken.safeTransfer(safeHouse, _scaledAmount);
    }
    
     /**
     * @dev update data from Admin contract.
     */
    function updateAdminData() internal { 
        depositFeeRate = admin.depositFeeRate();
        depositFeeRateParity = admin.depositFeeRateParity();
        tokenPrice = admin.tokenPrice();
        tokenPriceMean = admin.tokenPriceMean();
        tokenTotalSupply = token.totalSupply();
        treasury = admin.treasury();
    }
    
    /**
     * @dev Calculate the accepted withdrawal amounts for users.
     * @param _users the addresses of users.
     */
    function calculateAcceptedWithdrawalAmount(address[] memory _users) 
        internal {
        require (_users.length > 0, "Formation.Fi: no user");
        uint256 _amountLP;
        address _user;
        for (uint256 i = 0; i < _users.length; i++) {
            _user = _users[i];
            require( _user!= address(0), "Formation.Fi: zero address");
            ( , _amountLP, )= withdrawal.pendingWithdrawPerAddress(_user);
            if (withdrawal.balanceOf(_user) == 0) {
                continue;
            }
           _amountLP = Math.min((maxWithdrawal * _amountLP)/
            withdrawalAmountTotalOld, _amountLP); 
           acceptedWithdrawalPerAddress[_user] = _amountLP;
        }   
    }
    
}

// File: contracts_ETH/Gamma/InvestmentGamma.sol


pragma solidity ^0.8.4;



/** 
* @author Formation.Fi.
* @notice Implementation of the contract InvestementGamma.
*/

contract InvestmentGamma is Investment {
        constructor(address _admin,  address _safeHouse, address _stableToken, address _token,
        address _deposit, address _withdrawal) Investment( _admin, _safeHouse,  _stableToken,  _token,
         _deposit,  _withdrawal) {
        }
}