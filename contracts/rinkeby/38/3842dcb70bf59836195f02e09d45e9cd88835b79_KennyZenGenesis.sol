/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/Vaulted.sol


pragma solidity ^0.8.0;



/// @title This is an abstract to construct a safe contract, i.e. a smart contract containing a vault
///  which secures a safe of entrusted funds.
/// @author Kenny Zen (https://kennyzen.co)
/// @dev Info on how the various aspects of safe contracts fit together are documented in the safe contract Complex Cipher.
abstract contract Vaulted is Context, ReentrancyGuard {

  // The official Ethereum burn address
  address public burn = 0x000000000000000000000000000000000000dEaD;

  struct Vault {
    uint256 safe; // a trusted balance of pecuniary funds
    mapping(address => uint256) trust; // a map of an address to its trusted balance
  }

  /// @dev The total trusted balance for this contract is kept in the safe of the Vault struct _vault.
  /// @notice The amount of funds kept in the vault's safe is only accessible to the address of the
  ///  account which has deposited or been entrusted funds.
  Vault private _vault;

  /**
   * Get the trusted balance of a particular account (the account's trust).
   * @dev Only the account with a trusted balance greater than cipher (0) can claim from its trust.
   * @param _account The address of the account for which to retrieve the trust
   */
  function account(address _account) public view returns (uint256) {
    return _vault.trust[_account];
  }

  /**
   * Get the sum of funds entrusted to the vault's safe, i.e. the total trusted balance for this contract.
   * @dev Any account can add a trusted amount to the vault's safe. Any account with a trust greater
   *  than cipher (0) can claim from the vault's safe an amount no greater than the account's trust.
   */
  function safe() public view returns (uint256) {
    return _vault.safe;
  }

  /**
   * Add to the trusted balance of a particular account (the account's trust).
   * @dev Callable internally only. Use this function when receiving value to augment the balance
   *  of the vault's safe.
   * @param _account The address of the account for which to increase the trust
   * @param _amount The pecuniary amount by which to increase the trust and the vault's safe in wei
   */
  function _augment(address _account, uint256 _amount) internal {
    _vault.trust[_account] += _amount;
    _vault.safe += _amount;
  }

  /**
   * Take away from the trusted balance of a particular account (the account's trust).
   * @dev Callable internally only. For use when sending value from the safe contract to deplete
   *  the balance of the vault's safe.
   * @param _account The address of the account for which to decrease the trust
   * @param _amount The pecuniary amount by which to decrease the trust and the vault's safe in wei
   * @notice USE WITH CARE: Derivative logic MUST NOT allow for the depletion of entrusted funds in the
   *  vault's safe. Special attention MUST be paid to ensure the security of the vault's safe FOREVER.
   */
  function _deplete(address _account, uint256 _amount) internal {
    require(_vault.safe >= _amount && _vault.trust[_account] >= _amount, "Insufficient funds in vault.");
    _vault.trust[_account] -= _amount;
    _vault.safe -= _amount;
  }

  /**
   * Deposit an amount to the trust of a particular account.
   * @dev Callable by anyone. The _account cannot be the cipher (0) or the burn address.
   * @param _account The address of the account to which to entrust deposited funds
   */
  function deposit(address _account) external payable nonReentrant {
    require(_account != address(0) && _account != burn, "Cannot deposit funds to burn.");
    _augment(_account, msg.value);
  }

  /**
   * Withdraw an amount from the trust of a particular account.
   * @dev Callable by the _account only. Throws on insufficient funds. See {_send}. Can be overridden
   *  to extend or restrict behaviour.
   * @param _account The address of the account from which to withdraw entrusted funds
   * @param _amount The pecuniary amount to withdraw in wei
   * @notice USE WITH CARE: Overwrites of this or the `dispatch` function without a call to the
   *  `_send` function may leave the balance to this safe contract untouchable.
   */
  function withdraw(address _account, uint256 _amount) external virtual {
    _send(_account, _account, _amount);
  }

  /**
   * @dev See {_send}. Can be overridden to extend or restrict behaviour.
   * @notice USE WITH CARE: Overwrites of this or the `withdraw` function without a call to the
   *  `_send` function may leave the balance to this safe contract untouchable.
   */
  function dispatch(address _from, address _to, uint256 _amount) external virtual {
    _send(_from, _to, _amount);
  }

  /**
   * Send an amount from the trust of the _from account to the _to address.
   * @dev Callable by _from only. Throws on insufficient funds or if _to is the cipher (0)
   *  or the burn address.
   * @param _from The account from which to dispatch the _amount of trust funds
   * @param _to The account to which to send the _amount of funds
   * @param _amount The pecuniary amount to send in wei
   * TODO: Perhaps ensure the transfer is ERC20Safe
   */
  function _send(address _from, address _to, uint256 _amount) internal nonReentrant {
    require(_from == _msgSender(), "Unauthorized account.");
    require(_to != address(0) && _to != burn, "Cannot dispatch safe funds to burn.");
    require(_amount <= account(_from), "Insufficient funds in trust :(");
    _deplete(_from, _amount);
    (bool paid, ) = payable(_to).call{value: _amount}("");
    require(paid, "Payment failed :(");
  }

  /**
   * @dev The `receive` function executes on calls made to the safe contract to receive ether with
   *  no data. Can be overridden to extend behaviour.
   */
  receive() virtual external payable {
    // For now, we reject any ether not sent to the vault's safe.
    // Potentially, logic could be implemented to use the `_augment` function to augment the trust
    // of the contract owner, whereupon the owner can withdraw the funds from the vault's safe. In
    // addition, the funds thereupon could be forwarded directly to the owner, e.g.
    // _augment(owner(), msg.value);
    // _send(owner(), owner(), msg.value);
    revert("Nonpayable");
  }

}
// File: contracts/SimpleTokensSafe.sol


/*
 .
 .      *77777/'           77777#'    `(777777         `&7777       `(777777*              `(77777/'
 .      777'`            777777          7777&             `77         7777777#               `7%
 .     7#              #77777            7777%               `7        7  %77777&              7,
 .    7              .77777              7777#          ,              7    *777777            &
 .                  77777.               7777%        .7,              7      .777777          &
 .                77777%                 7777&    _.(777,              7         777777        &
 .              777777                   7777%     `,777,              7           777777      &
 .            %77777                     7777#        `7,              7             777777    &
 .          ,77777                7      7777#          ,       ,7     7               777777, &
 .         77777.               %7       7777%                 &,      7                 7777777
 .       77777(              ,777       .77777               /77       7                   #7777
 .    .77777&            ,;77777.     ,;777777.          ,/7777     ,;777:.                  &77
 .
 .
 .   Simple Tokens by Kenny Zen Edition ERC721 Vaulted
 .   Updated Wednesday, May 11, 2022
 .
 .   This contract contains a safe.
 .   Scroll down :)
 .
*/

pragma solidity >=0.8.9 <0.9.0;





/// @title This contract conforms to the ERC721 non-fungible token standard. It can be used to mint
///  special distinguishable assets called tokens, each ownable by an Ethereum wallet.
/// @author Kenny Zen (https://kennyzen.co)
/// @dev This safe contract keeps track of a collection of NFTs and also contains a vault which can
///  secure an account of entrusted funds for any address. Info on how the various of aspects of safe
///  contracts fit together are documented in the safe contract Complex Cipher.
abstract contract SimpleTokensSafe is ERC721, Ownable, Pausable, Vaulted {

  using Strings for uint256;

  /// @dev Emitted when the contract's entire subsidized balance has been claimed.
  event SubsidiesCollected(uint256 indexed amountWithdrawn);

  bytes4 public locale; // locale selector for this contract

  string public baseURI; // base URI to get token metadata
  string private _contractURI; // URL to get contract-level metadata

  uint256 public dateDeployed; // timestamp of the block within which this contract was added to Ethereum

  mapping(uint256 => mapping(address => bool)) public tokenHeld; // map of tokenIds to any token holder ever

  /**
  * Function overrides
  */
  /// Called before any token transfer. @dev See {ERC721-_beforeTokenTransfer}.
  function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  /// Called after any token transfer. @dev See {ERC721-_afterTokenTransfer}.
  function _afterTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
    tokenHeld[_tokenId][_to] = true;
    super._afterTokenTransfer(_from, _to, _tokenId);
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  /// Override the function called to renounce contract ownership.
  /// @dev Overrides {Ownable-renounceOwnership} by throwing instead. Removing this override function
  ///  will make ownership of this contract completely renounceable. Renouncing contract ownership
  ///  will then assign control of this contract to the cipher (0) address to be LOST FOREVER.
  function renounceOwnership() public view virtual override {
    revert("Ownership is not renounceable.");
  }

  /**
   * @dev Throws if called by any account other than the token holder.
   * @param _tokenId The tokenId of the token to check for ownership
   */
  modifier onlyHolder(uint256 _tokenId) {
    require(ownerOf(_tokenId) == _msgSender(), "You don't hold this token :(");
    _;
  }

  /**
   * @dev Determine if a particular wallet address holds a token.
   * @param _holder The account to check for ownership
   */
  function isTokenHolder(address _holder) public view returns (bool) {
    if (balanceOf(_holder) > 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Determine if a particular token of this contract has been minted.
   * @param _tokenId The tokenId of the token to validate existence
   */
  function isTokenMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * @dev Get the storefront-level metadata URL for this contract.
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * Get the metadata URI for a particular token.
   * @dev Throws if the token has never been minted.
   * @param _tokenId The tokenId of the token for which to retrieve metadata
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist!");
    return string(abi.encodePacked(baseURI, _tokenId.toString()));
  }

  /**
   * Set the base metadata URL for the tokens of this contract.
   * @dev Callable by the owner of this contract only.
   * @param _uri The URI pointing to the token metadata
   */
  function setBaseURI(string memory _uri) public onlyOwner {
    baseURI = _uri;
  }

  /**
   * Set the storefront-level metadata URL for this contract.
   * @dev Callable by the owner of this contract only.
   * @param _uri The URL pointing to the contract's metadata
   */
  function setContractURI(string memory _uri) public onlyOwner {
    _contractURI = _uri;
  }

  /**
   * Pause or unpause the contract.
   * @dev Callable by the owner of this contract only. Throws if the `paused` status has not changed.
   * @param _paused The value to which to update the `paused` status of the contract as a boolean
   */
  function pause(bool _paused) public virtual onlyOwner {
    if (_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  /**
   * @dev Claim the entire subsidized balance for the owner of this contract.
   * @notice WARNING: If ownership is renounceable, calling this function after renouncing contract
   *  ownership will cause this function to throw, leaving any subsidies thereupon unclaimable.
   */
  function _recover() internal {
    address _owner = owner();
    uint256 _withdrawn = account(_owner);
    _send(_owner, _owner, _withdrawn);
    emit SubsidiesCollected(_withdrawn);
  }

  /**
   * Withdraw all subsidies.
   * @dev Callable by the owner of this contract only. Does not throw if the subsidized balance
   *  is a cipher (0).
   * @notice WARNING: If ownership is renounceable, renouncing contract ownership will cause this
   *  function to throw, leaving any subsidies thereupon unclaimable.
   */
  function claim() external virtual onlyOwner {
    _recover();
  }

  /**
   * Transfer an NFT that has been sent to the contract directly.
   * @dev Callable by the owner of this contract only. Throws if the NFT is not owned by the contract
   *  or the _receiver is a contract which does not implement `onERC721Received`.
   * @param _implementation Address of the _tokenId's ERC721 compliant contract
   * @param _receiver Address of the account to which to send the token
   * @param _tokenId The tokenId of the token of the _implementation contract
   */
  function transferNFT(address _implementation, address _receiver, uint256 _tokenId) public onlyOwner {
    IERC721(_implementation).safeTransferFrom(address(this), _receiver, _tokenId);
  }

  /**
   * @dev Implementation of the `onERC721Received` function ensures that calls can be made to this
   *  contract safely to receive non-fungible tokens.
   */
  function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @dev The `receive` function executes on calls made to this contract to receive ether with no data.
   */
  receive() virtual override external payable {
    // The ether sent is added to the trust of the contract owner only, then forwarded to their address.
    address _owner = owner();
    _augment(_owner, msg.value);
    _send(_owner, _owner, msg.value);
  }

}
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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

// File: contracts/GenerationTokens.sol


pragma solidity >=0.8.9 <0.9.0;



/// @title This abstract sets up a locale token tracker for an unlimited number of mintable tokens
///  with innumerable generations, incrementing tokenIds on each new mint.
/// @author Kenny Zen (https://kennyzen.co)
/// @dev This safe contract mints generational NFTs. Info on how the various aspects of safe contracts
///  fit together are documented in the safe contract Complex Cipher.
abstract contract GenerationTokens is SimpleTokensSafe {

  using Strings for uint256;
  using Counters for Counters.Counter;

  address public executive = 0x075C21fa4BA3dE2146B3Cb788ddDa1c688ae0eDA; // the Ethereum account of Kenny Zen

  /// @dev Emitted when a new token is minted.
  event TokenMinted(uint256 indexed tokenId, address indexed minter);

  /// @dev Emitted when the supply of tokens for this locale changes.
  event TokenCountUpdated(uint256 indexed supply);

  string private _generationCID; // the IPFS content identifier of the current generation of tokens

  Counters.Counter private _generation; // keeps track of the current generation of tokens
  Counters.Counter private _tokenCount; // keeps track of the number of minted tokens

  uint256 public premium = 0.07 ether; // subsidy required to mint one (1) token
  uint256 public maxTokensPerMint = 1; // maximum number of tokens allowed per mint

  uint256 internal _mintableSupply; // total supply of mintable tokens

  mapping(uint256 => address) public minter; // map of tokenIds to original token holder
  mapping(uint256 => string) public tokenCID; // map of tokenIds to IPFS content identifier

  /**
   * @dev The constructor instantiates the ERC721 standard contract using _localeName and _localeSymbol,
   *  creates a new locale for these tokens, pauses the contract and gives birth to the cipher (0) generation of tokens.
   * @param _localeName The name of this locale ("Kenny Zen Genesis")
   * @param _localeSymbol The symbol of this locale ("ZEN")
   * @param _genesisCID The content identifier for the cipher (0) generation of tokens ("QmWsszxdYUh2rdUD7jKBdTnnmJrWbBf3YPZNAR5zNnf8TD")
   * @param _initialSupply The initial supply of tokens for generation cipher (0) (7)
   */
  constructor(
    string memory _localeName,
    string memory _localeSymbol,
    string memory _genesisCID,
    uint256 _initialSupply)
    ERC721(_localeName, _localeSymbol) {
      baseURI = "ipfs://";
      dateDeployed = block.timestamp;
      locale = bytes4(keccak256(abi.encodePacked(_localeName, _localeSymbol, dateDeployed)));
      pause(true);
      bearTokens(_genesisCID, _initialSupply);
  }

  /**
   * @dev Throws if the _mintAmount is noncompliant, or if there are no more mintable tokens.
   * @param _mintAmount The number of tokens to check for compliance.
   */
  modifier mintCompliance(uint256 _mintAmount) {
    if (_msgSender() != owner()) {
      require(_mintAmount > 0 && _mintAmount <= maxTokensPerMint, "Invalid mint amount!");
    }
    require(_tokenCount.current() + _mintAmount <= _mintableSupply, "No more mintables :(");
    _;
  }

  /**
   * @dev Throws if called by any account other than the original token holder.
   * @param _tokenId The tokenId of the token for which to check for ownership
   */
  modifier onlyMinter(uint256 _tokenId) {
    require(minter[_tokenId] == _msgSender(), "You ain't OG :(");
    _;
  }

  /**
   * @dev Throws if called by any account other than the current or orignial token holder.
   * @param _tokenId The tokenId of the token for which to check for ownership
   */
  modifier onlyOwned(uint256 _tokenId) {
    require(ownerOf(_tokenId) == _msgSender() || minter[_tokenId] == _msgSender()
    , "Not the owner :(");
    _;
  }

  /**
   * @dev Set up the minted token. This assigns the address of the orignal holder and asssigns the
   *  content identifier of the location where token metadata lives on IPFS.
   * @param _tokenId The tokenId of the token to set up
   * @param _minter The address of the original minter
   */
  function _structureToken(uint256 _tokenId, address _minter) private {
    tokenCID[_tokenId] = _generationCID;
    minter[_tokenId] = _minter;
    emit TokenMinted(_tokenId, _minter);
  }

  /**
   * @dev Set up the minted token. Be sure to include this within the mint function of any
   *  derivative safe contract to give the tokens their structure and generational context.
   *  Overrides should call `super.structureToken(_tokenId,_minter)`.
   * @param _tokenId The tokenId of the token to set up
   * @param _minter The address of the original minter
   */
  function structureToken(uint256 _tokenId, address _minter) internal virtual {
    _structureToken(_tokenId, _minter);
  }

  /**
   * @dev Get the number of generations that have been born.
   * @return The current number of generations
   */
  function generations() public view returns (uint256) {
    return _generation.current();
  }

  /**
   * @dev Get the number of tokens that have been minted.
   * @return The current token count
   */
  function totalSupply() public view returns (uint256) {
    return _tokenCount.current();
  }

  /**
   * @dev Increment the token count and fetch the latest mintable token.
   * @return The next tokenId to mint
   * @notice The initial tokenId is 1.
   */
  function nextToken() internal virtual returns (uint256) {
    _tokenCount.increment();
    return _tokenCount.current();
  }

  /**
   * @dev Get the number of tokens still available to be minted.
   * @return The available token count
   */
  function availableTokenCount() public view returns (uint256) {
    return _mintableSupply - totalSupply();
  }

  /**
   * @dev Get the metadata URI for a particular token. Throws if the token has never been minted.
   * @param _tokenId The tokenId of the token for which to retrieve metadata
   */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId));
    return string(abi.encodePacked(baseURI, tokenCID[_tokenId], "/", _tokenId.toString()));
  }

  /**
   * @dev Get the tokens owned by a particular wallet address by tokenId.
   * @param _owner The account to check for ownership
   */
  function tokensByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(_owner);
    uint256[] memory owned = new uint256[](balance);
    uint256 i = 0;
    uint256 currentId = 1;
    while (i < balance && currentId <= _tokenCount.current()) {
      address currentTokenOwner = ownerOf(currentId);
      if (currentTokenOwner == _owner) {
        owned[i] = currentId;
        i++;
      }
      currentId++;
    }
    return owned;
  }

  /**
   * Mint a number of tokens to the _receiver.
   * @dev Callable internally only.
   * @param _mintAmount The number of tokens to mint
   * @param _receiver The address of the account to which to mint _mintAmount of tokens
   */
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      uint256 _id = nextToken();
      _safeMint(_receiver, _id);
      _structureToken(_id, _receiver);
    }
    emit TokenCountUpdated(totalSupply());
  }

  /**
   * Mint a number of tokens to the sender.
   * @dev Callable by any address. Throws if the provided subsidy is noncompliant.
   * @param _mintAmount The number of tokens to mint
   */
  function mint(uint256 _mintAmount) public payable nonReentrant whenNotPaused mintCompliance(_mintAmount) {
    // minter must send a subsidy matching or exceeding the premium per token
    require(msg.value >= premium * _mintAmount, "Value sent is incorrect :(");
    _augment(owner(), msg.value);
    _mintLoop(_msgSender(), _mintAmount);
  }

  /**
   * Mint a number of tokens to the _receiver, courtesy of the contract owner. For giveaways ;)
   * @dev Callable by the owner of this contract only.
   * @param _mintAmount The number of minted tokens to airdrop
   * @param _receiver The address of the account to which to gift the minted tokens
   */
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  /**
   * Assign an address to act as the executive.
   * @dev Callable by the owner of this contract only.
   * @param _newExec The address of the new executive
   */
  function setExecutive(address _newExec) external onlyOwner {
    executive = _newExec;
  }

  /**
   * Update the premium per token.
   * @dev Callable by the owner of this contract only. The minter must send a subsidy matching or
   *  exceeding this premium. Throws if the contract is not paused.
   * @param _perTokenPremium The pecuniary amount of the subsidy required to mint a token in wei
   */
  function setPremium(uint256 _perTokenPremium) public onlyOwner whenPaused {
    premium = _perTokenPremium;
  }

  /**
   * Update the maxium number of tokens allowed to be minted per transaction.
   * @dev Callable by the owner of this contract only. Throws if the contract is not paused.
   * @param _maxTokens The address of the new executive
   */
  function setMaxTokensPerMint(uint256 _maxTokens) public onlyOwner whenPaused {
    maxTokensPerMint = _maxTokens;
  }

  /**
   * Update the content identifier for the current generation of tokens.
   * @dev Callable by the owner of this contract only. Theoretically, this would be called only
   *  in the event of a mistake or a severe change. Throws if the contract is not paused, or the
   *  _CID is invalid.
   * @param _CID The updated IPFS content identifier
   */
  function setCID(string memory _CID) public onlyOwner whenPaused {
    require(bytes(_CID).length == 46, "CID missing or invalid.");
      _generationCID = _CID;
  }

  /**
   * Update the supply of mintable tokens for the current generation.
   * @dev Callable by the owner of this contract only. Theoretically, this would be called only in
   *  the event of a mistake or a severe change, whereby the `_generationCID` is also updated.
   *  Throws if the contract is not paused.
   * @param _supply The new mintable supply of tokens
   */
  function setSupply(uint256 _supply) public onlyOwner whenPaused {
      require(_supply >= totalSupply(), "Total supply cannot be depleted.");
      _mintableSupply = _supply;
  }

  /**
   * Bear the next generation of mintable tokens for this contract.
   * @dev Callable by the owner of this contract only. Throws if the contract is not paused, the current
   *  generation of tokens is still being minted, the updated supply of tokens is the cipher (0), or the
   *  _CID is invalid.
   * @param _CID The IPFS content identifier of the new generation of tokens
   * @param _generationSupply The supply of tokens for the new generation
   */
  function bearTokens(string memory _CID, uint256 _generationSupply) public onlyOwner whenPaused {
    require(availableTokenCount() == 0 && _generationSupply > 0, "Progression not possible.");
    require(bytes(_CID).length == 46, "CID missing or invalid.");
    _mintableSupply += _generationSupply;
    _generationCID = _CID;
    _generation.increment();
  }

  /**
   * Withdraw all subsidies, splitting a percentage with the `executive`.
   * @dev Callable by the owner of this contract only. Throws if the subsidized balance is less than
   *  100 wei, whereupon the payment splitter would malfunction.
   * @notice WARNING: If ownership is renounceable, renouncing contract ownership will cause this
   *  function to throw, leaving any subsidies thereupon unclaimable.
   */
  function claim() external override onlyOwner {
    address _owner = owner();
    uint256 _withdrawn = account(_owner);
    require(_withdrawn > 99, "Insufficient funds :(");
    _send(_owner, executive, _withdrawn * 15 / 100); // 15% goes to the executive.
    _send(_owner, _owner, account(_owner));
    emit SubsidiesCollected(_withdrawn);
  }

}

// File: contracts/KennyZenGenesis.sol


pragma solidity >=0.8.9 <0.9.0;


/*

   7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777&77777777777777777777777777777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#'7777777777777777777777777777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#   *#%%&&77777777777777777777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#  &77777777777777777777('      %777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#(77777777777777777777'      ,777777777777777777777777777777777777777777777777
  7777777777777777777777777777777777777777777777777777777777777/'     .777777777777777777777777777777777777777777777777777
  7777777777777777777777777777777777777777777777777777777777/'     .&77777777777777777777777777777777777777777777777777777
  7777777777777777777777777777777777777777777777777777777/'     ./77777777777777777777777777777777777777777777777777777777
  77777777777777777777777777777777777777777777777777777'      .77777777777777777777777777777777777777777777777777777777777
  77777777777777777777777777777777777777777777777777'      .77777777777777777777777777777777777777777777777777777777777777
  77777777777777777777777777777777777777777777777#       #7777777777777777777777777777777777777777777777777777777777777777
  77777777777777777777777777777777777777777777&`      ,7777777777777777777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#      .777777777777777777777777/777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#   .#7777777777777777777777777' 777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777# .(7777777777777777777777&&#,   777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#,777777777777777777777777777777,777777777777777777777777777777777777777777777
  7777777777     .*%7777777777777'     ,777777777777777777777777777777777777777777/.     '%777777777777777777&,   .(777777
  777777777   *7777777777777777*     ,777777777777777777777777777777#'*7777777777777 *      '7777777777777777777 .77777777
  77777777  #7777777777777777*     .777777777777'`/*7777777777777777777&     7777777*77&      '77777777777777777.*77777777
  7777777.77777777777777777/     .7777777777#   .7777777777777777777777777,  7777777*77777.      *77777777777777,#77777777
  77777777777777777777777/     .777777777777#  7777777777777777777777777777% 7777777*7777777*      '777777777777,%77777777
  777777777777777777777/      77777777777777#,77777777#.          ,&77777777.7777777*777777777&      '7777777777,&77777777
  7777777777777777777#      7777777777777777##777777777777%   *7777777777777(7777777*777777777777.      %7777777,&77777777
  77777777777777777#      777777777777777777#&7777777777777& %77777777777777#7777777,77777777777777%      *77777,777777777
  777777777777777%      77777777777777777777#777777777777777 777777777777777/7777777.7777777777777777%      '777,777777777
  7777777777777%      777777777777777777% 77#&77777777777777 777777777777777 7777777 7777777777777777777      '&,777777777
  77777777777%      777777777777777777%  777#                                7777777 &77777777777777777777,      &77777777
  777777777&      77777777777777777#    7777#                                777777* .7777777777777777777777%    &77777777
  7777777&     .7777777777777&/'       &7777# ,77777777777777777777777777%,  7777*     *77777777777777777777777 ,&77777777
  777777777777777777777777777777777777777777#,777777777777777777777777777777,777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
  77777777777777777777777777777777777777777777777777777777777777777%%'#777777777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%`'%77777777777777777777777      777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%     #7777777777777777777777.   777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%,       *777777777777777777777  777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%%77%.      '7777777777777777777 777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%%77777&.       7777777777777777,777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%%777777777.       &777777777777/777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%#777777777777,       #777777777(777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777%/777777777777777.      '(777777(777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777% 77777777777777777%.      '(777(777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#  %7777777777777777777%      '.)777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777#    #77777777777777777777*,     777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777777&;,. 777777777777777777777*,  777777777777777777777777777777777777777777777
  777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
   7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

   7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
  77/                                                                                                                  \77
  77                                    KENNY ZEN GENESIS ERC721 NON-FUNGIBLE TOKENS                                    77
  77                                            Smart contract by Kenny Zen                                             77
  77                                               Twitter @kennystokens                                                77
  77                                          Updated Wednesday, May 11, 2022                                           77
  77\                                                                                                                  /77
   7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

*/

/// @title The safe contract Kenny Zen Genesis.
/// @author Kenny Zen (https://kennyzen.co)
/// @dev This safe contract sets up an unlimited collection of non-fungible tokens with innumberable generations.
///  Info on how the various aspects of safe contracts fit together are documented in the safe contract Complex Cipher.
contract KennyZenGenesis is GenerationTokens {

  constructor() GenerationTokens(
    "Kenny Zen Genesis",
    "ZEN",
    "QmWsszxdYUh2rdUD7jKBdTnnmJrWbBf3YPZNAR5zNnf8TD",
    7)
  {
    setContractURI("ipfs://QmbqZL4UZaDQVBHrnELJc6CyqXa536Nr3RojR88htwyG4V");
  }

  /// TODO: Perhaps disallow minting from a contract, for the sake of fairness
}