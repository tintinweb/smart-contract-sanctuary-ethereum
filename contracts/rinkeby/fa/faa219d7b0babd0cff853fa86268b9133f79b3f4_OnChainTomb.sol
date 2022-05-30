/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title: Tale Of Tombs
// @author: theaibutcher
//
// On chain PFP collection of 10k unique profile images with the following properties:
//   - a single Ethereum transaction created everything
//   - all metadata on chain
//   - all images on chain in svg format
//   - all created in the constraints of a single txn without need of any other txns to load additional data
//   - all 10,000 OnChain Tombs are unique
//   - the traits have distribution and rarities interesting for collecting
//   - everything on chain can be used in other apps and collections in the future

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
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
     * by making the `nonReentrant` function external, and make it call a
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

// Bring on the Tale Of Tombs!
contract OnChainTomb is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Strings for uint256;

  uint256 public constant maxSupply = 3000;
  uint256 public numClaimed = 0;
  string[] private col3 = ["FEC"];
  string[] private col4 = ["000"];
  string[] private bgFace = ["4d4d4d","e60000","000080","e6004c","663300"]; // only trait that is uniform, no need for rarity weights
  string[] private bgBack = ["262626","b30000","00004d","b3003b","4d2600"];
  string[] private bgBottom = ["262626","990000","00004d","b3003b","4d2600"];
  string[] private bgBottomBack = ["262626","4d0000","00001a","80002a","1a0d00"];
  string[] private borders = ["006600","0d0d0d","f2f2f2","006666","4d004d","99003d"];
  string[] private background = ["656","dda","e92","1eb","663","9de","367","ccc"];
  string[] private bgname = ['Old Lavender', 'Pale Yellow', 'Orange', 'Turquoise', 'Olive Green', 'Blizzard Blue', 'Ming', 'Silver'];
  uint8[] private stone_w =[20, 15, 12, 7, 4];
  string[] private stonename = ["Grey","Red","Navy Blue","Magenta","Brown"];
  string[] private tooc = ["00ff00","0d0d0d","d966ff","f2f2f2","ffff00","33ffff","ff6600","00ff00","0d0d0d","d966ff","f2f2f2","ffff00","33ffff","ff6600"];
  uint8[] private tool_w = [46, 30, 25, 20, 19, 18, 16, 15, 10, 19, 24, 17, 32, 40];
  string[] private toolname = ["Green Sword","Black Sword","Purple Sword","White Sword","Yellow Sword","Blue Sword","Orange Sword","Green Skull","Black Skull","Purple Skull","White Skull","Yellow Skull","Blue Skull","Orange Skull"];
  uint8[] private border_w = [50, 40, 30, 24, 18, 10];
  string[] private bordername = ["Green","Black","White","Indigo","Purple","Pink",""];
  string[] private z = ['<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><rect x="0" y="0" width="500" height="500" style="fill:#',
  '"/><path d="M141,329.6c1.4-21,1-42.6,3.5-64.1c1.4-11.7,3.9-23.3,4.9-35c1.3-16-0.3-32-0.7-48.1 c-0.1-4.7-0.6-9.4,0.6-14.1c0.6-2.4,1.5-4.9,4-5.4c4.3-1,3.1-3.4,2.2-6c-1-2.9-1.9-5.8-3-8.6c-6-14.7-0.9-27.9,6.4-40.3c6.2-10.6,14.3-20.1,22.8-29c9.5-10,21.3-15,35.2-15.2c2.6,0,5.2-0.1,7.9-0.3c1.3-0.1,2.6-0.1,4-0.2c1.2-0.1,2.5,0,3.7-0.2 c0.4-0.1,0.8-0.2,1.2-0.3c0.7,0,1.4,0.2,2,0.2c1.5,0.2,2.9,0.4,4.4,0.7c2.9,0.5,5.8,1,8.7,1.6c5.8,1.1,11.5,2.5,17.2,4 c3.1,0.8,6.2,1.7,9.1,3.2c5.3,2.9,9.1,7.8,14.2,11c3.5,2.2,7.4,3.5,10.6,6.1c3.6,2.9,5.9,7,8.1,11.1c2.4,4.4,4.8,8.8,6.4,13.6 c0.4,1.2,0.8,2.5,1.1,3.7c1.2,5.1,1.8,10.3,2.4,15.5c0.6,5.1,1.3,10.3,3,15.2c0.4,1.2,0.9,2.4,1.4,3.6c0.2,0.5,0.5,1,0.6,1.5 c0,0.7-0.1,1.4-0.1,2.1c-0.1,15.1-1.4,30.1-1.7,45.2c-0.5,24.4-2.2,48.8-4.9,73.1c-0.5,4.3,0.1,8.5,1.1,12.6 c2.9,12.2,3.8,24.4,2,37c-1.5,10.6-1.5,21.5-2.2,32.3c-0.3,4.8-2.9,6.8-7.6,6.9c-5.5,0.1-10.5-2.2-16-2.3 c-7.7-0.2-15.1,1.6-22.6,2.4c-12.6,1.2-24.8-1.1-37.2-2.6c-2.2-0.2-4.3-1.2-6.5-1.1c-2.3,0-4.5,0.1-6.8,0 c-1.1-0.1-2.2-0.1-3.3-0.4c-0.7-0.2-1.2-0.5-1.9-0.6c-3-0.3-6-0.3-9-0.5c-3-0.1-6-0.3-9-0.4c-6-0.3-12.1-0.5-18.1-0.7 s-12.1-0.4-18.1-0.6c-1.5,0-3-0.1-4.5-0.1c-1.4,0-3-0.3-4.4-0.1c-0.4,0.1-0.8,0.3-1.1,0.4c-1.4,0.4-3.1,0.2-4.5-0.1 c-4.4-1.2-5.5-5.9-5.6-9.9c-0.1-2.7,0.2-5.4,0.3-8.1C141,335.6,141,332.9,141,329.6z" style="fill:#',
  '"/><path d="M325.5,413.5c-0.8,5.2-0.1,11.1-1.6,16.7c-0.6,2.2-1.1,4.3-3.5,5.2c-2.3,0.8-3.9-0.2-5-2.2 c-0.8-1.4-2.2-1.3-3.6-1.4c-11.3-0.7-22.6-1.4-33.8-2c-38.6-2-77.1-4-115.7-6c-10.8-0.5-21.6-0.8-32.4-1.4c-2.9-0.2-8.7,0-9.4-3.9 c-0.2-1.2-0.9-2.2-1.2-3.4c-0.7-2.5-0.8-5.2-0.8-7.8c-0.2-6-0.3-12.1-0.5-18.1c0-1,0-2-0.1-3c0-0.7-0.2-1.1-0.5-1.6 c-0.7-1.5-0.1-3.2,0.9-4.4c1.3-1.6,3.1-2.3,5-1.5c6.2,2.3,12.7,1.8,19,2.2c29.6,1.7,59.3,3,89,4.4c27,1.3,53.9,2.7,80.9,4.1 c9.3,0.5,12.9,4.3,12.9,13.7C325.1,406.4,325.3,409.7,325.5,413.5z" style="fill:#',
  '"/><path d="M239.4,360c-9.1-0.3-18.3-0.7-27.3-2c-5.8-0.9-11.4-2.2-17.2-3c-6.2-0.8-12.6-0.9-18.8-1 c-9.5-0.2-19.2-0.3-28.4,2s-18.2,7.4-23.1,15.6c8.7,6.4,20.1,7.2,30.9,7.8c6.6,0.4,13.2,0.7,19.8,1.1c48.7,2.7,97.4,5.4,146.1,5.5 c-1.5-4.6-3-9.3-4.6-13.9c-1.4-4.1-3.4-8.9-8.2-9.9c-1.6-0.3-3.2,0-4.8,0.1c-2.8,0-5.7-0.2-8.5-0.3c-11.9-0.4-23.9-0.9-35.8-1.3 C252.8,360.5,246.1,360.2,239.4,360z" style="fill:#',
  '"/><path d="M350.1,351.6c1.5-0.8,3.2-1.6,4.1-3s1-3.1,1.1-4.7c0.4-6.6,0.8-13.1,1.2-19.7c0.5-7.4,0.9-14.8,0.8-22.2 c-0.1-7-0.8-14-0.4-20.9c0.4-6.4,1.7-12.7,2.4-19.1c2.5-22.6-2.8-45.4-1.8-68.1c0.4-8.4,1.7-16.8,2.2-25.3 c1.5-22.9-2.5-46.2-11.5-67.3c-0.8-1.8-1.6-3.6-3.1-4.8c-2-1.6-4.7-1.8-6.9-3.1c-3.1-1.9-4.3-5.7-6-9 c-4.2-8.2-12.2-13.8-20.9-16.9s-17.9-4-27-4.9c-6.4-0.6-12.8-1.2-19.2-1.9c-3.1-0.3-7.6,0.7-7.1,3.8c9.2,6.9,19.8,11.9,29.5,18.1 s18.9,14.1,23.5,24.7c2,4.5,3,9.4,4,14.3c3,14,5.9,28,6.6,42.3c0.5,10.4-0.2,20.9-0.9,31.4c-0.9,13.7-1.5,27.5-2.1,41.2 s-1,27.5-1.2,41.2c-0.3,13.8-0.4,27.5-0.3,41.2c0,6.9,0.1,13.8,0.2,20.6c0,3.4,0.1,6.9,0.2,10.3c0.1,3.2-0.2,6.7,0.2,10 c0.7,4.9,6.2,4.2,9.6,2.7c6.2-2.7,12.2-5.9,18.4-8.9C346.8,353.2,349,351.6,350.1,351.6z" style="fill:#',
  '"/><path d="M324,384.8c0.4,0.7,0.9,1.5,1.7,1.5c0.5,0,1-0.3,1.4-0.5c4.6-3.1,8.4-7.3,13.4-9.6c3.4-1.6,7.1-2.2,10.6-3.4 c5-1.7,9.5-4.6,14-7.4c1.6-1,3.4-2.5,3.1-4.4c-0.1-0.7-0.5-1.3-0.9-1.8c-2.5-3.4-5.5-6.3-8.9-8.7c-0.7-0.5-1.4-0.9-2.2-1 c-1-0.1-2,0.4-2.9,0.8c-7.3,3.6-14.5,7.2-21.7,10.9c-3.6,1.8-7.2,3.7-10.8,5.5c-3,1.5-5.5,2.6-3.5,6.2 C319.6,376.9,322,380.8,324,384.8z" style="fill:#',
  '"/><path d="M327.2,427.8c0.1,0.7,0.2,1.5,0.6,2c1.1,1.2,3,0.5,4.4-0.3c12.1-6.8,24.2-13.6,36.3-20.4 c1.2-0.7,2.5-1.4,3.3-2.6c0.8-1.3,0.9-2.9,1-4.4c0.4-8.1,0.7-16.2,1.1-24.4c0.1-2.3,0.1-4.8-1.2-6.6c-1.4-2-4.1-2.6-6.5-2.3 s-4.6,1.5-6.7,2.7c-9.7,5.4-19.4,10.7-29.1,16c-3.2,1.8-7.1,3-6.8,7.2c0.3,4.9,1.1,9.8,1.6,14.6c0.3,3.1,0.7,6.1,1,9.2 C326.5,421.6,327.2,424.8,327.2,427.8z" style="fill:#',
  '"/><path d="M272.4,114c1.9,1.6,1.7,4.9-0.3,6.4s-5.2,0.5-6.1-1.8s0.8-5.2,3.2-5.6C270.3,112.9,271.5,113.2,272.4,114z" style="fill:#',
  '"/><path d="M288.6,128.1c-0.1,0.5-0.2,0.9-0.2,1.4c0.1,0.9,0.7,1.6,1.5,1.9c2.1,1.1,5.2-0.5,5.5-2.9 c0.2-2.4-2.4-4.7-4.7-4c-0.2-0.1-0.5,0.1-0.6,0.3C289.2,125.9,289,126.9,288.6,128.1z" style="fill:#',
  '"/><path d="M278.7,142.2c-1.5,0-3,0-4.4,0c-0.4,0-0.8,0-1.1,0.3c-0.2,0.2-0.2,0.5-0.3,0.8c-0.2,1.2-0.3,2.3-0.4,3.5 c-0.1,1.4-0.1,3.2,1.1,3.9c0.8,0.4,1.7,0.3,2.5,0.5c0.7,0.2,1.3,0.6,2,0.5c1.4,0,2.3-1.5,2.6-2.9c0.3-1.5,0.4-3-0.3-4.4 s-2.1-2.4-3.6-2.2" style="fill:#',
  '"/><path d="M158.2,295.8c-0.6,1.6-1.1,3.2-1.4,4.9c-0.1,0.3-0.1,0.7,0.1,1c0.3,0.5,0.9,0.6,1.5,0.7 c1.5,0.1,3.2,0.1,4.1-1c0.3-0.3,0.5-0.8,0.6-1.2c0.5-1.6,0.2-3.5-1.2-4.4s-3.6-0.4-3.9,1.2" style="fill:#',
  '"/><path d="M180.5,312.2c-0.2-0.5-0.6-1.3-1.1-1.5c-0.3-0.1-0.8,0-1.2,0s-0.7,0-1.1,0c-0.3,0-0.6,0-0.8,0.1 c-0.4,0.2-0.8,0.8-1.1,1.1c-0.2,0.1-0.3,0.2-0.4,0.4c-0.3,0.5-0.4,1.2-0.4,1.8c0,0.2,0,1.8,0.2,1.8c1,0.2,4.5,0.5,5.5,0.7 c0.6,0.1-1.1,0.3-0.6-0.1c0.2-0.2,0.4-0.4,0.6-0.7C180.6,314.6,180.9,313.3,180.5,312.2z" style="fill:#',
  '"/><path d="M278.5,419.6c1.9,1.4,5,1,6.3-1c1-1.5,0.8-3.4,0.5-5.2c-0.1-0.5-0.2-1-0.5-1.3s-0.8-0.4-1.3-0.4 c-1.4-0.2-2.6-0.1-4-0.1c-0.2,0-0.4,0-0.6,0c-0.5,0.2-1,0.6-1.4,1c-1,1-1.4,2.2-1.1,3.6C276.7,417.5,277.4,418.8,278.5,419.6z" style="fill:#',
  '"/><path d="M343,305.4c-2.1,0.4-4.1,1.9-4.3,4s2.2,4.1,4.1,3.1c1.9-1.8,1.7-5.3-0.3-7" style="fill:#',
  '"/><path d="M291.6,325.1c-0.1,1.5-0.8,2.9-0.8,4.4s1,3.2,2.5,3.2c1.3,0,2.2-1.2,2.8-2.3c0.5-0.7,0.9-1.5,1.3-2.2 c0.3-0.4,0.5-0.9,0.3-1.4c-0.1-0.2-0.3-0.4-0.5-0.5c-1.7-1.1-3.8-1.6-5.9-1.5" style="fill:#',
  '"/><path d="M343.4,137.7c-0.2,0.9-0.3,1.9,0.1,2.7s1.5,1.3,2.3,0.8c0.4-0.2,0.6-0.6,0.8-1c0.3-0.8,0.6-1.6,0.4-2.4 c-0.2-0.8-0.8-1.6-1.6-1.7s-1.7,0.7-1.5,1.5" style="fill:#',
  '"/><path d="M162.9,168.8c0,0.5,0.1,0.9,0.1,1.3 M162.9,168.8c0,0.5,0.1,0.9,0.1,1.3" style="fill:#',
  '"/><path d="M374.6,359.8c-5.1-4.1-8.9-9.4-13.7-14c0.3-5.1,0.9-9.7,0.9-14.3c-0.1-12.6,0.7-25.2-0.3-37.8 c-0.6-7.7,1.5-15.1,3.6-22.5c4.1-14.1,1.8-28.6-0.3-42.5c-1.5-9.9-1.7-19.5-1-29.3c0.7-8.6,0.8-17.2,1.5-25.8 c0.9-12.2,2-24.2-1.1-36.5c-2.7-10.4-3.3-21.3-7.5-31.3c-3.3-7.8-3.3-7.8-13.5-21.3c-9.1-9.6-10.5-9.7-18.3-14.4 c-6-3.6-11.9-7-19.2-7.7c-9.3-0.9-17.9-5-27.1-6.5c-16-2.6-31.8-1.2-47.6,1.2c-21.2,3.3-42.1,7.4-58.4,23.6 c-7.7,7.7-15.6,15-18.9,25.7c-0.9,3-2.9,5.6-4.4,8.3c-6.9,11.7-5.3,17-6.3,32.2c0.6,1.1-1.4,7.7-2.1,9.5c-0.9,10.2-1,3.7-0.9,8.1 c0.3,13.3,0.4,26.6,0.5,39.8c0.1,12,0.6,24-1.6,35.8c-2.4,12.5-2.2,25.1-2.3,37.7c0,2.8,0.1,5.7-0.6,8.4 c-2.1,9.4-1.6,18.8-1.1,28.2c0.7,12.8,0.1,25.5,1.6,38.6c-7.4,5.8-14.7,11.6-22.1,17.2c-2.6,1.9-4.1,4-4.1,7.4 c0.2,14.1,0.2,28.2,0.3,42.3c0,3.8,1.8,5.9,5.7,6.2c18.1,1.1,36.1,2.2,54.1,3.4c23.4,1.5,46.7,2.9,70.1,4.4 c26.5,1.7,53,3.5,79.5,5.2c3.6,0.2,6.9-0.6,10-2.5c13.9-8.4,27.9-16.8,41.9-25c3.4-2,4.7-4.6,4.7-8.5c0.1-12.3,0.4-24.6,0.7-36.8 C377.3,363.8,376.8,361.5,374.6,359.8z M144.5,296.6c1.2-8.4,2.3-16.7,2.1-25.2c-0.3-11,1-21.8,2.6-32.6c2.2-15,1.4-30.1,1.1-45.2 c-0.1-5.5-0.2-11-0.1-16.4c0-1.4,0.1-2.8,0.2-4.2c0.1-0.8,0.2-1.6,0.2-2.5c0-0.4,0.3-0.7,0.6-1c0.4-0.5,0.9-1,1.3-1.5 c0.1-0.1,0.2-0.2,0.4-0.3c0.1,0,0.3,0,0.4,0.1c1.8,0.8,4.9,3.7,5,3.9c0,0.1,3.6,2.8,3.6,2.9c0.1,0.1-2.2,5.1-2.2,5.3 c4.3,0,3.2-1.4,6.7-7.7c0.2-0.4-3.5-2.9-3.5-3.4c-0.6-0.6-0.8-1.4-1.1-2.1c-0.3-0.9-0.8-1.7-1.3-2.4c-0.3-0.4-0.6-0.7-0.9-1.1 c-0.3-0.3-0.6-0.6-0.9-0.9c-0.2-0.2-0.3-0.4-0.3-0.7c-0.1-0.4-0.3-0.7-0.4-1.1c-0.4-0.9-0.8-1.9-1.1-2.9c-0.7-1.9-1.3-3.9-1.9-5.9 s-1.2-4-1.9-6c-0.4-1.1-0.8-2.1-1.2-3.2c0.7-9.4,2.5-18.4,8.7-26c1.4-1.8,2.3-4.1,3-6.2c2.8-9.2,9-15.8,16.1-21.7 c4.4-3.7,8.4-8.1,13.5-10.6c0.1-0.1,0.5,0.2,0.6,0.2c0.2,0.1,0.4,0.2,0.6,0.3c0.4,0.3,0.7,0.6,0.9,1c0.4,0.5,0.5,1.2,0.8,1.7 c0.2,0.5,0.4,1.1,0.6,1.6c0.4,1.1,0.8,2.1,1.1,3.2c0.1,0.2,0.1,0.3,0.2,0.4c0,0.1,0.1,0.2,0.1,0.2s0.2,0.1,0.3,0.1 c0.4,0.1,0.8,0.3,1.2,0.4c0.1,0-0.4,2.7-0.4,2.9v0.5c0,0.4-0.1,0.9-0.1,1.3c-0.1,0.9-0.1,1.8-0.2,2.7c0,0.3-0.1,0.7,0,1 s0.2,0.5,0.3,0.8c0.8,1.6,1.7,3.2,2.6,4.8c-0.1-0.2-0.1-0.6-0.2-0.8c-0.1-0.3-0.1-0.5-0.2-0.8c-0.1-0.5-0.2-1.1-0.3-1.6 c-0.1-0.7-0.2-1.4-0.3-2.2c0-0.3-0.1-0.5-0.1-0.8c0-0.2-0.1-0.3,0-0.5c0.1-0.3,0.2-0.6,0.4-0.8c0.1-0.3,0.3-0.6,0.4-0.9 c0,0,0.6,0.1,0.7,0.2c0.2,0.1,0.4,0.2,0.6,0.2c0.6,0.1,1.1,0.3,1.6,0.6c0.2,0.1,0.4,0.2,0.6,0.4c0.1,0.2,0.2,0.4,0.3,0.6 c0.5,1.3,1,2.7,1.6,4c0.1,0.2,0.2,0.5,0.4,0.7s0.4,0.3,0.6,0.4c1.3,0.8,2.7,1.6,4,2.4c-0.6-1-1.5-1.8-2.3-2.8 c-1.2-1.5-2-3.3-2.3-5.2c-0.1-0.4-0.1-0.8-0.1-1.2c-1-0.7-2-1.3-3-2c-0.4-0.3-0.9-0.5-1.2-0.8c-0.1-0.1-0.2-0.3-0.2-0.5 c-0.1-0.3-0.2-0.5-0.3-0.8c-0.4-1.1-0.7-2.2-1.1-3.2c-0.1-0.3-0.2-0.7-0.5-0.8c-0.1-0.1-0.3-0.1-0.5-0.2c-0.3-0.2-0.4-0.6-0.5-0.9 c-0.1-0.4-0.2-0.9-0.3-1.3c-0.1-0.3-0.2-0.7-0.2-1.1V81c-0.1-0.7-0.3-1.4-0.3-2.1c-0.1-1.8,0.3-3.6,1.3-5.2 c30.5-4.5,61.3-8.2,88.1,15.3v14c0,0.4,0,0.9-0.2,1.3c-0.1,0.1-0.1,0.2-0.2,0.4c-0.1,0.3-0.2,0.6-0.4,0.8c-0.3,0.5-0.6,1-1,1.6 s-0.8,1.2-1,1.9c0.1-0.1,0.2-0.1,0.3-0.2l0.3-0.3c0.2-0.2,0.5-0.4,0.7-0.5c0.5-0.3,0.9-0.7,1.3-1.1c0.2-0.2,0.3-0.4,0.5-0.7 s0.4-0.8,0.6-1.1c0.3-0.3,0.5-0.8,0.6-1.3c0.1-0.2,0.2-0.3,0.2-0.5c0.1-0.2,0.1-0.4,0.2-0.7c0.1-0.5,0.2-0.9,0.3-1.4 c0.4-2,0.5-4,0.8-6c0.1-0.8,0.3-1.5,0.5-2.3c8.3,6.5,16.9,12.2,18.1,23.6c1,9.6,2.7,19,5.4,28.3c0.8,2.7,1.5,5.5,1.5,8.3 c0,18.7,0.9,37.3-2.1,55.9c-1.6,9.9-1.5,20.2-1.6,30.3c0,10.8-0.6,21.6-1.6,32.3c-1,10.5-1,20.9,1.6,31.1 c1.4,5.4,0.5,10.8-0.1,16.3c-1.2,10.7-1.7,21.5-2.4,32.3c-0.2,2.6-0.1,5.3-1.2,8.1c-54.4-3-108.7-6-163.3-9.1c0,0-0.2-1.7-0.2-1.8 c-0.1-0.7-0.2-1.4-0.3-2.1c-0.2-1.4-0.3-2.7-0.4-4.1c-0.1-1.4,0-2.7,0.1-4v-0.5c0-0.5,0.1-1.1,0.2-1.5c0.1-0.5,0.2-1.1,0.3-1.6 c0.3-1.2,0.6-2.4,1.1-3.6c0.1-0.2,0.1-0.3,0.2-0.5c0.1-0.1,0.3-0.2,0.5-0.3c2.6-1,5.1-2,7.7-3c0.3-0.1,0.4-0.5,0.6-0.8 c0.2-0.3,0.4-0.6,0.7-0.9c0.2-0.2,0.5-0.4,0.7-0.6c0.4-0.4,0.6-0.9,0.8-1.4c0.4-0.8,0.8-1.7,1.1-2.5c0.2-0.4,0.4-0.8,0.5-1.1 c0-0.1,0-0.2,0.1-0.3c0.3-0.5,1-0.9,1.4-1.2c0.9-0.7,1.7-1.5,2.3-2.4c-0.8,0.4-1.4,0.9-2.2,1.4c-0.3,0.2-0.7,0.4-1.1,0.5 c-0.1,0-0.2,0-0.4,0.1c-0.1,0-0.1,0.1-0.1,0.1c-0.2,0.2-0.4,0.5-0.6,0.8c-0.4,0.6-0.8,1.2-1.2,1.8c-0.5,0.7-1,1.4-1.5,2.2 s-0.8,1.6-1.6,2c-0.2,0.1-0.5,0.2-0.8,0.3c-2.5,0.8-5.1,1.7-7.6,2.5c-0.5,0.2-1,0.3-1.5,0.7v-1c0.1-0.5,0-1,0.1-1.4v-2 c0-1.4-0.1-2.7-0.1-4.1c-0.1-2.7-0.3-5.4-0.4-8C143.9,307,143.8,301.8,144.5,296.6z M142.3,361.5c1.4-1.1,3.2-0.8,4.8-0.7 c32.1,1.8,64.2,3.5,96.3,5.3c21,1.2,42,2.4,63.1,3.5c1,0.1,2,0.3,3.1,0.4c2,4,3.6,8.1,4.8,13.1c-61.3-4-122.1-7.9-184-11.9 C134.6,367,138.6,364.4,142.3,361.5z M317.6,428.4c-4.5,0.7-8.9,0.1-13-0.4c-0.2,0-0.4-0.2-0.5-0.3c-0.2-0.1-0.3-0.2-0.5-0.4 c-0.3-0.2-0.6-0.5-0.9-0.8c-0.6-0.6-1-1.4-1.6-2c-0.2-0.2-0.5-0.4-0.6-0.6c-0.2-0.4-0.3-0.8-0.4-1.2c0-0.1,0-0.2-0.1-0.4 c-0.1-0.1-0.2-0.2-0.2-0.4c-0.5-0.6-0.9-1.2-1.2-1.9c-0.1-0.2-0.1-0.5-0.1-0.7c0.1-0.6-0.2-1.2-0.4-1.7c-0.1-0.5-0.2-0.9-0.3-1.4 c0-0.1-0.1-0.3-0.2-0.4c-0.2-0.3-0.5-0.5-0.8-0.7c-0.7-0.8-1.4-1.5-2.1-2.2c-0.3-0.3-0.6-0.5-0.9-0.7c0.2,0.1,0.3,0.4,0.5,0.6 c0.1,0.2,0.3,0.4,0.5,0.6c0.3,0.4,0.6,0.8,0.8,1.4c0,0.2,0.2,0.5,0.3,0.7c0.3,0.6,0.5,1.1,0.6,1.7c0.2,0.8,0.3,1.6,0.3,2.4 c0.1,0.7,0.1,1.5,0.2,2.2c0,0,0.5,0.2,0.6,0.2c0.1,0.1,0.1,0.3,0.1,0.5c0.2,0.5,0.5,1,0.8,1.5c0.1,0.2,0.2,0.4,0.3,0.6v1.7 c0,0.2,0,0.5-0.1,0.7c-0.2,0.3-0.6,0.5-0.5,0.9c-0.4,0-1,0.1-1.4,0c-0.1,0-0.2,0-0.3-0.1c-0.7-0.1-1.3-0.1-2-0.1 c-1.3-0.1-2.6-0.2-3.9-0.2c-11.3-0.7-22.6-1.5-33.9-2.2s-22.6-1.5-33.9-2.2c-11.3-0.7-22.6-1.5-33.9-2.2 c-11.3-0.7-22.6-1.5-33.9-2.2c-5.7-0.4-11.3-0.7-17-1.1c-2.8-0.2-5.7-0.4-8.5-0.5c-1.4-0.1-2.8-0.2-4.2-0.3 c-0.3,0-4.1-0.2-4.1-0.3v-9.6l0.1-0.1c0.1-0.1,0.1-0.1,0.2-0.2c0.1-0.2,0.2-0.3,0.3-0.5c0.3-0.4,0.5-0.7,0.8-1.1s0.7-0.8,1-1.2 c0.1-0.2,0.2-0.3,0.3-0.5c0.2-0.2,0.5-0.4,0.7-0.5c0.3-0.2,0.6-0.3,0.9-0.5c0.6-0.3,1.2-0.6,1.9-0.8c0.5-0.2,1-0.3,1.5-0.2 c0.4,0.1,0.8,0.3,1.1,0.6c1.1,0.8,2.3,1.6,3.6,1.9c0.3,0.1,0.4-0.2,0.6-0.3c0.5-0.5,1.1-0.9,1.6-1.2c0.1-0.1,0.3-0.2,0.4-0.2 c0.3-0.2,0.6-0.3,0.9-0.5c1.2-0.5,2.5-0.6,3.8-0.7c-0.9-0.3-1.9-0.5-3-0.6c-0.6,0-1.2,0-1.7,0.3c-0.1,0.1-0.2,0.2-0.2,0.2 c-0.1,0.1-0.3,0.2-0.4,0.3l-0.9,0.6c-0.1,0-0.1,0.1-0.2,0.1c-0.2,0.1-0.4,0.2-0.5,0.4c-0.1,0.1-0.4,0.3-0.6,0.3 c-0.1,0-0.3-0.1-0.5-0.2c-0.1-0.1-0.3-0.1-0.4-0.2c-0.3-0.2-0.6-0.4-0.8-0.5c-0.8-0.6-1.6-1.4-2.4-2.1c-0.1-0.1-0.2-0.1-0.3-0.2 h-0.4c-0.3,0.1-0.6,0.1-0.9,0.2c-0.2,0-0.3,0.1-0.5,0.1h-0.3c-0.3,0-0.6,0.1-0.9,0.1c-0.4,0.1-0.9,0.2-1.3,0.3 c-1.3,0.3-2.5,0.6-3.8,1v-20.1c65.6,4.2,131,8.5,196.7,12.7L317.6,428.4L317.6,428.4z M298.9,85.9l-2.9-4.1h-1.3 c-0.2,0-0.3-0.2-0.5-0.2l-3-2.4c-2-1.6-4.1-3.1-6.2-4.5c-4.2-2.9-8.6-5.6-13.3-7.8c-2.1-0.2-3.8-1.2-6.2-2.7 c2.6,0.4,4.4,0.7,6.2,1c6.2-0.1,12,1.9,17.9,3.7c4.6,1.4,9.2,2.9,14,3.3c7.3,0.5,13,4.4,18.7,8.3c4.5,3.1,6,8.2,7.4,13 c1,3.7-2.5,5.3-4.7,7.4v0.4c0,0.2,0.1,0.4,0.1,0.6c0.1,0.4,0.3,0.7,0.4,1.1c0.4,0.8,0.8,1.5,1.1,2.3c0.2,0.4,0.3,0.8,0.4,1.2 s0.2,0.9,0.1,1.3c0,0.2-0.3,0.4-0.4,0.5c-0.6,0.8-1.3,1.6-1.9,2.3l4.2-1.4c0.3-0.3,0.5-0.6,0.8-0.8c0.3-0.2,0.6-0.5,0.9-0.7 c-0.3-0.2-0.3-0.3-0.3-0.6c-0.1-0.4-0.2-0.9-0.3-1.3c-0.1-0.4-0.2-0.8-0.3-1.2c0-0.2-0.1-0.4-0.1-0.6c0-0.1-0.2-0.5-0.1-0.6 c1.1-2.2,3.5-2.6,4.7-4c7.4,0.5,11.5,4.4,13.6,11.1c2.7,8.5,3.4,17.5,5.9,26c4.3,15.2,1.6,30.2,0.5,45.3 c-0.6,8.7,0.3,17.6-1.4,26.2c-0.7,3.3-1.5,6.4-4.1,8.3c-0.9,3.7-0.1,7.1-0.3,10.5c-0.4,1-1.3,1.8-2.1,2.5 c-0.7,0.7-1.5,1.3-2.3,1.9c0,0,0,0-0.1,0.1c-0.7,0.5-1.5,1-2.1,1.6c-0.3,0.3-0.6,0.6-0.9,0.9s-0.7,0.5-1.1,0.8 c-0.7,0.4-1.4,0.9-2.1,1.4c-0.2,0.2-0.5,0.3-0.6,0.6l-0.4,0.4c-0.1,0.1-0.3,0.3-0.4,0.4c-0.1,0.1-0.2,0.2-0.2,0.3s0.1,0.1,0.1,0.2 c0.5,0.6,0.7,1.5,1.1,2.2c0.1,0.2,0.3,0.4,0.4,0.7c0.1,0.1,0.1,0.2,0.1,0.4c0.2,0.4,0.3,0.8,0.3,1.2v0.6c-0.1,0.4,0.1,0.8-0.2,1.1 c-0.4,0.4-0.9,0.8-1.3,1.2c-0.2,0.2-0.4,0.4-0.6,0.5c-0.4,0.4-0.9,0.7-1.3,1.1c-0.1,0.1-0.2,0.1-0.2,0.2c-0.1,0.1-0.1,0.3,0,0.5 c0.3,2.2,0.6,4.5,0.9,6.7c0,0.3,0.1,0.7,0.1,1.1c-0.1,0.3-0.1,0.6-0.1,1c0,0.9,0.1,1.8,0.2,2.6l1.9-9.3c1.4-2.6,4.9-3.1,5.8-5.7 c0-2.3-2.1-2.9-2.8-4.9c3.7-2.7,7.5-5.5,11.7-8.6c0.1-2,0.3-4.4,0.4-6.9c1.4,0.3,1.6,1.4,1.7,2.3c0.7,13.5,4,27,1.1,40.6 c-1,4.9-2.7,9.6-3.3,14.5c-1.6,13.8,0.5,27.5,0.2,41.2c-0.2,6.9,0.7,13.9-1.6,21.1c-10,5.2-20.1,9.9-31,15.1 c0.5-6.1,0.7-11.5,1.3-16.9c0.9-8.7,0.5-17.6,2.4-26.2c0.8-3.7,0.5-7.7-0.4-11.4c-3.1-12-3-24-1.5-36.1 c1.6-13.2,1.2-26.5,1.4-39.8s2.2-26.4,2.9-39.7c0.7-13.9,1.9-27.9-0.5-41.6c-1.9-10.9-5-21.6-6.3-32.7c-1-8.2-5.1-15-11.5-20.3 c-2.4-2-4.6-4.1-7-6.2C300,87,299.5,86.5,298.9,85.9c-0.1-0.1-0.2-0.1-0.2-0.2c-0.2-0.2-0.2-0.4-0.3-0.7 M351.5,359.2 c0,0,0.1,0.1,0.2,0.1s0.1,0,0.2,0.1c0.2,0,0.3,0.1,0.4,0.2c0.2,0.2,0.3,0.4,0.4,0.6c0,0.3,0.1,0.6,0.1,1c0,0.7,0.1,1.5,0,2.2 c0,0.4,0,0.7-0.1,1.1v0.4c0,0.2,0.2,0.2,0.4,0.3c0.3,0.1,0.5,0.4,0.6,0.6s0.2,0.4,0.1,0.6c0,0.2-0.1,0.4-0.2,0.5 c-0.2,0.4-0.5,0.6-0.9,0.8c-0.9,0.4-1.8,0.9-2.6,1.4c-8,4.2-16,8.5-24.4,12.9c-2.2-4.1-3.7-8.2-5.2-12.9 c11.1-5.2,22.1-10.4,33.2-15.7c3.7,2.3,6,5.8,8.7,8.8c-1.5,1.7-3.4,2.2-5.3,3.1c-0.2-0.1-0.4-0.2-0.6-0.3s-0.5-0.3-0.7-0.4 s-0.4-0.3-0.7-0.3c-0.3-0.1-0.7-0.3-0.9-0.5c-0.1-0.1-0.1-0.2-0.1-0.4c-0.1-0.4-0.2-0.7-0.2-1.1c-0.1-0.5-0.2-0.9-0.4-1.4 c-0.1-0.4-0.3-0.9-0.4-1.3l-2.1-0.8l2.1,0.8 M358.3,386.3v-1.5c0-0.3,0-0.7,0.2-1c0.1-0.2,0.1-0.3,0.2-0.4c0-0.1,0.1-0.1,0.1-0.2 c0.3-0.5,0.6-1,1-1.5c1.7-2,2.7-4.3,2.5-7.1c1.1-0.8,2.2-1.7,4.1-1.6c0.7,9.8,0.2,20-0.1,30.4c-12.6,7.5-25.2,15-38.3,22.7v-33.9 c10.2-5.4,20.3-10.7,30.5-16c0.3,0.4,0.5,0.9,0.6,1.4c0.1,0.3,0,0.7,0,1c0,0.2-0.1,0.3-0.2,0.5c0,0.1-0.1,0.2-0.2,0.4 c-0.1,0.1-0.3,0.3-0.4,0.4c-0.2,0.1-0.3,0.3-0.5,0.5s-0.4,0.5-0.5,0.7c-0.1,0.1-0.2,0.2-0.2,0.4c-0.1,0.1-0.2,0.3-0.2,0.5 c-0.3,0.5-0.6,1.1-1,1.6c-0.2,0.2-0.4,0.5-0.4,0.8c0,0.1,0,0.2,0.1,0.3v3.9c0,0.7,0.1,1.3,0.1,2c0,0.5-0.1,1.2-0.4,1.6l-0.3,0.3 c0,0-0.1,0.1-0.1,0.2s-0.1,0.1-0.2,0.2c-0.7,0.8-1.6,1.4-2.5,2c0.6-0.1,1.2-0.2,1.7-0.5c0.4-0.2,0.8-0.5,1.3-0.7 c0.1,0,0.2-0.2,0.4-0.2c0,0,0,0,0.1,0c0.2-0.3,0.3-0.6,0.5-1c0.1-0.1,0.1-0.3,0.2-0.5s0.1-0.3,0.2-0.5c0-0.1,0.1-0.2,0.1-0.3 c0.1-0.4,0.2-0.8,0.4-1.2c0.1-0.2,0.1-0.4,0.2-0.6c0-0.1,0.1-0.2,0.1-0.4s0-0.4,0.1-0.5c0-0.2,0.1-0.4,0.3-0.5c0.1,0,0.1,0,0.2,0 L358.3,386.3z" style="fill:#', '"/>',
    '</svg>'];

  string private skull1='<path transform="rotate(-0.124147 231.703 230.613)" d="m201.55082,200.49637c-1.31458,7.19434 -4.67248,14.07005 -4.89859,21.48881c0.30085,4.29544 -2.68066,6.60274 -6.76227,6.5215c-4.38989,4.39815 0.54184,11.34894 5.5089,13.12434c5.06916,3.28875 11.35782,-0.38608 16.37928,2.56406c6.66768,5.03775 9.45128,13.9698 7.15093,21.80038c-2.28716,6.46417 9.42066,4.11321 5.01695,-1.0541c-3.40115,-5.05065 6.41141,-3.3808 3.89934,1.41432c-0.47468,3.84915 2.93755,5.09502 1.41899,8.82415c3.95609,2.19251 -0.33162,3.42013 -2.74126,3.83411c-5.6428,2.71878 1.02067,-4.87026 -3.44956,-7.11494c-4.0936,0.85989 -1.31977,7.4855 -2.72488,6.72026c-2.89266,-2.18929 -2.89052,-10.3744 -7.74539,-5.03371c-1.61128,-6.58068 1.32864,-13.43419 -0.9361,-19.97667c0.92773,-4.88601 -7.05377,-6.57133 -6.04425,-0.90437c0.40244,8.64896 -2.31485,17.28069 -0.75533,25.88704c2.14792,5.30832 8.15531,7.69966 11.92572,11.79594c3.09653,3.15847 7.11092,6.53538 11.9305,5.54098c5.46641,-0.22902 10.9429,-0.71697 16.38465,0.12186c6.84461,0.20865 12.06962,-5.02053 17.9108,-7.70664c6.86677,-5.27002 5.78561,-14.68337 5.10108,-22.18156c-0.83937,-4.62932 1.00252,-9.26073 0.65927,-13.84671c-4.95057,-5.85457 -9.01228,4.43601 -7.60203,8.85718c-0.00034,5.5615 1.10466,12.72566 -4.38427,16.34848c-4.52985,-0.1104 -8.84096,1.47991 -13.40574,0.6484c-3.70407,2.126 -9.70374,2.07141 -10.92638,-2.98961c-0.48813,-4.49453 1.61892,-9.20658 -1.24397,-13.40123c2.51539,2.09393 6.90398,-1.80845 4.45818,2.88599c-2.98317,3.82127 2.52603,9.7096 4.6,4.06934c0.68808,-3.78428 -2.97634,-8.80684 3.0472,-7.99609c1.22841,1.33483 -4.19491,10.67193 3.21842,8.31234c5.2853,-1.11898 -0.9403,-9.13232 6.21703,-9.16016c3.46388,-3.94149 2.53124,-11.32931 7.82974,-14.31945c5.9078,-3.86429 15.13188,-1.07442 19.34851,-7.61859c3.59409,-3.34889 1.90273,-12.63091 -4.29578,-9.55532c-7.74613,0.72985 -1.5985,-10.14033 -1.81462,-14.21351c1.82512,-3.54759 -2.21647,-11.01527 -0.82477,-11.80756c2.62966,3.88869 3.5715,8.43694 3.00596,12.98151c-0.0486,3.85394 -1.7396,14.29865 3.80386,7.85998c1.87661,-4.48719 1.33081,-9.56974 2.6678,-14.23815c2.5787,-10.07896 -2.03851,-20.16352 -7.18585,-28.70034c-4.38389,-4.59577 -9.94938,-8.25936 -15.17579,-11.86646c-8.79102,-3.19563 -18.49765,-3.76811 -27.7823,-2.96722c-8.21265,1.37588 -16.89749,2.82645 -23.43991,8.23855c-6.37614,3.63122 -12.48265,8.45404 -15.0034,15.4314c-2.19673,5.62096 -6.04348,11.34521 -4.29517,17.58929c1.67203,5.20514 0.78522,10.61085 1.05594,15.93104c2.85031,6.08044 5.54135,-3.11139 5.27461,-6.15175c0.15779,-5.7655 3.30494,-10.86878 5.62395,-15.98708l0,-0.00001l0.00001,-0.00002zm52.35244,12.3691c5.86147,0.40596 13.28297,3.56078 13.44293,10.13795c0.89127,6.60037 -4.62665,12.99824 -11.69799,12.35097c-6.42305,-0.50993 -10.53096,-5.87241 -10.10445,-11.90134c-2.15042,-4.32281 1.19601,-8.9526 5.68723,-9.94634c0.87094,-0.28306 1.76616,-0.49493 2.67229,-0.64125l0,0l-0.00001,0zm-39.55502,0.56218c6.79974,-1.16882 14.53609,2.90823 14.5588,10.18302c0.63863,7.0328 -7.08659,8.41066 -12.3564,10.17248c-3.64647,2.27567 -7.43429,0.15685 -10.46421,-2.13596c-3.93118,-3.97703 -2.77572,-11.99133 1.37521,-15.62168c2.01287,-1.43983 4.50462,-2.00583 6.8866,-2.59786zm23.26768,18.55312c3.29183,4.37301 7.24369,11.04156 2.98665,16.00476c-3.77909,2.92934 -4.25554,-4.16668 -8.22206,-0.82475c-3.72106,-3.14982 -0.28908,-9.55938 2.32182,-12.75921c0.86054,-0.92143 1.84529,-1.73264 2.91359,-2.42081z" stroke-width="5" style="fill:#';
  string private skull2='<path transform="rotate(-0.124147 224.703 230.613)" d="m194.55082,200.49637c-1.31458,7.19434 -4.67248,14.07005 -4.89859,21.48881c0.30085,4.29544 -2.68066,6.60274 -6.76227,6.5215c-4.38989,4.39815 0.54184,11.34894 5.5089,13.12434c5.06916,3.28875 11.35782,-0.38608 16.37928,2.56406c6.66768,5.03775 9.45128,13.9698 7.15093,21.80038c-2.28716,6.46417 9.42066,4.11321 5.01695,-1.0541c-3.40115,-5.05065 6.41141,-3.3808 3.89934,1.41432c-0.47468,3.84915 2.93755,5.09502 1.41899,8.82415c3.95609,2.19251 -0.33162,3.42013 -2.74126,3.83411c-5.6428,2.71878 1.02067,-4.87026 -3.44956,-7.11494c-4.0936,0.85989 -1.31977,7.4855 -2.72488,6.72026c-2.89266,-2.18929 -2.89052,-10.3744 -7.74539,-5.03371c-1.61128,-6.58068 1.32864,-13.43419 -0.9361,-19.97667c0.92773,-4.88601 -7.05377,-6.57133 -6.04425,-0.90437c0.40244,8.64896 -2.31485,17.28069 -0.75533,25.88704c2.14792,5.30832 8.15531,7.69966 11.92572,11.79594c3.09653,3.15847 7.11092,6.53538 11.9305,5.54098c5.46641,-0.22902 10.9429,-0.71697 16.38465,0.12186c6.84461,0.20865 12.06962,-5.02053 17.9108,-7.70664c6.86677,-5.27002 5.78561,-14.68337 5.10108,-22.18156c-0.83937,-4.62932 1.00252,-9.26073 0.65927,-13.84671c-4.95057,-5.85457 -9.01228,4.43601 -7.60203,8.85718c-0.00034,5.5615 1.10466,12.72566 -4.38427,16.34848c-4.52985,-0.1104 -8.84096,1.47991 -13.40574,0.6484c-3.70407,2.126 -9.70374,2.07141 -10.92638,-2.98961c-0.48813,-4.49453 1.61892,-9.20658 -1.24397,-13.40123c2.51539,2.09393 6.90398,-1.80845 4.45818,2.88599c-2.98317,3.82127 2.52603,9.7096 4.6,4.06934c0.68808,-3.78428 -2.97634,-8.80684 3.0472,-7.99609c1.22841,1.33483 -4.19491,10.67193 3.21842,8.31234c5.2853,-1.11898 -0.9403,-9.13232 6.21703,-9.16016c3.46388,-3.94149 2.53124,-11.32931 7.82974,-14.31945c5.9078,-3.86429 15.13188,-1.07442 19.34851,-7.61859c3.59409,-3.34889 1.90273,-12.63091 -4.29578,-9.55532c-7.74613,0.72985 -1.5985,-10.14033 -1.81462,-14.21351c1.82512,-3.54759 -2.21647,-11.01527 -0.82477,-11.80756c2.62966,3.88869 3.5715,8.43694 3.00596,12.98151c-0.0486,3.85394 -1.7396,14.29865 3.80386,7.85998c1.87661,-4.48719 1.33081,-9.56974 2.6678,-14.23815c2.5787,-10.07896 -2.03851,-20.16352 -7.18585,-28.70034c-4.38389,-4.59577 -9.94938,-8.25936 -15.17579,-11.86646c-8.79102,-3.19563 -18.49765,-3.76811 -27.7823,-2.96722c-8.21265,1.37588 -16.89749,2.82645 -23.43991,8.23855c-6.37614,3.63122 -12.48265,8.45404 -15.0034,15.4314c-2.19673,5.62096 -6.04348,11.34521 -4.29517,17.58929c1.67203,5.20514 0.78522,10.61085 1.05594,15.93104c2.85031,6.08044 5.54135,-3.11139 5.27461,-6.15175c0.15779,-5.7655 3.30494,-10.86878 5.62395,-15.98708l0,-0.00001l0.00001,-0.00002zm52.35244,12.3691c5.86147,0.40596 13.28297,3.56078 13.44293,10.13795c0.89127,6.60037 -4.62665,12.99824 -11.69799,12.35097c-6.42305,-0.50993 -10.53096,-5.87241 -10.10445,-11.90134c-2.15042,-4.32281 1.19601,-8.9526 5.68723,-9.94634c0.87094,-0.28306 1.76616,-0.49493 2.67229,-0.64125l0,0l-0.00001,0zm-39.55502,0.56218c6.79974,-1.16882 14.53609,2.90823 14.5588,10.18302c0.63863,7.0328 -7.08659,8.41066 -12.3564,10.17248c-3.64647,2.27567 -7.43429,0.15685 -10.46421,-2.13596c-3.93118,-3.97703 -2.77572,-11.99133 1.37521,-15.62168c2.01287,-1.43983 4.50462,-2.00583 6.8866,-2.59786zm23.26768,18.55312c3.29183,4.37301 7.24369,11.04156 2.98665,16.00476c-3.77909,2.92934 -4.25554,-4.16668 -8.22206,-0.82475c-3.72106,-3.14982 -0.28908,-9.55938 2.32182,-12.75921c0.86054,-0.92143 1.84529,-1.73264 2.91359,-2.42081z" stroke-width="5" style="fill:#';
  string private skull3='<path transform="rotate(-0.124147 224.509 232.604)" d="m191.43179,203.40823c-1.2732,6.97428 -4.52539,13.63969 -4.74439,20.83152c0.29138,4.16406 -2.59627,6.40078 -6.5494,6.32202c-4.25171,4.26362 0.52479,11.00181 5.33549,12.7229c4.90959,3.18815 11.00028,-0.37427 15.86368,2.48563c6.45779,4.88366 9.15376,13.5425 6.92583,21.13356c-2.21516,6.26644 9.1241,3.9874 4.85903,-1.02186c-3.29408,-4.89616 6.20959,-3.27739 3.77659,1.37106c-0.45974,3.73141 2.84508,4.93917 1.37432,8.55424c3.83156,2.12545 -0.32118,3.31552 -2.65497,3.71683c-5.46517,2.63562 0.98854,-4.72129 -3.34097,-6.89731c-3.96474,0.83359 -1.27823,7.25654 -2.6391,6.5147c-2.8016,-2.12232 -2.79953,-10.05708 -7.50158,-4.87974c-1.56056,-6.37939 1.28682,-13.02327 -0.90663,-19.36563c0.89853,-4.73656 -6.83173,-6.37033 -5.85398,-0.87671c0.38978,8.38441 -2.24198,16.75212 -0.73155,25.09522c2.08031,5.14595 7.89859,7.46414 11.55031,11.43513c2.99906,3.06186 6.88707,6.33548 11.55494,5.3715c5.29433,-0.22202 10.59843,-0.69504 15.86887,0.11813c6.62915,0.20227 11.68968,-4.86697 17.34699,-7.47091c6.65061,-5.10882 5.60349,-14.23425 4.9405,-21.50308c-0.81295,-4.48772 0.97096,-8.97747 0.63851,-13.42318c-4.79473,-5.67549 -8.72858,4.30032 -7.36273,8.58626c-0.00033,5.39139 1.06989,12.33642 -4.24626,15.84842c-4.38726,-0.10703 -8.56266,1.43464 -12.98374,0.62857c-3.58747,2.06097 -9.39828,2.00805 -10.58243,-2.89817c-0.47276,-4.35705 1.56796,-8.92497 -1.20482,-12.99132c2.43621,2.02988 6.68665,-1.75314 4.31784,2.79772c-2.88927,3.70439 2.44652,9.4126 4.45519,3.94487c0.66642,-3.66853 -2.88264,-8.53746 2.95127,-7.75151c1.18974,1.294 -4.06286,10.3455 3.11711,8.05809c5.11892,-1.08475 -0.9107,-8.85298 6.02132,-8.87998c3.35485,-3.82093 2.45156,-10.98278 7.58327,-13.88145c5.72183,-3.74609 14.65554,-1.04156 18.73944,-7.38556c3.48095,-3.24645 1.84283,-12.24456 -4.16055,-9.26305c-7.50229,0.70753 -1.54818,-9.83016 -1.7575,-13.77875c1.76767,-3.43908 -2.1467,-10.67834 -0.79881,-11.4464c2.54688,3.76975 3.45907,8.17887 2.91134,12.58444c-0.04707,3.73606 -1.68484,13.8613 3.68412,7.61956c1.81753,-4.34994 1.28892,-9.27703 2.58382,-13.80264c2.49752,-9.77067 -1.97434,-19.54677 -6.95965,-27.82247c-4.24589,-4.4552 -9.63619,-8.00672 -14.69808,-11.50349c-8.51428,-3.09788 -17.91537,-3.65286 -26.90774,-2.87646c-7.95413,1.3338 -16.36557,2.74 -22.70204,7.98656c-6.17543,3.52015 -12.0897,8.19545 -14.53111,14.95939c-2.12758,5.44903 -5.85324,10.99819 -4.15996,17.05128c1.6194,5.04592 0.7605,10.2863 1.0227,15.44375c2.76058,5.89445 5.36691,-3.01622 5.10857,-5.96359c0.15282,-5.58914 3.2009,-10.53634 5.44691,-15.49807l0,-0.00001l0.00001,-0.00002zm50.70444,11.99076c5.67695,0.39354 12.86484,3.45187 13.01976,9.82786c0.86321,6.39848 -4.48101,12.60066 -11.32975,11.97319c-6.22086,-0.49434 -10.19946,-5.69279 -9.78637,-11.53731c-2.08273,-4.19059 1.15836,-8.67877 5.5082,-9.64211c0.84353,-0.2744 1.71056,-0.47979 2.58817,-0.62163l0,0l-0.00001,0zm-38.30987,0.54499c6.58569,-1.13306 14.07851,2.81927 14.1005,9.87155c0.61853,6.81768 -6.86351,8.1534 -11.96743,9.86133c-3.53168,2.20607 -7.20026,0.15205 -10.13481,-2.07063c-3.80743,-3.85538 -2.68834,-11.62455 1.33192,-15.14385c1.9495,-1.39579 4.36282,-1.94447 6.66982,-2.5184zm22.53524,17.98562c3.18821,4.23925 7.01567,10.70382 2.89263,15.51522c-3.66013,2.83974 -4.12158,-4.03924 -7.96324,-0.79952c-3.60393,-3.05347 -0.27998,-9.26698 2.24873,-12.36894c0.83346,-0.89324 1.78721,-1.67964 2.82187,-2.34676z" stroke-width="5" style="fill:#';
  string private sword1='<path transform="rotate(28.4051 231.952 242.145)" d="m210.46724,198.32755c-5.46219,-0.27315 -15.29382,3.82639 -13.1016,-3.1806c3.80043,-4.30022 14.09016,-2.25567 12.92047,2.75555l0.13358,0.31346l0.04755,0.11159l0,0zm13.21175,-9.29505c-5.21336,5.83015 -16.95859,6.24708 -25.77762,8.41846c-4.08457,1.52963 -20.64414,2.52373 -14.33873,-2.14606c9.0045,-3.89701 20.07968,-4.83768 30.21774,-6.96267c3.26421,-0.50086 7.05059,-0.69749 9.8986,0.69027zm-26.96423,6.16586c-3.97693,-8.91171 -7.95385,-17.82341 -11.93078,-26.73512c4.86513,-4.32083 15.59164,-2.44707 14.10563,3.31249c3.09186,6.92837 6.1837,13.85676 9.27555,20.78515m-4.28509,4.68915c17.37101,39.74345 37.57145,79.01973 62.81451,116.94766m-58.22789,-117.98162c17.54839,37.4015 35.50732,74.84224 59.73027,110.67725c0.33343,2.77646 11.39528,11.10089 1.3666,8.95292c-3.11859,-0.9757 -8.44479,-0.31227 -9.02249,-3.17482c-23.66371,-37.33912 -44.18073,-75.52609 -61.51745,-114.31691" style="fill:#';
  string private sword2='<path transform="rotate(28.4051 224.452 238.645)" d="m209.05897,197.84237c-4.80876,-0.2603 -13.46426,3.64632 -11.53429,-3.03092c3.34579,-4.09785 12.40459,-2.14952 11.37483,2.62587l0.1176,0.29871l0.04187,0.10634l0,0zm11.63126,-8.85763c-4.5897,5.55579 -14.92988,5.9531 -22.69391,8.02229c-3.59595,1.45764 -18.17454,2.40496 -12.62342,-2.04507c7.92732,-3.71361 17.6776,-4.61002 26.60287,-6.63501c2.87372,-0.47729 6.20714,-0.66467 8.71446,0.65779zm-23.73857,5.8757c-3.50118,-8.49233 -7.00236,-16.98465 -10.50353,-25.47698c4.28313,-4.11749 13.72645,-2.33191 12.41821,3.15661c2.72198,6.60232 5.44396,13.20467 8.16594,19.80701m-3.77248,4.46849c15.29296,37.87314 33.07688,75.30111 55.30018,111.44416m-51.26224,-112.42947c15.44912,35.64141 31.25967,71.32021 52.5849,105.46883c0.29354,2.64581 10.0321,10.57848 1.20312,8.5316c-2.74552,-0.92979 -7.43456,-0.29757 -7.94316,-3.02541c-20.83288,-35.58196 -38.8955,-71.97188 -54.15828,-108.93722" style="fill:#';
  string private zz='"/>';
  string private tr1='", "attributes": [{"trait_type": "Background","value": "';
  string private tr2='"},{"trait_type": "Stone","value": "';
  string private tr3='"},{"trait_type": "Cracks","value": "';
  string private tr4='"},{"trait_type": "Engraving","value": "';
  string private tr5='"}], "description": "First 100% OnChain NFT collection on the FTM Blockchain. There are a total of 3000 tombs available for the owners to be spooked. This collection says NO to IPFS and API. ", "image": "data:image/svg+xml;base64,';
  string private ra1='A';
  string private ra2='B';
  string private ra3='C';
  string private ra4='D';
  string private co1=', ';
  string private rl1='{"name": "Tale Of Tombs ';
  string private rl3='"}';
  string private rl4='data:application/json;base64,';

  struct Wha {
    uint8 bg;
    uint8 stone;
    uint8 border;
    uint8 tool;
  }

  // this was used to create the distributon of 3,000 and tested for uniqueness for the given parameters of this collection
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function usew(uint8[] memory w,uint256 i) internal pure returns (uint8) {
    uint8 ind=0;
    uint256 j=uint256(w[0]);
    while (j<=i) {
      ind++;
      j+=uint256(w[ind]);
    }
    return ind;
  }

  function randomOne(uint256 tokenId) internal view returns (Wha memory) {
    tokenId=12839-tokenId; // avoid dupes
    Wha memory wha;
    wha.bg = uint8(random(string(abi.encodePacked(ra1,tokenId.toString()))) % 8);
    wha.stone = usew(stone_w,random(string(abi.encodePacked(sword1,tokenId.toString())))%58);
    wha.border = usew(border_w,random(string(abi.encodePacked(ra3,tokenId.toString())))%172);
    wha.tool = usew(tool_w,random(string(abi.encodePacked(ra4,tokenId.toString())))%331);
    if (tokenId==569) {
      wha.tool++; // perturb dupe
    }
    return wha;
  }

function getTraits(Wha memory wha) internal view returns (string memory) {
    string memory o=string(abi.encodePacked(tr1,bgname[wha.bg],tr2,stonename[wha.stone],tr3,bordername[wha.border]));
    return string(abi.encodePacked(o,tr4,toolname[wha.tool],tr5));
  }


  // return comma separated traits:
  function getAttributes(uint256 tokenId) public view returns (string memory) {
    Wha memory wha = randomOne(tokenId);
    string memory o=string(abi.encodePacked(uint256(wha.stone).toString(),co1));
    return string(abi.encodePacked(o,uint256(wha.border).toString(),co1,uint256(wha.tool).toString(),co1,uint256(wha.bg).toString()));
  }

  function genTool(uint8 h) internal view returns (string memory) {
    string memory out = '';
    if (h>=0 && h<7) { out = string(abi.encodePacked(sword1,col4[0],zz,sword2,tooc[h],zz)); }
    if (h>6 && h<14) { out = string(abi.encodePacked(skull1,tooc[h],zz));
    out= string(abi.encodePacked(out,skull2,col4[0],zz,skull3,tooc[h],zz)); }
    return out;
  }

  function genSVG(Wha memory wha) internal view returns (string memory) {

    string memory output = string(abi.encodePacked(z[0],background[wha.bg],z[1],bgFace[wha.stone],z[2]));
    output = string(abi.encodePacked(output,bgBottom[wha.stone],z[3],bgFace[wha.stone],z[4],bgBack[wha.stone],z[5]));
    output = string(abi.encodePacked(output,bgBottomBack[wha.stone],z[6],bgBottomBack[wha.stone],z[7],col3[0],z[8]));
    output = string(abi.encodePacked(output,col3[0],z[9],col3[0],z[10],col3[0],z[11]));
    output = string(abi.encodePacked(output,col3[0],z[12],col3[0],z[13],col4[0],z[14]));
    output = string(abi.encodePacked(output,col4[0],z[15],col4[0],z[16],col4[0],z[17]));
    output = string(abi.encodePacked(output,borders[wha.border],z[18]));
    return string(abi.encodePacked(output,genTool(wha.tool),z[19]));
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    Wha memory wha = randomOne(tokenId);
    return string(abi.encodePacked(rl4,Base64.encode(bytes(string(abi.encodePacked(rl1,tokenId.toString(),getTraits(wha),Base64.encode(bytes(genSVG(wha))),rl3))))));
  }

  function ownerClaim(uint256 tokenId, address tomb_holder) public nonReentrant onlyOwner {
    require(tokenId > 0 && tokenId < 3001, "invalid claim");
    _safeMint(tomb_holder, tokenId);
  }

  constructor() ERC721("TaleOfTombs", "TOT") Ownable() {}
}