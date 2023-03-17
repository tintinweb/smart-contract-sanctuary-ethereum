// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TransferHelperUtils} from "../utils/TransferHelperUtils.sol";
import {IMintFeeManager} from "../interfaces/IMintFeeManager.sol";

/// @title MintFeeManager
/// @notice Manages mint fees for an 1155 contract
contract MintFeeManager is IMintFeeManager {
    uint256 public immutable mintFee;
    address public immutable mintFeeRecipient;

    constructor(uint256 _mintFee, address _mintFeeRecipient) {
        // Set fixed finders fee
        if (_mintFee >= 0.1 ether) {
            revert MintFeeCannotBeMoreThanZeroPointOneETH(_mintFee);
        }
        if (_mintFeeRecipient == address(0) && _mintFee > 0) {
            revert CannotSetMintFeeToZeroAddress();
        }
        mintFeeRecipient = _mintFeeRecipient;
        mintFee = _mintFee;
    }

    /// @notice Sends the mint fee to the mint fee recipient and returns the amount of ETH remaining that can be used in this transaction
    /// @param _quantity The amount of toknens being minted
    function _handleFeeAndGetValueSent(uint256 _quantity) internal returns (uint256 ethValueSent) {
        ethValueSent = msg.value;

        // Handle mint fee
        if (mintFeeRecipient != address(0)) {
            uint256 totalFee = mintFee * _quantity;
            ethValueSent -= totalFee;
            if (!TransferHelperUtils.safeSendETHLowLimit(mintFeeRecipient, totalFee)) {
                revert CannotSendMintFee(mintFeeRecipient, totalFee);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Creator Commands used by minter modules passed back to the main modules
interface ICreatorCommands {
    /// @notice This enum is used to define supported creator action types.
    /// This can change in the future
    enum CreatorActions {
        // No operation - also the default for mintings that may not return a command
        NO_OP,
        // Send ether
        SEND_ETH,
        // Mint operation
        MINT
    }

    /// @notice This command is for
    struct Command {
        // Method for operation
        CreatorActions method;
        // Arguments used for this operation
        bytes args;
    }

    /// @notice This command set is returned from the minter back to the user
    struct CommandSet {
        Command[] commands;
        uint256 at;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Generic control interface for bit-based permissions-control
interface ICreatorPermissionControl {
    /// @notice Emitted when permissions are updated
    event UpdatedPermissions(uint256 indexed tokenId, address indexed user, uint256 indexed permissions);

    /// @notice Public interface to get permissions given a token id and a user address
    /// @return Returns raw permission bits
    function getPermissions(uint256 tokenId, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IRenderer1155} from "./IRenderer1155.sol";

/// @notice Interface for creator renderer controls
interface ICreatorRendererControl {
    /// @notice Get the custom renderer contract (if any) for the given token id
    /// @dev Reverts if not custom renderer is set for this token
    function getCustomRenderer(uint256 tokenId) external view returns (IRenderer1155 renderer);

    error NoRendererForToken(uint256 tokenId);
    error RendererNotValid(address renderer);
    event RendererUpdated(uint256 indexed tokenId, address indexed renderer, address indexed user);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface ICreatorRoyaltiesControl is IERC2981 {
    /// @notice The RoyaltyConfiguration struct is used to store the royalty configuration for a given token.
    /// @param royaltyMintSchedule Every nth token will go to the royalty recipient.
    /// @param royaltyBPS The royalty amount in basis points for secondary sales.
    /// @param royaltyRecipient The address that will receive the royalty payments.
    struct RoyaltyConfiguration {
        uint32 royaltyMintSchedule;
        uint32 royaltyBPS;
        address royaltyRecipient;
    }

    /// @notice Thrown when a user tries to have 100% supply royalties
    error InvalidMintSchedule();

    /// @notice Event emitted when royalties are updated
    event UpdatedRoyalties(uint256 indexed tokenId, address indexed user, RoyaltyConfiguration configuration);

    /// @notice External data getter to get royalties for a token
    /// @param tokenId tokenId to get royalties configuration for
    function getRoyalties(uint256 tokenId) external view returns (RoyaltyConfiguration memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILegacyNaming {
    function name() external returns (string memory);

    function symbol() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMintFeeManager {
    error MintFeeCannotBeMoreThanZeroPointOneETH(uint256 mintFeeBPS);
    error CannotSendMintFee(address mintFeeRecipient, uint256 mintFee);
    error CannotSetMintFeeToZeroAddress();

    function mintFee() external view returns (uint256);

    function mintFeeRecipient() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {ICreatorCommands} from "./ICreatorCommands.sol";

/// @notice Minter standard interface
/// @dev Minters need to confirm to the ERC165 selector of type(IMinter1155).interfaceId
interface IMinter1155 is IERC165Upgradeable {
    function requestMint(
        address sender,
        uint256 tokenId,
        uint256 quantity,
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOwnable {
    function owner() external returns (address);

    event OwnershipTransferred(address lastOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

/// @dev IERC165 type required
interface IRenderer1155 is IERC165Upgradeable {
    /// @notice Called for assigned tokenId, or when token id is globally set to a renderer
    /// @dev contract target is assumed to be msg.sender
    /// @param tokenId token id to get uri for
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Only called for tokenId == 0
    /// @dev contract target is assumed to be msg.sender
    function contractURI() external view returns (string memory);

    /// @notice Sets up renderer from contract
    /// @param initData data to setup renderer with
    /// @dev contract target is assumed to be msg.sender
    function setup(bytes memory initData) external;

    // IERC165 type required – set in base helper
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

interface ITransferHookReceiver is IERC165Upgradeable {
    /// @notice Token transfer batch callback
    /// @param target target contract for transfer
    /// @param operator operator address for transfer
    /// @param from user address for amount transferred
    /// @param to user address for amount transferred
    /// @param ids list of token ids transferred
    /// @param amounts list of values transferred
    /// @param data data as perscribed by 1155 standard
    function onTokenTransferBatch(
        address target,
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    // IERC165 type required
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVersionedContract {
    function contractVersion() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {IERC1155MetadataURIUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC1155MetadataURIUpgradeable.sol";
import {IZoraCreator1155TypesV1} from "../nft/IZoraCreator1155TypesV1.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {IVersionedContract} from "./IVersionedContract.sol";
import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,

 */

/// @notice Main interface for the ZoraCreator1155 contract
/// @author @iainnash / @tbtstl
interface IZoraCreator1155 is IZoraCreator1155TypesV1, IVersionedContract, IOwnable, IERC1155MetadataURIUpgradeable {
    function PERMISSION_BIT_ADMIN() external returns (uint256);

    function PERMISSION_BIT_MINTER() external returns (uint256);

    function PERMISSION_BIT_SALES() external returns (uint256);

    function PERMISSION_BIT_METADATA() external returns (uint256);

    /// @notice Used to label the configuration update type
    enum ConfigUpdate {
        OWNER,
        FUNDS_RECIPIENT,
        TRANSFER_HOOK
    }
    event ConfigUpdated(address indexed updater, ConfigUpdate indexed updateType, ContractConfig newConfig);

    event UpdatedToken(address indexed from, uint256 indexed tokenId, TokenData tokenData);
    event SetupNewToken(uint256 indexed tokenId, address indexed sender, string newURI, uint256 maxSupply);

    function setOwner(address newOwner) external;

    event ContractRendererUpdated(IRenderer1155 renderer);
    event ContractMetadataUpdated(address indexed updater, string uri, string name);
    event Purchased(address indexed sender, address indexed minter, uint256 indexed tokenId, uint256 quantity, uint256 value);

    error TokenIdMismatch(uint256 expected, uint256 actual);
    error NotAllowedContractBaseIDUpdate();
    error UserMissingRoleForToken(address user, uint256 tokenId, uint256 role);

    error Config_TransferHookNotSupported(address proposedAddress);

    error Mint_InsolventSaleTransfer();
    error Mint_ValueTransferFail();
    error Mint_TokenIDMintNotAllowed();
    error Mint_UnknownCommand();

    error Burn_NotOwnerOrApproved(address operator, address user);

    error NewOwnerNeedsToBeAdmin();

    error Sale_CannotCallNonSalesContract(address targetContract);
    error Sale_CallFailed();

    error Renderer_CallFailed(bytes reason);
    error Renderer_NotValidRendererContract();

    error ETHWithdrawFailed(address recipient, uint256 amount);
    error FundsWithdrawInsolvent(uint256 amount, uint256 contractValue);

    error CannotMintMoreTokens(uint256 tokenId, uint256 quantity, uint256 totalMinted, uint256 maxSupply);

    function initialize(
        string memory newContractURI,
        ICreatorRoyaltiesControl.RoyaltyConfiguration memory defaultRoyaltyConfiguration,
        address payable defaultAdmin,
        bytes[] calldata setupActions
    ) external;

    /// @notice Only allow minting one token id at time
    /// @dev Mint contract function that calls the underlying sales function for commands
    /// @param minter Address for the minter
    /// @param tokenId tokenId to mint, set to 0 for new tokenId
    /// @param quantity to mint
    /// @param minterArguments calldata for the minter contracts
    function mint(IMinter1155 minter, uint256 tokenId, uint256 quantity, bytes calldata minterArguments) external payable;

    function adminMint(address recipient, uint256 tokenId, uint256 quantity, bytes memory data) external;

    function adminMintBatch(address recipient, uint256[] memory tokenIds, uint256[] memory quantities, bytes memory data) external;

    function burnBatch(address user, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /// @notice Contract call to setupNewToken
    /// @param tokenURI URI for the token
    /// @param maxSupply maxSupply for the token, set to 0 for open edition
    function setupNewToken(string memory tokenURI, uint256 maxSupply) external returns (uint256 tokenId);

    function updateTokenURI(uint256 tokenId, string memory _newURI) external;

    function updateContractMetadata(string memory _newURI, string memory _newName) external;

    function setTokenMetadataRenderer(uint256 tokenId, IRenderer1155 renderer, bytes calldata setupData) external;

    function contractURI() external view returns (string memory);

    function assumeLastTokenIdMatches(uint256 tokenId) external;

    function updateRoyaltiesForToken(uint256 tokenId, ICreatorRoyaltiesControl.RoyaltyConfiguration memory royaltyConfiguration) external;

    function addPermission(uint256 tokenId, address user, uint256 permissionBits) external;

    function removePermission(uint256 tokenId, address user, uint256 permissionBits) external;

    function isAdminOrRole(address user, uint256 tokenId, uint256 role) external view returns (bool);

    function getTokenInfo(uint256 tokenId) external view returns (TokenData memory);

    function callRenderer(uint256 tokenId, bytes memory data) external;

    function callSale(uint256 tokenId, IMinter1155 salesConfig, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILegacyNaming} from "../interfaces/ILegacyNaming.sol";
import {LegacyNamingStorageV1} from "./LegacyNamingStorageV1.sol";

/// @title LegacyNamingControl
/// @notice Contract for managing the name and symbol of an 1155 contract in the legacy naming scheme
contract LegacyNamingControl is LegacyNamingStorageV1, ILegacyNaming {
    /// @notice The name of the contract
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice The token symbol of the contract
    function symbol() external pure returns (string memory) {}

    function _setName(string memory _newName) internal {
        _name = _newName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract LegacyNamingStorageV1 {
    string internal _name;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITransferHookReceiver} from "../interfaces/ITransferHookReceiver.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,


    github.com/ourzora/zora-1155-contracts

 */

/// @notice Interface for types used across the ZoraCreator1155 contract
/// @author @iainnash / @tbtstl
interface IZoraCreator1155TypesV1 {
    /// @notice Used to store individual token data
    struct TokenData {
        string uri;
        uint256 maxSupply;
        uint256 totalMinted;
    }

    /// @notice Used to store contract-level configuration
    struct ContractConfig {
        address owner;
        uint96 __gap1;
        address payable fundsRecipient;
        uint96 __gap2;
        ITransferHookReceiver transferHook;
        uint96 __gap3;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {IERC1155MetadataURIUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC1155MetadataURIUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {IZoraCreator1155} from "../interfaces/IZoraCreator1155.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {ContractVersionBase} from "../version/ContractVersionBase.sol";
import {CreatorPermissionControl} from "../permissions/CreatorPermissionControl.sol";
import {CreatorRendererControl} from "../renderer/CreatorRendererControl.sol";
import {CreatorRoyaltiesControl} from "../royalties/CreatorRoyaltiesControl.sol";
import {ICreatorCommands} from "../interfaces/ICreatorCommands.sol";
import {IMinter1155} from "../interfaces/IMinter1155.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";
import {ITransferHookReceiver} from "../interfaces/ITransferHookReceiver.sol";
import {IZoraCreator1155} from "../interfaces/IZoraCreator1155.sol";
import {LegacyNamingControl} from "../legacy-naming/LegacyNamingControl.sol";
import {MintFeeManager} from "../fee/MintFeeManager.sol";
import {PublicMulticall} from "../utils/PublicMulticall.sol";
import {SharedBaseConstants} from "../shared/SharedBaseConstants.sol";
import {TransferHelperUtils} from "../utils/TransferHelperUtils.sol";
import {ZoraCreator1155StorageV1} from "./ZoraCreator1155StorageV1.sol";

/// @title ZoraCreator1155Impl
/// @notice The core implementation contract for a creator's 1155 token
/// @author @iainnash / @tbtstl
contract ZoraCreator1155Impl is
    IZoraCreator1155,
    ContractVersionBase,
    ReentrancyGuardUpgradeable,
    PublicMulticall,
    ERC1155Upgradeable,
    MintFeeManager,
    UUPSUpgradeable,
    CreatorRendererControl,
    LegacyNamingControl,
    ZoraCreator1155StorageV1,
    CreatorPermissionControl,
    CreatorRoyaltiesControl
{
    /// @notice This user role allows for any action to be performed
    uint256 public immutable PERMISSION_BIT_ADMIN = 2 ** 1;
    /// @notice This user role allows for only mint actions to be performed
    uint256 public immutable PERMISSION_BIT_MINTER = 2 ** 2;

    /// @notice This user role allows for only managing sales configurations
    uint256 public immutable PERMISSION_BIT_SALES = 2 ** 3;
    /// @notice This user role allows for only managing metadata configuration
    uint256 public immutable PERMISSION_BIT_METADATA = 2 ** 4;
    /// @notice This user role allows for only withdrawing funds and setting funds withdraw address
    uint256 public immutable PERMISSION_BIT_FUNDS_MANAGER = 2 ** 5;

    constructor(uint256 _mintFeeAmount, address _mintFeeRecipient) MintFeeManager(_mintFeeAmount, _mintFeeRecipient) initializer {}

    /// @notice Initializes the contract
    /// @param newContractURI The contract URI
    /// @param defaultRoyaltyConfiguration The default royalty configuration
    /// @param defaultAdmin The default admin to manage the token
    /// @param setupActions The setup actions to run, if any
    function initialize(
        string memory newContractURI,
        RoyaltyConfiguration memory defaultRoyaltyConfiguration,
        address payable defaultAdmin,
        bytes[] calldata setupActions
    ) external nonReentrant initializer {
        // We are not initalizing the OZ 1155 implementation
        // to save contract storage space and runtime
        // since the only thing affected here is the uri.
        // __ERC1155_init("");

        // Setup uups
        __UUPSUpgradeable_init();

        // Setup re-entracy guard
        __ReentrancyGuard_init();

        // Setup contract-default token ID
        _setupDefaultToken(defaultAdmin, newContractURI, defaultRoyaltyConfiguration);

        // Set owner to default admin
        _setOwner(defaultAdmin);

        _setFundsRecipient(defaultAdmin);

        // Run Setup actions
        if (setupActions.length > 0) {
            // Temporarily make sender admin
            _addPermission(CONTRACT_BASE_ID, msg.sender, PERMISSION_BIT_ADMIN);

            // Make calls
            multicall(setupActions);

            // Remove admin
            _removePermission(CONTRACT_BASE_ID, msg.sender, PERMISSION_BIT_ADMIN);
        }
    }

    /// @notice sets up the global configuration for the 1155 contract
    /// @param newContractURI The contract URI
    /// @param defaultRoyaltyConfiguration The default royalty configuration
    function _setupDefaultToken(address defaultAdmin, string memory newContractURI, RoyaltyConfiguration memory defaultRoyaltyConfiguration) internal {
        // Add admin permission to default admin to manage contract
        _addPermission(CONTRACT_BASE_ID, defaultAdmin, PERMISSION_BIT_ADMIN);

        // Mint token ID 0 / don't allow any user mints
        _setupNewToken(newContractURI, 0);

        // Update default royalties
        _updateRoyalties(CONTRACT_BASE_ID, defaultRoyaltyConfiguration);
    }

    /// @notice Updates the royalty configuration for a token
    /// @param tokenId The token ID to update
    /// @param newConfiguration The new royalty configuration
    function updateRoyaltiesForToken(
        uint256 tokenId,
        RoyaltyConfiguration memory newConfiguration
    ) external onlyAdminOrRole(tokenId, PERMISSION_BIT_FUNDS_MANAGER) {
        _updateRoyalties(tokenId, newConfiguration);
    }

    /// @notice remove this function from openzeppelin impl
    /// @dev This makes this internal function a no-op
    function _setURI(string memory newuri) internal virtual override {}

    /// @notice This gets the next token in line to be minted when minting linearly (default behavior) and updates the counter
    function _getAndUpdateNextTokenId() internal returns (uint256) {
        unchecked {
            return nextTokenId++;
        }
    }

    /// @notice Ensure that the next token ID is correct
    /// @dev This reverts if the invariant doesn't match. This is used for multicall token id assumptions
    /// @param lastTokenId The last token ID
    function assumeLastTokenIdMatches(uint256 lastTokenId) external view {
        unchecked {
            if (nextTokenId - 1 != lastTokenId) {
                revert TokenIdMismatch(lastTokenId, nextTokenId - 1);
            }
        }
    }

    /// @notice Checks if a user either has a role for a token or if they are the admin
    /// @dev This is an internal function that is called by the external getter and internal functions
    /// @param user The user to check
    /// @param tokenId The token ID to check
    /// @param role The role to check
    /// @return true or false if the permission exists for the user given the token id
    function _isAdminOrRole(address user, uint256 tokenId, uint256 role) internal view returns (bool) {
        return _hasAnyPermission(tokenId, user, PERMISSION_BIT_ADMIN | role);
    }

    /// @notice Checks if a user either has a role for a token or if they are the admin
    /// @param user The user to check
    /// @param tokenId The token ID to check
    /// @param role The role to check
    /// @return true or false if the permission exists for the user given the token id
    function isAdminOrRole(address user, uint256 tokenId, uint256 role) external view returns (bool) {
        return _isAdminOrRole(user, tokenId, role);
    }

    /// @notice Checks if the user is an admin for the given tokenId
    /// @dev This function reverts if the permission does not exist for the given user and tokenId
    /// @param user user to check
    /// @param tokenId tokenId to check
    /// @param role role to check for admin
    function _requireAdminOrRole(address user, uint256 tokenId, uint256 role) internal view {
        if (!(_hasAnyPermission(tokenId, user, PERMISSION_BIT_ADMIN | role) || _hasAnyPermission(CONTRACT_BASE_ID, user, PERMISSION_BIT_ADMIN))) {
            revert UserMissingRoleForToken(user, tokenId, role);
        }
    }

    /// @notice Checks if the user is an admin
    /// @dev This reverts if the user is not an admin for the given token id or contract
    /// @param user user to check
    /// @param tokenId tokenId to check
    function _requireAdmin(address user, uint256 tokenId) internal view {
        if (!(_hasAnyPermission(tokenId, user, PERMISSION_BIT_ADMIN) || _hasAnyPermission(CONTRACT_BASE_ID, user, PERMISSION_BIT_ADMIN))) {
            revert UserMissingRoleForToken(user, tokenId, PERMISSION_BIT_ADMIN);
        }
    }

    /// @notice Modifier checking if the user is an admin or has a role
    /// @dev This reverts if the msg.sender is not an admin for the given token id or contract
    /// @param tokenId tokenId to check
    /// @param role role to check
    modifier onlyAdminOrRole(uint256 tokenId, uint256 role) {
        _requireAdminOrRole(msg.sender, tokenId, role);
        _;
    }

    /// @notice Modifier checking if the user is an admin
    /// @dev This reverts if the msg.sender is not an admin for the given token id or contract
    /// @param tokenId tokenId to check
    modifier onlyAdmin(uint256 tokenId) {
        _requireAdmin(msg.sender, tokenId);
        _;
    }

    /// @notice Modifier checking if the requested quantity of tokens can be minted for the tokenId
    /// @dev This reverts if the number that can be minted is exceeded
    /// @param tokenId token id to check available allowed quantity
    /// @param quantity requested to be minted
    modifier canMintQuantity(uint256 tokenId, uint256 quantity) {
        _requireCanMintQuantity(tokenId, quantity);
        _;
    }

    /// @notice Only from approved address for burn
    /// @param from address that the tokens will be burned from, validate that this is msg.sender or that msg.sender is approved
    modifier onlyFromApprovedForBurn(address from) {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert Burn_NotOwnerOrApproved(msg.sender, from);
        }

        _;
    }

    /// @notice Checks if a user can mint a quantity of a token
    /// @dev Reverts if the mint exceeds the allowed quantity (or if the token does not exist)
    /// @param tokenId The token ID to check
    /// @param quantity The quantity of tokens to mint to check
    function _requireCanMintQuantity(uint256 tokenId, uint256 quantity) internal view {
        TokenData memory tokenInformation = tokens[tokenId];
        if (tokenInformation.totalMinted + quantity > tokenInformation.maxSupply) {
            revert CannotMintMoreTokens(tokenId, quantity, tokenInformation.totalMinted, tokenInformation.maxSupply);
        }
    }

    /// @notice Set up a new token
    /// @param newURI The URI for the token (underscore since `uri()` is reserved by OpenZeppelin)
    /// @param maxSupply The maximum supply of the token
    function setupNewToken(
        string memory newURI,
        uint256 maxSupply
    ) public onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_MINTER) nonReentrant returns (uint256) {
        // TODO(iain): isMaxSupply = 0 open edition or maybe uint256(max) - 1
        //                                                  0xffffffff -> 2**8*4 4.2bil
        //                                                  0xf0000000 -> 2**8*4-(8*3)

        uint256 tokenId = _setupNewToken(newURI, maxSupply);
        // Allow the token creator to administrate this token
        _addPermission(tokenId, msg.sender, PERMISSION_BIT_ADMIN);
        if (bytes(newURI).length > 0) {
            emit URI(newURI, tokenId);
        }

        emit SetupNewToken(tokenId, msg.sender, newURI, maxSupply);

        return tokenId;
    }

    /// @notice Update the token URI for a token
    /// @param tokenId The token ID to update the URI for
    /// @param _newURI The new URI
    function updateTokenURI(uint256 tokenId, string memory _newURI) external onlyAdminOrRole(tokenId, PERMISSION_BIT_METADATA) {
        if (tokenId == CONTRACT_BASE_ID) {
            revert NotAllowedContractBaseIDUpdate();
        }
        emit URI(_newURI, tokenId);
        tokens[tokenId].uri = _newURI;
    }

    /// @notice Update the global contract metadata
    /// @param _newURI The new contract URI
    /// @param _newName The new contract name
    function updateContractMetadata(string memory _newURI, string memory _newName) external onlyAdminOrRole(0, PERMISSION_BIT_METADATA) {
        tokens[CONTRACT_BASE_ID].uri = _newURI;
        _setName(_newName);
        emit ContractMetadataUpdated(msg.sender, _newURI, _newName);
    }

    function _setupNewToken(string memory newURI, uint256 maxSupply) internal returns (uint256 tokenId) {
        tokenId = _getAndUpdateNextTokenId();
        TokenData memory tokenData = TokenData({uri: newURI, maxSupply: maxSupply, totalMinted: 0});
        tokens[tokenId] = tokenData;
        emit UpdatedToken(msg.sender, tokenId, tokenData);
    }

    /// @notice Add a role to a user for a token
    /// @param tokenId The token ID to add the role to
    /// @param user The user to add the role to
    /// @param permissionBits The permission bit to add
    function addPermission(uint256 tokenId, address user, uint256 permissionBits) external onlyAdmin(tokenId) {
        _addPermission(tokenId, user, permissionBits);
    }

    /// @notice Remove a role from a user for a token
    /// @param tokenId The token ID to remove the role from
    /// @param user The user to remove the role from
    /// @param permissionBits The permission bit to remove
    function removePermission(uint256 tokenId, address user, uint256 permissionBits) external onlyAdmin(tokenId) {
        _removePermission(tokenId, user, permissionBits);

        // Clear owner field
        if (tokenId == CONTRACT_BASE_ID && user == config.owner && !_hasAnyPermission(CONTRACT_BASE_ID, user, PERMISSION_BIT_ADMIN)) {
            _setOwner(address(0));
        }
    }

    /// @notice Set the owner of the contract
    /// @param newOwner The new owner of the contract
    function setOwner(address newOwner) external onlyAdmin(CONTRACT_BASE_ID) {
        if (!_hasAnyPermission(CONTRACT_BASE_ID, newOwner, PERMISSION_BIT_ADMIN)) {
            revert NewOwnerNeedsToBeAdmin();
        }

        // Update owner field
        _setOwner(newOwner);
    }

    /// @notice Getter for the owner singleton of the contract for outside interfaces
    /// @return the owner of the contract singleton for compat.
    function owner() external view returns (address) {
        return config.owner;
    }

    /// @notice AdminMint that only checks if the requested quantity can be minted and has a re-entrant guard
    /// @param recipient recipient for admin minted tokens
    /// @param tokenId token id to mint
    /// @param quantity quantity to mint
    /// @param data callback data as specified by the 1155 spec
    function _adminMint(address recipient, uint256 tokenId, uint256 quantity, bytes memory data) internal {
        _mint(recipient, tokenId, quantity, data);
    }

    /// @notice Mint a token to a user as the admin or minter
    /// @param recipient The recipient of the token
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param data The data to pass to the onERC1155Received function
    function adminMint(
        address recipient,
        uint256 tokenId,
        uint256 quantity,
        bytes memory data
    ) external nonReentrant onlyAdminOrRole(tokenId, PERMISSION_BIT_MINTER) {
        // Call internal admin mint
        _adminMint(recipient, tokenId, quantity, data);
    }

    /// @notice Batch mint tokens to a user as the admin or minter
    /// @param recipient The recipient of the tokens
    /// @param tokenIds The token IDs to mint
    /// @param quantities The quantities of tokens to mint
    /// @param data The data to pass to the onERC1155BatchReceived function
    function adminMintBatch(address recipient, uint256[] memory tokenIds, uint256[] memory quantities, bytes memory data) external nonReentrant {
        bool isGlobalAdminOrMinter = _isAdminOrRole(msg.sender, CONTRACT_BASE_ID, PERMISSION_BIT_MINTER);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (!isGlobalAdminOrMinter) {
                _requireAdminOrRole(msg.sender, tokenIds[i], PERMISSION_BIT_MINTER);
            }
        }
        _mintBatch(recipient, tokenIds, quantities, data);
    }

    /// @notice Mint tokens given a minter contract and minter arguments
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param minterArguments The arguments to pass to the minter
    function mint(IMinter1155 minter, uint256 tokenId, uint256 quantity, bytes calldata minterArguments) external payable nonReentrant {
        // Require admin from the minter to mint
        _requireAdminOrRole(address(minter), tokenId, PERMISSION_BIT_MINTER);

        // Get value sent and handle mint fee
        uint256 ethValueSent = _handleFeeAndGetValueSent(quantity);

        // Execute commands returned from minter
        _executeCommands(minter.requestMint(address(this), tokenId, quantity, ethValueSent, minterArguments).commands, ethValueSent, tokenId);

        emit Purchased(msg.sender, address(minter), tokenId, quantity, msg.value);
    }

    /// @notice Set a metadata renderer for a token
    /// @param tokenId The token ID to set the renderer for
    /// @param renderer The renderer to set
    /// @param setupData The data to pass to the renderer upon intialization
    function setTokenMetadataRenderer(
        uint256 tokenId,
        IRenderer1155 renderer,
        bytes calldata setupData
    ) external nonReentrant onlyAdminOrRole(tokenId, PERMISSION_BIT_METADATA) {
        _setRenderer(tokenId, renderer, setupData);

        if (tokenId == 0) {
            emit ContractRendererUpdated(renderer);
        } else {
            // We don't know the uri from the renderer but can emit a notification to the indexer here
            emit URI("", tokenId);
        }
    }

    /// Execute Minter Commands ///

    /// @notice Internal functions to execute commands returned by the minter
    /// @param commands list of command structs
    /// @param ethValueSent the ethereum value sent in the mint transaction into the contract
    /// @param tokenId the token id the user requested to mint (0 if the token id is set by the minter itself across the whole contract)
    function _executeCommands(ICreatorCommands.Command[] memory commands, uint256 ethValueSent, uint256 tokenId) internal {
        for (uint256 i = 0; i < commands.length; ++i) {
            ICreatorCommands.CreatorActions method = commands[i].method;
            if (method == ICreatorCommands.CreatorActions.SEND_ETH) {
                (address recipient, uint256 amount) = abi.decode(commands[i].args, (address, uint256));
                if (ethValueSent > amount) {
                    revert Mint_InsolventSaleTransfer();
                }
                if (!TransferHelperUtils.safeSendETH(recipient, amount)) {
                    revert Mint_ValueTransferFail();
                }
            } else if (method == ICreatorCommands.CreatorActions.MINT) {
                (address recipient, uint256 mintTokenId, uint256 quantity) = abi.decode(commands[i].args, (address, uint256, uint256));
                if (tokenId != 0 && mintTokenId != tokenId) {
                    revert Mint_TokenIDMintNotAllowed();
                }
                _adminMint(recipient, tokenId, quantity, "");
            } else if (method == ICreatorCommands.CreatorActions.NO_OP) {
                // no-op
            } else {
                revert Mint_UnknownCommand();
            }
        }
    }

    /// @notice Token info getter
    /// @param tokenId token id to get info for
    /// @return TokenData struct returned
    function getTokenInfo(uint256 tokenId) external view returns (TokenData memory) {
        return tokens[tokenId];
    }

    /// @notice Proxy setter for sale contracts (only callable by SALES permission or admin)
    /// @param tokenId The token ID to call the sale contract with
    /// @param salesConfig The sales config contract to call
    /// @param data The data to pass to the sales config contract
    function callSale(uint256 tokenId, IMinter1155 salesConfig, bytes memory data) external onlyAdminOrRole(tokenId, PERMISSION_BIT_SALES) {
        _requireAdminOrRole(address(salesConfig), tokenId, PERMISSION_BIT_MINTER);
        if (!salesConfig.supportsInterface(type(IMinter1155).interfaceId)) {
            revert Sale_CannotCallNonSalesContract(address(salesConfig));
        }
        (bool success, ) = address(salesConfig).call(data);
        if (!success) {
            revert Sale_CallFailed();
        }
    }

    /// @notice Proxy setter for renderer contracts (only callable by METADATA permission or admin)
    /// @param tokenId The token ID to call the renderer contract with
    /// @param data The data to pass to the renderer contract
    function callRenderer(uint256 tokenId, bytes memory data) external onlyAdminOrRole(tokenId, PERMISSION_BIT_METADATA) {
        // We assume any renderers set are checked for EIP165 signature during write stage.
        (bool success, bytes memory why) = address(getCustomRenderer(tokenId)).call(data);
        if (!success) {
            revert Renderer_CallFailed(why);
        }
    }

    /// @notice Returns true if the contract implements the interface defined by interfaceId
    /// @param interfaceId The interface to check for
    /// @return if the interfaceId is marked as supported
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(CreatorRoyaltiesControl, ERC1155Upgradeable, IERC165Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IZoraCreator1155).interfaceId;
    }

    /// Generic 1155 function overrides ///

    /// @notice Mint function that 1) checks quantity and 2) handles supply royalty 3) keeps track of allowed tokens
    /// @param to to mint to
    /// @param id token id to mint
    /// @param amount of tokens to mint
    /// @param data as specified by 1155 standard
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        (address supplyRoyaltyRecipient, uint256 supplyRoyaltyAmount) = supplyRoyaltyInfo(id, tokens[id].totalMinted, amount);

        _requireCanMintQuantity(id, amount + supplyRoyaltyAmount);

        super._mint(to, id, amount, data);
        if (supplyRoyaltyAmount > 0) {
            super._mint(supplyRoyaltyRecipient, id, supplyRoyaltyAmount, data);
        }
        tokens[id].totalMinted += amount + supplyRoyaltyAmount;
    }

    /// @notice Mint batch function that 1) checks quantity and 2) handles supply royalty 3) keeps track of allowed tokens
    /// @param to to mint to
    /// @param ids token ids to mint
    /// @param amounts of tokens to mint
    /// @param data as specified by 1155 standard
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._mintBatch(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            (address supplyRoyaltyRecipient, uint256 supplyRoyaltyAmount) = supplyRoyaltyInfo(ids[i], tokens[ids[i]].totalMinted, amounts[i]);
            _requireCanMintQuantity(ids[i], amounts[i] + supplyRoyaltyAmount);
            if (supplyRoyaltyAmount > 0) {
                super._mint(supplyRoyaltyRecipient, ids[i], supplyRoyaltyAmount, data);
            }
            tokens[ids[i]].totalMinted += amounts[i] + supplyRoyaltyAmount;
        }
    }

    /// @notice Burns a batch of tokens
    /// @dev Only the current owner is allowed to burn
    /// @param from the user to burn from
    /// @param tokenIds The token ID to burn
    /// @param amounts The amount of tokens to burn
    function burnBatch(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert Burn_NotOwnerOrApproved(msg.sender, from);
        }

        _burnBatch(from, tokenIds, amounts);
    }

    function setTransferHook(ITransferHookReceiver transferHook) external onlyAdmin(CONTRACT_BASE_ID) {
        if (address(transferHook) != address(0)) {
            if (!transferHook.supportsInterface(type(ITransferHookReceiver).interfaceId)) {
                revert Config_TransferHookNotSupported(address(transferHook));
            }
        }

        config.transferHook = transferHook;
        emit ConfigUpdated(msg.sender, ConfigUpdate.TRANSFER_HOOK, config);
    }

    /// @notice Hook before token transfer that checks for a transfer hook integration
    /// @param operator operator moving the tokens
    /// @param from from address
    /// @param to to address
    /// @param ids token ids to move
    /// @param amounts amounts of tokens
    /// @param data data of tokens
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (address(config.transferHook) != address(0)) {
            config.transferHook.onTokenTransferBatch({target: address(this), operator: operator, from: from, to: to, ids: ids, amounts: amounts, data: data});
        }
    }

    /// @notice Returns the URI for the contract
    function contractURI() external view returns (string memory) {
        IRenderer1155 customRenderer = getCustomRenderer(CONTRACT_BASE_ID);
        if (address(customRenderer) != address(0)) {
            return customRenderer.contractURI();
        }
        return uri(0);
    }

    /// @notice Returns the URI for a token
    /// @param tokenId The token ID to return the URI for
    function uri(uint256 tokenId) public view override(ERC1155Upgradeable, IERC1155MetadataURIUpgradeable) returns (string memory) {
        if (bytes(tokens[tokenId].uri).length > 0) {
            return tokens[tokenId].uri;
        }
        return _render(tokenId);
    }

    /// @notice Internal setter for contract admin with no access checks
    /// @param newOwner new owner address
    function _setOwner(address newOwner) internal {
        address lastOwner = config.owner;
        config.owner = newOwner;

        emit OwnershipTransferred(lastOwner, newOwner);
        emit ConfigUpdated(msg.sender, ConfigUpdate.OWNER, config);
    }

    /// @notice Internal no-checks set funds recipient address
    /// @param fundsRecipient new funds recipient address
    function setFundsRecipient(address payable fundsRecipient) external onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_FUNDS_MANAGER) {
        config.fundsRecipient = fundsRecipient;
        emit ConfigUpdated(msg.sender, ConfigUpdate.FUNDS_RECIPIENT, config);
    }

    /// @notice Internal no-checks set funds recipient address
    /// @param fundsRecipient new funds recipient address
    function _setFundsRecipient(address payable fundsRecipient) internal {
        config.fundsRecipient = fundsRecipient;
        emit ConfigUpdated(msg.sender, ConfigUpdate.FUNDS_RECIPIENT, config);
    }

    /// @notice Withdraws all ETH from the contract to the message sender
    function withdraw() public onlyAdminOrRole(CONTRACT_BASE_ID, PERMISSION_BIT_FUNDS_MANAGER) {
        uint256 contractValue = address(this).balance;
        if (!TransferHelperUtils.safeSendETH(config.fundsRecipient, contractValue)) {
            revert ETHWithdrawFailed(config.fundsRecipient, contractValue);
        }
    }

    ///                                                          ///
    ///                         MANAGER UPGRADE                  ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal override onlyAdmin(CONTRACT_BASE_ID) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IZoraCreator1155TypesV1} from "./IZoraCreator1155TypesV1.sol";

/*


             ░░░░░░░░░░░░░░              
        ░░▒▒░░░░░░░░░░░░░░░░░░░░        
      ░░▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░      
    ░░▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░    
   ░▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░    
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░        ░░░░░░░░  
  ░▓▓▓▒▒▒▒░░░░░░░░░░░░░░    ░░░░░░░░░░  
  ░▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░  
  ░▓▓▓▓▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░  
   ░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░  
    ░░▓▓▓▓▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░    
    ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒░░    
      ░░▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░      
          ░░▓▓▓▓▓▓▓▓▓▓▓▓▒▒░░░          

               OURS TRULY,


    github.com/ourzora/zora-1155-contracts

 */

/// @notice Storage for 1155 contract
/// @author @iainnash / @tbtstl
contract ZoraCreator1155StorageV1 is IZoraCreator1155TypesV1 {
    /// @notice token data stored for each token
    mapping(uint256 => TokenData) internal tokens;

    /// @notice metadata renderer contract for each token
    mapping(uint256 => address) public metadataRendererContract;

    /// @notice next token id available when using a linear mint style (default for launch)
    uint256 public nextTokenId;

    /// @notice Global contract configuration
    ContractConfig config;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CreatorPermissionStorageV1} from "./CreatorPermissionStorageV1.sol";
import {ICreatorPermissionControl} from "../interfaces/ICreatorPermissionControl.sol";

contract CreatorPermissionControl is CreatorPermissionStorageV1, ICreatorPermissionControl {
    /// @notice Check if the user has the given permissions
    /// @dev if multiple permissions are passed in this checks for all the permissions requested
    /// @return true or false if all of the passed in permissions apply
    function _hasPermissions(uint256 tokenId, address user, uint256 permissionBits) internal view returns (bool) {
        // Does a bitwise and and checks if any of those permissions match
        return permissions[tokenId][user] & permissionBits == permissionBits;
    }

    /// @notice Check if the user has any of the given permissions
    /// @dev if multiple permissions are passed in this checks for any one of those permissions
    /// @return true or false if any of the passed in permissions apply
    function _hasAnyPermission(uint256 tokenId, address user, uint256 permissionBits) internal view returns (bool) {
        // Does a bitwise and and checks if any of those permissions match
        return permissions[tokenId][user] & permissionBits > 0;
    }

    /// @return raw permission bits for the given user
    function getPermissions(uint256 tokenId, address user) external view returns (uint256) {
        return permissions[tokenId][user];
    }

    /// @notice addPermission – internal function to add a set of permission bits to a user
    /// @param tokenId token id to add the permission to (0 indicates contract-wide add)
    /// @param user user to update permissions for
    /// @param permissionBits bits to add permissions to
    function _addPermission(uint256 tokenId, address user, uint256 permissionBits) internal {
        uint256 tokenPermissions = permissions[tokenId][user];
        tokenPermissions |= permissionBits;
        permissions[tokenId][user] = tokenPermissions;
        emit UpdatedPermissions(tokenId, user, tokenPermissions);
    }

    /// @notice _clearPermission clear permissions for user
    /// @param tokenId token id to clear permission from (0 indicates contract-wide action)
    function _clearPermissions(uint256 tokenId, address user) internal {
        permissions[tokenId][user] = 0;
        emit UpdatedPermissions(tokenId, user, 0);
    }

    /// @notice _removePermission removes permissions for user
    /// @param tokenId token id to clear permission from (0 indicates contract-wide action)
    /// @param user user to manage permissions for
    /// @param permissionBits set of permission bits to remove
    function _removePermission(uint256 tokenId, address user, uint256 permissionBits) internal {
        uint256 tokenPermissions = permissions[tokenId][user];
        tokenPermissions &= ~permissionBits;
        permissions[tokenId][user] = tokenPermissions;
        emit UpdatedPermissions(tokenId, user, tokenPermissions);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract CreatorPermissionStorageV1 {
    mapping(uint256 => mapping(address => uint256)) public permissions;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CreatorRendererStorageV1} from "./CreatorRendererStorageV1.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";
import {ITransferHookReceiver} from "../interfaces/ITransferHookReceiver.sol";
import {SharedBaseConstants} from "../shared/SharedBaseConstants.sol";

/// @title CreatorRendererControl
/// @notice Contract for managing the renderer of an 1155 contract
abstract contract CreatorRendererControl is CreatorRendererStorageV1, SharedBaseConstants {
    function _setRenderer(uint256 tokenId, IRenderer1155 renderer, bytes calldata setupData) internal {
        if (address(renderer) == address(0)) {
            delete customRenderers[tokenId];
        } else {
            customRenderers[tokenId] = renderer;

            if (!renderer.supportsInterface(type(IRenderer1155).interfaceId)) {
                revert RendererNotValid(address(renderer));
            }
            renderer.setup(setupData);
        }

        emit RendererUpdated({tokenId: tokenId, renderer: address(renderer), user: msg.sender});
    }

    /// @notice Return the renderer for a given token
    /// @dev Returns address 0 for no results
    /// @param tokenId The token to get the renderer for
    function getCustomRenderer(uint256 tokenId) public view returns (IRenderer1155 customRenderer) {
        customRenderer = customRenderers[tokenId];
        if (address(customRenderer) == address(0)) {
            customRenderer = customRenderers[CONTRACT_BASE_ID];
        }
    }

    /// @notice Function called to render when an empty tokenURI exists on the contract
    function _render(uint256 tokenId) internal view returns (string memory) {
        return getCustomRenderer(tokenId).uri(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorRendererControl} from "../interfaces/ICreatorRendererControl.sol";
import {IRenderer1155} from "../interfaces/IRenderer1155.sol";

/// @notice Creator Renderer Storage Configuration Contract V1
abstract contract CreatorRendererStorageV1 is ICreatorRendererControl {
    /// @notice Mapping for custom renderers
    mapping(uint256 => IRenderer1155) public customRenderers;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CreatorRoyaltiesStorageV1} from "./CreatorRoyaltiesStorageV1.sol";
import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";
import {SharedBaseConstants} from "../shared/SharedBaseConstants.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title CreatorRoyaltiesControl
/// @notice Contract for managing the royalties of an 1155 contract
abstract contract CreatorRoyaltiesControl is CreatorRoyaltiesStorageV1, SharedBaseConstants {
    uint256 immutable ROYALTY_BPS_TO_PERCENT = 10_000;

    /// @notice The royalty information for a given token.
    /// @param tokenId The token ID to get the royalty information for.
    function getRoyalties(uint256 tokenId) public view returns (RoyaltyConfiguration memory) {
        RoyaltyConfiguration memory config = royalties[tokenId];
        if (config.royaltyRecipient != address(0)) {
            return config;
        }
        // Otherwise, return default.
        return royalties[CONTRACT_BASE_ID];
    }

    /// @notice Returns the royalty information for a given token.
    /// @param tokenId The token ID to get the royalty information for.
    /// @param salePrice The sale price of the NFT asset specified by tokenId
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyConfiguration memory config = getRoyalties(tokenId);
        royaltyAmount = (config.royaltyBPS * salePrice) / ROYALTY_BPS_TO_PERCENT;
        receiver = config.royaltyRecipient;
    }

    /// @notice Returns the supply royalty information for a given token.
    /// @param tokenId The token ID to get the royalty information for.
    /// @param mintAmount The amount of tokens being minted.
    /// @param totalSupply The total supply of the token,
    function supplyRoyaltyInfo(uint256 tokenId, uint256 totalSupply, uint256 mintAmount) public view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyConfiguration memory config = getRoyalties(tokenId);
        if (config.royaltyMintSchedule == 0) {
            return (config.royaltyRecipient, 0);
        }
        uint256 totalRoyaltyMints = (mintAmount + (totalSupply % config.royaltyMintSchedule)) / (config.royaltyMintSchedule - 1);
        return (config.royaltyRecipient, totalRoyaltyMints);
    }

    function _updateRoyalties(uint256 tokenId, RoyaltyConfiguration memory configuration) internal {
        // Don't allow 100% supply royalties
        if (configuration.royaltyMintSchedule == 1) {
            revert InvalidMintSchedule();
        }
        royalties[tokenId] = configuration;
        emit UpdatedRoyalties(tokenId, msg.sender, configuration);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICreatorRoyaltiesControl} from "../interfaces/ICreatorRoyaltiesControl.sol";

abstract contract CreatorRoyaltiesStorageV1 is ICreatorRoyaltiesControl {
    mapping(uint256 => RoyaltyConfiguration) public royalties;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SharedBaseConstants {
    uint256 public immutable CONTRACT_BASE_ID = 0;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";

/// @title PublicMulticall
/// @notice Contract for executing a batch of function calls on this contract
abstract contract PublicMulticall {
    /**
     * @notice Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title TransferHelperUtils
/// @notice Helper functions for sending ETH
library TransferHelperUtils {
    /// @dev Gas limit to send funds
    uint256 internal constant FUNDS_SEND_LOW_GAS_LIMIT = 110_000;

    // @dev Gas limit to send funds – usable for splits, can use with withdraws
    uint256 internal constant FUNDS_SEND_GAS_LIMIT = 310_000;

    /// @notice Sends ETH to a recipient, making conservative estimates to not run out of gas
    /// @param recipient The address to send ETH to
    /// @param value The amount of ETH to send
    function safeSendETHLowLimit(address recipient, uint256 value) internal returns (bool success) {
        (success, ) = recipient.call{value: value, gas: FUNDS_SEND_LOW_GAS_LIMIT}("");
    }

    /// @notice Sends ETH to a recipient, making an attempt to not run out of gas
    /// @param recipient The address to send ETH to
    /// @param value The amount of ETH to send
    function safeSendETH(address recipient, uint256 value) internal returns (bool success) {
        (success, ) = recipient.call{value: value, gas: FUNDS_SEND_GAS_LIMIT}("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVersionedContract} from "../interfaces/IVersionedContract.sol";

/// @title ContractVersionBase
/// @notice Base contract for versioning contracts
contract ContractVersionBase is IVersionedContract {
    /// @notice The version of the contract
    function contractVersion() external pure override returns (string memory) {
        return "1.0.0";
    }
}