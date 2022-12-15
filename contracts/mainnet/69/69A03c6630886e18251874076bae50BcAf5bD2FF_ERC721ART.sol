/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

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
    ) external payable;

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
    ) external payable;

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
    ) external payable;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


/*
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
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

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
    ) public virtual override payable{
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
    ) public virtual override payable{
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
    ) public virtual override payable{
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
    function _exists(uint256 tokenId) public view returns (bool) {
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
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
    mapping(address => uint256) internal _balances;

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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

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


/**
 * @title Contract that will work with ERC223 tokens.
 */
abstract contract IERC223 {

    struct ERC223TransferInfo
    {
        address token_contract;
        address sender;
        uint256 value;
        bytes   data;
    }
    
    ERC223TransferInfo private tkn;
    
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenReceived(address _from, uint _value, bytes memory _data) public virtual
    {
        /**
         * @dev Note that inside of the token transaction handler the actual sender of token transfer is accessible via the tkn.sender variable
         * (analogue of msg.sender for Ether transfers)
         * 
         * tkn.value - is the amount of transferred tokens
         * tkn.data  - is the "metadata" of token transfer
         * tkn.token_contract is most likely equal to msg.sender because the token contract typically invokes this function
        */
        tkn.token_contract = msg.sender;
        tkn.sender         = _from;
        tkn.value          = _value;
        tkn.data           = _data;
        
        // ACTUAL CODE
    }


}


contract ERC223 is ERC20, IERC223{

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){
    
    }

    /**
     * @dev Additional event that is fired on successful transfer and logs transfer metadata,
     *      this event is implemented to keep Transfer event compatible with ERC20.
     */
    event TransferData(bytes data);

    /**
     * @dev ERC223 tokens must explicitly return "erc223" on standard() function call.
     */
    function standard() public pure returns (string memory)
    {
        return "erc223";
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _recipient    Receiver address.
     * @param _amount Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _recipient, uint _amount, bytes memory _data) 
    public returns (bool success){
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_recipient)
        }

        _balances[msg.sender] = _balances[msg.sender] - _amount;
        _balances[_recipient] = _balances[_recipient] + _amount;
        if(codeLength>0) {
            IERC223 receiver = IERC223(_recipient);
            receiver.tokenReceived(msg.sender, _amount, _data);
        }
        emit Transfer(msg.sender, _recipient, _amount);
        emit TransferData(_data);
        return true;
    }

}


interface ITOKEN {
    function firstOwnner(address owner) external view returns (uint balance);
}


contract TOKEN is ITOKEN {
    function firstOwnner(address) external pure override returns (uint balance){
        return 0;
    }
}


contract ERC223ART is ERC223{
    event AirdropPayout (address user, uint amount, uint8 airDropType);
    event DencentralAirdropPayout (address user, uint amount);


    uint presaleInphases = (250+4500+885+1775+2100+2350+3430+4430) * 10**23; 
    uint public tokenPhase = 0;
    uint[] public tokenPrice = [10, 12, 32, 42, 52, 64, 85, 290];
    uint[] public tokensInPhase = [250*10**23, 4500*10**23, 885*10**23, 1775*10**23, 2100*10**23, 2350*10**23, 3430*10**23, 4430*10**23];
    uint public decentralAirdropAmount = 1092700000000000000000000;
    uint totalBuyPresale = 0;
    mapping(address => uint) buyed;
    mapping(address => uint) public  decentralPayed;
    
    address uni;
    uint totalBuyAddresses = 0;
    uint[] public airdropBank = [1500*10**21, 750*10**21];
    uint8 airdropIndex = 0;

    struct AirDropValues {
        bool airdropPercent1;
        bool airdropPercent2;
        bool airdrop;
    }
    mapping(address => AirDropValues) public airDropUsers;

    constructor() ERC223("Decentral ART","ART"){
        _mint(address(this), presaleInphases + airdropBank[0] + airdropBank[1] + decentralAirdropAmount);
        _mint(msg.sender, (2500000+2746573)*10**20);

        uni = msg.sender;
    }


    function beforeDecentralAirdrop(address sender) public view returns(uint amount, string memory error){
        uint _buyed = TOKEN(0x7c620D582a6Eae9635E4CA4B9A2b1339F20EE1f2).firstOwnner(sender);
        uint _payed = decentralPayed[sender];
        if(_buyed == 0) return (0, "You haven't bought any tokens");
        if(_payed == _buyed) return (0, "The full reward has already been paid");
        return((_buyed * 100*10**18 - _payed), "Ok");
    }

    function decentralAirdrop() public {
        (uint amount, string memory error) = beforeDecentralAirdrop(msg.sender);
        require(amount > 0, error);
        decentralPayed[msg.sender] += amount;
        decentralAirdropAmount += amount;
        ERC223(address(this)).transfer(msg.sender, amount);
        emit DencentralAirdropPayout(msg.sender, amount);
    }   

    function fixPrice (uint phase, uint restTokens, uint input, uint price, uint tokens) 
        private view returns (bool enoughTokens, uint newPrice, uint newTokens) {
        uint priceForFullPhase = restTokens*tokenPrice[phase] / 10**6;
        uint computedTokens = input / tokenPrice[phase];
        if(priceForFullPhase >= input){
          return (
              false, 
              computedTokens * tokenPrice[phase] + price,
              computedTokens * 10**6 +tokens
          );
        } else {
          if(phase == 7){
            return (
                true,
                priceForFullPhase + price,
                restTokens + tokens
            );
          } else {
            return fixPrice(
              phase + 1,
              tokensInPhase[phase+1],
              input-priceForFullPhase,
              priceForFullPhase+price,
              restTokens+tokens
            );
          }
        }
    }


    function beforeBuyToken(uint weiAmount, bool _airdrop, address sender) public view returns(uint tokensAmount, string memory error) {
        if(weiAmount == 0){
            return (0, "Price cannot be zero");
        }
        if(_airdrop && airdropBank[1] == 0) {
            return (0, "Airdrop is over");
        }
        if(_airdrop && ((airdropBank[0] > 0 && airDropUsers[sender].airdropPercent1) || airDropUsers[sender].airdropPercent2)) {
            return (0, "You have already used this type of airdrop");
        }
        (bool enoughTokens, uint newPrice, uint newTokens) = fixPrice(tokenPhase, tokensInPhase[tokenPhase], weiAmount,0,0);
        if(enoughTokens){
            return (0, "Not enough tokens to sell");
        }
        if(newPrice == weiAmount){
            return (newTokens, "");
        }        
        return (0, "Wrong number of WEI");
    }

    function presaleInfo() public view returns (uint _totalBuyPresale, uint _totalBuyAddresses){
        return (totalBuyPresale, totalBuyAddresses);
    }


    function getAirDrop(uint want, address sender) private returns (string memory message, uint amount) {
        if(airdropBank[1] == 0){
            return ("Airdrop is over", 0);
        }
        if(airdropBank[airdropIndex] > 0) {
            (uint _amount) = sendAirdrop(airdropBank[airdropIndex], want, sender);
            if(_amount < want){
                airdropBank[airdropIndex] = 0;
            } else {
                airdropBank[airdropIndex] -= want;
            }
            if(airdropBank[airdropIndex] == 0) airdropIndex = 1;
            return ("Success", _amount);
        }
    }

    function airDrop() public returns (string memory message, uint amount) {
        if(airDropUsers[msg.sender].airdrop) {
            return ("You have already used this type of airdrop", 0);
        }
        (string memory _message, uint _amount) = getAirDrop(100*10**18, msg.sender);
        airDropUsers[msg.sender].airdrop = true;
        emit AirdropPayout(msg.sender, _amount, 0);
        return (_message, _amount);
    }

    function sendAirdrop(uint bank, uint want, address sender) private returns (uint amount){
        if(bank > want) {
            ERC223(address(this)).transfer(sender, want);
            return (want);
        } else {
            ERC223(address(this)).transfer(sender, bank);
            return (bank);
        }
    } 

    function buyTokens(bool airdrop) public payable {
        (uint tokensAmount, string memory error) = beforeBuyToken(msg.value, airdrop, msg.sender);
        require(tokensAmount > 0, error);

        payable(uni).transfer(msg.value);
        totalBuyPresale += tokensAmount;

        if(airdrop){
            if(airdropBank[0] > 0 && !airDropUsers[msg.sender].airdropPercent1){
                airDropUsers[msg.sender].airdropPercent1 = true;
            } else if(airdropBank[1] > 0 && !airDropUsers[msg.sender].airdropPercent2){
                airDropUsers[msg.sender].airdropPercent2 = true;
            }
            uint8 aType = airdropBank[0] > 0 ? 1 : 2;
            (string memory message, uint airDropAmount) = getAirDrop(tokensAmount / (airdropBank[0] > 0 ? 10 : 20), msg.sender);
            require(bytes(message).length == 7, message);
            emit AirdropPayout(msg.sender, airDropAmount, aType);
        }

        
        if(buyed[msg.sender] == 0){
            buyed[msg.sender] = 1;
            totalBuyAddresses++;
        }
        ERC223(address(this)).transfer(msg.sender, tokensAmount);
        do{
            if(tokensInPhase[tokenPhase] > tokensAmount) {
                tokensInPhase[tokenPhase] -= tokensAmount;
                tokensAmount = 0;
            } else {
                tokensAmount -= tokensInPhase[tokenPhase];
                tokensInPhase[tokenPhase] = 0;
                tokenPhase++;
            }
        } while (tokensAmount != 0);
    }
}


abstract contract IUNIVOTING {

    function registerUniART(address uni, address erc223) public {}
}


contract UNI_ART is IERC223 {
    event UniCreated (address token);
    event TokenCreated (string image, uint count, uint price, uint rewardPercent, address nftAddress, address artist, uint index);
    event PurchasedNFTs(address token, address newOwner, uint[] nftTokens, uint[] prices, address commissionTaker, uint commission);
    event PriceChanged(address token, uint[] nftTokens, uint[] prices);
    event Reward(address token, uint prize, address winner, uint holding, uint percent);
    event Unblocked(address who, uint price, address nft, uint256 tokenId);
    
    struct NFT {
        string image;
        uint count;
        uint price;
        uint rewardPercent;
        address nftAddress;
        address owner;
        uint main_prize;
    }

    NFT[] public nftList;
    ERC223ART token223;

    mapping(address => uint) public nftIndexes;
    uint public company223 = (2500000+2746573)*10**20; // Liquidity, FOR TEAM
    address _voting;
    address public _token223;
 

    constructor(address votingAddress){
        token223 = new ERC223ART();
        _token223 = address(token223);
        emit UniCreated(_token223);
        IUNIVOTING(votingAddress).registerUniART(address(this), _token223);
        _voting = votingAddress;
    }

    receive() external payable {
    }

    function voting() public view returns (address votingAddress){
        return _voting;
    }

    function createToken(string memory _image, uint _count, uint _price, uint _rewardPercent, 
        uint[] memory _prizes, uint _priceIncrease) public returns(address nftAddress, uint index) {
        require(_rewardPercent == 0 || _count >= 100, "Minimum count is 100 for NFT with rewards");
        
        uint _index = nftList.length;
        ERC721ART nft = new ERC721ART(_image, "ART", _count, _price, _rewardPercent, _index, _prizes, _priceIncrease);
        address _nftAddress = address(nft);
        
        nftList.push(NFT(_image, _count, _price, _rewardPercent, _nftAddress, msg.sender, 0));
        emit TokenCreated(_image, _count, _price, _rewardPercent, _nftAddress, msg.sender, _index);
        
        nftIndexes[_nftAddress] = _index;

        return(_nftAddress, _index);
    }

    struct BeforeBuyNFTVars {
        uint totalPrice;
        uint actualIndex;
        uint tokenIndex;
    }

    function beforeBuyNFT(address buyer, address nftAdddress, uint[] memory tokenIndexes, uint weiAmount) public view returns(string memory reason, bool error, uint errorTokenOrPrice, uint index){
        
        (uint _index, bool found) = getIndexByAddress(nftAdddress);
        if(!found)
            return ("No NFT found", true, 0, _index);
        if(tokenIndexes.length == 0)
            return ("Empty tokenIndexes", true, 0, _index);

        ERC721ART nft = ERC721ART(nftAdddress);
        BeforeBuyNFTVars memory v;

        v.totalPrice = 0;
        v.actualIndex = nft.totalTokens();
        for(uint i = 0; i < tokenIndexes.length; i++){
            v.tokenIndex = tokenIndexes[i];
            if(v.tokenIndex >= nftList[_index].count)
                return( "Wrong index", true, v.tokenIndex, _index);
            if(nft._exists(v.tokenIndex)){
                if(nft.prices(v.tokenIndex) == 0){
                    if(nft.isApproved(buyer, v.tokenIndex)){
                        v.totalPrice += nft.transferFee(v.tokenIndex);
                    }
                    else {
                        return( "Not for sell", true, v.tokenIndex, _index);
                    }
                }
                v.totalPrice += nft.prices(v.tokenIndex);
            } else {             
                if(nft.priceIncrease() > 0){
                    if(v.tokenIndex == v.actualIndex){
                        v.actualIndex++;
                    } else if(v.tokenIndex > v.actualIndex) {
                        return ("Wrong tokenIndexes order", true, 0, _index);
                    }
                }
                v.totalPrice += nft.getPrice(v.tokenIndex);
            }
        }
        
        if(v.totalPrice != weiAmount)
            return( "Not enough wei", true, v.totalPrice, _index);
       
        return("", false, v.totalPrice, _index);
        
    }
    
    struct TokenReceivedVars {
        uint toOwner;
        uint toCompany;
        uint toMainPrice;
        uint len;
        uint commission;
    }

    function tokenReceived(address _from, uint _value, bytes memory _data) override public {
        require(msg.sender == address(token223),"Only ERC223");
        TokenReceivedVars memory v;
        v.len = (_data.length - 20) / 32;
        uint[] memory tokenIndexes = new uint[](v.len);
        uint[] memory prices = new uint[](v.len);

        address nftAdddress;
        address commissionTaker;
        assembly {
            nftAdddress := mload(add(_data,20))
            commissionTaker := mload(add(_data,40))
        }

        for(uint s = 32; s <= v.len * 32; s += 32) {
            assembly {
                mstore(add(tokenIndexes, s), mload(add(_data, add(s,40))))
            }
        }

        (string memory reason, bool error, , uint nftIndex) = beforeBuyNFT(_from, nftAdddress, tokenIndexes, _value);
        require(!error, reason);
        
        ERC721ART nft = ERC721ART(nftAdddress);

        for(uint i = 0; i < v.len; i++) {
            uint index = tokenIndexes[i];
            if(nft._exists(index)) { // After market
                prices[i] = nft.prices(index);
                if(prices[i] == 0){
                    v.toMainPrice = nft.transferFee(index) * 4 / 11; // 2%
                    if(commissionTaker==address(0)){
                        company223 += nft.transferFee(index) - v.toMainPrice; // 3.5%
                    } else {
                        v.commission += v.toMainPrice; // 2%
                        company223 += nft.transferFee(index) - v.toMainPrice - v.toMainPrice; // 0.5%
                    }
                    nftList[nftIndex].main_prize += v.toMainPrice;
                } else {
                    v.toMainPrice = prices[i] / 50; // 2% to main prize

                    v.toCompany = prices[i] * 35 / 1000; // 3.5% to company
                    v.toOwner = prices[i] - v.toCompany - v.toMainPrice;
                    if(commissionTaker != address(0)){
                        v.commission += v.toCompany * 20 / 35; // 2%
                        v.toCompany -= v.toCompany * 20 / 35; // 1,5%
                    }
                    company223 += v.toCompany;
                    
                    token223.transfer(nft.ownerOf(index), v.toOwner); // transfer to owner
                    nftList[nftIndex].main_prize += v.toMainPrice;
                }
                nft.transfer(_from, index);
            } else { // First sell                
                prices[i] =  nft.getPrice(index);
                if(nft.rewardPercent() == 0) {
                    v.toCompany = prices[i] / 20; // 5% to company
                    v.toOwner = prices[i] - v.toCompany;  // 95% for owner
                    if(commissionTaker != address(0)){
                        v.commission += v.toCompany * 2 / 5; // 2%
                        v.toCompany -= v.toCompany * 2 / 5; // 3%
                    }
                    company223 += v.toCompany;
                } else {
                    uint reward = prices[i] * nft.rewardPercent() / (100000 + nft.rewardPercent()); // calcul reward by percents
                    v.toOwner = prices[i] - reward; // basic price without reward
                    if(commissionTaker != address(0)){
                        v.commission += v.toOwner / 50; // 2%
                        v.toOwner -= v.toOwner / 50; // 98%
                    }
                    v.toMainPrice = reward * 2 / 5; // 40%
                    nftList[nftIndex].main_prize += v.toMainPrice; // 40%
                }
                nft.mint(_from, index, prices[i]);
                token223.transfer(nftList[nftIndex].owner, v.toOwner); // transfer to owner
            }
        }
        if(nft.hodlingIndex() == 10 && nft.rewardPercent() > 0 && nft.balanceOf(_from) == nftList[nftIndex].count ){
            token223.transfer(_from, nftList[nftIndex].main_prize); // transfer to winner
            emit Reward(nftAdddress, nftList[nftIndex].main_prize , _from, nftList[nftIndex].count, 100);
            nft.stopRewards();
        }
        if(commissionTaker != address(0) && v.commission > 0){
            token223.transfer(commissionTaker, v.commission); // transfer to commission taker
        }
        nft.setPrices(tokenIndexes, new uint[](v.len));
        emit PurchasedNFTs(nftAdddress, _from, tokenIndexes, prices, commissionTaker, v.commission);
    }

    function emitPriceChanged(uint index, uint[] memory indexes, uint[] memory newPrices) public {
        NFT memory nftItem = nftList[index];
        require(msg.sender == nftItem.nftAddress, "only ERC721");
        emit PriceChanged(nftItem.nftAddress ,indexes, newPrices);
    }

    function executeReward(address token, uint index, uint reward, address winner, uint holding, uint percent) public {
        NFT memory nftItem = nftList[index];
        require(msg.sender == nftItem.nftAddress, "only ERC721");

        token223.transfer(winner, reward); // transfer to winner
        emit Reward(token, reward, winner, holding, percent);
    }

    function recieveFromNFT(uint index, uint amount, address who, uint tokenId) public {
        NFT memory nftItem = nftList[index];
        require(msg.sender == nftItem.nftAddress, "only ERC721");
        uint toMainPrize = amount * 4 / 11; // 2%
        company223 += amount - toMainPrize; // 3.5%
        nftList[index].main_prize += toMainPrize; // 2%
        emit Unblocked(who, amount, nftItem.nftAddress, tokenId);
    }


    function nftCount() public view returns(uint count){
        return nftList.length;
    }

    function getIndexByAddress(address nftToken) public view returns(uint index, bool found){
        uint _index = nftIndexes[nftToken];
        return (_index, ERC721ART(nftToken).selfIndex() == _index);
    }

    function executeVoting(bool art, address recipient, uint amount) public {
        require(msg.sender == _voting, "You cant");
        if(art){
            token223.transfer(recipient, amount);
            company223 -= amount;
        } else {
            payable(recipient).transfer(amount); 
        }
    }

    function companyAmount() public view returns (uint company) {
        return company223;
    }
}


contract ERC721ART is ERC721, IERC223{   

    UNI_ART base;
    uint public selfIndex;
    uint public available;
    uint public totalTokens;
    uint public actualPrice;
    uint public price; // Final price
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public firstPrice;
    mapping(uint256 => bool) public unblocked;
    uint public rewardPercent;
    uint[] public counts;
    uint[] public percents;
    uint[] public rewards;
    uint public hodlingIndex;
    uint public priceIncrease;

    constructor(string memory name_, string memory symbol_, uint available_, uint price_, uint rewardPercent_, uint selfIndex_, uint[] memory _prizes, uint _priceIncrease) ERC721(name_, symbol_){
        selfIndex = selfIndex_;
        available = available_;
        price = price_;
        priceIncrease = _priceIncrease;
        rewardPercent = rewardPercent_;        
        base = UNI_ART(payable(msg.sender));
        if(_priceIncrease > 0){
            actualPrice = price;
        }
        if(rewardPercent_ > 0){
            rewards = _prizes;
            uint last = 1;
            uint pom;
            uint next = 1;
            for(uint i = 0; i < 10; i++){        
                counts.push(available*last);
                percents.push(last);
                pom = last;
                last += next; 
                next = pom;
            }
        }
    }

    function transferFee(uint tokenId) public view returns(uint fee){
        return firstPrice[tokenId] * 55 / 1000; // 5,5%
    }

    function beforeUnblock(uint tokenId, uint amount) public view returns(bool error, string memory reason, uint unblockPrice){
        uint _price = firstPrice[tokenId] * 11 / 100; // 11% fee for unblock
        if(unblocked[tokenId])
            return(true, "Token is already unblocked", _price);
        if(_price != amount)
            return(true, "Wrong amount", _price);
        return(false, "", _price);
    }

    function tokenReceived(address _from, uint _value, bytes memory _data) override public {
        uint256 tokenId;
        for(uint i=0;i<_data.length;i++){
            tokenId = tokenId + uint(uint8(_data[i]))*(2**(8*(_data.length-(i+1))));
        }
        (bool error, string memory reason, ) = beforeUnblock(tokenId, _value);
        require(!error, reason);
        unblocked[tokenId] = true;
        ERC223ART(base._token223()).transfer(address(base), _value);
        base.recieveFromNFT(selfIndex, _value, _from, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked("https://api.decentral-art.com/erc721/", name(), "/"));
    }


    

    function getPrice(uint index) public view returns (uint _price) {
        if(priceIncrease == 0)
            return price;
        else {
            uint calculPrice = actualPrice;
            for(uint a = totalTokens; a < index; a++){
                calculPrice = calculPrice * priceIncrease / 100000;
            }
            return calculPrice;
        }
    }


    function setPrices(uint[] memory indexes, uint[] memory newPrices) public {
        require(indexes.length == newPrices.length, "Indexes and newPrices not same length");
        bool isBase = msg.sender == address(base);
        for(uint i = 0; i < indexes.length; i++){
            require(isBase || msg.sender == ERC721.ownerOf(indexes[i]), "Only UNI-ART or owner");
            prices[indexes[i]] = newPrices[i];
        }
        base.emitPriceChanged(selfIndex, indexes, newPrices);
    }

    function stopRewards() public {
        require(msg.sender == address(base), "Only UNI-ART");
        hodlingIndex = 11;
    }

    function mint(address to, uint token, uint _price) public {
        require(msg.sender == address(base), "Only UNI-ART");

        _safeMint(to, token);
        
        if(rewardPercent > 0 && hodlingIndex < 10 && balanceOf(to)*100 >= counts[hodlingIndex]){
            base.executeReward(address(this), selfIndex, rewards[hodlingIndex] , to, counts[hodlingIndex], percents[hodlingIndex]);
            hodlingIndex++;
        }
        
        firstPrice[token] = _price;
        actualPrice = actualPrice * priceIncrease / 100000;
        totalTokens += 1;
        available -= 1;
    }

    function isApproved(address spender, uint256 tokenId) public view returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transfer(
        address to,
        uint256 tokenId
    ) public {
        require(msg.sender == address(base), "Only UNI-ART");
        _safeTransfer(ownerOf(tokenId), to, tokenId, "");

        if(rewardPercent > 0 && hodlingIndex < 10 && balanceOf(to)*100 >= counts[hodlingIndex]){
            base.executeReward(address(this), selfIndex, rewards[hodlingIndex] , to, counts[hodlingIndex], percents[hodlingIndex]);
            hodlingIndex++;
        }
    }

    uint[] private arrWithZero = [0];
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override payable{
        require(unblocked[tokenId], "Token is bloked");
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        
        prices[tokenId] = 0;
        uint[] memory t = new uint[](1);
        t[0] = tokenId;
        base.emitPriceChanged(selfIndex, t, arrWithZero);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override payable{
        require(unblocked[tokenId], "Token is bloked");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);

        prices[tokenId] = 0;
        uint[] memory t = new uint[](1);
        t[0] = tokenId;
        base.emitPriceChanged(selfIndex, t, arrWithZero);
    }


}