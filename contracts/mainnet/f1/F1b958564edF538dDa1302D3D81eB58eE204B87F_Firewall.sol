//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IAdministrable.sol";

import "./libraries/LibAdministrable.sol";
import "./libraries/LibSanitize.sol";

/// @title Administrable
/// @author Kiln
/// @notice This contract handles the administration of the contracts
abstract contract Administrable is IAdministrable {
    /// @notice Prevents unauthorized calls
    modifier onlyAdmin() {
        if (msg.sender != LibAdministrable._getAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Prevents unauthorized calls
    modifier onlyPendingAdmin() {
        if (msg.sender != LibAdministrable._getPendingAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IAdministrable
    function getAdmin() external view returns (address) {
        return LibAdministrable._getAdmin();
    }

    /// @inheritdoc IAdministrable
    function getPendingAdmin() external view returns (address) {
        return LibAdministrable._getPendingAdmin();
    }

    /// @inheritdoc IAdministrable
    function proposeAdmin(address _newAdmin) external onlyAdmin {
        _setPendingAdmin(_newAdmin);
    }

    /// @inheritdoc IAdministrable
    function acceptAdmin() external onlyPendingAdmin {
        _setAdmin(LibAdministrable._getPendingAdmin());
        _setPendingAdmin(address(0));
    }

    /// @notice Internal utility to set the admin address
    /// @param _admin Address to set as admin
    function _setAdmin(address _admin) internal {
        LibSanitize._notZeroAddress(_admin);
        LibAdministrable._setAdmin(_admin);
        emit SetAdmin(_admin);
    }

    /// @notice Internal utility to set the pending admin address
    /// @param _pendingAdmin Address to set as pending admin
    function _setPendingAdmin(address _pendingAdmin) internal {
        LibAdministrable._setPendingAdmin(_pendingAdmin);
        emit SetPendingAdmin(_pendingAdmin);
    }

    /// @notice Internal utility to retrieve the address of the current admin
    /// @return The address of admin
    function _getAdmin() internal view returns (address) {
        return LibAdministrable._getAdmin();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IFirewall.sol";

import "./Administrable.sol";

/// @title Firewall
/// @author Figment
/// @notice This contract accepts calls to admin-level functions of an underlying contract, and
///         ensures the caller holds an appropriate role for calling that function. There are two roles:
///          - An Admin can call anything
///          - An Executor can call specific functions. The list of function is customisable.
///         Random callers cannot call anything through this contract, even if the underlying function
///         is unpermissioned in the underlying contract.
///         Calls to non-admin functions should be called at the underlying contract directly.
contract Firewall is IFirewall, Administrable {
    /// @inheritdoc IFirewall
    address public executor;

    /// @inheritdoc IFirewall
    address public destination;

    /// @inheritdoc IFirewall
    mapping(bytes4 => bool) public executorCanCall;

    /// @param _admin Address of the administrator, that is able to perform all calls via the Firewall
    /// @param _executor Address of the executor, that is able to perform only a subset of calls via the Firewall
    /// @param _executorCallableSelectors Initial list of allowed selectors for the executor
    constructor(address _admin, address _executor, address _destination, bytes4[] memory _executorCallableSelectors) {
        LibSanitize._notZeroAddress(_executor);
        LibSanitize._notZeroAddress(_destination);
        _setAdmin(_admin);
        executor = _executor;
        destination = _destination;

        emit SetExecutor(_executor);
        emit SetDestination(_destination);

        for (uint256 i; i < _executorCallableSelectors.length;) {
            executorCanCall[_executorCallableSelectors[i]] = true;
            emit SetExecutorPermissions(_executorCallableSelectors[i], true);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Prevents unauthorized calls
    modifier onlyAdminOrExecutor() {
        if (_getAdmin() != msg.sender && msg.sender != executor) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IFirewall
    function setExecutor(address _newExecutor) external onlyAdminOrExecutor {
        LibSanitize._notZeroAddress(_newExecutor);
        executor = _newExecutor;
        emit SetExecutor(_newExecutor);
    }

    /// @inheritdoc IFirewall
    function allowExecutor(bytes4 _functionSelector, bool _executorCanCall) external onlyAdmin {
        executorCanCall[_functionSelector] = _executorCanCall;
        emit SetExecutorPermissions(_functionSelector, _executorCanCall);
    }

    /// @inheritdoc IFirewall
    fallback() external payable virtual {
        _fallback();
    }

    /// @inheritdoc IFirewall
    receive() external payable virtual {
        _fallback();
    }

    /// @notice Performs call checks to verify that the caller is able to perform the call
    function _checkCallerRole() internal view {
        if (msg.sender == _getAdmin() || (executorCanCall[msg.sig] && msg.sender == executor)) {
            return;
        }
        revert LibErrors.Unauthorized(msg.sender);
    }

    /// @notice Forwards the current call parameters to the destination address
    /// @param _destination Address on which the forwarded call is performed
    /// @param _value Message value to attach to the call
    function _forward(address _destination, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the destination.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), _destination, _value, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Internal utility to perform authorization checks and forward a call
    function _fallback() internal virtual {
        _checkCallerRole();
        _forward(destination, msg.value);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Administrable Interface
/// @author Kiln
/// @notice This interface exposes methods to handle the ownership of the contracts
interface IAdministrable {
    /// @notice The pending admin address changed
    /// @param pendingAdmin New pending admin address
    event SetPendingAdmin(address indexed pendingAdmin);

    /// @notice The admin address changed
    /// @param admin New admin address
    event SetAdmin(address indexed admin);

    /// @notice Retrieves the current admin address
    /// @return The admin address
    function getAdmin() external view returns (address);

    /// @notice Retrieve the current pending admin address
    /// @return The pending admin address
    function getPendingAdmin() external view returns (address);

    /// @notice Proposes a new address as admin
    /// @dev This security prevents setting an invalid address as an admin. The pending
    /// @dev admin has to claim its ownership of the contract, and prove that the new
    /// @dev address is able to perform regular transactions.
    /// @param _newAdmin New admin address
    function proposeAdmin(address _newAdmin) external;

    /// @notice Accept the transfer of ownership
    /// @dev Only callable by the pending admin. Resets the pending admin if succesful.
    function acceptAdmin() external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Firewall
/// @author Figment
/// @notice This interface exposes methods to accept calls to admin-level functions of an underlying contract.
interface IFirewall {
    /// @notice The stored executor address has been changed
    /// @param executor The new executor address
    event SetExecutor(address indexed executor);

    /// @notice The stored destination address has been changed
    /// @param destination The new destination address
    event SetDestination(address indexed destination);

    /// @notice The storage permission for a selector has been changed
    /// @param selector The 4 bytes method selector
    /// @param status True if executor is allowed
    event SetExecutorPermissions(bytes4 selector, bool status);

    /// @notice Retrieve the executor address
    /// @return The executor address
    function executor() external view returns (address);

    /// @notice Retrieve the destination address
    /// @return The destination address
    function destination() external view returns (address);

    /// @notice Returns true if the executor is allowed to perform a call on the given selector
    /// @param _selector The selector to verify
    /// @return True if executor is allowed to call
    function executorCanCall(bytes4 _selector) external view returns (bool);

    /// @notice Sets the executor address
    /// @param _newExecutor New address for the executor
    function setExecutor(address _newExecutor) external;

    /// @notice Sets the permission for a function selector
    /// @param _functionSelector Method signature on which the permission is changed
    /// @param _executorCanCall True if selector is callable by the executor
    function allowExecutor(bytes4 _functionSelector, bool _executorCanCall) external;

    /// @notice Fallback method. All its parameters are forwarded to the destination if caller is authorized
    fallback() external payable;

    /// @notice Receive fallback method. All its parameters are forwarded to the destination if caller is authorized
    receive() external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../state/shared/AdministratorAddress.sol";
import "../state/shared/PendingAdministratorAddress.sol";

/// @title Lib Administrable
/// @author Kiln
/// @notice This library handles the admin and pending admin storage vars
library LibAdministrable {
    /// @notice Retrieve the system admin
    /// @return The address of the system admin
    function _getAdmin() internal view returns (address) {
        return AdministratorAddress.get();
    }

    /// @notice Retrieve the pending system admin
    /// @return The adress of the pending system admin
    function _getPendingAdmin() internal view returns (address) {
        return PendingAdministratorAddress.get();
    }

    /// @notice Sets the system admin
    /// @param _admin New system admin
    function _setAdmin(address _admin) internal {
        AdministratorAddress.set(_admin);
    }

    /// @notice Sets the pending system admin
    /// @param _pendingAdmin New pending system admin
    function _setPendingAdmin(address _pendingAdmin) internal {
        PendingAdministratorAddress.set(_pendingAdmin);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Lib Basis Points
/// @notice Holds the basis points max value
library LibBasisPoints {
    /// @notice The max value for basis points (represents 100%)
    uint256 internal constant BASIS_POINTS_MAX = 10_000;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Errors
/// @notice Library of common errors
library LibErrors {
    /// @notice The operator is unauthorized for the caller
    /// @param caller Address performing the call
    error Unauthorized(address caller);

    /// @notice The call was invalid
    error InvalidCall();

    /// @notice The argument was invalid
    error InvalidArgument();

    /// @notice The address is zero
    error InvalidZeroAddress();

    /// @notice The string is empty
    error InvalidEmptyString();

    /// @notice The fee is invalid
    error InvalidFee();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibErrors.sol";
import "./LibBasisPoints.sol";

/// @title Lib Sanitize
/// @notice Utilities to sanitize input values
library LibSanitize {
    /// @notice Reverts if address is 0
    /// @param _address Address to check
    function _notZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert LibErrors.InvalidZeroAddress();
        }
    }

    /// @notice Reverts if string is empty
    /// @param _string String to check
    function _notEmptyString(string memory _string) internal pure {
        if (bytes(_string).length == 0) {
            revert LibErrors.InvalidEmptyString();
        }
    }

    /// @notice Reverts if fee is invalid
    /// @param _fee Fee to check
    function _validFee(uint256 _fee) internal pure {
        if (_fee > LibBasisPoints.BASIS_POINTS_MAX) {
            revert LibErrors.InvalidFee();
        }
    }
}

// SPDX-License-Identifier:    MIT

pragma solidity 0.8.10;

/// @title Lib Unstructured Storage
/// @notice Utilities to work with unstructured storage
library LibUnstructuredStorage {
    /// @notice Retrieve a bool value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bool value
    function getStorageBool(bytes32 _position) internal view returns (bool data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an address value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The address value
    function getStorageAddress(bytes32 _position) internal view returns (address data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve a bytes32 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bytes32 value
    function getStorageBytes32(bytes32 _position) internal view returns (bytes32 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an uint256 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The uint256 value
    function getStorageUint256(bytes32 _position) internal view returns (uint256 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Sets a bool value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bool value to set
    function setStorageBool(bytes32 _position, bool _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an address value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The address value to set
    function setStorageAddress(bytes32 _position, address _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets a bytes32 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bytes32 value to set
    function setStorageBytes32(bytes32 _position, bytes32 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an uint256 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The uint256 value to set
    function setStorageUint256(bytes32 _position, uint256 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Administrator Address Storage
/// @notice Utility to manage the Administrator Address in storage
library AdministratorAddress {
    /// @notice Storage slot of the Administrator Address
    bytes32 public constant ADMINISTRATOR_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.administratorAddress")) - 1);

    /// @notice Retrieve the Administrator Address
    /// @return The Administrator Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ADMINISTRATOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Administrator Address
    /// @param _newValue New Administrator Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ADMINISTRATOR_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Pending Administrator Address Storage
/// @notice Utility to manage the Pending Administrator Address in storage
library PendingAdministratorAddress {
    /// @notice Storage slot of the Pending Administrator Address
    bytes32 public constant PENDING_ADMINISTRATOR_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.pendingAdministratorAddress")) - 1);

    /// @notice Retrieve the Pending Administrator Address
    /// @return The Pending Administrator Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(PENDING_ADMINISTRATOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Pending Administrator Address
    /// @param _newValue New Pending Administrator Address
    function set(address _newValue) internal {
        LibUnstructuredStorage.setStorageAddress(PENDING_ADMINISTRATOR_ADDRESS_SLOT, _newValue);
    }
}