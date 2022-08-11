/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: contracts/SquareStackWorld.sol

// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity 0.8.15;







contract SquareStackContract is ERC721URIStorage, Ownable {
  using SafeMath for uint256;

  struct SquareStack {
    uint256 stackLevel; // level in stack (0-18)
    uint256 x; // x coord of square
    uint256 y; // y coord of square
    address owner; // address of square owner
    uint256 tokenId; // NFT tokenId (same as square id)
    string squareName; // name given to square (level 18 only)
    string squareExternalURL; // url address for square to point to
    bool active; // is the square active in stack
  }

  struct SquareStackSaleData {
    uint256 salePrice; // sale price of square
    uint256 transferFee; // transfer price of square
    uint256 royaltyPercentage; // square royalty percentage
    bool forSale; // is the square for sale
  }

  struct SquareStackAccount {
    string accountName; // unique profile name for user in metaverse
    string accountURI; // uri of profile image for user
    uint256 accountRoyalties; // users total earnings from square royalties
  }

  struct SquareStackEnriched {
    uint256 stackLevel; // level in stack (0-18)
    uint256 x; // x coord of square
    uint256 y; // y coord of square
    address owner; // address of square owner
    uint256 tokenId; // NFT tokenId (same as square id)
    string squareName; // name given to square (level 18 only)
    string squareExternalURL; // url address for square to point to
    bool active; // is the square active in stack
    string accountName; // profile name of the square owner
    string accountURI; // uri of square owner's profile image
    string tokenURI; // NFT tokenURI
  }

  SquareStackSaleData[22] private squareStackSaleData; // holds sales data for stack

  mapping(uint256 => SquareStack) public squareStackLedger; // map of tokenId returning the Square
  mapping(address => SquareStackAccount) public accountLedger; // users wallet addres to account mapping
  mapping(string => address) public accountNameLedger; // users profile name to wallet address mapping

  uint256[][22] private squareStackWorld; // array used to store metaverse of Squares

  constructor() ERC721("SquareStack World", "SSW") {
    //Set Sales Data
    squareStackSaleData[0] = SquareStackSaleData(
      5828725000000000000000,
      1165745000000000000000,
      0,
      true
    ); //0
    squareStackSaleData[1] = SquareStackSaleData(
      1364601000000000000000,
      272920000000000000000,
      75000,
      true
    ); //1
    squareStackSaleData[2] = SquareStackSaleData(
      875802000000000000000,
      175160000000000000000,
      37500,
      true
    ); //2
    squareStackSaleData[3] = SquareStackSaleData(
      657625000000000000000,
      131525000000000000000,
      25000,
      true
    ); //3
    squareStackSaleData[4] = SquareStackSaleData(
      521499000000000000000,
      104300000000000000000,
      18750,
      true
    ); //4
    squareStackSaleData[5] = SquareStackSaleData(
      413550000000000000000,
      82710000000000000000,
      15000,
      true
    ); //5
    squareStackSaleData[6] = SquareStackSaleData(
      316839000000000000000,
      63368000000000000000,
      12500,
      true
    ); //6
    squareStackSaleData[7] = SquareStackSaleData(
      228905000000000000000,
      45781000000000000000,
      10714,
      true
    ); //7
    squareStackSaleData[8] = SquareStackSaleData(
      153093000000000000000,
      30619000000000000000,
      9375,
      true
    ); //8
    squareStackSaleData[9] = SquareStackSaleData(
      93403000000000000000,
      18681000000000000000,
      8333,
      true
    ); //9
    squareStackSaleData[10] = SquareStackSaleData(
      51349000000000000000,
      10270000000000000000,
      7500,
      true
    ); //10
    squareStackSaleData[11] = SquareStackSaleData(
      25174000000000000000,
      5035000000000000000,
      6818,
      true
    ); //11
    squareStackSaleData[12] = SquareStackSaleData(
      10907000000000000000,
      2181000000000000000,
      6250,
      true
    ); //12
    squareStackSaleData[13] = SquareStackSaleData(
      4144000000000000000,
      829000000000000000,
      5769,
      true
    ); //13
    squareStackSaleData[14] = SquareStackSaleData(
      1371000000000000000,
      274000000000000000,
      5357,
      true
    ); //14
    squareStackSaleData[15] = SquareStackSaleData(
      392000000000000000,
      78000000000000000,
      5000,
      true
    ); //15
    squareStackSaleData[16] = SquareStackSaleData(
      97000000000000000,
      19000000000000000,
      4687,
      true
    ); //16
    squareStackSaleData[17] = SquareStackSaleData(
      20000000000000000,
      4000000000000000,
      4411,
      true
    ); //17
    squareStackSaleData[18] = SquareStackSaleData(
      4000000000000000,
      4000000000000000,
      4166,
      true
    ); //18
    squareStackSaleData[19] = SquareStackSaleData(
      4000000000000000,
      4000000000000000,
      4166,
      true
    ); //19
    squareStackSaleData[20] = SquareStackSaleData(
      4000000000000000,
      4000000000000000,
      4166,
      true
    ); //20
    squareStackSaleData[21] = SquareStackSaleData(
      4000000000000000,
      4000000000000000,
      4166,
      true
    ); //21
  }

  //
  // function called once transfer is completed.  ensures Square is inactivated upon transfer.
  //
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._afterTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      squareStackLedger[tokenId].owner = to;
      squareStackLedger[tokenId].active = false;
    }
  }

  //
  // function called in order to pay fee and reactive Square after transfer
  //
  function payTransferFee(
    uint256 tokenId,
    string memory squareName,
    string memory squareExternalURL,
    string memory accountName,
    string memory accountURI
  ) public payable {
    SquareStack memory squareToPayFeeFor = squareStackLedger[tokenId];
    require(squareToPayFeeFor.owner == msg.sender, "not square owner");
    require(squareToPayFeeFor.active == false, "already active");

    // get fee to pay from sale data
    uint256 feeToPay = squareStackSaleData[squareToPayFeeFor.stackLevel]
      .transferFee;

    require(msg.value >= feeToPay, "not enough eth to pay fee");

    // get profile account of sender
    SquareStackAccount memory squareStackAccount = accountLedger[msg.sender];

    // if account was found
    if (bytes(squareStackAccount.accountName).length > 0) {
      // existing account was found
      // account name found needs to be same as account name of sender
      require(
        compareStrings(squareStackAccount.accountName, accountName) == true,
        "Account name not correct"
      );
    } else {
      // must be setting up a new account
      // ensure account name does not already exist
      require(
        accountNameLedger[accountName] == address(0),
        "Account name already exists"
      );
      // new accounts need an accountURI
      require(bytes(accountURI).length > 0, "New accounts need account URL");

      // store new account in the account ledger
      accountLedger[msg.sender] = SquareStackAccount({
        accountName: accountName,
        accountURI: accountURI,
        accountRoyalties: 0
      });

      // store new account name in the account name ledger
      accountNameLedger[accountName] = msg.sender;
    }

    // if a new external URL was provided then set the Square's externalURL to new URL
    if (bytes(squareExternalURL).length > 0) {
      squareStackLedger[tokenId].squareExternalURL = squareExternalURL;
    }

    // if new Square name was provided then set it.  only for stack level 21
    if (bytes(squareName).length > 0) {
      require(
        squareStackLedger[tokenId].stackLevel == 21,
        "only level 21 can have name"
      );
      squareStackLedger[tokenId].squareName = squareName;
    }

    //set Square to be active
    squareStackLedger[tokenId].active = true;

    // pay royalties up stack
    payRoyalties(
      squareToPayFeeFor.stackLevel,
      squareToPayFeeFor.x,
      squareToPayFeeFor.y,
      feeToPay
    );
  }

  //
  // mint a square NFT and add it to the metaverse
  //
  function mintSquare(
    string memory metaDataURI, // URI of meta data
    uint256 stackLevel, // Level in stack to mint (0-18)
    uint256 x, // x coordinate of square
    uint256 y, // y coordinate of square
    string memory squareName, // name for square.  only valid for stacklevel 18.
    string memory squareExternalURL, // url address for square to point to.  only valid for stacklevel 18. (optional)
    string memory mintingAccountName, // profile name of account owner
    string memory mintingAccountURI // URI of profile image
  ) public payable returns (uint256) {
    // make sure profile account name was sent
    require(
      bytes(mintingAccountName).length > 0,
      "Invalid minting account name"
    );

    // make sure meta data URI was sent
    require(bytes(metaDataURI).length > 0, "No metadata");

    // get profile account for senders address
    SquareStackAccount memory squareStackAccount = accountLedger[msg.sender];

    // check if profile account was found
    if (bytes(squareStackAccount.accountName).length > 0) {
      // existing profile account was found therefore must be an existing account
      // ensure account name that was found is the same as the one sent
      require(
        compareStrings(squareStackAccount.accountName, mintingAccountName) ==
          true,
        "Account name not correct"
      );
    } else {
      // no existing profile account was found so must need to set up a new one
      // check if new account name sent already exists
      require(
        accountNameLedger[mintingAccountName] == address(0),
        "Account name already exists"
      );
      // ensure new account has an account profile image
      require(
        bytes(mintingAccountURI).length > 0,
        "New accounts need account URL"
      );
    }

    // ensure square to be minted as valid parameters
    validateSquare(stackLevel, x, y, squareName, squareExternalURL);

    // generate a unique id fod the Square.  squareID is used as tokenID
    uint256 squareID = generateSquareID(stackLevel, x, y);

    // check is Square has already been minted
    SquareStack memory squareStack = squareStackLedger[squareID];
    require(squareStack.owner == address(0), "square already minted");

    // mint NFT
    _safeMint(msg.sender, squareID);
    // set the tokenURI to be the meta data URI sent
    _setTokenURI(squareID, metaDataURI);

    // add the Square to the square stack ledger
    squareStackLedger[squareID] = SquareStack({
      stackLevel: stackLevel,
      x: x,
      y: y,
      owner: msg.sender,
      tokenId: squareID,
      squareName: squareName,
      squareExternalURL: squareExternalURL,
      active: true
    });

    // add the square to the metaverse
    squareStackWorld[stackLevel].push(squareID);

    // if setting up a new prodile account
    if (bytes(squareStackAccount.accountName).length == 0) {
      // add new profile account to the account ledger
      accountLedger[msg.sender] = SquareStackAccount({
        accountName: mintingAccountName,
        accountURI: mintingAccountURI,
        accountRoyalties: 0
      });
      // add new profile account name to the account name ledger
      accountNameLedger[mintingAccountName] = msg.sender;
    }

    // pay any royalties up the square stack
    payRoyalties(stackLevel, x, y, msg.value);

    return squareID;
  }

  //
  // function to set sale data for each stack level
  //
  function setSaleData(
    uint256 stackLevel,
    uint256 price,
    uint256 transferFee,
    uint256 royaltyPercentage,
    bool forSale
  ) public onlyOwner {
    squareStackSaleData[stackLevel].salePrice = price;
    squareStackSaleData[stackLevel].transferFee = transferFee;
    squareStackSaleData[stackLevel].royaltyPercentage = royaltyPercentage;
    squareStackSaleData[stackLevel].forSale = forSale;
  }

  //
  // function to return sale data
  //
  function getSaleData() public view returns (SquareStackSaleData[22] memory) {
    return squareStackSaleData;
  }

  //
  // update the account profile.  only account owner can do this.
  //
  function setAccountProfile(
    string memory accountURI // URI of profile image
  ) public {
    require(
      bytes(accountLedger[msg.sender].accountName).length > 0,
      "no account found"
    );

    accountLedger[msg.sender].accountURI = accountURI;
  }

  //
  // update the square name and external url.  only square owner can do this.
  //
  function setSquareData(
    uint256 squareID, // unique square id
    string memory squareName, // new name for square
    string memory squareExternalURL // new website to point to
  ) public {
    require(
      msg.sender == squareStackLedger[squareID].owner,
      "not owner of square"
    );

    require(
      squareStackLedger[squareID].stackLevel == 21,
      "can not change this stackLevel"
    );

    squareStackLedger[squareID].squareName = squareName;
    squareStackLedger[squareID].squareExternalURL = squareExternalURL;
  }

  //
  // get all squares in the world for specified unique square id's
  //
  function getSquaresWithID(
    uint256[] memory squareIDs // array of square id's to find
  ) public view returns (SquareStackEnriched[] memory) {
    uint256 numSquaresToFind = squareIDs.length;

    SquareStackEnriched[] memory returnSquares;

    returnSquares = new SquareStackEnriched[](numSquaresToFind);

    for (uint256 i = 0; i < numSquaresToFind; i++) {
      returnSquares[i].stackLevel = squareStackLedger[squareIDs[i]].stackLevel;
      returnSquares[i].x = squareStackLedger[squareIDs[i]].x;
      returnSquares[i].y = squareStackLedger[squareIDs[i]].y;
      returnSquares[i].owner = squareStackLedger[squareIDs[i]].owner;
      returnSquares[i].tokenId = squareStackLedger[squareIDs[i]].tokenId;
      returnSquares[i].squareName = squareStackLedger[squareIDs[i]].squareName;
      returnSquares[i].squareExternalURL = squareStackLedger[squareIDs[i]]
        .squareExternalURL;
      returnSquares[i].active = squareStackLedger[squareIDs[i]].active;
      returnSquares[i].accountName = accountLedger[
        squareStackLedger[squareIDs[i]].owner
      ].accountName;
      returnSquares[i].accountURI = accountLedger[
        squareStackLedger[squareIDs[i]].owner
      ].accountURI;
      if (squareStackLedger[squareIDs[i]].owner != address(0)) {
        returnSquares[i].tokenURI = tokenURI(
          squareStackLedger[squareIDs[i]].tokenId
        );
      }
    }

    return returnSquares;
  }

  //
  // gets all squares in the metaverse
  //
  function getAllSquares(
    bool withAccount, // if set true, returns owners account details also
    bool withTokenURI, // if set true, returns NFT token URI also
    bool latestOnly, // if set true, only returns last square sold for each stack level
    uint256 stackLevel, // returns squares just that level.  if > 21 returns all
    address forOwner // if set with non-zero address, only returns squares with that owner
  ) public view returns (SquareStackEnriched[] memory) {
    uint256 totalNumToReturn = 0;

    uint256 fromStackLevel = 0;
    uint256 toStackLevel = 21;

    if (stackLevel <= 21) {
      fromStackLevel = stackLevel;
      toStackLevel = stackLevel;
    }

    if (latestOnly == false) {
      for (uint256 sl = fromStackLevel; sl <= toStackLevel; sl++) {
        uint256 numSquaresFound;

        if (forOwner == address(0)) {
          numSquaresFound = squareStackWorld[sl].length;
        } else {
          for (uint256 c = 0; c < squareStackWorld[sl].length; c++) {
            if (squareStackLedger[squareStackWorld[sl][c]].owner == forOwner) {
              numSquaresFound = numSquaresFound + 1;
            }
          }
        }

        totalNumToReturn = totalNumToReturn + numSquaresFound;
      }
    } else {
      totalNumToReturn = 22;
    }

    SquareStackEnriched[] memory returnSquares;

    if (totalNumToReturn == 0) {
      return returnSquares;
    }

    returnSquares = new SquareStackEnriched[](totalNumToReturn);

    uint256 r = 0;

    for (uint256 sl = fromStackLevel; sl <= toStackLevel; sl++) {
      uint256 numSquaresFound = squareStackWorld[sl].length;

      for (uint256 l = 0; l < numSquaresFound; l++) {
        if (latestOnly == true) {
          l = (squareStackWorld[sl].length).sub(1);
        }

        if (forOwner != address(0)) {
          if (squareStackLedger[squareStackWorld[sl][l]].owner != forOwner) {
            continue;
          }
        }

        returnSquares[r].stackLevel = squareStackLedger[squareStackWorld[sl][l]]
          .stackLevel;
        returnSquares[r].x = squareStackLedger[squareStackWorld[sl][l]].x;
        returnSquares[r].y = squareStackLedger[squareStackWorld[sl][l]].y;
        returnSquares[r].owner = squareStackLedger[squareStackWorld[sl][l]]
          .owner;
        returnSquares[r].tokenId = squareStackLedger[squareStackWorld[sl][l]]
          .tokenId;
        returnSquares[r].squareName = squareStackLedger[squareStackWorld[sl][l]]
          .squareName;
        returnSquares[r].squareExternalURL = squareStackLedger[
          squareStackWorld[sl][l]
        ].squareExternalURL;
        returnSquares[r].active = squareStackLedger[squareStackWorld[sl][l]]
          .active;

        if (withAccount == true) {
          returnSquares[r].accountName = accountLedger[
            squareStackLedger[squareStackWorld[sl][l]].owner
          ].accountName;
          returnSquares[r].accountURI = accountLedger[
            squareStackLedger[squareStackWorld[sl][l]].owner
          ].accountURI;
        }

        if (withTokenURI == true) {
          if (squareStackLedger[squareStackWorld[sl][l]].owner != address(0)) {
            returnSquares[r].tokenURI = tokenURI(
              squareStackLedger[squareStackWorld[sl][l]].tokenId
            );
          }
        }

        r++;
      }
    }

    return returnSquares;
  }

  //
  // function that calculates then pays royalties to all Squares above the given Square in the stack
  //
  function payRoyalties(
    uint256 stackLevel,
    uint256 x,
    uint256 y,
    uint256 salePrice
  ) private {
    // can only pay royalties to Squares above.  There are no Squares above level 0.
    if (stackLevel < 1) return;

    // Parent Square is the Square above current one.  Intialized to current one then moved up one level to parent in loop.
    uint256 parentSquareX = x;
    uint256 parentSquareY = y;
    uint256 parentSquareID;
    uint256 parentStackLevel = stackLevel;

    address squareIDOwner;

    // get the percentage to be used as Royal for the give Square in stack
    uint256 royaltyPercentage = squareStackSaleData[stackLevel]
      .royaltyPercentage;

    do {
      // set parent Square coords and level from existing one.  Parent Square is the one directly above given Square in stack.
      parentStackLevel = parentStackLevel.sub(1);
      parentSquareX = parentSquareX.div(2);
      parentSquareY = parentSquareY.div(2);

      // get the unique id for the parent Square.  squareID is same  as tokenID
      parentSquareID = generateSquareID(
        parentStackLevel,
        parentSquareX,
        parentSquareY
      );

      // only bother checking to pay parent if the parent Square has been minted
      if (_exists(parentSquareID)) {
        // parent Square exists i.e. it has been minted and has an owner that needs paying royalty
        // get the owner of the parent Square
        squareIDOwner = ownerOf(parentSquareID);

        // only pay if there is an owner and it's not you.  no point paying yourself.
        if (squareIDOwner != address(0) && squareIDOwner != msg.sender) {
          //only pay if the square is active.  (if the square has been transfered and the tranfer fee has not yet been paid, then the Square will not be active)
          if (squareStackLedger[parentSquareID].active == true) {
            // calculate the fee based on the royalty percentage of the sale price
            uint256 ownersFee = salePrice.mul(royaltyPercentage).div(100000);
            // pay royalty to the Square owner
            (bool sent, ) = squareIDOwner.call{ value: ownersFee }("");

            if (sent == true) {
              // if the royalty payment was sucessful, keep track of the total payment for the owner.
              accountLedger[squareIDOwner].accountRoyalties = accountLedger[
                squareIDOwner
              ].accountRoyalties.add(ownersFee);
            }
          }
        }
      }

      // keep going up the stack paying royalties until the top is reached
    } while (parentStackLevel > 0);
  }

  //
  // withdraw any Eth in the contract
  //
  function withdraw() public onlyOwner {
    uint256 withdrawBalance = address(this).balance;
    (bool sent, ) = msg.sender.call{ value: withdrawBalance }("");

    require(sent == true, "could not withdraw");

    return;
  }

  //
  // gets number of NFTs owned by calling address
  //
  function getBalance() public view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  //
  // gets the squarestack account profile for given wallet address
  //
  function getAccount(
    address forAddress // wallet address
  ) public view returns (SquareStackAccount memory) {
    return accountLedger[forAddress];
  }

  //
  // gets the squarestack account profile name for given wallet address
  //
  function getAccountName(
    address forAddress // wallet address
  ) public view returns (string memory) {
    return accountLedger[forAddress].accountName;
  }

  //
  // gets wallet address for given profile account name
  //
  function getAccountForName(
    string memory accountName // name of account profile
  ) public view returns (address) {
    return accountNameLedger[accountName];
  }

  //
  // genereates the unique square id for a given square.  use as the tokenID
  //
  function generateSquareID(
    uint256 stackLevel, // stackLevel of square
    uint256 x, // x coord of square
    uint256 y // y coord of square
  ) public pure returns (uint256) {
    if (stackLevel == 0) {
      require(y == 0, "invalid y for world");
      require(x == 0, "invalid x for world");
      return 0;
    }

    require(x < 100000000000000000000, "invalid x");
    require(y < 100000000000000000000, "invalid y");
    require(stackLevel < 100000000000000000000, "invalid stackLevel");

    uint256 xShifted = x.mul(100000000000000000000);
    uint256 stackLevelShifted = stackLevel.mul(
      10000000000000000000000000000000000000000
    );
    uint256 squareID = y.add(xShifted).add(stackLevelShifted);

    return squareID;
  }

  //
  // returns all the squares in the stack above given square
  //
  function getStackForSquare(
    uint256 stackLevel, // stackLevel of square
    uint256 x, // x coord of square
    uint256 y // y coord of square
  ) public view returns (SquareStackEnriched[] memory) {
    uint256 parentSquareX = x;
    uint256 parentSquareY = y;
    uint256 parentSquareID;

    SquareStackEnriched[] memory returnSquares;

    returnSquares = new SquareStackEnriched[](22);

    for (uint256 i = stackLevel; i >= 0; ) {
      if (i != stackLevel) {
        parentSquareX = parentSquareX.div(2);
        parentSquareY = parentSquareY.div(2);
      }

      parentSquareID = generateSquareID(i, parentSquareX, parentSquareY);

      returnSquares[i].stackLevel = i;
      returnSquares[i].x = parentSquareX;
      returnSquares[i].y = parentSquareY;
      returnSquares[i].owner = squareStackLedger[parentSquareID].owner;
      returnSquares[i].tokenId = squareStackLedger[parentSquareID].tokenId;
      returnSquares[i].squareName = squareStackLedger[parentSquareID]
        .squareName;
      returnSquares[i].squareExternalURL = squareStackLedger[parentSquareID]
        .squareExternalURL;
      returnSquares[i].active = squareStackLedger[parentSquareID].active;
      returnSquares[i].accountName = accountLedger[
        squareStackLedger[parentSquareID].owner
      ].accountName;
      returnSquares[i].accountURI = accountLedger[
        squareStackLedger[parentSquareID].owner
      ].accountURI;

      if (squareStackLedger[parentSquareID].owner != address(0)) {
        returnSquares[i].tokenURI = tokenURI(
          squareStackLedger[parentSquareID].tokenId
        );
      }
      if (i != 0) {
        i = i.sub(1);
      } else {
        break;
      }
    }

    return returnSquares;
  }

  //
  // utility function to compare two string values
  //
  function compareStrings(string memory a, string memory b)
    private
    pure
    returns (bool)
  {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      if (keccak256(abi.encodePacked(a)) == (keccak256(abi.encodePacked(b)))) {
        return true;
      } else {
        return false;
      }
    }
  }

  //
  // utility funcion to calculate the power of a number
  //
  function power(uint256 base, uint256 exponent)
    private
    pure
    returns (uint256)
  {
    uint256 result = 0;

    if (exponent == 0) {
      result == 1;
    } else {
      if (exponent == 1) {
        result = base;
      } else {
        result = power(SafeMath.mul(base, base), SafeMath.div(exponent, 2));
        if (SafeMath.mod(exponent, 2) == 1) {
          result = SafeMath.mul(base, result);
        }
      }
    }

    return result;
  }

  //
  // function to ensure a Square's parameters are valid
  //
  function validateSquare(
    uint256 stackLevel,
    uint256 x,
    uint256 y,
    string memory squareName,
    string memory squareExternalURL
  ) private {
    require(
      (stackLevel >= 0 && stackLevel <= 17) || stackLevel == 21,
      "invalid stackLevel"
    );

    require(squareStackSaleData[stackLevel].forSale == true, "not for sale");

    uint256 squareMinSalePrice = squareStackSaleData[stackLevel].salePrice;

    require(msg.value >= squareMinSalePrice, "not enough eth to pay");

    if (stackLevel == 0) {
      require(x == 0 && y == 0, "invalid square for stackLevel0");
    } else {
      uint256 maxSquareXY = power(2, stackLevel);
      require(x < maxSquareXY && y < maxSquareXY, "invalid square");
    }

    if (stackLevel == 21) {
      require(bytes(squareName).length > 0, "needs place name");
    } else {
      require(bytes(squareName).length == 0, "can not have place name");
    }

    if (stackLevel != 21) {
      require(bytes(squareExternalURL).length == 0, "can not have url");
    }
  }
}