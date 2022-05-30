/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
//Albert Banez
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

// File: contracts/FashionCrypto.sol


pragma solidity ^0.8.4;




abstract contract WithLimitedSupply {
    using Counters for Counters.Counter;
    /// @dev Emitted when the supply of this collection changes
    event SupplyChanged(uint256 indexed supply);

    // Keeps track of how many we have minted
    Counters.Counter private _tokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private _totalSupply;

    /// Instanciate the contract
    /// @param totalSupply_ how many tokens this collection should hold
    constructor (uint256 totalSupply_) {
        _totalSupply = totalSupply_;
    }

    /// @dev Get the max Supply
    /// @return the maximum token count
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @dev Get the current token count
    /// @return the created token count
    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    /// @dev Check whether tokens are still available
    /// @return the available token count
    function availableTokenCount() public view returns (uint256) {
        return totalSupply() - tokenCount();
    }

    /// @dev Increment the token count and fetch the latest count
    /// @return the next token id
    function nextToken() internal virtual returns (uint256) {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return token;
    }

    /// @dev Check whether another token is still available
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    /// @param amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, "Requested number of tokens not available");
        _;
    }

    /// Update the supply for the collection
    /// @param _supply the new token supply.
    /// @dev create additional token supply for this collection.
    function _setSupply(uint256 _supply) internal virtual {
        require(_supply > tokenCount(), "Can't set the supply to less than the current token count");
        _totalSupply = _supply;

        emit SupplyChanged(totalSupply());
    }
}


abstract contract RandomlyAssigned is WithLimitedSupply {
    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    // The initial token ID
    uint256 private startFrom;

    //uint256 public preSaleStartTime = 1653390000; //May 24, 8PM
    //uint256 public preSaleEndTime = 1653940800; //May 30, 8PM

    //Changing the startIndex
    event startIndexChange(uint oldValue, uint256 newValue);

    /// Instanciate the contract
    /// @param _totalSupply how many tokens this collection should hold
    /// @param _startFrom the tokenID with which to start counting
    constructor (uint256 _totalSupply, uint256 _startFrom)
        WithLimitedSupply(_totalSupply)
    {
        startFrom = _startFrom;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextToken() internal override ensureAvailability returns (uint256) {
        uint256 maxIndex = totalSupply() - tokenCount();
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        // Increment counts
        super.nextToken();

        return value + startFrom;
    }

    function _setStartFrom(uint256 index) internal virtual {
        uint256 prevStarFrom =startFrom;
        startFrom = index;
        emit startIndexChange(prevStarFrom, index);
    }
}

contract FashionCrypto is ERC721, Ownable, WithLimitedSupply  {
    using Strings for uint256;
    string public baseURI= "https://fashioncrypto.io/data/fashion/json/";
    string baseExtension = ".json";

    uint256 public cost = 0.05 ether;
    address public ownerAddress = 0xcff635D73F4Cd7C4005cFC3FE7cc01bb60F42FDd;
    bool public blnSale = true;
    bool public blnWhitelisted = true;
    uint256 public startIndex = 50;
    uint256 public endIndex = 250;
    uint256[] private usedTokenId;
    uint8 public batchMintMaxAmount = 5;    
    uint8 public whiteOneMax = 10;    
    uint8 public whiteTwoMax = 1;    

address[] private whitelistedAddressesOne =[0xcff635D73F4Cd7C4005cFC3FE7cc01bb60F42FDd, 0xe03895910e1190d846AeD3BEB317A84E1Ff892d2,
0x4e48783F618ecB06ddFB07D36c49119C2b82F0F4,
0xc20873d40e6F75BF6C39F3BB48bFC1847f335dE2,
0xaA3FcbF8ac0B093C20978EE025e25D95943B7a27,
0x5b2e7eCB43E61B30a7d0B3B698C430b204C22dBD,
0xBA8B0Ea93F9c7cf473e7f99E3bD52AFD37fa55eF,
0xBb209d8F0497e7b64813a7F91960a88d182331E9,
0x7B56dEB150df9dD428C1770fFDf334468f92a444,
0xbaDF8a6bA6EbF14E7690cb95782f5e492Cc47d75,
0x2224BC00EAD1d90365d860ed0C6A21363dA40784,
0x8872485d20694495aEccb098692270C3Ee419935,
0x0fF745e8Df3BCef82D59A8b8fB9cE8c542534136,
0x62017eb3cBc67F977A4bf962cF2Dc49C537f6cCa,
0xF133Ee684d71aA470D7B3ef2868cafaBa53E473e,
0xdf2cd7b522aaeF6dC418CF83cc1e815C1E2Bf8B0,
0x2e2489628CD9f1B98DfB83BB57DA2d0C10109019,
0x9119cc7143250C43b82A02f63BaCF7bDea930669,
0xbA87461c49666f72AFC1D2D805aF6dEB2E193A70,
0x575848A2a2fBf466d31a42820c90F7a71950192D,
0x2a1D69a0830f6094ec318d93A8779dB877871736,
0x500A9D4b9463dA8ef6885b13A66c32916a68af7a,
0x04606154dA2844fa6147F54e3A035651CEB2b197,
0xb6c5feC131aC371456B92B406C25948A83AcaBC1,
0x1cfe6cFD5DbEFD1a5B09524c949e4c4A606972Da,
0x2E8b6a975F7B0edCfe78A2E377329B6c575DC50F,
0x875B1A1Dd84Edf1012fa0d7A0c997425Fda12eFf,
0x138B5C84ba91ea4b95739A527e340489FeF2FE28,
0x3E0034B5D25bdB668EEc68e2643A2DFcFE786766,
0x5DE51b7944c766b1CAdce299463059bdEc38C1BF,
0x23EbD54Fd65825e06a6e5AACc1A0b523BFeb748e,
0xc30d117D16f6eB743BB0019e7863671919368cD1,
0x1557299331AAe614896e4fDC82D882C62Fb62302,
0x108C04d9145c93fE9E3B07Ad27698EDFd5e6e498,
0x4f355A9C74Bd22A90fa32DE4cD129da1999520aA,
0x6cB9C2c61908658e3C9875C864B5e2CAb2f21a4c,
0xE8b7a54AC34D1bA55Fd0E92a79136E7A225C2451,
0xf81Ef872db0ff70bDD3D7b729Ff0440E72b33b18,
0x2eFe4fA1D55880879800638021632F6b9c6F088C,
0xC88f6A403D1F2Ff76c6aB4a71ece88aA6321A40E,
0xd45D61a7762Ed1236b275caDA5f1171D74E008ab,
0x1da10F21F60920d940506939148Cac505315a707,
0xf4a33929872B87BB67dDCAC38548c808DD38F2ae,
0x545FF76F9Ee769B144cb79146c1069cfa0ef2A9f,
0xda4486A591B4543562713cE1413f34b44D3af45A,
0xBD3b7cCd7F58C40DD1150d3487f854f468357D4c,
0x869A83C3D912318fb8FcAC6ADadDaA50c2F373f6,
0xfef634E9Adc613871DE7FE764c38101d8fE85d68,
0x04f7244581360ae45eE6d136dd9ec64926c9386C,
0x012Bf606c1f1AB362A62dBC3e3d3e937027e198D,
0xB18cCecd1FbEBC7C3E30Cc70983720D9d672e8ca,
0x2834e08F4EeCd7b63A6FEFb8eBAadB3fDD277602,
0xE944b8ebBDE99A4D29Ba3faC1931435352d07956,
0xA0DbD3771a4fB21B517BbEa198bC335A44601A4E,
0x2CCc19E242e2f4C2541DAD341be3792Ac0eEd010,
0x16a20ac1719E1F68d663de5504fe58fE9b1ed758,
0xa1ce1e761695fCdB0288d94d3bc08e825064C0a3,
0x67DC869ef404607977833B7810310bA1466324B4,
0x73EB4c1DADb5cee393DA1e80b9a7098fa5afd437,
0x0955C6965Df31558C5D2a7A0F66631c16Dd42980,
0xBE19aa80959bc7c85970AEe306Ecef2cC03844E2,
0x87d7C97B5a69c26C5CBC99b1B27937eDf5ccA10d,
0x5ad430F7eeB9af006001fd21F9Ab27E1b994b506,
0x513db322a397701BF624B517B00291F82B665884,
0x520F3AFd4d156e71Fc26F330AcA6f89E083ff524,
0xF24c2c1A7d479F6B50D6c2065Da97366Ec9Fe39F,
0xe11394F5F5BD7244e73A253B2081Ba5BAA7d2432,
0xf5a9B8Ea9fb71aB2dA81A866d6877b4dd717f9d1,
0x0a1D634e51809b93ae943c9faf6027F117315d7E,
0xeaF63e1917F0B67b8dB58513115764b96Bf90320,
0xD6Fe2aC29E9A8ba1ed61B7689BFA864b31E8f3E6,
0xe2338c6f7148b792CE76a56F6Ff22aFaEbb9c4EA,
0xEF64c2Ac694185DBe61bC74E1505f28C86AB3AC0,
0x669f900DeA5cA376d9a7B6ceDB7D1ec744A24102,
0x0458f111cA216AdA7bB69bD673fF18c2816AeA27,
0xC5D55B32F0D317882c0aAa3b0A963d8CBe094C7c,
0xabe3E2EBd4784Dba6a80Fe341713Fc0532C219fb,
0x9C1c8a2F2AcCc64DAd1C6bd26F0B36aa65Fce219,
0x0A621d9bFf0E8d7978aD40282CBD28944Fef94df,
0xaBc8c7DD623eA76780f9aaA11f429B9602A6ae15,
0x0996Bb48A27E684414B151FfA0e902fB19543021,
0x4AA5C3269420f3D82a96B515a6C470d3fb7db3Fd,
0x31d226B0B94c3d13Cb067960f74e7f1e8aFd2EFD,
0x919aED549781C36882952751AD2A6c33527C0260,
0x4dBE58c21566Ebe2E48E009D4754461b606D990c,
0x3A7546280C77611191e06637adCD0250A2C719Aa,
0xC992BA0cE9aFdADfed23F1C3c654022e9E180686,
0xb49E763A51236602402b3E858Ee76c319F7c27dD,
0x83057f7bFb2d97eA7A9463F683db758aDCA71e8B,
0x251417D5F3315134ffC2295f80D7BfddDB698c14,
0xfB42cDc1EBa64d062Bf50644044aB5fE0E1282E8,
0x4Ab3190Dee3D3191df678A9e324f5D243E0a8B54,
0xd9344A213EAb0A9e8F15Dd3BBb2fDBdba35be368,
0x65d51D3554c6908A75712F1312C971281C8Dd79A,
0xB14Fa6697A7250f237291b56882331567cEFa3d4,
0x29d25f171EDfD17B5bB0b66628fB5286b7D29aea,
0xa3e371b5A01D8ce593A03f7248f42045d84A69F7,
0x13A6FCF17523451716E768fBCf23C150E81d3A24,
0x4eD3A923bD2DeEfaB72cd10E1152C2B5bbeF8506,
0xB4384bbEdDe91d50e257A364f8341B4E73Cb4231,
0xC907C13B7761575C403a6A79f04f9B3fAC6A6D03,
0x5ed20622a0037972644aF6B04E73e80A30C984d2,
0xf9BbD6b7a6224684f40A322232F7A011B96b873D,
0x03E6c622e80b728e93e721AfB51480cbcbc18A60,
0x2d1F22eAaeE458F7aFa58e29d71C746e2C326C27,
0x32E62E30F4c2e93B2D458c99d01e6A129B0da931,
0x87B6E64e98579fd7FB00bb9cEb76170faa8BACf7,
0x8A1182A263A55B4eB07dEEDC301815076739Bd53,
0x9bF8C690917b1a1D87a415a53636D3b0B9DFEBeA,
0xdF5f4DCA715d7F0CA82502E3DA3f3100d0A5fec0,
0x660e3533d3B089e48dEdc8b93A276a88258976a7,
0x5A01887De253D6142ee7db6530F6F749dfE83b76,
0x9f944958481BA262628957688DE6F4c3aAd9D805,
0x34cE42EeB1548d521cE52D4d3Fafe7ccD8629E68,
0xfc9b689b07776E3dcE406b8CDCFa4872AE3c9939,
0xBB0DF31b908053Ee001053E667EEf5b79d1a7E55,
0x1C0fbf1E1fD170010eca7016E6A9431Ca7c41D81,
0xDAc33C13D2631a89B966E259b4Dfce38E21F05b9
];
    address[] private whitelistedAddressesTwo =[0xB5F442aAA72d1a56A5431C459d94cC228de3b7eD,
0xA2EeC290592930350CC553Ef3a22Fa77CF9Bb058,
0x75950A08c633C9cfC14dF1F3E04058bB0DDacF85,
0xBa2e3b65A5E005cA8C8d3f36f4ba7Db9fE9F5948,
0xA94D609db541E1E21FD1179a63Ac41A651584EDb,
0xa8A5c10c39b6e0e42E09f288C1d122151550A722,
0x5Bf7f1552a8e2E02ab42969a267A30F927eFAd60,
0xc0c4ae2be965f660E109002d176D624B21c1CF13,
0x22d0a06717E2bA3A232c371C50CD55DbB7879CC7,
0x9044D452dC7A3506f363E6e8299c201ae344eA4A,
0x3DF9b94f7717ADC8F331E25cC967038a1e58ad53,
0xf5b529386e563cc25990E59afB5800f16d8F1189,
0xC14031baa3fC1E4eC64E12A4279126Be2157D76d,
0x051311C1D26443D6D87eb6A13A55ece32C97a7Ab,
0x1a2dE0E9dEdb22376626d5dda00f238C56cA4835,
0x3ac1C033c6ED5a4fb02014Cb984Aa3A055649E03,
0xFB06C94A6Da258E787AA9260E38832278080319c,
0x7a83B7EDB98956e7bC1aa107677354ea91608A38,
0xF1DD9a61234Bb81e28c42A8F76CC3D2f02F8FaB7,
0x61cC678Ac7AE5FD6A807480A7F229c1614fc6788,
0xd64539430357Bb87066e8e0AF5EbBF962CD9588b,
0xCB9DCD60980a74F27f381f93241A8b0Bf4B4A024,
0x72aa1F778dA7D960f6eA60D3c6Dcb9a0F76D0408,
0x8D5B11d815A6f35054b1B73e283FEA61b60737Be,
0xc1d423aE49fba66AA713610811d13e0BECf213c6,
0xA0a4A879B767EA2d6B23f7120F86f455c4E0A0cB,
0x35d6Cd57f4B6D561ad52f8aB5E9E10E6c159aa5C,
0x60f4Fbe6F706A67Bc560b4b7EecBb8f74193c658,
0x38BBe79305f908DD87a4417347ffE5C4A0Ea0Ec9,
0x2c120a611029B6E0d7d3827855592d3491191475,
0xAeE79B5D2a67A18Ca2Fe9a4E614D633f9dD7969E,
0x282C247EFC6408814A57ee1c2a0974042A54530e,
0xd8C84502264E9E0505e34AFe480bC3eCa62Fdd1b,
0x1851f43e431B74D1875FA966E26CB6a637790010,
0xd5965bA259aFf23080eacEECEf99dd80afc51B70,
0x123718c9F9B9c48048DA9A1134f9fCEa8E86a0D5,
0x8dD6ACDA4459de971a385B00DF177Cf41006a027,
0xe44659d918Ef53440C249bB5fA19ADbFfc057F82,
0xDD1132316Ac5cD0c1f358CbC06d930b8A674270B,
0xb4C006781B17a28fb68EB3B0D08c443E64A92cC1,
0x7134bdcDE26EC21021579175Cb9C60a4C93e97E6,
0x76F511623a40F35462Fda74847140bE5F1b23cE6,
0xfCBA7891121114F6FcF9cd2549bE4Ee7208454f4,
0x1fD6f1274AFBe571b66d19A8e8E1917a5e370E6e,
0xCd1fe3f3361E1A49b3CC415e7B2D0BF0C83d35ad,
0xFf2b935C5635A5aF779F8f040c4EEE6A1Fc772f2,
0xDdEF9F37Db1012D93E027A59752a1Eb084652498,
0x27dA21ab92aF4427f749F7aE282Cd3b9f29190Dd,
0x88684818e4Db145B3E4D8DF61192F96A0ca12F2F,
0x7C062b42720C5A16F67825476dEe09b3a2Dc13B1,
0x0C85E48e616fdd33720c00baE14668e833C82DEC,
0x119cE2117315b238c233c46a57Cd44d3F06B2fa9,
0x5f80f73d93895B89BDA6d47ab374a33ef0F62380,
0x2ae1f63142D9D81A65D882261A903ca4D06B5Bbe,
0x3C407D6c0Bca77456EC7AfeEbdaad81E8b23aB31,
0xC575cFaccbcC497C05936e70fCfC1a42D69F4CC0,
0x3b609939B50d10Cf822274C62Daa9c6053ce0F74,
0x6fC264D1AdacA3557d67d7A72a737F89dba13552,
0x6327191Ea83a372eC049633665FB679a233835dA,
0x6e04B6ac4bB1bd33E0490d126bCAd3c8e3C4f78D,
0x6A501447C443b9aA58E91eF4505B24FF25940fE1,
0x0445E3d6742F3Fd10a3781093e4f90bEFFaED31a,
0x8bA7f68C6d89b7D232ffcf5f58719996799Bb8a2,
0x657D736e04ccD506541f5A12044480eC93D2a308,
0x9A00f5f51EF96d1e8414D620c077Ead407c28AE2,
0x5ee9595c4912085B5A10CC884ee3D155920C35De,
0xF19d298D79Da876F93893b9df830F94865E28662,
0xa15Fab718b0cB25F82d61F58c014bD88a87EEED2,
0xF72fa7Cdf36b3F58Eae1da8929B1F67972504aF8,
0xB3Ec4C6C6B6aCa3DCe1ac400A9De37B8757e4B4C,
0x9452297493f5c9d65BEca47f1e6d5Aac13dED2f7,
0x6758608Ffc82E3c9F3520B94a0c77e8Ae2F6Bf7A,
0x581d40199937e70C5f5757547f230d790B00EB85,
0x02B3BF262Df4A97CE27383654C8858E73413F590,
0x6C6A9F4C1B227e9507B1f7680e7B5734a0529802,
0x82Ab0c87270Cc177B73b0d3e5cFD48a8f8FFD10d,
0x4Dc68B875279eFb0D0c1c3292d79848AF402c0FA,
0xf3F2F4c0c22F97A295091A4BE7f18a9F797E30Ae,
0x764394B7cde04489f436Ac6E1F272Aae62fA65a1,
0x251Fb2Fd729707dF6aF0C709681EFD25371cE8A9,
0x04D2CB63c907421E5FC215d4064A31f41156f4B9,
0x6c07aE8e5213115996867427B5DB8eDfc722900C,
0xC641b1ff7aD7fAd7D37ff9B2854DcBCd167212E7,
0x69512b193a2Fe70073b4c59cB9E27199B921DAc6,
0x78C2493597D3e767279e03F0d3Fea8E126329dE0,
0xcc811e52f35e758A24e0FEaA2b7439Bc21Ee4d21,
0x31C9BcE1020Ac0880E285C36CE8a89693a9F13A4,
0x4Ae2C32f298Db0dA192Cb225863bB797BbD9d1fb,
0xFb2F62d691CA8c9dD07cd859aa0Ac2930d558F66,
0xD6474B0b45834646FB3BD7e5F9c7096d97b66676,
0xC5cE03F7A4de6c44198C5b84549c45F4F1af8d87,
0x42D358F92Bd5d96D96c810625A5a13A483D149D7,
0x17C30c09Ab306e10a2e9999e89BB1883C9835E5a,
0x761225B1800af40fa73Ca615bb588cF63dD85BC7,
0x47443460C613C9323b1bF54D42B2903fAFc11664,
0x7179B654D852a93169db56dcDfBCea19Be1406Ca,
0xccc105058D1528D3E3bC3490713da97c37377976,
0x9bEDC4CE02dAdd1Eaac86362Dae44B909bFb24C4,
0xe6a9b136C17745573D43569c22aBBde34f1512a9,
0xe7552c4D4B655a100048689a32C41E92019217E9,
0x519114e1f68Dd9aa14AE60a14519F4698cC5Ef4e,
0x6F814B38fE1b1E3B6d7b323b66B500b97513CBb0,
0x1c24732509eFd844B5F398C4a3c6e255744FDE0f,
0x24e8cBCEce8eC14120Ae18d168Ceea059c6a4d3a,
0xfaC8EE3E18a18d9AE90831B1F60d513A6839D7EB,
0x271010FeEaC18Bc0C1f9082533A96EaCa2e30201,
0x0A8A034C161d9Cda052f40Eff0b24D6A6a05fdC9,
0xB1dc395a592856F7B5A9ae53B98aF8a64BDf6c85,
0x5fFFf27BCCD898a8B88D5FA431600bb6c7b94117,
0x92D3B546902f7ab1d7A595Dc3CF9F4C834C02fD4,
0x28012C04EC61d20Bcf6612F9313b4cC7089716Dc,
0x37a7679B309f62aE78C41092A60a0E7c994d7400,
0x22443d3ec9aF561C49d8389B9CB06069b7b3d304,
0x80ea006315A1c8278419BED1951c4fC047581641,
0xE30363483d911f59176B83c976637b5A8FBdC9cD,
0x834792b23B13035b8c38d8F37c9486099d5c2971,
0x561eE7C9fCb2EFEEa5B7Bf3C55deA36B15C07Bdf,
0x200404D036525Ce6F2056ce4c4cF8E25CC50B6d6,
0xD3De7FD8BF1667D97Bb9aaE7bA738EfDf34641dC,
0xDE7BC955c03aD2fc66955De7E4E84528260923bC,
0xC622b5FB8046950A4E56E98FE2b2a0E97340B82C,
0xBC5353f7a98412dC4583a8DBEFF5da3267aA264F,
0x6D3b5F1191Da580f88D40B911D471991199836FE,
0xA46666810794069Cc6eE3CEDb1AA62904dB24553,
0x1D08f4F40cC8Ae7eA0B37115B2b48620a43Bf403,
0xf18977B29C1F87F9871B8a7a5aF1e4059e39b9FE,
0x86170f6B17B8bC41C0C06c8aa0C2d7754A3605C1,
0x5a18a5a696c7f1b1D2c097D05d5e479D8f3eaEb6,
0x1203D4615D87E159Df82401C7acC89b59b5C64F6,
0xd1fEC8Da7edcfd651fBcBdE789aA27b38055F102,
0x4C843a3D077C353533b81aD2435268C8611fDF16,
0xDB8bc40369dACb601C21B2dc978F4988F51101cb,
0xA75747f401d938593b8124e6eb08e910c16B20Da,
0x37e0ec7fD9568a45dE59200aE69F01F8A69D59dF,
0xB5457E56C5154536A6ABEe2654Cfa32efCAF5956,
0x8661A1D4199A7b5372A488F6FaF590F179F98Dca,
0x9896021a2D4E9124BE5827a2792d02189f26D798,
0x0ab865AF5ab3c0854AfF619907c72A04E9c70DD7,
0x16CDE6ef425fdF7997525E38C31b2FC2Ad0b44bb,
0xCd33cfb6337032de97b74E1CBBFad835a9a4B9ce,
0xe18Ba83765406fcAE655f57dE36c40B64C6d2c2e,
0x845C9f3E5F63B739b27E92f50cAf55E695AFc902,
0xc12cf671656eb6E835B31A907A33a4a00AF00165,
0x93C3228B964b37947a4c7dA3E9FFf513dED3fF49,
0x133B2f8476af944c434454695313082215d5c4b3,
0x32474092852f1DA9f95A96fAF0FF3D254dfb1F91,
0x3612397C7bED3d2E9337d46827e869A7B13eC3eb,
0x760228f299677B1023b02Cbb1B9cf7147e077174,
0x9b57E1B617343F29b6386c00d14e5189e38EdA71,
0x0825Cf6a4115b770b4fd65373ff10ed51680E5Ee,
0xa6bC0614Ae72d8189f53700e5B9b62D23bF115bC,
0x8C41F8BB5b83De10AC8fbcd3CfC6ead69f84aD87,
0xA21f6bC5BC20f221f16f85FfCA8eDF0Ec6637ecE,
0x81A20A1c885a574a01d77b9847AA4f1D99EcDd3a,
0xd17Ab43D8f8E55eaB25725A5988Cea80d172102A,
0xF7789a8815FF679576943c8b57FA136C9dfF0754,
0x69Dfe997A1185f22B0B0a786247afcf36b670817,
0xE285834728BD7259791c6E6f63Ed0bAbA36Fa151,
0xF728e65fF04a2185ac5508dC83a6f3634Af2ad4B,
0xA84AefA8CF9377Fd80D9d0ccCC89A13fc308E206,
0xA57394Fb12D0aB830E80dCC55B45114629F78b30,
0xB00c93AB586Deed458864f262B0493194B02Ba84,
0xebe8f27c2DE46c1DF567990c9720Dc169AA86300,
0x981a1E7A9C337600c414889163117b1CF2De48Aa,
0xbD7E7FDF65633c54f13e751b5cb0fdf561237B70,
0x2fb975cd9Bd2Af43F2f7b7C03B63d29d9C83FB37,
0x34509b079D54A602998A289A1FF3a27601a46A4A,
0x7C043d5C962cfaf39A84367731dCd804eb03bA08,
0x6678eB423E5F954A8d7ab47Fa3373F9F743C1686,
0x44dA0Db572bD33d689e4D8Fab8b5D93192794016,
0x5a3d6C4642E7F575030a6e9B41Bcc60719AF2A18
];

    constructor() ERC721("FASHIONCRYPTO_Genesis", "FCG")  
     WithLimitedSupply(9999)
    {
    }

    function mint(uint256[] memory tokenId) ensureAvailability public payable     {
        require(blnSale == true, "Not Sales Period.");
        require(tokenId.length <= batchMintMaxAmount, "Maximum of tokens to buy at once exceeded.");
        require(msg.value == cost * tokenId.length, "Price must be equal to listing price.");
        
        if(blnWhitelisted == true){
            bool isWhiteListedOne =isAddressWhitelistedOne(msg.sender);
            bool isWhiteListedTwo =isAddressWhitelistedTwo(msg.sender);
            require(isWhiteListedOne || isWhiteListedTwo, "Not on the whitelist! Cannot buy during PreSales Period.");

            if(isWhiteListedOne){
                require(balanceOf(msg.sender) + tokenId.length <= whiteOneMax, "Max mint per address exceeded!");
            }else if(isWhiteListedTwo){
                require(balanceOf(msg.sender) + tokenId.length <= whiteTwoMax, "Max mint per address exceeded!");
            }

            for(uint256 i=0; i <= tokenId.length-1; i++){
                if (tokenId[i] >= startIndex && tokenId[i] <= endIndex){
                    _safeMint(msg.sender, tokenId[i]);
                    usedTokenId.push(tokenId[i]);
                    super.nextToken();
                }
            }
        }else{
            for(uint256 i=0; i <= tokenId.length-1; i++){
                if (tokenId[i] >= startIndex && tokenId[i] <= endIndex){
                    _safeMint(msg.sender, tokenId[i]);
                    usedTokenId.push(tokenId[i]);
                    super.nextToken();
                }
            }
        }
    }

    function mintOwner(uint256[] memory tokenId) ensureAvailability public  {
        require(msg.sender == ownerAddress, "Only Owner can use this method.");

        for(uint256 i=0; i <= tokenId.length-1; i++){
            _safeMint(msg.sender, tokenId[i]);
            usedTokenId.push(tokenId[i]);
            super.nextToken();
        }
    }

    function isAddressWhitelistedOne(address _user) private view returns (bool) {
        uint i = 0;
        while (i < whitelistedAddressesOne.length) {
            if(whitelistedAddressesOne[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }

    function isAddressWhitelistedTwo(address _user) private view returns (bool) {
        uint i = 0;
        while (i < whitelistedAddressesTwo.length) {
            if(whitelistedAddressesTwo[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }


    //internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function updateCost(uint256 costParam) public onlyOwner {
        cost = costParam;
    }

    function updatebaseURI(string memory baseURIParam) public onlyOwner {
        baseURI = baseURIParam;
    }

    function updateSale(bool saleParam) public onlyOwner {
        blnSale = saleParam;
    }

    function updateWhitelisted(bool whitelistedParam) public onlyOwner {
        blnWhitelisted = whitelistedParam;
    }

    function updateStartindex(uint256 startIndexParam) public onlyOwner {
        startIndex = startIndexParam;
    }

    function updateEndindex(uint256 endIndexParam) public onlyOwner {
        endIndex = endIndexParam;
    }

    function updateBatchMintMaxAmount(uint8 maxParam) public onlyOwner {
        batchMintMaxAmount = maxParam;
    }

    function updateWhiteOneMax(uint8 whiteOneParam) public onlyOwner {
        whiteOneMax = whiteOneParam;
    }

    function updateWhiteTwoMax(uint8 whiteTwoParam) public onlyOwner {
        whiteTwoMax = whiteTwoParam;
    }

    //function updatepreSaleStartTime(uint256 preSaleStartTimeParam) public onlyOwner {
    //    preSaleStartTime = preSaleStartTimeParam;
    //}

    //function updatepreSaleEndTime(uint256 preSaleEndTimeParam) public onlyOwner {
    //    preSaleEndTime = preSaleEndTimeParam;
    //}
	
    function updatewhitelistedAddressesOne(address addressParam) public onlyOwner {
        whitelistedAddressesOne.push(addressParam);
    }

    function updatewhitelistedAddressesTwo(address addressParam) public onlyOwner {
        whitelistedAddressesTwo.push(addressParam);
    }

    function updateownerAddress(address addressParam) public onlyOwner {
        ownerAddress = addressParam;
    }
	
    function fetchwhitelistedAddressesOne() public view returns (address[] memory) {
        return whitelistedAddressesOne;
    }

    function fetchwhitelistedAddressesTwo() public view returns (address[] memory) {
        return whitelistedAddressesTwo;
    }

    function fetchUsedTokenId() public view returns (uint256[] memory) {
        return usedTokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override
        returns (string memory){
            require(_exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
            );
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length >0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }
}