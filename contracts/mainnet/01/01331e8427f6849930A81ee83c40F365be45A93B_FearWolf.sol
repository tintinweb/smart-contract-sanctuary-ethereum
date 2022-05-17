// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


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
 * @dev Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 */
interface IERC721Receiver is IERC165 {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    function toString(bytes32 value) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && value[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && value[i] != 0; i++) {
            bytesArray[i] = value[i];
        }
        return string(bytesArray);
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
 * via _msgSender() and msg.data, they should not be accessed in such a direct
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
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId] || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}



/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165Storage, IERC721, IERC721Metadata {
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

        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
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
    function ownerOf(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (address) {
        return _owners[tokenId];
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
    function tokenURI(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (string memory) {
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
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (address) {
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual tokenExists(tokenId) returns (bool) {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _mint(address to, uint256 tokenId) internal virtual tokenNotMinted(tokenId) {
        require(to != address(0), "ERC721: mint to the zero address");

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            }
            catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        else {
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}


    /**
     * @dev Modifier that checks that token exists. Reverts if token doesn't exist.
     */
    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "ERC721: query for nonexistent token");
        _;
    }

    /**
     * @dev Modifier that checks that token is not minted (doesn't exist). Reverts if token exists.
     */
    modifier tokenNotMinted(uint256 tokenId) {
        require(!_exists(tokenId), "ERC721: token already minted");
        _;
    }
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



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

    constructor() {
        _registerInterface(type(IERC721Enumerable).interfaceId);
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



interface IMRC721 is IERC721 {
    function mint(address owner, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
    function totalSupply() external view returns (uint256);
}



interface IMRC721Metadata is IMRC721 {
    function mint(address to, uint256 id, bytes calldata data) external;
    function encodeParams(uint256 id) external view returns(bytes memory);
    function encodeParams(uint256[] calldata ids) external view returns(bytes memory);
}




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}




/**
 * @dev Interface of a contract containing identifier for Root role.
 */
interface IRoleContainerRoot {
    /**
    * @dev Returns Root role identifier.
    */
    function ROOT_ROLE() external view returns (bytes32);
}




/**
 * @dev Interface of a contract containing identifier for Admin role.
 */
interface IRoleContainerAdmin {
    /**
    * @dev Returns Admin role identifier.
    */
    function ADMIN_ROLE() external view returns (bytes32);
}



/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 */
abstract contract AccessControl is Context, ERC165Storage, IAccessControl, IRoleContainerAdmin {
    /**
    * @dev Root Admin role identifier.
    */
    bytes32 public constant ROOT_ROLE = "Root";

    /**
    * @dev Admin role identifier.
    */
    bytes32 public constant ADMIN_ROLE = "Admin";

    /**
    * @dev Manager role identifier.
    */
    bytes32 public constant MANAGER_ROLE = "Manager";

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor() {
        _registerInterface(type(IAccessControl).interfaceId);

        _setupRole(ROOT_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ROOT_ROLE);
        _setRoleAdmin(MANAGER_ROLE, ROOT_ROLE);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toString(role)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) private {
        _grantRole(role, account);
        _setRoleAdmin(role, ROOT_ROLE);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




/**
 * @dev Interface for contract which allows to pause and unpause the contract.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
    
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
    * @dev Pauses the contract.
    */
    function pause() external;

    /**
    * @dev Unpauses the contract.
    */
    function unpause() external;
}




/**
 * @dev Interface of a contract containing identifier for Pauser role.
 */
interface IRoleContainerPauser {
    /**
    * @dev Returns Pauser role identifier.
    */
    function PAUSER_ROLE() external view returns (bytes32);
}



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is AccessControl, IPausable, IRoleContainerPauser {
    /**
    * @dev Pauser role identifier.
    */
    bytes32 public constant PAUSER_ROLE = "Pauser";

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _registerInterface(type(IPausable).interfaceId);

        _setRoleAdmin(PAUSER_ROLE, ROOT_ROLE);

        _paused = true;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
   
    /**
    * @dev This function is called before pausing the contract.
    * Override to add custom pausing conditions or actions.
    */
    function _beforePause() internal virtual {
    }

    /**
    * @dev This function is called before unpausing the contract.
    * Override to add custom unpausing conditions or actions.
    */
    function _beforeUnpause() internal virtual {
    }

    /**
    * @dev Pauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused.
    */
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _beforePause();
        _pause();
    }

    /**
    * @dev Unpauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused;
    */
    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _beforeUnpause();
        _unpause();
    }
}



contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract OpenSeaCompatible is AccessControl {
    using Strings for uint256;

    string private contractUri;
    string private tokenBaseUri;
    string private tokenUriExtension;
    address private proxyRegistryAddress;
    mapping (uint256 => string) private customTokenUri;

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    // To support Opensea token-level metadata (ERC721)
    // https://docs.opensea.io/docs/metadata-standards
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory customUri = customTokenUri[tokenId];

        if (bytes(customUri).length > 0)
            return customUri;
        else
            return bytes(tokenBaseUri).length > 0 ? string(abi.encodePacked(tokenBaseUri, tokenId.toString(), tokenUriExtension)) : "";
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function _isOpenSeaProxy(address owner, address operator) internal view returns (bool) {
        if (proxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            return address(proxyRegistry.proxies(owner)) == operator;
        }
        
        return false;
    }

    function setContractURI(string calldata uri) external onlyRole(ADMIN_ROLE) {
        contractUri = uri;
    }

    function setBaseTokenURI(string calldata uri) external onlyRole(ADMIN_ROLE) {
        tokenBaseUri = uri;
    }

    function setTokenURIExtension(string calldata extension) external onlyRole(ADMIN_ROLE) {
        tokenUriExtension = extension;
    }

    function setCustomTokenUri(uint256 tokenId, string calldata uri) external onlyRole(ADMIN_ROLE) {
        customTokenUri[tokenId] = uri;
    }
    
    // OPENSEA PROXIES
    // ethereum: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    // rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
    // polygon: ?
    // bsc: ?
    function setProxyRegistryAddress(address proxyAddress) external onlyRole(ADMIN_ROLE) {
        proxyRegistryAddress = proxyAddress;
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
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
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
 * @dev Base data contract for FEAR Wolf.
 */
abstract contract FearWolfBase {

    uint64 public constant INBORN_DATA_SIZE_BITS = 36;
    uint64 public constant INBORN_CONTAINER_HULL = uint64(2 ** INBORN_DATA_SIZE_BITS);
    uint64 public constant FULL_DATA_SIZE_BITS = 92;
    uint64 public constant FULL_CONTAINER_HULL = uint64(2 ** FULL_DATA_SIZE_BITS);

    struct WolfParams {
        bool clanLeader;
        uint8 rank;
        uint8 clan;
        uint8 breed;
        Traits traits;
        UpgradeRates upgradeRates;
    }

    struct Traits {
        uint8 strength;
        uint8 speed;
        uint8 endurance;
        uint8 intelligence;
        uint8 howl;
        uint8 spirit;
        uint8 loyalty;
    }

    struct UpgradeRates {
        uint8 strengthRate;
        uint8 speedRate;
        uint8 enduranceRate;
        uint8 intelligenceRate;
        uint8 howlRate;
        uint8 spiritRate;
        uint8 loyaltyRate;
    }
    
    function _packParams(WolfParams memory params) internal pure returns(uint256 packedParams) {
        packedParams += params.traits.loyalty;
        packedParams <<= 8;
        packedParams += params.traits.spirit;
        packedParams <<= 8;
        packedParams += params.traits.howl;
        packedParams <<= 8;
        packedParams += params.traits.intelligence;
        packedParams <<= 8;
        packedParams += params.traits.endurance;
        packedParams <<= 8;
        packedParams += params.traits.speed;
        packedParams <<= 8;
        packedParams += params.traits.strength;
        packedParams <<= 4;
        packedParams += params.upgradeRates.loyaltyRate;
        packedParams <<= 4;
        packedParams += params.upgradeRates.spiritRate;
        packedParams <<= 4;
        packedParams += params.upgradeRates.howlRate;
        packedParams <<= 4;
        packedParams += params.upgradeRates.intelligenceRate;
        packedParams <<= 4;
        packedParams += params.upgradeRates.enduranceRate;
        packedParams <<= 4;
        packedParams += params.upgradeRates.speedRate;
        packedParams <<= 4;
        packedParams += params.upgradeRates.strengthRate;
        packedParams <<= 3;
        packedParams += params.breed;
        packedParams <<= 3;
        packedParams += params.clan;
        packedParams <<= 2;
        packedParams += params.rank;

        if (params.clanLeader)
            packedParams += 3;
    }

    function _unpackParams(uint256 packedParams) internal pure returns (WolfParams memory params) {
        params.rank = uint8((packedParams % (2**2)) % 3);
        params.clan = uint8((packedParams >> 2) % 8);
        params.breed = uint8((packedParams >> 5) % 8);
        params.clanLeader = packedParams % 4 == 3;
        params.upgradeRates.strengthRate = uint8((packedParams >> 8) % 16);
        params.upgradeRates.speedRate = uint8((packedParams >> 12) % 16);
        params.upgradeRates.enduranceRate = uint8((packedParams >> 16) % 16);
        params.upgradeRates.intelligenceRate = uint8((packedParams >> 20) % 16);
        params.upgradeRates.howlRate = uint8((packedParams >> 24) % 16);
        params.upgradeRates.spiritRate = uint8((packedParams >> 28) % 16);
        params.upgradeRates.loyaltyRate = uint8((packedParams >> 32) % 16);
        params.traits.strength = uint8((packedParams >> 36) % 16);
        params.traits.speed = uint8((packedParams >> 44) % 16);
        params.traits.endurance = uint8((packedParams >> 52) % 16);
        params.traits.intelligence = uint8((packedParams >> 60) % 16);
        params.traits.howl = uint8((packedParams >> 68) % 16);
        params.traits.spirit = uint8((packedParams >> 76) % 16);
        params.traits.loyalty = uint8((packedParams >> 84) % 16);
    }
}



interface IFuzzer {
    function getFuzz() external view returns (uint256);
}


/**
 * @dev Contract of FEAR Wolf NFT (ERC-721).
 */
contract FearWolf is FearWolfBase, ERC721Enumerable, AccessControl, Pausable, OpenSeaCompatible, VRFConsumerBase, IMRC721Metadata {

    /**
    * @dev Emitted when token parameters are updated.
    */
    event TokenUpdated(uint256 indexed tokenId, uint256 curParams, uint256 newParams, address operator);

    bytes32 public constant DISTRIBUTOR_ROLE = "Distributor";
    bytes32 public constant OPERATOR_ROLE = "Operator";
    bytes32 public constant BRIDGER_ROLE = "Bridger";

    uint64 private constant MAIN_CHAINID = 1;
    uint64 private constant RANDOM_DATA_SIZE_BITS = 40; // we need 39, but leave some extra here. still have capacity for that
    uint64 private constant RANDOM_CONTAINER_HULL = uint64(2 ** RANDOM_DATA_SIZE_BITS);
    uint64 private constant RANDOMNESS_SPLIT = 256 / RANDOM_DATA_SIZE_BITS;

    uint8 private constant ALPHA = 0;
    uint8 private constant BETA = 1;
    uint8 private constant OMEGA = 2;

    uint8 private constant STRENGTH = 0;
    uint8 private constant SPEED = 1;
    uint8 private constant ENDURANCE = 2;
    uint8 private constant INTELLIGENCE = 3;
    uint8 private constant HOWL = 4;
    uint8 private constant SPIRIT = 5;
    uint8 private constant LOYALTY = 6;

    uint8 private constant MIN = 0;
    uint8 private constant MAX = 1;

    // VRF
    bytes32 private vrfKeyHash;
    uint256 private vrfFee;

    mapping (uint256 => uint256) private wolfParams;

    uint256 private generationRandomness;
    uint256 private distributionRandomness;
    uint256 private fuzz = 1;

    uint64 private unownedWolvesCount;
    uint64[] private wolvesRandomness;

    uint16 private chainStartId;
    uint16 private chainPopulation;

    // ranks-clans-breeds-traits (generation stuff)
    uint16[] private ranksLimits;         // total on all chains: [666, 1350, 4650];
    uint16[] private rankPerClanLimits;   // total on all chains: [133, 270, 930]; // alpha, beta, omega
    uint16[] private breedPerRankLimits;  // total on all chains: [133, 135, 186]; // alpha, beta, omega

    uint16[][] private rankClanCounts = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]];
    uint16[][] private breedClanCounts = [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]];
    uint8[][][] private ratesLimits = [[[9, 10], [6, 9], [1, 8]], [[9, 10], [6, 9], [1, 8]], [[9, 10], [6, 9], [1, 8]], [[7, 10], [5, 8], [1, 8]], [[7, 10], [5, 8], [1, 8]], [[7, 10], [5, 8], [1, 8]], [[7, 10], [5, 8], [1, 8]]];
    bool[] private clanLeadersSet = [false, false, false, false, false];
    
    bool private mysteryBoxMode = true;
    

    constructor(address vrfCoordinatorAddress, address linkTokenAddress, bytes32 _vrfKeyHash, uint256 _vrfFee)
        ERC721("FEAR Wolf", "FEARWOLF")
        VRFConsumerBase(vrfCoordinatorAddress, linkTokenAddress)
    {
        _setRoleAdmin(DISTRIBUTOR_ROLE, ROOT_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, ROOT_ROLE);
        _setRoleAdmin(BRIDGER_ROLE, ROOT_ROLE);

        vrfKeyHash = _vrfKeyHash;
        vrfFee = _vrfFee;

        wolfParams[0] = 0; // params for mystery box
    }

    function _beforePause() internal virtual override {
        revert("Once unleashed FEAR Wolf cannot be stopped"); // cannot pause!
    }

    function _beforeUnpause() internal virtual override {
        require(unownedWolvesCount == chainPopulation, "Not enough unowned wolves");
        require(ranksLimits.length > 0, "Limits are not set");
    }

    function _getTotalCountByRank(uint256 rank) private view returns (uint16) {
        return rankClanCounts[rank][0] + rankClanCounts[rank][1] + rankClanCounts[rank][2] + rankClanCounts[rank][3] + rankClanCounts[rank][4];
    }

    function _normalize(uint256 value, uint256 min, uint256 max) private pure returns (uint256) {
        uint256 interval = max - min + 1;
        return value % interval + min;
    }
    function _normalizeByte(uint8 value, uint8 min, uint8 max) private pure returns (uint8) {
        uint8 interval = max - min + 1;
        return value % interval + min;
    }

    function _getCurrentRandomness(uint256 initialRandomness, uint256 i) private view returns (uint256) {
        return uint256(keccak256(abi.encode(initialRandomness, block.timestamp, i)));
    }
    function _getNextRandomTokenIndex(uint256 i) private view returns (uint256) {
        return _getCurrentRandomness(distributionRandomness, i) % chainPopulation;
    }


    //// RANDOMIZATION

    // Chainlink VRF handler
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        if (distributionRandomness == 0)
            distributionRandomness = randomness;
        else if (generationRandomness == 0)
            generationRandomness = randomness;
    }

    function _randomizeWolf(uint256 tokenId, uint64 randomness) private {
        (uint8 rank, uint8 clan, uint8 breed) = _determineRankClanBreed(randomness);
        bool clanLeader = !clanLeadersSet[clan] && rankClanCounts[ALPHA][clan] >= rankPerClanLimits[ALPHA] / 10 && randomness % 32 == 0 && block.chainid == MAIN_CHAINID;

        WolfParams memory params;
        params.rank = rank;
        params.clan = clan;
        params.breed = breed;
        params.clanLeader = clanLeader;
        params.upgradeRates.strengthRate = _normalizeByte(uint8((randomness >> 11) % 16), ratesLimits[STRENGTH][rank][MIN], ratesLimits[STRENGTH][rank][MAX]);
        params.upgradeRates.speedRate = _normalizeByte(uint8((randomness >> 15) % 16), ratesLimits[SPEED][rank][MIN], ratesLimits[SPEED][rank][MAX]);
        params.upgradeRates.enduranceRate = _normalizeByte(uint8((randomness >> 19) % 16), ratesLimits[ENDURANCE][rank][MIN], ratesLimits[ENDURANCE][rank][MAX]);
        params.upgradeRates.intelligenceRate = _normalizeByte(uint8((randomness >> 23) % 16), ratesLimits[INTELLIGENCE][rank][MIN], ratesLimits[INTELLIGENCE][rank][MAX]);
        params.upgradeRates.howlRate = _normalizeByte(uint8((randomness >> 27) % 16), ratesLimits[HOWL][rank][MIN], ratesLimits[HOWL][rank][MAX]);
        params.upgradeRates.spiritRate = _normalizeByte(uint8((randomness >> 31) % 16), ratesLimits[SPIRIT][rank][MIN], ratesLimits[SPIRIT][rank][MAX]);
        params.upgradeRates.loyaltyRate = _normalizeByte(uint8((randomness >> 35) % 16), ratesLimits[LOYALTY][rank][MIN], ratesLimits[LOYALTY][rank][MAX]);

        if (clanLeader) {
            _boostClanLeader(params);
            clanLeadersSet[clan] = true;
        }

        wolfParams[tokenId] = _packParams(params);

        rankClanCounts[rank][clan]++;
        breedClanCounts[breed][clan]++;
    }

    function _determineRankClanBreed(uint256 randomness) private view returns (uint8 rank, uint8 clan, uint8 breed) {
        if (randomness % 32 >= 10)
            rank = OMEGA;
        else if (randomness % 32 >= 3)
            rank = BETA;
        
        while (_getTotalCountByRank(rank) == ranksLimits[rank])
            rank = (rank + 1) % 3;

        if (rank == ALPHA && block.chainid == MAIN_CHAINID && _getTotalCountByRank(ALPHA) == ranksLimits[ALPHA] - 1) {
            clan = 4; // last alpha on the main chain goes to Vanguards
        }
        else {
            clan = uint8((randomness >> 5) % 5);
            while (rankClanCounts[rank][clan] >= rankPerClanLimits[rank])
                clan = (clan + 1) % 5;
        }

        if (rank == BETA) {
            breed = _normalizeByte(uint8((randomness >> 8) % 2), 1, 2);
            while (breedClanCounts[breed][clan] == breedPerRankLimits[rank])
                breed = (breed % 2) + 1; // 1 -> 2, 2 -> 1
        }
        else if (rank == OMEGA) {
            breed = _normalizeByte(uint8((randomness >> 8) % 5), 3, 7);
            while (breedClanCounts[breed][clan] == breedPerRankLimits[rank] || breed < 3)
                breed = (breed + 1) % 8;
        }
    }

    function _boostClanLeader(WolfParams memory params) private view {
        if (params.upgradeRates.strengthRate < ratesLimits[STRENGTH][ALPHA][MAX])
            params.upgradeRates.strengthRate += 1;
        if (params.upgradeRates.speedRate < ratesLimits[SPEED][ALPHA][MAX])
            params.upgradeRates.speedRate += 1;
        if (params.upgradeRates.enduranceRate < ratesLimits[ENDURANCE][ALPHA][MAX])
            params.upgradeRates.enduranceRate += 1;
        if (params.upgradeRates.intelligenceRate < ratesLimits[INTELLIGENCE][ALPHA][MAX])
            params.upgradeRates.intelligenceRate += 1;
        if (params.upgradeRates.howlRate < ratesLimits[HOWL][ALPHA][MAX])
            params.upgradeRates.howlRate += 1;
        if (params.upgradeRates.spiritRate < ratesLimits[SPIRIT][ALPHA][MAX])
            params.upgradeRates.spiritRate += 1;
        if (params.upgradeRates.loyaltyRate < ratesLimits[LOYALTY][ALPHA][MAX])
            params.upgradeRates.loyaltyRate += 1;
    }


    //// DISTRIBUTION

    /**
    * @dev Allows to mint and randomize new FEAR Wolf and assign it to the owner.
    * @param initialOwner Owner address.
    * @param wolvesCount Number of wolves to mint.
    * Requirements:
    * - Contract must not be paused;
    * - Caller must have 'DISTRIBUTOR_ROLE';
    * - Number of still unowned wolves must be greater than or equal to amount of wolves to mint.
    */
    function setInitialOwner(address initialOwner, uint256 wolvesCount) external whenNotPaused onlyRole(DISTRIBUTOR_ROLE) {
        require(unownedWolvesCount >= wolvesCount, "Not enough unowned wolves");

        for (uint i = 0; i < wolvesCount; i++) {
            uint256 tokenIndex = _normalize(_getNextRandomTokenIndex(i), 0, unownedWolvesCount - 1);
            uint64 randomness = wolvesRandomness[tokenIndex];
            uint64 tokenId = randomness >> RANDOM_DATA_SIZE_BITS;
            
            wolvesRandomness[tokenIndex] = wolvesRandomness[unownedWolvesCount - 1];
            delete wolvesRandomness[unownedWolvesCount - 1];
            unownedWolvesCount--;

            _safeMint(initialOwner, tokenId);
            _randomizeWolf(tokenId, randomness);
        }
    }


    //// VIEW AND UPDATE

    /**
    * @dev Returns FEAR Wolf parameters in human-readable format.
    * @param tokenId Id of FEAR Wolf.
    * Requirements:
    * - Token with provided id must exist.
    */
    function getTokenParams(uint256 tokenId) external view tokenExists(tokenId) returns (WolfParams memory) {
        return _unpackParams(mysteryBoxMode ? wolfParams[0] : wolfParams[tokenId]);
    }

    /** @dev Returns FEAR Wolf parameters in raw format.
    * @param tokenId Id of FEAR Wolf.
    * Requirements:
    * - Token with provided id must exist.
    */
    function getRawTokenParams(uint256 tokenId) external view tokenExists(tokenId) returns (uint256) {
        return mysteryBoxMode ? wolfParams[0] : wolfParams[tokenId];
    }

    /** @dev Updates FEAR Wolf parameters.
    * @param tokenId Id of FEAR Wolf.
    * Requirements:
    * - Token with provided id must exist;
    * - Caller must have 'OPERATOR_ROLE';
    * - Inborn parameters (rank/clan/breed/upgradeRates) must stay unaltered.
    * Emits {TokenUpdated} event on success.
    */
    function updateTokenParams(uint256 tokenId, uint256 params) external tokenExists(tokenId) onlyRole(OPERATOR_ROLE) {
        uint256 curParams = wolfParams[tokenId];
        require(curParams % INBORN_CONTAINER_HULL == params % INBORN_CONTAINER_HULL, "Inborn parameters was changed");
        
        wolfParams[tokenId] = params;
        emit TokenUpdated(tokenId, curParams, params, _msgSender());
    }

    
    //// OPENSEA AND ERC721ENUMERABLE STUFF

    function isApprovedForAll(address owner, address operator) public view override(ERC721, IERC721) returns (bool) {
        return _isOpenSeaProxy(owner, operator) || super.isApprovedForAll(owner, operator);
    }

    function totalSupply() public view virtual override(ERC721Enumerable, IMRC721) returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }

    function tokenURI(uint256 tokenId) public view virtual override tokenExists(tokenId) returns (string memory) {
        return OpenSeaCompatible._tokenURI(tokenId);
    }


    //// MUON BRIDGING

    function encodeParams(uint256 id) public view returns(bytes memory){
        return abi.encode(wolfParams[id] * fuzz);
    }

    function encodeParams(uint256[] calldata ids) public view returns(bytes memory){
    	bytes[] memory params = new bytes[](ids.length);
    	for(uint i = 0; i < ids.length; i++)
    		params[i] = encodeParams(ids[i]);
    	return abi.encode(params);
    }

    function mint(address, uint256) external view onlyRole(BRIDGER_ROLE) {
        revert("Use mint with data argument");
    }

    function mint(address to, uint256 id, bytes calldata data) external tokenNotMinted(id) onlyRole(BRIDGER_ROLE) {
        _safeMint(to, id);
        wolfParams[id]= abi.decode(data, (uint256)) / fuzz;
    }

    function burn(uint256 tokenId) external onlyRole(BRIDGER_ROLE) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function tokensOfOwner(address owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(owner);
        uint256[] memory tokensIds = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++)
            tokensIds[i] = tokenOfOwnerByIndex(owner, i);
        
        return tokensIds;
    }


    //// ADMIN SETUP FUNCTIONS

    function loadInitialRandomness() external whenPaused onlyRole(ADMIN_ROLE) {
        requestRandomness(vrfKeyHash, vrfFee);
        requestRandomness(vrfKeyHash, vrfFee);
    }

    function scaleGenerationRandomness(uint16 iterations) external whenPaused onlyRole(ADMIN_ROLE) {
        require(generationRandomness > 0, "Initial randomness is not set");
        require(chainPopulation > 0, "Chain parameters are not set");

        uint64 fullSteps = iterations * RANDOMNESS_SPLIT;
        if (unownedWolvesCount + fullSteps > chainPopulation)
            fullSteps = chainPopulation - unownedWolvesCount;

        uint256 currentRandomness;
        for (uint i = 0; i < fullSteps; i++) {
            if (i % RANDOMNESS_SPLIT == 0)
                currentRandomness = _getCurrentRandomness(generationRandomness, i);

            wolvesRandomness.push(
                uint64((currentRandomness >> (RANDOM_DATA_SIZE_BITS * (i % RANDOMNESS_SPLIT))) % RANDOM_CONTAINER_HULL + (RANDOM_CONTAINER_HULL * (unownedWolvesCount + i + chainStartId))));
        }

        unownedWolvesCount += fullSteps;
    }

    function getUnownedWolvesCount() external view onlyRole(ADMIN_ROLE) returns (uint64) {
        return unownedWolvesCount;
    }

    function setMysteryBoxModeState(bool state) external onlyRole(ADMIN_ROLE) {
        mysteryBoxMode = state;
    }

    function setFuzz(address _address) external onlyRole(ADMIN_ROLE) {
        fuzz = IFuzzer(_address).getFuzz();
    }

    function setChainParameters(uint16 _chainStartId, uint16 _chainPopulation) external whenPaused onlyRole(ADMIN_ROLE) {
        chainStartId = _chainStartId;
        chainPopulation = _chainPopulation;
        delete wolvesRandomness;
        unownedWolvesCount = 0;
    }

    function setLimits(uint16[] memory _ranksLimits, uint16[] memory _rankPerClanLimits, uint16[] memory _breedPerRankLimits) external whenPaused onlyRole(ADMIN_ROLE) {
        require(_ranksLimits.length == 3 &&_rankPerClanLimits.length == 3 && _breedPerRankLimits.length == 3, "Incorrect limits");
        ranksLimits = _ranksLimits;
        rankPerClanLimits = _rankPerClanLimits;
        breedPerRankLimits = _breedPerRankLimits;
    }
}