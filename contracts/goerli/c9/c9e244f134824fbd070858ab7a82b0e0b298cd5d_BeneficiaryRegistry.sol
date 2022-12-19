// SPDX-License-Identifier: MIT

// Docgen-SOLC: 0.8.0
pragma solidity ^0.8.0;

import "../interfaces/IBeneficiaryRegistry.sol";
import "../interfaces/IACLRegistry.sol";
import "../interfaces/IContractRegistry.sol";

contract BeneficiaryRegistry is IBeneficiaryRegistry {
  struct Beneficiary {
    string applicationCid; // ipfs address of application
    bytes32 region;
    uint256 listPointer;
  }

  /* ========== STATE VARIABLES ========== */

  IContractRegistry private contractRegistry;

  mapping(address => Beneficiary) private beneficiariesMap;
  address[] private beneficiariesList;

  /* ========== EVENTS ========== */

  event BeneficiaryAdded(address indexed _address, string indexed _applicationCid);
  event BeneficiaryRevoked(address indexed _address);

  /* ========== CONSTRUCTOR ========== */

  constructor(IContractRegistry _contractRegistry) {
    contractRegistry = _contractRegistry;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * @notice check if beneficiary exists in the registry
   */
  function beneficiaryExists(address _address) public view override returns (bool) {
    if (beneficiariesList.length == 0) return false;
    return beneficiariesList[beneficiariesMap[_address].listPointer] == _address;
  }

  /**
   * @notice get beneficiary's application cid from registry. this cid is the address to the beneficiary application that is included in the beneficiary nomination proposal.
   */
  function getBeneficiary(address _address) public view returns (string memory) {
    return beneficiariesMap[_address].applicationCid;
  }

  function getBeneficiaryList() public view returns (address[] memory) {
    return beneficiariesList;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice add a beneficiary with their IPFS cid to the registry
   * TODO: allow only election contract to modify beneficiary
   */
  function addBeneficiary(
    address _account,
    bytes32 _region,
    string calldata _applicationCid
  ) external override {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(
      keccak256("BeneficiaryGovernance"),
      msg.sender
    );
    require(_account == address(_account), "invalid address");
    require(bytes(_applicationCid).length > 0, "!application");
    require(!beneficiaryExists(_account), "exists");

    beneficiariesList.push(_account);
    beneficiariesMap[_account] = Beneficiary({
      applicationCid: _applicationCid,
      region: _region,
      listPointer: beneficiariesList.length - 1
    });

    emit BeneficiaryAdded(_account, _applicationCid);
  }

  /**
   * @notice remove a beneficiary from the registry. (callable only by council)
   */
  function revokeBeneficiary(address _address) external override {
    IACLRegistry aclRegistry = IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry")));
    require(
      aclRegistry.hasRole(keccak256("BeneficiaryGovernance"), msg.sender) ||
        (aclRegistry.hasRole(keccak256("Council"), msg.sender) &&
          aclRegistry.hasPermission(beneficiariesMap[_address].region, msg.sender)),
      "Only the BeneficiaryGovernance or council may perform this action"
    );
    require(beneficiaryExists(_address), "exists");
    delete beneficiariesList[beneficiariesMap[_address].listPointer];
    delete beneficiariesMap[_address];
    emit BeneficiaryRevoked(_address);
  }

  /* ========== MODIFIER ========== */

  modifier validAddress(address _address) {
    require(_address == address(_address), "invalid address");
    _;
  }
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
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface IBeneficiaryRegistry {
  function beneficiaryExists(address _address) external view returns (bool);

  function addBeneficiary(
    address _address,
    bytes32 region,
    string calldata applicationCid
  ) external;

  function revokeBeneficiary(address _address) external;
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