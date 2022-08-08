/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/ERC721A.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 internal currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}


// File contracts/SSTORE2.sol

pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*///////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}


// File contracts/MintVKStore.sol

pragma solidity ^0.8.0;

contract MintVKStore {
    function verifyingKey() external pure returns (uint256[50] memory) {
        uint256[50] memory IC;
        
        
            IC[0] = 10349858936374310350028840692986924688505832686543153319064156993955009388204; 
            IC[1] = 5222661465036803267917797684942165423798368187546484392429932129869720073842;                                 
        
            IC[2] = 1152820881643253628980002234168499642424805547648269735348361317405715210982; 
            IC[3] = 16316563555838162300070567619777955669307228524310993199835844450206820875741;                                 
        
            IC[4] = 21046052309519641364220597734312280870935112950592182349817699604569195287816; 
            IC[5] = 9970758484219198584516798899168319710408743992293091540113678096957533696923;                                 
        
            IC[6] = 13043375714937066715859500200886948667663917026519948027963100174833440404028; 
            IC[7] = 16891059543081011375690182759708214090895173686464347631090362825478276484537;                                 
        
            IC[8] = 7878823523277303321835614504369295599448252082517036845518409596920880038325; 
            IC[9] = 6953143463777376737603053101713201341585406130222013706697670143611509031804;                                 
        
            IC[10] = 9421585264927548356240369106173167727051632065330185875847103736532181062013; 
            IC[11] = 6673068995269429710513465241257668475985792335548461791373406632619687040316;                                 
        
            IC[12] = 20468628288513714580569185407980038821414346547480351989049908536151985791399; 
            IC[13] = 20023370304904084163728734538400654607425743923976619373960471050965721833936;                                 
        
            IC[14] = 11605063489174823670786672822870117373233344933353751971227170621564827781054; 
            IC[15] = 10409159073346723122692365481593061814872378453696466725747630086450683160832;                                 
        
            IC[16] = 12166615051865378882312329802414148430210278547532500143747458911004423917464; 
            IC[17] = 89191182654543168291345991019093364166264932757875105169650267058533107802;                                 
        
            IC[18] = 735487828622234634936775272140514065730615061458992991581958977104647875188; 
            IC[19] = 5199042348837718336627822525873282969885010255033578388857805518164045799635;                                 
        
            IC[20] = 2849803056718757804436797122347118278166476934949010787563288351503689980521; 
            IC[21] = 3804449000925647246653267162575884653975027158643990313312577768673943040523;                                 
        
            IC[22] = 9705731124588698284969767696124428087778639188259160532794533875795136404911; 
            IC[23] = 4625358445321283988682233827858977105871292217857511844743041042872739205026;                                 
        
            IC[24] = 17328895838559043206939052939619437828810916381913232789036292458206785090988; 
            IC[25] = 4720999537310912752683506434541863430836436206335452965645963296006081033745;                                 
        
            IC[26] = 4104685090219277256731491026004381765009537454355416873440830858419795089659; 
            IC[27] = 6185212382941060721217215505482766386484012198644801933075657798885283859041;                                 
        
            IC[28] = 6029401718138434170626738743047249563676334692958534396951102855517881976905; 
            IC[29] = 5026611719160111827107605215069687358101412468118024027327957509581199303028;                                 
        
            IC[30] = 12125232283171909785872891505693487178169141136144434621454396266926113089104; 
            IC[31] = 2580242725300312646622717192096821700307005024305687182386139086022282949477;                                 
        
            IC[32] = 15213783804604230984486995396884123638021642868526844536350346263649447977672; 
            IC[33] = 20530316432824357973602819462043738407295619148259860422980670769979596027204;                                 
        
            IC[34] = 11557921724978057537103602637379818907223141952452329833004691221109181805598; 
            IC[35] = 7417830429997547314376051577244629281573506076569265094774103556111433458996;                                 
        
            IC[36] = 207976142129605688360884716069827551300142833901656864675731598125157762497; 
            IC[37] = 5383707700516566455208647593248436088027693147885518838489790645482601559415;                                 
        
            IC[38] = 18242535700303747900267321398543321971210448489026255514435600858263898064468; 
            IC[39] = 12055777776587214366902841115708954164400488037876906405971087640267941336577;                                 
        
            IC[40] = 6519755839097246649316013323270745503221882582198553708443165825440259458485; 
            IC[41] = 3468880131360003383066114559777047530247782549556074246108535274922137293824;                                 
        
            IC[42] = 18241030747352010350971628190282404784011423254851889043711640931145534701166; 
            IC[43] = 17938427134153100646984263787957253295790178580030054635740540565276821396044;                                 
        
            IC[44] = 18065958091581708341333780910461948349665044152556183342953166251978223475835; 
            IC[45] = 19324519169276806566049412987459283013419941404143799647475773254749464262628;                                 
        
            IC[46] = 7045536021494909922651736548996402801343612977608864581604870222898672545133; 
            IC[47] = 4516058638992334421499068505976565840440530116192015523479443162780741576918;                                 
        
            IC[48] = 17448721240823846419199827289110421245023537888445247983738354356566339881398; 
            IC[49] = 12998992641971481090778547590331278533004967323832927006721098933552937935331;                                 
           
            
        return IC;
        
    }
}


// File contracts/Pairing.sol

// https://tornado.cash Verifier.sol generated by trusted setup ceremony.
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {
  uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  struct G1Point {
    uint256 X;
    uint256 Y;
  }

  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] X;
    uint256[2] Y;
  }

  struct VerifyingKey {
    Pairing.G1Point alfa1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] IC;
  }

  /*
   * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
   */
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    // The prime q in the base field F_q for G1
    if (p.X == 0 && p.Y == 0) {
      return G1Point(0, 0);
    } else {
      return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
    }
  }

  /*
   * @return r the sum of two points of G1
   */
  function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    require(success, "pairing-add-failed");
  }

  /*
   * @return r the product of a point on G1 and a scalar, i.e.
   *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
   *         points p.
   */
  function scalar_mul(uint256 pX, uint256 pY, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = pX;
    input[1] = pY;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-mul-failed");
  }

  /* @return The result of computing the pairing check
   *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   *         For example,
   *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   */
  function pairing(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool) {
    G1Point[4] memory p1 = [a1, b1, c1, d1];
    G2Point[4] memory p2 = [a2, b2, c2, d2];

    uint256 inputSize = 24;
    uint256[] memory input = new uint256[](inputSize);

    for (uint256 i = 0; i < 4; i++) {
      uint256 j = i * 6;
      input[j + 0] = p1[i].X;
      input[j + 1] = p1[i].Y;
      input[j + 2] = p2[i].X[0];
      input[j + 3] = p2[i].X[1];
      input[j + 4] = p2[i].Y[0];
      input[j + 5] = p2[i].Y[1];
    }

    uint256[1] memory out;
    bool success;

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    require(success, "pairing-opcode-failed");

    return out[0] != 0;
  }
}


// File contracts/MintVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
// 2022 hellsegga
//      compatibility with newer solidity version
//      gas optimization
//
pragma solidity ^0.8.0;


contract MintVerifier {
    using Pairing for *;
    address public VKStore;
    constructor(address addr) {
        VKStore = addr;
    }
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        //Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12496117104180901670522161682925063774403170071743495398826058279206052045580,
             5777445479013789829133487891353560159682482786394596653162267112494723311229],
            [5900269805713201160370535831808016527107849708580582493556700143442774400324,
             7045527285555319446921989553169442903129524494236740831643851304133463424296]
        );
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] calldata a,
            uint[4] calldata b,
            uint[2] calldata c,
            uint[24] calldata input
        ) external view returns (bool r) {
       
        // Negate proofA first
        Pairing.G1Point memory proofA;
        if (a[0] == 0 && a[1] == 0) {
            proofA = Pairing.G1Point(0, 0);
        } else {
            proofA = Pairing.G1Point(a[0], Pairing.PRIME_Q - (a[1] % Pairing.PRIME_Q));
        }
        Pairing.G2Point memory proofB = Pairing.G2Point([b[0], b[1]], [b[2], b[3]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(c[0], c[1]);
        
        VerifyingKey memory vk = verifyingKey();
        uint256 [50] memory vkIC = MintVKStore(VKStore).verifyingKey();
        require( (input.length + 1) * 2 == vkIC.length,"verifier-bad-input");
        
        uint256[3] memory ip3;
        uint256[4] memory ip4;
        bool success;

        for (uint i = 0; i < input.length; i++) {
            require(input[i] < Pairing.SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            
            ip3[0] = vkIC[(i + 1)*2];
            ip3[1] = vkIC[(i + 1)*2+1];
            ip3[2] = input[i];

            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := staticcall(sub(gas(), 2000), 7, ip3, 0x80, add(ip4, 0x40), 0x60)
                // Use "invalid" to make gas estimation work
                switch success
                case 0 {
                    invalid()
                }
            }

            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := staticcall(sub(gas(), 2000), 6, ip4, 0xc0, add(ip4, 0), 0x60)
                // Use "invalid" to make gas estimation work
                switch success
                case 0 {
                    invalid()
                }
            }
        }

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x;

        ip4[2] = vkIC[0];
        ip4[3] = vkIC[1];
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, ip4, 0xc0, vk_x, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
            invalid()
            }
        }
        
        bool result = Pairing.pairing(
            proofA, proofB,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proofC, vk.delta2
        );

        return result;
    }
}


// File contracts/RevealVKStore.sol

pragma solidity ^0.8.0;

contract RevealVKStore {
    function verifyingKey() external pure returns (uint256[588] memory) {
        uint256[588] memory IC;
        
        
            IC[0] = 7274139923696740817567557332787153588609481765896884011457791081199116992076; 
            IC[1] = 14004742006476490550482820118465302081097750434287311222322047997058261129728;                                 
        
            IC[2] = 15860365533454383622742202738761128979230134992210333503417770889624058107006; 
            IC[3] = 4339095031666815656428153144509808757107666007532031396675073627276342808825;                                 
        
            IC[4] = 7978091654007007128889097291262768208044841256843612498093281061960310041964; 
            IC[5] = 15531354925613709437511530658455620669417508959529785399245448409897724303473;                                 
        
            IC[6] = 7835275121594606403494739004531478446724349819920163113634085903736346023790; 
            IC[7] = 8237956728267386009246946402475927778470748950820725396659881941471513250026;                                 
        
            IC[8] = 3134874779290958864643010738005151405197807262084451682964507270674121974021; 
            IC[9] = 21430922375681372096492310592440770629056725667345235101544439039549288549726;                                 
        
            IC[10] = 17999908347658560847809426996980930293935838072653525552024611566736865553489; 
            IC[11] = 15928248523664804690296197389138357028439369140779091095007968937122176232573;                                 
        
            IC[12] = 19799648144648868935253747500165576585503399163994521803609659175989309521987; 
            IC[13] = 6383068780351931949557701049994682377965888051724257154563073896085965906701;                                 
        
            IC[14] = 11390167104827974604325859398336131914029181916674019469257655865147304098389; 
            IC[15] = 8008621256186241062375286683565466403870730952765179433295386258819449069732;                                 
        
            IC[16] = 19325212927946380537563953956831628073891815500563391294566286357421897604994; 
            IC[17] = 4864289130693619488540106019195920236726228424197577384899455515887934314247;                                 
        
            IC[18] = 7968181341187848207964479931201011271004445178795717894041669837223647238114; 
            IC[19] = 6992147337262592149851050745887749457205665677941087925602669317788117945923;                                 
        
            IC[20] = 3372014509258443261323018008078200818249927912878880214282971867041599645532; 
            IC[21] = 10610934741890252215945019815980538766011116519909158282387679578968778795879;                                 
        
            IC[22] = 4455628486628679069683972963505213879654181017480097425975648904816133966692; 
            IC[23] = 2303843084667236091410168597505742303458295892129076897798890723038138911498;                                 
        
            IC[24] = 15173211287179576440040531426081974832853799650838089434495194059807745379724; 
            IC[25] = 21761722516018680411442248081953597752073307495215025510059116402777528117768;                                 
        
            IC[26] = 21517184897914361233173772938690727988818653421631569699569364285991303593873; 
            IC[27] = 16531059410728434103351168663245155710216552931537832650913892688660462823866;                                 
        
            IC[28] = 13017734676642941861860146365809499022346673957679441830103865655662413895368; 
            IC[29] = 4112541592983867021820865837398102493370581009742834808418722400920500932137;                                 
        
            IC[30] = 11239661077356054057700289822952730266702611393732418408775470902320724955506; 
            IC[31] = 5980739815126513506733697893901654965634474995403682357317908438713095762934;                                 
        
            IC[32] = 4957340003443853928761171132983294583361141558155380279336593760170614709446; 
            IC[33] = 5978810156696749486484663975464164059522285837282571240488354401798684953588;                                 
        
            IC[34] = 17153976924414777636761467198396047907848123030048779850059053351085696790305; 
            IC[35] = 19311206785330601294132207272819318669735285424118660036777956925130762578968;                                 
        
            IC[36] = 20512098288789987314443519553068387003707355906694647569564430378433925189722; 
            IC[37] = 9514394098374795940210421190474632079136953079262625397153184135146096741708;                                 
        
            IC[38] = 19767695626824632253406339911765425387129731036074796177350314256853547522637; 
            IC[39] = 18921976923951030369339103280908902651890871530066994202454076824470095016158;                                 
        
            IC[40] = 2038347695999538676827867000855183662100505508879919488141036430611325623074; 
            IC[41] = 18206003489637541547496095654829254549138600194087039402496154327084553679142;                                 
        
            IC[42] = 18276521858917313345236515707618677195084210705397777313748422676642645921271; 
            IC[43] = 8468097645224896141773689493688722680713130201256200485700256419588034700990;                                 
        
            IC[44] = 8321255933272199602011016574066142289043264884417632923309290758756015094274; 
            IC[45] = 6364557225695741240081300395085377606561961671901296190000371232016876584695;                                 
        
            IC[46] = 9223338944415245441778402815483222707998190149241620995376780247112325967608; 
            IC[47] = 2580360286558130608049238060979563898500638644831646036294575509838862374905;                                 
        
            IC[48] = 8009178972189575888099448524180202069671882793017787237618417731111823808864; 
            IC[49] = 14959266205142336487288618847704458920556497345874991867530419236463853807950;                                 
        
            IC[50] = 1812719954621083339942708126634660820840038799096508400059421843939726622861; 
            IC[51] = 264016769135907681409614793516955465894512414079217282611877020251217339487;                                 
        
            IC[52] = 8887689445035847214773033159462914455717817064153795673412014774782518671196; 
            IC[53] = 5885464433214477921624628194682724066180120725242468140727109682604638989847;                                 
        
            IC[54] = 5077218830805011409105416764011916548713509847503463158181674103903154558497; 
            IC[55] = 11745985292329082277758664682862865845431994732247113320252888472540516646464;                                 
        
            IC[56] = 4313959210478719367067903112621361278761215435887270264034322832563346244338; 
            IC[57] = 846402034087657020645218597109309659114772946495948601971508669055069960711;                                 
        
            IC[58] = 1550880186183098408593695153632365922414323787658274616850649510507476872069; 
            IC[59] = 16177488000438856227094169055241542370960470892270015523477407850926596676965;                                 
        
            IC[60] = 17424710939851727209595712088651378135595154819699995780832187849035461789945; 
            IC[61] = 4508919750394832289431363882296136686443146869107234391384370431474276559271;                                 
        
            IC[62] = 20017736595343920124829334567651431666317818447472395613256936375265162606825; 
            IC[63] = 599436142413956329398073472476354925988426655727192318357949092957682681523;                                 
        
            IC[64] = 17008415844843667025894978175537757712442343273507690655187064671824710405522; 
            IC[65] = 16208243731110687382550953729317709604440694419677559239134450207397118980163;                                 
        
            IC[66] = 15820243523180343950727645710649072001197996401948849596369270760367577890441; 
            IC[67] = 20610887745903799679451872290673955429468107986772741632240065036187934573894;                                 
        
            IC[68] = 15369194290651575718063910352679515556933748218136490860965703843757912665379; 
            IC[69] = 2922792663362941383240500070988065040058165906468622969859261192974524814662;                                 
        
            IC[70] = 8952972913176167134366493857853208583897807621010250653606021087750461717518; 
            IC[71] = 5860566251798052084505455571734281408163779102597040257322141236037930169136;                                 
        
            IC[72] = 7044674401188708407008063360433175267428355397332876717533416454989947595552; 
            IC[73] = 6970038971917515807919240095728003754636785878764061092988547458818243862649;                                 
        
            IC[74] = 19161551597346913284807027433376387541656827469418212122547061181993498479575; 
            IC[75] = 3304073257475964846070865752245208424967703389844180179622720584187938834217;                                 
        
            IC[76] = 5915389344298746979611643788029068793492110423946454816842706149675361583226; 
            IC[77] = 20718819642706639951202822625558485945773860216061826336528626815718838940201;                                 
        
            IC[78] = 19201369326989267179737077083049528860892717532822901904715532670179100028402; 
            IC[79] = 11101843361472429894819311695049143443889614905571797034511267337703372550538;                                 
        
            IC[80] = 2085748274046764446574321698783169559572429578015714623999650719653691013325; 
            IC[81] = 4967919677809299421362078220976102740617561778404793958034278076967392361284;                                 
        
            IC[82] = 11616273800178700917553193866390575873084656825045610562569543044574471380294; 
            IC[83] = 16893525225397378471570932403687429204043102265412982084156662175389836773190;                                 
        
            IC[84] = 8540904588279818852100254845368479271540956942171769769250512152511364322265; 
            IC[85] = 735650361710842682935371744865495705036481004979831928774491352224794444176;                                 
        
            IC[86] = 5455104055720090735393437273708897671135965514842183996944989954910074524632; 
            IC[87] = 12786036470489637407840513464337344420801710255859005739195202149251696003667;                                 
        
            IC[88] = 5233372903243657947031895757827139155920520729278962328198518160016149173935; 
            IC[89] = 17762800322545713261581495650561362415082981682305846457086461220063748433916;                                 
        
            IC[90] = 13649386923317052611870063075640305439043502350600138078475938015770052677175; 
            IC[91] = 10883079144678815783175389959145372577574014479834576431211520921818738967399;                                 
        
            IC[92] = 17557667194301228112315188756013920353012077490159622093892280879451595788370; 
            IC[93] = 2367303730755768015329969640162193798186049237267468160195352710591305332975;                                 
        
            IC[94] = 5065533807352744597451626970844521719557112711657221976065506375822081712423; 
            IC[95] = 12664666774759722155655966683606620668127575872572979476232683017267111060151;                                 
        
            IC[96] = 7712555971847200434657671633301012514923879900157532098028954905062083242881; 
            IC[97] = 8646824257784375956659312312999459095201920896265126336631184671912897648417;                                 
        
            IC[98] = 12262305431675753067529367311075927277719937671943791114044758743740644009922; 
            IC[99] = 18178099550708200237357943170335410198208825563329452754695517412184597568312;                                 
        
            IC[100] = 13151399806917228977802014288427810364460123868861422553604377991776432899508; 
            IC[101] = 15561099062223171979539480044812910842860290557028169677047954066906020438392;                                 
        
            IC[102] = 13176822503447106405364530487249419144705328357975956851056946294493011709123; 
            IC[103] = 6042030430121460032271652091795555849722594196703255662658482269515083383000;                                 
        
            IC[104] = 20301166885057623367607872635265787738832350066179332715886958139515549558317; 
            IC[105] = 156688859633697955790094446864328808499230346465219910738054021990168431357;                                 
        
            IC[106] = 5129808376928482458350696049869191057362479565509879600538287275420595803700; 
            IC[107] = 2671118883906327110574464874028124408364094363923452504987705455691831245435;                                 
        
            IC[108] = 14319527714634141408359678034981932096434447097410272691451832371074150284562; 
            IC[109] = 9362427546250175865457411502134255038102452527011086248057304898369011324030;                                 
        
            IC[110] = 13573173831986825718378786727085584064397418194834832086620362977166679707024; 
            IC[111] = 1715515523774008286260205656839901473086351495090553977093251197216937723490;                                 
        
            IC[112] = 200767211747479867225315482032611547411157046945606494865732219620090582325; 
            IC[113] = 1583701316998391064413170835685432442062005714626919851803441634103670559886;                                 
        
            IC[114] = 3194074809283708957138475633316407668133117273452170306102891768685837917807; 
            IC[115] = 2370635261256585727896109387743603451352921719661860622458546755557626935001;                                 
        
            IC[116] = 4056927590231736287383173958763258686161133506793010956823604143958001392639; 
            IC[117] = 8645435687680650553660673197878481955543278111532537778153501037711298999621;                                 
        
            IC[118] = 16032848697641575325274630724354340267689221615424076421647755363363604493591; 
            IC[119] = 6488359092212193715074935077407068053949193849310161963095668102912309120192;                                 
        
            IC[120] = 18863037997240930567321440513814408659962136409808383898469146775721513887896; 
            IC[121] = 13848301320111515089615090598791734336869925347635138453840849825369019890455;                                 
        
            IC[122] = 10104475634494469729444657962137982665800396135859401483350157515657914183196; 
            IC[123] = 6117742036737189994795540504758155376897057673938662189443282009047822702112;                                 
        
            IC[124] = 10074730740725159733547906422097234584126413851299920006467294253060211597502; 
            IC[125] = 11148922760725990951696145841014412147031706139620682988805797307323518983569;                                 
        
            IC[126] = 21734691011084068178652229822243558134167142492857453797001956729282748876857; 
            IC[127] = 16471244106425780356192582015291025514155116313684423693726287741312640201782;                                 
        
            IC[128] = 10952501420312310985934775009302933341098559385316631704372956907540730979917; 
            IC[129] = 3815498627400941275777989398974659501373884171136743247904840216409336409283;                                 
        
            IC[130] = 13843406413822089846348841130472005236853741425829006690013853107881408351261; 
            IC[131] = 21624438086524321194265336114748479432779169440136381323816241035061064522414;                                 
        
            IC[132] = 12751267010244084501578495607381857192906679414318161549660697062647954740402; 
            IC[133] = 11712542222606564106159244564313386025381400794396379176488011371419351753741;                                 
        
            IC[134] = 15487764143046667562786709606043029130604757970827830954586366362346245760527; 
            IC[135] = 10258381691257680328449056729381780814435806091270211811465095707344888820670;                                 
        
            IC[136] = 12174610989797909264315867949709613921978888441246868121792970976182230510936; 
            IC[137] = 14587225606219828914517156545493527909125240180342625988581886364992977336149;                                 
        
            IC[138] = 9430028694724403549463725075866133288619859421575160466489087339543730449283; 
            IC[139] = 12023187930624516467255761991437620632139890975396010140093690788328225755903;                                 
        
            IC[140] = 10329595161411668723170782497714665670863444936789475181914988673334194394363; 
            IC[141] = 21115585662907872699127283485739799387217494567837862935658999079036794828073;                                 
        
            IC[142] = 18448178479298218142106325968080506104232809607168681635310085484920334426230; 
            IC[143] = 5906690144093295283005354673861999740422623079827980835848168148595319298314;                                 
        
            IC[144] = 16053980389831715867145998410079394800019245838142448954064395515580715923389; 
            IC[145] = 6591991776525452161227216426078512637625155283241674054764755542106393423315;                                 
        
            IC[146] = 2794663016731638660112027989188656983297418986225934345733416330472097448121; 
            IC[147] = 13939174927032831654628257359958947024988602545750012258694810122383371856530;                                 
        
            IC[148] = 10541979186239522348301738099805709976855604492621633981428380760275922796265; 
            IC[149] = 5277317890407913904348132540877581639408750058772327887424464647530091892911;                                 
        
            IC[150] = 6915399117759133414241164398991339567661123593539827875010811128763317328207; 
            IC[151] = 10730821520457311439735094801837782438826524875592365373377519928092672307548;                                 
        
            IC[152] = 11148435403137169871227413475160751670712646949266477661054782030022191156413; 
            IC[153] = 13850655116858440235695344598815268111681175669805559863733385422213506679623;                                 
        
            IC[154] = 2028055286580779031299648184650523513720786844090548232958953112774748365136; 
            IC[155] = 20738183236030578826323129720904750969755849601570232122660823623535208685918;                                 
        
            IC[156] = 4978782139400469825207862887739280466293742242702558241679063577898454534562; 
            IC[157] = 18297822900974684382585046803024451131892857938308400735019774192278137540186;                                 
        
            IC[158] = 1597944720171461680835811816469126720388013129999533435946494809854344561080; 
            IC[159] = 19762271999066423340881858400282011886517883680290115064495627851205011981062;                                 
        
            IC[160] = 20455486457049498409285553775817056743586893162430815085095261844259859481190; 
            IC[161] = 6841451300765967420278001213046304866757404950451074818568241987631611225706;                                 
        
            IC[162] = 16461474780422012515163186739368138002694935972812574697561507214358266840903; 
            IC[163] = 15423581901575902089441125354277862350545544615783671585332848754841470051132;                                 
        
            IC[164] = 3617017498888893611953614295481044343279445742132326533270490678257918091019; 
            IC[165] = 2016615811979624031471412887913238743264630647626943770493981433244384625267;                                 
        
            IC[166] = 3742333238688284526956696157476971502940805727772789084256043540432487886025; 
            IC[167] = 5823464167809833156205007556210006990597816211899484879411665719310716587918;                                 
        
            IC[168] = 16327351002680388434337374971820157260319853826724046652101249092184317937963; 
            IC[169] = 14763857557098303778835271420382878997010358369557243385725705853707136115191;                                 
        
            IC[170] = 6264947198419942552730817316885029755310765907362895117369783291291010451598; 
            IC[171] = 3771640455655263604752788382826446903749729510276139626700564060215958946440;                                 
        
            IC[172] = 10818103307060478857643068365905325889584393487271001904764688757753662560061; 
            IC[173] = 13133842471191795658569114667042517375918531105068633658714144086280632062460;                                 
        
            IC[174] = 7313097261571120027317625998345817961778820680426810828337330513473071044057; 
            IC[175] = 13087433105820157998965233320907263671089320350506928509939849183378078449638;                                 
        
            IC[176] = 8962678147234827255182447998727932305098555592195449810017612626980163913556; 
            IC[177] = 14367385037281551985067925606042999205407851168555725282369580112274426815282;                                 
        
            IC[178] = 12225836970458467948368771065314883020545760479573010888224084334761969595677; 
            IC[179] = 12551186547279772969340782418280827488098489188316644931866267420125766768838;                                 
        
            IC[180] = 14225784853386425648388605123493242295563488148929070604070881846937982309432; 
            IC[181] = 12206034324892989020815320104484328469377059893452214090351991881459952838086;                                 
        
            IC[182] = 19406475039542034464362801907504574919751856087978988200816914333011214689161; 
            IC[183] = 20092597186342225318811282703910642812323690504812472231672982279635546225906;                                 
        
            IC[184] = 15925022343105748097322456076987631534352532941247420802566394594539240932842; 
            IC[185] = 15135363327047146811778252591959366437168559246846867214505605518229995892242;                                 
        
            IC[186] = 10283391905171086735739989527245478528044877808499831867852997437894098380269; 
            IC[187] = 10391208526934501597644949417248300683090219578835484631711081251588081802752;                                 
        
            IC[188] = 17613989668068328557641736926326802531833199301512676076900766609070221435147; 
            IC[189] = 6527831363063334198760269588912026271100151675065677502603691850481304699342;                                 
        
            IC[190] = 7952776279906701507115877874653468310408121874986589038709954079434616060049; 
            IC[191] = 21645219352398642879988104794851302890369099651092228522282577101009110768070;                                 
        
            IC[192] = 19063870699696544934059132582317180161340457501693044898839655221532460074238; 
            IC[193] = 11134039497097333855432282075095643154165734707546272631183252069114507641566;                                 
        
            IC[194] = 1251755576051412602300624647429470330530285274503926093326684692445663132166; 
            IC[195] = 7171937738232148272499097367872213606013518508692681317433591020845247417323;                                 
        
            IC[196] = 13345885517426393742560776593962607548729162524237615697940202711197402553085; 
            IC[197] = 20240528694491313854908682874795994782987581054929758253417747118910830134187;                                 
        
            IC[198] = 18255887328411749369393363288198240134612084391841770515224701288215481040742; 
            IC[199] = 3368764226073516219826198222456136056158250383421612220154637682536350375913;                                 
        
            IC[200] = 12481888418253495835614724046810268198979040708209139274031038816644640415868; 
            IC[201] = 2110125141326959518318554094881387855926783619980826697803444850015504636778;                                 
        
            IC[202] = 4497158530052387861592685898483498978917075491891351937840497753259188907902; 
            IC[203] = 16065483415585848560023733180854106199862235585413811099953074594067262531364;                                 
        
            IC[204] = 485646999265518180959663773162017535508640911264771643960365571230719402281; 
            IC[205] = 2144103115837621333118085122915545583115595278865659755137046753335000303470;                                 
        
            IC[206] = 15725677857927389356830373204041487197663747438825247036061488775569300679652; 
            IC[207] = 3609978693567926830689907590771473806032613745652858913382087577265580669299;                                 
        
            IC[208] = 16875532455991428674452192654601601847809536472578414216211988770002145292281; 
            IC[209] = 8248354061427302395296676985509669782169294069059503024282707706983067395205;                                 
        
            IC[210] = 12943489051684214606424245992013562648918049686392106961721637442118441662079; 
            IC[211] = 11658376019547466475400552563543469239256153378162682023485790452435651973985;                                 
        
            IC[212] = 19848903563412643420226046955005926596876353171766574399430417419524644839966; 
            IC[213] = 6678206774345371622900374007654202172659752761474807201283752490921138003442;                                 
        
            IC[214] = 17334183459124816198696576045394415321505061925012497341049096222019400270702; 
            IC[215] = 5710969569314285419691742323613423994862061724207986220739594890760928263386;                                 
        
            IC[216] = 3152279945468750796054650288529380263333409823042043976142127452608135513686; 
            IC[217] = 17119360573671289428156266596170726552152575408781250032396807982229952931671;                                 
        
            IC[218] = 5094017948702484368077842551055083270467303269926144559720189593090328433130; 
            IC[219] = 7538849987406349711581470856149412742925732085930869618941373016214942989047;                                 
        
            IC[220] = 13396683417123573034004756069047053598051106526698615680330070067580660725660; 
            IC[221] = 2821883059561657266168928787634614260663357329188065255691958039405473628097;                                 
        
            IC[222] = 7365581978173976384226470038530432729836543547591798410765855201091670663690; 
            IC[223] = 1985436313123271795918023682432813298653403072871133424411930832309719675484;                                 
        
            IC[224] = 13742165384338804043951759995280982337646630882014610154763573121580048175895; 
            IC[225] = 12818981934811225691704126808427426071416121031319498281170468562888232177118;                                 
        
            IC[226] = 12265016243638280453225966369748199098166719088112337588996598943891240964463; 
            IC[227] = 5948681921090811611203435266844867483644865989078580607880720278061035116617;                                 
        
            IC[228] = 7036961913376006804603699633506435646731601695181805984264764330077615762874; 
            IC[229] = 6350635742638562015272600877549515035336849909832197160913074077878653904872;                                 
        
            IC[230] = 7869622860629652842520474557045308765117856102916930613314096355788634059806; 
            IC[231] = 15099295370800285381776172993183629845567339528007616737359550546899026683186;                                 
        
            IC[232] = 8451250377180221246149951661843787867068554027167866815873527811571106466828; 
            IC[233] = 14960445888743824024149194025235852613510436559420916777603393251239398500518;                                 
        
            IC[234] = 2409645565412948405091686845793819316340056092814418429696483006680029697927; 
            IC[235] = 735651679971551445142105547988337740225308311066137517365364953401366321867;                                 
        
            IC[236] = 3096988692601064940347764302877524958395353975627268670778230074918722730290; 
            IC[237] = 1696458477317855213238686982079079280619389889363300613384780181542627780122;                                 
        
            IC[238] = 11784986404390597949835083239574757870682001885946169877250949583470138587052; 
            IC[239] = 16219125463373802814371933403668371835886741858067321753600029481272046946924;                                 
        
            IC[240] = 9620949745586751257682718860348558830338813130748976347904394890768430484493; 
            IC[241] = 4013531362967236600664289062661862511772714476786032114959186011412081492226;                                 
        
            IC[242] = 12826001551941189023069319747609730252182066549417778567446792475474720076205; 
            IC[243] = 15622836548666471095480194022813171443220324158923891048049977847077148062731;                                 
        
            IC[244] = 16098626093532608721255874557615055549885216563423375391872075873686126614836; 
            IC[245] = 9975446983017121961723063189726030551430895155256713791016180902613420512561;                                 
        
            IC[246] = 1191813468080414151415669220545780659254455747591862350424740649687066647881; 
            IC[247] = 12431232206315373058890926329177594616714758946171007753836975158962910204486;                                 
        
            IC[248] = 8439514901073969215771844606960434885962443003259597001708996935137210639806; 
            IC[249] = 4981465733794640122427386672527763577565210230678003627548126166319961601867;                                 
        
            IC[250] = 15766761739673387348307468583857430106706091012156342184467879309827083448006; 
            IC[251] = 4769449727683763550377288257242538875309728830977186601672996646815359235153;                                 
        
            IC[252] = 2051803866348074604720530341057514949719417007807988815500535074107163066259; 
            IC[253] = 7671184002118397280345456607201009708407330220933177627067454497681792089502;                                 
        
            IC[254] = 20187640419010341681561381974695696574565917071445117900003610995326286186187; 
            IC[255] = 9002539844698138073512128921497429354038334346263165858221571455442061610008;                                 
        
            IC[256] = 3707788969764420503026113710609184556237244433211465280580955844564319200061; 
            IC[257] = 12739202382463948761532231987623963363802180497777660523946753708125086953632;                                 
        
            IC[258] = 18564732432540619926484636194780742646952985719947462001615589829292175758426; 
            IC[259] = 15374460896554510939373255249710756303224603447414879817905432674527855523786;                                 
        
            IC[260] = 16176933215962016883735193463512780728015024773642053397439041362990593175751; 
            IC[261] = 9416767214680100367083000907177889238472803173936285497752664916416731233144;                                 
        
            IC[262] = 13212025948010058083097267661758841725030840444948330185274280082535961311126; 
            IC[263] = 8771815182587105886172901327876910880117829874493908798094213526546305893037;                                 
        
            IC[264] = 13613938423280641125801886739441423173015709716239217304520058953308028323425; 
            IC[265] = 16726358281123889756685369761427873553873486377186518635698486529496394506701;                                 
        
            IC[266] = 9922954709090293792255777380822043229595696292552873745444527621640437830755; 
            IC[267] = 21694570616008626652317023901037634820550915400732291875097221260425610589115;                                 
        
            IC[268] = 4892392652850448608693678915945687346613691130188097509875200336506746392563; 
            IC[269] = 6354391908591115826109861104850423385773356223389241472920990301817260859159;                                 
        
            IC[270] = 7273735631034860115703064433845637155997118041433076011906881660179505263255; 
            IC[271] = 3780787498786621276797810044495215883115615313062132245809355863253747053873;                                 
        
            IC[272] = 19443915461096256881949742907143226069397873015674081690546391833864950270959; 
            IC[273] = 15107056610307404189620484608843716471823549527947540933354942546117566089906;                                 
        
            IC[274] = 17863480916666444706228426249224666332100289264795174558814964713986397196704; 
            IC[275] = 17643619436480646900662630425199727680938311995117467060777405637781587916417;                                 
        
            IC[276] = 20411754352733244376265424512181347111226655418544435751850944105285805161858; 
            IC[277] = 3416511167446850313541463945691637184698866591339570049812022031973929687682;                                 
        
            IC[278] = 2300195182658657283339610310695281624858086743955030811324269112503252165548; 
            IC[279] = 9355770698194004712038597405367502483588183184492105174438628256091727937084;                                 
        
            IC[280] = 5916325507223600327810700499397462596562580932281017075616739627090808356796; 
            IC[281] = 18592309737703595048185079735880558946283760987620429563443146971770704389818;                                 
        
            IC[282] = 879275275816419671294853081960927699474787085816849618294416213306869374205; 
            IC[283] = 1710196337195212071194110979649020479137595984117379051883917804462101336796;                                 
        
            IC[284] = 1428438969673891101572324589256036829825589493622954435664588911287124327732; 
            IC[285] = 13382514256005099737156647344557656219036709521694650464553952374099163616636;                                 
        
            IC[286] = 17265165620689624142700427470973798438017223062589315109449523557762027391581; 
            IC[287] = 7824829049994883713266457756093312670763531405645132473362933943396629062121;                                 
        
            IC[288] = 15632336771673389779456170331103907401212051743257872212281996455550713464262; 
            IC[289] = 16530069229552409412525505459491906942883583308793272379320013992204706228791;                                 
        
            IC[290] = 20230993416438478781070465818977651227839612304719787988502861261034142820511; 
            IC[291] = 13062867872526255371196682411180760778657978890609976733112273988397341422648;                                 
        
            IC[292] = 2413981815092209801441839517093466697176340514293145277100759716610010062982; 
            IC[293] = 8070543498723611944032466923036618599579912098739645596700879487023486256662;                                 
        
            IC[294] = 6463553584944814093034528551951966641224374812253715907296575365434070492550; 
            IC[295] = 18969929515920529180423539494742809901820726361615037337013480101719930704604;                                 
        
            IC[296] = 1669525753184881165957049177681638659826037719339303268249169658573619024480; 
            IC[297] = 12778321923519881605095644021089445678775292449802986039540250527456126624761;                                 
        
            IC[298] = 18516025390255087017517665985055213808944518760966840704328805077525443274132; 
            IC[299] = 19076840853064007855610307303159477571799732966721115085769279939931515474459;                                 
        
            IC[300] = 1967633471262843277240771188560115624898718670261572513658485637777691213340; 
            IC[301] = 14944342548808827039518200693700793489978436554205487389516503030182031307120;                                 
        
            IC[302] = 14558328164176343710000680772810240953037014761636281492145310587413466941751; 
            IC[303] = 3400059981256736154612285327108289110644076999271414473938016780810509351609;                                 
        
            IC[304] = 16798496969859014714178152144185737783486095543522076871380134064983060942189; 
            IC[305] = 7699214112744374404400739187556729188637128913410795966485870856613450773230;                                 
        
            IC[306] = 12383867185654951892541683492526834087203672972950378476496525637851276960496; 
            IC[307] = 17106489494159784465842785137592757602612114397065668142707060592577338681691;                                 
        
            IC[308] = 2213884247393176885133767919613083460164470460475959981434540023739818958891; 
            IC[309] = 6725088344889810977263851194356275534461197044167019904388431683047828543826;                                 
        
            IC[310] = 13736664690320341081217423283999904443125071551699898391721187037383178411112; 
            IC[311] = 4663785800251850302847663484453087170672823881571580112187942946969848839139;                                 
        
            IC[312] = 4912058394732994689077921321885768092472068714730298506001349654985178439870; 
            IC[313] = 3266951215019076271375796676506399905007063839881427514875252428365542601374;                                 
        
            IC[314] = 20748820124559996572453080021961295117453898745550757849181055667242674377094; 
            IC[315] = 6773208428732345083839551784790867258421575941687016040223398823159799471284;                                 
        
            IC[316] = 2698074238315569848236695650435661911153878528200176283467388350817727676572; 
            IC[317] = 16912855486138315747713802746587145623308377348030176822765973280696676670217;                                 
        
            IC[318] = 14049503125877831012467101426451692155002983835884808635168997374504124060222; 
            IC[319] = 19298456772793570148248175838307541198502326934446124634261332434810489661267;                                 
        
            IC[320] = 14650167143744422035599347455192168980362773324703182570422943503398177758769; 
            IC[321] = 16442796186903487632727731043384975665605517797952653282353920879527507981108;                                 
        
            IC[322] = 19310421216873918171466452979045265396223992853368360110920452010467929020438; 
            IC[323] = 4427510011162953523301624677607051549334885046812669721233907221919432233296;                                 
        
            IC[324] = 8657222233973119594650810490126425563763256144319364550871883724176644689727; 
            IC[325] = 16576997128871538298105526484631865917486490343374643957478934180950680422926;                                 
        
            IC[326] = 19234896114807091906038618982081949215456534833575952219611772723943328378378; 
            IC[327] = 16050857951063582595426770920974044493518022043316527929605462221339470695543;                                 
        
            IC[328] = 21400025868595708005295572197390298569967262263911384383794356515363237501018; 
            IC[329] = 4410077959472781152714686887626595456367087418017989386659156347384586491646;                                 
        
            IC[330] = 21654776558063156965678124595137552378311839603076448384800285166065660425787; 
            IC[331] = 3647286340365904469989257309319920371161096949121006765291685367673179537242;                                 
        
            IC[332] = 10449226563715025933240739392440689031191597401382826353492020316782017374018; 
            IC[333] = 21031843994837134651250954621445838067818438274745855133483594115294765232377;                                 
        
            IC[334] = 7843713131164177832309602865900248849997637644182112853039237972731266667848; 
            IC[335] = 185617727597854080068916442599414288295218702364950554407552204180649250169;                                 
        
            IC[336] = 16652421657705569080154299357923945386609353094348134867954205626699151291943; 
            IC[337] = 11663709095743740148573618011743863764787329221819178031844461432152825533289;                                 
        
            IC[338] = 11641108601992655674104419568487966733560122765656894822293408626429655570018; 
            IC[339] = 2420668786613768814798288358506315916072054299098800556204932755090720681214;                                 
        
            IC[340] = 11055706107422247338337590053232854383947926804278060820925213664685386311583; 
            IC[341] = 8819138211511305576874556747013064314367662740650139079620536399882355339974;                                 
        
            IC[342] = 11666868854736579725419078300080760387998044838417516022643649538206804370181; 
            IC[343] = 15496237875424840832239703913119089981672889672765635899409712615487058126498;                                 
        
            IC[344] = 13285098215289986392895293184219541994016658474663940594764140548880007948268; 
            IC[345] = 14202603600468148604207893523415834018123155182283506291691151012723627204168;                                 
        
            IC[346] = 2313639052037251027774017269596156433748171218335455872858539157273801100884; 
            IC[347] = 20664064767867315342228576621419570260799435384726816182155103925694111114511;                                 
        
            IC[348] = 13278909141598923613502114585705288164958281113846667777152326359681936712524; 
            IC[349] = 5763505237027657508687118373892150744101538569403379461204783563657456379731;                                 
        
            IC[350] = 4519679008803496501139384752733486732001183853332467940061355194392854019765; 
            IC[351] = 16415575860049476761776721670241108265594339148990847347829465549255754702130;                                 
        
            IC[352] = 7348960593631390486891682560399782914544789901984694594755482515721810900793; 
            IC[353] = 9672456891255059056953192317784757719856756761608328854513636859502787335069;                                 
        
            IC[354] = 9682875599895841752162741437048688640724705591765663905431692870626472631809; 
            IC[355] = 16496391455497760471144769346400141592338604341685202200418070475807317973032;                                 
        
            IC[356] = 1430550415395600415262563299453265427296558499648216346939428070634760885002; 
            IC[357] = 3433225834409260794152470910689381021888918745902476230924392473415986228015;                                 
        
            IC[358] = 7951397660416563983757596531008335403745204720652890378856595843581160127851; 
            IC[359] = 9557152586682107552182218222677692012735041721992312551357633214468805660620;                                 
        
            IC[360] = 15711138803509291444333269965422009259568466948492020504981194762668098705966; 
            IC[361] = 1307303275903040365985575786807600132458662187567928377774682677800382545303;                                 
        
            IC[362] = 179830743134616633747111404981996799267420980887398099782821666163284779612; 
            IC[363] = 2534057593458955602803293365601880643846756097450580339722357680538252837689;                                 
        
            IC[364] = 21854208010501819092940066306376170990391167575394924390808982426765108278600; 
            IC[365] = 12801679266252696572141091481815560371142223062915358594241530522651284126610;                                 
        
            IC[366] = 4706774802516712465718858730334460204532881882125378723452652965352148270919; 
            IC[367] = 4583010500206873791352012056930494538626284962292612711357951718594150478351;                                 
        
            IC[368] = 13000678216709932289840211239090770420627960874066484371771953992084223702149; 
            IC[369] = 11428605797905908086064651808466778445530444330541336640331145432299021837189;                                 
        
            IC[370] = 11734685203974370252147182644312733817526687335791976397140055346017397029972; 
            IC[371] = 17886800986240386056615177684894266784526006788055208193095772011175913686604;                                 
        
            IC[372] = 7457207370605071172781987457403867404395451759855961901525118523568023667715; 
            IC[373] = 16080664887944686067580329163019968174718693952027239112962123642157037342914;                                 
        
            IC[374] = 10438799405685304375097153975994253471728505633536326362057326868427541850497; 
            IC[375] = 15120365957823130133919121587713062356288922475572642511624812298908534151849;                                 
        
            IC[376] = 19465729641684047512381377125150666654164643195772559187227067972141324475384; 
            IC[377] = 6067398693118147205412230263441262988375838609789681431821062160656921065273;                                 
        
            IC[378] = 13959457748019400936723068335367512578234974540790011920402159443789846023757; 
            IC[379] = 19481845286073893608153295654707665816684620666668049270354957670620654876291;                                 
        
            IC[380] = 13920031783658781094749017898963180171317851242479716288521548241800375999478; 
            IC[381] = 17269283752252549200574091196150265656316189683697753888501089033038487808192;                                 
        
            IC[382] = 1032510111474444856259819435456146932326824842605623071761516254991383645641; 
            IC[383] = 10245407739789971353277711545691454268679271652734386038809955264293245207594;                                 
        
            IC[384] = 18437834887634946088503139820542035513447673350454881543924168297500607210548; 
            IC[385] = 12743835225764684893491370634739633133998306603736979634683827266169074039668;                                 
        
            IC[386] = 10312224419424426846882428499406097694753791427359516114338249152628573608724; 
            IC[387] = 16837510930535314100168835453361186441773433271716172587917439034427251866709;                                 
        
            IC[388] = 2489675946184855157159425403966142066742622618794588851202471951124412973098; 
            IC[389] = 9053848475881498396179043180979556743113365423805863255725950281591206051980;                                 
        
            IC[390] = 3965843212475247048509728326177616192865881040283454082374270244117009791647; 
            IC[391] = 18540038078665838900053719942571324716310307411065161959934425257589840486114;                                 
        
            IC[392] = 13848651413483759569856184094003595058091256770292185833361038554298321128056; 
            IC[393] = 8043681271203174962170171371336743194042753365475521197193558527012224898636;                                 
        
            IC[394] = 12487184560197172356691406799799819349975090301239179782509930055584429437168; 
            IC[395] = 5874714383289453304842536828017596333536236447540359906979139144262856373444;                                 
        
            IC[396] = 6246698947070061065119261907320253839048636758487882984603507214511392308453; 
            IC[397] = 20420350657493357475110585289565909106567606076290271717600482528379070887958;                                 
        
            IC[398] = 3720215257346748529155751785780432250643210271725013666701184285674464985435; 
            IC[399] = 3547404535917760535922650074892430850200057411201392953298047599730753123555;                                 
        
            IC[400] = 7258965234306503555866635457587468586731323262276667788568113580874360025673; 
            IC[401] = 11976201293079540598379414986455484409060427316737262733306073946720367864345;                                 
        
            IC[402] = 8185934028523630075267966122965534616656968079713074283167191250460474956449; 
            IC[403] = 1732710417405639791272368881576314203075500658344693480886444230061539186865;                                 
        
            IC[404] = 6238613617623196760936939577527820542439290786229173491346987488820114044444; 
            IC[405] = 4255851287580372547187571873055555537345551494426698784743664355017823544424;                                 
        
            IC[406] = 13642808522986174912759025586155533881144806377914675669038029081767116866431; 
            IC[407] = 12300068076735354024430767663174021532055811523043906235639160158970484812065;                                 
        
            IC[408] = 2139772499819537525156902184914385765701144109776234136455068449022484079172; 
            IC[409] = 12169488798808539184346468641351345901728388077632794150256804558502985160692;                                 
        
            IC[410] = 18190886986560882258960616861358096850851712704195166533038661477596979427586; 
            IC[411] = 12836746083051903357638201590002222635178041792512697143294263638918561945365;                                 
        
            IC[412] = 20912578180904246026315180813345864411052259826913281681016087056671239246561; 
            IC[413] = 11452785094827393450578111986714624294884918491847852308003767676277380583866;                                 
        
            IC[414] = 3993422889130577194248026287526502967161963013637668415400832383552491262129; 
            IC[415] = 9178144114214620686265576669785298821787411435841135109265639551485090359619;                                 
        
            IC[416] = 1232454435311925367681757984247671222147181586628765901344321258232914695132; 
            IC[417] = 5994973446694032965293574146953987724688386974284447272870039523184724471325;                                 
        
            IC[418] = 1786398401384675817628001403153264933203328068079405697495383341622758404121; 
            IC[419] = 3748227875651970687988905836314437059539896127406230408507463544784275497023;                                 
        
            IC[420] = 15426674291809696544890111523817193924976051527359854391605705422798972750830; 
            IC[421] = 12686199380885426350210465937841086078250950703432850897334773221433243672122;                                 
        
            IC[422] = 16975708931514577802379039496820232774848321651191204359217538812911094702041; 
            IC[423] = 5976234422108960272052592584407526653330032941157286916737319321618241496791;                                 
        
            IC[424] = 15858114233461132613463852324663581124486892929991429242640309722811405186722; 
            IC[425] = 15037143001826970541594559508107893901188120773284249177347217346500153249754;                                 
        
            IC[426] = 1586836895590634595528818918361166595229470786091861691659844935993810293667; 
            IC[427] = 3613922318299337006677920082956972393554886142111410424989693711964374010694;                                 
        
            IC[428] = 11415466553762183846615109305628854141452918616289847428919510151403421185066; 
            IC[429] = 6380013751581606577363587127004159422396608758941439070454655591028990806112;                                 
        
            IC[430] = 2581464257382816503068780109813845832433789244156127405735740086406738765750; 
            IC[431] = 12380271940102558751677957397598154640022962007568963021022912888135998972788;                                 
        
            IC[432] = 17925021025334334533553476445792561671764037871025536810507873272366858031961; 
            IC[433] = 17862694750631634100245737622086778983341596373262401482962302775645676492356;                                 
        
            IC[434] = 3468968911752646712937054166254213348163822450254014727734513859797004099028; 
            IC[435] = 2359864777850908349610416414035213998966784239997537214938961265191516861444;                                 
        
            IC[436] = 262102631968325557425161148242041002126501385211195515613495790717748546073; 
            IC[437] = 15816477489680367706100693230221831915774992504605502866153120925193778673223;                                 
        
            IC[438] = 6243382279525131230938681548626940136952414495812622664786862655417554322915; 
            IC[439] = 16625710257063590315971452152477002337978759613707278707097885829935215518103;                                 
        
            IC[440] = 9251706708454413828184669048134709302468566927138150736915519139145177227496; 
            IC[441] = 16175119745049712143946328956363737870251206131009741578530305738728343400694;                                 
        
            IC[442] = 2766422605591306050489923975001532593622884188256442381484565034435438481143; 
            IC[443] = 1470057439599808824361712620504705675861967710075207285093212319645457713084;                                 
        
            IC[444] = 19079113602199817383476664341366690275124982539531622302808348552611273095653; 
            IC[445] = 20348816099628742445759224658956608138386781362821614644434826023968368737025;                                 
        
            IC[446] = 6149324383445794316879297237172411321083921063044590785401684045006001529486; 
            IC[447] = 3683733523885701894272129735963569334426657327711467196186516386914044171249;                                 
        
            IC[448] = 10079120351758124442384949565093163486550538900467072268465626373850067678993; 
            IC[449] = 21304950788666720529693336253146736281338253793202258650255509897975835622784;                                 
        
            IC[450] = 8589165556158360380391142207040916723902483940407184285698750325846011470671; 
            IC[451] = 16355974559256923350093721135915931221844294329937309696235730422154239369930;                                 
        
            IC[452] = 7112932946896512846914332212544068426946411205637366721114808334348031932998; 
            IC[453] = 15714315940625716248840888958493397723162545593280235517145351525369379564141;                                 
        
            IC[454] = 16635960426582449863688904977457819749867961055891903578149899832544778248129; 
            IC[455] = 9883466609212394546713281077060021910071640884453865977540083194159344543849;                                 
        
            IC[456] = 21073412655400316463323434948430326054145948054637664106407530567730278957447; 
            IC[457] = 10378286274198740563971471426607025470312664500735716068740167565825953746680;                                 
        
            IC[458] = 18764304164308181824919578896796582356555101212321931069467468806919210692405; 
            IC[459] = 3438194580351244479101541303680489996982211267575699951573453834097347837063;                                 
        
            IC[460] = 12875753039590931501759556806961129359361783867701641241951144005818620218292; 
            IC[461] = 6370196848382550094736091182967910761502201653326832086926081907336878577847;                                 
        
            IC[462] = 20798768452110897950120880922048012557837649949321952672325873462833009792389; 
            IC[463] = 3572010363155678093171096695764421075631492615195540045172823439604298174517;                                 
        
            IC[464] = 6410841850308635115131824388807916630882656250945455346232862129592066030013; 
            IC[465] = 3689276999192188136276085053688742528334814193343855550424165294379852833175;                                 
        
            IC[466] = 14074061799881329586004625644166583865313365182060923930785548620696646715015; 
            IC[467] = 17617597044325301039245470666691750751349569467078543838396993706203417258187;                                 
        
            IC[468] = 6549205458119698957357297232589720183815153678548353088097181484727053153584; 
            IC[469] = 9439177789736122176215583608971087748334742839417609632216437992747648156692;                                 
        
            IC[470] = 9092559416790764046035029183834883168830778605293874493329177119908949078361; 
            IC[471] = 9656041969891782276779252944548004102952304859390049752288943447551634118149;                                 
        
            IC[472] = 13096905102058589738597239898028485089737337097169987727595443795578308668560; 
            IC[473] = 19981624023381492160546972673186350675809818002761650299644543345697204737237;                                 
        
            IC[474] = 2094485476671557083734964636829711687833333709825849904186299623918820166004; 
            IC[475] = 3204821407650528587533467698446509831919483962353366117083769221637587556671;                                 
        
            IC[476] = 1871795735851012113999927417112739737896997503741816828468556200184000547102; 
            IC[477] = 4518828408343538258111648725105250026908415683184494728412192262290987142592;                                 
        
            IC[478] = 7031067096974717939736972191862279677520344192543550365092824870844891234481; 
            IC[479] = 15978924829947288818912943651954107838416257693059870174958689648963376886185;                                 
        
            IC[480] = 19200412392837764521433387046231076567135918800485375929786704296557371269865; 
            IC[481] = 4530791407022118265654187076679291063922525029637004353098375841984599054250;                                 
        
            IC[482] = 16143320305824037856709246466452170121470751259309392234199416766006198561984; 
            IC[483] = 520455081021484382304179746626846379540213867200385555357442525292600382112;                                 
        
            IC[484] = 820942368174871285346341187967717716514560605076989777777945211895146292962; 
            IC[485] = 14741256573289385082453526753314884393330761224307239514151741881008961416247;                                 
        
            IC[486] = 4420882231410483392057910085003161685362834182459788919829936528982968419682; 
            IC[487] = 2740948086397430314020812879408031540588714578702393533614108503221043879986;                                 
        
            IC[488] = 9674803507040875720322480243765552721018066701860153341774233503845356516844; 
            IC[489] = 17733897616510947701609742609858546785549137223909097075855664354947199591809;                                 
        
            IC[490] = 6807652761982230824947149251558421311544106517702368487570864512904767952096; 
            IC[491] = 3442243636779335053149520814774582415722769981345082248017263096544050407401;                                 
        
            IC[492] = 5168577327248310590764538323118951408861602401111485914198407416728201481966; 
            IC[493] = 455598567022667046800780432253695664261758912692481106922039010044345309114;                                 
        
            IC[494] = 17021701434343411187647820937121383710983984512569137728642860895331157180507; 
            IC[495] = 9730780872402804841678495398348836842636748014829151531961661174791811692011;                                 
        
            IC[496] = 18305365191029035487228988529772918999672148822844054833125279086194472511296; 
            IC[497] = 19405064551328598644175616242895442282821854367449845677547655882984954042107;                                 
        
            IC[498] = 5375506283763330838893984328276903327100218201256561110601204877622861156969; 
            IC[499] = 3901856924906135875340511585957039354000602187044461004162347123274799236085;                                 
        
            IC[500] = 14328780268150710661585373975208270065782067109217670221139678801551256104395; 
            IC[501] = 10638753221362899556979679141384880687294925390206131159509419441021691021177;                                 
        
            IC[502] = 21317603240746082914213507476515103849215028241506657069801583795172069137489; 
            IC[503] = 11066723030358336512168820028550213382786702839358911556426271824043237612660;                                 
        
            IC[504] = 17135665155643653866331815306172475761519228045659725442887140741346648472294; 
            IC[505] = 2496866138872213694731788992800910654945903150507701290885843582187572496012;                                 
        
            IC[506] = 11615949703491810308584799106433019906937391108774962995399246431033372901744; 
            IC[507] = 18809538591833886492324506626036732237609713277926692157492697155163792862668;                                 
        
            IC[508] = 15878856020986053883222976893589863552177571710727669248458469282379037380369; 
            IC[509] = 4985238845999603448338573712842410945124566200345055508693542022225192266187;                                 
        
            IC[510] = 16532598669209367168258132446178825167497801315413250534350181123473469766556; 
            IC[511] = 9783027646299841854774351473131932315480784364042884513416660802060603410270;                                 
        
            IC[512] = 5891023442783836248011170721561695824404122836771967847785073032690066484845; 
            IC[513] = 16306141562739674723857299624399343997715384077530220374034455041492160179251;                                 
        
            IC[514] = 15523848230259791191667650179076338159959002766562474131589040305820139395031; 
            IC[515] = 21401292697133618202423456424870696177707159424690934005808851729113682151431;                                 
        
            IC[516] = 9608414622797263845870282146533998685546349446142951785620273261038691758751; 
            IC[517] = 17169333592783971551560228255753362121684415984659950973838416132835914981759;                                 
        
            IC[518] = 14742508864333007452080943244113349921344096429374278840286377377600816877308; 
            IC[519] = 5434170778455170238981150494983207746896027250457327901136923407350904722395;                                 
        
            IC[520] = 15316967408895304449881424659801866660125261413810451129934324340287288412557; 
            IC[521] = 3726280678419558763631531822274362065903668850841309166650956625729171075816;                                 
        
            IC[522] = 16140317907118940520899391026316428520419075795761108294004916863409430035523; 
            IC[523] = 21240593942783001231700828606913569055203633243280824954915147936133680570522;                                 
        
            IC[524] = 526544593950139243816586132992630780996980343059830959609017849036305329614; 
            IC[525] = 21195281639557345201640774574174135305968661497133532384150544937411970119164;                                 
        
            IC[526] = 16657283143700311955184280165623397695904065927050690925123649008114573926272; 
            IC[527] = 110470716491159788130134557438897023853772658172536262706547349447298783722;                                 
        
            IC[528] = 2894233184130111129319315204138003218279844457495139797273321238374966129562; 
            IC[529] = 14387032718209181148962078259060233327799572757487510681767861196631760281445;                                 
        
            IC[530] = 20842896160355223523999658878942620710506025218256690898280887584706462651598; 
            IC[531] = 12829791823403433977825304424822194607285316145657214594246738962448229861205;                                 
        
            IC[532] = 13969261103484322479504625485450072913051296160979402415572447844055429477645; 
            IC[533] = 17219668294790063561185230834160600622302794012144296728970768663974718410809;                                 
        
            IC[534] = 5115053418697569185012353893822425123902519598824266734184905088376736016788; 
            IC[535] = 21784301948754150734615566264142287761616088079722912554097610923430637778656;                                 
        
            IC[536] = 728256522249676367787995464723446706866310032561707438645071689323688978785; 
            IC[537] = 7870752636971359576856966491967175400431340973115204126884372967793226350029;                                 
        
            IC[538] = 18888610752385695982093976723142313433659643975443959376732205794398502562938; 
            IC[539] = 13487423761720426901215975610601120558674727740748924087767255678735868311760;                                 
        
            IC[540] = 812205854481918256468671817418990073166268775790776421709037123570311254530; 
            IC[541] = 5523165441194078174894721940501901638479705170055192184308815269035505179010;                                 
        
            IC[542] = 16493843220629996682069659886452611406954101951903259512026576683660345343292; 
            IC[543] = 566781194842138963262608742772550633731017134470938264182457883047351970023;                                 
        
            IC[544] = 12703146828823141154033930197072958528796797762510415556355053615113330936058; 
            IC[545] = 7480089243105113397288530313622604165393057716692182974234572458979834937587;                                 
        
            IC[546] = 11331431238257664621248406675813571476021674883177083616173031014666341815930; 
            IC[547] = 19370854846109753130298323927529746388993116390470942723009587550891442053932;                                 
        
            IC[548] = 16460976890643338642748016215286796315133140628729124566678657803584101782852; 
            IC[549] = 3049071109013438661433199302044808951460872939804460335860273961789871989312;                                 
        
            IC[550] = 4084526784613259208768537349324258625120171761899781944878012545181973760756; 
            IC[551] = 5608032055740701568013585881852577000456395571554842234216275358849526520532;                                 
        
            IC[552] = 8806081607456759024270554684307825449253124960343015422296651057463243612087; 
            IC[553] = 12690419868307217340841273947052581892174332116556594659423437868827377912589;                                 
        
            IC[554] = 16708944602438525532465104586460894699792273014502722625116990025597518707744; 
            IC[555] = 9587234636063222738448703120460668075212522907145118811806679065855377373333;                                 
        
            IC[556] = 8224083945182510252523084475578881612032113696280697256652953785226120313478; 
            IC[557] = 304691586633474357606614856840740877686763053019956398719074281650552788594;                                 
        
            IC[558] = 10750560899376143535669554568670603813706961488656043516106986389182255752839; 
            IC[559] = 15806772614452881081669912097506674272192651256799423049575241925041826039504;                                 
        
            IC[560] = 6903606151807999627615990005883913820756011407671848297037642867617158463639; 
            IC[561] = 3203890809970678678250755973584129837763446481009827185644996064090639388360;                                 
        
            IC[562] = 14472609533234974311477157102054740304482774241886616400725470687964477324426; 
            IC[563] = 3776119096042735235550645865387097124584573413293125870324883982018971583377;                                 
        
            IC[564] = 8540033291267085541043499674714458222432566160307388149811155983664134920228; 
            IC[565] = 21834144698675214508000429405749474161660970531167560728981611381502789707006;                                 
        
            IC[566] = 16317203634932423450721624091808405072963834206116913454955836934546412037251; 
            IC[567] = 4821413891380654493801890493050680075634745174065341110162295952820223381645;                                 
        
            IC[568] = 933545608021087038166783112835328932223898142368153655081228904445546353139; 
            IC[569] = 11907986710760520569911120158971312172606898502879243716829228922667383467087;                                 
        
            IC[570] = 3635236602417274818264022003887263724075481687357164795675443457878840975125; 
            IC[571] = 6438137679849061769578654607310295081530732522666704047980027312682732754915;                                 
        
            IC[572] = 16824406550281131179157259593263782830323609915078692676371700019071598619686; 
            IC[573] = 19518130214959418222681890500099933410357546797210168383869362879139555734493;                                 
        
            IC[574] = 6874084573954867993101047506094663110310511640309303896018291180253500609374; 
            IC[575] = 11174657245117015755311042831373565823321721785336331283309735148728177614237;                                 
        
            IC[576] = 20721616984458254390804389861453775086340238492846308345783089857862187587502; 
            IC[577] = 15216949719205848516988661095020463097856044372116456690698675482658345385877;                                 
        
            IC[578] = 12447601181474174390012619631838137075793444733062289716516067987649967668032; 
            IC[579] = 3431407663860923505817310848691050885610197901119859529174645400304313922315;                                 
        
            IC[580] = 1018431032182519642694981019987273659825150725507980183696879876241161258206; 
            IC[581] = 1745589372275738391072805518830921366691491301154464133024272105460070143452;                                 
        
            IC[582] = 9459521235322285453549182182422120666098083567520280927973194957685847209176; 
            IC[583] = 5388133807545591276055492344128869228474518102255257398007290563949311962151;                                 
        
            IC[584] = 8609288910018091263102787572883478421526993669063594512871038309155782660763; 
            IC[585] = 7595442193809850397642821884349082102094001920477517580034502214741298159541;                                 
        
            IC[586] = 12733091951570145396570569916392660940863354136875032518062619392342105631175; 
            IC[587] = 16017632357210683163567667680261678368609550493677083689022600365651176114862;                                 
           
            
        return IC;
        
    }
}


// File contracts/RevealVerifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
// 2022 hellsegga
//      compatibility with newer solidity version
//      gas optimization
//
pragma solidity ^0.8.0;


contract RevealVerifier {
    using Pairing for *;
    address public VKStore;
    constructor(address addr) {
        VKStore = addr;
    }
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        //Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [7097300879054166716055313759130380865711283338477787465191462477077205389753,
             7866334169760910528995916305968143354836260704522459552724323544370340705674],
            [364452281174209557735571930469749548733765047770352954344227176359158182713,
             20506793826798048908578502105076444809849153868799340282859422623583425596580]
        );
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] calldata a,
            uint[4] calldata b,
            uint[2] calldata c,
            uint[293] calldata input
        ) external view returns (bool r) {
       
        // Negate proofA first
        Pairing.G1Point memory proofA;
        if (a[0] == 0 && a[1] == 0) {
            proofA = Pairing.G1Point(0, 0);
        } else {
            proofA = Pairing.G1Point(a[0], Pairing.PRIME_Q - (a[1] % Pairing.PRIME_Q));
        }
        Pairing.G2Point memory proofB = Pairing.G2Point([b[0], b[1]], [b[2], b[3]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(c[0], c[1]);
        
        VerifyingKey memory vk = verifyingKey();
        uint256 [588] memory vkIC = RevealVKStore(VKStore).verifyingKey();
        require( (input.length + 1) * 2 == vkIC.length,"verifier-bad-input");
        
        uint256[3] memory ip3;
        uint256[4] memory ip4;
        bool success;

        for (uint i = 0; i < input.length; i++) {
            require(input[i] < Pairing.SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            
            ip3[0] = vkIC[(i + 1)*2];
            ip3[1] = vkIC[(i + 1)*2+1];
            ip3[2] = input[i];

            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := staticcall(sub(gas(), 2000), 7, ip3, 0x80, add(ip4, 0x40), 0x60)
                // Use "invalid" to make gas estimation work
                switch success
                case 0 {
                    invalid()
                }
            }

            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := staticcall(sub(gas(), 2000), 6, ip4, 0xc0, add(ip4, 0), 0x60)
                // Use "invalid" to make gas estimation work
                switch success
                case 0 {
                    invalid()
                }
            }
        }

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x;

        ip4[2] = vkIC[0];
        ip4[3] = vkIC[1];
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, ip4, 0xc0, vk_x, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
            invalid()
            }
        }
        
        bool result = Pairing.pairing(
            proofA, proofB,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proofC, vk.delta2
        );

        return result;
    }
}


// File contracts/Base64.sol


pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


// File contracts/EBMP.sol

pragma solidity ^0.8.0;

library EBMP {
    function uint32ToLittleEndian(uint32 a) internal pure returns (uint32) {
        unchecked {
            uint32 b1 = (a >> 24) & 255;
            uint32 b2 = (a >> 16) & 255;
            uint32 b3 = (a >> 8) & 255;
            uint32 b4 = a & 255;
            return uint32(b1 | (b2 << 8) | (b3 << 16) | (b4 << 24));
        }
    }

    // TODO: make this work with actual width/height non-divisible by 4
    function encodeBMP(
        uint8[] memory image,
        uint32 width,
        uint32 height,
        uint32 channels
    ) internal pure returns (string memory) {
        bytes memory BITMAPFILEHEADER =
            abi.encodePacked(
                string("BM"), // "BM" file identifier
                uint32(
                    uint32ToLittleEndian(14 + 40 + width * height * channels)
                ), // the size of the BMP file in bytes
                uint16(0), // Reserved; actual value depends on the application that creates the image, if created manually can be 0
                uint16(0), // Reserved; actual value depends on the application that creates the image, if created manually can be 0
                uint32(uint32ToLittleEndian(14 + 40)) // The offset, i.e. starting address, of the byte where the bitmap image data (pixel array) can be found.
            ); // total 2 + 4 + 2 + 2 + 4 = 14 bytes long
        bytes memory BITMAPINFO =
            abi.encodePacked(
                uint32(0x28000000), // the size of this header, in bytes (40)
                uint32(uint32ToLittleEndian(width)), // the bitmap width in pixels (signed integer)
                uint32(uint32ToLittleEndian(height)), // the bitmap height in pixels (signed integer)
                uint16(0x0100), // the number of color planes (must be 1)
                uint16(0x1800), // the number of bits per pixel, which is the color depth of the image. Typical values are 1, 4, 8, 16, 24 and 32
                uint32(0x00000000), // the compression method being used. See https://en.wikipedia.org/wiki/BMP_file_format for a table of available values
                uint32(uint32ToLittleEndian(width * height * channels)), // the image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps
                uint32(0xc30e0000), // the horizontal resolution of the image. (pixel per metre, signed integer) this is magic number from pillow
                uint32(0xc30e0000), // the vertical resolution of the image, also magic number from pillow
                uint32(0), // the number of colors in the color palette, or 0 to default to 2n
                uint32(0) // the number of important colors used, or 0 when every color is important; generally ignored
            ); // total 40 bytes long
        bytes memory data = new bytes(width * height * channels); // this is because line size have to be padded to 4 bytes
        for (uint256 r = 0; r < height; r++) {
            for (uint256 c = 0; c < width; c++) {
                for (uint256 color = 0; color < channels; color++) {
                    data[(r * width + c) * channels + color] = bytes1(
                        image[((height - 1 - r) * width + c) * channels + color]
                    );
                }
            }
        }
        string memory encoded =
            Base64.encode(
                abi.encodePacked(
                    BITMAPFILEHEADER,
                    BITMAPINFO,
                    data
                )
            );
        return encoded;
    }

}


// File contracts/055.sol



pragma solidity ^0.8.0;








struct ZeroKnowledgePrivateData {
    uint256[2] a;
    uint256[4] b;
    uint256[2] c;
}

struct MintData {
    // Zero Knowledge Proof parameter for private data
    ZeroKnowledgePrivateData privateData;
    // Token's public data, as specified per mint circuit
    uint256[24] publicData;
}

struct RevealData {
    // Zero Knowledge Proof parameter for private data
    ZeroKnowledgePrivateData privateData;
    // Token's public data, as specified per reveal circuit
    uint256[293] publicData;
}

contract Artifact055 is Ownable, ERC721A, ReentrancyGuard {

    // Specify a start price
    uint256 public currentPrice;

    // zk-SNARK Verifier for mint proof
    address public immutable mintVerifier;

    // zk-SNARK Verifier for reveal proof
    address public immutable revealVerifier;

    // Mapping from tokenId to thumbnail image
    address[] private thumbnail;

    // Mapping from tokenId to original image, encrypted or not
    address[] private content;

    // Mapping from tokenId to the hash of owner and minter's pubKeys & content hash
    mapping(uint256 => bytes32) public pubKeyContentHash;

    // Is content hash unique
    mapping(uint256 => bool) private _contentHashes;

    // Whether the image represented by contentHash is encrypted on chain
    mapping(uint256 => bool) public encrypted;

    // Mapping from uniqueId (stored on backend) to tokenId
    mapping(uint256 => uint256) public uniqueIdMapping;


    // Event for backend to know that a new NFT is minted
    event Mint(
        address indexed creator,
        uint256 indexed uniqueId,
        uint256 indexed tokenId
    );

    event Revealed(
        uint256 indexed tokenId
    );

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 startPrice_,
        address mintVerifier_,
        address revealVerifier_
    ) ERC721A("055", "055", maxBatchSize_, collectionSize_) {
        currentPrice = startPrice_;
        mintVerifier = mintVerifier_;
        revealVerifier = revealVerifier_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function reveal(uint256 tokenId, RevealData calldata data)
        external
        callerIsUser
        nonReentrant
    {
        require(_exists(tokenId), "nonexistent token");

        bytes32 pkeychash = keccak256(
            abi.encodePacked(
                data.publicData[0],
                data.publicData[1],
                data.publicData[2],
                data.publicData[3],
                data.publicData[4]
            )
        );

        require(encrypted[tokenId], "token already revealed");
        require(ownershipOf(tokenId).addr == msg.sender, "caller not owner");
        require(
            pkeychash == pubKeyContentHash[tokenId],
            "public key hash does not match"
        );
        require(
            RevealVerifier(revealVerifier).verifyProof(
                data.privateData.a,
                data.privateData.b,
                data.privateData.c,
                data.publicData
            ),
            "invalid reveal proof"
        );

        uint256[288] memory contentData;
        for (uint256 i = 5; i < 5 + 288; i++) {
            contentData[i - 5] = data.publicData[i];
        }

        content[tokenId] = SSTORE2.write(abi.encodePacked(contentData));

        encrypted[tokenId] = false;
        emit Revealed(tokenId);
    }

    function checkMintProof(MintData calldata data)
        external
        view
        returns (bool)
    {
        return
            MintVerifier(mintVerifier).verifyProof(
                data.privateData.a,
                data.privateData.b,
                data.privateData.c,
                data.publicData
            );
    }

    function _mint(address creator, MintData calldata data) internal {
        address recipient = address(uint160(data.publicData[0]));
        uint256 contentHash = data.publicData[1];

        require(
            _contentHashes[contentHash] == false,
            "a token has already been created with this content hash"
        );
        require(
            MintVerifier(mintVerifier).verifyProof(
                data.privateData.a,
                data.privateData.b,
                data.privateData.c,
                data.publicData
            ),
            "invalid mint proof"
        );

        uint256 tokenId = currentIndex;
        _contentHashes[contentHash] = true;

        pubKeyContentHash[tokenId] = keccak256(
            abi.encodePacked(
                contentHash,
                data.publicData[4],
                data.publicData[5],
                data.publicData[2],
                data.publicData[3]
            )
        );

        uint256[18] memory thumbnailData;
        for (uint256 i = 6; i < 6 + 18; i++) {
            thumbnailData[i - 6] = data.publicData[i];
        }

        thumbnail.push(SSTORE2.write(abi.encodePacked(thumbnailData)));
        content.push(address(0));

        encrypted[tokenId] = true;

        // Server's public key is stored in publicData[4] and publicData[5]
        // The x-coord (publicData[4]) will be used as the uniqueId
        // Set the mapping between uniqueId and tokenId
        // Undefined mapping returns 0, which could be a problem
        uniqueIdMapping[tokenId] = data.publicData[4];

        _safeMint(recipient, 1);

        // Emit an event to let the backend know a NFT has been minted
        emit Mint(creator, data.publicData[4], tokenId);
    }

    function publicMint(MintData calldata data)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        require(msg.value >= currentPrice, "Need to send more ETH.");
        _mint(msg.sender, data);
        refundIfOver(currentPrice);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    string private header =
        '<svg image-rendering="pixelated" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" > <image width="100%" height="100%" xlink:href="data:image/bmp;base64,';
    string private footer = '" /> </svg>';

    function _renderThumbnail(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        bytes memory rawData = SSTORE2.read(thumbnail[tokenId]);
        uint8[] memory image = new uint8[](432);
        for (uint256 i = 0; i < 6; i++) {
            for (uint256 c = 0; c < 3; c++) {
                for (uint256 k = 0; k < 24; k++) {
                    image[(i * 24 + k) * 3 + (2 - c)] = uint8(
                        rawData[(i * 3 + c) * 32 + 31 - k]
                    );
                }
            }
        }
        string memory enc = EBMP.encodeBMP(image, 12, 12, 3);

        enc = string(abi.encodePacked(header, enc, footer));

        return enc;
    }

    function _renderOriginal(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        bytes memory rawData = SSTORE2.read(content[tokenId]);
        uint8[] memory image = new uint8[](6912);
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 48; j++) {
                for (uint256 c = 0; c < 3; c++) {
                    for (uint256 k = 0; k < 24; k++) {
                        image[((i * 24 + k) * 48 + j) * 3 + (2 - c)] = uint8(
                            rawData[((i * 48 + j) * 3 + c) * 32 + 31 - k]
                        );
                    }
                }
            }
        }
        string memory enc = EBMP.encodeBMP(image, 48, 48, 3);

        enc = string(abi.encodePacked(header, enc, footer));

        return enc;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory img;
        string memory encrypt;
        if (encrypted[tokenId]) {
            img = _renderThumbnail(tokenId);
            encrypt = "true";
        } else {
            img = _renderOriginal(tokenId);
            encrypt = "false";
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', Strings.toString(tokenId) ,'", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(img)), '", "uniqueId":"', Strings.toString(uniqueIdMapping[tokenId]),
                        '", "encrypted": ', encrypt ,
                        '}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

}


// File contracts/MintRegistry.sol



pragma solidity ^0.8.0;


contract MintRegistry is Ownable, ReentrancyGuard {

    mapping(uint256 => uint256[2]) public pubKeys;

    mapping(uint256 => address) public reservation;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}