/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/EtheriaWrapper_v1pt0.sol

// Solidity 0.8.7-e28d00a7 optimization 200 (default)

pragma solidity ^0.8.6;







interface Etheria {
    function getOwner(uint8 col, uint8 row) external view returns(address);
    function getOfferers(uint8 col, uint8 row) external view returns (address[] memory);
    function getOffers(uint8 col, uint8 row) external view returns (uint[] memory);  
    function setName(uint8 col, uint8 row, string memory _n) external;
    function setStatus(uint8 col, uint8 row, string memory _s) external payable;
    function makeOffer(uint8 col, uint8 row) external payable;
    function acceptOffer(uint8 col, uint8 row, uint8 index, uint amt) external;
    function deleteOffer(uint8 col, uint8 row, uint8 index, uint amt) external;
}

contract EtheriaWrapper1pt0 is Ownable, ERC721 {

    address public _etheriaAddress;
    Etheria public _etheria;

    mapping (uint256 => address) public wrapInitializers;
   
    constructor() payable ERC721("Etheria Wrapper v1pt0 2015-10-22", "EW10") {
		_etheriaAddress = 0xe414716F017b5c1457bF98e985BCcB135DFf81F2;
		_etheria = Etheria(_etheriaAddress);
        _baseTokenURI = "https://etheria.world/metadata/v1pt0/";
		_baseTokenExtension = ".json";
    }
    
    receive() external payable
    {
        // Only accept from Etheria contract
        require(_msgSender() == _etheriaAddress, "EW10: ETH sender isn't Etheria contract");
    }

    event WrapStarted(address indexed addr, uint256 indexed _locationID);
    event WrapFinished(address indexed addr, uint256 indexed _locationID);
    event Unwrapped(address indexed addr, uint256 indexed _locationID);
    event NameSet(address indexed addr, uint256 indexed _locationID, string name);
    event StatusSet(address indexed addr, uint256 indexed _locationID, string status);
    event OfferRejected(address indexed addr, uint256 indexed _locationID, uint offer, address offerer);
    event OfferRetracted(address indexed addr, uint256 indexed _locationID); // offerer is always address(this) and amount always 0.01 ETH

    function _getIndex(uint8 col, uint8 row) internal pure returns (uint256) {
        require(col <= uint8(32) && row <= uint8(32), "EW10: Invalid col and/or row. Valid range is 0-32"); // uint8 prevents sub-0 automatically
        return (uint256(col) * uint256(33)) + uint256(row);
    }

    // ***** Why are v0.9 and v1.0 wrappable while v1.1 and v1.2 are not? (as of March 2022) *****
    //
    // Etheria was developed long before any NFT exchanges existed. As such, in versions v0.9 and 
    // v1.0, I added internal exchange logic (hereinafter the "offer system") to facilitate trading before abandoning
    // it in favor of a simple "setOwner" function in v1.1 and v1.2.
    // 
    // While this "offer system" was really poorly designed and clunky (the result of a manic episode of moving fast
    // and "testing in production"), it does actually work and work reliably if the proper precautions are taken.
    // 
    // What's more, this "offer system" used msg.sender (v0.9 and v1.0) instead of tx.origin (v1.1 and v1.2) which
    // which means v0.9 and v1.0 tiles are ownable by smart contracts... i.e. they are WRAPPABLE
    //
    // Wrappability means that this terrible "offer system" will be entirely bypassed after wrapping is complete
    // because it's the WRAPPER that is traded, not the base token. The base token is owned by the wrapper smart contract 
    // until unwrap time when the base token is transferred to the new owner.

    // ***** How the "offer system" works in v0.9 and v1.0 ***** (don't use this except to wrap/unwrap)
    //
    // Each v0.9 and v1.0 tile has two arrays: offers[] and offerers[] which can be up to 10 items long.
    // When a new offer comes in, the ETH is stored in the contract and the offers[] and offerers[] arrays are expanded
    // by 1 item to store the bid.
    //
    // The tile owner can then rejectOffer(col, row, offerIndex) or acceptOffer(col, row, offerIndex) to transfer
    // the tile to the successful bidder. 
    
    // ***** How to wrap *****
    //
    // 0. Start with the tile owned by your normal Ethereum account (not a smart contract) and make sure there are no 
    //      unwanted offers in the offer system. Call rejectOffer(col, row) until the arrays are completely empty.
    // 1. Call the wrapper contract's "makeOfferViaWrapper(col,row)" along with 0.01 ETH to force the wrapper to make 
    //      an offer on the base token. Only the tile owner can do this. The wrapper will save the owner's address.
    // 1b. Check the base token's offerer and offerers arrays. They should be 1 item long each, containing 0.01 and the
    //      address of the *wrapper*. Also check wrapInitializer with getWrapInitializer(col,row)
    // 2. Now call acceptOffer(col,row) for your tile on the base contract. Ownership is transferred to the wrapper 
    //      which already has a record of your ownership.
    // 3. Call finishWrap() from previous owner to complete the process.

    // ***** How to unwrap ***** (Note: you probably shouldn't)
    //
    // 0. Start with the tile owned by the wrapper. Call rejectOfferViaWrapper(col, row) to clear out offer arrays.
    // 1. Call makeOffer(col,row) with 0.01 ETH from the destination account. Check the base token's offerer and offerers arrays. 
    //      They should be 1 item long each, containing 0.01 and the address of the destination account.
    // 2. Now call acceptOfferViaWrapper(col,row) for your tile to unwrap the tile to the desired destination.

    // -----------------------------------------------------------------------------------------------------------------

    // External convenience function to let the user check who, if anyone, is the wrapInitializer for this col,row
    //
    function getWrapInitializer(uint8 col, uint8 row) external view returns (address) {
        uint256 _locationID = _getIndex(col, row);
        return wrapInitializers[_locationID];
    }

    // WRAP STEP(S) 0:
    // Reject all standing offers on the base tile you directly own.

    // WRAP STEP 1: 
    // Start the wrapping process by placing an offer on the target tile from the wrapper contract
    // Pre-requisites: 
    //      msg.sender must own the base tile (automatically excludes water, guarantees 721 does not exist)
    //      offer/ers arrays must be empty (all standing offers rejected)
    //      incoming value must be exactly 0.01 ETH
    //              
    function makeOfferViaWrapper(uint8 col, uint8 row) external payable {
        uint256 _locationID = _getIndex(col, row);
        require(_etheria.getOwner(col,row) == msg.sender, "EW10: You must be the tile owner to start the wrapping process.");
        require(_etheria.getOffers(col,row).length == 0, "EW10: The offer/ers arrays for this tile must be empty. Reject all offers.");
        require(msg.value == 10000000000000000, "EW10: You must supply exactly 0.01 ETH to this function.");        
        _etheria.makeOffer{value: msg.value}(col,row);
        // these two are redundant, but w/e
        require(_etheria.getOfferers(col,row)[0] == address(this), "EW10: The offerer in position 0 should be this wrapper address.");
        require(_etheria.getOffers(col,row)[0] == 10000000000000000, "EW10: The offer in position 0 should be 0.01 ETH.");
        wrapInitializers[_locationID] = msg.sender; // doesn't matter if a value already exists in this array
        emit WrapStarted(msg.sender, _locationID);
    }
    // post state: 
    //      Wrapper has placed a 0.01 ETH offer in position 0 of the specified tile that msg.sender owns, 
    //      Wrapper has recorded msg.sender as the wrapInitializer for the specified tile
    //      WrapStarted event fired

    // WRAP STEP 2: 
    // Call etheria.acceptOffer on the offer this wrapper made on the base tile to give the wrapper ownership (in position 0 only!)
    // post state:
    //      Wrapper now owns the tile, the previous owner (paid 0.01 ETH) is still recorded as the wrapInitializer for it. 721 not yet issued.
    //      0.009 and 0.001 ETH have been sent to the base tile owner and Etheria contract creator, respectively, after the "sale"
    //      base tile offer/ers arrays cleared out and refunded, if necessary
    //      Note: There is no event for the offer acceptance on the base tile
    //      Note: You *must* complete the wrapping process in step 3, even if you have changed your mind or want to unwrap.
    //              The wrapper now technically owns the tile and you can't do anything with it until you finishWrap() first.

    // WRAP STEP 3:
    // Finishes the wrapping process by minting the 721 token
    // Pre-requisites:
    //      caller must be the wrapInitializer for this tile
    //      tile must be owned by the wrapper
    //
    function finishWrap(uint8 col, uint8 row) external {
        uint256 _locationID = _getIndex(col, row);
        require(wrapInitializers[_locationID] == msg.sender, "EW10: You are not the wrapInitializer for this tile. Call makeOfferViaWrapper first.");
        require(_etheria.getOwner(col,row) == address(this), "EW10: Tile is not yet owned by this wrapper. Call etheria.acceptOffer to give the wrapper ownership, then finishWrap to complete.");
        _mint(msg.sender, _locationID); // automatically checks to see if token doesn't yet exist
        require(_exists(_locationID), "EW10: 721 was not created as it should have been. Reverting.");
        delete wrapInitializers[_locationID]; // done minting, remove from wrapInitializers array
        require(wrapInitializers[_locationID] == address(0), "EW10: wrapInitializer was not reset to 0. Reverting.");
        emit WrapFinished(msg.sender, _locationID);
    }
    //post state:
    //      721 token created and owned by caller
    //      wrapInitializer for this tile reset to 0
    //      WrapFinished event fired

    // UNWRAP STEP(S) 0 (if necessary):
    // rejectOfferViaWrapper enables the 721-ownerOf (you) to clear out standing offers on the base tile via the wrapper
    //      (since the wrapper technically owns the base tile). W/o this, the tile's 10 offer slots could be DoS-ed with bogus offers
    //      Note: This always rejects the 0 index offer to enforce the condition that our legit unwrapping offer sit
    //      in position 0, the only position where we can guarantee no frontrunning/switcharoo issues
    // Pre-requisites:
    //      The 721 exists for the col,row
    //      There is 1+ offer(s) on the base tile
    //      You own the 721
    //      The wrapper owns the base tile
    //
    function rejectOfferViaWrapper(uint8 col, uint8 row) external { 
        uint256 _locationID = _getIndex(col, row);
        require(_exists(_locationID), "EW10: That 721 does not exist.");
        uint8 offersLength = uint8(_etheria.getOffers(col,row).length); // can't be more than 10
        require(offersLength > 0, "EW10: The offer/ers arrays for this tile must not be empty.");
        address owner = ERC721.ownerOf(_locationID);
        require(owner == msg.sender, "EW10: You must be the 721-ownerOf the tile.");
        require(_etheria.getOwner(col,row) == address(this), "EW10: The wrapper must be the owner of the base tile.");
        address offerer = _etheria.getOfferers(col,row)[0]; // record offerer and offer for event below
        uint offer = _etheria.getOffers(col,row)[0];
        _etheria.deleteOffer(col,row,0,offer); // always rejecting offer at index 0, we don't care about the others
        require(_etheria.getOffers(col,row).length == (offersLength-1), "EW10: Offers array must be 1 less than before. It is not. Reverting.");
        emit OfferRejected(msg.sender, _locationID, offer, offerer); // 721 owner rejected an offer on tile x of amount offer by offerer
    }
    //post state:
    //      One less offer in the base tile's offers array
    //      OfferRejected event fired

    // UNWRAP STEP 1:
    // call etheria.makeOffer with 0.01 ETH from the same account that owns the 721 
    //  then make sure it's the offer sitting in position 0. If it isn't, rejectOfferViaWrapper until it is.

    // UNWRAP STEP 2:
    // Accepts the offer in position 0, the only position we can guarantee won't be switcharooed
    // Pre-requisites:
    //      721 must exist
    //      You must own the 721
    //      offer on base tile in position 0 must be 0.01 ETH from the 721-owner
    //  
    function acceptOfferViaWrapper(uint8 col, uint8 row) external {
        uint256 _locationID = _getIndex(col, row);
        require(_exists(_locationID), "EW10: That 721 does not exist.");
        address owner = ERC721.ownerOf(_locationID);
        require(owner == msg.sender, "EW10: You must be the 721-ownerOf the tile.");
        require(_etheria.getOfferers(col,row)[0] == msg.sender, "EW10: You are not the offerer in position 0.");
        require(_etheria.getOffers(col,row)[0] == 10000000000000000, "EW10: The offer in position 0 is not 0.01 ETH as expected.");
        _etheria.acceptOffer(col, row, 0, 10000000000000000); // 0.001 will be sent to Etheria creator and 0.009 will be sent to this contract
        require(_etheria.getOwner(col,row) == msg.sender, "EW10: You were not made the base tile owner as expected. Reverting.");
        _burn(_locationID);
        require(!_exists(_locationID), "EW10: The 721 was not burned as expected. Reverting.");
        emit Unwrapped(msg.sender, _locationID); // 721 owner unwrapped _locationID
    }
    // post state: 
    //      721 burned, base tile now owned by msg.sender
    //      0.001 sent to Etheria contract creator, 0.009 sent to this wrapper for the "sale" 
    //              Note: This 0.009 ETH is not withdrawable to you due to complexity and gas. Consider it an unwrap fee. :)
    //      Base tile offer/ers arrays cleared out and refunded, if necessary

    // NOTE: retractOfferViaWrapper is absent due to being unnecessary and overly complex. The tile owner can 
    //      always remove any unwanted offers, including any made from this wrapper.
   
    function setNameViaWrapper(uint8 col, uint8 row, string memory _n) external {
        uint256 _locationID = _getIndex(col, row);
        require(_exists(_locationID), "EW10: That 721 does not exist.");
        address owner = ERC721.ownerOf(_locationID);
        require(owner == msg.sender, "EW10: You must be the 721-ownerOf the tile.");
        _etheria.setName(col,row,_n);
        emit NameSet(msg.sender, _locationID, _n); // tile's 721-ownerOf set _locationID's name
    }

    function setStatusViaWrapper(uint8 col, uint8 row, string memory _n) external payable {
        uint256 _locationID = _getIndex(col, row);
        require(_exists(_locationID), "EW10: That 721 does not exist.");
        address owner = ERC721.ownerOf(_locationID);
        require(owner == msg.sender, "EW10: You must be the 721-ownerOf the tile.");
        require(msg.value == 1000000000000000000, "EW10: It costs 1 ETH to change status."); // 1 ETH
        _etheria.setStatus{value: msg.value}(col,row,_n);
        emit StatusSet(msg.sender, _locationID, _n);  // tile's 721-ownerOf set _locationID's status
    }
   
    // In the extremely unlikely event somebody is being stupid and filling all the slots on the tiles AND maliciously 
    // keeping a bot running to continually insert more bogus 0.01 ETH bids into the slots even as the tile owner 
    // rejects them (i.e. a DoS attack meant to prevent un/wrapping), the tile owner can still get their wrapper bid onto 
    // the tile via flashbots or similar (avoiding the mempool): Simply etheria.rejectOffer and wrapper.makeOfferViaWrapper 
    // in back-to-back transactions, then reject offers until the wrapper offer is in slot 0, ready to wrap. (It doesn't 
    // matter if the bot creates 9 more in the remaining slots.) Hence, there is nothing an attacker can do to DoS a tile.

    /**
     * @dev sets base token URI and the token extension...
     */

    string public _baseTokenURI;
    string public _baseTokenExtension; 

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function setTokenExtension(string memory __baseTokenExtension) public onlyOwner {
        _baseTokenExtension = __baseTokenExtension;
    }    
     
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {  // complete URI = base +  token + token extension
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), _baseTokenExtension));
    }

    function empty() external onlyOwner
    {
        // Unwrapping leaves 0.009 ETH on this wrapper each time. Allow creator to retrieve, if it ever becomes 
        // worth the effort. No other money should ever rest on this wrapper, only the base Etheria contract.
	    payable(msg.sender).transfer(address(this).balance); 
    }
}