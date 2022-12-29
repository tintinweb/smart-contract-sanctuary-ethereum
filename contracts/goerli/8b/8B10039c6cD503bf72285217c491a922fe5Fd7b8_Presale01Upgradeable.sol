/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// File: Library/StorageSlotUpgradeable.sol


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

// File: Interface/IBeaconUpgradeable.sol


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

// File: Interface/draft-IERC1822Upgradeable.sol


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

// File: Library/AddressUpgradeable.sol


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

// File: Library/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: Library/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;






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

// File: Library/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;




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

// File: Interface/IERC20Upgradeable.sol



pragma solidity ^0.8.2;

interface IERC20Upgradeable {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// File: Interface/IPresaleSettings.sol



pragma solidity ^0.8.16;

interface IPresaleSettings {
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getEthCreationFee () external view returns (uint256);
}
// File: Interface/IWETH.sol



pragma solidity ^0.8.16;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
// File: Library/ReentrancyGuard.sol



pragma solidity ^0.8.16;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}
// File: Library/SafeMath.sol



pragma solidity ^0.8.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: Library/TransferHelper.sol



pragma solidity ^0.8.16;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}
// File: Main/Presale01Upgradeable.sol



pragma solidity ^0.8.16;









contract Presale01Upgradeable is Initializable, ReentrancyGuard, UUPSUpgradeable{
    using SafeMath for uint256;
 
    struct PresaleInfo {
        address payable PRESALE_OWNER;
        IERC20Upgradeable S_TOKEN; // sale token
        IERC20Upgradeable B_TOKEN; // base token // usually WETH (ETH)
        uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
        uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 HARDCAP;
        uint256 SOFTCAP;
        uint256 START_TIME;
        uint256 END_TIME; 
        bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
    }
    
    struct PresaleFeeInfo {
        uint256 NOMOPOLY_BASE_FEE; // divided by 1000
        uint256 NOMOPOLY_TOKEN_FEE; // divided by 1000
        address payable BASE_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
    }
    
    struct PresaleStatus {
        bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
        bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
        bool FORCE_FAILED; // set this flag to force fail the presale
        bool IS_OWNER_WITHDRAWN;
        bool IS_TRANSFERED_FEE;
        bool LIST_ON_UNISWAP;
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
        uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
        uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
        uint256 ROUND1_LENGTH; // in blocks
        uint256 NUM_BUYERS; // number of unique participants
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
        uint256 lastWithdraw; // day of the last withdrawing. If first time => = firstDistributionType
        uint256 totalTokenWithdraw; // number of tokens withdraw
        bool isWithdrawnBase; // is withdraw base
    }

    struct VestingPeriod {
        uint256 distributionTime; 
        uint256 unlockRate;
    }

    struct RefundInfo {
        bool isRefund;
        uint256 refundFee;
        uint256 refundTime;
    }

    event AlertPurchase (
        address indexed buyerAddress,
        uint256 baseAmount,
        uint256 tokenAmount
    );

    event AlertClaimSaleToken (
        address indexed buyerAddress,
        uint256 amountClaimSaleToken
    );

    event AlertRefundBaseTokens (
        address indexed buyerAddress,
        uint256 amountRefundBaseToken
    );

    event AlertWithdrawBaseTokens (
        address indexed buyerAddress,
        uint256 amountWithdrawBaseToken,
        uint256 timeWithdraw
    );

    event AlertOwnerWithdrawTokens (
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertFinalize (
        address indexed saleOwnerAddress,
        uint256 amountSaleToken,
        uint256 amountBaseToken
    );

    event AlertAddNewVestingPeriod (
        address indexed saleOwnerAddress,
        uint256[] distributionTime,
        uint256[] unlockrate
    );
    
    PresaleInfo public PRESALE_INFO;
    PresaleFeeInfo public PRESALE_FEE_INFO;
    PresaleStatus public STATUS;
    address public PRESALE_GENERATOR;
    IPresaleSettings public PRESALE_SETTINGS;
    IWETH public WETH;
    mapping(address => BuyerInfo) public BUYERS;
    uint256 public TOTAL_FEE;
    uint256 public PERCENT_FEE;
    uint256 public REFUND_FEE;
    VestingPeriod[] private LIST_VESTING_PERIOD;
    mapping(address => uint256) public USER_FEES; 
    uint256 public TOTAL_TOKENS_REFUNDED;
    uint256 public TOTAL_FEES_REFUNDED;
    RefundInfo public REFUND_INFO;
    mapping(address => bool) public BUYER_REFUND;
    mapping(string => bool) public VERIFY_MESSAGE;
    address private CALLER; 
    address public MONOPOLY_DEV;
    bool public PAUSE;

    modifier onlyPresaleOwner() {
        require(PRESALE_INFO.PRESALE_OWNER == msg.sender, "NOT PRE-SALE OWNER.");
        _;
    }

    modifier onlyNomopolyDev() {
        require(MONOPOLY_DEV == msg.sender, "ONLY MONOPOLY DEV CALL CALL FUNCTION.");
        _;
    }

    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(CALLER == verifyString(message, v, r, s), "VERIFY SIGNATURE FAILED.");
        _;
    }

    modifier rejectDoubleMessage(string memory message) {
        require(!VERIFY_MESSAGE[message], "REJECT DOUBLE MESSAGE.");
        _;
    }

    modifier declineWhenTheSaleStops(){
        require(PAUSE == false, "PRE-SALE NOT YET DURING EXECUTION.");
        _;
    }

    function initialize(address _presaleGenerator) initializer public payable{
        __UUPSUpgradeable_init();
        PRESALE_GENERATOR = _presaleGenerator;
        WETH = IWETH(0x41b4eb90A6662fE91AC905BaAaE5F2e4d7399469);
        PRESALE_SETTINGS = IPresaleSettings(0x643998b4D9Acb15a931d4dAf876F13DfA3331974);
        MONOPOLY_DEV = 0xceC0efC0b6d21f4342cd821DfcfcC8E1daFda97d;
    }

    function init1 (
        address payable _presaleOwner, 
        uint256 _amount,
        uint256 _tokenPrice, 
        uint256 _maxEthPerBuyer, 
        uint256 _hardcap, 
        uint256 _softcap,
        uint256 _startTime,
        uint256 _endTime
      ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
        PRESALE_INFO.AMOUNT = _amount;
        PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
        PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
        PRESALE_INFO.HARDCAP = _hardcap;
        PRESALE_INFO.SOFTCAP = _softcap;
        PRESALE_INFO.START_TIME = _startTime;
        PRESALE_INFO.END_TIME = _endTime;
    }
    
    function init2 (
        IERC20Upgradeable _baseToken,
        IERC20Upgradeable _presaleToken,
        uint256 _unicryptBaseFee,
        uint256 _unicryptTokenFee,
        address payable _baseFeeAddress,
        address payable _tokenFeeAddress
      ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        PRESALE_INFO.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
        PRESALE_INFO.S_TOKEN = _presaleToken;
        PRESALE_INFO.B_TOKEN = _baseToken;
        PRESALE_FEE_INFO.NOMOPOLY_BASE_FEE = _unicryptBaseFee;
        PRESALE_FEE_INFO.NOMOPOLY_TOKEN_FEE = _unicryptTokenFee;
        PRESALE_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
        PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }

    function init3(
        bool is_white_list,
        address payable _caller,
        uint256 _percentFee,
        uint256[] memory _distributionTime,
        uint256[] memory _unlockRate,
        bool _isRefund,
        uint256[] memory _refundInfo
    ) external {
        require(msg.sender == PRESALE_GENERATOR, "FORBIDDEN.");
        require(_distributionTime.length == _unlockRate.length,"ARRAY MUST BE SAME LENGTH.");
        STATUS.WHITELIST_ONLY = is_white_list;
        CALLER = _caller;
        PERCENT_FEE = _percentFee;
        for(uint i = 0 ; i < _distributionTime.length ; i++) {
            VestingPeriod memory newVestingPeriod;
            newVestingPeriod.distributionTime = _distributionTime[i];
            newVestingPeriod.unlockRate = _unlockRate[i];
            LIST_VESTING_PERIOD.push(newVestingPeriod);
        }   
        REFUND_INFO.isRefund = _isRefund;
        REFUND_INFO.refundFee = _refundInfo[0];
        REFUND_INFO.refundTime = _refundInfo[1];
    }    
    
    function presaleStatus() public view returns (uint256) {
        if (STATUS.FORCE_FAILED) {
          return 3; // FAILED - force fail
        }
        if ((block.timestamp > PRESALE_INFO.END_TIME) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
          return 3; // FAILED - softcap not met by end block
        }
        if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
          return 2; // SUCCESS - hardcap met
        }
        if ((block.timestamp > PRESALE_INFO.END_TIME) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
          return 2; // SUCCESS - endblock and soft cap reached
        }
        if ((block.timestamp >= PRESALE_INFO.START_TIME) && (block.timestamp <= PRESALE_INFO.END_TIME)) {
          return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }

    function purchase(uint256 _amount, string memory _message, uint8 _v, bytes32 _r, bytes32 _s) 
        external 
        payable 
        nonReentrant 
        verifySignature(_message, _v, _r, _s)
        rejectDoubleMessage(_message)
        declineWhenTheSaleStops
    {
        // VERIFY_MESSAGE[_message] = true;
        // require(presaleStatus() == 1, "NOT ACTIVE."); // ACTIVE
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
        uint256 real_amount_in = amount_in;
        uint256 fee = 0;
        
        if (!STATUS.WHITELIST_ONLY) {
            real_amount_in = real_amount_in * (1000 - PERCENT_FEE)/ 1000;
            fee = amount_in - real_amount_in;
        }

        uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER - buyer.baseDeposited;
        uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
        allowance = allowance > remaining ? remaining : allowance;
        if (real_amount_in > allowance) {
            real_amount_in = allowance;
        }
        uint256 tokensSold = (real_amount_in * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        require(tokensSold > 0, "ZERO TOKENS.");
        if (buyer.baseDeposited == 0) {
            STATUS.NUM_BUYERS++;
        }
        buyer.baseDeposited += real_amount_in + fee;
        buyer.tokensOwed += tokensSold;
        STATUS.TOTAL_BASE_COLLECTED += real_amount_in;
        STATUS.TOTAL_TOKENS_SOLD += tokensSold;
        USER_FEES[msg.sender] += fee;
        TOTAL_FEE += fee;

        // return unused ETH
        if (PRESALE_INFO.PRESALE_IN_ETH && real_amount_in + fee < msg.value) {
            payable(msg.sender).transfer(msg.value - real_amount_in - fee);
        }
        // deduct non ETH token from user
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            TransferHelper.safeTransferFrom(
                address(PRESALE_INFO.B_TOKEN),
                msg.sender,
                address(this),
                real_amount_in + fee
            );
        }
        
        emit AlertPurchase(
            msg.sender,
            real_amount_in + fee,
            tokensSold
        );
    }
    
    function userClaimSaleTokens() external nonReentrant declineWhenTheSaleStops {
        require(presaleStatus() == 2, "NOT SUCCESS"); 

        require(
            STATUS.TOTAL_TOKENS_SOLD - STATUS.TOTAL_TOKENS_WITHDRAWN > 0,
            "ALL TOKEN HAS BEEN WITHDRAWN."
        );

        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO CLAIM.");
        uint256 rateWithdrawAfter;
        uint256 currentTime = block.timestamp;
        uint256 tokensOwed = buyer.tokensOwed;

        for(uint i = 0 ; i < LIST_VESTING_PERIOD.length ; i++) {
            if(currentTime >= LIST_VESTING_PERIOD[i].distributionTime &&
                buyer.lastWithdraw < LIST_VESTING_PERIOD[i].distributionTime
            ){
                rateWithdrawAfter += LIST_VESTING_PERIOD[i].unlockRate;
            }
        }
        require(
            tokensOwed > 0, 
            "TOKEN OWNER MUST BE GREAT MORE THEN ZERO."
        );

        require(
            rateWithdrawAfter > 0,
            "USER WITHDRAW ALL TOKEN SUCCESS."
        );

        buyer.lastWithdraw = currentTime;
        uint256 amountWithdraw = (tokensOwed * rateWithdrawAfter) / 1000; 

        if (buyer.totalTokenWithdraw + amountWithdraw > buyer.tokensOwed) {
            amountWithdraw = buyer.tokensOwed - buyer.totalTokenWithdraw;
        }

        STATUS.TOTAL_TOKENS_WITHDRAWN += amountWithdraw;
        buyer.totalTokenWithdraw += amountWithdraw; 
        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN),
            msg.sender,
            amountWithdraw
        );

        emit AlertClaimSaleToken(
            msg.sender,
            amountWithdraw
        );
    }

    function userRefundBaseTokens() external nonReentrant declineWhenTheSaleStops {
        require(REFUND_INFO.isRefund, "CANNOT REFUND.");
        require(presaleStatus() == 2, "NOT SUCCESS."); 
        require(REFUND_INFO.refundTime < block.timestamp, "NOT TIME TO REFUND BASE TOKEN.");

        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!BUYER_REFUND[msg.sender], "NOTHING TO REFUND.");
        require(buyer.totalTokenWithdraw == 0, "CANNOT REFUND.");

        uint256 whitelistDeposited = buyer.baseDeposited - (USER_FEES[msg.sender] * 1000) / PERCENT_FEE;
        uint256 refundAmount = (whitelistDeposited * (1000 - REFUND_INFO.refundFee)) / 1000;
        require(refundAmount > 0, "NOTHING TO REFUND.");

        TOTAL_TOKENS_REFUNDED += refundAmount;
        uint256 tokensRefunded = (whitelistDeposited * PRESALE_INFO.TOKEN_PRICE) / (10**uint256(PRESALE_INFO.B_TOKEN.decimals()));
        buyer.baseDeposited -= whitelistDeposited;
        buyer.tokensOwed -= tokensRefunded;

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            refundAmount,
            !PRESALE_INFO.PRESALE_IN_ETH
        );        

        BUYER_REFUND[msg.sender] = true;

        emit AlertClaimSaleToken(
            msg.sender,
            refundAmount
        );
    }
    
    function userWithdrawBaseTokens() external nonReentrant declineWhenTheSaleStops {
        require(presaleStatus() == 3, "NOT FAILED."); // FAILED
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(!buyer.isWithdrawnBase, "NOTHING TO REFUND.");
        require(buyer.baseDeposited > 0, "INVALID BASE DEPOSITED.");
        STATUS.TOTAL_BASE_WITHDRAWN += buyer.baseDeposited;
        

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            payable(msg.sender),
            buyer.baseDeposited,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        buyer.isWithdrawnBase = true;

        emit AlertWithdrawBaseTokens(
            msg.sender,
            buyer.baseDeposited,
            block.timestamp
        );
    }

    // on presale failure
    // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function ownerWithdrawTokensWhenFailed() external onlyPresaleOwner {
        require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE.");
        require(presaleStatus() == 3, "SALE FAILED."); // FAILED
        uint256 balanceSaleToken = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
        uint256 balanceBaseToken = PRESALE_INFO.B_TOKEN.balanceOf(address(this));

        TransferHelper.safeTransfer(
            address(PRESALE_INFO.S_TOKEN), 
            PRESALE_INFO.PRESALE_OWNER, 
            PRESALE_INFO.S_TOKEN.balanceOf(address(this))
        );

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            PRESALE_INFO.B_TOKEN.balanceOf(address(this)),
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        
        STATUS.IS_OWNER_WITHDRAWN = true;

        emit AlertOwnerWithdrawTokens(
            msg.sender,
            balanceSaleToken,
            balanceBaseToken
        );
    }

    function ownerWithdrawTokensWhenSuccess() external nonReentrant onlyPresaleOwner {
        require(!STATUS.IS_OWNER_WITHDRAWN, "GENERATION COMPLETE.");
        require(presaleStatus() == 2, "NOT SUCCESS."); // SUCCESS
        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this)) + STATUS.TOTAL_TOKENS_WITHDRAWN - STATUS.TOTAL_TOKENS_SOLD;
        uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));

        if (remainingSBalance > 0) {
            TransferHelper.safeTransfer(
                address(PRESALE_INFO.S_TOKEN),
                PRESALE_INFO.PRESALE_OWNER,
                remainingSBalance
            );
        }

        TransferHelper.safeTransferBaseToken(
            address(PRESALE_INFO.B_TOKEN),
            PRESALE_INFO.PRESALE_OWNER,
            remainingBaseBalance,
            !PRESALE_INFO.PRESALE_IN_ETH
        );
        
        STATUS.IS_OWNER_WITHDRAWN = true;

        emit AlertOwnerWithdrawTokens(
            msg.sender,
            remainingSBalance,
            remainingBaseBalance
        );
    }

    function finalize() external onlyNomopolyDev declineWhenTheSaleStops {
        uint256 remainingBBalance;
        if (!PRESALE_INFO.PRESALE_IN_ETH) {
            remainingBBalance = PRESALE_INFO.B_TOKEN.balanceOf(
                address(this)
            );
        } else {
            remainingBBalance = address(this).balance;
        }
        if(remainingBBalance > 0) {
            TransferHelper.safeTransferBaseToken(
                address(PRESALE_INFO.B_TOKEN),
                PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
                remainingBBalance,
                !PRESALE_INFO.PRESALE_IN_ETH
            );
        }

        uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(
            address(this)
        );
        if(remainingSBalance > 0) {
            TransferHelper.safeTransfer(
                address(PRESALE_INFO.S_TOKEN),
                PRESALE_FEE_INFO.BASE_FEE_ADDRESS,
                remainingSBalance
            );
        }
        selfdestruct(PRESALE_FEE_INFO.BASE_FEE_ADDRESS);

        emit AlertFinalize(
            msg.sender,
            remainingSBalance,
            remainingBBalance
        );
    }

    function presaleCancel() external onlyPresaleOwner declineWhenTheSaleStops{
        STATUS.FORCE_FAILED = true;
    }

    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer)
    {
          string memory header = "\x19Ethereum Signed Message:\n000000";
          uint256 lengthOffset;
          uint256 length;
          assembly {
              length:= mload(message)
              lengthOffset:= add(header, 57)
          }
          require(length <= 999999, "NOT PROVIDED.");
          uint256 lengthLength = 0;
          uint256 divisor = 100000;
          while (divisor != 0) {
              uint256 digit = length / divisor;
              if (digit == 0) {
                  if (lengthLength == 0) {
                      divisor /= 10;
                      continue;
                  }
              }
              lengthLength++;
              length -= digit * divisor;
              divisor /= 10;
              digit += 0x30;
              lengthOffset++;
              assembly {
                  mstore8(lengthOffset, digit)
              }
          }
          if (lengthLength == 0) {
              lengthLength = 1 + 0x19 + 1;
          } else {
              lengthLength += 1 + 0x19;
          }
          assembly {
              mstore(header, lengthLength)
          }
          bytes32 check = keccak256(abi.encodePacked(header, message));
          return ecrecover(check, v, r, s);
    }
    
    function updateBlocks(uint256 _startTime, uint256 _endTime) external onlyPresaleOwner declineWhenTheSaleStops{
        require(
            PRESALE_INFO.START_TIME > block.timestamp,
            "INVALID START BLOCK."
        );
        PRESALE_INFO.START_TIME = _startTime;
        PRESALE_INFO.END_TIME = _endTime;
    }

    function updateNewVestingPeriod(uint256[] memory _distributionTime, uint256[] memory _unlockRate) 
        public 
        onlyPresaleOwner 
        declineWhenTheSaleStops
    {
        require(_distributionTime.length == _unlockRate.length, "ARRAY MUST BE SAME LENGTH.");
        
        uint256 rateWithdrawRemaining;
        for(uint256 i = 0 ; i < _distributionTime.length ; i++) {
            rateWithdrawRemaining += _unlockRate[i];
            if(_distributionTime[i] <= block.timestamp) {
                revert("DISTRIBUTION TIME INVALID.");
            }
        } 
        require(
            rateWithdrawRemaining == 1000,
            "TOTAL RATE WITHDRAW REMAINING MUST EQUAL 100%."
        );
        
        delete LIST_VESTING_PERIOD;
        for (uint256 i = 0; i < _distributionTime.length; i++) {
            VestingPeriod memory newVestingPeriod;
            newVestingPeriod.distributionTime = _distributionTime[i];
            newVestingPeriod.unlockRate = _unlockRate[i];
            LIST_VESTING_PERIOD.push(newVestingPeriod);
        }

        emit AlertAddNewVestingPeriod(
            msg.sender,
            _distributionTime,
            _unlockRate
        );
    }

    function setPauseOrActivePresale(bool _isFause) external onlyNomopolyDev{
        require(PAUSE != _isFause, "THIS STATUS HAS ALREADY BEEN SET.");
        PAUSE = _isFause;
    }

    function getVetingPeriodInfo() external view returns(
        uint256[] memory,
        uint256[] memory
    ) {
        uint256 lengthVetingPeriod = LIST_VESTING_PERIOD.length;
        uint256[] memory distributionTime = new uint256[](lengthVetingPeriod);
        uint256[] memory unlockRate = new uint256[](lengthVetingPeriod);

        for(uint256 i = 0; i < lengthVetingPeriod; i++) {
            distributionTime[i] = LIST_VESTING_PERIOD[i].distributionTime;
            unlockRate[i] = LIST_VESTING_PERIOD[i].unlockRate;
        } 
        
        return(distributionTime, unlockRate);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyNomopolyDev
        override
    {}
}