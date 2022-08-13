/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

pragma solidity ^0.8.12;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)
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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)
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

/*
__________              __   .__                 .___             
\______   \__ __  ____ |  | _|__| __________   __| _/____   ______
 |     ___/  |  \/    \|  |/ /  |/  ___/  _ \ / __ |/ __ \ /  ___/
 |    |   |  |  /   |  \    <|  |\___ (  <_> ) /_/ \  ___/ \___ \ 
 |____|   |____/|___|  /__|_ \__/____  >____/\____ |\___  >____  >
                     \/     \/       \/           \/    \/     \/ 
*/
interface IPunksData {
    function punkImageSvg(uint16 index) external view returns (string memory svg);
}

interface ICryptoPunks {
    function punkIndexToAddress(uint256) external view returns (address);
}

contract WenLunchBox is ERC721, Ownable {

    address punkContractAddress;
    address punkImagesContractAddress;
    uint256 immutable MAX_SUPPLY;
    uint256 counter = 0;
    string constant LUNCHBOX_IMAGE = '<path d="M23 2h6m-9 1h3m6 0h3M16 4h4m12 0h2M13 5h3m18 0h3M10 6h3m24 0h2M7 7h3m29 0h2M4 8h3m34 0h2M2 9h2m39 0h2M1 10h1m43 0h3M1 11h1m46 0h2M1 12h2m47 0h2M1 13h1m1 0h1m48 0h2M1 14h1m2 0h1m49 0h2M1 15h1m3 0h1m50 0h2M2 16h1m3 0h2m50 0h2M3 17h2m3 0h1m51 0h1M3 18h1m1 0h1m3 0h1m50 0h1M3 19h1m2 0h1m3 0h1m49 0h1M3 20h1m3 0h1m3 0h2m46 0h2M3 21h1m4 0h1m4 0h1m43 0h2m1 0h1M3 22h1m5 0h2m3 0h1m40 0h2m3 0h1M3 23h1m7 0h1m3 0h2m36 0h2m5 0h1M4 24h1m7 0h1m4 0h1m33 0h2m7 0h1M5 25h1m7 0h2m3 0h1m30 0h2m8 0h1M6 26h1m8 0h1m3 0h2m26 0h2m9 0h1M7 27h1m8 0h1m4 0h1m23 0h2m9 0h3M8 28h1m8 0h1m4 0h1m20 0h2m9 0h2m2 0h1M9 29h2m7 0h2m3 0h2m16 0h2m9 0h2m4 0h1m-48 1h1m8 0h1m4 0h1m13 0h2m9 0h2m6 0h1m-47 1h1m8 0h1m4 0h2m9 0h2m9 0h2m8 0h1m-46 1h1m8 0h1m5 0h9m9 0h2m10 0h1m-45 1h1m8 0h2m19 0h2m12 0h1m-44 1h2m8 0h1m16 0h2m13 0h1m-41 1h1m8 0h1m13 0h2m13 0h2m-39 1h1m8 0h2m8 0h3m13 0h2m-36 1h1m9 0h8m14 0h2m-33 1h2m28 0h1m-29 1h1m25 0h2m-27 1h1m22 0h2m-24 1h1m19 0h2m-21 1h1m17 0h1m-18 1h2m13 0h2m-15 1h1m10 0h2m-12 1h2m6 0h2m-8 1h6" stroke="#000"/><path d="m23 3h6m-9 1h1m-5 1h1m-4 1h1m-4 1h1m-9 3h1m-1 1h1m1 1h1m2 2h1m0 1h1m47 16h1m-1 1h1m-9 3h1m-3 1h1" stroke="#cfc4ae"/><path d="M21 4h1m9 0h1M17 5h2m14 0h1M14 6h1m2 0h1m3 0h1m14 0h1M24 7h1m13 0h1M7 8h1m3 0h1m3 0h1m24 0h1M4 9h1m14 0h1M7 10h1m5 0h1M3 11h1m5 0h1m-5 1h1m4 0h1m-6 1h2m3 3h1m0 1h1m0 1h1m42 13h1m-3 1h3m-5 1h5m-7 1h6m-8 1h1m1 0h4m-6 1h4m-7 1h5m-7 1h1m1 0h4m-7 1h1m1 0h1m1 0h1m-5 1h1m1 0h1m-5 1h1m2 0h1m-3 1h1" stroke="#bfb8a7"/><path d="M22 4h9M19 5h14M15 6h2m1 0h3m1 0h14M11 7h13m1 0h13M8 8h3m1 0h3m1 0h17m1 0h1m3 0h1M5 9h14m1 0h10m1 0h1m1 0h1m1 0h3m1 0h1m2 0h1M3 10h4m1 0h5m1 0h17m1 0h1m1 0h1M4 11h5m1 0h18m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1M3 12h1m2 0h4m1 0h16m1 0h1m1 0h1m1 0h1M7 13h16m1 0h1m2 0h1m1 0h1m1 0h1m3 0h1M6 14h1m1 0h13m1 0h1m1 0h3m1 0h1m4 0h1M7 15h1m1 0h10m1 0h2m1 0h1m5 0h1M9 16h1m1 0h6m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1m-18 1h1m1 0h3m1 0h3m2 0h1m2 0h1m-12 1h1m1 0h1m1 0h1m1 0h1m2 0h1m3 0h1m-14 1h3m2 0h1m1 0h1m-6 1h3m-2 1h1m1 1h1m37 8h1m-3 1h1m-3 1h1m-3 1h1m-24 1h1m17 2h1m-3 1h1" stroke="#b2a898"/><path d="M33 8h1m1 0h3m1 0h1M30 9h1m1 0h1m1 0h1m3 0h1m1 0h2m-11 1h1m1 0h1m1 0h9m-16 1h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h6m-19 1h1m1 0h1m1 0h1m1 0h16m-26 1h1m1 0h2m1 0h1m1 0h1m1 0h3m1 0h8m1 0h1m1 0h1m2 0h1m-30 1h1m1 0h1m3 0h1m1 0h4m1 0h9m1 0h1m1 0h1m2 0h1m-31 1h1m2 0h1m1 0h5m1 0h11m1 0h2m1 0h1m1 0h1m-31 1h1m2 0h1m1 0h1m1 0h1m1 0h1m1 0h10m1 0h1m1 0h1m-27 1h1m3 0h2m1 0h2m1 0h11m1 0h2m1 0h1m2 0h1m-30 1h1m1 0h1m1 0h1m1 0h2m1 0h3m1 0h5m1 0h1m1 0h1m3 0h1m-24 1h2m1 0h1m1 0h5m1 0h3m1 0h3m1 0h1m1 0h1m-20 1h14m2 0h1m1 0h1m-20 1h11m1 0h1m1 0h1m1 0h1m4 0h1m-22 1h1m1 0h4m1 0h2m1 0h1m2 0h1m-12 1h6m1 0h1m1 0h1m2 0h1m-12 1h4m1 0h1m3 0h1m-8 1h1m1 0h1m2 0h1m-4 1h1m0 1h1m23 0h1m1 1h1m-3 1h1m-8 1h1m4 0h1m-8 1h1m4 0h1m-9 1h2m4 0h1m-16 1h1m1 0h1m1 0h4m1 0h2m2 0h1m-12 1h1m1 0h1m3 0h1m2 0h2m-12 1h8m1 0h1m0 4h1m-11 1h3m3 0h2" stroke="#9c9d9d"/><path d="M44 10h1m1 1h2m1 1h1m1 1h1m1 1h1m1 1h1M5 21h2m-2 1h3m-3 1h5m-1 1h2m-5 1h3m1 0h2m-5 1h2m1 0h3m-5 1h2m2 0h1m-3 1h2m1 0h2m-4 1h1m1 0h1m1 0h1m-2 1h3m-4 1h1m2 0h2m-3 1h1m2 0h1m-3 1h2m1 0h1m-3 1h2m1 0h2m-4 1h2m1 0h1m15 0h1m-19 1h2m1 0h2m-3 1h1m2 0h1m-3 1h4m15 0h1m-19 1h1m1 0h2m-3 1h1m2 0h1m9 0h1m4 0h1m-17 1h2m12 0h1m-14 1h2m10 0h1" stroke="#9fa7b1"/><path d="m2 13h1m-1 2h1m1 0h1m1 0h1m3 3h1m0 1h1m-4 1h1m0 1h1m4 0h1m0 1h1m41 0h1m-41 1h1m0 1h1m40 0h1m-2 1h1m-2 1h1m-3 1h1m-3 1h1m-27 7h1m1 1h1" stroke="#5f6266"/><path d="m4 13h1m39 3h1m2 1h1m-16 1h1m3 0h1m4 0h1m-16 1h1m3 0h1m8 0h1m-26 1h1m27 1h1m-20 1h1m4 0h1m4 0h1m1 0h1m-18 1h1m6 0h1m-12 1h1m13 1h1m23 0h1m-22 1h1m18 0h2m-5 1h2m1 0h1m1 0h2m-35 1h1m25 0h6m1 0h1m-33 1h2m21 0h6m1 0h1m5 0h1m-35 1h1m20 0h4m1 0h1m4 0h2m-32 1h1m15 0h1m1 0h4m1 0h1m5 0h2m-30 1h4m11 0h4m1 0h1m4 0h2m-26 1h3m1 0h1m1 0h1m4 0h1m2 0h2m1 0h1m5 0h1m-21 1h1m4 0h2m2 0h1m8 0h1m1 0h1m-21 1h1m15 0h1m1 0h1m-14 1h2m7 0h3m-6 1h2m1 0h1m-5 1h1m1 0h1m-10 1h1m1 0h1m1 0h1m1 0h1m-6 1h1m1 0h1" stroke="#959089"/><path d="M44 13h1m1 0h1m1 0h2m-7 1h1m1 0h1m1 0h2m1 0h3m-12 1h1m2 0h1m1 0h1m1 0h7m-17 1h1m1 0h1m1 0h2m1 0h13m-22 1h1m2 0h1m1 0h2m1 0h3m1 0h6m1 0h4m-25 1h1m2 0h2m1 0h1m1 0h14m1 0h2m-25 1h1m1 0h1m1 0h1m1 0h10m1 0h1m1 0h5m-26 1h2m1 0h1m1 0h10m1 0h6m1 0h2m-29 1h1m1 0h1m1 0h1m1 0h4m1 0h3m1 0h8m1 0h3m-29 1h1m2 0h1m1 0h2m1 0h1m1 0h9m1 0h2m1 0h4m-26 1h1m1 0h2m1 0h11m1 0h5M6 24h3m15 0h1m1 0h3m1 0h10m1 0h5m1 0h1M9 25h1m11 0h1m1 0h1m1 0h2m2 0h9m1 0h3m1 0h4M9 26h1m13 0h1m1 0h6m1 0h4m1 0h8m-35 1h2m1 0h1m10 0h1m1 0h8m1 0h4m1 0h1m1 0h2m-32 1h1m13 0h6m1 0h4m1 0h3m-29 1h1m1 0h1m1 0h1m10 0h13m-27 1h1m3 0h1m13 0h4m1 0h1m-23 1h2m2 0h1m-3 1h2m1 0h1m-2 1h1m1 0h1m-2 1h1m9 0h1m1 0h1m3 0h1m2 0h1m-19 1h1m1 0h1m-2 1h1m0 1h2m0 2h1m2 0h1m4 0h1m1 0h1m3 0h1m-14 1h2m6 0h1" stroke="#8a94a1"/><path d="m2 14h2m-1 2h3m0 1h2m-2 1h3m-2 1h1m1 0h1m0 1h1m2 0h1m-3 1h2m46 0h1m-48 1h1m3 0h1m41 0h2m-48 1h1m1 0h1m40 0h5m-47 1h1m1 0h1m37 0h1m2 0h2m-38 1h1m34 0h1m0 1h1m-34 1h1m-6 1h1m32 1h1m-3 1h1m-31 1h1m27 0h1m-25 1h1m21 0h1m-3 1h1m-21 1h1m17 0h1m-18 1h1m5 1h1m-5 1h1m0 1h1" stroke="#737477"/><path d="m5 14h1m2 2h1m0 1h1m1 1h1m0 1h1m3 5h1m2 0h1m34 0h2m2 0h1m-43 1h2m33 0h1m1 0h2m1 0h2m-42 1h1m1 0h1m3 0h1m26 0h1m2 0h4m-39 1h4m33 0h1m-35 1h2m0 1h1m-2 1h1m1 0h2m16 0h1m13 0h1m-34 1h1m1 0h2m25 1h1m-3 1h1m-24 1h1m20 0h1m-9 1h1m5 0h1m-15 1h1m4 0h1m4 1h1" stroke="#88837a"/><path d="M3 15h1m1 2h1m48 0h1m1 1h1M4 19h1m3 0h1m41 0h1m1 0h1M4 20h1m4 0h1m37 0h1m6 0h1M4 21h1m5 0h1m4 0h1m35 0h1M4 22h1m6 0h1m1 0h1m31 0h1m2 0h1m-36 1h1m29 0h1m5 0h1m-10 1h1m5 0h1m-32 1h1m22 0h1m3 0h1m-30 1h1m3 0h1m18 0h1m-23 1h1m19 0h1m4 0h1m1 0h1m9 0h1m-37 1h1m9 0h1m6 0h1m4 0h1m-12 1h1m28 0h1m-38 1h1m9 0h3m4 0h1m15 1h1m-32 1h1m0 1h1m25 0h1m8 0h1m-35 1h1m22 0h1m-23 1h1m19 0h1m9 0h1m-30 1h2m6 0h1m2 0h1m5 0h1m9 0h1m-27 1h1m1 0h1m21 0h1m-24 1h1m1 0h1m8 0h1m1 0h1m8 0h1m-21 1h3m5 0h1m9 0h1m-3 1h1m-4 2h1m-14 1h1m10 0h1m-10 1h1m6 0h1" stroke="#7e8590"/><path d="M59 17h1M4 18h1m54 0h1M5 19h1m52 0h2M6 20h1m50 0h2M7 21h1m47 0h2M8 22h1m44 0h2M4 23h1m5 0h1m39 0h3m-42 1h1m36 0h3m-39 1h1m6 0h1m27 0h2m-35 1h1m6 0h1m23 0h2m-32 1h1m6 0h1m21 0h1M9 28h1m6 0h1m6 0h2m16 0h2m13 0h2m-41 1h1m7 0h1m14 0h1m13 0h1m2 0h1m-39 1h1m6 0h2m9 0h2m13 0h1m4 0h1m-38 1h1m7 0h9m13 0h1m6 0h1m-37 1h1m26 0h1m8 0h1m-43 1h1m6 0h1m23 0h1m10 0h1m-34 1h1m19 0h1m10 0h2m-32 1h1m16 0h1m11 0h1m-29 1h1m13 0h1m11 0h1m-33 1h1m7 0h1m8 0h2m11 0h1m-22 1h8m12 0h1m-3 1h1m-3 1h1m-3 1h1m-18 1h1m15 0h1m-3 1h1m-12 1h1m8 0h1m-8 1h6" stroke="#40565f"/><path d="m5 20h1m-1 4h1m6 6h1m1 2h1m28 6h1m-4 1h1m1 0h1m1 0h1m-17 1h1m9 0h3m-16 1h1m2 0h2m1 0h5m2 0h1m2 0h1m-13 1h3m1 0h1m1 0h4m-10 1h10m-8 1h5" stroke="#b4b5b8"/><path d="m30 41h1m5 0h2m-6 1h1m1 0h1m1 2h1" stroke="#c2c3c4"/>';
    
    mapping(uint256=>uint256) public tokenIdToPunkMapping;
    mapping(uint256=>bool) public claimedPunks;

    constructor(address _punkContractAddress, address _punkImagesAddress, uint256 _maxSupply) ERC721("Punkisodes Wen LunchBox", "PNKL") Ownable() {
    	setPunkContractAddresses(_punkContractAddress, _punkImagesAddress);
        MAX_SUPPLY = _maxSupply;
    }

    function setPunkContractAddresses(address _punkContractAddress, address _punkImagesAddress) public onlyOwner {
        punkContractAddress = _punkContractAddress;
        punkImagesContractAddress = _punkImagesAddress;
    }

    function isPunkOwner(address expectedOwner, uint256 punkId) public view returns (bool) {
	     return expectedOwner == ICryptoPunks(punkContractAddress).punkIndexToAddress(punkId);
    }
    
    function getPunkImage(uint16 punkId) public view returns (string memory) {
	     return IPunksData(punkImagesContractAddress).punkImageSvg(punkId);
    }

    function mint(uint256 punkId) external {
        require(counter<MAX_SUPPLY, "tooo late");
        require(isPunkOwner(msg.sender, punkId), "not ur punk");
        require(!claimedPunks[punkId],"u greedie b*st*rd");
        uint256 tokenId = counter;
        counter++;
        tokenIdToPunkMapping[tokenId] = punkId;
        claimedPunks[punkId] = true;
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    base64Encode(
                        bytes(abi.encodePacked(
                                '{"name": "Wen lunchbox? nr ', Strings.toString(tokenId), '",'  ,
                                '"attributes": [{"trait_type" : "punk","value":"',Strings.toString(tokenIdToPunkMapping[tokenId]),'"}]',
                                ', "description":"','Wen lunchbox? for punk nr ', Strings.toString(tokenIdToPunkMapping[tokenId]),'.  Not affiliated with LarvaLabs!'
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                base64Encode(
                                        bytes(
                                            abi.encodePacked(
                                                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 62 50" shape-rendering="crispEdges" style="background-color:4F8294">',
                                                LUNCHBOX_IMAGE,
                                                '<g transform="translate(6 13) skewX(55) skewY(-15) scale(1.8,0.7)" opacity="0.8">',
                                                stripSvgTag(75, 6, getPunkImage(uint16(tokenIdToPunkMapping[tokenId]))),
                                                '</g>',
                                                '</svg>'
                                            )
                                        )
                                    ),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function drain() public onlyOwner {
	    payable(owner()).transfer(address(this).balance);
    }

    function link(uint tokenId, uint256 punkId) public payable {
        require(msg.sender==ownerOf(tokenId), "not ur lunchbox");
        require(isPunkOwner(msg.sender, punkId), "not ur punk");
        require(!claimedPunks[punkId], "already ur");
        require(msg.value >= 3.690 ether, "must pay 3.690 eth at minimum");

        //unclaim current punk
        claimedPunks[tokenIdToPunkMapping[tokenId]] = false;
        //link new punk
        tokenIdToPunkMapping[tokenId] = punkId;
        //claim again
        claimedPunks[punkId] = true;
    }


    /** 
     * @dev walletofOwner
     * @return tokens id owned by the given address
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function walletOfOwner(address queryAddress) external view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(queryAddress);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        //index starting at 0
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while ( ownedTokenIndex < ownerTokenCount && currentTokenId <= counter/*.current()*/ ) {
            if (ownerOf(currentTokenId) == queryAddress) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                unchecked{ ownedTokenIndex++;}
            }
            unchecked{ currentTokenId++;}
        }
        return ownedTokenIds;
    }

    function stringLen(string memory s) public pure returns (uint256) {
        return bytes(s).length;
    }

    function stripSvgTag(uint256 begin, uint256 last,string memory text) public pure returns (string memory) {
        uint256 end = stringLen(text);
        //last = 6 = strip </svg> from end
        bytes memory a = new bytes(end-begin+1-last);
        for(uint i=0;i<=end-begin-last;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // [MIT License]
    // @author Brecht Devos <[email protected]>
    function base64Encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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