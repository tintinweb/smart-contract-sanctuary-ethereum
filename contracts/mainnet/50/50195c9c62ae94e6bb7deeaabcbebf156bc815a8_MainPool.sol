/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

// License: MIT
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


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

// License: MIT
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]

// License: MIT
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/interfaces/IERC20Receiver.sol

// License: MIT
pragma solidity 0.8.11;

/**
 * @title ERC20 token receiver interface
 *
 * @dev Interface for any contract that wants to support safe transfers
 *      from ERC20 token smart contracts.
 * @dev Inspired by ERC721 and ERC223 token standards
 *
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * @dev See https://github.com/ethereum/EIPs/issues/223
 * @author Basil Gorin
 * Adapted for Syn City by Superpower Labs
 */
interface IERC20Receiver {
  /**
   * @notice Handle the receipt of a ERC20 token(s)
   * @dev The ERC20 smart contract calls this function on the recipient
   *      after a successful transfer (`safeTransferFrom`).
   *      This function MAY throw to revert and reject the transfer.
   *      Return of other than the magic value MUST result in the transaction being reverted.
   * @notice The contract address is always the message sender.
   *      A wallet/broker/auction application MUST implement the wallet interface
   *      if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _value amount of tokens which is being transferred
   * @param _data additional data with no specified format
   * @return `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` unless throwing
   */
  function onERC20Received(
    address _operator,
    address _from,
    uint256 _value,
    bytes calldata _data
  ) external returns (bytes4);
}


// File contracts/token/TokenReceiver.sol

// License: MIT
pragma solidity 0.8.11;


//import "hardhat/console.sol";

contract TokenReceiver is IERC20Receiver, IERC721ReceiverUpgradeable {
  function onERC20Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC20Received.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}


// File contracts/interfaces/IMainUser.sol

// License: MIT
pragma solidity 0.8.11;

interface IMainUser {
  event DepositSaved(address indexed user, uint16 indexed mainIndex);
  event DepositUnlocked(address indexed user, uint16 indexed mainIndex);

  struct Deposit {
    // @dev token type (0: sSYNR, 1: SYNR, 2: SYNR Pass...
    uint8 tokenType;
    // @dev locking period - from
    uint32 lockedFrom;
    // @dev locking period - until
    uint32 lockedUntil;
    // @dev token amount staked
    // SYNR maxTokenSupply is 10 billion * 18 decimals = 1e28
    // which is less type(uint96).max (~79e28)
    uint96 tokenAmountOrID;
    uint32 unlockedAt;
    uint16 otherChain;
    // since the process is asyncronous, the same deposit can be at a different mainIndex
    // on the main net and on the sidechain.
    uint16 mainIndex;
    // available space for an extra variable
    uint24 extra;
  }

  /// @dev Data structure representing token holder using a pool
  struct User {
    // @dev Total staked SYNR amount
    uint96 synrAmount;
    // @dev Total passes staked
    uint16 passAmount;
    Deposit[] deposits;
  }
}


// File contracts/interfaces/IMainPool.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// (c) 2022+ SuperPower Labs Inc.

interface IMainPool is IMainUser {
  event PoolInitiated(uint16 minimumLockupTime, uint16 earlyUnstakePenalty);
  event PoolPaused(bool isPaused);
  event BridgeSet(address bridge);
  event BridgeRemoved(address bridge);
  event ImplementationUpgraded(address newImplementation);

  struct Conf {
    uint8 status;
    uint16 minimumLockupTime;
    uint16 maximumLockupTime;
    uint16 earlyUnstakePenalty;
    // TVL
    uint16 passAmount;
    uint96 synrAmount;
    // reserved for future variables
    uint32 reserved1;
    uint32 reserved2;
    uint24 reserved3;
  }

  function setBridge(address bridge_, bool active) external;

  function getDepositByIndex(address user, uint256 index) external view returns (Deposit memory);

  function getDepositsLength(address user) external view returns (uint256);

  function initPool(uint16 minimumLockupTime_, uint16 earlyUnstakePenalty_) external;

  function getVestedPercentage(
    uint256 when,
    uint256 lockedFrom,
    uint256 lockedUntil
  ) external view returns (uint256);

  function calculatePenaltyForEarlyUnstake(uint256 when, IMainPool.Deposit memory deposit) external view returns (uint256);

  function withdrawSSynr(uint256 amount, address to) external;

  function withdrawPenalties(uint256 amount, address to) external;

  function stake(
    address user,
    uint256 payload,
    uint16 recipientChain
  ) external returns (uint256);

  function unstake(
    address user,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 mainIndex,
    uint256 tokenAmountOrID
  ) external;

  function pausePool(bool paused) external;

  function validateInput(
    uint256 tokenType,
    uint256 lockupTime,
    uint256 tokenAmountOrID
  ) external pure returns (bool);

  function deserializeInput(uint256 payload)
    external
    pure
    returns (
      uint256 tokenType,
      uint256 lockupTime,
      uint256 tokenAmountOrID
    );

  function getIndexFromPayload(uint256 payload) external pure returns (uint256);
}


// File contracts/interfaces/ISyndicateERC20.sol

// License: MIT
pragma solidity 0.8.11;

interface ISyndicateERC20 {
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes memory _data
  ) external;
}


// File contracts/interfaces/ISyntheticSyndicateERC20.sol

// License: MIT
pragma solidity 0.8.11;

interface ISyntheticSyndicateERC20 {
  function balanceOf(address owner) external view returns (uint256);

  function approve(address spender, uint256 amount) external;

  function isOperatorInRole(address operator, uint256 required) external view returns (bool);

  function transferFrom(
    address to,
    address receiver,
    uint256 tokenId
  ) external;
}


// File contracts/interfaces/IERC721Minimal.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// Superpower Labs / Syn City

interface IERC721Minimal {
  function safeTransferFrom(
    address to,
    address receiver,
    uint256 tokenId
  ) external;
}


// File contracts/utils/Constants.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// (c) 2022+ SuperPower Labs Inc.

contract Constants {
  uint8 public constant S_SYNR_SWAP = 1;
  uint8 public constant SYNR_STAKE = 2;
  uint8 public constant SYNR_PASS_STAKE_FOR_BOOST = 3;
  uint8 public constant SYNR_PASS_STAKE_FOR_SEEDS = 4;
  uint8 public constant BLUEPRINT_STAKE_FOR_BOOST = 5;
  uint8 public constant BLUEPRINT_STAKE_FOR_SEEDS = 6;

  uint256[50] private __gap;
}


// File contracts/utils/Versionable.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// (c) 2022+ SuperPower Labs Inc.

contract Versionable {
  function version() external pure virtual returns (uint256) {
    return 1;
  }
}


// File contracts/pool/MainPool.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// (c) 2022+ SuperPower Labs Inc.











//import "hardhat/console.sol";

contract MainPool is IMainPool, Versionable, Constants, TokenReceiver, Initializable, OwnableUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  // users and deposits
  mapping(address => User) public users;
  Conf public conf;

  ISyndicateERC20 public synr;
  ISyntheticSyndicateERC20 public sSynr;
  IERC721Minimal public pass;

  uint256 public penalties;

  mapping(address => bool) public bridges;

  modifier onlyBridge() {
    require(bridges[_msgSender()], "MainPool: forbidden");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    address synr_,
    address sSynr_,
    address pass_
  ) public initializer {
    // solhint-disable-next-line
    __Ownable_init();
    require(synr_.isContract(), "synr_ not a contract");
    require(sSynr_.isContract(), "sSynr_ not a contract");
    require(pass_.isContract(), "pass_ not a contract");
    synr = ISyndicateERC20(synr_);
    sSynr = ISyntheticSyndicateERC20(sSynr_);
    pass = IERC721Minimal(pass_);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
    emit ImplementationUpgraded(newImplementation);
  }

  function _updateTvl(
    uint256 tokenType,
    uint256 tokenAmount,
    bool increase
  ) internal {
    if (increase) {
      if (tokenType == SYNR_STAKE) {
        conf.synrAmount += uint96(tokenAmount);
      } else if (tokenType == SYNR_PASS_STAKE_FOR_BOOST || tokenType == SYNR_PASS_STAKE_FOR_SEEDS) {
        conf.passAmount++;
      }
    } else {
      if (tokenType == SYNR_STAKE) {
        conf.synrAmount = uint96(uint256(conf.synrAmount).sub(tokenAmount));
      } else {
        conf.passAmount--;
      }
    }
  }

  function setBridge(address bridge_, bool active) external override onlyOwner {
    require(bridge_.isContract(), "SeedPool: bridge_ not a contract");
    if (active) {
      bridges[bridge_] = true;
      emit BridgeSet(bridge_);
    } else {
      delete bridges[bridge_];
      emit BridgeRemoved(bridge_);
    }
  }

  function initPool(uint16 minimumLockupTime_, uint16 earlyUnstakePenalty_) external override onlyOwner {
    require(sSynr.isOperatorInRole(address(this), 0x0004_0000), "MainPool: contract cannot receive sSYNR");
    require(conf.maximumLockupTime == 0, "MainPool: already initiated");
    conf = Conf({
      status: 1,
      minimumLockupTime: minimumLockupTime_,
      maximumLockupTime: 365,
      earlyUnstakePenalty: earlyUnstakePenalty_,
      passAmount: 0,
      synrAmount: 0,
      reserved1: 0,
      reserved2: 0,
      reserved3: 0
    });
    emit PoolInitiated(minimumLockupTime_, earlyUnstakePenalty_);
  }

  function pausePool(bool paused) external onlyOwner {
    conf.status = paused ? 2 : 1;
    emit PoolPaused(paused);
  }

  /**
   * @notice Converts the input payload to the transfer payload
   * @param deposit The deposit
   * @return the payload, an encoded uint256
   */
  function _fromDepositToTransferPayload(Deposit memory deposit) internal pure returns (uint256) {
    return
      uint256(deposit.tokenType)
        .add(uint256(deposit.lockedFrom).mul(100))
        .add(uint256(deposit.lockedUntil).mul(1e12))
        .add(uint256(deposit.mainIndex).mul(1e22))
        .add(uint256(deposit.tokenAmountOrID).mul(1e27));
  }

  /**
   * @notice updates the user with the staked amount or the pass amount and creates new deposit for the user
   * @param user address of user being updated
   * @param tokenType identifies the type of transaction being made, 0=SSYNR, 1=SYNR, 2 or 3 = SYNR PASS.
   * @param lockedFrom timestamp when locked
   * @param lockedUntil timestamp when can unstake without penalty
   * @param tokenAmountOrID ammount of tokens being staked, in the case where a SYNR Pass is being staked, it identified its ID
   * @param otherChain chainID of recieving chain
   * @param mainIndex index of deposit being updated
   * @return the new deposit
   */
  function _updateUserAndAddDeposit(
    address user,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 tokenAmountOrID,
    uint16 otherChain,
    uint256 mainIndex
  ) internal returns (Deposit memory) {
    if (tokenType == SYNR_STAKE) {
      users[user].synrAmount += uint96(tokenAmountOrID);
    } else if (tokenType == SYNR_PASS_STAKE_FOR_BOOST || tokenType == SYNR_PASS_STAKE_FOR_SEEDS) {
      users[user].passAmount++;
    }
    _updateTvl(tokenType, tokenAmountOrID, true);
    Deposit memory deposit = Deposit({
      tokenType: uint8(tokenType),
      lockedFrom: uint32(lockedFrom),
      lockedUntil: uint32(lockedUntil),
      tokenAmountOrID: uint96(tokenAmountOrID),
      unlockedAt: 0,
      otherChain: otherChain,
      mainIndex: uint16(mainIndex),
      extra: 0
    });
    users[user].deposits.push(deposit);
    return deposit;
  }

  /**
   * @notice Searches for deposit from the user and its index
   * @param user address of user who made deposit being searched
   * @param index index of the deposit being searched
   * @return the deposit
   */
  function getDepositByIndex(address user, uint256 index) external view override returns (Deposit memory) {
    if (users[user].deposits.length <= index || users[user].deposits[index].lockedFrom == 0) {
      Deposit memory deposit;
      return deposit;
    } else {
      return users[user].deposits[index];
    }
  }

  /**
   * @param user address of user
   * @return the ammount of deposits a user has made
   */
  function getDepositsLength(address user) public view override returns (uint256) {
    return users[user].deposits.length;
  }

  /**
   * @notice makes the deposit
   * @param tokenType identifies the type of transaction being made, 0=SSYNR, 1=SYNR, 2 or 3 = SYNR PASS.
   * @param lockupTime time the staking will take
   * @param tokenAmountOrID ammount of tokens being staked, in the case where a SYNR Pass is being staked, it identified its ID
   * @param otherChain chainID of recieving chain
   * @return the TransferPayload calculated from the deposit
   */
  function _makeDeposit(
    address user,
    uint256 tokenType,
    uint256 lockupTime,
    uint256 tokenAmountOrID,
    uint16 otherChain
  ) internal returns (uint256) {
    require(tokenType < BLUEPRINT_STAKE_FOR_BOOST, "MainPool: invalid tokenType");
    validateInput(tokenType, lockupTime, tokenAmountOrID);
    if (tokenType == S_SYNR_SWAP || tokenType == SYNR_STAKE) {
      require(tokenAmountOrID >= 1e18, "MainPool: must stake at least one unity");
    }
    if (tokenType == SYNR_STAKE || tokenType == SYNR_PASS_STAKE_FOR_SEEDS) {
      require(
        lockupTime > conf.minimumLockupTime - 1 && lockupTime < conf.maximumLockupTime + 1,
        "MainPool: invalid lockupTime type"
      );
    }
    // Contract must be approved as spender.
    // It will throw if the balance is insufficient
    if (tokenType == S_SYNR_SWAP) {
      // MainPool must be whitelisted to receive sSYNR
      sSynr.transferFrom(user, address(this), tokenAmountOrID);
    } else if (tokenType == SYNR_STAKE) {
      // MainPool must be approved to spend the SYNR
      synr.safeTransferFrom(user, address(this), tokenAmountOrID, "");
    } else {
      // SYNR Pass
      // MainPool must be approved to make the transfer
      pass.safeTransferFrom(user, address(this), tokenAmountOrID);
    }
    return _fromDepositToTransferPayload(_updateUser(user, tokenType, lockupTime, tokenAmountOrID, otherChain));
  }

  /**
   * @notice updates the user, calls _updateUserAndAddDeposit
   * @param user address of user being updated
   * @param tokenType identifies the type of transaction being made, 0=SSYNR, 1=SYNR, 2 or 3 = SYNR PASS.
   * @param lockupTime time the staking will take
   * @param tokenAmountOrID ammount of tokens being staked, in the case where a SYNR Pass is being staked, it identified its ID
   * @param otherChain chainID of recieving chain
   * @return the deposit
   */
  function _updateUser(
    address user,
    uint256 tokenType,
    uint256 lockupTime,
    uint256 tokenAmountOrID,
    uint16 otherChain
  ) internal returns (Deposit memory) {
    uint256 lockedUntil = tokenType == SYNR_STAKE || tokenType == SYNR_PASS_STAKE_FOR_SEEDS
      ? uint32(block.timestamp.add(lockupTime * 1 days))
      : 0;
    Deposit memory deposit = _updateUserAndAddDeposit(
      user,
      tokenType,
      uint32(block.timestamp),
      lockedUntil,
      tokenAmountOrID,
      otherChain,
      getDepositsLength(user)
    );
    return deposit;
  }

  /**
   * @notice unstakes a deposit, calculates penalty for early unstake
   * @param user address of user
   * @param tokenType identifies the type of transaction being made, 0=SSYNR, 1=SYNR, 2 or 3 = SYNR PASS.
   * @param lockedFrom timestamp when locked
   * @param lockedUntil timestamp when can unstake without penalty
   * @param mainIndex index of deposit
   * @param tokenAmountOrID ammount of tokens being staked, in the case where a SYNR Pass is being staked, it identified its ID
   */
  function _unstake(
    address user,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 mainIndex,
    uint256 tokenAmountOrID
  ) internal {
    Deposit storage deposit = users[user].deposits[mainIndex];
    require(
      uint256(deposit.mainIndex) == mainIndex &&
        uint256(deposit.tokenType) == tokenType &&
        uint256(deposit.lockedFrom) == lockedFrom &&
        uint256(deposit.lockedUntil) == lockedUntil &&
        uint256(deposit.tokenAmountOrID) == tokenAmountOrID,
      "MainPool: inconsistent deposit"
    );
    require(deposit.unlockedAt == 0, "MainPool: deposit already unlocked");
    require(tokenType > S_SYNR_SWAP, "MainPool: sSYNR can not be unstaked");
    if (tokenType == SYNR_PASS_STAKE_FOR_SEEDS) {
      require(lockedUntil < block.timestamp, "MainPool: SYNR Pass cannot be early unstaked");
    }
    if (tokenType == SYNR_STAKE) {
      users[user].synrAmount = uint96(uint256(users[user].synrAmount).sub(tokenAmountOrID));
    } else {
      users[user].passAmount = uint16(uint256(users[user].passAmount).sub(1));
    }
    _updateTvl(tokenType, tokenAmountOrID, false);
    if (tokenType == SYNR_PASS_STAKE_FOR_BOOST || tokenType == SYNR_PASS_STAKE_FOR_SEEDS) {
      pass.safeTransferFrom(address(this), user, uint256(tokenAmountOrID));
    } else {
      uint256 penalty = calculatePenaltyForEarlyUnstake(block.timestamp, deposit);
      uint256 amount = uint256(tokenAmountOrID).sub(penalty);
      synr.safeTransferFrom(address(this), user, amount, "");
      if (penalty > 0) {
        penalties += penalty;
      }
    }
    deposit.unlockedAt = uint32(block.timestamp);
    emit DepositUnlocked(user, uint16(mainIndex));
  }

  /**
   * @notice gets Percentage Vested at a certain timestamp
   * @param when timestamp where percentage will be calculated
   * @param lockedFrom timestamp when locked
   * @param lockedUntil timestamp when can unstake without penalty
   * @return the percentage vested
   */
  function getVestedPercentage(
    uint256 when,
    uint256 lockedFrom,
    uint256 lockedUntil
  ) public pure override returns (uint256) {
    if (lockedUntil == 0) {
      return 10000;
    }
    uint256 lockupTime = lockedUntil.sub(lockedFrom);
    if (lockupTime == 0) {
      return 10000;
    }
    uint256 vestedTime = when.sub(lockedFrom);
    return vestedTime.mul(10000).div(lockupTime);
  }

  /**
   * @notice calculates penalty when unstaking SYNR before period is up
   * @param when timestamp where percentage will be calculated
   * @param deposit deposit from where penalty is to be calculated
   * @return the penalty, if any
   */
  function calculatePenaltyForEarlyUnstake(uint256 when, Deposit memory deposit) public view override returns (uint256) {
    if (when > uint256(deposit.lockedUntil)) {
      return 0;
    }
    uint256 vestedPercentage = getVestedPercentage(when, uint256(deposit.lockedFrom), uint256(deposit.lockedUntil));
    uint256 vestedAmount = uint256(deposit.tokenAmountOrID).mul(vestedPercentage).div(10000);
    return uint256(deposit.tokenAmountOrID).sub(vestedAmount).mul(conf.earlyUnstakePenalty).div(10000);
  }

  /**
   * @notice Withdraws SSYNR that has been Swapped to the contract
   * @param amount amount of ssynr to be withdrawn
   * @param beneficiary address to which the withdrawl will go to
   */
  function withdrawSSynr(uint256 amount, address beneficiary) external override onlyOwner {
    uint256 availableAmount = sSynr.balanceOf(address(this));
    require(availableAmount > 0 && amount <= availableAmount, "MainPool: sSYNR amount not available");
    if (amount == 0) {
      amount = availableAmount;
    }
    // the approve is necessary, because of a bug in the sSYNR contract
    sSynr.approve(address(this), amount);
    // beneficiary must be whitelisted to receive sSYNR
    sSynr.transferFrom(address(this), beneficiary, amount);
  }

  /**
   * @notice Withdraws SYNR that has been collected as tax for unstaking early
   * @param amount amount of ssynr to be withdrawn
   * @param beneficiary address to which the withdrawl will go to
   */
  function withdrawPenalties(uint256 amount, address beneficiary) external override onlyOwner {
    require(penalties > 0 && amount <= penalties, "MainPool: amount not available");
    require(beneficiary != address(0), "MainPool: beneficiary cannot be zero address");
    if (amount == 0) {
      amount = penalties;
    }
    penalties -= amount;
    synr.safeTransferFrom(address(this), beneficiary, amount, "");
  }

  /**
   * @notice stakes the payload if the pool is active
   * @param user address of user
   * @param payload an uint256 encoded with the information of the deposit
   * @param recipientChain chain to where the transfer will go
   */
  function _stake(
    address user,
    uint256 payload,
    uint16 recipientChain
  ) internal returns (uint256) {
    require(conf.status == 1, "MainPool: not initiated or paused");
    (uint256 tokenType, uint256 lockupTime, uint256 tokenAmountOrID) = deserializeInput(payload);
    require(conf.minimumLockupTime > 0, "MainPool: pool not alive");
    payload = _makeDeposit(user, tokenType, lockupTime, tokenAmountOrID, recipientChain);
    emit DepositSaved(user, uint16(getIndexFromPayload(payload)));
    return payload;
  }

  function stake(
    address user,
    uint256 payload,
    uint16 recipientChain
  ) external virtual onlyBridge returns (uint256) {
    require(getDepositsLength(user) < 50, "MainPool: maximum number of deposits reached");
    return _stake(user, payload, recipientChain);
  }

  function unstake(
    address user,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 mainIndex,
    uint256 tokenAmountOrID
  ) external virtual onlyBridge {
    _unstake(user, tokenType, lockedFrom, lockedUntil, mainIndex, tokenAmountOrID);
  }

  function validateInput(
    uint256 tokenType,
    uint256 lockupTime,
    uint256 tokenAmountOrID
  ) public pure override returns (bool) {
    require(tokenType < BLUEPRINT_STAKE_FOR_SEEDS + 1, "PayloadUtils: invalid token type");
    if (tokenType == SYNR_PASS_STAKE_FOR_BOOST || tokenType == SYNR_PASS_STAKE_FOR_SEEDS) {
      require(tokenAmountOrID < 889, "PayloadUtils: Not a Mobland SYNR Pass token ID");
    } else if (tokenType == BLUEPRINT_STAKE_FOR_BOOST || tokenType == BLUEPRINT_STAKE_FOR_SEEDS) {
      require(tokenAmountOrID < 8001, "PayloadUtils: Not a Blueprint token ID");
    } else {
      require(tokenAmountOrID < 1e28, "PayloadUtils: tokenAmountOrID out of range");
    }
    require(lockupTime < 1e3, "PayloadUtils: lockedTime out of range");
    return true;
  }

  function deserializeInput(uint256 payload)
    public
    pure
    override
    returns (
      uint256 tokenType,
      uint256 lockupTime,
      uint256 tokenAmountOrID
    )
  {
    tokenType = payload.mod(100);
    lockupTime = payload.div(100).mod(1e3);
    tokenAmountOrID = payload.div(1e5);
  }

  function getIndexFromPayload(uint256 payload) public pure override returns (uint256) {
    return payload.div(1e22).mod(1e5);
  }
}