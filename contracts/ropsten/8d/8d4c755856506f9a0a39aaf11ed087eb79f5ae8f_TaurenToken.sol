/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

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
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

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
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: TaurenNFT.sol



pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract TaurenNFT is ERC721URIStorage, Ownable {

    using SafeMath for uint256;

    event CreateNFT(address indexed user, uint256 types, uint256 tokenId);

    struct MyNFT{

        uint256 tokenId;
        
        uint256 types;

        uint256 price;

        uint256 periodIndex;

        uint256 status;
    }

	uint256 public counter;

    uint256 private randNum = 0;

    mapping(uint256 => uint256) public tokenIds;//tokenId

    mapping(uint256 => uint256) public tokenIdToIndex;

    mapping(address => uint256[]) public userTokenIds;

    mapping(uint256 => uint256) public tokenIdToTypes;

    mapping (uint256 => uint256) public tokenIdToStatus;//0正常, 1解救中

    mapping(uint256 => uint256) public typeToAmount;

    mapping(uint256 => uint256) public tokenIdToPeriod;//牛头人NFT期数

    mapping(uint256 => uint256) public periodToTokenId;

    mapping(uint256 => uint256) public typeToNFTPrice;

    // address USDT = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address DH = 0x755A1748c264C1EC3Fb2A22De5426C453fd38F63;

    // address private controllerAddress;
    mapping(address => bool) public isController;

	constructor() ERC721("TaurenNFT", "TRN"){
		counter = 0;

        typeToNFTPrice[1] = 500 * 10 ** 18;

        typeToNFTPrice[2] = 1000 * 10 ** 18;
	}

    function addController(address controllerAddr) public onlyOwner {
        isController[controllerAddr] = true;
    }

    function removeController(address controllerAddr) public onlyOwner {
        isController[controllerAddr] = false;
    }

    modifier onlyController {
         require(isController[msg.sender],"Must be controller");
         _;
    }

    function listNFTs(uint256 NFTType, uint256 amount) public onlyOwner {
        typeToAmount[NFTType] = amount;
    }

    function setNFTStatus(uint256 tokenId, uint256 status) public onlyController {
        tokenIdToStatus[tokenId] = status;
    }

    function setBullNFTPeriod(uint256 tokenId, uint256 period) public onlyController {
        tokenIdToPeriod[tokenId] = period;
        periodToTokenId[period] = tokenId;
    }

    function setNFTPrice(uint256 types, uint256 price) public onlyController {
        typeToNFTPrice[types] = price;
    }

    function setNFTPrices(uint256 types, uint256 price) public onlyOwner {
        typeToNFTPrice[types] = price;
    }

    function getBullNFTIds() public view returns(uint256[] memory bullTokenIds) {

        uint256[] memory tokenIds0 = new uint256[](1000);

        uint256 count;

        for(uint256 i = 1; i < 1001; i++){

            if(periodToTokenId[i] == 0){
                continue;
            }else{
                tokenIds0[i - 1] = periodToTokenId[i];

                count++;
            }
        }

        bullTokenIds = new uint256[](count);

        for(uint256 i = 0; i < count; i++){
            bullTokenIds[i] = tokenIds0[i];
        }

        return bullTokenIds;
    }

    function getMyNFT(address user) public view returns(MyNFT[] memory myNFTs) {

        uint256[] memory myTokenIds = getUserNFTIDs(user);

        myNFTs = new MyNFT[](uint256(myTokenIds.length));

        for(uint256 i = 0; i < myTokenIds.length; i++){

            uint256 types = tokenIdToTypes[myTokenIds[i]];

            uint256 price = typeToNFTPrice[types];

            uint256 period = tokenIdToPeriod[myTokenIds[i]];

            uint256 status = tokenIdToStatus[myTokenIds[i]];

            myNFTs[i] = MyNFT(myTokenIds[i], types, price, period, status);
        }

        return myNFTs;
    }

    function getMyNFTOfBull() public view returns(MyNFT[] memory myNFTs) {
        uint256[] memory bullTokenIds = getBullNFTIds();

        myNFTs = getMyNFTByTokenIds(bullTokenIds);

        return myNFTs;
    }

    function getMyNFTByType(address user, uint256 types) public view returns(MyNFT[] memory myNFTs) {

        uint256[] memory myTokenIds = getUserNFTIDs(user);

        myNFTs = new MyNFT[](uint256(myTokenIds.length));

        for(uint256 i = 0; i < myTokenIds.length; i++){

            uint256 typess = tokenIdToTypes[myTokenIds[i]];   

            if(types == typess){

                uint256 price = typeToNFTPrice[types];

                uint256 period = tokenIdToPeriod[myTokenIds[i]];

                uint256 status = tokenIdToStatus[myTokenIds[i]];

                myNFTs[i] = MyNFT(myTokenIds[i], types, price, period, status);
            }
        }

        return myNFTs;
    }

    function getMyNFTByTokenIds(uint256[] memory myTokenIds) public view returns(MyNFT[] memory myNFTs) {

        myNFTs = new MyNFT[](uint256(myTokenIds.length));

        for(uint256 i = 0; i < myTokenIds.length; i++){

            if(myTokenIds[i] != 0){

                uint256 types = tokenIdToTypes[myTokenIds[i]];

                uint256 price = typeToNFTPrice[types];

                uint256 period = tokenIdToPeriod[myTokenIds[i]];

                uint256 status = tokenIdToStatus[myTokenIds[i]];

                myNFTs[i] = MyNFT(myTokenIds[i], types, price, period, status);
            }

        }

        return myNFTs;
    }
    
	function createNFT(address user, uint256 NFTType) public onlyController returns (uint256){

        require(typeToAmount[NFTType] > 0, "ERC721: out of stock");

        counter ++;

        uint256 tokenId = _rand();

        _safeMint(user, tokenId);

        tokenIds[counter] = tokenId;

        tokenIdToTypes[tokenId] = NFTType;

        tokenIdToIndex[tokenId] = userTokenIds[user].length;

        userTokenIds[user].push(tokenId);

        typeToAmount[NFTType] = typeToAmount[NFTType].sub(1);

        emit CreateNFT(user, NFTType, tokenId);

        return tokenId;
	} 

	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(msg.sender, tokenId),"ERC721: you are not the owner nor approved!");	
		super._burn(tokenId);
	}

    function approveToController(address ownerAddr, uint256 tokenId) public onlyController {
        address owner = ownerOf(tokenId);

        require(ownerAddr == owner, "ERC721: this user does not own this tokenId");

        _approve(msg.sender, tokenId);
    }

    function _rand() internal virtual returns(uint256) {
        
        uint256 number1 =  uint256(keccak256(abi.encodePacked(block.timestamp, (randNum ++) * block.number, msg.sender))) % (4 * 10 ** 7) + 19686968;

        uint256 number2 =  uint256(keccak256(abi.encodePacked(block.timestamp, (randNum + 2) * block.number, msg.sender))) % (2 * 10 ** 7) + 19786796;
        
        return number1 + number2 + counter * 10 ** 8;
    }

    function getUserNFTIDs(address user) public view returns(uint256[] memory myTokenIds) {

        uint256 count;

        uint256[] memory tokenIds0 = new uint256[](uint256(userTokenIds[user].length));

        for(uint256 i = 0; i < userTokenIds[user].length; i++){
            if(userTokenIds[user][i] != 0){
                tokenIds0[count] = userTokenIds[user][i];

                count++;
            }
        }

        myTokenIds = new uint256[](uint256(count));

        for(uint256 i = 0; i < count; i++){
            myTokenIds[i] = tokenIds0[i];
        }

        return myTokenIds;
    }

    // function getBalance(address user) public view returns(uint256 balance) {

    //     uint256 decimals = ERC20(DH).decimals();

    //     balance = (ERC20(DH).balanceOf(user)).mul(100).div(10 ** decimals);

    //     return balance;
    // }

    // function getUserImageIdsByPageNumber(address user, uint256 pageNumber) public view returns(uint256[10] memory imageIds) {

    //     uint256 num = userTokenIds[user].length;

    //     if(num > 0){

    //         uint256[] memory allImageIds = new uint256[](uint256(num));

    //         uint256 count;

    //         for(uint256 i = 0; i < num; i++){
                
    //             if(userTokenIds[user][i] == 0){
    //                 count++;
    //                 continue;
    //             }else{
    //                 // allImageIds[i - count] = TokenIdToImageId[userTokenIds[user][i]];
    //             }
    //         }

    //         uint256 start = (pageNumber - 1) * 10;

    //         uint256 end = start + 10;

    //         for(uint256 j = start; j < end; j++){
    //             if(j < num && allImageIds[j] != 0){
    //                 uint256 k = j - start;
    //                 imageIds[k] = allImageIds[j];
    //             }
    //         }

    //         return imageIds;
    //     }
    // }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {

        uint256 index = tokenIdToIndex[tokenId];

        userTokenIds[from][index] = 0;

        tokenIdToIndex[tokenId] = userTokenIds[to].length;

        userTokenIds[to].push(tokenId);
        
        return super._transfer(from, to, tokenId);//授权与否?
    }
   
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File: IPancakeswapV2Router01.sol



pragma solidity ^0.8.0;

interface IPancakeswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: IPancakeswapV2Router02.sol



pragma solidity ^0.8.0;


interface IPancakeswapV2Router02 is IPancakeswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: IPancakeswapV2Factory.sol



pragma solidity ^0.8.0;


interface IPancakeswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: IBEP20.sol



pragma solidity ^0.8.0;
/**
 * @dev Interface of the BEP standard.
 */
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
// File: TaurenToken.sol



pragma solidity ^0.8.0;






contract TaurenToken is Context, IBEP20, Ownable {

    using SafeMath for uint256;

    struct Pledge{

        uint256 tokenId;
        
        uint256 types;

        // uint256 BUSDAmount;

        // uint256 KOFAmount;

        uint256 joinTime;
    }
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _blacklist;
    
    uint256 private _tTotal = 100 * 10**8 * 10**18;
    uint256 private constant MAX = ~uint256(0);
    string private _name = "Tauren Token";
    string private _symbol = "TT";
    uint8 private _decimals = 18;


    mapping (uint256 => address[]) public bullUsers;

    uint256 public bullPeriodIndex = 1;

    // uint256 public periodUserNum = 50;
    uint256 public periodUserNum = 5;

    // uint256 public totalSealTimes = 33;
    uint256 public totalSealTimes = 3;

    mapping (uint256 => address[]) public hammerOwner;

    // mapping (uint256 => uint256) public periodToTokenId;

    mapping (uint256 => uint256) public hammerFixTime;

    mapping (uint256 => Pledge) public tokenIdToPledges;

    mapping (uint256 => uint256) public pledgeTypeToRate;

    // mapping (uint256 => uint256) public tokenIdToStatus;

    uint256 public hammerFixCircle = 1 days;

    uint256 public hammerBasePrice = 100 * 10 ** 18;

    // uint256[] public NFTPrice = [500 * 10 ** 18, 1000 * 10 ** 18];

    address public bullNFTHolder = 0x45CbCBf16E1251d2019bEdb940f70Cb6F12068b0;

    address[] public genesisUser;

    mapping (address => uint256) public genesisUserIndex;

    uint256 public genesisPrivatePlacementAmount;

    uint256 public genesisPrivatePlacementTop = 100 * 10 ** 18;

    address public castingPoolAddr = 0xEd703D611df2fef3D0c626B1f688edFeeA8CfcF7;

    address public operationAddr = 0xEd703D611df2fef3D0c626B1f688edFeeA8CfcF7;

    address public genesisPoolAddr = 0xEd703D611df2fef3D0c626B1f688edFeeA8CfcF7;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public _castingPoolFee = 10;

    uint256 public _operationFee = 1;

    uint256 public _genesisPoolFee = 1;

    uint256 public _burnFee = 2;


    IPancakeswapV2Router02 public pancakeswapV2Router;

    address public pancakeswapV2Pair;

    // address public BUSD = 0xe52225889DC34fA282Ca9589f2b74aDA27a13b96;
    address public BUSD = 0x3faFBc359c6bA4fa624cD077A5Ef0bA7a28146FD;

    
    // bool inSwapAndLiquify;
    // bool public presaleEnded = false;
    
    uint256 public _maxTxAmount =  20 * 10**5 * 10**18;
    uint256 private numTokensToSwap =  3 * 10**3 * 10**18;
    uint256 private swapCoolDownTime = 5;
    // uint256 public swapCoolDownTimeForUser = 60;
    uint256 private lastSwapTime;
    mapping(address => uint256) private lastTxTimes;

    uint256 public tradingEnabledTimestamp = 1651845600;

    uint256 private timeToWait = 9;

    uint256 private randNum = 0;


    event ExcludedFromFee(address account);
    event IncludedToFee(address account);
    event AddBlacklist(address account);
    event RemoveBlacklist(address account);
    event UpdateFees(uint256 buyCastingPoolFee, uint256 buyOperationFee, uint256 buyCollapsePoolFee, uint256 burnFee);
    event UpdatedMaxTxAmount(uint256 maxTxAmount);
    event UpdateNumtokensToSwap(uint256 amount);
    event SwapAndCharged(uint256 token, uint256 liquidAmount, uint256 bnbPool,  uint256 bnbLiquidity);
    event UpdatedCoolDowntime(uint256 timeForContract);
    event UpdatedTradingEnabledTimestamp(uint256 timeForContract);

    event GenesisPrivatePlacement(address account, uint256 BNBAmount, uint256[] tokenIds);
    event RescueBullNFT(address account, uint256 tokenIds, uint256 periodIndex, uint256 rescueTimes);
    event SellTaurenNFT(address account, uint256 tokenId, uint256 periodIndex, uint256 price);
    event PledgeNFT(address account, uint256 tokenId, uint256 NFTType, uint256 types , uint256 tokenAmount);
    event QuitPledgeNFT(address account, uint256 tokenId, uint256 NFTType, uint256 types , uint256 tokenAmount, uint256 profit);
    

    // modifier lockTheSwap {
    //     inSwapAndLiquify = true;
    //     _;
    //     inSwapAndLiquify = false;
    // }

    TaurenNFT TRN;
    
    constructor () {
        //Test Net
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        //Mian Net
        // IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        // pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
        //     .createPair(address(this), BUSD);
        pancakeswapV2Pair = 0xD643BA060243Edf7995C68Be302515D93D07CF33;

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[castingPoolAddr] = true;
        _isExcludedFromFee[operationAddr] = true;
        _isExcludedFromFee[genesisPoolAddr] = true;

        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), owner(), _tTotal);

        TRN = TaurenNFT(0x47B815E627431dA0CF75fDEa630f2dd9C0033376);

        pledgeTypeToRate[1] = 100;
        pledgeTypeToRate[2] = 300;
        pledgeTypeToRate[3] = 500;
        pledgeTypeToRate[4] = 500;
    }

    //to receive ETH from pancakeswapV2Router when swapping
    receive() external payable {}

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setTimeToWait(uint256 _timeToWait) external onlyOwner {
        timeToWait = _timeToWait;
    }

    function setCoolDownTime(uint256 timeForContract) external onlyOwner {
        require(swapCoolDownTime != timeForContract);
        swapCoolDownTime = timeForContract;
        emit UpdatedCoolDowntime(timeForContract);
    }

    function setTradingEnabledTimestamp(uint256 tradingEnabledTime) external onlyOwner {
        require(tradingEnabledTimestamp != tradingEnabledTime);
        tradingEnabledTimestamp = tradingEnabledTime;
        emit UpdatedTradingEnabledTimestamp(tradingEnabledTime);
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }

    function addBlacklist(address account) external onlyOwner {
        _blacklist[account] = true;
        emit AddBlacklist(account);
    } 

    function removeBlacklist(address account) external onlyOwner {
        _blacklist[account] = false;
        emit RemoveBlacklist(account);
    }

    function addBot(address account) private {
        _blacklist[account] = true;
        emit AddBlacklist(account);
    }
    
    function setFees(uint256 castingPoolFee, uint256 operationFee, uint256 genesisPoolFee, uint256 burnFee) external onlyOwner() {
        require(_castingPoolFee != castingPoolFee || _operationFee != operationFee || _genesisPoolFee != genesisPoolFee || _burnFee != burnFee);

        if(_castingPoolFee != castingPoolFee){
            _castingPoolFee = castingPoolFee;
        }

        if(_operationFee != operationFee){
            _operationFee = operationFee;
        }

        if(_genesisPoolFee != genesisPoolFee){
            _genesisPoolFee = genesisPoolFee;
        }

        if(_burnFee != burnFee){
            _burnFee = burnFee;
        }
        
        emit UpdateFees(castingPoolFee, operationFee, genesisPoolFee, burnFee);
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
        emit UpdatedMaxTxAmount(maxTxAmount);
    }

    function setPledgeTypeToRate(uint256 index, uint256 rate) public onlyOwner {
        pledgeTypeToRate[index] = rate;
    }

    function setTaurenNFT(address TRNAddr) public onlyOwner {
        TRN = TaurenNFT(TRNAddr);
    }

    function getBalance(address user) public view returns(uint256 balance) {

        balance = balanceOf(user).mul(100).div(10 ** _decimals);

        return balance;
    }

    function setgenesisPrivatePlacementTop(uint256 top) public onlyOwner {
        genesisPrivatePlacementTop = top;
    }

    function genesisPrivatePlacement() public payable returns(uint256[] memory tokenIds) {

        uint256 BNBAmount = msg.value.div(10 ** 15);

        require(genesisPrivatePlacementAmount + msg.value <= genesisPrivatePlacementTop, "Private placement has ended");

        // require(BNBAmount >= 1 && BNBAmount % 1 == 0, "Wrong input");

        payable(genesisPoolAddr).transfer(msg.value);

        if(genesisUser.length == 0){

            genesisUserIndex[msg.sender] = genesisUser.length;

            genesisUser.push(msg.sender);
        }

        genesisPrivatePlacementAmount = genesisPrivatePlacementAmount + msg.value;

        tokenIds = new uint256[](BNBAmount);

        for(uint256 i = 0; i < BNBAmount; i++){
            uint256 tokenId = TRN.createNFT(msg.sender, 2);

            tokenIds[i] = tokenId;
        }

        emit GenesisPrivatePlacement(msg.sender, BNBAmount, tokenIds);

        return tokenIds;
    }

    function rescueBullNFT(uint256 _bullPeriodIndex) public {

        // uint256 _bullPeriodIndex = TRN.tokenIdToPeriod(tokenId);
        uint256 tokenId = TRN.periodToTokenId(_bullPeriodIndex);

        uint256 length  = hammerOwner[_bullPeriodIndex].length;

        require(length < totalSealTimes, "This NFT has been unlocked");

        require(checkBullUsers(_bullPeriodIndex, msg.sender), "You did not participate in this activity");

        address preOwner =  hammerOwner[_bullPeriodIndex][length - 1];

        require(preOwner != msg.sender, "You can't buy your own hammer");

        // require(hammerFixTime[_bullPeriodIndex] + 1 days < block.timestamp, "Hammer not yet repaired");
        require(hammerFixTime[_bullPeriodIndex] + 5 minutes < block.timestamp, "Hammer not yet repaired");

        uint256 price = hammerBasePrice.mul(105 ** (length - 1)).div(100 ** (length - 1));

        ERC20(BUSD).transferFrom(msg.sender, preOwner, price);

        hammerOwner[_bullPeriodIndex].push(msg.sender);

        uint256 amount = BUSDEqualToToken(price);

        transferFrom(msg.sender, deadWallet, amount * 10 ** 18);

        if(hammerOwner[_bullPeriodIndex].length >= totalSealTimes){

            TRN.approveToController(bullNFTHolder, tokenId);

            TRN.transferFrom(bullNFTHolder, msg.sender, tokenId);

            TRN.setNFTStatus(tokenId, 0);
        }

        emit RescueBullNFT(msg.sender, tokenId, _bullPeriodIndex, hammerOwner[_bullPeriodIndex].length);
    }

    function sellTaurenNFT(uint256 tokenId) public {

        uint256 _bullPeriodIndex = TRN.tokenIdToPeriod(tokenId);

        require(hammerOwner[_bullPeriodIndex].length >= totalSealTimes, "This NFT has not been unlocked");

        require(hammerOwner[_bullPeriodIndex][hammerOwner[_bullPeriodIndex].length - 1] == msg.sender && TRN.ownerOf(tokenId) == msg.sender, "You are not the owner");

        require(tokenIdToPledges[tokenId].joinTime == 0 && TRN.tokenIdToStatus(tokenId) == 0, "Your card is already pledged");

        TRN.approveToController(msg.sender, tokenId);

        TRN.transferFrom(msg.sender, owner(), tokenId);

        ERC20(BUSD).transferFrom(owner(), msg.sender, TRN.typeToNFTPrice(1));

        emit SellTaurenNFT(msg.sender, tokenId, _bullPeriodIndex, TRN.typeToNFTPrice(1));
    }

    function pledgeNFT(uint256 types, uint256 tokenId) public {

        require(TRN.ownerOf(tokenId) == msg.sender, "You are not the owner");

        require(tokenIdToPledges[tokenId].joinTime == 0 && TRN.tokenIdToStatus(tokenId) == 0, "Your card is already pledged");

        TRN.setNFTStatus(tokenId, 2);

        uint256 NFTType = TRN.tokenIdToTypes(tokenId);

        uint256 tokenAmount = BUSDEqualToToken(TRN.typeToNFTPrice(NFTType));

        if(types == 1){

            types = types.add(NFTType).sub(1).mul(10);

            // tokenIdToPledges[tokenId] = Pledge(tokenId,types,block.timestamp);
        }

        if(types == 2){

            types = types.add(NFTType).mul(10);

            transferFrom(msg.sender, castingPoolAddr, tokenAmount);
        }

        tokenIdToPledges[tokenId] = Pledge(tokenId,types,block.timestamp);

        emit PledgeNFT(msg.sender, tokenId, NFTType, types, tokenAmount);

    }

    function quitPledgeNFT(uint256 tokenId) public {

        require(TRN.ownerOf(tokenId) == msg.sender, "You are not the owner");

        require(tokenIdToPledges[tokenId].joinTime > 0 && TRN.tokenIdToStatus(tokenId) == 1, "Your card is not pledged");

        TRN.setNFTStatus(tokenId, 0);

        uint256 NFTType = TRN.tokenIdToTypes(tokenId);

        uint256 tokenAmount = BUSDEqualToToken(TRN.typeToNFTPrice(NFTType));

        if(tokenIdToPledges[tokenId].types >= 30){
            tokenAmount = tokenAmount.mul(2);
        }

        uint256 profit = getPledgeProfit(tokenId);

        transferFrom(castingPoolAddr, msg.sender, tokenAmount + profit);

        delete tokenIdToPledges[tokenId];

        emit QuitPledgeNFT(msg.sender, tokenId, NFTType, tokenIdToPledges[tokenId].types, tokenAmount, profit);
    }

    // function BUSDEqualToken(uint256 BUSDAmount) public view returns(uint256){
    //     uint256 tokenOfPair = balanceOf(pancakeswapV2Pair);

    //     uint256 BUSDOfPair = ERC20(BUSD).balanceOf(pancakeswapV2Pair);

    //     uint256 amount = tokenOfPair.mul(BUSDAmount).div(BUSDOfPair);

    //     return amount;
    // }

    function BUSDEqualToToken(uint256 BUSDAmount) public view returns(uint256) {
        
        uint256 tokenOfPair = balanceOf(pancakeswapV2Pair);

        uint256 BUSDOfPair = ERC20(BUSD).balanceOf(pancakeswapV2Pair);

        // uint256 amount = tokenOfPair.mul(BUSDAmount).div(BUSDOfPair * 100);
        uint256 amount = tokenOfPair.mul(BUSDAmount).div(BUSDOfPair);

        return amount;
    }

    function getPledgeKOGAmount(uint256 tokenId) public view returns(uint256){

        uint256 NFTTypes = TRN.tokenIdToTypes(tokenId);

        uint256 KOGAmount = BUSDEqualToToken(TRN.typeToNFTPrice(NFTTypes));

        return KOGAmount;
    }

    function getPledgeProfit(uint256 tokenId) public view returns(uint256){

        uint256 NFTType = TRN.tokenIdToTypes(tokenId);

        uint256 tokenAmount = BUSDEqualToToken(TRN.typeToNFTPrice(NFTType));

        if(tokenIdToPledges[tokenId].types >= 30){
            tokenAmount = tokenAmount.mul(2);
        }

        uint256 pledgeDays = (block.timestamp - tokenIdToPledges[tokenId].joinTime).div(24 hours);

        uint256 profit = tokenAmount.mul(pledgeTypeToRate[tokenIdToPledges[tokenId].types]).mul(pledgeDays).div(365);

        return profit;
    }

    function getBullUsers(uint256 _bullPeriodIndex) public view returns(address[] memory users) {

        users = bullUsers[_bullPeriodIndex];

        return users;
    }

    function checkBullUsers(uint256 _bullPeriodIndex, address user) public view returns(bool) {

        address[] memory users = bullUsers[_bullPeriodIndex];

        for(uint256 i = 0; i < users.length; i++){
            if(user == users[i]) return true;
        }

        return false;
    }

    function getHammerOwner(uint256 _bullPeriodIndex) private returns(address user) {

        uint256 index =  (uint256(keccak256(abi.encodePacked(block.timestamp, (randNum ++) * block.number, msg.sender)))) % bullUsers[_bullPeriodIndex].length;

        user = bullUsers[_bullPeriodIndex][index];

        return user;
    }

    function getBullNFTDetail(uint256 _bullPeriodIndex) public view returns(uint256 tokenId, address currentOwner, uint256 price, uint256 sealTimes) {

        // uint256 _bullPeriodIndex = TRN.tokenIdToPeriod(tokenId);

        tokenId = TRN.periodToTokenId(_bullPeriodIndex);

        uint256 length  = hammerOwner[_bullPeriodIndex].length;

        if(hammerOwner[_bullPeriodIndex].length > 0){
            price = hammerBasePrice.mul(105 ** (length - 1)).div(100 ** (length - 1));
        }

        sealTimes = totalSealTimes - length;

        currentOwner = bullUsers[_bullPeriodIndex][length - 1];

        return (tokenId, currentOwner, price, sealTimes);
    }

    function getHammerCurrentOwner(uint256 _bullPeriodIndex) public view returns(address user) {

        user = hammerOwner[_bullPeriodIndex][hammerOwner[_bullPeriodIndex].length - 1];

        return user;
    }

    function activateBullNFT() public {
        address user = getHammerOwner(bullPeriodIndex);
                    
        hammerOwner[bullPeriodIndex].push(user);

        uint256 tokenId = TRN.createNFT(bullNFTHolder, 1);

        TRN.setBullNFTPeriod(tokenId, bullPeriodIndex);

        hammerFixTime[bullPeriodIndex] = block.timestamp;

        TRN.setNFTStatus(tokenId, 1);

        bullPeriodIndex ++;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_blacklist[from] && !_blacklist[to], "Transfer from blacklist");
        
        if (to == pancakeswapV2Pair && balanceOf(pancakeswapV2Pair) == 0) {
            require(_isExcludedFromFee[from], "You are not allowed to add liquidity before presale is ended");
        }

        uint256 takeFee = 0;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            _tokenTransfer(from,to,amount,0);
            return;
        }

        // if (block.timestamp <= tradingEnabledTimestamp + timeToWait){
        //     addBot(to);
        //     _tokenTransfer(from,address(this),amount,0);
        //     return;
        // }

        // if (from != address(pancakeswapV2Router) && from != pancakeswapV2Pair && lastTxTimes[from] + swapCoolDownTime > block.timestamp && !_blacklist[from]){
        //     addBot(from);
        //     _tokenTransfer(from,operationAddr,amount,0);
        //     return;
        // }

        // if (to != address(pancakeswapV2Router) && to != pancakeswapV2Pair && lastTxTimes[to] + swapCoolDownTime > block.timestamp && !_blacklist[to]){
        //     addBot(to);
        //     _tokenTransfer(from,operationAddr,amount,0);
        //     return;
        // }

        // if (from != address(pancakeswapV2Router) && from != pancakeswapV2Pair){
        //     lastTxTimes[from] = block.timestamp;
        // }else if (to != address(pancakeswapV2Router) && to != pancakeswapV2Pair){
        //     lastTxTimes[to] = block.timestamp;
        // }

        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // uint256 tokenOfPair = balanceOf(pancakeswapV2Pair);
        // uint256 BUSDOfPair = ERC20(BUSD).balanceOf(pancakeswapV2Pair);

        if(
            !_isExcludedFromFee[from] && 
            !_isExcludedFromFee[to] && 
            // balanceOf(pancakeswapV2Pair) > 0 && 
            // !inSwapAndLiquify &&
            from != address(pancakeswapV2Router) && 
            from != pancakeswapV2Pair
            // from == pancakeswapV2Pair || to == pancakeswapV2Pair
        ) {
            takeFee = 1;

            // if(tokenOfPair > 0 && BUSDOfPair > 0 && amount >= tokenOfPair.mul(100).div(BUSDOfPair)){
            // if(tokenOfPair > 0 && BUSDOfPair > 0){
                bullUsers[bullPeriodIndex].push(to);
                if(bullUsers[bullPeriodIndex].length >= periodUserNum){
                    activateBullNFT();
                }
            // }  
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        // uint256 tokenBalance = balanceOf(address(this));
        // if(tokenBalance >= _maxTxAmount)
        // {
        //     tokenBalance = _maxTxAmount;
        // }
        
        // bool overMinTokenBalance = tokenBalance >= numTokensToSwap;
        // if (
        //     balanceOf(pancakeswapV2Pair) > 0 && 
        //     overMinTokenBalance &&
        //     !inSwapAndLiquify &&
        //     from != pancakeswapV2Pair &&
        //     swapAndLiquifyEnabled &&
        //     block.timestamp >= lastSwapTime + swapCoolDownTime
        // ) {
        //     tokenBalance = numTokensToSwap;
        //     swapAndCharge(tokenBalance);
        //     lastSwapTime = block.timestamp;
        // }

        // //indicates if fee should be deducted from transfer
        // if (balanceOf(pancakeswapV2Pair) > 0 && (from == pancakeswapV2Pair || to == pancakeswapV2Pair) && (!_isExcludedFromFee[from] && !_isExcludedFromFee[to])) {
        //     takeLiquidFee = true;
        // }else if((from != pancakeswapV2Pair && to != pancakeswapV2Pair) && (!_isExcludedFromFee[from] && !_isExcludedFromFee[to])){
        //     takeTransferFee = true;
        // }
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        // if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
        //     takeLiquidFee = false;
        // }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _getFeeValues(uint256 tAmount) private view returns (uint256 castingPoolFee, uint256 operationFee, uint256 genesisPoolFee, uint256 burnFee, uint256 tTransferAmount) {
        castingPoolFee = tAmount.mul(_castingPoolFee).div(10**2);
        operationFee = tAmount.mul(_operationFee).div(10**2);
        genesisPoolFee = tAmount.mul(_genesisPoolFee).div(10**2);
        burnFee = tAmount.mul(_burnFee).div(10**2);

        tTransferAmount = tAmount.sub(castingPoolFee).sub(operationFee).sub(genesisPoolFee).sub(burnFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 takeFee) private {

        require(!_blacklist[sender] && !_blacklist[recipient], "Transfer from blacklist");

        if(takeFee == 1){
            (uint256 castingPoolFee, uint256 operationFee, uint256 genesisPoolFee, uint256 burnFee, uint256 tTransferAmount) = _getFeeValues(amount);
            // (,,,uint256 burnFee, uint256 tTransferAmount) = _getFeeValues(amount);

            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);

            _balances[castingPoolAddr] = _balances[castingPoolAddr].add(castingPoolFee);
            _balances[operationAddr] = _balances[operationAddr].add(operationFee);
            _balances[genesisPoolAddr] = _balances[genesisPoolAddr].add(genesisPoolFee);
            _balances[deadWallet] = _balances[deadWallet].add(burnFee);

            // uint256 swapToken = amount.sub(tTransferAmount).sub(burnFee);

            // uint256 initialBalance = ERC20(BUSD).balanceOf(address(this));

            // swapTokensForEth(swapToken);

            // uint256 newBalance = ERC20(BUSD).balanceOf(address(this)).sub(initialBalance);

            // uint256 totalFee = _castingPoolFee + _operationFee + _genesisPoolFee;

            // ERC20(BUSD).transfer(castingPoolAddr, newBalance.mul(_castingPoolFee).div(totalFee));
            // ERC20(BUSD).transfer(operationAddr, newBalance.mul(_operationFee).div(totalFee));
            // ERC20(BUSD).transfer(genesisPoolAddr, newBalance.mul(_genesisPoolFee).div(totalFee));
            
            emit Transfer(sender, recipient, tTransferAmount);
            return;
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
    }
}