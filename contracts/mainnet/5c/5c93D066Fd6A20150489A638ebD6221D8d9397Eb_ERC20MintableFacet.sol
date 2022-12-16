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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Bytes32} from "./../../utils/libraries/Bytes32.sol";

library AccessControlStorage {
    using Bytes32 for bytes32;
    using AccessControlStorage for AccessControlStorage.Layout;

    struct Layout {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.AccessControl.storage")) - 1);

    event RoleGranted(bytes32 role, address account, address operator);
    event RoleRevoked(bytes32 role, address account, address operator);

    /// @notice Grants a role to an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @param operator The account requesting the role change.
    function grantRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (!s.hasRole(role, account)) {
            s.roles[role][account] = true;
            emit RoleGranted(role, account, operator);
        }
    }

    /// @notice Revokes a role from an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @param operator The account requesting the role change.
    function revokeRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (s.hasRole(role, account)) {
            s.roles[role][account] = false;
            emit RoleRevoked(role, account, operator);
        }
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts if `sender` does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param sender The message sender.
    /// @param role The role to renounce.
    function renounceRole(Layout storage s, address sender, bytes32 role) internal {
        s.enforceHasRole(role, sender);
        s.roles[role][sender] = false;
        emit RoleRevoked(role, sender, sender);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(Layout storage s, bytes32 role, address account) internal view returns (bool) {
        return s.roles[role][account];
    }

    /// @notice Ensures that an account has a role.
    /// @dev Reverts if `account` does not have `role`.
    /// @param role The role.
    /// @param account The account.
    function enforceHasRole(Layout storage s, bytes32 role, address account) internal view {
        if (!s.hasRole(role, account)) {
            revert(string(abi.encodePacked("AccessControl: missing '", role.toASCIIString(), "' role")));
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC165 Interface Detection Standard.
/// @dev See https://eips.ethereum.org/EIPS/eip-165.
/// @dev Note: The ERC-165 identifier for this interface is 0x01ffc9a7.
interface IERC165 {
    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId the interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(bytes4 interfaceId) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC165} from "./../interfaces/IERC165.sol";

library InterfaceDetectionStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.introspection.InterfaceDetection.storage")) - 1);

    bytes4 internal constant ILLEGAL_INTERFACE_ID = 0xffffffff;

    /// @notice Sets or unsets an ERC165 interface.
    /// @dev Reverts if `interfaceId` is `0xffffffff`.
    /// @param interfaceId the interface identifier.
    /// @param supported True to set the interface, false to unset it.
    function setSupportedInterface(Layout storage s, bytes4 interfaceId, bool supported) internal {
        require(interfaceId != ILLEGAL_INTERFACE_ID, "InterfaceDetection: wrong value");
        s.supportedInterfaces[interfaceId] = supported;
    }

    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId The interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(Layout storage s, bytes4 interfaceId) internal view returns (bool supported) {
        if (interfaceId == ILLEGAL_INTERFACE_ID) {
            return false;
        }
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        return s.supportedInterfaces[interfaceId];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";
import {ERC2771Calldata} from "./../libraries/ERC2771Calldata.sol";

/// @title Meta-Transactions Forwarder Registry Context (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
abstract contract ForwarderRegistryContextBase {
    IForwarderRegistry internal immutable _forwarderRegistry;

    constructor(IForwarderRegistry forwarderRegistry) {
        _forwarderRegistry = forwarderRegistry;
    }

    /// @notice Returns the message sender depending on the ForwarderRegistry-based meta-transaction context.
    function _msgSender() internal view virtual returns (address) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.sender;
        }

        address sender = ERC2771Calldata.msgSender();

        // Return the EIP-2771 calldata-appended sender address if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_forwarderRegistry) || _forwarderRegistry.isApprovedForwarder(sender, msg.sender)) {
            return sender;
        }

        return msg.sender;
    }

    /// @notice Returns the message data depending on the ForwarderRegistry-based meta-transaction context.
    function _msgData() internal view virtual returns (bytes calldata) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.data;
        }

        // Return the EIP-2771 calldata (minus the appended sender) if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_forwarderRegistry) || _forwarderRegistry.isApprovedForwarder(ERC2771Calldata.msgSender(), msg.sender)) {
            return ERC2771Calldata.msgData();
        }

        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as an approved meta-transaction forwarder for a sender account.
    /// @param sender The sender account.
    /// @param forwarder The forwarder account.
    /// @return isApproved True if `forwarder` is an approved meta-transaction forwarder for `sender`, false otherwise.
    function isApprovedForwarder(address sender, address forwarder) external view returns (bool isApproved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT licence)
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
library ERC2771Calldata {
    /// @notice Returns the sender address appended at the end of the calldata, as specified in EIP-2771.
    function msgSender() internal pure returns (address sender) {
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /// @notice Returns the calldata while omitting the appended sender address, as specified in EIP-2771.
    function msgData() internal pure returns (bytes calldata data) {
        unchecked {
            return msg.data[:msg.data.length - 20];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ProxyInitialization} from "./ProxyInitialization.sol";

library ProxyAdminStorage {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    struct Layout {
        address admin;
    }

    // bytes32 public constant PROXYADMIN_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin.phase")) - 1);

    event AdminChanged(address previousAdmin, address newAdmin);

    /// @notice Initializes the storage with an initial admin (immutable version).
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Reverts if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function constructorInit(Layout storage s, address initialAdmin) internal {
        require(initialAdmin != address(0), "ProxyAdmin: no initial admin");
        s.admin = initialAdmin;
        emit AdminChanged(address(0), initialAdmin);
    }

    /// @notice Initializes the storage with an initial admin (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Reverts if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function proxyInit(Layout storage s, address initialAdmin) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialAdmin);
    }

    /// @notice Sets a new proxy admin.
    /// @dev Reverts if `sender` is not the proxy admin.
    /// @dev Emits an {AdminChanged} event if `newAdmin` is different from the current proxy admin.
    /// @param newAdmin The new proxy admin.
    function changeProxyAdmin(Layout storage s, address sender, address newAdmin) internal {
        address previousAdmin = s.admin;
        require(sender == previousAdmin, "ProxyAdmin: not the admin");
        if (previousAdmin != newAdmin) {
            s.admin = newAdmin;
            emit AdminChanged(previousAdmin, newAdmin);
        }
    }

    /// @notice Gets the proxy admin.
    /// @return admin The proxy admin
    function proxyAdmin(Layout storage s) internal view returns (address admin) {
        return s.admin;
    }

    /// @notice Ensures that an account is the proxy admin.
    /// @dev Reverts if `account` is not the proxy admin.
    /// @param account The account.
    function enforceIsProxyAdmin(Layout storage s, address account) internal view {
        require(account == s.admin, "ProxyAdmin: not the admin");
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice Multiple calls protection for storage-modifying proxy initialization functions.
library ProxyInitialization {
    /// @notice Sets the initialization phase during a storage-modifying proxy initialization function.
    /// @dev Reverts if `phase` has been reached already.
    /// @param storageSlot the storage slot where `phase` is stored.
    /// @param phase the initialization phase.
    function setPhase(bytes32 storageSlot, uint256 phase) internal {
        StorageSlot.Uint256Slot storage currentVersion = StorageSlot.getUint256Slot(storageSlot);
        require(currentVersion.value < phase, "Storage: phase reached");
        currentVersion.value = phase;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Mintable} from "./../interfaces/IERC20Mintable.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Mintable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC20MintableBase is Context, IERC20Mintable {
    using ERC20Storage for ERC20Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant MINTER_ROLE = "minter";

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function mint(address to, uint256 value) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC20Storage.layout().mint(to, value);
    }

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function batchMint(address[] calldata recipients, uint256[] calldata values) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC20Storage.layout().batchMint(recipients, values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC20MintableBase} from "./../base/ERC20MintableBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Mintable (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, {ContractOwnershipFacet}, {InterfaceDetectionFacet} and {AccessControlFacet}.
contract ERC20MintableFacet is ERC20MintableBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Mintable.
    /// @dev Reverts if the sender is not the proxy admin.
    function initERC20MintableStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC20Storage.initERC20Mintable();
    }

    /// @inheritdoc ForwarderRegistryContextBase
    function _msgSender() internal view virtual override(Context, ForwarderRegistryContextBase) returns (address) {
        return ForwarderRegistryContextBase._msgSender();
    }

    /// @inheritdoc ForwarderRegistryContextBase
    function _msgData() internal view virtual override(Context, ForwarderRegistryContextBase) returns (bytes calldata) {
        return ForwarderRegistryContextBase._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, basic interface.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
interface IERC20 {
    /// @notice Emitted when tokens are transferred, including zero value transfers.
    /// @param from The account where the transferred tokens are withdrawn from.
    /// @param to The account where the transferred tokens are deposited to.
    /// @param value The amount of tokens being transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when an approval is set.
    /// @param owner The account granting an allowance to `spender`.
    /// @param spender The account being granted an allowance from `owner`.
    /// @param value The allowance amount being granted.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Sets the allowance to an account from the sender.
    /// @notice Warning: Beware that changing an allowance with this method brings the risk that someone may use both the old and
    ///  the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce
    ///  the spender's allowance to 0 and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Emits an {Approval} event.
    /// @param spender The account being granted the allowance by the message caller.
    /// @param value The allowance amount to grant.
    /// @return result Whether the operation succeeded.
    function approve(address spender, uint256 value) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from the sender.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @return result Whether the operation succeeded.
    function transfer(address to, uint256 value) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from a specified address.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @return result Whether the operation succeeded.
    function transferFrom(address from, address to, uint256 value) external returns (bool result);

    /// @notice Gets the total token supply.
    /// @return supply The total token supply.
    function totalSupply() external view returns (uint256 supply);

    /// @notice Gets an account balance.
    /// @param owner The account whose balance will be returned.
    /// @return balance The account balance.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the amount that an account is allowed to spend on behalf of another.
    /// @param owner The account that has granted an allowance to `spender`.
    /// @param spender The account that was granted an allowance by `owner`.
    /// @return value The amount which `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Allowance.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x9d075186.
interface IERC20Allowance {
    /// @notice Increases the allowance granted to an account by the sender.
    /// @notice This is an alternative to {approve} that can be used as a mitigation for transaction ordering problems.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender`'s allowance by the sender overflows.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by the sender.
    /// @param spender The account whose allowance is being increased.
    /// @param value The allowance amount increase.
    /// @return result Whether the operation succeeded.
    function increaseAllowance(address spender, uint256 value) external returns (bool result);

    /// @notice Decreases the allowance granted to an account by the sender.
    /// @notice This is an alternative to {approve} that can be used as a mitigation for transaction ordering problems.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender` does not have at least `value` of allowance by the sender.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by the sender.
    /// @param spender The account whose allowance is being decreased.
    /// @param value The allowance amount decrease.
    /// @return result Whether the operation succeeded.
    function decreaseAllowance(address spender, uint256 value) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Batch Transfers.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0xc05327e6.
interface IERC20BatchTransfers {
    /// @notice Transfers multiple amounts of tokens to multiple recipients from the sender.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the sender does not have at least `sum(values)` of balance.
    /// @dev Emits an {IERC20-Transfer} event for each transfer.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    /// @return result Whether the operation succeeded.
    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external returns (bool result);

    /// @notice Transfers multiple amounts of tokens to multiple recipients from a specified address.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `sum(values)` of allowance by `from`.
    /// @dev Emits an {IERC20-Transfer} event for each transfer.
    /// @dev Optionally emits an {IERC20-Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to be transferred.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    /// @return result Whether the operation succeeded.
    function batchTransferFrom(address from, address[] calldata recipients, uint256[] calldata values) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x3b5a0bf8.
interface IERC20Burnable {
    /// @notice Burns an amount of tokens from the sender, decreasing the total supply.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Emits an {IERC20-Transfer} event with `to` set to the zero address.
    /// @param value The amount of tokens to burn.
    /// @return result Whether the operation succeeded.
    function burn(uint256 value) external returns (bool result);

    /// @notice Burns an amount of tokens from a specified address, decreasing the total supply.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits an {IERC20-Transfer} event with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event if the sender is not `from` (non-standard).
    /// @param from The account to burn the tokens from.
    /// @param value The amount of tokens to burn.
    /// @return result Whether the operation succeeded.
    function burnFrom(address from, uint256 value) external returns (bool result);

    /// @notice Burns multiple amounts of tokens from multiple owners, decreasing the total supply.
    /// @dev Reverts if `owners` and `values` have different lengths.
    /// @dev Reverts if an `owner` does not have at least the corresponding `value` of balance.
    /// @dev Reverts if the sender is not an `owner` and does not have at least the corresponding `value` of allowance by this `owner`.
    /// @dev Emits an {IERC20-Transfer} event for each transfer with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event for each transfer if the sender is not this `owner` (non-standard).
    /// @param owners The list of accounts to burn the tokens from.
    /// @param values The list of amounts of tokens to burn.
    /// @return result Whether the operation succeeded.
    function batchBurnFrom(address[] calldata owners, uint256[] calldata values) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x28963e1e.
interface IERC20Mintable {
    /// @notice Mints an amount of tokens to a recipient, increasing the total supply.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits an {IERC20-Transfer} event with `from` set to the zero address.
    /// @param to The account to mint the tokens to.
    /// @param value The amount of tokens to mint.
    function mint(address to, uint256 value) external;

    /// @notice Mints multiple amounts of tokens to multiple recipients, increasing the total supply.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits an {IERC20-Transfer} event for each transfer with `from` set to the zero address.
    /// @param recipients The list of accounts to mint the tokens to.
    /// @param values The list of amounts of tokens to mint to each of `recipients`.
    function batchMint(address[] calldata recipients, uint256[] calldata values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, Tokens Receiver.
/// @notice Interface for supporting safe transfers from ERC20 contracts with the Safe Transfers extension.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x4fc35859.
interface IERC20Receiver {
    /// @notice Handles the receipt of ERC20 tokens.
    /// @dev Note: this function is called by an {ERC20SafeTransfer} contract after a safe transfer.
    /// @param operator The initiator of the safe transfer.
    /// @param from The previous tokens owner.
    /// @param value The amount of tokens transferred.
    /// @param data Optional additional data with no specified format.
    /// @return magicValue `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` (`0x4fc35859`) to accept, any other value to refuse.
    function onERC20Received(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Safe Transfers.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x53f41a97.
interface IERC20SafeTransfers {
    /// @notice Transfers an amount of tokens to a recipient from the sender. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received` fails, reverts or is rejected.
    /// @dev Emits an {IERC20-Transfer} event.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    /// @return result Whether the operation succeeded.
    function safeTransfer(address to, uint256 value, bytes calldata data) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from a specified address. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` fails, reverts or is rejected.
    /// @dev Emits an {IERC20-Transfer} event.
    /// @dev Optionally emits an {IERC20-Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    /// @return result Whether the operation succeeded.
    function safeTransferFrom(address from, address to, uint256 value, bytes calldata data) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "./../interfaces/IERC20.sol";
import {IERC20Allowance} from "./../interfaces/IERC20Allowance.sol";
import {IERC20BatchTransfers} from "./../interfaces/IERC20BatchTransfers.sol";
import {IERC20SafeTransfers} from "./../interfaces/IERC20SafeTransfers.sol";
import {IERC20Mintable} from "./../interfaces/IERC20Mintable.sol";
import {IERC20Burnable} from "./../interfaces/IERC20Burnable.sol";
import {IERC20Receiver} from "./../interfaces/IERC20Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC20Storage {
    using Address for address;
    using ERC20Storage for ERC20Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 supply;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20.storage")) - 1);

    bytes4 internal constant ERC20_RECEIVED = IERC20Receiver.onERC20Received.selector;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20, ERC20Allowance.
    function init() internal {
        InterfaceDetectionStorage.Layout storage erc165Layout = InterfaceDetectionStorage.layout();
        erc165Layout.setSupportedInterface(type(IERC20).interfaceId, true);
        erc165Layout.setSupportedInterface(type(IERC20Allowance).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20BatchTransfers.
    function initERC20BatchTransfers() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20BatchTransfers).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20SafeTransfers.
    function initERC20SafeTransfers() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20SafeTransfers).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Mintable.
    function initERC20Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Burnable.
    function initERC20Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Burnable).interfaceId, true);
    }

    /// @notice Sets the allowance to an account by an owner.
    /// @dev Note: This function implements {ERC20-approve(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Emits an {Approval} event.
    /// @param owner The account to set the allowance from.
    /// @param spender The account being granted the allowance by `owner`.
    /// @param value The allowance amount to grant.
    function approve(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        s.allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @notice Increases the allowance granted to an account by an owner.
    /// @dev Note: This function implements {ERC20Allowance-increaseAllowance(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender`'s allowance by `owner` overflows.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by `owner`.
    /// @param owner The account increasing the allowance.
    /// @param spender The account whose allowance is being increased.
    /// @param value The allowance amount increase.
    function increaseAllowance(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        uint256 allowance_ = s.allowances[owner][spender];
        if (value != 0) {
            unchecked {
                uint256 newAllowance = allowance_ + value;
                require(newAllowance > allowance_, "ERC20: allowance overflow");
                s.allowances[owner][spender] = newAllowance;
                allowance_ = newAllowance;
            }
        }
        emit Approval(owner, spender, allowance_);
    }

    /// @notice Decreases the allowance granted to an account by an owner.
    /// @dev Note: This function implements {ERC20Allowance-decreaseAllowance(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender` does not have at least `value` of allowance by `owner`.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by `owner`.
    /// @param owner The account decreasing the allowance.
    /// @param spender The account whose allowance is being decreased.
    /// @param value The allowance amount decrease.
    function decreaseAllowance(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        uint256 allowance_ = s.allowances[owner][spender];

        if (allowance_ != type(uint256).max && value != 0) {
            unchecked {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                uint256 newAllowance = allowance_ - value;
                require(newAllowance < allowance_, "ERC20: insufficient allowance");
                s.allowances[owner][spender] = newAllowance;
                allowance_ = newAllowance;
            }
        }
        emit Approval(owner, spender, allowance_);
    }

    /// @notice Transfers an amount of tokens from an account to a recipient.
    /// @dev Note: This function implements {ERC20-transfer(address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    function transfer(Layout storage s, address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to address(0)");

        if (value != 0) {
            uint256 balance = s.balances[from];
            unchecked {
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                if (from != to) {
                    s.balances[from] = newBalance;
                    s.balances[to] += value;
                }
            }
        }

        emit Transfer(from, to, value);
    }

    /// @notice Transfers an amount of tokens from an account to a recipient by a sender.
    /// @dev Note: This function implements {ERC20-transferFrom(address,address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from`.
    /// @param sender The message sender.
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    function transferFrom(Layout storage s, address sender, address from, address to, uint256 value) internal {
        if (from != sender) {
            s.decreaseAllowance(from, sender, value);
        }
        s.transfer(from, to, value);
    }

    //================================================= Batch Transfers ==================================================//

    /// @notice Transfers multiple amounts of tokens from an account to multiple recipients.
    /// @dev Note: This function implements {ERC20BatchTransfers-batchTransfer(address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Emits a {Transfer} event for each transfer.
    /// @param from The account transferring the tokens.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    function batchTransfer(Layout storage s, address from, address[] calldata recipients, uint256[] calldata values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 balance = s.balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: transfer to address(0)");

                uint256 value = values[i];
                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    if (from != to) {
                        s.balances[to] += value;
                    } else {
                        require(value <= balance, "ERC20: insufficient balance");
                        selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                    }
                }
                emit Transfer(from, to, value);
            }

            if (totalValue != 0 && totalValue != selfTransferTotalValue) {
                uint256 newBalance = balance - totalValue;
                require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
                s.balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
            }
        }
    }

    /// @notice Transfers multiple amounts of tokens from an account to multiple recipients by a sender.
    /// @dev Note: This function implements {ERC20BatchTransfers-batchTransferFrom(address,address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `sum(values)` of allowance by `from`.
    /// @dev Emits a {Transfer} event for each transfer.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account transferring the tokens.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    function batchTransferFrom(Layout storage s, address sender, address from, address[] calldata recipients, uint256[] calldata values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 balance = s.balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: transfer to address(0)");

                uint256 value = values[i];

                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    if (from != to) {
                        s.balances[to] += value;
                    } else {
                        require(value <= balance, "ERC20: insufficient balance");
                        selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                    }
                }

                emit Transfer(from, to, value);
            }

            if (totalValue != 0 && totalValue != selfTransferTotalValue) {
                uint256 newBalance = balance - totalValue;
                require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
                s.balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
            }
        }

        if (from != sender) {
            s.decreaseAllowance(from, sender, totalValue);
        }
    }

    //================================================= Safe Transfers ==================================================//

    /// @notice Transfers an amount of tokens from an account to a recipient. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Note: This function implements {ERC20SafeTransfers-safeTransfer(address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received` fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    function safeTransfer(Layout storage s, address from, address to, uint256 value, bytes calldata data) internal {
        s.transfer(from, to, value);
        if (to.isContract()) {
            _callOnERC20Received(from, from, to, value, data);
        }
    }

    /// @notice Transfers an amount of tokens to a recipient from a specified address. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Note: This function implements {ERC20SafeTransfers-safeTransferFrom(address,address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 value, bytes calldata data) internal {
        s.transferFrom(sender, from, to, value);
        if (to.isContract()) {
            _callOnERC20Received(sender, from, to, value, data);
        }
    }

    //================================================= Minting ==================================================//

    /// @notice Mints an amount of tokens to a recipient, increasing the total supply.
    /// @dev Note: This function implements {ERC20Mintable-mint(address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits a {Transfer} event with `from` set to the zero address.
    /// @param to The account to mint the tokens to.
    /// @param value The amount of tokens to mint.
    function mint(Layout storage s, address to, uint256 value) internal {
        require(to != address(0), "ERC20: mint to address(0)");
        if (value != 0) {
            uint256 supply = s.supply;
            unchecked {
                uint256 newSupply = supply + value;
                require(newSupply > supply, "ERC20: supply overflow");
                s.supply = newSupply;
                s.balances[to] += value; // balance cannot overflow if supply does not
            }
        }
        emit Transfer(address(0), to, value);
    }

    /// @notice Mints multiple amounts of tokens to multiple recipients, increasing the total supply.
    /// @dev Note: This function implements {ERC20Mintable-batchMint(address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits a {Transfer} event for each transfer with `from` set to the zero address.
    /// @param recipients The list of accounts to mint the tokens to.
    /// @param values The list of amounts of tokens to mint to each of `recipients`.
    function batchMint(Layout storage s, address[] memory recipients, uint256[] memory values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 totalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: mint to address(0)");

                uint256 value = values[i];
                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    s.balances[to] += value; // balance cannot overflow if supply does not
                }
                emit Transfer(address(0), to, value);
            }

            if (totalValue != 0) {
                uint256 supply = s.supply;
                uint256 newSupply = supply + totalValue;
                require(newSupply > supply, "ERC20: supply overflow");
                s.supply = newSupply;
            }
        }
    }

    //================================================= Burning ==================================================//

    /// @notice Burns an amount of tokens from an account, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-burn(uint256)}.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @param from The account burning the tokens.
    /// @param value The amount of tokens to burn.
    function burn(Layout storage s, address from, uint256 value) internal {
        if (value != 0) {
            uint256 balance = s.balances[from];
            unchecked {
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                s.balances[from] = newBalance;
                s.supply -= value; // will not underflow if balance does not
            }
        }

        emit Transfer(from, address(0), value);
    }

    /// @notice Burns an amount of tokens from an account by a sender, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-burnFrom(address,uint256)}.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account to burn the tokens from.
    /// @param value The amount of tokens to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 value) internal {
        if (from != sender) {
            s.decreaseAllowance(from, sender, value);
        }
        s.burn(from, value);
    }

    /// @notice Burns multiple amounts of tokens from multiple owners, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-batchBurnFrom(address,address[],uint256[])}.
    /// @dev Reverts if `owners` and `values` have different lengths.
    /// @dev Reverts if an `owner` does not have at least the corresponding `value` of balance.
    /// @dev Reverts if `sender` is not an `owner` and does not have at least the corresponding `value` of allowance by this `owner`.
    /// @dev Emits a {Transfer} event for each transfer with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event for each transfer if `sender` is not this `owner` (non-standard).
    /// @param sender The message sender.
    /// @param owners The list of accounts to burn the tokens from.
    /// @param values The list of amounts of tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address[] calldata owners, uint256[] calldata values) internal {
        uint256 length = owners.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 totalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address from = owners[i];
                uint256 value = values[i];

                if (from != sender) {
                    s.decreaseAllowance(from, sender, value);
                }

                if (value != 0) {
                    uint256 balance = s.balances[from];
                    uint256 newBalance = balance - value;
                    require(newBalance < balance, "ERC20: insufficient balance");
                    s.balances[from] = newBalance;
                    totalValue += value; // totalValue cannot overflow if the individual balances do not underflow
                }

                emit Transfer(from, address(0), value);
            }

            if (totalValue != 0) {
                s.supply -= totalValue; // _totalSupply cannot underfow as balances do not underflow
            }
        }
    }

    /// @notice Gets the total token supply.
    /// @dev Note: This function implements {ERC20-totalSupply()}.
    /// @return supply The total token supply.
    function totalSupply(Layout storage s) internal view returns (uint256 supply) {
        return s.supply;
    }

    /// @notice Gets an account balance.
    /// @dev Note: This function implements {ERC20-balanceOf(address)}.
    /// @param owner The account whose balance will be returned.
    /// @return balance The account balance.
    function balanceOf(Layout storage s, address owner) internal view returns (uint256 balance) {
        return s.balances[owner];
    }

    /// @notice Gets the amount that an account is allowed to spend on behalf of another.
    /// @dev Note: This function implements {ERC20-allowance(address,address)}.
    /// @param owner The account that has granted an allowance to `spender`.
    /// @param spender The account that was granted an allowance by `owner`.
    /// @return value The amount which `spender` is allowed to spend on behalf of `owner`.
    function allowance(Layout storage s, address owner, address spender) internal view returns (uint256 value) {
        return s.allowances[owner][spender];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Calls {IERC20Receiver-onERC20Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param value The value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC20Received(address sender, address from, address to, uint256 value, bytes memory data) private {
        require(IERC20Receiver(to).onERC20Received(sender, from, value, data) == ERC20_RECEIVED, "ERC20: safe transfer rejected");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Bytes32 {
    /// @notice Converts bytes32 to base32 string.
    /// @param value value to convert.
    /// @return the converted base32 string.
    function toBase32String(bytes32 value) internal pure returns (string memory) {
        unchecked {
            bytes32 base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;
            uint256 i = uint256(value);
            uint256 k = 52;
            bytes memory bstr = new bytes(k);
            bstr[--k] = base32Alphabet[uint8((i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (i % (2**s)) << (5-s)
            i /= 8;
            while (k > 0) {
                bstr[--k] = base32Alphabet[i % 32];
                i /= 32;
            }
            return string(bstr);
        }
    }

    /// @notice Converts a bytes32 value to an ASCII string, trimming the tailing zeros.
    /// @param value value to convert.
    /// @return the converted ASCII string.
    function toASCIIString(bytes32 value) internal pure returns (string memory) {
        unchecked {
            if (value == 0x00) return "";
            bytes memory bytesString = bytes(abi.encodePacked(value));
            uint256 pos = 31;
            while (true) {
                if (bytesString[pos] != 0) break;
                --pos;
            }
            bytes memory asciiString = new bytes(pos + 1);
            for (uint256 i; i <= pos; ++i) {
                asciiString[i] = bytesString[i];
            }
            return string(asciiString);
        }
    }
}