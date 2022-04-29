// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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


// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

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





// File: @openzeppelin/contracts/utils/Strings.sol
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

// File: @openzeppelin/contracts/utils/Address.sol



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



// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
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



// File: @openzeppelin/contracts/utils/Context.sol
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


// File: @openzeppelin/contracts/token/ERC721/ERC721.sol
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





// File: @openzeppelin/contracts/access/Ownable.sol
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




// Creator: Chiru Labs

pragma solidity ^0.8.4;

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
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
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement 
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

            _currentIndex = updatedIndex;
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
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
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}



// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}





// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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



/////////////////////////////////////////
/////🦔INTERFACES🦔/////////////////////
////////////////////////////////////////

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}


pragma solidity ^0.8.12;
interface InterfaceDescriptor {
    function renderBottom(uint256 _bottom) external view returns (bytes memory);
    function renderClothes(uint256 _clothes) external view returns (bytes memory);
    function renderBack(uint256 _back) external view returns (bytes memory);
    function renderAccessory(uint256 _accessory) external view returns (bytes memory);
    function renderHeadgear(uint256 _headgear) external view returns (bytes memory);
    function renderMouth(uint256 _mouth) external view returns (bytes memory);
    function renderBackground(uint256 _background) external view returns (bytes memory);
    function renderEyes(uint256 _eyes) external view returns (bytes memory);
    function renderLegendary(uint256 _legendary) external view returns (bytes memory);
    }

// File: contracts/edgehogs.sol
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// (((((((((((((((((((((((((((((((((%%%(((%%%(((%%%(((%%%%%%(((((((((((((((((((((((((((((((((((((((
// (((((((((((((((((((((((((((((((((@@@(((@@@(((@@@(((@@@@@@(((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((@@@(((@@@&&&@@@&&&@@@%%%@@@%%%%%%@@@((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((@@@@@@&&&%%%&&&%%%%%%###%%%###%%%###@@@(((((((((((((((((((((((((((((((((
// (((((((((((((((((((((@@@&&&%%%######%%%%%%######%%%###%%%###%%%@@@((((((((((((((((((((((((((((((
// ((((((((((((((((((@@@&&&&&&&&&%%%###%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@(((((((((((((((((((((((((((
// ((((((((((((######&&&&&&%%%&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@#########((((((((((((((((((
// ((((((((((((@@@@@@&&&&&&###@@@@@@@@@###%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@@@((((((((((((((((((
// (((((((((((((((@@@&&&%%%###@@@******%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@******&@@((((((((((((((((((
// (((((((((((((((@@@&&&%%%###%%%@@@***%%%///,,,,,,,,,%%%%%%*,,,,,,,,///***&@@(((((((((((((((((((((
// (((((((((@@@@@@&&&&&&&&&%%%%%%%%%@@@(//,,,,,,,,,,,,,,,,,,,,,,,,//////###@@@(((((((((((((((((((((
// ((((((((((((@@@&&&%%%%%%%%%%%%%%%@@@(//,,,,,,@@@   ,,,,,,,,,///@@@   ###@@@(((((((((((((((((((((
// ((((((((((((@@@&&&%%%%%%%%%%%%%%%@@@(//,,,,,,@@@   ,,,,,,,,,///@@@   ###@@@(((((((((((((((((((((
// (((((((((@@@@@@%%%&&&%%%%%%%%%%%%@@@(//,,,,,,@@@@@@*,,,,,,,,,,,@@@@@@###@@@(((((((((((((((((((((
// ((((((((((((@@@&&&&&&%%%###%%%%%%@@@(//////////////,,,,,,,,,,,,//////&@@((((((((((((((((((((((((
// (((((((((@@@&&&%%%&&&%%%%%%%%%@@@###//////,,,,,,,,,,,,,,,,,,@@@@@@(//&@@((((((((((((((((((((((((
// (((((((((@@@&&&&&&&&&%%%###@@@#########@@@(///////////,,,@@@@@@@@@@@@(((((((((((((((((((((((((((
// (((((((((@@@&&&%%%&&&&&&###@@@###//////###@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((
// (((((((((@@@&&&%%%&&&&&&###@@@###//////###@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((((((((((((((((((((
// (((((((((@@@&&&%%%######@@@###///////////////###############@@@(((((((((((((((((((((((((((((((((
// ((((((@@@&&&&&&%%%&&&###@@@###/////////,,,,,,,,,,,,//////###@@@(((((((((((((((((((((((((((((((((
// (((((((((@@@&&&%%%&&&@@@###/////////,,,,,,,,,,,,,,,,,,//////&@@@@@((((((((((((((((((((((((((((((
// ((((((@@@&&&&&&%%%###@@@###/////////,,,,,,,,,,,,,,,,,,,,,///&@@(//&@@(((((((((((((((((((((((((((
// (((((((((@@@&&&%%%###@@@######@@@(//,,,,,,,,,,,,,,,,,,,,,///&@@(//&@@(((((((((((((((((((((((((((
// (((((((((@@@&&&%%%###@@@######@@@(//,,,,,,,,,,,,,,,,,,,,,///&@@(//&@@(((((((((((((((((((((((((((
// (((((((((@@@&&&&&&&&&@@@###///@@@(//,,,,,,,,,,,,,,,,,,,,,///&@@(//&@@(((((((((((((((((((((((((((
// ((((((@@@&&&&&&&&&###@@@###///@@@(//,,,,,,,,,,,,,,,,,,//////&@@(//&@@(((((((((((((((((((((((((((
// (((((((((@@@&&&&&&%%%###@@@@@@(////////,,,,,,,,,,,,,,,//////&@@@@@((((((((((((((((((((((((((((((
// ((((((((((((@@@&&&%%%%%%@@@###////////////,,,,,,,,,/////////&@@(((((((((((((((((((((((((((((((((
// (((((((((((((((@@@######@@@###///////////////////////////&@@((((((((((((((((((((((((((((((((((((
// (((((((((((((((@@@######@@@###///////////////////////////&@@((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((@@@@@@@@@###///@@@@@@@@@@@@@@@###///&@@(((((((((((((((@spiridono((((((((((((((
// ((((((((((((((((((((((((@@@###///@@@(((((((((@@@###///&@@(((((((((((((((((((((((((((((((((((((((

contract Edgehogs is Ownable, ERC721A {
  uint256 public  MAX = 6666;
  uint256 public  MAX_FREE = 696;
  uint256 public  MAX_REROLLS = 1000;
  uint256 public  PURCHASE_LIMIT = 10;
  uint256 public  PRICE = 0.025 ether;
  uint256 public  REROLL_PRICE = 0.01 ether;

  uint256 public mintedTokens;
  uint256 public rerollsMade;
  uint256 public freeClaimed;

  uint8 public saleState = 0; // = DEV, 1 = SALE, 2 = REROLL, 3 = CLOSED

  // OpenSea auto approve is live
  bool public isOpenSeaApproved;

  //Legendaries status
  bool public legendariesSet = false;

  // OpenSea proxy registry contract
  OpenSeaProxyRegistry public openSeaProxyRegistry;

 // withdraw addresses
  address t1 = 0x392D50fCFDd5b36E6DdDB22bcB84AA80B8105890; //
  address t2 = 0xE0b76103Ec5d8159939572A61286bD3291DB8a43; 

 //Steve Aoki addrress
  address steveAoki = 0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4;

  //Save seed for traits for each token
  mapping(uint256 => uint256) public tokenSeed;
  // amount minted by address in presale
  mapping(address => uint256) public whitelistMints;

  InterfaceDescriptor public descriptor;

  uint16[][8] rarities;
  string[][9] traitsByName;
  uint256[] legendaryList;
  // Mapping from token ID to name
  mapping (uint256 => string) private _tokenName;

  // Mapping if certain name string has already been reserved
  mapping (string => bool) private _nameReserved;

  // presale merkle tree root
  bytes32 internal _merkleRoot;

  //SVG-parts shared by all Edgehogs
  string private constant svgStart =
    "<svg id='edgehog' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256' width='640' height='640'>";
  string private constant svgEnd =
    "<style>#edgehog{shape-rendering: crispedges; image-rendering: -moz-crisp-edges; image-rendering: optimizeSpeed; image-rendering: -webkit-crisp-edges; image-rendering: -webkit-optimize-contrast; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}.vibe { animation: 0.5s vibe infinite alternate ease-in-out; } @keyframes vibe { from { transform: translateY(0px); } to { transform: translateY(1.5%); } }</style></svg>";
  string private constant _body =
    "<image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEABAMAAACuXLVVAAAAD1BMVEUAAACTg2rLtaEnDQhZVlIUtesvAAAAAXRSTlMAQObYZgAAAMhJREFUeNrt2bENxCAQRUG3QAvXAi24/5oOS15hmdNB6vVMQkDwXwwbAAAAAAAAAAAAAAAAAAAAAMCq2uzNtkiAAAG5AmI8bBMCBAjIG1BOswgBAgTkCujjo/2H2ggQICB/wOemnAQIEJAvYD4+RtSTAAEC3hdwiIA4BQgQkCfgUBsBAgS8N6A0AgQIEDALKI0AAQJyBoRysfpAIUCAgOcH/Pu4vI+HGBcgQED+gG4cFyBAQN6AOoi7Pi5AgID8Adc7AQIEpAj4AjgSOK7j5zUdAAAAAElFTkSuQmCC'/>";
  string private constant _head =
    "<g class='vibe'><image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEABAMAAACuXLVVAAAAFVBMVEUAAADLtaEnDQiTg2rsmJkAAABZVlL0LlrIAAAAAXRSTlMAQObYZgAAALBJREFUeNrt1s0JwzAMgNGukBWyQlfoCl2h+4/QGCwQAZOfm5X3rpHQdwp+AQAAAAAAAAAAAJyxJnf3BAgQMH/Ap7uyFzsCBAiYPyBHvLsliZklaTP5uAABAuYPiIh0fCgifxsBAgQ8LyB/FyBAwDMDGgECBNQP2Bs9SOK4AAEC6gQ0o6Ph2wkQIKBuwOiHFMdDPi5AgIB6Ac16YD8vQICAegEAAAAAAAAAAAAAAEAZf88p+dDBeVtDAAAAAElFTkSuQmCC'/></g>";



  constructor(
    InterfaceDescriptor descriptor_,
    OpenSeaProxyRegistry openSeaProxyRegistry_,
    bytes32 merkleRoot_
  ) ERC721A("EDGEHOGS", unicode"⚉") {
    //Solidity 0.8.12 does not seem to support Unicode 10.0 emojis as of now, otherwise it would have been 🦔 ofc

    // Initializing variables
    descriptor = descriptor_;
    openSeaProxyRegistry = openSeaProxyRegistry_;
    _merkleRoot = merkleRoot_;

    //sum of rarities values must be equal to the mod used in _getRandomIndex, 10000 in our case
    
    rarities[0] = [0,
    200,
    2000,
    2000,
    2000,
    2000,
    900,
    900
    ]; //backgrounds

    rarities[1] = [
      0,
      1000,
      850,
      700,
      700,
      700,
      600,
      600,
      500,
      500,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      50
    ]; //backs
    rarities[2] = [
      0,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      50
    ]; //bottoms
    rarities[3] = [
      0,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      550,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      50
    ]; //clothes
    rarities[4] = [
      0,
      1000,
      800,
      800,
      800,
      600,
      600,
      500,
      500,
      400,
      400,
      400,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      150,
      100,
      50
    ]; //mouths
    rarities[5] = [
      0,
      800,
      600,
      600,
      600,
      600,
      600,
      400,
      400,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      50,
      50,
      50,
      50
    ]; //headgears
    rarities[6] = [
      0,
      850,
      800,
      800,
      600,
      600,
      600,
      400,
      400,
      400,
      400,
      300,
      300,
      300,
      300,
      300,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      100,
      50
    ]; //eyes
    rarities[7] = [
      0,
      800,
      700,
      700,
      700,
      700,
      500,
      500,
      500,
      500,
      500,
      500,
      500,
      400,
      400,
      400,
      300,
      200,
      200,
      200,
      200,
      200,
      100,
      100,
      100,
      50,
      50
    ]; //accessories

    //traits
    //backgrounds
    traitsByName[0] = [
      "n/a",
      "Psychedelic",
      "Purple",
      "Orange",
      "Green",
      "Pink",
      "Pink-Blue",
      "Blue-Green"
    ];
    //backs
    traitsByName[1] = [
      "n/a",
      "Edgehog",
      "Firework",
      "Black",
      "Neon Sparks",
      "Shoomery",
      "Pirate",
      "Punk",
      "Grant us Eyes",
      "Rainbow",
      "Neon Punk",
      "Psychedelic",
      "Slime",
      "Spotty",
      "Christmas",
      "Brainiac",
      "Cyberhog",
      "Bubble gum",
      "Skellyhog",
      "TNT",
      "Biohazard",
      "Robohog",
      "Hellhog",
      "Virus",
      "Pure Gold",
      "Diamond"
    ];
    //bottoms
    traitsByName[2] = [
      "n/a",
      "Fancy",
      "Padre",
      "Joker",
      "Vault Dweller",
      "Santa",
      "Torn Jeans",
      "Fishnets",
      "Bikini",
      "Green",
      "Pajamas",
      "BDSM",
      "Mime",
      "Pink",
      "Jungle",
      "Rainbow",
      "Elvis",
      "Bathog",
      "Partyhog",
      "Skelly",
      "Pure Gold"
    ];
    //clothes
    traitsByName[3] = [
      "n/a",
      "Pink",
      "Joker",
      "Vault Dweller",
      "Padre",
      "Santa",
      "Freddy",
      "Pierced Nips",
      "Bikini",
      "Punk",
      "Pajamas",
      "BDSM",
      "Mime",
      "Rapper",
      "Buff",
      "Rainbow",
      "Elvis",
      "Bathog",
      "Partyhog",
      "Skelly",
      "Pure Gold"
    ];
    //mouths
    traitsByName[4] = [
      "None",
      "Plain",
      "Smile",
      "Drooling",
      "Tongue",
      "Pipe",
      "Party",
      "Love",
      "Zombie",
      "Rabid",
      "Blush",
      "Mime",
      "Bubble gum",
      "Blunt",
      "Bloody",
      "Licker",
      "Vampire",
      "Blotter",
      "Virus",
      "Red Beard",
      "Golden tooth",
      "TNT",
      "Hannibal",
      "Biohazard",
      "Laser"
    ];
    //headgears
    traitsByName[5] = [
      "n/a",
      "None",
      "Beanie",
      "Fastfood",
      "Apple",
      "Frying pan",
      "Tinfoil hat",
      "Arrow",
      "Punk",
      "Rabbit ears",
      "Doc",
      "Pizza",
      "Anntennae",
      "Horny",
      "Pretty bow",
      "Eye",
      "Devil",
      "Skull",
      "Toad",
      "Unicorn",
      "Kamikaze",
      "Santa",
      "Pirate",
      "Alien eyes",
      "Demon",
      "Crown",
      "Chief",
      "Zombie hand",
      "Fake halo",
      "Brainz",
      "Strawberry cap",
      "Russian hat",
      "Frankenhog",
      "Plunger",
      "Sroomhead",
      "Octopus",
      "Plague Doctor",
      "VR"
    ];
    //eyes
    traitsByName[6] = [
      "n/a",
      "Plain",
      "Sus",
      "Green",
      "Crosseyed",
      "Angry",
      "Kawaii",
      "Tired",
      "Grumpy",
      "Red goggles",
      "Green goggles",
      "Bloodshot",
      "Goomba",
      "Eye patch",
      "Squinty",
      "Insane",
      "Vampire",
      "Pop out",
      "Popeye",
      "Dizzy",
      "Triple eye",
      "Hearts",
      "XX",
      "Alien",
      "VR goggles",
      "Cyclops",
      "Rainbow goggles",
      "Cyborg",
      "Cyberhog",
      "Demon",
      "Hogminator",
      "Steampunk",
      "Deal with it",
      "Lasers"
    ];
    //accessories
    traitsByName[7] = [
      "n/a",
      "None",
      "Coffee",
      "Sausage",
      "Sorcerer staff",
      "Mana potion",
      "Bong",
      "Pirate flag",
      "Whip",
      "Beer",
      "Steel claws",
      "Trident",
      "Knife",
      "Club",
      "Balloon",
      "Shocker",
      "Biohazard",
      "Lightsaber",
      "Master Sword",
      "Doggy",
      "Rose",
      "Gun",
      "Pee",
      "Chainsaw",
      "Scythe",
      "Dildo",
      "Minigun"
    ];

    traitsByName[8] = [
      "n/a",
      "Nude Dude",
      "Dark Entity",
      "Acid Hog",
      "Zombie Hog",
      "Hog Spirit",
      "Lava Hog",
      "Why So Serious",
      "Robohog",
      "Very Fast Blue Hog",
      "Retrohog"
    ];
  }

  //Get the attribute name for the properties of the token by its index
  function _getTrait(uint256 _trait, uint256 index)
    internal
    view
    returns (string memory)
  {
    return traitsByName[_trait][index];
  }

  ////////////////////////////////////////////////////////////
  /////🦔GENERATE TRAITS AND SVG BASED ON SEED🦔/////////////
  ///////////////////////////////////////////////////////////

  //Get randomized values for each different trait with a single pseudorandom seed
  // note: we are generating both traits and SVG on the fly based on the seed which is the the only parameter saved in memory
  // Not writing a whole struct allows for serious gas savings on mint, but has a downside that we can't easily address or change a single trait
  function getTraits(uint256 seed)
    public
    view
    returns (string memory svg, string memory properties)
  {
    uint16[] memory randomInputs = expand(seed, 8);
    uint16[] memory traits = new uint16[](9);
    /** traits[0] bg
        traits[1] back
        traits[2] bottom
        traits[3] clothes
        traits[4] mouth
        traits[5] headgear
        traits[6] eyes
        traits[7] accessory
        traits[8] legendary
    */

    if (seed > 100) {

    traits[0] = getRandomIndex(rarities[0], randomInputs[0]);
    traits[1] = getRandomIndex(rarities[1], randomInputs[1]);
    traits[2] = getRandomIndex(rarities[2], randomInputs[2]);
    traits[3] = getRandomIndex(rarities[3], randomInputs[3]);
    traits[4] = getRandomIndex(rarities[4], randomInputs[4]);
    traits[5] = getRandomIndex(rarities[5], randomInputs[5]);
    traits[6] = getRandomIndex(rarities[6], randomInputs[6]);
    traits[7] = getRandomIndex(rarities[7], randomInputs[7]);
    traits[8] = 0;

    //handling compatibility exceptions
    //tnt              //hellhog
    if (traits[1] == 19 || traits[1] == 22) {
      traits[5] = 1;
    }
    //tnt
    if (traits[4] == 21) {
      traits[7] = 0;
    }
    //staff              //scythe         //plain
    if (traits[7] == 4 || traits[7] == 24) {
      traits[4] = 1;
    }
    //VR
    if (traits[5] == 37) {
      traits[6] = 1;
    }
    //Plague
    if (traits[5] == 36) {
      traits[6] = 1;
      traits[4] = 0;
    }

    } else {
      traits[0] = 0;
      traits[1] = 0;
      traits[2] = 0;
      traits[3] = 0;
      traits[4] = 0;
      traits[5] = 0;
      traits[6] = 0;
      traits[7] = 0;
    
      traits[8] = uint16(seed);

    }


    // render svg
    bytes memory _svg = renderEdgehog(
      traits[0],
      traits[1],
      traits[2],
      traits[3],
      traits[4],
      traits[5],
      traits[6],
      traits[7],
      traits[8]
    );

    svg = base64(_svg);

    // pack properties, put 1 after the last property for JSON to be formed correctly (no comma after the last one)
    if (seed > 100) {
    bytes memory _properties = abi.encodePacked(
      packMetaData("background", _getTrait(0, traits[0]), 0),
      packMetaData("back", _getTrait(1, traits[1]), 0),
      packMetaData("bottom", _getTrait(2, traits[2]), 0),
      packMetaData("clothes", _getTrait(3, traits[3]), 0),
      packMetaData("mouth", _getTrait(4, traits[4]), 0),
      packMetaData("headgear", _getTrait(5, traits[5]), 0),
      packMetaData("eyes", _getTrait(6, traits[6]), 0),
      packMetaData("accessory", _getTrait(7, traits[7]), 1)
    );
      properties = string(abi.encodePacked(_properties));
      
    } else {
      bytes memory _properties = abi.encodePacked(
      packMetaData("legendary", _getTrait(8, seed), 1)
      );
      properties = string(abi.encodePacked(_properties));
    }

    return (svg, properties);
  }

  // Get a random attribute using the rarities defined
  // Shout out to Anonymice for the logic
  function getRandomIndex(
    uint16[] memory attributeRarities,
    uint256 randomNumber
  ) private pure returns (uint16 index) {
    uint16 random10k = uint16(randomNumber % 10000);
    uint16 lowerBound;
    for (uint16 i = 1; i <= attributeRarities.length; i++) {
      uint16 percentage = attributeRarities[i];

      if (random10k < percentage + lowerBound && random10k >= lowerBound) {
        return i;
      }
      lowerBound = lowerBound + percentage;
    }
    revert();
  }

  //Get attribute svg for each different property of the token
  function renderEdgehog(
    uint16 _background,
    uint16 _back,
    uint16 _bottom,
    uint16 _clothes,
    uint16 _mouth,
    uint16 _headgear,
    uint16 _eyes,
    uint16 _accessory,
    uint16 _legendary
  ) public view returns (bytes memory) {
    bytes memory start = abi.encodePacked(
      svgStart,
      descriptor.renderBackground(_background),
      descriptor.renderBack(_back),
      _body,
      descriptor.renderBottom(_bottom)
    );
    return
      abi.encodePacked(
        start, 
        descriptor.renderClothes(_clothes),
        _head,
        descriptor.renderAccessory(_accessory),
        descriptor.renderHeadgear(_headgear),
        descriptor.renderEyes(_eyes),
        descriptor.renderMouth(_mouth),
        descriptor.renderLegendary(_legendary),
        svgEnd
      );
  }

  /////////////////////////////////////
  /////🦔GENERATE METADATA🦔//////////
  ////////////////////////////////////

  //Get the metadata for a token in base64 format
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Token not found");
    (string memory svg, string memory properties) = getTraits(
      tokenSeed[tokenId]
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          base64(
            abi.encodePacked(
              '{"name":"Edgehog #',
              uint2str(tokenId),' ',_tokenName[tokenId],
              '", "description": "Edgehogs live on the cutting edge of Ethereum blockchain and are edgy as hell.", "traits": [',
              properties,
              '], "image":"data:image/svg+xml;base64,',
              svg,
              '"}'
            )
          )
        )
      );
  }

  // Bundle metadata so it follows the standard
  function packMetaData(
    string memory name,
    string memory svg,
    uint256 last
  ) private pure returns (bytes memory) {
    string memory comma = ",";
    if (last > 0) comma = "";
    return
      abi.encodePacked(
        '{"trait_type": "',
        name,
        '", "value": "',
        svg,
        '"}',
        comma
      );
  }

  /////////////////////////////////////
  /////🦔MINTING🦔////////////////////
  ////////////////////////////////////

    //giveaways are nice
	function gift(uint256 numberOfTokens, address recipient) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply + numberOfTokens <= MAX, "Would exceed max supply");
    for (uint256 i = 0; i < numberOfTokens; i++) {
      tokenSeed[supply + i] = uint256(
        keccak256(abi.encodePacked(block.timestamp, msg.sender, supply + i))
      );
    }
    delete supply;
    _safeMint(recipient, numberOfTokens);
  }

  //mint Edgehog
  function mint(uint256 numberOfTokens) external payable {
    uint256 supply = totalSupply();
    require(saleState == 1, "Sale inactive");
    require(msg.sender != steveAoki, "No Steve Aoki!");
    require(numberOfTokens <= PURCHASE_LIMIT, "Too many");
    require(supply + numberOfTokens <= MAX - MAX_FREE + freeClaimed, "Would exceed max public supply");
    require(PRICE * numberOfTokens == msg.value, "Wrong ETH amount");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      tokenSeed[supply + i] = uint256(
        keccak256(abi.encodePacked(block.timestamp, msg.sender, supply + i))
      );
    }
    delete supply;
    _safeMint(msg.sender, numberOfTokens);
  }

  //free mint, 1 per transaction, 1 per wallet, address must be whtelisted
  function presaleMint(bytes32[] calldata proof_) external {
    uint256 supply = totalSupply();
    require(saleState == 1, "Sale inactive");
    require(supply + 1 <= MAX, "Would exceed max supply");
    require(isWhitelisted(msg.sender, proof_), "Not on the list");
    require(whitelistMints[msg.sender] == 0, "Already minted");
    freeClaimed++;
    whitelistMints[msg.sender]++;
    tokenSeed[supply] = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender, supply))
    );
    delete supply;
    _safeMint(msg.sender, 1);
  }

  //rerolls a common edgehog
  function reroll(uint256 _tokenId) external payable {
    require(saleState == 2, "Reroll inactive");
    require(rerollsMade < MAX_REROLLS, "No more rerolls");
    require(msg.sender == ownerOf(_tokenId), "Only owner can reroll");
    require(!isLegendary(_tokenId), "Can't be rerolled");
    require(REROLL_PRICE == msg.value, "Wrong ETH amount");

    rerollsMade = rerollsMade + 1;
    tokenSeed[_tokenId] = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId + 1))
    );
    
  }

  
  //puts a legendary edgehog in place of a common
  function rollLegendary(uint256 _tokenId, uint256 _legendaryId) public onlyOwner {
     //can only make regulars legendaries
    require(!isLegendary(_tokenId), "Can't be upgraded");
    tokenSeed[_tokenId] = _legendaryId;
    addLegendaryNumber(_legendaryId);
    }

  //checks if an edgehog is legendary
  function isLegendary(uint256 _tokenId) public view returns (bool) {
      if (tokenSeed[_tokenId] <=100) {
      return true;
      } else {
      return false;
      }
  }

  //set legendaries
  function setLegendaries(uint256 _legendarySeed) public onlyOwner {
        require(legendariesSet == false, "Legendaries already set");
        uint256 s = totalSupply(); 
        uint256 n = _legendarySeed;
        for (uint256 i = 1; i <= 10; i++) {
                uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,n))) % s;
                    if (!isLegendary(randomNumber)) {

                    tokenSeed[randomNumber] = i;
                    addLegendaryNumber(randomNumber);
                    n = n * 6;

                    } 
        }
                delete s;
                delete n;
                legendariesSet = true;
    }

  /////////////////////////////////////
  /////🦔RENAMING🦔///////////////////
  ////////////////////////////////////

  // Shout out to Hashmasks 
  //Changes the name for Edgehog tokenId
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

   // Events
    event NameChange (uint256 indexed edgehogId, string newName);


   //Returns name of the NFT at index.
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

   //Returns if the name has been reserved.
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

   //Reserves the name if isReserve is set to true, de-reserves if set to false
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    //Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }


    //Converts the string to lowercase
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }


  ///////////////////////////////////
  /////🦔ADMIN🦔////////////////////
  //////////////////////////////////

  //Gets the token pre-approved for trading on OpenSea - saves gas for the end users
  function setOpenSeaProxyRegistry(OpenSeaProxyRegistry openSeaProxyRegistry_)
    external
    onlyOwner
  {
    openSeaProxyRegistry = openSeaProxyRegistry_;
  }

  function flipOpenSeaApproved() external onlyOwner {
    isOpenSeaApproved = !isOpenSeaApproved;
  }

  function flipSaleState() external onlyOwner {
    require(saleState < 3, "Sale state is already closed");
    saleState++;
  }

  function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX = _supply;
    }

  function setFreeSupply(uint256 _supply) public onlyOwner {
        MAX_FREE = _supply;
    }

  function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

  // Withdraw to the team according to shares
  function withdrawAll() public payable onlyOwner {
    uint256 _share = address(this).balance / 100;
      require(payable(t1).send(_share * 90));
      require(payable(t2).send(_share * 10));
    }

  ///////////////////////////////////
  /////🦔HELPERS🦔//////////////////
  //////////////////////////////////

  function isApprovedForAll(address _owner, address operator)
    public
    view
    override
    returns (bool)
  {
    return
      (isOpenSeaApproved &&
        address(openSeaProxyRegistry.proxies(_owner)) == operator) ||
      super.isApprovedForAll(_owner, operator);
  }

  // Check if the address is whitelisted
  function isWhitelisted(address account_, bytes32[] calldata proof_)
    public
    view
    returns (bool)
  {
    return _verify(_leaf(account_), proof_);
  }

  // Set Merckle root
  function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
    _merkleRoot = merkleRoot_;
  }

  // Encode Merckle leaf from address
  function _leaf(address account_) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account_));
  }

  // verify proof
  function _verify(bytes32 leaf_, bytes32[] memory proof_)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof_, _merkleRoot, leaf_);
  }

  ///set attributes libraries
  function setDescriptor(address source) external onlyOwner {
    descriptor = InterfaceDescriptor(source);
  }

  //generates random numbers based on a random number
  function expand(uint256 _randomNumber, uint256 n)
    private
    pure
    returns (uint16[] memory expandedValues)
  {
    expandedValues = new uint16[](n);
    for (uint256 i = 0; i < n; i++) {
      expandedValues[i] = bytes2uint(keccak256(abi.encode(_randomNumber, i)));
    }
    return expandedValues;
  }

  //converts uint256 to uint16
  function bytes2uint(bytes32 _a) private pure returns (uint16) {
    return uint16(uint256(_a));
  }

  function freeClaimedCount() external view returns (uint256) {
    return freeClaimed;
  }

  function rerollsMadeCount() external view returns (uint256) {
    return rerollsMade;
  }

  //adds a legendary edgehog's id to the list of legendaties
  function addLegendaryNumber(uint256 _legendaryId) public onlyOwner {
    legendaryList.push(_legendaryId);
  }

  //returns ids of legendary edgehogs
  function legendariesList() external view returns (uint256[] memory) {
    return legendaryList;
  }

  //adds a new name to the legendaries array
  function addNewLegendary(string memory _legendaryName) public onlyOwner {
    traitsByName[8].push(_legendaryName);
  }

  //returns number of tokens owned
  function tokensOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

  //Helper function to convert uint to string
  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

//  Base64 by Brecht Devos - <[email protected]>
//  Provides a function for encoding some bytes in base64

    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
  //if you are reading this, you are a true blockchain nerd. Much love - @spiridono! 🦔
}