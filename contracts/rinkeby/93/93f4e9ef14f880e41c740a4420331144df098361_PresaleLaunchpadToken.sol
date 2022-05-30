/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

library AddressUpgradeablePre {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

abstract contract InitializablePre {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeablePre.isContract(address(this));
    }
}

library StringsPre {
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// context.sol
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
abstract contract ContextPre {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//Address.sol
/**
 * @dev Collection of functions related to the address type
 */
library AddressPre {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Pre {
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

//erc165.sol
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
abstract contract ERC165Pre is IERC165Pre {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Pre).interfaceId;
    }
}

// IERC721.SOL
//IERC721

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721PRESALE is IERC165Pre {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// IERC721Enumerable.sol

interface IERC721EnumerablePre is IERC721PRESALE {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataPre is IERC721PRESALE {
    // /**
    //  * @dev Returns the token collection name.
    //  */
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

// IERC721Reciver.sol
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverPre {
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

error ApprovalCallerNotOwnerNorApprovedd();
error ApprovalQueryForNonexistentTokenn();
error ApproveToCallerr();
error ApprovalToCurrentOwnerr();
error BalanceQueryForZeroAddresss();
error MintedQueryForZeroAddresss();
error MintToZeroAddresss();
error MintZeroQuantityy();
error OwnerIndexOutOfBoundss();
error OwnerQueryForNonexistentTokenn();
error TokenIndexOutOfBoundss();
error TransferCallerNotOwnerNorApprovedd();
error TransferFromIncorrectOwnerr();
error TransferToNonERC721ReceiverImplementerr();
error TransferToZeroAddresss();
error UnableDetermineTokenOwnerr();
error URIQueryForNonexistentTokenn();

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

// contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
abstract contract OwnablePre is ContextPre {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract ERC721AA is
    ContextPre,
    ERC165Pre,
    IERC721PRESALE,
    IERC721MetadataPre,
    IERC721EnumerablePre,
    InitializablePre,
    OwnablePre
{
    using AddressPre for address;
    using StringsPre for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal _currentIndex;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    //     // Token name
    // string private _name;

    // // Token symbol
    // string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // constructor(string memory name_, string memory symbol_) {
    //     _name = name_;
    //     _symbol = symbol_;
    // }

    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index >= totalSupply()) revert TokenIndexOutOfBoundss();
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256 a)
    {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBoundss();
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

        // Execution should never reach this point.
        assert(false);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Pre, IERC165Pre)
        returns (bool)
    {
        return
            interfaceId == type(IERC721PRESALE).interfaceId ||
            interfaceId == type(IERC721MetadataPre).interfaceId ||
            interfaceId == type(IERC721EnumerablePre).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddresss();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddresss();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentTokenn();

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert UnableDetermineTokenOwnerr();
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
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentTokenn();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
        address owner = ERC721AA.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwnerr();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ApprovalCallerNotOwnerNorApprovedd();

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentTokenn();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if (operator == _msgSender()) revert ApproveToCallerr();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        if (!_checkOnERC721Received(from, to, tokenId, _data))
            revert TransferToNonERC721ReceiverImplementerr();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex;
    }

    // function _safeMint(address to, uint256 quantity) public {
    //     _safeMint(to, quantity, '');
    // }

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
    // function _safeMint(
    //     address to,
    //     uint256 quantity,
    //     bytes memory _data
    // ) internal {
    //     _mint(to, quantity);
    // }

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
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddresss();
        // if (quantity == 0) revert MintZeroQuantity();

        //_beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                // if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                //     revert TransferToNonERC721ReceiverImplementer();
                // }

                updatedIndex++;
            }

            _currentIndex = updatedIndex;
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
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApprovedd();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwnerr();
        if (to == address(0)) revert TransferToZeroAddresss();

        // _beforeTokenTransfers(from, to, tokenId, 1);

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
                    _ownerships[nextTokenId].startTimestamp = prevOwnership
                        .startTimestamp;
                }
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
            try
                IERC721ReceiverPre(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721ReceiverPre(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0)
                    revert TransferToNonERC721ReceiverImplementerr();
                else {
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

library MerkleProoff {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
//     using AddressUpgradeable for address;
//     using StringsUpgradeable for uint256;

// // Token name
// string private _name;

// // Token symbol
// string private _symbol;

//     // Mapping from token ID to owner address
//     mapping(uint256 => address) private _owners;

//     // Mapping owner address to token count
//     mapping(address => uint256) private _balances;

//     // Mapping from token ID to approved address
//     mapping(uint256 => address) private _tokenApprovals;

//     // Mapping from owner to operator approvals
//     mapping(address => mapping(address => bool)) private _operatorApprovals;

//     /**
//      * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
// //      */
//     function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
//         __ERC721_init_unchained(name_, symbol_);
//     }

//     function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
//         _name = name_;
//         _symbol = symbol_;
//     }

//     /**
//      * @dev See {IERC165-supportsInterface}.
//      */
//     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
//         return
//             interfaceId == type(IERC721Upgradeable).interfaceId ||
//             interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
//             super.supportsInterface(interfaceId);
//     }

//     /**
//      * @dev See {IERC721-balanceOf}.
//      */
//     function balanceOf(address owner) public view virtual override returns (uint256) {
//         require(owner != address(0), "ERC721: balance query for the zero address");
//         return _balances[owner];
//     }

//     /**
//      * @dev See {IERC721-ownerOf}.
//      */
//     function ownerOf(uint256 tokenId) public view virtual override returns (address) {
//         address owner = _owners[tokenId];
//         require(owner != address(0), "ERC721: owner query for nonexistent token");
//         return owner;
//     }

//     /**
//      * @dev See {IERC721Metadata-name}.
//      */
//     function name() public view virtual override returns (string memory) {
//         return _name;
//     }

//     /**
//      * @dev See {IERC721Metadata-symbol}.
//      */
//     function symbol() public view virtual override returns (string memory) {
//         return _symbol;
//     }

//     /**
//      * @dev See {IERC721Metadata-tokenURI}.
//      */
//     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
//         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

//         string memory baseURI = _baseURI();
//         return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
//     }

//     /**
//      * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
//      * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
//      * by default, can be overriden in child contracts.
//      */
//     function _baseURI() internal view virtual returns (string memory) {
//         return "";
//     }

//     /**
//      * @dev See {IERC721-approve}.
//      */
//     function approve(address to, uint256 tokenId) public virtual override {
//         address owner = ERC721Upgradeable.ownerOf(tokenId);
//         require(to != owner, "ERC721: approval to current owner");

//         require(
//             _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
//             "ERC721: approve caller is not owner nor approved for all"
//         );

//         _approve(to, tokenId);
//     }

//     /**
//      * @dev See {IERC721-getApproved}.
//      */
//     function getApproved(uint256 tokenId) public view virtual override returns (address) {
//         require(_exists(tokenId), "ERC721: approved query for nonexistent token");

//         return _tokenApprovals[tokenId];
//     }

//     /**
//      * @dev See {IERC721-setApprovalForAll}.
//      */
//     function setApprovalForAll(address operator, bool approved) public virtual override {
//         _setApprovalForAll(_msgSender(), operator, approved);
//     }

//     /**
//      * @dev See {IERC721-isApprovedForAll}.
//      */
//     function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
//         return _operatorApprovals[owner][operator];
//     }

//     /**
//      * @dev See {IERC721-transferFrom}.
//      */
//     function transferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) public virtual override {
//         //solhint-disable-next-line max-line-length
//         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

//         _transfer(from, to, tokenId);
//     }

//     /**
//      * @dev See {IERC721-safeTransferFrom}.
//      */
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) public virtual override {
//         safeTransferFrom(from, to, tokenId, "");
//     }

//     /**
//      * @dev See {IERC721-safeTransferFrom}.
//      */
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes memory _data
//     ) public virtual override {
//         require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
//         _safeTransfer(from, to, tokenId, _data);
//     }

//     /**
//      * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
//      * are aware of the ERC721 protocol to prevent tokens from being forever locked.
//      *
//      * `_data` is additional data, it has no specified format and it is sent in call to `to`.
//      *
//      * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
//      * implement alternative mechanisms to perform token transfer, such as signature-based.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `to` cannot be the zero address.
//      * - `tokenId` token must exist and be owned by `from`.
//      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
//      *
//      * Emits a {Transfer} event.
//      */
//     function _safeTransfer(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes memory _data
//     ) internal virtual {
//         _transfer(from, to, tokenId);
//         require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
//     }

//     /**
//      * @dev Returns whether `tokenId` exists.
//      *
//      * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
//      *
//      * Tokens start existing when they are minted (`_mint`),
//      * and stop existing when they are burned (`_burn`).
//      */
//     function _exists(uint256 tokenId) internal view virtual returns (bool) {
//         return _owners[tokenId] != address(0);
//     }

//     /**
//      * @dev Returns whether `spender` is allowed to manage `tokenId`.
//      *
//      * Requirements:
//      *
//      * - `tokenId` must exist.
//      */
//     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
//         require(_exists(tokenId), "ERC721: operator query for nonexistent token");
//         address owner = ERC721Upgradeable.ownerOf(tokenId);
//         return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
//     }

//     /**
//      * @dev Safely mints `tokenId` and transfers it to `to`.
//      *
//      * Requirements:
//      *
//      * - `tokenId` must not exist.
//      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
//      *
//      * Emits a {Transfer} event.
//      */
//     function _safeMint(address to, uint256 tokenId) internal virtual {
//         _safeMint(to, tokenId, "");
//     }

//     /**
//      * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
//      * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
//      */
//     function _safeMint(
//         address to,
//         uint256 tokenId,
//         bytes memory _data
//     ) internal virtual {
//         _mint(to, tokenId);
//         require(
//             _checkOnERC721Received(address(0), to, tokenId, _data),
//             "ERC721: transfer to non ERC721Receiver implementer"
//         );
//     }

//     /**
//      * @dev Mints `tokenId` and transfers it to `to`.
//      *
//      * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
//      *
//      * Requirements:
//      *
//      * - `tokenId` must not exist.
//      * - `to` cannot be the zero address.
//      *
//      * Emits a {Transfer} event.
//      */
//     function _mint(address to, uint256 tokenId) internal virtual {
//         require(to != address(0), "ERC721: mint to the zero address");
//         require(!_exists(tokenId), "ERC721: token already minted");

//         _beforeTokenTransfer(address(0), to, tokenId);

//         _balances[to] += 1;
//         _owners[tokenId] = to;

//         emit Transfer(address(0), to, tokenId);

//         _afterTokenTransfer(address(0), to, tokenId);
//     }

//     /**
//      * @dev Destroys `tokenId`.
//      * The approval is cleared when the token is burned.
//      *
//      * Requirements:
//      *
//      * - `tokenId` must exist.
//      *
//      * Emits a {Transfer} event.
//      */
//     function _burn(uint256 tokenId) internal virtual {
//         address owner = ERC721Upgradeable.ownerOf(tokenId);

//         _beforeTokenTransfer(owner, address(0), tokenId);

//         // Clear approvals
//         _approve(address(0), tokenId);

//         _balances[owner] -= 1;
//         delete _owners[tokenId];

//         emit Transfer(owner, address(0), tokenId);

//         _afterTokenTransfer(owner, address(0), tokenId);
//     }

//     /**
//      * @dev Transfers `tokenId` from `from` to `to`.
//      *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      * - `tokenId` token must be owned by `from`.
//      *
//      * Emits a {Transfer} event.
//      */
//     function _transfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal virtual {
//         require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
//         require(to != address(0), "ERC721: transfer to the zero address");

//         _beforeTokenTransfer(from, to, tokenId);

//         // Clear approvals from the previous owner
//         _approve(address(0), tokenId);

//         _balances[from] -= 1;
//         _balances[to] += 1;
//         _owners[tokenId] = to;

//         emit Transfer(from, to, tokenId);

//         _afterTokenTransfer(from, to, tokenId);
//     }

//     /**
//      * @dev Approve `to` to operate on `tokenId`
//      *
//      * Emits a {Approval} event.
//      */
//     function _approve(address to, uint256 tokenId) internal virtual {
//         _tokenApprovals[tokenId] = to;
//         emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
//     }

//     /**
//      * @dev Approve `operator` to operate on all of `owner` tokens
//      *
//      * Emits a {ApprovalForAll} event.
//      */
//     function _setApprovalForAll(
//         address owner,
//         address operator,
//         bool approved
//     ) internal virtual {
//         require(owner != operator, "ERC721: approve to caller");
//         _operatorApprovals[owner][operator] = approved;
//         emit ApprovalForAll(owner, operator, approved);
//     }

//     /**
//      * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
//      * The call is not executed if the target address is not a contract.
//      *
//      * @param from address representing the previous owner of the given token ID
//      * @param to target address that will receive the tokens
//      * @param tokenId uint256 ID of the token to be transferred
//      * @param _data bytes optional data to send along with the call
//      * @return bool whether the call correctly returned the expected magic value
//      */
//     function _checkOnERC721Received(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes memory _data
//     ) private returns (bool) {
//         if (to.isContract()) {
//             try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
//                 return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
//             } catch (bytes memory reason) {
//                 if (reason.length == 0) {
//                     revert("ERC721: transfer to non ERC721Receiver implementer");
//                 } else {
//                     assembly {
//                         revert(add(32, reason), mload(reason))
//                     }
//                 }
//             }
//         } else {
//             return true;
//         }
//     }

//     /**
//      * @dev Hook that is called before any token transfer. This includes minting
//      * and burning.
//      *
//      * Calling conditions:
//      *
//      * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
//      * transferred to `to`.
//      * - When `from` is zero, `tokenId` will be minted for `to`.
//      * - When `to` is zero, ``from``'s `tokenId` will be burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal virtual {}

//     /**
//      * @dev Hook that is called after any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _afterTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal virtual {}

//     /**
//      * @dev This empty reserved space is put in place to allow future versions to add new
//      * variables without shifting down storage in the inheritance chain.
//      * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
//      */
//     uint256[44] private __gap;
// }

contract PresaleLaunchpadToken is ERC721AA {

    address payable wallet =
        payable(0xc2c7d10B99bf936EffD3cFDD4f5e5f6A6acDDCd3);


    struct userAddress {
    address userAddress;
    uint256 counter;}
    
    mapping(address => userAddress) public _preSaleAddresses;
    mapping(address => bool)        public _preSaleAddressExist;

    string    private    _name;
    string    private    _symbol;
    string    public     baseuri;

    uint256   public     maxSupply;
    uint256   public     reserve;
    uint256   public     price;
    uint256   public     preSaleSupply;
    uint256   public     presalePrice;
    uint256   public     maxPerWallet;
    uint256   public     maxPerTrans;
    uint      public     counter=0;

    bool      public     isSalepaused = true;
    bool      public     isPresalepPaused = true;
    bytes32   private    _root;


            
    function setbaseuri(string memory _newnBaseUri) public onlyOwner {
        baseuri = _newnBaseUri;}
    
    function setmaxSupply(uint256 _quantity) public onlyOwner {
        maxSupply = _quantity;}
    
    function setReserveTokens(uint256 _quantity) public onlyOwner {
        reserve = _quantity;}
    
    function setPrice(uint256 _quantity) public onlyOwner {
        price = _quantity;}
    
    function setPreSalesupply(uint256 _quantity) public onlyOwner {
        presalePrice = _quantity;}
    
    function setPreSalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;}
    
    function setperWallet(uint256 _quantity) public onlyOwner {
        maxPerWallet = _quantity;}
    
    function setMaxxQtPerTx(uint256 _quantity) public onlyOwner {
        maxPerTrans = _quantity;}

    function name() public view override returns (string memory) {
        return _name;}

    function symbol() public view override returns (string memory) {
        return _symbol;}

    function _baseURI() internal view override returns (string memory) {
        return baseuri;}

    function flipPauseStatus() public onlyOwner {
        isSalepaused = !isSalepaused;}
    
    function flipPreSalePauseStatus() public onlyOwner {
        isPresalepPaused = !isPresalepPaused;}


    function initialize(address a) public initializer {
        __ERC721_init(_name, _symbol);
        _transferOwnership(a);}
    

    function mint(uint256 quantity) public payable {
        require(quantity > 0, "zero not allowedaa");
        require(quantity <= maxPerTrans, "Chosen Amount exceeds MaxQuantity");
        require(quantity + totalSupply() <= maxSupply - reserve,"public sale end");
        require(price * quantity == msg.value, "Sent ether value is incorrect");
        _mint(msg.sender, quantity);
    }

    function preSalemint(bytes32[] calldata _merkleProof, uint256 quantity)
        public
        payable
    {
        if (_preSaleAddressExist[msg.sender] == false) {
            _preSaleAddresses[msg.sender] = userAddress({
                userAddress: msg.sender,
                counter: 0
            });
            _preSaleAddressExist[msg.sender] = true;
        }

        require(isPresalepPaused == false, "Sale is not active at the moment");
        require(quantity <= maxPerTrans, "Chosen Amount exceeds MaxQuantity");
        require(
            totalSupply() + quantity <= preSaleSupply,
            "Quantity is greater than remaining Supply"
        );
        require(
            _preSaleAddresses[msg.sender].counter + quantity <= maxPerWallet,
            "Quantity Must Be Lesser Than Max Supply"
        );

        require(
            presalePrice * quantity == msg.value,
            "Sent Ether Value Is Incorrect"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProoff.verify(_merkleProof, _root, leaf), "Invalid Proof");
        _mint(msg.sender, quantity);
        _preSaleAddresses[msg.sender].counter += quantity;
    }

    function MintreserveTokens(uint256 quantity) public onlyOwner {
        require(quantity <= reserve, "The quantity exceeds the reserve.");
        reserve -= quantity;
        _mint(msg.sender, quantity);
    }
    
    function tokensOfOwner(address _owner)public view returns (uint256[] memory) {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }


        function contractDetails(
        
        string memory namee,
        string memory symboll,
        uint256 maxSupplyy,
        uint256 preSaleSupplyy,
        uint256 maxPerTranss,
        uint256 reservee,
        uint256 pricee,
        uint256 presalePricee,
        string memory baseurii,
        uint256 maxPerWallett,
        bytes32 root
    ) public  {
        if(counter>=1)
        {  require(msg.sender==owner());}
       _name            = namee;
       _symbol          = symboll;
        maxSupply       = maxSupplyy;
        preSaleSupply   = preSaleSupplyy;
        maxPerTrans     = maxPerTranss;
        reserve         = reservee;
        price           = pricee;
        presalePrice    = presalePricee;
        baseuri         = baseurii;
        maxPerWallet    = maxPerWallett;
        _root           = root;
        counter++;
    }


    function withdraw() public onlyOwner {
        uint256 totalbalance=address(this).balance;
        uint256 NCU=totalbalance*5/100;
        uint256 OwnerCUT=totalbalance-NCU;

        (bool hq,) = payable(owner()).call{value: OwnerCUT}("");
        (bool h, ) = payable(wallet ).call{value: NCU}     ("");
        
        require(hq);
        require(h);
    }

}