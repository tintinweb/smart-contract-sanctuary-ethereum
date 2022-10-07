// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0
pragma solidity ^0.8.0;

import "../interfaces/IRegion.sol";
import "../interfaces/IACLRegistry.sol";
import "../interfaces/IContractRegistry.sol";

contract Region is IRegion {
  IContractRegistry public contractRegistry;

  bytes32 public immutable override defaultRegion = keccak256("World");
  bytes32[] public regions;
  address[] public beneficiaryVaults;
  mapping(bytes32 => bool) public override regionExists;
  mapping(bytes32 => address) public override regionVaults;

  event RegionAdded(bytes32 region);

  constructor(address _beneficiaryVault, IContractRegistry _contractRegistry) {
    regions.push(keccak256("World"));
    regionExists[keccak256("World")] = true;
    beneficiaryVaults.push(_beneficiaryVault);
    regionVaults[keccak256("World")] = _beneficiaryVault;
    contractRegistry = _contractRegistry;
  }

  function getAllRegions() public view override returns (bytes32[] memory) {
    return regions;
  }

  function getAllVaults() public view override returns (address[] memory) {
    return beneficiaryVaults;
  }

  function addRegion(bytes32 region_, address _beneficiaryVault) external override {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    require(regionExists[region_] == false, "region already exists");
    regions.push(region_);
    regionExists[region_] = true;
    beneficiaryVaults.push(_beneficiaryVault);
    regionVaults[region_] = _beneficiaryVault;
    emit RegionAdded(region_);
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface IRegion {
  function defaultRegion() external view returns (bytes32);

  function regionExists(bytes32 region) external view returns (bool);

  function regionVaults(bytes32 region) external view returns (address);

  function getAllRegions() external view returns (bytes32[] memory);

  function getAllVaults() external view returns (address[] memory);

  function addRegion(bytes32 region, address beneficiaryVault) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IACLRegistry {
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
   * @dev Returns `true` if `account` has been granted `permission`.
   */
  function hasPermission(bytes32 permission, address account) external view returns (bool);

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

  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  function grantPermission(bytes32 permission, address account) external;

  function revokePermission(bytes32 permission) external;

  function requireApprovedContractOrEOA(address account) external view;

  function requireRole(bytes32 role, address account) external view;

  function requirePermission(bytes32 permission, address account) external view;

  function isRoleAdmin(bytes32 role, address account) external view;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.12

pragma solidity >=0.6.12;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);

  function getContractIdFromAddress(address _contractAddress) external view returns (bytes32);

  function addContract(
    bytes32 _name,
    address _address,
    bytes32 _version
  ) external;

  function updateContract(
    bytes32 _name,
    address _newAddress,
    bytes32 _version
  ) external;
}