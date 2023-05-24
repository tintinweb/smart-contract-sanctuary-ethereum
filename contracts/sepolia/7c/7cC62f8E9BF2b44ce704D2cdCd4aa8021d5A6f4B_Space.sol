// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC4824 } from "src/interfaces/IERC4824.sol";
import { ISpace, ISpaceActions, ISpaceState, ISpaceOwnerActions } from "src/interfaces/ISpace.sol";
import {
    Choice,
    FinalizationStatus,
    IndexedStrategy,
    Proposal,
    ProposalStatus,
    Strategy,
    UpdateSettingsInput
} from "src/types.sol";
import { IVotingStrategy } from "src/interfaces/IVotingStrategy.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";
import { IProposalValidationStrategy } from "src/interfaces/IProposalValidationStrategy.sol";
import { SXUtils } from "./utils/SXUtils.sol";
import { BitPacker } from "./utils/BitPacker.sol";

/// @title Space Contract
/// @notice The core contract for Snapshot X.
///         A proxy of this contract should be deployed with the Proxy Factory.
contract Space is ISpace, Initializable, IERC4824, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using BitPacker for uint256;
    using SXUtils for IndexedStrategy[];

    /// @dev Placeholder value to indicate the user does not want to update a string.
    /// @dev Evaluates to: `0xf2cda9b13ed04e585461605c0d6e804933ca828111bd94d4e6a96c75e8b048ba`.
    bytes32 private constant NO_UPDATE_HASH = keccak256(abi.encodePacked("No update"));

    /// @dev Placeholder value to indicate the user does not want to update an address.
    /// @dev Evaluates to: `0xf2cda9b13ed04e585461605c0d6e804933ca8281`.
    address private constant NO_UPDATE_ADDRESS = address(bytes20(keccak256(abi.encodePacked("No update"))));

    /// @dev Placeholder value to indicate the user does not want to update a uint32.
    /// @dev Evaluates to: `0xf2cda9b1`.
    uint32 private constant NO_UPDATE_UINT32 = uint32(bytes4(keccak256(abi.encodePacked("No update"))));

    /// @inheritdoc IERC4824
    string public daoURI;
    /// @inheritdoc ISpaceState
    uint32 public override maxVotingDuration;
    /// @inheritdoc ISpaceState
    uint32 public override minVotingDuration;
    /// @inheritdoc ISpaceState
    uint256 public override nextProposalId;
    /// @inheritdoc ISpaceState
    uint32 public override votingDelay;
    /// @inheritdoc ISpaceState
    uint256 public override activeVotingStrategies;
    /// @inheritdoc ISpaceState
    mapping(uint8 strategyIndex => Strategy strategy) public override votingStrategies;
    /// @inheritdoc ISpaceState
    uint8 public override nextVotingStrategyIndex;
    /// @inheritdoc ISpaceState
    Strategy public override proposalValidationStrategy;
    /// @inheritdoc ISpaceState
    mapping(address auth => bool allowed) public override authenticators;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => Proposal proposal) public override proposals;
    // @inheritdoc ISpaceState
    mapping(uint256 proposalId => mapping(Choice choice => uint256 votePower)) public override votePower;
    /// @inheritdoc ISpaceState
    mapping(uint256 proposalId => mapping(address voter => bool hasVoted)) public override voteRegistry;

    /// @inheritdoc ISpaceActions
    function initialize(
        address _owner,
        uint32 _votingDelay,
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        Strategy memory _proposalValidationStrategy,
        string memory _proposalValidationStrategyMetadataURI,
        string memory _daoURI,
        string memory _metadataURI,
        Strategy[] memory _votingStrategies,
        string[] memory _votingStrategyMetadataURIs,
        address[] memory _authenticators
    ) public override initializer {
        if (_votingStrategies.length == 0) revert EmptyArray();
        if (_authenticators.length == 0) revert EmptyArray();
        if (_votingStrategies.length != _votingStrategyMetadataURIs.length) revert ArrayLengthMismatch();

        __Ownable_init();
        transferOwnership(_owner);
        _setDaoURI(_daoURI);
        _setMaxVotingDuration(_maxVotingDuration);
        _setMinVotingDuration(_minVotingDuration);
        _setProposalValidationStrategy(_proposalValidationStrategy);
        _setVotingDelay(_votingDelay);
        _addVotingStrategies(_votingStrategies);
        _addAuthenticators(_authenticators);

        nextProposalId = 1;

        emit SpaceCreated(
            address(this),
            _owner,
            _votingDelay,
            _minVotingDuration,
            _maxVotingDuration,
            _proposalValidationStrategy,
            _proposalValidationStrategyMetadataURI,
            _daoURI,
            _metadataURI,
            _votingStrategies,
            _votingStrategyMetadataURIs,
            _authenticators
        );
    }

    // ------------------------------------
    // |                                  |
    // |             SETTERS              |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceOwnerActions
    // solhint-disable-next-line code-complexity
    function updateSettings(UpdateSettingsInput calldata input) external override onlyOwner {
        if ((input.minVotingDuration != NO_UPDATE_UINT32) && (input.maxVotingDuration != NO_UPDATE_UINT32)) {
            // Check that min and max VotingDuration are valid
            // We don't use the internal `_setMinVotingDuration` and `_setMaxVotingDuration` functions because
            // it would revert when `_minVotingDuration > maxVotingDuration` (when the new `_min` is
            // bigger than the current `max`).
            if (input.minVotingDuration > input.maxVotingDuration) {
                revert InvalidDuration(input.minVotingDuration, input.maxVotingDuration);
            }

            minVotingDuration = input.minVotingDuration;
            emit MinVotingDurationUpdated(input.minVotingDuration);

            maxVotingDuration = input.maxVotingDuration;
            emit MaxVotingDurationUpdated(input.maxVotingDuration);
        } else if (input.minVotingDuration != NO_UPDATE_UINT32) {
            _setMinVotingDuration(input.minVotingDuration);
            emit MinVotingDurationUpdated(input.minVotingDuration);
        } else if (input.maxVotingDuration != NO_UPDATE_UINT32) {
            _setMaxVotingDuration(input.maxVotingDuration);
            emit MaxVotingDurationUpdated(input.maxVotingDuration);
        }

        if (input.votingDelay != NO_UPDATE_UINT32) {
            _setVotingDelay(input.votingDelay);
            emit VotingDelayUpdated(input.votingDelay);
        }

        if (keccak256(abi.encodePacked(input.metadataURI)) != NO_UPDATE_HASH) {
            emit MetadataURIUpdated(input.metadataURI);
        }

        if (keccak256(abi.encodePacked(input.daoURI)) != NO_UPDATE_HASH) {
            _setDaoURI(input.daoURI);
            emit DaoURIUpdated(input.daoURI);
        }

        if (input.proposalValidationStrategy.addr != NO_UPDATE_ADDRESS) {
            _setProposalValidationStrategy(input.proposalValidationStrategy);
            emit ProposalValidationStrategyUpdated(
                input.proposalValidationStrategy,
                input.proposalValidationStrategyMetadataURI
            );
        }

        if (input.authenticatorsToAdd.length > 0) {
            _addAuthenticators(input.authenticatorsToAdd);
            emit AuthenticatorsAdded(input.authenticatorsToAdd);
        }

        if (input.authenticatorsToRemove.length > 0) {
            _removeAuthenticators(input.authenticatorsToRemove);
            emit AuthenticatorsRemoved(input.authenticatorsToRemove);
        }

        if (input.votingStrategiesToAdd.length > 0) {
            if (input.votingStrategiesToAdd.length != input.votingStrategyMetadataURIsToAdd.length) {
                revert ArrayLengthMismatch();
            }
            _addVotingStrategies(input.votingStrategiesToAdd);
            emit VotingStrategiesAdded(input.votingStrategiesToAdd, input.votingStrategyMetadataURIsToAdd);
        }

        if (input.votingStrategiesToRemove.length > 0) {
            _removeVotingStrategies(input.votingStrategiesToRemove);
            emit VotingStrategiesRemoved(input.votingStrategiesToRemove);
        }
    }

    /// @dev Gates access to whitelisted authenticators only.
    modifier onlyAuthenticator() {
        if (authenticators[msg.sender] != true) revert AuthenticatorNotWhitelisted();
        _;
    }

    // ------------------------------------
    // |                                  |
    // |             GETTERS              |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceState
    function getProposalStatus(uint256 proposalId) external view override returns (ProposalStatus) {
        Proposal memory proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        return
            proposal.executionStrategy.getProposalStatus(
                proposal,
                votePower[proposalId][Choice.For],
                votePower[proposalId][Choice.Against],
                votePower[proposalId][Choice.Abstain]
            );
    }

    // ------------------------------------
    // |                                  |
    // |             CORE                 |
    // |                                  |
    // ------------------------------------

    /// @inheritdoc ISpaceActions
    function propose(
        address author,
        string calldata metadataURI,
        Strategy calldata executionStrategy,
        bytes calldata userProposalValidationParams
    ) external override onlyAuthenticator {
        // Casting to `uint32` is fine because this gives us until year ~2106.
        uint32 snapshotTimestamp = uint32(block.timestamp);

        if (
            !IProposalValidationStrategy(proposalValidationStrategy.addr).validate(
                author,
                proposalValidationStrategy.params,
                userProposalValidationParams
            )
        ) revert FailedToPassProposalValidation();

        uint32 startTimestamp = snapshotTimestamp + votingDelay;
        uint32 minEndTimestamp = startTimestamp + minVotingDuration;
        uint32 maxEndTimestamp = startTimestamp + maxVotingDuration;

        // The execution payload is the params of the supplied execution strategy struct.
        bytes32 executionPayloadHash = keccak256(executionStrategy.params);

        Proposal memory proposal = Proposal(
            snapshotTimestamp,
            startTimestamp,
            minEndTimestamp,
            maxEndTimestamp,
            executionPayloadHash,
            IExecutionStrategy(executionStrategy.addr),
            author,
            FinalizationStatus.Pending,
            activeVotingStrategies
        );

        proposals[nextProposalId] = proposal;
        emit ProposalCreated(nextProposalId, author, proposal, metadataURI, executionStrategy.params);

        nextProposalId++;
    }

    /// @inheritdoc ISpaceActions
    function vote(
        address voter,
        uint256 proposalId,
        Choice choice,
        IndexedStrategy[] calldata userVotingStrategies,
        string calldata metadataURI
    ) external override onlyAuthenticator {
        Proposal memory proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        if (block.timestamp >= proposal.maxEndTimestamp) revert VotingPeriodHasEnded();
        if (block.timestamp < proposal.startTimestamp) revert VotingPeriodHasNotStarted();
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        if (voteRegistry[proposalId][voter]) revert UserAlreadyVoted();

        uint256 votingPower = _getCumulativePower(
            voter,
            proposal.snapshotTimestamp,
            userVotingStrategies,
            proposal.activeVotingStrategies
        );
        if (votingPower == 0) revert UserHasNoVotingPower();
        votePower[proposalId][choice] += votingPower;
        voteRegistry[proposalId][voter] = true;

        if (bytes(metadataURI).length == 0) {
            emit VoteCast(proposalId, voter, choice, votingPower);
        } else {
            emit VoteCastWithMetadata(proposalId, voter, choice, votingPower, metadataURI);
        }
    }

    /// @inheritdoc ISpaceActions
    function execute(uint256 proposalId, bytes calldata executionPayload) external override nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        _assertProposalExists(proposal);

        // We add reentrancy protection here to prevent this function being re-entered by the execution strategy.
        // We cannot use the Checks-Effects-Interactions pattern because the proposal status is checked inside
        // the execution strategy (so essentially forced to do Checks-Interactions-Effects).
        proposal.executionStrategy.execute(
            proposal,
            votePower[proposalId][Choice.For],
            votePower[proposalId][Choice.Against],
            votePower[proposalId][Choice.Abstain],
            executionPayload
        );

        proposal.finalizationStatus = FinalizationStatus.Executed;

        emit ProposalExecuted(proposalId);
    }

    /// @inheritdoc ISpaceOwnerActions
    function cancel(uint256 proposalId) external override onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        _assertProposalExists(proposal);
        if (proposal.finalizationStatus != FinalizationStatus.Pending) revert ProposalFinalized();
        proposal.finalizationStatus = FinalizationStatus.Cancelled;
        emit ProposalCancelled(proposalId);
    }

    /// @inheritdoc ISpaceActions
    function updateProposal(
        address author,
        uint256 proposalId,
        Strategy calldata executionStrategy,
        string calldata metadataURI
    ) external override onlyAuthenticator {
        Proposal storage proposal = proposals[proposalId];
        if (author != proposal.author) revert InvalidCaller();
        if (block.timestamp >= proposal.startTimestamp) revert VotingDelayHasPassed();

        proposal.executionPayloadHash = keccak256(executionStrategy.params);
        proposal.executionStrategy = IExecutionStrategy(executionStrategy.addr);

        emit ProposalUpdated(proposalId, executionStrategy, metadataURI);
    }

    // ------------------------------------
    // |                                  |
    // |            INTERNAL              |
    // |                                  |
    // ------------------------------------

    /// @dev Only the Space owner can authorize an upgrade to this contract.
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Sets the maximum voting duration.
    function _setMaxVotingDuration(uint32 _maxVotingDuration) internal {
        if (_maxVotingDuration < minVotingDuration) revert InvalidDuration(minVotingDuration, _maxVotingDuration);
        maxVotingDuration = _maxVotingDuration;
    }

    /// @dev Sets the minimum voting duration.
    function _setMinVotingDuration(uint32 _minVotingDuration) internal {
        if (_minVotingDuration > maxVotingDuration) revert InvalidDuration(_minVotingDuration, maxVotingDuration);
        minVotingDuration = _minVotingDuration;
    }

    /// @dev Sets the proposal validation strategy.
    function _setProposalValidationStrategy(Strategy memory _proposalValidationStrategy) internal {
        proposalValidationStrategy = _proposalValidationStrategy;
    }

    /// @dev Sets the voting delay.
    function _setVotingDelay(uint32 _votingDelay) internal {
        votingDelay = _votingDelay;
    }

    /// @dev Sets the DAO URI.
    function _setDaoURI(string memory _daoURI) internal {
        daoURI = _daoURI;
    }

    /// @dev Adds an array of voting strategies.
    function _addVotingStrategies(Strategy[] memory _votingStrategies) internal {
        uint256 cachedActiveVotingStrategies = activeVotingStrategies;
        uint8 cachedNextVotingStrategyIndex = nextVotingStrategyIndex;
        if (cachedNextVotingStrategyIndex >= 256 - _votingStrategies.length) revert ExceedsStrategyLimit();
        for (uint256 i = 0; i < _votingStrategies.length; i++) {
            if (_votingStrategies[i].addr == address(0)) revert ZeroAddress();
            cachedActiveVotingStrategies = cachedActiveVotingStrategies.setBit(cachedNextVotingStrategyIndex, true);
            votingStrategies[cachedNextVotingStrategyIndex] = _votingStrategies[i];
            cachedNextVotingStrategyIndex++;
        }
        activeVotingStrategies = cachedActiveVotingStrategies;
        nextVotingStrategyIndex = cachedNextVotingStrategyIndex;
    }

    /// @dev Removes an array of voting strategies, specified by their indices.
    function _removeVotingStrategies(uint8[] memory _votingStrategyIndices) internal {
        for (uint8 i = 0; i < _votingStrategyIndices.length; i++) {
            activeVotingStrategies = activeVotingStrategies.setBit(_votingStrategyIndices[i], false);
        }
        // There must always be at least one active voting strategy.
        if (activeVotingStrategies == 0) revert NoActiveVotingStrategies();
    }

    /// @dev Adds an array of authenticators.
    function _addAuthenticators(address[] memory _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }
    }

    /// @dev Removes an array of authenticators.
    function _removeAuthenticators(address[] memory _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = false;
        }
        // TODO: should we check that there are still authenticators left? same for other setters..
    }

    /// @dev Reverts if `msg.sender` is not in the list of whitelisted authenticators.
    function _assertValidAuthenticator() internal view {
        if (authenticators[msg.sender] != true) revert AuthenticatorNotWhitelisted();
    }

    /// @dev Reverts if a specified proposal does not exist.
    function _assertProposalExists(Proposal memory proposal) internal pure {
        // startTimestamp cannot be set to 0 when a proposal is created,
        // so if proposal.startTimestamp is 0 it means this proposal does not exist
        // and hence `proposalId` is invalid.
        if (proposal.startTimestamp == 0) revert InvalidProposal();
    }

    /// @dev Returns the cumulative voting power of a user over a set of voting strategies.
    function _getCumulativePower(
        address userAddress,
        uint32 timestamp,
        IndexedStrategy[] memory userStrategies,
        uint256 allowedStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy.
        userStrategies.assertNoDuplicateIndices();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint8 strategyIndex = userStrategies[i].index;

            // Check that the strategy is allowed for this proposal.
            if (!allowedStrategies.isBitSet(strategyIndex)) {
                revert InvalidStrategyIndex(strategyIndex);
            }

            Strategy memory strategy = votingStrategies[strategyIndex];

            totalVotingPower += IVotingStrategy(strategy.addr).getVotingPower(
                timestamp,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title EIP-4824 Common Interfaces for DAOs
/// @notice See https://eips.ethereum.org/EIPS/eip-4824
interface IERC4824 {
    /// @notice A distinct Uniform Resource Identifier (URI) pointing to a JSON object following
    ///         the "EIP-4824 DAO JSON-LD Schema". This JSON file splits into four URIs: membersURI,
    ///         proposalsURI, activityLogURI, and governanceURI. The membersURI should point to a
    ///         JSON file that conforms to the "EIP-4824 Members JSON-LD Schema". The proposalsURI
    ///         should point to a JSON file that conforms to the "EIP-4824 Proposals JSON-LD Schema".
    ///         The activityLogURI should point to a JSON file that conforms to the "EIP-4824 Activity
    ///         Log JSON-LD Schema". The governanceURI should point to a flatfile, normatively a .md file.
    ///         Each of the JSON files named above can be statically hosted or dynamically-generated.
    /// @return _daoURI The DAO URI.
    function daoURI() external view returns (string memory _daoURI);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IndexedStrategy, Proposal, ProposalStatus } from "../types.sol";
import { IExecutionStrategyErrors } from "./execution-strategies/IExecutionStrategyErrors.sol";

/// @title Execution Strategy Interface
interface IExecutionStrategy is IExecutionStrategyErrors {
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external;

    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) external view returns (ProposalStatus);

    function getStrategyType() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IProposalValidationStrategy {
    function validate(address author, bytes calldata params, bytes calldata userParams) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ISpaceState } from "./space/ISpaceState.sol";
import { ISpaceActions } from "./space/ISpaceActions.sol";
import { ISpaceOwnerActions } from "./space/ISpaceOwnerActions.sol";
import { ISpaceEvents } from "./space/ISpaceEvents.sol";
import { ISpaceErrors } from "./space/ISpaceErrors.sol";

/// @title Space Interface
// solhint-disable-next-line no-empty-blocks
interface ISpace is ISpaceState, ISpaceActions, ISpaceOwnerActions, ISpaceEvents, ISpaceErrors {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Voting Strategy Interface
interface IVotingStrategy {
    /// @notice Gets the voting power of an address at a given timestamp.
    /// @param timestamp The snapshot timestamp to get the voting power at. If a particular voting strategy
    ///                  requires a block number instead of a timestamp, the strategy should resolve the
    ///                  timestamp to a block number.
    /// @param voter The address to get the voting power of.
    /// @param params The global parameters that can configure the voting strategy for a particular Space.
    /// @param userParams The user parameters that can be used in the voting strategy computation.
    /// @return votingPower The voting power of the address at the given timestamp. If there is no voting power,
    ///                     return 0.
    function getVotingPower(
        uint32 timestamp,
        address voter,
        bytes calldata params,
        bytes calldata userParams
    ) external returns (uint256 votingPower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ProposalStatus } from "../../types.sol";

/// @title Execution Strategy Errors
interface IExecutionStrategyErrors {
    /// @notice Thrown when the current status of a proposal does not allow the desired action.
    /// @param status The current status of the proposal.
    error InvalidProposalStatus(ProposalStatus status);

    /// @notice Thrown when the execution of a proposal fails.
    error ExecutionFailed();

    /// @notice Thrown when the execution payload supplied to the execution strategy is not equal
    /// to the payload supplied when the proposal was created.
    error InvalidPayload();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Choice, IndexedStrategy, Strategy } from "src/types.sol";

/// @title Space Actions
/// @notice User focused actions that can be performed on a space.
interface ISpaceActions {
    /// @notice  Initializes a space proxy after deployment.
    /// @param   owner  The address of the space owner.
    /// @param   votingDelay  The delay between the creation of a proposal and the start of the voting period.
    /// @param   minVotingDuration  The minimum duration of the voting period.
    /// @param   maxVotingDuration  The maximum duration of the voting period.
    /// @param   proposalValidationStrategy  The strategy to use to validate a proposal,
    ///          consisting of a strategy address and an array of configuration parameters.
    /// @param   proposalValidationStrategyMetadataURI  The metadata URI for `proposalValidationStrategy`.
    /// @param   daoURI  The ERC4824 DAO URI for the space.
    /// @param   metadataURI  The metadata URI for the space.
    /// @param   votingStrategies  The whitelisted voting strategies,
    ///          each consisting of a strategy address and an array of configuration parameters.
    /// @param   votingStrategyMetadataURIs  The metadata URIs for `votingStrategies`.
    /// @param   authenticators The whitelisted authenticator addresses.
    function initialize(
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        Strategy memory proposalValidationStrategy,
        string memory proposalValidationStrategyMetadataURI,
        string memory daoURI,
        string memory metadataURI,
        Strategy[] memory votingStrategies,
        string[] memory votingStrategyMetadataURIs,
        address[] memory authenticators
    ) external;

    /// @notice  Creates a proposal.
    /// @param   author  The address of the proposal creator.
    /// @param   metadataURI  The metadata URI for the proposal.
    /// @param   executionStrategy  The execution strategy for the proposal,
    ///          consisting of a strategy address and an execution payload.
    /// @param   userProposalValidationParams  The user provided parameters for proposal validation.
    function propose(
        address author,
        string calldata metadataURI,
        Strategy calldata executionStrategy,
        bytes calldata userProposalValidationParams
    ) external;

    /// @notice  Casts a vote.
    /// @param   voter  The voter's address.
    /// @param   proposalId  The proposal id.
    /// @param   choice  The vote choice  (`For`, `Against`, `Abstain`).
    /// @param   userVotingStrategies  The strategies to use to compute the voter's voting power,
    ///          each consisting of a strategy index and an array of user provided parameters.
    /// @param   metadataURI  An optional metadata to give information about the vote.
    function vote(
        address voter,
        uint256 proposalId,
        Choice choice,
        IndexedStrategy[] calldata userVotingStrategies,
        string calldata metadataURI
    ) external;

    /// @notice  Executes a proposal.
    /// @param   proposalId  The proposal id.
    /// @param   executionPayload  The execution payload.
    function execute(uint256 proposalId, bytes calldata executionPayload) external;

    /// @notice  Updates the proposal execution strategy and metadata.
    /// @param   proposalId The id of the proposal to edit.
    /// @param   executionStrategy The new execution strategy.
    /// @param   metadataURI The new metadata URI.
    function updateProposal(
        address author,
        uint256 proposalId,
        Strategy calldata executionStrategy,
        string calldata metadataURI
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Space Errors
interface ISpaceErrors {
    /// @notice Thrown when an invalid minimum or maximum voting duration is supplied.
    error InvalidDuration(uint32 minVotingDuration, uint32 maxVotingDuration);

    /// @notice Thrown when an invalid empty array is supplied.
    error EmptyArray();

    /// @notice Thrown when two arrays which must be of equal length are not.
    error ArrayLengthMismatch();

    /// @notice Thrown when the caller is unauthorized to perform a certain action.
    error InvalidCaller();

    /// @notice Thrown when an invalid zero address is supplied
    error ZeroAddress();

    /// @notice Thrown when an invalid strategy index is supplied.
    error InvalidStrategyIndex(uint256 index);

    /// @notice Thrown if the number of voting strategies exceeds the limit (256).
    ///         Once this limit is reached, no more strategies can be added.
    error ExceedsStrategyLimit();

    /// @notice Thrown when one attempts to remove all voting strategies.
    ///         There must always be at least one active voting strategy.
    error NoActiveVotingStrategies();

    /// @notice Thrown if a proposal is invalid.
    error InvalidProposal();

    /// @notice Thrown if the caller is not a whitelisted authenticator.
    error AuthenticatorNotWhitelisted();

    /// @notice Thrown if a user attempts to vote twice on the same proposal.
    error UserAlreadyVoted();

    /// @notice Thrown if a user attempts to vote with no voting power.
    error UserHasNoVotingPower();

    /// @notice Thrown if a user attempts to vote when the voting period has not started.
    error VotingPeriodHasNotStarted();

    /// @notice Thrown if a user attempts to vote when the voting period has ended.
    error VotingPeriodHasEnded();

    /// @notice Thrown if a user attempts to finalize (execute or cancel) a proposal that has already been finalized.
    error ProposalFinalized();

    /// @notice Thrown if an author attempts to update their proposal after the voting delay has passed.
    error VotingDelayHasPassed();

    /// @notice Thrown if a new proposal did not pass the proposal validation strategy for the space.
    error FailedToPassProposalValidation();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IndexedStrategy, Proposal, Strategy, Choice } from "src/types.sol";

/// @title Space Events
interface ISpaceEvents {
    /// @notice Emitted when a space is created.
    /// @param space The address of the space.
    /// @param owner The address of the space owner (controller).
    /// @param votingDelay The delay in seconds between the creation of a proposal and the start of voting.
    /// @param minVotingDuration The minimum duration of the voting period.
    /// @param maxVotingDuration The maximum duration of the voting period.
    /// @param proposalValidationStrategy  The strategy to use to validate a proposal,
    ///        consisting of a strategy address and an array of configuration parameters.
    /// @param metadataURI The metadata URI for the space.
    /// @param votingStrategies  The whitelisted voting strategies,
    ///        each consisting of a strategy address and an array of configuration parameters.
    /// @param votingStrategyMetadataURIs The metadata URIs for `votingStrategies`.
    /// @param authenticators The whitelisted authenticator addresses.
    event SpaceCreated(
        address space,
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        Strategy proposalValidationStrategy,
        string proposalValidationStrategyMetadataURI,
        string daoURI,
        string metadataURI,
        Strategy[] votingStrategies,
        string[] votingStrategyMetadataURIs,
        address[] authenticators
    );

    /// @notice Emitted when a proposal is created.
    /// @param proposalId The proposal id.
    /// @param author The address of the proposal creator.
    /// @param proposal The proposal data. Refer to the `Proposal` definition for more details.
    /// @param metadataUri The metadata URI for the proposal.
    /// @param payload The execution payload for the proposal.
    event ProposalCreated(uint256 proposalId, address author, Proposal proposal, string metadataUri, bytes payload);

    /// @notice Emitted when a vote is cast.
    /// @param proposalId The proposal id.
    /// @param voter The address of the voter.
    /// @param choice The vote choice (`For`, `Against`, `Abstain`).
    /// @param votingPower The voting power of the voter.
    event VoteCast(uint256 proposalId, address voter, Choice choice, uint256 votingPower);

    /// @notice Emitted when a vote is cast with metadata.
    /// @param proposalId The proposal id.
    /// @param voter The address of the voter.
    /// @param choice The vote choice (`For`, `Against`, `Abstain`).
    /// @param votingPower The voting power of the voter.
    /// @param metadataUri The metadata URI for the vote.
    event VoteCastWithMetadata(
        uint256 proposalId,
        address voter,
        Choice choice,
        uint256 votingPower,
        string metadataUri
    );

    /// @notice Emitted when a proposal is executed.
    /// @param proposalId The proposal id.
    event ProposalExecuted(uint256 proposalId);

    /// @notice Emitted when a proposal is cancelled.
    /// @param proposalId The proposal id.
    event ProposalCancelled(uint256 proposalId);

    /// @notice Emitted when a set of voting strategies are added.
    /// @param newVotingStrategies The new voting strategies,
    ///        each consisting of a strategy address and an array of configuration parameters.
    /// @param newVotingStrategyMetadataURIs The metadata URIs for `newVotingStrategies`.
    event VotingStrategiesAdded(Strategy[] newVotingStrategies, string[] newVotingStrategyMetadataURIs);

    /// @notice Emitted when a set of voting strategies are removed.
    /// @dev There must be at least one voting strategy left active.
    /// @param votingStrategyIndices The indices of the voting strategies to remove.
    event VotingStrategiesRemoved(uint8[] votingStrategyIndices);

    /// @notice Emitted when a set of authenticators are added.
    /// @param newAuthenticators The new authenticators addresses.
    event AuthenticatorsAdded(address[] newAuthenticators);

    /// @notice Emitted when a set of authenticators are removed.
    /// @param authenticators The authenticator addresses to remove.
    event AuthenticatorsRemoved(address[] authenticators);

    /// @notice Emitted when the maximum voting duration is updated.
    /// @param newMaxVotingDuration The new maximum voting duration.
    event MaxVotingDurationUpdated(uint32 newMaxVotingDuration);

    /// @notice Emitted when the minimum voting duration is updated.
    /// @param newMinVotingDuration The new minimum voting duration.
    event MinVotingDurationUpdated(uint32 newMinVotingDuration);

    /// @notice Emitted when the metadata URI for the space is updated.
    /// @param newMetadataURI The new metadata URI.
    event MetadataURIUpdated(string newMetadataURI);

    /// @notice Emitted when the DAO URI for the space is updated.
    /// @param newDaoURI The new DAO URI.
    event DaoURIUpdated(string newDaoURI);

    /// @notice Emitted when the proposal validation strategy is updated.
    /// @param newProposalValidationStrategy The new proposal validation strategy,
    ///        consisting of a strategy address and an array of configuration parameters.
    /// @param newProposalValidationStrategyMetadataURI The metadata URI for the proposal validation strategy.
    event ProposalValidationStrategyUpdated(
        Strategy newProposalValidationStrategy,
        string newProposalValidationStrategyMetadataURI
    );

    /// @notice Emitted when the voting delay is updated.
    /// @param newVotingDelay The new voting delay.
    event VotingDelayUpdated(uint32 newVotingDelay);

    /// @notice Emitted when a proposal is updated.
    /// @param proposalId The proposal id.
    /// @param newExecutionStrategy The new execution strategy,
    ///        consisting of a strategy address and an execution payload array.
    /// @param newMetadataURI The metadata URI for the proposal.
    event ProposalUpdated(uint256 proposalId, Strategy newExecutionStrategy, string newMetadataURI);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strategy, UpdateSettingsInput } from "../../types.sol";

/// @title Space Owner Actions
/// @notice The actions that can be performed by the owner of a Space,
///         These are in addition to the methods exposed by the `OwnableUpgradeable` module and the
///         `upgradeTo()` method of `UUPSUpgradeable`.
interface ISpaceOwnerActions {
    /// @notice  Cancels a proposal that has not already been finalized.
    /// @param   proposalId  The proposal to cancel.
    function cancel(uint256 proposalId) external;

    /// @notice Updates the settings.
    /// @param input The settings to modify
    /// @dev The structure should consist of:
    ///     minVotingDuration The new minimum voting duration. Set to `NO_UPDATE_UINT32` to ignore.
    ///     maxVotingDuration The new maximum voting duration. Set to `NO_UPDATE_UINT32` to ignore.
    ///     votingDelay The new voting delay. Set to `NO_UPDATE_UINT32` to ignore.
    ///     metadataURI The new metadataURI. Set to `NO_UPDATE_STRING` to ignore.
    ///     daoURI The new daoURI. Set to `NO_UPDATE_STRING` to ignore.
    ///     proposalValidationStrategy The new proposal validation strategy to use. Set
    ///                 to `NO_UPDATE_STRATEGY` to ignore.
    ///     proposalValidationStrategyMetadataURI The new metadata URI for the proposal validation strategy.
    ///     authenticatorsToAdd The authenticators to add. Set to an empty array to ignore.
    ///     authenticatorsToRemove The authenticators to remove. Set to an empty array to ignore.
    ///     votingStrategiesToAdd The voting strategies to add. Set to an empty array to ignore.
    ///     votingStrategyMetadataURIsToAdd The voting strategy metadata uris to add. Set to
    ///                 an empty array to ignore.
    ///     votignStrategiesToRemove The indices of voting strategies to remove. Set to empty array to ignore.
    function updateSettings(UpdateSettingsInput calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Choice, Proposal, ProposalStatus, FinalizationStatus, Strategy } from "src/types.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";

/// @title Space State
interface ISpaceState {
    /// @notice The maximum duration of the voting period.
    function maxVotingDuration() external view returns (uint32);

    /// @notice The minimum duration of the voting period.
    function minVotingDuration() external view returns (uint32);

    /// @notice A pointer to the next available voting strategy index.
    function nextProposalId() external view returns (uint256);

    /// @notice The delay between proposal creation and the start of the voting period.
    function votingDelay() external view returns (uint32);

    /// @notice Returns whether a given address is a whitelisted authenticator.
    function authenticators(address) external view returns (bool);

    /// @notice Returns the voting strategy at a given index.
    /// @param index The index of the voting strategy.
    /// @return addr The address of the voting strategy.
    /// @return params The parameters of the voting strategy.
    function votingStrategies(uint8 index) external view returns (address addr, bytes memory params);

    /// @notice The bit array of the current active voting strategies.
    /// @dev The index of each bit corresponds to whether the strategy at that index
    ///       in `votingStrategies` is active.
    function activeVotingStrategies() external view returns (uint256);

    /// @notice The index of the next available voting strategy.
    function nextVotingStrategyIndex() external view returns (uint8);

    /// @notice The proposal validation strategy.
    /// @return addr The address of the proposal validation strategy.
    /// @return params The parameters of the proposal validation strategy.
    function proposalValidationStrategy() external view returns (address addr, bytes memory params);

    /// @notice Returns the voting power of a choice on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param choice The choice of the voter.
    function votePower(uint256 proposalId, Choice choice) external view returns (uint256);

    /// @notice Returns whether a voter has voted on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param voter The address of the voter.
    function voteRegistry(uint256 proposalId, address voter) external view returns (bool);

    /// @notice Returns the proposal at a given ID.
    /// @dev Returns all zeros if the proposal does not exist.
    /// @param proposalId The ID of the proposal.
    /// @return snapshotTimestamp The timestamp of the proposal snapshot.
    ///         All Voting Power will be calculated at this timestamp.
    /// @return startTimestamp The timestamp of the start of the voting period.
    /// @return minEndTimestamp The timestamp of the minimum end of the voting period.
    /// @return maxEndTimestamp The timestamp of the maximum end of the voting period.
    /// @return executionPayloadHash The keccak256 hash of the execution payload.
    /// @return executionStrategy The address of the execution strategy used in the proposal.
    /// @return author The address of the proposal author.
    /// @return finalizationStatus The finalization status of the proposal. See `FinalizationStatus`.
    /// @return activeVotingStrategies The bit array of the active voting strategies for the proposal.
    function proposals(
        uint256 proposalId
    )
        external
        view
        returns (
            uint32 snapshotTimestamp,
            uint32 startTimestamp,
            uint32 minEndTimestamp,
            uint32 maxEndTimestamp,
            bytes32 executionPayloadHash,
            IExecutionStrategy executionStrategy,
            address author,
            FinalizationStatus finalizationStatus,
            uint256 activeVotingStrategies
        );

    /// @notice Returns the status of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The status of the proposal. Refer to the `ProposalStatus` enum for more information.
    function getProposalStatus(uint256 proposalId) external view returns (ProposalStatus);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";

/// @notice The data stored for each proposal when it is created.
struct Proposal {
    // The timestamp at which voting power for the proposal is calculated. Overflows at year ~2106.
    uint32 snapshotTimestamp;
    // We store the following 3 timestamps for each proposal despite the fact that they can be
    // inferred from the votingDelay, minVotingDuration, and maxVotingDuration state variables
    // because those variables may be updated during the lifetime of a proposal.
    uint32 startTimestamp;
    uint32 minEndTimestamp;
    uint32 maxEndTimestamp;
    // The hash of the execution payload. We do not store the payload itself to save gas.
    bytes32 executionPayloadHash;
    // The address of execution strategy used for the proposal.
    IExecutionStrategy executionStrategy;
    // The address of the proposal creator.
    address author;
    // An enum that stores whether a proposal is pending, executed, or cancelled.
    FinalizationStatus finalizationStatus;
    // Bit array where the index of each each bit corresponds to whether the voting strategy.
    // at that index is active at the time of proposal creation.
    uint256 activeVotingStrategies;
}

/// @notice The data stored for each strategy.
struct Strategy {
    // The address of the strategy contract.
    address addr;
    // The parameters of the strategy.
    bytes params;
}

/// @notice The data stored for each indexed strategy.
struct IndexedStrategy {
    uint8 index;
    bytes params;
}

/// @notice The set of possible finalization statuses for a proposal.
///         This is stored inside each Proposal struct.
enum FinalizationStatus {
    Pending,
    Executed,
    Cancelled
}

/// @notice The set of possible statuses for a proposal.
enum ProposalStatus {
    VotingDelay,
    VotingPeriod,
    VotingPeriodAccepted,
    Accepted,
    Executed,
    Rejected,
    Cancelled
}

/// @notice The set of possible choices for a vote.
enum Choice {
    Against,
    For,
    Abstain
}

/// @notice Transaction struct that can be used to represent transactions inside a proposal.
struct MetaTransaction {
    address to;
    uint256 value;
    bytes data;
    Enum.Operation operation;
    // We require a salt so that the struct can always be unique and we can use its hash as a unique identifier.
    uint256 salt;
}

/// @dev    Structure used for the function `updateSettings` because of solidity's stack constraints.
///         For more information, see `ISpaceOwnerActions.sol`.
struct UpdateSettingsInput {
    uint32 minVotingDuration;
    uint32 maxVotingDuration;
    uint32 votingDelay;
    string metadataURI;
    string daoURI;
    Strategy proposalValidationStrategy;
    string proposalValidationStrategyMetadataURI;
    address[] authenticatorsToAdd;
    address[] authenticatorsToRemove;
    Strategy[] votingStrategiesToAdd;
    string[] votingStrategyMetadataURIsToAdd;
    uint8[] votingStrategiesToRemove;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title Uint256 Bit Setting and Checking Library
library BitPacker {
    /// @dev Sets the bit at the given index to the given value.
    function setBit(uint256 value, uint8 index, bool bit) internal pure returns (uint256) {
        uint256 mask = 1 << index;
        if (bit) {
            return value | mask;
        } else {
            return value & ~mask;
        }
    }

    /// @dev Returns true if the bit at the given index is set.
    function isBitSet(uint256 value, uint8 index) internal pure returns (bool) {
        uint256 mask = 1 << index;
        return (value & mask) != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IndexedStrategy } from "src/types.sol";

/// @title Snapshot X Types Utilities Library
library SXUtils {
    error DuplicateFound(uint8 index);

    /// @dev Reverts if a duplicate index is found in the given array of indexed strategies.
    function assertNoDuplicateIndices(IndexedStrategy[] memory strats) internal pure {
        if (strats.length < 2) {
            return;
        }

        uint256 bitMap;
        for (uint256 i = 0; i < strats.length; ++i) {
            // Check that bit at index `strats[i].index` is not set.
            uint256 s = 1 << strats[i].index;
            if (bitMap & s != 0) revert DuplicateFound(strats[i].index);
            // Update aforementioned bit.
            bitMap |= s;
        }
    }
}