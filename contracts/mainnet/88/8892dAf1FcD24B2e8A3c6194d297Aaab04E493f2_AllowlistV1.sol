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

import "./interfaces/IAllowlist.1.sol";

import "./Initializable.sol";
import "./Administrable.sol";

import "./state/allowlist/AllowerAddress.sol";
import "./state/allowlist/Allowlist.sol";

/// @title Allowlist (v1)
/// @author Kiln
/// @notice This contract handles the list of allowed recipients.
/// @notice All accounts have an uint256 value associated with their addresses where
/// @notice each bit represents a right in the system. The DENY_MASK defined the mask
/// @notice used to identify if the denied bit is on, preventing users from interacting
/// @notice with the system
contract AllowlistV1 is IAllowlistV1, Initializable, Administrable {
    /// @notice Mask used for denied accounts
    uint256 internal constant DENY_MASK = 0x1 << 255;

    /// @inheritdoc IAllowlistV1
    function initAllowlistV1(address _admin, address _allower) external init(0) {
        _setAdmin(_admin);
        AllowerAddress.set(_allower);
        emit SetAllower(_allower);
    }

    /// @inheritdoc IAllowlistV1
    function getAllower() external view returns (address) {
        return AllowerAddress.get();
    }

    /// @inheritdoc IAllowlistV1
    function isAllowed(address _account, uint256 _mask) external view returns (bool) {
        uint256 userPermissions = Allowlist.get(_account);
        if (userPermissions & DENY_MASK == DENY_MASK) {
            return false;
        }
        return userPermissions & _mask == _mask;
    }

    /// @inheritdoc IAllowlistV1
    function isDenied(address _account) external view returns (bool) {
        return Allowlist.get(_account) & DENY_MASK == DENY_MASK;
    }

    /// @inheritdoc IAllowlistV1
    function hasPermission(address _account, uint256 _mask) external view returns (bool) {
        return Allowlist.get(_account) & _mask == _mask;
    }

    /// @inheritdoc IAllowlistV1
    function getPermissions(address _account) external view returns (uint256) {
        return Allowlist.get(_account);
    }

    /// @inheritdoc IAllowlistV1
    function onlyAllowed(address _account, uint256 _mask) external view {
        uint256 userPermissions = Allowlist.get(_account);
        if (userPermissions & DENY_MASK == DENY_MASK) {
            revert Denied(_account);
        }
        if (userPermissions & _mask != _mask) {
            revert LibErrors.Unauthorized(_account);
        }
    }

    /// @inheritdoc IAllowlistV1
    function setAllower(address _newAllowerAddress) external onlyAdmin {
        AllowerAddress.set(_newAllowerAddress);
        emit SetAllower(_newAllowerAddress);
    }

    /// @inheritdoc IAllowlistV1
    function allow(address[] calldata _accounts, uint256[] calldata _permissions) external {
        if (msg.sender != AllowerAddress.get() && msg.sender != _getAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        if (_accounts.length == 0) {
            revert InvalidAlloweeCount();
        }

        if (_accounts.length != _permissions.length) {
            revert MismatchedAlloweeAndStatusCount();
        }

        for (uint256 i = 0; i < _accounts.length;) {
            LibSanitize._notZeroAddress(_accounts[i]);
            Allowlist.set(_accounts[i], _permissions[i]);
            unchecked {
                ++i;
            }
        }

        emit SetAllowlistPermissions(_accounts, _permissions);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./state/shared/Version.sol";

/// @title Initializable
/// @author Kiln
/// @notice This contract ensures that initializers are called only once per version
contract Initializable {
    /// @notice An error occured during the initialization
    /// @param version The version that was attempting to be initialized
    /// @param expectedVersion The version that was expected
    error InvalidInitialization(uint256 version, uint256 expectedVersion);

    /// @notice Emitted when the contract is properly initialized
    /// @param version New version of the contracts
    /// @param cdata Complete calldata that was used during the initialization
    event Initialize(uint256 version, bytes cdata);

    /// @notice Use this modifier on initializers along with a hard-coded version number
    /// @param _version Version to initialize
    modifier init(uint256 _version) {
        if (_version != Version.get()) {
            revert InvalidInitialization(_version, Version.get());
        }
        Version.set(_version + 1); // prevents reentrency on the called method
        _;
        emit Initialize(_version, msg.data);
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

/// @title Allowlist Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the list of allowed recipients.
interface IAllowlistV1 {
    /// @notice The permissions of several accounts have changed
    /// @param accounts List of accounts
    /// @param permissions New permissions for each account at the same index
    event SetAllowlistPermissions(address[] indexed accounts, uint256[] permissions);

    /// @notice The stored allower address has been changed
    /// @param allower The new allower address
    event SetAllower(address indexed allower);

    /// @notice The provided accounts list is empty
    error InvalidAlloweeCount();

    /// @notice The account is denied access
    /// @param _account The denied account
    error Denied(address _account);

    /// @notice The provided accounts and permissions list have different lengths
    error MismatchedAlloweeAndStatusCount();

    /// @notice Initializes the allowlist
    /// @param _admin Address of the Allowlist administrator
    /// @param _allower Address of the allower
    function initAllowlistV1(address _admin, address _allower) external;

    /// @notice Retrieves the allower address
    /// @return The address of the allower
    function getAllower() external view returns (address);

    /// @notice This method returns true if the user has the expected permission and
    ///         is not in the deny list
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    /// @return True if mask is respected and user is allowed
    function isAllowed(address _account, uint256 _mask) external view returns (bool);

    /// @notice This method returns true if the user is in the deny list
    /// @param _account Recipient to verify
    /// @return True if user is denied access
    function isDenied(address _account) external view returns (bool);

    /// @notice This method returns true if the user has the expected permission
    ///         ignoring any deny list membership
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    /// @return True if mask is respected
    function hasPermission(address _account, uint256 _mask) external view returns (bool);

    /// @notice This method retrieves the raw permission value
    /// @param _account Recipient to verify
    /// @return The raw permissions value of the account
    function getPermissions(address _account) external view returns (uint256);

    /// @notice This method should be used as a modifier and is expected to revert
    ///         if the user hasn't got the required permission or if the user is
    ///         in the deny list.
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    function onlyAllowed(address _account, uint256 _mask) external view;

    /// @notice Changes the allower address
    /// @param _newAllowerAddress New address allowed to edit the allowlist
    function setAllower(address _newAllowerAddress) external;

    /// @notice Sets the allowlisting status for one or more accounts
    /// @dev The permission value is overridden and not updated
    /// @param _accounts Accounts with statuses to edit
    /// @param _permissions Allowlist permissions for each account, in the same order as _accounts
    function allow(address[] calldata _accounts, uint256[] calldata _permissions) external;
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Allower Address Storage
/// @notice Utility to manage the Allower Address in storage
library AllowerAddress {
    /// @notice Storage slot of the Allower Address
    bytes32 internal constant ALLOWER_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.allowerAddress")) - 1);

    /// @notice Retrieve the Allower Address
    /// @return The Allower Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ALLOWER_ADDRESS_SLOT);
    }

    /// @notice Sets the Allower Address
    /// @param _newValue New Allower Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ALLOWER_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Allowlist Storage
/// @notice Utility to manage the Allowlist mapping in storage
library Allowlist {
    /// @notice Storage slot of the Allowlist mapping
    bytes32 internal constant ALLOWLIST_SLOT = bytes32(uint256(keccak256("river.state.allowlist")) - 1);

    /// @notice Structure stored in storage slot
    struct Slot {
        /// @custom:attribute Mapping keeping track of permissions per account
        mapping(address => uint256) value;
    }

    /// @notice Retrieve the Allowlist value of an account
    /// @param _account The account to verify
    /// @return The Allowlist value
    function get(address _account) internal view returns (uint256) {
        bytes32 slot = ALLOWLIST_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value[_account];
    }

    /// @notice Sets the Allowlist value of an account
    /// @param _account The account value to set
    /// @param _status The value to set
    function set(address _account, uint256 _status) internal {
        bytes32 slot = ALLOWLIST_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_account] = _status;
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Version Storage
/// @notice Utility to manage the Version in storage
library Version {
    /// @notice Storage slot of the Version
    bytes32 public constant VERSION_SLOT = bytes32(uint256(keccak256("river.state.version")) - 1);

    /// @notice Retrieve the Version
    /// @return The Version
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(VERSION_SLOT);
    }

    /// @notice Sets the Version
    /// @param _newValue New Version
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(VERSION_SLOT, _newValue);
    }
}