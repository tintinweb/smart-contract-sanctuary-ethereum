/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

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

// File: contracts/Fetih.sol


pragma solidity ^0.8.4;




interface IFetihOracleClient {
    function requestData(uint256 attackerId, uint256 defenderId, uint256 attackerSoldiers, uint256 defenderSoldiers) external returns (bytes32 requestId);
}

contract Fetih is ERC721, ERC721Enumerable, Ownable {
    string BASE_URI;
    uint256 constant MAX_SUPPLY = 81;
    uint256 constant CITY_PRICE = 0.1 * (10 ** 18);
    bool IS_WAR_ENDED;
    address ORACLE_CLIENT;
    uint256 constant MINIMUM_DEFENDER_SOLDIER = 1;
    uint256 constant MINIMUM_ATTACKER_SOLDIER = 3;
    uint256 constant PROD_SOLDIER_COST = CITY_PRICE / 10;

    mapping(uint256 => uint256) _soldiers;
    mapping(uint256 => mapping(uint256 => bool)) _invadableCities;
    mapping(address => mapping(uint256 => uint256)) _barrack;

    event UpdateBaseURI(string oldBaseURI, string newBaseURI);
    event BoughtCity(address sender, uint256 tokenId, uint256 amount);
    event UpdateOracleClient(address oldClient, address newClient);
    event StartedBattle(address emperor, uint256 attackerTokenId, uint256 defenderTokenId);
    event WonBattle(address emperor, uint256 conqueredTokenId);
    event LostBattle(address emperor, uint256 attackerTokenId, uint256 defenderTokenId);
    event PushSoldier(address emperor, uint256 tokenId);
    event ClaimSoldier(address emperor, uint256 tokenId);
    
    constructor(string memory _baseUri) ERC721("Fetih", "FTH") {
        BASE_URI = _baseUri;

        uint256 iterator = 1;
        for(;iterator <= maxSupply();) {
            _safeMint(address(this), iterator);
            _soldiers[iterator] = 10;
            
            unchecked {
                iterator++;
            }
        }

        initInvadableCities();
    }

    function getMinimumDefenderSoldier() internal pure returns(uint256) {
        return MINIMUM_DEFENDER_SOLDIER;
    }

    function getMinimumAttackerSoldier() internal pure returns(uint256) {
        return MINIMUM_ATTACKER_SOLDIER;
    }

    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function getBaseURI() external view returns(string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function _setBaseUri(string memory _baseUri) external onlyOwner {
        emit UpdateBaseURI(BASE_URI, _baseUri);

        BASE_URI = _baseUri;
    }

    function isInvadableCity(uint256 attackerTokenId, uint256 defenderTokenId) internal view returns(bool) {
        return _invadableCities[attackerTokenId][defenderTokenId];
    }

    function buyCity(uint256 tokenId) external payable {
        require(tokenId > 0 && tokenId <= maxSupply(), "There is no city with given tokenId!");
        require(balanceOf(msg.sender) == 0, "Can't buy when you have one!");
        require(msg.value >= CITY_PRICE, "Amount is not enough!");

        emit BoughtCity(msg.sender, tokenId, msg.value);

        safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function battle(uint256 attackerTokenId, uint256 defenderTokenId) external whenWarContinues {
        require(ownerOf(attackerTokenId) == msg.sender, "You are not owner of attacking city!");
        require(ownerOf(defenderTokenId) != msg.sender, "You can't attack your city!");
        require(_soldiers[attackerTokenId] >= getMinimumAttackerSoldier(), "City has more than 2 soldiers to attack!");
        require(isInvadableCity(attackerTokenId, defenderTokenId), "You should attack to city that has shared borders with attacking city!");

        emit StartedBattle(msg.sender, attackerTokenId, defenderTokenId);

        IFetihOracleClient(getOracleClient()).requestData(attackerTokenId, defenderTokenId, _soldiers[attackerTokenId], _soldiers[defenderTokenId]);
    }

    function battleResult(uint256 attackerTokenId, uint256 defenderTokenId, bool isSucceed) public onlyOracleClient whenWarContinues {
        uint256 attackerSoldiers = _soldiers[attackerTokenId];
        uint256 defenderSoldiers = _soldiers[defenderTokenId];
        address attackingEmperor = ownerOf(attackerTokenId);
        address defendingEmperor = ownerOf(defenderTokenId);

        if (isSucceed || defenderSoldiers == getMinimumDefenderSoldier()) {
            //if wins
            emit WonBattle(msg.sender, defenderTokenId);
            if (attackerSoldiers > 1) {
                attackerSoldiers -= 1; 
            }

            defenderSoldiers = 1;

            _soldiers[attackerTokenId] = attackerSoldiers;
            _soldiers[defenderTokenId] = defenderSoldiers;

            _transfer(defendingEmperor, attackingEmperor, defenderTokenId);

            // if all cities conquered
            uint256 amount = balanceOf(attackingEmperor);
            if (amount == maxSupply()) {
                uint256 totalPrice = address(this).balance * 9 / 10;
                uint256 comission = address(this).balance / 10;

                sendViaCall(payable(attackingEmperor), totalPrice);
                sendViaCall(payable(owner()), comission);
            }
        }
        else {
            //if loses
            emit LostBattle(msg.sender, attackerTokenId, defenderTokenId);

            if (attackerSoldiers <= 3) {
                attackerSoldiers = 1;
            } else {
                attackerSoldiers -= 3;
            }

            if (defenderSoldiers > 1) {
                defenderSoldiers -= 1;
            }

            _soldiers[attackerTokenId] = attackerSoldiers;
            _soldiers[defenderTokenId] = defenderSoldiers;

        }
    }

    function getOracleClient() public view returns (address) {
        return ORACLE_CLIENT;
    }

    function changeOracleClient(address _newClient) external onlyOwner {
        emit UpdateOracleClient(ORACLE_CLIENT, _newClient);

        ORACLE_CLIENT = _newClient;
    }

    function sendViaCall(address payable _to, uint256 amount) internal {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function produceSoldiers(uint256 tokenId) external whenWarContinues {
        require(ownerOf(tokenId) == msg.sender, "You should be emperor of the city!");
        require(!isTheBarrackBusy(tokenId), "Barrack is busy, claim your soldiers first!");
        
        emit PushSoldier(msg.sender, tokenId);

        _barrack[msg.sender][tokenId] = block.timestamp + 3600;
    }

    function isTheBarrackBusy(uint256 tokenId) public view returns (bool) {
        if (_barrack[msg.sender][tokenId] == 0) return false;

        return true;
    }

    function claimSoldiers(uint256 tokenId) external whenWarContinues {
        require(ownerOf(tokenId) == msg.sender, "You should be emperor of the city!");
        require(isTheBarrackBusy(tokenId), "You should start producing soldier first!");
        require(block.timestamp >= _barrack[msg.sender][tokenId], "Soldiers are not ready!");

        emit ClaimSoldier(msg.sender, tokenId);

        _barrack[msg.sender][tokenId] = 0;
        _soldiers[tokenId] += 5;
    }

    function getAllSoldiers() external view returns(uint256[] memory) {
        uint256[] memory soldiers = new uint256[](maxSupply());
        uint256 iterator = 0;
        for(;iterator > maxSupply();) {
            soldiers[iterator] = _soldiers[iterator + 1];

            unchecked {
                iterator++;
            }
        }

        return soldiers;
    }

    function getSoldiersByCity(uint256 tokenId) external view returns(uint256) {
        return _soldiers[tokenId];
    }

    function getAllOwners() external view returns(address[] memory) {
        address[] memory owners = new address[](maxSupply());
        uint256 iterator = 0;
        for(;iterator > maxSupply();) {
            owners[iterator] = ownerOf(iterator + 1);
            unchecked {
                iterator++;
            }
        }

        return owners;
    }

    modifier whenWarEnded(address from) {
        require(IS_WAR_ENDED || from == address(this), "The war continues!");

        _;
    }

    modifier whenWarContinues() {
        require(!IS_WAR_ENDED, "The war ended");

        _;
    }

    modifier onlyOracleClient() {
        require(getOracleClient() == msg.sender, "Only oracle client!");

        _;
    }

    // overrides

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenWarEnded(from) {
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
    ) public override whenWarEnded(from) {
        ERC721(address(this)).safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override whenWarEnded(from) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function initInvadableCities() internal {
        _invadableCities[1][31] = true;
        _invadableCities[1][80] = true;
        _invadableCities[1][46] = true;
        _invadableCities[1][38] = true;
        _invadableCities[1][51] = true;
        _invadableCities[1][33] = true;
        _invadableCities[2][63] = true;
        _invadableCities[2][21] = true;
        _invadableCities[2][44] = true;
        _invadableCities[2][46] = true;
        _invadableCities[2][27] = true;
        _invadableCities[3][32] = true;
        _invadableCities[3][42] = true;
        _invadableCities[3][26] = true;
        _invadableCities[3][43] = true;
        _invadableCities[3][64] = true;
        _invadableCities[3][20] = true;
        _invadableCities[3][15] = true;
        _invadableCities[4][65] = true;
        _invadableCities[4][76] = true;
        _invadableCities[4][36] = true;
        _invadableCities[4][25] = true;
        _invadableCities[4][49] = true;
        _invadableCities[4][13] = true;
        _invadableCities[5][66] = true;
        _invadableCities[5][60] = true;
        _invadableCities[5][55] = true;
        _invadableCities[5][19] = true;
        _invadableCities[6][42] = true;
        _invadableCities[6][68] = true;
        _invadableCities[6][40] = true;
        _invadableCities[6][71] = true;
        _invadableCities[6][18] = true;
        _invadableCities[6][14] = true;
        _invadableCities[6][26] = true;
        _invadableCities[6][3] = true;
        _invadableCities[7][33] = true;
        _invadableCities[7][70] = true;
        _invadableCities[7][42] = true;
        _invadableCities[7][32] = true;
        _invadableCities[7][15] = true;
        _invadableCities[7][48] = true;
        _invadableCities[8][53] = true;
        _invadableCities[8][25] = true;
        _invadableCities[8][75] = true;
        _invadableCities[9][48] = true;
        _invadableCities[9][20] = true;
        _invadableCities[9][45] = true;
        _invadableCities[9][35] = true;
        _invadableCities[10][35] = true;
        _invadableCities[10][45] = true;
        _invadableCities[10][43] = true;
        _invadableCities[10][16] = true;
        _invadableCities[10][17] = true;
        _invadableCities[11][43] = true;
        _invadableCities[11][26] = true;
        _invadableCities[11][14] = true;
        _invadableCities[11][54] = true;
        _invadableCities[11][16] = true;
        _invadableCities[12][21] = true;
        _invadableCities[12][49] = true;
        _invadableCities[12][25] = true;
        _invadableCities[12][24] = true;
        _invadableCities[12][62] = true;
        _invadableCities[12][23] = true;
        _invadableCities[13][56] = true;
        _invadableCities[13][65] = true;
        _invadableCities[13][4] = true;
        _invadableCities[13][49] = true;
        _invadableCities[13][72] = true;
        _invadableCities[14][26] = true;
        _invadableCities[14][6] = true;
        _invadableCities[14][18] = true;
        _invadableCities[14][67] = true;
        _invadableCities[14][81] = true;
        _invadableCities[14][54] = true;
        _invadableCities[14][11] = true;
        _invadableCities[15][48] = true;
        _invadableCities[15][7] = true;
        _invadableCities[15][32] = true;
        _invadableCities[15][3] = true;
        _invadableCities[15][20] = true;
        _invadableCities[16][10] = true;
        _invadableCities[16][43] = true;
        _invadableCities[16][11] = true;
        _invadableCities[16][54] = true;
        _invadableCities[16][41] = true;
        _invadableCities[16][77] = true;
        _invadableCities[17][10] = true;
        _invadableCities[17][59] = true;
        _invadableCities[17][22] = true;
        _invadableCities[18][6] = true;
        _invadableCities[18][71] = true;
        _invadableCities[18][19] = true;
        _invadableCities[18][37] = true;
        _invadableCities[18][67] = true;
        _invadableCities[18][14] = true;
        _invadableCities[18][78] = true;
        _invadableCities[19][66] = true;
        _invadableCities[19][5] = true;
        _invadableCities[19][55] = true;
        _invadableCities[19][57] = true;
        _invadableCities[19][37] = true;
        _invadableCities[19][18] = true;
        _invadableCities[19][71] = true;
        _invadableCities[20][48] = true;
        _invadableCities[20][15] = true;
        _invadableCities[20][3] = true;
        _invadableCities[20][64] = true;
        _invadableCities[20][45] = true;
        _invadableCities[20][9] = true;
        _invadableCities[21][63] = true;
        _invadableCities[21][47] = true;
        _invadableCities[21][72] = true;
        _invadableCities[21][49] = true;
        _invadableCities[21][12] = true;
        _invadableCities[21][23] = true;
        _invadableCities[21][44] = true;
        _invadableCities[21][2] = true;
        _invadableCities[22][17] = true;
        _invadableCities[22][59] = true;
        _invadableCities[22][71] = true;
        _invadableCities[23][21] = true;
        _invadableCities[23][12] = true;
        _invadableCities[23][62] = true;
        _invadableCities[23][24] = true;
        _invadableCities[23][44] = true;
        _invadableCities[24][23] = true;
        _invadableCities[24][62] = true;
        _invadableCities[24][12] = true;
        _invadableCities[24][25] = true;
        _invadableCities[24][69] = true;
        _invadableCities[24][29] = true;
        _invadableCities[24][28] = true;
        _invadableCities[24][58] = true;
        _invadableCities[24][44] = true;
        _invadableCities[25][12] = true;
        _invadableCities[25][49] = true;
        _invadableCities[25][4] = true;
        _invadableCities[25][36] = true;
        _invadableCities[25][75] = true;
        _invadableCities[25][8] = true;
        _invadableCities[25][53] = true;
        _invadableCities[25][61] = true;
        _invadableCities[25][69] = true;
        _invadableCities[25][24] = true;
        _invadableCities[26][3] = true;
        _invadableCities[26][42] = true;
        _invadableCities[26][6] = true;
        _invadableCities[26][14] = true;
        _invadableCities[26][11] = true;
        _invadableCities[26][43] = true;
        _invadableCities[27][79] = true;
        _invadableCities[27][63] = true;
        _invadableCities[27][2] = true;
        _invadableCities[27][46] = true;
        _invadableCities[27][80] = true;
        _invadableCities[27][31] = true;
        _invadableCities[28][29] = true;
        _invadableCities[28][61] = true;
        _invadableCities[28][24] = true;
        _invadableCities[28][58] = true;
        _invadableCities[28][52] = true;
        _invadableCities[29][24] = true;
        _invadableCities[29][69] = true;
        _invadableCities[29][61] = true;
        _invadableCities[29][28] = true;
        _invadableCities[30][65] = true;
        _invadableCities[30][73] = true;
        _invadableCities[31][79] = true;
        _invadableCities[31][27] = true;
        _invadableCities[31][80] = true;
        _invadableCities[31][1] = true;
        _invadableCities[32][7] = true;
        _invadableCities[32][42] = true;
        _invadableCities[32][3] = true;
        _invadableCities[32][15] = true;
        _invadableCities[33][1] = true;
        _invadableCities[33][51] = true;
        _invadableCities[33][42] = true;
        _invadableCities[33][70] = true;
        _invadableCities[33][7] = true;
        _invadableCities[34][41] = true;
        _invadableCities[34][59] = true;
        _invadableCities[34][39] = true;
        _invadableCities[35][9] = true;
        _invadableCities[35][45] = true;
        _invadableCities[35][10] = true;
        _invadableCities[36][4] = true;
        _invadableCities[36][76] = true;
        _invadableCities[36][75] = true;
        _invadableCities[36][25] = true;
        _invadableCities[37][19] = true;
        _invadableCities[37][57] = true;
        _invadableCities[37][18] = true;
        _invadableCities[37][74] = true;
        _invadableCities[37][78] = true;
        _invadableCities[38][1] = true;
        _invadableCities[38][46] = true;
        _invadableCities[38][58] = true;
        _invadableCities[38][66] = true;
        _invadableCities[38][50] = true;
        _invadableCities[38][51] = true;
        _invadableCities[39][22] = true;
        _invadableCities[39][59] = true;
        _invadableCities[39][34] = true;
        _invadableCities[40][50] = true;
        _invadableCities[40][66] = true;
        _invadableCities[40][71] = true;
        _invadableCities[40][6] = true;
        _invadableCities[40][68] = true;
        _invadableCities[41][77] = true;
        _invadableCities[41][34] = true;
        _invadableCities[41][16] = true;
        _invadableCities[41][11] = true;
        _invadableCities[41][54] = true;
        _invadableCities[42][7] = true;
        _invadableCities[42][70] = true;
        _invadableCities[42][33] = true;
        _invadableCities[42][51] = true;
        _invadableCities[42][68] = true;
        _invadableCities[42][6] = true;
        _invadableCities[42][26] = true;
        _invadableCities[42][3] = true;
        _invadableCities[42][63] = true;
        _invadableCities[43][45] = true;
        _invadableCities[43][64] = true;
        _invadableCities[43][3] = true;
        _invadableCities[43][26] = true;
        _invadableCities[43][11] = true;
        _invadableCities[43][16] = true;
        _invadableCities[43][10] = true;
        _invadableCities[44][46] = true;
        _invadableCities[44][2] = true;
        _invadableCities[44][21] = true;
        _invadableCities[44][23] = true;
        _invadableCities[44][24] = true;
        _invadableCities[44][58] = true;
        _invadableCities[45][35] = true;
        _invadableCities[45][9] = true;
        _invadableCities[45][20] = true;
        _invadableCities[45][64] = true;
        _invadableCities[45][43] = true;
        _invadableCities[45][10] = true;
        _invadableCities[46][27] = true;
        _invadableCities[46][2] = true;
        _invadableCities[46][44] = true;
        _invadableCities[46][58] = true;
        _invadableCities[46][38] = true;
        _invadableCities[46][6] = true;
        _invadableCities[46][80] = true;
        _invadableCities[47][63] = true;
        _invadableCities[47][21] = true;
        _invadableCities[47][72] = true;
        _invadableCities[47][56] = true;
        _invadableCities[47][73] = true;
        _invadableCities[48][7] = true;
        _invadableCities[48][15] = true;
        _invadableCities[48][20] = true;
        _invadableCities[48][9] = true;
        _invadableCities[49][21] = true;
        _invadableCities[49][72] = true;
        _invadableCities[49][13] = true;
        _invadableCities[49][4] = true;
        _invadableCities[49][25] = true;
        _invadableCities[49][12] = true;
        _invadableCities[50][51] = true;
        _invadableCities[50][38] = true;
        _invadableCities[50][66] = true;
        _invadableCities[50][40] = true;
        _invadableCities[50][68] = true;
        _invadableCities[51][50] = true;
        _invadableCities[51][38] = true;
        _invadableCities[51][6] = true;
        _invadableCities[51][33] = true;
        _invadableCities[51][42] = true;
        _invadableCities[51][68] = true;
        _invadableCities[52][35] = true;
        _invadableCities[52][9] = true;
        _invadableCities[52][64] = true;
        _invadableCities[52][20] = true;
        _invadableCities[52][43] = true;
        _invadableCities[52][10] = true;
        _invadableCities[53][8] = true;
        _invadableCities[53][25] = true;
        _invadableCities[53][69] = true;
        _invadableCities[53][61] = true;
        _invadableCities[54][81] = true;
        _invadableCities[54][14] = true;
        _invadableCities[54][11] = true;
        _invadableCities[54][16] = true;
        _invadableCities[54][41] = true;
        _invadableCities[55][52] = true;
        _invadableCities[55][60] = true;
        _invadableCities[55][5] = true;
        _invadableCities[55][19] = true;
        _invadableCities[55][57] = true;
        _invadableCities[56][65] = true;
        _invadableCities[56][13] = true;
        _invadableCities[56][72] = true;
        _invadableCities[56][47] = true;
        _invadableCities[56][73] = true;
        _invadableCities[57][55] = true;
        _invadableCities[57][19] = true;
        _invadableCities[57][37] = true;
        _invadableCities[58][38] = true;
        _invadableCities[58][49] = true;
        _invadableCities[58][44] = true;
        _invadableCities[58][24] = true;
        _invadableCities[58][28] = true;
        _invadableCities[58][52] = true;
        _invadableCities[58][60] = true;
        _invadableCities[58][66] = true;
        _invadableCities[59][34] = true;
        _invadableCities[59][39] = true;
        _invadableCities[59][22] = true;
        _invadableCities[59][17] = true;
        _invadableCities[60][58] = true;
        _invadableCities[60][52] = true;
        _invadableCities[60][55] = true;
        _invadableCities[60][5] = true;
        _invadableCities[60][66] = true;
        _invadableCities[61][53] = true;
        _invadableCities[61][69] = true;
        _invadableCities[61][29] = true;
        _invadableCities[61][28] = true;
        _invadableCities[62][23] = true;
        _invadableCities[62][12] = true;
        _invadableCities[62][24] = true;
        _invadableCities[63][27] = true;
        _invadableCities[63][2] = true;
        _invadableCities[63][21] = true;
        _invadableCities[63][47] = true;
        _invadableCities[64][45] = true;
        _invadableCities[64][20] = true;
        _invadableCities[64][3] = true;
        _invadableCities[64][43] = true;
        _invadableCities[65][30] = true;
        _invadableCities[65][73] = true;
        _invadableCities[65][56] = true;
        _invadableCities[65][13] = true;
        _invadableCities[65][4] = true;
        _invadableCities[66][38] = true;
        _invadableCities[66][58] = true;
        _invadableCities[66][60] = true;
        _invadableCities[66][5] = true;
        _invadableCities[66][19] = true;
        _invadableCities[66][71] = true;
        _invadableCities[66][40] = true;
        _invadableCities[66][50] = true;
        _invadableCities[67][74] = true;
        _invadableCities[67][18] = true;
        _invadableCities[67][14] = true;
        _invadableCities[67][81] = true;
        _invadableCities[67][78] = true;
        _invadableCities[68][51] = true;
        _invadableCities[68][50] = true;
        _invadableCities[68][40] = true;
        _invadableCities[68][6] = true;
        _invadableCities[68][42] = true;
        _invadableCities[69][24] = true;
        _invadableCities[69][25] = true;
        _invadableCities[69][53] = true;
        _invadableCities[69][61] = true;
        _invadableCities[69][29] = true;
        _invadableCities[70][33] = true;
        _invadableCities[70][42] = true;
        _invadableCities[70][7] = true;
        _invadableCities[71][40] = true;
        _invadableCities[71][66] = true;
        _invadableCities[71][19] = true;
        _invadableCities[71][18] = true;
        _invadableCities[71][6] = true;
        _invadableCities[72][47] = true;
        _invadableCities[72][56] = true;
        _invadableCities[72][13] = true;
        _invadableCities[72][49] = true;
        _invadableCities[72][21] = true;
        _invadableCities[73][47] = true;
        _invadableCities[73][56] = true;
        _invadableCities[73][65] = true;
        _invadableCities[73][30] = true;
        _invadableCities[74][37] = true;
        _invadableCities[74][67] = true;
        _invadableCities[74][78] = true;
        _invadableCities[75][25] = true;
        _invadableCities[75][36] = true;
        _invadableCities[75][8] = true;
        _invadableCities[76][4] = true;
        _invadableCities[76][36] = true;
        _invadableCities[77][41] = true;
        _invadableCities[77][16] = true;
        _invadableCities[78][67] = true;
        _invadableCities[78][74] = true;
        _invadableCities[78][37] = true;
        _invadableCities[78][18] = true;
        _invadableCities[79][27] = true;
        _invadableCities[79][31] = true;
        _invadableCities[80][27] = true;
        _invadableCities[80][46] = true;
        _invadableCities[80][1] = true;
        _invadableCities[80][31] = true;
        _invadableCities[81][67] = true;
        _invadableCities[81][13] = true;
        _invadableCities[81][54] = true;
    }
}