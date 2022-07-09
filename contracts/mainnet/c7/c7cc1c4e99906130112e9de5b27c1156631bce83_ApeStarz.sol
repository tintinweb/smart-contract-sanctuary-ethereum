/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: APSZ.sol


pragma solidity >=0.7.0 <0.9.0;



contract ApeStarz is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string public baseURI = "https://gateway.pinata.cloud/ipfs/QmcdvFkciLNnGqvKTw3aDDmR6BpH5s3Twe91pygYzqoaeT";
  uint256 public cost = 0.18 ether;
  uint256 public maxSupply = 6000;
  uint256 public maxMintAmount = 20;
  uint256 public freeMintLimit = 5;
  bool public paused = false;
  bool public onlyWhitelist = true;
  bool public freeMint = false;
  address private payTo = 0x79e8Dd74D1D537A46bd0392aAAE863fa1d193eBe;
  address[] public whitelistedAddresses = [0x574Fe052D19Ca31b13946f9e293fc4e2FC78bE10,
    0x9741D6B0f5B4FbaFCd122b33bEC1f330a99ACD9D,
    0xe3e773b1BfCD862AdAd74Deea1629EEEBa567887,
    0x3DE58DE90893bB3aa702157f9D0b4E4fF2c3c275,
    0x7D2Cc34AA09C72545Cc770FA16DD40e5e1e70Bb0,
    0xB23422f234C92c2B1c87D4E9A336a40eD0352Fb7,
    0x5dADD6B09255ca45C6F1E23C95C375315080a33a,
    0x107fb3BBc1b055cDe15F31D54bd3bef3629c40cc,
    0x4Cc864dBD66CE3EAfC6a52B30cBd7c6ec0ae56cd,
    0xC032A2e2b3C9B6780B950aC64649C6cDa490Be61,
    0x25B7D9bB5AABbD021428E013070217B38EeB1B15,
    0x12BbA87579A74744Cd7a05F0E402c53fB2F416D4,
    0xC9650b5F78d0051dD35634B7453CEBfFB3c35C6f,
    0x1157C7277897AF5B19853E39b3C8d6244656c6a6,
    0xda3130Bf3bA3D643Dd1BB2b1c0B08596D56C082E,
    0x0ebDfD75d33c05025074fd7845848D44966AB367,
    0x2a3e805394948d61699Df47BC720DcF9Ba476Cd6,
    0x9A82F795a8B7FaC06f952d3397E2102Ff94FBa46,
    0xBA11d515CF30E116b24855bB5868Ba7302c28add,
    0x0D5902dA80387A65eA99D9E07047E6b50724F09a,
    0x67727b73d3680AcF335763FF2f465d54ea8869bA,
    0xF8B35BbB8408A847026EBb8e042cE13Fa8d51832,
    0xc6C103a2aAa307125A4241C751b0A59A684497db,
    0x80B54EabcD878b6069a0f1ae389Bc9c8462587a6,
    0x2581C86ac21590b3114b94346Cb017d201f3fFDd,
    0x43B418282bff9e5Abe27db5F1C6D8e9ffDb38700,
    0x311f9bE714341ef79a2B4462ec30894a5D1F0C65,
    0x643c3b2AEf23C85D78c3b3C035DaEd82fBe2A8e0,
    0x3986cA50F1efB7aBD1a489b6c902B02bf5851B84,
    0x3A25A834eD332d93EC10a7d4b016dE6BA7B29230,
    0x4C5bBa599C38fF68F487044a0D66A7Ab003e7997,
    0x32F92aAaE2BF961c30b1372001CDd6B83c929091,
    0x7180Cb5020eF8f11C0B62dd013395C5D00643f63,
    0xE7fa6E7F809B9293DcD7a26c15684bF206fBDAd9,
    0xA0Faf579daf391bB845e9C81aCe25089549Dca91,
    0x4893a3860954559E4F87118F316A0cA3b9ec0010,
    0x15f308184F7f89a1B9359feec562bC08ab79B583,
    0xC5FBe21d08CB4c4639C5E6491852314372eFb7B7,
    0xfdE52F4178C6E0D4F691Ce2FCd303b90ED28ccac,
    0x9583fFFf0495e83F396A1843e4F568fDc16525a5,
    0xCEA3C3B0c56e09b4a6DB1c0F2ad68D8fc753bd99,
    0x997617068ae269Ed97F404B1A0D055ffBcb6E740,
    0x38d9CB3bB30353f8E8A8f29DF8368CFCa747D1dC,
    0xf8AfA2150c4871c246CF9Feb638C594603437989,
    0x270dFBd9D0024F1733077F9cC99Cf825fE23c8Fe,
    0x680180Da3c5e8c7B1e527E993939970C0CE0FC3e,
    0x4C8B46FD6bD16dC73A68AF60B4d7bDb17f34948d,
    0xa9D418D86A1A33454A4cBe5084dC98f6E831600d,
    0x8E718bc413eDE636bcDABe3C665F7F25fd84910F,
    0x6982d7e48D445465363bB8B7F0719e1e167d1b4B,
    0xD690A694360f5f7f069E431BF72faF3f71280B4b,
    0xddb96eE381720dcEF4909BF68711390e6165Eb6F,
    0x5Ba1606dB5b9BB6739D9e8D18948C9CBDD24b081,
    0xbB22379814a439e439dd99a74ABE7ED700aA7DBb,
    0x4C173fca10466A1c1cc6999662eC09c1fF2c4c14,
    0x29D0b5dB507D5d6C0BD0021fD7e8eb216e2862CA,
    0x3278E1BEd8dF88Bac4b2660c961dBd5804AAB19C,
    0x81fcd30F5AB08b176fdAD58a7e73fC528588956E,
    0x27927012FA557073EdAd4e46374F72d4791767a9,
    0x3C95c8f79C83399702DF0a237813C986Be99C05c,
    0xf04683631f47B3e2C2493Af4c1B44dd3196fBb5C,
    0xF025d82f9448cB87F001075B650baf6993c3E4c5,
    0x0CC833E3216c8f3dAF0F43C0FaD52920A1816e59,
    0x15639B624b43b888415B6A84FEDc439e882D1943,
    0x4B39338Bd93C5a1DB7257Edc01ACA101fBA28A25,
    0xbb9C5A9Bbc00473867f27C7DBEb70783d3Ef6e16,
    0x67019F085353000b34a848b2BF0BBe4187eebD5e,
    0x463aaFd38fFB9c83a1Ca19950F71007BB79e482B,
    0x0eEf056BC43C93117ce061bB45139dAbb2B7C07B,
    0x63fC81eD1E1eaB3E2906B578ccd3097970852a1B,
    0xFf85B0b8bE7C584F3DE4F17091913936e492970A,
    0x99E6D549DBdc382e99F9B7d3D0735f2CfCa71DaB,
    0xE356b1b10b17639EeB43867d0A86b21653a6eab6,
    0x5443015Cf063cBCcE45EFd216dc0a53b7224fb15,
    0xA02Bfb23935B0ABe38cF5608B9de03D74A47ED39,
    0xDabB81aF90a1C4520d323B55a82045C6262967C1,
    0x36bAe8e1a47Ec23b039B27537d55B105Cc5d602a,
    0x8BD59536C93d97006b4540927579c892B3bEf007,
    0x78e902De210934299306eB7d2e8Cd1EBd7cF656f,
    0x06B19CeCB29dbFF18204133ee67b86f120dEc07f,
    0x20aEbf0C634c5ad3fC9F861B9CF8c173F2e01873,
    0xc10CA26A9735A63D71815C79911DE25B07e03530,
    0xE6fbf74Bd85AFD53e66FdE4D1b38C6018305DEB4,
    0xeae54f35170520f27ADD981bC80e1cf284B36999,
    0x813A7Ae64F7be64f77595341ca810E44f88Dd925,
    0x0Fc8517F0BED4680C3c0EfE05f8AF8b7842E5c4b,
    0xB3f9eEee68097cCa0963fe6C22BE244D8006Df8A,
    0x5C49d2E868B62B0312b6aD77e6d623F4bb03BF80,
    0x135CAb4CA6daECab1C1fe224Acae94777f7DEAf2,
    0xb3974204cFfff0f3925D40A9Cc474109ff4Cf4DD,
    0xF720D15B23BfFf5C4c050aAc23f9E5B481FB6a6E,
    0x1B55c8b30eE78B04Da4E3A75752Cd0068C80fB92,
    0xAF75Fe9a22F44137f61D9059e1eC3D062270552c,
    0x018175F2634b00fF70C97F692D7fdEddD85b0eE4,
    0x0C7484fcAA3706962AE1e4f88A047333034E19bC,
    0x9773b5F08f6623F807dF6c0d4cB52047C2f524D3,
    0x1B4630ca1C7d34294C3dF86A02222716C1Cc904b,
    0x41b4F071ea4045F9C0B18bC55282A9b25cE659b9,
    0x787d92ad51E3467cF3F66D814c1e0dd0c0D9BB85,
    0x68a6766667CDe5Ab511568a18f3bba25CddF64bC,
    0xa84AbB4F2fd21b858B3c7823f5301755eCd46c26,
    0x60FF95EE56fa88c156634C90eF3FC1d2a408Dc07,
    0x617eca02EE345f7dB08A941f22cef7b284484e2e,
    0xc719FC82aed7f7F0263f38418909CC74a47623E9,
    0x6540758aa92f255D3e10f978826f5dba0a4C7630,
    0xe023DeD883D93517588cF325EE8B8b62Eb18f3E0,
    0x91914336f009603dA81e9403f53d7CF4A6e0c5A5,
    0xA68300cc9F9C2287E88B933Ed7E65eaE710Ca6eF,
    0xEF1803411186B0aBa8C7bE9425b25063Abc6a3CA,
    0x9C4334a99F5773E7BBA258e329A3D2FB3044385e,
    0xB7247a4FB7B63B37727645Fe0B08a8AfDa5Ca4bE,
    0x8910113Fd029C6a2A441D3C2d737E38dE4CbC6Ee,
    0xa8eB783538b177631231200e459eBdb376fA9cA2,
    0xD2F2d8a322Ea2b865D17792b77994B2df1fDAbFE,
    0xEBbFB2e6c6e6Bb9613EbFb8d5144A593Dda1c763,
    0xBA190354f3b7D83Ac287C3668FC853E7282d9A6E,
    0x3D64FC051CA5BB0842C1E824bAe1e6fDbbA4433C,
    0xf787EC2cCDde1688C60A3BF98E5c4F4D29319caB,
    0x1959a2F7e85391d883E35B18b01ba007A4eb1497,
    0x9882F124839fBf61903d8ff857b4d7433195d9f3,
    0x1eD1aCf5C0ac4663be4DF159bfCa5525a537BB9E,
    0x89E688f4be48480B211EE09c9bae70a92927fF47,
    0x7bd443fD83Bc572511148218441Cc86617db7E54,
    0x2B46AD7fDA1BC44136dF9f375E2d233E307f2725,
    0x5091F93aB457f8b7CE603E132bafD62cdCE38c8f,
    0x5Cfa4E2819E22cF87822f1c817660D86F6fF2DE8,
    0x78e6A5849acF5DCbF951A3aDBe73a3078387BAf2,
    0x2f48D5519989f1667c0C6542B9DaA682Fe791828,
    0x18aa1eFA28822B3001013d0e11c3a7C6E63DE9F4,
    0x0526B2a3E94F91268eE3C4f84b4F60DB1160b489,
    0xB19DD033e95C71311D8041C2664Ce38786B9aF4E,
    0x961bDA7A5Bd0fD05B88b83c6DF00c4E267A5fEf6,
    0x21fd552dB4915Dee608232308cb482BB22daa646,
    0xCf7eA9c780262c485E71AeF58eCF8fEDc8f88525,
    0x97605d6e7eEfBc64B4CC7F736879A1b4578c9fFA,
    0x4AcA23DAc423a307d1DCBd2b1e7997a6B40f88ad,
    0x0804123183084f62E08b2f61f0C3BeC509Fbf97F,
    0x070b912a286C8fb9E6E156D013fDc310817b17f1,
    0xa04f9F497AAF27Fe9759cc136c647798c2255d7a,
    0x79911647dBBC065F3623DA8f399e44079B6e2dbd,
    0xA3fB5F903C256c02A18854D6811bD2Fe60d13a2B,
    0xA999dFd18e475cA23211C57d596b036447e9B898,
    0x40CbF4B8F44E68133EaCDF96a99B36fd161FF763,
    0xb5619Ba9D7f67254e4C53c8bE903d951B551C9a5,
    0x1b1B138e142291B30573cb3970Ed3d10D7c1d581,
    0x105A51de9452132afE44fA666f3fcdA94B332904,
    0xA15a91FD85B9E31517c83e9eAa5221D4Dc190836,
    0x45f280dE434014d6C45a4db715312c0303FC0d63,
    0x0c0f9bF520936b35Fe377004624F8A33E5263240,
    0x540bc21784a3bcd72aB77C830381f3EEE4548A5C,
    0x417081086313B5A2225924DbD5e94f5A78AB882C,
    0x81107DDA531fdEc261B41614eD8403bBBB81aF4C,
    0x611b1D3B3B9B37782a2D0Ebd12bF9A9CDCe3Ac68,
    0xD17cA12B3A90609725323916026c649cFbD07061,
    0x3521940AFD29E49EC2DCDA04373aa4Fc2E932801,
    0x5E3D0C70269F4937f812c7A82dE29993864ba284,
    0xD06760aEDA369D76Dc990E37ac85b1446E4d4653,
    0x4F63879059EbA48Cca0ea856Ce30084C7FC7248a,
    0xB07d58Ceac51C884AC57e5f82E995dAa6258eFa6,
    0xEc009e60372839613cE0A5cCa9D28a6F38e57244,
    0x74D1F9623B5d007Ca8B74e121e2fdB96606E0835,
    0x42C5C49aA153EBdd90D5f0d2b420C8BeaD24E6a1,
    0xB253aDFD5c63c5dd136a9875a46FB63904873D2E,
    0xdDc94867f51d47fb3487677B294ba7618Dd9caDc,
    0x8D1c27Df742248aF2080C3e7268290B41a2607F9,
    0x9b805D4265F8E77FD98A9B9807e903EbF3894359,
    0xA0D15e3853BcC3000F728508802E5f213728BB6c,
    0xFC3C6fa1B191FE5196f8B1D0BeDb14eC42BD5A78,
    0x61f3A12939f0e49388De9df049c0cB36B0033AB7,
    0xB54F20C2aD1bE9ACFc97e62EdFC6C91FAbE0536D,
    0x30E7c4aA0aaB8Ce55B44ECDD31c8fd95FfCfE4B2,
    0x084bb55284a1c2Dd672B3861AcD377Ba0e5F04d0,
    0x5Df4678dB918Db3136c4a9DdF555Aea24576C3c3,
    0x2FC420Cf93988A70061E3EdA1353f8fcf471b5E1,
    0xDb0F87De59a38dfF7625933722292A5b38f14F63,
    0x6e2F5648A57f20573B6A6a6a5bB36Bd5361b58Dc,
    0x123e99070e9Cb7d196d61ea8A0E5ffDC5Ff43069,
    0x464b8209D20109D2d514B5e6dEcb1cc4829f5CBe,
    0xf3B4CcB8ff8D823fD8768Fa966BfA3f3957034E6,
    0x8b19d2D853b153941A22096b2722B6F1972D60bF,
    0x6da55655D7B25ea5BB911121d15dA06393A5a4f7,
    0x61A285519fFF83Ec1b0273aCac299d9dC687510d,
    0xA5850c36d2850237977A61fb3f955Feb8Def38D6,
    0xe2fBD823cFBeBe787cf67c4175b24Cb3E92A0a5a,
    0xc77595D885e8578BC46db0535502203C51aCcf3e,
    0x32537b729B344Ad47581f4Af59664a7299402F74,
    0xdD36da9C39F15859d23715bAdE79540Ff4c923F6,
    0x15eac7BDbc801EE41c8b793eA924e21Ff04fF7c2,
    0x9837373a08E9AF9CFad1e0533d156990Fc9C1466,
    0xd653DFd2a632D55Bd40810B6ba83C47b673e1640,
    0x4D14FD32b5486C21d04C299B8c1f31EF119e09B1,
    0xd1f84d415067eab285f5E0B3Cf16C04014625765,
    0x2B220D16C04764034485Fbe8aDBDa0F5a1EfDAA9,
    0x4fA0569a9952028303324137d3eA93E976681fC4,
    0xAC6A5BCE1421C478B8538C4EB5bf1b9a5116cFE3,
    0x9C274aDa02AcB73d496d47b9854DB9Ec59583a4e,
    0xb955ae2ED48C4f70e3e6b6b9CA41Df8b0fBE1805,
    0xa7f8a3deF4Ca9FD6f96fa8fD60281b46fA46BdEb,
    0xF6B5e83CFf9773470fbEA94d79DFC81736bF0845,
    0x63C4a1c6938CD921e3B595ED5b841Cc8F4971Ce9,
    0xd1108817cFeE56Be4F7f138909ba150C9265ee0B,
    0xda3665dd611E2652A5749F5F10e608314D5520E0,
    0x3F69e32bF9C555bC44cE2eB877B14c30fB68fdF2,
    0x55B0813eCfae02e588639E72E64A86c9e377409b,
    0x91322aF5244b658f9E0034f6877922833aceaCbA,
    0xDba6cf43ac338d1687a1e3bdaadA2Ce018aa2937,
    0xd864baBeC7bD14E09Ad05d42BA91f58b88f634B5,
    0x83aA6BD689d0e63f92F700F0d8AEce8e793eB4Ff,
    0x70B2dc1779323E33b02F6F9C3831c5787eCDDf4D,
    0xFa4b4e299F59A40Cf8E634A6cB4Aaf8C4Ec5d23A,
    0x8539F162877583B273ec8b69D0f332F9616843E2,
    0x14c1Dd87a317128FdDad6e873621196B8F5301b2,
    0x071A112b7cf1664Ac00bbAd69b30ebFC16a1Bf9C,
    0x7A33A334fA88A639734cDeD4708C82741BC9f0FA,
    0x5e6C77749d653b443EBa6cFfdA24D9Efe969459E,
    0x02515465a9f6F4Cf3008A8636bC4023d51fFA2e3,
    0x0cebA74453E4d558C7AACd347074cFeBb7b2F042,
    0x5F833a57BEAb228675f3e10A31c6ceE067C6b83C,
    0x0147A6A3081570002dBcF8bCdc4531903EaF0108,
    0xE8fF95721fF2960ff8a03233d62c022ed4c2800E,
    0x29F1B3EA36c4aB31Da1d002e267EBD964f2f3b41,
    0xf8aD5f2aDAe468c3ded4AD0B735d94F92bd34600,
    0x31fBD8aA3B73b6dcddD1c752917a3eEc303FFa47,
    0x8a43F226c03C7eE6F8565764A48a35b9E6923004,
    0x74388BBaD68345839BF223a9FD72A0B3250322d2,
    0x3d755D91FeC4D567cc8297F041e656A6fE8cA05B,
    0x9111Fbc3C0E6a9214cC42D8c6D4aBdB1f4DA4A27,
    0x8DfD586Fcc4A837156Db81a3FfEFBE2670a44827,
    0x55167b288296fd3Fa49E09bC19F60F4761F66065,
    0x693D6a5a3f424f2b72720F2854C6f94384F2c509,
    0x4f29e28892303eeb8F394aD574CA687256a93424,
    0xF8500E1423B6016553A7a2B08607d02365F91C05,
    0xb686459F4838B631DA5C35C1c98225eA60ead343,
    0x46868bC29eeB217434C4e1F664df42d897fC30FB,
    0x96AB20a1dCFA379842C4634DC52E540f79dC695d,
    0x09675A64119bA65aD9fbae1ffFD6256F097C4973,
    0x2BA34f92CfA4D8BAD97FAc144103cC225e9D3691,
    0x34094f6C8f280F62E00595f3fEf8160AB4A04A48,
    0x2Faa7a797684E10134F768ECf7f3ba1024FAED27,
    0x9c8CEccF01BBe27fE5b6fA62Fd5Dc0693E4557A9,
    0xb3eaf2B378FFC469C4E188466D096BB3cC5aa581,
    0x39E994756c85b1d7016A0e7D50Fdb064398DEe80,
    0x16A919A70CDB4Aa73e6d557A90b86998F3b5032B,
    0xA2682ceF27A63e7237A6Dfd8775BaEC62B044BFB,
    0x466d8f79c80B08f118BdA8ec6b5825F14677b7Cb,
    0x93175Bd9BC0075Da3786a838d31e08298f6806a7,
    0x1B931C172B3D918A830266E632F885C2bEe16E6E,
    0x9247D70E4d3Db6454ebb507a6Ac233E5bD0c85a8,
    0xd322945eD27EC170cEDA193e775699647A04cc46,
    0xc656A3e3ee2F9FF93016AE40B3b60B5268fFaBa1,
    0xA9d781d546d0337C6E333Bcb74BC3c55b1422cC7,
    0x6850f5843889567BF31E5060f09C7370ceF71741,
    0x2b8C345269746dca3fa8bce1F4b06C4E5cEA3dA7,
    0x428C3A8ABA01524E30ceA6B094d6555B23D54942,
    0x09BAF41ad555Bdf995d79B9C3Ce040920B4f31aA,
    0xB2BC469B18b540BF19A3c7A6bD8D10dED7C4d6EA,
    0xCF67Cfac7b10D75EAD27CcAab3De4fA99E2BC0e7,
    0x93c55dbB0178185B3ed439d8Fa35e436994D0426,
    0x71ad49DDbfA18b312A2e32a871549Ba4fD18300D,
    0x8261057CAa54B64e8fbae299d1D4669D306Ad2EE,
    0x4E8515F97d552198643d63a3449179399a74f9bf,
    0x2A5C13fB510E46140986c73a6D424AdF1584dB6b,
    0x8927A27aB000575b86Da699b0D46d809651aAC73,
    0xC19F233A15bd6464EFf6aF3c78f70037233a9ac7,
    0xA01f7476f019b715e159785C09B22e467c9674cD,
    0x2B0B675D848e2b7A88af65693B1408D3a7473416,
    0x89DC1211eAf777A6D2b4DEb2b9C937e6378bE898,
    0x6E64489BcA2b2Ca380c50fC53Ae5E0304D7c8132,
    0x176874277E805f8FCC7B9C409805597baBf0a6Fe,
    0x4b54A451ce2aE0995970A11db972992C6DE0BeD8,
    0x81fcd30F5AB08b176fdAD58a7e73fC528588956E,
    0x27927012FA557073EdAd4e46374F72d4791767a9,
    0x613d74ed2B6317b97D6D4B7f37F5c6F6f410835D,
    0x0Fc8517F0BED4680C3c0EfE05f8AF8b7842E5c4b,
    0x153907505063ceF8254a09140cddbB434B578Be9,
    0xcE2971Ea389035327C90715D893d6252B7685f6a,
    0xeae54f35170520f27ADD981bC80e1cf284B36999,
    0xc8cD71de8EFb0777C891A9d3139B4AcEB15fB7AC,
    0x9C30B7684B588AB6EBEb04F337A75873DBa9bA2a,
    0x0Fc8517F0BED4680C3c0EfE05f8AF8b7842E5c4b,
    0x40CbF4B8F44E68133EaCDF96a99B36fd161FF763,
    0x64B8Ed6bf18D17EF4Df9E9188B7D89Fee219932d,
    0xBFDa37454E71059dBb89539c23204FDBB0DD6785,
    0xB19DD033e95C71311D8041C2664Ce38786B9aF4E,
    0xAF75Fe9a22F44137f61D9059e1eC3D062270552c,
    0xf1258f6039529F41091507fd33f4996E1e171f44,
    0x97605d6e7eEfBc64B4CC7F736879A1b4578c9fFA,
    0x100f36CDAff56754786290C046E3149F688eCd36,
    0x0526B2a3E94F91268eE3C4f84b4F60DB1160b489, 
    0x34eA184c8867fDFD6f0fab5f9eeca3b5EBd44E93,
    0x1e0207ca0229bD5bbdB8102db56CaC7fB7cfba20,
    0x8BBDE96FC16f29De67B7575ef637fF85c2891dEb,
    0x5091F93aB457f8b7CE603E132bafD62cdCE38c8f,
    0x3D901cF1EEB8bD5cB38509B1e927Ec86416F9b1B,
    0xA63e2a3C5048f3418b77B289e308013e094C48e5,
    0x34094f6C8f280F62E00595f3fEf8160AB4A04A48,
    0x13165D3831Ea562Bb1285c28fb178330f3c912A2,
    0xd653DFd2a632D55Bd40810B6ba83C47b673e1640,
    0x2EeF4c634787B648aF99c2D46B8D81Ac24Ee283E,
    0x54f4fc045a112Bb8Bf6BF805469045bbB8a57183,
    0x0804123183084f62E08b2f61f0C3BeC509Fbf97F,
    0xf8AfA2150c4871c246CF9Feb638C594603437989,
    0x7cE1b7fDb5c4C11A35857a0BacbB663cEa333440,
    0xfA5750817A1eB836a766964883a6c9809986FA2d,
    0xe11e0CF3463731Edd6d86E855964d9ae13A8624b,
    0xb2B5F013C54d40882cA48d472AB361A9F2869a93,
    0x91914336f009603dA81e9403f53d7CF4A6e0c5A5,
    0x09BAF41ad555Bdf995d79B9C3Ce040920B4f31aA,
    0x330fBF6778CEC2629c732A4240826fdd5d814779,
    0x32F92aAaE2BF961c30b1372001CDd6B83c929091,
    0x2f48D5519989f1667c0C6542B9DaA682Fe791828,
    0xc5D0E395f4d911b589612a3b2e61387CF72f2211,
    0xbB59687CA9B00CD036B12f2438F204fA8E56AFe6,
    0x49241f3585501f41b1d9a7524AA39dDd63f32001,
    0xdfe930a578C77dA3AFe7cF5Ba81A74F70DE93d8D,
    0xB7247a4FB7B63B37727645Fe0B08a8AfDa5Ca4bE,
    0xf9F009AD1B965be9ca0D7c21a9B9ad0b7942c8F9,
    0xa8eB783538b177631231200e459eBdb376fA9cA2,
    0x98F83281aa0759c0b5446dacD86f2d25a4323DD5,
    0x70B2dc1779323E33b02F6F9C3831c5787eCDDf4D,
    0x4474aFF745BdeaD9b72698f40922E57072410753,
    0x4AcA23DAc423a307d1DCBd2b1e7997a6B40f88ad,
    0x149367D0c0E41e84D9FC430A201ea19ebf2fe6a2,
    0x3D64FC051CA5BB0842C1E824bAe1e6fDbbA4433C,
    0x21fd552dB4915Dee608232308cb482BB22daa646,
    0xf21e75461fc33AcBd5a1F02Cb09aD7B13e31f285,
    0xE22f275984E0C2Ab5CB496D14A7B1596Df940BFd,
    0x5D07c52B643Fe7077d1d64915b0E432d0386e6Ca,
    0x1eD1aCf5C0ac4663be4DF159bfCa5525a537BB9E,
    0x5091F93aB457f8b7CE603E132bafD62cdCE38c8f,
    0x2B46AD7fDA1BC44136dF9f375E2d233E307f2725,
    0xfe6EB7e72125CFDeEad66f9d5870f43810f39357,
    0x176874277E805f8FCC7B9C409805597baBf0a6Fe,
    0x176874277E805f8FCC7B9C409805597baBf0a6Fe,
    0xF69FD1BE1a17c598C0Fe4B0466cca0aD78cb86cB,
    0x2A5C13fB510E46140986c73a6D424AdF1584dB6b,
    0x4cd299D16560C417BfbF013C371D6A52271416F0,
    0xA01f7476f019b715e159785C09B22e467c9674cD,
    0x2A5C13fB510E46140986c73a6D424AdF1584dB6b,
    0x858a4e27B3563064ED9aBC3ACaB298cF512dAE61,
    0x466d8f79c80B08f118BdA8ec6b5825F14677b7Cb,
    0x8261057CAa54B64e8fbae299d1D4669D306Ad2EE,
    0xd994E3E364da38f7960dC6faD9b70ADeeB7b8AF3,
    0x1bddcfF107876Ee1FeaE040087D820107Ad67274,
    0x11FF7b0E1EF16310A5d72B330D366c7d7167b751,
    0x4a165a5541dE3F09858538d5dE25cbEc2494244c,
    0x6850f5843889567BF31E5060f09C7370ceF71741,
    0x0bF0B3bCBdFD3Be144B8D05a66D142225CF3E18e,
    0xE299A44763C4307a09d1A26e0d41E80117dA77f6,
    0x99aeD36ba440bedbb2a6FE526af1b20A5F59A312,
    0x82d3c2b1263D364dDd88ee6009f779B38457b539,
    0xe6D98Ac21c7598ea8766D80571eAD94678EC8146,
    0x67019F085353000b34a848b2BF0BBe4187eebD5e,
    0x6Db8C8f66185B807e1ab17D077C98221b3137757,
    0xA9d781d546d0337C6E333Bcb74BC3c55b1422cC7,
    0x91335F7Fb3Ef8B4EA2493fC4B1a921C506b0c3b6,
    0x42eB5E1A075d397024099173D3deAA3E7Fd380B0,
    0xEF1803411186B0aBa8C7bE9425b25063Abc6a3CA,
    0x98F83281aa0759c0b5446dacD86f2d25a4323DD5,
    0xc2ff2F6F7cd68C6BD86606f65B0d43591cd05757,
    0x0ebDfD75d33c05025074fd7845848D44966AB367,
    0x9247D70E4d3Db6454ebb507a6Ac233E5bD0c85a8,
    0x8261057CAa54B64e8fbae299d1D4669D306Ad2EE,
    0x6f43c6b2B711dc15e4eD466d51799F93A8Fe1f45,
    0x29F1B3EA36c4aB31Da1d002e267EBD964f2f3b41,
    0x7686F1b162296c1c9c96921f3965aF69639d7753,
    0x825acd62C9F7631939681d00802E7d58fec19F83,
    0xB3B6Fbee5DC1ACE4Aac7bF7e75715B0c7e023a0b,
    0x80a08D78Aa79DDb5373e36cFbf414c9075017C84,
    0xa465c8c2C2e11F374463D4676E2f2A70D6D07023,
    0x39E994756c85b1d7016A0e7D50Fdb064398DEe80,
    0xd51F76f765E4153d573150E1447b446b81CeC525,
    0xdCfaFb631df58aB6Dc1cE663638E0053cF05c27f,
    0x34094f6C8f280F62E00595f3fEf8160AB4A04A48,
    0xB492735E7A2b0c6f09f2b21CFfE3499181dB0c80,
    0x9247D70E4d3Db6454ebb507a6Ac233E5bD0c85a8,
    0xE8feee93Af1fD0296AFe27BC936583091F6d977e,
    0x9111Fbc3C0E6a9214cC42D8c6D4aBdB1f4DA4A27,
    0x93aF824CD336551B2E3494670B46E230affFC83C,
    0xE8fF95721fF2960ff8a03233d62c022ed4c2800E,
    0x0147A6A3081570002dBcF8bCdc4531903EaF0108,
    0x3fEA6cEB0d1eBfdb5A577502beb1686C8940aa19,
    0x36c1238af9cd4D640e6c5D4184Fc88A2117265F3,
    0xB23422f234C92c2B1c87D4E9A336a40eD0352Fb7,
    0xB23422f234C92c2B1c87D4E9A336a40eD0352Fb7,
    0xB23422f234C92c2B1c87D4E9A336a40eD0352Fb7,
    0x813A7Ae64F7be64f77595341ca810E44f88Dd925,
    0xda3665dd611E2652A5749F5F10e608314D5520E0,
    0xda3665dd611E2652A5749F5F10e608314D5520E0,
    0x63C4a1c6938CD921e3B595ED5b841Cc8F4971Ce9,
    0x91322aF5244b658f9E0034f6877922833aceaCbA,
    0xf22337d8E65edDdc181554806E0bA82afD417Bf5,
    0x95f8D5182Aa8fc23936744B0081B80A9DdeBF9e9,
    0xd51F76f765E4153d573150E1447b446b81CeC525,
    0xD4C90B2ac9a8598aF2b1BFfEdBeF70BAF3B252Df,
    0x004Af71aD0cBDB80AA49AEc3894d167173Be5efd,
    0xa04f9F497AAF27Fe9759cc136c647798c2255d7a,
    0x7A20448C50700E506b9FEB75c7Ce3166aE17611f,
    0xa84AbB4F2fd21b858B3c7823f5301755eCd46c26,
    0xc5D0E395f4d911b589612a3b2e61387CF72f2211,
    0x3289A6720c97eb1388F461952CDdECCAe72F7500,
    0xd653DFd2a632D55Bd40810B6ba83C47b673e1640,
    0xC8278082bFE0857696744588F8eC5029AAA1cE75,
    0xB3301F8Cf837c237eC6576287De79c3869b05084,
    0x20E6108eCdE71D88DE4Aa1941d0f16FD00b85d65,
    0x3ddeFbE3cc350eB626b31fBAB8060AeC7e1bC0d3,
    0x20E6108eCdE71D88DE4Aa1941d0f16FD00b85d65,
    0xe487C602E8c22354910782De711FB65522192c54,
    0x3D64FC051CA5BB0842C1E824bAe1e6fDbbA4433C,
    0x1e0207ca0229bD5bbdB8102db56CaC7fB7cfba20,
    0x464b8209D20109D2d514B5e6dEcb1cc4829f5CBe,
    0x4f55e7859e6AF3931F2a20376a0f3cA9153E5196,
    0x2FC420Cf93988A70061E3EdA1353f8fcf471b5E1,
    0x25464334d323D57216177EcBa7C50258822897f4,
    0x30E7c4aA0aaB8Ce55B44ECDD31c8fd95FfCfE4B2,
    0xC8f33E09F0d45B479b417aE101774966cb6B4181,
    0x79cB6F97d2814c82639c43d9aA38CD9c6d63AdE9,
    0xEc009e60372839613cE0A5cCa9D28a6F38e57244,
    0x123e99070e9Cb7d196d61ea8A0E5ffDC5Ff43069,
    0x34094f6C8f280F62E00595f3fEf8160AB4A04A48,
    0x3521940AFD29E49EC2DCDA04373aa4Fc2E932801,
    0xa0DBC70024F144e515f75206a6A1B9C3987Bbd5A,
    0xfa8F6DC80521dfD28834ca72c06bE7f9a1a72ec5,
    0x104E3af444db9c94887957F8AbAef6F0fCc97d10,
    0x89DC1211eAf777A6D2b4DEb2b9C937e6378bE898];
  address[] public freeMintAddresses = [
    0xaFad4149BC86C1BEFBBF899c09a34dc8b099CeAb,
    0x825acd62C9F7631939681d00802E7d58fec19F83,
    0xA0D15e3853BcC3000F728508802E5f213728BB6c,
    0xfe6EB7e72125CFDeEad66f9d5870f43810f39357,
    0x176874277E805f8FCC7B9C409805597baBf0a6Fe,
    0xd85CDE69Cc6B2f2ED4192CDc077Bfa361a198eFE];

  mapping(address => uint256) public addressMintedBalance;
  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _amount) public payable {
    require(!paused, "the contract has been paused paused");
    uint256 supply = totalSupply();
    require(_amount > 0, "need to mint at least 1 NFT");
    require(_amount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _amount <= maxSupply, "maxSupply limit exceeded");
    require(msg.value >= cost * _amount, "insufficient funds");
    
    if (msg.sender != owner()) {
        if(onlyWhitelist == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        }

        if (freeMint == true){
          require(eligibleFreeMint(msg.sender), "Address is not listed for freeMint");
          uint256 FreeMintCount = addressMintedBalance[msg.sender];
          require(FreeMintCount + _amount <= freeMintLimit, "max NFT per address exceeded");
        }
         
        
    }
    
    for (uint256 i = 1; i <= _amount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function eligibleFreeMint(address _user) public view returns(bool){
    for (uint i = 0; i < freeMintAddresses.length; i++){
      if (freeMintAddresses[i] == _user){
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
  

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function publicSaleOn() public onlyOwner {
      onlyWhitelist = false;
      freeMint = false;
      cost = 0.2 ether;
  }

  function freeMintSaleOn() public onlyOwner {
      freeMint = true;
      onlyWhitelist = false;
      cost = 0 ether;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(payTo).call{value: address(this).balance}("");
    require(os);
  }
}