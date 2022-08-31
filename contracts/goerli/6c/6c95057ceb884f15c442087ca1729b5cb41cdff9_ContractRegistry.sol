// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./interfaces/IContractRegistry.sol";
import "./interfaces/IAccessControlList.sol";
import "../../common/libraries/ErrorCodes.sol";

contract ContractRegistry is IContractRegistry {
  // contract id => address
  mapping(bytes32 => address) private addresses;

  // contract ids
  /// @inheritdoc IContractRegistry
  bytes32 public constant ACCESS_CONTROL = "ACCESS_CONTROL";

  constructor(address accessControl) {
    addresses[ACCESS_CONTROL] = accessControl;
  }

  /// @inheritdoc IContractRegistry
  function getAccessControl() external view override returns (address) {
    return addresses[ACCESS_CONTROL];
  }

  /// @inheritdoc IContractRegistry
  function setAccessControl(address newAccessControl) external override onlyOwner {
    _setAddress(ACCESS_CONTROL, newAccessControl);
  }

  function _setAddress(bytes32 id, address newAddress) internal {
    address oldAddress = addresses[id];
    addresses[id] = newAddress;
    emit AddressSet(id, oldAddress, newAddress);
  }

  modifier onlyOwner() {
    if (!IAccessControlList(addresses[ACCESS_CONTROL]).isOwner(msg.sender)) {
      revert ErrorCodes.OnlyOwner();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title The interface for the NIL Contract Registry
 * @notice Main registry that stores contract addresses for the entire protocol
 *  @dev Owned by NIL Governance
 */
interface IContractRegistry {
  /**
   * @notice Emitted when a new address is set
   * @param id The contract id
   * @param oldAddress The old contract address
   * @param newAddress The new contract address
   */
  event AddressSet(bytes32 id, address oldAddress, address newAddress);

  /**
   * @notice The contract id for the Access Control contract
   */
  function ACCESS_CONTROL() external view returns (bytes32);

  /**
   * @notice Returns the address of the Access Control contract
   * @return The address of the Access Control contract
   */
  function getAccessControl() external view returns (address);

  /**
   * @notice Updates the address of the Access Control contract
   * @param newAccessControl The address of the new Access Control contract
   **/
  function setAccessControl(address newAccessControl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title The interface for NIL's Access Control functionality
 * @notice The main registry of system roles and permissions across the entire protocol
 * @dev Owned by NIL Governance
 */
interface IAccessControlList {
  /**
   * @notice Returns the identifier of the Admin role
   * @return The id of the Admin role
   */
  function ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns true if the address is an admin, false otherwise
   * @param admin The address to check
   * @return True if the given address is an admin, false otherwise
   */
  function isAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin
   * @param admin The address of the new admin
   */
  function addAdmin(address admin) external;

  /**
   * @notice Removes an admin
   * @param admin The address of the admin to remove
   */
  function removeAdmin(address admin) external;

  /**
   * @notice Returns true if the address is an emergency admin, false otherwise
   * @param admin The address to check
   * @return True if the given address is an emergency admin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new emergency admin
   * @param emergencyAdmin The address of the new emergency admin
   */
  function addEmergencyAdmin(address emergencyAdmin) external;

  /**
   * @notice Removes an emergency admin
   * @param emergencyAdmin The address of the emergency admin to remove
   */
  function removeEmergencyAdmin(address emergencyAdmin) external;

  /**
   * @notice Returns true if the address is the protocol owner, false otherwise
   * @param owner The address to check
   * @return True if the given address is the protocol owner, false otherwise
   */
  function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library ErrorCodes {
  /* ========== ACCESS CONTROL ========== */
  /// @notice Only the protocol owner may perform this action
  error OnlyOwner();

  /// @notice Only a protocol admin may perform this action
  error OnlyAdmin();

  /* ========== INVALID PARAMETERS ========== */
  /// @notice Cannot use the zero address
  error ZeroAddress();

  /// @notice The DEFAULT_ADMIN_ROLE cannot be set using `grantRole()`
  /// @dev Use `transferOwnership()` instead
  error CannotGrantRoleDefaultAdmin();
}