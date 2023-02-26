// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IgETH {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function uri(uint256) external view returns (string memory);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function pause() external;

    function unpause() external;

    // gETH Specials

    function denominator() external view returns (uint256);

    function pricePerShare(uint256 id) external view returns (uint256);

    function priceUpdateTimestamp(uint256 id) external view returns (uint256);

    function setPricePerShare(uint256 price, uint256 id) external;

    function isInterface(
        address _interface,
        uint256 id
    ) external view returns (bool);

    function isAvoider(
        address account,
        uint256 id
    ) external view returns (bool);

    function avoidInterfaces(uint256 id, bool isAvoid) external;

    function setInterface(address _interface, uint256 id, bool isSet) external;

    function updateMinterRole(address Minter) external;

    function updatePauserRole(address Pauser) external;

    function updateOracleRole(address Oracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IgETHInterface {
  function initialize(
    uint256 id_,
    address erc1155_,
    bytes memory data
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

interface ILPToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(string memory name, string memory symbol)
        external
        returns (bool);

    function mint(address recipient, uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "../Portal/utils/DataStoreUtilsLib.sol";
import "../Portal/utils/GeodeUtilsLib.sol";
import "../Portal/utils/OracleUtilsLib.sol";
import "../Portal/utils/StakeUtilsLib.sol";

interface IPortal {
  function initialize(
    address _GOVERNANCE,
    address _SENATE,
    address _gETH,
    address _ORACLE_POSITION,
    address _DEFAULT_WITHDRAWAL_CONTRACT_MODULE,
    address _DEFAULT_LP_MODULE,
    address _DEFAULT_LP_TOKEN_MODULE,
    address[] calldata _ALLOWED_GETH_INTERFACE_MODULES,
    bytes[] calldata _ALLOWED_GETH_INTERFACE_MODULE_NAMES,
    uint256 _GOVERNANCE_FEE
  ) external;

  function getContractVersion() external view returns (uint256);

  function pause() external;

  function unpause() external;

  function pausegETH() external;

  function unpausegETH() external;

  function fetchWithdrawalContractUpgradeProposal(
    uint256 id
  ) external returns (uint256 withdrawalContractVersion);

  function gETH() external view returns (address);

  function gETHInterfaces(
    uint256 id,
    uint256 index
  ) external view returns (address);

  function allIdsByType(
    uint256 _type,
    uint256 _index
  ) external view returns (uint256);

  function generateId(
    string calldata _name,
    uint256 _type
  ) external pure returns (uint256 id);

  function getKey(
    uint256 _id,
    bytes32 _param
  ) external pure returns (bytes32 key);

  function readAddressForId(
    uint256 id,
    bytes32 key
  ) external view returns (address data);

  function readUintForId(
    uint256 id,
    bytes32 key
  ) external view returns (uint256 data);

  function readBytesForId(
    uint256 id,
    bytes32 key
  ) external view returns (bytes memory data);

  function readUintArrayForId(
    uint256 id,
    bytes32 key,
    uint256 index
  ) external view returns (uint256 data);

  function readBytesArrayForId(
    uint256 id,
    bytes32 key,
    uint256 index
  ) external view returns (bytes memory data);

  function readAddressArrayForId(
    uint256 id,
    bytes32 key,
    uint256 index
  ) external view returns (address data);

  function GeodeParams()
    external
    view
    returns (
      address SENATE,
      address GOVERNANCE,
      uint256 SENATE_EXPIRY,
      uint256 GOVERNANCE_FEE
    );

  function getProposal(
    uint256 id
  ) external view returns (GeodeUtils.Proposal memory proposal);

  function isElector(uint256 _TYPE) external view returns (bool);

  function isUpgradeAllowed(
    address proposedImplementation
  ) external view returns (bool);

  function setGovernanceFee(uint256 newFee) external;

  function setElectorType(uint256 _TYPE, bool isElector) external;

  function newProposal(
    address _CONTROLLER,
    uint256 _TYPE,
    bytes calldata _NAME,
    uint256 duration
  ) external;

  function approveProposal(uint256 id) external;

  function changeSenate(address _newSenate) external;

  function changeIdCONTROLLER(uint256 id, address newCONTROLLER) external;

  function approveSenate(uint256 proposalId, uint256 electorId) external;

  function StakingParams()
    external
    view
    returns (
      uint256 VALIDATORS_INDEX,
      uint256 VERIFICATION_INDEX,
      uint256 MONOPOLY_THRESHOLD,
      uint256 EARLY_EXIT_FEE,
      uint256 ORACLE_UPDATE_TIMESTAMP,
      uint256 DAILY_PRICE_INCREASE_LIMIT,
      uint256 DAILY_PRICE_DECREASE_LIMIT,
      bytes32 PRICE_MERKLE_ROOT,
      address ORACLE_POSITION
    );

  function getDefaultModule(
    uint256 _type
  ) external view returns (uint256 _version);

  function isAllowedModule(
    uint256 _type,
    uint256 _version
  ) external view returns (bool);

  function getValidator(
    bytes calldata pubkey
  ) external view returns (StakeUtils.Validator memory);

  function getValidatorByPool(
    uint256 poolId,
    uint256 index
  ) external view returns (bytes memory);

  function getMaintenanceFee(uint256 id) external view returns (uint256 fee);

  // function operatorAllowance(
  //   uint256 poolId,
  //   uint256 operatorId
  // ) external view returns (uint256 allowance);

  function isPrisoned(uint256 operatorId) external view returns (bool);

  function isPrivatePool(uint256 poolId) external view returns (bool);

  function isPriceValid(uint256 poolId) external view returns (bool);

  function isMintingAllowed(uint256 poolId) external view returns (bool);

  function canStake(bytes calldata pubkey) external view returns (bool);

  function initiateOperator(
    uint256 id,
    uint256 fee,
    uint256 validatorPeriod,
    address maintainer
  ) external payable;

  function initiatePool(
    uint256 fee,
    uint256 interfaceVersion,
    address maintainer,
    bytes calldata NAME,
    bytes calldata interface_data,
    bool[3] calldata config
  ) external payable;

  function setPoolVisibility(uint256 poolId, bool isPrivate) external;

  function deployLiquidityPool(uint256 poolId) external;

  function changeMaintainer(uint256 id, address newMaintainer) external;

  function switchMaintenanceFee(uint256 id, uint256 newFee) external;

  function increaseWalletBalance(
    uint256 id
  ) external payable returns (bool success);

  function decreaseWalletBalance(
    uint256 id,
    uint256 value
  ) external returns (bool success);

  function switchValidatorPeriod(uint256 id, uint256 newPeriod) external;

  function blameOperator(bytes calldata pk) external;

  function setEarlyExitFee(uint256 fee) external;

  function releasePrisoned(uint256 operatorId) external;

  function approveOperators(
    uint256 poolId,
    uint256[] calldata operatorIds,
    uint256[] calldata allowances
  ) external;

  function setWhitelist(uint256 poolId, address whitelist) external;

  function deposit(
    uint256 poolId,
    uint256 mingETH,
    uint256 deadline,
    uint256 price,
    bytes32[] calldata priceProofs,
    address receiver
  ) external payable;

  function proposeStake(
    uint256 poolId,
    uint256 operatorId,
    bytes[] calldata pubkeys,
    bytes[] calldata signatures1,
    bytes[] calldata signatures31
  ) external;

  function beaconStake(uint256 operatorId, bytes[] calldata pubkeys) external;

  function updateVerificationIndex(
    uint256 validatorVerificationIndex,
    bytes[] calldata alienatedPubkeys
  ) external;

  function regulateOperators(
    uint256[] calldata feeThefts,
    bytes[] calldata stolenBlocks
  ) external;

  function reportOracle(
    bytes32 priceMerkleRoot,
    uint256 allValidatorsCount
  ) external;

  function priceSync(
    uint256 poolId,
    uint256 price,
    bytes32[] calldata priceProofs
  ) external;

  function priceSyncBatch(
    uint256[] calldata poolIds,
    uint256[] calldata prices,
    bytes32[][] calldata priceProofs
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./IgETH.sol";

interface ISwap {
  // pool data view functions
  function getERC1155() external view returns (address);

  function getA() external view returns (uint256);

  function getAPrecise() external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getToken() external view returns (uint256);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function getDebt() external view returns (uint256);

  function getAdminBalance(uint256 index) external view returns (uint256);

  // min return calculation functions
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateTokenAmount(
    uint256[2] calldata amounts,
    bool deposit
  ) external view returns (uint256);

  function calculateRemoveLiquidity(
    uint256 amount
  ) external view returns (uint256[2] memory);

  function calculateRemoveLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256 availableTokenAmount);

  // state modifying functions
  function initialize(
    IgETH _gEth,
    uint256 _pooledTokenId,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    address lpTokenTargetAddress,
    address owner
  ) external returns (address lpToken);

  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external payable returns (uint256);

  function addLiquidity(
    uint256[2] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external payable returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[2] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[2] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[2] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);

  function withdrawAdminFees() external;

  function setAdminFee(uint256 newAdminFee) external;

  function setSwapFee(uint256 newSwapFee) external;

  function rampA(uint256 futureA, uint256 futureTime) external;

  function stopRampA() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IWhitelist {
  function isAllowed(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./IgETH.sol";
import "./IPortal.sol";

interface IWithdrawalContract {
  function initialize(
    uint256 _VERSION,
    uint256 _ID,
    address _gETH,
    address _PORTAL,
    address _CONTROLLER
  ) external returns (bool);

  function pause() external;

  function unpause() external;

  function getgETH() external view returns (IgETH);

  function getPortal() external view returns (IPortal);

  function getPoolId() external view returns (uint256);

  function getContractVersion() external view returns (uint256);

  function getProposedVersion() external view returns (uint256);

  function recoveryMode() external view returns (bool);

  function newProposal(
    address _CONTROLLER,
    uint256 _TYPE,
    bytes calldata _NAME,
    uint256 duration
  ) external;

  function approveProposal(
    uint256 id
  ) external returns (uint256 _type, address _controller);

  function fetchUpgradeProposal() external;

  function changeController(address _newSenate) external;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity =0.8.7;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @author Icebear & Crash Bandicoot
 * @title Isolated Storage Layout
 * A Storage Management Library for Dynamic Structs
 *
 * * DataStoreUtils is a storage management tool designed to create a safe and scalable
 * * storage layout with the help of data types, IDs and keys.
 *
 * * Focusing on upgradable contracts with multiple user types to create a
 * * sustainable development environment.
 * * In summary, extra gas cost that would be saved with Storage packing are
 * * ignored to create upgradable structs.
 *
 * @dev Distinct id and key pairs SHOULD return different storage slots
 * @dev TYPEs are defined in globals.sol
 *
 * @dev IDs are the representation of an entity with any given key as properties.
 * @dev While it is good practice to keep record,
 * * TYPE for ID is NOT mandatory, an ID might not have an explicit type.
 * * Thus there is no checks of types or keys.
 */

library DataStoreUtils {
  /**
   * @notice Main Struct for reading and writing operations for given (id, key) pairs
   * @param allIdsByType type => id[], optional categorization for IDs, requires direct access
   * @param uintData keccak(id, key) =>  returns uint256
   * @param bytesData keccak(id, key) => returns bytes
   * @param addressData keccak(id, key) =>  returns address
   * @param __gap keep the struct size at 16
   * @dev any other storage type can be expressed as uint or bytes
   */
  struct IsolatedStorage {
    mapping(uint256 => uint256[]) allIdsByType;
    mapping(bytes32 => uint256) uintData;
    mapping(bytes32 => bytes) bytesData;
    mapping(bytes32 => address) addressData;
    uint256[12] __gap;
  }

  /**
   *                              ** HELPERS **
   **/

  /**
   * @notice generaliazed method of generating an ID
   * @dev Some TYPEs may require permissionless creation. Allowing anyone to claim any ID,
   * meaning malicious actors can claim names to mislead people. To prevent this
   * TYPEs will be considered during ID generation.
   */
  function generateId(
    bytes memory _name,
    uint256 _type
  ) internal pure returns (uint256 id) {
    id = uint256(keccak256(abi.encodePacked(_name, _type)));
  }

  /**
   * @notice hashes given id and a parameter to be used as key in getters and setters
   * @return key bytes32 hash of id and parameter to be stored
   **/
  function getKey(
    uint256 id,
    bytes32 param
  ) internal pure returns (bytes32 key) {
    key = keccak256(abi.encodePacked(id, param));
  }

  /**
   *                              ** DATA GETTERS **
   **/

  function readUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key
  ) internal view returns (uint256 data) {
    data = self.uintData[getKey(_id, _key)];
  }

  function readBytesForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key
  ) internal view returns (bytes memory data) {
    data = self.bytesData[getKey(_id, _key)];
  }

  function readAddressForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key
  ) internal view returns (address data) {
    data = self.addressData[getKey(_id, _key)];
  }

  /**
   *                              ** ARRAY GETTERS **
   **/

  function readUintArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _index
  ) internal view returns (uint256 data) {
    data = self.uintData[getKey(_index, getKey(_id, _key))];
  }

  function readBytesArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _index
  ) internal view returns (bytes memory data) {
    data = self.bytesData[getKey(_index, getKey(_id, _key))];
  }

  function readAddressArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _index
  ) internal view returns (address data) {
    data = self.addressData[getKey(_index, getKey(_id, _key))];
  }

  /**
   *                              ** DATA SETTERS **
   **/

  function writeUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _data
  ) internal {
    self.uintData[getKey(_id, _key)] = _data;
  }

  function addUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _addend
  ) internal {
    self.uintData[getKey(_id, _key)] += _addend;
  }

  function subUintForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _minuend
  ) internal {
    self.uintData[getKey(_id, _key)] -= _minuend;
  }

  function writeBytesForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    bytes memory _data
  ) internal {
    self.bytesData[getKey(_id, _key)] = _data;
  }

  function writeAddressForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    address _data
  ) internal {
    self.addressData[getKey(_id, _key)] = _data;
  }

  /**
   *                              ** ARRAY SETTERS **
   **/

  function appendUintArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256 _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    self.uintData[getKey(self.uintData[arrayKey]++, arrayKey)] = _data;
  }

  function appendBytesArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    bytes memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    self.bytesData[getKey(self.uintData[arrayKey]++, arrayKey)] = _data;
  }

  function appendAddressArrayForId(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    address _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    self.addressData[getKey(self.uintData[arrayKey]++, arrayKey)] = _data;
  }

  /**
   *                              ** BATCH ARRAY SETTERS **
   **/

  function appendUintArrayForIdBatch(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    uint256[] memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    uint256 arrayLen = self.uintData[arrayKey];
    for (uint256 i; i < _data.length; ) {
      self.uintData[getKey(arrayLen++, arrayKey)] = _data[i];
      unchecked {
        i += 1;
      }
    }
    self.uintData[arrayKey] = arrayLen;
  }

  function appendBytesArrayForIdBatch(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    bytes[] memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    uint256 arrayLen = self.uintData[arrayKey];
    for (uint256 i; i < _data.length; ) {
      self.bytesData[getKey(arrayLen++, arrayKey)] = _data[i];
      unchecked {
        i += 1;
      }
    }
    self.uintData[arrayKey] = arrayLen;
  }

  function appendAddressArrayForIdBatch(
    IsolatedStorage storage self,
    uint256 _id,
    bytes32 _key,
    address[] memory _data
  ) internal {
    bytes32 arrayKey = getKey(_id, _key);
    uint256 arrayLen = self.uintData[arrayKey];
    for (uint256 i; i < _data.length; ) {
      self.addressData[getKey(arrayLen++, arrayKey)] = _data[i];
      unchecked {
        i += 1;
      }
    }
    self.uintData[arrayKey] = arrayLen;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "../../interfaces/IDepositContract.sol";
import "../helpers/BytesLib.sol";

library DepositContractUtils {
  IDepositContract internal constant DEPOSIT_CONTRACT =
    IDepositContract(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b);
  uint256 internal constant PUBKEY_LENGTH = 48;
  uint256 internal constant SIGNATURE_LENGTH = 96;
  uint256 internal constant WITHDRAWAL_CREDENTIALS_LENGTH = 32;
  uint256 internal constant DEPOSIT_AMOUNT = 32 ether;
  uint256 internal constant DEPOSIT_AMOUNT_PRESTAKE = 1 ether;
  uint256 internal constant MAX_DEPOSITS_PER_CALL = 50;

  /**
   * @dev Padding memory array with zeroes up to 64 bytes on the right
   * @param _b Memory array of size 32 .. 64
   */
  function _pad64(bytes memory _b) internal pure returns (bytes memory) {
    assert(_b.length >= 32 && _b.length <= 64);
    if (64 == _b.length) return _b;

    bytes memory zero32 = new bytes(32);
    assembly {
      mstore(add(zero32, 0x20), 0)
    }

    if (32 == _b.length) return BytesLib.concat(_b, zero32);
    else
      return
        BytesLib.concat(_b, BytesLib.slice(zero32, 0, uint256(64 - _b.length)));
  }

  /**
   * @dev Converting value to little endian bytes and padding up to 32 bytes on the right
   * @param _value Number less than `2**64` for compatibility reasons
   */
  function _toLittleEndian64(
    uint256 _value
  ) internal pure returns (uint256 result) {
    result = 0;
    uint256 temp_value = _value;
    for (uint256 i = 0; i < 8; ++i) {
      result = (result << 8) | (temp_value & 0xFF);
      temp_value >>= 8;
    }

    assert(0 == temp_value); // fully converted
    result <<= (24 * 8);
  }

  function _getDepositDataRoot(
    bytes memory _pubkey,
    bytes memory _withdrawalCredentials,
    bytes memory _signature,
    uint256 _stakeAmount
  ) internal pure returns (bytes32) {
    require(_stakeAmount >= 1 ether, "DepositContract: deposit value too low");
    require(
      _stakeAmount % 1 gwei == 0,
      "DepositContract: deposit value not multiple of gwei"
    );

    uint256 deposit_amount = _stakeAmount / 1 gwei;
    bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
    bytes32 signatureRoot = sha256(
      abi.encodePacked(
        sha256(BytesLib.slice(_signature, 0, 64)),
        sha256(_pad64(BytesLib.slice(_signature, 64, SIGNATURE_LENGTH - 64)))
      )
    );

    bytes32 depositDataRoot = sha256(
      abi.encodePacked(
        sha256(abi.encodePacked(pubkeyRoot, _withdrawalCredentials)),
        sha256(
          abi.encodePacked(_toLittleEndian64(deposit_amount), signatureRoot)
        )
      )
    );

    return depositDataRoot;
  }

  function addressToWC(address wcAddress) internal pure returns (bytes memory) {
    uint256 w = 1 << 248;

    return
      abi.encodePacked(
        bytes32(w) | bytes32(uint256(uint160(address(wcAddress))))
      );
  }

  function depositValidator(
    bytes calldata pubkey,
    bytes memory withdrawalCredential,
    bytes memory signature,
    uint256 amount
  ) internal {
    DEPOSIT_CONTRACT.deposit{value: amount}(
      pubkey,
      withdrawalCredential,
      signature,
      _getDepositDataRoot(pubkey, withdrawalCredential, signature, amount)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import {ID_TYPE, PERCENTAGE_DENOMINATOR} from "./globals.sol";
import {DataStoreUtils as DSU} from "./DataStoreUtilsLib.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title Geode Dual Governance
 * @notice Exclusively contains functions for the administration of the Isolated Storage,
 * and Limited Upgradability with Dual Governance of Governance and Senate
 * Note This library contains both functions called by users(ID) (approveSenate) and admins(GOVERNANCE, SENATE)
 *
 * @dev Reserved ID_TYPEs:
 *
 * * Type 0 : NULL
 *
 * * Type 1 : SENATE ELECTIONS
 * * * Every SENATE has an expiration date, a new one should be elected before it ends.
 * * * Only the controllers of IDs with TYPEs that are set true on _electorTypes can vote.
 * * * 2/3 is the expected concensus, however this logic seems to be improved in the future.
 *
 * * Type 2 : CONTRACT UPGRADES
 * * * Provides Limited Upgradability on Portal and Withdrawal Contract
 * * * Contract can be upgradable once Senate approves it.
 *
 * * Type 3 : __GAP__
 * * * ormally represented the admin contract, but we use UUPS. Reserved to be never used.
 *
 * @dev Contracts relying on this library must initialize GeodeUtils.DualGovernance
 * @dev Functions are already protected accordingly
 *
 * @dev review DataStoreUtils
 */
library GeodeUtils {
  /// @notice Using DataStoreUtils for IsolatedStorage struct
  using DSU for DSU.IsolatedStorage;

  /// @notice EVENTS
  event GovernanceFeeUpdated(uint256 newFee);
  event ControllerChanged(uint256 indexed id, address newCONTROLLER);
  event Proposed(
    uint256 id,
    address CONTROLLER,
    uint256 indexed TYPE,
    uint256 deadline
  );
  event ProposalApproved(uint256 id);
  event ElectorTypeSet(uint256 TYPE, bool isElector);
  event Vote(uint256 indexed proposalId, uint256 indexed voterId);
  event NewSenate(address senate, uint256 senateExpiry);

  /**
   * @notice Proposals give the control of a specific ID to a CONTROLLER
   *
   * @notice A Proposal has 4 specs:
   * @param TYPE: refer to globals.sol
   * @param CONTROLLER: the address that refers to the change that is proposed by given proposal.
   * * This slot can refer to the controller of an id, a new implementation contract, a new Senate etc.
   * @param NAME: DataStore generates ID by keccak(name, type)
   * @param deadline: refers to last timestamp until a proposal expires, limited by MAX_PROPOSAL_DURATION
   * * Expired proposals can not be approved by Senate
   * * Expired proposals can not be overriden by new proposals
   **/
  struct Proposal {
    address CONTROLLER;
    uint256 TYPE;
    bytes NAME;
    uint256 deadline;
  }

  /**
   * @notice DualGovernance allows 2 parties to manage a contract with proposals and approvals
   * @param GOVERNANCE a community that works to improve the core product and ensures its adoption in the DeFi ecosystem
   * Suggests updates, such as new operators, contract upgrades, a new Senate -without any permission to force them-
   * @param SENATE An address that protects the users by controlling the state of governance, contract updates and other crucial changes
   * Note SENATE is proposed by Governance and voted by all elector TYPEs, approved if ⌊2/3⌋ votes.
   * @param SENATE_EXPIRY refers to the last timestamp that SENATE can continue operating. Enforces a new election, limited by MAX_SENATE_PERIOD
   * @param GOVERNANCE_FEE operation fee on the given contract, acquired by GOVERNANCE. Limited by MAX_GOVERNANCE_FEE
   * @param approvedVersion only 1 implementation contract SHOULD be "approved" at any given time.
   * * @dev safe to set to address(0) after every upgrade as isUpgradeAllowed returns false for address(0)
   * @param _electorCount increased when a new id is added with _electorTypes[id] == true
   * @param _electorTypes only given TYPEs can vote
   * @param _proposals till approved, proposals are kept separated from the Isolated Storage
   * @param __gap keep the struct size at 16
   **/
  struct DualGovernance {
    address GOVERNANCE;
    address SENATE;
    uint256 SENATE_EXPIRY;
    uint256 GOVERNANCE_FEE;
    address approvedVersion;
    uint256 _electorCount;
    mapping(uint256 => bool) _electorTypes;
    mapping(uint256 => Proposal) _proposals;
    uint256[8] __gap;
  }

  /**
   * @notice limiting the GOVERNANCE_FEE, 5%
   */
  uint256 public constant MAX_GOVERNANCE_FEE =
    (PERCENTAGE_DENOMINATOR * 5) / 100;

  /**
   * @notice prevents Governance from collecting any fees till given timestamp:
   * @notice April 2025
   * @dev fee switch will be automatically switched on after given timestamp
   * @dev fee switch can be switched on with the approval of Senate (a contract upgrade)
   */
  uint256 public constant FEE_COOLDOWN = 1743454800;

  uint32 public constant MIN_PROPOSAL_DURATION = 1 days;
  uint32 public constant MAX_PROPOSAL_DURATION = 4 weeks;
  uint32 public constant MAX_SENATE_PERIOD = 365 days;

  modifier onlySenate(DualGovernance storage self) {
    require(msg.sender == self.SENATE, "GU: SENATE role needed");
    require(block.timestamp < self.SENATE_EXPIRY, "GU: SENATE expired");
    _;
  }

  modifier onlyGovernance(DualGovernance storage self) {
    require(msg.sender == self.GOVERNANCE, "GU: GOVERNANCE role needed");
    _;
  }

  modifier onlyController(DSU.IsolatedStorage storage DATASTORE, uint256 id) {
    require(
      msg.sender == DATASTORE.readAddressForId(id, "CONTROLLER"),
      "GU: CONTROLLER role needed"
    );
    _;
  }

  /**
   * @notice                                     ** DualGovernance **
   **/

  /**
   * @dev  ->  view
   */

  /**
   * @return address of SENATE
   **/
  function getSenate(
    DualGovernance storage self
  ) external view returns (address) {
    return self.SENATE;
  }

  /**
   * @return address of GOVERNANCE
   **/
  function getGovernance(
    DualGovernance storage self
  ) external view returns (address) {
    return self.GOVERNANCE;
  }

  /**
   * @return the expiration date of current SENATE as a timestamp
   */
  function getSenateExpiry(
    DualGovernance storage self
  ) external view returns (uint256) {
    return self.SENATE_EXPIRY;
  }

  /**
   * @notice active GOVERNANCE_FEE limited by FEE_COOLDOWN and MAX_GOVERNANCE_FEE
   * @dev MAX_GOVERNANCE_FEE MUST limit GOVERNANCE_FEE even if MAX is changed later
   * @dev MUST return 0 until cooldown period is active
   */
  function getGovernanceFee(
    DualGovernance storage self
  ) external view returns (uint256) {
    return
      block.timestamp < FEE_COOLDOWN
        ? 0
        : MAX_GOVERNANCE_FEE > self.GOVERNANCE_FEE
        ? self.GOVERNANCE_FEE
        : MAX_GOVERNANCE_FEE;
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlyGovernance, sets the governance fee
   * @dev Can not set the fee more than MAX_GOVERNANCE_FEE
   */
  function setGovernanceFee(
    DualGovernance storage self,
    uint256 newFee
  ) external onlyGovernance(self) {
    require(newFee <= MAX_GOVERNANCE_FEE, "GU: > MAX_GOVERNANCE_FEE");

    self.GOVERNANCE_FEE = newFee;

    emit GovernanceFeeUpdated(newFee);
  }

  /**
   * @notice                                     ** ID **
   */

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlyController, change the CONTROLLER of an ID
   * @dev this operation can not be reverted by the old CONTROLLER !
   * @dev can not provide address(0), try 0x000000000000000000000000000000000000dEaD
   */
  function changeIdCONTROLLER(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    address newCONTROLLER
  ) external onlyController(DATASTORE, id) {
    require(newCONTROLLER != address(0), "GU: CONTROLLER can not be zero");

    DATASTORE.writeAddressForId(id, "CONTROLLER", newCONTROLLER);

    emit ControllerChanged(id, newCONTROLLER);
  }

  /**
   * @notice                                     ** PROPOSALS **
   */

  /**
   * @dev  ->  view
   */

  /**
   * @dev refer to Proposal struct
   */
  function getProposal(
    DualGovernance storage self,
    uint256 id
  ) external view returns (Proposal memory) {
    return self._proposals[id];
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlyGovernance, creates a new Proposal
   * @dev DATASTORE[id] will not be updated until the proposal is approved
   * @dev Proposals can NEVER be overriden
   * @dev refer to Proposal struct
   */
  function newProposal(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    address _CONTROLLER,
    uint256 _TYPE,
    bytes calldata _NAME,
    uint256 duration
  ) external onlyGovernance(self) returns (uint256 id) {
    id = DSU.generateId(_NAME, _TYPE);

    require(self._proposals[id].deadline == 0, "GU: NAME already proposed");

    require(
      (DATASTORE.readBytesForId(id, "NAME")).length == 0,
      "GU: ID already exist"
    );

    require(_CONTROLLER != address(0), "GU: CONTROLLER can NOT be ZERO");
    require(
      _TYPE != ID_TYPE.NONE && _TYPE != ID_TYPE.__GAP__,
      "GU: TYPE is NONE or GAP"
    );
    require(
      duration >= MIN_PROPOSAL_DURATION && duration <= MAX_PROPOSAL_DURATION,
      "GU: invalid proposal duration"
    );

    uint256 _deadline = block.timestamp + duration;

    self._proposals[id] = Proposal({
      CONTROLLER: _CONTROLLER,
      TYPE: _TYPE,
      NAME: _NAME,
      deadline: _deadline
    });

    emit Proposed(id, _CONTROLLER, _TYPE, _deadline);
  }

  /**
   * @notice onlySenate, approves a proposal and records given data to
   *  @notice specific changes for the reserved types (1,2,3) are implemented here,
   *  any other addition should take place in Portal, as not related
   *  @param id given ID proposal that has been approved by Senate
   *  @dev Senate is not able to approve approved proposals
   *  @dev Senate is not able to approve expired proposals
   *  @dev Senate is not able to approve SENATE proposals
   */
  function approveProposal(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id
  ) external onlySenate(self) returns (uint256 _type, address _controller) {
    require(
      self._proposals[id].deadline > block.timestamp,
      "GU: NOT an active proposal"
    );

    _type = self._proposals[id].TYPE;
    _controller = self._proposals[id].CONTROLLER;

    require(_type != ID_TYPE.SENATE, "GU: can NOT approve SENATE election");

    DATASTORE.writeUintForId(id, "TYPE", _type);
    DATASTORE.writeAddressForId(id, "CONTROLLER", _controller);
    DATASTORE.writeBytesForId(id, "NAME", self._proposals[id].NAME);
    DATASTORE.allIdsByType[_type].push(id);

    if (_type == ID_TYPE.CONTRACT_UPGRADE) {
      self.approvedVersion = _controller;
    }

    if (isElector(self, _type)) {
      self._electorCount += 1;
    }

    // important
    self._proposals[id].deadline = block.timestamp;

    emit ProposalApproved(id);
  }

  /**
   * @notice                                       ** SENATE ELECTIONS **
   */

  /**
   * @dev  ->  view
   */

  function isElector(
    DualGovernance storage self,
    uint256 _TYPE
  ) public view returns (bool) {
    return self._electorTypes[_TYPE];
  }

  /**
   * @dev  ->  internal
   */

  /**
   * @notice internal function to set a new senate with a given period
   */
  function _setSenate(
    DualGovernance storage self,
    address _newSenate,
    uint256 _expiry
  ) internal {
    self.SENATE = _newSenate;
    self.SENATE_EXPIRY = _expiry;

    emit NewSenate(self.SENATE, self.SENATE_EXPIRY);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice onlySenate, Sometimes it is useful to be able to change the Senate's address.
   * @dev does not change the expiry
   */
  function changeSenate(
    DualGovernance storage self,
    address _newSenate
  ) external onlySenate(self) {
    _setSenate(self, _newSenate, self.SENATE_EXPIRY);
  }

  /**
   * @notice onlyGovernance, only elector types can vote for senate
   * @param _TYPE selected type
   * @param _isElector true if selected _type can vote for senate from now on
   * @dev can not set with the same value again, preventing double increment/decrements
   */
  function setElectorType(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _TYPE,
    bool _isElector
  ) external onlyGovernance(self) {
    require(_isElector != isElector(self, _TYPE), "GU: type already elector");
    require(
      _TYPE > ID_TYPE.__GAP__,
      "GU: 0, Senate, Upgrade, GAP cannot be elector"
    );

    self._electorTypes[_TYPE] = _isElector;

    if (_isElector) {
      self._electorCount += DATASTORE.allIdsByType[_TYPE].length;
    } else {
      self._electorCount -= DATASTORE.allIdsByType[_TYPE].length;
    }

    emit ElectorTypeSet(_TYPE, _isElector);
  }

  /**
   * @notice onlyController, Proposed CONTROLLER is the new Senate after 2/3 of the electors approved
   * NOTE mathematically, min 3 elector is needed for (c+1)*2/3 to work properly
   * @notice id can not vote if:
   * - approved already
   * - proposal is expired
   * - not its type is elector
   * - not senate proposal
   * @param voterId should have the voting rights, msg.sender should be the CONTROLLER of given ID
   * @dev pins id as "voted" when approved
   * @dev increases "approvalCount" of proposalId by 1 when approved
   */
  function approveSenate(
    DualGovernance storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 proposalId,
    uint256 voterId
  ) external onlyController(DATASTORE, voterId) {
    uint256 _type = self._proposals[proposalId].TYPE;
    require(_type == ID_TYPE.SENATE, "GU: NOT Senate Proposal");
    require(
      self._proposals[proposalId].deadline >= block.timestamp,
      "GU: proposal expired"
    );
    require(
      isElector(self, DATASTORE.readUintForId(voterId, "TYPE")),
      "GU: NOT an elector"
    );
    require(
      DATASTORE.readUintForId(proposalId, DSU.getKey(voterId, "voted")) == 0,
      " GU: already approved"
    );

    DATASTORE.writeUintForId(proposalId, DSU.getKey(voterId, "voted"), 1);
    DATASTORE.addUintForId(proposalId, "approvalCount", 1);

    if (
      DATASTORE.readUintForId(proposalId, "approvalCount") >=
      ((self._electorCount + 1) * 2) / 3
    ) {
      self._proposals[proposalId].deadline = block.timestamp;
      _setSenate(
        self,
        self._proposals[proposalId].CONTROLLER,
        block.timestamp + MAX_SENATE_PERIOD
      );
    }

    emit Vote(proposalId, voterId);
  }

  /**
   * @notice                                       ** LIMITED UPGRADABILITY **
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice Get if it is allowed to change a specific contract with the current version.
   * @return True if it is allowed by senate and false if not.
   * @dev address(0) should return false
   * @dev DO NOT TOUCH, EVER! WHATEVER YOU DEVELOP IN FUCKING 3022
   **/
  function isUpgradeAllowed(
    DualGovernance storage self,
    address proposedImplementation
  ) external view returns (bool) {
    return
      self.approvedVersion != address(0) &&
      self.approvedVersion == proposedImplementation;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

// PERCENTAGE_DENOMINATOR represents 100%
uint256 constant PERCENTAGE_DENOMINATOR = 10 ** 10;

/**
 * @notice ID_TYPE is like an ENUM, widely used within Portal and Modules like Withdrawal Contract
 * @dev Why not use enums, they basically do the same thing?
 * * We like using a explicit defined uints than linearly increasing ones.
 */
library ID_TYPE {
  /// @notice TYPE 0: *invalid*
  uint256 internal constant NONE = 0;

  /// @notice TYPE 1: Senate and Senate Election Proposals
  uint256 internal constant SENATE = 1;

  /// @notice TYPE 2: Contract Upgrade
  uint256 internal constant CONTRACT_UPGRADE = 2;

  /// @notice TYPE 3: *gap*: formally represented the admin contract, now reserved to be never used
  uint256 internal constant __GAP__ = 3;

  /// @notice TYPE 4: Node Operators
  uint256 internal constant OPERATOR = 4;

  /// @notice TYPE 5: Staking Pools
  uint256 internal constant POOL = 5;

  /// @notice TYPE 21: Module: Withdrawal Contract
  uint256 internal constant MODULE_WITHDRAWAL_CONTRACT = 21;

  /// @notice TYPE 31: Module: A new gETH interface
  uint256 internal constant MODULE_GETH_INTERFACE = 31;

  /// @notice TYPE 41: Module: A new Liquidity Pool
  uint256 internal constant MODULE_LIQUDITY_POOL = 41;

  /// @notice TYPE 42: Module: A new Liquidity Pool token
  uint256 internal constant MODULE_LIQUDITY_POOL_TOKEN = 42;
}

/**
 * @notice VALIDATOR_STATE keeping track of validators within The Staking Library
 */
library VALIDATOR_STATE {
  /// @notice STATE 0: *invalid*
  uint8 internal constant NONE = 0;

  /// @notice STATE 1: validator is proposed, 1 ETH is sent from Operator to Deposit Contract
  uint8 internal constant PROPOSED = 1;

  /// @notice STATE 2: proposal was approved, operator used pooled funds, 1 ETH is released back to Operator
  uint8 internal constant ACTIVE = 2;

  /// @notice STATE 3: validator is exited, not currently used much
  uint8 internal constant EXITED = 3;

  /// @notice STATE 69: proposal was malicious(alien), maybe faulty signatures or probably: (https://bit.ly/3Tkc6UC)
  uint8 internal constant ALIENATED = 69;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {ID_TYPE, VALIDATOR_STATE, PERCENTAGE_DENOMINATOR} from "./globals.sol";

import {DataStoreUtils as DSU} from "./DataStoreUtilsLib.sol";
import {StakeUtils as SU} from "./StakeUtilsLib.sol";
import {DepositContractUtils as DCU} from "./DepositContractUtilsLib.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title OracleUtils Library: An extension to StakeUtils Library
 * @notice Oracle, named Telescope, handles some operations for The Staking Library,
 * * using the following logic, which is very simple.
 *
 * @dev Telescope is responsible from 3 tasks:
 * * Updating the on-chain price of all pools with a MerkleRoot
 * * Confirming validator proposals
 * * Regulating the Node Operators
 *
 * 1. reportOracle: Continous Data Flow: Price Merkle Root and MONOPOLY_THRESHOLD
 * * 1. Oracle Nodes calculates the price of its derivative,
 * * * according to the validator data such as balance and fees.
 * * 2. If a pool doesn't have a validator, price is kept the same.
 * * 3. A merkle tree is constructed with the order of allIdsByType array.
 * * 4. A watcher collects all the signatures from Multiple Oracle Nodes, and submits the merkle root.
 * * 5. Anyone can update the price of the derivative
 * * * by calling priceSync() functions with correct merkle proofs
 * * 6. Minting is allowed within PRICE_EXPIRY (24H) after the last price update.
 * * 7. Updates the regulation around Monopolies
 *
 * 2. updateVerificationIndex :Confirming validator proposals
 * * Simply, all proposed validator has an index bound to them,
 * * n representing the latest proposal: (0,n]
 * * Telescope verifies the validator data provided in proposeStake:
 * * especially sig1, sig31 and withdrawal credentials.
 * * Telescope confirms the latest index it verified and states the faulty validator proposals (aliens)
 * * If a validator proposal is faulty then it's state is set to 69.
 * * * 2 step process is essential to prevent the frontrunning
 * * * with a problematic withdrawalCredential, (https://bit.ly/3Tkc6UC)
 *
 * 3. regulateOperators: Regulating the Operators
 * * Operators can act faulty in many different ways. To prevent such actions,
 * * Telescope regulates them with well defined limitations.
 * * * Currently only issue is the fee theft, meaning operator have not
 * * * used the withdrawal contract for miner fees or MEV boost.
 * * * * There can be other restrictions in the future.
 *
 * @dev All 3 functions have OracleOnly modifier, priceSync functions do not.
 *
 * @dev first review DataStoreUtils
 * @dev then review StakeUtils
 */

library OracleUtils {
  /// @notice Using DataStoreUtils for IsolatedStorage struct
  using DSU for DSU.IsolatedStorage;

  /// @notice Using StakeUtils for PooledStaking struct
  using SU for SU.PooledStaking;

  /// @notice EVENTS
  event Alienated(bytes indexed pubkey);
  event VerificationIndexUpdated(uint256 validatorVerificationIndex);
  event FeeTheft(uint256 indexed id, bytes proofs);
  event OracleReported(bytes32 merkleRoot, uint256 monopolyThreshold);

  /// @notice effective on MONOPOLY_THRESHOLD, limiting the active validators, set to 1% at start.
  uint256 public constant MONOPOLY_RATIO = (1 * PERCENTAGE_DENOMINATOR) / 100;

  /// @notice sensible value for the total beacon chain validators, no reasoning.
  uint256 public constant MIN_VALIDATOR_COUNT = 50000;

  modifier onlyOracle(SU.PooledStaking storage STAKER) {
    require(msg.sender == STAKER.ORACLE_POSITION, "OU: sender NOT ORACLE");
    _;
  }

  /**
   * @notice                                     ** VERIFICATION INDEX **
   **/

  /**
   * @dev  ->  internal
   */

  /**
   * @notice "Alien" is a validator that is created with a faulty withdrawal
   * credential or signatures, this is a malicious act.
   * @notice Alienation results in imprisonment for the operator of the faulty validator proposal.
   * @dev While alienating a validator we should adjust the 'surplus' and 'secured'
   * balances of the pool accordingly
   * @dev We should adjust the 'totalProposedValidators', 'proposedValidators' to fix allowances.
   */
  function _alienateValidator(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    bytes calldata _pk
  ) internal {
    require(
      STAKER._validators[_pk].state == VALIDATOR_STATE.PROPOSED,
      "OU: NOT all pubkeys are pending"
    );
    require(
      STAKER._validators[_pk].index <= STAKER.VERIFICATION_INDEX,
      "OU: unexpected index"
    );
    SU._imprison(DATASTORE, STAKER._validators[_pk].operatorId, _pk);

    uint256 poolId = STAKER._validators[_pk].poolId;
    DATASTORE.subUintForId(poolId, "secured", DCU.DEPOSIT_AMOUNT);
    DATASTORE.addUintForId(poolId, "surplus", DCU.DEPOSIT_AMOUNT);

    uint256 operatorId = STAKER._validators[_pk].operatorId;
    DATASTORE.subUintForId(operatorId, "totalProposedValidators", 1);
    DATASTORE.subUintForId(
      poolId,
      DSU.getKey(operatorId, "proposedValidators"),
      1
    );

    STAKER._validators[_pk].state = VALIDATOR_STATE.ALIENATED;

    emit Alienated(_pk);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice Updating VERIFICATION_INDEX, signaling that it is safe to activate
   * the validator proposals with lower index than new VERIFICATION_INDEX
   * @param validatorVerificationIndex (inclusive) index of the highest validator that is verified to be activated
   * @param alienatedPubkeys faulty proposals within the range of new and old verification indexes.
   */
  function updateVerificationIndex(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    uint256 validatorVerificationIndex,
    bytes[] calldata alienatedPubkeys
  ) external onlyOracle(STAKER) {
    require(
      STAKER.VALIDATORS_INDEX >= validatorVerificationIndex,
      "OU: high VERIFICATION_INDEX"
    );
    require(
      validatorVerificationIndex > STAKER.VERIFICATION_INDEX,
      "OU: low VERIFICATION_INDEX"
    );

    STAKER.VERIFICATION_INDEX = validatorVerificationIndex;

    for (uint256 i; i < alienatedPubkeys.length; ++i) {
      _alienateValidator(DATASTORE, STAKER, alienatedPubkeys[i]);
    }

    emit VerificationIndexUpdated(validatorVerificationIndex);
  }

  /**
   * @notice                                     ** REGULATING OPERATORS **
   */

  /**
   * @dev  ->  external
   */

  /**
   * @notice regulating operators, currently only regulation is towards fee theft, can add more stuff in the future.
   * @param feeThefts Operator ids who have stolen MEV or block rewards detected
   * @param proofs  BlockNumber, tx or any other referance as a proof
   * @dev Stuff here result in imprisonment
   */
  function regulateOperators(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    uint256[] calldata feeThefts,
    bytes[] calldata proofs
  ) external onlyOracle(STAKER) {
    require(feeThefts.length == proofs.length, "OU: invalid proofs");
    for (uint256 i; i < feeThefts.length; ++i) {
      SU._imprison(DATASTORE, feeThefts[i], proofs[i]);

      emit FeeTheft(feeThefts[i], proofs[i]);
    }
  }

  /**
   * @notice                                     ** CONTINUOUS UPDATES **
   */

  /**
   * @dev  ->  external
   */

  /**
   * @notice Telescope reports all of the g-derivate prices with a new PRICE_MERKLE_ROOT.
   * Then, updates the ORACLE_UPDATE_TIMESTAMP and MONOPOLY_THRESHOLD
   * @param allValidatorsCount Number of all validators within BeaconChain, all of them.
   * Prevents monopolies.
   */
  function reportOracle(
    SU.PooledStaking storage STAKER,
    bytes32 priceMerkleRoot,
    uint256 allValidatorsCount
  ) external onlyOracle(STAKER) {
    require(
      allValidatorsCount > MIN_VALIDATOR_COUNT,
      "OU: low validator count"
    );

    STAKER.PRICE_MERKLE_ROOT = priceMerkleRoot;
    STAKER.ORACLE_UPDATE_TIMESTAMP = block.timestamp;

    uint256 newThreshold = (allValidatorsCount * MONOPOLY_RATIO) /
      PERCENTAGE_DENOMINATOR;
    STAKER.MONOPOLY_THRESHOLD = newThreshold;

    emit OracleReported(priceMerkleRoot, newThreshold);
  }

  /**
   * @notice                                     ** Updating PricePerShare **
   */

  /**
   * @dev  ->  internal
   */

  /**
   * @dev in order to prevent faulty updates to the derivative prices there are boundaries to price updates.
   * 1. Price should not be increased more than DAILY_PRICE_INCREASE_LIMIT
   *  with the factor of how many days since priceUpdateTimestamp has past.
   * 2. Price should not be decreased more than DAILY_PRICE_DECREASE_LIMIT
   *  with the factor of how many days since priceUpdateTimestamp has past.
   */
  function _sanityCheck(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    uint256 _id,
    uint256 _newPrice
  ) internal view {
    require(
      DATASTORE.readUintForId(_id, "TYPE") == ID_TYPE.POOL,
      "OU: not a pool?"
    );

    uint256 lastUpdate = STAKER.gETH.priceUpdateTimestamp(_id);
    uint256 dayPercentSinceUpdate = ((block.timestamp - lastUpdate) *
      PERCENTAGE_DENOMINATOR) / 1 days;

    uint256 curPrice = STAKER.gETH.pricePerShare(_id);

    uint256 maxPrice = curPrice +
      ((curPrice * STAKER.DAILY_PRICE_INCREASE_LIMIT * dayPercentSinceUpdate) /
        PERCENTAGE_DENOMINATOR) /
      PERCENTAGE_DENOMINATOR;

    uint256 minPrice = curPrice -
      ((curPrice * STAKER.DAILY_PRICE_DECREASE_LIMIT * dayPercentSinceUpdate) /
        PERCENTAGE_DENOMINATOR /
        PERCENTAGE_DENOMINATOR);

    require(
      _newPrice >= minPrice && _newPrice <= maxPrice,
      "OU: price is insane"
    );
  }

  /**
   * @notice syncing the price of g-derivatives after checking the merkle proofs and the sanity of the price.
   * @param _price price of the derivative denominated in gETH.denominator()
   * @param _priceProof merkle proofs
   */
  function _priceSync(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    uint256 _poolId,
    uint256 _price,
    bytes32[] calldata _priceProof
  ) internal {
    bytes32 leaf = keccak256(
      bytes.concat(keccak256(abi.encode(_poolId, _price)))
    );
    require(
      MerkleProof.verify(_priceProof, STAKER.PRICE_MERKLE_ROOT, leaf),
      "OU: NOT all proofs are valid"
    );

    _sanityCheck(DATASTORE, STAKER, _poolId, _price);

    STAKER.gETH.setPricePerShare(_price, _poolId);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice external function to set a derivative price on Portal
   * @param price price of the derivative denominated in gETH.denominator()
   * @param priceProof merkle proofs
   */
  function priceSync(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    uint256 poolId,
    uint256 price,
    bytes32[] calldata priceProof
  ) external {
    _priceSync(DATASTORE, STAKER, poolId, price, priceProof);
  }

  /**
   * @notice external function to set a multiple derivatives price at once, saves gas.
   * @param prices price of the derivative denominated in gETH.denominator()
   * @param priceProofs merkle proofs
   */
  function priceSyncBatch(
    DSU.IsolatedStorage storage DATASTORE,
    SU.PooledStaking storage STAKER,
    uint256[] calldata poolIds,
    uint256[] calldata prices,
    bytes32[][] calldata priceProofs
  ) external {
    require(poolIds.length == prices.length);
    require(poolIds.length == priceProofs.length);
    for (uint256 i = 0; i < poolIds.length; ++i) {
      _priceSync(DATASTORE, STAKER, poolIds[i], prices[i], priceProofs[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ID_TYPE, VALIDATOR_STATE, PERCENTAGE_DENOMINATOR} from "./globals.sol";

import {DataStoreUtils as DSU} from "./DataStoreUtilsLib.sol";
import {DepositContractUtils as DCU} from "./DepositContractUtilsLib.sol";

import {IgETH} from "../../interfaces/IgETH.sol";
import {IWithdrawalContract} from "../../interfaces/IWithdrawalContract.sol";
import {ISwap} from "../../interfaces/ISwap.sol";
import {ILPToken} from "../../interfaces/ILPToken.sol";
import {IWhitelist} from "../../interfaces/IWhitelist.sol";
import {IgETHInterface} from "../../interfaces/IgETHInterface.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title The Staking Library
 * @notice Creating a global standard for Staking, allowing anyone to create a trustless staking pool,
 * improving the user experience for stakers and removing the need for intermediaries.
 * * Exclusively contains functions related to:
 * * 1. Modular Architecture of Configurable Staking Pools
 * * 2. Operator Marketplace and Staking Operations.
 * @dev It is important to keep every pool isolated and remember that every validator is unique.
 *
 * @dev Controllers and Maintainers:
 * * CONTROLLER is the owner of an ID, it manages the pool or the operator and its security is exteremely important.
 * * maintainer is the worker, can be used to automate some daily tasks
 * * * like distributing validators for Staking Pools or creating validators for Operators,
 * * * not so crucial in terms of security.
 *
 * @dev Reserved ID_TYPE:
 *
 * USERS:
 *
 * * Type 4 : Permissioned Operators
 * * * Needs to be onboarded by the Dual Governance (Senate + Governance).
 * * * Maintains Beacon Chain Validators on behalf of the Staking Pools.
 * * * Can participate in the Operator Marketplace after initiation.
 * * * Can utilize maintainers for staking operations.
 *
 * * Type 5 : Configurable Staking Pools
 * * * Permissionless to create.
 * * * Can utilize powers of modules such as Bound Liquidity Pools, Interfaces etc.
 * * * Can be public or private, can use a whitelist if private.
 * * * Can utilize maintainers for validator distribution on Operator Marketplace.
 * * * Uses a Withdrawal Contract to be given as withdrawalCredential on validator creation,
 * * * accruing rewards and keeping Staked Ether safe and isolated.
 *
 * DEFAULT MODULES:
 * * Some Modules has only 1 version that can be used by the Pool Owners.
 *
 * * Type 21 : Withdrawal Contract implementation version
 * * * Mandatory.
 * * * CONTROLLER is the implementation contract position (like always)
 * * * Requires the approval of Senate
 * * * Pools are in "Recovery Mode" until their Withdrawal Contract is upgraded.
 * * * * Meaning, no more Depositing or Staking can happen.
 *
 * * Type 41 : Liquidity Pool version
 * * * Optional.
 * * * CONTROLLER is the implementation contract position (like always)
 * * * Requires the approval of Senate.
 * * * Pools can simply deploy the new version of this Module and start using it, if ever changed.
 * * * Liquidity Providers however, need to migrate.
 *
 * * Type 42 : Liquidity Pool Token version
 * * * Optional, dependant to Liquidity Pool Module.
 * * * CONTROLLER is the implementation contract position (like always)
 * * * Requires the approval of Senate
 * * * Crucial to have the same name with the LP version
 *
 * ALLOWED MODULES:
 * * Some Modules can support many different versions that can be used by the Pool Owners.
 *
 * * Type 31 : gETH interface version
 * * * Optional.
 * * * CONTROLLER is the implementation contract position (like always)
 * * * Requires the approval of Senate
 * * * Currently should be utilized on initiation.
 *
 * @dev Contracts relying on this library must initialize StakeUtils.PooledStaking
 * @dev Functions are already protected with authentication
 *
 * @dev first review DataStoreUtils
 * @dev then review GeodeUtils
 */

library StakeUtils {
  /// @notice Using DataStoreUtils for IsolatedStorage struct
  using DSU for DSU.IsolatedStorage;

  /// @notice EVENTS
  event IdInitiated(uint256 indexed id, uint256 indexed TYPE);
  event MaintainerChanged(uint256 indexed id, address newMaintainer);
  event FeeSwitched(uint256 indexed id, uint256 fee, uint256 effectiveAfter);
  event ValidatorPeriodSwitched(
    uint256 indexed id,
    uint256 period,
    uint256 effectiveAfter
  );
  event OperatorApproval(
    uint256 indexed poolId,
    uint256 indexed operatorId,
    uint256 allowance
  );
  event Prisoned(uint256 indexed id, bytes proof, uint256 releaseTimestamp);
  event Deposit(uint256 indexed poolId, uint256 boughtgETH, uint256 mintedgETH);
  event ProposalStaked(
    uint256 indexed poolId,
    uint256 operatorId,
    bytes[] pubkeys
  );
  event BeaconStaked(bytes[] pubkeys);

  /**
   * @param state state of the validator, refer to globals.sol
   * @param index representing this validator's placement on the chronological order of the validators proposals
   * @param poolId needed for withdrawal_credential
   * @param operatorId needed for staking after allowance
   * @param poolFee percentage of the rewards that will go to pool's maintainer, locked when the validator is proposed
   * @param operatorFee percentage of the rewards that will go to operator's maintainer, locked when the validator is proposed
   * @param createdAt the timestamp pointing the proposal to create a validator with given pubkey.
   * @param expectedExit the latest point in time the operator is allowed to maintain this validator (createdAt + validatorPeriod).
   * @param signature BLS12-381 signature for the validator, used when sending the remaining 31 ETH on validator activation.
   **/
  struct Validator {
    uint8 state;
    uint256 index;
    uint256 poolId;
    uint256 operatorId;
    uint256 poolFee;
    uint256 operatorFee;
    uint256 earlyExitFee;
    uint256 createdAt;
    uint256 expectedExit;
    bytes signature31;
  }

  /**
   * @param gETH ERC1155, Staking Derivatives Token, should NOT be changed.
   * @param VALIDATORS_INDEX total number of validators that are proposed at any given point.
   * * Includes all validators: proposed, active, alienated, exited.
   * @param VERIFICATION_INDEX the highest index of the validators that are verified (as not alien) by the Holy Oracle.
   * @param MONOPOLY_THRESHOLD max number of validators 1 operator is allowed to operate, updated by the Holy Oracle.
   * @param EARLY_EXIT_FEE a parameter to be used while handling the validator exits, currently 0 and logic around it is ambigious.
   * @param ORACLE_UPDATE_TIMESTAMP timestamp of the latest oracle update
   * @param DAILY_PRICE_DECREASE_LIMIT limiting the price decreases for one oracle period, 24h. Effective for any time interval.
   * @param DAILY_PRICE_INCREASE_LIMIT limiting the price increases for one oracle period, 24h. Effective for any time interval.
   * @param PRICE_MERKLE_ROOT merkle root of the prices of every pool
   * @param ORACLE_POSITION address of the Oracle multisig https://github.com/Geodefi/Telescope-Eth
   * @param _defaultModules TYPE => version, pointing to the latest versions of the given TYPE.
   * * Like default Withdrawal Contract version.
   * @param _allowedModules TYPE => version => isAllowed, useful to check if any version of the module can be used.
   * * Like all the whitelisted gETH interfaces.
   * @param _validators pubkey => Validator, contains all the data about proposed or/and active validators
   * @param __gap keep the struct size at 16
   **/
  struct PooledStaking {
    IgETH gETH;
    uint256 VALIDATORS_INDEX;
    uint256 VERIFICATION_INDEX;
    uint256 MONOPOLY_THRESHOLD;
    uint256 EARLY_EXIT_FEE;
    uint256 ORACLE_UPDATE_TIMESTAMP;
    uint256 DAILY_PRICE_INCREASE_LIMIT;
    uint256 DAILY_PRICE_DECREASE_LIMIT;
    bytes32 PRICE_MERKLE_ROOT;
    address ORACLE_POSITION;
    mapping(uint256 => uint256) _defaultModules;
    mapping(uint256 => mapping(uint256 => bool)) _allowedModules;
    mapping(bytes => Validator) _validators;
    uint256[3] __gap;
  }
  /**
   * @notice                                     ** Constants **
   */

  /// @notice limiting the pool and operator maintenance fee, 10%
  uint256 public constant MAX_MAINTENANCE_FEE =
    (PERCENTAGE_DENOMINATOR * 10) / 100;

  /// @notice limiting EARLY_EXIT_FEE, 5%
  uint256 public constant MAX_EARLY_EXIT_FEE =
    (PERCENTAGE_DENOMINATOR * 5) / 100;

  /// @notice price of gETH is only valid for 24H, after that minting is not allowed.
  uint256 public constant PRICE_EXPIRY = 24 hours;

  /// @notice ignoring any buybacks if the Liquidity Pools has a low debt
  uint256 public constant IGNORABLE_DEBT = 1 ether;

  /// @notice limiting the operator.validatorPeriod, between 3 months to 5 years
  uint256 public constant MIN_VALIDATOR_PERIOD = 90 days;
  uint256 public constant MAX_VALIDATOR_PERIOD = 1825 days;

  /// @notice some parameter changes are effective after a delay
  uint256 public constant SWITCH_LATENCY = 3 days;

  /// @notice limiting the access for Operators in case of bad/malicious/faulty behaviour
  uint256 public constant PRISON_SENTENCE = 14 days;

  /**
   * @notice                                     ** AUTHENTICATION **
   */

  /**
   * @dev  ->  internal
   */

  /**
   * @notice restricts the access to given function based on TYPE and msg.sender
   * @param expectCONTROLLER restricts the access to only CONTROLLER.
   * @param expectMaintainer restricts the access to only maintainer.
   * @param restrictionMap Restricts which TYPEs can pass the authentication 0: Operator = TYPE(4), Pool = TYPE(5)
   * @dev authenticate can only be used after an ID is initiated
   * @dev CONTROLLERS and maintainers of the Prisoned Operators can not access.
   * @dev In principal, CONTROLLER should be able to do anything a maintainer is authenticated to do.
   */
  function authenticate(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    bool expectCONTROLLER,
    bool expectMaintainer,
    bool[2] memory restrictionMap
  ) internal view {
    require(
      DATASTORE.readUintForId(id, "initiated") != 0,
      "SU: ID is not initiated"
    );

    uint256 typeOfId = DATASTORE.readUintForId(id, "TYPE");

    if (typeOfId == ID_TYPE.OPERATOR) {
      require(restrictionMap[0], "SU: TYPE NOT allowed");
      if (expectCONTROLLER || expectMaintainer) {
        require(
          !isPrisoned(DATASTORE, id),
          "SU: operator is in prison, get in touch with governance"
        );
      }
    } else if (typeOfId == ID_TYPE.POOL) {
      require(restrictionMap[1], "SU: TYPE NOT allowed");
    } else revert("SU: invalid TYPE");

    if (expectMaintainer) {
      require(
        msg.sender == DATASTORE.readAddressForId(id, "maintainer"),
        "SU: sender NOT maintainer"
      );
      return;
    }

    if (expectCONTROLLER) {
      require(
        msg.sender == DATASTORE.readAddressForId(id, "CONTROLLER"),
        "SU: sender NOT CONTROLLER"
      );
      return;
    }
  }

  /**
   * @notice                                     ** CONFIGURABLE STAKING POOL MODULES **
   *
   * - WithdrawalContracts
   * - gETHInterfaces
   * - Bound Liquidity Pools
   * - Pool visibility (public/private) and using whitelists
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice access all interfaces of a given ID.
   * @dev for future referance: unsetted interfaces SHOULD return address(0)
   */
  function gETHInterfaces(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    uint256 index
  ) external view returns (address _interface) {
    _interface = DATASTORE.readAddressArrayForId(id, "interfaces", index);
  }

  /**
   * @notice returns true if the pool is private
   */
  function isPrivatePool(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId
  ) public view returns (bool) {
    return (DATASTORE.readUintForId(poolId, "private") == 1);
  }

  /**
   * @dev  ->  internal
   */

  /**
   * @notice internal function to set a gETHInterface
   * @param _interface address of the new gETHInterface for given ID
   * @dev every interface has a unique index within the "interfaces" dynamic array.
   * @dev on unset, SHOULD replace the implementation with address(0) for obvious security reasons.
   */
  function _setInterface(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    address _interface
  ) internal {
    require(!self.gETH.isInterface(_interface, id), "SU: already interface");
    DATASTORE.appendAddressArrayForId(id, "interfaces", _interface);
    self.gETH.setInterface(_interface, id, true);
  }

  /**
   * @notice deploys a new gETHInterface by cloning the DEFAULT_gETH_INTERFACE
   * @param _version id, can use any version as an interface that is allowed for TYPE = MODULE_GETH_INTERFACE
   * @param interface_data interfaces might require additional data on initialization; like name, symbol, etc.
   * @dev currrently, can NOT deploy an interface after initiation, thus only used by the initiator.
   * @dev currrently, can NOT unset an interface.
   */
  function _deployInterface(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _id,
    uint256 _version,
    bytes memory interface_data
  ) internal {
    require(
      self._allowedModules[ID_TYPE.MODULE_GETH_INTERFACE][_version],
      "SU: not an interface"
    );

    address gInterface = Clones.clone(
      DATASTORE.readAddressForId(_version, "CONTROLLER")
    );

    require(
      IgETHInterface(gInterface).initialize(
        _id,
        address(self.gETH),
        interface_data
      ),
      "SU: could not init interface"
    );

    _setInterface(self, DATASTORE, _id, gInterface);
  }

  /**
   * @notice Deploys a Withdrawal Contract that will be used as a withdrawal credential on validator creation
   * @dev using the latest version of the MODULE_WITHDRAWAL_CONTRACT
   * @dev every pool requires a withdrawal Contract, thus this function is only used by the initiator
   */
  function _deployWithdrawalContract(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _id
  ) internal {
    require(
      DATASTORE.readAddressForId(_id, "withdrawalContract") == address(0),
      "SU: already has a withdrawal contract"
    );

    uint256 version = self._defaultModules[ID_TYPE.MODULE_WITHDRAWAL_CONTRACT];

    address withdrawalContract = address(
      new ERC1967Proxy(
        DATASTORE.readAddressForId(version, "CONTROLLER"),
        abi.encodeWithSelector(
          IWithdrawalContract(address(0)).initialize.selector,
          version,
          _id,
          self.gETH,
          address(this),
          DATASTORE.readAddressForId(_id, "CONTROLLER")
        )
      )
    );

    DATASTORE.writeAddressForId(_id, "withdrawalContract", withdrawalContract);

    DATASTORE.writeBytesForId(
      _id,
      "withdrawalCredential",
      DCU.addressToWC(withdrawalContract)
    );
  }

  /**
   * @dev  ->  public
   */

  /**
   * @notice deploys a new liquidity pool using the latest version of MODULE_LIQUDITY_POOL
   * @dev sets the liquidity pool, LP token and liquidityPoolVersion
   * @dev gives full allowance to the pool, should not be a problem as portal does not hold any tokens
   * @param _GOVERNANCE governance address will be the owner of the created pool.
   * @dev a controller can deploy a liquidity pool after initiation
   * @dev a controller can deploy a new version of this module, but LPs would need to migrate
   */
  function deployLiquidityPool(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    address _GOVERNANCE
  ) public {
    authenticate(DATASTORE, poolId, true, false, [false, true]);
    uint256 lpVersion = self._defaultModules[ID_TYPE.MODULE_LIQUDITY_POOL];

    require(
      DATASTORE.readUintForId(poolId, "liquidityPoolVersion") != lpVersion,
      "SU: already latest version"
    );

    address lp = Clones.clone(
      DATASTORE.readAddressForId(lpVersion, "CONTROLLER")
    );
    bytes memory NAME = DATASTORE.readBytesForId(poolId, "NAME");

    require(
      ISwap(lp).initialize(
        IgETH(self.gETH),
        poolId,
        string(abi.encodePacked(NAME, "-Geode LP Token")),
        string(abi.encodePacked(NAME, "-LP")),
        DATASTORE.readAddressForId(
          self._defaultModules[ID_TYPE.MODULE_LIQUDITY_POOL_TOKEN],
          "CONTROLLER"
        ),
        _GOVERNANCE
      ) != address(0),
      "SU: could not init liquidity pool"
    );

    // approve token so we can use it in buybacks
    self.gETH.setApprovalForAll(lp, true);

    DATASTORE.writeUintForId(poolId, "liquidityPoolVersion", lpVersion);
    DATASTORE.writeAddressForId(poolId, "liquidityPool", lp);
  }

  /**
   * @notice changes the visibility of the pool
   * @param isPrivate true if pool should be private, false for public pools
   * Note private pools can whitelist addresses with the help of a third party contract.
   */
  function setPoolVisibility(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    bool isPrivate
  ) public {
    authenticate(DATASTORE, poolId, true, false, [false, true]);

    require(isPrivate != isPrivatePool(DATASTORE, poolId), "SU: already set");

    DATASTORE.writeUintForId(poolId, "private", isPrivate ? 1 : 0);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice private pools can whitelist addresses with the help of a third party contract
   * @dev Whitelisting contracts should implement IWhitelist interface.
   */
  function setWhitelist(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    address whitelist
  ) external {
    authenticate(DATASTORE, poolId, true, false, [false, true]);
    require(isPrivatePool(DATASTORE, poolId), "SU: must be private pool");
    DATASTORE.writeAddressForId(poolId, "whitelist", whitelist);
  }

  /**
   * @notice                                     ** INITIATORS **
   *
   * IDs that are occupied by a user should be initiated to be activated
   * - Operators need to onboarded by the Dual Governance to be able to initiate an ID.
   * - Pools are permissionless, calling the initiator will immediately activate the pool.
   */

  /**
   * @dev  ->  external
   */

  /**
   * @notice initiates ID as a Permissionned Node Operator
   * @notice requires ID to be approved as a node operator with a specific CONTROLLER
   * @param fee as a percentage limited by MAX_MAINTENANCE_FEE, PERCENTAGE_DENOMINATOR is 100%
   * @param validatorPeriod the expected maximum staking interval. This value should between
   * * MIN_VALIDATOR_PERIOD and MAX_VALIDATOR_PERIOD values defined as constants above.
   * Operator can unstake at any given point before this period ends.
   * If operator disobeys this rule, it can be prisoned with blameOperator()
   * @param maintainer an address that automates daily operations, a script, a contract...
   * @dev operators can fund their internal wallet on initiation by simply sending some ether.
   */
  function initiateOperator(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    uint256 fee,
    uint256 validatorPeriod,
    address maintainer
  ) external {
    require(
      DATASTORE.readUintForId(id, "initiated") == 0,
      "SU: already initiated"
    );

    require(
      DATASTORE.readUintForId(id, "TYPE") == ID_TYPE.OPERATOR,
      "SU: TYPE NOT allowed"
    );

    require(
      msg.sender == DATASTORE.readAddressForId(id, "CONTROLLER"),
      "SU: sender NOT CONTROLLER"
    );

    _setMaintainer(DATASTORE, id, maintainer);
    _setMaintenanceFee(DATASTORE, id, fee);
    _setValidatorPeriod(DATASTORE, id, validatorPeriod);

    _increaseWalletBalance(DATASTORE, id, msg.value);

    DATASTORE.writeUintForId(id, "initiated", block.timestamp);
    emit IdInitiated(id, ID_TYPE.OPERATOR);
  }

  /**
   * @notice Creates a Configurable Trustless Staking Pool!
   * @param fee as a percentage limited by MAX_MAINTENANCE_FEE, PERCENTAGE_DENOMINATOR is 100%
   * @param interfaceVersion Pool creators can choose any allowed version as their gETHInterface
   * @param maintainer an address that automates daily operations, a script, a contract... not really powerful.
   * @param _GOVERNANCE needed in case the Pool is configured with a Bound Liquidity Pool
   * @param NAME used to generate an ID for the Pool
   * @param interface_data interfaces might require additional data on initialization; like name, symbol, etc.
   * @param config [private(true) or public(false), deploying an interface with given version, deploying liquidity pool with latest version]
   * @dev checking only initiated is enough to validate that ID is not used. no need to check TYPE, CONTROLLER etc.
   * @dev requires exactly 1 validator worth of funds to be deposited on initiation - to prevent sybil attacks
   */
  function initiatePool(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 fee,
    uint256 interfaceVersion,
    address maintainer,
    address _GOVERNANCE,
    bytes calldata NAME,
    bytes calldata interface_data,
    bool[3] calldata config
  ) external {
    require(
      msg.value == DCU.DEPOSIT_AMOUNT,
      "SU: requires 1 validator worth of Ether"
    );

    uint256 id = DSU.generateId(NAME, ID_TYPE.POOL);

    require(id > 10 ** 7, "SU: Wow! low id");

    require(
      DATASTORE.readUintForId(id, "initiated") == 0,
      "SU: already initiated"
    );
    DATASTORE.writeUintForId(id, "TYPE", ID_TYPE.POOL);
    DATASTORE.writeAddressForId(id, "CONTROLLER", msg.sender);
    DATASTORE.writeBytesForId(id, "NAME", NAME);
    DATASTORE.writeUintForId(id, "initiated", block.timestamp);
    DATASTORE.allIdsByType[ID_TYPE.POOL].push(id);

    _setMaintainer(DATASTORE, id, maintainer);
    _setMaintenanceFee(DATASTORE, id, fee);

    _deployWithdrawalContract(self, DATASTORE, id);
    if (config[0]) setPoolVisibility(DATASTORE, id, true);
    if (config[1])
      _deployInterface(self, DATASTORE, id, interfaceVersion, interface_data);
    if (config[2]) deployLiquidityPool(self, DATASTORE, id, _GOVERNANCE);

    // initially 1 ETHER = 1 ETHER
    self.gETH.setPricePerShare(1 ether, id);

    // mint gETH and send back to the caller
    uint256 mintedgETH = _mintgETH(self, DATASTORE, id, DCU.DEPOSIT_AMOUNT);
    self.gETH.safeTransferFrom(address(this), msg.sender, id, mintedgETH, "");

    emit IdInitiated(id, ID_TYPE.POOL);
  }

  /**
   * @notice                                     ** MAINTAINERS **
   */

  /**
   * @dev  ->  internal
   */

  /**
   * @notice Set the maintainer address on initiation or later
   * @param newMaintainer address of the new maintainer
   */
  function _setMaintainer(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    address newMaintainer
  ) internal {
    require(newMaintainer != address(0), "SU: maintainer can NOT be zero");

    address currentMaintainer = DATASTORE.readAddressForId(id, "maintainer");

    require(
      currentMaintainer != newMaintainer,
      "SU: provided the current maintainer"
    );

    DATASTORE.writeAddressForId(id, "maintainer", newMaintainer);
    emit MaintainerChanged(id, newMaintainer);
  }

  /**
   * @dev  ->  external
   */
  /**
   * @notice CONTROLLER of the ID can change the maintainer to any address other than ZERO_ADDRESS
   * @dev there can only be 1 maintainer per ID.
   * @dev it is wise to change the maintainer before the CONTROLLER, in case of any migration
   */
  function changeMaintainer(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    address newMaintainer
  ) external {
    authenticate(DATASTORE, id, true, false, [true, true]);
    _setMaintainer(DATASTORE, id, newMaintainer);
  }

  /**
   * @notice                                     ** MAINTENANCE FEE **
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice Gets fee as a percentage, PERCENTAGE_DENOMINATOR = 100%
   * @return fee = percentage * PERCENTAGE_DENOMINATOR / 100
   */
  function getMaintenanceFee(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id
  ) public view returns (uint256 fee) {
    if (DATASTORE.readUintForId(id, "feeSwitch") > block.timestamp) {
      return DATASTORE.readUintForId(id, "priorFee");
    }
    return DATASTORE.readUintForId(id, "fee");
  }

  /**
   * @dev  ->  internal
   */

  /**
   * @notice  internal function to set fee with NO DELAY
   */
  function _setMaintenanceFee(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _id,
    uint256 _newFee
  ) internal {
    require(_newFee <= MAX_MAINTENANCE_FEE, "SU: > MAX_MAINTENANCE_FEE ");
    DATASTORE.writeUintForId(_id, "fee", _newFee);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice Changes the fee that is applied to the newly created validators, with A DELAY OF SWITCH_LATENCY.
   * Note Can NOT be called again while its currently switching.
   * @dev advise that 100% == PERCENTAGE_DENOMINATOR
   */
  function switchMaintenanceFee(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    uint256 newFee
  ) external {
    authenticate(DATASTORE, id, true, false, [true, true]);

    require(
      block.timestamp > DATASTORE.readUintForId(id, "feeSwitch"),
      "SU: fee is currently switching"
    );

    DATASTORE.writeUintForId(
      id,
      "priorFee",
      DATASTORE.readUintForId(id, "fee")
    );
    DATASTORE.writeUintForId(id, "feeSwitch", block.timestamp + SWITCH_LATENCY);

    _setMaintenanceFee(DATASTORE, id, newFee);

    emit FeeSwitched(id, newFee, block.timestamp + SWITCH_LATENCY);
  }

  /**
   * @notice                                     ** INTERNAL WALLET **
   *
   * Internal wallet of an ID accrues fees over time.
   * It is also used by Node Operators to fund 1 ETH per validator proposal, which is reimbursed if/when activated.
   */

  /**
   * @dev  ->  internal
   */

  /**
   * @notice Simply increases the balance of an IDs Maintainer wallet
   * @param _value Ether (in Wei) amount to increase the wallet balance.
   * @return success if the amount was deducted
   */
  function _increaseWalletBalance(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _id,
    uint256 _value
  ) internal returns (bool success) {
    DATASTORE.addUintForId(_id, "wallet", _value);
    return true;
  }

  /**
   * @notice To decrease the balance of an Operator's wallet internally
   * @param _value Ether (in Wei) amount to decrease the wallet balance and send back to Maintainer.
   */
  function _decreaseWalletBalance(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _id,
    uint256 _value
  ) internal returns (bool success) {
    require(
      DATASTORE.readUintForId(_id, "wallet") >= _value,
      "SU: NOT enough funds in wallet"
    );
    DATASTORE.subUintForId(_id, "wallet", _value);
    return true;
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice external function to increase the internal wallet balance
   * @dev anyone can increase the balance directly, useful for withdrawalContracts and fees etc.
   */
  function increaseWalletBalance(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id
  ) external returns (bool success) {
    authenticate(DATASTORE, id, false, false, [true, true]);
    return _increaseWalletBalance(DATASTORE, id, msg.value);
  }

  /**
   * @notice external function to decrease the internal wallet balance
   * @dev only CONTROLLER can decrease the balance externally,
   * @return success if the amount was sent and deducted
   */
  function decreaseWalletBalance(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 id,
    uint256 value
  ) external returns (bool success) {
    authenticate(DATASTORE, id, true, false, [true, true]);

    require(address(this).balance >= value, "SU: not enough funds in Portal ?");

    bool decreased = _decreaseWalletBalance(DATASTORE, id, value);

    (bool sent, ) = payable(DATASTORE.readAddressForId(id, "CONTROLLER")).call{
      value: value
    }("");
    require(decreased && sent, "SU: Failed to send ETH");
    return sent;
  }

  /**
   * @notice                                     ** PRISON **
   *
   * When node operators act in a malicious way, which can also be interpereted as
   * an honest mistake like using a faulty signature, Oracle imprisons the operator.
   * These conditions are:
   * * 1. Created a malicious validator(alien): faulty withdrawal credential, faulty signatures etc.
   * * 2. Have not respect the validatorPeriod
   * * 3. Stole block fees or MEV boost rewards from the pool
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice Checks if the given operator is Prisoned
   * @dev "released" key refers to the end of the last imprisonment, when the limitations of operator is lifted
   */
  function isPrisoned(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _operatorId
  ) public view returns (bool) {
    return (block.timestamp < DATASTORE.readUintForId(_operatorId, "released"));
  }

  /**
   * @dev  ->  internal
   */

  /**
   * @notice Put an operator in prison
   * @dev "released" key refers to the end of the last imprisonment, when the limitations of operator is lifted
   */
  function _imprison(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _operatorId,
    bytes calldata proof
  ) internal {
    authenticate(DATASTORE, _operatorId, false, false, [true, false]);

    DATASTORE.writeUintForId(
      _operatorId,
      "released",
      block.timestamp + PRISON_SENTENCE
    );

    emit Prisoned(_operatorId, proof, block.timestamp + PRISON_SENTENCE);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice allows imprisoning an Operator if the validator have not been exited until expectedExit
   * @dev anyone can call this function
   * @dev if operator has given enough allowance, they SHOULD rotate the validators to avoid being prisoned
   */
  function blameOperator(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    bytes calldata pk
  ) external {
    require(
      self._validators[pk].state == VALIDATOR_STATE.ACTIVE,
      "SU: validator is never activated"
    );
    require(
      block.timestamp > self._validators[pk].expectedExit,
      "SU: validator is still active"
    );

    _imprison(DATASTORE, self._validators[pk].operatorId, pk);
  }

  /**
   * @notice                                     ** OPERATOR FUNCTIONS **
   */

  /**
   * @dev  ->  internal
   */

  /**
   * @notice internal function to set validator period with NO DELAY
   */
  function _setValidatorPeriod(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _operatorId,
    uint256 _newPeriod
  ) internal {
    require(
      _newPeriod >= MIN_VALIDATOR_PERIOD,
      "SU: should be more than MIN_VALIDATOR_PERIOD"
    );

    require(
      _newPeriod <= MAX_VALIDATOR_PERIOD,
      "SU: should be less than MAX_VALIDATOR_PERIOD"
    );

    DATASTORE.writeUintForId(_operatorId, "validatorPeriod", _newPeriod);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice updates validatorPeriod for given operator, with A DELAY OF SWITCH_LATENCY.
   * @dev limited by MIN_VALIDATOR_PERIOD and MAX_VALIDATOR_PERIOD
   */
  function switchValidatorPeriod(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 operatorId,
    uint256 newPeriod
  ) external {
    authenticate(DATASTORE, operatorId, true, true, [true, false]);

    require(
      block.timestamp > DATASTORE.readUintForId(operatorId, "periodSwitch"),
      "SU: period is currently switching"
    );

    DATASTORE.writeUintForId(
      operatorId,
      "priorPeriod",
      DATASTORE.readUintForId(operatorId, "validatorPeriod")
    );
    DATASTORE.writeUintForId(
      operatorId,
      "periodSwitch",
      block.timestamp + SWITCH_LATENCY
    );

    _setValidatorPeriod(DATASTORE, operatorId, newPeriod);

    emit ValidatorPeriodSwitched(
      operatorId,
      newPeriod,
      block.timestamp + SWITCH_LATENCY
    );
  }

  /**
   * @notice                                     ** OPERATOR MARKETPLACE **
   */

  /**
   * @dev  ->  view
   */

  /** *
   * @notice operatorAllowance is the maximum number of validators that the given Operator is allowed to create on behalf of the Pool
   * @dev an operator can not create new validators if:
   * * 1. allowance is 0 (zero)
   * * 2. lower than the current (proposed + active) number of validators
   * * But if operator withdraws a validator, then able to create a new one.
   * @dev prestake checks the approved validator count to make sure the number of validators are not bigger than allowance
   * @dev allowance doesn't change when new validators created or old ones are unstaked.
   */
  function operatorAllowance(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    uint256 operatorId
  ) public view returns (uint256 allowance) {
    allowance = DATASTORE.readUintForId(
      poolId,
      DSU.getKey(operatorId, "allowance")
    );
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice To allow a Node Operator run validators for your Pool with a given number of validators.
   * * This number can be set again at any given point in the future.
   * @param poolId the gETH id of the Pool
   * @param operatorIds array of Operator IDs to allow them create validators
   * @param allowances the MAX number of validators that can be created by the Operator, for given Pool
   * @dev When decreased the approved validator count below current active+proposed validators,
   * operator can NOT create new validators.
   */
  function batchApproveOperators(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    uint256[] calldata operatorIds,
    uint256[] calldata allowances
  ) external returns (bool) {
    authenticate(DATASTORE, poolId, true, true, [false, true]);

    require(
      operatorIds.length == allowances.length,
      "SU: allowances should match"
    );

    for (uint256 i = 0; i < operatorIds.length; ) {
      authenticate(DATASTORE, operatorIds[i], false, false, [true, false]);

      DATASTORE.writeUintForId(
        poolId,
        DSU.getKey(operatorIds[i], "allowance"),
        allowances[i]
      );

      emit OperatorApproval(poolId, operatorIds[i], allowances[i]);

      unchecked {
        i += 1;
      }
    }
    return true;
  }

  /**
   * @notice                                     ** POOL HELPERS **
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice returns WithdrawalContract as a contract
   */
  function withdrawalContractById(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId
  ) public view returns (IWithdrawalContract) {
    return
      IWithdrawalContract(
        DATASTORE.readAddressForId(poolId, "withdrawalContract")
      );
  }

  /**
   * @notice returns liquidityPool as a contract
   */
  function liquidityPoolById(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 _poolId
  ) public view returns (ISwap) {
    return ISwap(DATASTORE.readAddressForId(_poolId, "liquidityPool"));
  }

  /**
   * @notice checks if the Whitelist allows staker to use given private pool
   * @dev Owner of the pool doesn't need whitelisting
   * @dev Otherwise requires a whitelisting address to be set
   * todo: add to portal
   */
  function isWhitelisted(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    address staker
  ) public view returns (bool) {
    if (DATASTORE.readAddressForId(poolId, "CONTROLLER") == msg.sender)
      return true;

    address whitelist = DATASTORE.readAddressForId(poolId, "whitelist");
    require(whitelist != address(0), "SU: this pool does not have whitelist");

    return IWhitelist(whitelist).isAllowed(staker);
  }

  /**
   * @notice returns true if the price is valid:
   * - last price syncinc happened less than 24h
   * - there has been no oracle reports since the last update
   *
   * @dev known bug / feature: if there have been no oracle updates,
   * * this function will return true.
   *
   * lastupdate + PRICE_EXPIRY >= block.timestamp ? true
   *    : lastupdate >= self.ORACLE_UPDATE_TIMESTAMP ? true
   *    : false
   */
  function isPriceValid(
    PooledStaking storage self,
    uint256 poolId
  ) public view returns (bool isValid) {
    uint256 lastupdate = self.gETH.priceUpdateTimestamp(poolId);
    unchecked {
      isValid =
        lastupdate + PRICE_EXPIRY >= block.timestamp ||
        lastupdate >= self.ORACLE_UPDATE_TIMESTAMP;
    }
  }

  /**
   * @notice checks if staking is allowed in given staking pool
   * @notice staking is not allowed if:
   * 1. Price is not valid
   * 2. WithdrawalContract is in Recovery Mode, can have many reasons
   */
  function isMintingAllowed(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId
  ) public view returns (bool) {
    return
      isPriceValid(self, poolId) &&
      !(withdrawalContractById(DATASTORE, poolId).recoveryMode());
  }

  /**
   * @notice                                     ** POOLING OPERATIONS **
   */

  /**
   * @dev  ->  internal
   */

  /**
   * @notice mints gETH for a given ETH amount, keeps the tokens in Portal.
   * @dev fails if the price if minting is not allowed
   */
  function _mintgETH(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    uint256 ethAmount
  ) internal returns (uint256 mintedgETH) {
    require(
      isMintingAllowed(self, DATASTORE, poolId),
      "SU: minting is not allowed"
    );

    mintedgETH = (
      ((ethAmount * self.gETH.denominator()) / self.gETH.pricePerShare(poolId))
    );

    self.gETH.mint(address(this), poolId, mintedgETH, "");
    DATASTORE.addUintForId(poolId, "surplus", ethAmount);
  }

  /**
   * @notice conducts a buyback using the given liquidity pool
   * @param poolId id of the gETH that will be bought
   * @param sellEth ETH amount to sell
   * @param minToBuy TX is expected to revert by Swap.sol if not meet
   * @param deadline TX is expected to revert by Swap.sol if not meet
   * @dev this function assumes that pool is deployed by deployLiquidityPool
   * as index 0 is ETH and index 1 is gETH!
   */
  function _buyback(
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    uint256 sellEth,
    uint256 minToBuy,
    uint256 deadline
  ) internal returns (uint256 outAmount) {
    // SWAP in LP
    outAmount = liquidityPoolById(DATASTORE, poolId).swap{value: sellEth}(
      0,
      1,
      sellEth,
      minToBuy,
      deadline
    );
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice Allowing users to deposit into a staking pool.
   * @notice If a pool is not public only the maintainer can deposit.
   * @param poolId id of the staking pool, liquidity pool and gETH to be used.
   * @param mingETH liquidity pool parameter
   * @param deadline liquidity pool parameter
   * @dev an example for minting + buybacks
   * * Buys from DWP if price is low -debt-, mints new tokens if surplus is sent -more than debt-
   * // debt  msgValue
   * // 100   10  => buyback
   * // 100   100 => buyback
   * // 10    100 => buyback + mint
   * // 1     x   => mint
   * // 0.5   x   => mint
   * // 0     x   => mint
   */
  function deposit(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    uint256 mingETH,
    uint256 deadline,
    address receiver
  ) external returns (uint256 boughtgETH, uint256 mintedgETH) {
    authenticate(DATASTORE, poolId, false, false, [false, true]);
    require(deadline > block.timestamp, "SU: deadline not met");
    require(receiver != address(0), "SU: receiver is zero address");

    if (isPrivatePool(DATASTORE, poolId))
      require(
        isWhitelisted(DATASTORE, poolId, msg.sender),
        "SU: sender NOT whitelisted"
      );

    uint256 remEth = msg.value;

    if (DATASTORE.readAddressForId(poolId, "liquidityPool") != address(0)) {
      uint256 debt = liquidityPoolById(DATASTORE, poolId).getDebt();
      if (debt > IGNORABLE_DEBT) {
        if (debt < remEth) {
          boughtgETH = _buyback(DATASTORE, poolId, debt, 0, deadline);
          remEth -= debt;
        } else {
          boughtgETH = _buyback(DATASTORE, poolId, remEth, mingETH, deadline);
          remEth = 0;
        }
      }
    }

    if (remEth > 0) mintedgETH = _mintgETH(self, DATASTORE, poolId, remEth);
    require(boughtgETH + mintedgETH >= mingETH, "SU: less than minimum");

    // send back to user
    self.gETH.safeTransferFrom(
      address(this),
      receiver,
      poolId,
      boughtgETH + mintedgETH,
      ""
    );

    emit Deposit(poolId, boughtgETH, mintedgETH);
  }

  /**
   * @notice                                     ** VALIDATOR OPERATIONS **
   *
   * Creation of a Validator takes 2 steps: propose and beacon stake.
   * Before entering beaconStake function, _canStake verifies the eligibility of
   * given pubKey that is proposed by an operator with proposeStake function.
   * Eligibility is defined by an optimistic alienation, check alienate() for info.
   */

  /**
   * @dev  ->  view
   */

  /**
   * @notice internal function to check if a validator can use the pool funds
   *
   *  @param pubkey BLS12-381 public key of the validator
   *  @return true if:
   *   - pubkey should be proposed
   *   - pubkey should not be alienated (https://bit.ly/3Tkc6UC)
   *   - validator's index should be lower than VERIFICATION_INDEX. Updated by Telescope.
   * Note: TODO while distributing the rewards, if a validator has 1 Eth, it is safe to assume that the balance belongs to Operator
   */
  function _canStake(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    bytes calldata pubkey,
    uint256 verificationIndex
  ) internal view returns (bool) {
    return
      (self._validators[pubkey].state == VALIDATOR_STATE.PROPOSED &&
        self._validators[pubkey].index <= verificationIndex) &&
      !(
        withdrawalContractById(DATASTORE, self._validators[pubkey].poolId)
          .recoveryMode()
      );
  }

  /**
   * @notice external function to check if a validator can use the pool funds
   */
  function canStake(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    bytes calldata pubkey
  ) external view returns (bool) {
    return _canStake(self, DATASTORE, pubkey, self.VERIFICATION_INDEX);
  }

  /**
   * @dev  ->  external
   */

  /**
   * @notice Helper Struct to pack constant data that does not change per validator.
   * * needed for that famous Solidity feature.
   */
  struct constantValidatorData {
    uint256 index;
    uint256 poolFee;
    uint256 operatorFee;
    uint256 earlyExitFee;
    uint256 expectedExit;
    bytes withdrawalCredential;
  }

  /**
   * @notice Validator Credentials Proposal function, first step of crating validators.
   * * Once a pubKey is proposed and not alienated after verificationIndex updated,
   * * it is optimistically allowed to take funds from staking pools.
   *
   * @param poolId the id of the staking pool
   * @param operatorId the id of the Operator whose maintainer calling this function
   * @param pubkeys  Array of BLS12-381 public keys of the validators that will be proposed
   * @param signatures1 Array of BLS12-381 signatures that will be used to send 1 ETH from the Operator's
   * maintainer balance
   * @param signatures31 Array of BLS12-381 signatures that will be used to send 31 ETH from pool on beaconStake
   *
   * @dev DCU.DEPOSIT_AMOUNT_PRESTAKE = 1 ether, DCU.DEPOSIT_AMOUNT = 32 ether which is the minimum amount to create a validator.
   * 31 Ether will be staked after verification of oracles. 32 in total.
   * 1 ether will be sent back to Node Operator when the finalized deposit is successful.
   * @dev ProposeStake requires enough allowance from Staking Pools to Operators.
   * @dev ProposeStake requires enough funds within Wallet.
   * @dev Max number of validators to propose is per call is MAX_DEPOSITS_PER_CALL (currently 64)
   */
  function proposeStake(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 poolId,
    uint256 operatorId,
    bytes[] calldata pubkeys,
    bytes[] calldata signatures1,
    bytes[] calldata signatures31
  ) external {
    // checks and effects
    authenticate(DATASTORE, operatorId, true, true, [true, false]);
    authenticate(DATASTORE, poolId, false, false, [false, true]);
    {
      uint256 pkLen = pubkeys.length;

      require(
        pkLen > 0 && pkLen <= DCU.MAX_DEPOSITS_PER_CALL,
        "SU: MAX 50 nodes per call"
      );
      require(pkLen == signatures1.length, "SU: invalid signatures1 length");
      require(pkLen == signatures31.length, "SU: invalid signatures31 length");

      unchecked {
        require(
          (DATASTORE.readUintForId(operatorId, "totalActiveValidators") +
            DATASTORE.readUintForId(operatorId, "totalProposedValidators") +
            pkLen) <= self.MONOPOLY_THRESHOLD,
          "SU: IceBear does NOT like monopolies"
        );

        require(
          (DATASTORE.readUintForId(
            poolId,
            DSU.getKey(operatorId, "proposedValidators")
          ) +
            DATASTORE.readUintForId(
              poolId,
              DSU.getKey(operatorId, "activeValidators")
            ) +
            pkLen) <= operatorAllowance(DATASTORE, poolId, operatorId),
          "SU: NOT enough allowance"
        );

        require(
          DATASTORE.readUintForId(poolId, "surplus") >=
            DCU.DEPOSIT_AMOUNT * pkLen,
          "SU: NOT enough surplus"
        );
      }

      _decreaseWalletBalance(
        DATASTORE,
        operatorId,
        (pkLen * DCU.DEPOSIT_AMOUNT_PRESTAKE)
      );

      DATASTORE.subUintForId(poolId, "surplus", (pkLen * DCU.DEPOSIT_AMOUNT));

      DATASTORE.addUintForId(poolId, "secured", (pkLen * DCU.DEPOSIT_AMOUNT));

      DATASTORE.addUintForId(
        poolId,
        DSU.getKey(operatorId, "proposedValidators"),
        pkLen
      );

      DATASTORE.addUintForId(operatorId, "totalProposedValidators", pkLen);
    }

    constantValidatorData memory valData = constantValidatorData({
      index: self.VALIDATORS_INDEX + 1,
      poolFee: getMaintenanceFee(DATASTORE, poolId),
      operatorFee: getMaintenanceFee(DATASTORE, operatorId),
      earlyExitFee: self.EARLY_EXIT_FEE,
      expectedExit: block.timestamp +
        DATASTORE.readUintForId(operatorId, "validatorPeriod"),
      withdrawalCredential: DATASTORE.readBytesForId(
        poolId,
        "withdrawalCredential"
      )
    });

    for (uint256 i; i < pubkeys.length; ) {
      require(
        self._validators[pubkeys[i]].state == VALIDATOR_STATE.NONE,
        "SU: Pubkey already used or alienated"
      );
      require(
        pubkeys[i].length == DCU.PUBKEY_LENGTH,
        "SU: PUBKEY_LENGTH ERROR"
      );
      require(
        signatures1[i].length == DCU.SIGNATURE_LENGTH,
        "SU: SIGNATURE_LENGTH ERROR"
      );

      require(
        signatures31[i].length == DCU.SIGNATURE_LENGTH,
        "SU: SIGNATURE_LENGTH ERROR"
      );

      self._validators[pubkeys[i]] = Validator(
        1,
        valData.index + i,
        poolId,
        operatorId,
        valData.poolFee,
        valData.operatorFee,
        valData.earlyExitFee,
        block.timestamp,
        valData.expectedExit,
        signatures31[i]
      );

      DCU.depositValidator(
        pubkeys[i],
        valData.withdrawalCredential,
        signatures1[i],
        DCU.DEPOSIT_AMOUNT_PRESTAKE
      );

      unchecked {
        i += 1;
      }
    }

    self.VALIDATORS_INDEX += pubkeys.length;

    emit ProposalStaked(poolId, operatorId, pubkeys);
  }

  /**
   *  @notice Sends 31 Eth from staking pool to validators that are previously created with ProposeStake.
   *  1 Eth per successful validator boostraping is returned back to Wallet.
   *
   *  @param operatorId the id of the Operator whose maintainer calling this function
   *  @param pubkeys  Array of BLS12-381 public keys of the validators that are already proposed with ProposeStake.
   *
   *  @dev To save gas cost, pubkeys should be arranged by poolIds.
   *  ex: [pk1, pk2, pk3, pk4, pk5, pk6, pk7]
   *  pk1, pk2, pk3 from pool1
   *  pk4, pk5 from pool2
   *  pk6 from pool3
   *  seperate them in similar groups as much as possible.
   *  @dev Max number of validators to boostrap is MAX_DEPOSITS_PER_CALL (currently 64)
   *  @dev A pubkey that is alienated will not get through. Do not frontrun during ProposeStake.
   */
  function beaconStake(
    PooledStaking storage self,
    DSU.IsolatedStorage storage DATASTORE,
    uint256 operatorId,
    bytes[] calldata pubkeys
  ) external {
    authenticate(DATASTORE, operatorId, true, true, [true, false]);

    require(
      pubkeys.length > 0 && pubkeys.length <= DCU.MAX_DEPOSITS_PER_CALL,
      "SU: MAX 50 nodes"
    );

    {
      uint256 verificationIndex = self.VERIFICATION_INDEX;
      for (uint256 j; j < pubkeys.length; ) {
        require(
          _canStake(self, DATASTORE, pubkeys[j], verificationIndex),
          "SU: NOT all pubkeys are stakeable"
        );
        unchecked {
          j += 1;
        }
      }
    }

    {
      bytes32 activeValKey = DSU.getKey(operatorId, "activeValidators");
      bytes32 proposedValKey = DSU.getKey(operatorId, "proposedValidators");

      uint256 poolId = self._validators[pubkeys[0]].poolId;

      bytes memory withdrawalCredential = DATASTORE.readBytesForId(
        poolId,
        "withdrawalCredential"
      );

      uint256 lastIdChange;
      for (uint256 i; i < pubkeys.length; ) {
        if (poolId != self._validators[pubkeys[i]].poolId) {
          uint256 sinceLastIdChange;

          unchecked {
            sinceLastIdChange = i - lastIdChange;
          }

          DATASTORE.subUintForId(
            poolId,
            "secured",
            (DCU.DEPOSIT_AMOUNT * (sinceLastIdChange))
          );
          DATASTORE.addUintForId(poolId, activeValKey, (sinceLastIdChange));
          DATASTORE.subUintForId(poolId, proposedValKey, (sinceLastIdChange));

          poolId = self._validators[pubkeys[i]].poolId;
          withdrawalCredential = DATASTORE.readBytesForId(
            poolId,
            "withdrawalCredential"
          );
          lastIdChange = i;
        }

        bytes memory signature = self._validators[pubkeys[i]].signature31;

        DCU.depositValidator(
          pubkeys[i],
          withdrawalCredential,
          signature,
          DCU.DEPOSIT_AMOUNT - DCU.DEPOSIT_AMOUNT_PRESTAKE
        );

        DATASTORE.appendBytesArrayForId(poolId, "validators", pubkeys[i]);
        self._validators[pubkeys[i]].state = VALIDATOR_STATE.ACTIVE;
        unchecked {
          i += 1;
        }
      }
      {
        uint256 sinceLastIdChange;
        unchecked {
          sinceLastIdChange = pubkeys.length - lastIdChange;
        }

        DATASTORE.subUintForId(
          poolId,
          "secured",
          DCU.DEPOSIT_AMOUNT * (sinceLastIdChange)
        );
        DATASTORE.addUintForId(poolId, activeValKey, (sinceLastIdChange));
        DATASTORE.subUintForId(poolId, proposedValKey, (sinceLastIdChange));

        DATASTORE.addUintForId(
          operatorId,
          "totalActiveValidators",
          pubkeys.length
        );
        DATASTORE.subUintForId(
          operatorId,
          "totalProposedValidators",
          pubkeys.length
        );
        _increaseWalletBalance(
          DATASTORE,
          operatorId,
          DCU.DEPOSIT_AMOUNT_PRESTAKE * pubkeys.length
        );
      }
      emit BeaconStaked(pubkeys);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {ID_TYPE} from "../utils/globals.sol";
import {DataStoreUtils} from "../utils/DataStoreUtilsLib.sol";
import {GeodeUtils} from "../utils/GeodeUtilsLib.sol";

import {IgETH} from "../../interfaces/IgETH.sol";
import {IPortal} from "../../interfaces/IPortal.sol";
import {IWithdrawalContract} from "../../interfaces/IWithdrawalContract.sol";
import "hardhat/console.sol";

/**
 * @author Icebear & Crash Bandicoot
 * @title WithdrawalContract: Saviour of Trustless Staking Derivatives
 * @notice This is a simple contract:
 * - used as the withdrawal credential of the validators.
 * - accrues fees and rewards from validators over time.
 * - handles the withdrawal queue for stakers.
 * - manages its own versioning without trusting Portal.
 * @dev This contract utilizes Dual Governance between Portal (GOVERNANCE) and 
 the Pool Owner (SENATE) to empower the Limited Upgradability.
 *
 * @dev Recovery Mode stops pool operations while allowing withdrawal queue to operate as usual
 *
 * @dev todo: Withdrawal Queue
 */

contract WithdrawalContract is
  IWithdrawalContract,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using DataStoreUtils for DataStoreUtils.IsolatedStorage;
  using GeodeUtils for GeodeUtils.DualGovernance;

  ///@notice Events
  event ControllerChanged(uint256 id, address newCONTROLLER);
  event Proposed(
    uint256 id,
    address CONTROLLER,
    uint256 TYPE,
    uint256 deadline
  );
  event ProposalApproved(uint256 id);
  event NewSenate(address senate, uint256 senateExpiry);

  event ContractVersionSet(uint256 version);

  ///@notice Variables
  DataStoreUtils.IsolatedStorage private DATASTORE;
  GeodeUtils.DualGovernance private GEM;
  address internal gETH;
  uint256 internal POOL_ID;
  uint256 internal CONTRACT_VERSION;

  function initialize(
    uint256 _VERSION,
    uint256 _ID,
    address _gETH,
    address _PORTAL,
    address _OWNER
  ) public virtual override initializer returns (bool) {
    __ReentrancyGuard_init();
    __Pausable_init();
    __UUPSUpgradeable_init();

    gETH = _gETH;
    POOL_ID = _ID;

    GEM.GOVERNANCE = _PORTAL;
    GEM.SENATE = _OWNER;
    GEM.SENATE_EXPIRY = type(uint256).max;

    CONTRACT_VERSION = _VERSION;
    emit ContractVersionSet(_VERSION);

    return true;
  }

  modifier onlyPortal() {
    require(
      msg.sender == GEM.getGovernance(),
      "WithdrawalContract: sender NOT PORTAL"
    );
    _;
  }

  modifier onlyOwner() {
    require(
      msg.sender == GEM.getSenate(),
      "WithdrawalContract: sender NOT OWNER"
    );
    _;
  }

  ///@dev required by the UUPS module
  function _authorizeUpgrade(
    address proposed_implementation
  ) internal virtual override onlyOwner {
    require(
      GEM.isUpgradeAllowed(proposed_implementation),
      "WithdrawalContract: NOT allowed to upgrade"
    );
  }

  /**
   * @notice pausing the contract activates the recoveryMode
   */
  function pause() external virtual override onlyOwner {
    _pause();
  }

  /**
   * @notice unpausing the contract deactivates the recoveryMode
   */
  function unpause() external virtual override onlyOwner {
    _unpause();
  }

  /**
   * @notice get gETH as a contract
   */
  function getgETH() public view override returns (IgETH) {
    return IgETH(gETH);
  }

  /**
   * @notice get Portal as a contract
   */
  function getPortal() public view override returns (IPortal) {
    return IPortal(GEM.getGovernance());
  }

  /**
   * @notice get the gETH ID of the corresponding staking pool
   */
  function getPoolId() public view override returns (uint256) {
    return POOL_ID;
  }

  /**
   * @notice get the current version of the contract
   */
  function getContractVersion() public view virtual override returns (uint256) {
    return CONTRACT_VERSION;
  }

  /**
   * @notice get the latest version of the withdrawal contract module from Portal
   */
  function getProposedVersion() public view virtual override returns (uint256) {
    return getPortal().getDefaultModule(ID_TYPE.MODULE_WITHDRAWAL_CONTRACT);
  }

  /**
   * @notice Recovery Mode allows Withdrawal Contract to isolate itself
   * from Portal and continue handling the withdrawals.
   * @return isRecovering true if recoveryMode is active
   */
  function recoveryMode()
    public
    view
    virtual
    override
    returns (bool isRecovering)
  {
    isRecovering =
      getContractVersion() != getProposedVersion() ||
      paused() ||
      getPortal().readAddressForId(getPoolId(), "CONTROLLER") !=
      GEM.getSenate() ||
      block.timestamp >= GEM.getSenateExpiry();
  }

  /**
   * @notice Creates a new Proposal within Withdrawal Contract, used by Portal
   * @dev only Governance check is inside, note Governance is Portal.
   */
  function newProposal(
    address _CONTROLLER,
    uint256 _TYPE,
    bytes calldata _NAME,
    uint256 duration
  ) external virtual override {
    GEM.newProposal(DATASTORE, _CONTROLLER, _TYPE, _NAME, duration);
  }

  function approveProposal(
    uint256 id
  )
    public
    virtual
    override
    whenNotPaused
    returns (uint256 _type, address _controller)
  {
    (_type, _controller) = GEM.approveProposal(DATASTORE, id);
  }

  /**
   * @notice Fetching an upgradeProposal from Portal creates an upgrade proposal
   * @notice approving the version changes the approvedVersion on GeodeUtils
   * @dev remaining code is basically taken from upgradeTo of UUPS since
   * it is still not public, but external
   */
  function fetchUpgradeProposal() external virtual override onlyOwner {
    uint256 proposedVersion = getPortal()
      .fetchWithdrawalContractUpgradeProposal(POOL_ID);

    require(
      proposedVersion != getContractVersion() && proposedVersion != 0,
      "WithdrawalContract: PROPOSED_VERSION ERROR"
    );

    approveProposal(proposedVersion);
    _authorizeUpgrade(GEM.approvedVersion);
    _upgradeToAndCallUUPS(GEM.approvedVersion, new bytes(0), false);
  }

  /**
   * @notice changes the Senate's address without extending the expiry
   * @dev OnlySenate is checked inside the GeodeUtils
   */
  function changeController(address _newSenate) external virtual override {
    GEM.changeSenate(_newSenate);
  }

  fallback() external payable {}

  receive() external payable {}

  /**
   * @notice keep the contract size at 50
   */
  uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}