/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
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
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint256 count;
        for (uint256 i; i < _owners.length; ++i) {
            if (owner == _owners[i]) ++count;
        }
        return count;
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

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
        return tokenId < _owners.length && _owners[tokenId] != address(0);
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
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        _owners.push(to);

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
        _owners[tokenId] = address(0);

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

contract VRFRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VRF coordinator
     *
     * @dev To prevent repetition of VRF output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VRF seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vRFInputSeed The seed to be passed directly to the VRF
     * @return The id for this request
     *
     * @dev Note that _vRFInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVRFInputSeed
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint256 count;
        for (uint256 i; i < _owners.length; i++) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}

interface IIllogics {
    function isAdmin(address addr) external view returns (bool);

    function mintGoop(address _addr, uint256 _goop) external;

    function burnGoop(address _addr, uint256 _goop) external;

    function spendGoop(uint256 _item, uint256 _count) external;

    function mintGoopBatch(address[] calldata _addr, uint256 _goop) external;

    function burnGoopBatch(address[] calldata _addr, uint256 _goop) external;
}

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for ////important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

interface ILab {
    function getIllogical(uint256 _tokenId) external view returns (uint256);
}

contract illogics is IIllogics, ERC721Enumerable, Ownable, VRFConsumerBase {
    /**************************
     *
     *  DATA STRUCTURES & ENUM
     *
     **************************/

    // Data structure that defines the elements of stakedToken
    struct StakedToken {
        address ownerOfNFT;
        uint256 timestamp;
        uint256 lastRerollPeriod;
    }

    // Data structure that defines the elements of a saleId
    struct Sale {
        string description;
        bool saleStatus;
        uint256 price;
        uint256 supply;
        uint256 maxPurchase;
    }

    /**************************
     *
     *  State Variables
     *
     **************************/

    // ***** constants and assignments *****
    uint256 public maxMint = 2; // ill-list max per minter address
    uint256 public constant REROLL_COST = 50; // Goop required to reroll a token
    uint256 public constant GOOP_INTERVAL = 12 hours; // The interval upon which Goop is calcualated
    uint256 public goopPerInterval = 5; // Goop awarded per interval
    address public teamWallet = 0xB3D1b19202423EcD55ACF1E635ea1Bded11a5c9f; // address of the team wallet

    // ***** ill-list minting *****
    bool public mintingState; // enable/disable minting
    bytes32 public merkleRoot; // ill-list Merkle Root

    // ***** Chainlink VRF & tokenID *****
    IERC20 public link; // address of Chainlink token contract
    uint256 public VRF_fee; // Chainlink VRF fee
    uint256 public periodCounter; // current VRF period
    bytes32 public VRF_keyHash; // Chainlink VRF random number keyhash
    string public baseURI; // URI to illogics metadata

    // ***** Goop ecosystem & Sales *****
    uint256 public totalGoopSupply; // total Goop in circulation
    uint256 public totalGoopSpent; // total Goop spent in the ecosystem
    uint256 public saleId; // last saleID applied to a saleItem

    // ***** feature state management *****
    bool public spendState; // Goop spending state
    bool public rerollState; // reroll function state
    bool public stakingState; // staking state
    bool public transferState; // Goop P2P transfer state
    bool public claimStatus; // Goop claim status
    bool public verifyVRF; // can only be set once, used to validate the Chainlink config prior to mint

    // ***** OpenSea *****
    address public proxyRegistryAddress; // proxyRegistry address

    // ***** TheLab *****
    address public labAddress; // the address of TheLab ;)

    /**************************
     *
     *  Mappings
     *
     **************************/

    mapping(uint256 => Sale) public saleItems; // mapping of saleId to the Sale data scructure
    mapping(uint256 => StakedToken) public stakedToken; // mapping of tokenId to the StakedToken data structure
    mapping(address => uint256) public goop; // mapping of address to a Goop balance
    mapping(address => uint256[]) public staker; // mapping of address to owned tokens staked
    mapping(uint256 => uint256) public collectionDNA; // mapping of VRF period to seed DNA for said period
    mapping(uint256 => uint256[]) public rollTracker; // mapping reroll period (periodCounter) entered to tokenIds
    mapping(address => bool) private admins; // mapping of address to an administrative status
    mapping(address => bool) public projectProxy; // mapping of address to projectProxy status
    mapping(address => bool) public addressToMinted; // mapping of address to minted status
    mapping(address => mapping(uint256 => uint256)) public addressPurchases; // mapping of an address to an saleItemId to number of units purchased

    /**********************************************************
     *
     *  Events
     *
     **********************************************************/

    event RequestedRandomNumber(bytes32 indexed requestId); // emitted when the ChainLink VRF is requested
    event RecievedRandomNumber(bytes32 indexed requestId, uint256 periodCounter, uint256 randomNumber); // emitted when a random number is recieved by the Chainlink VRF callback()
    event spentGoop(address indexed purchaser, uint256 indexed item, uint256 indexed count); //emitted when an item is purchased with Goop

    /**********************************************************
     *
     *  Constructor
     *
     **********************************************************/

    /**
     * @dev Initializes the contract by:
     *  - setting a `name` and a `symbol` in the ERC721 constructor
     *  - setting the Chainlnk VRFConsumerBase constructor
     *  - setting collection dependant assignments
     */

    constructor(
        bytes32 _VRF_keyHash,
        uint256 _VRF_Fee,
        address _vrfCoordinator,
        address _linkToken
    ) ERC721("illogics", "ill") VRFConsumerBase(_vrfCoordinator, _linkToken) {
        VRF_keyHash = _VRF_keyHash;
        VRF_fee = _VRF_Fee;
        link = IERC20(address(_linkToken));
        admins[_msgSender()] = true;
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }

    /**********************************************************
     *
     *  Modifiers
     *
     **********************************************************/

    /**
     * @dev Ensures only contract admins can execute privileged functions
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "admins only");
        _;
    }

    /**********************************************************
     *
     *  Contract Management
     *
     **********************************************************/

    /**
     * @dev Check is an address is an admin
     */
    function isAdmin(address _addr) public view override returns (bool) {
        return owner() == _addr || admins[_addr];
    }

    /**
     * @dev Grant administrative control to an address
     */
    function addAdmin(address _addr) external onlyAdmin {
        admins[_addr] = true;
    }

    /**
     * @dev Revoke administrative control for an address
     */
    function removeAdmin(address _addr) external onlyAdmin {
        admins[_addr] = false;
    }

    /**********************************************************
     *
     *  Admin and Contract setters
     *
     **********************************************************/

    /**
     *  @dev running this after the constructor adds the deployed address
     *  of this contract to the admins
     */
    function init() external onlyAdmin {
        admins[address(this)] = true;
    }

    /**
     * @dev enables//disables minting state
     */
    function setMintingState(bool _state) external onlyAdmin {
        mintingState = _state;
    }

    /**
     * @dev enable/disable staking, this does not impact unstaking
     */
    function setStakingState(bool _state) external onlyAdmin {
        stakingState = _state;
    }

    /**
     *  @dev enable/disable reroll, this must be in a disabled state
     *  prior to calling the final VRF
     */
    function setRerollState(bool _state) external onlyAdmin {
        rerollState = _state;
    }

    /**
     * @dev enable/disable P2P transfer of Goop
     */
    function setTransferState(bool _state) external onlyAdmin {
        transferState = _state;
    }

    /**
     * @dev enable/disable the ability to spend Goop
     */
    function setSpendState(bool _state) external onlyAdmin {
        spendState = _state;
    }

    /**
     * @dev set TheLab address (likely some future Alpha here)
     */
    function setLabAddress(address _labAddress) external onlyAdmin {
        labAddress = _labAddress;
    }

    /**
     * @dev set the baseURI.
     */
    function setBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
    }

    /**
     * @dev Set the maxMint
     */
    function setMaxMint(uint256 _maxMint) external onlyAdmin {
        maxMint = _maxMint;
    }

    /**
     * @dev set the amount of Goop earned per interval
     */
    function setGoopPerInterval(uint256 _goopPerInterval) external onlyAdmin {
        goopPerInterval = _goopPerInterval;
    }

    /**
     * @dev enable/disable Goop claiming
     */
    function setClaim(bool _claimStatus) external onlyAdmin {
        claimStatus = _claimStatus;
    }

    /**********************************************************
     *
     *  The illest ill-list
     *
     **********************************************************/

    /**
     * @dev set the merkleTree root
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev calculates the leaf hash
     */
    function leaf(string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload));
    }

    /**
     * @dev verifies the inclusion of the leaf hash in the merkleTree
     */
    function verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**********************************************************
     *
     *  TheLab
     *
     **********************************************************/

    /**
     * @notice expect big things from this...
     */
    function multiHelix(uint256 _tokenId) public view returns (uint256) {
        require(labAddress != address(0x0), "The Lab is being setup.");
        return ILab(labAddress).getIllogical(_tokenId);
    }

    /**********************************************************
     *
     *  Token management
     *
     **********************************************************/

    /**
     *  @dev ill-list leverages merkleTree for the mint, there is no public sale.
     *
     *  The first token in the collection is 0 and the last token is 8887, which
     *  equates to a collection size of 8888. Gas optimization uses an index based
     *  model that returns an array size of 8888. As another gas optimization, we
     *  refrained from <= or >= and as a result we must +1, hence the < 8889.
     */
    function illListMint(bytes32[] calldata proof) public payable {
        string memory payload = string(abi.encodePacked(_msgSender()));
        uint256 totalSupply = _owners.length;

        require(mintingState, "Ill-list not active");
        require(verify(leaf(payload), proof), "Invalid Merkle Tree proof supplied");
        require(addressToMinted[_msgSender()] == false, "can not mint twice");
        require(totalSupply + maxMint < 8889, "project fully minted");

        addressToMinted[_msgSender()] = true;

        for (uint256 i; i < maxMint; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    /**
     * @dev mints 'tId' to 'address'
     */
    function _mint(address to, uint256 tId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tId);
    }

    /**********************************************************
     *
     *  TOKEN
     *
     **********************************************************/

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the `tokenId` token.
     */
    function tokenURI(uint256 _tId) public view override returns (string memory) {
        require(_exists(_tId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tId)));
    }

    /**
     * @dev transfer an array of tokens from '_from' address to '_to' address
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tIds
    ) public {
        for (uint256 i = 0; i < _tIds.length; i++) {
            transferFrom(_from, _to, _tIds[i]);
        }
    }

    /**
     * @dev safe transfer an array of tokens from '_from' address to '_to' address
     */
    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tIds.length; i++) {
            safeTransferFrom(_from, _to, _tIds[i], data_);
        }
    }

    /**
     * @dev returns a confirmation that 'tIds' are owned by 'account'
     */
    function isOwnerOf(address account, uint256[] calldata _tIds) external view returns (bool) {
        for (uint256 i; i < _tIds.length; ++i) {
            if (_owners[_tIds[i]] != account) return false;
        }

        return true;
    }

    /**
     * @dev Retunrs the tokenIds of 'owner'
     */
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**********************************************************
     *
     *  GENEROSITY + ETH FUNDING
     *
     **********************************************************/

    /**
     * @dev Just in case someone sends ETH to the contract
     */
    function withdraw() public {
        (bool success, ) = teamWallet.call{value: address(this).balance}("");
        require(success, "Failed to send.");
    }

    receive() external payable {}

    /**********************************************************
     *
     *  CHAINLINK VRF & TOKEN DNA
     *
     **********************************************************/

    /**
     * @dev Requests a random number from the Chainlink VRF
     */
    function requestRandomNumber() external onlyAdmin returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= VRF_fee, "Not enough LINK");
        requestId = requestRandomness(VRF_keyHash, VRF_fee);

        emit RequestedRandomNumber(requestId);
    }

    /**
     * @dev Receives the random number from the Chainlink VRF callback
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
        periodCounter++;
        collectionDNA[periodCounter] = _randomNumber;

        emit RecievedRandomNumber(_requestId, periodCounter, _randomNumber);
    }

    /**
     * @dev this allows you to test the VRF call to ensure it works as expected prior to mint
     * It resets the collectionDNA and period counter to defaults prior to minting.
     */
    function setVerifyVRF() external onlyAdmin {
        require(!verifyVRF, "this is a one way function it can not be called twice");
        collectionDNA[1] = 0;
        periodCounter = 0;
        verifyVRF = true;
    }

    /**
     *  @notice A reroll is an opportunity to change your tokenDNA and only available when reroll is enabled.
     *  A token that is rerolled gets brand new tokenDNA that is generated in the next reroll period
     *  with the result of the Chainlink VRF requestRandomNumber(). Its impossible to know the result
     *  of your reroll in advance of the Chainlink call and as a result you may end up with a rarer
     *  or less rare tokenDNA.
     */
    function reroll(uint256[] calldata _tokenIds) external {
        uint256 amount = REROLL_COST * _tokenIds.length;
        require(rerollState, "reroll not enabled");
        require(goop[_msgSender()] >= amount, "not enough goop for reroll");

          for (uint256 i = 0; i < _tokenIds.length; i++) {

            require(stakedToken[_tokenIds[i]].ownerOfNFT == _msgSender(), "you dont own this token or its not staked");

            rollTracker[periodCounter + 1].push(_tokenIds[i]);
            stakedToken[_tokenIds[i]].lastRerollPeriod = periodCounter;
        }

        _burnGoop(_msgSender(), amount);
    }

    /**
     * @dev Set/change the Chainlink VRF keyHash
     */
    function setVRFKeyHash(bytes32 _keyHash) external onlyAdmin {
        VRF_keyHash = _keyHash;
    }

    /**
     * @dev Set/change the Chainlink VRF fee
     */
    function setVRFFee(uint256 _fee) external onlyAdmin {
        VRF_fee = _fee;
    }

    /**
     * @notice
     *  - tokenDNA is generated dynamically based on the relevant Chainlink VRF seed. If a token is never
     *    rerolled, it will be constructed based on period 1 (initial VRF) seed. if a token is rerolled in
     *    period 5, its DNA will be based on the VRF seed for period 6. This ensures that no one can
     *    predict or manipulate tokenDNA
     *  - tokenDNA is generated on the fly and not maintained as state on-chain or off-chain.
     *  - tokenDNA is used to construct the unique metadata for each NFT
     *
     *  - Some people may not like this function as its based on nested loops, so here is the logic
     *    1. this is an external function and is never called by this contract or future contract
     *    2. the maximum depth of i will ever be 20, after which all tokenDNA is permanent
     *    3. it ensures tokenDNA is always correct under all circumstances
     *    4. it has 0 gas implications
     */
    function getTokenDNA(uint256 _tId) external view returns (uint256) {
        require(_tId < _owners.length, "tokenId out of range");

        for (uint256 i = periodCounter; i > 0; i--) {
            if (i == 1) {
                return uint256(keccak256(abi.encode(collectionDNA[i], _tId)));
            } else {
                for (uint256 j = 0; j < rollTracker[i].length; j++) {
                    if (rollTracker[i][j] == _tId) {
                        return uint256(keccak256(abi.encode(collectionDNA[i], _tId)));
                    }
                }
            }
        }
    }

    /**
     * @notice To maintain transparency with awarding the "1/1" tokens we are leveraging
     * ChainlinkVRF. To accomplish this we are calling requestRandomNumber() after the reveal
     * and will use the next periodCounter to derive a fair one of one giveaway.
     */
    function get1of1() external view returns (uint256[] memory) {
        uint256[] memory oneOfOnes = new uint256[](20);
        uint256 counter;
        uint256 addCounter;
        bool matchStatus;

        while (addCounter < 20) {
            uint256 result = (uint256(keccak256(abi.encode(collectionDNA[2], counter))) % 8887);

            for (uint256 i = 0; i < oneOfOnes.length; i++) {
                if (result == oneOfOnes[i]) {
                    matchStatus = true;
                    break;
                }
            }

            if (!matchStatus) {
                oneOfOnes[addCounter] = result;
                addCounter++;
            } else {
                matchStatus = false;
            }
            counter++;
        }
        return oneOfOnes;
    }

    /**********************************************************
     *
     *  STAKING & UNSTAKING
     *
     **********************************************************/

    /**
     * @notice Staking your NFT transfers ownership to (this) contract until you unstake it.
     * When an NFT is staked you will earn Goop, which can be used within the illogics
     * ecosystem to procure items we have for sale.
     */
    function stakeNFT(uint256[] calldata _tokenIds) external {
        require(stakingState, "staking not enabled");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "you are not the owner");

            safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);

            stakedToken[_tokenIds[i]].ownerOfNFT = _msgSender();
            stakedToken[_tokenIds[i]].timestamp = block.timestamp;
            staker[_msgSender()].push(_tokenIds[i]);
        }
    }

    /**
     * @notice unstaking a token that has unrealized Goop forfeits the Goop associated
     * with the token(s) being unstaked. This was done intentionally as a holder may
     * not to pay the gas costs associated with claiming Goop. Please see unstakeAndClaim
     * to also claim Goop.
     *
     * Unstaking your NFT transfers ownership back to the address that staked it.
     * When an NFT is unstaked, you will no longer be earning Goop.
     */
    function unstakeNFT(uint256[] calldata _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {

            require(stakedToken[_tokenIds[i]].ownerOfNFT == _msgSender(), "you are not the owner");
            require(canBeUnstaked(_tokenIds[i]), "token in reroll or cool down period");

            _transfer(address(this), _msgSender(), _tokenIds[i]);

            delete stakedToken[_tokenIds[i]].ownerOfNFT;
            delete stakedToken[_tokenIds[i]].timestamp;
            delete stakedToken[_tokenIds[i]].lastRerollPeriod;

            /**
             * @dev - iterates the array of tokens staked and pops the one being unstaked
             */
            for (uint256 j = 0; j < staker[_msgSender()].length; j++) {
                if (staker[_msgSender()][j] == _tokenIds[i]) {
                    staker[_msgSender()][j] = staker[_msgSender()][staker[_msgSender()].length - 1];
                    staker[_msgSender()].pop();
                }
            }
        }
    }

    /**
     * @dev unstakeAndClaim will unstake the token and realize the Goop that it has earned.
     * If you are not interested in earning Goop you can call unstaske and save the gas.
     * Unstaking your NFT transfers ownership back to the address that staked it.
     * When an NFT is unstaked you will no longer be earning Goop.
     */
    function unstakeAndClaim(uint256[] calldata _tokenIds) external {
        claimGoop();
        unstakeNFT(_tokenIds);
    }

    /**
     * @notice
     * - An address requests a reroll for a tokenId, the tokenDNA is updated after the subsequent VRF request.
     * - To prevent the sale of a token prior to the tokenDNA and metadata being refreshed in the marketplace,
     *   we have implemented a cool-down period. The cool down period will allow a token to be unstaked when
     *   it is not in the previous period
     */
    function canBeUnstaked(uint256 _tokenId) public view returns (bool) {
        // token has never been rerolled and can be unstaked
        if (stakedToken[_tokenId].lastRerollPeriod == 0) {
            return true;
        }
        // token waiting for next VRF and can not be unstaked
        if (stakedToken[_tokenId].lastRerollPeriod == periodCounter) {
            return false;
        }
        // token in cooldown period after the reroll and can not be unstaked
        if (periodCounter - stakedToken[_tokenId].lastRerollPeriod == 1) {
            return false;
        }

        return true;
    }

    /**
     * @dev returns an array of tokens that an address has staked
     */
    function ownerStaked(address _addr) public view returns (uint256[] memory) {
        return staker[_addr];
    }

    // enables safeTransferFrom function to send ERC721 tokens to this contract (used in staking)
    function onERC721Received(
        address operator,
        address from,
        uint256 tId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**********************************************************
     *
     *  GOOP ECOSYSTEM
     *
     **********************************************************/

    /**
     * @notice
     *  - Goop is an internal point system, there are no goop tokenomics as it
     *    is minted when claimed and burned when spent. As such the amount of goop
     *    in circulation is constantly changing.
     *  - Goop may resemble an ERC20, it can be transferred or donated P2P, however
     *    it cannot be traded on an exchange and has no monetary value, further it
     *    can only be used in the illogics ecosystem.
     *  - Goop exists in 2 forms, claimed and unclaimed, in order to spend goop
     *    it must be claimed.
     */

    /**
     * @dev Goop earned as a result of staking but not yet claimed/realized
     */
    function unclaimedGoop() external view returns (uint256) {
        address addr = _msgSender();
        uint256 stakedTime;

        for (uint256 i = 0; i < staker[addr].length; i++) {

            stakedTime += block.timestamp - stakedToken[staker[addr][i]].timestamp;
        }
        return (stakedTime / GOOP_INTERVAL) * goopPerInterval;
    }

    /**
     * @dev claim earned Goop without unstaking
     */
    function claimGoop() public {
        require(claimStatus, "GOOP: claim not enabled");

        address addr = _msgSender();
        uint256 stakedTime;

        for (uint256 i = 0; i < staker[addr].length; i++) {
            stakedTime += block.timestamp - stakedToken[staker[addr][i]].timestamp;
            stakedToken[staker[addr][i]].timestamp = block.timestamp;
        }
        _mintGoop(addr, (stakedTime / GOOP_INTERVAL) * goopPerInterval);
    }

    /**
     *
     * @dev Moves `amount` Goop from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function transferGoop(address _to, uint256 _amount) public returns (bool) {
        address owner = _msgSender();
        _transferGoop(owner, _to, _amount);
        return true;
    }

    /**
     * @dev Moves `amount` of Goop from `sender` to `recipient`.
     */
    function _transferGoop(
        address from,
        address to,
        uint256 _amount
    ) internal {
        require(transferState, "GOOP: transfer not enabled");
        require(from != address(0), "GOOP: transfer from the zero address");
        require(to != address(0), "GOOP: transfer to the zero address");

        uint256 fromBalance = goop[from];
        require(goop[from] >= _amount, "GOOP: insufficient balance ");
        unchecked {
            goop[from] = fromBalance - _amount;
        }
        goop[to] += _amount;
    }

    /**
     * @dev admin function to mint Goop to a single address
     */
    function mintGoop(address _addr, uint256 _goop) external override onlyAdmin {
        _mintGoop(_addr, _goop);
    }

    /**
     * @dev admin function to mint Goop to multiple addresses
     */
    function mintGoopBatch(address[] calldata _addr, uint256 _goop) external override onlyAdmin {
        for (uint256 i = 0; i < _addr.length; i++) {
            _mintGoop(_addr[i], _goop);
        }
    }

    /**
     * @dev Creates `amount` Goop and assigns them to `account`
     */
    function _mintGoop(address account, uint256 amount) internal {
        require(account != address(0), "GOOP: mint to the zero address");

        totalGoopSupply += amount;
        goop[account] += amount;
    }

    /**
     * @dev admin function to burn Goop from a single address
     */
    function burnGoop(address _addr, uint256 _goop) external override onlyAdmin {
        _burnGoop(_addr, _goop);
    }

    /**
     * @dev admin function to burn Goop from multiple addresses
     */
    function burnGoopBatch(address[] calldata _addr, uint256 _goop) external override onlyAdmin {
        for (uint256 i = 0; i < _addr.length; i++) {
            _burnGoop(_addr[i], _goop);
        }
    }

    /**
     * @dev permits Goop to be spent within the illogics ecosystem
     */
    function spendGoop(uint256 _item, uint256 _count) public override {
        addressPurchases[_msgSender()][_item] += _count;

        require(spendState, "GOOP: spending not enabled");
        require(saleItems[_item].saleStatus, "Item not currently for sale");
        require(saleItems[_item].supply >= _count, "Item sold out.");
        require(addressPurchases[_msgSender()][_item] <= saleItems[_item].maxPurchase, "Exceeded allowed purchase quantity");

        uint256 cost = _count * saleItems[_item].price;
        require(goop[_msgSender()] >= cost, "Insufficient goop.");

        _burnGoop(_msgSender(), cost);

        saleItems[_item].supply -= _count;
        totalGoopSpent += _count * saleItems[_item].price;

        emit spentGoop(_msgSender(), _item, _count);
    }

    /**
     * @dev Destroys `amount` Goop from `account`
     */
    function _burnGoop(address account, uint256 amount) internal {
        require(account != address(0), "GOOP: burn from the zero address");

        uint256 accountBalance = goop[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            goop[account] = accountBalance - amount;
        }
        totalGoopSupply -= amount;
    }

    /**********************************************************
     *
     *  GOOP SALE
     *
     **********************************************************/

    /**
     * @dev creates a new sale item and sets the sale elements
     */
    function createNewSale(
        string memory _description,
        bool _saleState,
        uint256 _price,
        uint256 _supply,
        uint256 _maxPurchase
    ) external onlyAdmin {
        saleId++;
        saleItems[saleId] = Sale(_description, _saleState, _price, _supply, _maxPurchase);
    }

    /**
     * @dev changes the description of the selected item
     */
    function setSaleDescription(uint256 _item, string memory _description) external onlyAdmin {
        saleItems[_item].description = _description;
    }

    /**
     * @dev enable/disable the sale of the selected item     
     */
    function setSaleStatus(uint256 _item, bool _saleStatus) external onlyAdmin {
        saleItems[_item].saleStatus = _saleStatus;
    }

    /**
     * @dev changes the sale price of the selected item
     */
    function setSalePrice(uint256 _item, uint256 _price) external onlyAdmin {
        saleItems[_item].price = _price;
    }

    /**
     * @dev changes supply of the selected item
     */
    function setSaleSupply(uint256 _item, uint256 _supply) external onlyAdmin {
        saleItems[_item].supply = _supply;
    }

    /**
     * @dev changes the max amount an address can purchase of the selected item
     */
    function setMaxPurchase(uint256 _item, uint256 _maxPurchase) external onlyAdmin {
        saleItems[_item].maxPurchase = _maxPurchase;
    }

    /**********************************************************
     *
     *  OPENSEA
     *
     **********************************************************/

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyAdmin {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}