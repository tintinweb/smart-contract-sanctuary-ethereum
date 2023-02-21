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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title The Dog Money auction house

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓██████████████▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓███████████▓▓▓▓▓▓▓▓███████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░▒▓██████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓███████▓▒░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▒▓█████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓█████▓▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░▒▓████▓▓▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓████▓▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▒████▓▓▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▓▓████▒░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▓████▓▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▓████▓░░░░░░░░░░░░░
░░░░░░░░░░░▒███▓▓▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▓▓███▓░░░░░░░░░░░
░░░░░░░░░▒████▓▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▓▓███▒░░░░░░░░░
░░░░░░░░▓███▓▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▓▓▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▓▓▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▓███▓░░░░░░░░
░░░░░░░███▓▒▒▒▒▒░░▒▒▒▒▒▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████▓▒▒▒▒▒▒▒░░▒▒▒▒▒▓███░░░░░░░
░░░░░▒███▓▒▒▒▒░░▒▒▒▒▒▓█████████████████████████████████████████████▓▒▒▒▒▒▒░░▒▒▒▒▓███▒░░░░░
░░░░▒███▓▒▒▒▒░░▒▒▒▓█████████████████▓▓▓▓██████████▓▓▓██████████████████▒▒▒▒░░▒▒▒▒▓███▒░░░░
░░░░███▓▒▒▒▒░░▒▓████████████████████████▒███████▓▒████████████████████████▒▒░░▒▒▒▒▓███▒░░░
░░░███▓▒▒▒▒▒▓████████████████████████████▓██████▒████████████████████████████▓░▒▒▒▒▓███░░░
░░▓██▓▒▒▒▒██████████████████████████████████████████████████████████████████████░▒▒▒▓███░░
░▒███▒▒▒▒▒█████████████████████████▓██████████████████▓█████████████████████████░▒▒▒▒███▒░
░███▓▒▒▒▒░▒████████████████▓███▓▓████████████████████▓███▓▒███▓████████████████░░▒▒▒▒▓███░
▒███▒▒▒▒░▒▒░██████████████▓██████▓▓▓██████████████████▓▓▓██████▓█████████████▓░▒▒░▒▒▒▒███▒
▓██▓▒▒▒▒░▒▒▒░████████████▓██████████████████████████████████████▓███████████▓░▒▒▒░▒▒▒▒▓██▓
███▓▒▒▒▒░▒▒▒▒░██████████▒███████████▓███████████████▓▓███████████▓█████████▓░▒▒▒▒░░▒▒▒▒███
███▒▒▒▒░░▒▒▒▒▒░▓███████▒█████▓█████▓██████████████████▓████▓▓█████▓███████▒░▒▒▒▒▒░░▒▒▒▒███
███▒▒▒▒░░▒▒▒▒▒▒░▓█████▒███████▒██▓▓████▓▓▓▓████▓▓▓▓████▓▓██▒██████▓▓█████▒▒▒▒▒▒▒▒░░▒▒▒▒███
███▒▒▒▒░░▒▒▒▒▒▒▒░▓███▒▓█████████▒█████▓▓██████████▒██████▒█████████▓▓███▒▒▒▒▒▒▒▒▒░░▒▒▒▒███
███▓▒▒▒▒░▒▒▒▒▒▒▒▒░▒▓▒▒█████████▒███████▒█▓█▓██▓█▓█▒███████▒█████████░▒▓▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒███
▓██▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒░▓████████▒████████▓▓▓▒██▒▓▓▓████████▒████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓██▓
▒███▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░████████░████████████▒▓████████████▒███████▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒███▒
░███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░███████▓▓███████████▓▓███████████▒███████▓░▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███░
░▒███▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████▒▓██████████▒▓██████████▓▓███████░▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒███▒░
░░███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░████████▒▓████████▓▓▓▓████████▓▒████████░▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███░░
░░░███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒░▓█████████▓▓█████▓▒████▒▓█████▒▓█████████░▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███░░░
░░░▒███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒░░████████████▒▓▓▒▒████████▒▒▓▓▒███████████▒░░▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███▒░░░
░░░░▒███▓▒▒▒▒░░▒▒▒▒▒▒░░▒▒▒▓██████████▓██▓▓▓▓▓▓▓▓▓▓██▓█████████▓▓▒▒▒░▒▒▒▒▒▒▒░░▒▒▒▒▓███▒░░░░
░░░░░▒███▓▒▒▒▒░░▒▒▒▒▒░▒▒▒▒▒▒▒▒▓████████████████████████████▓▒▒▒▒▒▒▒░░▒▒▒▒▒░░▒▒▒▒▓███▒░░░░░
░░░░░░░███▓▒▒▒▒▒░░▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▓▓██████████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒░░▒▒▒▒▒▓███░░░░░░░
░░░░░░░░▓███▓▒▒▒▒▒░▒▒░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒░▒▒▒▒▒▓███▓░░░░░░░░
░░░░░░░░░▒████▓▒▒▒▒▒░░████▓▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▓████░░▒▒▒▒▒▓▓███▒░░░░░░░░░
░░░░░░░░░░░▓███▓▓▒▒▒▒▒░▒▓████▓▓▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▓█████▓▒░▒▒▒▒▒▓▓███▓░░░░░░░░░░░
░░░░░░░░░░░░░▓████▓▒▒▒▒▒▒░▒▓███████▓▓▒▒▒░▒▒▒▒▒▒▒▒▒░▒▓▓▓███████▓▒░▒▒▒▒▒▒▓▓███▓░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▒████▓▓▒▒▒▒▒▒░░▒▓███████▓▓▓▓▓▓▓▓▓▓▓████████▓▒▒░▒▒▒▒▒▒▒▓████▓░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░▒▓████▓▓▒▒▒▒▒▒▒▒░▒▒▒▒▓▓▓████████▓▓▓▒▒▒▒░▒▒▒▒▒▒▒▒▓▓████▓▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▒▓█████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓█████▓▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▒▓███████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓██████▓▒░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓███████████▓▓▓▓▓▓▓▓███████████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓██████████████▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

// LICENSE
// DogMoneyAuctionHouse.sol is a modified version of NounHouse's NounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/1a80def995e58ef72fb0e52b55310a6e7bf78c0e/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Dog Money.

pragma solidity ^0.8.6;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IDogMoneyAuctionHouse} from "./interfaces/IDogMoneyAuctionHouse.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract DogMoneyAuctionHouse is
    IDogMoneyAuctionHouse,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable
{
    event QueueUpdated();

    // The address of the WETH contract.
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created.
    uint256 public timeBuffer;

    // The minimum price accepted in an auction.
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid.
    uint8 public minBidIncrementPercentage;

    // The maximum number of tokens of each type (20, 721, 1155).
    uint8 public maxTokensPerType = 5;

    // The duration of a single auction.
    uint256 public duration;

    // The active auction.
    IDogMoneyAuctionHouse.Auction public auction;

    // It's the most gas-efficient to keep this array off-chain,
    // however, in order to progress through the queue "automatically" (since somebody needs to settle each auction),
    // then it does need to be kept on-chain, or via an oracle. For simplicity, it's on chain. It can be re-used
    // for an efficient off-chain queue if desired in the future.
    mapping(int256 => IDogMoneyAuctionHouse.Auction) public nextAuctions;

    int256 public numNextAuctions = 0;

    // A negative number means that we have reached the end, and are free to overwrite from 0.
    int256 public nextAuctionHead;

    IERC20 public reserveCurrency;
    mapping(address => bool) public acceptedCurrenciesMap;
    address[] public acceptedCurrenciesArray;

    mapping(uint256 => IDogMoneyAuctionHouse.Auction) public pastAuctions;
    uint256 public numAuctions = 0;

    address public fundsReceiver;

    // Uniswap
    // 0.3%
    uint24 public constant poolFee = 3000;
    ISwapRouter public swapRouter;

    constructor(MinimalForwarder forwarder)
        ERC2771ContextUpgradeable(address(forwarder))
    {}

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration,
        address _fundsReceiver,
        IERC20 _reserveCurrency,
        address[] memory _acceptedCurrencies,
        ISwapRouter _swapRouter
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        fundsReceiver = _fundsReceiver;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
        reserveCurrency = _reserveCurrency;

        acceptedCurrenciesArray = _acceptedCurrencies;
        for (uint16 i = 0; i < _acceptedCurrencies.length; i++) {
            acceptedCurrenciesMap[_acceptedCurrencies[i]] = true;
        }

        swapRouter = _swapRouter;
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @notice Settle the current auction, start the next auction without an overriding AuctionPack.
     */
    function settleCurrentAndCreateNewAuction()
        external
        override
        nonReentrant
        whenNotPaused
    {
        _settleAuction(false);
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     */
    function settleAuction(bool forceSettle)
        external
        override
        nonReentrant
        onlyOwner
    {
        _settleAuction(forceSettle);
    }

    /**
     * @notice Create a bid for an Auction, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(
        uint256 auctionId,
        IERC20 token,
        uint256 amountInReserveCurrency,
        uint256 amountInMaximum
    ) external payable override nonReentrant {
        IDogMoneyAuctionHouse.Auction memory _auction = auction;

        require(_auction.id == auctionId, "Wrong auctionId");
        require(block.timestamp < _auction.endTime, "Auction expired");
        require(
            amountInReserveCurrency >= reservePrice &&
                amountInReserveCurrency >= _auction.auctionPack.reservePrice,
            "Must send at least reservePrice"
        );
        require(
            amountInReserveCurrency >=
                _auction.amount +
                    ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
        require(
            address(token) == address(reserveCurrency) ||
                acceptedCurrenciesMap[address(token)] == true,
            "Unsupported currency"
        );

        // Swap if not given the reserve currency.
        if (address(token) != address(reserveCurrency)) {
            TransferHelper.safeTransferFrom(
                address(token),
                _msgSender(),
                address(this),
                amountInMaximum
            );

            TransferHelper.safeApprove(
                address(token),
                address(swapRouter),
                amountInMaximum
            );

            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: address(token),
                    tokenOut: address(reserveCurrency),
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountInReserveCurrency,
                    amountInMaximum: amountInMaximum,
                    sqrtPriceLimitX96: 0
                });

            // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
            uint256 amountIn = swapRouter.exactOutputSingle(params);

            // For exact output swaps, the amountInMaximum may not have all been spent.
            // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
            if (amountIn < amountInMaximum) {
                TransferHelper.safeApprove(
                    address(token),
                    address(swapRouter),
                    0
                );
                TransferHelper.safeTransfer(
                    address(token),
                    _msgSender(),
                    amountInMaximum - amountIn
                );
            }
        } else {
            token.transferFrom(
                _msgSender(),
                address(this),
                amountInReserveCurrency
            );
        }

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            reserveCurrency.transfer(lastBidder, _auction.amount);
        }

        auction.amount = amountInReserveCurrency;
        auction.bidder = payable(_msgSender());

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(
            _auction.id,
            _msgSender(),
            amountInReserveCurrency,
            extended
        );

        if (extended) {
            emit AuctionExtended(_auction.id, _auction.endTime);
        }
    }

    /**
     * @notice Pause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice)
        external
        override
        onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        override
        onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    function _ensureApprovals(
        IDogMoneyAuctionHouse.AuctionPack memory auctionPack
    ) internal view {
        require(
            auctionPack.erc20Addresses.length +
                auctionPack.erc721Addresses.length +
                auctionPack.erc1155Addresses.length >
                0,
            "Empty auctionpack"
        );

        for (
            uint256 i = 0;
            i < auctionPack.erc20Addresses.length && i < maxTokensPerType;
            i++
        ) {
            if (auctionPack.erc20Addresses[i] == address(0)) continue;
            require(
                IERC20(auctionPack.erc20Addresses[i]).allowance(
                    owner(),
                    address(this)
                ) >= auctionPack.erc20Amounts[i],
                "ERC20 was not approved"
            );
        }

        for (
            uint256 i = 0;
            i < auctionPack.erc721Addresses.length && i < maxTokensPerType;
            i++
        ) {
            if (auctionPack.erc721Addresses[i] == address(0)) continue;
            require(
                IERC721(auctionPack.erc721Addresses[i]).getApproved(
                    auctionPack.erc721TokenIds[i]
                ) == address(this),
                "ERC721 was not approved"
            );
        }

        for (
            uint256 i = 0;
            i < auctionPack.erc1155Addresses.length && i < maxTokensPerType;
            i++
        ) {
            if (auctionPack.erc1155Addresses[i] == address(0)) continue;
            require(
                IERC1155(auctionPack.erc1155Addresses[i]).isApprovedForAll(
                    owner(),
                    address(this)
                ),
                "ERC1155 was not approved"
            );
        }
    }

    function getNextAuction(bool canRestartCycle)
        public
        view
        returns (IDogMoneyAuctionHouse.Auction memory)
    {
        if (nextAuctionHead >= 0 && nextAuctionHead < numNextAuctions) {
            return nextAuctions[nextAuctionHead];
        }

        for (uint256 i = auction.id + 1; i < numAuctions; i++) {
            if (pastAuctions[i].amount == 0 && !pastAuctions[i].cancelled) {
                return pastAuctions[i];
            }
        }

        if (canRestartCycle) {
            for (uint256 i = 0; i <= auction.id; i++) {
                if (pastAuctions[i].amount == 0 && !pastAuctions[i].cancelled) {
                    return pastAuctions[i];
                }
            }
        }

        require(false, "Nothing Queued");
        // This should never get hit, but it solves
        // "Warning: Unnamed return variable can remain unassigned."
        return nextAuctions[0];
    }

    function getQueuedAuction(int256 i)
        public
        view
        returns (IDogMoneyAuctionHouse.Auction memory)
    {
        return nextAuctions[i];
    }

    /**
     * @notice Create an auction using the provided auctionPack.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     */
    function createAuction() external onlyOwner {
        _createAuction();
    }

    function _createAuction() internal {
        IDogMoneyAuctionHouse.Auction memory _nextAuction = getNextAuction(
            true
        );

        if (_nextAuction.lastAttempt == 0) {
            nextAuctionHead++;
            _createAuction(_nextAuction.auctionPack);
        } else {
            _reactivateAuction(_nextAuction.id);
        }
    }

    function _reactivateAuction(uint256 auctionId) internal {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        pastAuctions[auctionId].startTime = startTime;
        pastAuctions[auctionId].endTime = endTime;
        pastAuctions[auctionId].lastAttempt = startTime;
        auction = pastAuctions[auctionId];
        emit AuctionCreated(auction.id, startTime, endTime);
    }

    function _createAuction(AuctionPack memory auctionPack) internal {
        _ensureApprovals(auctionPack);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auction = Auction({
            id: numAuctions++,
            auctionPack: auctionPack,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false,
            cancelled: false,
            lastAttempt: block.timestamp
        });

        emit AuctionCreated(auction.id, startTime, endTime);
    }

    /**
     * @notice Create an auction using the provided auctionPack.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     */
    function createAuction(AuctionPack memory auctionPack) external onlyOwner {
        _createAuction(auctionPack);
    }

    /**
     * @notice Set the queue of future auctionpacks to use.
     * @dev Store the auction details in the `nextAuctions` state variable.
     */
    function setNextAuctions(AuctionPack[] memory auctionPacks)
        external
        onlyOwner
    {
        nextAuctionHead = 0;
        numNextAuctions = int256(auctionPacks.length);

        for (uint256 i = 0; i < uint256(numNextAuctions); i++) {
            _ensureApprovals(auctionPacks[i]);
            nextAuctions[int256(i)] = Auction({
                id: 0,
                auctionPack: auctionPacks[i],
                amount: 0,
                startTime: 0,
                endTime: 0,
                bidder: payable(0),
                settled: false,
                cancelled: false,
                lastAttempt: 0
            });
        }

        emit QueueUpdated();
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, then nothing changes to the AuctionPack, but
     * it will be returned to in the future.
     */
    function _settleAuction(bool forceSettle) internal {
        IDogMoneyAuctionHouse.Auction memory _auction = auction;

        if (auction.cancelled) return;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");

        // Allow the dao operator to force settle the auction as things stand.
        require(
            forceSettle || block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        // Set it to true no matter what so that we don't settle it twice, even if we forceSettle without a bidder.
        // (basically disabling the current auction without adding extra storage/logic fees.)
        auction.settled = true;

        if (_auction.bidder != address(0)) {
            for (
                uint256 i = 0;
                i < _auction.auctionPack.erc20Addresses.length &&
                    i < maxTokensPerType;
                i++
            ) {
                if (_auction.auctionPack.erc20Addresses[i] == address(0))
                    continue;
                IERC20(_auction.auctionPack.erc20Addresses[i]).transferFrom(
                    owner(),
                    _auction.bidder,
                    _auction.auctionPack.erc20Amounts[i]
                );
            }

            for (
                uint256 i = 0;
                i < _auction.auctionPack.erc721Addresses.length &&
                    i < maxTokensPerType;
                i++
            ) {
                if (_auction.auctionPack.erc721Addresses[i] == address(0))
                    continue;
                IERC721(_auction.auctionPack.erc721Addresses[i]).transferFrom(
                    owner(),
                    _auction.bidder,
                    _auction.auctionPack.erc721TokenIds[i]
                );
            }

            for (
                uint256 i = 0;
                i < _auction.auctionPack.erc1155Addresses.length &&
                    i < maxTokensPerType;
                i++
            ) {
                if (_auction.auctionPack.erc1155Addresses[i] == address(0))
                    continue;
                IERC1155(_auction.auctionPack.erc1155Addresses[i])
                    .safeTransferFrom(
                        owner(),
                        _auction.bidder,
                        _auction.auctionPack.erc1155TokenIds[i],
                        _auction.auctionPack.erc1155Amounts[i],
                        new bytes(0)
                    );
            }

            if (_auction.amount > 0) {
                reserveCurrency.transfer(fundsReceiver, _auction.amount);
            }
        } else {
            auction.amount = 0;
        }

        auction.lastAttempt = block.timestamp;
        pastAuctions[_auction.id] = auction;

        emit AuctionSettled(_auction.id, _auction.bidder, _auction.amount);
    }

    function cancelCurrentAuction() external onlyOwner {
        IDogMoneyAuctionHouse.Auction memory _auction = auction;
        require(_auction.cancelled == false, "Already cancelled");
        _auction.cancelled = true;

        if (_auction.amount > 0) {
            reserveCurrency.transfer(_auction.bidder, _auction.amount);
            _auction.amount = 0;
        }
    }

    /**
     * @notice Cancel the given auction.
     */
    function cancelAuction(uint256 auctionId) external onlyOwner {
        pastAuctions[auctionId].cancelled = true;
    }

    function setFundsReceiver(address _fundsReceiver) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function getAcceptedCurrencies() public view returns (address[] memory) {
        return acceptedCurrenciesArray;
    }

    /**
     * @notice Retrieve a specific auction.
     */
    function getPastAuction(uint256 auctionId)
        public
        view
        returns (IDogMoneyAuctionHouse.Auction memory)
    {
        return pastAuctions[auctionId];
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓██████████████▓▓▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓███████████▓▓▓▓▓▓▓▓███████████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░▒▓██████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓███████▓▒░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▒▓█████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓█████▓▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░▒▓████▓▓▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▓▓████▓▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▒████▓▓▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▓▓████▒░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▓████▓▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▓████▓░░░░░░░░░░░░░
░░░░░░░░░░░▒███▓▓▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▓▓███▓░░░░░░░░░░░
░░░░░░░░░▒████▓▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▓▓███▒░░░░░░░░░
░░░░░░░░▓███▓▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▓▓▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▓▓▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▓███▓░░░░░░░░
░░░░░░░███▓▒▒▒▒▒░░▒▒▒▒▒▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████▓▒▒▒▒▒▒▒░░▒▒▒▒▒▓███░░░░░░░
░░░░░▒███▓▒▒▒▒░░▒▒▒▒▒▓█████████████████████████████████████████████▓▒▒▒▒▒▒░░▒▒▒▒▓███▒░░░░░
░░░░▒███▓▒▒▒▒░░▒▒▒▓█████████████████▓▓▓▓██████████▓▓▓██████████████████▒▒▒▒░░▒▒▒▒▓███▒░░░░
░░░░███▓▒▒▒▒░░▒▓████████████████████████▒███████▓▒████████████████████████▒▒░░▒▒▒▒▓███▒░░░
░░░███▓▒▒▒▒▒▓████████████████████████████▓██████▒████████████████████████████▓░▒▒▒▒▓███░░░
░░▓██▓▒▒▒▒██████████████████████████████████████████████████████████████████████░▒▒▒▓███░░
░▒███▒▒▒▒▒█████████████████████████▓██████████████████▓█████████████████████████░▒▒▒▒███▒░
░███▓▒▒▒▒░▒████████████████▓███▓▓████████████████████▓███▓▒███▓████████████████░░▒▒▒▒▓███░
▒███▒▒▒▒░▒▒░██████████████▓██████▓▓▓██████████████████▓▓▓██████▓█████████████▓░▒▒░▒▒▒▒███▒
▓██▓▒▒▒▒░▒▒▒░████████████▓██████████████████████████████████████▓███████████▓░▒▒▒░▒▒▒▒▓██▓
███▓▒▒▒▒░▒▒▒▒░██████████▒███████████▓███████████████▓▓███████████▓█████████▓░▒▒▒▒░░▒▒▒▒███
███▒▒▒▒░░▒▒▒▒▒░▓███████▒█████▓█████▓██████████████████▓████▓▓█████▓███████▒░▒▒▒▒▒░░▒▒▒▒███
███▒▒▒▒░░▒▒▒▒▒▒░▓█████▒███████▒██▓▓████▓▓▓▓████▓▓▓▓████▓▓██▒██████▓▓█████▒▒▒▒▒▒▒▒░░▒▒▒▒███
███▒▒▒▒░░▒▒▒▒▒▒▒░▓███▒▓█████████▒█████▓▓██████████▒██████▒█████████▓▓███▒▒▒▒▒▒▒▒▒░░▒▒▒▒███
███▓▒▒▒▒░▒▒▒▒▒▒▒▒░▒▓▒▒█████████▒███████▒█▓█▓██▓█▓█▒███████▒█████████░▒▓▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒███
▓██▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒░▓████████▒████████▓▓▓▒██▒▓▓▓████████▒████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓██▓
▒███▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░████████░████████████▒▓████████████▒███████▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒███▒
░███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░███████▓▓███████████▓▓███████████▒███████▓░▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███░
░▒███▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████▒▓██████████▒▓██████████▓▓███████░▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒███▒░
░░███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒░████████▒▓████████▓▓▓▓████████▓▒████████░▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███░░
░░░███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒░▓█████████▓▓█████▓▒████▒▓█████▒▓█████████░▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███░░░
░░░▒███▓▒▒▒▒░▒▒▒▒▒▒▒▒▒░░████████████▒▓▓▒▒████████▒▒▓▓▒███████████▒░░▒▒▒▒▒▒▒▒▒░▒▒▒▒▓███▒░░░
░░░░▒███▓▒▒▒▒░░▒▒▒▒▒▒░░▒▒▒▓██████████▓██▓▓▓▓▓▓▓▓▓▓██▓█████████▓▓▒▒▒░▒▒▒▒▒▒▒░░▒▒▒▒▓███▒░░░░
░░░░░▒███▓▒▒▒▒░░▒▒▒▒▒░▒▒▒▒▒▒▒▒▓████████████████████████████▓▒▒▒▒▒▒▒░░▒▒▒▒▒░░▒▒▒▒▓███▒░░░░░
░░░░░░░███▓▒▒▒▒▒░░▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▓▓██████████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒░░▒▒▒▒▒▓███░░░░░░░
░░░░░░░░▓███▓▒▒▒▒▒░▒▒░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒░▒▒▒▒▒▓███▓░░░░░░░░
░░░░░░░░░▒████▓▒▒▒▒▒░░████▓▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▓████░░▒▒▒▒▒▓▓███▒░░░░░░░░░
░░░░░░░░░░░▓███▓▓▒▒▒▒▒░▒▓████▓▓▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▓█████▓▒░▒▒▒▒▒▓▓███▓░░░░░░░░░░░
░░░░░░░░░░░░░▓████▓▒▒▒▒▒▒░▒▓███████▓▓▒▒▒░▒▒▒▒▒▒▒▒▒░▒▓▓▓███████▓▒░▒▒▒▒▒▒▓▓███▓░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▒████▓▓▒▒▒▒▒▒░░▒▓███████▓▓▓▓▓▓▓▓▓▓▓████████▓▒▒░▒▒▒▒▒▒▒▓████▓░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░▒▓████▓▓▒▒▒▒▒▒▒▒░▒▒▒▒▓▓▓████████▓▓▓▒▒▒▒░▒▒▒▒▒▒▒▒▓▓████▓▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░▒▓█████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓█████▓▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▒▓███████▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓██████▓▒░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓███████████▓▓▓▓▓▓▓▓███████████▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓██████████████▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

pragma solidity ^0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDogMoneyAuctionHouse {
    struct Auction {
        // The id of this auction.
        uint256 id;
        // The package containing which tokens are to be auctioned.
        AuctionPack auctionPack;
        // The current highest bid amount.
        uint256 amount;
        // The time that the auction started.
        uint256 startTime;
        // The time that the auction is scheduled to end.
        uint256 endTime;
        // The address of the current highest bid.
        address payable bidder;
        // Whether or not the auction has been settled.
        bool settled;
        // If there isn't balance for an auction, or it was made
        // erroneously, then the auction operator can cancel it.
        bool cancelled;
        // Used to recycle through old auctions.
        uint256 lastAttempt;
    }

    struct AuctionPack {
        bool isInitialized;
        string metadataURI;
        uint256 reservePrice;
        address[] erc20Addresses;
        uint256[] erc20Amounts;
        address[] erc721Addresses;
        uint256[] erc721TokenIds;
        address[] erc1155Addresses;
        uint256[] erc1155Amounts;
        uint256[] erc1155TokenIds;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed auctionId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed auctionId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function settleAuction(bool forceSettle) external;

    function settleCurrentAndCreateNewAuction() external;

    function createAuction() external;

    function createAuction(AuctionPack memory auctionPack) external;

    function setNextAuctions(AuctionPack[] memory auctionPack) external;

    function createBid(
        uint256 auctionId,
        IERC20 token,
        uint256 amountInReserveCurrency,
        uint256 amountInMaximum
    ) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
        external;

    function cancelAuction(uint256 auctionId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}