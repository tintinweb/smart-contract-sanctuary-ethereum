/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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

// File: contracts/SmartSwapV2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma abicoder v2;






interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface SmartFinanceHelper {
    // calculates the token amount that will be received after deducting stargate's fees
    function getDstAmountAfterFees (
        uint16 dstChainId,
        address dstSupportToken,
        address srcSupportToken,
        uint256 srcChainTokenAmt
    ) external view returns(uint256);

    // calculates the protocol fees
    function calculateProtocolFees (
        uint256 _amount,
        bool _islocal
    ) external view returns(uint256);

    // gets the fee address where protocol fees is collected
    function feeAddress() external view returns(address);

    // gets the referral fee.
    function calculateProtocolReferralFees(
        uint256 _amount
    ) external view returns(uint256);

    // Get the referral address.
    function getReferralInfo(address _msgSender) external view returns(address);
    // Get the referral ID.
    function getReferralID(address _address) external view returns(uint256);
    // Set the referral ID.
    function setReferralInfo(address _address, address _value) external;
    // Get Destination referral address.
    function getDestReferralID(uint256 _key) external view returns(address);
}

interface SmartFinanceRouter {
    // smart router's functions that calls stargate's router contract to enable cross chain swap
    function sendSwap(
        address initiator,
        bytes memory stargateData,
        bytes memory payload,
        uint256 dstChainReleaseAmt
    ) external payable;
}

library StringHelper {
    function concat(
        bytes memory a,
        bytes memory b
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }
    
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return 'Transaction reverted silently';
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
}

contract SmartSwapV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable{
    using StringHelper for bytes;
    using StringHelper for uint256;

    // Smart Finance Contracts
    address public smartRouter;
    address public smartHelper;

    // Failed Tx Recovery Address.
    address public failedTxRecovery;
    
    // Mapping for supported tokens by stargate
    mapping(address => bool) public isSupportToken;
    // Mapping for decimals for each stargate's supported token of destination chains.
    mapping(uint16 => mapping(address => uint8)) public dstSupportDecimal;

    bool public isWhitelistActive;
    mapping(address => bool) public isWhitelisted;

    address public swapTarget0x;

    event Swap(
        address initiator,
        address buyToken,
        uint256 buyAmount,
        address sellToken,
        uint256 sellAmount,
        address receiver
    );

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Using this function to initialize the smart swap's parameters
    /// @param _supportToken Address of the stargate supported stable token
    /// @param _recovery account address that can failed transactions to get tokens out of the account  
    function initialize (
        address _supportToken,
        address _recovery
    ) public initializer {
        require(_supportToken != address(0),"Invalid Address");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        isSupportToken[_supportToken] = true;
        failedTxRecovery = _recovery; 
    }

    receive() external payable {}

    /// @notice withdraw token from the router contract (Only owner can call this fn)
    /// @param _token address of the token owner wishes to withdraw from the contract
    function withdraw(address _token) onlyOwner external {
        require(_token != address(0), "Invalid Address");
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice function to Pause smart contract.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice function to UnPause smart contract
    function unPause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice withdraw chain native token from the router contract (Only owner can call this fn)
    function withdrawETH() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    /// @notice updates the 0x Smart Swap target address.
    function updateswapTarget0x(address _swapTarget) public onlyOwner {
        require(address(_swapTarget) != address(0),"No Zero Address");
        swapTarget0x = _swapTarget;
    }

    /// @notice updates the account address which can call the contract to recover failed transactions
    /// @param _recovery account address
    function updateFailedTxRecoveryAddress(address _recovery) public onlyOwner whenNotPaused {
        failedTxRecovery = _recovery;
    }

    function addToWhitelist(address[] calldata _addresses) public onlyOwner {
        require(_addresses.length <= 100,"Whitelist List exceeds allowed limit.");
        for(uint256 i = 0; i < _addresses.length; i++) {
            require(address(_addresses[i]) != address(0),"No Zero Address");
            isWhitelisted[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _addresses) public onlyOwner {
        require(_addresses.length <= 100,"Whitelist List exceeds allowed limit.");
        for(uint256 i = 0; i < _addresses.length; i++) {
            require(address(_addresses[i]) != address(0),"No Zero Address");
            isWhitelisted[_addresses[i]] = false;
        }
    } 

    function toggleWhitelistState() external onlyOwner {
        isWhitelistActive = !isWhitelistActive;
    }

    /// @notice updates smart helper contract
    /// @param _helper smart helper contract address
    function updateHelper(
        address _helper
    ) external onlyOwner whenNotPaused {
        require(_helper != address(0),"Invalid Address");
        smartHelper = _helper;
    }

    /// @notice updates smart router contract
    /// @param _router smart router contract address
    function updateRouter(
        address _router
    ) external onlyOwner whenNotPaused {
        require(_router != address(0),"Invalid Address");
        smartRouter = _router;
    }

    /// @notice updates destination chain's supported tokens
    /// @param _dstChainId destination chain id
    /// @param _dstToken stargate supported destination stable token address
    /// @param _dstTokenDecimal token decimals for the token
    function updateDstSupport(
        uint16 _dstChainId,
        address _dstToken,
        uint8 _dstTokenDecimal
    ) external onlyOwner whenNotPaused {
        require(_dstToken != address(0),"Invalid Address");
        dstSupportDecimal[_dstChainId][_dstToken] = _dstTokenDecimal;
    }

    /// @notice updates src chain's support tokens
    /// @param _supportToken stargate supported src stable token address
    function updateSupportToken(
        address _supportToken
    ) external onlyOwner whenNotPaused {
        require(_supportToken != address(0),"Invalid Address");
        isSupportToken[_supportToken] = true;
    }

    /// @notice updates src chain's support tokens
    /// @param _supportToken stargate supported src stable token address
    function removeSupportToken(
        address _supportToken
    ) external onlyOwner whenNotPaused {
        require(_supportToken != address(0),"Invalid Address");
        isSupportToken[_supportToken] = false;
    }



    /// @notice performs local swap from native to token
    /// @param buyToken token address which the user wants to swap the native token for
    /// @param sellAmt amount of native token user wants to swap
    /// @param receiver address where swapped tokens are to be transferred
    /// @param swapTarget 0x protocol's dex address to enable swap
    /// @param swapData byte data containing the local swap information
    function swapNativeForTokens(
        address buyToken,
        uint256 sellAmt,
        address receiver,
        address swapTarget,
        bytes memory swapData
    ) external payable nonReentrant() whenNotPaused {
        if(isWhitelistActive) {
            require(isWhitelisted[msg.sender],"You are NOT Whitelisted");
        }
        // Track balance of the buyToken to determine how much we've bought.
        uint256 currBuyBal = IERC20(buyToken).balanceOf(address(this));

        // Validate swapTarget
        require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");

        // Swap Token For Token
        (bool success, bytes memory res) = swapTarget.call{value: sellAmt}(swapData);
        require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));

        uint256 boughtBuyAmt = IERC20(buyToken).balanceOf(address(this)) - currBuyBal;

        // Take the fee.
        payable(SmartFinanceHelper(smartHelper).feeAddress()).transfer(SmartFinanceHelper(smartHelper).calculateProtocolFees(sellAmt, true));

        // Transfer the bought amount to the designated address.
        IERC20(buyToken).transfer(receiver, boughtBuyAmt);

        emit Swap(
            msg.sender, 
            buyToken, 
            boughtBuyAmt, 
            address(0), 
            sellAmt, 
            receiver
        );
    }

    /// @notice performs local swap from token to token
    /// @param buyToken token address which the user wants to swap the native token for
    /// @param sellToken token address which the user wantes to sell
    /// @param sellAmt amount of native token user wants to swap
    /// @param spender 0x protocol's dex address to enable swap ### ADD THIS
    /// @param swapTarget 0x protocol's dex address to enable swap
    /// @param receiver address where swapped tokens are to be transferred
    /// @param swapData byte data containing the local swap information
    function swapTokenForToken(
        address buyToken,
        address sellToken,
        uint256 sellAmt, 
        address spender, 
        address swapTarget,
        address receiver,
        bytes memory swapData
    ) public payable nonReentrant() whenNotPaused {
        if(isWhitelistActive) {
            require(isWhitelisted[msg.sender],"You are NOT Whitelisted");
        }
        // Deposit Tokens into the account
        if (msg.sender != smartRouter){
            if(msg.sender != failedTxRecovery) {
                IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmt);
            }
        }

        // We will always validate the sellAmt in form of Token.
        require(IERC20(sellToken).balanceOf(address(this)) >= sellAmt, "Insufficient Balance");

        // Validate Approval
        require(IERC20(sellToken).approve(spender, sellAmt), "Sell Token Approval Failed");

        uint256 currBuyBal = IERC20(buyToken).balanceOf(address(this));

        // Validate swapTarget
        require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");

        // Swap Token For Token
        (bool success, bytes memory res) = swapTarget.call(swapData);
        require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));

        uint256 boughtBuyAmt = IERC20(buyToken).balanceOf(address(this)) - currBuyBal;

        // Take the fee.
        payable(SmartFinanceHelper(smartHelper).feeAddress()).transfer(SmartFinanceHelper(smartHelper).calculateProtocolFees(sellAmt, true));

        // Transfer the bought amount to the designated address.
        IERC20(buyToken).transfer(receiver, boughtBuyAmt);

        emit Swap(
            msg.sender, 
            buyToken, 
            boughtBuyAmt, 
            sellToken, 
            sellAmt, 
            receiver
        );
    }

    /// @notice performs local swap from token to native
    /// @param sellToken token address which the user wantes to sell
    /// @param sellAmt amount of native token user wants to swap
    /// @param spender 0x protocol's dex address to enable swap ### ADD THIS
    /// @param swapTarget 0x protocol's dex address to enable swap
    /// @param receiver address where swapped tokens are to be transferred
    /// @param swapData byte data containing the local swap information
    function swapTokenForNative(
        address sellToken,
        uint256 sellAmt,
        address spender, 
        address swapTarget,
        address payable receiver,
        bytes memory swapData
    ) public payable nonReentrant() whenNotPaused {
        if(isWhitelistActive) {
            require(isWhitelisted[msg.sender],"You are NOT Whitelisted");
        }
        // Deposit Tokens into the account
        if (msg.sender != smartRouter){
            if(msg.sender != failedTxRecovery) {
                IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmt);
            }
        }
        
        // We will always validate the sellAmt in form of Token.
        require(IERC20(sellToken).balanceOf(address(this)) >= sellAmt, "Insufficient Balance");

        // Validate Approval
        require(IERC20(sellToken).approve(spender, sellAmt), "Sell Token Approval Failed");

        uint256 currBuyBal = address(this).balance;

        // Validate swapTarget
        require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");

        // Swap Token For ETH
        (bool success, bytes memory res) = swapTarget.call(swapData);
        require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));

        uint256 boughtBuyAmt = address(this).balance - currBuyBal;

        // Take the fee.
        payable(SmartFinanceHelper(smartHelper).feeAddress()).transfer(SmartFinanceHelper(smartHelper).calculateProtocolFees(sellAmt, true));
        
        // Transfer ETH to the designated address.
        receiver.transfer(boughtBuyAmt);
        
        emit Swap(
            msg.sender, 
            address(0), 
            boughtBuyAmt, 
            sellToken, 
            sellAmt, 
            receiver
        );
    }
    // Helper Functions
    /// @notice creates destination payload to enable swapping to enable user to get the desired token on the destination chain
    /// @dev return payload to enable swapping to enable user to get the desired token on the destination chain
    /// @param key referralID
    /// @param srcChainData encoded stargate's destination chain id, src chain stable token and src chain stable token amount
    /// @param dstChainSwapData encoded data with information of destination local swap
    function _createDstChainPayload(
        uint256 key,
        bytes memory srcChainData,
        bytes memory dstChainSwapData
    ) internal view returns (bytes memory payload) {
        (
            address dstChainSupportToken,
            address dstChainToken,
            uint256 dstChainAmount,
            address spender,
            address swapTarget,
            address payable dstReceiver,
            bytes memory swapData
        ) = abi.decode(dstChainSwapData, (address, address, uint256, address, address, address, bytes));

        // Determine the releaseAmt for Destination
        {
            (uint16 dstChainId, address srcChainToken, uint256 srcChainReleaseAmt) = abi.decode(srcChainData, (uint16,address,uint256));
            // Normalising the value to 6 decimals.
            srcChainReleaseAmt = srcChainReleaseAmt * 10**6 / (10**IERC20(srcChainToken).decimals());
            uint256 afterStargateFees = SmartFinanceHelper(smartHelper).getDstAmountAfterFees(
                dstChainId,
                dstChainSupportToken,
                srcChainToken,
                srcChainReleaseAmt
            );
            // After Protocol Fees
            afterStargateFees = afterStargateFees - SmartFinanceHelper(smartHelper).calculateProtocolFees(afterStargateFees, false);
            // After Stargate Fees
            afterStargateFees = afterStargateFees * (10**dstSupportDecimal[dstChainId][dstChainSupportToken]) / 10**6;
            // Check if the release amount at destination is greater than what we anticipate.
            require(afterStargateFees >= dstChainAmount,"Insufficient Destination Amount");
        }


        if(dstChainToken == address(0)){
            // Native at Destination
            bytes memory actionObject = abi.encode(
                dstChainSupportToken,
                dstChainAmount,
                spender,
                swapTarget,
                dstReceiver,
                swapData
            );

            return (
                abi.encode(
                    msg.sender,
                    uint16(3),
                    key,
                    actionObject
                )
            );
        } else if(dstChainToken == dstChainSupportToken) {
            // Support Token at Destination
            bytes memory actionObject = abi.encode(
                dstChainSupportToken,
                dstChainAmount,
                dstReceiver
            );

            return (
                abi.encode(
                    msg.sender,
                    uint16(1),
                    key,
                    actionObject
                )
            );
        } else {
            // Token at Destination
            bytes memory actionObject = abi.encode(
                dstChainToken,
                dstChainSupportToken,
                dstChainAmount,
                spender,
                swapTarget,
                dstReceiver,
                swapData
            );

            return (
                abi.encode(
                    msg.sender,
                    uint16(2),
                    key,
                    actionObject
                )
            );
        }
    }

    // Cross Swap
    /// @notice performs cross chain swap from native on src chain to token on destination chain
    /// @param dstChainId stargate's destination chain id
    /// @param srcChainSwapData encoded data with information of src chain local swap
    /// @param dstChainSwapData encoded data with information of destination chain local swap
    /// @param stargateData encoded data with information of stargate cross chain swap
    function sendCrossSwapNativeForToken(
        uint16 dstChainId,
        address referralID,
        bytes memory srcChainSwapData,
        bytes memory dstChainSwapData,
        bytes memory stargateData
    ) external payable nonReentrant() whenNotPaused {
        if(isWhitelistActive) {
            require(isWhitelisted[msg.sender],"You are NOT Whitelisted");
        }

        uint256 key;
        {
            if (referralID == address(0)) {
                if (SmartFinanceHelper(smartHelper).getReferralInfo(msg.sender) != address(0)) {
                    key = SmartFinanceHelper(smartHelper).getReferralID(SmartFinanceHelper(smartHelper).getReferralInfo(msg.sender));
                }
            } else {
                require(SmartFinanceHelper(smartHelper).getReferralID(referralID) != 0, "SMRT: Invalid Ref ID");
                SmartFinanceHelper(smartHelper).setReferralInfo(msg.sender,referralID);
                key = SmartFinanceHelper(smartHelper).getReferralID(referralID);
            }
        }

        // Break the Src Chain Swap Data
        (
            uint256 sellAmt,
            address srcBuyToken,
            address swapTarget,
            bytes memory swapData
        ) = abi.decode(srcChainSwapData, (uint256, address, address, bytes));

        uint256 balance = IERC20(srcBuyToken).balanceOf(address(this));

        require(isSupportToken[srcBuyToken],"Not Support Token");

        // Swap Native for Support Token
        {
            // Validate swapTarget
            require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");

            // Swap Native For Token
            (bool success, bytes memory res) = swapTarget.call{value: sellAmt}(swapData);
            require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
        }

        // Updated Balance
        balance = IERC20(srcBuyToken).balanceOf(address(this)) - balance;

        // Create Payload for Destination
        bytes memory payload = _createDstChainPayload(
            key,
            abi.encode(dstChainId,srcBuyToken,balance), 
            dstChainSwapData
        );

        // Transfer tokens to smartRouter
        IERC20(srcBuyToken).transfer(smartRouter, balance);
        // Sends the native token along with destination payload to enable swap on the destination chain
        SmartFinanceRouter(smartRouter).sendSwap{value: msg.value - sellAmt}(
            msg.sender,
            stargateData, 
            payload,
            balance
        );

    }

    /// @notice performs cross chain swap from non-native on src chain to token on destination chain
    /// @param dstChainId stargate's destination chain id
    /// @param srcChainSwapData encoded data with information of src chain local swap
    /// @param dstChainSwapData encoded data with information of destination chain local swap
    /// @param stargateData encoded data with information of stargate cross chain swap
    function sendCrossSwapTokenForToken(
        uint16 dstChainId,
        address referralID,
        bytes memory srcChainSwapData,
        bytes memory dstChainSwapData,
        bytes memory stargateData
    ) external payable nonReentrant() whenNotPaused {
        if(isWhitelistActive) {
            require(isWhitelisted[msg.sender],"You are NOT Whitelisted");
        }

        uint256 key;
        {
            if (referralID == address(0)) {
                if (SmartFinanceHelper(smartHelper).getReferralInfo(msg.sender) != address(0)) {
                    key = SmartFinanceHelper(smartHelper).getReferralID(SmartFinanceHelper(smartHelper).getReferralInfo(msg.sender));
                }
            } else {
                require(SmartFinanceHelper(smartHelper).getReferralID(referralID) != 0, "SMRT: Invalid Ref ID");
                SmartFinanceHelper(smartHelper).setReferralInfo(msg.sender,referralID);
                key = SmartFinanceHelper(smartHelper).getReferralID(referralID);
            }
        }

        // Break the Src Chain Swap Data
        (
            address srcSellToken,
            uint256 sellAmt,
            address srcBuyToken,
            address swapTarget,
            address spender,
            bytes memory swapData
        ) = abi.decode(srcChainSwapData, (address, uint256, address, address, address, bytes));

        // Transfer Tokens
        IERC20(srcSellToken).transferFrom(msg.sender, address(this), sellAmt);

        uint256 balance = IERC20(srcBuyToken).balanceOf(address(this));

        require(isSupportToken[srcBuyToken],"Not Support Token");

        if(isSupportToken[srcSellToken]){
            // Update Balance to the support Token Sell Amt.
            balance = sellAmt;
        } else 
        {
            // Swap Token for Support Token
            {
                // Validate Approval
                require(IERC20(srcSellToken).approve(spender, sellAmt), "Sell Token Approval Failed");

                // Validate swapTarget
                require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");

                // Swap Token For Token
                (bool success, bytes memory res) = swapTarget.call(swapData);
                require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
            }

            // Updated Balance
            balance = IERC20(srcBuyToken).balanceOf(address(this)) - balance;
        }
        
        // Create Payload for Destination
        bytes memory payload = _createDstChainPayload(
            key,
            abi.encode(dstChainId,srcBuyToken,balance),
            dstChainSwapData
        );

        // Transfer tokens to smartRouter
        IERC20(srcBuyToken).transfer(smartRouter, balance);

        // Sends the native token along with destination payload to enable swap on the destination chain
        SmartFinanceRouter(smartRouter).sendSwap{value: msg.value}(
            msg.sender,
            stargateData, 
            payload,
            balance
        );
    }

    /// @notice receives payload from the smart router on the destination chain to enable swapping of received stargate supported tokens into the token the user wants
    /// @param amountLD amount received from stargate's router
    /// @param payload encoded data containing information for local swap
    function receivePayload(
        uint256 amountLD,
        bytes memory payload
    ) external payable {
        require(msg.sender == smartRouter,"Only SmartFinanceRouter");
        (
            ,
            uint16 actionType,
            uint256 key,
            bytes memory actionObject
        ) = abi.decode(payload, (address, uint16, uint256, bytes));

        if(actionType == uint16(1)){
            (
                address token,
                ,
                address receiver
            ) = abi.decode(actionObject, (address, uint256, address));

            {
                // Send to the receiver
                uint256 fee = SmartFinanceHelper(smartHelper).calculateProtocolFees(amountLD, false);

                // Send Tokens
                IERC20(token).transfer(receiver, amountLD-fee);

                // Transfer the fees
                {
                    if (key != 0) {
                        // Transfer Referral Fee.
                        IERC20(token).transfer(SmartFinanceHelper(smartHelper).getDestReferralID(key), SmartFinanceHelper(smartHelper).calculateProtocolReferralFees(fee));
                        // Transfer Protocol Fee.
                        IERC20(token).transfer(SmartFinanceHelper(smartHelper).feeAddress(), fee-SmartFinanceHelper(smartHelper).calculateProtocolReferralFees(fee));
                    } else {
                        // Transfer Protocol Fee.
                        IERC20(token).transfer(SmartFinanceHelper(smartHelper).feeAddress(), fee);
                    }
                }
            }
        } else if(actionType == uint16(2)) {
            (
                address buyToken,
                address sellToken,
                uint256 sellAmt,
                address spender,
                address swapTarget,
                address receiver,
                bytes memory swapData
            ) = abi.decode(actionObject, (address, address, uint256, address, address, address, bytes));

            // Swap Support Token for Designated Token
            {
                // Get the ideal balance of the contract before transfer from Router.
                uint256 idealBalance = IERC20(sellToken).balanceOf(address(this)) - amountLD;

                // We will always validate the sellAmt.
                require(idealBalance + amountLD >= sellAmt, "Insufficient Balance");

                // Validate Approval
                require(IERC20(sellToken).approve(spender, sellAmt), "Sell Token Approval Failed");

                uint256 currBuyBal = IERC20(buyToken).balanceOf(address(this));

                // Validate swapTarget
                require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");

                // Swap Token For Token
                {
                    (bool success, bytes memory res) = swapTarget.call(swapData);
                    require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
                }

                // Transfer the bought amount to the designated address.
                {
                    uint256 boughtBuyAmt = IERC20(buyToken).balanceOf(address(this)) - currBuyBal;
                    IERC20(buyToken).transfer(receiver, boughtBuyAmt);
                }

                // Transfer the fees to feeAddress
                {
                    // Calculate Fee
                    uint256 fee = IERC20(sellToken).balanceOf(address(this)) - idealBalance;
                    require(fee >= SmartFinanceHelper(smartHelper).calculateProtocolFees(sellAmt, false), "Service Fee too low.");

                    if (key != 0) {
                        // Transfer Referral Fee.
                        IERC20(sellToken).transfer(SmartFinanceHelper(smartHelper).getDestReferralID(key), SmartFinanceHelper(smartHelper).calculateProtocolReferralFees(fee));
                        // Transfer Protocol Fee.
                        IERC20(sellToken).transfer(SmartFinanceHelper(smartHelper).feeAddress(), fee - SmartFinanceHelper(smartHelper).calculateProtocolReferralFees(fee));
                    } else {
                        // Transfer Protocol Fee.
                        IERC20(sellToken).transfer(SmartFinanceHelper(smartHelper).feeAddress(), fee);
                    }
                }
            }
        } else {
            (
                address sellToken,
                uint256 sellAmt,
                address spender,
                address swapTarget,
                address payable receiver,
                bytes memory swapData
            ) = abi.decode(actionObject, (address, uint256, address, address, address, bytes));
            
            // Swap Support Tokens For Native Asset
            {
                // Get the ideal balance of the contract before transfer from Router.
                uint256 idealBalance = IERC20(sellToken).balanceOf(address(this)) - amountLD;

                // We will always validate the sellAmt.
                require(idealBalance + amountLD >= sellAmt, "Insufficient Balance");

                // Validate Approval
                require(IERC20(sellToken).approve(spender, sellAmt), "Sell Token Approval Failed");

                uint256 currBuyBal = address(this).balance;

                // Validate swapTarget
                require(address(swapTarget) == address(swapTarget0x),"Invalid Target Address");
                
                // Swap Token For Token
                {
                    (bool success, bytes memory res) = swapTarget.call(swapData);
                    require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));
                }
                // Transfer the bought amount to the designated address.
                {
                    uint256 boughtBuyAmt = address(this).balance - currBuyBal;
                    receiver.transfer(boughtBuyAmt);
                }
                // Transfer the fees to feeAddress
                {
                    // Calculate Fee
                    uint256 fee = IERC20(sellToken).balanceOf(address(this)) - idealBalance;
                    require(fee >= SmartFinanceHelper(smartHelper).calculateProtocolFees(sellAmt, false), "Service Fee too low.");

                    if (key != 0) {
                        // Transfer Referral Fee.
                        IERC20(sellToken).transfer(SmartFinanceHelper(smartHelper).getDestReferralID(key), SmartFinanceHelper(smartHelper).calculateProtocolReferralFees(fee));
                        // Transfer Protocol Fee.
                        IERC20(sellToken).transfer(SmartFinanceHelper(smartHelper).feeAddress(), fee - SmartFinanceHelper(smartHelper).calculateProtocolReferralFees(fee));
                    } else {
                        // Transfer Protocol Fee.
                        IERC20(sellToken).transfer(SmartFinanceHelper(smartHelper).feeAddress(), fee);
                    }
                }
            }
        }
    }
}