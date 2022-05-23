/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/PokerGo.sol



pragma solidity ^0.8.0;

//import '@openzeppelin/contracts/token/ERC721/ERC721.sol';





contract PokerGO is ERC721Enumerable, Ownable
{
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public nextTokenId = 1;

    uint256 public constant MAX_SUPPLY = 1326;

    // Public sale
    uint256 public PRICE = 0.10 ether;
    uint256 public publicsaleStartDate;
    mapping (address => uint256) public minted;
    mapping (address => uint256) public p1minted;
    mapping (address => uint256) public p2minted;
    mapping (address => uint256) public freeminted;
    mapping (address => uint256) private _canFreeMint;


    // Pre-sale
    uint256 public phase1StartDate;
    uint256 public phase2StartDate;
    mapping (address => bool) public isWhitelisted;

    uint256 public revealDate;

    string public baseTokenURI;
    string public baseExtension = ".json";
    string public unrevealedURI;

    address payable public payments;



    constructor(string memory baseURI, uint256 _phase1StartDate, uint256 _phase2StartDate, uint256 _publicsaleStartDate, string memory _unrevealedURI, uint256 _revealDate,address _payments, address[] memory _freeAddress, uint256[] memory _canMinttotal) ERC721("PokerGo NFT", "PGNGT") {
        require(_freeAddress.length == _canMinttotal.length, "Address and number length mismatch");
        require(_freeAddress.length > 0, "No Free Mint Address");

        for (uint256 i = 0; i < _freeAddress.length; i++) {
            _addFreeMint(_freeAddress[i], _canMinttotal[i]);
        }
        setBaseURI(baseURI);
        setUnrevealedURI(_unrevealedURI);
        phase1StartDate = _phase1StartDate;
        phase2StartDate = _phase2StartDate;
        publicsaleStartDate = _publicsaleStartDate;
        revealDate = _revealDate;
        payments = payable(_payments);
    }
    function _addFreeMint(address account, uint256 canminttotal_) private {
        require(account != address(0), "Account is the zero address");
        require(canminttotal_ > 0, "Cannot Free Mint 0 NFT");
        require(_canFreeMint[account] == 0, "Account already has shares");
        _canFreeMint[account] = canminttotal_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (block.timestamp < revealDate) {
            return unrevealedURI;
        }
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (block.timestamp < revealDate) {
            return unrevealedURI;
        }
        
        else {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
        }    
    }

    function mint(uint256 _count) public payable {
        uint256 totalMinted = nextTokenId;
        if (_canFreeMint[msg.sender]>0)
        {
            require(_count > 0, "Cannot mint 0 NFTs");
            freeminted[msg.sender] += _count;
            require(freeminted[msg.sender] <= _canFreeMint[msg.sender], string(abi.encodePacked("Address can't mint more than ", _canFreeMint[msg.sender].toString(), " NFTs in Free mint")));
            for (uint256 i = 0; i < _count; i++) {
                _mintNFT();
            }  
        } else {

            require(block.timestamp > phase1StartDate, "Sale not started yet");
            //require(block.timestamp > phase2StartDate, "Phase 2 Sale not started yet");

            require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left");
            require(_count > 0, "Cannot mint 0 NFTs");
            require(msg.value >= calculatePrice(_count),"Not enough ether to purchase NFTs");
            
            if  (block.timestamp > publicsaleStartDate) {
                minted[msg.sender] += _count;
                require(minted[msg.sender] <= 10, "Address can't mint more than 10 NFTs in Public sale");
            } else if (block.timestamp > phase2StartDate) {
                require(isWhitelisted[msg.sender], "Address is not whitelisted");
                p2minted[msg.sender] += _count;
                require(p2minted[msg.sender] <= 5, "Address can't mint more than 5 NFTs in Phase 2 sale");
            } else if (block.timestamp > phase2StartDate) {
                require(isWhitelisted[msg.sender], "Address is not whitelisted");
                p1minted[msg.sender] += _count;
                require(p1minted[msg.sender] <= 2, "Address can't mint more than 2 NFTs in Phase 1 sale");
            } 
        }
        for (uint256 i = 0; i < _count; i++) {
            _mintNFT();
        }
    }

    function calculatePrice(uint256 _count) public view returns(uint256) {
        return _count * PRICE;
    }

    function _mintNFT() private {
        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId, '');
        nextTokenId = tokenId + 1;
    }

    // Owner functions

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = payable(payments).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setPhase2StartDate(uint256 _endDate) external onlyOwner {
        phase2StartDate = _endDate;
    }

    function setPhase1StartDate(uint256 _startDate) external onlyOwner {
        phase1StartDate = _startDate;
    }

    function setPublicSaleStartDate(uint256 _publicsaleStartDate) external onlyOwner {
        publicsaleStartDate = _publicsaleStartDate;
    }

    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0;i < _addresses.length;i++) {
            isWhitelisted[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist (address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0;i < _addresses.length;i++) {
            isWhitelisted[_addresses[i]] = false;
        }
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function setRevealDate(uint256 _revealDate) public onlyOwner {
        revealDate = _revealDate;
    }
}

/*
0x6080604052600160075567016345785d8a00006008556040518060400160405280600581526020017f2e6a736f6e000000000000000000000000000000000000000000000000000000815250601490805190602001906200006292919062000674565b503480156200007057600080fd5b5060405162005e1838038062005e1883398181016040528101906200009691906200092c565b6040518060400160405280600b81526020017f506f6b6572476f204e46540000000000000000000000000000000000000000008152506040518060400160405280600581526020017f50474e475400000000000000000000000000000000000000000000000000000081525081600090805190602001906200011a92919062000674565b5080600190805190602001906200013392919062000674565b505050620001566200014a620002a060201b60201c565b620002a860201b60201c565b80518251146200019d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620001949062000c05565b60405180910390fd5b6000825111620001e4576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620001db9062000b9f565b60405180910390fd5b60005b825181101562000253576200023d8382815181106200020b576200020a62000e81565b5b602002602001015183838151811062000229576200022862000e81565b5b60200260200101516200036e60201b60201c565b80806200024a9062000dd5565b915050620001e7565b506200026588620004f460201b60201c565b62000276846200059f60201b60201c565b86600f81905550856010819055508460098190555082601281905550505050505050505062001059565b600033905090565b6000600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905081600660006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415620003e1576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620003d89062000be3565b60405180910390fd5b6000811162000427576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016200041e9062000b7d565b60405180910390fd5b6000600e60008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205414620004ac576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620004a39062000b5b565b60405180910390fd5b80600e60008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055505050565b62000504620002a060201b60201c565b73ffffffffffffffffffffffffffffffffffffffff166200052a6200064a60201b60201c565b73ffffffffffffffffffffffffffffffffffffffff161462000583576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016200057a9062000bc1565b60405180910390fd5b80601390805190602001906200059b92919062000674565b5050565b620005af620002a060201b60201c565b73ffffffffffffffffffffffffffffffffffffffff16620005d56200064a60201b60201c565b73ffffffffffffffffffffffffffffffffffffffff16146200062e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401620006259062000bc1565b60405180910390fd5b80601590805190602001906200064692919062000674565b5050565b6000600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b828054620006829062000d69565b90600052602060002090601f016020900481019282620006a65760008555620006f2565b82601f10620006c157805160ff1916838001178555620006f2565b82800160010185558215620006f2579182015b82811115620006f1578251825591602001919060010190620006d4565b5b50905062000701919062000705565b5090565b5b808211156200072057600081600090555060010162000706565b5090565b60006200073b620007358462000c50565b62000c27565b9050808382526020820190508285602086028201111562000761576200076062000ee4565b5b60005b858110156200079557816200077a888262000865565b84526020840193506020830192505060018101905062000764565b5050509392505050565b6000620007b6620007b08462000c7f565b62000c27565b90508083825260208201905082856020860282011115620007dc57620007db62000ee4565b5b60005b85811015620008105781620007f5888262000915565b845260208401935060208301925050600181019050620007df565b5050509392505050565b6000620008316200082b8462000cae565b62000c27565b90508281526020810184848401111562000850576200084f62000ee9565b5b6200085d84828562000d33565b509392505050565b600081519050620008768162001025565b92915050565b600082601f83011262000894576200089362000edf565b5b8151620008a684826020860162000724565b91505092915050565b600082601f830112620008c757620008c662000edf565b5b8151620008d98482602086016200079f565b91505092915050565b600082601f830112620008fa57620008f962000edf565b5b81516200090c8482602086016200081a565b91505092915050565b60008151905062000926816200103f565b92915050565b600080600080600080600080610100898b03121562000950576200094f62000ef3565b5b600089015167ffffffffffffffff81111562000971576200097062000eee565b5b6200097f8b828c01620008e2565b9850506020620009928b828c0162000915565b9750506040620009a58b828c0162000915565b9650506060620009b88b828c0162000915565b955050608089015167ffffffffffffffff811115620009dc57620009db62000eee565b5b620009ea8b828c01620008e2565b94505060a0620009fd8b828c0162000915565b93505060c089015167ffffffffffffffff81111562000a215762000a2062000eee565b5b62000a2f8b828c016200087c565b92505060e089015167ffffffffffffffff81111562000a535762000a5262000eee565b5b62000a618b828c01620008af565b9150509295985092959890939650565b600062000a80601a8362000ce4565b915062000a8d8262000f09565b602082019050919050565b600062000aa760168362000ce4565b915062000ab48262000f32565b602082019050919050565b600062000ace60148362000ce4565b915062000adb8262000f5b565b602082019050919050565b600062000af560208362000ce4565b915062000b028262000f84565b602082019050919050565b600062000b1c601b8362000ce4565b915062000b298262000fad565b602082019050919050565b600062000b4360228362000ce4565b915062000b508262000fd6565b604082019050919050565b6000602082019050818103600083015262000b768162000a71565b9050919050565b6000602082019050818103600083015262000b988162000a98565b9050919050565b6000602082019050818103600083015262000bba8162000abf565b9050919050565b6000602082019050818103600083015262000bdc8162000ae6565b9050919050565b6000602082019050818103600083015262000bfe8162000b0d565b9050919050565b6000602082019050818103600083015262000c208162000b34565b9050919050565b600062000c3362000c46565b905062000c41828262000d9f565b919050565b6000604051905090565b600067ffffffffffffffff82111562000c6e5762000c6d62000eb0565b5b602082029050602081019050919050565b600067ffffffffffffffff82111562000c9d5762000c9c62000eb0565b5b602082029050602081019050919050565b600067ffffffffffffffff82111562000ccc5762000ccb62000eb0565b5b62000cd78262000ef8565b9050602081019050919050565b600082825260208201905092915050565b600062000d028262000d09565b9050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b60005b8381101562000d5357808201518184015260208101905062000d36565b8381111562000d63576000848401525b50505050565b6000600282049050600182168062000d8257607f821691505b6020821081141562000d995762000d9862000e52565b5b50919050565b62000daa8262000ef8565b810181811067ffffffffffffffff8211171562000dcc5762000dcb62000eb0565b5b80604052505050565b600062000de28262000d29565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82141562000e185762000e1762000e23565b5b600182019050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b600080fd5b600080fd5b600080fd5b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4163636f756e7420616c72656164792068617320736861726573000000000000600082015250565b7f43616e6e6f742046726565204d696e742030204e465400000000000000000000600082015250565b7f4e6f2046726565204d696e742041646472657373000000000000000000000000600082015250565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b7f4163636f756e7420697320746865207a65726f20616464726573730000000000600082015250565b7f4164647265737320616e64206e756d626572206c656e677468206d69736d617460008201527f6368000000000000000000000000000000000000000000000000000000000000602082015250565b620010308162000cf5565b81146200103c57600080fd5b50565b6200104a8162000d29565b81146200105657600080fd5b50565b614daf80620010696000396000f3fe6080604052600436106102515760003560e01c806375794a3c11610139578063b88d4fde116100b6578063d81d8ef01161007a578063d81d8ef0146108a8578063e985e9c5146108e5578063eb6426a914610922578063ef56267e1461094d578063f2fde38b1461098a578063fe2c7fee146109b357610251565b8063b88d4fde146107c1578063c504685e146107ea578063c668286214610815578063c87b56dd14610840578063d547cfb71461087d57610251565b8063918b933f116100fd578063918b933f146106d757806395d89b4114610714578063a0712d681461073f578063a22cb4651461075b578063ae1042651461078457610251565b806375794a3c146106045780637f6497831461062f5780638044741f146106585780638d859f3e146106815780638da5cb5b146106ac57610251565b80633af32abf116101d2578063548db17411610196578063548db174146104f657806355f804b31461051f5780636352211e146105485780637035bf181461058557806370a08231146105b0578063715018a6146105ed57610251565b80633af32abf146104325780633c66485e1461046f5780633ccfd60b1461049a578063405200cd146104a457806342842e0e146104cd57610251565b80631e08a9e4116102195780631e08a9e41461034d5780631e7269c51461037857806323b872dd146103b557806332cb6b0c146103de5780633775ddcc1461040957610251565b806301ffc9a71461025657806306fdde0314610293578063081812fc146102be578063095ea7b3146102fb5780630c88b73114610324575b600080fd5b34801561026257600080fd5b5061027d600480360381019061027891906136e3565b6109dc565b60405161028a9190613dd3565b60405180910390f35b34801561029f57600080fd5b506102a8610abe565b6040516102b59190613dee565b60405180910390f35b3480156102ca57600080fd5b506102e560048036038101906102e09190613786565b610b50565b6040516102f29190613d6c565b60405180910390f35b34801561030757600080fd5b50610322600480360381019061031d919061365a565b610bd5565b005b34801561033057600080fd5b5061034b60048036038101906103469190613786565b610ced565b005b34801561035957600080fd5b50610362610d73565b60405161036f9190614150565b60405180910390f35b34801561038457600080fd5b5061039f600480360381019061039a91906134d7565b610d79565b6040516103ac9190614150565b60405180910390f35b3480156103c157600080fd5b506103dc60048036038101906103d79190613544565b610d91565b005b3480156103ea57600080fd5b506103f3610df1565b6040516104009190614150565b60405180910390f35b34801561041557600080fd5b50610430600480360381019061042b9190613786565b610df7565b005b34801561043e57600080fd5b50610459600480360381019061045491906134d7565b610e7d565b6040516104669190613dd3565b60405180910390f35b34801561047b57600080fd5b50610484610e9d565b6040516104919190614150565b60405180910390f35b6104a2610ea3565b005b3480156104b057600080fd5b506104cb60048036038101906104c69190613786565b611017565b005b3480156104d957600080fd5b506104f460048036038101906104ef9190613544565b61109d565b005b34801561050257600080fd5b5061051d6004803603810190610518919061369a565b6110bd565b005b34801561052b57600080fd5b506105466004803603810190610541919061373d565b6111ce565b005b34801561055457600080fd5b5061056f600480360381019061056a9190613786565b611264565b60405161057c9190613d6c565b60405180910390f35b34801561059157600080fd5b5061059a611316565b6040516105a79190613dee565b60405180910390f35b3480156105bc57600080fd5b506105d760048036038101906105d291906134d7565b6113a4565b6040516105e49190614150565b60405180910390f35b3480156105f957600080fd5b5061060261145c565b005b34801561061057600080fd5b506106196114e4565b6040516106269190614150565b60405180910390f35b34801561063b57600080fd5b506106566004803603810190610651919061369a565b6114ea565b005b34801561066457600080fd5b5061067f600480360381019061067a9190613786565b6115fb565b005b34801561068d57600080fd5b50610696611681565b6040516106a39190614150565b60405180910390f35b3480156106b857600080fd5b506106c1611687565b6040516106ce9190613d6c565b60405180910390f35b3480156106e357600080fd5b506106fe60048036038101906106f991906134d7565b6116b1565b60405161070b9190614150565b60405180910390f35b34801561072057600080fd5b506107296116c9565b6040516107369190613dee565b60405180910390f35b61075960048036038101906107549190613786565b61175b565b005b34801561076757600080fd5b50610782600480360381019061077d919061361a565b611ebc565b005b34801561079057600080fd5b506107ab60048036038101906107a69190613786565b611ed2565b6040516107b89190614150565b60405180910390f35b3480156107cd57600080fd5b506107e860048036038101906107e39190613597565b611ee9565b005b3480156107f657600080fd5b506107ff611f4b565b60405161080c9190614150565b60405180910390f35b34801561082157600080fd5b5061082a611f51565b6040516108379190613dee565b60405180910390f35b34801561084c57600080fd5b5061086760048036038101906108629190613786565b611fdf565b6040516108749190613dee565b60405180910390f35b34801561088957600080fd5b50610892612126565b60405161089f9190613dee565b60405180910390f35b3480156108b457600080fd5b506108cf60048036038101906108ca91906134d7565b6121b4565b6040516108dc9190614150565b60405180910390f35b3480156108f157600080fd5b5061090c60048036038101906109079190613504565b6121cc565b6040516109199190613dd3565b60405180910390f35b34801561092e57600080fd5b50610937612260565b6040516109449190614150565b60405180910390f35b34801561095957600080fd5b50610974600480360381019061096f91906134d7565b612266565b6040516109819190614150565b60405180910390f35b34801561099657600080fd5b506109b160048036038101906109ac91906134d7565b61227e565b005b3480156109bf57600080fd5b506109da60048036038101906109d5919061373d565b612376565b005b60007f80ac58cd000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19161480610aa757507f5b5e139f000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b80610ab75750610ab68261240c565b5b9050919050565b606060008054610acd9061444c565b80601f0160208091040260200160405190810160405280929190818152602001828054610af99061444c565b8015610b465780601f10610b1b57610100808354040283529160200191610b46565b820191906000526020600020905b815481529060010190602001808311610b2957829003601f168201915b5050505050905090565b6000610b5b82612476565b610b9a576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b9190614050565b60405180910390fd5b6004600083815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050919050565b6000610be082611264565b90508073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610c51576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610c48906140b0565b60405180910390fd5b8073ffffffffffffffffffffffffffffffffffffffff16610c706124e2565b73ffffffffffffffffffffffffffffffffffffffff161480610c9f5750610c9e81610c996124e2565b6121cc565b5b610cde576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610cd590613fb0565b60405180910390fd5b610ce883836124ea565b505050565b610cf56124e2565b73ffffffffffffffffffffffffffffffffffffffff16610d13611687565b73ffffffffffffffffffffffffffffffffffffffff1614610d69576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d6090614070565b60405180910390fd5b8060128190555050565b60125481565b600a6020528060005260406000206000915090505481565b610da2610d9c6124e2565b826125a3565b610de1576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610dd890614110565b60405180910390fd5b610dec838383612681565b505050565b61052e81565b610dff6124e2565b73ffffffffffffffffffffffffffffffffffffffff16610e1d611687565b73ffffffffffffffffffffffffffffffffffffffff1614610e73576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610e6a90614070565b60405180910390fd5b80600f8190555050565b60116020528060005260406000206000915054906101000a900460ff1681565b60105481565b610eab6124e2565b73ffffffffffffffffffffffffffffffffffffffff16610ec9611687565b73ffffffffffffffffffffffffffffffffffffffff1614610f1f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610f1690614070565b60405180910390fd5b600047905060008111610f67576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610f5e90614030565b60405180910390fd5b60003373ffffffffffffffffffffffffffffffffffffffff1682604051610f8d90613d57565b60006040518083038185875af1925050503d8060008114610fca576040519150601f19603f3d011682016040523d82523d6000602084013e610fcf565b606091505b5050905080611013576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161100a906140f0565b60405180910390fd5b5050565b61101f6124e2565b73ffffffffffffffffffffffffffffffffffffffff1661103d611687565b73ffffffffffffffffffffffffffffffffffffffff1614611093576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161108a90614070565b60405180910390fd5b8060098190555050565b6110b883838360405180602001604052806000815250611ee9565b505050565b6110c56124e2565b73ffffffffffffffffffffffffffffffffffffffff166110e3611687565b73ffffffffffffffffffffffffffffffffffffffff1614611139576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161113090614070565b60405180910390fd5b60005b81518110156111ca5760006011600084848151811061115e5761115d6145b6565b5b602002602001015173ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555080806111c2906144af565b91505061113c565b5050565b6111d66124e2565b73ffffffffffffffffffffffffffffffffffffffff166111f4611687565b73ffffffffffffffffffffffffffffffffffffffff161461124a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161124190614070565b60405180910390fd5b806013908051906020019061126092919061324d565b5050565b6000806002600084815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16141561130d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161130490613ff0565b60405180910390fd5b80915050919050565b601580546113239061444c565b80601f016020809104026020016040519081016040528092919081815260200182805461134f9061444c565b801561139c5780601f106113715761010080835404028352916020019161139c565b820191906000526020600020905b81548152906001019060200180831161137f57829003601f168201915b505050505081565b60008073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415611415576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161140c90613fd0565b60405180910390fd5b600360008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b6114646124e2565b73ffffffffffffffffffffffffffffffffffffffff16611482611687565b73ffffffffffffffffffffffffffffffffffffffff16146114d8576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016114cf90614070565b60405180910390fd5b6114e260006128e8565b565b60075481565b6114f26124e2565b73ffffffffffffffffffffffffffffffffffffffff16611510611687565b73ffffffffffffffffffffffffffffffffffffffff1614611566576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161155d90614070565b60405180910390fd5b60005b81518110156115f75760016011600084848151811061158b5761158a6145b6565b5b602002602001015173ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555080806115ef906144af565b915050611569565b5050565b6116036124e2565b73ffffffffffffffffffffffffffffffffffffffff16611621611687565b73ffffffffffffffffffffffffffffffffffffffff1614611677576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161166e90614070565b60405180910390fd5b8060108190555050565b60085481565b6000600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b600b6020528060005260406000206000915090505481565b6060600180546116d89061444c565b80601f01602080910402602001604051908101604052809291908181526020018280546117049061444c565b80156117515780601f1061172657610100808354040283529160200191611751565b820191906000526020600020905b81548152906001019060200180831161173457829003601f168201915b5050505050905090565b600060075490506000600e60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054111561199a57600082116117ed576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016117e490613f90565b60405180910390fd5b81600d60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825461183c9190614281565b92505081905550600e60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054600d60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054111561190d600e60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020546129ae565b60405160200161191d9190613d2a565b6040516020818303038152906040529061196d576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016119649190613dee565b60405180910390fd5b5060005b8281101561199457611981612b0f565b808061198c906144af565b915050611971565b50611e91565b600f5442116119de576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016119d590613e10565b60405180910390fd5b61052e6119f48383612b4690919063ffffffff16565b1115611a35576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611a2c906140d0565b60405180910390fd5b60008211611a78576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611a6f90613f90565b60405180910390fd5b611a8182611ed2565b341015611ac3576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611aba90613e30565b60405180910390fd5b600954421115611baa5781600a60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254611b1c9190614281565b92505081905550600a8060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541115611ba5576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611b9c90614130565b60405180910390fd5b611e90565b601054421115611d1e57601160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16611c40576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611c3790613f30565b60405180910390fd5b81600c60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254611c8f9190614281565b925050819055506005600c60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541115611d19576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611d1090613f70565b60405180910390fd5b611e8f565b601054421115611e8e57601160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16611db4576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611dab90613f30565b60405180910390fd5b81600b60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254611e039190614281565b925050819055506002600b60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541115611e8d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611e8490613ed0565b60405180910390fd5b5b5b5b5b60005b82811015611eb757611ea4612b0f565b8080611eaf906144af565b915050611e94565b505050565b611ece611ec76124e2565b8383612b5c565b5050565b600060085482611ee29190614308565b9050919050565b611efa611ef46124e2565b836125a3565b611f39576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611f3090614110565b60405180910390fd5b611f4584848484612cc9565b50505050565b600f5481565b60148054611f5e9061444c565b80601f0160208091040260200160405190810160405280929190818152602001828054611f8a9061444c565b8015611fd75780601f10611fac57610100808354040283529160200191611fd7565b820191906000526020600020905b815481529060010190602001808311611fba57829003601f168201915b505050505081565b6060611fea82612476565b612029576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161202090614090565b60405180910390fd5b6012544210156120c557601580546120409061444c565b80601f016020809104026020016040519081016040528092919081815260200182805461206c9061444c565b80156120b95780601f1061208e576101008083540402835291602001916120b9565b820191906000526020600020905b81548152906001019060200180831161209c57829003601f168201915b50505050509050612121565b60006120cf612d25565b905060008151116120ef576040518060200160405280600081525061211d565b806120f9846129ae565b601460405160200161210d93929190613cf9565b6040516020818303038152906040525b9150505b919050565b601380546121339061444c565b80601f016020809104026020016040519081016040528092919081815260200182805461215f9061444c565b80156121ac5780601f10612181576101008083540402835291602001916121ac565b820191906000526020600020905b81548152906001019060200180831161218f57829003601f168201915b505050505081565b600c6020528060005260406000206000915090505481565b6000600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16905092915050565b60095481565b600d6020528060005260406000206000915090505481565b6122866124e2565b73ffffffffffffffffffffffffffffffffffffffff166122a4611687565b73ffffffffffffffffffffffffffffffffffffffff16146122fa576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016122f190614070565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16141561236a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161236190613e70565b60405180910390fd5b612373816128e8565b50565b61237e6124e2565b73ffffffffffffffffffffffffffffffffffffffff1661239c611687565b73ffffffffffffffffffffffffffffffffffffffff16146123f2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016123e990614070565b60405180910390fd5b806015908051906020019061240892919061324d565b5050565b60007f01ffc9a7000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916149050919050565b60008073ffffffffffffffffffffffffffffffffffffffff166002600084815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1614159050919050565b600033905090565b816004600083815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550808273ffffffffffffffffffffffffffffffffffffffff1661255d83611264565b73ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92560405160405180910390a45050565b60006125ae82612476565b6125ed576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016125e490613f50565b60405180910390fd5b60006125f883611264565b90508073ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff16148061263a575061263981856121cc565b5b8061267857508373ffffffffffffffffffffffffffffffffffffffff1661266084610b50565b73ffffffffffffffffffffffffffffffffffffffff16145b91505092915050565b8273ffffffffffffffffffffffffffffffffffffffff166126a182611264565b73ffffffffffffffffffffffffffffffffffffffff16146126f7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016126ee90613e90565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415612767576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161275e90613ef0565b60405180910390fd5b612772838383612e54565b61277d6000826124ea565b6001600360008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546127cd9190614362565b925050819055506001600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546128249190614281565b92505081905550816002600083815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550808273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60405160405180910390a46128e3838383612e59565b505050565b6000600660009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905081600660006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b606060008214156129f6576040518060400160405280600181526020017f30000000000000000000000000000000000000000000000000000000000000008152509050612b0a565b600082905060005b60008214612a28578080612a11906144af565b915050600a82612a2191906142d7565b91506129fe565b60008167ffffffffffffffff811115612a4457612a436145e5565b5b6040519080825280601f01601f191660200182016040528015612a765781602001600182028036833780820191505090505b5090505b60008514612b0357600182612a8f9190614362565b9150600a85612a9e91906144f8565b6030612aaa9190614281565b60f81b818381518110612ac057612abf6145b6565b5b60200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a905350600a85612afc91906142d7565b9450612a7a565b8093505050505b919050565b60006007549050612b30338260405180602001604052806000815250612e5e565b600181612b3d9190614281565b60078190555050565b60008183612b549190614281565b905092915050565b8173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415612bcb576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401612bc290613f10565b60405180910390fd5b80600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c3183604051612cbc9190613dd3565b60405180910390a3505050565b612cd4848484612681565b612ce084848484612eb9565b612d1f576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401612d1690613e50565b60405180910390fd5b50505050565b6060601254421015612dc35760158054612d3e9061444c565b80601f0160208091040260200160405190810160405280929190818152602001828054612d6a9061444c565b8015612db75780601f10612d8c57610100808354040283529160200191612db7565b820191906000526020600020905b815481529060010190602001808311612d9a57829003601f168201915b50505050509050612e51565b60138054612dd09061444c565b80601f0160208091040260200160405190810160405280929190818152602001828054612dfc9061444c565b8015612e495780601f10612e1e57610100808354040283529160200191612e49565b820191906000526020600020905b815481529060010190602001808311612e2c57829003601f168201915b505050505090505b90565b505050565b505050565b612e688383613050565b612e756000848484612eb9565b612eb4576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401612eab90613e50565b60405180910390fd5b505050565b6000612eda8473ffffffffffffffffffffffffffffffffffffffff1661322a565b15613043578373ffffffffffffffffffffffffffffffffffffffff1663150b7a02612f036124e2565b8786866040518563ffffffff1660e01b8152600401612f259493929190613d87565b602060405180830381600087803b158015612f3f57600080fd5b505af1925050508015612f7057506040513d601f19601f82011682018060405250810190612f6d9190613710565b60015b612ff3573d8060008114612fa0576040519150601f19603f3d011682016040523d82523d6000602084013e612fa5565b606091505b50600081511415612feb576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401612fe290613e50565b60405180910390fd5b805181602001fd5b63150b7a0260e01b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916817bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614915050613048565b600190505b949350505050565b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1614156130c0576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016130b790614010565b60405180910390fd5b6130c981612476565b15613109576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161310090613eb0565b60405180910390fd5b61311560008383612e54565b6001600360008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546131659190614281565b92505081905550816002600083815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550808273ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60405160405180910390a461322660008383612e59565b5050565b6000808273ffffffffffffffffffffffffffffffffffffffff163b119050919050565b8280546132599061444c565b90600052602060002090601f01602090048101928261327b57600085556132c2565b82601f1061329457805160ff19168380011785556132c2565b828001600101855582156132c2579182015b828111156132c15782518255916020019190600101906132a6565b5b5090506132cf91906132d3565b5090565b5b808211156132ec5760008160009055506001016132d4565b5090565b60006133036132fe84614190565b61416b565b9050808382526020820190508285602086028201111561332657613325614619565b5b60005b85811015613356578161333c88826133e4565b845260208401935060208301925050600181019050613329565b5050509392505050565b600061337361336e846141bc565b61416b565b90508281526020810184848401111561338f5761338e61461e565b5b61339a84828561440a565b509392505050565b60006133b56133b0846141ed565b61416b565b9050828152602081018484840111156133d1576133d061461e565b5b6133dc84828561440a565b509392505050565b6000813590506133f381614d1d565b92915050565b600082601f83011261340e5761340d614614565b5b813561341e8482602086016132f0565b91505092915050565b60008135905061343681614d34565b92915050565b60008135905061344b81614d4b565b92915050565b60008151905061346081614d4b565b92915050565b600082601f83011261347b5761347a614614565b5b813561348b848260208601613360565b91505092915050565b600082601f8301126134a9576134a8614614565b5b81356134b98482602086016133a2565b91505092915050565b6000813590506134d181614d62565b92915050565b6000602082840312156134ed576134ec614628565b5b60006134fb848285016133e4565b91505092915050565b6000806040838503121561351b5761351a614628565b5b6000613529858286016133e4565b925050602061353a858286016133e4565b9150509250929050565b60008060006060848603121561355d5761355c614628565b5b600061356b868287016133e4565b935050602061357c868287016133e4565b925050604061358d868287016134c2565b9150509250925092565b600080600080608085870312156135b1576135b0614628565b5b60006135bf878288016133e4565b94505060206135d0878288016133e4565b93505060406135e1878288016134c2565b925050606085013567ffffffffffffffff81111561360257613601614623565b5b61360e87828801613466565b91505092959194509250565b6000806040838503121561363157613630614628565b5b600061363f858286016133e4565b925050602061365085828601613427565b9150509250929050565b6000806040838503121561367157613670614628565b5b600061367f858286016133e4565b9250506020613690858286016134c2565b9150509250929050565b6000602082840312156136b0576136af614628565b5b600082013567ffffffffffffffff8111156136ce576136cd614623565b5b6136da848285016133f9565b91505092915050565b6000602082840312156136f9576136f8614628565b5b60006137078482850161343c565b91505092915050565b60006020828403121561372657613725614628565b5b600061373484828501613451565b91505092915050565b60006020828403121561375357613752614628565b5b600082013567ffffffffffffffff81111561377157613770614623565b5b61377d84828501613494565b91505092915050565b60006020828403121561379c5761379b614628565b5b60006137aa848285016134c2565b91505092915050565b6137bc81614396565b82525050565b6137cb816143a8565b82525050565b60006137dc82614233565b6137e68185614249565b93506137f6818560208601614419565b6137ff8161462d565b840191505092915050565b60006138158261423e565b61381f8185614265565b935061382f818560208601614419565b6138388161462d565b840191505092915050565b600061384e8261423e565b6138588185614276565b9350613868818560208601614419565b80840191505092915050565b600081546138818161444c565b61388b8186614276565b945060018216600081146138a657600181146138b7576138ea565b60ff198316865281860193506138ea565b6138c08561421e565b60005b838110156138e2578154818901526001820191506020810190506138c3565b838801955050505b50505092915050565b6000613900601483614265565b915061390b8261463e565b602082019050919050565b6000613923602183614265565b915061392e82614667565b604082019050919050565b6000613946603283614265565b9150613951826146b6565b604082019050919050565b6000613969602683614265565b915061397482614705565b604082019050919050565b600061398c602583614265565b915061399782614754565b604082019050919050565b60006139af601c83614265565b91506139ba826147a3565b602082019050919050565b60006139d2601d83614276565b91506139dd826147cc565b601d82019050919050565b60006139f5603383614265565b9150613a00826147f5565b604082019050919050565b6000613a18602483614265565b9150613a2382614844565b604082019050919050565b6000613a3b601983614265565b9150613a4682614893565b602082019050919050565b6000613a5e601a83614265565b9150613a69826148bc565b602082019050919050565b6000613a81602c83614265565b9150613a8c826148e5565b604082019050919050565b6000613aa4603383614265565b9150613aaf82614934565b604082019050919050565b6000613ac7601283614265565b9150613ad282614983565b602082019050919050565b6000613aea603883614265565b9150613af5826149ac565b604082019050919050565b6000613b0d602a83614265565b9150613b18826149fb565b604082019050919050565b6000613b30602983614265565b9150613b3b82614a4a565b604082019050919050565b6000613b53601283614276565b9150613b5e82614a99565b601282019050919050565b6000613b76602083614265565b9150613b8182614ac2565b602082019050919050565b6000613b99601983614265565b9150613ba482614aeb565b602082019050919050565b6000613bbc602c83614265565b9150613bc782614b14565b604082019050919050565b6000613bdf602083614265565b9150613bea82614b63565b602082019050919050565b6000613c02602f83614265565b9150613c0d82614b8c565b604082019050919050565b6000613c25602183614265565b9150613c3082614bdb565b604082019050919050565b6000613c48601483614265565b9150613c5382614c2a565b602082019050919050565b6000613c6b60008361425a565b9150613c7682614c53565b600082019050919050565b6000613c8e601083614265565b9150613c9982614c56565b602082019050919050565b6000613cb1603183614265565b9150613cbc82614c7f565b604082019050919050565b6000613cd4603383614265565b9150613cdf82614cce565b604082019050919050565b613cf381614400565b82525050565b6000613d058286613843565b9150613d118285613843565b9150613d1d8284613874565b9150819050949350505050565b6000613d35826139c5565b9150613d418284613843565b9150613d4c82613b46565b915081905092915050565b6000613d6282613c5e565b9150819050919050565b6000602082019050613d8160008301846137b3565b92915050565b6000608082019050613d9c60008301876137b3565b613da960208301866137b3565b613db66040830185613cea565b8181036060830152613dc881846137d1565b905095945050505050565b6000602082019050613de860008301846137c2565b92915050565b60006020820190508181036000830152613e08818461380a565b905092915050565b60006020820190508181036000830152613e29816138f3565b9050919050565b60006020820190508181036000830152613e4981613916565b9050919050565b60006020820190508181036000830152613e6981613939565b9050919050565b60006020820190508181036000830152613e898161395c565b9050919050565b60006020820190508181036000830152613ea98161397f565b9050919050565b60006020820190508181036000830152613ec9816139a2565b9050919050565b60006020820190508181036000830152613ee9816139e8565b9050919050565b60006020820190508181036000830152613f0981613a0b565b9050919050565b60006020820190508181036000830152613f2981613a2e565b9050919050565b60006020820190508181036000830152613f4981613a51565b9050919050565b60006020820190508181036000830152613f6981613a74565b9050919050565b60006020820190508181036000830152613f8981613a97565b9050919050565b60006020820190508181036000830152613fa981613aba565b9050919050565b60006020820190508181036000830152613fc981613add565b9050919050565b60006020820190508181036000830152613fe981613b00565b9050919050565b6000602082019050818103600083015261400981613b23565b9050919050565b6000602082019050818103600083015261402981613b69565b9050919050565b6000602082019050818103600083015261404981613b8c565b9050919050565b6000602082019050818103600083015261406981613baf565b9050919050565b6000602082019050818103600083015261408981613bd2565b9050919050565b600060208201905081810360008301526140a981613bf5565b9050919050565b600060208201905081810360008301526140c981613c18565b9050919050565b600060208201905081810360008301526140e981613c3b565b9050919050565b6000602082019050818103600083015261410981613c81565b9050919050565b6000602082019050818103600083015261412981613ca4565b9050919050565b6000602082019050818103600083015261414981613cc7565b9050919050565b60006020820190506141656000830184613cea565b92915050565b6000614175614186565b9050614181828261447e565b919050565b6000604051905090565b600067ffffffffffffffff8211156141ab576141aa6145e5565b5b602082029050602081019050919050565b600067ffffffffffffffff8211156141d7576141d66145e5565b5b6141e08261462d565b9050602081019050919050565b600067ffffffffffffffff821115614208576142076145e5565b5b6142118261462d565b9050602081019050919050565b60008190508160005260206000209050919050565b600081519050919050565b600081519050919050565b600082825260208201905092915050565b600081905092915050565b600082825260208201905092915050565b600081905092915050565b600061428c82614400565b915061429783614400565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff038211156142cc576142cb614529565b5b828201905092915050565b60006142e282614400565b91506142ed83614400565b9250826142fd576142fc614558565b5b828204905092915050565b600061431382614400565b915061431e83614400565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561435757614356614529565b5b828202905092915050565b600061436d82614400565b915061437883614400565b92508282101561438b5761438a614529565b5b828203905092915050565b60006143a1826143e0565b9050919050565b60008115159050919050565b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b82818337600083830152505050565b60005b8381101561443757808201518184015260208101905061441c565b83811115614446576000848401525b50505050565b6000600282049050600182168061446457607f821691505b6020821081141561447857614477614587565b5b50919050565b6144878261462d565b810181811067ffffffffffffffff821117156144a6576144a56145e5565b5b80604052505050565b60006144ba82614400565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8214156144ed576144ec614529565b5b600182019050919050565b600061450382614400565b915061450e83614400565b92508261451e5761451d614558565b5b828206905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b600080fd5b600080fd5b600080fd5b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f53616c65206e6f74207374617274656420796574000000000000000000000000600082015250565b7f4e6f7420656e6f75676820657468657220746f207075726368617365204e465460008201527f7300000000000000000000000000000000000000000000000000000000000000602082015250565b7f4552433732313a207472616e7366657220746f206e6f6e20455243373231526560008201527f63656976657220696d706c656d656e7465720000000000000000000000000000602082015250565b7f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160008201527f6464726573730000000000000000000000000000000000000000000000000000602082015250565b7f4552433732313a207472616e736665722066726f6d20696e636f72726563742060008201527f6f776e6572000000000000000000000000000000000000000000000000000000602082015250565b7f4552433732313a20746f6b656e20616c7265616479206d696e74656400000000600082015250565b7f416464726573732063616e2774206d696e74206d6f7265207468616e20000000600082015250565b7f416464726573732063616e2774206d696e74206d6f7265207468616e2032204e60008201527f46547320696e20506861736520312073616c6500000000000000000000000000602082015250565b7f4552433732313a207472616e7366657220746f20746865207a65726f2061646460008201527f7265737300000000000000000000000000000000000000000000000000000000602082015250565b7f4552433732313a20617070726f766520746f2063616c6c657200000000000000600082015250565b7f41646472657373206973206e6f742077686974656c6973746564000000000000600082015250565b7f4552433732313a206f70657261746f7220717565727920666f72206e6f6e657860008201527f697374656e7420746f6b656e0000000000000000000000000000000000000000602082015250565b7f416464726573732063616e2774206d696e74206d6f7265207468616e2035204e60008201527f46547320696e20506861736520322073616c6500000000000000000000000000602082015250565b7f43616e6e6f74206d696e742030204e4654730000000000000000000000000000600082015250565b7f4552433732313a20617070726f76652063616c6c6572206973206e6f74206f7760008201527f6e6572206e6f7220617070726f76656420666f7220616c6c0000000000000000602082015250565b7f4552433732313a2062616c616e636520717565727920666f7220746865207a6560008201527f726f206164647265737300000000000000000000000000000000000000000000602082015250565b7f4552433732313a206f776e657220717565727920666f72206e6f6e657869737460008201527f656e7420746f6b656e0000000000000000000000000000000000000000000000602082015250565b7f204e46547320696e2046726565206d696e740000000000000000000000000000600082015250565b7f4552433732313a206d696e7420746f20746865207a65726f2061646472657373600082015250565b7f4e6f206574686572206c65667420746f20776974686472617700000000000000600082015250565b7f4552433732313a20617070726f76656420717565727920666f72206e6f6e657860008201527f697374656e7420746f6b656e0000000000000000000000000000000000000000602082015250565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b7f4552433732314d657461646174613a2055524920717565727920666f72206e6f60008201527f6e6578697374656e7420746f6b656e0000000000000000000000000000000000602082015250565b7f4552433732313a20617070726f76616c20746f2063757272656e74206f776e6560008201527f7200000000000000000000000000000000000000000000000000000000000000602082015250565b7f4e6f7420656e6f756768204e465473206c656674000000000000000000000000600082015250565b50565b7f5472616e73666572206661696c65642e00000000000000000000000000000000600082015250565b7f4552433732313a207472616e736665722063616c6c6572206973206e6f74206f60008201527f776e6572206e6f7220617070726f766564000000000000000000000000000000602082015250565b7f416464726573732063616e2774206d696e74206d6f7265207468616e2031302060008201527f4e46547320696e205075626c69632073616c6500000000000000000000000000602082015250565b614d2681614396565b8114614d3157600080fd5b50565b614d3d816143a8565b8114614d4857600080fd5b50565b614d54816143b4565b8114614d5f57600080fd5b50565b614d6b81614400565b8114614d7657600080fd5b5056fea26469706673582212207f770850efe3f997233954729718069f5d8603297aca7ec08b651ce02e1e6afd64736f6c634300080700330000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000006287631c000000000000000000000000000000000000000000000000000000006287644800000000000000000000000000000000000000000000000000000000628765740000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000006288b5c800000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000036697066733a2f2f516d596b48566346653447766e63735154594c4d4746354248765770347456474b35486836334b4a7879486333382f000000000000000000000000000000000000000000000000000000000000000000000000000000000036697066733a2f2f516d596b48566346653447766e63735154594c4d4746354248765770347456474b35486836334b4a7879486333382f0000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000009472f18a0f6caeb103322a8ff30979ff9656e6f30000000000000000000000005d76ab21af2d65a9d97bc2ee976f02b73c050ccb00000000000000000000000013ee4ca689f7e742aa63598e747d611358a77a6d00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000004*/