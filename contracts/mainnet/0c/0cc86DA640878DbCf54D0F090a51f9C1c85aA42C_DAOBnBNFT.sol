/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

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


// File contracts/DAOBnBNFT.sol



pragma solidity ^0.8.4;




contract OpenSeaOwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
}

interface IToken {
    /**
     * @dev Called from DAOBnBNFT when one is transfered/minted/burned
     */
    function updateRewards(address _user) external;
}

error CardTypeQueryForNonexistentToken();
error OnlyMintersCanMint();
error NoMintAmountProvided();
error AllSilverCardsMinted();
error AllBlackCardsMinted();

contract DAOBnBNFT is Ownable, ERC721Opt, ERC721OptOwnersExplicit, ERC721OptBatchBurnable, ERC721OptBatchTransferable {
     using Strings for uint16;

    /* Base URI for token URIs */
    string public baseURI;

    /* OpenSea user account proxy */
    address public openSeaProxyRegistryAddress;

    /* Token contract */
    IToken public token;

    uint16 silverCardsMax = 6400;
    uint16 blackCardsMax = 2700;

    uint16 blackCardsMinted;

    /* mapping of each wallets black cards */
    mapping(address => uint16) public walletBlackCards;
    
    /* Minter addressess */
    mapping(address => bool) public minters;

    /* mapping of each token id to card type 0 = silver, 1 = black */
    mapping(uint16 => bool) _blackCardTokenIds;
    
    constructor(string memory name_, string memory symbol_, string memory _initialBaseURI, address _openSeaProxyRegistryAddress, address[] memory _minters) ERC721Opt(name_, symbol_) {
        baseURI = _initialBaseURI;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        
        for (uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }
    }

    /**
     * @dev Get silver cards left for sale
     */
    function silverCardsLeft() public view returns (uint256) {
        return silverCardsMax - (_nextTokenId - 1 - blackCardsMinted);
    }

    /**
     * @dev Get black cards left for sale
     */
    function blackCardsLeft() public view returns (uint256) {
        return blackCardsMax - blackCardsMinted;
    }

    /**
     * @dev Get the card type for a specific tokenId
     */
    function tokenCardType(uint16 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert CardTypeQueryForNonexistentToken();

        if (_blackCardTokenIds[tokenId]) {
            return "black";
        }

        return "silver";
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
                ? string(abi.encodePacked(_baseURI(), tokenCardType(uint16(tokenId)), '.json'))
                : '';
    }

    /**
     * @dev Mint of specific card type to address. 
     */
    function mint(uint16 silverCardsAmount, uint16 blackCardsAmount, address to) public {
        if(!minters[msg.sender]) revert OnlyMintersCanMint();
        if(silverCardsAmount + blackCardsAmount == 0) revert NoMintAmountProvided();
        if(_nextTokenId - 1 - blackCardsMinted + silverCardsAmount > silverCardsMax) revert AllSilverCardsMinted();
        if(blackCardsMinted + blackCardsAmount > blackCardsMax) revert AllBlackCardsMinted();

        if (blackCardsAmount > 0) {
            blackCardsMinted += blackCardsAmount;

            uint16 tokenId = uint16(_nextTokenId) + silverCardsAmount;

            for (uint16 i; i < blackCardsAmount; i++) {
                _blackCardTokenIds[tokenId++] = true;
            }
        }
        
        _safeMint(to, silverCardsAmount + blackCardsAmount, '');
    }

    /**
     * @dev Override so we can update token rewards before transfer happens
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (address(token) != address(0)) {
            token.updateRewards(from);
            token.updateRewards(to);
        }

        uint16 blackCards;

        for(uint16 i = uint16(startTokenId); i < startTokenId + quantity; i++) {
            if (_blackCardTokenIds[i]) {
                blackCards += 1;
            }
        }

        if (from != address(0)) {
            walletBlackCards[from] -= blackCards;
        }
        if (to != address(0)) {
            walletBlackCards[to] += blackCards;
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
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
        for(uint256 i = 0; i < addresses.length; i++) {
            minters[addresses[i]] = allowed;
        }
    }

    /**
     * @dev Update available cards
     */
    function updateAvailableCards(uint16 silverCards, uint16 blackCards) external onlyOwner {
        silverCardsMax = silverCards;
        blackCardsMax = blackCards;
    }

    /**
     * @dev Set the token contract
     */
    function setToken(IToken _token) external onlyOwner {
        token = _token;
    }

    /**
     * @dev Force update all owners for better transfers
     */
    function updateOwners(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/DAOBnBMinter.sol


pragma solidity ^0.8.0;



contract DAOBnBMinter is Ownable {
    using Strings for uint16;
    using ECDSA for bytes32;

    /* DAObnb NFT contract */
    DAOBnBNFT nftContract;

    /* Is Pre Sale Active */
    bool public preSaleIsActive;
    /* Is Sale Active */
    bool public saleIsActive;
    
    /* If > 0 limit pre sale silver cards purchases per address */
    uint16 public maxPreSaleSilverCardsPerAddress = 2;
    /* If > 0 limit pre sale black cards purchases per address */
    uint16 public maxPreSaleBlackCardsPerAddress = 1;

    /* Limit how many silver cards can be purchased in single transaction for pre sale */
    uint16 public maxPreSaleSilverCardsPerTransaction = 2;
    /* Limit how many black cards can be purchased in single transaction for pre sale */
    uint16 public maxPreSaleBlackCardsPerTransaction = 1;
    
    /* Limit how many silver cards can be purchased in single transaction for public sale */
    uint16 public maxSilverCardsPerTransaction = 16;
    /* Limit how many black cards can be purchased in single transaction for public sale */
    uint16 public maxBlackCardsPerTransaction = 4;

    /* silver cards reserved for marketing */
    uint16 public reservedSilverCards = 640;
    /* black cards reserved for marketing */
    uint16 public reservedBlackCards = 270;

    /* Price for silver card during pre sale */
    uint256 public preSaleSilverCardPrice = 0.175 ether;
    /* Price for black card during pre sale */
    uint256 public preSaleBlackCardPrice = 0.7 ether;

    /* Price for silver card during public sale */
    uint256 public silverCardPrice = 0.175 ether;
    /* Price for black card during public sale */
    uint256 public blackCardPrice = 0.7 ether;
    
    /* PreSaleList Signature Addresses */
    mapping(address => bool) public preSaleListSignatureAddresses;
    /* PreSaleList Signature Nounces used */
    mapping(uint16 => address) public preSaleListSignatureUsedNounces;
    
    /* PreSaleListed addressess */
    mapping(address => bool) public preSaleListedAddresses;

    /* Silver cards minted per address during pre sale */
    mapping(address => uint16) public preSaleSilverCardPurchases;
    /* Black cards minted per address during pre sale */
    mapping(address => uint16) public preSaleBlackCardPurchases;

    constructor(
        DAOBnBNFT _nftContract,
        address[] memory _preSaleListSignatureAddresses
    ) {
        nftContract = _nftContract;

        for (uint256 i = 0; i < _preSaleListSignatureAddresses.length; i++) {
            preSaleListSignatureAddresses[_preSaleListSignatureAddresses[i]] = true;
        }
    }

    function getPreSaleListMessage(uint16 nounce, address sender)
        public
        pure
        returns (bytes32)
    {
        if (nounce > 0) {
            return keccak256(abi.encodePacked('ProjectId: 621285d3e200cdf5b5ef5704, Nounce: ', nounce));
        }
        
        return keccak256(abi.encodePacked('ProjectId: 621285d3e200cdf5b5ef5704, Address: ', sender));
    }
    
    function mintPreSale(uint16 silverCardsAmount, uint16 blackCardsAmount, uint16 nounce, bytes calldata signature) external payable {
        require(preSaleIsActive, 'Pre sale must be active to mint pre sale');
        require(!saleIsActive, 'Regular sale is already active');
        require(
            silverCardsAmount + blackCardsAmount > 0,
            'No amounts provided'
        );
        require(
            silverCardsAmount <= maxPreSaleSilverCardsPerTransaction,
            'Can not mint that many silver tokens in a single transaction during the pre sale'
        );
        require(
            blackCardsAmount <= maxPreSaleBlackCardsPerTransaction,
            'Can not mint that many black tokens in a single transaction during the pre sale'
        );
        require(
            silverCardsAmount <= nftContract.silverCardsLeft() - reservedSilverCards,
            'Sold Out'
        );
        require(
            blackCardsAmount <= nftContract.blackCardsLeft() - reservedBlackCards,
            'Sold Out'
        );
        require(
            preSaleSilverCardPurchases[msg.sender] + silverCardsAmount <= maxPreSaleSilverCardsPerAddress,
            'Can only mint so many silver cards during the presale'
        );
        require(
            preSaleBlackCardPurchases[msg.sender] + blackCardsAmount <= maxPreSaleBlackCardsPerAddress,
            'Can only mint so many black cards during the presale'
        );
        require(
            msg.value >= (preSaleSilverCardPrice * silverCardsAmount) + (preSaleBlackCardPrice * blackCardsAmount),
            'Ether value sent is not correct'
        );
        require(preSaleListedAddresses[_msgSender()] || signature.length > 0, 'Signature required for pre sale');
        require(nounce == 0 || preSaleListSignatureUsedNounces[nounce] == address(0) || preSaleListSignatureUsedNounces[nounce] == _msgSender(), 'Invalid or used nounce');

        if (!preSaleListedAddresses[_msgSender()] && preSaleListSignatureUsedNounces[nounce] != _msgSender()) {
            bytes32 message = getPreSaleListMessage(nounce, _msgSender());
            bytes32 messageHash = message.toEthSignedMessageHash();
            address signer = messageHash.recover(signature);

            require(preSaleListSignatureAddresses[signer], 'Signature invalid');

            if (nounce > 0) {
                preSaleListSignatureUsedNounces[nounce] = _msgSender();
            }
        }

        preSaleSilverCardPurchases[msg.sender] += silverCardsAmount;
        preSaleBlackCardPurchases[msg.sender] += blackCardsAmount;

        nftContract.mint(silverCardsAmount, blackCardsAmount, msg.sender);
    }
    
    function mint(uint16 silverCardsAmount, uint16 blackCardsAmount) external payable {
        require(saleIsActive, 'Regular sale is not active');
        require(
            silverCardsAmount + blackCardsAmount > 0,
            'No amounts provided'
        );
        require(
            silverCardsAmount <= maxSilverCardsPerTransaction,
            'Can not mint that many silver cards in a single transaction during the sale'
        );
        require(
            blackCardsAmount <= maxBlackCardsPerTransaction,
            'Can not mint that many black cards in a single transaction during the sale'
        );
        require(
            silverCardsAmount <= nftContract.silverCardsLeft() - reservedSilverCards,
            'Sold Out'
        );
        require(
            blackCardsAmount <= nftContract.blackCardsLeft() - reservedBlackCards,
            'Sold Out'
        );
        require(
            msg.value >= (silverCardPrice * silverCardsAmount) + (blackCardPrice * blackCardsAmount),
            'Ether value sent is not correct'
        );

        nftContract.mint(silverCardsAmount, blackCardsAmount, _msgSender());
    }
    
    /**
     * @dev Update a list of addresses to be allowed to be used for signature based preSaleList
     */
    function updatePreSaleListSignatureAddresses(address[] memory _preSaleListSignatureAddresses, bool allowed)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _preSaleListSignatureAddresses.length; i++) {
            preSaleListSignatureAddresses[_preSaleListSignatureAddresses[i]] = allowed;
        }
    }
    
    /**
     * @dev Update a list of addresses to be allowed in preSaleList
     */
    function updatePreSaleListedAddresses(address[] memory _preSaleListedAddresses, bool allowed)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _preSaleListedAddresses.length; i++) {
            preSaleListedAddresses[_preSaleListedAddresses[i]] = allowed;
        }
    }

    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMaxPreSaleCardsPerAddress(uint16 _silverCardsAmount, uint16 _blackCardsAmount) external onlyOwner {
        maxPreSaleSilverCardsPerAddress = _silverCardsAmount;
        maxPreSaleBlackCardsPerAddress = _blackCardsAmount;
    }

    function setMaxPreSaleCardsPerTransaction(uint16 _silverCardsAmount, uint16 _blackCardsAmount) external onlyOwner {
        maxPreSaleSilverCardsPerTransaction = _silverCardsAmount;
        maxPreSaleBlackCardsPerTransaction = _blackCardsAmount;
    }

    function setMaxCardsPerTransaction(uint16 _silverCardsAmount, uint16 _blackCardsAmount, bool updatePreSaleAlso) external onlyOwner {
        maxSilverCardsPerTransaction = _silverCardsAmount;
        maxBlackCardsPerTransaction = _blackCardsAmount;

        if (updatePreSaleAlso) {
            maxPreSaleSilverCardsPerTransaction = _silverCardsAmount;
            maxPreSaleBlackCardsPerTransaction = _blackCardsAmount;
        }
    }

    function setReservedCards(uint16 _silverCardsAmount, uint16 _blackCardsAmount) external onlyOwner {
        reservedSilverCards = _silverCardsAmount;
        reservedBlackCards = _blackCardsAmount;
    }

    function setPreSalePrice(uint256 _silverCardPrice, uint256 _blackCardPrice) external onlyOwner {
        preSaleSilverCardPrice = _silverCardPrice;
        preSaleBlackCardPrice = _blackCardPrice;
    }

    function setPrice(uint256 _silverCardPrice, uint256 _blackCardPrice, bool updatePreSaleAlso) external onlyOwner {
        silverCardPrice = _silverCardPrice;
        blackCardPrice = _blackCardPrice;

        if (updatePreSaleAlso) {
            preSaleSilverCardPrice = _silverCardPrice;
            preSaleBlackCardPrice = _blackCardPrice;
        }
    }

    function reserveMint(uint16 silverCardsAmount, uint16 blackCardsAmount, address[] calldata to) external onlyOwner {
        require(
            (silverCardsAmount * to.length) <= reservedSilverCards,
            'Not enough reserve left for team'
        );
        require(
            (blackCardsAmount * to.length) <= reservedBlackCards,
            'Not enough reserve left for team'
        );
        require(
            silverCardsAmount + blackCardsAmount > 0,
            'No amounts provided'
        );

        for (uint16 i = 0; i < to.length; i++) {
            nftContract.mint(silverCardsAmount, blackCardsAmount, to[i]);
        }

        reservedSilverCards = uint16(reservedSilverCards - (silverCardsAmount * to.length));
        reservedBlackCards = uint16(reservedBlackCards - (blackCardsAmount * to.length));
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}