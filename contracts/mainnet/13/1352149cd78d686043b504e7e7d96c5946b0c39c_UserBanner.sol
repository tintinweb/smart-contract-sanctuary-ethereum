/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity >=0.4.16 <0.9.0;
pragma solidity >=0.8.0;


//a
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

//a
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

//a
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

//a
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

//a
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

//a
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

//a
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

//a
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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

//a
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

//a
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)
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

//a
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)
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

//a
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)
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

//a
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

//Copyleft (ɔ) Remilia Corporation All Rights Reversed
// pragma solidity >=0.4.16 <0.9.0;
contract UserBanner is ERC721Enumerable, Ownable {

	string private __baseURI;
	function _baseURI() internal view virtual override returns (string memory) {
		return __baseURI;
	}
	function _setBaseURI(string memory baseURI_) internal virtual {
		__baseURI = baseURI_;
	}
	function setBaseURI(string memory baseURI) public onlyOwner {
		_setBaseURI(baseURI);
	}

	string private __contractURI;
	function _contractURI() internal view virtual returns (string memory) {
		return __contractURI;
	}
	function _setContractURI(string memory contractURI_) internal virtual {
		__contractURI = contractURI_;
	}
	function setContractURI(string memory contractURI) public onlyOwner {
		_setContractURI(contractURI);
	}

	bool private started = false;

	uint256 private mask = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;

	uint8[] private shift = [
		8 * 0,
		8 * 8,
		8 * 16,
		8 * 24
	];

	// Hardcode into a literal in one tx if possible?
	uint256[] private packed = [
0x04be77ffb3b583ecac0440bcee416b402c665357240f594ef11d0afa4d5ea90a,
0xb44d47e48cf746aa687ebad194fd537f6e00582a982f68fe8fd4cc402d935e7d,
0xe8756b20ee12500070bf378e8b131acfd380c6871b01080854c94941deed9348,
0x294de76fe57ed3692e92b0c507d2b3186f1ccd7be18763ffb9eeb63a217fcfa3,
0x13a207198643788a7e0735cbacdf8e321629d9fe7775b800d8906fc10c34d04f,
0x18aa4c810bf69d5232c48f10a174933ed3fce20f49b4150e0cdaa625c03ade56,
0x899e3505a0a21e6e1d610c786805a2deb929a2520e385c8215d0511870299bc0,
0x04a1bfbf6e495b4cb460e0e7c8ffafc27da72beb828d052777c469bc152e3d58,
0x1702e7463c5a6f6efd2be02625980700a9e266a085531d7c8918dc42a9db48aa,
0x32ca05b629a946d9c74da6951b8e50390ac8b549eb0f7713da966f2234bfa9d2,
0x29a538fc3566a2e52ef9a1286ae559fd9197f14fa796fcf5f9f9f06534307a2d,
0x118292dd9689d3ae30e4f2891b2b91d15be9508abdba84aa4e4db4a498a35872,
0x9a4f432accee31b49419c2d676f2a616e1af8e50e421acc2bfa434a4cc261d4e,
0xff54643a595176e5b4d09066f2e9448921b23e129b46809c17062ffb6a16b9d8,
0x959ef3c047c7ed15424625b600ab25caadbe595ef6ffa080a8a5a9a9feece114,
0x7b317f7fff5d2e87ce57f4d98505ead7d961287ff800f7e0be20dae2db14c771,
0x176f70d7ebab8cf701e30b141b03e11f2cfe60e773472869c0ac1a8055f2edf6,
0x88087ee12d44dcc8e17afe3a01faeffdb7e13679db6c5e6cb3fc2c3cec4ce000,
0x90f7cef591e2be88258b5a62fe2ca3d026f049aa5cf0afa4772cd7dd3cc7803f,
0x8958e45cb6b054b7dfa9d4a4ee7b2748aa26de213f1507043f21a086bae913f0,
0x11c7b7993a4612ebf77877742ddde051ad367394bfff2fe4cc14a6ddc29881b1,
0x328ca458b055f179d5640a5d594550f5624f58087c7f388fc3f465db8f82490d,
0xcdeac38b1f3501362d894db5c48b757a7c00c6f7e2d82cee2ed0b13cc0da4ed2,
0xa5e4a8d3a128d3a0ca2561adbf6a1c5946ed02eaea7f87fd9b989ab1be63197c,
0x92f594b6f0d8f9d0b665e430252c8132f28de6003d3dbadb02e7427105643f63,
0xdcd892515e9ca13fb022c5b9786efd8f660404273f7cd6880e611007d66125d5,
0xa9b054a1fb2a6c30d0d805e8270ffe4fdaa2a2a8092dd036c73609b01ea3dad8,
0x141a92c3bfe19293af0487bf705ab0999bcc4d23c0838d35f700a0ac7074fa58,
0x4661878caa6683a2843d0a9ec553aaa7eba108693d1506b05a76a2c25c9a17a9,
0xa14c9c8ff481b61b8a36ffd8c12b32f1b06c2b48f0ff95645117abe91f10dd0f,
0x58b968aaac0a86ed5e28a0bbdb0d58931d12c4864722875cb39648b12ebe70c6,
0x5d9a1ab8ad5b2f2868791f489057cc002725ac1b70517a567f5e24148c9c2658,
0x57322c951150da21a5338c1be0f6f6504906157ec5e28b06aa68185aaae74d24,
0xc1e83888bcc03dff64089c2d1140fae30c3846909ac3e65c8f091d276ba04957,
0xa796916ba29c32d8eb0615e2383e2f96a10817ff22bfa2583a0f40a0c1a35833,
0xafd224b226d177e486922a949cd01cbd5ad7c52ac8b548f74a931babf7241af9,
0x0215781b6f2a11cce450d68d971f77f983d2848638a0d7a4dbaa3c0239071687,
0x8ae79744863fc03319e8ca4a9db3bf1ad007c2fcb7724e54bf0c009cf47e7f5e,
0x87d1347b33d87776863b1e9738d68a9ebe89f8e5c055e84e5da01d183c0cd0c7,
0x470db727b4735c8128672fdf5f5cd0703c8aa700e552f99f1ffc2520157dcf66,
0x43c60c167967bbc4e4651f4c8643f2347ce1544e21c7a29f6b970e0e6fae26fb,
0x96e0ee7d32cfb27964495d2a6f2e20924e424c94aa952dca072f3e10553e26f7,
0xff9bbbad1bf7f84ccc18c954ae185b0e807195e13841d98aa65db70b28e2fda3,
0x53c2b899901d423b63231c77ade93c082f35056627ddbd562bc87c38d5335edd,
0x5aeeb37303c0a22a16de8e81c65a85744f0d99ab401f630fc8faef643c046508,
0x7331b5e622816cc8e8560dc53aad39181476f1a3e0227146998bf63ad4882cee,
0xb6c8d73f865189d4c1e3ec08a82e6c2236c8dc9508df73f9d07a0c9c0ab1a192,
0xbc57456309fe15220990768d44b70b1de695c38186d7c7019d09342155bc1dbd,
0x76fb44cf214939edea00027097d030000700b7df6169a95ab5d5be1158cb6868,
0xa4ea58956359ed832a63a107d45947443d02d1cb650d883a9642c81140834774,
0x825357201726d3d250802f64e6038c82649e584de032e1d15e2c50485fe8efd1,
0x3ecf8db364f8dc6d5044437b038f0a70b3bdf992cb9e8b92b0b1fb177d317ecb,
0xdc31c0e36406c0170d8aa00d2834ddf65448a9795c40e69a617747ad2a35b31e,
0xce66145d8cdc091745409b41fcbe151f0f9fa555c9009c068dc0be3b6e88705e,
0x002e9e50ca5082785a722391417d930789cd88be9e1bdfe96066e877d0f2c404,
0x7a00ae177ba4a64cc8555c1e903ea8eae575b3f250cd1855e3616e9f5e2e0b51,
0x886f5a4bc8b62135753fc2961e085b2eee0a6c02f9dc0393b1a0ab3b167841ea,
0xeec6be570c6603221b356b325f0eb4748fff64ab20e78c1630ec5686e64d205e,
0xa86b97013fb2fa9c1538c1fcee6d0d37e1c1072f49d44800d3a925dd1127e4ff,
0x43301bbd24a5d8d2a164f0378f9e8ba599ed7c216b6e77ddee17d4f65e927564,
0x585aef9cb4c3d4d96affe4dfb79261f6edd16588627110ad3318d9c542b2e5a5,
0x7b601996d5ea69b7c86bf1cec2ad432bbb4de4d83d0515263e837c9f32f6e288,
0x907763608d00f490d8b86d6f6b23c18b6350114ba9a9498397cb3370863492db,
0x25887707b541065020bec3326120a492217393c82f3f3e2743abf4fc393e044b,
0x9770ec070bac9a571344524e2d2d28e5051b71721542b630092a870c71ddb428,
0x886d86ead4d0fa677014778b178e47f1cb6abefb9a2c3a18c4c929f864714926,
0xb43e9322c3d43a7ade6f1ab2a2c4c2aa265950d3362854a61bfde6e3eb64420e,
0x15c6a7ad98e0efd2b34096fe7507efa30901c7d98061cf16d47dbfb8a275e153,
0x362361397c18d0cb50357736eccf985672877019500b7a2c067451536dd5de70,
0x8042b309510da3c7b2df4d6582451ed70a6c0e6ee1d4cb3d7508b0ba022c998f,
0x186b7b7a9e73bf7acd49a76c6d7cdf0a63fb3c104c89ecf492f91d9b729face2,
0x0777c99f6e1222cbeac663f8c255e70c86e1fb5afe75c46c5eafee36f14b9cd2,
0x4e811712dcbdd9c28479512853da60a84a07d947c48823e34318838de747867a,
0x4fefe07dfaf71184a8118b3603c55c79510fdc97c8da3b95d90610e9ea91dda3,
0x36f1ab34ecc8f27df3df8341faa1373f3420fd66ab5aec95dfa6ddfe4254cf69,
0x64cb7106b7aaab9c721b9fe7e26f5e268e5c98eb39d87fe5da6eff9d38b9bd7d,
0x37ecf0856c6f0c3dddb12874324be8acdc00b9f367d5b0732fb5b6f8bd77f3bd,
0x84e3d8567460202d9b72ac7253c62f2873c880d3b353c78559cdebcaef4de5a4,
0xd3a853ff02d390a35b18c6794cd8d8e154755ddcf7db4dfa1069c3305a0a149a,
0x79f39651e25b0a00576d589c2504de733fe7fce25d3761d22c59a5b948f5a84f,
0x470010764c8697d6d3e09245d864cf864c56492336367dcb89ea7715849bd724,
0x294dfe83ac364721aeda66b4ac6382fc688cb30e0535fbedfad3e8484fdbc217,
0x2f611477f0a3b1adfca2855fb6b2533f46651e8c42c35f09f08162df327f5d8a,
0xee750252f9f77209bc020e1b025bee018ab640700e4be4065147e481fab90420,
0x5f5a6203eb57c4517f6fef7fa7ebb5f1ff6824250a0ccfecf2207c07eaeff002,
0xfbfac2ea2255749c90facf5a4bb4d0c4f194acdb9a24d38dfb84fcd9f9f995cb,
0x3470eaecceede93fec9a7925aeff6c7bfa7750143fb88a314984a7dc8ca5d0b7,
0xab1b1b80853e36344a3c2c9e90a816367ef96297ef0117874a85be3241833d2b,
0x168eaf67d67741cbfd27b6119c7b1918c51250b7bb80f4f7132178e210e8db42,
0x2ee15d10e05e814b0d1bfb1e6f855a20797b21f36b265ac3984c2bb0db53cf47,
0xff9bb89e36232b0917c0948cbe2119ef1f83bf43c406bd4bd50c7364aa2ffc69,
0x60e3a8372c103f6070dfe8b56edee9421d2678792bff5e2e98b6a5fc3c9c29e9,
0x63aa95a559042526a0a4de1c48b04c52691c2c993eec2da8d3ddeb6d6ba6ac2f,
0x9960adc80296299a9845d8b0c6ea4147f9204ec1b0494ee3fc56cf9a2d1c8af7,
0xcf853f64c98d6cc8df3777bd1f6e1757bd2183c4f0b9cd972ca789b48e58bafb,
0xc9a93548f7e4d2812f0ef02bb43adab46873af9e61c47dff1a9846a5ed8c73ee,
0xaa8836a2cbd19c9bf84fba0bc1b899a4c49ce020d84c742b409fa47362ed17fe,
0x4bbf661d20ff3459f7d4ea87ed936287bcbc69cabaf1606afb02a61503311be9,
0xf079ed44f181df4a4e42803eafd303aa6c491c30b6357fc5aa692b4c6623fb5f,
0x585ab73d452acb1ccffd080d9b11b29e2bc8aa153a9aa5da9b5271ad34782639,
0x1500a528cb9793ed6afa1c3122272969a3d8f91a170b5b8e5e296e2c0c2e036b,
0x8c2ce7025bd14759aef8849e596b5f703f0b4e761d20f63d5a0a00e14744d0bb,
0xfddaca5119c388b8345c0f107ffa8abdb9eab28f74649c8a45e967138df23f00,
0xa6d3a660e263430c207ae2a3cd761e8e26d82758eb1767fb8f3263fd3247457d,
0x58f213356ad292e094907fc896072ec911032994f815b1f81bd49e537b65ec3d,
0xc11d5a8ed6241dec861dc6ee230d61b3586210f1864c19966f177679a4d99601,
0xed6fe6a6efaf6435700de61a8ffdd74a461d22ce898be7eaf3e4e34520ef9ba1,
0xaf9d6a25e0f5c7d19c59220f38f5991b9cb1cf84bb32cbeebbba808f20cc9d95,
0x9e3ae79f4016e92a4f3fffd8f60a4950b0eb7144da5d3a60a3c2cb704eb88085,
0x03f3b824e6395fc18a43a864d919ce542de6f9e399eac20ed2bdfd6bbef71ca3,
0x1efb47f894d46c4cb3ff252c15b5870f27b3fab8fa8c4f63685fded90292eb48,
0x839c20e7f5456081e57047c9d0511afab3ca9be636297e1d201e7c2f4901a408,
0xfe67de0a5b9bb160252951c62ea94022d98e79ab424171f1d7caf0c523b38831,
0x5204a4b36685e5c8c32b942c0c608e1fd6cb0a4f69b901226a791c2326e628a7,
0xd3de76a13e15306debd1859b666ee9ce40db99474da72997801ace766a8e91d7,
0xe7fcc6c56396a4f994060430cca101be622aff1216fc2697f1a78afebbaf7f96,
0xa8e6e754819120dcd3fc572bdd4c99dc503945148b1be5547dac5a8fc09e5df4,
0xaba34bb49d7b199e1a7cb27aaf853e22b76bc1f84e9c872cac09171d3f93212d,
0x0799454cff074980028df79c0e0602d0e5b2c1f756d120cde11e9ce70244544b,
0x627dce90aa307410d06f136e0bc24aad951d20df731131cf3db3b69b6c0a9536,
0x1983801ba37050f6597f8e6d211fc22420a564e497d6e28a3ffef74d3129feee,
0x0324b227ea06eda68b262bcbece666e032fd18d46178a90c87b6316629fc6bf6,
0x9cd4f5444a7b9f8e0c41f86e3cd95e35c4727e0ac3412be024fc61a8c49ec811,
0xcd002b7433404c3238f0ccb8e08c9cfbd64b1412553a9904904ad9212d042d27,
0xa98f7096a271189ba30b6e6ba14c59100af772651251da9f92a807f356075006,
0x71145a097b4dd01abd6a67c71876aa7d0f15e8f7ec4eb4d972ce6caf0f785522,
0xdcf3955d44e35a1d7828bf2c69036ddff96ee14ba2123896446274ee303e7db5,
0x8cfa67b8f6a3881be62858703bd677f5c6dc4065910a301271246721d7efa1a4,
0x7c9357e34a5051d25557967408fc18f72c1c162cd3a04f0081c8d132f1658261,
0x8de98473c53b6a2d2387e8e0442de22cca664bb39731ffdbca66de26cf6e756c,
0x5ad4de50be0280fba179c33bd3bcc78800be37bef0d1c3e807e2d1e1c8769ea6,
0xc8137a1dfefa5bc82ef003df31788decc71a4b7756bc4dbc0c3eae84ccec8358,
0x7c61481e97e73979c98afc1fce12be715db85011e7ff9797dde82ae46d7503ff,
0x6f3e81e643ac1dcbe0c2d516c10f2f50c098c1635124a3f1408340e784d72ae1,
0xf9ac78230e8df93f3b0559df1dbbc92cdf8586032d9961c634cf14d01d8b7472,
0xb0ac91b9a32c7e83dfb67cd13e247881623457a4ea38ca6ddec4098d005c6606,
0x09bb765f14bb1f2031f21d49be17973242df35840f95e648c8963497f6760472,
0x3ca033acf8df846f851d67dffd9170511e424e9d15fe1f8c75ce3e991ffdb436,
0x04b4ddf11bf43a9447cd54be3041e6949c27434e8702194cd5bf8e65c27d1267,
0xffd2e192c08769b88752873fda063b40b16e2b28dd16c55448c8550d6be2057d,
0x85d19706a9090dcc1700641e0e6c944de2d8e1f19f1b640ee89e7d0a3c7480e7,
0xd28f3d4d19e2ad05ef2d263acf3108a80e5a0d8456bd47b3ad933cea8ca6c3d9,
0xb0ea8e62c85d3bd3af5e59e6576a07d41912ac74ef37edb752b878d7583d8523,
0x6d034705ffb7c3c53277851b01d9943a40ab79e48bb3fa7c5dda090298f3bf19,
0x741fe78dafc83388b4b19a17b0847ddf5a041400bf15f21a9ab14ce370431e76,
0x210ccae4003f10dec5b07c8bed18c872f6b5900daf5cb5760e8ca4c81a311a63,
0x4f8e554625330f5511152ca3a5cb8756524be7fcb371f2dad6f23b348d6c9576,
0x8cb0489a5977375583ebda7c592f8797cea7b6dfe86c2593fa8ceda02552750f,
0xd6e46251391db88408fd48833c2e58502aff26a54a49b1b6955817ee468fbff2,
0x583bb4527225cecaa1278c2949e8a98c75bc0a4831df398ab7d61e445d6659ce,
0xe8f23558754620485545b015c3339de89721220b18d7b6f44740d491a87e6584,
0x65c4431f8df1d72a42672e76c59c6e821aaf0fa1c8c5f2c60a9c381307c730ff,
0x1c6ebadb7d23ed6c558816df388817458758c2ab1bc67c7d76dda98288f4052f,
0x2005ae5fbab174f76c5ac1cefaf5d1de1534ae3d99fa8afd8e86d91c7ad56b30,
0xbc169394fdb522bec381cfbe263c346e6927f067f493d324146a1e3aa1637b5d,
0x914bcdbc01fd3ae9eae6079d4cfa2c71510092fa30578024486e9337458a1bbb,
0xd4b62c7dbc1bb79123b78be1a054346948ba1569fc78dbe324cdb395671927ea,
0x313af6a640c47bb581fe464a6c5da393e9e4fd9cd0a96699024a61fb8507277e,
0x7dcccac51b8580036790df6518847722219e1e598a1557b9727da81156845ff0,
0x22493d19d10ea6739bbedc0b3fbc32ebb6309e4a734094269e09fbb31cbdbea1,
0x0fa1d2b93b5663810a7a812888c35dd425564c789a2557b3495c2fb0150af2ba,
0x6e066809750a055ba3cf36536b9cff8ade3ca0e50fdcf2597da6db17a9d8fe57,
0x83a07f23f72a9b2af879ebcc0a1f891d2d3c27766727726965381ecd9cc7e78a,
0x043243b0eb3e853f408543342a1cf6871806a67f072829705ba0eca7d61cab7a,
0x538cc1cf33bda6889034c2e6fdc290793d1c08ab546ddc70674619ee4866df15,
0x2917a17f944c5f2a307623363e2f50c181967140f5d46b4a5528586f55900c4e,
0xde3b02b595a5eb0b52e8a33d0bd572480eaa30ac8ce316f31454806506f3051c,
0xa646270c314453367fef3ca743f0bd957d40e5125e91610e23e71ee0bd7b189b,
0x8872772923f7c70b53d24475ee4fe4d5ee20b441a90baeb73bb127a80e2621da,
0x0e43cada96ea0ee3757a8048d2cd51283493680b23818fa69ef469fb849e1781,
0x38b2d53f99ebd1722d8f4d420fa67772ec5979dbd3ad9f5bf7652be832653e74,
0xa99af6d4dd22ada5f06a2a82c4243ffb40546cf5e91699bd76a36d1d2924460a,
0xfdff31ba18f5168e616cca7ecdab9d6ef1cc59f83eb4f2ad660deef15ffb7762,
0x97e247889c2b9141211bf4e8963d63a6359fb5b675ad10ced8aaf8a1671e6fcb,
0x9783c77aaac52266faa4cac60aba40d97e4886ccd5c0186e6aeec28d53d509bd,
0xfa6f9a5a10167556970f0953e3715c265ed94c9c6d0b8eb95d289a61f42a2535,
0xde925363cee815412ba1c0136f6160360ab97526c2ea86783927383fbe4bb2a7,
0xeea6394379722e7a93e824e1eaa26e4df7f72a859351a822321b27fd5da7bfa9,
0xdf243b2f59176408027c6ae0def6ae62e0b03ca4d82da6fbe965902d4f2bdc59,
0xca3cb60c3b6325e9419470b4a19428f0ecf220b3a845884ab8f4e654e1641306,
0xe5668117e58a2d3c03748f21e2617d7afa167284c5184e26ce5d25ff1791b56f,
0xf5bb0c541ae2463eb557f2ac3e7ac8df287ba5bc57e32b5212bc921da23d06bb,
0x65e407a458552fe5aa8fbcbb4e614791ce0b8173dd02c0009f47763f3559a5d9,
0x583d0f7d4b2261b5ccc667dff10f32a66f2be60c16c96ebec0a9bc6d3e1a8665,
0x25356a8a7d011a6d0ada23fce10b74b01ffdbe7179eab42ee828c1118f5d25e2,
0x642dd757ee660773abd419f67d00aab29171d474364f1716ea4dc91be14e162f,
0xd6a591390c6b7d765c012f1c3ecb1f03843672dcf65774d79a1a007804f6f3b5,
0xdcbe42e3689cfbfaf7ea549994fb5b6050bca31caf61de120c088ca086c49a01,
0x4f9c258b2d1f03e51178420aa397606059090a84e63afb58ea926c36e96fa686,
0x25f9dd122af94bf1fc7c5e1a8d885a3f231a7eaad45da1c88c6604092b2132c9,
0x2785c5f46a0283d5f60b2f931e89c32f1f7732ca8f86e78d7d2d3552b03c8957,
0x0b3ae19aa5ec870df4ac7f2b134a292d7b32f903520e36c899057dc70a7f32ec,
0xfe2dce02b897c5470e2e8bd22636f01aad994c0acc97093f3cd541285400c6af,
0x679cc222a9dea1a3b26915e8c4c28b65b7ba85288c09f348ce240b525451f887,
0x3021c1a64e54419ccb14930bc85b7cafb8664124ae4ba5bf1c036457183ae1cb,
0x97f42b5bc3702fb2d4a6cd8840fc98e0553608448a05af110727c9dfe2b8ed42,
0xec26113d571246bf51cbb4dda93f1146eeaad8993e8d9458272d22daab1551a4,
0x71db8da172185387ae395384eadd0d1fc9b8973e7a6d9acb970f6294812d4039,
0x84a0ac1277f47728897c0581be5e5e25fdff70f6712fd0fec331a0737ef514a2,
0x948370336ef97449ef210c96eff9701f9a9eb92c3b0b48b41b40aeeb3992ba23,
0x2f2e42f570ae207b63ea5076632d39798e5c677b2dbca5ab85603744fb792f76,
0xc3f4932f0d588655af54e2f00a426142eaacf2bde606d06a9a586525edea2af1,
0x1dc4903f5901ff89fe1b29a9f53e6cd11a8c2cf61d0c122501022224fe16c7b2,
0x8fbe819a70d78f305b71c4fe26604c6b6d8578afc25bff56958f73c59c655a42,
0x4bdba6fe4b51743bdd0b4f0976df5eda3887e54b4e3ea155cf4ff864349d51ed,
0xbe7b218afbda4ac584375639f1410fd663a7e77e30c9924d76d54c4e3e388bd3,
0x02fca3a3d0b200c5c32ab4f052dfdcaedc1f92c6a5a6fab57f5d41f8a3070b32,
0x2da1b9ab321e7dfd7b5f6aa88df94b1abe404098b566946fda64607d765ae877,
0x141a9204a3f929a0d2a4c0f350b74d460e924c8af21b899c9ea4352e4ffb8764,
0x26b60dde57e4c4e140679b76fe56ea15f423d5eb3a83058862a0d0f04c6b6020,
0x2386177793558cefb99512222cb23d95cfd774e764969180af76e577cbd791d8,
0x76263122599ee30894d9bee0a3e8aaf7ce5656d63d2a3e2e58dd8c92b7be7944,
0xca81c51409c0480b233ff71383effe4544c285299ae67dce01c13c3ada2c11dc,
0x0517b33d8e925eb36ff4b8005d09d1b03251daabc612bcd740fdb706e416468e,
0x86040f1770059e7d4a79ebfbd5df12314d42d7169ae12a291f4227cc80b40f98,
0x2c0dfbd0ee1e33953a9ff0982a107e46b9510a983e6715173010b6681ebbc5d4,
0x74406e2ac5175fa1b9c7608cbf46044f539cfbb07b8a5fe46245c5733d7cd37b,
0x8276858597af540ea3b559dc8d3b040027097418cc1636674c34526e1f9a3d6f,
0x20737617f5e64b453aa90648606bd27c7223dec92ed55a5b46837c32f1ccc31c,
0xb836107a6dd14fe143b9875cc0f2de5b7501cae3ae1cfa6d821e9884b042bbe0,
0xbe61a21f8ee88b762ff762f1d6a49170e5868b3592c85be22a1c74c8c12d208a,
0xd0a32f529ce21e00464a16115157ef7732829c076ad2a76afd993e36e86ef9e1,
0x3c07c5d2a6b5e3b6fc92a394378103131886310ea0963edd16e0510085ddcdf9,
0x810f6baf4ce3f7320d86bc22191fbecba34fb771750c75111da9ed21789d4c0d,
0x1d50d372b8ca722affd7577ebe58e524b5f88bab05cf3b78e3c28f8e4a9222c6,
0x37f7c551d589ca473a44ecc80d2c49ff79c52a789e74d6ae002570bce274101e,
0xf08f5045e57388b396a4a98884e8c635c8c7e866ed7fae7524a5cfe23b0479ea,
0xca197b5a3b4c62cfd61c9b9fd84440608221bce0857cbf237453c6ad133e537d,
0x6000a57f00fa009b0586a4c7beb9f66f0d6ab143f354dc879838a142cbc07879,
0x790e2112a467485f87ce86610c2c107648ec2ca6ccd21acbdc8034c5fb133a0a,
0xe836285895fdcebb42d5944ce6616f9eac54f1dc57aa9da9c8b95c46a1941158,
0x87e01d88313b388fff7a189d23576a45ae490e9aeca5c347398776de2862625c,
0x9f58967e22a74b59269a79f372b22e9598267909f2ff761d8d95c95c8aa7efd9,
0x365c0dbd9907b1a1758db4a32b517f5c2fd4120952389fc58cc57e172db40805,
0x04e47890dae571cfbb442867abd3f9e637dc9381bc6cbe713d997d41d95f61fd,
0x09913f5ce8e965e0cf1c06ab914f3a37e4d2320c7bbb9e504950db1732a99842,
0x8758b164234f5f60e5ba5ccdc07dffbf9d66b2228b8f76040bb15932be61d6dd,
0xd05fc8746a2cdb0d0a4365df3a7f989325945396f8c0847a1cded2010e4491a5,
0xfa39b27f73b4a01ad6d1ad285db3fa808ae0c84d88ec3deb94c17aedec1a485c,
0x303d65774dfb0af74e09d57aed661f2ebc75b22803d8920ace520cf4b18eaf9a,
0xfe5d0074780b409904ca22b04e08659675c9635fd6a020e2bd1c85842662ca71,
0xe33723ad8ea961560ba7755c5fccd72035f30b367859823faa765a2bd4ac0c6b,
0xa712b29e058dd527ad05eaca21344d38bf4d1c49a2d6da907a676a2c2938acb2,
0xc351ca1abccd1dd35825046bf8d4df6362e99edec7cf393fd302c6cf6cae1d92,
0xfc4b090f9fa6c076400847a9462f5931efc3e026a0547139d8d6e6e523c7f90d,
0x3801c2037166fdcdeb26f83b037743aa29d13574c50916760722e189cd0cf717,
0x9098b67c21bcb58702c5616ba02850821e8c3c1eeec5aa7e3edb6e7b471baa75,
0x7a41a336bfd056e80ea7c61f5d4f578834dd44995aab75c8f6572c77c514fcae,
0xf4c48a50e54ef8c378886691afeec32a22f08cb325e521169538049df2af2ad5,
0xc7f013aba6dd22b0c91c288d417759dcd11c38e28dffde5c16c957d5960e3a08,
0x9a00240ecdaae1021a547e4336f5ccba6c49eff66fc2d231bbeee9c3182a5c36,
0x4f27f3e889aba67c681e712a6874e1bef6b75a4ddd9ef741fbee4346ed2a5a7d,
0x7c00f9cbe6dbb357e711c742b34b36e3e39f49c93776de1a93d1e4f1fed9c6f8,
0x48f411a6721c89dbbf2b818845c20e17c1a780d257e5763242a30050d0c56322,
0x59ae97f13dd9687af8c8f8a12c089fdafe7e68a43e98d68c3bdcaea810335451,
0xfa5c8bc2f8c630b6c7f6f815db2b8accae092ff0be13a31fb2ba4886873ed027,
0xcfc9f11ef4e24a8e3777b5371de23ee7ba5fe4cf906010d05e3abb8aeff3543b,
0xf2c35f10b7e9930d9cc1c6261488246322f6b36a0251d93187017d7125b5b9dc,
0x08e68511aa365bef9d3337b4ad47385f63c54edec60bd41d4995525bf2c11b8e,
0xad8f8b0184465bc92cac1e81bd6ea847af1509ed6367ed0a6d6fcf13901a4aa1,
0xb41ae3d73c1d7c0662c2b0d886d12b0d43610dd88f05701b4cb5a002a42389c2,
0x3068a51c2b0cf35273a1971f70ab1cb37d5248bcd80e15708c0f087d64f71763,
0x6a405d89878587aca433b1fdccf1f155aef586536255f4d734d84bda02ebf037,
0x1812f20d7dac59dff6c010dc2a16041387ffa09e0baf2f10e035014cf4dfd494,
0x947704cae78e0b88aa4ba3cf01e26194ee1a23c0c9c7d39ccb15417e4d04d7e8,
0xb2b6e0033a015f3fb94aba3e3de0880683cde29350035e468c38906bb7122667,
0x550ba7d4f18a46ec35a459f62c9a06aa2bf331109cc76b24ebbad7f243a185b1,
0xec3aef2b3bf72ad3cd6fd32f472af51d555267a795adfc84322c21b934c0a0a2,
0x1b0b01a79eda6011629247d76a9019dae5c67e3a0a58be30ada687a309e466e0,
0x29a2ecc606b8f9af3b39d3308238c3632e208ffd25bd0426a1b5047a25603f1c,
0x47b4d3571de53857641e407525140eccf97dcaab0234274d5981f8407306aa1e,
0xd4a073fb8efeb65faef24a5ebcb199cbe16af4e2f9871243227ebff92ba03e2d,
0xea11e21a24d6c01cb354efef57a876efd61f987d7f6b5e8fe49e3469b3dded6b,
0xf79de415e84261e779d9e0d155e0fb20ea1c1cdb586e9a146fb7a3e1dbf719b3,
0xc88ed114cbdc5cf7abc6e032ac5afb5578405d4546d41cecaa46a43ad5ccb688,
0xe5557b20edab7c86f150d5da246f86b3567584d73d6d3baccd226854415ab830,
0xd8d5073e4ec316a5c4f4c8e9adcc13c0ae7fbae1381f68d8218ae8079e826d53,
0x2b923574c764fae1dca936b354bac4e1f6334348bb75f0e073666bc178dfb032,
0x829995e4c010dce1c341697053980a4ae8ff85ec0217639c5c516499fa2ddcd0,
0x0b512bcdef9bbde269578ca5fb5f00c47aeb26f97bf05c264197df7d2ff4bea3,
0x6e89ef2ab42e16416ae713abee0a1e8f11059352b617c3bab5ff5538d7c9a0ea,
0xac8e09aadc40d594bd3f397da2fffb7fb6a8665257cc0acbd841e5e6c0d2c6e3,
0x57abdb4edffbe3df37919e4b170b247781fbf1fd46bedb1a5dc1d8a439beec5c,
0x75f44b45c4ca527fa2771716eb4ca96a975419dddd8362c513054d29e2093b77,
0x015d9aabd8d17ea6260d7735c3d5b991027fdcf41cc648c1294c3cd162953d95,
0x42c1789b7b7a9102a77e7535108a8a7907bdd6a72bf1452df8a517cd05f6a0e9,
0xaa7c75aa92c33117864454949108d6729190feacdf2783533d4926c0f422a9f8,
0xf70039b9e9cfc216d7ef4b601b73bf96c6476e5d9b89260fb6155c53fd3f527a,
0xf409827eed42baa93c54943f31104ea1c51b8aee59e9662ece3ec8a18a6f2dc7,
0x1e35b46fd99ffd7a1e124c602c4ea6926828782c7285aedc1bc614d985812821,
0x56514f6dfebada637dedaa846645d33402bb7738d69fe761ab748949bea78230,
0xa5002bf6d9e7109c4214e1a3628aeddd0f86aac66ec78344ff0214e72fa80c90,
0x4c14510e62dd96864d6ae924825ded6a5ce64410722ea8ea8684ad9d14f3e0b4,
0xd4cd52c6389b7db327822cb5277b351825901998fa85b47b790dd6a4ee8b23ff,
0x71d86fb0c6bc74891982a5944f92a5c1654611267261d94243665e993e847b49,
0xf3fe3b6359ba586d755c6e3a1cf999d6dbe568476e9d819a9b3a8dc7a5e4f63a,
0x90d36b97988b03b4dc33c43d08ce98a890f175a516b9e2ed61e9c7b83a30364e,
0xadbaad9420739da8a0aabfb48a253c672da3b2dd728e1ab4a8cce89bf06488b8,
0x99a8a42cd1d4a3d8b886f8f16b3d9c772306ee803cfcb9051687d960b03f1f4e,
0x3c0e6c09b4aa08c6e4e8b95f429e349fd947c573f5a2bc7b5f443266b67c097c,
0x56dca91daec3a488367e36bd00e31c482bc39f4a6a0e701239cede2d54bf06ee,
0x7357c545a39076060855700a4854db3df04a4d75ac88eefc1d06e82285f2ef2e,
0x6e625c86b9ba6830ff7117efe7c2c9f658b61ad674eaf311916244a9fc539cfe,
0x6e59253bfbbfc4d7ba6834608d6b9936ce5f46ecda463253279b9212d6d053ab,
0x6ab7dbfdd47a41407d4718e471379ba288c6ffe5c37a779b109b05986d1dd4fc,
0xfcad78e10a4cff06f71b2fa699c49f96cfa268a4719f5cf5e13e98fcb3c97420,
0x3e9453e2592508dde64e300f0935b328e8fd7c45c77cb504c332d871dae7ae9e,
0xd65725ad6427fac422e597075fcf1f4e345ea220c6df5ab5182237f0b00225ee,
0xf33c589a63905ce9bac68a87b714769fca22476cdde06328159cd562bff17569,
0xfdd0dad0ab75f77d7f48c44ff5fcd7b1fda1c6b59aa426ad975400f00588dc65,
0xca85855616b2fe3084b338ff41051541c4aa7bb623cb5a5ae38d79c1307bfa9e,
0x34eae95633f75f7d9ea8b78ca197abf38c4e69e95464aad1c6e102d36c1f4a13,
0xb971c43c261618c35e01e2bc6cf638ca6be8f5c66aa5d5d643de8fe85bfbe2bc,
0x727a39e4ba6db3a9160651292c1b7855e9f199439e38b502d3d4bef0f8207a56,
0x759f0171bc009cdcdb077330d00665d61a05ee611f6077d83890a3f27b48ada5,
0x0e28de0d9f6a75a8c66a3f71153382a2dd63dc114c0476c92936674ef33897de,
0x326f31f60dab91f8dabf157069e2668d593401cc0644d631498f966cf9b68929,
0xefb3b827cf15b1f33a1f260454873645998b6fa8a22bf5156fda2d4902f993f1,
0x9b36cf22f9f126053548b2b5918ee56797e6ce780f732af2bf0ab3a11bcf4521,
0x65648e6c60d1a45ce9c35b0491e383bf8b82aed626e60b6078e3e2c9def8b7f2,
0xcc6ef6582b248bcc48768adaad3b2b4d25ccdbaf514bc58843d16fd26f0d6653,
0x386e742c2935a633358d0c92634d74616fbed69fbba309fdf6a1e6df415f72fe,
0x9a68e684f5a94dfbc5d2be116b5d015b7c8e59e60500de37d643195239200ef4,
0x009fa71f81d03f7fdf49fa2d7f6b3eef698869b3d818a4b5cf97f2865c5a2c4b,
0x14dc1491a3b4f1138c25bef0e66e3e801d77bd6be0ca04f33fbcd0edbe2752ad,
0x97284364d33456e3644473b4d81431ab4a459ef51cda1dc02711beda68fe8cf5,
0xec528931c8f61f9e6b43ce8d38d4342b99dcab639b624c3d416d16685c685263,
0xda644e78084a75fd062802909dc5112b1f6f2599e4dede92760031f3b4c591c5,
0x1a03e3a7dc8de28e3dd72ae6a0728ece4c6b06793dd0486c003fe12796b874bd,
0x0189f4b9195c1aa955630e7beb85ce978810abb8aebbc04b2068b011d47dfeb6,
0x9280ec1e46138f63621e922b1feadd85095d71c96d3983bf4d649deeb92ba59c,
0xbe68b3c32220d5eaac7aeeee470936a8d8b096577099cdd3e6d18d2ac0a87151,
0x55d948f68b852733ddc49ecc05b5aea5e639c3dfff734b0ff7ce07f16045d0ed,
0x77ca2cb78331f4e64fe751a4dec902d838aef87a3e335c4ea41386bfb368907b,
0xccb0225cbbea9b5925bc4f0aeebd745c3b0aeef969b63c91a793858e8074d47d,
0x804363713e741c1f7f45c773147ef178ff3208436e8e0dc743718288b43b9ed9,
0x0af218274455e015032f234d5aac28b8bc73b6cbdea1c61c5ab3fd0cefe48525,
0x39d182e5391c881b497ca8087c681e01c2f8b3535782c24ae7fe1ca173fb5992,
0x5ddbfe891059e0ce32e482344e0935c6133f7ad00bd895e95fe33b4dad258920,
0xd620df44d48f777f46de12335397fc845333a0126a208161f0e64f6c01227796,
0x226f69f12ad203641878e459525ed9626e644bfc15919094869a3d801c9c0ecc,
0xf5f58e6e9bed3ab40dee87d5019ad2d2b8f47efd337b35a875045245bbad5d67,
0x9f26bcc76ed674407221f7a299a293e41d9b3d0bae62dfe03b0271f661178269,
0xd61d588fe8a9bf21d433e2db8affe0cdcf4492a574e9d9559f00bfce543dfee4,
0x0e449d7c29926f7f42b3c019eeee7f726113338b313734243a9862c7b4578135,
0x5af39e4bed756fb34e7a1fa3108dd956e609412560c479991eb5326dae38c408,
0xcaf425790b4f11a934699f0bd5b4703c69629702ad3fcbaf444e808fe8e43744,
0xc8704a3ee308abaf9b6727d5b69eb45c65858c083011dd5e217bc515d862853c,
0x683d767d48210e82249956645d9e3923d2f2e8ceea449bdcaa7a987c3bb6a25d,
0x19204fed98a5522a9899f49fc88424c0fe785ff62776e5351282e45c69e03684,
0x309999019b34aafe6b6521e7704448d696948d42476ef9a298b62d50cf2fbbf8,
0x98a6049449a14f63a19e4ccbeef4f351c7fea75450e3e5b6e4ca62e9c5dff999,
0x7b6608f1c8b6d0969a2cbf8151839471993ffcd0d24cca8a156542aa2db159b8,
0x1046ab48102dab40ad10bdfe2114097a2551d9fe15885c6b5b35490fd3e478c3,
0xdd01b92b1285f8b4c6c0e623900a7b80de772d07b4643957179e814be84de896,
0x709846627e93f497d5c6f702a8651551936325addfee7bcf0747a88cb528a8c1,
0x61267efb05547bd2388f3837ea62f40ed5d9d72f01bdb7a0fda73bd3c3119a9a,
0x8bdc8bcdc16a36424ef23de6d930d80dd6d88c6cb0e6a0d8cc60b105c73d1806,
0xda833d8d79abb35fce5345cb02d74dfd87a99a75328fcdf007106f67a1b5301c,
0xbb4185661ec5f4c2a63ab25bab90fe0a6bb36c4ecb6533e42e524f754f9696c0,
0xaef44038e7eb0b170c8a82ad11d1cc686729c9aaec6ce4dd4a1127612b1c3a8d,
0x909fc8262f75b0472f3fb397497c84f6b8f97d132fe2ee82b685fd2a137455c8,
0x7860feaef381554bfc982b32cd687fbd7418c403d48e2d77a7e47c327a605fe0,
0xdc713bd43bc5f00a425ff71d64a1a8368fe22c3df835aca243cc6be52b7bc0e8,
0x9277345a9120bec4d08e0c44e01d1ed9e5bf5f09deb299cdb3f280ea64ff3de8,
0x130fa4e2ca893d89b99873c81c3bcccb4f13c9b479f074ec787210cb234840a4,
0x4267968bcbaba58e06a823ecec0a489e36dc28336f25896e63c695b39a146629,
0x4b3a8d7788d34efdaf334dc26484746ff533b59d3e25354f9e8bd7ee35f92047,
0x93b5d4a57dec443c6085f8de0c221f845251d08e2fb1a82759ce2358f3ce1edd,
0x14c48b62b094c72fa0d7bdfcfc5364110e1175ca66e41456485f3c26927423f5,
0x72d0baaff9861ad77fa8739eee6edc90570791f709b17f088462281eee1bc22a,
0xa03e36d7700917fab8438e447818a185265cfff930e6dddb95d71ca740c27980,
0x6de47ac8608a2b1d60015015058085ed3bc42e5746b1c8055800ccad0711791a,
0x93d46e57a3137471df420add98700f1457b01b25312dac1658fe5d09593e820a,
0x6fffcbca1475d4fb05feb8fcf6df7a09f44ec20e8552efb5b24253178bff3353,
0x32947a96473e7133817da7a0dda02e682b815303a0ba4ee41eb15bd2d8f1f3c5,
0x89b0c80fec6ad197aad0ea71ce6bddbcc0e706b30e9b80245eb29023ff31ae2c,
0xae608ebc9d74eb26a0cd0b4b8284330eff6c0af757498ef2c828987e35cd0551,
0xa58ac0ec912b2d1dfd165127f44152f5d91d3f52b5e53461ef85df4fae7018a1,
0xeeb375b978ff4d84320d308897bd09227de2922f3643b635dcc0810695fb24dd,
0xd553ba60f620ab0c9f15ed48269c8fcf5664ce769cd153a12f538bf14adfae26,
0x4b70bf3c8da748fc6092369349177ac6f4ab4a009c7b3bb0371a55a625aa3c35,
0x43c4ae9612777f59ccd1721af294522ea0bbd57a6a574b3582508cf24742e233,
0x8c0ed435d8e7bcb579e9c9ef8f88e23c4e3169a448efccaaa1ac6766d1b1e407,
0xc9b234a62988d4d926cca1649b7914581c6397fb2f48e047af06adbb6d838eee,
0xd1f1b0887f98dc32fc69e0a830ccef354679ff72c0fcbe32efa1ffde52178e4a,
0x7c26ec90dd3ca9e549577e2ba68afa0e9f963dffb532ba79b89a51ab71c8d200,
0x48c0502daa9c28d82e1f8b2c99a7d505e3f1fea6cea035c9c00b5b00fa544056,
0x23a05e31959b69b4c0e3d37158d4c9c02b862e3028fe9acbb431ecb1d3f0d766,
0xe71397ab819b57ee5baebce73d6a23d11344410cc44a79db0c5983859834de61,
0xd43d95779a716749744ba45575fdfaa828ceb2cc18508d82fd9412b700215dc3,
0x8558ee5bd2f87db670435a41e25948a4210ef65bd61ee8bf8083e141e7241160,
0x2c59c2cc3546cc08679502c01161f50e8572d1143fea5b9cbb15246d61ed576f,
0x3f4b033dbc257c20b24cf893b5ad41e473e6e519a02f9a6957e7107322c32e59,
0x8b02e7ff4b049348c24333338156d249b23e5d23bcd5ed3ddcc21200baf77e8c,
0x7f58f06a536de06f85be2f5d6ea788dbd2cb567a2a492c7d0eb6782dfa6dded0,
0xc6183b0172834b9ea954737fe5752fad7574e52b5dfb384c24b9ed6e138f4f83,
0x2a5de140a6b06145ad407a58041ff5f2b1db799a1b201232110a85f2e09bbb8c,
0xe8cbd3e938504af0cb267203ee52ef6cfcc02c2ecc708642ce941edd82180b62,
0xa3040b5c143e92d91250b51c09c070b5f1079c27af66a068599ca4c8bf12764d,
0x83f09d23188af92b1ff2538b9ee495c4eb447d64516f912ff5b16a996014c154,
0xfb24ac349ab6ecb70d4e8f5739ee50a76972a42967a17d2ee711676da67bcb36,
0xac1557817dc9faea7a420bb0df338aa5f696b5e216067036e3cad20af839cb3c,
0xd451cd4a79f6a7562c98487589952eefbe33973a4ef320cb3d76b870fa3aa202,
0x16fe3ea3fba15c0ac8448fb61e3b8fba11f5d020489675b9f9c7bb9f62f76b44,
0x53fd7db8cf32b163917071183dade9868e6e3e18106b0577d19776cb877fabbf,
0x977a44b018fcde3a10db718b832d4233d287546513c9d9d0b69432d3f4f540ca,
0x5039a3fe4c1660e5c19f51f920c043d6bfedfc2669b12b811ec628a90894cd52,
0x204b7d47077d03e0e75092341b8f187cf195e32783b1c246b456241a9a407899,
0x05198fe10016b7db0c7a0fbb0b6f09032f9d1bbdb548b7e91d7c8069ae14c0c4,
0x15e3c809bfbc8666d8265a2fea9607ba160f0b2c70b57d6df361f4981220bf16,
0x277f77e62fee23ab32bf066f96a4f248c438ab7f9bbd651c71d7ba1442946c68,
0xde7050f1bd892c73ff65a163d183dc7556f009ce7c3d62ce6b794e8ac667e061,
0x809d30b1efbcd8f2ca39c4385927a5a7414a246ae6aa3436246537b99d8688e4,
0x97521e5cdd428cadd9803dcd1b82527e6793ddc210a0050e4a6a55a0be4b9c00,
0x50327ed8f7a8ef321de5ab693e2f6c29a12debe57d1e00b22881ddf2e1004b55,
0x66acbef282cac22248caab0e6fb68cf3675f8a578067aee67a2c7c79b342d7a8,
0x1f5fd62b8fe3631ce8053e57e1acdc9d5797b4630c1f3ff252aa3d27ed003209,
0x87164f15ffb6a049c1d1afb25ba23bb06e426bdc34570f58557dc64b62292b48,
0x02e18a6add9f5e9b31c940656ddf0aac2f5c91b8ca45940daf0e2bb26b420c27,
0x9f51fb13f78d9211a6bd17545be1e3b862c9c553789c716129d4922a9439641a,
0x84f8a53cfdb9295ce354ee54548a187d87c2fba4ae78997b2cc01c68521c415e,
0xb7be4a4b39447e83e213f4410eec54cbab7879d425f1129874b168ad33e8b9c0,
0x4748c03d3a66c77ad2a845950190822ffe9f3bc5077a39f2d386928dade2ba09,
0x0074e4cf4e394feef0141aaba17c10e943533f486fc82c94e161c2c7366ae266,
0x69d5d7ffd7e772ebecbdaaa6e207b3f6e562d67cd19cbcdd0571f85454a315f6,
0x5709146adf5347dd882406ba8ead0d5aadae1ef699e65057ebe6a1eeb145e557,
0xcb11ba2300724577e5ec9342a44ed2f10d0ea613bbf9dc10b14fcdbfb35259c1,
0x5dcae01e96c7af39cc3a80e34e39cab222e19a65eefe2bb0c2de87b221c49592,
0xc6835fc34b2cc85df4b7d8db31c4eebc71a309e12c7d22620ea9e9a92689b54b,
0x8052eb32702f88d0f33d9628e1dba9caa48a104698e90e3de86b41639d82ad34,
0xe6ef253444736af98ab8edb1f96ecff54ec89eff273149098b5e09342da08b7a,
0x3d1f0aa4175bb0d10b4db96fa2f3afbaf877a197d39aa231fce872bcaed1565a,
0x9c8f17b46f18f5d7f89ffe471e7b8df2186d526114e74d9e29b82fa9101ab367,
0x2c61e7a81b09f48cc94b1160dbb3ffc83bb739f0ef993081ee01979492808079,
0xf0ec7bda83b1f04f9944de6260f61d3bc08c27681d05d4fea5bbbe6f4d0616ce,
0xf2b6bb5416342cf22e13eb34ddf8d72c4eae7de6fd5ccaf18c0ccd55673702c1,
0xb06d993008d1bf0999e2e216a5a2d40de69e541a2ad0146567edaeef676c88ce,
0xabafa17eab2eec001a165c567da9affaa71b2225dc691814fd1accb178702348,
0xe203a4f1a56e34dde7eeb9fc5edcad1085b384d148ee0f68563f7416bd38e830,
0xd1f48b894b1aa4a6836d6531bd948f1a513a147fca25b2aa5b49bdcdb15082f7,
0x55aa2e6cf53c5bd8777dadf89c40eb78137fa3fda4d6e26aabccb934942c82f6,
0x4c05e520e57e654c495a73b6678686d215d8f16e7ef9813bfa8bf54f11303879,
0x8c147558c1edb8e3747176b42b698ec4526ffb864fae600b9a1ab817fb895bf7,
0xd48e2f394a88fad323392718540a8c70d0b1bae26ed17a79cc6c10fed68d76d9,
0x85d6920e5e8ac1365b5e2db3d2a15d03f2ab59f79bb6ebfb8ceeb36f91c22c0e,
0xf7d7d78adcb8310de563fde2ec7a7dec7e1635ac1688b3c2a748f075109ecb42,
0x4b690ef2f67b446d35e8045f746886325e1b56d9c1c7cffad561bc0d18f891d0,
0xe4bc9aac5dfe91a3e23a800a2efea346931751af5a5aa2a1f8b4286f1d880e9f,
0xebd84efd75975f3fcdc0734fba40ba00779fd5c372371b934a3dd8cae0f016b7,
0xa58b9e8601e2187d72e202e02ea2bc54565aa8510560ab412cc0a37b2f28012f,
0x342e00fbc3682c2e0d48bc4c126fa86982657636ddeccc94238250c35f8cf158,
0xe0de6843a944e9e835250714a3a27aae433f1e30f3c2a51579cc6a4aeec9dc3d,
0xdb6875530d3f7d38493cda4b7c7b5cd9f73b8bfb0d6b43bc408d983a4c2a0b66,
0xbdbb39c881dbe9eec90635d6626dc2592e8edd7bd9aba9870ab60cd1b1061957,
0x4d47c5ef8c4d3337d69f9688b32c452ad32b22029969576cb2bd57479d33082f,
0x16987857d138c1099b5ad529eff1263ab0933696098044af1403469b74a9793a,
0xbf8ede55247c795445d297f2d20f3ba2c24b016a680c42c21eedc0611a3900b8,
0x171fe0c00c70f4013c3d0a907f150ee87b0ab7b97a83d371cf554bf9a992e7b1,
0xedeed0dbec35d1a0fbb202e5a18665ee761378a40cf204376579c79dbb272cd8,
0x58081a2d78a00554ffd053111e5d540a066831e7e3709745857c4b0f05aede35,
0x9c516d873925ca78526a6491340bbb2276b23af7cdbdbc98a4fbabe53de9ac2d,
0xfa3d598cf80e4442150e6f212b8ac841bfefaeb6f4a4f6173f576114e745510f,
0x5af43f7a0fb1cb439a7c63f92f398d685b646aba59f3c613bf522a690629ccec,
0x75efedba484dc59626fe7a684ba143b072248e7644f5369e218539fe46368f43,
0x3f0cad1abca7ebe585118ebb46e5c00709fc53e83cd09930f599a1f324a6d7c4,
0x71aadef439a84ead4fdfd62b3b83bd90437456e92aad26e4ea9e4c12f3c3f310,
0xa9ec39500a9a17b183f37e8d45ecaa29fe3d7de40b1136345ac513ba17685151,
0x18ec6db4f7b0defd14924b5e0172dd9ff455028bc1cbf545afc811a5a4dd9ea0,
0x45470121208cea39a56c065b55ff7655c6ccd73efae611ad2007ba233608b4c5,
0x0e8eb22801d646947e1815c271d5ac907e39d456ed9bbd5973245330c745ab45,
0xdaea35cbed9ebfa90e6cccb3f0e5f121b43da94aabc544b63da59bd32e5c36f2,
0x4b5ee46053000cb7213a9b86eb64c4a6befd59e8920e4e50f9e3a833d3e6dc69,
0x2fb44c88ec4754e667a3d1fe0c095922573bd90bd550e69cbc2dbeb6494b5c17,
0x450a7b97972068077f2f34a2b59cb0b2e8f6456389288aba3784bf8d47b3788e,
0x5f0bd4bf7fa6c0ef5fce43bc48f0eb183444da109a653c5a9e1f703aa61210f1,
0x6beba149eeebe9e46f9a58e4c40909dea883864cb35bc668eb1e82901934f92c,
0x90cd1d4234fb5fcf8369f1149e8aeba220056467f295306d73ed7e90e4cc69d9,
0xfa3a5ea171cd4006703aef6bfbf1e8f59ac781179766bf4572c1ad4aeea88714,
0x0d297054d756007b8f339de0121be4d3a514316308ec9fee5e0311ad0d34f5b6,
0x243b121f1c56e4a809a352140873ba9d02e643bafeabceb4a0f97bd3f687c638,
0xd1219d86cb52041e5816d280d73006fac66b204181b6416c731bf22ab5d32da9,
0x1a243c45faae6ec84041ffd196a2b079138da602430e13dc3660985daf9dc827,
0x6ca6ca5a7f2f92a45d9ddeff577f276234649fb5e0eeab5b4b6ca6ffc2c50028,
0x8cedd0c778080c308e3505a76b0cd42a629a5fa65e4e23515b231866b3acd727,
0x0ce58864c446c27527f4bc791082e1e48dab66f2658b791e6af19517611eb5d6,
0xffde22e34ad5d6a968baffbb324cf133807789ea829cddec1685744c452e7a6e,
0xcf1b7e8edff940245ade0962e1de1a4b84cfe065b55cdfffa8dd71e5f7bfaea8,
0x90cc5456b57afaa2aff02a2b629346ffcfb2ad494bbd2513fff2eab50d2e04b3,
0x82dce6606cab60f27d9f47a8bd05fb547415d9adcdf8f09125026c89915d71f6,
0x9f728ed50599be7c3cc18d735856d177e2f05697472c3b45c29373a9bc760134,
0xa3c1d325f450d824a3381fdbd6d78f91798e9b805df2975d8a03be302704305e,
0x0419b0c0e79f938b2139988e3db630637efbf2f948162204a6ea6fa9ef9dfe84,
0x052179692aa5dac55140604b2cff131e7b49508bb4c4855c909adb46a02faa4c,
0x3d63e6de2ebb9d2fc5c2bb6f802bc4df22bcba7d9380dcd5708650facf82356a,
0x79994f795f422e27c66d39e9c4f4323ff00b5961784c06ced8953fc4550b3cdb,
0x471eaab72abf2497eaf977a8b99f6824678efcc536ade1f8533927869e12202b,
0x81ffa8383ad84944edf0daccec24c7f4839df8746780e39730e578f60e64d98c,
0x9ea7113899da4b90ebf40c338169b26887b84c416c0c41108d62d18f7518ddf6,
0x31387e079708bf8c26b2723f7771f981bf5c28c2c0ad0bc3a91651924b5ad290,
0x8536490839dd94d4d464927f9f48fdfb2303c93e79858faf530c26bcdd0c5d9d,
0x389db3aecf8e428258b1594f17ef4211b78e8bc28874eaa27a47deb626cde681,
0x5c7c0f94fb75c7185c6c26480c474f1e2936ced115d1c698ddef6dfb29262cc9,
0xe51e5b416c089d38b1ff47e823b120f96f18f494d95270f8e2f1ede25c743479,
0x0b1a44eae1484b766461c3791bc9d4e503fe96f999f40a8aac064a46eac1ce51,
0xf57c5c589f0a6cef300ad7477273b9bba5e1957361bc83f22db802b6c3acafe0,
0x809741f672b4b817e32c618ce04206f871bb37cc6c4c0482019267cfc4239f4e,
0xcd35907f5f91d334dfe2eb374ee593f4a69c28e7cc8aed187ce55dededcd5bf7,
0xfb8d4ed38bb62413eaac2c60d55466333a6fbebe238ed86aba87ce12f5dea170,
0x61143b850ec702837544cc308c8e18f8b5e2f74055010108abdbf4acaa885c11,
0x17a9cc64d6306bde8d72ef83f79a28af3c6e09c65c5fdd4e1678b76c132daddd,
0x46dac6c2985de5a214c7622d090e8a31672d81ecf85267adee975f720d93d6b8,
0xbcc376b3ce8f21dae182308b08c166ed8878b83e36591219266d88832d64619a,
0xad2a57962d76376cf9c5ae757ecdcfed590427b8ad9b9ed3e88ab0a6fb5f0946,
0xb6780990336829ed92544c2aafa6597c82e9943020b229f56e570fca0136f802,
0xf9a9d3bf3441e71a800b869e9f46aea402a5631c010e189b090e8788a0d8e885,
0x343ba39f32d3a3f6c98aacfa000324162cb7c2886b224858c98345e31d12fce7,
0xa52bb0a808516259878214a9159d143359f37fe3672fa99435a9274eb8ec8b6c,
0x98d8cceb516e9afd8cc13fa08ed3c05b38943516080917dfe7fdfaa1ebd872f8,
0xfb5288d38c1cc35bfdc8cebdabda660ac42e20df1ad1f0f4f0fda526ba720e35,
0x41afd667de087b76d869d12b26566c66cf60db578307d434b001d5085b9755aa,
0x30ec39976ec1d965ceb9b374105cf60479099816af06563693aee89a04142eaf,
0x258028450da654ba369394128d33120d9475e9fc1dc57fce24c902fa85d50c48,
0xc7d4f6226677845bd6e82939b1d03a069ca3b588f5e0f3a4c95c955a476b75d0,
0x29227a18aac9105132c93d57eeacaf6ffbc7bd6c1f17d2b35d7149bd38463d0f,
0x4caec82c9387fd0ea9395462a82156d3452a4da73090a2057c8e8c76bb8d4fff,
0xf73b8e1bf069564f845df223eba775977465677a4b0455a9281a53284d9a98c5,
0x671d3f906a4f8d880950a587449a0ed4a62cb6868dec4ac8ffe3ccdfef72d811,
0x4905006cf1d96495123bac00e14ba1199219f767c19e948f354eecb18b27bb99,
0xe44d72912fd7be16d577b6d2c7032262a43195b5c7229f89550f69e5dcf92c4d,
0x65e592ecd7a23affc3e4fa2b2cd75a7ae57ecdd35aa6b8db0261a91b957839a3,
0x6a9866ececbe1d3a649ea94eec38f25e7866b1db090903269136297d8211d6fd,
0xf7d30d5410ea1df36b854b4ebc331790ec018b53af9af93ad322265043be74f7,
0x3d6ae776629344a740dd2ff5dee214ff9efe2ad1e435c57ba96ca87611874fb9,
0x677f97a7f97de6c4d6e5a8a1edad1550df835148701ceafe5317276294a3617c,
0x95c5f78d79a260e4ff0cb690fb534dcc8fef86857374e971a5bb23b724b4028d,
0xe5b862ceafc269a96d1f4c9a83ff40cb4deafbeaf7a2bb1e7e6e4b237ac7d095,
0xeb33f938872b87493eb0d9151a920d8f5e2a00effaa38ff592da0c1fbd82f4c8,
0x49945b3361ba804371e9b65abc2d26809aca10e570e39026da0b2e637641f9b9,
0x940343826310784ffcb11e7b3c88d8f1116b41f2f3cec4b28508f0c4b98f2750,
0x6250f0dfa628ca768b256c4ea3c842861a28baa50caf3c02bb65218d6c2e5927,
0x73cb7630aba73cb758908c9170d28688c194e117adc99fec1aaf669b88ef4724,
0x6e12f57d403e556771a5c38ef70221858c385d91acc15efbffbb2aefed25683b,
0x81807d7383138a39c8c147858c96062417c0b9024d581e169eaa8c70b925295c,
0xa4962f307d7e0e30efadb8d49a9b14768a0575048bc760321e866e92e1c13d86,
0x0b2eabc1c99f4e2710ff4b9d7dfccd9a9d51df6763808208914ac537af7f6e1b,
0x000ba080ecef822fb1386e30b2f3ec9e1229229e5abdd19f08e82bc346f7d511,
0xbb1af9498cfb54885c00bd1137c8a57aaa5b5207a77b9c3a5813df406c266d91,
0x224f8d298ad9a4b135c96bd9afe69b3f90cee4b066ae0df7f2d763dd49686992,
0x2ae8fce0f6f56a6efec5f2df6736f395e5f66656b21a9108026c1d93c0dbe38b,
0xd294a49f188fc7a53e62ec63c611ab470c20b29c2c9af614010bbff3ce9b36b3,
0x63c09d1964532f8c064cb2e1957be6c0ff6462d831edae34258d432f6be82800,
0x89f2dca8f137fd3b964d8887517b7c5958ed6583d62cb9e7648e81e6a2ef257c,
0x3dc8eb62bb159a54ee4353bbabb0163e9671ae6be2aa7eae791f520a60020b11,
0xbb8e5aef3022afa7c94cfc1abd3d042a5f25fac5c67b1b3d07ebdfb7093ea3fe,
0xb59e9e49a1ee500dc26af174c59f224a6345f252ca7a18c15ef75f0db7cf04d7,
0x62badde857e1ef37efc87e7dfc6d86ffc429b2d138a161cf310a125d685ebcc2,
0xf6e1b23ad806bbea36fa0d2a9249a1de1beaf5130dc71894e3e7177a58c74401,
0x06bb45769d7e75d9dc7884bfe8f6106ae5fb3a3405644831885edd515506b19f,
0xa60be800c0b7aa63b41b0ef3b2897290eae096c3179a4a5c0bf74c99804fd776,
0xe1a4c63702155265bbf31873443efc633f3463fbe4fc32aa5f3242c6d1adef74,
0x6c5994ad21abdba2c764ab70bc4a16ebd6740629808a72a7c3847adb77a04778,
0x38589339d8e913bbe1d115a831a2dfa26a26758eca20fc91f950ed26e26fcb41,
0xaff05cfe9ae2568c5ec95bd8d1f7d639f27656810ebd64366fc04674d293a193,
0x682465945bd80829204af41ea8c1ec5261c301d5f11b0d268d4a2f3e434a03c6,
0xb91b8c416349e65dd9ed9839d88a126a9e13eeba8b3db6ffc98c69d93821f6e4,
0xd609b14fb13196b398e2da0128f4d4e4d4b80d5bba953b7a16b7788c24436267,
0xf8688c01febbc77c2f279c3e5e8fd63ef6c701f4f4dbdc104aa902ec85ec21b4,
0xc6afad031bbca7ffdb86cb06c0f2de74452b8070585e1d859113896bed5c3ed0,
0x52ed046834e1e87163d3fa25150a8eeafc93965403ac65df56c70480ad3489ce,
0x8a59607d69b0d8e48403ba1347ded1ad9e42edc79e98f13a627dd03640d6bc97,
0x42384dfc76c2261be38b93b48eb560c04112137480398018db428f10223aa14b,
0x356957efc12d4f38d5cf7f2af8f891130ee12ef6fdca19dd79ded7a99af807f4,
0xe85805e529ce96e4e6137e838b4c49f3435341ac5149a6c2e5ab307a060edc3b,
0xda5228d7d32faae13592a2a4bb4a866ac8310e7ef1f2731cc695fcc817fd2ea5,
0xada611d5228ee5544b3c454b12bba526998ee30a59f53e24284c198f6f87b122,
0xdd2cf12ba71c08354333cf8dfa3682c1ce09f762dd046befcb5395c2bcd31998,
0x5bd65148f1f7928edf5c0ce68d0e6b596af51222529b8fa4c34e6519e9b7ff3f,
0xc713430a19fd8329b2a86c7317c7684c6ce24bf8e21b0cd11454a63a2847982c,
0x3f159a6131c681d694d7de16632ecf668882f7a2f0e7f26ab8189d9f285cc106,
0xf600f793827845c73c3ff807de703b2cc313933b11c4592792fdf215b9627d70,
0xba0cf479a5a1ca58cc06b41929e354997b74cd8dffdca1a499977a16e470e34e,
0x0c5a5169b275cbf9a54a14cdba7e9e6dddd20338027c9b1eaaf971ce05a83cc7,
0xb859078a2a8c4e6ea9af794f1e77c5440d6550caa5479343805203672b1a3dad,
0xa715c0be7373550325ba3bf36ad60a32872d2ba8fb04e58eca6d37c5c634f082,
0x7db24a859c583ad266991686d33fd15c28b03174558cad5bdc18ac438eff1a9f,
0xa57d98ef02015a17e629e5d3f02d46966d0e846b4550e4179d5d0b401349f679,
0xec1d1b5af73bfa0e3bb2db2b33f835e4d5e799b69ed327e183c52e0ed078dcc3,
0x4533da2e2504da6a57fa1c3d8bb97571a19638fd2798f2fa235de6c607776a6b,
0x55db1d454121f30ecdda7093a7b09283d90e003f764604c961effef4e7ba9abd,
0xfc5b0db1adcb7288823b81f67bddb1c7e555bf1ae4103f9864ce0f914a1d65d0,
0x93904f1bd136c95e527d74f89f296f9e0efda41ab6c4f2f05ebaebab0665f33c,
0x960e5935f2808ac495a7673d883bbc9f1fb17cdd4aea563e07f242882ab00aee,
0x9f06d1b08bd1709afa711f93121c9273914b4593dc54c2b3f3bbd8d55d5c2ccd,
0x74320342b48eeae7cc2bd448ded30fc2edb70e56dd739b4933c90dd301d5516e,
0x40c395ec14a6d8bbd53c552de98d1193ba0ab2eb49d3b8899ea658b8399c814f,
0x6ecbdc8b817b9b54420d4b5065bb612ce9480d53f9c17543efe3a7c08afb98e7,
0x1393403f5b20e149fda444b509038b057ac8ffc011f8f133860435652f728942,
0xd3e640460fb0b63dc65a137ae1c98ca406fb4dfd96de087e11a5a298649cd961,
0x4229e5243c82d3e961c0a60eda6b44ebd744586d8822daf433dbb43991ab2804,
0x8bd885fda07569ed5a3843a595025669bdbf62b01b9dbb4e451465dd4c56af61,
0xf64d5c027411341b75141ed4a45ec4b713a05c1ebe31cc971f89d22079d036fe,
0x02dc30554f01cbefa971ab69b106a0decfd8ebb9231827325fcf72d058365345,
0xbe9fd93f35f052c80118fb4a0e10bb81938dbcbe59bd2fd3ae424905f4a1b43e,
0xda27bcb34a75485d9984927abab0d3d96eac4e6ec404a92e34d790909a4b1db4,
0x8f22481bf36cc031ab74bf2579b958920a26043499d579ad8e0eaaf52c87d4c6,
0x4f99662d2926bb9cfba3002ae795f7ddfec39501ad05778382de9a1e1dfd6088,
0x8ab3c2c65154b3f6f90ef8147de924a56576da598dd74ccf7efc22c5cf853f02,
0x399f10895f8105041260083765a5ffbd74ea9fab60c1c83394e217e08007ca7a,
0x50619977c6b7f31897eea3dbd300ac16708a8c64e18fd23e207efee0238dd277,
0x2245c028378c16e03424e0554e827f7efd707e45cc5c2ecac422262b9e3261b2,
0x5abafd6b6f411acd16c3dd93c76b52aa0b0052275d8422b005b505cb9c3216b0,
0x0195407ee4965e72d4a5025922922d615e3e849ccfe627f0c9a718d3b68865c0,
0xea8a22c90806af8a3f7c49c1fc3ab71a35b8c2f4672b751db87bcad7e110a2d6,
0x6287820bdbc7eb3ade2a9e7f06be6b6c1b8ef840c514ee61c1da36e46a7e197f,
0xa0b7be5d08e9a8c936670fc5ae276919e3036d50f791937947c0af3f03d6bf19,
0x2f511ab130b867fac5c3808b828be0fbbedd4c628300894969c4207d731a2710,
0xdd4ede3df05df04eb7a5d42a0faea5245bb7ff2cd72089e3252f7c1d2457615d,
0xe983e3bdb071a6ed127865b98842034e34873643484596ac58eebe0c6c596f26,
0x443d2871bcbaffc187f59305255960c2e20c90035b13cf9773438e087b967d57,
0x4cb8281ed639fab4a077b385dabb577265ed6887dc8c246f6908e88d5b7930ee,
0xd5e7f58ef48650773dc1958f4428fb3e2c3c7424a06ff172de3892534807b927,
0x4bea44ae69d735e134a5304dab70f172741dcde3bd76ef4fdb8f653f143bdcf9,
0xb9cdd7b9ddce0e8638a11d40ef5fb1d378ebe298fb41b25f2928d84fe2049675,
0xf31bda66ea3075c1e38bd2d0977fe6ad7fb1b9a8d0204e279087e76ffa4f0d83,
0xebb5f10b7e9d039f878a942e18780998c4e5c97f22244df4eef19f8b8c8adc9b,
0x20394740da47beabdaaa527fc0ce88714a2a7af375384d3bb74058ff37bf080b,
0x0a1a6e1eac6f067f813bf9cb8251475a0bb2626324718718826d90717b43b56a,
0x9f2d9f069eb1c6eb35e353e8dc5ef3ec2e4c96921eb553324fada9f76a21cc4f,
0x1bb7cdd51558f1570dc17d543bf78b901d67fae20118272b4f9af040684b9763,
0xdeb4b214de8d90e3f5bbb0fc5723e24c8cb5d4e733d02ae3c08dffbf2516a170,
0xcf5ff8f9090936fcac00eaa5ab5deeb274be6b953ea05fed64c2a5b1ef006aa2,
0xe766eb6c1932329eb6fb4b74ff3aee342b23d643bfed9260a33b7e78253a31f2,
0x9bc46f3c84fcf468692f85133f42f3d2ef94272d185e7af1622b2b8797681955,
0x1ef41c79e6bcd4ce5dc9b5970f04e8fd3a89cbc9d66fd1b966496bba53b5eea2,
0xc7715d66e85f4eff3d56824449cd2faf045352d45c3a11fb3650b281538130a9,
0xee529a4a5356895c31f93ca692a54414854b856b27301636a1eeb816f13d48d1,
0x97a4d230aad02b175072120e5b3436cdb111c298dbc0c7c9407099456053fa02,
0xc0d660a9463f633eb0089fee8786a7d2acfea8002dd9eab816b94c197397b5a9,
0xbb955c4d0c154ff4936c5d1f4e40e78941bd9a0dab4bfb82899ed10ca4dbcccc,
0xbb127913525e4d68dae4ad1ce3729898a411fe888919dba90b96a4f5b116286f,
0x72bf3f421bd42c41afb9d019650080c5cb16e170d300285d597ebd61da705ad4,
0x34db6178f891375109ddf066bf649cc90ffda67b24f0b2dcedcae39baa7b8890,
0xee9d40b311181b9a74f236d7c9ebc03e2ce718c8a1d8b10e6f66f80cae43d57f,
0x22eced8c71bafa9980579a3ef205b9b4df377fe46ac2d753707ad6fea8df1e23,
0xcc330a2a40cea686279062ba439a6a8d7b83888495a280de38ea2a29e5ad851f,
0x219a728ec5dd515b9c37468c4182b17ca9ef6dda8a413704b87aff6a46ecc580,
0x561a226bd893f85bc4bac0cac1f670067197028448e6a4f9206c87a7f4eb57d9,
0x4f0497680aa7b6aeef61615e1c89b2bebd428111b44159a015a1edfe14ba4faf,
0xea31e602228f15b1f0d42f8d150b420e6b3059c0766ed0d9e647f533dc4d93f3,
0x1505a338c948bd322b8d01edc77c4797e24ccbbef003a4328a27f135de25be3f,
0x24978f44a92ae84f181055f70b0c56e2db3e8510f19486153d3d4db1c6fc3159,
0x415b84ac5bee78047a9516bf1449fa64ef96dccbf7cb2976ea9e4eea0ba8c70a,
0x42b86a965548f5261ceef1a9842569ea6df516d67c5ecfab12af08d9e467b5d9,
0x7fed5d196c46e6625ed52a35fb1e59ae23b0bc42682589778c63c5edafe2505e,
0x7b475da8919e54844b21556fdc03dbc6208d69ab6e184b400644848cbe92ece1,
0x02d900e304141edc7f65944705676b9abb4b9185fcc2fb05484b71945f52f4d5,
0x2bf9e14cd252e197926deb873ded7c03b8315483600966394614b2a555c2a5d5,
0xd813cd28df184625d94252dddea1af6fbdcb0f596b171676df08cd255f542992,
0xac0cb3e4e5b346897cf8c06a100ebbaf36231c0752fadc73d3f453c4528c3c73,
0x29ba9304cca535ac287360d746acf4d8f43e145a192a9c4af716c204ba5f70ce,
0x3cfa99c2e647b905be6f8f188bdc25ff2d2b91649cfdf231c1e168e2293fa2c4,
0xcf8331be45c8b7b843f5a250e166f4c704094d8555e6c4c24a8b33f1718a7ba4,
0x8fbba85d755e659cae5a4bc105e79f2ad64b1db0bce604c9ee79d47b42dee5c9,
0xc64ba167a1e2efab22668cb86a1d7859163a181db81a439dea408a7ec4df0021,
0x05f6bd2b2da764ba4bcce777270cbb6f07e7df7d9ffeda7e2c149e886dfa2e28,
0xb2a43b7f0c7161e21fb791acb1eff239e0ea15b10054de0a8a41881b28259ef8,
0xd6d6afb054beec7a75f2f9a2f0bcc348dc03cdd883c07e700afc3b7fbf791a0b,
0x8677a9cd72232acf159b5d1cf22b6cb12a0e8a55a282648a026d51b9bfa290da,
0xef15cafea0fb50c95689b14eeb8f65cf6fd357f4bf7f330bc0bb211947792871,
0xf95b465a260f5204e430380343615e56d3ad12a2344717507e9a0ecaddd3cd80,
0xef07ead907cbf0e653b94a7901f7c5e22b9a07ac64940853347f8fad4d841927,
0x697d18665e7814936c0004473e48521f19d3df59e3ea08e1f73d618a66d7ea43,
0xbdaedd19afe7fb006029a5188526b0b8151bcfb94c1b9ae95eb649369e786d11,
0xd109569caa2dd1f823502b4bc6a43689ed9f72ed56b1a285cad67f5249eda5f9,
0x009fcdb1840e045d5b141f123abc8718d013175f5a42faf3183fed48b46bf05d,
0x37bcb8a542f561ba537bd935685dd84630d14fb36a22f9fab645a3bd6e30c708,
0xd51a73cb8ae979874fbabfb6914ab9e6924f2d0d44680af88ce27977871367a7,
0x4af6fcea13b1d3a7fecec5183b86a64992bad775f27d68b60470d65173e9e741,
0xc42c082956fb4036dd14d2375801355a7702a143042cf06a01f006fec52f63df,
0x8dddad8bda597236317f1547ab2e8bb50943d74ba2c52b010406717cc9b5ec3b,
0xa6fdcef115ce969eef2224702299219b25e9bc1a2acb42eee7cf2634253a9dc6,
0xee8cfeb71af3efde07877149291d8ba4d2e3101b0b7a6c741a41fe8771109d38,
0x9eadce0ee48273d1cd9662753e44a01ec3bb6c6269c247e5ac7b0ca5d2d6fd90,
0xc837ab63e80abd27fa3353c3974c5a2b7bcd979f68fd0f9bbda96f176cda96f6,
0x6b9cac2d45ce0a36def870c45160501ee7b7c53d805b80392d186ddcd993f1d6,
0x048a50b73f5240a6f0adeb37c9b599926e1e0a442e3da14ad6eb4efe0dffc2e8,
0xebfee3df0b37beb81df5e58e2c29ceac61d80eb35dcf97ad2e4a365fc7afa3eb,
0xc2fac4532b0881bb267f7d3399e2827d59572486eb35673ee9b11a24d2dabeb9,
0x32f4ac0c9ad04e9603c09afb5719280b9bfd18a072189ec6ae7b425a3e332a46,
0x98ce2c7978dd440e1cb5ec200f3dcb24a41c1c18c6f8e9c1bc5f942e293b6d2f,
0x90872529a2d3ea441eed3e0dd8237df901b92a3e938acb89bb56eb8966d3f1b8,
0xb79fb65f3b396799dac5ef83ae273f4e0ad5c8ef2d0c1666db2936422e8db53e,
0x7f1fbdd1f6ab31eadf0b8012d68ae9f2299b2ebdeff664c7a76c99ca59b8a958,
0x7896efaa084194567f5f1a0155d0d4d571f105ebdbb3e323287941517810d7ba,
0xc047e35b7fd0080ee9c6fda271b8ab054d8ca3afd542cd6db9c0eb8bf1b99ccd,
0xd7199667e4fe88ef55f3845689e670b8f1dcf1ad48af90518fcfbc0b0d3a0506,
0xc60d7e78cc35aaf36f1bda4933ac441d6e5011411e165d8fdfeb62190d13742f,
0x5a8fc4ffc213b9892f2390e760160b4292cee4727ab8402483e99469aa5a537b,
0x130ec8edcddcb39d382c60b81357b809443257d35f7fb5f7a620d3cd85c8411a,
0x1462f32c42069a49ecd0ff89d9b8ca6903acfb1ed34969a5ea3ff32478c49de7,
0x0e400fe520923173c35dcde6afeef27b71868539ba26eed73adad23cc1ffd21d,
0x1d8b92f9daf96c3d785c564f742b912dac842bddad8386d7d5b90e56c8ecb96d,
0x37fdaa0dc7319aa5ec9708032569580be4147c7d0c5a7dde646bcf2da7529890,
0xdae55b124b3a64b41b9058908c31623df2f753c9473dd50e6f916878a9f669cb,
0x40975bdf8775386a42ab199a838cc870f20192c8a5a5fc2b2c30bb7a4a788e5d,
0x09bdce03b7d6014da5e6a5ebf0678bf9cd74d7803ac0ae39f846119400df8cee,
0x0240fd470e6ab28a9781d6c7678e53798a21d2bb970c12f8bb68e9268231f717,
0x950c17876193f4cc592b91a8fc8fb1cacf390a139bdcc51c0968895b2ea5fefb,
0x82920c7f782649b922d442c85d6785d469488d86362ffce7ad171a0b3d22ed25,
0x0f3c30edfdc7e6c6da6321673d100854972be47c3737811d01de9dc163c065bd,
0xd828a3185456c6b2687e1c375db095e3e2573e63d70b10c4bafeae2042b06e67,
0x0f99d60c135aeba05c90d4405557f3530a4a6f56ffc8c270d356c62b127c81ef,
0x6dd92970b2933b0842f0fedccb7a9a9233cdc15d72bceaa6a087b0b902bf6d04,
0x277c61ac5138a2e520857ae595eb133c5bcc93186b83f3c50d30f6f30eb13c84,
0x60f6d8d9e1cc5615b63ffc010a85918ac788ef2a1043656a49333388c62d4df2,
0x75edd98367e7c0ae1dddb98dc3f578e920d009b9847e56d0402dc7b772330ec3,
0x4d1302df9f64530b92a2ddac7a27283a34baafaa8a124fa83c17fc9db0c51b01,
0xef67262558343f035e12c1a1e2b4d700dfca203000e4e8859695349f5388e0d9,
0x1edc64cbc18638ccc528294492df1673f8609133487cb2c5d336cb983ec0e23c,
0x845f9eb9226b9a027f8bb977fad767d7175ad2376a8a30e05a7cda9d03e33165,
0x286eaccf4876643b680bf71154ce7ab52323449e401ebd3ca38f5e6c86960c33,
0x4b97fd63e587ba1bbf7f7f000c514a4db4c5bf25acd87a31874ac4a1cc9cfa45,
0x028003c645eabe5871a911543de3eee72a3e14fbf63d421808c30756b0a535b2,
0xef72a90edf0613a49e6513dc08ff1b474ce8dc60637362ac003d00f8464eb2f6,
0xdbdc7d846636bbc4e2b5e0a4058e1d502d1fe59d9e8cf25bfa90226ef69df200,
0x68f63f73703fa2e197616b7af997c0438a6cc7475e4cd1b8777d41e8a16933b7,
0xde6f640e4b109fba4c204a3f0fb17d462e1baffa3e745369f0c78dce2db59b70,
0xb65cc609089914ef56edc199bbb7d0708ba71e4a4f91898ca55b1cb8923bc7b4,
0xcac6dbc2d937ee1d441a22c250f7982d62328f1a80fa84046c04b893ac8f7d22,
0x7a65c50448448ac72296bdde5b2f241832be6e8af5fc469bdc2c6db67801bdab,
0x911ec952b8694f42cdb2057398383342c68c425c29d0201849f86a451fab507e,
0x8edb27568c165cb9ecaa4f30bb31b60ad3cc4e16aaab0d2479b11216b0505e98,
0xf7e874ed64e3a59a9e6129a4d57e5be6902893be6a09e0389f8866c54795d7c7,
0xf2085dc39f350256f99215a3094b33ef4b9a98b3e86eded1369a8c0c346f5447,
0x6e160771c14785a7cb259577367a167da7b2eda5d70fc4053b56ebb6e8bee825,
0x3fc521e2ed2f88d47b24e71a42d030cbd48383f75d47d4ae2bd0d1380cbc47ec,
0xb51bedede8b88986a693d8c12e4edf08e81bfff72028434aece17e01f6ca8c78,
0x33f29780285b863d59733a0f296cf9985335b2bb9e047081fb3e097d0724f74a,
0x61977c42e1f71573d404913fdb11a2d2643536520e7aa03c226ef4f046f09a40,
0x025671275c672eeea24c3ce09e835409c67770f9010e84170b298c5a69c61f4b,
0x75f8d1d7b66304eac10ee2f4586146bb52bbb98ff0be2b8197cc4d8b14a92ae1,
0x704e2557af4b6d2dd7d82436505a60562b7351aa179059ca94f74ecc20a29ab8,
0xcf18a49cd56e298a6c84657ba4f78f78c61801790bf6cdcb062352df1d086939,
0xaa7b2ab865ef4964a398412131e62da9fa6ed3e135f9700ceb4734b3b56c41a8,
0xedd0dca4feb25755536b9fc08c49f8c3c49c124a725c7f2090e2ad1160ed58c9,
0x96da9a07a137660d6e60cd916217462a9511aea8cd078c430a882daf7bef17d9,
0xaf263671c3407f1331f5d9eb93572732d13a9c658458233249ca958866bcb9a7,
0x99b23f3ecf5a4786c87075f7583f5ae9c0545533763d06c15a50e14a9c238e0e,
0x1cc248b1694c3d8106f2b5f05ee5be455244596045f4ede8f65dc1731c3a1542,
0x0ffe9a55425766e34c175c6745d979ee4f8dec3c9f0be810dd79cb904aa36392,
0x6ee19dde4e93a03085c728d26e7cf67e1f517fe3e004a27a39b83a8a4b2aba59,
0xf829f757ac8bc270be51ee60f0f5796ad8dd707409d2e5108f0146176c3a9160,
0x0b6cb2a1f2fde02af0eeb646e31fffa636564daed562b766e3f88b102ae1ca07,
0xebb24fa20f6a626f6080c73c50ccd950ead4a134010e36a3649fa38126d42821,
0xf3dd9ab4131c40ed4c169715efaf2038942030edf84724344f43c690368bbdfe,
0xafc37f099831035ce55b0c0a6b5f8f2ce3eef0499d82ae1d4adc565ebd643966,
0x4059f2d3dfbdb2b9c4db1d755e91ed052ced7c92c5dbc738dedfe51d63b4b00c,
0x53d89ca80d9aa46b83830c4c49aa4de84ee1279a9d12a5b5708a8017385d460b,
0x4a0724dd1b56cc9e22cafc1bcc1f9afe193829522b8438a1183f8b4c7d4ee93b,
0xcc67b4c216f7ca590fe3239236c273558e4c67d272946aa652cc8f64d0d1d675,
0x756630b9c30969adef4d3bd75334ab3188a92090b6d5d2e95d593729a61ac0c3,
0xc51c41afc7a7c772c553c4d80dedc98966a23e3daad69bca87cea804f05aa012,
0x45038ce21a993fde4b1b06eb86566b25aec20ce7e46a11ab9e187ff3b74cc0ac,
0x12404a9617d3c902b914bd20b15e0f307399f33c6c0c0a294c99d65fa1677237,
0x397a0252370668e464e4a00f2ea80218ea0c1d980d095fe971361ddb5e08fc86,
0x0ba779d88db8a6bea7e737ad12e08cbfddc8bf1b75448f1b5e50514a3564002b,
0x869a980c3f4765838b890d0f161711026cf207677aafa18327637b46da39d917,
0x9476b39ff0014278981cda7f6440db452a50f39757355f2c6ca2f601bc061a53,
0x8cd3772589b43f4321553c3b068341aa802f5daec00f8a31e860097adaf1239c,
0xdc7bc1343b4a9a5000e83fd7a366f619f2ba7eb424502d6d874db34af7af384c,
0xa085b2650985327dd6ad736345084284f116963c8ea9fbe9254e6240b13eeb4a,
0xb387a891d5f76aacbd186c08727a35260d6803b16e76439d542e91a8f45d897a,
0xe4654e733d4503c306418a4a1487d0e775a3a77ac06eafa1485d6e79b5d08580,
0xc523d973d7fdfb0c5630884b20288ef15bd00802a97aa0b225df9ba1ca2b5463,
0x2e3b50ff89121202ebb728125bb6abae76c0544ca4b496e6e207cf8ce79a53b7,
0x68729d0b87f3ff1f679169f3ecc7bf32035fecc1fd91291daa69512752b298b6,
0x3c0b05909f8064ad029e5edd774f6dbd3a74cc93dc8b0c6efabcfd8395a89486,
0xa95a6dc19f8b4934a5c947ccb0166a424be4bfbbcacf93b8eb228b780f3e3564,
0xf412e66c2f10439e5bcfb94aca173d4db126b53c07186f4578f30d4c502b4f17,
0x0ae16bc39b989d06eb5b2dcbbb6e917f7462fee2934a98b822142b54ad9e8d46,
0xc30f16fc3150d4e028127025a389b6f952067a6c216eefbbbefb080c64c021b4,
0x785eae4e430f517f33c1266b661276a6e986439022b257ae635ac22630ec7330,
0x93b3673983157ce91230e30b13f4d5003ecc7619efabfc1441324d4439417bd1,
0xb0dfed624381d7b4786f6478dd23475130b35b460f96e56cfb3642b5d36c7f26,
0x659d8e15cf2f77ba781a5d63306bd50c389051a365d4f9323b3b95b3a3028602,
0x2f5e9e57ff0e0b2a68f0aa74418fa34eacb589d13d1177cb907651671a9fcddb
	];

	function CheckPacked( uint256 user, uint256 i, uint8 j ) public view returns ( bool ) {
		return ( ( packed[i] >> shift[j] ) & mask ) == ( user & mask );
	}
	function ErasePacked( uint256 i, uint8 j ) private {
		packed[i] = packed[i] & ( ~( mask << shift[j] ) );
	}

	function Withdraw() public onlyOwner {
		payable( msg.sender ).transfer( address( this ).balance );
	}

	function StartMint() public onlyOwner {
		require( !started, "You've already started the minting." );
		started = true;
	}
	
	mapping( address => uint256 ) public mintCounter;

	uint256 constant price = 2e17;
	uint256 constant supply = 2000;

	function MintMain( uint256 i, uint8 j ) public payable {
		require( started, "Minting has not started yet." );
		uint256 n = totalSupply();
		require( n < supply, "We're out! Stay tuned for more REMILIA productions ~.o" );
		require( mintCounter[ msg.sender ] < 2, "You've minted enough already." );
		if ( mintCounter[ msg.sender ] == 1 ) {
			require( msg.value == price, "Incorrect amount of wei sent." );
		} else {
			require( msg.value == 0, "Incorrect amount of wei sent." );
		}
		require( CheckPacked( uint256( uint160( msg.sender ) ), i, j ), "Oops! Looks like you're not cool enough for this." );
		// ErasePacked( i, j );
		// One-based, so the TID range is 1-2000.
		_safeMint( msg.sender, n + 1 );
		_safeMint( msg.sender, n + 2 );
		mintCounter[ msg.sender ] = mintCounter[ msg.sender ] + 1;
	}

	constructor() ERC721(
		"This User... Banners",
		"USR"
	) { }
}