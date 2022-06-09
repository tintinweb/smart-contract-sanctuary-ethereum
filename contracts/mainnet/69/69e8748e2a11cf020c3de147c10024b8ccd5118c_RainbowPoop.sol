/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

/*  🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈
    RainbowPoop 
    not just a piece of shit
    but also a rainbow poop 🌈💩
    or probably another piece of shit
    or something
    or probably nothing
    or 'poopchip'
    Let's poop it! Hellyeah!
    https://rainbowpoop.wtf
    💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩💩
 */


// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

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

// File @openzeppelin/contracts/access/[email protected]

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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

// File @openzeppelin/contracts/interfaces/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

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

        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File contracts/ERC721A.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
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

    uint256 private currentIndex = 0;

    uint256 internal immutable collectionSize;
    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     * `collectionSize_` refers to how many tokens are in the collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) {
        require(collectionSize_ > 0, "ERC721A: collection must have a nonzero supply");
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
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
        require(index > 0 && index <= totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
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
        revert("ERC721A: unable to get token of owner by index");
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
        require(owner != address(0), "ERC721A: balance query for the zero address");
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), "ERC721A: number minted query for the zero address");
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

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

        revert("ERC721A: unable to determine the owner of token");
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
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721A: approve caller is not owner nor approved for all");

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "ERC721A: approve to caller");

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
    ) public override {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721A: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - there must be `quantity` tokens remaining unminted in the total collection.
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
        uint256 startTokenId = totalSupply() + 1;
        require(to != address(0), "ERC721A: mint to the zero address");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "ERC721A: token already minted");
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(addressData.balance + uint128(quantity), addressData.numberMinted + uint128(quantity));
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(_checkOnERC721Received(address(0), to, updatedIndex, _data), "ERC721A: transfer to non ERC721Receiver implementer");
            updatedIndex++;
        }

        currentIndex += quantity;
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

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr || getApproved(tokenId) == _msgSender() || isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, "ERC721A: transfer caller is not owner nor approved");

        require(prevOwnership.addr == from, "ERC721A: transfer from incorrect owner");
        require(to != address(0), "ERC721A: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
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

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > collectionSize - 1) {
            endIndex = collectionSize - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), "not enough minted yet for this cleanup");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(ownership.addr, ownership.startTimestamp);
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
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
                    revert("ERC721A: transfer to non ERC721Receiver implementer");
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

// File contracts/Base64.sol

pragma solidity ^0.8.0;

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

// File contracts/RainbowPoop.sol

pragma solidity ^0.8.0;

contract RainbowPoop is ERC721A, Ownable, IERC2981 {
    using Strings for uint256;
    using Strings for uint8;

    string[8] private RAINBOW_COLORS = ["url(#rainbow)", "#ff2f2b", "#ff5722", "#ffeb3b", "#4caf50", "#03a9f4", "#673ab7", "#9c27b0"];
    string[23] private GENERAL_COLORS = [
        "url(#rainbow)",
        "#fff",
        "#f44336",
        "#e91e63",
        "#9c27b0",
        "#673ab7",
        "#3f51b5",
        "#2196f3",
        "#03a9f4",
        "#00bcd4",
        "#009688",
        "#4caf50",
        "#8bc34a",
        "#cddc39",
        "#ffeb3b",
        "#ffc107",
        "#ff9800",
        "#ff5722",
        "#795548",
        "#9e9e9e",
        "#607d8b",
        "#000",
        "none"
    ];

    string[8] private HAIR_COLORS = ["url(#rainbow)", "#607d8b", "#f44336", "#fff", "#8bc34a", "#2196f3", "#ff9800", "#795548"];
    string[8] private HEAD_COLORS = ["url(#rainbow)", "#607d8b", "#f44336", "#fff", "#8bc34a", "#2196f3", "#ff9800", "#795548"];
    string[8] private BOTTOM_COLORS = ["url(#rainbow)", "#f44336", "#000", "#8bc34a", "#2196f3", "#607d8b", "#ff9800", "#795548"];

    struct Poop {
        uint8 background;
        uint8 hair;
        uint8 head;
        uint8 bottom;
        uint8 eyes;
        uint8 mouth;
        uint8 generation;
        uint8 shit;
    }

    string[8] private backgroundAttr = [unicode"🌈", "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet"];
    string[8] private hairAttr = [unicode"🌈", "Goblin", "Punk", "Pure", "Zombie", "Ape", "Popcorn", "Poop"];
    string[8] private headAttr = [unicode"🌈", unicode"👽", unicode"👹", unicode"💀", unicode"🧟", unicode"🤖", unicode"🦹‍♂️", unicode"💩"];
    string[8] private bottomAttr = [unicode"🌈", "Beetrootpoop", "Poophole", "Veganpoop", "Poopman", "Koalapoop", "Shampoop", "Poopoop"];
    string[8] private eyesAttr = [unicode"🌈", "Laserpoop", "Cyclopoop", "Fasionpoop", "Poophole", "Pandapoop", "Koalapoop", "Poopoop"];
    string[8] private mouthAttr = [unicode"🌈", "Poopshit", "Freezingpoop", "Puppypoop", "Bitchpoop", "Boredpoop", "Nopoop", "Cheesepoop"];
    string[8] private generationAttr = [unicode"🌈", unicode"💩"];
    string[8] private shitAttr = ["L", "G", "B", "T", "Q", "I", "A", "P"];

    constructor() ERC721A("RainbowPoop - from shit to rainbow poop", "rainbowpoop.wtf", 10, 10000) {}

    function poop(uint256 quantity) external payable {
        require(quantity <= 2, "poop too much");
        require(quantity + totalSupply() <= collectionSize, "no more poop");
        require(balanceOf(msg.sender) + quantity <= maxBatchSize, "you own poooooop");
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        Poop memory p = randomPoop(tokenId);
        string memory output = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Rainbow Poop #',
                        tokenId.toString(),
                        unicode'", "description": "RainbowPoop is not just a piece of shit, but also a rainbow poop 🌈💩. "',
                        ',"attributes":',
                        poopAttributes(p),
                        ',"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(poopSVG(p))),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", output));
    }

    function poopSVG(uint256 tokenId) public view returns (string memory) {
        return poopSVG(randomPoop(tokenId));
    }

    function poopSVG(Poop memory p) private view returns (string memory) {
        string[9] memory parts = [
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60"><defs><linearGradient id="rainbow" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#ff2f2b"/><stop offset="17%" stop-color="#ff5722"/><stop offset="33%" stop-color="#ffeb3b"/><stop offset="50%" stop-color="#4caf50"/><stop offset="66%" stop-color="#03a9f4"/><stop offset="83%" stop-color="#673ab7"/><stop offset="100%" stop-color="#9c27b0"/></linearGradient></defs>',
            poopBackground(p.background),
            poopHair(p.hair),
            poopHead(p.head),
            poopBottom(p.bottom),
            poopEyes(p.eyes),
            poopMouth(p.mouth),
            poopGeneration(p.generation),
            "</svg>"
        ];

        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    }

    function randomPoop(uint256 tokenId) private pure returns (Poop memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId)));

        return
            Poop({
                background: avgPoopIndex(uint8(rand & 255)),
                hair: seqPoopIndex(uint8((rand >> 8) & 255)),
                head: powPoopIndex(uint8((rand >> 16) & 255)),
                bottom: avgPoopIndex(uint8((rand >> 24) & 255)),
                eyes: seqPoopIndex(uint8((rand >> 32) & 255)),
                mouth: seqPoopIndex(uint8((rand >> 40) & 255)),
                generation: twoPoopIndex(uint8((rand >> 48) & 255)),
                shit: avgPoopIndex(uint8((rand >> 56) & 255))
            });
    }

    function avgPoopIndex(uint8 num) private pure returns (uint8) {
        return (num % 8);
    }

    function powPoopIndex(uint8 num) private pure returns (uint8) {
        if (num < 2) {
            return 0;
        }
        if (num < 4) {
            return 1;
        }
        if (num < 8) {
            return 2;
        }
        if (num < 16) {
            return 3;
        }
        if (num < 32) {
            return 4;
        }
        if (num < 64) {
            return 5;
        }
        if (num < 128) {
            return 6;
        }
        return 7;
    }

    function seqPoopIndex(uint8 num) private pure returns (uint8) {
        if (num < 8) {
            return 0;
        }
        if (num < 16) {
            return 1;
        }
        if (num < 24) {
            return 2;
        }
        if (num < 40) {
            return 3;
        }
        if (num < 64) {
            return 4;
        }
        if (num < 104) {
            return 5;
        }
        if (num < 168) {
            return 6;
        }
        return 7;
    }

    function twoPoopIndex(uint8 num) private pure returns (uint8) {
        return (num < 51) ? 0 : 1;
    }

    function poopBackground(uint8 index) private view returns (string memory) {
        return string(abi.encodePacked('<rect width="100%" height="100%" fill="', RAINBOW_COLORS[index], '" />'));
    }

    function poopHair(uint8 index) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M39 16c-2.5 4.99-9.02 7.2-15.86 8.38l-5.91.88c-.72.13-1.41.27-2.07.44C9.62 16.56 16.36 11.87 24 9c6.28-2.36 2-8 2-8 9 0 16 9 13 15z" fill="',
                    HAIR_COLORS[index],
                    '" stroke="#000"/>'
                )
            );
    }

    function poopHead(uint8 index) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M55 35a13 13 0 01-1.74 6.33c-2.59 4.49-8.34 8.87-19 11.91l-2.39.64A125 125 0 019 57a8 8 0 01-8-8c0-3 1.5-5.25 4.5-7a12 12 0 013-1.15 70 70 0 019.71-1.54l7-.86a61.68 61.68 0 008.19-1.78l12.37-7.02A34 34 0 0048 27s7 2 7 8z" fill="',
                    HEAD_COLORS[index],
                    '" stroke="#000"/>'
                    '<path d="M48 27a34 34 0 01-2.3 2.65l-12.37 7.02a61.68 61.68 0 01-8.19 1.78l-7.0.86c-3.2.2-6.5.8-9.71 1.54A8 8 0 016 35c0-5 3.43-8 9.16-9.3.66-.17 1.35-.31 2.07-.44l5.91-.88C29.98 23.2 36.5 20.99 39 16c10 0 9 11 9 11z" fill="',
                    HEAD_COLORS[index],
                    '" stroke="#000"/>'
                )
            );
    }

    function poopBottom(uint8 index) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M59 49a8 8 0 01-8 8H9a125 125 0 0022.83-3.12l2.39-.64c10.7-3.04 16.45-7.42 19-11.91A8 8 0 0159 49z" fill="',
                    BOTTOM_COLORS[index],
                    '" stroke="#000"/>'
                )
            );
    }

    function poopEyes(uint8 index) private view returns (string memory) {
        if (index == 0) {
            return string(abi.encodePacked(_poopCircle(21, 32, 8, 0), _poopCircle(40, 32, 8, 0), _poopRect(28, 30, 1, 5, 2, 0)));
        }
        if (index == 1) {
            return string(abi.encodePacked(_poopCircle(22, 32, 2, 2, 14), _poopCircle(38, 32, 2, 2, 14), _poopRect(6, 31, 1, 48, 2, 2, 14)));
        }
        if (index == 2) {
            return '<rect x="14" y="28" rx="4" width="33" height="8" stroke-width="3" fill="#03a9f4" stroke="#000" />';
            // return _poopRect(14, 28, 4, 33, 8, 8, 21, 'stroke-width="3"');
        }
        if (index == 3) {
            return string(abi.encodePacked(_poopRect(13, 26, 3, 16, 10, 8), _poopRect(32, 26, 3, 16, 10, 8), _poopRect(28, 29, 1, 5, 2, 0)));
        }
        if (index == 4) {
            return string(abi.encodePacked(_poopCircle(17, 32, 2, 20), _poopCircle(33, 32, 2, 20), _poopRect(13, 28, 1, 14, 2, 21), _poopRect(29, 28, 1, 14, 2, 21)));
        }
        if (index == 5) {
            return string(abi.encodePacked(_poopCircle(21, 32, 8, 21), _poopCircle(39, 32, 8, 21), _poopEllipse(22, 32, 4, 2, 20), _poopEllipse(39, 32, 4, 2, 20)));
        }
        if (index == 6) {
            return string(abi.encodePacked(_poopCircle(22, 32, 2, 20), _poopCircle(40, 32, 2, 20)));
        }
        return string(abi.encodePacked(_poopEye(true), _poopEye(false)));
    }

    function poopMouth(uint8 index) private view returns (string memory) {
        if (index == 0) {
            // pure
            return _poopPath("m21 43a10 24 10 0 0 19 1z", 0);
        }
        if (index == 1) {
            // shit
            return _poopPath("m22 40a10 8 0 0 0 20 4z", 2);
        }
        if (index == 2) {
            // freezing
            return
                string(
                    abi.encodePacked(
                        _poopRect(20, 44, 3, 20, 6, 2),
                        _poopLine(24, 44, 24, 50, 21),
                        _poopLine(28, 44, 28, 50, 21),
                        _poopLine(32, 44, 32, 50, 21),
                        _poopLine(36, 44, 36, 50, 21)
                    )
                );
        }
        if (index == 3) {
            // puppy
            return _poopPath("m36 45a10 6 0 0 1-10 0", 22);
        }
        if (index == 4) {
            // bitch
            return _poopEllipse(30, 46, 5, 6, 2, 21);
        }
        if (index == 5) {
            // bored
            return _poopPath("m28 45a12 6 0 0 1 13 1", 22);
        }
        if (index == 6) {
            // cheese
            return _poopPath("M30 54c7 0 9-5 10-9a1 1 0 00-1-1 26 26 0 01-17 0 1 1 0 00-1 1C20 48 22 54 30 54z", 2);
        }

        // none
        return "";
    }

    function poopGeneration(uint8 index) private pure returns (string memory) {
        return index == 0 ? string(abi.encodePacked('<text x="1" y="15" font-size="16">', unicode"🌈", "</text>")) : "";
    }

    function _poopPath(string memory d, uint8 fill) private view returns (string memory) {
        return string(abi.encodePacked('<path d="', d, '" style="stroke-linecap:round;stroke:#000;" fill="', GENERAL_COLORS[fill], '"/>'));
    }

    function _poopEye(bool isLeftEye) private view returns (string memory) {
        string memory cx0 = (isLeftEye ? 21 : 39).toString();
        string memory cx1 = (isLeftEye ? 22 : 38).toString();
        return
            string(
                abi.encodePacked(
                    '<ellipse cx="',
                    cx0,
                    '" cy="32" rx="7" ry="8" fill="',
                    GENERAL_COLORS[1],
                    '" stroke="#000"/><ellipse cx="',
                    cx1,
                    '" cy="32" fill="#052e43" rx="2.5" ry="3.5" /><ellipse cx="',
                    cx1,
                    '" cy="32" fill="#607d8b" rx="1" ry="1.6" />'
                )
            );
    }

    function _poopLine(
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2,
        uint8 stroke
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<line x1="',
                    x1.toString(),
                    '" y1="',
                    y1.toString(),
                    '" x2="',
                    x2.toString(),
                    '" y2="',
                    y2.toString(),
                    '" stroke="',
                    GENERAL_COLORS[stroke],
                    '"/>'
                )
            );
    }

    function _poopEllipse(
        uint8 cx,
        uint8 cy,
        uint8 rx,
        uint8 ry,
        uint8 fill
    ) private view returns (string memory) {
        return _poopEllipse(cx, cy, rx, ry, fill, 22);
    }

    function _poopEllipse(
        uint8 cx,
        uint8 cy,
        uint8 rx,
        uint8 ry,
        uint8 fill,
        uint8 stroke
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<ellipse cx="',
                    cx.toString(),
                    '" cy="',
                    cy.toString(),
                    '" rx="',
                    rx.toString(),
                    '" ry="',
                    ry.toString(),
                    '" fill="',
                    GENERAL_COLORS[fill],
                    '" stroke="',
                    GENERAL_COLORS[stroke],
                    '"/>'
                )
            );
    }

    function _poopRect(
        uint8 x,
        uint8 y,
        uint8 rx,
        uint8 width,
        uint8 height,
        uint8 fill
    ) private view returns (string memory) {
        return _poopRect(x, y, rx, width, height, fill, 21);
    }

    function _poopRect(
        uint8 x,
        uint8 y,
        uint8 rx,
        uint8 width,
        uint8 height,
        uint8 fill,
        uint8 stroke
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    x.toString(),
                    '" y="',
                    y.toString(),
                    '" rx="',
                    rx.toString(),
                    '" width="',
                    width.toString(),
                    '" height="',
                    height.toString(),
                    '" fill="',
                    GENERAL_COLORS[fill],
                    '" stroke="',
                    GENERAL_COLORS[stroke],
                    '"/>"'
                )
            );
    }

    function _poopCircle(
        uint8 x,
        uint8 y,
        uint8 r,
        uint8 fill
    ) private view returns (string memory) {
        return _poopCircle(x, y, r, fill, 21);
    }

    function _poopCircle(
        uint8 x,
        uint8 y,
        uint8 r,
        uint8 fill,
        uint8 stroke
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle cx="',
                    x.toString(),
                    '" cy="',
                    y.toString(),
                    '" r="',
                    r.toString(),
                    '" fill="',
                    GENERAL_COLORS[fill],
                    '" stroke="',
                    GENERAL_COLORS[stroke],
                    '" />'
                )
            );
    }

    function poopAttributes(Poop memory p) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type":"Background","value":"',
                    backgroundAttr[p.background],
                    '"},{"trait_type":"Hair","value":"',
                    hairAttr[p.hair],
                    '"},{"trait_type":"Head","value":"',
                    headAttr[p.head],
                    '"},{"trait_type":"Bottom","value":"',
                    bottomAttr[p.bottom],
                    '"},{"trait_type":"Eyes","value":"',
                    eyesAttr[p.eyes],
                    '"},{"trait_type":"Mouth","value":"',
                    mouthAttr[p.mouth],
                    '"},{"trait_type":"Generation","value":"',
                    generationAttr[p.generation],
                    '"},{"trait_type":"Shit","value":"',
                    shitAttr[p.shit],
                    '"}]'
                )
            );
    }

    function purePoop(uint256 quantity, address receiver) external onlyOwner {
        require(quantity + totalSupply() <= collectionSize, "no more poop");
        _safeMint(receiver, quantity);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (address(this), (salePrice * 7) / 100);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "no tips");
    }

    receive() external payable {}
}