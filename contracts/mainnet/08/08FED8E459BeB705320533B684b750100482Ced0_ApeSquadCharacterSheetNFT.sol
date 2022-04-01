/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
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


// File contracts/ERC721Opt.sol



pragma solidity ^0.8.4;







error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintToDeadAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error TransferToDeadAddress();
error UnableGetTokenOwnerByIndex();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 1 (e.g. 1, 2, 3..).
 */
contract ERC721Opt is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    uint256 internal _nextTokenId = 1;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owners details
    // An empty struct value does not necessarily mean the token is unowned. See ownerOf implementation for details.
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to balances
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Address to use for burned accounting
    address constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as burned cannot be incremented
        // more than _nextTokenId - 1 times
        unchecked {
            return (_nextTokenId - 1) - balanceOf(DEAD_ADDR);    
        }
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
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        unchecked {
            for (uint256 curr = tokenId;; curr--) {
                owner = _owners[curr];
                if (owner != address(0)) {
                    return owner;
                }
            }
        }
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) revert ApprovalCallerNotOwnerNorApproved();

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
    }

    function _isApprovedOrOwner(address sender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);

        return (sender == owner ||
            getApproved(tokenId) == sender ||
            isApprovedForAll(owner, sender));
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId > 0 && tokenId < _nextTokenId && _owners[tokenId] != DEAD_ADDR;
    }
    
    function _mint(address to, uint256 quantity) internal virtual {
        _mint(to, quantity, '', false);
    }

    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal virtual {
        uint256 startTokenId = _nextTokenId;
        if (to == address(0)) revert MintToZeroAddress();
        if (to == DEAD_ADDR) revert MintToDeadAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance overflow if current value + quantity > 1.56e77 (2**256) - 1
        // updatedIndex overflows if _nextTokenId + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _balances[to] += quantity;

            _owners[startTokenId] = to;

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe) {
                    if (!_checkOnERC721Received(address(0), to, updatedIndex, _data)) revert TransferToNonERC721ReceiverImplementer();
                }

                updatedIndex++;
            }

            _nextTokenId = updatedIndex;
        }

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
        address owner = ownerOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == owner ||
            isApprovedForAll(owner, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (owner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();
        if (to == DEAD_ADDR) revert TransferToDeadAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, owner);

        // Underflow of the sender's balance is impossible because we check for
        // owner above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;

            _owners[tokenId] = to;

            // If the owner slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            
            uint256 nextTokenId = tokenId + 1;
            if (_owners[nextTokenId] == address(0)) {
                // This will suffice for checking _exists(nextTokenId), 
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _nextTokenId) {
                    _owners[nextTokenId] = owner;
                }
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
        address owner = ownerOf(tokenId);

        _beforeTokenTransfers(owner, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, owner);

        // Underflow of the sender's balance is impossible because we check for
        // owner above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _balances[owner] -= 1;
            _balances[DEAD_ADDR] += 1;

            _owners[tokenId] = DEAD_ADDR;

            // If the owner slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            
            uint256 nextTokenId = tokenId + 1;
            if (_owners[nextTokenId] == address(0)) {
                // This will suffice for checking _exists(nextTokenId), 
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _nextTokenId) { 
                    _owners[nextTokenId] = owner;
                }
            }
        }

        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfers(owner, address(0), tokenId, 1);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();
                else {
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


// File contracts/extensions/ERC721OptOwnersExplicit.sol



pragma solidity ^0.8.4;

error AllOwnersHaveBeenSet();
error QuantityMustBeNonZero();
error NoTokensMintedYet();

abstract contract ERC721OptOwnersExplicit is ERC721Opt {
    uint256 public nextOwnerToExplicitlySet = 1;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        if (quantity == 0) revert QuantityMustBeNonZero();
        if (_nextTokenId == 1) revert NoTokensMintedYet();
        uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
        if (_nextOwnerToExplicitlySet >= _nextTokenId) revert AllOwnersHaveBeenSet();

        // Index underflow is impossible.
        // Counter or index overflow is incredibly unrealistic.
        unchecked {
            uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

            // Set the end index to be the last token index
            if (endIndex + 1 > _nextTokenId) {
                endIndex = _nextTokenId - 1;
            }

            for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
                if (_owners[i] == address(0) && _owners[i] != DEAD_ADDR) {
                    address ownership = ownerOf(i);
                    _owners[i] = ownership;
                }
            }

            nextOwnerToExplicitlySet = endIndex + 1;
        }
    }
}


// File contracts/extensions/ERC721OptBurnable.sol



pragma solidity ^0.8.4;

error BurnCallerNotOwnerNorApproved();

/**
 * @title ERC721Opt Burnable Token
 * @dev ERC721Opt Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721OptBurnable is ERC721Opt {

    /**
     * @dev Burns `tokenId`. See {ERC721Opt-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert BurnCallerNotOwnerNorApproved();
        _burn(tokenId);
    }
}


// File contracts/extensions/ERC721OptBatchBurnable.sol



pragma solidity ^0.8.4;

/**
 * @title ERC721Opt Batch Burnable Token
 * @dev ERC721Opt Token that can be irreversibly batch burned (destroyed).
 */
abstract contract ERC721OptBatchBurnable is ERC721OptBurnable {
    /**
     * @dev Perform burn on a batch of tokens
     */
    function batchBurn(uint16[] memory tokenIds) public virtual {
        for (uint16 i = 0; i < tokenIds.length; ++i) {
            if (!_isApprovedOrOwner(_msgSender(), tokenIds[i])) revert BurnCallerNotOwnerNorApproved();
            _burn(tokenIds[i]);
        }
    }
}


// File contracts/extensions/ERC721OptBatchTransferable.sol



pragma solidity ^0.8.4;

/**
 * @title ERC721Opt Batch Transferable Token
 * @dev ERC721Opt Token that can be batch transfered
*/
abstract contract ERC721OptBatchTransferable is ERC721Opt {
    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
    */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint16[] tokenIds
    );

    /**
     * @dev Perform transferFrom on a batch of tokens
     */
    function batchTransferFrom(
        address from,
        address to,
        uint16[] memory tokenIds
    ) public virtual {
        for (uint16 i = 0; i < tokenIds.length; ++i) {
            if (!_isApprovedOrOwner(_msgSender(), tokenIds[i])) revert TransferCallerNotOwnerNorApproved();
            transferFrom(from, to, tokenIds[i]);
        }

        emit TransferBatch(_msgSender(), from, to, tokenIds);
    }

    /**
     * @dev Perform safeTransferFrom on a batch of tokens
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint16[] memory tokenIds
    ) public virtual {
        safeBatchTransferFrom(from, to, tokenIds, '');
    }

    /**
     * @dev Perform safeTransferFrom on a batch of tokens
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint16[] memory tokenIds,
        bytes memory _data
    ) public virtual {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (!_isApprovedOrOwner(_msgSender(), tokenIds[i])) revert TransferCallerNotOwnerNorApproved();
            safeTransferFrom(from, to, tokenIds[i], _data);
        }

        emit TransferBatch(_msgSender(), from, to, tokenIds);
    }
}


// File contracts/OpenSea.sol



pragma solidity ^0.8.4;

contract OpenSeaOwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
}


// File contracts/ApeSquadCharacterSheetNFT.sol



pragma solidity ^0.8.4;




error CharacterSheetTypeQueryForNonexistentToken();
error OnlyMintersCanMintCharacterSheets();
error InvalidPurchaseCharacterSheetTypeId();
error AllCharacterSheetsOfTypeMinted();
error NoCharacterSheetMintAmountProvided();
error InvalidUpdateCharacterSheetLengthsDontMatch();
error InvalidUpdateCharacterSheetTypeId();

contract ApeSquadCharacterSheetNFT is Ownable, ERC721Opt, ERC721OptOwnersExplicit, ERC721OptBatchBurnable, ERC721OptBatchTransferable {
     using Strings for uint256;

    struct CharacterSheetPurchase {
        uint16 characterSheetTypeId;
        uint16 amount;
    }

    struct CharacterSheetType {
        string name;
        uint16 maxCharacterSheets;
        uint16 minted;
    }

    /* Base URI for token URIs */
    string public baseURI;

    /* OpenSea user account proxy */
    address public openSeaProxyRegistryAddress;
    
    /* Minter addressess */
    mapping(address => bool) public minters;

    CharacterSheetType[] public characterSheetTypes;

    /* mapping of each token id to characterSheet type */
    mapping(uint256 => uint16) _tokenIdCharacterSheetTypes;
    
    /* mapping of each token id to rarity. 0 = common, 1 = rare, 2 = legendary */
    mapping(uint256 => uint8) public characterSheetRarity;
    
    constructor(string memory name_, string memory symbol_, string memory _initialBaseURI, address _openSeaProxyRegistryAddress, address[] memory _minters) ERC721Opt(name_, symbol_) {
        baseURI = _initialBaseURI;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        
        for (uint256 i; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }

        _addCharacterSheet("Alex", 250);
        _addCharacterSheet("Borg", 250);
        _addCharacterSheet("Dax", 250);
        _addCharacterSheet("Kanoa", 250);
        _addCharacterSheet("Kazz", 250);
    }

    /**
     * @dev Get characterSheetType count
     */
    function characterSheetTypeCount() public view returns (uint256) {
        return characterSheetTypes.length;
    }

    /**
     * @dev Get characterSheets left for sale
     */
    function characterSheetsLeft(uint16 characterSheetTypeId) public view returns (uint256) {
        return characterSheetTypes[characterSheetTypeId].maxCharacterSheets - characterSheetTypes[characterSheetTypeId].minted;
    }

    /**
     * @dev Get the characterSheet type for a specific tokenId
     */
    function tokenCharacterSheetType(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert CharacterSheetTypeQueryForNonexistentToken();

        return characterSheetTypes[_tokenIdCharacterSheetTypes[tokenId]].name;
    }

    /**
     * @dev Override to if default approved for OS proxy accounts or normal approval
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        OpenSeaProxyRegistry openSeaProxyRegistry = OpenSeaProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (address(openSeaProxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return ERC721Opt.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Override to change the baseURI used in tokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Override to change tokenURI format
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'))
                : '';
    }

    /**
     * @dev Mint of specific characterSheet type to address. 
     */
    function mint(address to, CharacterSheetPurchase[] calldata characterSheetPurchases) public {
        if(!minters[msg.sender]) revert OnlyMintersCanMintCharacterSheets();

        uint256 amountToMint;

        uint256 tokenId = _nextTokenId;

        for (uint16 i; i < characterSheetPurchases.length; i++) {
            CharacterSheetPurchase memory p = characterSheetPurchases[i];

            if(p.characterSheetTypeId >= characterSheetTypes.length) revert InvalidPurchaseCharacterSheetTypeId();

            if(p.amount > characterSheetsLeft(characterSheetPurchases[i].characterSheetTypeId)) revert AllCharacterSheetsOfTypeMinted();

            characterSheetTypes[p.characterSheetTypeId].minted += p.amount;
            amountToMint += p.amount;

            for (uint16 j; j < p.amount; j++) {
                _tokenIdCharacterSheetTypes[tokenId++] = p.characterSheetTypeId;
            }
        }
            
        if(amountToMint == 0) revert NoCharacterSheetMintAmountProvided();
        
        _safeMint(to, amountToMint, '');
    }

    /**
     * @dev Mint of specific poster type to address. 
     */
    function mintType(address to, uint16 characterSheetTypeId, uint16 amount) public {
        if(!minters[msg.sender]) revert OnlyMintersCanMintCharacterSheets();
            
        if(amount == 0) revert NoCharacterSheetMintAmountProvided();

        uint256 tokenId = _nextTokenId;
        if(characterSheetTypeId >= characterSheetTypes.length) revert InvalidPurchaseCharacterSheetTypeId();

        if(amount > characterSheetsLeft(characterSheetTypeId)) revert AllCharacterSheetsOfTypeMinted();

        characterSheetTypes[characterSheetTypeId].minted += amount;

        for (uint16 i; i < amount; i++) {
            _tokenIdCharacterSheetTypes[tokenId++] = characterSheetTypeId;
        }
        
        _safeMint(to, amount, '');
    }

    /**
     * @dev Set the base uri for token metadata
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Set minter status for addresses
     */
    function setMinters(address[] calldata addresses, bool allowed) external onlyOwner {
        for(uint256 i; i < addresses.length; i++) {
            minters[addresses[i]] = allowed;
        }
    }

    /**
     * @dev Add new characterSheet
     */
    function _addCharacterSheet(string memory name, uint16 maxCharacterSheets) internal {
        CharacterSheetType memory cs;

        cs.name = name;
        cs.maxCharacterSheets = maxCharacterSheets;

        characterSheetTypes.push(cs);
    }

    /**
     * @dev Add new characterSheet
     */
    function addCharacterSheet(string calldata name, uint16 maxCharacterSheets) external onlyOwner {
        _addCharacterSheet(name, maxCharacterSheets);
    }

    /**
     * @dev Update characterSheet names
     */
    function updateCharacterSheetNames(uint16[] calldata characterSheetTypeIds, string[] calldata names) external onlyOwner {
        if(characterSheetTypeIds.length != names.length) revert InvalidUpdateCharacterSheetLengthsDontMatch();

        for (uint16 i; i < characterSheetTypeIds.length; i++) {
            if(characterSheetTypeIds[i] >= characterSheetTypes.length) revert InvalidUpdateCharacterSheetTypeId();

            characterSheetTypes[characterSheetTypeIds[i]].name = names[i];
        }
    }

    /**
     * @dev Update available characterSheets
     */
    function updateMaxCharacterSheets(uint16[] calldata characterSheetTypeIds, uint16[] calldata maxCharacterSheets) external onlyOwner {
        if(characterSheetTypeIds.length != maxCharacterSheets.length) revert InvalidUpdateCharacterSheetLengthsDontMatch();

        for (uint16 i; i < characterSheetTypeIds.length; i++) {
            if(characterSheetTypeIds[i] >= characterSheetTypes.length) revert InvalidUpdateCharacterSheetTypeId();

            characterSheetTypes[characterSheetTypeIds[i]].maxCharacterSheets = maxCharacterSheets[i];
        }
    }

    /**
     * @dev Upate Rarities on chain for future staking
     */
    function updateRarities(uint8 rarity, uint256[] calldata tokenIds) external onlyOwner {
        if (rarity == 0) {
            for(uint256 i; i < tokenIds.length; i++) {
                if (tokenIds[i] >= _nextTokenId) continue;

                delete characterSheetRarity[tokenIds[i]];
            }
        } else {
            for(uint256 i; i < tokenIds.length; i++) {
                if (tokenIds[i] >= _nextTokenId) continue;

                characterSheetRarity[tokenIds[i]] = rarity;
            }
        }
    }

    /**
     * @dev Force update all owners for better transfers
     */
    function updateOwners(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }
}


// File contracts/ApeSquadPosterNFT.sol



pragma solidity ^0.8.4;




error PosterTypeQueryForNonexistentToken();
error OnlyMintersCanMintPosters();
error InvalidPurchasePosterTypeId();
error AllPostersOfTypeMinted();
error NoPosterMintAmountProvided();
error InvalidUpdatePosterLengthsDontMatch();
error InvalidUpdatePosterTypeId();

contract ApeSquadPosterNFT is Ownable, ERC721Opt, ERC721OptOwnersExplicit, ERC721OptBatchBurnable, ERC721OptBatchTransferable {
     using Strings for uint256;

    struct PosterPurchase {
        uint16 posterTypeId;
        uint16 amount;
    }

    struct PosterType {
        string name;
        uint16 maxPosters;
        uint16 minted;
    }

    /* Base URI for token URIs */
    string public baseURI;

    /* OpenSea user account proxy */
    address public openSeaProxyRegistryAddress;
    
    /* Minter addressess */
    mapping(address => bool) public minters;

    PosterType[] public posterTypes;

    /* mapping of each token id to poster type */
    mapping(uint256 => uint16) _tokenIdPosterTypes;

    /* mapping of each token id to rarity. 0 = common, 1 = rare, 2 = legendary */
    mapping(uint256 => uint8) public posterRarity;
    
    constructor(string memory name_, string memory symbol_, string memory _initialBaseURI, address _openSeaProxyRegistryAddress, address[] memory _minters) ERC721Opt(name_, symbol_) {
        baseURI = _initialBaseURI;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        
        for (uint256 i; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }

        _addPoster("Season 1", 1250);
    }

    /**
     * @dev Get posterType count
     */
    function posterTypeCount() public view returns (uint256) {
        return posterTypes.length;
    }

    /**
     * @dev Get posters left for sale
     */
    function postersLeft(uint16 posterTypeId) public view returns (uint256) {
        return posterTypes[posterTypeId].maxPosters - posterTypes[posterTypeId].minted;
    }

    /**
     * @dev Get the poster type for a specific tokenId
     */
    function tokenPosterType(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert PosterTypeQueryForNonexistentToken();

        return posterTypes[_tokenIdPosterTypes[tokenId]].name;
    }

    /**
     * @dev Override to if default approved for OS proxy accounts or normal approval
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        OpenSeaProxyRegistry openSeaProxyRegistry = OpenSeaProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (address(openSeaProxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return ERC721Opt.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Override to change the baseURI used in tokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Override to change tokenURI format
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'))
                : '';
    }

    /**
     * @dev Mint of specific poster type to address. 
     */
    function mint(address to, PosterPurchase[] calldata posterPurchases) public {
        if(!minters[msg.sender]) revert OnlyMintersCanMintPosters();

        uint256 amountToMint;

        uint256 tokenId = _nextTokenId;

        for (uint16 i; i < posterPurchases.length; i++) {
            PosterPurchase memory p = posterPurchases[i];

            if(p.posterTypeId >= posterTypes.length) revert InvalidPurchasePosterTypeId();

            if(p.amount > postersLeft(posterPurchases[i].posterTypeId)) revert AllPostersOfTypeMinted();

            posterTypes[p.posterTypeId].minted += p.amount;
            amountToMint += p.amount;

            for (uint16 j; j < p.amount; j++) {
                _tokenIdPosterTypes[tokenId++] = p.posterTypeId;
            }
        }
            
        if(amountToMint == 0) revert NoPosterMintAmountProvided();
        
        _safeMint(to, amountToMint, '');
    }

    /**
     * @dev Mint of specific poster type to address. 
     */
    function mintType(address to, uint16 posterTypeId, uint16 amount) public {
        if(!minters[msg.sender]) revert OnlyMintersCanMintPosters();
            
        if(amount == 0) revert NoPosterMintAmountProvided();

        uint256 tokenId = _nextTokenId;
        if(posterTypeId >= posterTypes.length) revert InvalidPurchasePosterTypeId();

        if(amount > postersLeft(posterTypeId)) revert AllPostersOfTypeMinted();

        posterTypes[posterTypeId].minted += amount;

        for (uint16 i; i < amount; i++) {
            _tokenIdPosterTypes[tokenId++] = posterTypeId;
        }
        
        _safeMint(to, amount, '');
    }

    /**
     * @dev Set the base uri for token metadata
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Set minter status for addresses
     */
    function setMinters(address[] calldata addresses, bool allowed) external onlyOwner {
        for(uint256 i; i < addresses.length; i++) {
            minters[addresses[i]] = allowed;
        }
    }

    /**
     * @dev Add new poster
     */
    function _addPoster(string memory name, uint16 maxPosters) internal {
        PosterType memory p;

        p.name = name;
        p.maxPosters = maxPosters;

        posterTypes.push(p);
    }
    
    /**
     * @dev Add new poster
     */
    function addPoster(string calldata name, uint16 maxPosters) external onlyOwner {
        _addPoster(name, maxPosters);
    }

    /**
     * @dev Update poster names
     */
    function updatePosterNames(uint16[] calldata posterTypeIds, string[] calldata names) external onlyOwner {
        if(posterTypeIds.length != names.length) revert InvalidUpdatePosterLengthsDontMatch();

        for (uint16 i; i < posterTypeIds.length; i++) {
            if(posterTypeIds[i] >= posterTypes.length) revert InvalidUpdatePosterTypeId();

            posterTypes[posterTypeIds[i]].name = names[i];
        }
    }
    /**
     * @dev Update available posters
     */
    function updateMaxPosters(uint16[] calldata posterTypeIds, uint16[] calldata maxPosters) external onlyOwner {
        if(posterTypeIds.length != maxPosters.length) revert InvalidUpdatePosterLengthsDontMatch();

        for (uint16 i; i < posterTypeIds.length; i++) {
            if(posterTypeIds[i] >= posterTypes.length) revert InvalidUpdatePosterTypeId();

            posterTypes[posterTypeIds[i]].maxPosters = maxPosters[i];
        }
    }

    /**
     * @dev Upate Rarities on chain for future staking
     */
    function updateRarities(uint8 rarity, uint256[] calldata tokenIds) external onlyOwner {
        if (rarity == 0) {
            for(uint256 i; i < tokenIds.length; i++) {
                if (tokenIds[i] >= _nextTokenId) continue;

                delete posterRarity[tokenIds[i]];
            }
        } else {
            for(uint256 i; i < tokenIds.length; i++) {
                if (tokenIds[i] >= _nextTokenId) continue;

                posterRarity[tokenIds[i]] = rarity;
            }
        }
    }

    /**
     * @dev Force update all owners for better transfers
     */
    function updateOwners(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }
}


// File contracts/ApeSquadMinter.sol


pragma solidity ^0.8.0;



contract ApeSquadMinter is Ownable {
    /* Character Sheet NFT contract */
    ApeSquadCharacterSheetNFT characterSheetNFTContract;
    /* Poster NFT contract */
    ApeSquadPosterNFT posterNFTContract;

    /* Is Sale Active */
    bool public saleIsActive;

    /* silver cards reserved for marketing */
    mapping(uint16 => uint16) public reservedCharacterSheets;
    /* posters reserved for marketing */
    uint16 public reservedSeason1Posters = 2;

    /* Price for character sheets */
    uint256 public characterSheetPrice = 0.08 ether;

    /* NFT Contracts that can get free poster */
    address[] public freeSeason1PosterNftContracts;

    /* Mapping of claimed posters */
    mapping(address => bool) public season1PosterClaimed;

    constructor(
        ApeSquadCharacterSheetNFT _characterSheetNFTContract,
        ApeSquadPosterNFT _posterNFTContract,
        address[] memory _freeSeason1PosterNftContracts
    ) {
        characterSheetNFTContract = _characterSheetNFTContract;
        posterNFTContract = _posterNFTContract;

        for (uint16 i; i < characterSheetNFTContract.characterSheetTypeCount(); i++) {
            reservedCharacterSheets[i] = 6;
        }

        freeSeason1PosterNftContracts = _freeSeason1PosterNftContracts;
    }
    
    function mint(ApeSquadCharacterSheetNFT.CharacterSheetPurchase[] calldata characterSheetPurchases, bool freeSeason1Poster) external payable {
        require(msg.sender == tx.origin, 'Only EOA');
        require(saleIsActive, 'Regular sale is not active');

        uint256 totalAmount;

        for (uint16 i; i < characterSheetPurchases.length; i++) {
            require(
                characterSheetPurchases[i].amount <= characterSheetNFTContract.characterSheetsLeft(characterSheetPurchases[i].characterSheetTypeId) - reservedCharacterSheets[characterSheetPurchases[i].characterSheetTypeId],
                'Sold Out'
            );
            totalAmount += characterSheetPurchases[i].amount;
        }

        if (freeSeason1Poster) {
            require(!season1PosterClaimed[msg.sender], 'Season 1 Poster already claimed');

            bool valid = totalAmount > 0 || characterSheetNFTContract.balanceOf(msg.sender) > 0;

            if (totalAmount == 0 && characterSheetNFTContract.balanceOf(msg.sender) == 0) {
                for (uint256 i; i < freeSeason1PosterNftContracts.length; i++) {
                   valid = valid || IERC721(freeSeason1PosterNftContracts[i]).balanceOf(msg.sender) > 0;
                   if (valid) break;
                }
            }

            require(valid, 'Season 1 Poster requirements not met');
            season1PosterClaimed[msg.sender] = true;
        }

        require(
            msg.value >= (totalAmount * characterSheetPrice),
            'Ether value sent is not correct'
        );

        if(totalAmount > 0) {
            characterSheetNFTContract.mint(msg.sender, characterSheetPurchases);
        }
        if (freeSeason1Poster) {
            posterNFTContract.mintType(msg.sender, 0, 1);
        }
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setReserves(uint16[] calldata _characterSheetTypeIds, uint16[] calldata _characterSheetAmounts, uint16 _season1PosterAmount) external onlyOwner {
        require(
            _characterSheetTypeIds.length == _characterSheetAmounts.length,
            'Character Sheet Type Ids length should match Amounts length'
        );

        for (uint16 i; i < _characterSheetTypeIds.length; i++) {
            require(
                _characterSheetTypeIds[i] < characterSheetNFTContract.characterSheetTypeCount(),
                'Character Sheet Type Id should be with in range'
            );

            reservedCharacterSheets[_characterSheetTypeIds[i]] = _characterSheetAmounts[i];
        }

        reservedSeason1Posters = _season1PosterAmount;
    }

    function setFreeSeason1PosterNftContracts(address[] calldata _freeSeason1PosterNftContracts) external onlyOwner {
        freeSeason1PosterNftContracts = _freeSeason1PosterNftContracts;
    }

    function setPrice(uint256 _characterSheetPrice) external onlyOwner {
        characterSheetPrice = _characterSheetPrice;
    }

    function reserveMint(uint16[] calldata _characterSheetTypeIds, uint16[] calldata _characterSheetAmounts, uint16 season1Posters, address[] calldata to) external onlyOwner {
        require(
            _characterSheetTypeIds.length == _characterSheetAmounts.length,
            'Character Sheet Type Ids length should match Amounts length'
        );
        
        for (uint16 i; i < _characterSheetTypeIds.length; i++) {
            require(
                (_characterSheetAmounts[i] * to.length) <= reservedCharacterSheets[_characterSheetTypeIds[i]],
                'Not enough reserve left for team'
            );
        }

        require(
            (season1Posters * to.length) <= reservedSeason1Posters,
            'Not enough reserve left for team'
        );

        for (uint16 i = 0; i < to.length; i++) {
            for (uint16 j; j < _characterSheetTypeIds.length; j++) {
                characterSheetNFTContract.mintType(to[i], _characterSheetTypeIds[j], _characterSheetAmounts[j]);
            }

            if (season1Posters > 0 ) {
                posterNFTContract.mintType(to[i], 0, season1Posters);
            }
        }

        for (uint16 i; i < _characterSheetTypeIds.length; i++) {
            reservedCharacterSheets[_characterSheetTypeIds[i]] -= uint16(_characterSheetAmounts[i] * to.length);
        }

        reservedSeason1Posters -= uint16(season1Posters * to.length);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}