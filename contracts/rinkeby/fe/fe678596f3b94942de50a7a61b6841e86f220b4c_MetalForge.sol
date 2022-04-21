/**
 *Submitted for verification at Etherscan.io on 2022-04-20
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

pragma solidity ^0.8.0;




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
}



pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
}



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






pragma solidity 0.8.10;



contract MetalForge is Ownable, Pausable {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint public rewardRate = 1;
    uint public lastUpdateTime;

    bool public liquidLegendMintOver = false;

    mapping(address => uint) public rewards;

    uint public _totalSupply;

    uint public _totalRewards;

    mapping(address => uint) private _balances;

    mapping(address => uint256) public userLastUpdateTime;

    using SafeERC20 for IERC20;
    IERC20 public immutable metalToken;

    ERC721Enumerable public immutable alpha;
    ERC721Enumerable public immutable beta;



    uint256 public immutable BETA_DISTRIBUTION_AMOUNT;


    uint256 public totalClaimed;

    uint256 public claimDuration;
    uint256 public claimStartTime;

    mapping (uint256 => bool) public alphaClaimed;

    mapping (uint256 => bool) public betaClaimed;


    event ClaimStart(
        uint256 _claimDuration,
        uint256 _claimStartTime
    );


    event BetaClaimed(
        uint256 indexed tokenId,
        address indexed account,
        uint256 timestamp
    );


    event AirDrop(
        address indexed account,
        uint256 indexed amount,
        uint256 timestamp
    );


    constructor(
        address _metalTokenAddress,
        address _alphaContractAddress,
        address _betaContractAddress,
        uint256 _BETA_DISTRIBUTION_AMOUNT,
        address _stakingToken,
        address _rewardsToken
    ) {
        require(_metalTokenAddress != address(0), "The Metal token address can't be 0");
        require(_alphaContractAddress != address(0), "The Alpha contract address can't be 0");
        require(_betaContractAddress != address(0), "The Beta contract address can't be 0");


        metalToken = IERC20(_metalTokenAddress);
        alpha = ERC721Enumerable(_alphaContractAddress);
        beta = ERC721Enumerable(_betaContractAddress);
        

        BETA_DISTRIBUTION_AMOUNT = _BETA_DISTRIBUTION_AMOUNT;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
_balances[0x8da220B4e8F6a9280A0963af019658D9b3B2f050] = 72000000000000000000;
        userLastUpdateTime[0x8da220B4e8F6a9280A0963af019658D9b3B2f050] = block.timestamp;
_balances[0xB68D316571c20836A9C5573D5A80CfF1c8c8616a] = 27000000000000000000;
        userLastUpdateTime[0xB68D316571c20836A9C5573D5A80CfF1c8c8616a] = block.timestamp;
_balances[0xfebbB48C8f7A67Dc3DcEE19524A410E078e6A6a1] = 18000000000000000000;
        userLastUpdateTime[0xfebbB48C8f7A67Dc3DcEE19524A410E078e6A6a1] = block.timestamp;
_balances[0x56ae97EDfdab3b367E8e0DDcdB63A0C4072B96D2] = 17000000000000000000;
        userLastUpdateTime[0x56ae97EDfdab3b367E8e0DDcdB63A0C4072B96D2] = block.timestamp;
_balances[0x4d5062FF38294c74f769e21362fb02db62e9FD32] = 17000000000000000000;
        userLastUpdateTime[0x4d5062FF38294c74f769e21362fb02db62e9FD32] = block.timestamp;
_balances[0x035f4B090F4fE6a2d95a3e3617ba0FAF8C8322e5] = 16000000000000000000;
        userLastUpdateTime[0x035f4B090F4fE6a2d95a3e3617ba0FAF8C8322e5] = block.timestamp;
_balances[0x7ab96Ab53b725e670Ee061BEA6507D49399a9766] = 15000000000000000000;
        userLastUpdateTime[0x7ab96Ab53b725e670Ee061BEA6507D49399a9766] = block.timestamp;
_balances[0x26650b2Fc1328CB9977F81Bb23Bb7A0E7F3491d5] = 15000000000000000000;
        userLastUpdateTime[0x26650b2Fc1328CB9977F81Bb23Bb7A0E7F3491d5] = block.timestamp;
_balances[0xfD13f2909d89635b48E6E7EE8DFcE176BcCb0467] = 14000000000000000000;
        userLastUpdateTime[0xfD13f2909d89635b48E6E7EE8DFcE176BcCb0467] = block.timestamp;
_balances[0xD10ACE4dE10c4Bac60537E0FA781316c8d7114b4] = 14000000000000000000;
        userLastUpdateTime[0xD10ACE4dE10c4Bac60537E0FA781316c8d7114b4] = block.timestamp;
_balances[0x043Db7F3B2Bf07ED0404cc241AF842846c023721] = 14000000000000000000;
        userLastUpdateTime[0x043Db7F3B2Bf07ED0404cc241AF842846c023721] = block.timestamp;
_balances[0x867Eb0804eACA9FEeda8a0E1d2B9a32eEF58AF8f] = 13000000000000000000;
        userLastUpdateTime[0x867Eb0804eACA9FEeda8a0E1d2B9a32eEF58AF8f] = block.timestamp;
_balances[0xd3F332cF93Cb42dBF4f39dF4001f157165eaC1E6] = 11000000000000000000;
        userLastUpdateTime[0xd3F332cF93Cb42dBF4f39dF4001f157165eaC1E6] = block.timestamp;
_balances[0xAB8782298BB8c647562c8D80c794E6E013852f99] = 11000000000000000000;
        userLastUpdateTime[0xAB8782298BB8c647562c8D80c794E6E013852f99] = block.timestamp;
_balances[0x5DB081FCC35103a64A4d3Ed46BF863BD2ea897B5] = 11000000000000000000;
        userLastUpdateTime[0x5DB081FCC35103a64A4d3Ed46BF863BD2ea897B5] = block.timestamp;
_balances[0x18651bC48BC18110C99332f63BB921Cf0592cA53] = 11000000000000000000;
        userLastUpdateTime[0x18651bC48BC18110C99332f63BB921Cf0592cA53] = block.timestamp;
_balances[0x8E85532d19f74b731bC2B39E47b63EE4b0e756Ca] = 10000000000000000000;
        userLastUpdateTime[0x8E85532d19f74b731bC2B39E47b63EE4b0e756Ca] = block.timestamp;
_balances[0x10d503FFE3b10fC43285396De53D4Df66a7A15e5] = 10000000000000000000;
        userLastUpdateTime[0x10d503FFE3b10fC43285396De53D4Df66a7A15e5] = block.timestamp;
_balances[0x3fB7C90E78dB88097BB735D5d16e157623f7763D] = 10000000000000000000;
        userLastUpdateTime[0x3fB7C90E78dB88097BB735D5d16e157623f7763D] = block.timestamp;
_balances[0x6482F3DAb84BD792Ad85DD2785c5197464058Bf4] = 9000000000000000000;
        userLastUpdateTime[0x6482F3DAb84BD792Ad85DD2785c5197464058Bf4] = block.timestamp;
_balances[0x629443448bC078e5BAa59C610D9d540438aE874C] = 9000000000000000000;
        userLastUpdateTime[0x629443448bC078e5BAa59C610D9d540438aE874C] = block.timestamp;
_balances[0x697CBD509d8b8804539E50e566AFb54430a44384] = 9000000000000000000;
        userLastUpdateTime[0x697CBD509d8b8804539E50e566AFb54430a44384] = block.timestamp;
_balances[0xE77c2317E7d9170f374A6ce32877E95E91E6AE92] = 8000000000000000000;
        userLastUpdateTime[0xE77c2317E7d9170f374A6ce32877E95E91E6AE92] = block.timestamp;
_balances[0x7AD79B83575BECB692bddF23909b74f1F52503De] = 8000000000000000000;
        userLastUpdateTime[0x7AD79B83575BECB692bddF23909b74f1F52503De] = block.timestamp;
_balances[0x3D39e226589765a5c13ddE7913129d517b776D15] = 8000000000000000000;
        userLastUpdateTime[0x3D39e226589765a5c13ddE7913129d517b776D15] = block.timestamp;
_balances[0x31b87a02e51B5adBfb8eC5E7186861a18Be07d94] = 8000000000000000000;
        userLastUpdateTime[0x31b87a02e51B5adBfb8eC5E7186861a18Be07d94] = block.timestamp;
_balances[0xdb55afCfd038D51642fD67025D8A252C645A91a8] = 7000000000000000000;
        userLastUpdateTime[0xdb55afCfd038D51642fD67025D8A252C645A91a8] = block.timestamp;
_balances[0xEA771c3aA97fC8DbA614ECf6de91D7B2b595EF1a] = 7000000000000000000;
        userLastUpdateTime[0xEA771c3aA97fC8DbA614ECf6de91D7B2b595EF1a] = block.timestamp;
_balances[0xD8dBC8Db662B2712c5C9E1e66A961c427a81bE3d] = 7000000000000000000;
        userLastUpdateTime[0xD8dBC8Db662B2712c5C9E1e66A961c427a81bE3d] = block.timestamp;
_balances[0xD9709a9454E27496f9849b2c87e597c893513b43] = 7000000000000000000;
        userLastUpdateTime[0xD9709a9454E27496f9849b2c87e597c893513b43] = block.timestamp;
_balances[0x69Cd3080236750F7A006FdDdf86797A7Efc813a4] = 7000000000000000000;
        userLastUpdateTime[0x69Cd3080236750F7A006FdDdf86797A7Efc813a4] = block.timestamp;
_balances[0x0D54d4500FACb7f836868A94daAb41ABdcFAB0A8] = 7000000000000000000;
        userLastUpdateTime[0x0D54d4500FACb7f836868A94daAb41ABdcFAB0A8] = block.timestamp;
_balances[0x4800FfC1E498702A52B499BC623a2CD2694f72Ef] = 7000000000000000000;
        userLastUpdateTime[0x4800FfC1E498702A52B499BC623a2CD2694f72Ef] = block.timestamp;
_balances[0xe7F246e9B74EA4209A3010a54090794829309e6d] = 6000000000000000000;
        userLastUpdateTime[0xe7F246e9B74EA4209A3010a54090794829309e6d] = block.timestamp;
_balances[0x92Cc17C86eBf30Cb1D80c6c7BA497F002E623647] = 6000000000000000000;
        userLastUpdateTime[0x92Cc17C86eBf30Cb1D80c6c7BA497F002E623647] = block.timestamp;
_balances[0x9547C19FF5b3902EAF7aEb29A525D994F416A8E3] = 6000000000000000000;
        userLastUpdateTime[0x9547C19FF5b3902EAF7aEb29A525D994F416A8E3] = block.timestamp;
_balances[0xa3C2461C7E6Bdaee0514ff300Af45A2834f157e4] = 6000000000000000000;
        userLastUpdateTime[0xa3C2461C7E6Bdaee0514ff300Af45A2834f157e4] = block.timestamp;
_balances[0x5ED2698484c888C5701Bc0Af690ccA67F67Bc000] = 6000000000000000000;
        userLastUpdateTime[0x5ED2698484c888C5701Bc0Af690ccA67F67Bc000] = block.timestamp;
_balances[0x00C980F967b3E94e471C94d226Da998E1eb55A33] = 6000000000000000000;
        userLastUpdateTime[0x00C980F967b3E94e471C94d226Da998E1eb55A33] = block.timestamp;
_balances[0x24Ed9ccd78d230404f96630846F7cF59B59E940D] = 6000000000000000000;
        userLastUpdateTime[0x24Ed9ccd78d230404f96630846F7cF59B59E940D] = block.timestamp;
_balances[0xF4607227597d922e0D53EB75C548EAC3942cFC67] = 5000000000000000000;
        userLastUpdateTime[0xF4607227597d922e0D53EB75C548EAC3942cFC67] = block.timestamp;
_balances[0xE7820e30f55C042ed6e51211BF3F93ee617834d9] = 5000000000000000000;
        userLastUpdateTime[0xE7820e30f55C042ed6e51211BF3F93ee617834d9] = block.timestamp;
_balances[0xcbaf3Af3878bE2Fc267F38fb869608b3ab4f1DD8] = 5000000000000000000;
        userLastUpdateTime[0xcbaf3Af3878bE2Fc267F38fb869608b3ab4f1DD8] = block.timestamp;
_balances[0xc80b4ae46b715C3feef42fd8E0B3E8326794fF35] = 5000000000000000000;
        userLastUpdateTime[0xc80b4ae46b715C3feef42fd8E0B3E8326794fF35] = block.timestamp;
_balances[0xE3b3cb94e331a47EaEF80f1a85aE6Ad624286161] = 5000000000000000000;
        userLastUpdateTime[0xE3b3cb94e331a47EaEF80f1a85aE6Ad624286161] = block.timestamp;
_balances[0xaBea3DbFbA04F0AA033A63568d0eBFddEdf6d4ee] = 5000000000000000000;
        userLastUpdateTime[0xaBea3DbFbA04F0AA033A63568d0eBFddEdf6d4ee] = block.timestamp;
_balances[0xd91fA1d8f18668d8f9E8c7D23FdAbe2b7478d9b9] = 5000000000000000000;
        userLastUpdateTime[0xd91fA1d8f18668d8f9E8c7D23FdAbe2b7478d9b9] = block.timestamp;
_balances[0x60757a5d9a412ab064CddE92AfAEa0e0eb8bb9bD] = 5000000000000000000;
        userLastUpdateTime[0x60757a5d9a412ab064CddE92AfAEa0e0eb8bb9bD] = block.timestamp;
_balances[0x56f322D0DCb001960e62084Cadd8Fa529D577F6D] = 5000000000000000000;
        userLastUpdateTime[0x56f322D0DCb001960e62084Cadd8Fa529D577F6D] = block.timestamp;
_balances[0x52f3077256049a2CE25e378bDf2d8Bb8f72B0672] = 5000000000000000000;
        userLastUpdateTime[0x52f3077256049a2CE25e378bDf2d8Bb8f72B0672] = block.timestamp;
_balances[0x29146D7c15d94f19fb92863b80898ca93a659C54] = 5000000000000000000;
        userLastUpdateTime[0x29146D7c15d94f19fb92863b80898ca93a659C54] = block.timestamp;
_balances[0x219C9F6799a890f2093Fa0a87277C976DDc46f2D] = 5000000000000000000;
        userLastUpdateTime[0x219C9F6799a890f2093Fa0a87277C976DDc46f2D] = block.timestamp;
_balances[0xe4FaDECA360813E6d0AFF959E0f7F256EEA5A26b] = 4000000000000000000;
        userLastUpdateTime[0xe4FaDECA360813E6d0AFF959E0f7F256EEA5A26b] = block.timestamp;
_balances[0xFa34804390a2f6e14C547aFa976d4479F5f660E2] = 4000000000000000000;
        userLastUpdateTime[0xFa34804390a2f6e14C547aFa976d4479F5f660E2] = block.timestamp;
_balances[0xBa21A83F49dbE14640c5a365713a93858397b598] = 4000000000000000000;
        userLastUpdateTime[0xBa21A83F49dbE14640c5a365713a93858397b598] = block.timestamp;
_balances[0xCFa91e557B07a81D0244cF902E27934B1A9BDE74] = 4000000000000000000;
        userLastUpdateTime[0xCFa91e557B07a81D0244cF902E27934B1A9BDE74] = block.timestamp;
_balances[0xe057C9AC1961299E596ef1aBA90D7d63b3AF03af] = 4000000000000000000;
        userLastUpdateTime[0xe057C9AC1961299E596ef1aBA90D7d63b3AF03af] = block.timestamp;
_balances[0xD8cB23521FAfb06A8ccDC60A8a01E7b92E9f4b82] = 4000000000000000000;
        userLastUpdateTime[0xD8cB23521FAfb06A8ccDC60A8a01E7b92E9f4b82] = block.timestamp;
_balances[0xe5a34bE43255181458a907a2AF99bEDc7C496E53] = 4000000000000000000;
        userLastUpdateTime[0xe5a34bE43255181458a907a2AF99bEDc7C496E53] = block.timestamp;
_balances[0xB36Ac67Fc5903f0b7317ba63DB2141De591175C0] = 4000000000000000000;
        userLastUpdateTime[0xB36Ac67Fc5903f0b7317ba63DB2141De591175C0] = block.timestamp;
_balances[0xD9e6E096649e183eB3F51f3A424EA940d4126a07] = 4000000000000000000;
        userLastUpdateTime[0xD9e6E096649e183eB3F51f3A424EA940d4126a07] = block.timestamp;
_balances[0xf1D6212ee15486a0E1541FD68318a2de4abF872d] = 4000000000000000000;
        userLastUpdateTime[0xf1D6212ee15486a0E1541FD68318a2de4abF872d] = block.timestamp;
_balances[0x99400C16d02C5dE7fE3b941815A8Bcd578A6FB42] = 4000000000000000000;
        userLastUpdateTime[0x99400C16d02C5dE7fE3b941815A8Bcd578A6FB42] = block.timestamp;
_balances[0x95e122628A0f323598460A071555c38cdc46fe00] = 4000000000000000000;
        userLastUpdateTime[0x95e122628A0f323598460A071555c38cdc46fe00] = block.timestamp;
_balances[0x9Baf7C87825e382408a5C17D36af48d3c8A4756B] = 4000000000000000000;
        userLastUpdateTime[0x9Baf7C87825e382408a5C17D36af48d3c8A4756B] = block.timestamp;
_balances[0x5629B2A346A466c0D07cBDCfEcdb6a3bb7d68ca5] = 4000000000000000000;
        userLastUpdateTime[0x5629B2A346A466c0D07cBDCfEcdb6a3bb7d68ca5] = block.timestamp;
_balances[0xAad3ceAbDb56c0D80710B21F9eBB27466d162229] = 4000000000000000000;
        userLastUpdateTime[0xAad3ceAbDb56c0D80710B21F9eBB27466d162229] = block.timestamp;
_balances[0x32466B73482B5d32e4B7b25BB15D4D9811c6a57A] = 4000000000000000000;
        userLastUpdateTime[0x32466B73482B5d32e4B7b25BB15D4D9811c6a57A] = block.timestamp;
_balances[0x2D2aD14D91b90ef3a1C61d9651F9A08F02d6c132] = 4000000000000000000;
        userLastUpdateTime[0x2D2aD14D91b90ef3a1C61d9651F9A08F02d6c132] = block.timestamp;
_balances[0x35F8ab8F92D45887A723bef52661a297a43Fd629] = 4000000000000000000;
        userLastUpdateTime[0x35F8ab8F92D45887A723bef52661a297a43Fd629] = block.timestamp;
_balances[0x1491aa46efaA3C03dc10Ee42FEA8BF749b8CA589] = 4000000000000000000;
        userLastUpdateTime[0x1491aa46efaA3C03dc10Ee42FEA8BF749b8CA589] = block.timestamp;
_balances[0x3161bdB52CFD87552DBb131c7D23dDEb7f0A1F5D] = 4000000000000000000;
        userLastUpdateTime[0x3161bdB52CFD87552DBb131c7D23dDEb7f0A1F5D] = block.timestamp;
_balances[0x033EC75DC32F5afD7D5b47eCA710B864b95E1a3C] = 4000000000000000000;
        userLastUpdateTime[0x033EC75DC32F5afD7D5b47eCA710B864b95E1a3C] = block.timestamp;
_balances[0x350e4e76d19290b49e3069da4A521E1b1eAD08dC] = 4000000000000000000;
        userLastUpdateTime[0x350e4e76d19290b49e3069da4A521E1b1eAD08dC] = block.timestamp;
_balances[0x435f2d5768456096527f9D01aC91F9AACfd5A72B] = 4000000000000000000;
        userLastUpdateTime[0x435f2d5768456096527f9D01aC91F9AACfd5A72B] = block.timestamp;
_balances[0x0dFdaaFac6ce581850EB5528186225DfC062F629] = 4000000000000000000;
        userLastUpdateTime[0x0dFdaaFac6ce581850EB5528186225DfC062F629] = block.timestamp;
_balances[0x072f38201348Cd61e39f1C41f05295466DCf35F2] = 4000000000000000000;
        userLastUpdateTime[0x072f38201348Cd61e39f1C41f05295466DCf35F2] = block.timestamp;
_balances[0x29F539c2Fb325e936268d67E17AfcA1281081d11] = 4000000000000000000;
        userLastUpdateTime[0x29F539c2Fb325e936268d67E17AfcA1281081d11] = block.timestamp;
_balances[0xB310de47510b4b4289220E28529F382FCa7b4B60] = 3000000000000000000;
        userLastUpdateTime[0xB310de47510b4b4289220E28529F382FCa7b4B60] = block.timestamp;
_balances[0xE7BF814ecC1902B84c31337882FCb22A0a47ad90] = 3000000000000000000;
        userLastUpdateTime[0xE7BF814ecC1902B84c31337882FCb22A0a47ad90] = block.timestamp;
_balances[0xD5D30906f6CF5bc0682Ef355d970b10B43c752ab] = 3000000000000000000;
        userLastUpdateTime[0xD5D30906f6CF5bc0682Ef355d970b10B43c752ab] = block.timestamp;
_balances[0xEbFF4A6ff7547c04A0b1432e6E7d09A2F344d7e9] = 3000000000000000000;
        userLastUpdateTime[0xEbFF4A6ff7547c04A0b1432e6E7d09A2F344d7e9] = block.timestamp;
_balances[0xfDfa92555e96bB2A57Da8a1A8cbda2262551F538] = 3000000000000000000;
        userLastUpdateTime[0xfDfa92555e96bB2A57Da8a1A8cbda2262551F538] = block.timestamp;
_balances[0xfE76B20e5Cc2f29F73B8b4991718CB18ce0BC7ED] = 3000000000000000000;
        userLastUpdateTime[0xfE76B20e5Cc2f29F73B8b4991718CB18ce0BC7ED] = block.timestamp;
_balances[0xe5130b679246e95Ca3a0eD2f284154B80607084F] = 3000000000000000000;
        userLastUpdateTime[0xe5130b679246e95Ca3a0eD2f284154B80607084F] = block.timestamp;
_balances[0xE047a9A62abc961ACF31B3A4c7e581EC8c706B74] = 3000000000000000000;
        userLastUpdateTime[0xE047a9A62abc961ACF31B3A4c7e581EC8c706B74] = block.timestamp;
_balances[0xB6dFA145D7Ad9a4Dd1e3C09c71c04D48E5D2e166] = 3000000000000000000;
        userLastUpdateTime[0xB6dFA145D7Ad9a4Dd1e3C09c71c04D48E5D2e166] = block.timestamp;
_balances[0xffd204B6ADc2F1617126D9A681b3087b950552D9] = 3000000000000000000;
        userLastUpdateTime[0xffd204B6ADc2F1617126D9A681b3087b950552D9] = block.timestamp;
_balances[0xeaafcB9E855Af7733F6Ed029aB164F09B29BF19d] = 3000000000000000000;
        userLastUpdateTime[0xeaafcB9E855Af7733F6Ed029aB164F09B29BF19d] = block.timestamp;
_balances[0xe23020aE155b31a22903dF8b0c743130CBB91C3e] = 3000000000000000000;
        userLastUpdateTime[0xe23020aE155b31a22903dF8b0c743130CBB91C3e] = block.timestamp;
_balances[0xb91aeAc38C146E599E41eDc54a81b4e30AE021e4] = 3000000000000000000;
        userLastUpdateTime[0xb91aeAc38C146E599E41eDc54a81b4e30AE021e4] = block.timestamp;
_balances[0xF42Bc1A36780275B0B410063546235b8B9B66321] = 3000000000000000000;
        userLastUpdateTime[0xF42Bc1A36780275B0B410063546235b8B9B66321] = block.timestamp;
_balances[0xB72eDF2669F2b05571aE4eE0E045D5927982b1a9] = 3000000000000000000;
        userLastUpdateTime[0xB72eDF2669F2b05571aE4eE0E045D5927982b1a9] = block.timestamp;
_balances[0xA2B48C299A90303E758680E4FdEcE6C0AdC1D588] = 3000000000000000000;
        userLastUpdateTime[0xA2B48C299A90303E758680E4FdEcE6C0AdC1D588] = block.timestamp;
_balances[0x978fFD1E31C031AD3e9b6a599d41E3D2a9bba4D3] = 3000000000000000000;
        userLastUpdateTime[0x978fFD1E31C031AD3e9b6a599d41E3D2a9bba4D3] = block.timestamp;
_balances[0x6F2ADc5a75e69c03D6AceE4b7dF84AE042D028f5] = 3000000000000000000;
        userLastUpdateTime[0x6F2ADc5a75e69c03D6AceE4b7dF84AE042D028f5] = block.timestamp;
_balances[0x692E0e5A4c6ed2C87A2Cf4CF5A95C97eE9d4bC52] = 3000000000000000000;
        userLastUpdateTime[0x692E0e5A4c6ed2C87A2Cf4CF5A95C97eE9d4bC52] = block.timestamp;
_balances[0x75CB87f8db17C5921Dfdd887a7F0aD576e2dA3aC] = 3000000000000000000;
        userLastUpdateTime[0x75CB87f8db17C5921Dfdd887a7F0aD576e2dA3aC] = block.timestamp;
_balances[0x85A87E7D4337798928Ec2FA8038B7efe327DA6Ad] = 3000000000000000000;
        userLastUpdateTime[0x85A87E7D4337798928Ec2FA8038B7efe327DA6Ad] = block.timestamp;
_balances[0x503bd321404723e8E6f1895cc11704A3Ba57c3F6] = 3000000000000000000;
        userLastUpdateTime[0x503bd321404723e8E6f1895cc11704A3Ba57c3F6] = block.timestamp;
_balances[0x6978CBD9B315803E9E022Ccb01E61039236086cb] = 3000000000000000000;
        userLastUpdateTime[0x6978CBD9B315803E9E022Ccb01E61039236086cb] = block.timestamp;
_balances[0x968137a1243e99A6D70afb8255F58191b26360a5] = 3000000000000000000;
        userLastUpdateTime[0x968137a1243e99A6D70afb8255F58191b26360a5] = block.timestamp;
_balances[0x5483Bb4Af64A34A3D510aA44A9C6D6Cf2c8D751F] = 3000000000000000000;
        userLastUpdateTime[0x5483Bb4Af64A34A3D510aA44A9C6D6Cf2c8D751F] = block.timestamp;
_balances[0x73241EBe4db860bbc7e1DD2B0F0805E2e14c2B4F] = 3000000000000000000;
        userLastUpdateTime[0x73241EBe4db860bbc7e1DD2B0F0805E2e14c2B4F] = block.timestamp;
_balances[0x54A987BB76eB866dc2359D6a7f7B8E160BD48f39] = 3000000000000000000;
        userLastUpdateTime[0x54A987BB76eB866dc2359D6a7f7B8E160BD48f39] = block.timestamp;
_balances[0x9f7b7DE079194BA5B2B5F8078fa8658872CC7888] = 3000000000000000000;
        userLastUpdateTime[0x9f7b7DE079194BA5B2B5F8078fa8658872CC7888] = block.timestamp;
_balances[0x6bB985e8f805b97Fa041bA4Fa187c68b5d24f649] = 3000000000000000000;
        userLastUpdateTime[0x6bB985e8f805b97Fa041bA4Fa187c68b5d24f649] = block.timestamp;
_balances[0x5E554AEB067375d81d82DBfB8739B27983807CfA] = 3000000000000000000;
        userLastUpdateTime[0x5E554AEB067375d81d82DBfB8739B27983807CfA] = block.timestamp;
_balances[0x93e4a8D7aA34CAed7669bfbd24037680277D277C] = 3000000000000000000;
        userLastUpdateTime[0x93e4a8D7aA34CAed7669bfbd24037680277D277C] = block.timestamp;
_balances[0x6eD487770e3065Ab5Ff038f757AAde4a35601C43] = 3000000000000000000;
        userLastUpdateTime[0x6eD487770e3065Ab5Ff038f757AAde4a35601C43] = block.timestamp;
_balances[0x4f53168EE82f997cf526180B8bCCa8805759C714] = 3000000000000000000;
        userLastUpdateTime[0x4f53168EE82f997cf526180B8bCCa8805759C714] = block.timestamp;
_balances[0x41238e4FC13AD5b2AA2ccA906027bF6058a9FbD0] = 3000000000000000000;
        userLastUpdateTime[0x41238e4FC13AD5b2AA2ccA906027bF6058a9FbD0] = block.timestamp;
_balances[0x34e12B4F69503683017B51BB00fce7F41092B739] = 3000000000000000000;
        userLastUpdateTime[0x34e12B4F69503683017B51BB00fce7F41092B739] = block.timestamp;
_balances[0x290A455727Ab78F39bd45F9fcCD8d7dC7418D764] = 3000000000000000000;
        userLastUpdateTime[0x290A455727Ab78F39bd45F9fcCD8d7dC7418D764] = block.timestamp;
_balances[0x14C4FA893F0e86dD6bAf9AEA3F13AD110D30304d] = 3000000000000000000;
        userLastUpdateTime[0x14C4FA893F0e86dD6bAf9AEA3F13AD110D30304d] = block.timestamp;
_balances[0x058A86A0b6594590B4eb5F2787f7EBaBbCCdFC00] = 3000000000000000000;
        userLastUpdateTime[0x058A86A0b6594590B4eb5F2787f7EBaBbCCdFC00] = block.timestamp;
_balances[0x46FADA17B8F2b8c0AD4DD5226205aB2eb0e72412] = 3000000000000000000;
        userLastUpdateTime[0x46FADA17B8F2b8c0AD4DD5226205aB2eb0e72412] = block.timestamp;
_balances[0x43b1Ad99AA6DB7CB8Fd6a906706b1Ee278b70d9d] = 3000000000000000000;
        userLastUpdateTime[0x43b1Ad99AA6DB7CB8Fd6a906706b1Ee278b70d9d] = block.timestamp;
_balances[0x48c724c256C52994427ccDFBbfD7E9b93776acD5] = 3000000000000000000;
        userLastUpdateTime[0x48c724c256C52994427ccDFBbfD7E9b93776acD5] = block.timestamp;
_balances[0x3436100674492BCe353C6709ec11DEd32b1A797a] = 3000000000000000000;
        userLastUpdateTime[0x3436100674492BCe353C6709ec11DEd32b1A797a] = block.timestamp;
_balances[0x08bf2A7488f7DA084d8cffbF4B5CeF085f2cFf2F] = 3000000000000000000;
        userLastUpdateTime[0x08bf2A7488f7DA084d8cffbF4B5CeF085f2cFf2F] = block.timestamp;
_balances[0x24e90090DeDA09E90BC20d6448799fcC963310b5] = 3000000000000000000;
        userLastUpdateTime[0x24e90090DeDA09E90BC20d6448799fcC963310b5] = block.timestamp;
_balances[0x30F871610C59431707EF9875a93506b8Fa0e99Dc] = 3000000000000000000;
        userLastUpdateTime[0x30F871610C59431707EF9875a93506b8Fa0e99Dc] = block.timestamp;
_balances[0x361BbBF83e5CcEd01900b99D3e1e78217877479e] = 3000000000000000000;
        userLastUpdateTime[0x361BbBF83e5CcEd01900b99D3e1e78217877479e] = block.timestamp;
_balances[0x310D9B19088A1c987873AECC96C02e2610f833A0] = 3000000000000000000;
        userLastUpdateTime[0x310D9B19088A1c987873AECC96C02e2610f833A0] = block.timestamp;
_balances[0x290A02050765Cc86b6f47689A12532A20285398D] = 3000000000000000000;
        userLastUpdateTime[0x290A02050765Cc86b6f47689A12532A20285398D] = block.timestamp;
_balances[0x1d65535f10c6518181B1cba06Cf0dC6106Fd4E8d] = 3000000000000000000;
        userLastUpdateTime[0x1d65535f10c6518181B1cba06Cf0dC6106Fd4E8d] = block.timestamp;
_balances[0x4698FCa939f91a5D02008211a359fa3c710C7b2a] = 3000000000000000000;
        userLastUpdateTime[0x4698FCa939f91a5D02008211a359fa3c710C7b2a] = block.timestamp;
_balances[0x027C73dF1f9F1b846bb79c0D23C6c5a5798a747F] = 3000000000000000000;
        userLastUpdateTime[0x027C73dF1f9F1b846bb79c0D23C6c5a5798a747F] = block.timestamp;
_balances[0x0C07747AB98EE84971C90Fbd353eda207B737c43] = 3000000000000000000;
        userLastUpdateTime[0x0C07747AB98EE84971C90Fbd353eda207B737c43] = block.timestamp;
_balances[0x4b1bbd21916421c830426db9279E3BdB2D238c48] = 3000000000000000000;
        userLastUpdateTime[0x4b1bbd21916421c830426db9279E3BdB2D238c48] = block.timestamp;
_balances[0x2d18205663e3c675E63E9AE5831ce166e11A1DD9] = 3000000000000000000;
        userLastUpdateTime[0x2d18205663e3c675E63E9AE5831ce166e11A1DD9] = block.timestamp;
_balances[0x27C515f713421fb3E0f1Ae0F3DA4623EB3580b3d] = 3000000000000000000;
        userLastUpdateTime[0x27C515f713421fb3E0f1Ae0F3DA4623EB3580b3d] = block.timestamp;
_balances[0xB9b0834b132a82567e38E9c160124284430ceD6a] = 2000000000000000000;
        userLastUpdateTime[0xB9b0834b132a82567e38E9c160124284430ceD6a] = block.timestamp;
_balances[0xeb6B52E7D5c6f462Def7301707Cb77776653BE7C] = 2000000000000000000;
        userLastUpdateTime[0xeb6B52E7D5c6f462Def7301707Cb77776653BE7C] = block.timestamp;
_balances[0xbf6c7208a0aD7612C53BFfB567E7365a3d02e86a] = 2000000000000000000;
        userLastUpdateTime[0xbf6c7208a0aD7612C53BFfB567E7365a3d02e86a] = block.timestamp;
_balances[0xD2531Bce6e9d732112EBaFce01f592595fEc14DB] = 2000000000000000000;
        userLastUpdateTime[0xD2531Bce6e9d732112EBaFce01f592595fEc14DB] = block.timestamp;
_balances[0xc5c7904A8D8955AA97cF249Dc5eCD0a55524D064] = 2000000000000000000;
        userLastUpdateTime[0xc5c7904A8D8955AA97cF249Dc5eCD0a55524D064] = block.timestamp;
_balances[0xF447E6818FE4daa3F048373C3011BcE14a23F5d7] = 2000000000000000000;
        userLastUpdateTime[0xF447E6818FE4daa3F048373C3011BcE14a23F5d7] = block.timestamp;
_balances[0xC5963017878724AE94cB1dCb9547707e77A86cF2] = 2000000000000000000;
        userLastUpdateTime[0xC5963017878724AE94cB1dCb9547707e77A86cF2] = block.timestamp;
_balances[0xf5BEeaEA001053a31a471F5f7eE0AE278D18F5f6] = 2000000000000000000;
        userLastUpdateTime[0xf5BEeaEA001053a31a471F5f7eE0AE278D18F5f6] = block.timestamp;
_balances[0xD8fEae09b146E3A060d440B1321F9f8905D25FF3] = 2000000000000000000;
        userLastUpdateTime[0xD8fEae09b146E3A060d440B1321F9f8905D25FF3] = block.timestamp;
_balances[0xd2d3F659E49e037138a018337Ce16F05b0416A99] = 2000000000000000000;
        userLastUpdateTime[0xd2d3F659E49e037138a018337Ce16F05b0416A99] = block.timestamp;
_balances[0xec237Ef673b6ef6f62DDA77a5731E2cB2Ce371f4] = 2000000000000000000;
        userLastUpdateTime[0xec237Ef673b6ef6f62DDA77a5731E2cB2Ce371f4] = block.timestamp;
_balances[0xd32a49ee43667494342426cfb44E66E1ce58d81C] = 2000000000000000000;
        userLastUpdateTime[0xd32a49ee43667494342426cfb44E66E1ce58d81C] = block.timestamp;
_balances[0xD20FEd1Ae1dc6C2927E57516BF7C9F22ed269118] = 2000000000000000000;
        userLastUpdateTime[0xD20FEd1Ae1dc6C2927E57516BF7C9F22ed269118] = block.timestamp;
_balances[0xAC26B45B4675611C3e2FeF1D4a386d06E0a38252] = 2000000000000000000;
        userLastUpdateTime[0xAC26B45B4675611C3e2FeF1D4a386d06E0a38252] = block.timestamp;
_balances[0xcd245Eb87Cce56756BBF4661A5a88999A48d8752] = 2000000000000000000;
        userLastUpdateTime[0xcd245Eb87Cce56756BBF4661A5a88999A48d8752] = block.timestamp;
_balances[0xE22D911479C9D288A21Cf171A4F7904CC4868151] = 2000000000000000000;
        userLastUpdateTime[0xE22D911479C9D288A21Cf171A4F7904CC4868151] = block.timestamp;
_balances[0xBAd8CA5A6595991a7005145371b3fcD189B40805] = 2000000000000000000;
        userLastUpdateTime[0xBAd8CA5A6595991a7005145371b3fcD189B40805] = block.timestamp;
_balances[0xd59183c7F3a454Ef2cC9Aa5aCe16C0a193fD22Ef] = 2000000000000000000;
        userLastUpdateTime[0xd59183c7F3a454Ef2cC9Aa5aCe16C0a193fD22Ef] = block.timestamp;
_balances[0xeA90FA58fEBAB4222C4e8F8Eec6049Bff5f7233E] = 2000000000000000000;
        userLastUpdateTime[0xeA90FA58fEBAB4222C4e8F8Eec6049Bff5f7233E] = block.timestamp;
_balances[0xc7d5490B2992F369D9CfB913A511320a3d26ABc8] = 2000000000000000000;
        userLastUpdateTime[0xc7d5490B2992F369D9CfB913A511320a3d26ABc8] = block.timestamp;
_balances[0xeaFdD35E23aBF7D932F3AfE5755AaB40C53FAD6b] = 2000000000000000000;
        userLastUpdateTime[0xeaFdD35E23aBF7D932F3AfE5755AaB40C53FAD6b] = block.timestamp;
_balances[0xe438751B44a9C6288FD97634D5F5eF2741B686c4] = 2000000000000000000;
        userLastUpdateTime[0xe438751B44a9C6288FD97634D5F5eF2741B686c4] = block.timestamp;
_balances[0xfaF7adBA4dcbFE585071837129Abc805d2Cd093C] = 2000000000000000000;
        userLastUpdateTime[0xfaF7adBA4dcbFE585071837129Abc805d2Cd093C] = block.timestamp;
_balances[0xe4F29109Df1b22D6804e4e55Ab068166b2310A6c] = 2000000000000000000;
        userLastUpdateTime[0xe4F29109Df1b22D6804e4e55Ab068166b2310A6c] = block.timestamp;
_balances[0xeca52B542105C44ec8A423C920432bD908FcDb76] = 2000000000000000000;
        userLastUpdateTime[0xeca52B542105C44ec8A423C920432bD908FcDb76] = block.timestamp;
_balances[0xaf0C08bb4e7De5D1824F26b5c550a204C0067A17] = 2000000000000000000;
        userLastUpdateTime[0xaf0C08bb4e7De5D1824F26b5c550a204C0067A17] = block.timestamp;
_balances[0xf208127D6325DaAa568f031709a31d198b08d0f5] = 2000000000000000000;
        userLastUpdateTime[0xf208127D6325DaAa568f031709a31d198b08d0f5] = block.timestamp;
_balances[0xCb1b713a5ac5FF206fC1F1D78C57A089F5578e98] = 2000000000000000000;
        userLastUpdateTime[0xCb1b713a5ac5FF206fC1F1D78C57A089F5578e98] = block.timestamp;
_balances[0xb1Ef4840213e387e5Cebcf5472d88fE9C2775dFa] = 2000000000000000000;
        userLastUpdateTime[0xb1Ef4840213e387e5Cebcf5472d88fE9C2775dFa] = block.timestamp;
_balances[0xBF7267e9614166b300c5e7DaBd57751B96E0C607] = 2000000000000000000;
        userLastUpdateTime[0xBF7267e9614166b300c5e7DaBd57751B96E0C607] = block.timestamp;
_balances[0xDbDa03Aa9E624Ba214f475B1007042d6cFD8E23e] = 2000000000000000000;
        userLastUpdateTime[0xDbDa03Aa9E624Ba214f475B1007042d6cFD8E23e] = block.timestamp;
_balances[0xf7E7996fb07c67852C91cB82f72Ed62Ba060eD14] = 2000000000000000000;
        userLastUpdateTime[0xf7E7996fb07c67852C91cB82f72Ed62Ba060eD14] = block.timestamp;
_balances[0xDF965C23cdF6019dd848766e3813aFB915d034a6] = 2000000000000000000;
        userLastUpdateTime[0xDF965C23cdF6019dd848766e3813aFB915d034a6] = block.timestamp;
_balances[0xc253052671Fa11953E9EABf515307e8507c5e61C] = 2000000000000000000;
        userLastUpdateTime[0xc253052671Fa11953E9EABf515307e8507c5e61C] = block.timestamp;
_balances[0xdfBea6F320b313121753EF8dc2cde2590d23792d] = 2000000000000000000;
        userLastUpdateTime[0xdfBea6F320b313121753EF8dc2cde2590d23792d] = block.timestamp;
_balances[0xfDf4395d23A0619A29027AE5395e4466Ba3fb95e] = 2000000000000000000;
        userLastUpdateTime[0xfDf4395d23A0619A29027AE5395e4466Ba3fb95e] = block.timestamp;
_balances[0x973477e108f9e5B4aA61CC5B972015daf3c20f5a] = 2000000000000000000;
        userLastUpdateTime[0x973477e108f9e5B4aA61CC5B972015daf3c20f5a] = block.timestamp;
_balances[0x8F00638af9c39BE1cb44B2841D4b265fE6b55bF4] = 2000000000000000000;
        userLastUpdateTime[0x8F00638af9c39BE1cb44B2841D4b265fE6b55bF4] = block.timestamp;
_balances[0x5f58a3499bC7Bd393c5DAB9Ec256313c8622cE95] = 2000000000000000000;
        userLastUpdateTime[0x5f58a3499bC7Bd393c5DAB9Ec256313c8622cE95] = block.timestamp;
_balances[0x61742B9c3C30443e4587efdA9A942B9fd738Cf4e] = 2000000000000000000;
        userLastUpdateTime[0x61742B9c3C30443e4587efdA9A942B9fd738Cf4e] = block.timestamp;
_balances[0x5c50F99393e2C9D7922a8DCb1800808d46f2Bdd9] = 2000000000000000000;
        userLastUpdateTime[0x5c50F99393e2C9D7922a8DCb1800808d46f2Bdd9] = block.timestamp;
_balances[0x621Db47A673D0123cBA815eF128284A3164d531d] = 2000000000000000000;
        userLastUpdateTime[0x621Db47A673D0123cBA815eF128284A3164d531d] = block.timestamp;
_balances[0x9c7952EcDe33E626F1212B5841bF9B35d710403E] = 2000000000000000000;
        userLastUpdateTime[0x9c7952EcDe33E626F1212B5841bF9B35d710403E] = block.timestamp;
_balances[0x686C9e4D47A5D31c6a3a6356A4F3f19212Fab7BB] = 2000000000000000000;
        userLastUpdateTime[0x686C9e4D47A5D31c6a3a6356A4F3f19212Fab7BB] = block.timestamp;
_balances[0x8df59977017E57c0770bCe742e39e7F5f031370F] = 2000000000000000000;
        userLastUpdateTime[0x8df59977017E57c0770bCe742e39e7F5f031370F] = block.timestamp;
_balances[0x69771301F39eF29E7916027D860abcEE41c3A8f0] = 2000000000000000000;
        userLastUpdateTime[0x69771301F39eF29E7916027D860abcEE41c3A8f0] = block.timestamp;
_balances[0x91FFfdF92872438783E92C7722509CD1BC66c8A3] = 2000000000000000000;
        userLastUpdateTime[0x91FFfdF92872438783E92C7722509CD1BC66c8A3] = block.timestamp;
_balances[0x57816604aB4147f2aEF715067e76C51a0785C0cd] = 2000000000000000000;
        userLastUpdateTime[0x57816604aB4147f2aEF715067e76C51a0785C0cd] = block.timestamp;
_balances[0x94A608EBf30169750a2C797b310f6cB0728e8BE3] = 2000000000000000000;
        userLastUpdateTime[0x94A608EBf30169750a2C797b310f6cB0728e8BE3] = block.timestamp;
_balances[0x69a98d9Dd03e00Cb3f9663B6d8e3AeE1c027c0a4] = 2000000000000000000;
        userLastUpdateTime[0x69a98d9Dd03e00Cb3f9663B6d8e3AeE1c027c0a4] = block.timestamp;
_balances[0x9BB1B1463D8323678b585fa20672c9f18f8cAd2B] = 2000000000000000000;
        userLastUpdateTime[0x9BB1B1463D8323678b585fa20672c9f18f8cAd2B] = block.timestamp;
_balances[0x6D1DEDAceB920980Ae80e2C901971755296Ca41e] = 2000000000000000000;
        userLastUpdateTime[0x6D1DEDAceB920980Ae80e2C901971755296Ca41e] = block.timestamp;
_balances[0x5f3ca358E464650327AD24DEf75f22494A349a28] = 2000000000000000000;
        userLastUpdateTime[0x5f3ca358E464650327AD24DEf75f22494A349a28] = block.timestamp;
_balances[0x727c1b5aA33b1607078e0Fb5C2BA43ec07E2fC7f] = 2000000000000000000;
        userLastUpdateTime[0x727c1b5aA33b1607078e0Fb5C2BA43ec07E2fC7f] = block.timestamp;
_balances[0x876CcD8F591555950A2Ad84CE929029188521FC2] = 2000000000000000000;
        userLastUpdateTime[0x876CcD8F591555950A2Ad84CE929029188521FC2] = block.timestamp;
_balances[0x746c306b5A4ddf4e82201b549E743C06233Af854] = 2000000000000000000;
        userLastUpdateTime[0x746c306b5A4ddf4e82201b549E743C06233Af854] = block.timestamp;
_balances[0x5BE48Eb33ecC783CE0dBf17Ce0d392bDC3D1C5de] = 2000000000000000000;
        userLastUpdateTime[0x5BE48Eb33ecC783CE0dBf17Ce0d392bDC3D1C5de] = block.timestamp;
_balances[0x78D3b056BF44600B719c1e43Ef3E0E356D55F6A3] = 2000000000000000000;
        userLastUpdateTime[0x78D3b056BF44600B719c1e43Ef3E0E356D55F6A3] = block.timestamp;
_balances[0x90173D26F4FeFbF783D3f78773653f3E986CEc58] = 2000000000000000000;
        userLastUpdateTime[0x90173D26F4FeFbF783D3f78773653f3E986CEc58] = block.timestamp;
_balances[0x5A1Cd1be11fe3A92B32C38e959C8bca1a075b035] = 2000000000000000000;
        userLastUpdateTime[0x5A1Cd1be11fe3A92B32C38e959C8bca1a075b035] = block.timestamp;
_balances[0x92A5158CAAA83Ba2a1Ed8E8fc28DA823d227E04B] = 2000000000000000000;
        userLastUpdateTime[0x92A5158CAAA83Ba2a1Ed8E8fc28DA823d227E04B] = block.timestamp;
_balances[0xaae3DDdeB1C4dEe0882A6AB897FaBBF0570530d1] = 2000000000000000000;
        userLastUpdateTime[0xaae3DDdeB1C4dEe0882A6AB897FaBBF0570530d1] = block.timestamp;
_balances[0x93137e7CF86359A49B6892014829831740325206] = 2000000000000000000;
        userLastUpdateTime[0x93137e7CF86359A49B6892014829831740325206] = block.timestamp;
_balances[0x7d116123BC836B532EC6D8121bc48BD509Abfb4d] = 2000000000000000000;
        userLastUpdateTime[0x7d116123BC836B532EC6D8121bc48BD509Abfb4d] = block.timestamp;
_balances[0x971Ae3969a24eD3082c053507d84071Daf55C59D] = 2000000000000000000;
        userLastUpdateTime[0x971Ae3969a24eD3082c053507d84071Daf55C59D] = block.timestamp;
_balances[0x7E5Ed83fe9fE3CB47fA04d36e49beBDA164c3AAE] = 2000000000000000000;
        userLastUpdateTime[0x7E5Ed83fe9fE3CB47fA04d36e49beBDA164c3AAE] = block.timestamp;
_balances[0x99d3e206c94D86Bf80b4E4D49b789FAEbd5d1c24] = 2000000000000000000;
        userLastUpdateTime[0x99d3e206c94D86Bf80b4E4D49b789FAEbd5d1c24] = block.timestamp;
_balances[0x81c874020282397cC05009fba791dEbA802EE531] = 2000000000000000000;
        userLastUpdateTime[0x81c874020282397cC05009fba791dEbA802EE531] = block.timestamp;
_balances[0x9BeB2df4Bf7Ddd5f06f7Ac71ecaB0440246278CE] = 2000000000000000000;
        userLastUpdateTime[0x9BeB2df4Bf7Ddd5f06f7Ac71ecaB0440246278CE] = block.timestamp;
_balances[0x83A4699a7526B979fca28633EFB7f19d652f2773] = 2000000000000000000;
        userLastUpdateTime[0x83A4699a7526B979fca28633EFB7f19d652f2773] = block.timestamp;
_balances[0x9d44C131E702AC25CEAD57943cEac7ecb35b7817] = 2000000000000000000;
        userLastUpdateTime[0x9d44C131E702AC25CEAD57943cEac7ecb35b7817] = block.timestamp;
_balances[0x5A6338B837CE975C7F5c9aEF9cE1f7EB256C009F] = 2000000000000000000;
        userLastUpdateTime[0x5A6338B837CE975C7F5c9aEF9cE1f7EB256C009F] = block.timestamp;
_balances[0xA2216B7c998571Daf84bAb685B31FcE0F16753E7] = 2000000000000000000;
        userLastUpdateTime[0xA2216B7c998571Daf84bAb685B31FcE0F16753E7] = block.timestamp;
_balances[0x85E700F6c3856F45D983DaD41e5E99dF733390f4] = 2000000000000000000;
        userLastUpdateTime[0x85E700F6c3856F45D983DaD41e5E99dF733390f4] = block.timestamp;
_balances[0x873Beebe8C95Ee6945f4efeFd4079cb323671d7B] = 2000000000000000000;
        userLastUpdateTime[0x873Beebe8C95Ee6945f4efeFd4079cb323671d7B] = block.timestamp;
_balances[0xa714dadBdeC7436dcd5B6BB9eEe3CfbDb95302DD] = 2000000000000000000;
        userLastUpdateTime[0xa714dadBdeC7436dcd5B6BB9eEe3CfbDb95302DD] = block.timestamp;
_balances[0x3E6E5A70d7f811811dA53326d97454e5acB28ab0] = 2000000000000000000;
        userLastUpdateTime[0x3E6E5A70d7f811811dA53326d97454e5acB28ab0] = block.timestamp;
_balances[0x1876aAc2A7EC76AEc5F01cC97ac56569d582e0C0] = 2000000000000000000;
        userLastUpdateTime[0x1876aAc2A7EC76AEc5F01cC97ac56569d582e0C0] = block.timestamp;
_balances[0x0561B1fddeF16C270f3e1A67230e6e41386F32CF] = 2000000000000000000;
        userLastUpdateTime[0x0561B1fddeF16C270f3e1A67230e6e41386F32CF] = block.timestamp;
_balances[0x25431650e79Da5fd0516c2Ac523188Bfa1E1f2FA] = 2000000000000000000;
        userLastUpdateTime[0x25431650e79Da5fd0516c2Ac523188Bfa1E1f2FA] = block.timestamp;
_balances[0x0B104d633dc97FAD97d1210cdfA0955d758449AF] = 2000000000000000000;
        userLastUpdateTime[0x0B104d633dc97FAD97d1210cdfA0955d758449AF] = block.timestamp;
_balances[0x25B1a29A9F336F1ea94ef223B6461dd793c6A5F6] = 2000000000000000000;
        userLastUpdateTime[0x25B1a29A9F336F1ea94ef223B6461dd793c6A5F6] = block.timestamp;
_balances[0x0B30158C32C65F97b856fd3284F768224897a3bF] = 2000000000000000000;
        userLastUpdateTime[0x0B30158C32C65F97b856fd3284F768224897a3bF] = block.timestamp;
_balances[0x01D9e348cda769Cb09Fc75Eb56759e15C4ECaF67] = 2000000000000000000;
        userLastUpdateTime[0x01D9e348cda769Cb09Fc75Eb56759e15C4ECaF67] = block.timestamp;
_balances[0x006958472e1F5f736BF2D6460C6015Fa0425D770] = 2000000000000000000;
        userLastUpdateTime[0x006958472e1F5f736BF2D6460C6015Fa0425D770] = block.timestamp;
_balances[0x0283401164BD0e32bB06328039d4a32aFe0D22b8] = 2000000000000000000;
        userLastUpdateTime[0x0283401164BD0e32bB06328039d4a32aFe0D22b8] = block.timestamp;
_balances[0x1C8B33d97943c6952f6abE8bfdb41102ffD6ebb3] = 2000000000000000000;
        userLastUpdateTime[0x1C8B33d97943c6952f6abE8bfdb41102ffD6ebb3] = block.timestamp;
_balances[0x058f44A1Fe342B452162A0863fA0de8A8f5B9751] = 2000000000000000000;
        userLastUpdateTime[0x058f44A1Fe342B452162A0863fA0de8A8f5B9751] = block.timestamp;
_balances[0x04Fe2B4FCD3E5C2472e9b537f815e5F5697795Be] = 2000000000000000000;
        userLastUpdateTime[0x04Fe2B4FCD3E5C2472e9b537f815e5F5697795Be] = block.timestamp;
_balances[0x0319e1d708EB4fAa2090d564A04622c0C38F69Ca] = 2000000000000000000;
        userLastUpdateTime[0x0319e1d708EB4fAa2090d564A04622c0C38F69Ca] = block.timestamp;
_balances[0x213Ad70bF4821C268A22641a06D92edE6deE71BC] = 2000000000000000000;
        userLastUpdateTime[0x213Ad70bF4821C268A22641a06D92edE6deE71BC] = block.timestamp;
_balances[0x11ebB2fA2586B87bD63C366A3006A5cD35257feb] = 2000000000000000000;
        userLastUpdateTime[0x11ebB2fA2586B87bD63C366A3006A5cD35257feb] = block.timestamp;
_balances[0x2318C512B95404d05b09936DB4836c78054253f7] = 2000000000000000000;
        userLastUpdateTime[0x2318C512B95404d05b09936DB4836c78054253f7] = block.timestamp;
_balances[0x12250BE94E7bdF6D43b6702256Fe0eC953e16662] = 2000000000000000000;
        userLastUpdateTime[0x12250BE94E7bdF6D43b6702256Fe0eC953e16662] = block.timestamp;
_balances[0x48eC9D21018E9A8E70d26AC936E53FF4532aC8F8] = 2000000000000000000;
        userLastUpdateTime[0x48eC9D21018E9A8E70d26AC936E53FF4532aC8F8] = block.timestamp;
_balances[0x2A407492f6EeC72000BbF5564212De937dee7551] = 2000000000000000000;
        userLastUpdateTime[0x2A407492f6EeC72000BbF5564212De937dee7551] = block.timestamp;
_balances[0x4D54FE5C7261493E91C45D77381d51cf9B49DF7a] = 2000000000000000000;
        userLastUpdateTime[0x4D54FE5C7261493E91C45D77381d51cf9B49DF7a] = block.timestamp;
_balances[0x2b165a80E79f5458aa66Efd0ee6D384215AbC0c8] = 2000000000000000000;
        userLastUpdateTime[0x2b165a80E79f5458aa66Efd0ee6D384215AbC0c8] = block.timestamp;
_balances[0x1adEade06289256391F12C398961d308F51E01f8] = 2000000000000000000;
        userLastUpdateTime[0x1adEade06289256391F12C398961d308F51E01f8] = block.timestamp;
_balances[0x2b80581651BDeCfadeA111A000E95ef06FB29044] = 2000000000000000000;
        userLastUpdateTime[0x2b80581651BDeCfadeA111A000E95ef06FB29044] = block.timestamp;
_balances[0x1cFd878b78C9e6C1334e6131dAa1F5e0B2295002] = 2000000000000000000;
        userLastUpdateTime[0x1cFd878b78C9e6C1334e6131dAa1F5e0B2295002] = block.timestamp;
_balances[0x2C4eFC1229dB8803BC57363Ed449cFDcCd220356] = 2000000000000000000;
        userLastUpdateTime[0x2C4eFC1229dB8803BC57363Ed449cFDcCd220356] = block.timestamp;
_balances[0x371F45D21A38058C3F23592ccb479Fc0cC26bA6f] = 2000000000000000000;
        userLastUpdateTime[0x371F45D21A38058C3F23592ccb479Fc0cC26bA6f] = block.timestamp;
_balances[0x1313D555bBE2069D87E12B1Bb4ca2f401fF18589] = 2000000000000000000;
        userLastUpdateTime[0x1313D555bBE2069D87E12B1Bb4ca2f401fF18589] = block.timestamp;
_balances[0x3De9339b516f442942779E67FabbFd3b46d87eCe] = 2000000000000000000;
        userLastUpdateTime[0x3De9339b516f442942779E67FabbFd3b46d87eCe] = block.timestamp;
_balances[0x14164C1b74b0fdA87fEDeb527Ecb5803554F1EF7] = 2000000000000000000;
        userLastUpdateTime[0x14164C1b74b0fdA87fEDeb527Ecb5803554F1EF7] = block.timestamp;
_balances[0x051Bf486C56B5Bb3cd53704158Fe093833F57A25] = 2000000000000000000;
        userLastUpdateTime[0x051Bf486C56B5Bb3cd53704158Fe093833F57A25] = block.timestamp;
_balances[0x2d4D0C9290B8647C8283aBB77058Db3bD8B71461] = 2000000000000000000;
        userLastUpdateTime[0x2d4D0C9290B8647C8283aBB77058Db3bD8B71461] = block.timestamp;
_balances[0x425aB2051e0cB14701Bd00bFa7e65aa57dA252Df] = 2000000000000000000;
        userLastUpdateTime[0x425aB2051e0cB14701Bd00bFa7e65aa57dA252Df] = block.timestamp;
_balances[0x2FA63f156B4Ed19bAC7AF3d33aD86eBEbff8555d] = 2000000000000000000;
        userLastUpdateTime[0x2FA63f156B4Ed19bAC7AF3d33aD86eBEbff8555d] = block.timestamp;
_balances[0x22165afD3D07F0dC2Ce13c5bb20FDF925e56E350] = 2000000000000000000;
        userLastUpdateTime[0x22165afD3D07F0dC2Ce13c5bb20FDF925e56E350] = block.timestamp;
_balances[0x14372929E2E6Cb64644F89AD4fbA54BD00A14b0c] = 2000000000000000000;
        userLastUpdateTime[0x14372929E2E6Cb64644F89AD4fbA54BD00A14b0c] = block.timestamp;
_balances[0x23E9AEC68f6691eE6b9B0F0b07c97B6070D060e3] = 2000000000000000000;
        userLastUpdateTime[0x23E9AEC68f6691eE6b9B0F0b07c97B6070D060e3] = block.timestamp;
_balances[0x05eaDE32195cB0Bb6Dd7ba9535419b98Be7ABa8A] = 2000000000000000000;
        userLastUpdateTime[0x05eaDE32195cB0Bb6Dd7ba9535419b98Be7ABa8A] = block.timestamp;
_balances[0x06697DF880377d0C45fb94355B17AD1d70CF7bb3] = 2000000000000000000;
        userLastUpdateTime[0x06697DF880377d0C45fb94355B17AD1d70CF7bb3] = block.timestamp;
_balances[0x092399444236dA63F79400bE20a2498245f9e9f2] = 2000000000000000000;
        userLastUpdateTime[0x092399444236dA63F79400bE20a2498245f9e9f2] = block.timestamp;
_balances[0x4AE8123EC93CA0F357379d7E91CDdE221997aBda] = 2000000000000000000;
        userLastUpdateTime[0x4AE8123EC93CA0F357379d7E91CDdE221997aBda] = block.timestamp;
_balances[0x317085162ECa4B00B380079eA5C5DF150dBcEbed] = 2000000000000000000;
        userLastUpdateTime[0x317085162ECa4B00B380079eA5C5DF150dBcEbed] = block.timestamp;
_balances[0x4b78a7c9aF58680eFfa4D23eb7F76Fa55F9166a0] = 2000000000000000000;
        userLastUpdateTime[0x4b78a7c9aF58680eFfa4D23eb7F76Fa55F9166a0] = block.timestamp;
_balances[0x18416984583f1D6759DbAD170462964cA3869b19] = 2000000000000000000;
        userLastUpdateTime[0x18416984583f1D6759DbAD170462964cA3869b19] = block.timestamp;
_balances[0x09EdED237B18Df5aB766fFA9026E1DD8018146BA] = 2000000000000000000;
        userLastUpdateTime[0x09EdED237B18Df5aB766fFA9026E1DD8018146BA] = block.timestamp;
_balances[0x4D8FCD9304ca1574CDC453d9390aBf1aD1e6bB89] = 2000000000000000000;
        userLastUpdateTime[0x4D8FCD9304ca1574CDC453d9390aBf1aD1e6bB89] = block.timestamp;
_balances[0x251398Ca6E383c632Ef704A045b68ce8D117e971] = 2000000000000000000;
        userLastUpdateTime[0x251398Ca6E383c632Ef704A045b68ce8D117e971] = block.timestamp;
_balances[0x4e4CC29ab82cf8aa4EcD3578A26409E57793de4b] = 2000000000000000000;
        userLastUpdateTime[0x4e4CC29ab82cf8aa4EcD3578A26409E57793de4b] = block.timestamp;
_balances[0xad5e2343950C305B2e942266D2CB8Eb633d9f7aC] = 1000000000000000000;
        userLastUpdateTime[0xad5e2343950C305B2e942266D2CB8Eb633d9f7aC] = block.timestamp;
_balances[0xC02Dd50b25364e747410730A1df9B72A92C3C68B] = 1000000000000000000;
        userLastUpdateTime[0xC02Dd50b25364e747410730A1df9B72A92C3C68B] = block.timestamp;
_balances[0xACA85D76EA0ce8d29c1511De4F53Ed09805676d5] = 1000000000000000000;
        userLastUpdateTime[0xACA85D76EA0ce8d29c1511De4F53Ed09805676d5] = block.timestamp;
_balances[0xC94250F3928d0f8DdB6e2812eE74f7Cb15cd274d] = 1000000000000000000;
        userLastUpdateTime[0xC94250F3928d0f8DdB6e2812eE74f7Cb15cd274d] = block.timestamp;
_balances[0xeb05798683c29E0F520cddBb9b2D8794A98fc2f1] = 1000000000000000000;
        userLastUpdateTime[0xeb05798683c29E0F520cddBb9b2D8794A98fc2f1] = block.timestamp;
_balances[0xc99bF706F34a1F95bB87d359A1881829A18ab1f9] = 1000000000000000000;
        userLastUpdateTime[0xc99bF706F34a1F95bB87d359A1881829A18ab1f9] = block.timestamp;
_balances[0xc80a1f5B642f780437275160cBebaCE9e0806CF9] = 1000000000000000000;
        userLastUpdateTime[0xc80a1f5B642f780437275160cBebaCE9e0806CF9] = block.timestamp;
_balances[0xca03AA3060dfdd3acdB73f8B41096a0f3336298B] = 1000000000000000000;
        userLastUpdateTime[0xca03AA3060dfdd3acdB73f8B41096a0f3336298B] = block.timestamp;
_balances[0xe4FeE867eDB93f336AeD8b0051dF26A2ce3e1d99] = 1000000000000000000;
        userLastUpdateTime[0xe4FeE867eDB93f336AeD8b0051dF26A2ce3e1d99] = block.timestamp;
_balances[0xB33f116A49307D83d345eb6B28C77b4a93F7E378] = 1000000000000000000;
        userLastUpdateTime[0xB33f116A49307D83d345eb6B28C77b4a93F7E378] = block.timestamp;
_balances[0xe9C814545B9775E1af5677715C05D9C349571474] = 1000000000000000000;
        userLastUpdateTime[0xe9C814545B9775E1af5677715C05D9C349571474] = block.timestamp;
_balances[0xCB4CC352e1165fAC6935a18b619109e1F0943Fb0] = 1000000000000000000;
        userLastUpdateTime[0xCB4CC352e1165fAC6935a18b619109e1F0943Fb0] = block.timestamp;
_balances[0xED453D5C7A9703175b28bBb41EffbB860bDEdA82] = 1000000000000000000;
        userLastUpdateTime[0xED453D5C7A9703175b28bBb41EffbB860bDEdA82] = block.timestamp;
_balances[0xCB4D43d13B8c1835639c84AC5b1f54502a731285] = 1000000000000000000;
        userLastUpdateTime[0xCB4D43d13B8c1835639c84AC5b1f54502a731285] = block.timestamp;
_balances[0xF42E4E235002ff9d56E3b221E21Fb5aD553Ded7B] = 1000000000000000000;
        userLastUpdateTime[0xF42E4E235002ff9d56E3b221E21Fb5aD553Ded7B] = block.timestamp;
_balances[0xB34CA4E1D37Bd1AE1663E5aEa3b295adB858A7e3] = 1000000000000000000;
        userLastUpdateTime[0xB34CA4E1D37Bd1AE1663E5aEa3b295adB858A7e3] = block.timestamp;
_balances[0xF8DEe5549496B329041207913352B3e31Dcc035B] = 1000000000000000000;
        userLastUpdateTime[0xF8DEe5549496B329041207913352B3e31Dcc035B] = block.timestamp;
_balances[0xcBB7B5fcA7B2Db9958F681857b23AAb878bA2ccA] = 1000000000000000000;
        userLastUpdateTime[0xcBB7B5fcA7B2Db9958F681857b23AAb878bA2ccA] = block.timestamp;
_balances[0xE4E076Ec8C75AFea19A8AE686104D3a819Ce8bd5] = 1000000000000000000;
        userLastUpdateTime[0xE4E076Ec8C75AFea19A8AE686104D3a819Ce8bd5] = block.timestamp;
_balances[0xcBCF8d9D3819ad9c3868Fe876451C04FA47124D6] = 1000000000000000000;
        userLastUpdateTime[0xcBCF8d9D3819ad9c3868Fe876451C04FA47124D6] = block.timestamp;
_balances[0xE5f9722bf74eF1aBe32C645b501ccB4719aBe10C] = 1000000000000000000;
        userLastUpdateTime[0xE5f9722bf74eF1aBe32C645b501ccB4719aBe10C] = block.timestamp;
_balances[0xCBEDA136b27939256907B07922c6e83F07b94802] = 1000000000000000000;
        userLastUpdateTime[0xCBEDA136b27939256907B07922c6e83F07b94802] = block.timestamp;
_balances[0xe819D78c8AE7Eb2c3BEBBED6CaCB6f91D6221735] = 1000000000000000000;
        userLastUpdateTime[0xe819D78c8AE7Eb2c3BEBBED6CaCB6f91D6221735] = block.timestamp;
_balances[0xaee9b7040C9E8d1589385BD9e035Dd5D51f2d606] = 1000000000000000000;
        userLastUpdateTime[0xaee9b7040C9E8d1589385BD9e035Dd5D51f2d606] = block.timestamp;
_balances[0xC23C131474F297445C80E01a82d2C26710e1eE04] = 1000000000000000000;
        userLastUpdateTime[0xC23C131474F297445C80E01a82d2C26710e1eE04] = block.timestamp;
_balances[0xCd5A7Aa5F610f420EEC0A069bF245B394C5C4626] = 1000000000000000000;
        userLastUpdateTime[0xCd5A7Aa5F610f420EEC0A069bF245B394C5C4626] = block.timestamp;
_balances[0xc402DA6d3448Cfbfc936E50D7767F665D457C1aE] = 1000000000000000000;
        userLastUpdateTime[0xc402DA6d3448Cfbfc936E50D7767F665D457C1aE] = block.timestamp;
_balances[0xcd839C3ACC7Fe116883bA5BD9A2A26Ac5A573322] = 1000000000000000000;
        userLastUpdateTime[0xcd839C3ACC7Fe116883bA5BD9A2A26Ac5A573322] = block.timestamp;
_balances[0xEfFF0D15D756fe449b152D85F720AE6652662fd0] = 1000000000000000000;
        userLastUpdateTime[0xEfFF0D15D756fe449b152D85F720AE6652662fd0] = block.timestamp;
_balances[0xcdC313bD8dd163140a3c5C48948f470f66A03ee0] = 1000000000000000000;
        userLastUpdateTime[0xcdC313bD8dd163140a3c5C48948f470f66A03ee0] = block.timestamp;
_balances[0xf3B1aE06392b7c0Be9745727489DA8349B504b99] = 1000000000000000000;
        userLastUpdateTime[0xf3B1aE06392b7c0Be9745727489DA8349B504b99] = block.timestamp;
_balances[0xCe4378D3b0e61077c84E00D2bb47F8127BcDbD96] = 1000000000000000000;
        userLastUpdateTime[0xCe4378D3b0e61077c84E00D2bb47F8127BcDbD96] = block.timestamp;
_balances[0xf4b45f7cc32C63B896A39884e3Ec160753A1D33F] = 1000000000000000000;
        userLastUpdateTime[0xf4b45f7cc32C63B896A39884e3Ec160753A1D33F] = block.timestamp;
_balances[0xceD3420927c3Febe1d7dcC7374f236d7c9eBC03E] = 1000000000000000000;
        userLastUpdateTime[0xceD3420927c3Febe1d7dcC7374f236d7c9eBC03E] = block.timestamp;
_balances[0xf759A860386649C3Ee92F598B8c6C82c3222eB8e] = 1000000000000000000;
        userLastUpdateTime[0xf759A860386649C3Ee92F598B8c6C82c3222eB8e] = block.timestamp;
_balances[0xcf5C931B8F98C12E3a911A6Ce25f6312b19c0d52] = 1000000000000000000;
        userLastUpdateTime[0xcf5C931B8F98C12E3a911A6Ce25f6312b19c0d52] = block.timestamp;
_balances[0xfB011a6A7F7Acf29878BE12de6D93f928EF68f81] = 1000000000000000000;
        userLastUpdateTime[0xfB011a6A7F7Acf29878BE12de6D93f928EF68f81] = block.timestamp;
_balances[0xCFa1b76bA955C76B1e015743ab8F301aC13315fE] = 1000000000000000000;
        userLastUpdateTime[0xCFa1b76bA955C76B1e015743ab8F301aC13315fE] = block.timestamp;
_balances[0xbDc6fef7Da102bFc1316FB10dA9Eb4F7D057375e] = 1000000000000000000;
        userLastUpdateTime[0xbDc6fef7Da102bFc1316FB10dA9Eb4F7D057375e] = block.timestamp;
_balances[0xb45547f45865C4bba3B6C6494Ec9191D611D549D] = 1000000000000000000;
        userLastUpdateTime[0xb45547f45865C4bba3B6C6494Ec9191D611D549D] = block.timestamp;
_balances[0xBEd0F8b7916C3b0a49457aEb3E83866f8FF0396c] = 1000000000000000000;
        userLastUpdateTime[0xBEd0F8b7916C3b0a49457aEb3E83866f8FF0396c] = block.timestamp;
_balances[0xd09460ae7BC9F5CFAB9065c306E04A0631Bc4daB] = 1000000000000000000;
        userLastUpdateTime[0xd09460ae7BC9F5CFAB9065c306E04A0631Bc4daB] = block.timestamp;
_balances[0xbf4936C0c19A3FCE25751Dcf4731A1C34a1Dc8bf] = 1000000000000000000;
        userLastUpdateTime[0xbf4936C0c19A3FCE25751Dcf4731A1C34a1Dc8bf] = block.timestamp;
_balances[0xd0a837591f6EB0b9549e8246534CE3c7b13a97E1] = 1000000000000000000;
        userLastUpdateTime[0xd0a837591f6EB0b9549e8246534CE3c7b13a97E1] = block.timestamp;
_balances[0xe6FE74f3014b101113eb67AC3393C62eFf87DC41] = 1000000000000000000;
        userLastUpdateTime[0xe6FE74f3014b101113eb67AC3393C62eFf87DC41] = block.timestamp;
_balances[0xB4a74798Abfe8f9500c5471B6B1C6c7536794DA9] = 1000000000000000000;
        userLastUpdateTime[0xB4a74798Abfe8f9500c5471B6B1C6c7536794DA9] = block.timestamp;
_balances[0xe7EfDf10a4413b833C1A8B1B3479837029450cee] = 1000000000000000000;
        userLastUpdateTime[0xe7EfDf10a4413b833C1A8B1B3479837029450cee] = block.timestamp;
_balances[0xd15fAA3b678EeF600E268e5c394E32c53813a55e] = 1000000000000000000;
        userLastUpdateTime[0xd15fAA3b678EeF600E268e5c394E32c53813a55e] = block.timestamp;
_balances[0xe93A1D96dB1ea72eab4A89896d42B98a15F3e31d] = 1000000000000000000;
        userLastUpdateTime[0xe93A1D96dB1ea72eab4A89896d42B98a15F3e31d] = block.timestamp;
_balances[0xD1862137A8d37CFe560c061f413C05737e979E42] = 1000000000000000000;
        userLastUpdateTime[0xD1862137A8d37CFe560c061f413C05737e979E42] = block.timestamp;
_balances[0xEa24214bd787D9c1ad68A183e3E42ec4Ba359bdD] = 1000000000000000000;
        userLastUpdateTime[0xEa24214bd787D9c1ad68A183e3E42ec4Ba359bdD] = block.timestamp;
_balances[0xb4a7eAADF1dBFcd5c51B544916e011068E948B4F] = 1000000000000000000;
        userLastUpdateTime[0xb4a7eAADF1dBFcd5c51B544916e011068E948B4F] = block.timestamp;
_balances[0xC2E9b88f2015A3a1C1f58cfcbDDa94b84d16Cdb6] = 1000000000000000000;
        userLastUpdateTime[0xC2E9b88f2015A3a1C1f58cfcbDDa94b84d16Cdb6] = block.timestamp;
_balances[0xB5905960c0224d9333fC58eb60E2B57423b18d99] = 1000000000000000000;
        userLastUpdateTime[0xB5905960c0224d9333fC58eb60E2B57423b18d99] = block.timestamp;
_balances[0xC331e33B500788997B314b6645DB0E3090a0D1F8] = 1000000000000000000;
        userLastUpdateTime[0xC331e33B500788997B314b6645DB0E3090a0D1F8] = block.timestamp;
_balances[0xd29fCdB06c603C646c22b1630403D06536e707C8] = 1000000000000000000;
        userLastUpdateTime[0xd29fCdB06c603C646c22b1630403D06536e707C8] = block.timestamp;
_balances[0xB1D20112fea3BEF0694b6b1Cc93a6858a87fDf4e] = 1000000000000000000;
        userLastUpdateTime[0xB1D20112fea3BEF0694b6b1Cc93a6858a87fDf4e] = block.timestamp;
_balances[0xB5dcd02bC81d02Fe90d4f75E808ed805CCdbfBA3] = 1000000000000000000;
        userLastUpdateTime[0xB5dcd02bC81d02Fe90d4f75E808ed805CCdbfBA3] = block.timestamp;
_balances[0xEE83722B5e5a8B5f415353a40a8866Cc028078C9] = 1000000000000000000;
        userLastUpdateTime[0xEE83722B5e5a8B5f415353a40a8866Cc028078C9] = block.timestamp;
_balances[0xd2eA729970c85ABe1a83AC5627740aBEc17Ef16D] = 1000000000000000000;
        userLastUpdateTime[0xd2eA729970c85ABe1a83AC5627740aBEc17Ef16D] = block.timestamp;
_balances[0xF0a1A867eB17F9b859BD0799DA54f1092a1819e0] = 1000000000000000000;
        userLastUpdateTime[0xF0a1A867eB17F9b859BD0799DA54f1092a1819e0] = block.timestamp;
_balances[0xb622007d605e71294469536ad334Fc7DFD6C0bb0] = 1000000000000000000;
        userLastUpdateTime[0xb622007d605e71294469536ad334Fc7DFD6C0bb0] = block.timestamp;
_balances[0xf34F6DC279c7b6d3E235830078c78186885392FD] = 1000000000000000000;
        userLastUpdateTime[0xf34F6DC279c7b6d3E235830078c78186885392FD] = block.timestamp;
_balances[0xD34d390Dde6fC8F3cF8A3D5d7DCC077F403a9f0D] = 1000000000000000000;
        userLastUpdateTime[0xD34d390Dde6fC8F3cF8A3D5d7DCC077F403a9f0D] = block.timestamp;
_balances[0xf40BDB3596bAa36eB9885D8d6aF5b556Ab658180] = 1000000000000000000;
        userLastUpdateTime[0xf40BDB3596bAa36eB9885D8d6aF5b556Ab658180] = block.timestamp;
_balances[0xD37780329f8174ce58f70beC078f2fFEa9f8826C] = 1000000000000000000;
        userLastUpdateTime[0xD37780329f8174ce58f70beC078f2fFEa9f8826C] = block.timestamp;
_balances[0xc7e243702c5d6BAc0183d6175AD992F827B5d1f5] = 1000000000000000000;
        userLastUpdateTime[0xc7e243702c5d6BAc0183d6175AD992F827B5d1f5] = block.timestamp;
_balances[0xD3B0aCC19B4483CE47e1Bd3E2A2113335Ed63929] = 1000000000000000000;
        userLastUpdateTime[0xD3B0aCC19B4483CE47e1Bd3E2A2113335Ed63929] = block.timestamp;
_balances[0xF53C825E33C9C0C3D04025a1816999903C77e0A9] = 1000000000000000000;
        userLastUpdateTime[0xF53C825E33C9C0C3D04025a1816999903C77e0A9] = block.timestamp;
_balances[0xABA5509bDcAF5D7B97d65a3Bc9aA5261a14119b1] = 1000000000000000000;
        userLastUpdateTime[0xABA5509bDcAF5D7B97d65a3Bc9aA5261a14119b1] = block.timestamp;
_balances[0xf67aB8E5093C7DdBE65C796dfdCCf1B5014310f7] = 1000000000000000000;
        userLastUpdateTime[0xf67aB8E5093C7DdBE65C796dfdCCf1B5014310f7] = block.timestamp;
_balances[0xAEF8A68196bd0Ed27761dC2271f907e1C4F53E88] = 1000000000000000000;
        userLastUpdateTime[0xAEF8A68196bd0Ed27761dC2271f907e1C4F53E88] = block.timestamp;
_balances[0xF810EF4979B4813f47A1F1aFe8ea1811F7ef1117] = 1000000000000000000;
        userLastUpdateTime[0xF810EF4979B4813f47A1F1aFe8ea1811F7ef1117] = block.timestamp;
_balances[0xd5d1c5daF1Ef2807b4033c169eCc0F7e1CbCdFf9] = 1000000000000000000;
        userLastUpdateTime[0xd5d1c5daF1Ef2807b4033c169eCc0F7e1CbCdFf9] = block.timestamp;
_balances[0xfa6c1486468F2D0DbD119cFB48eE6Ecd0439c122] = 1000000000000000000;
        userLastUpdateTime[0xfa6c1486468F2D0DbD119cFB48eE6Ecd0439c122] = block.timestamp;
_balances[0xAd595AFC4767c8Cbf6e2361044bEF474F973d420] = 1000000000000000000;
        userLastUpdateTime[0xAd595AFC4767c8Cbf6e2361044bEF474F973d420] = block.timestamp;
_balances[0xfb7Ba88222958F4d9377c92D6fB179157ac0B0b8] = 1000000000000000000;
        userLastUpdateTime[0xfb7Ba88222958F4d9377c92D6fB179157ac0B0b8] = block.timestamp;
_balances[0xD5FCd14F89569A80882faFbe194e9E82dDb24099] = 1000000000000000000;
        userLastUpdateTime[0xD5FCd14F89569A80882faFbe194e9E82dDb24099] = block.timestamp;
_balances[0xC8bA1511e1Eb443460203c2980eC307bD1DD24a6] = 1000000000000000000;
        userLastUpdateTime[0xC8bA1511e1Eb443460203c2980eC307bD1DD24a6] = block.timestamp;
_balances[0xd5FfcabF2bA93b4C30698b0398dfbf1af3163A61] = 1000000000000000000;
        userLastUpdateTime[0xd5FfcabF2bA93b4C30698b0398dfbf1af3163A61] = block.timestamp;
_balances[0xbdEAe4E937cE2c16D29d79238DC6ed1538A38017] = 1000000000000000000;
        userLastUpdateTime[0xbdEAe4E937cE2c16D29d79238DC6ed1538A38017] = block.timestamp;
_balances[0xD60f0939Fc21b52570fB5921E3621FD5940fa794] = 1000000000000000000;
        userLastUpdateTime[0xD60f0939Fc21b52570fB5921E3621FD5940fa794] = block.timestamp;
_balances[0xE4e5adA234773De8E61Bda8c1D1DEbba800A5462] = 1000000000000000000;
        userLastUpdateTime[0xE4e5adA234773De8E61Bda8c1D1DEbba800A5462] = block.timestamp;
_balances[0xd68FFB64c59Ce599345e41B8DD04Fe3A30727724] = 1000000000000000000;
        userLastUpdateTime[0xd68FFB64c59Ce599345e41B8DD04Fe3A30727724] = block.timestamp;
_balances[0xbf3356C71A7ad67Dc405E7BBb6e8C6203b952163] = 1000000000000000000;
        userLastUpdateTime[0xbf3356C71A7ad67Dc405E7BBb6e8C6203b952163] = block.timestamp;
_balances[0xD6d2Fcc947e62B21CedbeD336893A2Ba47cd8dac] = 1000000000000000000;
        userLastUpdateTime[0xD6d2Fcc947e62B21CedbeD336893A2Ba47cd8dac] = block.timestamp;
_balances[0xE50eb8F24ACa74f8F61515DfaE5Adca4ECCb9926] = 1000000000000000000;
        userLastUpdateTime[0xE50eb8F24ACa74f8F61515DfaE5Adca4ECCb9926] = block.timestamp;
_balances[0xFde08538aF13608E87d7A1Bf62D52cf18F52Ab6E] = 1000000000000000000;
        userLastUpdateTime[0xFde08538aF13608E87d7A1Bf62D52cf18F52Ab6E] = block.timestamp;
_balances[0xB012140bC6Bf3B260273EAD7E8C5E50658e3b0f5] = 1000000000000000000;
        userLastUpdateTime[0xB012140bC6Bf3B260273EAD7E8C5E50658e3b0f5] = block.timestamp;
_balances[0xB79bFeDcc95eF943a45f11FDF1D20fF879076519] = 1000000000000000000;
        userLastUpdateTime[0xB79bFeDcc95eF943a45f11FDF1D20fF879076519] = block.timestamp;
_balances[0xE6d29A790e8fbc1e291e221B5720AC6D19F7649D] = 1000000000000000000;
        userLastUpdateTime[0xE6d29A790e8fbc1e291e221B5720AC6D19F7649D] = block.timestamp;
_balances[0xb7f1aB82Ad8CFABF05d0f33921459e5e29eA4262] = 1000000000000000000;
        userLastUpdateTime[0xb7f1aB82Ad8CFABF05d0f33921459e5e29eA4262] = block.timestamp;
_balances[0xb08aD4E641d8A47353631C8BFa1672B4c37DB300] = 1000000000000000000;
        userLastUpdateTime[0xb08aD4E641d8A47353631C8BFa1672B4c37DB300] = block.timestamp;
_balances[0xFfa5cAD50Acca980bC28091867Fe3E59e9964fCc] = 1000000000000000000;
        userLastUpdateTime[0xFfa5cAD50Acca980bC28091867Fe3E59e9964fCc] = block.timestamp;
_balances[0xc105B1478BD8D2a5Aa21031737dd2f6C2b1f22De] = 1000000000000000000;
        userLastUpdateTime[0xc105B1478BD8D2a5Aa21031737dd2f6C2b1f22De] = block.timestamp;
_balances[0xb8b10231291584011964B349aA49d2657fe8707d] = 1000000000000000000;
        userLastUpdateTime[0xb8b10231291584011964B349aA49d2657fe8707d] = block.timestamp;
_balances[0xC13849e0D791028b313944545F5740D9993113c2] = 1000000000000000000;
        userLastUpdateTime[0xC13849e0D791028b313944545F5740D9993113c2] = block.timestamp;
_balances[0xaF227300a7a93b9806F7D434829FFee99680a4F1] = 1000000000000000000;
        userLastUpdateTime[0xaF227300a7a93b9806F7D434829FFee99680a4F1] = block.timestamp;
_balances[0xe8A58731a05F1Db50fe74508Df3c41E767Deb337] = 1000000000000000000;
        userLastUpdateTime[0xe8A58731a05F1Db50fe74508Df3c41E767Deb337] = block.timestamp;
_balances[0xb95350a45B0C1D4c24d3D02637378DB437a2bfca] = 1000000000000000000;
        userLastUpdateTime[0xb95350a45B0C1D4c24d3D02637378DB437a2bfca] = block.timestamp;
_balances[0xE9b29c6aa376C54060081063c22cf08a2bdBeD4d] = 1000000000000000000;
        userLastUpdateTime[0xE9b29c6aa376C54060081063c22cf08a2bdBeD4d] = block.timestamp;
_balances[0xd8e611961E49c21592f58DeFe9272e81E0880fF0] = 1000000000000000000;
        userLastUpdateTime[0xd8e611961E49c21592f58DeFe9272e81E0880fF0] = block.timestamp;
_balances[0xea06264f9324c417d633a867B62D5f03e1346418] = 1000000000000000000;
        userLastUpdateTime[0xea06264f9324c417d633a867B62D5f03e1346418] = block.timestamp;
_balances[0xD8Ee44e9694AdC402257574c3E9bea10Bd2cad34] = 1000000000000000000;
        userLastUpdateTime[0xD8Ee44e9694AdC402257574c3E9bea10Bd2cad34] = block.timestamp;
_balances[0xea2f7b134f1f2ba9beEfDb86b1377D59101eD92F] = 1000000000000000000;
        userLastUpdateTime[0xea2f7b134f1f2ba9beEfDb86b1377D59101eD92F] = block.timestamp;
_balances[0xb973eEc0b1795F4cf7032FE13822c7ceEEa39F4C] = 1000000000000000000;
        userLastUpdateTime[0xb973eEc0b1795F4cf7032FE13822c7ceEEa39F4C] = block.timestamp;
_balances[0xB179787fd0BE17B84A583b034679BC3261CbD6B3] = 1000000000000000000;
        userLastUpdateTime[0xB179787fd0BE17B84A583b034679BC3261CbD6B3] = block.timestamp;
_balances[0xAF48BBd95e49B8F023f72c96A6B662E808C9f8bf] = 1000000000000000000;
        userLastUpdateTime[0xAF48BBd95e49B8F023f72c96A6B662E808C9f8bf] = block.timestamp;
_balances[0xc32fe77b640E5Efc2A9F82a8628f8CfEfD364BA8] = 1000000000000000000;
        userLastUpdateTime[0xc32fe77b640E5Efc2A9F82a8628f8CfEfD364BA8] = block.timestamp;
_balances[0xaF88a198559D08B5932a5dF63b6Be42bE8f96eE1] = 1000000000000000000;
        userLastUpdateTime[0xaF88a198559D08B5932a5dF63b6Be42bE8f96eE1] = block.timestamp;
_balances[0xeB1f372c45ebbB2A3d08BF0A5844509045F3E338] = 1000000000000000000;
        userLastUpdateTime[0xeB1f372c45ebbB2A3d08BF0A5844509045F3E338] = block.timestamp;
_balances[0xd9774232a4EDc5B39EEF6573688836bFCD85540C] = 1000000000000000000;
        userLastUpdateTime[0xd9774232a4EDc5B39EEF6573688836bFCD85540C] = block.timestamp;
_balances[0xEB6d919f8421783053c0944498A434E75d20653D] = 1000000000000000000;
        userLastUpdateTime[0xEB6d919f8421783053c0944498A434E75d20653D] = block.timestamp;
_balances[0xbA304A224404F3238eB9c3Ecf07090dFf117B544] = 1000000000000000000;
        userLastUpdateTime[0xbA304A224404F3238eB9c3Ecf07090dFf117B544] = block.timestamp;
_balances[0xC4c2BCC816428d141889b8e5D31ba8954dF1A687] = 1000000000000000000;
        userLastUpdateTime[0xC4c2BCC816428d141889b8e5D31ba8954dF1A687] = block.timestamp;
_balances[0xDa1a6aF84084eabF1275baB59E9c0512DF882388] = 1000000000000000000;
        userLastUpdateTime[0xDa1a6aF84084eabF1275baB59E9c0512DF882388] = block.timestamp;
_balances[0xeCd3C1b558a31D4533F476020200B5CA4EC64A83] = 1000000000000000000;
        userLastUpdateTime[0xeCd3C1b558a31D4533F476020200B5CA4EC64A83] = block.timestamp;
_balances[0xdAb7dB966aaE25A22f66404202803e553097DD76] = 1000000000000000000;
        userLastUpdateTime[0xdAb7dB966aaE25A22f66404202803e553097DD76] = block.timestamp;
_balances[0xEe74230003Ea3D5F241d51Cc6De1C820CEe1108B] = 1000000000000000000;
        userLastUpdateTime[0xEe74230003Ea3D5F241d51Cc6De1C820CEe1108B] = block.timestamp;



        lastUpdateTime = block.timestamp;
        _totalSupply = 117200000000000000000000;


        _pause();
    }

    function startClaimablePeriod(uint256 _claimDuration) external onlyOwner whenPaused {
        require(_claimDuration > 0, "Claim duration should be greater than 0");

        claimDuration = _claimDuration;
        claimStartTime = block.timestamp;

        _unpause();

        emit ClaimStart(_claimDuration, claimStartTime);
    }

    function pauseClaimablePeriod() external onlyOwner {
        _pause();
    }




    function claimLegendTokens(uint[] calldata _tokenIds) external whenNotPaused {
        require(block.timestamp >= claimStartTime && block.timestamp < claimStartTime + claimDuration, "Claimable period is finished");
        require((alpha.balanceOf(msg.sender) > 0), "Nothing to claim");
        require((beta.balanceOf(msg.sender) > 0), "Nothing to claim");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(beta.ownerOf(_tokenIds[i]) == msg.sender, "NOT_LL_OWNER");
        }

        uint256 tokensToClaim;
        uint256 gammaToBeClaim;

        (tokensToClaim, gammaToBeClaim) = ((_tokenIds.length * BETA_DISTRIBUTION_AMOUNT),0);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(!betaClaimed[_tokenIds[i]] ) {
                betaClaimed[_tokenIds[i]] = true;
                emit BetaClaimed(_tokenIds[i], msg.sender, block.timestamp);
            }
        }



        metalToken.safeTransfer(msg.sender, tokensToClaim);

        totalClaimed += tokensToClaim;
        emit AirDrop(msg.sender, tokensToClaim, block.timestamp);
    }

    function claimLegendTokensAsStake(uint[] calldata _tokenIds) external whenNotPaused {
        require(block.timestamp >= claimStartTime && block.timestamp < claimStartTime + claimDuration, "Claimable period is finished");
        require((alpha.balanceOf(msg.sender) > 0), "Nothing to claim");
        require((beta.balanceOf(msg.sender) > 0), "Nothing to claim");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(beta.ownerOf(_tokenIds[i]) == msg.sender, "NOT_LL_OWNER");
        }

        uint256 tokensToClaim;
        uint256 gammaToBeClaim;

        (tokensToClaim, gammaToBeClaim) = ((_tokenIds.length * BETA_DISTRIBUTION_AMOUNT),0);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(!betaClaimed[_tokenIds[i]] ) {
                betaClaimed[_tokenIds[i]] = true;
                emit BetaClaimed(_tokenIds[i], msg.sender, block.timestamp);
            }
        }

        _totalSupply += tokensToClaim;
         _balances[msg.sender] += tokensToClaim;

        totalClaimed += tokensToClaim;
        emit AirDrop(msg.sender, tokensToClaim, block.timestamp);
    }




    function min(uint256 a, uint256 b) private pure returns(uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    // function claimUnclaimedTokens() external onlyOwner {
    //     require(block.timestamp > claimStartTime + claimDuration, "Claimable period is not finished yet");
    //     metalToken.safeTransfer(owner(), metalToken.balanceOf(address(this)));

    //     uint256 balance = address(this).balance;
    //     if (balance > 0) {
    //         Address.sendValue(payable(owner()), balance);
    //     }
    // }

    function toggleLiquidLegendsStatus() external onlyOwner {
        liquidLegendMintOver = !liquidLegendMintOver;
    }


    /**
        start of metal staking portion
    **/
    function rewardPerToken(uint256 userTime) public view returns (uint) {
        
        if (_totalSupply == 0) {
            return 0;
        }
        return
            ((block.timestamp - userTime) * rewardRate ) ;
    }

    function earned(address account) public view returns (uint) {
        return
            (_balances[account] *
                (rewardPerToken(userLastUpdateTime[account]))/ 1e18 )  +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewards[account] = earned(account);
        _totalRewards += earned(account);
        userLastUpdateTime[account] = block.timestamp;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function stakeOnBehalf(uint _amount,address account ) external updateReward(account) {
        _totalSupply += _amount;
        _balances[account] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }


    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount <= _balances[msg.sender], "withdraw amount over stake");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }

    function getRewardAsStake() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
         _balances[msg.sender] += reward;
    }


     function changerewardRate(uint256 newRewardRate) external onlyOwner {
        rewardRate = newRewardRate;
    }

        // this total supply is staked not held by contract
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

        //emergency owner withdrawal function.
    function withdrawAllTokens() external onlyOwner {
        uint256 tokenSupply = rewardsToken.balanceOf(address(this));
        rewardsToken.transfer(msg.sender, tokenSupply);
    }
        //normal owner withdrawl function
    function withdrawSomeTokens(uint _amount) external onlyOwner {
        rewardsToken.transfer(msg.sender, _amount);
    }

}