// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
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
        __ERC1967Upgrade_init_unchained();
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import { ECRecover } from "./ECRecover.sol";

/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./EIP/EIP712.sol";

contract Exchange is Initializable, UUPSUpgradeable, Proxied {
    using SafeMathUpgradeable for uint256;

    enum Errors {
        SIGNATURE_INVALID, // Signature is invalid
        MAKER_SIGNATURE_INVALID, // Maker signature is invalid
        TAKER_SIGNATURE_INVALID, // Taker signature is invalid
        SIDES_INVALID,
        PRICE_INVALID,
        ORDER_EXPIRED, // Order has already expired
        TRADE_ALREADY_COMPLETED_OR_CANCELLED, // Trade has already been completed or it has been cancelled by taker
        TRADE_AMOUNT_TOO_BIG, // Trade buyToken amount bigger than the remianing amountBuy
        ROUNDING_ERROR_TOO_LARGE // Rounding error too large
    }

    string public domainName;
    string public domainVersion;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address userAddress,address baseToken,address quoteToken,uint256 amount,uint256 pricepoint,uint256 side,uint256 salt,uint256 feeMake,uint256 feeTake)"
        );

    address public rewardAccount;
    mapping(address => bool) public operators;
    mapping(bytes => uint256) public filled; // Mappings of orderHash => amount of amountBuy filled.
    mapping(bytes32 => bool) public traded; // Mappings of tradeHash => bool value representing whether the trade is completed(true) or incomplete(false).
    mapping(bytes32 => Pair) public pairs;

    event LogRewardAccountUpdate(
        address oldRewardAccount,
        address newRewardAccount
    );
    event LogOperatorUpdate(address operator, bool isOperator);

    event LogBatchTrades(
        bytes[] makerOrderHashes,
        bytes[] takerOrderHashes,
        bytes32 indexed tokenPairHash
    );

    event LogTrade(
        address indexed maker,
        address indexed taker,
        address tokenSell,
        address tokenBuy,
        uint256 filledAmountSell,
        uint256 filledAmountBuy,
        uint256 paidFeeMake,
        uint256 paidFeeTake,
        bytes32 orderHash,
        bytes32 tradeHash,
        bytes32 indexed tokenPairHash // keccak256(makerToken, takerToken), allows subscribing to a token pair
    );

    event LogError(uint8 errorId, bytes makerOrderHash, bytes takerOrderHash);

    event LogCancelOrder(
        bytes orderHash,
        address userAddress,
        address baseToken,
        address quoteToken,
        uint256 amount,
        uint256 pricepoint,
        uint256 side
    );

    struct Pair {
        bytes32 pairID;
        address baseToken;
        address quoteToken;
        uint256 pricepointMultiplier;
    }

    struct Order {
        address userAddress;
        address baseToken;
        address quoteToken;
        uint256 amount;
        uint256 pricepoint;
        uint256 side;
        uint256 salt;
        uint256 feeMake;
        uint256 feeTake;
    }

    struct Trade {
        bytes32 orderHash; // Keccak-256 hash of the order to which the trade is linked
        uint256 amount; // The amount of buy tokens asked in the order
        uint256 tradeNonce; // A taker wise unique incrementing integer value assigned to the trade
        address taker; // Ethereum address of the trade taker
    }

    modifier onlyOperator() {
        require(
            msg.sender == _proxyAdmin() || operators[msg.sender],
            "Not operator"
        );
        _;
    }

    function initialize(
        string memory _domainName,
        string memory _domainVersion,
        address _rewardAccount,
        address _owner
    ) public initializer proxied {
        __UUPSUpgradeable_init();

        domainName = _domainName;
        domainVersion = _domainVersion;
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(
            _domainName,
            _domainVersion
        );

        rewardAccount = _rewardAccount;

        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                _owner
            )
        }
    }

    function transferOwnership(address _owner)
        external
        onlyProxyAdmin
        returns (bool success)
    {
        require(_owner != address(0) && _owner != _proxyAdmin(), "Invalid");

        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                _owner
            )
        }

        return true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        proxied
    {}

    function registerPair(
        address _baseToken,
        address _quoteToken,
        uint256 _pricepointMultiplier
    ) public onlyProxyAdmin returns (bool success) {
        bytes32 pairID = getPairHash(_baseToken, _quoteToken);

        pairs[pairID] = Pair({
            pairID: pairID,
            baseToken: _baseToken,
            quoteToken: _quoteToken,
            pricepointMultiplier: _pricepointMultiplier
        });

        return true;
    }

    function getPairPricepointMultiplier(
        address _baseToken,
        address _quoteToken
    ) public view returns (uint256) {
        bytes32 pairID = getPairHash(_baseToken, _quoteToken);

        return pairs[pairID].pricepointMultiplier;
    }

    function pairIsRegistered(address _baseToken, address _quoteToken)
        public
        view
        returns (bool)
    {
        bytes32 pairID = getPairHash(_baseToken, _quoteToken);
        if (pairs[pairID].pricepointMultiplier == 0) return false;

        return true;
    }

    /// @dev Sets the address of fees account.
    /// @param _rewardAccount An address to set as fees account.
    /// @return Success on setting fees account.
    function setFeeAccount(address _rewardAccount)
        public
        onlyProxyAdmin
        returns (bool)
    {
        require(_rewardAccount != address(0), "address(0) detected");
        emit LogRewardAccountUpdate(rewardAccount, _rewardAccount);
        rewardAccount = _rewardAccount;
        return true;
    }

    /// @dev Sets domain separator.
    /// @param _name Domain name.
    /// @param _version Domain version.
    /// @return Success on setting domain separator.
    function setDomainSeparator(string memory _name, string memory _version)
        public
        onlyProxyAdmin
        returns (bool)
    {
        require(
            bytes(_name).length != 0 && bytes(_version).length != 0,
            "Empty string"
        );
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(_name, _version);
        return true;
    }

    /// @dev Sets or unset's an operator.
    /// @param _operator The address of operator to set.
    /// @param _isOperator Bool value indicating whether the address is operator or not.
    /// @return Success on setting an operator.
    function setOperator(address _operator, bool _isOperator)
        public
        onlyProxyAdmin
        returns (bool)
    {
        require(_operator != address(0), "address(0) detected");
        emit LogOperatorUpdate(_operator, _isOperator);
        operators[_operator] = _isOperator;
        return true;
    }

    function executeBatchTrades(
        // uint256[10][] memory orderValues,
        // address[4][] memory orderAddresses,
        Order[] memory makerOrder,
        Order[] memory takerOrder,
        uint256[] memory amounts,
        uint8[2][] memory v,
        bytes32[4][] memory rs
    ) public onlyOperator returns (bool success) {
        // bytes[] memory makerOrderHashes = new bytes[](
        //     orderAddresses.length
        // );
        // bytes[] memory takerOrderHashes = new bytes[](
        //     orderAddresses.length
        // );

        require(makerOrder.length == takerOrder.length, "missmatch");

        bytes[] memory makerOrderHashes = new bytes[](makerOrder.length);
        bytes[] memory takerOrderHashes = new bytes[](takerOrder.length);

        // for (uint256 i = 0; i < orderAddresses.length; i++) {
        for (uint256 i = 0; i < makerOrderHashes.length; i++) {
            bool valid = validateSignatures(
                // orderValues[i],
                // orderAddresses[i],
                makerOrder[i],
                takerOrder[i],
                v[i],
                rs[i]
            );

            if (!valid) return false;

            // uint256 pricepointMultiplier = validatePair(orderAddresses[i]);
            uint256 pricepointMultiplier = validatePair(
                makerOrder[i].baseToken,
                makerOrder[i].quoteToken
            );
            (
                bytes memory makerOrderHash,
                bytes memory takerOrderHash,
                bool isTraded
            ) = executeTrade(
                    // orderValues[i],
                    // orderAddresses[i],
                    makerOrder[i],
                    takerOrder[i],
                    amounts[i],
                    pricepointMultiplier
                );

            if (isTraded) {
                makerOrderHashes[i] = makerOrderHash;
                takerOrderHashes[i] = takerOrderHash;
            }
        }

        payTakerFees(
            // orderValues[0], //takerOrder.amount
            // orderAddresses[0], //takerOrder.feeTake
            takerOrder[0],
            amounts
        );

        // emitLog(orderAddresses[0], makerOrderHashes, takerOrderHashes);
        emitLog(takerOrder[0], makerOrderHashes, takerOrderHashes);

        return true;
    }

    // function executeSingleTrade(
    //     uint256[10] memory orderValues,
    //     address[4] memory orderAddresses,
    //     uint256 amount,
    //     uint8[2] memory v,
    //     bytes32[4] memory rs
    // ) public onlyOperator returns (bool success) {
    function executeSingleTrade(
        Order memory makerOrder,
        Order memory takerOrder,
        uint256 amount,
        uint8[2] memory v,
        bytes32[4] memory rs
    ) public onlyOperator returns (bool success) {
        // bool valid = validateSignatures(orderValues, orderAddresses, v, rs);
        bool valid = validateSignatures(makerOrder, takerOrder, v, rs);

        if (!valid) return false;

        // uint256 pricepointMultiplier = validatePair(orderAddresses);
        uint256 pricepointMultiplier = validatePair(
            makerOrder.baseToken,
            makerOrder.quoteToken
        );
        // executeTrade(orderValues, orderAddresses, amount, pricepointMultiplier);
        executeTrade(makerOrder, takerOrder, amount, pricepointMultiplier);

        // paySingleTradeTakerFees(
        //     // orderValues, //takerOrder.amount
        //     // orderAddresses, //takerOrder.userAddress
        //     takerOrder,
        //     amount
        // );

        uint256[] memory _amount = new uint256[](1);
        _amount[0] = amount;
        payTakerFees(takerOrder, _amount);

        return true;
    }

    // function validatePair(address[4] memory orderAddresses)
    function validatePair(address baseToken, address quoteToken)
        internal
        view
        returns (uint256 ppm)
    {
        // bytes32 pairID = getPairHash(orderAddresses[2], orderAddresses[3]);
        bytes32 pairID = getPairHash(baseToken, quoteToken);
        Pair memory pair = pairs[pairID];

        ppm = pair.pricepointMultiplier;
    }

    // function validateSignatures(
    //     uint256[10] memory orderValues,
    //     address[4] memory orderAddresses,
    //     uint8[2] memory v,
    //     bytes32[4] memory rs
    // ) public returns (bool) {
    function validateSignatures(
        Order memory makerOrder,
        Order memory takerOrder,
        uint8[2] memory v,
        bytes32[4] memory rs
    ) public returns (bool) {
        // Order memory makerOrder = Order({
        //     userAddress: orderAddresses[0],
        //     baseToken: orderAddresses[2],
        //     quoteToken: orderAddresses[3],
        //     amount: orderValues[0],
        //     pricepoint: orderValues[1],
        //     side: orderValues[2],
        //     salt: orderValues[3],
        //     feeMake: orderValues[8],
        //     feeTake: orderValues[9]
        // });

        // Order memory takerOrder = Order({
        //     userAddress: orderAddresses[1],
        //     baseToken: orderAddresses[2],
        //     quoteToken: orderAddresses[3],
        //     amount: orderValues[4],
        //     pricepoint: orderValues[5],
        //     side: orderValues[6],
        //     salt: orderValues[7],
        //     feeTake: orderValues[8],
        //     feeMake: orderValues[9]
        // });

        bytes memory makerOrderHash = getOrderHash(makerOrder);
        bytes memory takerOrderHash = getOrderHash(takerOrder);

        if (
            !isValidSignature(
                makerOrder.userAddress,
                makerOrderHash,
                v[0],
                rs[0],
                rs[1]
            )
        ) {
            emit LogError(
                uint8(Errors.MAKER_SIGNATURE_INVALID),
                makerOrderHash,
                takerOrderHash
            );
            return false;
        }

        if (
            !isValidSignature(
                takerOrder.userAddress,
                takerOrderHash,
                v[1],
                rs[2],
                rs[3]
            )
        ) {
            emit LogError(
                uint8(Errors.TAKER_SIGNATURE_INVALID),
                makerOrderHash,
                takerOrderHash
            );
            return false;
        }

        return true;
    }

    /*
     * Core exchange functions
     */
    // function executeTrade(
    //     uint256[10] memory orderValues,
    //     address[4] memory orderAddresses,
    //     uint256 amount,
    //     uint256 pricepointMultiplier
    // )
    function executeTrade(
        Order memory makerOrder,
        Order memory takerOrder,
        uint256 amount,
        uint256 pricepointMultiplier
    )
        public
        onlyOperator
        returns (
            bytes memory,
            bytes memory,
            bool
        )
    {
        // Order memory makerOrder = Order({
        //     userAddress: orderAddresses[0],
        //     baseToken: orderAddresses[2],
        //     quoteToken: orderAddresses[3],
        //     amount: orderValues[0],
        //     pricepoint: orderValues[1],
        //     side: orderValues[2],
        //     salt: orderValues[3],
        //     feeMake: orderValues[8],
        //     feeTake: orderValues[9]
        // });

        // Order memory takerOrder = Order({
        //     userAddress: orderAddresses[1],
        //     baseToken: orderAddresses[2],
        //     quoteToken: orderAddresses[3],
        //     amount: orderValues[4],
        //     pricepoint: orderValues[5],
        //     side: orderValues[6],
        //     salt: orderValues[7],
        //     feeTake: orderValues[8],
        //     feeMake: orderValues[9]
        // });

        bytes memory makerOrderHash = getOrderHash(makerOrder);
        bytes memory takerOrderHash = getOrderHash(takerOrder);

        if ((filled[makerOrderHash].add(amount)) > makerOrder.amount) {
            emit LogError(
                uint8(Errors.TRADE_AMOUNT_TOO_BIG),
                makerOrderHash,
                takerOrderHash
            );
            return (makerOrderHash, takerOrderHash, false);
        }

        if ((filled[takerOrderHash].add(amount)) > takerOrder.amount) {
            emit LogError(
                uint8(Errors.TRADE_AMOUNT_TOO_BIG),
                makerOrderHash,
                takerOrderHash
            );
            return (makerOrderHash, takerOrderHash, false);
        }

        //TODO force side = 0 or 1
        if (takerOrder.side == makerOrder.side) {
            emit LogError(
                uint8(Errors.SIDES_INVALID),
                makerOrderHash,
                takerOrderHash
            );
            return (makerOrderHash, takerOrderHash, false);
        }

        if (makerOrder.side == 0) {
            //makerOrder is a buy
            if (makerOrder.pricepoint < takerOrder.pricepoint) {
                //buy price < sell price
                emit LogError(
                    uint8(Errors.PRICE_INVALID),
                    makerOrderHash,
                    takerOrderHash
                );
                return (makerOrderHash, takerOrderHash, false);
            }
        }

        if (makerOrder.side == 1) {
            //takerOrder is a buy
            if (takerOrder.pricepoint < makerOrder.pricepoint) {
                emit LogError(
                    uint8(Errors.PRICE_INVALID),
                    makerOrderHash,
                    takerOrderHash
                );
                return (makerOrderHash, takerOrderHash, false);
            }
        }

        filled[takerOrderHash] = (filled[takerOrderHash].add(amount));
        filled[makerOrderHash] = (filled[makerOrderHash].add(amount));

        uint256 baseTokenAmount = amount;
        uint256 quoteTokenAmount = (amount.mul(makerOrder.pricepoint)).div(
            pricepointMultiplier
        );
        uint256 fee = getPartialAmount(
            amount,
            makerOrder.amount,
            makerOrder.feeMake
        );

        if (makerOrder.side == 0) {
            // maker is buyer (stop limit)
            require(
                IERC20Upgradeable(makerOrder.quoteToken).transferFrom(
                    makerOrder.userAddress,
                    takerOrder.userAddress,
                    quoteTokenAmount
                )
            );
            require(
                IERC20Upgradeable(makerOrder.quoteToken).transferFrom(
                    makerOrder.userAddress,
                    rewardAccount,
                    fee
                )
            );
            require(
                IERC20Upgradeable(takerOrder.baseToken).transferFrom(
                    takerOrder.userAddress,
                    makerOrder.userAddress,
                    baseTokenAmount
                )
            );
        } else {
            // taker is buyer (market instant)
            require(
                IERC20Upgradeable(makerOrder.baseToken).transferFrom(
                    makerOrder.userAddress,
                    takerOrder.userAddress,
                    baseTokenAmount
                )
            );
            require(
                IERC20Upgradeable(takerOrder.quoteToken).transferFrom(
                    takerOrder.userAddress,
                    rewardAccount,
                    fee
                )
            );
            require(
                IERC20Upgradeable(takerOrder.quoteToken).transferFrom(
                    takerOrder.userAddress,
                    makerOrder.userAddress,
                    quoteTokenAmount - fee
                )
            );
        }

        return (makerOrderHash, takerOrderHash, true);
    }

    // function paySingleTradeTakerFees(
    //     // uint256[10] memory orderValues,
    //     // address[4] memory orderAddresses,
    //     Order memory takerOrder,
    //     uint256 amount
    // ) internal returns (bool success) {
    //     // uint256 takerOrderAmount = orderValues[4];
    //     // uint256 feeTake = orderValues[8];
    //     // address userAddress = orderAddresses[1];
    //     // address quoteToken = orderAddresses[3];

    //     uint256 takerOrderAmount = takerOrder.amount;
    //     uint256 feeTake = takerOrder.feeTake;
    //     address userAddress = takerOrder.userAddress;
    //     address quoteToken = takerOrder.quoteToken;

    //     uint256 fee = getPartialAmount(amount, takerOrderAmount, feeTake);
    //     require(
    //         IERC20Upgradeable(quoteToken).transferFrom(
    //             userAddress,
    //             rewardAccount,
    //             fee
    //         )
    //     );

    //     return true;
    // }

    function payTakerFees(
        // uint256[10] memory orderValues,
        // address[4] memory orderAddresses,
        Order memory takerOrder,
        uint256[] memory amounts
    ) internal returns (bool success) {
        // uint256 takerOrderAmount = orderValues[4];
        // uint256 feeTake = orderValues[8];
        // address userAddress = orderAddresses[1];
        // address quoteToken = orderAddresses[3];

        uint256 takerOrderAmount = takerOrder.amount;
        uint256 feeTake = takerOrder.feeTake;
        address userAddress = takerOrder.userAddress;
        address quoteToken = takerOrder.quoteToken;

        uint256 totalAmount;
        for (uint256 i = 0; i < amounts.length; i++) {
            // totalAmount = totalAmount + amounts[i];
            totalAmount += amounts[i];
        }

        uint256 fee = getPartialAmount(totalAmount, takerOrderAmount, feeTake);
        require(
            IERC20Upgradeable(quoteToken).transferFrom(
                userAddress,
                rewardAccount,
                fee
            )
        );

        return true;
    }

    function batchCancelOrders(
        uint256[6][] memory orderValues,
        address[3][] memory orderAddresses,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public {
        for (uint256 i = 0; i < orderAddresses.length; i++) {
            cancelOrder(orderValues[i], orderAddresses[i], v[i], r[i], s[i]);
        }
    }

    /// @dev Cancels the input order.
    /// @param orderValues Array of order's amountBuy, amountSell, expires, nonce, feeMake & feeTake values.
    /// @param orderAddresses Array of order's tokenBuy, tokenSell & maker addresses.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @return Success or failure of order cancellation.
    function cancelOrder(
        uint256[6] memory orderValues,
        address[3] memory orderAddresses,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        Order memory order = Order({
            userAddress: orderAddresses[0],
            baseToken: orderAddresses[1],
            quoteToken: orderAddresses[2],
            amount: orderValues[0],
            pricepoint: orderValues[1],
            side: orderValues[2],
            salt: orderValues[3],
            feeTake: orderValues[4],
            feeMake: orderValues[5]
        });

        bytes memory orderHash = getOrderHash(order);

        if (!isValidSignature(msg.sender, orderHash, v, r, s)) {
            emit LogError(uint8(Errors.SIGNATURE_INVALID), orderHash, "");
            return false;
        }

        filled[orderHash] = order.amount;
        emit LogCancelOrder(
            orderHash,
            order.userAddress,
            order.baseToken,
            order.quoteToken,
            order.amount,
            order.pricepoint,
            order.side
        );

        return true;
    }

    /*
     * Pure public functions
     */

    /// @dev Verifies that a signature is valid.
    /// @param signer address of signer.
    /// @param hashData Signed Keccak-256 hash.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @return Validity of order signature.
    function isValidSignature(
        address signer,
        bytes memory hashData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        return signer == EIP712.recover(DOMAIN_SEPARATOR, v, r, s, hashData);
    }

    /// @dev Checks if rounding error > 0.1%.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) public pure returns (bool) {
        uint256 remainder = mulmod(target, numerator, denominator);
        if (remainder == 0) return false;
        // No rounding error.

        uint256 errPercentageTimes1000000 = (remainder.mul(1000000)).div(
            numerator.mul(target)
        );
        return errPercentageTimes1000000 > 1000;
    }

    /// @dev Calculates partial value given a numerator and denominator.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target.
    function getPartialAmount(
        uint256 numerator, // amount
        uint256 denominator, // maker/taker amount
        uint256 target // fee
    ) public pure returns (uint256) {
        return (numerator.mul(target)).div(denominator);
    }

    /*
     *   Internal functions
     */

    function getPairHash(address _baseToken, address _quoteToken)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_baseToken, _quoteToken));
    }

    /// @dev Encode order.
    /// @param order Order that will be hased.
    /// @return Keccak-256 hash of order.
    function getOrderHash(Order memory order)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                ORDER_TYPEHASH,
                order.userAddress,
                order.baseToken,
                order.quoteToken,
                order.amount,
                order.pricepoint,
                order.side,
                order.salt,
                order.feeMake,
                order.feeTake
            );
    }

    function emitLog(
        // address[4] memory orderAddresses,
        Order memory takerOrder,
        bytes[] memory makerOrderHashes,
        bytes[] memory takerOrderHashes
    ) public {
        emit LogBatchTrades(
            makerOrderHashes,
            takerOrderHashes,
            // keccak256(abi.encodePacked(orderAddresses[1], orderAddresses[2]))
            getPairHash(takerOrder.baseToken, takerOrder.quoteToken)
        );
    }
}

// if (isRoundingError(trade.amount, order.amountBuy, order.amountSell)) {
//             emit LogError(uint8(Errors.ROUNDING_ERROR_TOO_LARGE), orderHash, tradeHash);
//             return (orderHash, tradeHash, 0);
//         }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}