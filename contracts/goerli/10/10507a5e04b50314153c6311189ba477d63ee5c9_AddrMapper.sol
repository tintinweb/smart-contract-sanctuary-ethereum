// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title AddrMapper
 * @author Fujidao Labs
 * @notice Contract that stores and returns addresses mappings
 * Required for getting contract addresses for some providers and flashloan providers.
 */

import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {IAddrMapper} from "../interfaces/IAddrMapper.sol";

contract AddrMapper is IAddrMapper, SystemAccessControl {
  // provider name => key address => returned address
  // (e.g. Compound_V2 => public erc20 => protocol Token)
  mapping(string => mapping(address => address)) private _addrMapping;
  // provider name => key1 address => key2 address => returned address
  // (e.g. Compound_V3 => collateral erc20 => borrow erc20 => Protocol market)
  mapping(string => mapping(address => mapping(address => address))) private _addrNestedMapping;

  string[] private _providerNames;

  mapping(string => bool) private _isProviderNameAdded;

  constructor(address chief) SystemAccessControl(chief) {}

  function getProviders() public view returns (string[] memory) {
    return _providerNames;
  }

  function getAddressMapping(
    string memory providerName,
    address inputAddr
  )
    external
    view
    override
    returns (address)
  {
    return _addrMapping[providerName][inputAddr];
  }

  function getAddressNestedMapping(
    string memory providerName,
    address inputAddr1,
    address inputAddr2
  )
    external
    view
    override
    returns (address)
  {
    return _addrNestedMapping[providerName][inputAddr1][inputAddr2];
  }

  /**
   * @dev Adds an address mapping.
   * Requirements:
   * - ProviderName should be formatted: Name_Version or Name_Version_Asset
   */
  function setMapping(
    string memory providerName,
    address keyAddr,
    address returnedAddr
  )
    public
    override
    onlyTimelock
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
      _providerNames.push(providerName);
    }
    _addrMapping[providerName][keyAddr] = returnedAddr;
    address[] memory inputAddrs = new address[](1);
    inputAddrs[0] = keyAddr;
    emit MappingChanged(inputAddrs, returnedAddr);
  }

  /**
   * @dev Adds a nested address mapping.
   * Requirements:
   * - ProviderName should be formatted: Name_Version or Name_Version_Asset
   */
  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    public
    override
    onlyTimelock
  {
    if (!_isProviderNameAdded[providerName]) {
      _isProviderNameAdded[providerName] = true;
      _providerNames.push(providerName);
    }
    _addrNestedMapping[providerName][keyAddr1][keyAddr2] = returnedAddr;
    address[] memory inputAddrs = new address[](2);
    inputAddrs[0] = keyAddr1;
    inputAddrs[1] = keyAddr2;
    emit MappingChanged(inputAddrs, returnedAddr);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SystemAccessControl.
 * @author Fujidao Labs
 * @notice Helper contract that should be inherited by contract implementations that
 * should call {Chief} for access control checks.
 */

import {IChief} from "../interfaces/IChief.sol";
import {CoreRoles} from "./CoreRoles.sol";

contract SystemAccessControl is CoreRoles {
  error SystemAccessControl__hasRole_missingRole(address caller, bytes32 role);
  error SystemAccessControl__onlyTimelock_callerIsNotTimelock();
  error SystemAccessControl__onlyChiefHouseKeeper_notHouseKeeper();

  IChief public immutable chief;

  modifier hasRole(address caller, bytes32 role) {
    if (!chief.hasRole(role, caller)) {
      revert SystemAccessControl__hasRole_missingRole(caller, role);
    }
    _;
  }

  modifier onlyChiefHouseKeeper() {
    if (!chief.hasRole(HOUSE_KEEPER_ROLE, msg.sender)) {
      revert SystemAccessControl__onlyChiefHouseKeeper_notHouseKeeper();
    }
    _;
  }

  modifier onlyTimelock() {
    if (msg.sender != chief.timelock()) {
      revert SystemAccessControl__onlyTimelock_callerIsNotTimelock();
    }
    _;
  }

  constructor(address chief_) {
    chief = IChief(chief_);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IAddrMapper {
  /**
   * @dev Log a change in address mapping
   */
  event MappingChanged(address[] keyAddress, address mappedAddress);

  function getAddressMapping(
    string memory providerName,
    address keyAddr
  )
    external
    view
    returns (address returnedAddr);

  function getAddressNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2
  )
    external
    view
    returns (address returnedAddr);

  function setMapping(string memory providerName, address keyAddr, address returnedAddr) external;

  function setNestedMapping(
    string memory providerName,
    address keyAddr1,
    address keyAddr2,
    address returnedAddr
  )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Chief helper interface.
 * @author Fujidao Labs
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  function timelock() external view returns (address);

  function addrMapper() external view returns (address);

  function allowedFlasher(address flasher) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

contract CoreRoles {
  bytes32 public constant HOUSE_KEEPER_ROLE = keccak256("HOUSE_KEEPER_ROLE");

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}

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