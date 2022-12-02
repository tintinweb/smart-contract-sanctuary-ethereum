/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC721.sol";

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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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


/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/TemporaryToken/Temporary721Burnable.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
////import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
////import "@openzeppelin/contracts/utils/Address.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "@openzeppelin/contracts/utils/Strings.sol";
////import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error NonTransferable();
error NotAnAdmin();
error InvalidTokenId();
error TransferToNonERC721ReceiverImplementer();
error MintToZeroAddress();


/**
 Temporary non-transferable ERC721 token for ownership-checks.
*/
contract TmpERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    /// The name of this ERC-721 contract.
    string public name;

    /// The symbol associated with this ERC-721 contract.
    string public symbol;

    /**
      The metadata URI to which token IDs are appended for generating `tokenUri`
      results. The URI will always naively slap a decimal token ID to the end of
      this provided URI.
    */
    string public metadataUri;

    /// Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    /// Mapping owner address to token count
    mapping(address => uint256) private _balances;

    /// Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    /// Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /// A mapping to track administrative callers who have been set by the owner.
    mapping (address => bool) private administrators;

    /// Struct that contains info about staked asset.
    struct StakedAsset {
        address collection;
        uint256 tokenId;
    }

    /// Mapping that contains all staked assets for each address that are claimable.
    mapping (address => StakedAsset[]) public stakedAssets;

    /// Mapping that transform tmpTokenId to data about original asset 
    mapping (uint256 => StakedAsset) public stakedAsset;

    /**
        A modifier to see if a caller is an approved administrator.
    */
    modifier onlyAdmin () {
      if (_msgSender() != owner() && !administrators[_msgSender()]) {
        revert NotAnAdmin();
      }
      _;
    }

    /**
      Construct a new instance of this ERC-721 contract.

      @param _name The name to assign to this item collection contract.
      @param _symbol The ticker symbol of this item collection.
      @param _metadataURI The metadata URI to perform later token ID substitution
        with.
    */
    constructor(string memory _name, string memory _symbol, string memory _metadataURI) {
        name = _name;
        symbol = _symbol;
        metadataUri = _metadataURI;
    }

    /**
      Flag this contract as supporting the ERC-721 standard, the ERC-721 metadata
      extension, and the enumerable ERC-721 extension.
    
      @param interfaceId The identifier, as defined by ERC-165, of the contract
        interface to support.
    
      @return Whether or not the interface being tested is supported.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
      Retrieve the number of distinct token IDs held by `_owner`.

      @param owner The address to retrieve a count of held tokens for.

      @return The number of tokens held by `owner`.
    */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _balances[owner];
    }

    /**
      Return the address that holds a particular token ID.

      @param tokenId The token ID to check for the holding address of.

      @return The address that holds the token with ID of `id`.
    */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (!_exists(tokenId)) { revert InvalidTokenId(); }
        return owner;
    }

    /**
      Return the token URI of the token with the specified `_id`. The token URI is
      dynamically constructed from this contract's `metadataUri`.

      @param _id The ID of the token to retrive a metadata URI for.

      @return The metadata URI of the token with the ID of `_id`.
    */
    function tokenURI (
      uint256 _id
    ) external view virtual override returns (string memory) {
      if (!_exists(_id)) { revert InvalidTokenId(); }
      return bytes(metadataUri).length != 0
        ? IERC721Metadata(stakedAsset[_id].collection).tokenURI(_id) //string(abi.encodePacked(metadataUri, _id.toString()))
        : '';
    }

    /**
      Allow the owner of a particular token ID, or an approved operator of the
      owner, to set the approved address of a particular token ID.

      Since this token is non-transferable, function reverts in any cases.

      @param _approved The address being approved to transfer the token of ID `_id`.
      @param _id The token ID with its approved address being set to `_approved`.
    */
    function approve(address _approved, uint256 _id) public virtual override {
        revert NonTransferable();
    }

    /**
      Return the address approved to perform transfers on behalf of the owner of
      token `_id`. If no address is approved, this returns the zero address.

      @param _id The specific token ID to check for an approved address.

      @return The address that may operate on token `_id` on its owner's behalf.
    */
    function getApproved(uint256 _id) public view virtual override returns (address) {
        return _tokenApprovals[_id];
    }

    /**
      Enable or disable approval for a third party `_operator` address to manage
      all of the caller's tokens.

      Since this token is non-transferable, function reverts in any cases.

      @param _operator The address to grant management rights over all of the
        caller's tokens.
      @param _approved The status of the `_operator`'s approval for the caller.
    */
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        revert NonTransferable();
    }

    /**
      This function returns true if `_operator` is approved to transfer items
      owned by `_owner`.

      @param owner The owner of items to check for transfer ability.
      @param operator The potential transferrer of `_owner`'s items.

      @return Whether `_operator` may transfer items owned by `_owner`.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
      This function performs transfer of token ID `_id` from address `_from` to
      address `_to`.

      Since this token is non-transferable, function reverts in any cases.

      @param from The address to transfer the token from.
      @param to The address to transfer the token to.
      @param tokenId The ID of the token being transferred.
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert NonTransferable();
    }

    /**
      This function performs transfer of token ID `_id` from address `_from` to
      address `_to`. This function validates that the receiving address reports
      itself as being able to properly handle an ERC-721 token.

      Since this token is non-transferable, function reverts in any cases.

      @param from The address to transfer the token from.
      @param to The address to transfer the token to.
      @param tokenId The ID of the token being transferred.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
      This function performs transfer of token ID `_id` from address `_from` to
      address `_to`. This function validates that the receiving address reports
      itself as being able to properly handle an ERC-721 token. This variant also
      sends `_data` along with the transfer check.
      
      Since this token is non-transferable, function reverts in any cases.

      @param from The address to transfer the token from.
      @param to The address to transfer the token to.
      @param tokenId The ID of the token being transferred.
      @param data Optional data to send along with the transfer check.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        revert NonTransferable();
    }

    /**
      This function allows permissioned minters of this contract to mint tokens with certain id. 
      Any minted tokens are sent to the `to` address.

      @param to The recipient of the tokens being minted.
      @param tokenId Id of token that has to be minted.
      @param _collection Collection address of staked token.
      @param _stakedId Id of staked token.
     */
    function mint(address to, uint256 tokenId, address _collection, uint256 _stakedId) external onlyAdmin {
        _safeMint(to, tokenId);
        stakedAsset[tokenId] = StakedAsset({
            collection: _collection,
            tokenId: _stakedId
        });
        stakedAssets[to].push(StakedAsset({
            collection: _collection,
            tokenId: _stakedId
        }));
    }

    /**
      Allow the caller, either the owner of a token or an approved manager, to
      burn a specific token ID. In order for the token to be eligible for burning,
      transfer of the token must not be locked.

      @param tokenId The token ID to burn.
      @param _collection Collection address of staked token.
      @param _stakedId Id of staked token
    */
    function burn(uint256 tokenId, address _collection, uint256 _stakedId) external onlyAdmin {
        address owner = ownerOf(tokenId);
        uint256 arrayLength = stakedAssets[owner].length;
        for (uint256 i = 0; i < arrayLength; ) {
            if (stakedAssets[owner][i].tokenId == _stakedId) {
              if (stakedAssets[owner][i].collection == _collection) {
                if (i != arrayLength - 1) {
                    stakedAssets[owner][i] = stakedAssets[owner][arrayLength - 1];
                }
                break;
              }
            }
            unchecked {
                ++i;
            }
        }
        stakedAssets[owner].pop();
        _burn(tokenId);
    }

    /** Function that returns array of claimable tokens
        @param staker The address of the user at which we want to get tokens that are
        available for claiming.
        @return array of collection addresses and tokenIds that are claimable.
    */
    function claimableTokens(address staker) external view returns(StakedAsset[] memory) {
        return stakedAssets[staker];
    }

    /**
      This function allows the original owner of the contract to add or remove
      other addresses as administrators. Administrators may perform mints and burns.

      @param _newAdmin The new admin to update permissions for.
      @param _isAdmin Whether or not the new admin should be an admin.
    */
    function setAdmin (
      address _newAdmin,
      bool _isAdmin
    ) external onlyOwner {
      administrators[_newAdmin] = _isAdmin;
    }

    /**
      Allow the item collection owner to update the metadata URI of this
      collection.

      @param _uri The new URI to update to.
    */
    function setURI (
      string calldata _uri
    ) external virtual onlyOwner {
      metadataUri = _uri;
    }

    /**
      Return whether a particular token ID exists. A token exists if it has been
      minted but not burned.

      @param tokenId The ID of a specific token to check for existence.

      @return Whether or not the token of ID `_id` exists.
    */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
      This function allows permissioned minters of this contract to mint tokens with certain id. 
      Any minted tokens are sent to the `to` address. This function validates that the receiving 
      address reports itself as being able to properly handle an ERC-721 token.

      @param to The recipient of the tokens being minted.
      @param tokenId Id of token that has to be minted.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
      This function allows permissioned minters of this contract to mint tokens with certain id. 
      Any minted tokens are sent to the `to` address. This function validates that the receiving 
      address reports itself as being able to properly handle an ERC-721 token. This variant also
      sends `_data` along with the transfer check.

      @param to The recipient of the tokens being minted.
      @param tokenId Id of token that has to be minted.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if(!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
      This function allows permissioned minters of this contract to mint tokens with certain id. 
      Any minted tokens are sent to the `to` address.

      @param to The recipient of the tokens being minted.
      @param tokenId Id of token that has to be minted.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) { revert MintToZeroAddress(); }
        if (_exists(tokenId)) { revert InvalidTokenId();}

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
      Allow the caller, either the owner of a token or an approved manager, to
      burn a specific token ID. In order for the token to be eligible for burning,
      transfer of the token must not be locked.

      @param tokenId The token ID to burn.
    */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
      This is an private helper function used to, if the transfer destination is
      found to be a smart contract, check to see if that contract reports itself
      as safely handling ERC-721 tokens by returning the magical value from its
      `onERC721Received` function.

      @param from The address of the previous owner of token `_id`.
      @param to The destination address that will receive the token.
      @param tokenId The ID of the token being transferred.
      @param data Optional data to send along with the transfer check.

      @return Whether or not the destination contract reports itself as being able
        to handle ERC-721 tokens.
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
                    revert TransferToNonERC721ReceiverImplementer();
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
}