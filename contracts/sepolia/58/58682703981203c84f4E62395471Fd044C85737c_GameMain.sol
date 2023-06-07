// File: @openzeppelin/[email protected]/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File: @openzeppelin/[email protected]/interfaces/IERC1967Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// File: @openzeppelin/[email protected]/proxy/beacon/IBeaconUpgradeable.sol


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

// File: @openzeppelin/[email protected]/interfaces/draft-IERC1822Upgradeable.sol


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

// File: @openzeppelin/[email protected]/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/[email protected]/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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

// File: @openzeppelin/[email protected]/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;







/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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

// File: @openzeppelin/[email protected]/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/[email protected]/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: main_contract_proxy_relise.sol


pragma solidity ^0.8.9;




// interface etcOrc
interface IETCORC {
    function ownerOf(uint256 _tokenId) external view returns (address);
}
library Errors {
    string constant NOT_ORC_OWNER = "Only orc owner";
    string constant NOT_OWNER = "Only Owner";
    string constant NOT_REGENERATIONS = "Not regenerations";
    string constant IS_REGISTER = "Orc is regenerations";
    string constant NOT_RANK_LIST = "Not ranc list";
    string constant NOT_REGISTRATION = "Orc not register";
    string constant NOT_PAID_FEE = "Not paid fee";
    string constant INVALID_VALUE = "Invalid value";
    string constant NOT_APPROVED_CONTRACT = "Not approved";
}

contract GameMain is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // variable initialization
    uint256 orcLimit;
    address public ETCORCContract;

    IETCORC ietcorc;

    struct orcStruct {
        string name;
        uint256 lvl;
        uint256 rank;
        uint256 Victories;
        uint256 Defeats;
        int profitNFT;
        uint256 XP;
        uint256 startRegenerationHP;
        uint256 startRegenerationIncreaseXP;
        int profitETC;
        bool freeze;
    }

    struct lvlStruct {
        uint256 maxBids;
        uint256 XP;
        uint256 IncreaseXpTime;
        uint256 HpRegenTime;
    }

    mapping(uint256 => lvlStruct) public mapLvl;
    mapping(uint256 => orcStruct) public orcInfo;
    mapping(uint256 => uint256) public mapXpPayValue;
    mapping(address => bool) public approvedListContract;
    uint16[2500] public rankList_1;
    uint16[2500] public rankList_2;
    uint16[2500] public rankList_3;
    uint16[2500] public rankList_4;
    // object interface etcOrc



    //=========================================
    //        [6461 ,9151 ,2580 ,7176 ,8347 ,6405 ,21 ,1399 ,7688 ,719 ,7861 ,297 ,2249 ,5561 ,8418 ,5042 ,791 ,3563 ,1022 ,8105 ,5976 ,2733 ,724 ,2968 ,5948 ,5492 ,7415 ,3914 ,3074 ,8612 ,2219 ,4597 ,5141 ,2701 ,8654 ,9609 ,3787 ,7144 ,1659 ,8895 ,2720 ,1398 ,7998 ,2535 ,1216 ,4170 ,2207 ,5876 ,1939 ,8321 ,6590 ,102 ,3329 ,5845 ,7892 ,2187 ,8865 ,2826 ,9507 ,7086 ,1895 ,7487 ,1776 ,3477 ,9132 ,1865 ,1995 ,5048 ,7671 ,3922 ,8522 ,8282 ,4684 ,7228 ,1886 ,4422 ,9204 ,362 ,8617 ,5591 ,3428 ,155 ,1666 ,3956 ,3520 ,4447 ,6482 ,474 ,6562 ,6223 ,8101 ,3805 ,4658 ,9367 ,8499 ,7160 ,3419 ,675 ,1220 ,6464 ,3148 ,3974 ,1136 ,600 ,6242 ,3601 ,5601 ,278 ,9176 ,4639 ,6635 ,243 ,3032 ,5423 ,9435 ,4226 ,5379 ,103 ,7499 ,5929 ,1077 ,2390 ,9310 ,7689 ,7773 ,420 ,1264 ,7330 ,4899 ,9468 ,6504 ,2364 ,4147 ,6889 ,782 ,6487 ,3699 ,2261 ,3799 ,5020 ,878 ,1270 ,1831 ,7632 ,1938 ,9202 ,6040 ,9068 ,9040 ,513 ,7815 ,6535 ,9546 ,5839 ,5585 ,5858 ,7390 ,3596 ,6408 ,3271 ,5562 ,272 ,2301 ,6069 ,8928 ,7606 ,2022 ,9898 ,3435 ,6851 ,2925 ,7927 ,8912 ,2229 ,5283 ,7979 ,7050 ,662 ,3174 ,8716 ,783 ,8052 ,2710 ,7402 ,1182 ,4514 ,4089 ,884 ,8929 ,6155 ,4629 ,9889 ,2685 ,5925 ,4440 ,4397 ,3210 ,7372 ,6445 ,305 ,6943 ,8500 ,9489 ,6121 ,5285 ,6164 ,1823 ,1135 ,2351 ,8199 ,754 ,2323 ,4178 ,3059 ,7954 ,8424 ,1973 ,8419 ,9551 ,8163 ,5263 ,2075 ,1492 ,3067 ,2458 ,4195 ,6489 ,6868 ,3246 ,2973 ,6555 ,4227 ,5044 ,8045 ,3447 ,591 ,2349 ,5663 ,1847 ,9703 ,6959 ,2536 ,2174 ,4146 ,5345 ,2629 ,3276 ,7826 ,6502 ,4682 ,3562 ,8800 ,6577 ,6835 ,55 ,7178 ,1286 ,5163 ,1700 ,6561 ,8216 ,3680 ,5007 ,2227 ,8003 ,4940 ,7625 ,6955 ,5409 ,6528 ,1312 ,3038 ,7566 ,2093 ,2435 ,7130 ,2785 ,4856 ,3409 ,1269 ,9477 ,9521 ,672 ,6335 ,8023 ,8341 ,5500 ,8569 ,973 ,3214 ,6980 ,6283 ,535 ,9010 ,1523 ,7486 ,4959 ,7666 ,6777 ,9112 ,6265 ,9210 ,1421 ,2578 ,3513 ,4772 ,4795 ,9175 ,3219 ,9657 ,6510 ,3548 ,4398 ,4878 ,1248 ,9673 ,2215 ,6601 ,8924 ,7604 ,5201 ,6610 ,2368 ,6698 ,3448 ,4112 ,9215 ,8727 ,7865 ,7342 ,8272 ,5935 ,3771 ,8786 ,781 ,4485 ,1352 ,6928 ,6541 ,1649 ,6437 ,2012 ,8857 ,3786 ,8987 ,6977 ,9772 ,8271 ,7974 ,8573 ,6991 ,8822 ,5106 ,7559 ,1373 ,3120 ,4410 ,1775 ,1300 ,6681 ,7284 ,4174 ,1960 ,7790 ,286 ,3686 ,4136 ,4448 ,2017 ,7849 ,9122 ,5969 ,7523 ,5687 ,5217 ,3508 ,7813 ,2618 ,2335 ,2073 ,571 ,6002 ,8156 ,2327 ,1890 ,212 ,8998 ,8393 ,8603 ,6782 ,2976 ,9394 ,4051 ,704 ,8009 ,1750 ,637 ,2815 ,1941 ,9597 ,1171 ,5093 ,5864 ,3340 ,6568 ,4922 ,6151 ,1584 ,1931 ,4686 ,6417 ,3652 ,3457 ,2428 ,1551 ,1670 ,7809 ,4881 ,6961 ,7354 ,3051 ,2184 ,7327 ,553 ,7925 ,5712 ,2097 ,4540 ,731 ,6595 ,8788 ,2812 ,9240 ,3754 ,5898 ,8904 ,1164 ,4278 ,619 ,4722 ,1448 ,5669 ,6158 ,3900 ,4941 ,7454 ,5519 ,3306 ,3108 ,1916 ,6511 ,9480 ,435 ,7336 ,7872 ,3399 ,8909 ,5786 ,628 ,4164 ,5133 ,715 ,300 ,7380 ,6474 ,9746 ,2939 ,3510 ,1566 ,3072 ,8992 ,6089 ,5719 ,8993 ,7213 ,4609 ,6893 ,8118 ,9143 ,7256 ,1721 ,8780 ,1809 ,184 ,1741 ,8890 ,4200 ,8467 ,905 ,1875 ,6329 ,9317 ,7489 ,8210 ,9087 ,9545 ,1242 ,5464 ,171 ,3564 ,5963 ,457 ,6715 ,7626 ,805 ,9167 ,7013 ,6874 ,5278 ,80 ,6171 ,1810 ,6020 ,1186 ,9080 ,6580 ,3881 ,9084 ,6358 ,2568 ,4958 ,6556 ,426 ,275 ,8179 ,1054 ,965 ,1419 ,246 ,3308 ,3161 ,4111 ,8704 ,2627 ,7914 ,7164 ,5277 ,136 ,3838 ,2395 ,3721 ,7658 ,2898 ,3634 ,3262 ,4054 ,482 ,8463 ,6787 ,37 ,6755 ,1676 ,5406 ,9937 ,6872 ,6259 ,6533 ,758 ,6506 ,42 ,8171 ,2457 ,3164 ,6670 ,7148 ,8184 ,2264 ,4653 ,6133 ,9632 ,4049 ,4171 ,7071 ,6381 ,2216 ,2745 ,8447 ,7289 ,2342 ,9963 ,6559 ,2427 ,2918 ,8900 ,8177 ,462 ,6081 ,3784 ,5125 ,4771 ,8329 ,7227 ,1440 ,1265 ,943 ,7634 ,6677 ,4231 ,9586 ,7054 ,8241 ,4497 ,2286 ,3735 ,3052 ,1974 ,6648 ,7893 ,9899 ,2844 ,4406 ,6009 ,3831 ,403 ,9985 ,773 ,3661 ,9280 ,6924 ,4509 ,1530 ,1052 ,7564 ,5202 ,1561 ,7447 ,8313 ,1288 ,2003 ,4371 ,1680 ,86 ,1690 ,4833 ,9952 ,3610 ,1571 ,5419 ,9691 ,4753 ,2895 ,261 ,54 ,3575 ,8896 ,9655 ,3821 ,7206 ,9297 ,1470 ,7123 ,3009 ,8501 ,9880 ,5347 ,8961 ,7924 ,229 ,6776 ,2352 ,8368 ,1172 ,1127 ,9267 ,844 ,9716 ,4309 ,9236 ,7620 ,4743 ,3408 ,7404 ,2084 ,5472 ,7084 ,4957 ,1519 ,761 ,9581 ,6326 ,6054 ,3604 ,8556 ,5450 ,9499 ,181 ,7744 ,4016 ,5728 ,8074 ,3962 ,7166 ,5497 ,2735 ,5094 ,3845 ,1965 ,8950 ,9734 ,2582 ,381 ,6616 ,3021 ,1555 ,9875 ,8576 ,8601 ,1743 ,7842 ,8671 ,2055 ,1298 ,926 ,4335 ,5047 ,6521 ,6778 ,3555 ,4749 ,955 ,1607 ,89 ,3842 ,8217 ,5706 ,8861 ,2481 ,5578 ,8172 ,8706 ,439 ,6622 ,5877 ,4955 ,6894 ,8145 ,5913 ,7705 ,7300 ,7778 ,7225 ,8834 ,1109 ,7512 ,7040 ,8040 ,7796 ,9686 ,1537 ,8412 ,3512 ,6795 ,1654 ,1899 ,3822 ,562 ,785 ,3213 ,471 ,411 ,2122 ,5388 ,1538 ,4040 ,4292 ,1412 ,8672 ,307 ,3294 ,9920 ,9656 ,8653 ,225 ,8072 ,5689 ,6748 ,4502 ,7237 ,8141 ,6033 ,9677 ,9212 ,1462 ,7736 ,7382 ,6850 ,7238 ,7690 ,1505 ,6418 ,8413 ,6406 ,7555 ,8679 ,5091 ,6605 ,7797 ,9481 ,3848 ,6662 ,5067 ,2173 ,8331 ,9999 ,5334 ,8345 ,9522 ,5693 ,9134 ,3300 ,6345 ,8028 ,9228 ,5989 ,6542 ,7517 ,2622 ,8235 ,3402 ,3002 ,4230 ,7331 ,3624 ,9061 ,6696 ,1096 ,9893 ,6087 ,2038 ,8932 ,6462 ,9666 ,8918 ,1849 ,4038 ,6808 ,5400 ,7005 ,291 ,9341 ,5281 ,6618 ,6666 ,3397 ,5426 ,4840 ,4279 ,5746 ,1311 ,1378 ,8294 ,3092 ,5857 ,1987 ,1013 ,6957 ,7419 ,5341 ,6211 ,9389 ,4778 ,3988 ,2149 ,2878 ,9469 ,7010 ,4809 ,9196 ,624 ,1793 ,4237 ,2081 ,6347 ,1773 ,9639 ,7611 ,3996 ,7572 ,9643 ,6320 ,7315 ,1898 ,7763 ,6711 ,6411 ,6144 ,9457 ,7311 ,5922 ,5960 ,2202 ,6775 ,8686 ,28 ,4897 ,9067 ,3259 ,7900 ,567 ,3209 ,1718 ,8614 ,1165 ,5702 ,8236 ,2118 ,9103 ,4452 ,5720 ,5569 ,1732 ,3908 ,3027 ,4101 ,5366 ,343 ,5493 ,9093 ,1657 ,2504 ,2951 ,5316 ,2595 ,3832 ,2465 ,3587 ,1006 ,6060 ,1090 ,2128 ,2476 ,6956 ,764 ,4548 ,7760 ,1249 ,9350 ,3827 ,756 ,5435 ,2220 ,1859 ,3496 ,2888 ,4677 ,6159 ,9610 ,418 ,684 ,8906 ,9185 ,7575 ,4482 ,907 ,3708 ,3706 ,5170 ,860 ,5885 ,4244 ,9125 ,3796 ,2662 ,8474 ,2446 ,1562 ,2693 ,7200 ,5711 ,9808 ,391 ,5905 ,8631 ,5394 ,9835 ,3880 ,6395 ,1791 ,7303 ,1747 ,5780 ,5653 ,318 ,422 ,9978 ,7702 ,9780 ,3438 ,2150 ,6836 ,1597 ,3950 ,9045 ,912 ,2584 ,4499 ,4511 ,8975 ,8754 ,1122 ,9282 ,3461 ,59 ,5867 ,5251 ,6806 ,8537 ,7960 ,8031 ,5249 ,8477 ,101 ,9791 ,2447 ,2033 ,6682 ,9056 ,9897 ,6031 ,8561 ,7895 ,1363 ,4519 ,9369 ,1777 ,6396 ,3384 ,9089 ,1619 ,7171 ,497 ,1048 ,5461 ,8942 ,2501 ,8699 ,9392 ,4913 ,9867 ,8396 ,9079 ,9344 ,5580 ,6548 ,7772 ,9304 ,3943 ,8175 ,7195 ,2493 ,1616 ,8252 ,94 ,2869 ,695 ,265 ,8692 ,6968 ,599 ,6099 ,5452 ,5239 ,7177 ,5759 ,74 ,578 ,4439 ,8453 ,7409 ,893 ,9154 ,4642 ,6983 ,6141 ,9816 ,4043 ,8300 ,6065 ,4157 ,961 ,9036 ,5848 ,6566 ,1128 ,402 ,4295 ,9708 ,610 ,7676 ,4811 ,8117 ,4185 ,8581 ,8759 ,3291 ,3504 ,5579 ,864 ,4744 ,4974 ,9601 ,8470 ,6427 ,9733 ,1162 ,7070 ,7323 ,2689 ,1850 ,2199 ,4742 ,7236 ,6815 ,670 ,1291 ,6195 ,8266 ,9152 ,2703 ,5104 ,706 ,6479 ,8384 ,7899 ,7418 ,2224 ,5909 ,3665 ,5434 ,2513 ,3538 ,3886 ,5686 ,6150 ,2875 ,9695 ,6018 ,6978 ,4960 ,3627 ,7565 ,9568 ,2758 ,4128 ,9846 ,2430 ,5140 ,6749 ,818 ,1385 ,7749 ,6419 ,4367 ,5478 ,1983 ,8275 ,283 ,6287 ,4209 ,3714 ,5433 ,2547 ,1692 ,3299 ,747 ,7855 ,5538 ,5110 ,4058 ,8846 ,3304 ,7 ,9070 ,4001 ,9820 ,3898 ,3367 ,8506 ,8732 ,4290 ,3344 ,1297 ,2256 ,251 ,3667 ,894 ,8642 ,7007 ,5078 ,3478 ,1490 ,2032 ,6412 ,3779 ,237 ,6745 ,6095 ,7378 ,1065 ,8641 ,9033 ,5225 ,2002 ,1406 ,4355 ,4384 ,4631 ,7481 ,3629 ,2606 ,9529 ,2083 ,4145 ,2624 ,8962 ,5162 ,4042 ,274 ,877 ,9066 ,5647 ,8274 ,4307 ,3244 ,3152 ,9870 ,1792 ,4816 ,2603 ,9088 ,1094 ,5508 ,9328 ,8011 ,5417 ,4879 ,5754 ,5320 ,3591 ,3005 ,5112 ,4256 ,4978 ,2155 ,3979 ,5882 ,3062 ,8968 ,8417 ,6972 ,2265 ,3561 ,2414 ,4541 ,4115 ,4492 ,8191 ,8358 ,5510 ,6204 ,91 ,5276 ,4177 ,5846 ,5737 ,703 ,4119 ,1428 ,9484 ,2757 ,1123 ,3543 ,5374 ,1272 ,712 ,4495 ,8637 ,158 ,4577 ,8182 ,6773 ,1883 ,3645 ,4702 ,8034 ,4650 ,9318 ,8922 ,3163 ,2148 ,4939 ,6006 ,5350 ,7644 ,8696 ,4120 ,1953 ,1918 ,5553 ,2126 ,7088 ,9037 ,5980 ,3541 ,5548 ,7279 ,7965 ,1341 ,298 ,9023 ,4822 ,7915 ,4614 ,4337 ,8127 ,3656 ,6468 ,8777 ,441 ,5267 ,3196 ,9903 ,6106 ,341 ,1611 ,7738 ,8615 ,2870 ,541 ,5874 ,7870 ,8713 ,936 ,1274 ,840 ,1111 ,5673 ,2008 ,7952 ,2691 ,1130 ,5264 ,4484 ,4526 ,3362 ,5502 ,3065 ,3778 ,5844 ,8110 ,5893 ,3028 ,4646 ,6279 ,1207 ,7867 ,2066 ,3245 ,2517 ,3188 ,5053 ,2605 ,925 ,7850 ,3267 ,4149 ,7400 ,4909 ,8317 ,2919 ,5074 ,9825 ,2678 ,2455 ,2877 ,1966 ,728 ,8408 ,124 ,1469 ,5808 ,8109 ,3687 ,9585 ,1542 ,2374 ,7864 ,8826 ,8745 ,8479 ,7114 ,6700 ,9671 ,133 ,3320 ,9137 ,44 ,4796 ,2398 ,1901 ,2687 ,1488 ,8144 ,1381 ,8422 ,8267 ,3430 ,3025 ,2316 ,6953 ,5065 ,8741 ,5953 ,4966 ,5718 ,1336 ,3082 ,2893 ,4370 ,10000 ,3199 ,3265 ,219 ,5657 ,9378 ,6862 ,9384 ,3882 ,980 ,4618 ,3775 ,9402 ,1239 ,7818 ,8498 ,4807 ,7888 ,5230 ,3824 ,8877 ,196 ,4 ,8268 ,7801 ,5654 ,4476 ,427 ,1353 ,6790 ,8920 ,7483 ,904 ,9452 ,7269 ,3226 ,8598 ,8851 ,8659 ,1471 ,1688 ,8205 ,4344 ,2530 ,5521 ,3307 ,8376 ,1610 ,5280 ,4929 ,6614 ,3941 ,3583 ,6524 ,1211 ,4094 ,3383 ,2811 ,3358 ,2553 ,9682 ,3057 ,2560 ,645 ,4373 ,8464 ,7694 ,4017 ,4507 ,8033 ,4332 ,8757 ,5997 ,5535 ,2365 ,2533 ,1871 ,4466 ,7610 ,2240 ,3927 ,448 ,8543 ,6564 ,7503 ,8575 ,6472 ,6011 ,839 ,7788 ,1547 ,6145 ,1984 ,9747 ,1580 ,3069 ,5818 ,5756 ,2257 ,1848 ,451 ,3091 ,8208 ,9183 ,5619 ,7245 ,6798 ,2046 ,9562 ,6856 ,7955 ,5034 ,8512 ,3016 ,2196 ,607 ,1869 ,6168 ,5954 ,7808 ,2835 ,6407 ,8356 ,2072 ,6042 ,7424 ,3639 ,8743 ,5594 ,8383 ,4933 ,4680 ,9018 ,2532 ,7909 ,7526 ,2940 ,1018 ,2911 ,9404 ,3034 ,1255 ,1245 ,18 ,9990 ,4162 ,7014 ,8142 ,5173 ,4573 ,9921 ,516 ,605 ,1282 ,2712 ,4403 ,9450 ,6892 ,268 ,7337 ,683 ,6901 ,8917 ,8395 ,3722 ,1704 ,9348 ,8640 ,2705 ,8316 ,3863 ,3395 ,8926 ,3143 ,2255 ,1845 ,3302 ,1663 ,8774 ,4789 ,3928 ,9886 ,7720 ,9148 ,3345 ,492 ,4050 ,8514 ,9600 ,2233 ,2669 ,6713 ,9709 ,5145 ,6227 ,7019 ,3376 ,2928 ,2528 ,3737 ,8465 ,6243 ,416 ,2866 ,299 ,665 ,9293 ,7392 ,8411 ,7889 ,582 ,1915 ,2512 ,8026 ,5908 ,6311 ,2665 ,1665 ,6067 ,9528 ,4027 ,661 ,5717 ,7059 ,1605 ,4003 ,4885 ,4066 ,3526 ,676 ,625 ,2371 ,6321 ,9706 ,9712 ,7297 ,3744 ,677 ,8588 ,8535 ,3465 ,9956 ,1795 ,1504 ,8201 ,2488 ,3243 ,3619 ,2657 ,2970 ,4800 ,8787 ,2867 ,10 ,1894 ,1510 ,9596 ,4328 ,7776 ,9667 ,1303 ,3571 ,4662 ,2031 ,3160 ,63 ,1842 ,3048 ,9288 ,6131 ,6165 ,3519 ,6606 ,6271 ,2294 ,5295 ,9508 ,6105 ,6688 ,5355 ,2440 ,9320 ,2140 ,9150 ,8519 ,249 ,9710 ,483 ,1968 ,1053 ,6208 ,3279 ,4557 ,2492 ,5192 ,287 ,377 ,9060 ,2497 ,6139 ,1819 ,1733 ,5730 ,2007 ,4625 ,1161 ,7456 ,6026 ,2833 ,3178 ,6174 ,8456 ,8634 ,7307 ,6800 ,7718 ,1924 ,1977 ,7963 ,6186 ,9321 ,396 ,635 ,9226 ,4598 ,4728 ,5793 ,6804 ,6719 ,7259 ,7725 ,4294 ,7724 ,7510 ,9984 ,1206 ,6160 ,1460 ,574 ,8160 ,7184 ,7923 ,329 ,9271 ,3586 ,9273 ,5172 ,9918 ,3228 ,1697 ,4769 ,5205 ,6152 ,6448 ,9437 ,7843 ,2643 ,8403 ,6010 ,1310 ,5629 ,1990 ,4409 ,2743 ,3007 ,8960 ,1796 ,7116 ,9349 ,8119 ,587 ,9967 ,3815 ,3049 ,5314 ,630 ,6083 ,6338 ,1441 ,2716 ,4258 ,1132 ,238 ,9669 ,1592 ,8791 ,999 ,449 ,5597 ,7458 ,9818 ,5822 ,7814 ,9149 ,5724 ,6941 ,2056 ,65 ,7246 ,5336 ,7767 ,5300 ,30 ,257 ,222 ,2354 ,2856 ,4619 ,3187 ,9278 ,3527 ,4691 ,6519 ,2527 ,3841 ,7313 ,2921 ,1012 ,5455 ,2474 ,6602 ,9764 ,9074 ,4083 ,977 ,9101 ,7286 ,9576 ,7646 ,6768 ,3826 ,2731 ,5259 ,4114 ,3470 ,8554 ,3315 ,8080 ,3705 ,1218 ,5180 ,6929 ,9756 ,214 ,889 ,4285 ,2314 ,6503 ,7582 ,236 ,5084 ,5866 ,533 ,8540 ,4067 ,2448 ,7656 ,6153 ,9704 ,6175 ,327 ,4845 ,71 ,5697 ,6545 ,7058 ,96 ,4504 ,7946 ,896 ,6253 ,3550 ,8842 ,3144 ,1326 ,6343 ,7397 ,9837 ,8610 ,5584 ,8905 ,8893 ,3420 ,7659 ,5396 ,7441 ,5796 ,7287 ,6676 ,6705 ,2876 ,2997 ,9731 ,8984 ,3940 ,4095 ,2927 ,2355 ,4730 ,1133 ,6393 ,9444 ,3690 ,4107 ,598 ,7897 ,1598 ,3324 ,3333 ,9857 ,7660 ,2400 ,5701 ,3290 ,3728 ,129 ,1874 ,216 ,9261 ,8240 ,4569 ,7876 ,4302 ,5674 ,8668 ,835 ,9225 ,5422 ,6721 ,2023 ,576 ,8222 ,469 ,5495 ,7862 ,5161 ,3611 ,1015 ,3549 ,4605 ,3359 ,2634 ,4116 ,1410 ,2894 ,2975 ,7841 ,4130 ,4032 ,1634 ,9743 ,1579 ,9913 ,7083 ,2159 ,468 ,8213 ,4798 ,4873 ,4901 ,8648 ,4718 ,3917 ,942 ,596 ,456 ,6004 ,6843 ,8489 ,4266 ,6656 ,1499 ,4665 ,7470 ,5509 ,6909 ,146 ,1622 ,5681 ,7051 ,1357 ,701 ,5957 ,6739 ,253 ,7068 ,2908 ,7568 ,2683 ,4583 ,6587 ,5420 ,6293 ,897 ,4076 ,6958 ,1000 ,1545 ,1424 ,5234 ,4217 ,491 ,6389 ,7938 ,7091 ,3406 ,9119 ,8700 ,2091 ,9286 ,7932 ,4571 ,8600 ,1959 ,984 ,993 ,5934 ,4365 ,2099 ,4343 ,137 ,9463 ,9821 ,1951 ,9784 ,1434 ,2437 ,9427 ,2541 ,1325 ,6704 ,3521 ,6003 ,9699 ,2744 ,4138 ,5865 ,4532 ,4932 ,186 ,2408 ,1969 ,4594 ,5906 ,9379 ,4317 ,1919 ,7934 ,350 ,5349 ,4062 ,9110 ,9968 ,9510 ,1927 ,7684 ,762 ,9828 ,7429 ,4318 ,3849 ,2138 ,8591 ,7905 ,1134 ,8995 ,1285 ,8756 ,8734 ,3318 ,9644 ,7056 ,6746 ,7067 ,1243 ,4151 ,5414 ,5077 ,8769 ,4433 ,7061 ,3758 ,6420 ,3556 ,7664 ,6575 ,7135 ,8022 ,5650 ,7368 ,9398 ,5900 ,2291 ,9559 ,8934 ,2790 ,6328 ,3439 ,8004 ,3476 ,681 ,9065 ,7168 ,8423 ,5727 ,7141 ,8471 ,4553 ,1491 ,6947 ,473 ,1089 ,1100 ,6554 ,9802 ,4767 ,3248 ,8082 ,1319 ,7201 ,3218 ,3490 ,2377 ,6671 ,2079 ,9347 ,8440 ,2134 ,6831 ,4946 ,3280 ,8076 ,6741 ,3485 ,1142 ,3150 ,4600 ,1338 ,7265 ,6016 ,9563 ,2320 ,1423 ,7374 ,3752 ,8012 ,5339 ,2786 ,3151 ,4389 ,7580 ,7945 ,4379 ,7732 ,5642 ,1456 ,7571 ,1475 ,3984 ,7679 ,4276 ,6766 ,852 ,9878 ,5060 ,784 ,4041 ,7266 ,2799 ,9165 ,508 ,351 ,985 ,8134 ,8000 ,8043 ,7605 ,7756 ,5666 ,8130 ,9275 ,8238 ,8196 ,7263 ,1038 ,3407 ,1032 ,9410 ,3763 ,3071 ,830 ,3003 ,892 ,2680 ,7333 ,3230 ,3047 ,5721 ,3211 ,3414 ,7964 ,3012 ,2289 ,5924 ,4152 ,9063 ,7111 ,9599 ,5284 ,6516 ,4249 ,5146 ,7338 ,2912 ,9769 ,2992 ,4987 ,1617 ,4877 ,802 ,496 ,8256 ,3560 ,7240 ,794 ,7283 ,5537 ,688 ,5322 ,8380 ,3022 ,3620 ,8567 ,4954 ,36 ,1438 ,2954 ,9272 ,3739 ,2236 ,8845 ,2293 ,2252 ,8572 ,4247 ,8062 ,8490 ,3616 ,4053 ,489 ,3946 ,6944 ,6125 ,8204 ,2636 ,6914 ,1905 ,7821 ,3365 ,1046 ,3877 ,5195 ,788 ,66 ,2101 ,534 ,9000 ,5113 ,7270 ,9799 ,6079 ,7638 ,9962 ,3387 ,3313 ,8925 ,5739 ,6075 ,9022 ,4044 ,4382 ,3011 ,1198 ,3113 ,2635 ,1370 ,9178 ,3689 ,3135 ,9002 ,5547 ,5794 ,1069 ,1356 ,9961 ,6723 ,4156 ,141 ,6234 ,1208 ,8169 ,9160 ,9869 ,7824 ,1073 ,7355 ,2182 ,4345 ,6527 ,5638 ,7098 ,323 ,2647 ,9142 ,5671 ,6916 ,7112 ,3131 ,1758 ,4313 ,6185 ,7115 ,9224 ,9668 ,4543 ,6202 ,501 ,260 ,5117 ,9849 ,6021 ,4284 ,1637 ,2338 ,1422 ,4737 ,3835 ,3669 ,6373 ,3602 ,7910 ,2200 ,5559 ,917 ,4824 ,5127 ,8327 ,9241 ,280 ,6652 ,4861 ,4729 ,365 ,264 ,5187 ,2165 ,3851 ,1125 ,6690 ,9396 ,880 ,5633 ,6615 ,3312 ,5776 ,1970 ,4025 ,5505 ,344 ,1043 ,13 ,5226 ,2577 ,820 ,7423 ,2671 ,9445 ,4633 ,3268 ,7272 ,4124 ,2452 ,401 ,5499 ,556 ,8303 ,3709 ,8301 ,1266 ,7839 ,1454 ,539 ,3375 ,3390 ,9754 ,9001 ,7478 ,2154 ,4584 ,9613 ,2266 ,4073 ,8673 ,4839 ,1420 ,4774 ,9887 ,6299 ,3868 ,2095 ,9373 ,1204 ,2709 ,8903 ,472 ,8650 ,5143 ,2057 ,2477 ,1928 ,3896 ,6840 ,6149 ,6275 ,6057 ,81 ,6340 ,721 ,4274 ,1527 ,9172 ,7477 ,4212 ,226 ,5572 ,6592 ,3915 ,8243 ,122 ,415 ,2188 ,4876 ,2281 ,8703 ,4121 ,4655 ,8529 ,6097 ,9517 ,609 ,3467 ,8206 ,1106 ,2690 ,9895 ,1154 ,4386 ,861 ,9752 ,8523 ,7787 ,6948 ,6044 ,3867 ,8751 ,7421 ,8473 ,815 ,1461 ,8044 ,4758 ,3893 ,4340 ,633 ,668 ,669 ,8959 ,3394 ,3492 ,6041 ,887 ,6193 ,2375 ,6264 ,6349 ,5964 ,29 ,3060 ,25 ,7682 ,7608 ,414 ,7840 ,3878 ,6732 ,8806 ,5923 ,7192 ,7549 ,4996 ,841 ,2425 ,9245 ,649 ,9737 ,5438 ,2509 ,5813 ,6432 ,8094 ,2284 ,5356 ,5564 ,8128 ,3885 ,4808 ,8131 ,2626 ,8365 ,5787 ,4561 ,52 ,8876 ,9100 ,2479 ,8830 ,1224 ,8812 ,9464 ,9860 ,663 ,4679 ,2403 ,659 ,8227 ,5733 ,2774 ,100 ,3309 ,179 ,7351 ,7485 ,3261 ,4045 ,3795 ,7211 ,3221 ,2278 ,277 ,83 ,7308 ,2270 ,4574 ,8152 ,6620 ,760 ,8765 ,6034 ,940 ,5863 ,3042 ,9123 ,8058 ,6645 ,9395 ,8867 ,5479 ,9519 ,5723 ,9121 ,573 ,4535 ,3472 ,4056 ,3274 ,1629 ,5206 ,6429 ,6683 ,4426 ,7039 ,3000 ,1866 ,6930 ,3371 ,3701 ,5346 ,8605 ,2544 ,8763 ,2543 ,9244 ,6323 ,1483 ,8491 ,772 ,3889 ,6365 ,5945 ,6132 ,4919 ,20 ,6049 ,2283 ,3136 ,4770 ,6225 ,627 ,5741 ,1386 ,9550 ,512 ,6140 ,1671 ,566 ,7073 ,5447 ,9180 ,6176 ,5836 ,8367 ,2339 ,2011 ,4846 ,4645 ,6454 ,7975 ,8853 ,3621 ,6196 ,3829 ,3417 ,9046 ,3450 ,4843 ,9140 ,1606 ,1814 ,3287 ,2776 ,6769 ,5916 ,3204 ,5425 ,2974 ,504 ,1070 ,9408 ,4024 ,1371 ,1427 ,5843 ,1144 ,771 ,9761 ,8941 ,3559 ,7350 ,9242 ,8608 ,8261 ,1151 ,254 ,9491 ,4917 ,7301 ,2085 ,5108 ,4530 ,8251 ,4985 ,7621 ,5810 ,4934 ,1989 ,9397 ,6560 ,2204 ,140 ,1917 ,5761 ,1430 ,1252 ,9534 ,3913 ,7099 ,5033 ,1258 ,7023 ,5644 ,7438 ,6332 ,7435 ,4766 ,9191 ,5032 ,195 ,4948 ,7992 ,2274 ,2473 ,6181 ,4213 ,7550 ,6979 ,4606 ,5868 ,8017 ,4134 ,2564 ,6887 ,6200 ,438 ,1550 ,6073 ,3056 ,990 ,9400 ,1305 ,7174 ,8802 ,8625 ,9338 ,3716 ,4475 ,8948 ,4801 ,6589 ,2262 ,2694 ,7089 ,2258 ,221 ,1329 ,7601 ,6082 ,3453 ,1967 ,2713 ,4926 ,2670 ,949 ,3283 ,2397 ,1686 ,2852 ,6220 ,3389 ,1113 ,6906 ,4077 ,5085 ,7295 ,1946 ,1799 ,2175 ,5546 ,8178 ,1920 ,2444 ,546 ,5722 ,2890 ,2614 ,43 ,6822 ,3540 ,1028 ,4470 ,6505 ,8684 ,6581 ,8444 ,9264 ,9146 ,7951 ,4224 ,8187 ,8466 ,7681 ,1062 ,7836 ,1139 ,4707 ,956 ,8448 ,6975 ,498 ,308 ,3434 ,3350 ,5293 ,1656 ,1631 ,2343 ,655 ,7017 ,9017 ,6350 ,6572 ,1500 ,3154 ,1489 ,2637 ,1596 ,256 ,5742 ,7522 ,8081 ,4264 ,5586 ,1857 ,1826 ,6758 ,1443 ,4850 ,4849 ,147 ,7921 ,7743 ,5870 ,7328 ,333 ,6032 ,9035 ,9475 ,8073 ,4560 ,4225 ,3964 ,3679 ,7491 ,6456 ,4745 ,7930 ,235 ,4420 ,8953 ,7735 ,8505 ,6333 ,6714 ,4196 ,959 ,5520 ,4654 ,1618 ,2649 ,3607 ,2014 ,8635 ,9907 ,149 ,7235 ,2186 ,4943 ,9250 ,1506 ,5329 ,5973 ,7982 ,8135 ,2160 ,5194 ,6183 ,3989 ,217 ,9331 ,9587 ,1641 ,9690 ,7791 ,3574 ,7425 ,4250 ,5351 ,2956 ,4847 ,2587 ,7271 ,9885 ,8622 ,700 ,5059 ,9520 ,7837 ,4736 ,8443 ,5732 ,5692 ,3516 ,1110 ,3100 ,271 ,9941 ,3468 ,445 ,82 ,4777 ,5944 ,7495 ,2942 ,3138 ,9415 ,4191 ,5550 ,6163 ,3282 ,8107 ,603 ,9836 ,9155 ,5317 ,6184 ,4035 ,8602 ,7609 ,986 ,2796 ,417 ,9495 ,2843 ,3423 ,9833 ,6441 ,2525 ,7619 ,9713 ,1184 ,2682 ,2358 ,7502 ,5119 ,430 ,1643 ,4635 ,5092 ,838 ,9305 ,967 ,4896 ,2029 ,3475 ,7407 ,390 ,9239 ,6023 ,3768 ,5656 ,8916 ,231 ,4893 ,7048 ,8297 ,3700 ,8190 ,1593 ,9443 ,2602 ,2910 ,4787 ,9908 ,3551 ,3322 ,4835 ,7721 ,4299 ,991 ,7765 ,7172 ,2588 ,4400 ,6848 ,2846 ,7004 ,1327 ,6447 ,4993 ,1121 ,3471 ,93 ,5581 ,875 ,4323 ,7940 ,7871 ,337 ,7120 ,1360 ,3026 ,8565 ,911 ,615 ,8186 ,3532 ,2495 ,5337 ,9930 ,1893 ,5220 ,6074 ,6667 ,5014 ,4361 ,9374 ,5603 ,8589 ,7822 ,4376 ,7966 ,9567 ,6814 ,3975 ,845 ,5544 ,5279 ,853 ,2763 ,6846 ,4855 ,8828 ,971 ,4870 ,3623 ,4555 ,7189 ,2753 ,2827 ,4218 ,3963 ,4874 ,5000 ,5682 ,9760 ,6772 ,5826 ,4320 ,4113 ,2234 ,8683 ,5056 ,8111 ,9569 ,3923 ,1195 ,6126 ,9403 ,7693 ,2759 ,373 ,4667 ,7325 ,5197 ,5850 ,9672 ,7403 ,5773 ,3116 ,2074 ,3459 ,5545 ,9694 ,1387 ,2369 ,7986 ,4203 ,6282 ,1228 ,3130 ,2113 ,3203 ,7377 ,1080 ,2684 ,2907 ,4498 ,4972 ,7063 ,3109 ,7416 ,3800 ,5596 ,9020 ,180 ,8123 ,9386 ,209 ,738 ,6515 ,1742 ,4781 ,9678 ,2269 ,7162 ,3755 ,6114 ,4735 ,8262 ,9722 ,2068 ,4261 ,3535 ,1535 ,1900 ,9793 ,1263 ,8481 ,5894 ,2857 ,2570 ,8137 ,5273 ,5635 ,4906 ,1600 ,689 ,2067 ,7281 ,3969 ,72 ,4628 ,9955 ,5824 ,930 ,7920 ,8863 ,9981 ,6625 ,3678 ,2792 ,2559 ,4925 ,3106 ,2704 ,5828 ,3357 ,2308 ,164 ,4419 ,6346 ,7856 ,9417 ,8570 ,8536 ,9141 ,7640 ,793 ,5760 ,8609 ,9865 ,3672 ,1331 ,7953 ,1613 ,824 ,6254 ,8353 ,8407 ,6525 ,8332 ,4586 ,9582 ,4841 ,7806 ,9859 ,8736 ,1188 ,9030 ,281 ,7577 ,6404 ,6322 ,9556 ,9458 ,5168 ,4723 ,3094 ,2523 ,9332 ,2824 ,8159 ,6685 ,5542 ,1114 ,1334 ,8124 ,4206 ,3462 ,5694 ,1844 ,9434 ,421 ,3776 ,8245 ,85 ,6996 ,6964 ,5246 ,2413 ,4829 ,4636 ,522 ,7012 ,2963 ,8032 ,2178 ,2201 ,7531 ,5749 ,2642 ,9094 ,2230 ,4923 ,4449 ,1521 ,8967 ,1354 ,276 ,2483 ,7649 ,4765 ,3075 ,3780 ,8035 ,9459 ,5801 ,1380 ,5966 ,1283 ,6934 ,8069 ,6989 ,4689 ,3935 ,1672 ,6551 ,335 ,748 ,606 ,9771 ,3422 ,1068 ,9032 ,5471 ,3128 ,9819 ,1902 ,6571 ,6284 ,7217 ,5243 ,2793 ,6973 ,2460 ,4836 ,8154 ,3764 ,5058 ,6783 ,4490 ,6824 ,7695 ,3269 ,2880 ,2621 ,2468 ,2619 ,7537 ,2650 ,198 ,8475 ,3967 ,8996 ,1957 ,8729 ,9069 ,429 ,1722 ,3606 ,7904 ,8279 ,4489 ,7167 ,7784 ,9454 ,8057 ,470 ,2653 ,8725 ,4359 ,2958 ,9839 ,8439 ,9611 ,8059 ,3765 ,9805 ,8133 ,3473 ,6576 ,5943 ,2972 ,4670 ,8104 ,1979 ,5802 ,1731 ,7775 ,3107 ,2378 ,1333 ,8296 ,9649 ,345 ,6881 ,6500 ,9368 ,2482 ,2955 ,2039 ,2317 ,5476 ,882 ,666 ,2964 ,5516 ,9789 ,5676 ,8844 ,2237 ,4223 ,862 ,4456 ,547 ,7875 ,9249 ,4324 ,7935 ,7534 ,194 ,9262 ,8281 ,514 ,7399 ,5606 ,4908 ,5343 ,4761 ,964 ,4563 ,3321 ,1416 ,589 ,5481 ,4065 ,8209 ,8340 ,4009 ,8292 ,7501 ,3584 ,6655 ,3904 ,2902 ,2171 ,2779 ,1526 ,8051 ,4251 ,1786 ,5367 ,1362 ,5099 ,1027 ,3642 ,1008 ,8515 ,6730 ,6290 ,7984 ,7383 ,3890 ,9932 ,2836 ,2228 ,9685 ,3231 ,1176 ,9894 ,2461 ,561 ,7045 ,7599 ,3348 ,3993 ,817 ,331 ,2421 ,5763 ,8194 ,233 ,2981 ,4210 ,4122 ,2277 ,7231 ,4982 ,4104 ,3808 ,8579 ,8721 ,1437 ,2609 ,1642 ,3079 ,9011 ,6654 ,4159 ,6750 ,4123 ,1653 ,9050 ,3381 ,3514 ,6791 ,3973 ,9592 ,5632 ,2737 ,6062 ,3086 ,2049 ,9629 ,8349 ,4673 ,9097 ,9549 ,6852 ,9871 ,1104 ,6599 ,5362 ,5037 ,6508 ,7292 ,1948 ,7090 ,6904 ,2982 ,2360 ,2223 ,6789 ,3633 ,4326 ,9959 ,1552 ,1405 ,9751 ,996 ,218 ,9281 ,9543 ,1292 ,5649 ,8705 ,7358 ,9951 ,8866 ,3625 ,5565 ,6235 ,409 ,4963 ,6650 ,7584 ,7906 ,2979 ,7597 ,3063 ,3659 ,192 ,7547 ,9970 ,2434 ,8382 ,2959 ,3110 ,7244 ,248 ,3451 ,4806 ,4091 ,5799 ,3753 ,389 ,5621 ,9406 ,2864 ,5627 ,8593 ,7602 ,9075 ,6950 ,9359 ,2967 ,3994 ,8014 ,8239 ,9026 ,3902 ,3756 ,9874 ,5615 ,6544 ,3029 ,7845 ,6774 ,7950 ,2966 ,9588 ,8946 ,3720 ,3286 ,2210 ,9940 ,3186 ,2034 ,126 ,5748 ,9455 ,4634 ,1838 ,8277 ,437 ,5383 ,1041 ,4322 ,9721 ,8460 ,5609 ,664 ,4255 ,2192 ,5103 ,4357 ,6260 ,3761 ,8760 ,1486 ,6276 ,4248 ,7384 ,8768 ,5903 ,9127 ,4208 ,4106 ,8046 ,1725 ,5010 ,69 ,9126 ,7250 ,7719 ,4815 ,2292 ,8173 ,5412 ,6908 ,2006 ,4110 ,9138 ,4071 ,4487 ,713 ,6385 ,7731 ,3931 ,8883 ,9243 ,9630 ,778 ,2130 ,4638 ,9027 ,7712 ,2336 ,3641 ,3382 ,9179 ,6401 ,3839 ,2723 ,5587 ,765 ,6038 ,9352 ,8068 ,1131 ,384 ,6819 ,6059 ,1083 ,8814 ,7036 ,7538 ,565 ,5598 ,2331 ,1119 ,9625 ,2841 ,3578 ,7032 ,9300 ,4375 ,3920 ,579 ,970 ,9260 ,8856 ,6832 ,2450 ,6920 ,2272 ,3146 ,7261 ,8005 ,6366 ,1782 ,7792 ,8997 ,9438 ,7443 ,6718 ,9041 ,9085 ,5404 ,2778 ,938 ,2214 ,9366 ,4454 ,3341 ,6303 ,8954 ,7754 ,5745 ,3507 ,3400 ,481 ,2019 ,479 ,7674 ,443 ,9770 ,9872 ,8930 ,8363 ,8688 ,1508 ,5604 ,6403 ,5136 ,432 ,4238 ,822 ,3220 ,2787 ,270 ,3906 ,6626 ,7191 ,7322 ,5098 ,5991 ,2416 ,9579 ,4990 ,1262 ,9370 ,9099 ,678 ,5076 ,6197 ,6138 ,4976 ,5410 ,5487 ,8531 ,5214 ,7933 ,9533 ,5193 ,7558 ,3452 ,4799 ,9856 ,406 ,9702 ,4791 ,8940 ,6703 ,7193 ,1476 ,7391 ,8825 ,9342 ,523 ,8379 ,7912 ,317 ,4831 ,5740 ,7780 ,4093 ,4457 ,8872 ,6709 ,3242 ,2392 ,7528 ,6513 ,7282 ,2366 ,263 ,3664 ,885 ,2715 ,9697 ,1818 ,6436 ,2350 ,3292 ,9376 ,2625 ,447 ,9572 ,2597 ,5688 ,3368 ,5176 ,8192 ,4599 ,7748 ,7959 ,2498 ,5803 ,4568 ,1729 ,7475 ,9954 ,3482 ,4330 ,6910 ,6156 ,4713 ,2151 ,3015 ,9558 ,9189 ,7673 ,7759 ,7029 ,7877 ,1696 ,5185 ,9647 ,2909 ,7320 ,8838 ,5488 ,2984 ,4747 ,9207 ,5315 ,6239 ,8508 ,9523 ,2862 ,3905 ,359 ,9540 ,1057 ,6945 ,1501 ,9948 ,9211 ,3590 ,6433 ,5102 ,7587 ,7431 ,7386 ,5783 ,1181 ,7293 ,2500 ,5151 ,8472 ,5025 ,7563 ,6093 ,8392 ,5927 ,3582 ,1788 ,4522 ,5518 ,425 ,9617 ,6770 ,7516 ,976 ,3522 ,4603 ,1415 ,493 ,7388 ,4812 ,3224 ,3366 ,2901 ,4819 ,4755 ,3874 ,2971 ,6440 ,8020 ,7657 ,6101 ,3127 ,6570 ,7437 ,5600 ,2125 ,8945 ,5050 ,7016 ,8571 ,9487 ,2135 ,7000 ,2133 ,9995 ,823 ,4478 ,1175 ,7133 ,9573 ,8430 ,79 ,2675 ,7306 ,3862 ,8103 ,2222 ,4387 ,4442 ,3149 ,5959 ,8797 ,6077 ,2515 ,22 ,6867 ,7373 ,4473 ,3615 ,4263 ,9471 ,3227 ,7474 ,4474 ,4377 ,5782 ,732 ,45 ,4269 ,9163 ,9170 ,5915 ,2089 ,9759 ,6886 ,150 ,8889 ,1804 ,7969 ,2330 ,9607 ,5558 ,7214 ,5914 ,1570 ,7567 ,8525 ,6318 ,3019 ,9483 ,8129 ,3085 ,9055 ,6728 ,4085 ,8290 ,8056 ,144 ,1005 ,9925 ,9219 ,8972 ,9353 ,3894 ,6216 ,7353 ,5368 ,9863 ,4334 ,7869 ,3396 ,837 ,7405 ,9042 ,1801 ,4253 ,5552 ,315 ,6986 ,224 ,4235 ,6869 ,1573 ,6882 ,1707 ,4037 ,3537 ,4912 ,8630 ,6413 ,114 ,7009 ,593 ,3170 ,3216 ,2424 ,3599 ,3986 ,8420 ,6426 ,1907 ,4198 ,3971 ,1117 ,585 ,6274 ,8720 ,7636 ,7851 ,5729 ,8200 ,8801 ,2672 ,6361 ,8255 ,1885 ,5575 ,8364 ,3169 ,1234 ,7104 ,2692 ,5442 ,1515 ,9794 ,1603 ,4342 ,8773 ,4078 ,7642 ,4254 ,6289 ,5188 ,6460 ,686 ,9117 ,3657 ,2380 ,1947 ,6453 ,4752 ,6870 ,9503 ,7990 ,9200 ,8410 ,4661 ,6416 ,4837 ,6803 ,5456 ,2282 ,8701 ,3088 ,2000 ,1011 ,6493 ,9078 ,5062 ,1299 ,8320 ,6792 ,1678 ,3296 ,2047 ,7713 ,9980 ,6064 ,2537 ,1736 ,4030 ,502 ,4857 ,6845 ,1689 ,4643 ,7079 ,1714 ,7253 ,5352 ,4190 ,3222 ,4141 ,1045 ,5515 ,461 ,1726 ,9652 ,5563 ,826 ,4055 ,9901 ,7136 ,617 ,1458 ,153 ,9052 ,3960 ,4529 ,5212 ,2018 ,690 ,7701 ,9081 ,2872 ,2842 ,583 ,5566 ,2147 ,5330 ,8289 ,7169 ,8881 ,3698 ,2987 ,369 ,1467 ,9113 ,9465 ,4803 ,8233 ,6391 ,601 ,8188 ,5275 ,5064 ,2502 ,8885 ,5148 ,6663 ,8067 ,1976 ,987 ,8377 ,3688 ,1759 ,5233 ,9868 ,4241 ,8485 ,8951 ,948 ,5088 ,7314 ,1933 ,979 ,5992 ,9824 ,166 ,2109 ,5216 ,9479 ,7334 ,1988 ,8636 ,6123 ,3990 ,8495 ,7247 ,3921 ,798 ,9755 ,8446 ,8170 ,7999 ,4411 ,3168 ,4268 ,1004 ,4969 ,679 ,2830 ,2764 ,3594 ,4349 ,6261 ,210 ,7929 ,9730 ,720 ,3762 ,5993 ,7062 ,6315 ,8136 ,8237 ,9076 ,6796 ,797 ,1583 ,7680 ,3454 ,1805 ,6348 ,5947 ,825 ,6779 ,9470 ,812 ,9199 ,2 ,9524 ,8808 ,4252 ,9515 ,2221 ,1276 ,1439 ,6985 ,2015 ,3497 ,1699 ,7031 ,2180 ,6496 ,121 ,5100 ,8604 ,4570 ,1625 ,5253 ,1485 ,4911 ,5116 ,3043 ,7669 ,5757 ,3819 ,4351 ,1061 ,6367 ,8330 ,769 ,3184 ,3053 ,8087 ,1698 ,1039 ,9680 ,289 ,5309 ,6495 ,6830 ,5132 ,6699 ,4872 ,6838 ,1870 ,7298 ,6553 ,1108 ,2346 ,8564 ,5743 ,1259 ,1708 ,56 ,1912 ,4453 ,9904 ,8166 ,4601 ,8955 ,8079 ,928 ,3673 ,2490 ,7147 ,8887 ,671 ,3554 ,61 ,1677 ,330 ,7060 ,1167 ,4687 ,8563 ,188 ,1402 ,4408 ,1937 ,3353 ,9047 ,5873 ,4794 ,2208 ,8215 ,2487 ,4900 ,3076 ,6277 ,5465 ,2771 ,5661 ,4528 ,6444 ,9827 ,4989 ,1982 ,4368 ,1682 ,7907 ,5169 ,966 ,6877 ,3192 ,58 ,5237 ,2677 ,3237 ,4523 ,1760 ,3425 ,2158 ,2839 ,7662 ,2889 ,7586 ,8988 ,7799 ,2896 ,495 ,6939 ,5805 ,67 ,3463 ,2025 ,4464 ,5972 ,6678 ,8739 ,2312 ,3436 ,2396 ,9422 ,6190 ,4303 ,9497 ,1227 ,4699 ,3413 ,5459 ,6864 ,5179 ,2037 ,4423 ,6702 ,9817 ,4520 ,7448 ,4192 ,5055 ,7461 ,8025 ,3404 ,1316 ,8207 ,7218 ,313 ,1404 ,6000 ,7274 ,3429 ,454 ,9360 ,8633 ,9631 ,9382 ,5324 ,749 ,9205 ,9936 ,3544 ,6863 ,6673 ,7668 ,8785 ,9659 ,387 ,3801 ,3233 ,3377 ,6270 ,352 ,7469 ,8833 ,1411 ,557 ,3433 ,8153 ,7807 ,7202 ,4072 ,6173 ,8545 ,4187 ,2803 ,5965 ,6499 ,7589 ,4022 ,1843 ,6107 ,6767 ,6410 ,9919 ,1627 ,2485 ,8 ,7432 ,2243 ,908 ,941 ,1757 ,8183 ,5812 ,6935 ,8093 ,874 ,924 ,4875 ,7145 ,6324 ,876 ,4991 ,7406 ,6668 ,3658 ,4979 ,1390 ,542 ,6030 ,6529 ,2922 ,4102 ,3804 ,8935 ,9197 ,9778 ,4390 ,6422 ,1679 ,1748 ,7026 ,6876 ,303 ,2505 ,6266 ,3741 ,95 ,7198 ,9390 ,7057 ,1425 ,3403 ,8566 ,4784 ,1755 ,6734 ,4975 ,653 ,2604 ,2727 ,1436 ,7708 ,4668 ,6056 ,3004 ,8583 ,8652 ,6210 ,9416 ,9501 ,2572 ,2309 ,9831 ,8360 ,696 ,8690 ,328 ,413 ,4150 ,1177 ,8398 ,8342 ,4740 ,4319 ,3774 ,6483 ,8457 ,5359 ,1107 ,2747 ,8404 ,4773 ,5896 ,1241 ,2475 ,819 ,7006 ,580 ,5436 ,5570 ,3197 ,5386 ,6974 ,9195 ,6371 ,1149 ,2203 ,7622 ,9602 ,8415 ,8685 ,4950 ,109 ,348 ,1821 ,5411 ,6550 ,9650 ,8369 ,3361 ,7931 ,87 ,4289 ,2931 ,4186 ,3031 ,6386 ,3316 ,9627 ,1833 ,6962 ,5086 ,2405 ,2045 ,7053 ,4312 ,6221 ,2879 ,1401 ,2420 ,5815 ,3595 ,6376 ,8285 ,5012 ,851 ,163 ,8280 ,6080 ,5699 ,5878 ,3373 ,2593 ,8908 ,2169 ,1711 ,2467 ,6425 ,3014 ,4719 ,693 ,4820 ,7434 ,6952 ,6558 ,3812 ,2611 ,2478 ,5030 ,2772 ,185 ,6701 ,4008 ,3608 ,6478 ,755 ,515 ,9845 ,5503 ,1763 ,7264 ,7371 ,6115 ,7613 ,5189 ,9494 ,2983 ,5937 ,363 ,1794 ,5393 ,4015 ,1321 ,7757 ,5250 ,7124 ,7379 ,2868 ,4394 ,7105 ,5069 ,40 ,8532 ,6309 ,836 ,850 ,5290 ,8336 ,8607 ,9815 ,2325 ,4096 ,2456 ,6517 ,3668 ,506 ,3954 ,2784 ,3112 ,9628 ,5451 ,6742 ,5313 ,8977 ,6256 ,935 ,9516 ,1408 ,8053 ,586 ,2562 ,8370 ,9201 ,8750 ,1465 ,8731 ,8180 ,8249 ,1753 ,5292 ,4905 ,780 ,4193 ,5573 ,8019 ,9316 ,8325 ,3234 ,1478 ,8461 ,7536 ,2205 ,2767 ,8969 ,7417 ,5534 ,1638 ,8149 ,9931 ,9453 ,9662 ,7868 ,6543 ,9238 ,2891 ,4864 ,6657 ,7370 ,295 ,8645 ,3649 ,9111 ,3336 ,3077 ,8772 ,1520 ,2300 ,5785 ,5458 ,7310 ,1739 ,5747 ,376 ,7645 ,848 ,1384 ,5299 ,7041 ,2814 ,6104 ,6651 ,4414 ,8224 ,5800 ,4183 ,8799 ,7991 ,8174 ,6710 ,2623 ,8770 ,4181 ,4366 ,1687 ,957 ,9593 ,9927 ,740 ,4534 ,3238 ,8795 ,9181 ,6177 ,5358 ,4607 ,68 ,9114 ,8229 ,770 ,8001 ,357 ,1150 ,6111 ,8538 ,3018 ,5628 ,8597 ,2367 ,3958 ,7579 ,15 ,6674 ,8606 ,5571 ,4399 ,5139 ,5932 ,4581 ,1277 ,4047 ,1409 ,7476 ,7747 ,1896 ,1576 ,3873 ,9902 ,5371 ,2696 ,6212 ,4952 ,8487 ,460 ,189 ,1214 ,4004 ,1719 ,7561 ,4566 ,9514 ,3039 ,7428 ,2631 ,3255 ,5643 ,9116 ,6607 ,9561 ,2466 ,8824 ,1317 ,3331 ,3631 ,813 ,1449 ,7819 ,7655 ,7268 ,6925 ,8592 ,1318 ,4971 ,640 ,768 ,6634 ,9129 ,6593 ,7335 ,1798 ,4986 ,1908 ,1971 ,4153 ,4775 ,9135 ,5568 ,5041 ,5308 ,9439 ,9851 ,3119 ,646 ,9843 ,4659 ,8339 ,4471 ,6278 ,8662 ,2914 ,9008 ,8165 ,7983 ,1784 ,5926 ,2244 ,643 ,7600 ,5939 ,3593 ,1836 ,6052 ,8488 ,2834 ,6861 ,9512 ,5158 ,9822 ,7919 ,6998 ,7365 ,1891 ,5028 ,35 ,7034 ,3369 ,5231 ,5872 ,4428 ,7670 ,3035 ,5797 ,1563 ,1413 ,9615 ,1651 ,5768 ,9340 ,1934 ,2886 ,1180 ,3080 ,4039 ,5855 ,1539 ,1391 ,9811 ,5424 ,871 ,2991 ,6423 ,6747 ,1756 ,4750 ,2860 ,2345 ,5527 ,3724 ,3515 ,951 ,2393 ,5408 ,529 ,9230 ,5155 ,7675 ,4446 ,7182 ,3200 ,9021 ,3040 ,3239 ,604 ,4703 ,995 ,2105 ,9053 ,1961 ,2279 ,6799 ,41 ,8298 ,2311 ,8530 ,9339 ,7728 ,6898 ,8027 ,7891 ,5574 ,6588 ,9258 ,913 ,6522 ,9107 ,9953 ,6008 ,5779 ,8151 ,1888 ,3859 ,4882 ,674 ,9928 ,5987 ,4277 ,3194 ,2183 ,9259 ,9301 ,2394 ,5029 ,1754 ,3576 ,3749 ,6582 ,1518 ,8258 ,648 ,4738 ,1010 ,347 ,424 ,7628 ,8055 ,692 ,9797 ,7497 ,6341 ,4582 ,5764 ,9648 ,9945 ,8445 ,2853 ,4396 ,5395 ,1981 ,5861 ,2322 ,9298 ,1126 ,6813 ,3570 ,2373 ,2194 ,994 ,8678 ,325 ,9624 ,8599 ,5134 ,2926 ,5340 ,7030 ,6297 ,530 ,9333 ,777 ,5504 ,1192 ,1056 ,3193 ,5298 ,9156 ,4779 ,6084 ,6860 ,7947 ,3712 ,4216 ,9109 ,5240 ,6932 ,9401 ,282 ,6206 ,5204 ,3997 ,6286 ,200 ,2592 ,2102 ,4617 ,3183 ,5852 ,6586 ,5513 ,9877 ,4090 ,2506 ,4020 ,1945 ,6301 ,1275 ,1925 ,6237 ,543 ,400 ,9861 ,3172 ,9614 ,6669 ,3731 ,5744 ,310 ,5551 ,9233 ,6375 ,8226 ,9292 ,6829 ,3208 ,5369 ,1532 ,4615 ,110 ,6247 ,1811 ,5735 ,8680 ,1511 ,2706 ,2353 ,1081 ,3704 ,1710 ,2565 ,2307 ,4029 ,9362 ,9096 ,3757 ,6364 ,2235 ,8350 ,7854 ,3797 ,3932 ,7066 ,9505 ,8874 ,8871 ,1166 ,9732 ,4867 ,6871 ,5690 ,8816 ,1086 ,9971 ,1693 ,3565 ,2539 ,6007 ,3866 ,312 ,1544 ,5589 ,608 ,8689 ,944 ,978 ,4883 ,7820 ,8202 ,9235 ,132 ,2807 ,8737 ,9274 ,3637 ,2123 ,1014 ,2267 ,9810 ,2162 ,4656 ,7252 ,3284 ,9377 ,9351 ,2946 ,6134 ,8862 ,6224 ,856 ,7853 ,3581 ,4698 ,3670 ,6480 ,5888 ,9725 ,5736 ,4865 ,3736 ,5073 ,6039 ,8054 ,4179 ,5327 ,8875 ,90 ,7863 ,3236 ,735 ,6706 ,1124 ,6923 ,9684 ,3491 ,2600 ,8982 ,342 ,7768 ,6854 ,208 ,2092 ,6963 ,2313 ,1655 ,4640 ,5270 ,9436 ,6359 ,1064 ,1582 ,2721 ,4418 ,5631 ,3121 ,1936 ,4701 ,8702 ,6987 ,910 ,5038 ,4363 ,1002 ,1864 ,3523 ,9246 ,4997 ,1516 ,2048 ,6450 ,1033 ,507 ,7798 ,4140 ,9184 ,5196 ,4826 ,5477 ,8524 ,8674 ,9795 ,8344 ,7667 ,6536 ,9565 ,3995 ,3743 ,2598 ,6463 ,8923 ,3871 ,3225 ,5255 ,123 ,8891 ,7033 ,4887 ,1059 ,702 ,7044 ,5258 ,6781 ,5891 ,2176 ,1178 ,3275 ,3944 ,3134 ,6826 ,2832 ,4088 ,3981 ,1903 ,4842 ,9975 ,9051 ,6931 ,9387 ,1608 ,8401 ,6470 ,5833 ,8436 ,1379 ,9917 ,9616 ,7113 ,64 ,1302 ,8782 ,5306 ,5288 ,4175 ,8016 ,4505 ,6058 ,5950 ,6308 ,1296 ,9295 ,2809 ,895 ,5245 ,309 ,2546 ,8006 ,1254 ,3129 ,6853 ,4942 ,7339 ,8839 ,5659 ,3013 ,9105 ,1839 ,3717 ,9335 ,8864 ,7961 ,1309 ,1482 ,1856 ,8355 ,2480 ,8643 ,8482 ,9054 ,2616 ,4868 ,8730 ,7052 ,918 ,5005 ,8484 ,1494 ,7450 ,9203 ,620 ,1574 ,6780 ,5762 ,8790 ,3766 ,4281 ,9957 ,9082 ,4921 ,2179 ,1878 ,9696 ,9428 ,2949 ,6763 ,8496 ,8348 ,7126 ,1082 ,7445 ,5291 ,1668 ,5460 ,3326 ,6530 ,5401 ,639 ,3343 ,1645 ,3592 ,7829 ,9247 ,4304 ,8518 ,2273 ,989 ,1355 ,9679 ,2305 ,3370 ,1716 ,1464 ,1632 ,4280 ,1568 ,7226 ,3685 ,1815 ,8823 ,2385 ,5190 ,5348 ,2406 ,9306 ,9312 ,7347 ,4608 ,560 ,5391 ,3857 ,6012 ,2082 ,5708 ,1477 ,5683 ,8167 ,3298 ,746 ,4271 ,1140 ,8870 ,8427 ,6238 ,3418 ,3693 ,4014 ,7962 ,9741 ,3263 ,8211 ,9711 ,7022 ,4559 ,3087 ,1313 ,3703 ,743 ,6653 ,2001 ,9924 ,9358 ,6926 ,7480 ,6485 ,4620 ,2766 ,5405 ,4103 ,8212 ,3790 ,6811 ,2510 ,172 ,831 ,7519 ,3844 ,9792 ,4537 ,9717 ,934 ,2554 ,2990 ,518 ,5344 ,182 ,6439 ,2445 ,5871 ,2661 ,3501 ,6805 ,5968 ,1930 ,4172 ,9525 ,6827 ,8695 ,5879 ,8162 ,6438 ,8911 ,809 ,3431 ,6424 ,2831 ,4437 ,7977 ,1055 ,5498 ,4562 ,1036 ,3182 ,594 ,8548 ,9829 ,7025 ,2332 ,9364 ,744 ,6336 ,4144 ,4580 ,5622 ,1624 ,1661 ,4725 ,6940 ,7138 ,8148 ,5842 ,7076 ,3270 ,8628 ,3095 ,5626 ,8438 ,1187 ,2848 ,983 ,9346 ,8092 ,7296 ,284 ,3622 ,9987 ,694 ,2781 ,5986 ,1650 ,2050 ,2794 ,2783 ,488 ,4402 ,431 ,1854 ,8295 ,3 ,1746 ,6127 ,5302 ,7440 ,1817 ,9555 ,7590 ,891 ,9809 ,5641 ,1926 ,9308 ,2071 ,1892 ,9419 ,6807 ,5860 ,5228 ,2702 ,5869 ,5530 ,1935 ,5640 ,4895 ,70 ,3750 ,2348 ,6567 ,8038 ,7395 ,4036 ,3023 ,1889 ,5297 ,3856 ,3983 ,5024 ,7515 ,799 ,4436 ,8963 ,7332 ,8244 ,5715 ,745 ,7709 ,9537 ,6050 ,4133 ,3852 ,5704 ,1751 ,2321 ,4825 ,7117 ,8042 ,9848 ,510 ,8086 ,8372 ,392 ,4404 ,6786 ,6549 ,5247 ,4545 ,6724 ,1958 ,5191 ,2585 ,3058 ,4962 ,2315 ,2290 ,7242 ,1559 ,5294 ,757 ,5955 ,7794 ,7087 ,916 ,8334 ,8771 ,8964 ,1701 ,6267 ,7831 ,292 ,7455 ,6624 ,4572 ,595 ,1350 ,5071 ,8746 ,6430 ,2389 ,7037 ,997 ,1129 ,5933 ,3223 ,6384 ,2143 ,5021 ,9498 ,2686 ,2529 ,2920 ,1962 ,2381 ,7451 ,6191 ,7880 ,3064 ,8269 ,5070 ,2516 ,7715 ,7643 ,9006 ,708 ,2760 ,6300 ,5938 ,3235 ,6999 ,3416 ,9720 ,9039 ,1007 ,1143 ,7802 ,641 ,6981 ,7985 ,7764 ,4907 ,8694 ,8761 ,1024 ,2648 ,526 ,4480 ,9646 ,1980 ,7156 ,3033 ,9705 ,6240 ,2524 ,3836 ,4057 ,6912 ,8841 ,634 ,5679 ,2090 ,5951 ,370 ,736 ,9758 ,4028 ,3502 ,7746 ,2069 ,7848 ,7493 ,7081 ,3253 ,9689 ,311 ,3793 ,1314 ,5107 ,4724 ,1435 ,9768 ,5716 ,3145 ,1647 ,7152 ,9757 ,7280 ,1246 ,9638 ,156 ,167 ,1330 ,8047 ,1932 ,2328 ,6467 ,2491 ,7460 ,8158 ,5620 ,4265 ,4424 ,8312 ,906 ,9192 ,6310 ,7508 ,8884 ,8095 ,4951 ,5999 ,9043 ,9594 ,6810 ,6229 ,2978 ,741 ,4257 ,8738 ,4105 ,5807 ,4542 ,766 ,5437 ,7548 ,4194 ,9426 ,7726 ,4558 ,4554 ,2131 ,3770 ,1112 ,8480 ,3254 ,922 ,6736 ,4813 ,4790 ,9092 ,9982 ,2655 ,7733 ,1956 ,2722 ,7665 ,6024 ,5382 ,739 ,8665 ,9905 ,9560 ,3529 ,3415 ,7562 ,7352 ,711 ,7376 ,2078 ,1734 ,9993 ,5705 ,9539 ,3798 ,9257 ,8586 ,2718 ,4949 ,6637 ,9603 ,8675 ,2923 ,680 ,3124 ,2239 ,4228 ,8264 ,4588 ,3854 ,2601 ,6070 ,9432 ,3006 ,7215 ,2016 ,9385 ,3198 ,6378 ,6198 ,5804 ,8120 ,7488 ,5670 ,1365 ,5988 ,9674 ,7150 ,2916 ,4378 ,6119 ,2903 ,8957 ,6146 ,3600 ,8965 ,5390 ,7251 ,8483 ,8010 ,3426 ,9986 ,3325 ,4981 ,6194 ,4602 ,7633 ,8112 ,423 ,1841 ,8835 ,8390 ,3936 ,4460 ,521 ,334 ,3647 ,4393 ,1141 ,1268 ,3285 ,4369 ,6976 ,3351 ,5531 ,1828 ,5660 ,3791 ,2026 ,8991 ,6179 ,6639 ,7630 ,6313 ,3115 ,269 ,5446 ,8021 ,6565 ,4163 ,7302 ,3525 ,3547 ,8359 ,5480 ,7943 ,7677 ,9313 ,5998 ,3912 ,729 ,2566 ,6124 ,1509 ,575 ,5691 ,4336 ,6090 ,9319 ,4173 ,8818 ,4587 ,1429 ,4401 ,5921 ,5798 ,6402 ,1626 ,5475 ,1954 ,8943 ,7357 ,2591 ,9467 ,8931 ,9823 ,568 ,1484 ,5494 ,128 ,2170 ,3618 ,1764 ,5200 ,8638 ,2357 ,5977 ,5662 ,7381 ,7093 ,7196 ,3783 ,5052 ,4143 ,5595 ,1092 ,1852 ,9190 ,2821 ,647 ,7804 ,6488 ,7771 ,7629 ,5556 ,7598 ,2613 ,5072 ,3930 ,9482 ,1581 ,1745 ,2576 ,3789 ,9118 ,3823 ,2782 ,4672 ,1414 ,7755 ,9323 ,8815 ,1623 ,8618 ,2329 ,8257 ,2521 ,4697 ,5123 ,8442 ,4768 ,1923 ,5159 ,9606 ,1453 ,9048 ,4236 ,1997 ,9926 ,6619 ,2549 ,9637 ,242 ,6236 ,1835 ,8624 ,372 ,7504 ,6241 ,7987 ,7203 ,6363 ,1102 ,7479 ,3104 ,371 ,5611 ,6314 ,3528 ,7639 ,3872 ,4222 ,4757 ,9077 ,3293 ,8938 ,6569 ,7018 ,5557 ,7349 ,3156 ,3980 ,4858 ,3869 ,1447 ,6245 ,7543 ,2798 ,119 ,616 ,1599 ,5634 ,4052 ,2250 ,8070 ,5507 ,1169 ,7457 ,1348 ,1304 ,9779 ,9620 ,673 ,6633 ,9814 ,7874 ,3372 ,1383 ,3788 ,1323 ,4059 ,6801 ,2110 ,8858 ,8658 ,5655 ,7426 ,8088 ,1084 ,3579 ,1640 ,8308 ,4503 ,9277 ,9992 ,8432 ,4158 ,9997 ,6902 ,3951 ,9909 ,2552 ,339 ,9640 ,8247 ,1529 ,5157 ,8810 ,5931 ,3853 ,8958 ,9701 ,8550 ,4838 ,1964 ,3919 ,3609 ,9900 ,5602 ,6086 ,5011 ,9745 ,3828 ,197 ,3992 ,6076 ,2280 ,742 ,6360 ,5164 ,6172 ,5533 ,8030 ,5473 ,5904 ,5043 ,3834 ,1709 ,9664 ,1230 ,9766 ,7823 ,4880 ,9700 ,6573 ,687 ,7879 ,2104 ,8263 ,7413 ,8544 ,4915 ,855 ,1498 ,500 ,1996 ,5775 ,4494 ,5035 ,1290 ,5095 ,7968 ,3498 ,1921 ,7096 ,2668 ,7080 ,5849 ,1200 ,8309 ,4624 ,1183 ,7740 ,1261 ,7697 ,4711 ,5995 ,8847 ,5171 ,8807 ,9692 ,7980 ,6735 ,130 ,800 ,6214 ,9073 ,1541 ,174 ,7359 ,8276 ,7687 ,5646 ,8405 ,8901 ,8351 ,8878 ,8449 ,3653 ,7844 ,7027 ,8125 ,8113 ,9661 ,8682 ,4593 ,9425 ,6355 ,3443 ,8265 ,9177 ,8980 ,4407 ,4207 ,9535 ,1146 ,7727 ,3338 ,3449 ,4621 ,8083 ,3926 ,8048 ,477 ,3141 ,127 ,3347 ,7540 ,1832 ,6380 ,6954 ,8462 ,3317 ,8657 ,3970 ,4848 ,7277 ,1394 ,8539 ,5274 ,8132 ,4788 ,6078 ,7976 ,4552 ,1999 ,8899 ,6316 ,9969 ,5463 ,998 ,3380 ,2569 ,5130 ,4288 ,937 ,4465 ,9623 ,4716 ,2612 ,9473 ,6584 ,6457 ,1609 ,5738 ,2663 ,7102 ,3899 ,5665 ,4033 ,4169 ,5941 ,2324 ,2260 ,5984 ,9724 ,7366 ,8315 ,8435 ,2676 ,6466 ,3734 ,1695 ,7361 ,4980 ,1644 ,2415 ,5772 ,6612 ,6757 ,2410 ,9327 ,5177 ,1417 ,2952 ,7557 ,5831 ,5082 ,3727 ,792 ,1720 ,1556 ,6691 ,1190 ,7581 ,2873 ,5445 ,1781 ,152 ,4070 ,6966 ,8324 ,8667 ,8299 ,6617 ,3500 ,1884 ,5378 ,952 ,2805 ,6199 ,5930 ,6108 ,1522 ,1904 ,9788 ,1472 ,4493 ,786 ,636 ,9034 ,2630 ,6409 ,9019 ,807 ,3046 ,2226 ,6743 ,5625 ,9988 ,9024 ,6351 ,8584 ,3883 ,1752 ,4201 ,4010 ,528 ,5312 ,446 ,191 ,2132 ,6459 ,3494 ,629 ,9128 ,3364 ,161 ,6142 ,7739 ,5637 ,2464 ,2112 ,7452 ,5418 ,5714 ,2804 ,5616 ,8849 ,8670 ,3066 ,9604 ,2296 ,6899 ,99 ,1787 ,2086 ,618 ,241 ,9511 ,4852 ,2915 ,2695 ,2818 ,3833 ,4551 ,8452 ,7260 ,4275 ,5165 ,8050 ,2111 ,4627 ,1851 ,2004 ,1684 ,8907 ,6455 ,1367 ,8749 ,5467 ,6628 ,5851 ,7922 ,4910 ,9798 ,863 ,5026 ,9933 ,881 ,3458 ,2020 ,8596 ,1487 ,2433 ,6960 ,3212 ,1797 ,5428 ,9476 ,3432 ,2929 ,6507 ,8061 ,960 ,1952 ,779 ,6918 ,1867 ,5375 ,4417 ,6759 ,2340 ,4866 ,9303 ,3682 ,8868 ,2664 ,169 ,8776 ,4970 ,5838 ,220 ,1858 ,9619 ,5920 ,7937 ,6103 ,8952 ,5895 ,3484 ,6672 ,3553 ,9420 ,3991 ,4007 ,3953 ,5827 ,9423 ,7777 ,588 ,6476 ,24 ,6725 ,356 ,6291 ,4797 ,6201 ,453 ,5013 ,4616 ,3517 ,5208 ,9742 ,8521 ,7825 ,3158 ,9414 ,3813 ,4087 ,3568 ,1703 ,267 ,6112 ,2736 ,5271 ,1712 ,555 ,3748 ,3982 ,2106 ,5769 ,5377 ,4092 ,1880 ,7020 ,4205 ,963 ,3987 ,5610 ,4536 ,358 ,6537 ,8259 ,7730 ,7556 ,5469 ,3860 ,9231 ,9133 ,9841 ,1877 ,9375 ,5949 ,3411 ,3323 ,7652 ,5713 ,6458 ,4421 ,519 ,2756 ,7663 ,4372 ,1906 ,3650 ,697 ,4965 ,1153 ,1503 ,5734 ,3901 ,4469 ,6209 ,577 ,857 ,9314 ,9544 ,8971 ,6258 ,9299 ,8989 ,2638 ,2449 ,4871 ,1493 ,3499 ,6071 ,6841 ,8492 ,8647 ,6708 ,1713 ,1359 ,3773 ,1635 ,3697 ,4539 ,7471 ,5449 ,4657 ,3892 ,8869 ,2851 ,4995 ,6994 ,2538 ,4148 ,8947 ,5152 ,9922 ,6785 ,4817 ,5806 ,7028 ,7936 ,1497 ,5311 ,4988 ,7008 ,5982 ,6501 ,2058 ,3626 ,9589 ,8649 ,1474 ,2356 ,4467 ,8138 ,752 ,1281 ,9166 ,213 ,1816 ,3442 ,7118 ,2486 ,4649 ,6035 ,9974 ,5075 ,4611 ,6233 ,9965 ,1232 ,7146 ,759 ,5307 ,4756 ,5027 ,6382 ,5840 ,6370 ,3858 ,3691 ,2275 ,6689 ,8781 ,7860 ,3820 ,9462 ,6982 ,992 ,5254 ,2108 ,1808 ,6116 ,108 ,5310 ,1783 ,8114 ,8036 ,2540 ,1237 ,8740 ,3740 ,6716 ,3041 ,6984 ,4793 ,9598 ,5468 ,250 ,4512 ,5398 ,6094 ,7194 ,5962 ,1540 ,3567 ,6342 ,8437 ,1803 ,9858 ,7552 ,2708 ,5002 ,7970 ,434 ,2417 ,3978 ,6109 ,5484 ,982 ,6246 ,3155 ,2399 ,6051 ,7996 ,6372 ,84 ,4550 ,4215 ,2749 ,3481 ,7885 ,6394 ,3327 ,7574 ,6788 ,4293 ,7356 ,4683 ,9496 ,428 ,2741 ,4823 ,5880 ,4567 ,5282 ,349 ,2027 ,1525 ,914 ,2107 ,3256 ,525 ,62 ,1040 ,3557 ,3045 ,1219 ,6817 ,7239 ,3342 ,7607 ,2917 ,5902 ,9776 ,9707 ,1342 ,3352 ,7500 ,1116 ,1975 ,6096 ,6762 ,4513 ,6027 ,3247 ,5051 ,8493 ,288 ,2752 ,550 ,1095 ,2436 ,8284 ,716 ,157 ,5942 ,3363 ,7532 ,7344 ,5881 ,1042 ,135 ,8428 ,7596 ,1034 ,4006 ,7210 ,2376 ,1339 ,7890 ,5335 ,6949 ,2114 ,6731 ,4731 ,2934 ,5080 ,9371 ,5235 ,1779 ,6136 ,7161 ,2550 ,8714 ,1307 ,4165 ,1301 ,3249 ,8509 ,6518 ,563 ,2341 ,4651 ,4762 ,6312 ,5695 ,1397 ,6764 ,3671 ,8421 ,201 ,1173 ,46 ,6917 ,408 ,5979 ,6585 ,4211 ,804 ,6268 ,2443 ,709 ,8066 ,7173 ,5402 ,6938 ,8986 ,9025 ,4681 ,2306 ,6189 ,1620 ,7317 ,9488 ,584 ,7994 ,3159 ,7617 ,6765 ,9881 ,4938 ,5890 ,3603 ,2245 ,9753 ,3695 ,6231 ,4585 ,570 ,900 ,487 ,4019 ,3760 ,5321 ,5990 ,3118 ,4538 ,3466 ,1578 ,2212 ,8629 ,6997 ,8528 ,9882 ,9608 ,9296 ,5023 ,737 ,9765 ,7094 ,3083 ,4306 ,3654 ,9431 ,5373 ,8990 ,9361 ,9263 ,6751 ,258 ,8287 ,6896 ,2418 ,8578 ,1772 ,5036 ,57 ,2404 ,2789 ,4166 ,4197 ,2646 ,1324 ,8494 ,4298 ,354 ,7294 ,4894 ,7685 ,3785 ,4034 ,3142 ,7046 ,972 ,3644 ,9527 ,7817 ,7981 ,7085 ,8478 ,5899 ,7614 ,3460 ,1376 ,6675 ,7208 ,4524 ,7343 ,8594 ,7956 ,8246 ,1403 ,3870 ,4994 ,6969 ,34 ,7125 ,7560 ,6649 ,1293 ,6875 ,1029 ,2426 ,3456 ,1050 ,2161 ,3646 ,9635 ,1872 ,1730 ,5131 ,7393 ,7190 ,538 ,947 ,1820 ,2633 ,9237 ,5482 ,5501 ,9208 ,1673 ,8220 ,8302 ,5257 ,6611 ,7627 ,3068 ,1021 ,6257 ,7866 ,1235 ,7901 ,9014 ,1572 ,2640 ,9015 ,7616 ,8371 ,827 ,4202 ,1646 ,8978 ,4705 ,75 ,1431 ,7594 ,4338 ,7903 ,6443 ,4700 ,3916 ,7288 ,2762 ,2251 ,4783 ,1658 ,6497 ,4695 ,8793 ,6066 ,3710 ,527 ,9407 ,8733 ,9062 ,4859 ,6849 ,9736 ,705 ,644 ,2431 ,5443 ,9781 ,6446 ,879 ,6839 ,4048 ,3677 ,1016 ,3598 ,3957 ,1251 ,4732 ,5008 ,1765 ,6481 ,7205 ,7742 ,9862 ,9174 ,4360 ,8886 ,9547 ,1335 ,475 ,6390 ,7878 ,7941 ,6660 ,5338 ,7506 ,2806 ,9424 ,5636 ,4549 ,4081 ,613 ,3918 ,8459 ,5399 ,1533 ,9782 ,5514 ,386 ,1914 ,6285 ,7651 ,5767 ,4117 ,554 ,8328 ,8015 ,419 ,3030 ,4782 ,2899 ,3536 ,7703 ,5917 ,394 ,6203 ,9329 ,3888 ,787 ,2900 ,4884 ,1369 ,51 ,8915 ,9584 ,3638 ,3140 ,1683 ,710 ,7436 ,6100 ,2817 ,8306 ,7304 ,9916 ,9541 ,3330 ,9449 ,9536 ,8639 ,5224 ,537 ,8742 ,1685 ,1548 ,9504 ,9446 ,1567 ,2847 ,5115 ,7917 ,3730 ,7521 ,3847 ,7578 ,5403 ,2209 ,9977 ,4928 ,9456 ,734 ,6369 ,5018 ,6469 ,7758 ,7805 ,3503 ,7498 ,73 ,4693 ,4098 ,8910 ,1345 ,6891 ,3745 ,2960 ,7248 ,5680 ,6744 ,4674 ,829 ,3257 ,6907 ,9726 ,5183 ,8516 ,923 ,6647 ,4325 ,1393 ,6434 ,3681 ,5221 ,7165 ,2746 ,5121 ,3295 ,6251 ,9324 ,8234 ,5081 ,9996 ,4031 ,2596 ,3605 ,631 ,7948 ,3010 ,368 ,3251 ,6302 ,9383 ,9130 ,9911 ,6990 ,9223 ,7834 ,7326 ,6490 ,6306 ,7524 ,4260 ,9194 ,9838 ,8115 ,2994 ,8385 ,7509 ,9935 ,953 ,5381 ,9950 ,7591 ,4746 ,2508 ,397 ,4533 ,5766 ,9595 ,7015 ,4792 ,405 ,8455 ,2819 ,9294 ,2429 ,9915 ,3272 ,2388 ,7064 ,2739 ,8527 ,3573 ,3961 ,5526 ,1091 ,1940 ,9947 ,8557 ,433 ,790 ,3887 ,3945 ,8096 ,7444 ,4232 ,6597 ,4391 ,3937 ,6471 ,5160 ,9687 ,5016 ,8764 ,151 ,4690 ,3176 ,7811 ,9571 ,8809 ,8037 ,9315 ,2213 ,7219 ,7542 ,5166 ,4886 ,2302 ,2938 ,2558 ,9486 ,9698 ,5120 ,7832 ,2822 ,5061 ,5630 ,2935 ,828 ,8533 ,5128 ,611 ,4576 ,2053 ,5901 ,8185 ,5001 ,8651 ,3319 ,8627 ,1444 ,9641 ,9234 ,2945 ,8999 ,3354 ,7913 ,2372 ,285 ,9162 ,6897 ,3479 ,1879 ,2936 ,9998 ,5875 ,5795 ,5126 ,382 ,767 ,1202 ,5207 ,1985 ,931 ,1589 ,5068 ,7716 ,4321 ,6922 ,929 ,4501 ,2120 ,7142 ,2551 ,2913 ,7967 ,8821 ,7886 ,8813 ,5470 ,7324 ,6509 ,3663 ,1717 ,8029 ,7362 ,484 ,4531 ,6180 ,316 ,8914 ,3662 ,2383 ,1280 ,5841 ,2268 ,4591 ,5936 ,7852 ,5096 ,3825 ,1236 ,4063 ,8805 ,7650 ,6475 ,3675 ,5528 ,1076 ,6526 ,8326 ,9790 ,1 ,3884 ,4129 ,8468 ,5167 ,5109 ,7401 ,7427 ,8122 ,7717 ,4346 ,6219 ,3539 ,2531 ,4998 ,353 ,239 ,3742 ,6327 ,3897 ,1256 ,1221 ,2996 ,3084 ,1137 ,3781 ,3696 ,7723 ,3339 ,9206 ,1986 ,9461 ,9268 ,5019 ,8677 ,8387 ,5524 ,7612 ,5834 ,1771 ,8970 ,5353 ,7752 ,2855 ,4675 ,2040 ,3201 ,2775 ,1955 ,2096 ,6085 ,920 ,8106 ,8798 ,7316 ,2142 ,8718 ,3837 ,1778 ,3111 ,4832 ,7065 ,5223 ,4904 ,8753 ,1031 ,3577 ,9115 ,6113 ,2518 ,2639 ,2454 ,9914 ,2441 ,4131 ,9773 ,4455 ,8305 ,6307 ,1257 ,5022 ,6707 ,4135 ,9964 ,3694 ,6486 ,8520 ,3334 ,5525 ,8936 ,6169 ,8681 ,6352 ,178 ,324 ,465 ,2153 ,3202 ,4021 ,7490 ,602 ,9232 ,5 ,4830 ,1662 ,2998 ,9490 ,4671 ,1991 ,9492 ,8286 ,4827 ,6532 ,9830 ,2036 ,7318 ,9285 ,8711 ,2748 ,8921 ,1147 ,2673 ,3707 ,4821 ,2231 ,8024 ,1294 ,5416 ,3264 ,3636 ,4331 ,5777 ,7408 ,8697 ,2905 ,7412 ,2167 ,7603 ,4685 ,1558 ,5342 ,5554 ,4168 ,455 ,650 ,5961 ,2840 ,7163 ,2800 ,3139 ,8803 ,5124 ,7394 ,9618 ,4273 ,8708 ,1044 ,3483 ,5122 ,9381 ,8966 ,9740 ,9013 ,1723 ,5778 ,206 ,5046 ,1824 ,9806 ,112 ,3794 ,8232 ,2906 ,5486 ,6252 ,6484 ,3552 ,8507 ,2462 ,4381 ,3356 ,7055 ,7179 ,4488 ,9356 ,6249 ,2897 ,2041 ,5765 ,1361 ,6538 ,9564 ,9681 ,7234 ,5489 ,3001 ,340 ,4333 ,1735 ,7363 ,3232 ,8616 ,7707 ,3153 ,3489 ,651 ,5985 ,551 ,7188 ,7554 ,322 ,8189 ,6546 ,7043 ,9269 ,4184 ,3190 ,9580 ,9767 ,6694 ,8039 ,4862 ,9336 ,5040 ,763 ,6354 ,751 ,3205 ,7573 ,3126 ,1738 ,2409 ,4860 ,9124 ,1215 ,9626 ,2054 ,2730 ,8582 ,2129 ,8595 ,4596 ,1557 ,6965 ,4161 ,4578 ,621 ,5286 ,4544 ,540 ,7119 ,4176 ,6014 ,2654 ,9910 ,1496 ,2401 ,6514 ,9803 ,1780 ,1660 ,2837 ,7908 ,207 ,9429 ,3732 ,8663 ,5658 ,8660 ,3215 ,6613 ,4924 ,1855 ,9161 ,9229 ,9139 ,4546 ,4890 ,9883 ,8728 ,486 ,685 ,9622 ,9714 ,3328 ,5618 ,2904 ,7997 ,9173 ,8755 ,467 ,4604 ,7722 ,3185 ,9530 ,168 ,4412 ,3335 ,1315 ,4286 ,8335 ,733 ,1813 ,3093 ,4676 ,796 ,7207 ,6629 ,1210 ,2797 ,2119 ,4287 ,5593 ,7761 ,3191 ,6661 ,6431 ,1812 ,8779 ,5466 ,404 ,6643 ,2242 ,76 ,6794 ,9591 ,7753 ,48 ,262 ,2344 ,7789 ,5907 ,1861 ,8939 ,6809 ,6621 ,7466 ,3277 ,8526 ,6890 ,47 ,5114 ,775 ,1238 ,3955 ,8429 ,3843 ,2030 ,8270 ,118 ,7859 ,2193 ,5248 ,4754 ,1588 ,1019 ,6802 ,5175 ,3393 ,9098 ,1863 ,7468 ,9102 ,8231 ,849 ,5210 ,211 ,3895 ,2977 ,3782 ,2854 ,814 ,6262 ,9719 ,3651 ,898 ,2362 ,5319 ,2679 ,2651 ,3588 ,9218 ,9873 ,9605 ,6028 ,1395 ,7846 ,7800 ,816 ,4459 ,9104 ,6334 ,774 ,3558 ,4353 ,2407 ,3952 ,8762 ,1534 ,2729 ,2471 ,3305 ,3911 ,4356 ,49 ,6398 ,7257 ,2496 ,3546 ,2326 ,3258 ,1766 ,12 ,1495 ,3179 ,6061 ,9633 ,139 ,5209 ,7367 ,7107 ,2780 ,1929 ,3811 ,3288 ,193 ,8425 ,6740 ,6325 ,3050 ,1480 ,8994 ,2411 ,5726 ,8882 ,1913 ,1366 ,2402 ,1565 ,1337 ,2141 ,6816 ,6534 ,77 ,9255 ,8613 ,8078 ,4748 ,2892 ,6048 ,4632 ,7095 ,3398 ,5911 ,9004 ,4712 ,6135 ,9334 ,2136 ,3310 ,1591 ,4961 ,1911 ,2439 ,6913 ,410 ,78 ,5755 ,7187 ,23 ,98 ,175 ,707 ,9983 ,5357 ,7751 ,8747 ,5897 ,9783 ,8748 ,5830 ,1105 ,2607 ,3090 ,4392 ,4362 ,2042 ,1648 ,5792 ,53 ,8735 ,1837 ,1199 ,6120 ,834 ,1740 ,6053 ,4220 ,7827 ,2697 ,4931 ,9493 ,5684 ,9430 ,5421 ,9283 ,9748 ,2965 ,9251 ,8381 ,3692 ,302 ,92 ,5174 ,6903 ,6295 ,1868 ,6215 ,8223 ,9785 ,811 ,1346 ,7233 ,4125 ,7615 ,8304 ,9651 ,5182 ,9214 ,1807 ,4011 ,5668 ,1368 ,4518 ,7623 ,7692 ,6280 ,7769 ,3972 ,3314 ,2802 ,4945 ,572 ,8621 ,5372 ,4916 ,9991 ,9187 ,6129 ,5004 ,9466 ,4944 ,5083 ,8242 ,6539 ,2359 ,4154 ,2438 ,5090 ,6296 ,2801 ,5752 ,6523 ,5912 ,6273 ,4510 ,6583 ,7595 ,367 ,5490 ,3545 ,866 ,8840 ,1244 ,464 ,6603 ,9658 ,4167 ,412 ,5784 ,4739 ,205 ,4692 ,4622 ,5006 ,399 ,7647 ,3410 ,7243 ,9502 ,5444 ,293 ,4315 ,9307 ,1806 ,5886 ,2838 ,1881 ,8406 ,3939 ,3289 ,1093 ,5651 ,7074 ,7896 ,388 ,4354 ,6680 ,4947 ,9892 ,8319 ,9762 ,5790 ,8949 ,3278 ,5328 ,3846 ,3037 ,7711 ,714 ,8431 ,3948 ,3648 ,8837 ,4517 ,3807 ,125 ,131 ,1762 ,9188 ,2561 ,7420 ,6091 ,6895 ,6182 ,1614 ,6993 ,5677 ,105 ,7319 ,6228 ,3865 ,1226 ,4714 ,1770 ,4262 ,3180 ,301 ,3542 ,2557 ,5448 ,176 ,5789 ,9532 ,6137 ,160 ,623 ,1233 ,6110 ,228 ,4297 ,1590 ,8283 ,4327 ,2769 ,9 ,872 ,691 ,1340 ,4100 ,8099 ,3493 ,2761 ,1669 ,642 ,2941 ,5015 ,5555 ,7505 ,3998 ,1120 ,7212 ,8333 ,2152 ,1432 ,7683 ,2882 ,3747 ,3412 ,9309 ,6578 ,988 ,5241 ,5009 ,1652 ,3446 ,8143 ,6230 ,5506 ,5496 ,6025 ,1225 ,2788 ,4441 ,9574 ,4214 ,564 ,2573 ,8361 ,6686 ,946 ,6630 ,5118 ,6936 ,7078 ,7511 ,7887 ,170 ,1963 ,726 ,9728 ,9131 ,6623 ,5940 ,4902 ,4547 ,1514 ,5613 ,3511 ,4715 ,4802 ,4451 ,1075 ,8354 ,9621 ,9325 ,6726 ,1628 ,1320 ,6015 ,106 ,4082 ,2652 ,2384 ,4626 ,654 ,9891 ,6771 ,8927 ,1358 ,7158 ,9676 ,1531 ,3332 ,4516 ,7830 ,5439 ,4430 ,3809 ,3580 ,5774 ,5608 ,5387 ,9227 ,1087 ,8102 ,7121 ,1066 ,4438 ,8676 ,3792 ,8855 ,6888 ,9064 ,6880 ,6130 ,4246 ,5178 ,3903 ,1097 ,888 ,7750 ,5725 ,1512 ,3802 ,1528 ,2005 ,2666 ,4590 ,4301 ,8322 ,7275 ,3374 ,2164 ,5751 ,6377 ,8783 ,1887 ,5887 ,2724 ,3070 ,1118 ,8724 ,8318 ,9976 ,7216 ,1507 ,1524 ,326 ,5590 ,3924 ,4734 ,4061 ,8829 ,865 ,8278 ,505 ,843 ,7786 ,6837 ,4415 ,378 ,4300 ,3632 ,2574 ,9409 ,2732 ,320 ,2059 ,319 ,9832 ,8559 ,5361 ,7553 ,503 ,4814 ,7883 ,9801 ,1595 ,2571 ,6294 ,2581 ,8060 ,3360 ,2124 ,4898 ,7109 ,8655 ,6729 ,5227 ,1343 ,7762 ,3910 ,2575 ,2503 ,9182 ,7249 ,7882 ,3102 ,5331 ,7241 ,9654 ,2061 ,380 ,4182 ,2370 ,1155 ,7884 ,8542 ,869 ,6063 ,5057 ,7047 ,5385 ,6547 ,858 ,6162 ,1193 ,4785 ,5198 ,3391 ,8843 ,6847 ,1479 ,111 ,2361 ,614 ,7229 ,4188 ,2337 ,6919 ,6491 ,9217 ,5150 ,9800 ,6552 ,4999 ,8546 ,2511 ,2820 ,1156 ,1138 ,279 ,9645 ,6821 ,7002 ,8879 ,5685 ,27 ,9252 ,3725 ,9016 ,5648 ,145 ,9749 ,5522 ,7473 ,8293 ,2719 ,7134 ,5975 ,4678 ,5397 ,4727 ,6646 ,3177 ,4854 ,5219 ,8291 ,5582 ,552 ,8414 ,9169 ,9548 ,494 ,2755 ,2947 ,2494 ,2594 ,6092 ,842 ,5623 ,7364 ,4462 ,919 ,3125 ,2391 ,9418 ,9642 ,7838 ,7551 ,5512 ,4308 ,1079 ,9311 ,899 ,3036 ,5511 ,3105 ,2563 ,8902 ,8956 ,459 ,9380 ,8214 ,1664 ,7273 ,3097 ,6858 ,2295 ,8981 ,7149 ,2412 ,8664 ,8352 ,5242 ,4844 ,7369 ,4259 ,7973 ,1800 ,223 ,5186 ,4983 ,6970 ,9538 ,5837 ,1377 ,3816 ,9979 ,7810 ,8394 ,9216 ,7290 ,6045 ,3965 ,321 ,8580 ,592 ,5332 ,859 ,722 ,9735 ,4483 ,8366 ,338 ,346 ,8558 ,2010 ,9876 ,2247 ,6205 ,5710 ,6692 ,3266 ,5946 ,5326 ,933 ,7021 ,2363 ,8409 ,7154 ,1098 ,5820 ,9289 ,2489 ,4142 ,7782 ,2177 ,1060 ,1942 ,3437 ,2028 ,4984 ,9083 ,8792 ,407 ,3175 ,6842 ,2052 ,199 ,8195 ,725 ,4479 ,8378 ,440 ,1152 ,6812 ,4741 ,5549 ,3165 ,6244 ,3861 ,490 ,4364 ,4282 ,4851 ,9330 ,1873 ,5384 ,5700 ,8719 ,2933 ,3818 ,873 ,2969 ,1382 ,8766 ,7224 ,3733 ,6001 ,4472 ,8794 ,5617 ,8555 ,6684 ,8008 ,7103 ,4977 ,3505 ,8709 ,2808 ,3929 ,8497 ,4930 ,867 ,6368 ,7137 ,2303 ,7463 ,5261 ,7881 ,2087 ,485 ,1594 ,8691 ,3101 ,2514 ,1407 ,1601 ,4810 ,6608 ,7464 ,5996 ,2849 ,1101 ,8155 ,2858 ,5703 ,1450 ,6833 ,1630 ,3405 ,4445 ,1287 ,7894 ,240 ,4084 ,5983 ,7535 ,306 ,4688 ,5788 ,2871 ,9973 ,7958 ,1943 ,3612 ,395 ,247 ,6043 ,1553 ,9688 ,5262 ,1728 ,1191 ,9912 ,9159 ,3123 ,7678 ,6631 ,6596 ,4612 ,2263 ,1030 ,5981 ,6937 ,5485 ,5079 ,9552 ,3162 ,3440 ,2660 ,476 ,2768 ,5363 ,2157 ,7410 ,2751 ,8502 ,5952 ,2198 ,202 ,266 ,7411 ,9853 ,4099 ,3424 ,7949 ,8310 ,7496 ,2051 ,4669 ,2628 ,5105 ,2717 ,1260 ,5184 ,1922 ,808 ,6512 ,8979 ,2285 ,2304 ,6167 ,2217 ,776 ,846 ,5137 ,5667 ,8898 ,8451 ,3597 ,5612 ,854 ,4458 ,8374 ,120 ,1459 ,6823 ,2943 ,7672 ,8098 ,2734 ,6465 ,7209 ,6825 ,2989 ,9221 ,2522 ,9345 ,6353 ,3480 ,4708 ,5431 ,5432 ,3427 ,4155 ,134 ,6738 ,9842 ,314 ,5441 ,2985 ,1148 ,5232 ,8511 ,2063 ,6933 ,2232 ,8198 ,9826 ,7783 ,7255 ,5238 ,2137 ,7699 ,3240 ,4760 ,7745 ,801 ,3117 ,3024 ,6161 ,7291 ,6498 ,7710 ,4706 ,6640 ,1737 ,5039 ,5462 ,3949 ,7541 ,1253 ,3207 ,9071 ,3098 ,5698 ,7396 ,652 ,3531 ,1389 ,509 ,1761 ,9807 ,1072 ,4786 ,5675 ,1349 ,3738 ,4515 ,3008 ,7449 ,3840 ,3751 ,8547 ,3103 ,6859 ,9290 ,5097 ,9136 ,385 ,5087 ,9675 ,2453 ,7729 ,2145 ,9866 ,6563 ,8077 ,7514 ,6421 ,7075 ,6967 ,4647 ,5266 ,2742 ,3938 ,5540 ,1179 ,6594 ,3666 ,8071 ,517 ,4927 ,9994 ,8669 ,6013 ,8577 ,5771 ,4074 ,3301 ,7545 ,379 ,4432 ,6636 ,7700 ,1909 ,4023 ,6330 ,1993 ,1846 ,9738 ,7299 ,4637 ,4002 ,7520 ,7346 ,5135 ,6046 ,7254 ,6658 ,5825 ,4060 ,336 ,6855 ,6166 ,6170 ,962 ,9248 ,2667 ,8767 ,2259 ,26 ,6213 ,7696 ,1209 ,8450 ,915 ,3767 ,2791 ,7971 ,2924 ,2076 ,6362 ,3089 ,1160 ,9090 ,638 ,3054 ,2197 ,1575 ,4427 ,803 ,115 ,2590 ,5269 ,6659 ,6187 ,4666 ,3655 ,2298 ,2139 ,4204 ,8049 ,2146 ,6752 ,7635 ,9028 ,8919 ,4610 ,545 ,4329 ,4314 ,5567 ,9448 ,4283 ,7341 ,9506 ,8553 ,8666 ,9213 ,4491 ,7153 ,9929 ,2156 ,8587 ,3810 ,6017 ,4380 ,4751 ,9934 ,5111 ,6157 ,9946 ,7978 ,9095 ,2379 ,6722 ,4660 ,8253 ,3589 ,9526 ,3985 ,7069 ,3864 ,2962 ,5709 ,1071 ,6281 ,4818 ,1749 ,3173 ,2980 ,1827 ,8486 ,1017 ,7525 ,2507 ,1426 ,1364 ,9942 ,6733 ,5539 ,8140 ,5325 ,9421 ,1170 ,6992 ,9442 ,6911 ,6995 ,9168 ,2865 ,2172 ,3096 ,1767 ,5809 ,7108 ,8402 ,1789 ,3777 ,2555 ,7942 ,2013 ,7049 ,3630 ,9405 ,1271 ,1724 ,8399 ,8933 ,7793 ,3297 ,9265 ,6143 ,3189 ,1351 ,2823 ,2674 ,4189 ,9612 ,9923 ,3909 ,2589 ,8836 ,4595 ,2387 ,9057 ,9906 ,1145 ,2988 ,3122 ,7329 ,7654 ,1295 ,3044 ,7001 ,2166 ,5605 ,3509 ,204 ,1513 ,364 ,9365 ,2765 ,4759 ,6226 ,14 ,4267 ,1035 ,3303 ,2961 ,7433 ,6473 ,9145 ,3726 ,9343 ,6727 ,5592 ,2044 ,6452 ,2548 ,909 ,7527 ,5817 ,8873 ,6357 ,9003 ,1284 ,9665 ,9693 ,9322 ,6665 ,9577 ,2828 ,17 ,2586 ,5847 ,6477 ,7803 ,3273 ,9279 ,6435 ,4726 ,8510 ,8193 ,5156 ,7398 ,3635 ,8897 ,2777 ,3684 ,3676 ,177 ,5971 ,4720 ,6449 ,7988 ,9884 ,4521 ,5491 ,7857 ,1546 ,6641 ,2773 ,142 ,750 ,8097 ,9337 ,4388 ,5149 ,5624 ,9718 ,9157 ,2659 ,6828 ,6374 ,5978 ,1374 ,8357 ,4160 ,4352 ,2645 ,7494 ,4229 ,9566 ,9864 ,581 ,2707 ,1702 ,290 ,9276 ,5244 ,3133 ,8585 ,5970 ,480 ,234 ,8476 ,2632 ,7321 ,2386 ,436 ,8254 ,4233 ,968 ,569 ,8503 ,7042 ,753 ,6339 ,4486 ,9949 ,1481 ,6900 ,8707 ,8860 ,463 ,5429 ,8752 ,9531 ,1418 ,5430 ,273 ,6951 ,3337 ,6298 ,1455 ,6591 ,8323 ,8590 ,4525 ,8661 ,2310 ,9844 ,8859 ,8203 ,5272 ,4696 ,8831 ,5919 ,4374 ,9391 ,4641 ,4863 ,1517 ,1949 ,8817 ,9958 ,9447 ,2825 ,5063 ,1247 ,5365 ,8338 ,2077 ,2850 ,531 ,255 ,3392 ,3530 ,6600 ,7375 ,3346 ,9038 ,3081 ,5731 ,6697 ,4764 ,7186 ,2248 ,9777 ,3533 ,8894 ,252 ,7348 ,939 ,8854 ,5994 ,2253 ,6118 ,3614 ,3746 ,6102 ,383 ,31 ,7170 ,3217 ,2225 ,7570 ,5066 ,1825 ,1328 ,9590 ,4914 ,7507 ,9553 ,7199 ,4444 ,7529 ,6712 ,7569 ,6761 ,2750 ,9058 ,723 ,6921 ,6292 ,544 ,33 ,1158 ,97 ,4869 ,9787 ,699 ,9542 ,9193 ,9433 ,7706 ,8314 ,8146 ,5529 ,8722 ,1392 ,6117 ,6269 ,5304 ,4270 ,8181 ,1681 ,4291 ,6793 ,698 ,5614 ,8260 ,1396 ,2060 ,3803 ,9031 ,902 ,3524 ,4892 ,360 ,2062 ,4240 ,159 ,2545 ,9729 ,8850 ,9222 ,7779 ,9715 ,5138 ,7222 ,9440 ,2795 ,4435 ,8715 ,1910 ,9944 ,8065 ,1502 ,1468 ,3355 ,1639 ,4964 ,7285 ,6072 ,5696 ,2599 ,4347 ,9186 ,1026 ,6664 ,2681 ,5144 ,6884 ,2117 ,1433 ,2246 ,1802 ,2451 ,9636 ,8228 ,7159 ,7011 ,6879 ,9509 ,8974 ,974 ,6397 ,9284 ,5707 ,4339 ,8568 ,8225 ,7989 ,8091 ,5301 ,4710 ,3166 ,1205 ,4348 ,3934 ,215 ,4496 ,7774 ,7462 ,5750 ,4316 ,1897 ,4648 ,2422 ,7446 ,3401 ,3925 ,7795 ,9153 ,4139 ,7593 ,2098 ,4508 ,7453 ,2863 ,9412 ,559 ,7544 ,7637 ,8693 ,2698 ,2542 ,8013 ,366 ,4589 ,8534 ,5856 ,8789 ,6154 ,2065 ,3830 ,789 ,7276 ,8632 ,9478 ,5543 ,4889 ,4721 ,549 ,3020 ,4694 ,230 ,5289 ,6022 ,9287 ,1157 ,903 ,7926 ,626 ,2297 ,4097 ,9570 ,4296 ,9943 ,4383 ,5199 ,4180 ,7704 ,2347 ,9164 ,4350 ,3891 ,950 ,1099 ,2881 ,5770 ,2948 ,3252 ,5678 ,2726 ,2728 ,7267 ,8248 ,7714 ,8433 ,5287 ,9086 ,6055 ,7024 ,6946 ,1882 ,511 ,7204 ,5583 ,7151 ,7340 ,4012 ,7588 ,116 ,886 ,4219 ,5811 ,6319 ,7309 ,9854 ,5413 ,7221 ,9850 ,232 ,4341 ,1213 ,9270 ,3171 ,7157 ,8820 ,8758 ,3379 ,3977 ,2845 ,5454 ,9474 ,8041 ,5370 ,2519 ,5835 ,2115 ,7546 ,7139 ,8116 ,244 ,113 ,2190 ,6883 ,1473 ,8712 ,2567 ,5236 ,8150 ,6218 ,8458 ,1203 ,8084 ,8832 ,9158 ,727 ,657 ,3099 ,8400 ,6579 ,9302 ,9198 ,8121 ,7360 ,5607 ,6 ,1715 ,9796 ,1536 ,3817 ,7110 ,187 ,7858 ,1992 ,6754 ,5407 ,7106 ,6222 ,8726 ,1049 ,8441 ,2299 ,6540 ,4127 ,3241 ,1308 ,9005 ,450 ,3572 ,138 ,2088 ,332 ,3444 ,1587 ,5823 ,5153 ,1229 ,259 ,2094 ,1197 ,958 ,6248 ,6288 ,9834 ,5853 ,1322 ,2829 ,1078 ,7131 ,5576 ,2700 ,1250 ,4630 ,3759 ,5256 ,4413 ,7835 ,8717 ,6644 ,5181 ,5215 ,2484 ,5958 ,9813 ,8126 ,4385 ,4199 ,2191 ,5854 ,2070 ,9774 ,4936 ,5129 ,3617 ,9049 ,8362 ,8454 ,5333 ,2318 ,2620 ,9896 ,8775 ,9989 ,4644 ,3772 ,5296 ,165 ,4834 ,1994 ,2334 ,4663 ,9583 ,4704 ,6047 ,1222 ,2024 ,868 ,2583 ,6818 ,9670 ,3311 ,6272 ,9847 ,2874 ,833 ,8819 ,6337 ,5541 ,8391 ,4920 ,2859 ,4664 ,5457 ,5758 ,8913 ,5892 ,3132 ,8389 ,294 ,3114 ,2883 ,5318 ,8090 ,4565 ,5474 ,2937 ,5229 ,9855 ,9144 ,3147 ,1289 ,7185 ,6844 ,1604 ,3968 ,7430 ,3195 ,4108 ,4064 ,8063 ,3385 ,4434 ,7492 ,8168 ,7003 ,4556 ,1067 ,1457 ,6760 ,5560 ,7143 ,1636 ,597 ,8888 ,1862 ,7781 ,2241 ,1442 ,2382 ,6263 ,7305 ,6784 ,1388 ,1876 ,11 ,7785 ,8848 ,4973 ,7902 ,7127 ,3814 ,6557 ,7175 ,5884 ,3715 ,6574 ,9727 ,4239 ,1163 ,5213 ,7484 ,2617 ,7183 ,7766 ,7038 ,5645 ,6717 ,9372 ,8811 ,5928 ,9460 ,9399 ,7422 ,870 ,9472 ,7442 ,590 ,7181 ,1115 ,7737 ,9575 ,8892 ,162 ,1051 ,7618 ,2499 ,536 ,6632 ,3959 ,1063 ,4431 ,532 ,2725 ,5577 ,1554 ,1744 ,8416 ,9256 ,8007 ,3569 ,5211 ,2442 ,7101 ,3879 ,6971 ,975 ,7482 ,5154 ,4763 ,1103 ,8002 ,8164 ,7916 ,60 ,9578 ,8778 ,6388 ,2432 ,4080 ,7641 ,6399 ,1037 ,5862 ,5832 ,7993 ,7972 ,6344 ,6679 ,6019 ,2423 ,8698 ,6255 ,9266 ,6305 ,6857 ,2641 ,1621 ,8562 ,3723 ,203 ,7439 ,1231 ,8147 ,9059 ,3250 ,8426 ,2211 ,5203 ,4079 ,5672 ,2608 ,5101 ,1612 ,981 ,4481 ,3729 ,1577 ,8973 ,890 ,3566 ,374 ,6609 ,2610 ,5089 ,6029 ,9723 ,1217 ,8710 ,3167 ,304 ,5415 ,7278 ,524 ,3855 ,8804 ,4804 ,6400 ,1375 ,3942 ,1174 ,4069 ,5376 ,5017 ,1950 ,8620 ,3976 ,682 ,9812 ,8157 ,7898 ,8552 ,1790 ,4937 ,1223 ,9091 ,5054 ,9012 ,1998 ,4776 ,622 ,9513 ,1586 ,6873 ,9106 ,1347 ,458 ,3628 ,5819 ,4968 ,2995 ,7465 ,5364 ,4918 ,4828 ,6304 ,7741 ,6192 ,19 ,5781 ,4310 ,718 ,143 ,2656 ,9663 ,117 ,9938 ,361 ,3702 ,3455 ,499 ,6520 ,2333 ,3718 ,9653 ,8985 ,2770 ,7653 ,7077 ,1769 ,6687 ,4068 ,2319 ,8375 ,2714 ,8397 ,9485 ,2463 ,632 ,7385 ,6207 ,9518 ,2615 ,5814 ,6494 ,8937 ,3518 ,4118 ,2218 ,4425 ,2116 ,9363 ,16 ,1212 ,9879 ,1706 ,2469 ,7576 ,1675 ,1774 ,3660 ,5049 ,1972 ,7262 ,9388 ,667 ,7816 ,7686 ,6797 ,5532 ,1615 ,2043 ,2810 ,8469 ,2064 ,8551 ,7513 ,4013 ,6178 ,520 ,4018 ,7585 ,1240 ,5599 ,8250 ,1840 ,4405 ,6331 ,3388 ,2999 ,9411 ,5821 ,7691 ,6068 ,6451 ,8827 ,8517 ,7128 ,3421 ,4272 ,1025 ,5791 ,4243 ,548 ,4903 ,6122 ,1602 ,3933 ,5523 ,1674 ,1549 ,2168 ,7518 ,7035 ,7387 ,5222 ,6128 ,8230 ,921 ,2861 ,9890 ,5252 ,8796 ,8784 ,4853 ,7092 ,5392 ,5045 ,1463 ,3875 ,7100 ,6379 ,444 ,6720 ,1829 ,7467 ,5753 ,6878 ,4506 ,7472 ,104 ,2658 ,4416 ,7180 ,32 ,1194 ,2993 ,4575 ,6820 ,3640 ,2930 ,2953 ,9683 ,7312 ,7847 ,5859 ,3876 ,1834 ,4623 ,5974 ,3061 ,2986 ,8388 ,5147 ,8723 ,4709 ,1785 ,5816 ,8549 ,3907 ,7132 ,9355 ,4429 ,8018 ,1727 ,7995 ,6638 ,9763 ,442 ,6415 ,6627 ,9291 ,883 ,4126 ,1768 ,8560 ,5305 ,7122 ,296 ,658 ,190 ,1267 ,5536 ,9786 ,2009 ,3260 ,8983 ,9108 ,4956 ,9750 ,4305 ,1691 ,3534 ,8623 ,3711 ,4477 ,1047 ,3719 ,3441 ,7698 ,2520 ,7140 ,810 ,6250 ,5354 ,2181 ,9120 ,2556 ,2579 ,7345 ,1279 ,9634 ,2534 ,1159 ,3683 ,4245 ,6737 ,1009 ,3713 ,4109 ,4137 ,8273 ,3486 ,1705 ,2754 ,3613 ,8343 ,4967 ,4005 ,4468 ,5664 ,183 ,466 ,9554 ,5380 ,3073 ,398 ,1023 ,1020 ,4443 ,227 ,5956 ,3017 ,4780 ,8513 ,3445 ,7223 ,9966 ,8089 ,1830 ,3206 ,1585 ,4935 ,4953 ,9451 ,9007 ,4527 ,3966 ,2021 ,8100 ,9357 ,1201 ,7230 ,6531 ,2144 ,5889 ,6232 ,1466 ,1400 ,717 ,8626 ,5967 ,7648 ,2711 ,9960 ,8646 ,1446 ,478 ,2100 ,2276 ,9147 ,2816 ,3349 ,6036 ,3281 ,5389 ,6356 ,9326 ,7734 ,9744 ,452 ,4652 ,7812 ,5829 ,6428 ,4242 ,1306 ,7918 ,4046 ,8346 ,3386 ,5918 ,2699 ,6753 ,9939 ,2459 ,1074 ,832 ,1667 ,6217 ,7928 ,3674 ,9171 ,5268 ,4805 ,5260 ,7389 ,9009 ,8656 ,927 ,1189 ,2185 ,7220 ,7631 ,4888 ,8744 ,9220 ,1088 ,50 ,9804 ,1344 ,6834 ,6756 ,4086 ,2526 ,6383 ,6392 ,7539 ,4592 ,7258 ,954 ,8944 ,9254 ,9029 ,8219 ,7232 ,6693 ,9044 ,7944 ,5453 ,3181 ,795 ,8288 ,2206 ,8504 ,1569 ,1273 ,1001 ,8541 ,1452 ,2189 ,3488 ,4311 ,3469 ,6037 ,5218 ,3487 ,7097 ,8085 ,901 ,4463 ,1978 ,8880 ,2271 ,821 ,375 ,5517 ,1185 ,6642 ,2813 ,5910 ,4613 ,2419 ,2738 ,6148 ,5360 ,5588 ,6905 ,2887 ,7957 ,2238 ,7770 ,4234 ,8197 ,5652 ,8108 ,2195 ,7414 ,2944 ,6865 ,7939 ,9888 ,8337 ,9840 ,7197 ,1451 ,2950 ,4717 ,558 ,3078 ,4500 ,2740 ,9441 ,8218 ,5031 ,9500 ,9393 ,2121 ,6915 ,5440 ,88 ,5303 ,656 ,3137 ,3055 ,6442 ,9072 ,5142 ,612 ,1278 ,154 ,1168 ,6927 ,5639 ,1694 ,8574 ,8139 ,2932 ,2470 ,5003 ,945 ,6414 ,107 ,8221 ,6387 ,2103 ,1822 ,393 ,6885 ,8311 ,2644 ,8307 ,3495 ,7624 ,1564 ,7082 ,38 ,9209 ,7129 ,4733 ,1860 ,1445 ,6088 ,730 ,8434 ,8064 ,8611 ,6317 ,4579 ,5265 ,7533 ,7661 ,4026 ,4358 ,2080 ,2884 ,6604 ,6492 ,8176 ,3947 ,7828 ,3474 ,245 ,5427 ,806 ,9775 ,4450 ,5883 ,6098 ,2035 ,1560 ,3157 ,1372 ,173 ,6005 ,3643 ,8075 ,8386 ,7911 ,9253 ,7583 ,1543 ,4132 ,355 ,8644 ,6695 ,3999 ,3769 ,4992 ,9413 ,4075 ,6188 ,4891 ,660 ,7833 ,8373 ,2127 ,7592 ,4000 ,9852 ,4461 ,6866 ,1085 ,7155 ,2472 ,9739 ,8161 ,9354 ,9660 ,7459 ,2957 ,4395 ,2885 ,3806 ,7072 ,3585 ,5323 ,8976 ,7530 ,2163 ,7873 ,3378 ,3506 ,4221 ,1003 ,8852 ,3464 ,3850 ,932 ,8619 ,1633 ,2287 ,3229 ,1058 ,1332 ,4564 ,148 ,5483 ,847 ,1196 ,9972 ,6147 ,6942 ,1853 ,9557 ,1944 ,6988 ,2254 ,969 ,2688 ,2288 ,39 ,8687 ,6598 ]
   

    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _ETCORCContract) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    
        orcLimit = 10000;

        ietcorc = IETCORC(_ETCORCContract);

        ETCORCContract = _ETCORCContract;

        mapXpPayValue[100] = 0.1 ether;
        mapXpPayValue[500] = 0.3 ether;
        mapXpPayValue[1000] = 0.5 ether;
        mapXpPayValue[5000] = 2.5 ether;
        mapXpPayValue[10000] = 5 ether;
        //        ------------
        mapLvl[1].maxBids = 0.1 ether;
        mapLvl[2].maxBids = 0.2 ether;
        mapLvl[3].maxBids = 0.4 ether;
        mapLvl[4].maxBids = 1 ether;
        mapLvl[5].maxBids = 2 ether;
        mapLvl[6].maxBids = 4 ether;
        mapLvl[7].maxBids = 7 ether;
        mapLvl[8].maxBids = 10 ether;
        mapLvl[9].maxBids = 15 ether;
        mapLvl[10].maxBids = 20 ether;
        mapLvl[11].maxBids = 25 ether;
        mapLvl[12].maxBids = 30 ether;
        mapLvl[13].maxBids = 35 ether;
        mapLvl[14].maxBids = 40 ether;
        mapLvl[15].maxBids = 50 ether;
        mapLvl[16].maxBids = 60 ether;
        mapLvl[17].maxBids = 70 ether;
        mapLvl[18].maxBids = 80 ether;
        mapLvl[19].maxBids = 90 ether;
        mapLvl[20].maxBids = 100 ether;
        //        ------------
        mapLvl[1].XP = 20;
        mapLvl[2].XP = 50;
        mapLvl[3].XP = 90;
        mapLvl[4].XP = 150;
        mapLvl[5].XP = 230;
        mapLvl[6].XP = 350;
        mapLvl[7].XP = 500;
        mapLvl[8].XP = 700;
        mapLvl[9].XP = 1000;
        mapLvl[10].XP = 1500;
        mapLvl[11].XP = 2300;
        mapLvl[12].XP = 3500;
        mapLvl[13].XP = 5000;
        mapLvl[14].XP = 7000;
        mapLvl[15].XP = 10000;
        mapLvl[16].XP = 14000;
        mapLvl[17].XP = 20000;
        mapLvl[18].XP = 30000;
        mapLvl[19].XP = 50000;
        mapLvl[20].XP = 1000000000000000;
        //---------------------------
        mapLvl[1].IncreaseXpTime = 7200;
        mapLvl[2].IncreaseXpTime = 6900;
        mapLvl[3].IncreaseXpTime = 6600;
        mapLvl[4].IncreaseXpTime = 6300;
        mapLvl[5].IncreaseXpTime = 6000;
        mapLvl[6].IncreaseXpTime = 5700;
        mapLvl[7].IncreaseXpTime = 5400;
        mapLvl[8].IncreaseXpTime = 5100;
        mapLvl[9].IncreaseXpTime = 4800;
        mapLvl[10].IncreaseXpTime = 4500;
        mapLvl[11].IncreaseXpTime = 4200;
        mapLvl[12].IncreaseXpTime = 3900;
        mapLvl[13].IncreaseXpTime = 3600;
        mapLvl[14].IncreaseXpTime = 3300;
        mapLvl[15].IncreaseXpTime = 3000;
        mapLvl[16].IncreaseXpTime = 2400;
        mapLvl[17].IncreaseXpTime = 1800;
        mapLvl[18].IncreaseXpTime = 1200;
        mapLvl[19].IncreaseXpTime = 900;
        mapLvl[20].IncreaseXpTime = 600;
        //---------------------------
        mapLvl[1].HpRegenTime = 3600;
        mapLvl[2].HpRegenTime = 3000;
        mapLvl[3].HpRegenTime = 2700;
        mapLvl[4].HpRegenTime = 2400;
        mapLvl[5].HpRegenTime = 2100;
        mapLvl[6].HpRegenTime = 1800;
        mapLvl[7].HpRegenTime = 1500;
        mapLvl[8].HpRegenTime = 1200;
        mapLvl[9].HpRegenTime = 900;
        mapLvl[10].HpRegenTime = 720;
        mapLvl[11].HpRegenTime = 600;
        mapLvl[12].HpRegenTime = 540;
        mapLvl[13].HpRegenTime = 480;
        mapLvl[14].HpRegenTime = 420;
        mapLvl[15].HpRegenTime = 360;
        mapLvl[16].HpRegenTime = 300;
        mapLvl[17].HpRegenTime = 240;
        mapLvl[18].HpRegenTime = 180;
        mapLvl[19].HpRegenTime = 120;
        mapLvl[20].HpRegenTime = 60;
        //---------------------------
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

     // public function
    function restoreHP(uint256 _orcId) public payable checkOrcRegister (_orcId) {
        _checkOrcOwner(_orcId);
        require(msg.value == 0.1 ether, Errors.NOT_PAID_FEE);
        orcInfo[_orcId].startRegenerationHP = 0;
    }

    function changeName(uint256 _orcId, string memory _newName) public checkOrcRegister (_orcId) {
        _checkOrcOwner(_orcId);
        orcInfo[_orcId].name = _newName;
    }

    function increaseXp(uint256 _orcId) public checkOrcRegister (_orcId) {
        _checkOrcOwner(_orcId);
        uint256 lvl = orcInfo[_orcId].lvl;
        require(block.timestamp - orcInfo[_orcId].startRegenerationIncreaseXP > mapLvl[lvl].IncreaseXpTime, Errors.NOT_REGENERATIONS);
        uint256 rankFactor = _getIncreaseXpValueForRank(orcInfo[_orcId].rank);
        orcInfo[_orcId].XP += rankFactor;
        _checkLvlUp(_orcId);
        orcInfo[_orcId].startRegenerationIncreaseXP = block.timestamp;
    }

    function getXP(uint256 _orcId, uint256 _XP) public payable checkOrcRegister (_orcId) {
        _checkOrcOwner(_orcId);
        bool flag = true;
        uint256[5] memory xpList = [uint256(100), 500, 1000, 5000, 10000];
        for (uint256 i = 0; i < 5; i++) {
            if (xpList[i] == _XP) {
                require(mapXpPayValue[_XP] == msg.value, Errors.NOT_PAID_FEE);
                orcInfo[_orcId].XP += _XP;
                flag = false;
            }
        }
        if (flag) {
            revert(Errors.INVALID_VALUE);
        }
        _checkLvlUp(_orcId);
    }

    function getOrcRegenHPTime(uint _orcId) public view checkOrcRegister (_orcId) returns (uint regenHpTime){
        uint lvl = orcInfo[_orcId].lvl;
        uint timeRegen = mapLvl[lvl].HpRegenTime;
        uint startRegenerationHP = orcInfo[_orcId].startRegenerationHP;
        if (startRegenerationHP + timeRegen > block.timestamp) {
            return 0;
        } else {
            return block.timestamp - (startRegenerationHP + timeRegen);
        }
    }

    function getXpForNextLvl(uint _orcId) view private  checkOrcRegister (_orcId) returns (uint XPForNextLvl) {
        if (orcInfo[_orcId].lvl == 20) {
            XPForNextLvl = 0;
        } else {
            XPForNextLvl = mapLvl[orcInfo[_orcId].lvl].XP - orcInfo[_orcId].XP;
        }
        return XPForNextLvl;
    }

        function registrationOrc(uint _orcId, string memory _newName) public {
            _checkOrcOwner(_orcId);
            uint16[2500] memory rankList;
            uint rank_id;
            if (_orcId <= 2500 ){
                rankList = rankList_1;
                rank_id = _orcId;
            } else if ( _orcId <= 5000 ){
                rankList = rankList_2;
                rank_id = _orcId - 2500;
            }else if ( _orcId <= 7500 ){
                rankList = rankList_3;
                rank_id = _orcId - 5000;
            } else {
                rankList = rankList_4;
                rank_id = _orcId - 7500;
            }

            require(orcInfo[_orcId].rank == 0, Errors.IS_REGISTER);
            require(rankList[rank_id] != 0, Errors.NOT_RANK_LIST);
            orcInfo[_orcId].name = _newName;
            orcInfo[_orcId].rank = rankList[rank_id - 1];
            orcInfo[_orcId].lvl = 1;
            
        }
    //admin function
    
    function createRankLIst(uint part,uint16[2500] memory _rankList) public onlyOwner {
        if (part == 1) {
        rankList_1 = _rankList;
        }
        else if (part == 2){
            rankList_2 = _rankList;
        } else if (part == 3){
            rankList_3 = _rankList;
        } else {
            rankList_4 = _rankList;
        }
    }
   
   function setApprovedContract(address _contract,bool _status) public onlyOwner {
       approvedListContract[_contract] = _status;
   }

    function setPaidXpEtcValue(uint _XP, uint _paidValue) public onlyOwner {
        require(_XP == 100 || _XP == 500 || _XP == 1000 || _XP == 5000 || _XP == 10000, Errors.INVALID_VALUE);
        mapXpPayValue[_XP] = _paidValue;
    }

    function withdraw() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }
    //private function

    function _getRandomNum(uint minValue, uint maxValue) private view returns (uint randomNum){
        return uint(maxValue - (block.timestamp * minValue * 1103515245 / 65536) % (maxValue + 1 - minValue));
    }

    function _getIncreaseXpValueForRank(uint rank) view private returns (uint rankFactor) {
        if (rank <= 50) {
            rankFactor = _getRandomNum(15, 30);
        } else if (rank <= 100) {
            rankFactor = _getRandomNum(14, 25);
        } else if (rank <= 300) {
            rankFactor = _getRandomNum(12, 22);
        } else if (rank <= 600) {
            rankFactor = _getRandomNum(11, 20);
        } else if (rank < 1000) {
            rankFactor = _getRandomNum(10, 19);
        } else if (rank < 2000) {
            rankFactor = _getRandomNum(9, 18);
        } else if (rank < 3000) {
            rankFactor = _getRandomNum(8, 17);
        } else if (rank < 4000) {
            rankFactor = _getRandomNum(7, 16);
         } else if (rank < 5000) {
            rankFactor = _getRandomNum(6, 15);
         } else if (rank < 6000) {
            rankFactor = _getRandomNum(5, 14);
         } else if (rank < 7000) {
            rankFactor = _getRandomNum(4, 13);
         } else if (rank < 8000) {
            rankFactor = _getRandomNum(3, 12);
         } else if (rank < 9000) {
            rankFactor = _getRandomNum(2, 11);
        } else {
            rankFactor = _getRandomNum(1, 10);
        }
        return rankFactor;
    }
    

    function _checkLvlUp(uint _orcId) private {
        for (uint i = 1; i <= 20; i++){
            if (orcInfo[_orcId].XP < mapLvl[i].XP){
                orcInfo[_orcId].lvl = i;
                break ;
            }
        }
    }

    function _checkOrcOwner(uint _orcId) private view {
        
        require(msg.sender == ietcorc.ownerOf(_orcId), Errors.NOT_ORC_OWNER);

    }

    function _setOrcVictories(uint _orcId, uint256 _victories) external approvedContract {
        orcInfo[_orcId].Victories= _victories;
    }
    function _setOrcDefeats(uint _orcId, uint256 _defeats) external approvedContract {
        orcInfo[_orcId].Defeats= _defeats;
    }

    function _setOrcProfitETC(uint _orcId, int _profitETC) external approvedContract {
        orcInfo[_orcId].profitETC = _profitETC;
    }

    function _setOrcStartRegenerationHP(uint _orcId, uint256 _startRegenerationHP) external approvedContract {
        orcInfo[_orcId].startRegenerationHP = _startRegenerationHP;
    }
    function _setOrcFreezeStatus(uint _orcId, bool _freeze) external approvedContract {
        orcInfo[_orcId].freeze = _freeze;
    }
    function _setOrcXP(uint _orcId,  uint256 _XP) external approvedContract {
        orcInfo[_orcId].XP = _XP;
    }
    function _setProfitNFT(uint _orcId,  int _profitNFT) external approvedContract {
        orcInfo[_orcId].profitNFT = _profitNFT;
    }


    function checkLvlUp(uint _orcId) external  approvedContract {
        _checkLvlUp(_orcId);
    }
    
    function getOrcInfo(uint _orcId) external view approvedContract returns( uint256 lvl, uint256 rank, uint256 Victories, uint256 Defeats, int profitNFT, uint256 XP, uint256 startRegenerationHP, int profitETC, bool freeze) {
         lvl = orcInfo[_orcId].lvl;
         rank = orcInfo[_orcId].rank;
         Victories = orcInfo[_orcId].Victories; 
         Defeats = orcInfo[_orcId].Defeats; 
         profitNFT = orcInfo[_orcId].profitNFT; 
         XP = orcInfo[_orcId].XP; 
         startRegenerationHP = orcInfo[_orcId].startRegenerationHP; 
         profitETC = orcInfo[_orcId].profitETC;
         freeze = orcInfo[_orcId].freeze;                                                              
        return  (lvl ,rank ,Victories,Defeats ,profitNFT ,XP ,startRegenerationHP ,profitETC ,freeze) ;                                                                              
        
    }
    function getMapLvl(uint _orcId) external view approvedContract returns( uint256 maxBids, uint256 XP, uint256 IncreaseXpTime, uint256 HpRegenTime) {
        
        maxBids = mapLvl[_orcId].maxBids    ;
        XP = mapLvl[_orcId].XP    ;
        IncreaseXpTime = mapLvl[_orcId].IncreaseXpTime    ;
        HpRegenTime = mapLvl[_orcId].HpRegenTime    ;
    }

    
    // modifier initialization


    modifier approvedContract{
        require(approvedListContract[msg.sender] == true,  Errors.NOT_APPROVED_CONTRACT );
        _;
    }
    modifier checkOrcRegister (uint _orcId) {
        require(orcInfo[_orcId].rank != 0, Errors.NOT_REGISTRATION);
        _;
    }


    //=========================================
    fallback() external payable {
    }

    receive() external payable {
    }

}