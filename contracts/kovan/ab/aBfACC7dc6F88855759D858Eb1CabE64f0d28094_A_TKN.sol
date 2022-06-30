/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier:  UNLICENSED

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

// File: contracts/Imports/token/ERC721/IERC721.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/IERC721Receiver.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/extensions/IERC721Metadata.sol

//  MIT

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

// File: contracts/Imports/utils/Address.sol

//  MIT

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

// File: contracts/Imports/utils/Context.sol

//  MIT

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

// File: contracts/Imports/utils/Strings.sol

//  MIT

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

// File: contracts/Imports/utils/introspection/ERC165.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/ERC721.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/extensions/IERC721Enumerable.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/extensions/ERC721Enumerable.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/extensions/ERC721Burnable.sol

//  MIT

pragma solidity ^0.8.0;


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// File: contracts/Imports/security/Pausable.sol

//  MIT

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

// File: contracts/Imports/token/ERC721/extensions/ERC721Pausable.sol

//  MIT

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// File: contracts/Imports/token/ERC721/extensions/ERC721URIStorage.sol

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: contracts/Imports/access/IAccessControl.sol

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
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

// File: contracts/Imports/access/IAccessControlEnumerable.sol

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: contracts/Imports/access/AccessControl.sol

//  MIT

pragma solidity ^0.8.0;




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
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

// File: contracts/Imports/utils/structs/EnumerableSet.sol

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/Imports/access/AccessControlEnumerable.sol

//  MIT

pragma solidity ^0.8.0;



/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// File: contracts/Imports/utils/Counters.sol

//  MIT

pragma solidity ^0.8.0;

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

// File: contracts/Imports/security/ReentrancyGuard.sol

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Resources/RESOURCE_PRUF_STRUCTS.sol

/*--------------------------------------------------------PRüF0.8.7
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\__/\\ ___/\\\\\\\\\\\\\\\        
__\/\\\/////////\\\ _/\\\///////\\\ ____\//__\//____\/\\\///////////__       
___\/\\\_______\/\\\_\/\\\_____\/\\\ ________________\/\\\ ____________      
____\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\_\/\\\\\\\\\\\ ____     
_____\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\_\/\\\///////______
______\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\_\/\\\ ____________
_______\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\_\/\\\ ____________
________\/\\\ ____________\/\\\ _____\//\\\_\//\\\\\\\\\ _\/\\\ ____________
_________\/// _____________\/// _______\/// __\///////// __\/// _____________
*---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 *  TO DO
 *
 *---------------------------------------------------------------*/

//  UNLICENSED
pragma solidity ^0.8.7;

struct Record {
    uint8 assetStatus; // Status - Transferrable, locked, in transfer, stolen, lost, etc.
    uint8 modCount; // Number of times asset has been forceModded.
    uint16 numberOfTransfers; //number of transfers and forcemods
    uint32 node; // Type of asset
    uint32 countDown; // Variable that can only be decreased from countDownStart
    uint32 int32temp; // int32 for persisting transitional data
    //128 bits left in this packing)
    bytes32 URIhash; //hash of off chain content adressable storage ; unuiqe element of URI
    bytes32 mutableStorage1; // Publically viewable asset description
    bytes32 nonMutableStorage1; // Publically viewable immutable notes
    bytes32 mutableStorage2; // Publically viewable asset description
    bytes32 nonMutableStorage2; // Publically viewable immutable notes
    bytes32 rightsHolder; // KEK256 Registered owner
}

//     proposed ISO standardized
//     struct Record {
//     uint8 assetStatus; // Status - Transferrable, locked, in transfer, stolen, lost, etc.
//     uint32 node; // Type of asset
//     uint32 countDown; // Variable that can only be decreased from countDownStart
//     uint32 int32temp; // int32 for persisting transitional data
//     bytes32 mutableStorage1; // Publically viewable asset description
//     bytes32 nonMutableStorage1; // Publically viewable immutable notes
//     bytes32 mutableStorage2; // Publically viewable asset description
//     bytes32 nonMutableStorage2; // Publically viewable immutable notes
//     bytes32 rightsHolder; // KEK256  owner
// }

struct Node {
    //Struct for holding and manipulating node data
    uint8 custodyType; // custodial or noncustodial, special asset types       //immutable
    uint8 managementType; // type of management for asset creation, import, export //immutable
    uint8 storageProvider; // Storage Provider
    uint8 switches; // bitwise Flags for node control                          //immutable
    uint32 nodeRoot; // asset type root (bicyles - USA Bicycles)             //immutable
    uint32 discount; // price sharing //internal admin                                      //immutable
    address referenceAddress; // Used with wrap / decorate
    bytes32 CAS1; //content adressable storage pointer 1
    bytes32 CAS2; //content adressable storage pointer 1
    string name; // NameHash for node
}

struct ExtendedNodeData {
    uint8 u8a;
    uint8 u8b;
    uint16 u16c;
    uint32 u32d;
    uint32 u32e;
    address idProviderAddr;
    uint256 idProviderTokenId;
}

struct ContractDataHash {
    //Struct for holding and manipulating contract authorization data
    uint8 contractType; // Auth Level / type
    bytes32 nameHash; // Contract Name hashed
}

struct DefaultContract {
    //Struct for holding and manipulating contract authorization data
    uint8 contractType; // Auth Level / type
    string name; // Contract name
}

struct escrowData {
    bytes32 controllingContractNameHash; //hash of the name of the controlling escrow contract
    bytes32 escrowOwnerAddressHash; //hash of an address designated as an executor for the escrow contract
    uint256 timelock;
}

struct escrowDataExtLight {
    //used only in recycle
    //1 slot
    uint8 escrowData; //used by recycle
    uint8 u8_1;
    uint8 u8_2;
    uint8 u8_3;
    uint16 u16_1;
    uint16 u16_2;
    uint32 u32_1;
    address addr_1; //used by recycle
}

struct escrowDataExtHeavy {
    //specific uses not defined
    // 5 slots
    uint32 u32_2;
    uint32 u32_3;
    uint32 u32_4;
    address addr_2;
    bytes32 b32_1;
    bytes32 b32_2;
    string escrowStringData;
}

struct Costs {
    //make these require full epoch to change???
    uint256 serviceCost; // Cost in the given item category
    address paymentAddress; // 2nd-party fee beneficiary address
}

struct Invoice {
    //invoice struct to facilitate payment messaging in-contract
    //uint32 node;
    address rootAddress;
    address NTHaddress;
    uint256 rootPrice;
    uint256 NTHprice;
}

struct MarketFees {
    //data for PRUF_MARKET fees and commissions
    address listingFeePaymentAddress;
    address saleCommissionPaymentAddress;
    uint8 approval;
    uint256 listingFee;
    uint256 saleCommission;
}

// struct PRUFID {
//     //ID struct for ID info
//     uint256 trustLevel; //admin only
//     bytes32 IdHash;
// }

struct Stake {
    uint256 stakedAmount; //tokens in stake
    uint256 mintTime; //blocktime of creation
    uint256 startTime; //blocktime of creation or most recent payout
    uint256 interval; //staking interval in seconds
    uint256 bonusPercentage; // % per reward period, in tenths of a percent, assigned to this stake on creation
    uint256 maximum; // maximum tokens allowed to be held by this stake
}

struct ConsignmentTag {
    uint256 tokenId;
    address tokenContract;
    address currency;
    uint256 price;
    uint32 node;
}

struct Block {
    bytes32 block1;
    bytes32 block2;
    bytes32 block3;
    bytes32 block4;
    bytes32 block5;
    bytes32 block6;
    bytes32 block7;
    bytes32 block8;
}

// File: contracts/Resources/RESOURCE_PRUF_INTERFACES.sol

/*--------------------------------------------------------PRüF0.8.7
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\__/\\ ___/\\\\\\\\\\\\\\\        
__\/\\\/////////\\\ _/\\\///////\\\ ____\//__\//____\/\\\///////////__       
___\/\\\_______\/\\\_\/\\\_____\/\\\ ________________\/\\\ ____________      
____\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\_\/\\\\\\\\\\\ ____     
_____\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\_\/\\\///////______
______\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\_\/\\\ ____________
_______\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\_\/\\\ ____________
________\/\\\ ____________\/\\\ _____\//\\\_\//\\\\\\\\\ _\/\\\ ____________
_________\/// _____________\/// _______\/// __\///////// __\/// _____________
*---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 *  TO DO
 *
 *---------------------------------------------------------------*/

//  UNLICENSED
pragma solidity ^0.8.7;

//---------------------------------------------------------------------------------------------------------------
/*
 * @dev Interface for STOR
 * INHERITANCE:



 */
interface STOR_Interface {
    //--------------------------------Public Functions---------------------------------//

    /**
     * @dev Authorize / Deauthorize contract NAMES permitted to make record modifications, per node
     * allows NodeTokenHolder to Authorize / Deauthorize specific contracts to work within their node
     * @param   _name -  Name of contract being authed
     * @param   _node - affected node
     * @param   _contractAuthLevel - auth level to set for thae contract, in that node
     */
    function enableContractForNode(
        string memory _name,
        uint32 _node,
        uint8 _contractAuthLevel
    ) external;

    //--------------------------------External Functions---------------------------------//

    /**
     * @dev Triggers stopped state. (pausable)
     */
    function pause() external;

    /**
     * @dev Returns to normal state. (pausable)
     */
    function unpause() external;

    /**
     * @dev Authorize / Deauthorize ADRESSES permitted to make record modifications, per node
     * populates contract name resolution and data mappings
     * @param _contractName - String name of contract
     * @param _contractAddr - address of contract
     * @param _node - node to authorize in
     * @param _contractAuthLevel - auth level to assign
     */
    function authorizeContract(
        string calldata _contractName,
        address _contractAddr,
        uint32 _node,
        uint8 _contractAuthLevel
    ) external;

    /**
     * @dev set the default list of 11 contracts (zero index) to be applied to Noees
     * @param _contractNumber - 0-10
     * @param _name - name
     * @param _contractAuthLevel - authLevel
     */
    function addDefaultContracts(
        uint256 _contractNumber,
        string calldata _name,
        uint8 _contractAuthLevel
    ) external;

    /**
     * @dev retrieve a record from the default list of 11 contracts to be applied to Nodees
     * @param _contractNumber to look up (0-10)
     * @return the name and auth level of indexed contract
     */
    function getDefaultContract(uint256 _contractNumber)
        external
        view
        returns (DefaultContract memory);

    /**
     * @dev Set the default 11 authorized contracts
     * @param _node the Node which will be enabled for the default contracts
     */
    function enableDefaultContractsForNode(uint32 _node) external;

    /**
     * @dev Make a new record, writing to the 'database' mapping with basic initial asset data
     * calling contract must be authorized in relevant node
     * @param   _idxHash - asset ID
     * @param   _rgtHash - rightsholder id hash
     * @param _URIhash - hash of URI Suffix
     * @param   _node - node in which to create the asset
     * @param   _countDownStart - initial value for decrement-only value
     */
    function newRecord(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        bytes32 _URIhash,
        uint32 _node,
        uint32 _countDownStart
    ) external;

    /**
     * @dev Modify a record, writing to the 'database' mapping with updates to multiple fields
     * @param _idxHash - record asset ID
     * @param _rgtHash - record owner ID hash
     * @param _newAssetStatus - New Status to set
     * @param _countDown - New countdown value (must be <= old value)
     * @param _int32temp - temp value
     * @param _incrementModCount - 0 = no 170 = yes
     * @param _incrementNumberOfTransfers - 0 = no 170 = yes
     */
    function modifyRecord(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint8 _newAssetStatus,
        uint32 _countDown,
        uint32 _int32temp,
        uint256 _incrementModCount,
        uint256 _incrementNumberOfTransfers
    ) external;

    /**
     * @dev Change node of an asset - writes to node in the 'Record' struct of the 'database' at _idxHash
     * @param _idxHash - record asset ID
     * @param _newNode - Aseet Class to change to
     */
    function changeNode(bytes32 _idxHash, uint32 _newNode) external;

    /**
     * @dev Set an asset to Lost Or Stolen. Allows narrow modification of status 6/12 assets, normally locked
     * @param _idxHash - record asset ID
     * @param _newAssetStatus - Status to change to
     */
    function setLostOrStolen(bytes32 _idxHash, uint8 _newAssetStatus) external;

    /**
     * @dev Set an asset to escrow locked status (6/50/56).
     * @param _idxHash - record asset ID
     * @param _newAssetStatus - New Status to set
     */
    function setEscrow(bytes32 _idxHash, uint8 _newAssetStatus) external;

    /**
     * @dev remove an asset from escrow status. Implicitly trusts escrowManager ECR_MGR contract
     * @param _idxHash - record asset ID
     */
    function endEscrow(bytes32 _idxHash) external;

    /**
     * @dev Modify record MutableStorage data
     * @param  _idxHash - record asset ID
     * @param  _mutableStorage1 - first half of content adressable storage location
     * @param  _mutableStorage2 - second half of content adressable storage location
     */
    function modifyMutableStorage(
        bytes32 _idxHash,
        bytes32 _mutableStorage1,
        bytes32 _mutableStorage2
    ) external;

    /**
     * @dev Modify NonMutableStorage data
     * @param _idxHash - record asset ID
     * @param _nonMutableStorage1 - first half of content addressable storage location
     * @param _nonMutableStorage2 - second half of content addressable storage location
     */
    function setNonMutableStorage(
        bytes32 _idxHash,
        bytes32 _nonMutableStorage1,
        bytes32 _nonMutableStorage2
    ) external;

    /**
     * @dev return a record from the database
     * @param  _idxHash - record asset ID
     * returns a complete Record struct (see interfaces for struct definitions)
     */
    function retrieveRecord(bytes32 _idxHash)
        external
        view
        returns (Record memory);

    /**
     * @dev return a record from the database w/o rgt
     * @param _idxHash - record asset ID
     * @return rec.assetStatus,
                rec.modCount,
                rec.node,
                rec.countDown,
                rec.countDownStart,
                rec.mutableStorage1,
                rec.mutableStorage2,
                rec.nonMutableStorage1,
                rec.nonMutableStorage2,
     */
    function retrieveShortRecord(bytes32 _idxHash)
        external
        view
        returns (
            uint8,
            uint8,
            uint32,
            uint32,
            uint32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            uint16
        );

    /**
     * @dev Compare record.rightsholder with supplied bytes32 rightsholder
     * @param _idxHash - record asset ID
     * @param _rgtHash - record owner ID hash
     * @return 170 if matches, 0 if not
     */
    function verifyRightsHolder(bytes32 _idxHash, bytes32 _rgtHash)
        external
        view
        returns (uint256);

    /**
     * @dev Compare record.rightsholder with supplied bytes32 rightsholder (writes an emit in blockchain for independant verification)
     * @param _idxHash - record asset ID
     * @param _rgtHash - record owner ID hash
     * @return 170 if matches, 0 if not
     */
    function blockchainVerifyRightsHolder(bytes32 _idxHash, bytes32 _rgtHash)
        external
        returns (uint256);

    /**
     * @dev returns the address of a contract with name _name. This is for web3 implementations to find the right contract to interact with
     * example :  Frontend = ****** so web 3 first asks storage where to find frontend, then calls for frontend functions.
     * @param _name - contract name
     * @return contract address
     */
    function resolveContractAddress(string calldata _name)
        external
        view
        returns (address);

    /**
     * @dev returns the contract type of a contract with address _addr.
     * @param _addr - contract address
     * @param _node - node to look up contract type-in-class
     * @return contractType of given contract
     */
    function ContractInfoHash(address _addr, uint32 _node)
        external
        view
        returns (uint8, bytes32);
}

//---------------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------------
// /*
//  * @dev Interface for NODE_MGR
//  * INHERITANCE:
//     import "../Resources/PRUF_BASIC.sol";
//  */
interface NODE_MGR_Interface {
    //--------------------------------------------Admin Related Functions--------------------------
    /**
     * @dev Set pricing for Nodes
     * @param _newNodePrice - cost per node (18 decimals)
     * @param _newNodeBurn - burn per node (18 decimals)
     */
    function setNodePricing(uint256 _newNodePrice, uint256 _newNodeBurn)
        external;

    /**
     * @dev return current node token index and price
     * @return {
         nodeTokenIndex: current token number
         node_price: current price per node
         node_burn: burn per node
     }
     */
    function currentNodePricingInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    //--------------------------------------------External Functions--------------------------

    /**
     * @dev Mints Node token and creates an node.
     * @param _node - node to be created (unique)
     * @param _name - name to be configured to node (unique)
     * @param _nodeRoot - root of node
     * @param _custodyType - custodyType of new node (see docs)
     * @param _managementType - managementType of new node (see docs)
     * @param _storageProvider - storageProvider of new node (see docs)
     * @param _discount - discount of node (100 == 1%, 10000 == max)
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     * @param _recipientAddress - address to recieve node
     */
    function createNode(
        uint32 _node,
        string calldata _name,
        uint32 _nodeRoot,
        uint8 _custodyType,
        uint8 _managementType,
        uint8 _storageProvider,
        uint32 _discount,
        bytes32 _CAS1,
        bytes32 _CAS2,
        address _recipientAddress
    ) external;

    /**
     * @dev Burns (amount) tokens and mints a new Node token to the calling address
     * @param _name - chosen name of node
     * @param _nodeRoot - chosen root of node
     * @param _custodyType - chosen custodyType of node (see docs)
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     * @param _caller caller passed from an ID_VERIFIER
     * requires that caller has ID_VERIFIER_ROLE
     */
    function purchaseNode(
        string calldata _name,
        uint32 _nodeRoot,
        uint8 _custodyType,
        bytes32 _CAS1,
        bytes32 _CAS2,
        address _caller
    ) external returns (uint32);

    /**
     * @dev Authorize / Deauthorize users for an address be permitted to make record modifications
     * @dev only useful for custody types that designate user adresses (type1...)
     * @param _node - node that user is being authorized in
     * @param _addrHash - hash of address belonging to user being authorized
     * @param _userType - authority level for user (see docs)
     */
    function addUser(
        uint32 _node,
        bytes32 _addrHash,
        uint8 _userType
    ) external;

    /**
     * @dev Set import status for foreign nodes
     * @param _thisNode - node to dis/allow importing into
     * @param _otherNode - node to be imported
     * @param _newStatus - importability status (0=not importable, 1=importable >1 =????)
     */
    function updateImportStatus(
        uint32 _thisNode,
        uint32 _otherNode,
        uint256 _newStatus
    ) external;

    /**
     * @dev Modifies an node Node content adressable storage data pointer
     * @param _node - node being modified
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     */
    function updateNodeCAS(
        uint32 _node,
        bytes32 _CAS1,
        bytes32 _CAS2
    ) external;

    /**
     * @dev Set function costs and payment address per Node, in PRUF(18 decimals)
     * @param _node - node to set service costs
     * @param _service - service type being modified (see service types in ZZ_PRUF_DOCS)
     * @param _serviceCost - 18 decimal fee in PRUF associated with specified service
     * @param _paymentAddress - address to have _serviceCost paid to
     */
    function setOperationCosts(
        uint32 _node,
        uint16 _service,
        uint256 _serviceCost,
        address _paymentAddress
    ) external;

    /**
     * @dev Configure the immutable data in an Node one time
     * @param _node - node being modified
     * @param _managementType - managementType of node (see docs)
     * @param _storageProvider - storageProvider of node (see docs)
     * @param _refAddress - address permanently tied to node
     * @param _switches - 8 switch bits
     */
    function setNonMutableData(
        uint32 _node,
        uint8 _managementType,
        uint8 _storageProvider,
        address _refAddress,
        uint8 _switches
    ) external;

    /**
     * @dev extended node data setter
     * @param _node - node being configured
     * @param _u8a ExtendedNodeData
     * @param _u8b ExtendedNodeData
     * @param _u16c ExtendedNodeData
     * @param _u32d ExtendedNodeData
     * @param _u32e ExtendedNodeData
     */
    function setExtendedNodeData(
        uint32 _node,
        uint8 _u8a,
        uint8 _u8b,
        uint16 _u16c,
        uint32 _u32d,
        uint32 _u32e
    ) external;

    /**
     * @dev set an external erc721 token as ID verification (when bit 6 set to 1)
     * @param _node - node being configured
     * @param _tokenContractAddress  token contract used to verify id
     * @param _tokenId token ID used to verify id
     */
    function setExternalIdToken(
        uint32 _node,
        address _tokenContractAddress,
        uint256 _tokenId
    ) external;

    /**
     * @dev set an external erc721 token as ID verification (when bit 6 set to 1)
     * @param _node - node being configured
     * @param _tokenContractAddress  token contract used to verify id
     * @param _tokenId token ID used to verify id
     */
    function daoSetExternalId(
        uint32 _node,
        address _tokenContractAddress,
        uint256 _tokenId
    ) external;
}

//---------------------------------------------------------------------------------------------------------------

// NODE_STOR_Interface
// import "../Resources/PRUF_BASIC.sol";
// import "../Imports/security/ReentrancyGuard.sol";

interface NODE_STOR_Interface {
    //--------------------------------------------Administrative Setters--------------------------

    /**
     * @dev Sets the valid storage type providers.
     * @param _storageProvider - uint position for storage provider
     * @param _status - uint position for custody type status
     */
    function setStorageProviders(uint8 _storageProvider, uint8 _status)
        external;

    /**
     * @dev Sets the valid management types.
     * @param _managementType - uint position for management type
     * @param _status - uint position for custody type status
     */
    function setManagementTypes(uint8 _managementType, uint8 _status) external;

    /**
     * @dev Sets the valid custody types.
     * @param _custodyType - uint position for custody type
     * @param _status - uint position for custody type status
     */
    function setCustodyTypes(uint8 _custodyType, uint8 _status) external;

    /**
     * !! to be used with great caution !!
     * This potentially breaks decentralization and must eventually be given over to DAO.
     * @dev Increases (but cannot decrease) price share for a given node
     * @param _node - node in which cost share is being modified
     * @param _newDiscount - discount(1% == 100, 10000 == max)
     */
    function changeShare(uint32 _node, uint32 _newDiscount) external;

    /**
     * !! -------- to be used with great caution and only as a result of community governance action -----------
     * @dev Transfers a name from one node to another
     *   -Designed to remedy brand infringement issues. This breaks decentralization and must eventually be given
     *   -over to DAO.
     * @param _fromNode - source node
     * @param _toNode - destination node
     * @param _thisName - name to be transferred
     */
    function transferName(
        uint32 _fromNode,
        uint32 _toNode,
        string calldata _thisName
    ) external;

    /**
     * @dev Modifies an node Node name for its exclusive namespace
     * @param _node - node being modified
     * @param _newName - updated name associated with node (unique)
     */
    function updateNodeName(uint32 _node, string calldata _newName) external;

    /**
     * @dev Modifies the name => nodeid name resolution mapping
     * @param _node - node being mapped to the name
     * @param _name - namespace being remapped
     */
    function setNodeIdForName(uint32 _node, string memory _name) external;

    /**
     * !! -------- to be used with great caution -----------
     * @dev Modifies an Node with minimal controls
     * @param _node - node to be modified
     * @param _nodeRoot - root of node
     * @param _custodyType - custodyType of node (see docs)
     * @param _managementType - managementType of node (see docs)
     * @param _storageProvider - storageProvider of node (see docs)
     * @param _discount - discount of node (100 == 1%, 10000 == max)
     * @param _refAddress - referance address associated with an node
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     */
    function modifyNode(
        uint32 _node,
        uint32 _nodeRoot,
        uint8 _custodyType,
        uint8 _managementType,
        uint8 _storageProvider,
        uint32 _discount,
        address _refAddress,
        bytes32 _CAS1,
        bytes32 _CAS2
    ) external;

    /**
     * @dev Administratively Deauthorize address be permitted to mint or modify records
     * @dev only useful for custody types that designate user adresses (type1...)
     * @param _node - node that user is being deauthorized in
     * @param _addrHash - hash of address to deauthorize
     */
    function blockUser(uint32 _node, bytes32 _addrHash) external;

    /**
     * @dev Modifies an node Node content adressable storage data pointer
     * @param _node - node being modified
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     */
    function updateNodeCAS(
        uint32 _node,
        bytes32 _CAS1,
        bytes32 _CAS2
    ) external;

    /**
     * @dev Modifies node.switches bitwise (see NODE option switches in ZZ_PRUF_DOCS)
     * @param _node - node to be modified
     * @param _position - uint position of bit to be modified
     * @param _bit - switch - 1 or 0 (true or false)
     */
    function modifyNodeSwitches(
        uint32 _node,
        uint8 _position,
        uint8 _bit
    ) external;

    /**
     * @dev Authorize / Deauthorize users for an address be permitted to make record modifications
     * @dev only useful for custody types that designate user adresses (type1...)
     * @param _node - node that user is being authorized in
     * @param _addrHash - hash of address belonging to user being authorized
     * @param _userType - authority level for user (see docs)
     */
    function addUser(
        uint32 _node,
        bytes32 _addrHash,
        uint8 _userType
    ) external;

    /**
     * @dev Set import status for foreign nodes
     * @param _thisNode - node to dis/allow importing into
     * @param _otherNode - node to be imported
     * @param _newStatus - importability status (0=not importable, 1=importable >1 =????)
     */
    function updateImportStatus(
        uint32 _thisNode,
        uint32 _otherNode,
        uint256 _newStatus
    ) external;

    /**
     * @dev Set function costs and payment address per Node, in PRUF(18 decimals)
     * @param _node - node to set service costs
     * @param _service - service type being modified (see service types in ZZ_PRUF_DOCS)
     * @param _serviceCost - 18 decimal fee in PRUF associated with specified service
     * @param _paymentAddress - address to have _serviceCost paid to
     */
    function setOperationCosts(
        uint32 _node,
        uint16 _service,
        uint256 _serviceCost,
        address _paymentAddress
    ) external;

    /**
     * @dev Configure the immutable data in an Node one time
     * @param _node - node being modified
     * @param _managementType - managementType of node (see docs)
     * @param _storageProvider - storageProvider of node (see docs)
     * @param _refAddress - address permanently tied to node
     * @param _switches - 8 switch bits
     */
    function setNonMutableData(
        uint32 _node,
        uint8 _managementType,
        uint8 _storageProvider,
        address _refAddress,
        uint8 _switches
    ) external;

    /**
     * @dev extended node data setter
     * @param _node - node being configured
     * @param _u8a ExtendedNodeData
     * @param _u8b ExtendedNodeData
     * @param _u16c ExtendedNodeData
     * @param _u32d ExtendedNodeData
     * @param _u32e ExtendedNodeData
     */
    function setExtendedNodeData(
        uint32 _node,
        uint8 _u8a,
        uint8 _u8b,
        uint16 _u16c,
        uint32 _u32d,
        uint32 _u32e
    ) external;

    /**
     * @dev set an external erc721 token as ID verification (when bit 6 set to 1)
     * @param _node - node being configured
     * @param _tokenContractAddress  token contract used to verify id
     * @param _tokenId token ID used to verify id
     */
    function setExternalIdToken(
        uint32 _node,
        address _tokenContractAddress,
        uint256 _tokenId
    ) external;

    /** CTS:EXAMINE changed from daoSetExternalIdToken to daoSetExternalId
     * @dev DAO set an external erc721 token as ID verification (when bit 6 set to 1)
     * @param _node - node being configured
     * @param _tokenContractAddress  token contract used to verify id
     * @param _tokenId token ID used to verify id
     */
    function daoSetExternalId(
        uint32 _node,
        address _tokenContractAddress,
        uint256 _tokenId
    ) external;

    /**
     * @dev unlink erc721 token as ID verification
     * @param _node - node being unlinked
     */
    function unlinkExternalId(uint32 _node) external;

    /**
     * @dev extended node data setter
     * @param _foreignNode - node from other blockcahin to point to local node
     * @param _localNode local node to point to
     */
    function setLocalNode(uint32 _foreignNode, uint32 _localNode) external;

    /**
     * @dev Set import status for foreing nodes
     * @param _thisNode - node to dis/allow importing into
     * @param _otherNode - node to be potentially imported
     * returns importability status of _thisNode=>_othernode mapping
     */
    function getImportStatus(uint32 _thisNode, uint32 _otherNode)
        external
        view
        returns (uint256);

    /**
     * @dev extended node data setter
     * @param _foreignNode - node from other blockcahin to check for local node
     */
    function getLocalNode(uint32 _foreignNode) external view returns (uint32);

    /**
     * @dev extended node data getter
     * @param _node - node being queried
     * returns ExtendedNodeData struct (see resources-structs)
     */
    function getExtendedNodeData(uint32 _node)
        external
        view
        returns (ExtendedNodeData memory);

    /**
     * @dev get an node Node User type for a specified address
     * @param _userHash - hash of selected user
     * @param _node - node of query
     * @return type of user @ _node (see docs)
     */
    function getUserType(bytes32 _userHash, uint32 _node)
        external
        view
        returns (uint8);

    /**
     * @dev get the number of adresses authorized on a node
     * @param _node - node to query
     * @return number of auth users
     */
    function getNumberOfUsers(uint32 _node) external view returns (uint256);

    /**
     * @dev get the status of a specific management type
     * @param _managementType - management type associated with query (see docs)
     * @return 1 or 0 (enabled or disabled)
     */
    function getManagementTypeStatus(uint8 _managementType)
        external
        view
        returns (uint8);

    /**
     * @dev get the status of a specific storage provider
     * @param _storageProvider - storage provider associated with query (see docs)
     * @return 1 or 0 (enabled or disabled)
     */
    function getStorageProviderStatus(uint8 _storageProvider)
        external
        view
        returns (uint8);

    /**
     * @dev get the status of a specific custody type
     * @param _custodyType - custody type associated with query (see docs)
     * @return 1 or 0 (enabled or disabled)
     */
    function getCustodyTypeStatus(uint8 _custodyType)
        external
        view
        returns (uint8);

    /**
     * @dev Retrieve extended nodeData @ _node
     * @param _node - node associated with query
     * @return nodeData (see docs)
     * supports indirect node reference via localNodeFor[node]
     */
    function getNodeData(uint32 _node) external view returns (Node memory);

    /**
     * @dev verify the root of two Nodees are equal
     * @param _node1 - first node associated with query
     * @param _node2 - second node associated with query
     * @return 170 or 0 (true or false)
     * supports indirect node reference via localNodeFor[node]
     */
    function isSameRootNode(uint32 _node1, uint32 _node2)
        external
        view
        returns (uint8);

    /**
     * @dev Retrieve Node_name @ _tokenId or node
     * @param _node - tokenId associated with query
     * return name of token @ _tokenID
     * supports indirect node reference via localNodeFor[node]
     */
    function getNodeName(uint32 _node) external view returns (string memory);

    /**
     * @dev Retrieve node @ Node_name
     * @param _forThisName - name of node for nodeNumber query
     * @return node number @ _name
     */
    function resolveNode(string calldata _forThisName)
        external
        view
        returns (uint32);

    /**
     * @dev Retrieve function costs per Node, per service type in PRUF(18 decimals)
     * @param _node - node associated with query
     * @param _service - service number associated with query (see service types in ZZ_PRUF_DOCS)
     * @return invoice{
         rootAddress: @ _node root payment address @ _service
         rootPrice: @ _node root service cost @ _service
         NTHaddress: @ _node payment address tied @ _service
         NTHprice: @ _node service cost @ _service
         node: Node index
     }
     * supports indirect node reference via localNodeFor[node]
     */
    function getInvoice(uint32 _node, uint16 _service)
        external
        view
        returns (Invoice memory);

    /**
     * @dev Retrieve service costs for _node._service
     * @param _node - node associated with query
     * @param _service - service associated with query
     * @return Costs Struct for_node
     * supports indirect node reference via localNodeFor[node]
     */
    function getPaymentData(uint32 _node, uint16 _service)
        external
        view
        returns (Costs memory);

    /**
     * @dev Retrieve Node_discount @ _node
     * @param _node - node associated with query
     * @return percentage of rewards distribution @ _node
     * supports indirect node reference via localNodeFor[node]
     */
    function getNodeDiscount(uint32 _node) external view returns (uint32);

    /**
     * @dev get bit from .switches at specified position
     * @param _node - node associated with query
     * @param _position - bit position associated with query
     * @return 1 or 0 (enabled or disabled)
     * supports indirect node reference via localNodeFor[node]
     */
    function getSwitchAt(uint32 _node, uint8 _position)
        external
        view
        returns (uint256);

    /**
     * @dev creates an node and its corresponding namespace and data fields
     * @param _newNodeData - creation Data for new Node
     * @param _newNode - Node to be created (unique)
     * @param _caller - function caller passed by trusted calling contract
     * sets localNodeFor[_newNode] to _newNode
     */
    function createNodeData(
        Node memory _newNodeData,
        uint32 _newNode,
        address _caller
    ) external;
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for ECR_MGR
 * INHERITANCE:

 */
interface ECR_MGR_Interface {
    /**
     * @dev Set an asset to escrow status (6/50/56). Sets timelock for unix timestamp of escrow end.
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _newAssetStatus - new escrow status of asset (see docs)
     * @param _escrowOwnerAddressHash - hash of escrow controller address
     * @param _timelock - timelock parameter for time controlled escrows
     */
    function setEscrow(
        bytes32 _idxHash,
        uint8 _newAssetStatus,
        bytes32 _escrowOwnerAddressHash,
        uint256 _timelock
    ) external;

    /**
     * @dev remove asset from escrow
     * @param _idxHash - hash of asset information created by frontend inputs
     */
    function endEscrow(bytes32 _idxHash) external;

    /**
     * @dev Sets data in the Escrow Data Light mapping
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _escrowDataLight - struct of data associated with light load escrows
     */
    function setEscrowDataLight(
        bytes32 _idxHash,
        escrowDataExtLight calldata _escrowDataLight
    ) external;

    /**
     * @dev Sets data in the Escrow Data Heavy mapping
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param escrowDataHeavy - struct of data associated with heavy load escrows
     */
    function setEscrowDataHeavy(
        bytes32 _idxHash,
        escrowDataExtHeavy calldata escrowDataHeavy
    ) external;

    /**
     * @dev Permissive removal of asset from escrow status after time-out (no special qualifiers to end expired escrow)
     * @param _idxHash - hash of asset information created by frontend inputs
     */
    function permissiveEndEscrow(bytes32 _idxHash) external;

    /**
     * @dev return escrow owner hash
     * @param _idxHash - hash of asset information created by frontend inputs
     *
     * @return hash of escrow owner
     */
    function retrieveEscrowOwner(bytes32 _idxHash)
        external
        view
        returns (bytes32);

    /**
     * @dev return escrow data associated with an asset
     * @param _idxHash - hash of asset information created by frontend inputs
     *
     * @return all escrow data  @ _idxHash
     */
    function retrieveEscrowData(bytes32 _idxHash)
        external
        view
        returns (escrowData memory);

    /**
     * @dev return EscrowDataLight
     * @param _idxHash - hash of asset information created by frontend inputs
     *
     * @return EscrowDataLight struct @ _idxHash
     */
    function retrieveEscrowDataLight(bytes32 _idxHash)
        external
        view
        returns (escrowDataExtLight memory);

    /**
     * @dev return EscrowDataHeavy
     * @param _idxHash - hash of asset information created by frontend inputs
     *
     * @return EscrowDataHeavy struct @ _idxHash
     */
    function retrieveEscrowDataHeavy(bytes32 _idxHash)
        external
        view
        returns (escrowDataExtHeavy memory);
}

//---------------------------------------------------------------------------------------------------------------

// /**
//  * @dev Interface for ID_MGR
//  * INHERITANCE:
// // import "./RESOURCE_PRUF_STRUCTS.sol";
// // import "./Imports/access/AccessControl.sol";
// // import "./Imports/security/Pausable.sol";
// */
// interface ID_MGR_Interface {
//     /**
//      * @dev Mint an Asset token
//      * @param _recipientAddress - Address to mint token into
//      * @param _trustLevel - Token ID to mint
//      * @param _IdHash - URI string to atatch to token
//      */
//     function mintID(
//         address _recipientAddress,
//         uint256 _trustLevel,
//         bytes32 _IdHash
//     ) external;

//     /**
//      * @dev Burn PRUF_ID token
//      * @param _addr - address to burn ID from
//      */
//     function burnID(address _addr) external;

//     /**
//      * @dev Set new ID data fields
//      * @param _addr - address to set trust level
//      * @param _trustLevel - _trustLevel to set
//      */
//     function setTrustLevel(address _addr, uint256 _trustLevel) external;

//     /**
//      * @dev get ID data given an address to look up
//      * @param _addr - address to check
//      * @return ID struct (see interfaces for struct definitions)
//      */
//     function IdDataByAddress(address _addr)
//         external
//         view
//         returns (PRUFID memory);

//     /**
//      * @dev get ID data given an IdHash to look up
//      * @param _IdHash - IdHash to check
//      * @return ID struct (see interfaces for struct definitions)
//      */
//     function IdDataByIdHash(bytes32 _IdHash)
//         external
//         view
//         returns (PRUFID memory);

//     /**
//      * @dev get ID trustLevel
//      * @param _addr - address to check
//      * @return trust level of token id
//      */
//     function trustLevel(address _addr) external view returns (uint256);

//     /**
//      * @dev Pauses all token transfers.
//      *
//      * See {ERC721Pausable} and {Pausable-_pause}.
//      *
//      * Requirements:
//      *
//      * - the caller must have the `PAUSER_ROLE`.
//      */
//     function pause() external;

//     /**
//      * @dev Unpauses all token transfers.
//      *
//      * See {ERC721Pausable} and {Pausable-_unpause}.
//      *
//      * Requirements:
//      *
//      * - the caller must have the `PAUSER_ROLE`.
//      */
//     function unpause() external;
// }

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for RCLR
 * INHERITANCE:


 */
interface RCLR_Interface {
    /**
     * @dev discards item -- caller is assetToken contract
     * @param _idxHash asset ID
     * @param _sender discarder
     * Caller Must have DISCARD_ROLE
     */
    function discard(bytes32 _idxHash, address _sender) external;

    /**
     * @dev reutilize a recycled asset
     * maybe describe the reqs in this one, back us up on the security
     * @param _idxHash asset ID
     * @param _rgtHash rights holder hash to set
     */
    function recycle(bytes32 _idxHash, bytes32 _rgtHash) external;
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for APP
 * INHERITANCE:

 */
interface APP_Interface {
    //--------------------------------------------External Functions--------------------------

    /**
     * @dev Creates a new record
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of rightsholder information created by frontend inputs
     * @param _node - node the asset will be created in
     * @param _countDownStart - decremental counter for an assets lifecycle
     * @param _URIsuffix URI
     */
    function newRecord(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint32 _node,
        uint32 _countDownStart,
        string memory _URIsuffix
    ) external;

    // /** //import & export have been slated for reevaluation
    //  * @dev import Rercord, must match export node
    //  * posessor is considered to be owner. sets rec.assetStatus to 0.
    //  * @param _idxHash - hash of asset information created by frontend inputs
    //  * @param _newNode - node the asset will be imported into
    //  */
    // function importAsset(bytes32 _idxHash, uint32 _newNode) external;

    /**
     * @dev Modify rec.rightsHolder
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of new rightsholder information created by frontend inputs
     */
    function forceModifyRecord(bytes32 _idxHash, bytes32 _rgtHash) external;

    /**
     * @dev Transfer rights to new rightsHolder with confirmation of matching rgthash
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of rightsholder information created by frontend inputs
     * @param _newrgtHash - hash of targeted reciever information created by frontend inputs
     */
    function transferAsset(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        bytes32 _newrgtHash
    ) external;

    /**
     * @dev Modify **Record** NonMutableStorage with confirmation of matching rgthash
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of rightsholder information created by frontend inputs
     * @param _nonMutableStorage1 - field for permanent external asset data
     * @param _nonMutableStorage2 - field for permanent external asset data
     */
    function addNonMutableStorage(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        bytes32 _nonMutableStorage1,
        bytes32 _nonMutableStorage2
    ) external;

    /**
     * @dev Transfer any specified assetToken from contract
     * @param _to - address to send to
     * @param _idxHash - asset index
     */
    function transferAssetToken(address _to, bytes32 _idxHash) external;

    /**
     * @dev Modify **Record**.assetStatus with confirmation of matching rgthash required
     * @param _idxHash asset to moidify
     * @param _rgtHash rgthash to match in front end
     * @param _newAssetStatus updated status
     */
    function modifyStatus(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint8 _newAssetStatus
    ) external;

    /**
     * @dev set **Record**.assetStatus to lost or stolen, with confirmation of matching rgthash required
     * @param _idxHash asset to moidify
     * @param _rgtHash rgthash to match in front end
     * @param _newAssetStatus updated status
     */
    function setLostOrStolen(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint8 _newAssetStatus
    ) external;

    /**
     * @dev Decrement **Record**.countdown with confirmation of matching rgthash required
     * @param _idxHash asset to moidify
     * @param _rgtHash rgthash to match in front end
     * @param _decAmount amount to decrement
     */
    function decrementCounter(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint32 _decAmount
    ) external;

    /**
     * @dev Modify rec.MutableStorage field with rghHash confirmation
     * @param _idxHash idx of asset to Modify
     * @param _rgtHash rgthash to match in front end
     * @param _mutableStorage1 content adressable storage adress part 1
     * @param _mutableStorage2 content adressable storage adress part 2
     */
    function modifyMutableStorage(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        bytes32 _mutableStorage1,
        bytes32 _mutableStorage2
    ) external;

    //     /** //import & export have been slated for reevaluation
    //      * @dev Export FROM Custodial - sets asset to status 70 (importable) for export
    //      * @dev exportTo - sets asset to status 70 (importable) and defines the node that the item can be imported into
    //      * @param _idxHash idx of asset to Modify
    //      * @param _exportTo node target for export
    //      * @param _addr adress to send asset to
    //      * @param _rgtHash rgthash to match in front end
    //      */
    //     function exportAssetTo(
    //         bytes32 _idxHash,
    //         uint32 _exportTo,
    //         address _addr,
    //         bytes32 _rgtHash
    //     ) external;
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for APP_NC
 * INHERITANCE:

 */
interface APP_NC_Interface {
    //---------------------------------------External Functions-------------------------------

    /**
     * @dev Create a newRecord with description
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of rightsholder information created by frontend inputs
     * @param _node - node the asset will be created in
     * @param _countDownStart - decremental counter for an assets lifecycle
     * @param _mutableStorage1 - field for external asset data
     * @param _mutableStorage2 - field for external asset data
     * @param _URIsuffix - tokenURI
     */
    function newRecordWithDescription(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint32 _node,
        uint32 _countDownStart,
        bytes32 _mutableStorage1,
        bytes32 _mutableStorage2,
        string memory _URIsuffix
    ) external;

    /**
     * @dev Create a newRecord with permanent description
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of rightsholder information created by frontend inputs
     * @param _node - node the asset will be created in
     * @param _countDownStart - decremental counter for an assets lifecycle
     * @param _nonMutableStorage1 - field for permanent external asset data
     * @param _nonMutableStorage2 - field for permanent external asset data
     * @param _URIsuffix - tokenURI
     */
    function newRecordWithNote(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint32 _node,
        uint32 _countDownStart,
        bytes32 _nonMutableStorage1,
        bytes32 _nonMutableStorage2,
        string memory _URIsuffix
    ) external;

    /**
     * @dev Create a newRecord
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _rgtHash - hash of rightsholder information created by frontend inputs
     * @param _node - node the asset will be created in
     * @param _countDownStart - decremental counter for an assets lifecycle
     * @param _URIsuffix - tokenURI
     */
    function newRecord(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint32 _node,
        uint32 _countDownStart,
        string memory _URIsuffix
    ) external;

    // /** //import & export have been slated for reevaluation
    //  * @dev exportTo - sets asset to status 70 (importable) and defines the node that the item can be imported into
    //  * @param _idxHash idx of asset to Modify
    //  * @param _exportTo node target for export
    //  */
    // function exportAssetTo(bytes32 _idxHash, uint32 _exportTo) external;

    // /** //import & export have been slated for reevaluation
    //  * @dev Import a record into a new node
    //  * @param _idxHash - hash of asset information created by frontend inputs
    //  * @param _newNode - node the asset will be imported into
    //  */
    // function importAsset(bytes32 _idxHash, uint32 _newNode) external;

    /**
     * @dev record NonMutableStorage data
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _nonMutableStorage1 - field for permanent external asset data
     * @param _nonMutableStorage2 - field for permanent external asset data
     */
    function addNonMutableStorage(
        bytes32 _idxHash,
        bytes32 _nonMutableStorage1,
        bytes32 _nonMutableStorage2
    ) external;

    /**
     * @dev record NonMutableStorage data
     * @param _idxHash - hash of asset information created by frontend inputs
     * @param _nonMutableStorage1 - field for permanent external asset data
     * @param _nonMutableStorage2 - field for permanent external asset data
     */
    function updateNonMutableStorage(
        bytes32 _idxHash,
        bytes32 _nonMutableStorage1,
        bytes32 _nonMutableStorage2
    ) external;

    /**
     * @dev Modify rgtHash (like forceModify)
     * @param _idxHash idx of asset to Modify
     * @param _newRgtHash rew rgtHash to apply
     */
    function changeRgt(bytes32 _idxHash, bytes32 _newRgtHash) external;

    /**
     * @dev Modify **Record**.assetStatus with confirmation required
     * @param _idxHash idx of asset to Modify
     * @param _newAssetStatus Updated status
     */
    function modifyStatus(bytes32 _idxHash, uint8 _newAssetStatus) external;

    /**
     * @dev set **Record**.assetStatus to lost or stolen, with confirmation of matching rgthash required.
     * @param _idxHash idx of asset to Modify
     * @param _newAssetStatus Updated status
     */
    function setLostOrStolen(bytes32 _idxHash, uint8 _newAssetStatus) external;

    /**
     * @dev Decrement **Record**.countdown.
     * @param _idxHash index hash of asset to modify
     * @param _decAmount Amount to decrement
     */
    function decrementCounter(bytes32 _idxHash, uint32 _decAmount) external;

    /**
     * @dev Modify **Record**.mutableStorage1 with confirmation of matching rgthash required.
     * @param _idxHash idx of asset to Modify
     * @param _mutableStorage1 content addressable storage address part 1
     * @param _mutableStorage2 content addressable storage address part 2
     */
    function modifyMutableStorage(
        bytes32 _idxHash,
        bytes32 _mutableStorage1,
        bytes32 _mutableStorage2
    ) external;
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for EO_STAKING
 * INHERITANCE:





 */
interface EO_STAKING_Interface {
    //--------------------------------------External functions--------------------------------------------//

    /**
     * @dev Setter for setting fractions of a day for minimum interval
     * @param _minUpgradeInterval in seconds
     */
    function setMinimumPeriod(uint256 _minUpgradeInterval) external;

    /**
     * @dev Kill switch for staking reward earning
     * @param _delay delay in seconds to end stake earning
     */
    function endStaking(uint256 _delay) external;

    /**
     * @dev Set address of contracts to interface with
     * @param _utilAddress address of UTIL_TKN(PRUF)
     * @param _stakeAddress address of STAKE_TKN
     * @param _stakeVaultAddress address of STAKE_VAULT
     * @param _rewardsVaultAddress address of REWARDS_VAULT
     */
    function setTokenContracts(
        address _utilAddress,
        address _stakeAddress,
        address _stakeVaultAddress,
        address _rewardsVaultAddress
    ) external;

    /**
     * @dev Set stake tier parameters
     * @param _stakeTier Staking level to set
     * @param _min Minumum stake
     * @param _max Maximum stake
     * @param _interval staking interval, in dayUnits - set to the number of days that the stake and reward interval will be based on.
     * @param _bonusPercentage bonusPercentage in tenths of a percent: 15 = 1.5% or 15/1000 per interval. Calculated to a fixed amount of tokens in the actual stake
     */
    function setStakeLevels(
        uint256 _stakeTier,
        uint256 _min,
        uint256 _max,
        uint256 _interval,
        uint256 _bonusPercentage
    ) external;

    /**
     * @dev Create a new stake
     * @param _amount amount of tokens to stake
     * @param _stakeTier staking tier
     */
    function stakeMyTokens(uint256 _amount, uint256 _stakeTier) external;

    /**
     * @dev Transfers eligible rewards to staker, resets last payment time, adds _amount tokens to holders stake
     * @param _tokenId token id to modify stake
     */
    function increaseMyStake(uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev Transfers eligible rewards to staker, resets last payment time
     * @param _tokenId token id to claim rewards on
     */
    function claimBonus(uint256 _tokenId) external;

    /**
     * @dev Burns stake, transfers eligible rewards and staked tokens to staker
     * @param _tokenId stake key token id
     */
    function breakStake(uint256 _tokenId) external;

    /**
     * @dev Pauses contract.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     */
    function pause() external;

    /**
     * @dev Unpauses contract.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     */
    function unpause() external;

    /**
     * @dev Check eligible rewards amount for a stake, for verification
     * @param _tokenId token id to check
     * @return reward and microIntervals
     */
    function checkEligibleRewards(uint256 _tokenId)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns info of given stake key tokenId
     * @param _tokenId Stake ID to return
     * @return Stake struct, see Interfaces.sol
     */
    function stakeInfo(uint256 _tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Return specific stakeTier specification
     * @param _stakeTier stake level to inspect
     * @return StakingTier @ given index, see declaration in beginning of contract
     */
    function getStakeLevel(uint256 _stakeTier)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for STAKE_VAULT
 * INHERITANCE:





 */
interface STAKE_VAULT_Interface {
    //-----------External Admin functions / isContractAdmin-----------//

    /**
     * @dev Set address of contracts to interface with
     * @param _utilAddress address of UTIL_TKN contract
     * @param _stakeAddress address of STAKE_TKN contract
     */
    function setTokenContracts(address _utilAddress, address _stakeAddress)
        external;

    //-------------------------External functions-----------------------//

    /**
     * @dev moves tokens(amount) from holder(tokenID) into itself using trustedAgentTransfer, records the amount in stake map
     * @param _tokenId stake token to take stake for
     * @param _amount amount of stake to pull
     */
    function takeStake(uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev sends stakedAmount[tokenId] tokens to ownerOf(tokenId), updates the stake map.
     * @param _tokenId stake token to release stake for
     */
    function releaseStake(uint256 _tokenId) external;

    /**
     * @dev Returns the amount of tokens staked on (tokenId)
     * @param _tokenId token to check
     * @return Stake of _tokenId
     */
    function stakeOfToken(uint256 _tokenId) external view returns (uint256);

    /**
     * @dev Pauses contract.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     */
    function pause() external;

    /**
     * @dev Unpauses contract.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     */
    function unpause() external;
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for REWARDS_VAULT
 * INHERITANCE:





 */
interface REWARDS_VAULT_Interface {
    /**
     * @dev Set address of contracts to interface with
     * @param _utilAddress address of UTIL_TKN
     * @param _stakeAddress address of STAKE_TKN
     */
    function setTokenContracts(address _utilAddress, address _stakeAddress)
        external;

    /**
     * @dev Sends (amount) pruf to ownerOf(tokenId)
     * @param _tokenId - stake key token ID
     * @param _amount - amount to pay to owner of (tokenId)
     */
    function payRewards(uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev Pauses contract.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     */
    function pause() external;

    /**
     * @dev Unpauses contract.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     */
    function unpause() external;
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for UD_721
 * INHERITANCE:


 */
interface UD_721_Interface {
    /**
     * @dev Set address of STOR contract to interface with
     * @param _erc721Address address of token contract to interface with
     */
    function setUnstoppableDomainsTokenContract(address _erc721Address)
        external;

    /**
     * @dev Burns (amount) tokens and mints a new Node token to the calling address
     * @param _domain - chosen domain of node
     * @param _tld - chosen tld of node
     * @param _nodeRoot - chosen root of node
     * @param _custodyType - chosen custodyType of node (see docs)
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     */
    function purchaseNode(
        string calldata _domain,
        string calldata _tld,
        uint32 _nodeRoot,
        uint8 _custodyType,
        bytes32 _CAS1,
        bytes32 _CAS2
    ) external returns (uint256);

    /**
     * @dev Authorize / Deauthorize users for an address be permitted to make record modifications
     * @dev only useful for custody types that designate user adresses (type1...)
     * @param _node - node that user is being authorized in
     * @param _addrHash - hash of address belonging to user being authorized
     * @param _userType - authority level for user (see docs)
     */
    function addUser(
        uint32 _node,
        bytes32 _addrHash,
        uint8 _userType
    ) external;

    /**
     * @dev Set import status for foreign nodes
     * @param _thisNode - node to dis/allow importing into
     * @param _otherNode - node to be imported
     * @param _newStatus - importability status (0=not importable, 1=importable >1 =????)
     */
    function updateImportStatus(
        uint32 _thisNode,
        uint32 _otherNode,
        uint256 _newStatus
    ) external;

    /**
     * @dev Modifies an node Node content adressable storage data pointer
     * @param _node - node being modified
     * @param _CAS1 - any external data attatched to node 1/2
     * @param _CAS2 - any external data attatched to node 2/2
     */
    function updateNodeCAS(
        uint32 _node,
        bytes32 _CAS1,
        bytes32 _CAS2
    ) external;

    /**
     * @dev Set function costs and payment address per Node, in PRUF(18 decimals)
     * @param _node - node to set service costs
     * @param _service - service type being modified (see service types in ZZ_PRUF_DOCS)
     * @param _serviceCost - 18 decimal fee in PRUF associated with specified service
     * @param _paymentAddress - address to have _serviceCost paid to
     */
    function setOperationCosts(
        uint32 _node,
        uint16 _service,
        uint256 _serviceCost,
        address _paymentAddress
    ) external;

    /**
     * @dev Configure the immutable data in an Node one time
     * @param _node - node being modified
     * @param _managementType - managementType of node (see docs)
     * @param _storageProvider - storageProvider of node (see docs)
     * @param _refAddress - address permanently tied to node
     */
    function setNonMutableData(
        uint32 _node,
        uint8 _managementType,
        uint8 _storageProvider,
        address _refAddress,
        uint8 _switches
    ) external;

    /**
     * @dev extended node data setter
     * @param _node - node being configured
     * @param _u8a ExtendedNodeData
     * @param _u8b ExtendedNodeData
     * @param _u16c ExtendedNodeData
     * @param _u32d ExtendedNodeData
     * @param _u32e ExtendedNodeData
     */
    function setExtendedNodeData(
        uint32 _node,
        uint8 _u8a,
        uint8 _u8b,
        uint16 _u16c,
        uint32 _u32d,
        uint32 _u32e
    ) external;

    function getTokenIdFromDomain(string memory _domain, string memory _tld)
        external
        returns (uint256);
}

//---------------------------------------------------------------------------------------------------------------

/*
 * @dev Interface for BASIC
 * INHERITANCE:








 */
interface BASIC_Interface {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Resolve contract addresses from STOR
     */
    function resolveContractAddresses() external;

    /**
     * @dev Set address of STOR contract to interface with
     * @param _storageAddress address of PRUF_STOR
     */
    function setStorageContract(address _storageAddress) external;

    /***
     * @dev Triggers stopped state. (pausable)
     */
    function pause() external;

    /***
     * @dev Returns to normal state. (pausable)
     */
    function unpause() external;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external returns (bool);

    /**
     * @dev send an ERC721 token from this contract
     * @param _tokenContract Address of foreign token contract
     * @param _to destination
     * @param _tokenID Token ID
     */
    function ERC721Transfer(
        address _tokenContract,
        address _to,
        uint256 _tokenID
    ) external;

    /**
     * @dev send an ERC20 token from this contract
     * @param _tokenContract Address of foreign token contract
     * @param _to destination
     * @param _amount amount to transfer
     */
    function ERC20Transfer(
        address _tokenContract,
        address _to,
        uint256 _amount
    ) external;
}

//---------------------------------------------------------------------------------------------------------------

// /**
//  * @dev External interface of AccessControl declared to support ERC165 detection.
//  */
// interface IAccessControl {
//     /**
//      * @dev Returns `true` if `account` has been granted `role`.
//      */
//     function hasRole(bytes32 role, address account)
//         external
//         view
//         returns (bool);

//     /**
//      * @dev Returns the admin role that controls `role`. See {grantRole} and
//      * {revokeRole}.
//      *
//      * To change a role's admin, use {AccessControl-_setRoleAdmin}.
//      */
//     function getRoleAdmin(bytes32 role) external view returns (bytes32);

//     /**
//      * @dev Grants `role` to `account`.
//      *
//      * If `account` had not been already granted `role`, emits a {RoleGranted}
//      * event.
//      *
//      * Requirements:
//      *
//      * - the caller must have ``role``'s admin role.
//      */
//     function grantRole(bytes32 role, address account) external;

//     /**
//      * @dev Revokes `role` from `account`.
//      *
//      * If `account` had been granted `role`, emits a {RoleRevoked} event.
//      *
//      * Requirements:
//      *
//      * - the caller must have ``role``'s admin role.
//      */
//     function revokeRole(bytes32 role, address account) external;

//     /**
//      * @dev Revokes `role` from the calling account.
//      *
//      * Roles are often managed via {grantRole} and {revokeRole}: this function's
//      * purpose is to provide a mechanism for accounts to lose their privileges
//      * if they are compromised (such as when a trusted device is misplaced).
//      *
//      * If the calling account had been granted `role`, emits a {RoleRevoked}
//      * event.
//      *
//      * Requirements:
//      *
//      * - the caller must be `account`.
//      */
//     function renounceRole(bytes32 role, address account) external;

//     /**
//      * @dev Returns one of the accounts that have `role`. `index` must be a
//      * value between 0 and {getRoleMemberCount}, non-inclusive.
//      *
//      * Role bearers are not sorted in any particular way, and their ordering may
//      * change at any point.
//      *
//      * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
//      * you perform all queries on the same block. See the following
//      * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
//      * for more information.
//      */
//     function getRoleMember(bytes32 role, uint256 index)
//         external
//         view
//         returns (address);

//     /**
//      * @dev Returns the number of accounts that have `role`. Can be used
//      * together with {getRoleMember} to enumerate all bearers of a role.
//      */
//     function getRoleMemberCount(bytes32 role) external view returns (uint256);
//}

// File: contracts/Resources/RESOURCE_PRUF_TKN_INTERFACES.sol

/*--------------------------------------------------------PRüF0.8.7
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\__/\\ ___/\\\\\\\\\\\\\\\        
__\/\\\/////////\\\ _/\\\///////\\\ ____\//__\//____\/\\\///////////__       
___\/\\\_______\/\\\_\/\\\_____\/\\\ ________________\/\\\ ____________      
____\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\_\/\\\\\\\\\\\ ____     
_____\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\_\/\\\///////______
______\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\_\/\\\ ____________
_______\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\_\/\\\ ____________
________\/\\\ ____________\/\\\ _____\//\\\_\//\\\\\\\\\ _\/\\\ ____________
_________\/// _____________\/// _______\/// __\///////// __\/// _____________
*---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 *  TO DO
 *
 *---------------------------------------------------------------*/

//  UNLICENSED
pragma solidity ^0.8.7;

/*
 * @dev Interface for UTIL_TKN
 * INHERITANCE:





 */
interface UTIL_TKN_Interface {
    /**
     * @dev ----------------------------------------PERMANANTLY !!!  Kills trusted agent and payable functions
     * this will break the functionality of current payment mechanisms.
     *
     * The workaround for this is to create an allowance for pruf contracts for a single or multiple payments,
     * either ahead of time "loading up your PRUF account" or on demand with an operation. On demand will use quite a bit more gas.
     * "preloading" should be pretty gas efficient, but will add an extra step to the workflow, requiring users to have sufficient
     * PRuF "banked" in an allowance for use in the system.
     * @param _key - set 170 to kill trusted agent role permenantly
     */
    function adminKillTrustedAgent(uint256 _key) external;

    /**
     * @dev Set calling wallet to a "cold Wallet" that cannot be manipulated by TRUSTED_AGENT or PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function setColdWallet() external;

    /**
     * @dev un-set calling wallet to a "cold Wallet", enabling manipulation by TRUSTED_AGENT and PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function unSetColdWallet() external;

    /**
     * @dev return an addresses "cold wallet" status
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS
     * @param _addr - Address to check cold wallet
     * returns 0 if not a cold wallet, 170 if a cold wallet
     */
    function isColdWallet(address _addr) external view returns (uint256);

    /**
     * @dev Set address of SHARES payment contract. by default contract will use root address instead if set to zero.
     * @param _paymentAddress - address to send shares payment to
     */
    function AdminSetSharesAddress(address _paymentAddress) external;

    /*
     * @dev Deducts token payment from transaction
     * Requirements:
     * - the caller must have PAYABLE_ROLE.
     * - the caller must have a pruf token balance of at least `_rootPrice + _NTHprice`.
     */
    // ---- NON-LEGACY
    // function payForService(address _senderAddress, Invoice calldata invoice)
    //     external;

    //---- LEGACY
    /**
     * @dev Deducts token payment from transaction
     * @param _senderAddress - address to send payment from
     * @param _rootAddress - root address for payment
     * @param _rootPrice - root amount for payment
     * @param _NTHaddress - NTH address for payment
     * @param _NTHprice - NTH amount for payment
     */
    function payForService(
        address _senderAddress,
        address _rootAddress,
        uint256 _rootPrice,
        address _NTHaddress,
        uint256 _NTHprice
    ) external;

    /**
     * @dev arbitrary burn (requires TRUSTED_AGENT_ROLE)   ****USE WITH CAUTION
     * @param _addr - Address from which to burn tokens
     * @param _amount - amount of tokens to burn
     */
    function trustedAgentBurn(address _addr, uint256 _amount) external;

    /**
     * @dev arbitrary transfer (requires TRUSTED_AGENT_ROLE)   ****USE WITH CAUTION
     * @param _from - Address from which to send tokens
     * @param _to - Address to send tokens to
     * @param _amount - amount of tokens to transfer
     */
    function trustedAgentTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @dev Take a balance snapshot, returns snapshot ID
     * returns snapshot number
     */
    function takeSnapshot() external returns (uint256);

    /**
     * @dev Creates `_amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param _to - Address to send tokens to
     * @param _amount - amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @dev Returns the cap on the token's total supply.
     * returns total cap
     */
    function cap() external view returns (uint256);

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId)
        external
        returns (uint256);

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) external returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        returns (uint256);

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
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements
     *       -on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        returns (address);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external returns (bytes32);

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

//=========================================================================================================================================================================================================
/*
 * @dev Interface for NODE_TKN
 * INHERITANCE:



 */
interface NODE_TKN_Interface {
    /**
     * @dev Universally callable function that sends a node token to the address of its referenced ID token,
     * or removes the bit6 flag if its ID token does not exist.
     */
    function fixOrphanedNode(uint256 _thisNode) external;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev See {IERC165-supportsInterface}.
     * @param interfaceId - ID of interface
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    //----------------------External Functions----------------------//

    /**
     * @dev Set storage contract to interface with
     * @param _nodeStorageAddress - Storage contract address
     */
    function setNodeStorageContract(
        address _nodeStorageAddress
    ) external;

    /**
     * @dev Mint a Node token
     * @param _recipientAddress - Address to mint token into
     * @param _tokenId - Token ID to mint
     * @param _tokenURI - URI string to atatch to token
     * @return Token ID of minted token
     */
    function mintNodeToken(
        address _recipientAddress,
        uint256 _tokenId,
        string calldata _tokenURI
    ) external returns (uint256);

    /**
     * @dev See if node token exists
     * @param tokenId - Token ID to set URI
     * @return 170 or 0 (true or false)
     */
    function tokenExists(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address tokenHolderAdress);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements
     *       -on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        returns (address);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external returns (bytes32);

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

//=========================================================================================================================================================================================================
/*
 * @dev Interface for STAKE_TKN
 * INHERITANCE:



 */
interface STAKE_TKN_Interface {
    /**
     * @dev Mint a stake key token to specified address
     * @param _recipientAddress - Address to mint token into
     * @param _tokenId - Token ID to mint
     * @return minted token ID
     */
    function mintStakeToken(address _recipientAddress, uint256 _tokenId)
        external
        returns (uint256);

    /**
     * @dev Burn a stake key token
     * @param _tokenId - Token ID to burn
     * @return burned Token ID
     */
    function burnStakeToken(uint256 _tokenId) external returns (uint256);

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external returns (string memory);

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address tokenHolderAdress);

    /**
     * @dev Returns 170 if the specified token exists, otherwise zero
     *
     */
    function tokenExists(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements
     *       -on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        returns (address);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external returns (bytes32);

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

//=========================================================================================================================================================================================================

/*
 * @dev Interface for A_TKN
 * INHERITANCE:



 */
interface A_TKN_Interface {
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @param tokenId - token to have URI checked
     * @return URI of token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    /**
     * @dev ----------------------------------------PERMANANTLY !!!  Kills trusted agent and payable functions
     * this will break the functionality of current payment mechanisms.
     *
     * The workaround for this is to create an allowance for pruf contracts for a single or multiple payments,
     * either ahead of time "loading up your PRUF account" or on demand with an operation. On demand will use quite a bit more gas.
     * "preloading" should be pretty gas efficient, but will add an extra step to the workflow, requiring users to have sufficient
     * PRuF "banked" in an allowance for use in the system.
     * @param _key - set to 170 to PERMENANTLY REMOVE TRUSTED AGENT CAPABILITY
     */
    function killTrustedAgent(uint256 _key) external;

    /**
     * @dev Set storage contract to interface with
     * @param _storageAddress - Storage contract address
     */
    function setStorageContract(address _storageAddress) external;

    /**
     * @dev Address Setters  - resolves addresses from storage and sets local interfaces
     */
    function resolveContractAddresses() external;

    /**
     * @dev return an adresses "cold wallet" status
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS
     * @param _addr - address to check
     * @return 170 if adress is set to "cold wallet" status
     */
    function isColdWallet(address _addr) external view returns (uint256);

    /**
     * @dev Set calling wallet to a "cold Wallet" that cannot be manipulated by TRUSTED_AGENT or PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function setColdWallet() external;

    /**
     * @dev un-set calling wallet to a "cold Wallet", enabling manipulation by TRUSTED_AGENT and PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function unSetColdWallet() external;

    /**
     * @dev Sets the baseURI for a storage provider.
     * @param _storageProvider - storage provider number
     * @param _URI - baseURI to add
     */
    function setBaseURIforStorageType(
        uint8 _storageProvider,
        string calldata _URI
    ) external ;

    /**
     * @dev Mint an Asset token
     * @param _recipientAddress - Address to mint token into (may mint to node holder depending on flags)
     * @param _tokenId - Token ID to mint
     * @return Token ID of minted token
     */
    function mintAssetToken(
        address _recipientAddress,
        uint256 _tokenId,
        string calldata _URIsuffix
    ) external returns (uint256);

    /**
     * @dev Set new token URI String
     * @param _tokenId - Token ID to set URI
     * @param _tokenURI - URI string to atatch to token
     * @return tokenId
     */
    function setURI(uint256 _tokenId, string calldata _tokenURI)
        external
        returns (uint256);

    /**
     * @dev returns a baseURI for a storage provider / index combination, as well as the total number of URIs.
     * @param _node - node
     */
    function getBaseUriForNode(uint32 _node) external;

    // /*
    //  * @dev Reassures user that token is minted in the PRUF system
    //  */
    // function validatePipToken(
    //     uint256 tokenId,
    //     uint32 _node,
    //     string calldata _authCode
    // ) external view;

    /**
     * @dev See if asset token exists
     * @param tokenId - Token ID to set URI
     * @return 170 if token exists, otherwise 0
     */
    function tokenExists(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Transfers the ownership of a given token ID to another address by a TRUSTED_AGENT.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param _from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function trustedAgentTransferFrom(
        address _from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely burns an asset token
     * @param _tokenId - Token ID to Burn
     */
    function trustedAgentBurn(uint256 _tokenId) external;

    /**
     * @dev Safely burns a token and sets the corresponding RGT to zero in storage.
     * @param _tokenId - Token ID to discard
     */
    function discard(uint256 _tokenId) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @dev externalized IAOO
     * @param _addr adress to check
     * @param _tokenId token to check
     */
    function isApprovedOrOwner(address _addr, uint256 _tokenId) external view;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        returns (address tokenHolderAdress);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external returns (string memory tokenSymbol);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external returns (uint256);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements
     *       -on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        returns (address);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external returns (bytes32);

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

//=========================================================================================================================================================================================================

/*
 * @dev Interface for MARKET_TKN
 * INHERITANCE:



 */
interface MARKET_TKN_Interface {
    /**
     * @dev Mint new consignment Tag token, store consignment data
     * @param _recipientAddress - Address to mint token into
     * @param _tokenId - Token ID to mint
     * @param _tokenURI - URI string to atatch to token
     * returns Token ID of minted token
     */
    function mintConsignmentToken(
        address _recipientAddress,
        uint256 _tokenId,
        string calldata _tokenURI
    ) external returns (uint256);

    /**
     * @dev Set new token URI String
     * @param _tokenId - Token ID to set URI
     * @param _tokenURI - URI string to atatch to token
     * returns Token ID
     */
    function setURI(uint256 _tokenId, string calldata _tokenURI)
        external
        returns (uint256);

    /**
     * @dev See if consignment token exists
     * @param _tokenId - Token ID to set URI
     * returns 170 if token exists, otherwise 0
     */
    function tokenExists(uint256 _tokenId) external view returns (uint256);

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    /**
     * @dev Safely burns an consignment token, consignment data
     * @param _tokenId - Token ID to Burn
     */
    function tagAdminBurn(uint256 _tokenId) external;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) external returns (string memory);

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        returns (address tokenHolderAdress);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external returns (string memory tokenSymbol);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external returns (uint256);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements
     *       -on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        returns (address);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external returns (bytes32);

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

//=========================================================================================================================================================================================================

// File: contracts/ReleaseCandidates/PRUF_A_TKN.sol

/*--------------------------------------------------------PRüF0.9.0
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\__/\\ ___/\\\\\\\\\\\\\\\        
__\/\\\/////////\\\ _/\\\///////\\\ ____\//__\//____\/\\\///////////__       
___\/\\\_______\/\\\_\/\\\_____\/\\\ ________________\/\\\ ____________      
____\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\_\/\\\\\\\\\\\ ____     
_____\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\_\/\\\///////______
______\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\_\/\\\ ____________
_______\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\_\/\\\ ____________
________\/\\\ ____________\/\\\ _____\//\\\_\//\\\\\\\\\ _\/\\\ ____________
_________\/// _____________\/// _______\/// __\///////// __\/// _____________
*---------------------------------------------------------------------------*/

/**-----------------------------------------------------------------
 * PRüF A_TKN
 * PRüF ASSET NFT CONTRACT - PRüF Asset tokens.
 *---------------------------------------------------------------*/

//  UNLICENSED
pragma solidity ^0.8.7;









/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract A_TKN is
    ReentrancyGuard,
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    //mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    //mapping for base URIs associated with the corresponding storageType
    mapping(uint8 => string) private baseURIforStorageType; //storageType => (index => URI)
    //mapping for coldWallet bool
    mapping(address => uint256) private coldWallet; //CTS EXAMINE does this need to be a uint256 if its just being used as a bool?

    Counters.Counter private _tokenIdTracker;

    uint256 trustedAgentEnabled = 1;

    bytes32 public constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRUSTED_AGENT_ROLE =
        keccak256("TRUSTED_AGENT_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    address internal STOR_Address;
    address internal RCLR_Address;
    address internal NODE_STOR_Address;
    address internal NODE_TKN_Address;

    STOR_Interface internal STOR;
    RCLR_Interface internal RCLR;
    NODE_STOR_Interface internal NODE_STOR;
    NODE_TKN_Interface internal NODE_TKN;

    //B320x01 is written to the rightsholder field in cases where no rightsholder has been declared after transfer
    bytes32 public constant B320x01 = 0x0000000000000000000000000000000000000000000000000000000000000001;

    constructor() ERC721("PRUF Asset Token", "PRAT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONTRACT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    //---------------------------------------Modifiers-------------------------------

    /**
     * @dev Verify user credentials
     * Originating Address:
     *      has CONTRACT_ADMIN_ROLE
     */
    modifier isContractAdmin() {
        require(
            hasRole(CONTRACT_ADMIN_ROLE, _msgSender()),
            "AT:MOD-ICA:Calling address does not belong to a contract admin"
        );
        _;
    }

    /**
     * @dev Verify user credentials
     * Originating Address:
     *      has MINTER_ROLE
     */
    modifier isMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AT:MOD-IM:Calling address does not belong to a minter"
        );
        _;
    }

    /**
     * @dev Verify user credentials
     * Originating Address:
     *      has TRUSTED_AGENT_ROLE and Trusted Agent role is not disabled
     */
    modifier isTrustedAgent() {
        require(
            hasRole(TRUSTED_AGENT_ROLE, _msgSender()),
            "AT:MOD-ITA:Must have TRUSTED_AGENT_ROLE"
        );
        require(
            trustedAgentEnabled == 1,
            "AT:MOD-ITA:Trusted Agent function permanently disabled - use allowance / transferFrom pattern"
        );
        _;
    }

    /**
     * @dev Verify user credentials
     * Originating Address:
     *      has DAO_ROLE
     */
    modifier isDAO() {
        require(
            hasRole(DAO_ROLE, _msgSender()),
            "AT:MOD-ID:Must have DAO_ROLE"
        );
        _;
    }

    //---------------------------------------Public Functions-------------------------------

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @param tokenId - token to have URI checked
     * @return URI of token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "AT:TU:nonexistent token");
        //^^^^^^^checks^^^^^^^^^

        Record memory rec = getRecord(bytes32(tokenId));
        Node memory nodeData = NODE_STOR.getNodeData(rec.node);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURIforStorageType[nodeData.storageProvider];

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override nonReentrant {
        bytes32 _idxHash = bytes32(_tokenId);
        Record memory rec = getRecord(_idxHash);

        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "AT:TF:Transfer caller is not owner nor approved"
        );
        require(
            rec.assetStatus == 51,
            "AT:TF:Asset not in transferrable status"
        );
        //^^^^^^^checks^^^^^^^^

        rec.numberOfTransfers = 170;

        rec.rightsHolder = B320x01;

        writeRecord(_idxHash, rec);
        _transfer(_from, _to, _tokenId);
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        //^^^^^^^checks^^^^^^^^

        safeTransferFrom(_from, _to, _tokenId, "");
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override nonReentrant {
        bytes32 _idxHash = bytes32(_tokenId);
        Record memory rec = getRecord(_idxHash);
        (uint8 isAuth, ) = STOR.ContractInfoHash(_to, 0); // trailing comma because does not use the returned hash

        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "AT:STF:Transfer caller !owner nor approved"
        );
        require( // ensure that status 70 assets are only sent to an actual PRUF contract
            (rec.assetStatus != 70) || (isAuth > 0),
            "AT:STF:Cannot send status 70 asset to unauthorized address"
        );
        require(
            (rec.assetStatus == 51) || (rec.assetStatus == 70),
            "AT:STF:Asset !in transferrable status"
        );
        require(
            _to != address(0),
            "AT:STF:Cannot transfer asset to zero address. Use discard."
        );
        //^^^^^^^checks^^^^^^^^^

        rec.numberOfTransfers = 170;
        rec.rightsHolder = B320x01;

        writeRecord(_idxHash, rec);
        _safeTransfer(_from, _to, _tokenId, _data);
        //^^^^^^^effects^^^^^^^^^
    }

    //---------------------------------------External Functions-------------------------------
    /**
     * @dev Sets the baseURI for a storage provider.
     * @param _storageProvider - storage provider number
     * @param _URI - baseURI to add
     */
    function setBaseURIforStorageType(
        uint8 _storageProvider,
        string calldata _URI
    ) external isDAO {
        //^^^^^^^checks^^^^^^^^^

        baseURIforStorageType[_storageProvider] = _URI;
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev returns a baseURI for a storage provider / index combination, as well as the total number of URIs.
     * @param _storageProvider - storage provider number
     */
    function getBaseURIforStorageType(uint8 _storageProvider)
        external
        view
        returns (string memory)
    {
        //^^^^^^^checks^^^^^^^^^

        return (baseURIforStorageType[_storageProvider]);
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev returns a baseURI for a storage provider / index combination, as well as the total number of URIs.
     * @param _node - node
     */
    function getBaseUriForNode(uint32 _node)
        external
        view
        returns (string memory)
    {
        Node memory thisNode = NODE_STOR.getNodeData(_node);
        uint8 storageProvider = thisNode.storageProvider;
        //^^^^^^^checks^^^^^^^^^

        return (baseURIforStorageType[storageProvider]);
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev !!! PERMANENTLY !!!  Kills trusted agent and payable functions
     * this will break the functionality of current payment mechanisms.
     *
     * The workaround for this is to create an allowance for pruf contracts for a single or multiple payments,
     * either ahead of time "loading up your PRUF account" or on demand with an operation. On demand will use quite a bit more gas.
     * "preloading" should be pretty gas efficient, but will add an extra step to the workflow, requiring users to have sufficient
     * PRuF "banked" in an allowance for use in the system.
     * @param _key - set to 170 to PERMENANTLY REMOVE TRUSTED AGENT CAPABILITY
     */
    function killTrustedAgent(uint256 _key) external isDAO {
        //^^^^^^^checks^^^^^^^^^

        if (_key == 170) {
            trustedAgentEnabled = 0; // !!! THIS IS A PERMANENT ACTION AND CANNOT BE UNDONE
        }
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Set storage contract to interface with
     * @param _storageAddress - Storage contract address
     */
    function setStorageContract(address _storageAddress)
        external
        isContractAdmin
    {
        require(_storageAddress != address(0), "AT:SSC:Storage address = 0");
        //^^^^^^^checks^^^^^^^^^

        STOR = STOR_Interface(_storageAddress);
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Address Setters  - resolves addresses from storage and sets local interfaces
     */
    function resolveContractAddresses() external isContractAdmin {
        //^^^^^^^checks^^^^^^^^^

        RCLR_Address = STOR.resolveContractAddress("RCLR");
        RCLR = RCLR_Interface(RCLR_Address);

        NODE_STOR_Address = STOR.resolveContractAddress("NODE_STOR");
        NODE_STOR = NODE_STOR_Interface(NODE_STOR_Address);

        NODE_TKN_Address = STOR.resolveContractAddress("NODE_TKN");
        NODE_TKN = NODE_TKN_Interface(NODE_TKN_Address);
        //^^^^^^^effects/interactions^^^^^^^^^
    }

    /**
     * @dev return an adresses "cold wallet" status
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS
     * @param _addr - address to check
     * @return 170 if adress is set to "cold wallet" status
     */
    function isColdWallet(address _addr) public view returns (uint256) {
        return coldWallet[_addr];
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev Set calling wallet to a "cold Wallet" that cannot be manipulated by TRUSTED_AGENT or PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function setColdWallet() external {
        coldWallet[_msgSender()] = 170;
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev un-set calling wallet to a "cold Wallet", enabling manipulation by TRUSTED_AGENT and PAYABLE permissioned functions
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS and must be unset from cold before it can interact with
     * contract functions.
     */
    function unSetColdWallet() external {
        //^^^^^^^checks^^^^^^^^^

        coldWallet[_msgSender()] = 0;
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Mint an Asset token (may mint only to node holder depending on flags)
     * @param _recipientAddress - Address to mint token into
     * @param _tokenId - Token ID to mint
     * @param _URIsuffix - URI suffix
     * @return Token ID of minted token
     */
    function mintAssetToken(
        address _recipientAddress,
        uint256 _tokenId,
        string memory _URIsuffix
    ) external isMinter nonReentrant returns (uint256) {
        //^^^^^^^checks^^^^^^^^^

        _safeMint(_recipientAddress, _tokenId);

        _setTokenURI(_tokenId, _URIsuffix);
        //^^^^^^^effects^^^^^^^^^

        return (_tokenId);
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev Set new token URI String, under special circumstances
     * only works if asset is in stat 201.
     * Conceptually, the nodeHolder would deploy a contract to update URI for assets. that contract would
     * hold the node or be auth100. TH would authorize the contract for their token, and
     * call the updateMyURI function in that contract. The update function would set stat201, then
     * call this function to update the URI to the new value, then unset the 201 status.
     * @param _tokenId - Token ID to set URI
     * @param _tokenURI - URI string to atatch to token
     * @return tokenId
     */
    function setURI(uint256 _tokenId, string calldata _tokenURI)
        external
        returns (uint256)
    {
        bytes32 _idxHash = bytes32(_tokenId);
        Record memory rec = getRecord(_idxHash);
        uint256 bit6 = NODE_STOR.getSwitchAt(rec.node, 6);

        require(
            rec.assetStatus == 201,
            "AT:SU:URI Immutable Record status != 201"
        );

        require(
            (NODE_TKN.ownerOf(rec.node) == _msgSender()) || //caller holds the Node
                (NODE_STOR.getUserType(
                    keccak256(abi.encodePacked(_msgSender())),
                    rec.node
                ) == 100), //or is auth type 100 in Node
            "AT:SU:Caller !NTH or authorized"
        );
        
        if (bit6 == 1) {
            ExtendedNodeData memory extendedNodeInfo = NODE_STOR
                .getExtendedNodeData(rec.node);
            require(
                (NODE_TKN.ownerOf(rec.node) ==
                    IERC721(extendedNodeInfo.idProviderAddr).ownerOf(
                        extendedNodeInfo.idProviderTokenId
                    )), // if switch6 = 1 verify that IDroot token and Node token are held in the same address
                "AT:SU: Node and root of identity are separated. URI Update is disabled"
            );
        }

        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "AT:SU:Caller !owner nor approved"
        );
        //^^^^^^^checks^^^^^^^^^

        _setTokenURI(_tokenId, _tokenURI);
        return _tokenId;
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev See if asset token exists
     * @param tokenId - Token ID to set URI
     * @return 170 if token exists, otherwise 0
     */
    function tokenExists(uint256 tokenId) external view returns (uint256) {
        //^^^^^^^checks^^^^^^^^^

        if (_exists(tokenId)) {
            return 170;
        } else {
            return 0;
        }
        //^^^^^^^interactions^^^^^^^^^
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address by a TRUSTED_AGENT.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function trustedAgentTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external nonReentrant isTrustedAgent {
        bytes32 _idxHash = bytes32(_tokenId);
        Record memory rec = getRecord(_idxHash);

        require(
            rec.assetStatus == 51,
            "AT:TATF:Asset not in transferrable status"
        );
        require(
            isColdWallet(ownerOf(_tokenId)) != 170,
            "AT:TATF:Holder is cold Wallet"
        );
        //^^^^^^^checks^^^^^^^^

        rec.numberOfTransfers = 170;

        rec.rightsHolder = B320x01;

        writeRecord(_idxHash, rec);
        _transfer(_from, _to, _tokenId);
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Safely burns an asset token
     * @param _tokenId - Token ID to Burn
     */
    function trustedAgentBurn(uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
        isTrustedAgent
    {
        require(
            isColdWallet(ownerOf(_tokenId)) != 170,
            "AT:TAB:Holder is cold Wallet"
        );
        //^^^^^^^checks^^^^^^^^^

        _burn(_tokenId);
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Safely burns a token and sets the corresponding RGT to zero in storage.
     * @param _tokenId - Token ID to discard
     */
    function discard(uint256 _tokenId) external nonReentrant whenNotPaused {
        bytes32 _idxHash = bytes32(_tokenId);

        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "AT:D:Transfer caller !owner nor approved"
        );
        //^^^^^^^checks^^^^^^^^^

        RCLR.discard(_idxHash, _msgSender());
        //^^^^^^^interactions^^^^^^^^^

        _burn(_tokenId);
        //^^^^^^^effects^^^^^^^^^ (out of order here, but verified and necescary)
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "AT:P:Caller !have pauser role"
        );
        //^^^^^^^checks^^^^^^^^^

        _pause();
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "AT:UP:Caller !have pauser role"
        );
        //^^^^^^^checks^^^^^^^^^

        _unpause();
        //^^^^^^^effects^^^^^^^^^
    }

    function isApprovedOrOwner(address _addr, uint256 _tokenId) external view {
        require(
            _isApprovedOrOwner(_addr, _tokenId),
            "AT:IAOO:Not approved or owner"
        );
    }

    //---------------------------------------Internal Functions-------------------------------

    /**
     * @dev Get a Record from Storage @ idxHash and return a Record Struct
     * @param _idxHash - Asset Index
     * @return Record Struct (see interfaces for struct definitions)
     */
    function getRecord(bytes32 _idxHash) internal view returns (Record memory) {
        //^^^^^^^checks^^^^^^^^^

        Record memory rec = STOR.retrieveRecord(_idxHash);

        return rec; // Returns Record struct rec
        //^^^^^^^Interactions^^^^^^^^^
    }

    /**
     * @dev all paused functions are blocked here (inside ERC720Pausable.sol)
     * @param _from - from address
     * @param _to - to address
     * @param _tokenId - token ID to transfer
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * @param tokenId - token to be burned
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     * @param tokenId - token URI will be added to
     * @param _tokenURI - URI of token
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "AT:STU:URI set of nonexistent token");
        //^^^^^^^checks^^^^^^^^^

        _tokenURIs[tokenId] = _tokenURI;
        //^^^^^^^effects^^^^^^^^^
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * @return supported interfaceId
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
        //^^^^^^^interactions^^^^^^^^^
    }

    //---------------------------------------Private Functions-------------------------------

    /**
     * @dev Write a Record to Storage @ idxHash
     * @param _idxHash - Asset Index
     * @param _rec - Complete Record Struct (see interfaces for struct definitions)
     */
    function writeRecord(bytes32 _idxHash, Record memory _rec)
        private
        whenNotPaused
    {
        //^^^^^^^checks^^^^^^^^^

        STOR.modifyRecord(
            _idxHash,
            _rec.rightsHolder,
            _rec.assetStatus,
            _rec.countDown,
            _rec.int32temp,
            _rec.modCount,
            _rec.numberOfTransfers
        ); // Send data and writehash to storage
        //^^^^^^^interactions^^^^^^^^^
    }
}