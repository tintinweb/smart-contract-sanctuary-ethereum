/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/*
  ______  __       __   __     __
 /      \|  \     |  \ |  \   |  \
|  ▓▓▓▓▓▓\ ▓▓____  \▓▓_| ▓▓_  | ▓▓ ______   ______   _______
| ▓▓___\▓▓ ▓▓    \|  \   ▓▓ \ | ▓▓/      \ /      \ /       \
 \▓▓    \| ▓▓▓▓▓▓▓\ ▓▓\▓▓▓▓▓▓ | ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓
 _\▓▓▓▓▓▓\ ▓▓  | ▓▓ ▓▓ | ▓▓ __| ▓▓ ▓▓    ▓▓ ▓▓   \▓▓\▓▓    \
|  \__| ▓▓ ▓▓  | ▓▓ ▓▓ | ▓▓|  \ ▓▓ ▓▓▓▓▓▓▓▓ ▓▓      _\▓▓▓▓▓▓\
 \▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  \▓▓  ▓▓ ▓▓\▓▓     \ ▓▓     |       ▓▓
  \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓▓▓ \▓▓ \▓▓▓▓▓▓▓\▓▓      \▓▓▓▓▓▓▓

contract by
 ██╗      █████╗ ██████╗ ██╗  ██╗██╗███╗   ██╗
 ██║     ██╔══██╗██╔══██╗██║ ██╔╝██║████╗  ██║
 ██║     ███████║██████╔╝█████╔╝ ██║██╔██╗ ██║
 ██║     ██╔══██║██╔══██╗██╔═██╗ ██║██║╚██╗██║
 ███████╗██║  ██║██║  ██║██║  ██╗██║██║ ╚████║
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
*/
// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.13;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)



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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)



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
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
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


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)




// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)



/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)



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


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)









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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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


// File contracts/Shitler.sol

/*
  ______  __       __   __     __
 /      \|  \     |  \ |  \   |  \
|  ▓▓▓▓▓▓\ ▓▓____  \▓▓_| ▓▓_  | ▓▓ ______   ______   _______
| ▓▓___\▓▓ ▓▓    \|  \   ▓▓ \ | ▓▓/      \ /      \ /       \
 \▓▓    \| ▓▓▓▓▓▓▓\ ▓▓\▓▓▓▓▓▓ | ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\  ▓▓▓▓▓▓▓
 _\▓▓▓▓▓▓\ ▓▓  | ▓▓ ▓▓ | ▓▓ __| ▓▓ ▓▓    ▓▓ ▓▓   \▓▓\▓▓    \
|  \__| ▓▓ ▓▓  | ▓▓ ▓▓ | ▓▓|  \ ▓▓ ▓▓▓▓▓▓▓▓ ▓▓      _\▓▓▓▓▓▓\
 \▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  \▓▓  ▓▓ ▓▓\▓▓     \ ▓▓     |       ▓▓
  \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓▓▓ \▓▓ \▓▓▓▓▓▓▓\▓▓      \▓▓▓▓▓▓▓

contract by
 ██╗      █████╗ ██████╗ ██╗  ██╗██╗███╗   ██╗
 ██║     ██╔══██╗██╔══██╗██║ ██╔╝██║████╗  ██║
 ██║     ███████║██████╔╝█████╔╝ ██║██╔██╗ ██║
 ██║     ██╔══██║██╔══██╗██╔═██╗ ██║██║╚██╗██║
 ███████╗██║  ██║██║  ██║██║  ██╗██║██║ ╚████║
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
*/
// Help us shit on h!tler and raise funds for displaced Ukranians!









contract Shitlers is ERC721, IERC2981 {
    using Strings for uint256;

    ///////////////////////////////////////////////////////////////////////////
    // Public constants
    ///////////////////////////////////////////////////////////////////////////
    uint256 constant public MAX_SUPPLY = 2500;
    uint256 constant public MAX_MINT = 100;
    uint256 constant public MINT_PRICE = 0.069 ether;

    ///////////////////////////////////////////////////////////////////////////
    // Important Globals
    ///////////////////////////////////////////////////////////////////////////
    bool public mintOpen;
    uint256 public publicSaleTime = 1650999600; // April 30th at 12am UTC
    uint256 public totalSupply;

    string public provenance = "12345";
    string private baseURI = "ipfs://bafybeiela7lwj7jz5ehnvmolwn5nmpswtuxydi5alqff6y6fqsvpzmsqfe/";
    string private transformedBaseURI = "ipfs://bafybeiela7lwj7jz5ehnvmolwn5nmpswtuxydi5alqff6y6fqsvpzmsqfe/";

    ///////////////////////////////////////////////////////////////////////////
    // Team members and shares
    ///////////////////////////////////////////////////////////////////////////
    mapping(address => bool) private isTeam;

    address constant public LARKIN = 0x46E50dc219BA5A26890Dc99cDe4f4AC2a48011e9;
    address constant public YEAH_STUDIOS = 0x42db56A9b07C429FE1cfA80a99D46EB1AC05E2A3;  // yeahstudios.eth

    // Team Addresses
    address[] private team = [
        YEAH_STUDIOS                              , // Charity - CORE's eth address through Coinbase service changes hourly - funds will be sent to CORE post-mint
        0x05ed59e9765Ce11ACb387B66f91A99E1514ee7c8, // Pixel
        LARKIN                                    , // Larkin
        0x1BAcD207F29Ef028C5B761A686FFE6f6a385EF5F, // makerlee
        0xE62798584a153D5F9f2E5fA8993ad3Bfa42DF1BF, // makewayx
        0x727fA26Ee1B9813B299D7eb0FbB7e2edB6BAd184, // mustachi0
        0x12FF12Ab21B2C6E432158c5816F9CC1b6b2E2894  // Korey
    ];

    uint256 constant private TEAM_MINTS = 25;
    uint256 public teamMintsDone;

    // Charity and team wallet addresses
    //                           Charity  Pixel Larkin makerlee makewayx mustachi0 Korey
    uint256[] private teamShares = [510,    130,   100,     65,     65,     65,     65];

    uint256 constant private TOTAL_SHARES = 1000;


    // For EIP-2981 (royalties)
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 constant private ROYALTIES_PERCENTAGE = 5;


    mapping (uint256 => bool) public transformed;  // per tokenId

    ///////////////////////////////////////////////////////////////////////////
    // Contract initialization
    ///////////////////////////////////////////////////////////////////////////
    constructor()
        ERC721("Shitler", "SHITLER")
    {
        // Contract creator is on team even if not in team list
        isTeam[msg.sender] = true;

        // Validate that the team size matches number of share buckets for mint and royalties
        uint256 teamSize = team.length;
        if (teamSize != teamShares.length) revert InvalidTeam(teamShares.length);

        // Validate that the number of teamShares match the expected for mint and royalties
        uint256 totalTeamShares;
        for (uint256 i; i < teamSize; ) {
            isTeam[team[i]] = true;
            unchecked {
                totalTeamShares += teamShares[i];
                ++i;
            }
        }
        if (totalTeamShares != TOTAL_SHARES) revert InvalidTeam(totalTeamShares);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyDev() {
        if (msg.sender != LARKIN) revert OnlyAllowedAddressCanDoThat(LARKIN);
        _;
    }
    modifier onlyYeah() {
        if (msg.sender != YEAH_STUDIOS) revert OnlyAllowedAddressCanDoThat(YEAH_STUDIOS);
        _;
    }
    modifier onlyTeam() {
        if (!isTeam[msg.sender]) revert OnlyTeamCanDoThat();
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Contract setup
    ///////////////////////////////////////////////////////////////////////////
    // The developer can change a team member (in case of emergency - wallet lost etc)
    function setTeamMember(uint256 index, address member) external onlyDev {
        require(member != address(0), "Cannot set team member to 0");
        require(index < team.length, "Invalid team member index");

        isTeam[team[index]] = false;  // remove team member
        team[index] = member; // relace team member
        isTeam[member] = true;
    }

    // Provenance hash proves that the team didn't play favorites with assigning tokenIds
    // for rare NFTs to specific addresses with a post-mint reveal
    function setProvenanceHash(string memory _provenanceHash) external onlyDev {
        provenance = _provenanceHash;
    }

    // Base IPFS URI that points to all metadata for the collection
    // It basically points to the IPFS folder containing all metadata.
    // So, if it points to ipfs://blah/, then tokenId 69 will have
    // metadata URI ipfs://blah/69
    //
    // The 'image' tag in the metadat for a tokenId points to its image's IPFS URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId > totalSupply) revert TokenDNE(tokenId);

        string memory mBaseURI = transformed[tokenId] ? transformedBaseURI : baseURI;
        return bytes(mBaseURI).length > 0 ? string(abi.encodePacked(mBaseURI, tokenId.toString())) : "";
    }


    // Update the base URI (like to reveal)
    function setBaseURI(string memory _uri) external onlyDev {
        baseURI = _uri;
    }
    function setTransformedBaseURI(string memory _uri) external onlyDev {
        transformedBaseURI = _uri;
    }

    // Sale is live when public sale is live and supply cap hasn't been reached
    function isSaleLive() public view returns (bool) {
        if (totalSupply < MAX_SUPPLY && block.timestamp >= publicSaleTime) {
            return true;
        }
        return false;
    }

    function setPublicSaleTime(uint256 _newTime) public onlyDev {
        publicSaleTime = _newTime;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint!
    ///////////////////////////////////////////////////////////////////////////
    // Yeah! Studios™ can mint some to use for giveaways and team
    function teamMint(uint256 _amount) external onlyYeah {
        if (totalSupply + _amount > MAX_SUPPLY) revert WouldPassSupplyCap(totalSupply + _amount);
        if (teamMintsDone + _amount > TEAM_MINTS) revert TeamMintsDone();

        uint256 tokenId = totalSupply + 1;
        uint256 finalSupply = tokenId + _amount;
        unchecked { totalSupply += _amount; teamMintsDone += _amount; }

        for (; tokenId < finalSupply; ) {
            _safeMint(msg.sender, tokenId);
            unchecked { ++tokenId; }
        }
    }

    // Regular paid mint of some number of tokens
    function mint(uint256 _amount) external payable {
        if (!isSaleLive()) revert MintClosed();
        if (totalSupply + _amount > MAX_SUPPLY) revert WouldPassSupplyCap(totalSupply + _amount);
        if (MINT_PRICE * _amount != msg.value) revert WrongPayment(msg.value, MINT_PRICE * _amount);

        uint256 tokenId = totalSupply + 1;
        uint256 finalSupply = tokenId + _amount;

        unchecked { totalSupply += _amount; }

        for (; tokenId < finalSupply; ) {
            _safeMint(msg.sender, tokenId);
            unchecked { ++tokenId; }
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Withdraw funds from contract
    ///////////////////////////////////////////////////////////////////////////
    // ETH is received for mint and royalties
    function withdrawETH() public onlyTeam {
        uint256 totalETH = address(this).balance;
        if (totalETH == 0) revert EmptyWithdraw();

        uint256 teamSize = team.length;
        for (uint256 i; i < teamSize; ) {
            address payable wallet = payable(team[i]);
            // How much mint ETH is this wallet owed
            uint256 payment = (totalETH * teamShares[i]) / TOTAL_SHARES;
            if (payment > 0) {
                Address.sendValue(wallet, payment);
            }

            unchecked { ++i; }
        }
        emit ETHWithdrawn(totalETH);
    }

    // Royalties in any ERC20 are accepted
    function withdrawERC20(IERC20 _token) public onlyTeam {
        uint256 totalERC20 = _token.balanceOf(address(this));
        if (totalERC20 == 0) revert EmptyWithdraw();

        uint256 teamSize = team.length;
        for (uint256 i; i < teamSize; ) {
            uint256 payment = (totalERC20 * teamShares[i]) / TOTAL_SHARES;

            _token.transfer(team[i], payment);

            unchecked { ++i; }
        }
        emit ERC20Withdrawn(address(_token), totalERC20);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Royalties - ERC2981
    ///////////////////////////////////////////////////////////////////////////
    // Supports ERC2981 for royalties as well as ofc 721 and 165
    function supportsInterface(bytes4 _interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return _interfaceId == INTERFACE_ID_ERC2981 || super.supportsInterface(_interfaceId);
    }

    // NFT marketplaces will call this function to determine amount of royalties
    // to charge and who to send them to
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = address(this);
        _royaltyAmount = (_salePrice * ROYALTIES_PERCENTAGE) / 100;
    }

    // ensure this contract can receive payments (royalties)
    receive() external payable { }

    ///////////////////////////////////////////////////////////////////////////
    // Custom functions
    ///////////////////////////////////////////////////////////////////////////
    function transform(uint256 _tokenId) public {
        if (ownerOf(_tokenId) != msg.sender) revert OnlyTokenOwnerCanDoThat(_tokenId);
        if (transformed[_tokenId]) revert AlreadyTransformed(_tokenId);

        transformed[_tokenId] = true;
        emit Transformed(_tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Errors and Events
    ///////////////////////////////////////////////////////////////////////////
    error InvalidTeam(uint256 sizeOrShares);
    error OnlyTeamCanDoThat();
    error OnlyAllowedAddressCanDoThat(address allowed);
    error TeamMintsDone();
    error MintClosed();
    error WouldPassSupplyCap(uint256 wouldBeSupply);
    error WrongPayment(uint256 wrong, uint256 expected);
    error EmptyWithdraw();
    error TokenDNE(uint256 tokenId);
    error OnlyTokenOwnerCanDoThat(uint256 tokenId);
    error AlreadyTransformed(uint256 tokenId);

    event ETHWithdrawn(uint256 amount);
    event ERC20Withdrawn(address erc20, uint256 amount);
    event Transformed(uint256 tokenId);
}

/*
 Product of
 Yeah! Studios™ - @yeah_studios - yeahstudios.io - yeahstudios.eth

 Lead, Design, Branding: PixelPimp - @pixelpimp
 Solidity & React:       Larkin    - @CodeLarkin - codelarkin.eth
 Marketing:              makerlee  - @0xmakerlee - makerlee.eth
 Marketing:              mustachi0
 Genrative:              makewayx
 Social Media Manager:   Korey     - @ayeKorey


╔╗  ╔╗         ╔╗  ╔╗    ╔═══╗ ╔╗       ╔╗              ╔════╗╔═╗╔═╗
║╚╗╔╝║         ║║  ║║    ║╔═╗║╔╝╚╗      ║║              ║╔╗╔╗║║║╚╝║║
╚╗╚╝╔╝╔══╗╔══╗ ║╚═╗║║    ║╚══╗╚╗╔╝╔╗╔╗╔═╝║╔╗╔══╗╔══╗    ╚╝║║╚╝║╔╗╔╗║
 ╚╗╔╝ ║╔╗║╚ ╗║ ║╔╗║╚╝    ╚══╗║ ║║ ║║║║║╔╗║╠╣║╔╗║║══╣      ║║  ║║║║║║
  ║║  ║║═╣║╚╝╚╗║║║║╔╗    ║╚═╝║ ║╚╗║╚╝║║╚╝║║║║╚╝║╠══║     ╔╝╚╗ ║║║║║║
  ╚╝  ╚══╝╚═══╝╚╝╚╝╚╝    ╚═══╝ ╚═╝╚══╝╚══╝╚╝╚══╝╚══╝     ╚══╝ ╚╝╚╝╚╝

contract by:
 ██╗      █████╗ ██████╗ ██╗  ██╗██╗███╗   ██╗
 ██║     ██╔══██╗██╔══██╗██║ ██╔╝██║████╗  ██║
 ██║     ███████║██████╔╝█████╔╝ ██║██╔██╗ ██║
 ██║     ██╔══██║██╔══██╗██╔═██╗ ██║██║╚██╗██║
 ███████╗██║  ██║██║  ██║██║  ██╗██║██║ ╚████║
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
*/