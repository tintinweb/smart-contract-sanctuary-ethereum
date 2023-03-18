// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC721AInternal.sol";

/**
 * @dev Interface of ERC721A, adopted from Azuki's IERC721AUpgradeable to remove name(), symbol(), tokenURI() and supportsInterface() functions, as they're provided by independent factes.
 */
interface IERC721ABase is IERC721AInternal {
    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Interface of ERC721A adopted to contain everything except public functions.
 */
interface IERC721AInternal {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721A} that allows other facets from the diamond to mint tokens.
 */
interface IERC721MintableExtension {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC721A-_mint}.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function mintByFacet(address to, uint256 amount) external;

    /**
     * @dev Mint new tokens for multiple addresses with different amounts.
     */
    function mintByFacet(address[] memory tos, uint256[] memory amounts) external;

    /**
     * @dev Mint constant amount of new tokens for multiple addresses (e.g. 1 nft for each address).
     */
    function mintByFacet(address[] memory tos, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
pragma solidity ^0.8.0;

/// @title EIP-721 Metadata Update Extension
interface IERC4906 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PyramidStorage} from "../libraries/PyramidStorage.sol";

interface IPyramids {
    event itemAddedToPyramid(uint16 pyramidId, uint16 addedItem);

    event itemsAddedToPyramid(uint16 pyramidId, uint16[] addedItems);

    event itemRemovedFromPyramid(uint16 pyramidId, uint16 removedItem);

    event itemsRemovedFromPyramid(
        uint16 pyramidId,
        PyramidStorage.TokenSlot[4] removedItems
    );

    event itemContractUpdated(
        address newItemsContract,
        address oldItemsContract
    );

    function airdrop(
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) external;

    function getItemContract() external view returns (address _itemsContract);

    function setItemContract(address _itemsContract) external;

    function getItemType(uint16 _id) external pure returns (uint8);

    function getPyramidSlots(
        uint16 _pyramidId
    ) external view returns (PyramidStorage.TokenSlot[4] memory tokenSlots);

    function addItemsToPyramid(
        uint16 _pyramidId,
        uint16[] calldata _itemIds
    ) external;

    function addItemToPyramid(uint16 _pyramidId, uint16 _itemId) external;

    function removeItemFromPyramid(uint16 _pyramidId, uint16 _itemId) external;

    function removeItemsFromPyramid(uint16 _pyramidId) external;

    function withdrawWrongERC721(
        address _token,
        address _to,
        uint256 _tokenId
    ) external;

    function setContractURI(string calldata _contractURI) external;

    function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library PyramidStorage {
    struct TokenSlot {
        uint16 tokenId;
        bool occupied;
    }

    struct Layout {
        mapping(uint16 => TokenSlot[4]) pyramidToSlots;
        address itemsContract;
        string contractURI;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("grizzly.contracts.storage.Pyramid");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setItemsContract(
        Layout storage l,
        address _itemsContract
    ) internal {
        l.itemsContract = _itemsContract;
    }

    function setContractURI(
        Layout storage l,
        string memory _contractURI
    ) internal {
        l.contractURI = _contractURI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@flair-sdk/contracts/src/access/ownable/OwnableInternal.sol";
import "@flair-sdk/contracts/src/token/ERC721/base/IERC721ABase.sol";
import "@flair-sdk/contracts/src/token/ERC721/extensions/mintable/IERC721MintableExtension.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC721Receiver.sol";
import "./libraries/PyramidStorage.sol";
import "./interfaces/IPyramids.sol";
import "./interfaces/IERC4906.sol";

contract Pyramids is
    IPyramids,
    IERC4906,
    IERC721Receiver,
    OwnableInternal,
    ReentrancyGuardUpgradeable
{
    using PyramidStorage for PyramidStorage.Layout;

    /**
     * @dev Mint tokens and distribute them to a list of recipients.
     * @param _tos An array of recipient addresses to receive tokens.
     * @param _amounts An array of token amounts to be distributed, in the same order as _tos.
     * @notice Only the contract owner can call this function.
     */
    function airdrop(
        address[] calldata _tos,
        uint256[] calldata _amounts
    ) public virtual onlyOwner {
        IERC721MintableExtension(address(this)).mintByFacet(_tos, _amounts);
    }

    /**
     * @notice Returns the address of the items contract associated with the Pyramid contract.
     * @return _itemsContract The address of the items contract.
     */
    function getItemContract() public view returns (address _itemsContract) {
        return PyramidStorage.layout().itemsContract;
    }

    /**
     * @notice Sets the address of the items contract associated with the Pyramid contract.
     * @param _itemsContract The address of the items contract to be set.
     * @dev This function can only be called by the owner of the contract.
     */
    function setItemContract(address _itemsContract) public onlyOwner {
        address oldItemsContract = PyramidStorage.layout().itemsContract;
        PyramidStorage.layout().setItemsContract(_itemsContract);
        emit itemContractUpdated(_itemsContract, oldItemsContract);
    }

    /**
     * @notice Returns the item type of an item.
     * @param _id The ID of the item whose type is to be returned.
     * @return itemType The type of the item.
     * 0 = orb, 1 = key, 2 = hourglass, 3 = skateboard
     * @dev This function can be called externally and is view-only.
     */
    function getItemType(uint16 _id) external pure returns (uint8) {
        uint8 itemType = _checkItemType(_id);

        return itemType;
    }

    /**
     * @dev Returns an array of `TokenSlot` structs representing the token slots of the specified pyramid.
     * @param _pyramidId The ID of the pyramid to query.
     * @return tokenSlots An array of `TokenSlot` structs representing the tokenIds and an `occupied` bool of the specified pyramid.
     */
    function getPyramidSlots(
        uint16 _pyramidId
    ) external view returns (PyramidStorage.TokenSlot[4] memory tokenSlots) {
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] memory pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        return pyramidSlots;
    }

    /**
     * @notice Adds multiple items to a pyramid.
     * @param _pyramidId The ID of the pyramid.
     * @param _itemIds An array containing the IDs of the items to be added.
     * @dev This function can be called externally.
     */
    function addItemsToPyramid(
        uint16 _pyramidId,
        uint16[] calldata _itemIds
    ) public nonReentrant {
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        require(_pyramidId >= 0, "Pyramids: Pyramid nonexistant.");
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(
            _itemIds.length <= 4,
            "Pyramids: You can only add up to 4 items to a pyramid"
        );
        require(
            _itemIds.length > 0,
            "Pyramids: You must add at least 1 item to a pyramid"
        );
        require(
            PyramidStorage.layout().itemsContract != address(0),
            "Pyramids: Items contract not set"
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        for (uint8 i; i < _itemIds.length; ) {
            require(
                itemContract.ownerOf(_itemIds[i]) == msg.sender,
                "Pyramids: You do not own this item."
            );
            uint8 _type = _checkItemType(_itemIds[i]);
            if (_type == 0) {
                require(
                    !pyramidSlots[0].occupied,
                    "Pyramids: Remove orb before adding another."
                );
                pyramidSlots[0].tokenId = _itemIds[i];
                pyramidSlots[0].occupied = true;
            }
            if (_type == 1) {
                require(
                    !pyramidSlots[1].occupied,
                    "Pyramids: Remove key before adding another."
                );
                pyramidSlots[1].tokenId = _itemIds[i];
                pyramidSlots[1].occupied = true;
            }
            if (_type == 2) {
                require(
                    !pyramidSlots[2].occupied,
                    "Pyramids: Remove hourglass before adding another."
                );
                pyramidSlots[2].tokenId = _itemIds[i];
                pyramidSlots[2].occupied = true;
            }
            if (_type == 3) {
                require(
                    !pyramidSlots[3].occupied,
                    "Pyramids: Remove skateboard before adding another."
                );
                pyramidSlots[3].tokenId = _itemIds[i];
                pyramidSlots[3].occupied = true;
            }
            itemContract.transferFrom(msg.sender, address(this), _itemIds[i]);
            ++i;
        }
        emit itemsAddedToPyramid(_pyramidId, _itemIds);
        emit MetadataUpdate(_pyramidId);
    }

    /**
     * @dev Adds an item to a pyramid by transferring an ERC721 token from the caller to this contract and assigning it to a slot in the pyramid.
     * The slot is determined by the type of item being added. Only the owner of the pyramid can add an item to it.
     * @param _pyramidId The ID of the pyramid to which the item will be added.
     * @param _itemId The ID of the item to be added.
     */
    function addItemToPyramid(
        uint16 _pyramidId,
        uint16 _itemId
    ) public nonReentrant {
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(_itemId <= 19999, "Pyramids: Item nonexistant.");
        require(
            PyramidStorage.layout().itemsContract != address(0),
            "Pyramids: Items contract not set"
        );

        require(
            itemContract.ownerOf(_itemId) == msg.sender,
            "Pyramids: You do not own this item."
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        uint8 _type = _checkItemType(_itemId);
        if (_type == 0) {
            require(
                !pyramidSlots[0].occupied,
                "Pyramids: Remove orb before adding another."
            );
            pyramidSlots[0].tokenId = _itemId;
            pyramidSlots[0].occupied = true;
        }
        if (_type == 1) {
            require(
                !pyramidSlots[1].occupied,
                "Pyramids: Remove key before adding another."
            );
            pyramidSlots[1].tokenId = _itemId;
            pyramidSlots[1].occupied = true;
        }
        if (_type == 2) {
            require(
                !pyramidSlots[2].occupied,
                "Pyramids: Remove hourglass before adding another."
            );
            pyramidSlots[2].tokenId = _itemId;
            pyramidSlots[2].occupied = true;
        }
        if (_type == 3) {
            require(
                !pyramidSlots[3].occupied,
                "Pyramids: Remove skateboard before adding another."
            );
            pyramidSlots[3].tokenId = _itemId;
            pyramidSlots[3].occupied = true;
        }
        itemContract.transferFrom(msg.sender, address(this), _itemId);
        emit MetadataUpdate(_pyramidId);
        emit itemAddedToPyramid(_pyramidId, _itemId);
    }

    /**
     * @dev Removes an item from a pyramid by transferring an ERC721 token from this contract to the caller and removing its reference from the slot in the pyramid.
     * The slot is determined by the type of item being removed. Only the owner of the pyramid can remove an item from it.
     * @param _pyramidId The ID of the pyramid from which the item will be removed.
     * @param _itemId The ID of the item to be removed.
     */
    function removeItemFromPyramid(
        uint16 _pyramidId,
        uint16 _itemId
    ) public nonReentrant {
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(_itemId <= 19999, "Pyramids: Item nonexistant.");
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        uint8 _type = _checkItemType(_itemId);
        if (_type == 0) {
            require(
                pyramidSlots[0].occupied,
                "Pyramids: There is no orb attached to this pyramid."
            );
            require(
                pyramidSlots[0].tokenId == _itemId,
                "Pyramids: The orb id stored does not match."
            );
            pyramidSlots[0].occupied = false;
            pyramidSlots[0].tokenId = 0;
            itemContract.transferFrom(address(this), msg.sender, _itemId);
        }
        if (_type == 1) {
            require(
                pyramidSlots[1].occupied,
                "Pyramids: There is no key attached to this pyramid."
            );
            require(
                pyramidSlots[1].tokenId == _itemId,
                "Pyramids: The key id stored does not match."
            );
            pyramidSlots[1].occupied = false;
            pyramidSlots[1].tokenId = 0;
            itemContract.transferFrom(address(this), msg.sender, _itemId);
        }
        if (_type == 2) {
            require(
                pyramidSlots[2].occupied,
                "Pyramids: There is no hourglass attached to this pyramid."
            );
            require(
                pyramidSlots[2].tokenId == _itemId,
                "Pyramids: The hourglass id stored does not match."
            );
            pyramidSlots[2].occupied = false;
            pyramidSlots[2].tokenId = 0;
            itemContract.transferFrom(address(this), msg.sender, _itemId);
        }
        if (_type == 3) {
            require(
                pyramidSlots[3].occupied,
                "Pyramids: There is no skateboard attached to this pyramid."
            );
            require(
                pyramidSlots[3].tokenId == _itemId,
                "Pyramids: The skateboard id stored does not match."
            );
            pyramidSlots[3].occupied = false;
            pyramidSlots[3].tokenId = 0;
            itemContract.transferFrom(address(this), msg.sender, _itemId);
        }
        emit MetadataUpdate(_pyramidId);
        emit itemRemovedFromPyramid(_pyramidId, _itemId);
    }

    /*
     * @dev Removes all items from the specified pyramid owned by the caller and transfers them back to the caller.
     * @param _pyramidId The ID of the pyramid from which to remove items.
     * @return None.
     */
    function removeItemsFromPyramid(uint16 _pyramidId) public nonReentrant {
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        uint8 numOccupied;
        PyramidStorage.TokenSlot[4] memory removedItems = pyramidSlots;
        for (uint8 i; i < pyramidSlots.length; ) {
            if (pyramidSlots[i].occupied) {
                ++numOccupied;
                itemContract.transferFrom(
                    address(this),
                    msg.sender,
                    pyramidSlots[i].tokenId
                );
                pyramidSlots[i].occupied = false;
                pyramidSlots[i].tokenId = 0;
            }
            ++i;
        }
        require(numOccupied > 0, "Pyramids: There are no items to remove.");
        emit itemsRemovedFromPyramid(_pyramidId, removedItems);
        emit MetadataUpdate(_pyramidId);
    }

    /**
     * @notice Returns the type of an item.
     * @param id The ID of the item whose type is to be returned.
     * @return The type of the item.
     * 0 = orb, 1 = key, 2 = hourglass, 3 = skateboard
     * @dev This function can only be called internally.
     */
    function _checkItemType(uint16 id) internal pure returns (uint8) {
        uint8 _type;
        require(id < 20000, "Pyramids: token id nonexsistent");

        assembly {
            switch gt(id, 14999)
            case 1 {
                _type := 3
            }
            case 0 {
                switch gt(id, 9999)
                case 1 {
                    _type := 2
                }
                case 0 {
                    switch gt(id, 4999)
                    case 1 {
                        _type := 1
                    }
                    case 0 {
                        _type := 0
                    }
                }
            }
        }
        return _type;
    }

    /**
     * @dev Transfers a wrongly deposited ERC721 token to the specified recipient
     * @param _token The address of the ERC721 token contract
     * @param _to The address of the recipient who will receive the wrongly deposited token
     * @param _tokenId The ID of the ERC721 token to transfer
     */
    function withdrawWrongERC721(
        address _token,
        address _to,
        uint256 _tokenId
    ) public onlyOwner nonReentrant {
        IERC721ABase(_token).transferFrom(address(this), _to, _tokenId);
    }

    /**
     * @dev ERC721 receiver function that returns the `bytes4` selector indicating support for the ERC721 interface
     * @param operator The address of the operator performing the transfer
     * @param from The address of the sender who is transferring the token
     * @param tokenId The ID of the ERC721 token being transferred
     * @param data Additional data attached to the transfer
     * @return The `bytes4` selector indicating support for the ERC721 interface
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function contractURI() public view returns (string memory) {
        return PyramidStorage.layout().contractURI;
    }

    function setContractURI(string calldata _uri) public onlyOwner {
        PyramidStorage.layout().setContractURI(_uri);
    }
}