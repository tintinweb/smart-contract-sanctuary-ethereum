/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/core/IDAO.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IDAO
/// @author Aragon Association - 2022
/// @notice The interface required for DAOs within the Aragon App DAO framework.
abstract contract IDAO {
    /// @notice The `IDAO` interface ID.
    bytes4 internal constant DAO_INTERFACE_ID = type(IDAO).interfaceId;

    struct Action {
        address to; // Address to call
        uint256 value; // Value to be sent with the call (for example ETH if on mainnet)
        bytes data; // FuncSig + arguments
    }

    /// @notice Checks if an address has permission on a contract via a permission identifier and considers if `ANY_ADDRESS` was used in the granting process.
    /// @param _where The address of the contract.
    /// @param _who The address of a EOA or contract to give the permissions.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionOracle` registered.
    /// @return bool Returns true if the address has permission, false if not.
    function hasPermission(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) external virtual returns (bool);

    /// @notice Updates the DAO metadata (e.g., an IPFS hash).
    /// @param _metadata The IPFS hash of the new metadata object.
    function setMetadata(bytes calldata _metadata) external virtual;

    /// @notice Emitted when the DAO metadata is updated.
    /// @param metadata The IPFS hash of the new metadata object.
    event MetadataSet(bytes metadata);

    /// @notice Executes a list of actions.
    /// @dev Runs a loop through the array of actions and executes them one by one. If one action fails, all will be reverted.
    /// @param callId The id of the call. The definition of the value of callId is up to the calling contract and can be used, e.g., as a nonce.
    /// @param _actions The array of actions.
    /// @return bytes[] The array of results obtained from the executed actions in `bytes`.
    function execute(uint256 callId, Action[] memory _actions)
        external
        virtual
        returns (bytes[] memory);

    /// @notice Emitted when a proposal is executed.
    /// @param actor The address of the caller.
    /// @param callId The id of the call.
    /// @dev The value of callId is defined by the component/contract calling the execute function.
    ///      A Component implementation can use it, for example, as a nonce.
    /// @param actions Array of actions executed.
    /// @param execResults Array with the results of the executed actions.
    event Executed(address indexed actor, uint256 callId, Action[] actions, bytes[] execResults);

    /// @notice Deposits (native) tokens to the DAO contract with a reference string.
    /// @param _token The address of the token or address(0) in case of the native token.
    /// @param _amount The amount of tokens to deposit.
    /// @param _reference The reference describing the deposit reason.
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external payable virtual;

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );

    /// @notice Emitted when a native token deposit has been made to the DAO.
    /// @dev This event is intended to be emitted in the `receive` function and is therefore bound by the gas limitations for `send`/`transfer` calls introduced by EIP-2929.
    /// @param sender The address of the sender.
    /// @param amount The amount of native tokens deposited.
    event NativeTokenDeposited(address sender, uint256 amount);

    /// @notice Withdraw (native) tokens from the DAO with a withdraw reference string.
    /// @param _token The address of the token and address(0) in case of the native token.
    /// @param _to The target address to send (native) tokens to.
    /// @param _amount The amount of (native) tokens to withdraw.
    /// @param _reference The reference describing the withdrawal reason.
    function withdraw(
        address _token,
        address _to,
        uint256 _amount,
        string memory _reference
    ) external virtual;

    /// @notice Emitted when a (native) token withdrawal has been made from the DAO.
    /// @param token The address of the withdrawn token or address(0) in case of the native token.
    /// @param to The address of the withdrawer.
    /// @param amount The amount of tokens withdrawn.
    /// @param _reference The reference describing the withdrawal reason.
    event Withdrawn(address indexed token, address indexed to, uint256 amount, string _reference);

    /// @notice Setter for the trusted forwarder verifying the meta transaction.
    /// @param _trustedForwarder The trusted forwarder address.
    function setTrustedForwarder(address _trustedForwarder) external virtual;

    /// @notice Getter for the trusted forwarder verifying the meta transaction.
    /// @return The trusted forwarder address.
    function getTrustedForwarder() external virtual returns (address);

    /// @notice Emitted when a new TrustedForwarder is set on the DAO.
    /// @param forwarder the new forwarder address.
    event TrustedForwarderSet(address forwarder);

    /// @notice Setter for the ERC1271 signature validator contract.
    /// @param _signatureValidator ERC1271 SignatureValidator.
    function setSignatureValidator(address _signatureValidator) external virtual;

    /// @notice Checks whether a signature is valid for the provided data.
    /// @param _hash The keccak256 hash of arbitrary length data signed on the behalf of `address(this)`.
    /// @param _signature Signature byte array associated with _data.
    /// @return magicValue Returns the `bytes4` magic value `0x1626ba7e` if the signature is valid.
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        virtual
        returns (bytes4);
}

// File @openzeppelin/contracts/interfaces/[email protected]

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

// File @openzeppelin/contracts/proxy/beacon/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

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
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/proxy/ERC1967/[email protected]

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
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
        require(
            Address.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
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
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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

// File @openzeppelin/contracts/proxy/utils/[email protected]

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
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
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
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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

// File contracts/core/permission/IPermissionOracle.sol

pragma solidity 0.8.10;

/// @title IPermissionOracle
/// @author Aragon Association - 2021
/// @notice This interface can be implemented to support more customary permissions depending on on- or off-chain state, e.g., by querying token ownershop or a secondary oracle, respectively.
interface IPermissionOracle {
    /// @notice This method is used to check if a call is permitted.
    /// @param _where The address of the target contract.
    /// @param _who The address (EOA or contract) for which the permission are checked.
    /// @param _permissionId The permission identifier.
    /// @param _data Optional data passed to the `PermissionOracle` implementation.
    /// @return allowed Returns true if the call is permitted.
    function hasPermissions(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes calldata _data
    ) external returns (bool allowed);
}

// File contracts/core/permission/BulkPermissionsLib.sol

pragma solidity 0.8.10;

/// @title BulkPermissionsLib
/// @author Aragon Association - 2021, 2022
/// @notice A library containing objects for bulk permission processing.
library BulkPermissionsLib {
    enum Operation {
        Grant,
        Revoke,
        Freeze
    }

    struct Item {
        Operation operation;
        bytes32 permissionId;
        address who;
    }
}

// File contracts/core/permission/PermissionManager.sol

pragma solidity 0.8.10;

/// @title PermissionManager
/// @author Aragon Association - 2021, 2022
/// @notice The permission manager used in a DAO and its associated components.
contract PermissionManager is Initializable {
    /// @notice The ID of the permission required to call the `grant`, `grantWithOracle`, `revoke`, `freeze`, and `bulk` function.
    bytes32 public constant ROOT_PERMISSION_ID = keccak256("ROOT_PERMISSION");

    /// @notice A special address encoding permissions that are valid for any address.
    address internal constant ANY_ADDR = address(type(uint160).max);

    /// @notice A special address encoding if a permissions is not set and therefore not allowed.
    address internal constant UNSET_FLAG = address(0);

    /// @notice A special address encoding if a permission is allowed.
    address internal constant ALLOW_FLAG = address(2);

    /// @notice A mapping storing permissions as hashes (i.e., `permissionHash(where, who, permissionId)`) and their status (unset, allowed, or redirect to a `PermissionOracle`).
    mapping(bytes32 => address) internal permissionsHashed;

    /// @notice A mapping storing frozen permissions as hashes (i.e., `frozenPermissionHash(where, permissionId)`) and their status (`true` = frozen (immutable), `false` = not frozen (mutable)).
    mapping(bytes32 => bool) internal frozenPermissionsHashed;

    /// @notice Thrown if a call is unauthorized.
    /// @param here The context in which the authorization reverted.
    /// @param where The contract requiring the permission.
    /// @param who The address (EOA or contract) missing the permission.
    /// @param permissionId The permission identifier.
    error Unauthorized(address here, address where, address who, bytes32 permissionId);

    /// @notice Thrown if a permission has been already granted.
    /// @param where The address of the target contract to grant `who` permission to.
    /// @param who The address (EOA or contract) to which the permission has already been granted.
    /// @param permissionId The permission identifier.
    error PermissionAlreadyGranted(address where, address who, bytes32 permissionId);

    /// @notice Thrown if a permission has been already revoked.
    /// @param where The address of the target contract to revoke `who`s permission from.
    /// @param who The address (EOA or contract) from which the permission has already been revoked.
    /// @param permissionId The permission identifier.
    error PermissionAlreadyRevoked(address where, address who, bytes32 permissionId);

    /// @notice Thrown if a permission is frozen.
    /// @param where The address of the target contract for which the permission is frozen.
    /// @param permissionId The permission identifier.
    error PermissionFrozen(address where, bytes32 permissionId);

    // Events

    /// @notice Emitted when a permission `permission` is granted in the context `here` to the address `who` for the contract `where`.
    /// @param permissionId The permission identifier.
    /// @param here The address of the context in which the permission is granted.
    /// @param who The address (EOA or contract) receiving the permission.
    /// @param where The address of the target contract for which `who` receives permission.
    /// @param oracle The address `ALLOW_FLAG` for regular permissions or, alternatively, the `PermissionOracle` to be used.
    event Granted(
        bytes32 indexed permissionId,
        address indexed here,
        address indexed who,
        address where,
        IPermissionOracle oracle
    );

    /// @notice Emitted when a permission `permission` is revoked in the context `here` from the address `who` for the contract `where`.
    /// @param permissionId The permission identifier.
    /// @param here The address of the context in which the permission is revoked.
    /// @param who The address (EOA or contract) losing the permission.
    /// @param where The address of the target contract for which `who` loses permission
    event Revoked(
        bytes32 indexed permissionId,
        address indexed here,
        address indexed who,
        address where
    );

    /// @notice Emitted when a `permission` is made frozen to the address `here` by the contract `where`.
    /// @param permissionId The permission identifier.
    /// @param here The address of the context in which the permission is frozen.
    /// @param where The address of the target contract for which the permission is frozen.
    event Frozen(bytes32 indexed permissionId, address indexed here, address where);

    /// @notice A modifier to be used to check permissions on a target contract.
    /// @param _where The address of the target contract for which the permission is required.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(address _where, bytes32 _permissionId) {
        if (
            !(hasPermissions(_where, msg.sender, _permissionId, msg.data) ||
                hasPermissions(address(this), msg.sender, _permissionId, msg.data))
        )
            revert Unauthorized({
                here: address(this),
                where: _where,
                who: msg.sender,
                permissionId: _permissionId
            });
        _;
    }

    /// @notice Initialization method to set the initial owner of the permission manager.
    /// @dev The initial owner is granted the `ROOT_PERMISSION_ID` permission.
    /// @param _initialOwner The initial owner of the permission manager.
    function __PermissionManager_init(address _initialOwner) internal onlyInitializing {
        _initializePermissionManager(_initialOwner);
    }

    /// @notice Grants permission to an address to call methods in a contract guarded by an auth modifier with the specified permission identifier.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) receiving the permission.
    /// @param _permissionId The permission identifier.
    function grant(
        address _where,
        address _who,
        bytes32 _permissionId
    ) external auth(_where, ROOT_PERMISSION_ID) {
        _grant(_where, _who, _permissionId);
    }

    /// @notice Grants permission to an address to call methods in a target contract guarded by an auth modifier with the specified permission identifier if the referenced oracle permits it.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) receiving the permission.
    /// @param _permissionId The permission identifier.
    /// @param _oracle The `PermissionOracle` that will be asked for authorization on calls connected to the specified permission identifier.
    function grantWithOracle(
        address _where,
        address _who,
        bytes32 _permissionId,
        IPermissionOracle _oracle
    ) external auth(_where, ROOT_PERMISSION_ID) {
        _grantWithOracle(_where, _who, _permissionId, _oracle);
    }

    /// @notice Revokes permission from an address to call methods in a target contract guarded by an auth modifier with the specified permission identifier.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the target contract for which `who` loses permission.
    /// @param _who The address (EOA or contract) losing the permission.
    /// @param _permissionId The permission identifier.
    function revoke(
        address _where,
        address _who,
        bytes32 _permissionId
    ) external auth(_where, ROOT_PERMISSION_ID) {
        _revoke(_where, _who, _permissionId);
    }

    /// @notice Freezes the current permission settings of a target contract. This is a permanent operation and permissions on the specified contract with the specified permission identifier can never be granted or revoked again.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the target contract for which the permission are frozen.
    /// @param _permissionId The permission identifier.
    function freeze(address _where, bytes32 _permissionId)
        external
        auth(_where, ROOT_PERMISSION_ID)
    {
        _freeze(_where, _permissionId);
    }

    /// @notice Processes bulk items on the permission manager.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the contract.
    /// @param items The array of bulk items to process.
    function bulk(address _where, BulkPermissionsLib.Item[] calldata items)
        external
        auth(_where, ROOT_PERMISSION_ID)
    {
        for (uint256 i = 0; i < items.length; i++) {
            BulkPermissionsLib.Item memory item = items[i];

            if (item.operation == BulkPermissionsLib.Operation.Grant)
                _grant(_where, item.who, item.permissionId);
            else if (item.operation == BulkPermissionsLib.Operation.Revoke)
                _revoke(_where, item.who, item.permissionId);
            else if (item.operation == BulkPermissionsLib.Operation.Freeze)
                _freeze(_where, item.permissionId);
        }
    }

    /// @notice Checks if an address has permission on a contract via a permission identifier and considers if `ANY_ADDRESS` was used in the granting process.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) for which the permission is checked.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionOracle` registered.
    /// @return bool Returns true if `who` has the permissions on the target contract via the specified permission identifier.
    function hasPermissions(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) public returns (bool) {
        return
            _hasPermission(_where, _who, _permissionId, _data) || // check if _who has permission for _permissionId on _where
            _hasPermission(_where, ANY_ADDR, _permissionId, _data) || // check if anyone has permission for _permissionId on _where
            _hasPermission(ANY_ADDR, _who, _permissionId, _data); // check if _who has permission for _permissionId on any contract
    }

    /// @notice This method is used to check if permissions for a given permission identifier on a contract are frozen.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _permissionId The permission identifier.
    /// @return bool Returns true if the permission identifier is frozen for the contract address.
    function isFrozen(address _where, bytes32 _permissionId) public view returns (bool) {
        return frozenPermissionsHashed[frozenPermissionHash(_where, _permissionId)];
    }

    /// @notice Grants the `ROOT_PERMISSION_ID` permission to the initial owner during initialization of the permission manager.
    /// @param _initialOwner The initial owner of the permission manager.
    function _initializePermissionManager(address _initialOwner) internal {
        _grant(address(this), _initialOwner, ROOT_PERMISSION_ID);
    }

    /// @notice This method is used in the public `grant` method of the permission manager.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    function _grant(
        address _where,
        address _who,
        bytes32 _permissionId
    ) internal {
        _grantWithOracle(_where, _who, _permissionId, IPermissionOracle(ALLOW_FLAG));
    }

    /// @notice This method is used in the internal `_grant` method of the permission manager.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    /// @param _oracle The PermissionOracle to be used or it is just the ALLOW_FLAG.
    function _grantWithOracle(
        address _where,
        address _who,
        bytes32 _permissionId,
        IPermissionOracle _oracle
    ) internal {
        if (isFrozen(_where, _permissionId)) {
            revert PermissionFrozen({where: _where, permissionId: _permissionId});
        }

        bytes32 permHash = permissionHash(_where, _who, _permissionId);

        if (permissionsHashed[permHash] != UNSET_FLAG) {
            revert PermissionAlreadyGranted({
                where: _where,
                who: _who,
                permissionId: _permissionId
            });
        }
        permissionsHashed[permHash] = address(_oracle);

        emit Granted(_permissionId, msg.sender, _who, _where, _oracle);
    }

    /// @notice This method is used in the public `revoke` method of the permission manager.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    function _revoke(
        address _where,
        address _who,
        bytes32 _permissionId
    ) internal {
        if (isFrozen(_where, _permissionId)) {
            revert PermissionFrozen({where: _where, permissionId: _permissionId});
        }

        bytes32 permHash = permissionHash(_where, _who, _permissionId);
        if (permissionsHashed[permHash] == UNSET_FLAG) {
            revert PermissionAlreadyRevoked({
                where: _where,
                who: _who,
                permissionId: _permissionId
            });
        }
        permissionsHashed[permHash] = UNSET_FLAG;

        emit Revoked(_permissionId, msg.sender, _who, _where);
    }

    /// @notice This method is used in the public `freeze` method of the permission manager.
    /// @param _where The address of the target contract for which the permission is frozen.
    /// @param _permissionId The permission identifier.
    function _freeze(address _where, bytes32 _permissionId) internal {
        bytes32 frozenPermHash = frozenPermissionHash(_where, _permissionId);
        if (frozenPermissionsHashed[frozenPermHash]) {
            revert PermissionFrozen({where: _where, permissionId: _permissionId});
        }
        frozenPermissionsHashed[frozenPermHash] = true;

        emit Frozen(_permissionId, msg.sender, _where);
    }

    /// @notice Checks if a caller has the permissions on a contract via a permission identifier and redirects the approval to an `PermissionOracle` if this was in the setup.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionOracle` registered..
    /// @return bool Returns true if `who` has the permissions on the contract via the specified permissionId identifier.
    function _hasPermission(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) internal returns (bool) {
        address accessFlagOrAclOracle = permissionsHashed[
            permissionHash(_where, _who, _permissionId)
        ];

        if (accessFlagOrAclOracle == UNSET_FLAG) return false;
        if (accessFlagOrAclOracle == ALLOW_FLAG) return true;

        // Since it's not a flag, assume it's an PermissionOracle and try-catch to skip failures
        try
            IPermissionOracle(accessFlagOrAclOracle).hasPermissions(
                _where,
                _who,
                _permissionId,
                _data
            )
        returns (bool allowed) {
            if (allowed) return true;
        } catch {}

        return false;
    }

    /// @notice Generates the hash for the `permissionsHashed` mapping obtained from the word "PERMISSION", the contract address, the address owning the permission, and the permission identifier.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    /// @return bytes32 The permission hash.
    function permissionHash(
        address _where,
        address _who,
        bytes32 _permissionId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("PERMISSION", _who, _where, _permissionId));
    }

    /// @notice Generates the hash for the `frozenPermissionsHashed` mapping obtained from the word "IMMUTABLE", the contract address, and the permission identifier.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _permissionId The permission identifier.
    /// @return bytes32 The hash used in the `frozenPermissions` mapping.
    function frozenPermissionHash(address _where, bytes32 _permissionId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("IMMUTABLE", _where, _permissionId));
    }
}

// File contracts/core/component/DaoAuthorizable.sol

pragma solidity 0.8.10;

/// @title DaoAuthorizable
/// @author Aragon Association - 2022
/// @notice An abstract contract providing a meta transaction compatible modifier to authorize function calls through an associated DAO.
/// This contract provides an `auth` modifier that can be applied to functions in inheriting contracts. The permission to call these functions is managed by the associated DAO.
/// @dev Make sure to call `__DaoAuthorizable_init` during initialization of the inheriting contract.
///      This contract is compatible with meta transactions through OZ's `ContextUpgradable`.
abstract contract DaoAuthorizable is Initializable, ContextUpgradeable {
    /// @notice The associated DAO managing the permissions of inheriting contracts.
    IDAO internal dao;

    /// @notice Thrown if a call is unauthorized in the associated DAO.
    /// @param dao The associated DAO.
    /// @param here The context in which the authorization reverted.
    /// @param where The contract requiring the permission.
    /// @param who The address (EOA or contract) missing the permission.
    /// @param permissionId The permission identifier.
    error DaoUnauthorized(
        address dao,
        address here,
        address where,
        address who,
        bytes32 permissionId
    );

    /// @notice Initializes the contract by setting the associated DAO.
    /// @param _dao The associated DAO address.
    function __DaoAuthorizable_init(IDAO _dao) internal virtual onlyInitializing {
        dao = _dao;
    }

    /// @notice A modifier to be used to check permissions on a target contract via the associated DAO.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(bytes32 _permissionId) {
        if (!dao.hasPermission(address(this), _msgSender(), _permissionId, _msgData()))
            revert DaoUnauthorized({
                dao: address(dao),
                here: address(this),
                where: address(this),
                who: _msgSender(),
                permissionId: _permissionId
            });

        _;
    }
}

// File contracts/core/erc165/ERC165.sol

pragma solidity 0.8.10;

/// @title ERC165
/// @author Aragon Association - 2022
abstract contract ERC165 {
    /// @notice The interface ID of the `supportsInterface` function.
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /// @notice Virtual method to query if a contract supports a certain interface defaulting to the `ERC165_INTERFACE_ID` if it is not overridden.
    /// @param _interfaceId The interface identifier as specified in ERC-165 being queried.
    /// @return True if the inheriting contract implements the requested interface, false otherwise.
    function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}

// File contracts/core/erc165/AdaptiveERC165.sol

pragma solidity 0.8.10;

/// @title AdaptiveERC165
/// @author Aragon Association - 2022
contract AdaptiveERC165 is ERC165 {
    /// @notice ERC165 interface ID -> whether it is supported
    mapping(bytes4 => bool) internal standardSupported;

    /// @notice Callback function signature -> magic number to return
    mapping(bytes4 => bytes32) internal callbackMagicNumbers;

    bytes32 internal constant UNREGISTERED_CALLBACK = bytes32(0);

    // Errors
    error AdapERC165UnkownCallback(bytes32 magicNumber);

    // Events

    /// @notice Emmitted when a new standard is registred and assigned to `interfaceId`
    event StandardRegistered(bytes4 interfaceId);

    /// @notice Emmitted when a callback is registered
    event CallbackRegistered(bytes4 sig, bytes4 magicNumber);

    /// @notice Emmitted when a callback is received
    event CallbackReceived(bytes4 indexed sig, bytes data);

    /// @notice Checks if the contract supports a specific interface or not
    /// @param _interfaceId The identifier of the interface to check for
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return standardSupported[_interfaceId] || super.supportsInterface(_interfaceId);
    }

    /// @notice Handles callbacks to support future versions of the ERC165 or similar without upgrading the contracts.
    /// @param _sig The function signature of the called method (msg.sig)
    /// @param _data The data resp. arguments passed to the method
    function _handleCallback(bytes4 _sig, bytes memory _data) internal {
        bytes32 magicNumber = callbackMagicNumbers[_sig];
        if (magicNumber == UNREGISTERED_CALLBACK)
            revert AdapERC165UnkownCallback({magicNumber: magicNumber});

        emit CallbackReceived(_sig, _data);

        // low-level return magic number
        assembly {
            mstore(0x00, magicNumber)
            return(0x00, 0x20)
        }
    }

    /// @notice Registers a standard and also callback
    /// @param _interfaceId The identifier of the interface to check for
    /// @param _callbackSig The function signature of the called method (msg.sig)
    /// @param _magicNumber The magic number to be registered for the function signature
    function _registerStandardAndCallback(
        bytes4 _interfaceId,
        bytes4 _callbackSig,
        bytes4 _magicNumber
    ) internal {
        _registerStandard(_interfaceId);
        _registerCallback(_callbackSig, _magicNumber);
    }

    /// @notice Registers a standard resp. interface type
    /// @param _interfaceId The identifier of the interface to check for
    function _registerStandard(bytes4 _interfaceId) internal {
        standardSupported[_interfaceId] = true;
        emit StandardRegistered(_interfaceId);
    }

    /// @notice Registers a callback
    /// @param _callbackSig The function signature of the called method (msg.sig)
    /// @param _magicNumber The magic number to be registered for the function signature
    function _registerCallback(bytes4 _callbackSig, bytes4 _magicNumber) internal {
        callbackMagicNumbers[_callbackSig] = _magicNumber;
        emit CallbackRegistered(_callbackSig, _magicNumber);
    }
}

// File contracts/registry/InterfaceBasedRegistry.sol

pragma solidity 0.8.10;

/// @title InterfaceBasedRegistry
/// @author Aragon Association - 2022
/// @notice An [ERC-165](https://eips.ethereum.org/EIPS/eip-165)-based registry for contracts
abstract contract InterfaceBasedRegistry is DaoAuthorizable, UUPSUpgradeable {
    /// @notice The ID of the permission required to call the `_authorizeUpgrade` function.
    bytes32 public constant UPGRADE_PERMISSION_ID = keccak256("UPGRADE_PERMISSION");

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID that the target contracts being registered must support.
    bytes4 public targetInterfaceId;

    /// @notice The mapping containing the registry entries returning true for registererd contract addresses.
    mapping(address => bool) public entries;

    /// @notice Thrown if the contract is already registered.
    /// @param registrant The address of the contract to be registered.
    error ContractAlreadyRegistered(address registrant);

    /// @notice Thrown if the contract does not support the required interface.
    /// @param registrant The address of the contract to be registered.
    error ContractInterfaceInvalid(address registrant);

    /// @notice Thrown if the address is not a contract.
    /// @param registrant The address of the contract to be registered.
    error ContractAddressInvalid(address registrant);

    /// @notice Thrown if the contract do not support ERC165.
    /// @param registrant The address of the contract.
    error ContractERC165SupportInvalid(address registrant);

    /// @notice Initializes the component.
    /// @dev This is required for the UUPS upgradability pattern.
    /// @param _managingDao The interface of the DAO managing the components permissions.
    /// @param _targetInterfaceId The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface id of the contracts to be registered.
    function __InterfaceBasedRegistry_init(IDAO _managingDao, bytes4 _targetInterfaceId)
        internal
        virtual
        onlyInitializing
    {
        __DaoAuthorizable_init(_managingDao);

        targetInterfaceId = _targetInterfaceId;
    }

    /// @notice Internal method authorizing the upgrade of the contract via the [upgradeabilty mechanism for UUPS proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @dev The caller must have the `UPGRADE_PERMISSION_ID` permission.
    function _authorizeUpgrade(address) internal virtual override auth(UPGRADE_PERMISSION_ID) {}

    /// @notice Register an [ERC-165](https://eips.ethereum.org/EIPS/eip-165) contract address.
    /// @dev The managing DAO needs to grant REGISTER_PERMISSION_ID to registrar.
    /// @param registrant The address of an [ERC-165](https://eips.ethereum.org/EIPS/eip-165) contract.
    function _register(address registrant) internal {
        if (!Address.isContract(registrant)) {
            revert ContractAddressInvalid({registrant: registrant});
        }

        if (entries[registrant]) revert ContractAlreadyRegistered({registrant: registrant});

        try AdaptiveERC165(registrant).supportsInterface(targetInterfaceId) returns (bool result) {
            if (!result) revert ContractInterfaceInvalid(registrant);
        } catch {
            revert ContractERC165SupportInvalid({registrant: registrant});
        }

        entries[registrant] = true;
    }
}

// File contracts/registry/DAORegistry.sol

pragma solidity 0.8.10;

/// @title Register your unique DAO name
/// @author Aragon Association - 2022
/// @notice This contract provides the possiblity to register a DAO.
contract DAORegistry is InterfaceBasedRegistry {
    bytes32 public constant REGISTER_DAO_PERMISSION_ID = keccak256("REGISTER_DAO_PERMISSION");

    /// @notice Emitted when a new DAO is registered
    /// @param dao The address of the DAO contract
    /// @param creator The address of the creator
    /// @param name The name of the DAO
    event DAORegistered(IDAO indexed dao, address indexed creator, string name);

    /// @notice Initializes the contract
    /// @param _managingDao the managing DAO address
    function initialize(IDAO _managingDao) public initializer {
        __InterfaceBasedRegistry_init(_managingDao, type(IDAO).interfaceId);
    }

    /// @notice Registers a DAO by its address
    /// @dev A name is unique within the Aragon DAO framework and can get stored here
    /// @param name The name of the DAO
    /// @param dao The address of the DAO contract
    /// @param creator The address of the creator
    function register(
        string calldata name,
        IDAO dao,
        address creator
    ) external auth(REGISTER_DAO_PERMISSION_ID) {
        // TODO: Implement ENS subdomain. Currently DAO's name can be repeated, will be resolved once the ENS subdomain is implemented.

        _register(address(dao));

        emit DAORegistered(dao, creator, name);
    }
}