/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



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


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}



/*                                                                                                                                                                                                                                                                                                        
                             [email protected]@[email protected]@                                                                                                                 
                             [email protected]@@[email protected]@                                                                                                                 
                             [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@@@@@@@[email protected]@[email protected]@.                                                                       
                             [email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@@[email protected]@@@@[email protected]
[email protected]kPkXkqOr                                                            
                  [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]
[email protected]@[email protected]@[email protected]:rJ                                                         
                  [email protected]@[email protected][email protected]@.                                                        
                  [email protected]@BMMB[email protected]Bi .,                                                     
                      @[email protected]@MM[email protected][email protected]@@                                                     
                      [email protected]@BMM[email protected]@@B                                                     
                          @BMMBMB[email protected][email protected]@                                                 
                          [email protected][email protected]@@8                                                 
                      @[email protected][email protected]@[email protected]@B,                                         
                      [email protected]@BBMMMBMMMBMB[email protected][email protected]@[email protected]                                          
                      @@BMBMMMMMMMMMMMMMMMM[email protected]@q10Z                                      
                      [email protected][email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]                                      
                      @[email protected][email protected];iLr                                  
                      [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@                                  
                  .,  @[email protected][email protected]@O                                  
                  [email protected]@[email protected]::::::::[email protected]@[email protected]@BGP88::i:::::vriSM0ENZBk                                  
                  [email protected]@BBMBMBMMMMMBMBMMMBMBMMMMMBMBMBB0qZEEEMF7vYiiiii;i;[email protected]@EqGMiii;:i:rYvrP8ZNZ0B1                                  
              [email protected]@[email protected]@NkPZrr77,:::::::::::::::::.       kGkXSPSXSPZi.::    .  .i::::,:ir;[email protected]@BJ                              
              [email protected]@[email protected]::.,.,.,.,.,..,        PEPkXSPSXX8:..:        ::,,.,[email protected]                              
              :@[email protected]:iii.. [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@BBNZB7                              
              [email protected]@[email protected]@[email protected]@[email protected]@BMZBBi:ii.. [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@r                              
           [email protected]:iii...:ri:[email protected]@Xr7Liiiiiiiiii:[email protected]@[email protected]
[email protected]@[email protected]@[email protected]:;i...    ,i:::::[email protected]::                       ::[email protected]:::::,,[email protected]                              
           @[email protected];,:::::,ii;iiiiiNFNL:ir::,::::::::,...::::::,:ri:70SNrii;:i:iMOB7                              
           @@[email protected]::::i:::i::[email protected];iir;7rrrr;ririi:::iirrririr;r;rir:...ir;ririrrrii:::iirri:::[email protected]                              
       :. [email protected]@X5kqiiiii;i;[email protected]@GPNML7LYrrrriiir77rrir;ririiiiirrri;i;iri;i;;i,:,ii;iririrrriiiii;ir;;:rO8B7                              
       [email protected]@BBBG5q8i.::iiiiiiiii:irL7v::,[email protected];iririr;ririr;rrrrr;rrrrrr777r7rrrrrrrr;ri;iri;[email protected]                              
       @[email protected]@GPNBr::ii;iiii:iri:7vLLi::[email protected]@GPNMY7LLLYLLiri7JjJ7ir;r;rrr;rrrir;r;rrrrr;r;rrrrrrrrrrrrririr;riri;LJ7LO8B7                              
       [email protected]@: ......i::[email protected]:::[email protected];ii:iir;r;rrrrrrriii;iiii:i::::irrrrrrrii:::::[email protected]                              
       @[email protected]@: .,....::[email protected]:,,:@[email protected]:i:rrrr7r7r777rii;irii::,:,::ir77777;:::,:,:[email protected]                              
       @@MMMBBOXZB: ,.,..,@[email protected];iriiir...,.,.:iri:.. [email protected] ..... ZMZ8Z8MU:i:7YLvGGBF                                  
       @[email protected]@: .... ,BMBPrvvv7r;@[email protected]@GPNOY7vLLLvLLJJvir;iiii.....  :7rr.   [email protected]@[email protected] [email protected]@[email protected],,,ruLL8MBq                                  
       [email protected],::i:::[email protected]@MMMBBOSE8JrLLLLLvYLj7iiriiir...,iii:,,.JX5u2JuYjJuu5151F12uuJjJjYUSkPv;r:[email protected]                                  
       @[email protected]:iiii:iM8Mu:[email protected]@[email protected]:   [email protected]@r:ii:i:[email protected]@[email protected]:iii::[email protected]@vi::EOBN                                  
   iY;:[email protected];rMEMu::[email protected]::::;;iiii:uqF15U1U5USuujuuuJj1F21U1251kP7ii:[email protected]                                  
   @@@@@[email protected]:::::[email protected]@[email protected]:iirrrii:[email protected]@[email protected]@1.:::::[email protected]@[email protected];[email protected]
[email protected]::[email protected];ii;iiiirri7LLvYvv7NNNqkkZJ::iii::qZqqPN01rvv7iiiqqG2  ,                               
   [email protected]@@@O8MB:::[email protected]@BL::[email protected]@NXPEEOOZ;7777vvrirriiii5u2viiivuYY7v77:::iirrr;riv77777vrii;;r;;ii:[email protected]
[email protected]:iiLv72B8Mvi::[email protected];JJYviriLJJYJLYv;i;;rrrrri;LJvLLYYvirrr;r;[email protected]
[email protected]::::::,[email protected]@[email protected]@08GOOMB27YLririi:i:iir.  . . .iiiiiiiiii:i:i:::i:ii;....ii:iBOBr                              
   [email protected],.,,:,,[email protected]:::i:rr, ......riiiiiiiiiiiiiiiiiiiii, . ii:[email protected]@i                              
[email protected]@[email protected][email protected]@u  .:iii:i:i:i:i:i:i:i:i:i:i:i:i:i:i:iii:iJYv1GOB,                          
@[email protected]@[email protected]@[email protected]@B5   .::,:,:,,,,,,,,,:,:,:,,,,,,,,,:,:,:,,,[email protected]@.                          
MBMBMMMBMMMBMMMMMMMBMBOMOMMMMMMMOMBBMBMMMMMMMMMMMBMBMMBMk08FrL7uuUur;;[email protected]
[email protected]@[email protected]@[email protected]@MPqO57vL777v:iii::[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]                          
MMMMMMMMMBMBMMMMMMMMMMMBMBMBMMMMMBMBMBMMMMMMMMMMMMMMMBBMk08FrLvLvYLii;[email protected]@[email protected]@[email protected]@P;r;[email protected]@U1F57Lr2O8B.                          
[email protected]LLYiii;irii,, [email protected]    @[email protected]:,:,:,,.,@@Br   [email protected],,[email protected]                          
MMMBMBMMMBMBMMMMMBMMMMMMMBMMMBMBMMMMMMMMMMMBMMMMMMMMMMMMk085rLvLvYLrrrrr;rii:,[email protected]@@    [email protected]::i:i:i::[email protected]@v   [email protected]@:::iJLr2OOB.                          
BMBMMMMMMMBMBMBMMMMMMMBMMMMMBMBMBMBMMMMMMMMMBMMMMMBMMMBOkX8Ui777LvLLJjJir;;ii,[email protected]    @[email protected]::iiii;ii:[email protected]@v   [email protected]::[email protected]                          
MMMMMBMMMMMMMMMMMMMMMBMMMMMBMBMMMBMBMBMBMMMMMBMMMMMBMMMMS0G5rvvL7LvYLJv;;r;ii:[email protected]@@    [email protected]:iiiiiiii:[email protected]@@v   [email protected]@:i:iYLrU8OB.                          
[email protected]7vLvLLLiririi::,,,@[email protected],,::iiiiiiiiii:::[email protected]@BL.,:[email protected]                           
MMMMMMMMMMMMMMMBMMMMMMMMMBMMMBMBMBMBMBMMMMMMMMMBMBMBMMMMMBBOXZMurLvLvJviiriiii::::[email protected]@,::iiiiiiiiiiii:::[email protected]@v:::iiii77ijE0B                           
[email protected]rvLvLLLvLYvirriii:iiii:iii;iiiiiiiiiiii:[email protected]@[email protected]@                       
MMMMMBMMMMMBMBMMMBMMMMMMMMMBMBMMMMMBMMMMMMMBMMMBMMMMMMMBMBBOkEOvi7rLvLLJLu7iirii:i:::::iiiiiiiiii;iiiiii::::iri;[email protected]@[email protected]@B                       
[email protected]kP0vvvLvLLv7vvri;ii:iiii;iii;i;i;iii;i;iiii:;;;[email protected]@2k8F                   
[email protected]@[email protected]@B7irrrr77jYur;i;:i:iiiiiiiiiiiiiiiiiiiiiiii;[email protected]@B                   
BMMMMMBMMMMMMMBMBMMMBMBMBMMMBMBMMMMMMMMMMMMMMMBMMMBMOGOGOOBNu251F152511UFFu7LL7r7rrr7riiiiiiii;i;i;iii;i;[email protected]@@M                   
[email protected]@[email protected]@[email protected]@Xir77v7v7vvv:i:i:i:iiiii:iii:iii:[email protected]@@[email protected]                   
BOMMBMMMMMMMBMBMMMMMMMMMMMMMMMMMBMMMMMMMMMMMBMBBMOBMk5XXq[email protected]OMMBMMMBBO .,                
[email protected];iiii:::[email protected]@[email protected]@@@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]
[email protected]@8PGGL7LvLvJ7iiririri;[email protected]@@BL               
[email protected]:iii:i:i;rrriii;iiii:::i::rL7v::::77r7r777777v7Lr:::iL7vi::iiiiii;[email protected]@[email protected]:           
[email protected]:iirr7i;;r;r;rii:iiii7LYLiiiiLvv7v7v7v7vvLLviii7YLYriii;;[email protected]@[email protected]@@@B,           
MMMBMMMMMBMMMMMBMMMMMBMMMMMMMMMBMMMMMMMBMPq82rvJ;iirLJYLir;ri;i:......,7rrrri;ir;ririrJYLLLLvLLYLrir;iiiir;riiiiiii;iriiii:[email protected]           
BMMMMMMMMMMMMMBMBMBMMMMMBMBMMMBMMMMMMMBBMFNZ2i7vri;iuu1Jr;r;ii;.  . . .77rr;riririr;;rUJjLLLYLjjuir;ririrrrii:i:iiiirrri:::[email protected]@.           
[email protected];ririrrrri:i:i:i:riiirrri;irrrirr7;7LYL7r7riiri,,,:riiir;riiiirri7vL77r;:[email protected]@.           
BMMMBMMMMMMMBMBMMMBMMMMMMMBMMMMMMMMMMMMBMX0Okrju7ir;i:ii;i;r7r7;;iri;i;iii;rrr;i;i7rr;riirUJUriiri;;i   :rri7rrriiii7r7vFu2ri::[email protected]@            
[email protected]:::irriririririiiiir;7::::irirrrirv77rirr:::::::::::ir;;iiii:::[email protected]@virY        
MMMMBMBMBMMMBMMMMMMMBMMMMMBMMMMMMMMMMMMBMXEOu:iirr7rri;:   ,riir7r7rrrriiirrrr, . ;;;i7rriri;;rr7   .rrr: . :iiiiir:   ,[email protected]@@B        
[email protected]:iriiiii;ii,:,:ii:iiiirrr;iiiirr7:,,,:i:irrir;r;;irr,,,:rir:,,,:;iii;ii.,.:[email protected]@[email protected]        
BMMMMMMMMMBMMMBMMMBMBMMMMMMMMMMMMMBMBMMBMkEM2:rr, . ii;irrr:.....  iri;iriiiii;irr....riiirrriiii;7rri;irrrrriiiiiiir;r;[email protected]
[email protected]:ir,...i;irir;:.,.,...iiri;i;i;i;i;ir...,;;ir;rr;i;i;iriririr;ii;i;iiiiiiir;[email protected]@        
BOMMBMMMMMMMMMMMMMMMMMBMMMBMMMMMMMBMBMBBMkNOu:iiiiri;i;irir:...i7rr...... :rririrr,..,7rr;iiiirr7...,;ri: . iiririii7rr;[email protected]
[email protected]::i:i:iiiir;rr:...ir7r.......:r;rrrr7.,.:77rriiir;r7,..,7r7:...:7rriii;rr;;ii:77r;[email protected]@        
BMBMMMMMMMMMBMMMMMBMMMBMMMMMMMMMBMMMMMMMBMBBMXGOu7JYiiri...:r;r:,.,i;i;irii.,.,,,,,..,ri;iiii;rr7...,,,.:;ri:...;[email protected]@B        
[email protected] . :rrr,...rrr;rir:........,.,r;iiiiirr77..,....:7;7,...iri;rrirLv;[email protected]@@        
*/
pragma solidity >=0.8.0 <0.9.0;

contract KJCTest is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string private baseURI; // 
    string private generatedMythicBaseURI; //
    string public baseExtension = ".json"; //
    string public generatedMythicBaseExtension; //*//
    string public notRevealedUri; //
    string public generatedMythicNotRevealedUri; //
    string public ogProvenanceHash; 
    string public generatedMythicsProvenanceHash; //
    uint256 public preSaleCost = 0.001 ether; //*//
    uint256 public cost = 0.002 ether; //*//  
    uint256 public maxSupply = 20; //*//
    uint256 public preSaleMaxSupply = 6;//*// 
    uint256 public maxMintAmountPresale = 2; // 
    uint256 public maxMintAmount = 10; // 
    uint256 public nftPerAddressLimitPresale = 4; //*//
    uint256 public nftPerAddressLimit = 12; //*//
    uint256 public preSaleDate = 1648670400; //*// Test date of March 30, 4PM EST
    uint256 public publicSaleDate = 1648756800; //*// Test date of March 31, 4PM EST
    uint256 public freeMintReserve = 2; //*//
    uint256 public fusedMythicCount = 0; // Number of new Mythics minted through fusion thus far
    uint256 public maxMythicSupply = 10; //*// Maximum number of new Mythics that can be minted through fusion
    uint256 public chargeRequirement = 10 weeks; //*//
    uint256 public mythicRevealGap = 1 weeks; //*// Time after publicSaleDate + chargeRequirement, at which point Mythics minted through fusion will be automatically revealed
    uint256 public revealGap = 1 weeks; //*// Time after publicSaleDate, at which point minted Kongenzaz 1 through maxSupply will be automatically revealed
    bool public paused = false; //
    bool public isHolderActive = false; // 
    bool public fusionPaused = false; //
    bool public noSmartContracts = true; //

    mapping(address => uint256) public addressMintedBalance;
    mapping(uint256 => uint256) public timeOfAcquisitionOrLastFusion; //reset on mint, transfer, and fusion

    constructor(string memory _name, string memory _symbol, string memory _initNotRevealedUri) ERC721(_name, _symbol) {
        setNotRevealedURI(_initNotRevealedUri);
    }

    bytes32 public merkleRoot = 0x364b472ce5cccc92514d33a9bef873943c3d59e219430f934429ee91acc9c948;//*//

    address public holderContractAddress;//*//
   
    event provenanceHashesSet(string _ogHash, string _mythicHash);
    event CostChanged(uint256 _currentCost);
    event KongenzazMinted(address indexed _to, uint256 indexed _totalSupply);
    event NewMythicMinted(uint256 _mythicId, uint256 _kongenzaOne, uint256 _kongenzaTwo, address indexed _fuserAddress); 

    /* 
        * PROVENANCE SETTER ONLY OWNER
        
        * @dev
        * ogProvenanceHash: the SHA-256 hash of the IPFS hash of the metadata for Kongenzaz numbers 1 through maxSupply.
        * generatedMythicsProvenanceHash: the SHA-256 hash of the IPFS hash of the metadata for the Mythic Kongenzaz
          that can be minted (through fusion) by owners of Kongenzaz numbers 1 through maxSupply.
        * The metadata of each Kongenza contains the IPFS hash of its GIF.
        * Each provenance hash is set here prior to the commencment of the presale.
    */
    function setProvenanceHashes(string memory _ogHash, string memory _mythicHash) public presaleNotBegun onlyOwner {
        ogProvenanceHash = _ogHash;
        generatedMythicsProvenanceHash = _mythicHash;
        emit provenanceHashesSet(_ogHash, _mythicHash);
    }


    //ONLY OWNER FUSION SETTERS    
    function setMaxMythicSupply(uint256 _newMaxMythicSupply) public presaleNotBegun onlyOwner {
        maxMythicSupply = _newMaxMythicSupply;
    }

    function setChargeRequirement (uint256 _newChargeRequirement) public presaleNotBegun onlyOwner {
        chargeRequirement = _newChargeRequirement;
    }

    function setMythicRevealGap (uint256 _newMythicRevealGapInSeconds) public presaleNotBegun onlyOwner {
        mythicRevealGap = _newMythicRevealGapInSeconds;
    }    

    //FUSION FUNCTION
    function fusion(uint256 _kongenzaOne, uint256 _kongenzaTwo) public allowedSender {
        require(!fusionPaused, "Fusion is paused");
        require(sufficientMythicSupply(), "Maximum Mythic supply reached");
        require(nonZeroIDs(_kongenzaOne, _kongenzaTwo), "An ID cannot be 0");
        require(noGeneratedMythicsInIds(_kongenzaOne, _kongenzaTwo), "Cannot fuse using generated Mythics");
        require(allIdsUnique(_kongenzaOne, _kongenzaTwo), "You must enter unique Kongenzaz");
        require(ownerOfAllIds(_kongenzaOne, _kongenzaTwo), "You must enter Kongenzaz that you own");
        require(allCharged(_kongenzaOne, _kongenzaTwo), "You must enter Kongenzaz that are charged"); 
        resetTimeOfAcquisitionOrLastFusion(_kongenzaOne, _kongenzaTwo);
        fusedMythicCount++;
        uint256 _mythicId = getRandomIdForMythic(_kongenzaOne);
        _mint(msg.sender, _mythicId);
        emit NewMythicMinted(_mythicId, _kongenzaOne, _kongenzaTwo, msg.sender);
    }
    

    //INTERNAL VIEW FUSION FUNCTIONS
    function getRandomIdForMythic(uint256 _kongenzaOne) internal view returns (uint256) { 
        uint256 _randomIdForMythic = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, fusedMythicCount, msg.sender, _kongenzaOne))) % maxMythicSupply) + maxSupply + 1;
        if(_exists(_randomIdForMythic)){
            for (uint256 i = 1; i < maxMythicSupply; i++) {
                if((_randomIdForMythic - i > maxSupply) && (_randomIdForMythic - i <= maxSupply + maxMythicSupply)){
                    if(!_exists(_randomIdForMythic - i)){
                        return _randomIdForMythic - i;
                    }
                }
                if((_randomIdForMythic + i > maxSupply) && (_randomIdForMythic + i <= maxSupply + maxMythicSupply)){
                    if(!_exists(_randomIdForMythic + i)){
                        return _randomIdForMythic + i;
                    }
                }
            }
        }
        require(((_randomIdForMythic > maxSupply) && (_randomIdForMythic <= maxSupply + maxMythicSupply)), "mythicId out of range");
        return _randomIdForMythic;     
    }

    function sufficientMythicSupply() internal view returns (bool) {
        return fusedMythicCount < maxMythicSupply;
    }

    function nonZeroIDs(uint256 _kongenzaOne, uint256 _kongenzaTwo) internal pure returns (bool) {
        if (_kongenzaOne > 0 && _kongenzaTwo > 0) {
            return true;
        }
        else {
            return false;
        }
    }
 
    function noGeneratedMythicsInIds(uint256 _kongenzaOne, uint256 _kongenzaTwo) internal view returns (bool) {
        if (_kongenzaOne > maxSupply || _kongenzaTwo > maxSupply) {
            return false;
        }
        else {
           return true;  
        }
    }

    function ownerOfAllIds(uint256 _kongenzaOne, uint256 _kongenzaTwo) internal view returns (bool) {
        if (ownerOf(_kongenzaOne) != msg.sender || ownerOf(_kongenzaTwo) != msg.sender) {
            return false;
        }
        else {
            return true;
        }
    }

    function allIdsUnique(uint256 _kongenzaOne, uint256 _kongenzaTwo) internal pure returns (bool) {
        if (_kongenzaOne == _kongenzaTwo) {
            return false;
        }
        return true;
    }

    function allCharged(uint256 _kongenzaOne, uint256 _kongenzaTwo) internal view returns (bool) {
        if (isCharged(_kongenzaOne) && isCharged(_kongenzaTwo)) {
            return true;
        }
        else {
            return false;
        }
    }

    function isCharged(uint256 _id) internal view returns (bool) { 
        require(_exists(_id), "ID does not exist"); 
        require((_id <= maxSupply), "Generated Mythics do not charge");
        if ((block.timestamp - timeOfAcquisitionOrLastFusion[_id]) >= chargeRequirement) {
            return true;
        }
        else {
            return false;
        }
    }

    function _generatedMythicBaseURI() internal view returns (string memory) {
        return generatedMythicBaseURI;
    } 

    //INTERNAL STATE FUSION FUNCTIONS
    function resetTimeOfAcquisitionOrLastFusion(uint256 _kongenzaOne, uint256 _kongenzaTwo) internal {
        timeOfAcquisitionOrLastFusion[_kongenzaOne] = block.timestamp;
        timeOfAcquisitionOrLastFusion[_kongenzaTwo] = block.timestamp;
    }


    //PUBLIC VIEW FUSION FUNCTIONS
    function timeUntilCharged(uint256 _id) public view returns (uint256) { 
        require((_id <= maxSupply), "Generated Mythics do not charge");
        if (isCharged(_id)) {
            return 0;
        }
        else {
            return timeOfAcquisitionOrLastFusion[_id] + chargeRequirement - block.timestamp;
        }
    }

    function isMythicsRevealed() public view returns (bool) {
        if (block.timestamp > publicSaleDate + chargeRequirement + mythicRevealGap) {
            return true;
        }
        else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        timeOfAcquisitionOrLastFusion[tokenId] = block.timestamp;
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        timeOfAcquisitionOrLastFusion[tokenId] = block.timestamp;
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    
    //MINT MODIFIERS
    modifier notPaused {
         require(!paused, "the contract is paused");
         _;
    }

    modifier presaleNotBegun {
        require(block.timestamp < preSaleDate, "presale has begun");
        _;
    }

    modifier saleStarted {
        require(block.timestamp >= preSaleDate, "Sale has not started yet");
        _;
    }

    modifier minimumMintAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "must mint at least 1 KONGENZA");
        _;
    }

    modifier allowedSender {
        if (noSmartContracts) {
            require(msg.sender == tx.origin, "No smart contracts");
        }
        _;
    }

    //INTERNAL MINT FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
   
    function presaleValidations(uint256 _ownerMintedCount, uint256 _mintAmount, uint256 _supply, bytes32[] memory _proof) internal {
        require(isWhitelisted(_proof, msg.sender), "not eligible for presale");
        require(_ownerMintedCount + _mintAmount <= nftPerAddressLimitPresale, "max supply per address exceeded for presale");
        require(msg.value >= preSaleCost * _mintAmount, "insufficient funds");
        require(_mintAmount <= maxMintAmountPresale,"max mint amount per presale transaction exceeded");
        require(_supply + _mintAmount <= preSaleMaxSupply,"presale supply exceeded");
    }

    function publicsaleValidations(uint256 _ownerMintedCount, uint256 _mintAmount) internal {
        require(_ownerMintedCount + _mintAmount <= nftPerAddressLimit,"max supply per address exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        require(_mintAmount <= maxMintAmount,"max mint amount per transaction exceeded");
    }

    //PUBLIC MINT FUNCTION
    function mint(uint256 _mintAmount, bytes32[] memory _proof) public payable notPaused saleStarted allowedSender minimumMintAmount(_mintAmount) {
        uint256 supply = totalSupply();
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        block.timestamp < publicSaleDate ? presaleValidations(ownerMintedCount, _mintAmount, supply, _proof) : publicsaleValidations(ownerMintedCount, _mintAmount);

        require((supply + _mintAmount) <= (maxSupply - freeMintReserve), "max supply exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            if (block.timestamp < publicSaleDate) { 
                addressMintedBalance[msg.sender]++; //unnecessary check during public sale
            }
            timeOfAcquisitionOrLastFusion[supply + i] = block.timestamp;    
            _mint(msg.sender, supply + i);
        }
        emit KongenzazMinted(msg.sender, totalSupply());
    }

   
    //MINT GRATIS FUNCTION
    //E.g., for those who, prior to sale, earned giveaways
    function freeMint(uint256 _mintAmount, address _destination) public onlyOwner {
        require(_mintAmount > 0, "need to mint at least 1 KONGENZA");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max supply exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            timeOfAcquisitionOrLastFusion[supply + i] = block.timestamp;   
            _mint(_destination, supply + i);
        }
    }

    //PUBLIC VIEWS
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function getRevealDate() public view returns (uint256) {
        return publicSaleDate + revealGap;
    }

    function isHolder(address _wallet) public view returns (bool) {
        if (holderContractAddress == address(0)) {
            return false;
        }
        ERC721Enumerable _nftContract = ERC721Enumerable(holderContractAddress);
        uint256 _nftBalance = _nftContract.balanceOf(_wallet);
        return (_nftBalance > 0);
    }

    function isInMerkle(bytes32[] memory _proof, address _userAddress) public view returns (bool){
        if (_proof.length == 0) {
            return false;
        }
        bytes32 _leaf = keccak256(abi.encodePacked(_userAddress));
        if (MerkleProof.verify(_proof, merkleRoot, _leaf)) {
            return true;
        }
        else {
            return false;
        }
    }

    function isWhitelisted(bytes32[] memory _proof, address _userAddress) public view returns (bool) {
        if (isHolderActive && isHolder(_userAddress)) {
            return true;  
        }
        else if (isInMerkle(_proof, _userAddress)) {
            return true;
        }
        else {
            return false;
        }
    }

    function isRevealed() public view returns (bool) {
        if (block.timestamp >= getRevealDate()) {
            return true;
        }
        else {
            return false;
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!isRevealed()) {
            return notRevealedUri;
        } 
        else if (tokenId <= maxSupply) {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(), baseExtension)) : "";
        }
        else {
            if (!isMythicsRevealed()) {
                return generatedMythicNotRevealedUri;
            }
            else {
                string memory currentMythicBaseURI = _generatedMythicBaseURI();
                return bytes(currentMythicBaseURI).length > 0 ? string(abi.encodePacked(currentMythicBaseURI,tokenId.toString(), generatedMythicBaseExtension)) : "";
            }
        }
    }

    function getCurrentCost() public view returns (uint256) {
        if (block.timestamp < publicSaleDate) {
            return preSaleCost;
        } else {
            return cost;
        }
    }

    //PUBLIC ONLY OWNER VIEWS
    function getBaseURI() public view onlyOwner returns (string memory) {
        return baseURI;
    }

    function getGeneratedMythicBaseURI() public view onlyOwner returns (string memory) {
        return generatedMythicBaseURI;
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    //PUBLIC ONLY OWNER SETTERS
    function setNoSmartContracts(bool _noContracts) public onlyOwner {
        noSmartContracts = _noContracts;
    }

    function setIsHolderActive(bool _newIsHolderActive) public onlyOwner {
        isHolderActive = _newIsHolderActive;
    }

    function setHolderContractAddress(address _newHolderContractAddress) public onlyOwner {
        holderContractAddress = _newHolderContractAddress;
    }

    function setFreeMintReserve(uint256 _newFreeMintReserve) public onlyOwner {
        freeMintReserve = _newFreeMintReserve;
    } 

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFusionPaused(bool _pauseFusion) public onlyOwner {
        fusionPaused = _pauseFusion;
    }
    
    function setNftPerAddressLimitPreSale(uint256 _limit) public onlyOwner {
        nftPerAddressLimitPresale = _limit;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setPresaleCost(uint256 _newPresaleCost) public onlyOwner {
        preSaleCost = _newPresaleCost;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
        emit CostChanged(cost);
    }
    
    function setmaxMintAmountPreSale(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmountPresale = _newmaxMintAmount;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setGeneratedMythicBaseURI(string memory _newMythicBaseURI) public onlyOwner {
        generatedMythicBaseURI = _newMythicBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setGeneratedMythicBaseExtension(string memory _newMythicBaseExtension) public onlyOwner {
        generatedMythicBaseExtension = _newMythicBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setGeneratedMythicNotRevealedURI(string memory _uri) public onlyOwner {
        generatedMythicNotRevealedUri = _uri;
    }

    function setPresaleMaxSupply(uint256 _newPresaleMaxSupply) public onlyOwner {
        preSaleMaxSupply = _newPresaleMaxSupply;
    }

    function setMaxSupply(uint256 _newMaxSupply) public presaleNotBegun onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setPreSaleDate(uint256 _preSaleDate) public presaleNotBegun onlyOwner {
        preSaleDate = _preSaleDate;
    }

    function setPublicSaleDate(uint256 _publicSaleDate) public onlyOwner {
        require(!isRevealed(), "already revealed");
        publicSaleDate = _publicSaleDate;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function withdrawAmountTwo(uint256 _amount) public payable onlyOwner {
        uint256 _balance = getContractBalance();
        require(_amount <= _balance, "amount higher than balance");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawAmountToAddress(uint256 _amount, address _destination) public payable onlyOwner {
          uint256 _balance = getContractBalance();
          require(_amount <= _balance, "amount higher than balance");
        (bool success, ) = payable(_destination).call{value: _amount}("");
        require(success);
    }
    
    function withdrawAmount(uint256 _amount) public payable onlyOwner {
          uint256 _balance = getContractBalance();
          require(_amount <= _balance, "amount higher than balance");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}