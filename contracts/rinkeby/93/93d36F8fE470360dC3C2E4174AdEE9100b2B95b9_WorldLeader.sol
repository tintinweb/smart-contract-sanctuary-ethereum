/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/OwnableOrOwned.sol



pragma solidity ^0.8.0;

abstract contract OwnableOrOwned is Ownable {
    struct OwnedContracts {
        address payable leader;
        address missileMaker;
        address ufoInvasion;
    }
    OwnedContracts internal _ownedContracts;

    function ownedContracts() private view returns (OwnedContracts memory) {
        return _ownedContracts;
    }

    function _setUfoInvasion(address to) internal {
        _ownedContracts.ufoInvasion = to;
    }

    function _setOwnedContracts(
        address payable leader,
        address missileMaker,
        address ufoInvasion
    ) public virtual onlyOwner {
        _ownedContracts = OwnedContracts(leader, missileMaker, ufoInvasion);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


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


// File contracts/ERC721QueryableBurn.sol


pragma solidity ^0.8.4;
/**
 * @dev This implements a mapping which tracks whether an NFT was burned or not, so that we can both call
 * "_existsOrBurned" instead of "_exists" to determine if it has existed but was burned, or hasn't ever existed,
 * and "_ownerOfSafe" instead of "ownerOf" which returns the burn address if it has been burned before.
 */

abstract contract ERC721QueryableBurn is ERC721Enumerable {

    mapping(uint => bool) _isBurnedLookup;

    function _existsOrBurned(uint tokenId) internal view returns (bool) {
        return _isBurnedLookup[tokenId] || _exists(tokenId);
    }

    function existsOrBurned(uint tokenId) public view returns (bool) {
        return _existsOrBurned(tokenId);
    }

    function _isBurned(uint tokenId) internal view returns (bool) {
        return _isBurnedLookup[tokenId];
    }

    function isBurned(uint tokenId) public view returns (bool) {
        return _isBurned(tokenId);
    }

    function _ownerOfSafe(uint tokenId) internal view returns (address) {
        return !_isBurned(tokenId)
        ? ownerOf(tokenId)
        : address(0x0);
    }

    function ownerOfSafe(uint tokenId) public view returns (address) {
        return _ownerOfSafe(tokenId);
    }

    function burn(uint tokenId) internal virtual {
        _isBurnedLookup[tokenId] = true;
        _burn(tokenId);
    }
}


// File contracts/BaseNft.sol


pragma solidity ^0.8.4;
//import "./ERC721EnumerableWithQueryableBurn.sol";
contract BaseNft is ERC721QueryableBurn, OwnableOrOwned {
    using SafeMath for uint;
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdx;

    string public baseTokenURI;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokensOfOwner(address _owner) public view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}


// File contracts/Helpers.sol


pragma solidity ^0.8.4;
library Helpers {
    using SafeMath for uint;
    function shuffle(uint blockTimestamp, uint randVal, address[] memory uniqueHolders) internal pure returns (address[] memory) {
        for (uint256 i = 0; i < uniqueHolders.length; i++) {
            uint256 n = i.add(uint256(keccak256(abi.encodePacked(blockTimestamp, randVal, i))).mod(uniqueHolders.length.sub(i)));
            address temp = uniqueHolders[n];
            uniqueHolders[n] = uniqueHolders[i];
            uniqueHolders[i] = temp;
        }
        return uniqueHolders;
    }

    function shuffle(uint blockTimestamp, uint randVal, uint[] memory uniqueHolders) internal pure returns (uint[] memory) {
        for (uint256 i = 0; i < uniqueHolders.length; i++) {
            uint256 n = i.add(uint256(keccak256(abi.encodePacked(blockTimestamp, randVal, i))).mod(uniqueHolders.length.sub(i)));
            uint temp = uniqueHolders[n];
            uniqueHolders[n] = uniqueHolders[i];
            uniqueHolders[i] = temp;
        }
        return uniqueHolders;
    }

    function secsToDays(uint secs) internal pure returns (uint) {
        return secs.div(60).div(60).div(24);
    }

    function daysToSecs(uint numDays) internal pure returns (uint) {
        return numDays.mul(60).mul(60).mul(24);
    }

    function secsToHours(uint numSecs) internal pure returns (uint) {
        return numSecs.div(60).div(60);
    }

    function hoursToSecs(uint numHours) internal pure returns (uint) {
        return numHours.mul(60).mul(60);
    }

    function randomize(uint randVal, uint blockTimestamp, uint idx) internal pure returns (uint) {
        return uint256(keccak256(abi.encodePacked(blockTimestamp, randVal.add(idx.add(1)))));
    }

    function randomize(uint randVal, uint blockTimestamp) internal pure returns (uint) {
        return uint256(keccak256(abi.encodePacked(blockTimestamp, randVal)));
    }

    function modSafe(uint this_, uint by) internal pure returns (uint) {
        uint byThisSafe = by > 0 ? by : 1;
        return this_.mod(byThisSafe);
    }

    function subSafe(uint this_, uint by) internal pure returns (uint) {
        if (by >= this_) {
            return 0;
        }
        return this_.sub(by);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/finance/[email protected]


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;



/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}


// File contracts/WorldLeader.sol


pragma solidity ^0.8.4;

// this is (mostly) not my code
//import "./ERC721Enumerable.sol";
contract WorldLeader is ERC721Enumerable, PaymentSplitter, OwnableOrOwned {
    using SafeMath for uint;
    using Counters for Counters.Counter;
    using Helpers for uint;
    Counters.Counter private _tokenIdx;

    bool private _autoWithdraw = false;
    uint public constant MAX_SUPPLY = 5800;
    uint public constant PRICE = 0.13 ether;
    uint public constant MAX_PER_MINT = 21;

    enum ReleaseStatus {
        Unreleased,
        Released
    }

    ReleaseStatus public _releaseStatus = ReleaseStatus.Unreleased;

    string public baseTokenURI;
    uint private _numPayees;

    mapping(address => bool) _freeMintLookup;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721("BidensRocket", "BIDEN") PaymentSplitter(_payees, _shares) payable {
        _numPayees = _payees.length;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mintNFTs(uint _numToPayForCount) external payable {
        require(_releaseStatus != ReleaseStatus.Unreleased, "this is not yet released!");

        uint totalMinted = _tokenIdx.current();

        uint numToMintCount = _numToPayForCount;

        if (_numToPayForCount >= 10 && _numToPayForCount < 17) {
            numToMintCount += 2;
        } else if (_numToPayForCount >= 17) {
            numToMintCount += 3;
        }

        require(totalMinted.add(numToMintCount) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_numToPayForCount > 0 && _numToPayForCount <= MAX_PER_MINT, "count is empty!");

        uint priceNeeded = _freeMintLookup[msg.sender] ? PRICE.mul(_numToPayForCount.sub(1)) : PRICE.mul(_numToPayForCount);
        _freeMintLookup[msg.sender] = false;

        require(msg.value >= priceNeeded, "Need more Metis");

        for (uint i = 0; i < numToMintCount; i++) {
            _mintSingleNFT();
        }
        if (_autoWithdraw) {
            withdrawAuto();
        }
    }

    function exists(uint nftId) public view returns (bool) {
        return _exists(nftId);
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIdx.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIdx.increment();
    }

    function tokensOfOwner(address _owner) public view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdrawAuto() private {
        for (uint i = 0; i < _numPayees; i++) {
            release(payable(payee(i)));
        }
    }

    function hasFreeMint(address addr) public view returns (bool) {
        return _freeMintLookup[addr];
    }

    function addAddressesForFreeMint(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _freeMintLookup[addresses[i]] = true;
        }
    }

    function getReleaseStatus() public view returns (ReleaseStatus) {
        return _releaseStatus;
    }

    function releaseMint() public onlyOwner {
        require(_releaseStatus == ReleaseStatus.Unreleased, "this mint is already released!");
        _releaseStatus = ReleaseStatus.Released;
    }

    function setAutoWithdraw(bool to) public onlyOwner {
        _autoWithdraw = to;
    }

    function getAutoWithdraw() public view onlyOwner returns (bool) {
        return _autoWithdraw;
    }

    function getPrice() public view onlyOwner returns (uint) {
        return PRICE;
    }

    function getMaxSupply() public view onlyOwner returns (uint) {
        return MAX_SUPPLY;
    }

    function getNumPayees() public view onlyOwner returns (uint) {
        return _numPayees;
    }
}


// File contracts/MissileMaker.sol


pragma solidity ^0.8.4;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// handles creating new missiles & the RNG for doing so, their damage, & the intervals for how often players can
// try to roll more missiles again
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract MissileMaker is BaseNft {
    using Helpers for uint;
    using SafeMath for uint;
    using Counters for Counters.Counter;
    uint private _creationTime;

    // how many hours make up one interval (within which a leader NFT can only attempt to roll for a missile once)
    //
    uint public _hoursBetweenCutoffs = 24;
    uint public _missileChancePerc = 30;

    mapping(uint => uint) _lastRunLookup;
    uint _maxDmgPerRoll = 99;
    uint _minDmgPerRoll = 43;
    uint _numDmgRolls = 5;

    struct MissileOdds {
        uint numMissilesToMint;
        bool isOkay;
    }
    mapping(uint => uint64) _missileDmgLookup;

    uint32 _missileCreatedEventId;
    struct MissileCreatedState {
        uint16 dmg;
        uint32 missileCreatedEventId;
        address owner;
        uint missileNftId;
    }

    mapping(uint => MissileCreatedState) _missileCreatedLookup;

    function getMissileCreatedInfo(uint missileNftId) private view returns (MissileCreatedState memory) {
        //        require(_missileCreatedLookup[missileNftId].dmg > 0, "this missile created event doesn't exist!");
        return _missileCreatedLookup[missileNftId];
    }

    event MissilesCreated(uint missileCreatedEventId, address createdForAddress);

    constructor() BaseNft("Missile Maker", "U235") {
        _creationTime = block.timestamp;
    }

    function _getNextCutoffInSecondsSinceEpoch() private view returns (uint) {
        uint timeSinceCreationInDays = block.timestamp.sub(_creationTime).secsToDays();
        uint startOfThisStepInSecs = _creationTime.add(timeSinceCreationInDays.daysToSecs());
        uint nextCutoffHours = startOfThisStepInSecs.secsToHours().add(_hoursBetweenCutoffs);
        return nextCutoffHours.hoursToSecs();
    }

    function isRollForMissileReady(uint lastRun) private view returns (bool) {
        uint nextCutoff = getNextCutoffInSecondsSinceEpoch();
        return lastRun == 0 || nextCutoff.sub(lastRun) > _hoursBetweenCutoffs.mul(60).mul(60);
    }

    function _maybeGetMissiles(address sender, uint randVal, uint missilePercChance) private returns (uint) {
        WorldLeader thisWorldLeader = WorldLeader(_ownedContracts.leader);
        if (thisWorldLeader.balanceOf(sender) == 0) {
            return 0;
        }
        uint[] memory leaderNftIds = thisWorldLeader.tokensOfOwner(sender);
        uint currentPercentage = 0;
        uint numMissilesToMint = 0;

        bool anyReady = false;
        //
        // increment the % chance of rolling a missile according to the missilePercChance depending on number of NFTs owned.
        // when this reaches or exceeds 100%, consider this a guaranteed missile for the user and start back at 0 again
        // for their chance of rolling another one. repeat this for the amount of NFTs they own until you have an
        // amount of guaranteed missiles, and a % chance of getting one more.
        //
        // each unique world leader collection calculates these odds separately.
        //
        for (uint i = 0; i < leaderNftIds.length; i++) {
            uint leaderNftId = leaderNftIds[i];
            if (isRollForMissileReady(_lastRunLookup[leaderNftId])) {
                anyReady = true;
                _lastRunLookup[leaderNftId] = block.timestamp;
                currentPercentage = currentPercentage.add(missilePercChance);
                if (currentPercentage >= 100) {
                    numMissilesToMint++;
                    currentPercentage = currentPercentage.sub(100);
                }
            }
        }

        if (userDidRollMissile(randVal, currentPercentage)) {
            numMissilesToMint++;
        }

        return numMissilesToMint;
    }

    function userDidRollMissile(uint randVal, uint thisMissilePercChance) private view returns (bool){
        uint num = uint(randVal.randomize(block.timestamp).modSafe(100));
        return num <= thisMissilePercChance;
    }

    function maybeGetMissiles(uint randVal) external {
        randVal = randVal.randomize(block.timestamp, _creationTime);
        uint numMissilesToMint = _maybeGetMissiles(msg.sender, randVal, _missileChancePerc);
        createMissiles(msg.sender, randVal, numMissilesToMint);
    }

    function createMissiles(address sender, uint randVal, uint numMissilesToMint) private {
        for (uint i = 0; i < numMissilesToMint; i++) {
            uint missileNftId = _mintSingleNFT(sender);
            uint16 dmg = rollMissileDmg(randVal, i);
            _missileDmgLookup[missileNftId] = dmg;
            _missileCreatedLookup[missileNftId] = MissileCreatedState(dmg, _missileCreatedEventId, sender, missileNftId);
        }
        emit MissilesCreated(_missileCreatedEventId, sender);
        _missileCreatedEventId++;
    }

    function _mintSingleNFT(address to) private returns (uint) {
        uint newTokenID = tokenIdx.current();
        _safeMint(to, newTokenID);
        tokenIdx.increment();
        return newTokenID;
    }

    function burnSomeMissiles(uint[] calldata missileIds) external {
        require(msg.sender == _ownedContracts.ufoInvasion || msg.sender == owner());
        for (uint i = 0; i < missileIds.length; i++) {
            if (missileIds[i] != 0) {
                burn(missileIds[i]);
            }
        }
    }

    function _getMissileDmgs(address sender, uint256[] calldata missileIds) external view returns (uint64[] memory) {
        uint64[] memory dmgs = new uint64[](missileIds.length);
        for (uint i = 0; i < missileIds.length; i++) {
            dmgs[i] = _getMissileDmg(sender, missileIds[i]);
        }
        return dmgs;
    }

    function getDmgsOfMissiles(uint[] memory missileIds) external view returns (uint64[] memory) {
        uint64[] memory dmgs = new uint64[](missileIds.length);
        for (uint i = 0; i < missileIds.length; i++) {
            dmgs[i] = getMissileDmg(missileIds[i]);
        }
        return dmgs;
    }

    function _getMissileDmg(address sender, uint256 missileId) private view returns (uint64) {
        require(msg.sender == _ownedContracts.ufoInvasion || msg.sender == owner());
        require(ownerOf(missileId) == sender, "getMissileDmg :: you can't do that");
        uint64 missileDmg = getMissileDmg(missileId);
        //        burn(missileId);
        return missileDmg;
    }

    function rollMissileDmg(uint randVal, uint idx) private view returns (uint16){
        uint16 dmg = 0;
        for (uint i = 0; i < _numDmgRolls; i++) {
            dmg += uint16(randVal.randomize(block.timestamp, idx).modSafe(_maxDmgPerRoll.sub(_minDmgPerRoll)).add(_minDmgPerRoll));
        }
        return dmg;
    }

    // ********** PUBLIC DATA QUERY METHODS **********

    function getNextCutoffInSecondsSinceEpoch() public view returns (uint) {
        return _getNextCutoffInSecondsSinceEpoch();
    }

    // returns the percentage chance each World Leader NFT has at rolling a missile
    function getMissilePercChance() public view returns (uint) {
        return _missileChancePerc;
    }

    // returns the amount of damage the missile with the id `missileId` does
    function getMissileDmg(uint256 missileId) public view returns (uint64) {
        require(!_isBurned(missileId), "this missile has already been used!");
        require(_exists(missileId), "this does not exist!");
        return _missileDmgLookup[missileId];
    }

    // returns the missile ids of the missiles owned by the user
    function getUserMissiles(address _owner) public view returns (uint[] memory) {
        uint tokenCountNotBurned = 0;
        for (uint i = 0; i < balanceOf(_owner); i++) {
            uint token = tokenOfOwnerByIndex(_owner, i);
            if (!_isBurned(token)) {
                tokenCountNotBurned++;
            }
        }

        uint[] memory tokensId = new uint[](tokenCountNotBurned);

        for (uint i = 0; i < tokenCountNotBurned; i++) {
            uint token = tokenOfOwnerByIndex(_owner, i);
            if (!_isBurned(token)) {
                tokensId[i] = token;
            }
        }

        return tokensId;
    }

    // returns the number of missiles rolling attempts the message sender has available currently
    function numMissilesReadyToRoll() public view returns (uint) {
        WorldLeader leader = WorldLeader(_ownedContracts.leader);
        if (leader.balanceOf(msg.sender) == 0) {
            return 0;
        }
        uint[] memory leaderNftIds = leader.tokensOfOwner(msg.sender);
        uint numReady = 0;
        for (uint i = 0; i < leaderNftIds.length; i++) {
            if (isRollForMissileReady(_lastRunLookup[leaderNftIds[i]])) {
                numReady++;
            }
        }
        return numReady;
    }

    // ********** ONLY OWNER PARAMETER CHANGING **********

    function setHoursBetweenCutoffs(uint newDaysBetweenCutoff) public onlyOwner {
        _hoursBetweenCutoffs = newDaysBetweenCutoff;
    }

    function setMissilePercChance(uint newChancePerc) public onlyOwner {
        _missileChancePerc = newChancePerc;
    }
}


// File contracts/UfoInvasion.sol


pragma solidity ^0.8.4;
library UfoInvasionExt {
    using Helpers for uint;
    using Helpers for uint16;
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SafeMath for uint32;
    using SafeMath for uint64;
    using SafeMath for uint256;

    // in the case the last game was completed faster than the length wanted (given by _wantedGameLengthInHours),
    // make the next game's total UFO HP larger as a percentage of the gap and vice-versa
    //
    function getNewTotalUfoHealth(uint gameStartTime, uint gameEndTime, uint wantedGameLengthInHours, uint prevTotalUfoHp) internal pure returns (uint16) {
        uint gameLengthHours = uint16(gameEndTime.sub(gameStartTime).div(60).div(60));
        uint diff = gameLengthHours > wantedGameLengthInHours
        ? gameLengthHours.sub(wantedGameLengthInHours)
        : wantedGameLengthInHours.sub(gameLengthHours);
        uint adjustment = prevTotalUfoHp.div(100).mul(diff.mul(100).div(wantedGameLengthInHours));
        uint newTotalUfoHp = gameLengthHours > wantedGameLengthInHours
        ? prevTotalUfoHp.sub(adjustment)
        : prevTotalUfoHp.add(adjustment);
        return uint16(newTotalUfoHp);
    }

    function rollHpForUFOs(uint blockTimestamp, uint randVal, uint numUFOs, uint16 totalUfoHp) internal pure returns (uint16[] memory) {
        uint avgHpPerUfoNeeded;
        uint min;
        uint max;
        uint16[] memory ufoHps = new uint16[](numUFOs);
        for (uint i = 0; i < numUFOs; i++) {
            // setting hp values for individual UFOs to values within a range (so they're not all the same every
            // match, but ensuring that the total UFO hp ends up roughly around where we want it. this should
            // make the gameplay more varied between matches
            if (i == numUFOs - 1) {
                ufoHps[i] = totalUfoHp;
                break;
            }
            avgHpPerUfoNeeded = totalUfoHp.div(numUFOs.sub(i));
            min = avgHpPerUfoNeeded.subSafe(avgHpPerUfoNeeded.div(10));
            max = avgHpPerUfoNeeded.add(avgHpPerUfoNeeded.div(10));
            ufoHps[i] = uint16(randVal.randomize(blockTimestamp, i).modSafe(max.sub(min)).add(min));
            totalUfoHp = uint16(totalUfoHp.subSafe(ufoHps[i]));
        }
        return ufoHps;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// this handles the destroy UFO gameplay loop, including dynamically adjusting the difficulty of a match
// so that games approach taking the same amount of time regardless of the # of players playing.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract UfoInvasion is BaseNft("UFO Invasion", "UFO") {
    using Helpers for uint;
    using UfoInvasionExt for uint;
    using Helpers for uint16;
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SafeMath for uint32;
    using SafeMath for uint64;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct UfoState {
        uint16 curHp;
        uint16 startingHp;
        uint32 gameNum;
        address locationAddress;
        uint ufoId;
    }

    bool _gameActive = false;
    mapping(uint => uint) _ufoIdxLookup;

    uint32 _totalNumGamesPlayed = 0;
    uint8 _maxMissilesInOneAttack = 5;
    uint16 _minMintedNeededBeforeAttacks = 100;

    mapping(uint => UfoState) _ufoStateLookup;
    struct GameStats {
        bool isOver;
        uint16 totalUfoHp;
        uint32 gameNum;
        address winner;
        uint gameStartTimeInSeconds;
        uint elapsedSecs;
        uint[] ufoIds;
    }

    mapping(uint => GameStats) _gameStats;

    uint16 _totalUfoHp = 2500;
    uint _gameStartTime = 0;
    uint _gameEndTime;

    uint8 private _minNumUfosToAttack = 3;

    uint8 _minNumUFOs = 7;
    uint8 _maxNumUFOs = 15;

    uint16 _startGameMulti = 5;
    uint64 _gameWinnerMulti = 110; // 150%
    uint64 _ufoKillMulti = 150; // 150%
    uint16 _wantedGameLengthInHours = 48;

    // mapping of holder addresses to their index in the _airdropToAddresses array to ensure we get unique addresses
    mapping(address => bool) _airdropToIdx;
    address[] _airdropToAddresses;

    struct ScoreData {
        bool exists;
        uint32 wins;
        uint32 nukesUsed;
        uint64 score;
        address playerAddress;
    }

    uint128 _numPlayersWithScoreInGame;
    mapping(address => ScoreData) _curGamePlayerScoreLookup;
    address[] _curGameAddresses;

    uint128 _numPlayersOnLeaderboard;
    mapping(address => ScoreData) _allTimeLeaderboardLookup;
    address[] _allTimeLeaderboardAddresses;

    uint32 private _missileTxnId;
    struct MissileAttack {
        uint16 dmg;
        uint16 hpBefore;
        uint16 hpAfter;
        uint32 missileTxnId;
        uint32 gameNum;
        address attacker;
        address locationAddress;
        uint missileId;
        uint ufoId;
    }
    mapping(uint => MissileAttack) _missileAttackLookup;
    function getMissileAttackInfo(uint missileId) public view returns (MissileAttack memory) {
        require(_missileAttackLookup[missileId].dmg > 0
        //        , "this attack doesn't exist!"
        );
        return _missileAttackLookup[missileId];
    }

    event MissileAttackedUFO(uint32 gameNum, address attacker, uint missileTxnId, uint missileId);
    event GameStart(uint gameNum);
    event GameOver(uint gameNum);

    enum AttackUfoResult {
        OnlyDamageDealt,
        UfoDestroyed,
        UfoDestroyedAndGameOver
    }

    function findNumUfosStillAlive(uint[] memory ufoIds) private view returns (uint) {
        if (ufoIds.length == 0) {
            return 0;
        }
        uint stillAliveNum = 0;
        for (uint i = 0; i < ufoIds.length; i++) {
            if (_ufoStateLookup[ufoIds[i]].curHp > 0) {
                stillAliveNum++;
            }
        }
        return stillAliveNum;
    }

    function filterUfosAlive(uint[] memory ufosIds) private view returns (uint[] memory) {
        uint[] memory newUfos = new uint[](ufosIds.length.sub(1));
        uint added = 0;
        for (uint i = 0; i < ufosIds.length; i++) {
            if (_ufoStateLookup[ufosIds[i]].curHp > 0) {
                newUfos[added] = ufosIds[i];
            }
        }
        return newUfos;
    }

    function verifyNumUfosToAttack(uint16 numUfos, uint16 numAliveUFOs) private view {
        if (numAliveUFOs >= _minNumUfosToAttack) {
            require(numUfos >= _minNumUfosToAttack
            //            , "you must provide minNumUfosToAttack UFOs to attack when more than minNumUfosToAttack remain alive!"
            );
        } else {
            require(numUfos <= numAliveUFOs
            //            , "you cannot provide more ufoIds than there exists UFOs still alive!"
            );
        }
    }

    function validateUFOs(uint8 numMissileIds, uint16 amountUFOs, uint16 numAliveUFOs, uint randVal) private returns (uint) {
        verifyNumUfosToAttack(amountUFOs, numAliveUFOs);
        require(_gameActive
        //        , "there is not game currently active!"
        );
        require(WorldLeader(_ownedContracts.leader).totalSupply() > _minMintedNeededBeforeAttacks
        //        , "not enough world leader NFTs minted yet!"
        );
        require(numMissileIds <= _maxMissilesInOneAttack
        //        , string(abi.encodePacked("you can only use ", _maxMissilesAtOnce.uint2str(), "at once!"))
        );
        _gameStats[_totalNumGamesPlayed].elapsedSecs = block.timestamp.subSafe(_gameStats[_totalNumGamesPlayed].gameStartTimeInSeconds);
        //        randVal = randVal.add(_totalNumGamesPlayed + 2);
        return randVal.add(_totalNumGamesPlayed + 2);
    }

    function _ufoAttacker(uint randVal, uint[] memory missileIds, uint[] memory ufoIds) private {
        MissileMaker missileMaker = MissileMaker(_ownedContracts.missileMaker);
        uint64[] memory missileDmgs = missileMaker._getMissileDmgs(msg.sender, missileIds);
        AttackUfoResult result = AttackUfoResult.OnlyDamageDealt;
        for (uint i = 0; i < missileIds.length; i++) {
            if (result == AttackUfoResult.UfoDestroyed) {
                ufoIds = filterUfosAlive(ufoIds);
                if (ufoIds.length == 0) {
                    missileIds[i] = 0; // set the ones we don't want to burn to 0
                    break;
                }
            } else if (result == AttackUfoResult.UfoDestroyedAndGameOver) {
                missileIds[i] = 0;
                break;
            }
            randVal = randVal + i;
            uint ufoId = ufoIds[uint(randVal.randomize(block.timestamp, i).modSafe(ufoIds.length))];
            result = attackOneUFO(
                missileDmgs[i],
                msg.sender,
                missileIds[i],
                ufoId
            );
        }
        missileMaker.burnSomeMissiles(missileIds);
        _missileTxnId++;
    }

    function attackUFOs(uint randVal, uint[] memory missileIds, uint[] memory ufoIds) external {
        bool allAlive = true;
        for (uint i = 0; i < ufoIds.length; i++) {
            allAlive = _ufoStateLookup[ufoIds[i]].curHp > 0;
        }
        require(allAlive
        //        , "you cannot provide a UFO id for a UFO which is not alive!"
        );
        uint16 numAliveUFOs = uint16(getNumAliveUFOs());
        randVal = validateUFOs(uint8(missileIds.length), uint8(ufoIds.length), numAliveUFOs, randVal);
        _ufoAttacker(randVal, missileIds, ufoIds);
    }

    function attackRandomUFOs(uint randVal, uint[] memory missileIds) external  {
        uint8 numAliveUFOs = uint8(getNumAliveUFOs());
        uint8 amountUFOs = numAliveUFOs < _minNumUfosToAttack ? numAliveUFOs : _minNumUfosToAttack;
        randVal = validateUFOs(uint8(missileIds.length), amountUFOs, numAliveUFOs, randVal);
        uint[] memory randomUfoIds = getRandomUfoIds(randVal, amountUFOs > _gameStats[_totalNumGamesPlayed].ufoIds.length ? _gameStats[_totalNumGamesPlayed].ufoIds.length : amountUFOs);
        _ufoAttacker(randVal, missileIds, randomUfoIds);
    }

    function attackOneUFO(uint64 missileDmg, address sender, uint missileId, uint ufoId) private returns (AttackUfoResult) {
        updateScore(true, missileDmg, sender);
        updateScore(false, missileDmg, sender);
        uint16 hpBefore = _ufoStateLookup[ufoId].curHp;
        _ufoStateLookup[ufoId].curHp = uint16(_ufoStateLookup[ufoId].curHp.subSafe(missileDmg));
        _curGamePlayerScoreLookup[sender].score += missileDmg;
        _allTimeLeaderboardLookup[sender].score += missileDmg;
        emit MissileAttackedUFO(_totalNumGamesPlayed, sender, _missileTxnId, missileId);
        _missileAttackLookup[missileId] = MissileAttack(uint16(missileDmg), hpBefore,  _ufoStateLookup[ufoId].curHp, _missileTxnId, _totalNumGamesPlayed, sender, ownerOf(ufoId), missileId, ufoId);
        if (_ufoStateLookup[ufoId].curHp == 0) {
            missileDmg = uint64(missileDmg.mul(_ufoKillMulti).div(100).subSafe(missileDmg));
            _curGamePlayerScoreLookup[sender].score += missileDmg;
            _allTimeLeaderboardLookup[sender].score += missileDmg;
            burn(ufoId);
            if (isGameOver()) {
                _gameStats[_totalNumGamesPlayed].winner = getWinner();
                missileDmg = uint64(_curGamePlayerScoreLookup[sender].score.mul(_gameWinnerMulti).div(100).subSafe(_curGamePlayerScoreLookup[sender].score));
                _curGamePlayerScoreLookup[_gameStats[_totalNumGamesPlayed].winner].score += missileDmg;
                _allTimeLeaderboardLookup[_gameStats[_totalNumGamesPlayed].winner].score += missileDmg;
                _gameStats[_totalNumGamesPlayed].isOver = true;
                _gameEndTime = block.timestamp;
                return AttackUfoResult.UfoDestroyedAndGameOver;
            }
            return AttackUfoResult.UfoDestroyed;
        }
        return AttackUfoResult.OnlyDamageDealt;
    }

    function updateScore(
        bool isCurGame,
        uint64 missileDmg,
        address sender
    ) private {
        ScoreData storage scoreData;
        address[] storage scoreDataAddresses;
        uint128 numScoringPlayers;
        if (isCurGame) {
            scoreData = _curGamePlayerScoreLookup[sender];
            scoreDataAddresses = _curGameAddresses;
            numScoringPlayers = _numPlayersWithScoreInGame;
        } else {
            scoreData = _allTimeLeaderboardLookup[sender];
            scoreDataAddresses = _allTimeLeaderboardAddresses;
            numScoringPlayers = _numPlayersOnLeaderboard;
        }
        if (!scoreData.exists) {
            scoreData.exists = true;
            scoreData.playerAddress = sender;
            scoreData.nukesUsed = 1;
            scoreData.wins = 0;
            scoreData.score = missileDmg;
            if (numScoringPlayers >= scoreDataAddresses.length) {
                scoreDataAddresses.push(sender);
            } else {
                scoreDataAddresses[numScoringPlayers] = sender;
            }
            if (isCurGame) {
                _numPlayersWithScoreInGame++;
            } else {
                _numPlayersOnLeaderboard++;
            }
        } else {
            scoreData.score += missileDmg;
            scoreData.nukesUsed++;
        }
    }

    function isGameOver() private returns (bool) {
        for (uint i = 0; i < _gameStats[_totalNumGamesPlayed].ufoIds.length; i++) {
            if (_ufoStateLookup[_gameStats[_totalNumGamesPlayed].ufoIds[i]].curHp != 0) {
                return false;
            }
        }
        emit GameOver(_totalNumGamesPlayed);
        _totalNumGamesPlayed++;
        _gameActive = false;
        return true;
    }

    function getWinner() private returns (address) {
        address highestSeenAddr = address(0x0);
        uint highestSeenScore = 0;
        for (uint i = 0; i < _numPlayersWithScoreInGame; i++) {
            address playerAddr = _curGameAddresses[i];
            ScoreData memory curGameScore = _curGamePlayerScoreLookup[playerAddr];
            if (
                curGameScore.score > highestSeenScore
                || ( // if there's a tie, take the player with more score all-time, if this is also a tie we take who's first
                curGameScore.score == highestSeenScore
                && _allTimeLeaderboardLookup[playerAddr].score > _allTimeLeaderboardLookup[highestSeenAddr].score
                )
                || highestSeenScore == 0
                || highestSeenAddr == address(0x0)
            ) {
                highestSeenScore = curGameScore.score;
                highestSeenAddr = playerAddr;
            }
        }
        _allTimeLeaderboardLookup[highestSeenAddr].wins++;
        return highestSeenAddr;
    }

    function startNewUfoInvasionGame(uint randVal) public {
        randVal = randVal.add(_totalNumGamesPlayed + 1);
        require(!_gameActive);
        _gameActive = true;
        if (_gameStartTime != 0 && _gameEndTime != 0) { // use the default total UFO health when there has never been a game before
            _totalUfoHp = _gameStartTime.getNewTotalUfoHealth(_gameEndTime, uint(_wantedGameLengthInHours), uint(_totalUfoHp));
            for (uint i = 0; i < _numPlayersWithScoreInGame; i++) {
                delete _curGameAddresses[i];
            }
            _numPlayersWithScoreInGame = 0;
        }
        airdropNewUFOs(randVal);
        // reward players for paying to start new game
        _curGamePlayerScoreLookup[msg.sender].score += uint64(_totalUfoHp.mul(_startGameMulti).div(100));
        emit GameStart(_totalNumGamesPlayed);
    }

    // roll new random number of UFOs
    //
    function airdropNewUFOs(uint randVal) private  {
        uint totalUnique = 0;
        WorldLeader leader = WorldLeader(_ownedContracts.leader);
        uint numLeaderNfts = leader.totalSupply();

        for (uint i = 0; i < numLeaderNfts; i++) {
            uint256 leaderNftId = leader.tokenByIndex(i);
            address owner = leader.ownerOf(leaderNftId);
            if (_airdropToIdx[owner]) {
                continue;
            }
            totalUnique++;
            _airdropToIdx[owner] = true;
            if (i >= _airdropToAddresses.length) {
                _airdropToAddresses.push(owner);
            } else {
                _airdropToAddresses[i] = owner;
            }
        }
        address[] memory uniqueAddresses = new address[](totalUnique);
        for (uint i = 0; i < totalUnique; i++) {
            uniqueAddresses[i] = _airdropToAddresses[i];
        }

        for (uint i = 0; i < totalUnique; i++) {
            _airdropToIdx[_airdropToAddresses[i]] = false;
        }

        uniqueAddresses = randVal.shuffle(block.timestamp, uniqueAddresses);

        uint newNumUFOs = uint(randVal.randomize(block.timestamp).modSafe(_maxNumUFOs.sub(_minNumUFOs)).add(_minNumUFOs));
        uint numWinners = uniqueAddresses.length <= newNumUFOs ? uniqueAddresses.length : newNumUFOs;

        address[] memory ufoAirdropWinners = new address[](numWinners);

        for (uint i = 0; i < numWinners; i++) {
            ufoAirdropWinners[i] = uniqueAddresses[i];
        }

        uint16[] memory newUfoHps = block.timestamp.rollHpForUFOs(randVal, ufoAirdropWinners.length, _totalUfoHp);

        uint[] memory ufoIds = new uint[](ufoAirdropWinners.length);

        for (uint i = 0; i < ufoAirdropWinners.length; i++) {
            address locationAddress = ufoAirdropWinners[i];
            uint ufoId = _mintSingleNFT(locationAddress);
            _ufoIdxLookup[ufoId] = i;
            ufoIds[i] = ufoId;
            _ufoStateLookup[ufoId] = UfoState(newUfoHps[i], newUfoHps[i], _totalNumGamesPlayed, locationAddress, ufoId);
        }
        _gameStats[_totalNumGamesPlayed] = GameStats(
            false,
            _totalUfoHp,
            _totalNumGamesPlayed,
            address(0x0),
            _gameStartTime,
            0,
            ufoIds
        );
    }

    function _mintSingleNFT(address to) private returns (uint) {
        uint newTokenID = tokenIdx.current();
        _safeMint(to, newTokenID);
        tokenIdx.increment();
        return newTokenID;
    }

    function getRandomUfoIds(uint randVal, uint amountUFOs) private view returns (uint[] memory) {
        uint numAliveUFOs = getNumAliveUFOs();
        uint[] memory ufoIds = new uint[](numAliveUFOs);
        uint foundAlive = 0;
        for (uint i = 0; i < _gameStats[_totalNumGamesPlayed].ufoIds.length; i++) {
            if (_ufoStateLookup[_gameStats[_totalNumGamesPlayed].ufoIds[i]].curHp != 0) {
                ufoIds[foundAlive] = _gameStats[_totalNumGamesPlayed].ufoIds[i];
                foundAlive++;
            }
        }
        ufoIds = randVal.shuffle(block.timestamp, ufoIds);
        numAliveUFOs = amountUFOs > numAliveUFOs ? numAliveUFOs : amountUFOs;
        uint[] memory randomUfos = new uint[](numAliveUFOs);
        for (uint i = 0; i < numAliveUFOs; i++) {
            randomUfos[i] = ufoIds[i];
        }
        return randomUfos;
    }

    function getNumAliveUFOs() private view returns (uint) {
        uint numAliveUfos = 0;
        for (uint i = 0; i < _gameStats[_totalNumGamesPlayed].ufoIds.length; i++) {
            if (_ufoStateLookup[_gameStats[_totalNumGamesPlayed].ufoIds[i]].curHp != 0) {
                numAliveUfos++;
            }
        }
        return numAliveUfos;
    }

    function getUfoAtIdxByGameNum(uint ufoIdx, uint gameNum) public view returns (UfoState memory) {
        uint[] memory ufoIds = _gameStats[gameNum].ufoIds;
        require(ufoIdx < ufoIds.length
        //        , "there are not that many ufos in the current game!"
        );
        require(_existsOrBurned(ufoIds[ufoIdx])
        //        , "ufo at this id does not exist!"
        );
        UfoState memory ufoState = _ufoStateLookup[ufoIds[ufoIdx]];
        ufoState.locationAddress = _ownerOfSafe(ufoIds[ufoIdx]);
        return ufoState;
    }

    function getGameStatsByGameNum(uint gameNum) public view returns (GameStats memory) {
        require(gameNum <= _totalNumGamesPlayed
        //        , "there have not been that many games yet!"
        );
        return GameStats(
            _gameStats[gameNum].isOver,
            _gameStats[gameNum].totalUfoHp,
            _gameStats[gameNum].gameNum,
            _gameStats[gameNum].winner,
            _gameStats[gameNum].gameStartTimeInSeconds,
            !_gameStats[gameNum].isOver
        ? block.timestamp.sub(_gameStats[gameNum].gameStartTimeInSeconds)
        : _gameStats[gameNum].elapsedSecs,
            _gameStats[gameNum].ufoIds
        );
    }

    // ********** PUBLIC DATA QUERY METHODS **********

    // returns whether there is currently a game active or not
    function isGameActive() external view returns (bool) {
        return _gameActive;
    }

    // calls getNumUFOsInGameByGameNum(_totalNumGamesPlayed)
    function getCurGameNumUFOs() external view returns (uint) {
        if (!_gameActive && _totalNumGamesPlayed == 0) {
            return 0;
        }
        return getGameStatsByGameNum(_totalNumGamesPlayed).ufoIds.length;
    }

    // calls getNumUFOsInGameByGameNum(_totalNumGamesPlayed)
    function getUfoAtIdxInCurrentGame(uint ufoIdx) external view returns (UfoState memory) {
        require(_totalNumGamesPlayed > 0 || _gameActive
        //        , "there has never been a game before!"
        );
        return getUfoAtIdxByGameNum(
            ufoIdx,
            _gameActive
            ? _totalNumGamesPlayed
            : uint32(_totalNumGamesPlayed.sub(1))
        );
    }

    // returns the number of players in the current game's stats
    function getCurGameNumPlayers() external view returns (uint) {
        return _numPlayersWithScoreInGame;
    }

    // returns the stats for the player at the index `idx` for the current game
    function getCurGamePlayerAtIdx(uint idx) external view returns (ScoreData memory) {
        require(idx < _curGameAddresses.length
        //                , "there is no leaderboard entry at this index!"
        );
        require(_curGamePlayerScoreLookup[_curGameAddresses[idx]].exists
        //                , "this player has not yet played the current game!"
        );
        return _curGamePlayerScoreLookup[_curGameAddresses[idx]];
    }

    // returns the total number of players who have stats on the leaderboard
    function getNumLeaderboardPlayers() external view returns (uint) {
        return _numPlayersOnLeaderboard;
    }

    // returns the leaderboard information for the player at the index `idx`
    function getLeaderboardPlayerAtIdx(uint idx) external view returns (ScoreData memory) {
        require(
            idx < _allTimeLeaderboardAddresses.length
            && _allTimeLeaderboardLookup[_allTimeLeaderboardAddresses[idx]].exists
        //                , "there is no leaderboard entry at this index!"
        );
        //        require(_allTimeLeaderboardLookup[_allTimeLeaderboardAddresses[idx]].exists
        ////                , "this player has never scored any points before!"
        //        );
        return _allTimeLeaderboardLookup[_allTimeLeaderboardAddresses[idx]];
    }

    // returns the total number of games played so far
    function getTotalNumberOfGames() public view returns (uint) {
        return _totalNumGamesPlayed;
    }

    function setProps(
        uint8 minUfos,
        uint8 maxUfos,
        uint8 maxNumMissilesInOneAttack,
        uint16 minMintedNeededBeforeAttacks,
        uint16 startGameMulti,
        uint64 gameWinnerMulti,
        uint64 ufoKillMulti
    ) public onlyOwner {
        require(gameWinnerMulti >= 100 && ufoKillMulti >= 100);
        _minNumUFOs = minUfos;
        _maxNumUFOs = maxUfos;
        _maxMissilesInOneAttack = maxNumMissilesInOneAttack;
        _minMintedNeededBeforeAttacks = minMintedNeededBeforeAttacks;
        _gameWinnerMulti = gameWinnerMulti;
        _ufoKillMulti = ufoKillMulti;
        _startGameMulti = startGameMulti;
    }
}