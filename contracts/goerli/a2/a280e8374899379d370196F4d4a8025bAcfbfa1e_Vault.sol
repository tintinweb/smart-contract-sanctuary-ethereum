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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
interface IERC20Permit {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.8.4;

import "./Interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract AggrigatorWrapper is Initializable, UUPSUpgradeable {
  address owner;

  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
    owner = msg.sender;
  }

  function getPricePerRound(
    AggregatorV3Interface aggregatorContract,
    uint80 roundId
  ) internal view returns (int256) {
    (, int256 price, , uint256 timeStamp, ) = AggregatorV3Interface(
      aggregatorContract
    ).getRoundData(roundId);
    require(timeStamp > 0, "Round not completed");
    return price;
  }

  function getLastPrice(
    AggregatorV3Interface priceFeed
  ) public view returns (int256, uint80) {
    (uint80 roundID, int256 price, , , ) = priceFeed.latestRoundData();
    return (price, roundID);
  }

  function getPriceByTime(
    AggregatorV3Interface aggregatorContract,
    uint256 time
  ) public view returns (int256, uint80) {
    uint80 offset = aggregatorContract.phaseId() * 2 ** 64;
    uint80 end = uint80(aggregatorContract.latestRound()) % offset;

    uint80 roundID = getBlockByPhase(
      aggregatorContract,
      time,
      offset,
      1,
      (end + 1) / 2,
      end
    );
    int256 price = getPricePerRound(aggregatorContract, roundID);
    return (price, roundID);
  }

  function getBlockByPhase(
    AggregatorV3Interface aggregatorContract,
    uint256 time,
    uint80 offset,
    uint80 start,
    uint80 mid,
    uint80 end
  ) public view returns (uint80) {
    require(end >= mid + 1, "Block not found");
    require(end > start, "Block not found");
    (, , , uint256 midTime, ) = aggregatorContract.getRoundData(mid + offset);
    (, , , uint256 endTime, ) = aggregatorContract.getRoundData(end + offset);
    if (midTime == 0)
      return
        getBlockByPhase(aggregatorContract, time, offset, start, mid + 1, end);
    else if (endTime == 0)
      return
        getBlockByPhase(aggregatorContract, time, offset, start, mid, end - 1);

    if (end == mid + 1) {
      if ((endTime >= time) && (midTime < time)) {
        return offset + end;
      }
    }

    require(endTime >= time, "Block not found");

    if (midTime >= time)
      return
        getBlockByPhase(
          aggregatorContract,
          time,
          offset,
          start,
          (start + mid) / 2,
          mid
        );
    else
      return
        getBlockByPhase(
          aggregatorContract,
          time,
          offset,
          mid,
          (mid + end) / 2,
          end
        );
  }

  function getLastPriceX1e6(
    AggregatorV3Interface aggregatorContract
  ) public view returns (int256, uint80) {
    (int256 price, uint80 roundID) = getLastPrice(aggregatorContract);
    return (price / 1e2, roundID);
  }

  function _authorizeUpgrade(address newImplementation) internal view override {
    require(msg.sender == owner, "Not Owner");
    require(newImplementation != address(0), "address zero");
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function phaseId() external view returns (uint16);

    function latestRound() external view returns (uint256);

    function latestAnswer() external view returns (uint256);

    function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./AggrigatorWrapper.sol";

contract Vault is Initializable, UUPSUpgradeable {
  using SafeERC20 for IERC20;
  enum RoundStates {
    UNSET,
    PREPARING,
    STARTED,
    PENDING,
    COMPLETED
  }
  enum VaultTypes {
    PUT,
    CALL
  }
  /// vault type (0=PUT,1=CALL)
  VaultTypes public VAULT_TYPE;
  /// the state of the current round (0=STARTED,1=PENDING,2=COMPLETED)
  mapping(uint256 => RoundStates) public roundState;
  /// the courrent round
  uint256 public round;
  /// when the current round will expire
  uint256 public roundExpiry;
  /// the time on wich we start calculate the round expiry(currentRoundExpiry = START_TIME + round * ROUND_PERIOD + ROUND_PERIOD)
  uint256 public START_TIME;
  /// duration of each round
  uint256 public ROUND_PERIOD;
  /// the ERC20 token used as collateral
  IERC20 public DEPOSIT_CURRENCY;
  /// a string to be used as vault title
  bytes public VAULT_SYMBOL;
  /// address of the authorized account to initiate a new round
  address public VAULT_MAKER;
  /// the admin of the vault
  address public OWNER;
  /// the amount to be floored to
  uint256 public DUST_FLOOR = 1000 wei;
  /// max cap for the vault
  uint256 public DEPOSIT_CAP;
  /// to pause deposits and withdrawals(this is reseted to true when initiating a new round)
  bool public AllowInteraction = true;
  /// address of the deployed AggrigatorWrapper contract
  AggrigatorWrapper public PRICE_FEED;
  /// adress of the chainlink aggrigator to be used by the AggrigatorWrapper
  AggregatorV3Interface public LINK_AGGREGATOR;

  /// the address where the contract's fees are sent to
  address public TREASURY;
  /// deposit that will be added at 'queuedRound' for a user
  mapping(address => uint256) public queuedDeposit;
  /// round that the deposit will be added
  mapping(address => uint256) public queuedRound;
  /// total deposits in the vault from users for each round
  mapping(uint256 => uint256) public totalDeposit;
  /// total deposits in the vault from users for each round
  mapping(address => uint256) public userTotalDeposit;
  /// track the sum of all deposits currently present on the vault
  uint256 public vaultTotalDeposits;
  /// total amount of colletirals in the vault for each round
  mapping(uint256 => uint256) public totalAsset;
  /// total amount deposited by uesr
  mapping(address => uint256) public activeDeposit;
  /// amount that will be withdrowen after the 'withdrawQueueRound'
  mapping(address => uint256) public withdrawQueueAmt;
  /// the round that the queued withdraw can be withdrown
  mapping(address => uint256) public withdrawQueueRound;
  /// total amount withdrown in each round
  mapping(uint256 => uint256) public totalWithdraw;
  /// total amount of colatirals withdrawn scaled for each round
  mapping(uint256 => uint256) public scaledTotalWithdraw;
  /// the premium payed by the maker in the start of each round
  mapping(uint256 => uint256) public premiumPaid;
  /// the amount sent to the vault maker at the end of each round
  mapping(uint256 => uint256) public settlementLoss;
  /// the amount withdrown after each round
  mapping(uint256 => uint256) public preRoundWithdraw;
  /// the strike price for each round
  mapping(uint256 => uint256) public strikeX1e6;
  /// the spotPrice for each round
  mapping(uint256 => uint256) public spotPrice;
  /// the settlementPrice for each round
  mapping(uint256 => uint256) public priceOnExpiryX1e6;
  /// the performanceFee deducted in each round
  mapping(uint256 => uint256) public performanceFee;
  /// the managementFee deducted in each round
  mapping(uint256 => uint256) public managementFee;
  /// the oracleTime on settelement for each round
  mapping(uint256 => uint256) public timeOnExpiry;
  /// the scaled total amount in the vault in each round
  mapping(uint256 => uint256) public assetScaleX1e36;
  /// the scalad balance for each user
  mapping(address => uint256) public userScaleX1e36;
  uint256 public minSizeOfVault;
  mapping(uint256 => uint80) public startRoundID;
  mapping(uint256 => uint80) public settlementRoundID;
  uint256 private _currentAssets;
  uint256 private _scaledTotalWithdraw;
  uint256 private _assetScaleX1e36;
  uint256 private _userScaleX1e36;
  mapping(uint256 => uint256) private _totalWithdrawFromUserDeposits;
  uint256 public vaultTotalClaimableWithdrawals;

  event QueueDeposit(
    address indexed _from,
    uint256 indexed _round,
    uint256 _amt
  );
  event QueueWithdraw(
    address indexed _from,
    uint256 indexed _round,
    uint256 _amt
  );
  event Withdraw(address indexed _from, uint256 indexed _round, uint256 _amt);
  event NewRound(
    address indexed _from,
    uint256 indexed _round,
    uint256 _strikeX1e6,
    uint256 _premium,
    uint256 _minSizeOfVault
  );
  event Settlement(
    uint256 indexed _round,
    uint256 _strikeX1e6,
    uint256 _oracleTime,
    uint256 _settlementLoss
  );

  constructor() {
    _disableInitializers();
  }

  /**
   * @param _type: 0 for put vault, 1 for call vault
   * @param startTime: Time to start the first round
   * @param period: Duration of each round
   * @param collatCap: Vault max deposit (deposit cap)
   * @param collateralAddress: Address of the collateral token (WETH token / WBTC Token …)
   * @param aggrigatorWrapper: Address of the deployed AggrigatorWrapper (needs to be deployed at least once)
   * @param linkAggregator: Address of the chain link aggregator used to get price of the collateral asset
   * @param collateralSymbolCoinbase: A bytes that represent the collateral Symbol (acts like a title for the vault)
   * @param vaultMaker: Account address that will initiate rounds
   * @param owner: Address of the admin of the contract
   * @param treasury: Address of the Fees recipient
   */
  function initialize(
    VaultTypes _type,
    uint256 startTime,
    uint256 period,
    uint256 collatCap,
    address collateralAddress,
    address aggrigatorWrapper,
    address linkAggregator,
    bytes memory collateralSymbolCoinbase,
    address vaultMaker,
    address owner,
    address treasury
  ) public {
    AllowInteraction = true;
    DUST_FLOOR = 1000 wei;
    VAULT_TYPE = _type;
    TREASURY = treasury;
    round = 0;
    roundExpiry = 0;
    START_TIME = startTime;
    ROUND_PERIOD = period;
    DEPOSIT_CAP = collatCap;
    DEPOSIT_CURRENCY = IERC20(collateralAddress);
    VAULT_SYMBOL = collateralSymbolCoinbase;
    PRICE_FEED = AggrigatorWrapper(aggrigatorWrapper);
    LINK_AGGREGATOR = AggregatorV3Interface(linkAggregator);
    VAULT_MAKER = vaultMaker;
    OWNER = owner;
    assetScaleX1e36[0] = 1e36;
  }

  modifier clearQueue() {
    require(AllowInteraction == true, "vault paused.");

    uint256 userWithdrawRound = withdrawQueueRound[msg.sender];
    if (userWithdrawRound > 0) {
      if (
        ((round == userWithdrawRound - 1) && (roundExpiry == 0)) ||
        (round >= userWithdrawRound)
      ) {
        activeDeposit[msg.sender] =
          (activeDeposit[msg.sender] * assetScaleX1e36[userWithdrawRound - 1]) /
          userScaleX1e36[msg.sender];
        userScaleX1e36[msg.sender] = assetScaleX1e36[userWithdrawRound - 1];
        _withdraw();
      }
    }
    if (queuedDeposit[msg.sender] > 0) {
      if (round >= queuedRound[msg.sender]) {
        activeDeposit[msg.sender] =
          (activeDeposit[msg.sender] *
            assetScaleX1e36[queuedRound[msg.sender] - 1]) /
          userScaleX1e36[msg.sender];
        activeDeposit[msg.sender] += queuedDeposit[msg.sender];
        userScaleX1e36[msg.sender] = assetScaleX1e36[
          queuedRound[msg.sender] - 1
        ];
        queuedRound[msg.sender] = 0;
        queuedDeposit[msg.sender] = 0;
      }
    }
    if (userScaleX1e36[msg.sender] != assetScaleX1e36[round]) {
      if (activeDeposit[msg.sender] > 0) {
        activeDeposit[msg.sender] =
          (activeDeposit[msg.sender] * assetScaleX1e36[round]) /
          userScaleX1e36[msg.sender];
      }
      userScaleX1e36[msg.sender] = assetScaleX1e36[round];
    }

    _;
  }

  function processQueue() public clearQueue {}

  /**
   * Queue WETH for deposit. Contract will enjoin all queued WETH for next epoch.
   * Cannot have pending withdrawal while depositing
   * Deposits and withdrawals are both on a queued basis.
   * To reduce complexity, each epoch can only have either a pending deposit or withdrawal, to assist with accounting.
   * If a user wants to deposit while withdrawal is pending, recommend to the user to cancel the existing withdrawal.
   * If the user wants to deposit when withdrawal is ready, recommend the user to withdraw first.
   * @param amt: amount to deposit
   */
  function deposit(uint256 amt) external clearQueue {
    require(withdrawQueueRound[msg.sender] == 0, "withdrawQueue!=0");

    if (amt == 0) {
      if (queuedRound[msg.sender] > round) {
        uint256 amtToRemove = queuedDeposit[msg.sender];
        uint256 roundRemove = queuedRound[msg.sender];
        queuedDeposit[msg.sender] = 0;
        queuedRound[msg.sender] = 0;
        totalDeposit[roundRemove] -= amtToRemove;
        userTotalDeposit[msg.sender] -= amtToRemove;
        vaultTotalDeposits -= amtToRemove;
        DEPOSIT_CURRENCY.safeTransfer(msg.sender, amtToRemove);
      }
    } else {
      queuedDeposit[msg.sender] += amt;
      queuedRound[msg.sender] = round + 1;
      totalDeposit[round + 1] += amt;
      addToUserDeposit(msg.sender, amt);
      DEPOSIT_CURRENCY.safeTransferFrom(msg.sender, address(this), amt);
    }
    require(vaultTotalDeposits <= DEPOSIT_CAP, "Vault max deposit reached");
    emit QueueDeposit(msg.sender, round, amt);
  }

  /**
   * Queue WETH for withdrawal.
   * Calling initWithdraw can be called multiple times per epoch, latest call will be valid
   */
  function initWithdraw() external clearQueue returns (uint256) {
    require(queuedRound[msg.sender] <= round, "depositQueue!=0");
    uint256 amt = activeDeposit[msg.sender];

    if (roundExpiry == 0) {
      preRoundWithdraw[round] += amt;
      activeDeposit[msg.sender] -= amt;
      removeFromUserDeposit(msg.sender);
      DEPOSIT_CURRENCY.safeTransfer(msg.sender, amt);
      return amt;
    } else {
      if (withdrawQueueRound[msg.sender] == round + 1) {
        // remove user total deposit
        _totalWithdrawFromUserDeposits[round + 1] -= userTotalDeposit[
          msg.sender
        ];
        totalWithdraw[round + 1] -= withdrawQueueAmt[msg.sender];
        withdrawQueueAmt[msg.sender] = 0;
      }

      withdrawQueueAmt[msg.sender] = amt;
      withdrawQueueRound[msg.sender] = round + 1;
      totalWithdraw[round + 1] += amt;
      // add user total deposit
      _totalWithdrawFromUserDeposits[round + 1] += userTotalDeposit[msg.sender];

      if (amt == 0) withdrawQueueRound[msg.sender] = 0;
      emit QueueWithdraw(msg.sender, round, amt);
      return amt;
    }
  }

  function cancelWithdraw() external clearQueue {
    require(
      withdrawQueueRound[msg.sender] == round + 1 && roundExpiry != 0,
      "can not cancel withdraw'"
    );
    // remove user total deposit
    _totalWithdrawFromUserDeposits[round + 1] -= userTotalDeposit[msg.sender];
    totalWithdraw[round + 1] -= withdrawQueueAmt[msg.sender];
    withdrawQueueAmt[msg.sender] = 0;
    withdrawQueueRound[msg.sender] = 0;
  }

  /**
   * Transfer queued WETH to user
   * Users must manually call this function after exit epoch.
   * Amount withdrawn will be scaled to account for settlement losses for the epoch before exit.
   */
  function withdraw() public {
    uint256 userWithdrawRound = withdrawQueueRound[msg.sender];

    require(withdrawQueueRound[msg.sender] > 0, "No Queued Withdraw");
    require(
      roundState[userWithdrawRound - 1] == RoundStates.COMPLETED,
      "Round not completed"
    );
    if (
      ((round == userWithdrawRound - 1) && (roundExpiry == 0)) ||
      (round >= userWithdrawRound)
    ) {
      processQueue();
    } else {
      revert("Withdraw not ready");
    }
  }

  function _withdraw() internal returns (uint256) {
    uint256 userWithdrawRound = withdrawQueueRound[msg.sender];
    if (userWithdrawRound == 0) return 0;
    if (
      ((round == userWithdrawRound - 1) && (roundExpiry == 0)) ||
      (round >= userWithdrawRound)
    ) {
      uint256 withdrawAmt = withdrawQueueAmt[msg.sender];
      uint256 withdrawAmtScaled = (withdrawAmt *
        scaledTotalWithdraw[userWithdrawRound]) /
        totalWithdraw[userWithdrawRound];
      withdrawQueueRound[msg.sender] = 0;
      withdrawQueueAmt[msg.sender] = 0;
      if (activeDeposit[msg.sender] <= withdrawAmtScaled)
        activeDeposit[msg.sender] = 0;
      else {
        activeDeposit[msg.sender] -= withdrawAmtScaled;
      }
      vaultTotalClaimableWithdrawals -= userTotalDeposit[msg.sender];
      removeFromUserDeposit(msg.sender);

      DEPOSIT_CURRENCY.safeTransfer(msg.sender, withdrawAmtScaled);
      emit Withdraw(msg.sender, userWithdrawRound, withdrawAmtScaled);
      return withdrawAmtScaled;
    } else {
      return 0;
    }
  }

  function RoundExpiry(uint256 _round) public view returns (uint256) {
    return _round * ROUND_PERIOD + START_TIME;
  }

  function checkVaultParams(
    uint256 roundStrikeX1e6,
    uint256 _spotPrice
  ) internal {
    uint80 roundID = 0;
    if (_spotPrice == 0) {
      (int256 price, uint80 id) = PRICE_FEED.getLastPriceX1e6(LINK_AGGREGATOR);
      _spotPrice = uint256(price);
      roundID = id;
    }
    if (VAULT_TYPE == VaultTypes.PUT) {
      require(roundStrikeX1e6 < _spotPrice, "Strike>=PriceFeed");
    } else {
      require(roundStrikeX1e6 > _spotPrice, "Strike<=PriceFeed");
    }
    startRoundID[round + 1] = roundID;
    spotPrice[round + 1] = _spotPrice;
  }

  /**
   * Only maker can call this function to initiate new round
   * Maker should allow contract to transfer premium amount of collateral
   * This function can only be called when there is pending deposits and the last round is expired
   * @param roundStrikeX1e6:the round strike price
   * @param _spotPrice:the round spot price
   * @param _minSizeOfVault:should be greater or equal to the deposited assets to prevent deposit slippage attacks
   */
  function initNewRound(
    uint256 roundStrikeX1e6,
    uint256 _spotPrice,
    uint256 _minSizeOfVault
  ) external {
    require(msg.sender == VAULT_MAKER, "NotDesignatedMaker");
    if ((block.timestamp > roundExpiry) && (roundExpiry != 0))
      settleStrikeByRoundExpiry();
    require(roundExpiry == 0, "NotExpiredYet");
    require(
      roundState[round] == RoundStates.UNSET ||
        roundState[round] == RoundStates.COMPLETED,
      "round not completed"
    );
    AllowInteraction = true;

    while (block.timestamp > RoundExpiry(round + 1)) {
      round += 1;
      uint preRoundSubs = scaledTotalWithdraw[round] +
        settlementLoss[round - 1] +
        performanceFee[round - 1] +
        managementFee[round - 1] +
        preRoundWithdraw[round - 1];
      totalAsset[round] = totalAsset[round - 1] + totalDeposit[round];
      if (totalAsset[round] <= preRoundSubs) totalAsset[round] = 0;
      else totalAsset[round] -= preRoundSubs;
      assetScaleX1e36[round] = assetScaleX1e36[round - 1];
      roundState[round] = RoundStates.COMPLETED;
    }
    checkVaultParams(roundStrikeX1e6, _spotPrice);

    strikeX1e6[round + 1] = roundStrikeX1e6;
    uint subs = scaledTotalWithdraw[round + 1] +
      settlementLoss[round] +
      performanceFee[round] +
      managementFee[round] +
      preRoundWithdraw[round];
    uint256 totalAssetNow = totalAsset[round] +
      premiumPaid[round] +
      totalDeposit[round + 1];
    if (totalAssetNow <= subs) totalAssetNow = 0;
    else totalAssetNow -= subs;
    totalAsset[round + 1] = totalAssetNow;
    assetScaleX1e36[round + 1] = assetScaleX1e36[round];
    roundState[round + 1] = RoundStates.PREPARING;
    round += 1;
    roundExpiry = RoundExpiry(round);
    require(totalAsset[round] >= _minSizeOfVault, "Vault size too small.");
    minSizeOfVault = _minSizeOfVault;
  }

  function sendPremium(uint256 premium) external {
    require(msg.sender == VAULT_MAKER, "NotDesignatedMaker");
    require(roundState[round] == RoundStates.PREPARING, "round not initiated");
    DEPOSIT_CURRENCY.safeTransferFrom(msg.sender, address(this), premium);

    premiumPaid[round] = premium;

    require(totalAsset[round] > premium + DUST_FLOOR, "No deposit in vault");
    roundState[round] = RoundStates.STARTED;
    emit NewRound(
      msg.sender,
      round,
      strikeX1e6[round],
      premium,
      minSizeOfVault
    );
  }

  /**
   * In the first hour, Only VAULT_MAKER and Maker can call this, to allow VAULT_MAKER to overwrite the price with settleStrikeManual with a suitable index
   * However, to prevent user from being locked out unfairly, settleStrike can be called by anyone after 1 hour
   */
  function settleStrikeByRoundExpiry() internal {
    if (block.timestamp < roundExpiry + 1 hours) {
      require(msg.sender == VAULT_MAKER, "Not Maker For First Hour");
    }
    (int256 price, uint80 roundID) = PRICE_FEED.getPriceByTime(
      LINK_AGGREGATOR,
      roundExpiry
    );
    _settleStrike(
      uint256(price) / 1e2,
      LINK_AGGREGATOR.latestTimestamp(),
      roundID
    );
  }

  /**
   * In the case unable to find a roundID that is immediately after expiry and preceded by a block before expiry, we just take the latest price result even if its before expiry, as long as block time is 2 hours after expiry
   */
  function settlementPendingExpired() external {
    require(
      block.timestamp > roundExpiry + 2 hours,
      "Allowed 2 hour after expiry"
    );
    (int256 price, uint80 roundID) = PRICE_FEED.getLastPriceX1e6(
      LINK_AGGREGATOR
    );
    _settleStrike(uint256(price), roundExpiry, roundID);
  }

  function settlementPending(uint256 price) external {
    if (price > 0) {
      settleStrikeManual(price);
    } else {
      settleStrikeByRoundExpiry();
    }
  }

  function _settleStrike(
    uint256 priceX1e6,
    uint256 oracleTime,
    uint80 roundID
  ) internal {
    require(
      roundState[round] == RoundStates.STARTED ||
        roundState[round] == RoundStates.PENDING,
      "Round not Started"
    );
    if (VAULT_TYPE == VaultTypes.PUT) {
      _settleStrike_put(priceX1e6, oracleTime, roundID);
    } else {
      _settleStrike_call(priceX1e6, oracleTime, roundID);
    }
  }

  function _settleStrike_call(
    uint256 priceX1e6,
    uint256 oracleTime,
    uint80 roundID
  ) internal {
    require(oracleTime >= roundExpiry, "Not Expired");
    require(block.timestamp >= roundExpiry, "Not Expired");
    if (roundExpiry > 0) {
      uint256 settlementPrice = priceX1e6;
      if (settlementPrice > strikeX1e6[round]) {
        settlementLoss[round] =
          (totalAsset[round] * (settlementPrice - strikeX1e6[round])) /
          (settlementPrice);
        performanceFee[round] = 0;
        managementFee[round] = 0;
      } else {
        settlementLoss[round] = 0;
        calculateManagementFees();
        calculatePerformanceFees();
      }

      _currentAssets =
        totalAsset[round] +
        premiumPaid[round] -
        settlementLoss[round] -
        managementFee[round] -
        performanceFee[round];
      _scaledTotalWithdraw =
        (totalWithdraw[round + 1] * _currentAssets) /
        totalAsset[round];
      _assetScaleX1e36 =
        (assetScaleX1e36[round] * _currentAssets) /
        totalAsset[round];
      _userScaleX1e36 = assetScaleX1e36[round];

      priceOnExpiryX1e6[round] = settlementPrice;
      timeOnExpiry[round] = oracleTime;
      settlementRoundID[round] = roundID;
      roundState[round] = RoundStates.PENDING;
    }
  }

  function _settleStrike_put(
    uint256 priceX1e6,
    uint256 oracleTime,
    uint80 roundID
  ) internal {
    require(oracleTime >= roundExpiry, "Not Expired");
    require(block.timestamp >= roundExpiry, "Not Expired");
    if ((roundExpiry > 0)) {
      uint256 settlementPrice = priceX1e6;
      if (settlementPrice < strikeX1e6[round]) {
        settlementLoss[round] =
          (totalAsset[round] * (strikeX1e6[round] - settlementPrice)) /
          strikeX1e6[round];
        performanceFee[round] = 0;
        managementFee[round] = 0;
      } else {
        settlementLoss[round] = 0;
        calculateManagementFees();
        calculatePerformanceFees();
      }
      _currentAssets =
        totalAsset[round] +
        premiumPaid[round] -
        settlementLoss[round] -
        managementFee[round] -
        performanceFee[round];
      _scaledTotalWithdraw =
        (totalWithdraw[round + 1] * _currentAssets) /
        totalAsset[round];
      _assetScaleX1e36 =
        (assetScaleX1e36[round] * _currentAssets) /
        totalAsset[round];
      _userScaleX1e36 = assetScaleX1e36[round];

      priceOnExpiryX1e6[round] = settlementPrice;
      timeOnExpiry[round] = oracleTime;
      settlementRoundID[round] = roundID;
      roundState[round] = RoundStates.PENDING;
    }
  }

  function settlementComplete() external {
    require(msg.sender == VAULT_MAKER, "Not Maker");
    require(roundState[round] == RoundStates.PENDING, "Round not Pending");

    if (settlementLoss[round] > 0)
      DEPOSIT_CURRENCY.safeTransfer(VAULT_MAKER, settlementLoss[round]);
    if (performanceFee[round] + managementFee[round] > 0)
      DEPOSIT_CURRENCY.safeTransfer(
        TREASURY,
        performanceFee[round] + managementFee[round]
      );
    _currentAssets =
      totalAsset[round] +
      premiumPaid[round] -
      settlementLoss[round] -
      managementFee[round] -
      performanceFee[round];
    scaledTotalWithdraw[round + 1] =
      (totalWithdraw[round + 1] * _currentAssets) /
      totalAsset[round];
    assetScaleX1e36[round] =
      (assetScaleX1e36[round] * _currentAssets) /
      totalAsset[round];
    vaultTotalClaimableWithdrawals += _totalWithdrawFromUserDeposits[round + 1];
    userScaleX1e36[address(this)] = assetScaleX1e36[round];
    roundState[round] = RoundStates.COMPLETED;
    roundExpiry = 0;
    emit Settlement(
      round,
      priceOnExpiryX1e6[round],
      timeOnExpiry[round],
      settlementLoss[round]
    );
  }

  function calculateManagementFees() internal {
    managementFee[round] = (totalAsset[round] * 20) / 52 / 1000;
  }

  function calculatePerformanceFees() internal {
    performanceFee[round] = (premiumPaid[round] * 10) / 100;
  }

  function removeFromUserDeposit(address tgt) internal {
    vaultTotalDeposits -= userTotalDeposit[tgt];
    userTotalDeposit[tgt] = 0;
  }

  function addToUserDeposit(address tgt, uint256 amt) internal {
    vaultTotalDeposits += amt;
    userTotalDeposit[tgt] += amt;
  }

  /**
   * Allows OWNER to arbitrarily transfer Ownership
   * @param _newOwner:address of the new owner of the vault
   */
  function setOwner(address _newOwner) external {
    require(msg.sender == OWNER, "Not Owner");
    OWNER = _newOwner;
  }

  /**
   * Allows Maker to arbitrarily change the treasury address
   * @param _newTreasury:the address where the contract's fees are sent to
   */
  function setTreasury(address _newTreasury) external {
    require(msg.sender == VAULT_MAKER, "Not Maker");
    TREASURY = _newTreasury;
  }

  /**
   * Allows Maker to arbitrarily set settlement price
   * @param priceX1e6 : the settelement price
   */
  function settleStrikeManual(uint256 priceX1e6) internal {
    require(msg.sender == VAULT_MAKER, "Not Maker");
    _settleStrike(priceX1e6, roundExpiry, 0);
  }

  /**
   * Allows Maker to arbitrarily set expiry date for current round
   * @param arbitraryExpiry: new date
   */
  function setExpiry(uint256 arbitraryExpiry) external {
    require(msg.sender == VAULT_MAKER, "Not Maker");
    roundExpiry = arbitraryExpiry;
  }

  /**
   * Allows VAULT_MAKER to arbitrarily set deposit cap
   * @param newDepositCap: new Cap
   */
  function setMaxCap(uint256 newDepositCap) external {
    require(msg.sender == VAULT_MAKER, "Not VAULT_MAKER");
    DEPOSIT_CAP = newDepositCap;
  }

  /**
   * Allows OWNER to arbitrarily change MAKER
   * @param newMaker: address of the newMaker
   */
  function setMaker(address newMaker) external {
    require(msg.sender == OWNER, "Not Owner");
    VAULT_MAKER = newMaker;
  }

  /**
   * Allows VAULT_MAKER to arbitrarily change AggrigatorWrapper address
   * @param newAggrigatorWrapper: new AggrigatorWrapper address
   */
  function setAggrigatorWrapper(
    AggrigatorWrapper newAggrigatorWrapper
  ) external {
    require(msg.sender == VAULT_MAKER, "Not VAULT_MAKER");
    PRICE_FEED = newAggrigatorWrapper;
  }

  /**
   * Set ALLOW_INTERACTIONS - VAULT_MAKER can arbitrarily stop deposits and withdrawals.
   * @param _flag: new value
   */
  function setAllowInteraction(bool _flag) external {
    require(msg.sender == VAULT_MAKER, "Not VAULT_MAKER");
    AllowInteraction = _flag;
  }

  /**
   * Allows VAULT_MAKER to deposit on behalf. This is used for upgrading contracts primarily, and for potential future use cases such as meta-vaults.
   * @param tgt : user wallet address
   * @param amt : the amount to deposit
   */
  function depositOnBehalf(address tgt, uint256 amt) external {
    require(msg.sender == VAULT_MAKER, "Not VAULT_MAKER");
    require(withdrawQueueRound[tgt] == 0, "withdrawQueue!=0");
    queuedDeposit[tgt] += amt;
    queuedRound[tgt] = round + 1;
    totalDeposit[round + 1] += amt;
    addToUserDeposit(tgt, amt);
    userScaleX1e36[tgt] = assetScaleX1e36[round];
    DEPOSIT_CURRENCY.safeTransferFrom(msg.sender, address(this), amt);
    emit QueueDeposit(tgt, round, amt);
  }

  function _authorizeUpgrade(address newImplementation) internal view override {
    require(msg.sender == OWNER, "Not Owner");
    require(newImplementation != address(0), "address zero");
  }
}