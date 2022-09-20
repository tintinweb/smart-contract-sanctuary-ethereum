/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

pragma solidity 0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity 0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.0;



abstract contract Initializable {
   
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

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity 0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity 0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity 0.8.0;







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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity 0.8.0;




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

// File: new.sol

/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


pragma solidity 0.8.0;


interface IBEP20 {

        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        function sell(uint256 amount) external;
    }




contract StakingContract is Initializable , UUPSUpgradeable{

    using SafeMath for uint256;
    
    IBEP20 public genToken;
    IBEP20 public arenaToken;
    IBEP20 public busdToken;

    struct Stake {

        uint256 amount;
        uint256 genBonus;
        uint256 areenaBonus;
    }
        
    struct Player {

        uint256 battleCount;
        uint256 walletLimit;
        uint256 withdrawTime;
        uint256 activeBattles;
        uint256 winingBattles;
        uint256 losingBattles;
        uint256 totalGenBonus;
        uint256 referalAmount;
        uint256 totalArenaTokens;
        uint256 totalAmountStaked;
        uint256 genAmountPlusBonus;
        mapping(uint256 => Stake) battleRecord;
    }


    struct Battle {

        bool active;
        bool joined;
        bool leaved;
        bool completed;
        address loser;
        address winner;
        address joiner;
        address creator;
        uint256 battleTime;
        uint256 endingTime;
        uint256 stakeAmount;
        uint256 startingTime;
        uint256 riskPercentage;
        uint256 creatorStartingtime;

    }

    struct referenceInfo{
    
        uint256 creatorReferalAmount;
        uint256 joinerReferalAmount;
        address battleCreator;
        address battleJoiner;
        address creatorReferalPerson;
        address joinerReferalPerson;
    }

    address public owner;
    uint256 public battleId;
    uint256 public totalAreena;
    uint256 public lowerMileStone;
    uint256 public uppermileStone;
    uint256 public areenaInCirculation;
    uint256 public genRewardPercentage;
    uint256 public genRewardMultiplicationValue;
    

 

    mapping(uint256 => Battle) public battles;
    mapping(address => Player) public players;
    mapping(address => uint256) private genLastTransaction;
    mapping(address => uint256) private referalLastTransaction;
    mapping(address => uint256) private areenaLastTransaction;
    mapping(uint256 => mapping(address => uint256)) public stakeCount;
    mapping(address => mapping(address => bool)) public alreadyBatteled;
    mapping(address => uint256[]) public playerBattleIds;
    mapping(uint256 => referenceInfo) public referalPerson;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public claimRferalAmount;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public referalTime;


    address private treasuryWallet ;
    address private areenaWallet ;
    address private busdWallet ;

    // address private treasuryWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // address private areenaWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // address private busdWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;


//    uint256 private  totalAreena ;
    uint256 private minimumStake ;
    uint256[5] public stakeOptions;
    uint256[5] public riskOptions ;
   

    event createBattle(address indexed battleCreator, uint256 stakeAmount, uint256 indexed battleId);
    event battleCreator(address indexed battleCreator, uint256 stakeAmount, uint256 indexed battleId);
    event battleJoiner(address indexed battleJoiner, uint256 stakeAmount, uint256 indexed battleId);
    event winnerDetails(uint256 indexed winnerStakedAmount, uint256 winnerGenBonus, uint256 indexed winnerAreenaBonus);
    event loserDetails(uint256 indexed looserStakedAmount, uint256 looserGenBonus);
    event leaveBattleDetails(address creator, address joiner, uint256 _battleId);
    event withdrawThreePercentage(address withdrawerAddress, uint256 withdrawAmount, uint256 remainingAmount, uint256 nextTime);
    event withdrawFivePercentage(address withdrawerAddress, uint256 withdrawAmount, uint256 remainingAmount, uint256 nextTime);
    event withdrawSevenPercentage(address withdrawerAddress, uint256 withdrawAmount, uint256 remainingAmount, uint256 nextTime);
    event areenaBooster(address buyer, uint256 priceUserPaid, uint256 newWalletLimit);
    event claimReferalAmount(uint256 referalAmount, uint256 nextTime, uint256 castleAmount);
    event areenaTokenSold(address sellerAddress, uint256 lowerMileStone, uint256 upperMileStone);
    event referalInfo(address joinerRefaralPerson, address creatorReferalPerson, uint256 joinerReferalAmount, uint256 creatorReferalAmount, uint256 battleId, uint256 joinerReferalTime, uint256 creatorReferalTime);

    // constructor(address _genToken, address _arenaToken, address _busdToken){
        
    //     owner = msg.sender;
    //     genToken = IBEP20(_genToken);
    //     busdToken = IBEP20(_busdToken);
    //     arenaToken = IBEP20(_arenaToken);
    //     genRewardPercentage = 416667000000000; //0.000416667%
    //     genRewardMultiplicationValue = 1e9;     
    //     totalAreena = 10000*1e18;
    // }

     constructor() {
        _disableInitializers();
    }

function initialize(address _genToken, address _arenaToken, address _busdToken) initializer public {
       owner = msg.sender;
        genToken = IBEP20(_genToken);
        busdToken = IBEP20(_busdToken);
        arenaToken = IBEP20(_arenaToken);
        genRewardPercentage = 416667000000000; //0.000416667%
        genRewardMultiplicationValue = 1e9;     
        totalAreena = 10000*1e18;
     minimumStake = 25;
    stakeOptions = [35, 200, 450, 700, 1000];
  riskOptions = [25, 50, 75];
       treasuryWallet = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;
     areenaWallet = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;
     busdWallet = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;

    }





    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    
    function checkOption (uint256 amount) internal view returns(uint256){
        uint256 value;
        for(uint256 i =0; i < 5; i++){
            if(amount == stakeOptions[i]){
                value = stakeOptions[i];
                break;
            }
        }
        if (value !=0){
            return value;
        }
        else{
            return amount;
        }
    }


function Newupdate() public pure{
    uint256 amount = 1123;
   
}
    
    function CreateBattle(uint256 _amount, uint256 _riskPercentage, address _referalPerson) external {

        Player storage player = players[msg.sender];
        
        Battle storage battle = battles[battleId];
        battle.creator = msg.sender;
        
        uint256 stakeAmount = checkOption (_amount);
        stakeAmount = stakeAmount.mul(1e18);
        
        require(stakeAmount >= minimumStake, "You must stake atleast 25 Gen tokens to enter into the battle.");
        require(stakeAmount <= (stakeOptions[4].mul(1e18)), "You can not stake more then 1000 Gen tokens to create a battle.");
        
        require((genToken.balanceOf(battle.creator) + player.genAmountPlusBonus) >= stakeAmount,"You does not have sufficent amount of gen Token.");
        require(_riskPercentage == riskOptions[0] || _riskPercentage == riskOptions[1] || _riskPercentage == riskOptions[2], "Please chose the valid risk percentage.");
        
        require(battle.creator != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
            

        if(genToken.balanceOf(battle.creator) < stakeAmount){
            
            uint256 amountFromUser = genToken.balanceOf(battle.creator); 
            genToken.transferFrom(battle.creator, address(this), amountFromUser);
            
            uint256 amountFromAddress =  stakeAmount - amountFromUser;
            player.genAmountPlusBonus -= amountFromAddress;

        }
        else{
            genToken.transferFrom(battle.creator, address(this), stakeAmount);
        }


        emit createBattle(battle.creator,stakeAmount,battleId);

        referalPerson[battleId].creatorReferalPerson = _referalPerson;
        referalPerson[battleId].battleCreator = battle.creator;

        battleId++;
        battle.stakeAmount = stakeAmount;
        battle.riskPercentage = _riskPercentage;
        battle.creatorStartingtime = block.timestamp;

    }

    uint256 private creatorReferalAmount;
    uint256 private joinerReferalAmount;
    uint256 private sendCreatorDeductionAmount;
    uint256 private sendJoinerDeductionAmount;

    uint256 private joinerAfterDeductedAmount ;


    function JoinBattle(uint256 _amount, uint256 _battleId, address _joinerReferalPerson) public {

        Battle storage battle = battles[_battleId];
        Player storage player = players[msg.sender];
        battle.joiner = msg.sender;
    
        uint256 stakeAmount = _amount.mul(1e18);
        
        require(!battle.joined && !battle.leaved && battle.stakeAmount != 0, "You can not join this battle. This battle in not created yet!.");
        require(!battle.joined && !battle.leaved, "You can not join this battle. This battle may be already joined or completed."); 
        
        require(!alreadyBatteled[battle.creator][battle.joiner], "You can not create or join new battles with same person.");    
        require(!alreadyBatteled[battle.joiner][battle.creator], "You can not create or join new battles with same person.");  
        
        require(stakeAmount == battle.stakeAmount,"Enter the exact amount of tokens to be a part of this battle.");   
        require((genToken.balanceOf(battle.joiner) + player.genAmountPlusBonus) >= stakeAmount,"You does not have sufficent amount of gen Token.");
        
        require(battle.joiner != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        
        players[battle.creator].battleCount++;
        if(battle.creator != battle.joiner){
            player.battleCount++;
        }

        battle.startingTime = block.timestamp;
        battle.active = true;
        battle.joined = true;
        
        players[battle.creator].activeBattles++;
        if(battle.creator != battle.joiner){
            player.activeBattles++;
        }


        stakeCount[_battleId][battle.creator] = players[battle.creator].battleCount;
        stakeCount[_battleId][battle.joiner] = players[battle.joiner].battleCount;

        playerBattleIds[battle.joiner].push(_battleId);
        playerBattleIds[battle.creator].push(_battleId);
        
        uint256 creatorDeductedAmount = calculateCreatorPercentage(stakeAmount);
        uint256 creatorAfterDeductedAmount = stakeAmount - creatorDeductedAmount;

        uint256  joinerDeductedAmount = calculateJoinerPercentage(stakeAmount);
        joinerAfterDeductedAmount = stakeAmount - joinerDeductedAmount;

        if(genToken.balanceOf(msg.sender) < stakeAmount){

            uint256 amountFromUser = genToken.balanceOf(battle.joiner); 
            genToken.transferFrom(battle.joiner, address(this), amountFromUser);

            uint256 amountFromAddress =  stakeAmount - amountFromUser;
            player.genAmountPlusBonus -= amountFromAddress;
        }
        else{

            genToken.transferFrom(battle.joiner, address(this), stakeAmount);
        }

        ////////// Joiner_Referal_section /////////////

        joinerReferalAmount = calculateReferalPercentage(stakeAmount);
    
        referalPerson[_battleId].battleJoiner = battle.joiner;
        referalPerson[_battleId].joinerReferalPerson = _joinerReferalPerson;
        referalPerson[_battleId].joinerReferalAmount = joinerReferalAmount;
        
        sendJoinerDeductionAmount = joinerDeductedAmount - joinerReferalAmount; 
        genToken.transfer(treasuryWallet, sendJoinerDeductionAmount);

        players[_joinerReferalPerson].referalAmount += joinerReferalAmount;

        uint256 joinerReferalTime = block.timestamp;
        referalTime[_battleId][battle.joiner][_joinerReferalPerson] = joinerReferalTime;
        
        settingReferalInfo(joinerReferalTime,joinerReferalAmount, _joinerReferalPerson, battle.joiner);

        ////////// Creator_Referal_section /////////////
        
        creatorReferalAmount = calculateReferalPercentage(stakeAmount);
        
        referalPerson[_battleId].creatorReferalAmount = creatorReferalAmount;
        
        sendCreatorDeductionAmount = creatorDeductedAmount - creatorReferalAmount;
        genToken.transfer(treasuryWallet, sendCreatorDeductionAmount);
            
        players[referalPerson[_battleId].creatorReferalPerson].referalAmount += creatorReferalAmount;

        uint256 creatorReferalTime = block.timestamp;
        referalTime[_battleId][battle.creator][referalPerson[_battleId].creatorReferalPerson] = creatorReferalTime;
            
        settingReferalInfo(creatorReferalTime,creatorReferalAmount, referalPerson[_battleId].creatorReferalPerson, battle.creator);

        alreadyBatteled[battle.creator][battle.joiner] = true;
        alreadyBatteled[battle.joiner][battle.creator] = true;

        
        player.totalAmountStaked += joinerAfterDeductedAmount;
        players[battle.creator].totalAmountStaked +=  creatorAfterDeductedAmount;
        players[battle.creator].battleRecord[stakeCount[_battleId][battle.creator]].amount = creatorAfterDeductedAmount;
        players[battle.joiner].battleRecord[stakeCount[_battleId][battle.joiner]].amount = joinerAfterDeductedAmount;    


        emit referalInfo(
            _joinerReferalPerson, 
            referalPerson[_battleId].creatorReferalPerson,
            referalPerson[_battleId].joinerReferalAmount,
            referalPerson[_battleId].creatorReferalAmount, 
            _battleId,
            joinerReferalTime,
            creatorReferalTime
        );

         emit battleJoiner(
            battle.joiner,
            stakeAmount,
            _battleId
        );

        emit battleCreator(
            battle.creator, 
            players[battle.creator].battleRecord[players[battle.creator].battleCount].amount,
            _battleId
        );

    }

    function settingReferalInfo(uint256 _referalTime, uint256 _referalAmount, address _referalPerson, 
        address _battlePerson) internal {	
			claimRferalAmount[_battlePerson][_referalPerson][_referalTime] = _referalAmount;
	}

    
    uint256 private totalMinutes;

    function LeaveBattle(uint256 _battleId) public {

        Battle storage battle = battles[_battleId];

        require(msg.sender == battle.creator || msg.sender == battle.joiner, "You must be a part of a battle before leaving it.");
        require(!battle.leaved, "You canot join this battle because battle creator Already leaved.");
       
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        if(!battle.joined)
        {
           
           if(block.timestamp > (battle.startingTime + 15 minutes)) //////////////////////48 hours add
           {

                 uint256 _tokenAmount = battle.stakeAmount;
            
                uint256 deductedAmount = calculateSendBackPercentage(_tokenAmount);

                _tokenAmount = _tokenAmount - deductedAmount;
                players[battle.creator].genAmountPlusBonus += _tokenAmount;
                genToken.transfer(treasuryWallet, deductedAmount); 

                battle.leaved = true;
                
            }
            else{

                players[battle.creator].genAmountPlusBonus += battle.stakeAmount;
                battle.leaved = true;

            }

        }
        else{

            require( !battle.completed,"This battle is already ended.");

            if(msg.sender == battle.creator){
                battle.loser = battle.creator;
                battle.winner = battle.joiner;
            }
            else{
                battle.loser = battle.joiner;
                battle.winner = battle.creator; 
            }

            
            uint256 losertokenAmount = players[battle.loser].battleRecord[stakeCount[_battleId][battle.loser]].amount;
            uint256 winnertokenAmount = players[battle.winner].battleRecord[stakeCount[_battleId][battle.winner]].amount;

            totalMinutes =  calculateTotalMinutes(block.timestamp, battle.startingTime);
 
            uint256 loserGenReward = calculateRewardInGen(losertokenAmount, totalMinutes);
            uint256 winnerGenReward = calculateRewardInGen(winnertokenAmount, totalMinutes);
     
            uint256 riskDeductionFromLoser = calculateRiskPercentage(loserGenReward, battle.riskPercentage);
             
            uint256 loserFinalGenReward = loserGenReward - riskDeductionFromLoser;

            uint256 winnerAreenaReward = calculateRewardInAreena(battle.stakeAmount, totalMinutes);
 
            uint256 sendWinnerGenReward =  winnerGenReward + riskDeductionFromLoser + winnertokenAmount;
            uint256 sendLoserGenReward =  losertokenAmount + loserFinalGenReward;

            
            areenaInCirculation += winnerAreenaReward;
            battle.endingTime = block.timestamp;
            battle.battleTime = totalMinutes;
            battle.completed = true;
            battle.active = false;

            players[battle.winner].winingBattles++;
            players[battle.winner].genAmountPlusBonus += sendWinnerGenReward;
            players[battle.winner].totalArenaTokens += winnerAreenaReward;
            players[battle.loser].losingBattles++;
            players[battle.loser].genAmountPlusBonus += sendLoserGenReward;
            players[battle.winner].totalGenBonus += (winnerGenReward + riskDeductionFromLoser);
            players[battle.loser].totalGenBonus += loserFinalGenReward;
            
            players[battle.winner].battleRecord[stakeCount[_battleId][battle.winner]].genBonus = (winnerGenReward + riskDeductionFromLoser);
            players[battle.winner].battleRecord[stakeCount[_battleId][battle.winner]].areenaBonus = winnerAreenaReward;
            players[battle.loser].battleRecord[stakeCount[_battleId][battle.loser]].genBonus = loserFinalGenReward;
            
            if(battle.creator != battle.joiner){
                players[battle.winner].activeBattles--;
            }
            players[battle.loser].activeBattles--;

            emit leaveBattleDetails(
                battle.creator,
                battle.joiner, 
                _battleId
            );
            
            emit winnerDetails(
                winnertokenAmount, 
                (winnerGenReward + riskDeductionFromLoser), 
                winnerAreenaReward
            );
            
            emit loserDetails(
                losertokenAmount,
                loserFinalGenReward
            );
        }
    }
    

    function GenWithdraw(uint256 _percentage) external {

        Player storage player = players[msg.sender];
        
        require(player.genAmountPlusBonus > 0, "You do not have sufficent amount of tokens to withdraw.");

        if(_percentage == 3){
            
            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 13 minutes");
            genLastTransaction[msg.sender] = block.timestamp + 13 minutes; //hours/////////////////////////

            uint256 sendgenReward = calculateWithdrawThreePercentage(player.genAmountPlusBonus);
            genToken.transfer(msg.sender,sendgenReward);
            
            player.genAmountPlusBonus -= sendgenReward;
            player.withdrawTime = genLastTransaction[msg.sender];

            emit withdrawThreePercentage(msg.sender, sendgenReward, player.genAmountPlusBonus, genLastTransaction[msg.sender]);
        }
        else if(_percentage == 5){
            
            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 15 minutes");
            genLastTransaction[msg.sender] = block.timestamp + 15 minutes; //hours//////////////////////

            uint256 sendgenReward = calculateWithdrawFivePercentage(player.genAmountPlusBonus);
            genToken.transfer(msg.sender,sendgenReward);

            player.genAmountPlusBonus -= sendgenReward;
            player.withdrawTime = genLastTransaction[msg.sender];

            emit withdrawFivePercentage(msg.sender, sendgenReward, player.genAmountPlusBonus, genLastTransaction[msg.sender]);
        }
        else if(_percentage == 7){

            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 17 minutes");
            genLastTransaction[msg.sender] = block.timestamp + 17 minutes; //hours/////////////////

            uint256 sendgenReward = calculateWithdrawSevenPercentage(player.genAmountPlusBonus);
            genToken.transfer(msg.sender,sendgenReward);
            
            player.genAmountPlusBonus -= sendgenReward;
            player.withdrawTime = genLastTransaction[msg.sender];

            emit withdrawSevenPercentage(msg.sender, sendgenReward, player.genAmountPlusBonus, genLastTransaction[msg.sender]);

        }
        else{

            require(_percentage == 3 || _percentage == 5 || _percentage == 7, "Enter the right amount of percentage.");
        }
    }

     function calculateAreenaPrice() public view returns (uint256 _areenaValue){
       
        uint256 _busdWalletBalance = BusdInTreasury();
        _areenaValue = _busdWalletBalance.div(10000);
        
        uint256 _initialPercentage = 7500; // 75 % 
        return _areenaValue.mul(_initialPercentage).div(10000);

    }

    function calculateAreenaBosterPrice() public view returns(uint256){
        
        uint256 areenaInTreasury = AreenaInTreasury();
        uint256 ABV = BusdInTreasury().mul(1e18);
        
        uint256 findValue = (ABV.div(areenaInTreasury));
        uint256 bosterPercentage = calculateBosterPercentage(findValue);

        return bosterPercentage;
	}

    function BuyAreenaBoster() external {

        Player storage player = players[msg.sender];

        if(player.walletLimit == 0){
            player.walletLimit = 1*1e18;
        }

        uint256 _areenaBosterPrice = calculateAreenaBosterPrice();

        require(busdToken.balanceOf(msg.sender) >= _areenaBosterPrice, "You didnt have enough amount of USD to buy Areena Boster.");
        busdToken.transferFrom(msg.sender, busdWallet, _areenaBosterPrice);

        player.walletLimit += 3*1e18;

        emit areenaBooster(msg.sender, _areenaBosterPrice, player.walletLimit);
    }

    
    bool private onceGreater;
    
     function sell(uint256 _tokenAmount) external {
        
        uint256 _realTokenAmount = _tokenAmount.mul(1e18);

         Player storage player = players[msg.sender];

        if(player.walletLimit == 0){
            player.walletLimit = 1*1e18;
        }

        uint256 _walletLimit = player.walletLimit;

        require(_realTokenAmount < _walletLimit,"Please Buy Areena Boster To get All of your reward.");
        require(_realTokenAmount <= (3*1e18), "You can sell only three areena Token per day.");
        
        require(owner != address(0), "ERC20: approve from the zero address");
        require(msg.sender != address(0), "ERC20: approve to the zero address");
        
        require(players[msg.sender].totalArenaTokens >= _realTokenAmount, "You do not have sufficient amount of balance.");
        
        if(!onceGreater){
            require((busdToken.balanceOf(busdWallet) + (90000 * 1e18)) >= (101000*1e18),
            "Selling of Areena token will start when BusdTreasury wallet reaches 101000.");
            onceGreater = true;
        }

        
        lowerMileStone = 101000*1e18;
        uppermileStone = 102000*1e18;
        
        require((busdToken.balanceOf(busdWallet) + (90000 * 1e18)) > lowerMileStone &&
                (busdToken.balanceOf(busdWallet) + (90000 * 1e18)) < uppermileStone,
                "Areena selling Start when busdTreasury will be greater then lower milestone.");

    
        // console.log("lower mileStone: ",lowerMileStone );
        // console.log("uppermileStone: ",uppermileStone );
        
        if((busdToken.balanceOf(busdWallet) + (90000 * 1e18)) > lowerMileStone && 
           (busdToken.balanceOf(busdWallet) + (90000 * 1e18)) <= uppermileStone){

            require(block.timestamp > areenaLastTransaction[msg.sender],"You canot sell areena token again before 24 hours.");
                
            uint256 sendAmount = _tokenAmount.mul(calculateAreenaPrice());
            uint256 checkBalance = (busdToken.balanceOf(busdWallet) + (90000 * 1e18)) - sendAmount;

                //  console.log("sendAmount: ",sendAmount );
                // console.log("checkBalance: ",checkBalance );
                // console.log("lower mileStone: ",lowerMileStone );

            require(checkBalance > lowerMileStone, 
                    "You couldent sell Areena untill busd amount reaches to a certain level."); 
            
            busdToken.transferFrom(busdWallet,msg.sender, sendAmount);   

            areenaInCirculation -= _realTokenAmount;
            players[msg.sender].totalArenaTokens -= _realTokenAmount;
                
            areenaLastTransaction[msg.sender] = block.timestamp + 4 minutes;//////////hours////////////////
            emit areenaTokenSold(msg.sender, lowerMileStone, uppermileStone);
        
        }

        uint256 walletSize = (busdToken.balanceOf(busdWallet) + (90000 * 1e18));

        if(walletSize >= uppermileStone){
            lowerMileStone = uppermileStone.add(1000);
            uppermileStone = uppermileStone.add(1000);
        }


    }


    function claimReferalBonus(uint256 _battleId) public returns(bool v){

        Battle memory battle = battles[_battleId];

        
        if(msg.sender == referalPerson[_battleId].creatorReferalPerson){

            
            uint256 referallTime = referalTime[_battleId][battle.creator][msg.sender];
            require(block.timestamp > referallTime.add(7 minutes),"You can not claim bonus before 7 minutes."); //////////Add 7 days here /////////
            
            uint256 referallAmount = claimRferalAmount[battle.creator][msg.sender][referallTime];

            require(players[msg.sender].genAmountPlusBonus > (referallAmount.mul(5)), "Your castle gen amount must be five times of your referal amount");
            
            players[msg.sender].referalAmount -= referallAmount;
            players[msg.sender].genAmountPlusBonus += referallAmount;

            return true;
        }
        else if(msg.sender == referalPerson[_battleId].joinerReferalPerson){

            uint256 referallTime = referalTime[_battleId][battle.joiner][msg.sender];
            require(block.timestamp > referallTime.add(7 minutes),"You can not claim bonus before 7 minutes."); //////////Add 7 days here /////////

            uint256 referallAmount = claimRferalAmount[battle.joiner][msg.sender][referallTime];
            require(players[msg.sender].genAmountPlusBonus > (referallAmount.mul(5)), "Your castle gen amount must be five times of your referal amount");
            
            players[msg.sender].referalAmount -= referallAmount;
            players[msg.sender].genAmountPlusBonus += referallAmount;

            return true;
        }
        else {
            bool referallPerson;
            require(referallPerson, "You can not claim reward because you are not the referalPerson of this battle.");
            
            return false;
        }
    }

    
    function calculateZValue(uint zValue) public pure returns (uint256) {
         
         return (zValue % 100 == 0)?(zValue / 100 ): ((zValue / 100)+1);
    }

    function calculateRewardInAreena (uint256 _amount, uint256 _battleLength) public view  returns(uint256){

        uint256 realAreena = (totalAreena - areenaInCirculation).div(1e18);
        return (((calculateZValue(realAreena) *_amount).div(525600)).mul(_battleLength)).div(100);
    }

    function calculateRewardInGen(uint256 _amount, uint256 _totalMinutes) public view returns(uint256){
 
        uint256 _initialPercentage = genRewardPercentage;
        _initialPercentage = (_initialPercentage * _totalMinutes).div(genRewardMultiplicationValue);
        
        uint256 value =  ((_amount.mul(_initialPercentage)).div(100 * genRewardMultiplicationValue));
        return value;
    }

    function calculateBosterPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 7500; // 25 * 3 = 75 % 
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateReferalPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 500; // 5 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawThreePercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 300; // 3 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawFivePercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 500; // 5 %
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    function calculateWithdrawSevenPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 700; // 7 %
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    
    function calculateTotalMinutes(uint256 _endingTime, uint256 _startingTime) public pure returns(uint256 _totalMinutes){

        _totalMinutes = ((_endingTime - _startingTime) / 60); // in minutes!
        return _totalMinutes;
    } 

    function calculateJoinerPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 3000; // 30 %
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    
    function calculateCreatorPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 2000; // 20 % 
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateRiskPercentage(uint256 _amount, uint256 _riskPercentage ) public pure returns(uint256){

        uint256 _initialPercentage =_riskPercentage.mul(100) ;
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateSendBackPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 300; // 3 %
        return _amount.mul(_initialPercentage).div(10000);
    }


    function playerStakeDetails(address _playerAddress,uint battleCount) public view returns(Stake memory){
        
        Player storage player = players[_playerAddress];
        return player.battleRecord[battleCount];
    }

    function setGenRewardPercentage(uint256 _percentage, uint256 value) external  onlyOwner {
        genRewardMultiplicationValue = value;
        genRewardPercentage = _percentage.mul(value);
    }

    function getAreenaPrice() public view returns(uint256){
        return calculateAreenaPrice();
    }

    function setTreasuryWallet(address _walletAddress) external onlyOwner {
        treasuryWallet = _walletAddress;
    }
    
    function setAreenaWallet(address _walletAddress) external onlyOwner {
        areenaWallet = _walletAddress;
    }

    function setBusdWallet(address _walletAddress) external onlyOwner {
        busdWallet = _walletAddress;
    }

    function getGenRewardPercentage() external view returns(uint256) {
        uint256 genReward = genRewardPercentage.div(genRewardMultiplicationValue);
        return genReward;
    }

    function plateformeEarning () public view returns(uint256){
        return genToken.balanceOf(treasuryWallet);
    }

    function addContractBalance (uint256 _amount) external onlyOwner {
        genToken.transferFrom(treasuryWallet, address(this), _amount);
    }

    // get players battle Ids.    
    function getAllBattleIds(address _playerAddress) external view returns (uint256[] memory)
    {
        return playerBattleIds[_playerAddress];
    }

    function getContractBalance () public view onlyOwner returns(uint256){
        return genToken.balanceOf(address(this));
    }

    function AreenaInTreasury() public view returns(uint256){
        
        uint256 realAreena = totalAreena - areenaInCirculation;
        return realAreena;
    }

    function GenInTreasury() external view returns(uint256){
        return genToken.balanceOf(treasuryWallet);
    }
     
    function BusdInTreasury() public view returns(uint256){
        return (busdToken.balanceOf(busdWallet) + (90000 * 1e18));
    }

    function getAreenaBosterPrice() external view returns(uint256){  
        return calculateAreenaBosterPrice();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    
}