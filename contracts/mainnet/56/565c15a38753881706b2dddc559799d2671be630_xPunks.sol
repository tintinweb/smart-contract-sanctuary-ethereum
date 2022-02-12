/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT


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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

// File: contracts/LowerGas.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 (max value of uint128) of supply
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
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

    uint256 internal currentIndex = 0;

    uint256 internal immutable maxBatchSize;

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

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_
    ) {
        require(maxBatchSize_ > 0, 'ERC721A: max batch size must be nonzero');
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), 'ERC721A: global index out of bounds');
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), 'ERC721A: owner index out of bounds');
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
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
        revert('ERC721A: unable to get token of owner by index');
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
        require(owner != address(0), 'ERC721A: balance query for the zero address');
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), 'ERC721A: number minted query for the zero address');
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), 'ERC721A: owner query for nonexistent token');

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert('ERC721A: unable to determine the owner of token');
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
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
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
        require(to != owner, 'ERC721A: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721A: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'ERC721A: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), 'ERC721A: approve to caller');

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
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721A: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), 'ERC721A: mint to the zero address');
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), 'ERC721A: token already minted');
        require(quantity <= maxBatchSize, 'ERC721A: quantity to mint too high');
        require(quantity > 0, 'ERC721A: quantity must be greater 0');

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                'ERC721A: transfer to non ERC721Receiver implementer'
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
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
    unchecked {
        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
    }

        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
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
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

pragma solidity ^0.8.0;

contract xPunks is ERC721A, Ownable {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    mapping(address => bool) whitelist;

    uint256 public cost = 0.00 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 100;
    uint256 public nftPerAddressLimitWl = 10;

    bool public paused = true;
    bool public onlyWhitelisted = true;

    mapping(address => uint256) public addressMintedBalance;

    constructor() ERC721A("0xPunks", "0xPunk", maxMintAmountPerTx) {
        whitelist[0x8950507282B85127eBf0c27465a3CBc5079e9B8B] = true;
        whitelist[0xa7868550a0B397Da722D9705AA49B7299B8A33EF] = true;
        whitelist[0x76433F75F03af38621937eA1dF9D2AfD7a40e945] = true;
        whitelist[0xb58b6370d7d28f00906811AA591C4AB7e64D17cF] = true;
        whitelist[0x0423A96A0f5e937182080FB49b552003B8385F98] = true;
        whitelist[0x3ef083f9f48B5f3b7734aA582f7BF04cf2D4b173] = true;
        whitelist[0xC23C131474F297445C80E01a82d2C26710e1eE04] = true;
        whitelist[0x66c31c7f9f7b83e9f3dD7D4a1927718699C0Fd23] = true;
        whitelist[0x060A8aCd75600A9C1BA459BE7552D39a8240c406] = true;
        whitelist[0xaB0DFa07aC5E991C3932E871B6891C6af7C61394] = true;
        whitelist[0x0705A9B50f75bF6217bd0489B30DC50516982EFA] = true;
        whitelist[0xbDBA43F98D3609a92e92fA4e94Adca011E3dD10C] = true;
        whitelist[0x0B74DF5BF962f95059a27bFBE24811eD7529B86D] = true;
        whitelist[0xE1698607C930dC6330C5706827c033e1A810C8cd] = true;
        whitelist[0x43A85e0Bc901BbA74fbEC5c968cc8A5BD58ed9D4] = true;
        whitelist[0x709273edc511F6180f36dCebbF93d61E0e3e79e4] = true;
        whitelist[0xcbee667d79772E21522B4e9130B567bA5094F08d] = true;
        whitelist[0x87133bd017ae8E811d7b98Ebe542F03D532E4Bd2] = true;
        whitelist[0xDfae7A193E246E6D99bF340193e5Ffa738D4EAbB] = true;
        whitelist[0x9876449DE01A64a87F765aA72651CC795E44ef29] = true;
        whitelist[0x8E2AF953De826e92E4bB253906D216a6d82BF4D0] = true;
        whitelist[0x8EDb8FFDc0E690Bb5852a7d83D48246F18250D18] = true;
        whitelist[0x3c0508B8F5c3e45119c6927A1ac49849fC67d32A] = true;
        whitelist[0x7196dFb5a25f4A444a905Dc7e712E41c325D60EE] = true;
        whitelist[0xb670357Fa3FAeDe5DC91CBe9F5D2A9D4e6dB3435] = true;
        whitelist[0x69305Eb29BFdBf46eB194Fd148722DD76Ba82A72] = true;
        whitelist[0xEEdD9171c591e01161c1b28a1D4a1db4eC030CEe] = true;
        whitelist[0xeEeC3aD8773a980f42C50DC4167ae3F3C7BE2Ee1] = true;
        whitelist[0x80c0088A56828BB0930bC28B93fcE0415B611d4e] = true;
        whitelist[0xe4f5DC22B0d48f3243b90Dd7efd4d9a26Ad24EDF] = true;
        whitelist[0x082fd10c51Ae3f47E0d6AeC3D81506a9FF7c2D93] = true;
        whitelist[0xD415BC63A4d4966D52B638fC5f3B7ede7BffCAa2] = true;
        whitelist[0x60aBc21754286A71D75b51947143A59319BA27fC] = true;
        whitelist[0x6C6Bd1b569d8C6067514fbF94221330316d6d424] = true;
        whitelist[0x6abe2A3Ff9DCb5389cf3c15A347B68CF539332c8] = true;
        whitelist[0x5D9398a9a9b88764f49eBc7F0fdc8344bAd3C58d] = true;
        whitelist[0x7d3C13FC1037652545395882Ba64C3F024E30841] = true;
        whitelist[0x3a766e5FEb4a955103a5B57463593FE66B0C8dFD] = true;
        whitelist[0x9841f6cDDE91ACa364C71b43469A8c9B021E096a] = true;
        whitelist[0x6031B736D50F0D4845eB756169E74F7e3756e157] = true;
        whitelist[0xb5A38E6Fa233Ad318eE22BED6B50a6EACB1f23ca] = true;
        whitelist[0xDD41Ef8F9ce193abeD960ab9d30db0a0dee1DD29] = true;
        whitelist[0xB1bb090F332743Cb2c618271f0a069d6d0F26b86] = true;
        whitelist[0xbd8394B4040485984031f7956eAf106e1B30966D] = true;
        whitelist[0xEc2bDcb9d003593752246c5C582417b4732388AF] = true;
        whitelist[0x95181454510CCcD77EC910146a79BBc5619Daf76] = true;
        whitelist[0x2FA5D2dFA5317d7E0a5012547a23787A99F37B02] = true;
        whitelist[0x2E1d22353c8BFBf09B46e62D1F48Bd5b66dadE1f] = true;
        whitelist[0x940618ce8741C7eC2e95A6f11D79F9252A5Cce15] = true;
        whitelist[0x76f6AD15694FEEE5F3a055baD2E45D185f0048be] = true;
        whitelist[0x4df3772b95A745Fc850B7f636A17FA6169171468] = true;
        whitelist[0x75576DaB750c88B3CA8eb2B5510C47e3BF7c78a4] = true;
        whitelist[0xf6b4E7e3605C72EaEf290eB4C90C4bDB128c0DAb] = true;
        whitelist[0xAB8EA35D2e200bF9089b7E9Bee47568Fdb211012] = true;
        whitelist[0xB5c6D5bd47cDf90B897AA3D10c82aFa8178E6E95] = true;
        whitelist[0x53475949ACf6C33CDb9d38663c5Ca1337f9a4aC8] = true;
        whitelist[0x4547E9f00d6653CbA21eAf876407eC402044e7d1] = true;
        whitelist[0x5E70F21d15a4338Cc73829320a1633E078e2a7DB] = true;
        whitelist[0xaB2F5627B9DE831d75ab893D21Df0193E484c2c5] = true;
        whitelist[0xDc13005aBCEB471e3513f1a4A1b3279A215EE926] = true;
        whitelist[0xc012d72Cd1d05B5d4A69361C8f1d292516F6E46f] = true;
        whitelist[0xB527f9b886231Bd5609264767521b1A22A81bc32] = true;
        whitelist[0xaF3c7adA8Cb623B2b4cd2Aa497F2689fcA1DB192] = true;
        whitelist[0xD53bCC6a2C2d4C60D889Bb9bB34913dA58b9d104] = true;
        whitelist[0x112f7E9307736149540954EFDCd4A0B60881496d] = true;
        whitelist[0x23b5Da4853B2C846aF5554B9FB68Bf5686B5353a] = true;
        whitelist[0x640e5b00aB5e4368A2BB077255A8B5E27C87997E] = true;
        whitelist[0x8A1d7a7e230849d88Cd237Bb446bb38BBeacc051] = true;
        whitelist[0xdbeAF92c601721Da293ad636903627e0955D94c5] = true;
        whitelist[0xB438105f9049294bAbdC8040f1F8D1d6FF7570c4] = true;
        whitelist[0x288F4336Ed3A09B1efE622C1cdcDBf4b168FCA39] = true;
        whitelist[0xeDF6714512eb99Dc339741CA8FBb47CF77448d3C] = true;
        whitelist[0x3aE5f284430b14a12ffd4E2Be6ed425c15650D20] = true;
        whitelist[0x6a575eCAe3d5cCc4bB1fAf2342eB77170b19A412] = true;
        whitelist[0x03A8726172fA51D64b0c3D583dE5876e73d73d0e] = true;
        whitelist[0x1608Ff5289837bE911607a1384C6FC4eeb42f162] = true;
        whitelist[0x6003838aFef9c93f050070F5b947acCaC61C8dC1] = true;
        whitelist[0xD9498e2fc646B5882e78a6243FB5EfAeDc1cD85f] = true;
        whitelist[0x222d6b7D7270F63d1e55587f5703F71Bf48f5305] = true;
        whitelist[0x399b5B66B70AD7B884a4b91A41049a5D0023076B] = true;
        whitelist[0x54d6d8Ae3BF787d89A673241F14817886f057aEC] = true;
        whitelist[0x2BD0A65B7E0f5759ce21E380269a42b615E8eA15] = true;
        whitelist[0xf11Fa70332dF9f3b40498bD3D8E837d69CAB76eC] = true;
        whitelist[0x3541500AA53bC242ae50498E91850a3dE89F4dfc] = true;
        whitelist[0xED47dE07c8a00c7d3eC096598A1a50e1467Ca65B] = true;
        whitelist[0xc605564e306a7bDC86d34Cf0CA39826BC34A5780] = true;
        whitelist[0x616aBaAEE8D6CEac7d6B8a81DabBF24614A8A71A] = true;
        whitelist[0x93b48aA209Dc9d9760ffB979A004a9623E085608] = true;
        whitelist[0x65C540ab906d287D3DE03B1BeB0A928e95AE4a68] = true;
        whitelist[0x14a88E30B610Cd12A029BC8B182d80d0C5cBF130] = true;
        whitelist[0x5887f4967b086123D0034945A180B4AE404BAB59] = true;
        whitelist[0x216967cC1E2bc57A296A55b9687AC184485374a9] = true;
        whitelist[0x08924f908484eA57EFe132C0dbA1924Cd1B9eE7E] = true;
        whitelist[0x505A09A559b3Dd0a9DEf9E0A4a37aDc9aA3f18E2] = true;
        whitelist[0xb266E542c645627da44821b1010C25768E23e112] = true;
        whitelist[0x884d9a4C073096Ee84951bf079F8E17bC23AdD05] = true;
        whitelist[0xcbF727141be136C8B3993f06893c5c7466bAC013] = true;
        whitelist[0x929a12d5d22ffEf6E39Bc1c2276e1EB61f73dA4e] = true;
        whitelist[0xdEe822Bf349F4f27aAab0FC2301e35eb4b9fE82B] = true;
        whitelist[0xfD69501D62BF232c2fF1A186c9757047E37B7469] = true;
        whitelist[0xB5A2370E6e741c6A12c40E6FF8FC6852D38e88cE] = true;
        whitelist[0x36D7e86212Eff3837671ddb76F5111A4E5fE6f9F] = true;
        whitelist[0x974F851a17dDE74aBA727eEdbC310492778e5aAF] = true;
        whitelist[0x075CaFcDa6cC6B472ED9ac0A23D22730a112Fc11] = true;
        whitelist[0x1878166eE6d72E287c75bc169ef2c4e7eA5B7a5E] = true;
        whitelist[0xf390fBf1993F2559F5425309D5230D74e9a0B84c] = true;
        whitelist[0xA7f1a10c9F862444d2E87f4EC91293B9926181EF] = true;
        whitelist[0x4B8Db3EeE0dBf35a3D13d910e48Ab29b57EAf381] = true;
        whitelist[0xc95332cd0f986Dc8bFa9ec137bB846530Bb7C993] = true;
        whitelist[0x7F4F5983e886fC61a054b6b5566adc0652799e24] = true;
        whitelist[0xf72E7c395e252926C11152d59e28f35bD204508A] = true;
        whitelist[0x4A52b132a00330fa03c87a563D7909A38d8afee8] = true;
        whitelist[0x7cA9089962600A9e708444aE2Cf0AfFDcC0577E0] = true;
        whitelist[0x67B1045f193B35a31C90BE77e3f1C3da95339799] = true;
        whitelist[0x894d3BE637D08Dd563a4F0680d07bfF63F5023bb] = true;
        whitelist[0x825e825D65ce535bac38617d25D0F6182ACa5A80] = true;
        whitelist[0xA56AC6Bf86212B039c0d5a4F32039B8DA1a9c6AE] = true;
        whitelist[0x91cB240fdF49c9231A44391a7B899ab8D8EBEa85] = true;
        whitelist[0xdC65010f53576BFf30F7eb3a6B4C055E50e1dD59] = true;
        whitelist[0x718bc2a2646d3bd44a4949817e9eC3977E63c7F9] = true;
        whitelist[0xc6D22E96b86811dcA83F4b710610F5ab697534b5] = true;
        whitelist[0xE181b5C3bA16b6b13b5Bf3FEbe569C7BF300358c] = true;
        whitelist[0x3A8B8d1d156477BF6Fd20f248eF8b2f1d03fB251] = true;
        whitelist[0xa85352ff10189979e9A2d051Ff7BeF36CfA4105E] = true;
        whitelist[0x267d7aDC497CdaCc9E986b03E76030173c2f071F] = true;
        whitelist[0x61299F94ede485b997760e5fC789f432D82ba60e] = true;
        whitelist[0x1B7C38ED20337Eb5107E4d2324D6fb7485B0828B] = true;
        whitelist[0x8A53b410031c6C606CD495DFE1F3e65003dC384C] = true;
        whitelist[0xF0BF03895366f562A5d079EbED178Ebb0F3C137f] = true;
        whitelist[0x9050618292cFd34C7768e1DF8B0C14CaFE99AE2D] = true;
        whitelist[0x3F5d7a01D9A32817d9cE7EEb85cF40e95c32Cb84] = true;
        whitelist[0xA26c5F0b89322cd75828d5085Db8164287315df3] = true;
        whitelist[0x101A0778cda24359A096342A2Aa45eF52A6Ec1dF] = true;
        whitelist[0xffC81e8FF9A40727d7df97233F1Fae26344EB90C] = true;
        whitelist[0x8BB8056D9B8A6f7c19d292182E8bD0555703619D] = true;
        whitelist[0xAfC2F698a08B957CCc33a2D931AacEf2F970959E] = true;
        whitelist[0x154500Ccb9cC55A0E390966AA53Fe10E7DA1047d] = true;
        whitelist[0x332EEbd4bC9027176ABac020B32FB401B685b622] = true;
        whitelist[0x4a8A003acC8a2c0329286e46650bE18dfe2cb12d] = true;
        whitelist[0x18A47791DFd3A120BbB74dCcB78080773642B904] = true;
        whitelist[0xc42480b588Aff1B9f15Db3845fb74299195C8FCE] = true;
        whitelist[0x3679a16c418da3416F0D69C9F2458B2bFF795661] = true;
        whitelist[0xCE8115142c4F1a6800eFE097B7906C69391A4E0f] = true;
        whitelist[0xb87887822e4F856D9c9BeE711970474b2804e85B] = true;
        whitelist[0x823b47733E2B3eE86cfF4263CE3Df8FF3FD733c3] = true;
        whitelist[0x8f4EA43f0CAf2a8D9Bb0dC4d2e23C809F13807da] = true;
        whitelist[0x888E0021b852BB4acE259e2a1E635d4dF090955c] = true;
        whitelist[0x453AE45bd4a672A708902C5ecF7da9C746C22aE2] = true;
        whitelist[0x06b745CB7564E6c7B1eaB76aa017000229f1fF7c] = true;
        whitelist[0xF514Cda5173cDf41b2f1784cBc3dAAb68cd177bd] = true;
        whitelist[0x585f2C2142550503E5441f1257512C6EDE6E9C14] = true;
        whitelist[0x56CF2aFF10c47CcD54ea9bEF6c723fDdA18c09c8] = true;
        whitelist[0x24C6E698a4bC01A70223F9d10bB6C4B7c62C3654] = true;
        whitelist[0xc0206D84Ac53242B48700ee4d31292c9A039F56D] = true;
        whitelist[0x3D7E059A0805cEe4eAd6052725E2738275E873d2] = true;
        whitelist[0x7f87b63c5DE256E81cC9465C3364d2c288837406] = true;
        whitelist[0xF7ce09F3df6c357dd3337F5700b0ec64E4b4cd1B] = true;
        whitelist[0x352469270f9AebcF41503fAa69f9d9a2Dd21271F] = true;
        whitelist[0xf9d1144F72E59Cf2Ec1c0A9e1a35a93B41B28F95] = true;
        whitelist[0x7597CF59d781d626D851D3301AD7DAb682692788] = true;
        whitelist[0x0e8aF8a5ad2dE05d29092b0456089ad46657c67e] = true;
        whitelist[0xEb7BC5C16C0E31Aa4f386E7B1D529c45D7750AC7] = true;
        whitelist[0xEb7BC5C16C0E31Aa4f386E7B1D529c45D7750AC7] = true;
        whitelist[0x780CFD2F5fA3E3cB8F99Bc14A0879C698Db04583] = true;
        whitelist[0xe6E416d39Dd0b521dA1b59D3af4D8930e6d5626B] = true;
        whitelist[0xA79042D975C435b5B02196e363F4A09147230ebf] = true;
        whitelist[0x732Bb12525961f5853154DeB9d0a4Aacd2eB240f] = true;
        whitelist[0x70D7B21f7585c02A665aD6AC0C900AF0cEAB2b55] = true;
        whitelist[0x0E01800b3Edf3933657d08aa39FE2152FC325E97] = true;
        whitelist[0x7301A502ce32e15838Ec1E4F10e2BFc2Ec3bf0a0] = true;
        whitelist[0x1Ccf5898c6Fa8208BAA2918A4fB4E283069bd1bE] = true;
        whitelist[0x64A060C7b979e1de998Bca7AE30BB700fDaf6998] = true;
        whitelist[0xF514CD2D661ad6bE472df3b7398492F40609bFEC] = true;
        whitelist[0x8A1137F86d2e33BF6a1Fb97159B0327bf1bE19ff] = true;
        whitelist[0x8D8f852De8698013E015A2a3260Df7409cB352E7] = true;
        whitelist[0x530e6E083E6D842DD883D9D1F59a8733dA1Dbf9d] = true;
        whitelist[0x5356d041cFdE0fbFa7691327AC29Fe9709C3F6B7] = true;
        whitelist[0x74D6D53dD045220DCE6999b5C9a2E468d881c6c6] = true;
        whitelist[0x299E736200fC47486f7BCfE04D5EEA8C7D0a7006] = true;
        whitelist[0xb26a76fB5dA1a3cd337bC11be8b0222D2ab16e91] = true;
        whitelist[0xeb42523A092CeaFb6b5b52b0a88d3F88154A3494] = true;
        whitelist[0x173aaE27F24539142452Fe2FC2927F6966B04664] = true;
        whitelist[0x5Ab733A1cbBd39f452BdC6869CE30e7BBBA3D3D0] = true;
        whitelist[0x649343619d5D1cd7a5C7D9553eD756BDa225B608] = true;
    }

    /**
      * @dev validates whitelist
    */
    modifier isWhitelisted(address _sender) {
        require(whitelist[msg.sender], "Address does not exist in OG list");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(currentIndex + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(!onlyWhitelisted, "Presale is on");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _safeMint(msg.sender, _mintAmount);
    }

    function mintWhitelist(uint256 _mintAmount) public payable isWhitelisted(msg.sender) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(!paused, "The contract is paused!");
        require(onlyWhitelisted, "Presale has ended");
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimitWl, "max NFT per address exceeded");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        addressMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setNftPerAddressLimitWl(uint256 _limit) public onlyOwner {
        nftPerAddressLimitWl = _limit;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}