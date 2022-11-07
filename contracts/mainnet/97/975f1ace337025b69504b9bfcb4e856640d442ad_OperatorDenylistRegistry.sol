// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC173} from "./interfaces/IERC173.sol";
import {IOperatorDenylistRegistry} from "./interfaces/IOperatorDenylistRegistry.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title Operator Denylist Registry
/// @author Kfish
/// @dev We use denied as default instead of approved because it defaults to false,
///      otherwise we would have to approve operators instead which serves another purpose
/// @notice This is a registry to be used by creators where they can deny operators from
///         interacting with their contracts
contract OperatorDenylistRegistry is IOperatorDenylistRegistry {
    /// @notice Used to check administrator rights using IAccessControl
    bytes32 private constant _DEFAULT_ADMIN_ROLE = 0x00;

    struct OperatedContract {
        mapping(address => bool) operators;
        mapping(address => bool) registryOperators;
    }

    /// @notice Mapping of a contract address to an OperatedContract struct
    mapping(address => OperatedContract) private operatedContracts;
    /// @notice Mapping of a contract address to it's codehash
    ///         used to keep track of new address registrations
    mapping(address => bytes32) private codeHashes;

    /// @notice Add or remove a batch of addresses to the registry
    /// @dev Calls setOperatorDenied for each entry
    /// @param operatedContract the contract being managed
    /// @param operators list of addresses to update their denial state
    /// @param denials whether each operator should be denied or not
    function batchSetOperatorDenied(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata denials
    ) external {
        if (operators.length == 0) revert InvalidOperators();
        if (operators.length != denials.length)
            revert OperatorsDenialsLengthMismatch();
        for (uint256 i = 0; i < operators.length; i++) {
            setOperatorDenied(operatedContract, operators[i], denials[i]);
        }
    }

    /// @notice Add registry operators for a managed contract
    /// @dev Calls setApprovalForRegistryOperator
    /// @param operatedContract the contract being managed
    /// @param operators list of addresses to update as operators
    /// @param approvals whether each operator is approved or not
    function batchSetApprovalForRegistryOperator(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata approvals
    ) external {
        if (operators.length == 0) revert InvalidOperators();
        if (operators.length != approvals.length)
            revert OperatorsApprovalsLengthMismatch();
        for (uint256 i = 0; i < operators.length; i++) {
            setApprovalForRegistryOperator(
                operatedContract,
                operators[i],
                approvals[i]
            );
        }
    }

    /// @notice Add a registry operator for a managed contract
    /// @dev Operators will be able to add or remove operators
    ///      and add or remove entries in the managed contract's denylist
    /// @param operatedContract the contract being managed
    /// @param operator the address of the registry operator
    /// @param approved whether the registry operator will be approved or not
    function setApprovalForRegistryOperator(
        address operatedContract,
        address operator,
        bool approved
    ) public {
        if (operatedContract == address(0) || operator == address(0))
            revert AddressZero();
        if (
            !_hasOperatedContractPrivileges(operatedContract, msg.sender) &&
            !isRegistryOperatorApproved(operatedContract, msg.sender)
        ) revert SenderNotContractOwnerOrRegistryOperator();
        operatedContracts[operatedContract].registryOperators[
            operator
        ] = approved;

        emit ApprovedRegistryOperator(
            msg.sender,
            operatedContract,
            operator,
            approved
        );
    }

    /// @notice Setting an operator as denied or not
    /// @param operatedContract the contract being managed
    /// @param operator the operator being updated
    /// @param denied whether the operator is denied or not
    function setOperatorDenied(
        address operatedContract,
        address operator,
        bool denied
    ) public {
        if (operatedContract == address(0) || operator == address(0))
            revert AddressZero();
        if (
            !_hasOperatedContractPrivileges(operatedContract, msg.sender) &&
            !isRegistryOperatorApproved(operatedContract, msg.sender)
        ) revert SenderNotContractOwnerOrRegistryOperator();
        bytes32 operatorCodeHash = operatedContract.codehash;
        operatedContracts[operatedContract].operators[operator] = denied;
        emit DeniedOperator(msg.sender, operatedContract, operator, denied);

        if (codeHashes[operator] != operatorCodeHash) {
            codeHashes[operator] = operatorCodeHash;
            emit RegisteredNewOperator(msg.sender, operator, operatorCodeHash);
        }
    }

    /// @notice Checks whether an operator is denied or not
    /// @param operatedContract the contract being managed
    /// @param operator the operator to check
    /// @return true if the operator is denied
    function isOperatorDenied(address operatedContract, address operator)
        public
        view
        returns (bool)
    {
        if (operatedContract == address(0)) revert AddressZero();
        if (operatedContract.code.length == 0) revert InvalidContractAddress();
        if (operator.code.length > 0) {
            return operatedContracts[operatedContract].operators[operator];
        } else {
            return false;
        }
    }

    /// @notice Checks whether an operator is denied or not for msg.sender
    /// @dev To be called by contracts using the registry
    /// @param operator the operator to check for
    /// @return true if the operator is denied
    function isOperatorDenied(address operator) public view returns (bool) {
        return isOperatorDenied(msg.sender, operator);
    }

    /// @notice Check whether an address is approved to update a contracts denylist
    /// @param operatedContract the contract being managed
    /// @param operator the registry operator to check
    /// @return true if the registry operator is approved
    function isRegistryOperatorApproved(
        address operatedContract,
        address operator
    ) public view returns (bool) {
        if (operatedContract == address(0) || operator == address(0))
            revert AddressZero();
        return
            _hasOperatedContractPrivileges(operatedContract, operator) ||
            operatedContracts[operatedContract].registryOperators[operator];
    }

    /// @notice Checks whether an operator is owner or has DEFAULT_ADMIN_ROLE
    /// @param operatedContract the contract being managed
    /// @param operator the operator to check
    /// @return true if the operator is owner or admin of the operated contract
    function _hasOperatedContractPrivileges(
        address operatedContract,
        address operator
    ) private view returns (bool) {
        if (operatedContract.code.length == 0) revert InvalidContractAddress();
        if (
            ERC165Checker.supportsInterface(
                operatedContract,
                type(IAccessControl).interfaceId
            )
        ) {
            return _isDefaultAdminOfContract(operatedContract, operator);
        }
        if (
            ERC165Checker.supportsInterface(
                operatedContract,
                type(IERC173).interfaceId
            )
        ) {
            return IERC173(operatedContract).owner() == operator;
        } else {
            try IERC173(operatedContract).owner() returns (
                address contractOwner
            ) {
                return contractOwner == operator;
            } catch {
                revert IOperatorDenylistRegistry.CannotVerifyContractOwnership();
            }
        }
    }

    /// @notice Check whether an operator has the DEFAULT_ADMIN_ROLE of a contract
    /// @dev called by _hasOperatedContractPrivileges only if the AccessControl interface
    ///      is supported
    /// @param operatedContract the contract being managed
    /// @param operator the address to check
    function _isDefaultAdminOfContract(
        address operatedContract,
        address operator
    ) private view returns (bool) {
        if (operatedContract.code.length == 0) revert InvalidContractAddress();
        return
            IAccessControl(operatedContract).hasRole(
                _DEFAULT_ADMIN_ROLE,
                operator
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 /* is ERC165 */ {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() view external returns(address);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOperatorDenylistRegistry {
    error InvalidContractAddress();
    error SenderNotContractOwnerOrRegistryOperator();
    error CannotVerifyContractOwnership();
    error AddressZero();
    error OperatorsApprovalsLengthMismatch();
    error OperatorsDenialsLengthMismatch();
    error InvalidOperators();

    event RegisteredNewOperator(
        address indexed sender,
        address indexed operator,
        bytes32 codeHash
    );
    event DeniedOperator(
        address indexed sender,
        address indexed operatedContract,
        address indexed operator,
        bool denied
    );
    event ApprovedRegistryOperator(
        address indexed sender,
        address indexed operatedContract,
        address indexed operator,
        bool approved
    );

    function isRegistryOperatorApproved(
        address operatedContract,
        address operator
    ) external view returns (bool);

    function isOperatorDenied(address operator) external view returns (bool);

    function isOperatorDenied(address operatedContract, address operator)
        external
        view
        returns (bool);

    function setOperatorDenied(
        address operatedContract,
        address operator,
        bool denied
    ) external;

    function setApprovalForRegistryOperator(
        address operatedContract,
        address operator,
        bool approved
    ) external;

    function batchSetApprovalForRegistryOperator(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata approvals
    ) external;

    function batchSetOperatorDenied(
        address operatedContract,
        address[] calldata operators,
        bool[] calldata denials
    ) external;
}