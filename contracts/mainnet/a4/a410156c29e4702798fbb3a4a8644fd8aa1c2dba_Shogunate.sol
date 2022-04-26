/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// File contracts/library/SeedRand.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library SeedRand {
  function rand(
    uint256 _seed,
    uint256 _index
  ) internal pure returns (uint256 val) {
    unchecked {
      val = uint256(keccak256(abi.encodePacked(
        _seed, _index
      )));
    }
  }

  function randUint256(
    uint256 _seed,
    uint256 _index,
    uint256 n
  ) internal pure returns (uint256) {
    require(n > 0, "SeedRand#randUint256: n must be positive");
    uint256 val;
    uint256 div = type(uint256).max / n;

    do {
      val = rand(_seed, _index);
    } while (val >= div * n);

    return val % n;
  }

  function range(
    uint256 _seed,
    uint256 _index,
    uint256 min,
    uint256 max
  ) internal pure returns (uint256) {
    return min + randUint256(_seed, _index, max - min);
  }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// File contracts/interface/IShogunate.sol

interface IShogunate is IERC721, IERC721Metadata {
  /**
    * Method to return the soul of a Shogunate NFT. The soul contains all of the
    * attributes of the Shogunate NFT.
    * @param _tokenId - The ID of the token to return the soul of.
   */
  function soulOf(uint256 _tokenId) external view returns (bytes32);

  /**
    * Method to return the clan of a Shogunate NFT.
    * @param _tokenId - The ID of the token to return the clan of.
   */
  function clanOf(uint256 _tokenId) external view returns (uint8);

  /**
    * Method to return the token ID of the shogun of a clan.
    * @param _clanId - The ID of the clan to return the shogun of.
   */
  function shogunOf(uint8 _clanId) external view returns (uint256);

  /**
    * Method to check if a token is a shogun or not
    * @param _tokenId = The ID of the token to test
   */
   function isShogun(uint256 _tokenId) external view returns (bool);

   /**
     * Method to check if tokenId exists
    */
    function exists(uint256 _tokenId) external view returns (bool);
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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


// File contracts/interface/IERC721Subscriber.sol

interface IERC721Subscriber {
  /**
    * Method called when a token is transferred
    * @param from - The address the token is being transferred from
    * @param to - The address the token is being transferrd to
    * @param tokenId - The token ID being transferred
   */
  function onERC721Transferred(
    address from,
    address to,
    uint256 tokenId
  ) external;
}


// File contracts/ERC721Transmitter.sol

abstract contract ERC721Transmitter is ERC721 {
  // Subscriber to transmit data to
  IERC721Subscriber public subscriber;

  // Contract-wide transmission toggle
  bool public contractDataTransmissionPaused = false;

  // Token specific transmission opt-out choices
  mapping(uint256 => bool) public dataTransmissionPaused;

  /**
    * @dev Internal method to pause a token data transmission
    * @param tokenId - The token ID to pause the data transmission of
    * @param paused - True to pause, false to unpause
   */
  function _pauseTokenDataTransmission(uint256 tokenId, bool paused) internal {
    dataTransmissionPaused[tokenId] = paused;
  }

  /**
    * @dev Internal method to pause data transmission for the whole contract.
    * @param paused - True to pause, false to unpause
   */
  function _pauseContractDataTransmission(bool paused) internal {
    contractDataTransmissionPaused = paused;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._afterTokenTransfer(from, to, tokenId);

    if (
      !contractDataTransmissionPaused
      && !dataTransmissionPaused[tokenId]
      && address(subscriber) != address(0)
    ) {
      subscriber.onERC721Transferred(from, to, tokenId);
    }
  }
}


// File contracts/AbstractShogunate.sol

abstract contract AbstractShogunate is IShogunate,
  ERC721, ERC721URIStorage, ERC721Transmitter, Ownable, ReentrancyGuard
{
  using ECDSA for bytes32;
  using Address for address;
  using Strings for uint256;

  // Max commits per transaction
  uint256 constant public MAX_COMMIT_PER_TX = 10;
  // Max reveals per transaction
  uint256 constant public MAX_REVEAL_PER_TX = 10;

  // Next ID to generate
  uint256 public nextId = 1;
  // Total Shogunate supply, including both Samurai and Shoguns
  uint256 public totalSupply = 0;

  // Mapping from tokenId to soul
  mapping(uint256 => bytes32) souls;

  // Mapping from clan to shogun tokenId
  mapping(uint8 => uint256) internal shogunIds;

  // Open time of the reveal phase
  uint256 public revealOpen;
  // Max supply
  uint256 immutable public maxTokens;

  /**
    * Event emitted when a tokenId is comitted in exchange for a mint pass
    * @param account - Account that comitted the token
    * @param tokenId - The ID of the comitted token
   */
  event Commited(address indexed account, uint256 tokenId);

  /**
    * Event emitted when a tokenId is revealed.
    * Can be called by anyone, but token always goes to the user who committed
    * it.
    * @param tokenId - The revealed token ID
    * @param soul - The soul of the revealed token
   */
  event NewSoul(uint256 indexed tokenId, bytes32 soul);

  // Address that can allow metadata migrations
  address public migrator;

  // Default base URI for all Samurai and Shoguns
  string public defaultURI;

  // keccak256 hash of the probability tables to use.
  bytes32 public tablesHash;

  /**
    * Represents a commit.
   */
  struct RevealCommit {
    // User that committed the token, and will receive it once revealed.
    address receiver;
    // Block number that the commit has been done at.
    uint256 blockNumber;
  }

  // Mapping from tokenId to commit data
  mapping(uint256 => RevealCommit) public revealCommits;
  // Mapping from block number to block hash
  mapping(uint256 => bytes32) public blockhashesStore;
  // Last block that a commit was done at
  uint256 public lastCommitBlock;

  constructor(
    string memory _defaultURI,
    uint256 _revealOpen,
    uint256 _maxTokens,
    address _migrator,
    bytes32 _tablesHash
  ) {
    defaultURI = _defaultURI;
    revealOpen = _revealOpen;
    maxTokens = _maxTokens;
    migrator = _migrator;
    tablesHash = _tablesHash;
  }

  /**
    * Method to update the transfer subscriber.
    * The transfer subscriber receives data on transfers in the contract.
    * Owner only.
    * @param _newSubscriber - The new subscriber to send data to
   */
  function updateTransferSubscriber(
    IERC721Subscriber _newSubscriber
  ) external onlyOwner {
    subscriber = _newSubscriber;
  }

  /**
    * Method to update the migrator.
    * The migrator is the account able to sign authorization for owners to 
    * migrate individual token metadata.
    * Owner only.
    * @param _newMigrator - New migrator to validate authorizations.
   */
  function updateMigrator(address _newMigrator) external onlyOwner {
    migrator = _newMigrator;
  }

  /**
    * Method to update the beginning of the reveal phase.
    * Owner only.
    * @param _newRevealOpen - New open time
   */
  function updateRevealOpen(uint256 _newRevealOpen) external onlyOwner {
    require(
      block.timestamp < revealOpen,
      "Shogunate: Cannot change reveal open time when reveal is open."
    );
    require(
      _newRevealOpen > block.timestamp,
      "Shogunate: Reveal open time cannot be set in the past."
    );
    revealOpen = _newRevealOpen;
  }

  /**
    * @dev Internal method to generate a soul
    * @param _soulEssence - Soul seed
    * @param pTable - Probability table - Used in generation
    * @param aTable - Alias table - Used in generation
   */
  function _generateSoul(
    uint256 _soulEssence,
    bytes32[] calldata pTable,
    bytes32[] calldata aTable
  ) virtual internal returns(bytes32);

  /**
    * @dev Internal method to authorize minting a new Samurai.
    * Does all logic and actions necessary to authorize a mint.
    * @param _amount - The amount of mints to authorize
   */
  function _authorizeMint(uint256 _amount) virtual internal;

  /**
    * @dev Internal method to hash the probability and alias tables.
    * This hash can then be compared to 'tablesHash' to validate the tables.
    * @param pTable - The probability table
    * @param aTable - The alias table
   */
  function _hashTables(
    bytes32[] calldata pTable,
    bytes32[] calldata aTable
  ) pure internal returns (bytes32) {
    return keccak256(abi.encodePacked(pTable, aTable));
  }

  /**
    * Method to store the lastest needed block hash.
    * That method can be called by anyone, and will store the blockhash of the
    * latest block a commit was done at, therefore freezing its randomness and
    * bypassing the 256 block limit to fetch a previous block hash.
    * 
    * It is called:
    * - Everytime a commit, reveal, or recommit is done.
    * - By external Shogunate systems to enforce the randomness and fairness of
    *   the generation process.
    * It can be called by anyone who wishes to enforce it :)
    * 
    * Never reverts, simply does nothing if there is nothing to store.
   */
  function storeLatestNeededBlockHash() public {
    if (
      lastCommitBlock > 0
      && lastCommitBlock < block.number
      && blockhashesStore[lastCommitBlock] == 0x0
    ) {
      bytes32 lastCommitBlockHash = blockhash(lastCommitBlock);
      if (lastCommitBlockHash != 0x0) {
        blockhashesStore[lastCommitBlock] = lastCommitBlockHash;
      }
    }
  }

  /**
    * Method to commit a mint pass to the generation of a specific token ID,
    * using the blockhash of the current block as a source of randomness for a
    * future reveal.
    * User calling it will be authorized through the authorizeMint method.
    * @param _amount - The amount to commit - Must be less than MAX_COMMIT_PER_TX
   */
  function commit(
    uint256 _amount
  ) external nonReentrant {
    require(
      _amount <= MAX_COMMIT_PER_TX,
      "Shogunate#commit: Too many commits at once."
    );

    // Freeze the randomness of previous commits if necessary
    storeLatestNeededBlockHash();

    uint256 _nextId = nextId;
    require(
      !msg.sender.isContract(),
      "Shogunate#commit: Caller cannot be a contract."
    );
    require(
      block.timestamp >= revealOpen,
      "Shogunate#commit: Reveal is not open."
    );
    require(
      _nextId - 1 + _amount <= maxTokens,
      "Shogunate#commit: Not enough tokens available."
    );
    _authorizeMint(_amount);

    for (uint256 i = 0; i < _amount; i++) {
      revealCommits[_nextId + i] = RevealCommit(
        msg.sender,
        block.number
      );
      emit Commited(msg.sender, _nextId + i);
    }
    lastCommitBlock = block.number;
    nextId += _amount;
  }

  /**
    * Method to reset a previous commit with the current block number.
    * Can only be called when the block linked to the commit has an unreachable
    * block.
    * This method is intended as an emergency measure in case Shogunate external
    * systems go down.
    * Can be called by anyone.
    * @param tokenId - The token ID to recommi
   */
  function recommit(
    uint256 tokenId
  ) external nonReentrant {
    // Freeze the randomness of previous commits if necessary
    storeLatestNeededBlockHash();
    
    RevealCommit storage revealCommit = revealCommits[tokenId];
    require(
      revealCommit.receiver != address(0) &&
      revealCommit.blockNumber < block.number,
      "Shogunate#recommit: tokenId not ready to be revealed."
    );

    bytes32 commitBlockHash = blockhashesStore[revealCommit.blockNumber];
    require(
      commitBlockHash == 0x0,
      "Shogunate#recommit: Commit block hash is reachable."
    );

    revealCommit.blockNumber = block.number;
    lastCommitBlock = block.number;
  }

  /**
    * Method to reveal a maximum of MAX_REVEAL_PER_TX tokens.
    * Can be called by anyone for any ready-to-reveal token, but minted token
    * will obviously always go to the committer.
    * 
    * Provided tables are hashed and matched with the contract's tablesHash
    * @param tokenIds - Array of token IDs to reveal
    * @param pTable - Probability table to reveal with
    * @param aTable - Alias table to reveal with
   */
  function reveal(
    uint256[] calldata tokenIds,
    bytes32[] calldata pTable,
    bytes32[] calldata aTable
  ) external nonReentrant {
    require(
      tokenIds.length <= MAX_REVEAL_PER_TX,
      "Shogunate#reveal: Too many reveals at once."
    );

    // Freeze the randomness of previous commits if necessary
    storeLatestNeededBlockHash();

    require(
      _hashTables(pTable, aTable) == tablesHash,
      "Shogunate#reveal: Invalid tables."
    );

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      RevealCommit memory revealCommit = revealCommits[tokenId];
      require(
        revealCommit.receiver != address(0),
        "Shogunate#reveal: tokenId not ready to be revealed"
      );

      bytes32 commitBlockHash = blockhashesStore[revealCommit.blockNumber];
      require(
        commitBlockHash != 0x0,
        "Shogunate#reveal: Commit block hash is unreachable."
      );

      uint256 soulEssence = uint256(keccak256(abi.encodePacked(
        revealCommit.receiver,
        commitBlockHash,
        tokenId
      )));
      bytes32 soul = _generateSoul(soulEssence, pTable, aTable);
      souls[tokenId] = soul;
      _mint(revealCommit.receiver, tokenId);
      emit NewSoul(tokenId, soul);
    }
  }

  /**
    * Method to get the soul of the given token ID.
    * Reverts ig token does not exist.
    * @param _tokenId - The token ID to get the soul of
   */
  function soulOf(uint256 _tokenId) external view returns (bytes32) {
    require(
      _exists(_tokenId),
      "Shogunate#soulOf: tokenId does not exist."
    );
    return souls[_tokenId];
  }

  /**
    * Method to check if a token exists.
    * @param _tokenId - The token ID to check
   */
  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
    * Method to get the URI of the given token ID.
    * Returns the default URI concatenated with the token ID or a URI specific
    * to the given tokenId if present.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override(ERC721, IERC721Metadata, ERC721URIStorage) returns (string memory) {
    require(_exists(tokenId), "Shogunate#tokenURI: URI query for nonexistent token");

    string memory tmpURI = super.tokenURI(tokenId);
    
    if (bytes(tmpURI).length == 0) {
      return string(abi.encodePacked(defaultURI, tokenId.toString()));
    }
    return tmpURI;
  }

  /**
    * Method to update default URI.
    * Owner only.
    * @param _defaultURI - NEw default URI
   */
  function updateDefaultURI(string calldata _defaultURI) external onlyOwner {
    defaultURI = _defaultURI;
  }

  /**
    * Method to migrate token URI.
    * Must be called by token owner and contain a valid signature signed by
    * migrator.
    * @param _tokenId - Token ID to migrate
    * @param _validUntil - Signature expiration
    * @param _tokenURI - New token specific URI
    * @param _signature- Signature
   */
  function migrateTokenURI(
    uint256 _tokenId,
    uint256 _validUntil,
    string calldata _tokenURI,
    bytes calldata _signature
  ) external nonReentrant {
    require(
      _exists(_tokenId),
      "Shogunate#migrateTokenURI: Token does not exist."
    );
    require(
      ownerOf(_tokenId) == _msgSender(),
      "Shogunate#migrateTokenURI: Sender does not own token."
    );
    require(
      _validUntil >= block.timestamp,
      "Shogunate#migrateTokenURI: Signature is expired."
    );
    require(
      _isValidSignature(
        keccak256(abi.encodePacked(_tokenId, _msgSender(), _validUntil, _tokenURI)),
        _signature
      ),
      "Shogunate#migrateTokenURI: Invalid signature."
    );

    _setTokenURI(_tokenId, _tokenURI);
  }

  /**
    * @dev Internal method to test the validity of a signature
   */
  function _isValidSignature(bytes32 _hash, bytes memory _signature) internal view returns (bool) {
    bytes32 signedHash = _hash.toEthSignedMessageHash();
    return signedHash.recover(_signature) == migrator;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC165, ERC721) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _burn(
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Transmitter) {
    super._afterTokenTransfer(from, to, tokenId);
    if (from == address(0)) {
      totalSupply += 1;
    }
    if (to == address(0)) {
      totalSupply -= 1;
    }
  }

  /**
    * Method to pause data transmission of a specific token.
    * Intended as a way for owners to opt out of synchronization with L2.
    * @param tokenId - Token ID to stop the transmission of.
    * @param paused - True to pause, false to unpause
   */
  function pauseTokenDataTransmission(
    uint256 tokenId,
    bool paused
  ) external nonReentrant {
    require(
      ownerOf(tokenId) == _msgSender(),
      "Shogunate#pauseTokenDataTransmission: Caller does not own token."
    );
    _pauseTokenDataTransmission(tokenId, paused);
  }

  /**
    * Method to pause data transmission of the whole contract.
    * Owner only.
    * @param paused - True to pause, false to unpause
   */
  function pauseContractDataTransmission(bool paused) external onlyOwner {
    _pauseContractDataTransmission(paused);
  }
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File contracts/interface/IMintPass.sol

interface IMintPass is IERC1155 {
  /**
    * Method to redeem (burn) mint passes.
    * Can only be calledby the redeemer.
    * @param id - The ID of the mint pass to redeem
    * @param account - The account to redeem from
    * @param amount - The amount to redeem
   */
  function redeem(uint256 id, address account, uint256 amount) external;

  /**
    * Method to mint new mint passes.
    * Can only be called by the minter.
    * @param id - The ID of the mint pass to mint
    * @param account - The account to mint to
    * @param amount - The amount of mint passes to mint
   */
  function mint(uint256 id, address account, uint256 amount) external;
}


// File contracts/Shogunate.sol

contract Shogunate is AbstractShogunate {
  // Mint pass contract
  IMintPass public mintPass;
  // Mint pass ID
  uint256 public mintPassId;

  // Clans amount (attribute 1)
  uint256 constant CLANS = 5;

  // Max probability value (200 means steps in .5%)
  uint256 constant PMAX = 200;

  // Structure to hold generation data to pass around
  struct GenerationData {
    bytes32[] pTable;
    bytes32[] aTable;
    uint256 soulEssence;
  }

  constructor(
    IMintPass _mintPass,
    uint256 _mintPassId,
    string memory _defaultURI,
    uint256 _revealOpen,
    uint256 _maxTokens,
    address _migrator,
    bytes32 _tablesHash
  ) AbstractShogunate(
    _defaultURI,
    _revealOpen,
    _maxTokens,
    _migrator,
    _tablesHash
  ) ERC721("Shogunate", "SGN") {
    mintPass = _mintPass;
    mintPassId = _mintPassId;
  }

  /**
    * @dev Internal method to authorize a mint.
    * Redeems mint passes.
    * @param _amount - Amount of mints to authorize
   */
  function _authorizeMint(uint256 _amount) internal override {
    mintPass.redeem(mintPassId, msg.sender, _amount);
  }

  /**
    * @dev Internal method to generate an attribute with an identical
    * probability to select each variation
   */
  function _generateUniformAttribute(
    GenerationData memory _gd,
    uint256 _attributeIndex,
    uint256 _variationsCount
  ) internal pure returns (bytes1) {
    uint256 soulShard = uint256(keccak256(
      abi.encodePacked(_gd.soulEssence, _attributeIndex)
    ));
    return bytes1(uint8(SeedRand.randUint256(
      soulShard,
      0,
      _variationsCount
    )));
  }
  
  /**
    * @dev Internal method to generate an attribute according to a probability
    * table.
   */
  function _generateAttribute(
    GenerationData memory _gd,
    uint256 _attributeIndex,
    uint256 _tablesIndex
  ) internal pure returns (bytes1) {
    uint256 soulShard = uint256(keccak256(
      abi.encodePacked(_gd.soulEssence, _attributeIndex)
    ));
    uint256 pIndex = SeedRand.randUint256(
      soulShard,
      0,
      uint8(_gd.pTable[_tablesIndex][0])
    );
    uint256 biasedCoinFlip = SeedRand.randUint256(
      soulShard,
      1,
      PMAX
    );
    if (biasedCoinFlip < uint8(_gd.pTable[_tablesIndex][pIndex + 1])) {
      return bytes1(uint8(pIndex));
    }
    return bytes1(_gd.aTable[_tablesIndex][pIndex + 1]);
  }

  /**
    * @dev Generates a master samurai
   */
  function _generateMasterSamuraiSoul(
    GenerationData memory _gd,
    bytes memory _soul
  ) internal pure {
    _soul[2] = _generateAttribute(_gd, 2, 21); // Head
    _soul[4] = _generateAttribute(_gd, 4, 22); // Outfit
    _soul[5] = _generateAttribute(_gd, 5, 23); // Armor Color
    _soul[6] = _generateAttribute(_gd, 6, 24); // Weapon
    _soul[7] = _generateAttribute(_gd, 7, 25); // Eyes
    _soul[14] = _generateAttribute(_gd, 14, 26); // Datemono
    _soul[15] = _generateAttribute(_gd, 15, 27); // Mask
    _soul[16] = _generateAttribute(_gd, 16, 28); // Mustache
  }

  /**
    * @dev Generates a female apprentice
   */
  function _generateFemaleApprentice(
    GenerationData memory _gd,
    bytes memory _soul
  ) internal pure {
    _soul[2] = _generateAttribute(_gd, 2, 11); // Head
    _soul[3] = _generateAttribute(_gd, 3, 12); // Outfit Type
    if (_soul[3] == 0) {
      // Outfit Type is Armor
      _soul[4] = _generateAttribute(_gd, 4, 13); // Armor
      _soul[5] = _generateAttribute(_gd, 5, 15); // Armor Color
    } else {
      // Outfit Type is Kimono
      _soul[4] = _generateAttribute(_gd, 4, 14); // Kimono
    }
    _soul[6] = _generateAttribute(_gd, 6, 16); // Weapon
    _soul[7] = _generateAttribute(_gd, 7, 17); // Eyes
    _soul[8] = _generateAttribute(_gd, 8, 18); // Necklace
    _soul[9] = _generateAttribute(_gd, 9, 19); // Eyebrows
    _soul[10] = _generateUniformAttribute(_gd, 10, 4); // Nose
    _soul[11] = _generateUniformAttribute(_gd, 11, 3); // Mouth
    _soul[12] = _generateAttribute(_gd, 12, 20); // Face Paint
  }

  /**
    * @dev Generates a male apprentice
   */
  function _generateMaleApprentice(
    GenerationData memory _gd,
    bytes memory _soul
  ) internal pure {
    _soul[2] = _generateAttribute(_gd, 2, 1); // Head
    _soul[3] = _generateAttribute(_gd, 3, 2); // Outfit Type
    if (_soul[3] == 0) {
      // Outfit Type is Armor
      _soul[4] = _generateAttribute(_gd, 4, 3); // Armor
      _soul[5] = _generateAttribute(_gd, 5, 5); // Armor Color
    } else {
      // Outfit Type is Kimono
      _soul[4] = _generateAttribute(_gd, 4, 4); // Kimono
    }
    _soul[6] = _generateAttribute(_gd, 6, 6); // Weapon
    _soul[7] = _generateAttribute(_gd, 7, 7); // Eyes
    _soul[8] = _generateAttribute(_gd, 8, 8); // Necklace
    _soul[9] = _generateAttribute(_gd, 9, 9); // Eyebrows
    _soul[10] = _generateUniformAttribute(_gd, 10, 4); // Nose
    _soul[11] = _generateUniformAttribute(_gd, 11, 3); // Mouth
    _soul[13] = _generateAttribute(_gd, 13, 10); // Beard
  }

  /**
    * @dev Internal method to generate a new soul
   */
  function _generateSoul(
    uint256 _soulEssence,
    bytes32[] calldata pTable,
    bytes32[] calldata aTable
  ) internal pure override returns(bytes32) {
    GenerationData memory gd = GenerationData(pTable, aTable, _soulEssence);
    bytes memory soul = new bytes(17);

    soul[0] = _generateAttribute(gd, 0, 0); // Base
    soul[1] = _generateUniformAttribute(gd, 1, 5); // Clan
    if (soul[0] == 0) {
      _generateMasterSamuraiSoul(gd, soul);
    } else if (uint8(soul[0]) == 0x1) {
      _generateFemaleApprentice(gd, soul);
    } else {
      _generateMaleApprentice(gd, soul);
    }

    return bytes32(soul);
  }

  /**
    * Method to get the clan of a given tokenId.
    * @param _tokenId - Token ID to check the clan of
   */
  function clanOf(uint256 _tokenId) external view returns(uint8) {
    require(
      _exists(_tokenId),
      "Shogunate#soulOf: tokenId does not exist."
    );
    return uint8(souls[_tokenId][1]);
  }

  /**
    * Method to get the shogun of a specific clan.
    * @param _clanId - Clan ID to get the shogun of
   */
  function shogunOf(uint8 _clanId) public view returns(uint256) {
    require(_clanId < CLANS, "Shogunate#shogunOf: Clan does not exist.");
    return shogunIds[_clanId];
  }

  /**
    * Method to check is a tokenId is a shogun
    @param _tokenId - Token ID to check
   */
  function isShogun(uint256 _tokenId) external view returns(bool) {
    require(
      _exists(_tokenId),
      "Shogunate#isShogun: tokenId does not exist."
    );
    return souls[_tokenId][0] == 0xFF;
  }

  /**
    * Method to generate a Shogun.
    * Owner only.
    * Once a shogun has been minted for a specific clan, it cannot be minted
    * again.
    * A shogun token cannot collide with a potential Samurai ID
    * @param _tokenId - The token to give the shogun
    * @param _clanId - The clan this shogun will lead
   */
  function mintShogun(uint256 _tokenId, uint8 _clanId) external onlyOwner {
    require(_tokenId > maxTokens, "Shogunate#mintShogun: Token is reserved.");
    require(
      shogunOf(_clanId) == 0,
      "Shogunate#mintShogun: Clan already has a shogun."
    );
    bytes32 soul = bytes32(abi.encodePacked(
      uint8(0xFF),
      _clanId
    ));
    souls[_tokenId] = soul;
    shogunIds[_clanId] = _tokenId;
    _mint(msg.sender, _tokenId);

    emit NewSoul(_tokenId, soul);
  }
}