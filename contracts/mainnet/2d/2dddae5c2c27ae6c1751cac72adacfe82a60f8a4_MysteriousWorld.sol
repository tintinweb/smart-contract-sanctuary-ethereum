/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
// # MysteriousWorld
// Read more at https://www.themysterious.world/utility

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
        require(operator != _msgSender(), "ERC721: approve to caller");

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// The Creature World and Superlative Secret Society is used so we check who holds a nft
// for the free mint claim system
interface Creature {
    function ownerOf(uint256 token) external view returns(address);
    function tokenOfOwnerByIndex(address inhabitant, uint256 index) external view returns(uint256);
    function balanceOf(address inhabitant) external view returns(uint256);
}

interface Superlative {
    function ownerOf(uint256 token) external view returns(address);
    function tokenOfOwnerByIndex(address inhabitant, uint256 index) external view returns(uint256);
    function balanceOf(address inhabitant) external view returns(uint256);
}

// The runes contract is used to burn for sacrifices and update balances on transfers
interface IRunes {
    function burn(address inhabitant, uint256 cost) external;
    function updateRunes(address from, address to) external;
}

// Allows us to mint with $LOOKS instead of ETH
interface Looks {
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address owner) external view returns(uint256);
}

/*
 * o               .        ___---___                    .                   
 *        .              .--\        --.     .     .         .
 *                     ./.;_.\     __/~ \.     
 *                    /;  / `-'  __\    . \                            
 *  .        .       / ,--'     / .   .;   \        |
 *                  | .|       /       __   |      -O-       .
 *                 |__/    __ |  . ;   \ | . |      |
 *                 |      /  \\_    . ;| \___|    
 *    .    o       |      \  .~\\___,--'     |           .
 *                  |     | . ; ~~~~\_    __|
 *     |             \    \   .  .  ; \  /_/   .
 *    -O-        .    \   /         . |  ~/                  .
 *     |    .          ~\ \   .      /  /~          o
 *   .                   ~--___ ; ___--~       
 *                  .          ---         .   MYSTERIOUS WORLD
 */
contract MysteriousWorld is ERC721, Ownable {
    using Address  for address;
    using Counters for Counters.Counter;

    Counters.Counter private Population;
    Counters.Counter private sacrificed; // tracks the amount of rituals performed
    Counters.Counter private sacred; // tracks the 1/1s created from rituals

    Creature public creature;
    Superlative public superlative;
    IRunes public runes;
    Looks public looks;

    string private baseURI;

    uint256 constant public maxInhabitants  = 6666;
    uint256 constant public maxRituals      = 3333; // max amount of rituals that can be performed
    uint256 constant public teamInhabitants = 66; // the amount of inhabitants that will be reserved to the teams wallet
    uint256 constant public maxWInhabitants = 900; // the amount of free inhabitants given to the community
    uint256 constant public maxFInhabitants = 100; // the amount of free inhabitants given to holders of superlative & creatureworld - fcfs basis
    uint256 constant public maxPerTxn       = 6;

    uint256 public whitelistInhabitantsClaimed; // tracks the amount of mints claimed from giveaway winners
    uint256 public freeInhabitantsClaimed; // tracks the amount of free mints claimed from superlative & creatureworld holders
    uint256 public teamInhabitantsClaimed; // tracks the amount reserved for the team wallet
    uint256 public saleActive = 0; // the period for when public mint starts
    uint256 public claimActive = 0; // the period for free mint claiming - once the claimActive timestamp is reached, remaing supply goes to public fcfs

    uint256 public mintPrice   = 0.06 ether;
    uint256 public ritualPrice = 100 ether; // base price for rituals is 100 $RUNES
    uint256 public ritualRate  = 0.5 ether; // the rate increases the ritualPrice by the amount of rituals performed
    address public ritualWallet; // where the ritualized tokens go when u perform a ritual on them
    uint256 public looksPrice = 37 ether; // will be updated once contract is deployed if price difference is to high
    address public looksWallet;

    bool public templeAvailable = false; // once revealed, the temple will be available for rituals to be performed

    mapping(uint256 => bool)    public ritualizedInhabitants; // tracks the tokens that survived the ritual process
    mapping(uint256 => bool)    public uniqueInhabitants; // tracks the tokens that became gods
    mapping(address => uint256) public claimedW; // tracks to see what wallets claimed their whitelisted free mints
    mapping(address => uint256) public claimedF; // tracks to see what wallets claimed the free mints for the superlative & creatureworld

    event performRitualEvent(address caller, uint256 vessel, uint256 sacrifice);
    event performSacredRitualEvent(address caller, uint256 vessel, uint256 sacrifice);

    /*
     * # isTempleOpen
     * only allows you to perform a ritual if its enabled - this will be set after reveal
     */
    modifier isTempleOpen() {
        require(templeAvailable, "The temple is not ready yet");
        _;
    }

    /*
     * # inhabitantOwner
     * checks if you own the tokens your sacrificing
     */
    modifier inhabitantOwner(uint256 inhabitant) {
        require(ownerOf(inhabitant) == msg.sender, "You can't use another persons inhabitants");
        _;
    }

    /*
     * # ascendedOwner
     * checks if the inhabitant passed is ascended
     */
    modifier ascendedOwner(uint256 inhabitant) {
        require(ritualizedInhabitants[inhabitant], "This inhabitant needs to sacrifice another inhabitant to ascend");
        _;
    }

    /*
     * # isSaleActive
     * allows inhabitants to be sold...
     */
    modifier isSaleActive() {
        require(block.timestamp > saleActive, "Inhabitants aren't born yet");
        _;
    }

    /*
     * # isClaimActive
     * allows inhabitants to be taken for free... use this for the greater good
     */
    modifier isClaimActive() {
        require(block.timestamp < claimActive, "All inhabitants are gone");
        _;
    }

    constructor(address burner, address rare) ERC721("The Mysterious World", "The Mysterious World") {
        ritualWallet = burner;
        looksWallet = rare;
    }

    /*
     * # getAmountOfCreaturesHeld
     * returns the total amount of creature world nfts a wallet holds
     */
    function getAmountOfCreaturesHeld(address holder) public view returns(uint256) {
        return creature.balanceOf(holder);
    }

    /*
     * # getAmountOfSuperlativesHeld
     * returns the total amount of superlatives nfts a wallet holds
     */
    function getAmountOfSuperlativesHeld(address holder) public view returns(uint256) {
        return superlative.balanceOf(holder);
    }

    /*
     * # checkIfClaimedW
     * checks if the giveaway winners minted their tokens
     */
    function checkIfClaimedW(address holder) public view returns(uint256) {
        return claimedW[holder];
    }

    /*
     * # checkIfClaimedF
     * checks if the superlative and creature holders minted their free tokens
     */
    function checkIfClaimedF(address holder) public view returns(uint256) {
        return claimedF[holder];
    }

    /*
     * # addWhitelistWallets
     * adds the addresses to claimedW while setting the amount each address can claim
     */
    function addWhitelistWallets(address[] calldata winners) external payable onlyOwner {
        for (uint256 wallet;wallet < winners.length;wallet++) {
            claimedW[winners[wallet]] = 1;
        }
    }
    
    /*
     * # mint
     * mints a inhabitant - godspeed
     */
    function mint(uint256 amount) public payable isSaleActive {
        require(tx.origin == msg.sender, "Can't mint from other contracts!");
        require(amount > 0 && amount <= maxPerTxn, "Your amount must be between 1 and 6");

        if (block.timestamp <= claimActive) {
            require(Population.current() + amount <= (maxInhabitants - (maxWInhabitants + maxFInhabitants)), "Not enough inhabitants for that");
        } else {
            require(Population.current() + amount <= maxInhabitants, "Not enough inhabitants for that");
        }

        require(mintPrice * amount == msg.value, "Mint Price is not correct");
        
        for (uint256 i = 0;i < amount;i++) {
            _safeMint(msg.sender, Population.current());
            Population.increment();
        }
    }

    /*
     * # mintWhitelist
     * mints a free inhabitant from the whitelist wallets
     */
    function mintWhitelist() public payable isSaleActive isClaimActive {
        uint256 currentInhabitants = Population.current();

        require(tx.origin == msg.sender, "Can't mint from other contracts!");
        require(currentInhabitants + 1 <= maxInhabitants, "No inhabitants left");
        require(whitelistInhabitantsClaimed + 1 <= maxWInhabitants, "No inhabitants left");
        require(claimedW[msg.sender] == 1, "You don't have permission to be here outsider");

        _safeMint(msg.sender, currentInhabitants);
        
        Population.increment();
        claimedW[msg.sender] = 0;
        whitelistInhabitantsClaimed++;

        delete currentInhabitants;
    }

    /*
     * # mintFList
     * mints a free inhabitant if your holding a creature world or superlative token - can only be claimed once fcfs
     */
    function mintFList() public payable isSaleActive isClaimActive {
        uint256 currentInhabitants = Population.current();

        require(tx.origin == msg.sender, "Can't mint from other contracts!");
        require(currentInhabitants + 1 <= maxInhabitants, "No inhabitants left");
        require(freeInhabitantsClaimed + 1 <= maxFInhabitants, "No inhabitants left");
        require(getAmountOfCreaturesHeld(msg.sender) >= 1 || getAmountOfSuperlativesHeld(msg.sender) >= 1, "You don't have permission to be here outsider");
        require(claimedF[msg.sender] < 1, "You already took a inhabitant");

        _safeMint(msg.sender, currentInhabitants);

        Population.increment();
        claimedF[msg.sender] = 1;
        freeInhabitantsClaimed++;

        delete currentInhabitants;
    }

    /*
     * # mintWithLooks
     * allows you to mint with $LOOKS token - still need to pay gas :(
     */
    function mintWithLooks(uint256 amount) public payable isSaleActive {
        uint256 currentInhabitants = Population.current();

        require(tx.origin == msg.sender, "Can't mint from other contracts!");
        require(amount > 0 && amount <= maxPerTxn, "Your amount must be between 1 and 6");

        if (block.timestamp <= claimActive) {
            require(currentInhabitants + amount <= (maxInhabitants - (maxWInhabitants + maxFInhabitants)), "Not enough inhabitants for that");
        } else {
            require(currentInhabitants + amount <= maxInhabitants, "Not enough inhabitants for that");
        }

        require(looks.balanceOf(msg.sender) >= looksPrice * amount, "Not enough $LOOKS to buy a inhabitant");
        
        looks.transferFrom(msg.sender, looksWallet, looksPrice * amount);

        for (uint256 i = 0;i < amount;i++) {
            _safeMint(msg.sender, currentInhabitants + i);

            Population.increment();
        }

        delete currentInhabitants;
    }

    /*
     * # reserveInhabitants
     * mints the amount provided for the team wallet - the amount is capped by teamInhabitants
     */
    function reserveInhabitants(uint256 amount) public payable onlyOwner {
        uint256 currentInhabitants = Population.current();

        require(teamInhabitantsClaimed + amount < teamInhabitants, "We've run out of inhabitants for the team");

        for (uint256 i = 0;i < amount;i++) {
            _safeMint(msg.sender, currentInhabitants + i);

            Population.increment();
            teamInhabitantsClaimed++;
        }

        delete currentInhabitants;
    }

    /*
     * # performRitual
     * performing the ritual will burn one of the tokens passed and upgrade the first token passed. upgrading will
     * change the metadata of the image and add to the sacrifice goals for the project.
     */
    function performRitual(uint256 vessel, uint256 sacrifice) public payable inhabitantOwner(vessel) inhabitantOwner(sacrifice) isTempleOpen {
        require(vessel != sacrifice, "You can't sacrifice the same inhabitants");
        require(!ritualizedInhabitants[vessel] && !ritualizedInhabitants[sacrifice], "You can't sacrifice ascended inhabitants with those of the lower class");

        // burn the $RUNES and transfer the sacrificed token to the burn wallet
        runes.burn(msg.sender, ritualPrice + (ritualRate * sacrificed.current()));
        safeTransferFrom(msg.sender, ritualWallet, sacrifice, "");

        // track the tokens that ascended & add to the global goal
        sacrificed.increment();
        ritualizedInhabitants[vessel] = true;

        emit performRitualEvent(msg.sender, vessel, sacrifice);
    }

    /*
     * # performSacredRight
     * this is performed during the 10% sacrifical goals for the 1/1s. check the utility page for more info
     */
    function performSacredRitual(uint256 vessel, uint256 sacrifice) public payable inhabitantOwner(vessel) inhabitantOwner(sacrifice) ascendedOwner(vessel) ascendedOwner(sacrifice) isTempleOpen {
        uint256 currentGoal = 333 * sacred.current(); // 10% of maxRituals 

        require(vessel != sacrifice, "You can't sacrifice the same inhabitants");
        require(sacrificed.current() >= currentGoal, "Not enough sacrifices to discover a God!");

         // burn the $RUNES and transfer the sacrificed token to the burn wallet
        runes.burn(msg.sender, ritualPrice + (ritualRate * sacrificed.current()));
        safeTransferFrom(msg.sender, ritualWallet, sacrifice, "");

        ritualizedInhabitants[vessel] = false;
        uniqueInhabitants[vessel] = true;
        sacrificed.increment();
        sacred.increment();

        emit performSacredRitualEvent(msg.sender, vessel, sacrifice);
    }

    /*
     * # getCaptives
     * returns all the tokens a wallet holds
     */
    function getCaptives(address inhabitant) public view returns(uint256[] memory) {
        uint256 population = Population.current();
        uint256 amount     = balanceOf(inhabitant);
        uint256 selector   = 0;

        uint256[] memory inhabitants = new uint256[](amount);

        for (uint256 i = 0;i < population;i++) {
            if (ownerOf(i) == inhabitant) {
                inhabitants[selector] = i;
                selector++;
            }
        }

        return inhabitants;
    }

    /*
     * # totalSupply
     */
    function totalSupply() external view returns(uint256) {
        return Population.current();
    }

    /*
     * # getSacrificed
     */
    function getSacrificed() external view returns(uint256) {
        return sacrificed.current();
    }

    /*
     * # getSacred
     */
    function getSacred() external view returns(uint256) {
        return sacred.current();
    }

    /*
     * # _baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     * # setBaseURI
     */
    function setBaseURI(string memory metadataUrl) public payable onlyOwner {
        baseURI = metadataUrl;
    }

    /*
     * # withdraw
     * withdraws the funds from the smart contract to the owner
     */
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        delete balance;
    }

    /*
     * # setSaleSettings
     * sets the drop time and the claimimg time
     */
    function setSaleSettings(uint256 saleTime, uint256 claimTime) public payable onlyOwner {
        saleActive  = saleTime;
        claimActive = claimTime;
    }

    /*
     * # setMintPrice
     * sets the mint price for the sale incase we need to change it
     */
    function setMintPrice(uint256 price) public payable onlyOwner {
        mintPrice = price;
    }

    /*
     * # setLooksPrice
     * sets the price of $LOOKS to mint with incase we need to set it multiple times
     */
    function setLooksPrice(uint256 price) public payable onlyOwner {
        looksPrice = price;
    }

    /*
     * # setRitualSettings
     * allows us to change the ritual price, rate, and whether ritual is enabled or not
     */
    function setRitualSettings(uint256 price, uint256 rate, bool available) public payable onlyOwner {
        ritualPrice     = price;
        ritualRate      = rate;
        templeAvailable = available;
    }

    /*
     * # setCollectionInterfaces
     * sets the interfaces for creatureworld, superlative, and runes
     */
    function setCollectionInterfaces(address creatureContract, address superlativeContract, address runesContract, address looksContract) public payable onlyOwner {
        creature    = Creature(creatureContract);
        superlative = Superlative(superlativeContract);
        runes       = IRunes(runesContract);
        looks       = Looks(looksContract);
    }

    /*
     * # transferFrom
     */
    function transferFrom(address from, address to, uint256 inhabitant) public override {
        runes.updateRunes(from, to);

        ERC721.transferFrom(from, to, inhabitant);
    }

    /*
     * # safeTransferFrom
     */
    function safeTransferFrom(address from, address to, uint256 inhabitant) public override {
        safeTransferFrom(from, to, inhabitant, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 inhabitant, bytes memory data) public override {
        runes.updateRunes(from, to);

        ERC721.safeTransferFrom(from, to, inhabitant, data);
    }
}