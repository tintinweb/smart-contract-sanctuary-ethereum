// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// SPDX-License-Identifier: MIT
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ProvisioningPool.sol";

contract AuctionMarket is Ownable, ReentrancyGuard {
    event Start(
        ZNftInterface ZNft,
        uint256 id,
        uint256 repayAmount,
        address originalOwner,
        uint256 endTime
    );
    event Bid(
        address indexed bidder,
        ZNftInterface ZNft,
        uint256 id,
        uint256 amount
    );
    event Withdraw(
        address indexed bidder,
        ZNftInterface ZNft,
        uint256 id,
        uint256 amout
    );
    event CloseBid(
        address winnder,
        ZNftInterface ZNft,
        uint256 id,
        uint256 closeAmount
    );

    event IncreaseInsurance(
        ZNftInterface ZNft,
        address account,
        uint256 amount
    );
    event DecreaseInsurance(
        ZNftInterface ZNft,
        address account,
        uint256 amount
    );

    struct AuctionInfo {
        // is auction still going
        bool isOnAuction;
        // the time when the borrower can no longer depay borrow debt to redeem.
        uint256 redeemEndAt;
        // the time when the auction ends and the highest bid gets the NFT.
        uint256 auctionEndAt;
        // highest bidder address
        address highestBidder;
        // highest bidding value
        uint256 highestBid;
        // the balance that the borrower have to repay to redeem the NFT.
        uint256 borrowRepay;
        // address of the borrower who originally own the NFT.
        address borrower;
    }

    address public underlying;
    uint256 public gracePeriod;
    uint256 public auctionDuration;
    uint256 public insuranceGracePeriod;
    uint256 public bidderPenaltyShareBasisPoint; // 10000 = 1%
    uint256 public penaltyBasisPoint; // 10000 = 1%
    uint256 public bidExtension = 10 minutes;

    mapping(address => mapping(uint256 => AuctionInfo)) public auctionInfo; // znft -> id -> Auction info so that this auction market can do auction for all nfts.
    mapping(address => mapping(uint256 => bool)) public insurance; // if true then the NFT is being protected by insurance
    mapping(ZNftInterface => mapping(address => uint256))
        public accountInsurance; // hit points of the users insurance
    mapping(address => bool) public provisioningPools;

    constructor(
        address underlying_,
        uint256 gracePeriod_,
        uint256 insuranceGracePeriod_,
        uint256 auctionDuration_,
        uint256 penaltyBasisPoint_,
        uint256 bidderPenaltyShareBasisPoint_
    ) {
        underlying = underlying_;
        gracePeriod = gracePeriod_;
        insuranceGracePeriod = insuranceGracePeriod_;
        auctionDuration = auctionDuration_;
        penaltyBasisPoint = penaltyBasisPoint_;
        bidderPenaltyShareBasisPoint = bidderPenaltyShareBasisPoint_;
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */
    function setProvisioningPool(address pp, bool state) public onlyOwner {
        provisioningPools[pp] = state;
    }

    /** Pay penalty */
    function redeemAndPayPenalty(uint256 id, ZNftInterface zNftCollateral)
        external
        nonReentrant
    {
        AuctionInfo storage auction = auctionInfo[address(zNftCollateral)][id];
        require(
            block.timestamp < auction.redeemEndAt,
            "AuctionMarket: redemption period over."
        );
        require(
            msg.sender == auction.borrower,
            "AuctionMarket: redeemer not the borrower"
        );
        uint256 repay = auction.borrowRepay;
        uint256 penalty = (repay * penaltyBasisPoint) / 10000;
        address highestBidder = auction.highestBidder;
        repay += penalty;
        IERC20(underlying).transferFrom(msg.sender, address(this), repay);
        if (highestBidder != address(0)) {
            uint256 bidderRefund = auction.highestBid +
                (penalty * bidderPenaltyShareBasisPoint) /
                10000;
            IERC20(underlying).transfer(highestBidder, bidderRefund);
        }
        // return the NFT
        zNftCollateral.safeTransferFrom(address(this), msg.sender, id);

        // end bid, change states. possible reentrancy.
        endBid(id, repay, address(zNftCollateral));
    }

    // @notice This function can be used to initiate an auction
    // @dev only provisioningPool can call this function
    // @param  id  The token Id of the zNftCollateral
    // @param  repayAmount  The balance that the borrower have to repay to make the loan whole.
    // @param  originalOwner  The original owner of the zNftCollateral
    // @param  zNftCollateral The znft being auctioned off
    function startAuction(
        uint256 id,
        uint256 repayAmount,
        address originalOwner,
        ZNftInterface zNftCollateral
    ) public nonReentrant {
        //require(address(zNftCollateral.comptroller()) == comptroller, "comptroller does not match");
        require(
            provisioningPools[msg.sender],
            "AuctionMarket: caller must be a ProvisioningPool"
        );
        require(
            zNftCollateral.ownerOf(id) == address(this),
            "AuctionMarkt: AuctionMarket does not own this NFT."
        );
        require(
            !auctionInfo[address(zNftCollateral)][id].isOnAuction,
            "NFT already on auction."
        );

        // initialize the auction
        auctionInfo[address(zNftCollateral)][id].isOnAuction = true;

        if (accountInsurance[zNftCollateral][originalOwner] > 0) {
            auctionInfo[address(zNftCollateral)][id].redeemEndAt =
                block.timestamp +
                gracePeriod +
                insuranceGracePeriod;
            spendInsurance(zNftCollateral, originalOwner);
        } else {
            auctionInfo[address(zNftCollateral)][id].redeemEndAt =
                block.timestamp +
                gracePeriod;
        }
        // initial auctionEndAt = redeemEndAt
        // which means once redeemEndAt passes, auction ends too
        // if no bidder, extend auctionEndAt by xx hours (who calls?)
        auctionInfo[address(zNftCollateral)][id].auctionEndAt = auctionInfo[
            address(zNftCollateral)
        ][id].redeemEndAt;
        auctionInfo[address(zNftCollateral)][id].borrowRepay = repayAmount;
        auctionInfo[address(zNftCollateral)][id].borrower = originalOwner;

        emit Start(
            zNftCollateral,
            id,
            repayAmount,
            originalOwner,
            auctionInfo[address(zNftCollateral)][id].auctionEndAt
        );
    }

    function bid(
        uint256 id,
        address zNftCollateral,
        uint256 amount
    ) public nonReentrant {
        AuctionInfo storage auction = auctionInfo[zNftCollateral][id];

        require(
            amount > auction.highestBid,
            "AuctionMarket: bid must be higher than the highest bid"
        );

        require(
            amount > auction.borrowRepay,
            "AuctionMarket: bid must be higher than the borrow repay"
        );
        require(
            block.timestamp < auction.auctionEndAt && auction.isOnAuction,
            "AuctionMarket: auction ended"
        );
        address previousHighestBidder = auction.highestBidder;
        uint256 previousHighestBid = auction.highestBid;
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;

        // extend bid time if within the last bidding period.
        if (block.timestamp > auction.auctionEndAt - bidExtension) {
            auction.auctionEndAt = block.timestamp + bidExtension;
        }
        IERC20(underlying).transferFrom(msg.sender, address(this), amount);
        if (previousHighestBidder != address(0)) {
            IERC20(underlying).transfer(
                previousHighestBidder,
                previousHighestBid
            );
        }

        emit Bid(msg.sender, ZNftInterface(zNftCollateral), id, amount);
    }

    function winBid(uint256 id, ProvisioningPool provisioningPool)
        public
        nonReentrant
    {
        ZNftInterface zNftCollateral = provisioningPool.zNftCollateral();
        AuctionInfo storage auction = auctionInfo[address(zNftCollateral)][id];

        require(
            block.timestamp > auction.auctionEndAt,
            "AuctionMarket: auction ongoing"
        );
        require(auction.isOnAuction, "AuctionMarket: auction ended");
        if (auction.highestBidder != address(0)) {
            zNftCollateral.transferFrom(
                address(this),
                auction.highestBidder,
                id
            );
            // end the auction
            endBid(id, auction.highestBid, address(zNftCollateral)); // end bid and replenish money in the Provisioning pool
            IERC20(underlying).transfer(
                address(provisioningPool),
                auction.highestBid
            );
        } else {
            // if no one bids, continue auction
            auction.auctionEndAt = block.timestamp + auctionDuration;
            emit Start(
                zNftCollateral,
                id,
                auction.borrowRepay,
                auction.borrower,
                auction.auctionEndAt
            );
        }
    }

    function endBid(
        uint256 id,
        uint256 closeAmount,
        address zNftCollateral
    ) internal {
        AuctionInfo storage auction = auctionInfo[zNftCollateral][id];
        auction.isOnAuction = false;
        auction.redeemEndAt = 0;
        auction.auctionEndAt = 0;
        auction.borrowRepay = 0;
        auction.highestBidder = address(0);
        auction.highestBid = 0;
        auction.borrower = address(0);
        emit CloseBid(
            auction.highestBidder,
            ZNftInterface(zNftCollateral),
            id,
            closeAmount
        );
    }

    function activateInsurance(
        ZNftInterface zNftCollateralAddress,
        address originalOwner,
        uint256 amount
    ) public {
        accountInsurance[zNftCollateralAddress][originalOwner] += amount;

        emit IncreaseInsurance(zNftCollateralAddress, originalOwner, amount);
    }

    function spendInsurance(
        ZNftInterface zNftCollateralAddress,
        address originalOwner
    ) internal {
        // spend insurance on the event of being liquidatedated
        accountInsurance[zNftCollateralAddress][originalOwner] -= 1; // spend insurance
        emit DecreaseInsurance(zNftCollateralAddress, originalOwner, 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./ZNftInterface.sol";
import "./PriceOracle.sol";
import "./ComptrollerStorage.sol";
import "./ZBond.sol";
import "./ComptrollerInterface.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */

contract Comptroller is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ComptrollerInterface,
    ComptrollerStorage
{
    /// @notice Emitted when an owner supports a market
    event MarketListed(ZNftInterface ZNft, ZBond zBond);

    /// @notice Emitted when close factor is changed by owner
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    /// @notice Emitted when a collateral factor is changed by owner
    event NewCollateralFactor(
        ZNftInterface ZNft,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by owner
    event NewLiquidationIncentive(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(
        PriceOracle oldPriceOracle,
        PriceOracle newPriceOracle
    );

    /// @notice Emitted when price oracle is changed
    event NewNFTPriceOracle(
        NftPriceOracle oldPriceOracle,
        NftPriceOracle newPriceOracle
    );

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(address asset, string action, bool pauseState);

    event DecreasedBalance(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event IncreasedBalance(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 1e18; // 1

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    function initialize() public initializer {
        __Ownable_init();
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param zBond The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     */
    function mintAllowed(
        address zBond,
        address minter,
        uint256 mintAmount
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[zBond], "Comptroller: mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        require(markets[zBond].isListed, "Comptroller: market is not listed");

        // Keep the flywheel moving
        // updateCompSupplyIndex(zBond);
        // distributeSupplierComp(zBond, minter);
    }

    /**
     * @notice Checks if the account should be allowed to redeem zNft tokens
     * @param zNft The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of zNft tokens to exchange for the underlying asset in the market
     */
    function redeemAllowed(
        address zNft,
        address redeemer,
        uint256 redeemTokens
    ) external view override {
        redeemAllowedInternal(zNft, redeemer, redeemTokens);
    }

    function redeemAllowedInternal(
        address asset,
        address redeemer,
        uint256 redeemTokens
    ) internal view {
        require(markets[asset].isListed, "Comptroller: market is not listed");
        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                redeemer,
                asset,
                asset,
                redeemTokens,
                0
            );
        require(
            shortfall == 0,
            "Comptroller: insufficient liquidity to redeem"
        );
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param zBond The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     */
    function borrowAllowed(
        address zBond,
        address borrower,
        uint256 borrowAmount,
        uint256 duration
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[zBond], "Comptroller: borrow is paused");
        require(
            duration < ZBond(zBond).maximumLoanDuration(),
            "Comptroller: borrow term too long"
        );

        // require the caller of this function to be supported zbond
        require(
            markets[address(zBond)].isListed,
            "Comptroller: market is not listed"
        );

        // total borrow has to be lower than the reserved pool.
        require(
            borrowAmount <= ZBond(zBond).provisioningPool().getCashBalance(),
            "Comptroller: cannot borrow more than the provisioning pool"
        );
        require(
            oracle.getUnderlyingPrice(zBond) != 0,
            "Comptroller: asset price == 0"
        );

        uint256 borrowCap = borrowCaps[zBond];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = ZBond(zBond).totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            require(
                nextTotalBorrows < borrowCap,
                "Comptroller: market borrow cap reached"
            );
        }

        address correspondingZNFTAddress = address(ZBond(zBond).ZNft());
        (, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            borrower,
            zBond,
            correspondingZNFTAddress,
            0,
            borrowAmount
        );
        require(
            shortfall == 0,
            "Comptroller: insufficient liquidity to borrow"
        );
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param zBond The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     */
    function repayBorrowAllowed(
        address zBond,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external override {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        require(
            markets[address(zBond)].isListed,
            "Comptroller: market is not listed."
        );
        //decreaseBalance(zBond, borrower, repayAmount);
    }

    /**

        There will be only one NFT being liquidated per overdue.
        This function calculates how much to repay for that one NFT.
        Need to convert credit into the correct unit
        TODO: what if liquidation and overdue conditions both satisfy.
        TODO: change function name to calculateOverdueRepayAmount
    */
    /**
     * @notice Container for borrow balance information
     */
    struct BorrowSnapshot {
        uint256 deadline;
        uint256 loanDuration;
        uint256 minimumPaymentDue;
        uint256 principalBorrow;
        uint256 weightedInterestRate;
    }

    function calculateLiquidationAmount(
        address borrower,
        address zBondBorrowed,
        uint256[] calldata id,
        address ZNft
    ) external view override returns (uint256) {
        // calculate the credit offered by one NFT
        // numNFTs * price * collateralRate
        uint256 nftPriceMantissa = oracle.getUnderlyingPrice(ZNft);
        require(nftPriceMantissa > 0, "Comptroller: asset price == 0");

        uint256 nftCollateralFactor = markets[address(ZNft)]
            .collateralFactorMantissa;
        uint256 maxRepay = (id.length *
            nftCollateralFactor *
            nftPriceMantissa) / 1e18;

        // calculate the borrowed balance equivalent value
        uint256 borrowBalance = ZBond(zBondBorrowed)
            .getAccountCurrentBorrowBalance(borrower);
        uint256 borrowedAssetPriceMantissa = oracle.getUnderlyingPrice(
            zBondBorrowed
        );
        uint256 borrowValue = (borrowBalance * borrowedAssetPriceMantissa) /
            1e18;
        if (maxRepay > borrowValue) {
            // if borrowed asset is less expensive than the NFT, can liquidate all borrow balance
            return borrowBalance;
        } else {
            // if borrowed assets is more expensive than the NFT, can only liquidate the collateral value of NFT
            return (maxRepay * 1e18) / borrowedAssetPriceMantissa;
        }
    }

    /**
     * @notice Calculate number of ZNft tokens to seize given an underlying amount
     * @dev Used in liquidation (called in zBond.liquidateBorrowFreshNft)
     * @param zBondBorrowed The address of the borrowed zBond
     * @param actualRepayAmount The amount of zBondBorrowed underlyin to convert into NFTs
     * @return (errorCode, number of cNft tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeNfts(
        address zBondBorrowed,
        address cNftCollateral,
        uint256 actualRepayAmount
    ) external view override returns (uint256) {
        /* Read oracle prices for borrowed and collateral markets */
        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(
            zBondBorrowed
        );
        uint256 priceCollateralMantissa = nftOracle.getUnderlyingPrice(
            ZNftInterface(cNftCollateral)
        );
        require(
            priceBorrowedMantissa == 0,
            "Comptroller: borrowed assets price is 0."
        );
        require(
            priceCollateralMantissa == 0,
            "Comptroller: nft asset price is 0."
        );
        require(
            1e18 <= liquidationIncentiveMantissa,
            "Comptroller: liquidation insentive less than 1."
        );
        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeTokens = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         */
        uint256 seizeTokens;

        seizeTokens =
            (actualRepayAmount *
                liquidationIncentiveMantissa *
                priceBorrowedMantissa) /
            priceCollateralMantissa /
            1e18;
        return (seizeTokens);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param zBondBorrowed Asset which was borrowed by the borrower
     * @param ZNft Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     */
    function liquidateBorrowAllowed(
        address zBondBorrowed,
        address ZNft,
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) external override {
        // Shh - currently unused
        liquidator;

        require(
            markets[zBondBorrowed].isListed,
            "Comptroller: zBond market not listed"
        );
        require(liquidator != borrower, "Comptroller: Cannot liquidate self");
        require(
            id.length == 1,
            "Comptroller: Can only liquidate 1 NFT a time."
        );
        for (uint256 i = 0; i < id.length; i++) {
            require(
                ZNftInterface(ZNft).ownerOf(id[i]) == borrower,
                "Comptroller: Cannot liquidate NFT that the borrower do not own."
            );
        }
        if (sequenceOfLiquidation[ZNft][borrower].length != 0) {
            uint256 last = sequenceOfLiquidation[ZNft][borrower][
                sequenceOfLiquidation[ZNft][borrower].length - 1
            ];
            sequenceOfLiquidation[ZNft][borrower].pop();
            while (last != id[0]) {
                if (ZNftInterface(ZNft).ownerOf(last) != borrower) {
                    last = sequenceOfLiquidation[ZNft][borrower][
                        sequenceOfLiquidation[ZNft][borrower].length - 1
                    ];
                    sequenceOfLiquidation[ZNft][borrower].pop();
                } else {
                    require(
                        last != id[0],
                        "Comptroller: Not the preferred NFT to be liquidated"
                    ); // TODO: should we throw or should we just assign this NFT to be liquidated
                    //id[0] = last;
                }
            }
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (, uint256 shortfall) = getAccountLiquidityInternal(borrower, ZNft);

        require(shortfall > 0, "Comptroller: no debt to liquidate.");

        // if the credit line is fine, then check overdue

        //require(id.length == 1, "Cannot seize over 1 NFT when overdue");

        BorrowSnapshot memory borrowSnapshot;
        (
            borrowSnapshot.deadline,
            borrowSnapshot.loanDuration,
            borrowSnapshot.minimumPaymentDue,
            borrowSnapshot.principalBorrow,
            borrowSnapshot.weightedInterestRate
        ) = ZBond(zBondBorrowed).accountBorrows(borrower);

        require(
            (shortfall > 0) ||
                (borrowSnapshot.minimumPaymentDue < block.timestamp &&
                    borrowSnapshot.minimumPaymentDue != 0) ||
                (borrowSnapshot.deadline < block.timestamp &&
                    borrowSnapshot.deadline != 0),
            "Comptroller: insufficient shortfall to liquidate or not overdue."
        );
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param ZNftCollateral Asset which was used as collateral and will be seized
     * @param zBondBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address ZNftCollateral,
        address zBondBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "Comptroller: seize is paused");

        // Shh - currently unused
        seizeTokens;
        liquidator;
        borrower;
        require(
            markets[ZNftCollateral].isListed,
            "Comptroller: ZNft collateral is not listed"
        );
        require(
            markets[zBondBorrowed].isListed,
            "Comptroller: ZBond collateral is not listed"
        );
        require(
            ZNftInterface(ZNftCollateral).comptroller() ==
                address(ZBond(zBondBorrowed).comptroller()),
            "Comptroller: comptroller mismatch"
        );
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param zNft The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of zNfts to transfer
     */
    function transferAllowed(
        address zNft,
        address src,
        address dst,
        uint256 transferTokens
    ) external view override {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "Comptroller: transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        redeemAllowedInternal(zNft, src, transferTokens);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account, address ZNft)
        public
        view
        returns (uint256, uint256)
    {
        (
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                account,
                address(0),
                ZNft,
                0,
                0
            );

        return (liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account, address ZNft)
        internal
        view
        returns (uint256, uint256)
    {
        return
            getHypotheticalAccountLiquidityInternal(
                account,
                address(0),
                ZNft,
                0,
                0
            );
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param assetModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address assetModify,
        address ZNft,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) public view returns (uint256, uint256) {
        (
            uint256 liquidity,
            uint256 shortfall
        ) = getHypotheticalAccountLiquidityInternal(
                account,
                assetModify,
                ZNft,
                redeemTokens,
                borrowAmount
            );
        return (liquidity, shortfall);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `zBondBalance` is the number of zBonds the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 zBondBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        uint256 nftOraclePriceMantissa;
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param assetModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemNFTAmount The amount of underlying to hypothetically borrow
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral zBond using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        address assetModify,
        address ZNft,
        uint256 redeemNFTAmount,
        uint256 borrowAmount
    ) internal view returns (uint256, uint256) {
        require(address(oracle) != address(0), "Comptroller: oracle not set");
        require(
            address(nftOracle) != address(0),
            "Comptroller: nft oracle not set"
        );

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        if ((assetModify != ZNft) && assetModify != address(0)) {
            require(
                allMarkets[ZNftInterface(ZNft)][ZBond(assetModify)],
                "Comptroller: markets mismatch"
            );
        }

        // For each ZBond the ZNft corresponds to
        ZBond[] memory assets = ZNftInterface(ZNft).getZBonds();
        for (uint256 i = 0; i < assets.length; i++) {
            ZBond asset = assets[i];

            // Read the balances and exchange rate from the zBond
            vars.borrowBalance = asset.getAccountCurrentBorrowBalance(account);

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(
                address(asset)
            );
            require(
                vars.oraclePriceMantissa != 0,
                "Comptroller: ZBond price is not set."
            );

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects +=
                (vars.oraclePriceMantissa * vars.borrowBalance) /
                1e18;

            // Calculate effects of interacting with zBondModify
            if (address(asset) == assetModify) {
                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects +=
                    (vars.oraclePriceMantissa * borrowAmount) /
                    1e18;
            }
        }

        // calculate znft collateral value with or without changes
        uint256 nftBalance = ZNftInterface(ZNft).balanceOf(account);

        if (nftBalance > 0) {
            // Get the price of the NFT and the collateral factor
            vars.nftOraclePriceMantissa = nftOracle.getUnderlyingPrice(
                ZNftInterface(ZNft)
            );
            require(
                vars.nftOraclePriceMantissa != 0,
                "Comptroller: NFT price cannot be 0."
            );
            // sumCollateral += nftOraclePrice * collateralFactor * nftBalance
            vars.sumCollateral =
                (vars.nftOraclePriceMantissa *
                    markets[address(ZNft)].collateralFactorMantissa *
                    nftBalance) /
                1e18;

            if (assetModify == address(ZNft)) {
                // sumBorrowPlusEffects += nftOraclePrice * collateralFactor * redeemTokens
                vars.sumBorrowPlusEffects +=
                    (vars.nftOraclePriceMantissa *
                        markets[address(ZNft)].collateralFactorMantissa *
                        redeemNFTAmount) /
                    1e18;
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    function changeSequenceOfLiquidation(
        ZNftInterface ZNft,
        uint256[] calldata sequence
    ) public {
        require(
            markets[address(ZNft)].isListed,
            "Comptroller: NFT not supported"
        );
        for (uint256 i = 0; i < sequence.length; i++) {
            require(
                ZNft.ownerOf(sequence[i]) == msg.sender,
                "Comptroller: sender does not own this NFT."
            );
        }
        sequenceOfLiquidation[address(ZNft)][msg.sender] = sequence;
    }

    /*** Owner Functions ***/

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Owner function to set a new price oracle
     */
    function _setPriceOracle(PriceOracle newOracle) public onlyOwner {
        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);
    }

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Owner function to set a new price oracle
     */
    function _setNftPriceOracle(NftPriceOracle newOracle_) public onlyOwner {
        // Track the old oracle for the comptroller
        NftPriceOracle oldOracle = nftOracle;
        // Set comptroller's nft oracle to newOracle
        nftOracle = newOracle_;

        emit NewNFTPriceOracle(oldOracle, newOracle_);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Owner function to set closeFactor
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     */
    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        onlyOwner
    {
        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);
    }

    function _setBorrowCap(address zBondAddress, uint256 newBorrowCap)
        external
    {
        require(
            msg.sender == borrowCapGuardian || msg.sender == owner(),
            "Comptroller: only borrowCapGuardian and owner can set borrow cap"
        );
        borrowCaps[zBondAddress] = newBorrowCap;
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Owner function to set per-market collateralFactor
     * @param ZNft The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     */
    function _setCollateralFactor(
        ZNftInterface ZNft,
        uint256 newCollateralFactorMantissa
    ) external onlyOwner returns (uint256) {
        //  verify the market is NFT
        Market storage market = markets[address(ZNft)];
        require(ZNft.isZNft(), "Comptroller: NFTs collaterals only");

        // Verify market is listed
        require(
            market.isListed,
            "Comptroller: Cannot set non-exisiting market collateral factors."
        );

        // Check collateral factor <= 0.9
        require(
            collateralFactorMaxMantissa > newCollateralFactorMantissa,
            "Comptroller: Collateral factor too large."
        );
        // If collateral factor != 0, fail if price == 0

        require(
            nftOracle.getUnderlyingPrice(ZNft) != 0,
            "Comptroller: ZNft underlying price is 0"
        );

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(
            ZNft,
            oldCollateralFactorMantissa,
            newCollateralFactorMantissa
        );
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Owner function to set liquidationIncentive
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        onlyOwner
        returns (uint256)
    {
        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(
            oldLiquidationIncentiveMantissa,
            newLiquidationIncentiveMantissa
        );
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Owner function to set isListed and add support for the market
     * @param zBond The address of the market (token) to list
     * @param ZNft The address of the market (token) to list
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */

    function _supportMarket(ZNftInterface ZNft, ZBond zBond)
        external
        onlyOwner
        returns (uint256)
    {
        require(ZNft.isZNft(), "Comptroller: ZNft is not an NFT");
        require(zBond.isZBond(), "Comptroller: zBond is not a ZBond");
        require(
            !markets[address(zBond)].isListed,
            "Comptroller: zBond already listed"
        );
        require(
            address(zBond.ZNft()) == address(ZNft),
            "Comptroller: zBond ZNft do not match"
        );

        markets[address(zBond)].isListed = true;
        markets[address(ZNft)].isListed = true;
        allMarkets[ZNft][zBond] = true;
        ZNft.setZBond(zBond);

        add(0, address(zBond), true);
        add(0, address(zBond.provisioningPool()), true);

        emit MarketListed(ZNft, zBond);
    }

    /**
     * @notice Owner function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian)
        public
        onlyOwner
        returns (uint256)
    {
        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
    }

    function _setBorrowCapGuardian(address newBorrowCapGuardian)
        public
        onlyOwner
    {
        borrowCapGuardian = newBorrowCapGuardian;
    }

    function _setMintPaused(address asset, bool state) public returns (bool) {
        require(
            markets[asset].isListed,
            "Comptroller: cannot pause a market that is not listed"
        );
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "Comptroller: only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "Comptroller: only owner can unpause"
        );

        mintGuardianPaused[asset] = state;

        emit ActionPaused(asset, "Mint", state);

        return state;
    }

    function _setBorrowPaused(ZBond zBond, bool state) public returns (bool) {
        require(
            markets[address(zBond)].isListed,
            "Comptroller: cannot pause a market that is not listed"
        );
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "Comptroller: only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "Comptroller: only owner can unpause"
        );

        borrowGuardianPaused[address(zBond)] = state;
        emit ActionPaused(address(zBond), "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "Comptroller: only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "Comptroller: only owner can unpause"
        );

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(
            msg.sender == pauseGuardian || msg.sender == owner(),
            "Comptroller: only pause guardian and owner can pause"
        );
        require(
            msg.sender == owner() || state == true,
            "Comptroller: only owner can unpause"
        );

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _setZumer(address zumer_) public onlyOwner {
        zumer = IERC20(zumer_);
    }

    /**
     * @notice Returns true if the given zBond market has been deprecated
     * @dev All borrows in a deprecated zBond market can be immediately liquidated
     * @param zBond The market to check if deprecated
     */
    function isDeprecated(ZBond zBond) public view returns (bool) {
        return
            markets[address(zBond)].collateralFactorMantissa == 0 &&
            borrowGuardianPaused[address(zBond)] == true;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    // token rewards functions

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        address _pool,
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        uint256 id = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                pool: _pool,
                balance: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accZumerPerShare: 0
            })
        );

        poolToID[_pool] = id;
    }

    // Update the given pool's ZUMER allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return (_to - _from) * BONUS_MULTIPLIER;
        } else if (_from >= bonusEndBlock) {
            return _to - _from;
        } else {
            return
                (bonusEndBlock - _from) *
                BONUS_MULTIPLIER +
                (_to - bonusEndBlock);
        }
    }

    // View function to see pending ZUMERs on frontend.
    function pendingZumer(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accZumerPerShare = pool.accZumerPerShare;
        uint256 lpSupply = pool.balance;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 zumerReward = (multiplier *
                zumerPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accZumerPerShare =
                accZumerPerShare +
                ((zumerReward * 1e18) / lpSupply);
        }
        return (user.amount * accZumerPerShare) / 1e18 - (user.rewardDebt);
    }

    // an even better pending zumer function
    function pendingZumerAll(uint256[] memory _pids, address _user)
        public
        view
        returns (uint256)
    {
        uint256 all = 0;
        for (uint256 i; i < _pids.length; i++) {
            all += pendingZumer(_pids[i], _user);
        }
        return all;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.balance;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 zumerReward = (multiplier * zumerPerBlock * pool.allocPoint) /
            totalAllocPoint;

        pool.accZumerPerShare =
            pool.accZumerPerShare +
            (zumerReward * 1e18) /
            lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // relevant contracts (provisioning pool, zbond) call this method to make sure that the users balance that
    // claim the zumer tokens is properly recorded
    function increaseBalance(
        address poolAddress,
        address account,
        uint256 _amount
    ) internal {
        uint256 _pid = poolToID[poolAddress];
        PoolInfo storage pool = poolInfo[_pid];

        //require(msg.sender == pool.pool, "Only certified contracts can change balances.");

        UserInfo storage user = userInfo[_pid][account];

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accZumerPerShare) /
                1e18 -
                user.rewardDebt;
            zumer.transfer(account, pending);
        }
        pool.balance += _amount;
        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accZumerPerShare) / 1e18;

        emit IncreasedBalance(account, _pid, _amount);
    }

    function decreaseBalance(
        address poolAddress,
        address account,
        uint256 _amount
    ) internal {
        uint256 _pid = poolToID[poolAddress];
        PoolInfo storage pool = poolInfo[_pid];

        UserInfo storage user = userInfo[_pid][account];
        require(
            user.amount >= _amount,
            "Comptroller: decrease balance: not enough balance"
        );

        updatePool(_pid);
        uint256 pending = (user.amount * pool.accZumerPerShare) /
            1e18 -
            user.rewardDebt;

        zumer.transfer(account, pending);

        pool.balance -= _amount;
        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accZumerPerShare) / 1e18;

        emit DecreasedBalance(account, _pid, _amount);
    }

    function claimAllZumers(address[] memory poolAddresses) external {
        for (uint256 i; i < poolAddresses.length; i++) {
            uint256 _pid = poolToID[poolAddresses[i]];
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][msg.sender];
            updatePool(_pid);
            if (user.amount > 0) {
                uint256 pending = (user.amount * pool.accZumerPerShare) /
                    1e18 -
                    user.rewardDebt;
                zumer.transfer(msg.sender, pending);
            }
            user.rewardDebt = (user.amount * pool.accZumerPerShare) / 1e18;
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev Keep in sync with ComptrollerInterface080.sol.
abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Policy Hooks ***/
    function mintAllowed(
        address zBond,
        address minter,
        uint256 mintAmount
    ) external virtual;

    function redeemAllowed(
        address zNft,
        address redeemer,
        uint256 redeemTokens
    ) external virtual;

    function borrowAllowed(
        address zBond,
        address borrower,
        uint256 borrowAmount,
        uint256 duration
    ) external virtual;

    function repayBorrowAllowed(
        address zBond,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external virtual;

    function calculateLiquidationAmount(
        address borrower,
        address zBondBorrowed,
        uint256[] calldata id,
        address ZNft
    ) external virtual returns (uint256);

    function liquidateBorrowAllowed(
        address zBondBorrowed,
        address ZNft,
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) external virtual;

    function seizeAllowed(
        address zBondCollateral,
        address zBondBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual;

    function transferAllowed(
        address zNft,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeNfts(
        address zBondBorrowed,
        address zBondCollateral,
        uint256 repayAmount
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ZNftInterface.sol";
import "./ZBond.sol";
import "./NftPriceOracle.sol";
import "./PriceOracle.sol";

contract ComptrollerStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => mapping(address => ZBond[])) public accountAssets;

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;
        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
    }

    struct BorrowState {
        uint256 dueTime;
        uint256 initialBorrow;
    }
    /**
     * @notice Official mapping of asset -> collateral metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets for a ZNft market
    mapping(ZNftInterface => mapping(ZBond => bool)) public allMarkets;

    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each zBond address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;

    /// @notice Last block at which a contributor's COMP rewards have been allocated
    mapping(address => uint256) public lastContributorBlock;

    NftPriceOracle public nftOracle;

    mapping(address => mapping(address => uint256[]))
        public sequenceOfLiquidation; // nft => user => id

    // token awards storage

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ZUMERs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accZumerPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accZumerPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address pool; // Address of the contract being rewarded.
        uint256 balance; // balance of the tokens that will be used in the calculation.
        uint256 allocPoint; // How many allocation points assigned to this pool. ZUMERs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ZUMERs distribution occurs.
        uint256 accZumerPerShare; // Accumulated ZUMERs per share, times 1e12. See below.
    }

    // The ZUMER TOKEN!
    IERC20 public zumer;
    // Block number when bonus ZUMER period ends.
    uint256 public bonusEndBlock;
    // ZUMER tokens created per block.
    uint256 public zumerPerBlock;
    // Bonus muliplier for early zumer makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolToID;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ZUMER mining starts.
    uint256 public startBlock;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract FeeSelector {
    /**
        _decisionToken: token that is used to decide the fee
        upperBound: upper bound of the funding cost
        lowerBound
    */

    struct UserVotes {
        uint256 upperLong;
        uint256 lowerLong;
        uint256 upperShort;
        uint256 lowerShort;
    }

    IERC20 public decisionToken;

    struct PoolInfo {
        uint256 upperBound;
        uint256 lowerBound;
        uint256 upperTotal;
        uint256 lowerTotal;
    }

    PoolInfo public longPool;

    PoolInfo public shortPool;

    mapping(address => UserVotes) public userAcounts;

    constructor(
        IERC20 _decisionToken,
        uint256 _upperBoundLong,
        uint256 _lowerBoundLong,
        uint256 _upperBoundShort,
        uint256 _lowerBoundShort
    ) {
        decisionToken = _decisionToken;
        longPool.upperBound = _upperBoundLong;
        longPool.lowerBound = _lowerBoundLong;

        shortPool.upperBound = _upperBoundShort;
        shortPool.lowerBound = _lowerBoundShort;
    }

    function stake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong += upperAmount;
            userAcounts[msg.sender].lowerLong += lowerAmount;

            longPool.upperTotal += upperAmount;
            longPool.lowerTotal += lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort += upperAmount;
            userAcounts[msg.sender].lowerShort += lowerAmount;

            shortPool.upperTotal += upperAmount;
            shortPool.lowerTotal += lowerAmount;
        }

        decisionToken.transferFrom(
            msg.sender,
            address(this),
            upperAmount + lowerAmount
        );
    }

    function unstake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong -= upperAmount;
            userAcounts[msg.sender].lowerLong -= lowerAmount;

            longPool.upperTotal -= upperAmount;
            longPool.lowerTotal -= lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort -= upperAmount;
            userAcounts[msg.sender].lowerShort -= lowerAmount;

            shortPool.upperTotal -= upperAmount;
            shortPool.lowerTotal -= lowerAmount;
        }

        decisionToken.transfer(msg.sender, upperAmount + lowerAmount);
    }

    /**
        Rate calculation formula:(longRate - shortRate)/ (maximum loan duration) * (target) + shortRate
        Returns the double for the duration.
     */
    function getFundingCostForDuration(
        uint256 loanDuration,
        uint256 maximumLoanDuration
    ) public view returns (uint256) {
        (uint256 longRate, uint256 shortRate) = getFundingCostRateFx();
        return
            ((longRate - shortRate) * loanDuration) /
            maximumLoanDuration +
            shortRate;
    }

    function getFundingCost(PoolInfo memory pool)
        public
        pure
        returns (uint256)
    {
        if (pool.upperTotal + pool.lowerTotal == 0) {
            return pool.lowerBound;
        }

        return
            (pool.upperBound *
                pool.upperTotal +
                pool.lowerBound *
                pool.lowerTotal) / (pool.upperTotal + pool.lowerTotal);
    }

    function getFundingCostRateFx() public view returns (uint256, uint256) {
        uint256 upper = getFundingCost(longPool);
        uint256 lower = getFundingCost(shortPool);

        return (upper, lower);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ZNftInterface.sol";

abstract contract NftPriceOracle {
    /// @notice Indicator that this is a NftPriceOracle contract (for inspection)
    bool public constant isNftPriceOracle = true;

    /**
     * @notice Get the underlying price of a cNft asset
     * @param cNft The cNft to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(ZNftInterface cNft)
        external
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
     * @notice Get the underlying price of a cToken asset
     * @param asset The asset to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address asset)
        external
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./ZBond.sol";
import "./ZNftInterface.sol";
import "./ComptrollerInterface.sol";
import "./AuctionMarket.sol";

abstract contract ProvisioningPoolStorage {
    ZNftInterface public zNftCollateral;
    ComptrollerInterface public comptroller;
    ZBond public zBond;
    uint256 public penaltyMantissa;
    AuctionMarket public auctionMarket;
    uint256 public constant expireDuration = 30 days;

    uint256 public totalStakedUnderlying;
    IERC20 public underlying;

    struct StakeData {
        uint256 expireTime;
        uint256 staked;
        uint256 unstaked;
    }
    mapping(address => StakeData[]) public userStakeData;
}

/**
    @title Zumer's Provioning Pool
    @notice 

 */
contract ProvisioningPool is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    ProvisioningPoolStorage
{
    event Staked(address staker, uint256 amount, uint256 expiration);
    event Unstaked(address staker, uint256 amount, uint256 expiration);
    event Received(address sender, uint256 amount);

    function initialize(
        ComptrollerInterface _comptroller,
        ZNftInterface _zNftCollateral,
        ZBond _zBond,
        string memory _name,
        string memory _symbol,
        AuctionMarket _auctionMarket,
        IERC20 _underlying
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);

        comptroller = _comptroller;
        zNftCollateral = _zNftCollateral;
        zBond = _zBond;
        auctionMarket = _auctionMarket;
        underlying = _underlying;
    }

    /**
        Stakes in the provisioning pool. Returns the number of ppToken minted.
    
     */
    function stakeInternal(uint256 amount, uint256 time)
        internal
        returns (uint256)
    {
        require(time >= expireDuration, "Stake should be at least 30 days.");
        uint256 mintAmount = (getCurrentExchangeRateMantissa() * amount) / 1e18;
        _mint(msg.sender, mintAmount);

        totalStakedUnderlying += amount;
        emit Staked(msg.sender, mintAmount, time + block.timestamp);

        // update user timestamp data.
        StakeData memory stakeData = StakeData(
            time + block.timestamp,
            mintAmount,
            0
        );
        userStakeData[msg.sender].push(stakeData);

        // interaction
        doTransferIn(msg.sender, amount);

        //zumerMiner.increaseBalance(msg.sender, amount);

        return mintAmount;
    }

    /**
        Unstakes in the provisioning pool. Returns the number of ppToken burned.
    
     */
    function unstakeInternal(uint256 amount) internal returns (uint256) {
        require(
            underlying.balanceOf(address(this)) > 0,
            "Not enough to unstake in the provisioning pool."
        );

        // effects

        uint256 burnAmount = (amount * getCurrentExchangeRateMantissa()) / 1e18;
        _burn(msg.sender, burnAmount);
        totalStakedUnderlying -= amount;

        // interaction
        doTransferOut(msg.sender, amount);

        //zumerMiner.decreaseBalance(msg.sender, amount);

        return burnAmount;
    }

    function unstakeAll() external returns (uint256) {
        uint256 burnedPPAmount = 0;
        uint256 numOfUnstakes = 0;
        uint256 length = userStakeData[msg.sender].length;

        require(length > 0, "User has no stakes to unstake");
        StakeData[] storage sd = userStakeData[msg.sender];

        // effects
        for (uint256 i = 0; i < length; i++) {
            if (sd[i].expireTime < block.timestamp) {
                burnedPPAmount += sd[i].staked - sd[i].unstaked;
                sd[i].unstaked = sd[i].staked;
                numOfUnstakes += 1;
                emit Unstaked(msg.sender, burnedPPAmount, sd[i].expireTime);
            }
        }

        // remove empty user data/ claimed user data so the contract doesn't get locked because the array is too long
        // by shifting
        /*         for(uint i = 0; i < length - numOfUnstakes; i++) {
            sd[i] = sd[i + numOfUnstakes];
        }

        for(uint i = 0; i < numOfUnstakes; i++) {
            sd.pop();
        } */

        // interaction
        uint256 burnAmount = unstakeInternal(burnedPPAmount);
        return burnAmount;
    }

    /**
        returns pp token burned and the amount 
     */
    function unstakeAmount(uint256 amount)
        external
        returns (uint256 burnAmount, uint256)
    {
        uint256 burnedPPAmount = 0;
        uint256 numOfUnstakes = 0;
        uint256 length = userStakeData[msg.sender].length;
        uint256 insufficientAmount = amount;

        require(length > 0, "User has no stakes to unstake");
        StakeData[] storage sd = userStakeData[msg.sender];

        // effects
        for (uint256 i = 0; i < length; i++) {
            if (sd[i].expireTime < block.timestamp) {
                if (amount >= sd[i].staked - sd[i].unstaked) {
                    // if we have enough tokens to unstake then unstake
                    burnedPPAmount += sd[i].staked - sd[i].unstaked;
                    numOfUnstakes += 1;
                    amount -= sd[i].staked - sd[i].unstaked;
                    sd[i].unstaked = sd[i].staked;
                } else {
                    // else only unstake some then terminate
                    burnedPPAmount += amount;
                    sd[i].unstaked += amount;
                    amount = 0;
                    break;
                }
            }
        }

        // remove empty user data/ claimed user data so the contract doesn't get locked because the array is too long
        // by shifting
        /*         for(uint i = 0; i < length - numOfUnstakes; i++) {
            sd[i] = sd[i + numOfUnstakes];
        }

        for(uint i = 0; i < numOfUnstakes; i++) {
            sd.pop();
        }
 */

        // interaction
        burnAmount = unstakeInternal(burnedPPAmount);
        return (burnAmount, insufficientAmount - amount);
    }

    /** Liquidation */
    function liquidateOverDueNFT(address borrower, uint256[] calldata id)
        public
    {
        // require(address(address(zNftCollateral).comptroller()) == comptroller, "comptroller does not match");

        address originalOwner = zNftCollateral.ownerOf(id[0]);

        uint256 repayFromProvisioning = comptroller.calculateLiquidationAmount(
            borrower,
            address(zBond),
            id,
            address(zNftCollateral)
        );
        uint256 actualRepayAmount = repayAndSeize(address(this), borrower, id);
        require(
            zNftCollateral.ownerOf(id[0]) == address(this),
            "NFT liquidation failed"
        );

        // send to auction
        zNftCollateral.transferFrom(
            address(this),
            address(auctionMarket),
            id[0]
        );
        // start auction
        auctionMarket.startAuction(
            id[0],
            actualRepayAmount,
            originalOwner,
            ZNftInterface(address(zNftCollateral))
        );
    }

    /**
        Gets the exchange rate of ppToken: underlying. Scaled by 1e18;
     */
    function getCurrentExchangeRateMantissa() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 1e18;
        } else {
            return (totalSupply() * 1e18) / totalStakedUnderlying;
        }
    }

    function getMaxBurn(address account) public view returns (uint256) {
        // calculate maximum claimable.
        uint256 maxBurn = 0;
        for (uint256 i = 0; i < userStakeData[account].length; i++) {
            StakeData memory sd = userStakeData[account][i];
            if (sd.expireTime < block.timestamp) {
                maxBurn += sd.staked - sd.unstaked;
            }
        }
        return maxBurn;
    }

    /** Replenish lending pool */
    /**
        When the lending pool run out of money, replenish the pool with money from the provisioning pool. 
    require(msg.sender == address(zBond) || msg.sender == address(auctionMarket));
        require(amount <= address(this).balance, "provisioning: insufficient funds");
     */
    function replenishLendingPoolInternal(uint256 amount) internal {
        totalStakedUnderlying -= amount;
        doTransferOut(address(zBond), amount);
    }

    function doTransferIn(address sender, uint256 amount) internal {
        underlying.transferFrom(sender, address(this), amount);
    }

    function doTransferOut(address receiver, uint256 amount) internal {
        underlying.transfer(receiver, amount);
    }

    function getCashBalance() external view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /** Replenish lending pool */
    /**
        When the lending pool run out of money, replenish the pool with money from the provisioning pool. 
    require(msg.sender == address(zBondETH) || msg.sender == address(auctionMarket));
        require(amount <= address(this).balance, "provisioning: insufficient funds");
     */
    function replenishLendingPool(uint256 amount) external {
        require(
            msg.sender == address(zBond) || msg.sender == address(auctionMarket)
        );
        require(
            amount <= address(this).balance,
            "provisioning: insufficient funds"
        );
        replenishLendingPoolInternal(amount);
    }

    function stake(uint256 amount, uint256 time) external returns (uint256) {
        return stakeInternal(amount, time);
    }

    function repayAndSeize(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) public returns (uint256 actualRepayAmount) {
        // TODO: move it somewhere better?
        IERC20(underlying).approve(address(zBond), type(uint256).max);
        return (zBond).liquidateOverdueBorrow(liquidator, borrower, id);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ComptrollerInterface.sol";
import "./FeeSelector.sol";
import "./ProvisioningPool.sol";
import "./ZNftInterface.sol";

interface ZBondInterface {
    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(
        address minter,
        uint256 mintAmount,
        uint256 mintTokens,
        uint256 totalSupply
    );
    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 totalBorrows,
        uint256 duration
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        ZNftInterface cTokenCollateral
    );

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
}

abstract contract ZBondStorage is ZBondInterface {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /** 
        how much time that a user can borrow without paying interests until they get margin call
    */
    uint256 public constant minimumPaymentDueFrequency = 30 days; // TODO

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current funding cost should be
     */
    FeeSelector public feeSelector;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public provisioningPoolMantissa;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total number of underlying accumulated in the contract plus the borrowed token
     */
    uint256 public totalSupplyPrinciplePlusInterest;

    /**
     * @notice Underlying
     */
    IERC20 public underlying;

    /**
     * @notice Container for borrow balance information
     */
    struct BorrowSnapshot {
        uint256 deadline;
        uint256 loanDuration;
        uint256 minimumPaymentDue;
        uint256 principalBorrow;
        uint256 weightedInterestRate;
    }

    struct SupplySnapshot {
        uint256 principalSupply;
        uint256 startDate;
    }

    /**
     * @notice days that one has to pledge in the pool to get all the awards
     */
    uint256 public constant fullAwardCollectionDuration = 30 days;

    uint256 public constant maximumLoanDuration = 180 days;
    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;

    mapping(address => SupplySnapshot) public accountSupplies;

    mapping(address => uint256[]) public userLiquidationSequence;

    ZNftInterface public ZNft;
    ProvisioningPool public provisioningPool;
    bool public constant isZBond = true;

    uint256 public creditCostRatioMantissa;

    uint256 public underwritingFeeRatioMantissa;
}

contract ZBond is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    ReentrancyGuard,
    ZBondStorage
{
    function initialize(
        string memory name_,
        string memory symbol_,
        ZNftInterface ZNft_,
        FeeSelector feeSelector_,
        ComptrollerInterface comptroller_,
        IERC20 underlying_
    ) public initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
        ZNft = ZNft_;
        feeSelector = feeSelector_;
        comptroller = comptroller_;
        underlying = underlying_;
        creditCostRatioMantissa = 0.05 * 1e18;
        underwritingFeeRatioMantissa = 0.01 * 1e18;
    }

    /**
        amountIn: the underlying asset that will be transfered in the contract.
     */
    function mintInternal(uint256 amountIn) internal returns (uint256) {
        uint256 mintAmount = (getExchangeRateMantissa() * amountIn) / 1e18;
        _mint(msg.sender, mintAmount);

        // effects
        // change user state
        accountSupplies[msg.sender].principalSupply += amountIn;
        if (accountSupplies[msg.sender].startDate == 0) {
            accountSupplies[msg.sender].startDate = block.timestamp;
        }

        // change global state
        totalSupplyPrinciplePlusInterest += amountIn;

        // interaction
        doTransferIn(msg.sender, amountIn);
        emit Mint(
            msg.sender,
            amountIn,
            mintAmount,
            totalSupplyPrinciplePlusInterest
        );

        return mintAmount;
    }

    /**
        amountIn: the underlying asset that will be transfered out from the contract contract.
     */
    function redeemInternal(uint256 amountOut) internal returns (uint256) {
        require(
            underlying.balanceOf(address(this)) > 0,
            "ZBond: no underlying tokens to redeem in the lending pool."
        );
        // effects
        uint256 burnAmount = (getExchangeRateMantissa() * amountOut) / 1e18;
        require(
            burnAmount <= balanceOf(msg.sender),
            "ZBond: not enough balance to redeem"
        );

        // reduce total supply
        totalSupplyPrinciplePlusInterest -= amountOut;
        _burn(msg.sender, burnAmount);

        // interaction
        emit Redeem(msg.sender, amountOut, burnAmount);

        doTransferOut(msg.sender, amountOut);

        return burnAmount;
    }

    function borrowInternal(uint256 amount, uint256 duration)
        internal
        returns (uint256, uint256)
    {
        comptroller.borrowAllowed(address(this), msg.sender, amount, duration);
        uint256 fundingRateMantissa = feeSelector.getFundingCostForDuration(
            duration,
            maximumLoanDuration
        );

        fundingRateMantissa += creditCostRatioMantissa;
        // effects
        updateUserStateAfterBorrow(
            msg.sender,
            amount,
            duration,
            fundingRateMantissa
        );
        totalBorrows += amount;

        // interactions
        // transfer underwriting fee to the admin
        uint256 underwritingFee = (amount * underwritingFeeRatioMantissa) /
            1e18;
        doTransferOut(owner(), underwritingFee);
        // transfer principle borrow to the user
        doTransferOut(msg.sender, amount - underwritingFee);

        emit Borrow(msg.sender, amount, totalBorrows, duration);

        //zumerMiner.increaseBalance(msg.sender, amount);
    }

    /**
    
        returns actual amount paid and the interest that are transfered to the provisioining pool.
     */
    function repayBorrowInternal(address borrower, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        comptroller.repayBorrowAllowed(
            address(this),
            msg.sender,
            msg.sender,
            amount
        );

        // effects
        (uint256 overpay, uint256 interestPaid) = updateUserStateAfterRepay(
            borrower,
            amount
        );
        uint256 provisioningInterest = (provisioningPoolMantissa *
            interestPaid) / 1e18;
        totalSupplyPrinciplePlusInterest += (interestPaid -
            provisioningInterest);

        // interactions
        doTransferIn(msg.sender, amount - overpay);

        if (address(provisioningPool) != address(0)) {
            doTransferOut(address(provisioningPool), provisioningInterest);
        } else {
            doTransferOut(owner(), provisioningInterest);
        }

        // update zumer claims

        //zumerMiner.decreaseBalance(msg.sender, amount);

        return (amount - overpay, provisioningInterest);
    }

    function liquidateBorrowInternal(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) internal returns (uint256) {
        comptroller.liquidateBorrowAllowed(
            address(this),
            address(ZNft),
            liquidator,
            borrower,
            id
        );

        uint256 repayAmount = comptroller.calculateLiquidationAmount(
            borrower,
            address(this),
            id,
            address(ZNft)
        );

        (
            uint256 actualPayBack,
            uint256 provisioningPoolInterestPaid
        ) = repayBorrowInternal(borrower, repayAmount);

        // seize collaterals;
        ZNft.seize(liquidator, borrower, id);

        emit LiquidateBorrow(liquidator, borrower, repayAmount, ZNft);
        return actualPayBack;
    }

    /**
        Gets the rate betwen the total supply of zBondToken: totalSupply
     */
    function getExchangeRateMantissa() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 1e18;
        } else {
            return (totalSupply() * 1e18) / totalSupplyPrinciplePlusInterest;
        }
    }

    /** 
        update the users' borrow state
        returns (overpay, interest paid).   
    */
    function updateUserStateAfterRepay(address borrower, uint256 paid)
        internal
        returns (uint256, uint256)
    {
        uint256 borrowBalance = accountBorrows[borrower].principalBorrow;
        uint256 currentInterestToPay = getAccountCurrentBorrowBalance(
            borrower
        ) - borrowBalance;
        if (paid < currentInterestToPay) {
            return (0, paid);
        } else {
            // if user closed position, then delete user borrow position
            if (borrowBalance + currentInterestToPay <= paid) {
                delete accountBorrows[borrower];
                return (
                    paid - (borrowBalance + currentInterestToPay),
                    currentInterestToPay
                );
            }
            // if user reduced position (or at least paid all of their interests), then reduce initial borrow and carry over the minimum payment due time, total loan due time is not affected
            else {
                accountBorrows[borrower].minimumPaymentDue =
                    block.timestamp +
                    minimumPaymentDueFrequency;
                accountBorrows[borrower].principalBorrow =
                    borrowBalance +
                    currentInterestToPay -
                    paid;

                return (0, currentInterestToPay);
            }
        }
    }

    function updateUserStateAfterBorrow(
        address borrower,
        uint256 borrowAmount,
        uint256 duration,
        uint256 interest
    ) internal {
        // initialize borrow state if dueTime is not set
        if (accountBorrows[borrower].minimumPaymentDue == 0) {
            accountBorrows[borrower].minimumPaymentDue =
                block.timestamp +
                minimumPaymentDueFrequency;
        }
        if (accountBorrows[borrower].deadline == 0) {
            accountBorrows[borrower].loanDuration = duration;
            accountBorrows[borrower].deadline =
                block.timestamp +
                accountBorrows[borrower].loanDuration;
        }

        require(
            (accountBorrows[borrower].minimumPaymentDue >= block.timestamp) &&
                (accountBorrows[borrower].deadline >= block.timestamp),
            "ZBond: cannot increase position if overdue"
        );

        // set weighted interest
        uint256 timeLeft = accountBorrows[borrower].deadline - block.timestamp;
        if (accountBorrows[borrower].principalBorrow == 0) {
            accountBorrows[borrower].weightedInterestRate = interest;
        } else {
            accountBorrows[borrower].weightedInterestRate =
                ((accountBorrows[borrower].weightedInterestRate *
                    accountBorrows[borrower].principalBorrow *
                    accountBorrows[borrower].loanDuration +
                    interest *
                    borrowAmount *
                    timeLeft) * 1e18) /
                (accountBorrows[borrower].principalBorrow *
                    accountBorrows[borrower].loanDuration +
                    borrowAmount *
                    timeLeft);
        }

        accountBorrows[borrower].principalBorrow += borrowAmount;
    }

    function getAccountCurrentBorrowBalance(address borrower)
        public
        view
        returns (uint256)
    {
        uint256 principle = accountBorrows[borrower].principalBorrow;

        if (principle == 0) {
            return 0;
        }

        uint256 interestRate = accountBorrows[borrower].weightedInterestRate;
        uint256 duration = accountBorrows[borrower].loanDuration;
        uint256 deadline = accountBorrows[borrower].deadline;
        uint256 accruedPeriod;

        if (block.timestamp >= deadline) {
            // if due/overdue, balance should be all the principle and all the interests
            accruedPeriod = duration;
        } else {
            // remaining loan duration = deadline - block.timestamp
            // accruedPeriod = loan duration - remaining loan duration
            accruedPeriod = duration - (deadline - block.timestamp);
        }
        // interestRate is annualised percentage rate
        uint256 interest = (principle * interestRate * accruedPeriod) /
            365 days /
            1e18;
        return principle + interest;
    }

    function pledgeThenBorrow(
        uint256[] calldata ids,
        uint256 amount,
        uint256 duration
    ) public {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(ZNft.underlying()).transferFrom(
                msg.sender,
                address(this),
                ids[i]
            );
        }
        IERC721(ZNft.underlying()).setApprovalForAll(address(ZNft), true);
        ZNft.mint(ids, msg.sender);
        borrowInternal(amount, duration);
    }

    function repayAllThenRedeem(uint256[] calldata ids) public {
        uint256 borrowBalance = getAccountCurrentBorrowBalance(msg.sender);
        repayBorrowInternal(msg.sender, borrowBalance);
        ZNft.redeem(ids, msg.sender);
    }

    function setProvisioningPool(
        address provisioningPoolAddress,
        uint256 provisioingPoolMantissa_
    ) public onlyOwner {
        provisioningPool = ProvisioningPool(payable(provisioningPoolAddress));
        provisioningPoolMantissa = provisioingPoolMantissa_;
    }

    function setUnderwritingFeeRatio(uint256 underwritingFeeRatioMantissa_)
        public
        onlyOwner
    {
        underwritingFeeRatioMantissa = underwritingFeeRatioMantissa_;
    }

    function setCreditCostRatio(uint256 creditCostRatioMantissa_)
        public
        onlyOwner
    {
        creditCostRatioMantissa = creditCostRatioMantissa_;
    }

    function mint(uint256 amount) external nonReentrant returns (uint256) {
        return mintInternal(amount);
    }

    function redeem(uint256 amount) external nonReentrant {
        redeemInternal(amount);
    }

    function borrow(uint256 amount, uint256 duration) external nonReentrant {
        borrowInternal(amount, duration);
    }

    function repayBorrow(uint256 amount) external nonReentrant {
        repayBorrowInternal(msg.sender, amount);
    }

    function doTransferIn(address sender, uint256 amount) internal {
        underlying.transferFrom(sender, address(this), amount);
    }

    function doTransferOut(address receiver, uint256 amount) internal {
        underlying.transfer(receiver, amount);
    }

    function liquidateOverdueBorrow(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) external nonReentrant returns (uint256) {
        return liquidateBorrowInternal(liquidator, borrower, id);
    }

    function liquidateBorrow(
        address liquidator,
        address borrower,
        uint256[] calldata ids
    ) external nonReentrant returns (uint256) {
        return liquidateBorrowInternal(liquidator, borrower, ids);
    }

    function getCashBalance() external view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ZBond.sol";
import "./AuctionMarket.sol";

abstract contract ZNftInterface is ERC721Upgradeable, IERC721Receiver {
    address public underlying;
    bool isPunk;
    string public uri;
    address public comptroller;
    AuctionMarket public auctionMarket;
    bool public constant isZNft = true;

    /**
     * We will likely support other erc tokens other than wETH.
     */
    ZBond[] public zBonds;
    /**
     * @notice Event emitted when ZNfts are minted
     */
    event Mint(address minter, uint256[] mintIds);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256[] redeemIds);

    function seize(
        address liquidator,
        address borrower,
        uint256[] calldata seizeIds
    ) external virtual;

    function mint(uint256[] calldata tokenIds, address minter)
        external
        virtual
        returns (uint256);

    function redeem(uint256[] calldata tokenIds, address redeemer)
        external
        virtual
        returns (uint256);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external virtual;

    function getZBonds() external view virtual returns (ZBond[] memory);

    function setZBond(ZBond zBond) external virtual;
}