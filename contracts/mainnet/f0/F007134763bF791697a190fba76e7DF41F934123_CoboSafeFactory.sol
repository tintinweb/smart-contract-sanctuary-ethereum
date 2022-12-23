// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Pausable.sol";

import "ERC1967Proxy.sol";
import "Ownable.sol";
import "CoboSafeModule.sol";

contract CoboSafeFactory is TransferOwnable, Pausable {
    string public constant NAME = "Cobo Safe Factory";
    string public constant VERSION = "0.5.0";

    /// @dev the current SubSafeModule implementation address
    address public implementation;

    /// @dev the default subSafe factory to work with
    address public subSafeFactory;

    /// @dev the module list
    address[] public modules;
    /// @dev mapping from `safe` => `module`
    mapping(address => address) public safeToModule;
    /// @dev mapping from `module` => `safe`
    mapping(address => address) public moduleToSafe;

    /// @notice Event fired when a module is created
    /// @dev Event fired when a a module is created via `createModule` or `createSubSafeModuleWithNonce`
    /// @param safe the module's owner
    /// @param module the module created
    /// @param sender the owner who created the module
    event NewModule(
        address indexed safe,
        address indexed module,
        address indexed sender
    );

    /// @notice Constructor function for CoboSafeFactory
    /// @dev The factory contract to create CoboSafeModule.
    /// @param _implementation the SubSafe implementation address
    /// @param _subSafeFactory the SubSafeFactory instance's address
    constructor(address _implementation, address _subSafeFactory) {
        setImplementation(_implementation);
        setSubSafeFactory(_subSafeFactory);
    }

    /// @notice Create the module for given safe with the modulesSize as salt seed
    /// @dev It is compatible with previous implementation. The factory contract to create CoboSafeModule
    ///      by using default nonce and subSafeFactory.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    function createModule(address payable _safe)
        external
        whenNotPaused
        returns (address _module)
    {
        _module = createSafeModuleWithNonce(_safe, modulesSize());
    }

    /// @notice Create the module with nonce and subSafeFactory
    /// @dev The factory contract to create CoboSafeModule by using provided nonce and subSafeFactory.
    ///      If _subSafeFactory is zero address, the default is used.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    /// @param _nonce as the seed of salt
    function createSafeModuleWithNonce(address payable _safe, uint256 _nonce)
        public
        whenNotPaused
        returns (address _module)
    {
        require(_safe != address(0), "Invalid safe address");
        require(safeToModule[_safe] == address(0), "Module already created");
        bytes memory bytecode = type(ERC1967Proxy).creationCode;
        bytes memory initData = abi.encodeWithSignature('initialize(address,address)', _safe, subSafeFactory);

        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(implementation, initData)
        );
        bytes32 salt = keccak256(abi.encodePacked(_safe, address(this), _nonce));

        assembly {
            _module := create2(
                0,
                add(creationCode, 32),
                mload(creationCode),
                salt
            )
        }
        require(_module != address(0), "Failed to create module");
        modules.push(_module);
        safeToModule[_safe] = _module;
        moduleToSafe[_module] = _safe;

        emit NewModule(_safe, _module, _msgSender());
    }

    /// @notice Set the SafeModule implementation address
    /// @param _implementation SubSafeModule implementation address
    function setImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0), "Invalid implementation address");
        implementation = _implementation;
    }

    /// @notice Set the SubSafeFactory instance's address
    /// @dev to handle the upgrade of SubSafeFactory
    /// @param _subSafeFactory the SubSafeFactory instance's address
    function setSubSafeFactory(address _subSafeFactory) public onlyOwner {
        require(_subSafeFactory != address(0), "Invalid subSafeFactory address");
        subSafeFactory = _subSafeFactory;
    }

    /// @notice Set the factory pause status
    /// @param paused the paused status of true|false
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /// @notice return the total count of created modules
    /// @return The total count of created modules
    function modulesSize() public view returns (uint256) {
        return modules.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity 0.8.17;

import "Proxy.sol";
import "ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "IBeacon.sol";
import "draft-IERC1822.sol";
import "Address.sol";
import "StorageSlot.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
pragma solidity 0.8.17;

import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract TransferOwnable is Ownable {
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "CoboSafeModuleBase.sol";
import "CoboSubSafe.sol";
import "CoboSubSafeFactory.sol";

/// @title A GnosisSafe module to extend the original CoboSafe that implements Cobo SubSafe and strategy.
///        `SubSafe` is used to separate the fund and to execute the strategy.
/// @author Cobo Safe Dev Team ([email protected])
/// @notice Use this module to access Gnosis Safe with sub-safe and strategy
/// @dev This contract implements the core data structure and its related features.
contract CoboSafeModule is CoboSafeModuleBase {
    /// @dev the subSafe factory to work with
    address public subSafeFactory;

    /// @notice Initializer function for CoboSafeModule
    /// @dev When this module is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance. The instance is
    ///      supposed to call `enableModule` on the constructed module instance
    ///      in order for it to function properly.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    /// @param _subSafeFactory the SubSafeFactory instance's address
    function initialize(address payable _safe, address _subSafeFactory) initializer public {
        require(_subSafeFactory != address(0), "invalid subSafeFactory address");
        __CoboSafeModule_init(_safe);
        subSafeFactory = _subSafeFactory;
    }

    /// @notice Batch call Gnosis Safe to execute transactions through subSafe or not
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract method `to`::`func` in target subSafe,
    ///      where `func` is the function selector contained in first 4 bytes of `data`.
    ///      The function can only be called by delegates.
    /// @param subSafeList The target subSafes to be called, address(0) for bypass subSafe
    /// @param toList The target contracts to be called by subSafe
    /// @param valueList The value data to be transferred by subSafe
    /// @param dataList The input data to be called by subSafe
    function batchExecTransactionsV2(
        address[] calldata subSafeList,
        address[] calldata toList,
        uint256[] calldata valueList,
        bytes[] calldata dataList)
        external
        onlyDelegate
    {
        require(
            subSafeList.length > 0 && subSafeList.length == toList.length && toList.length == valueList.length && toList.length == dataList.length,
            "invalid inputs"
        );

        for (uint256 i = 0; i < toList.length; i++) {
            if(subSafeList[i] != address(0)) {
                _execTransactionBySubSafe(subSafeList[i],toList[i], valueList[i], dataList[i]);
            } else {
                _execTransaction(toList[i], valueList[i], dataList[i]);
            }
        }
    }

    /// @notice Call Gnosis Safe to execute a transaction through subSafe
    /// @param subSafe The target subSafe to be called
    /// @param to The target contract to be called by Gnosis Safe
    /// @param value The value data to be transferred by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    function _execTransactionBySubSafe(address subSafe, address to, uint256 value, bytes calldata data) internal {
        require(subSafe != address(0), "invalid subSafe address");
        require(_isOwnedSubSafe(subSafe), "not owned subSafe");
        require(_hasPermission(_msgSender(), to, value, data), "permission denied");
        bytes memory data = abi.encodeWithSignature('execTransaction(address,uint256,bytes)', to, value, data);

        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        require(
            GnosisSafe(payable(owner())).execTransactionFromModule(
                subSafe,
                value,
                data,
                Enum.Operation.Call
            ),
            "failed in execution for subSafe in safe"
        );
        emit ExecTransaction(subSafe, value, Enum.Operation.Call, data, _msgSender());
    }

    /// @notice Internal function to check if the subSafe owned by the module's owner
    /// @dev Only owned subSafe can be handled by the module
    /// @param subSafe the address of subSube to be checked
    /// @return true|false
    function _isOwnedSubSafe(
        address subSafe
    )  internal view returns (bool) {
        return CoboSubSafeFactory(subSafeFactory).subSafeToSafe(subSafe) == owner();
    }

    /// @notice Return the name of module
    /// @dev reflect the new name
    /// @return name
    function NAME() public override pure returns (string memory) {
        return "Cobo Safe Module";
    }

    /// @notice Return the version of module
    /// @dev reflect the new version
    /// @return version
    function VERSION() public override pure returns (string memory){
        return "0.5.0";
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "UUPSUpgradeable.sol";
import "EnumerableSet.sol";
import "GnosisSafe.sol";
import "OwnableUpgradeable.sol";

/// Interface of AclProtector
interface AclProtector {
    function check(bytes32 role, uint256 value, bytes calldata data) external returns (bool);
}

/// Interface of PostExecutionChecker
interface PostExecutionChecker {
    function postCheck(bytes32 role, uint256 value, bytes calldata data) external returns (bool);
}

/// Interface of TransferProtector
interface TransferProtector {
    function check(bytes32[] memory roles, address receiver, uint256 value) external returns (bool);
}

/// @title A GnosisSafe module that implements Cobo's role based access control policy
/// @author Cobo Safe Dev Team ([email protected])
/// @notice Use this module to access Gnosis Safe with role based access control policy
/// @dev This contract implements the core data structure and its related features.
contract CoboSafeModuleBase is OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Event fired when a delegate is added
    /// @dev Event fired when a delegate is added via `grantRole` method
    /// @param delegate the delegate being added
    /// @param sender the owner who added the delegate
    event DelegateAdded(address indexed delegate, address indexed sender);

    /// @notice Event fired when a delegate is removed
    /// @dev Event fired when a delegate is remove via `revokeRole` method
    /// @param delegate the delegate being removed
    /// @param sender the owner who removed the delegate
    event DelegateRemoved(address indexed delegate, address indexed sender);

    /// @notice Event fired when a role is added
    /// @dev Event fired when a role is being added via `addRole` method
    /// @param role the role being added
    /// @param sender the owner who added the role
    event RoleAdded(bytes32 indexed role, address indexed sender);

    /// @notice Event fired when a role is grant to a delegate
    /// @dev Event fired when a role is grant to a delegate via `grantRole`
    /// @param role the role being granted
    /// @param delegate the delegate being granted the given role
    /// @param sender the owner who granted the role to the given delegate
    event RoleGranted(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    /// @notice Event fired when a role is revoked from a delegate
    /// @dev Event fired when a role is revoked from a delegate via `revokeRole`
    /// @param role the role being revoked
    /// @param delegate the delegate being revoked the given role
    /// @param sender the owner who revoked the role from the given delegate
    event RoleRevoked(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    /// @notice Event fired after a transaction is successfully executed by a delegate
    /// @dev Event fired after a transaction is successfully executed by a delegate via `execTransaction` method
    /// @param to the targate contract to execute the transaction
    /// @param value the ether value to be sent to the target contract when executing the transaction
    /// @param operation use `call` or `delegatecall` to execute the transaction on the contract
    /// @param data input data to execute the transaction on the given contract
    /// @param sender the delegate who execute the transaction
    event ExecTransaction(
        address indexed to,
        uint256 value,
        Enum.Operation operation,
        bytes data,
        address indexed sender
    );

    /// @notice Event fired when a role is associated with a contract and its function list
    /// @dev Event fired when a role is associated with a contract and its function list via `assocRoleWithContractFuncs`
    /// @param role the role to be associated with the given contract and function list
    /// @param _contract the target contract to be associated with the role
    /// @param funcList a list of function signatures of the given contract to be associated with the role
    /// @param sender the owner who associated the role with the contract and its function list
    event AssocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    /// @notice Event fired when a role is disassociate from a contract and its function list
    /// @dev Event fired when a role is disassociate from a contract and its function list via `dissocRoleFromContractFuncs`
    /// @param role the role to be disassociated from the given contract and function list
    /// @param _contract the target contract to be disassociated from the role
    /// @param funcList a list of function signatures of the given contract to be disassociated from the role
    /// @param sender the owner who disassociated the role from the contract and its function list
    event DissocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    /// @notice Event fired when a protector to a contract is changed
    /// @dev Event fired when a protector is changed to protect a contract via `installAclForContract`
    /// @param _contract the target contract to be protected
    /// @param oldProtector the protector contract to be uninstalled
    /// @param newProtector the protector contract to installed
    /// @param sender the owner who install the protector to the target contract
    event ProtectorChanged(
        address indexed _contract,
        address oldProtector,
        address indexed newProtector,
        address indexed sender
    );

    /// @notice Event fired when a post-execution checker to a contract is changed
    /// @dev Event fired when a protector is changed to protect a contract via `installPostExecutionCheckerForContract`
    /// @param _contract the target contract to be protected
    /// @param oldChecker the checker contract to be uninstalled
    /// @param newChecker the checker contract to installed
    /// @param sender the owner who install the checker to the target contract
    event PostExecutionCheckerChanged(
        address indexed _contract,
        address oldChecker,
        address indexed newChecker,
        address indexed sender
    );

    /// @notice Event fired when a call is checked by a protector
    /// @dev Event fired when the a call is checked via `_hasPermission`
    /// @param _contract the target contract to be execute
    /// @param contractFunc the target contract function to be execute
    /// @param protector the contract to check the access control
    /// @param role the role to check the access control
    /// @param value the ether value to be sent to the target contract
    /// @param data the original call data
    /// @param success the result of access control checking
    /// @param sender the user who trigger the execution
    event AclChecked(
        address indexed _contract,
        bytes4 contractFunc,
        address indexed protector,
        bytes32 role,
        uint256 value,
        bytes data,
        bool success,
        address indexed sender
    );

    /// @notice Event fired when a call is checked by a post-execution checker
    /// @dev Event fired when the a call is checked via `_hasPermission`
    /// @param _contract the target contract to be execute
    /// @param contractFunc the target contract function to be execute
    /// @param postExecutionChecker the contract to check after the contract executed
    /// @param role the role to check the access control
    /// @param value the ether value to be sent to the target contract
    /// @param data the original call data
    /// @param success the result of access control checking
    /// @param sender the user who trigger the execution
    event PostExecutionChecked(
        address indexed _contract,
        bytes4 contractFunc,
        address indexed postExecutionChecker,
        bytes32 role,
        uint256 value,
        bytes data,
        bool success,
        address indexed sender
    );

    /// @notice Event fired when a transfer is checked by a protector
    /// @dev Event fired when the a transfer is checked via `_isAllowedTransfer`
    /// @param protector the contract to check the access control
    /// @param receiver transfer receiver
    /// @param value ETH value
    /// @param success the result of access control checking
    /// @param sender the user who trigger the execution
    event TransferChecked(
        address indexed protector,
        address indexed receiver,
        uint256 value,
        bool success,
        address indexed sender
    );

    /// @dev Tracks the set of granted delegates. The set is dynamically added
    ///      to or removed from by  `grantRole` and `rokeRole`.  `isDelegate`
    ///      also uses it to test if a caller is a valid delegate or not
    EnumerableSet.AddressSet delegateSet;

    /// @dev Tracks what roles each delegate owns. The mapping is dynamically
    ///      added to or removed from by  `grantRole` and `rokeRole`. `hasRole`
    ///      also uses it to test if a delegate is granted a given role or not
    mapping(address => EnumerableSet.Bytes32Set) delegateToRoles;

    /// @dev Tracks the set of roles. The set keeps track of all defined roles.
    ///      It is updated by `addRole`, and possibly by `removeRole` if to be
    ///      supported. All role based access policy checks against the set for
    ///      role validity.
    EnumerableSet.Bytes32Set roleSet;

    /// @dev Tracks the set of contract address. The set keeps track of contracts
    ///      which have been associated with a role. It is updated by
    ///      `assocRoleWithContractFuncs` and `dissocRoleFromContractFuncs`
    EnumerableSet.AddressSet contractSet;

    /// @dev mapping from `contract address` => `function selectors`
    mapping(address => EnumerableSet.Bytes32Set) contractToFuncs;

    /// @dev mapping from `contract address` => `function selectors` => `list of roles`
    mapping(address => mapping(bytes32 => EnumerableSet.Bytes32Set)) funcToRoles;

    /// @dev mapping from `contract address` => `protector contract address`
    mapping(address => address) public contractToProtector;

    /// @dev mapping from `contract address` => `post-execution checker contract address`
    mapping(address => address) public contractToPostExecutionChecker;

    /// @dev to protect the chain coin transfer
    address public transferProtector;

    /// @dev modifier to assert only delegate is allow to proceed
    modifier onlyDelegate() {
        require(isDelegate(_msgSender()), "must be delegate");
        _;
    }

    /// @dev modifier to assert the given role must be predefined
    /// @param role the role to be checked
    modifier roleDefined(bytes32 role) {
        require(roleSet.contains(role), "unrecognized role");
        _;
    }

    /// @notice Initialize function for CoboSafeModule
    /// @dev When this module is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance. The instance is
    ///      supposed to call `enableModule` on the constructed module instance
    ///      in order for it to function properly.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    function __CoboSafeModule_init(address payable _safe) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __CoboSafeModule_init_unchained(_safe);
    }

    function __CoboSafeModule_init_unchained(address payable _safe) internal onlyInitializing {
        require(_safe != address(0), "invalid safe address");

        // make the given safe the owner of the current module.
        _transferOwnership(_safe);
    }

    /// @notice Grant a role to a delegate
    /// @dev Granting a role to a delegate will give delegate permission to call
    ///      contract functions associated with the role. Only owner can grant
    ///      role and the must be predefined and not granted to the delegate
    ///      already. on success, `RoleGranted` event would be fired and
    ///      possibly `DelegateAdded` as well if this is the first role being
    ///      granted to the delegate.
    /// @param role the role to be granted
    /// @param delegate the delegate to be granted role
    function grantRole(bytes32 role, address delegate)
        external
        onlyOwner
        roleDefined(role)
    {
        require(!hasRole(role, delegate), "role already granted");

        delegateToRoles[delegate].add(role);

        // We need to emit `DelegateAdded` before `RoleGranted` to allow
        // subgraph event handler to process in sensible order.
        if (delegateSet.add(delegate)) {
            emit DelegateAdded(delegate, _msgSender());
        }

        emit RoleGranted(role, delegate, _msgSender());
    }

    /// @notice Revoke a role from a delegate
    /// @dev Revoking a role from a delegate will remove the permission the
    ///      delegate has to call contract functions associated with the role.
    ///      Only owner can revoke the role.  The role has to be predefined and
    ///      granted to the delegate before revoking, otherwise the function
    ///      will be reverted. `RoleRevoked` event would be fired and possibly
    ///      `DelegateRemoved` as well if this is the last role the delegate
    ///      owns.
    /// @param role the role to be granted
    /// @param delegate the delegate to be granted role
    function revokeRole(bytes32 role, address delegate)
        external
        onlyOwner
        roleDefined(role)
    {
        require(hasRole(role, delegate), "role has not been granted");

        delegateToRoles[delegate].remove(role);

        // We need to make sure `RoleRevoked` is fired before `DelegateRemoved`
        // to make sure the event handlers in subgraphs are triggered in the
        // right order.
        emit RoleRevoked(role, delegate, _msgSender());

        if (delegateToRoles[delegate].length() == 0) {
            delegateSet.remove(delegate);
            emit DelegateRemoved(delegate, _msgSender());
        }
    }

    /// @notice Add a new role
    /// @dev only owner can call this function, the role has to be a new role.
    ///      On success, `RoleAdded` event will be fired
    /// @param role the role to be added
    function addRole(bytes32 role) public onlyOwner {
        require(!roleSet.contains(role), "role exists");

        roleSet.add(role);

        emit RoleAdded(role, _msgSender());
    }

    /// @notice Call Gnosis Safe to execute a transaction
    /// @dev Delegates can call this method to invoke gnosis safe to forward to
    ///      transaction to target contract method `to`::`func`, where `func`
    ///      is the function selector contained in first 4 bytes of `data`.
    ///      The function can only be called by delegates.
    /// @param to The target contract to be called by Gnosis Safe
    /// @param value The value data to be transferred by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    ///
    /// TODO: implement EIP712 signature.
    function execTransaction(address to, uint256 value, bytes calldata data)
        external
        onlyDelegate
    {
        _execTransaction(to, value, data);
    }

    /// @notice Batch execute multiple transaction via Gnosis Safe
    /// @dev This is batch version of the `execTransaction` function to allow
    ///      the delegates to bundle multiple calls into a single transaction and
    ///      sign only once. Batch execute the transactions, one failure cause the
    ///      batch reverted. Only delegates are allowed to call this.
    /// @param toList list of contract addresses to be called
    /// @param valueList list of value data associated with each contract call
    /// @param dataList list of input data associated with each contract call
    function batchExecTransactions(
        address[] calldata toList,
        uint256[] calldata valueList,
        bytes[] calldata dataList
    ) external onlyDelegate {
        require(
            toList.length > 0 && toList.length == valueList.length && toList.length == dataList.length,
            "invalid inputs"
        );

        for (uint256 i = 0; i < toList.length; i++) {
            _execTransaction(toList[i], valueList[i], dataList[i]);
        }
    }

    /// @dev The internal implementation of `execTransaction` and
    ///      `batchExecTransactions`, that invokes gnosis safe to forward to
    ///      transaction to target contract method `to`::`func`, where `func` is
    ///      the function selector contained in first 4 bytes of `data`.  The
    ///      function checks if the calling delegate has the required permission
    ///      to call the designated contract function before invoking Gnosis
    ///      Safe.
    /// @param to The target contract to be called by Gnosis Safe
    /// @param value The value data to be transferred by Gnosis Safe
    /// @param data The input data to be called by Gnosis Safe
    function _execTransaction(address to, uint256 value, bytes calldata data) internal {
        require(_hasPermission(_msgSender(), to, value, data), "permission denied");

        // execute the transaction from Gnosis Safe, note this call will bypass
        // safe owners confirmation.
        require(
            GnosisSafe(payable(owner())).execTransactionFromModule(
                to,
                value,
                data,
                Enum.Operation.Call
            ),
            "failed in execution in safe"
        );

        require(_processPostExecutionCheck(_msgSender(), to, value, data), "post-execution check failed");

        emit ExecTransaction(to, value, Enum.Operation.Call, data, _msgSender());
    }

    /// @dev Internal function to check if a delegate has the permission to call a given contract function
    /// @param delegate the delegate to be checked
    /// @param to the target contract
    /// @param value The value to be checked by protector
    /// @param data the calldata to be checked by protector
    /// @return true|false
    function _hasPermission(
        address delegate,
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bool) {
        // for ETH transfer
        if (data.length == 0) {
            bytes32[] memory roles = getRolesByDelegate(delegate);
            require(roles.length > 0, "no role granted to delegate");

            require(transferProtector != address(0), "invalid transfer protector");
            return _checkByTransferProtector(roles, to, value);
        } else {
            bytes4 selector = _getSelector(data);
            EnumerableSet.Bytes32Set storage funcRoles = funcToRoles[to][selector];
            address aclProtector = contractToProtector[to];

            return _checkContractPermission(delegate, to, value, data, selector, funcRoles, aclProtector);
        }

    }

    function _getSelector(bytes calldata data) internal pure returns (bytes4 selector) {
        require(data.length >=4, "invalid data length");

        assembly {
            selector := calldataload(data.offset)
        }
    }

    /// @dev Internal function to check if a delegate has the permission to call a given contract function
    /// @param delegate the delegate to be checked
    /// @param to the target contract
    /// @param value The value to be checked by protector
    /// @param data the calldata to be checked by protector
    /// @return true|false
    function _checkContractPermission(
        address delegate,
        address to,
        uint256 value,
        bytes calldata data,
        bytes4 _selector,
        EnumerableSet.Bytes32Set storage _funcRoles,
        address _aclProtector
    ) internal returns (bool) {
        bytes32[] memory roles = getRolesByDelegate(delegate);
        require(roles.length > 0, "no role granted to delegate");

        // for contract call
        for (uint256 index = 0; index < roles.length; index++) {
            // check func and parameters
            if (_funcRoles.contains(roles[index])) {
                if (_aclProtector != address(0)) {
                    if (_checkByAclProtector(_aclProtector, roles[index], to, value, _selector, data)) {
                        return true;
                    }
                } else {
                    return true;
                }
            }
        }
        return false;
    }

    /// @dev Internal function to check if a role has the permission to transfer ETH
    /// @param roles the roles to check
    /// @param receiver ETH receiver
    /// @param value ETH value
    /// @return true|false
    function _checkByTransferProtector(
        bytes32[] memory roles,
        address receiver,
        uint256 value
    ) internal returns (bool) {
        bool success = TransferProtector(transferProtector).check(
            roles,
            receiver,
            value
        );
        emit TransferChecked(
            transferProtector,
            receiver,
            value,
            success,
            _msgSender()
        );
        return success;
    }

    /// @dev Internal function to check if a role has the permission to exec transaction
    /// @param aclProtector address of the protector contract
    /// @param role the role to check
    /// @param to the target contract
    /// @param value The value to be checked by protector
    /// @param selector the selector to be checked by protector
    /// @param data the calldata to be checked by protector
    /// @return true|false
    function _checkByAclProtector(
        address aclProtector,
        bytes32 role,
        address to,
        uint256 value,
        bytes4 selector,
        bytes calldata data
    ) internal returns (bool) {
        bool success = AclProtector(aclProtector).check(
            role,
            value,
            data
        );
        emit AclChecked(
            to,
            selector,
            aclProtector,
            role,
            value,
            data,
            success,
            _msgSender()
        );
        return success;
    }

    /// @dev Internal function to proceed the post-execution check
    /// @param delegate the delegate to be checked
    /// @param to the target contract
    /// @param value The value to be checked by protector
    /// @param data the calldata to be checked by protector
    /// @return true|false
    function _processPostExecutionCheck(
        address delegate,
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bool) {
        address postExecutionChecker = contractToPostExecutionChecker[to];
        if (postExecutionChecker == address(0)) {
            return true;
        }

        bytes4 selector = _getSelector(data);
        EnumerableSet.Bytes32Set storage funcRoles = funcToRoles[to][selector];

        bytes32[] memory roles = getRolesByDelegate(delegate);
        require(roles.length > 0, "no role granted to delegate");

        // for contract call
        for (uint256 index = 0; index < roles.length; index++) {
            // check func and parameters
            if (funcRoles.contains(roles[index])) {
                bool success = PostExecutionChecker(postExecutionChecker).postCheck(
                    roles[index],
                    value,
                    data
                );
                emit PostExecutionChecked(
                    to,
                    selector,
                    postExecutionChecker,
                    roles[index],
                    value,
                    data,
                    success,
                    _msgSender()
                );
                if (success) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice Associate a role with given contract funcs
    /// @dev only owners are allowed to call this function, the given role has
    ///      to be predefined. On success, the role will be associated with the
    ///      given contract function, `AssocContractFuncs` event will be fired.
    /// @param role the role to be associated
    /// @param _contract the contract address to be associated with the role
    /// @param funcList the list of contract functions to be associated with the role
    function assocRoleWithContractFuncs(
        bytes32 role,
        address _contract,
        string[] calldata funcList
    ) external onlyOwner roleDefined(role) {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            funcToRoles[_contract][funcSelector32].add(role);
            contractToFuncs[_contract].add(funcSelector32);
        }

        contractSet.add(_contract);

        emit AssocContractFuncs(role, _contract, funcList, _msgSender());
    }

    /// @notice Dissociate a role from given contract funcs
    /// @dev only owners are allowed to call this function, the given role has
    ///      to be predefined. On success, the role will be disassociated from
    ///      the given contract function, `DissocContractFuncs` event will be
    ///      fired.
    /// @param role the role to be disassociated
    /// @param _contract the contract address to be disassociated from the role
    /// @param funcList the list of contract functions to be disassociated from the role
    function dissocRoleFromContractFuncs(
        bytes32 role,
        address _contract,
        string[] calldata funcList
    ) external onlyOwner roleDefined(role) {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            funcToRoles[_contract][funcSelector32].remove(role);

            if (funcToRoles[_contract][funcSelector32].length() <= 0) {
                contractToFuncs[_contract].remove(funcSelector32);
            }
        }

        if (contractToFuncs[_contract].length() <= 0) {
            contractSet.remove(_contract);
        }

        emit DissocContractFuncs(role, _contract, funcList, _msgSender());
    }

    /// @notice Install protector contract for given contract
    /// @dev only owners are allowed to call this function. On success, the contract will
    ///      protector with the selector mapping, `ProtectorChanged` event will be fired.
    /// @param _contract the contract to be protected(address(0) for transfer protector)
    /// @param newProtector the acl/transfer contract
    function installProtectorContract(address _contract, address newProtector)
        external
        onlyOwner
    {
        address oldProtector;
        if (address(_contract) == address(0)) {
            // transfer protector
            oldProtector = transferProtector;
            require(oldProtector != newProtector, "invalid transfer protector");
            transferProtector = newProtector;
        } else {
            // acl protector
            oldProtector = contractToProtector[_contract];
            require(oldProtector != newProtector, "invalid acl protector");
            contractToProtector[_contract] = newProtector;
        }

        emit ProtectorChanged(_contract, oldProtector, newProtector, _msgSender());
    }

    /// @notice Install post-execution checker contract for given contract
    /// @dev only owners are allowed to call this function. On success, the contract will
    ///      protector with the selector mapping, `PostExecutionCheckerChanged` event will be fired.
    /// @param _contract the contract to be protected(address(0) for transfer protector)
    /// @param newChecker the checker contract
    function installPostExecutionCheckerContract(address _contract, address newChecker)
        external
        onlyOwner
    {
        address oldChecker;
        // post-execution checker
        oldChecker = contractToPostExecutionChecker[_contract];
        require(oldChecker != newChecker, "invalid acl protector");
        contractToPostExecutionChecker[_contract] = newChecker;

        emit PostExecutionCheckerChanged(_contract, oldChecker, newChecker, _msgSender());
    }

    /// @notice Return the name of module
    /// @dev to keep the compatible with old version, using the upper case for the function
    /// @return name
    function NAME() public virtual view returns (string memory) {
        return "Cobo Safe Module";
    }

    /// @notice Return the version of module
    /// @dev to keep the compatible with old version, using the upper case for the function
    /// @return version
    function VERSION() public virtual view returns (string memory) {
        return "0.5.0";
    }

    /// @notice Checks if an address is a permitted delegate
    /// @dev the address must have been granted role via `grantRole` in order to become a delegate
    /// @param delegate the address to be checked
    /// @return true|false
    function isDelegate(address delegate) public view returns (bool) {
        return delegateSet.contains(delegate);
    }

    /// @notice Test if a delegate has a role
    /// @dev Return true if a delegate has the role otherwise false.
    /// @param role the role to be checked
    /// @param delegate the delegate to be checked
    /// @return true|false
    function hasRole(bytes32 role, address delegate)
        public
        view
        returns (bool)
    {
        return delegateToRoles[delegate].contains(role);
    }

    /// @notice Public function to check if a role has the permission to call a given contract function
    /// @dev Return true if a role has the permission to call a given contract function otherwise false.
    /// @param role the role to be checked
    /// @param to the target contract
    /// @param selector the function selector of the contract function to be called
    /// @return true|false
    function roleCanAccessContractFunc(
        bytes32 role,
        address to,
        bytes4 selector
    ) external view returns (bool) {
        return funcToRoles[to][selector].contains(role);
    }

    /// @notice Get all the delegates who are currently granted any role
    /// @return list of delegate addresses
    function getAllDelegates() public view returns (address[] memory) {
        bytes32[] memory store = delegateSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a delegate, return all the roles granted to the delegate
    /// @return list of roles
    function getRolesByDelegate(address delegate)
        public
        view
        returns (bytes32[] memory)
    {
        return delegateToRoles[delegate]._inner._values;
    }

    /// @notice Get all the roles defined in the module
    /// @return list of roles
    function getAllRoles() external view returns (bytes32[] memory) {
        return roleSet._inner._values;
    }

    /// @notice Get all the contracts ever associated with any role
    /// @return list of contract addresses
    function getAllContracts() public view returns (address[] memory) {
        bytes32[] memory store = contractSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a contract, list all the function selectors of this contract associated with a role
    /// @param _contract the contract
    /// @return list of function selectors in the contract ever associated with a role
    function getFuncsByContract(address _contract)
        public
        view
        returns (bytes4[] memory)
    {
        bytes32[] memory store = contractToFuncs[_contract]._inner._values;
        bytes4[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    /// @notice Given a function, list all the roles that have permission to access to them
    /// @param _contract the contract address
    /// @param funcSelector the function selector
    /// @return list of roles
    function getRolesByContractFunction(address _contract, bytes4 funcSelector)
        public
        view
        returns (bytes32[] memory)
    {
        return funcToRoles[_contract][funcSelector]._inner._values;
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "draft-IERC1822Upgradeable.sol";
import "ERC1967UpgradeUpgradeable.sol";
import "Initializable.sol";

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

import "IBeaconUpgradeable.sol";
import "draft-IERC1822Upgradeable.sol";
import "AddressUpgradeable.sol";
import "StorageSlotUpgradeable.sol";
import "Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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

abstract contract TransferOwnableUpgradeable is OwnableUpgradeable {
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "UUPSUpgradeable.sol";
import "IERC20Upgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "OwnableUpgradeable.sol";

contract CoboSubSafe is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Event fired when fund is collected
    /// @dev Event fired when fund is collected via `collectFund` method
    /// @param erc20 the token being collected, zero address for chain asset
    /// @param tokenAmt the amount to be collected, 0 for balance
    /// @param to the receiver address, mostly to the parent safe
    event Collected(
        address indexed erc20,
        uint256 tokenAmt,
        address indexed to
    );

    /// @notice Constructor function for CoboArgusSubSafe
    /// @dev When this subSafe is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    function initialize(address payable _safe) initializer public {
        __CoboSubSafe_init(_safe);
    }

    function __CoboSubSafe_init(address payable _safe) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __CoboSubSafe_init_unchained(_safe);
    }

    function __CoboSubSafe_init_unchained(address payable _safe) internal onlyInitializing {
        require(_safe != address(0), "invalid safe address");

        // make the given safe the owner of the current module.
        _transferOwnership(_safe);
    }

    /**
     * @notice Collect fund from subSafe to Gnosis Safe.
     * @dev To collect the fund from subSafe to Gnosis Safe. If the `erc20` is the reward token,
     *      the commission is applied. If the `tokenAmt` is zero, all balance is collected.
     * @param erc20 Token Address(zero address for ETH).
     * @param tokenAmt Token Amount.
     */
    function collectFund(address erc20, uint256 tokenAmt)
        public
        onlyOwner
    {
        if (erc20 == address(0)) {
            uint256 maxAmt = address(this).balance;
            if (tokenAmt == 0) {
                tokenAmt = maxAmt;
            } else {
                tokenAmt = tokenAmt >= maxAmt ? maxAmt : tokenAmt;
            }
            // need check if work as expected
            payable(owner()).transfer(tokenAmt);
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(erc20);
            uint256 maxAmt = token.balanceOf(address(this));
            if (tokenAmt == 0) {
                tokenAmt = maxAmt;
            } else {
                tokenAmt = tokenAmt >= maxAmt ? maxAmt : tokenAmt;
            }
            token.safeTransfer(owner(), tokenAmt);
        }

        emit Collected(erc20, tokenAmt, owner());
    }

    /// @notice Execute transaction via subSafe
    /// @dev Only owner are allowed to call this.
    /// @param to contract address to be called
    /// @param value value data associated with contract call
    /// @param data input data associated with contract call
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwner returns (bytes memory) {
         (bool success, bytes memory ret) = to.call{value: value}(data);
        require(success);
        return ret;
    }

    /// @notice Return the name of module
    /// @dev reflect the new name
    /// @return name
    function NAME() public pure returns (string memory) {
        return "Cobo SubSafe";
    }

    /// @notice Return the version of module
    /// @dev reflect the new version
    /// @return version
    function VERSION() public pure returns (string memory){
        return "0.1.0";
    }

    receive() external payable {}

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "draft-IERC20PermitUpgradeable.sol";
import "AddressUpgradeable.sol";

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "EnumerableSet.sol";
import "Pausable.sol";

import "ERC1967Proxy.sol";
import "Ownable.sol";
import "CoboSubSafe.sol";

contract CoboSubSafeFactory is TransferOwnable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "Cobo SubSafe Factory";
    string public constant VERSION = "0.1.0";

    /// @dev the current SubSafe implementation address
    address public implementation;

    /// @dev total subSafes created by this factory
    address[] public subSafes;

    /// @dev mapping from `Cobo SubSafe` => `Name`
    mapping(address => string) public subSafesName;

    /// @dev mapping from `Gnosis safe address` => `Cobo SubSafes`
    mapping(address => EnumerableSet.AddressSet) safeToSubSafes;

    /// @dev mapping from `Cobo SubSafe` => `Gnosis safe address`
    mapping(address => address) public subSafeToSafe;

    /// @notice Event fired when a subSafe is created
    /// @dev Event fired when a subSafe is created  via `createSubSafe` method
    /// @param safe the parent safe address
    /// @param safe the Cobo subSafe address
    /// @param name the subSafe's name
    event SubSafeCreated(
        address indexed safe,
        address indexed subSafe,
        string name
    );

    /// @notice Constructor function for CoboSubSafeFactory
    /// @dev Deploy the factory with the default SubSafe implementation.
    /// @param _implementation the SubSafe implementation address
    constructor(address _implementation) {
        setImplementation(_implementation);
    }

    /// @notice Create the CoboSubSafe
    /// @dev To create the subSafe by using create2 method. The salt is generated based on
    ///      sender's address, factory address and nonce given. `SubSafeCreated` event is
    ///      fired after created successfully.
    /// @param name the subSafe's name.
    /// @param nonce the nonce to generate the salt.
    function createSubSafe(string memory name, uint256 nonce)
        external
        whenNotPaused
        returns (address subSafe)
    {
        address safe = _msgSender();
        bytes memory bytecode = type(ERC1967Proxy).creationCode;
        bytes memory initData = abi.encodeWithSignature('initialize(address)', safe);

        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(implementation, initData)
        );
        bytes32 salt = keccak256(abi.encodePacked(safe, address(this), nonce));

        assembly {
            subSafe := create2(0, add(creationCode, 32), mload(creationCode), salt)
        }
        require(subSafe != address(0), "Failed to create subSafe");

        require(subSafeToSafe[subSafe] == address(0), "Duplicated subSafe existed");
        emit SubSafeCreated(safe, subSafe, name);

        subSafes.push(subSafe);
        subSafesName[subSafe] = name;
        safeToSubSafes[safe].add(subSafe);
        subSafeToSafe[subSafe] = safe;
    }

    /// @notice Set the SubSafe implementation address
    /// @param _implementation SubSafe implementation address
    function setImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0), "invalid implementation address");
        implementation = _implementation;
    }

    /// @notice Set the factory pause status
    /// @param paused the paused status of true|false
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /// @notice return the total count of created subSafes
    /// @return The total count of created subSafes
    function subSafesSize() external view returns (uint256) {
        return subSafes.length;
    }

    /// @notice Given a function, list all the roles that have permission to access to them
    /// @param safe the gnosis safe owned the subSafe
    /// @return list of subSafes
    function getSubSafesBySafe(address safe)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = safeToSubSafes[safe]._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }
}