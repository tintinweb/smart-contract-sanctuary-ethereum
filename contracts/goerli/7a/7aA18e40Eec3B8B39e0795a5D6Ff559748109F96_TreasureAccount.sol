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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
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
pragma solidity ^0.8.9;

interface IClientAccountBeacon {

    event ClientAccountBeaconCreated(address beacon, address logic);

    /**
     * @dev Returns client account beacon address
     */
    function getClientAccountBeacon() external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "./IClientAccountBeacon.sol";
import "./Multisignable.sol";

contract MultisigClientAccountBeacon is Multisignable, IClientAccountBeacon {

    uint8 private _operation;

    UpgradeableBeacon internal _clientAccountBeacon;
    bool private _isClientAccountBeaconSet;
    address private _clientAccountLogic;

    struct BeaconUpgradeTrans {
        address clientAccountLogic;
    }
    mapping (uint256 => BeaconUpgradeTrans) public _transactions;

    function __MultisigClientAccountBeacon_init(
        uint8 operation,
        address clientAccountLogic,
        uint signCount) internal onlyInitializing {
        __MultisigClientAccountBeacon_init_unchained(operation, clientAccountLogic, signCount);
    }

    function __MultisigClientAccountBeacon_init_unchained(
        uint8 operation,
        address clientAccountLogic,
        uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
        _clientAccountLogic = clientAccountLogic;
        _deployClientAccountBeacon(clientAccountLogic);
    }

    function _deployClientAccountBeacon(address clientAccountLogic) internal {
        if (!_isClientAccountBeaconSet) {
            if (clientAccountLogic != address(0)) {
                _clientAccountBeacon = new UpgradeableBeacon(clientAccountLogic);
                emit ClientAccountBeaconCreated(address(_clientAccountBeacon), clientAccountLogic);
            }
            _isClientAccountBeaconSet = true;
        }
    }

    function getClientAccountBeacon() external view override returns(address) {
        return address(_clientAccountBeacon);
    }

    function requestBeaconUpgrade(address clientAccountLogic) external
    ownerExists(msg.sender)
    returns (uint256 BeaconUpgradeTransId)
    {
        BeaconUpgradeTransId = createBeaconUpgradeTrans(clientAccountLogic);
        confirmBeaconUpgrade(BeaconUpgradeTransId);
        return BeaconUpgradeTransId;
    }

    function confirmBeaconUpgrade(uint256 transId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transId);
        executeBeaconUpgrade(transId);
    }

    function revokeBeaconUpgradeConfirmation(uint256 transId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transId);
    }

    function createBeaconUpgradeTrans(address clientAccountLogic)
    private
    returns (uint256 beaconUpgradeTransId)
    {
        beaconUpgradeTransId = getTransactionCount(_operation);

        BeaconUpgradeTrans storage beaconUpgradeTrans = _transactions[beaconUpgradeTransId];
        createTransaction(_operation, address(_clientAccountBeacon), beaconUpgradeTransId);
        beaconUpgradeTrans.clientAccountLogic = clientAccountLogic;

        return beaconUpgradeTransId;
    }

    function executeBeaconUpgrade(uint256 transId)
    private
    ownerExists(msg.sender)
    {
        if (isConfirmed(_operation, transId)) {
            BeaconUpgradeTrans storage beaconUpgradeTrans = _transactions[transId];
            bytes memory payload = abi.encodeWithSignature("upgradeTo(address)", beaconUpgradeTrans.clientAccountLogic);
            executeTransaction(_operation, transId, payload);
        }
    }

    function getBeaconUpgradeTrans(uint256 transId) public view
        returns(BeaconUpgradeTrans memory, Transaction memory) {

        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigContractUpgradeable is Multisignable {

    uint8 private _operation;

    struct UpgradeContractTransaction {
        address newContractImplementationAddress;
    }

    mapping (uint256 => UpgradeContractTransaction) private _transactions;

    function __MultisigContractUpgradeable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigContractUpgradeable_init_unchained(operation, signCount);
    }

    function __MultisigContractUpgradeable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestUpgradeContract(address token, address newContractImplementationAddress) external
    ownerExists(msg.sender)
    addressNotNull(newContractImplementationAddress)
    returns (uint256 transId)
    {
        transId = createUpgradeContractTransaction(token, newContractImplementationAddress);
        confirmUpgradeContract(transId);
        return transId;
    }

    function confirmUpgradeContract(uint256 transId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transId);
        executeUpgradeContract(transId);
    }

    function revokeUpgradeContractConfirmation(uint256 transId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transId);
    }

    function createUpgradeContractTransaction(address token, address newContractImplementationAddress)
    private
    returns (uint256 transId)
    {

        transId = getTransactionCount(_operation);

        UpgradeContractTransaction storage upgradeContractTransaction = _transactions[transId];
        createTransaction(_operation, token, transId);
        upgradeContractTransaction.newContractImplementationAddress = newContractImplementationAddress;

        return transId;
    }

    function executeUpgradeContract(uint256 transId)
    private
    ownerExists(msg.sender)
    {
        if (isConfirmed(_operation, transId)) {
            UpgradeContractTransaction storage upgradeContractTransaction = _transactions[transId];

            bytes memory payload = abi.encodeWithSignature("upgradeTo(address)", upgradeContractTransaction.newContractImplementationAddress);
            executeTransaction(_operation, transId, payload);
        }
    }

    function getUpgradeContractTrans(uint256 transId) public view
        returns(UpgradeContractTransaction memory, Transaction memory) {

        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigEmissionable is Multisignable {

    uint8 private _operation;

    enum EmissionableOp {
        MINT,
        BURN
    }

    struct EmissionableTrans {
        uint256 amount;
        EmissionableOp op;
    }

    mapping (uint256 => EmissionableTrans) private _transactions;

    function __MultisigEmissionable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigEmissionable_init_unchained(operation, signCount);
    }

    function __MultisigEmissionable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestEmissionableOp(address token, uint256 amount, EmissionableOp op) external
    ownerExists(msg.sender)
    returns (uint256 transId)
    {
        transId = createEmissionableTransaction(token, amount, op);
        confirmEmissionableOp(transId);
        return transId;
    }

    function confirmEmissionableOp(uint256 transId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transId);
        executeEmissionableOp(transId);
    }

    function revokeEmissionableOp(uint256 transId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transId);
    }

    function createEmissionableTransaction(address token, uint256 amount, EmissionableOp op)
    private
    returns (uint256 transId)
    {
        transId = getTransactionCount(_operation);

        EmissionableTrans storage trans = _transactions[transId];
        createTransaction(_operation, token, transId);
        trans.amount = amount;
        if (op == EmissionableOp.MINT) {
            trans.op = op;
        } else if (op == EmissionableOp.BURN) {
            trans.op = op;
        } else {
            revert("Operation unknown");
        }

        return transId;
    }

    function executeEmissionableOp(uint256 transId)
    private
    ownerExists(msg.sender)
    {
        if (isConfirmed(_operation, transId)) {
            EmissionableTrans storage trans = _transactions[transId];
            bytes memory payload;
            if (trans.op == EmissionableOp.MINT) {
                payload = abi.encodeWithSignature("mint(uint256)", trans.amount);
            } else if (trans.op == EmissionableOp.BURN) {
                payload = abi.encodeWithSignature("burn(uint256)", trans.amount);
            } else {
                revert("Operation unknown");
            }
            executeTransaction(_operation, transId, payload);
        }
    }

    function getEmissionableTrans(uint256 transId) public view
        returns(EmissionableTrans memory, Transaction memory) {

        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigFreezable is Multisignable {

    uint8 private _operation;

    enum FreezableOperation {
        FREEZE,
        UNFREEZE,
        WIPE
    }

    struct FreezableTrans {
        address account;
        FreezableOperation op;
    }

    mapping (uint256 => FreezableTrans) private _transactions;

    function __MultisigFreezable_init(uint8 operation, uint signCount)
    internal
    onlyInitializing
    {
        __MultisigFreezable_init_unchained(operation, signCount);
    }

    function __MultisigFreezable_init_unchained(uint8 operation, uint signCount)
    internal
    onlyInitializing
    {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestFreezableOp(address token, address account, FreezableOperation op) external
    ownerExists(msg.sender)
    returns (uint256 transId) {

        transId = createFreezableTrans(token, account, op);
        confirmFreezableOp(transId);
        return transId;
    }

    function confirmFreezableOp(uint256 transId)
    public
    ownerExists(msg.sender) {

        confirmTransaction(_operation, transId);
        executeFreezableOp(transId);
    }

    function revokeFreezableOp(uint256 transId)
    public
    ownerExists(msg.sender) {

        revokeTransactionConfirmation(_operation, transId);
    }

    function createFreezableTrans(address token, address account, FreezableOperation op)
    private
    returns (uint256 transId)
    {

        transId = getTransactionCount(_operation);

        FreezableTrans storage trans = _transactions[transId];
        createTransaction(_operation, token, transId);
        trans.account = account;
        if (op == FreezableOperation.FREEZE) {
            trans.op = op;
        } else if (op == FreezableOperation.UNFREEZE) {
            trans.op = op;
        } else if (op == FreezableOperation.WIPE) {
            trans.op = op;
        } else {
            revert("Unknown operation");
        }

        return transId;
    }

    function executeFreezableOp(uint256 transId)
    private
    ownerExists(msg.sender)
    transactionConfirmed(_operation, transId, msg.sender)
    transactionNotExecuted(_operation, transId)
    {
        if (isConfirmed(_operation, transId)) {
            FreezableTrans storage trans = _transactions[transId];
            address account = trans.account;
            bytes memory payload;
            if (trans.op == FreezableOperation.FREEZE) {
                payload = abi.encodeWithSignature("freeze(address)", account);
            } else if (trans.op == FreezableOperation.UNFREEZE) {
                payload = abi.encodeWithSignature("unfreeze(address)", account);
            } else if (trans.op == FreezableOperation.WIPE) {
                payload = abi.encodeWithSignature("wipeFrozenAddress(address)", account);
            } else {
                revert("Operation unknown");
            }
            executeTransaction(_operation, transId, payload);
        }
    }

    function getFreezableTrans(uint256 transId) public view
        returns(FreezableTrans memory, Transaction memory) {

        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Multisignable is Initializable {

    event Created(uint8 operation, uint256 indexed id, address indexed initiator);
    event Confirmed(uint8 operation, uint256 indexed id, address indexed confirmer);
    event Revoked(uint8 operation, uint256 indexed id, address indexed sender);
    event Executed(uint8 operation, uint256 indexed id);
    event Failed(uint8 operation, uint256 indexed id);

    mapping (uint => mapping (address => bool)) internal _confirmations;
    mapping (address => bool) internal _isOwner;
    address[] internal _owners;
    mapping (uint8 => uint) internal _signatureCount;
    uint8[] internal _operations;

    struct Transaction {
        uint256 transactionId;
        address tokenAddress;
        address initiator;
        bool executed;
    }

    mapping (uint8 => mapping (uint256 => Transaction)) private _transactions;
    mapping (uint8 => uint256) private _lastTransactionId;
    mapping (uint8 => uint256) public _transactionCount;
    mapping (uint8 => mapping (uint256 => mapping (address => bool))) public _transactionConfirmations;

    modifier transactionExists(uint8 operation, uint256 transactionId) {
        require(_transactions[operation][transactionId].initiator != address(0));
        _;
    }

    modifier transactionConfirmed(uint8 operation, uint256 transactionId, address owner) {
        require(_transactionConfirmations[operation][transactionId][owner]);
        _;
    }

    modifier checkOperationConfirmed(uint8 operation) {
        require(_isLastConfirmed(operation));
        _;
    }

    modifier transactionNotConfirmed(uint8 operation, uint transactionId, address owner) {
        require(!_transactionConfirmations[operation][transactionId][owner]);
        _;
    }

    modifier transactionNotExecuted(uint8 operation, uint256 transactionId) {
        require(!_transactions[operation][transactionId].executed);
        _;
    }

    modifier addressNotNull(address addressValue) {
        require(addressValue != address(0));
        _;
    }

    modifier ownerExists(address owner) {
        require(_isOwner[owner]);
        _;
    }

    modifier ownerDoesNotExists(address owner) {
        require(!_isOwner[owner]);
        _;
    }

    function __Multisignable_init(address[] memory owners) internal onlyInitializing {
        __Multisignable_init_unchained(owners);
    }

    function __Multisignable_init_unchained(address[] memory owners) internal onlyInitializing {
        for (uint i = 0; i < owners.length; i++) {
            require(!_isOwner[owners[i]] && owners[i] != address(0));
            _isOwner[owners[i]] = true;
        }
        _owners = owners;
    }

    function getTransactionCount(uint8 operation)
    internal
    returns(uint256)
    {
        uint256 transactionId = _transactionCount[operation];
        _transactionCount[operation] = transactionId + 1;
        return transactionId;
    }

    function confirmTransaction(uint8 operation, uint256 transactionId)
    internal
    ownerExists(msg.sender)
    transactionExists(operation, transactionId)
    transactionNotConfirmed(operation, transactionId, msg.sender)
    {
        _transactionConfirmations[operation][transactionId][msg.sender] = true;
        emit Confirmed(operation, transactionId, msg.sender);
    }

    function revokeTransactionConfirmation(uint8 operation, uint transactionId)
    internal
    ownerExists(msg.sender)
    transactionConfirmed(operation, transactionId, msg.sender)
    transactionNotExecuted(operation, transactionId)
    {
        _transactionConfirmations[operation][transactionId][msg.sender] = false;
        emit Revoked(operation, transactionId, msg.sender);
    }

    function executeTransaction(uint8 operation, uint256 transactionId, bytes memory payload)
    internal
    ownerExists(msg.sender)
    transactionConfirmed(operation, transactionId, msg.sender)
    transactionNotExecuted(operation, transactionId)
    returns(bool success, bytes memory returnData) {

        Transaction storage transaction = _transactions[operation][transactionId];
        (success, returnData) = transaction.tokenAddress.call(payload);
        if (success) {
            transaction.executed = true;
            emit Executed(operation, transactionId);
        } else {
            emit Failed(operation, transactionId);
        }
    }

    function executeTransaction(uint8 operation, uint256 transactionId)
    internal
    ownerExists(msg.sender)
    transactionConfirmed(operation, transactionId, msg.sender)
    transactionNotExecuted(operation, transactionId) {

        Transaction storage transaction = _transactions[operation][transactionId];
        transaction.executed = true;
        emit Executed(operation, transactionId);
    }

    function createTransaction(uint8 operation, address tokenAddress, uint256 transactionId)
        internal {

        Transaction storage transaction = _transactions[operation][transactionId];
        transaction.tokenAddress = tokenAddress;
        transaction.transactionId = transactionId;
        transaction.initiator = msg.sender;
        transaction.executed = false;
        _lastTransactionId[operation] = transactionId;
        emit Created(operation, transactionId, msg.sender);
    }

    function createTransaction(uint8 operation, uint256 transactionId)
        internal {
        Transaction storage transaction = _transactions[operation][transactionId];
        transaction.transactionId = transactionId;
        transaction.initiator = msg.sender;
        transaction.executed = false;
        _lastTransactionId[operation] = transactionId;
        emit Created(operation, transactionId, msg.sender);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint8 operation, uint256 transactionId)
    public
    view
    returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < _owners.length; i++) {
            if (_transactionConfirmations[operation][transactionId][_owners[i]]) {
                count += 1;
            }
            if (count == _signatureCount[operation])
                return true;
        }
        return false;
    }

    /// @dev Check the confirmation status of a last transaction.
    function _isLastConfirmed(uint8 operation)
    internal
    view
    returns (bool)
    {
       return isConfirmed(operation, _lastTransactionId[operation]);
    }

    function getTrans(uint8 operation, uint256 transactionId) internal view
    returns(Transaction memory)
    {
        return _transactions[operation][transactionId];
    }

    function getOwners() public view
    returns(address[] memory) {

        return _owners;
    }

    function isOwner(address owner) public view
    returns(bool) {

        return _isOwner[owner];
    }

    function getOperations() public view returns (uint8[] memory) {
        return _operations;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigOwnersManageable is Multisignable {

    uint8 private _operation;

    struct OwnersTrans {
        address owner;
        bool del;
    }

    mapping (uint256 => OwnersTrans) private _ownersTrans;

    function __MultisigOwnersManageable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigOwnersManageable_init_unchained(operation, signCount);
    }

    function __MultisigOwnersManageable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestOwnersOp(address owner, bool del) external
    ownerExists(msg.sender)
    returns (uint256 transId) {
        if (del) {
            require(_owners.length > 1);
            require(isOwner(owner));
        } else {
            require(!isOwner(owner));
        }
        transId = createOwnersTrans(owner, del);
        confirmOwnersOp(transId);
        return transId;
    }

    function confirmOwnersOp(uint256 transId)
    public
    ownerExists(msg.sender) {

        confirmTransaction(_operation, transId);
        executeOwnersOp(transId);
    }

    function revokeOwnersOp(uint256 transId)
    public
    ownerExists(msg.sender) {

        revokeTransactionConfirmation(_operation, transId);
    }

    function createOwnersTrans(address owner, bool del)
    private
    returns (uint256 transId)
    {

        transId = getTransactionCount(_operation);

        OwnersTrans storage trans = _ownersTrans[transId];
        createTransaction(_operation, transId);
        trans.owner = owner;
        trans.del = del;

        return transId;
    }

    function executeOwnersOp(uint256 transId)
    private
    ownerExists(msg.sender)
    transactionConfirmed(_operation, transId, msg.sender)
    transactionNotExecuted(_operation, transId)
    {
        if (isConfirmed(_operation, transId)) {
            OwnersTrans storage trans = _ownersTrans[transId];
            address owner = trans.owner;

            _isOwner[owner] = !trans.del;
            if (trans.del) {
                for (uint i = 0; i < _owners.length; i++) {
                    if (_owners[i] == owner) {
                        _owners[i] = _owners[_owners.length - 1];
                        _owners.pop();
                        break;
                    }
                }
                for (uint8 i = 0; i < _operations.length; i++) {
                    if (_signatureCount[_operations[i]] > _owners.length) {
                        _signatureCount[_operations[i]] = _owners.length;
                    }
                }
            } else {
                _owners.push(owner);
            }

            executeTransaction(_operation, transId);
        }
    }

    function getOwnersTrans(uint256 transId) public view
        returns(OwnersTrans memory, Transaction memory) {

        return (_ownersTrans[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigPausable is Multisignable {

    uint8 private _operation;

    enum PausableOperation {
        PAUSE,
        UNPAUSE
    }

    struct PausableTrans {
        PausableOperation op;
    }


    mapping (uint256 => PausableTrans) private _transactions;

    function __MultisigPausable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigPausable_init_unchained(operation, signCount);
    }

    function __MultisigPausable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestPausableOp(address token, PausableOperation op) external
    ownerExists(msg.sender)
    returns (uint256 transId) {

        transId = createPausableTrans(token, op);
        confirmPausableOp(transId);
        return transId;
    }

    function confirmPausableOp(uint256 transId)
    public
    ownerExists(msg.sender) {

        confirmTransaction(_operation, transId);
        executePausableOp(transId);
    }

    function revokePausableOp(uint256 transId)
    public
    ownerExists(msg.sender) {

        revokeTransactionConfirmation(_operation, transId);
    }

    function createPausableTrans(address token, PausableOperation op)
    private
    returns (uint256 transId)
    {

        transId = getTransactionCount(_operation);

        PausableTrans storage trans = _transactions[transId];
        createTransaction(_operation, token, transId);
        if (op == PausableOperation.PAUSE) {
            trans.op = op;
        } else if (op == PausableOperation.UNPAUSE) {
            trans.op = op;
        } else {
            revert("Operation unknown");
        }

        return transId;
    }

    function executePausableOp(uint256 transId)
    private
    ownerExists(msg.sender)
    transactionConfirmed(_operation, transId, msg.sender)
    transactionNotExecuted(_operation, transId)
    {
        if (isConfirmed(_operation, transId)) {
            PausableTrans storage trans = _transactions[transId];
            bytes memory payload;
            if (trans.op == PausableOperation.PAUSE) {
                payload = abi.encodeWithSignature("pause()");
            } else if (trans.op == PausableOperation.UNPAUSE) {
                payload = abi.encodeWithSignature("unpause()");
            } else {
                revert("Operation unknown");
            }
            executeTransaction(_operation, transId, payload);
        }
    }

    function getPausableTrans(uint256 transId) public view
    returns(PausableTrans memory, Transaction memory) {

        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigSignatureCountManageable is Multisignable {

    uint8 private _operation;
    uint8 private constant ALL = 255;

    struct ChangeSignatureCountTransaction {
        uint8 operationType;
        uint newSignatureCount;
    }

    mapping (uint256 => ChangeSignatureCountTransaction) private _transactions;

    function __MultisigSignatureCountManageable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigSignatureCountManageable_init_unchained(operation, signCount);
    }

    function __MultisigSignatureCountManageable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestChangeAllSignatureCount(uint newSignatureCount) external
    ownerExists(msg.sender)
    returns (uint256 changeSignatureCountTransactionId)
    {
        return requestChangeSignatureCount(ALL, newSignatureCount);
    }

    function requestChangeSignatureCount(uint8 operationType, uint newSignatureCount) public
    ownerExists(msg.sender)
    returns (uint256 changeSignatureCountTransactionId)
    {
        require(newSignatureCount > 0);
        require(newSignatureCount <= _owners.length);
        changeSignatureCountTransactionId = createChangeSignatureCountTransaction(operationType, newSignatureCount);
        confirmChangeSignatureCount(changeSignatureCountTransactionId);
        return changeSignatureCountTransactionId;
    }

    function confirmChangeSignatureCount(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transactionId);
        executeChangeSignatureCount(transactionId);
    }

    function revokeChangeSignatureCountConfirmation(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transactionId);
    }

    function createChangeSignatureCountTransaction(uint8 operationType, uint newSignatureCount)
    private
    returns (uint256 changeSignatureCountTransactionId)
    {

        changeSignatureCountTransactionId = getTransactionCount(_operation);

        ChangeSignatureCountTransaction storage changeSignatureCountTransaction = _transactions[changeSignatureCountTransactionId];
        createTransaction(_operation, changeSignatureCountTransactionId);
        changeSignatureCountTransaction.operationType = operationType;
        changeSignatureCountTransaction.newSignatureCount = newSignatureCount;

        return changeSignatureCountTransactionId;
    }

    function executeChangeSignatureCount(uint256 transactionId)
    private
    ownerExists(msg.sender)
    transactionConfirmed(_operation, transactionId, msg.sender)
    transactionNotExecuted(_operation, transactionId)
    {
        if (isConfirmed(_operation, transactionId)) {
            ChangeSignatureCountTransaction storage changeSignatureCountTransaction = _transactions[transactionId];
            uint8 operationType = changeSignatureCountTransaction.operationType;
            uint newSignatureCount = changeSignatureCountTransaction.newSignatureCount;
            if (operationType != ALL) {
                _signatureCount[operationType] = newSignatureCount;
            } else {
                for (uint8 i = 0; i < _operations.length; i++) {
                    _signatureCount[_operations[i]] = newSignatureCount;
                }
            }

            executeTransaction(_operation, transactionId);
        }
    }

    function getChangeSignatureCountTrans(uint256 transId) public view
    returns(ChangeSignatureCountTransaction memory, Transaction memory)
    {
        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Multisignable.sol";

contract MultisigTransferable is Multisignable {

    uint8 private _operation;

    struct TransferTransaction {
        address recipient;
        uint256 amount;
    }

    mapping (uint256 => TransferTransaction) private _transferTransactions;

    function __MultisigTransferable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigTransferable_init_unchained(operation, signCount);
    }

    function __MultisigTransferable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestTransfer(address tokenAddress, address recipient, uint256 amount) external
    ownerExists(msg.sender)
    returns (uint256 transferTransactionId)
    {
        transferTransactionId = createTransferTransaction(tokenAddress, recipient, amount);
        confirmTransfer(transferTransactionId);
        return transferTransactionId;
    }

    function confirmTransfer(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transactionId);
        executeTransfer(transactionId);
    }

    function revokeTransferConfirmation(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transactionId);
    }

    function createTransferTransaction(address tokenAddress, address recipient, uint256 amount)
    private
    returns (uint256 transferTransactionId)
    {

        transferTransactionId = getTransactionCount(_operation);

        TransferTransaction storage transferTransaction = _transferTransactions[transferTransactionId];
        createTransaction(_operation, tokenAddress, transferTransactionId);
        transferTransaction.recipient = recipient;
        transferTransaction.amount = amount;

        return transferTransactionId;
    }

    function executeTransfer(uint256 transactionId)
    private
    ownerExists(msg.sender)
    {
        if (isConfirmed(_operation, transactionId)) {
            TransferTransaction storage transferTransaction = _transferTransactions[transactionId];

            bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", transferTransaction.recipient, transferTransaction.amount);
            executeTransaction(_operation, transactionId, payload);
        }
    }

    function getTransferTrans(uint256 transId) public view
    returns(TransferTransaction memory, Transaction memory)
    {
        return (_transferTransactions[transId], getTrans(_operation, transId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Multisignable.sol";

contract MultisigTransferOwnership is Multisignable, OwnableUpgradeable {

    uint8 private _operation;

    struct TransferOwnershipTransaction {
        address newOwnerAddress;
    }

    mapping (uint256 => TransferOwnershipTransaction) private _transactions;

    function __MultisigTransferOwnership_init(uint8 operation, uint signCount, address owner) internal onlyInitializing {
        __MultisigTransferOwnership_init_unchained(operation, signCount, owner);
    }

    function __MultisigTransferOwnership_init_unchained(uint8 operation, uint signCount, address owner) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _transferOwnership(owner);
        _operations.push(operation);
    }

    function requestTransferOwnership(address newOwnerAddress) external
    ownerExists(msg.sender)
    addressNotNull(newOwnerAddress)
    returns (uint256 transferOwnershipTransactionId)
    {
        transferOwnershipTransactionId = createTransferOwnershipTransaction(newOwnerAddress);
        confirmTransferOwnership(transferOwnershipTransactionId);
        return transferOwnershipTransactionId;
    }

    function confirmTransferOwnership(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transactionId);
        executeTransferOwnership(transactionId);
    }

    function revokeTransferOwnershipConfirmation(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transactionId);
    }

    function createTransferOwnershipTransaction(address newOwnerAddress)
    private
    returns (uint256 transferOwnershipTransactionId)
    {

        transferOwnershipTransactionId = getTransactionCount(_operation);

        TransferOwnershipTransaction storage transferOwnershipTransaction = _transactions[transferOwnershipTransactionId];
        createTransaction(_operation, transferOwnershipTransactionId);
        transferOwnershipTransaction.newOwnerAddress = newOwnerAddress;

        return transferOwnershipTransactionId;
    }

    function executeTransferOwnership(uint256 transactionId)
    private
    ownerExists(msg.sender)
    transactionConfirmed(_operation, transactionId, msg.sender)
    transactionNotExecuted(_operation, transactionId)
    {
        if (isConfirmed(_operation, transactionId)) {
            TransferOwnershipTransaction storage transferOwnershipTransaction = _transactions[transactionId];
            address newOwnerAddress = transferOwnershipTransaction.newOwnerAddress;
            require(newOwnerAddress != address(0));

            _transferOwnership(newOwnerAddress);
            executeTransaction(_operation, transactionId);
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual override {
        require(_isInitializing() || _isLastConfirmed(_operation), "Ownable: should be confirmed or in initializing");
        OwnableUpgradeable._transferOwnership(newOwner);
    }

    function getTransferOwnershipTrans(uint256 transId) public view
    returns(TransferOwnershipTransaction memory, Transaction memory)
    {
        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Multisignable.sol";

contract MultisigUpgradeable is Multisignable {

    uint8 private _operation;

    struct UpgradeTransaction {
        address newImplementationAddress;
    }

    mapping (uint256 => UpgradeTransaction) private _transactions;

    function __MultisigUpgradeable_init(uint8 operation, uint signCount) internal onlyInitializing {
        __MultisigUpgradeable_init_unchained(operation, signCount);
    }

    function __MultisigUpgradeable_init_unchained(uint8 operation, uint signCount) internal onlyInitializing {
        _operation = operation;
        _signatureCount[operation] = signCount;
        _operations.push(operation);
    }

    function requestUpgrade(address newImplementationAddress) external
    ownerExists(msg.sender)
    addressNotNull(newImplementationAddress)
    returns (uint256 upgradeTransactionId)
    {
        upgradeTransactionId = createUpgradeTransaction(newImplementationAddress);
        confirmUpgrade(upgradeTransactionId);
        return upgradeTransactionId;
    }

    function confirmUpgrade(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        confirmTransaction(_operation, transactionId);
        executeUpgrade(transactionId);
    }

    function revokeUpgradeConfirmation(uint256 transactionId)
    public
    ownerExists(msg.sender)
    {
        revokeTransactionConfirmation(_operation, transactionId);
    }

    function createUpgradeTransaction(address newImplementationAddress)
    private
    returns (uint256 upgradeTransactionId)
    {

        upgradeTransactionId = getTransactionCount(_operation);

        UpgradeTransaction storage upgradeTransaction = _transactions[upgradeTransactionId];
        createTransaction(_operation, upgradeTransactionId);
        upgradeTransaction.newImplementationAddress = newImplementationAddress;

        return upgradeTransactionId;
    }

    function executeUpgrade(uint256 transactionId)
    private
    ownerExists(msg.sender)
    transactionConfirmed(_operation, transactionId, msg.sender)
    transactionNotExecuted(_operation, transactionId)
    {
        if (isConfirmed(_operation, transactionId)) {
            UpgradeTransaction storage upgradeTransaction = _transactions[transactionId];
            address newImplementationAddress = upgradeTransaction.newImplementationAddress;
            require(newImplementationAddress != address(0));
            UUPSUpgradeable(address(this)).upgradeTo(newImplementationAddress);
            executeTransaction(_operation, transactionId);
        }
    }

    function getUpgradeTrans(uint256 transId) public view
        returns(UpgradeTransaction memory, Transaction memory){

        return (_transactions[transId], getTrans(_operation, transId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./MultisigClientAccountBeacon.sol";
import "./MultisigEmissionable.sol";
import "./MultisigTransferable.sol";
import "./MultisigPausable.sol";
import "./MultisigFreezable.sol";
import "./MultisigTransferOwnership.sol";
import "./MultisigUpgradeable.sol";
import "./MultisigOwnersManageable.sol";
import "./MultisigSignatureCountManageable.sol";
import "./MultisigContractUpgradeable.sol";

contract TreasureAccount is
    MultisigClientAccountBeacon,
    MultisigEmissionable,
    MultisigTransferable,
    MultisigPausable,
    MultisigFreezable,
    MultisigUpgradeable,
    MultisigOwnersManageable,
    MultisigSignatureCountManageable,
    MultisigContractUpgradeable,
    UUPSUpgradeable {

    enum Operation {
        MANAGE_EMISSION,
        TRANSFER,
        MANAGE_PAUSE_UNPAUSE,
        MANAGE_FREEZE_UNFREEZE_WIPE_ACCOUNT,
        UPGRADE,
        MANAGE_MULTISIG_ADDRESS,
        CHANGE_CONFIRMATION_COUNT,
        UPGRADE_CLIENT_ACCOUNT_BEACON,
        UPGRADE_CONTRACT
    }

    function initialize(
        address[] calldata owners,
        uint signatureCount,
        address clientAccountLogic
    ) initializer public {
        __Multisignable_init(owners);
        __MultisigClientAccountBeacon_init(uint8(Operation.UPGRADE_CLIENT_ACCOUNT_BEACON), clientAccountLogic, signatureCount);
        __MultisigEmissionable_init(uint8(Operation.MANAGE_EMISSION), signatureCount);
        __MultisigTransferable_init(uint8(Operation.TRANSFER), signatureCount);
        __MultisigPausable_init(uint8(Operation.MANAGE_PAUSE_UNPAUSE), signatureCount);
        __MultisigFreezable_init(uint8(Operation.MANAGE_FREEZE_UNFREEZE_WIPE_ACCOUNT), signatureCount);
        __MultisigUpgradeable_init(uint8(Operation.UPGRADE), signatureCount);
        __MultisigOwnersManageable_init(uint8(Operation.MANAGE_MULTISIG_ADDRESS), signatureCount);
        __MultisigSignatureCountManageable_init(uint8(Operation.CHANGE_CONFIRMATION_COUNT), signatureCount);
        __MultisigContractUpgradeable_init(uint8(Operation.UPGRADE_CONTRACT), signatureCount);
    }

    receive() external payable virtual {}

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address /*newImplementation*/)
    internal
    view
    checkOperationConfirmed(uint8(Operation.UPGRADE))
    override
    {
        require(address(this) == msg.sender);
    }

    uint256[45] private __gap;

}