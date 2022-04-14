/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8;

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)



// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
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
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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
        return !AddressUpgradeable.isContract(address(this));
    }
}
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)






/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



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
interface IERC165Upgradeable {
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
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)





/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}
/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)



/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @dev
/// A `Pool` refers to the different "pools" users can lock their CNV into.
///
/// When a user locks into a `Pool`, their CNV cannot be withdrawn for a duration
/// of `term` seconds. The amount a user locks determines the amount of shares
/// they get of this `Pool`. This amount of shares is calculated by:
///
/// shares = amount * (pool.balance / pool.supply)
///
/// The pool `balance` is then increased by the amount locked, and the pool
/// `supply` is increased by the amount of shares.
///
/// On each rebase the percent change in CNV since last rebase is calculated,
/// and `g` determines how much of that percent change will be assigned to the
/// Pool. For example - if CNV supply increased by 10%, and `g` for a specific
/// pool is g=100%, then that pool will obtain a 10% increase in supply. These
/// are referred to as "anti-dilutive rewards". This increase in supply is
/// reflected by increasing the `balance` of the pool.
///
/// Additionally, on each rebase there are "excess rewards" given to each pool.
/// The amount of excess rewards each pool gets is determined by `excessRatio`,
/// and unlike "anti-dilutive rewards" these rewards are reflected by increasing
/// the `rewardsPerShare`.
///
/// When users unlock, the amount of shares they own is converted to an amount
/// of CNV:
///
/// amount = shares / (pool.balance / pool.supply)
///
/// this amount is then reduced from pool.balance, and the shares are reduced
/// from pool.supply.
struct Pool {
    uint64  term;                   // length in seconds a user must lock
    uint256 g;                      // pct of CNV supply growth to be matched to this pool on each rebase
    uint256 excessRatio;            // ratio of excess rewards for this pool on each rebase
    uint256 balance;                // balance of CNV locked (amount locked + anti-dilutive rewards)
    uint256 supply;                 // supply of shares of this pool assigned to users when they lock
    uint256 rewardsPerShare;        // index of excess rewards for each share
}

/// @dev
/// A `Position` refers to a users "position" when they lock into a Pool.
///
/// When a user locks into a Pool, they obtain a `Position` which contains the
/// `maturity` which is used to check when they can unlock their CNV, a `poolID`
/// which is used to then convert the amount of `shares` they own of that pool
/// into CNV, `shares` which is the number of shares they own of that pool to be
/// later converted into CNV, and `rewardDebt` which reflects the index of
/// pool rewardsPerShare at the time they entered the pool. This value is used
/// so that when they unlock, they only get the difference of current rewardsPerShare
/// and `rewardDebt`, thus only getting excess rewards for the time they were in
/// the pool and not for rewards distrobuted before they entered the Pool.
struct Position {
    uint32  poolID;                  // ID of pool to which position belongs to
    uint224 shares;                  // amount of pool shares assigned to this position
    uint32  maturity;                // timestamp when lock position can be unlocked
    uint224 rewardDebt;              // index of rewardsPerShare at time of entering pool
}

contract StakingStorageV1 {

    /// @notice address of CNV ERC20 token, used to mint CNV rewards to this contract.
    address public CNV;

    /// @notice address of Bonding contract, used to retrieve information regarding
    /// bonding activity in a given rebase interval.
    address public BONDS;

    /// @notice address of COOP to send COOP funds to.
    address public COOP;

    /// @notice address of `ValueShuttle` contract. When Bonding occurs on
    /// `Bonding` contract, it sends all incoming bonded value to `VALUESHUTTLE`.
    /// Then during rebase, this contract calls `VALUESHUTTLE` to obtain
    /// the USD denominated value of bonding activity during rebase and instructs
    /// `ValueShuttle` to empty the funds to the Treasury.
    address public VALUESHUTTLE;

    /// @notice address of contract in charge of displaying lock position NFT
    address public URI_ADDRESS;

    /// @notice array containing pool info
    Pool[] public pools;

    /// @notice time in seconds that must pass before next rebase
    uint256 public rebaseInterval;

    /// @notice as an incentive for the public to call the "rebase()" method, and
    /// to not increase the gas of lock() and unlock() methods by including rebase
    /// in those methods, a rebase incentive is provided. This is an amount of CNV
    /// that will be transferred to callers of the "rebase()" method.
    uint256 public rebaseIncentive;

    /// @notice pct of CNV supply to be rewarded as excess rewards.
    /// @dev
    /// During each rebase, after anti-dilution rewards have been assigned, an
    /// additional "excess rewards" are distributed. The total amount of excess
    /// rewards to be distributed among all pools is given as a percentage of
    /// total CNV supply. For example - if apyPerRebase = 10%, then 10% of total
    /// CNV supply will be distributed to pools as "excess rewards".
    uint256 public apyPerRebase;

    /// @notice amount of CNV available to mint without breaking backing.
    /// @dev
    /// During Bonding activity, by design there is more value being received
    /// than CNV minted. This difference is accounted for in `globalExcess`.
    /// For example, if during bonding activity $100 has been accumulated and
    /// 70 CNV has been minted (for bonders, DAO, and anti-dilution rewards),
    /// then `globalExcess` will be increased by 30.
    ///
    /// This number also determines the availability of "excess rewards" as
    /// determined by `apyPerRebase`. For example - if a current rebase only
    /// produced an excess of 10 CNV, and `apyPerRebase` indicates that 20 CNV
    /// should be distributed, and `globalExcess` is 30, then rebasing will
    /// use from `globalExcess` to distribute those rewards and thus reduce
    /// globalExcess to 20.
    /// For this same logic - this numbers serves as a floor on excess rewards
    /// to prevent the protocol from minting more CNV than there is value in
    /// the Treasury.
    uint256 public globalExcess;

    //////////////////////////////

    /// @dev
    /// used to calculate the amount of CNV during each rebase that goes to COOP.
    /// see _calculateCOOPRate
    uint256 public coopRatePriceControl;

    /// @dev
    /// used to calculate the amount of CNV during each rebase that goes to COOP.
    /// see _calculateCOOPRate
    uint256 public haogegeControl;

    /// @dev
    /// used to calculate the amount of CNV during each rebase that goes to COOP.
    /// see _calculateCOOPRate
    uint256 public coopRateMax;

    /// @notice minimum CNV bond price denominated in USD (wad)
    /// used to calculate staking cap during _lock()
    uint256 public minPrice;

    /// @notice time of last rebase, used to determine whether a rebase is due.
    uint256 public lastRebaseTime;

    /// @notice supply of lock position NFTs, used for positionID
    uint256 public totalSupply;

    /// @notice mapping that returns position info for a given NFT
    mapping(uint256 => Position) public positions;
}

interface IBonding {
    function vebase() external returns (bool);
    function cnvEmitted() external view returns(uint256);
    function getAvailableSupply() external view returns(uint256);
}

interface ICNV is IERC20, IERC20Permit {
    function mint(address guy, uint256 input) external;
}

interface IValueShuttle {
    function shuttleValue() external returns(uint256);
}

interface IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// TODO: Dio
// 1. replace AccessControl_TEMP with Concave Access Control
// 2. BONDING circulating supply method [ circulatingSupply()(uint256) ]
// 3. Fractionalization support

/// NOTE CONVEX PLZ CHECK ./test/utils/opinions.md for opinions
/// IDEA replace loops with hardcoded logic, since we can upgrade

/// F9 - Are the correct modifiers applied, such as onlyOwner/requiresAuth?
/// C25 - Are magic numbers replaced by a constant with an intuitive name?
/// C50 - Use ternary expressions to simplify branching logic wherever possible.
/// T2 - Are events emitted for every storage mutating function?

/// calculateCOOPRate/lock/rebase walkthru

/// @dev removed pool.open
contract StakingV1 is StakingStorageV1, Initializable, OwnableUpgradeable, PausableUpgradeable, ERC721Upgradeable {

    using FixedPointMathLib for uint256;

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice             emitted when a user locks
    /// @param _amount      amount of CNV locked
    /// @param _poolID      ID of the pool locked into
    /// @param _sender      address of sender
    event Lock(
        uint256 indexed _amount,
        uint256 indexed _poolID,
        address indexed _sender
    );

    /// @notice             emitted when a user unlocks
    /// @param _amount      amount of CNV unlocked (principal + anti-dilutive + excess)
    /// @param _poolID      ID of the pool locked into
    /// @param _owner       address of NFT owner
    event Unlock(
        uint256 indexed _amount,
        uint256 indexed _poolID,
        address indexed _owner
    );

    /// @notice             emitted when a rebase occurs
    /// @param eStakers     emissions for stakes (anti-dilutive + excess)
    /// @param eCOOP        emissions for COOP
    /// @param CNVS         CNV supply used for anti-dilution calculation
    event Rebase(
        uint256 indexed eStakers,
        uint256 indexed eCOOP,
        uint256 indexed CNVS
    );

    /// @notice                     emitted during rebase for each pool
    /// @param poolID               ID of pool
    /// @param baseObligation       anti-dilution rewards for pool
    /// @param excessObligation     excess rewards for pool
    /// @param balance              pool balance before rebase
    event PoolRewarded(
        uint256 indexed poolID,
        uint256 indexed baseObligation,
        uint256 indexed excessObligation,
        uint256 balance
    );


    // ADMIN MGMT EVENTS

    /// @notice                 emitted when MGMT creates a new pool
    /// @param _term            length of pool term in seconds
    /// @param _g               amount of CNV supply growth matched to pool
    /// @param _excessRatio     ratio to calculate excess rewards for this pool
    /// @param _poolID          ID of the pool
    event PoolOpened(
        uint64  indexed _term,
        uint256 indexed _g,
        uint256 indexed _excessRatio,
        uint256 _poolID
    );

    /// @notice                 emitted when MGMT manages a pool
    /// @param _term            length of pool term in seconds
    /// @param _g               amount of CNV supply growth matched to pool
    /// @param _excessRatio     ratio to calculate excess rewards for this pool
    /// @param _poolID          ID of the pool
    event PoolManaged(
        uint64 indexed  _term,
        uint256 indexed _g,
        uint256 indexed _excessRatio,
        uint256 _poolID
    );

    /// @notice                         emitted when MGMT manages COOP rate
    /// @param _coopRatePriceControl    used for COOP rate calc
    /// @param _haogegeControl          used for COOP rate calc
    /// @param _coopRateMax             used for COOP rate calc
    event CoopRateManaged(
        uint256 indexed _coopRatePriceControl,
        uint256 indexed _haogegeControl,
        uint256 indexed _coopRateMax
    );

    // ///
    // event AntiDilutiveMint(
    //     address indexed to,
    //     uint256 indexed amount,
    //     uint256 antiDilutionAmount
    // );
    event ExcessRewardsDistributed(
        uint256 indexed amountDistributed,
        uint256 indexed globalExcess
    );
    event RebaseAPYManaged(
        uint256 indexed apy
    );
    event RebaseIncentiveManaged(
        uint256 indexed rebaseIncentive
    );
    event RebaseIntervalManaged(
        uint256 indexed rebaseIncentive
    );
    event MinPriceManaged(
        uint256 indexed minPrice
    );
    event AddressManaged(
        uint8 indexed _what,
        address _address
    );

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    function initialize(
        address _CNV,
        address _COOP,
        address _BONDS,
        address _VALUESHUTTLE
    ) external virtual initializer {
        // NOTE ENSURE INIT CANNOT BE CALLED TWICE

        CNV = _CNV;
        COOP = _COOP;
        BONDS = _BONDS;
        VALUESHUTTLE = _VALUESHUTTLE;

        coopRatePriceControl = 50e18;
        haogegeControl = 69e15;
        haogegeControl = 42069e12;
        coopRateMax = 1e17;
        minPrice = 36e18;
        rebaseInterval = 28800;

        __Pausable_init();
        __Ownable_init(); // owner is msg.sender by default
        __ERC721_init("Vested CNV Note", "veCNV"); // feel free to change
        _pause();
    }

    /* -------------------------------------------------------------------------- */
    /*                              LOCK/UNLOCK LOGIC                             */
    /* -------------------------------------------------------------------------- */


    function lockWithPermit(
        address to,
        uint256 input,
        uint256 pid,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual whenNotPaused returns(uint256 tokenId) {
        // Approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        ICNV(CNV).permit(msg.sender, address(this), input, permitDeadline, v, r, s);

        tokenId = _lock(to,input,pid);
    }

    function lock(
        address to,
        uint256 input,
        uint256 pid
    ) external virtual whenNotPaused returns(uint256 tokenId) {
        tokenId = _lock(to,input,pid);
    }

    function unlock(
        address to,
        uint256 tokenId
    ) external virtual whenNotPaused returns (uint256 amountOut) {
        // F6: CHECKS

        // Check that caller is owner of position to be unlocked
        require(ownerOf(tokenId) == msg.sender, "!OWNER");
        // Fetch position storage to memory
        Position memory position = positions[tokenId];
        // Check that position has matured
        require(position.maturity <= block.timestamp, "!TIME");

        // F6: EFFECTS

        // C2: avoid reading state multiple times
        uint256 shares = position.shares;
        uint256 poolID = position.poolID;
        Pool storage pool = pools[poolID];
        // Calculate base amount obligated to user
        uint256 baseObligation = shares.fmul(_poolIndex(pool.balance, pool.supply), 1e18);
        // Calculate exess amount obligated to user
        uint256 excessObligation = shares.fmul(pool.rewardsPerShare, 1e18) - position.rewardDebt;
        // Calculate "amountOut" due to user
        amountOut = baseObligation + excessObligation;
        // Subtract users baseObligation and shares from pool storage
        pool.balance -= baseObligation;
        pool.supply -= shares;
        // C38: Delete keyword used when setting a variable to a zero value for refund
        delete positions[tokenId];
        // Transfer user "amountOut" (baseObligation + excessObligation rewards)
        TransferHelper.safeTransfer(CNV, to, amountOut);
        // T2: Events emitted for every storage mutating function.
        emit Unlock(amountOut, poolID, msg.sender);
    }

    function rebase() external virtual whenNotPaused returns (bool vebase) {
        if (block.timestamp >= lastRebaseTime + rebaseInterval) {
            uint256 incentive = rebaseIncentive;
            (uint256 eCOOP, uint256 eStakers, uint256 CNVS) = _rebase(incentive);
            ICNV(CNV).mint(COOP, eCOOP);
            ICNV(CNV).mint(address(this), eStakers);
            ICNV(CNV).mint(msg.sender, incentive);
            emit Rebase(eStakers, eCOOP, CNVS);
            vebase = true;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // UTILS
    ////////////////////////////////////////////////////////////////////////////

    function lockPoolsLength() external virtual view returns (uint256) {
        return pools.length;
    }

    function _checkPoolExcessRatioSums() internal virtual view returns (bool) {
        uint256 excessRatioSum;
        uint256 poolsLength = pools.length;
        for (uint256 i; i < poolsLength;) {
            Pool memory pool = pools[i];
            if (/* pool.open || */ pool.balance != 0) excessRatioSum  += pool.excessRatio;
            unchecked { ++i; }
        }
        return excessRatioSum <= 1e18;
    }

    function _poolIndex(
        uint256 _bal,
        uint256 _supply
    ) public pure virtual returns (uint256) {
        if (_bal + _supply == 0) return 1e18;
        return uint256(1e18).fmul(_bal, _supply);
    }

    ////////////////////////////////////////////////////////////////////////////
    // _lock logic
    ////////////////////////////////////////////////////////////////////////////

    function _lock(
        address to,
        uint256 input,
        uint256 pid
    ) internal virtual returns(uint256 tokenId) {
        // F6: CHECKS

        // Fetch pool storage from pools mapping
        Pool storage pool = pools[pid];
        // C2: avoid reading state multiple times
        uint256 shares = input.fmul(1e18, _poolIndex(pool.balance, pool.supply));
        uint256 rewardDebt = shares.fmul(pool.rewardsPerShare, 1e18);
        // Pull users stake (CNV) to this contract
        TransferHelper.safeTransferFrom(CNV, msg.sender, address(this), input);
        // Optimistically mutate state to calculate lgm, REVIEW F6: possible reentrance issue
        pool.balance += input;
        pool.supply += shares;
        // Create lgm variable to be used in below calculation
        uint256 lgm;
        // Avoid fetching length each loop to save gas
        uint256 poolsLength = pools.length;

        // Iterate through pool balances to calculate lgm
        for (uint256 i; i < poolsLength;) {
            Pool memory lp = pools[i];
            uint256 _balance = lp.balance;
            if (_balance != 0) lgm += _balance.fmul(lp.g, 1e18);
            unchecked { ++i; }
        }

        // Check that staking cap is still satisfied
        uint256 lhs = 1e18 - coopRateMax - uint256(1e18 - coopRateMax).fmul(1e18, minPrice);
        uint256 rhs = lgm.fmul(1e18, circulatingSupply() - IBonding(BONDS).cnvEmitted());
        require(lhs > rhs, "CAP");

        // F6: EFFECTS

        // Increment totalSupply to account for new nft
        unchecked { ++totalSupply; }
        // Set return value, users nft id
        tokenId = totalSupply;
        // Store users position info
        positions[tokenId] = Position(
            uint32(pid),
            uint224(shares),
            uint32(block.timestamp + pool.term),
            uint224(rewardDebt)
        );
        // Mint caller nft that represents their stake
        _mint(to, tokenId);
        // T2: Events emitted for every storage mutating function.
        emit Lock(input, pid, msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////
    // REBASE
    ////////////////////////////////////////////////////////////////////////////

    function _rebase(
        uint256 eRI
    ) internal virtual returns (uint256 eCOOP, uint256 eStakers, uint256 CNVS) {

        uint256 value = IValueShuttle(VALUESHUTTLE).shuttleValue();
        uint256 amountOut = IBonding(BONDS).cnvEmitted();
        uint256 poolsLength = pools.length;
        CNVS = circulatingSupply() - amountOut;
        eCOOP = uint256(value - amountOut).fmul(_calculateCOOPRate(value, amountOut), 1e18);
        uint256 lgm;
        uint256 erm;

        for (uint256 i; i < poolsLength;) {
            Pool memory lp = pools[i];
            uint256 balance = lp.balance;
            if (balance != 0) {
                lgm += balance.fmul(lp.g, 1e18);
                erm += balance.fmul(lp.excessRatio, 1e18);
            }
            unchecked { ++i; }
        }

        uint256 emissions = uint256(amountOut + eCOOP + eRI).fmul(1e18, 1e18 - lgm.fmul(1e18, CNVS));
        uint256 g = emissions.fmul(1e18, CNVS);
        uint256 excessObligation = (value - emissions) + globalExcess;
        uint256 excessRewards = CNVS.fmul(apyPerRebase, 1e18);
        if (excessRewards > excessObligation) excessRewards = excessObligation;
        uint256 excessMultiplier = erm != 0 ? excessRewards.fmul(1e18, erm) : 0;
        (uint256 eStakersAD, uint256 excessConsumed) = _distribute(poolsLength, g, excessMultiplier);

        globalExcess = excessObligation - excessConsumed;

        // delete cnvEmitted;
        require(IBonding(BONDS).vebase());
        lastRebaseTime = block.timestamp;
        eStakers = eStakersAD + excessConsumed;
    }

    function _distribute(
        uint256 poolsLength,
        uint256 g,
        uint256 excessMultiplier
    ) internal virtual returns(uint256 eStakers, uint256 excessConsumed) {
        for (uint256 i; i < poolsLength;) {
            Pool storage pool =  pools[i];
            uint256 balance = pool.balance;
            uint256 supply = pool.supply;

            if (balance != 0 && supply != 0) {
                uint256 baseObligation = g.fmul(pool.g.fmul(balance, 1e18), 1e18);
                uint256 excessObligation = excessMultiplier.fmul(balance, 1e18).fmul(pool.excessRatio, 1e18);
                emit PoolRewarded(
                    i,
                    baseObligation,
                    excessObligation,
                    pool.balance
                );
                pool.balance = balance + baseObligation;
                pool.rewardsPerShare += excessObligation.fmul(1e18, supply);
                eStakers += baseObligation;
                excessConsumed += excessObligation;
            }
            unchecked { ++i; }
        }
    }


    function _calculateCOOPRate(
        uint256 _value,
        uint256 _cnvOut
    ) public view virtual returns (uint256) {

        if (_cnvOut == 0) return _value;
        uint256 _bondPrice = _value.fmul(1e18, _cnvOut);

        uint256 coopRate = (coopRatePriceControl * 1e18 / _bondPrice * haogegeControl) / 1e18;
        if (coopRate > coopRateMax) return coopRateMax;
        return coopRate;
    }

    function circulatingSupply() public view virtual returns(uint256) {
        return ICNV(CNV).totalSupply() - IBonding(BONDS).getAvailableSupply();
    }

    /* -------------------------------------------------------------------------- */
    /*                              ERC721.tokenURI()                             */
    /* -------------------------------------------------------------------------- */

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (URI_ADDRESS != address(0)) return IERC721(URI_ADDRESS).tokenURI(id);
    }

    /* -------------------------------------------------------------------------- */
    /*                              MANAGEMENT LOGIC                              */
    /* -------------------------------------------------------------------------- */


    function openLockPool(
        uint64 _term,
        uint256 _g,
        uint256 _excessRatio
    ) external virtual onlyOwner {
        pools.push(Pool(_term, _g, _excessRatio, 0, 0, 0));
        require(_checkPoolExcessRatioSums(), "RATIO_SUM");

        emit PoolOpened(_term,_g,_excessRatio,pools.length-1);
    }

    function manageLockPool(
        uint256 poolID,
        uint64 _term,
        uint256 _g,
        uint256 _excessRatio
    ) external virtual onlyOwner {
        Pool storage pool = pools[poolID];
        (pool.term, pool.g, pool.excessRatio) = (_term, _g, _excessRatio);
        require(_checkPoolExcessRatioSums(), "RATIO_SUM");

        emit PoolOpened(_term,_g,_excessRatio,poolID);
    }

    function setCOOPParameters(
        uint256 _coopRatePriceControl,
        uint256 _haogegeControl,
        uint256 _coopRateMax
    ) external virtual onlyOwner {
        coopRatePriceControl = _coopRatePriceControl;
        haogegeControl = _haogegeControl;
        coopRateMax = _coopRateMax;

        emit CoopRateManaged(_coopRatePriceControl,_haogegeControl,_coopRateMax);
    }

    function manualExcessDistribution(uint256[] memory amounts) external virtual onlyOwner {
        uint256 length = amounts.length;
        uint256 toDistribute;
        for (uint256 i; i < length;) {
            Pool storage pool = pools[i];
            uint256 amount = amounts[i];
            pool.rewardsPerShare += amount.fmul(1e18, pool.supply);
            toDistribute += amount;
            unchecked { ++i; }
        }
        uint256 ge = globalExcess;
        require(toDistribute <= ge,"EXCEEDS_EXCESS");
        globalExcess = ge - toDistribute;
        ICNV(CNV).mint(address(this), toDistribute);

        emit ExcessRewardsDistributed(toDistribute,globalExcess);
    }

    function setAPYPerRebase(uint256 _apy) external virtual onlyOwner {
        apyPerRebase = _apy;

        emit RebaseAPYManaged(_apy);
    }

    function setRebaseIncentive(uint256 _rebaseIncentive) external virtual onlyOwner {
        rebaseIncentive = _rebaseIncentive;

        emit RebaseIncentiveManaged(rebaseIncentive);
    }

    function setRebaseInterval(uint256 _rebaseInterval) external virtual onlyOwner {
        rebaseInterval = _rebaseInterval;

        emit RebaseIntervalManaged(rebaseInterval);
    }

    function setMinPrice(uint256 _minPrice) external virtual onlyOwner {
        minPrice = _minPrice;

        emit MinPriceManaged(minPrice);
    }

    function setPause(bool _toPause) external virtual onlyOwner {
        if (_toPause) _pause();
        else _unpause();
    }

    function setAddress(uint8 _what, address _address) external virtual onlyOwner {
        require(_what < 5,"BAD_INPUT");
        if (_what == 0) {
            CNV = _address;
        } else if (_what == 1) {
            BONDS = _address;
        } else if (_what == 2) {
            COOP = _address;
        } else if (_what == 3) {
            VALUESHUTTLE = _address;
        } else {
            URI_ADDRESS = _address;
        }

        emit AddressManaged(_what,_address);
    }

}