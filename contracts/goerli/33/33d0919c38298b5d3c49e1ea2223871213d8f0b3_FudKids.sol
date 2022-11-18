/**
 *Submitted for verification at Etherscan.io on 2022-11-18
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

pragma solidity >=0.7.0 <0.9.0;

contract FudKids is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.001 ether;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmount = 10;
  bool public paused = false;
  bool public revealed = true;
  string public notRevealedUri;
  
   constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

 
  function withdraw() public payable onlyOwner {

   
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}

/**
["0x4c9389B3BA1d0e4308314A17891353d9235C812e",
"0xA26f411bb3749AeBeD305AF0368f1Baa1aE6D326",
"0x1D37802dECfd7FCe3539849a384231bD6d663E22",
"0x448C1d47826b9608ef2B43f8E5aEced3592CC04f",
"0x3A3C6174364c497792b60A541ed5189913985473",
"0x7f2aA9F93FdE516dc538eef9E90a41a98fc13684",
"0xFb4D4E6882C5086df0cf85E8542D712378faDd6e",
"0x928E2b95B10C1Bf27D6eF0D418c8cC1Ce7E2091C",
"0xC375AF9666078099A4CA193B3252Cc19F2af464B",
"0x7ba2B9614a6970372001C44225fb4f06Bb32241d",
"0x656065CA0DC7fC003e093Db8BFbF13423228F424",
"0xc430c82F41e30E0660341C97C040D33206364Ed2",
"0x8D3bA5963c380f98e42616bF87240bbEDCc2f1fE",
"0x554c8665710bd51b777892493684b49baEd0c952",
"0x073cbE955466da7525051Ee90B982382D9995D98",
"0x74A0f67e9D89c54a84E2147D0916F637bc18cB39",
"0x06837eE01747Ca90811e63F09E51127f0393f0eC",
"0x0B234e380A029ACD6715db790f242fa0BcEeA339",
"0x4c9389B3BA1d0e4308314A17891353d9235C812e",
"0xA26f411bb3749AeBeD305AF0368f1Baa1aE6D326",
"0x1D37802dECfd7FCe3539849a384231bD6d663E22",
"0x448C1d47826b9608ef2B43f8E5aEced3592CC04f",
"0x3A3C6174364c497792b60A541ed5189913985473",
"0x7f2aA9F93FdE516dc538eef9E90a41a98fc13684",
"0xFb4D4E6882C5086df0cf85E8542D712378faDd6e",
"0x928E2b95B10C1Bf27D6eF0D418c8cC1Ce7E2091C",
"0xC375AF9666078099A4CA193B3252Cc19F2af464B",
"0x7ba2B9614a6970372001C44225fb4f06Bb32241d",
"0x656065CA0DC7fC003e093Db8BFbF13423228F424",
"0xc430c82F41e30E0660341C97C040D33206364Ed2",
"0x8D3bA5963c380f98e42616bF87240bbEDCc2f1fE",
"0x554c8665710bd51b777892493684b49baEd0c952",
"0x073cbE955466da7525051Ee90B982382D9995D98",
"0x74A0f67e9D89c54a84E2147D0916F637bc18cB39",
"0x06837eE01747Ca90811e63F09E51127f0393f0eC",
"0x0B234e380A029ACD6715db790f242fa0BcEeA339",
"0x719df1fe4f51b50c03d8630d53e936ba4525c7a2",
"0xbf20064C795362e7A87F6d21fe3C57Bd99e4a9A5",
"0x04D21350C04E7ba4f9B9AAE31C1209915f50EEf0",
"0xA213a8F7ac2E317916f1f34ca1E18cb59DA9A038",
"0x3BC27709d76fD1AF992EC4967FFD22cC6CBcef69",
"0x5192e971E7587c1e11B7f5fA6730761c3cE6FE67",
"0x789170D8CeE2cC6Ada432Bf3c2Ce8bb584d3b33B",
"0x468b98B17C278909975A1A211ee039D4A6614520",
"0x1171646580c73a93a85f9d4F8ACb62Df1A3aF296",
"0x4648B0ff7EEf5410CaEE5CBf9b6a0410DB17bB42",
"0xdCdc6f2c4a9cf445f65bD1535255fd030f8d6229",
"0x4546c562735D78923693e9724B010Fa12f14B3B6",
"0x8408C6f14e2d94149A66aF7302D4B3B77233AbaC",
"0x75864932e4061561b0F37E1082c04E7Fbd7f1adC",
"0x44305CA5f776A11639ac4eF3FC4C279B241f2919",
"0xF75f623772E2963Eb7A62Bdc0fB0b2C71D47D768",
"0x6abfdB5D406d9FE549C303805968EB295Ab9ddD2",
"0x19C7545E41E94D9be68EE4600287dc4E98E82712",
"0x343b7b8c4B6C5b2696ee8A2c9330b9654F78a9aB",
"0xc180a5550BD3EAbd39E591429C34a8445F8e94D3",
"0x69c0E38b72b7ea3dAA6F8C519e7b6e5F6754FD74",
"0xab95a0fb53df696a492a93f30fa126bde2493043",
"0xd13DCA1Ad400d91DD82D5B377B66e3A56999e95E",
"0x7767DAC225A233ea1055D79FB227B1696d538B75",
"0x7f6C11033C958A32Ca0CF9d29e6767102A386d07",
"0xd69ae6Dd8eE3AE6d430570e5a79496eC98313E69",
"0xE4575c894B13C99c8F3e9fC0DCdd220131aAbc0b",
"0x0C2b14e62251C7D154C15166bdE72f540BD85a0F",
"0x176B113D6DAf61869444148A7DD2f222EfEF2097",
"0x5a01feb1100f52Fc67A474A610FFE3DB549E7b7B",
"0x261C4011dB156EAa1eA7D0d8e32Ab5a829Ac7296",
"0xa3751B82cDeC62E7D6b7129a409B45Ef6C5aE3d7",
"0xF2a5064a71B3F055160b2554eFAAEA9be75B5170",
"0x8cD37c74302E1F66c33874Cf658D78D64BBe64aB",
"0xE103Cf8d7E32Efe945caFe8BA92BC9489DC356eA",
"0x71195F2AeBCE1Af5137B3017095c0B418A2A37d6",
"0x055E0E034EF604DA2faF895eb0B64B2DE1248c48",
"0x9A69eb60720B4f7caBB1F348e6d6f14cb9E5c90c",
"0xB0c5e29dA9c768e1d1b1E4db60b02c0eA1A37bA6",
"0xF670f4451Fbf4430E58a65119202C0773a60b24E",
"0x03eE34d2a0999670349994F1781e0f147aEE47e6",
"0x32C8c81D8b096857376D66B3894a4cF4d8C4188E",
"0xB53D9Bd2A9985D822887456A0Bf7eCA899768FCA",
"0xAe82d33245f289BeF949820070431C9DED58928d",
"0xe6e81Ea611C167A98ABAF54b52c0F30d29D1Ea5c",
"0xc45aC38e47347726E0B09908fbE869Fa50520AA8",
"0xE8d1749a84Dd38b08093480a73781421F68771be",
"0xDD33629974f4c3DAEe98E7C1C58C7B21646058CC",
"0x74BF0c24935752Ecdb6CddF7044380F25B05fAf1",
"0x0150d184cC304e83346Ff145c3E1dbcdBfBb567c",
"0xc6576f4430C023EFb44Bad58a54F29CfDe776a4F",
"0x4AF39a873Cfd7E8EC7adE2264C18a0f0BFEC665E",
"0xBfDdA87016151899473647Ec107eDE0569e9F878",
"0x070a5Cc40b9ae83429faA3E523A4E4Ca2b051D39",
"0x859c7c99128AE2dC80b43F2da711E35F9DEb0d5C",
"0xfdaB5fb8356a9b0Da6bd28247989538415f74326",
"0x1aa4e5d423186a6099b6D5a02857400B39871c35",
"0xaBeFAC45D9dfB4c44aDC1137F967284D763827d4",
"0xD2b0EA86D97dDA380C157A5E8b76918D0dD0847D",
"0x5b8A0194efEbcF745bb5EC5c811C515a56d5D8B9",
"0x1be527073364960b3DC66576081326F74a0b7bDf",
"0x365bb4F039D7603ae36f35D7e5C98E85D818DFE0",
"0xC7Eec1cD320bbE4348dCEFB0E0AEda21B75d81B3",
"0xB616EeE28344eae22d1514bbb0CB75f908422018",
"0x5aE7a789cBa0F789549a2B8B2f73Dd042c436014",
"0xdA3D240BbF83f0707B577f18E1790c72B31FE646",
"0x356f6bBE64623dF66149C26f318450a42679e80e",
"0xb2309f46c794B2B6E69E4B246ae7DA88631aBb1a",
"0x39e8fc0A646262B0ebEfD182dd0b7f7cd849493D",
"0x20A2846d7C074C20Fe8b6514396cB57ca12d929f",
"0xA4afB515dc5FCB4d40949bE1c9520Ae71C0220D0",
"0x9a3538d3636d6df2e258f4db29ed01fbfaee7a94",
"0x6f2A63c4e8CDc1e26439f50606A9984149C75507",
"0x0452C29AA6BC90B85088B2f4d29f8067e9Be257c",
"0x643AD95d084b14F33c3d1A3c42858D3B4AEEcf7B",
"0xDc2838c7bE0e1Ed3f31475B6CEb9f187Dbfe708f",
"0xB8432bA3eb4f8B7860bf28c099171A39E2a89286		",
"0x219d2F7b92180CbD13F118F85f306f1246C369c7		",
"0x6c5F5bCbb4f334347937cE7B06BEE854188A4BfF		",
"0x726358ab4296cb6a17ec2c0ab7cf8cc9ae79b246		",
"0x6A037b9B16A88BCaE5614D5221991B423e90A315		",
"0xAe7688d98fc120f2D0922772E00A5d16f721d2B4		",
"0xcbfc848D35429C89316BDfe43d8B0a4a22446FCd		",
"0x0d10b48bD53BF19d55c5C2CC4Bb26D530246777d		",
"0x759866FCe5Ca3cb48D45800468965ceE36cfA0F6		",
"0x91901CEF0E7DA80b5bD90B0dd4481FD65747B9Df		",
"0x257211448194153028033d25De69F4779A065c05		",
"0xC6631B2Af605ce12fbB8975b5C7F282Fd170FB42		",
"0x9D6061f52b2A1032Dc396066350C57B8ba4dA430		",
"0x66B59208Af4F63ca34013274AE9A0Cc1A49E1d48		",
"0xc112e382f44F9aAF265C0A3bE9aBF36FdBD529f4		",
"0x3Cc066DA8Ce85BE94718D2987CAA834d8315D367		",
"0x344bA2F42077B7206ed62cE745fd15477Bdf1795		",
"0x39BdC7B65D9Cb2F945fF43e6F5064D9eeC7ecAB3		",
"0x29aFf5B6DebB19D5600b7ECdc62A76A40ADd8488		",
"0xfA47751F1f52b20E88d7Af3326178E7712cD2f28		",
"0x87aEc0decd539a4f69EB41A49aa45a9D2eC83916		",
"0xDcf524fEb91e2DC7Ef4f7d739e4d9FFf7BBC6d5f		",
"0xFcF21d7607fABB9dEfcC872Ab8E46E1c104ceB9A		",
"0xc0BfB2cbC4e314a7ABdB232b2650BCb6be875f36		",
"0xaB87CDE2A10A0a76f08A7Ec29655cf2EA42fFa20		",
"0x66765543b704301Ec3Da55eAc5d04B2BAd07573e		",
"0xc652A30974cf298B16B87d1d7Ac63645ff07fA82		",
"0x78bAf29F679AcCBcf0d17cF95eBb9f6B319E728F		",
"0x56EEa87bA47CC1495c7bE72949b1A28F7748cd9e		",
"0x989c8DE75AC4e3E72044436b018090c97635A7fa		",
"0x5481E32168c4198331835b537d5dCCd1390B5225		",
"0x31625e4C4174F5a1658c6641fE9a9a5938e1f809		",
"0xb77b2cddd60CFd880583294c2f71bf128d55Fa56		",
"0x12d70b666897dae73f784e09aad8ecfa3063c86f		",
"0x6DC142DC98820DC6EEb6d39369bb4F99Af04fd9D		",
"0x463ccA3A02B8185285BDc3a845B2A7158f610743		",
"0x326A02197bDD518119e9d2e2966595EaB01b0359		",
"0x5404A4D869b31e1ce899B02C54A0C3556A21e4bD		",
"0x5c4561684f2E1FA3DD3C4F427C5C4F70bB1D505d		",
"0x4f79482B04A4F51e30Eadaa54A6000B88F1aDd42		",
"0xde8A0426c6ff0187E3133aC4A6b27e1c6e820C4c		",
"0x19FDE7280b7c04349e86aEe212b44E6Bd6F839aC		",
"0x0bAA57514DB4a4b29ed6e134f394BAb2b6D3C57d		",
"0x8e969C5587f28b31aD4806d3a5A884D29aAd2015		",
"0xc9D00D064D6f3009Bb695D23e8dBFcE9578bC244		",
"0x79B81B520911cc79fbfE18246AaDd9C697eAB1db		",
"0x898eC7CFF66CE9B3d2591a091B2d35E19a3a7f2f		",
"0xdC9bAf5eAB3A767d390422Bd950B65a1b51b1a0A		",
"0x823E61B7786Dc0f7eb0f0372422A15b689eDF060		",
"0x8433058e14772c81235077E744Dde09514f1BfA0		",
"0x9E8E45461B95F318d8FC87A1aE89256B82CeE60c		",
"0x856F0ca734993E272c98dC9c81D873b1E5D1c07A		",
"0x226F3Cad6Ca7998CcdC65CcF95B23Df250E4Cc86		",
"0xceEaA5475b5b573121C0d66eB99fEeb92FBFA87c		",
"0xEE14BE5e97CD0C26F50C9c5b2709855027b500dB		",
"0x9e605F197Bb5c4A3bD1c04E19fFB90f7B679d552		",
"0x8Ad8c171B5Ce886c6d9C6D7211f9057cF286522a		",
"0xA7c444E1514E4398e72F3Df98DB2072c5aB358A4		",
"0x77d90755AB4e458ce85352fda7f445302f02FB63		",
"0x2c84d5e862B25D555324E2D546E1D86bdCE43e48		",
"0x21A16abbf72a120E3df1Ac64D96f19dB827b5d56		",
"0x5504BCd87D0796ceC806343beA8407F32575C689		",
"0x9C6F20AD5111F1f3B6F2d46Acc695A91976B5905		",
"0x6050529831605e2e8Ae46e32B919dD13bd939F70		",
"0xbEe1f7e369B3271088Ed58bF225DF13Cd96D32d5		",
"0x05F8E15D6D0EA924fc3c67D17d7CAE4F8243c9Ae		",
"0x91c2492daCd0006b35847306e1035a83ABcC5383		",
"0x401b014E51C9609fcE3327cEc5be494E30B36800		",
"0x61743F54c1feC04Cb7A21FF5EE0453755268E3e5		",
"0xcE6D560610B016Bf112E18E80C1596d203e1Db5d		",
"0x7E5f079d65F257cCb204851594d821Ef5007FD33		",
"0x378305C2E32264B2130002aA6De22b7fEcf34fA3		",
"0xF4adf7D11032C3EA471b56f8869c99b20Ab90a16		",
"0xc36CE23BF539c09421798542ACc50f385A9700B2		",
"0xCDf2f0556b4856Faa5AdE0A3d36A0a533b81EC8b		",
"0x8B712fb280EC956Ab2a1ad4d5BD62f9C498c449A		",
"0xfbBb6F371D55ad8580aa18e42b6A113A8548E36d		",
"0x4d39b15c56EF58e978E45786a7d244301683c61E		",
"0xeE269d6b43ec026Ee7f48c33Ba50ecc31534e638		",
"0x93261bE447104636C3CFf57413880721361FEDaC		",
"0x8c2A36F85d92a3ece722fd14529E11390e2994D7		",
"0xeEb23003fdeB02c29995e861b1d31CeB7b277E78		",
"0x102FB3BD549cC3E060bF76C3FA51BC79e2033aA0		",
"0xC1380d65E5cf5c565e335b34Af527590298dFB2D		",
"0x15b966928f8C4814c05760724f7504684B481FB6		",
"0x38f15a3402143A56d80b85A7FD98d8535Fff440E		",
"0x47A51e662E5A777cC969a0895A41f323D9b7749B		",
"0xD56D0db4018c85C1888Cb9d85E85F5F44179fe41		",
"0x42c8C0d6905AC10884cC8db1Aa807700bD5F5714		",
"0x71b4B07B721F52122a91E2F8381Feb923aBabdfD		",
"0x6076F38c582d9559770556add2EeA12E41aB5252		",
"0x2C5A4C2330af0409e19972f76f108d1d4667aB02		",
"0x307611AC9526d65224CeDadBF17513772E718E9E		",
"0x049b775B8698b021bb198374ebB8C0c04bC80Db8		",
"0xA0f1cB22B2Aee4eF29cB0622B0cd95be54f5E370		",
"0x7Fa5c02827B6513a791aBd588E023e0D7B34CC19		",
"0xCc753A27368aE3ff4b8d28D6A65E01Ef30294Ffe		",
"0x0a4eFdfAE9Ad331F4fc46322d721D37D4E87C190		",
"0xabD1fa79835C349AacB73466c48e89C7a6cdB821		",
"0xB967c3321B2AdE548416409C0733a71af5c9b9Ee",
"0xa89e3AF6C971FD5B17782fbfaf96a603270f0518",
"0x5c4a4A0f1B73038722f3D3F560282897E9a53A66",
"0x419F2E40EacFB8e636E644A4e65f3A533c40679a",
"",
"0x25D931EC485134Da8914A1d771f1110010E20C17",
"0xB66C9De8339EC8fF4949389B8878CDE9cFcBF488",
"0xa0197546d72a4EC3CedeAc7dAf3aAB99Fd673912",
"0x635123F0a1e192B03F69b3d082e79C969A5eE9b0",
"0x7344eBbEE3939285Dee8055115E8CA64Fb0A2D7D",
"0xcb373d8D63446C2B25B28BD3ec1Ac102bbB2Fe2e",
"0x282B2F1B4Bd30155B33f1B50F6d84f869C4A5F88",
"0xC2Ebb4149d5C1025064172931C29fcA67F3E5266",
"0x1CcbD9aA12881f71Ee13bd4182d4e978Af81ece3",
"0x9c5aB27aB9D8365819B47C504b549eC7664b4ccA",
"0xF059790E3ecB46866c2223b1E185BfD152dd3e76",
"0x76DAEe426884326efD12986296682bd9330858C0",
"0xf0fF3cBA39207600f4A8e52AB21C1fB2F7A173D8",
"0x3E6e47fEc4c58150989F474F46E5C5b03e10836F",
"0x7A6BA943658dB0B15cED5c36Bf8E8E815d0F9293",
"0xc691452456fC46C1Ca7104b91B62785BaB919102",
"0x4f1E84baB4c883CE6c303770936eFdCfb763a0a5",
"0xA3E5F04689eaF61B643c480FA118d82110C6e7FA",
"0xC596b68eF4AEAf49dB5e48ED8F2C652d50Ea4E08",
"0xa51d83ac64fCA3340bF70776275a55d938133cDa",
"0xD220A562DED7f126316101f353810A50De5D33d7",
"0x533fD15aef6C22B977ffe0f24C82062ce0fa88Ec",
"0xCcF7261E767D15bF1839023d4786B2631DDcB72e",
"0xE09b854b77D8C212E9de979C050666dF9b4684ca",
"0x1257EA6f17f3bD82B323789cF08B79191CC82b6D",
"0xF0C15C42d12a66A64C18B7B3AAAbD301850c2B67",
"0x9871Ff2637D8283836aE1e7c71FB6012685009bB",
"0x1Fdf397dd1E6596cED2f8E630cE222cBa9e5eE1f",
"0xE105106F401d5caA68936d595F5D96f7f07D67aC",
"0xfe18EBF2d3E54AF293bB27b0BCe19e2857831708",
"0x15FaBD08ae2c4C18a4018f9e3B1ADC54F844F95B",
"0xFC5f9ad4DBa930cCD2f7e28473b5387E56ec1A8C",
"0xb84812cA8546D24E390Dd746F824d96d434fc575",
"0x02c920A7157C5CaEE087E7cE6330b27CA72Cbf3C",
"0x3c997580131d21607182fA93a15CecABbd32FaA9",
"0x6A96312fA5D5E6c8415Fe8387D7211D888e37634",
"0xfdaf22dce66d4d77996f98d810c58a0874cc1858",
"0x797e022eeaB958C74794b52de0980300061f3e6c",
"0xeac5f9697180bdbb4db384a5b1feafbbec49c8bf",
"0x9a75b4770D7362Ed532aDD2C6bfE1af41468Ed00",
"0x25D89b0f8eFB939dC3615b3C13A61C45a6E9dE76",
"0x1B27a21267C6f16c422879bA779D69cF98B07460",
"0xD628Ff3CC4Cb23c11288215527aE20895dFc0146",
"0x3a4AEa84dbe0644E93FA2631BB454C9dDA5ab7De",
"0x59b8FF1342521c34B075aFFE350924A75312FcBe",
"0x0710C4ad1Ab32E96B6F6077a924f9e671906d19D",
"0x407CD37f440879E4c61877Ca54C427D682e6BABc",
"0x3A204A8B5a9Cd6bC1F817Ee8088929a31574289E",
"0xc802720D71E7e2433a26d887e5b37D183ccabAb1",
"0xF5ee02736f2d50BB7e85449df82f2aF5F173D33D",
"0xDaC2f2D98b138F594CF57113D0A61a856aA90fA2",
"0x1a5DAAf40FBf5F24876d47FDb8BD0590E52c4c27",
"0x3426A7626b479CC0DF2340EaE36AcaA46943c7A6",
"0xba467F4B4757166482f508767d8a93BB23736D46",
"0x02eA4D918593C0b2a3f7Ad652df98d027DcE33e0",
"0x0B9E0bE8CF299F04952C6313Ed81Af813F6E1361",
"0xBA847B6420aabaC2B22e6b682310C147d48E71c6",
"0x2186E0dB5Ff6a8589eA736Ad8f680a1Ee35e8358",
"0xc315F37b61E766a775e7AE649987A1861A2F8aa0",
"0x3d629AEe3cf67cf001194e8E8ae2dD6734e24A76",
"0xeD374438535dD7B6dCcFFE931Eb04869763932c2",
"0x77F00a4676844AF2C576aB240a423DCd81664c8E",
"0x495624a0f21833B4B577D0d442b7207419A0f413",
"0x91752F5d0eC6D3032861941071dBE0bDc3dE7361",
"0x8123cC29ff8979F783A251C3a2aB24D46BFA981d",
"0xB69139447cbC59a48C0E50fb73d0eD83eee63485",
"0x955Cd171d0ddF8F23B0FF3f64a8EEec0e2a2225A",
"0xC0609a194c9ee47a7d961710b4c86BA9F12eFc22",
"0x5dc0D2198C14295D2Db50428Ce310A9444629c85",
"0x541DA271df32cc747ab49CF84e6D417C0e67eb5b",
"0x9A5A6c88c9C41703f043cc09C9d1029a28efdDbc",
"0x09eC9338AD0B379c54c9B046A37bEF97e4b59Ac5",
"0x9c203C00d702d0762dA5222Dfb937bedfbe3E00A",
"0x041dE134053ebDCa0033000084b31A750CD1CF9f",
"0x5dD033716ED8293638deE697C08c7Dc107aC818C",
"0xc6f479AC0cEe18c1C8FB34bD17968A5944F50f22",
"0x52be3580601524652978648E872D0aA448aFC928",
"0x43d018c74eEAB4Ed68B6F32eE82Ff1939CFF236B",
"0x63aE99F260320D39fac72458388F8a1dc9641F71",
"0xf44666Cb1225E1Abc9Afe15b90Ae2044247C838B",
"0x40a683fCE0Ac3d6798770523093BfC1082ac806d",
"0xDd9993cC2B7274CF968b7eE1e6F984619349A309",
"0x562D4A9e900f391Df832f9818618c09D394597b7",
"0x10DBC2b5291506be314CF7342551C3877B67dE56",
"0x05bFBa34a229dD926208dC4Bca5Be4e2d3235eE5",
"0x82a1362B317035409a4a592E6d97Bf2E465c054c",
"0x9306F22b7dF39e4e690eCf7698890EF2e4546101",
"0xC00604A96e6Fa9f978E977124ad00638fEA52D0d",
"0x37eB8f40a3B2dd1ac80F17cB556393D15e22fb2d",
"0x254bfD20fE4A9FC6b62ac7589063d3228B8cE3e6",
"0xc2c1cBAE9bEE8c610B2c81045f893b00A08c7BE5",
"0x3822C309635092Ee6bBB0101d50C9490B4E92715",
"0xE6B953aB1E4f5d503D331BdDc4Cb84c0a098eFb1",
"0xB06716762d95080Ef63B74FcEd62F541a48cD660",
"0x682EBEE8033eDD185dc38bab65Ed858162F854e9",
"0xD0462700eb32bF39A72A931494F8FC3D9DED6536",
"0x6a94Abed79073c8B11e7626Fd5bb8b8e4Bc9Bebe",
"0x45BEC6446dF4434c29f7F3F40cd84b77DCc4a6A7",
"0x74617847750DDc88A2e0907461833fb05ef7EB06",
"0xa73e23472ba023A3715e4A039795f274e58a14EF",
"0x94C9455E050e8dc9d49681FB3568d3056F43f246",
"0xb571a2be229e0af8da3d9666c1736a77217a11cb",
"0x309d458AAB130543919b9D1A86F19aEaB9b6D331",
"0x4c54d8EEc737Ca6DB9474E2958c17D065f19B196",
"0x4aD5Ad94903605C6AFBefEc6Da9f0602E97F8c8D",
"0xC866601b8A28D3D014C16d997B342d5b38A746Cc",
"0xaD66051B2DC63444cEd86b41a9bb33dD6f321ccd",
"0x8d701bD0504A13aa89BdBD30ad45688d11AdEaCa",
"0xda8E6690262c8DB3C556c26b60233d754bF5700B",
"0x1a4Ef4C828600393fB492730Da23157B463AFF04",
"0x327C86581E15d6A72207e655216938Ef10C78999",
"0xF1106c3c26C0036DD744A8fD59a10c3E736B95C9",
"0xC42590551EfB807dC30D18aAE557B5504b018754",
"0x33B5b0327D2187d330EeB248c9e1975873be435F",
"0x75A8aBca8AC51ab7d71dE077e94b8A66d8c4B359",
"0xA1342B27953a25e4C87FCee629841284BA7a1BCC",
"0x7b4d4A5963a3f7834284Eb4886A257fc4daC0e98",
"0xd68E70e207EE9326a0C4E8eef1c342981790BA3E",
"0x1e149B8DBCe698E9505Ca9107FD3343687bcf5F8",
"0xDC9C3f87eFA40352082c792beE9918ee529cad45",
"0x379135D63e37865F1811A65a1A50257f80A17A3f",
"0x117582162a277616Dc2911678F56F37669deb1ac",
"0x0E9A1e0Eb8B1a7d8a6177005FF436Fc6B29ae62d",
"0x1BA955F88ed824eDbB723C65ae71233B9fF6188c",
"0x4864737A400b48bdda8f817A5cA45Bd8c44A2f7E",
"0x8E554D06b63A018DD792250D9266Eb57B9C5B245",
"0x9A4987E81613B0B13D24Aad4afcAf36D77B2F2C1",
"0x6F12719E4D3089C00759CcEDffcD9da1d709436C",
"0x44Df69378025E2Fe342e09E1CBE5b2A9C0B66223",
"0x5C0A9301a9938De83CA227077EB64d3fFA55e465",
"0x753e9c65BD55e86911Ffdca00eAF7234B386b1e9",
"0x9e2A5a2b7eC68b6b882041D6fFFf6254D85EB7e1",
"0x8EAA028cC94997AfC8F043d6E0A6fA8325696E50",
"0x647C8a18d17D461Ae82dbB99B8aea0b645d2D206",
"0xF248326915ceaC73B79Adf746e4778956b346501",
"0x1A43D19C22661D0c85E34A8d752867232fd24393",
"0x1daa499fAb47F6937513e952d6d32079848bcCa9",
"0x8Ca283740973170c56ffe68a062C0FFf7E33C1C1",
"0x46D8080F7699E43B98eD93e25f7D795562D92BBD",
"0xc4a77C2CB0717112BA865BB7dcd06ebD01E26150",
"0x03eE34d2a0999670349994F1781e0f147aEE47e6",
"0xC7Eec1cD320bbE4348dCEFB0E0AEda21B75d81B3",
"0x2baF181424C4918d255F8274bc06f048aa5d7F10",
"0x0000000C01915E253A7f1017C975812eDd5E8ECC",
"0xb62d2b9729130768845a9Bd683b92D0b2C48aa7e",
"0xCEdB178012eB7177dE3d8B9387DCb28D93a05A19",
"0xCD79a4B585A6361d8ca4d966d0163211BbcE1531",
"0x660182e8f264060e1DFB65fA01DE84B0159AB2C3",
"0x96C83773ff4157F33be45aEbab42526ddA79bB0a",
"0x352B6F8aCB571DF3CD968f19Aa84105aCCc73790",
"0xCEbC6fcD8a43A582b0C6C0Fe1e9A1ffb76D11CAf",
"0x4830FfCb9543B2E4257ff21E18cDA9d0Df4C9Ad5",
"0xF9E63Fd7AF34cCFEaB085c369Ca0e47BdD01F3d5",
"0x56fDED725607f10ae98dC3572EF0f01196586aFA",
"0xbb08212af6A1b0a6d5E8acB6C108aF72Ae25fe5a",
"0x450c973D85da1b7505A553b8212Ac51D8e3C4981",
"0xeCf7Cd8fC69D2Ca0ED09a7CFFF330238e7A726fa",
"0x02727AEc608156fc01730Fcf32C7C433D7430F0d",
"0x1Fb3e99E0c0D77Af32070cC558932c341cff31E3",
"0xaC5d07A55aCBA2D131796234a386015305e3d59B",
"0xfF3501F3529E86896986fB0379075060980f563b",
"0x88937e9aD8b0C5988f0e56C705A8f3B7294F5CD0",
"0x82ae8746F255e0faC003Cf3A1f5B976d988B3450",
"0xCA1Cd2C5a4CEa64EBBd32d0c128D5972cB530D55",
"0x7b4d4A5963a3f7834284Eb4886A257fc4daC0e98",
"0x630A2Ff284b1D9034e873Bda412122fe8fEd0630",
"0x981266532Ba833Ba2c9Ea4D91152C644bfd7F068",
"0xEC45D70e70E7e719139fc62205290dEA60AbcB01",
"0xe90e71f662722fC4cB14c53C628217EEefD77a0b",
"0x0795536288350475BB77B5d4e5cB862B4FD1792B",
"0x0376De0C2c8A2c8916Dab716d47D9652087C2918",
"0x5f9DdD54d19d4A7D6dA010f8A934f9ecfD0149ea",
"0x0112e8d7f728e7004f1ce6D5D533884B18C71108",
"0xD505e18D57De7C5B52B29C3e039Aa056bF3b33f9",
"0x0E1F051204F64dB4ff698e8948e9e06B7F8eb619",
"0x24EE547a325B60Ba76e27Db2B58C454c98b470D2",
"0xe1C6EbFB10dA12d1f7b39493807612A0CD131d24",
"0x5238CfB6f54aFd9B5CacB2f48e9E5825E5BC7538",
"0x070d287911692B2C129a6E32766BdDF17B59d0Ff",
"0x520f3afd4d156e71fc26f330aca6f89e083ff524",
"0x8DD34fbCA7c01c1df799e0D595a5D2943Ea2F4Db",
"0x27bad4cfF7F844C3743c0821199c40A9f8963EFB",
"0x39e8fc0A646262B0ebEfD182dd0b7f7cd849493D",
"0x0fa403cc315abE20A99b69c6ffCC64556A8a25A9",
"0x1BFa36EA533bAE7fa8EB8Dc518c80BD91335e936",
"0x9Cbf45642acf39B23a0AeD84c319C46B169a05F7",
"0xF656F3C30A6658ED4C1b2eC34FaF22414EeEf70d",
"0x23aA2AF4038feE37dF9a9e7aaE42Eb18F0493e43",
"0x25838d6342a309e08920862B12A9f35684946300",
"0xd41150D2aF00f0eC727c6Fe1c2344bc95cE0014C",
"0x182B32912D74A620124F7BdC13f6dA38c5DbE8CF",
"0x1563c9c1aD2C797B4E71FfD517638598C30FD56C",
"0xD93F5582DC03C9f896557c0beEE7Ecb57a8F7d63",
"0xDF682344A7CDfed02CB0e3fF2F19FC7B223528Fe",
"0x0b7293C15e988380F9D919E611996fc5e480d2A9",
"0x39AAb7348Ee10834DE144aB450A12eab67019a75",
"0x660105EA6435e8D4C887A3C830b8812746eAdA30",
"0xF8075fe5e5f8A8593Fe18a2060B4dD5e9b090261",
"0xBA8716DBDbBF336C560D2C1F36E0875246440716",
"0x7367CedE689B43dE7D87d3fC6Fb364Ec151A5934",
"0xab7eDc77Cf552D6b17dCcbbbCE79216799A58567",
"0x91d75598B1319a6c899815872819879a57C97494",
"0x2Bc4Ed66590FeA9D91C6c8FcaD312E4048C9CaCd",
"0x92E51Ed1DA7Bc7cc558aEe1e9eC5d8E5dCdDBb84",
"0xbAaffC86d1cF8c57aD8B9eC86849Ca657d1Cdf69",
"0x2ad4510F4FeBc4386E9732D79E08c4A15d5e1758",
"0x975553551c32F09cf49e3c5b186762Ce6b58Be69",
"0x3910CbfCA62559CEC14f51E93F320823D149fe2D",
"0x998B25538486e05F863D29061Cc95554DeAE3AEa",
"0xB75DDDEdd9D74015E4C82aA48b0f071D46b90f74",
"0xC6df0C5DFDfcFe85C60137AEd076ba9af899A204",
"0x586346131f56E6D410b05fe03Fa8b713Dc4F2b8a",
"0x211eC332154d22E4B9aba0d762Dd20111EB3fd10",
"0xB8f8743417f7eE8Af9F031ae738Cdd40b4154e5F",
"0xA8a453B9b8f6Da431439CCc4B7b1bFB6fd944604",
"0xD95eAD0E76D2d71D20Bab8c6777d6A11F203589f",
"0xdD78d745BAeDc74e4aD560840fc0875EFC798fC0",
"0x71E52F9B12a3d11efF3Afc1E82C977F5d1bA3286",
"0x46391D1175EFDEbB38bd0CA61928274292Ec3896",
"0xb13106B738C8CDfC2767309Ad9FdeD9Ed76614ca",
"0x76AE7078D5B9f62F674ad0eBf1413d4Df8E73B87",
"0x630F47be29bBD99b46352117bF62AA5E735a8035",
"0x55caC8c88C84723eB8Df4D9054EcF030Cc82A774",
"0xAEDB73612d2bA258FE456Dc1A777298B4C6D6A82",
"0x9EeE96e03801b01A3A3A72b2A4309105389b858F",
"0x49f63eC5aCe937798724aA71e0CAa42827952215",
"0x93971cc1582E46Db7F22f279acace1b3c07dEB71",
"0x1e82aF0c2a5883D3ed78A0feC92a41C6DD8723E6",
"0xC012fC5d78ec73280688DF1FEaCb107a4ef43237",
"0x8051BC59d00E71A2c71D8D034A08605d91f2dFa3",
"0xCD45dAcdBb272Cc143d6623f6fa213aFfe3328fC",
"0xE716198556D331f20de0B5559AEf43371b86C0f1",
"0x7d388c8b67255f66568d21425fc270210B2C6B44",
"0x495624a0f21833B4B577D0d442b7207419A0f413",
"0xF1c43051f63147039669A7e4b19D07107418D30D",
"0xf36B79aF25aC3E772E547AcD0196859A89Ce1AA4",
"0xe94C6fae8e8fE99e951473Bc5826f7f758719c46",
"0xF123E2025E7790126045be0fce7107bF707275cf",
"0x65a5d8939326709A86c2ce8141A010Cd674c88D1",
"0xaA597C1545d80018C0481764b2DBC684013e3652",
"0x23Be58c3dedFA1E4b6aC93F9D1Cb28d3e6Bb2ff6",
"0x4085ADb71f055ee28f4409873bbefD85BE6e1E61",
"0x6eB4869D18d88291cD4c01399815CB96ff9D7338",
"0xC200023258a45435C413F0660Ae749f1f6762a39",
"0x24512E43ba243c777D648763C71F19a06d2118CB",
"0x755883DBf18D856B0E3AB5F07aD1c9101B3F82d5",
"0x39a9755448D35163716698A21846f2Bf65D3fAe9",
"0xBEc318FC920D603FAa9124aCef46d83c3ed0673b",
"0x6dA6599a17fa5c7014CA77596f7C52668Ef28C37",
"0x48a89224AEED25a6EB91695FDa523f511DdbE765",
"0xC6B1306c0a0567e86B44ab63B6eE4Df3FEC1c1B1",
"0xc2Be9170c6d71D63217bC22A17284A5fE124CC87",
"0xcdAEf60C93Ca6D1F839A05510e593161D02A5824",
"0x6CcF36E10ac03A4881458eDBD8684C38723Ef623",
"0x99aa91d7186bbC2bA90C6f4A75F99abb4fBfD52e",
"0xbF682a3a08c8F369eC37D90E38afc8bCD8e9E909",
"0xf61A63b9f17f9cB423E8BC6Ed35bab42F9232f9B",
"0xc3f4dBAEB8F0dd2A4dF4C1857fD91e7110CA2e9A",
"0x361F2dcbC692F45b1010148E43155B5d3aFFe04F",
"0x401c8940B1A54cd9BE617ca004aC9Ff39a272852",
"0x49B6C88891Da0DC873E4ECa109C773188F8b125F",
"0x98319863e839Af6654CaAce9f296608eD1F1AD5D",
"0x2BbcD3e51661C5005173d44D6561A3A339588E06",
"0xcd1f2390F69e8adED87d61497D331CD729c83fA4",
"0x27a01A4Cf24DbbfE322c6C9d9d7b575Ca6bB3c9a",
"0xF2B548394F5E8eE171209739d66675594BE555E0",
"0x21a85bDC7c5ec0b4049bD54DBEde2318fC889dcb",
"0xC0a299dC0F466EB9F543667E2A8d23aEd5Bd6598",
"0xaA5E9F299B4D54606A73037e2C3b96FDc26F4d83",
"0x9C8434cDF7576f6d3317eDEBD9F54876f662dB2c",
"0xaA597C1545d80018C0481764b2DBC684013e3652",
"0x906A999eeacb77C358B02A2B8543c30EF7D6C4B1",
"0xF08576f40D74A3D0A6f7709a1e3f603DEAc39f05",
"0x13E480c3350F50a74e2F5777B485652e87e40896",
"0xDE7BC955c03aD2fc66955De7E4E84528260923bC",
"0xb3DC6Ff7C5BB3f1Fe7b79DEF802048EaD10F8690",
"0xaD66051B2DC63444cEd86b41a9bb33dD6f321ccd",
"0xe22eB5FEa7d68e3653F8947A2Cd471AC7B333Ae5",
"0x562D4A9e900f391Df832f9818618c09D394597b7",
"0xd6324c9946AB30aA3a80F1d1539E023585dcC60c",
"0xbf3A4Fb2Ced25D118C819087eA80fe721d1e28e9",
"0xb056b47D7c030dDD649F4d4642A36CD942B076De",
"0x12C3d1d971728582ED725a93d2C2A7023921Fad7",
"0x136e409d3C13DbF044d8eCa5e6c22cb0a7915500",
"0x4713198d6bA226bb73E4b1F90a010DCB5af18403",
"0x69C489719288655DedC602D7FCD345b937176e3d",
"0x328a64849478c53DFa5f082045989b6d9C2856b1",
"0x80F224E3b7B2A75e3Af0A294BbF3109180fCD7A8",
"0x4AfF0f9BC168bf7A8F3DA5766EB4798BF5e4a4cA",
"0xB63B78Ea0828FbAff0ABCB2c2d1F53D96D588c87",
"0x5bb1d72c002d76da7327e51f21005215fb858d92",
"0x28160bB601ACD1f4Ff35D7053945f8F6B9C6636B",
"0x0E1795E72668290B14Db0bfEFAe2D1861Cd2F5E3",
"0x3954be4Cd914cef58205f923760E06E615b841d2",
"0xb061428D604b1b36cb75c807B6fC71DDfc4d4Ae0",
"0x6CA05BA42eed37c0dB6218eb3BB2a8779F7c88cb",
"0xB624B49a057E7a059f2657D3226E0b7D0da535be",
"0x9f37aC209c3a46629516bB2181fDAd38142DEC0A",
"0x911C183020C0fe13A60D185d03ac1B6819468979",
"0x6DDFF2ff83317a2f8C3E85A370cbABc6007a9a9e",
"0x0D8712a6dBE0CD0ed1c83C12e7f8Db3a2E6F21Ba",
"0x144E6A0B0712e4989dc8d83988E02519e7f4086b",
"0xE9D252f5C6A7048FabF5d05E021a635bA765a2af",
"0x314008370Bc17C4627D760E4c1500Ff207f67D5f",
"0x41d697666fAe34006E540E1d8365f2Ed2E192E2C",
"0x97c4ee7d410A01D4896e68aE193854c5627cFF4d",
"0xf37A2f6A2BC7865a7096C44ee4ced0956d70B8e7",
"0x2dF22f43C69237B042D94e4077CE0FEdF15b07D9",
"0x3D370928f718B0151dE616555a0aa673E851AF7B",
"0xD94f8a6c71D9ECa04CB3b26F5533482Db64d0Ca8",
"0xBba37120506a2770761A71684a8e24b1314C11ea",
"0x5Fb543c3Af09bE337C9957E1EF9Cfb4aaCC222Fe",
"0xf11Bfd45c460d14158c27Bd2D6b6858d5aE18974",
"0xb1F46301B39872D591c6e79EFEc3b75Ecb0c9781",
"0x355ba48665E8a0515bc929DCA06550448Ade9fa4",
"0x3AEeac5a31223B20F582E797e4d5899f0cC46499",
"0x29bD2D1BC9382aB20ee799B6a8beaF9dE1a8E929",
"0xdD1A66eDf38a954eE9bb7aAF1142117450aC4aef",
"0xeceBDBf0e865E29F91bE4E9D365404f26Ce07e4a",
"0xD8e7C8fc95087C8372301429B119f81d7D167633",
"0xF9C9455b705Bd80B8670382B7c71DB9aFa1e34a8",
"0x64A18e8e55815eC13dfDA0C4f36Bac5c52F6c460",
"0x3B4D2cbf6A42D2dCE49d3759c38d9C716c41C007",
"0x4034Bed2f138de45261a9cbE3469d2b7014AbACF",
"0x6F10719408d99d917f395efC2e2EC9136b873cEb",
"0x14E913040629B3E29E53Dda339b60B3138a559d5",
"0xF68E721A5E83d020d7878992D69D09BB2932F5fE",
"0x97EaC3909c80fbbF3B61757e46369954186F8482",
"0x7672f7EC15cD4e4D921Ab814c9fD03eAD0AcC612",
"0x7bd79955Aa2c4CD7D1609a36f0F3F0C3dB9F74Eb",
"0x4648B0ff7EEf5410CaEE5CBf9b6a0410DB17bB42",
"0x03ABEe80d70eac6B9EB4e68f56Be1CAAa42f48EE",
"0xEB0dD307D96F7fF10d46924dF400a8997d1225a7",
"0x03e0c1efcC7aFa5E92214E7fbDF5524cd7229601",
"0xD4E453677A089D6463b6359880B305D66d3F59c3",
"0xe638b89c2D183d9427A6D2577a01763231592E3f",
"0x766Bc5eAEF59C1DE710AaADdcB8dFa9e27E85817",
"0x6ab5A4E1FEaFC948d64f6a4eCb4beDaC5362b549",
"0x4fDf81caDDf6C1CA706F601573d9fD3d4AA9929d",
"0x2be88941Da381AB1ebaf72cd2E7e75887119b4Ac",
"0xB3419F794308aD4D14BC76e20dAD1cF7dC9337F9",
"0xa539835b75c64f1910C1b2554D2D07c2DCd527D5",
"0x9C6F20AD5111F1f3B6F2d46Acc695A91976B5905",
"0x325FC6333cCb80BBEca15A5665C33868ec40E335",
"0x9Dc04B883b280397d0502373fE07BA66d60dBf02",
"0x1537Ea142F6571731366a48B307C537d4804D5c4",
"0x6ffb560ca7944d01a532eba6a5dcc7a33b6a4e86",
"0xB8E91C83327Ee37c50E748EE7086Df53361d7811",
"0xD3399419C82FB9D3DE626583813bDB336D508801",
"0x9265870456A80D660D4aA4ad4009946888603280",
"0xb4ade6CC28D0aE3c7659E2b9BDf4975448a0693a",
"0xCab52D374CA3519a984e5578d8F8789f050b4fBA",
"0xe6519b4726aA433ED7a748125e3445876bc34100",
"0xEC97CD3771b5f1fdbe4673c597b06f4c7ac389E3",
"0x720579e98ce71D9cFac9AB371B52D8Dcd483889A",
"0x2DEC75aa6f7e05DE1e1B2E8d1A85F79AEFc17d06",
"0xcA077958D1b357Bdf8dd5B823500a71C0E78FBC0",
"0xA6c6B7327B30DdA256D3485F8e1610B63c7690bd",
"0xcB495f3e08d040D7b57E35853f4cCfC173556C09",
"0x57e8550e14fA3D7c78c031380270dc04B2D777fc",
"0x730100728bc596a72E9F06661b4A5d664a9E4A6e",
"0xD3399419C82FB9D3DE626583813bDB336D508801",
"0x9265870456A80D660D4aA4ad4009946888603280",
"0xb4ade6CC28D0aE3c7659E2b9BDf4975448a0693a",
"0xCab52D374CA3519a984e5578d8F8789f050b4fBA",
"0xEC97CD3771b5f1fdbe4673c597b06f4c7ac389E3",
"0x720579e98ce71D9cFac9AB371B52D8Dcd483889A",
"0x2DEC75aa6f7e05DE1e1B2E8d1A85F79AEFc17d06",
"0xcA077958D1b357Bdf8dd5B823500a71C0E78FBC0",
"0xA6c6B7327B30DdA256D3485F8e1610B63c7690bd",
"0xcB495f3e08d040D7b57E35853f4cCfC173556C09",
"0xe469214f68F90AeE4808389002A72C0732104eE8",
"0x513D899df5438ba8b44a7045489eC696A552eaa2",
"0xDA990050BF6c91251FaA8a41a514365e031Da635",
"0x078C5D9ae0b38C658A0d4f77e03A142CFaf6D769",
"0x1B1dEF412C0193176CdA648b64E7f1004DCC381c",
"0xaf5dCe57191F4e116e3fe82804DE2684bBB0616b",
"0x6f0Ab97310DC936fBc43ec5bF9A5B5D88378BF92",
"0x85Dd7456e6EB5cbCEA592B53eAc71CC01A08fdF2",
"0x163F89fEFE1a8E285d5846DC011967a48f2c84d4",
"0xa467f805521f645c6BA69A94ac6fA94561339b22",
"0xb6F2f7D7990241726e47FACE7463303eA8C46bf6",
"0x513Ae0dDEf04AD9D316b851fAcB9662939e3c596",
"0x81332A92d10ADb7A4a4ea89185a777B9423841cF",
"0x15924aA4B8cE27650b7fC6028dC4105aff85671f",
"0x7b7Ce245d2A8C3d9bf48Ab95EE4CB1612629bA57",
"0x0B6EF5B38Cb642b75b82918973fd19883e33bA4f",
"0x27bad4cfF7F844C3743c0821199c40A9f8963EFB",
"0x79fF9B338d6E84334561f78e8EC90CF584ECE735",
"0x25838d6342a309e08920862B12A9f35684946300",
"0x6B0C2764FAE7f4F37d8265B47c7BC519d758e902",
"0xd32916E642174D8CCD6938b77AC2ba83D6C0CaCc",
"0x2ae6c9914C7aA642471aFaea888F6377f86D8050",
"0x10a58a179417Ab40bEA3330Ba143174444C91993",
"0x28B76B13bf75ac68729BA4096CAa16Cb2e811b03",
"0x8fe3f381C4D0f6743717270dD5c6229745855B1d",
"0x1a4EAE396a846080C4F11C9e3af5b8466798578B",
"0xa793435fad4706827BFedbF2Ab3CAB321B943C52",
"0x2D6E239F03C6dEe0f0817Ef2592c9DE89CA1F2c6",
"0x88340710dFF155993D75c2FDbC66dC76e0294380",
"0x4d9D7F7DA34102294800b559Dc1ca82ed3db5A96",
"0x1f6a939584721f487CeF15b8B115825cE4d77d66",
"0x9bb73422d9E3dd9a7fc89d93BEF1e2F4a6F29F3D",
"0x7d95373b666f4d24361eB5F070a8840bAf860D0e",
"0x42814e227Ad06c81c655919Ac82ab86bBEa607ad",
"0x9f6cbf42308Fe051B6FC5D8495a0E70F429c716b",
"0xA54f0264bEef86F8Ce13cA1C7e0CFCFC39b69Fc0",
"0xf6A7AC4fB0b936E4Fc83d36D1Adecf346d6283F1",
"0xE3C0356AdF90902F9553F25Cbd0F5bBC2353fb77",
"0x39219EA64b27a8921977B3870Db74F7e132AFcc7",
"0xD1D21D4CA3d0b3f5d4FB8f98FaBc7D70DAFAD5C9",
"0x0db0960e1E358875c5A39A2422425A8513dd77AE",
"0xC58ace27dc0FA1F8D33Edad04D43A8A17774c8EE",
"0xC179d9017Fa3A85926442e14cF053478A7D782B6",
"0x53f95f79fc93CfDE0A4942Afda17A814d41Ce33B",
"0x50471EcE53a57623F8Dc358DedbcD9418085d855",
"0xe451F67fa26b860333D5866C7cCe3d73570bF6d3",
"0xc0BfB2cbC4e314a7ABdB232b2650BCb6be875f36",
"0xb42d01DC403426fe8681FaD13348Bc375E382Df8",
"0x4399Bc01127d28f759c9a92109E1C73Affa59b23",
"0x68b690a66A52C89D632127Bae0d8542579bbae14",
"0x53f95f79fc93CfDE0A4942Afda17A814d41Ce33B",
"0x63017B087d1a91a4D4769C389B17D964A2D9bf17",
"0xe7184D38e439C2065F3b458f2a7ee18ee6E979C4",
"0xE99e76861b67380B6E03fBcE4aecAc62d6c8a9B6",
"0x88B38c0a95f402c9812fE00b974Bfe7aED8adA11",
"0x9c080d0aC7bC34463E073981115D75eD8A418B25",
"0x2132234ddEAcC84fE4eE3d7fd0eb9F7417e01e87",
"0xB355b541b18848Bbe24321f87e58599e318966cc",
"0xCbA4e0a97d04A0a43f16f8Cc0c2B26467a2c9Ac7",
"0xbb63f531E385be9C544D8EeDEF172cD375627Eb8",
"0x9ED2dda65c0401d08db3d39373834244600cE01f",
"0xdB1a06132dBBC4857b24E628FD630fbf6Dbb6eC7",
"0x5C878046cd34F0179eC60EF30a41a8BEEb737bB0",
"0x3D68db78D9bB22903F066bC26f82feDB7DDC719F",
"0x9999f4B1FAa84A6DaAd8A0A766c495C33B3ac4F9",
"0x72DF163BaCfA83403621a6979F2442A96Edfc46d",
"0xDDb9AB1421E6F1d864c01BA63FB05B183d5ea4d4",
"0x2a8B63707f3Dbd72a3aCA96152386474f6110221",
"0x5d86fB05befc7DF27a2951175f31484B747922de",
"0x09dD64318580671f4Fc61e97d3887417eD58be6C",
"0x4B1444f4C91451c26584678D775Db7D0567f00Df",
"0xbd1149556925859cdcc9dd377653b6db40153e36",
"0xcb4e783Fd4c847c58999d3B8Acd68284427e00F7",
"0x273B8feb49c6593c9Abc9BcD4C2F19fe4dEa5E10",
"0x82BA156f63Bdef4ea09dB3267e86843f0D4350B9",
"0xE8468b7e702C1A38e1D761Bb25B38e0D1fDeCAfa",
"0x1182a0d3943b0c6212B55a2755095E7420888F6e",
"0xDa12aa22cB991FF42C3A7AF907Fe36fceeDdC300",
"0x92E51Ed1DA7Bc7cc558aEe1e9eC5d8E5dCdDBb84",
"0x950c78AB8926CD9B505Ca71d3705D40818a0B3F5",
"0xfB44fb1f9bB2213190EeAF88cCDC54684b61d7eE",
"0xe6cC3F3f57d597b4a21EC24bD3F608B28efd44ea",
"0x86423FBDA4d4EE1a89FD688376125A94c8595758",
"0x39219EA64b27a8921977B3870Db74F7e132AFcc7",
"0xD54B3eF97A80A4193f6E8cE32171330CB4291D77",
"0x5Af8e1b347dc1B994609FdA2BD4e2d8e2E0a8AF5",
"0xdcaa2C1064bEc96d53Dee577965D8471a48CB1a5",
"0x66368a1B3A81d792bEdF0B7637E1f9c922518b22",
"0x1Ec0D5de85f8582ba4cb174e9d610624021FA0b3",
"0x6E2573E8199B23B9A1e4bd6b9e8838302bea5707",
"0x938A65d95FD0e038e275CfEb69e2cB4Bcb432c81",
"0xcc43b1a95b48a3c884181c78682e8a35f99bce41",
"0xa55EE4B08df0125687540dA23BAabfFF08355Dc3",
"0x8D324DC828948aB753E45217A831135a3E1A1351",
"0x702C95233ca8A60e1977B815Ef2D6C724d2B785c",
"0xD154b29aEB90dD858853da94E447b6538199B0C3",
"0xdb769dAA3332AE6c23352a9827EB98fD0f204EbA",
"0xF060Dc51DD57abAD1353b3d21624DEF9dcD9C4E0",
"0x3428A10f1E2962C62fC5cC571E47B45f631adeF8",
"0xF518eE482E8FEA2AD3B669FE59247E8091d4d28D",
"0xCf7f51347E9420268375dF12C6BaD832df233146",
"",
"0x9d03BCd4cA2c5F118CB28e2DF59114F260b3aE8a",
"0x06859Cf8D2feCdC74D386f4c2B83a5d5EEbFC41c",
"0xae4e84139804cc18ee4c4daabe5fe264a4600a27",
"0xDe28298e13B9B18Bbf81bB40A2f51ACcb1C2f6fe",
"0x0d26a62fD82665e43028748f187611a0f5F749cE ",
"0xAf11DF798Ec726433AbaA5486Cf1555335DD30e2",
"0x9278004928aBDE9B3426D6B51dC3fB33d3D55524",
"0xCE4Fe2bdF99A85C6F6278dAF4734a7aF506c8795",
"0xbd1849da28B0BB78E61612c54B36C1d607Cf0D3D",
"0x96D184e691c329191c72b57d978A8882a1bFCE4F",
"0x1D726eb59c1A0ABCbF13355140c274353b9D5472",
"0xac9969be02fdec9E753fD2dD79C8Afef8076F1E4",
"0xdb30ED602A78DbE39D2DC60CA4d592Efe975D017",
"0xBaC702e25a5f3A87fC6286E0b545783321740C00",
"0x157Aa38494c0659358Db3664145fF55344A1c814",
"0xA4d2AF62084A834Aa7a2D1174534042a96D21eA9",
"0x949a8336C08ed3823fC2a7790030049D8D296970",
"0x932e3a8CeD511c230761F449301EF3683b6012E5",
"0x49D48b2F56e53670D50be73242Af9f8041221DDC",
"0xf9b3478693a2111d87ece1248ef225c5b644781b",
"0x9283B44A6E4b5C12aD3Ed2A56dFF38D4496E2506",
"0xd39aC2e911Becc7Df091364433c3b699da086351",
"0x0ee38C6615E34Ee9aF2ac305BdD29E259a6e9f2D",
"0xf8298234C70d64457D56139FEAbbE3BE7122a65D",
"0xfc89dCfcD82C343502B8881cBB0596935163cb2A",
"0x4034Bed2f138de45261a9cbE3469d2b7014AbACF",
"0x24defc5ca01716f8fe4f27Ab28ffADbe974b387B",
"0xE9275ac6c2378c0Fb93C738fF55D54a80b3E2d8a",
"0x628b6cEA25c398B90f47042a92a083e000dDc080",
"0x04453C4a56c9eAddf4141Fb64365cc69c2438Fc4",
"0x1f2bCB6d2A3551eB303BCE9d5d5c5c4f2556b750",
"0x8cD385c500170b3E8E5C99b92B14ccb9D53201Ec",
"0x883CBe5027b84a6Ea4210475a465A4Bb87c1C10f",
"0xd9f11854A049A3C193854B286efA8d67127fDCFA",
"0x99245b0928C9739a763d6a60B34c72A960713ed2",
"0x07c80edf955789a6a00ae3953c322336ab64adeb",
"0x58367d36c2E4EFf07A54217e212Dc18559D0373f",
"0xdd17b67F3c9Fb5928a1ca1e638EC5Ff8332Ec7c5",
"0xF0de51Db4cBfb929b92060Cb1A0Bd7794af0beF0",
"0x00569EEd301Cee9457e9A738Ef368d7E20000629",
"0x11DBA2bbB4C1E0c4f3F14Fa252f1AEccCfFebED6",
"0x3041138595603149b956804cE534A3034F35c6Aa",
"0x0a01B206898B01fe8E69CC0DD5bCeCE5758DDD80",
"0x6e79d308A57FFCe3b46D4F5f54D89f53356F407E",
"0x9A6BA129DD7edC303646256f15f0ae7d5FF71710",
"0xba3fEE6D223E91aFceF16c1c3E43B23a7DacA0dD",
"0x2105d66926a88E240e132d5452dE6A9518e742Db",
"0xe78668cb78e60BDbd1Bd330a0cE4645B04b7d9E2",
"0xfAF90529c26EE206079927cfa6C3EA51BB9Dc620",
"0x09c9C2d06031EAD3269A582678CDB0EB4B628F15",
"0x0Ad76F6fe77683CD4408F21925c1cB03cf9270C3",
"0x91e72476a5CC200261BFDa4adA33F7886F4DF3dE",
"0x77714152AB9ca25Cb98FdF56e094A7aE1D12d3C4",
"0xB2B44E9Ac62D27f92b3901B7AcfEDCb9E9488D43",
"0xe1b79e255eF028D132BFA7B4343B9f866aa19644",
"0xB78B86b95687043795b721BdF5A4544F353bB6A4",
"0x12A6c99b093493DE650aAdC2F62a7A03d1A0695F",
"0x334e1Ed13D3110ED90Ed35002D8C04567043a25E",
"0x8F119ad8916ACEf965D6C41Fa2414a5db36535A4",
"0xfba9b68c4Bfc94109B45F76E11307154152B39e7",
"0xA2a7d69F487209d1516ABd6C0B3470f22fa05444",
"0x0e4a576A37F7dadF7b893Bda6B14A29e85EBa126",
"0xc79d7152ab448e2a79052c7a1ee6279f818f6e92",
"0xbEC4eCd0fb39877457D025F82E3F46834324dBaE",
"0x3Ca311E5E652Bd2d3649C41f0883f495C958f76e",
"0x038b99D435595a815196EcE05F6a5191Ab4dC115",
"0xF2a5064a71B3F055160b2554eFAAEA9be75B5170",
"0x799667c8B46ef200E7f56e44966DA938219B5fBb",
"0xcd87A1FeF8EFB74ebF04Ba02CFfA2bdB82013b2E",
"0x73Fb964F740E82204C90734aCeF40d8492048B4c",
"0x692f67fCCE9aC486a6B32fCaf70603D54Fff89e3",
"0x37D31D31208f5E9b7C5d263d94371146A32b6430",
"0xDB00Eb7e4C86965901458aE914c5c2585aDa298b",
"0x9Be3220Bc76247ED56eaEA3F341671B7Be2FeB33",
"0xD42692df64B396256D4B85B9ba7504c35F577ABd",
"0x883F4CF26b98271dE4ee4B2607354B7313c881CA",
"0x61083B5354F67EA12b17d5026A19547287AeC815",
"0x99974A4377B7A0dBe4179C313597cda6ae9BE206",
"0x981af8b52d4a9d8A06B50CCD04b01B0dBe418Eb0 ",
"0x253CBED58A2B4164CFedcFE8f94c3E686a8CB811",
"0x8aC81D37145974Ff347Df22A643464E7C13AB96b",
"0x70b5A2CBAfB2BEA59131dd7ED771D246924E1360 ",
"0xE279Fe8d7614D0767217392187F85284863D83Ab",
"0x7c927e5803aa0077A06442999686EfD6035BBe72",
"0x38246249A85D6227a82CDC10C43C2dd1E0370179",
"0x2D83e33F9c88Ecf424f61b8800188Ba026e3C479",
"0x2eeb493EB7D6d664E0E9328A79118E3f2668dc87",
"0xB82fd820eD07d7c0d0D2FbEd62880ffAa2463D86",
"0x3992F44f6bf0dF217Fc931c0EA2450c854acaCC8",
"0x98532fa1DFeA60e03499ea02F747D7E12d801dC0 ",
"0xC7871E58c7c21a42A1e904c736ec38Cc5D430233",
"0x64B5955e7fB1e6A457332C5A1E5e0bCA287D3503",
"0xC7fE6c3DC025F4A38De102F418734d1280Fb63b4",
"0x05FCFcE619E41b7cAf3Fd8E70e3BDA16E8e64b77",
"0x0E7DEF2B802b6f6fEC68a3Fc7037B8a6F51754c0",
"0xda63126A7139AC5eD71a5bB238960300c62232AA",
"0x14796AB8541498AdD91BCfFEF372EbB86B600599",
"0x510556FED1932D8115817aa755Ffd318AFEF38f3",
"0xEFfa685DD91ec6C1804498AC55fcEb5c592a8758",
"0x104Be7518A497a8924BF2D3dd04f03339E9f3841",
"0xcEFDA5554fA4fC9995D5AADFF667Cc516aeEe239",
"0x90287E1ea448557C4D79095c2729301247b592C9",
"0x421F4d0eDB6e8E64900d5230a9FC95f733bEB239",
"0x1ee418d71bB24fF148bB05CcAC0D1964E6c147C7",
"0xaE73F3527a334196bd3d38a48e4621b7Eca02761",
"0xEd56066F2656E988dF277DE0DB94d199F100f9ae",
"0x80a3f412B21786AA4A3F428692935aA846eD4135",
"0x057cFDEEfFf35aaFf54aC852c52eFc3e2ffeAFA3",
"0x2C5ED7C83FFA4cE5c7c66a8392F5E92B14b3Ad5E",
"0xaFf15eA06801Ade3aC8A94573a109BF2e18D4842",
"0xd6A3519db8a71A3E5b03254267645FF88AD859e5",
"0x3ab108f7888B2288896604F7D43CAB6AB51F6A59",
"0x159E2EC11b49489c5ad91C3Fc76d9e0Cde99d427",
"0x1a0F6A08EEea5891d2E63Cbb4503fF9d7E88FbeA",
"0x311AfE145aa7Ce5400C77EE92F2F19558166ea7c",
"0xac5057f0508deB3EaF33443B676836996A9dF6b3",
"0x77f3d0c605f7426D68C91D2b92aa80609358bce6",
"0xcfE0C27d71BCE489487A5872850a377CF4f9c202",
"0x1B635A7975b975008F3601eD8f058c11dE662877",
"0x85b1e8D0C705CCD932659AB38e07A2CBDB6D5c47",
"0x545557A4aa2019642c4f214331786C37da947A2B",
"0x72B9F88fD1d04F3FcC2be4bD733D1f7166951C9c",
"0xffcCe90352f585eF50Eb1cEAcc800d3b840d2a9a",
"0x934b5699D497Aa156be908522E0FDAf5009666D2",
"0xC8581BA5BDbcA1EFc59026B434b00C542702D963",
"0x9B07AdD4B8d20cf1Bb5a3732168dd0CaA8B829E1",
"0x3E4319453999063d5E16D5af55C7036554738134",
"0x9805f21eB7F46D5b941755CEed8a518c6920138F",
"0xE613fCb8a55A64AE07f109F1fB726B0f4D7839a4",
"0xa63872a970Fc5BffdFea4cC0d40Ec09a05bCe3Df",
"0xC34E95040ed3eDc65B66F59532D5255Ff97a043a",
"0xFAD59EF4EFB4D2D8B8E63047CAEf48A924C0c505",
"0x4a87D1b71937F06Db976631BdFacC82A5cdd076A",
"0x26Fc8207B442a023031d9C84B91716402bD920B8",
"0xE00d090A7038C62E89A7aaFfe0Df260Bb17eC456",
"0xfC484509817aD9689f08bbE78Ce96EFfBC40c981",
"0x3539e0f40c1EE32CD89bDa6725a3c492cB985D97",
"0xEb990A14708A32E39Cd8d24B2386b83785dA3B65",
"0xDF76A9775e6c0087da3248766980B35ca124C8ac",
"0x0F6a3d90B65f8CC98aB60F9BC5AB246d923d3976",
"0x31c49181950384DAC9883519ee3E685c7289534A",
"0x256D04E2a6Bb2518414B95FFC91140Bc28E9017F",
"0x53A2B93E7c54Fa5E6bD7Cd71C0AdFb5f3584aBB1",
"0xEdCA595eA233Fbd7F941a07b9B3a6DCfEe9804E9",
"0x14A087B80f389ab454986E04676cDeF23F383867",
"0xC2eaCFbB2FE0064523758687fE3dDe3bAa76dE4C",
"0xC587F79E394bC895aA52B021D7260c553fd6386D",
"0xEB6ea1546Df6D2DD2f4dA1B5dc52a5a49Fd7cc7a",
"0x2aDc7d0d398661C77af81611431cA52BE673d791",
"0x29de6cD4417D94AAbB0031098832aF0D0cC1ec20",
"0xF839a939eb84f6BAB06B9E8f2e3CA064C38B7779",
"0x6DC8542e1fa9089fa0586Df635f3512AD67F4006",
"0xF8e735b40418f12ed890Eb5B8F598c60f36BCc16",
"0x6fC29F04B1A12A4e69a46765517916b7114693F8",
"0x2c50a641ae7fa8d4679aF1DC1b0f2BF8A5af895e",
"0x338Fff1999A757ACd405070E666c4e1547F5715C",
"0xf185aAdC2dED7D59C0f0C8eCD128BF34e5d9FB26",
"0xf944f5715314af4D0c882A868599d7849AAC266F",
"0xDe35b26a6Ab67a594b71F278845725F2Debcf4ee",
"0x33777754e555adc3bffebefd833497bf6bdfb727",
"0xf9022Bde93979254bdF304eb16D189ab1754EC5B",
"0x4983ACf9aFd7cAd84685711dD41ee6120138dD33",
"0x952D968B82BF8355c2A36f11f91E2111c4CCe691",
"0xc905eA749Ce7c301162470eCb534a65B063b4d06",
"0xBeDAdfAB9BDF0700e6e9EfF7e8BBB2B8991c550d",
"0x98a14ee90e27dd9c1c50be4f1467aba1db0220c7",
"0x01859354d54a0bd7ea6234cd46163a926e74c641",
"0xd5ba7a4541700d2183d0f8e1308975865e5ceb28",
"0x71cca1f6cde602fbae48903e7e785ffb23c39f2f",
"0xFc7af206E1a69F7886fB47fF8e1287fFf4406D03",
"0xF8DA926B6f798a3b264328C35DD68023De78c859",
"0xBF3Fb8f645164976F5223Be4cd4Ba81aa4F3Db81",
"0x92509d03343C3173cFC48ff12844efB1F3741264",
"0x28afC128874229e557d6870e93dE93d8eFCF3718",
"0x189E95603298257390ef807e077887004718C8c1",
"0xB00Fe8F68DF3fC1a68d1e8d96C8C8bF11FF750D2",
"0x1859714500877bb557A4271Be93C049780ab221c",
"0x0CE02D3a89efa218CD0f486514CAe77D74b88bEe",
"0xebdB40f3c45c19f060e9413D8c7b93209d0F289c",
"0xB91627ff8913aCaD42b8Ab83ff2a0469b70425f0",
"0xdf6d106b6311eD2A165D78137c2D2e4c3373d979",
"0xCB08C4171fD1FdA994605076F036Ff5B126e9F2F",
"0xa0545e076122f52A7e2cc672f9fb9403EB310ABf",
"0x532b7b0B8DcCCa7464A48548cFf76557d8aBe4F2",
"0x6Cc094a60935d8A3Be1d322c08981B2C6cbb132b",
"0x056237475b3e0659c71434938680F821C1Ebf639",
"0x4CA8146910c0616F594c1c5750B39A74a9232D77",
"0xdb3be154AeB741867196A918fa2Bd5f704dc022A",
"0x6aFaD62C0902e1abA89AF7eC1c9032Ac8fdc0998",
"0x09eC9338AD0B379c54c9B046A37bEF97e4b59Ac5",
"0x0BdA5FfA68972Ae3586102deF7f97083B6aB54A3",
"0xaC5F857cdEa4A4AeA07b5C6218Eb731144a50C6b",
"0xCDeBD69B1d2C6e3f7E6746dCc19C4CDd24ac12Ec",
"0x94a6a655D0D5CDEc20c8CB14e29AC79B6C79DBb9",
"0x014c96f838e13c31192201924512B0d4850033E2",
"0xa3924eeA5c05f3AaF73b5F68318a2c79633AF090",
"0x1fc540894ae94ee9adC464dbD1cF8185EC0f68e4",
"0x53E71b9D7EFfDC75E0891E43E73C3f564cBDaCb5",
"0x2936b5eD22844a3BfDC23ebEaF79C4370F40B98A",
"0x00e38dDcbd8E58a8D49eaFBE16b11cb8842c3B9a",
"0x2cd98D640F570916Dc19De33dFED43a13f3Fa7f9 ",
"0xbfA656167BA1fb5AA6199c0bfD6E9457777EEc8B",
"0x47734B0f659e8fCee5ADd2f4D29f50E09D232BF0",
"0x3577E232C84119a918477efc21490acCa2Cb34a1",
"0xa495FB3EF5Ad8323ebE5B369f81785DB8236E018",
"0xbeEa49fD389fC2b89705b9Db12001227BA7072fe",
"0x9e85280CB47aE823Ff1d817E8bc969fc08ABA6fB",
"0x3984ce896301BB2D44Ee1BE6fD098459a2169693",
"0x1da328ebc2df14da160f0f7e8f4a678ee40bd435",
"0xFb84e38FA1dB7e6A4764da8ffAa28d91cfce7cBd",
"0xeD28AF504dC907600dCBe4bb7814C812e70671BE",
"0x9268237f8acCc682026b0b9B3E76d1B613817466",
"0x74F4D13C8B58F974245f3a820fffA1E2282A51A6",
"0x7133B7EF6470F0819c36E60BD8Fc447997A855B3",
"0xE1a528Bf5EA0594DA3C596Fc95Ed6dcb239E6885",
"0x7b2EcF451d982A5dEE29BeB9F891F17bb3058503",
"0x47e2facCA5113C554FF0b9847539af7580FF92c7",
"0x44a82b1C154C7b6e4beB9884Db4F01Dbf040E877",
"0x9Fc96c63E9Fb9596c0100d1a3528A46109Fded6d",
"0x60f3bcdE522276D5dFfCA9CeA976f3333CEcaEc3",
"0x2011335D934240d3A2BAa78B9ce4371E56Ec9D85",
"0xf362F7EA4a7e187b2297dD3851511459FE8A9079",
"0x404eAF1dFe3E790F000cBE4bcbfCF485a235b437",
"0x5B5e609D878040fb0D818e91466244fDB7c54Ba3",
"0xde8A0426c6ff0187E3133aC4A6b27e1c6e820C4c",
"0xe365abA924c6105dA509fca843C783132bd6c113",
"0x4fa0e8318DFBb42233eCb5330661691fa802c458",
"0x83EaA3797DA6D83f98B5386b2DF35b412954bb4E",
"0x537b2671238Dc3db1352668D0F4f4651da8ecc6D",
"0x72335Da64ba698972549D3Fe6071D8E0201a85b0",
"0xcacB2bEd1259f8e3853b89bB4d407B6C3ffaAa69",
"0x11AFed04dA53C19416730794456379e1b589A7B4",
"0x97c4A9935441ca9Ee67C673E293e9a5c6A170631",
"0xda1A76bC9a1f7eA0d2d6001586ee23c8B4ea0c3A",
"0x6eeF5898826F1925f06e633743b23Bf0683Db3F6",
"0x3d5fE6aA41c54F5A934Fa221dE26c0cE427DD612",
"0xaefbB5350943c6b39Aa25aBb86005C1EE6BF84ff",
"0xf98f7132BB7e3D46481164d2d5700A37FB1a1D2D",
"0xE5A00878De0bD4E8d3623bd1B0740fAF67179Af3",
"0x60f4d73B39DBFeC50E9C9FEd9b80471bB180C5fD",
"0x28c0D774495801c3F0c911029f7DC34C1724A940",
"0x45239c4e79F90B107E59cA2a4e4DcBDe095afd1e",
"0x8c329f1976BE9a509c6d57C02E010B1cC5906590",
"0xc25754645642722f8aD12B0b6B07e467D9adC2B7",
"0x13895E84e8a6aA7C221A786FFF44205ec2cA9Fd6",
"0xD80E91A4367E3Be0872c9Bbf740D48d3436b224c",
"0x42EB67B16bf82fc617404Bf86235520AE56a481D",
"0x25954Fb49bFc6A2A09770be5CCA756c8676F31ba",
"0xDaDEBB53C8139908b67E13b5DbeE24650EC6eE36",]
*/