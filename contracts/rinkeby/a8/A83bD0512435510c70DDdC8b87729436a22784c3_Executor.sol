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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
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
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
                version == 1 && !Address.isContract(address(this)),
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity 0.8.10;

contract BaseMath {

    /// @notice Constant for the fractional arithmetics. Similar to 1 ETH = 1e18 wei.
    uint256 constant internal DECIMAL_PRECISION = 1e18;

    /// @notice Constant for the fractional arithmetics with ACR.
    uint256 constant internal ACR_DECIMAL_PRECISION = 1e4;

}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

/// @title Central logger contract
/// @notice Log collector with only 1 purpose - to emit the event. Can be called from any contract
/** @dev Use like this:
*
* bytes32 internal constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");
* CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
*
* Or directly:
*   CentralLogger logger = CentralLogger(0xDEPLOYEDADDRESS);
*
* logger.log(
*            address(this),
*            msg.sender,
*            "myGreatFunction",
*            abi.encode(msg.value, param1, param2)
*        );
*
* DO NOT USE delegateCall as it defies the centralisation purpose of this logger.
*/
contract CentralLogger {

    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

	/* solhint-disable no-empty-blocks */
	constructor() {
	}

    /// @notice Log the event centrally
    /// @dev For gas impact see https://www.evm.codes/#a3
    /// @param _logName length must be less than 32 bytes
    function log(
        address _contract,
        address _caller,
        string memory _logName,
        bytes memory _data
    ) public {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Ownable.sol";

contract CommunityAcknowledgement is Ownable {

	/// @notice Recognised Community Contributor Acknowledgement Rate
	/// @dev Id is keccak256 hash of contributor address
	mapping (bytes32 => uint16) public rccar;

	/// @notice Emit when owner recognises contributor
	/// @param contributor Keccak256 hash of recognised contributor address
	/// @param previousAcknowledgementRate Previous contributor acknowledgement rate
	/// @param newAcknowledgementRate New contributor acknowledgement rate
	event ContributorRecognised(bytes32 indexed contributor, uint16 indexed previousAcknowledgementRate, uint16 indexed newAcknowledgementRate);

	/* solhint-disable-next-line no-empty-blocks */
	constructor(address _adoptionDAOAddress) Ownable(_adoptionDAOAddress) {

	}

	/// @notice Getter for Recognised Community Contributor Acknowledgement Rate
	/// @param _contributor Keccak256 hash of contributor address
	/// @return Acknowledgement Rate
	function getAcknowledgementRate(bytes32 _contributor) external view returns (uint16) {
		return rccar[_contributor];
	}

	/// @notice Getter for Recognised Community Contributor Acknowledgement Rate for msg.sender
	/// @return Acknowledgement Rate
	function senderAcknowledgementRate() external view returns (uint16) {
		return rccar[keccak256(abi.encodePacked(msg.sender))];
	}

	/// @notice Recognise community contributor and set its acknowledgement rate
	/// @dev Only owner can recognise contributor
	/// @dev Emits `ContributorRecognised` event
	/// @param _contributor Keccak256 hash of recognised contributor address
	/// @param _acknowledgementRate Contributor new acknowledgement rate
	function recogniseContributor(bytes32 _contributor, uint16 _acknowledgementRate) public onlyOwner {
		uint16 _previousAcknowledgementRate = rccar[_contributor];
		rccar[_contributor] = _acknowledgementRate;
		emit ContributorRecognised(_contributor, _previousAcknowledgementRate, _acknowledgementRate);
	}

	/// @notice Recognise list of contributors
	/// @dev Only owner can recognise contributors
	/// @dev Emits `ContributorRecognised` event for every contributor
	/// @param _contributors List of keccak256 hash of recognised contributor addresses
	/// @param _acknowledgementRates List of contributors new acknowledgement rates
	function batchRecogniseContributor(bytes32[] calldata _contributors, uint16[] calldata _acknowledgementRates) external onlyOwner {
		require(_contributors.length == _acknowledgementRates.length, "Lists do not match in length");

		for (uint256 i = 0; i < _contributors.length; i++) {
			recogniseContributor(_contributors[i], _acknowledgementRates[i]);
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./Ownable.sol";

/// @title APUS config contract
/// @notice Holds global variables for the rest of APUS ecosystem
contract Config is Ownable {

	/// @notice Adoption Contribution Rate, where 100% = 10000 = ACR_DECIMAL_PRECISION. 
	/// @dev Percent value where 0 -> 0%, 10 -> 0.1%, 100 -> 1%, 250 -> 2.5%, 550 -> 5.5%, 1000 -> 10%, 0xffff -> 655.35%
	/// @dev Example: x * adoptionContributionRate / ACR_DECIMAL_PRECISION
	uint16 public adoptionContributionRate;

	/// @notice Adoption DAO multisig address
	address payable public adoptionDAOAddress;

	/// @notice Emit when owner changes Adoption Contribution Rate
	/// @param caller Who changed the Adoption Contribution Rate (i.e. who was owner at that moment)
	/// @param previousACR Previous Adoption Contribution Rate
	/// @param newACR New Adoption Contribution Rate
	event ACRChanged(address indexed caller, uint16 previousACR, uint16 newACR);

	/// @notice Emit when owner changes Adoption DAO address
	/// @param caller Who changed the Adoption DAO address (i.e. who was owner at that moment)
	/// @param previousAdoptionDAOAddress Previous Adoption DAO address
	/// @param newAdoptionDAOAddress New Adoption DAO address
	event AdoptionDAOAddressChanged(address indexed caller, address previousAdoptionDAOAddress, address newAdoptionDAOAddress);

	/* solhint-disable-next-line func-visibility */
	constructor(address payable _adoptionDAOAddress, uint16 _initialACR) Ownable(_adoptionDAOAddress) {
		adoptionContributionRate = _initialACR;
		adoptionDAOAddress = _adoptionDAOAddress;
	}


	/// @notice Change Adoption Contribution Rate
	/// @dev Only owner can change Adoption Contribution Rate
	/// @dev Emits `ACRChanged` event
	/// @param _newACR Adoption Contribution Rate
	function setAdoptionContributionRate(uint16 _newACR) external onlyOwner {
		uint16 _previousACR = adoptionContributionRate;
		adoptionContributionRate = _newACR;
		emit ACRChanged(msg.sender, _previousACR, _newACR);
	}

	/// @notice Change Adoption DAO address
	/// @dev Only owner can change Adoption DAO address
	/// @dev Emits `AdoptionDAOAddressChanged` event
	function setAdoptionDAOAddress(address payable _newAdoptionDAOAddress) external onlyOwner {
		address payable _previousAdoptionDAOAddress = adoptionDAOAddress;
		adoptionDAOAddress = _newAdoptionDAOAddress;
		emit AdoptionDAOAddressChanged(msg.sender, _previousAdoptionDAOAddress, _newAdoptionDAOAddress);
	}

}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Config.sol";
import "./Registry.sol";
import "./Stargate.sol";
import "./CentralLogger.sol";
import "./CommunityAcknowledgement.sol";
import "./interfaces/IBorrowerOperations.sol";
import "./interfaces/ITroveManager.sol";
import "./interfaces/ICollSurplusPool.sol";
import "./interfaces/ILUSDToken.sol";
import "./interfaces/IPriceFeed.sol";
import "./LiquityMath.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @title APUS execution logic
/// @dev Should be called as delegatecall from APUS smart account proxy
contract Executor is LiquityMath, Initializable, Ownable {

	// ================================================================================
	// WARNING!!!!
	// Executor must not have or store any stored variables (constant and immutable variables are not stored).
	// It could conflict with proxy storage as it is called via delegatecall from proxy.
	// ================================================================================
	/* solhint-disable var-name-mixedcase */

	/// @notice Registry's contracts IDs
	bytes32 private constant CONFIG_ID = keccak256("Config");
	bytes32 private constant STARGATE_ID = keccak256("Stargate");
	bytes32 private constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");
	bytes32 private constant COMMUNITY_ACKNOWLEDGEMENT_ID = keccak256("CommunityAcknowledgement");

	/// @notice APUS registry address
	Registry public immutable registry;

	// L1 Liquity deployed contracts
	// see https://docs.liquity.org/documentation/resources#contract-addresses
	IBorrowerOperations public immutable BorrowerOperations;
	ITroveManager public immutable TroveManager;
	ICollSurplusPool public immutable CollSurplusPool;
    ILUSDToken public immutable LUSDToken;
	IPriceFeed public immutable PriceFeed;
	
	/* solhint-enable var-name-mixedcase */

	/// @dev enum for the logger events
	enum AdjustCreditLineLiquityChoices {
		DebtIncrease, DebtDecrease, CollateralIncrease, CollateralDecrease
	}

    /* --- Variable container structs  ---
    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */
	/* solhint-disable-next-line contract-name-camelcase */
	struct LocalVariables_adjustCreditLineLiquity {
		Config config;
		uint256 neededLUSDChange;
		uint256 expectedLiquityProtocolRate;
		uint256 previousLUSDBalance;
		uint256 previousETHBalance;	
		uint16 acr;
		uint256 price;
		bool isDebtIncrease;
		uint256 mintedLUSD;
		uint256 adoptionContributionLUSD;				
	}

	/* solhint-disable-next-line func-visibility */
	constructor(
		address _registry,
		address _borrowerOperations,
		address _troveManager,
		address _collSurplusPool,
		address _lusdToken,
		address _priceFeed
	) Ownable(address(0)) {
		registry = Registry(_registry);
		BorrowerOperations = IBorrowerOperations(_borrowerOperations);
		TroveManager = ITroveManager(_troveManager);
		CollSurplusPool = ICollSurplusPool(_collSurplusPool);
		LUSDToken = ILUSDToken(_lusdToken);
		PriceFeed = IPriceFeed(_priceFeed);
	}

	/// TODO: Doc
	function initialize(address _owner) external onlyInitializing {
		_transferOwnership(_owner);
	}

	// ------------------------------------------ Liquity functions ------------------------------------------

	/// @notice Sends LUSD amount from Smart Account to _LUSDTo account. Sends total balance if uint256.max is given as the amount.
	/* solhint-disable-next-line var-name-mixedcase */
	function sendLUSD(address _LUSDTo, uint256 _amount) internal {
		if (_amount == type(uint256).max) {
            _amount = getLUSDBalance(address(this));
        }
		// Do not transfer from Smart Account to itself, silently pass such case.
        if (_LUSDTo != address(this) && _amount != 0) {
			// LUSDToken.transfer reverts on recipient == adress(0) or == liquity contracts.
			// Overall either reverts or procedes returning true. Never returns false.
            LUSDToken.transfer(_LUSDTo, _amount);
		}
	}

	/// @notice Pulls LUSD amount from `_from` address to Smart Account. Pulls total balance if uint256.max is given as the amount.
	function pullLUSDFrom(address _from, uint256 _amount) internal {
		if (_amount == type(uint256).max) {
            _amount = getLUSDBalance(_from);
        }
		// Do not transfer from Smart Account to itself, silently pass such case.
		if (_from != address(this) && _amount != 0) {
			// function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
			// LUSDToken.transfer reverts on allowance issue, recipient == adress(0) or == liquity contracts.
			// Overall either reverts or procedes returning true. Never returns false.
			LUSDToken.transferFrom(_from, address(this), _amount);
		}
	}

	/// @notice Gets the LUSD balance of the account
	function getLUSDBalance(address _acc) internal view returns (uint256) {
		return LUSDToken.balanceOf(_acc);
	}

	/// @notice Get and apply Recognised Community Contributor Acknowledgement Rate to ACR for the Contributor
	/// @param _acr Adoption Contribution Rate in uint16
	/// @param _requestor Requestor for whom to apply Contributor Acknowledgement if is set
	function adjustAcrForRequestor(uint16 _acr, address _requestor) internal view returns (uint16) {
		// Get and apply Recognised Community Contributor Acknowledgement Rate
		CommunityAcknowledgement ca = CommunityAcknowledgement(registry.getAddress(COMMUNITY_ACKNOWLEDGEMENT_ID));

		uint16 rccar = ca.getAcknowledgementRate(keccak256(abi.encodePacked(_requestor)));

		return applyRccarOnAcr(rccar, _acr);
	}


	/// @notice Open a new credit line using Liquity protocol by depositing ETH collateral and borrowing LUSD.
	/// @dev Value is amount of ETH to deposit into Liquity Trove
	/// @param _LUSDRequestedDebt Amount of LUSD caller wants to borrow and withdraw.
	/// @param _LUSDTo Address that will receive the generated LUSD.
	/// @param _upperHint For gas optimalisation. Referring to the prevId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _lowerHint For gas optimalisation. Referring to the nextId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDAmount instead of _LUSDRequestedDebt
	/* solhint-disable-next-line var-name-mixedcase */
	function openCreditLineLiquity(uint256 _LUSDRequestedDebt, address _LUSDTo, address _upperHint, address _lowerHint, address _caller) external payable onlyOwner {

		// Assertions and relevant reverts are done within Liquity protocol
		// Re-entrancy is avoided by calling the openTrove (cannot open the additional trove for the same smart account)
		
		Config config = Config(registry.getAddress(CONFIG_ID));

		uint256 mintedLUSD;
		uint256 neededLUSDAmount;
		uint256 expectedLiquityProtocolRate;

		{ // scope to avoid stack too deep errors
			uint16 acr = adjustAcrForRequestor(config.adoptionContributionRate(), _caller);

			// Find effectively that Liquity is in Recovery mode => 0 rate
			// TroveManager.checkRecoveryMode() requires priceFeed.fetchPrice(), 
			// which is expensive to run and will be run again when openTrove is called.
			// We use much cheaper view PriceFeed.lastGoodPrice instead, which might be outdated by 1 call
			// Consequence in such situation is that the Adoption Contribution is decreased by otherwise non applicable protocol fee.
			// There is no negative impact on the user.
			uint256 price = PriceFeed.lastGoodPrice();
			expectedLiquityProtocolRate = (TroveManager.checkRecoveryMode(price)) ? 0 : TroveManager.getBorrowingRateWithDecay();

			neededLUSDAmount = calcNeededLiquityLUSDAmount(_LUSDRequestedDebt, expectedLiquityProtocolRate, acr);

			uint256 previousLUSDBalance = getLUSDBalance(address(this));

			BorrowerOperations.openTrove{value: msg.value}(
				LIQUITY_PROTOCOL_MAX_BORROWING_FEE,
				neededLUSDAmount,
				_upperHint,
				_lowerHint
			);

			mintedLUSD = getLUSDBalance(address(this)) - previousLUSDBalance;
		}

		// Can send only what was minted
		// assert (_LUSDRequestedDebt <= mintedLUSD); // asserts in adoptionContributionLUSD calculation by avoiding underflow
		uint256 adoptionContributionLUSD = mintedLUSD - _LUSDRequestedDebt;

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "openCreditLineLiquity",
			abi.encode(_LUSDRequestedDebt, _LUSDTo, _upperHint, _lowerHint, neededLUSDAmount, mintedLUSD, expectedLiquityProtocolRate)
		);

		// Send LUSD to the Adoption DAO
		sendLUSD(config.adoptionDAOAddress(), adoptionContributionLUSD);

		// Send LUSD to the requested address
		// Must be located at the end to avoid withdrawal by re-entrancy into potential LUSD withdrawal function
		sendLUSD(_LUSDTo, _LUSDRequestedDebt);
	}


	/// @notice Closes the Liquity trove
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _caller msg.sender in the Stargate
	/// @dev Closing Liquity Credit Line pulls required LUSD and therefore requires approval on LUSD spending
	/* solhint-disable-next-line var-name-mixedcase */
	function closeCreditLineLiquity(address _LUSDFrom, address payable _collateralTo, address _caller) public onlyOwner {

		uint256 collateral = TroveManager.getTroveColl(address(this));

		// getTroveDebt returns composite debt including 200 LUSD gas compensation
		// Liquity Trove cannot have less than 2000 LUSD total composite debt
		// @dev Substraction is safe since solidity 0.8 reverts on underflow
		uint256 debtToRepay = TroveManager.getTroveDebt(address(this)) - LIQUITY_LUSD_GAS_COMPENSATION;

		// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
		// Pull LUSD from _from (typically EOA) to Smart Account proxy
		pullLUSDFrom(_LUSDFrom, debtToRepay);

		// Closing trove results in ETH to be stored on Smart Account proxy
		BorrowerOperations.closeTrove(); 

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "closeCreditLineLiquity",
			abi.encode(_LUSDFrom, _collateralTo, debtToRepay, collateral)
		);

		// Must be last to avoid re-entrancy attack
		// In fact BorrowerOperations.closeTrove() fails on re-entrancy since Trove would be closed in re-entrancy
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: collateral }("");
		require(success, "Sending collateral ETH failed");

	}

	/// @notice Closes the Liquity trove using EIP2612 Permit.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _caller msg.sender in the Stargate
	/// @dev Closing Liquity Credit Line pulls required LUSD and therefore requires approval on LUSD spending
	/* solhint-disable-next-line var-name-mixedcase */
	function closeCreditLineLiquityWithPermit(address _LUSDFrom, address payable _collateralTo, uint8 v, bytes32 r, bytes32 s, address _caller) external onlyOwner {
		// getTroveDebt returns composite debt including 200 LUSD gas compensation
		// Liquity Trove cannot have less than 2000 LUSD total composite debt
		// @dev Substraction is safe since solidity 0.8 reverts on underflow
		uint256 debtToRepay = TroveManager.getTroveDebt(address(this)) - LIQUITY_LUSD_GAS_COMPENSATION;

		LUSDToken.permit(_LUSDFrom, address(this), debtToRepay, type(uint256).max, v, r, s);

		closeCreditLineLiquity(_LUSDFrom, _collateralTo, _caller);
	}

	/// @notice Enables a borrower to simultaneously change both their collateral and debt.
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed.
	///			The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution and protocol's fees are applied in the form of additional debt in case of requested debt increase.
	/// @param _LUSDAddress Address where the LUSD is being pulled from in case of to repaying debt.
	/// Or address that will receive the generated LUSD in case of increasing debt.
	/// Approval of LUSD transfers for given Smart Account is required in case of repaying debt.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation. Referring to the prevId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _lowerHint For gas optimalisation. Referring to the nextId of the two adjacent nodes in the linked list that are (or would become) the neighbors of the given Liquity Trove.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDChange instead of _LUSDRequestedChange
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	/* solhint-disable var-name-mixedcase */
	function adjustCreditLineLiquity(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		address _LUSDAddress,
		uint256 _collWithdrawal,
		address _collateralTo,
		address _upperHint, address _lowerHint, address _caller
		/* solhint-enable var-name-mixedcase */
	) public payable onlyOwner {

		// Assertions and relevant reverts are done within Liquity protocol

		LocalVariables_adjustCreditLineLiquity memory vars;
		
		vars.config = Config(registry.getAddress(CONFIG_ID));

		// Make sure there is a requested increase in debt
		vars.isDebtIncrease = _isDebtIncrease && (_LUSDRequestedChange > 0);

		// Handle pre trove action regarding debt.
		if (vars.isDebtIncrease) {
			{
			vars.acr = adjustAcrForRequestor(vars.config.adoptionContributionRate(), _caller);

			// Find effectively that Liquity is in Recovery mode => 0 rate
			// TroveManager.checkRecoveryMode() requires priceFeed.fetchPrice(), 
			// which is expensive to run and will be run again when adjustTrove is called.
			// We use much cheaper view PriceFeed.lastGoodPrice instead, which might be outdated by 1 call
			// Consequence in such situation is that the Adoption Contribution is decreased by otherwise non applicable protocol fee.
			// There is no negative impact on the user.
			vars.price = PriceFeed.lastGoodPrice();
			vars.expectedLiquityProtocolRate = (TroveManager.checkRecoveryMode(vars.price)) ? 0 : TroveManager.getBorrowingRateWithDecay();

			vars.neededLUSDChange = calcNeededLiquityLUSDAmount(_LUSDRequestedChange, vars.expectedLiquityProtocolRate, vars.acr);
			}
		} else {
			// Debt decrease (= repayment) or no change in debt
			vars.neededLUSDChange = _LUSDRequestedChange;

			if (vars.neededLUSDChange > 0) {
				// Debt decrease
				// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
				// Pull LUSD from _LUSDAddress (typically EOA) to Smart Account proxy
				// Pull is re-entrancy safe as we call non upgradable LUSDToken
				pullLUSDFrom(_LUSDAddress, vars.neededLUSDChange);
			}
		}

		vars.previousLUSDBalance = getLUSDBalance(address(this));
		vars.previousETHBalance = address(this).balance;

		// Check on singular-collateral-change is done within Liquity
		// Receiving ETH in case of collateral increase is implemented by passing the value. 
		BorrowerOperations.adjustTrove{value: msg.value}(
				LIQUITY_PROTOCOL_MAX_BORROWING_FEE,
				_collWithdrawal,
				vars.neededLUSDChange,
				vars.isDebtIncrease,
				_upperHint,
				_lowerHint
			);

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));

		// Handle post trove-change regarding debt.
		// Only debt increase requires actions, as debt decrease was handled by pre trove operation.
		if (vars.isDebtIncrease) {
			vars.mintedLUSD = getLUSDBalance(address(this)) - vars.previousLUSDBalance;
			// Can send only what was minted
			// assert (_LUSDRequestedChange <= mintedLUSD); // asserts in adoptionContributionLUSD calculation by avoiding underflow
			vars.adoptionContributionLUSD = vars.mintedLUSD - _LUSDRequestedChange;

			// Send LUSD to the Adoption DAO
			sendLUSD(vars.config.adoptionDAOAddress(), vars.adoptionContributionLUSD);

			// Send LUSD to the requested address
			sendLUSD(_LUSDAddress, _LUSDRequestedChange);


			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(
					AdjustCreditLineLiquityChoices.DebtIncrease, 
					vars.mintedLUSD, 
					_LUSDRequestedChange,
					_LUSDAddress
					)
			);

		} else if (vars.neededLUSDChange > 0) {
			// Log debt decrease
			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(AdjustCreditLineLiquityChoices.DebtDecrease, _LUSDRequestedChange, _LUSDAddress)
			);
		}

		// Handle post trove-change regarding collateral.
		// Only collateral decrease (withdrawal) requires actions, 
		// as collateral increase was handled by passing value to the trove operation (= getting ETH from sender into the trove).
		if (msg.value > 0) {
			// Log collateral increase
			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(AdjustCreditLineLiquityChoices.CollateralIncrease, msg.value, _caller)
			);

		} else if (_collWithdrawal > 0) {
			// Collateral decrease

			// Make sure we send what was provided by the Trove
			uint256 collateralChange = address(this).balance - vars.previousETHBalance;

			logger.log(
				address(this), _caller, "adjustCreditLineLiquity",
				abi.encode(AdjustCreditLineLiquityChoices.CollateralDecrease, collateralChange, _collWithdrawal, _collateralTo)
			);

			// Must be last to avoid re-entrancy attack
			// solhint-disable-next-line avoid-low-level-calls
			(bool success, ) = _collateralTo.call{ value: collateralChange }("");
			require(success, "Sending collateral ETH failed");
		}
	}

	/// @notice Enables a borrower to simultaneously change both their collateral and decrease debt providing LUSD from ANY ADDRESS using EIP2612 Permit. 
	/// Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// It is useful only when the debt decrease is requested while working with collateral.
	/// In all other cases [adjustCreditLineLiquity()] MUST be used. It is cheaper on gas.
	/// @param _LUSDRequestedChange Amount of LUSD to be returned.
	/// @param _LUSDFrom Address where the LUSD is being pulled from. Can be ANY ADDRESS with enough LUSD.
	/// Approval of LUSD transfers for given Smart Account is ensured by the offchain signature from that address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	/* solhint-disable var-name-mixedcase */
	function adjustCreditLineLiquityWithPermit(
		uint256 _LUSDRequestedChange,
		address _LUSDFrom,
		uint256 _collWithdrawal,
		address _collateralTo,
		address _upperHint, address _lowerHint,
		uint8 v, bytes32 r, bytes32 s,
		address _caller
		/* solhint-enable var-name-mixedcase */
	) external payable onlyOwner {
		LUSDToken.permit(_LUSDFrom, address(this), _LUSDRequestedChange, type(uint256).max, v, r, s);

		adjustCreditLineLiquity(false, _LUSDRequestedChange, _LUSDFrom, _collWithdrawal, _collateralTo, _upperHint, _lowerHint, _caller);
	}

	/// @notice Claims remaining collateral from the user's closed Liquity Trove due to a redemption or a liquidation with ICR > MCR in Recovery Mode
	/// @param _collateralTo Address that will receive the claimed collateral ETH.
	/// @param _caller msg.sender in the Stargate
	function claimRemainingCollateralLiquity(address payable _collateralTo, address _caller) external onlyOwner {
		
		uint256 remainingCollateral = CollSurplusPool.getCollateral(address(this));

		// Reverts if there is no collateral to claim 
		BorrowerOperations.claimCollateral();

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "claimRemainingCollateralLiquity",
			abi.encode(_collateralTo, remainingCollateral)
		);

		// Send claimed ETH
		// Must be last to avoid re-entrancy attack
		// In fact BorrowerOperations.claimCollateral() reverts on re-entrancy since there will be no residual collateral to claim
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: remainingCollateral }("");
		/* solhint-disable-next-line reason-string */
		require(success, "Sending of claimed collateral failed.");
	}

	/// @notice Allows ANY ADDRESS (calling and paying) to add ETH collateral to borrower's Credit Line (Liquity protocol) and thus increase CR (decrease LTV ratio).
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// 	DANGEROUS operation, which can be initiated by non-owner of Smart Account (via Smart Account, though)
	///		Having the impact on the Smart Account storage. Therefore no 3rd party contract besides Liquity is called.
	function addCollateralLiquity(address _upperHint, address _lowerHint, address _caller) external payable onlyOwner {

		BorrowerOperations.addColl{value: msg.value}(_upperHint, _lowerHint);

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "addCollateralLiquity",
			abi.encode(msg.value, _caller)
		);
	}


	/// @notice Withdraws amount of ETH collateral from the Credit Line and transfer to _collateralTo address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function withdrawCollateralLiquity(uint256 _collWithdrawal, address payable _collateralTo, address _upperHint, address _lowerHint, address _caller) external onlyOwner {

		// Withdrawing results in ETH to be stored on Smart Account proxy
		BorrowerOperations.withdrawColl(_collWithdrawal, _upperHint, _lowerHint);

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "withdrawCollateralLiquity",
			abi.encode(_collWithdrawal, _collateralTo)
		);

		// Must be last to mitigate re-entrancy attack
		// Re-entrancy only enables caller to withdraw and transfer more ETH if allowed by the trove.
		// Having just negative impact on the caller (by spending more gas).
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = _collateralTo.call{ value: _collWithdrawal }("");
		require(success, "Sending collateral ETH failed");

	}

	/// @notice Enables credit line owner to partially repay the debt from ANY ADDRESS by the given amount of LUSD.
	/// Approval of LUSD transfers for given Smart Account is required.
	/// Cannot repay below 2000 LUSD composite debt. Use closeCreditLineLiquity to repay whole debt instead.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid. Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/* solhint-disable-next-line var-name-mixedcase */	
	function repayLUSDLiquity(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, address _caller) public onlyOwner {
		// Debt decrease
		// Liquity requires to have LUSD on the msg.sender, i.e. on Smart Account proxy
		// Pull LUSD from _LUSDFrom (typically EOA) to Smart Account proxy
		// Pull is re-entrancy safe as we call non upgradable LUSDToken contract
		pullLUSDFrom(_LUSDFrom, _LUSDRequestedChange);

		BorrowerOperations.repayLUSD(_LUSDRequestedChange, _upperHint, _lowerHint);

		CentralLogger logger = CentralLogger(registry.getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), _caller, "repayLUSDLiquity",
			abi.encode(_LUSDRequestedChange, _LUSDFrom)
		);

	}

	/// @notice Enables credit line owner to partially repay the debt from ANY ADDRESS by the given amount of LUSD using EIP 2612 Permit.
	/// Approval of LUSD transfers for given Smart Account is ensured by the offchain signature from that address.
	/// Cannot repay below 2000 LUSD composite debt. Use closeCreditLineLiquity to repay whole debt instead.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid. Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _caller msg.sender in the Stargate
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/* solhint-disable-next-line var-name-mixedcase */	
	function repayLUSDLiquityWithPermit(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, uint8 v, bytes32 r, bytes32 s, address _caller) external onlyOwner {
		LUSDToken.permit(_LUSDFrom, address(this), _LUSDRequestedChange, type(uint256).max, v, r, s);

		repayLUSDLiquity(_LUSDRequestedChange, _LUSDFrom, _upperHint, _lowerHint, _caller);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ExecutorProxy is BeaconProxy, Initializable {

	constructor(address _beacon) BeaconProxy(_beacon, "") {

	}


	function initialize(address _owner, address _beacon) external initializer {
		_setBeacon(_beacon, abi.encodeWithSignature("initialize(address)", _owner));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BaseMath.sol";

/// @title Business calculation logic related to the Liquity protocol
/// @dev To be inherited only
contract LiquityMath is BaseMath {

    // Maximum protocol fee as defined in the Liquity contracts
    // https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L48
    uint256 internal constant LIQUITY_PROTOCOL_MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // Amount of LUSD to be locked in Liquity's gas pool on opening troves
    // https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L334
    uint256 internal constant LIQUITY_LUSD_GAS_COMPENSATION = 200e18;

	/// @notice Calculates the needed amount of LUSD parameter for Liquity protocol when borrowing LUSD
    /// @param _LUSDRequestedAmount Amount the user wants to withdraw
    /// @param _expectedLiquityProtocolRate Current / expected borrowing rate of the Liquity protocol
    /// @param _adoptionContributionRate Adoption Contribution Rate in uint16 form (xxyy defines xx.yy %). LPR is applied when ACR < LPR. Thus LPR is always used When AR is set to 0.
    /* solhint-disable-next-line var-name-mixedcase */
    function calcNeededLiquityLUSDAmount(uint256 _LUSDRequestedAmount, uint256 _expectedLiquityProtocolRate, uint16 _adoptionContributionRate) internal pure returns (
        uint256 neededLiquityLUSDAmount
    ) {

        // Normalise ACR 1e4 -> 1e18
        uint256 acr = DECIMAL_PRECISION / ACR_DECIMAL_PRECISION * _adoptionContributionRate;

        // Apply Liquity protocol rate when ACR is lower
        acr = acr < _expectedLiquityProtocolRate ? _expectedLiquityProtocolRate : acr;

        // Includes requested debt and adoption contribution which covers also liquity protocol fee
        uint256 expectedDebtToRepay = _LUSDRequestedAmount * acr / DECIMAL_PRECISION + _LUSDRequestedAmount;

        // = x / ( 1 + fee rate<0.005 - 0.05> )
        neededLiquityLUSDAmount = DECIMAL_PRECISION * expectedDebtToRepay / ( DECIMAL_PRECISION + _expectedLiquityProtocolRate ); 

        require(neededLiquityLUSDAmount >= _LUSDRequestedAmount, "Cannot mint less than requested.");
    }

    /// @notice Calculates adjusted Adoption Contribution Rate decreased by RCCAR down to min 0.
    /// @param _rccar Recognised Community Contributor Acknowledgement Rate in uint16 form (xxyy defines xx.yy % points).
    /// @param _adoptionContributionRate Adoption Contribution Rate in uint16 form (xxyy defines xx.yy %).
    function applyRccarOnAcr(uint16 _rccar, uint16 _adoptionContributionRate) internal pure returns (
        uint16 adjustedAcr
    ) {
        return (_adoptionContributionRate > _rccar ? _adoptionContributionRate - _rccar : 0);
    }
}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
// Using less gas and initiating the first owner to the provided multisig address

pragma solidity ^0.8.10;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one provided during the deployment of the contract. 
 * This can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {

    /**
     * @dev Address of the current owner. 
     */
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @param _firstOwner Initial owner
     * @dev Initializes the contract setting the initial owner.
     */
    constructor(address _firstOwner) {
        _transferOwnership(_firstOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: cannot be zero address");
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address _newOwner) internal virtual {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

/// @title Registry contract for whole Apus ecosystem
/// @notice Holds addresses of all essential Apus contracts
contract Registry is Ownable, IBeacon {

	/// @notice Stores address under its id
	/// @dev Id is keccak256 hash of its string representation
	mapping (bytes32 => address) public addresses;

	/// @notice Emit when owner registers address
	/// @param id Keccak256 hash of its string id representation
	/// @param previousAddress Previous address value under given id
	/// @param newAddress New address under given id
	event AddressRegistered(bytes32 indexed id, address indexed previousAddress, address indexed newAddress);

	/* solhint-disable-next-line no-empty-blocks */
	constructor(address _initialOwner) Ownable(_initialOwner) {

	}


	/// @notice Getter for registered addresses
	/// @dev Returns zero address if address have not been registered before
	/// @param _id Registered address identifier
	function getAddress(bytes32 _id) external view returns(address) {
		return addresses[_id];
	}


	/// @notice Register address under given id
	/// @dev Only owner can register addresses
	/// @dev Emits `AddressRegistered` event
	/// @param _id Keccak256 hash of its string id representation
	/// @param _address Registering address
	function registerAddress(bytes32 _id, address _address) public onlyOwner {
		require(_address != address(0), "Can't register 0x0 address");
		address _previousAddress = addresses[_id];
		addresses[_id] = _address;
		emit AddressRegistered(_id, _previousAddress, _address);
	}

	/// @notice Register list of addresses under given list of ids
	/// @dev Only owner can register addresses
	/// @dev Emits `AddressRegistered` event for every address
	/// @param _ids List of keccak256 hashes of its string id representation
	/// @param _addresses List of registering addresses
	function batchRegisterAddresses(bytes32[] calldata _ids, address[] calldata _addresses) external onlyOwner {
		require(_ids.length == _addresses.length, "Lists do not match in length");

		for (uint256 i = 0; i < _ids.length; i++) {
			registerAddress(_ids[i], _addresses[i]);
		}
	}

	/// TODO: Doc
	function implementation() external view returns (address) {
		return addresses[keccak256("Executor")];
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract SqrtMath {

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    // source: https://github.com/paulrberg/prb-math/blob/86c068e21f9ba229025a77b951bd3c4c4cf103da/contracts/PRBMath.sol#L591
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Registry.sol";
import "./Executor.sol";
import "./ExecutorProxy.sol";
import "./Config.sol";
import "./CentralLogger.sol";
import "./CommunityAcknowledgement.sol";
import "./LiquityMath.sol";
import "./SqrtMath.sol";
import "./interfaces/ITroveManager.sol";
import "./interfaces/IHintHelpers.sol";
import "./interfaces/ISortedTroves.sol";
import "./interfaces/ICollSurplusPool.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";


/// @title Stargate contract serves as a gateway and a gatekeeper into the APUS protocol ecosystem
/// @notice The main motivation of Stargate is to give user understandable transaction to sign (i.e. no bytecode giberish) 
/// and to chain common sequence of transactions thus saving gas.
/// @dev It encodes all arguments and calls given user's Smart Account proxy with any additional arguments
contract Stargate is LiquityMath, SqrtMath {
	using Clones for address;

	/* solhint-disable var-name-mixedcase */

	/// @notice Registry's contracts IDs
	bytes32 private constant EXECUTOR_PROXY_ID = keccak256("ExecutorProxy");
	bytes32 private constant CONFIG_ID = keccak256("Config");
	bytes32 private constant COMMUNITY_ACKNOWLEDGEMENT_ID = keccak256("CommunityAcknowledgement");
	bytes32 private constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");

	/// @notice APUS registry address
	address public immutable registry;

	// L1 Liquity deployed contracts addresses
	// see https://docs.liquity.org/documentation/resources#contract-addresses
	ITroveManager public immutable TroveManager;
	IHintHelpers public immutable HintHelpers;
	ISortedTroves public immutable SortedTroves;
	ICollSurplusPool public immutable CollSurplusPool;

	/// @notice Event raised on Stargate when a new Smart Account is created. 
	/// Corresponding event is also raised on the Central Logger
	event SmartAccountCreated(
		address indexed owner,
		address indexed smartAccountAddress
	);


	/// @notice Modifier will fail if message sender is not the proxy owner
	/// @param _proxy Proxy address that must be owned
	modifier onlyProxyOwner(address payable _proxy) {
		require(Executor(_proxy).owner() == msg.sender, "Sender has to be proxy owner");
		_;
	}

	/* solhint-disable-next-line func-visibility */
	constructor(
		address _registry,
		address _troveManager,
		address _hintHelpers,
		address _sortedTroves,
		address _collSurplusPool
	) {
		registry = _registry;
		TroveManager = ITroveManager(_troveManager);
		HintHelpers = IHintHelpers(_hintHelpers);
		SortedTroves = ISortedTroves(_sortedTroves);
		CollSurplusPool = ICollSurplusPool(_collSurplusPool);
	}

	// Stargate MUST NOT be able to receive ETH from sender to itself
	// in 0.8.x function() is split to receive() and fallback(); if both are undefined -> tx reverts

	// ------------------------------------------ User functions ------------------------------------------


	/// @notice Creates the Smart Account directly. Its new address is emitted to the event.
	/// It is cheaper to open Smart Account while opening Credit Line wihin 1 transaction.
	function openSmartAccount() external {
		_openSmartAccount();
	}

	/// @notice Builds the new MakerDAO's proxy aka Smart Account with enabled calls from this Stargate
	function _openSmartAccount() internal returns (address payable) {
		// Deploy a new proxy onto blockchain
		address smartAccount = Registry(registry).getAddress(EXECUTOR_PROXY_ID).clone();

		// Set owner of a new proxy aka Smart Account to be the user
		// Set registry as executor proxy beacon
		ExecutorProxy(payable(smartAccount)).initialize(msg.sender, registry);

		// Emit centraly at this contract and the Central Logger
		emit SmartAccountCreated(msg.sender, smartAccount);
		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), msg.sender, "openSmartAccount", abi.encode(smartAccount)
		);
				
		return payable(smartAccount);
	}

	/// @notice Get the gasless information on Credit Line (Liquity) status of the given Smart Account
	/// @param _smartAccount Smart Account address.
	/// @return status Status of the Credit Line within Liquity protocol, where:
	/// 0..nonExistent,
	/// 1..active,
	/// 2..closedByOwner,
	/// 3..closedByLiquidation,
	/// 4..closedByRedemption
	/// @return collateral ETH collateral.
	/// @return debtToRepay Total amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return debtComposite Composite debt including the liquidation reserve. Valid for LTV (CR) calculations.   
	function getCreditLineStatusLiquity(address payable _smartAccount) external view returns (
		uint8 status,
		uint256 collateral,
		uint256 debtToRepay, 
		uint256 debtComposite
	) {
		(debtComposite, collateral, , status, ) = TroveManager.Troves(_smartAccount);	
		debtToRepay = debtComposite > LIQUITY_LUSD_GAS_COMPENSATION ? debtComposite - LIQUITY_LUSD_GAS_COMPENSATION : 0;
	}

	/// @notice Calculates Liquity sorting hints based on the provided NICR
	function getLiquityHints(uint256 NICR) internal view returns (
		address upperHint,
		address lowerHint
	) {
		// Get an approximate address hint from the deployed HintHelper contract.
		uint256 numTroves = SortedTroves.getSize();
		uint256 numTrials = sqrt(numTroves) * 15;
		(address approxHint, , ) = HintHelpers.getApproxHint(NICR, numTrials, 0x41505553);

		// Use the approximate hint to get the exact upper and lower hints from the deployed SortedTroves contract
		(upperHint, lowerHint) = SortedTroves.findInsertPosition(NICR, approxHint, approxHint);
	}

	/// @notice Calculates LUSD expected debt to repay. 
	/// Includes _LUSDRequested, Adoption Contribution, Liquity protocol fee.
	/// Adoption Contribution reflects the Adoption Contribution Rate and Recognised Community Contributor Acknowledgement Rate if applicable.
	function getLiquityExpectedDebtToRepay(uint256 _LUSDRequested) internal view returns (uint256 expectedDebtToRepay) {
		uint16 applicableAcr;
		uint256 expectedLiquityProtocolRate;

		(applicableAcr, expectedLiquityProtocolRate) = getLiquityRates();

		uint256 neededLUSDAmount = calcNeededLiquityLUSDAmount(_LUSDRequested, expectedLiquityProtocolRate, applicableAcr);

		uint256 expectedLiquityProtocolFee = TroveManager.getBorrowingFeeWithDecay(neededLUSDAmount);

		expectedDebtToRepay = neededLUSDAmount + expectedLiquityProtocolFee;
	}

	/// @notice Calculates the rates related to Liquity for the msg.sender
	/// @return applicableAcr Adoption Contribution Rate with applied Recognised Community Contributor Acknowledgement Rate of msg.sender if applicable.
	/// @return expectedLiquityProtocolRate Current rate of the Liquity protocol
	function getLiquityRates() internal view returns (uint16 applicableAcr, uint256 expectedLiquityProtocolRate) {
		// Get and apply Recognised Community Contributor Acknowledgement Rate
		CommunityAcknowledgement ca = CommunityAcknowledgement(Registry(registry).getAddress(COMMUNITY_ACKNOWLEDGEMENT_ID));
		uint16 rccar = ca.getAcknowledgementRate(keccak256(abi.encodePacked(msg.sender)));

		Config config = Config(Registry(registry).getAddress(CONFIG_ID));

		applicableAcr = applyRccarOnAcr(rccar, config.adoptionContributionRate());

		expectedLiquityProtocolRate = TroveManager.getBorrowingRateWithDecay();
	}

	/// @notice Calculates the current rate for the msg.sender as related to Liquity and Adoption Contribution incl. RCCAR
	function userAdoptionRate() external view returns (uint256) {
		uint16 applicableAcr;
		uint256 expectedLiquityProtocolRate;

		(applicableAcr, expectedLiquityProtocolRate) = getLiquityRates();

		// Normalise applicable ACR 1e4 -> 1e18
        uint256 r = DECIMAL_PRECISION / ACR_DECIMAL_PRECISION * applicableAcr;

        // Apply Liquity protocol rate when applicable ACR is lower
        return r < expectedLiquityProtocolRate ? expectedLiquityProtocolRate : r;
	}

	/// @notice Makes a gasless calculation to get the data for the Credit Line's initial setup on Liquity protocol
    /// @param _LUSDRequested Requested LUSD amount to be taken by borrower. In e18 (1 LUSD = 1e18).
	///	  		Adoption Contribution including protocol's fees is applied in the form of additional debt.
    /// @param _collateralAmount Amount of ETH to be deposited into the Credit Line. In wei (1 ETH = 1e18).
	/// @return expectedDebtToRepay Total amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return liquidationReserve Liquidation gas reserve required by the Liquity protocol.
	/// @return expectedCompositeDebtLiquity Total debt of the new Credit Line including the liquidation reserve. Valid for LTV (CR) calculations.
	/// @return NICR Nominal Individual Collateral Ratio for this calculation as defined and used by Liquity protocol.
	/// @return upperHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @return lowerHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
    function calculateInitialLiquityParameters(uint256 _LUSDRequested, uint256 _collateralAmount) public view returns (
		uint256 expectedDebtToRepay,
		uint256 liquidationReserve,
		uint256 expectedCompositeDebtLiquity,
        uint256 NICR,
		address upperHint,
		address lowerHint
    ) {
		liquidationReserve = LIQUITY_LUSD_GAS_COMPENSATION;

		expectedDebtToRepay = getLiquityExpectedDebtToRepay(_LUSDRequested);

		expectedCompositeDebtLiquity = expectedDebtToRepay + LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the nominal NICR of the new Liquity's trove
		NICR = _collateralAmount * 1e20 / expectedCompositeDebtLiquity;

		(upperHint, lowerHint) = getLiquityHints(NICR);
    }

	/// @notice Makes a gasless calculation to get the data for the Credit Line's adjustement on Liquity protocol
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed. The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution including protocol's fees is applied in the form of additional debt in case of requested debt increase.
	/// @param _isCollateralIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _collateralChange Amount of ETH collateral to be withdrawn or added. The increase or decrease is indicated by _isCollateralIncrease.
	/// @return newCollateral Calculated future collateral.
	/// @return expectedDebtToRepay Total future amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return liquidationReserve Liquidation gas reserve required by the Liquity protocol.
	/// @return expectedCompositeDebtLiquity Total future debt of the new Credit Line including the liquidation reserve. Valid for LTV (CR) calculations.
	/// @return NICR Nominal Individual Collateral Ratio for this calculation as defined and used by Liquity protocol.
	/// @return upperHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @return lowerHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @dev bools and uints are used to avoid typecasting and overflow issues and to explicitely signal the direction
	function calculateChangedLiquityParameters(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		bool _isCollateralIncrease,
		uint256 _collateralChange,
		address payable _smartAccount
	)  public view returns (
		uint256 newCollateral,
		uint256 expectedDebtToRepay,
		uint256 liquidationReserve,
		uint256 expectedCompositeDebtLiquity,
        uint256 NICR,
		address upperHint,
		address lowerHint
    ) {
		liquidationReserve = LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the current LUSD debt and ETH collateral
		(uint256 currentCompositeDebt, uint256 currentCollateral, , ) = TroveManager.getEntireDebtAndColl(_smartAccount);

		uint256 currentDebtToRepay = currentCompositeDebt - LIQUITY_LUSD_GAS_COMPENSATION;

		if (_isCollateralIncrease) {
			newCollateral = currentCollateral + _collateralChange;
		} else {
			newCollateral = currentCollateral - _collateralChange;
		}

		if (_isDebtIncrease) {
			uint256 additionalDebtToRepay = getLiquityExpectedDebtToRepay(_LUSDRequestedChange);
			expectedDebtToRepay = currentDebtToRepay + additionalDebtToRepay;
		} else {
			expectedDebtToRepay = currentDebtToRepay - _LUSDRequestedChange;
		}

		expectedCompositeDebtLiquity = expectedDebtToRepay + LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the nominal NICR of the new Liquity's trove
		NICR = newCollateral * 1e20 / expectedCompositeDebtLiquity;

		(upperHint, lowerHint) = getLiquityHints(NICR);

	}

	/// @notice Gasless check if there is anything to be claimed after the forced closure of the Liquity Credit Line
	function checkClaimableCollateralLiquity(address _smartAccount) external view returns (uint256) {
		return CollSurplusPool.getCollateral(_smartAccount);
	}

}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

// Common interface for the Liquity Trove management.
interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function openTrove(uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;


interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event EtherSent(address _to, uint _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getETH() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

interface IHintHelpers {

    function getRedemptionHints(
        uint _LUSDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedLUSDamount
        );

    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed);

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint);

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IERC2612.sol";

interface ILUSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);

    // Getter for the last good price seen from an oracle by Liquity
    function lastGoodPrice() external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;


// Common interface for the Trove Manager.
interface ITroveManager {
    
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _ETHSent, uint _ETHFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower) external view returns (uint);

    function getPendingLUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _LUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);
    
    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);

    function Troves(address) external view returns (uint256, uint256, uint256, uint8, uint128); 
}