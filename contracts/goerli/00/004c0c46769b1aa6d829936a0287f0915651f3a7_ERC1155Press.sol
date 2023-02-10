// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*


                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.


*/

import {ERC1155Skeleton} from "./ERC1155Skeleton.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../../utils/utils/OwnableUpgradeable.sol";
import {IERC1155TokenRenderer} from "./interfaces/IERC1155TokenRenderer.sol";
import {IERC1155PressContractLogic} from "./interfaces/IERC1155PressContractLogic.sol";
import {IERC1155PressTokenLogic} from "./interfaces/IERC1155PressTokenLogic.sol";
import {IERC1155Press} from "./interfaces/IERC1155Press.sol";
import {IERC1155Skeleton} from "./interfaces/IERC1155Skeleton.sol";
import {ERC1155PressPermissions} from "./ERC1155PressPermissions.sol";

/**
 * @title ERC1155Press
 * @notice Highly configurable ERC1155 implementation
 * @dev Functionality is configurable using external renderer + logic contracts at both contract and token level
 * @dev Uses EIP-5633 for configurable token level soulbound status
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Press is
    ERC1155Skeleton,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC1155Press,
    OwnableUpgradeable,
    ERC1155PressPermissions
{

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTANTS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Max basis points (BPS) for secondary royalties + primary sales fee
    uint16 constant public MAX_BPS = 50_00;

    /// @dev Gas limit to send funds
    uint256 constant internal FUNDS_SEND_GAS_LIMIT = 210_000;    

    /// @dev Max supply value
    uint256 constant internal maxSupply = type(uint256).max;

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Initializes a new, creator-owned proxy of ERC1155Press.sol
    /// @dev `initializer` for OpenZeppelin's OwnableUpgradeable
    /// @param _name Contract name
    /// @param _symbol Contract symbol
    /// @param _initialOwner User that owns the contract upon deployment  
    /// @param _contractLogic Contract level logic contract to use for access control
    /// @param _contractLogicInit Contract level logic optional init data
    function initialize(
        string memory _name, 
        string memory _symbol, 
        address _initialOwner,
        IERC1155PressContractLogic _contractLogic,
        bytes memory _contractLogicInit
    ) public initializer {
        // Setup reentrancy guard
        __ReentrancyGuard_init();
        // Setup owner for Ownable 
        __Ownable_init(_initialOwner);

        // Setup contract name + contract symbol. Cannot be updated after initialization
        name = _name;
        symbol = _symbol;

        // Setup + initialize contract level logic
        contractLogic = _contractLogic;
        _contractLogic.initializeWithData(_contractLogicInit);

        emit ERC1155PressInitialized({
            sender: msg.sender,
            owner: _initialOwner,
            contractLogic: _contractLogic
        });
    }

    // ||||||||||||||||||||||||||||||||
    // ||| MINT FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Allows user to mint copies of a new tokenId from the Press contract
    /// @dev No ability to update platform fees after setting them in this call
    /// @dev No ability to update token specific soulbound value after setting it in this call
    /// @param recipients address to mint NFTs to
    /// @param quantity number of NFTs to mint to each address
    /// @param logic logic contract to associate with a given token
    /// @param logicInit logicInit data to associate with a given logic contract
    /// @param renderer renderer contracts to associate with a given token
    /// @param rendererInit rendererInit data to associate with a given renderer contract
    /// @param fundsRecipient address that receives funds generated by the token (minus fees) + any secondary royalties
    /// @param royaltyBPS secondary royalty BPS
    /// @param primarySaleFeeRecipient optional primary sale fee recipient address
    /// @param primarySaleFeeBPS primary sale feeBPS. cannot be zero if fee recipient set to != address(0)
    /// @param soulbound determines whether token can be transferred after minted. false = transferrable, true = non-transferrable            
    function mintNew(
        address[] memory recipients,
        uint256 quantity,
        IERC1155PressTokenLogic logic, 
        bytes memory logicInit,
        IERC1155TokenRenderer renderer, 
        bytes memory rendererInit,
        address payable fundsRecipient,
        uint16 royaltyBPS,
        address payable primarySaleFeeRecipient,
        uint16 primarySaleFeeBPS,
        bool soulbound        
    ) external payable nonReentrant {
        // // Call contract level logic contract to check if user can mint
        _canMintNew(address(this), msg.sender, recipients, quantity);
        // // Call logic contract to check what msg.value needs to be sent
        _mintNewValueCheck(msg.value, address(this), msg.sender, recipients, quantity);

        // Check to see if royaltyBPS and feeBPS set to acceptable levels
        if (royaltyBPS > MAX_BPS || primarySaleFeeBPS > MAX_BPS) {
            revert Setup_PercentageTooHigh(MAX_BPS);
        }
        // Check to see if minted quantity exceeds maxSupply
        if (quantity > maxSupply) {
            revert Exceeds_MaxSupply();
        }        

        // Increment tokenCount for contract. Update global _tokenCount state and sets tokenId to be minted in txn
        ++_tokenCount;

        // Cache _tokenCount value
        uint256 tokenId = _tokenCount;

        // Set token specific logic + renderer contracts
        configInfo[tokenId].logic = logic;
        configInfo[tokenId].renderer = renderer;
        // Set token specific funds recipient + royaltyBPS. Funds recipient address will receive (primary mint revenue - parimary sale fee) + secondary royalties
        configInfo[tokenId].fundsRecipient = fundsRecipient;
        configInfo[tokenId].royaltyBPS = royaltyBPS;
        // Set token specific primry sale fee recipient + feeBPS. Cannot be updated after set 
        configInfo[tokenId].primarySaleFeeRecipient = primarySaleFeeRecipient;        
        configInfo[tokenId].primarySaleFeeBPS = primarySaleFeeBPS;
        // Set token specific soulbound value. false = transferable, true = non-transferable
        configInfo[tokenId].soulbound = soulbound;

        // Initialize token logic + renderer
        IERC1155PressTokenLogic(logic).initializeWithData(tokenId, logicInit);
        IERC1155TokenRenderer(renderer).initializeWithData(tokenId, rendererInit);  

        // For each recipient provided, mint them given quantity of tokenId being newly minted
        for (uint256 i = 0; i < recipients.length; ++i) {
            // Check to see if any recipient is zero address
            _checkForZeroAddress(recipients[i]);
            // Mint quantity of given tokenId to recipient
            _mint(recipients[i], tokenId, quantity, new bytes(0));

            emit NewTokenMinted({
                tokenId: tokenId,
                sender: msg.sender,
                recipient: recipients[i],
                quantity: quantity
            });            
        }

        // Initialize tokenId => tokenFundsInfo mapping. Even if msg.value is 0, we still want to set it
        tokenFundsInfo[tokenId] = msg.value;      

        // Update tracking of funds associated with given tokenId in tokenFundsInfo
        emit TokenFundsIncreased({
            tokenId: tokenId,
            sender: msg.sender,            
            amount: msg.value
        });
    }

    /// @notice Allows user to mint an existing token from the Press contract
    /// @param tokenId which tokenId to mint copies of
    /// @param recipients addresses to mint NFTs to. multiple recipients allows for gifting
    /// @param quantity how many copies to mint to each recipient
    function mintExisting(         
        uint256 tokenId, 
        address[] memory recipients,
        uint256 quantity
    ) external payable nonReentrant {
        // Cache msg.sender + msg.value
        (uint256 msgValue, address sender) = (msg.value, msg.sender);

        // Check to see if tokenId being minted exists
        _exists(tokenId);
        // Call token level logic contract to check if user can mint
        _canMintExisting(address(this), sender, tokenId, recipients, quantity);
        // Call logic contract to check what msg.value needs to be sent for given Press + tokenIds + quantities + msg.sender
        _mintExistingValueCheck(msgValue, address(this), tokenId, sender, recipients, quantity);
        // Check to see if minted quantity exceeds maxSupply

        if (_totalSupply[tokenId] + quantity > maxSupply) {
            revert Exceeds_MaxSupply();
        }               

        // Mint desired quantity of desired tokenId to each provided recipient
        for (uint256 i; i < recipients.length; ++i) {
            // Mint quantity of given tokenId to recipient
            _mint(recipients[i], tokenId, quantity, new bytes(0));

            emit ExistingTokenMinted({
                tokenId: tokenId,
                sender: sender,
                recipient: recipients[i],
                quantity: quantity
            });    
        }

        // Update tokenId => tokenFundsInfo mapping
        tokenFundsInfo[tokenId] += msgValue;

        // Update tracking of funds associated with given tokenId in tokenFundsInfo
        emit TokenFundsIncreased({
            tokenId: tokenId,
            sender: sender,            
            amount: msgValue
        });        
    }

    // ||||||||||||||||||||||||||||||||
    // ||| BURN FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice User burn function for given tokenId
    /// @param id tokenId to burn
    /// @param amount quantity to burn
    function burn(uint256 id, uint256 amount) public {    
        // Check if burn is allowed for sender
        _canBurn(address(this), id, amount, msg.sender);

        _burn(msg.sender, id, amount);
    }

    /// @notice User batch burn function for given tokenIds
    /// @param ids tokenIds to burn
    /// @param amounts quantities to burn
    function batchBurn(uint256[] memory ids, uint256[] memory amounts) public {
        // Cache msg.sender
        address sender = msg.sender;
        
        // prevents users from submitting invalid inputs
        if (ids.length != amounts.length) {
            revert Invalid_Input();
        }        

        // check for burn perimssion for each token
        for (uint256 i; i < ids.length; ++i) {
            // Check if burn is allowed for sender
            _canBurn(address(this), ids[i], amounts[i], sender);
        }

        _batchBurn(sender, ids, amounts);
    }   

    // ||||||||||||||||||||||||||||||||
    // ||| ADMIN FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Function to set configInfo[tokenId].fundsRecipient
    /// @dev Cannot set `fundsRecipient` to the zero address
    /// @param tokenId tokenId to target
    /// @param newFundsRecipient payable address to receive funds via withdraw
    function setFundsRecipient(uint256 tokenId, address payable newFundsRecipient) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        _canUpdateConfig(address(this), tokenId, msg.sender);

        // Update `fundsRecipient` address in config
        configInfo[tokenId].fundsRecipient = newFundsRecipient;

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: msg.sender, 
            logic: configInfo[tokenId].logic,
            renderer: configInfo[tokenId].renderer,
            fundsRecipient: newFundsRecipient,
            royaltyBPS: configInfo[tokenId].royaltyBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }

    /// @notice Function to set config.logic
    /// @dev Cannot set fundsRecipient or logic or renderer to address(0)
    /// @dev Max `newRoyaltyBPS` value = 5000
    /// @param tokenId tokenId to target
    /// @param newFundsRecipient payable address to recieve funds via withdraw
    /// @param newRoyaltyBPS uint16 value of royaltyBPS
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setConfig(
        uint256 tokenId,
        address payable newFundsRecipient,
        uint16 newRoyaltyBPS,
        IERC1155PressTokenLogic newLogic,
        bytes memory newLogicInit,        
        IERC1155TokenRenderer newRenderer,
        bytes memory newRendererInit
    ) external nonReentrant {
        // Call logic contract to check is msg.sender can update config for given Press + token
        _canUpdateConfig(address(this), tokenId, msg.sender);
        // Check if newRoyaltyBPS is higher than immutable MAX_BPS value
        if (newRoyaltyBPS > MAX_BPS) {
            revert Setup_PercentageTooHigh(MAX_BPS);
        }        

        // Update fundsRecipient address in config
        configInfo[tokenId].fundsRecipient = newFundsRecipient;
        // Update royaltyBPS in config
        configInfo[tokenId].royaltyBPS = newRoyaltyBPS;
        // Update logic contract address in config + initialize it
        configInfo[tokenId].logic = newLogic;
        newLogic.initializeWithData(tokenId, newLogicInit);
        // Update renderer address in config + initialize it
        configInfo[tokenId].renderer = newRenderer;
        newRenderer.initializeWithData(tokenId, newRendererInit);        

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: msg.sender, 
            logic: newLogic,
            renderer: newRenderer,
            fundsRecipient: newFundsRecipient,
            royaltyBPS: newRoyaltyBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }

    // ||||||||||||||||||||||||||||||||
    // ||| CONTRACT OWNERSHIP |||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Set new owner for access control + frontends
    /// @param newOwner address of the new owner
    function setOwner(address newOwner) public {
        // Check if msg.sender can transfer ownership
        if (msg.sender != owner() && !contractLogic.canSetOwner(address(this), msg.sender)) {
            revert No_Transfer_Access();
        }

        // Transfer contract ownership to new owner
        _transferOwnership(newOwner);
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNDS WITHDRAWALS ||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Allows user to withdraw funds generated by a given tokenIds to the designated funds recipient for those tokens
    /// @dev reverts if any withdraw call is invalid for any provided tokenId
    /// @param tokenIds which tokenIds to withdraw funds from
    function withdraw(uint256[] memory tokenIds) external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;

        // Attempt to process withdraws for each tokenId provided
        for (uint256 i; i < tokenIds.length; ++i) {  
            // check to see if tokenId exists
            _exists(tokenIds[i]);
            // Check if withdraw is allowed for sender
            _canWithdraw(address(this), tokenIds[i], sender);
            // Check to see if tokenId has a balance
            if (tokenFundsInfo[tokenIds[i]] == 0) {
                revert No_Withdrawable_Balance(tokenIds[i]);
            }  

            // Calculate primary sale fee amount
            uint256 funds = tokenFundsInfo[tokenIds[i]];
            uint256 fee = funds * configInfo[tokenIds[i]].primarySaleFeeBPS / 10_000;

            // Payout primary sale fees
            if (fee > 0) {
                (bool successFee,) = configInfo[tokenIds[i]].primarySaleFeeRecipient.call{value: fee, gas: FUNDS_SEND_GAS_LIMIT}("");
                if (!successFee) {
                    revert Withdraw_FundsSendFailure();
                }
                funds -= fee;
            }
            // Payout recipient
            (bool successFunds,) = configInfo[tokenIds[i]].fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
            if (!successFunds) {
                revert Withdraw_FundsSendFailure();
            }

            // Update tokenIds[i] => tokenFundsInfo mapping
            tokenFundsInfo[tokenIds[i]] -= (funds + fee);

            emit TokenFundsWithdrawn({
                tokenId: tokenIds[i], 
                sender: sender, 
                fundsRecipient: configInfo[tokenIds[i]].fundsRecipient, 
                fundsAmount: funds, 
                feeRecipient: configInfo[tokenIds[i]].primarySaleFeeRecipient, 
                feeAmount: fee
            });
        }
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW CALLS |||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Simple override for owner interface
    function owner() public view override(OwnableUpgradeable, IERC1155Press) returns (address) {
        return super.owner();
    }

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) public view virtual override(ERC1155Skeleton, IERC1155Press) returns (string memory) {
        return configInfo[tokenId].renderer.uri(tokenId);
    }

    /// @notice Getter for logic contract stored in configInfo for a given tokenId
    function getTokenLogic(uint256 tokenId) external view returns (IERC1155PressTokenLogic) {
        return configInfo[tokenId].logic;
    }    

    /// @notice Getter for renderer contract stored in configInfo for a given tokenId
    function getRenderer(uint256 tokenId) external view returns (IERC1155TokenRenderer) {
        return configInfo[tokenId].renderer;
    }    

    /// @notice Getter for fundsRecipent address stored in configInfo for a given tokenId
    function getFundsRecipient(uint256 tokenId) external view returns (address payable) {
        return configInfo[tokenId].fundsRecipient;
    }    

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) public view virtual override(ERC1155Skeleton, IERC1155Skeleton) returns (bool) {
        return configInfo[id].soulbound;
    }           

    /// @notice Config level details
    /// @return Configuration (defined in IERC1155Press) 
    function getConfigDetails(uint256 tokenId) external view returns (Configuration memory) {
        return Configuration({
            logic: configInfo[tokenId].logic,
            renderer: configInfo[tokenId].renderer,
            fundsRecipient: configInfo[tokenId].fundsRecipient,
            royaltyBPS: configInfo[tokenId].royaltyBPS,
            primarySaleFeeRecipient: configInfo[tokenId].primarySaleFeeRecipient,
            primarySaleFeeBPS: configInfo[tokenId].primarySaleFeeBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }      

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC1155Press, ERC1155Skeleton)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }        

    // ||||||||||||||||||||||||||||||||
    // ||| UPGRADES |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Can only be called by an admin or the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override canUpgrade {}

    modifier canUpgrade() {
        // call logic contract to check is msg.sender can upgrade
        _canUpgrade(address(this), msg.sender);

        _;
    }            

    // ||||||||||||||||||||||||||||||||
    // ||| MISC |||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||    
    
    // Check to see if address = address(0)
    function _checkForZeroAddress(address addressToCheck) internal pure {
        if (addressToCheck == address(0)) {
            revert Cannot_Set_Zero_Address();
        }
    }    

    // Check to see if tokenId being minted exists
    function _exists(uint256 tokenId) internal view {
        if (tokenId > _tokenCount) {
            revert Token_Doesnt_Exist(tokenId);
        }                
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155TokenRenderer} from "./interfaces/IERC1155TokenRenderer.sol";
import {IERC1155PressContractLogic} from "./interfaces/IERC1155PressContractLogic.sol";
import {IERC1155PressTokenLogic} from "./interfaces/IERC1155PressTokenLogic.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";
import {IERC1155Press} from "./interfaces/IERC1155Press.sol";

/**
 * @title ERC1155PressPermissions
 * @notice Permission calls used in ERC1155Press
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155PressPermissions is ERC1155PressStorageV1 {

    function _canMintNew(address targetPress, address sender, address[] memory recipients, uint256 quantity) internal view {
        // Call contract level logic contract to check if user can mint
        if (!IERC1155PressContractLogic(contractLogic).canMintNew(targetPress, sender, recipients, quantity)) {
            revert IERC1155Press.No_MintNew_Access();
        }     
    }

    // Call logic contract to check what msg.value needs to be sent
    function _mintNewValueCheck(uint256 msgValue, address targetPress, address sender, address[] memory recipients, uint256 quantity) internal view {
        if (msgValue != IERC1155PressContractLogic(contractLogic).mintNewPrice(targetPress, sender, recipients, quantity)) {
            revert IERC1155Press.Incorrect_Msg_Value();
        }
    }

    // Call token level logic contract to check if user can mint
    function _canMintExisting(address targetPress, address sender, uint256 tokenId, address[] memory recipients, uint256 quantity) internal view {
        if (!IERC1155PressTokenLogic(configInfo[tokenId].logic).canMintExisting(targetPress, sender, tokenId, recipients, quantity)) {
            revert IERC1155Press.No_MintExisting_Access();
        }           
    } 

    // Call logic contract to check what msg.value needs to be sent
    function _mintExistingValueCheck(uint256 msgValue, address targetPress, uint256 tokenId, address sender, address[] memory recipients, uint256 quantity) internal view {
        if (msgValue != IERC1155PressTokenLogic(configInfo[tokenId].logic).mintExistingPrice(targetPress, tokenId, sender, recipients, quantity)) {
            revert IERC1155Press.Incorrect_Msg_Value();
        }
    }

    // Call logic contract to check if burn is allowed for sender
    function _canBurn(address targetPress, uint256 tokenId, uint256 amount, address sender) internal view {
        if (!IERC1155PressTokenLogic(configInfo[tokenId].logic).canBurn(targetPress, tokenId, amount, sender)) {
            revert IERC1155Press.No_Burn_Access();
        }   
    }

    // Call logic contract to check is msg.sender can update
    function _canUpdateConfig(address targetPress, uint256 tokenId, address sender) internal view {
        if (!IERC1155PressTokenLogic(configInfo[tokenId].logic).canUpdateConfig(targetPress, tokenId, sender)) {
            revert IERC1155Press.No_Config_Access();
        }    
    }    

    // Call logic contract to check if withdraw is allowed for sender
    function _canWithdraw(address targetPress, uint256 tokenId, address sender) internal view {
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canWithdraw(targetPress, tokenId, sender) != true) {
            revert IERC1155Press.No_Withdraw_Access();
        }    
    }    
    // call logic contract to check is msg.sender can upgrade
    function _canUpgrade(address targetPress, address sender) internal view {
        if (!IERC1155PressContractLogic(contractLogic).canUpgrade(targetPress, sender)) {
            revert IERC1155Press.No_Upgrade_Access();
        }    
    }




        // // Call token level logic contract to check if user can mint
        // if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canMintExisting(address(this), sender, tokenId, recipients, quantity)) {
        //     revert No_MintExisting_Access();
        // }   
        // Call logic contract to check what msg.value needs to be sent for given Press + tokenIds + quantities + msg.sender
        // if (msg.value != IERC1155PressTokenLogic(configInfo[tokenId].logic).mintExistingPrice(address(this), tokenId, sender, recipients, quantity)) {
        //     revert Incorrect_Msg_Value();
        // }         

        // // Call logic contract to check what msg.value needs to be sent for given Press + msg.sender
        // if (msg.value != IERC1155PressContractLogic(contractLogic).mintNewPrice(address(this), msg.sender, recipients, quantity)) {
        //     revert Incorrect_Msg_Value();
        // }            

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Version} from "../../utils/utils/Version.sol";
import {FundsReceiver} from "../../utils/utils/FundsReceiver.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";
import {IERC5633} from "../../utils/interfaces/IERC5633.sol";
import {IERC1155Skeleton} from "./interfaces/IERC1155Skeleton.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

/**
 * @title ERC1155Skeleton
 * @notice ERC1155 Skeleton that containing overrides on certain 1155 functions
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Skeleton is
    ERC1155,
    Version(1),
    ERC1155PressStorageV1,
    FundsReceiver,
    IERC1155Skeleton,
    IERC2981Upgradeable,
    IERC5633
{    

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW CALLS |||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @dev Total amount of existing tokens with a given tokenId.
    function totalSupply(uint256 tokenId) external view virtual returns (uint256) {
        return _totalSupply[tokenId];
    }    

    /// @notice getter for internal _numMinted counter which keeps track of quantity minted per tokenId per wallet address
    function numMinted(uint256 tokenId, address account) public view returns (uint256) {
        return _numMinted[tokenId][account];
    }         

    /// @notice getter for internal _tokenCount counter which keeps track of the most recently minted tokenId
    function tokenCount() public view returns (uint256) {
        return _tokenCount;
    } 

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) public view virtual override(IERC5633, IERC1155Skeleton) returns (bool) {
        return configInfo[id].soulbound;
    }       

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) public view virtual override(ERC1155) returns (string memory) {}

    /// @dev Get royalty information for token
    /// @param _salePrice Sale price for the token
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override(IERC2981Upgradeable)
        returns (address receiver, uint256 royaltyAmount)
    {
        if (configInfo[_tokenId].fundsRecipient == address(0)) {
            return (configInfo[_tokenId].fundsRecipient, 0);
        }
        return (
            configInfo[_tokenId].fundsRecipient,
            (_salePrice * configInfo[_tokenId].royaltyBPS) / 10_000
        );
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ERC1155 CUSTOMIZATION ||||||
    // ||||||||||||||||||||||||||||||||

    /*
        the following changes to mint/burn calls 
        allow for totalSupply + numMinted to be tracked at the token level
    */

    /// @dev See {ERC1155-_mint}.
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
        _numMinted[id][account] += amount;
    }

    /// @dev See {ERC1155-_batchMint}.
    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._batchMint(to, ids, amounts, data);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] += amounts[i];
            _numMinted[ids[i]][to] += amounts[i];
            unchecked { ++i; }
        }
    }

    /// @dev See {ERC1155-_burn}.
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }     

    /// @dev See {ERC1155-_batchBurn}.
    function _batchBurn(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._batchBurn(account, ids, amounts);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] -= amounts[i];
            unchecked { ++i; }
        }
    }

    /*
        the following changes enable EIP-5633 style soulbound functionality
    */    

    // override safeTransferFrom hook to calculate array[](1) of tokenId being checked and pass it through
    //      the custom _beforeTokenTransfer soulbound check hook
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes calldata data
    ) public override {
        super.safeTransferFrom(from, to, id, amount, data);
        uint256[] memory ids = _asSingletonArray(id);
        _beforeTokenTransfer(from, to, ids);
    }

    // override safeBatchTransferFrom hook and pass array[] of ids through 
    //      custom _beforeTokenTransfer soulbound check hook
    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata data
    ) public override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        _beforeTokenTransfer(from, to, ids);
    }

    // for single transfers, ids.length will always equal 1
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids
    ) internal virtual {

        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i])) {
                require(
                    from == address(0) || to == address(0),
                    "ERC5633: Soulbound, Non-Transferable"
                );
            }
        }
    }    

    // create an array of length 1
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }    

    // interfcace
    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        virtual
        view
        override(ERC1155, IERC165Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC5633).interfaceId == interfaceId ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }            
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*


                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.


*/

import {IERC1155PressTokenLogic} from "./IERC1155PressTokenLogic.sol";
import {IERC1155TokenRenderer} from "./IERC1155TokenRenderer.sol";
import {IERC1155PressContractLogic} from "./IERC1155PressContractLogic.sol";
import {IERC1155Skeleton} from "./IERC1155Skeleton.sol";

interface IERC1155Press is IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // stores token level logic + renderer + funds + transferability related information
    struct Configuration {
        address payable fundsRecipient;
        IERC1155PressTokenLogic logic;
        IERC1155TokenRenderer renderer;
        address payable primarySaleFeeRecipient;
        bool soulbound;
        uint16 royaltyBPS;
        uint16 primarySaleFeeBPS;        
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have mint new access for given Press
    error No_MintNew_Access();    
    /// @notice msg.sender does not have mint existing access for given Press
    error No_MintExisting_Access();
    /// @notice msg.sender does not have config access for given Press + tokenId
    error No_Config_Access();     
    /// @notice msg.sender does not have withdraw access for given Press
    error No_Withdraw_Access();    
    /// @notice cannot withdraw balance from a tokenId with no associated funds  
    error No_Withdrawable_Balance(uint256 tokenId);     
    /// @notice msg.sender does not have burn access for given Press + tokenId
    error No_Burn_Access();    
    /// @notice msg.sender does not have upgrade access for given Press
    error No_Upgrade_Access();     
    /// @notice msg.sender does not have owernship transfer access for given Press
    error No_Transfer_Access();       

    // Constraint/invalid/failure errors
    /// @notice invalid input
    error Invalid_Input();
    /// @notice If minted total supply would exceed max supply
    error Exceeds_MaxSupply();    
    /// @notice invalid contract inputs due to parameter.length mismatches
    error Input_Length_Mismatch();
    /// @notice token doesnt exist error
    error Token_Doesnt_Exist(uint256 tokenId);    
    /// @notice incorrect msg.value for transaction
    error Incorrect_Msg_Value();    
    /// @notice cant set address
    error Cannot_Set_Zero_Address();
    /// @notice cannot set royalty or finders fee bps this high
    error Setup_PercentageTooHigh(uint16 maxBPS);    
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();    
    /// @notice error setting config varibles
    error Set_Config_Fail(); 

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Event emitted upon ERC1155Press initialization
    /// @param sender msg.sender calling initialization function
    /// @param owner initial owner of contract
    /// @param contractLogic logic contract set 
    event ERC1155PressInitialized(
        address indexed sender,        
        address indexed owner,
        IERC1155PressContractLogic indexed contractLogic
    );          

    /// @notice Event emitted when minting a new token
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender calling mintNew function
    /// @param recipient recipient of tokens
    /// @param quantity quantity of tokens received by recipient 
    event NewTokenMinted(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed recipient,
        uint256 quantity
    );    

    /// @notice Event emitted when minting an existing token
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender calling mintExisting function
    /// @param recipient recipient of tokens
    /// @param quantity quantity of tokens received by recipient 
    event ExistingTokenMinted(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed recipient,
        uint256 quantity
    );

    /// @notice Event emitted when adding to a tokenId's funds tracking
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender passing value
    /// @param amount value being added to tokenId's funds tracking
    event TokenFundsIncreased(
        uint256 indexed tokenId,        
        address indexed sender,
        uint256 amount
    );    

    /// @notice Event emitted when the funds generated by a given tokenId are withdrawn from the minting contract
    /// @param tokenId tokenId to withdraw generated funds from
    /// @param sender address that issued the withdraw
    /// @param fundsRecipient address that the funds were withdrawn to
    /// @param fundsAmount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event TokenFundsWithdrawn(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed fundsRecipient,        
        uint256 fundsAmount,
        address feeRecipient,
        uint256 feeAmount
    );    

    /// @notice Event emitted when config is updated post initialization
    /// @param tokenId tokenId config being updated
    /// @param sender address that sent update txn
    /// @param logic logic contract address
    /// @param renderer renderer contract address
    /// @param fundsRecipient fundsRecipient
    /// @param royaltyBPS royaltyBPS
    /// @param soulbound soulbound bool
    event UpdatedConfig(
        uint256 indexed tokenId,
        address indexed sender,        
        IERC1155PressTokenLogic logic,
        IERC1155TokenRenderer renderer,
        address fundsRecipient,
        uint16 royaltyBPS,
        bool soulbound
    );    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Public owner setting that can be set by the contract admin
    function owner() external view returns (address);

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Getter for logic contract stored in configInfo for a given tokenId
    function getTokenLogic(uint256 tokenId) external view returns (IERC1155PressTokenLogic); 

    /// @notice Getter for renderer contract stored in configInfo for a given tokenId
    function getRenderer(uint256 tokenId) external view returns (IERC1155TokenRenderer); 

    /// @notice Getter for fundsRecipent address stored in configInfo for a given tokenId
    function getFundsRecipient(uint256 tokenId) external view returns (address payable); 

    /// @notice Config level details
    /// @return Configuration (defined in IERC1155Press) 
    function getConfigDetails(uint256 tokenId) external view returns (Configuration memory);

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressContractLogic {  
    
    // Initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    // Access control functions
    /// @notice checks if a certain address can access mintnew functionality for a given Press + recepients + quantity combination
    function canMintNew(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (bool);    
    /// @notice checks if a certain address can set ownership of a given Press
    function canSetOwner(address targetPress, address transferCaller) external view returns (bool);    
    /// @notice checks if a certain address can upgrade the underlying implementation for a given Press
    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool);    

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintNewPrice(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressTokenLogic {  
    
    // Initialize function
    /// @notice initializes logic file for a given tokenId + Press with arbitrary data
    function initializeWithData(uint256 tokenId, bytes memory initData) external;    

    // Access control functions
    /// @notice checks if a certain address can edit metadata post metadata initialization for a given Press + tokenId
    function canEditMetadata(address targetPress, uint256 tokenId, address editCaller) external view returns (bool);        
    /// @notice checks if a certain address can update the Config struct on a given tokenId for a given Press 
    function canUpdateConfig(address targetPress, uint256 tokenId, address updateCaller) external view returns (bool);
    /// @notice checks if a certain address can access mint functionality for a given tokenId for a given Press + recipient + quantity combination
    function canMintExisting(address targetPress, address mintCaller, uint256 tokenId, address[] memory recipients, uint256 quantity) external view returns (bool);
    /// @notice checks if a certain address can call the withdraw function for a given tokenId for a given Press
    function canWithdraw(address targetPress, uint256 tokenId, address withdrawCaller) external view returns (bool);
    /// @notice checks if a certain address can call the burn function for a given tokenId for a given Press
    function canBurn(address targetPress, uint256 tokenId, uint256 quantity, address burnCaller) external view returns (bool);    

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress, uint256 tokenId) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintExistingPrice(address targetPress, uint256 tokenId, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Amount of existing (minted & not burned) tokens with a given tokenId
    function totalSupply(uint256 tokenId) external view returns (uint256);

    /// @notice getter for internal _numMinted counter which keeps track of quantity minted per tokenId per wallet address
    function numMinted(uint256 tokenId, address account) external view returns (uint256);    

    /// @notice Getter for last minted tokenId
    function tokenCount() external view returns (uint256);

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155TokenRenderer {
    function uri(uint256 tokenId) external view returns (string memory);
    function initializeWithData(uint256 tokenId, bytes memory rendererInit) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155Press} from "../interfaces/IERC1155Press.sol";
import {IERC1155PressContractLogic} from "../interfaces/IERC1155PressContractLogic.sol";

contract ERC1155PressStorageV1 {    
    /// @dev Counter to keep track of tokenId. First token minted will be tokenId #1
    uint256 internal _tokenCount = 0;
    /// @notice Contract name
    string public name;
    /// @notice Contract sumbol
    string public symbol;
    /// @notice Contract level logic storage
    IERC1155PressContractLogic public contractLogic;
    /// @notice Logic + renderer press contract storage. Stored at tokenId level
    mapping(uint256 => IERC1155Press.Configuration) public configInfo;      
    /// @notice Mapping keeping track of funds generated from mints of a given token 
    mapping(uint256 => uint256) public tokenFundsInfo;    
    /// @notice Token level total supply
    mapping(uint256 => uint256) internal _totalSupply;    
    /// @notice Token level minted tracker
    mapping(uint256 => mapping(address => uint256)) internal _numMinted;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5633 {
  /**
   * @dev Emitted when a token type `id` is set or cancel to soulbound, according to `bounded`.
   */
  event Soulbound(uint256 indexed id, bool bounded);

  /**
   * @dev Returns true if a token type `id` is soulbound.
   */
  function isSoulbound(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IOwnable
/// @author Rohan Kulkarni
/// @notice The external Ownable events, errors, and functions
interface IOwnableUpgradeable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    /// @dev Owner cannot be the zero/burn address
    error OWNER_CANNOT_BE_ZERO_ADDRESS();


    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @notice This allows this contract to receive native currency funds from other contracts
 * Uses event logging for UI reasons.
 * @author Zora Labs
 */
contract FundsReceiver {
    event FundsReceived(address indexed source, uint256 amount);

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IOwnableUpgradeable} from "../interfaces/IOwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Ownable
/// @author Rohan Kulkarni / Iain Nash
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (access/OwnableUpgradeable.sol)
/// - Uses custom errors declared in IOwnable
/// - Adds optional two-step ownership transfer (`safeTransferOwnership` + `acceptOwnership`)
abstract contract OwnableUpgradeable is IOwnableUpgradeable, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending owner
    address internal _pendingOwner;

    /// @dev Modifier to check if the address argument is the zero/burn address
    modifier notZeroAddress(address check) {
        if (check == address(0)) {
            revert OWNER_CANNOT_BE_ZERO_ADDRESS();
        }
        _;
    }

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert ONLY_OWNER();
        }
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) {
            revert ONLY_PENDING_OWNER();
        }
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner)
        internal
        notZeroAddress(_initialOwner)
        onlyInitializing
    {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @notice The address of the owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer from the last owner
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner)
        public
        notZeroAddress(_newOwner)
        onlyOwner
    {
        _transferOwnership(_newOwner);
    }

    /// @notice Forces an ownership transfer from any sender
    /// @param _newOwner New owner to transfer contract to
    /// @dev Ensure is called only from trusted internal code, no access control checks.
    function _transferOwnership(address _newOwner) internal {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;

        if (_pendingOwner != address(0)) {
            delete _pendingOwner;
        }
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner)
        public
        notZeroAddress(_newOwner)
        onlyOwner
    {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Resign ownership of contract
    /// @dev only callably by the owner, dangerous call.
    function resignOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Version {
  uint32 private immutable __version;

  /// @notice The version of the contract
  /// @return The version ID of this contract implementation
  function contractVersion() external view returns (uint32) {
      return __version;
  }

  constructor(uint32 version) {
    __version = version;
  }
}