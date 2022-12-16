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

import {IERC721Deliverable} from "./../interfaces/IERC721Deliverable.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Deliverable (proxiable version).
/// @notice ERC721Deliverable implementation where burnt tokens can be minted again.
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC721DeliverableBase is Context, IERC721Deliverable {
    using ERC721Storage for ERC721Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    // prevent variable name clash with public ERC721MintableBase.MINTER_ROLE
    bytes32 private constant _MINTER_ROLE = "minter";

    /// @inheritdoc IERC721Deliverable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function deliver(address[] calldata recipients, uint256[] calldata tokenIds) external virtual override {
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, _msgSender());
        ERC721Storage.layout().deliver(recipients, tokenIds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC721DeliverableBase} from "./../base/ERC721DeliverableBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Deliverable (facet version).
/// @notice ERC721Deliverable implementation where burnt tokens can be minted again.
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, {InterfaceDetectionFacet} and {AccessControlFacet}.
contract ERC721DeliverableFacet is ERC721DeliverableBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Deliverable.
    /// @dev Reverts if the sender is not the proxy admin.
    function initERC721DeliverableStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC721Storage.initERC721Deliverable();
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

/// @title ERC721 Non-Fungible Token Standard, basic interface (functions).
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev This interface only contains the standard functions. See IERC721Events for the events.
/// @dev Note: The ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 {
    /// @notice Sets or unsets an approval to transfer a single token on behalf of its owner.
    /// @dev Note: There can only be one approved address per token at a given time.
    /// @dev Note: A token approval gets reset when this token is transferred, including a self-transfer.
    /// @dev Reverts if `tokenId` does not exist.
    /// @dev Reverts if `to` is the token owner.
    /// @dev Reverts if the sender is not the token owner and has not been approved by the token owner.
    /// @dev Emits an {Approval} event.
    /// @param to The address to approve, or the zero address to remove any existing approval.
    /// @param tokenId The token identifier to give approval for.
    function approve(address to, uint256 tokenId) external;

    /// @notice Sets or unsets an approval to transfer all tokens on behalf of their owner.
    /// @dev Reverts if the sender is the same as `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator The address to approve for all tokens.
    /// @param approved True to set an approval for all tokens, false to unset it.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Unsafely transfers the ownership of a token to a recipient.
    /// @dev Note: Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer. Self-transfers are possible.
    /// @param tokenId The identifier of the token to transfer.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Gets the balance of an address.
    /// @dev Reverts if `owner` is the zero address.
    /// @param owner The address to query the balance of.
    /// @return balance The amount owned by the owner.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the owner of a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the owner of.
    /// @return tokenOwner The owner of the token identifier.
    function ownerOf(uint256 tokenId) external view returns (address tokenOwner);

    /// @notice Gets the approved address for a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the approval of.
    /// @return approved The approved address for the token identifier, or the zero address if no approval is set.
    function getApproved(uint256 tokenId) external view returns (address approved);

    /// @notice Gets whether an operator is approved for all tokens by an owner.
    /// @param owner The address which gives the approval for all tokens.
    /// @param operator The address which receives the approval for all tokens.
    /// @return approvedForAll Whether the operator is approved for all tokens by the owner.
    function isApprovedForAll(address owner, address operator) external view returns (bool approvedForAll);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Batch Transfer.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0xf3993d11.
interface IERC721BatchTransfer {
    /// @notice Unsafely transfers a batch of tokens to a recipient.
    /// @dev Resets the token approval for each of `tokenIds`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits an {IERC721-Transfer} event for each of `tokenIds`.
    /// @param from Current tokens owner.
    /// @param to Address of the new token owner.
    /// @param tokenIds Identifiers of the tokens to transfer.
    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x8b8b4ef5.
interface IERC721Burnable {
    /// @notice Burns a token.
    /// @dev Reverts if `tokenId` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits an {IERC721-Transfer} event with `to` set to the zero address.
    /// @param from The current token owner.
    /// @param tokenId The identifier of the token to burn.
    function burnFrom(address from, uint256 tokenId) external;

    /// @notice Burns a batch of tokens.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits an {IERC721-Transfer} event with `to` set to the zero address for each of `tokenIds`.
    /// @param from The current tokens owner.
    /// @param tokenIds The identifiers of the tokens to burn.
    function batchBurnFrom(address from, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Deliverable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x9da5e832.
interface IERC721Deliverable {
    /// @notice Unsafely mints tokens to multiple recipients.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliver(address[] calldata recipients, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x8e773e13.
interface IERC721Mintable {
    /// @notice Unsafely mints a token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mint(address to, uint256 tokenId) external;

    /// @notice Safely mints a token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC721-Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMint(address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Unsafely mints a batch of tokens.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMint(address to, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, Tokens Receiver.
/// @notice Interface for supporting safe transfers from ERC721 contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handles the receipt of an ERC721 token.
    /// @dev Note: This function is called by an ERC721 contract after a safe transfer.
    /// @dev Note: The ERC721 contract address is always the message sender.
    /// @param operator The initiator of the safe transfer.
    /// @param from The previous token owner.
    /// @param tokenId The token identifier.
    /// @param data Optional additional data with no specified format.
    /// @return magicValue `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` (`0x150b7a02`) to accept, any other value to refuse.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721} from "./../interfaces/IERC721.sol";
import {IERC721BatchTransfer} from "./../interfaces/IERC721BatchTransfer.sol";
import {IERC721Mintable} from "./../interfaces/IERC721Mintable.sol";
import {IERC721Deliverable} from "./../interfaces/IERC721Deliverable.sol";
import {IERC721Burnable} from "./../interfaces/IERC721Burnable.sol";
import {IERC721Receiver} from "./../interfaces/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC721Storage {
    using Address for address;
    using ERC721Storage for ERC721Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(uint256 => uint256) owners;
        mapping(address => uint256) balances;
        mapping(uint256 => address) approvals;
        mapping(address => mapping(address => bool)) operators;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC721.ERC721.storage")) - 1);

    bytes4 internal constant ERC721_RECEIVED = IERC721Receiver.onERC721Received.selector;

    // Single token approval flag
    // This bit is set in the owner's value to indicate that there is an approval set for this token
    uint256 internal constant TOKEN_APPROVAL_OWNER_FLAG = 1 << 160;

    // Burnt token magic value
    // This magic number is used as the owner's value to indicate that the token has been burnt
    uint256 internal constant BURNT_TOKEN_OWNER_VALUE = 0xdead000000000000000000000000000000000000000000000000000000000000;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721BatchTransfer.
    function initERC721BatchTransfer() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721BatchTransfer).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Mintable.
    function initERC721Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Deliverable.
    function initERC721Deliverable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Deliverable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Burnable.
    function initERC721Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Burnable).interfaceId, true);
    }

    /// @notice Sets or unsets an approval to transfer a single token on behalf of its owner.
    /// @dev Note: This function implements {ERC721-approve(address,uint256)}.
    /// @dev Reverts if `tokenId` does not exist.
    /// @dev Reverts if `to` is the token owner.
    /// @dev Reverts if `sender` is not the token owner and has not been approved by the token owner.
    /// @dev Emits an {Approval} event.
    /// @param sender The message sender.
    /// @param to The address to approve, or the zero address to remove any existing approval.
    /// @param tokenId The token identifier to give approval for.
    function approve(Layout storage s, address sender, address to, uint256 tokenId) internal {
        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        address ownerAddress = _tokenOwner(owner);
        require(to != ownerAddress, "ERC721: self-approval");
        require(_isOperatable(s, ownerAddress, sender), "ERC721: non-approved sender");
        if (to == address(0)) {
            if (_tokenHasApproval(owner)) {
                // remove the approval bit if it is present
                s.owners[tokenId] = uint256(uint160(ownerAddress));
            }
        } else {
            uint256 ownerWithApprovalBit = owner | TOKEN_APPROVAL_OWNER_FLAG;
            if (owner != ownerWithApprovalBit) {
                // add the approval bit if it is not present
                s.owners[tokenId] = ownerWithApprovalBit;
            }
            s.approvals[tokenId] = to;
        }
        emit Approval(ownerAddress, to, tokenId);
    }

    /// @notice Sets or unsets an approval to transfer all tokens on behalf of their owner.
    /// @dev Note: This function implements {ERC721-setApprovalForAll(address,bool)}.
    /// @dev Reverts if `sender` is the same as `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param sender The message sender.
    /// @param operator The address to approve for all tokens.
    /// @param approved True to set an approval for all tokens, false to unset it.
    function setApprovalForAll(Layout storage s, address sender, address operator, bool approved) internal {
        require(operator != sender, "ERC721: self-approval for all");
        s.operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Unsafely transfers the ownership of a token to a recipient by a sender.
    /// @dev Note: This function implements {ERC721-transferFrom(address,address,uint256)}.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function transferFrom(Layout storage s, address sender, address from, address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: transfer to address(0)");

        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        require(_tokenOwner(owner) == from, "ERC721: non-owned token");

        if (!_isOperatable(s, from, sender)) {
            require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
        }

        s.owners[tokenId] = uint256(uint160(to));
        if (from != to) {
            unchecked {
                // cannot underflow as balance is verified through ownership
                --s.balances[from];
                //  cannot overflow as supply cannot overflow
                ++s.balances[to];
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /// @notice Safely transfers the ownership of a token to a recipient by a sender.
    /// @dev Note: This function implements {ERC721-safeTransferFrom(address,address,uint256)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 tokenId) internal {
        s.transferFrom(sender, from, to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, from, to, tokenId, "");
        }
    }

    /// @notice Safely transfers the ownership of a token to a recipient by a sender.
    /// @dev Note: This function implements {ERC721-safeTransferFrom(address,address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 tokenId, bytes calldata data) internal {
        s.transferFrom(sender, from, to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, from, to, tokenId, data);
        }
    }

    /// @notice Unsafely transfers a batch of tokens to a recipient by a sender.
    /// @dev Note: This function implements {ERC721BatchTransfer-batchTransferFrom(address,address,uint256[])}.
    /// @dev Resets the token approval for each of `tokenIds`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits a {Transfer} event for each of `tokenIds`.
    /// @param sender The message sender.
    /// @param from Current tokens owner.
    /// @param to Address of the new token owner.
    /// @param tokenIds Identifiers of the tokens to transfer.
    function batchTransferFrom(Layout storage s, address sender, address from, address to, uint256[] calldata tokenIds) internal {
        require(to != address(0), "ERC721: transfer to address(0)");
        bool operatable = _isOperatable(s, from, sender);

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(_tokenExists(owner), "ERC721: non-existing token");
                require(_tokenOwner(owner) == from, "ERC721: non-owned token");
                if (!operatable) {
                    require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
                }
                s.owners[tokenId] = uint256(uint160(to));
                emit Transfer(from, to, tokenId);
            }

            if (from != to && length != 0) {
                // cannot underflow as balance is verified through ownership
                s.balances[from] -= length;
                // cannot overflow as supply cannot overflow
                s.balances[to] += length;
            }
        }
    }

    /// @notice Unsafely mints a token.
    /// @dev Note: This function implements {ERC721Mintable-mint(address,uint256)}.
    /// @dev Note: Either `mint` or `mintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mint(Layout storage s, address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to address(0)");
        require(!_tokenExists(s.owners[tokenId]), "ERC721: existing token");

        s.owners[tokenId] = uint256(uint160(to));

        unchecked {
            // cannot overflow due to the cost of minting individual tokens
            ++s.balances[to];
        }

        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Safely mints a token.
    /// @dev Note: This function implements {ERC721Mintable-safeMint(address,uint256,bytes)}.
    /// @dev Note: Either `safeMint` or `safeMintOnce` should be used in a given contract, but not both.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMint(Layout storage s, address sender, address to, uint256 tokenId, bytes memory data) internal {
        s.mint(to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, address(0), to, tokenId, data);
        }
    }

    /// @notice Unsafely mints a batch of tokens.
    /// @dev Note: This function implements {ERC721Mintable-batchMint(address,uint256[])}.
    /// @dev Note: Either `batchMint` or `batchMintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits a {Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMint(Layout storage s, address to, uint256[] memory tokenIds) internal {
        require(to != address(0), "ERC721: mint to address(0)");

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                require(!_tokenExists(s.owners[tokenId]), "ERC721: existing token");

                s.owners[tokenId] = uint256(uint160(to));
                emit Transfer(address(0), to, tokenId);
            }

            s.balances[to] += length;
        }
    }

    /// @notice Unsafely mints tokens to multiple recipients.
    /// @dev Note: This function implements {ERC721Deliverable-deliver(address[],uint256[])}.
    /// @dev Note: Either `deliver` or `deliverOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits a {Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliver(Layout storage s, address[] memory recipients, uint256[] memory tokenIds) internal {
        uint256 length = recipients.length;
        require(length == tokenIds.length, "ERC721: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.mint(recipients[i], tokenIds[i]);
            }
        }
    }

    /// @notice Unsafely mints a token once.
    /// @dev Note: This function implements {ERC721Mintable-mint(address,uint256)}.
    /// @dev Note: Either `mint` or `mintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `tokenId` has been previously burnt.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mintOnce(Layout storage s, address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to address(0)");

        uint256 owner = s.owners[tokenId];
        require(!_tokenExists(owner), "ERC721: existing token");
        require(!_tokenWasBurnt(owner), "ERC721: burnt token");

        s.owners[tokenId] = uint256(uint160(to));

        unchecked {
            // cannot overflow due to the cost of minting individual tokens
            ++s.balances[to];
        }

        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Safely mints a token once.
    /// @dev Note: This function implements {ERC721Mintable-safeMint(address,uint256,bytes)}.
    /// @dev Note: Either `safeMint` or `safeMintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `tokenId` has been previously burnt.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMintOnce(Layout storage s, address sender, address to, uint256 tokenId, bytes memory data) internal {
        s.mintOnce(to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, address(0), to, tokenId, data);
        }
    }

    /// @notice Unsafely mints a batch of tokens once.
    /// @dev Note: This function implements {ERC721Mintable-batchMint(address,uint256[])}.
    /// @dev Note: Either `batchMint` or `batchMintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Reverts if one of `tokenIds` has been previously burnt.
    /// @dev Emits a {Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMintOnce(Layout storage s, address to, uint256[] memory tokenIds) internal {
        require(to != address(0), "ERC721: mint to address(0)");

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(!_tokenExists(owner), "ERC721: existing token");
                require(!_tokenWasBurnt(owner), "ERC721: burnt token");

                s.owners[tokenId] = uint256(uint160(to));

                emit Transfer(address(0), to, tokenId);
            }

            s.balances[to] += length;
        }
    }

    /// @notice Unsafely mints tokens to multiple recipients once.
    /// @dev Note: This function implements {ERC721Deliverable-deliver(address[],uint256[])}.
    /// @dev Note: Either `deliver` or `deliverOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Reverts if one of `tokenIds` has been previously burnt.
    /// @dev Emits a {Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliverOnce(Layout storage s, address[] memory recipients, uint256[] memory tokenIds) internal {
        uint256 length = recipients.length;
        require(length == tokenIds.length, "ERC721: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC721: mint to address(0)");

                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(!_tokenExists(owner), "ERC721: existing token");
                require(!_tokenWasBurnt(owner), "ERC721: burnt token");

                s.owners[tokenId] = uint256(uint160(to));
                ++s.balances[to];

                emit Transfer(address(0), to, tokenId);
            }
        }
    }

    /// @notice Burns a token by a sender.
    /// @dev Note: This function implements {ERC721Burnable-burnFrom(address,uint256)}.
    /// @dev Reverts if `tokenId` is not owned by `from`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param tokenId The identifier of the token to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 tokenId) internal {
        uint256 owner = s.owners[tokenId];
        require(from == _tokenOwner(owner), "ERC721: non-owned token");

        if (!_isOperatable(s, from, sender)) {
            require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
        }

        s.owners[tokenId] = BURNT_TOKEN_OWNER_VALUE;

        unchecked {
            // cannot underflow as balance is verified through TOKEN ownership
            --s.balances[from];
        }
        emit Transfer(from, address(0), tokenId);
    }

    /// @notice Burns a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC721Burnable-batchBurnFrom(address,uint256[])}.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address for each of `tokenIds`.
    /// @param sender The message sender.
    /// @param from The current tokens owner.
    /// @param tokenIds The identifiers of the tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address from, uint256[] calldata tokenIds) internal {
        bool operatable = _isOperatable(s, from, sender);

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(from == _tokenOwner(owner), "ERC721: non-owned token");
                if (!operatable) {
                    require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
                }
                s.owners[tokenId] = BURNT_TOKEN_OWNER_VALUE;
                emit Transfer(from, address(0), tokenId);
            }

            if (length != 0) {
                s.balances[from] -= length;
            }
        }
    }

    /// @notice Gets the balance of an address.
    /// @dev Note: This function implements {ERC721-balanceOf(address)}.
    /// @dev Reverts if `owner` is the zero address.
    /// @param owner The address to query the balance of.
    /// @return balance The amount owned by the owner.
    function balanceOf(Layout storage s, address owner) internal view returns (uint256 balance) {
        require(owner != address(0), "ERC721: balance of address(0)");
        return s.balances[owner];
    }

    /// @notice Gets the owner of a token.
    /// @dev Note: This function implements {ERC721-ownerOf(uint256)}.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the owner of.
    /// @return tokenOwner The owner of the token.
    function ownerOf(Layout storage s, uint256 tokenId) internal view returns (address tokenOwner) {
        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        return _tokenOwner(owner);
    }

    /// @notice Gets the approved address for a token.
    /// @dev Note: This function implements {ERC721-getApproved(uint256)}.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the approval of.
    /// @return approved The approved address for the token identifier, or the zero address if no approval is set.
    function getApproved(Layout storage s, uint256 tokenId) internal view returns (address approved) {
        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        if (_tokenHasApproval(owner)) {
            return s.approvals[tokenId];
        } else {
            return address(0);
        }
    }

    /// @notice Gets whether an operator is approved for all tokens by an owner.
    /// @dev Note: This function implements {ERC721-isApprovedForAll(address,address)}.
    /// @param owner The address which gives the approval for all tokens.
    /// @param operator The address which receives the approval for all tokens.
    /// @return approvedForAll Whether the operator is approved for all tokens by the owner.
    function isApprovedForAll(Layout storage s, address owner, address operator) internal view returns (bool approvedForAll) {
        return s.operators[owner][operator];
    }

    /// @notice Gets whether a token was burnt.
    /// @param tokenId The token identifier.
    /// @return tokenWasBurnt Whether the token was burnt.
    function wasBurnt(Layout storage s, uint256 tokenId) internal view returns (bool tokenWasBurnt) {
        return _tokenWasBurnt(s.owners[tokenId]);
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Calls {IERC721Receiver-onERC721Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param tokenId Identifier of the token transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC721Received(address sender, address from, address to, uint256 tokenId, bytes memory data) private {
        require(IERC721Receiver(to).onERC721Received(sender, from, tokenId, data) == ERC721_RECEIVED, "ERC721: safe transfer rejected");
    }

    /// @notice Returns whether an account is authorised to make a transfer on behalf of an owner.
    /// @param owner The token owner.
    /// @param account The account to check the operatability of.
    /// @return operatable True if `account` is `owner` or is an operator for `owner`, false otherwise.
    function _isOperatable(Layout storage s, address owner, address account) private view returns (bool operatable) {
        return (owner == account) || s.operators[owner][account];
    }

    function _tokenOwner(uint256 owner) private pure returns (address tokenOwner) {
        return address(uint160(owner));
    }

    function _tokenExists(uint256 owner) private pure returns (bool tokenExists) {
        return uint160(owner) != 0;
    }

    function _tokenWasBurnt(uint256 owner) private pure returns (bool tokenWasBurnt) {
        return owner == BURNT_TOKEN_OWNER_VALUE;
    }

    function _tokenHasApproval(uint256 owner) private pure returns (bool tokenHasApproval) {
        return owner & TOKEN_APPROVAL_OWNER_FLAG != 0;
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