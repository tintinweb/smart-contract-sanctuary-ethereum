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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IERC20TransferProxy.sol";
import "../interfaces/INftTransferProxy.sol";
import "../interfaces/ITransferProxy.sol";
import "../interfaces/ITransferExecutor.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IERC165.sol";

abstract contract TransferExecutor is Initializable, OwnableUpgradeable, ITransferExecutor {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // bitpacked storage
    struct RoyaltyInfo {
        address owner;
        uint96 percent; // 0 - 10000, where 10000 is 100%, 100 = 1%
    }

    address public nftBuyContract; // uint160
    uint256 public protocolFee; // value 0 - 2000, where 2000 = 20% fees, 100 = 1%

    mapping(bytes4 => address) public proxies;
    mapping(address => bool) public whitelistERC20; // whitelist of supported ERC20s
    mapping(address => RoyaltyInfo) public royaltyInfo; // mapping of NFT to their royalties

    // bitpacked 256
    address public nftToken; // same as uint160
    uint48 public constant MAX_ROYALTY = 10000; // 10000 = 100%
    uint48 public constant MAX_PROTOCOL_FEE = 2000; // 2000 = 20%

    event ProxyChange(bytes4 indexed assetType, address proxy);
    event WhitelistChange(address indexed token, bool value);
    event ProtocolFeeChange(uint256 fee);
    event RoyaltyInfoChange(address indexed token, address indexed owner, uint256 percent, address indexed setter);

    function __TransferExecutor_init_unchained(
        INftTransferProxy _transferProxy,
        IERC20TransferProxy _erc20TransferProxy,
        address _cryptoKittyProxy,
        address _nftBuyContract,
        address _nftToken,
        uint256 _protocolFee
    ) internal {
        proxies[LibAsset.ERC20_ASSET_CLASS] = address(_erc20TransferProxy);
        proxies[LibAsset.ERC721_ASSET_CLASS] = address(_transferProxy);
        proxies[LibAsset.ERC1155_ASSET_CLASS] = address(_transferProxy);
        proxies[LibAsset.CRYPTO_KITTY] = _cryptoKittyProxy;
        nftBuyContract = _nftBuyContract;
        protocolFee = _protocolFee;
        nftToken = _nftToken;
    }

    // ADMIN over-ride
    function setRoyalty(
        address nftContract,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(amount <= MAX_ROYALTY);

        royaltyInfo[nftContract].owner = recipient;
        royaltyInfo[nftContract].percent = uint96(amount);

        emit RoyaltyInfoChange(nftContract, recipient, amount, msg.sender);
    }

    /**
     * @dev external function for owners / admins to self-set royalties for their contracts
     * @param nftContract is the ERC721/ERC1155 collection in questions
     * @param recipient is where royalties are sent to
     * @param amount is the percentage of the atomic sale proceeds
     */
    function setRoyaltyOwnerAdmin(
        address nftContract,
        address recipient,
        uint256 amount
    ) external {
        require(amount <= MAX_ROYALTY);
        // bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
        require(!IERC165(nftContract).supportsInterface(0x2a55205a), "!erc2981");
        require(msg.sender == IOwnable(nftContract).owner() ||
            msg.sender == IOwnable(nftContract).admin(), "!owner/!admin");

        royaltyInfo[nftContract].owner = recipient;
        royaltyInfo[nftContract].percent = uint96(amount);

        emit RoyaltyInfoChange(nftContract, recipient, amount, msg.sender);
    }

    function changeProtocolFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_PROTOCOL_FEE);
        protocolFee = _fee;
        emit ProtocolFeeChange(_fee);
    }

    function modifyWhitelist(address _token, bool _val) external onlyOwner {
        require(whitelistERC20[_token] != _val);
        whitelistERC20[_token] = _val;
        emit WhitelistChange(_token, _val);
    }

    function setTransferProxy(bytes4 assetType, address proxy) external onlyOwner {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    /**
     * @dev internal function for transferring ETH w/ fees
     * @notice fees are being sent in addition to base ETH price
     * @param to counterparty receiving ETH for transaction
     * @param value base value of ETH in wei
     * @param validRoyalty true if singular NFT asset paired with only fungible token(s) trade
     * @param optionalNftAssets only used if validRoyalty is true, should be 1 asset => NFT collection being traded
     */
    function transferEth(
        address to,
        uint256 value,
        bool validRoyalty,
        LibAsset.Asset[] memory optionalNftAssets
    ) internal {
        uint256 royalty;

        // handle royalty
        if (validRoyalty) {
            require(optionalNftAssets.length == 1, "NFT.com: Royalty not supported for multiple NFTs");
            require(optionalNftAssets[0].assetType.assetClass == LibAsset.ERC721_ASSET_CLASS, "te !721");
            (address nftRoyalty, , ) = abi.decode(optionalNftAssets[0].assetType.data, (address, uint256, bool));

            // handle royalty
            if (royaltyInfo[nftRoyalty].owner != address(0) && royaltyInfo[nftRoyalty].percent != uint256(0)) {
                // Royalty
                royalty = (value * royaltyInfo[nftRoyalty].percent) / 10000;

                (bool success3, ) = royaltyInfo[nftRoyalty].owner.call{ value: royalty }("");
                require(success3, "te !rty");
            }
        }

        // ETH Fee
        uint256 fee = ((value - royalty) * protocolFee) / 10000;
        (bool success1, ) = nftBuyContract.call{ value: fee }("");
        (bool success2, ) = to.call{ value: (value - royalty) - fee }("");

        require(success1 && success2, "te !eth");
    }

    /**
     * @dev multi-asset transfer function
     * @param auctionType type of auction
     * @param asset the asset being transferred
     * @param from address where asset is being sent from
     * @param to address receiving said asset
     * @param decreasingPriceValue value only used for decreasing price auction
     * @param validRoyalty true if singular NFT asset paired with only fungible token(s) trade
     * @param optionalNftAssets only used if validRoyalty is true, should be 1 asset => NFT collection being traded
     */
    function transfer(
        LibSignature.AuctionType auctionType,
        LibAsset.Asset memory asset,
        address from,
        address to,
        uint256 decreasingPriceValue,
        bool validRoyalty,
        LibAsset.Asset[] memory optionalNftAssets
    ) internal override {
        require(nftBuyContract != address(0));
        require(to != address(0) && from != address(0));
        uint256 value;

        if (auctionType == LibSignature.AuctionType.Decreasing && from == msg.sender) value = decreasingPriceValue;
        else (value, ) = abi.decode(asset.data, (uint256, uint256));

        require(value != 0);

        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            transferEth(to, value, validRoyalty, optionalNftAssets);
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(asset.assetType.data, (address));
            require(whitelistERC20[token], "t !list");
            uint256 royalty;

            // handle royalty
            if (validRoyalty) {
                require(optionalNftAssets.length == 1, "t len");
                require(optionalNftAssets[0].assetType.assetClass == LibAsset.ERC721_ASSET_CLASS, "t !721");
                (address nftContract, , ) = abi.decode(optionalNftAssets[0].assetType.data, (address, uint256, bool));

                if (royaltyInfo[nftContract].owner != address(0) && royaltyInfo[nftContract].percent != uint256(0)) {
                    royalty = (value * royaltyInfo[nftContract].percent) / 10000;

                    // Royalty
                    IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS]).erc20safeTransferFrom(
                        IERC20Upgradeable(token),
                        from,
                        royaltyInfo[nftContract].owner,
                        royalty
                    );
                }
            }

            uint256 feePercent = token == nftToken ? protocolFee / 2 : protocolFee;
            uint256 fee = ((value - royalty) * feePercent) / 10000;

            // ERC20 Fee
            IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS]).erc20safeTransferFrom(
                IERC20Upgradeable(token),
                from,
                nftBuyContract,
                fee
            );

            IERC20TransferProxy(proxies[LibAsset.ERC20_ASSET_CLASS]).erc20safeTransferFrom(
                IERC20Upgradeable(token),
                from,
                to,
                (value - royalty) - fee
            );
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId, ) = abi.decode(asset.assetType.data, (address, uint256, bool));

            require(value == 1, "t !1");
            INftTransferProxy(proxies[LibAsset.ERC721_ASSET_CLASS]).erc721safeTransferFrom(
                IERC721Upgradeable(token),
                from,
                to,
                tokenId
            );
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId, ) = abi.decode(asset.assetType.data, (address, uint256, bool));
            INftTransferProxy(proxies[LibAsset.ERC1155_ASSET_CLASS]).erc1155safeTransferFrom(
                IERC1155Upgradeable(token),
                from,
                to,
                tokenId,
                value
            );
        } else {
            // non standard assets
            ITransferProxy(proxies[asset.assetType.assetClass]).transfer(asset, from, to);
        }
        emit Transfer(asset, from, to);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash Hash of the data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity >=0.8.4;

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
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);

    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../lib/LibSignature.sol";
struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface IMarketplaceEvent {
    event NewMarketplace(address indexed marketPlace);
    event BuyNowInfo(bytes32 indexed makerStructHash, address takerAddress);
    event Match(
        bytes32 indexed makerStructHash,
        bytes32 indexed takerStructHash,
        LibSignature.AuctionType auctionType,
        Sig makerSig,
        Sig takerSig,
        bool privateSale
    );
    event Match2A(
        bytes32 indexed makerStructHash,
        address indexed makerAddress,
        address indexed takerAddress,
        uint256 start,
        uint256 end,
        uint256 nonce,
        uint256 salt
    );
    event Match2B(
        bytes32 indexed makerStructHash,
        bytes[] sellerMakerOrderAssetData,
        bytes[] sellerMakerOrderAssetTypeData,
        bytes4[] sellerMakerOrderAssetClass,
        bytes[] sellerTakerOrderAssetData,
        bytes[] sellerTakerOrderAssetTypeData,
        bytes4[] sellerTakerOrderAssetClass
    );
    event Match3A(
        bytes32 indexed takerStructHash,
        address indexed makerAddress,
        address indexed takerAddress,
        uint256 start,
        uint256 end,
        uint256 nonce,
        uint256 salt
    );
    event Match3B(
        bytes32 indexed takerStructHash,
        bytes[] buyerMakerOrderAssetData,
        bytes[] buyerMakerOrderAssetTypeData,
        bytes4[] buyerMakerOrderAssetClass,
        bytes[] buyerTakerOrderAssetData,
        bytes[] buyerTakerOrderAssetTypeData,
        bytes4[] buyerTakerOrderAssetClass
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INftTransferProxy {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);

    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external;

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function admin() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../lib/LibSignature.sol";

abstract contract ITransferExecutor {
    event Transfer(LibAsset.Asset asset, address indexed from, address indexed to);

    function transfer(
        LibSignature.AuctionType auctionType,
        LibAsset.Asset memory asset,
        address from,
        address to,
        uint256 decreasingPriceValue,
        bool validRoyalty,
        LibAsset.Asset[] memory optionalNftAssets
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../lib/LibAsset.sol";

interface ITransferProxy {
    event AddOperator(address indexed operator);
    event RemoveOperator(address indexed operator);

    function transfer(LibAsset.Asset calldata asset, address from, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../lib/LibSignature.sol";

interface IValidationLogic {
    function validateBuyNow(LibSignature.Order calldata sellOrder, address buyer) external view returns (bool);

    function validateMatch_(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        address sender,
        bool viewOnly
    ) external view returns (bool);

    function getDecreasingPrice(LibSignature.Order memory sellOrder) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 constant public CRYPTO_PUNK = bytes4(keccak256("CRYPTO_PUNK"));
    bytes4 constant public CRYPTO_KITTY = bytes4(keccak256("CRYPTO_KITTY"));
    bytes32 constant private ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );
    bytes32 constant private ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,bytes data)AssetType(bytes4 assetClass,bytes data)"
    );
    struct AssetType {
        bytes4 assetClass;      // asset class (erc20, 721, etc)
        bytes data;             // (address, uint256, bool) = (contract address, tokenId - only NFTs, allow all from collection - only NFTs)
                                // if allow all = true, ignore tokenId
    }
    struct Asset {
        AssetType assetType;
        bytes data;             // (uint256, uint256) = value, minimumBid
                                //      SELL ORDER:
                                //          MAKE: (the amount for sale, 0)
                                //          TAKE: (buy now price, min bid value), if decreasing price auction, then (start price, ending price)
                                //      BUY  ORDER:
                                //          MAKE: (amount offered must >= min bid value, 0)
                                //          TAKE: (must match sell order make, 0)
    }
    function hash(AssetType calldata assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ASSET_TYPE_TYPEHASH,
            assetType.assetClass,
            keccak256(assetType.data)
        ));
    }
    function hash(Asset calldata asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ASSET_TYPEHASH,
            hash(asset.assetType),
            keccak256(asset.data)
        ));
    }
    function hash(Asset[] calldata assets) internal pure returns (bytes32) {
        bytes32[] memory assetHashes = new bytes32[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            assetHashes[i] = hash(assets[i]);
        }
        return keccak256(abi.encodePacked(assetHashes));
    }
    function isSingularNft(
        Asset[] calldata assets
    ) internal pure returns (bool) {
        if (assets.length == 1 && assets[0].assetType.assetClass == ERC721_ASSET_CLASS) {
            return true;
        } else {
            return false;
        }
    }
    function isOnlyFungible(
        Asset[] calldata assets
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetType.assetClass != ERC20_ASSET_CLASS &&
                assets[i].assetType.assetClass != ETH_ASSET_CLASS) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./LibAsset.sol";

library LibSignature {
    enum AuctionType {
        FixedPrice,
        English,
        Decreasing
    }

    struct Order {
        address maker;                // user making a order (buy or sell)
        LibAsset.Asset[] makeAssets;  // asset(s) being sold or used to buy
        address taker;                // optional param => who is allowed to buy or sell, ZERO_ADDRESS if public sale
        LibAsset.Asset[] takeAssets;  // desired counterAsset(s), can be empty to allow any bids
        uint256 salt;                 // unique salt to eliminate collisons
        uint256 start;                // optional: set = 0 to disregard. start Unix timestamp of when order is valid
        uint256 end;                  // optional: set = 0 to disregard. end Unix timestamp of when order is invalid
        uint256 nonce;                // nonce for all orders
        AuctionType auctionType;      // type of auction
    }

    bytes32 constant private ORDER_TYPEHASH = keccak256(
        "Order(address maker,Asset[] makeAssets,address taker,Asset[] takeAssets,uint256 salt,uint256 start,uint256 end,uint256 nonce,uint8 auctionType)Asset(AssetType assetType,bytes data)AssetType(bytes4 assetClass,bytes data)"
    );

    function _domainSeparatorV4Marketplace() internal view returns (bytes32) {
        bytes32 _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        return keccak256(abi.encode(
            _TYPE_HASH,
            keccak256("NFT.com Marketplace"),
            keccak256("1"),
            block.chainid,
            address(this)
        ));
    }

    function _hashTypedDataV4Marketplace(bytes32 structHash) internal view returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4Marketplace(), structHash);
    }

    function getStructHash(Order calldata order, uint256 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.maker,
            LibAsset.hash(order.makeAssets),
            order.taker,
            LibAsset.hash(order.takeAssets),
            order.salt,
            order.start,
            order.end,
            nonce,
            order.auctionType
        ));
    }

    function validate(Order calldata order) internal view {
        require(order.maker != address(0x0), "ls: !0");
        require(order.start == 0 || order.start < block.timestamp, "ls: start expired");
        require(order.end == 0 || order.end > block.timestamp, "ls: end expired");
        require(order.makeAssets.length != 0, "ls: make > 0");
        require(order.takeAssets.length != 0, "ls: take > 0");
    }

    function concatVRS(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(65);
        bytes1 v1 = bytes1(v);

        assembly {
            mstore(add(result, 0x20), r)
            mstore(add(result, 0x40), s)
            mstore(add(result, 0x60), v1)
        }

        return result;
    }

    function recoverVRS(bytes memory signature)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(signature.length == 65, "NFT.com: !65 length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMarketplaceEvent.sol";

contract MarketplaceEvent is Initializable, UUPSUpgradeable, OwnableUpgradeable, IMarketplaceEvent {
    address public marketPlace;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setMarketPlace(address _marketPlace) external onlyOwner {
        marketPlace = _marketPlace;
        emit NewMarketplace(_marketPlace);
    }

    function emitExecuteSwap(
        bytes32 sellHash,
        bytes32 buyHash,
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        uint8[2] calldata v,
        bytes32[2] calldata r,
        bytes32[2] calldata s
    ) external returns (bool) {
        require(msg.sender == marketPlace);
        emit Match(
            sellHash,
            buyHash,
            sellOrder.auctionType,
            Sig(v[0], r[0], s[0]),
            Sig(v[1], r[1], s[1]),
            sellOrder.taker != address(0x0)
        );

        emit Match2A(
            sellHash,
            sellOrder.maker,
            sellOrder.taker,
            sellOrder.start,
            sellOrder.end,
            sellOrder.nonce,
            sellOrder.salt
        );

        emitMatch2(sellOrder, sellHash, buyOrder, buyHash);

        return true;
    }

    function emitBuyNow(
        bytes32 sellHash,
        LibSignature.Order calldata sellOrder,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(msg.sender == marketPlace);
        emit Match(
            sellHash,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            sellOrder.auctionType,
            Sig(v, r, s),
            Sig(
                0,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000
            ),
            sellOrder.taker != address(0x0)
        );

        emit BuyNowInfo(sellHash, msg.sender);

        emit Match2A(
            sellHash,
            sellOrder.maker,
            sellOrder.taker,
            sellOrder.start,
            sellOrder.end,
            sellOrder.nonce,
            sellOrder.salt
        );

        emitMatch2(sellOrder, sellHash, sellOrder, 0x0000000000000000000000000000000000000000000000000000000000000000);

        return true;
    }

    function emitMatch2(
        LibSignature.Order calldata sellOrder,
        bytes32 sellStructHash,
        LibSignature.Order calldata buyOrder,
        bytes32 buyStructHash
    ) private {
        uint256 totalSellOrderTakeAssets = sellOrder.takeAssets.length;
        bytes[] memory sellerMakerOrderAssetData = new bytes[](sellOrder.makeAssets.length);
        bytes[] memory sellerMakerOrderAssetTypeData = new bytes[](sellOrder.makeAssets.length);
        bytes4[] memory sellerMakerOrderAssetClass = new bytes4[](sellOrder.makeAssets.length);
        for (uint256 i = 0; i < sellOrder.makeAssets.length; i++) {
            sellerMakerOrderAssetData[i] = sellOrder.makeAssets[i].data;
            sellerMakerOrderAssetTypeData[i] = sellOrder.makeAssets[i].assetType.data;
            sellerMakerOrderAssetClass[i] = sellOrder.makeAssets[i].assetType.assetClass;
        }

        bytes[] memory sellerTakerOrderAssetData = new bytes[](sellOrder.takeAssets.length);
        bytes[] memory sellerTakerOrderAssetTypeData = new bytes[](sellOrder.takeAssets.length);
        bytes4[] memory sellerTakerOrderAssetClass = new bytes4[](sellOrder.takeAssets.length);
        for (uint256 i = 0; i < totalSellOrderTakeAssets;) {
            sellerTakerOrderAssetData[i] = sellOrder.takeAssets[i].data;
            sellerTakerOrderAssetTypeData[i] = sellOrder.takeAssets[i].assetType.data;
            sellerTakerOrderAssetClass[i] = sellOrder.takeAssets[i].assetType.assetClass;
            unchecked {
                i++;
            }
        }

        emit Match2B(
            sellStructHash,
            sellerMakerOrderAssetData,
            sellerMakerOrderAssetTypeData,
            sellerMakerOrderAssetClass,
            sellerTakerOrderAssetData,
            sellerTakerOrderAssetTypeData,
            sellerTakerOrderAssetClass
        );

        // buy order
        if (buyStructHash != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            emitMatch3(buyStructHash, buyOrder);
        }
    }

    function emitMatch3(bytes32 buyStructHash, LibSignature.Order calldata buyOrder) private {
        bytes[] memory buyerMakerOrderAssetData = new bytes[](buyOrder.makeAssets.length);
        bytes[] memory buyerMakerOrderAssetTypeData = new bytes[](buyOrder.makeAssets.length);
        bytes4[] memory buyerMakerOrderAssetClass = new bytes4[](buyOrder.makeAssets.length);
        uint256 totalBuyOrderMakeAssets = buyOrder.makeAssets.length;
        for (uint256 i = 0; i < totalBuyOrderMakeAssets;) {
            buyerMakerOrderAssetData[i] = buyOrder.makeAssets[i].data;
            buyerMakerOrderAssetTypeData[i] = buyOrder.makeAssets[i].assetType.data;
            buyerMakerOrderAssetClass[i] = buyOrder.makeAssets[i].assetType.assetClass;
            unchecked {
                ++i;
            }
        }

        bytes[] memory buyerTakerOrderAssetData = new bytes[](buyOrder.takeAssets.length);
        bytes[] memory buyerTakerOrderAssetTypeData = new bytes[](buyOrder.takeAssets.length);
        bytes4[] memory buyerTakerOrderAssetClass = new bytes4[](buyOrder.takeAssets.length);
        uint256 totalBuyOrderTakeAssets = buyOrder.takeAssets.length;
        for (uint256 i = 0; i < totalBuyOrderTakeAssets;) {
            buyerTakerOrderAssetData[i] = buyOrder.takeAssets[i].data;
            buyerTakerOrderAssetTypeData[i] = buyOrder.takeAssets[i].assetType.data;
            buyerTakerOrderAssetClass[i] = buyOrder.takeAssets[i].assetType.assetClass;
            unchecked {
                ++i;
            }
        }

        emit Match3A(
            buyStructHash,
            buyOrder.maker,
            buyOrder.taker,
            buyOrder.start,
            buyOrder.end,
            buyOrder.nonce,
            buyOrder.salt
        );

        emit Match3B(
            buyStructHash,
            buyerMakerOrderAssetData,
            buyerMakerOrderAssetTypeData,
            buyerMakerOrderAssetClass,
            buyerTakerOrderAssetData,
            buyerTakerOrderAssetTypeData,
            buyerTakerOrderAssetClass
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IERC1271.sol";
import "./helpers/TransferExecutor.sol";
import "./ValidationLogic.sol";
import "./MarketplaceEvent.sol";

contract NftMarketplace is Initializable, ReentrancyGuardUpgradeable, UUPSUpgradeable, TransferExecutor {
    using AddressUpgradeable for address;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    mapping(bytes32 => bool) public cancelledOrFinalized; // Cancelled / finalized order, by hash
    mapping(bytes32 => uint256) private _approvedOrdersByNonce;
    mapping(address => uint256) public nonces; // nonce for each account
    ValidationLogic public validationLogic;
    MarketplaceEvent public marketplaceEvent;
    mapping(address => bool) public aggregator;

    //events
    event Cancel(bytes32 structHash, address indexed maker);
    event Approval(bytes32 structHash, address indexed maker);
    event NonceIncremented(address indexed maker, uint256 newNonce);
    event EditAggregator(address indexed aggregator, bool status);

    enum ROYALTY {
        FUNGIBLE_MAKE_ASSETS,
        FUNGIBLE_TAKE_ASSETS,
        FUNGIBLE_SELLER_MAKE_ASSETS,
        FUNGIBLE_BUYER_MAKE_ASSETS,
        NEITHER
    }

    function initialize(
        INftTransferProxy _transferProxy,
        IERC20TransferProxy _erc20TransferProxy,
        address _cryptoKittyProxy,
        address _stakingContract,
        address _nftToken,
        ValidationLogic _validationLogic,
        MarketplaceEvent _marketplaceEvent
    ) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __TransferExecutor_init_unchained(
            _transferProxy,
            _erc20TransferProxy,
            _cryptoKittyProxy,
            _stakingContract,
            _nftToken,
            100
        );
        validationLogic = _validationLogic;
        marketplaceEvent = _marketplaceEvent;
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function editAggregator(address _aggregator, bool _status) external onlyOwner {
        aggregator[_aggregator] = _status;
        emit EditAggregator(_aggregator, _status);
    }

    /**
     * @dev internal functions for returning struct hash, after verifying it is valid
     * @param order the order itself
     * @param sig the struct sig (contains VRS)
     * @return hash of order and nonce
     */
    function requireValidOrder(
        LibSignature.Order calldata order,
        Sig memory sig,
        uint256 nonce
    ) internal view returns (bytes32) {
        bytes32 hash = LibSignature.getStructHash(order, nonce);
        require(validateOrder(hash, order, sig));
        return hash;
    }

    // invalidate all previous unused nonce orders
    function incrementNonce() external {
        uint256 newNonce = ++nonces[msg.sender];
        emit NonceIncremented(msg.sender, newNonce);
    }

    function orderApproved(LibSignature.Order calldata order) public view returns (bool approved) {
        require(order.salt != 0);
        bytes32 hash = LibSignature.getStructHash(order, nonces[order.maker]);

        return _approvedOrdersByNonce[hash] != 0 && !cancelledOrFinalized[hash];
    }

    /**
     * @dev internal function for validating a buy or sell order
     * @param hash the struct hash for a bid
     * @param order the order itself
     * @param sig the struct sig (contains VRS)
     * @return true if signature matches has of order; also checks for contract signature
     */
    function validateOrder(
        bytes32 hash,
        LibSignature.Order calldata order,
        Sig memory sig
    ) internal view returns (bool) {
        LibSignature.validate(order); // validates start and end time

        if (cancelledOrFinalized[hash]) {
            return false;
        }

        uint256 approvedOrderNoncePlusOne = _approvedOrdersByNonce[hash];
        if (approvedOrderNoncePlusOne != 0) {
            return approvedOrderNoncePlusOne == nonces[order.maker] + 1;
        }

        bytes32 hashV4 = LibSignature._hashTypedDataV4Marketplace(hash);

        if (ECDSAUpgradeable.recover(hashV4, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        // EIP 1271 Contract Validation
        if (order.maker.isContract()) {
            require(
                IERC1271(order.maker).isValidSignature(hashV4, LibSignature.concatVRS(sig.v, sig.r, sig.s)) ==
                    MAGICVALUE,
                "!1271"
            );

            return true;
        }

        return false;
    }

    /**
     * @dev public facing function that validates an order with a signature
     * @param order a buy or sell order
     * @param v sigV
     * @param r sigR
     * @param s sigS
     * @return tuple, index 0 = true if order is valid and index 1 = hash of order
     */
    function validateOrder_(
        LibSignature.Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool, bytes32) {
        bytes32 hash = LibSignature.getStructHash(order, nonces[order.maker]);
        return (validateOrder(hash, order, Sig(v, r, s)), hash);
    }

    function cancel(LibSignature.Order calldata order) external nonReentrant {
        require(msg.sender == order.maker);
        require(order.salt != 0);
        bytes32 hash = LibSignature.getStructHash(order, nonces[order.maker]);
        cancelledOrFinalized[hash] = true;
        emit Cancel(hash, msg.sender);
    }

    /**
     * @dev Approve an order
     * @param order the order (buy or sell) in question
     */
    function approveOrder_(LibSignature.Order calldata order) external nonReentrant {
        // checks
        require(msg.sender == order.maker);
        require(order.salt != 0);
        bytes32 hash = LibSignature.getStructHash(order, nonces[order.maker]);

        /* Assert order has not already been approved. */
        require(_approvedOrdersByNonce[hash] == 0);

        // effects

        /* Mark order as approved. */
        _approvedOrdersByNonce[hash] = nonces[order.maker] + 1;

        emit Approval(hash, msg.sender);
    }

    /**
     * @dev functions that allows anyone to execute a sell order that has a specified price > 0
     * @param sellOrder the listing
     * @param v vSig (optional if order is already approved)
     * @param r rSig (optional if order is already approved)
     * @param s sSig (optional if order is already approved)
     */
    function buyNow(
        LibSignature.Order calldata sellOrder,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        // checks
        bytes32 sellHash = requireValidOrder(sellOrder, Sig(v, r, s), nonces[sellOrder.maker]);
        require(validationLogic.validateBuyNow(sellOrder, msg.sender));
        require(msg.sender != sellOrder.maker, "!maker");
        uint256 totalSellOrderTakeAssets = sellOrder.takeAssets.length;
        uint256 totalSellOrderMakeAssets = sellOrder.makeAssets.length;

        cancelledOrFinalized[sellHash] = true;

        ROYALTY royaltyScore = (LibAsset.isSingularNft(sellOrder.takeAssets) &&
            LibAsset.isOnlyFungible(sellOrder.makeAssets))
            ? ROYALTY.FUNGIBLE_MAKE_ASSETS
            : (LibAsset.isSingularNft(sellOrder.makeAssets) && LibAsset.isOnlyFungible(sellOrder.takeAssets))
            ? ROYALTY.FUNGIBLE_TAKE_ASSETS
            : ROYALTY.NEITHER;

        // interactions (i.e. perform swap, fees and royalties)
        for (uint256 i = 0; i < totalSellOrderTakeAssets;) {
            // send assets from buyer to seller (payment for goods)
            transfer(
                sellOrder.auctionType,
                sellOrder.takeAssets[i],
                msg.sender,
                sellOrder.maker,
                sellOrder.auctionType == LibSignature.AuctionType.Decreasing
                    ? validationLogic.getDecreasingPrice(sellOrder)
                    : 0,
                royaltyScore == ROYALTY.FUNGIBLE_TAKE_ASSETS,
                sellOrder.makeAssets
            );

            unchecked {
                ++i;
            }
        }

        for (uint256 j = 0; j < totalSellOrderMakeAssets;) {
            // send assets from seller to buyer (goods)
            transfer(
                sellOrder.auctionType,
                sellOrder.makeAssets[j],
                sellOrder.maker,
                msg.sender,
                0,
                royaltyScore == ROYALTY.FUNGIBLE_MAKE_ASSETS,
                sellOrder.takeAssets // nft asset for royalty calculation
            );

            unchecked {
                ++j;
            }
        }

        require(marketplaceEvent.emitBuyNow(sellHash, sellOrder, v, r, s));
    }

    /**
     * @dev executeSwap takes two orders and executes them together
     * @param sellOrder the listing
     * @param buyOrder bids for a listing
     * @param v array of v sig, index 0 = sellOrder, index 1 = buyOrder
     * @param r array of r sig, index 0 = sellOrder, index 1 = buyOrder
     * @param s array of s sig, index 0 = sellOrder, index 1 = buyOrder
     */
    function executeSwap(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        uint8[2] calldata v,
        bytes32[2] calldata r,
        bytes32[2] calldata s
    ) public payable nonReentrant {
        // checks
        bytes32 sellHash = requireValidOrder(sellOrder, Sig(v[0], r[0], s[0]), nonces[sellOrder.maker]);
        bytes32 buyHash = requireValidOrder(buyOrder, Sig(v[1], r[1], s[1]), nonces[buyOrder.maker]);
        require(msg.sender == sellOrder.maker || msg.sender == buyOrder.maker || aggregator[msg.sender], "!maker");
        require(validationLogic.validateMatch_(sellOrder, buyOrder, msg.sender, false));

        if (sellOrder.end != 0) {
            require(block.timestamp >= (sellOrder.end - 24 hours), "!exe");
        }

        // effects
        cancelledOrFinalized[buyHash] = true;
        cancelledOrFinalized[sellHash] = true;

        ROYALTY royaltyScore = (LibAsset.isSingularNft(buyOrder.makeAssets) &&
            LibAsset.isOnlyFungible(sellOrder.makeAssets))
            ? ROYALTY.FUNGIBLE_SELLER_MAKE_ASSETS
            : (LibAsset.isSingularNft(sellOrder.makeAssets) && LibAsset.isOnlyFungible(buyOrder.makeAssets))
            ? ROYALTY.FUNGIBLE_BUYER_MAKE_ASSETS
            : ROYALTY.NEITHER;

        // interactions (i.e. perform swap, fees and royalties)
        for (uint256 i = 0; i < buyOrder.makeAssets.length;) {
            // send assets from buyer to seller (payment for goods)
            transfer(
                sellOrder.auctionType,
                buyOrder.makeAssets[i],
                buyOrder.maker,
                sellOrder.maker,
                0,
                royaltyScore == ROYALTY.FUNGIBLE_BUYER_MAKE_ASSETS,
                sellOrder.makeAssets // nft asset for royalty calculation
            );

            unchecked {
                ++i;
            }
        }

        for (uint256 j = 0; j < sellOrder.makeAssets.length;) {
            // send assets from seller to buyer (goods)
            transfer(
                sellOrder.auctionType,
                sellOrder.makeAssets[j],
                sellOrder.maker,
                buyOrder.maker,
                0,
                royaltyScore == ROYALTY.FUNGIBLE_SELLER_MAKE_ASSETS,
                buyOrder.makeAssets // nft asset for royalty calculation
            );

            unchecked {
                ++j;
            }
        }

        // refund leftover eth in contract
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success);

        require(marketplaceEvent.emitExecuteSwap(sellHash, buyHash, sellOrder, buyOrder, v, r, s));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IValidationLogic.sol";

contract ValidationLogic is Initializable, UUPSUpgradeable, OwnableUpgradeable, IValidationLogic {
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     *  @dev validateSingleAssetMatch1 makes sure two assets can be matched (same index in LibSignature array)
     *  @param buyTakeAsset what the buyer is hoping to take
     *  @param sellMakeAsset what the seller is hoping to make
     *  @return true if valid
     */
    function validateSingleAssetMatch1(LibAsset.Asset calldata buyTakeAsset, LibAsset.Asset calldata sellMakeAsset)
        internal
        pure
        returns (bool)
    {
        (uint256 sellMakeValue, ) = abi.decode(sellMakeAsset.data, (uint256, uint256));
        (uint256 buyTakeValue, ) = abi.decode(buyTakeAsset.data, (uint256, uint256));

        return
            // asset being sold
            (sellMakeAsset.assetType.assetClass == buyTakeAsset.assetType.assetClass) &&
            // sell value == buy take
            sellMakeValue == buyTakeValue;
    }

    /**
     * @dev validAssetTypeData checks if tokenIds are the same (only for NFTs)
     *  @param sellTakeAssetClass (bytes4 of type in LibAsset)
     *  @param buyMakeAssetTypeData assetTypeData for makeAsset on buyOrder
     *  @param sellTakeAssetTypeData assetTypeData for takeAsset on sellOrder
     *  @return true if valid
     */
    function validAssetTypeData(
        bytes4 sellTakeAssetClass,
        bytes memory buyMakeAssetTypeData,
        bytes memory sellTakeAssetTypeData
    ) internal pure returns (bool) {
        if (
            sellTakeAssetClass == LibAsset.ERC721_ASSET_CLASS ||
            sellTakeAssetClass == LibAsset.ERC1155_ASSET_CLASS ||
            sellTakeAssetClass == LibAsset.CRYPTO_KITTY
        ) {
            (address buyMakeAddress, uint256 buyMakeTokenId, ) = abi.decode(
                buyMakeAssetTypeData,
                (address, uint256, bool)
            );

            (address sellTakeAddress, uint256 sellTakeTokenId, bool sellTakeAllowAll) = abi.decode(
                sellTakeAssetTypeData,
                (address, uint256, bool)
            );

            require(buyMakeAddress == sellTakeAddress, "vatd !match");

            if (sellTakeAllowAll) {
                return true;
            } else {
                return buyMakeTokenId == sellTakeTokenId;
            }
        } else if (sellTakeAssetClass == LibAsset.ERC20_ASSET_CLASS) {
            return abi.decode(buyMakeAssetTypeData, (address)) == abi.decode(sellTakeAssetTypeData, (address));
        } else if (sellTakeAssetClass == LibAsset.ETH_ASSET_CLASS) {
            // no need to handle LibAsset.ETH_ASSET_CLASS since that is handled during execution
            return true;
        } else {
            // should not come here
            return false;
        }
    }

    /**
     *  @dev validateSingleAssetMatch2 makes sure two assets can be matched (same index in LibSignature array)
     *  @param sellTakeAsset what the seller is hoping to take
     *  @param buyMakeAsset what the buyer is hoping to make
     *  @return true if valid
     */
    function validateSingleAssetMatch2(LibAsset.Asset calldata sellTakeAsset, LibAsset.Asset calldata buyMakeAsset)
        internal
        pure
        returns (bool)
    {
        (uint256 buyMakeValue, ) = abi.decode(buyMakeAsset.data, (uint256, uint256));
        (, uint256 sellTakeMinValue) = abi.decode(sellTakeAsset.data, (uint256, uint256));

        return
            // token denominating sell order listing
            (sellTakeAsset.assetType.assetClass == buyMakeAsset.assetType.assetClass) &&
            // buyOrder must be within bounds
            buyMakeValue >= sellTakeMinValue &&
            // make sure tokenIds match if NFT AND contract address matches
            validAssetTypeData(
                sellTakeAsset.assetType.assetClass,
                buyMakeAsset.assetType.data,
                sellTakeAsset.assetType.data
            );

        // NOTE: sellTakeMin could be 0 and buyer could offer 0;
        // NOTE: (in case seller wants to make a list of optional assets to select from)
    }

    /**
     *  @dev validateMatch makes sure two orders (on sell side and buy side) match correctly
     *  @param sellOrder the listing
     *  @param buyOrder bid for a listing
     *  @param sender person sending the transaction
     *  @param viewOnly true for viewOnly (primarily for testing purposes)
     *  @return true if orders can match
     */
    function validateMatch(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        address sender,
        bool viewOnly
    ) internal pure returns (bool) {
        // flag to ensure ETH is not used multiple timese
        bool ETH_ASSET_USED = false;

        require(
            (sellOrder.auctionType == LibSignature.AuctionType.English) &&
                (buyOrder.auctionType == LibSignature.AuctionType.English),
            "vm auctionType"
        );

        // sellOrder taker must be valid
        require(
            (sellOrder.taker == address(0) || sellOrder.taker == buyOrder.maker) &&
                // buyOrder taker must be valid
                (buyOrder.taker == address(0) || buyOrder.taker == sellOrder.maker),
            "vm !match"
        );

        // must be selling something and make and take must match
        require(
            sellOrder.makeAssets.length != 0 && buyOrder.takeAssets.length == sellOrder.makeAssets.length,
            "vm assets > 0"
        );

        require(
            buyOrder.makeAssets.length != 0 && sellOrder.takeAssets.length == buyOrder.makeAssets.length,
            "vm assets > 0"
        );

        // check if seller maker and buyer take match on every corresponding index
        for (uint256 i = 0; i < sellOrder.makeAssets.length; i++) {
            if (!validateSingleAssetMatch1(buyOrder.takeAssets[i], sellOrder.makeAssets[i])) {
                return false;
            }

            // if ETH, seller must be sending ETH / calling
            if (sellOrder.makeAssets[i].assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
                require(!ETH_ASSET_USED, "vm eth");
                require(viewOnly || sender == sellOrder.maker, "vma sellerEth"); // seller must pay ETH
                ETH_ASSET_USED = true;
            }
        }

        // if seller's takeAssets = 0, that means seller doesn't make what buyer's makeAssets are, so ignore
        // if seller's takeAssets > 0, seller has a specified list
        if (sellOrder.takeAssets.length != 0) {
            require(sellOrder.takeAssets.length == buyOrder.makeAssets.length, "vm assets_len");
            // check if seller maker and buyer take match on every corresponding index
            for (uint256 i = 0; i < sellOrder.takeAssets.length; i++) {
                if (!validateSingleAssetMatch2(sellOrder.takeAssets[i], buyOrder.makeAssets[i])) {
                    return false;
                }

                // if ETH, buyer must be sending ETH / calling
                if (buyOrder.makeAssets[i].assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
                    require(!ETH_ASSET_USED, "vm eth2");
                    require(viewOnly || sender == buyOrder.maker, "vmb buyerEth"); // buyer must pay ETH
                    ETH_ASSET_USED = true;
                }
            }
        }

        return true;
    }

    function decreasingValidation(LibSignature.Order calldata sellOrder) private pure {
        require(sellOrder.takeAssets.length == 1, "dv 1_len");
        require(
            (sellOrder.takeAssets[0].assetType.assetClass == LibAsset.ETH_ASSET_CLASS) ||
                (sellOrder.takeAssets[0].assetType.assetClass == LibAsset.ERC20_ASSET_CLASS),
            "dv fung" // only fungible tokens
        );
    }

    /**
     *  @dev validateBuyNow makes sure a buyer can fulfill the sellOrder and that the sellOrder is formatted properly
     *  @param sellOrder the listing
     *  @param buyer potential executor of sellOrder
     *  @return true if validBuyNow
     */
    function validateBuyNow(LibSignature.Order calldata sellOrder, address buyer) public view override returns (bool) {
        require((sellOrder.taker == address(0) || sellOrder.taker == buyer), "vbn !match");
        require(sellOrder.makeAssets.length != 0, "vbn make > 0");
        require(sellOrder.takeAssets.length != 0, "vbn take > 0");

        if (sellOrder.auctionType == LibSignature.AuctionType.Decreasing) {
            decreasingValidation(sellOrder);

            require(sellOrder.start != 0 && sellOrder.start < block.timestamp, "vbn start");
            require(sellOrder.end != 0 && sellOrder.end > block.timestamp, "vbn end");
        }

        return true;
    }

    /**
     *  @dev public facing function to make sure orders can execute
     *  @param sellOrder the listing
     *  @param buyOrder bid for a listing
     *  @param viewOnly true for viewOnly (primarily for testing purposes)
     *  @return true if valid match
     */
    function validateMatch_(
        LibSignature.Order calldata sellOrder,
        LibSignature.Order calldata buyOrder,
        address sender,
        bool viewOnly
    ) public pure override returns (bool) {
        return validateMatch(sellOrder, buyOrder, sender, viewOnly);
    }

    /**
     *  @dev public facing function to get current price of a decreasing price auction
     *  @param sellOrder the listing
     *  @return current price denominated in the asset specified
     */
    function getDecreasingPrice(LibSignature.Order calldata sellOrder) public view override returns (uint256) {
        require(sellOrder.auctionType == LibSignature.AuctionType.Decreasing, "gdp !decreasing");
        decreasingValidation(sellOrder);

        uint256 secondsPassed = 0;
        uint256 publicSaleDurationSeconds = sellOrder.end - sellOrder.start;
        uint256 finalPrice;
        uint256 initialPrice;

        (initialPrice, finalPrice) = abi.decode(sellOrder.takeAssets[0].data, (uint256, uint256));

        secondsPassed = block.timestamp - sellOrder.start;

        if (secondsPassed >= publicSaleDurationSeconds) {
            return finalPrice;
        } else {
            uint256 totalPriceChange = initialPrice - finalPrice;
            uint256 currentPriceChange = (totalPriceChange * secondsPassed) / publicSaleDurationSeconds;
            return initialPrice - currentPriceChange;
        }
    }
}