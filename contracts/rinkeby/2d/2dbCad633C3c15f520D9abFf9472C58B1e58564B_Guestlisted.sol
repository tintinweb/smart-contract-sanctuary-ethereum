/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/*

  Guestlisted by @etherlect

  ____________________________________________________________
 /                                                            \ 
/______________________________________________________________\   
|   [+]     [+] [+] [+] [+]   CLUB   [+] [+] [+] [+]     [+]   |   
================================================================
 |  [+]     [+] [+] [+] [+] [+]  [+] [+] [+] [+] [+]     [+]  |
 |----------------------------------------------------------- |
 |  +-+  |  +-+ +-+ +-+ +-+ +-+  +-+ +-+ +-+ +-+ +-+  |  +-+  |
 |  |*|  |  |*| |*| |*| |*| |*|  |*| |*| |*| |*| |*|  |  | |  |
 |  +-+  |  +-+ +-+ +-+ +-+ +-+  +-+ +-+ +-+ +-+ +-+  |  +-+  |                                         
 |  [ ]  |  [+] [+] [+] [+] [+]  [+] [+] [+] [+] [+]  |  [ ]  |
 |  +-+  |                    +--+                    |  +-+  |    
 |  | |  |                    |  |                    |  | |  |   
 ==============================================================
 _ --  --_  --  _ -  __  -    |  |    __ --   - _ --    --- _ _
 _    --- __  -   _--   __ -  |  |  _  - __ -- ___ -- _ - __ - 
    __ --      - -   _ -  -   |  |    _ - _ -- _ --- _ -- _ ---  

*/


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



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


// File @openzeppelin/contracts/security/[email protected]



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
     * by making the `nonReentrant` function external, and make it call a
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


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/GuestlistedLibrary.sol

// File contracts/GuestlistedLibrary.sol

pragma solidity ^0.8.12;

library GuestlistedLibrary {
    struct Venue { 
        string name;
        string location;
        uint[2][] indexes;
        string[] colors;
        uint[] djIndexes;
    }

    struct DJ { 
        string firstName;
        string lastName;
        uint fontSize;
    }

    struct DrawData {
        uint tokenId;
        uint deterministicNumber;
        uint randomNumber;
        uint shapeRandomNumber;
        uint shapeIndex;
        string json;
        string date;
        string bg;
        string color;
        string shape;
        string attributes;
        string customMetadata;
        string djFullName;
        Venue venue;
        DJ dj;
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}


// File contracts/Guestlisted.sol


pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;


contract Guestlisted is ERC721, ReentrancyGuard, Ownable {
    
    using ECDSA for bytes32;

    // -------------------------------------------------------------------------------------------------------
    // 
    //  Mint config
    //  
    //  @startIndex                 =>      Start index from which to mint tokens
    //  @endIndex                   =>      End index until which to mint tokens
    //  @remaining                  =>      Remaining tokens to mint
    //  @mintPrice                  =>      Current mint price (in WEI)
    //  @maxTokensPerTransaction    =>      Max allowed tokens to mint per transaction
    //  @maxMintsPerWallet          =>      Max allowed tokens to mint per wallet
    //  @version                    =>      Used as a key along with wallet address in mintedPerWallet mapping
    //  @isActive                   =>      State of the mint
    //  @isRandom                   =>      Mint strategy (random / predictable)
    //  @isOnlyForHolders           =>      Allows only token holders to mint
    //  @isOnWhitelist              =>      Request a signature of wallet address by whitelistSigner
    //  @whitelistSigner            =>      Whitelist signer address which should be recovered while minting
    //  
    // -------------------------------------------------------------------------------------------------------
    struct MintConfig { 
        uint startIndex;
        uint endIndex;
        uint remaining;
        uint mintPrice;
        uint maxTokensPerTransaction;
        uint maxMintsPerWallet;
        uint version;
        bool isActive;
        bool isRandom;
        bool isOnlyForHolders;
        bool isOnWhitelist;
        address whitelistSigner;
    }

    // ------------------------------------------------------------------------
    // 
    //  If exists, custom metadata is added in the JSON metadata of tokens:
    //  
    //  { 
    //      ...other properties,
    //      name: value,
    //      name: value,
    //      ...
    //  }
    //  
    // ------------------------------------------------------------------------
    struct CustomMetadata { 
        string name;
        string value;
    }

    // ------------------------------------------------------------------------
    // 
    //  If exists, custom attributes are added in the JSON metadata of tokens:
    //  
    //  {
    //      "attributes": {
    //          ...other attributes,
    //         {
    //             "display_type": displayType, 
    //             "trait_type": traitType, 
    //             "value": value
    //         }
    //      } 
    //  }
    //  
    // ------------------------------------------------------------------------
    struct CustomAttribute { 
        string displayType;
        string traitType;
        string value;
    }
    
    // ------------------------------------------------------------------------
    // 
    //  Mapping storing the number of mints per wallet
    //  string(abi.encodePacked(walletAddress, mintConfig.version)) => nbMinted
    // 
    // ------------------------------------------------------------------------
    mapping(string => uint) public mintedPerWallet;

    // --------------------------------------------------------
    // 
    //  Mapping storing already minted tokens
    // 
    // --------------------------------------------------------
    mapping(uint => uint) private mintCache;

    // --------------------------------------------------------
    // 
    //  Mappings for eventual future custom metadata & 
    //  attributes of tokens (added in the JSON if exists)
    //  tokenId => CustomAttribute[] / CustomMetadata[]
    // 
    // --------------------------------------------------------
    mapping(uint => CustomAttribute[]) public customAttributes;
    mapping(uint => CustomMetadata[]) public customMetadata;

    // --------------------------------------------------------
    // 
    //  Mapping returns if the color of the
    //  text should be white given a bg color
    //  bgColor (hex) => 0 (true) / 1 (false)
    // 
    // --------------------------------------------------------
    mapping(string => uint) public isTextColorWhite;

    // --------------------------------------------------------
    // 
    //  Instantiation of global variables
    // 
    // --------------------------------------------------------
    
    uint public totalSupply;
    uint public minted;
    uint public burned;
    bool public isBurnActive;
    GuestlistedArtProxy public artProxyContract;
    MintConfig public mintConfig;
    GuestlistedLibrary.Venue[] private venues;
    GuestlistedLibrary.DJ[] private djs;

    // --------------------------------------------------------
    // 
    //  Returns the metadata of a token (base64 encoded JSON)
    // 
    // --------------------------------------------------------
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");

        // --------------------------------------------------------
        // 
        //  Building drawData used in the artProxyContract
        // 
        // --------------------------------------------------------
        GuestlistedLibrary.DrawData memory drawData;
        drawData.tokenId = _tokenId;
        drawData.deterministicNumber = deterministic(GuestlistedLibrary.toString(_tokenId));
        drawData.randomNumber = random(GuestlistedLibrary.toString(_tokenId));
        drawData.shapeRandomNumber = drawData.deterministicNumber % 100;

        // --------------------------------------------------------
        // 
        //  Iterate indexes of each venue and pick the venue
        //  corresponding to the _tokenId
        // 
        // --------------------------------------------------------
        for (uint i = 0; i < venues.length; i++) {
            for (uint j = 0; j < venues[i].indexes.length; j++) {
                if (venues[i].indexes[j][0] <= _tokenId && 
                    venues[i].indexes[j][1] >= _tokenId) {
                    drawData.venue = venues[i];
                    break;
                }
            }
        }

        // --------------------------------------------------------
        // 
        //  Pick the date, bg, text color and dj for a given 
        //  tokenId and the selected venue
        // 
        // --------------------------------------------------------
        drawData.date = getDate(_tokenId);
        drawData.bg = drawData.venue.colors[drawData.deterministicNumber % drawData.venue.colors.length];
        drawData.color = isTextColorWhite[drawData.bg] == 1 ? 'ffffff' : '393D3F';
        drawData.dj = djs[drawData.venue.djIndexes[drawData.deterministicNumber % drawData.venue.djIndexes.length]];
        

        // --------------------------------------------------------
        // 
        //  Pick a shape
        // 
        // --------------------------------------------------------
        
        // circle = 25% of chances
        drawData.shapeIndex = 0;
        drawData.shape = 'circle';

        if (drawData.shapeRandomNumber > 25 && drawData.shapeRandomNumber <= 35) {
            // line => 10% of chances
            drawData.shapeIndex = 4;
            drawData.shape = 'line';
        } else if (drawData.shapeRandomNumber > 35 && drawData.shapeRandomNumber <= 55) {
            // prism => 20% of chances
            drawData.shapeIndex = 1;
            drawData.shape = 'prism';
        } else if (drawData.shapeRandomNumber > 55 && drawData.shapeRandomNumber <= 80) {
            // cube => 25% of chances
            drawData.shapeIndex = 3;
            drawData.shape = 'cube';
        } else if (drawData.shapeRandomNumber > 80 && drawData.shapeRandomNumber <= 100) {
            // square => 20% of chances
            drawData.shapeIndex = 2;
            drawData.shape = 'square';
        }

        drawData.djFullName = string(
            abi.encodePacked(
                drawData.dj.firstName, 
                bytes(drawData.dj.lastName).length == 0 ? '': string(abi.encodePacked(' ', drawData.dj.lastName))
            )
        );

        // --------------------------------------------------------
        // 
        //  Build attributes
        // 
        // --------------------------------------------------------
        drawData.attributes = string(
            abi.encodePacked(
                '{"trait_type":"venue","value":"',
                drawData.venue.name,
                '"}, {"trait_type":"dj","value":"',
                drawData.djFullName,
                '"}, {"trait_type":"date","value":"',
                drawData.date,
                '"}, {"trait_type":"shape","value":"',
                drawData.shape,
                '"}, {"trait_type":"background","value":"',
                drawData.bg,
                '"}, {"trait_type":"color","value":"',
                drawData.color,
                '"}'
            )
        );

        // --------------------------------------------------------
        // 
        //  Build custom attributes of the token if there is any
        // 
        // --------------------------------------------------------
        for (uint i = 0;i < customAttributes[_tokenId].length; i++) {
            drawData.attributes = string(
                abi.encodePacked(
                    drawData.attributes,
                    ',{"display_type":"',
                    customAttributes[_tokenId][i].displayType,
                    '","trait_type":"',
                    customAttributes[_tokenId][i].traitType,
                    '","value":"',
                    customAttributes[_tokenId][i].value,
                    '"}'
                )
            );
        }

        // --------------------------------------------------------
        // 
        //  Build custom metadata of the token if there is any
        // 
        // --------------------------------------------------------
        for (uint i = 0;i < customMetadata[_tokenId].length; i++) {
            drawData.customMetadata = string(
                abi.encodePacked(
                    drawData.customMetadata,
                    ',"',
                    customMetadata[_tokenId][i].name,
                    '":"',
                    customMetadata[_tokenId][i].value,
                    '"'
                )
            );
        }

        // --------------------------------------------------------
        // 
        //  Build final token metadata JSON
        //  (get the image from proxy art contract)
        // 
        // --------------------------------------------------------
        drawData.json = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"guestlisted #',
                    GuestlistedLibrary.toString(_tokenId),
                    ' - ',
                    drawData.djFullName,
                    ' at ',
                    drawData.venue.name,
                    '", "id": "',
                    GuestlistedLibrary.toString(_tokenId),
                    '", "description":"You are guestlisted.", "image":"',
                    artProxyContract.draw(drawData),
                    '", "attributes":[',
                    drawData.attributes,
                    ']',
                    drawData.customMetadata,
                    '}'
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", drawData.json));
    }

    // --------------------------------------------------------
    // 
    //  Returns a random index of token to mint depending on
    //  sender addr and current block timestamp & difficulty
    // 
    // --------------------------------------------------------
    function getRandomTokenIndex (address senderAddress) internal returns (uint) {
        uint randomNumber = random(string(abi.encodePacked(senderAddress)));
        uint i = (randomNumber % mintConfig.remaining) + mintConfig.startIndex;

        // --------------------------------------------------------
        // 
        //  If there's a cache at mintCache[i] then use it
        //  otherwise use i itself
        // 
        // --------------------------------------------------------
        uint index = mintCache[i] == 0 ? i : mintCache[i];

        // --------------------------------------------------------
        // 
        //  Grab a number from the tail & decrease remaining
        // 
        // --------------------------------------------------------
        mintCache[i] = mintCache[mintConfig.remaining - 1 + mintConfig.startIndex] == 0 ? mintConfig.remaining - 1 + mintConfig.startIndex : mintCache[mintConfig.remaining - 1 + mintConfig.startIndex];
        mintConfig.remaining--;

        return index;
    }

    function mint(uint _nbTokens, bytes memory signature) public payable nonReentrant  {
        require(mintConfig.isActive, "The mint is not active at the moment.");
        require(_nbTokens > 0, "Number of tokens can not be less than or equal to 0.");
        require(_nbTokens <= mintConfig.maxTokensPerTransaction, "Number of tokens can not be higher than allowed.");
        require(mintConfig.remaining >= _nbTokens, "The mint would exceed the number of remaining tokens.");
        require(mintConfig.mintPrice * _nbTokens == msg.value, "Sent ETH value is incorrect.");

        // --------------------------------------------------------
        // 
        //  Check signature if mintConfig.isOnWhitelist is true
        // 
        // --------------------------------------------------------
        if (mintConfig.isOnWhitelist) {
            address recoveredSigner = keccak256(abi.encodePacked(_msgSender())).toEthSignedMessageHash().recover(signature);
            require(recoveredSigner == mintConfig.whitelistSigner, "Your wallet is not whitelisted.");
        }

        // --------------------------------------------------------
        // 
        //  Check if minter is holder if 
        //  mintConfig.isOnlyForHolders is true
        // 
        // --------------------------------------------------------
        if (mintConfig.isOnlyForHolders) {
            require(balanceOf(_msgSender()) > 0, "You have to own at least one token to mint more.");
        }

        // --------------------------------------------------------
        // 
        //  Check if minter has not already reached the
        //  limit of mints per wallet + update the mapping
        //  minterKey is composed of the wallet address and version
        //  version can be updated to reinit all wallets to 0 mints
        // 
        // --------------------------------------------------------
        string memory minterKey = string(abi.encodePacked(_msgSender(), mintConfig.version));
        require(mintedPerWallet[minterKey] + _nbTokens <= mintConfig.maxMintsPerWallet, "Your wallet is not allowed to mint as many tokens.");
        mintedPerWallet[minterKey] += _nbTokens;

        // --------------------------------------------------------
        // 
        //  Mint depending on mint strategy: random / predictable
        // 
        // --------------------------------------------------------
        if (mintConfig.isRandom) {
            for (uint i = 0; i < _nbTokens;i++) {
                totalSupply++;
                minted++;
                _safeMint(_msgSender(), getRandomTokenIndex(_msgSender()));
            }
        } else {
            for (uint i = 0; i < _nbTokens;i++) {
                // --------------------------------------------------------
                // 
                //  Update mint cache & remaining before mint
                // 
                // --------------------------------------------------------
                totalSupply++;
                minted++;
                mintCache[minted] = mintConfig.remaining - 1 + mintConfig.startIndex;
                mintConfig.remaining--;
                _safeMint(_msgSender(), minted);
            }
        }
    }

    function burn(uint _tokenId) external {
        require(isBurnActive, "Burning disabled.");
        require(_exists(_tokenId), "The token does not exists.");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of the token.");
        totalSupply--;
        burned++;
        _burn(_tokenId);
    }

    // --------------------------------------------------------
    // 
    //  Returns a date for a tokenId
    //  date range: 01.01.22 - 28.12.25
    // 
    // --------------------------------------------------------
    function getDate (uint256 _tokenId) internal pure returns (string memory) {
        uint deterministicNumber = deterministic(GuestlistedLibrary.toString(_tokenId));
        uint day = deterministicNumber % 28 + 1;
        uint month = deterministicNumber % 12 + 1;
        uint yearDeterministic = deterministicNumber % 4;
        string memory yearString = '22';

        if (yearDeterministic == 1) yearString = '23';
        else if (yearDeterministic == 2) yearString = '24';
        else if (yearDeterministic == 3) yearString = '25';

        string memory dayString = GuestlistedLibrary.toString(day);
        if (day < 10) dayString = string(abi.encodePacked('0', dayString));

        string memory monthString = GuestlistedLibrary.toString(month);
        if (month < 10) monthString = string(abi.encodePacked('0', monthString));

        return string(abi.encodePacked(dayString, '.', monthString, '.', yearString));
    }

    // --------------------------------------------------------
    // 
    //  Returns a deterministic number for an input
    // 
    // --------------------------------------------------------
    function deterministic (string memory input) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(input)));
    }

    // --------------------------------------------------------
    // 
    //  Returns a relatively random number for an input
    //  depending on current block timestamp & difficulty
    // 
    // --------------------------------------------------------
    function random (string memory input) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, input)));
    }

    // --------------------------------------------------------
    // 
    //  Updates a venue in the storage at specified index
    //  Adds a new venue if the index is -1
    // 
    // --------------------------------------------------------
    function updateVenue (int _index, GuestlistedLibrary.Venue memory _venue) public onlyOwner {
        require((_index == -1) || (uint(_index) < venues.length), 'Can not update non-existent venue.');
        if (_index == -1) venues.push(_venue);
        else venues[uint(_index)] = _venue;
    }

    function getVenueByIndex (uint _index) external view returns (GuestlistedLibrary.Venue memory) {
        require(_index < venues.length , 'Venue does not exists.');
        return venues[_index];
    }

    // --------------------------------------------------------
    // 
    //  Updates a dj in the storage at specified index
    //  Adds a new dj if the index is -1
    // 
    // --------------------------------------------------------
    function updateDJ (int _index, GuestlistedLibrary.DJ memory _dj) public onlyOwner {
        require((_index == -1) || (uint(_index) <= djs.length - 1), 'Can not update non-existent dj.');
        if (_index == -1) djs.push(_dj);
        else djs[uint(_index)] = _dj;
    }

    function getDJByIndex (uint _index) external view returns (GuestlistedLibrary.DJ memory) {
        require(_index < djs.length , 'DJ does not exists.');
        return djs[_index];
    }

    function updateIsTextColorWhite (string memory bg, uint value) public onlyOwner {
        require(value == 0 || value == 1, 'Wrong value.');
        isTextColorWhite[bg] = value;
    }

    function updateArtProxyContract(address _artProxyContractAddress) public onlyOwner {
        artProxyContract = GuestlistedArtProxy(_artProxyContractAddress);
    }

    // --------------------------------------------------------
    // 
    //  Update the adress used to sign & recover whitelists
    // 
    // --------------------------------------------------------
    function updateWhitelistSigner(address _whitelistSigner) external onlyOwner {
        mintConfig.whitelistSigner = _whitelistSigner;
    }

    // ----------------------------------------------------------------
    // 
    //  Erease and update the custom metadata for a set of tokens.
    //  This metadata will be added to specified tokens in the
    //  tokenURI method.
    // 
    // ----------------------------------------------------------------
    function updateCustomMetadata (uint[] memory _tokenIds, CustomMetadata[] memory _customMetadata) external onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            delete customMetadata[_tokenIds[i]];
            for (uint j = 0; j < _customMetadata.length; j++) {
                customMetadata[_tokenIds[i]].push(_customMetadata[j]);
            }
        }
    }

    // ----------------------------------------------------------------
    // 
    //  Erease and update the custom attributes for a set of tokens.
    //  Those attributes will be added to specified tokens in the
    //  tokenURI method.
    // 
    // ----------------------------------------------------------------
    function updateCustomAttributes (uint[] memory _tokenIds, CustomAttribute[] memory _customAttributes) external onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            delete customAttributes[_tokenIds[i]];
            for (uint j = 0; j < _customAttributes.length; j++) {
                customAttributes[_tokenIds[i]].push(_customAttributes[j]);
            }
        }
    }

    function updateMintConfig(MintConfig memory _mintConfig) public onlyOwner {
        mintConfig = _mintConfig;
    }

    function flipBurnState() external onlyOwner {
        isBurnActive = !isBurnActive;
    }

    function flipMintState() external onlyOwner {
        mintConfig.isActive = !mintConfig.isActive;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ----------------------------------------------------------------
    // 
    //  Returns un array of tokens owned by an address
    //  (gas optimisation of tokenOfOwnerByIndex from ERC721Enumerable)
    // 
    // ----------------------------------------------------------------
    function tokensOfOwner(address _ownerAddress) public virtual view returns (uint[] memory) {
        uint balance = balanceOf(_ownerAddress);
        uint[] memory tokens = new uint[](balance);
        uint tokenId;
        uint found;

        while (found < balance) {
            if (_exists(tokenId) && ownerOf(tokenId) == _ownerAddress) {
                tokens[found++] = tokenId;
            }
            tokenId++;
        }

        return tokens;
    }

    constructor(
        address _artProxyContractAddress,
        MintConfig memory _mintConfig,
        GuestlistedLibrary.Venue[] memory _venues, 
        GuestlistedLibrary.DJ[] memory _djs, 
        string[] memory bgsWithWhiteTextColor,
        uint[] memory _ownerReserve
    ) ERC721("guestlisted", "guestlist") Ownable() {
        // --------------------------------------------------------
        // 
        //  Setup the art proxy contract instance
        // 
        // --------------------------------------------------------
        updateArtProxyContract(_artProxyContractAddress);

        // --------------------------------------------------------
        // 
        //  Update the mintConfig
        // 
        // --------------------------------------------------------
        updateMintConfig(_mintConfig);

        // --------------------------------------------------------
        // 
        //  Store venues
        // 
        // --------------------------------------------------------
        for (uint i = 0;i < _venues.length; i++) {
            updateVenue(-1, _venues[i]);
        }

        // --------------------------------------------------------
        // 
        //  Store djs
        // 
        // --------------------------------------------------------
        for (uint i = 0;i < _djs.length; i++) {
            updateDJ(-1, _djs[i]);
        }

        // --------------------------------------------------------
        // 
        //  Store backgounds that has white text color
        // 
        // --------------------------------------------------------
        for (uint i = 0; i < bgsWithWhiteTextColor.length; i++) {
            updateIsTextColorWhite(bgsWithWhiteTextColor[i], 1);
        }

        // --------------------------------------------------------
        // 
        //  Mint owner reserved tokens
        // 
        // --------------------------------------------------------
        for (uint i = 0; i < _ownerReserve.length; i++) {
            mintCache[_ownerReserve[i]] = mintConfig.remaining - 1 + mintConfig.startIndex;
            totalSupply++;
            minted++;
            mintConfig.remaining--;
            _safeMint(owner(), _ownerReserve[i]);
        }
    }
}

// --------------------------------------------------------
// 
//  Art proxy contract function signature
// 
// --------------------------------------------------------
contract GuestlistedArtProxy {
    function draw (GuestlistedLibrary.DrawData memory drawData) public view returns (string memory) {}
}