/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

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
        _requireMinted(tokenId);

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
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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

// File: Caio.sol



pragma solidity >=0.7.0 <0.9.0;












contract CaioVicentino is Context, ERC721URIStorage, ERC721Enumerable, Ownable {
  using Strings for uint256;

  string private baseURI;
  string private baseExtension = ".json";
  string private notRevealedUri = "";
  uint256 private maxSupply = 2000;
  uint256 private maxMintAmount = 1;
  uint256 private FreeMintPerAddressLimit = 1;
  bool private paused = false;
  bool private revealed = false;
  bool private onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) private addressMintedBalance;
  mapping(uint256 => uint) private _availableTokens;
  uint256 private _numAvailableTokens;

  address _contractOwner;
  mapping (address => bool) private _managers;

  mapping (address => bool) private _affiliates;
  bool private _allowAffiliateProgram = true;
  uint private _affiliateProgramPercentage = 15;

  bool private _allowRecommendation = true;
  uint256 private _recommendationPercentage = 10;

  mapping(address => uint256) private _addressLastMintedTokenId;
  uint256 private _deadLine = 1669926880;

  bool private _isFreeMint = false;
  uint256 private _nftEtherValue = 250000000000000000;

  event _transferSend(address _from, address _to, uint _amount);

constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);

    whitelistedAddresses = [
        0x81F10a638289eF66cD784049d901Bb25eE36AFC6,
        0xA7337bd8E6dD5134f3Af68a97C1f73Ca29523C89,
        0x330cb911AdE49B84bB3a7D3cB04334d5c34a771C,
        //0x4fee32a23c8a6e6715017467604ec809c1b662c5,
        0x09Bf493f58C7B2d9E0CA0534d6941A8Fc728E3ac,
        0x6450dA461D027A49C2b30F8cf41Bd72798699A6B,
        0x50BC324249624E152312E7465C435355a1fFBc8D,
        0xF52D03e7a9696f5e090A5b5Dc36Aa2E490aB4434,
        0x1b054F3b45AB48D58282448070861a8B67A0DFd8,
        0xAd8E9e0e87b2E5c2c90ea413ce6600E8B2097eFf,
        0x903D52710222A4d0F622084ed51464e80C32E129,
        0x2637C82c3998648A3909B93C8E0baf84b152E5FF,
        0xFb591314B65eEF7bb1475d03b27ef230f411bfb5,
        0xb61642CDeF7F494c603ACdb94E2617fbF8A1c5F3,
        0x35c9BfECB6a551e182e5Df9743E403Ef15A6E875,
        0x8C18EE90bFF40FDa7a5801B08816658c243186F0,
        0x8C18EE90bFF40FDa7a5801B08816658c243186F0,
        //0x36fb3c8d2174285888a97c6f398a8ba91673eee4,
        0xEe5F9319b41287C84059F79035aE1F4aBDd40887,
        0xFD7208b28F596211F64DF4c06e0b17E37bc690f0,
        0xE70E0a3A6abde3E20B3b2703Fa4aBDffc16634FE,
        0x4477E59250e6565b0DaD0f500bFD6a85238A30b4,
        0xcB1d177d7Cb3A4985CF783FBD6Cc42169f47B272,
        0xaDF6B80B4f6b2BD3a2438FC6d6F11526B02E0eaA,
        0x9a761Cc6331Fd28D0b04811135dfA233f6499C9C,
        0xA95a2e96a7aCc714677bCE90ddEFd257838C7DAE,
        //0xa3a008b6f2bf51d4fc0ab32aa6b2a41c3a179833,
        0xf913d44F4D2000DCeb230f847d3711a7EBc4Ca68,
        0xa4C3C19334a52a451C1173d696F2739Fd8E2eC4F,
        0x08Ea54122C0FF2A76E9bD455762C170Ed27DE8C3,
        0x02c61b0bC7AEC8fa40eF91311c3C923eE6b9E084,
        0x36A2A9B42C807d1b4bF60cD66AA0302677CE7AB1,
        0xDc7F990EC4D2F2470BdeAfcABb9aE2C17Cc11312,
        0xB224614C79cCc0b31dbBfACf4fBcDe178a0D8817,
        0xEffB99fB7e6230A6e898Bc5a2b76bb7dC2bbe83C,
        0x0307cC53D1e6E651Ee3Ebf437Cbe6bd56b394C7a,
        0xb549E6CD740Ab5A37f2D11Af27B66DF5c10f4BFA,
        0x125aD150043F25A8C0A09C8b82Ac2a26EaAC1400,
        0x5996c5e0EaE30D76878AdCa83554de2c2FF68987,
        0xc43e8f1f4E09E0F9958bb296EFB9930A5e74DAdE,
        0x7FCC1DF22ae0925B198Ae5bf1594CEe42EA16781,
        //0x22fc4482844911650d9ded9f05459287e22bd261,
        //0x30D4c032C6e7a1B85fbeA75C3F0b9f540aAC1067,
        //0x63c9a867d704df159bbbb88eeee1609196b1995e,
        //0x62d323aAe31A25e1cf5eDB12e1f32A8f79Fb5701,
        //0x647ad0a3c3a8a3b5ff6570dd99ef222f36e2c140,
        0x660A7093C70e2857E404A5F6B4C774bd7E8d9942,
        0x0bADBdaa62809b75a3A6D19edd7c3cCeCf5cC530,
        0x2aE9E465277155c62782176E4Ffa9821335664D8,
        0x57bA848CD616241607764647CFF6732593c409df,
        0x321392a37400E03083743648D98b9eB6D73A8e7F,
        0x9eD2D17E0c7777768B609a7B5862bb9CBe4De881,
        0x55cc409d435161CAB80eEdC323210c149b94A4A5,
        0x04a3d07F39b643948c39Ad3d3aa24EF03A6B7CFC,
        0x5D972A19197cDF398C9Ee0792C9B294Fe6Ec8CEA,
        0xdc800F118daCeb08cb06Abed3C0811bE7cAE9B14,
        0x3f7ebD27deCBDbf0178fD5a76Fda010EFAc14403,
        0x6EaF5692fF6Af4860604E3C22F76C4a2Baab2ea4,
        0xD8276041B083f8864B6e8953988C44e3921dE2C4,
        //0x21bc24808f3458204ad3f8efaf78a540b76f0007,
        0xc307C0f599721092b9A53AeD9d737dB15d42CaA0,
        0xa380300BE85b84D15e92c1502CD085E4FD382196,
        0xf646d6Aab948baD288bce6924A7B88cAcBE7C5a5,
        0xcAA6F6c65527CD54b89E0D1793BD1E2F67b0e8Fd,
        0x0527fEF489AaaA7ab8550e48bd90b2afBa204A1a,
        //0xc55eac912227ee228e6e63867ea3a2bc9bb3d3f1,
        0xCc512fEd22E36619fAA8E100D8417934319D0EB4,
        0xCb80e7f2d8bEa4B3E4E891a7763ada8834ce7489,
        0x1D12Cb2f83Fc002C1331285bF08B3d11461B98A8,
        0x3ada65250978e00026f5D94CedB4c0892cB5AE06,
        0x8cD3e2f5835bac886b23A1ae074d7d597236181E,
        0xeb135B84BDf44C6105606D78b7b63872F68E8044,
        0x3B330a2Aad9D2E69427044d632a696Dc2Ad7299A,
        0x46ac2a5881A9756A958E563E48385FE13367EdB6,
        0x848f7B971bEBcB660A4C2C071D0fD631E6c60Aca,
        0x848f7B971bEBcB660A4C2C071D0fD631E6c60Aca,
        0x1495dD855f2F4C3A62492742cffE74f8BFbD42fc,
        //0x8edc309dcb114f0f1c06c7dcea8d2965c88d564e,
        0x9083FA9EdDaEAbAfeA9beB7af8E78585Ed4f098F,
        0x9277741535022c7f3488E1c4c9F17Fd6626189fb,
        0xf16247eaEC7517320Ca3121619702c119039EdE5,
        0x354E3E4A33930629e2c491bBAa896128BE12640d,
        0xc9584B94078036ed16E14E872663f3a3827191f8,
        0xDff6320b49b149B3619E2E285266E313cBAdCEb7,
        0xE67BA543F2f5EAF639AeEc136417b892AAE77247,
        0x76D0C82D6ebc00F994e16eD8EDdA8AE6E206E68E,
        0xdA75B96a7b1799cf2691B89077bF4163Efef281B,
        0xd5f95DcE2A052972f5dBAb8699c07A8b9eb26968,
        0x8f0dFfd959dfC45E0220B4c6ADa93A94DD7031CA,
        0xaB34fA3cE1DE38Ae89dB55bd32cc64874d13Ff19,
        0xaB34fA3cE1DE38Ae89dB55bd32cc64874d13Ff19,
        0x2B0B03CcA9198A8ffe85F0EcA321E514bc15A518,
        0x3fE9457922D2e8E1c7C0c379F667C668C6E2189e,
        0x71078b85099187FCa048b37753FFf208e49a4d20,
        0x0250cd163a13b41030bc20D96868d93aCdf51CF8,
        0xE3C84eA82874cE9E02954eEF2119E5298df4e0Ad,
        0x72627E544DFed699441323cEd59dd64c257a8415,
        0x55283d90c9DAE76571a7B5a4B3a78c03EDd6D9B9,
        0x6f1E7C7165cdAD8146FeA8E838fAe6421F548eBa,
        0x6658C279A936Bf73C185864bC1e1Fac61f301DF0,
        0xC846d616680Be2140745A4201F52762969622eA8,
        0x982F43EbB971E6087fDB5b0E9f27d34288750b8F,
        0x982F43EbB971E6087fDB5b0E9f27d34288750b8F,
        0x1e8956830135f274fCC786b0c6F4D5D546810FA4,
        0x85194fFba51D0A3d9b7aBcAe802868F1e03f021C,
        0xdCD88f18ba1c11AE9CE86763cbf6FEB475544790,
        0xe7387b044E872CD1B08D7f02C4CC052747211236,
        0xf8F818438A402B931e4202998a81b2630BfB43A3,
        0xCd90c627206D14416E0AD518fC80089cb206EaEF,
        0x63E0161Fc85BD2640894d17051399fE013362e1E,
        0x01911D3DC3E10fE13e1400e2E8516E8F1d19D51c,
        0x963C32D2e404d062a1305468A52F1c774a9D768E,
        0xC356E8fFEa6c866bE5F293d5FEe3A39c70e4075F,
        0x14196EAbcbB4052D327756ECf85DA8F0dAd08f83,
        0xa806708fFB3CfC1bd9B87766a9Bf8094308ab981,
        0xFd8F16F5f91508aF37b2311324a626DDb5DbABA1,
        0x4F012643Bb7416D8cbA711D7153264e043ed30FA,
        0xfc073e73C0677c1876368fE6Fd64DD98023f1a76,
        0xDE47a1bA1a4Ee603611DEe23539a4B8976ed713C,
        0x4547B89eAEd946e1cF22050522f48B67370728d6,
        0x67AC06BA59551364992f2f72A6e55E6cCFA7E3DD,
        0xB8Bc30Cce75b2AbD93A443382aE9dCDEB803c852,
        0xA8EE3A92Bdf7437485696C13F24f7B6FE1d15cD9,
        //0x45604feac898fffd9120ce1bcac4fa6d7e9e5e8c,
        0x42De8F255C207dC18F0850E1eFb8e1318f667E0D,
        0x6890C938B3a3d460396c257892A1e88021D271BD,
        0x2F419B26514ae7D132293327CFE1Ae12eb4E77C6,
        0xE3346750A5B59b6cbB9102Ff3C05a756C377BE9A,
        0x555323425ec69B204F01F8e30ad42438f614E547,
        0x89d1006F035Bc7d7bfB6DA8D440eE9A6d0eD5B08,
        0xC536145940315B7c2D2e9380b59cAa6d311daEF4,
        0xA27Bfb24F0cA393d3F562fa0B07ef68A7a3e496e,
        0x2e4F6d6B417408Bdac14Ae490A3642C6EcC093Ae,
        //0x4622bef7d6c5f7f1acc479b764688dc3e7316d68,
        0xd2f8d886C19D3bd783a5E311a5035a57b2F6Cf44,
        0x92360Bef03Bb7c6EE017C98eE1AEd5C859965Ff3,
        0x83a416Ad90A8FE242ed495897FD7cb8B5567A318,
        0x09e54215015c0ad924128E90CD625aF0cF3ad38b,
        0xFc9EEC12C7c2584E4F9c88780122380157E3361a,
        0xFEF8283C8225987B8d2Df54423214F4Fe2bF7765,
        0xA2e731DB15098a4aaCef51Cf8b7759094BF1564B,
        0x4208ec246258bec356711FDd8CACCF9A5df63e7E,
        0x32D82825Fe32dDC5E98B85d523d4beab16e5e8f1,
        0xDB19a4F51436835688849A1C6e93852627E109AA,
        0xd87630778D564E2ebD3B3551B026dB1fa29CEcad,
        0xA89C95f3b69c6435fa022fcE66EFa46289E24476,
        0xef1177c6d6A9e1FC0D360289323DB6DE1145A194,
        0xdccDD925271508d24137c084092CC21A5cd59749,
        0xf42351cE647C79aA2d97082daf73D1cc9fE9bF2C,
        0xaF3dB3f25f69cb77414CE6B02E895C3a3698E62d,
        0x06e0AB8EB9cA8cF9D362E9fA090624aAf46291A9,
        0x085F06c6f0ff53eFB1075f76C36BDca95C53C126,
        0x30288DC80ff40b585E28673122B4aDBAFF4c9E6D,
        0x2F6d40D46E8ADF77B45b29CB655bCe4Ec59B3AE8,
        0x254C19b280A5A938186B7066B5d47464CBBC1C80,
        0xdc9ed7193b2516C84cB73f7F076426165c0ab459,
        0xf9fc19e7F3b429ba634FA6FF250EfdefD20AeF65,
        0x27ac31c7b573df4015827133C1fc414549EC8A64,
        0x9653DFECF88d8E393f0E3e94D2aDd28fa45Ac462,
        //0x0170d825f624c26adb89344a9fb59169e3fa2d4f,
        0x581896bcEE77DE0028D3EF6dA37FDdC496b380eb,
        0xC9Ee3563face2B242a24A5326F1596b30875f77C,
        0x1C3f7eEE6De019E85F4dc09C4ca501141af6c13c,
        0xb6F33C2586b75B6F01eB0aF65349cd9ce5a4c482,
        0x8D0080e604FB1bA7A13c071F4BF5e1C0c60946a7,
        0x09Bf493f58C7B2d9E0CA0534d6941A8Fc728E3ac,
        0xE0086584d67Fc3eA73555f1D84C8ea8AD60Df6F2,
        0x35fE35665c705f95A750B8596716652b44792AAb,
        0xDD3Fdd44626698b0B1179Edd6930d2790CEE64B3,
        0x3731584c211f23F9574D5b2107DF3C75268F3B67,
        0xfA308d2800259714CeB69bb12F6cCEEA12b5752A,
        0xB7660d122bF4834A7156D3486b7a1c664B73977C,
        0x05edbCd3645f4844938A99756B1343d37F63947b,
        0x84aae58431D783E7976D2a994a03d35c9a28C5cA,
        0x9537700CdcF6023b9175A1B185F1Ec6dfC8Cfc95,
        0x7325c2900d7620D173458241b8dE5444fe58Db50,
        0x46D95954dD98B03820c69a7e85E1631A2d3f0425,
        0xeB3688a6cF5f25Dbc6F3be4e8a38eF6cE5F8a64c,
        0x0619FC41C9990E95AFc140e459A3dD0dFA5f40D8,
        0x588f12F97f4E97D26d309309AE0Fe96412627C2c,
        0x25c0Eb04eC90E79c983C60fAF9933a90E05e7A30,
        0xBeb6efc0D779EfaE8735f6c7ABB79f01107FA4cf,
        0xC9a737b5389F157aA1251953D77fb16e9c2Cf0c6,
        0xA88917860A99f54E357b077680158f0Fe8E12d26,
        0xF7Ce845FE195E892760388912403Df5039Efb75a,
        //0xfF17Eeb739E9Aeee448A7FC601fCa09498832eda,
        0x28d5Feffd8883079E615DF1e1E68DA73f9EeA8cB,
        0xf2F7B38dC62175F143e75f70aB3A760268AF8D74,
        0xe4f2558d5F0BF5119Ef67967d5F42DEaaA94FE6F,
        0x66B33937624Cb80329BCE31F5b3E734fd73b79b5,
        0xC5470eb81b520b42fd026Fb481bF1FA996DCA006,
        0xcae07dF74E103700e6Fe2FDee3E8A9CE6836EBdd,
        0x7707a6dC67444927140A9e3d01779f58997f4ce3,
        0x608041a806688da55Fb6ff92c4418eD878788ff2,
        0xa878B20383eFC0ae170399e5e0ef28A27418cfe3,
        0x31c7491950c769C7E376Eb395d042D1d4FdC704E,
        0x0634288c1b2F524667c26F273FEA56Be120Be740,
        0xe18Bcc7c71b898C587483c3D64F1729d997C2f8D,
        0x91688C607887AEA2C4EC46A832052936Fb4c1bEF,
        0x9E3e9706331CC0c0FEC1F185aFb0660c581c85e7,
        0x0D8a29852A4D4aC35E4cd4EE0FBcdEb947846252,
        0x1014380e4790951D41bed27478141c29fc31200d,
        0xD1f5067Ffb98BbD1ebb624E946D12Cfd42695F0b,
        0x2830F76F087Af61E54E0000018e1573823FEda6c,
        0x3584636171540C6136295f55C6E207Bd144D496D,
        0xA9f769B32323041850Bd6A8a79c1C3ED8eCdB34d,
        0xA8f7C289fe5956547F59f47B3612Bda581112d4e,
        0x54Bf88e4CD31FA9872545f0d069cB47d4648dC9E,
        //0x3df4e2989fb05dd39541087c4dd34b5557412611,
        0x9700E9b9B1ae81A59c871BfE6A4d83F0E5056e1B,
        0xeA2Bf14dAA8b854718c47e4984637b4D7D3A9c86,
        0x5367Ff3529C8c7319C3d62D480741878E18367f4,
        0xDff6320b49b149B3619E2E285266E313cBAdCEb7,
        0x614A8244B356a4D94F88E39486C12ad1aC22E4C5,
        0x682434353e84C9A4dC03bab4c1a0dE25962BF3a7,
        0xFEF8283C8225987B8d2Df54423214F4Fe2bF7765,
        0x8cD3e2f5835bac886b23A1ae074d7d597236181E,
        0xe4723d74171551De943bC26Ba637811c74b75075,
        0x3f8524f494CEC3d0d0F2Fdc8EB464D26921C784E,
        0xE9f716dfDa69F5808bD2f1b0e7b30c9a017627e8,
        0xEF1cc55D98dbe2a517dBe990C4ec9C6806186f90,
        0x5E9622b1957510769F59Fe45A2e9Db8965442279,
        0xC7f72b26a69F52a4A0c7455DcDE5E25291202831,
        0xF966c3B273801F058a30D75489d4c98c336F928E,
        0x3f5247Fd57BF5502142DC4941ea34FdD31D63A3c,
        //0x40a4fce89b26e924a3b5f13a91e78a5dc4944a45,
        0xf1A352A0047149a84E7978d83db172884eaee72d,
        0xB7f78DC6fE0cdcEcd2FcFEFE21A4fB39E70ec94B,
        0xbf1633db9da394d774c87479C0cd1c2c67F79532,
        0x639F6C7C9Cc6B7B80B2e063eB84c81FE136E3694,
        0x612aB532BEdebd21C56Fea036490402397Ad2981,
        0xbEc143e7dBA00d8CFd9bE25D89CA3020978d7AE9,
        0x34e116f1b2A72c34a51A9a0579C52DcE8d2A1403,
        0x818A984Cb26eD5686316048ACb03Be60a232E68A,
        0x598BE9c9dE342450B7f81a6Ea5cA6CB8db5Fa807,
        0x31F6F21a2Ced7ba4965f49e04ADc0Fa2C2fcfbAA,
        0xD323EdFe73A6a57dE58B2A15eDa830F9f43beA69,
        0x0dDee713865872b809DC525B332Ca1cbAB323d14,
        0x94C4a3E8bfa74594249A8df7F0558Ce248c89bd5,
        0x53449Be5bE745Ac9812eedAf91d91C9c4c60d17D,
        0x2fabB7aCD046Fa1a560586132B5A19A131d0AD3F,
        0xB9EeDb6F53A4f20309CbF465F49572f22536c158,
        0x31eF6d19b6D94B95C0e343bC154f9700407cFf6D,
        0x4F012643Bb7416D8cbA711D7153264e043ed30FA,
        0xFb762e280505c541e843753da648390376FD2E08,
        0xFb762e280505c541e843753da648390376FD2E08,
        0x9E00FFDa4b57ed3a4f55037aeBc0eCdd7aB59b9b,
        0xD1dd101bB3429D0984FAEEe197E339D1c7318FF1,
        0x76c97c86Dd77a420e0e43BFE7fb55846aCEb403C,
        0xaA3115Affba967D35783a07E3952e39c27A88B2E,
        0x2e12466d66fBc2CF1dD718Dd1d6426D4889f33b3,
        0x409B6F4709E83C527748c4b931eb050FceE1EC55,
        0x8Ad95129FE55F7FB2d270081D6fE9C5e3e3aC03d,
        0x8585845383c370AF5d415f0680Fd80D81Ee27295,
        0x55769d0411006BD2e5ec13b0Fa4B25aBbFf1Cf79,
        0xB39053b5455520e1990550aEB90da91AAdBb66c5,
        0x2133759FEbA9f44971E3F87482c218A6d203ff53,
        0x52Af2C5C256Fd5c17186b27f16482179C5d4045C,
        0x52Af2C5C256Fd5c17186b27f16482179C5d4045C,
        0x79dFD4b5c46E9de1eBA8799cfDd340aa09A52C9D,
        0x8e4a055A4951990f38B9CBA94e9eA07234b32d31,
        0xfaeaE16DF9D4FbF2C0Fba2ADdd73d82CB2226528,
        0x6eF9eA526B6Bd64167E546A26467D7fA9894E77a,
        0xc9ce9AF79a771d69041a8ca49A7e84aB229eE165,
        0xd6F09D04c69e2390A5A955677e6d2f1B7cC47568,
        0x1A5bA50a154471b8CA1063cd46A3a2AEe60CFfB7,
        0x91c5039a92ae137D40CEAa901F364aD50027Caf7,
        0x42DDf6DDe56a5BcD90B670213D067989156aa477,
        0xA95a2e96a7aCc714677bCE90ddEFd257838C7DAE,
        0xE43ef627A3381D0F200fA64B7bB6014ed7df5645,
        0x60085E00da5Bf19976Ac4B854517e714Bf92fd5f,
        0x4208ec246258bec356711FDd8CACCF9A5df63e7E,
        0x75e34C6A1964aa3eBfF2e9E6DAC12E44cDCAFE75,
        0x1D12Cb2f83Fc002C1331285bF08B3d11461B98A8,
        0xD5BcEf68325097D597a1fc879a074aC6a51bB007,
        0xDB19a4F51436835688849A1C6e93852627E109AA,
        0x2CEc17bD69Bb44463744dD8a732E954B478E9b10,
        0x50877B3F45413CB122AC973af1B01b9c927cb535,
        0x3142E5eA6300184576e82bB68C9d3Cb016E5022a,
        0x436CA1Ee1D5B54db97a5D6cab88B517ce7350cE4,
        //0x09aae7650feda7654a31b664afadb0cd5c531821,
        0xEbE0D5f66Df52A32aB8B2cCF8D2e275449693f70,
        0xB7E694fE4B89D51ec3ddE0E32aFCb96052CDFf68,
        0x1495dD855f2F4C3A62492742cffE74f8BFbD42fc,
        0xa4169B535607e347a6807D8Cf7276E03e2043d78,
        0xcB31A25c00aA6f683DA772Dc513412B2E6622728,
        0x1e98EFA54EcC646f00C56128748036291b80B877,
        0x41a21D07B6d44AA7A69936b263B15AB313430e88,
        0x40dba13952aEB3EC8cE78571838C9fbCe4519131,
        0x40dba13952aEB3EC8cE78571838C9fbCe4519131,
        0xa511fe8801A6F9e13e02Fa9dE3263D3CBAafa05f,
        0x1106e81DD949E62A0A33929dAeE8401CCe1e5AeD
        ];

        _contractOwner = msg.sender;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
      super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  //################################ SET FUNCTIONS #########################################################
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
   baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function reveal(bool _state, string memory _newBaseURI) public onlyOwner {
      revealed = _state;
      baseURI = _newBaseURI;
  }

  function setFreeMintPerAddressLimit(uint256 _limit) public onlyOwner {
    FreeMintPerAddressLimit = _limit;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

   function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setAllowAffiliateProgram(bool _state) public onlyOwner {
     _allowAffiliateProgram = _state;
  }

  function setAffiliateProgramPercentage(uint256 percentage) public onlyOwner {
    _affiliateProgramPercentage = percentage;
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
     maxSupply = _maxSupply;
  }

  function setWhitelistedAddress(address _wallet) public onlyOwner {
    whitelistedAddresses.push(_wallet);
  }

  function setNftEtherValue(uint256 nftEtherValue) public onlyOwner {
    _nftEtherValue = nftEtherValue;
  }

  function setDeadLine(uint256 _newDeadLine) public onlyOwner {
     _deadLine = _newDeadLine;
  }

  function setAffiliate(address manager, bool state) public onlyOwner {
    _affiliates[manager] = state;
  }

  function setIsFreeMint(bool state) public onlyOwner {
      _isFreeMint = state;
  }

  // function removeWhitelistedAddress(address _user) public onlyOwner {
  //   for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
  //     if (whitelistedAddresses[i] == _user) {
  //         delete whitelistedAddresses[i];
  //     }
  //   }
  // }

  //################################ GET FUNCTIONS #########################################################
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
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

  function getRandomAvailableTokenId(address payable to, uint256 updatedNumAvailableTokens)
        public payable
        returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    0,
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    function getAvailableTokenAtIndex(uint256 indexToUse, uint256 updatedNumAvailableTokens)
        internal
        returns (uint256)
    {
        if (indexToUse == 0) {
            indexToUse++;
        }
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }

        uint256 lastIndex = updatedNumAvailableTokens;
        if (indexToUse != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
                delete _availableTokens[lastIndex];
            }
        }

        return result;
    }

    function getQtdAvailableTokens() public view returns (uint256) {
      if(_numAvailableTokens > 0){
        return _numAvailableTokens;
      }
      return maxSupply;
    }

    function getMaxSupply() public view returns (uint) {
      return maxSupply;
    }

    function getDeadLine() public view returns (uint256) {
      return _deadLine;
    }

    function getNftEtherValue() public view returns (uint) {
      return _nftEtherValue;
    }

    function getAddressLastMintedTokenId(address wallet) public view returns (uint256) {
      return _addressLastMintedTokenId[wallet];
    }

    function getMaxMintAmount() public view returns (uint256) {
      return maxMintAmount;
    }

    function getBalance() public view returns (uint) {
     return msg.sender.balance;
    }

    function isAffliliated(address wallet) public view returns (bool) {
     return _affiliates[wallet];
    }

    function contractIsFreeMint() public view returns (bool) {
     return _isFreeMint;
    }

    // function getAllowAffiliateProgram() public view returns (bool) {
    //  return _allowAffiliateProgram;
    // }

    function isPaused() public view returns (bool) {
      return paused;
    }

   function isOnlyWhitelist() public view returns (bool) {
     return onlyWhitelisted;
   }

  //######################################## MINT FUNCTION ###################################################
  function mint(
    uint256 _mintAmount,
    address payable _recommendedBy,
    uint256 _indicationType, //1=directlink, 2=affiliate, 3=recomendation
    address payable endUser
    ) public payable {
    require(!paused, "o contrato pausado");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "precisa mintar pelo menos 1 NFT");
    require(_mintAmount + balanceOf(endUser) <= maxMintAmount, "quantidade limite de mint por carteira excedida");
    require(supply + _mintAmount <= maxSupply, "quantidade limite de NFT excedida");

    if(_deadLine > 0){
      require(_deadLine > block.timestamp, "esta mintagem se encontra encerrada");
    }

    if(onlyWhitelisted){
      require(isWhitelisted(endUser), "mint aberto apenas para carteiras na whitelist");
    }

    if(_indicationType == 2){
        require(_allowAffiliateProgram, "no momento o programa de afiliados se encontra desativado");
    }

    if(!_isFreeMint ){
      if(!isWhitelisted(endUser)){
        split(_mintAmount, _recommendedBy, _indicationType);
      } else {
        uint256[] memory tokensIds = walletOfOwner(endUser);
        if( tokensIds.length > 0 ){
          split(_mintAmount, _recommendedBy, _indicationType);
        }
      }
    }

    uint256 updatedNumAvailableTokens = maxSupply - totalSupply();
    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 tokenId = getRandomAvailableTokenId(payable(endUser), updatedNumAvailableTokens);

      addressMintedBalance[endUser]++;

      _safeMint(endUser, tokenId);
      _setTokenURI(tokenId, string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension)));

      --updatedNumAvailableTokens;

      _addressLastMintedTokenId[endUser] = tokenId;
    }
    _numAvailableTokens = updatedNumAvailableTokens;
  }

 function split(uint256 _mintAmount, address payable _recommendedBy, uint256 _indicationType ) public payable{
    require(msg.value >= (_nftEtherValue * _mintAmount), "valor da mintagem diferente do valor definido no contrato");

    uint ownerAmount = msg.value;

    if(_indicationType > 1){

      uint256 _splitPercentage = _recommendationPercentage;
       if(_indicationType == 2 && _allowAffiliateProgram){
          if( _affiliates[_recommendedBy] ){
            _splitPercentage = _affiliateProgramPercentage;
          }
       }

      uint256 amount = msg.value * _splitPercentage / 100;
      ownerAmount = msg.value - amount;

      emit _transferSend(msg.sender, _recommendedBy, amount);
      _recommendedBy.transfer(amount);
    }
    payable(_contractOwner).transfer(ownerAmount);
  }
}