/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: MIT

/**
    @title ERC721 NFT for FatChoy
    @author KontonLorenz
    @dev Built on the back of the Hashlips NFT Contract template - which itself is built on openzepplin's repository
    @notice Fat Choys are here to bring prosperity to 2022 - Get them before it's too late!
*/

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

contract FatChoy is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmount = 20;
  bool public paused = true;
  bool public revealed = true;
  bool public whitelistPaused = true;
  string public notRevealedUri;

  address[] public whitelist;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);

    whitelist = [
        0xA327a16b71bA107393E0dC046B0Be0908AA667aD,
        0x6CC0d7791db228b66c190462eA19FCa92AA1f25F,
        0xc3250be2F664Db7b423973adfd400e4c5541A445,
        0x9311D45341b284900711F9BC155ce2E381248c29,
        0xb4103329230dB58eA6E2480e4022B577833600dF,
        0x8f1CA5Ff845AD2B2527686BC62c3145B92331531,
        0x8Da15F7e6bf20Eae393D0210d0F69eA98fC8Ea5e,
        0x8791C9057566AF6F55f18FDbeA4465E1B1ee2f8E,
        0x08FCa0C57FeC5Cf118A5Bb1474B3dF7942aB877f,
        0xFda54B47e5D4762bb43fC282d33279cfd1b2026C,
        0xFc9e2CF27dAd13B149dD476eeEd2B46E061A1a6d,
        0x7Ea9b8ba0d889Ba42458f657Ed27244AD593dfe7,
        0x0929a4109E7BfD43270Aa3C84084168dcE2A2955,
        0x9829335c360932CB6C17e5A51836de33A0Ae30ef,
        0xc7D47D1f5357Ae5e61BCa9C6D287dF6c5115C415,
        0xDEc096F829AAc7bF4b9D927903eF08F51De34a21,
        0x61ba11A8E0c7005767929c6781A8d3f322C2886D,
        0x954E128f3e3d85ba3aDaFB9d53e7c060833e2Bb0,
        0x5a7fFE8A96d7aBfbBE3B4A239130515F7d2E0ec0,
        0xbf9Fda32692b25c6083cbe48399eF019B62F0712,
        0xd87E0f3F988c2f271CdB2019381b47Ab57115414,
        0x52A8d97577983706F91EcA67513a3412F155a166,
        0xa516BB97dBC89832e9AA02Ea420E63a67EE2cE53,
        0x60EE37531AB136232C8736759F65228129da7a91,
        0x4575890793Ac619ac4E5B6f3849beEf5f1E8D928,
        0x341D13B93a9e6eC3B9b2B5C3EE7747D6eC95Cf69,
        0x062f08f9999a2aeb8235Bb5Fb4B0321C5F6aF10F,
        0xc3250be2F664Db7b423973adfd400e4c5541A445,
        0x10FBec46F97087503b7c535ba645F33ef1Eb692F,
        0x80Cfaf6273eb4C5537914fF492c9a7Ff72DeB433,
        0x7919A9C5961d895CDa921F6E0396E40a3d6f7e51,
        0x48E31c1048f50Ae93d3Db523129AAfC9De2B2b52,
        0x472C4D5EE8B29664a09940e20F2BC871e2b61A06,
        0x29104975057C20062596FB755047c1C9fb59daaE,
        0x407303a3D2c34196EA610911688472C3A223f51B,
        0x97061119a6D30432b0CBD2a28cda2FE8f109e710,
        0x6d9ed472Da62B604eD479026185995889ae8f80e,
        0x0f17ac7a5f4d6A9b1c5876E98bCFf33Ddf33905a,
        0x17e1Ac278b39822AE6B1C8A25b7938ad4672EDC7,
        0x6fec6cB90D4bc025D5249F299d640D66FCbfb6eb,
        0xb464CA834796272E08Dc6460940B281B046a2cEe,
        0x337CfB6E0466977c6419D5DcA8FA8B82904787b1,
        0x1482A191208754D05B69c89f499995FC89e4397C,
        0x4291156c56f09d7E30B33CEA68BF745dFd475C24,
        0xb0C4c6A91a9ed11A89A1EF69de09A3254D6d87E2,
        0x9996b0883179B9f27C20BdCB565a041dBca2eebe,
        0xfdD6D56486B6A1c1CBFc1a1f6cE2573875DaA7df,
        0x744f7738bf3a9446E300FD4E04aF8A2dab1098b5,
        0x649cbF9adb764aC365960eE3e43457c4Aab5c319,
        0x55beA373713D08023659Caa997e2CC282e9B786e,
        0xA10902C668bF73De06471adeF3E47cf56f00602B,
        0xaC72BCf83a55713a49A08420477fDf6f3C9b50FE,
        0xFC8553A7bb0BbB9a7642ACef2224205334C8Ddc0,
        0xeA921aCfe2d96D30690e06b5d4D64be6e1192ce6,
        0x3d8a60d69e4Ce4150177B0B77cb9aC093FCC2c43,
        0x476799Eaf7A58a7A8ebea73a15FC2B7B834151A4,
        0xD7c85b73f7dfb9Ce969025ac931F9C7f17e82Caa,
        0x9cA3AC1637680879cDcaCa85d5E25422c05Eb9F8,
        0x8068BD398396B060d820745FDE9C545a38bb776d,
        0xCE78550a045441905BCEb92C378f67574211439d,
        0x815e969a2bf9a910A09eC5A88EC78BDC90e7957D,
        0x057C416df3cE3Bd89E86A1fB764B106698048FE7,
        0x182B32912D74A620124F7BdC13f6dA38c5DbE8CF,
        0x6C134832ba6b733419e27413176d2cf685075401,
        0xa516BB97dBC89832e9AA02Ea420E63a67EE2cE53,
        0xD827eb2673D3Dc1a7F886413f6f0950Ec2fbBc98,
        0x4892cfe386f14Cf8640F6CA124E0F97DC1b7af57,
        0xF33fd427e695B63C81F238b5d8EA75Aea31d15a4,
        0x2694e8fd3B504Ea897e94391A78F921Ab0250703,
        0x607054b35f06c5b5224A5922b214C33D163f4D90,
        0x1AA963E68CFDE4dab1Df1E15E70B2BB4103c4848,
        0xB71b2eCc3DAa289452d6ff3b34Ef2F5643337505,
        0xdfDf2D882D9ebce6c7EAc3DA9AB66cbfDa263781,
        0xb0C4c6A91a9ed11A89A1EF69de09A3254D6d87E2,
        0xB17C020bb54b2329ddDcD23c668F2e70897Fd7a7,
        0xe12d5e83441614303772C851040EdDF12f4E1A9E,
        0x281A0eC0A602eB9C9B92a6711941f9D8E93fBB0f,
        0xFb7Ac89d730dC18F2FBD86ffc91aD47284D504f4,
        0xd9d748a8F2927DEcc92a8e01b732bf4A056C6868,
        0xc29249BE70ca601934c8250373203AC03C01C3B3,
        0x26bd2f2931e0857D7e749ED4a4a6ecfEd9adc159,
        0x76D6c95DF6be289e18c5a682DcC4263eC6DbA53f,
        0xC9d8D69A74f2f32f7294d242c7272aa873167b22,
        0xad03756c766B32e1ACEfAA28E77d158892b580A6,
        0xe96DB623c2CE30F65171F5fc487127748d1065C6,
        0x2F8D8846C376bC842Cd9B904C9b505e39A6c54Dc,
        0x8C702A9a6e0cd14a53251C630743c4F5327eddE8,
        0x6049CEaA510d5E7585A4D7Fa6C102C1bdaaaBaCe,
        0x2aEfc99091420218De94D8b446d29F08189a3B0c,
        0x6b615390f73Eae2b20C81ab17aBfe8BE7fF57523,
        0x24b0842f31748C7c9eD0e69261F5E3578A24D8e1,
        0xff87a8C90595171D06c92D6926dBBf43777CF7A3,
        0xB2082914a908a91194B3Ad50e5aEe2e7FB77D435,
        0xE800D3401cE4dA88D738df0502f5CcD5d1e63083,
        0x0908823204A6044981b22d636D15B2A4A1916b3e,
        0x1FC7A92b67317CBf8124037bD3A137FcF9ee61E1,
        0xb4b81b693F322F6dadac99c9DE4366970e99f6D8,
        0xe4e45993cc1718dFB1b7dB2bc72Ac10f0737e74A,
        0xB960665D4e601063df28c9067c0d925069cf9142,
        0x116c2978B393453D6C2Cb5F6Ab282F898B8BC128,
        0x0634e57C875d6Cc0037FA5174e8BAF602eBE8344,
        0xB06716762d95080Ef63B74FcEd62F541a48cD660,
        0xDafAa782BcD1d519e7374A8D4a33bE8809d2023b,
        0xaFa47C5911dc32a9047e983c20E3860C2f303592,
        0x59F14A2f59F6d10ac77Ba67576ebE37eda56a064,
        0x6D65ACA6c7e880218A26e324E62422743D845316,
        0x0b0e6e7235d67E35EA8D736766088A28C1985aFC,
        0x2D1E7B6E6284409e16991dE76d2A82847a7d61C5,
        0x788c1702D8E34Ec11cbc99Beadc4d3E2d50f89e2,
        0x6cf313F417937C6ca5aC85b4Efb4175fBA397C7E,
        0xbf45D67779793c5e2387609e497A051e2906c383,
        0x887F4ae78D3F2219998b75Bc8fC2C9d9673a942a,
        0x39BBFC85f0b4bFFef053cf5Ef31c70B0C9B5Dc9b,
        0x4ECF5BC9A031bF984D2a00D3f9eEf0BA6c7f692c,
        0x069D3e170f6A0aa557EF97342BAb3063f77c58DB,
        0x0eD1f069A895a94eF6866979FDD71F556024D018,
        0x06C650E7d03ED5b82ab2a69297888b108E1b0CD1,
        0xBBC3d8108069B10a5859a08f31d140b9f357F73f,
        0x3C045d92B7c3bb83E2018e2e296F6A0BC0E2eB07,
        0x93e266B9a1534acE15314a35D2E8369c30c4f81e,
        0xd83577256002E1F54CE8536F1510e175e7D1db17,
        0x2C8D2e50Ee03f98A2f4CCFbe1A61552b79bDF6fa,
        0xbED050C15224a53a12815Fa79F2B1EF431887Eb2,
        0x383234d747497f8E3e0c485f66f52B19227727a6,
        0x56fF22798ab380616380eb5af6D055aC91f4b114,
        0x53AFdcd8197A9FEF79729f2D6AEE5954aEC1E0D3,
        0x69774A09Ca3E16421712E472DCd16a0a98c330DF,
        0x379CAdAb8F98bF10121E2e9B7fc02CA802345E8b,
        0x476e8C784Cb487Ba1532907556E47AB960F5D137,
        0xD952f25A26404E6C1d3E320C7116fc444296a2e7,
        0x1F124970A7724F0c4A9159498824D505Fde6f9aA,
        0x1A2Cfb4E1eD487c94621C4C8cd73889679D09631,
        0x43A76b029EDCdE8E7fC64A8bb0e240b0E642aAeB,
        0xeb6f552540468e7E3FCb0aA036C1E71076b67e2C,
        0x4dfC3F37a5CeE7Ea111e65D35eCfe61Fdd10fbC5,
        0xbED050C15224a53a12815Fa79F2B1EF431887Eb2,
        0xAAc21Bb3608D996793E256C0E72305F6a4e2185D,
        0x626c19C0EdAc14D34F84e99005c28CfA2Fb2505B,
        0x5C30755fb63e910200016A9be44652F20B8d0164,
        0xF33364a83b6002D5070EC5FA31F5d9EB93572732,
        0x4f8c2d5397262653Cd8956CB977A0bA3660210c7,
        0x1Dca1f25E29Ff5C35BFb4a6E39ff872bf717945B,
        0x94ff6a83A067cC9E6a4C0767792beDA781a16375,
        0x1EC1CcEF3e1735bdA3F4BA698e8a524AA7c93274,
        0x59Fc9b09134cAf06eC444d10Ba01D7999f26252b,
        0xbe2909813f6F850af99C8b968febF6eb884F1454,
        0x14aE683317D9d27957F56C78e9308E7D54BC3b36,
        0xe8000117B9fcAA0612D0bB872846eBA74F9AA43D,
        0xEE9c816B1FB76DCeE3c82777D7253678B7F8BEdf,
        0x15259752Ba5e5708657B2659Aacb543f101D3355,
        0x082ed91C65EcbA6Ac147B115f661B1c7b584D23C,
        0xd3022599033430bF3fDFb6D9CE41D3CdA7E20245,
        0xd1fFdA9C225DDEE34f0837BF4D4a441bDd54C473,
        0x7dE1f5eB781edc662472436eEBc09d331FB73261,
        0x7f64d79293b8eaB2ad215AA17EEc4733abAA9e62,
        0x2434f861cd062A403FfafcC616DeDc81f378b72a,
        0x1e252b86616D5ee310b9676977f392b0E84D193F,
        0xeBf7c4FCA7318df6ca17cAC473C96F71Fc7704b9,
        0xfF9Cfb8eD63fFB4A15e1bDF0451F073155Fd0aa0,
        0x3a647b4e245EE3Ec5dfe76fd97FF8f8f367B454B,
        0x4f960d763e2d153299F310432fD8e16F75cc9BCa,
        0x284F3268d61e07337b6bB461E9994F678b543b10,
        0x48513224a50C339d23484c9cd4A95DaB5a9e8862,
        0x9902f56BA1054a3025cedaD37654e86512614Af1,
        0x8715538b1f9f0402F9175CDc0762bA61A1C35940,
        0x2c8694832425742A9445f4896A8897fd8A603251,
        0x965E0B3CE256AFB883c4320789d9FddFc51a0AAE,
        0xc5912457428bF9dd878F4AFEcC62B52AE977f887,
        0x9Faa6b1a8a24701725452262CdcB24C9bDE10efa,
        0xB2082914a908a91194B3Ad50e5aEe2e7FB77D435,
        0xD50212833C9a1d7be8255744aC0eBabCC3C42eFD,
        0xE284A94E532509b99cBDE842a698DC38444bA93E,
        0x9902f56BA1054a3025cedaD37654e86512614Af1,
        0x6B4Fc8B4c1F60203bd7bE84D85bf8AC6156E2e3f,
        0xC38a2306a8bdC16353a283cEC840BbBd5BDf8799,
        0xb07BE2f3B41cAF8eBbb911b3786D5Ba9B7aE057e,
        0xfd45BA41CFB3FC218565a197405f427c8c65de4a,
        0xFAa5D029D4085C604F2CEb8A7a028c22e7398Be3,
        0x3C045d92B7c3bb83E2018e2e296F6A0BC0E2eB07,
        0x821B6535AA02082a54F35aDaDb8ff2bFd7baFBEB,
        0xf5A7a63c642f7E852569A4D1FA546bE587C3322d,
        0x3A2Ae8c069C0e8D2b41f5A02A4e1779de3FECFc5,
        0x446199dDE35B1D567894B022b1FB86eF13F4001B,
        0x4856b9bcb8c467CCd18B920bDE1673c49855cFdf,
        0x4c6AB491dE3cdE727D931C079348E700EA675472,
        0x4ff08d6Cb961A322e629d4d05b35D548945EfD21,
        0x5Af514bC61f2dEB8209F5EC01281fD58FaA0fe04,
        0x725A4e8a6687a29F706519584532CB0f1a516430,
        0x74961A235B2A402C2Ce571Fa4b38b2dD6b73Db30,
        0x8ab83D869f2Bc250b781D26F6584fd5c562FdD9D,
        0x8d47F71ae25A18dE8d091C8DeE92b1B4be0Bb590,
        0x90214F4d26157CE4bAdf22786Fed2dF45D69d1Ff,
        0x95dD010D54Efb6B4fcD040dBBd93eeE8f2acc7a2,
        0xA3264a6B18b0e43DA9C7C235B5434294C2f9B10D,
        0xa3c5eB3724205D9b134eAE56618C6f69cA57c951,
        0xa6a15056f8DA65E91776bfcDb831eCA37E067133,
        0xAbC5371f421F5b9f1B02Aa1f9756787Fd3dEA6E4,
        0xf45D07e683caE570D56300A108A6D6B1E7F1Dc79,
        0xf5962Dd1cfb95Bd15a598b721091B373FcF1e3D1,
        0xf75E2e45233c6B4aBd0a48984d280228E620E7e4,
        0xD19B33D31c4A654578ECB16163C6e2F1138f5892,
        0xE85A3ec4CC1efB0069c638e57216b8fC478be6D6,
        0x272BD5A3760Ec5C195b872fAd4B6b3e5A142c575,
        0x09EA2FE741AE319207c68738A3275E61ff56Fb96,
        0xdFBB06683a882E827907422dbFE836E5430fE2aC,
        0x7cB0393740204B1034E58Fddd1580563B6f3c0a3,
        0x56348fe5080930CD48aC1E71E9b18CbbDB953B86,
        0x8D16e6AF9faa28277B4fef9F7225ab1642a7dC8E,
        0x7cc4E967242E1CaD92152d47AE0bB9169e97d553,
        0xf4680C0A183f7f0F6a5bb060550140688Bc41042,
        0xe9e75190a114E779a27cF5522dd480b90d703A1A,
        0xC727D9b5Ab6548890A888A3CC68e0b66eE99030A,
        0x84cD3038b7b2983E582092cd4e48761d37BE4348
    ];
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

  /**
    * @dev Public function for verifying whitelist eligibility
    * Called in whitelistMint function
    * @param _to verifies the address as eligible for whitelist
   */
   function whitelistEligible(address _to) public view returns (bool) {
       for (uint i=0; i < whitelist.length; i++) {
           if (whitelist[i] == _to) {
               return true;
           }
       }
       return false;
   }



  /**
    * @dev Public function for purchasing presale {num} tokens. Requires whitelistEligible()
    * Calls _safeMint() for minting process
    * @param _mintAmount is the number of NFTs minted (Max is stored in public uint maxMintAmount)
   */
   function whitelistMint(uint256 _mintAmount) public payable {
       uint256 supply = totalSupply();
       require(!whitelistPaused);
       require(whitelistEligible(msg.sender));
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

  function pauseWL(bool _wlState) public onlyOwner {
    whitelistPaused = _wlState;
  }

  function pushWL(address _to) public onlyOwner {
      whitelist.push(_to);
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