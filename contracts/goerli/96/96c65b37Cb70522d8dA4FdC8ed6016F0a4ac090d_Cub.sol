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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

import "openzeppelin-contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IFixer.sol";
import "./interfaces/IHatcher.sol";
import "./interfaces/ICub.sol";

/// @title Cub
/// @author mortimr @ Kiln
/// @dev Unstructured Storage Friendly
/// @notice The cub is controlled by a Hatcher in charge of providing its status details and implementation address.
contract Cub is Proxy, ERC1967Upgrade, ICub {
    /// @notice Initializer to not rely on the constructor
    /// @param beacon The address of the beacon to pull its info from
    /// @param data The calldata to add to the initial call, if any
    // slither-disable-next-line naming-convention
    function ___initializeCub(address beacon, bytes memory data) external {
        if (_getBeacon() != address(0)) {
            revert CubAlreadyInitialized();
        }
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /// @notice Internal utility to retrieve the implementation from the beacon
    /// @return The implementation address
    // slither-disable-next-line dead-code
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /// @notice Prevents unauthorized calls
    /// @dev This will make the method transparent, forcing unauthorized callers into the fallback
    modifier onlyBeacon() {
        if (msg.sender != _getBeacon()) {
            _fallback();
        } else {
            _;
        }
    }

    /// @notice Prevents unauthorized calls
    /// @dev This will make the method transparent, forcing unauthorized callers into the fallback
    modifier onlyMe() {
        if (msg.sender != address(this)) {
            _fallback();
        } else {
            _;
        }
    }

    /// @inheritdoc ICub
    // slither-disable-next-line reentrancy-events
    function appliedFixes(address[] memory fixers) public onlyMe {
        emit AppliedFixes(fixers);
    }

    /// @inheritdoc ICub
    function applyFix(address fixer) external onlyBeacon {
        _applyFix(fixer);
    }

    /// @notice Retrieve the list of fixes for this cub from the hatcher
    /// @param beacon Address of the hatcher acting as a beacon
    /// @return List of fixes to apply
    function _fixes(address beacon) internal view returns (address[] memory) {
        return IHatcher(beacon).fixes(address(this));
    }

    /// @notice Retrieve the status for this cub from the hatcher
    /// @param beacon Address of the hatcher acting as a beacon
    /// @return First value is true if fixes are pending, second value is true if cub is paused
    function _status(address beacon) internal view returns (address, bool, bool) {
        return IHatcher(beacon).status(address(this));
    }

    /// @notice Commits fixes to the hatcher
    /// @param beacon Address of the hatcher acting as a beacon
    function _commit(address beacon) internal {
        IHatcher(beacon).commitFixes();
    }

    /// @notice Fetches the current cub status and acts accordingly
    /// @param beacon Address of the hatcher acting as a beacon
    function _fix(address beacon) internal returns (address) {
        (address implementation, bool hasFixes, bool isPaused) = _status(beacon);
        if (isPaused && msg.sender != beacon && msg.sender != address(0)) {
            revert CalledWhenPaused(msg.sender);
        }
        if (hasFixes) {
            bool isStaticCall = false;
            address[] memory fixes = _fixes(beacon);
            // This is a trick to check if the current execution context
            // allows state modifications
            try this.appliedFixes(fixes) {}
            catch {
                isStaticCall = true;
            }
            // if we properly emitted AppliedFixes, we are not in a view or pure call
            // we can then apply fixes
            if (!isStaticCall) {
                for (uint256 idx = 0; idx < fixes.length;) {
                    if (fixes[idx] != address(0)) {
                        _applyFix(fixes[idx]);
                    }

                    unchecked {
                        ++idx;
                    }
                }
                _commit(beacon);
            }
        }
        return implementation;
    }

    /// @notice Applies the given fix, and reverts in case of error
    /// @param fixer Address that implements the fix
    // slither-disable-next-line controlled-delegatecall,delegatecall-loop,low-level-calls
    function _applyFix(address fixer) internal {
        (bool success, bytes memory rdata) = fixer.delegatecall(abi.encodeWithSelector(IFixer.fix.selector));
        if (!success) {
            revert FixDelegateCallError(fixer, rdata);
        }
        (success) = abi.decode(rdata, (bool));
        if (!success) {
            revert FixCallError(fixer);
        }
    }

    /// @notice Fallback method that ends up forwarding calls as delegatecalls to the implementation
    function _fallback() internal override (Proxy) {
        _beforeFallback();
        address beacon = _getBeacon();
        address implementation = _fix(beacon);
        _delegate(implementation);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

/// @title Cub
/// @author mortimr @ Kiln
/// @dev Unstructured Storage Friendly
/// @notice The cub is controlled by a Hatcher in charge of providing its status details and implementation address.
interface ICub {
    /// @notice An error occured when performing the delegatecall to the fix
    /// @param fixer Address implementing the fix
    /// @param err The return data from the call error
    error FixDelegateCallError(address fixer, bytes err);

    /// @notice The fix method failed by returning false
    /// @param fixer Added implementing the fix
    error FixCallError(address fixer);

    /// @notice A call was made while the cub was paused
    /// @param caller The address that performed the call
    error CalledWhenPaused(address caller);

    error CubAlreadyInitialized();

    /// @notice Emitted when several fixes have been applied
    /// @param fixes List of fixes to apply
    event AppliedFixes(address[] fixes);

    /// @notice Public method that emits the AppliedFixes event
    /// @dev Transparent to all callers except the cub itself
    /// @dev Only callable by the cub itself as a regular call
    /// @dev This method is used to detect the execution context (view/non-view)
    /// @param _fixers List of applied fixes
    function appliedFixes(address[] memory _fixers) external;

    /// @notice Applies the provided fix
    /// @dev Transparent to all callers except the hatcher
    /// @param _fixer The address of the contract implementing the fix to apply
    function applyFix(address _fixer) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

/// @title Fixer
/// @author mortimr @ Kiln
/// @dev Unstructured Storage Friendly
/// @notice The Hatcher can deploy, upgrade, fix and pause a set of instances called cubs.
/// @notice All cubs point to the same coomon implementation.
interface IFixer {
    /// @notice Interface to implement on a Fixer contract
    /// @return isFixed True if fix was properly applied
    function fix() external returns (bool isFixed);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

import "openzeppelin-contracts/proxy/beacon/IBeacon.sol";

/// @title Hatcher Interface
/// @author mortimr @ Kiln
/// @dev Unstructured Storage Friendly
/// @notice The Hatcher can deploy, upgrade, fix and pause a set of instances called cubs.
/// @notice All cubs point to the same coomon implementation.
interface IHatcher is IBeacon {
    /// @notice Emitted when the system is globally paused
    event GlobalPause();

    /// @notice Emitted when the system is globally unpaused
    event GlobalUnpause();

    /// @notice Emitted when a specific cub is paused
    /// @param cub Address of the cub being paused
    event Pause(address cub);

    /// @notice Emitted when a specific cub is unpaused
    /// @param cub Address of the cub being unpaused
    event Unpause(address cub);

    /// @notice Emitted when a global fix is removed
    /// @param index Index of the global fix being removed
    event DeletedGlobalFix(uint256 index);

    /// @notice Emitted when a cub has properly applied a fix
    /// @param cub Address of the cub that applied the fix
    /// @param fix Address of the fix was applied
    event AppliedFix(address cub, address fix);

    /// @notice Emitted the common implementation is updated
    /// @param implementation New common implementation address
    event Upgraded(address indexed implementation);

    /// @notice Emitted a new cub is hatched
    /// @param cub Address of the new instance
    /// @param cdata Calldata used to perform the atomic first call
    event Hatched(address indexed cub, bytes cdata);

    /// @notice Emitted a the initial progress has been changed
    /// @param initialProgress New initial progress value
    event SetInitialProgress(uint256 initialProgress);

    /// @notice Emitted a cub committed some global fixes
    /// @param cub Address of the cub that applied the global fixes
    /// @param progress New cub progress
    event CommittedFixes(address cub, uint256 progress);

    /// @notice Emitted a global fix is registered
    /// @param fix Address of the new global fix
    /// @param index Index of the new global fix in the global fix array
    event RegisteredGlobalFix(address fix, uint256 index);

    /// @notice The provided implementation is not a smart contract
    /// @param implementation The provided implementation
    error ImplementationNotAContract(address implementation);

    /// @notice Retrieve the common implementation
    /// @return implementationAddress Address of the common implementation
    function implementation() external view returns (address implementationAddress);

    /// @notice Retrieve cub status details
    /// @param cub The address of the cub to fetch the status of
    /// @return implementationAddress The current implementation address to use
    /// @return hasFixes True if there are fixes to apply
    /// @return isPaused True if the system is paused globally or the calling cub is paused
    function status(address cub) external view returns (address implementationAddress, bool hasFixes, bool isPaused);

    /// @notice Retrieve the initial progress
    /// @dev This value is the starting progress value for all new cubs
    /// @return currentInitialProgress The initial progress
    function initialProgress() external view returns (uint256 currentInitialProgress);

    /// @notice Retrieve the current progress of a specific cub
    /// @param cub Address of the cub
    /// @return currentProgress The current progress of the cub
    function progress(address cub) external view returns (uint256 currentProgress);

    /// @notice Retrieve the global pause status
    /// @return isGlobalPaused True if globally paused
    function globalPaused() external view returns (bool isGlobalPaused);

    /// @notice Retrieve a cub pause status
    /// @param cub Address of the cub
    /// @return isPaused True if paused
    function paused(address cub) external view returns (bool isPaused);

    /// @notice Retrieve a cub's global fixes that need to be applied, taking its progress into account
    /// @param cub Address of the cub
    /// @return fixesAddresses An array of addresses that implement fixes
    function fixes(address cub) external view returns (address[] memory fixesAddresses);

    /// @notice Retrieve the raw list of global fixes
    /// @return globalFixesAddresses An array of addresses that implement the global fixes
    function globalFixes() external view returns (address[] memory globalFixesAddresses);

    /// @notice Retrieve the address of the next hatched cub
    /// @return nextHatchedCub The address of the next cub
    function nextHatch() external view returns (address nextHatchedCub);

    /// @notice Creates a new cub
    /// @param cdata The calldata to use for the initial atomic call
    /// @return cubAddress The address of the new cub
    function hatch(bytes calldata cdata) external returns (address cubAddress);

    /// @notice Creates a new cub, without calldata
    /// @return cubAddress The address of the new cub
    function hatch() external returns (address cubAddress);

    /// @notice Sets the progress of the caller to the current global fixes array length
    function commitFixes() external;

    /// @notice Apply a fix to several cubs
    /// @param fixer Fixer contract implementing the fix
    /// @param cubs List of cubs to apply the fix on
    function applyFixToCubs(address fixer, address[] calldata cubs) external;

    /// @notice Apply several fixes to one cub
    /// @param cub The cub to apply the fixes on
    /// @param fixers List of fixer contracts implementing the fixes
    function applyFixesToCub(address cub, address[] calldata fixers) external;

    /// @notice Register a new global fix for cubs to call asynchronously
    /// @param fixer Address of the fixer implementing the fix
    function registerGlobalFix(address fixer) external;

    /// @notice Deletes a global fix from the array
    /// @param index Index of the global fix to remove
    function deleteGlobalFix(uint256 index) external;

    /// @notice Upgrades the common implementation address
    /// @param newImplementation Address of the new common implementation
    function upgradeTo(address newImplementation) external;

    /// @notice Upgrades the common implementation address and the initial progress value
    /// @param newImplementation Address of the new common implementation
    /// @param initialProgress_ The new initial progress value
    function upgradeToAndChangeInitialProgress(address newImplementation, uint256 initialProgress_) external;

    /// @notice Sets the initial progress value
    /// @param initialProgress_ The new initial progress value
    function setInitialProgress(uint256 initialProgress_) external;

    /// @notice Pauses a set of cubs
    /// @param cubs List of cubs to pause
    function pauseCubs(address[] calldata cubs) external;

    /// @notice Unpauses a set of cubs
    /// @param cubs List of cubs to unpause
    function unpauseCubs(address[] calldata cubs) external;

    /// @notice Pauses all the cubs of the system
    function globalPause() external;

    /// @notice Unpauses all the cubs of the system
    /// @dev If a cub was specifically paused, this method won't unpause it
    function globalUnpause() external;
}