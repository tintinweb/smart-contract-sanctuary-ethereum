/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

// ===============================================
//          TERMS AND CONDITIONS
//        https://www.anma.io/legal
// ===============================================

/*
    HIDEKI TSUKAMOTO | ANOMALOUS MATERIALS | 15.08.2021
______________.___.__________  ___ _______________________ 
\_   ___ \__  |   |\______   \/   |   \_   _____|______   \
/    \  \//   |   | |     ___/    ~    \    __)_ |       _/
\     \___\____   | |    |   \    Y    /        \|    |   \
 \______  / ______| |____|    \___|_  /_______  /|____|_  /
        \/\/                        \/        \/        \/ 
*/

/*
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

struct CypherAttributes
{
    uint colorset;
    int decay;
    int chaos;
    int utilRand;
    int numChannels;
    int[8] density;
    int[8] intricacy;
}


struct StringBuilder
{
    bytes data;
}

library SB
{
    function create(uint256 capacity)
        internal pure returns(StringBuilder memory)
    {
        return StringBuilder(new bytes(capacity + 32));
    }

    function resize(StringBuilder memory sb, uint256 newCapacity) 
        internal view
    {
        StringBuilder memory newSb = create(newCapacity);
        
        assembly 
        {
            let data := mload(sb)
            let newData := mload(newSb)
            let size := mload(add(data, 32)) // get used byte count
            let bytesToCopy := add(size, 32) // copy the used bytes, plus the size field in first 32 bytes
            
            pop(staticcall(
                gas(), 
                0x4, 
                add(data, 32), 
                bytesToCopy, 
                add(newData, 32), 
                bytesToCopy))
        }
        
        sb.data = newSb.data;
    }

    function resizeIfNeeded(StringBuilder memory sb, uint256 spaceNeeded) 
        internal view
    {
        uint capacity;
        uint size;
        assembly
        {
            let data := mload(sb)
            capacity := sub(mload(data), 32)
            size := mload(add(data, 32))
        }

        uint remaining = capacity - size;
        if (remaining >= spaceNeeded)
        {
            return;
        }

        uint newCapacity = capacity << 1;
        uint newRemaining = newCapacity - size;
        if (newRemaining >= spaceNeeded)
        {
            resize(sb, newCapacity);
        }
        else
        {
            newCapacity = spaceNeeded + size;
            resize(sb, newCapacity);
        }
    }
    
    function getString(StringBuilder memory sb) 
        internal pure returns(string memory) 
    {
        string memory ret;
        assembly 
        {
            let data := mload(sb)
            ret := add(data, 32)
        }
        return ret;
    }

    function writeStr(StringBuilder memory sb, string memory str) 
        internal view
    {
        resizeIfNeeded(sb, bytes(str).length);

        assembly 
        {
            let data := mload(sb)
            let size := mload(add(data, 32))
            pop(staticcall(gas(), 0x4, add(str, 32), mload(str), add(size, add(data, 64)), mload(str)))
            mstore(add(data, 32), add(size, mload(str)))
        }
    }

    function concat(StringBuilder memory dst, StringBuilder memory src) 
        internal view
    {
        string memory asString;
        assembly
        {
            let srcData := mload(src)
            asString := add(srcData, 32)
        }

        writeStr(dst, asString);
    }

    function writeUint(StringBuilder memory sb, uint u) 
        internal view
    {
        if (u > 0)
        {
            uint len;
            uint size;
            
            assembly
            {
                // get length string will be
                len := 0
                
                for {let val := u} gt(val, 0) {val := div(val,  10) len := add(len, 1)}
                {
                }

                // get bytes currently used
                let data := mload(sb)
                size := mload(add(data, 32))
            }
            
            // make sure there's room
            resizeIfNeeded(sb, len);
            
            assembly
            {
                let data := mload(sb)

                for {let i := 0 let val := u} lt(i, len) {i := add(i, 1) val := div(val, 10)}
                {
                    // sb.data[64 + size + (len - i - 1)] = (val % 10) + 48
                    mstore8(add(data, add(63, add(size, sub(len, i)))), add(mod(val, 10), 48))
                }
            
                size := add(size, len)
            
                mstore(add(data, 32), size)
            }
        }
        else
        {
            uint size;
            assembly
            {
                let data := mload(sb)
                size := mload(add(data, 32))
            }
            // make sure there's room
            resizeIfNeeded(sb, 1);
            
            assembly
            {
                let data := mload(sb)
                mstore(add(data, 32), add(size, 1))
                mstore8(add(data, add(64, size)), 48)
            }
        }
    }
    
    function writeInt(StringBuilder memory sb, int i) 
        internal view
    {
        if (i < 0)
        {
            // write the - sign
            uint size;
            assembly
            {
                let data := mload(sb)
                size := mload(add(data, 32))
            }
            resizeIfNeeded(sb, 1);
            
            assembly
            {
                let data := mload(sb)
                mstore(add(data, 32), add(size, 1))
                mstore8(add(data, add(64, size)), 45)
            }

            // now the digits can be written as a uint
            i *= -1;
        }
        writeUint(sb, uint(i));
    }

    function writeRgb(StringBuilder memory sb, uint256 col) 
        internal view
    {
        resizeIfNeeded(sb, 6);

        string[16] memory nibbles = [
            "0", "1", "2", "3", "4", "5", "6", "7", 
            "8", "9", "a", "b", "c", "d", "e", "f"];

        string memory asStr = string(abi.encodePacked(
            nibbles[(col >> 20) & 0xf],
            nibbles[(col >> 16) & 0xf],
            nibbles[(col >> 12) & 0xf],
            nibbles[(col >> 8) & 0xf],
            nibbles[(col >> 4) & 0xf],
            nibbles[col & 0xf]
        ));

        writeStr(sb, asStr);
    }
}


struct Rand
{
    uint256 value;
}

library Random
{
    function create(uint256 srand) 
        internal pure returns(Rand memory) 
    {
        Rand memory rand = Rand({value: srand});
        return rand;
    }
    
    function value(Rand memory rand) 
        internal pure returns(uint256) 
    {
        rand.value = uint256(keccak256(abi.encodePacked(rand.value)));
        return rand.value;
    }
    
    // (max inclusive)
    function range(Rand memory rand, int256 min, int256 max) 
        internal pure returns(int256) 
    {
        if (min <= max)
        {
            uint256 span = uint256(max - min);

            return int256(value(rand) % (span + 1)) + min;
        }
        else
        {
            return range(rand, max, min);
        }
    }
}

contract CypherDrawing is Ownable
{   
    int constant FONT_SIZE = 4;

    uint8[1024] private curve;
    int8[1024] private noiseTable;
    uint24[256][5] private gradients;

    function setCurve(uint8[1024] memory newCurve) 
        public onlyOwner
    {
        curve = newCurve;
    }

    function setNoiseTable(int8[1024] memory newNoiseTable) 
        public onlyOwner
    {
        noiseTable = newNoiseTable;
    }

    function setGradients(uint24[256][5] memory newGradients)
        public onlyOwner
    {
        gradients = newGradients;
    }

    function getAttributes(bytes32 hash)
        public view returns (CypherAttributes memory)
    {
        Rand memory rand = Random.create(uint256(hash));
        CypherAttributes memory attributes = createAttributes(rand);
        return attributes;
    }

    function generate(bytes32 hash) 
        public view returns(string memory)
    {
        StringBuilder memory b = SB.create(128 * 1024);

        SB.writeStr(b, "<svg viewBox='0 0 640 640' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>"
            
            "<style>"
            "text{"
                "font-size:");
        SB.writeInt(b, FONT_SIZE);
        SB.writeStr(b, "px;"
                "font-family: monospace;"
                "fill: #cccccc;"
            "}"
            "</style>"

            "<defs>"
                "<filter id='glow'>"
                    "<feGaussianBlur stdDeviation='3.0' result='coloredBlur'/>"
                    "<feComponentTransfer in='coloredBlur' result='coloredBlur'>"
                        "<feFuncA type='linear' slope='0.70'/>"
                    "</feComponentTransfer>"
                    "<feMerge>"
                        "<feMergeNode in='coloredBlur'/>"
                        "<feMergeNode in='SourceGraphic'/>"
                    "</feMerge>"
                "</filter>"
            "</defs>"

            "<rect width='640' height='640' fill='#090809'/>"              
            
            "<g id='cypher' shape-rendering='geometricPrecision' filter='url(#glow)'>");
        
        Rand memory rand = Random.create(uint256(hash));
        CypherAttributes memory attributes = createAttributes(rand);
        draw(b, attributes, rand);
            
        SB.writeStr(b, "</g>"
            
            "</svg>");

        return SB.getString(b);
    }

    struct Ring
    {
        uint id;
        int arcs;
        int span;
        int inner;
        int outer;
    }

    struct SegmentData
    {
        uint ringId;
        uint segId;
        int inner;
        int outer;
        int thick;
        int start;
        int fin;
        EdgeType edge;
        FillType fill;
        SpanType innerSpanType;
        PadType padInner;
        SpanType outerSpanType;
        PadType padOuter;
        uint colour;
    }

    enum SpanType
    {
        None,
        Arc,
        Cap,
        Ang,
        Brk,
        Dotted
    }

    enum Variant
    {
        None,
        Inner,
        Outer,
        Double,
        Max
    }

    enum EdgeType
    {
        None,
        Simple
    }

    enum FillType
    {
        None,
        Block,
        Hollow,
        Text,
        Increment, 
        Comp
    }

    enum PadType
    {
        None,
        Single
    }

    
    function clamp(int num)
        private pure returns(int)
    {
        return clamp(num, 0, 31);
    }
    
    function clamp(int num, int min, int max)
        private pure returns(int)
    {
        return num <= min ? min : num >= max ? max : num;
    }

    function noise(Rand memory rand) 
        private view returns(int)
    {
        return noiseTable[uint(Random.range(rand, 0, 1023))];
    }

    function createAttributes(Rand memory rand) 
        private view returns(CypherAttributes memory)
    {
        int weighted = int8(curve[uint(Random.range(rand, 0, 1023))]);
        
        CypherAttributes memory attributes;
        attributes.colorset = (uint(weighted < int(8) ? int(8) : weighted) - 8)/6;
        attributes.decay = 32 - clamp(weighted + noise(rand));
        attributes.chaos = 32 - clamp(weighted + noise(rand));
        attributes.utilRand = Random.range(rand, 0, 1023);
        attributes.numChannels = 4 + (clamp(weighted + noise(rand), 0, 32) >> 3);
        
        int count = 0;
        while(true)
        {
            uint idx = uint(Random.range(rand, 0, 7));

            if(count == attributes.numChannels)
            { 
                break;
            }
            else if(attributes.density[idx]==1)
            {
                continue;
            } 
            else 
            {
                attributes.density[idx]=1;
                count++;
            }
        }

        for (uint i = 0; i < 8; ++i)
        {
            attributes.intricacy[i] = clamp(weighted + noise(rand));
        }

        return attributes;
    }

    function getSegmentColour(
        CypherAttributes memory atr, 
        Ring memory ring, 
        Rand memory rand) 
        private view returns(uint24)
    {
        int array_offset    = atr.utilRand % 256;
        int grad_noise      = Random.range(rand, 0, 30);
        int colour_index    = (array_offset + ring.inner + grad_noise) % 256;
        return gradients[atr.colorset][uint(colour_index)];
    }

    function draw(
        StringBuilder memory b, 
        CypherAttributes memory atr, 
        Rand memory rand) 
        private view
    {
        Ring[16] memory rings = createRings(rand);

        // frame
        for(uint i=0; i<16; ++i)
        {
            SB.writeStr(b, "<circle cx='320' cy='320' fill='none' stroke-width='0.1' stroke-opacity='15%' stroke='#");
            SB.writeRgb(b, gradients[atr.colorset][uint(rings[i].inner)-1]);
            SB.writeStr(b, "' r='");
            SB.writeInt(b, rings[i].inner);
            SB.writeStr(b, "'/>");
        }

        // defs & ring
        // defs added as we go, ring must be deferred
        SB.writeStr(b, "<defs>");
        StringBuilder memory ringSvg = SB.create(4096);
        for(uint i=0; i<16; i++)
        {
            uint channelIndex = (i >> 1);
            if(atr.density[channelIndex] == 0) continue;

            int span = rings[i].span;

            uint segs = 8 >> uint(Random.range(rand, 1, 2));

            int[] memory sections = new int[](segs);
            
            for(uint g=0; g<segs; g++)
            {
                sections[g] = 1;
            }

            {
                int increments = int(span)-int(segs);
                for(int s=0; s<increments; s++)
                {  
                    sections[uint(Random.range(rand, 0, int(segs) - 1))]++;
                }
            }

            int progress = int(span);

            // template
            SB.writeStr(b, "<g id='variant_r");
            SB.writeUint(b, rings[i].id);
            SB.writeStr(b, "_v0'>");
            for(uint t=0; t<segs; t++)
            {
                progress -= int(sections[t]); // TODO make sure everything with subtractions happens with ints

                SegmentData memory segmentData;
                segmentData.ringId = i;
                segmentData.segId = t;
                segmentData.inner = rings[i].inner;
                segmentData.outer = rings[i].outer;
                segmentData.thick = rings[i].outer - int(rings[i].inner);
                segmentData.start = progress * 5;
                segmentData.fin = sections[t] * 5;
                segmentData.edge = EdgeType(rings[i].inner % 2);
                {
                    int maxIntricacy = atr.intricacy[channelIndex] >> 3;
                    segmentData.fill = FillType(Random.range(rand, 2, 2+maxIntricacy));
                    segmentData.innerSpanType = SpanType(Random.range(rand, 2, 2+maxIntricacy));
                    segmentData.outerSpanType = SpanType(Random.range(rand, 2, 2+maxIntricacy));
                }
                segmentData.padInner = PadType(rings[i].outer % 2);
                segmentData.padOuter = PadType(rings[i].outer % 2);
                segmentData.colour = getSegmentColour(atr, rings[i], rand);

                if (Random.range(rand, 0, 10) > 7)
                {
                    segmentData.colour = (segmentData.colour & 0xfefefe) >> 1;
                }

                drawSegment(
                    b, 
                    segmentData,
                    rand);
            }
            SB.writeStr(b, "</g>");

            // arc
            SB.writeStr(ringSvg, "<g id='r");
            SB.writeUint(ringSvg, i);
            SB.writeStr(ringSvg, "'>");
            for (uint j = 0; j < uint(rings[i].arcs); j++)
            {            
                if (Random.range(rand, 0, 64) < atr.decay)
                {
                    continue;  //THIS HAS THE EFFECT I WAS LOOKING FOR.
                }
                
                int chaosAddition = Random.range(rand, 0, 720);

                int angle = atr.chaos < Random.range(rand, 0, 64) ? rings[i].span : chaosAddition;

                int rotation = (angle * int(j)) * 5;

                SB.writeStr(ringSvg, "<g id='r");
                SB.writeUint(ringSvg, i);
                SB.writeStr(ringSvg, "a");
                SB.writeUint(ringSvg, j);
                SB.writeStr(ringSvg, "' transform='rotate(");
                SB.writeInt(ringSvg, rotation);
                SB.writeStr(ringSvg, " 320 320)'><use xlink:href='#variant_r");
                SB.writeUint(ringSvg, i);
                SB.writeStr(ringSvg, "_v0'/> </g>");
            }
            
            uint shifted = 8 << uint(Random.range(rand, 0, 4));

            SB.writeStr(ringSvg, "<animateTransform attributeName='transform' attributeType='XML' type='rotate' from='0 320 320' to='");
            if (Random.range(rand, 0, 10) > 8)
            {
                SB.writeStr(ringSvg, "-");
            }
            SB.writeStr(ringSvg, "360 320 320' dur='");
            SB.writeUint(ringSvg, shifted);
            SB.writeStr(ringSvg, "s' begin='1s' repeatCount='indefinite'/></g>");
        }

        SB.writeStr(b, "</defs>");
        SB.concat(b, ringSvg);
    }

    function createRings(Rand memory rand) 
        private pure returns(Ring[16] memory)
    {
        uint8[8] memory chf = [0, 0, 0, 0, 0, 0, 0, 0];

        for(uint i=0; i<24; i++)
        {
            chf[uint(Random.range(rand, 0, 7))]++;
        }

        int[16] memory radii = [int(5), 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];

        for(uint j=0; j<chf.length; j++) 
        {
            int total = int8(chf[j]);

            for(int i=0; i<total; i++) 
            {
                uint lower = j*2;
                uint upper = (j*2)+3;
                uint index = uint(Random.range(rand, int(lower), int(upper)));

                int adv = Random.range(rand, i, total);

                radii[index % 16]+=(adv*5);

                total-=adv;
            }
        }

        Ring[16] memory rings;

        uint8[5] memory increments =  [12, 18, 24, 36, 72];
        int progress = 60;

        for(uint i=0; i<16; i++)
        {
            uint idxInc            = uint(Random.range(rand, 0, int(increments.length)-1));
            int increment           = int8(increments[idxInc]);
            int pad                 = 1;
            int thisRingThickness = radii[i];

            
            int innerRadius        = progress+pad;
            int outerRadius        = int(innerRadius+thisRingThickness) - int(pad);

            progress += thisRingThickness;

            int numArcs  = 72/increment;
        
            rings[i] = Ring(
            {
                id          : i,
                arcs        : numArcs,
                span        : increment,
                inner       : innerRadius,
                outer       : outerRadius
            });
        }

        return rings;
    }

    function drawSpan(
        StringBuilder memory b,
        SpanType spanType, 
        int start, 
        int fin, 
        int radius, 
        PadType pad, 
        Variant variant,
        uint col,
        Rand memory rand) 
        private view
    {
        if (spanType == SpanType.Arc)
        {
            arc(b, start, fin, radius, pad, col, rand);
        }
        else if (spanType == SpanType.Dotted)
        {
            dotted(b, start, fin, radius, pad, col, rand);
        }
        else if (spanType == SpanType.Cap)
        {
            cap(b, start, fin, radius, pad, col, rand);
        }
        else if (spanType == SpanType.Ang)
        {
            ang(b, start, fin, radius, pad, variant, col, rand);
        }
        else if (spanType == SpanType.Brk)
        {
            brk(b, start, fin, radius, pad, variant, col, rand);
        }
    }

    function drawSegment(
        StringBuilder memory b, 
        SegmentData memory segmentData,
        Rand memory rand) 
        private view
    {
        SB.writeStr(b, "<g id='r");
        SB.writeUint(b, segmentData.ringId);
        SB.writeStr(b, "v0s");
        SB.writeUint(b, segmentData.segId);
        SB.writeStr(b, "'>");

        //draw the inner span
        drawSpan(
            b,
            segmentData.innerSpanType, 
            segmentData.start, 
            segmentData.fin, 
            segmentData.inner, 
            segmentData.padInner, 
            Variant.Inner, 
            segmentData.colour,
            rand);

        //draw the outer span
        drawSpan(
            b,
            segmentData.outerSpanType, 
            segmentData.start, 
            segmentData.fin, 
            segmentData.outer, 
            segmentData.padOuter, 
            Variant.Outer, 
            segmentData.colour,
            rand);

        //draw the edges (matching)
        if (segmentData.edge == EdgeType.Simple)
        {
            simple(
                b, 
                segmentData.start, 
                segmentData.fin, 
                segmentData.outer, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour,
                rand);
        }

        int radius = segmentData.inner + ((segmentData.outer-segmentData.inner) / 2);

        if (segmentData.fill == FillType.Block)
        {
            blck(
                b, 
                segmentData.start, 
                segmentData.fin, 
                radius, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour, 
                rand);
        }
        else if (segmentData.fill == FillType.Increment)
        {
            inc(
                b, 
                segmentData.start, 
                segmentData.fin, 
                radius, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour, 
                rand);
        }
        else if (segmentData.fill == FillType.Text)
        {
            if (!(segmentData.thick < 5 || segmentData.fin < 30))
            {
                text(
                    b, 
                    segmentData.start, 
                    segmentData.fin, 
                    segmentData.inner, 
                    segmentData.colour, 
                    rand);                    
            }
        }
        else if (segmentData.fill == FillType.Hollow)
        {
            hollow(
                b, 
                segmentData.start, 
                segmentData.fin, 
                segmentData.inner, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour,
                rand);
        }
        else if (segmentData.fill == FillType.Comp)
        {
            blck(
                b, 
                segmentData.start, 
                segmentData.fin, 
                radius, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour, 
                rand);

            inc(
                b, 
                segmentData.start, 
                segmentData.fin, 
                radius, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour, 
                rand);

            hollow(
                b, 
                segmentData.start, 
                segmentData.fin, 
                segmentData.inner, 
                segmentData.padOuter, 
                segmentData.thick, 
                segmentData.colour,
                rand);

            if (!(segmentData.thick < 5 || segmentData.fin < 30))
            {
                text(
                    b,
                    segmentData.start, 
                    segmentData.fin, 
                    segmentData.inner, 
                    segmentData.colour, 
                    rand);
            }
        }

        SB.writeStr(b, "</g>");
    }
    
    /*fill types*/

    function hollow(
        StringBuilder memory b,
        int start, 
        int fin, 
        int radius, 
        PadType pad, 
        int thickness, 
        uint col,
        Rand memory rand) 
        view private
    {
        int padding     = pad == PadType.Single ? int(2) : int(0);
        int angleStart = start+padding;
        int angleEnd   = fin-(padding*2);
        int innerRad   = radius + padding;
        int outerRad   = radius + (thickness-padding);
        int centreRad  = 320 + innerRad;
        int len         = centreRad + thickness - (padding*2);

        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><line y1='320' x1='");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, "' y2='320' x2='");
        SB.writeInt(b, len);
        SB.writeStr(b, "'  stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "'/><circle r='");
        SB.writeInt(b, innerRad);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='360' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray='");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 360'/><circle r='");
        SB.writeInt(b, outerRad);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='360' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray='");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 360'/><g transform='rotate(");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 320 320)'><line y1='320' x1='");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, "' y2='320' x2='");
        SB.writeInt(b, len);
        SB.writeStr(b, "'  stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "'/></g></g>");
    }

    function randomStrokeWidth(Rand memory rand) 
        private pure returns(string memory)
    {
        return Random.range(rand, 0, 9) > 6 ? "0.6" : "0.3";
    }

    function text(
        StringBuilder memory b,
        int start, 
        int fin, 
        int radius, 
        uint col, 
        Rand memory rand) 
        view private
    {
        int padding     = 2;
        int angleStart = start - padding;
        uint textId = Random.value(rand);
        
        string[12] memory sym = ["0.421", "0.36", "0.73","0.421", "0.36", "0.73","0.421", "0.36", "0.73", "+", "^", "_"];

        string memory chars = sym[uint(Random.range(rand, 0, int(sym.length)-1))];

        radius += FONT_SIZE + padding;

        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart-180+fin);
        SB.writeStr(b, " 320 320)'><path id='text_path_");
        SB.writeUint(b, textId);
        SB.writeStr(b, "' d='M");
        SB.writeInt(b, 320-radius);
        SB.writeStr(b, ", 320 a1, 1 0 0, 0 ");
        SB.writeInt(b, radius*2);
        SB.writeStr(b, ", 0' pathLength='100' fill='none' stroke-width='0' stroke='red'/><text x='0%' style='fill:#");
        SB.writeRgb(b, col);
        SB.writeStr(b, ";'><textPath href='#text_path_");
        SB.writeUint(b, textId);
        SB.writeStr(b, "' pointer-events='none'>");
        SB.writeStr(b, chars);
        SB.writeStr(b, "</textPath></text></g>");
    }

    function inc(
        StringBuilder memory b,
        int start, 
        int fin, 
        int radius, 
        PadType pad, 
        int thickness, 
        uint col, 
        Rand memory rand) 
        view private
    {
        int padding     = (pad == PadType.Single) ? int(4) : int(0);
        int angleStart = start + padding / 2;
        int angleEnd   = fin - (padding);
        int stroke      = thickness - padding;

        uint incId = Random.value(rand);

        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><clipPath id='inc_cutter_");
        SB.writeUint(b, incId);
        SB.writeStr(b, "'><rect x='0' y='0' width='640' height='320' stroke='black' fill='none' transform='rotate(");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, ", 320, 320)' /></clipPath><path d='M");
        SB.writeInt(b, 320-radius);
        SB.writeStr(b, ", 320 a1, 1 0 0, 0 ");
        SB.writeInt(b, radius*2);
        SB.writeStr(b, ", 0' pathLength='100' fill='none' stroke-width='");
        SB.writeInt(b, stroke);
        SB.writeStr(b, "' stroke-opacity='0.4' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-dasharray='0.05 1' clip-path='url(#inc_cutter_");
        SB.writeUint(b, incId);
        SB.writeStr(b, ")'/></g>");
    }

    function blck(
        StringBuilder memory b,
        int start, 
        int /*fin*/, 
        int radius, 
        PadType pad, 
        int thickness, 
        uint col, 
        Rand memory rand) 
        view private
    {
        int padding     = (pad == PadType.Single) ? int(4) : int(0);
        int angleStart = start + padding / 2;
        int stroke      = thickness - padding;
        int opac        = Random.range(rand, 2, 8);


        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='359' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-opacity='");
        SB.writeInt(b, opac);
        SB.writeStr(b, "%' stroke-width='");
        SB.writeInt(b, stroke);
        SB.writeStr(b, "' stroke-dasharray='");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " ");
        SB.writeInt(b, 360 - angleStart);
        SB.writeStr(b, "'/></g>");
    }

    /*edge types*/

    function simple(
        StringBuilder memory b,
        int start, 
        int fin, 
        int radius, 
        PadType pad, 
        int len, 
        uint col,
        Rand memory rand) 
        view private
    {
        int padding = (pad == PadType.Single) ? int(1) : int(0);
        int angleStart = start + padding;
        int angleEnd = fin - (padding * 2);
        int centreRad = 320 + radius;
        int edgeLength = centreRad - len;

        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><line y1='320' x1='");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, "' y2='320' x2='");
        SB.writeInt(b, edgeLength);
        SB.writeStr(b, "'  stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "'/><g transform='rotate(");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 320 320)'><line y1='320' x1='");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, "' y2='320' x2='");
        SB.writeInt(b, edgeLength);
        SB.writeStr(b, "'  stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "'/></g></g>");
    }

    /*spans*/

    function brk(
        StringBuilder memory b,
        int start, 
        int fin, 
        int radius, 
        PadType pad, 
        Variant variant, 
        uint col, 
        Rand memory rand) 
        view private
    {
        int padding     = (pad == PadType.Single) ? int(1) : int(0);
        int angleStart = start + padding;
        int angleEnd   = fin - (padding * 2);
        int centreRad  = 320 + radius;
        int brkSize    = 2;
        int brkOffset = (variant == Variant.Inner) ? centreRad + brkSize : centreRad - brkSize;

        //uint brkId = Rand.next(rand);

        SB.writeStr(b, "<g><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='359' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray='");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " ");
        SB.writeInt(b, 360 - angleStart);
        SB.writeStr(b, "'/><line y1='320' x1='");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, "' y2='320' x2='");
        SB.writeInt(b, brkOffset);
        SB.writeStr(b, "' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "'/><g transform='rotate(");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 320 320)'><line y1='320' x1='");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, "' y2='320' x2='");
        SB.writeInt(b, brkOffset);
        SB.writeStr(b, "' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "'/></g></g>");
    }

   function ang(
       StringBuilder memory b,
       int start, 
       int fin, 
       int radius, 
       PadType pad, 
       Variant variant, 
       uint col,
       Rand memory rand) 
       view private
   {
        int padding = (pad == PadType.Single) ? int(1) : int(0);
        int angleStart = start + padding;
        int angleEnd = fin - (padding * 2);
        int angsSize = 2;
        int centreRad = 320 + radius;
        int centreAng = (variant == Variant.Inner) ? centreRad + angsSize : centreRad - angsSize;
        int opac = Random.range(rand, 10, 100);
        
        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='360' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "'  stroke-opacity='");
        SB.writeInt(b, opac);
        SB.writeStr(b, "%' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray= '");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 360'/><polyline points='");
        SB.writeInt(b, centreAng);
        SB.writeStr(b, ", 320  ");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, ", 320 ");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, ", ");
        SB.writeInt(b, 320+angsSize);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' fill='none'/><g transform='rotate(");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 320 320)'><polyline points='");
        SB.writeInt(b, centreAng);
        SB.writeStr(b, ", 320 ");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, ", 320 ");
        SB.writeInt(b, centreRad);
        SB.writeStr(b, ", ");
        SB.writeInt(b, 320-angsSize);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' fill='none'/></g></g>");
   }

   function cap(
       StringBuilder memory b,
       int start, 
       int fin, 
       int radius, 
       PadType pad, 
       uint col,
       Rand memory rand) 
       view private
   {
        int padding = (pad == PadType.Single) ? int(1) : int(0);
        int angleStart = start + padding;
        int angleEnd = fin - (padding * 2);
        int gap = angleEnd - 2;
        

        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='360' stroke-opacity='20%' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray='");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, " 360'/><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='360' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray='1 ");
        SB.writeInt(b, gap);
        SB.writeStr(b, " 1 360'/></g>");
   }

   function dotted(
       StringBuilder memory b,
       int start, 
       int fin, 
       int radius, 
       PadType pad, 
       uint col, 
       Rand memory rand) 
       view private
   {
        int padding     = (pad == PadType.Single) ? int(1) : int(0);
        int angleStart = start + padding;
        int angleEnd   = fin - (padding * 2);
        int gap = angleEnd - 2;
        int opac = Random.range(rand, 10, 100);

        uint dotId = Random.value(rand);

        SB.writeStr(b, "<g transform='rotate(");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " 320 320)'><clipPath id='dot_cutter_");
        SB.writeUint(b, dotId);
        SB.writeStr(b, "'><rect x='0' y='0' width='640' height='320' stroke='black' fill='none' transform='rotate(");
        SB.writeInt(b, angleEnd);
        SB.writeStr(b, ", 320, 320)' /></clipPath><path d='M");
        SB.writeInt(b, 320-radius);
        SB.writeStr(b, ", 320 a1, 1 0 0, 0 ");
        SB.writeInt(b, radius*2);
        SB.writeStr(b, ", 0' pathLength='100' fill='none' stroke-opacity='");
        SB.writeInt(b, opac);
        SB.writeStr(b, "%' stroke-width='0.4' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-dasharray='0.25 0.25' clip-path='url(#dot_cutter_");
        SB.writeUint(b, dotId);
        SB.writeStr(b, ")'/><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='359' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='0.4' stroke-dasharray='1 ");
        SB.writeInt(b, gap);
        SB.writeStr(b, " 1 360'/></g>");
   }

   function arc(
       StringBuilder memory b, 
       int start, 
       int /*fin*/, 
       int radius, 
       PadType pad, 
       uint col, 
       Rand memory rand) 
       view private
   {
        int padding     = (pad == PadType.Single) ? int(1) : int(0);
        int angleStart = start + padding;

        SB.writeStr(b, "<g><circle r='");
        SB.writeInt(b, radius);
        SB.writeStr(b, "' cx='320' cy='320' fill='none' pathLength='359' stroke='#");
        SB.writeRgb(b, col);
        SB.writeStr(b, "' stroke-width='");
        SB.writeStr(b, randomStrokeWidth(rand));
        SB.writeStr(b, "' stroke-dasharray='");
        SB.writeInt(b, angleStart);
        SB.writeStr(b, " ");
        SB.writeInt(b, 360 - angleStart);
        SB.writeStr(b, "'/></g>");
   }
}

contract CypherMetadata is Ownable
{   
    using Strings for uint256;

    CypherDrawing _drawing;
    string private _imageBaseUri;

    constructor(
        CypherDrawing drawing,
        string memory imageBaseUri)
    {
        _drawing = drawing;
        _imageBaseUri = imageBaseUri;
    }

    function tokenURI(
        uint256 tokenId, 
        bytes32 hash,
        uint256 generation,
        bool isFirstTokenInGeneration) 
        public view returns(string memory) 
    {
        return string(abi.encodePacked("data:application/json;utf8,{"
            "\"image\":\"data:image/svg+xml;utf8,",
            _drawing.generate(hash), "\",",
            _commonMetadata(tokenId, hash, generation, isFirstTokenInGeneration),
            "}"));
    }

    function metadata(
        uint256 tokenId,
        bytes32 hash, 
        uint256 generation,
        bool isFirstTokenInGeneration)
        public view returns(string memory)
    {
        string memory imageUri = bytes(_imageBaseUri).length > 0 ? string(abi.encodePacked(_imageBaseUri, tokenId.toString())) : "";

        return string(abi.encodePacked("{"
            "\"external_url\": \"", imageUri, "\",",
            "\"image\": \"", imageUri, "\",",
            _commonMetadata(tokenId, hash, generation, isFirstTokenInGeneration),
            "}"));
    }

    function setDrawing(CypherDrawing drawing)
        public onlyOwner
    {
        _drawing = drawing;
    }

    function setImageBaseUri(string memory imageBaseUri)
        public onlyOwner
    {
        _imageBaseUri = imageBaseUri;
    }

    function _commonMetadata(
        uint256 tokenId, 
        bytes32 hash, 
        uint256 generation,
        bool isFirstTokenInGeneration)
        private view returns(string memory)
    {
        CypherAttributes memory attributes = _drawing.getAttributes(hash);
        
        int overall = 0;
        for (uint i = 0; i < 8; ++i)
        {
            overall += attributes.density[i] * attributes.intricacy[i];
        }
        overall >>= 3;

        StringBuilder memory b = SB.create(2048);
        
        SB.writeStr(b, "\"description\": \"Cypher is a generative art project by Hideki Tsukamoto comprised of 1024 tokens calculated and drawn via smart-contract, by the Ethereum Virtual Machine. Cypher is part one of the 'Apex' series.\","
            "\"name\": \"Cypher #"); 
        SB.writeUint(b, tokenId);
        SB.writeStr(b, "\","
            "\"background_color\": \"1a181b\","
            "\"attributes\": [");
        if (tokenId == 0)
        {
            SB.writeStr(b, "{"
                "\"trait_type\": \"Edition\","
                "\"value\": \"Genesis\""
                "},");
        }
        else if (tokenId == 1)
        {
            SB.writeStr(b, "{"
                "\"trait_type\": \"Edition\","
                "\"value\": \"Primary\""
                "},");
        }
        else if (tokenId == 2)
        {
            SB.writeStr(b, "{"
                "\"trait_type\": \"Edition\","
                "\"value\": \"Secondary\""
                "},");
        }
        else if (tokenId == 3)
        {
            SB.writeStr(b, "{"
                "\"trait_type\": \"Edition\","
                "\"value\": \"Tertiary\""
                "},");
        }
        if (isFirstTokenInGeneration)
        {
            SB.writeStr(b, "{"
                "\"trait_type\": \"Edition\","
                "\"value\": \"Generation Genesis\""
                "},");
        }
        SB.writeStr(b, "{"
            "\"trait_type\": \"Generation\"," 
            "\"value\": \"");
        SB.writeUint(b, generation);
        SB.writeStr(b, "\"},"
            "{"
                "\"trait_type\": \"Intricacy\","
                "\"value\":\"");
        SB.writeStr(b, _attributeValueString_0_32(overall));
        SB.writeStr(b, "\"},"
            "{"
                "\"trait_type\": \"Intricacy Value\","
                "\"max_value\": 32,"
                "\"value\":");
        SB.writeInt(b, overall);
        SB.writeStr(b, "},"
            "{"
                "\"trait_type\": \"Chaos\","
                "\"value\":\"");
        SB.writeStr(b, _attributeValueString_0_32(attributes.chaos));
        SB.writeStr(b, "\"},"
            "{"
                "\"trait_type\": \"Chaos Value\","
                "\"max_value\": 32,"
                "\"value\":");
        SB.writeInt(b, attributes.chaos);
        SB.writeStr(b, "},"
            "{"
                "\"trait_type\": \"Channels\","
                "\"value\":\"");
        SB.writeStr(b, _attributeValueString_0_8(attributes.numChannels));
        SB.writeStr(b, "\"},"
            "{"
                "\"trait_type\": \"Channels Value\","
                "\"max_value\": 8,"
                "\"value\":");
        SB.writeInt(b, attributes.numChannels);
        SB.writeStr(b, "},"
            "{"
                "\"trait_type\": \"Decay\","
                "\"value\":\"");
        SB.writeStr(b, _attributeValueString_0_32(attributes.decay));
        SB.writeStr(b, "\"},"
            "{"
                "\"trait_type\": \"Decay Value\","
                "\"max_value\": 32,"
                "\"value\":");
        SB.writeInt(b, attributes.decay);
        SB.writeStr(b, "},"
            "{"
                "\"trait_type\": \"Level\","
                "\"value\":\"");
        SB.writeUint(b, attributes.colorset + 1);
        SB.writeStr(b, "\"},"
            "{"
                "\"trait_type\": \"Level Value\","
                "\"max_value\": 5,"
                "\"value\":");
        SB.writeUint(b, attributes.colorset + 1);
        SB.writeStr(b, "}"
            "]");

        return SB.getString(b);
    }

    function _attributeValueString_0_32(int256 value)
        private pure returns(string memory)
    {
        if (value == 0)
        {
            return "Void";
        }
        else if (value <= 2)
        {
            return "Marginal";
        }
        else if (value <= 8)
        {
            return "Low";
        }
        else if (value <= 23)
        {
            return "Average";
        }
        else if (value <= 29)
        {
            return "High";
        }
        else if (value <= 31)
        {
            return "Super";
        }
        else
        {
            return "Extreme";
        }
    }

    function _attributeValueString_0_8(int256 value) 
        private pure returns(string memory)
    {
        if (value == 0)
        {
            return "Void";
        }
        else if (value <= 1)
        {
            return "Marginal";
        }
        else if (value <= 2)
        {
            return "Low";
        }
        else if (value <= 5)
        {
            return "Average";
        }
        else if (value <= 6)
        {
            return "High";
        }
        else if (value <= 7)
        {
            return "Super";
        }
        else
        {
            return "Extreme";
        }
    }
}



contract Cypher is ERC721Enumerable, Ownable
{
    uint256 private _maxTokenInvocations;
    uint256 private _reservedInvocations;
    uint256 private _auctionStartBlock;
    uint256 private _auctionEndBlock;
    uint256 private _initialFee;
    uint256 private _initialDuration;
    uint256 private _maxHalvings;
    address payable private _recipient;
    CypherDrawing private _drawing;
    CypherMetadata private _metadata;
    mapping(uint256 => bytes32) private _hashes;
    mapping(uint256 => uint256) private _generation;
    bool _isLocked;

    struct ConstructorArgs
    {
        string name;
        string symbol;
        uint256 maxTokenInvocations;
        uint256 reservedInvocations;
        uint256 auctionStartBlock;
        uint256 initialFee;
        uint256 initialDuration;
        uint256 maxHalvings;
        address payable recipient;
        CypherDrawing drawing;
        CypherMetadata meta;
    }

    constructor(
        ConstructorArgs memory args)
        ERC721(args.name, args.symbol)
    {
        _maxTokenInvocations = args.maxTokenInvocations;
        _reservedInvocations = args.reservedInvocations;
        _auctionStartBlock = args.auctionStartBlock;
        _initialFee = args.initialFee;
        _initialDuration = args.initialDuration;
        _maxHalvings = args.maxHalvings;
        _recipient = args.recipient;
        _drawing = args.drawing;
        _metadata = args.meta;

        // minting #0
        bytes32 hash = keccak256(
            abi.encodePacked(uint(0),
                            blockhash(block.number - 1)));

        _hashes[0] = hash;
        _generation[0] = 0;
        _safeMint(msg.sender, 0);
    }

    modifier isUnlocked() 
    {
        require(!_isLocked, "Contract is locked");
        _;
    }

    function lock() public onlyOwner
    {
        _isLocked = true;
    }

    function setMaxTokenInvocations(uint256 maxTokenInvocations)
        public onlyOwner isUnlocked
    {
        _maxTokenInvocations = maxTokenInvocations;
    }

    function setReservedInvocations(uint256 reservedInvocations)
        public onlyOwner isUnlocked
    {
        _reservedInvocations = reservedInvocations;
    }

    function setAuctionStartBlock(uint256 auctionStartBlock)
        public onlyOwner isUnlocked
    {
        _auctionStartBlock = auctionStartBlock;
    }

    function setInitialFee(uint256 initialFee)
        public onlyOwner isUnlocked
    {
        _initialFee = initialFee;
    }

    function setInitialDuration(uint256 initialDuration)
        public onlyOwner isUnlocked
    {
        _initialDuration = initialDuration;
    }

    function setMaxHalvings(uint256 maxHalvings)
        public onlyOwner isUnlocked
    {
        _maxHalvings = maxHalvings;
    }

    function setRecipient(address payable recipient)
        public onlyOwner
    {
        _recipient = recipient;
    }

    function setDrawingContract(CypherDrawing drawing)
        public onlyOwner isUnlocked
    {
        _drawing = drawing;
    }

    function setMetadataContract(CypherMetadata meta)
        public onlyOwner
    {
        _metadata = meta;
    }

    function getInfo()
        public view returns(
            bool hasStarted,
            bool hasEnded,
            uint256 blocksUntilAuctionStart,
            uint256 currentGeneration,
            uint256 currentFee,
            uint256 blocksUntilNextHalving,
            uint256 currentInvocationCount,
            uint256 maxTokenInvocations)
    {
        uint256 nextBlock = block.number + 1;
        if (nextBlock >= _auctionStartBlock)
        {
            hasStarted = _auctionStartBlock != 0;

            blocksUntilAuctionStart = 0;
        }
        else
        {
            hasStarted = false;

            blocksUntilAuctionStart = _auctionStartBlock - nextBlock;
        }

        if (_auctionEndBlock == 0)
        {
            hasEnded = false;

            (currentGeneration, 
            currentFee, 
            blocksUntilNextHalving) = _getAuctionState(nextBlock);
        }
        else
        {
            hasEnded = true;

            (currentGeneration, 
            currentFee, ) = _getAuctionState(_auctionEndBlock);
            blocksUntilNextHalving = 0;
        }

        currentInvocationCount = totalSupply();
        maxTokenInvocations = _maxTokenInvocations;
    }

    function purchase() 
        public payable returns (uint256 tokenId)
    {
        require(_auctionStartBlock > 0 && block.number >= _auctionStartBlock, 
                "auction hasn't started yet");

        uint256 totalInvocations = totalSupply();
        uint256 invocationsRemaining = _maxTokenInvocations - totalInvocations;
        
        require(invocationsRemaining > _reservedInvocations ||
            (invocationsRemaining > 0 && msg.sender == owner()), 
            "max token invocations reached");

        uint256 blockNumber = block.number;
        if (_auctionEndBlock != 0)
        {
            blockNumber = _auctionEndBlock;
        }
        else if (invocationsRemaining == (_reservedInvocations + 1))
        {
            _auctionEndBlock = block.number;
        }

        uint256 generation;
        uint256 fee;
        (generation, fee, ) = _getAuctionState(blockNumber);

        require(msg.value == fee, "value doesn't equal cost");
        
        (bool success, ) = _recipient.call{value:msg.value}("");
        require(success, "Transfer failed.");
        
        tokenId = totalInvocations;
        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, 
                            blockhash(block.number - 1),
                            tokenId > 0 ? _hashes[tokenId - 1] : bytes32(0)));
        
        _hashes[tokenId] = hash;
        _generation[tokenId] = generation;
        _safeMint(msg.sender, tokenId);
        
        return tokenId;
    }
 
    function metadata(uint256 tokenId)
        public view returns (string memory)
    {
        require(_exists(tokenId), "token not minted");

        return _metadata.metadata( 
            tokenId, 
            _hashes[tokenId],
            _generation[tokenId],
            _isFirstTokenInGeneration(tokenId));
    }

    function generate(uint256 tokenId) 
        public view returns (string memory)
    { 
        require(_exists(tokenId), "token not minted");
        return _drawing.generate(_hashes[tokenId]);
    }

    function tokenURI(uint256 tokenId) public view virtual override 
        returns (string memory) 
    {
        require(_exists(tokenId), "token not minted");

        return _metadata.tokenURI(
            tokenId, 
            _hashes[tokenId],
            _generation[tokenId],
            _isFirstTokenInGeneration(tokenId));
    }

    function _getAuctionState(uint256 blockNumber) private view returns (
        uint256 currentGeneration, 
        uint256 currentFee, 
        uint256 blocksUntilNextHalving)
    {
        if (_auctionStartBlock == 0)
        {
            return (0, _initialFee, 0);
        }
        
        if (blockNumber < _auctionStartBlock)
        {
            uint256 firstHalving = _auctionStartBlock + _initialDuration;
            return (0, _initialFee, firstHalving - blockNumber);
        }

        uint256 generation = 0;
        uint256 fee = _initialFee;
        uint256 duration = _initialDuration;
        uint256 nextHalving = _auctionStartBlock + duration;

        for (uint256 i = 0; i < _maxHalvings; ++i)
        {
            if (blockNumber < nextHalving)
            {
                return (generation, fee, nextHalving - blockNumber);
            }

            ++generation;
            fee >>= 1;
            duration <<= 1;
            nextHalving += duration;
        }

        return (generation, fee, 0);
    }

    function _isFirstTokenInGeneration(uint256 tokenId)
        private view returns(bool)
    {
        if (tokenId > 0)
        {
            return _generation[tokenId] != _generation[tokenId - 1];
        }

        return true;
    }
}