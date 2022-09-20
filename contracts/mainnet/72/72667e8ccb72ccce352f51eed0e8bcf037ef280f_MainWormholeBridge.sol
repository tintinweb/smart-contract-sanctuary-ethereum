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


// File @openzeppelin/contracts-upgradeable/security/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// License: MIT
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @ndujalabs/wormhole-tunnel/contracts/interfaces/[email protected]

// License: Apache2
pragma solidity ^0.8.0;

interface IWormholeStructs {
  struct Provider {
    uint16 chainId;
    uint16 governanceChainId;
    bytes32 governanceContract;
  }

  struct GuardianSet {
    address[] keys;
    uint32 expirationTime;
  }

  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 guardianIndex;
  }

  struct VM {
    uint8 version;
    uint32 timestamp;
    uint32 nonce;
    uint16 emitterChainId;
    bytes32 emitterAddress;
    uint64 sequence;
    uint8 consistencyLevel;
    bytes payload;
    uint32 guardianSetIndex;
    Signature[] signatures;
    bytes32 hash;
  }
}


// File @ndujalabs/wormhole-tunnel/contracts/interfaces/[email protected]

// License: Apache2
pragma solidity ^0.8.0;

interface IWormhole is IWormholeStructs {
  event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

  function publishMessage(
    uint32 nonce,
    bytes memory payload,
    uint8 consistencyLevel
  ) external payable returns (uint64 sequence);

  function parseAndVerifyVM(bytes calldata encodedVM)
    external
    view
    returns (
      IWormholeStructs.VM memory vm,
      bool valid,
      string memory reason
    );

  function verifyVM(IWormholeStructs.VM memory vm) external view returns (bool valid, string memory reason);

  function verifySignatures(
    bytes32 hash,
    IWormholeStructs.Signature[] memory signatures,
    IWormholeStructs.GuardianSet memory guardianSet
  ) external pure returns (bool valid, string memory reason);

  function parseVM(bytes memory encodedVM) external pure returns (IWormholeStructs.VM memory vm);

  function getGuardianSet(uint32 index) external view returns (IWormholeStructs.GuardianSet memory);

  function getCurrentGuardianSetIndex() external view returns (uint32);

  function getGuardianSetExpiry() external view returns (uint32);

  function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

  function isInitialized(address impl) external view returns (bool);

  function chainId() external view returns (uint16);

  function governanceChainId() external view returns (uint16);

  function governanceContract() external view returns (bytes32);

  function messageFee() external view returns (uint256);
}


// File @ndujalabs/wormhole-tunnel/contracts/libraries/[email protected]

// License: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
  function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
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

  function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
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
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
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

        sstore(sc, add(and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00), and(mload(mc), mask)))

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
        //        let mlengthmod := mod(mlength, 32)
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
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
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

  function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
    require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
    uint8 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x1), _start))
    }

    return tempUint;
  }

  function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
    require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
    uint16 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x2), _start))
    }

    return tempUint;
  }

  function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
    require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
    uint32 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x4), _start))
    }

    return tempUint;
  }

  function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
    require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
    uint64 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x8), _start))
    }

    return tempUint;
  }

  function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
    require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
    uint96 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0xc), _start))
    }

    return tempUint;
  }

  function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
    require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
    uint128 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x10), _start))
    }

    return tempUint;
  }

  function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
    require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
    require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
    bytes32 tempBytes32;

    assembly {
      tempBytes32 := mload(add(add(_bytes, 0x20), _start))
    }

    return tempBytes32;
  }

  function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
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

  function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
    bool success = true;

    assembly {
      // we know _preBytes_offset is 0
      let fslot := sload(_preBytes.slot)
      // Decode the length of the stored array like in concatStorage().
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
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


// File @ndujalabs/wormhole-tunnel/contracts/[email protected]

// License: Apache2
pragma solidity ^0.8.0;


contract WormholeCommon {
  using BytesLib for bytes;
  struct WTransfer {
    // PayloadID uint8 = 1
    // TokenID of the token, if an NFT; amount if a transfer; encoded uint for something else
    uint256 payload;
    // Address of the recipient. Left-zero-padded if shorter than 32 bytes
    bytes32 to;
    // Chain ID of the recipient
    uint16 toChain;
  }

  struct State {
    // Wormhole bridge contract address and chainId
    address payable wormhole;
    uint16 chainId;
    // Mapping of consumed token transfers
    mapping(bytes32 => bool) completedTransfers;
    // Mapping of contracts on other chains
    mapping(uint16 => bytes32) contractsByChainId;
  }

  State _wormholeState;

  function isTransferCompleted(bytes32 hash) public view returns (bool) {
    return _wormholeState.completedTransfers[hash];
  }

  function contractByChainId(uint16 chainId_) public view returns (bytes32) {
    return _wormholeState.contractsByChainId[chainId_];
  }

  function wormhole() public view returns (IWormhole) {
    return IWormhole(_wormholeState.wormhole);
  }

  function chainId() public view returns (uint16) {
    return _wormholeState.chainId;
  }

  function _setWormhole(address wh) internal {
    _wormholeState.wormhole = payable(wh);
  }

  function _setChainId(uint16 chainId_) internal {
    _wormholeState.chainId = chainId_;
  }

  function _setTransferCompleted(bytes32 hash) internal {
    _wormholeState.completedTransfers[hash] = true;
  }

  function _setContract(uint16 chainId_, bytes32 contractExtendedAddress) internal {
    _wormholeState.contractsByChainId[chainId_] = contractExtendedAddress;
  }

  function _wormholeCompleteTransfer(bytes memory encodedVm) internal returns (address to, uint256 payload) {
    (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVm);

    require(valid, reason);

    require(_verifyContractVM(vm), "invalid emitter");

    WTransfer memory wTransfer = _parseTransfer(vm.payload);

    require(!isTransferCompleted(vm.hash), "transfer already completed");
    _setTransferCompleted(vm.hash);

    require(wTransfer.toChain == chainId(), "invalid target chain");

    // transfer bridged NFT to recipient
    address transferRecipient = address(uint160(uint256(wTransfer.to)));

    return (transferRecipient, wTransfer.payload);
  }

  function _wormholeTransferWithValue(
    uint256 payload,
    uint16 recipientChain,
    bytes32 recipient,
    uint32 nonce,
    uint256 value
  ) internal returns (uint64 sequence) {
    require(contractByChainId(recipientChain) != 0, "recipientChain not allowed");
    sequence = _logTransfer(WTransfer({payload: payload, to: recipient, toChain: recipientChain}), value, nonce);
    return sequence;
  }

  function _logTransfer(
    WTransfer memory wTransfer,
    uint256 callValue,
    uint32 nonce
  ) internal returns (uint64 sequence) {
    bytes memory encoded = _encodeTransfer(wTransfer);
    sequence = wormhole().publishMessage{value: callValue}(nonce, encoded, 15);
  }

  function _verifyContractVM(IWormhole.VM memory vm) internal view returns (bool) {
    if (contractByChainId(vm.emitterChainId) == vm.emitterAddress) {
      return true;
    }
    return false;
  }

  function _encodeTransfer(WTransfer memory wTransfer) internal pure returns (bytes memory encoded) {
    encoded = abi.encodePacked(uint8(1), wTransfer.payload, wTransfer.to, wTransfer.toChain);
  }

  function _parseTransfer(bytes memory encoded) internal pure returns (WTransfer memory wTransfer) {
    uint256 index = 0;

    uint8 payloadId = encoded.toUint8(index);
    index += 1;

    require(payloadId == 1, "invalid WTransfer");

    wTransfer.payload = encoded.toUint256(index);
    index += 32;

    wTransfer.to = encoded.toBytes32(index);
    index += 32;

    wTransfer.toChain = encoded.toUint16(index);
    index += 2;

    require(encoded.length == index, "invalid WTransfer");
    return wTransfer;
  }
}


// File @ndujalabs/wormhole-tunnel/contracts/interfaces/[email protected]

// License: Apache2
pragma solidity ^0.8.0;

/// ERC165 interfaceId is 0x647bffff
/* is IERC165 */
interface IWormholeTunnel {
  function wormholeInit(uint16 chainId, address wormhole) external;

  function wormholeRegisterContract(uint16 chainId, bytes32 contractByChainId) external;

  function wormholeGetContract(uint16 chainId) external view returns (bytes32);

  function wormholeTransfer(
    uint256 payload,
    uint16 recipientChain,
    bytes32 recipient,
    uint32 nonce
  ) external payable returns (uint64 sequence);

  function wormholeCompleteTransfer(bytes memory encodedVm) external;
}


// File @ndujalabs/wormhole-tunnel/contracts/[email protected]

// License: Apache2
pragma solidity ^0.8.0;







abstract contract WormholeTunnelUpgradeable is
  IWormholeTunnel,
  WormholeCommon,
  PausableUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  ERC165Upgradeable
{
  using BytesLib for bytes;

  // solhint-disable-next-line func-name-mixedcase
  function __WormholeTunnel_init() internal virtual initializer {
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IWormholeTunnel).interfaceId || super.supportsInterface(interfaceId);
  }

  function wormholeInit(uint16 chainId, address wormhole) public override onlyOwner {
    _setChainId(chainId);
    _setWormhole(wormhole);
  }

  function wormholeRegisterContract(uint16 chainId_, bytes32 contractExtendedAddress) public override onlyOwner {
    _setContract(chainId_, contractExtendedAddress);
  }

  function wormholeGetContract(uint16 chainId) public view override returns (bytes32) {
    return contractByChainId(chainId);
  }

  /** @dev Examples of implementation for an ERC721:

  function wormholeTransfer(
    uint256 payload,
    uint16 recipientChain,
    bytes32 recipient,
    uint32 nonce
  ) public payable virtual override whenNotPaused returns (uint64 sequence) {
    require(owner(payload) == _msgSender(), "ERC721: transfer caller is not the owner");
    _burn(payload);
    return _wormholeTransferWithValue(payload, recipientChain, recipient, nonce, msg.value);
  }

  // Complete a transfer from Wormhole
  function wormholeCompleteTransfer(bytes memory encodedVm) public virtual override {
    (address to, uint256 payload) = _wormholeCompleteTransfer(encodedVm);
    _safeMint(to, payload);
  }

  */

  uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


// File @openzeppelin/contracts-upgradeable/utils/cryptography/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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


// File contracts/interfaces/IWormholeBridge.sol

// License: MIT
pragma solidity 0.8.11;

// Authors: Francesco Sullo <[email protected]>
// to be used by Tesseract.sol

interface IWormholeBridge {
  function wormholeTransfer(
    uint256 payload,
    uint16 recipientChain,
    bytes32 recipient,
    uint32 nonce
  ) external payable returns (uint64 sequence);

  function wormholeCompleteTransfer(bytes memory encodedVm) external;
}


// File contracts/interfaces/ITesseract.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// (c) 2022+ SuperPower Labs Inc.

interface ITesseract {
  event BridgeSet(uint16 bridgeType, address bridge);
  event ImplementationUpgraded(address newImplementation);

  function setBridge(uint16 bridgeType, address bridge_) external;

  function supportedBridgeById(uint256 id) external view returns (string memory);

  function crossChainTransfer(
    uint8 bridgeType,
    uint256 payload,
    uint16 recipientChain,
    uint32 nonce
  ) external payable returns (uint64 sequence);

  function completeCrossChainTransfer(uint16 bridgeType, bytes memory encodedVm) external;
}


// File contracts/Tesseract.sol

// License: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <[email protected]>
// (c) 2022+ SuperPower Labs Inc.






//import "hardhat/console.sol";

contract Tesseract is ITesseract, Versionable, Initializable, OwnableUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  mapping(uint16 => address) public bridges;

  // bridges[1] is WormholeBridge

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  // solhint-disable-next-line
  function initialize() public initializer {
    __Ownable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function setBridge(uint16 bridgeType, address bridge_) external override onlyOwner {
    require(bridge_.isContract(), "Tesseract: bridge_ not a contract");
    bridges[bridgeType] = bridge_;
    emit BridgeSet(bridgeType, bridge_);
  }

  function supportedBridgeById(uint256 id) external view virtual override returns (string memory) {
    if (id == 1) {
      return "Wormhole";
    } else {
      revert("Tesseract: unsupported bridge");
    }
  }

  function crossChainTransfer(
    uint8 bridgeType,
    uint256 payload,
    uint16 recipientChain,
    uint32 nonce
  ) external payable virtual override returns (uint64 sequence) {
    if (bridgeType == 1) {
      return
        IWormholeBridge(bridges[1]).wormholeTransfer(payload, recipientChain, bytes32(uint256(uint160(_msgSender()))), nonce);
    } else {
      revert("Tesseract: unsupported bridge");
    }
  }

  function completeCrossChainTransfer(uint16 bridgeType, bytes memory encodedVm) external override {
    if (bridgeType == 1) {
      IWormholeBridge(bridges[1]).wormholeCompleteTransfer(encodedVm);
    } else {
      revert("Tesseract: unsupported bridge");
    }
  }

  function withdrawProceeds(address payable to) public onlyOwner {
    to.transfer(address(this).balance);
  }
}


// File contracts/bridge/WormholeBridge.sol

// License: MIT
pragma solidity 0.8.11;

// Authors: Francesco Sullo <[email protected]>




contract WormholeBridge is WormholeTunnelUpgradeable {
  using AddressUpgradeable for address;
  using ECDSAUpgradeable for bytes32;
  using SafeMathUpgradeable for uint256;

  event ImplementationUpgraded(address newImplementation);

  Tesseract public tesseract;
  address public pool;
  address public validator;

  modifier onlyTesseract() {
    require(address(tesseract) == _msgSender(), "MainWormholeBridge: Forbidden");
    _;
  }

  // solhint-disable-next-line
  function __WormholeBridge_init(address tesseract_, address pool_) public virtual initializer {
    __WormholeTunnel_init();
    require(tesseract_.isContract(), "WormholeBridge: tesseract_ not a contract");
    require(pool_.isContract(), "WormholeBridge: pool_ not a contract");
    tesseract = Tesseract(tesseract_);
    pool = pool_;
  }

  function setValidator(address validator_) external onlyOwner {
    require(validator_ != address(0), "MainPool: address zero not allowed");
    validator = validator_;
  }

  function updatePool(address pool_) external onlyOwner {
    require(pool_.isContract(), "WormholeBridge: pool_ not a contract");
    pool = pool_;
  }

  // must be overwritten
  function wormholeTransfer(
    uint256,
    uint16,
    bytes32,
    uint32
  ) public payable virtual override returns (uint64) {
    return uint64(0);
  }

  // must be overwritten
  function wormholeCompleteTransfer(bytes memory encodedVm) public virtual override {}

  // must be overwritten
  function completeTransferIfBridgeFails(
    address to,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 mainIndex,
    uint256 tokenAmountOrID,
    bytes memory signature
  ) external virtual {
    require(
      isSignedByValidator(encodeForSignature(to, tokenType, lockedFrom, lockedUntil, mainIndex, tokenAmountOrID), signature),
      "WormholeBridge: invalid signature"
    );
  }

  // this is called internally
  // and externally by the web3 app to test the validation
  function isSignedByValidator(bytes32 _hash, bytes memory _signature) public view returns (bool) {
    return validator != address(0) && validator == _hash.recover(_signature);
  }

  // this is called internally
  // and externally by the web3 app
  function encodeForSignature(
    address to,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 mainIndex,
    uint256 tokenAmountOrID
  ) public view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          block.chainid,
          to,
          tokenType,
          lockedFrom,
          lockedUntil,
          mainIndex,
          tokenAmountOrID
        )
      );
  }

  function withdrawProceeds(address payable to) public onlyOwner {
    to.transfer(address(this).balance);
  }

  function deserializeDeposit(uint256 payload)
    public
    pure
    returns (
      uint256 tokenType,
      uint256 lockedFrom,
      uint256 lockedUntil,
      uint256 mainIndex,
      uint256 tokenAmountOrID
    )
  {
    tokenType = payload.mod(100);
    lockedFrom = payload.div(100).mod(1e10);
    lockedUntil = payload.div(1e12).mod(1e10);
    mainIndex = payload.div(1e22).mod(1e5);
    tokenAmountOrID = payload.div(1e27);
  }
}


// File contracts/bridge/MainWormholeBridge.sol

// License: MIT
pragma solidity 0.8.11;

// Authors: Francesco Sullo <[email protected]>


contract MainWormholeBridge is WormholeBridge {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address tesseract_, address pool_) public virtual initializer {
    __WormholeBridge_init(tesseract_, pool_);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
    emit ImplementationUpgraded(newImplementation);
  }

  // STAKE/BURN starts on the main chain and completes on the side chain
  function wormholeTransfer(
    uint256 payload,
    uint16 recipientChain,
    bytes32 recipient,
    uint32 nonce
  ) public payable override whenNotPaused onlyTesseract returns (uint64) {
    address sender = address(uint160(uint256(recipient)));
    payload = MainPool(pool).stake(sender, payload, recipientChain);
    uint64 sequence = _wormholeTransferWithValue(payload, recipientChain, recipient, nonce, msg.value);
    return sequence;
  }

  // STAKE/BURN starts on the side chain and completes on the main chain
  function wormholeCompleteTransfer(bytes memory encodedVm) public virtual override {
    (address to, uint256 payload) = _wormholeCompleteTransfer(encodedVm);
    _onWormholeCompleteTransfer(to, payload);
  }

  function _onWormholeCompleteTransfer(address to, uint256 payload) internal {
    (
      uint256 tokenType,
      uint256 lockedFrom,
      uint256 lockedUntil,
      uint256 mainIndex,
      uint256 tokenAmountOrID
    ) = deserializeDeposit(payload);
    MainPool(pool).unstake(to, tokenType, lockedFrom, lockedUntil, mainIndex, tokenAmountOrID);
  }

  /*
During the debugging on the testnet, we experienced some cases where the
bridge protocol could not complete the process. It is a sporadic event,
but if it happens, funds will be locked in the contract on the starting
chain and will be lost. This emergency function can be executed by any
user who got a valid signature from a validator to assure that the data
is correct.
*/
  function completeTransferIfBridgeFails(
    address to,
    uint256 tokenType,
    uint256 lockedFrom,
    uint256 lockedUntil,
    uint256 mainIndex,
    uint256 tokenAmountOrID,
    bytes memory signature
  ) external override {
    require(
      isSignedByValidator(encodeForSignature(to, tokenType, lockedFrom, lockedUntil, mainIndex, tokenAmountOrID), signature),
      "MainWormholeBridge: invalid signature"
    );
    MainPool(pool).unstake(to, tokenType, lockedFrom, lockedUntil, mainIndex, tokenAmountOrID);
  }
}