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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "../tokens/PrincipalToken.sol";

import "../interfaces/IPrincipalTokenFactory.sol";

// Module to deploy Vault
contract PrincipalTokenFactory is
    IPrincipalTokenFactory,
    Ownable2StepUpgradeable
{
    /* State
     *****************************************************************************************************************/

    struct PoolSetting {
        //can be used for stack too deep if curve parameter are not fixed and passed in request
        string name;
        string symbol;
        uint256 A;
        uint256 gamma;
        uint256 mid_fee;
        uint256 out_fee;
        uint256 allowed_extra_profit;
        uint256 fee_gamma;
        uint256 adjustment_step;
        uint256 admin_fee;
        uint256 ma_half_time;
        uint256 initial_price;
    }
    struct DeploymentResponse {
        //can be used for stack too deep if curve parameter are not fixed and passed in request
        bool success;
        bytes responseData;
    }

    address private curveFactory;
    address private registry;
    address private immutable principalTokenBeaconUpgradeable;
    address private immutable ytBeaconUpgradeable;
    mapping(address => StructUtil.PoolData[]) private principalTokenPoolMap;

    address public curveAddressProvider;

    /* Events
     *****************************************************************************************************************/

    event PrincipalTokenDeployed(
        address indexed _principalToken,
        address indexed _poolCreator
    );
    event CurveFactoryChanged(address indexed newFactory);
    event CurveAddressProviderSet(address indexed curveAddressProvider);
    event CurvePoolDeployed(
        address indexed poolAddress,
        address ibt,
        address pt
    );
    event RegistryUpdated(
        address indexed oldRegistry,
        address indexed newRegistry
    );
    event PoolAdded(address indexed curvePool, address indexed principalToken);

    /**
     * @notice Constructor of the contract
     * @param _principalTokenBeaconUpgradeable The address of futurevault beacon.
     * @param _ytBeaconUpgradeable The address of yt beacon.
     */
    constructor(
        address _principalTokenBeaconUpgradeable,
        address _ytBeaconUpgradeable
    ) {
        if (
            _principalTokenBeaconUpgradeable == address(0) ||
            _ytBeaconUpgradeable == address(0)
        ) {
            revert ZeroAddressError();
        }
        principalTokenBeaconUpgradeable = _principalTokenBeaconUpgradeable;
        ytBeaconUpgradeable = _ytBeaconUpgradeable;
        _disableInitializers(); // using this so that the deployed logic contract later cannot be initialized.
    }

    /** Initializer*/
    function initialize() external initializer {
        __Ownable2Step_init();
    }

    /**
     * @notice Deploys the PrincipalToken contract implementation.
     * @param name_ Name of the PrincipalToken.
     * @param symbol_ Symbol of the PrincipalToken.
     * @param ibt_ Address of the ibt of the PrincipalToken.
     * @param maturity_ The maturity time of the PrincipalToken.
     * @param max_fees_ Maximum fees of the PrincipalToken.
     * @param registry_ Address of the Registry contract of the PrincipalToken.
     * @return principalToken The address of the principalToken deployed.
     * @return curvePoolAddress The address of the curve Pool deployed for ibt/pt.
     */
    function deployPrincipalToken(
        string memory name_,
        string memory symbol_,
        address ibt_,
        uint256 maturity_,
        uint256 max_fees_,
        address registry_,
        address principalTokenAdmin
    )
        external
        override
        returns (address principalToken, address curvePoolAddress)
    {
        if ((principalTokenBeaconUpgradeable == address(0))) {
            revert BeaconNotSet();
        }

        principalToken = address(
            new BeaconProxy(
                principalTokenBeaconUpgradeable,
                abi.encodeWithSelector(
                    PrincipalToken(address(0)).initialize.selector,
                    name_,
                    symbol_,
                    ibt_,
                    maturity_,
                    max_fees_,
                    registry_,
                    ytBeaconUpgradeable
                )
            )
        );

        emit PrincipalTokenDeployed(principalToken, msg.sender);

        // changing admin from self(principalTokenFactory) to principalTokenAdmin
        Ownable2StepUpgradeable(principalToken).transferOwnership(
            principalTokenAdmin
        );

        // deploying curve pool for the deployed PT and its IBT
        curvePoolAddress = _deployCurvePool(principalToken, ibt_);
    }

    /**
    * @notice Function which sets the curveAddressProvider address used in
      getting the curve factory address. Can only be called by owner.
    * @param curveAddressProvider_ The address of the curveAddressProvider.
     */
    function setCurveAddressProvider(
        address curveAddressProvider_
    ) external override {
        _checkOwner();
        if ((curveAddressProvider_ == address(0))) {
            revert ZeroAddressError();
        }
        emit CurveAddressProviderSet(curveAddressProvider_);
        curveAddressProvider = curveAddressProvider_;
        _setCurveFactory();
    }

    /**
     * @notice Setter for the registry address, Can only be called by the owner.
     * @param _newRegistry the address of the token factory
     */
    function setRegistry(address _newRegistry) public override {
        _checkOwner();
        if ((_newRegistry == address(0))) {
            revert ZeroAddressError();
        }
        emit RegistryUpdated(registry, _newRegistry);
        registry = _newRegistry;
    }

    /* Factory getters
     *****************************************************************************************************************/

    /**
     * @notice Getter for the registry address
     * @return the address of the registry
     */
    function getRegistryAddress() external view override returns (address) {
        return registry;
    }

    /* See IPrincipalTokenFactory-getPool */
    function getPool(
        address _principalToken,
        uint256 poolIndex
    ) external view override returns (StructUtil.PoolData memory pool) {
        pool = principalTokenPoolMap[_principalToken][poolIndex];
    }

    /**
     * @notice Getter for the curve factory address
     * @return the address of the curve factory
     */
    function getCurveFactoryAddress() public view override returns (address) {
        return curveFactory;
    }

    /**
     * @notice Function for deploying the Curve Pool.
     * @param principalToken The address of the principalToken that will be associated with the pool.
     * @param ibt The address of the ibt that will be associated with the pool.
     */
    function _deployCurvePool(
        address principalToken,
        address ibt
    ) internal returns (address curvePoolAddr) {
        address[2] memory coins;
        coins[0] = ibt;
        coins[1] = principalToken;
        uint256 ASSET_UNIT = 10 **
            IERC20MetadataUpgradeable(coins[0]).decimals();
        uint256 intitalPrice = IPrincipalToken(principalToken).convertToShares(
            ASSET_UNIT
        );
        if ((curveFactory == address(0))) {
            revert CurveFactoryNotSet();
        }
        (bool success, bytes memory responseData) = curveFactory.call(
            abi.encodeWithSelector(
                0xc955fa04,
                "FV_POOL_APW",
                "APW/PT/IBT",
                coins, //[ibt,pt]
                200000000, // A
                100000000000000, // gamma
                15000000, //mid_fee
                50000000, //out_fee
                10000000000, //allowed_extra_profit
                5000000000000000, //fee_gamma
                5500000000000, //adjustment_step
                5000000000, //admin_fee
                600, //ma_half_time
                intitalPrice //initial_price
            )
        );

        if (!(success)) {
            revert DeploymentFailed();
        }
        assembly {
            curvePoolAddr := mload(add(add(responseData, 12), 20))
        }
        _addPool(curvePoolAddr, principalToken);
        emit CurvePoolDeployed(curvePoolAddr, coins[0], principalToken);
    }

    /**
    * @notice Function which sets the curve factory address used in
      deploying the curve pool. Can only be called by owner.
     */
    function _setCurveFactory() internal {
        // keccack of getter get_address(uint256) of curveAddressProvider is 493f4f74e22e7386370f0e9d655568828bd1c31ff9768464b2c471cdb8e8587c
        // The function selector is first 4bytes of it, so 0x493f4f74
        uint256 index = 6; // currently curve factory address is stored at index 6 on MAINNET.
        (bool success, bytes memory responseData) = curveAddressProvider.call(
            abi.encodeWithSelector(0x493f4f74, index)
        );
        if (!(success)) {
            revert FailedToFetchCurveFactoryAddress();
        }
        curveFactory = abi.decode(responseData, (address));
        emit CurveFactoryChanged(curveFactory);
    }

    /**
     * @notice Add a pool to principalTokenPoolMap mapping.
     * @param _principalToken the address of the principalToken.
     * @param _pool the address of deployed IBT/PT pool.
     */
    function _addPool(address _pool, address _principalToken) internal {
        StructUtil.PoolData memory poolData;
        poolData.pool = _pool;
        poolData.poolProtocolName = "Curve";
        principalTokenPoolMap[_principalToken].push(poolData);
        emit PoolAdded(_pool, _principalToken);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IPrincipalToken is IERC20Upgradeable, IERC4626Upgradeable {
    /* ERRORS
     *****************************************************************************************************************/
    error PrincipalTokenExpired();
    error PrincipalTokenRateError();
    error PrincipalTokenNotExpired();
    error NetYieldZero();
    error ZeroAddressError();
    error CallerIsNotOwner();
    error CallerIsNotYtContract();
    error CallerIsNotFeeCollector();
    error RatesAtExpiryNotStored();
    error RatesAtExpiryAlreadyStored();
    error FeeMoreThanMaxValue();
    error AssetsValueLessThanMinValue();
    error AssetsValueMoreThanMaxValue();
    error SharesValueLessThanMinValue();
    error SharesValueMoreThanMaxValue();
    error TransferValueExceedsYieldBalance();

    /**
     * @notice Returns the amount of shares that the Vault would exchange for the amount of assets provided
     * @param assets the amount of assets to convert
     * @param _ptRate the rate to convert at
     * @return shares the resulting amount of shares
     */
    function convertToSharesWithRate(
        uint256 assets,
        uint256 _ptRate
    ) external view returns (uint256 shares);

    /**
     * @notice Returns the amount of assets that the Vault would exchange for the amount of shares provided
     * @param shares the amount of shares to convert
     * @param _ptRate the rate to convert at
     * @return assets the resulting amount of assets
     */
    function convertToAssetsWithRate(
        uint256 shares,
        uint256 _ptRate
    ) external view returns (uint256 assets);

    /**
     * @notice Returns the equivalent amount of IBT tokens to an amount of assets
     * @param assets the amount of assets to convert
     * @param _ibtRate the rate to convert at
     * @return the corresponding amount of ibts
     */
    function convertAssetsToIBTWithRate(
        uint256 assets,
        uint256 _ibtRate
    ) external view returns (uint256);

    /**
     * @notice Returns the equivalent amount of Assets to an amount of IBT tokens
     * @param ibtAmount the amount of ibt tokens to convert
     * @param _ibtRate the rate to convert at
     * @return the corresponding amount of assets
     */
    function convertIBTToAssetsWithRate(
        uint256 ibtAmount,
        uint256 _ibtRate
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of underlying assets that the Vault would exchange for the amount of principal tokens provided
     *      Equivalent function to convertToAssets
     * @param principalAmount amount of principal to convert
     */
    function convertToUnderlying(
        uint256 principalAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of Principal tokens that the Vault would exchange for the amount of underlying assets
     *      Equivalent function to convertToShares
     * @param underlyingAmount amount of underlying to convert
     */
    function convertToPrincipal(
        uint256 underlyingAmount
    ) external view returns (uint256);

    /**
     * @dev Return the address of the underlying token used by the Principal
     * Token for accounting, and redeeming
     */
    function underlying() external view returns (address);

    /**
     * @dev Return the unix timestamp (uint256) at or after which Principal
     * Tokens can be redeemed for their underlying deposit
     */
    function maturity() external view returns (uint256);

    /**
     * @dev Allows the owner to redeem his PT and claim his yield after expiry
     * and send it to the receiver
     *
     * @param receiver the address to which the yield and pt redeem will be sent
     * @param owner the owner of the PT
     * @return the amount of underlying withdrawn
     */
    function withdrawAfterExpiry(
        address receiver,
        address owner
    ) external returns (uint256);

    /**
     * @dev Stores PT and IBT rates at expiry. Ideally, this function should be called
     * the day of expiry
     * @return the IBT and PT rates at expiry
     */
    function storeRatesAtExpiry() external returns (uint256, uint256);

    /**
     * @dev Returns the IBT rate at expiry
     */
    function getIBTRateAtExpiry() external view returns (uint256);

    /**
     * @dev Returns the PT rate at expiry
     */
    function getPTRateAtExpiry() external view returns (uint256);

    /**
     * @notice Claims pending tokens for both sender and receiver and sets
       correct ibt balances
     * @param _from the sender of yt tokens
     * @param _to the receiver of yt tokens
     */
    function beforeYtTransfer(address _from, address _to) external;

    /**
     * @notice Calculates and transfers the yield generated in form of ibt
     * @return returns the yield that is tranferred or will be transferred
     */
    function claimYield() external returns (uint256);

    /**
     * @notice Toggle Pause
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function pause() external;

    /**
     * @notice Toggle UnPause
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function unPause() external;

    /**
     * @notice Setter for the fee collector address
     * @param _feeCollector the address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external;

    /**
     * @notice Setter for the new maxProtocolFee
     * @param newMaxFee the new MaxFee to update
     */
    function setMaxProtocolFee(uint256 newMaxFee) external;

    /**
     * @notice Getter for the fee collector address
     * @return the address of the fee collector
     */
    function getFeeCollectorAddress() external view returns (address);

    /**
     * @notice get the address of zap depositor
     */
    function getZapDepositorAddress() external view returns (address);

    /**
     * @notice get the address of registry.
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Updates the yield till now for the _user address
     * @param _user the user whose yield will be updated
     * @return the yield of the user
     */
    function updateYield(address _user) external returns (uint256);

    /** @dev Deposits amount of assets into the pt contract and mints atleast minShares to user.
     * @param assets the amount of assets being deposited
     * @param receiver the receiver of the shares
     * @param minShares The minimum expected shares from this deposit
     * @return shares the amount of shares minted to the receiver
     */
    function deposit(
        uint256 assets,
        address receiver,
        uint256 minShares
    ) external returns (uint256);

    /** @dev Deposits amount of ibt into the pt contract and mints expected shares to users
     * @param ibtAmount the amount of ibt being deposited
     * @param receiver the receiver of the shares
     * @return shares the amount of shares minted to the receiver
     */
    function depositWithIBT(
        uint256 ibtAmount,
        address receiver
    ) external returns (uint256 shares);

    /** @dev Deposits amount of ibt into the pt contract and mints at least minShares to users
     * @param ibtAmount the amount of ibt being deposited
     * @param receiver the receiver of the shares
     * @param minShares The minimum expected shares from this deposit
     * @return shares the amount of shares minted to the receiver
     */
    function depositWithIBT(
        uint256 ibtAmount,
        address receiver,
        uint256 minShares
    ) external returns (uint256);

    /** @dev Takes assets(Maximum maxAssets) and mints exactly shares to user
     * @param shares the amount of shares to be minted
     * @param receiver the receiver of the shares
     * @param maxAssets The maximum assets that can be taken from the user
     * @return assets The actual amount of assets taken by pt contract for minting the shares.
     */
    function mint(
        uint256 shares,
        address receiver,
        uint256 maxAssets
    ) external returns (uint256);

    /** @dev Burns the exact shares of users and return the assets to user
     * @param shares the amount of shares to be burnt
     * @param receiver the receiver of the assets
     * @param owner the owner of the shares
     * @param minAssets The minimum assets that should be returned to user
     * @return assets The actual amount of assets returned by pt contract for burning the shares.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssets
    ) external returns (uint256);

    /** @dev Burns the shares of users and return the exact assets to user
     * @param assets the amount of exact assets to be returned
     * @param receiver the receiver of the assets
     * @param owner the owner of the shares
     * @param maxShares The maximum shares that can be burnt by the pt contract
     * @return shares The actual amount of shares burnt by pt contract for returning the assets.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxShares
    ) external returns (uint256);

    /** @dev Converts the amount of ibt to its equivalent value in assets
     * @param ibtAmount The amount of ibt to convert to assets
     */
    function convertToAssetsOfIBT(
        uint256 ibtAmount
    ) external view returns (uint256);

    /** @dev Converts the amount of assets tokens to its equivalent value in ibt
     * @param assets The amount of assets to convert to ibt
     */
    function convertToSharesOfIBT(
        uint256 assets
    ) external view returns (uint256);

    /** @dev Returns the ibt address of the pt contract
     * @return ibt the address of the ibt token
     */
    function getIBT() external returns (address ibt);

    /** @dev Returns the ibtRate at the time of calling */
    function getIBTRate() external view returns (uint256);

    /** @dev Returns the ptRate at the time of calling */
    function getPTRate() external view returns (uint256);

    /** @dev Returns value equal to 1 unit of ibt */
    function getIBTUnit() external view returns (uint256);

    /** @dev Returns value equal to 1 unit of asset */
    function getAssetUnit() external view returns (uint256);

    /** @dev Returns max fee that can be set for the pt contract */
    function getMaxProtocolFee() external view returns (uint256);

    /** @dev Returns the yt address of the pt contract
     * @return yt the address of the yt token
     */
    function getYT() external returns (address yt);

    /** @dev Returns the registry address set in the pt contract */
    function getRegistry() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "../util/lib/StructUtil.sol";

interface IPrincipalTokenFactory {
    /* Errors
     *****************************************************************************************************************/

    error BeaconNotSet();
    error CurveFactoryNotSet();
    error DeploymentFailed();
    error ZeroAddressError();
    error FailedToFetchCurveFactoryAddress();

    /**
     * @notice Deploys the PrincipalToken contract implementation.
     * @param name_ Name of the PrincipalToken.
     * @param symbol_ Symbol of the PrincipalToken.
     * @param ibt_ Address of the ibt of the PrincipalToken.
     * @param maturity_ The maturity time of the PrincipalToken.
     * @param max_fees_ Maximum fees of the PrincipalToken.
     * @param registry_ Address of the Registry contract of the PrincipalToken.
     * @return principalToken The address of the principalToken deployed.
     * @return curvePoolAddress The address of the curve Pool deployed for ibt/pt.
     */
    function deployPrincipalToken(
        string memory name_,
        string memory symbol_,
        address ibt_,
        uint256 maturity_,
        uint256 max_fees_,
        address registry_,
        address principalTokenAdmin_
    ) external returns (address principalToken, address curvePoolAddress);

    /**
    * @notice Function which sets the curveAddressProvider address used in
      getting the curve factory address. Can only be called by owner.
    * @param curveAddressProvider The address of the curveAddressProvider.
     */
    function setCurveAddressProvider(address curveAddressProvider) external;

    /**
     * @notice Setter for the registry address, Can only be called by the owner.
     * @param _newRegistry the address of the token factory
     */
    function setRegistry(address _newRegistry) external;

    /**
     * @notice Getter for the curve factory address
     * @return the address of the curve factory
     */
    function getCurveFactoryAddress() external view returns (address);

    /**
     * @notice Getter for the pool registered with this future.
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Getter for the pool registered with this principalToken.
     * @param _principalToken the address of the principalToken.
     */
    function getPool(
        address _principalToken,
        uint256 poolIndex
    ) external view returns (StructUtil.PoolData calldata pool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface IRegistry {
    /* Errors
     *****************************************************************************************************************/
    error ZeroAddressError();
    error PTListUpdateFailed();

    /**
     * @notice Setter for the tokens factory addres
     * @param _newPrincipalTokenFactory the address of the token factory
     */
    function setPrincipalTokenFactory(
        address _newPrincipalTokenFactory
    ) external;

    /**
     * @notice Getter for the token factory address
     * @return the token factory address
     */
    function getPrincipalTokenFactoryAddress() external view returns (address);

    /**
     * @notice Setter for the LP vault factory address
     * @param _lpVaultFactory The address of the LP vault factory
     */
    function setLPVaultFactory(address _lpVaultFactory) external;

    /**
     * @notice Getter for the LP vault factory address
     * @return The LP vault factory address
     */
    function getLPVaultFactory() external view returns (address);

    /* Futures
     *****************************************************************************************************************/

    /**
     * @notice Add a principalToken to the registry
     * @param _principalToken the address of the principalToken to add to the registry
     */
    function addPrincipalToken(address _principalToken) external;

    /**
     * @notice Remove a principalToken from the registry
     * @param _principalToken the address of the principalToken to remove from the registry
     */
    function removePrincipalToken(address _principalToken) external;

    /**
     * @notice set zap depositor
     * @param _zap address of zap depositor
     */
    function setZapDepositor(address _zap) external;

    /**
     * @notice Getter to check if a principalToken is registered
     * @param _principalToken the address of the principalToken to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredPrincipalToken(
        address _principalToken
    ) external view returns (bool);

    /**
     * @notice Getter for the principalToken registered at an index
     * @param _index the index of the principalToken to return
     * @return the address of the corresponding principalToken
     */
    function getPrincipalTokenAt(
        uint256 _index
    ) external view returns (address);

    /**
     * @notice Getter for number of principalToken registered
     * @return the number of principalToken registered
     */
    function principalTokenCount() external view returns (uint256);

    /**
     * @notice get the address of zap depositor
     */
    function getZapDepositor() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

import "openzeppelin-contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

pragma solidity 0.8.13;

interface IYT is IERC20Upgradeable {
    error CallerIsNotPtContract();

    /**
     * @notice Initializer of the contract.
     * @param name_ The name of the yt token.
     * @param symbol_ The symbol of the yt token.
     * @param principalToken The address of the PT associated with this YT token.
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address principalToken
    ) external;

    /**
    @notice returns the decimals of the yt tokens.
    */
    function decimals() external view returns (uint8);

    /** @dev Returns the address of principalToken associated with this YT. */
    function getPrincipalToken() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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

    /**
     * @notice checks for msg.sender to be principalToken and then calls _burn of ERC20Upgradeable.
     * See {ERC20Upgradeable- _burn}.
     */
    function burnWithoutUpdate(address from, uint256 amount) external;

    /**
     * @notice checks for msg.sender to be principalToken and then calls _mint of ERC20Upgradeable.
     * See {ERC20Upgradeable- _mint}.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account` before expiry, and 0 after expiry.
     * @notice This behaviour is for UI/UX purposes only.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the actual amount of tokens owned by `account` at any point in time.
     */
    function actualBalanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "openzeppelin-erc20-extensions/draft-ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts/proxy/beacon/BeaconProxy.sol";

import "../util/lib/NamingUtil.sol";

import "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IPrincipalToken.sol";
import "../interfaces/IYT.sol";

contract PrincipalToken is
    ERC20PermitUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IERC4626Upgradeable,
    IPrincipalToken
{
    using MathUpgradeable for uint256;

    uint256 private constant MAX_FEES = 1e18; // equivalent to 100% fees
    uint256 private constant SAFETY_BOUND = 100; // used to favour the protocol in case of approximations

    bool private ratesAtExpiryStored;
    bool private transferYield; // this flag is checked in claimYield whether to transfer yield or not
    address private zapDepositor; //zap depositor
    IERC20MetadataUpgradeable private _asset;
    IYT private yt; // yield token of this principalToken, deployed while initializing
    uint256 private ibtUnit; // equal to one unit(10^decimals) of the token (IBT) held by the pt contract
    uint256 private assetUnit; // equal to one unit(10^decimals) of the token (asset)
    uint256 private totalFeesInIBT;
    address private feeCollector;
    uint256 private ptRate;
    uint256 private ibtRate;
    uint256 private expiry; // expiry of the principalToken, set at the time of initializing
    address private ibt; // interest bearing token held by the pt contract
    uint256 private unclaimedFeesInIBT;
    uint256 private maxProtocolFee;
    IRegistry private registry; // registry required to fetch address of zap depositors

    mapping(address => uint256) private ibtRateOfUser; // stores each user's IBT rate
    mapping(address => uint256) private ptRateOfUser; // stores each user's PT rate
    mapping(address => uint256) public yieldOfUserInIBT; // mapping between the user address and the amount of ibt generated from the yield

    /* EVENTS
     *****************************************************************************************************************/
    event Redeem(address indexed from, address indexed to, uint256 assets);
    event YTDeployed(address indexed yt);
    event YieldUpdated(address indexed user, uint256 indexed yield);
    event FeeClaimed(address indexed _feeCollector, uint256 _feesInIBT);
    event YieldTransferred(address indexed receiver, uint256 yield);
    event UpdatedZapDepositor(address indexed zapDepositor);
    event UpdatedFeeCollector(address indexed feeCollector);
    event RatesStoredAtExpiry(
        uint256 indexed _ibtRate,
        uint256 indexed _ptRate
    );
    event MaxProtocolFeeUpdated(
        uint256 indexed oldMaxFee,
        uint256 indexed newMaxFee
    );

    /* MODIFIERS
     *****************************************************************************************************************/

    /// @notice A modifier that ensures the current block timestamp is at or before expiry
    modifier notExpired() virtual {
        if (block.timestamp > expiry) {
            revert PrincipalTokenExpired();
        }
        _;
    }

    /// @notice A modifier that ensures the current block timestamp is at or after expiry
    modifier afterExpiry() virtual {
        if (block.timestamp < expiry) {
            revert PrincipalTokenNotExpired();
        }
        _;
    }

    // constructor
    constructor() {
        _disableInitializers(); // using this so that the deployed logic contract later cannot be initialized
    }

    /* INITIALIZER
     *****************************************************************************************************************/

    /**
     * @dev First function called after deployment of the contract
     * it deploys YT and intializes values of required variables
     * @param _name Name of the principalToken(PT)
     * @param _symbol Symbol of the principalToken
     * @param _ibt The token which pt contract holds
     * @param _expiry the timestamp at which the pt contract will expire/mature
     * @param _max_fees The maximum fees charged by the protocol on the yield generated (in %)
     * @param _registry The address of registry which stores address
     * @param _ytBeacon The address of yt beacon
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _ibt,
        uint256 _expiry,
        uint256 _max_fees,
        address _registry,
        address _ytBeacon
    ) external initializer {
        if (_ytBeacon == address(0) || _ibt == address(0)) {
            revert ZeroAddressError();
        }
        _asset = IERC20MetadataUpgradeable(IERC4626Upgradeable(_ibt).asset());
        expiry = _expiry + block.timestamp;
        string memory _ibtSymbol = IERC4626Upgradeable(_ibt).symbol();
        string memory ptSymbol = NamingUtil.genPTSymbol(_ibtSymbol, expiry);
        __ERC20_init(_name, ptSymbol);
        __ERC20Permit_init(_name);
        __Ownable2Step_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        ibtUnit = 10 ** IERC4626Upgradeable(_ibt).decimals();
        assetUnit = 10 ** _asset.decimals();
        ibt = _ibt;
        string memory _ytSymbol = NamingUtil.genYTSymbol(_ibtSymbol, expiry);
        yt = _deployYT("Yield Token", _ytSymbol, _ytBeacon);
        ibtRate = convertToAssetsOfIBT(ibtUnit);
        ptRate = assetUnit;
        if (_max_fees > MAX_FEES) {
            revert FeeMoreThanMaxValue();
        }
        maxProtocolFee = _max_fees;
        registry = IRegistry(_registry);
        transferYield = true;
        zapDepositor = registry.getZapDepositor();
    }

    /** @dev See {PausableUpgradeable-_pause}. */
    function pause() external override {
        _checkOwner();
        _pause();
    }

    /** @dev See {PausableUpgradeable-_unPause}. */
    function unPause() external override {
        _checkOwner();
        _unpause();
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        override
        notExpired
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(address(_asset)),
            msg.sender,
            address(this),
            assets
        );
        SafeERC20Upgradeable.safeIncreaseAllowance(
            IERC20Upgradeable(address(_asset)),
            ibt,
            assets
        );
        uint256 ibtAmount = IERC4626Upgradeable(ibt).deposit(
            assets,
            address(this)
        );
        shares = _depositIBT(ibtAmount, receiver);
    }

    /** @dev See {IPrincipalToken-deposit}.
     * @notice This function should be integrated on UI instead of deposit(uint256 assets,address receiver)
     */
    function deposit(
        uint256 assets,
        address receiver,
        uint256 minShares
    ) external override returns (uint256) {
        uint256 shares = deposit(assets, receiver);
        if (shares < minShares) {
            revert SharesValueLessThanMinValue();
        }
        return shares;
    }

    /** @dev See {IPrincipalToken-depositWithIBT}.*/
    function depositWithIBT(
        uint256 ibtAmount,
        address receiver
    )
        public
        override
        notExpired
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC4626Upgradeable(ibt),
            msg.sender,
            address(this),
            ibtAmount
        );
        shares = _depositIBT(ibtAmount, receiver);
    }

    /** @dev See {IPrincipalToken-depositWithIBT}.
     * @notice This function should be integrated on UI instead of depositWithIBT(uint256 ibtAmount,address receiver)
     */
    function depositWithIBT(
        uint256 ibtAmount,
        address receiver,
        uint256 minShares
    ) external override returns (uint256) {
        uint256 shares = depositWithIBT(ibtAmount, receiver);
        if (shares < minShares) {
            revert SharesValueLessThanMinValue();
        }
        return shares;
    }

    /** @dev See {IERC4626-mint}. */
    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256) {
        uint256 assets = convertToAssets(shares);
        deposit(assets, receiver);

        return assets;
    }

    /** @dev See {IPrincipalToken-mint}.
     * @notice This function should be integrated on UI instead of mint(uint256 shares,address receiver)
     */
    function mint(
        uint256 shares,
        address receiver,
        uint256 maxAssets
    ) external override returns (uint256) {
        uint256 assets = mint(shares, receiver);
        if (assets > maxAssets) {
            revert AssetsValueMoreThanMaxValue();
        }
        return assets;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        public
        override
        afterExpiry
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        if (owner != msg.sender) {
            revert CallerIsNotOwner();
        }
        if (shares > maxRedeem(owner)) {
            revert SharesValueMoreThanMaxValue();
        }

        assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        IERC4626Upgradeable(ibt).withdraw(assets, receiver, address(this));
        emit Redeem(owner, receiver, assets);
    }

    /** @dev See {IPrincipalToken-redeem}.
     * @notice This function should be integrated on UI instead of redeem(uint256 shares,address receiver, address owner)
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssets
    ) external override returns (uint256) {
        uint256 assets = redeem(shares, receiver, owner);
        if (assets < minAssets) {
            revert AssetsValueLessThanMinValue();
        }
        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        override(IERC4626Upgradeable)
        notExpired
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        if (owner != msg.sender) {
            revert CallerIsNotOwner();
        }
        uint256 yieldInIBT = updateYield(owner);
        uint256 maxAssetsToWithdraw = maxWithdraw(owner);
        if (maxAssetsToWithdraw < assets) {
            revert AssetsValueMoreThanMaxValue();
        }
        uint256 ytBalance = yt.actualBalanceOf(owner);
        uint256 maxBurnablePT = balanceOf(owner);
        maxBurnablePT = (maxBurnablePT > ytBalance) ? ytBalance : maxBurnablePT; // maximum pt that can be burned
        uint256 ptInIBT = convertToSharesOfIBT(convertToAssets(maxBurnablePT)); // owner's pt value in IBT
        if (ptInIBT == 0) {
            // if ptInIBT is 0 then either the max burnable pt or the pt rate is 0
            return 0;
        }
        // dividing by 10^18 because fees is in terms of 18 decimals for precision.
        uint256 feesInIBT = (yieldInIBT * maxProtocolFee) / MAX_FEES; // fees of the yield of owner in IBT
        uint256 assetsInIBT = convertToSharesOfIBT(assets); // desired withdrawn assets in IBT
        uint256 ytSharesToClaimYield; // yt shares calculation for yield claiming.
        // calculation of shares that will be burnt for yt and pt.
        if (assetsInIBT > yieldInIBT - feesInIBT) {
            ytSharesToClaimYield = ytBalance;
            shares =
                (maxBurnablePT * (assetsInIBT - (yieldInIBT - feesInIBT))) /
                (ptInIBT);
        } else {
            if (yieldInIBT - feesInIBT == 0) {
                revert NetYieldZero();
            }
            ytSharesToClaimYield =
                (assetsInIBT * ytBalance) /
                (yieldInIBT - feesInIBT);
            shares = 0;
        }
        transferYield = false;
        claimYieldOfAmount(ytSharesToClaimYield);
        // burning shares of owner's yt and pt
        yt.burnWithoutUpdate(owner, shares);
        _withdraw(msg.sender, receiver, owner, assets, shares);

        IERC4626Upgradeable(ibt).withdraw(assets, receiver, address(this));
    }

    /** @dev See {IPrincipalToken-withdraw}.
     * @notice This function should be integrated on UI instead of withdraw(uint256 assets,address receiver, address owner)
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxShares
    ) external override returns (uint256) {
        uint256 shares = withdraw(assets, receiver, owner);
        if (shares > maxShares) {
            revert SharesValueMoreThanMaxValue();
        }
        return shares;
    }

    /** @dev See {IPrincipalToken-withdrawAfterExpiry}. */
    function withdrawAfterExpiry(
        address receiver,
        address owner
    )
        external
        override
        afterExpiry
        nonReentrant
        whenNotPaused
        returns (uint256 withdrawnAssets)
    {
        if (owner != msg.sender) {
            revert CallerIsNotOwner();
        }
        uint256 shares = maxRedeem(owner);
        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        // get all the owner's net yield in IBT
        uint256 yieldInIBT = updateYield(owner);
        yieldOfUserInIBT[owner] = 0;
        // dividing by 10^18 because fees is in terms of 18 decimals for precision.
        uint256 currentFee = ((yieldInIBT * maxProtocolFee) / MAX_FEES);
        _updateFees(currentFee);
        yieldInIBT -= currentFee;
        emit YieldTransferred(receiver, convertToAssetsOfIBT(yieldInIBT));
        // withdraw all the owner's PT and yield in IBT and send it to receiver
        withdrawnAssets = assets + convertToAssetsOfIBT(yieldInIBT);
        IERC4626Upgradeable(ibt).withdraw(
            withdrawnAssets,
            receiver,
            address(this)
        );
        // burn all YT of the owner
        yt.burnWithoutUpdate(owner, yt.actualBalanceOf(owner));
    }

    /**
     * To claim collected fee so far
     */
    function claimFees() external returns (uint256) {
        if (msg.sender != feeCollector) {
            revert CallerIsNotFeeCollector();
        }
        uint256 _feesInIBT = unclaimedFeesInIBT;
        uint256 _feesInUnderlying = convertToAssetsOfIBT(_feesInIBT);
        unclaimedFeesInIBT = 0;

        IERC4626Upgradeable(ibt).withdraw(
            _feesInUnderlying,
            feeCollector,
            address(this)
        );
        emit FeeClaimed(feeCollector, _feesInIBT);
        return _feesInUnderlying;
    }

    /** @dev See {IPrincipalToken-updateYield}. */
    function updateYield(
        address _user
    ) public override returns (uint256 updatedUserYieldInIBT) {
        (uint256 _ptRate, uint256 _ibtRate) = _updatePTandIBTRates();

        uint256 _oldIBTRateUser = ibtRateOfUser[_user];
        uint256 _oldPTRateUser = ptRateOfUser[_user];

        // Check for skipping yield update when the user deposits for the first time or rates decreased to 0.
        if (_oldIBTRateUser != 0) {
            updatedUserYieldInIBT = _computeYield(
                _user,
                _oldIBTRateUser,
                _ibtRate,
                _oldPTRateUser,
                _ptRate
            );
            yieldOfUserInIBT[_user] = updatedUserYieldInIBT;
            emit YieldUpdated(_user, updatedUserYieldInIBT);
        }

        if (_oldIBTRateUser != _ibtRate) {
            ibtRateOfUser[_user] = _ibtRate;
        }
        if (_oldPTRateUser != _ptRate) {
            ptRateOfUser[_user] = _ptRate;
        }
    }

    /** @dev See {IPrincipalToken-claimYield}. */
    function claimYield() external override returns (uint256) {
        return claimYieldOfAmount(yt.actualBalanceOf(msg.sender));
    }

    /**
     * @dev Claim yield of a specific amount of YT
     * @param _amount The amount setting a ratio amount/yt balance which indicates the proportion of yield to claim
     * @return The amount of yield claimed in underlying
     */
    function claimYieldOfAmount(
        uint256 _amount
    ) public notExpired returns (uint256) {
        address _user = msg.sender;
        uint256 yieldToTransfer = updateYield(_user);
        uint256 userYTBalance = yt.actualBalanceOf(_user);
        if (yieldToTransfer != 0 && (_amount != 0 || userYTBalance == 0)) {
            _amount = _amount > userYTBalance ? userYTBalance : _amount;
            // get the amount to user yt balance ratio (1 if yt balance is 0)
            uint256 ratio = userYTBalance == 0
                ? ibtUnit
                : MathUpgradeable.ceilDiv((_amount * ibtUnit), userYTBalance);
            yieldToTransfer = (yieldToTransfer * ratio) / ibtUnit;
            if (yieldToTransfer > yieldOfUserInIBT[_user]) {
                revert TransferValueExceedsYieldBalance();
            }
            yieldOfUserInIBT[_user] -= yieldToTransfer;
            uint256 currentFee = ((yieldToTransfer * maxProtocolFee) /
                MAX_FEES); // dividing by 10^18 because fees is in terms of 18 decimals for precision.
            _updateFees(currentFee);
            yieldToTransfer -= currentFee;
            uint256 yieldToTransferInUnderlying = convertToAssetsOfIBT(
                yieldToTransfer
            );
            emit YieldTransferred(_user, yieldToTransferInUnderlying);
            if (!transferYield) {
                transferYield = true;
                return yieldToTransferInUnderlying;
            }
            IERC4626Upgradeable(ibt).withdraw(
                yieldToTransferInUnderlying,
                _user,
                address(this)
            );
            return yieldToTransferInUnderlying;
        } else {
            return 0;
        }
    }

    /** @dev See {IPrincipalToken-beforeYtTransfer}. */
    function beforeYtTransfer(address _from, address _to) external override {
        if (msg.sender != address(yt)) {
            revert CallerIsNotYtContract();
        }
        updateYield(_from);
        updateYield(_to);
    }

    /* SETTERS
     *****************************************************************************************************************/

    /**
     * @notice Setter for the new maxProtocolFee
     * @param newMaxFee the new MaxFee to update
     */
    function setMaxProtocolFee(uint256 newMaxFee) public override {
        _checkOwner();
        if (newMaxFee > MAX_FEES) {
            revert FeeMoreThanMaxValue();
        }
        emit MaxProtocolFeeUpdated(maxProtocolFee, newMaxFee);
        maxProtocolFee = newMaxFee;
    }

    /**
     * @notice Setter for the controller address
     * @param _feeCollector the address of the new controller
     */
    function setFeeCollector(address _feeCollector) public {
        _checkOwner();
        if (_feeCollector == address(0)) {
            revert ZeroAddressError();
        }
        feeCollector = _feeCollector;
        emit UpdatedFeeCollector(feeCollector);
    }

    /** @dev See {IPrincipalToken-storeRatesAtExpiry}. */
    function storeRatesAtExpiry()
        external
        override
        afterExpiry
        returns (uint256 _ibtRate, uint256 _ptRate)
    {
        if ((ratesAtExpiryStored)) {
            revert RatesAtExpiryAlreadyStored();
        }
        ratesAtExpiryStored = true;

        (_ptRate, _ibtRate) = _getCurrentPTandIBTRates();
        ibtRate = _ibtRate;
        ptRate = _ptRate;
        emit RatesStoredAtExpiry(_ibtRate, _ptRate);
    }

    /**
     * @notice update zap depositor
     */
    function updateZapDepositor() external {
        _checkOwner();
        zapDepositor = registry.getZapDepositor();
        emit UpdatedZapDepositor(zapDepositor);
    }

    /* GETTERS
     *****************************************************************************************************************/

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(
        uint256 assets
    ) external view override notExpired whenNotPaused returns (uint256) {
        return convertToShares(assets);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(
        uint256 assets
    ) public view override whenNotPaused returns (uint256) {
        (uint256 _ptRate, uint256 _ibtRate) = _getPTandIBTRates();
        uint256 _yieldOfUserInIBT = _computeCurrentYieldInIBTOfUserWithRates(
            msg.sender,
            _ptRate,
            _ibtRate
        );
        uint256 maxNetYieldOfUserInUnderlying = convertToAssetsOfIBT(
            (_yieldOfUserInIBT * (MAX_FEES - maxProtocolFee)) / MAX_FEES
        );

        if (assets <= maxNetYieldOfUserInUnderlying) {
            return 0;
        } else {
            return
                convertToSharesWithRate(
                    assets - maxNetYieldOfUserInUnderlying,
                    _ptRate
                );
        }
    }

    /** @dev See {IERC4626-maxWithdraw}.
     * @param owner the owner of the shares and yield
     * @return maxAssets the maximum amount of underlying assets that can be withdrawn from the owner
     */
    function maxWithdraw(
        address owner
    ) public view override whenNotPaused returns (uint256) {
        uint256 ptBalance = balanceOf(owner);
        uint256 ytBalance = yt.actualBalanceOf(owner);
        uint256 maxBurnable;
        if (block.timestamp <= expiry) {
            maxBurnable = (ptBalance > ytBalance) ? ytBalance : ptBalance;
        } else {
            maxBurnable = ptBalance;
        }
        (uint256 _ptRate, uint256 _ibtRate) = _getPTandIBTRates();
        uint256 _yieldOfUserInIBT = _computeCurrentYieldInIBTOfUserWithRates(
            owner,
            _ptRate,
            _ibtRate
        );
        return
            convertToAssetsOfIBT(
                ((MAX_FEES - maxProtocolFee) * _yieldOfUserInIBT) / MAX_FEES
            ) + convertToAssetsWithRate(maxBurnable, _ptRate);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(
        uint256 shares
    ) external view override returns (uint256) {
        return _convertToAssets(shares);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(
        uint256 shares
    ) public view override afterExpiry whenNotPaused returns (uint256) {
        if (ratesAtExpiryStored) {
            // amount shares of pt value in assets at expiry
            uint256 assetsAtExpiry = convertToAssetsWithRate(shares, ptRate);
            // ibt at expiry corresponding to assetsAtExpiry
            uint256 assetsInIBTAtExpiry = convertAssetsToIBTWithRate(
                assetsAtExpiry,
                ibtRate
            );
            // value now of the assetsInIBTAtExpiry in assets
            return convertToAssetsOfIBT(assetsInIBTAtExpiry);
        } else {
            revert RatesAtExpiryNotStored();
        }
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view override returns (uint256) {
        return block.timestamp >= expiry ? balanceOf(owner) : 0;
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(
        uint256 assets
    ) public view override returns (uint256 shares) {
        return _convertToShares(assets);
    }

    /** @dev See {IPrincipalToken-convertToPrincipal}. */
    function convertToPrincipal(
        uint256 underlyingAmount
    ) external view override returns (uint256) {
        return _convertToShares(underlyingAmount);
    }

    /** @dev See {IPrincipalToken-convertToSharesWithRate}. */
    function convertToSharesWithRate(
        uint256 assets,
        uint256 _ptRate
    ) public view returns (uint256 shares) {
        return (assets * ibtUnit) / _ptRate;
    }

    /** @dev See {IPrincipalToken-convertToSharesOfIBT}. */
    function convertToSharesOfIBT(
        uint256 assets
    ) public view override returns (uint256) {
        return _convertToSharesOfIBT(assets);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(
        uint256 shares
    ) public view override returns (uint256 assets) {
        return _convertToAssets(shares);
    }

    /** @dev See {IPrincipalToken-convertToUnderlying}. */
    function convertToUnderlying(
        uint256 principalAmount
    ) external view override returns (uint256) {
        return _convertToAssets(principalAmount);
    }

    /** @dev See {IPrincipalToken-convertToAssetsWithRate}. */
    function convertToAssetsWithRate(
        uint256 shares,
        uint256 _ptRate
    ) public view returns (uint256 assets) {
        return (shares * _ptRate) / ibtUnit;
    }

    /** @dev See {IPrincipalToken-convertToAssetsOfIBT}. */
    function convertToAssetsOfIBT(
        uint256 ibtAmount
    ) public view override returns (uint256) {
        return _convertToAssetsOfIBT(ibtAmount);
    }

    /** @dev See {IPrincipalToken-convertIBTToAssetsWithRate}. */
    function convertIBTToAssetsWithRate(
        uint256 ibtAmount,
        uint256 _ibtRate
    ) external view override returns (uint256) {
        return (ibtAmount * (_ibtRate)) / (ibtUnit);
    }

    /** @dev See {IPrincipalToken-convertAssetsToIBTWithRate}. */
    function convertAssetsToIBTWithRate(
        uint256 assets,
        uint256 _ibtRate
    ) public view override returns (uint256) {
        return (assets * (ibtUnit)) / (_ibtRate);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view override returns (uint256) {
        uint256 ibtBalance = IERC4626Upgradeable(ibt).balanceOf(address(this));
        return convertToAssetsOfIBT(ibtBalance);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public pure override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public pure override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC20Upgradeable-decimals} */
    function decimals()
        public
        view
        override(IERC20MetadataUpgradeable, ERC20Upgradeable)
        returns (uint8)
    {
        return IERC4626Upgradeable(ibt).decimals();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() external view override returns (address) {
        return address(_asset);
    }

    /** @dev See {IPrincipalToken-underlying}. */
    function underlying() external view override returns (address) {
        return address(_asset);
    }

    /** @dev See {IPrincipalToken-underlying}. */
    function maturity() external view override returns (uint256) {
        return expiry;
    }

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getFeeCollectorAddress() external view returns (address) {
        return feeCollector;
    }

    /**
     * @notice get the address of zap depositor
     */
    function getZapDepositorAddress() external view returns (address) {
        return zapDepositor;
    }

    /**
     * @notice get the address of registry.
     */
    function getRegistryAddress() external view returns (address) {
        return address(registry);
    }

    /** @dev See {IPrincipalToken-getIBT}. */
    function getIBT() external view override returns (address) {
        return ibt;
    }

    /** @dev See {IPrincipalToken-getYT}. */
    function getYT() external view override returns (address) {
        return address(yt);
    }

    /** @dev See {IPrincipalToken-getRegistry}. */
    function getRegistry() external view override returns (address) {
        return address(registry);
    }

    /** @dev Returns max fee that can be set for the pt contract */
    function getMaxProtocolFee() external view override returns (uint256) {
        return maxProtocolFee;
    }

    /**
     * @notice get the address of zap depositor
     */
    function getZapDepositor() external view returns (address) {
        return zapDepositor;
    }

    /** @dev See {IPrincipalToken-getIBTRate}. */
    function getIBTRate() external view override returns (uint256) {
        return ibtRate;
    }

    /** @dev See {IPrincipalToken-getPTRate}. */
    function getPTRate() external view override returns (uint256) {
        return ptRate;
    }

    /** @dev See {IPrincipalToken-getIBTUnit}. */
    function getIBTUnit() external view override returns (uint256) {
        return ibtUnit;
    }

    /** @dev See {IPrincipalToken-getAssetUnit}. */
    function getAssetUnit() external view override returns (uint256) {
        return assetUnit;
    }

    /** @dev See {IPrincipalToken-getIBTRateAtExpiry}. */
    function getIBTRateAtExpiry() external view override returns (uint256) {
        if (!ratesAtExpiryStored) {
            revert RatesAtExpiryNotStored();
        }
        return ibtRate;
    }

    /** @dev See {IPrincipalToken-getPTRateAtExpiry}. */
    function getPTRateAtExpiry() external view override returns (uint256) {
        if (!ratesAtExpiryStored) {
            revert RatesAtExpiryNotStored();
        }
        return ptRate;
    }

    /**
     * @notice get the IBT amount of fee collected which is still unclaimed
     */
    function getUnclaimedFeesInIBT() external view returns (uint256) {
        return unclaimedFeesInIBT;
    }

    /**
     * @notice get the current yield in IBT of the user
     * @param _user the address of the user to get the current yield from
     * @return _yieldOfUserInIBT the yield in IBT of the user
     */
    function getCurrentYieldInIBTOfUser(
        address _user
    ) external view returns (uint256 _yieldOfUserInIBT) {
        (uint256 _ptRate, uint256 _ibtRate) = _getPTandIBTRates();
        _yieldOfUserInIBT = _computeCurrentYieldInIBTOfUserWithRates(
            _user,
            _ptRate,
            _ibtRate
        );
    }

    /* INTERNAL FUNCTIONS
     *****************************************************************************************************************/

    /**
     * @dev Deploys a yield token for this principalToken,
     * called while initializing.
     * @param name_ Name of the yield token.
     * @param symbol_ Symbol of the yield token.
     * @param ytBeacon_ The address of yt beacon.
     * @return deployed yield token.
     */
    function _deployYT(
        string memory name_,
        string memory symbol_,
        address ytBeacon_
    ) internal returns (IYT) {
        address _ytAddr = address(
            new BeaconProxy(
                ytBeacon_,
                abi.encodeWithSelector(
                    IYT(address(0)).initialize.selector,
                    name_,
                    symbol_,
                    address(this)
                )
            )
        );
        emit YTDeployed(_ytAddr);
        return IYT(_ytAddr);
    }

    /**
     * @dev Converts amount of assets (underlying) to amount of shares (pt/yt)
     * @param assets amount of assets to convert in shares
     * @return shares resulting amount of shares
     */
    function _convertToShares(
        uint256 assets
    ) internal view returns (uint256 shares) {
        (uint256 _ptRate, ) = _getPTandIBTRates();
        return (assets * ibtUnit) / _ptRate;
    }

    /**
     * @dev Converts amount of shares (pt/yt) to amount of assets (underlying)
     * @param shares amount of shares to convert in assets
     * @return assets resulting amount of assets
     */
    function _convertToAssets(
        uint256 shares
    ) internal view returns (uint256 assets) {
        (uint256 _ptRate, ) = _getPTandIBTRates();
        return (shares * _ptRate) / ibtUnit;
    }

    /**
     * @dev Converts amount of assets to amount of ibt
     * @param assets amount of assets to convert in ibt
     */
    function _convertToSharesOfIBT(
        uint256 assets
    ) internal view returns (uint256) {
        return IERC4626Upgradeable(ibt).convertToShares(assets);
    }

    /**
     * @dev Converts amount of ibt to amount of assets
     * @param ibtAmount amount of ibt to convert
     */
    function _convertToAssetsOfIBT(
        uint256 ibtAmount
    ) internal view returns (uint256) {
        return IERC4626Upgradeable(ibt).convertToAssets(ibtAmount);
    }

    /**
     * @dev updated un claimed fees when yield is claimed
     * @param _feesInIBT the fees to be added (in IBT)
     */
    function _updateFees(uint256 _feesInIBT) internal {
        unclaimedFeesInIBT = unclaimedFeesInIBT + _feesInIBT;
        totalFeesInIBT = totalFeesInIBT + _feesInIBT;
    }

    /**
     * @dev Internal function for minting pt & yt to depositing user. Also updates yield before minting.
     * @param ibtAmount the amount of ibt being deposited by the user
     * @param receiver the address of the receiver
     * @return shares returns the amount of shares being minted to the receiver
     */
    function _depositIBT(
        uint256 ibtAmount,
        address receiver
    ) internal returns (uint256 shares) {
        updateYield(receiver);
        uint256 amountInUnderlying = convertToAssetsOfIBT(ibtAmount);
        shares = convertToShares(amountInUnderlying);
        if (msg.sender == zapDepositor) {
            _deposit(msg.sender, msg.sender, amountInUnderlying, shares);
        } else {
            _deposit(msg.sender, receiver, amountInUnderlying, shares);
        }
        yt.mint(receiver, shares);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the pt contract, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transfered and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal {
        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the pt contract, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transfered, which is a valid state.
        _burn(owner, shares);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice compute the current yield in IBT of the user using the given rates
     * @param _user the address of the user to get the current yield from
     * @param _ptRate used as the new PT rate
     * @param _ibtRate used as the new IBT rate
     * @return _yieldOfUserInIBT the yield in IBT of the user using the given rates
     */
    function _computeCurrentYieldInIBTOfUserWithRates(
        address _user,
        uint256 _ptRate,
        uint256 _ibtRate
    ) internal view returns (uint256 _yieldOfUserInIBT) {
        uint256 _oldibtRate = ibtRateOfUser[_user];
        uint256 _oldptRate = ptRateOfUser[_user];
        // Check for skipping the computation of yield when the user oldIBTRate is 0.
        if (_oldibtRate != 0) {
            _yieldOfUserInIBT = _computeYield(
                _user,
                _oldibtRate,
                _ibtRate,
                _oldptRate,
                _ptRate
            );
        }
    }

    /**
     * @dev Internal function for computing yield of a user since last update
     * @param _user the address for which we want to calculate the yield
     * @param _oldIBTRate the previous deposit ibt rate of user
     * @param _ibtRate the current rate of IBT
     * @param _oldPTRate the previous deposit pt rate of user
     * @param _ptRate the current rate of PT
     * @return returns the calculated yield in IBT of user
     */
    function _computeYield(
        address _user,
        uint256 _oldIBTRate,
        uint256 _ibtRate,
        uint256 _oldPTRate,
        uint256 _ptRate
    ) internal view returns (uint256) {
        uint256 yieldInUnderlying;
        uint256 newYieldInIBT;
        uint256 currentYieldOfUser = yieldOfUserInIBT[_user];
        uint256 userYTBalance = yt.actualBalanceOf(_user);
        uint256 ibtOfYT = convertAssetsToIBTWithRate(
            convertToAssetsWithRate(userYTBalance, _oldPTRate),
            _oldIBTRate
        );
        if (_oldPTRate == _ptRate && _ibtRate == _oldIBTRate) {
            return currentYieldOfUser;
        } else if (_oldPTRate == _ptRate && _ibtRate > _oldIBTRate) {
            // only positive yield happened
            yieldInUnderlying = MathUpgradeable.mulDiv(
                ibtOfYT,
                (_ibtRate - _oldIBTRate),
                assetUnit
            );
            newYieldInIBT = convertAssetsToIBTWithRate(
                yieldInUnderlying,
                _ibtRate
            );
        } else {
            if (_oldPTRate > _ptRate) {
                // PT depeg happened
                if (_ibtRate >= _oldIBTRate) {
                    // both negative and positive yield happened, more positive
                    yieldInUnderlying =
                        MathUpgradeable.mulDiv(
                            userYTBalance,
                            (_oldPTRate - _ptRate),
                            assetUnit
                        ) +
                        MathUpgradeable.mulDiv(
                            ibtOfYT,
                            (_ibtRate - _oldIBTRate),
                            assetUnit
                        );
                } else {
                    // either both negative and positive yield happened, more negative
                    // or only negative yield happened
                    uint256 actualNegativeYieldInUnderlying = MathUpgradeable
                        .mulDiv(
                            userYTBalance,
                            (_oldPTRate - _ptRate),
                            assetUnit
                        );
                    uint256 expectedNegativeYieldInUnderlying = MathUpgradeable
                        .ceilDiv(ibtOfYT * (_oldIBTRate - _ibtRate), assetUnit);
                    yieldInUnderlying = expectedNegativeYieldInUnderlying >
                        actualNegativeYieldInUnderlying
                        ? 0
                        : actualNegativeYieldInUnderlying -
                            expectedNegativeYieldInUnderlying;
                    yieldInUnderlying = yieldInUnderlying < SAFETY_BOUND
                        ? 0
                        : yieldInUnderlying;
                }
                newYieldInIBT = convertAssetsToIBTWithRate(
                    yieldInUnderlying,
                    _ibtRate
                );
            } else {
                // PT rate increased or PT depeg was not depegged on IBT rate decrease
                revert PrincipalTokenRateError();
            }
        }
        return (currentYieldOfUser + newYieldInIBT);
    }

    /**
     * @dev Internal function for updating PT and IBT rates i.e. depegging PT if negative yield happened
     */
    function _updatePTandIBTRates()
        internal
        returns (uint256 _ptRate, uint256 _ibtRate)
    {
        (_ptRate, _ibtRate) = _getPTandIBTRates();
        if (block.timestamp <= expiry) {
            if (_ibtRate != ibtRate) {
                ibtRate = _ibtRate;
            }
            if (_ptRate != ptRate) {
                ptRate = _ptRate;
            }
        }
    }

    /**
     * @dev View function to get current IBT and PT rate
     * @return new pt and ibt rates
     */
    function _getCurrentPTandIBTRates()
        internal
        view
        returns (uint256, uint256)
    {
        uint256 currentIBTRate = convertToAssetsOfIBT(ibtUnit);
        uint256 currentPTRate = currentIBTRate < ibtRate
            ? (ptRate * currentIBTRate) / ibtRate
            : ptRate;
        return (currentPTRate, currentIBTRate);
    }

    /**
     * @dev View function to get IBT and PT rates
     * @return pt and ibt rates
     */
    function _getPTandIBTRates() internal view returns (uint256, uint256) {
        if (block.timestamp >= expiry) {
            if (ratesAtExpiryStored) {
                return (ptRate, ibtRate);
            } else {
                revert RatesAtExpiryNotStored();
            }
        } else {
            return _getCurrentPTandIBTRates();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

library NamingUtil {
    function genYTSymbol(
        string memory _ibtSymbol,
        uint256 _dateOfExpiry
    ) internal pure returns (string memory) {
        string memory date = uintToString(_dateOfExpiry);
        string memory symbol = concatenate(_ibtSymbol, "-");
        return
            concatenate(
                concatenate("PT-", concatenate("y", symbol)),
                date
            );
    }

    function genFYTSymbol(
        string memory _ytSymbol,
        uint256 _dateOfExpiry
    ) internal view returns (string memory) {
        string memory date = uintToString(_dateOfExpiry);
        string memory symbol = concatenate(_ytSymbol, "-");
        return
            concatenate(
                concatenate("FYT-", symbol),
                date
            );
    }

    function genPTSymbol(
        string memory _ibtSymbol,
        uint256 _dateOfExpiry
    ) internal pure returns (string memory) {
        string memory date = uintToString(_dateOfExpiry);
        string memory symbol = concatenate(_ibtSymbol, "-");
        return
            concatenate(
                concatenate("PT-", symbol),
                date
            );
    }

    function concatenate(
        string memory a,
        string memory b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function uintToString(uint256 _i) internal pure returns (string memory) {
       if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

library StructUtil {
    struct PoolData {
        address pool;
        string poolProtocolName;
    }
}