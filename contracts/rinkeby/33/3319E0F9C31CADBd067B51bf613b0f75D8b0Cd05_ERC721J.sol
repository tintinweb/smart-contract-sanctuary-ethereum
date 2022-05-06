// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MaxCopiesReached();
error MintToZeroAddress();
error NotEnoughEther();
error OwnerIndexOutOfBounds();
error OwnerIsOperator();
error OwnerQueryForNonexistentToken();
error QueryForNonexistentToken();
error SenderNotOwner();
error TokenAlreadyMinted();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();
error URISetOfNonexistentSong();

//
//Version 1.1 of ERC721J
//
//Supports 1/1 original turning into 100.
//Minting a copy requires the owner to own a copy.
//
//
//New in 1.1: added contractURI. Renamed mintNewSong to mintOriginal. Renamed mintCopySong to mintCopy.
//
//More features coming in v2! Stay tuned!
//
contract ERC721J is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable,
    Ownable
{
    using Address for address;
    using Strings for uint256;
    // _tokenIds and _songIds for keeping track of the ongoing total tokenids, and total songids
    uint256 private _tokenIds;
    uint256 private _songIds;

    // Token name
    string private _name = "ERC721J";

    // Token symbol
    string private _symbol = "721J";

    //Define the baseURI
    string _baseURI = "https://arweave.net/";

    //Define Contract URI
    string _contractURI;

    struct tokenInfo {
        uint128 song;
        uint128 serial;
    }

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping for song URIs. Takes songId then songEdition into a string.
    mapping(uint256 => string) private _songURIs;
    // Mapping for the counters of songs minted for each song
    mapping(uint256 => uint256) private _songSerials;
    // Mapping for the extra info to each tokenId
    mapping(uint256 => tokenInfo) private _tokenIdInfo;

    // Mapping for the max songs. Takes songId then max amount of editions for that song.
    mapping(uint256 => uint256) private _maxEditions;

    //from erc721enumerable
    //
    //function returns the total supply of tokens minted by the contract
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIds;
    }

    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index > _tokenIds) revert TokenIndexOutOfBounds();
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index > balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _tokenIds;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        unchecked {
            for (uint256 i; i <= numMintedSoFar; i++) {
                address ownership = _owners[i];
                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
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
        assert(false);
        return 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert OwnerQueryForNonexistentToken();
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    //
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = serialOfToken(tokenId);
        string memory _tokenURI;
        // Shows different uri depending on serial number
        if (songSerial < 2) {
            _tokenURI = _songURIs[(songId * 3) - 2];
        } else if (songSerial < 11) {
            _tokenURI = _songURIs[(songId * 3) - 1];
        } else {
            _tokenURI = _songURIs[songId * 3];
        }
        // Set baseURI
        string memory base = baseURI();
        // Concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        } else {
            return "";
        }
    }

    //
    //
    //URI Section
    //
    //

    //Returns baseURI internally
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    //sets the baseURI
    function setBaseURI(string memory base) public virtual onlyOwner {
        _baseURI = base;
    }

    //Returns contractURI internally
    function contractURI() public view virtual returns (string memory) {
        // Set baseURI
        string memory base = baseURI();
        // Concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_contractURI).length > 0) {
            return string(abi.encodePacked(base, _contractURI));
        } else {
            return "";
        }
    }

    //sets the contractURI
    function setContractURI(string memory uri) public virtual onlyOwner {
        _contractURI = uri;
    }

    //sets the songURIs when minting a new song
    function _setSongURI(
        uint256 songId,
        string memory songURI1,
        string memory songURI2,
        string memory songURI3
    ) internal virtual {
        if (!_exists(songId)) revert URISetOfNonexistentSong();
        _songURIs[(songId * 3) - 2] = songURI1;
        _songURIs[(songId * 3) - 1] = songURI2;
        _songURIs[songId * 3] = songURI3;
    }

    //Changes the songURI for one edition of a song, when given the songId and songEdition
    function changeSongURI(
        uint256 songId,
        uint256 songEdition,
        string memory songURI
    ) public virtual onlyOwner {
        if (!_exists(songId)) revert URISetOfNonexistentSong();

        if (songEdition == 1) {
            _songURIs[(songId * 3) - 2] = songURI;
        } else if (songEdition == 2) {
            _songURIs[(songId * 3) - 1] = songURI;
        } else if (songEdition == 3) {
            _songURIs[songId * 3] = songURI;
        }
    }

    //
    //ERC721 Meat and Potatoes Section
    //

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    //
    //Transfer Section
    //
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert TransferCallerNotOwnerNorApproved();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert TransferCallerNotOwnerNorApproved();
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    //
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    //
    //Minting Section!
    //

    uint256 mintPrice = 50000000000000000;

    function mintOriginal(
        string memory songURI1,
        string memory songURI2,
        string memory songURI3,
        uint256 maxEditions
    ) public onlyOwner {
        // Updates the count of total tokenids and songids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;
        uint256 songId = _songIds;
        songId++;
        _songIds = songId;

        // Updates the count of how many of a particular song have been made
        uint256 songSerial = _songSerials[songId];
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or serial of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].serial = uint128(songSerial);

        _maxEditions[songId] = maxEditions;

        _safeMint(msg.sender, id);
        _setSongURI(songId, songURI1, songURI2, songURI3);
    }

    function ownerMintsCopy(uint256 tokenId, address to) public onlyOwner {
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender) revert SenderNotOwner();
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        _safeMintCopy(ownerOf(tokenId), to, id);

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or serial# of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].serial = uint128(songSerial);
    }

    function mintCopyTo(uint256 tokenId, address to) public payable {
        //requires eth
        if (msg.value < mintPrice ) revert NotEnoughEther();
        //requires the sender to have the tokenId in their walle
        if (ownerOf(tokenId) != msg.sender) revert SenderNotOwner();
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        _safeMintCopy(ownerOf(tokenId), to, id);

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or serial# of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].serial = uint128(songSerial);
    }

    function mintCopy(uint256 tokenId) public payable {
        //requires eth
        if (msg.value < mintPrice ) revert NotEnoughEther();
        //requires the sender to have the tokenId in their wallet
        if (ownerOf(tokenId) != msg.sender) revert SenderNotOwner();
        //Gets the songId from the tokenId
        uint256 songId = songOfToken(tokenId);
        uint256 songSerial = _songSerials[songId];
        //requires the current amount of copies that song to be less than what's set
        if (songSerial >= _maxEditions[songId]) revert MaxCopiesReached();

        // Updates the count of total tokenids
        uint256 id = _tokenIds;
        id++;
        _tokenIds = id;

        _safeMintCopy(ownerOf(tokenId), msg.sender, id);
        

        //Updates the count of how many of a particular song have been made
        songSerial++;
        _songSerials[songId] = songSerial;
        //makes it easy to look up the song or serial# of a tokenid
        _tokenIdInfo[id].song = uint128(songId);
        _tokenIdInfo[id].serial = uint128(songSerial);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMintCopy(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeMintCopy(from, to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _safeMintCopy(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mintCopy(from, to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId)) revert TokenAlreadyMinted();

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }


    function _mintCopy(address from, address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId)) revert TokenAlreadyMinted();

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    //
    //More ERC721 Functions Meat and Potatoes style Section
    //

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) revert OwnerIsOperator();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    //
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    //
    //Other Functions Section
    //

    //function returns how many different songs have been created
    function amountOfSongs() public view virtual returns (uint256) {
        return _songIds;
    }

    //function returns what song a certain tokenid is
    function songOfToken(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdInfo[tokenId].song;
    }

    //function returns what serial number a certain tokenid is
    function serialOfToken(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _tokenIdInfo[tokenId].serial;
    }

    //function returns how many of a song are minted
    function songSupply(uint256 songId) public view virtual returns (uint256) {
        return _songSerials[songId];
    }

    //returns a songURI, when given the songId and songEdition
    function getSongURI(uint256 songId, uint256 songEdition)
        public
        view
        virtual
        returns (string memory)
    {
        if (!_exists(songId)) revert URIQueryForNonexistentToken();
        string memory _songURI;
        if (songEdition == 1) {
            _songURI = _songURIs[(songId * 3) - 2];
        } else if (songEdition == 2) {
            _songURI = _songURIs[(songId * 3) - 1];
        } else if (songEdition == 3) {
            _songURI = _songURIs[songId * 3];
        }
        string memory base = baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, _songURI))
                : "";
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        // Payable address can receive Ether
        address payable owner;
        owner = payable(msg.sender);
        // send all Ether to owner
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}