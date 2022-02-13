/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT

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


pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

// ERC721A Creator: Chiru Labs

pragma solidity ^0.8.4;

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    // Compiler will pack the following 
    // _currentIndex and _burnCounter into a single 256bit word.
    
    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // The number of tokens burned.
    uint128 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = uint128(updatedIndex);
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked { 
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
                    revert TransferToNonERC721ReceiverImplementer();
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

pragma solidity >=0.7.0 <0.9.0;
contract Test is Ownable, ERC721A {
  using Strings for uint256;
  using SafeMath for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.09 ether;
  uint256 public whitelistCost = 0.06 ether;
  uint256 public maxSupply = 2334;
  uint256 public maxMintAmount = 4;
  uint256 public whiteListCount = 0;
  uint256 public maxWhitelistSpots = 871;
  mapping(address => bool) public whitelisted;
  bool public paused = true;
  bool public pauseWhitelistMint = true; 
  bool public pauseWhitelist = false; 

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    initWhitelist();
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  } 
  
  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override(ERC721A) {
      if(!pauseWhitelistMint && paused) {
          require(whitelisted[to] != false);
      }
      super._beforeTokenTransfers(from, to, tokenId, quantity);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount < maxMintAmount);
    require((cost.mul(_mintAmount)) <= msg.value);
    require(supply + _mintAmount < maxSupply);
    require(walletOfOwner(_to).length < 3);
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, _mintAmount);
    }
  }

  function mintFromWhiteList(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!pauseWhitelistMint);
    require(whitelisted[_to] != false);
    require(_mintAmount > 0);
    require(_mintAmount < maxMintAmount);
    require((whitelistCost.mul(_mintAmount)) <= msg.value);
    require(supply + _mintAmount < maxSupply);
    require(walletOfOwner(_to).length < 3);
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, _mintAmount);
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setWhitelistCost(uint256 _newCost) public onlyOwner {
    whitelistCost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
   
   function setmaxWhitelistSpots(uint256 _newmaxWhitelistSpots) public onlyOwner {
    maxWhitelistSpots = _newmaxWhitelistSpots;
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

  function setpauseWhitelistMint(bool _state) public onlyOwner {
    pauseWhitelistMint = _state;
  }

  function setPauseWhitelist(bool _state) public onlyOwner {
    pauseWhitelist = _state;
  }

  function whitelistUser() public payable {
    require(whiteListCount < maxWhitelistSpots);
    require(whitelisted[msg.sender] != true);
    require(!pauseWhitelist);
    whitelisted[msg.sender] = true;
    whiteListCount ++;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
    whiteListCount --;
  }

  function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
  }
  
  function initWhitelist() private {
    whitelisted[address(0x08A9834648edb461340102D0445d7382FF58e2aF)] = true;
    whitelisted[address(0x8DEa94aC7A9625e16195961059f88945aad80472)] = true;
    whitelisted[address(0xAc07E26C74562c50A21A25821382ed52CB6e651c)] = true;
    whitelisted[address(0x3032E44e082d74d3557A2A0F5eC537971a60754F)] = true;
    whitelisted[address(0x443FaD4C2Ea59E9D24c083BE0841Cee1FBF6A85e)] = true;
    whitelisted[address(0xFC48426Da0338735945BaDEf273736cCFF53A358)] = true;
    whitelisted[address(0x169efE5FFa1011fd90ee8438785E49066eD8Ed31)] = true;
    whitelisted[address(0x1cE3C5487DaDEF77eade6eA5C56fE958C3fC7c07)] = true;
    whitelisted[address(0x3eeCE4Dd5D965A1836ed264b21A0FC958a3F250C)] = true;
    whitelisted[address(0x46b2bD5C888E6d57a839c559FD6076F2c15A8cB1)] = true;
    whitelisted[address(0x51f11D024b5aa797edA65e80614bA81CDb6Bc1AF)] = true;
    whitelisted[address(0x886478D3cf9581B624CB35b5446693Fc8A58B787)] = true;
    whitelisted[address(0x8AABAce8fDf59E33D876548321Ee7d14f9dC96e9)] = true;
    whitelisted[address(0x8E00016c2e96532ceBdD7eF603b6011D3Be64A2C)] = true;
    whitelisted[address(0xaAc08b2ABD2eC5412d63AFC35Ad86A0C132D417D)] = true;
    whitelisted[address(0xD28eABD0921f2b29F9A8622D0F044098Ff2B86e0)] = true;
    whitelisted[address(0xd54B4Fde949570F18F1C13952a538a1525b6CaB2)] = true;
    whitelisted[address(0xe2CE82CC0176f84d9d94fc37E157E4EC44880E07)] = true;
    whitelisted[address(0xF2B18EeF2bDc79a909aA5f2b4183FC0B716b24b9)] = true;
    whitelisted[address(0x002fc6eE54133b3908D659e4fC93cc66018b9837)] = true;
    whitelisted[address(0x0057fF99a06f82Cd876c4F7F1718BD9A4F2e74B6)] = true;
    whitelisted[address(0x0120701845482355c2345AA31B4b5420aa4905F4)] = true;
    whitelisted[address(0x01Ab06F4Eb304a6f804E26CbE5f16D23D06b68a5)] = true;
    whitelisted[address(0x01f53e1C6018270ba5697EE03D79139525dDA046)] = true;
    whitelisted[address(0x0273791633032554754E967201cd03718e0Ed572)] = true;
    whitelisted[address(0x02868814F0D899633AE6550B1621f9eBB032e861)] = true;
    whitelisted[address(0x0296566745838C32b9955B57f9652540a276DFc0)] = true;
    whitelisted[address(0x02d53ac91ef54bCA4F557aE776579799D6fB4DA3)] = true;
    whitelisted[address(0x02e6a976b1081102d423D16c0950717b75FF7C05)] = true;
    whitelisted[address(0x03570C5AE578DDB3a0E654d7A9CDeddB2d0e5673)] = true;
    whitelisted[address(0x035f95e0fe44268D02c3f6589C815AEcB0C0A5B7)] = true;
    whitelisted[address(0x03C8060E6e38097EA6ABB22242F7E2280485c438)] = true;
    whitelisted[address(0x0487902a77767e30f271576c1c945F0B90976451)] = true;
    whitelisted[address(0x04Ec17F9e8502de87Ee47Fa1c36e8D7afD062B0C)] = true;
    whitelisted[address(0x0528bD05A9D96895b14eA922D2Dfeb17E1240D87)] = true;
    whitelisted[address(0x0603542df0C37dDf675897F12EdcE086c71B0971)] = true;
    whitelisted[address(0x06AAAA4B517C5e6d2E49886A5b53049AEB9aE1a0)] = true;
    whitelisted[address(0x06F999FdF38da57013132F2D3e31CA9121e83526)] = true;
    whitelisted[address(0x08B1240dd2109A80B076219761e866269762C04C)] = true;
    whitelisted[address(0x08b5CE35443d5EBB2751309d351A4b961FbA89c4)] = true;
    whitelisted[address(0x09202adcc6240D813F82E4Cf0D33732A9A863074)] = true;
    whitelisted[address(0x09443af3e8bf03899A40d6026480fAb0E44D518E)] = true;
    whitelisted[address(0x0971e862176f9E7C4F131a9D94290b8254E84500)] = true;
    whitelisted[address(0x0A04fE911785d5C52b9cbAE0CB47a71dA5a402b1)] = true;
    whitelisted[address(0x0A2650ec5e7a22bcD97B24d6a922f90db3d8b08b)] = true;
    whitelisted[address(0x0A3A0cF2B9f37e15d3d559B85b8A26a3099b0894)] = true;
    whitelisted[address(0x0BbE17FfB2dFF302f1EadE3f39390Cf4Ee60F4Fc)] = true;
    whitelisted[address(0x0c201f1e68d3B0188EF0586a1F750DD6de8f22e0)] = true;
    whitelisted[address(0x0c4adE9AC2255b61EE4b5FB40bF596fafF4d3Fcd)] = true;
    whitelisted[address(0x0C6552A920e44208985bE101143AC80933939013)] = true;
    whitelisted[address(0x0d5F1eF9231A937e0ca6033E4033eb3e998FC37f)] = true;
    whitelisted[address(0x0D678c050f0dA05065d9e47a579A6EbbA19D47e2)] = true;
    whitelisted[address(0x0e3c7363dEcaBFE24637CAAD9e6432c6Ab750648)] = true;
    whitelisted[address(0x0e79c644eC160Afe87eA8e87201C0fe35bA63E1f)] = true;
    whitelisted[address(0x0ED5D89f3aFdC6b0C3f7d933eb7a0DeEd2EfE57B)] = true;
    whitelisted[address(0x0F05Cee2b8A580D297919731077f3064df6316E8)] = true;
    whitelisted[address(0x0f181677692b1A9D3FbdEC8Fc4A684963E4ffd61)] = true;
    whitelisted[address(0x0f28fA0946ac4d53Db74bCec1D164491853d4e2a)] = true;
    whitelisted[address(0x0FB3fA40850C1E472B6eCED8FB10781763D42193)] = true;
    whitelisted[address(0x0fFADE3d9175f11Ffb0B40F44e78832784DBe808)] = true;
    whitelisted[address(0x1010595F96Ab62b31BfeAc411Ec5f8f60DB5DC23)] = true;
    whitelisted[address(0x10507Db1eD9ed1ca12154489DDF74D686dcB263E)] = true;
    whitelisted[address(0x109b2373C3DFFe0EE1B974C83Fc5fBB9A7D14801)] = true;
    whitelisted[address(0x10A5CBdD5b4877073fDa5B9Ae653e7dA6A2A60Fe)] = true;
    whitelisted[address(0x117026Eb0C5ED7D365e78710753fc2961E085b2E)] = true;
    whitelisted[address(0x118c5f1f2B376d6eF511c9e54148C0b93d951874)] = true;
    whitelisted[address(0x11b4FB343AD313c7E2a7D2686A932d60C20DcA7c)] = true;
    whitelisted[address(0x126f066A7ceC41152893803Fb55B80cBBc5413CF)] = true;
    whitelisted[address(0x12A794d592C25e7f92dEDd50C31Ee2AB7CCB3251)] = true;
    whitelisted[address(0x1349E61596bDEfF11d6efb4a1DE8bC9B17a39d4F)] = true;
    whitelisted[address(0x138F66B1F3830ad6485A5ba9c85d22C582278D76)] = true;
    whitelisted[address(0x13EEe41d67b8d99E11174161D72cF8cCD194458C)] = true;
    whitelisted[address(0x1449D26e442415E076E044ca97966a284C0C865A)] = true;
    whitelisted[address(0x144B70fBd0566d1930E15A35982b5845691ffDA0)] = true;
    whitelisted[address(0x1450cD95d73aa440D62D6132E5efd9E6a055508A)] = true;
    whitelisted[address(0x147DD6046f61C59dF200546Bf0ADBFE68bdDC76d)] = true;
    whitelisted[address(0x150b68747d1c18853d50BE65631905685E919858)] = true;
    whitelisted[address(0x152b51DCE27Ee622Ae70dDf3875964b3479daFff)] = true;
    whitelisted[address(0x152e15139C0f1a8A4a1E3150A4418F4f2D714C88)] = true;
    whitelisted[address(0x156F3B91565178e01A6cD2b33Baf978b00ed373e)] = true;
    whitelisted[address(0x15B012ae12A18c3DdF19708f3dd44b8b3Ef103dc)] = true;
    whitelisted[address(0x167328cc55423AbBF4C13909ee9eD9b8f03580F6)] = true;
    whitelisted[address(0x16C6a5FB6165d4492d54eaab947becbe94380dA5)] = true;
    whitelisted[address(0x170AcA328D51E15cFb20d21BF5794F3f4B451411)] = true;
    whitelisted[address(0x17A77D63765963d0Cb9deC12Fa8F62E68Fee8fD4)] = true;
    whitelisted[address(0x17B5Aa4832BA0Eeb5b55C8400565b12546562a54)] = true;
    whitelisted[address(0x17e566d94b9E9471eaAA1fd48fEd92666Fe0e6c0)] = true;
    whitelisted[address(0x184198548062CA7f7c243d2F990325cf22A664aB)] = true;
    whitelisted[address(0x18826e1321099A31E1CE324aFaA41d72aeDbdB74)] = true;
    whitelisted[address(0x1898E27601583a9b7Df4b23803C6d2B70a4cd30d)] = true;
    whitelisted[address(0x193d802A97a4632Df34ebA214B8598422830a14c)] = true;
    whitelisted[address(0x19d400354eC96De83B1a517a6D7caA768c344CcE)] = true;
    whitelisted[address(0x19E989a9D6D16522E4B0896020032601d30D247d)] = true;
    whitelisted[address(0x19f6595fBf65b10C9c6f01Ea1de7331F8beBb014)] = true;
    whitelisted[address(0x1a73F73BCdF7BfBf084dB5560A8F8089aBbbe4A8)] = true;
    whitelisted[address(0x1a7860453f766648a598144eE467e74159E7cd1D)] = true;
    whitelisted[address(0x1b7d73BB22E8Afa3e6476E9Ecc5F05Fb532Ea56A)] = true;
    whitelisted[address(0x1D35C173e0558092d88904b8a06F893BCDB7AfAF)] = true;
    whitelisted[address(0x1D92474Bc23b2A57B6C4230b6D304AD1A06DaABE)] = true;
    whitelisted[address(0x1dD3e55ab77eE5d7cb833736b60009A133f1de78)] = true;
    whitelisted[address(0x1e0d4A10a3D2b2eFCaB3BD98fA046bDf6132D676)] = true;
    whitelisted[address(0x1E4bC7f1F6Caf1E033d30FDEF0a4601FdCDcF3Ff)] = true;
    whitelisted[address(0x1e5ca784b2CCdaD1a1d3f33bC272C8538dbD125B)] = true;
    whitelisted[address(0x1e817924A6643CA8caD5799422df2CC5737D858a)] = true;
    whitelisted[address(0x1EA16E00618F61C86f2a2dD83D786bd539136b38)] = true;
    whitelisted[address(0x1Eb9a983eEDda4eFBD36Aa4244fdaaB0e897f89f)] = true;
    whitelisted[address(0x1F38D276f1510f7F2d6F3D95F02891Af2fEB0D1c)] = true;
    whitelisted[address(0x1fCca6CcB88AFBc361f0e2a7BFd0AF7d737548c3)] = true;
    whitelisted[address(0x1Fd2978aC57fB2f459EF1AB7812b58f29aB437BA)] = true;
    whitelisted[address(0x1fDbFfD0d8e237E64E68A904c2a6F447a1aD5C90)] = true;
    whitelisted[address(0x1feE9067d041b4dA0c8cacc37D935a760f3b6454)] = true;
    whitelisted[address(0x20335C504A4f0D8Db934e9f77a67b55E6AE8e1e1)] = true;
    whitelisted[address(0x207adc33B9F105F03af95f161f2963369598e9E3)] = true;
    whitelisted[address(0x210ce89c0fE5222ff262E71f1c3243f1BfDeB113)] = true;
    whitelisted[address(0x21bcA401c280c8492a1Ca15D554382EeCB92F2f3)] = true;
    whitelisted[address(0x21bE7e444967B3d1E8fD0333b7FC3320A9fDA6Ee)] = true;
    whitelisted[address(0x21f131A636992eA1Fa5482f771bC63a02356fB1B)] = true;
    whitelisted[address(0x22457106c538B1dE56ACf7ce12386BCFDc0D647B)] = true;
    whitelisted[address(0x23001f94835E025898a891dc6a8a128453A86B40)] = true;
    whitelisted[address(0x230B2e139A7d56F24120735a32E9b33459a4f63e)] = true;
    whitelisted[address(0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A)] = true;
    whitelisted[address(0x23292E0918D3022470B9e6a7C013a695Ca07F1EC)] = true;
    whitelisted[address(0x2476052Cf6588A71A4fFB5039FE5ecEA4C74cB84)] = true;
    whitelisted[address(0x24a786F52Cde169D00C8f518f30Ec2f5cEf471B6)] = true;
    whitelisted[address(0x24fb6DC785DcA4828165725c3a9a3dBcF0DC392F)] = true;
    whitelisted[address(0x25143Fb39A90346dc852560d214e723B5bdA95bF)] = true;
    whitelisted[address(0x2554dC6A888264262501A4ad50cf2428c3Fa071E)] = true;
    whitelisted[address(0x2566BbE9853b6b90bfE7A5788ddD01735F503982)] = true;
    whitelisted[address(0x25C37149C315A240a44064d24659eb772C63f301)] = true;
    whitelisted[address(0x26035af2d99c8A9AeaB0017921E504029431F2C1)] = true;
    whitelisted[address(0x262836a3c29B2f1123696D2F457b0468d4de0AA4)] = true;
    whitelisted[address(0x2677a482a7D72466ac2Cf5D930aa0731987F8F6B)] = true;
    whitelisted[address(0x271d44c5fd756839cF75b7382F11fFa88A83AA75)] = true;
    whitelisted[address(0x2805fEA05Cd3c681420F9e6a1A318DE0DB7B9540)] = true;
    whitelisted[address(0x280B7674dae3E54e573968849434777b9617c1F5)] = true;
    whitelisted[address(0x2845720856A20d55318AE4B84b89D41Bf307674c)] = true;
    whitelisted[address(0x28993f04250a2b54Ff199ABA411d9C4c9A41f5D8)] = true;
    whitelisted[address(0x28aA594e69b660Af4669bA88FD94a6676855F98A)] = true;
    whitelisted[address(0x28e1fd970ACFD3b025E5fE96AC908a5682401121)] = true;
    whitelisted[address(0x295B0128e6a5a10d44dc6E079b419f1D21B075F6)] = true;
    whitelisted[address(0x2991b1DfdF4258472aCDe8c316Faa313c50E760C)] = true;
    whitelisted[address(0x29E0D24B832A2A0782DCb0281a369e82c3C39389)] = true;
    whitelisted[address(0x2a1da7C4efbCBD95B775224bDBf80B834df1697B)] = true;
    whitelisted[address(0x2A87fACc2B71042d48918e99a5A55Da3Ea868C50)] = true;
    whitelisted[address(0x2a8f1940ff9EdB8a6be937F171Cc12e1E2eAb264)] = true;
    whitelisted[address(0x2Ab1735Ab09F57DB6436aa70676B158ed70a70BB)] = true;
    whitelisted[address(0x2aC4Cd6cD6083EE0f64bA8737E2aBaf020F942e8)] = true;
    whitelisted[address(0x2b177fdb87A9Bab54b55f1eFf89B0Cf785513403)] = true;
    whitelisted[address(0x2B4E6F23c0d78bB78806E1E0306a7625CaF83abd)] = true;
    whitelisted[address(0x2BF546648aF2d883C7c468b409fE375eCaAE8525)] = true;
    whitelisted[address(0x2BFb180820644C17101565C1a875450593DE3Fff)] = true;
    whitelisted[address(0x2CBcEE8ea14d206f131a5E109c05BbF33F8c8201)] = true;
    whitelisted[address(0x2d03e46389af5A5853d15C65Ab3195BB5871780d)] = true;
    whitelisted[address(0x2d53B848079979B6B10202e38290d6F4C2Ff7c5F)] = true;
    whitelisted[address(0x2DCAf9ba3402F3bE3df1e4D15b3aCeed6c2514b0)] = true;
    whitelisted[address(0x2E4432526a20d3A31E49d61226c15248AF2e88F9)] = true;
    whitelisted[address(0x2eDc53d2Fb0DB8f10A488c49d94ca74A831a68A9)] = true;
    whitelisted[address(0x2F710C26fAbb94A229B54475f16C941180861222)] = true;
    whitelisted[address(0x2F8dfdBA59771FEe82150b031a16fc50705b5397)] = true;
    whitelisted[address(0x2fe172123CedD49dD19fEcd5109C570ba9E5Cc35)] = true;
    whitelisted[address(0x2Ff8272EB50a63A73cdeAEd3B2dC05E8265b3cf7)] = true;
    whitelisted[address(0x3055426Acc19853D096022E9e9f0C30f066Cb89E)] = true;
    whitelisted[address(0x3055B4A85cD135728AF28926A1Ea2379925d90A2)] = true;
    whitelisted[address(0x306138e3A8aFbB87e10b0123D1e5F63032c1f9a2)] = true;
    whitelisted[address(0x3085C72ebeC06aB2b5c541A836D89c59888b28A0)] = true;
    whitelisted[address(0x30e62300d679aDEEb3BAf746d31b97C726BE0C85)] = true;
    whitelisted[address(0x310089304b07a178ae057bf12A2a873dDEE35acd)] = true;
    whitelisted[address(0x3108D79FB3953199db057063Be31E73006112477)] = true;
    whitelisted[address(0x31356F6d29aec5c0f3F059a64d2A15622ae775D3)] = true;
    whitelisted[address(0x32135aeaB90aB298642921Fad2069d887349c823)] = true;
    whitelisted[address(0x324E9e6E602fDf1F7F50deCEa6Cb83Fff575020f)] = true;
    whitelisted[address(0x3386c5cC0f55EF9Cbfb8dc927aB06Aa34D04D46f)] = true;
    whitelisted[address(0x339cC7EE5dD728dc158E74709A8384334B999FCd)] = true;
    whitelisted[address(0x33BA6599cB0DB14929ef112c74Cc15D1F5dB9B89)] = true;
    whitelisted[address(0x33F87f51f7b82340801afEE83DEDd4DD4F3578fa)] = true;
    whitelisted[address(0x35D355014B53942E4cC6429d133f5073AB8DbDEC)] = true;
    whitelisted[address(0x3686A4b272C646ef6fBE34377337d95Db7356E63)] = true;
    whitelisted[address(0x36a4D7dF2f79C2B76016aC35dA695290eD8Cfd50)] = true;
    whitelisted[address(0x3764e5efC052F7AD7a1670F32F7E66fAa25C7F05)] = true;
    whitelisted[address(0x37EF5b0a412cd864e368C53F77a0DE4Ac64b93f1)] = true;
    whitelisted[address(0x3808943Ad70CdA79ff3A524DDE9784B1ebb0DD28)] = true;
    whitelisted[address(0x384d2223B8812601B287b52dEb719865a781E0F5)] = true;
    whitelisted[address(0x3872A54e9F577055cc981d672dbde006D0d41C98)] = true;
    whitelisted[address(0x3927f1b51aFD205311BdDdEb5646C4C6A309b2b2)] = true;
    whitelisted[address(0x3A16BC5604B3f7c82BcF819C434005E3aA62F677)] = true;
    whitelisted[address(0x3A2D016124DF975850b84A6A970ECd5725bF793D)] = true;
    whitelisted[address(0x3A97e83356FfF79Ac8c8be95A0A8619c160AE165)] = true;
    whitelisted[address(0x3aB1210537A3d275CcFFEE995134784A2d88cB5B)] = true;
    whitelisted[address(0x3b228235aa52DD0b691777A61c5fd5a65649A75A)] = true;
    whitelisted[address(0x3B28e44823c5F12393b6A4B409dd762F8c76079f)] = true;
    whitelisted[address(0x3B368ED1dE5b6a704f031D4B1ca791aB51036b5E)] = true;
    whitelisted[address(0x3B44d2F615A1A0E50C3403315f056A288D6F14F7)] = true;
    whitelisted[address(0x3bF5217382a815eC75fEC40E9Fb3196AA823F1c4)] = true;
    whitelisted[address(0x3C006ab85a4ccB61382B4f4A6f2E97f469607E7C)] = true;
    whitelisted[address(0x3CacFADb5375b4503FA51Fd0E3dbfD445cb88854)] = true;
    whitelisted[address(0x3cAeAc7FF83B19f4D14C02CDa879c4740B4F0378)] = true;
    whitelisted[address(0x3CcB86a565DAa86D1613A634DD16663779bBD63f)] = true;
    whitelisted[address(0x3D0A9ABa6604663369Ce736CB4a5F21eAf7FAa31)] = true;
    whitelisted[address(0x3d157c57871E270BC70ebc962F90894ffd228975)] = true;
    whitelisted[address(0x3d1df78367d956c4fAFC766cfeCb9Fb2a7Fc479c)] = true;
    whitelisted[address(0x3D61d3da40a372CA317832717d7E6205cEDb439b)] = true;
    whitelisted[address(0x3Dc3C7A65331Bbd9ecB08B9c9284e3d160155376)] = true;
    whitelisted[address(0x3Ddd280cdEA5CC80b65683c0Acc039f01f858189)] = true;
    whitelisted[address(0x3e3349576DD5F340F759FDf52e3f330b80f52D90)] = true;
    whitelisted[address(0x3E9f15DFbF0719e157FAdfD435A4221C004712A0)] = true;
    whitelisted[address(0x3f56121E9D140305AdB81ECAb3c82550E237e8f2)] = true;
    whitelisted[address(0x3f71289F01A262be7FeC3477f39bC0729Adc9429)] = true;
    whitelisted[address(0x40005111b892140f2418624156FC544a172f1562)] = true;
    whitelisted[address(0x40063bF74477F142e5E2c1933eDe3891C5f06160)] = true;
    whitelisted[address(0x403AfDf9Ea925D3b48E719a44610da1679a57651)] = true;
    whitelisted[address(0x4054AD5c3c15c6dFAf16709A79Aa5446509f3E2B)] = true;
    whitelisted[address(0x406Bbd4B112e77D7091E36c23B92ccA918b5419A)] = true;
    whitelisted[address(0x413d825fD9df5C6A02a9558A75287c70046Fe778)] = true;
    whitelisted[address(0x4140100f2229122245E981c3874ba29CC183c8Dc)] = true;
    whitelisted[address(0x42299a01A17FC93eC0Af54da89268e6B49B19464)] = true;
    whitelisted[address(0x42547E29Dc9DB41121510a8853F0fd96Fb6Ca89B)] = true;
    whitelisted[address(0x426C51c967f171999CeEccBc870e463f9B7A7307)] = true;
    whitelisted[address(0x42a75ddE1981F918ba5a84D340811F72Ea18DBF0)] = true;
    whitelisted[address(0x42cc3BA5Cbc8Cff67737A48254d31Fd39C932aCF)] = true;
    whitelisted[address(0x4316881248b39C1cAdB72640604463aAE3B77cf7)] = true;
    whitelisted[address(0x43afd951f70c744870671eC69A81762Dd1DE029f)] = true;
    whitelisted[address(0x43cBBeF1E3F63e7A2Eebd1D181a3a80350f003Ab)] = true;
    whitelisted[address(0x43Fa235eCc245309dDae5C4Be1e3DB9ed9F08f10)] = true;
    whitelisted[address(0x44fa8705438b9934aa7702518982A46529fB122a)] = true;
    whitelisted[address(0x45C4102Cc509751a73ec31D06976277657ceBb70)] = true;
    whitelisted[address(0x45Ff51Bde3b9d1113D9C5288fC8cf1860AA46f0f)] = true;
    whitelisted[address(0x460EC2cEac43deeE182de019b6014Df63597C33d)] = true;
    whitelisted[address(0x461e76A4fE9f27605d4097A646837c32F1ccc31c)] = true;
    whitelisted[address(0x474f4249B70aDDb619BC5986845C7A3c9FAECe64)] = true;
    whitelisted[address(0x475c3D8ED09774069D028B4BC009fecB07f2517D)] = true;
    whitelisted[address(0x47796A2DCE928826d5754b966fe34D181c5bD50f)] = true;
    whitelisted[address(0x47a373f82f9f6B10A281BdE7f53862EA6df201e3)] = true;
    whitelisted[address(0x481C7823E54f000AA278Bab4C001971177737aeC)] = true;
    whitelisted[address(0x4824610A829c89bFC2D8E103568E3FC22130769F)] = true;
    whitelisted[address(0x489e37365f047282bb0136667Fb3E1d5bdbeF817)] = true;
    whitelisted[address(0x48a329fEA5eCafb14CE4f39618537b1E5Ab8337b)] = true;
    whitelisted[address(0x49559793a429A4f5959d9bd40208d6DFdcF67395)] = true;
    whitelisted[address(0x497e113b6195f448807669D7f3DAfC55AF324FFa)] = true;
    whitelisted[address(0x49BE89682318bc5B79fCf33c51eE2bc518FBa992)] = true;
    whitelisted[address(0x49c5e1236a202462A0eE30fa525814468488CEc8)] = true;
    whitelisted[address(0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123)] = true;
    whitelisted[address(0x4A655f46b9CA555D6E89f310186A6B9dDB162D3e)] = true;
    whitelisted[address(0x4b8A930E59b5151Bcf5447DF6DFaC704f5841272)] = true;
    whitelisted[address(0x4bE985173Feb9939BB2342979B9837dc7235ddDB)] = true;
    whitelisted[address(0x4Bf2120F90Feff1E1f443Ad07E542CA6b2F30105)] = true;
    whitelisted[address(0x4C3EDf0a3dD2E6Bc1a7DBc051419651b94d5ACAA)] = true;
    whitelisted[address(0x4cfD427aC7217ab1768f410Efc33a37132b8f3c9)] = true;
    whitelisted[address(0x4Dc1483356A04D2d316Fd21BEb589E2e8ac76F7C)] = true;
    whitelisted[address(0x4dC605F5FF73121D589F1851f9563A9af74B3984)] = true;
    whitelisted[address(0x4Eb227c899665463fd3660710f3ed040E31a3dF2)] = true;
    whitelisted[address(0x4F0657196da1186b831B48e284540dA0d7E9667a)] = true;
    whitelisted[address(0x4f0c752fdbEA79558DdA8273750562eed4a518e2)] = true;
    whitelisted[address(0x4f1A8864AC33813b2192F1f542aB15f8c31b4318)] = true;
    whitelisted[address(0x4f291731d56aD651b390d2FFd078C055655E03c5)] = true;
    whitelisted[address(0x5062B410A9A8D0A235E7197F3EE7D87ad0ab35D5)] = true;
    whitelisted[address(0x506DdEEc475b43F48786e04608b5f8D7F9C3C690)] = true;
    whitelisted[address(0x50BbC5a6AEc6C9B637bDed595e4E9eccA7D78fC1)] = true;
    whitelisted[address(0x516059764369DFbEc3Df6D1d5f1ACDCc72DDC908)] = true;
    whitelisted[address(0x51AaE7357c8baD10DB3532e9AC597efFA5C3820f)] = true;
    whitelisted[address(0x51F062D317B44Fdf7A6953E108Ae5Ae5f7Ab64a4)] = true;
    whitelisted[address(0x5213EC5D5800444e1847c1ac7b7721b15C3483F9)] = true;
    whitelisted[address(0x52a256c00b626D8d00a4ca8D3c23c32EF451FafB)] = true;
    whitelisted[address(0x52eB4bD04DeA22Dc589cC973A96D9e1f9E423c12)] = true;
    whitelisted[address(0x52F182B878Ea4E7f10a9FE093e2313b3c21C101F)] = true;
    whitelisted[address(0x5313c1cec7c72244FEBb81bE440fF4212B0073ef)] = true;
    whitelisted[address(0x531B692Fbc7E265632b9E5d368Be184c04472BD4)] = true;
    whitelisted[address(0x5338111fe1667be2c202E67CAcA67C8Ee9B0d9F8)] = true;
    whitelisted[address(0x534f3C83a5750367C00d2aE49Ee7Fb769DD1A238)] = true;
    whitelisted[address(0x5429C397A1098fc06a4A97c53197a2719a339Bc0)] = true;
    whitelisted[address(0x546e97e67bf162Fbe3e727EE77E6d7b4C17F9cE7)] = true;
    whitelisted[address(0x546f4010c1204b9c52575b6f4DfBB29Bd782E6Ef)] = true;
    whitelisted[address(0x54e5e0Dd6a8fBF5bFF95E4e57cf710A30f659A5d)] = true;
    whitelisted[address(0x54FD1ca1E849E39a85d9f15020eB0136896cF3e0)] = true;
    whitelisted[address(0x555c929D0f0162B6A434d924865Cf10b667F98E2)] = true;
    whitelisted[address(0x5588BBb679e5f0533Ac08Be2781f89CADF85DBBc)] = true;
    whitelisted[address(0x55f5d5C0652702e8FF15DB5FaCe5fb0Fb336b1d0)] = true;
    whitelisted[address(0x561cb224546f9C5a0dF2B274d64aa3aFbf02d5a2)] = true;
    whitelisted[address(0x56B367a6303B3d626bFBabc625B8E0B5BD9452f8)] = true;
    whitelisted[address(0x577ff1Df8C33F95C6180BCD7b56251a9D1f3422c)] = true;
    whitelisted[address(0x578b514A05fBC84D2Fb46294C3B4805a48a158d5)] = true;
    whitelisted[address(0x57e0b5d35F4e90DbA01587a5C84565b2A0c1e351)] = true;
    whitelisted[address(0x5811a26fe25AAb30c9Ef466c32E601be8a4A79FA)] = true;
    whitelisted[address(0x581af5d6Be178E0C48fa21F977cAAeCb3ceA4EA6)] = true;
    whitelisted[address(0x583C040607da037592Da1399F1fC2cb44Eb81d4B)] = true;
    whitelisted[address(0x585A1C44Ce466fcDB57d138A87C3bb97E380C674)] = true;
    whitelisted[address(0x58B3EB75B8390bAdC945312ab1d594AA947577aD)] = true;
    whitelisted[address(0x599C125bedc5b69A3F37c881Dce77713cF28F382)] = true;
    whitelisted[address(0x5a32fb84aF55046EC2Fc3540e333b6C30D66ea41)] = true;
    whitelisted[address(0x5A6751623861A8b6DbBbcc445638caba55aDd302)] = true;
    whitelisted[address(0x5aBc5F885E235c30F99c80B9Da8d21f85f65AEa2)] = true;
    whitelisted[address(0x5ae7d1C67Bb65751379c895E74ae9A8bdd71d8d2)] = true;
    whitelisted[address(0x5aFAe50c1cd513101aa502Aa6353E3313F9fA04c)] = true;
    whitelisted[address(0x5b00F3D1644fF3106248B2C50505A67ABF31efFF)] = true;
    whitelisted[address(0x5B4F87CADC9625CB9B9cFf449324D204e799D19a)] = true;
    whitelisted[address(0x5B5805B7452B5dCd3975fE421a4f07A328F39129)] = true;
    whitelisted[address(0x5Ba55d3707035C4D52C9c6E01a4162697bA26d98)] = true;
    whitelisted[address(0x5C58449F634101aD8be368FFeb6423F929a3EDc7)] = true;
    whitelisted[address(0x5c799fBE242f1ca679A125d66Fe4f4AB3b553719)] = true;
    whitelisted[address(0x5c7d3c121AE854A9B98601E9A05408bf1BBC9924)] = true;
    whitelisted[address(0x5CcBB68cDe5287Fb4aFBAF5a5879c46fED8Ec5f5)] = true;
    whitelisted[address(0x5CE4D43A98857D2b590976EC17DfD46032B7D0fa)] = true;
    whitelisted[address(0x5D0AbBD188fDDB20CA2B0e0DA901759C61E017A0)] = true;
    whitelisted[address(0x5d7297f3d4959f49782F91a40ccFced0f712C03B)] = true;
    whitelisted[address(0x5DBd839A1E46A64886C5e1dF8EE415f216E48cd5)] = true;
    whitelisted[address(0x5e130cB7F8CDCfB5A15018ee5846769703Ec4478)] = true;
    whitelisted[address(0x5EDAe7594dC0E6998bf21721edA38C24FE200586)] = true;
    whitelisted[address(0x5F584aB0D09252081351F7323c20634b29A5411a)] = true;
    whitelisted[address(0x5F974CcA40408C7573976bff175bD99BE5d953F7)] = true;
    whitelisted[address(0x5fff1DE825d2cBc8617336A1f437d17De5F5d6e2)] = true;
    whitelisted[address(0x608acb7B3AEfbA64D85B097FcbB6922197D3a40D)] = true;
    whitelisted[address(0x60A833bb4eBECB2832f85E52d5cd739238aBF631)] = true;
    whitelisted[address(0x60DB719B85c700eDEdc7C68036cC48990a92D558)] = true;
    whitelisted[address(0x60DBC1F41D921066B4eC1d373d86B12e5c26810b)] = true;
    whitelisted[address(0x610D5267C83520cBE2491d822eB63bD16Cb7d296)] = true;
    whitelisted[address(0x612BFe6dB528CA987C2e2e5aDEF1bD99807252F3)] = true;
    whitelisted[address(0x6264F5faD7D8E8585164f85f4A28D72e9b99c6a6)] = true;
    whitelisted[address(0x628d7C45305d073CbD0F1dC587673b83DF35d90B)] = true;
    whitelisted[address(0x62FA9f3548611888BC96F5aE5A2eCA1EF91d4b0e)] = true;
    whitelisted[address(0x641cBbEB074F07D55B471DC71Dc3ABac8e9974F2)] = true;
    whitelisted[address(0x6538869C502A7a22A65F51DC7F122d40D5fe0753)] = true;
    whitelisted[address(0x653d88c5bE999FE81803df064573BF0584f0abA3)] = true;
    whitelisted[address(0x654251FfA3A70f7C4e5e0A736aE45ade639482b8)] = true;
    whitelisted[address(0x65e7a7f6F3fAD6FF5A7ddaC61E22F5E844BDD3C3)] = true;
    whitelisted[address(0x65F7A02a41382b22747C989660a6986E4C3Ed02c)] = true;
    whitelisted[address(0x66726f549248756012167D145eF2cC1895B14936)] = true;
    whitelisted[address(0x669735809FF59029991d52435b274B1B18ADE6A8)] = true;
    whitelisted[address(0x66C2cfF52Fb25386285B50e62a4b9bF86DAd0B1F)] = true;
    whitelisted[address(0x677cadCf44a2E977Cba59c07eB32b7fA9d0Ff614)] = true;
    whitelisted[address(0x67D8C8b467081De46241EC17b7e3b9f64c4147cB)] = true;
    whitelisted[address(0x682958Da7b7AD90AF267f9aE2E34b791382ac033)] = true;
    whitelisted[address(0x683A17ef21F204eAD8580c4e649b737c5610187c)] = true;
    whitelisted[address(0x6848ECf31809466e4059c1890A7a73508609189d)] = true;
    whitelisted[address(0x688ffae751fd12ed525983AF83952d63b6D9A952)] = true;
    whitelisted[address(0x68bcA5a8BDebe05Fb8A6648C7316b4Eb7e19a064)] = true;
    whitelisted[address(0x690246e3357eb55f4D09f7C78F342378554c8B4B)] = true;
    whitelisted[address(0x698D2Dd21a3c178D2EECdBc0a68D404f8Cfd7dfA)] = true;
    whitelisted[address(0x6997aCbcF220978A1a79402420C80804563849D9)] = true;
    whitelisted[address(0x69C38C760634C23F3a3D9bE441ecCbD2e50e5F73)] = true;
    whitelisted[address(0x69d99A55E63715c0fc72a4846c66169D80374942)] = true;
    whitelisted[address(0x69eF61AFc3AA356e1ac97347119d75cBdAbEF534)] = true;
    whitelisted[address(0x6a55623711391Cc8EAB4fdB2564Af79Ee97aDc36)] = true;
    whitelisted[address(0x6b5dB7Ec30D761C47d700d52879De66Be1DB520f)] = true;
    whitelisted[address(0x6B83A1536b9d46162BCd64BBcB56F78D832bD014)] = true;
    whitelisted[address(0x6BA7502bde7D9E27fb0542f398f267Cf92273A1c)] = true;
    whitelisted[address(0x6Be4Bd252c565FACC239B41fdb051177BcBeb3D7)] = true;
    whitelisted[address(0x6bFFCb9526f7ade351867006B1F8896de9d735f3)] = true;
    whitelisted[address(0x6C15D3a7ea840A8Cb2884056233B8aEF8e6E269c)] = true;
    whitelisted[address(0x6C8031A9EB4415284f3f89C0420F697c87168263)] = true;
    whitelisted[address(0x6D460D8ff89fE8814dD40ae68e3F0414ae41f777)] = true;
    whitelisted[address(0x6d7e93dC6D159BDAC80955BA90b40AdBF3aF2bc7)] = true;
    whitelisted[address(0x6d9627b90d81c1E972F571390adfEEBf89057bC3)] = true;
    whitelisted[address(0x6e4047516a1E8360F614f1226573d445272f4DB9)] = true;
    whitelisted[address(0x6e51757d41ad563B9C05904dDdB72b28F1646a9F)] = true;
    whitelisted[address(0x6E76c0EBB2d597E1981dBede53e89d168d28222C)] = true;
    whitelisted[address(0x6E81aF1BcD504a51Da5BD6A0d7DF70D7674CE90E)] = true;
    whitelisted[address(0x6E8f10ecFe545909315Cbf3C0727c3A339e8Bd67)] = true;
    whitelisted[address(0x6Fc2D43A3A63F577Eb2Af1719dC211C1D13FD40C)] = true;
    whitelisted[address(0x6ff540ad2988a3933Adf732C63F53321E4339CB9)] = true;
    whitelisted[address(0x7030ffC140306CEbd8c3CE14C1d826fA28C0347B)] = true;
    whitelisted[address(0x70Ac8716bc5d34D7B71573b406b57A577c352e12)] = true;
    whitelisted[address(0x71132b343C12eB2E2c19e30adBc8E28A22457003)] = true;
    whitelisted[address(0x7132385000c146217d91fbde31755CD75ac8D35a)] = true;
    whitelisted[address(0x714E780FbEd38d1123866AdCDA8B6Ce0B8c45075)] = true;
    whitelisted[address(0x71887d3f89B8456a8413bd4743E642d6ace80b42)] = true;
    whitelisted[address(0x71A3AC6a29bB183Ad6A174A2fDD7770228c3e9Cb)] = true;
    whitelisted[address(0x722D4c3B5aBF15fc894ED2221261BD829d24d064)] = true;
    whitelisted[address(0x72B5D33bcA9BF26334251b449A01112883629C5B)] = true;
    whitelisted[address(0x731Df08901Ad4e64B465050e71fCF204972C955A)] = true;
    whitelisted[address(0x735AA4251131150C457f6Ce2535d4A5381F23593)] = true;
    whitelisted[address(0x73884E7C43bBf9dcda15C2AC6672E4Bd6a236D5F)] = true;
    whitelisted[address(0x738c5552E5a8764B0Aac5981fc3F46D802437578)] = true;
    whitelisted[address(0x73e61e58dCc5aF3308daC0b33551813AB8a39E99)] = true;
    whitelisted[address(0x740c1909E892C53500bcE83fC1d50aa1039d3522)] = true;
    whitelisted[address(0x741F6e1320AcD71D3B0Fc01e4583aDc9AD453013)] = true;
    whitelisted[address(0x74A231f77851D9F854a04197756B6A2508fF093A)] = true;
    whitelisted[address(0x74A7b842FDeb244C152aa5BC8B7fbae362091EE1)] = true;
    whitelisted[address(0x7556c627834f41Bc51f62162Fa2B684e22ebf010)] = true;
    whitelisted[address(0x75671398C524A18A0feA89c0B4E596417891eB13)] = true;
    whitelisted[address(0x758fe70FB1b5aA2AB120fEa9c21894CC40a2271F)] = true;
    whitelisted[address(0x75a117A38CFce76d427F9E6C3dd440094a71c0e4)] = true;
    whitelisted[address(0x7600a927c4476E17E67F1DC005f5A245f861A97D)] = true;
    whitelisted[address(0x76249520D08fb12e74eaf5A116014ea8917eD9D5)] = true;
    whitelisted[address(0x76366CE4a4a3D80F1C135FCfA16546279777f6A6)] = true;
    whitelisted[address(0x76C90db137071f5245581ED95E4cF0e884948579)] = true;
    whitelisted[address(0x76F8e396d1710aEDc3e8d8D49f7f6886d53f6640)] = true;
    whitelisted[address(0x77071885F8E52C181e5bA75de5dAe7F8AFBDB02D)] = true;
    whitelisted[address(0x78a1450692A739396475Ea201A312942F9fb0c2c)] = true;
    whitelisted[address(0x78F7fdE7CA80edd524606DC123E31FaA21A25241)] = true;
    whitelisted[address(0x796567c254d20Fc00FCaD2634BaF94FbA29Adc47)] = true;
    whitelisted[address(0x7979a89716A56325043a150BB69aA1a5cfbaFFf0)] = true;
    whitelisted[address(0x7a1Cf37FFB708490251BE83190DCf0957bBf0b62)] = true;
    whitelisted[address(0x7A43439a162A8aBeFa462B631b414Bfe5d4b98dB)] = true;
    whitelisted[address(0x7b01D04faE0aB2479344Be8dAaEdd0Ae1b04486F)] = true;
    whitelisted[address(0x7b1D30818FcC4df52720f51d5644BC89e5A9AE81)] = true;
    whitelisted[address(0x7b46d40525E1b8Bc9DC293e4cC071C01BE2a9699)] = true;
    whitelisted[address(0x7B5c5757c859703732FD8a8057a35e731ab55E8C)] = true;
    whitelisted[address(0x7b8e679112adcC40Ea813741A5980cA27Ed37f3f)] = true;
    whitelisted[address(0x7bc10fB9Aa3f4fe388f502f9669A5b4249F3cF35)] = true;
    whitelisted[address(0x7bF8bF27e3F300FeCe90EB785e4F09aba827eDde)] = true;
    whitelisted[address(0x7Bfed3cA41c356D951b749d64169A0f6A2e9481c)] = true;
    whitelisted[address(0x7c5504688EB4f81Ed558550066Dc218FfEE1f6c8)] = true;
    whitelisted[address(0x7c58206ec651952A7c7D1c6D1b1ecD522DfFC399)] = true;
    whitelisted[address(0x7ce2C24fa9447da94f15d9255C5F44bFdaf8dC07)] = true;
    whitelisted[address(0x7d989ce97CFF246E23b2c8e9d431e922C3e85dea)] = true;
    whitelisted[address(0x7Dd4E7c48D1b98E98E959e1221dbDF02E61114D2)] = true;
    whitelisted[address(0x7E0A623B4dD59730812B62022C59c2CC3546cC08)] = true;
    whitelisted[address(0x7e3921aea9F82E3EfE564840a5568215Abcd4B79)] = true;
    whitelisted[address(0x7F0e7c7b312DB064968e459302D27EBcb528474f)] = true;
    whitelisted[address(0x7f10349fE2BFd080dC887B4567deFF88f8feb007)] = true;
    whitelisted[address(0x7f5a0A6847fD0FA05C13CBC02f435047b429E37C)] = true;
    whitelisted[address(0x7f6b350Fe7311D10309170210bA270E21F0622E3)] = true;
    whitelisted[address(0x7F72E3106478626ee8b2E16a8ee9Af26f5B55eb4)] = true;
    whitelisted[address(0x7fbBeec889AB1dC16613e325Cc4A81c842FDDa1c)] = true;
    whitelisted[address(0x7fE0EBfC57eb31d744258deB3D173cE92e2Ef0c5)] = true;
    whitelisted[address(0x80F0b99Cf421e4e04170e35bCb89d462C68bD7F2)] = true;
    whitelisted[address(0x814ff0e076695E93DC35B02F1f9b2f91D4C70086)] = true;
    whitelisted[address(0x8186e444c80d08Eb172551aC07D7a89A05238b43)] = true;
    whitelisted[address(0x819524C1B47f52fF4789966111780A684F660baa)] = true;
    whitelisted[address(0x8201B23a1443D18Ef6E7b0B6312f571F8c04E9b0)] = true;
    whitelisted[address(0x8234874Cdfe349104EFbc9088E15698741937BaF)] = true;
    whitelisted[address(0x82E10421FcD48c9786623923fD1E310DED894c2c)] = true;
    whitelisted[address(0x83075e5eF89A4Db9986F6Ade2B40d1201AD3f4b2)] = true;
    whitelisted[address(0x830a706F2FA095BdC2d6a4881DaA23fB8A5Fa709)] = true;
    whitelisted[address(0x838fB06CF2D84414B778370C9973D73B5aA866D5)] = true;
    whitelisted[address(0x84024926db8B245A7A54508421F234e1788eb518)] = true;
    whitelisted[address(0x8404A839Aca323e93b394E738061a3180386bed7)] = true;
    whitelisted[address(0x841728066E0D6f80bD6e042a0B29a699cC16e1B0)] = true;
    whitelisted[address(0x845F33Bf5Ea37Bbc691493c92295f61859937b4c)] = true;
    whitelisted[address(0x84ECeaC5C5F60402A54383C44f9790b685013624)] = true;
    whitelisted[address(0x850A9b8A3C05Cf7e162Ffb3c4602442404f96924)] = true;
    whitelisted[address(0x855d5C5C4FAa7341D43B7123A3a20E824c831995)] = true;
    whitelisted[address(0x856FA31C53dbE0BEc7E095B2f75337ae0d3Dc07A)] = true;
    whitelisted[address(0x85807974f57aa531e2624CD4c03518d4a46e83FE)] = true;
    whitelisted[address(0x86213Ab6b741A572fE6be368C5a0b18E35Ce6A13)] = true;
    whitelisted[address(0x8627fb1AEA05677E018Fe0d3b74E65Bd4F170323)] = true;
    whitelisted[address(0x863b76a911fE973D14a53fD94cbEb0C34563CF36)] = true;
    whitelisted[address(0x86a69e4FA797262E9Cb539155ADF1aE6681A9766)] = true;
    whitelisted[address(0x8751768E2Ff68066F5C1Ce21501046c4a0359E0a)] = true;
    whitelisted[address(0x87c3C247Eaf81728F58609317C81CAd4B9457C39)] = true;
    whitelisted[address(0x8875A3AF3257Deea1682d0E9b35ebAD5653B8803)] = true;
    whitelisted[address(0x8887123bA5350b8259a109c886b2B20b27ceFDf8)] = true;
    whitelisted[address(0x8916D73032d94F5BD4820FAF9CE0dd47B2761b27)] = true;
    whitelisted[address(0x8938BE9CAe4604a154C713c4FF49b92B99621E53)] = true;
    whitelisted[address(0x8a0A569B2937ecC360a686386E34dF83CD2348a3)] = true;
    whitelisted[address(0x8A6A7D2DFd80C43bcf4D8EFe19eC7F44Ed82784D)] = true;
    whitelisted[address(0x8a8C9d751ff5A258503fC7656523690C4Ffdc2f9)] = true;
    whitelisted[address(0x8a97E0c4F2f5C74C6e995649a0d5C3bE167eb394)] = true;
    whitelisted[address(0x8AbBF0430A6601F34F6d2b76198560daD14E5491)] = true;
    whitelisted[address(0x8aD71CBCaf5161c110AecD0Ce6A720ED3367e689)] = true;
    whitelisted[address(0x8aDCb24D66522A22dC42de1487CCF16B999111e7)] = true;
    whitelisted[address(0x8B8963B363a5a51D1c9db72b9933D3B8250c06c8)] = true;
    whitelisted[address(0x8bD94904FE0FDB65cEF83DC4F3B4F88B80A5c5Df)] = true;
    whitelisted[address(0x8BFcb8DBdF1fb5B2f87A79a78A65525483c72986)] = true;
    whitelisted[address(0x8C0c0D92b6b5437caC28491CC9573D34c5995837)] = true;
    whitelisted[address(0x8C1f393c989C667ad20E3d9Df72A4F778C5c64b2)] = true;
    whitelisted[address(0x8C5bA8D0017C92527Daa77b145919A77614dfd9e)] = true;
    whitelisted[address(0x8c77Ed27FF05d0d41612c3fC0f8518D347aFa623)] = true;
    whitelisted[address(0x8c939bCebdb76d9a9Fc12af3389937Ad912A4b05)] = true;
    whitelisted[address(0x8cb377959625E693986c6AdeF82fFF01d4d91aF8)] = true;
    whitelisted[address(0x8D42638FcE46eF0BF19dEAaD8cD6801eC58b9634)] = true;
    whitelisted[address(0x8dA4fE40495897C4a68396Da09b0344030858E14)] = true;
    whitelisted[address(0x8df57abeb39322C065f93E105fbD6AC4758D7782)] = true;
    whitelisted[address(0x8e0D17dab1B3e7BB40402E8bD33F47c9D3a16657)] = true;
    whitelisted[address(0x8e47B0b287357d97fb3720BCb85f048dABcB923F)] = true;
    whitelisted[address(0x8e6e5ECDcB7f59955821367f006f1B9D1C710B59)] = true;
    whitelisted[address(0x8e8dcA5b4677e3F992EFf3e0241109D013174865)] = true;
    whitelisted[address(0x8f3FCc99c84c914Bc80166BaD316b9a5875bde6B)] = true;
    whitelisted[address(0x8f76300DA80EF04f1cd4767f9d3C1b70f22e2c96)] = true;
    whitelisted[address(0x8F8B4759dC93CA55bD6997DF719F20F581F10F5C)] = true;
    whitelisted[address(0x8F903cFC0Af3C2EC0d872c57538AF5e071544a57)] = true;
    whitelisted[address(0x90dAc9266DC23064Aa07877cd90576664A659b82)] = true;
    whitelisted[address(0x915B472dfA70C8FE9D074a8c859089c44252D6b8)] = true;
    whitelisted[address(0x9268b5650a0cdaF0B5433c14aD37e0e84D8d5FB3)] = true;
    whitelisted[address(0x92B3a3c748aF31DfE71D79F9020fC501b3a222cC)] = true;
    whitelisted[address(0x92d5A477deE70EF861c5c712884f005aeBa4F3b7)] = true;
    whitelisted[address(0x92E08E89D388083C1F5625Eb4B6712b40e5F8Bde)] = true;
    whitelisted[address(0x9311AE3f67B6eE5469168C85448E2A03b0478C48)] = true;
    whitelisted[address(0x932c3BdDd0DDEf23Fc31286B4bC651d4E3c2ee58)] = true;
    whitelisted[address(0x9354878eFaA0D6D821B7264B22672423E89f0Cc1)] = true;
    whitelisted[address(0x937d084e2951109AD5F3CD114Ff2A96C6ccEb562)] = true;
    whitelisted[address(0x93d0eC9e86f65eA032F2baea93d5d47A176A4d2D)] = true;
    whitelisted[address(0x94040D6352613DFA5596A98fF2F2D1C0692633aa)] = true;
    whitelisted[address(0x943E771B93249cEd39197Af8Ec37C60e18DFf3d7)] = true;
    whitelisted[address(0x94d40848908363b78c760beCfc2873C05718000B)] = true;
    whitelisted[address(0x95649f108393a38D182e148F0424C2604CdA8cC9)] = true;
    whitelisted[address(0x95c313F8b1326A3C72c1B8C617c0ecc9491DFbA9)] = true;
    whitelisted[address(0x95f29D69EB0d19353095EEa4DB88a0871d533aDf)] = true;
    whitelisted[address(0x960C9a33808aE928E263851c7418f4F8eae3c52B)] = true;
    whitelisted[address(0x9633aA121026943F41cc204A32B58e0324362beE)] = true;
    whitelisted[address(0x965A3c654E89eA57a7eA6c255078d5fFDe0F6508)] = true;
    whitelisted[address(0x967Edc401472dc8b7dc3b9E51bc66bD6477EE209)] = true;
    whitelisted[address(0x9693200746C056Bb3E548B6A25c5Fb1d5db2d874)] = true;
    whitelisted[address(0x96c195F6643A3D797cb90cb6BA0Ae2776D51b5F3)] = true;
    whitelisted[address(0x97259b59e08b5DBd72D03653AADF94986C019eFE)] = true;
    whitelisted[address(0x976E240875874067c89Caa2E31027DC7F7C47aBe)] = true;
    whitelisted[address(0x978C54e840D37e0fBdbcf2E2CB241D68a92a950c)] = true;
    whitelisted[address(0x9796260c3D8E52f2c053D27Dcb382b7f2a504522)] = true;
    whitelisted[address(0x9832DBBAEB7Cc127c4712E4A0Bca286f10797A6f)] = true;
    whitelisted[address(0x98771321ad898eD7e2A367fC860aaf398E070807)] = true;
    whitelisted[address(0x98f1ae97C69d0cEdfAAC46d859A033587adfdf8F)] = true;
    whitelisted[address(0x98FE2866EaeC69778dcAe4b3F64e505811f86edb)] = true;
    whitelisted[address(0x9a48E63742CE93cB2dbF5bad3F1956c7C7fEa262)] = true;
    whitelisted[address(0x9a678b81E235669e627833f153199ec87135FD8e)] = true;
    whitelisted[address(0x9A9f7885a9a0b9EFD48D1eAFA17e2E633f89E609)] = true;
    whitelisted[address(0x9ABd86b849aAFA01E4f383690Cd1D5595c2b2458)] = true;
    whitelisted[address(0x9ba3E099C986268d9997f8e013A85467915eBDdE)] = true;
    whitelisted[address(0x9BD91abdf39A167712B9F6c24d1c9805d5FB9242)] = true;
    whitelisted[address(0x9C43267f4f84F5b2cABE9629A14A56cA19D19dc3)] = true;
    whitelisted[address(0x9c9682C108FD7229113121c9C7a497502d130A06)] = true;
    whitelisted[address(0x9D86F34deFa178Ad1549aFa9f508D8911ba1922F)] = true;
    whitelisted[address(0x9e932d1b6a022Ed40101cf368AbaA816c85fB747)] = true;
    whitelisted[address(0x9f1DB99469E373E72c42e1A3B70C4BBb4Ed67B95)] = true;
    whitelisted[address(0x9f76Ce789B57351C6531b86bb9C483D937C43C29)] = true;
    whitelisted[address(0x9F9F64b725f4c21095135E2ECc68c75F8A65cFCf)] = true;
    whitelisted[address(0x9fbC036c044B82e01ea87584B94A7A2FD3732B69)] = true;
    whitelisted[address(0x9FC0898FE75760644d2c7B3ac4873B0FA8015FB9)] = true;
    whitelisted[address(0xa00ECadae8Ef39AF7CB49630f15aa0Ec28EA385a)] = true;
    whitelisted[address(0xa03611d16f53c9E0a4332296Df786C44feB58F89)] = true;
    whitelisted[address(0xa0393A76b132526a70450273CafeceB45eea6dEE)] = true;
    whitelisted[address(0xa06Eb1A338648dB5D4dE6664098c37462b0Eda37)] = true;
    whitelisted[address(0xA09110caF0e83BE6aD5416D3C23A496ba53F6aFf)] = true;
    whitelisted[address(0xa0eF45d5c903cF434b7dB2a92DF14C3c56E2058A)] = true;
    whitelisted[address(0xa1035Aa2E4750a6482DB805321824815c73B22B7)] = true;
    whitelisted[address(0xA11CD2B77565Ee8c7D27B5163D7CA1B84Ec4072d)] = true;
    whitelisted[address(0xa12A5c2bdaAdE76E54cf85d72B37975550dEB570)] = true;
    whitelisted[address(0xa12f07B45388fA68C7fF6B4189AeC886e5eFff60)] = true;
    whitelisted[address(0xA148Fe19EA6689e9EFC6D1CD8c8F834f6ceC86B0)] = true;
    whitelisted[address(0xa1cE8cF0E40AdF551CDdC4Cecc1B4f94b96Eb542)] = true;
    whitelisted[address(0xa1f6BA1E968eB4A2c4BD4ac69aC7afDC2689AC0C)] = true;
    whitelisted[address(0xA225CC0aE57ecb003D9B334859efB77A96C8F948)] = true;
    whitelisted[address(0xa2Af0f6e3Ea05C76ddC68b5cDefB8fd780681432)] = true;
    whitelisted[address(0xA2E983ee245aD36964919704cb03E5179f18a30c)] = true;
    whitelisted[address(0xA2f31cc4b77c45d58c0068e9a6AE51733DD80b49)] = true;
    whitelisted[address(0xA39ce92785b1A68B084D6BE13AdBB00C6725eA53)] = true;
    whitelisted[address(0xa3F581A05296F35ad684BE27e0681eb2A46E1Dd2)] = true;
    whitelisted[address(0xa49A2864Ae7Ab6F58f9F19BA6B51249905A21623)] = true;
    whitelisted[address(0xa4CBD8899FEb43ebD792cC65488924d19c705D55)] = true;
    whitelisted[address(0xa4d80978BB057B6e1AfB0E47EB2b4879483C295D)] = true;
    whitelisted[address(0xA4fd65694A9708C2d204BDF7acF8b9c09B105903)] = true;
    whitelisted[address(0xa530f7739413e787c205233658185edC1e68C25E)] = true;
    whitelisted[address(0xa54820398e7945DdA4f2c894156F0F34f15CBa07)] = true;
    whitelisted[address(0xa5D5404864E9eA3104ec6721CA08E563964Ae536)] = true;
    whitelisted[address(0xa638cEfe07a8E186a08D16993075B799521F1df7)] = true;
    whitelisted[address(0xA75C6950871495082EEf89B850bE547b1eEBdE6E)] = true;
    whitelisted[address(0xa7dfFAC8974ec0550C7EEa9dF10ea4ba7B12A861)] = true;
    whitelisted[address(0xa8e29741eEF79e9c304E75bFD0d179F90CCb6280)] = true;
    whitelisted[address(0xA921b3fb76B85a8581691fd4A873b13c258e167b)] = true;
    whitelisted[address(0xA961C1A357018b88a4970Bb146A02223643b8Ea4)] = true;
    whitelisted[address(0xA9E8b2244AE175b485352dAb119C8c4c7B634e4c)] = true;
    whitelisted[address(0xa9FfaE7701e5b364CdDCbC16Cf583F244E5B4d21)] = true;
    whitelisted[address(0xAA217386D998762B5D65880Dd78Ae7b00A8800fA)] = true;
    whitelisted[address(0xF1Da6E2d387e9DA611dAc8a7FC587Eaa4B010013)] = true;
    whitelisted[address(0xAAF4ECA1bf2B7EB0d405925D910e0B783C4d3192)] = true;
    whitelisted[address(0xAB2c57668Cb7ecd1CF27F360a89516B6A9987EF5)] = true;
    whitelisted[address(0xAB47b66bb804A59F9dfD07c059D9aeE7Fa5A37F4)] = true;
    whitelisted[address(0xaB5B61160F6985e4E4B030be4dE47eAB1630a057)] = true;
    whitelisted[address(0xab5eE3f1c290c1f9Bf45D461aF22bFdcBb94c716)] = true;
    whitelisted[address(0xaB867BE4C031EA93798f2AB13be34bE46e50BC11)] = true;
    whitelisted[address(0xAb9d4311cDf2B777220B955cDe5D6b022b9cCF96)] = true;
    whitelisted[address(0xAba043c5c6f970507905D78C7C366CFd7b32D941)] = true;
    whitelisted[address(0xAbbd63F46D5a645A25E2a3e3b6Ba6481A37F208C)] = true;
    whitelisted[address(0xABDAbF4A1c7C6a107F7183B0Bd381c2C4410fe40)] = true;
    whitelisted[address(0xAC8DD35eCB0d1ab5F0F9CEF7100D42bDb81448eB)] = true;
    whitelisted[address(0xAC98E464EfE2ba89cf5ae888A2EEEe7Ba0C19688)] = true;
    whitelisted[address(0xaC9Fd8414fF31ac4B1aBB0EF242f29B6D0d4dD95)] = true;
    whitelisted[address(0xAcCB9e02E2ecf1c59960588Ac48DA6540a875469)] = true;
    whitelisted[address(0xaD4489f64a8be791294116D3E99D2721C7f0a72A)] = true;
    whitelisted[address(0xAd7091A6B4302EFb4d18Fe045762a0347D959468)] = true;
    whitelisted[address(0xaDdB35cdFD6bD3441b61d5AA5e14537aC8222Ba0)] = true;
    whitelisted[address(0xADe573de628741f7f31e28197Dd637C30685fE2F)] = true;
    whitelisted[address(0xaDec3C8FC2324408a5e678C9A7906961DdEe4E02)] = true;
    whitelisted[address(0xAe06A3Cc904366C010a1C9e1a3C4030Be343c8d6)] = true;
    whitelisted[address(0xae08bc16F9AFB623EFE894147Dc36ed0eeB5CDB4)] = true;
    whitelisted[address(0xAE60C874eE07f44fB7BBbD1a5087cDB66E90BEd8)] = true;
    whitelisted[address(0xAe88Abd8647549FDBfb42e974a5DE46C55249288)] = true;
    whitelisted[address(0xAe9cB20372f80A56f14215A47FB0cE9e43225ec1)] = true;
    whitelisted[address(0xaeb7c50878120E6dc8B97e14BA386Cc749812708)] = true;
    whitelisted[address(0xAF02c7b6A919D2A89000A569dFDfa90DFB48ebff)] = true;
    whitelisted[address(0xAF48726A02DA567B30f5534B383A066f2ed2Aa14)] = true;
    whitelisted[address(0xaF6EDa4c74e0c4ccFb97F4c116B2eE4e84295ccd)] = true;
    whitelisted[address(0xAfC35CABe575dA4c18546aE8Efc40C534D4057a3)] = true;
    whitelisted[address(0xB1Ce2c57A6f8816113fd172A75fC3B9803320228)] = true;
    whitelisted[address(0xB1d115394c34FBCd87DA40e1e0371C523fE26317)] = true;
    whitelisted[address(0xb1D61f01Ef1669010c22fE3e2b1De8852c6Dbb65)] = true;
    whitelisted[address(0xB1ff9542aC3cDf84AA4b659a6a5C69a70c3a179F)] = true;
    whitelisted[address(0xB20b5fB144e09f3761A254DA2C6bf22fF4Ab0D90)] = true;
    whitelisted[address(0xB2C6e55eEF32C0B118C548cB12d0Dc04Cd0c151B)] = true;
    whitelisted[address(0xb2D37EE7d37B36541655bF3F1f1BBE5dD7e9a7b4)] = true;
    whitelisted[address(0xB2E14d9760B1d197cF04d8cBC961f274e746430F)] = true;
    whitelisted[address(0xb38a8820D9ef5798DA2F959C93d1b8f29ba0b434)] = true;
    whitelisted[address(0xB3A03242029AE5AF36B1824fe72CEd2D7828833F)] = true;
    whitelisted[address(0xB3a290335D7af543D0b42Ddfd0A4b6626B417c17)] = true;
    whitelisted[address(0xb45d6D0dE883400De33F08Ad97DDc086d49B1CD9)] = true;
    whitelisted[address(0xB4A8D73fc5C079Ebc562149C04CE4ff6D2B8932f)] = true;
    whitelisted[address(0xb4BE136d2FF6583C07812EdD5bB92e03206B63fd)] = true;
    whitelisted[address(0xb528a98FF4fE831A7CF3c40572472862BE109D88)] = true;
    whitelisted[address(0xb55dCf7f3642d7229523B37e2E97A27B2D8bfF28)] = true;
    whitelisted[address(0xB580bEb37D0940141c0f17Fd362C91e56A19C27e)] = true;
    whitelisted[address(0xb5C63de24208eDE3aA15D6Ec2053B3e537Ef04Bb)] = true;
    whitelisted[address(0xb5F966Ab3AD40e8Ef90ce660A91F3Ad16A211680)] = true;
    whitelisted[address(0xb69000eE1Fd107D05904391Cf768b77cD76E3745)] = true;
    whitelisted[address(0xb725266b2294fa0d59AB40939B619aC48A829573)] = true;
    whitelisted[address(0xB72dc1e80A501256ED235a32A815b78FDDFBf811)] = true;
    whitelisted[address(0xB767e25829819b8e49c7B159802276B4e49a4579)] = true;
    whitelisted[address(0xb77F3a59E605cC487659C2816cF844635530846e)] = true;
    whitelisted[address(0xB78000150490739ACBbD735b3D79C030499F12d6)] = true;
    whitelisted[address(0xB7AAcA9073E115D0cB57e4883986D46A290c3C10)] = true;
    whitelisted[address(0xb7AFD63bb2D0BeC53adbC4F7DB37c63d0bD1272c)] = true;
    whitelisted[address(0xB88f65Bd2493BA8e4fc15d9D0C3905d16874e9Bc)] = true;
    whitelisted[address(0xb8f4BF5D78383f5Ca09Ab00D4f199f2171e6f3c0)] = true;
    whitelisted[address(0xB8F5855b2dBbE6c5CD9dea25571f945F14B99Bb4)] = true;
    whitelisted[address(0xb8fcddb0dc67d65C6354fe5948170A5f6F1f6DC2)] = true;
    whitelisted[address(0xb9825aAf3326136C004d4dF5bE17c0234BF5B474)] = true;
    whitelisted[address(0xba2eEb81f0e405310C9b9b500994238Ab6989307)] = true;
    whitelisted[address(0xBA447324b50696C38283d57f504B1ED8B49b3C4E)] = true;
    whitelisted[address(0xba5784cA3E29565f487aa3049D39401569F83883)] = true;
    whitelisted[address(0xbA9dFBaf86060b014F37e13af5AFA060053f6Fb4)] = true;
    whitelisted[address(0xBB416fECA6C36a13e7848EaEAB0099D02A3440b4)] = true;
    whitelisted[address(0xbB4db555C87AEb8f7589FB04464690A9c617478b)] = true;
    whitelisted[address(0xBB5eB75a8AD51dfa60408d76EF6df8069eee405d)] = true;
    whitelisted[address(0xBB7D62e9bF012B2De27c1f2a0d8BD90397D3c660)] = true;
    whitelisted[address(0xBBE74dc49949A944909c6b15b03aE7aEAf072d1d)] = true;
    whitelisted[address(0xBc159B71c296c21a1895a8dDf0aa45969c5F17c2)] = true;
    whitelisted[address(0xBc3d8b2f5048D56a45945D35638D7E973a5a82A0)] = true;
    whitelisted[address(0xBd1CDda6c79296030cE81D7071eB70E12d4B3895)] = true;
    whitelisted[address(0xbd4564c7082665EfEaA2E178643388f2068f5085)] = true;
    whitelisted[address(0xbd7931081C39Db0759eE68B2E7040bBc7FD08aF4)] = true;
    whitelisted[address(0xbdd0FBf3481611ebc81DEad1AD16939DfD53B93C)] = true;
    whitelisted[address(0xBe7dCF29d3BA00660B22E1AFf7b1573A39Ce03cd)] = true;
    whitelisted[address(0xbE87477cC374473b1143308f35A8642Bf5722e49)] = true;
    whitelisted[address(0xbE8Fe12B9EB1CA2a593e6C070c71c294b6FE9f00)] = true;
    whitelisted[address(0xBEA28617CF5757be6cabC36Ca9CDa266DDe9325F)] = true;
    whitelisted[address(0xBf3094896deEa522BE9cE170be80de5f5f34E2Cc)] = true;
    whitelisted[address(0xbf48216Dbc1c4EdA52148Ab6c5CaEB7cCa861871)] = true;
    whitelisted[address(0xbf4E93EcBD6B7071645B7cA69345FAF1e228BB09)] = true;
    whitelisted[address(0xBf5EE70F178412f3b02BF414038A214A6fD15bD5)] = true;
    whitelisted[address(0xBfA7262D82d93d1F679bC15276F4131e6F57575a)] = true;
    whitelisted[address(0xC0130Dc92ED0AD39207019BdC1272B71E5e3Bfe1)] = true;
    whitelisted[address(0xC0bd687ff2b9BfD7458B3B9086D0aE01319Db80F)] = true;
    whitelisted[address(0xc0eBE72C83646F39197F12935b64d2E581846a26)] = true;
    whitelisted[address(0xC0F6360c1551D8934c0E6e8Be6af8926d7D9e417)] = true;
    whitelisted[address(0xc0fA854Ee4dd016Fffef1A72Fc2fbe46FA1486b4)] = true;
    whitelisted[address(0xC14833a0d90126a74EEE50794F31d9D05Fb95Cb4)] = true;
    whitelisted[address(0xC193d0FCA7C4C4557F5640a86c175D0a11D04c03)] = true;
    whitelisted[address(0xc1dc7965b9606066D9B2114b01Bee430FEaa859F)] = true;
    whitelisted[address(0xc1e19c10DB03051d675Dd6E82D776241B9FfBe11)] = true;
    whitelisted[address(0xc230225bF14836ca1840aB9EBEA8b7A872f45AF4)] = true;
    whitelisted[address(0xc2d10994ebe2b19E5F02aE498cC5bbA0D8324ea4)] = true;
    whitelisted[address(0xc2e5e9Cc4F26Dc179C3f386e702283576B5157Fb)] = true;
    whitelisted[address(0xC310e03D5E88635a214AC05CC60fcf8D83c1376a)] = true;
    whitelisted[address(0xc315155D817140250D238F140142a10b69Fa1c4e)] = true;
    whitelisted[address(0xC352644C82d8B47D01Ff8B707833C767929c95a2)] = true;
    whitelisted[address(0xC3C50d8Ae310A06800696Ff7218458350cfcCA1d)] = true;
    whitelisted[address(0xC3E24494c2da66B5B6287d46d2a9B0b02b868B3b)] = true;
    whitelisted[address(0xc423eC887183b5D5845baa522C534ab6cc1444e6)] = true;
    whitelisted[address(0xc483BEFfd95242934ec08C68a5C217c6a3c82bF5)] = true;
    whitelisted[address(0xc492007f04bF3Eb00c9c126De5C7545906a14b2E)] = true;
    whitelisted[address(0xc4dfCA8e5ef803feB8CFddc9a34389F192EC7F32)] = true;
    whitelisted[address(0xc5C08107950750c24861758671846959205B495b)] = true;
    whitelisted[address(0xc5e2b4Bd2a4fCC7b9C0775D9Fc40Da3942D614Bf)] = true;
    whitelisted[address(0xc5ea9Eb8CDbA62E0a7d89b4fe6a2431aFe64133B)] = true;
    whitelisted[address(0xC5F1B1ea8b25B40c1e9e7bfFb41511Fee3433D31)] = true;
    whitelisted[address(0xc6387b820D5B270618f043799F5472CAcC44CDdb)] = true;
    whitelisted[address(0xC64A2Cc5BCca4b28889594F0715feAd1574da926)] = true;
    whitelisted[address(0xC66eec223a82B78346DD46471f8dcaD0654F3D8b)] = true;
    whitelisted[address(0xC6c1dBD9FBE38ACAEc5f5FD5B55586C15B07Dfc6)] = true;
    whitelisted[address(0xC6C210E56F7E146883DcDe3a99233FBc86803fC3)] = true;
    whitelisted[address(0xC6C401663D66bBA46d61903C75D49159e3Ce4582)] = true;
    whitelisted[address(0xC702bdC4630900A7971f35AaC9097bc6639f30a4)] = true;
    whitelisted[address(0xc743fB483F63cdC1d6509DfD25E0D2B305981F2a)] = true;
    whitelisted[address(0xc76d0C717C27e3d08215203348388c81D0646F9F)] = true;
    whitelisted[address(0xc7892218FfE73AaFA2Dc1Bd118d26c2C324c1291)] = true;
    whitelisted[address(0xC7a573443749352a0e20AE0b5DB4CA80648fe810)] = true;
    whitelisted[address(0xC7e2919731b1393BEca1Eb98bb134372cf0052Db)] = true;
    whitelisted[address(0xc8C32E208183Ab8eCcE10e0f588023faD39cA523)] = true;
    whitelisted[address(0xc968416370639A9B74B077A4a8f97076e4Ae1D9E)] = true;
    whitelisted[address(0xC9AFA68a7eF45524187bA29cebf96785E1eb7C01)] = true;
    whitelisted[address(0xca12efF294E3599B214Fea18d5c9034F003FFCA1)] = true;
    whitelisted[address(0xca2617c0C16a78dc0B29Ca72a88785E5797ae61f)] = true;
    whitelisted[address(0xcA56426Fb389B5E2440879Cb5fC644418002Cc77)] = true;
    whitelisted[address(0xca5b22d1a8903788236ba718e9d288FeC3a0A7d1)] = true;
    whitelisted[address(0xCA7fE7122AdB023c6d0362c85F883bD27c340ed6)] = true;
    whitelisted[address(0xcA968044EffFf14Bee263CA6Af3b9823f1968f37)] = true;
    whitelisted[address(0xcB0eCC860f565292fA355c229B13cf103c3A7bB4)] = true;
    whitelisted[address(0xCB2fc9461B4a0C0a06fC176b1757C5BCA616F1d9)] = true;
    whitelisted[address(0xCB6560B30BE7aB328e7045cd0079051f014AE699)] = true;
    whitelisted[address(0xcc4A82b6A10067bd082d0FEB3405207719eDa85A)] = true;
    whitelisted[address(0xCC811Ad1Fd46FF65Df9E6c6dc0181874e9957707)] = true;
    whitelisted[address(0xCcF43Dcc4e52e0216E461955bd98B08DA53213eA)] = true;
    whitelisted[address(0xcD4688e62b06673353629B990C61a150D5000F88)] = true;
    whitelisted[address(0xCDf0948cC738Ac26c1FA83Edcb96B87591F64dbc)] = true;
    whitelisted[address(0xcE51cccb82b7e59688315bd9E25647c198ca8A07)] = true;
    //whitelisted[null)] = true;
    whitelisted[address(0xceEe10faE3Ff68E73a3f0F4847CB1F82147eB599)] = true;
    whitelisted[address(0xcf0BCF55E6d2ff447784a10773c6340Fce228BcD)] = true;
    whitelisted[address(0xCF1110e2c6BA06d4b54794Af3D9cA413FE013f77)] = true;
    whitelisted[address(0xCF2fDC3Fc241B3569C7B6871b21239F6895dE80D)] = true;
    whitelisted[address(0xcF3c264Ca5d3bEc8ad1966A02A46f53B8e722353)] = true;
    whitelisted[address(0xCF9BFCF8C34930933328725c8958f36D709E9496)] = true;
    whitelisted[address(0xD0A067aF1111e8499a2635b5ce445f239C9Aba29)] = true;
    whitelisted[address(0xD13297C1AD2220438989670a9680FA53c9347A2b)] = true;
    whitelisted[address(0xd1485406996381F88999DA9789e2F03D69BC53f2)] = true;
    whitelisted[address(0xD1691D8Ecc04eD5368C1CD055d408b2A30Ee2BE7)] = true;
    whitelisted[address(0xd1948313060bFebcd11C5f3a67C3b5e133A66c9c)] = true;
    whitelisted[address(0xd2749E7729d61B8dAF41f4e26f5Bf5D0047481ED)] = true;
    whitelisted[address(0xd28c8260F20D97618A3E4Ec8D083f1dc330E25E7)] = true;
    whitelisted[address(0xd29Fa752a2647EEF4D6141f0f9D41F366808683E)] = true;
    whitelisted[address(0xd303717C61C8A6804EdBfeCee3769Ec5228f7b71)] = true;
    whitelisted[address(0xd36954DF517cFd9D533d4494B0E62B61c02Fc29a)] = true;
    whitelisted[address(0xD369cf51fAeCb90a8b8c9b2e28481912ED5791AA)] = true;
    whitelisted[address(0xd388b0C6061da49D9bE366a0470De135201717D2)] = true;
    whitelisted[address(0xd3AA10B12eA74b65820F6CbCc6568ba81fA51a6A)] = true;
    whitelisted[address(0xD4004668cdADb5Fedb26EDAbFcf964e5b54b279F)] = true;
    whitelisted[address(0xd4822DC27B7F4C56225275D00c2228c7c1f06022)] = true;
    whitelisted[address(0xD48FaE12b4Bd481C29130C236f0b345e77D1ac5f)] = true;
    whitelisted[address(0xd4B3e03531f897083af5ea4b99119F8aDBaF0a82)] = true;
    whitelisted[address(0xd527F4AE525cA3D2c6037E9EBfE68112Da0c498C)] = true;
    whitelisted[address(0xD551076646DDAeCa92810c31bC42da56204310B0)] = true;
    whitelisted[address(0xD56dbDD50681a72181cfD2417C5D1A5DA566513B)] = true;
    whitelisted[address(0xd5D971E73f45E3559925909134118755c3662db6)] = true;
    whitelisted[address(0xD5F1B85d88010C74864DA7DA522edf5e6200c452)] = true;
    whitelisted[address(0xd5f45430f18f31FcB4b5129b618e24A9bafaC1e3)] = true;
    whitelisted[address(0xd5F997BBbbec8750E31f2851859aC75Fd8272bc0)] = true;
    whitelisted[address(0xd69F56cDF10628382AA7AB72fCEEe50017d59634)] = true;
    whitelisted[address(0xD6eC35b3A2339DbA5e71E086D5eE34E7E74ED4b4)] = true;
    whitelisted[address(0xd6f4FF94250302cBaDfF10021710E93D001EFDcF)] = true;
    whitelisted[address(0xd710FB7CF82c202cC83d8616B7C5cbA2C52D6e9b)] = true;
    whitelisted[address(0xd7189A81961CB3cC0Dd6eC6a1f90Bc5f95DfD7f0)] = true;
    whitelisted[address(0xd78F0E92C56C45Ff017B7116189eB5712518a7E9)] = true;
    whitelisted[address(0xd7Ae1F1660C4a1f898A4875a46d5dbc6C03C292E)] = true;
    whitelisted[address(0xd7C253751771B3Cf8424f8DA6aDD0B4D6345965F)] = true;
    whitelisted[address(0xd88809018C63aB48c284342E24C11805d4870D43)] = true;
    whitelisted[address(0xD8BcFffBF8dC67353CD0739F4F2ad487C657D5b0)] = true;
    whitelisted[address(0xD8e77DbEa06f2CC16732ac3CBDb5a3e3023e28Ea)] = true;
    whitelisted[address(0xD8f76F9B09984150ae868DEB81ECBf33352f9fD8)] = true;
    whitelisted[address(0xD9f4c3C2D0068D906c07c63fCBCacE55a69E07Ea)] = true;
    whitelisted[address(0xdA0FB480B86a150C065455fF9969F6788876aa74)] = true;
    whitelisted[address(0xdA44E1c6AdDF1D218cF9633F6E1eDFFE11e41Ea6)] = true;
    whitelisted[address(0xDA67f6093580e1Cf6C8F3c6eE11Fb27C86c8B87f)] = true;
    whitelisted[address(0xdAB154DFEE9381De7c1A3ee7C77733086ae622Aa)] = true;
    whitelisted[address(0xDB16072d75D1E6fDa8cd9800E16a69C097A6477f)] = true;
    whitelisted[address(0xDB34Fd28a9b186c8ecf60b4e207e8DE7be3fCFd2)] = true;
    whitelisted[address(0xDb5c39064E1A12b06A2587BC61A13038Ee2709ad)] = true;
    whitelisted[address(0xDB8b788F25D3746d0840Eb5Bb2Bb2070cc765779)] = true;
    whitelisted[address(0xDBE99fd2Fdbb94207e9cabe2B7252aAfD72780dC)] = true;
    whitelisted[address(0xDbeC007955799173d98360cCd7e082Ab268027Ba)] = true;
    whitelisted[address(0xDC3046B66B248F5461929e39cD0fD1e09Fe3726C)] = true;
    //whitelisted[null)] = true;
    whitelisted[address(0xDCfAc63689c05358A9411671D132eE2D2bFFE388)] = true;
    whitelisted[address(0xDD091FF04b43BFDdF9e235E50010cb12244CA79d)] = true;
    whitelisted[address(0xDd12c40d8Eb5837A959890ea72c993e5c6fED7D3)] = true;
    whitelisted[address(0xdd3767ABcAB26f261e2508A1DA1914053c7DDa78)] = true;
    whitelisted[address(0xdD72527cD9265013952Ad33825b35aB66E93bf3B)] = true;
    whitelisted[address(0xDe45Cb23098722c7856878F1A5F3fb1fD48Cf78E)] = true;
    whitelisted[address(0xdE46188a52Dd7B51ddAD4F8f7aAAE9e72002bD4b)] = true;
    whitelisted[address(0xdEd6EbA3206fEb90Ab7862c6dABd460c1b4C1F46)] = true;
    whitelisted[address(0xdEFafb62E63A84263Ec77e320fac4c4e9E87F13e)] = true;
    whitelisted[address(0xdf627f9cb3aa0C5229A9aFe7010d289e39370105)] = true;
    whitelisted[address(0xdF8b134fb7743aCD805eCDeE11335dd0Cca921fc)] = true;
    whitelisted[address(0xe04b16cE29A6be7B52354Cf796E4cae4c97DC7f9)] = true;
    whitelisted[address(0xE0c3Ba96Be3783aE6048F0f72ACe091c16d73Eb0)] = true;
    whitelisted[address(0xe1090646FAD97ba9588d84b57F39463E78d7A87A)] = true;
    whitelisted[address(0xE1441e4387132e3a6e9da2D82eefc8ac68061c8A)] = true;
    whitelisted[address(0xE14A9018a95790BC58A5Ce21445504bdC8EAdD02)] = true;
    whitelisted[address(0xe19E9a1398c7695d709C04cC1CE803DD3Ad742F1)] = true;
    whitelisted[address(0xe1d790C497FA988a7ED11Af79B87140b0Bb1754f)] = true;
    whitelisted[address(0xe1D86a7088d05398A2B9bA566bE0b3C5ffa5D9aF)] = true;
    whitelisted[address(0xe1Ff8fd541f2Fd105D6303A6956506BCB60B90Db)] = true;
    whitelisted[address(0xE25B901C30f48ced7f061F9e9Bda21b0bCB66f54)] = true;
    whitelisted[address(0xE2DEB568caD111A5E035A9542C61f16B53F7961C)] = true;
    whitelisted[address(0xe2f818f8878f5e183aB0a22AFDF8da26B1724ECa)] = true;
    whitelisted[address(0xE34193834EC63c52ac8a033fE4643b577250E060)] = true;
    whitelisted[address(0xE35701E37e38BB33bF1c0271b55fa0F236296757)] = true;
    whitelisted[address(0xe366Fc3f537d1eb9119a49e152D78B5fD005589A)] = true;
    whitelisted[address(0xe3691b46c787759033bBD29B2d320a1c08E7Ab86)] = true;
    whitelisted[address(0xe3c91f88db5C6486891e1a0Fbb94Ed27Dd86604c)] = true;
    whitelisted[address(0xe3Ec7347F7A2031be31C84C279159db18627B224)] = true;
    whitelisted[address(0xE3F4577Dd2fD22692eC2B1e3067cc02AEa692b54)] = true;
    whitelisted[address(0xE45DEc2F5C189979f5a89EEa39D42529E3aAA469)] = true;
    whitelisted[address(0xE485768ddbCBFfa556eCc4f48b305057a16B85C1)] = true;
    whitelisted[address(0xe4bEF15A0d7d5A889ac0aD7C86d9cA1c4B5D18E6)] = true;
    whitelisted[address(0xE52E82cf498EB4F30B3b03831450d56C6c246567)] = true;
    whitelisted[address(0xE5691DFc88e01c16F46560E1a5e6A5ebF0678BF9)] = true;
    whitelisted[address(0xE5798a530Bb7105e148D38ac884f05C28Ed8e804)] = true;
    whitelisted[address(0xE61AC512918A4851B7EA44fb93D8B0566Cfe5d03)] = true;
    whitelisted[address(0xE636a17BF41DAD86be29D57291919475EE9F2bDb)] = true;
    whitelisted[address(0xe73DC05e51856E631d45B6ECbEf17dAD7C3100C8)] = true;
    whitelisted[address(0xE822e03633ebc49caDa543c08E111844AF31BD92)] = true;
    whitelisted[address(0xE838de1FdfE4b2F3A04A57431e9287ea6eA289C8)] = true;
    whitelisted[address(0xE839Ce51a3491e49463599d3DA444080c24520F2)] = true;
    whitelisted[address(0xE8cd32eB3B7c052dc677Df36eC7ea733070B76b4)] = true;
    whitelisted[address(0xE95f55A3E9554Cb041201E20FFe7638a762A2a67)] = true;
    whitelisted[address(0xe97176A375c9F9C161733cC5F8f181AaD7Ec75AB)] = true;
    whitelisted[address(0xE9C131DfF5a72Fc84998478d8A3E498c5bBa9F34)] = true;
    whitelisted[address(0xeA5dB10aAcF3178aeC750D1df3fC97ad8bE553eF)] = true;
    whitelisted[address(0xEB0420c7C56822902F5D244341deed79f9E3A96C)] = true;
    whitelisted[address(0xeB2773D1a2DC350AA78F2F2A59a32EF0EFC3411A)] = true;
    whitelisted[address(0xEB5065B37519244F9642b9E1abBeCF01a0DdFAcf)] = true;
    whitelisted[address(0xeB993B7879789E0F602aD85471Df54EB33E240DE)] = true;
    whitelisted[address(0xEc5E07E3CE7aFba0eda95556c3067feb09A1fB8d)] = true;
    whitelisted[address(0xec9f7bEC8C665ba2a0BE0dC87AD79C34EE9D9736)] = true;
    whitelisted[address(0xecEd9C6E12B3C2067d9dF196108EfA46ad109a4A)] = true;
    whitelisted[address(0xED12b9a42399DFf7053ECF7671766558FB0A867C)] = true;
    whitelisted[address(0xEd1A9E046bEdb13Eb801AEd473eA142e18Eb0a4b)] = true;
    whitelisted[address(0xED23096CdAdFFa3c9fc466110062DD1eA3E803ec)] = true;
    whitelisted[address(0xed98c163390DCC7BD868cB465e30Fde2E13A7Abd)] = true;
    whitelisted[address(0xEdbfb071a47D6AdBEC37a74E5420B6a4cB88FE12)] = true;
    whitelisted[address(0xEdcf96F9E3c983Eaccc67b73dA0759EfF376867D)] = true;
    whitelisted[address(0xEDecE21F7B66735B54809fc05418bC1D5F41d73a)] = true;
    whitelisted[address(0xee705d889B131ee6705c0afe138e76A459b791a6)] = true;
    whitelisted[address(0xeF27AEb7757BB393eBE1ef28aa083130670c466e)] = true;
    whitelisted[address(0xEf3867Cb3D3baf773eC288CA93618bbC521df579)] = true;
    whitelisted[address(0xefe5699D433D52031e6D7388905ff39eFF40C205)] = true;
    whitelisted[address(0xEFfC16DB961C6BA6Bb224c869cda87B64211CCc4)] = true;
    whitelisted[address(0xf072E5eBF890decE7c051b47EcEb45883F0dA844)] = true;
    whitelisted[address(0xF12C50B8ccc506043Cd7bb3549F9AFA9afFBf593)] = true;
    whitelisted[address(0xF13023cBF895719D522c11E6b40b1eFD18039A3D)] = true;
    whitelisted[address(0xf131772381360E6a36581eD162523e339f6e1D67)] = true;
    whitelisted[address(0xF1D17665b561eBfF87430d738eecFC8c77798c6C)] = true;
    whitelisted[address(0xf1d83de0eAd95747f4AC184b36659c0D538309C8)] = true;
    whitelisted[address(0xF2008B311Df45CB362e4AaDe56B811b020E26A2f)] = true;
    whitelisted[address(0xF2530610CfC8cBb5A6aDFb5180516A038A1174AC)] = true;
    whitelisted[address(0xF3b8B04d1594CeE1B4EdfaC15083b26e93c6E73F)] = true;
    whitelisted[address(0xf435D252B6Dec2B6D764cD78b9C4b51a0667BC26)] = true;
    whitelisted[address(0xf43B2bE4AA887F426F05f78604b364af667C608d)] = true;
    whitelisted[address(0xF4FaCa935238f1F12ce0E5499a567946b8556A0B)] = true;
    whitelisted[address(0xF5f33389EB6D5Ad8D6134D6236450ecb51f341f1)] = true;
    whitelisted[address(0xF600Fa5Eeff7C083C31d81bf357C40FD91E2A281)] = true;
    whitelisted[address(0xf69a42fC0d56D4269EbA351f3875b666961D2d02)] = true;
    whitelisted[address(0xF6dCDD3fB36d074f09c93a016Ef306BdF20E971d)] = true;
    whitelisted[address(0xf6EcCCc2c729A2e2733bE1c1d1B944855ba0A24b)] = true;
    whitelisted[address(0xf881FC763887254404940b31D59F4B03987Ae152)] = true;
    whitelisted[address(0xF913cf3f8F54EC1335309219fb663567c6DcAdB5)] = true;
    whitelisted[address(0xf99983c1b128b87beD9aE10eC19df12feFDEb822)] = true;
    whitelisted[address(0xf9c9B88821f1d6ceFB52785e6bF68C6786E98E7a)] = true;
    whitelisted[address(0xfA14Be9b28E85fB6634849dCE7ad757bc9C250f6)] = true;
    whitelisted[address(0xfA4C277Bdcaaf36d9B10b1d84703703D156C074b)] = true;
    whitelisted[address(0xfaBe2CDC2d0CAf98A9dEDE669eA51CBc206A0d68)] = true;
    whitelisted[address(0xfb31964431630505044F46eC9Ac346058337ce15)] = true;
    whitelisted[address(0xfB810CaAbCD6F6dEF19A35516893b5abB8F4Fcb9)] = true;
    whitelisted[address(0xfb898525212330413Dc78e4cdd992bC9836C2401)] = true;
    whitelisted[address(0xfBC7DCe91a879A3EC8cC04130ea6E7EA928D6EB4)] = true;
    whitelisted[address(0xFC9219eDf221015dDEb57c435b04059627594D66)] = true;
    whitelisted[address(0xfcf6a3d7eb8c62a5256a020e48f153c6D5Dd6909)] = true;
    whitelisted[address(0xfd128cA2AE504EE8e9098115D3Cb6Ae65aDB791F)] = true;
    whitelisted[address(0xfD52027d4471949d7620ceC3696dA3133832a6eC)] = true;
    whitelisted[address(0xfD85dd30e9c763b54A09A9198AA2c36Af917620A)] = true;
    whitelisted[address(0xFddF481E4AEA8377F067f4Ee710EFe4C0A17a411)] = true;
    whitelisted[address(0xFe16c0524a51D2E579419FD25b88E0d3ac2B80E4)] = true;
    whitelisted[address(0xFe23fB9B286e37BDe8D325D16Fa4b4d496587F6A)] = true;
    whitelisted[address(0xfE3107BBbA13AF26d6A38C19C5a24790d8c6eAbe)] = true;
    whitelisted[address(0xfE93a4981d0A6cB62c94b037BC870c793EFE9F4D)] = true;
    whitelisted[address(0xFeeD2eab7fc2c43D06f55eCD5ef5DB5f2fE77935)] = true;
    whitelisted[address(0xFf3BD22870c5C4D097619d75D7E2bE056581b013)] = true;
    whiteListCount+=852;
  }
}