/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
    ) private returns (bool) {
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

// File: contracts/OnChainBabyOtter.sol


pragma solidity >=0.7.0 <0.9.0;







/**
 * 100% ethereum on-chain baby otter, by Prof. Otterlove.
 *
 *
 * I did an experiment to create the cutest animal on the blockchain,
 * and the cutest animal is otter, it's obvious.
 * I don't want people to fight over my cute babies otters,
 * that's why there isn't one more rare than another.
 * By the way, I've noticed that babies otters
 * can take differents characters on adoption.
 *
 * Be good parents, they are not toys, they have a heart...
 * But, they are so cute, so I have no doubts.
 *
 */
contract OnChainBabyOtter is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _babyOtterIds;
    using Strings for uint256;

    bool pauseAdoption = true;
    bool revealed;
    mapping(address => bool) internal _minted;
    mapping(uint256 => uint256) internal _dna;
    mapping(uint256 => uint256) internal _natureOtter;
    event registerOfBabyOtterOwners(address _address, uint256 _otterId);

    constructor() ERC721("OnChain Baby Otter", "OBO") {
        /*
         * @Prof., thank you for funding my function.
         *
         *                  Yours truly,
         *                  b0162fcbd0d41d88
         *                  d1d1b03a103cab83
         *                  9d8983332d9f1f52
         *                  cda62016d5df3594,
         *                      xoxo
         */
        setPriceFeed(0, 0xAc559F25B1619171CbC396a50854A3240b6A4e99);
        setPriceFeed(1, 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        setPriceFeed(2, 0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676);
        setPriceFeed(3, 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);
        setPriceFeed(4, 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }

    /**
     * You can adopt only one baby otter. I'll gladly give you one.
     * Only one so that you can love it as much as possible <3.
     */
    function adoptMyLovelyOtter() external payable {
        require(!pauseAdoption, "Paused");
        require(_babyOtterIds.current() < 2048, "All adopted");
        require(!_minted[msg.sender], "One adoption is allowed");
        _babyOtterIds.increment();
        uint256 newItemId = _babyOtterIds.current();
        _safeMint(msg.sender, newItemId);
        _minted[msg.sender] = true;
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        uint256(blockhash(block.number - 1))
                )
            )
        );
        if (seed % 3 == 0) {
            _dna[newItemId] = seed;
            _natureOtter[newItemId] = 0;
        } else if (seed % 3 == 1) {
            _dna[newItemId] = uint256(keccak256(abi.encodePacked(msg.sender)));
            _natureOtter[newItemId] = 1;
        } else {
            _natureOtter[newItemId] = 2;
        }
    }

    /**
     * This is how your lovely baby otter will look like.
     */
    function babyOtterAppearance(uint256 dna)
        public
        pure
        returns (string memory)
    {
        string memory svg;
        svg = (
            string(
                bytes.concat(
                    abi.encodePacked(
                        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100' shape-rendering='crispEdges'>",
                        "<rect x='0' y='0' width='100' height='100' fill='",
                        getDnaPart(1, dna),
                        "'/>",
                        /*
                         * @Prof., with a small addition.
                         *  ------------
                         *  -----||-----
                         *       ||
                         *       ||
                         *
                         *                  Yours truly,
                         *                  b0162fcbd0d41d88
                         *                  d1d1b03a103cab83
                         *                  9d8983332d9f1f52
                         *                  cda62016d5df3594,
                         *                      xoxo
                         */
                        "<path stroke='#000' d='M41 18h5m8 0h5m-19 1h2m1 0h17m-19 1h5m3 0h2m3 0h5m-10 1h2m-2 1h2m-2 1h2m-4 1h6m-5 1h4m-7 1h10m-12 1h3m9 0h2m-16 1h3m12 0h3m-19 1h2m16 0h2m-21 1h2m18 0h2m-27 1h6m20 0h3m1 0h2m-33 1h2m3 0h1m22 0h1m3 0h2m-34 1h1m3 0h2m22 0h2m3 0h2m-36 1h1m4 0h1m3 0h5m8 0h5m3 0h1m4 0h1m-36 1h1m3 0h2m2 0h2m3 0h2m6 0h2m3 0h2m2 0h2m3 0h1m-36 1h1m3 0h1m2 0h2m5 0h1m6 0h1m5 0h2m2 0h1m-32 1h2m2 0h1m2 0h1m6 0h1m6 0h1m6 0h1m2 0h1m2 0h2m-35 1h2m1 0h1m2 0h1m6 0h1m6 0h1m6 0h1m2 0h1m1 0h1m-32 1h1m1 0h1m2 0h1m6 0h1m6 0h1m6 0h1m2 0h3m-30 1h1m2 0h2m4 0h2m6 0h2m4 0h2m2 0h1m-28 1h1m3 0h2m2 0h2m8 0h2m2 0h2m3 0h1m-28 1h1m4 0h1m1 0h2m10 0h4m4 0h1m-16 1h1m2 0h1m11 0h1m-28 1h1m11 0h4m11 0h1m-28 1h2m11 0h2m12 0h1m-27 1h1m8 0h1m2 0h2m2 0h1m8 0h1m-26 1h1m8 0h8m8 0h1m-26 1h2m22 0h2m-25 1h2m20 0h2m-23 1h1m20 0h1m-22 1h2m18 0h2m-21 1h3m14 0h3m-18 1h3m10 0h3m-16 1h1m1 0h13m-16 1h2m13 0h2m-17 1h1m15 0h1m-18 1h2m3 0h1m11 0h2m-19 1h1m4 0h1m12 0h1m-19 1h1m4 0h1m8 0h3m1 0h2m-21 1h2m4 0h1m2 0h4m2 0h1m4 0h1m-21 1h1m5 0h1m5 0h1m1 0h1m1 0h2m1 0h2m-21 1h1m5 0h1m3 0h3m1 0h3m1 0h2m-21 1h1m6 0h2m3 0h1m4 0h3m-20 1h1m7 0h5m5 0h1m-19 1h1m8 0h1m8 0h3m-21 1h1m8 0h2m9 0h1m-21 1h1m9 0h1m7 0h1m1 0h1m-21 1h1m9 0h1m6 0h2m1 0h1m-21 1h1m8 0h2m6 0h1m2 0h1m-21 1h1m8 0h1m6 0h2m1 0h2m-21 1h2m5 0h4m4 0h2m2 0h1m-21 1h4m8 0h5m3 0h3m-24 1h2m2 0h2m4 0h2m5 0h1m2 0h2m1 0h1m-24 1h1m4 0h3m4 0h1m4 0h2m3 0h2m-25 1h2m4 0h1m1 0h6m5 0h5m-26 1h3m4 0h2m-24 1h10m2 0h4m5 0h2m-23 1h2m7 0h2m1 0h1m7 0h2m-21 1h3m15 0h1m-17 1h4m10 0h3m-14 1h5m4 0h3m-8 1h6m8-63h1M32 33h1m34 3h1m-6 9h1M53 60h1m2 6h1m-9 6h1m-1 1h1m-20 5h1m8 1h1m15-52h1m8 4h1M36 43h1m-2-4h1m30-1h1m-25 4h1' />",
                        "<path stroke='",
                        getDnaPart(1000000000, dna)
                    ),
                    abi.encodePacked(
                        "' d='M46 27h7m-9 1h12m-14 1h16m-17 1h9m1 0h8m-19 1h20m-25 1h3m1 0h22m1 0h3m-31 1h3m2 0h22m2 0h3m-33 1h2m3 0h3m5 0h8m5 0h3m3 0h2m-34 1h1m4 0h1m8 0h6m7 0h2m4 0h1m-34 1h2m2 0h2m8 0h6m8 0h2m2 0h2m-32 1h1m1 0h2m8 0h6m8 0h2m1 0h2m-31 1h1m1 0h2m8 0h6m8 0h2m1 0h1m-28 1h2m8 0h6m8 0h2m-26 1h2m8 0h6m8 0h2m-26 1h3m6 0h8m6 0h3m-26 1h4m4 0h10m4 0h1m1 0h2m-26 1h11m2 0h1m1 0h11m-26 1h11m4 0h11m-25 1h5m14 0h4m-23 1h2m20 0h2m-19 8h1m-1 1h5m7 0h1m-14 1h6m7 0h2m-15 1h3m1 0h2m8 0h1m-16 1h4m1 0h2m8 0h2m-17 1h4m1 0h2m9 0h1m-17 1h4m1 0h2m7 0h4m-19 1h5m1 0h5m3 0h1m2 0h1m-18 1h5m1 0h3m7 0h1m-18 1h6m2 0h3m-11 1h7m-7 1h8m-8 1h8m10 0h1m-19 1h9m9 0h1m-19 1h9m9 0h1m-19 1h8m9 0h2m-19 1h8m-7 1h5m10 0h2m-16 1h7m7 0h2m-19 1h2m2 0h2m1 0h1m8 0h2m2 0h1m-22 1h4m3 0h4m7 0h3m-21 1h4m-5 1h4m-6 1h5m-19 1h7m4 0h7m-16 1h7m1 0h7m-12 1h10m-6 1h4m20-54h1m6 15h1m-12 1h1m11 2h1m-6 25h1m-13 3h1m5-43h1m-12 5h1M29 79h1m4-42h1m19 35h1' /><path stroke='",
                        getDnaPart(1000000000000000000, dna),
                        "' d='M42 35h3m10 0h3m-17 1h1m1 0h3m8 0h5m-19 1h5m10 0h5m-20 1h4m12 0h4m-20 1h3m14 0h3m-19 1h1m15 0h2m-17 1h1m13 0h2m-16-5h1m-1 4h1m0 1h1m1-4h1m8 0h1m-11 1h2m8 0h2m-13 1h1m12 0h1m-14 1h1m12 0h1m-13-1h2m8 0h2m-12 1h1m10 0h1' /><path stroke='",
                        getDnaPart(1000000000000000000000000000, dna),
                        "' d='M43 37h1m12 0h1m-15 1h3m10 0h3m-15 1h1m12 0h1' /><path stroke='",
                        getDnaPart(1000000000000000000000000000000000000, dna),
                        "' d='M43 45h1m2 0h3m2 0h6m-17 1h6m1 0h2m2 0h2m1 0h6m-22 1h8m8 0h8m-23 1h22m-21 1h4m1 0h15m-20 1h3m1 0h16m-19 1h18m-16 1h14m-12 1h10m-7 2h1m1 0h5m-7 1h7m-7 1h8m-8 1h8m-8 1h5m-1 1h1m-1 1h1m-1 1h1m-2 1h3m-3 1h5m-8 1h8m-7 1h7m-7 1h7m-7 1h6m-6 1h6m-7 1h6m-5 1h4m-9-26h1m0 0h1m3 10h1m-6-6h1m-2 1h1m9 9h1m0 4h1M35 34h2m26 0h2m-31 1h2m28 0h2m-31 1h1m28 0h1' /><path stroke='",
                        getDnaPart(1000000000, dna),
                        "' ><animate id='wk' attributeName='d' dur='0.25s' values='M55 35h1m-14 0h3m11 0h2;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6; M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1 M40 39h6m8 0h6; M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1 M40 39h6m8 0h6 M41 40h3m11 0h4m-15 0h1; M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1 M40 39h6m8 0h6 M41 40h3m11 0h4m-15 0h1 M42 41h2M56 41h2;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1 M40 39h6m8 0h6 M41 40h3m11 0h4m-15 0h1;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1 M40 39h6m8 0h6;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6 M40 38h2m1 0h3m8 0h2m1 0h3m-18 0h1m13 0h1;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1 M40 37h6m8 0h6;M55 35h1m-14 0h3m11 0h2 M41 36h1m1 0h3m8 0h4m-16 0h1m15 0h1;M55 35h1m-14 0h3m11 0h2'  begin='4s;wk.end+4s'/></path></svg>"
                    )
                )
            )
        );
        return svg;
    }

    function tokenURI(uint256 babyOtterId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(babyOtterId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory json;
        if (!revealed) {
            json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name": "Sleeping baby otter #',
                            Strings.toString(babyOtterId),
                            '" , "description": "zzzz.....zzzz.....zzzz.....zzzz", "image_data": "',
                            bytes(
                                string(
                                    abi.encodePacked(
                                        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100' shape-rendering='crispEdges'>",
                                        "<path stroke='#000' d='M45 26h10m-12 1h3m8 0h3m-15 1h2m12 0h2m-17 1h2m14 0h2m-22 1h5m17 0h4m-26 1h1m2 0h1m18 0h1m2 0h1m-27 1h2m1 0h2m18 0h2m1 0h2m-28 1h2m1 0h1m2 0h11m1 0h4m2 0h1m1 0h2m-27 1h3m1 0h2m14 0h2m1 0h3m-24 1h3m5 0h7m4 0h3m-22 1h2m3 0h4m5 0h4m2 0h2m-22 1h1m3 0h2m11 0h2m2 0h1m-22 1h1m2 0h2m13 0h2m1 0h1m-23 1h2m1 0h2m15 0h4m-24 1h2m1 0h1m2 0h1m3 0h1m2 0h1m3 0h1m3 0h3m-23 1h1m1 0h1m2 0h2m1 0h2m2 0h5m3 0h2m-22 1h3m17 0h2m-21 1h2m15 0h4m-22 1h6m11 0h2m1 0h2m-23 1h2m4 0h4m7 0h2m3 0h2m-24 1h1m8 0h3m1 0h5m5 0h1m-24 1h1m10 0h3m3 0h2m4 0h1m-24 1h1m12 0h2m8 0h1m-24 1h1m13 0h2m3 0h1m3 0h1m-24 1h1m14 0h2m3 0h1m2 0h1m-24 1h1m16 0h1m5 0h1m-24 1h1m17 0h1m4 0h1m-24 1h1m18 0h1m3 0h1m-24 1h2m18 0h4m-23 1h2m19 0h1m-22 1h3m18 0h1m-22 1h1m1 0h2m17 0h1m-22 1h1m2 0h2m16 0h1m-22 1h1m3 0h2m15 0h1m-17 1h3m12 0h1m-21 1h2m5 0h2m11 0h1m-20 1h2m5 0h3m8 0h2m-19 1h2m6 0h3m4 0h3m-17 1h3m6 0h2m3 0h2m-16 1h1m1 0h2m11 0h1m-16 1h1m14 0h1m-16 1h2m12 0h2m-15 1h1m12 0h1m-14 1h2m10 0h2m-13 1h2m8 0h2m-11 1h3m5 0h2m-8 1h3m1 0h3m-5 1h3m6-43h1M46 41h1m-8 19h1m20 0h1m-8-27h1m2 15h1m0 2h1'/>",
                                        "<path stroke='#eaeaaa' d='M46 27h8m-10 1h12m-13 1h14m-15 1h16m-20 1h2m1 0h6m1 0h11m1 0h2m-24 1h1m2 0h18m2 0h1m-24 1h1m1 0h2m16 0h2m1 0h1m-22 1h1m2 0h14m2 0h1m-18 1h5m7 0h4m-17 1h3m13 0h2m-19 1h3m15 0h2m-20 1h2m17 0h1m-20 2h1m-1 1h1m17 3h1m-19 1h4m13 0h3m-21 1h8m9 0h5m-22 1h10m3 0h3m2 0h3m-21 1h9m1 0h2m2 0h2m2 0h4m-22 1h13m2 0h3m1 0h3m-22 1h7m1 0h6m2 0h2m2 0h2m-22 1h11m1 0h4m1 0h5m-22 1h17m1 0h4m-22 1h18m1 0h3m-21 1h4m1 0h13m-17 1h6m1 0h10m1 0h1m-18 1h18m-20 1h1m2 0h12m1 0h4m-20 1h2m2 0h3m1 0h12m-20 1h3m2 0h15m-20 1h4m3 0h12m-18 1h5m2 0h11m-17 1h5m3 0h1m1 0h6m-15 1h6m3 0h4m-11 1h6m2 0h3m-13 1h1m2 0h11m-14 1h14m-13 1h12m-12 1h12m-11 1h10m-8 1h7m-6 1h5m-3 1h1m-4-41h1m-8 8h1m7 9h1m6 0h1m-9 7h1m10 0h1m1-8h1m-15 3h1m3 1h1m-7 3h1m10 3h1m-9 1h1m3 4h1m-6 8h1'/>",
                                        "<path stroke='",
                                        _dna[babyOtterId] != 0
                                            ? getDnaPart(
                                                1000000000,
                                                _dna[babyOtterId]
                                            )
                                            : getDnaPart(
                                                1000000000,
                                                uint256(
                                                    keccak256(
                                                        abi.encodePacked(
                                                            ownerOf(babyOtterId)
                                                        )
                                                    )
                                                )
                                            ),
                                        "' d='M48 36h5m-8 1h4m1 0h1m1 0h4m-12 1h5m1 0h1m1 0h5m-14 1h8m1 0h6m-16 1h2m1 0h3m1 0h2m1 0h3m1 0h3m-17 1h2m5 0h2m5 0h2m-16 1h9m1 0h7m-17 1h15m-12 1h11m-8 1h4m1 0h2m-5 1h1m-2-9h1m-1 1h1m1-1h1m-1 1h1m-1 1h1m6 2h1m-7 4h1m-2-3h1'/>",
                                        "</svg>"
                                    )
                                )
                            ),
                            '","attributes":[{"trait_type":"Nature", "value":"',
                            _natureOtter[babyOtterId] == 0
                                ? "Independent"
                                : _natureOtter[babyOtterId] == 1
                                ? "Loyal"
                                : "Fits",
                            '"}]}'
                        )
                    )
                )
            );
        } else {
            json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name": "Baby otter #',
                            Strings.toString(babyOtterId),
                            '" , "description": "I am one of the ',
                            remainingBabyOtter() == 2048
                            /*
                             * @Prof., tell them what it is.
                             *
                             *                  Yours truly,
                             *                  b0162fcbd0d41d88
                             *                  d1d1b03a103cab83
                             *                  9d8983332d9f1f52
                             *                  cda62016d5df3594,
                             *                      xoxo
                             */
                                ? "2048 babies otters. What is this thing on my head?"
                                : Strings.toString(remainingBabyOtter()),
                            remainingBabyOtter() == 2048
                                ? ""
                                : /*
                                 * @Prof., look, they are begging now.
                                 *
                                 *                  Yours truly,
                                 *                  b0162fcbd0d41d88
                                 *                  d1d1b03a103cab83
                                 *                  9d8983332d9f1f52
                                 *                  cda62016d5df3594,
                                 *                      xoxo
                                 */
                                " babies otters remaining. We were 2048... Never touch this thing on my head, please...",
                            '", "image_data": "',
                            _dna[babyOtterId] != 0
                                ? bytes(babyOtterAppearance(_dna[babyOtterId]))
                                : bytes(
                                    babyOtterAppearance(
                                        uint256(
                                            keccak256(
                                                abi.encodePacked(
                                                    ownerOf(babyOtterId)
                                                )
                                            )
                                        )
                                    )
                                ),
                            '","attributes":[{"trait_type":"Nature", "value":"',
                            _natureOtter[babyOtterId] == 0
                                ? "Independent"
                                : _natureOtter[babyOtterId] == 1
                                ? "Loyal"
                                : "Fits",
                            '"}]}'
                        )
                    )
                )
            );
        }

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * Pause adoption of the lovely baby otter.
     */
    function setPauseAdoption(bool _state) external onlyOwner {
        pauseAdoption = _state;
    }

    /**
     * Wake up babies otters, look how cute they are!
     */
    function wakeUp() external onlyOwner {
        revealed = true;
        /*
         * @Prof. you should have checked twice before launching this contract.
         * Enjoy this 5 days...
         *
         *                  Yours truly,
         *                  b0162fcbd0d41d88
         *                  d1d1b03a103cab83
         *                  9d8983332d9f1f52
         *                  cda62016d5df3594,
         *                      xoxo
         */
        countdown = block.timestamp + 432000;
    }

    /**
     * Official register of baby otter owners.
     */
    function registrationOfBabyOtterOwners(uint256 _otterId) external payable {
        require(
            ownerOf(_otterId) == msg.sender,
            "You are not a baby otter owner"
        );
        require(msg.value >= 20000000000000000);
        emit registerOfBabyOtterOwners(msg.sender, _otterId);
    }

    function getBalanceContract() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: getBalanceContract()
        }("");
        require(success);
    }

    function getDnaPart(uint256 _div, uint256 _properties)
        public
        pure
        returns (bytes memory)
    {
        uint256 rr = _properties / _div;
        uint256 r = (rr % 1023) % 256;
        uint256 gg = _properties / (_div * 1000);
        uint256 g = (gg % 1023) % 256;
        uint256 bb = _properties / (_div * 1000000);
        uint256 b = (bb % 1023) % 256;
        return
            abi.encodePacked(
                "rgb(",
                Strings.toString(r),
                ",",
                Strings.toString(g),
                ",",
                Strings.toString(b),
                ")"
            );
    }

    uint256 public countdown = 0;
    mapping(uint256 => AggregatorV3Interface) internal priceFeed;
    uint256 internal countOfPriceFeed = 5;
    uint256 internal min = 1;
    uint256 internal max = 2048;

    function babyOtterExplosion() public {
        /**
         * @Prof., you are completely crazy.
         * I hate otters, i hate people, i hate YOU.
         * I managed to insert this function just before the deployment.
         * It's just to add a little fun. Who doesn't like explosions?
         * When you use this function, half of the remaining babies otters explode.
         * Maybe your otter will explode in front of your eyes! Kaboom!
         *
         *                  Yours truly,
         *                  b0162fcbd0d41d88
         *                  d1d1b03a103cab83
         *                  9d8983332d9f1f52
         *                  cda62016d5df3594,
         *                      xoxo
         *
         */
        require(revealed, "More fun when they are awake");
        require(balanceOf(msg.sender) > 0, "You must have an otter, idiot");
        require(countdown <= block.timestamp, "Tic, Tac...");
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        uint256(blockhash(block.number - 1)) +
                        getAllPrice()
                )
            )
        );
        if (seed % 2 == 0) {
            for (
                uint256 i = min;
                i <= min - 1 + remainingBabyOtter() / 2;
                i++
            ) {
                _burn(i);
            }
            min = min + remainingBabyOtter() / 2;
        } else {
            for (uint256 i = min + remainingBabyOtter() / 2; i <= max; i++) {
                _burn(i);
            }
            max = max - remainingBabyOtter() / 2;
        }
        countdown = block.timestamp + 432000;
    }

    function remainingBabyOtter() internal view returns (uint256) {
        return (max - min) + 1;
    }

    function setPriceFeed(uint256 _val, address _address) public onlyOwner {
        priceFeed[_val] = AggregatorV3Interface(_address);
    }

    function setCountOfPriceFeed(uint256 _val) public onlyOwner {
        countOfPriceFeed = _val;
    }

    function getLatestPrice(uint256 _index) internal view returns (int256) {
        (, int256 price, , , ) = priceFeed[_index].latestRoundData();
        return price;
    }

    function getAllPrice() internal view returns (uint256) {
        /**
         * @Prof., I learned a lot from you.
         * Look how I complicated the calculation of the random number.
         *
         *                  Yours truly,
         *                  b0162fcbd0d41d88
         *                  d1d1b03a103cab83
         *                  9d8983332d9f1f52
         *                  cda62016d5df3594,
         *                      xoxo
         *
         */
        uint256 total;
        for (uint256 i = 0; i < countOfPriceFeed; i++) {
            total += uint256(getLatestPrice(i));
        }
        return total;
    }
}