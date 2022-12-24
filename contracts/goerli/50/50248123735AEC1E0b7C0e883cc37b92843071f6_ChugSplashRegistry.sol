// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @notice Struct representing the state of a ChugSplash bundle.
 */
struct ChugSplashBundleState {
    ChugSplashBundleStatus status;
    bool[] executions;
    bytes32 merkleRoot;
    uint256 actionsExecuted;
    uint256 timeClaimed;
    address selectedExecutor;
}

/**
 * @notice Struct representing a ChugSplash action.
 */
struct ChugSplashAction {
    string target;
    ChugSplashActionType actionType;
    bytes data;
}

/**
 * @notice Enum representing possible ChugSplash action types.
 */
enum ChugSplashActionType {
    SET_STORAGE,
    DEPLOY_IMPLEMENTATION,
    SET_IMPLEMENTATION
}

/**
 * @notice Enum representing the status of a given ChugSplash action.
 */
enum ChugSplashBundleStatus {
    EMPTY,
    PROPOSED,
    APPROVED,
    COMPLETED,
    CANCELLED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {
    ChugSplashBundleState,
    ChugSplashAction,
    ChugSplashActionType,
    ChugSplashBundleStatus
} from "./ChugSplashDataTypes.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Proxy } from "./libraries/Proxy.sol";
import { ChugSplashRegistry } from "./ChugSplashRegistry.sol";
import { IProxyAdapter } from "./IProxyAdapter.sol";
import { ProxyUpdater } from "./ProxyUpdater.sol";
import { Create2 } from "./libraries/Create2.sol";
import { MerkleTree } from "./libraries/MerkleTree.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ChugSplashManager
 */
contract ChugSplashManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /**
     * @notice Emitted when a ChugSplash bundle is proposed.
     *
     * @param bundleId   ID of the bundle being proposed.
     * @param bundleRoot Root of the proposed bundle's merkle tree.
     * @param bundleSize Number of steps in the proposed bundle.
     * @param configUri  URI of the config file that can be used to re-generate the bundle.
     */
    event ChugSplashBundleProposed(
        bytes32 indexed bundleId,
        bytes32 bundleRoot,
        uint256 bundleSize,
        string configUri
    );

    /**
     * @notice Emitted when a ChugSplash bundle is approved.
     *
     * @param bundleId ID of the bundle being approved.
     */
    event ChugSplashBundleApproved(bytes32 indexed bundleId);

    /**
     * @notice Emitted when a ChugSplash action is executed.
     *
     * @param bundleId    Unique ID for the bundle.
     * @param executor    Address of the executor.
     * @param actionIndex Index within the bundle hash of the action that was executed.
     */
    event ChugSplashActionExecuted(
        bytes32 indexed bundleId,
        address indexed executor,
        uint256 actionIndex
    );

    /**
     * @notice Emitted when a ChugSplash bundle is completed.
     *
     * @param bundleId        Unique ID for the bundle.
     * @param executor        Address of the executor.
     * @param actionsExecuted Total number of completed actions.
     */
    event ChugSplashBundleCompleted(
        bytes32 indexed bundleId,
        address indexed executor,
        uint256 actionsExecuted
    );

    /**
     * @notice Emitted when an active ChugSplash bundle is cancelled.
     *
     * @param bundleId        Bundle ID that was cancelled.
     * @param owner           Owner of the ChugSplashManager.
     * @param actionsExecuted Total number of completed actions before cancellation.
     */
    event ChugSplashBundleCancelled(
        bytes32 indexed bundleId,
        address indexed owner,
        uint256 actionsExecuted
    );

    /**
     * @notice Emitted when ownership of a proxy is transferred from the ProxyAdmin to the project
     *         owner.
     *
     * @param targetHash Hash of the target's string name.
     * @param proxy      Address of the proxy that is the subject of the ownership transfer.
     * @param proxyType  The proxy type.
     * @param newOwner   Address of the project owner that is receiving ownership of the proxy.
     * @param target     String name of the target.
     */
    event ProxyOwnershipTransferred(
        string indexed targetHash,
        address indexed proxy,
        bytes32 indexed proxyType,
        address newOwner,
        string target
    );

    /**
     * @notice Emitted when a bundle is claimed by an executor.
     *
     * @param bundleId ID of the bundle that was claimed.
     * @param executor Address of the executor that claimed the bundle ID for the project.
     */
    event ChugSplashBundleClaimed(bytes32 indexed bundleId, address indexed executor);

    /**
     * @notice Emitted when an executor claims a payment.
     *
     * @param executor The executor being paid.
     * @param amount   The ETH amount sent to the executor.
     */
    event ExecutorPaymentClaimed(address indexed executor, uint256 amount);

    /**
     * @notice Emitted when the owner withdraws ETH from this contract.
     *
     * @param owner  Address that initiated the withdrawal.
     * @param amount ETH amount withdrawn.
     */
    event OwnerWithdrewETH(address indexed owner, uint256 amount);

    /**
     * @notice Emitted when the owner of this contract adds a new proposer.
     *
     * @param proposer Address of the proposer that was added.
     * @param proposer Address of the owner.
     */
    event ProposerAdded(address indexed proposer, address indexed owner);

    /**
     * @notice Emitted when the owner of this contract removes an existing proposer.
     *
     * @param proposer Address of the proposer that was removed.
     * @param proposer Address of the owner.
     */
    event ProposerRemoved(address indexed proposer, address indexed owner);

    /**
     * @notice Emitted when ETH is deposited in this contract
     */
    event ETHDeposited(address indexed from, uint256 indexed amount);

    /**
     * @notice Emitted when a default proxy is deployed by this contract.
     *
     * @param targetHash Hash of the target's string name. This equals the salt used to deploy the
     *                   proxy.
     * @param proxy      Address of the deployed proxy.
     * @param bundleId   ID of the bundle in which the proxy was deployed.
     * @param target     String name of the target.
     */
    event DefaultProxyDeployed(
        string indexed targetHash,
        address indexed proxy,
        bytes32 indexed bundleId,
        string target
    );

    /**
     * @notice Emitted when an implementation contract is deployed by this contract.
     *
     * @param targetHash     Hash of the target's string name.
     * @param implementation Address of the deployed implementation.
     * @param bundleId       ID of the bundle in which the implementation was deployed.
     * @param target         String name of the target.
     */
    event ImplementationDeployed(
        string indexed targetHash,
        address indexed implementation,
        bytes32 indexed bundleId,
        string target
    );

    /**
     * @notice The storage slot that holds the address of an EIP-1967 implementation contract.
     *         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 internal constant EIP1967_IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Address of the ChugSplashRegistry.
     */
    ChugSplashRegistry public immutable registry;

    /**
     * @notice Address of the ProxyUpdater.
     */
    address public immutable proxyUpdater;

    /**
     * @notice Amount that must be deposited in this contract in order to execute a bundle. The
     *         project owner can withdraw this amount whenever a bundle is not active. This bond
     *         will be forfeited if the project owner cancels a bundle that is in progress, which is
     *         necessary to prevent owners from trolling executors by immediately cancelling and
     *         withdrawing funds.
     */
    uint256 public immutable ownerBondAmount;

    /**
     * @notice Amount in ETH that the executor must send to this contract to claim a bundle for
     *         `executionLockTime`.
     */
    uint256 public immutable executorBondAmount;

    /**
     * @notice Amount of time for an executor to finish executing a bundle once they have claimed
     *         it. If the executor fails to completely execute the bundle in this amount of time,
     *         their bond is forfeited to the ChugSplashManager.
     */
    uint256 public immutable executionLockTime;

    /**
     * @notice Amount that executors are paid, denominated as a percentage of the cost of execution.
     *         For example: if a bundle costs 1 gwei to execute and the executorPaymentPercentage is
     *         10, then the executor will profit 0.1 gwei.
     */
    uint256 public immutable executorPaymentPercentage;

    /**
     * @notice Mapping of targets to proxy addresses. If a target is using the default
     *         proxy, then its value in this mapping is the zero-address.
     */
    mapping(string => address payable) public proxies;

    /**
     * @notice Mapping of executor addresses to the ETH amount stored in this contract that is
     *         owed to them.
     */
    mapping(address => uint256) public debt;

    /**
     * @notice Mapping of targets to proxy types. If a target is using the default proxy,
     *         then its value in this mapping is bytes32(0).
     */
    mapping(string => bytes32) public proxyTypes;

    /**
     * @notice Mapping of salt values to deployed implementation addresses. An implementation
     *         address is stored in this mapping in each DeployImplementation action, and is
     *         retrieved in the SetImplementation action. The salt is a hash of the bundle ID and
     *         target, which is guaranteed to be unique within this contract since each bundle ID
     *         can only be executed once and each target is unique within a bundle. The salt
     *         prevents address collisions, which would otherwise be possible since we use Create2
     *         to deploy the implementations.
     */
    mapping(bytes32 => address) public implementations;

    /**
     * @notice Maps an address to a boolean indicating if the address is allowed to propose bundles.
     *         The owner of this contract is the only address that can add or remove proposers from
     *         this mapping.
     */
    mapping(address => bool) public proposers;

    /**
     * @notice Mapping of bundle IDs to bundle state.
     */
    mapping(bytes32 => ChugSplashBundleState) internal _bundles;

    /**
     * @notice Name of the project this contract is managing.
     */
    string public name;

    /**
     * @notice ID of the currently active bundle.
     */
    bytes32 public activeBundleId;

    /**
     * @notice Total ETH amount that is owed to executors.
     */
    uint256 public totalDebt;

    /**
     * @param _registry                  Address of the ChugSplashRegistry.
     * @param _name                      Name of the project this contract is managing.
     * @param _owner                     Address of the project owner.
     * @param _proxyUpdater              Address of the ProxyUpdater.
     * @param _executorBondAmount        Executor bond amount in ETH.
     * @param _executionLockTime         Amount of time for an executor to completely execute a
     *                                   bundle after claiming it.
     * @param _ownerBondAmount           Amount that must be deposited in this contract in order to
     *                                   execute a bundle.
     * @param _executorPaymentPercentage Amount that an executor will earn from completing a bundle,
     *                                   denominated as a percentage.
     */
    constructor(
        ChugSplashRegistry _registry,
        string memory _name,
        address _owner,
        address _proxyUpdater,
        uint256 _executorBondAmount,
        uint256 _executionLockTime,
        uint256 _ownerBondAmount,
        uint256 _executorPaymentPercentage
    ) {
        registry = _registry;
        proxyUpdater = _proxyUpdater;
        executorBondAmount = _executorBondAmount;
        executionLockTime = _executionLockTime;
        ownerBondAmount = _ownerBondAmount;
        executorPaymentPercentage = _executorPaymentPercentage;

        initialize(_name, _owner);
    }

    /**
     * @param _name  Name of the project this contract is managing.
     * @param _owner Initial owner of this contract.
     */
    function initialize(string memory _name, address _owner) public initializer {
        name = _name;

        __Ownable_init();
        _transferOwnership(_owner);
    }

    /**
     * @notice Computes the bundle ID from the bundle parameters.
     *
     * @param _bundleRoot Root of the bundle's merkle tree.
     * @param _bundleSize Number of elements in the bundle's tree.
     * @param _configUri  URI pointing to the config file for the bundle.
     *
     * @return Unique ID for the bundle.
     */
    function computeBundleId(
        bytes32 _bundleRoot,
        uint256 _bundleSize,
        string memory _configUri
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_bundleRoot, _bundleSize, _configUri));
    }

    /**
     * @notice Queries the selected executor for a given project/bundle.
     *
     * @param _bundleId ID of the bundle currently being executed.
     *
     * @return Address of the selected executor.
     */
    function getSelectedExecutor(bytes32 _bundleId) public view returns (address) {
        ChugSplashBundleState storage bundle = _bundles[_bundleId];
        return bundle.selectedExecutor;
    }

    /**
     * @notice Gets the ChugSplashBundleState struct for a given bundle ID. Note that we explicitly
     *         define this function because the getter function that is automatically generated by
     *         the Solidity compiler doesn't return a struct.
     *
     * @param _bundleId Bundle ID.
     *
     * @return ChugSplashBundleState struct.
     */
    function bundles(bytes32 _bundleId) public view returns (ChugSplashBundleState memory) {
        return _bundles[_bundleId];
    }

    /**
     * @notice Computes the Create2 address of the default EIP-1967 proxy deployed by the
     *         ChugSplashManager when a bundle is executed. Note that there will not be a contract
     *         at the deployed address until one with the given target name is executed by
     *         the ChugSplashManager.
     *
     * @param _name Name of the target to get the corresponding proxy address of.
     *
     * @return Address of the proxy for the given name.
     */
    function getDefaultProxyAddress(string memory _name) public view returns (address payable) {
        return (
            payable(
                Create2.compute(
                    address(this),
                    keccak256(bytes(_name)),
                    abi.encodePacked(type(Proxy).creationCode, abi.encode(address(this)))
                )
            )
        );
    }

    /**
     * @notice Propose a new ChugSplash bundle to be approved. Only callable by the owner of this
     *         contract or a proposer. These permissions are required to prevent spam.
     *
     * @param _bundleRoot Root of the bundle's merkle tree.
     * @param _bundleSize Number of elements in the bundle's tree.
     * @param _configUri  URI pointing to the config file for the bundle.
     */
    function proposeChugSplashBundle(
        bytes32 _bundleRoot,
        uint256 _bundleSize,
        string memory _configUri
    ) public {
        require(
            msg.sender == owner() || proposers[msg.sender] == true,
            "ChugSplashManager: caller must be proposer or owner"
        );

        bytes32 bundleId = computeBundleId(_bundleRoot, _bundleSize, _configUri);
        ChugSplashBundleState storage bundle = _bundles[bundleId];

        require(
            bundle.status == ChugSplashBundleStatus.EMPTY,
            "ChugSplashManager: bundle already exists"
        );

        bundle.status = ChugSplashBundleStatus.PROPOSED;
        bundle.executions = new bool[](_bundleSize);
        bundle.merkleRoot = _bundleRoot;

        emit ChugSplashBundleProposed(bundleId, _bundleRoot, _bundleSize, _configUri);
        registry.announce("ChugSplashBundleProposed");
    }

    /**
     * @notice Allows the owner to approve a bundle to be executed. There must be at least
     *         `ownerBondAmount` deposited in this contract in order for a bundle to be approved.
     *         The owner can send the bond to this contract via a call to `depositETH` or `receive`.
     *         This bond will be forfeited if the project owner cancels an approved bundle. Also
     *         note that the bundle can be executed as soon as it is approved.
     *
     * @param _bundleId ID of the bundle to approve
     */
    function approveChugSplashBundle(bytes32 _bundleId) public onlyOwner {
        require(
            address(this).balance - totalDebt >= ownerBondAmount,
            "ChugSplashManager: insufficient balance in manager"
        );

        ChugSplashBundleState storage bundle = _bundles[_bundleId];

        require(
            bundle.status == ChugSplashBundleStatus.PROPOSED,
            "ChugSplashManager: bundle does not exist or has already been approved or completed"
        );

        require(
            activeBundleId == bytes32(0),
            "ChugSplashManager: another bundle has been approved and not yet completed"
        );

        activeBundleId = _bundleId;
        bundle.status = ChugSplashBundleStatus.APPROVED;

        emit ChugSplashBundleApproved(_bundleId);
        registry.announce("ChugSplashBundleApproved");
    }

    /**
     * @notice Executes multiple ChugSplash actions at once. This speeds up execution time since the
     *         executor doesn't need to send as many transactions to execute a bundle. Note that
     *         this function only accepts SetStorage and DeployImplementation actions.
     *         SetImplementation actions must be sent separately to `completeChugSplashBundle` after
     *         the SetStorage and DeployImplementation actions have been executed.
     *
     * @param _actions       Array of SetStorage/DeployImplementation actions to execute.
     * @param _actionIndexes Array of action indexes.
     * @param _proofs        Array of Merkle proofs for each action.
     */
    function executeMultipleActions(
        ChugSplashAction[] memory _actions,
        uint256[] memory _actionIndexes,
        bytes32[][] memory _proofs
    ) public {
        for (uint256 i = 0; i < _actions.length; i++) {
            executeChugSplashAction(_actions[i], _actionIndexes[i], _proofs[i]);
        }
    }

    /**
     * @notice Executes a specific action within the current active bundle for a project. Actions
     *         can only be executed once. A re-entrancy guard is added to prevent an implementation
     *         contract's constructor from calling another contract which in turn calls back into
     *         this function.
     *
     * @param _action      Action to execute.
     * @param _actionIndex Index of the action in the bundle.
     * @param _proof       Merkle proof of the action within the bundle.
     */
    function executeChugSplashAction(
        ChugSplashAction memory _action,
        uint256 _actionIndex,
        bytes32[] memory _proof
    ) public nonReentrant {
        uint256 initialGasLeft = gasleft();

        require(
            activeBundleId != bytes32(0),
            "ChugSplashManager: no bundle has been approved for execution"
        );

        ChugSplashBundleState storage bundle = _bundles[activeBundleId];

        require(
            bundle.executions[_actionIndex] == false,
            "ChugSplashManager: action has already been executed"
        );

        address executor = getSelectedExecutor(activeBundleId);
        require(
            executor == msg.sender,
            "ChugSplashManager: caller is not approved executor for active bundle ID"
        );

        require(
            MerkleTree.verify(
                bundle.merkleRoot,
                keccak256(abi.encode(_action.target, _action.actionType, _action.data)),
                _actionIndex,
                _proof,
                bundle.executions.length
            ),
            "ChugSplashManager: invalid bundle action proof"
        );

        // Get the proxy type and adapter for this target.
        bytes32 proxyType = proxyTypes[_action.target];
        address adapter = registry.adapters(proxyType);

        require(adapter != address(0), "ChugSplashManager: proxy type has no adapter");

        // Get the proxy to use for this target. The proxy can either be the default proxy used by
        // ChugSplash or a non-standard proxy that has previously been set by the project owner.
        address payable proxy;
        if (proxyType == bytes32(0)) {
            // Use a default proxy if this target has no proxy type assigned to it.

            // Make sure the proxy has code in it and deploy the proxy if it doesn't. Since we're
            // deploying via CREATE2, we can always correctly predict what the proxy address
            // *should* be and can therefore easily check if it's already populated.
            // TODO: See if there's a better way to handle this case because it messes with the gas
            // cost of DEPLOY_IMPLEMENTATION/SET_STORAGE operations in a somewhat unpredictable way.
            proxy = getDefaultProxyAddress(_action.target);
            if (proxy.code.length == 0) {
                bytes32 salt = keccak256(bytes(_action.target));
                Proxy created = new Proxy{ salt: salt }(address(this));

                // Could happen if insufficient gas is supplied to this transaction, should not
                // happen otherwise. If there's a situation in which this could happen other than a
                // standard OOG, then this would halt the entire contract.
                // TODO: Make sure this cannot happen in any case other than OOG.
                require(
                    address(created) == proxy,
                    "ChugSplashManager: Proxy was not created correctly"
                );

                emit DefaultProxyDeployed(_action.target, proxy, activeBundleId, _action.target);
                registry.announce("DefaultProxyDeployed");
            } else if (_getProxyImplementation(proxy, adapter) != address(0)) {
                // Set the proxy's implementation to address(0).
                _setProxyStorage(proxy, adapter, EIP1967_IMPLEMENTATION_KEY, bytes32(0));
            }
        } else {
            // We intend to support alternative proxy types in the future, but doing so requires
            // including additional checks to guarantee that actions will always executable. We will
            // re-enable the ability to use different proxy types once we have implemented those
            // additional checks.
            revert("ChugSplashManager: invalid proxy type, must be default proxy");
            // proxy = proxies[_action.target];
        }

        // Mark the action as executed and update the total number of executed actions.
        bundle.actionsExecuted++;
        bundle.executions[_actionIndex] = true;

        // Next, we execute the ChugSplash action by calling deployImplementation/setStorage.
        if (_action.actionType == ChugSplashActionType.DEPLOY_IMPLEMENTATION) {
            _deployImplementation(_action.target, _action.data);
        } else if (_action.actionType == ChugSplashActionType.SET_STORAGE) {
            (bytes32 key, bytes32 val) = abi.decode(_action.data, (bytes32, bytes32));
            _setProxyStorage(proxy, adapter, key, val);
        } else {
            revert("ChugSplashManager: attemped setImplementation action in wrong function");
        }

        emit ChugSplashActionExecuted(activeBundleId, msg.sender, _actionIndex);
        registry.announceWithData("ChugSplashActionExecuted", abi.encodePacked(proxy));

        // Estimate the amount of gas used in this call by subtracting the current gas left from the
        // initial gas left. We add 152778 to this amount to account for the intrinsic gas cost
        // (21k), the calldata usage, and the subsequent opcodes that occur when we add the
        // executorPayment to the totalDebt and debt. Unfortunately, there is a wide variance in the
        // gas costs of these last opcodes due to the variable cost of SSTORE. Also, gas refunds
        // might be contributing to the difficulty of getting a good estimate. For now, we err on
        // the side of safety by adding a larger value.
        // TODO: Get a better estimate than 152778.
        uint256 gasUsed = 152778 + initialGasLeft - gasleft();

        // Calculate the executor's payment and add it to the total debt and the current executor's
        // debt.
        uint256 executorPayment;
        if (block.chainid != 10 && block.chainid != 420) {
            // Use the basefee for any network that isn't Optimism.
            executorPayment = (block.basefee * gasUsed * (100 + executorPaymentPercentage)) / 100;
        } else if (block.chainid == 10) {
            // Optimism mainnet does not have the basefee opcode, so we hardcode its value here.
            executorPayment = (1000000 * gasUsed * (100 + executorPaymentPercentage)) / 100;
        } else {
            // Optimism goerli does not have the basefee opcode, so we hardcode its value here.
            executorPayment = (gasUsed * (100 + executorPaymentPercentage)) / 100;
        }

        totalDebt += executorPayment;
        debt[msg.sender] += executorPayment;
    }

    /**
     * @notice Completes the bundle by executing all SetImplementation actions. This occurs in a
     *         single transaction to ensure that all contracts are initialized at the same time.
     *         Note that this function will revert if it is called before all of the SetCode and
     *         DeployImplementation actions have been executed in `executeChugSplashAction`.
     *
     * @param _actions       Array of ChugSplashActions, where each action type must be
     *                       `SET_IMPLEMENTATION`.
     * @param _actionIndexes Array of action indexes.
     * @param _proofs        Array of Merkle proofs.
     */
    function completeChugSplashBundle(
        ChugSplashAction[] memory _actions,
        uint256[] memory _actionIndexes,
        bytes32[][] memory _proofs
    ) public {
        uint256 initialGasLeft = gasleft();

        require(
            activeBundleId != bytes32(0),
            "ChugSplashManager: no bundle has been approved for execution"
        );

        address executor = getSelectedExecutor(activeBundleId);
        require(
            executor == msg.sender,
            "ChugSplashManager: caller is not approved executor for active bundle ID"
        );

        ChugSplashBundleState storage bundle = _bundles[activeBundleId];

        for (uint256 i = 0; i < _actions.length; i++) {
            ChugSplashAction memory action = _actions[i];
            uint256 actionIndex = _actionIndexes[i];
            bytes32[] memory proof = _proofs[i];

            require(
                bundle.executions[actionIndex] == false,
                "ChugSplashManager: action has already been executed"
            );

            require(
                MerkleTree.verify(
                    bundle.merkleRoot,
                    keccak256(abi.encode(action.target, action.actionType, action.data)),
                    actionIndex,
                    proof,
                    bundle.executions.length
                ),
                "ChugSplashManager: invalid bundle action proof"
            );

            // Mark the action as executed and update the total number of executed actions.
            bundle.actionsExecuted++;
            bundle.executions[actionIndex] = true;

            // Get the implementation address using the salt as its key.
            address implementation = implementations[
                keccak256(abi.encode(activeBundleId, bytes(action.target)))
            ];

            // Get the proxy and adapter that correspond to this target.
            address payable proxy = getDefaultProxyAddress(action.target);
            bytes32 proxyType = proxyTypes[action.target];
            address adapter = registry.adapters(proxyType);

            // Upgrade the proxy's implementation contract.
            _upgradeProxyTo(proxy, adapter, implementation);

            emit ChugSplashActionExecuted(activeBundleId, msg.sender, actionIndex);
            registry.announceWithData("ChugSplashActionExecuted", abi.encodePacked(proxy));
        }

        require(
            bundle.actionsExecuted == bundle.executions.length,
            "ChugSplashManager: bundle was not completed"
        );

        // If all actions have been executed, then we can complete the bundle. Mark the bundle as
        // completed and reset the active bundle hash so that a new bundle can be executed.
        bundle.status = ChugSplashBundleStatus.COMPLETED;
        bytes32 completedBundleId = activeBundleId;
        activeBundleId = bytes32(0);

        emit ChugSplashBundleCompleted(completedBundleId, msg.sender, bundle.actionsExecuted);
        registry.announce("ChugSplashBundleCompleted");

        // See the explanation in `executeChugSplashAction`.
        uint256 gasUsed = 152778 + initialGasLeft - gasleft();

        // Calculate the executor's payment.
        uint256 executorPayment;
        if (block.chainid != 10 && block.chainid != 420) {
            // Use the basefee for any network that isn't Optimism.
            executorPayment = (block.basefee * gasUsed * (100 + executorPaymentPercentage)) / 100;
        } else if (block.chainid == 10) {
            // Optimism mainnet does not have the basefee opcode, so we hardcode its value here.
            executorPayment = (1000000 * gasUsed * (100 + executorPaymentPercentage)) / 100;
        } else {
            // Optimism goerli does not have the basefee opcode, so we hardcode its value here.
            executorPayment = (gasUsed * (100 + executorPaymentPercentage)) / 100;
        }

        // Add the executor's payment to the total debt.
        totalDebt += executorPayment;
        // Add the executor's payment and the executor's bond to their debt.
        debt[msg.sender] += executorPayment + executorBondAmount;
    }

    /**
     * @notice **WARNING**: Cancellation is a potentially dangerous action and should not be
     *         executed unless in an emergency.
     *
     *         Cancels an active ChugSplash bundle. If an executor has not claimed the bundle,
     *         the owner is simply allowed to withdraw their bond via a subsequent call to
     *         `withdrawOwnerETH`. Otherwise, cancelling a bundle will cause the project owner to
     *         forfeit their bond to the executor, and will also allow the executor to refund their
     *         own bond.
     */
    function cancelActiveChugSplashBundle() public onlyOwner {
        require(activeBundleId != bytes32(0), "ChugSplashManager: no bundle is currently active");

        ChugSplashBundleState storage bundle = _bundles[activeBundleId];

        if (bundle.selectedExecutor != address(0)) {
            if (bundle.timeClaimed + executionLockTime >= block.timestamp) {
                // Give the owner's bond to the current executor if the bundle is cancelled within
                // the `executionLockTime` window. Also return the executor's bond.
                debt[bundle.selectedExecutor] += ownerBondAmount + executorBondAmount;
                // We don't add the `executorBondAmount` to the `totalDebt` here because we already
                // did this in `claimBundle`.
                totalDebt += ownerBondAmount;
            } else {
                // Give the executor's bond to the owner if the `executionLockTime` window has
                // passed.
                totalDebt -= executorBondAmount;
            }
        }

        bytes32 cancelledBundleId = activeBundleId;
        activeBundleId = bytes32(0);
        bundle.status = ChugSplashBundleStatus.CANCELLED;

        emit ChugSplashBundleCancelled(cancelledBundleId, msg.sender, bundle.actionsExecuted);
        registry.announce("ChugSplashBundleCancelled");
    }

    /**
     * @notice Allows an executor to post a bond of `executorBondAmount` to claim the sole right to
     *         execute actions for a bundle over a period of `executionLockTime`. Only the first
     *         executor to post a bond gains this right. Executors must finish executing the bundle
     *         within `executionLockTime` or else their bond is forfeited to this contract and
     *         another executor may claim the bundle. Note that this strategy creates a PGA for the
     *         transaction to claim the bundle but removes PGAs during the execution process.
     */
    function claimBundle() external payable {
        require(activeBundleId != bytes32(0), "ChugSplashManager: no bundle is currently active");
        require(
            executorBondAmount == msg.value,
            "ChugSplashManager: incorrect executor bond amount"
        );

        ChugSplashBundleState storage bundle = _bundles[activeBundleId];

        require(
            block.timestamp > bundle.timeClaimed + executionLockTime,
            "ChugSplashManager: bundle is currently claimed by an executor"
        );

        address prevExecutor = bundle.selectedExecutor;
        bundle.timeClaimed = block.timestamp;
        bundle.selectedExecutor = msg.sender;

        // Add the new executor's bond to the `totalDebt` if there was no previous executor. We skip
        // this if there was a previous executor because this allows the owner to claim the previous
        // executor's forfeited bond.
        if (prevExecutor == address(0)) {
            totalDebt += executorBondAmount;
        }

        emit ChugSplashBundleClaimed(activeBundleId, msg.sender);
        registry.announce("ChugSplashBundleClaimed");
    }

    /**
     * @notice Allows executors to claim their ETH payments and bond. Executors may only withdraw
     *         ETH that is owed to them by this contract.
     */
    function claimExecutorPayment() external {
        uint256 amount = debt[msg.sender];

        debt[msg.sender] -= amount;
        totalDebt -= amount;

        (bool success, ) = payable(msg.sender).call{ value: amount }(new bytes(0));
        require(success, "ChugSplashManager: call to withdraw owner funds failed");

        emit ExecutorPaymentClaimed(msg.sender, amount);
        registry.announce("ExecutorPaymentClaimed");
    }

    /**
     * @notice Transfers ownership of a proxy from this contract to the project owner.
     *
     * @param _target   Target that corresponds to the proxy.
     * @param _newOwner Address of the project owner that is receiving ownership of the proxy.
     */
    function transferProxyOwnership(string memory _target, address _newOwner) public onlyOwner {
        require(activeBundleId == bytes32(0), "ChugSplashManager: bundle is currently active");

        // Get the proxy type that corresponds to this target.
        bytes32 proxyType = proxyTypes[_target];
        address payable proxy;
        if (proxyType == bytes32(0)) {
            // Use a default proxy if no proxy type has been set by the project owner.
            proxy = getDefaultProxyAddress(_target);
        } else {
            // We revert here since we currently do not support custom proxy types.
            revert("ChugSplashManager: invalid proxy type, must be default proxy");
            // proxy = proxies[_name];
        }

        // Get the adapter that corresponds to this proxy type.
        address adapter = registry.adapters(proxyType);

        // Delegatecall the adapter to change ownership of the proxy.
        (bool success, ) = adapter.delegatecall(
            abi.encodeCall(IProxyAdapter.changeProxyAdmin, (proxy, _newOwner))
        );
        require(success, "ChugSplashManager: delegatecall to change proxy admin failed");

        emit ProxyOwnershipTransferred(_target, proxy, proxyType, _newOwner, _target);
        registry.announce("ProxyOwnershipTransferred");
    }

    /**
     * @notice Allows the project owner to withdraw all funds in this contract minus the total debt
     *         owed to the executors. Cannot be called when there is an active bundle.
     */
    function withdrawOwnerETH() external onlyOwner {
        require(
            activeBundleId == bytes32(0),
            "ChugSplashManager: cannot withdraw funds while bundle is active"
        );

        uint256 amount = address(this).balance - totalDebt;
        (bool success, ) = payable(msg.sender).call{ value: amount }(new bytes(0));
        require(success, "ChugSplashManager: call to withdraw owner funds failed");

        emit OwnerWithdrewETH(msg.sender, amount);
        registry.announce("OwnerWithdrewETH");
    }

    /**
     * @notice Allows the owner of this contract to add a proposer.
     *
     * @param _proposer Address of the proposer to add.
     */
    function addProposer(address _proposer) external onlyOwner {
        require(proposers[_proposer] == false, "ChugSplashManager: proposer was already added");

        proposers[_proposer] = true;

        emit ProposerAdded(_proposer, msg.sender);
        registry.announce("ProposerAdded");
    }

    /**
     * @notice Allows the owner of this contract to remove a proposer.
     *
     * @param _proposer Address of the proposer to remove.
     */
    function removeProposer(address _proposer) external onlyOwner {
        require(proposers[_proposer] == true, "ChugSplashManager: proposer was already removed");

        proposers[_proposer] = false;

        emit ProposerRemoved(_proposer, msg.sender);
        registry.announce("ProposerRemoved");
    }

    /**
     * @notice Allows anyone to send ETH to this contract.
     */
    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
        registry.announce("ETHDeposited");
    }

    /**
     * @notice Deploys an implementation contract, which will later be set as the proxy's
     *         implementation address. Note that we wait to set the proxy's implementation address
     *         until the very last call of the bundle to avoid a situation where end-users are
     *         interacting with a proxy whose storage has not fully been initialized.
     *
     * @param _target Target that corresponds to the implementation.
     * @param _code   Creation bytecode of the implementation contract.
     */
    function _deployImplementation(string memory _target, bytes memory _code) internal {
        // Calculate the salt for the Create2 call. This salt ensures that there are no address
        // collisions since each bundle ID can only be executed once, and each target is unique
        // within that bundle.
        bytes32 salt = keccak256(abi.encode(activeBundleId, bytes(_target)));

        // Get the expected address of the implementation contract.
        address expectedImplementation = Create2.compute(address(this), salt, _code);

        address implementation;
        assembly {
            implementation := create2(0x0, add(_code, 0x20), mload(_code), salt)
        }

        // Could happen if insufficient gas is supplied to this transaction, should not
        // happen otherwise. If there's a situation in which this could happen other than a
        // standard OOG, then this would halt the entire contract.
        // TODO: Make sure this cannot happen in any case other than OOG.
        require(
            expectedImplementation == implementation,
            "ChugSplashManager: implementation was not deployed correctly"
        );

        // Map the implementation's salt to its newly deployed address.
        implementations[salt] = implementation;

        emit ImplementationDeployed(_target, implementation, activeBundleId, _target);
        registry.announce("ImplementationDeployed");
    }

    /**
     * @notice Modifies a storage slot within the proxy contract.
     *
     * @param _proxy     Address of the proxy.
     * @param _adapter   Address of the adapter for this proxy.
     * @param _key       Storage key to modify.
     * @param _value     New value for the storage key.
     */
    function _setProxyStorage(
        address payable _proxy,
        address _adapter,
        bytes32 _key,
        bytes32 _value
    ) internal {
        // Delegatecall the adapter to upgrade the proxy's implementation to be the ProxyUpdater,
        // which has the `setStorage` function.
        _upgradeProxyTo(_proxy, _adapter, proxyUpdater);

        // Call the `setStorage` action on the proxy.
        (bool success, ) = _proxy.call(abi.encodeCall(ProxyUpdater.setStorage, (_key, _value)));
        require(success, "ChugSplashManager: call to set proxy storage failed");

        // Delegatecall the adapter to set the proxy's implementation back to address(0).
        _upgradeProxyTo(_proxy, _adapter, address(0));
    }

    /**
     * @notice Delegatecalls an adapter to get the address of the proxy's implementation contract.
     *
     * @param _proxy   Address of the proxy.
     * @param _adapter Address of the adapter to use for the proxy.
     */
    function _getProxyImplementation(
        address payable _proxy,
        address _adapter
    ) internal returns (address) {
        (bool success, bytes memory implementationBytes) = _adapter.delegatecall(
            abi.encodeCall(IProxyAdapter.getProxyImplementation, (_proxy))
        );
        require(success, "ChugSplashManager: delegatecall to get proxy implementation failed");

        // Convert the implementation's type from bytes to address.
        address implementation;
        assembly {
            implementation := mload(add(implementationBytes, 32))
        }
        return implementation;
    }

    /**
     * @notice Delegatecalls an adapter to upgrade a proxy's implementation contract.
     *
     * @param _proxy          Address of the proxy to upgrade.
     * @param _adapter        Address of the adapter to use for the proxy.
     * @param _implementation Address to set as the proxy's new implementation contract.
     */
    function _upgradeProxyTo(
        address payable _proxy,
        address _adapter,
        address _implementation
    ) internal {
        (bool success, ) = _adapter.delegatecall(
            abi.encodeCall(IProxyAdapter.upgradeProxyTo, (_proxy, _implementation))
        );
        require(success, "ChugSplashManager: delegatecall to upgrade proxy failed");
    }

    /**
     * @notice Gets the code hash for a given account.
     *
     * @param _account Address of the account to get a code hash for.
     *
     * @return Code hash for the account.
     */
    function _getAccountCodeHash(address _account) internal view returns (bytes32) {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(_account)
        }
        return codeHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Proxy } from "./libraries/Proxy.sol";
import { ChugSplashRegistry } from "./ChugSplashRegistry.sol";

/**
 * @title ChugSplashManagerProxy
 */
contract ChugSplashManagerProxy is Proxy {
    /**
     * @notice Address of the ChugSplashRegistry.
     */
    ChugSplashRegistry public immutable registryProxy;

    /**
     * @param _registryProxy The ChugSplashRegistry's proxy.
     * @param _admin         Owner of this contract.
     */
    constructor(ChugSplashRegistry _registryProxy, address _admin) payable Proxy(_admin) {
        registryProxy = _registryProxy;
    }

    /**
     * @notice The implementation contract for this proxy is stored in the ChugSplashRegistry's
     *         proxy.
     */
    function _getImplementation() internal view override returns (address) {
        return registryProxy.managerImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ChugSplashManager } from "./ChugSplashManager.sol";
import { ChugSplashManagerProxy } from "./ChugSplashManagerProxy.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Proxy } from "./libraries/Proxy.sol";

/**
 * @title ChugSplashRegistry
 * @notice The ChugSplashRegistry is the root contract for the ChugSplash deployment system. All
 *         deployments must be first registered with this contract, which allows clients to easily
 *         find and index these deployments. Deployment names are unique and are reserved on a
 *         first-come, first-served basis.
 */
contract ChugSplashRegistry is Initializable {
    /**
     * @notice Emitted whenever a new project is registered.
     *
     * @param projectNameHash Hash of the project name. Without this parameter, we
     *                        won't be able to recover the unhashed project name in
     *                        events, since indexed dynamic types like strings are hashed.
     *                        For further explanation:
     *                        https://github.com/ethers-io/ethers.js/issues/243
     * @param creator         Address of the creator of the project.
     * @param manager         Address of the ChugSplashManager for this project.
     * @param owner           Address of the initial owner of the project.
     * @param projectName     Name of the project that was registered.
     */
    event ChugSplashProjectRegistered(
        string indexed projectNameHash,
        address indexed creator,
        address indexed manager,
        address owner,
        string projectName
    );

    /**
     * @notice Emitted whenever a ChugSplashManager contract wishes to announce an event on the
     *         registry. We use this to avoid needing a complex indexing system when we're trying
     *         to find events emitted by the various manager contracts.
     *
     * @param eventNameHash Hash of the name of the event being announced.
     * @param manager       Address of the ChugSplashManager announcing an event.
     * @param eventName     Name of the event being announced.
     */
    event EventAnnounced(string indexed eventNameHash, address indexed manager, string eventName);

    /**
     * @notice Emitted whenever a ChugSplashManager contract wishes to announce an event on the
     *         registry, including a field for arbitrary data. We use this to avoid needing a
     *         complex indexing system when we're trying to find events emitted by the various
     *         manager contracts.
     *
     * @param eventNameHash Hash of the name of the event being announced.
     * @param manager       Address of the ChugSplashManager announcing an event.
     * @param dataHash      Hash of the extra data.
     * @param eventName     Name of the event being announced.
     * @param data          The extra data.
     */
    event EventAnnouncedWithData(
        string indexed eventNameHash,
        address indexed manager,
        bytes indexed dataHash,
        string eventName,
        bytes data
    );

    /**
     * @notice Emitted whenever a new proxy type is added.
     *
     * @param proxyType Hash representing the proxy type.
     * @param adapter   Address of the adapter for the proxy.
     */
    event ProxyTypeAdded(bytes32 proxyType, address adapter);

    /**
     * @notice Mapping of project names to ChugSplashManager contracts.
     */
    mapping(string => ChugSplashManager) public projects;

    /**
     * @notice Mapping of created manager contracts.
     */
    mapping(ChugSplashManager => bool) public managers;

    /**
     * @notice Mapping of proxy types to adapters.
     */
    mapping(bytes32 => address) public adapters;

    /**
     * @notice Address of the ProxyUpdater.
     */
    address public immutable proxyUpdater;

    /**
     * @notice Amount that must be deposited in the ChugSplashManager in order to execute a bundle.
     */
    uint256 public immutable ownerBondAmount;

    /**
     * @notice Amount that an executor must send to the ChugSplashManager to claim a bundle.
     */
    uint256 public immutable executorBondAmount;

    /**
     * @notice Amount of time for an executor to completely execute a bundle after claiming it.
     */
    uint256 public immutable executionLockTime;

    /**
     * @notice Amount that executors are paid, denominated as a percentage of the cost of execution.
     */
    uint256 public immutable executorPaymentPercentage;

    /**
     * @notice Address of the ChugSplashManager implementation contract.
     */
    // TODO: Remove once this contract is not upgradeable anymore.
    address public immutable managerImplementation;

    /**
     * @param _proxyUpdater              Address of the ProxyUpdater.
     * @param _ownerBondAmount           Amount that must be deposited in the ChugSplashManager in
     *                                   order to execute a bundle.
     * @param _executorBondAmount        Amount that an executor must send to the ChugSplashManager
     *                                   to claim a bundle.
     * @param _executionLockTime         Amount of time for an executor to completely execute a
     *                                   bundle after claiming it.
     * @param _executorPaymentPercentage Amount that an executor will earn from completing a bundle,
     *                                   denominated as a percentage.
     * @param _managerImplementation     Address of the ChugSplashManager implementation contract.
     */
    constructor(
        address _proxyUpdater,
        uint256 _ownerBondAmount,
        uint256 _executorBondAmount,
        uint256 _executionLockTime,
        uint256 _executorPaymentPercentage,
        address _managerImplementation
    ) {
        proxyUpdater = _proxyUpdater;
        ownerBondAmount = _ownerBondAmount;
        executorBondAmount = _executorBondAmount;
        executionLockTime = _executionLockTime;
        executorPaymentPercentage = _executorPaymentPercentage;
        managerImplementation = _managerImplementation;
    }

    /**
     * @notice Registers a new project.
     *
     * @param _name  Name of the new ChugSplash project.
     * @param _owner Initial owner for the new project.
     */
    function register(string memory _name, address _owner) public {
        require(
            address(projects[_name]) == address(0),
            "ChugSplashRegistry: name already registered"
        );

        // Deploy the ChugSplashManager's proxy.
        ChugSplashManagerProxy manager = new ChugSplashManagerProxy{
            salt: keccak256(bytes(_name))
        }(
            this, // This will be the Registry's proxy address since the Registry will be
            // delegatecalled by the proxy.
            address(this)
        );
        // Initialize the proxy. Note that we initialize it in a different call from the deployment
        // because this makes it easy to calculate the Create2 address off-chain before it is
        // deployed.
        manager.upgradeToAndCall(
            managerImplementation,
            abi.encodeCall(ChugSplashManager.initialize, (_name, _owner))
        );

        projects[_name] = ChugSplashManager(payable(address(manager)));
        managers[ChugSplashManager(payable(address(manager)))] = true;

        emit ChugSplashProjectRegistered(_name, msg.sender, address(manager), _owner, _name);
    }

    /**
     * @notice Allows ChugSplashManager contracts to announce events.
     *
     * @param _event Name of the event to announce.
     */
    function announce(string memory _event) public {
        require(
            managers[ChugSplashManager(payable(msg.sender))] == true,
            "ChugSplashRegistry: events can only be announced by ChugSplashManager contracts"
        );

        emit EventAnnounced(_event, msg.sender, _event);
    }

    /**
     * @notice Allows ChugSplashManager contracts to announce events, including a field for
     *         arbitrary data.
     *
     * @param _event Name of the event to announce.
     * @param _data  Arbitrary data to include in the announced event.
     */
    function announceWithData(string memory _event, bytes memory _data) public {
        require(
            managers[ChugSplashManager(payable(msg.sender))] == true,
            "ChugSplashRegistry: events can only be announced by ChugSplashManager contracts"
        );

        emit EventAnnouncedWithData(_event, msg.sender, _data, _event, _data);
    }

    /**
     * @notice Adds a new proxy type with a corresponding adapter, which can be used to upgrade a
     *         custom proxy.
     *
     * @param _proxyType Hash representing the proxy type
     * @param _adapter   Address of the adapter for this proxy type.
     */
    function addProxyType(bytes32 _proxyType, address _adapter) external {
        require(
            adapters[_proxyType] == address(0),
            "ChugSplashRegistry: proxy type has an existing adapter"
        );
        adapters[_proxyType] = _adapter;

        emit ProxyTypeAdded(_proxyType, _adapter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IProxyAdapter
 * @notice Interface that must be inherited by each adapter.
 */
interface IProxyAdapter {
    /**
     * @notice Returns the current implementation of the proxy.
     *
     * @param _proxy Address of the proxy.
     */
    function getProxyImplementation(address payable _proxy) external returns (address);

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * @param _proxy          Address of the proxy.
     * @param _implementation Address of the new implementation.
     */
    function upgradeProxyTo(address payable _proxy, address _implementation) external;

    /**
     * @notice Changes the admin of the proxy.
     *
     * @param _proxy    Address of the proxy.
     * @param _newAdmin Address of the new admin.
     */
    function changeProxyAdmin(address payable _proxy, address _newAdmin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Create2
 * @notice Simple library for computing CREATE2 addresses.
 */
library Create2 {
    /**
     * @notice Computes the CREATE2 address for the given parameters.
     *
     * @param _creator  Address executing the CREATE2 instruction.
     * @param _salt     32 byte salt passed to the CREATE2 instruction.
     * @param _bytecode Initcode for the contract creation.
     *
     * @return Predicted address of the created contract.
     */
    function compute(
        address _creator,
        bytes32 _salt,
        bytes memory _bytecode
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(bytes1(0xff), _creator, _salt, keccak256(_bytecode))
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @custom:attribution https://github.com/ethereum-optimism/optimism
 * @title MerkleTree
 * @notice Simple Merkle tree implementation, supports up to 2^16 leaves.
 */
library MerkleTree {
    /**
     * @notice Calculates a merkle root for a list of 32-byte leaf hashes.
     *         NOTE: If the number of leaves passed in is not a power of two, it pads out the
     *         tree with zero hashes. If you do not know the original length of elements for the
     *         tree you are verifying, then this may allow empty leaves past _elements.length to
     *         pass a verification check down the line.
     *         NOTE: The _elements argument is modified, therefore it must not be used again.
     *
     * @param _elements Array of hashes from which to generate a merkle root.
     *
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(bytes32[] memory _elements) internal pure returns (bytes32) {
        require(_elements.length > 0, "MerkleTree: must provide at least one leaf hash");

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize; // rowSize / 2
        bool rowSizeIsOdd; // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling = _elements[(2 * i)];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * @notice Verifies a merkle branch for the given leaf hash. Assumes the original length of
     *         leaves generated is a known, correct input, and does not return true for indices
     *         extending past that index (even if _siblings would be otherwise valid).
     *
     * @param _root        The Merkle root to verify against.
     * @param _leaf        The leaf hash to verify inclusion of.
     * @param _index       The index in the tree of this leaf.
     * @param _siblings    Array of sibline nodes in the inclusion proof, starting from depth 0.
     * @param _totalLeaves The total number of leaves originally passed into.
     *
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    ) internal pure returns (bool) {
        require(_totalLeaves > 0, "MerkleTree: total leaves must be greater than zero");
        require(_index < _totalLeaves, "MerkleTree: index out of bounds");
        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "MerkleTree: total siblings does not correctly correspond to total leaves"
        );

        bytes32 computedRoot = _leaf;
        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings[i]));
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }

    /**
     * @notice Calculates the integer ceiling of the log base 2 of an input.
     *
     * @param _in Unsigned input to calculate the log.
     *
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(uint256 _in) private pure returns (uint256) {
        require(_in > 0, "Lib_MerkleTree: Cannot compute ceil(log_2) of 0.");

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((uint256(1) << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint256(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title Proxy
 * @notice Proxy is a transparent proxy that passes through the call if the caller is the owner or
 *         if the caller is address(0), meaning that the call originated from an off-chain
 *         simulation.
 */
contract Proxy {
    /**
     * @notice The storage slot that holds the address of the implementation.
     *         bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 internal constant IMPLEMENTATION_KEY =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice The storage slot that holds the address of the owner.
     *         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice An event that is emitted each time the implementation is changed. This event is part
     *         of the EIP-1967 specification.
     *
     * @param implementation The address of the implementation contract
     */
    event Upgraded(address indexed implementation);

    /**
     * @notice An event that is emitted each time the owner is upgraded. This event is part of the
     *         EIP-1967 specification.
     *
     * @param previousAdmin The previous owner of the contract
     * @param newAdmin      The new owner of the contract
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @notice A modifier that reverts if not called by the owner or by address(0) to allow
     *         eth_call to interact with this proxy without needing to use low-level storage
     *         inspection. We assume that nobody is able to trigger calls from address(0) during
     *         normal EVM execution.
     */
    modifier proxyCallIfNotAdmin() {
        if (msg.sender == _getAdmin() || msg.sender == address(0)) {
            _;
        } else {
            // This WILL halt the call frame on completion.
            _doProxyCall();
        }
    }

    /**
     * @notice Sets the initial admin during contract deployment. Admin address is stored at the
     *         EIP-1967 admin storage slot so that accidental storage collision with the
     *         implementation is not possible.
     *
     * @param _admin Address of the initial contract admin. Admin as the ability to access the
     *               transparent proxy interface.
     */
    constructor(address _admin) {
        _changeAdmin(_admin);
    }

    // slither-disable-next-line locked-ether
    receive() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    // slither-disable-next-line locked-ether
    fallback() external payable {
        // Proxy call by default.
        _doProxyCall();
    }

    /**
     * @notice Set the implementation contract address. The code at the given address will execute
     *         when this contract is called.
     *
     * @param _implementation Address of the implementation contract.
     */
    function upgradeTo(address _implementation) external proxyCallIfNotAdmin {
        _setImplementation(_implementation);
    }

    /**
     * @notice Set the implementation and call a function in a single transaction. Useful to ensure
     *         atomic execution of initialization-based upgrades.
     *
     * @param _implementation Address of the implementation contract.
     * @param _data           Calldata to delegatecall the new implementation with.
     */
    function upgradeToAndCall(
        address _implementation,
        bytes calldata _data
    ) external payable proxyCallIfNotAdmin returns (bytes memory) {
        _setImplementation(_implementation);
        (bool success, bytes memory returndata) = _implementation.delegatecall(_data);
        require(success, "Proxy: delegatecall to new implementation contract failed");
        return returndata;
    }

    /**
     * @notice Changes the owner of the proxy contract. Only callable by the owner.
     *
     * @param _admin New owner of the proxy contract.
     */
    function changeAdmin(address _admin) external proxyCallIfNotAdmin {
        _changeAdmin(_admin);
    }

    /**
     * @notice Gets the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function admin() external proxyCallIfNotAdmin returns (address) {
        return _getAdmin();
    }

    /**
     * @notice Queries the implementation address.
     *
     * @return Implementation address.
     */
    function implementation() external proxyCallIfNotAdmin returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Sets the implementation address.
     *
     * @param _implementation New implementation address.
     */
    function _setImplementation(address _implementation) internal {
        assembly {
            sstore(IMPLEMENTATION_KEY, _implementation)
        }
        emit Upgraded(_implementation);
    }

    /**
     * @notice Changes the owner of the proxy contract.
     *
     * @param _admin New owner of the proxy contract.
     */
    function _changeAdmin(address _admin) internal {
        address previous = _getAdmin();
        assembly {
            sstore(OWNER_KEY, _admin)
        }
        emit AdminChanged(previous, _admin);
    }

    /**
     * @notice Performs the proxy call via a delegatecall.
     */
    function _doProxyCall() internal {
        address impl = _getImplementation();
        require(impl != address(0), "Proxy: implementation not initialized");

        assembly {
            // Copy calldata into memory at 0x0....calldatasize.
            calldatacopy(0x0, 0x0, calldatasize())

            // Perform the delegatecall, make sure to pass all available gas.
            let success := delegatecall(gas(), impl, 0x0, calldatasize(), 0x0, 0x0)

            // Copy returndata into memory at 0x0....returndatasize. Note that this *will*
            // overwrite the calldata that we just copied into memory but that doesn't really
            // matter because we'll be returning in a second anyway.
            returndatacopy(0x0, 0x0, returndatasize())

            // Success == 0 means a revert. We'll revert too and pass the data up.
            if iszero(success) {
                revert(0x0, returndatasize())
            }

            // Otherwise we'll just return and pass the data up.
            return(0x0, returndatasize())
        }
    }

    /**
     * @notice Queries the implementation address.
     *
     * @return Implementation address.
     */
    function _getImplementation() internal view virtual returns (address) {
        address impl;
        assembly {
            impl := sload(IMPLEMENTATION_KEY)
        }
        return impl;
    }

    /**
     * @notice Queries the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function _getAdmin() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ProxyUpdater
 * @notice The ProxyUpdater contains the logic that sets storage slots within the proxy contract
 *         when an action is executed in the ChugSplashManager. When a `setStorage` action is
 *         executed, the ChugSplashManager temporarily sets the proxy's implementation to be this
 *         contract so that the proxy can delegatecall into it.
 */
contract ProxyUpdater {
    /**
     * @notice Modifies some storage slot within the proxy contract. Gives us a lot of power to
     *         perform upgrades in a more transparent way.
     *
     * @param _key   Storage key to modify.
     * @param _value New value for the storage key.
     */
    function setStorage(bytes32 _key, bytes32 _value) external {
        assembly {
            sstore(_key, _value)
        }
    }
}