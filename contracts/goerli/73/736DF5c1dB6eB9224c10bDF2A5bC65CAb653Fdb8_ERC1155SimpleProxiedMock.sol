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

import {AccessControlStorage} from "./../libraries/AccessControlStorage.sol";
import {ContractOwnershipStorage} from "./../libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title Access control via roles management (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract AccessControlBase is Context {
    using AccessControlStorage for AccessControlStorage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Emitted when a role is granted.
    /// @param role the granted role.
    /// @param account the account granted with the role.
    /// @param operator the initiator of the grant.
    event RoleGranted(bytes32 role, address account, address operator);

    /// @notice Emitted when a role is revoked or renounced.
    /// @param role the revoked or renounced role.
    /// @param account the account losing the role.
    /// @param operator the initiator of the revocation, or identical to `account` for a renouncement.
    event RoleRevoked(bytes32 role, address account, address operator);

    /// @notice Grants a role to an account.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    function grantRole(bytes32 role, address account) external {
        address operator = _msgSender();
        ContractOwnershipStorage.layout().enforceIsContractOwner(operator);
        AccessControlStorage.layout().grantRole(role, account, operator);
    }

    /// @notice Revokes a role from an account.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    function revokeRole(bytes32 role, address account) external {
        address operator = _msgSender();
        ContractOwnershipStorage.layout().enforceIsContractOwner(operator);
        AccessControlStorage.layout().revokeRole(role, account, operator);
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts if the sender does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param role The role to renounce.
    function renounceRole(bytes32 role) external {
        AccessControlStorage.layout().renounceRole(_msgSender(), role);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return AccessControlStorage.layout().hasRole(role, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC173} from "./../interfaces/IERC173.sol";
import {ContractOwnershipStorage} from "./../libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC173 Contract Ownership Standard (proxiable version).
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ContractOwnershipBase is Context, IERC173 {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @inheritdoc IERC173
    function owner() public view virtual override returns (address) {
        return ContractOwnershipStorage.layout().owner();
    }

    /// @inheritdoc IERC173
    function transferOwnership(address newOwner) public virtual override {
        ContractOwnershipStorage.layout().transferOwnership(_msgSender(), newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @notice Emitted when the contract ownership changes.
    /// @param previousOwner the previous contract owner.
    /// @param newOwner the new contract owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Sets the address of the new contract owner.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits an {OwnershipTransferred} event if `newOwner` is different from the current contract owner.
    /// @param newOwner The address of the new contract owner. Using the zero address means renouncing ownership.
    function transferOwnership(address newOwner) external;

    /// @notice Gets the address of the contract owner.
    /// @return contractOwner The address of the contract owner.
    function owner() external view returns (address contractOwner);
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
    function grantRole(
        Layout storage s,
        bytes32 role,
        address account,
        address operator
    ) internal {
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
    function revokeRole(
        Layout storage s,
        bytes32 role,
        address account,
        address operator
    ) internal {
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
    function renounceRole(
        Layout storage s,
        address sender,
        bytes32 role
    ) internal {
        s.enforceHasRole(role, sender);
        s.roles[role][sender] = false;
        emit RoleRevoked(role, sender, sender);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(
        Layout storage s,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return s.roles[role][account];
    }

    /// @notice Ensures that an account has a role.
    /// @dev Reverts if `account` does not have `role`.
    /// @param role The role.
    /// @param account The account.
    function enforceHasRole(
        Layout storage s,
        bytes32 role,
        address account
    ) internal view {
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

import {IERC173} from "./../interfaces/IERC173.sol";
import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../introspection/libraries/InterfaceDetectionStorage.sol";

library ContractOwnershipStorage {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        address contractOwner;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.ContractOwnership.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.core.access.ContractOwnership.phase")) - 1);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Initializes the storage with an initial contract owner (immutable version).
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner The initial contract owner.
    function constructorInit(Layout storage s, address initialOwner) internal {
        if (initialOwner != address(0)) {
            s.contractOwner = initialOwner;
            emit OwnershipTransferred(address(0), initialOwner);
        }
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC173).interfaceId, true);
    }

    /// @notice Initializes the storage with an initial contract owner (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner The initial contract owner.
    function proxyInit(Layout storage s, address initialOwner) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialOwner);
    }

    /// @notice Sets the address of the new contract owner.
    /// @dev Reverts if `sender` is not the contract owner.
    /// @dev Emits an {OwnershipTransferred} event if `newOwner` is different from the current contract owner.
    /// @param newOwner The address of the new contract owner. Using the zero address means renouncing ownership.
    function transferOwnership(
        Layout storage s,
        address sender,
        address newOwner
    ) internal {
        address previousOwner = s.contractOwner;
        require(sender == previousOwner, "Ownership: not the owner");
        if (previousOwner != newOwner) {
            s.contractOwner = newOwner;
            emit OwnershipTransferred(previousOwner, newOwner);
        }
    }

    /// @notice Gets the address of the contract owner.
    /// @return contractOwner The address of the contract owner.
    function owner(Layout storage s) internal view returns (address contractOwner) {
        return s.contractOwner;
    }

    /// @notice Ensures that an account is the contract owner.
    /// @dev Reverts if `account` is not the contract owner.
    /// @param account The account.
    function enforceIsContractOwner(Layout storage s, address account) internal view {
        require(account == s.contractOwner, "Ownership: not the owner");
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

import {IERC165} from "./interfaces/IERC165.sol";
import {InterfaceDetectionStorage} from "./libraries/InterfaceDetectionStorage.sol";

/// @title ERC165 Interface Detection Standard (immutable or proxiable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) or proxied implementation.
abstract contract InterfaceDetection is IERC165 {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return InterfaceDetectionStorage.layout().supportsInterface(interfaceId);
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
import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";

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
    function setSupportedInterface(
        Layout storage s,
        bytes4 interfaceId,
        bool supported
    ) internal {
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

import {IForwarderRegistry} from "./interfaces/IForwarderRegistry.sol";
import {IERC2771} from "./interfaces/IERC2771.sol";
import {ForwarderRegistryContextBase} from "./base/ForwarderRegistryContextBase.sol";

/// @title Meta-Transactions Forwarder Registry Context (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
abstract contract ForwarderRegistryContext is ForwarderRegistryContextBase, IERC2771 {
    constructor(IForwarderRegistry forwarderRegistry_) ForwarderRegistryContextBase(forwarderRegistry_) {}

    function forwarderRegistry() external view returns (IForwarderRegistry) {
        return _forwarderRegistry;
    }

    /// @inheritdoc IERC2771
    function isTrustedForwarder(address forwarder) external view virtual override returns (bool) {
        return forwarder == address(_forwarderRegistry);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";
import {ERC2771Data} from "./../libraries/ERC2771Data.sol";

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
        address msgSender = msg.sender;

        // Optimised path in case of an EOA-initiated direct transaction to the contract
        // solhint-disable-next-line avoid-tx-origin
        if (msgSender == tx.origin) {
            return msgSender;
        }

        address sender = ERC2771Data.msgSender();

        // Return the EIP-2771 calldata-appended sender address if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msgSender == address(_forwarderRegistry) || _forwarderRegistry.isForwarderFor(sender, msgSender)) {
            return sender;
        }

        return msgSender;
    }

    /// @notice Returns the message data depending on the ForwarderRegistry-based meta-transaction context.
    function _msgData() internal view virtual returns (bytes calldata) {
        address msgSender = msg.sender;

        // Optimised path in case of an EOA-initiated direct transaction to the contract
        // solhint-disable-next-line avoid-tx-origin
        if (msgSender == tx.origin) {
            return msg.data;
        }

        // Return the EIP-2771 calldata (minus the appended sender) if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msgSender == address(_forwarderRegistry) || _forwarderRegistry.isForwarderFor(ERC2771Data.msgSender(), msgSender)) {
            return ERC2771Data.msgData();
        }

        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Secure Protocol for Native Meta Transactions.
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
interface IERC2771 {
    /// @notice Checks whether a forwarder is trusted.
    /// @param forwarder The forwarder to check.
    /// @return isTrusted True if `forwarder` is trusted, false if not.
    function isTrustedForwarder(address forwarder) external view returns (bool isTrusted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as a meta-transaction forwarder for a signer account.
    /// @param forwarder The signer account.
    /// @param forwarder The forwarder account.
    /// @return isForwarder True if `forwarder` is a meta-transaction forwarder for `signer`, false otherwise.
    function isForwarderFor(address signer, address forwarder) external view returns (bool isForwarder);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT licence)
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
library ERC2771Data {
    /// @notice Returns the sender address appended at the end of the calldata, as specified in ERC2771.
    function msgSender() internal pure returns (address sender) {
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /// @notice Returns the calldata omitting the appended sender address, as specified in ERC2771.
    function msgData() internal pure returns (bytes calldata data) {
        return msg.data[:msg.data.length - 20];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IForwarderRegistry} from "./../../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC1155Storage} from "./../../../../token/ERC1155/libraries/ERC1155Storage.sol";
import {ContractOwnershipStorage} from "./../../../../access/libraries/ContractOwnershipStorage.sol";
import {ERC1155Base} from "./../../../../token/ERC1155/base/ERC1155Base.sol";
import {ERC1155MintableBase} from "./../../../../token/ERC1155/base/ERC1155MintableBase.sol";
import {ContractOwnershipBase} from "./../../../../access/base/ContractOwnershipBase.sol";
import {AccessControlBase} from "./../../../../access/base/AccessControlBase.sol";
import {InterfaceDetection} from "./../../../../introspection/InterfaceDetection.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../../metatx/base/ForwarderRegistryContextBase.sol";
import {ForwarderRegistryContext} from "./../../../../metatx/ForwarderRegistryContext.sol";

contract ERC1155SimpleProxiedMock is
    ERC1155Base,
    ERC1155MintableBase,
    ContractOwnershipBase,
    AccessControlBase,
    InterfaceDetection,
    ForwarderRegistryContext
{
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContext(forwarderRegistry) {}

    function init() public virtual {
        ContractOwnershipStorage.layout().proxyInit(_msgSender());
        ERC1155Storage.init();
        ERC1155Storage.initERC1155Mintable();
    }

    function __msgData() external view returns (bytes calldata) {
        return _msgData();
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

import {IERC1155} from "./../interfaces/IERC1155.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard, basic interface (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ERC1155Base is Context, IERC1155 {
    using ERC1155Storage for ERC1155Storage.Layout;

    /// @inheritdoc IERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override {
        ERC1155Storage.layout().safeTransferFrom(_msgSender(), from, to, id, value, data);
    }

    /// @inheritdoc IERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        ERC1155Storage.layout().safeBatchTransferFrom(_msgSender(), from, to, ids, values, data);
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) external virtual override {
        ERC1155Storage.layout().setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(address owner, address operator) external view override returns (bool approvedForAll) {
        return ERC1155Storage.layout().isApprovedForAll(owner, operator);
    }

    /// @inheritdoc IERC1155
    function balanceOf(address owner, uint256 id) external view virtual override returns (uint256 balance) {
        return ERC1155Storage.layout().balanceOf(owner, id);
    }

    /// @inheritdoc IERC1155
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory balances) {
        return ERC1155Storage.layout().balanceOfBatch(owners, ids);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155Mintable} from "./../interfaces/IERC1155Mintable.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Mintable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC1155MintableBase is Context, IERC1155Mintable {
    using ERC1155Storage for ERC1155Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant MINTER_ROLE = "minter";

    /// @inheritdoc IERC1155Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override {
        address sender = _msgSender();
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, sender);
        ERC1155Storage.layout().safeMint(sender, to, id, value, data);
    }

    /// @inheritdoc IERC1155Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        address sender = _msgSender();
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, sender);
        ERC1155Storage.layout().safeBatchMint(sender, to, ids, values, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, basic interface.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 {
    /// @notice Emitted when some token is transferred.
    /// @param operator The initiator of the transfer.
    /// @param from The previous token owner.
    /// @param to The new token owner.
    /// @param id The transferred token identifier.
    /// @param value The amount of token.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /// @notice Emitted when a batch of tokens is transferred.
    /// @param operator The initiator of the transfer.
    /// @param from The previous tokens owner.
    /// @param to The new tokens owner.
    /// @param ids The transferred tokens identifiers.
    /// @param values The amounts of tokens.
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /// @notice Emitted when an approval for all tokens is set or unset.
    /// @param owner The tokens owner.
    /// @param operator The approved address.
    /// @param approved True when then approval is set, false when it is unset.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted optionally when a token metadata URI is set.
    /// @param value The token metadata URI.
    /// @param id The token identifier.
    event URI(string value, uint256 indexed id);

    /// @notice Safely transfers some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Safely transfers a batch of tokens.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /// @notice Enables or disables an operator's approval.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator) external view returns (bool approved);

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance);

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts if `owners` and `ids` have different lengths.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x921ed8d1.
interface IERC1155Burnable {
    /// @notice Burns some token.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external;

    /// @notice Burns multiple tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Deliverable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0xe8ab9ccc.
interface IERC1155Deliverable {
    /// @notice Safely mints tokens to multiple recipients.
    /// @dev Reverts if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `recipients` balance overflows.
    /// @dev Reverts if one of `recipients` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event from the zero address for each transfer.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x0e89341c.
interface IERC1155MetadataURI {
    /// @notice Retrieves the URI for a given token.
    /// @dev URIs are defined in RFC 3986.
    /// @dev The URI MUST point to a JSON file that conforms to the "ERC1155 Metadata URI JSON Schema".
    /// @dev The uri function SHOULD be used to retrieve values if no event was emitted.
    /// @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
    /// @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
    ///  an implementation to return a valid string even if the token does not exist.
    /// @return metadataURI The URI associated to the token.
    function uri(uint256 id) external view returns (string memory metadataURI);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x5190c92c.
interface IERC1155Mintable {
    /// @notice Safely mints some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Safely mints a batch of tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, Tokens Receiver.
/// @notice Interface for any contract that wants to support transfers from ERC1155 asset contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
interface IERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC1155 token type.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
    /// @dev Return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (`0xf23a6e61`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param id The ID of the token being transferred
    /// @param value The amount of tokens being transferred
    /// @param data Additional data with no specified format
    /// @return magicValue `0xf23a6e61` to accept the transfer, or any other value to reject it.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4 magicValue);

    /// @notice Handles the receipt of multiple ERC1155 token types.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
    /// @dev Return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (`0xbc197c81`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the batch transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param ids An array containing ids of each token being transferred (order and length must match _values array)
    /// @param values An array containing amounts of each token being transferred (order and length must match _ids array)
    /// @param data Additional data with no specified format
    /// @return magicValue `0xbc197c81` to accept the transfer, or any other value to reject it.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155} from "./../interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {IERC1155Mintable} from "./../interfaces/IERC1155Mintable.sol";
import {IERC1155Deliverable} from "./../interfaces/IERC1155Deliverable.sol";
import {IERC1155Burnable} from "./../interfaces/IERC1155Burnable.sol";
import {IERC1155TokenReceiver} from "./../interfaces/IERC1155TokenReceiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC1155Storage {
    using Address for address;
    using ERC1155Storage for ERC1155Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operators;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC1155.ERC1155.storage")) - 1);

    bytes4 internal constant ERC1155_SINGLE_RECEIVED = IERC1155TokenReceiver.onERC1155Received.selector;
    bytes4 internal constant ERC1155_BATCH_RECEIVED = IERC1155TokenReceiver.onERC1155BatchReceived.selector;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155MetadataURI.
    function initERC1155MetadataURI() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155MetadataURI).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Mintable.
    function initERC1155Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Deliverable.
    function initERC1155Deliverable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Deliverable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Burnable.
    function initERC1155Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Burnable).interfaceId, true);
    }

    /// @notice Safely transfers some token by a sender.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(
        Layout storage s,
        address sender,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        _transferToken(s, from, to, id, value);

        emit TransferSingle(sender, from, to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, from, to, id, value, data);
        }
    }

    /// @notice Safely transfers a batch of tokens by a sender.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(
        Layout storage s,
        address sender,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");

        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _transferToken(s, from, to, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, from, to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, from, to, ids, values, data);
        }
    }

    /// @notice Safely mints some token by a sender.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(
        Layout storage s,
        address sender,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: mint to address(0)");

        _mintToken(s, to, id, value);

        emit TransferSingle(sender, address(0), to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, address(0), to, id, value, data);
        }
    }

    /// @notice Safely mints a batch of tokens by a sender.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(
        Layout storage s,
        address sender,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1155: mint to address(0)");
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _mintToken(s, to, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, address(0), to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, address(0), to, ids, values, data);
        }
    }

    /// @notice Safely mints tokens to multiple recipients by a sender.
    /// @dev Reverts if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `recipients` balance overflows.
    /// @dev Reverts if one of `recipients` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event from the zero address for each transfer.
    /// @param sender The message sender.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(
        Layout storage s,
        address sender,
        address[] memory recipients,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        uint256 length = recipients.length;
        require(length == ids.length && length == values.length, "ERC1155: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.safeMint(sender, recipients[i], ids[i], values[i], data);
            }
        }
    }

    /// @notice Burns some token by a sender.
    /// @dev Reverts `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(
        Layout storage s,
        address sender,
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");
        _burnToken(s, from, id, value);
        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @notice Burns multiple tokens by a sender.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(
        Layout storage s,
        address sender,
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) internal {
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _burnToken(s, from, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /// @notice Enables or disables an operator's approval by a sender.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param sender The message sender.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(
        Layout storage s,
        address sender,
        address operator,
        bool approved
    ) internal {
        require(operator != sender, "ERC1155: self-approval for all");
        s.operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(
        Layout storage s,
        address owner,
        address operator
    ) internal view returns (bool approved) {
        return s.operators[owner][operator];
    }

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(
        Layout storage s,
        address owner,
        uint256 id
    ) internal view returns (uint256 balance) {
        require(owner != address(0), "ERC1155: balance of address(0)");
        return s.balances[id][owner];
    }

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts if `owners` and `ids` have different lengths.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(
        Layout storage s,
        address[] memory owners,
        uint256[] memory ids
    ) internal view returns (uint256[] memory balances) {
        uint256 length = owners.length;
        require(length == ids.length, "ERC1155: inconsistent arrays");

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i; i != length; ++i) {
                balances[i] = s.balanceOf(owners[i], ids[i]);
            }
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Returns whether an account is authorised to make a transfer on behalf of an owner.
    /// @param owner The token owner.
    /// @param account The account to check the operatability of.
    /// @return operatable True if `account` is `owner` or is an operator for `owner`, false otherwise.
    function _isOperatable(
        Layout storage s,
        address owner,
        address account
    ) private view returns (bool operatable) {
        return (owner == account) || s.operators[owner][account];
    }

    function _transferToken(
        Layout storage s,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) private {
        if (value != 0) {
            unchecked {
                uint256 fromBalance = s.balances[id][from];
                uint256 newFromBalance = fromBalance - value;
                require(newFromBalance < fromBalance, "ERC1155: insufficient balance");
                if (from != to) {
                    uint256 toBalance = s.balances[id][to];
                    uint256 newToBalance = toBalance + value;
                    require(newToBalance > toBalance, "ERC1155: balance overflow");

                    s.balances[id][from] = newFromBalance;
                    s.balances[id][to] += newToBalance;
                }
            }
        }
    }

    function _mintToken(
        Layout storage s,
        address to,
        uint256 id,
        uint256 value
    ) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][to];
                uint256 newBalance = balance + value;
                require(newBalance > balance, "ERC1155: balance overflow");
                s.balances[id][to] = newBalance;
            }
        }
    }

    function _burnToken(
        Layout storage s,
        address from,
        uint256 id,
        uint256 value
    ) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][from];
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC1155: insufficient balance");
                s.balances[id][from] = newBalance;
            }
        }
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param id Identifier of the token transferred.
    /// @param value Value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155Received(
        address sender,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) private {
        require(IERC1155TokenReceiver(to).onERC1155Received(sender, from, id, value, data) == ERC1155_SINGLE_RECEIVED, "ERC1155: transfer rejected");
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155BatchReceived} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param ids Identifiers of the tokens transferred.
    /// @param values Values transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155BatchReceived(
        address sender,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(sender, from, ids, values, data) == ERC1155_BATCH_RECEIVED,
            "ERC1155: transfer rejected"
        );
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