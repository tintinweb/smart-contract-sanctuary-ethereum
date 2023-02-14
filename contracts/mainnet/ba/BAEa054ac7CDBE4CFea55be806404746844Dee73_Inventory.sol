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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./libraries/LibIMPT.sol";
import "./libraries/SigRecovery.sol";

import "../interfaces/ICarbonCreditNFT.sol";

contract CarbonCreditNFT is
  ICarbonCreditNFT,
  IERC1155MetadataURIUpgradeable,
  ERC1155Upgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using StringsUpgradeable for uint256;

  IMarketplace public override MarketplaceContract;
  IInventory public override InventoryContract;
  ISoulboundToken public override SoulboundContract;
  IAccessManager public override AccessManager;

  string private _name;
  string private _symbol;

  modifier onlyMarketplace() {
    if (msg.sender != address(MarketplaceContract)) {
      revert TransferMethodDisabled();
    }
    _;
  }

  modifier onlyIMPTRole(bytes32 _role, IAccessManager _AccessManager) {
    LibIMPT._hasIMPTRole(_role, msg.sender, AccessManager);
    _;
  }

  function initialize(ConstructorParams memory _params) public initializer {
    __ERC1155_init(_formatBaseUri(_params.baseURI));
    __Pausable_init();
    __UUPSUpgradeable_init();

    LibIMPT._checkZeroAddress(address(_params.AccessManager));

    AccessManager = _params.AccessManager;

    _name = _params.name;
    _symbol = _params.symbol;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function uri(
    uint256 _id
  )
    public
    view
    override(
      ICarbonCreditNFT,
      ERC1155Upgradeable,
      IERC1155MetadataURIUpgradeable
    )
    returns (string memory)
  {
    return string.concat(super.uri(_id), "/", _id.toString());
  }

  /// @dev This function is to check that the upgrade functions in UUPSUpgradeable are being called by an address with the correct role
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {}

  function _verifyTransferRequest(
    TransferAuthorisationParams calldata _transferAuthParams,
    bytes calldata _transferAuthSignature
  ) internal view {
    bytes memory encodedTransferRequest = abi.encode(
      _transferAuthParams.expiry,
      _transferAuthParams.to
    );

    address recoveredAddress = SigRecovery.recoverAddressFromMessage(
      encodedTransferRequest,
      _transferAuthSignature
    );

    if (!AccessManager.hasRole(LibIMPT.IMPT_BACKEND_ROLE, recoveredAddress)) {
      revert LibIMPT.InvalidSignature();
    }

    if (_transferAuthParams.expiry < block.timestamp) {
      revert LibIMPT.SignatureExpired();
    }
  }

  function retire(uint256 _tokenId, uint256 _amount) external whenNotPaused {
    _burn(msg.sender, _tokenId, _amount);

    SoulboundContract.incrementRetireCount(msg.sender, _tokenId, _amount);
    InventoryContract.incrementBurnCount(_tokenId, _amount);
  }

  /// @dev The safeTransferFrom and safeBatchTransferFrom methods are disabled for users, this is because only KYCed user's can hold CarbonCreditNFT's. This KYC status is checked via a centralised backend and a signature is then generated that is validated by the contract. The methods transferFromBackendAuth and batchTransferFromBackendAuth allow this functionality.
  /// @dev Separately the safeTransferFrom and safeBatchTransferFrom are enabled for the MarketplaceContract as that contract will be handling the validation of sale orders and also has it's own checks for the backend signature auth
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  )
    public
    virtual
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    whenNotPaused
    onlyMarketplace
  {
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    public
    virtual
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    whenNotPaused
    onlyMarketplace
  {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function transferFromBackendAuth(
    address from,
    uint256 id,
    uint256 amount,
    TransferAuthorisationParams calldata transferAuthParams,
    bytes calldata backendSignature
  ) public virtual override whenNotPaused {
    _verifyTransferRequest(transferAuthParams, backendSignature);

    super.safeTransferFrom(from, transferAuthParams.to, id, amount, "");
  }

  function batchTransferFromBackendAuth(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts,
    TransferAuthorisationParams calldata transferAuthParams,
    bytes calldata backendSignature
  ) public virtual override whenNotPaused {
    _verifyTransferRequest(transferAuthParams, backendSignature);

    super.safeBatchTransferFrom(from, transferAuthParams.to, ids, amounts, "");
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  )
    external
    virtual
    override
    whenNotPaused
    onlyIMPTRole(LibIMPT.IMPT_MINTER_ROLE, AccessManager)
  {
    InventoryContract.updateTotalMinted(id, amount);
    _mint(to, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    external
    virtual
    override
    whenNotPaused
    onlyIMPTRole(LibIMPT.IMPT_MINTER_ROLE, AccessManager)
  {
    for (uint8 i = 0; i < ids.length; i++) {
      InventoryContract.updateTotalMinted(ids[i], amounts[i]);
    }
    _mintBatch(to, ids, amounts, data);
  }

  /// @dev Concats the provided baseUri with the address of the contract in the following form: `${baseURL}/${address(this)}`
  /// @param _baseUri The base uri to use
  /// @return formattedBaseUri The formatted base uri
  function _formatBaseUri(
    string memory _baseUri
  ) internal view returns (string memory formattedBaseUri) {
    formattedBaseUri = string.concat(
      _baseUri,
      "/",
      StringsUpgradeable.toHexString(uint256(uint160(address(this))), 20)
    );
  }

  function setBaseUri(
    string calldata _baseUri
  ) external override onlyIMPTRole(LibIMPT.DEFAULT_ADMIN_ROLE, AccessManager) {
    string memory formattedBaseUri = _formatBaseUri(_baseUri);
    // Set the URI on the base ERC1155 contract and pull it from there using the uri() method when needed
    super._setURI(formattedBaseUri);

    emit BaseUriUpdated(formattedBaseUri);
  }

  function setMarketplaceContract(
    IMarketplace _marketplaceContract
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_marketplaceContract));

    MarketplaceContract = _marketplaceContract;

    emit MarketplaceContractChanged(_marketplaceContract);
  }

  function setSoulboundContract(
    ISoulboundToken _soulboundContract
  ) public override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_soulboundContract));

    SoulboundContract = _soulboundContract;

    emit SoulboundContractChanged(_soulboundContract);
  }

  function setInventoryContract(
    IInventory _inventoryContract
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_inventoryContract));

    InventoryContract = _inventoryContract;

    emit InventoryContractChanged(_inventoryContract);
  }

  function pause()
    external
    override
    onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager)
  {
    _pause();
  }

  function unpause()
    external
    override
    onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager)
  {
    _unpause();
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    returns (bool isOperator)
  {
    // This allows the marketplace contract to manage user's NFTs during sales without users having to approve their NFTs to the marketplace contract
    if (msg.sender == address(MarketplaceContract)) {
      return true;
    }

    // otherwise, use the default ERC1155.isApprovedForAll()
    return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC1155Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return ERC1155Upgradeable.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "../interfaces/IInventory.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./libraries/LibIMPT.sol";

contract Inventory is IInventory, Initializable, UUPSUpgradeable {
  address public override stableWallet;

  // Mapping tokenID to storage values in struct
  mapping(uint256 => TokenDetails) public tokenDetails;

  CarbonCreditNFT public override nftContract;
  IAccessManager public override AccessManager;

  /// @dev modifies function so that it is only callable by the stable wallet
  modifier onlyStableWallet() {
    if (msg.sender != stableWallet) {
      revert UnauthorizedCall();
    }
    _;
  }

  /// @dev modifies function so that it is only callable by the Carbon Credit NFT contract
  modifier onlyNftContract() {
    if (msg.sender != address(nftContract)) {
      revert UnauthorizedCall();
    }
    _;
  }

  /// @dev modifies a function so that it is only callable by a user with the correct roles
  modifier onlyIMPTRole(bytes32 _role, IAccessManager _AccessManager) {
    LibIMPT._hasIMPTRole(_role, msg.sender, AccessManager);
    _;
  }

  function initialize(
    InventoryConstructorParams memory _params
  ) external initializer {
    LibIMPT._checkZeroAddress(_params.stableWallet);
    LibIMPT._checkZeroAddress(address(_params.nftContract));
    LibIMPT._checkZeroAddress(address(_params.AccessManager));
    __UUPSUpgradeable_init();

    AccessManager = _params.AccessManager;

    stableWallet = _params.stableWallet;
    nftContract = _params.nftContract;
  }

  function setStableWallet(
    address _stableWallet
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(_stableWallet);
    stableWallet = _stableWallet;
    emit UpdateWallet(_stableWallet);
  }

  function setNftContract(
    CarbonCreditNFT _nftContract
  ) external override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {
    LibIMPT._checkZeroAddress(address(_nftContract));
    nftContract = _nftContract;
  }

  /// @dev This function is to check that the upgrade functions in UUPSUpgradeable are being called by an address with the correct role
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyIMPTRole(LibIMPT.IMPT_ADMIN_ROLE, AccessManager) {}

  function updateTotalMinted(
    uint256 _tokenId,
    uint256 _amount
  ) external override onlyNftContract {
    TokenDetails memory token = tokenDetails[_tokenId];
    if (
      _amount > token.totalSupply - (token.tokensMinted + token.imptBurnCount)
    ) {
      revert NotEnoughSupply();
    }
    tokenDetails[_tokenId].tokensMinted += _amount;
    emit TotalSupplyUpdated(_tokenId, _amount);
  }

  function updateTotalSupply(
    uint256 _tokenId,
    uint256 _amount
  ) public override onlyStableWallet {
    tokenDetails[_tokenId].totalSupply = _amount;
    emit TotalSupplyUpdated(_tokenId, _amount);
  }

  function updateBulkTotalSupply(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) public override onlyStableWallet {
    // NOTE: Gas usage on this function is less than calling above function x times (see unit tests)
    for (uint16 i; i < _tokenIds.length; i++) {
      updateTotalSupply(_tokenIds[i], _amounts[i]);
    }
  }

  function getAllTokenDetails(
    uint256[] memory _tokenIds
  ) external view override returns (TokenDetails[] memory _tokenDetails) {
    TokenDetails[] memory supplies = new TokenDetails[](_tokenIds.length);
    for (uint16 i; i < _tokenIds.length; i++) {
      supplies[i] = tokenDetails[_tokenIds[i]];
    }
    return supplies;
  }

  function incrementBurnCount(
    uint256 _tokenId,
    uint256 _amount
  ) external override onlyNftContract {
    TokenDetails storage newTokenDetail = tokenDetails[_tokenId];
    newTokenDetail.imptBurnCount += _amount;
    newTokenDetail.tokensMinted -= _amount;
    tokenDetails[_tokenId] = newTokenDetail;
    emit BurnCountUpdated(_tokenId, _amount);
  }

  function confirmBurnCounts(
    uint256 _tokenId,
    uint256 _amount
  ) public override onlyStableWallet {
    uint256 retireCount = tokenDetails[_tokenId].imptBurnCount;
    if (retireCount == 0) {
      revert AmountMustBeMoreThanZero();
    }
    if (_amount == 0) {
      revert AmountMustBeMoreThanZero();
    }
    tokenDetails[_tokenId].imptBurnCount -= _amount;
    emit BurnSent(_tokenId, _amount);
  }

  function bulkConfirmBurnCounts(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) public override onlyStableWallet {
    for (uint16 i; i < _tokenIds.length; i++) {
      confirmBurnCounts(_tokenIds[i], _amounts[i]);
    }
  }

  function confirmAndUpdate(
    uint256 _tokenId,
    uint256 _newTotalSupply,
    uint256 _confirmedBurned
  ) public override onlyStableWallet {
    confirmBurnCounts(_tokenId, _confirmedBurned);
    updateTotalSupply(_tokenId, _newTotalSupply);
  }

  function bulkConfirmAndUpdate(
    uint256[] memory _tokenIds,
    uint256[] memory _newTotalSupplies,
    uint256[] memory _confirmedBurnAmount
  ) public override onlyStableWallet {
    bulkConfirmBurnCounts(_tokenIds, _confirmedBurnAmount);
    updateBulkTotalSupply(_tokenIds, _newTotalSupplies);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../interfaces/IAccessManager.sol";

/// @title LibIMPT
/// @author Github: Labrys-Group
/// @dev Library for implementing frequently re-used functions, errors, events and data structures / state in IMPT
library LibIMPT {
  //######################
  //#### PUBLIC STATE ####

  bytes32 public constant IMPT_ADMIN_ROLE = keccak256("IMPT_ADMIN_ROLE");
  bytes32 public constant IMPT_BACKEND_ROLE = keccak256("IMPT_BACKEND_ROLE");
  bytes32 public constant IMPT_APPROVED_DEX = keccak256("IMPT_APPROVED_DEX");
  bytes32 public constant IMPT_MINTER_ROLE = keccak256("IMPT_MINTER_ROLE");
  bytes32 public constant IMPT_SALES_MANAGER = keccak256("IMPT_SALES_MANAGER");
  bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0);

  //################
  //#### ERRORS ####

  ///@dev Thrown when _checkZeroAddress is called with the zero addres.
  error CannotBeZeroAddress();
  ///@dev Thrown when an auth signature from the IMPT back-end is invalid
  error InvalidSignature();
  ///@dev Thrown when an auth signature from the IMPT back-end  has expired
  error SignatureExpired();

  /// @dev Thrown when a custom checkRole function is used and the caller does not have the required role
  error MissingRole(bytes32 _role, address _account);

  ///@dev Emitted when the IMPT treasury changes
  event IMPTTreasuryChanged(address _implementation);

  //############################
  //#### INTERNAL FUNCTIONS ####

  ///@dev Internal function that checks if an address is zero and reverts if it is.
  ///@param _address The address to check.
  function _checkZeroAddress(address _address) internal pure {
    if (_address == address(0)) {
      revert CannotBeZeroAddress();
    }
  }

  function _hasIMPTRole(
    bytes32 _role,
    address _address,
    IAccessManager _AccessManager
  ) internal view {
    if (!(_AccessManager.hasRole(_role, _address))) {
      revert MissingRole(_role, msg.sender);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title SigRecovery
/// @dev This contract provides some helpers for signature recovery
library SigRecovery {
  /// @dev This method prefixes the provided message parameter with the message signing prefix, it also hashes the result as this hash is used in signature recovery
  /// @param _message The message to prefix
  function prefixMessageHash(
    bytes32 _message
  ) internal pure returns (bytes32 prefixedMessageHash) {
    prefixedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _message)
    );
  }

  /// @dev This method splits the signature, extracting the r, s and v values
  /// @param _sig The signature to split
  function splitSignature(
    bytes memory _sig
  ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(_sig.length == 65, "Sig: Invalid signature length");

    assembly {
      // First 32 bytes holds the signature length, skips first 32 bytes as that is the prefix
      r := mload(add(_sig, 32))
      // Gets the following 32 bytes of the signature
      s := mload(add(_sig, 64))
      // Get the final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(_sig, 96)))
    }
  }

  /// @dev This method prefixes the provided message hash, splits the signature and uses ecrecover to return the signing address
  /// @param _message The message that was signed
  /// @param _signature The signature
  function recoverAddressFromMessage(
    bytes memory _message,
    bytes memory _signature
  ) internal pure returns (address recoveredAddress) {
    bytes32 hashOfMessage = prefixMessageHash(keccak256(_message));

    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    recoveredAddress = ecrecover(hashOfMessage, v, r, s);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

/// @title Interface for the AccessManager Smart Contract
/// @author Github: Labrys-Group
/// @notice Utilised to house all authorised accounts within the IMPT contract eco-system
interface IAccessManager is IAccessControlEnumerable {
  struct ConstructorParams {
    address superUser;
  }

  /// @dev throws when the array lengths do not match when bulk granting roles
  error ArrayLengthMismatch();

/// @dev used to grant roles to specific addresses in bulk
/// @param _roles an array of roles encoded into bytes
/// @param _addresses the addresses to grant the roles to, in order of roles listed
  function bulkGrantRoles(
    bytes32[] calldata _roles,
    address[] calldata _addresses
  ) external;

/// @dev sets the admin role for approved DEX and Sales Managers
  function transferDEXRoleAdmin() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "./IMarketplace.sol";
import "./IAccessManager.sol";
import "./IInventory.sol";
import "./ISoulboundToken.sol";

/// @title ICarbonCreditNFT
/// @author Github: Labrys-Group
/// @dev This interface represents a carbon credit non-fungible token (NFT). It extends the IERC1155 interface to allow for the creation and management of carbon credits.
interface ICarbonCreditNFT is IERC1155Upgradeable {
  /// @dev The `TransferAuthorisationParams` struct holds the parameters required to authorisation a token transfer, this struct will be signed by a backend wallet. Only KYCed users can hold CarbonCreditNFT's and this authorisation ensures that the Backend has checked that the 'to' address belongs to a KYCed user
  /// @param expiry representing the request UNIX expiry time
  /// @param to The receiver of the transfer
  struct TransferAuthorisationParams {
    uint40 expiry;
    address to;
  }

  /// @dev The `ConstructorParams` struct holds the parameters that are required to be passed to the contract's constructor.
  /// @param superUser The address of the superuser of the contract.
  /// @param baseURI The base URI for the NFT contract
  struct ConstructorParams {
    address superUser;
    address platformAdmin;
    string baseURI;
    IAccessManager AccessManager;
    string name;
    string symbol;
  }

  //################
  //#### ERRORS ####
  //

  /// @dev The `MustBeMarketplaceContract` error is thrown if the contract being interacted with is not the marketplace contract
  error MustBeMarketplaceContract();

  /// @dev This error is thrown when calling the safeTransferFrom or safeBatchTransferFrom with the standard ERC1155 transfer parameters. This is disabled because we require a backend signature in order to transfer tokens, this requires disabling the base method and overloading it with a new one that includes the additional parameters
  error TransferMethodDisabled();

  //###################
  //#### FUNCTIONS ####
  /// @dev Returns the token uri for the provided token id
  /// @param _id The token id for which the URI is being retrieved.
  /// @return The token URI for the provided token id.
  function uri(uint256 _id) external view returns (string memory);

  /// @dev Allows user's with the IMPT_MINTER_ROLE to mint tokens. This function creates new tokens and assigns them to the specified address.
  /// @param _to The address to which the new tokens should be assigned.
  /// @param _id The token id for the new tokens being minted.
  /// @param _amount The number of tokens being minted.
  /// @param _data Optional data pass through incase we develop the token hooks later on
   /// @dev checks the inventory contract for available supply and updates accordingly after minting
  /// @dev This function is only callable when the contract is not paused
  function mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external;

  /// @dev Burns the NFT token and increments retire/burn counts for soulbound and inventory contracts, respectively
  /// @param _tokenId the Carbon Credit NFT token ID to burn
  /// @param _amount the amount of a given token ID to burn
  /// @dev This function is only callable when the contract is not paused
  function retire(uint256 _tokenId, uint256 _amount) external;

  /// @dev Allows user's with the IMPT_MINTER_ROLE to batch mint multiple token id's with varying amounts to a specified user. This function creates new tokens and assigns them to the specified address.
  /// @param _to The address to which the new tokens should be assigned.
  /// @param _ids An array of token id's for the new tokens being minted.
  /// @param _amounts An array of the number of tokens being minted for each corresponding token id in the ids array.
  /// @param _data Optional data pass through incase we develop the token hooks later on
  /// @dev checks the inventory contract for available supply and updates accordingly after minting
  /// @dev This function is only callable when the contract is not paused
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;

  /// @dev Allows user's to transfer their CarbonCreditNFT to a KYCed user. The TransferAuthorisationParams contains the destination to address and the backendSignature ensures that the backend has validated the address to be a KYCed user.
  /// @param _from The from address
  /// @param _id The tokenId to transfer
  /// @param _amount The amount of tokenId's to transfer
  /// @param _backendSignature The signed TransferAuthorisationParams by the backend
  /// @param _transferAuthParams The transfer parameters
  /// @dev This function is only callable when the contract is not paused
  function transferFromBackendAuth(
    address _from,
    uint256 _id,
    uint256 _amount,
    TransferAuthorisationParams calldata _transferAuthParams,
    bytes calldata _backendSignature
  ) external;

  /// @dev Allows user's to transfer multiple CarbonCreditNFT's to a KYCed user. The TransferAuthorisationParams contains the destination to address and the backendSignature ensures that the backend has validated the address to be a KYCed user.
  /// @param _from The from address
  /// @param _ids The id's to transfer
  /// @param _amounts Equivalent length array containing the amount of each tokenId to transfer
  /// @param _backendSignature The signed TransferAuthorisationParams by the backend
  /// @param _transferAuthParams The transfer parameters
  /// @dev This function is only callable when the contract is not paused
  function batchTransferFromBackendAuth(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    TransferAuthorisationParams calldata _transferAuthParams,
    bytes calldata _backendSignature
  ) external;

  //################
  //#### EVENTS ####

  /// @dev The `MarketplaceContractChanged` event is emitted whenever the contract's associated marketplace contract is changed.
  /// @param _implementation The new implementation of the marketplace contract.
  event MarketplaceContractChanged(IMarketplace _implementation);

  /// @dev The `InventoryContractChanged` event is emitted whenever the contract's associated inventory contract is changed.
  /// @param _implementation The new implementation of the inventory contract.
  event InventoryContractChanged(IInventory _implementation);

  /// @dev The `SoulboundContractChanged` event is emitted whenever the contract's associated soulbound token contract is changed.
  /// @param _implementation The new implementation of the soulbound contract.
  event SoulboundContractChanged(ISoulboundToken _implementation);

  /// @dev The `BaseURIUpdated` event is emitted whenever the contract's baseUri is updated
  /// @param _baseUri The new baseUri to set
  event BaseUriUpdated(string _baseUri);

  //##########################
  //#### SETTER-FUNCTIONS ####

  /// @dev The `setBaseUri` function sets the baseURI for the contract, the provided baseUri is concatted with the address of the contract so that the uri for tokens is: `${baseUri}/${address(this)}/${tokenId}`
  /// @param _baseUri The new base uri for the contract
  function setBaseUri(string calldata _baseUri) external;

  /// @dev The `setMarketplaceContract` function sets the marketplace contract
  /// @param _marketplaceContract The new implementation of the marketplace contract.
  function setMarketplaceContract(IMarketplace _marketplaceContract) external;

  /// @dev The `setInventoryContract` function sets the inventory contract
  /// @param _inventoryContract The new implementation of the inventory contract.
  function setInventoryContract(IInventory _inventoryContract) external;

  /// @dev The `setSoulboundContract` function sets the soulbound token contract
  /// @param _soulboundContract The new implementation of the soulbound token contract.
  function setSoulboundContract(ISoulboundToken _soulboundContract) external;

  /// @dev This function allows the platform admin to pause the contract.
  function pause() external;

  /// @dev This function allows the platform admin to unpause the contract.
  function unpause() external;

  //################################
  //#### AUTO-GENERATED GETTERS ####
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /// @dev The `MarketplaceContract` function returns the address of the contract's associated marketplace contract.
  ///@return implementation The address of the contract's associated marketplace contract.
  function MarketplaceContract()
    external
    view
    returns (IMarketplace implementation);

  /// @dev This function returns the address of the IMPT Access Manager contract
  ///@return implementation The address of the contract's associated AccessManager contract.
  function AccessManager()
    external
    view
    returns (IAccessManager implementation);

  /// @dev The `InventoryContract` function returns the address of the contract's associated inventory contract.
  ///@return implementation The address of the contract's associated inventory contract.
  function InventoryContract()
    external
    view
    returns (IInventory implementation);

  /// @dev The `SoulboundContract` function returns the address of the contract's associated inventory contract.
  ///@return implementation The address of the contract's associated inventory contract.
  function SoulboundContract()
    external
    view
    returns (ISoulboundToken implementation);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "../implementations/CarbonCreditNFT.sol";
import "./IAccessManager.sol";

interface IInventory {
  struct InventoryConstructorParams {
    address stableWallet;
    CarbonCreditNFT nftContract;
    IAccessManager AccessManager;
  }

  /// @dev stores the starge details for a particular token ID
  struct TokenDetails {
    uint256 totalSupply;
    uint256 tokensMinted;
    uint256 imptBurnCount;
  }

  //####################################
  //#### ERRORS #######################
  //####################################
  /// @dev reverts if the function is called by an unauthorized address
  error UnauthorizedCall();

  /// @dev reverts function if updating totals will result in negatives (to be used where functions might panic instead)
  error TotalMismatch();

  /// @dev reverts function if amount is less than 0
  error AmountMustBeMoreThanZero();

  /// @dev reverts a function if there is not enough total supply for a given token
  error NotEnoughSupply();

  //###################################
  //#### EVENTS #######################
  //###################################
  /// @dev emits when the burn count has been updated
  /// @param _tokenId the id of the token whose burn count has been updated
  /// @param _amount the number of tokens burned
  event BurnCountUpdated(uint256 _tokenId, uint256 _amount);

  /// @dev emits when the burn count has been sent to Thallo
  /// @param _tokenId the id of the token whose burn count has been sent
  /// @param _amount the number of tokens sent to be burned by Thallo
  event BurnSent(uint256 _tokenId, uint256 _amount);

  /// @dev emits when the burn count has been confirmed by Thallo
  /// @param _tokenId the id of the token whose burn count is confirmed
  /// @param _amount the amount of tokens confirmed burned by Thallo
  event BurnConfirmed(uint256 _tokenId, uint256 _amount);

  /// @dev emits when the total supply has been sent by Thallo
  /// @param _tokenId the id of the token whose supply has been updated
  /// @param _newSupply the updated total supply of the token
  event TotalSupplyUpdated(uint256 indexed _tokenId, uint256 _newSupply);

  /// @dev emits when the stable wallet has been updated
  /// @param _newStableWallet the address of the new stable walelt
  event UpdateWallet(address _newStableWallet);

  //####################################
  //#### FUNCTIONS #####################
  //####################################
  /// @dev updates the total supply of a given token ID, as given by Thallo
  /// @param _tokenId the Carbon Credit NFT's token ID (ERC-1155)
  /// @param _amount the amount that the total will be set to
  function updateTotalSupply(uint256 _tokenId, uint256 _amount) external;

  /// @dev updates the total supply of a given token ID, as given by Thallo
  /// @param _tokenIds an array of the Carbon Credit NFT's token IDs (ERC-1155)
  /// @param _amounts an array of the amounts that the total will be set to
  function updateBulkTotalSupply(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) external;

  /// @dev returns the total supply of a given token ID
  /// @param _tokenIds an array of the Carbon Credit NFT's token IDs (ERC-1155)
  function getAllTokenDetails(
    uint256[] memory _tokenIds
  ) external view returns (TokenDetails[] memory);

  /// @dev updates the IMPT burn count when a carbon NFT is retired
  /// @param _tokenId the token ID for update burn counts for
  /// @param _amount the amount to increment the burn count by
  function incrementBurnCount(uint256 _tokenId, uint256 _amount) external;

  /// @dev this function calls the confirm burn counts and update total supply functions in a single transaction
  /// @param _tokenId the Carbon Credit NFT token ID
  /// @param _newTotalSupply the amount to which to total supply will be set
  /// @param _confirmedBurned the amount that Thallo has confirmed burned on their end
  function confirmAndUpdate(
    uint256 _tokenId,
    uint256 _newTotalSupply,
    uint256 _confirmedBurned
  ) external;

  function bulkConfirmAndUpdate(
    uint256[] memory _tokenIds,
    uint256[] memory _newTotalSupplies,
    uint256[] memory _confirmedBurns
  ) external;

  /// @dev Updates total when Thallo confirms the number of tokens burned to IMPT
  /// @param _tokenId the Carbon Credit NFT's token ID (ERC-1155)
  /// @param _amount the amount of tokens Thallo has burned
  function confirmBurnCounts(uint256 _tokenId, uint256 _amount) external;

  /// @dev Updates totals in bulk when Thallo confirms the number of tokens burned to IMPT
  /// @param _tokenIds the Carbon Credit NFT's token IDs (ERC-1155)
  /// @param _amounts the amounts of tokens Thallo has burned
  function bulkConfirmBurnCounts(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) external;

  /// @dev The wallet that is able to sign contracts on behalf of IMPT
  /// @param _stableWallet the wallet address
  function setStableWallet(address _stableWallet) external;

  /// @dev The wallet that is able to sign contracts on behalf of IMPT
  /// @param _nftContract the address of the carbon credit NFT
  function setNftContract(CarbonCreditNFT _nftContract) external;

  /// @dev decrements the total supply, to be called whenever carbon credit tokens are minted
  /// @param _tokenId the id of the token id that needs to be decremented
  /// @param _amount the amount by which to decrement the total supply
  function updateTotalMinted(uint256 _tokenId, uint256 _amount) external;

  //####################################
  //#### GETTERS #######################
  //####################################
  /// @dev The stable wallet is an admin-controlled wallet
  function stableWallet() external returns (address);

  /// @dev The nftContract is the Carbon Credit NFT
  function nftContract() external returns (CarbonCreditNFT);

  /// @dev This function returns the address of the IMPT Access Manager contract
  function AccessManager()
    external
    view
    returns (IAccessManager implementation);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ICarbonCreditNFT.sol";
import "../interfaces/IAccessManager.sol";

/// @title Interface for the IMarketplace Smart Contract
/// @author Github: Labrys-Group
interface IMarketplace {
  //################
  //#### STRUCTS ###

  /// @dev This struct represents the parameters required to construct a marketplace contract.
  /// @param superUser The address of the superuser of the contract
  /// @param platformAdmin The address of the platform admin of the contract
  /// @param CarbonCreditNFT The address of the carbon credit NFT contract
  /// @param IMPTAddress The address of the IMPT ERC20 contract
  /// @param IMPTTreasuryAddress The address of the IMPT treasury contract
  struct ConstructorParams {
    ICarbonCreditNFT CarbonCreditNFT;
    IERC20 IMPTAddress;
    address IMPTTreasuryAddress;
    IAccessManager AccessManager;
  }

  /// @dev This struct represents a sale order for carbon credits
  /// @param saleOrderId The unique identifier for this sale order, this will be invalidated within the method to ensure no double-spends
  /// @param tokenId The token ID of the carbon credit being sold
  /// @param amount The amount of carbon credits being sold
  /// @param salePrice The price at which the carbon credits are being sold
  /// @param expiry The expiration timestamp for this sale order
  /// @param seller The address of the seller
  struct SaleOrder {
    bytes24 saleOrderId;
    uint256 tokenId;
    uint256 amount;
    uint256 salePrice;
    uint40 expiry;
    address seller;
  }

  /// @dev This struct contains the authorisation parameters for a sale request, this will be provided along with a SaleOrder. This struct will be signed by the backend, as it will check if the 'to' address is KYCed and the expiry will ensure the request cannot live too long
  /// @param expiry This authorisation expiry will be a short duration ~5 mins and allows users to delist their tokens or change the sell order without risking another user saving the sellerSignature to be executed later on
  /// @param to The address that will receive the purchased tokens
  struct AuthorisationParams {
    uint40 expiry;
    address to;
  }

  //####################################
  //#### ERRORS #######################
  //####################################

  /// @dev This error is thrown when a sale order has expired.
  error SaleOrderExpired();

  /// @dev This error is thrown when the seller does not have sufficient carbon credits to fulfill the sale.
  error InsufficientSellerCarbonCreditBalance();

  /// @dev This error is thrown when the buyer does not have sufficient balance of IMPT to fulfill the purchase.
  error InsufficientTokenBalance();

  /// @dev This error is thrown when a sale order with the same ID has already been used.
  error SaleOrderIdUsed();

  /// @dev This error is thrown when a user is trying to use AuthorisationParams where the to address doesn't match the msg.sender
  error InvalidBuyer();

  //####################################
  //#### EVENTS #######################
  //####################################

  /// @dev This event is emitted when a carbon credit sale is completed.
  /// @param _saleOrderId The unique identifier for the sale order.
  /// @param _tokenId The token ID of the carbon credit being sold.
  /// @param _amount The amount of carbon credits being sold.
  /// @param _salePrice The price at which the carbon credits were sold.
  /// @param _seller The address of the seller.
  /// @param _buyer The address of the buyer.
  event CarbonCreditSaleCompleted(
    bytes24 _saleOrderId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _salePrice,
    address indexed _seller,
    address indexed _buyer
  );

  /// @dev This event is emitted when the royalty percentage changes.
  /// @param _royaltyPercentage The new royalty percentage.
  event RoyaltyPercentageChanged(uint256 _royaltyPercentage);

  //####################################
  //#### SETTER-FUNCTIONS #############
  //####################################

  /// @dev This function allows the platform admin to set the address of the IMPT treasury contract.
  /// @param _implementation The address of the IMPT treasury contract.
  function setIMPTTreasury(address _implementation) external;

  /// @dev This function allows the platform admin to set the royalty percentage.
  /// @param _royaltyPercentage The new royalty percentage.
  function setRoyaltyPercentage(uint256 _royaltyPercentage) external;

  /// @dev This function allows the platform admin to pause the contract.
  function pause() external;

  /// @dev This function allows the platform admin to unpause the contract.
  function unpause() external;

  //####################################
  //#### AUTO-GENERATED GETTERS #######
  //####################################

  /// @dev This function returns the address of the IMPT ERC20 contract.
  /// @return _implementation The address of the IMPT ERC20 contract.
  function IMPTAddress() external returns (IERC20 _implementation);

  /// @dev This function returns the address of the carbon credit NFT contract.
  /// @return _implementation The address of the carbon credit NFT contract.
  function CarbonCreditNFT() external returns (ICarbonCreditNFT _implementation);

  /// @dev This function returns the address of the IMPT treasury contract.
  /// @return _implementation The address of the IMPT treasury contract.
  function IMPTTreasuryAddress() external returns (address _implementation);

  /// @dev This function returns whether the specified sale order ID has been used.
  /// @param _saleOrderId The sale order ID to check.
  /// @return used True if the sale order ID has been used, false otherwise.
  function usedSaleOrderIds(bytes24 _saleOrderId) external returns (bool used);

  /// @dev This function returns the address of the IMPT Access Manager contract
  function AccessManager() external returns (IAccessManager implementation);

  /// @dev This method executes the provided sale order, charging the seller their sale amount and transferring the msg.sender the tokens. It also takes a royalty percentage from the sale and transfers it to the IMPT treasury. This method also ensures that the _authorisationParams.to == msg.sender
  /// @param _authorisationParams The authorisation parameters from the backend
  /// @param _authorisationSignature The signed saleOrder + authorisationParams
  /// @param _saleOrder The sale order details
  /// @param _sellerOrderSignature The seller's signature
  function purchaseToken(
    AuthorisationParams calldata _authorisationParams,
    bytes calldata _authorisationSignature,
    SaleOrder calldata _saleOrder,
    bytes calldata _sellerOrderSignature
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/ICarbonCreditNFT.sol";
import "../interfaces/IAccessManager.sol";

/// @dev Interface for a soulbound token which is non-transferrable and closely follows the 721 standard.
/// @dev It also manages the token types and formatting of metadata responses
interface ISoulboundToken is IERC165 {
  //################
  //#### STRUCTS ####
  /// @dev The `ConstructorParams` struct holds the parameters that are required to be passed to the contract's constructor.
  /// @param name_ The token name
  /// @param symbol_ The token symbol
  /// @param description_ The description of the token
  /// @param _carbonCreditContract The address of the carbon credit contract (must match interface specs)
  /// @param adminAddress The address that will be assigned to the role IMPT_ADMIN
  struct ConstructorParams {
    string name_;
    string symbol_;
    string description_;
    ICarbonCreditNFT _carbonCreditContract;
    IAccessManager AccessManager;
  }

  /// @dev The required fields for each tokenType. Each tokenType exists in the CarbonCreditNFT contract as a subcollection
  /// @param displayName Unique display name for the token type
  /// @param tokenId The id of the TokenType in the CarbonCreditNFT contract
  struct TokenType {
    string displayName;
    uint256 tokenId;
  }

  //################
  //#### EVENTS ####
  /// @dev This emits ONLY when token `_tokenId` is minted from the zero address and is used to conform closely to ERC721 standards
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /// @dev Emits when the Carbon Credit contract has been updated
  event CarbonNftContractUpdated(ICarbonCreditNFT _newAddress);

  /// @dev Emits when the user's retire count for a given token ID is updated
  event RetireCountUpdated(address _owner, uint256 _tokenId, uint256 _amount);

  /// @dev Emits when a new token type is added
  event TokenTypeAdded(ISoulboundToken.TokenType _tokenType);

  /// @dev Emits when a new token type is removed
  event TokenTypeRemoved(uint256 _tokenId);

  //################
  //#### ERRORS ####
  /// @dev UnauthorizedCall throws an error if a call is made from an address without the correct role
  error UnauthorizedCall();

  /// @dev HasToken error is thrown if the target wallet for minting already has a token
  error HasToken();

  /// @dev TokenIdNotFound throws when passing a token ID into a function that does not exist
  error TokenIdNotFound();

  /// @dev NoTokenTypes throws if there have not been any token types added before trying to remove token types
  error NoTokenTypes();

  //##########################
  //#### CUSTOM FUNCTIONS ####
  /// @notice mints a new soulbound token
  /// @param _to the address to send the token to
  /// @param _imageURI the image URI for the token, to be included in the metadata
  function mint(address _to, string calldata _imageURI) external;

  /// @notice Increments the user's burned token count to be displayed in soulbound token metadata
  /// @param _user Address of the user whos burned count needs to be updated
  /// @param _tokenId The soulbound token ID owned by the user above
  /// @param _amount The amount by which to increase the user burned count
  function incrementRetireCount(
    address _user,
    uint256 _tokenId,
    uint256 _amount
  ) external;

  /// @notice returns all the current token types
  function getAllTokenTypes()
    external
    view
    returns (ISoulboundToken.TokenType[] memory);

  /// @notice adds a new token type
  /// @param _tokenType the data to add to the end of the token types array
  function addTokenType(TokenType calldata _tokenType) external;

  /// @notice removes token type from the array. If the token is not at the end of the array, the element at the end of the array is moved to the deleted item's position
  /// @param _tokenId the token ID of the token type, as from the CarbonCreditNFT
  function removeTokenType(uint256 _tokenId) external;

  /// @notice updates the carbon credit contract implementation
  /// @param _carbonCreditContract the new implementation of the carbon credit NFT
  function setCarbonCreditContract(
    ICarbonCreditNFT _carbonCreditContract
  ) external;

  /// @dev returns the current count of the token IDs (in other words, the next token ID to be minted)
  function getCurrentTokenId() external view returns (uint256);

  //###########################
  //#### ERC-721 FUNCTIONS ####
  /// @notice Returns the total amount of tokens for the provided user, can only ever be 0 or 1
  /// @param _owner An address for whom to query the balance
  /// @return The number of tokens owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint256);

  /// @notice Find the owner of a token
  /// @dev tokens assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for a token
  /// @return The address of the owner of the token
  function ownerOf(uint256 _tokenId) external view returns (address);

  /// @notice The name of the Account Bound Token contract
  function name() external view returns (string memory);

  /// @notice The symbol of the Account Bound Token contract
  function symbol() external view returns (string memory);

  /// @notice The symbol of the Account Bound Token contract
  function description() external view returns (string memory);

  /// @notice TokenURI contains metadata for the individual token as base64 encoded JSON object
  /// @param _tokenId The token to retrieve a metadata URI for
  function tokenURI(uint256 _tokenId) external view returns (string memory);

  //################################
  //#### AUTO-GENERATED GETTERS ####
  /// @dev This function returns the address of the IMPT Access Manager contract
  ///@return implementation The address of the contract's associated AccessManager contract.
  function AccessManager()
    external
    view
    returns (IAccessManager implementation);

  /// @dev returns the current implementatino of the Carbon Credit NFT contract
  function carbonCreditContract() external view returns (ICarbonCreditNFT);

  /// @dev returns the number of tokens of a particular token ID that a user has burned
  /// @param owner the user's address
  /// @param tokenId the token ID for which to return the burn counts
  function usersBurnedCounts(
    address owner,
    uint256 tokenId
  ) external view returns (uint256);
}