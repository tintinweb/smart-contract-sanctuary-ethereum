/**
 *Submitted for verification at Etherscan.io on 2022-02-22
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

       // emit Transfer(address(0), to, tokenId); // tady povolit
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


interface ITOKEN {
    function firstOwnner(address owner) external view returns (uint balance);
}


contract VAR is ITOKEN {
    address owner;
    // Info about wallets
    uint mainGoalAmount = 20000000000000000; // předvyplněné 0.1515 jinak by šel do záporu při prvních výhrách
    uint companyAmount = 0;

    uint8 actualPhase = 0;
    uint totalMintedTokens = 0;
    
    address[] public hodlers;  // před operací se musím podívat kolik měl tokenů. pokud nějaké měl, nepřidávám, pokud měl 0 tak přidávám a pokud nový stav je nula, pak odebírám, ale nevím index...
    mapping(address => uint) public hodlersIndex; // tady je třeba uvažovat o tom, že když se maže z pole hodletů, tak se vezme podlení adresa z hodlerů a pokud to není ten mazaný, tak se musí upravit nová pozice v tomto mappingu
    
    uint[] VIPIndexes;
    mapping(uint256 => uint) sellingPrice;
    mapping(address => uint) firstOwnners;
    
    struct Phase {
        uint tokensAmount;
        uint prizesAmount;
        uint prize;
        uint winAmount;
        address[] buyers;
        uint[] winners;
        uint toGoalWallet;
    }
    
    uint nonce = 0;
    function random(uint participants, address salt) internal returns(uint) {
        nonce++;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt, nonce))) % participants;
    }
    
    Phase[] phases;
    
    constructor() {
        address[] memory emptyAddressesArray;
        uint[] memory emptyWinners;
        phases.push(Phase(1, 1, 1000000000000000, 1500000000000000, emptyAddressesArray, emptyWinners, 19705000000000000));//1
        phases.push(Phase(1, 1, 1000000000000000, 20000000000000000, emptyAddressesArray, emptyWinners, 8790000000000000));//2
        phases.push(Phase(2, 1, 23600000000000000, 40000000000000000, emptyAddressesArray, emptyWinners, 22124000000000000));//3
        phases.push(Phase(3, 1, 38200000000000000, 100000000000000000, emptyAddressesArray, emptyWinners, 22871333333333300));//4
        phases.push(Phase(5, 1, 50000000000000000, 200000000000000000, emptyAddressesArray, emptyWinners, 25900000000000000));//5
        phases.push(Phase(8, 1, 61800000000000000, 400000000000000000, emptyAddressesArray, emptyWinners, 26962000000000000));//6
        phases.push(Phase(13, 1, 78600000000000000, 786000000000000000, emptyAddressesArray, emptyWinners, 30701692307692300));//7
        phases.push(Phase(21, 1, 161800000000000000, 1618000000000000000, emptyAddressesArray, emptyWinners, 70003904761904800));//8
        phases.push(Phase(34, 1, 218000000000000000, 2180000000000000000, emptyAddressesArray, emptyWinners, 110790588235294000));//9
        phases.push(Phase(55, 1, 236000000000000000, 2360000000000000000, emptyAddressesArray, emptyWinners, 133923636363636000));//10
        phases.push(Phase(89, 2, 382000000000000000, 3820000000000000000, emptyAddressesArray, emptyWinners, 194732808988764000));//11
        phases.push(Phase(144, 3, 500000000000000000, 5000000000000000000, emptyAddressesArray, emptyWinners, 253541666666667000));//12
        phases.push(Phase(233, 5, 618000000000000000, 6180000000000000000, emptyAddressesArray, emptyWinners, 306375364806867000));//13
        phases.push(Phase(377, 8, 786000000000000000, 7860000000000000000, emptyAddressesArray, emptyWinners, 385333633952255000));//14
        phases.push(Phase(610, 13, 1618000000000000000, 16180000000000000000, emptyAddressesArray, emptyWinners, 771176393442623000));//15
        phases.push(Phase(987, 21, 2618000000000000000, 26180000000000000000, emptyAddressesArray, emptyWinners, 1235977446808510000));//16
        phases.push(Phase(1579, 34, 3618000000000000000, 36180000000000000000, emptyAddressesArray, emptyWinners, 1694980481317290000));//17
        phases.push(Phase(2584, 55, 4236000000000000000, 42360000000000000000, emptyAddressesArray, emptyWinners, 1987281021671830000));//18
        phases.push(Phase(4181, 89, 6872300000000000000, 68723000000000000000, emptyAddressesArray, emptyWinners, 3211551348242050000));//19
    }
    
    function info() public view returns(uint ActualPhase, uint TotalMintedTokens, uint MainGoalWei, uint CompanyWei, uint TotalWei){
        return (actualPhase, totalMintedTokens, mainGoalAmount, companyAmount, address(this).balance);
    }
    
    function firstOwnner(address ownerAddress) external view  override returns (uint balance){
        require(ownerAddress != address(0), "ITOKEN: balance query for the zero address");
        return firstOwnners[ownerAddress];
    }
}


contract DRAW is VAR {
    event DrawLots (uint8 phase, address[] winners, uint amount, uint[] winnerIndexes);
    
    function drawLots() public {
        require(phases[actualPhase].tokensAmount == 0, "Not all tokens were sold in the actual phase");
        uint[] memory winnerIndexes = new uint[](phases[actualPhase].prizesAmount);
        address[] memory winners = new address[](phases[actualPhase].prizesAmount);
        
        for(uint16 i = 0; i < phases[actualPhase].prizesAmount; i++){
            winnerIndexes[i] = random( phases[actualPhase].buyers.length, phases[actualPhase].buyers[i]);
            winners[i] = phases[actualPhase].buyers[winnerIndexes[i]];
            phases[actualPhase].winners.push(winnerIndexes[i]);
            payable(winners[i]).transfer(phases[actualPhase].winAmount); // Vyplacení výhry
        }
        emit DrawLots(actualPhase, winners, phases[actualPhase].winAmount, winnerIndexes);
        actualPhase++;
    }
    
}

abstract contract GOALS is VAR, ERC721 {
    
    event GoalReached (uint16 owningTokens, address winner, uint amount);
    event WinHodlers (uint8 index, address[] winners, uint amount);
    
    uint goalsReached = 0;
    uint16[12] goalsInTokens = [54, 109, 218, 327, 546, 874, 1420, 2294, 3715, 6009, 9725, 10927];
    uint16[11] goalPrizes = [890, 550, 340, 210, 130, 80, 50, 30, 20, 10, 10]; // in promiles
    
    uint8[19] VIPsInPhases = [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89];
    
    
    uint8 public actualHolderPriceIndex = 0;
    uint[10] holdersPrices = [10, 20, 22, 23, 24, 25, 26, 27, 28, 29];


    function checkGoalReached(address payable testedAddress) internal { //metoda volána z přesunu a nákupu tokenu
        uint256 amount = balanceOf(testedAddress);
        if(goalsReached < 11 && amount >= goalsInTokens[goalsReached]){ // Částečné výhry
            uint prize = mainGoalAmount * goalPrizes[goalsReached] / 1000;
            testedAddress.transfer(prize); //výherce získá 10% z vybraných ETH pro výhry
            mainGoalAmount -= prize;
            emit GoalReached(goalsInTokens[goalsReached], testedAddress, prize);
            goalsReached++;
        } else if(goalsReached == 11 && amount >= goalsInTokens[goalsReached]){ // Plná výhra
            testedAddress.transfer(mainGoalAmount); // Hlavní výhra
            emit GoalReached(10927, testedAddress, mainGoalAmount);
            mainGoalAmount -= mainGoalAmount;
            goalsReached++;
        }
    }
    
    mapping(address => uint8) isWinner; // proměnná bude obsahovat index probíhající akce, pokud byla adresa použita, pokud ne, tak bude číslováno od nuly
    
    function drawHodlers() public {
        require(actualHolderPriceIndex < holdersPrices.length, "No prizes for hodlers");
        require(owner == msg.sender, "Function is only for owner");
        uint countOfWinners = hodlers.length < 100 ? hodlers.length : 100; // Počet výher
        address[] memory winners = new address[](countOfWinners); // výherci pro event
        uint prize = mainGoalAmount * holdersPrices[actualHolderPriceIndex] / 100000; // mainGoalAmount * promile / 1000 / 100 hodlery
        uint index;
        address winner;
        uint8 maxRandoms;
        // každý hodler dostane cenu pouze jednou, tedy pokud je málo hodlerů, tak jich nebude 100
        for(uint8 p = 0; p < countOfWinners; p++){ // maximum 100
            maxRandoms = 10;
            do {
                index = random( countOfWinners, hodlers[hodlers.length/2] );
                winner = hodlers[index];
            } while (isWinner[winner] == actualHolderPriceIndex + 1 && maxRandoms-- > 1); // pokud wýherce již jednou vyhrál, losujeme znovu + opatření proti zacyklení
            isWinner[winner] = actualHolderPriceIndex+1;
            winners[p] = hodlers[index];
            payable(winner).transfer(prize); // odeslání odměny
            mainGoalAmount -= prize;
        }
        
        emit WinHodlers(actualHolderPriceIndex, winners, prize);
        
        actualHolderPriceIndex++;
    }
    


}


abstract contract BUYPIX is VAR, ERC721, DRAW, GOALS {
    
    constructor() {
    
    }
    
    
    // tady dodělat cenu
    event TokenPurchased (uint8 oldPhase, uint8 actualPhase, uint256 first, uint256 count, address newOwner);
    event VIPFounded (uint[] tokenIds, uint returnAmount, address owner, uint8 phase);
    
    receive() external payable { }
    
    function beforeBuyTokens (uint weiAmount) public view returns(bool, string memory, uint){
        uint tokens = weiAmount / phases[actualPhase].prize;
        uint rest = weiAmount % phases[actualPhase].prize;
        if(0 == tokens)
            return( true, "Not enough wei to buy a token",tokens);
        if(rest > 0)
            return( true, "Please send exact amount of wei",tokens);
        if(phases[actualPhase].tokensAmount < tokens)
            return( true, "Not enough tokens in actual phase",tokens);
        if(totalMintedTokens >= 10927)
            return( true, "All tokens purchased",tokens);

        return(false, "ok",tokens);
    }
    
    
    
    function buyTokens() public payable {
        (bool error, , uint tokens) = beforeBuyTokens(msg.value);
        
        require(!error, "Error, use method beforeBuyTokens(uint weiAmount)");


        uint oldTokenIndex = totalMintedTokens;
        uint returnAmount = 0;
        
        if(_balances[msg.sender] == 0){ // neměl žádné tokeny, 
            hodlersIndex[msg.sender] = hodlers.length; // a nastavíme jeho index
            hodlers.push(msg.sender); // přidáme ho do seznamu
        }
        
        for(uint i = 0; i < tokens; i++){
            _safeMint(msg.sender , totalMintedTokens+i); 
            mainGoalAmount = mainGoalAmount + phases[actualPhase].toGoalWallet - 20000000000000000;
            phases[actualPhase].buyers.push(msg.sender);

            // Testování množství tokenů při nákupu
            checkGoalReached(payable(msg.sender));

            // Losování VIP tokenu
            if(VIPsInPhases[actualPhase] > 0){ 
                uint8 isWin = phases[actualPhase].tokensAmount <= VIPsInPhases[actualPhase]? 1 : randomVIP(msg.sender, actualPhase, totalMintedTokens);
                if(isWin == 1){
                    VIPsInPhases[actualPhase]--;
                    VIPIndexes.push(totalMintedTokens+i);
                    returnAmount += phases[actualPhase].prize / 2; // Vracíme 50%
                }
            }
            phases[actualPhase].tokensAmount--;
        }
        
        if(returnAmount > 0){
            payable(msg.sender).transfer(returnAmount); // Vyplatíme za VIPIndexes
            emit VIPFounded(VIPIndexes, returnAmount, msg.sender, actualPhase);
            delete VIPIndexes; // smazání pole
        }
        
        totalMintedTokens += tokens;
        firstOwnners[msg.sender] += tokens;

        uint8 oldPhase = actualPhase;
    

        // Automatické losování
        if(phases[actualPhase].tokensAmount == 0){
            drawLots();
        }
        
        emit TokenPurchased(oldPhase, actualPhase, oldTokenIndex, tokens, msg.sender);
    }
    
    function randomVIP(address salt, uint8 phase, uint lastToken) view internal returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt, phase, lastToken))) % 2);
    }
}


contract VOTING is VAR {

    event Vote(ActionType actionType, uint proposalIndex, address addr, uint8 vote);
    event FinishVoting(ActionType actionType, bool result, uint proposalIndex);
    event ProposalCreated(uint endTime, ActionType actionType, address actionAddress, uint8[] percents, address[] addresses, uint amount, uint proposalIndex);
    
    enum ActionType {add_voter, remove_voter, set_percent, eth_emission}

    struct VoteStatus {
        address participant;
        uint8 vote; // 0 no 1 yes 2 resignation
    }
    
    struct Proposal {
        uint endTime;
        uint8 result; // 0 no 1 yes 2 notFinished
        ActionType actionType; // 0 add 1 remove participant 2 transfer ETH
        address actionAddress; // Add/Remove participant or transfer address
        uint8[] percents;
        address[] addresses;
        uint amount; // amount of transfered Wei
        address[] voters;
        uint8[] votes;
    }

    struct ParticipantVote {
        address addr;
        uint8 vote;
    }
    
    address[] public participants;
    mapping(address => uint8) participantPercent;
    Proposal[] proposals;
    
    VoteStatus[] status;
    
    constructor() {
        address one = 0x7fc34Ec9A397AF68B22b0F2565AC3cC3927DcD95;
        address two = 0x71DAfd62F010d5Eb701cA9f10d62358C3b280a6F;
        participants.push(one);
        participants.push(two);
        participantPercent[one] = 50;
        participantPercent[two] = 50;
    }
    
    //receive() external payable { }

    function beforeCreateProposal(ActionType _actionType, address _actionAddress, uint8[] memory _percents, address[] memory _addresses, address _senderAddress) public view returns(bool, string memory) {

        if(findParticipantIndex(_senderAddress) == 0)
            return(true, "You are not in participant");
            
        if(uint(_actionType) < 2) {
            uint index = findParticipantIndex(_actionAddress);
            if(_actionType == ActionType.add_voter && index != 0)
                return(true, "This participant already exist");
            if(_actionType == ActionType.remove_voter){
                if(participantPercent[_actionAddress] > 0)
                    return(true, "The participant to delete must have zero percent");
                if(index == 0)
                    return(true, "This is not participant address");
                if(participants.length <= 2)
                    return(true, "Minimal count of participants is 2");
            }
        }
        if(_actionType == ActionType.set_percent){
            if(_percents.length != participants.length)
                return(true, "Wrong percents length");
            if(_addresses.length != participants.length)
                return(true, "Wrong addresses length");
            uint8 total = 0;
            for(uint i = 0; _percents.length > i; i++){
                total += _percents[i];
            }
            if(total != 100)
                return(true, "The sum of the percentages must be 100");
        }
        return(false, "ok");
    }
    
    function createProposal( ActionType _actionType, address _actionAddress, uint8[] memory _percents, address[] memory _addresses, uint _amount) public {
        (bool error, string memory message) = beforeCreateProposal(_actionType, _actionAddress, _percents, _addresses, msg.sender);
        require (!error, message);

        uint time = block.timestamp + (3 * 24 hours); // Three days
        address[] memory emptyVoters;
        uint8[] memory emptyVotes;
        proposals.push(
            Proposal(time, 2,  _actionType, _actionAddress, _percents, _addresses, _amount, emptyVoters, emptyVotes)
        );
        emit ProposalCreated(time, _actionType, _actionAddress, _percents, _addresses, _amount, proposals.length-1);
    }
    
    function beforeVoteInProposal (uint proposalIndex, address senderAddress) public view returns(bool error, string memory description) {
        uint index = findParticipantIndex(senderAddress);
        if(index == 0)
            return(true, "You are not in participant");
        if(proposals.length <= proposalIndex)
            return(true, "Proposal not exist");
        if(proposals[proposalIndex].result != 2)
            return(true, "Proposal finished");
        if(block.timestamp >= proposals[proposalIndex].endTime)
            return(true, "Time for voting is out");

        for(uint i = 0; proposals[proposalIndex].voters.length > i; i++){
            if(proposals[proposalIndex].voters[i] == senderAddress){
                return(true, "You are already voted");
            }
        }
        return(false, "ok");
    }

    function voteInProposal (uint proposalIndex, uint8 vote) public{
        (bool error, string memory message) = beforeVoteInProposal(proposalIndex, msg.sender);
        require (!error, message);
        proposals[proposalIndex].voters.push(msg.sender);
        proposals[proposalIndex].votes.push(vote);
        emit Vote(proposals[proposalIndex].actionType, proposalIndex, msg.sender, vote);
    }

    function beforeFinishProposal (uint proposalIndex, address senderAddress) public view 
    returns(bool error, string memory message, uint votedYes, uint votedNo) {
        uint index = findParticipantIndex(senderAddress);
        uint _votedYes = 0;
        uint _votedNo = 0;
        
        for(uint i = 0; proposals[proposalIndex].voters.length > i; i++){
            if(proposals[proposalIndex].votes[i] == 1)
                _votedYes++;
            if(proposals[proposalIndex].votes[i] == 0)
                _votedNo++;
        }

        if(index == 0)
            return(true, "You are not in participant", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.add_voter && findParticipantIndex(proposals[proposalIndex].actionAddress) > 0)
            return(true, "This participant already exist", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.remove_voter && participants.length == 2)
            return(true, "Minimal count of voted participants is 2", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.remove_voter && participantPercent[proposals[proposalIndex].actionAddress] > 0)
            return(true, "The participant to delete must have zero percent", _votedYes, _votedNo);
        if(proposals.length <= proposalIndex)
            return(true, "Proposal does not exist", _votedYes, _votedNo);
        if(proposals[proposalIndex].result != 2)
            return(true, "Voting has finished", _votedYes, _votedNo);
        if(block.timestamp <= proposals[proposalIndex].endTime && proposals[proposalIndex].voters.length != participants.length)
            return(true, "Voting is not finished", _votedYes, _votedNo);
            // Tady změnit balance na konkrétní účet
        if(proposals[proposalIndex].actionType == ActionType.eth_emission && address(this).balance < proposals[proposalIndex].amount)
            return(true, "Low ETH balance", _votedYes, _votedNo);    
        
        if(proposals[proposalIndex].voters.length <= participants.length - proposals[proposalIndex].voters.length) // Minimum participants on proposal
            return(true, "Count of voted participants must be more than 50%", _votedYes, _votedNo);
        return(false, "ok", _votedYes, _votedNo);
    }
    
    function finishProposal(uint proposalIndex) public {
        (bool error, string memory message, uint votedYes, uint votedNo) = beforeFinishProposal(proposalIndex, msg.sender);
        require (!error, message);

        proposals[proposalIndex].result = votedYes > votedNo? 1 : 0;

        if(votedYes > votedNo){
            if(proposals[proposalIndex].actionType == ActionType.add_voter){ // Add participant
                participants.push(proposals[proposalIndex].actionAddress);
            } 
            else if (proposals[proposalIndex].actionType == ActionType.remove_voter) { // Remove participant
                uint index = findParticipantIndex(proposals[proposalIndex].actionAddress) - 1;
                participants[index] = participants[participants.length-1]; // Copy last item on removed position and
                participants.pop(); // remove last
            }
            else if (proposals[proposalIndex].actionType == ActionType.set_percent){
                for(uint i = 0; proposals[proposalIndex].addresses.length > i; i++){
                    participantPercent[proposals[proposalIndex].addresses[i]] = proposals[proposalIndex].percents[i];
                }
            }
            else if (proposals[proposalIndex].actionType == ActionType.eth_emission) { // Transfer ETH
                uint totalSend = proposals[proposalIndex].amount;
                uint remains = totalSend;
                for(uint i = 0; participants.length > i; i++){
                    if(i < participants.length-1){
                        payable(participants[i]).transfer(totalSend/100*participantPercent[participants[i]]);
                        remains -= totalSend/100*participantPercent[participants[i]];
                    }
                    else
                        payable(participants[i]).transfer(remains);
                }
               
            }
        }
        emit FinishVoting(proposals[proposalIndex].actionType, votedYes > votedNo, proposalIndex);
    }

    function statusOfProposal (uint index) public view returns (address[] memory, uint8[] memory) {
        require(proposals.length > index, "Proposal at index not exist");
        return (proposals[index].voters, proposals[index].votes);
    }
    
    function getProposal(uint index) public view returns( uint endTime, uint8 result, ActionType actionType, address actionAddress, 
    uint8[] memory percents, address[] memory addresses, uint amount, address[] memory voters, uint8[] memory votes) {
        require(proposals.length > index, "Proposal at index not exist");
        Proposal memory p = proposals[index];
        return (p.endTime, p.result, p.actionType, p.actionAddress, p.percents, p.addresses, p.amount, p.voters, p.votes);
    }

    function proposalsLength () public view returns (uint) {
        return proposals.length;
    }

    function participantsLength () public view returns (uint) {
        return participants.length;
    }
    
    function percentagePayouts () public view returns (address[] memory participantsAdresses, uint8[] memory percents) {
        uint8[] memory pom = new uint8[](participants.length);
        for(uint i = 0; participants.length > i; i++){
            pom[i] = participantPercent[participants[i]];
        }
        return (participants, pom);
    }
    
    function findParticipantIndex(address addr) private view returns (uint) {
        for(uint i = 0; participants.length > i; i++){
            if(participants[i] == addr)
            return i+1;
        }
        return 0;
    }
}


contract DECENTRAL_ART is VAR, ERC721, DRAW, BUYPIX, VOTING {
    
    event PricesUpdated (uint256[] tokenIds, uint[] prices, address owner);
    event TokensSold (uint256[] tokenIds, uint[] tokenPrices, uint fee, address newOwner);
    event ContractCreated (uint TransferFee, Phase[] Phases);
    
    uint transferFee = 15000;
    
    constructor() ERC721("Decentral ART", "ART"){
        owner = msg.sender;
        
        emit ContractCreated(transferFee, phases);
    }
    
    function setTransferFee(uint fee) public {
        require(owner == msg.sender, "Function is only for owner");
        transferFee = fee;
    }
    
    function getTransferFee() public view  returns (uint fee){
        return transferFee;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public  override payable{
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(msg.value == transferFee, "ART: not payed transfer fee. Please use method getTransferFee()");
        require(sellingPrice[tokenId] == 0, "ART: token is set to sell. Please use method setSellingPrices() and set price to zero.");
        _transfer(from, to, tokenId);
        
        checkGoalReached(payable(msg.sender));
        checkHodler(msg.sender);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override payable{
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(msg.value == transferFee, "ART: not payed transfer fee. Please use method getTransferFee()");
        require(sellingPrice[tokenId] == 0, "ART: token is set to sell. Please use method setSellingPrices() and set price to zero.");
        _safeTransfer(from, to, tokenId, _data);
        
        checkGoalReached(payable(msg.sender));
        checkHodler(msg.sender);
    }
    
    function beforeSetSellingPrices(uint256[] memory tokenIds, uint[] memory prices) public view returns (bool error, string memory description){
        if(tokenIds.length != prices.length)
            return( true, "Not same size of arrays");
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            if(_owners[tokenIds[i]] != msg.sender){
                return( true, "You are not owner of selected tokens");
            }
        }

        return(false, "ok");
    }
    
    function setSellingPrices(uint256[] memory tokenIds, uint[] memory prices) public {
        (bool error,  ) = beforeSetSellingPrices(tokenIds, prices);
        
        require(!error, "Error, use method beforeSetSellingPrices(uint256[] memory tokenIds, uint[] memory prices)");
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            sellingPrice[tokenIds[i]] = prices[i];
        }
        emit PricesUpdated(tokenIds, prices, msg.sender);
    }
    
    function beforeBuyOfferedTokens(uint256[] memory tokenIds, uint sendingETH) public view returns (bool error, string memory description, uint fee){
        uint _price = 0;
        uint _fee = 0;
        for(uint256 i = 0; i < tokenIds.length; i++){
            if(sellingPrice[tokenIds[i]] == 0){
                return( true, "One of the selected tokens is not for sale.", _fee);
            }
            _price += sellingPrice[tokenIds[i]];
        }
        _fee = _price * 45;
        _fee = _fee / 1000;
        
        if(sendingETH != _price + _fee)
            return( true, "You are sending wrong amount of ETH.", _fee);
            
        return(false, "ok", _fee);
    }
    
    function buyOfferedTokens(uint256[] memory tokenIds) payable public {
        (bool error, ,uint256 fee) = beforeBuyOfferedTokens(tokenIds, msg.value);
        require(!error, "Error, use method beforeBuyOfferedTokens(uint256[] memory tokenIds, uint sendingETH)");
        
        if(_balances[msg.sender] == 0){ // neměl žádné tokeny, 
            hodlersIndex[msg.sender] = hodlers.length; // a nastavíme jeho index
            hodlers.push(msg.sender); // přidáme ho do seznamu
        }
        
        uint[] memory tokenPrices = new uint[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++){
            address payable oldOwner = payable(_owners[tokenIds[i]]);
             oldOwner.transfer(sellingPrice[tokenIds[i]]); // Přesun ETH bývalému vlastníkovi
             _transfer(oldOwner, msg.sender, tokenIds[i]); // Přesun tokenu
             
             checkHodler(oldOwner); // Kontrola zda bývalý hodler nemá 0 tokenů
             
             tokenPrices[i] = sellingPrice[tokenIds[i]];
             sellingPrice[tokenIds[i]] = 0; // Nastavení ceny na nulu aby se nemohl dále prodávat
        }
        emit TokensSold(tokenIds, tokenPrices, fee, msg.sender); // Událost
        mainGoalAmount += fee * 100 / 225;
    }
    
    function checkHodler(address hodler) internal {
        if(_balances[hodler] == 0){ // nemá žádné tokeny, 
            uint index = hodlersIndex[hodler];
            if(index < hodlers.length-1){ // Je li na posledním místě, tak se jen udělá pop
                hodlers[index] = hodlers[hodlers.length-1]; // Pokud ne, poslední hodler se přesune na místo mazaného
                hodlersIndex[hodlers[hodlers.length-1]] = index; // a přepíše se index přesouvaného
            }
            hodlers.pop(); // Smažeme posledního
        }
    }
    
    struct Owner {
        address owner;
        uint256[] winners;
    }
}