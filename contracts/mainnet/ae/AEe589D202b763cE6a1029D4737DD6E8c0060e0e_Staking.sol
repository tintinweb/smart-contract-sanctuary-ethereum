// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

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
    function getApproved(uint256 tokenId) external view returns (address);

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
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC721Metadata.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
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
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

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
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
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
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IMLC {
    function mintTo(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@andskur/contracts/contracts/extension/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@andskur/contracts/contracts/eip/interface/IERC20.sol";
import "@andskur/contracts/contracts/eip/interface/IERC721.sol";
import "@andskur/contracts/contracts/eip/interface/IERC721A.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMLC.sol";


contract Staking is Ownable, PausableUpgradeable {

    // Collection data type with reward amount, reward interval and minimal time of staking
    struct StakedCollection {
        uint256 rewardAmount;
        uint256 rewardInterval;
        uint256 minStaking;
    }

    // Staked Token data type that identifier by collection address and token ID
    struct StakedToken {
        address collection;
        uint256 tokenId;
        address staker;
        uint256 totalStakingTime;
    }

    // Staker data type of token holder user
    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 claimedRewards;
        StakedToken[] stakedTokens;
    }

    // Interface for ERC20 rewards token
    IMLC public rewardsToken;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Collection addresses Token Id to staker
    mapping(address => mapping(uint256 => address)) public stakerAddresses;

    // Added collections for stacking
    //collection address => stacking params see `stakedCollection` data type
    mapping(address => StakedCollection) private _stakedCollections;

    // init function, like constructor but for upgradable contracts
    function initialize(address _rewardsTokenAddress) external initializer {
        require(_rewardsTokenAddress != address(0), "Address of rewards ERC20 should not be 0 address!");
        _setupOwner(msg.sender);
        rewardsToken = IMLC(_rewardsTokenAddress);
    }

    // setRewardsTokenAddress set new rewardsToken address
    function setRewardsTokenAddress(address _rewardsTokenAddress) external onlyOwner whenNotPaused {
        require(_rewardsTokenAddress != address(0), "Rewards address should not be 0 address!");
        rewardsToken = IMLC(_rewardsTokenAddress);
    }

    /*
    * @dev Adds `_amount` of available rewards to claim for given `_staker` address
    *
    * Requirements:
    * - Caller should be owner
    * - Contract should not be paused
    *
    * @param _staker  user address
    * @param _amount  amount of rewards that will be added to available rewards to claim
    */
    function addInitialReward(address _staker, uint256 _amount) external onlyOwner whenNotPaused {
        _addInitialReward(_staker, _amount);
    }

    function addInitialRewardsArray(address[] memory _stakers, uint256[] memory _amounts) external onlyOwner whenNotPaused {
        require(_stakers.length > 0, "There must be at least one staker address");
        require(_amounts.length > 0, "There must be at least one amount value");
        require(_amounts.length == _stakers.length, "stakers length should be the same as _amounts length");

        for (uint256 i = 0; i < _stakers.length; i ++) {
            _addInitialReward(_stakers[i], _amounts[i]);
        }
    }

    function _addInitialReward(address _staker, uint256 _amount) internal {
        require(_staker != address(0), "Staker should not be 0 address!");
        require(_amount > 0, "Amount should be more than 0!");

        if (stakers[_staker].amountStaked > 0) {
            uint256 rewards = calculateRewards(_staker);
            stakers[_staker].unclaimedRewards += rewards;
            _updateTotalTimeStaked(_staker);
        }

        stakers[_staker].unclaimedRewards += _amount;

        stakers[_staker].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev If address already has ERC721 Token/s staked, calculate the rewards.
    * Increment the amountStaked and map msg.sender to the Token Id of the staked
    * Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    * value of now.
    *
    * @param _collectionAddress  NFT collection address
    * @param _tokenIds[]  NFT collection token IDs to stake
    */
    function stake(address _collectionAddress, uint256[] memory _tokenIds) external whenNotPaused {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            _updateTotalTimeStaked(msg.sender);
        }

        require(_stakedCollections[_collectionAddress].minStaking > 0, "Collection not registered or stacking interval is null");
        require(_stakedCollections[_collectionAddress].rewardInterval > 0, "Collection rewardInterval is null");
        require(_stakedCollections[_collectionAddress].minStaking > 0, "Collection rewardInterval is null");
        require(_tokenIds.length > 0, "There must be at least one token id");

        for (uint256 i = 0; i < _tokenIds.length; i ++) {
            require(IERC721(_collectionAddress).ownerOf(_tokenIds[i]) == msg.sender, "You don't own this token");

            IERC721(_collectionAddress).transferFrom(msg.sender, address(this), _tokenIds[i]);

            StakedToken memory stakedToken = StakedToken(_collectionAddress, _tokenIds[i], msg.sender, 0);

            stakers[msg.sender].stakedTokens.push(stakedToken);

            stakers[msg.sender].amountStaked++;

            stakerAddresses[_collectionAddress][_tokenIds[i]] = msg.sender;
        }

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    * calculate the rewards and store them in the unclaimedRewards
    * decrement the amountStaked of the user and transfer the ERC721 token back to them
    *
    * @param _collectionAddress  NFT collection address
    * @param _tokenIds  NFT collection token IDs to withdraw
    */
    function withdraw(address _collectionAddress, uint256[] memory _tokenIds) external whenNotPaused {
        require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");

        for (uint256 l = 0; l < _tokenIds.length; l++) {
            require(stakerAddresses[_collectionAddress][_tokenIds[l]] == msg.sender, "You don't own this token");
        }

        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        for (uint256 j = 0; j < _tokenIds.length; j++) {

            uint256 index = 0;
            for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
                if (
                    stakers[msg.sender].stakedTokens[i].tokenId == _tokenIds[j]
                    &&
                    stakers[msg.sender].stakedTokens[i].collection == _collectionAddress
                    &&
                    stakers[msg.sender].stakedTokens[i].staker != address(0)
                ) {
                    index = i;
                    break;
                }
            }

            stakers[msg.sender].stakedTokens[index].staker = address(0);
            stakers[msg.sender].amountStaked--;
            stakerAddresses[_collectionAddress][_tokenIds[j]] = address(0);

            IERC721(_collectionAddress).transferFrom(address(this), msg.sender, _tokenIds[j]);

        }

        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    /*
    * @dev Calculate rewards for the msg.sender, check if there are any rewards
    * claim given amount, set unclaimedRewards to calculated rewards - amount to claim
    * and transfer the ERC20 Reward token to the user
    *
    * @param amountToClaim  how much coins user want to claim
    */
    function claimRewards(uint256 amountToClaim) external whenNotPaused {
        require(amountToClaim > 0, "Amount to claim should be more than 0");
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = rewards - amountToClaim;
        stakers[msg.sender].claimedRewards = amountToClaim + stakers[msg.sender].claimedRewards;
        rewardsToken.mintTo(msg.sender, amountToClaim);
    }

    /*
    * @dev Calculate rewards for the msg.sender, check if there are any rewards
    * claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token to the user
    *
    */
    function claimAllRewards() external whenNotPaused {
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        _updateTotalTimeStaked(msg.sender);
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].claimedRewards = rewards + stakers[msg.sender].claimedRewards;
        rewardsToken.mintTo(msg.sender, rewards);
    }

    /*
    * @dev Return available for given _staker address
    *
    * @param _staker   user address
    */
    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
        return rewards;
    }

    /*
    * @dev Return total claimed rewards for given _staker address
    *
    * @param _staker   user address
    */
    function claimedRewards(address _staker) public view returns (uint256) {
        return stakers[_staker].claimedRewards;
    }

    /*
    * @dev Return all staked tokens for given _staker address
    *
    * @param _staker   user address
    */
    function getStakedTokens(address _staker) public view returns (StakedToken[] memory) {
        Staker memory staker = stakers[_staker];

        if (stakers[_staker].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](staker.amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < staker.stakedTokens.length; j++) {
                StakedToken memory token = staker.stakedTokens[j];

                if (token.staker != (address(0))) {
                    _stakedTokens[_index] = staker.stakedTokens[j];
                    _stakedTokens[_index].totalStakingTime += block.timestamp - staker.timeOfLastUpdate;
                    _index++;
                }
            }

            return _stakedTokens;
        }

        else {
            return new StakedToken[](0);
        }
    }

    /*
    * @dev Return staked tokens count for given _collectionAddress
    *
    * @param _collectionAddress   collection address
    */
    function stakedTokensCount(address _collectionAddress) public view returns(uint256) {
        uint256 stakedCount;
        uint256 totalSupply = IERC721A(_collectionAddress).totalSupply();

        for(uint256 i = 1; i <= totalSupply; i++) {
            if (stakerAddresses[_collectionAddress][i] != address(0)) {
                stakedCount++;
            }
        }

        return stakedCount;
    }

    /*
    * @dev Return one staked token for given _collectionAddress and _tokenID
    *
    * @param _collectionAddress   collection address
    * @param _tokenID             token id
    */
    function getStakedToken(address _collectionAddress, uint256 _tokenID) public view returns(StakedToken memory) {
        if (_stakedCollections[_collectionAddress].minStaking > 0) {
            if (stakerAddresses[_collectionAddress][_tokenID] != address(0)) {
                for (uint256 j = 0; j < stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens.length; j++) {
                    StakedToken memory token = stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j];

                    if (
                        token.staker != (address(0)) &&
                        token.tokenId == _tokenID &&
                        token.collection == _collectionAddress
                    ) {
                        uint256 totalStakingTime = stakers[stakerAddresses[_collectionAddress][_tokenID]].stakedTokens[j].totalStakingTime;
                        return StakedToken(
                            token.collection,
                            token.tokenId,
                            token.staker,
                            totalStakingTime += block.timestamp - stakers[stakerAddresses[_collectionAddress][_tokenID]].timeOfLastUpdate
                        );
                    }
                }
            }
        }

        return StakedToken(address(0), 0, address(0), 0);
    }

    /*
    * @dev Calculate rewards for given _staker address
    *
    * @param _staker   user address to calculate available reward
    */
    function calculateRewards(address _staker) internal view returns (uint256 _rewards) {
        Staker memory staker = stakers[_staker];

        for (uint256 i = 0; i < staker.stakedTokens.length; i++) {
            StakedToken memory token = staker.stakedTokens[i];
            StakedCollection memory collection = _stakedCollections[token.collection];

            if (block.timestamp - stakers[stakerAddresses[token.collection][token.tokenId]].timeOfLastUpdate < collection.minStaking) {
                continue;
            }

            if (token.staker != (address(0))) {
                _rewards += ((block.timestamp - staker.timeOfLastUpdate) * collection.rewardAmount) / collection.rewardInterval;
            }
        }
        return _rewards;
    }

    /*
    * @dev Adds `collectionAddress` with given params to `_stakedCollections` mapping
    *
    * Requirements:
    * - `collectionAddress` should not be 0
    * - `collectionAddress` should not be added to `_stakedCollections` mapping
    * - `rewardAmount` should not be 0
    * - `rewardInterval` should not be 0
    * - `minStaking` should not be 0
    * - only owner of the contract
    *
    * @param collectionAddress  address of the collection
    * @param rewardAmount       amount of coins as a reward for staking
    * @param rewardInterval     amount in block that could be produced in ethereum chain before users can take their reward
    * @param minStaking        amount in block that user could wait before he could be able to unstake tokens
    */
    function addCollection(
        address collectionAddress,
        uint256 rewardAmount,
        uint256 rewardInterval,
        uint256 minStaking
    ) external onlyOwner whenNotPaused {
        require(collectionAddress != address(0), "Collection address is a zero address!");
        require(_stakedCollections[collectionAddress].rewardAmount == 0, "Collection is already added!");
        require(rewardAmount != 0, "Reward amount should not be 0!");
        require(rewardInterval != 0, "Reward interval should not be 0!");
        require(minStaking != 0, "Minimal time of staking should not be 0!");

        _stakedCollections[collectionAddress] = StakedCollection(rewardAmount, rewardInterval, minStaking);
    }


    /*
     * @dev shows added collection params
     *
     * Requirements:
     * - `collectionAddress` must not be zero address
     * - `collectionAddress` must be in `_stakedCollections` mapping
     *
     * @param `collectionAddress`- address of a collection contract
     * @return `stakedCollection` data type with params of the collection such as
     * reward amount, reward interval and minimal time of staking
     */
    function showCollection(address collectionAddress) public view returns(StakedCollection memory) {
        require(collectionAddress != address(0), "Collection address is a zero address!");
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");

        return _stakedCollections[collectionAddress];
    }

    /*
     * @dev allows to edit amount of the reward for given collection. Changes `stakedCollection.rewardAmount`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newRewardAmount` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newRewardAmount`- new amount of coins as a reward for staking
     */
    function editRewardAmount(address collectionAddress, uint256 newRewardAmount) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newRewardAmount != 0, "Reward amount should not be 0!");

        _stakedCollections[collectionAddress].rewardAmount = newRewardAmount;
    }

    /*
     * @dev allows to edit reward interval for given collection. Changes `stakedCollection.rewardInterval`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newRewardInterval` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newRewardInterval`- new amount in block that could be produced in ethereum chain before users can take their reward
     */
    function editRewardInterval(address collectionAddress, uint256 newRewardInterval) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newRewardInterval != 0, "Reward interval should not be 0!");

        _stakedCollections[collectionAddress].rewardInterval = newRewardInterval;
    }

    /*
     * @dev allows to edit minimal time of staking for given collection. Changes `stakedCollection.minStaking`
     *
     * Requirements:
     * - `collectionAddress` must be in `_stakedCollections` mapping
     * - `newMinStaking` should not be 0
     * - only owner of the contract
     *
     * @param `collectionAddress`- address of a collection contract
     * @param `newMinStaking`- new amount in block that user could wait before he could be able to unstake tokens
     */
    function editMinStaking(address collectionAddress, uint256 newMinStaking) external onlyOwner whenNotPaused {
        require(_stakedCollections[collectionAddress].rewardAmount != 0, "Collection is not added!");
        require(newMinStaking != 0, "Minimal time of staking should not be 0!");

        _stakedCollections[collectionAddress].minStaking = newMinStaking;
    }

    /*
     * @dev allows to set all not view only operations on pause
     *
     * Requirements:
     * - contract must not be paused
     * - only owner of the contract
     *
     */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * @dev allows to set all not view-only operations to normal state
     *
     * Requirements:
     * - contract must be paused
     * - only owner of the contract
     *
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _updateTotalTimeStaked(address stakerAddress) internal {
        for (uint256 i = 0; i < stakers[stakerAddress].stakedTokens.length; i++) {
            stakers[stakerAddress].stakedTokens[i].totalStakingTime += (
            block.timestamp - stakers[stakerAddress].timeOfLastUpdate
            );
        }

    }
}