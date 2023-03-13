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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @author Monumental Team
/// @title MNT Auction
/// @notice  Per user auction contract handling auction life-cycle
/// @dev Initially inspired from the Avo Labs GmbH auction
contract MNTAuction is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(address => mapping(uint256 => Auction)) private nftContractAuctions;
    mapping(address => uint256) private failedTransferCredits;

    struct Auction {
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint256 auctionStart;
        uint256 auctionEnd;
        uint128 reservedPrice;
        uint128 fixedPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer; // Only for fixed price. Define a whitelisted address
        address nftRecipient; //The bidder can specify a recipient for the NFT if their bid is successful.
        address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
        address[] feeRecipients;
        uint32[] feePercentages;
        bool done;
        bool auctionEndSettled;
    }

    struct InfoType {
        uint64 blockNumber;
        uint256 auctionStart;
        uint256 auctionEnd;
        uint128 reservedPrice;
        uint128 fixedPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer;
        bool isAuctionStarted;
        bool isAuctionEnded;
        bool hasBid;
        bool isAuctionDone;
        bool isFixedPrice;
        bool isWhiteListed;
    }

    struct InfoBoolType {
        bool isAuctionStarted;
        bool isAuctionEnded;
        bool hasBid;
        bool isAuctionDone;
        bool isFixedPrice;
        bool isWhiteListed;
    }

    uint32 private constant gasLimit = 1000000;

    uint64 private lastBlockNumber;

    /// ---------------------------
    /// Events
    /// ---------------------------

    event MNTTimedAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 reservedPrice,
        uint128 fixedPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event MNTFixedPriceCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 fixedPrice,
        address whitelistedBuyer,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event MNTBidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount,
        address erc20Token,
        uint256 tokenAmount
    );

    event MNTAuctionEndUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 auctionEndPeriod
    );

    event MNTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder,
        address nftRecipient
    );

    event MNTClaimDone(address nftContractAddress, uint256 tokenId, address _nftSeller, address _nftHighestBidder, uint128 _nftHighestBid);

    event MNTAuctionWithdrawn
    (
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event MNTBidWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );

    event MNTWhitelistUpdated(
        address nftContractAddress,
        uint256 tokenId,
        address newWhitelistedBuyer
    );

    event MNTReservedPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );

    event MNTFixedPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint128 newFixedPrice
    );
    event MNTHighestBidTaken(address nftContractAddress, uint256 tokenId, address _nftSeller, address _nftHighestBidder, uint128 _nftHighestBid);

    event MNTRoyaltiesInfo(address _receiver, uint256 _royalties);

    event MNTAuctionPaymentDetail(address _nftContractAddress, uint256 _tokenId, address _recipient, uint256 _amount, bool success);

    event MNTAuctionPaymentGlobal(address _nftContractAddress, uint256 _tokenId, address _seller, address _nftHighestBidder, uint256 _highestBid, uint256 fees, uint256 _royalties);

    event MNTWithDrawSuccess(address _recipient, uint256 _amount);

    /// ---------------------------
    /// MODIFIERS
    /// ---------------------------

    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != msg.sender, "Auction already started by owner");

        if (nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != address(0)) {
            require(msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId), "Sender doesn't own NFT");

            _resetAuction(_nftContractAddress, _tokenId);
        }
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(_isAuctionOngoing(_nftContractAddress, _tokenId), "Auction has ended");
        _;
    }

    modifier auctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(!_isAuctionOngoing(_nftContractAddress, _tokenId), "Auction is not yet over");
        _;
    }

    modifier auctionDone(address _nftContractAddress, uint256 _tokenId) {
        require(_isAuctionDone(_nftContractAddress, _tokenId), "Auction is not done");
        _;
    }

    modifier auctionActive(address _nftContractAddress, uint256 _tokenId) {
        require(!_isAuctionDone(_nftContractAddress, _tokenId), "Auction is inactive");
        _;
    }

    modifier checkPrice(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }
    /*
     * The minimum price must be 80% of the fixedPrice(if set).
     */
    modifier reservedPriceDoesNotExceedLimit(
        uint128 _fixedPrice,
        uint128 _reservedPrice
    ) {
        require(_fixedPrice == 0 || _getPortionOfBid(_fixedPrice, 8000) >= _reservedPrice, "MinPrice > 80% of fixedPrice");
        _;
    }

    modifier checkSellerAndOwner(address _nftContractAddress, uint256 _tokenId) {
        require(msg.sender != nftContractAuctions[_nftContractAddress][_tokenId].nftSeller, "Owner cannot bid on own NFT");
        require(_checkOwner(_nftContractAddress, _tokenId), "Seller is not the owner");
        _;
    }

    modifier onlySeller(address _nftContractAddress, uint256 _tokenId) {
        require(msg.sender == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller, "Only nft seller");
        _;
    }
    /*
     * The bid amount was either equal the fixedPrice or it must be higher than the previous
     * bid by the specified bid increase percentage.
     */
    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) {
        require(_doesBidMeetBidRequirements(_nftContractAddress, _tokenId, _tokenAmount), "Not enough funds to bid on NFT");
        _;
    }
    // check if the highest bidder can purchase this NFT.
    modifier onlyApplicableBuyer(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(!_isWhitelistedAuction(_nftContractAddress, _tokenId) || nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer == msg.sender, "Only the whitelisted buyer");
        _;
    }

    modifier reservedPriceNotMet(address _nftContractAddress, uint256 _tokenId) {
        require(!_isReservedPriceMet(_nftContractAddress, _tokenId), "A valid bid was made");
        _;
    }

    /*
     * Payment is accepted if the payment is made in the ERC20 token or ETH specified by the seller.
     * Early bids on NFTs not yet up for auction must be made in ETH.
     */
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    ) {
        require(_isPaymentAccepted(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount), "Bid to be in specified ERC20/Eth");
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier increasePercentageAboveMinimum(uint32 _bidIncreasePercentage) {
        require(_bidIncreasePercentage >= 100, "Bid increase percentage too low");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(_recipientsLength == _percentagesLength, "Recipients != percentages");
        _;
    }

    modifier isNotFixedPrice(address _nftContractAddress, uint256 _tokenId) {
        require(!_isFixedPrice(_nftContractAddress, _tokenId), "Unauthorized for fixed price");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// Initialize
    function initialize(address owner) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(owner);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}


    /// Checks if contract implements the ERC-2981 interface
    /// @param _contract contract address
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal returns (bool) {
        (bool success) = IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    /// ---------------------------
    /// Internal check functions
    /// ---------------------------

    /// Check if the auction is ongoing
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint256 auctionStartTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionStart;
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;

        bool isSettled = nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled;

        return (auctionStartTimestamp <= block.timestamp && ((isSettled && block.timestamp < auctionEndTimestamp) || !isSettled));
    }

    /// Check if the auction is done
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isAuctionDone(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].done;
    }

    /// Check if a bid has been made
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isBidMade(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
    }

    /// Check if a defined reserved price is met or not
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isReservedPriceMet(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint128 reservedPrice = nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice;
        return
        reservedPrice > 0 && (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= reservedPrice);
    }

    /// Check if a defined fixed price is met or not
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isFixedPriceMet(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint128 fixedPrice = nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice;
        return
        fixedPrice > 0 && nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= fixedPrice;
    }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * In the case of a sale: the bid needs to meet the fixedPrice.
     * In the case of an auction: the bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        uint128 fixedPrice = nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice;
        //if fixedPrice is met, ignore increase percentage
        if (fixedPrice > 0 && (msg.value >= fixedPrice || _tokenAmount >= fixedPrice)) {
            return true;
        }
        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid * (10000 + _getBidIncreasePercentage(_nftContractAddress, _tokenId))) / 10000;

        return (msg.value >= bidIncreaseAmount || _tokenAmount >= bidIncreaseAmount);
    }

    /// Check if the seller is still the owner
    /// If a transfer occurred during an ongoing auction without any bid done,
    /// this function ensure that no one can bid on it.
    /// The owner of the NFT will become the auction SC on a timed auction only
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _checkOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        bool ownerIsSeller = IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller;
        bool ownerIsAuction = IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this);
        return (ownerIsSeller || ownerIsAuction);
    }


    /// Check if current auction is fixed price
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isFixedPrice(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice > 0 && nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice == 0);
    }

    /// Check if the auction has an whitelisted address defined
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isWhitelistedAuction(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer != address(0));
    }

    /// Check if the highest bidder is allowed to proceed
    /// If a whitelisted address is defined, ensure the highest bidder is the one.
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isHighestBidderAllowedToPurchaseNFT(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return
        (!_isWhitelistedAuction(_nftContractAddress, _tokenId)) || _isHighestBidderWhitelisted(_nftContractAddress, _tokenId);
    }

    /// Check if the highest bidder is whitelisted
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isHighestBidderWhitelisted(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder == nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer);
    }


    /// Payment is accepted in the following scenarios:
    /// (1) Auction already created - can accept ETH or Specified Token
    ///     --------> Cannot bid with ETH & an ERC20 Token together in any circumstance<------
    /// (2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
    /// (3) Cannot make a zero bid (no ETH or Token amount)
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;

        if (_isERC20Auction(auctionERC20Token)) {
            return msg.value == 0 && auctionERC20Token == _bidERC20Token && _tokenAmount > 0;
        } else {
            return msg.value != 0 && _bidERC20Token == address(0) && _tokenAmount == 0;
        }
    }

    function _isERC20Auction(address _auctionERC20Token)
    internal
    pure
    returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    /// Returns the percentage of the total bid (used to calculate fee payments)
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
    internal
    pure
    returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        return nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage;
    }

    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _getAuctionBidPeriod(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (uint32)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod;
    }

    /// Return the recipient address.
    /// If not set, return the highest bidder address
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (address)
    {
        address nftRecipient = nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient;

        if (nftRecipient == address(0)) {
            return nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }

    /// Transfer the NFT contract to the auction contact.
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(_nftSeller, address(this), _tokenId);
            require(IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this), "nft transfer failed");
        } else {
            require(IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this), "Seller doesn't own NFT");
        }
    }

    /// Init timed auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _reservedPrice _reservedPrice
    /// @param _fixedPrice _fixedPrice
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function _initTimedAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _reservedPrice,
        uint128 _fixedPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    internal
    reservedPriceDoesNotExceedLimit(_fixedPrice, _reservedPrice)
    correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
    isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = _erc20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId].feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = _fixedPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice = _reservedPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;

    }

    /// Create timed auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _reservedPrice _reservedPrice
    /// @param _fixedPrice _fixedPrice
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function _createTimedAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _reservedPrice,
        uint128 _fixedPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal {
        _initTimedAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _reservedPrice,
            _fixedPrice,
            _feeRecipients,
            _feePercentages
        );
        emit MNTTimedAuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _reservedPrice,
            _fixedPrice,
            _getAuctionBidPeriod(_nftContractAddress, _tokenId),
            _getBidIncreasePercentage(_nftContractAddress, _tokenId),
            _feeRecipients,
            _feePercentages
        );
        _updateAuction(_nftContractAddress, _tokenId);
    }

    /// Create a timed auction
    /// @param _start _start
    /// @param _end _end
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _reservedPrice _reservedPrice
    /// @param _fixedPrice _fixedPrice
    /// @param _auctionBidPeriod _auctionBidPeriod
    /// @param _bidIncreasePercentage _bidIncreasePercentage
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function mntCreateTimedAuction(
        uint256 _start,
        uint256 _end,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _reservedPrice,
        uint128 _fixedPrice,
        uint32 _auctionBidPeriod,
        uint32 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external
    isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
    checkPrice(_reservedPrice)
    increasePercentageAboveMinimum(_bidIncreasePercentage)
    {

        nftContractAuctions[_nftContractAddress][_tokenId].auctionStart = _start;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _end;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = _auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = _bidIncreasePercentage;
        nftContractAuctions[_nftContractAddress][_tokenId].done = false;

        nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled = false;

        _createTimedAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _reservedPrice,
            _fixedPrice,
            _feeRecipients,
            _feePercentages
        );

        _updateLastBlockNumber();
    }

    /// Init a fixed price auction
    /// @param _start _start
    /// @param _end _end
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _fixedPrice _fixedPrice
    /// @param _whitelistedBuyer _whitelistedBuyer
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function _initFixedPriceAuction(
        uint256 _start,
        uint256 _end,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _fixedPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    internal
    correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
    isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = _erc20Token;
        }

        nftContractAuctions[_nftContractAddress][_tokenId].auctionStart = _start;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _end;
        nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId].feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = _fixedPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = _whitelistedBuyer;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        nftContractAuctions[_nftContractAddress][_tokenId].done = false;

        nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled = false;

    }

    /// Create a fixed price auction
    /// @param _start _start
    /// @param _end _end
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _fixedPrice _fixedPrice
    /// @param _whitelistedBuyer _whitelistedBuyer
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function mntCreateFixedPriceAuction(
        uint256 _start,
        uint256 _end,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _fixedPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external
    isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
    checkPrice(_fixedPrice)
    {
        _initFixedPriceAuction(
            _start,
            _end,
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _fixedPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );

        emit MNTFixedPriceCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _fixedPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );
        //check if fixedPrice is meet and conclude sale, otherwise reverse the early bid
        if (_isBidMade(_nftContractAddress, _tokenId)) {
            //we only revert the underbid if the seller specifies a different
            //whitelisted buyer to the highest bidder
            if (_isHighestBidderAllowedToPurchaseNFT(
                    _nftContractAddress,
                    _tokenId
                )
            ) {
                if (_isFixedPriceMet(_nftContractAddress, _tokenId)) {
                    _transferNftToAuctionContract(
                        _nftContractAddress,
                        _tokenId
                    );
                    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                }
            } else {
                _reverseAndResetPreviousBid(_nftContractAddress, _tokenId);
            }
        }

        _updateLastBlockNumber();
    }

    /********************************************************************
     * Make bids with ETH or an ERC20 Token specified by the NFT seller.*
     * Additionally, a buyer can pay the asking price to conclude a sale*
     * of an NFT.                                                       *
     ********************************************************************/

    /// Place a bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _tokenAmount _tokenAmount
    function _placeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
    internal
    checkSellerAndOwner(_nftContractAddress, _tokenId)
    paymentAccepted(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount)
    bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId, _tokenAmount)
    {

        _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);
        emit MNTBidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            msg.value,
            _erc20Token,
            _tokenAmount
        );
        _updateAuction(_nftContractAddress, _tokenId);
    }

    /// Place a bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _tokenAmount _tokenAmount
    function mntPlaceBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
    external
    payable
    auctionOngoing(_nftContractAddress, _tokenId)
    auctionActive(_nftContractAddress, _tokenId)
    onlyApplicableBuyer(_nftContractAddress, _tokenId)
    {
        _placeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
        _updateLastBlockNumber();
    }

    /// Update an auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function _updateAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        // If fixed price is reached, process to NFT transfer and seller payment
        if (_isFixedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
            return;
        }
        // if reserved price is reached , process to NFT transfer and start auction
        if (_isReservedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    /// Update the last blockNumber.
    function _updateLastBlockNumber()
    internal {
        lastBlockNumber = uint64(block.timestamp);
    }

    /// Set the auction end date (only on the first bid)
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _settleAuctionEnd(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        if (!nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled) {
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _getAuctionBidPeriod(_nftContractAddress, _tokenId) + uint64(block.timestamp);
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled = true;
        }

    }

    /// Update auction end
    /// During the last 10 minuts, if a bid occured, auction end time is extended with 10 min more
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _updateAuctionEnd(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        _settleAuctionEnd(_nftContractAddress, _tokenId);

        uint256 diff = 0;
        if (nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd > block.timestamp) {
            diff = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd - block.timestamp;
        }

        if (0 < diff && diff <= 600) {
            //nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _getAuctionBidPeriod(_nftContractAddress, _tokenId) + uint64(block.timestamp);
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = /*diff*/ 600 + nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;

            emit MNTAuctionEndUpdated(
                _nftContractAddress,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd
            );
        }

    }

    /// Reset auction
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _resetAuction(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = address(0);
    }

    /// Set an auction as done
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _setAuctionDone(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].done = true;
    }

    /// Reset all bids
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _resetBids(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
    }

    /// Update highest bid
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    /// @param _tokenAmount amount
    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transferFrom(msg.sender, address(this), _tokenAmount);
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = _tokenAmount;
        } else {
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = uint128(msg.value);
        }
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;
    }

    /// Reverse and reset previous bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;

        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
    }

    /// Reverse previous bid and update highest bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _tokenAmount _tokenAmount
    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;

        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

        if (prevNftHighestBidder != address(0)) {
            _payout(_nftContractAddress, _tokenId, prevNftHighestBidder, prevNftHighestBid);
        }
    }

    /// Transfer an NFT and pay the seller
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payFeesAndSeller(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _nftHighestBid);
        IERC721(_nftContractAddress).transferFrom(address(this), _nftRecipient, _tokenId);

        _resetAuction(_nftContractAddress, _tokenId);
        _setAuctionDone(_nftContractAddress, _tokenId);

        emit MNTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder,
            _nftRecipient
        );
    }

    /// Pay fees and seller
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _nftSeller _nftSeller
    /// @param _nftHighestBidder _nftHighestBidder
    /// @param _highestBid _highestBid
    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _nftHighestBidder,
        uint256 _highestBid
    ) internal {
        uint256 feesPaid;

        // Pay royalties base on the highest bid price
        uint256 royalties = 0;
        if (_checkRoyalties(_nftContractAddress)) {
            // Get amount of royalties to pays and recipient
            (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(_nftContractAddress).royaltyInfo(_tokenId, _highestBid);

            emit MNTRoyaltiesInfo(royaltiesReceiver, royaltiesAmount);

            // Transfer royalties to right holder if not zero
            if (royaltiesAmount > 0) {
                royalties = royaltiesAmount;
                bool success = _payout(_nftContractAddress, _tokenId, royaltiesReceiver, royaltiesAmount);
                emit MNTAuctionPaymentDetail(_nftContractAddress, _tokenId, royaltiesReceiver, royaltiesAmount, success);
            }
        }

        // Pay platform fees
        for (uint256 i = 0; i < nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(_highestBid, nftContractAuctions[_nftContractAddress][_tokenId].feePercentages[i]);
            feesPaid = feesPaid + fee;
            bool success = _payout(_nftContractAddress, _tokenId, nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients[i], fee);
            emit MNTAuctionPaymentDetail(_nftContractAddress, _tokenId, nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients[i], fee, success);
        }

        // Pay the seller
        bool success = _payout(_nftContractAddress, _tokenId, _nftSeller, (_highestBid - feesPaid - royalties));
        emit MNTAuctionPaymentDetail(_nftContractAddress, _tokenId, _nftSeller, (_highestBid - feesPaid - royalties), success);

        emit MNTAuctionPaymentGlobal(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _highestBid, feesPaid, royalties);

    }

    /// Send funds to recipient
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _recipient recipient address
    /// @param _amount amount
    /// @notice Send funds to recipient
    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal
    returns (bool)
    {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            bool success = IERC20(auctionERC20Token).transfer(_recipient, _amount);
            return success;
        } else {
            // attempt to send the funds to the recipient
            (bool success,) = payable(_recipient).call{value : _amount, gas : gasLimit}("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
            }
            return success;
        }
    }

    /// Claim an auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function mntClaim(address _nftContractAddress, uint256 _tokenId)
    external
    auctionOver(_nftContractAddress, _tokenId)
    {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        //address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        _transferNftAndPaySeller(_nftContractAddress, _tokenId);

        _updateLastBlockNumber();

        emit MNTClaimDone(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _nftHighestBid);
    }

    /// Withdraw auction
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function mntWithdrawAuction(address _nftContractAddress, uint256 _tokenId)
    external
    {
        //only the NFT owner can prematurely close and auction
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        _resetAuction(_nftContractAddress, _tokenId);
        _setAuctionDone(_nftContractAddress, _tokenId);

        _updateLastBlockNumber();

        emit MNTAuctionWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /// Withdraw bid function
    /// @dev Not used
    function mntWithdrawBid(address _nftContractAddress, uint256 _tokenId)
    external
    reservedPriceNotMet(_nftContractAddress, _tokenId)
    {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        require(msg.sender == nftHighestBidder, "Cannot withdraw funds");

        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);

        _updateLastBlockNumber();

        emit MNTBidWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /// Update white list buyer
    /// @dev Not used
    function mntUpdateWhitelistedBuyer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _newWhitelistedBuyer
    ) external onlySeller(_nftContractAddress, _tokenId) {
        require(_isFixedPrice(_nftContractAddress, _tokenId), "Not a fixed price");
        nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = _newWhitelistedBuyer;
        //if an underbid is by a non whitelisted buyer,reverse that bid
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        if (nftHighestBid > 0 && !(nftHighestBidder == _newWhitelistedBuyer)) {
            //we only revert the underbid if the seller specifies a different
            //whitelisted buyer to the highest bider

            _resetBids(_nftContractAddress, _tokenId);

            _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
        }

        _updateLastBlockNumber();

        emit MNTWhitelistUpdated(
            _nftContractAddress,
            _tokenId,
            _newWhitelistedBuyer
        );
    }

    /// Update minimum price
    /// @dev Not used
    function mntUpdateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newMinPrice
    )
    external
    onlySeller(_nftContractAddress, _tokenId)
    reservedPriceNotMet(_nftContractAddress, _tokenId)
    isNotFixedPrice(_nftContractAddress, _tokenId)
    checkPrice(_newMinPrice)
    reservedPriceDoesNotExceedLimit(nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice, _newMinPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice = _newMinPrice;

        emit MNTReservedPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);

        if (_isReservedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }

        _updateLastBlockNumber();
    }

    function mntUpdateFixedPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newFixedPrice
    )
    external
    onlySeller(_nftContractAddress, _tokenId)
    checkPrice(_newFixedPrice)
    reservedPriceDoesNotExceedLimit(_newFixedPrice, nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = _newFixedPrice;
        emit MNTFixedPriceUpdated(_nftContractAddress, _tokenId, _newFixedPrice);
        if (_isFixedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        }

        _updateLastBlockNumber();

    }

    /// When seller decide to end an auction, this function takes the highest bid and terminate auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function mntTakeHighestBid(address _nftContractAddress, uint256 _tokenId)
    external
    onlySeller(_nftContractAddress, _tokenId)
    {
        require(_isBidMade(_nftContractAddress, _tokenId), "cannot payout 0 bid");

        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        //address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);

        _updateLastBlockNumber();

        emit MNTHighestBidTaken(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _nftHighestBid);
    }

    /// If the transfer of a bid has failed, allow the recipient to reclaim their amount later.
    function mntWithdrawAllFailedCredits(/*uint32 gasLimit*/) external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        (bool successfulWithdraw,) = msg.sender.call{value : amount, gas : gasLimit}("");

        if (successfulWithdraw) {
            emit MNTWithDrawSuccess(msg.sender, amount);
        }
        require(successfulWithdraw, "withdraw failed");

        failedTransferCredits[msg.sender] = 0;

        _updateLastBlockNumber();
    }

    /// Get the last blockNumber in which the auction state has changed
    function getLastBlockNumber() public view returns (uint64 blockNumber){
        return lastBlockNumber;
    }

    /// Overview of the auction state
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function getInfo(address _nftContractAddress, uint256 _tokenId) public view returns (InfoType memory){

        uint256 auctionStartTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionStart;
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;

        bool isSettled = nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled;

        bool isAuctionStarted = auctionStartTimestamp <= block.timestamp;
        bool isAuctionEnded = isSettled && auctionEndTimestamp < block.timestamp && !_isFixedPrice(_nftContractAddress, _tokenId);
        bool hasBid = _isBidMade(_nftContractAddress, _tokenId);
        bool isAuctionDone = nftContractAuctions[_nftContractAddress][_tokenId].done;
        bool isFixedPrice = _isFixedPrice(_nftContractAddress, _tokenId);

        bool isWhiteListed = _isWhitelistedAuction(_nftContractAddress, _tokenId);

        InfoBoolType memory infoBoolType = InfoBoolType(
            isAuctionStarted,
            isAuctionEnded,
            hasBid,
            isAuctionDone,
            isFixedPrice,
            isWhiteListed
        );

        return _fillInfoStruct(_nftContractAddress, _tokenId, lastBlockNumber, infoBoolType);
    }

    /// Fill the info struct
    function _fillInfoStruct(
        address _nftContractAddress,
        uint256 _tokenId,
        uint64 _lastBlockNumber,
        InfoBoolType memory infoBoolType
    ) internal view returns (InfoType memory){
        InfoType memory info = InfoType(
            _lastBlockNumber,
            nftContractAuctions[_nftContractAddress][_tokenId].auctionStart,
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd,
            nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice,
            nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice,
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid,
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder,
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer,
            infoBoolType.isAuctionStarted,
            infoBoolType.isAuctionEnded,
            infoBoolType.hasBid,
            infoBoolType.isAuctionDone,
            infoBoolType.isFixedPrice,
            infoBoolType.isWhiteListed
        );
        return info;
    }

}