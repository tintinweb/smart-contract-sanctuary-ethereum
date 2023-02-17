// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
library StorageSlot {
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./libraries/BeaconClones.sol";
import "./access/Ownable.sol";
import "./interfaces/IEnsoWallet.sol";

contract EnsoWalletFactory is Ownable, UUPSUpgradeable {
    using StorageAPI for bytes32;
    using BeaconClones for address;

    address public immutable ensoBeacon;

    event Deployed(IEnsoWallet instance, string label, address deployer);

    error AlreadyInit();
    error NoLabel();

    constructor(address ensoBeacon_) {
        ensoBeacon = ensoBeacon_;
        // Set owner to 0xff so that the implementation cannot be initialized
        OWNER.setAddress(address(type(uint160).max));
    }

    // @notice A function to initialize state on the proxy the delegates to this contract
    // @param newOwner The new owner of this contract
    function initialize(address newOwner) external {
        if (newOwner == address(0)) revert InvalidAccount();
        if (OWNER.getAddress() != address(0)) revert AlreadyInit();
        OWNER.setAddress(newOwner);
    }

    // @notice Deploy a wallet using the msg.sender as the salt
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut after deployment
    // @param state The optional state for executing a shortcut after deployment
    function deploy(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) public payable returns (IEnsoWallet) {
        bytes32 salt = bytes32(uint256(uint160(msg.sender)));
        return _deploy(salt, "", shortcutId, commands, state);
    }

    // @notice Deploy a wallet using a hash of the msg.sender and a label as the salt
    // @param label The label to identify deployment
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut after deployment
    // @param state The optional state for executing a shortcut after deployment
    function deployCustom(
        string memory label,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) public payable returns (IEnsoWallet) {
        if (bytes(label).length == 0) revert NoLabel();
        bytes32 salt = _customSalt(msg.sender, label);
        return _deploy(salt, label, shortcutId, commands, state);
    }

    // @notice Get the deployment address for the msg.sender
    function getAddress() public view returns (address payable) {
        return getUserAddress(msg.sender);
    }

    // @notice Get the deployment address for the user
    // @param user The address of the user that is used to determine the deployment address
    function getUserAddress(address user) public view returns (address payable) {
        bytes32 salt = bytes32(uint256(uint160(user)));
        return _predictDeterministicAddress(salt);
    }

    // @notice Get the deployment address for a user and label
    // @param user The address of the user that is used to determine the deployment address
    // @param label The label that is used to determine the deployment address
    function getCustomAddress(address user, string memory label) external view returns (address payable) {
        if (bytes(label).length == 0) revert NoLabel();
        bytes32 salt = _customSalt(user, label);
        return _predictDeterministicAddress(salt);
    }

    // @notice The internal function for deploying a new wallet
    // @param salt The salt for deploy the address deterministically
    // @param label The label to identify deployment in the emitted event
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut after deployment
    // @param state The optional state for executing a shortcut after deployment
    function _deploy(
        bytes32 salt,
        string memory label,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) internal returns (IEnsoWallet instance) {
        instance = IEnsoWallet(payable(ensoBeacon.cloneDeterministic(salt)));
        instance.initialize{value: msg.value}(msg.sender, salt, shortcutId, commands, state);
        emit Deployed(instance, label, msg.sender);
    }

    // @notice Internal function to generate a custom salt using a user address and label
    // @param user The address of the user
    // @param label The label to identify the deployment
    function _customSalt(address user, string memory label) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, label));
    }

    // @notice Internal function to derive the deployment address from a salt
    // @param salt The bytes32 salt to generate the deployment address
    function _predictDeterministicAddress(bytes32 salt) internal view returns (address payable) {
        return payable(ensoBeacon.predictDeterministicAddress(salt, address(this)));
    }

    // @notice Internal function to support UUPS upgrades of the implementing proxy
    // @notice newImplementation Address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        if (msg.sender != OWNER.getAddress()) revert NotOwner();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "../libraries/StorageAPI.sol";

// @notice The OWNER slot must be set in the importing contract's constructor or initialize function
abstract contract Ownable {
    using StorageAPI for bytes32;

    // Using same slot generation technique as eip-1967 -- https://eips.ethereum.org/EIPS/eip-1967
    bytes32 internal constant OWNER = bytes32(uint256(keccak256("enso.access.owner")) - 1);
    bytes32 internal constant PENDING_OWNER = bytes32(uint256(keccak256("enso.access.pendingOwner")) - 1);

    event OwnershipTransferred(address previousOwner, address newOwner);
    event OwnershipTransferStarted(address previousOwner, address newOwner);

    error NotOwner();
    error NotPermitted();
    error InvalidAccount();

    modifier onlyOwner() {
        if (msg.sender != OWNER.getAddress()) revert NotOwner();
        _;
    }

    // @notice Transfer ownership of this contract, ownership is only transferred after new owner accepts
    // @param newOwner The address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAccount();
        address currentOwner = OWNER.getAddress();
        if (newOwner == currentOwner) revert InvalidAccount();
        PENDING_OWNER.setAddress(newOwner);
        emit OwnershipTransferStarted(currentOwner, newOwner);
    }

    // @notice Accept ownership of this contract
    function acceptOwnership() external {
        if (msg.sender != PENDING_OWNER.getAddress()) revert NotPermitted();
        PENDING_OWNER.setAddress(address(0));
        address previousOwner = OWNER.getAddress();
        OWNER.setAddress(msg.sender);
        emit OwnershipTransferred(previousOwner, msg.sender);
    }

    // @notice The current owner of this contract
    // @return The address of the current owner
    function owner() external view returns (address) {
        return OWNER.getAddress();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "../EnsoWalletFactory.sol";
import "../proxy/UpgradeableProxy.sol";

contract FactoryDeployer {
    address public immutable factory;

    constructor(address owner, address factoryImplementation) {
        factory = address(new UpgradeableProxy(factoryImplementation));
        EnsoWalletFactory(factory).initialize(owner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

interface IEnsoWallet {
    function initialize(
        address owner,
        bytes32 salt,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol

pragma solidity ^0.8.16;

library BeaconClones {
    /**
     * @dev Deploys and returns the address of a clone that gets an implementation
     *      from the `beacon` and mimics its behaviour.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `beacon` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address beacon, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x6080604052348015600f57600080fd5b5060a88061001e6000396000f3fe6080)
            mstore(add(ptr, 0x20), 0x6040526040517f5c60da1b000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x40), 0x0000000000000081526000600160208260048573000000000000000000000000)
            mstore(add(ptr, 0x54), shl(0x60, beacon))
            mstore(add(ptr, 0x68), 0x5afa0360705780513682833781823684845af490503d82833e808015606c573d)
            mstore(add(ptr, 0x88), 0x83f35b3d83fd5b00fea264697066735822122002f8a2f5acabeb1d754972351e)
            mstore(add(ptr, 0xa8), 0xc784958a7f99e64f368c267a38bb375594c03c64736f6c634300081000330000)
            instance := create2(0, ptr, 0xc6, salt)
        }
        require(instance != address(0), "create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address beacon,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x6080604052348015600f57600080fd5b5060a88061001e6000396000f3fe6080)
            mstore(add(ptr, 0x20), 0x6040526040517f5c60da1b000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x40), 0x0000000000000081526000600160208260048573000000000000000000000000)
            mstore(add(ptr, 0x54), shl(0x60, beacon))
            mstore(add(ptr, 0x68), 0x5afa0360705780513682833781823684845af490503d82833e808015606c573d)
            mstore(add(ptr, 0x88), 0x83f35b3d83fd5b00fea264697066735822122002f8a2f5acabeb1d754972351e)
            mstore(add(ptr, 0xa8), 0xc784958a7f99e64f368c267a38bb375594c03c64736f6c63430008100033ff00)
            mstore(add(ptr, 0xc7), shl(0x60, deployer))
            mstore(add(ptr, 0xdb), salt)
            mstore(add(ptr, 0xfb), keccak256(ptr, 0xc6))
            predicted := keccak256(add(ptr, 0xc6), 0x55)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.16;

library StorageAPI {
    function setBytes(bytes32 key, bytes memory data) internal {
        bytes32 slot = keccak256(abi.encodePacked(key));
        assembly {
            let length := mload(data)
            switch gt(length, 0x1F)
            case 0x00 {
                sstore(key, or(mload(add(data, 0x20)), mul(length, 2)))
            }
            case 0x01 {
                sstore(key, add(mul(length, 2), 1))
                for {
                    let i := 0
                } lt(mul(i, 0x20), length) {
                    i := add(i, 0x01)
                } {
                    sstore(add(slot, i), mload(add(data, mul(add(i, 1), 0x20))))
                }
            }
        }
    }

    function setBytes32(bytes32 key, bytes32 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setAddress(bytes32 key, address a) internal {
        assembly {
            sstore(key, a)
        }
    }

    function setUint256(bytes32 key, uint256 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setInt256(bytes32 key, int256 val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function setBool(bytes32 key, bool val) internal {
        assembly {
            sstore(key, val)
        }
    }

    function getBytes(bytes32 key) internal view returns (bytes memory data) {
        bytes32 slot = keccak256(abi.encodePacked(key));
        assembly {
            let length := sload(key)
            switch and(length, 0x01)
            case 0x00 {
                let decodedLength := div(and(length, 0xFF), 2)
                mstore(data, decodedLength)
                mstore(add(data, 0x20), and(length, not(0xFF)))
                mstore(0x40, add(data, 0x40))
            }
            case 0x01 {
                let decodedLength := div(length, 2)
                let i := 0
                mstore(data, decodedLength)
                for {

                } lt(mul(i, 0x20), decodedLength) {
                    i := add(i, 0x01)
                } {
                    mstore(add(add(data, 0x20), mul(i, 0x20)), sload(add(slot, i)))
                }
                mstore(0x40, add(data, add(0x20, mul(i, 0x20))))
            }
        }
    }

    function getBytes32(bytes32 key) internal view returns (bytes32 val) {
        assembly {
            val := sload(key)
        }
    }

    function getAddress(bytes32 key) internal view returns (address a) {
        assembly {
            a := sload(key)
        }
    }

    function getUint256(bytes32 key) internal view returns (uint256 val) {
        assembly {
            val := sload(key)
        }
    }

    function getInt256(bytes32 key) internal view returns (int256 val) {
        assembly {
            val := sload(key)
        }
    }

    function getBool(bytes32 key) internal view returns (bool val) {
        assembly {
            val := sload(key)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

contract UpgradeableProxy {
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address implementation) {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    fallback() external payable {
        assembly {
            let addr := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}