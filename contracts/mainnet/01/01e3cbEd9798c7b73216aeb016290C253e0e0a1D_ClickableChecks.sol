/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.8.12;

// SPDX-License-Identifier: MIT
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

// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

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

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Creator: Chiru Labs
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 - 1 (max value of uint128) of supply
 */
abstract contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex;

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

    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), 'ERC721A: global index out of bounds');
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), 'ERC721A: owner index out of bounds');
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
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

        revert('ERC721A: unable to get token of owner by index');
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721A: balance query for the zero address');
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), 'ERC721A: number minted query for the zero address');
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), 'ERC721A: owner query for nonexistent token');

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert('ERC721A: unable to determine the owner of token');
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, 'ERC721A: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721A: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'ERC721A: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), 'ERC721A: approve to caller');

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721A: transfer to non ERC721Receiver implementer'
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), 'ERC721A: mint to the zero address');
        require(quantity != 0, 'ERC721A: quantity must be greater than 0');

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe) {
                    require(
                        _checkOnERC721Received(address(0), to, updatedIndex, _data),
                        'ERC721A: transfer to non ERC721Receiver implementer'
                    );
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, 'ERC721A: transfer caller is not owner nor approved');

        require(prevOwnership.addr == from, 'ERC721A: transfer from incorrect owner');
        require(to != address(0), 'ERC721A: transfer to the zero address');

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

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
                    revert('ERC721A: transfer to non ERC721Receiver implementer');
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

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
	function decode(string memory _data) internal pure returns (bytes memory) {
	    bytes memory data = bytes(_data);

	    if (data.length == 0) return new bytes(0);
	    require(data.length % 4 == 0, "invalid base64 decoder input");

	    // load the table into memory
	    bytes memory table = TABLE_DECODE;

	    // every 4 characters represent 3 bytes
	    uint256 decodedLen = (data.length / 4) * 3;

	    // add some extra buffer at the end required for the writing
	    bytes memory result = new bytes(decodedLen + 32);

	    assembly {
	        // padding with '='
	        let lastBytes := mload(add(data, mload(data)))
	        if eq(and(lastBytes, 0xFF), 0x3d) {
	            decodedLen := sub(decodedLen, 1)
	            if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
	                decodedLen := sub(decodedLen, 1)
	            }
	        }

	        // set the actual output length
	        mstore(result, decodedLen)

	        // prepare the lookup table
	        let tablePtr := add(table, 1)

	        // input ptr
	        let dataPtr := data
	        let endPtr := add(dataPtr, mload(data))

	        // result ptr, jump over length
	        let resultPtr := add(result, 32)

	        // run over the input, 4 characters at a time
	        for {} lt(dataPtr, endPtr) {}
	        {
	           // read 4 characters
	           dataPtr := add(dataPtr, 4)
	           let input := mload(dataPtr)

	           // write 3 bytes
	           let output := add(
	               add(
	                   shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
	                   shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
	               add(
	                   shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
	                           and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
	                )
	            )
	            mstore(resultPtr, shl(232, output))
	            resultPtr := add(resultPtr, 3)
	        }
	    }

	    return result;
	}
}

library checkSVG {

    function desc() internal pure returns (string memory) {
        return "This artwork may or may not have required a lot of clicks! :-)!";
    }

    function url() internal pure returns (string memory) {
        return "https://clickable-checks.art";
    }

    function getColor(uint s, uint e, string memory t) internal pure returns (string memory) {
        bytes memory a = new bytes(7);
        uint p = 0;
        for(uint i=s;i<=e;i++){
            a[p] = bytes(t)[i];
            p++;
        }
        return string(a);
    }

    function getMeta(uint256 token, address addy, string memory colors, uint256 likes) internal pure returns (string memory) {
        
        string memory svg = "<svg width='2000' height='2000' viewBox='0 0 2000 2000' fill='none' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>";
        svg = string(abi.encodePacked(svg,"<defs><path id='b' d='M659 526.564c0-4.275-2.375-8.004-5.819-9.762.429-1.22.646-2.506.641-3.8 0-5.985-4.631-10.83-10.355-10.83-1.258 0-2.493.214-3.61.665-1.71-3.657-5.272-6.127-9.357-6.127-4.085 0-7.648 2.47-9.334 6.104a9.77 9.77 0 0 0-3.61-.665c-5.723 0-10.355 4.845-10.355 10.853 0 1.33.214 2.613.642 3.8-3.468 1.758-5.843 5.463-5.843 9.762 0 4.037 2.114 7.576 5.273 9.452-.051.458-.075.918-.072 1.378 0 5.985 4.632 10.853 10.355 10.853 1.259 0 2.494-.213 3.61-.665 1.663 3.61 5.225 6.104 9.31 6.104 4.085 0 7.648-2.47 9.31-6.104a10.04 10.04 0 0 0 3.61.665c5.724 0 10.355-4.845 10.355-10.853 0-.475-.023-.927-.071-1.378 3.183-2.019 5.32-5.391 5.32-9.452Zm-17.955-9.049-11.756 17.622a2.016 2.016 0 0 1-2.826.547l-.309-.238-6.555-6.555a2.014 2.014 0 0 1-.595-1.437 2.028 2.028 0 0 1 2.032-2.032 2.033 2.033 0 0 1 1.436.595l4.798 4.774 10.379-15.58a2.022 2.022 0 0 1 2.094-.859c.263.055.511.161.732.313a2.016 2.016 0 0 1 .57 2.824v.026'/></defs>"));
        svg = string(abi.encodePacked(svg,"<g clip-path='url(#a)'><path d='M2000 0H0v2000h2000V0Z' fill='#EFEFEF'/>"));

        uint x = 20;
        uint y = 20;
        uint a = 0;

        string memory iColor = checkSVG.getColor(a,(a+6),colors);

        svg = string(abi.encodePacked(svg,"<path d='M1448.89 447.852H551.107V1552.15h897.783V447.852Z' fill='",iColor,"'/>"));

        for (uint i = 1; i <= 10; i++) {
            for (uint j = 1; j <= 8; j++) {
                a = a + 7;
                iColor = checkSVG.getColor(a,(a+6),colors);
                svg = svg = string(abi.encodePacked(svg,"<use xlink:href='#b' x='", Strings.toString(x),"' y='",Strings.toString(y),"' fill='",iColor, "'/>"));
                x = x + 100;
            }
            y = y + 100;
            x = 20;
        }
        svg = string(abi.encodePacked(svg,"</g><defs><clipPath id='a'><path fill='#fff' d='M0 0h2000v2000H0z'/></clipPath></defs></svg>"));

        string memory json = string(abi.encodePacked('{"name": "Clickable Checks #', Strings.toString(token + 1), '", "external_url": "',checkSVG.url(),'", ', '"description": "', checkSVG.desc(),'", "attributes":[{"trait_type": "Author", "value": "', Strings.toHexString(uint256(uint160(addy)), 20), '"},{"display_type": "boost_number", "trait_type": "Likes", "value": ', Strings.toString(likes), '}], "image_data": "', svg, '"}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }
}

contract ClickableChecks is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 10000;
    uint256 public price = 0.0012 ether;

    bool public editable = false;
    
    uint256 public maxPerWallet = 25;

    mapping(address => uint256) public minted;
    mapping(uint256 => address) public tokenAuthors;
    mapping(uint256 => string) public tokenColors;
    mapping(uint256 => uint256) public tokenLikes;

    constructor() ERC721A("Clickable Checks", "CLICKABLECHECK") {
    }

    function setPrice(uint256 a) external onlyOwner {
        price = a;
    }

    function setEditable(bool b) external onlyOwner {
        editable = b;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

	function tokenURI(uint256 token) public view virtual override returns (string memory) {
	    require(token >= 0 && token <= totalSupply(),"nonexistent token");
        return checkSVG.getMeta(token, tokenAuthors[token], tokenColors[token], tokenLikes[token]);
	}

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function likeCC(uint256 token) external {
        require(token >= 0 && token < totalSupply(),"nonexistent token");

        tokenLikes[token] += 1;
    }

    function updateCC(uint256 token, string memory colors) external {
        require(token >= 0 && token < totalSupply(),"nonexistent token");
        require(editable, "Edit isn't allowed atm.");
        require((bytes(colors).length == 567), "Invalid colors");
        
        address owner = ERC721A.ownerOf(token);
        require(msg.sender == owner, 'Non-owned token.');

        tokenColors[token] = colors;
    }

    function mintCC(string memory colors) external payable {
        require(msg.sender == tx.origin, "Wallet required");
        require((bytes(colors).length == 567), "Invalid colors");
        require((minted[msg.sender] + 1) <= maxPerWallet, "Wallet limit reached");

        uint256 amount = 1;
        uint256 avail = maxSupply - totalSupply();

        amount = Math.min(amount, avail);
        require(amount > 0, "Sold out!");
        require(msg.value >= price, "Not enough ETH sent.");
        
        uint256 tokIdx = totalSupply();
        minted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
        
        tokenAuthors[tokIdx] = msg.sender;
        tokenColors[tokIdx] = colors;
        tokenLikes[tokIdx] = 0;
    }
}