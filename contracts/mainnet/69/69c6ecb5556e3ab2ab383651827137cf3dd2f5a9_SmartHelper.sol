/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// File: contracts/IStargateRouter.sol



pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}
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

// File: contracts/SmartHelperV2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;





interface StargateFeeLibrary {
    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    // Gets Fees for local and inter-chain swap
    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external view returns(SwapObj memory s);
}

contract SmartHelper is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    uint256 constant public MAX_INT = 2**256 - 1;
    address public smartSwap; // address of smart swap contract
    address public stargateRouter;  // address of smart router contract
    address public feeLibrary; // address of Stargate Fee Library

    // Cross-Chain Fee Charged.
    address payable public feeAddress; // address where protocol fees is collected
    // Parameters defining tiered fee structure for cross chain swap
    uint256 public TIER_1_FEE;
    uint256 public TIER_2_FEE;
    uint256 public TIER_3_FEE;
    uint256 public TIER_4_FEE;
    
    uint256 public FEE_PERCENT_BASE;

    uint256 public TIER_1_LIMIT;
    uint256 public TIER_2_LIMIT;
    uint256 public TIER_3_LIMIT;
    
    // Native Fee charged for LocalSwaps
    uint256 public localNativeFee;
    // mapping storing whitelisted src chain stable token address -> stargate pool id
    mapping(address => uint256) public srcTokenToPoolId;
    // mapping storing whitelisted dest chain stable token address -> stargate pool id
    mapping(uint16 => mapping(address => uint256)) public dstTokenToPoolId;
    // mapping storing stargate chain id -> stargate smart router address
    mapping(uint16 => address) public dstSmartRouter;

    mapping (address => address) public referralInfo;
    mapping (address => uint256) public refereeID;
    mapping (uint256 => address) public destRefereeID;
    uint256 public referralFee;
    uint256 public referralFeeBase;

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Using this function to initialize the contract parameters
    /// @param _smartSwap Address of the smart swap contract
    /// @param _stargateRouter Address of stargate's router
    /// @param _feeLibrary Address of stargate's fee library
    /// @param _localNativeFee amount of fees to be charged for local swap
    /// @param _feeAddress Address where protocol fees will be stored 
    function initialize (
        address _smartSwap,
        address _stargateRouter,
        address _feeLibrary,
        uint256 _localNativeFee,
        address payable _feeAddress
    ) public initializer {
        require(_smartSwap != address(0),"SMRT: Invalid Address");
        __Ownable_init();
        __UUPSUpgradeable_init();
        smartSwap = _smartSwap;
        stargateRouter = _stargateRouter;
        feeLibrary = _feeLibrary;
        localNativeFee = _localNativeFee;
        feeAddress = _feeAddress;
        TIER_1_FEE = 3000;
        TIER_2_FEE = 2500;
        TIER_3_FEE = 1875;
        TIER_4_FEE = 1250;

        FEE_PERCENT_BASE = 1000000;

        TIER_1_LIMIT = 1000_000_000;
        TIER_2_LIMIT = 10000_000_000;
        TIER_3_LIMIT = 50000_000_000;
    }

    /// @notice Using this function to update smart swap contract address
    /// @param _smartSwap Address of the smart swap contract
    function updateSmartSwap(
        address _smartSwap
    ) external onlyOwner {
        require(_smartSwap != address(0),"SMRT: Invalid Address");
        smartSwap = _smartSwap;
    }

    /// @notice Using this function to update stargateFee Library
    /// @param _feeLibrary Address of the smart swap contract
    function updateStargateFeeLibrary(
        address _feeLibrary
    ) external onlyOwner {
        require(_feeLibrary != address(0),"SMRT: Invalid Address");
        feeLibrary = _feeLibrary;
    }

    /// Update the protocol fees 
    /// @param _feeAddress Fee address where protocol fees is stored
    function updateProtocolFeeAddress(
        address payable _feeAddress
    ) external onlyOwner {
        require(_feeAddress != address(0),"SMRT: Invalid Address");
        feeAddress = _feeAddress;
    }

    /// @notice Using this function to add support for src chain stable tokens(Supported by Stargate)
    /// @param _token Address of the whitelisted token
    /// @param _poolId Stargate Pool id
    function updateSrcTokenPoolId(
        address _token,
        uint256 _poolId
    ) external onlyOwner {
        require(_token != address(0) && _poolId != 0, "SMRT: Invalid Inputs");
        srcTokenToPoolId[_token] = _poolId;
    }

    /// @notice Using this function to add support for dest chain stable tokens(Supported by Stargate)
    /// @param _dstChainId Stargate chain id for destination chain
    /// @param _token Address of the whitelisted token on destination chain
    /// @param _poolId Stargate Pool id for whitelisted token on destination chain
    function updateDstTokenPoolId(
        uint16 _dstChainId,
        address _token,
        uint256 _poolId
    ) external onlyOwner {
        require(_token != address(0) && _poolId != 0 && _dstChainId != 0, "SMRT: Invalid Inputs");
        dstTokenToPoolId[_dstChainId][_token] = _poolId;
    }

    /// @notice Using this function to update destination chain smart router address
    /// @param _dstChainId Stargate chain id for destination chain
    /// @param _dstSmartRouter Address of the smart router contract on destination chain
    function updateDstSmartRouter(
        uint16 _dstChainId,
        address _dstSmartRouter
    ) external onlyOwner {
        require(address(_dstSmartRouter) != address(0),"SMRT: Invalid Input");
        dstSmartRouter[_dstChainId] = _dstSmartRouter;
    }

    /// Update the protocol fees 
    /// @param _fee_tier_1 Fee to be collected for cross chain swap when amount is less than 1000 tokens
    /// @param _fee_tier_2 Fee to be collected for cross chain swap when amount is greater than 1000 tokens but less than 10000
    /// @param _fee_tier_3 Fee to be collected for cross chain swap when amount is greater than 10000 tokens but less than 50000
    /// @param _fee_tier_4 Fee to be collected for cross chain swap when amount is greater than 50000
    /// @param _feePercentBase Defines the base using which fees is calculated
    /// @param _localNativeFee Fees to be colledted for local swap
    function updateProtocolFee(
        uint256 _fee_tier_1,
        uint256 _fee_tier_2,
        uint256 _fee_tier_3,
        uint256 _fee_tier_4,
        uint256 _feePercentBase,
        uint256 _localNativeFee
    ) external onlyOwner {
        TIER_1_FEE = _fee_tier_1;
        TIER_2_FEE = _fee_tier_2;
        TIER_3_FEE = _fee_tier_3;
        TIER_4_FEE = _fee_tier_4;
        FEE_PERCENT_BASE = _feePercentBase;
        localNativeFee = _localNativeFee;
    }

    function updateProtocolTierLimits(
        uint256 _tier_1_limit,
        uint256 _tier_2_limit,
        uint256 _tier_3_limit
    ) external onlyOwner {
        TIER_1_LIMIT = _tier_1_limit;
        TIER_2_LIMIT = _tier_2_limit;
        TIER_3_LIMIT = _tier_3_limit;
    }

    /// Calculates the protocol fees
    /// @param _amount Amount on which fees needs to be calculated
    /// @param _islocal Boolean defining if swap is local or cross chain
    function calculateProtocolFees(
        uint256 _amount,
        bool _islocal
    ) external view returns(uint256) {
        if(_islocal) {
            return localNativeFee;
        } else {
            /// For cross chain swap, fees is calculated based on amount being transferred.
            if (_amount <= TIER_1_LIMIT) {
                return _amount * TIER_1_FEE / FEE_PERCENT_BASE;
            } else if (_amount > TIER_1_LIMIT && _amount <= TIER_2_LIMIT) {
                return _amount * TIER_2_FEE / FEE_PERCENT_BASE;
            } else if (_amount > TIER_2_LIMIT && _amount <= TIER_3_LIMIT) {
                return _amount * TIER_3_FEE / FEE_PERCENT_BASE;
            } else {
                return _amount * TIER_4_FEE / FEE_PERCENT_BASE;
            }
        }
    }

    /// Calculates the protocol referral fees
    /// @param _amount Amount on which fees needs to be calculated
    function calculateProtocolReferralFees(
        uint256 _amount
    ) external view returns(uint256) {
        return _amount * referralFee / referralFeeBase;
    }

    /// Encodes the src chain data for native src token
    /// @param sellAmt Amount of native token being swapped
    /// @param buyToken address of the token the needs to be bought for native token
    /// @param swapTarget 0x protocol's dex address to enable swap
    /// @param swapData byte data signifying the local swap information
    function createSrcSwapETHData(
        uint256 sellAmt,
        address buyToken,
        address swapTarget,
        bytes memory swapData
    ) external pure returns (bytes memory) {
        return abi.encode(
            sellAmt,
            buyToken,
            swapTarget,
            swapData
        );
    }

    /// Encodes the src chain data for non native src token
    /// @dev Returns back the encoded value to token swap on the src chain
    /// @param sellToken Address of token which the user wishes to swap
    /// @param sellAmt Amount of native token being swapped
    /// @param buyToken address of the token the needs to be bought for native token
    /// @param swapTarget 0x protocol's dex address to enable swap
    /// @param spender 0x protocol's dex address to enable swap
    /// @param swapData byte data signifying the local swap information
    function createSrcSwapData(
        address sellToken,
        uint256 sellAmt,
        address buyToken,
        address swapTarget,
        address spender,
        bytes memory swapData
    ) external pure returns (bytes memory) {
        return abi.encode(
            sellToken,
            sellAmt,
            buyToken,
            swapTarget,
            spender,
            swapData
        );
    }

    /// Encodes the dest chain data for dest token
    /// @dev Returns back the encoded value to token swap on the destination chain
    /// @param dstChainSupportToken Address of stargate supported stable token which is used to enable destination chain swap
    /// @param dstChainToken Address of the token user wants on the destination chain
    /// @param dstChainReleaseAmt Amount to be released by stargate on the destination chain
    /// @param spender 0x protocol's dex address to enable swap
    /// @param swapTarget 0x protocol's dex address to enable swap
    /// @param dstReceiver Address where swapped tokens will be transferred on the destination chain
    /// @param swapData byte data signifying the local swap information on destination chain
    function createDstChainSwapData(
        address dstChainSupportToken,
        address dstChainToken,
        uint256 dstChainReleaseAmt,
        address spender,
        address swapTarget,
        address payable dstReceiver,
        bytes memory swapData
    ) external pure returns (bytes memory) {
        return abi.encode(
            dstChainSupportToken,
            dstChainToken,
            dstChainReleaseAmt,
            spender,
            swapTarget,
            dstReceiver,
            swapData
        );
    }

    /// Encodes the stargate data which enables cross chain swap
    /// @dev Returns back the encoded value to facilitate cross chain swap
    /// @param dstChainId stargate's destination chain id where user wants to transfer the funds
    /// @param gasForSwap gas amount which will be used to facilitate stargate's cross chain stable token transfer
    /// @param srcPoolToken stargate's src pool id 
    /// @param dstPoolToken stargate's dest pool id
    function createStargateData(
        uint16 dstChainId,
        uint256 gasForSwap,
        address srcPoolToken,
        address dstPoolToken
    ) external view returns (bytes memory) {
        return abi.encode(
            dstChainId,
            dstSmartRouter[dstChainId],
            srcTokenToPoolId[srcPoolToken],
            dstTokenToPoolId[dstChainId][dstPoolToken],
            gasForSwap
        );
    }

    /// Gets the extra fees that will be collected from the user to enable cross chain swap
    /// @dev Returns back the fees that will be used to facilitate the cross chain swap
    /// @param dstChainId stargate's destination chain id where user wants to transfer the funds
    /// @param functionType /// ADD DETAILS ####
    /// @param to Address where swapped tokens will be transferred on the destination chain
    /// @param dstGasForCall Gas required to be sent for stargate cross chain swap
    /// @param dstPayload Payload indicating the details to swap the required token on the destination chain
    function getCrossChainGasEstimate(
        uint16 dstChainId,
        uint8 functionType,
        address to,
        uint256 dstGasForCall,
        bytes memory dstPayload
    ) external view returns (uint256 fee) {
        (fee,) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            dstChainId,
            functionType,
            abi.encodePacked(to),
            dstPayload,
            IStargateRouter.lzTxObj(dstGasForCall,0, "0x")
        );
        return fee;
    }

    /// decodes payload on the destination chain to decide what type of swapping needs to be done on the destination chain
    /// @dev Returns back the type of swap that will take place on the destination chain along with the payload to enable the swap
    /// @param payload payload received by smart router using 0x messaging protocol
    function decodePayloadForAction(
        bytes memory payload
    ) external pure returns (
        uint16 action, 
        uint256 key,
        bytes memory actionObject
    ) {
        (
            ,
            action,
            key,
            actionObject
        ) = abi.decode(payload,(address,uint16,uint256,bytes));
        return (action, key, actionObject);
    }

    /// decodes payload on the destination chain where destination token is stargate pool token, i.e no extra token swap is required
    /// @dev Returns back the decoded payload giving details about support token, release amount and the address where tokens need to be transferred
    /// @param actionObject encoded payload having dest chain swap details
    function decodeActionType1(
        bytes memory actionObject
    ) external pure returns (
        address supportToken,
        uint256 releaseAmt,
        address payable receiver
    ) {
        (
            supportToken,
            releaseAmt,
            receiver
        ) = abi.decode (actionObject,(address, uint256, address));
        return (supportToken, releaseAmt, receiver);
    }

    /// decodes payload on the destination chain where final destination token is neither stargate pool token nor a native token
    /// @dev Returns back the decoded payload giving details about support token released by stargar, final destination token, release amount, 0x Swap details and the address where tokens need to be transferred
    /// @param actionObject encoded payload having dest chain swap details
    function decodeActionType2(
        bytes memory actionObject
    ) external pure returns (
        address supportToken,
        address token,
        uint256 releaseAmt,
        address spender,
        address swapTarget,
        address payable receiver,
        bytes memory swapData
    ) {
        (
            token,
            supportToken,
            releaseAmt,
            spender,
            swapTarget,
            receiver,
            swapData
        ) = abi.decode(actionObject,(address, address, uint256, address, address, address, bytes));
        return (
            token,
            supportToken,
            releaseAmt,
            spender,
            swapTarget,
            receiver,
            swapData
        );
    }

    /// decodes payload on the destination chain where final destination token is a native token
    /// @dev Returns back the decoded payload giving details about support token released by stargar, release amount of native token, 0x Swap details and the address where tokens need to be transferred
    /// @param actionObject encoded payload having dest chain swap details
    function decodeActionType3 (
        bytes memory actionObject
    ) external pure returns (
        address supportToken,
        uint256 releaseAmt,
        address spender,
        address swapTarget,
        address receiver,
        bytes memory swapData
    ) {
        (
            supportToken,
            releaseAmt,
            spender,
            swapTarget,
            receiver,
            swapData
        ) = abi.decode(actionObject,(address, uint256, address, address, address, bytes));
        return (
            supportToken,
            releaseAmt,
            spender,
            swapTarget,
            receiver,
            swapData
        );
    }

    /// Gets the token amount router contract will receive after stargate cuts their protocol fees
    /// @dev Returns back the token amount router contract will receive after stargate cuts their protocol fees
    /// @param dstChainId stargate's destination chain id where user wants to transfer the funds
    /// @param dstSupportToken address of destination support token which stargate will release on the destination chain
    /// @param srcSupportToken address of src support token which router will send stargate to facilitate cross chain swap
    /// @param srcChainTokenAmt amount of stargate supported token that router will send stargate to facilitate cross chain swap
    function getDstAmountAfterFees (
        uint16 dstChainId,
        address dstSupportToken,
        address srcSupportToken,
        uint256 srcChainTokenAmt
    ) external view returns(uint256) {
        // Calls the Stargate fees library to get the fees stargate will charge to enable cross chain swap
        StargateFeeLibrary.SwapObj memory fees = StargateFeeLibrary(feeLibrary).getFees(
            srcTokenToPoolId[srcSupportToken],
            dstTokenToPoolId[dstChainId][dstSupportToken],
            dstChainId,
            address(this),
            srcChainTokenAmt
        );
        return srcChainTokenAmt - fees.eqFee - fees.protocolFee - fees.lpFee + fees.eqReward;
    }

    /// Sets the reveral ID for an address.
    /// @dev Sets the reveral ID for an address.
    /// @param _referralID Array of Referral address to add.
    /// @param _key Array of referral IDs for the referral address.
    function addReferral(address[] memory _referralID, uint256[] memory _key) public onlyOwner{
        uint256 length = _referralID.length;
        require(_referralID.length == _key.length, "SMRT: Length mismatch");
        for(uint256 i = 0; i< length; i++){
            refereeID[_referralID[i]] = _key[i];
            destRefereeID[_key[i]] = _referralID[i];
        }
    }

    /// Sets the referral fee and the base.
    /// @dev Sets the referral fee and the base.
    /// @param _fee Referral Fee to be set.
    /// @param _feeBase Referral fee base to be set.
    function updateReferralFee(uint256 _fee, uint256 _feeBase) public onlyOwner {
        referralFee = _fee;
        referralFeeBase = _feeBase;
    }

    /// Get the referral address.
    /// @dev Gets the referral address.
    /// @param __msgSender Address corresponding to which the referral address needs to be fetched.
    function getReferralInfo(address __msgSender) external view returns(address) {
        return referralInfo[__msgSender];
    }

    //// Get the referral ID.
    /// @dev Gets the referral ID.
    /// @param _address Address corresponding to which the referral ID needs to be fetched.
    function getReferralID(address _address) external view returns(uint256) {
        return refereeID[_address];
    }

    /// Get the referral address.
    /// @dev Gets the referral address.
    /// @param _key Key corresponding to which the referral address needs to be calculated.
    function getDestReferralID(uint256 _key) external view returns(address) {
        return destRefereeID[_key];
    }

    //// Set the referral ID.
    /// @dev Sets the referral ID.
    /// @param _address Address corresponding to which the referral ID needs to be set.
    /// @param _key value that needs to be set for an address.
    function setReferralInfo(address _address, address _key) external {
        require(msg.sender == smartSwap,"SMRT: Only SmartFinanceSwap");
        referralInfo[_address] = _key;
    }
}