// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

error WeReallyNeedTheOwnerToDoThisPlease();

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
        if(owner() != _msgSender()) revert WeReallyNeedTheOwnerToDoThisPlease();
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.12;

import "./DNA_Storage.sol";
import "./DNA_Utils.sol";

// Open Zeppelin libraries for controlling upgradability and access.
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


// common errors
error AhemThisTokenDoesntExist();
error WeDontCheckBalancesForTheZeroAddressHere();

// mint errors
error SorryFriendContractsCantMint();
error LoveTheExcitementButMintIsNotActive();
error LoveTheSupportButCantMintThatMany();
error ReallyWantToMintForYouButNotTheRightFunds();
error WeWouldBreakIfWeMintedThisMany();
error WeKnowYoureTheOwnerAndAllButYouCantMintThatMany();
error AhManWeAreAllOutOfFreeTokens();
error LoveTheSupportButCantMintThatManyFreeTokens();
error WeDontMintToTheZeroAddressDuh();

// approval errors
error WeNeedTheTokenOwnerToCallThis();
error OwnersDontNeedApprovalDuh();
error StopTryingToApproveIfYoureNotTheOwnerOrApproved();
error HeyFriendCantApproveToCaller();
error UnableToSetApproverForTokenOnPaymentPlan();

// transfer errors
error TheFromAddressNeedsToBeTheOwnerPlease();
error WhyAreYouTryingToTransferTheTokenIfYoureNotTheOwnerOrApproved();
error PleaseDontTransferToTheZeroAddressThanks();
error TransferToNonERC721ReceiverImplementer();
error UnableToTransferTokenOnPaymentPlan();
error UmmThisIsAwkwardThatContractCantReceiveERC721Tokens();
error WellThisIsWeirdYoureTransferringToYourself();

// payment plan errors
error ThisTokenIsAlreadyPaidOff();
error UnableToProcessRefund();

// delegation errors
error ThatAddressIsAlreadyDelegatedHomie();
error JustNeedToPayOffTheTokenToDelegate();

// fund errors
error DangYouDontHaveEnoughEthDude();
error IDKWhatHappenedCoudlntSendTheEther();

// trouble maker errors
error WhoaWhoaWhoaNoReEnteringFunctionsPlease();



contract DNACommon is Initializable, UUPSUpgradeable, OwnableUpgradeable, DNAStorageV1
{

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}



    /*
        ███████ ██    ██ ███████ ███    ██ ████████ ███████ 
        ██      ██    ██ ██      ████   ██    ██    ██      
        █████   ██    ██ █████   ██ ██  ██    ██    ███████ 
        ██       ██  ██  ██      ██  ██ ██    ██         ██ 
        ███████   ████   ███████ ██   ████    ██    ███████
    */

    // ERC721 events

    // emitted when 'tokenId' is transferred
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // emitted when 'owner' approves 'address' to manage 'tokenId'
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // emitted when 'owner' approves 'operator' to manage all of its DNA tokens
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    /*
        ███    ███  ██████  ██████  ██ ███████ ██ ███████ ██████  ███████ 
        ████  ████ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██ ██      
        ██ ████ ██ ██    ██ ██   ██ ██ █████   ██ █████   ██████  ███████ 
        ██  ██  ██ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██      ██ 
        ██      ██  ██████  ██████  ██ ██      ██ ███████ ██   ██ ███████ 
    */

    // re-entrancy guard
    function _nonReentrant() private view
    {
        if(ReentrantStatus == Entered) revert WhoaWhoaWhoaNoReEnteringFunctionsPlease();
    }
    modifier nonReentrant()
    {
        _nonReentrant();
        ReentrantStatus = Entered;
        _;
        ReentrantStatus = NotEntered;
    }

    // token must exist modifier
    function _tokenMustExist(uint256 _tokenId) private view
    {
        if(_tokenId < StartTokenIndex || _tokenId >= CurrentTokenIndex) revert AhemThisTokenDoesntExist();
    }
    modifier tokenMustExist(uint256 _tokenID)
    {
        _tokenMustExist(_tokenID);
        _;
    }
    


    /*
        ██    ██ ██████  ██████   █████  ████████ ███████ ███████ 
        ██    ██ ██   ██ ██   ██ ██   ██    ██    ██      ██      
        ██    ██ ██████  ██   ██ ███████    ██    █████   ███████ 
        ██    ██ ██      ██   ██ ██   ██    ██    ██           ██ 
         ██████  ██      ██████  ██   ██    ██    ███████ ███████ 
    */

    function updateProjectDetails(string memory _name, string memory _symbol) external onlyOwner
    {
        ProjectName = _name;
        ProjectSymbol = _symbol;
    }

    function updateMothershipCoordinates(string memory _newMothershipCoordinates) external onlyOwner
    {
        MothershipCoordinates = _newMothershipCoordinates;
    }

    function updateTeamAddy(address _newAddress) external onlyOwner
    {
        TeamAddy = _newAddress;
    }

    function releaseDaEth() external onlyOwner
    {

        if(address(this).balance == 0) revert DangYouDontHaveEnoughEthDude();
        (bool success, ) = TeamAddy.call{value: address(this).balance}("");
        if(!success) revert IDKWhatHappenedCoudlntSendTheEther();
    }
    


    /*
        ██████  ██████   ██████       ██ ███████  ██████ ████████ 
        ██   ██ ██   ██ ██    ██      ██ ██      ██         ██    
        ██████  ██████  ██    ██      ██ █████   ██         ██    
        ██      ██   ██ ██    ██ ██   ██ ██      ██         ██    
        ██      ██   ██  ██████   █████  ███████  ██████    ██    
                                                                
                                                                
        ██ ███    ██ ███████  ██████                              
        ██ ████   ██ ██      ██    ██                             
        ██ ██ ██  ██ █████   ██    ██                             
        ██ ██  ██ ██ ██      ██    ██                             
        ██ ██   ████ ██       ██████
    */

    function totalSupply() public view returns(uint256)
    {
        unchecked
        {
            return CurrentTokenIndex-1;    
        }   
    }

    function getMintDetails() public view returns(uint256[9] memory)
    {
        // 0 - AlienPrice
        // 1 - PaymentPlanPrice
        // 2 - PaymentPlanTime
        // 3 - MaxMintPerAddress
        // 4 - MaxFreePerAddress
        // 5 - CurrentTokenIndex
        // 6 - TotalMinted
        // 7 - TotalMintedFree
        // 8 - ReserveUsed
        return [AlienPrice, PaymentPlanPrice, PaymentPlanTime, MaxMintPerAddress, MaxFreePerAddress, CurrentTokenIndex, TotalMinted, TotalMintedFree, ReserveUsed];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./DNA_Token.sol";

contract DNAMint is DNAToken
{

    using DNAUtils for address;
    
    /*
    
        ███    ███ ██ ███    ██ ████████ 
        ████  ████ ██ ████   ██    ██    
        ██ ████ ██ ██ ██ ██  ██    ██    
        ██  ██  ██ ██ ██  ██ ██    ██    
        ██      ██ ██ ██   ████    ██    
    
    */

    // free mint function, not payable
    function freeMintAlien(uint256 _quantity) external nonReentrant
    {
        // check for active mint first
        if(!IsFreeMintActive) revert LoveTheExcitementButMintIsNotActive();

        // contracts cant mint 😢
        if ((msg.sender).isContract()) revert SorryFriendContractsCantMint();

        // check if able to mint quantity
        if (CurrentTokenIndex > MaxFreeMints) revert AhManWeAreAllOutOfFreeTokens();

        // check address not minting too many
        if (AddressDataMap[msg.sender].numMinted + 1 > MaxFreePerAddress) revert LoveTheSupportButCantMintThatManyFreeTokens();

        _freeMint(msg.sender, _quantity);
    }

    // internal mint function
    function _freeMint(address _to, uint256 _quantity) private
    {
        // check if _to is zero address
        if(_to == address(0)) revert WeDontMintToTheZeroAddressDuh();
        
        unchecked
        {
            // update address data
            AddressDataMap[_to].numMinted += uint16(_quantity);
            AddressDataMap[_to].numMintedFree += uint16(_quantity);
            AddressDataMap[_to].balance += uint16(_quantity);

            TokenData storage thisTokenData = TokenDataMap[CurrentTokenIndex];
            // update token data
            thisTokenData.tokenOwner = _to;
            thisTokenData.emergenceDate = uint64(block.timestamp);
            thisTokenData.ownedSince = uint64(block.timestamp);
            // emit transfer events
            uint256 end = CurrentTokenIndex + _quantity;
            while(CurrentTokenIndex < end)
            {   
                // emit transfer event
                emit Transfer(address(0), _to, CurrentTokenIndex);
                // update token counter
                CurrentTokenIndex++;
            }
            // update total counts
            TotalMinted += _quantity;
            TotalMintedFree += _quantity;
        }
    }

    // mint function
    function publicMintAlien(uint256 _quantity, bool _paymentPlan) external payable nonReentrant
    {
        // check for active mint first
        if(!IsPublicMintActive) revert LoveTheExcitementButMintIsNotActive();

        // contracts cant mint 😢
        if ((msg.sender).isContract()) revert SorryFriendContractsCantMint();

        // check if able to mint quantity
        if (TotalMinted + (MaxReserve-ReserveUsed) + _quantity > CollectionSize) revert WeWouldBreakIfWeMintedThisMany();        

        // check address not minting too many
        if (AddressDataMap[msg.sender].numMinted + _quantity > MaxMintPerAddress) revert LoveTheSupportButCantMintThatMany();

        unchecked
        {   
            // calculate cost
            
            uint256 tokenPrice;

            // determine which price to use
            if(_paymentPlan)
            {
                tokenPrice = PaymentPlanPrice;
            } else
            {
                tokenPrice = AlienPrice;
            }

            uint256 totalCost = tokenPrice*_quantity;

            // check if value sent is correct
            if (totalCost != msg.value) revert ReallyWantToMintForYouButNotTheRightFunds();

            // MINT THEM THANGS!
            _mint(msg.sender, _quantity, _paymentPlan);
        }
    }

    // internal mint function
    function _mint(address _to, uint256 _quantity, bool _paymentPlan) private
    {
        // check if _to is zero address
        if(_to == address(0)) revert WeDontMintToTheZeroAddressDuh();

        unchecked
        {
            // update address data
            AddressDataMap[_to].numMinted += uint16(_quantity);
            AddressDataMap[_to].balance += uint16(_quantity);

            // get start and end indices
            uint256 curTokenIndex = CurrentTokenIndex;
            uint256 end = curTokenIndex + _quantity;
            
            // update owner and timestamp
            TokenDataMap[curTokenIndex].tokenOwner = _to;
            TokenDataMap[curTokenIndex].ownedSince = uint64(block.timestamp);

            // update mint counts
            TotalMinted += _quantity;

            // mint payment plan tokens
            if(_paymentPlan)
            {
                // emit transfer events for logging
                while(curTokenIndex < end)
                {                    
                    // update payment map
                    PaymentDataMap[curTokenIndex] = AlienPrice - PaymentPlanPrice;
                    // emit transfer event
                    emit Transfer(address(0), _to, curTokenIndex++);
                }
            } else // mint all fully purchased tokens
            {
                // emit transfer events for logging
                while (curTokenIndex < end)
                {
                    // update fully paid
                    emit Transfer(address(0), _to, curTokenIndex++);
                }
            }

            // update current index
            CurrentTokenIndex = curTokenIndex;
        }
    }

    // make payment for token
    function makePayment(uint256 _tokenId) external payable
    {
        // get token data
        TokenData memory tokenData = getTokenData(_tokenId);
        // check if owner
        if(msg.sender != tokenData.tokenOwner) revert WeNeedTheTokenOwnerToCallThis();
        // check if paid off already
        if(PaymentDataMap[_tokenId] == 0) revert ThisTokenIsAlreadyPaidOff();
        // update remaining amount
        uint256 remainingBalance = PaymentDataMap[_tokenId];
        // process payments
        unchecked
        {
            // overpayment
            if(msg.value > remainingBalance)
            {
                // get refund amount
                uint256 refund = msg.value - PaymentDataMap[_tokenId];
                // update remaining value
                PaymentDataMap[_tokenId] = 0;
                // send refund
                bool sent = payable(msg.sender).send(refund);
                // revert if unsuccessful
                if(!sent) revert UnableToProcessRefund();

            } else if(msg.value == remainingBalance) // exact payment
            {
                // update remaining value
                PaymentDataMap[_tokenId] = 0;

            } else // under payment
            {
                PaymentDataMap[_tokenId] = remainingBalance - msg.value;
            }
        }
    }



    /*

        ████████ ███████  █████  ███    ███              
           ██    ██      ██   ██ ████  ████              
           ██    █████   ███████ ██ ████ ██              
           ██    ██      ██   ██ ██  ██  ██              
           ██    ███████ ██   ██ ██      ██              
                                                                                                               
        ███████ ██   ██ ██ ███████ ███    ██ ██ ████████ 
        ██      ██   ██ ██    ███  ████   ██ ██    ██    
        ███████ ███████ ██   ███   ██ ██  ██ ██    ██    
             ██ ██   ██ ██  ███    ██  ██ ██ ██    ██    
        ███████ ██   ██ ██ ███████ ██   ████ ██    ██

    */
    
    // toggle free mint
    function toggleFreeMintStatus() external onlyOwner
    {
        IsFreeMintActive = !IsFreeMintActive;
    }

    // toggle public mint
    function togglePublicMintStatus() external onlyOwner
    {
        IsPublicMintActive = !IsPublicMintActive;
    }

    // update mint details
    function updateMintDetails(uint256 _newMintPrice, uint256 _newPlanPrice, uint256 _newMaxMint, uint256 _newMaxFree) external onlyOwner
    {
        AlienPrice = _newMintPrice;
        PaymentPlanPrice = _newPlanPrice;
        MaxMintPerAddress = _newMaxMint;
        MaxFreePerAddress = _newMaxFree;
    }

    // mint for team members
    function teamMemberMint(uint256 _quantity, address _to) external onlyOwner nonReentrant
    {
        // check if quantity can be minted
        if(_quantity > MaxReserve - ReserveUsed) revert WeKnowYoureTheOwnerAndAllButYouCantMintThatMany();

        // update reserve count
        ReserveUsed += _quantity;

        // total minted updated here
        _mint(_to, _quantity, false);
    }

    // reclaim any unpaid tokens
    function reclaimToken(uint256[] memory _tokenIds) external onlyOwner
    {
        unchecked
        {
            for(uint256 i=0; i<_tokenIds.length; ++i)
            {  
                uint256 tokenId = _tokenIds[i];
                TokenData memory tokenData = getTokenData(tokenId);

                // check if fully paid
                if(PaymentDataMap[tokenId] > 0)
                {
                    // check if minted greater than 90 days
                    if(block.timestamp - tokenData.ownedSince > PaymentPlanTime)
                    {
                        // reclaim
                        
                        // update balances
                        AddressDataMap[tokenData.tokenOwner].balance -= 1;
                        AddressDataMap[owner()].balance += 1;

                        TokenData storage thisTokenData = TokenDataMap[tokenId];

                        // update emergence date if owner is address(0)
                        if(thisTokenData.tokenOwner == address(0))
                        {
                            thisTokenData.emergenceDate = tokenData.emergenceDate;
                        }

                        // udpate ownership, timestamp, and timesTransferred
                        thisTokenData.tokenOwner = owner();
                        thisTokenData.ownedSince = uint64(block.timestamp);
                        thisTokenData.teleportationCount = 0;

                        // if _tokenId+1 owner is not set, set originator as owner
                        uint256 nextTokenId = tokenId + 1;
                        
                        // check if next token exists
                        bool nextTokenExists = nextTokenId < CurrentTokenIndex;
                        TokenData storage nextTokenData = TokenDataMap[nextTokenId];

                        // if _tokenId+1 owner is not set and token exists, set originator as owner
                        if (nextTokenData.tokenOwner == address(0) && nextTokenExists)
                        {
                            nextTokenData.tokenOwner = tokenData.tokenOwner;
                            nextTokenData.ownedSince = tokenData.ownedSince;
                            nextTokenData.emergenceDate = tokenData.emergenceDate;
                        }

                        // refund any cost

                        // get refund amount
                        uint256 refund = AlienPrice - PaymentDataMap[tokenId];

                        // update remaining value
                        PaymentDataMap[tokenId] = 0;
                        
                        // send refund
                        bool sent = payable(tokenData.tokenOwner).send(refund);
                        
                        // revert if unsuccessful
                        if(!sent) revert UnableToProcessRefund();
                    

                        // emit transfer event
                        emit Transfer(tokenData.tokenOwner, owner(), tokenId);                  

                    }
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract DNAStorageV1
{
    // token data struct
    struct TokenData
    {
        address tokenOwner;         // owner of token
        address delegate;           // delegate of token
        uint64 delegatedSince;      // date of last delegation
        uint64 emergenceDate;       // date minted
        uint64 teleportationCount;  // times transferred
        uint64 ownedSince;          // time owned since last transfer
    }

    // map from token to token data
    mapping(uint256 => TokenData) internal TokenDataMap;

    // address data struct
    struct AddressData
    {
        uint16 numMinted;           // number minted
        uint16 numMintedFree;       // number minted free
        uint16 balance;             // number of tokens held
        uint16 numUsers;            // number of tokens loaned to users
        uint16 numDelegated;        // number of tokens delegated
    }

    // map from address to address data
    mapping(address => AddressData) internal AddressDataMap;

    // token id to approved address
    mapping(uint256 => address) internal TokenApprovals;
    // owner to operator approvals
    mapping(address => mapping(address => bool)) internal OperatorApprovals;

    // map from token to payment plan data
    mapping(uint256 => uint256) internal PaymentDataMap;
    
    // reentrancy constants
    uint256 internal constant NotEntered = 1;
    uint256 internal constant Entered = 2;
    uint256 internal ReentrantStatus;       // = NotEntered;

    // collection constants
    uint256 internal constant CollectionSize = 10051;
    uint256 internal constant StartTokenIndex = 1;
    
    // mint constants
    uint256 internal constant MaxFreeMints = 551;
    uint256 internal constant MaxReserve = 500;
    
    // mint details
    uint256 internal AlienPrice;            // = 0.051 ether;    
    uint256 internal PaymentPlanPrice;      // = 0.01 ether;
    uint256 internal PaymentPlanTime;       // = 7776000;
    uint256 internal MaxMintPerAddress;     // = 10;
    uint256 internal MaxFreePerAddress;     // = 1;
    uint256 internal CurrentTokenIndex;     // = 1;
    uint256 internal TotalMintedFree;
    uint256 internal TotalMinted;
    uint256 internal ReserveUsed;
    bool public IsFreeMintActive;
    bool public IsPublicMintActive;
    address internal TeamAddy;
    
    // project info
    string internal ProjectName;            // Definitely Not Aliens
    string internal ProjectSymbol;          // DNA
    string internal MothershipCoordinates;  // idk my bff Jill
    
    // gap for contract storage (JUST in case)
    uint256[100] private _impGap;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./DNA_Common.sol";

contract DNAToken is DNACommon
{

    using DNAUtils for address;
    using DNAUtils for uint256;



    /*

        ███████ ██████   ██████  ██  ██████  ███████ 
        ██      ██   ██ ██      ███ ██       ██      
        █████   ██████  ██       ██ ███████  ███████ 
        ██      ██   ██ ██       ██ ██    ██      ██ 
        ███████ ██   ██  ██████  ██  ██████  ███████ 

    */

    // see IERC165 supportsInterface
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool)
    {
        return _interfaceId == 0x80ac58cd   ||  // erc721
                _interfaceId == 0x5b5e139f  ||  // erc721-metadata
                _interfaceId == 0x01ffc9a7;     // erc165
    }



    /*

        ███████ ██████   ██████ ███████ ██████   ██ 
        ██      ██   ██ ██           ██      ██ ███ 
        █████   ██████  ██          ██   █████   ██ 
        ██      ██   ██ ██         ██   ██       ██ 
        ███████ ██   ██  ██████    ██   ███████  ██                                            
                                                    
    */

    // see IERC721 balanceOf
    function balanceOf(address _address) public view returns (uint256)
    {
        // check if query is for address(0)
        if(_address == address(0)) revert WeDontCheckBalancesForTheZeroAddressHere();
        // return the balance
        return AddressDataMap[_address].balance;
    }

    // see IERC721 ownerOf
    function ownerOf(uint256 _tokenId) public view returns (address)
    {
        // using getTokenData since this is a batch mint, some TokenToData[_tokenId].tokenOwner are address(0)
        TokenData memory tokenData = getTokenData(_tokenId);
        return tokenData.delegate == address(0) ? tokenData.tokenOwner : tokenData.delegate;
    }

    // see IERC721 safeTransferFrom
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public
    {
        // transfer token first so changes are updated
        _transfer(_from, _to, _tokenId);
        
        // if _to is a contract, ensure it implements IERC721Receiver-onERC721Received
        if (_to.isContract() && !_checkContractOnERC721Received(_from, _to, _tokenId, _data)) 
        {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    // see IERC721 safeTransferFrom
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public
    {
        // transfer token
        safeTransferFrom(_from, _to, _tokenId, '');
    }

    // see IERC721 transferFrom
    function transferFrom(address _from, address _to, uint256 _tokenId) public
    {
        // transfer token
        _transfer(_from, _to, _tokenId);
    }

    // see IERC721 approve
    function approve(address _to, uint256 _tokenId) public
    {
        // get token owner
        address tokenOwner = getTokenData(_tokenId).tokenOwner;
        
        // check if trying to approve owner
        if (_to == tokenOwner) revert OwnersDontNeedApprovalDuh();

        // ensure owner or operator is calling function
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender)) revert StopTryingToApproveIfYoureNotTheOwnerOrApproved();

        // check if token is paid off
        if(PaymentDataMap[_tokenId] > 0) revert UnableToSetApproverForTokenOnPaymentPlan();

        // set approval
        _approve(tokenOwner, _to, _tokenId);
    }

    // see IERC721 setApprovalForAll
    function setApprovalForAll(address _operator, bool _approved) public
    {
        _setApprovalForAll(msg.sender, _operator, _approved);
    }

    // see IERC721 getApproved
    function getApproved(uint256 _tokenId) public view tokenMustExist(_tokenId) returns (address)
    {
        // return approver of _tokenId
        return TokenApprovals[_tokenId];
    }

    // see IERC721 isApprovedForAll
    function isApprovedForAll(address _tokenOwner, address _operator) public view returns (bool)
    {
        // return _operator approval status of _tokenOwner tokens
        return OperatorApprovals[_tokenOwner][_operator];
    }



    /*

        ███████ ██████   ██████ ███████ ██████   ██       ███    ███ ███████ ████████  █████  ██████   █████  ████████  █████  
        ██      ██   ██ ██           ██      ██ ███       ████  ████ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██ 
        █████   ██████  ██          ██   █████   ██ █████ ██ ████ ██ █████      ██    ███████ ██   ██ ███████    ██    ███████ 
        ██      ██   ██ ██         ██   ██       ██       ██  ██  ██ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██ 
        ███████ ██   ██  ██████    ██   ███████  ██       ██      ██ ███████    ██    ██   ██ ██████  ██   ██    ██    ██   ██ 
                                                                                                                                                                                                                                                          
    */

    // get project name
    function name() public view returns (string memory)
    {
        return ProjectName;
    }
    
    // get project symbol
    function symbol() public view returns (string memory)
    {
        return ProjectSymbol;
    }

    // get token URI
    function tokenURI(uint256 _tokenId) public view tokenMustExist(_tokenId) returns (string memory)
    {
        // return base uri with token index
        return string.concat(MothershipCoordinates, _tokenId.toString());
        
    }



    /*
         ██████  ███████ ███    ██ ███████ ██████   █████  ██      
        ██       ██      ████   ██ ██      ██   ██ ██   ██ ██      
        ██   ███ █████   ██ ██  ██ █████   ██████  ███████ ██      
        ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██ ██      
         ██████  ███████ ██   ████ ███████ ██   ██ ██   ██ ███████ 
    */

    // function to get token data
    function getTokenData(uint256 _tokenId) public view tokenMustExist(_tokenId) returns (TokenData memory)
    {
        // get token data
        TokenData memory tokenData = TokenDataMap[_tokenId];
        // if token owner is not address(0), return the data
        if (tokenData.tokenOwner != address(0))
        {
            return tokenData;
        }

        // create temporary token id
        uint256 tempTokenId = _tokenId;
        // there will always be an owner before a 0 address owner, avoiding underflow
        for(;;)
        {
            // using unchecked to reduce gas
            unchecked
            {
                // decrement token index
                tempTokenId--;
            }
            
            // when owner found, update owner and ownedSince properties
            if (TokenDataMap[tempTokenId].tokenOwner != address(0))
            {
                TokenData memory parentTokenData = TokenDataMap[tempTokenId];
                // update owner, emergence date (mint date), and owned time from parent
                tokenData.tokenOwner = parentTokenData.tokenOwner;
                tokenData.emergenceDate = parentTokenData.emergenceDate;
                tokenData.ownedSince = parentTokenData.ownedSince;
                return tokenData;
            }
        }
        
        // catch all to avoid no exit warning
        revert AhemThisTokenDoesntExist();
    }

    // function to get address data
    function getAddressData(address _address) public view returns(AddressData memory)
    {
        return AddressDataMap[_address];
    }

    // function to get payment data
    function getPaymentData(uint256 _tokenId) external view returns(uint256)
    {
        return PaymentDataMap[_tokenId];
    }

    // function to delegate token usage to another address
    function delegateToken(uint256 _tokenId, address _to) external
    {
        // get token data (this checks if token exists)
        TokenData memory tokenData = getTokenData(_tokenId);

        // check if msg.sender is owner
        if(msg.sender != tokenData.tokenOwner) revert WeNeedTheTokenOwnerToCallThis();
        
        // check if delegating to same token
        if(tokenData.delegate == _to) revert ThatAddressIsAlreadyDelegatedHomie();

        // check if token is paid off
        if(PaymentDataMap[_tokenId] > 0) revert JustNeedToPayOffTheTokenToDelegate();
        
        // update delegated timestamp
        TokenDataMap[_tokenId].delegatedSince = uint64(block.timestamp);
        
        // emit transfer evern for marketplaces
        if(_to == address(0))
        {
            emit Transfer(tokenData.delegate, tokenData.tokenOwner, _tokenId);
        } else
        {
            if(tokenData.delegate == address(0))
            {
                emit Transfer(tokenData.tokenOwner, _to, _tokenId);
            } else
            {
                emit Transfer(tokenData.delegate, _to, _tokenId);
            }
        }
        
        // update delegate
        TokenDataMap[_tokenId].delegate = _to;        
    }



    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████
    */

    // internal transfer function
    function _transfer(address _from, address _to, uint256 _tokenId) private
    {
        // get token data
        TokenData memory tokenData = getTokenData(_tokenId);
        
        // check _from is owner
        if (_from != tokenData.tokenOwner) revert TheFromAddressNeedsToBeTheOwnerPlease();
        
        // check for proper transfer approval
        bool isApprovedOrOwner = (msg.sender == _from ||
            isApprovedForAll(_from, msg.sender) ||
            getApproved(_tokenId) == msg.sender);
        
        // revert if not approved
        if (!isApprovedOrOwner) revert WhyAreYouTryingToTransferTheTokenIfYoureNotTheOwnerOrApproved();
        
        // check if token is paid off
        if(PaymentDataMap[_tokenId] > 0) revert UnableToTransferTokenOnPaymentPlan();

        // check if transferring to self
        if(_from == _to) revert WellThisIsWeirdYoureTransferringToYourself();

        // revert if transferring to address(0)
        if (_to == address(0)) revert PleaseDontTransferToTheZeroAddressThanks();

        // clear approvals
        _approve(_from, address(0), _tokenId);

        // underflow not possible as ownership check above guarantees at least 1
        // overflow not possible as collection is capped and getTokenData() checks for existence
        unchecked
        {
            // update balances
            AddressDataMap[_from].balance -= 1;
            AddressDataMap[_to].balance += 1;

            TokenData storage thisTokenData = TokenDataMap[_tokenId];

            // update emergence date if owner is address(0)
            if(thisTokenData.tokenOwner == address(0))
            {
                thisTokenData.emergenceDate = tokenData.emergenceDate;
            }

            // udpate ownership, timestamp, and timesTransferred
            thisTokenData.tokenOwner = _to;
            thisTokenData.ownedSince = uint64(block.timestamp);
            thisTokenData.teleportationCount += 1;

            // reset delegate information
            if(tokenData.delegate != address(0))
            {
                // update token delegate
                thisTokenData.delegate = address(0);
                // update delegated since
                thisTokenData.delegatedSince = 0;
                // decrease owner delegated count
                AddressDataMap[_from].numDelegated -= 1;
            }

            // if _tokenId+1 owner is not set, set originator as owner
            uint256 nextTokenId = _tokenId + 1;
            
            // check if next token exists
            bool nextTokenExists = nextTokenId < CurrentTokenIndex;

            TokenData storage nextTokenData = TokenDataMap[nextTokenId];

            // if _tokenId+1 owner is not set and token exists, set originator as owner
            if (nextTokenData.tokenOwner == address(0) && nextTokenExists)
            {
                nextTokenData.tokenOwner = _from;
                nextTokenData.ownedSince = tokenData.ownedSince;
            }
        }        

        // emit transfer event
        emit Transfer(_from, _to, _tokenId);
    }

    // internal approve function
    function _approve(address _tokenOwner, address _to, uint256 _tokenId) private
    {
        TokenApprovals[_tokenId] = _to;
        emit Approval(_tokenOwner, _to, _tokenId);
    }

    // internal set approval for all function for operators
    function _setApprovalForAll(address _owner, address _operator, bool _approved) private
    {
        // check if trying to approve self
        if(_owner == _operator) revert HeyFriendCantApproveToCaller();

        // set operator approval
        OperatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }
    
    // internal receipt verification function *callback*
    function _checkContractOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool)
    {
        if (_to.code.length > 0)
        {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval)
            {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason)
            {
                if (reason.length == 0)
                {
                    revert UmmThisIsAwkwardThatContractCantReceiveERC721Tokens();
                } else
                {
                    /// @solidity memory-safe-assembly
                    assembly
                    {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else
        {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library DNAUtils
{
    // int functions
    function toString(uint256 _value) internal pure returns (string memory)
    {
        // check if 0
        if (_value == 0)
        {
            return "0";
        }
        // get number of digits
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0)
        {
            digits++;
            temp /= 10;
        }
        // create string
        bytes memory buffer = new bytes(digits);
        while (_value != 0)
        {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        // return string
        return string(buffer);
    }
    
    // address functions
    function isContract(address account) internal view returns (bool)
    {
        // check if contract by code length
        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./DNA_Mint.sol";

/*

        ██████  ███████ ███████ ██ ███    ██ ██ ████████ ███████ ██      ██    ██ 
        ██   ██ ██      ██      ██ ████   ██ ██    ██    ██      ██       ██  ██  
        ██   ██ █████   █████   ██ ██ ██  ██ ██    ██    █████   ██        ████   
        ██   ██ ██      ██      ██ ██  ██ ██ ██    ██    ██      ██         ██    
        ██████  ███████ ██      ██ ██   ████ ██    ██    ███████ ███████    ██    
                                                                                
                                                                                
        ███    ██  ██████  ████████                                               
        ████   ██ ██    ██    ██                                                  
        ██ ██  ██ ██    ██    ██                                                  
        ██  ██ ██ ██    ██    ██                                                  
        ██   ████  ██████     ██                                                  
                                                                                
                                                                                
         █████  ██      ██ ███████ ███    ██ ███████                              
        ██   ██ ██      ██ ██      ████   ██ ██                                   
        ███████ ██      ██ █████   ██ ██  ██ ███████                              
        ██   ██ ██      ██ ██      ██  ██ ██      ██                              
        ██   ██ ███████ ██ ███████ ██   ████ ███████                              

        vision: @0xJLevi
        art: @MrThursday
        code: @0xSomeGuy
*/

contract DefinitelyNotAliens is DNAMint
{
    function initialize() public initializer
    {
        AlienPrice = .051 ether;
        PaymentPlanPrice = .0051 ether;
        MaxMintPerAddress = 10;
        MaxFreePerAddress = 1;
        CurrentTokenIndex = 1;
        PaymentPlanTime = 7776000;
        ReentrantStatus = NotEntered;
        __Ownable_init();
    }
}